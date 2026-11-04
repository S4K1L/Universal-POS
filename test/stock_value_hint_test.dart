import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:orbin/data/local/database.dart';
import 'package:orbin/features/stock/stock_screen.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('items on the shelf with no cost price are called out instead of valued at zero', (tester) async {
    final rig = await pumpScreen(tester, const StockScreen(), routes: {});
    final branch = rig.ctx.mainBranch!.id;
    Future<void> item(String n, {int? costP, int onHand = 5000}) async {
      await rig.db.into(rig.db.lProducts).insert(LProductsCompanion.insert(id: 'p$n', name: 'Item $n'));
      await rig.db.into(rig.db.lVariants).insert(LVariantsCompanion.insert(id: 'v$n', productId: 'p$n', priceP: 9000, costP: Value(costP)));
      await rig.db.into(rig.db.lStock).insert(LStockCompanion.insert(branchId: branch, variantId: 'v$n', onHandMilli: onHand));
    }

    await item('1', costP: 5000);
    await item('2'); // no cost price set
    await item('3', costP: 0); // cost price of zero
    await settle(tester);

    expect(find.text('2 items have no cost price'), findsOneWidget);
    expect(find.text('No cost price'), findsNWidgets(2));
  });

  testWidgets('with every cost set there is no warning', (tester) async {
    final rig = await pumpScreen(tester, const StockScreen(), routes: {});
    await rig.db.into(rig.db.lProducts).insert(LProductsCompanion.insert(id: 'p1', name: 'Item 1'));
    await rig.db.into(rig.db.lVariants).insert(LVariantsCompanion.insert(id: 'v1', productId: 'p1', priceP: 9000, costP: const Value(5000)));
    await rig.db.into(rig.db.lStock).insert(LStockCompanion.insert(branchId: rig.ctx.mainBranch!.id, variantId: 'v1', onHandMilli: 5000));
    await settle(tester);

    expect(find.textContaining('have no cost price'), findsNothing);
    expect(find.text('No cost price'), findsNothing);
  });
}
