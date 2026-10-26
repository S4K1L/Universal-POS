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
import '../../core/util/responsive.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import '../sales/sales_screen.dart' show showSaleDetail;
import 'report_blocks.dart';
import 'report_doc.dart';
import 'report_pdf.dart';

typedef _Range = ({String from, String to});

String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _reportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, _Range>((ref, r) async {
  ref.cacheForSession(revalidate: true);
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
    api.getList('/reports/top-products', query: {...q, 'limit': ReportDoc.topProductLimit}),
    api.getList('/reports/by-category', query: q),
    api.getList('/reports/cashiers', query: q),
    opt(() => api.getMap('/reports/stock-valuation')),
    ctx.cap('customer_credit') ? opt(() => api.getMap('/reports/dues')) : Future.value(null),
    ctx.can('view_margin') ? opt(() => api.getList('/reports/exceptions', query: q)) : Future.value(null),
    ctx.feature('expenses') ? opt(() => api.getMap('/reports/expenses', query: q)) : Future.value(null),
    opt(() => api.getMap('/sales', query: {...q, 'status': 'completed', 'limit': ReportDoc.registerLimit})),
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
    'register': results[9],
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
  bool _pdfBusy = false;

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

  Future<void> _downloadPdf(ReportDoc doc) async {
    setState(() => _pdfBusy = true);
    try {
      await downloadReportPdf(doc);
    } catch (e) {
      if (mounted) toast(context, context.tr('Could not create the PDF'), error: true);
    }
    if (mounted) setState(() => _pdfBusy = false);
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
        SingleChildScrollView(
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
        const SizedBox(height: 14),
        AsyncBody<Map<String, dynamic>>(
          value: data,
          onRetry: () => ref.invalidate(_reportProvider(_range)),
          loading: const SkeletonList(rows: 4, height: 120),
          data: (d) {
            final days = (d['days'] as List).cast<Map<String, dynamic>>();
            final cats = (d['categories'] as List).cast<Map<String, dynamic>>();
            final cashiers = (d['cashiers'] as List).cast<Map<String, dynamic>>();
            final dues = (d['dues'] as Map?)?.cast<String, dynamic>();
            final exceptions = (d['exceptions'] as List?)?.cast<Map<String, dynamic>>();
            final reg = (d['register'] as Map?)?.cast<String, dynamic>();
            final doc = ReportDoc.fromData(
              d,
              ctx,
              from: DateTime.parse(_range.from),
              to: DateTime.parse(_range.to),
              register: ((reg?['items'] as List?) ?? const []).cast<Map<String, dynamic>>(),
              registerTotal: (reg?['total'] as num?)?.toInt() ?? 0,
            );

            final stacked = context.width < 640;
            final wide = context.width >= 900;
            final accentDeep = doc.palette.deep;
            final step = days.length > 16 ? (days.length / 10).ceil() : 1;
            final totals = [for (final x in days) parsePaisa(x['total'])];
            final bestDay = totals.isEmpty || totals.every((v) => v == 0) ? -1 : totals.indexOf(totals.reduce((a, b) => a > b ? a : b));
            final canCsv = ctx.feature('export') && ctx.can('export_data');

            final actions = Wrap(spacing: 10, runSpacing: 8, alignment: stacked ? WrapAlignment.start : WrapAlignment.end, children: [
              FilledButton.icon(
                onPressed: _pdfBusy ? null : () => _downloadPdf(doc),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: accentDeep, disabledBackgroundColor: Colors.white70),
                icon: _pdfBusy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: accentDeep)) : const Icon(Icons.picture_as_pdf_rounded, size: 19),
                label: Text(context.tr('Download PDF')),
              ),
              if (canCsv)
                OutlinedButton.icon(
                  onPressed: () => _export(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                  icon: const Icon(Icons.table_view_rounded, size: 19),
                  label: Text(context.tr('Export')),
                ),
            ]);

            Widget titled(String heading, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ReportHeading(heading, accent: doc.accent), child]);
            Widget card(Widget child) => Surface(child: child);
            const gap = SizedBox(height: 22);

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ReportBanner(doc: doc, action: actions, stacked: stacked),
              const SizedBox(height: 18),
              ReportIdentity(doc: doc, stacked: stacked),
              gap,
              titled('Summary', ReportKpis(doc: doc, fourUp: !stacked)),
              gap,
              if (wide && doc.payments.isNotEmpty && doc.hasValuation)
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(flex: 3, child: titled('Sales by payment method', ReportPayments(doc: doc, compact: false))),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: titled('Inventory valuation', ReportValuation(doc: doc))),
                  ]),
                )
              else ...[
                if (doc.payments.isNotEmpty) titled('Sales by payment method', ReportPayments(doc: doc, compact: stacked)),
                if (doc.payments.isNotEmpty && doc.hasValuation) gap,
                if (doc.hasValuation) titled('Inventory valuation', ReportValuation(doc: doc)),
              ],
              gap,
              titled('Top selling products', ReportProducts(doc: doc, compact: stacked)),
              gap,
              titled('Invoice register', ReportRegister(doc: doc, rows: 25, compact: stacked, onOpen: (inv) => showSaleDetail(context, ref, inv.id, null))),
              gap,
              titled(
                'Sales by day',
                card(days.isEmpty
                    ? Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text(context.tr('No sales in this period'), style: tt.bodyMedium!.copyWith(color: t.muted))))
                    : BarChart(
                        height: context.isCompact ? 180 : 220,
                        values: [for (final x in days) parsePaisa(x['total']).toDouble()],
                        // a long range shows every few days' number so the labels never crowd
                        labels: [for (final (i, x) in days.indexed) i % step == 0 || i == days.length - 1 ? f.digits('${DateTime.parse(x['date'] as String).day}') : ''],
                        tips: [for (final x in days) '${f.dateShort(DateTime.parse(x['date'] as String))} · ${f.money(parsePaisa(x['total']))}'],
                        axis: (v) => f.moneyCompact(v.round()),
                        highlight: bestDay,
                      )),
              ),
              if (cats.isNotEmpty || cashiers.isNotEmpty) ...[
                gap,
                CardGrid(children: [
                  if (cats.isNotEmpty)
                    titled('By category', card(Column(children: [for (final x in cats.take(8)) ShareBar(label: x['category'] as String, value: f.money(parsePaisa(x['revenue'])), fraction: parsePaisa(x['revenue']) / (parsePaisa(cats.first['revenue']) == 0 ? 1 : parsePaisa(cats.first['revenue'])), color: t.info)]))),
                  if (cashiers.isNotEmpty)
                    titled(
                      'Staff',
                      card(Column(children: [
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
                      ])),
                    ),
                ]),
              ],
              if (dues != null) ...[
                gap,
                titled(
                  context.term(ctx, 'due', 'Due'),
                  card(Column(children: [
                    KV(context.tr('Outstanding now'), f.money(parsePaisa(dues['total'])), bold: true),
                    for (final k in ['0-30', '31-60', '61-90', '90+']) KV('$k ${context.tr('days')}', f.money(parsePaisa((dues['ageing'] as Map)[k])), color: k == '90+' && parsePaisa((dues['ageing'] as Map)[k]) > 0 ? t.danger : null),
                  ])),
                ),
              ],
              if (exceptions != null && exceptions.isNotEmpty) ...[
                gap,
                titled(
                  'Worth a look',
                  card(Column(children: [
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
                  ])),
                ),
              ],
              gap,
              ReportFooter(doc: doc),
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
