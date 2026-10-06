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

final adminPlansProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async => ref.watch(apiProvider).getMap('/admin/plans'));

/// Plans & pricing. **Every number a business pays or is limited by is edited here** — nothing is in code.
class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final data = ref.watch(adminPlansProvider);
    return PageBody(
      maxWidth: 1180,
      child: AsyncBody<Map<String, dynamic>>(
        value: data,
        onRetry: () => ref.invalidate(adminPlansProvider),
        data: (d) {
          final plans = (d['plans'] as List).cast<Map<String, dynamic>>();
          return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('Set what each plan costs and includes'), style: tt.titleLarge), Text(context.tr('Changes apply to new payments straight away. A request already waiting keeps the price it was filed at.'), style: tt.bodySmall)])),
              FilledButton.icon(
                onPressed: () async {
                  final r = await showPanel<bool>(context, maxWidth: 760, dismissible: false, builder: (_) => Material(color: Colors.transparent, child: PanelScaffold(title: context.tr('New plan'), child: PlanEditor(catalog: d, onSaved: () => Navigator.pop(context, true)))));
                  if (r == true) ref.invalidate(adminPlansProvider);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(context.tr('New plan')),
              ),
            ]),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (c, box) {
              final cols = box.maxWidth > 1000 ? 3 : (box.maxWidth > 680 ? 2 : 1);
              final w = (box.maxWidth - 16 * (cols - 1)) / cols;
              return Wrap(spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.start, children: [
                for (final p in plans) SizedBox(width: w, child: Surface(padding: const EdgeInsets.all(18), child: PlanEditor(catalog: d, existing: p, onSaved: () => ref.invalidate(adminPlansProvider)))),
              ]);
            }),
          ]);
        },
      ),
    );
  }
}

class PlanEditor extends ConsumerStatefulWidget {
  const PlanEditor({super.key, required this.catalog, this.existing, required this.onSaved});
  final Map<String, dynamic> catalog;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<PlanEditor> {
  late final _key = TextEditingController(text: widget.existing?['key'] as String?);
  late final _name = TextEditingController(text: widget.existing?['name'] as String?);
  late final _tagline = TextEditingController(text: widget.existing?['tagline'] as String?);
  late final _monthly = TextEditingController(text: _fmt(widget.existing?['monthly_price']));
  late final _yearly = TextEditingController(text: _fmt(widget.existing?['yearly_price']));
  late final _trial = TextEditingController(text: '${widget.existing?['trial_days'] ?? 14}');
  late final Map<String, TextEditingController> _limits;
  late final Set<String> _features;
  late bool _allCaps;
  late final Set<String> _caps;
  late bool _highlight, _public, _active;
  bool _busy = false, _dirty = false;

  String _fmt(Object? v) => v == null ? '' : paisaToWire(parsePaisa(v)).replaceAll(RegExp(r'\.00$'), '');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final limitKeys = (widget.catalog['limit_keys'] as Map).keys.cast<String>().toList();
    _limits = {for (final k in limitKeys) k: TextEditingController(text: ((e?['limits'] as Map?)?[k] ?? (k == 'sales_per_month' ? -1 : 1000)).toString())};
    _features = {...((e?['features'] as List?)?.cast<String>() ?? const ['pos', 'inventory', 'customers', 'reports', 'offline_sync'])};
    _allCaps = e == null ? true : e['capabilities'] == null;
    _caps = {...((e?['capabilities'] as List?)?.cast<String>() ?? const <String>[])};
    _highlight = e?['highlight'] == true;
    _public = e?['public'] != false;
    _active = e?['active'] != false;
  }

  void _touch() => setState(() => _dirty = true);

  Future<void> _save() async {
    setState(() => _busy = true);
    final body = {
      'key': _key.text.trim().isEmpty ? widget.existing!['key'] : _key.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_'),
      'name': _name.text.trim(),
      'tagline': _tagline.text.trim(),
      'monthly_price': _monthly.text.trim().isEmpty ? '0' : _monthly.text.trim(),
      'yearly_price': _yearly.text.trim().isEmpty ? '0' : _yearly.text.trim(),
      'currency': 'BDT',
      'trial_days': int.tryParse(_trial.text.trim()) ?? 0,
      'limits': {for (final e in _limits.entries) e.key: int.tryParse(e.value.text.trim()) ?? -1},
      'features': _features.toList(),
      'capabilities': _allCaps ? null : _caps.toList(),
      'highlight': _highlight,
      'public': _public,
      'active': _active,
      'sort_order': widget.existing?['sort_order'] ?? 10,
    };
    try {
      final api = ref.read(apiProvider);
      if (widget.existing == null) {
        await api.post('/admin/plans', body: body);
      } else {
        await api.put('/admin/plans/${widget.existing!['id']}', body: body);
      }
      if (mounted) {
        toast(context, context.tr('Plan saved'), good: true);
        setState(() => _dirty = false);
      }
      widget.onSaved();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final n = widget.existing!['tenant_count'] as int;
    final ok = await confirmDialog(context, title: context.tr('Remove this plan?'), message: n > 0 ? context.trf('{n} businesses are on it, so it will be hidden and closed to new sign-ups instead of deleted.', {'n': context.fmt.intN(n)}) : context.tr('No business uses it. It will be deleted.'), confirm: context.tr('Remove'), danger: true);
    if (!ok) return;
    try {
      await ref.read(apiProvider).delete('/admin/plans/${widget.existing!['id']}');
      widget.onSaved();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final e = widget.existing;
    final features = (widget.catalog['features'] as Map).cast<String, String>();
    final limitLabels = (widget.catalog['limit_keys'] as Map).cast<String, String>();
    final caps = (widget.catalog['capabilities'] as Map).cast<String, dynamic>();
    final monthly = paisaOf(_monthly), yearly = paisaOf(_yearly);
    final saving = monthly > 0 && yearly > 0 ? ((monthly * 12 - yearly) * 100 / (monthly * 12)) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(controller: _name, onChanged: (_) => _touch(), style: tt.headlineSmall, decoration: InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, hintText: context.tr('Plan name'), contentPadding: EdgeInsets.zero))),
        if (e != null) ...[
          Pill('${f.intN(e['tenant_count'] as int)} ${context.tr('businesses')}', dense: true),
          PopupMenuButton<String>(onSelected: (_) => _delete(), itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(context.tr('Remove plan'), style: TextStyle(color: t.danger)))]),
        ],
      ]),
      if (e == null) ...[const FormGap(8), TextField(controller: _key, decoration: InputDecoration(labelText: context.tr('Plan key'), hintText: 'gold', helperText: context.tr('Short id, letters and digits')))],
      const FormGap(8),
      TextField(controller: _tagline, onChanged: (_) => _touch(), decoration: InputDecoration(labelText: context.tr('One-line description'))),
      const FormGap(),
      Row(children: [
        Expanded(child: MoneyField(controller: _monthly, label: context.tr('Per month'), onChanged: (_) => _touch())),
        const SizedBox(width: 10),
        Expanded(child: MoneyField(controller: _yearly, label: context.tr('Per year'), onChanged: (_) => _touch())),
      ]),
      if (saving > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text(context.trf('Yearly saves {pct}% versus 12 months', {'pct': context.fmt.intN(saving.round())}), style: tt.bodySmall!.copyWith(color: t.success, fontWeight: FontWeight.w700))),
      const FormGap(),
      TextField(controller: _trial, keyboardType: TextInputType.number, onChanged: (_) => _touch(), decoration: InputDecoration(labelText: context.tr('Free trial (days)'), prefixIcon: const Icon(Icons.card_giftcard_rounded, size: 19))),
      const FormHeading('Limits', hint: '-1 means unlimited'),
      Wrap(spacing: 10, runSpacing: 10, children: [for (final k in _limits.entries) SizedBox(width: 130, child: TextField(controller: k.value, keyboardType: const TextInputType.numberWithOptions(signed: true), onChanged: (_) => _touch(), decoration: InputDecoration(labelText: limitLabels[k.key] ?? k.key)))]),
      const FormHeading('Included features'),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final k in features.entries) FilterChip(label: Text(k.value), selected: _features.contains(k.key), onSelected: (on) {
            on ? _features.add(k.key) : _features.remove(k.key);
            _touch();
          })]),
      const FormHeading('Business capabilities', hint: 'Which behaviours businesses on this plan may use.'),
      SwitchRow(title: context.tr('All capabilities'), subtitle: _allCaps ? context.tr('Whatever the business type enables') : context.tr('Restricted to the ticked ones'), value: _allCaps, onChanged: (v) {
        _allCaps = v;
        _touch();
      }),
      if (!_allCaps)
        Wrap(spacing: 8, runSpacing: 8, children: [for (final c in caps.entries.where((c) => (c.value as Map)['status'] == 'ready')) FilterChip(label: Text((c.value as Map)['label'] as String), selected: _caps.contains(c.key), onSelected: (on) {
              on ? _caps.add(c.key) : _caps.remove(c.key);
              _touch();
            })]),
      const FormGap(),
      SwitchRow(title: context.tr('Show on the pricing page'), value: _public, onChanged: (v) {
        _public = v;
        _touch();
      }),
      SwitchRow(title: context.tr('Highlight as “Popular”'), value: _highlight, onChanged: (v) {
        _highlight = v;
        _touch();
      }),
      SwitchRow(title: context.tr('Active'), subtitle: context.tr('Inactive plans can’t be bought'), value: _active, onChanged: (v) {
        _active = v;
        _touch();
      }),
      const FormGap(),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy || (!_dirty && e != null) ? null : _save,
          icon: _busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: t.onAccent)) : const Icon(Icons.check_rounded),
          label: Text(e == null ? context.tr('Create plan') : (_dirty ? context.tr('Save changes') : context.tr('Saved'))),
        ),
      ),
    ]);
  }
}
