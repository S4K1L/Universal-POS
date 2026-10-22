import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/api/api_client.dart';
import 'package:universal_pos/core/money/money.dart';
import 'package:universal_pos/data/local/database.dart';
import 'package:universal_pos/data/providers.dart';
import 'package:universal_pos/data/repos/catalogue_repo.dart';
import 'package:universal_pos/data/repos/sales_repo.dart';
import 'package:universal_pos/data/session.dart';
import 'package:universal_pos/data/sync/sync_engine.dart';
import 'package:universal_pos/features/pos/cart_controller.dart';

/// End-to-end: a till signs in, loads the catalogue, sells with NO connection, and the sales reach the server by
/// themselves once the connection returns. Runs against the real API on localhost:8000 (skipped if it isn't up).
const api = 'http://localhost:8000/api/v1';

Future<bool> _apiUp() async {
  try {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final r = await (await c.getUrl(Uri.parse('http://localhost:8000/health'))).close();
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool up;
  setUpAll(() async {
    HttpOverrides.global = null; // allow real sockets in tests
    up = await _apiUp();
  });

  test('sell offline, sync automatically when the connection returns', () async {
    if (!up) {
      markTestSkipped('API not running on :8000');
      return;
    }
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      cacheWindowProvider.overrideWithValue(Duration.zero), // no keep-alive timers left pending when a test ends
      dbProvider.overrideWithValue(db),
      bootstrapProvider.overrideWithValue(const Bootstrap(serverUrl: api)),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    // ---- the platform admin adds a brand-new local shop (its own business, so the test never touches demo data)
    final admin = ApiClient(baseUrl: api);
    final adminLogin = await admin.post('/auth/login', body: {'phone': '01700000000', 'password': 'admin12345'}, noAuth: true);
    admin.setTokens(adminLogin['access_token'] as String, null);
    final phone = '0198${(DateTime.now().millisecondsSinceEpoch % 10000000).toString().padLeft(7, '0')}';
    await admin.post('/admin/tenants', body: {
      'name': 'Offline Test Store',
      'owner_name': 'Test Owner',
      'phone': phone,
      'password': 'owner12345',
      'business_type_key': 'local_shop',
      'plan_key': 'enterprise',
      'sample_data': true,
    });

    // ---- sign in (online)
    final session = container.read(sessionProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await session.login(phone, 'owner12345');
    final s = container.read(sessionProvider);
    expect(s.status, AuthStatus.ready);
    expect(s.ctx!.typeKey, 'local_shop');
    final code = await container.read(salesRepoProvider).tillCode();

    // ---- first sync pulls the catalogue
    final sync = container.read(syncProvider.notifier);
    await sync.syncNow();
    expect(container.read(syncProvider).bootstrapped, isTrue);
    final repo = container.read(catalogueRepoProvider);
    final products = await repo.products(limit: 500);
    expect(products.length, greaterThan(20));
    final rice = products.firstWhere((p) => p.product.name == 'Miniket Rice');
    expect(rice.product.allowFraction, isTrue);
    final riceVariant = rice.variants.first;
    final stockBefore = rice.availableOf(riceVariant);
    expect(stockBefore, greaterThan(0));

    // ---- the connection drops
    final client = container.read(apiProvider)..forceOffline = true;
    await sync.syncNow();
    expect(container.read(syncProvider).online, isFalse);

    // ---- three sales with no connection
    final cart = container.read(cartProvider.notifier);
    final sales = container.read(salesRepoProvider);
    final invoices = <String>[];
    for (var i = 0; i < 3; i++) {
      final fresh = (await repo.byId(rice.product.id))!;
      final r = await cart.add(fresh, fresh.variants.first, qtyMilli: 1500 + i * 500); // 1.5 kg, 2 kg, 2.5 kg
      expect(r, isNull);
      final total = container.read(pricedCartProvider).total;
      final bundle = await sales.completeSale(SaleDraft(cart: container.read(cartProvider), payments: [NewPayment('cash', total)]));
      cart.clear();
      invoices.add(bundle.sale.invoiceNo);
      expect(bundle.sale.syncState, 'pending');
    }
    expect(invoices, ['INV-$code-000001', 'INV-$code-000002', 'INV-$code-000003']);
    expect(await (db.select(db.outbox)..where((o) => o.status.equals('pending'))).get(), hasLength(3));

    // stock on the till already reflects the sales that have not synced (6 kg)
    final after = (await repo.byId(rice.product.id))!;
    expect(after.availableOf(after.variants.first), stockBefore - 6000);
    expect(container.read(syncProvider).pending, 3);

    // ---- the connection returns: it syncs by itself
    client.forceOffline = false;
    await sync.syncNow();
    final st = container.read(syncProvider);
    expect(st.online, isTrue);
    expect(st.pending, 0);
    expect(st.failed, 0);
    expect(await (db.select(db.lSales)..where((t) => t.syncState.equals('synced'))).get(), hasLength(3));

    // ---- the server has them, with the same invoice numbers and the right money
    final res = await client.getMap('/sales', query: {'q': 'INV-$code'});
    final items = (res['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((e) => e['invoice_no']).toSet(), invoices.toSet());
    final serverTotal = items.fold<int>(0, (a, e) => a + parsePaisa(e['total']));
    final localTotal = (await db.select(db.lSales).get()).fold<int>(0, (a, e) => a + e.totalP);
    expect(serverTotal, localTotal);

    // ---- and the stock the server holds matches what the till showed
    await sync.syncNow();
    final settled = (await repo.byId(rice.product.id))!;
    expect(settled.availableOf(settled.variants.first), stockBefore - 6000);

    // ---- replaying the same events is harmless
    final rows = await (db.select(db.outbox)..where((o) => o.status.equals('done'))).get();
    expect(rows, hasLength(3));
    await (db.update(db.outbox)).write(const OutboxCompanion(status: Value('pending')));
    await sync.syncNow();
    final again = await client.getMap('/sales', query: {'q': 'INV-$code'});
    expect((again['items'] as List).length, 3); // not 6
    expect(await (db.select(db.outbox)..where((o) => o.status.equals('done'))).get(), hasLength(3));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
