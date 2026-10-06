import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/i18n/lang.dart';
import 'package:universal_pos/features/auth/login_screen.dart';
import 'package:universal_pos/features/billing/billing_screen.dart';
import 'package:universal_pos/features/customers/customers_screen.dart';
import 'package:universal_pos/features/dashboard/dashboard_screen.dart';
import 'package:universal_pos/features/expenses/expenses_screen.dart';
import 'package:universal_pos/features/products/products_screen.dart';
import 'package:universal_pos/features/purchases/purchases_screen.dart';
import 'package:universal_pos/features/reports/reports_screen.dart';
import 'package:universal_pos/features/sales/sales_screen.dart';
import 'package:universal_pos/features/settings/settings_screen.dart';
import 'package:universal_pos/features/shifts/shifts_screen.dart';
import 'package:universal_pos/features/stock/stock_screen.dart';
import 'package:universal_pos/features/sync/sync_screen.dart';
import 'package:universal_pos/features/pos/pos_screen.dart';

import 'support/harness.dart';

/// The same screens in Bangla: translated text, Bangla digits, and Bangla's taller glyphs still fit on a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  for (final (name, size) in [('phone', phone), ('desktop', desktop)]) {
    testWidgets('login in Bangla on $name', (tester) async {
      await pumpScreen(tester, const LoginScreen(), size: size, signedOut: true, lang: AppLang.bn);
      await settle(tester, frames: 3);
      expect(find.text('আবার স্বাগতম'), findsOneWidget);
      expect(find.text('সাইন ইন'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dashboard in Bangla on $name', (tester) async {
      await pumpScreen(tester, const DashboardScreen(), size: size, lang: AppLang.bn, routes: {'GET /reports/dashboard': (_) => fx['dashboard_supershop'], 'GET /orders': (_) => {'items': []}});
      await settle(tester);
      expect(find.text('সেরা বিক্রীত'), findsOneWidget);
      expect(find.textContaining('আজকের বিক্রি'), findsWidgets);
      expect(find.textContaining('৳'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('billing in Bangla on $name', (tester) async {
      await pumpScreen(tester, const BillingScreen(), size: size, lang: AppLang.bn, routes: {
        'GET /billing/subscription': (_) => fx['billing_sub'],
        'GET /billing/plans': (_) => fx['billing_plans'],
        'GET /billing/payment-requests': (_) => fx['billing_requests'],
      });
      await settle(tester);
      expect(find.textContaining('১,৯৯৯'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('customers screen shows the business’s own term (Members) in Bangla', (tester) async {
    await pumpScreen(tester, const CustomersScreen(), size: phone, lang: AppLang.bn, routes: {
      'GET /customers': (_) => {'items': [], 'total': 0},
      'GET /customers/dues': (_) => {'total': '0.00', 'count': 0, 'items': []},
    });
    await settle(tester);
    expect(find.textContaining('সদস্য'), findsWidgets); // the supershop type calls customers "Members"
    expect(tester.takeException(), isNull);
  });

  // Bangla runs wider and taller than English: the rest of the till must still fit a 5-inch screen.
  for (final (screen, build) in <(String, Widget Function())>[
    ('products', () => const ProductsScreen()),
    ('stock', () => const StockScreen()),
    ('sales', () => const SalesScreen()),
    ('purchases', () => const PurchasesScreen()),
    ('expenses', () => const ExpensesScreen()),
    ('shifts', () => const ShiftsScreen()),
    ('reports', () => const ReportsScreen()),
    ('settings', () => const SettingsScreen()),
    ('sync center', () => const SyncScreen()),
    ('sell', () => const PosScreen()),
  ]) {
    testWidgets('$screen in Bangla fits a phone', (tester) async {
      await pumpScreen(tester, build(), size: phone, lang: AppLang.bn, routes: retailRoutes(fx));
      await settle(tester);
      expectNoError(tester);
    });
  }
}
