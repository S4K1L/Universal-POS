import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/data/local/database.dart';

void main() {
  test('resetting the catalogue forgets what was downloaded but never what this till did', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.lCategories).insert(LCategoriesCompanion.insert(id: 'c1', name: 'Hair'));
    await db.kvSet('sync_cursor', '2286');
    await db.kvSet('bootstrapped', '1');
    await db.into(db.outbox).insert(OutboxCompanion.insert(id: 'ev1', type: 'sale.create', payload: jsonEncode({'id': 's1'}), occurredAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc()));

    await db.resetCatalogue();

    expect(await db.select(db.lCategories).get(), isEmpty);
    expect(await db.kvGet('sync_cursor'), isNull); // the next sync starts from the beginning
    expect(await db.kvGet('bootstrapped'), isNull);
    expect(await db.select(db.outbox).get(), hasLength(1)); // an unsynced sale is never thrown away
  });
}
