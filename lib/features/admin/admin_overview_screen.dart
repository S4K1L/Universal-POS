import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/dash.dart';
import '../../core/ui/kit.dart';
import '../../core/util/responsive.dart';
import '../../data/session.dart';

final adminOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return ref.watch(apiProvider).getMap('/admin/overview');
});

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    return context.tr(h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final compact = context.isCompact;
    final data = ref.watch(adminOverviewProvider);
    final name = ((ref.watch(sessionProvider.select((s) => s.user?['name'])) as String?) ?? '').split(' ').first;
    return PageBody(
      maxWidth: 1240,
      padding: EdgeInsets.fromLTRB(compact ? 14 : 24, 6, compact ? 14 : 24, 0),
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminOverviewProvider),
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? _greeting(context) : '${_greeting(context)}, $name', style: compact ? tt.headlineMedium : tt.displaySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('${f.weekday(DateTime.now())}, ${f.date(DateTime.now())}', style: tt.bodyMedium!.copyWith(color: t.muted)),
              Pill(context.tr('Platform console'), color: t.accent, dense: true),
            ]),
          ]),
          const SizedBox(height: 20),
          AsyncBody<Map<String, dynamic>>(
            value: data,
            onRetry: () => ref.invalidate(adminOverviewProvider),
            loading: const _Loading(),
            data: (d) => _Body(d: d),
          ),
        ]),
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

/// Colour and wording for each subscription state the platform reports.
Color _stateColor(Tokens t, String s) => switch (s) {
      'active' => t.success,
      'trialing' => t.info,
      'grace' => t.warning,
      _ => t.danger,
    };

String _stateLabel(BuildContext c, String s) => c.tr(switch (s) {
      'active' => 'Active',
      'trialing' => 'On trial',
      'grace' => 'In grace period',
      'expired' => 'Expired',
      'suspended' => 'Suspended',
      'cancelled' => 'Cancelled',
      _ => s,
    });

class _Body extends StatelessWidget {
  const _Body({required this.d});
  final Map<String, dynamic> d;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final wide = context.isWide;
    final compact = context.isCompact;
    final byType = (d['by_business_type'] as Map).cast<String, dynamic>();
    final byPlan = (d['by_plan'] as Map).cast<String, dynamic>();
    final byState = (d['by_state'] as Map).cast<String, dynamic>();
    final revenue = (d['revenue_by_month'] as List).cast<Map<String, dynamic>>();
    final signups = (d['signups_by_month'] as List).cast<Map<String, dynamic>>();
    final sales = (d['sales_24h'] as Map).cast<String, dynamic>();
    final pending = d['pending_payments'] as int;
    final tenants = d['tenants'] as int;
    final mrr = parsePaisa(d['mrr']);
    final lapsed = d['lapsed'] as int, expiring = d['expiring_in_7_days'] as int;
    final attention = lapsed + expiring;
    final palette = [t.accent, t.info, t.warning, const Color(0xFFD6336C), const Color(0xFF8B5CF6), t.success];

    // ---------------------------------------------------------------------------------------------------- hero
    final useRevenue = revenue.length >= 2;
    final trend = useRevenue ? [for (final r in revenue) parsePaisa(r['amount'])] : [for (final r in signups) (r['count'] as num).toInt()];
    final trendCaption = useRevenue ? context.tr('Subscription revenue') : context.tr('New businesses');
    final headline = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HeroLabel(context.tr('Monthly recurring revenue')),
      SizedBox(height: compact ? 8 : 12),
      CountUp(value: mrr, format: f.money, builder: (_, text) => HeroValue(text, size: compact ? 38 : 50)),
      const SizedBox(height: 12),
      Text(context.tr('From active subscriptions'), style: TextStyle(color: t.onInkMuted, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
    final hero = HeroPanel(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 28, compact ? 20 : 26, compact ? 20 : 28, compact ? 18 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(flex: 5, child: headline),
            const SizedBox(width: 28),
            Expanded(flex: 6, child: HeroTrend(values: trend, caption: trendCaption)),
          ])
        else ...[
          headline,
          if (trend.length > 1) ...[const SizedBox(height: 14), HeroTrend(values: trend, caption: trendCaption)],
        ],
        SizedBox(height: compact ? 16 : 22),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        SizedBox(height: compact ? 14 : 18),
        HeroMetrics(metrics: [
          HeroMetric(context.tr('Businesses'), f.intN(tenants), sub: '${f.intN((byState['active'] as num?)?.toInt() ?? 0)} ${context.tr('active')} · ${f.intN((byState['trialing'] as num?)?.toInt() ?? 0)} ${context.tr('on trial')}'),
          HeroMetric(context.tr('Need attention'), f.intN(attention), sub: '${f.intN(lapsed)} ${context.tr('lapsed')} · ${f.intN(expiring)} ${context.tr('expiring in 7 days')}', color: attention > 0 ? const Color(0xFFFCD34D) : null),
          HeroMetric(context.tr('Sold across all shops (24h)'), f.moneyCompact(parsePaisa(sales['total'])), sub: '${f.intN(sales['count'] as int)} ${context.tr('invoices')}', color: const Color(0xFF6EE7B7)),
        ]),
      ]),
    );

    // ---------------------------------------------------------------------------------------------------- shortcuts
    final quick = LayoutBuilder(builder: (c, box) {
      final items = [
        (Icons.storefront_rounded, 'Businesses', '/admin/businesses', 0),
        (Icons.payments_rounded, 'Payments', '/admin/payments', pending),
        (Icons.sell_rounded, 'Plans', '/admin/plans', 0),
        (Icons.category_rounded, 'Types', '/admin/types', 0),
        (Icons.fact_check_rounded, 'Audit', '/admin/audit', 0),
      ];
      final cols = compact ? 3 : items.length;
      const gap = 10.0;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap + 4, children: [
        for (final (icon, label, route, badge) in items) SizedBox(width: w, child: QuickAction(icon: icon, label: context.tr(label), badge: badge, onTap: () => context.go(route))),
      ]);
    });

    // ---------------------------------------------------------------------------------------------------- cards
    final waiting = pending > 0
        ? Surface(
            color: t.tint(t.warning, 0.1),
            border: false,
            onTap: () => context.go('/admin/payments'),
            child: Row(children: [
              IconSquare(Icons.payments_rounded, color: t.warning, size: 38),
              const SizedBox(width: 14),
              Expanded(child: Text('${f.intN(pending)} ${context.tr(pending == 1 ? 'payment is waiting for your review' : 'payments are waiting for your review')}', style: tt.titleSmall)),
              const Icon(Icons.chevron_right_rounded),
            ]),
          )
        : null;

    final revenueCard = DashCard(
      title: context.tr('Subscription revenue'),
      subtitle: context.tr('Approved payments, by month'),
      trailing: revenue.isEmpty ? null : NumText(f.money(revenue.fold<int>(0, (a, r) => a + parsePaisa(r['amount']))), size: 20, weight: 800),
      child: revenue.isEmpty
          ? _ChartEmpty(context.tr('No approved payments yet'))
          : BarChart(
              height: compact ? 180 : 210,
              values: [for (final r in revenue) parsePaisa(r['amount']).toDouble()],
              labels: [for (final r in revenue) f.digits((r['month'] as String).substring(5))],
              tips: [for (final r in revenue) '${f.digits(r['month'] as String)} · ${f.money(parsePaisa(r['amount']))}'],
              axis: (v) => f.moneyCompact(v.round()),
              highlight: revenue.length - 1,
            ),
    );
    final signupsCard = DashCard(
      title: context.tr('New businesses'),
      subtitle: context.tr('Sign-ups by month'),
      trailing: signups.isEmpty ? null : NumText(f.intN(signups.fold<int>(0, (a, r) => a + (r['count'] as num).toInt())), size: 20, weight: 800),
      child: signups.isEmpty
          ? const _ChartEmpty('—')
          : BarChart(
              height: compact ? 180 : 210,
              values: [for (final r in signups) (r['count'] as num).toDouble()],
              labels: [for (final r in signups) f.digits((r['month'] as String).substring(5))],
              tips: [for (final r in signups) '${f.digits(r['month'] as String)} · ${f.intN((r['count'] as num).toInt())}'],
              axis: (v) => f.intN(v.round()),
              highlight: signups.length - 1,
            ),
    );

    // Subscription health: one bar split by state, with the numbers beneath.
    final total = byState.values.fold<int>(0, (a, b) => a + (b as num).toInt());
    final order = ['active', 'trialing', 'grace', 'expired', 'suspended', 'cancelled'];
    final states = [for (final k in order) if ((byState[k] as num?) != null && (byState[k] as num) > 0) k, for (final k in byState.keys) if (!order.contains(k)) k];
    final healthCard = DashCard(
      title: context.tr('Subscription health'),
      subtitle: context.trf('{n} businesses', {'n': f.intN(tenants)}),
      action: attention > 0 ? context.tr('Review') : null,
      onAction: attention > 0 ? () => context.go('/admin/businesses') : null,
      child: total == 0
          ? DashEmpty(context.tr('No businesses yet'))
          : Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(children: [
                    for (final (i, k) in states.indexed) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(flex: math.max((byState[k] as num).toInt(), 1), child: Container(color: _stateColor(t, k))),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              for (final k in states)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _stateColor(t, k), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_stateLabel(context, k), style: tt.bodyMedium)),
                    NumText(f.intN((byState[k] as num).toInt()), size: 14),
                    SizedBox(width: 44, child: Text('${f.digits(((byState[k] as num) * 100 / total).round().toString())}%', textAlign: TextAlign.end, style: tt.bodySmall)),
                  ]),
                ),
            ]),
    );

    Widget dist(String title, Map<String, dynamic> m) {
      final sum = m.values.fold<num>(0, (a, b) => a + (b as num));
      return DashCard(
        title: title,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Donut(size: 112, slices: [for (final (i, e) in m.entries.indexed) DonutSlice(e.key, (e.value as num).toDouble(), palette[i % palette.length])], center: NumText(f.intN(sum.toInt()), size: 22, weight: 800)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(children: [
              for (final (i, e) in m.entries.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: palette[i % palette.length], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key, style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    NumText(f.intN((e.value as num).toInt()), size: 14),
                    SizedBox(width: 44, child: Text('${f.digits(sum == 0 ? '0' : ((e.value as num) * 100 / sum).round().toString())}%', textAlign: TextAlign.end, style: tt.bodySmall)),
                  ]),
                ),
            ]),
          ),
        ]),
      );
    }

    final typeCard = dist(context.tr('By business type'), byType);
    final planCard = dist(context.tr('By plan'), byPlan);

    // ---------------------------------------------------------------------------------------------------- layout
    Widget stack(List<Widget> kids, {int from = 2}) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, k) in kids.indexed) ...[if (i > 0) const SizedBox(height: 14), Reveal(delay: Reveal.stagger(from + i), child: k)],
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (waiting != null) ...[Reveal(child: waiting), const SizedBox(height: 14)],
      Reveal(child: hero),
      const SizedBox(height: 18),
      Reveal(delay: Reveal.stagger(1), child: quick),
      const SizedBox(height: 18),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 7, child: stack([revenueCard, signupsCard])),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: stack([healthCard, typeCard, planCard], from: 3)),
        ])
      else
        stack([healthCard, revenueCard, signupsCard, typeCard, planCard]),
    ]);
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(height: 200, child: Center(child: Text(text, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: context.t.muted))));
}
