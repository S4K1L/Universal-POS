import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/local/database.dart';
import '../../data/models/context.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import '../pos/receipt.dart';

class _Row {
  _Row({required this.id, required this.invoiceNo, required this.soldAt, required this.customer, required this.totalP, required this.paidP, required this.status, required this.syncState, this.flagged = false, this.server});
  final String id, invoiceNo, customer, status, syncState;
  final DateTime soldAt;
  final int totalP, paidP;
  final bool flagged;
  final Map<String, dynamic>? server;
  int get dueP => (totalP - paidP) < 0 ? 0 : totalP - paidP;
}

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _q = TextEditingController();
  String _range = 'today';
  bool _owing = false;
  final List<_Row> _server = [];
  bool _loading = true, _hasMore = false, _offline = false;
  Object? _error;
  int _offset = 0;
  Timer? _debounce;
  int _seenRevision = -1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _q.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _offset = 0;
      _server.clear();
    }
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });
    final now = DateTime.now();
    final from = switch (_range) { 'today' => now, '7d' => now.subtract(const Duration(days: 6)), '30d' => now.subtract(const Duration(days: 29)), _ => null };
    try {
      final res = await ref.read(apiProvider).getMap('/sales', query: {
        'limit': 30,
        'offset': _offset,
        if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
        if (from != null) 'date_from': _d(from),
        if (from != null) 'date_to': _d(now),
        if (_owing) 'owing': true,
      });
      final items = (res['items'] as List).cast<Map<String, dynamic>>();
      _server.addAll([
        for (final s in items)
          _Row(
            id: s['id'] as String,
            invoiceNo: s['invoice_no'] as String,
            soldAt: DateTime.parse(s['sold_at'] as String),
            customer: (s['customer_name'] as String?) ?? 'Walk-in',
            totalP: parsePaisa(s['total']),
            paidP: parsePaisa(s['paid']),
            status: s['status'] as String,
            syncState: 'synced',
            flagged: (s['flags'] as List).isNotEmpty,
            server: s,
          ),
      ]);
      _offset += items.length;
      _hasMore = _server.length < (res['total'] as num).toInt();
    } on ApiError catch (e) {
      _offline = e.offline;
      _error = e.offline ? null : e;
      _hasMore = false;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final rev = ref.watch(syncProvider.select((s) => s.revision));
    if (rev != _seenRevision) {
      if (_seenRevision != -1) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _load(reset: true) : null);
      _seenRevision = rev;
    }
    final local = ref.watch(_localSalesProvider).value ?? const <LSale>[];
    final localRows = [
      for (final s in local)
        _Row(id: s.id, invoiceNo: s.invoiceNo, soldAt: s.soldAt, customer: s.customerName, totalP: s.totalP, paidP: s.paidP, status: s.status, syncState: s.syncState),
    ];
    final q = _q.text.trim().toLowerCase();
    final now = DateTime.now();
    final fromLocal = switch (_range) { 'today' => DateTime(now.year, now.month, now.day), '7d' => now.subtract(const Duration(days: 6)), '30d' => now.subtract(const Duration(days: 29)), _ => DateTime(2000) };
    bool localMatch(_Row r) => r.soldAt.isAfter(fromLocal.subtract(const Duration(seconds: 1))) && (q.isEmpty || r.invoiceNo.toLowerCase().contains(q) || r.customer.toLowerCase().contains(q)) && (!_owing || r.dueP > 0);
    final pending = localRows.where((r) => r.syncState != 'synced' && localMatch(r)).toList();
    final rows = <_Row>[
      ...pending,
      if (_offline) ...localRows.where((r) => r.syncState == 'synced' && localMatch(r)) else ..._server.where((r) => !pending.any((p) => p.id == r.id)),
    ]..sort((a, b) => b.soldAt.compareTo(a.soldAt));
    final totalShown = rows.where((r) => r.status != 'voided').fold<int>(0, (a, r) => a + r.totalP);

    return PageBody(
      maxWidth: 1000,
      child: Column(children: [
        Row(children: [
          Expanded(child: AppSearchField(controller: _q, hint: context.tr('Search invoice or customer'), onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
          })),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            SegTabs<String>(items: [('today', context.tr('Today')), ('7d', context.tr('7 days')), ('30d', context.tr('30 days')), ('all', context.tr('All'))], value: _range, onChanged: (v) {
              setState(() => _range = v);
              _load(reset: true);
            }),
            const SizedBox(width: 10),
            FilterChip(label: Text(context.tr('Owing')), selected: _owing, onSelected: (v) {
              setState(() => _owing = v);
              _load(reset: true);
            }),
          ]),
        ),
        const SizedBox(height: 10),
        if (_offline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(color: t.tint(t.warning, 0.1), border: false, padding: const EdgeInsets.all(12), child: Row(children: [Icon(Icons.cloud_off_rounded, color: t.warning, size: 20), const SizedBox(width: 10), Expanded(child: Text(context.tr('Offline — showing the sales made on this till.'), style: tt.bodyMedium))])),
          ),
        Row(children: [
          Text('${f.intN(rows.length)} ${context.tr('sales')}', style: tt.labelMedium!.copyWith(color: t.muted)),
          const Spacer(),
          NumText(f.money(totalShown), size: 15, weight: 800),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: _error != null
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : rows.isEmpty && _loading
                  ? const SkeletonList(rows: 6, height: 66)
                  : rows.isEmpty
                      ? EmptyState(icon: Icons.receipt_long_rounded, title: context.tr('No sales found'), message: context.tr('Sales you ring up appear here the moment they are saved.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: rows.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == rows.length) {
                              return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: _loading ? null : () => _load(), child: Text(context.tr('Load more')))));
                            }
                            final r = rows[i];
                            return Padding(padding: const EdgeInsets.only(bottom: 8), child: _SaleTile(row: r, onTap: () => showSaleDetail(context, ref, r.id, r.server)));
                          },
                        ),
        ),
      ]),
    );
  }
}

final _localSalesProvider = StreamProvider.autoDispose<List<LSale>>((ref) {
  ref.cacheForSession();
  return ref.watch(salesRepoProvider).watchRecent(limit: 300);
});

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.row, required this.onTap});
  final _Row row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final voided = row.status == 'voided';
    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Monogram(row.customer == 'Walk-in' ? '#' : row.customer, size: 42, round: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(row.invoiceNo, style: tt.titleSmall!.copyWith(decoration: voided ? TextDecoration.lineThrough : null), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (row.flagged) ...[const SizedBox(width: 6), Icon(Icons.flag_rounded, size: 16, color: t.warning)],
            ]),
            Text('${row.customer == 'Walk-in' ? context.tr('Walk-in') : row.customer} · ${f.dateTime(row.soldAt)}', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          NumText(f.money(row.totalP, decimals: true), size: 15, weight: 800, color: voided ? t.faint : t.text),
          const SizedBox(height: 4),
          Wrap(spacing: 4, children: [
            if (voided) Pill(context.tr('Void'), color: t.danger, dense: true)
            else if (row.dueP > 0) Pill('${context.tr('Due')} ${f.money(row.dueP)}', color: t.warning, dense: true)
            else Pill(context.tr('Paid'), color: t.success, dense: true),
            if (row.syncState == 'pending') Pill(context.tr('Waiting to sync'), color: t.info, dense: true, icon: Icons.schedule_rounded),
            if (row.syncState == 'failed') Pill(context.tr('Not synced'), color: t.danger, dense: true, icon: Icons.error_outline_rounded),
          ]),
        ]),
      ]),
    );
  }
}

// -------------------------------------------------------------------------------------- detail

Future<void> showSaleDetail(BuildContext context, WidgetRef ref, String saleId, Map<String, dynamic>? server) =>
    showPanel<void>(context, maxWidth: 520, builder: (_) => _SaleDetail(saleId: saleId, server: server));

class _SaleDetail extends ConsumerStatefulWidget {
  const _SaleDetail({required this.saleId, this.server});
  final String saleId;
  final Map<String, dynamic>? server;

  @override
  ConsumerState<_SaleDetail> createState() => _SaleDetailState();
}

class _SaleDetailState extends ConsumerState<_SaleDetail> {
  final _key = GlobalKey();
  ReceiptData? _data;
  // what the return / due actions need, whichever side the sale came from
  List<({String id, String name, int qtyMilli, int returnedMilli, int chargedP, String unit})> _lines = [];
  int _totalP = 0, _paidP = 0;
  String? _customerId;
  String _status = 'completed';
  String _sync = 'synced';
  bool _local = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ctx = ref.read(ctxProvider);
    final repo = ref.read(salesRepoProvider);
    try {
      final bundle = await repo.bundleOf(widget.saleId);
      if (bundle != null) {
        _local = true;
        _data = ReceiptData.fromBundle(bundle, ctx);
        _lines = [for (final l in bundle.lines) (id: l.id, name: l.productName, qtyMilli: l.qtyMilli, returnedMilli: l.returnedQtyMilli, chargedP: l.chargedP, unit: l.unit)];
        _totalP = bundle.sale.totalP;
        _paidP = bundle.sale.paidP;
        _customerId = bundle.sale.customerId;
        _status = bundle.sale.status;
        _sync = bundle.sale.syncState;
      } else {
        final s = widget.server ?? await ref.read(apiProvider).getMap('/sales/${widget.saleId}');
        _data = ReceiptData.fromServer(s, ctx);
        _lines = [for (final l in (s['lines'] as List).cast<Map<String, dynamic>>()) (id: l['id'] as String, name: l['product_name'] as String, qtyMilli: parseMilli(l['qty']), returnedMilli: parseMilli(l['returned_qty']), chargedP: parsePaisa(l['charged_total']), unit: l['unit'] as String)];
        _totalP = parsePaisa(s['total']);
        _paidP = parsePaisa(s['paid']);
        _customerId = s['customer_id'] as String?;
        _status = s['status'] as String;
      }
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() {});
  }

  int get _dueP => (_totalP - _paidP) < 0 ? 0 : _totalP - _paidP;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ctx = ref.watch(ctxProvider);
    if (_error != null) return PanelScaffold(title: context.tr('Sale'), child: ErrorView(error: _error!, onRetry: _load));
    final d = _data;
    if (d == null) return PanelScaffold(title: context.tr('Sale'), child: const SkeletonList(rows: 4, height: 60));
    final canReturn = ctx.can('refund') && _status == 'completed' && _lines.any((l) => l.qtyMilli > l.returnedMilli);
    final canCollect = ctx.can('collect_dues') && _status == 'completed' && _dueP > 0;
    final canVoid = ctx.can('void_sale') && _status == 'completed';
    return PanelScaffold(
      title: d.invoiceNo,
      subtitle: context.fmt.dateTime(d.when),
      padBody: false,
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _busyRun(() => ReceiptPrinter.print(_key, d.invoiceNo)), icon: const Icon(Icons.print_rounded, size: 19), label: Text(context.tr('Print')))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () => _busyRun(() => ReceiptPrinter.share(_key, d.invoiceNo)), icon: const Icon(Icons.ios_share_rounded, size: 19), label: Text(context.tr('Share')))),
        ]),
        if (canCollect || canReturn || canVoid) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (canCollect) Expanded(child: FilledButton.icon(onPressed: () => _collect(ctx), icon: const Icon(Icons.payments_rounded, size: 19), label: Text('${context.tr('Collect')} ${context.fmt.money(_dueP)}'))),
            if (canCollect && (canReturn || canVoid)) const SizedBox(width: 8),
            if (canReturn) Expanded(child: OutlinedButton.icon(onPressed: () => _return(ctx), icon: const Icon(Icons.assignment_return_rounded, size: 19), label: Text(context.tr('Return')))),
            if (canReturn && canVoid) const SizedBox(width: 8),
            if (canVoid) Expanded(child: OutlinedButton.icon(onPressed: _void, icon: Icon(Icons.block_rounded, size: 19, color: t.danger), label: Text(context.tr('Void'), style: TextStyle(color: t.danger)))),
          ]),
        ],
      ]),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(children: [
          if (_sync == 'pending') Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(color: t.tint(t.info, 0.1), border: false, padding: const EdgeInsets.all(10), child: Row(children: [Icon(Icons.schedule_rounded, size: 18, color: t.info), const SizedBox(width: 8), Expanded(child: Text(context.tr('Saved on this till — waiting to sync.'), style: Theme.of(context).textTheme.bodySmall))]))),
          if (_sync == 'failed') Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(color: t.tint(t.danger, 0.1), border: false, padding: const EdgeInsets.all(10), child: Row(children: [Icon(Icons.error_outline_rounded, size: 18, color: t.danger), const SizedBox(width: 8), Expanded(child: Text(context.tr('The server refused this sale. See the Sync center.'), style: Theme.of(context).textTheme.bodySmall))]))),
          Center(child: ReceiptView(data: d, boundaryKey: _key)),
        ]),
      ),
    );
  }

  Future<void> _busyRun(Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  Future<void> _collect(TenantContext ctx) async {
    final ok = await showPanel<bool>(context, maxWidth: 420, builder: (_) => _CollectPanel(dueP: _dueP, customerId: _customerId, saleId: widget.saleId));
    if (ok == true && mounted) {
      toast(context, context.tr('Payment saved'), good: true);
      Navigator.pop(context);
    }
  }

  Future<void> _return(TenantContext ctx) async {
    final ok = await showPanel<bool>(context, maxWidth: 480, builder: (_) => _ReturnPanel(saleId: widget.saleId, lines: _lines, local: _local));
    if (ok == true && mounted) {
      toast(context, context.tr('Return recorded'), good: true);
      Navigator.pop(context);
    }
  }

  Future<void> _void() async {
    final reason = TextEditingController();
    final ok = await showPanel<bool>(
      context,
      maxWidth: 420,
      builder: (c) => PanelScaffold(
        title: context.tr('Void this sale?'),
        subtitle: context.tr('The goods go back on the shelf and the sale stops counting in reports.'),
        footer: Row(children: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('Cancel'))),
          const Spacer(),
          FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: context.t.danger, foregroundColor: Colors.white), child: Text(context.tr('Void sale'))),
        ]),
        child: TextField(controller: reason, decoration: InputDecoration(labelText: context.tr('Reason'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
      ),
    );
    if (ok == true) {
      await ref.read(salesRepoProvider).voidSale(widget.saleId, reason.text.trim());
      if (mounted) {
        toast(context, context.tr('Sale voided'), good: true);
        Navigator.pop(context);
      }
    }
  }
}

class _CollectPanel extends ConsumerStatefulWidget {
  const _CollectPanel({required this.dueP, required this.saleId, this.customerId});
  final int dueP;
  final String saleId;
  final String? customerId;

  @override
  ConsumerState<_CollectPanel> createState() => _CollectPanelState();
}

class _CollectPanelState extends ConsumerState<_CollectPanel> {
  late final _amount = TextEditingController(text: paisaToWire(widget.dueP).replaceAll(RegExp(r'\.00$'), ''));
  final _ref = TextEditingController();
  String _method = 'cash';

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final amount = paisaOf(_amount);
    final bad = amount <= 0 || amount > widget.dueP;
    return PanelScaffold(
      title: context.tr('Collect payment'),
      subtitle: '${context.tr('Still due')} ${context.fmt.money(widget.dueP, decimals: true)}',
      footer: FilledButton(
        onPressed: bad
            ? null
            : () async {
                await ref.read(salesRepoProvider).collectDue(saleId: widget.saleId, customerId: widget.customerId, amountP: amount, method: _method, reference: _ref.text.trim());
                if (context.mounted) Navigator.pop(context, true);
              },
        child: Text('${context.tr('Receive')} ${context.fmt.money(amount, decimals: true)}'),
      ),
      child: Column(children: [
        MoneyField(controller: _amount, label: context.tr('Amount'), symbol: ctx.currencySymbol, autofocus: true, onChanged: (_) => setState(() {}), helper: amount > widget.dueP ? context.tr('More than what is due') : null),
        const FormGap(),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in ctx.enabledPaymentMethods) ChoiceChip(avatar: Icon(m.icon, size: 17, color: m.color), label: Text(m.label), selected: _method == m.code, onSelected: (_) => setState(() => _method = m.code)),
        ]),
        if (ctx.enabledPaymentMethods.where((m) => m.code == _method).firstOrNull?.needsReference ?? false) ...[
          const FormGap(),
          TextField(controller: _ref, decoration: InputDecoration(labelText: context.tr('Transaction ID / reference'), prefixIcon: const Icon(Icons.tag_rounded, size: 19))),
        ],
      ]),
    );
  }
}

class _ReturnPanel extends ConsumerStatefulWidget {
  const _ReturnPanel({required this.saleId, required this.lines, required this.local});
  final String saleId;
  final List<({String id, String name, int qtyMilli, int returnedMilli, int chargedP, String unit})> lines;
  final bool local;

  @override
  ConsumerState<_ReturnPanel> createState() => _ReturnPanelState();
}

class _ReturnPanelState extends ConsumerState<_ReturnPanel> {
  final Map<String, int> _qty = {};
  bool _restock = true, _busy = false;
  final _reason = TextEditingController();

  int get _refund => widget.lines.fold(0, (a, l) {
        final q = _qty[l.id] ?? 0;
        return a + (q == 0 ? 0 : (q >= l.qtyMilli - l.returnedMilli ? l.chargedP : l.chargedP * q ~/ l.qtyMilli));
      });

  Future<void> _submit() async {
    final lines = {for (final e in _qty.entries) if (e.value > 0) e.key: e.value};
    if (lines.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (widget.local) {
        await ref.read(salesRepoProvider).returnItems(saleId: widget.saleId, lines: lines, restock: _restock, reason: _reason.text.trim());
      } else {
        await ref.read(apiProvider).post('/sales/${widget.saleId}/returns', body: {
          'id': newId(),
          'sale_id': widget.saleId,
          'lines': [for (final e in lines.entries) {'sale_line_id': e.key, 'qty': milliToWire(e.value)}],
          'restock': _restock,
          'reason': _reason.text.trim(),
        });
        ref.read(syncProvider.notifier).kick();
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.offline ? context.tr('Returns on sales from another till need a connection.') : e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    return PanelScaffold(
      title: context.tr('Return items'),
      subtitle: context.tr('Pick what came back.'),
      footer: FilledButton(onPressed: _busy || _refund == 0 ? null : _submit, child: Text('${context.tr('Refund')} ${f.money(_refund, decimals: true)}')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final l in widget.lines)
          if (l.qtyMilli > l.returnedMilli)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l.name, style: tt.titleSmall), Text('${context.tr('Bought')} ${f.qty(l.qtyMilli)} ${l.unit}${l.returnedMilli > 0 ? ' · ${f.qty(l.returnedMilli)} ${context.tr('already returned')}' : ''}', style: tt.bodySmall)])),
                  IconButton(onPressed: (_qty[l.id] ?? 0) <= 0 ? null : () => setState(() => _qty[l.id] = ((_qty[l.id] ?? 0) - 1000).clamp(0, 1 << 40)), icon: const Icon(Icons.remove_circle_outline_rounded)),
                  SizedBox(width: 34, child: NumText(f.qty(_qty[l.id] ?? 0), size: 15, align: TextAlign.center)),
                  IconButton(onPressed: (_qty[l.id] ?? 0) >= l.qtyMilli - l.returnedMilli ? null : () => setState(() => _qty[l.id] = ((_qty[l.id] ?? 0) + 1000).clamp(0, l.qtyMilli - l.returnedMilli)), icon: Icon(Icons.add_circle_rounded, color: t.accent)),
                ]),
              ),
            ),
        const FormGap(6),
        SwitchRow(title: context.tr('Put back on the shelf'), subtitle: context.tr('Turn off for damaged goods'), value: _restock, onChanged: (v) => setState(() => _restock = v)),
        TextField(controller: _reason, decoration: InputDecoration(labelText: context.tr('Reason'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
        const FormGap(),
        Text(context.tr('If the customer still owes on this invoice, the refund is taken off what they owe first; only the rest is paid back.'), style: tt.bodySmall),
      ]),
    );
  }
}
