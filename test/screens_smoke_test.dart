import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/features/admin/admin_audit_screen.dart';
import 'package:universal_pos/features/admin/admin_businesses_screen.dart';
import 'package:universal_pos/features/admin/admin_payments_screen.dart';
import 'package:universal_pos/features/admin/admin_settings_screen.dart';
import 'package:universal_pos/features/admin/admin_types_screen.dart';
import 'package:universal_pos/features/customers/customers_screen.dart';
import 'package:universal_pos/features/expenses/expenses_screen.dart';
import 'package:universal_pos/features/orders/orders_screen.dart';
import 'package:universal_pos/features/pos/pos_screen.dart';
import 'package:universal_pos/features/products/product_form.dart';
import 'package:universal_pos/features/products/products_screen.dart';
import 'package:universal_pos/features/purchases/purchases_screen.dart';
import 'package:universal_pos/features/reports/reports_screen.dart';
import 'package:universal_pos/features/sales/sales_screen.dart';
import 'package:universal_pos/features/settings/settings_screen.dart';
import 'package:universal_pos/features/shifts/shifts_screen.dart';
import 'package:universal_pos/features/stock/stock_screen.dart';
import 'package:universal_pos/features/sync/sync_screen.dart';

import 'support/harness.dart';

/// The rest of the app, laid out at phone / tablet / desktop width against real API payloads captured from the
/// running backend. Anything thrown while building or laying out (overflow, bad cast, missing field) fails here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  Map<String, Handler> retail() => retailRoutes(fx);

  final tenantScreens = <(String, Widget Function(), String?)>[
    ('products', () => const ProductsScreen(), null),
    ('stock', () => const StockScreen(), null),
    ('customers', () => const CustomersScreen(), null),
    ('sales', () => const SalesScreen(), null),
    ('purchases', () => const PurchasesScreen(), null),
    ('expenses', () => const ExpensesScreen(), null),
    ('shifts', () => const ShiftsScreen(), null),
    ('reports', () => const ReportsScreen(), null),
    ('settings', () => const SettingsScreen(), null),
    ('sync center', () => const SyncScreen(), null),
    ('sell', () => const PosScreen(), null),
  ];

  for (final (name, size) in [('phone', phone), ('tablet', tablet), ('desktop', desktop)]) {
    for (final (screen, build, _) in tenantScreens) {
      testWidgets('$screen renders on $name', (tester) async {
        await pumpScreen(tester, build(), size: size, routes: retail());
        await settle(tester);
        expectNoError(tester);
      });
    }

    testWidgets('orders (furniture) renders on $name', (tester) async {
      await pumpScreen(tester, const OrdersScreen(), size: size, type: 'furniture', routes: {'GET /orders': (_) => fx['orders_furniture']});
      await settle(tester);
      expect(find.textContaining('Quotations'), findsWidgets);
      expectNoError(tester);
    });

    final adminRoutes = <String, Handler>{
      'GET /admin/tenants': (_) => fx['admin_tenants'],
      'GET /admin/business-types': (_) => fx['admin_types'],
      'GET /admin/plans': (_) => fx['admin_plans'],
      'GET /admin/payment-requests': (_) => fx['admin_requests'],
      'GET /admin/payment-channels': (_) => fx['admin_channels'],
      'GET /admin/audit': (_) => fx['admin_audit'],
      'GET /admin/settings': (_) => fx['admin_settings'],
      'GET /admin/invoices': (_) => fx['admin_invoices'],
      'GET /public/business-types': (_) => fx['public_types'],
    };
    for (final (screen, build) in <(String, Widget Function())>[
      ('businesses', () => const AdminBusinessesScreen()),
      ('business types', () => const AdminTypesScreen()),
      ('payments', () => const AdminPaymentsScreen()),
      ('audit', () => const AdminAuditScreen()),
      ('platform settings', () => const AdminSettingsScreen()),
    ]) {
      testWidgets('admin $screen renders on $name', (tester) async {
        await pumpScreen(tester, build(), size: size, admin: true, routes: adminRoutes);
        await settle(tester);
        expectNoError(tester);
      });
    }
  }

  // The add-product form is the clearest place where the business type shows: the fields are not the same.
  for (final (type, expected) in [
    ('supershop', ['Brand']),
    ('cosmetic', ['Skin type', 'Shade']),
    ('furniture', ['Material', 'Warranty']),
    ('pharmacy', ['Generic name']),
  ]) {
    testWidgets('add-product form for $type shows its own fields', (tester) async {
      await pumpScreen(tester, Consumer(builder: (context, ref, _) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => showProductForm(context, ref), child: const Text('open')))))
          , size: desktop, type: type, routes: retail());
      await settle(tester);
      await tester.tap(find.text('open'));
      await settle(tester, frames: 6);
      for (final label in expected) {
        expect(find.textContaining(label), findsWidgets, reason: '$type form should show "$label"');
      }
      expectNoError(tester);
    });
  }
}
