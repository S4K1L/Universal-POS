import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/api/api_client.dart';
import 'package:universal_pos/data/local/database.dart';
import 'package:universal_pos/data/providers.dart';
import 'package:universal_pos/data/sync/sync_engine.dart';

import 'support/harness.dart' show FixedSession;
import 'package:universal_pos/data/session.dart';

/// A server stand-in that can refuse a push the way a real one (or the proxy in front of it) would.
class _PushServer implements HttpClientAdapter {
  _PushServer({required this.refuse});

  /// Returns an HTTP status to refuse this whole request with, or null to apply every event in it.
  final int? Function(List<Map<String, dynamic>> events) refuse;
  final List<int> batchSizes = [];
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add('${options.method} ${options.uri.path}');
    ResponseBody json(Object body, [int status = 200]) => ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (options.uri.path.endsWith('/health')) return json({'status': 'ok'});
    if (options.uri.path.endsWith('/sync/pull')) return json({'cursor': 0, 'has_more': false, 'changes': []});
    final events = ((options.data as Map)['events'] as List).cast<Map<String, dynamic>>();
    batchSizes.add(events.length);
    final status = refuse(events);
    if (status != null) return json({'detail': 'refused', 'code': 'refused'}, status);
    return json({
      'results': [
        for (final e in events) {'id': e['id'], 'status': 'applied'}
      ]
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<(ProviderContainer, AppDatabase, _PushServer)> _rig(int? Function(List<Map<String, dynamic>>) refuse, {int events = 5, String base = 'http://fake/api/v1'}) async {
  SyncController.watchConnectivity = false;
  final db = AppDatabase(NativeDatabase.memory());
  final server = _PushServer(refuse: refuse);
  final client = ApiClient(baseUrl: base)..adapter = server;
  final container = ProviderContainer(overrides: [
    cacheWindowProvider.overrideWithValue(Duration.zero),
    dbProvider.overrideWithValue(db),
    bootstrapProvider.overrideWithValue(Bootstrap(serverUrl: base)),
    apiProvider.overrideWithValue(client),
    sessionProvider.overrideWith(() => FixedSession(const SessionState(status: AuthStatus.ready))),
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  for (var i = 0; i < events; i++) {
    await db.into(db.outbox).insert(OutboxCompanion.insert(
          id: 'ev-$i',
          type: 'expense.create',
          payload: jsonEncode({'id': 'x$i', 'poison': i == 2}),
          occurredAt: DateTime.now().toUtc(),
          createdAt: DateTime.now().toUtc(),
          summary: const Value('test'),
        ));
  }
  return (container, db, server);
}

Future<Map<String, int>> _tally(AppDatabase db) async {
  final rows = await db.select(db.outbox).get();
  return {for (final s in ['pending', 'done', 'failed']) s: rows.where((r) => r.status == s).length};
}

bool _poisoned(List<Map<String, dynamic>> events) => events.any((e) => (e['payload'] as Map)['poison'] == true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('one malformed event no longer fails the whole batch', () async {
    final (container, db, server) = await _rig((events) => _poisoned(events) ? 422 : null);
    final sync = container.read(syncProvider.notifier)..start();
    await sync.syncNow();

    expect(await _tally(db), {'pending': 0, 'done': 4, 'failed': 1});
    final bad = await (db.select(db.outbox)..where((t) => t.status.equals('failed'))).getSingle();
    expect(bad.id, 'ev-2');
    expect(server.batchSizes.first, 5); // tried as a batch first, then one at a time
  });

  for (final status in [408, 429, 503]) {
    test('a $status keeps every event queued instead of parking it', () async {
      final (container, db, _) = await _rig((_) => status);
      final sync = container.read(syncProvider.notifier)..start();
      await sync.syncNow();
      expect(await _tally(db), {'pending': 5, 'done': 0, 'failed': 0});
    });
  }

  test('the connectivity probe finds /health beside the API, even behind a path prefix', () async {
    final (container, _, server) = await _rig((_) => null, events: 0, base: 'https://shop.example/pos/api/v1');
    final sync = container.read(syncProvider.notifier)..start();
    await sync.syncNow();
    expect(server.paths, contains('GET /pos/health'));
  });
}
