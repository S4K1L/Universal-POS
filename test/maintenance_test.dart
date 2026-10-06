import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/app/router.dart';
import 'package:universal_pos/core/api/api_client.dart';
import 'package:universal_pos/core/i18n/lang.dart';
import 'package:universal_pos/core/theme/theme.dart';
import 'package:universal_pos/data/platform_status.dart';
import 'package:universal_pos/data/providers.dart';
import 'package:universal_pos/data/session.dart';
import 'package:universal_pos/data/sync/sync_engine.dart';
import 'package:universal_pos/features/auth/device_setup_screen.dart';
import 'package:universal_pos/features/dashboard/dashboard_screen.dart';
import 'package:universal_pos/features/maintenance/maintenance_screen.dart';

import 'support/harness.dart';

/// A server that answers every request with one canned status and body — or, with [down], is unreachable.
class _Canned implements HttpClientAdapter {
  _Canned(this.status, this.body, {this.down = false});
  final int status;
  final Object body;
  final bool down;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (down) throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

class _FixedStatus extends PlatformStatusController {
  _FixedStatus(this._s);
  final PlatformStatus _s;
  @override
  PlatformStatus build() => _s;
  @override
  Future<void> refresh() async {}
  void set(PlatformStatus s) => state = s;
}

class _PendingSync extends SyncController {
  @override
  SyncState build() => const SyncState(pending: 3);
}

const _on = PlatformStatus(maintenance: true, message: 'Upgrading — back at 3pm', support: {'phone': '01800000000', 'email': 'help@example.com'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadFonts();
    PlatformStatusController.autoPoll = false;
  });
  tearDownAll(() => PlatformStatusController.autoPoll = true);

  group('platform status', () {
    ProviderContainer containerFor(HttpClientAdapter adapter) {
      final client = ApiClient(baseUrl: 'http://fake/api/v1')..adapter = adapter;
      final c = ProviderContainer(overrides: [
        bootstrapProvider.overrideWithValue(const Bootstrap(serverUrl: 'http://fake/api/v1')),
        apiProvider.overrideWithValue(client),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('reads maintenance, the admin message and only the support contacts that are filled in', () async {
      final c = containerFor(_Canned(200, {
        'maintenance': true,
        'message': 'Upgrading — back at 3pm',
        'support': {'phone': '01800000000', 'email': '', 'whatsapp': ' '},
      }));
      await c.read(platformStatusProvider.notifier).refresh();
      final s = c.read(platformStatusProvider);
      expect(s.maintenance, isTrue);
      expect(s.message, 'Upgrading — back at 3pm');
      expect(s.support, {'phone': '01800000000'});
    });

    test('an unreachable server is not maintenance, and does not clear what we knew', () async {
      final up = containerFor(_Canned(200, {'maintenance': false, 'message': '', 'support': {}}));
      await up.read(platformStatusProvider.notifier).refresh();
      expect(up.read(platformStatusProvider).maintenance, isFalse);

      final c = containerFor(_Canned(0, {}, down: true));
      c.read(platformStatusProvider.notifier).enterMaintenance('Back at 3pm');
      await c.read(platformStatusProvider.notifier).refresh();
      expect(c.read(platformStatusProvider).maintenance, isTrue, reason: 'offline must not end maintenance');
      expect(containerFor(_Canned(0, {}, down: true)).read(platformStatusProvider).maintenance, isFalse, reason: 'offline must not start it either');
    });

    test('a 503 maintenance answer from any call raises the flag with the admin message', () async {
      final messages = <String>[];
      final client = ApiClient(baseUrl: 'http://fake/api/v1', onMaintenance: messages.add)..adapter = _Canned(503, {'detail': 'Upgrading — back at 3pm', 'code': 'maintenance'});
      await expectLater(client.getMap('/tenants/me/context'), throwsA(isA<ApiError>().having((e) => e.maintenance, 'maintenance', isTrue)));
      expect(messages, ['Upgrading — back at 3pm']);
    });

    test('a 503 that is not maintenance does not', () async {
      final messages = <String>[];
      final client = ApiClient(baseUrl: 'http://fake/api/v1', onMaintenance: messages.add)..adapter = _Canned(503, {'detail': 'Bad gateway'});
      await expectLater(client.getMap('/x'), throwsA(isA<ApiError>()));
      expect(messages, isEmpty);
    });
  });

  group('maintenance screen', () {
    testWidgets('shows the admin message, support contacts and what is safe on the device', (tester) async {
      await pumpScreen(tester, const MaintenanceScreen(), size: phone, extra: [
        platformStatusProvider.overrideWith(() => _FixedStatus(_on)),
        syncProvider.overrideWith(_PendingSync.new),
      ]);
      await settle(tester, frames: 2);
      expectNoError(tester);
      expect(find.text("We'll be right back"), findsOneWidget);
      expect(find.text('MAINTENANCE IN PROGRESS'), findsOneWidget);
      expect(find.text('Upgrading — back at 3pm'), findsOneWidget);
      expect(find.text('01800000000'), findsOneWidget);
      expect(find.text('help@example.com'), findsOneWidget);
      expect(find.textContaining('Sales waiting to sync: 3'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('falls back to a kind default when the admin left the message empty, and has no help section without contacts', (tester) async {
      await pumpScreen(tester, const MaintenanceScreen(), extra: [platformStatusProvider.overrideWith(() => _FixedStatus(const PlatformStatus(maintenance: true)))]);
      await settle(tester, frames: 2);
      expectNoError(tester);
      expect(find.text('We are making improvements and will be back shortly.'), findsOneWidget);
      expect(find.text('Need help?'), findsNothing);
      expect(find.textContaining('Sales waiting to sync'), findsNothing);
    });

    for (final (name, size) in [('phone', phone), ('small phone', const Size(320, 568)), ('landscape phone', const Size(844, 390)), ('tablet', tablet), ('desktop', desktop)]) {
      testWidgets('lays out on a $name in Bangla and dark mode', (tester) async {
        await pumpScreen(tester, const MaintenanceScreen(), size: size, lang: AppLang.bn, dark: true, extra: [
          platformStatusProvider.overrideWith(() => _FixedStatus(_on)),
          syncProvider.overrideWith(_PendingSync.new),
        ]);
        await tester.pump(const Duration(seconds: 2)); // past the entrance, gears turning
        expectNoError(tester);
        expectNoError(tester);
        expect(find.text('আমরা এখনই ফিরে আসছি'), findsOneWidget);
        expect(find.text('রক্ষণাবেক্ষণ চলছে'), findsOneWidget);
      });
    }
  });

  group('motion', () {
    double opacityOfMessage(WidgetTester tester) => tester.widget<Opacity>(find.ancestor(of: find.byKey(const Key('maintenance-message')), matching: find.byType(Opacity)).first).opacity;

    final status = [platformStatusProvider.overrideWith(() => _FixedStatus(_on))];

    testWidgets('the content settles in one piece at a time and the gears keep turning', (tester) async {
      await pumpScreen(tester, const MaintenanceScreen(), extra: status);
      expect(opacityOfMessage(tester), 0, reason: 'starts hidden');
      await tester.pump(const Duration(milliseconds: 500)); // the message card enters from ~340 ms to ~900 ms
      expect(opacityOfMessage(tester), inExclusiveRange(0, 1), reason: 'mid-entrance');
      await tester.pump(const Duration(seconds: 2));
      expect(opacityOfMessage(tester), 1);
      expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'the clock behind the gears is still ticking');
      expectNoError(tester);
    });

    testWidgets('with reduce-motion on it is the same page, held still', (tester) async {
      await pumpScreen(
        tester,
        Builder(builder: (c) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: true), child: const MaintenanceScreen())),
        extra: status,
      );
      expect(opacityOfMessage(tester), 1, reason: 'no entrance animation');
      expect(find.text('Upgrading — back at 3pm'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0, reason: 'nothing is animating');
      expectNoError(tester);
    });

    testWidgets('Check again shows progress, then says it is still under maintenance', (tester) async {
      await pumpScreen(tester, const MaintenanceScreen(), extra: status);
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Check again'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('We check again automatically.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Still under maintenance. We will keep checking.'), findsOneWidget);
      expectNoError(tester);
    });
  });

  group('routing', () {
    Future<ProviderContainer> pumpApp(WidgetTester tester, SessionState session, PlatformStatus status) async {
      tester.view.physicalSize = desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fx = Fixtures.load();
      final client = ApiClient(baseUrl: 'http://fake/api/v1')..adapter = FakeAdapter({
          'GET /admin/overview': (_) => fx['admin_overview'],
          'GET /reports/dashboard': (_) => fx['dashboard_supershop'],
          'GET /orders': (_) => {'items': []},
        });
      final c = ProviderContainer(overrides: [
        bootstrapProvider.overrideWithValue(const Bootstrap(serverUrl: 'http://fake/api/v1')),
        apiProvider.overrideWithValue(client),
        sessionProvider.overrideWith(() => FixedSession(session)),
        platformStatusProvider.overrideWith(() => _FixedStatus(status)),
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: LangScope(
          lang: AppLang.en,
          child: MaterialApp.router(
            routerConfig: c.read(routerProvider),
            theme: buildTheme(Brightness.light),
            supportedLocales: const [Locale('en'), Locale('bn')],
            localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          ),
        ),
      ));
      await settle(tester, frames: 3);
      return c;
    }

    SessionState tenant({bool registered = true}) {
      final ctx = Fixtures.load().context('supershop');
      return SessionState(status: registered ? AuthStatus.ready : AuthStatus.needsDevice, ctx: ctx, user: (ctx.raw['user'] as Map).cast<String, dynamic>(), device: registered ? testDevice() : null);
    }

    testWidgets('a business user who signs in during maintenance lands on the maintenance page, not the till setup', (tester) async {
      await pumpApp(tester, tenant(registered: false), _on);
      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byType(DeviceSetupScreen), findsNothing);
    });

    testWidgets('a registered till is held on the maintenance page too, then released when maintenance ends', (tester) async {
      final c = await pumpApp(tester, tenant(), _on);
      expect(find.byType(MaintenanceScreen), findsOneWidget);

      (c.read(platformStatusProvider.notifier) as _FixedStatus).set(const PlatformStatus());
      await settle(tester, frames: 3);
      expect(find.byType(MaintenanceScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('without maintenance a new device sees the normal setup page', (tester) async {
      await pumpApp(tester, tenant(registered: false), const PlatformStatus());
      expect(find.byType(DeviceSetupScreen), findsOneWidget);
      expect(find.byType(MaintenanceScreen), findsNothing);
    });

    testWidgets('the platform admin is never shut out, so they can switch maintenance off', (tester) async {
      await pumpApp(tester, const SessionState(status: AuthStatus.ready, user: {'role': 'super_admin', 'name': 'Platform Admin'}), _on);
      expect(find.byType(MaintenanceScreen), findsNothing);
    });
  });
}
