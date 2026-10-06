import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/kit.dart';
import '../../core/util/responsive.dart';
import '../../data/models/context.dart';
import '../../data/providers.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(syncProvider.select((s) => s.revision)); // refetch when something actually changed
  final api = ref.watch(apiProvider);
  final branch = ref.watch(sessionProvider.select((s) => s.device?.branchId));
  return api.getMap('/reports/dashboard', query: {if (branch != null) 'branch_id': branch});
});

final _ordersBriefProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
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
    final sync = ref.watch(syncProvider);
    final data = ref.watch(dashboardProvider);
    final first = ctx.userName.split(' ').first;
    final canSeeSales = ctx.can('view_sales') || ctx.can('view_reports');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
        await ref.read(syncProvider.notifier).syncNow();
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(context.isCompact ? 14 : 24, 4, context.isCompact ? 14 : 24, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_greeting(context)}, $first', style: tt.displaySmall),
                      const SizedBox(height: 2),
                      Text('${f.date(DateTime.now())} · ${f.weekday(DateTime.now())}', style: tt.bodyMedium!.copyWith(color: t.muted)),
                    ]),
                  ),
                  Pill(ctx.typeLabel, color: t.accent),
                ]),
                const SizedBox(height: 18),
                if (!canSeeSales)
                  EmptyState(icon: Icons.waving_hand_rounded, title: '${context.tr('Welcome')}, $first', message: context.tr('Open the Sell screen to start ringing up customers.'), action: FilledButton(onPressed: () => context.go('/pos'), child: Text(context.tr('Start selling'))))
                else
                  data.when(
                    skipLoadingOnRefresh: true,
                    data: (d) => _Online(d: d, ctx: ctx),
                    loading: () => const SkeletonList(rows: 4, height: 110),
                    error: (e, _) => _OfflineView(ctx: ctx, error: e),
                  ),
                if (ctx.cap('document_flow') && ctx.can('manage_orders') && ctx.feature('orders')) ...[const SizedBox(height: 18), _OrdersCard(ctx: ctx)],
                if (!sync.online && !sync.syncing) const SizedBox.shrink(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineView extends ConsumerWidget {
  const _OfflineView({required this.ctx, required this.error});
  final TenantContext ctx;
  final Object error;

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
          Icon(isOffline ? Icons.cloud_off_rounded : Icons.info_outline_rounded, color: t.warning),
          const SizedBox(width: 12),
          Expanded(child: Text(isOffline ? context.tr('You are offline. These numbers are only what this till has sold since midnight — the full picture returns when you are back online.') : (error is ApiError ? (error as ApiError).message : '$error'), style: tt.bodyMedium)),
        ]),
      ),
      const SizedBox(height: 14),
      local.when(
        data: (l) => LayoutBuilder(builder: (c, box) {
          final cols = box.maxWidth > 760 ? 3 : (box.maxWidth > 480 ? 2 : 1);
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 2.8 : 2.0,
            children: [
              StatTile(label: context.tr('Sold on this till today'), value: f.money(l.total), icon: Icons.payments_rounded, hint: '${f.intN(l.count)} ${context.tr('invoices')}'),
              StatTile(label: context.tr('Credit given'), value: f.money(l.due), icon: Icons.menu_book_rounded, color: t.warning),
              StatTile(label: context.tr('Cash in drawer today'), value: f.money(l.byMethod['cash'] ?? 0), icon: Icons.savings_rounded, color: t.success),
            ],
          );
        }),
        loading: () => const SkeletonList(rows: 1, height: 100),
        error: (_, __) => const SizedBox.shrink(),
      ),
    ]);
  }
}

class _Online extends ConsumerWidget {
  const _Online({required this.d, required this.ctx});
  final Map<String, dynamic> d;
  final TenantContext ctx;

  List<double> _trend(Map<String, dynamic> d) => [for (final x in (d['trend'] as List? ?? const [])) paisaD((x as Map)['total'])];
  double paisaD(Object? v) => parsePaisa(v) / 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final today = (d['today'] as Map?)?.cast<String, dynamic>();
    final yday = (d['yesterday'] as Map?)?.cast<String, dynamic>();
    if (today == null) return const SizedBox.shrink();
    final trend = _trend(d);
    final gross = parsePaisa(today['gross_sales']);
    final yGross = parsePaisa(yday?['gross_sales']);
    final delta = yGross > 0 ? (gross - yGross) / yGross : null;
    final invoices = (today['invoices'] as num).toInt();
    final avg = parsePaisa(today['avg_bill']);
    final profit = today['gross_profit'];
    final methods = [for (final m in (today['by_method'] as List).cast<Map<String, dynamic>>()) m];
    final top = (d['top_products'] as List? ?? const []).cast<Map<String, dynamic>>();
    final low = (d['low_stock'] as List? ?? const []).cast<Map<String, dynamic>>();
    final expiring = (d['expiring'] as List? ?? const []).cast<Map<String, dynamic>>();
    final dues = (d['dues'] as Map?)?.cast<String, dynamic>();
    final hourly = (d['hourly'] as List? ?? const []).cast<Map<String, dynamic>>();

    final tiles = <Widget>[
      StatTile(label: context.tr("Today's sales"), value: f.money(gross), icon: Icons.payments_rounded, delta: delta, spark: trend, hint: '${context.tr('vs yesterday')} ${f.money(yGross)}'),
      StatTile(label: context.tr('Invoices'), value: f.intN(invoices), icon: Icons.receipt_long_rounded, color: t.info, hint: '${context.tr('Average bill')} ${f.money(avg)}'),
      if (profit != null) StatTile(label: context.tr('Gross profit'), value: f.money(parsePaisa(profit)), icon: Icons.trending_up_rounded, color: t.success, hint: gross > 0 ? '${(parsePaisa(profit) * 100 / gross).toStringAsFixed(0)}% ${context.tr('margin')}' : null)
      else StatTile(label: context.tr('Items sold'), value: f.qty(parseMilli(today['items_sold'])), icon: Icons.shopping_bag_rounded, color: t.success),
      if (ctx.cap('customer_credit')) StatTile(label: context.tr('Credit given today'), value: f.money(parsePaisa(today['due_created'])), icon: Icons.menu_book_rounded, color: t.warning, hint: dues == null ? null : '${f.money(parsePaisa(dues['total']))} ${context.tr('outstanding')}')
      else StatTile(label: context.tr('Returns'), value: f.money(parsePaisa(today['returns_total'])), icon: Icons.assignment_return_rounded, color: t.warning, hint: '${f.intN((today['returns_count'] as num).toInt())} ${context.tr('today')}'),
    ];

    final wide = context.isWide;
    final trendCard = Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Section(
          title: context.tr('Last 14 days'),
          subtitle: context.tr('Daily sales'),
          child: MiniBars(
            values: trend,
            labels: [for (final x in (d['trend'] as List).cast<Map<String, dynamic>>()) f.digits(DateTime.parse(x['date'] as String).day.toString())],
            fmt: (v) => f.money((v * 100).round()),
          ),
        ),
      ]),
    );
    final mixCard = Surface(
      child: Section(
        title: context.tr('How people paid'),
        subtitle: context.tr('Today'),
        child: methods.isEmpty
            ? Padding(padding: const EdgeInsets.symmetric(vertical: 26), child: Center(child: Text(context.tr('No sales yet today'), style: tt.bodyMedium!.copyWith(color: t.muted))))
            : Row(children: [
                Donut(
                  size: 112,
                  slices: [for (final m in methods) DonutSlice(context.methodName(ctx, m['method'] as String), parsePaisa(m['amount']).toDouble(), _methodColor(ctx, m['method'] as String))],
                  center: Column(mainAxisSize: MainAxisSize.min, children: [NumText(f.intN(methods.fold(0, (a, m) => a + (m['count'] as num).toInt())), size: 20, weight: 800), Text(context.tr('payments'), style: tt.labelSmall)]),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(children: [
                    for (final m in methods.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _methodColor(ctx, m['method'] as String), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(context.methodName(ctx, m['method'] as String), style: tt.bodyMedium)),
                          NumText(f.moneyCompact(parsePaisa(m['amount'])), size: 13),
                        ]),
                      ),
                  ]),
                ),
              ]),
      ),
    );

    final topCard = Surface(
      child: Section(
        title: context.tr('Best sellers'),
        subtitle: context.tr('Last 7 days'),
        child: top.isEmpty
            ? Text(context.tr('Nothing sold yet'), style: tt.bodyMedium!.copyWith(color: t.muted))
            : Column(children: [
                for (final p in top)
                  ShareBar(label: p['name'] as String, value: f.money(parsePaisa(p['revenue'])), fraction: parsePaisa(p['revenue']) / (parsePaisa(top.first['revenue']) == 0 ? 1 : parsePaisa(top.first['revenue']))),
              ]),
      ),
    );

    final lowCard = low.isEmpty && !(ctx.feature('inventory'))
        ? null
        : Surface(
            child: Section(
              title: context.tr('Running low'),
              subtitle: context.tr('At or below the reorder level'),
              action: TextButton(onPressed: () => context.go('/stock'), child: Text(context.tr('Stock'))),
              child: low.isEmpty
                  ? Row(children: [Icon(Icons.check_circle_rounded, color: t.success, size: 20), const SizedBox(width: 8), Text(context.tr('Everything is stocked'), style: tt.bodyMedium)])
                  : Column(children: [
                      for (final x in low.take(6))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(child: Text(x['label'] == '' ? x['name'] as String : '${x['name']} · ${x['label']}', style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Pill(parseMilli(x['on_hand']) <= 0 ? context.tr('Out') : '${f.qty(parseMilli(x['on_hand']))} ${x['unit']}', color: parseMilli(x['on_hand']) <= 0 ? t.danger : t.warning, dense: true),
                          ]),
                        ),
                    ]),
            ),
          );

    final expCard = ctx.cap('expiry_tracking') && ctx.feature('inventory')
        ? Surface(
            child: Section(
              title: context.tr('Expiring soon'),
              subtitle: context.tr('Within 60 days'),
              child: expiring.isEmpty
                  ? Row(children: [Icon(Icons.check_circle_rounded, color: t.success, size: 20), const SizedBox(width: 8), Text(context.tr('Nothing close to expiry'), style: tt.bodyMedium)])
                  : Column(children: [
                      for (final x in expiring.take(6))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(child: Text(x['label'] == '' ? x['name'] as String : '${x['name']} · ${x['label']}', style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${f.qty(parseMilli(x['qty']))}  ', style: tt.bodySmall),
                            Pill((x['days_left'] as num) < 0 ? context.tr('Expired') : '${f.intN((x['days_left'] as num).toInt())} ${context.tr('days')}', color: (x['days_left'] as num) <= 14 ? t.danger : t.warning, dense: true),
                          ]),
                        ),
                    ]),
            ),
          )
        : null;

    final duesCard = dues != null && ctx.cap('customer_credit')
        ? Surface(
            child: Section(
              title: '${context.term(ctx, 'due', 'Due')} · ${context.tr('who owes you')}',
              subtitle: context.trf('{amount} in total', {'amount': f.money(parsePaisa(dues['total']))}),
              action: TextButton(onPressed: () => context.go('/customers'), child: Text(context.tr('All'))),
              child: (dues['top'] as List).isEmpty
                  ? Text(context.tr('No one owes anything'), style: tt.bodyMedium!.copyWith(color: t.muted))
                  : Column(children: [
                      for (final x in (dues['top'] as List).cast<Map<String, dynamic>>())
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Monogram(x['name'] as String, size: 32, round: true),
                            const SizedBox(width: 10),
                            Expanded(child: Text(x['name'] as String, style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            NumText(f.money(parsePaisa(x['balance'])), size: 14, color: t.warning),
                          ]),
                        ),
                    ]),
            ),
          )
        : null;

    final hourCard = hourly.any((h) => parsePaisa(h['total']) > 0)
        ? Surface(
            child: Section(
              title: context.tr('Busy hours'),
              subtitle: context.tr('Today, by hour'),
              child: MiniBars(
                height: 110,
                values: [for (var h = 8; h <= 22; h++) parsePaisa(hourly[h]['total']) / 100],
                labels: [for (var h = 8; h <= 22; h++) f.digits('${h > 12 ? h - 12 : h}')],
                fmt: (v) => f.money((v * 100).round()),
                highlightLast: false,
              ),
            ),
          )
        : null;

    Widget grid(List<Widget> kids, {int cols = 2, double gap = 14}) => LayoutBuilder(builder: (c, box) {
          final n = box.maxWidth > 860 ? cols : 1;
          final w = (box.maxWidth - gap * (n - 1)) / n;
          return Wrap(spacing: gap, runSpacing: gap, children: [for (final k in kids) SizedBox(width: w, child: k)]);
        });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (c, box) {
        final cols = box.maxWidth > 900 ? 4 : 2;
        final w = (box.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [for (final tile in tiles) SizedBox(width: w, child: tile)]);
      }),
      const SizedBox(height: 14),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: trendCard), const SizedBox(width: 14), Expanded(flex: 2, child: mixCard)])
      else ...[trendCard, const SizedBox(height: 14), mixCard],
      const SizedBox(height: 14),
      grid([topCard, if (lowCard != null) lowCard, if (expCard != null) expCard, if (duesCard != null) duesCard, if (hourCard != null) hourCard]),
    ]);
  }
}

Color _methodColor(TenantContext ctx, String code) => ctx.paymentMethods.where((m) => m.code == code).firstOrNull?.color ?? const Color(0xFF64748B);

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
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        int n(String s) => list.where((o) => o['status'] == s).length;
        final due = list.where((o) => (o['status'] == 'confirmed' || o['status'] == 'ready') && o['delivery_date'] != null).toList()
          ..sort((a, b) => (a['delivery_date'] as String).compareTo(b['delivery_date'] as String));
        final receivable = list.where((o) => o['status'] == 'confirmed' || o['status'] == 'ready').fold<int>(0, (a, o) => a + parsePaisa(o['balance']));
        return Surface(
          child: Section(
            title: context.tr('Order pipeline'),
            subtitle: '${f.money(receivable)} ${context.tr('still to collect on open orders')}',
            action: TextButton(onPressed: () => context.go('/orders'), child: Text(context.tr('Open orders'))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (final (label, key, c) in [('Quotations', 'quotation', t.info), ('Confirmed', 'confirmed', t.accent), ('Ready', 'ready', t.warning), ('Delivered', 'delivered', t.success)])
                  Expanded(child: Column(children: [NumText(f.intN(n(key)), size: 26, weight: 800, color: c), Text(context.tr(label), style: tt.labelSmall)])),
              ]),
              if (due.isNotEmpty) ...[
                const Divider(height: 28),
                Text(context.tr('Next deliveries'), style: tt.titleSmall),
                const SizedBox(height: 8),
                for (final o in due.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(Icons.local_shipping_rounded, size: 18, color: t.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${o['number']} · ${o['customer_name']}', style: tt.bodyMedium)),
                      Pill(f.dateShort(DateTime.parse(o['delivery_date'] as String)), dense: true),
                    ]),
                  ),
              ],
            ]),
          ),
        );
      },
    );
  }
}
