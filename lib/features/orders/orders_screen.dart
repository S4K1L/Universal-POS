import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/money/pricing.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/models/context.dart';
import '../../data/repos/catalogue_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import '../pos/receipt.dart';

final _ordersProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, status) async {
  ref.cacheForSession(revalidate: true);
  ref.watch(syncProvider.select((s) => s.revision));
  return ref.watch(apiProvider).getMap('/orders', query: {'limit': 100, if (status != 'all') 'status': status});
});

const _statuses = [('all', 'All'), ('quotation', 'Quotations'), ('confirmed', 'Confirmed'), ('ready', 'Ready'), ('delivered', 'Delivered'), ('cancelled', 'Cancelled')];

Color _statusColor(Tokens t, String s) => switch (s) {
      'quotation' => t.info,
      'confirmed' => t.accent,
      'ready' => t.warning,
      'delivered' => t.success,
      _ => t.faint,
    };

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _status = 'all';
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(_ordersProvider(_status));

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(_ordersProvider(_status));
    return PageBody(
      maxWidth: 1000,
      child: Column(children: [
        Row(children: [
          Expanded(child: AppSearchField(controller: _q, hint: context.tr('Search order or customer'), onChanged: (_) => setState(() {}))),
          const SizedBox(width: 10),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () async {
                final r = await showPanel<bool>(context, maxWidth: 780, dismissible: false, builder: (_) => const OrderBuilder());
                if (r == true) _refresh();
              },
              icon: const Icon(Icons.add_rounded, size: 21),
              label: Text(context.tr('New quotation')),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegTabs<String>(items: [for (final (k, l) in _statuses) (k, context.tr(l))], value: _status, onChanged: (v) => setState(() => _status = v))),
        const SizedBox(height: 10),
        Expanded(
          child: AsyncBody<Map<String, dynamic>>(
            value: data,
            onRetry: _refresh,
            data: (d) {
              final q = _q.text.trim().toLowerCase();
              final items = (d['items'] as List).cast<Map<String, dynamic>>().where((o) => q.isEmpty || (o['number'] as String).toLowerCase().contains(q) || (o['customer_name'] as String).toLowerCase().contains(q)).toList();
              if (items.isEmpty) return EmptyState(icon: Icons.request_quote_outlined, title: context.tr('No orders here'), message: context.tr('Draft a quotation for a customer, take a deposit to confirm it, then deliver and invoice.'));
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final o = items[i];
                  final c = _statusColor(t, o['status'] as String);
                  final bal = parsePaisa(o['balance']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Surface(
                      onTap: () async {
                        final r = await showPanel<bool>(context, maxWidth: 640, builder: (_) => OrderDetail(id: o['id'] as String));
                        if (r == true) _refresh();
                      },
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        IconSquare(Icons.request_quote_rounded, color: c, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [Flexible(child: Text(o['number'] as String, style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Pill(context.tr(_statuses.firstWhere((s) => s.$1 == o['status']).$2.replaceAll('Quotations', 'Quotation').replaceAll('Cancelled', 'Cancelled')), color: c, dense: true)]),
                            Text('${o['customer_name']}${o['delivery_date'] == null ? '' : ' · ${context.tr('delivery')} ${f.dateShort(DateTime.parse(o['delivery_date'] as String))}'}', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          NumText(f.money(parsePaisa(o['total']), decimals: true), size: 15, weight: 800),
                          if (o['status'] == 'confirmed' || o['status'] == 'ready') Text('${context.tr('balance')} ${f.money(bal)}', style: tt.bodySmall!.copyWith(color: t.warning)) else if (parsePaisa(o['deposit_paid']) > 0 && o['status'] == 'quotation') Text('${context.tr('deposit')} ${f.money(parsePaisa(o['deposit_paid']))}', style: tt.bodySmall),
                        ]),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// -------------------------------------------------------------------------------------------- detail

class OrderDetail extends ConsumerStatefulWidget {
  const OrderDetail({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends ConsumerState<OrderDetail> {
  Map<String, dynamic>? _o;
  Object? _error;
  bool _changed = false, _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _o = await ref.read(apiProvider).getMap('/orders/${widget.id}');
      _error = null;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() {});
  }

  Future<void> _act(Future<Map<String, dynamic>> Function() call, {String? done}) async {
    setState(() => _busy = true);
    try {
      final r = await call();
      _changed = true;
      _o = (r['order'] as Map?)?.cast<String, dynamic>() ?? r;
      if (done != null && mounted) toast(context, done, good: true);
      if (r['sale'] != null && mounted) {
        final sale = (r['sale'] as Map).cast<String, dynamic>();
        await showPanel<void>(context, maxWidth: 420, builder: (c) => PanelScaffold(title: context.tr('Invoice'), subtitle: sale['invoice_no'] as String, padBody: false, child: ReceiptPanel(data: ReceiptData.fromServer(sale, ref.read(ctxProvider)))));
      }
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _quoteText(BuildContext context, TenantContext ctx, Map<String, dynamic> o) {
    final f = const Fmt(AppLang.en);
    final b = StringBuffer()
      ..writeln('${ctx.businessName} — ${o['status'] == 'quotation' ? 'Quotation' : 'Order'} ${o['number']}')
      ..writeln('For: ${o['customer_name']}')
      ..writeln();
    for (final l in (o['lines'] as List).cast<Map<String, dynamic>>()) {
      b.writeln('• ${l['product_name']}${(l['variant_label'] as String).isEmpty ? '' : ' (${l['variant_label']})'} × ${f.qty(parseMilli(l['qty']))} — ${f.money(parsePaisa(l['line_total']), decimals: true)}');
      if ((l['spec_note'] as String).isNotEmpty) b.writeln('   ${l['spec_note']}');
    }
    b
      ..writeln()
      ..writeln('Delivery: ${f.money(parsePaisa(o['delivery_charge']), decimals: true)}')
      ..writeln('TOTAL: ${f.money(parsePaisa(o['total']), decimals: true)}');
    if (o['valid_until'] != null) b.writeln('Valid until ${o['valid_until']}');
    if ((o['terms'] as String).isNotEmpty) b.writeln('\n${o['terms']}');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    if (_error != null) return PanelScaffold(title: context.tr('Order'), child: ErrorView(error: _error!, onRetry: _load));
    final o = _o;
    if (o == null) return PanelScaffold(title: context.tr('Order'), child: const SkeletonList(rows: 4));
    final status = o['status'] as String;
    final c = _statusColor(t, status);
    final balance = parsePaisa(o['balance']);
    final id = o['id'] as String;
    final api = ref.read(apiProvider);
    final steps = ['quotation', 'confirmed', 'ready', 'delivered'];
    final at = steps.indexOf(status);

    final actions = <Widget>[
      if (status == 'quotation') FilledButton.icon(onPressed: _busy ? null : () => _deposit(o, confirming: true), icon: const Icon(Icons.verified_rounded, size: 19), label: Text(context.tr('Take deposit & confirm'))),
      if (status == 'confirmed') ...[
        FilledButton.icon(onPressed: _busy ? null : () => _act(() => api.post('/orders/$id/status', body: {'status': 'ready'}), done: context.tr('Marked ready')), icon: const Icon(Icons.inventory_rounded, size: 19), label: Text(context.tr('Mark ready'))),
        OutlinedButton.icon(onPressed: _busy ? null : () => _deposit(o), icon: const Icon(Icons.add_card_rounded, size: 19), label: Text(context.tr('Add payment'))),
      ],
      if (status == 'ready') ...[
        FilledButton.icon(onPressed: _busy ? null : () => _deliver(o), icon: const Icon(Icons.local_shipping_rounded, size: 19), label: Text(context.tr('Deliver & invoice'))),
        OutlinedButton.icon(onPressed: _busy ? null : () => _deposit(o), icon: const Icon(Icons.add_card_rounded, size: 19), label: Text(context.tr('Add payment'))),
      ],
      if (status == 'confirmed') OutlinedButton.icon(onPressed: _busy ? null : () => _deliver(o), icon: const Icon(Icons.local_shipping_rounded, size: 19), label: Text(context.tr('Deliver & invoice'))),
      if (status == 'quotation') OutlinedButton.icon(onPressed: _busy ? null : () async {
            final r = await showPanel<bool>(context, maxWidth: 780, dismissible: false, builder: (_) => OrderBuilder(existing: o));
            if (r == true) {
              _changed = true;
              await _load();
            }
          }, icon: const Icon(Icons.edit_rounded, size: 19), label: Text(context.tr('Edit quote'))),
      OutlinedButton.icon(onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _quoteText(context, ctx, o)));
            if (context.mounted) toast(context, context.tr('Copied — paste it into WhatsApp or SMS'), good: true);
          }, icon: const Icon(Icons.share_rounded, size: 19), label: Text(context.tr('Copy to share'))),
      if (status != 'delivered' && status != 'cancelled') TextButton.icon(onPressed: _busy ? null : () => _cancel(o), icon: Icon(Icons.cancel_outlined, size: 19, color: t.danger), label: Text(context.tr('Cancel order'), style: TextStyle(color: t.danger))),
    ];

    return PanelScaffold(
      title: o['number'] as String,
      subtitle: '${o['customer_name']} · ${f.dateTime(DateTime.parse(o['created_at'] as String))}',
      leading: IconSquare(Icons.request_quote_rounded, color: c, size: 46),
      actions: [Pill(context.tr(status[0].toUpperCase() + status.substring(1)), color: c)],
      child: WillPopScope2(
        changed: () => _changed,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (at >= 0)
            Row(children: [
              for (final (i, s) in steps.indexed) ...[
                Expanded(child: Column(children: [Container(height: 5, decoration: BoxDecoration(color: i <= at ? c : t.outline, borderRadius: BorderRadius.circular(3))), const SizedBox(height: 6), Text(context.tr(s[0].toUpperCase() + s.substring(1)), style: tt.labelSmall!.copyWith(color: i <= at ? t.text : t.faint))])),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ]),
          const FormGap(18),
          if ((o['delivery_address'] as String).isNotEmpty || o['delivery_date'] != null)
            Surface(
              color: t.surface2,
              border: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (o['delivery_date'] != null) Row(children: [Icon(Icons.event_rounded, size: 18, color: t.muted), const SizedBox(width: 8), Text('${context.tr('Delivery')} ${f.date(DateTime.parse(o['delivery_date'] as String))}', style: tt.titleSmall)]),
                if ((o['delivery_address'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.place_rounded, size: 18, color: t.muted), const SizedBox(width: 8), Expanded(child: Text(o['delivery_address'] as String, style: tt.bodyMedium))])),
              ]),
            ),
          const FormHeading('Items'),
          for (final l in (o['lines'] as List).cast<Map<String, dynamic>>())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Monogram(l['product_name'] as String, size: 38),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${l['product_name']}${(l['variant_label'] as String).isEmpty ? '' : ' · ${l['variant_label']}'}', style: tt.titleSmall),
                  Text('${f.qty(parseMilli(l['qty']))} × ${f.money(parsePaisa(l['unit_price']), decimals: true)}${(l['lead_time_days'] as num) > 0 ? ' · ${f.intN((l['lead_time_days'] as num).toInt())} ${context.tr('days lead time')}' : ''}', style: tt.bodySmall),
                  if ((l['spec_note'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(l['spec_note'] as String, style: tt.bodySmall!.copyWith(color: t.accentDeep, fontStyle: FontStyle.italic))),
                ])),
                NumText(f.money(parsePaisa(l['line_total']), decimals: true), size: 14),
              ]),
            ),
          const Divider(height: 26),
          KV(context.tr('Subtotal'), f.money(parsePaisa(o['subtotal']), decimals: true)),
          if (parsePaisa(o['discount']) > 0) KV(context.tr('Discount'), '−${f.money(parsePaisa(o['discount']), decimals: true)}'),
          if (parsePaisa(o['tax_total']) > 0) KV(context.tr('VAT'), f.money(parsePaisa(o['tax_total']), decimals: true)),
          if (parsePaisa(o['delivery_charge']) > 0) KV(context.tr('Delivery'), f.money(parsePaisa(o['delivery_charge']), decimals: true)),
          KV(context.tr('Total'), f.money(parsePaisa(o['total']), decimals: true), bold: true),
          if ((o['payments'] as List).isNotEmpty) ...[
            const FormHeading('Payments'),
            for (final p in (o['payments'] as List).cast<Map<String, dynamic>>()) KV('${f.dateTime(DateTime.parse(p['paid_at'] as String))} · ${p['method']}${(p['reference'] as String).isEmpty ? '' : ' · ${p['reference']}'}', '${p['kind'] == 'refund' ? '−' : ''}${f.money(parsePaisa(p['amount']), decimals: true)}', color: p['kind'] == 'refund' ? t.danger : t.success),
            KV(context.tr('Balance'), f.money(balance, decimals: true), bold: true, color: balance > 0 ? t.warning : t.success),
          ],
          if (ctx.depositPercentMin > 0 && status == 'quotation') Padding(padding: const EdgeInsets.only(top: 10), child: Text(context.trf('A deposit of at least {pct}% confirms the order.', {'pct': f.intN(ctx.depositPercentMin)}), style: tt.bodySmall)),
          if ((o['terms'] as String).isNotEmpty) ...[const FormHeading('Terms'), Text(o['terms'] as String, style: tt.bodyMedium)],
          const FormGap(20),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ]),
      ),
    );
  }

  Future<void> _deposit(Map<String, dynamic> o, {bool confirming = false}) async {
    final ctx = ref.read(ctxProvider);
    final total = parsePaisa(o['total']);
    final minimum = confirming ? total * ctx.depositPercentMin ~/ 100 : 0;
    final paid = parsePaisa(o['deposit_paid']);
    final suggest = confirming ? (minimum - paid).clamp(0, total) : parsePaisa(o['balance']);
    final r = await showPanel<Map<String, dynamic>>(context, maxWidth: 440, builder: (_) => _TakePayment(title: confirming ? context.tr('Take deposit') : context.tr('Add payment'), subtitle: confirming ? '${context.tr('Minimum')} ${context.fmt.money(minimum)} (${ctx.depositPercentMin}%)' : '${context.tr('Balance')} ${context.fmt.money(parsePaisa(o['balance']))}', suggestP: suggest, maxP: parsePaisa(o['balance'])));
    if (r != null && mounted) await _act(() => ref.read(apiProvider).post('/orders/${o['id']}/deposits', body: r), done: confirming ? context.tr('Order confirmed') : context.tr('Payment recorded'));
  }

  Future<void> _deliver(Map<String, dynamic> o) async {
    final balance = parsePaisa(o['balance']);
    Map<String, dynamic>? pay;
    if (balance > 0) {
      pay = await showPanel<Map<String, dynamic>>(context, maxWidth: 440, builder: (_) => _TakePayment(title: context.tr('Balance on delivery'), subtitle: '${context.tr('Balance')} ${context.fmt.money(balance)}', suggestP: balance, maxP: balance, allowSkip: ref.read(ctxProvider).cap('customer_credit')));
      if (pay == null || !mounted) return;
    }
    await _act(() => ref.read(apiProvider).post('/orders/${o['id']}/deliver', body: {'payments': [if (pay != null && pay['amount'] != '0') pay]}), done: context.tr('Delivered and invoiced'));
  }

  Future<void> _cancel(Map<String, dynamic> o) async {
    final reason = TextEditingController();
    final ok = await showPanel<bool>(
      context,
      maxWidth: 420,
      builder: (c) => PanelScaffold(
        title: context.tr('Cancel this order?'),
        subtitle: parsePaisa(o['deposit_paid']) > 0 ? context.trf('{amount} deposit will be recorded as refunded.', {'amount': context.fmt.money(parsePaisa(o['deposit_paid']))}) : null,
        footer: Row(children: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('Keep order'))), const Spacer(), FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: context.t.danger, foregroundColor: Colors.white), child: Text(context.tr('Cancel order')))]),
        child: TextField(controller: reason, decoration: InputDecoration(labelText: context.tr('Reason'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
      ),
    );
    if (ok == true) await _act(() => ref.read(apiProvider).post('/orders/${o['id']}/cancel', body: {'reason': reason.text.trim()}));
  }
}

/// Pops with `true` if anything changed, however the panel is closed.
class WillPopScope2 extends StatelessWidget {
  const WillPopScope2({super.key, required this.changed, required this.child});
  final bool Function() changed;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(changed());
      }, child: child);
}

class _TakePayment extends ConsumerStatefulWidget {
  const _TakePayment({required this.title, required this.subtitle, required this.suggestP, required this.maxP, this.allowSkip = false});
  final String title, subtitle;
  final int suggestP, maxP;
  final bool allowSkip;

  @override
  ConsumerState<_TakePayment> createState() => _TakePaymentState();
}

class _TakePaymentState extends ConsumerState<_TakePayment> {
  late final _amount = TextEditingController(text: widget.suggestP == 0 ? '' : paisaToWire(widget.suggestP).replaceAll(RegExp(r'\.00$'), ''));
  final _ref = TextEditingController();
  String _method = 'cash';

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final amount = paisaOf(_amount);
    final bad = amount <= 0 || amount > widget.maxP;
    return PanelScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      footer: Row(children: [
        if (widget.allowSkip) TextButton(onPressed: () => Navigator.pop(context, {'amount': '0', 'method': 'cash'}), child: Text(context.tr('Leave on account'))),
        const Spacer(),
        FilledButton(onPressed: bad ? null : () => Navigator.pop(context, {'amount': paisaToWire(amount), 'method': _method, 'reference': _ref.text.trim()}), child: Text('${context.tr('Receive')} ${context.fmt.money(amount, decimals: true)}')),
      ]),
      child: Column(children: [
        MoneyField(controller: _amount, label: context.tr('Amount'), symbol: ctx.currencySymbol, autofocus: true, onChanged: (_) => setState(() {}), helper: amount > widget.maxP ? context.tr('More than the balance') : null),
        const FormGap(),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final m in ctx.enabledPaymentMethods) ChoiceChip(avatar: Icon(m.icon, size: 17, color: m.color), label: Text(m.label), selected: _method == m.code, onSelected: (_) => setState(() => _method = m.code))]),
        if (ctx.enabledPaymentMethods.where((m) => m.code == _method).firstOrNull?.needsReference ?? false) ...[const FormGap(), TextField(controller: _ref, decoration: InputDecoration(labelText: context.tr('Transaction ID / reference'), prefixIcon: const Icon(Icons.tag_rounded, size: 19)))],
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------------ builder

class _OLine {
  _OLine({required this.variantId, required this.name, required this.baseUnitPrice, required this.taxBp}) {
    price.text = paisaToWire(baseUnitPrice).replaceAll(RegExp(r'\.00$'), '');
  }
  final String variantId, name;
  final int baseUnitPrice, taxBp;
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  final discount = TextEditingController();
  final spec = TextEditingController();
  final lead = TextEditingController();
}

class OrderBuilder extends ConsumerStatefulWidget {
  const OrderBuilder({super.key, this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<OrderBuilder> createState() => _OrderBuilderState();
}

class _OrderBuilderState extends ConsumerState<OrderBuilder> {
  Map<String, dynamic>? _customer;
  final _custSearch = TextEditingController();
  List<Map<String, dynamic>> _custResults = [];
  final _address = TextEditingController();
  final _delivery = TextEditingController();
  final _discount = TextEditingController();
  final _terms = TextEditingController();
  final _note = TextEditingController();
  DateTime? _deliveryDate, _validUntil = DateTime.now().add(const Duration(days: 10));
  final List<_OLine> _lines = [];
  final _search = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, int> _rates = {};
  Timer? _debounce;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(catalogueRepoProvider).taxRates().then((r) => mounted ? setState(() => _rates = r) : null);
    final o = widget.existing;
    if (o != null) {
      _customer = {'id': o['customer_id'], 'name': o['customer_name']};
      _address.text = o['delivery_address'] as String;
      _delivery.text = parsePaisa(o['delivery_charge']) == 0 ? '' : paisaToWire(parsePaisa(o['delivery_charge'])).replaceAll(RegExp(r'\.00$'), '');
      _discount.text = parsePaisa(o['discount']) == 0 ? '' : paisaToWire(parsePaisa(o['discount'])).replaceAll(RegExp(r'\.00$'), '');
      _terms.text = o['terms'] as String;
      _note.text = o['note'] as String;
      _deliveryDate = o['delivery_date'] == null ? null : DateTime.parse(o['delivery_date'] as String);
      _validUntil = o['valid_until'] == null ? null : DateTime.parse(o['valid_until'] as String);
      for (final l in (o['lines'] as List).cast<Map<String, dynamic>>()) {
        final line = _OLine(variantId: l['variant_id'] as String, name: '${l['product_name']}${(l['variant_label'] as String).isEmpty ? '' : ' · ${l['variant_label']}'}', baseUnitPrice: parsePaisa(l['unit_price']), taxBp: parseRateBp(l['tax_rate']));
        line.qty.text = milliToWire(parseMilli(l['qty'])).replaceAll(RegExp(r'\.?0+$'), '');
        line.discount.text = parsePaisa(l['discount']) == 0 ? '' : paisaToWire(parsePaisa(l['discount'])).replaceAll(RegExp(r'\.00$'), '');
        line.spec.text = l['spec_note'] as String;
        line.lead.text = (l['lead_time_days'] as num) == 0 ? '' : '${l['lead_time_days']}';
        _lines.add(line);
      }
    } else {
      _terms.text = ref.read(ctxProvider).depositPercentMin > 0 ? '${ref.read(ctxProvider).depositPercentMin}% advance, balance on delivery. Quotation valid for 10 days.' : '';
    }
  }

  Future<void> _findCustomer(String q) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final r = await ref.read(apiProvider).getMap('/customers', query: {'q': q.trim(), 'limit': 6});
        if (mounted) setState(() => _custResults = (r['items'] as List).cast<Map<String, dynamic>>());
      } on ApiError {
        // offline
      }
    });
  }

  Future<void> _find(String q) async {
    _debounce?.cancel();
    if (q.trim().isEmpty) return setState(() => _results = []);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final r = await ref.read(apiProvider).getMap('/products', query: {'q': q.trim(), 'limit': 8});
        if (mounted) setState(() => _results = (r['items'] as List).cast<Map<String, dynamic>>());
      } on ApiError {
        // offline
      }
    });
  }

  void _add(Map<String, dynamic> p, Map<String, dynamic> v) => setState(() {
        _lines.add(_OLine(variantId: v['id'] as String, name: '${p['name']}${(v['label'] as String).isEmpty ? '' : ' · ${v['label']}'}', baseUnitPrice: parsePaisa(v['price']), taxBp: p['tax_class_id'] == null ? 0 : (_rates[p['tax_class_id']] ?? 0)));
        final lead = (p['attributes'] as Map)['lead_time_days'];
        if (lead != null) _lines.last.lead.text = '$lead';
        _search.clear();
        _results = [];
      });

  PricedCart _preview(TenantContext ctx) => priceCart(
        [for (final l in _lines) LineInput(unitPrice: paisaOf(l.price), qtyMilli: l.qty.text.trim().isEmpty ? 0 : parseMilli(l.qty.text.trim()), discount: paisaOf(l.discount), taxRateBp: l.taxBp)],
        billDiscount: paisaOf(_discount),
        taxMode: ctx.taxMode,
      );

  Future<void> _save() async {
    if (_customer == null) return setState(() => _error = context.tr('Choose the customer.'));
    if (_lines.isEmpty) return setState(() => _error = context.tr('Add at least one item.'));
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'customer_id': _customer!['id'],
      'delivery_address': _address.text.trim(),
      if (_deliveryDate != null) 'delivery_date': _deliveryDate!.toIso8601String().substring(0, 10),
      if (_validUntil != null) 'valid_until': _validUntil!.toIso8601String().substring(0, 10),
      'discount': _discount.text.trim().isEmpty ? '0' : _discount.text.trim(),
      'delivery_charge': _delivery.text.trim().isEmpty ? '0' : _delivery.text.trim(),
      'terms': _terms.text.trim(),
      'note': _note.text.trim(),
      'lines': [
        for (final l in _lines)
          {
            'variant_id': l.variantId,
            'qty': l.qty.text.trim(),
            'unit_price': l.price.text.trim(),
            'discount': l.discount.text.trim().isEmpty ? '0' : l.discount.text.trim(),
            'spec_note': l.spec.text.trim(),
            'lead_time_days': int.tryParse(l.lead.text.trim()) ?? 0,
          }
      ],
    };
    try {
      final api = ref.read(apiProvider);
      if (widget.existing == null) {
        await api.post('/orders', body: body);
      } else {
        await api.put('/orders/${widget.existing!['id']}', body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.offline ? context.tr('Quotations are saved online.') : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final priced = _preview(ctx);
    final deliveryP = paisaOf(_delivery);
    final cw = context.term(ctx, 'customer', 'Customer');
    return PanelScaffold(
      title: widget.existing == null ? context.tr('New quotation') : '${context.tr('Edit')} ${widget.existing!['number']}',
      footer: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(context.tr('Quote total'), style: tt.labelSmall), NumText(f.money(priced.total + deliveryP, decimals: true), size: 22, weight: 800)])),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const SizedBox(width: 8),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : Text(context.tr('Save quotation'))),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.error_outline_rounded, size: 19, color: t.danger), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
        if (_customer != null)
          Surface(color: t.accentSoft, border: false, child: Row(children: [Monogram(_customer!['name'] as String, size: 36, round: true), const SizedBox(width: 12), Expanded(child: Text(_customer!['name'] as String, style: tt.titleSmall)), TextButton(onPressed: widget.existing == null ? () => setState(() => _customer = null) : null, child: Text(context.tr('Change')))]))
        else ...[
          AppSearchField(controller: _custSearch, hint: context.trf('Search {word} by name or phone', {'word': cw.toLowerCase()}), onChanged: _findCustomer),
          for (final c in _custResults) Padding(padding: const EdgeInsets.only(top: 6), child: Surface(onTap: () => setState(() {
                _customer = c;
                _address.text = (c['address'] as String?) ?? '';
                _custResults = [];
              }), padding: const EdgeInsets.all(10), child: Row(children: [Monogram(c['name'] as String, size: 32, round: true), const SizedBox(width: 10), Expanded(child: Text(c['name'] as String, style: tt.titleSmall)), Text(f.digits((c['phone'] as String?) ?? ''), style: tt.bodySmall)]))),
          if (_custResults.isEmpty && _custSearch.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(context.tr('No match — add the customer under Customers first.'), style: tt.bodySmall)),
        ],
        const FormGap(),
        TextField(controller: _address, decoration: InputDecoration(labelText: context.tr('Delivery address'), prefixIcon: const Icon(Icons.place_rounded, size: 19))),
        const FormGap(),
        Row(children: [
          Expanded(child: DateField(label: context.tr('Delivery date'), value: _deliveryDate, onChanged: (d) => setState(() => _deliveryDate = d))),
          const SizedBox(width: 12),
          Expanded(child: DateField(label: context.tr('Quote valid until'), value: _validUntil, onChanged: (d) => setState(() => _validUntil = d))),
        ]),
        const FormHeading('Items'),
        AppSearchField(controller: _search, hint: context.tr('Search an item to add'), onChanged: _find),
        for (final p in _results)
          for (final v in (p['variants'] as List).cast<Map<String, dynamic>>().where((v) => v['active'] != false))
            Padding(padding: const EdgeInsets.only(top: 6), child: Surface(onTap: () => _add(p, v), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [Monogram(p['name'] as String, size: 32), const SizedBox(width: 10), Expanded(child: Text((v['label'] as String).isEmpty ? p['name'] as String : '${p['name']} · ${v['label']}', style: tt.titleSmall)), NumText(f.money(parsePaisa(v['price'])), size: 14), const SizedBox(width: 8), const Icon(Icons.add_circle_rounded, size: 22)]))),
        const SizedBox(height: 10),
        for (final (i, l) in _lines.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(
              color: t.surface2,
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(l.name, style: tt.titleSmall)), IconButton(onPressed: () => setState(() => _lines.removeAt(i)), icon: const Icon(Icons.close_rounded, size: 19))]),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  SizedBox(width: 90, child: TextField(controller: l.qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Qty')))),
                  SizedBox(width: 140, child: MoneyField(controller: l.price, label: context.tr('Price'), symbol: ctx.currencySymbol, onChanged: (_) => setState(() {}))),
                  SizedBox(width: 130, child: MoneyField(controller: l.discount, label: context.tr('Discount'), symbol: ctx.currencySymbol, onChanged: (_) => setState(() {}))),
                  if (ctx.cap('custom_orders')) SizedBox(width: 110, child: TextField(controller: l.lead, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Lead days')))),
                ]),
                if (ctx.cap('custom_orders')) ...[const FormGap(10), TextField(controller: l.spec, decoration: InputDecoration(labelText: context.tr('Specification (finish, size, notes)'), prefixIcon: const Icon(Icons.design_services_rounded, size: 19)))],
              ]),
            ),
          ),
        const FormHeading('Totals'),
        Row(children: [
          Expanded(child: MoneyField(controller: _discount, label: context.tr('Discount on the whole quote'), symbol: ctx.currencySymbol, onChanged: (_) => setState(() {}))),
          if (ctx.cap('delivery')) ...[const SizedBox(width: 12), Expanded(child: MoneyField(controller: _delivery, label: context.tr('Delivery charge'), symbol: ctx.currencySymbol, onChanged: (_) => setState(() {})))],
        ]),
        const FormGap(),
        KV(context.tr('Subtotal'), f.money(priced.subtotal, decimals: true)),
        if (priced.taxTotal > 0) KV(ctx.taxMode == TaxMode.inclusive ? context.tr('incl. VAT') : context.tr('VAT'), f.money(priced.taxTotal, decimals: true)),
        const FormGap(),
        TextField(controller: _terms, maxLines: 2, decoration: InputDecoration(labelText: context.tr('Terms'), prefixIcon: const Icon(Icons.gavel_rounded, size: 19))),
        const FormGap(),
        TextField(controller: _note, maxLines: 2, decoration: InputDecoration(labelText: context.tr('Internal note'), prefixIcon: const Icon(Icons.sticky_note_2_rounded, size: 19))),
      ]),
    );
  }
}
