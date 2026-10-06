import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';

final adminOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async => ref.watch(apiProvider).getMap('/admin/overview'));

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(adminOverviewProvider);
    return PageBody(
      maxWidth: 1180,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminOverviewProvider),
        child: AsyncBody<Map<String, dynamic>>(
          value: data,
          onRetry: () => ref.invalidate(adminOverviewProvider),
          loading: const SkeletonList(rows: 4, height: 110),
          data: (d) {
            final byType = (d['by_business_type'] as Map).cast<String, dynamic>();
            final byPlan = (d['by_plan'] as Map).cast<String, dynamic>();
            final byState = (d['by_state'] as Map).cast<String, dynamic>();
            final revenue = (d['revenue_by_month'] as List).cast<Map<String, dynamic>>();
            final signups = (d['signups_by_month'] as List).cast<Map<String, dynamic>>();
            final sales = (d['sales_24h'] as Map).cast<String, dynamic>();
            final pending = d['pending_payments'] as int;
            final palette = [t.accent, t.info, t.warning, const Color(0xFFD6336C), const Color(0xFF8B5CF6), t.success];
            return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Surface(
                    color: t.tint(t.warning, 0.1),
                    border: false,
                    onTap: () => context.go('/admin/payments'),
                    child: Row(children: [Icon(Icons.payments_rounded, color: t.warning), const SizedBox(width: 12), Expanded(child: Text('${f.intN(pending)} ${context.tr(pending == 1 ? 'payment is waiting for your review' : 'payments are waiting for your review')}', style: tt.titleSmall)), const Icon(Icons.chevron_right_rounded)]),
                  ),
                ),
              LayoutBuilder(builder: (c, box) {
                final cols = box.maxWidth > 900 ? 4 : 2;
                final w = (box.maxWidth - 12 * (cols - 1)) / cols;
                final tiles = [
                  StatTile(label: context.tr('Businesses'), value: f.intN(d['tenants'] as int), icon: Icons.storefront_rounded, hint: '${f.intN((byState['active'] as num?)?.toInt() ?? 0)} ${context.tr('active')} · ${f.intN((byState['trialing'] as num?)?.toInt() ?? 0)} ${context.tr('on trial')}'),
                  StatTile(label: context.tr('Monthly recurring revenue'), value: f.money(parsePaisa(d['mrr'])), icon: Icons.trending_up_rounded, color: t.success, hint: context.tr('From active subscriptions')),
                  StatTile(label: context.tr('Need attention'), value: f.intN((d['lapsed'] as int) + (d['expiring_in_7_days'] as int)), icon: Icons.notification_important_rounded, color: t.warning, hint: '${f.intN(d['lapsed'] as int)} ${context.tr('lapsed')} · ${f.intN(d['expiring_in_7_days'] as int)} ${context.tr('expiring in 7 days')}'),
                  StatTile(label: context.tr('Sold across all shops (24h)'), value: f.moneyCompact(parsePaisa(sales['total'])), icon: Icons.point_of_sale_rounded, color: t.info, hint: '${f.intN(sales['count'] as int)} ${context.tr('invoices')} · ${f.intN(d['devices'] as int)} ${context.tr('tills')}'),
                ];
                return Wrap(spacing: 12, runSpacing: 12, children: [for (final x in tiles) SizedBox(width: w, child: x)]);
              }),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (c, box) {
                final two = box.maxWidth > 820;
                final rev = Surface(
                  child: Section(
                    title: context.tr('Subscription revenue'),
                    subtitle: context.tr('Approved payments, by month'),
                    child: revenue.isEmpty ? Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Center(child: Text(context.tr('No approved payments yet'), style: tt.bodyMedium!.copyWith(color: t.muted)))) : MiniBars(values: [for (final r in revenue) parsePaisa(r['amount']) / 100], labels: [for (final r in revenue) (r['month'] as String).substring(5)], fmt: (v) => f.money((v * 100).round())),
                  ),
                );
                final sig = Surface(
                  child: Section(
                    title: context.tr('New businesses'),
                    subtitle: context.tr('Sign-ups by month'),
                    child: signups.isEmpty ? Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('—', style: tt.bodyMedium))) : MiniBars(color: t.info, values: [for (final r in signups) (r['count'] as num).toDouble()], labels: [for (final r in signups) (r['month'] as String).substring(5)], fmt: (v) => v.toStringAsFixed(0)),
                  ),
                );
                return two ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: rev), const SizedBox(width: 14), Expanded(child: sig)]) : Column(children: [rev, const SizedBox(height: 14), sig]);
              }),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (c, box) {
                final two = box.maxWidth > 820;
                Widget dist(String title, Map<String, dynamic> m) => Surface(
                      child: Section(
                        title: title,
                        child: Row(children: [
                          Donut(size: 104, slices: [for (final (i, e) in m.entries.indexed) DonutSlice(e.key, (e.value as num).toDouble(), palette[i % palette.length])], center: NumText(f.intN(m.values.fold<int>(0, (a, b) => a + (b as num).toInt())), size: 22, weight: 800)),
                          const SizedBox(width: 16),
                          Expanded(child: Column(children: [for (final (i, e) in m.entries.indexed) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(e.key, style: tt.bodyMedium)), NumText(f.intN((e.value as num).toInt()), size: 14)]))])),
                        ]),
                      ),
                    );
                final a = dist(context.tr('By business type'), byType), b = dist(context.tr('By plan'), byPlan);
                return two ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 14), Expanded(child: b)]) : Column(children: [a, const SizedBox(height: 14), b]);
              }),
              if ((d['devices_not_synced_24h'] as int) > 0) ...[
                const SizedBox(height: 14),
                Surface(color: t.tint(t.info, 0.08), border: false, child: Row(children: [Icon(Icons.sync_problem_rounded, color: t.info), const SizedBox(width: 12), Expanded(child: Text('${f.intN(d['devices_not_synced_24h'] as int)} ${context.tr('tills have not synced in the last 24 hours — they may be offline or switched off.')}', style: tt.bodyMedium))])),
              ],
            ]);
          },
        ),
      ),
    );
  }
}
