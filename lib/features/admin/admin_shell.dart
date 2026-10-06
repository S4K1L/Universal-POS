import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/lang.dart';
import '../shell/shell.dart';

const _adminNav = [
  NavEntry(id: 'overview', label: 'Overview', icon: Icons.space_dashboard_outlined, activeIcon: Icons.space_dashboard_rounded, route: '/admin/overview'),
  NavEntry(id: 'businesses', label: 'Businesses', icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, route: '/admin/businesses'),
  NavEntry(id: 'plans', label: 'Plans', icon: Icons.sell_outlined, activeIcon: Icons.sell_rounded, route: '/admin/plans'),
  NavEntry(id: 'types', label: 'Types', icon: Icons.category_outlined, activeIcon: Icons.category_rounded, route: '/admin/types'),
  NavEntry(id: 'payments', label: 'Payments', icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, route: '/admin/payments'),
  NavEntry(id: 'audit', label: 'Audit', icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, route: '/admin/audit'),
  NavEntry(id: 'settings', label: 'Settings', icon: Icons.tune_outlined, activeIcon: Icons.tune_rounded, route: '/admin/settings'),
];

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final current = _adminNav.where((e) => loc.startsWith(e.route)).firstOrNull;
    return ShellFrame(
      entries: _adminNav,
      title: context.tr(current?.label ?? 'Platform console'),
      subtitle: context.tr('Universal POS · platform console'),
      showBeacon: false,
      primaryIds: const ['overview', 'businesses', 'plans', 'payments'],
      child: child,
    );
  }
}
