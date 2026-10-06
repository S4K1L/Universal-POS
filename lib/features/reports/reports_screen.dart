import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

typedef _Range = ({String from, String to});

String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _reportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, _Range>((ref, r) async {
  ref.watch(syncProvider.select((s) => s.revision));
  final api = ref.watch(apiProvider);
  final ctx = ref.watch(ctxProvider);
  final q = {'date_from': r.from, 'date_to': r.to};
  Future<T?> opt<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on ApiError catch (e) {
      if (e.offline) rethrow;
      return null;
    }
  }

  final results = await Future.wait<Object?>([
    api.getMap('/reports/summary', query: q),
    api.getList('/reports/sales-by-day', query: q),
    api.getList('/reports/top-products', query: {...q, 'limit': 8}),
    api.getList('/reports/by-category', query: q),
    api.getList('/reports/cashiers', query: q),
    opt(() => api.getMap('/reports/stock-valuation')),
    ctx.cap('customer_credit') ? opt(() => api.getMap('/reports/dues')) : Future.value(null),
    ctx.can('view_margin') ? opt(() => api.getList('/reports/exceptions', query: q)) : Future.value(null),
    ctx.feature('expenses') ? opt(() => api.getMap('/reports/expenses', query: q)) : Future.value(null),
  ]);
  return {
    'summary': results[0],
    'days': results[1],
    'top': results[2],
    'categories': results[3],
    'cashiers': results[4],
    'valuation': results[5],
    'dues': results[6],
    'exceptions': results[7],
    'expenses': results[8],
  };
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _preset = '7d';
  DateTimeRange? _custom;

  _Range get _range {
    final now = DateTime.now();
    switch (_preset) {
      case 'today':
        return (from: _d(now), to: _d(now));
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        return (from: _d(y), to: _d(y));
      case '30d':
        return (from: _d(now.subtract(const Duration(days: 29))), to: _d(now));
      case 'month':
        return (from: _d(DateTime(now.year, now.month, 1)), to: _d(now));
      case 'custom':
        return (from: _d(_custom!.start), to: _d(_custom!.end));
      default:
        return (from: _d(now.subtract(const Duration(days: 6))), to: _d(now));
    }
  }

  Future<void> _export(BuildContext context) async {
    try {
      final r = await ref.read(apiProvider).dio.get<String>('/reports/export/sales.csv', queryParameters: {'date_from': _range.from, 'date_to': _range.to}, options: Options(responseType: ResponseType.plain));
      await Clipboard.setData(ClipboardData(text: r.data ?? ''));
      if (context.mounted) toast(context, context.tr('Sales CSV copied — paste it into Excel or Sheets'), good: true);
    } on DioException catch (e) {
      if (context.mounted) toast(context, ref.read(apiProvider).wrap(e).message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final data = ref.watch(_reportProvider(_range));

    return PageBody(
      maxWidth: 1100,
      child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
        Row(children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegTabs<String>(
                items: [('today', context.tr('Today')), ('yesterday', context.tr('Yesterday')), ('7d', context.tr('7 days')), ('30d', context.tr('30 days')), ('month', context.tr('This month')), ('custom', context.tr('Custom'))],
                value: _preset,
                onChanged: (v) async {
                  if (v == 'custom') {
                    final r = await showDateRangePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 400)), lastDate: DateTime.now(), initialDateRange: _custom);
                    if (r == null) return;
                    setState(() {
                      _custom = r;
                      _preset = 'custom';
                    });
                  } else {
                    setState(() => _preset = v);
                  }
                },
              ),
            ),
          ),
          if (ctx.feature('export') && ctx.can('export_data')) ...[const SizedBox(width: 10), OutlinedButton.icon(onPressed: () => _export(context), icon: const Icon(Icons.table_view_rounded, size: 19), label: Text(context.tr('Export')))],
        ]),
        const SizedBox(height: 14),
        AsyncBody<Map<String, dynamic>>(
          value: data,
          onRetry: () => ref.invalidate(_reportProvider(_range)),
          loading: const SkeletonList(rows: 4, height: 120),
          data: (d) {
            final s = (d['summary'] as Map).cast<String, dynamic>();
            final days = (d['days'] as List).cast<Map<String, dynamic>>();
            final top = (d['top'] as List).cast<Map<String, dynamic>>();
            final cats = (d['categories'] as List).cast<Map<String, dynamic>>();
            final cashiers = (d['cashiers'] as List).cast<Map<String, dynamic>>();
            final val = (d['valuation'] as Map?)?.cast<String, dynamic>();
            final dues = (d['dues'] as Map?)?.cast<String, dynamic>();
            final exceptions = (d['exceptions'] as List?)?.cast<Map<String, dynamic>>();
            final exp = (d['expenses'] as Map?)?.cast<String, dynamic>();
            final methods = (s['by_method'] as List).cast<Map<String, dynamic>>();
            final gross = parsePaisa(s['gross_sales']);
            final net = parsePaisa(s['net_sales']);
            final tiles = [
              StatTile(label: context.tr('Sales'), value: f.money(gross), icon: Icons.payments_rounded, hint: '${f.intN(s['invoices'] as int)} ${context.tr('invoices')}', spark: [for (final x in days) parsePaisa(x['total']) / 100]),
              StatTile(label: context.tr('Net of returns'), value: f.money(net), icon: Icons.assignment_return_rounded, color: t.info, hint: '${f.money(parsePaisa(s['returns_total']))} ${context.tr('returned')}'),
              if (s['gross_profit'] != null) StatTile(label: context.tr('Gross profit'), value: f.money(parsePaisa(s['gross_profit'])), icon: Icons.trending_up_rounded, color: t.success, hint: gross > 0 ? '${(parsePaisa(s['gross_profit']) * 100 / gross).toStringAsFixed(1)}% ${context.tr('margin')}' : null)
              else StatTile(label: context.tr('Average bill'), value: f.money(parsePaisa(s['avg_bill'])), icon: Icons.receipt_rounded, color: t.success),
              if (exp != null) StatTile(label: context.tr('Expenses'), value: f.money(parsePaisa(exp['total'])), icon: Icons.account_balance_wallet_rounded, color: t.warning, hint: s['gross_profit'] == null ? null : '${context.tr('profit after expenses')} ${f.money(parsePaisa(s['gross_profit']) - parsePaisa(exp['total']))}')
              else StatTile(label: context.tr('Discounts'), value: f.money(parsePaisa(s['discounts'])), icon: Icons.percent_rounded, color: t.warning),
            ];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LayoutBuilder(builder: (c, box) {
                final cols = box.maxWidth > 900 ? 4 : 2;
                final w = (box.maxWidth - 12 * (cols - 1)) / cols;
                return Wrap(spacing: 12, runSpacing: 12, children: [for (final x in tiles) SizedBox(width: w, child: x)]);
              }),
              const SizedBox(height: 14),
              Surface(
                child: Section(
                  title: context.tr('Sales by day'),
                  child: MiniBars(
                    height: 170,
                    values: [for (final x in days) parsePaisa(x['total']) / 100],
                    labels: [for (final x in days) days.length > 16 ? '' : f.digits('${DateTime.parse(x['date'] as String).day}')],
                    fmt: (v) => f.money((v * 100).round()),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (c, box) {
                final two = box.maxWidth > 820;
                final mix = Surface(
                  child: Section(
                    title: context.tr('Payment methods'),
                    child: methods.isEmpty
                        ? Text(context.tr('No payments in this period'), style: tt.bodyMedium!.copyWith(color: t.muted))
                        : Column(children: [
                            for (final m in methods)
                              ShareBar(
                                label: context.methodName(ctx, m['method'] as String),
                                value: f.money(parsePaisa(m['amount'])),
                                fraction: parsePaisa(m['amount']) / (parsePaisa(methods.first['amount']) == 0 ? 1 : parsePaisa(methods.first['amount'])),
                                color: ctx.paymentMethods.where((x) => x.code == m['method']).firstOrNull?.color,
                              ),
                          ]),
                  ),
                );
                final topCard = Surface(
                  child: Section(
                    title: context.tr('Best sellers'),
                    child: top.isEmpty
                        ? Text(context.tr('Nothing sold in this period'), style: tt.bodyMedium!.copyWith(color: t.muted))
                        : Column(children: [for (final p in top) ShareBar(label: p['name'] as String, value: f.money(parsePaisa(p['revenue'])), fraction: parsePaisa(p['revenue']) / (parsePaisa(top.first['revenue']) == 0 ? 1 : parsePaisa(top.first['revenue'])))]),
                  ),
                );
                return two ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: mix), const SizedBox(width: 14), Expanded(child: topCard)]) : Column(children: [mix, const SizedBox(height: 14), topCard]);
              }),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (c, box) {
                final two = box.maxWidth > 820;
                final catCard = Surface(
                  child: Section(
                    title: context.tr('By category'),
                    child: cats.isEmpty ? Text('—', style: tt.bodyMedium) : Column(children: [for (final x in cats.take(8)) ShareBar(label: x['category'] as String, value: f.money(parsePaisa(x['revenue'])), fraction: parsePaisa(x['revenue']) / (parsePaisa(cats.first['revenue']) == 0 ? 1 : parsePaisa(cats.first['revenue'])), color: t.info)]),
                  ),
                );
                final staffCard = Surface(
                  child: Section(
                    title: context.tr('Staff'),
                    child: cashiers.isEmpty
                        ? Text('—', style: tt.bodyMedium)
                        : Column(children: [
                            for (final x in cashiers)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(children: [
                                  Monogram(x['cashier'] as String, size: 34, round: true),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x['cashier'] as String, style: tt.titleSmall), Text('${f.intN(x['invoices'] as int)} ${context.tr('invoices')}${parsePaisa(x['discounts']) > 0 ? ' · ${context.tr('discounts')} ${f.money(parsePaisa(x['discounts']))}' : ''}', style: tt.bodySmall)])),
                                  NumText(f.money(parsePaisa(x['total'])), size: 14, weight: 800),
                                ]),
                              ),
                          ]),
                  ),
                );
                return two ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: catCard), const SizedBox(width: 14), Expanded(child: staffCard)]) : Column(children: [catCard, const SizedBox(height: 14), staffCard]);
              }),
              if (val != null || dues != null) ...[
                const SizedBox(height: 14),
                LayoutBuilder(builder: (c, box) {
                  final two = box.maxWidth > 820;
                  final valCard = val == null
                      ? null
                      : Surface(
                          child: Section(title: context.tr('Stock on hand'), subtitle: context.tr('Right now'), child: Column(children: [
                            KV(context.tr('Units'), f.qty(parseMilli(val['units']))),
                            KV(context.tr('Retail value'), f.money(parsePaisa(val['retail_value']))),
                            if (val['cost_value'] != null) KV(context.tr('Cost value'), f.money(parsePaisa(val['cost_value']))),
                            if (val['potential_profit'] != null) KV(context.tr('Potential profit'), f.money(parsePaisa(val['potential_profit'])), color: t.success),
                          ])),
                        );
                  final duesCard = dues == null
                      ? null
                      : Surface(
                          child: Section(title: context.term(ctx, 'due', 'Due'), subtitle: '${f.money(parsePaisa(dues['total']))} ${context.tr('outstanding')}', child: Column(children: [
                            for (final k in ['0-30', '31-60', '61-90', '90+']) KV('$k ${context.tr('days')}', f.money(parsePaisa((dues['ageing'] as Map)[k])), color: k == '90+' && parsePaisa((dues['ageing'] as Map)[k]) > 0 ? t.danger : null),
                          ])),
                        );
                  final kids = [?valCard, ?duesCard];
                  return two && kids.length == 2 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: kids[0]), const SizedBox(width: 14), Expanded(child: kids[1])]) : Column(children: [for (final k in kids) Padding(padding: const EdgeInsets.only(bottom: 14), child: k)]);
                }),
              ],
              if (exceptions != null && exceptions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Surface(
                  child: Section(
                    title: context.tr('Worth a look'),
                    subtitle: context.tr('Sales the system flagged — price changes, unusual discounts, stock shortfalls'),
                    child: Column(children: [
                      for (final x in exceptions.take(10))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.flag_rounded, size: 19, color: t.warning),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${x['invoice_no']} · ${x['cashier']}', style: tt.titleSmall), Text([for (final fl in (x['flags'] as List).cast<Map<String, dynamic>>()) _flagLabel(context, fl['code'] as String)].join(' · '), style: tt.bodySmall)])),
                            NumText(f.money(parsePaisa(x['total'])), size: 14),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ],
            ]);
          },
        ),
      ]),
    );
  }
}

String _flagLabel(BuildContext context, String code) => context.tr(switch (code) {
      'price_override' => 'Price changed',
      'discount_not_permitted' => 'Discount without permission',
      'oversold' => 'Sold below zero stock',
      'total_mismatch' => 'Total differs from server',
      'due_without_customer' => 'Unpaid with no customer',
      'credit_limit_exceeded' => 'Over credit limit',
      'branch_not_allowed' => 'Wrong branch',
      'invoice_renumbered' => 'Invoice renumbered',
      'fractional_qty' => 'Fractional quantity',
      'credit_not_enabled' => 'Credit not enabled',
      _ => code,
    });
