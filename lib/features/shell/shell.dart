import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../core/util/responsive.dart';
import '../../data/models/context.dart';
import '../../data/providers.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

class NavEntry {
  const NavEntry({required this.id, required this.label, required this.icon, required this.route, this.lockedReason, this.activeIcon});
  final String id, label, route;
  final IconData icon;
  final IconData? activeIcon;
  final String? lockedReason; // plan | permission
}

const _icons = <String, (IconData, IconData)>{
  'dashboard': (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  'pos': (Icons.point_of_sale_outlined, Icons.point_of_sale_rounded),
  'orders': (Icons.request_quote_outlined, Icons.request_quote_rounded),
  'sales': (Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  'products': (Icons.category_outlined, Icons.category_rounded),
  'stock': (Icons.inventory_2_outlined, Icons.inventory_2_rounded),
  'purchases': (Icons.local_shipping_outlined, Icons.local_shipping_rounded),
  'customers': (Icons.groups_outlined, Icons.groups_rounded),
  'expenses': (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  'shifts': (Icons.schedule_outlined, Icons.schedule_rounded),
  'reports': (Icons.insights_outlined, Icons.insights_rounded),
  'settings': (Icons.tune_outlined, Icons.tune_rounded),
  'billing': (Icons.workspace_premium_outlined, Icons.workspace_premium_rounded),
};

/// The business's own words: a pharmacy's "Customers" are "Patients", a furniture showroom's are "Clients".
String moduleLabel(TenantContext ctx, String id, String fallback) {
  switch (id) {
    case 'customers':
      return '${ctx.term('customer', 'Customer')}s';
    case 'products':
      return '${ctx.term('product', 'Product')}s';
    case 'pos':
      return 'Sell';
  }
  return fallback;
}

List<NavEntry> navFor(TenantContext ctx) {
  final out = <NavEntry>[];
  for (final m in ctx.modules) {
    if (m.lockedReason == 'capability') continue; // a local shop never sees "Orders" or "Shifts"
    final icons = _icons[m.id] ?? (Icons.circle_outlined, Icons.circle);
    out.add(NavEntry(id: m.id, label: moduleLabel(ctx, m.id, m.label), icon: icons.$1, activeIcon: icons.$2, route: '/${m.id}', lockedReason: m.available ? null : m.lockedReason));
  }
  return out;
}

/// Shared frame: a floating ink "dock" on wide screens, bottom navigation on phones.
class ShellFrame extends ConsumerWidget {
  const ShellFrame({super.key, required this.entries, required this.child, required this.title, this.subtitle, this.showBeacon = true, this.banner, this.onLocked, this.primaryIds = const []});
  final List<NavEntry> entries;
  final Widget child;
  final String title;
  final String? subtitle;
  final bool showBeacon;
  final Widget? banner;
  final void Function(NavEntry)? onLocked;
  final List<String> primaryIds;

  String _selected(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (final e in entries) {
      if (loc == e.route || loc.startsWith('${e.route}/')) return e.id;
    }
    return entries.isEmpty ? '' : entries.first.id;
  }

  void _go(BuildContext context, NavEntry e) {
    if (e.lockedReason != null && onLocked != null) {
      onLocked!(e);
    } else {
      context.go(e.route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final selected = _selected(context);
    final wide = context.isWide;
    final body = Column(children: [
      _TopBar(title: title, subtitle: subtitle, showBeacon: showBeacon, compact: !wide),
      if (banner != null) banner!,
      Expanded(child: child),
    ]);

    if (wide) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: SafeArea(
          child: Row(children: [
            Padding(padding: const EdgeInsets.fromLTRB(12, 12, 0, 12), child: _Dock(entries: entries, selected: selected, onTap: (e) => _go(context, e))),
            Expanded(child: body),
          ]),
        ),
      );
    }

    // phone: primary destinations in the bar, everything else under "More"
    final prim = <NavEntry>[];
    for (final id in primaryIds) {
      for (final e in entries) {
        if (e.id == id && e.lockedReason == null) prim.add(e);
      }
    }
    for (final e in entries) {
      if (prim.length >= 4) break;
      if (!prim.contains(e) && e.lockedReason == null && e.id != 'settings' && e.id != 'billing') prim.add(e);
    }
    final bar = prim.take(4).toList();
    final moreSelected = !bar.any((e) => e.id == selected);
    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: _BottomBar(
        items: bar,
        selected: selected,
        moreSelected: moreSelected,
        onTap: (e) => _go(context, e),
        onMore: () => _showMore(context, entries, selected),
      ),
    );
  }

  void _showMore(BuildContext context, List<NavEntry> all, String selected) {
    showPanel<void>(
      context,
      builder: (ctx) => PanelScaffold(
        title: context.tr('More'),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            for (final e in all)
              Surface(
                onTap: () {
                  Navigator.pop(ctx);
                  _go(context, e);
                },
                color: e.id == selected ? context.t.accentSoft : context.t.surface2,
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Icon(e.activeIcon ?? e.icon, size: 26, color: e.lockedReason != null ? context.t.faint : context.t.accentDeep),
                    if (e.lockedReason != null) Positioned(right: -8, top: -6, child: Icon(Icons.lock_rounded, size: 13, color: context.t.warning)),
                  ]),
                  const SizedBox(height: 8),
                  Text(context.tr(e.label), style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center, maxLines: 2),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dock extends ConsumerWidget {
  const _Dock({required this.entries, required this.selected, required this.onTap});
  final List<NavEntry> entries;
  final String selected;
  final void Function(NavEntry) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final ctx = ref.watch(sessionProvider.select((s) => s.ctx));
    final main = entries.where((e) => e.id != 'settings' && e.id != 'billing').toList();
    final foot = entries.where((e) => e.id == 'settings' || e.id == 'billing').toList();
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(children: [
        Tooltip(message: ctx?.businessName ?? 'Universal POS', child: BrandMark(size: 42, color: ctx?.accent)),
        const SizedBox(height: 14),
        Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 22), color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [for (final e in main) _DockItem(e, e.id == selected, () => onTap(e))]),
        ),
        for (final e in foot) _DockItem(e, e.id == selected, () => onTap(e)),
      ]),
    );
  }
}

class _DockItem extends StatefulWidget {
  const _DockItem(this.e, this.selected, this.onTap);
  final NavEntry e;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final e = widget.e;
    final locked = e.lockedReason != null;
    final sel = widget.selected;
    final fg = sel ? t.accent : (locked ? t.onInkMuted.withValues(alpha: 0.6) : (_hover ? t.onInk : t.onInkMuted));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? t.accent.withValues(alpha: 0.16) : (_hover ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(sel ? (e.activeIcon ?? e.icon) : e.icon, size: 25, color: fg),
              if (locked) Positioned(right: -7, top: -5, child: Icon(Icons.lock_rounded, size: 12, color: t.warning)),
            ]),
            const SizedBox(height: 5),
            Text(context.tr(e.label), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg, height: 1.1, fontVariations: const [FontVariation('wght', 650)])),
          ]),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.items, required this.selected, required this.moreSelected, required this.onTap, required this.onMore});
  final List<NavEntry> items;
  final String selected;
  final bool moreSelected;
  final void Function(NavEntry) onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(color: t.surface, border: Border(top: BorderSide(color: t.outline))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (final e in items) Expanded(child: _BarItem(label: context.tr(e.label), icon: e.id == selected ? (e.activeIcon ?? e.icon) : e.icon, on: e.id == selected, onTap: () => onTap(e))),
            Expanded(child: _BarItem(label: context.tr('More'), icon: Icons.grid_view_rounded, on: moreSelected, onTap: onMore)),
          ]),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.label, required this.icon, required this.on, required this.onTap});
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(color: on ? t.accentSoft : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 23, color: on ? t.accentDeep : t.muted),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: on ? t.accentDeep : t.muted, fontVariations: const [FontVariation('wght', 650)]), maxLines: 1),
      ]),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title, this.subtitle, required this.showBeacon, required this.compact});
  final String title;
  final String? subtitle;
  final bool showBeacon, compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    final lang = ref.watch(langProvider);
    final userName = (session.user?['name'] as String?) ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, compact ? 10 : 18, compact ? 8 : 20, compact ? 6 : 10),
      child: Row(children: [
        if (compact && session.ctx != null) ...[BrandMark(size: 34, color: session.ctx!.accent), const SizedBox(width: 10)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: compact ? tt.titleLarge : tt.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null && !compact) Text(subtitle!, style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (showBeacon) const Beacon(),
        const SizedBox(width: 6),
        if (!compact) ...[
          Tooltip(
            message: lang == AppLang.bn ? 'English' : 'বাংলা',
            child: _TopBtn(label: lang == AppLang.bn ? 'EN' : 'বাং', onTap: () => ref.read(langProvider.notifier).set(lang == AppLang.bn ? AppLang.en : AppLang.bn)),
          ),
          const SizedBox(width: 6),
          _TopIcon(
            icon: t.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: t.dark ? 'Light mode' : 'Dark mode',
            onTap: () => ref.read(themeModeProvider.notifier).set(t.dark ? ThemeMode.light : ThemeMode.dark),
          ),
          const SizedBox(width: 6),
        ],
        PopupMenuButton<String>(
          tooltip: userName,
          offset: const Offset(0, 46),
          onSelected: (v) async {
            if (v == 'lang') ref.read(langProvider.notifier).set(lang == AppLang.bn ? AppLang.en : AppLang.bn);
            if (v == 'theme') ref.read(themeModeProvider.notifier).set(t.dark ? ThemeMode.light : ThemeMode.dark);
            if (v == 'sync') context.go('/sync');
            if (v == 'settings') context.go(session.isAdmin ? '/admin/settings' : '/settings');
            if (v == 'out') await _signOut(context, ref);
          },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userName, style: tt.titleSmall),
              Text((session.ctx?.roleLabel ?? 'Platform admin'), style: tt.bodySmall),
            ])),
            const PopupMenuDivider(),
            if (compact) PopupMenuItem(value: 'lang', child: Text(lang == AppLang.bn ? 'English' : 'বাংলা')),
            if (compact) PopupMenuItem(value: 'theme', child: Text(t.dark ? context.tr('Light mode') : context.tr('Dark mode'))),
            if (!session.isAdmin) PopupMenuItem(value: 'sync', child: Text(context.tr('Sync center'))),
            PopupMenuItem(value: 'settings', child: Text(context.tr('Settings'))),
            PopupMenuItem(value: 'out', child: Text(context.tr('Sign out'), style: TextStyle(color: t.danger))),
          ],
          child: Monogram(userName.isEmpty ? '?' : userName, size: 40, round: true),
        ),
      ]),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(syncProvider).pending;
    if (pending > 0) {
      final ok = await confirmDialog(
        context,
        title: context.tr('Sign out with unsynced sales?'),
        message: '${context.fmt.intN(pending)} ${context.tr('items are still waiting to reach the server. They stay safe on this device and sync when you sign back in with a connection.')}',
        confirm: context.tr('Sign out anyway'),
        danger: true,
      );
      if (!ok) return;
    }
    await ref.read(sessionProvider.notifier).logout();
  }
}

class _TopBtn extends StatelessWidget {
  const _TopBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: t.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 44, height: 40, child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: t.text)))),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: t.outline)),
        child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: t.text))),
      ),
    );
  }
}

/// The connection "beacon": a calm dot that says whether the till is online, syncing, or holding sales for later.
class Beacon extends ConsumerWidget {
  const Beacon({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(syncProvider);
    final fmt = context.fmt;
    final Color c;
    final String label;
    final IconData? icon;
    if (!s.started) {
      return const SizedBox.shrink();
    } else if (s.failed > 0) {
      c = t.danger;
      label = '${fmt.intN(s.failed)} ${context.tr('need attention')}';
      icon = Icons.error_outline_rounded;
    } else if (!s.online) {
      c = t.warning;
      label = s.pending > 0 ? '${context.tr('Offline')} · ${fmt.intN(s.pending)} ${context.tr('waiting')}' : context.tr('Offline');
      icon = Icons.cloud_off_rounded;
    } else if (s.syncing || s.pending > 0) {
      c = t.info;
      label = s.pending > 0 ? '${context.tr('Syncing')} · ${fmt.intN(s.pending)}' : context.tr('Syncing');
      icon = Icons.sync_rounded;
    } else {
      c = t.success;
      label = context.tr('Online');
      icon = null;
    }
    final compact = context.isCompact && !large;
    return Tooltip(
      message: s.lastSync == null ? label : '$label · ${context.tr('last sync')} ${fmt.ago(s.lastSync!)}',
      child: Material(
        color: t.tint(c, 0.12),
        shape: StadiumBorder(side: BorderSide(color: c.withValues(alpha: 0.35))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.go('/sync'),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(color: c, pulse: s.syncing || !s.online, icon: icon, spin: s.syncing),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.dark ? Color.lerp(c, Colors.white, 0.35) : Color.lerp(c, Colors.black, 0.25))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse, this.icon, this.spin = false});
  final Color color;
  final bool pulse, spin;
  final IconData? icon;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.icon != null) {
      final icon = Icon(widget.icon, size: 16, color: widget.color);
      return widget.spin ? RotationTransition(turns: _c, child: icon) : icon;
    }
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          if (widget.pulse) Container(width: 14 * (0.5 + _c.value * 0.5), height: 14 * (0.5 + _c.value * 0.5), decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)))),
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
        ]),
      ),
    );
  }
}

/// Slim banner for trial / renewal / lapsed states.
class SubscriptionBanner extends ConsumerWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(sessionProvider.select((s) => s.ctx));
    final notice = ctx?.notice;
    if (ctx == null || notice == null) return const SizedBox.shrink();
    final t = context.t;
    final bad = ctx.lapsed || ctx.subState == 'grace' || ctx.subState == 'expired';
    final c = bad ? t.danger : (ctx.subState == 'trialing' ? t.info : t.warning);
    return Padding(
      padding: EdgeInsets.fromLTRB(context.isCompact ? 12 : 24, 0, context.isCompact ? 12 : 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: t.tint(c, 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(bad ? Icons.warning_amber_rounded : Icons.workspace_premium_rounded, size: 19, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(notice), style: Theme.of(context).textTheme.labelMedium)),
          if (ctx.can('manage_subscription'))
            TextButton(onPressed: () => context.go('/billing'), style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: c), child: Text(context.tr(bad ? 'Renew now' : 'View plans'))),
        ]),
      ),
    );
  }
}

class TenantShell extends ConsumerWidget {
  const TenantShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final ctx = session.ctx;
    if (ctx == null) return const SizedBox.shrink();
    final entries = navFor(ctx);
    final loc = GoRouterState.of(context).matchedLocation;
    final current = entries.where((e) => loc == e.route || loc.startsWith('${e.route}/')).firstOrNull;
    return ShellFrame(
      entries: entries,
      title: context.tr(current?.label ?? ctx.businessName),
      subtitle: '${ctx.businessName} · ${ctx.branches.where((b) => b.id == session.device?.branchId).firstOrNull?.name ?? ctx.typeLabel}',
      banner: const SubscriptionBanner(),
      primaryIds: const ['dashboard', 'pos', 'sales', 'products', 'customers'],
      onLocked: (e) => _explainLock(context, ctx, e),
      child: child,
    );
  }

  void _explainLock(BuildContext context, TenantContext ctx, NavEntry e) {
    final t = context.t;
    final plan = e.lockedReason == 'plan';
    showPanel<void>(
      context,
      maxWidth: 440,
      builder: (c) => PanelScaffold(
        title: context.tr(e.label),
        leading: IconSquare(plan ? Icons.workspace_premium_rounded : Icons.lock_person_rounded, color: t.warning),
        footer: plan && ctx.can('manage_subscription')
            ? FilledButton(
                onPressed: () {
                  Navigator.pop(c);
                  context.go('/billing');
                },
                child: Text(context.tr('See plans')),
              )
            : OutlinedButton(onPressed: () => Navigator.pop(c), child: Text(context.tr('Got it'))),
        child: Text(
          plan
              ? '${context.trf('Your {plan} plan does not include this yet.', {'plan': ctx.planName})} ${ctx.can('manage_subscription') ? context.tr('Upgrade to unlock it.') : context.tr('Ask the business owner to upgrade.')}'
              : context.tr('Your role does not have access to this. Ask the owner to grant it in Settings → Staff.'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
