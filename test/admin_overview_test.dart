import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/ui/dash.dart';
import 'package:universal_pos/features/admin/admin_overview_screen.dart';

import 'support/harness.dart';

/// The platform console's home: the revenue headline, the shortcuts (with the number of payments waiting), and a
/// breakdown of how the businesses stand.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();
  final data = {
    ...(fx['admin_overview'] as Map).cast<String, dynamic>(),
    'pending_payments': 3,
    'by_state': {'active': 11, 'trialing': 4, 'grace': 2, 'expired': 1},
    'tenants': 18,
  };

  for (final (name, size) in [('desktop', desktop), ('tablet', tablet), ('phone', phone)]) {
    testWidgets('overview lays out cleanly on $name', (tester) async {
      await pumpScreen(tester, const AdminOverviewScreen(), size: size, admin: true, routes: {'GET /admin/overview': (_) => data});
      await settle(tester, frames: 25);
      expect(find.text('MONTHLY RECURRING REVENUE'), findsOneWidget);
      expect(find.text('Subscription health'), findsOneWidget);
      expect(find.text('3 payments are waiting for your review'), findsOneWidget);
      expect(find.text('3'), findsWidgets, reason: 'the payments shortcut carries the number waiting');

      // every shortcut tile is the same size, whichever row it lands on
      final sizes = {for (var i = 0; i < 5; i++) tester.getSize(find.byType(QuickAction).at(i))};
      expect(sizes, hasLength(1));

      // the health bar's legend adds up to the number of businesses
      for (final label in ['Active', 'On trial', 'In grace period', 'Expired']) {
        expect(find.text(label), findsOneWidget);
      }
      expectNoError(tester);
    });
  }

  testWidgets('with nothing to show yet it still reads as a finished page', (tester) async {
    await pumpScreen(tester, const AdminOverviewScreen(), size: desktop, admin: true, routes: {'GET /admin/overview': (_) => fx['admin_overview']});
    await settle(tester, frames: 25);
    expect(find.text('No approved payments yet'), findsOneWidget);
    expect(find.textContaining('waiting for your review'), findsNothing);
    expectNoError(tester);
  });
}
