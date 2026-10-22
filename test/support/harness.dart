import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/api/api_client.dart';
import 'package:universal_pos/core/i18n/lang.dart';
import 'package:universal_pos/core/theme/theme.dart';
import 'package:universal_pos/data/local/database.dart';
import 'package:universal_pos/data/models/context.dart';
import 'package:universal_pos/data/providers.dart';
import 'package:universal_pos/data/session.dart';
import 'package:universal_pos/data/sync/sync_engine.dart';

/// Real responses captured from the running API (see test/fixtures/api.json) served through a fake Dio adapter, so
/// every screen is exercised with realistic data and no network.
class Fixtures {
  Fixtures._(this.data);
  final Map<String, dynamic> data;
  static Fixtures? _cache;

  static Fixtures load() => _cache ??= Fixtures._(jsonDecode(File('test/fixtures/api.json').readAsStringSync()) as Map<String, dynamic>);

  dynamic operator [](String k) => data[k];
  TenantContext context(String type) => TenantContext.fromJson((data['context_$type'] as Map).cast<String, dynamic>());
}

typedef Handler = dynamic Function(RequestOptions o);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);
  final Map<String, Handler> routes;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final key = '${options.method} ${options.path}';
    calls.add(key);
    final h = routes[key];
    if (h == null) {
      return ResponseBody.fromString(jsonEncode({'detail': 'No fake for $key', 'code': 'not_faked'}), 404, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    final body = h(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

class FixedSession extends SessionController {
  FixedSession(this._s);
  final SessionState _s;
  @override
  SessionState build() => _s;
}

class Rig {
  Rig({required this.container, required this.db, required this.adapter, required this.ctx});
  final ProviderContainer container;
  final AppDatabase db;
  final FakeAdapter adapter;
  final TenantContext ctx;
}

Future<void> loadFonts() async {
  SyncController.watchConnectivity = false;
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  await load('PJS', ['PlusJakartaSans.ttf']);
  await load('Hind', ['HindSiliguri-Regular.ttf']);
}

const phone = Size(390, 844);
const tablet = Size(820, 1180);
const desktop = Size(1440, 900);

/// Pump [child] inside the same theme/i18n/providers the real app uses.
Future<Rig> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size size = desktop,
  String type = 'supershop',
  Map<String, Handler> routes = const {},
  bool admin = false,
  bool signedOut = false,
  AppLang lang = AppLang.en,
  bool dark = false,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final previousOnError = FlutterError.onError;
  _lastDetails = null;
  FlutterError.onError = (details) {
    _lastDetails ??= details.toDiagnosticsNode().toStringDeep();
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);
  final fx = Fixtures.load();
  final ctx = fx.context(type);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => db.close());
  final adapter = FakeAdapter(routes);
  final client = ApiClient(baseUrl: 'http://fake/api/v1');
  client.adapter = adapter;
  client.setTokens('t', 'r');
  final state = signedOut
      ? const SessionState(status: AuthStatus.signedOut)
      : admin
          ? const SessionState(status: AuthStatus.ready, user: {'role': 'super_admin', 'name': 'Platform Admin'})
          : SessionState(status: AuthStatus.ready, ctx: ctx, user: (ctx.raw['user'] as Map).cast<String, dynamic>());
  final container = ProviderContainer(overrides: [
    cacheWindowProvider.overrideWithValue(Duration.zero), // no keep-alive timers left pending when a test ends
    dbProvider.overrideWithValue(db),
    bootstrapProvider.overrideWithValue(Bootstrap(serverUrl: 'http://fake/api/v1', lang: lang)),
    apiProvider.overrideWithValue(client),
    sessionProvider.overrideWith(() => FixedSession(state)),
    ...extra,
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: LangScope(
      lang: lang,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark ? Brightness.dark : Brightness.light, accent: ctx.accent),
        locale: Locale(lang.name),
        supportedLocales: const [Locale('en'), Locale('bn')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: Scaffold(body: SafeArea(child: child)),
      ),
    ),
  ));
  return Rig(container: container, db: db, adapter: adapter, ctx: ctx);
}

/// Let async work (futures, drift streams, animations) finish.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Await [f] while advancing the test clock. Drift schedules its internal work on timers that live in the test's
/// fake-async zone, so awaiting database or sync work inside `runAsync` alone would wait forever.
Future<T> drive<T>(WidgetTester tester, Future<T> f, {int maxTicks = 600}) async {
  var done = false;
  T? value;
  Object? error;
  StackTrace? trace;
  f.then((v) {
    done = true;
    value = v;
  }, onError: (Object e, StackTrace st) {
    done = true;
    error = e;
    trace = st;
  });
  for (var i = 0; i < maxTicks && !done; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 25));
  }
  if (!done) throw TestFailure('Timed out waiting for async work');
  if (error != null) Error.throwWithStackTrace(error!, trace!);
  return value as T;
}


/// Like `expect(tester.takeException(), isNull)` but prints the whole diagnostic (which widget overflowed, where it was built).
void expectNoError(WidgetTester tester) {
  final e = tester.takeException();
  if (e == null) return;
  fail(_lastDetails ?? (e is FlutterError ? e.toStringDeep() : e.toString()));
}

String? _lastDetails;

/// Responses for every GET the tenant screens make, from real payloads captured off the running backend.
Map<String, Handler> retailRoutes(Fixtures fx) {
  final saleId = fx['sales_supershop']['items'][0]['id'];
  return {
    'GET /products': (_) => fx['products_supershop'],
    'GET /customers': (_) => fx['customers_supershop'],
    'GET /reports/dues': (_) => fx['customers_dues'],
    'GET /sales': (_) => fx['sales_supershop'],
    'GET /sales/$saleId': (_) => fx['sale_detail'],
    'GET /purchases': (_) => fx['purchases'],
    'GET /suppliers': (_) => fx['suppliers'],
    'GET /shifts': (_) => fx['shifts'],
    'GET /users': (_) => fx['users'],
    'GET /users/roles': (_) => fx['users_roles'],
    'GET /branches': (_) => fx['branches'],
    'GET /reports/summary': (_) => fx['report_summary'],
    'GET /reports/stock-valuation': (_) => fx['report_stock_valuation'],
    'GET /reports/expenses': (_) => fx['report_expenses'],
    'GET /reports/top-products': (_) => fx['report_top_products'],
    'GET /reports/sales-by-day': (_) => fx['report_sales_by_day'],
    'GET /reports/expiring': (_) => fx['report_expiring'],
    'GET /reports/exceptions': (_) => fx['report_exceptions'],
    'GET /reports/cashiers': (_) => fx['report_cashiers'],
    'GET /reports/by-category': (_) => fx['report_by_category'],
    'GET /orders': (_) => {'items': [], 'total': 0, 'limit': 50, 'offset': 0},
      };
}
