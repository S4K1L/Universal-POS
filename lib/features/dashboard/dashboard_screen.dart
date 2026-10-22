import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/dash.dart';
import '../../core/ui/kit.dart';
import '../../core/util/responsive.dart';
import '../../data/models/context.dart';
import '../../data/providers.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import '../shell/shell.dart' show navFor;

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheForSession(revalidate: true);
  ref.watch(syncProvider.select((s) => s.revision)); // refetch when something actually changed
  final api = ref.watch(apiProvider);
  final branch = ref.watch(sessionProvider.select((s) => s.branchId));
  return api.getMap('/reports/dashboard', query: {if (branch != null) 'branch_id': branch});
});

final _ordersBriefProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.cacheForSession(revalidate: true);
  ref.watch(syncProvider.select((s) => s.revision));
  final r = await ref.watch(apiProvider).getMap('/orders', query: {'limit': 100});
  return (r['items'] as List).cast<Map<String, dynamic>>();
});

/// What this till alone has sold since midnight — the dashboard when there is no connection.
final _localTodayProvider = FutureProvider.autoDispose<_LocalToday>((ref) async {
  ref.watch(syncProvider.select((s) => s.revision + s.pending));
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  final sales = await ref.watch(salesRepoProvider).salesSince(midnight);
  final db = ref.watch(dbProvider);
  final pays = await db.select(db.lSalePayments).get();
  final byMethod = <String, int>{};
  final today = sales.map((s) => s.id).toSet();
  for (final p in pays) {
    if (today.contains(p.saleId)) byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amountP;
  }
  return _LocalToday(sales.length, sales.fold(0, (a, s) => a + s.totalP), sales.fold(0, (a, s) => a + (s.totalP - s.paidP)), byMethod);
});

class _LocalToday {
  _LocalToday(this.count, this.total, this.due, this.byMethod);
  final int count, total, due;
  final Map<String, int> byMethod;
}

// ======================================================================================================== screen

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    return context.tr(h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final ctx = ref.watch(ctxProvider);
    final f = context.fmt;
    final data = ref.watch(dashboardProvider);
    final branchId = ref.watch(sessionProvider.select((s) => s.branchId));
    final first = ctx.userName.split(' ').first;
    final canSeeSales = ctx.can('view_sales') || ctx.can('view_reports');
    final compact = context.isCompact;
    final branch = ctx.branches.where((b) => b.id == branchId).firstOrNull;
    final pos = navFor(ctx).where((e) => e.id == 'pos' && e.lockedReason == null).firstOrNull;
    final orders = ctx.cap('document_flow') && ctx.can('manage_orders') && ctx.feature('orders') ? _OrdersCard(ctx: ctx) : null;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
        await ref.read(syncProvider.notifier).syncNow();
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(compact ? 14 : 24, 6, compact ? 14 : 24, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_greeting(context)}, $first', style: compact ? tt.headlineMedium : tt.displaySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Text('${f.weekday(DateTime.now())}, ${f.date(DateTime.now())}', style: tt.bodyMedium!.copyWith(color: t.muted)),
                        if (branch != null && ctx.branches.length > 1) Pill(branch.name, icon: Icons.storefront_rounded, dense: true),
                        Pill(ctx.typeLabel, color: t.accent, dense: true),
                      ]),
                    ]),
                  ),
                  if (pos != null && !compact) ...[
                    const SizedBox(width: 16),
                    FilledButton.icon(onPressed: () => context.go(pos.route), icon: Icon(pos.icon, size: 19), label: Text(context.tr(pos.label))),
                  ],
                ]),
                const SizedBox(height: 20),
                if (!canSeeSales)
                  EmptyState(icon: Icons.waving_hand_rounded, title: '${context.tr('Welcome')}, $first', message: context.tr('Open the Sell screen to start ringing up customers.'), action: FilledButton(onPressed: () => context.go('/pos'), child: Text(context.tr('Start selling'))))
                else
                  FadeSwitcher(
                    child: data.when(
                      skipLoadingOnRefresh: true,
                      skipLoadingOnReload: true,
                      data: (d) => _Online(key: const ValueKey('online'), d: d, ctx: ctx, orders: orders),
                      loading: () => const Deferred(key: ValueKey('loading'), child: _Loading()),
                      error: (e, _) => _OfflineView(key: const ValueKey('offline'), ctx: ctx, error: e, orders: orders),
                    ),
                  ),
                if (!canSeeSales && orders != null) ...[const SizedBox(height: 18), orders],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Column(children: [
        Skeleton(height: 236, radius: 26),
        SizedBox(height: 14),
        Skeleton(height: 84, radius: 18),
        SizedBox(height: 14),
        Skeleton(height: 260, radius: 18),
      ]);
}

// ======================================================================================================== offline

class _OfflineView extends ConsumerWidget {
  const _OfflineView({super.key, required this.ctx, required this.error, this.orders});
  final TenantContext ctx;
  final Object error;
  final Widget? orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final local = ref.watch(_localTodayProvider);
    final isOffline = error is ApiError && (error as ApiError).offline;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Surface(
        color: t.tint(t.warning, 0.1),
        border: false,
        child: Row(children: [
          IconSquare(isOffline ? Icons.cloud_off_rounded : Icons.info_outline_rounded, color: t.warning, size: 38),
          const SizedBox(width: 14),
          Expanded(child: Text(isOffline ? context.tr('You are offline. These numbers are only what this till has sold since midnight — the full picture returns when you are back online.') : (error is ApiError ? (error as ApiError).message : '$error'), style: tt.bodyMedium)),
        ]),
      ),
      const SizedBox(height: 14),
      local.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (l) => HeroPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HeroLabel(context.tr('Sold on this till today')),
            const SizedBox(height: 10),
            HeroValue(f.money(l.total)),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            HeroMetrics(metrics: [
              HeroMetric(context.tr('Invoices'), f.intN(l.count)),
              HeroMetric(context.tr('Credit given'), f.money(l.due)),
              HeroMetric(context.tr('Cash in drawer today'), f.money(l.byMethod['cash'] ?? 0)),
            ]),
          ]),
        ),
        loading: () => const Deferred(child: Skeleton(height: 200, radius: 26)),
        error: (_, __) => const SizedBox.shrink(),
      ),
      if (orders != null) ...[const SizedBox(height: 14), orders!],
    ]);
  }
}

// ======================================================================================================== online

class _Online extends ConsumerWidget {
  const _Online({super.key, required this.d, required this.ctx, this.orders});
  final Map<String, dynamic> d;
  final TenantContext ctx;
  final Widget? orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final today = (d['today'] as Map?)?.cast<String, dynamic>();
    final yday = (d['yesterday'] as Map?)?.cast<String, dynamic>();
    if (today == null) return const SizedBox.shrink();
    final trendRows = (d['trend'] as List? ?? const []).cast<Map<String, dynamic>>();
    final trend = [for (final x in trendRows) parsePaisa(x['total'])];
    final gross = parsePaisa(today['gross_sales']);
    final yGross = parsePaisa(yday?['gross_sales']);
    final delta = yGross > 0 ? (gross - yGross) / yGross : null;
    final invoices = (today['invoices'] as num).toInt();
    final avg = parsePaisa(today['avg_bill']);
    final profit = today['gross_profit'];
    final methods = (today['by_method'] as List).cast<Map<String, dynamic>>();
    final top = (d['top_products'] as List? ?? const []).cast<Map<String, dynamic>>();
    final low = (d['low_stock'] as List? ?? const []).cast<Map<String, dynamic>>();
    final expiring = (d['expiring'] as List? ?? const []).cast<Map<String, dynamic>>();
    final dues = (d['dues'] as Map?)?.cast<String, dynamic>();
    final hourly = (d['hourly'] as List? ?? const []).cast<Map<String, dynamic>>();
    final wide = context.isWide;
    final compact = context.isCompact;

    // ------------------------------------------------------------------------------------------------ hero
    final metrics = <HeroMetric>[
      HeroMetric(context.tr('Invoices'), f.intN(invoices), sub: '${context.tr('Average bill')} ${f.moneyCompact(avg)}'),
      if (profit != null)
        HeroMetric(context.tr('Gross profit'), f.money(parsePaisa(profit)), sub: gross > 0 ? '${f.digits((parsePaisa(profit) * 100 / gross).toStringAsFixed(0))}% ${context.tr('margin')}' : null, color: const Color(0xFF6EE7B7))
      else
        HeroMetric(context.tr('Items sold'), f.qty(parseMilli(today['items_sold']))),
      if (ctx.cap('customer_credit'))
        HeroMetric(context.tr('Credit given'), f.money(parsePaisa(today['due_created'])), sub: dues == null ? null : '${f.moneyCompact(parsePaisa(dues['total']))} ${context.tr('outstanding')}', color: const Color(0xFFFCD34D))
      else
        HeroMetric(context.tr('Returns'), f.money(parsePaisa(today['returns_total'])), sub: '${f.intN((today['returns_count'] as num).toInt())} ${context.tr('today')}', color: const Color(0xFFFCD34D)),
    ];
    final hero = HeroPanel(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 28, compact ? 20 : 26, compact ? 20 : 28, compact ? 18 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(flex: 5, child: HeroHeadline(value: gross, format: f.money, delta: delta, versus: '${context.tr('vs yesterday')} ${f.money(yGross)}')),
            const SizedBox(width: 28),
            Expanded(flex: 6, child: HeroTrend(values: trend, caption: context.tr('Last 14 days'))),
          ])
        else ...[
          HeroHeadline(value: gross, format: f.money, delta: delta, versus: '${context.tr('vs yesterday')} ${f.money(yGross)}'),
          const SizedBox(height: 14),
          HeroTrend(values: trend, caption: context.tr('Last 14 days')),
        ],
        SizedBox(height: compact ? 16 : 22),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        SizedBox(height: compact ? 14 : 18),
        HeroMetrics(metrics: metrics),
      ]),
    );

    // ------------------------------------------------------------------------------------------------ quick actions
    const order = ['purchases', 'products', 'expenses', 'customers', 'orders', 'reports'];
    final entries = navFor(ctx);
    final actions = [
      for (final id in order)
        for (final e in entries)
          if (e.id == id && e.lockedReason == null) e
    ].toList();
    final pos = entries.where((e) => e.id == 'pos' && e.lockedReason == null).firstOrNull;
    final shown = actions.take(compact ? (pos != null ? 3 : 4) : 5).toList();
    final quick = shown.isEmpty && pos == null
        ? null
        : LayoutBuilder(builder: (c, box) {
            final all = [if (pos != null && compact) pos, ...shown];
            final cols = compact ? math.min(all.length, 4) : all.length;
            const gap = 10.0;
            final w = (box.maxWidth - gap * (cols - 1)) / math.max(cols, 1);
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (final e in all) SizedBox(width: w, child: QuickAction(icon: e.icon, label: context.tr(e.label), primary: e.id == 'pos', onTap: () => context.go(e.route))),
            ]);
          });

    // ------------------------------------------------------------------------------------------------ cards
    final bestIdx = trend.isEmpty ? -1 : trend.indexOf(trend.reduce(math.max));
    final total14 = trend.fold<int>(0, (a, b) => a + b);
    final trendCard = DashCard(
      title: context.tr('Daily sales'),
      subtitle: context.tr('Last 14 days'),
      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        NumText(f.money(total14), size: 20, weight: 800),
        if (bestIdx >= 0 && trend[bestIdx] > 0) ...[
          const SizedBox(height: 4),
          Pill('${context.tr('Best day')} · ${f.dateShort(DateTime.parse(trendRows[bestIdx]['date'] as String))}', icon: Icons.emoji_events_rounded, color: t.warning, dense: true),
        ],
      ]),
      child: BarChart(
        values: [for (final v in trend) v.toDouble()],
        labels: [for (final x in trendRows) f.digits(DateTime.parse(x['date'] as String).day.toString())],
        tips: [for (var i = 0; i < trend.length; i++) '${f.dateShort(DateTime.parse(trendRows[i]['date'] as String))} · ${f.money(trend[i])}'],
        axis: (v) => f.moneyCompact(v.round()),
        highlight: trend.length - 1,
        height: compact ? 170 : 210,
      ),
    );

    final topMax = top.isEmpty ? 1 : math.max(parsePaisa(top.first['revenue']), 1);
    final topCard = DashCard(
      title: context.tr('Best sellers'),
      subtitle: context.tr('Last 7 days'),
      child: top.isEmpty
          ? DashEmpty(context.tr('Nothing sold yet'))
          : Column(children: [
              for (final (i, p) in top.indexed)
                _RankRow(rank: i + 1, label: p['name'] as String, value: f.money(parsePaisa(p['revenue'])), fraction: parsePaisa(p['revenue']) / topMax),
            ]),
    );

    final payTotal = methods.fold<int>(0, (a, m) => a + parsePaisa(m['amount']));
    final mixCard = DashCard(
      title: context.tr('How people paid'),
      subtitle: context.tr('Today'),
      child: methods.isEmpty
          ? DashEmpty(context.tr('No sales yet today'))
          : Row(children: [
              Donut(
                size: 118,
                slices: [for (final m in methods) DonutSlice(context.methodName(ctx, m['method'] as String), parsePaisa(m['amount']).toDouble(), _methodColor(ctx, m['method'] as String))],
                center: Column(mainAxisSize: MainAxisSize.min, children: [NumText(f.intN(methods.fold(0, (a, m) => a + (m['count'] as num).toInt())), size: 22, weight: 800), Text(context.tr('payments'), style: tt.labelSmall)]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(children: [
                  for (final m in methods.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: _methodColor(ctx, m['method'] as String), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 9),
                        Expanded(child: Text(context.methodName(ctx, m['method'] as String), style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        NumText(f.moneyCompact(parsePaisa(m['amount'])), size: 13.5),
                        SizedBox(width: 40, child: Text(payTotal > 0 ? '${f.digits((parsePaisa(m['amount']) * 100 / payTotal).round().toString())}%' : '', textAlign: TextAlign.end, style: tt.bodySmall)),
                      ]),
                    ),
                ]),
              ),
            ]),
    );

    int hourTotal(int h) => parsePaisa(hourly.length > h ? hourly[h]['total'] : 0);
    final active = [for (var h = 0; h < 24; h++) if (hourTotal(h) > 0) h];
    final h0 = active.isEmpty ? 8 : math.min(8, active.first), h1 = active.isEmpty ? 18 : math.max(18, active.last);
    final hourTotals = [for (var h = h0; h <= h1; h++) hourTotal(h)];
    final peak = hourTotals.isEmpty ? -1 : hourTotals.indexOf(hourTotals.reduce(math.max));
    String hour12(int h) => f.digits('${h % 12 == 0 ? 12 : h % 12}');
    final hourCard = hourTotals.any((v) => v > 0)
        ? DashCard(
            title: context.tr('Busy hours'),
            subtitle: context.tr('Today, by hour'),
            child: BarChart(
              values: [for (final v in hourTotals) v.toDouble()],
              labels: [for (var h = h0; h <= h1; h++) hour12(h)],
              tips: [for (var i = 0; i < hourTotals.length; i++) '${hour12(h0 + i)}:00 ${(h0 + i) < 12 ? 'AM' : 'PM'} · ${f.money(hourTotals[i])}'],
              axis: (v) => f.moneyCompact(v.round()),
              highlight: peak,
              height: 130,
            ),
          )
        : null;

    final lowCard = low.isEmpty && !ctx.feature('inventory')
        ? null
        : DashCard(
            title: context.tr('Running low'),
            subtitle: context.tr('At or below the reorder level'),
            count: low.isEmpty ? null : low.length,
            action: context.tr('Stock'),
            onAction: () => context.go('/stock'),
            child: low.isEmpty
                ? DashAllGood(context.tr('Everything is stocked'))
                : Column(children: [
                    for (final x in low.take(6))
                      DashListRow(
                        title: x['label'] == '' ? x['name'] as String : '${x['name']} · ${x['label']}',
                        trailing: Pill(parseMilli(x['on_hand']) <= 0 ? context.tr('Out') : '${f.qty(parseMilli(x['on_hand']))} ${x['unit']}', color: parseMilli(x['on_hand']) <= 0 ? t.danger : t.warning, dense: true),
                      ),
                  ]),
          );

    final expCard = ctx.cap('expiry_tracking') && ctx.feature('inventory')
        ? DashCard(
            title: context.tr('Expiring soon'),
            subtitle: context.tr('Within 60 days'),
            count: expiring.isEmpty ? null : expiring.length,
            child: expiring.isEmpty
                ? DashAllGood(context.tr('Nothing close to expiry'))
                : Column(children: [
                    for (final x in expiring.take(6))
                      DashListRow(
                        title: x['label'] == '' ? x['name'] as String : '${x['name']} · ${x['label']}',
                        meta: f.qty(parseMilli(x['qty'])),
                        trailing: Pill((x['days_left'] as num) < 0 ? context.tr('Expired') : '${f.intN((x['days_left'] as num).toInt())} ${context.tr('days')}', color: (x['days_left'] as num) <= 14 ? t.danger : t.warning, dense: true),
                      ),
                  ]),
          )
        : null;

    final duesCard = dues != null && ctx.cap('customer_credit')
        ? DashCard(
            title: '${context.term(ctx, 'due', 'Due')} · ${context.tr('who owes you')}',
            subtitle: context.trf('{amount} in total', {'amount': f.money(parsePaisa(dues['total']))}),
            action: context.tr('All'),
            onAction: () => context.go('/customers'),
            child: (dues['top'] as List).isEmpty
                ? DashEmpty(context.tr('No one owes anything'))
                : Column(children: [
                    for (final x in (dues['top'] as List).cast<Map<String, dynamic>>())
                      DashListRow(
                        leading: Monogram(x['name'] as String, size: 34, round: true),
                        title: x['name'] as String,
                        trailing: NumText(f.money(parsePaisa(x['balance'])), size: 14, color: t.warning),
                      ),
                  ]),
          )
        : null;

    // ------------------------------------------------------------------------------------------------ layout
    final main = <Widget>[if (orders != null) orders!, trendCard, topCard, if (hourCard != null) hourCard];
    final side = <Widget>[mixCard, if (lowCard != null) lowCard, if (expCard != null) expCard, if (duesCard != null) duesCard];

    // Blocks arrive one after another, top to bottom, so the page builds itself instead of snapping in.
    Widget stack(List<Widget> kids, {int from = 2}) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, k) in kids.indexed) ...[if (i > 0) const SizedBox(height: 14), Reveal(delay: Reveal.stagger(from + i), child: k)],
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Reveal(child: hero),
      if (quick != null) ...[const SizedBox(height: 14), Reveal(delay: Reveal.stagger(1), child: quick)],
      const SizedBox(height: 14),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 7, child: stack(main)),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: stack(side, from: 3)),
        ])
      else
        stack([if (orders != null) orders!, trendCard, mixCard, topCard, if (lowCard != null) lowCard, if (hourCard != null) hourCard, if (expCard != null) expCard, if (duesCard != null) duesCard]),
    ]);
  }
}

Color _methodColor(TenantContext ctx, String code) => ctx.paymentMethods.where((m) => m.code == code).firstOrNull?.color ?? const Color(0xFF64748B);

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.label, required this.value, required this.fraction});
  final int rank;
  final String label, value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final first = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: first ? t.accent : t.surface2, borderRadius: BorderRadius.circular(8), border: first ? null : Border.all(color: t.outline)),
          child: Text(context.fmt.digits('$rank'), style: tt.labelMedium!.copyWith(color: first ? t.onAccent : t.muted, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label, style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),
              NumText(value, size: 13.5),
            ]),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, color: first ? t.accent : t.accent.withValues(alpha: 0.55), backgroundColor: t.outline.withValues(alpha: 0.55)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ======================================================================================================== orders

class _OrdersCard extends ConsumerWidget {
  const _OrdersCard({required this.ctx});
  final TenantContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final orders = ref.watch(_ordersBriefProvider);
    return orders.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        int n(String s) => list.where((o) => o['status'] == s).length;
        final due = list.where((o) => (o['status'] == 'confirmed' || o['status'] == 'ready') && o['delivery_date'] != null).toList()
          ..sort((a, b) => (a['delivery_date'] as String).compareTo(b['delivery_date'] as String));
        final receivable = list.where((o) => o['status'] == 'confirmed' || o['status'] == 'ready').fold<int>(0, (a, o) => a + parsePaisa(o['balance']));
        return DashCard(
          title: context.tr('Order pipeline'),
          subtitle: '${f.money(receivable)} ${context.tr('still to collect on open orders')}',
          action: context.tr('Open orders'),
          onAction: () => context.go('/orders'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              for (final (i, (label, key, c)) in [('Quotations', 'quotation', t.info), ('Confirmed', 'confirmed', t.accent), ('Ready', 'ready', t.warning), ('Delivered', 'delivered', t.success)].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(color: t.tint(c, 0.09), borderRadius: BorderRadius.circular(R.control)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NumText(f.intN(n(key)), size: 24, weight: 800, color: t.dark ? Color.lerp(c, Colors.white, 0.3) : Color.lerp(c, Colors.black, 0.2)),
                      const SizedBox(height: 2),
                      Text(context.tr(label), style: tt.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
              ],
            ]),
            if (due.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(context.tr('Next deliveries'), style: tt.titleSmall),
              const SizedBox(height: 4),
              for (final o in due.take(3))
                DashListRow(
                  leading: IconSquare(Icons.local_shipping_rounded, size: 34, color: t.muted),
                  title: '${o['number']} · ${o['customer_name']}',
                  trailing: Pill(f.dateShort(DateTime.parse(o['delivery_date'] as String)), dense: true),
                ),
            ],
          ]),
        );
      },
    );
  }
}
