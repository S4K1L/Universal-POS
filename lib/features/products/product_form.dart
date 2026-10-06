import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/local/database.dart';
import '../../data/models/context.dart';
import '../../data/providers.dart';
import '../../data/session.dart';

/// Add or edit a product. **The form is not hard-coded**: which fields appear comes from the business type's
/// attribute definitions and from the capabilities it has switched on — a supershop sees weight and expiry, a
/// cosmetic shop sees shades and skin type, a furniture showroom sees material, dimensions and finishes.
Future<bool?> showProductForm(BuildContext context, WidgetRef ref, {Map<String, dynamic>? existing}) =>
    showPanel<bool>(context, maxWidth: 760, dismissible: false, builder: (_) => ProductForm(existing: existing));

class _VariantDraft {
  _VariantDraft({this.id, Map<String, String>? options}) : options = options ?? {};
  String? id;
  final Map<String, String> options;
  final sku = TextEditingController();
  final price = TextEditingController();
  final mrp = TextEditingController();
  final cost = TextEditingController();
  final barcode = TextEditingController();
  final plu = TextEditingController();
  final openQty = TextEditingController();
  final lot = TextEditingController();
  DateTime? expiry;
  bool active = true;

  void dispose() {
    for (final c in [sku, price, mrp, cost, barcode, plu, openQty, lot]) {
      c.dispose();
    }
  }
}

class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({super.key, this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _name = TextEditingController();
  final _nameLocal = TextEditingController();
  final _reorder = TextEditingController();
  final _warranty = TextEditingController();
  final _description = TextEditingController();
  String? _categoryId, _taxClassId;
  String _type = 'stockable';
  String _baseUnit = 'pc';
  bool _fraction = false, _lot = false, _expiry = false, _active = true;
  final List<({TextEditingController unit, TextEditingController factor})> _alt = [];
  final Map<String, dynamic> _attr = {};
  final List<_VariantDraft> _variants = [];
  bool _busy = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ctx = ref.read(ctxProvider);
    final p = widget.existing;
    if (p != null) {
      _name.text = p['name'] as String;
      _nameLocal.text = (p['name_local'] as String?) ?? '';
      _description.text = (p['description'] as String?) ?? '';
      _categoryId = p['category_id'] as String?;
      _taxClassId = p['tax_class_id'] as String?;
      _type = p['type'] as String;
      _baseUnit = p['base_unit'] as String;
      _fraction = p['allow_fraction'] == true;
      _lot = p['tracking'] == 'lot';
      _expiry = p['track_expiry'] == true;
      _active = p['active'] != false;
      _reorder.text = _clean(p['reorder_level']);
      _warranty.text = (p['warranty_months'] as num?) == 0 ? '' : '${p['warranty_months']}';
      for (final a in (p['alt_units'] as List).cast<Map<String, dynamic>>()) {
        _alt.add((unit: TextEditingController(text: a['unit'] as String), factor: TextEditingController(text: _clean(a['factor']))));
      }
      _attr.addAll((p['attributes'] as Map).cast<String, dynamic>());
      for (final v in (p['variants'] as List).cast<Map<String, dynamic>>()) {
        final d = _VariantDraft(id: v['id'] as String, options: ((v['option_values'] as Map?) ?? {}).map((k, val) => MapEntry(k as String, val.toString())));
        d.sku.text = v['sku'] as String;
        d.price.text = _money(v['price']);
        d.mrp.text = parsePaisa(v['mrp']) == 0 ? '' : _money(v['mrp']);
        d.cost.text = v['cost'] == null ? '' : _money(v['cost']);
        d.plu.text = (v['plu'] as String?) ?? '';
        d.barcode.text = ((v['barcodes'] as List).isEmpty) ? '' : ((v['barcodes'] as List).first as Map)['code'] as String;
        d.active = v['active'] != false;
        _variants.add(d);
      }
    } else {
      _baseUnit = ctx.units.isNotEmpty ? ctx.units.first.code : 'pc';
      _reorder.text = '${((ctx.raw['settings'] as Map)['stock'] as Map?)?['reorder_default'] ?? ''}';
      _variants.add(_VariantDraft());
    }
  }

  String _clean(Object? v) => milliToWire(parseMilli(v)).replaceAll(RegExp(r'\.?0+$'), '');
  String _money(Object? v) => paisaToWire(parsePaisa(v)).replaceAll(RegExp(r'\.00$'), '');

  @override
  void dispose() {
    for (final c in [_name, _nameLocal, _reorder, _warranty, _description]) {
      c.dispose();
    }
    for (final a in _alt) {
      a.unit.dispose();
      a.factor.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _body(TenantContext ctx) {
    final usesVariants = ctx.cap('variants');
    return {
      'name': _name.text.trim(),
      'name_local': _nameLocal.text.trim(),
      'description': _description.text.trim(),
      if (_categoryId != null) 'category_id': _categoryId,
      if (_editing && _categoryId == null) 'clear_category': true,
      if (!_editing) 'type': _type,
      'base_unit': _baseUnit,
      'alt_units': ctx.cap('multi_uom') ? [for (final a in _alt) if (a.unit.text.trim().isNotEmpty && a.factor.text.trim().isNotEmpty) {'unit': a.unit.text.trim(), 'factor': a.factor.text.trim()}] : [],
      'allow_fraction': ctx.cap('fractional_qty') && _fraction,
      'tracking': ctx.cap('lot_tracking') && _lot && _type == 'stockable' ? 'lot' : 'none',
      'track_expiry': ctx.cap('expiry_tracking') && _lot && _expiry && _type == 'stockable',
      if (_taxClassId != null && ctx.cap('item_tax')) 'tax_class_id': _taxClassId,
      if (_editing && (_taxClassId == null || !ctx.cap('item_tax'))) 'clear_tax_class': true,
      'attributes': _attr,
      'reorder_level': _reorder.text.trim().isEmpty ? '0' : _reorder.text.trim(),
      'warranty_months': ctx.cap('warranty') ? int.tryParse(_warranty.text.trim()) ?? 0 : 0,
      if (_editing) 'active': _active,
      'variants': [
        for (final v in _variants)
          {
            if (v.id != null) 'id': v.id,
            if (v.sku.text.trim().isNotEmpty) 'sku': v.sku.text.trim(),
            'option_values': usesVariants ? {for (final e in v.options.entries) if (e.value.trim().isNotEmpty) e.key: e.value.trim()} : {},
            'price': v.price.text.trim().isEmpty ? '0' : v.price.text.trim(),
            'mrp': v.mrp.text.trim().isEmpty ? '0' : v.mrp.text.trim(),
            'cost': v.cost.text.trim().isEmpty ? '0' : v.cost.text.trim(),
            if (ctx.cap('scale_barcode') && v.plu.text.trim().isNotEmpty) 'plu': v.plu.text.trim(),
            'active': v.active,
            'barcodes': [if (v.barcode.text.trim().isNotEmpty) {'code': v.barcode.text.trim()}],
            if (v.id == null && _type == 'stockable' && v.openQty.text.trim().isNotEmpty && parseMilli(v.openQty.text) > 0)
              'opening_stock': {
                'qty': v.openQty.text.trim(),
                if (v.cost.text.trim().isNotEmpty) 'unit_cost': v.cost.text.trim(),
                if (_lot) 'lot_no': v.lot.text.trim().isEmpty ? 'OPENING' : v.lot.text.trim(),
                if (_lot && _expiry && v.expiry != null) 'expiry': v.expiry!.toIso8601String().substring(0, 10),
              },
          },
      ],
    };
  }

  Future<void> _save() async {
    final ctx = ref.read(ctxProvider);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = context.tr('Give it a name.'));
      return;
    }
    for (final v in _variants) {
      if (v.price.text.trim().isEmpty) {
        setState(() => _error = context.tr('Every option needs a price.'));
        return;
      }
    }
    for (final a in ctx.attributes) {
      if (a.required && (_attr[a.key] == null || _attr[a.key].toString().trim().isEmpty || (_attr[a.key] is List && (_attr[a.key] as List).isEmpty))) {
        setState(() => _error = '${a.label} ${context.tr('is required.')}');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final body = _body(ctx);
      if (_editing) {
        await api.patch('/products/${widget.existing!['id']}', body: body);
      } else {
        await api.post('/products', body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.offline ? context.tr('Products can only be saved while online.') : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, title: context.tr('Remove this product?'), message: context.tr('If it has sales it is hidden instead of deleted, so your history stays intact.'), confirm: context.tr('Remove'), danger: true);
    if (!ok) return;
    try {
      await ref.read(apiProvider).delete('/products/${widget.existing!['id']}');
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final ctx = ref.watch(ctxProvider);
    final word = context.term(ctx, 'product', 'Product');
    final cats = ref.watch(_formCategories).value ?? const <LCategory>[];
    final taxes = ref.watch(_formTaxes).value ?? const <LTaxClassesData>[];
    final canCost = ctx.can('view_cost') || !_editing;
    final grouped = <String, List<AttributeDef>>{};
    for (final a in ctx.attributes) {
      grouped.putIfAbsent(a.group, () => []).add(a);
    }
    final units = ctx.units;
    final usesVariants = ctx.cap('variants');
    final axes = ctx.variantAxes;

    return PanelScaffold(
      title: _editing ? '${context.tr('Edit')} $word' : '${context.tr('New')} $word',
      subtitle: '${ctx.typeLabel} · ${context.tr('fields adapt to your business')}',
      footer: Row(children: [
        if (_editing) TextButton.icon(onPressed: _busy ? null : _delete, icon: Icon(Icons.delete_outline_rounded, size: 19, color: t.danger), label: Text(context.tr('Remove'), style: TextStyle(color: t.danger))),
        const Spacer(),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const SizedBox(width: 8),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : Text(context.tr('Save'))),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: t.danger.withValues(alpha: 0.3))), child: Row(children: [Icon(Icons.error_outline_rounded, size: 19, color: t.danger), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
        TextField(controller: _name, autofocus: !_editing, decoration: InputDecoration(labelText: '$word ${context.tr('name')}', prefixIcon: const Icon(Icons.label_rounded, size: 19))),
        const FormGap(),
        TextField(controller: _nameLocal, decoration: InputDecoration(labelText: context.tr('Name in Bangla (optional)'), prefixIcon: const Icon(Icons.translate_rounded, size: 19))),
        const FormGap(),
        LayoutBuilder(builder: (c, box) {
          final two = box.maxWidth > 520;
          final catField = DropdownBox<String?>(label: context.tr('Category'), value: _categoryId, icon: Icons.folder_rounded, items: [DropdownMenuItem(value: null, child: Text(context.tr('None'))), for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))], onChanged: (v) => setState(() => _categoryId = v));
          final unitField = DropdownBox<String>(
            label: context.tr('Sold by'),
            value: units.any((u) => u.code == _baseUnit) ? _baseUnit : null,
            icon: Icons.straighten_rounded,
            items: [for (final u in units) DropdownMenuItem(value: u.code, child: Text(context.lang == AppLang.bn && u.labelBn.isNotEmpty ? u.labelBn : u.label))],
            onChanged: (v) => setState(() {
              _baseUnit = v ?? _baseUnit;
              if (ctx.cap('fractional_qty') && (units.where((u) => u.code == _baseUnit).firstOrNull?.allowFraction ?? false)) _fraction = true;
            }),
          );
          return two ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: catField), const SizedBox(width: 12), Expanded(child: unitField)]) : Column(children: [catField, const FormGap(), unitField]);
        }),
        if (!_editing) ...[
          const FormGap(),
          SegTabs<String>(items: [('stockable', context.tr('Stocked item')), ('non_stock', context.tr('No stock')), ('service', context.tr('Service'))], value: _type, onChanged: (v) => setState(() => _type = v), expand: true),
        ],
        // ---- capability-driven options
        if (ctx.cap('fractional_qty') || ctx.cap('multi_uom') || (ctx.cap('lot_tracking') && _type == 'stockable') || ctx.cap('item_tax') || ctx.cap('warranty')) FormHeading(context.tr('Selling & stock'), hint: context.tr('Only the options your business type uses are shown.')),
        if (ctx.cap('fractional_qty')) SwitchRow(title: context.tr('Sold by weight or length'), subtitle: context.tr('Allow decimals like 1.25 kg'), value: _fraction, onChanged: (v) => setState(() => _fraction = v)),
        if (ctx.cap('multi_uom')) ...[
          Text(context.tr('Other units (dozen, carton, strip…)'), style: tt.titleSmall),
          const SizedBox(height: 8),
          for (final (i, a) in _alt.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: TextField(controller: a.unit, decoration: InputDecoration(labelText: context.tr('Unit name'), hintText: 'dozen'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: a.factor, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${context.tr('How many')} $_baseUnit', hintText: '12'))),
                IconButton(onPressed: () => setState(() => _alt.removeAt(i)), icon: const Icon(Icons.remove_circle_outline_rounded)),
              ]),
            ),
          TextButton.icon(onPressed: () => setState(() => _alt.add((unit: TextEditingController(), factor: TextEditingController()))), icon: const Icon(Icons.add_rounded, size: 19), label: Text(context.tr('Add a unit'))),
          const FormGap(6),
        ],
        if (ctx.cap('lot_tracking') && _type == 'stockable') SwitchRow(title: context.tr('Track batches'), subtitle: context.tr('Record a batch number each time stock arrives'), value: _lot, onChanged: (v) => setState(() {
              _lot = v;
              if (!v) _expiry = false;
            })),
        if (ctx.cap('expiry_tracking') && _lot && _type == 'stockable') SwitchRow(title: context.tr('Has an expiry date'), subtitle: context.tr('Sells the soonest-to-expire batch first and warns before it goes off'), value: _expiry, onChanged: (v) => setState(() => _expiry = v)),
        if (ctx.cap('item_tax') && taxes.isNotEmpty) DropdownBox<String?>(label: context.tr('VAT'), value: _taxClassId, icon: Icons.receipt_rounded, items: [DropdownMenuItem(value: null, child: Text(context.tr('No VAT'))), for (final x in taxes) DropdownMenuItem(value: x.id, child: Text('${x.name} (${context.fmt.percentBp(x.rateBp)})'))], onChanged: (v) => setState(() => _taxClassId = v)),
        if (_type == 'stockable') ...[
          const FormGap(),
          Row(children: [
            Expanded(child: TextField(controller: _reorder, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Reorder level'), helperText: context.tr('Warn when stock falls to this'), prefixIcon: const Icon(Icons.notification_important_rounded, size: 19)))),
            if (ctx.cap('warranty')) ...[const SizedBox(width: 12), Expanded(child: TextField(controller: _warranty, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Warranty (months)'), prefixIcon: const Icon(Icons.verified_user_rounded, size: 19))))],
          ]),
        ],
        // ---- the business type's own fields
        for (final g in grouped.entries) ...[
          FormHeading(context.lang == AppLang.bn && g.key == 'Details' ? 'বিবরণ' : g.key),
          for (final a in g.value) Padding(padding: const EdgeInsets.only(bottom: 12), child: _AttrField(def: a, value: _attr[a.key], onChanged: (v) => setState(() => v == null || v == '' || (v is List && v.isEmpty) ? _attr.remove(a.key) : _attr[a.key] = v))),
        ],
        // ---- pricing / variants
        FormHeading(usesVariants ? context.tr('Options & pricing') : context.tr('Pricing'), hint: usesVariants ? context.trf('Each combination of {axes} has its own price, barcode and stock.', {'axes': axes.map((a) => (context.lang == AppLang.bn && (a['label_bn'] ?? '') != '' ? a['label_bn'] : a['label']).toString().toLowerCase()).join(' / ')}) : null),
        for (final (i, v) in _variants.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              color: t.surface2,
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (usesVariants)
                  Row(children: [
                    Expanded(
                      child: Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final a in axes)
                          SizedBox(
                            width: 170,
                            child: TextFormField(
                              initialValue: v.options[a['key'] as String] ?? '',
                              onChanged: (s) => v.options[a['key'] as String] = s,
                              decoration: InputDecoration(labelText: context.lang == AppLang.bn && (a['label_bn'] ?? '') != '' ? a['label_bn'] as String : a['label'] as String),
                            ),
                          ),
                      ]),
                    ),
                    if (_variants.length > 1) IconButton(onPressed: () => setState(() {
                          if (v.id == null) {
                            _variants.removeAt(i);
                          } else {
                            v.active = false;
                          }
                        }), icon: const Icon(Icons.delete_outline_rounded)),
                  ]),
                if (usesVariants) const FormGap(),
                if (v.active) ...[
                  Wrap(spacing: 10, runSpacing: 12, children: [
                    SizedBox(width: 150, child: MoneyField(controller: v.price, label: context.tr('Selling price'), symbol: ctx.currencySymbol)),
                    SizedBox(width: 150, child: MoneyField(controller: v.mrp, label: context.tr('MRP (optional)'), symbol: ctx.currencySymbol)),
                    if (canCost) SizedBox(width: 150, child: MoneyField(controller: v.cost, label: context.tr('Cost price'), symbol: ctx.currencySymbol)),
                    SizedBox(width: 190, child: TextField(controller: v.barcode, decoration: InputDecoration(labelText: context.tr('Barcode'), prefixIcon: const Icon(Icons.qr_code_rounded, size: 19)))),
                    SizedBox(width: 150, child: TextField(controller: v.sku, decoration: InputDecoration(labelText: context.tr('SKU'), hintText: context.tr('auto')))),
                    if (ctx.cap('scale_barcode') && _fraction) SizedBox(width: 150, child: TextField(controller: v.plu, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Scale code (PLU)')))),
                  ]),
                  if (v.id == null && _type == 'stockable') ...[
                    const FormGap(),
                    Text(context.tr('Opening stock (optional)'), style: tt.labelMedium!.copyWith(color: t.muted)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 10, runSpacing: 12, children: [
                      SizedBox(width: 150, child: TextField(controller: v.openQty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '${context.tr('Quantity')} ($_baseUnit)'))),
                      if (_lot) SizedBox(width: 150, child: TextField(controller: v.lot, decoration: InputDecoration(labelText: context.tr('Batch no.')))),
                      if (_lot && _expiry) SizedBox(width: 190, child: DateField(label: context.tr('Expiry date'), value: v.expiry, onChanged: (d) => setState(() => v.expiry = d), first: DateTime.now().subtract(const Duration(days: 30)))),
                    ]),
                  ],
                ] else
                  Row(children: [Text(context.tr('This option will be hidden'), style: tt.bodySmall), TextButton(onPressed: () => setState(() => v.active = true), child: Text(context.tr('Undo')))]),
              ]),
            ),
          ),
        if (usesVariants) OutlinedButton.icon(onPressed: () => setState(() => _variants.add(_VariantDraft())), icon: const Icon(Icons.add_rounded, size: 19), label: Text(context.tr('Add another option'))),
        if (_editing) ...[
          const FormGap(),
          SwitchRow(title: context.tr('Available for sale'), subtitle: context.tr('Turn off to hide it from the till without deleting it'), value: _active, onChanged: (v) => setState(() => _active = v)),
        ],
      ]),
    );
  }
}

final _formCategories = StreamProvider.autoDispose<List<LCategory>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.lCategories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)])).watch();
});

final _formTaxes = StreamProvider.autoDispose<List<LTaxClassesData>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.lTaxClasses)..orderBy([(c) => OrderingTerm.asc(c.rateBp)])).watch();
});

/// One field of the business type's product definition, rendered by its declared type.
class _AttrField extends StatelessWidget {
  const _AttrField({required this.def, required this.value, required this.onChanged});
  final AttributeDef def;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = '${context.lang == AppLang.bn && def.labelBn.isNotEmpty ? def.labelBn : def.label}${def.required ? ' *' : ''}${def.unit != null ? ' (${def.unit})' : ''}';
    switch (def.type) {
      case 'bool':
        return SwitchRow(title: label, value: value == true, onChanged: onChanged);
      case 'select':
        return DropdownBox<String?>(label: label, value: def.options.contains(value) ? value as String : null, items: [const DropdownMenuItem(value: null, child: Text('—')), for (final o in def.options) DropdownMenuItem(value: o, child: Text(o))], onChanged: onChanged);
      case 'multiselect':
        final sel = (value as List?)?.cast<String>() ?? const <String>[];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: context.t.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final o in def.options) FilterChip(label: Text(o), selected: sel.contains(o), onSelected: (on) => onChanged(on ? [...sel, o] : sel.where((x) => x != o).toList()))]),
        ]);
      case 'date':
        return DateField(label: label, value: value == null ? null : DateTime.tryParse('$value'), onChanged: (d) => onChanged(d?.toIso8601String().substring(0, 10)));
      case 'int':
      case 'decimal':
      case 'money':
        return TextFormField(initialValue: value?.toString() ?? '', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (s) => onChanged(s.trim().isEmpty ? null : s.trim()), decoration: InputDecoration(labelText: label));
      case 'textarea':
        return TextFormField(initialValue: value?.toString() ?? '', maxLines: 3, onChanged: onChanged, decoration: InputDecoration(labelText: label));
      default:
        return TextFormField(initialValue: value?.toString() ?? '', onChanged: onChanged, decoration: InputDecoration(labelText: label));
    }
  }
}
