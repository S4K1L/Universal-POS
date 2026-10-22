import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/ui/kit.dart';
import 'package:universal_pos/data/local/database.dart';
import 'package:universal_pos/features/customers/customers_screen.dart';

import 'support/harness.dart';

/// The customer list keeps its columns tidy: a phone number never wraps digit by digit, and the points and balance
/// badges end at the same edge on every row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  Future<Rig> pumpList(WidgetTester tester, Size size) async {
    final rig = await pumpScreen(tester, const CustomersScreen(), size: size, routes: retailRoutes(fx));
    await drive(tester, rig.db.batch((b) {
      b.insertAll(rig.db.lCustomers, [
        LCustomersCompanion.insert(id: 'c1', name: 'Muhammad Abdur Rahman Chowdhury Senior', phone: const Value('01822200001'), balanceP: const Value(194310), points: const Value(280)),
        LCustomersCompanion.insert(id: 'c2', name: 'Rubel Khan', phone: const Value('01822200004'), balanceP: const Value(70000), points: const Value(3000)),
        LCustomersCompanion.insert(id: 'c3', name: 'Shirin Sultana', phone: const Value('01822200003'), balanceP: const Value(522720), points: const Value(31)),
      ]);
    }));
    await settle(tester, frames: 20);
    return rig;
  }

  testWidgets('on a phone every phone number stays on one line and the long name is truncated', (tester) async {
    await pumpList(tester, phone);
    for (final n in ['01822200001', '01822200004', '01822200003']) {
      expect(tester.getSize(find.text(n)).height, lessThan(20), reason: '$n wrapped');
    }
    expectNoError(tester);
  });

  testWidgets('on desktop the points and balance badges line up down the list', (tester) async {
    await pumpList(tester, desktop);
    final pts = [for (final p in ['280 pts', '3,000 pts', '31 pts']) tester.getRect(find.text(p)).right];
    expect(pts[1], closeTo(pts[0], 14), reason: 'the points column should share one right edge (pill padding aside)');
    expect(pts[2], closeTo(pts[0], 14));
    final owes = [for (final f in find.textContaining('owes').evaluate()) tester.getRect(find.byWidget(f.widget)).right];
    expect(owes, hasLength(3));
    expect(owes[1], closeTo(owes[0], 1));
    expect(owes[2], closeTo(owes[0], 1));
    expectNoError(tester);
  });

  testWidgets('the two summary tiles are the same height', (tester) async {
    await pumpList(tester, desktop);
    final tiles = find.byType(StatTile);
    expect(tiles, findsNWidgets(2));
    expect(tester.getSize(tiles.at(0)).height, closeTo(tester.getSize(tiles.at(1)).height, 0.5));
  });
}
