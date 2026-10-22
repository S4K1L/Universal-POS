import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/features/auth/login_screen.dart';
import 'package:universal_pos/features/billing/billing_screen.dart';
import 'package:universal_pos/features/dashboard/dashboard_screen.dart';
import 'package:universal_pos/features/admin/admin_overview_screen.dart';
import 'package:universal_pos/features/admin/admin_plans_screen.dart';

import 'support/harness.dart';

/// Every screen, at phone / tablet / desktop width, with real API payloads. A RenderFlex overflow or any thrown
/// error fails the test — this is the "does it lay out on a 5-inch till and a 27-inch monitor" check.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  for (final (name, size) in [('phone', phone), ('tablet', tablet), ('desktop', desktop)]) {
    testWidgets('login renders on $name', (tester) async {
      await pumpScreen(tester, const LoginScreen(), size: size, signedOut: true);
      await settle(tester, frames: 3);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dashboard renders on $name', (tester) async {
      await pumpScreen(tester, const DashboardScreen(), size: size, routes: {'GET /reports/dashboard': (_) => fx['dashboard_supershop'], 'GET /orders': (_) => {'items': []}});
      await settle(tester);
      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(find.text('Best sellers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('billing shows the plans exactly as the admin priced them on $name', (tester) async {
      await pumpScreen(tester, const BillingScreen(), size: size, routes: {
        'GET /billing/subscription': (_) => fx['billing_sub'],
        'GET /billing/plans': (_) => fx['billing_plans'],
        'GET /billing/payment-requests': (_) => fx['billing_requests'],
      });
      await settle(tester);
      expect(find.text('Business'), findsWidgets);
      expect(find.textContaining('1,999'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin overview renders on $name', (tester) async {
      await pumpScreen(tester, const AdminOverviewScreen(), size: size, admin: true, routes: {'GET /admin/overview': (_) => fx['admin_overview']});
      await settle(tester);
      expect(find.text('Businesses'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin plans editor renders on $name', (tester) async {
      await pumpScreen(tester, const AdminPlansScreen(), size: size, admin: true, routes: {'GET /admin/plans': (_) => fx['admin_plans']});
      await settle(tester);
      expect(find.text('Starter'), findsWidgets);
      expect(find.text('Per month'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
