import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/lang.dart';
import '../shell/shell.dart';
import 'admin_approvals_screen.dart';

const _adminNav = [
  NavEntry(id: 'overview', label: 'Overview', icon: Icons.space_dashboard_outlined, activeIcon: Icons.space_dashboard_rounded, route: '/admin/overview'),
  NavEntry(id: 'approvals', label: 'Approvals', icon: Icons.how_to_reg_outlined, activeIcon: Icons.how_to_reg_rounded, route: '/admin/approvals'),
  NavEntry(id: 'businesses', label: 'Businesses', icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, route: '/admin/businesses'),
  NavEntry(id: 'users', label: 'Users', icon: Icons.people_outline_rounded, activeIcon: Icons.people_alt_rounded, route: '/admin/users'),
  NavEntry(id: 'plans', label: 'Plans', icon: Icons.sell_outlined, activeIcon: Icons.sell_rounded, route: '/admin/plans'),
  NavEntry(id: 'types', label: 'Types', icon: Icons.category_outlined, activeIcon: Icons.category_rounded, route: '/admin/types'),
  NavEntry(id: 'payments', label: 'Payments', icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, route: '/admin/payments'),
  NavEntry(id: 'audit', label: 'Audit', icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, route: '/admin/audit'),
  NavEntry(id: 'settings', label: 'Settings', icon: Icons.tune_outlined, activeIcon: Icons.tune_rounded, route: '/admin/settings'),
];

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(pendingApprovalsProvider);
    final entries = [
      for (final e in _adminNav) e.id == 'approvals' ? NavEntry(id: e.id, label: e.label, icon: e.icon, activeIcon: e.activeIcon, route: e.route, badge: waiting) : e,
    ];
    final loc = GoRouterState.of(context).matchedLocation;
    final current = _adminNav.where((e) => loc.startsWith(e.route)).firstOrNull;
    return ShellFrame(
      entries: entries,
      title: context.tr(current?.label ?? 'Platform console'),
      subtitle: context.tr('Orbin · platform console'),
      showBeacon: false,
      primaryIds: const ['overview', 'approvals', 'businesses', 'payments'],
      child: child,
    );
  }
}
