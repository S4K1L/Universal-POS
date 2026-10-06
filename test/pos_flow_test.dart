import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/data/session.dart';
import 'package:universal_pos/data/sync/sync_engine.dart';
import 'package:universal_pos/features/pos/pos_screen.dart';

import 'support/harness.dart';

/// The till, driven like a cashier: catalogue arrives by sync, items are tapped, the sale is paid and receipted —
/// with the connection down — and lands in the outbox ready to sync.
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
            for (final (i, p) in products.indexed) {'seq': 100 + i, 'entity': 'stock', 'id': 'stk-$i', 'op': 'upsert', 'data': {'id': 'stk-$i', 'variant_id': (p['variants'] as List).first['id'], 'branch_id': 'branch-1', 'on_hand': '40.000'}},
          ],
        },
    'GET /tenants/me/context': (_) => fx['context_supershop'],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();
  final products = (fx['products_supershop']['items'] as List).cast<Map<String, dynamic>>();
  final plain = products.firstWhere((p) => p['allow_fraction'] == false && (p['variants'] as List).length == 1);

  for (final (name, size) in [('desktop', desktop), ('phone', phone)]) {
    testWidgets('ring up, pay and receipt a sale with the connection down ($name)', (tester) async {
      final rig = await pumpScreen(tester, const PosScreen(), size: size, routes: _routes(fx));
      final sync = rig.container.read(syncProvider.notifier);
      sync.start();
      await drive(tester, sync.syncNow());
      await settle(tester);
      final st = rig.container.read(syncProvider);
      expect(st.bootstrapped, isTrue, reason: 'online=${st.online} error=${st.error} calls=${rig.adapter.calls}');

      // the catalogue that arrived by sync is on screen
      expect(find.text(plain['name'] as String), findsWidgets);

      // …then the internet goes away
      rig.container.read(apiProvider).forceOffline = true;

      await tester.tap(find.text(plain['name'] as String).first);
      await settle(tester, frames: 4);
      if (size == phone) {
        expect(find.text('View sale'), findsOneWidget);
        await tester.tap(find.text('View sale'));
        await settle(tester, frames: 4);
      }
      expect(find.text('Current sale'), findsOneWidget);
      await tester.tap(find.text('Charge'));
      await settle(tester, frames: 6);
      expect(find.text('Take payment'), findsOneWidget);

      await tester.tap(find.textContaining('Complete sale'));
      await settle(tester, frames: 8);
      expect(find.text('Sale complete'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final outbox = await drive(tester, rig.db.select(rig.db.outbox).get());
      expect(outbox.where((o) => o.type == 'sale.create' && o.status == 'pending'), hasLength(1));
      final payload = jsonDecode(outbox.first.payload) as Map<String, dynamic>;
      expect(payload['invoice_no'], 'INV-D01-000001');
      expect((payload['lines'] as List).first['variant_id'], (plain['variants'] as List).first['id']);
      final sales = await drive(tester, rig.db.select(rig.db.lSales).get());
      expect(sales, hasLength(1));
      expect(sales.first.syncState, 'pending');
      sync.stop();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
