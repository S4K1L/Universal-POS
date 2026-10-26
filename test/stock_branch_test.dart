import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/data/local/database.dart';
import 'package:universal_pos/data/repos/catalogue_repo.dart';

Future<void> addItem(AppDatabase db, String n, {required Map<String, int> stock, int costP = 5000}) async {
  await db.into(db.lProducts).insert(LProductsCompanion.insert(id: 'p$n', name: 'Item $n'));
  await db.into(db.lVariants).insert(LVariantsCompanion.insert(id: 'v$n', productId: 'p$n', priceP: 9000, costP: Value(costP)));
  for (final e in stock.entries) {
    await db.into(db.lStock).insert(LStockCompanion.insert(branchId: e.key, variantId: 'v$n', onHandMilli: e.value));
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a till counts its own branch, not whichever branch happened to sync last', () async {
    await addItem(db, '1', stock: {'main': 10000, 'second': 0}); // the second branch holds none of it
    final main = CatalogueRepo(db, branchId: () => 'main');
    final second = CatalogueRepo(db, branchId: () => 'second');
    final all = CatalogueRepo(db);

    expect((await main.products()).single.totalAvailable, 10000);
    expect((await second.products()).single.totalAvailable, 0);
    expect((await all.products()).single.totalAvailable, 10000); // no branch: everything
  });

  test("another branch's unsynced sale does not reduce this till's stock", () async {
    await addItem(db, '1', stock: {'main': 10000});
    for (final branch in ['main', 'second']) {
      await db.into(db.outbox).insert(OutboxCompanion.insert(
            id: 'sale-$branch',
            type: 'sale.create',
            payload: jsonEncode({
              'id': 's-$branch',
              'branch_id': branch,
              'lines': [
                {'variant_id': 'v1', 'qty': '2', 'unit_factor': '1'}
              ]
            }),
            occurredAt: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
          ));
    }
    final repo = CatalogueRepo(db, branchId: () => 'main');
    expect((await repo.products()).single.totalAvailable, 8000); // only the sale made at this branch
  });

  test('a catalogue larger than SQLite allows in one IN (…) still loads whole', () async {
    await db.batch((b) {
      for (var i = 0; i < 1500; i++) {
        b.insert(db.lProducts, LProductsCompanion.insert(id: 'p$i', name: 'Item ${i.toString().padLeft(4, '0')}'));
        b.insert(db.lVariants, LVariantsCompanion.insert(id: 'v$i', productId: 'p$i', priceP: 9000, costP: const Value(5000)));
        b.insert(db.lStock, LStockCompanion.insert(branchId: 'main', variantId: 'v$i', onHandMilli: 2000));
      }
    });
    final all = await CatalogueRepo(db, branchId: () => 'main').products(limit: 100000, stockedOnly: true);
    expect(all, hasLength(1500));
    expect(all.fold<int>(0, (a, p) => a + p.totalAvailable), 1500 * 2000);
  });

  test('upgrading a device from the one-row-per-item stock table re-downloads it', () async {
    final dir = Directory.systemTemp.createTempSync('stock_upgrade');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/till.sqlite');

    final fresh = AppDatabase(NativeDatabase(file));
    await fresh.kvSet('sync_cursor', '2286');
    await fresh.kvSet('bootstrapped', '1');
    await fresh.kvSet('tenant_id', 'keep-me');
    // put the database back the way version 1 left it
    await fresh.customStatement('DROP TABLE l_stock');
    await fresh.customStatement('CREATE TABLE l_stock (variant_id TEXT NOT NULL PRIMARY KEY, on_hand_milli INTEGER NOT NULL)');
    await fresh.customStatement("INSERT INTO l_stock VALUES ('v1', 5000)");
    await fresh.customStatement('PRAGMA user_version = 1');
    await fresh.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect(await upgraded.select(upgraded.lStock).get(), isEmpty);
    await upgraded.into(upgraded.lStock).insert(LStockCompanion.insert(branchId: 'main', variantId: 'v1', onHandMilli: 1));
    expect(await upgraded.kvGet('sync_cursor'), isNull); // so the next sync fetches everything, with branches
    expect(await upgraded.kvGet('bootstrapped'), isNull);
    expect(await upgraded.kvGet('tenant_id'), 'keep-me'); // who this device belongs to is untouched
  });
}
