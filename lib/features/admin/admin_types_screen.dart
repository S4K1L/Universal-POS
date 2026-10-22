import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/session.dart';
import 'admin_businesses_screen.dart' show accentOf, typeIcon;

final _typesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return ref.watch(apiProvider).getMap('/admin/business-types');
});

/// Business types are data: capabilities, extra product fields, defaults. Edit one here and shops adopt it with
/// "Update" — no code change, no app release.
class AdminTypesScreen extends ConsumerWidget {
  const AdminTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(_typesProvider);
    return PageBody(
      maxWidth: 1000,
      child: AsyncBody<Map<String, dynamic>>(
        value: data,
        onRetry: () => ref.invalidate(_typesProvider),
        data: (d) {
          final types = (d['business_types'] as List).cast<Map<String, dynamic>>();
          return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('Business types'), style: tt.titleLarge), Text(context.tr('What each kind of shop gets: fields, screens and behaviour.'), style: tt.bodySmall)])),
              FilledButton.icon(
                onPressed: () async {
                  final r = await showPanel<bool>(context, maxWidth: 780, dismissible: false, builder: (_) => _TypeEditor(catalog: d, types: types));
                  if (r == true) ref.invalidate(_typesProvider);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(context.tr('New type')),
              ),
            ]),
            const SizedBox(height: 14),
            for (final ty in types)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Surface(
                  onTap: () async {
                    final r = await showPanel<bool>(context, maxWidth: 780, dismissible: false, builder: (_) => _TypeEditor(catalog: d, types: types, existing: ty));
                    if (r == true) ref.invalidate(_typesProvider);
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: accentOf(((ty['definition'] as Map)['theme'] as Map?)?.cast()), borderRadius: BorderRadius.circular(15)), child: Icon(typeIcon((((ty['definition'] as Map)['theme'] as Map?)?['icon']) as String?), color: Colors.white)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Flexible(child: Text(ty['label'] as String, style: tt.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Pill('v${ty['version']}', dense: true, mono: true), const SizedBox(width: 6), if (ty['active'] != true) Pill(context.tr('Hidden'), color: t.faint, dense: true)]),
                      Text(ty['description'] as String, style: tt.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: [for (final c in (((ty['definition'] as Map)['capabilities']) as List).cast<String>()) Pill(((d['capabilities'] as Map)[c] as Map?)?['label'] as String? ?? c, dense: true, color: t.accentDeep)]),
                    ])),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      NumText(f.intN(ty['tenant_count'] as int), size: 22, weight: 800),
                      Text(context.tr('businesses'), style: tt.labelSmall),
                      if ((ty['tenants_on_older_version'] as int) > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Pill('${f.intN(ty['tenants_on_older_version'] as int)} ${context.tr('to update')}', color: t.info, dense: true)),
                    ]),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

const _swatches = ['#0E9F6E', '#E8A200', '#D6336C', '#B5651D', '#0891B2', '#6D28D9', '#2563EB', '#DC2626', '#0F766E', '#4D7C0F'];
const _icons = [('store', 'Store'), ('shopping_basket', 'Basket'), ('spa', 'Beauty'), ('chair', 'Furniture'), ('medication', 'Pharmacy')];
const _attrTypes = ['text', 'textarea', 'int', 'decimal', 'money', 'bool', 'date', 'select', 'multiselect', 'select_or_create'];

class _TypeEditor extends ConsumerStatefulWidget {
  const _TypeEditor({required this.catalog, required this.types, this.existing});
  final Map<String, dynamic> catalog;
  final List<Map<String, dynamic>> types;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_TypeEditor> createState() => _TypeEditorState();
}

class _TypeEditorState extends ConsumerState<_TypeEditor> {
  late Map<String, dynamic> _def;
  final _key = TextEditingController();
  late final _label = TextEditingController(text: widget.existing?['label'] as String?);
  late final _desc = TextEditingController(text: widget.existing?['description'] as String?);
  late String _family = (widget.existing?['family'] as String?) ?? 'counter_retail';
  late bool _active = widget.existing?['active'] != false;
  String? _copyFrom;
  final Map<String, TextEditingController> _term = {};
  late final TextEditingController _cats;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.existing != null;
  Map<String, dynamic> _copy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _def = _copy(widget.existing != null ? (widget.existing!['definition'] as Map).cast() : (widget.types.first['definition'] as Map).cast());
    _cats = TextEditingController(text: ((_def['categories'] as List?) ?? const []).join('\n'));
    for (final k in ['customer', 'product', 'supplier', 'due']) {
      _term[k] = TextEditingController(text: ((_def['terminology'] as Map?)?[k] as String?) ?? '');
    }
  }

  void _adopt(Map<String, dynamic> from) {
    _def = _copy(from);
    _cats.text = ((_def['categories'] as List?) ?? const []).join('\n');
    for (final k in _term.keys) {
      _term[k]!.text = ((_def['terminology'] as Map?)?[k] as String?) ?? '';
    }
  }

  Map<String, dynamic> get _stock => (_def['stock'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  Map<String, dynamic> get _tax => (_def['tax'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  Map<String, dynamic> get _theme => (_def['theme'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  Map<String, dynamic> get _loyalty => (_def['loyalty'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  Set<String> get _caps => {...(_def['capabilities'] as List).cast<String>()};

  Future<void> _save() async {
    _def['categories'] = _cats.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    _def['terminology'] = {for (final e in _term.entries) if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim()};
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'key': _editing ? widget.existing!['key'] : _key.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_'),
      'label': _label.text.trim(),
      'description': _desc.text.trim(),
      'family': _family,
      'sort_order': widget.existing?['sort_order'] ?? 20,
      'active': _active,
      'definition': _def,
    };
    try {
      if (_editing) {
        await ref.read(apiProvider).put('/admin/business-types/${widget.existing!['key']}', body: body);
      } else {
        await ref.read(apiProvider).post('/admin/business-types', body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final capsMeta = (widget.catalog['capabilities'] as Map).cast<String, dynamic>();
    final groups = <String, List<MapEntry<String, dynamic>>>{};
    for (final c in capsMeta.entries) {
      groups.putIfAbsent((c.value as Map)['group'] as String, () => []).add(c);
    }
    final caps = _caps;
    final attrs = ((_def['attributes'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final taxClasses = ((_tax['classes'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final accent = accentOf(_theme.cast());
    return PanelScaffold(
      title: _editing ? (widget.existing!['label'] as String) : context.tr('New business type'),
      subtitle: _editing ? '${context.tr('Version')} ${widget.existing!['version']} · ${widget.existing!['tenant_count']} ${context.tr('businesses')}. ${context.tr('Saving publishes a new version.')}' : null,
      leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(13)), child: Icon(typeIcon(_theme['icon'] as String?), color: Colors.white)),
      footer: Row(children: [const Spacer(), TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))), const SizedBox(width: 8), FilledButton(onPressed: _busy ? null : _save, child: Text(_editing ? context.tr('Publish new version') : context.tr('Create type')))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.error_outline_rounded, size: 19, color: t.danger), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
        if (!_editing) ...[
          Row(children: [
            Expanded(child: TextField(controller: _key, decoration: InputDecoration(labelText: context.tr('Key'), hintText: 'mobile_shop', helperText: context.tr('Lowercase letters, digits, underscore')))),
            const SizedBox(width: 12),
            Expanded(child: DropdownBox<String>(label: context.tr('Start from a copy of'), value: _copyFrom, items: [for (final x in widget.types) DropdownMenuItem(value: x['key'] as String, child: Text(x['label'] as String))], onChanged: (v) => setState(() {
                  _copyFrom = v;
                  if (v != null) _adopt((widget.types.firstWhere((x) => x['key'] == v)['definition'] as Map).cast());
                }))),
          ]),
          const FormGap(),
        ],
        TextField(controller: _label, decoration: InputDecoration(labelText: context.tr('Name'))),
        const FormGap(),
        TextField(controller: _desc, maxLines: 2, decoration: InputDecoration(labelText: context.tr('Description'))),
        const FormGap(),
        Row(children: [Text('${context.tr('Sales flow')}:', style: tt.titleSmall), const SizedBox(width: 10), SegTabs<String>(items: [('counter_retail', context.tr('Counter')), ('order_based', context.tr('Order-based'))], value: _family, onChanged: (v) => setState(() => _family = v))]),
        const FormGap(8),
        SwitchRow(title: context.tr('Available when adding a business'), value: _active, onChanged: (v) => setState(() => _active = v)),
        const FormHeading('Look'),
        Wrap(spacing: 10, runSpacing: 10, children: [for (final s in _swatches) GestureDetector(onTap: () => setState(() => _theme['accent'] = s), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: accentOf({'accent': s}), shape: BoxShape.circle, border: Border.all(color: _theme['accent'] == s ? t.text : Colors.transparent, width: 2.5))))]),
        const FormGap(),
        Wrap(spacing: 8, children: [for (final (k, l) in _icons) ChoiceChip(avatar: Icon(typeIcon(k), size: 17), label: Text(l), selected: _theme['icon'] == k, onSelected: (_) => setState(() => _theme['icon'] = k))]),
        const FormHeading('Capabilities', hint: 'Behaviours this kind of business uses. Some need another to be on; unshipped ones are locked.'),
        for (final g in groups.entries) ...[
          Padding(padding: const EdgeInsets.only(top: 6, bottom: 6), child: Text(g.key, style: tt.labelMedium!.copyWith(color: t.muted))),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in g.value)
              Tooltip(
                message: (c.value as Map)['status'] == 'planned' ? context.tr('Coming soon') : (c.value as Map)['description'] as String,
                child: FilterChip(
                  label: Text((c.value as Map)['label'] as String),
                  selected: caps.contains(c.key),
                  onSelected: (c.value as Map)['status'] == 'planned'
                      ? null
                      : (on) => setState(() {
                            final s = _caps;
                            if (on) {
                              s.add(c.key);
                              s.addAll(((c.value as Map)['requires'] as List).cast<String>());
                            } else {
                              s.remove(c.key);
                              s.removeWhere((k) => (((capsMeta[k] as Map)['requires'] as List).cast<String>()).contains(c.key));
                            }
                            _def['capabilities'] = s.toList()..sort();
                          }),
                ),
              ),
          ]),
        ],
        const FormHeading('Words this business uses'),
        Wrap(spacing: 10, runSpacing: 10, children: [for (final e in _term.entries) SizedBox(width: 190, child: TextField(controller: e.value, decoration: InputDecoration(labelText: e.key[0].toUpperCase() + e.key.substring(1))))]),
        const FormHeading('Extra product fields', hint: 'These appear on the add-product form for this kind of business.'),
        for (final (i, a) in attrs.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(
              onTap: () async {
                final r = await showPanel<Map<String, dynamic>>(context, maxWidth: 480, builder: (_) => _AttrEditor(existing: a));
                if (r != null) setState(() => attrs[i] = r);
              },
              color: t.surface2,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${a['label']}${a['required'] == true ? ' *' : ''}', style: tt.titleSmall), Text('${a['key']} · ${a['type']}${(a['options'] as List).isEmpty ? '' : ' · ${(a['options'] as List).join(', ')}'}', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)])),
                IconButton(icon: const Icon(Icons.close_rounded, size: 19), onPressed: () => setState(() => attrs.removeAt(i))),
              ]),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final r = await showPanel<Map<String, dynamic>>(context, maxWidth: 480, builder: (_) => const _AttrEditor());
            if (r != null) setState(() => _def['attributes'] = [...attrs, r]);
          },
          icon: const Icon(Icons.add_rounded, size: 19),
          label: Text(context.tr('Add a field')),
        ),
        const FormHeading('Stock & tax defaults'),
        Row(children: [
          Expanded(child: DropdownBox<String>(label: context.tr('Which stock sells first'), value: (_stock['allocation'] as String?) ?? 'none', items: [DropdownMenuItem(value: 'none', child: Text(context.tr('No batches'))), DropdownMenuItem(value: 'fefo', child: Text(context.tr('Soonest expiry first'))), DropdownMenuItem(value: 'fifo', child: Text(context.tr('Oldest first')))], onChanged: (v) => setState(() => _stock['allocation'] = v))),
          const SizedBox(width: 12),
          Expanded(child: DropdownBox<String>(label: context.tr('VAT in prices'), value: (_tax['mode'] as String?) ?? 'inclusive', items: [DropdownMenuItem(value: 'inclusive', child: Text(context.tr('Included'))), DropdownMenuItem(value: 'exclusive', child: Text(context.tr('Added on top')))], onChanged: (v) => setState(() => _tax['mode'] = v))),
        ]),
        const FormGap(8),
        SwitchRow(title: context.tr('Allow selling below zero stock'), value: _stock['allow_negative'] == true, onChanged: (v) => setState(() => _stock['allow_negative'] = v)),
        SwitchRow(title: context.tr('Round bills to the nearest taka'), value: _tax['cash_rounding'] == 'nearest_1', onChanged: (v) => setState(() => _tax['cash_rounding'] = v ? 'nearest_1' : 'none')),
        if (caps.contains('loyalty')) SwitchRow(title: context.tr('Loyalty points on by default'), value: _loyalty['enabled'] == true, onChanged: (v) => setState(() {
              _loyalty['enabled'] = v;
              _loyalty['points_per_100'] ??= 1;
            })),
        const FormGap(8),
        Text(context.tr('VAT classes'), style: tt.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final (i, c) in taxClasses.indexed) InputChip(label: Text('${c['name']} · ${c['rate']}%'), onDeleted: taxClasses.length > 1 ? () => setState(() => taxClasses.removeAt(i)) : null)]),
        const FormGap(8),
        OutlinedButton.icon(
          onPressed: () async {
            final name = TextEditingController(), rate = TextEditingController();
            final ok = await showPanel<bool>(context, maxWidth: 380, builder: (c) => PanelScaffold(title: context.tr('Add VAT class'), footer: FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('Add'))), child: Column(children: [TextField(controller: name, decoration: InputDecoration(labelText: context.tr('Name'), hintText: 'VAT 15%')), const FormGap(), TextField(controller: rate, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Rate (%)')))])));
            if (ok == true && name.text.trim().isNotEmpty) setState(() => _tax['classes'] = [...taxClasses, {'name': name.text.trim(), 'rate': double.tryParse(rate.text.trim()) ?? 0}]);
          },
          icon: const Icon(Icons.add_rounded, size: 19),
          label: Text(context.tr('Add VAT class')),
        ),
        const FormHeading('Starter categories', hint: 'One per line. Copied into every new business of this type.'),
        TextField(controller: _cats, maxLines: 6, minLines: 3, decoration: const InputDecoration(hintText: 'Skincare\nMakeup')),
      ]),
    );
  }
}

class _AttrEditor extends StatefulWidget {
  const _AttrEditor({this.existing});
  final Map<String, dynamic>? existing;

  @override
  State<_AttrEditor> createState() => _AttrEditorState();
}

class _AttrEditorState extends State<_AttrEditor> {
  late final _key = TextEditingController(text: widget.existing?['key'] as String?);
  late final _label = TextEditingController(text: widget.existing?['label'] as String?);
  late final _labelBn = TextEditingController(text: widget.existing?['label_bn'] as String?);
  late final _options = TextEditingController(text: ((widget.existing?['options'] as List?) ?? const []).join(', '));
  late final _group = TextEditingController(text: (widget.existing?['group'] as String?) ?? 'Details');
  late String _type = (widget.existing?['type'] as String?) ?? 'text';
  late bool _required = widget.existing?['required'] == true;
  late final Map<String, dynamic> _flags = {...((widget.existing?['flags'] as Map?)?.cast<String, dynamic>() ?? {})};

  @override
  Widget build(BuildContext context) => PanelScaffold(
        title: widget.existing == null ? context.tr('New field') : (widget.existing!['label'] as String),
        footer: FilledButton(
          onPressed: _label.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, {
                    'key': (widget.existing?['key'] as String?) ?? _key.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_'),
                    'label': _label.text.trim(),
                    'label_bn': _labelBn.text.trim(),
                    'type': _type,
                    'required': _required,
                    'options': _options.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    'unit': widget.existing?['unit'],
                    'group': _group.text.trim().isEmpty ? 'Details' : _group.text.trim(),
                    'flags': {for (final k in ['searchable', 'filterable', 'show_in_pos', 'show_on_label', 'show_on_receipt']) k: _flags[k] == true},
                  }),
          child: Text(context.tr('Done')),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _label, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Label'))),
          const FormGap(),
          TextField(controller: _labelBn, decoration: InputDecoration(labelText: context.tr('Label in Bangla'))),
          if (widget.existing == null) ...[const FormGap(), TextField(controller: _key, decoration: InputDecoration(labelText: context.tr('Key'), hintText: 'skin_type', helperText: context.tr('Stored with each product; can’t change later')))],
          const FormGap(),
          DropdownBox<String>(label: context.tr('Type'), value: _type, items: [for (final t in _attrTypes) DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))], onChanged: (v) => setState(() => _type = v ?? 'text')),
          if (_type == 'select' || _type == 'multiselect') ...[const FormGap(), TextField(controller: _options, decoration: InputDecoration(labelText: context.tr('Options (comma separated)')))],
          const FormGap(),
          TextField(controller: _group, decoration: InputDecoration(labelText: context.tr('Section on the form'))),
          const FormGap(),
          SwitchRow(title: context.tr('Required'), value: _required, onChanged: (v) => setState(() => _required = v)),
          SwitchRow(title: context.tr('Searchable at the till'), value: _flags['searchable'] == true, onChanged: (v) => setState(() => _flags['searchable'] = v)),
          SwitchRow(title: context.tr('Filterable in lists'), value: _flags['filterable'] == true, onChanged: (v) => setState(() => _flags['filterable'] = v)),
          SwitchRow(title: context.tr('Shown on the sale screen'), value: _flags['show_in_pos'] == true, onChanged: (v) => setState(() => _flags['show_in_pos'] = v)),
        ]),
      );
}
