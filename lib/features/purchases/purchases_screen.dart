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
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

final _suppliersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return (await ref.watch(apiProvider).getList('/suppliers')).cast<Map<String, dynamic>>();
});

final _purchasesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.cacheForSession(revalidate: true);
  ref.watch(syncProvider.select((s) => s.revision));
  final r = await ref.watch(apiProvider).getMap('/purchases', query: {'limit': 100});
  return (r['items'] as List).cast<Map<String, dynamic>>();
});

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  String _tab = 'purchases';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final suppliers = ref.watch(_suppliersProvider);
    final purchases = ref.watch(_purchasesProvider);
    final word = context.term(ctx, 'supplier', 'Supplier');
    final names = {for (final s in suppliers.value ?? const <Map<String, dynamic>>[]) s['id'] as String: s['name'] as String};

    return PageBody(
      maxWidth: 960,
      child: Column(children: [
        Row(children: [
          Flexible(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegTabs<String>(items: [('purchases', context.tr('Purchases')), ('suppliers', context.plural(word))], value: _tab, onChanged: (v) => setState(() => _tab = v)))),
          const SizedBox(width: 12),
          if (ctx.can('manage_purchases'))
            FilledButton.icon(
              onPressed: () async {
                final r = _tab == 'purchases' ? await showPanel<bool>(context, maxWidth: 760, dismissible: false, builder: (_) => const _PurchaseForm()) : await showPanel<bool>(context, maxWidth: 460, builder: (_) => const _SupplierForm());
                if (r == true) {
                  ref.invalidate(_suppliersProvider);
                  ref.invalidate(_purchasesProvider);
                  ref.read(syncProvider.notifier).kick();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(_tab == 'purchases' ? context.tr('Receive stock') : '${context.tr('Add')} $word'),
            ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: _tab == 'purchases'
              ? AsyncBody<List<Map<String, dynamic>>>(
                  value: purchases,
                  onRetry: () => ref.invalidate(_purchasesProvider),
                  data: (list) => list.isEmpty
                      ? EmptyState(icon: Icons.local_shipping_outlined, title: context.tr('No deliveries recorded'), message: context.tr('Record goods you receive from a supplier — stock, cost and what you owe update together.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final p = list[i];
                            final due = parsePaisa(p['due']);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Surface(
                                onTap: () => showPanel<void>(context, maxWidth: 560, builder: (_) => _PurchaseDetail(p: p, supplier: names[p['supplier_id']] ?? '')),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  const IconSquare(Icons.local_shipping_rounded, size: 42),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p['number']} · ${names[p['supplier_id']] ?? ''}', style: tt.titleSmall), Text('${f.date(DateTime.parse(p['purchase_date'] as String))} · ${f.intN((p['lines'] as List).length)} ${context.tr('items')}${(p['invoice_no'] as String).isEmpty ? '' : ' · ${p['invoice_no']}'}', style: tt.bodySmall)])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [NumText(f.money(parsePaisa(p['total']), decimals: true), size: 15, weight: 800), if (due > 0) Pill('${context.tr('Owe')} ${f.money(due)}', color: t.warning, dense: true) else Pill(context.tr('Paid'), color: t.success, dense: true)]),
                                ]),
                              ),
                            );
                          },
                        ),
                )
              : AsyncBody<List<Map<String, dynamic>>>(
                  value: suppliers,
                  onRetry: () => ref.invalidate(_suppliersProvider),
                  data: (list) => list.isEmpty
                      ? EmptyState(icon: Icons.storefront_outlined, title: context.trf('No {word} yet', {'word': context.plural(word.toLowerCase())}))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final s = list[i];
                            final bal = parsePaisa(s['balance']);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Surface(
                                onTap: ctx.can('manage_purchases')
                                    ? () async {
                                        final r = await showPanel<bool>(context, maxWidth: 460, builder: (_) => _SupplierForm(existing: s));
                                        if (r == true) ref.invalidate(_suppliersProvider);
                                      }
                                    : null,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  Monogram(s['name'] as String, size: 42),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] as String, style: tt.titleSmall), if ((s['phone'] as String).isNotEmpty) Text(f.digits(s['phone'] as String), style: tt.bodySmall)])),
                                  if (bal > 0) Pill('${context.tr('You owe')} ${f.money(bal)}', color: t.warning),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ]),
    );
  }
}

class _SupplierForm extends ConsumerStatefulWidget {
  const _SupplierForm({this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<_SupplierForm> {
  late final _name = TextEditingController(text: widget.existing?['name'] as String?);
  late final _phone = TextEditingController(text: widget.existing?['phone'] as String?);
  late final _company = TextEditingController(text: widget.existing?['company'] as String?);
  late final _address = TextEditingController(text: widget.existing?['address'] as String?);

  @override
  Widget build(BuildContext context) => PanelScaffold(
        title: widget.existing == null ? context.tr('New supplier') : context.tr('Edit supplier'),
        footer: FilledButton(
          onPressed: () async {
            if (_name.text.trim().isEmpty) return;
            final body = {'name': _name.text.trim(), 'phone': _phone.text.trim(), 'company': _company.text.trim(), 'address': _address.text.trim()};
            try {
              if (widget.existing == null) {
                await ref.read(apiProvider).post('/suppliers', body: body);
              } else {
                await ref.read(apiProvider).patch('/suppliers/${widget.existing!['id']}', body: body);
              }
              if (context.mounted) Navigator.pop(context, true);
            } on ApiError catch (e) {
              if (context.mounted) toast(context, e.message, error: true);
            }
          },
          child: Text(context.tr('Save')),
        ),
        child: Column(children: [
          TextField(controller: _name, autofocus: true, decoration: InputDecoration(labelText: context.tr('Name'), prefixIcon: const Icon(Icons.storefront_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _company, decoration: InputDecoration(labelText: context.tr('Company (optional)'), prefixIcon: const Icon(Icons.business_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone'), prefixIcon: const Icon(Icons.phone_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _address, decoration: InputDecoration(labelText: context.tr('Address'), prefixIcon: const Icon(Icons.home_rounded, size: 19))),
        ]),
      );
}

class _PurchaseDetail extends ConsumerWidget {
  const _PurchaseDetail({required this.p, required this.supplier});
  final Map<String, dynamic> p;
  final String supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final due = parsePaisa(p['due']);
    return PanelScaffold(
      title: p['number'] as String,
      subtitle: '$supplier · ${f.date(DateTime.parse(p['purchase_date'] as String))}',
      footer: due > 0 && ref.watch(ctxProvider).can('manage_purchases')
          ? FilledButton.icon(
              onPressed: () async {
                final r = await showPanel<bool>(context, maxWidth: 420, builder: (_) => _PayPurchase(id: p['id'] as String, due: due));
                if (r == true && context.mounted) {
                  ref.invalidate(_purchasesProvider);
                  ref.invalidate(_suppliersProvider);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.payments_rounded),
              label: Text('${context.tr('Pay supplier')} · ${f.money(due)}'),
            )
          : null,
      child: Column(children: [
        for (final l in (p['lines'] as List).cast<Map<String, dynamic>>())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l['product_name'] as String, style: tt.titleSmall), Text('${f.qty(parseMilli(l['qty']))} × ${f.money(parsePaisa(l['unit_cost']), decimals: true)}${(l['lot_no'] as String).isEmpty ? '' : ' · ${context.tr('batch')} ${l['lot_no']}'}${l['expiry'] == null ? '' : ' · ${context.tr('exp')} ${f.date(DateTime.parse(l['expiry'] as String))}'}', style: tt.bodySmall)])),
              NumText(f.money(parsePaisa(l['line_total']), decimals: true), size: 14),
            ]),
          ),
        const Divider(height: 24),
        KV(context.tr('Total'), f.money(parsePaisa(p['total']), decimals: true), bold: true),
        KV(context.tr('Paid'), f.money(parsePaisa(p['paid']), decimals: true)),
        if (due > 0) KV(context.tr('Still owed'), f.money(due, decimals: true), color: t.warning),
        if ((p['payments'] as List).isNotEmpty) ...[
          const FormHeading('Payments'),
          for (final x in (p['payments'] as List).cast<Map<String, dynamic>>()) KV('${f.date(DateTime.parse(x['paid_at'] as String))} · ${x['method']}', f.money(parsePaisa(x['amount']), decimals: true)),
        ],
      ]),
    );
  }
}

class _PayPurchase extends ConsumerStatefulWidget {
  const _PayPurchase({required this.id, required this.due});
  final String id;
  final int due;

  @override
  ConsumerState<_PayPurchase> createState() => _PayPurchaseState();
}

class _PayPurchaseState extends ConsumerState<_PayPurchase> {
  late final _amount = TextEditingController(text: paisaToWire(widget.due).replaceAll(RegExp(r'\.00$'), ''));
  String _method = 'cash';

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    return PanelScaffold(
      title: context.tr('Pay supplier'),
      footer: FilledButton(
        onPressed: () async {
          try {
            await ref.read(apiProvider).post('/purchases/${widget.id}/payments', body: {'amount': _amount.text.trim(), 'method': _method});
            if (context.mounted) Navigator.pop(context, true);
          } on ApiError catch (e) {
            if (context.mounted) toast(context, e.message, error: true);
          }
        },
        child: Text(context.tr('Record payment')),
      ),
      child: Column(children: [
        MoneyField(controller: _amount, label: context.tr('Amount'), symbol: ctx.currencySymbol, autofocus: true, helper: '${context.tr('Still owed')} ${context.fmt.money(widget.due)}'),
        const FormGap(),
        Wrap(spacing: 8, children: [for (final m in ctx.enabledPaymentMethods.take(5)) ChoiceChip(avatar: Icon(m.icon, size: 17, color: m.color), label: Text(m.label), selected: _method == m.code, onSelected: (_) => setState(() => _method = m.code))]),
      ]),
    );
  }
}

// ----------------------------------------------------------------------------------- new purchase

class _Line {
  _Line({required this.variantId, required this.name, required this.lot, required this.expiryRequired, String cost = ''}) {
    this.cost.text = cost;
  }
  final String variantId, name;
  final bool lot, expiryRequired;
  final qty = TextEditingController(text: '1');
  final cost = TextEditingController();
  final lotNo = TextEditingController();
  DateTime? expiry;
}

class _PurchaseForm extends ConsumerStatefulWidget {
  const _PurchaseForm();

  @override
  ConsumerState<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<_PurchaseForm> {
  String? _supplier;
  final _invoice = TextEditingController();
  final _paid = TextEditingController();
  String _method = 'cash';
  final List<_Line> _lines = [];
  final _search = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Timer? _debounce;
  bool _busy = false;
  String? _error;

  int get _total => _lines.fold(0, (a, l) => a + (parseMilli(l.qty.text.isEmpty ? '0' : l.qty.text) * parsePaisa(l.cost.text.isEmpty ? '0' : l.cost.text) ~/ 1000));

  Future<void> _find(String q) async {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final r = await ref.read(apiProvider).getMap('/products', query: {'q': q.trim(), 'limit': 8});
        if (mounted) setState(() => _results = (r['items'] as List).cast<Map<String, dynamic>>().where((p) => p['type'] == 'stockable').toList());
      } on ApiError {
        // offline: leave the list as is
      }
    });
  }

  void _add(Map<String, dynamic> p, Map<String, dynamic> v) {
    if (_lines.any((l) => l.variantId == v['id'])) return;
    setState(() {
      _lines.add(_Line(
        variantId: v['id'] as String,
        name: (v['label'] as String).isEmpty ? p['name'] as String : '${p['name']} · ${v['label']}',
        lot: p['tracking'] == 'lot',
        expiryRequired: p['tracking'] == 'lot' && p['track_expiry'] == true,
        cost: v['cost'] == null || parsePaisa(v['cost']) == 0 ? '' : paisaToWire(parsePaisa(v['cost'])).replaceAll(RegExp(r'\.00$'), ''),
      ));
      _search.clear();
      _results = [];
    });
  }

  Future<void> _submit() async {
    if (_supplier == null) return setState(() => _error = context.tr('Choose a supplier.'));
    if (_lines.isEmpty) return setState(() => _error = context.tr('Add at least one item.'));
    for (final l in _lines) {
      if (l.expiryRequired && l.expiry == null) return setState(() => _error = '${l.name}: ${context.tr('enter an expiry date.')}');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).post('/purchases', body: {
        'supplier_id': _supplier,
        'invoice_no': _invoice.text.trim(),
        'paid': _paid.text.trim().isEmpty ? '0' : _paid.text.trim(),
        'pay_method': _method,
        'lines': [
          for (final l in _lines)
            {
              'variant_id': l.variantId,
              'qty': l.qty.text.trim(),
              'unit_cost': l.cost.text.trim().isEmpty ? '0' : l.cost.text.trim(),
              if (l.lot) 'lot_no': l.lotNo.text.trim(),
              if (l.expiry != null) 'expiry': l.expiry!.toIso8601String().substring(0, 10),
            }
        ],
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.offline ? context.tr('Receiving stock needs a connection.') : e.message);
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
    final suppliers = ref.watch(_suppliersProvider).value ?? const [];
    return PanelScaffold(
      title: context.tr('Receive stock'),
      subtitle: context.tr('Stock, cost and what you owe the supplier update together.'),
      footer: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(context.tr('Total'), style: tt.labelSmall), NumText(f.money(_total, decimals: true), size: 22, weight: 800)])),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const SizedBox(width: 8),
        FilledButton(onPressed: _busy ? null : _submit, child: _busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : Text(context.tr('Save delivery'))),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.error_outline_rounded, size: 19, color: t.danger), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
        Row(children: [
          Expanded(flex: 3, child: DropdownBox<String>(label: context.term(ctx, 'supplier', 'Supplier'), value: _supplier, icon: Icons.storefront_rounded, items: [for (final s in suppliers) DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String))], onChanged: (v) => setState(() => _supplier = v))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: TextField(controller: _invoice, decoration: InputDecoration(labelText: context.tr('Supplier invoice no.')))),
        ]),
        const FormHeading('Items received'),
        AppSearchField(controller: _search, scannable: true, hint: context.tr('Search an item to add'), onChanged: _find),
        for (final p in _results)
          for (final v in (p['variants'] as List).cast<Map<String, dynamic>>().where((v) => v['active'] != false))
            Padding(padding: const EdgeInsets.only(top: 6), child: Surface(onTap: () => _add(p, v), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [Monogram(p['name'] as String, size: 32), const SizedBox(width: 10), Expanded(child: Text((v['label'] as String).isEmpty ? p['name'] as String : '${p['name']} · ${v['label']}', style: tt.titleSmall)), const Icon(Icons.add_circle_rounded, size: 22)]))),
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
                  SizedBox(width: 110, child: TextField(controller: l.qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Quantity')))),
                  SizedBox(width: 140, child: MoneyField(controller: l.cost, label: context.tr('Unit cost'), symbol: ctx.currencySymbol, onChanged: (_) => setState(() {}), decimals: 4)),
                  if (l.lot) SizedBox(width: 140, child: TextField(controller: l.lotNo, decoration: InputDecoration(labelText: context.tr('Batch no.')))),
                  if (l.expiryRequired) SizedBox(width: 190, child: DateField(label: context.tr('Expiry date'), value: l.expiry, first: DateTime.now().subtract(const Duration(days: 30)), onChanged: (d) => setState(() => l.expiry = d))),
                ]),
              ]),
            ),
          ),
        const FormHeading('Payment'),
        Row(children: [
          Expanded(child: MoneyField(controller: _paid, label: context.tr('Paid now (optional)'), symbol: ctx.currencySymbol, helper: _total > 0 && _paid.text.isNotEmpty ? '${context.tr('Remaining')} ${f.money((_total - paisaOf(_paid)).clamp(0, 1 << 40))} ${context.tr('goes on account')}' : null, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 12),
          Expanded(child: DropdownBox<String>(label: context.tr('Paid with'), value: _method, items: [for (final m in ctx.enabledPaymentMethods) DropdownMenuItem(value: m.code, child: Text(m.label))], onChanged: (v) => setState(() => _method = v ?? 'cash'))),
        ]),
      ]),
    );
  }
}
