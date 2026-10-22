import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/data/models/cart.dart';
import 'package:universal_pos/data/sync/sync_engine.dart';
import 'package:universal_pos/features/pos/cart_controller.dart';
import 'package:universal_pos/features/pos/pos_screen.dart';

import 'support/harness.dart';

/// The sale's line list as the cashier uses it: lines arrive, change, and leave — each with its animation — and the
/// numbers always settle on the right values.
Map<String, Handler> _routes(Fixtures fx) {
  final products = (fx['products_supershop']['items'] as List).cast<Map<String, dynamic>>();
  return {
    'GET http://fake/health': (_) => {'status': 'ok'},
    'POST /sync/push': (o) => {'results': []},
    'GET /sync/pull': (_) => {
          'cursor': 20,
          'has_more': false,
          'changes': [
            for (final (i, p) in products.indexed) {'seq': i + 1, 'entity': 'product', 'id': p['id'], 'op': 'upsert', 'data': p},
            for (final (i, p) in products.indexed) {'seq': 100 + i, 'entity': 'stock', 'id': 'stk-$i', 'op': 'upsert', 'data': {'id': 'stk-$i', 'variant_id': (p['variants'] as List).first['id'], 'branch_id': 'branch-1', 'on_hand': '50.000'}},
          ],
        },
    'GET /tenants/me/context': (_) => fx['context_supershop'],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  for (final (name, size) in [('desktop', desktop), ('phone', phone)]) {
    testWidgets('cart lines animate in, change, swipe away and clear ($name)', (tester) async {
      final rig = await pumpScreen(tester, const PosScreen(), size: size, routes: _routes(fx));
      final sync = rig.container.read(syncProvider.notifier)..start();
      await drive(tester, sync.syncNow());
      await settle(tester);
      final cart = rig.container.read(cartProvider.notifier);
      CartState state() => rig.container.read(cartProvider);

      // two different items go in
      await tester.tap(find.text('Atta 2 kg').first);
      await settle(tester, frames: 4);
      await tester.tap(find.text('Baby Diaper (M, 44)').first);
      await settle(tester, frames: 4);
      expect(state().lines, hasLength(2));
      if (size == phone) {
        await tester.tap(find.text('View sale'));
        await settle(tester, frames: 4);
      }
      expect(find.byKey(const ValueKey('lines')), findsOneWidget);
      expectNoError(tester);

      // the plus button raises the quantity of the first line; the figure rolls to the new value and settles
      final key = state().lines.first.key;
      final before = state().lines.first.qtyMilli;
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pump(const Duration(milliseconds: 60));
      expectNoError(tester); // mid-animation: old and new number are both on screen
      await settle(tester, frames: 6);
      expect(state().lines.first.qtyMilli, greaterThan(before));
      expect(state().lines.first.key, key, reason: 'a quantity change keeps the same line');
      expect(find.text('2'), findsWidgets);

      // swipe the second line to the left to delete it
      final second = find.byKey(ValueKey('line-${state().lines[1].key}'));
      expect(second, findsOneWidget);
      await tester.drag(second, const Offset(-600, 0));
      await settle(tester, frames: 8);
      expect(state().lines, hasLength(1));
      expect(find.byKey(const ValueKey('lines')), findsOneWidget);
      expectNoError(tester);

      // the trash button removes the last one, and the empty state fades back in
      await tester.tap(find.byTooltip('Remove').first);
      await settle(tester, frames: 8);
      expect(state().lines, isEmpty);
      expect(find.text('Ready to sell'), findsOneWidget);

      // clearing a sale with several lines removes them all
      if (size == phone) {
        await tester.tapAt(const Offset(195, 20)); // the sale sheet covers the catalogue: dismiss it by its barrier
        await settle(tester, frames: 4);
      }
      await tester.tap(find.text('Atta 2 kg').first);
      await settle(tester, frames: 3);
      await tester.tap(find.text('Baby Diaper (M, 44)').first);
      await settle(tester, frames: 3);
      expect(state().lines, hasLength(2));
      if (size == phone) {
        await tester.tap(find.text('View sale'));
        await settle(tester, frames: 4);
      }
      cart.clear();
      await settle(tester, frames: 6);
      expect(state().lines, isEmpty);
      expect(find.text('Ready to sell'), findsOneWidget);
      expectNoError(tester);

      sync.stop();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
