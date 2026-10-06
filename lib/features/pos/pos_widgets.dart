import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/keypad.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/local/database.dart';
import '../../data/models/cart.dart';
import '../../data/providers.dart';
import '../../data/repos/catalogue_repo.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import 'cart_controller.dart';

// ------------------------------------------------------------------------------------ product tile

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.pv, required this.onTap, this.inCartMilli = 0});
  final ProductView pv;
  final VoidCallback onTap;
  final int inCartMilli;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final p = pv.product;
    final out = pv.outOfStock;
    final low = pv.lowStock && !out;
    final price = pv.hasVariants && pv.minPrice != pv.maxPrice ? '${f.money(pv.minPrice, symbol: false)}–${f.money(pv.maxPrice, symbol: false)}' : f.money(pv.minPrice);
    final unit = p.allowFraction ? '/${p.baseUnit}' : '';
    final selected = inCartMilli > 0;
    return Opacity(
      opacity: out ? 0.55 : 1,
      child: Surface(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        color: selected ? t.accentSoft : t.surface,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Monogram(p.name, size: 40, seed: p.categoryId ?? p.id),
            const Spacer(),
            if (selected) Pill('×${f.qty(inCartMilli)}', color: t.accent, filled: true, dense: true, mono: true)
            else if (pv.hasVariants) Pill('${f.intN(pv.variants.length)} ${context.tr('options')}', dense: true),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              context.lang == AppLang.bn && p.nameLocal.isNotEmpty ? p.nameLocal : p.name,
              style: tt.titleSmall!.copyWith(height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: NumText('$price$unit', size: 16, weight: 800))),
            if (pv.stocked) _StockDot(out: out, low: low, label: out ? context.tr('Out') : f.qty(pv.totalAvailable)),
          ]),
        ]),
      ),
    );
  }
}

class _StockDot extends StatelessWidget {
  const _StockDot({required this.out, required this.low, required this.label});
  final bool out, low;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = out ? t.danger : (low ? t.warning : t.faint);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: out || low ? c : t.muted)),
    ]);
  }
}

// ----------------------------------------------------------------------------------- quantity sheet

/// Type a quantity on a keypad (weighed goods, bulk). Returns milli-units, or null if cancelled.
Future<int?> showQtySheet(BuildContext context, {required String title, required String unit, int initialMilli = 0, bool allowFraction = true, int? maxMilli}) {
  return showPanel<int>(context, maxWidth: 400, builder: (ctx) => _QtySheet(title: title, unit: unit, initialMilli: initialMilli, allowFraction: allowFraction, maxMilli: maxMilli));
}

class _QtySheet extends StatefulWidget {
  const _QtySheet({required this.title, required this.unit, required this.initialMilli, required this.allowFraction, this.maxMilli});
  final String title, unit;
  final int initialMilli;
  final bool allowFraction;
  final int? maxMilli;

  @override
  State<_QtySheet> createState() => _QtySheetState();
}

class _QtySheetState extends State<_QtySheet> {
  late String _v = widget.initialMilli > 0 ? milliToWire(widget.initialMilli).replaceAll(RegExp(r'\.?0+$'), '') : '';
  bool _fresh = true;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final milli = _v.isEmpty ? 0 : parseMilli(_v);
    final over = widget.maxMilli != null && milli > widget.maxMilli!;
    return PanelScaffold(
      title: widget.title,
      footer: FilledButton(onPressed: milli > 0 && !over ? () => Navigator.pop(context, milli) : null, child: Text(context.trf('Set {qty} {unit}', {'qty': f.qty(milli), 'unit': widget.unit}))),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: over ? t.danger : t.outline)),
          child: Column(children: [
            NumText(_v.isEmpty ? '0' : f.digits(_v), size: 44, weight: 800, color: over ? t.danger : t.text),
            Text(widget.unit, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: t.muted)),
            if (over) Padding(padding: const EdgeInsets.only(top: 4), child: Text(context.trf('Only {qty} available', {'qty': f.qty(widget.maxMilli!)}), style: TextStyle(color: t.danger, fontWeight: FontWeight.w700, fontSize: 12.5))),
          ]),
        ),
        const SizedBox(height: 14),
        Keypad(
          allowDot: widget.allowFraction,
          onKey: (k) => setState(() {
            if (_fresh && k != 'back' && k != 'clear') _v = '';
            _fresh = false;
            _v = applyKey(_v, k, maxDecimals: 3, maxLen: 9);
          }),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------- variant picker

Future<void> showVariantPicker(BuildContext context, WidgetRef ref, ProductView pv) {
  return showPanel<void>(context, maxWidth: 480, builder: (ctx) => _VariantPicker(pv: pv));
}

class _VariantPicker extends ConsumerWidget {
  const _VariantPicker({required this.pv});
  final ProductView pv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final axes = ref.watch(ctxProvider).variantAxes.map((a) => a['label'] as String).join(' · ');
    return PanelScaffold(
      title: pv.product.name,
      subtitle: axes.isEmpty ? null : '${context.tr('Choose')} $axes',
      leading: Monogram(pv.product.name, size: 44),
      child: Column(children: [
        for (final v in pv.variants)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Opacity(
              opacity: pv.stocked && pv.availableOf(v) <= 0 && !ref.read(ctxProvider).allowNegativeStock ? 0.5 : 1,
              child: Surface(
                onTap: () async {
                  final r = await ref.read(cartProvider.notifier).add(pv, v);
                  if (!context.mounted) return;
                  if (r != null) {
                    toast(context, r.message, error: true);
                  } else {
                    Navigator.pop(context);
                  }
                },
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.label.isEmpty ? v.sku : v.label, style: tt.titleSmall),
                      Text(v.sku, style: tt.bodySmall),
                    ]),
                  ),
                  if (pv.stocked) Padding(padding: const EdgeInsets.only(right: 12), child: Pill(pv.availableOf(v) <= 0 ? context.tr('Out') : '${f.qty(pv.availableOf(v))} ${context.tr('left')}', color: pv.availableOf(v) <= 0 ? t.danger : t.muted, dense: true)),
                  NumText(f.money(v.priceP), size: 16, weight: 800),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------ customer picker

Future<CartCustomer?> showCustomerPicker(BuildContext context) => showPanel<CartCustomer?>(context, maxWidth: 520, builder: (_) => const _CustomerPicker());

class _CustomerPicker extends ConsumerStatefulWidget {
  const _CustomerPicker();

  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  final _q = TextEditingController();
  List<LCustomer> _rows = [];
  Map<String, int> _pending = {};
  bool _creating = false;
  final _name = TextEditingController(), _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final q = _q.text.trim().toLowerCase();
    final rows = await (db.select(db.lCustomers)
          ..where((c) => c.active.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)])
          ..limit(80))
        .get();
    final filtered = q.isEmpty ? rows : rows.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
    final pending = await ref.read(salesRepoProvider).pendingCustomerDeltas();
    if (mounted) {
      setState(() {
        _rows = filtered;
        _pending = pending;
      });
    }
  }

  CartCustomer _toCart(LCustomer c) => CartCustomer(c.id, c.name, balanceP: c.balanceP + (_pending[c.id] ?? 0), creditLimitP: c.creditLimitP, phone: c.phone);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final tt = Theme.of(context).textTheme;
    final ctx = ref.watch(ctxProvider);
    final word = context.term(ctx, 'customer', 'Customer');
    if (_creating) {
      return PanelScaffold(
        title: '${context.tr('New')} $word',
        footer: Row(children: [
          TextButton(onPressed: () => setState(() => _creating = false), child: Text(context.tr('Back'))),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              if (_name.text.trim().isEmpty) return;
              final c = await ref.read(salesRepoProvider).saveCustomer(name: _name.text.trim(), phone: _phone.text.trim());
              if (context.mounted) Navigator.pop(context, _toCart(c));
            },
            child: Text(context.tr('Save & select')),
          ),
        ]),
        child: Column(children: [
          TextField(controller: _name, autofocus: true, decoration: InputDecoration(labelText: context.tr('Name'), prefixIcon: const Icon(Icons.person_rounded, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone'), prefixIcon: const Icon(Icons.phone_rounded, size: 20))),
        ]),
      );
    }
    return PanelScaffold(
      title: word,
      footer: Row(children: [
        OutlinedButton.icon(onPressed: () => Navigator.pop(context, null), icon: const Icon(Icons.person_off_rounded, size: 18), label: Text(context.tr('Walk-in'))),
        const Spacer(),
        FilledButton.icon(onPressed: () => setState(() => _creating = true), icon: const Icon(Icons.person_add_rounded, size: 19), label: Text('${context.tr('New')} $word')),
      ]),
      child: Column(children: [
        AppSearchField(controller: _q, hint: context.tr('Search by name or phone'), onChanged: (_) => _load(), autofocus: true),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('No one matches.'), style: tt.bodyMedium!.copyWith(color: t.muted)))
        else
          for (final c in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(
                onTap: () => Navigator.pop(context, _toCart(c)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Monogram(c.name, size: 40, round: true),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.name, style: tt.titleSmall), if (c.phone.isNotEmpty) Text(f.digits(c.phone), style: tt.bodySmall)])),
                  if (c.balanceP + (_pending[c.id] ?? 0) > 0) Pill('${context.tr('owes')} ${f.money(c.balanceP + (_pending[c.id] ?? 0))}', color: t.warning, dense: true),
                ]),
              ),
            ),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------ line editor

Future<void> showLineEditor(BuildContext context, WidgetRef ref, CartLine line) => showPanel<void>(context, maxWidth: 440, builder: (_) => _LineEditor(lineKey: line.key));

class _LineEditor extends ConsumerStatefulWidget {
  const _LineEditor({required this.lineKey});
  final String lineKey;

  @override
  ConsumerState<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends ConsumerState<_LineEditor> {
  late final _price = TextEditingController();
  late final _disc = TextEditingController();
  late final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final l = ref.read(cartProvider).lines.firstWhere((x) => x.key == widget.lineKey);
    _price.text = paisaToWire(l.unitPriceP).replaceAll(RegExp(r'\.00$'), '');
    _disc.text = l.discountP == 0 ? '' : paisaToWire(l.discountP).replaceAll(RegExp(r'\.00$'), '');
    _note.text = l.note;
  }

  @override
  void dispose() {
    _price.dispose();
    _disc.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final cart = ref.watch(cartProvider);
    final l = cart.lines.where((x) => x.key == widget.lineKey).firstOrNull;
    if (l == null) return const SizedBox.shrink();
    final notifier = ref.read(cartProvider.notifier);
    return PanelScaffold(
      title: l.name,
      subtitle: l.variantLabel.isEmpty ? null : l.variantLabel,
      footer: Row(children: [
        TextButton.icon(
          onPressed: () {
            notifier.remove(l.key);
            Navigator.pop(context);
          },
          icon: Icon(Icons.delete_outline_rounded, color: t.danger, size: 19),
          label: Text(context.tr('Remove'), style: TextStyle(color: t.danger)),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            if (ctx.can('override_price')) {
              final p = parsePaisa(_price.text);
              notifier.setPrice(l.key, p == l.listPriceP ? null : p);
            }
            if (ctx.can('apply_discount')) notifier.setLineDiscount(l.key, _disc.text.trim().isEmpty ? 0 : parsePaisa(_disc.text));
            notifier.setLineNote(l.key, _note.text.trim());
            Navigator.pop(context);
          },
          child: Text(context.tr('Apply')),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (l.altUnits.isNotEmpty) ...[
          Text(context.tr('Sell by'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: Text(l.baseUnit), selected: l.unit == l.baseUnit, onSelected: (_) => notifier.setUnit(l.key, l.baseUnit, 1000)),
            for (final a in l.altUnits) ChoiceChip(label: Text('${a.unit} (${f.qty(a.factorMilli)} ${l.baseUnit})'), selected: l.unit == a.unit, onSelected: (_) => notifier.setUnit(l.key, a.unit, a.factorMilli)),
          ]),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _price,
          enabled: ctx.can('override_price'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '${context.tr('Price per')} ${l.unit}', prefixText: '${ctx.currencySymbol} ', helperText: ctx.can('override_price') ? '${context.tr('List price')} ${f.money(l.listPriceP)}' : context.tr('You need permission to change prices'), prefixIcon: const Icon(Icons.sell_rounded, size: 19)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _disc,
          enabled: ctx.can('apply_discount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.tr('Discount on this line'), prefixText: '${ctx.currencySymbol} ', helperText: ctx.can('apply_discount') ? null : context.tr('You need permission to give discounts'), prefixIcon: const Icon(Icons.percent_rounded, size: 19)),
        ),
        const SizedBox(height: 12),
        TextField(controller: _note, decoration: InputDecoration(labelText: context.tr('Note (optional)'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------ bill discount

Future<void> showDiscountSheet(BuildContext context, WidgetRef ref) => showPanel<void>(context, maxWidth: 400, builder: (_) => const _DiscountSheet());

class _DiscountSheet extends ConsumerStatefulWidget {
  const _DiscountSheet();

  @override
  ConsumerState<_DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends ConsumerState<_DiscountSheet> {
  String _v = '';
  bool _percent = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final priced = ref.watch(pricedCartProvider);
    final sub = priced.subtotal;
    final entered = _v.isEmpty ? 0 : parsePaisa(_v);
    final amount = _percent ? sub * parsePaisa(_v) ~/ 10000 : entered;
    return PanelScaffold(
      title: context.tr('Discount on the bill'),
      subtitle: '${context.tr('Subtotal')} ${f.money(sub)}',
      footer: Row(children: [
        TextButton(
          onPressed: () {
            ref.read(cartProvider.notifier).setBillDiscount(0);
            Navigator.pop(context);
          },
          child: Text(context.tr('Clear')),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            ref.read(cartProvider.notifier).setBillDiscount(amount.clamp(0, sub));
            Navigator.pop(context);
          },
          child: Text('${context.tr('Apply')} ${f.money(amount.clamp(0, sub))}'),
        ),
      ]),
      child: Column(children: [
        SegTabs<bool>(items: [(false, context.tr('Amount')), (true, context.tr('Percent'))], value: _percent, onChanged: (v) => setState(() {
              _percent = v;
              _v = '';
            }), expand: true),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: t.outline)),
          child: Center(child: NumText(_v.isEmpty ? '0' : '${f.digits(_v)}${_percent ? '%' : ''}', size: 38, weight: 800)),
        ),
        const SizedBox(height: 14),
        Keypad(onKey: (k) => setState(() => _v = applyKey(_v, k))),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------- held carts

Future<void> showHeldCarts(BuildContext context, WidgetRef ref) => showPanel<void>(context, maxWidth: 460, builder: (_) => const _HeldPanel());

class _HeldPanel extends ConsumerWidget {
  const _HeldPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(heldCartsProvider).value ?? const [];
    final f = context.fmt;
    return PanelScaffold(
      title: context.tr('Parked sales'),
      subtitle: context.tr('Customers who stepped away — pick one up where you left it.'),
      child: held.isEmpty
          ? EmptyState(icon: Icons.pause_circle_outline_rounded, title: context.tr('Nothing parked'), compact: true)
          : Column(children: [
              for (final h in held)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Surface(
                    onTap: () async {
                      await ref.read(cartProvider.notifier).resume(h.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      const IconSquare(Icons.pause_circle_rounded, size: 38),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(h.name, style: Theme.of(context).textTheme.titleSmall), Text(f.ago(h.createdAt), style: Theme.of(context).textTheme.bodySmall)])),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20), onPressed: () => ref.read(cartProvider.notifier).discardHeld(h.id)),
                    ]),
                  ),
                ),
            ]),
    );
  }
}
