import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../core/ui/brand.dart';
import '../data/platform_status.dart';
import '../data/session.dart';
import '../features/admin/admin_audit_screen.dart';
import '../features/admin/admin_businesses_screen.dart';
import '../features/admin/admin_overview_screen.dart';
import '../features/admin/admin_payments_screen.dart';
import '../features/admin/admin_plans_screen.dart';
import '../features/admin/admin_settings_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/admin_types_screen.dart';
import '../features/auth/device_setup_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/billing/billing_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/pos/pos_screen.dart';
import '../features/products/products_screen.dart';
import '../features/purchases/purchases_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/shell.dart';
import '../features/shifts/shifts_screen.dart';
import '../features/stock/stock_screen.dart';
import '../features/sync/sync_screen.dart';

/// Bridges Riverpod to go_router: the router re-evaluates its redirect whenever the session changes.
class _SessionListenable extends ChangeNotifier {
  void poke() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable();
  ref.listen(sessionProvider.select((s) => (s.status, s.isAdmin)), (_, __) => listenable.poke());
  ref.listen(platformStatusProvider.select((p) => p.maintenance), (_, __) => listenable.poke());
  ref.onDispose(listenable.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final s = ref.read(sessionProvider);
    final loc = state.matchedLocation;
    // While the platform is in maintenance every business user waits on one screen; the console stays open so the
    // admin can switch it off. The screen lets go on its own when maintenance ends.
    final maintenance = ref.read(platformStatusProvider).maintenance;
    switch (s.status) {
      case AuthStatus.booting:
        return loc == '/splash' ? null : '/splash';
      case AuthStatus.signedOut:
        return loc == '/login' ? null : '/login';
      case AuthStatus.needsDevice:
        if (maintenance) return loc == '/maintenance' ? null : '/maintenance';
        return loc == '/setup' ? null : '/setup';
      case AuthStatus.ready:
        if (s.isAdmin) return loc.startsWith('/admin') ? null : '/admin/overview';
        if (maintenance) return loc == '/maintenance' ? null : '/maintenance';
        if (loc.startsWith('/admin') || const ['/login', '/splash', '/setup', '/maintenance', '/'].contains(loc)) return '/dashboard';
        return null;
    }
  }

  Page<void> fade(Widget child, GoRouterState s) => CustomTransitionPage<void>(
        key: s.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 160),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: c),
      );

  GoRoute r(String path, Widget Function() w) => GoRoute(path: path, pageBuilder: (c, s) => fade(w(), s));

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: redirect,
    routes: [
      r('/splash', () => const _Splash()),
      r('/login', () => const LoginScreen()),
      r('/setup', () => const DeviceSetupScreen()),
      r('/maintenance', () => const MaintenanceScreen()),
      ShellRoute(
        builder: (c, s, child) => TenantShell(child: child),
        routes: [
          r('/dashboard', () => const DashboardScreen()),
          r('/pos', () => const PosScreen()),
          r('/orders', () => const OrdersScreen()),
          r('/sales', () => const SalesScreen()),
          r('/products', () => const ProductsScreen()),
          r('/stock', () => const StockScreen()),
          r('/purchases', () => const PurchasesScreen()),
          r('/customers', () => const CustomersScreen()),
          r('/expenses', () => const ExpensesScreen()),
          r('/shifts', () => const ShiftsScreen()),
          r('/reports', () => const ReportsScreen()),
          r('/settings', () => const SettingsScreen()),
          r('/billing', () => const BillingScreen()),
          r('/sync', () => const SyncScreen()),
        ],
      ),
      ShellRoute(
        builder: (c, s, child) => AdminShell(child: child),
        routes: [
          r('/admin/overview', () => const AdminOverviewScreen()),
          r('/admin/businesses', () => const AdminBusinessesScreen()),
          r('/admin/plans', () => const AdminPlansScreen()),
          r('/admin/types', () => const AdminTypesScreen()),
          r('/admin/payments', () => const AdminPaymentsScreen()),
          r('/admin/audit', () => const AdminAuditScreen()),
          r('/admin/settings', () => const AdminSettingsScreen()),
        ],
      ),
    ],
  );
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.t.canvas,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              BrandMark(size: 72),
              SizedBox(height: 16),
              BrandWordmark(size: 24),
            ]),
          ),
        ),
      );
}
