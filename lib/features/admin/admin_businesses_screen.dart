import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Color accentOf(Map<String, dynamic>? theme) {
  final hex = (theme?['accent'] as String?) ?? '#0E9F6E';
  return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
}

IconData typeIcon(String? name) => switch (name) {
      'shopping_basket' => Icons.shopping_basket_rounded,
      'spa' => Icons.spa_rounded,
      'chair' => Icons.chair_rounded,
      'medication' => Icons.medication_rounded,
      _ => Icons.store_rounded,
    };

final _publicTypesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => (await ref.watch(apiProvider).getList('/public/business-types')).cast<Map<String, dynamic>>());

class AdminBusinessesScreen extends ConsumerStatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  ConsumerState<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends ConsumerState<AdminBusinessesScreen> {
  final _q = TextEditingController();
  String? _status;
  final List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  Object? _error;
  Timer? _debounce;

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

  Future<void> _load({bool reset = false}) async {
    if (reset) _items.clear();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(apiProvider).getMap('/admin/tenants', query: {'limit': 40, 'offset': _items.length, if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(), if (_status != null) 'status': _status});
      _items.addAll((r['items'] as List).cast<Map<String, dynamic>>());
      _total = (r['total'] as num).toInt();
    } on ApiError catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    return PageBody(
      maxWidth: 1100,
      child: Column(children: [
        Row(children: [
          Expanded(child: AppSearchField(controller: _q, hint: context.tr('Search by business, owner or phone'), onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
          })),
          const SizedBox(width: 10),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () async {
                final r = await showPanel<bool>(context, maxWidth: 720, dismissible: false, builder: (_) => const _AddBusiness());
                if (r == true) _load(reset: true);
              },
              icon: const Icon(Icons.add_business_rounded, size: 21),
              label: Text(context.tr('Add business')),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegTabs<String?>(items: [(null, context.tr('All')), ('trialing', context.tr('Trial')), ('active', context.tr('Active')), ('suspended', context.tr('Suspended'))], value: _status, onChanged: (v) {
              setState(() => _status = v);
              _load(reset: true);
            }),
          ),
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Text('${f.intN(_total)} ${context.tr('businesses')}', style: tt.labelMedium!.copyWith(color: t.muted))),
        const SizedBox(height: 8),
        Expanded(
          child: _error != null
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : _items.isEmpty && _loading
                  ? const SkeletonList(rows: 6, height: 76)
                  : _items.isEmpty
                      ? EmptyState(icon: Icons.storefront_outlined, title: context.tr('No businesses yet'), message: context.tr('Add the first one — pick its type and plan, and everything else is set up for you.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _items.length + (_items.length < _total ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _items.length) return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: _loading ? null : () => _load(), child: Text(context.tr('Load more')))));
                            final b = _items[i];
                            final state = b['state'] as String;
                            final c = switch (state) { 'active' => t.success, 'trialing' => t.info, 'grace' => t.warning, _ => t.danger };
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Surface(
                                onTap: () async {
                                  final r = await showPanel<bool>(context, maxWidth: 640, builder: (_) => _BusinessDetail(id: b['id'] as String));
                                  if (r == true) _load(reset: true);
                                },
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Monogram(b['name'] as String, size: 46),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(b['name'] as String, style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${(b['business_type'] as Map?)?['label'] ?? ''} · ${b['owner_name']} · ${f.digits(b['phone'] as String)}', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ])),
                                  if (context.width > 700) ...[
                                    Padding(padding: const EdgeInsets.only(right: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [NumText(f.moneyCompact(parsePaisa(b['revenue_30d'])), size: 14), Text('${f.intN(b['sales_30d'] as int)} ${context.tr('sales / 30d')}', style: tt.bodySmall)])),
                                  ],
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Pill('${(b['plan'] as Map?)?['name'] ?? ''}', dense: true), const SizedBox(height: 4), Pill(context.tr(state == 'grace' ? 'Grace' : state[0].toUpperCase() + state.substring(1)), color: c, dense: true)]),
                                ]),
                              ),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}

extension _W on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
}

// ------------------------------------------------------------------------------------------ detail

class _BusinessDetail extends ConsumerStatefulWidget {
  const _BusinessDetail({required this.id});
  final String id;

  @override
  ConsumerState<_BusinessDetail> createState() => _BusinessDetailState();
}

class _BusinessDetailState extends ConsumerState<_BusinessDetail> {
  Map<String, dynamic>? _b;
  Map<String, dynamic>? _plans;
  Map<String, dynamic>? _caps;
  Object? _error;
  bool _changed = false, _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiProvider);
      _b = await api.getMap('/admin/tenants/${widget.id}');
      _plans ??= await api.getMap('/admin/plans');
      _caps ??= (_plans!['capabilities'] as Map).cast<String, dynamic>();
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() {});
  }

  Future<void> _patch(Map<String, dynamic> body, {String? done}) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).patch('/admin/tenants/${widget.id}', body: body);
      _changed = true;
      await _load();
      if (done != null && mounted) toast(context, done, good: true);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    if (_error != null) return PanelScaffold(title: context.tr('Business'), child: ErrorView(error: _error!, onRetry: _load));
    final b = _b;
    if (b == null) return PanelScaffold(title: context.tr('Business'), child: const SkeletonList(rows: 4));
    final usage = (b['usage'] as Map).cast<String, dynamic>();
    final limits = (b['limits'] as Map).cast<String, dynamic>();
    final bt = (b['business_type'] as Map?)?.cast<String, dynamic>();
    final enabled = ((b['capability_overrides'] as Map)['enabled'] as List? ?? const []).cast<String>();
    final disabled = ((b['capability_overrides'] as Map)['disabled'] as List? ?? const []).cast<String>();
    final effective = (b['capabilities'] as List).cast<String>();
    final base = (b['capability_base'] as List).cast<String>();
    final planKeys = [for (final p in (_plans!['plans'] as List).cast<Map<String, dynamic>>().where((p) => p['active'] == true)) p];
    final stale = bt != null && (b['template_version'] as int) < (bt['current_version'] as int);
    final suspended = b['status'] == 'suspended';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: PanelScaffold(
        title: b['name'] as String,
        subtitle: '${bt?['label'] ?? ''} · ${b['city']}',
        leading: Monogram(b['name'] as String, size: 46),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final (label, v) in [('Staff', '${usage['staff']}${(limits['staff'] as num) >= 0 ? ' / ${limits['staff']}' : ''}'), ('Branches', '${usage['branches']}${(limits['branches'] as num) >= 0 ? ' / ${limits['branches']}' : ''}'), ('Products', '${usage['products']}${(limits['products'] as num) >= 0 ? ' / ${limits['products']}' : ''}'), ('Tills', '${usage['devices']}${(limits['devices'] as num) >= 0 ? ' / ${limits['devices']}' : ''}'), ('Sales / 30d', f.intN(b['sales_30d'] as int)), ('Revenue / 30d', f.moneyCompact(parsePaisa(b['revenue_30d'])))])
              Container(width: 150, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr(label), style: tt.labelSmall), const SizedBox(height: 3), NumText(v.startsWith('৳') ? v : f.digits(v), size: 17, weight: 800)])),
          ]),
          const FormHeading('Owner'),
          KV(context.tr('Name'), b['owner_name'] as String, mono: false),
          KV(context.tr('Phone'), f.digits(b['phone'] as String)),
          KV(context.tr('Last active'), b['last_active_at'] == null ? '—' : f.ago(DateTime.parse(b['last_active_at'] as String)), mono: false),
          const FormHeading('Subscription'),
          DropdownBox<String>(label: context.tr('Plan'), value: (b['plan'] as Map?)?['key'] as String?, icon: Icons.workspace_premium_rounded, items: [for (final p in planKeys) DropdownMenuItem(value: p['key'] as String, child: Text('${p['name']} · ${f.money(parsePaisa(p['monthly_price']))}/${context.tr('mo')}'))], onChanged: (v) {
            if (v != null && v != (b['plan'] as Map?)?['key']) _patch({'plan_key': v, 'reason': 'Plan changed from console'}, done: context.tr('Plan changed'));
          }),
          const FormGap(),
          KV(context.tr('Status'), context.tr(b['state'] as String), mono: false, bold: true),
          KV(context.tr('Access until'), f.date(DateTime.parse(b['period_end'] as String)), mono: false),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in [7, 30, 365]) OutlinedButton(onPressed: _busy ? null : () => _patch({'extend_days': d, 'reason': 'Extended from console'}, done: context.trf('Extended by {n} days', {'n': f.intN(d)})), child: Text('+${f.intN(d)} ${context.tr('days')}')),
            suspended
                ? FilledButton(onPressed: _busy ? null : () => _patch({'status': 'active'}, done: context.tr('Reactivated')), child: Text(context.tr('Reactivate')))
                : OutlinedButton(onPressed: _busy ? null : () async {
                    final sure = await confirmDialog(context, title: context.tr('Suspend this business?'), message: context.tr('Staff are locked out until you reactivate it. Sales already made on tills still sync.'), confirm: context.tr('Suspend'), danger: true);
                    if (sure && context.mounted) _patch({'status': 'suspended', 'reason': 'Suspended from console'}, done: context.tr('Suspended'));
                  }, child: Text(context.tr('Suspend'), style: TextStyle(color: t.danger))),
          ]),
          const FormHeading('Capabilities', hint: 'What this business can do. Switch individual ones on or off for just this business.'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in _caps!.entries.where((c) => (c.value as Map)['status'] == 'ready'))
              FilterChip(
                label: Text((c.value as Map)['label'] as String),
                selected: effective.contains(c.key),
                avatar: base.contains(c.key) ? null : Icon(Icons.tune_rounded, size: 15, color: t.accentDeep),
                onSelected: _busy
                    ? null
                    : (on) {
                        final en = {...enabled}, di = {...disabled};
                        if (on) {
                          di.remove(c.key);
                          if (!base.contains(c.key)) en.add(c.key);
                        } else {
                          en.remove(c.key);
                          if (base.contains(c.key)) di.add(c.key);
                        }
                        _patch({'capabilities_enabled': en.toList(), 'capabilities_disabled': di.toList(), 'reason': 'Capability override'});
                      },
              ),
          ]),
          if (stale) ...[
            const FormGap(),
            Surface(
              color: t.tint(t.info, 0.1),
              border: false,
              child: Row(children: [
                Icon(Icons.system_update_alt_rounded, color: t.info),
                const SizedBox(width: 12),
                Expanded(child: Text(context.trf('{type} has a newer version (v{current}). This business is on v{used}.', {'type': bt['label'], 'current': bt['current_version'], 'used': b['template_version']}), style: tt.bodyMedium)),
                FilledButton(onPressed: _busy ? null : () async {
                  try {
                    await ref.read(apiProvider).post('/admin/tenants/${widget.id}/apply-template');
                    _changed = true;
                    await _load();
                  } on ApiError catch (e) {
                    if (context.mounted) toast(context, e.message, error: true);
                  }
                }, child: Text(context.tr('Update'))),
              ]),
            ),
          ],
          const FormGap(20),
          OutlinedButton.icon(
            onPressed: () async {
              if (!await confirmDialog(context, title: context.tr('Reset the owner password?'), message: context.tr('A new password is generated and shown once. The old one stops working.'), confirm: context.tr('Reset'))) return;
              try {
                final r = await ref.read(apiProvider).post('/admin/tenants/${widget.id}/reset-owner-password');
                if (!context.mounted) return;
                await showPanel<void>(context, maxWidth: 420, builder: (c) => _Credentials(phone: r['phone'] as String, password: r['password'] as String));
              } on ApiError catch (e) {
                if (context.mounted) toast(context, e.message, error: true);
              }
            },
            icon: const Icon(Icons.key_rounded, size: 19),
            label: Text(context.tr('Reset owner password')),
          ),
        ]),
      ),
    );
  }
}

class _Credentials extends StatelessWidget {
  const _Credentials({required this.phone, required this.password});
  final String phone, password;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PanelScaffold(
      title: context.tr('Owner login'),
      subtitle: context.tr('Shown once — copy it now.'),
      leading: IconSquare(Icons.key_rounded, color: t.warning),
      footer: FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('Done'))),
      child: Surface(
        color: t.surface2,
        child: Column(children: [
          _CopyRow(context.tr('Phone'), phone),
          const Divider(height: 22),
          _CopyRow(context.tr('Password'), password),
        ]),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 2), SelectableText(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))])),
        IconButton(icon: const Icon(Icons.copy_rounded), onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) toast(context, context.tr('Copied'), good: true);
        }),
      ]);
}

// ------------------------------------------------------------------------------------------ wizard

class _AddBusiness extends ConsumerStatefulWidget {
  const _AddBusiness();

  @override
  ConsumerState<_AddBusiness> createState() => _AddBusinessState();
}

class _AddBusinessState extends ConsumerState<_AddBusiness> {
  int _step = 0;
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _lang = 'bn';
  String? _type, _plan;
  String _cycle = 'monthly';
  int? _trial;
  bool _sample = true, _busy = false;
  String? _error;
  Map<String, dynamic>? _plans;

  @override
  void initState() {
    super.initState();
    ref.read(apiProvider).getMap('/admin/plans').then((p) {
      if (mounted) setState(() => _plans = p);
    });
  }

  bool get _step0Ok => _name.text.trim().length >= 2 && _owner.text.trim().length >= 2 && RegExp(r'^01[3-9]\d{8}$').hasMatch(_phone.text.trim());

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(apiProvider).post('/admin/tenants', body: {
        'name': _name.text.trim(),
        'owner_name': _owner.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        if (_password.text.isNotEmpty) 'password': _password.text,
        'business_type_key': _type,
        'plan_key': _plan,
        'billing_cycle': _cycle,
        if (_trial != null) 'trial_days': _trial,
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'language': _lang,
        'sample_data': _sample,
      });
      final login = (r['owner_login'] as Map).cast<String, dynamic>();
      if (!mounted) return;
      await showPanel<void>(context, maxWidth: 440, dismissible: false, builder: (c) => PanelScaffold(
            title: context.trf('{name} is ready', {'name': _name.text.trim()}),
            subtitle: context.tr('Give the owner these details to sign in.'),
            leading: IconSquare(Icons.check_circle_rounded, color: context.t.success),
            footer: FilledButton(onPressed: () => Navigator.pop(c), child: Text(context.tr('Done'))),
            child: Surface(color: context.t.surface2, child: Column(children: [_CopyRow(context.tr('Phone'), login['phone'] as String), const Divider(height: 22), _CopyRow(context.tr('Password'), login['password'] as String)])),
          ));
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
    final f = context.fmt;
    final types = ref.watch(_publicTypesProvider).value ?? const [];
    final plans = ((_plans?['plans'] as List?) ?? const []).cast<Map<String, dynamic>>().where((p) => p['active'] == true).toList();
    final steps = [context.tr('Business'), context.tr('Type'), context.tr('Plan'), context.tr('Owner')];
    final canNext = switch (_step) { 0 => _step0Ok, 1 => _type != null, 2 => _plan != null, _ => true };
    final chosenType = types.where((x) => x['key'] == _type).firstOrNull;
    final chosenPlan = plans.where((p) => p['key'] == _plan).firstOrNull;
    return PanelScaffold(
      title: context.tr('Add a business'),
      subtitle: '${context.trf('Step {a} of {b}', {'a': f.intN(_step + 1), 'b': f.intN(steps.length)})} · ${steps[_step]}',
      footer: Row(children: [
        if (_step > 0) TextButton(onPressed: _busy ? null : () => setState(() => _step--), child: Text(context.tr('Back'))) else TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const Spacer(),
        if (_step < 3) FilledButton(onPressed: canNext ? () => setState(() => _step++) : null, child: Text(context.tr('Continue'))) else FilledButton.icon(onPressed: _busy || _type == null || _plan == null ? null : _create, icon: _busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: t.onAccent)) : const Icon(Icons.rocket_launch_rounded, size: 19), label: Text(context.tr('Create business'))),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [for (final (i, _) in steps.indexed) Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: Container(height: 5, decoration: BoxDecoration(color: i <= _step ? t.accent : t.outline, borderRadius: BorderRadius.circular(3)))))]),
        const FormGap(18),
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.error_outline_rounded, size: 19, color: t.danger), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
        if (_step == 0) ...[
          TextField(controller: _name, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Business name'), prefixIcon: const Icon(Icons.storefront_rounded, size: 19))),
          const FormGap(),
          Row(children: [Expanded(child: TextField(controller: _city, decoration: InputDecoration(labelText: context.tr('City / area')))), const SizedBox(width: 12), Expanded(child: TextField(controller: _address, decoration: InputDecoration(labelText: context.tr('Address'))))]),
          const FormHeading('Owner'),
          TextField(controller: _owner, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Owner name'), prefixIcon: const Icon(Icons.person_rounded, size: 19))),
          const FormGap(),
          Row(children: [Expanded(child: TextField(controller: _phone, onChanged: (_) => setState(() {}), keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone (their login)'), hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_rounded, size: 19)))), const SizedBox(width: 12), Expanded(child: TextField(controller: _email, decoration: InputDecoration(labelText: context.tr('Email (optional)'))))]),
          const FormGap(),
          Wrap(spacing: 8, children: [Text('${context.tr('App language')}:', style: tt.titleSmall), ChoiceChip(label: const Text('বাংলা'), selected: _lang == 'bn', onSelected: (_) => setState(() => _lang = 'bn')), ChoiceChip(label: const Text('English'), selected: _lang == 'en', onSelected: (_) => setState(() => _lang = 'en'))]),
        ],
        if (_step == 1) ...[
          Text(context.tr('What kind of business is it?'), style: tt.titleMedium),
          Text(context.tr('This decides which fields, screens and behaviours the business gets — you can fine-tune it later.'), style: tt.bodySmall),
          const FormGap(),
          for (final ty in types)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                onTap: () => setState(() => _type = ty['key'] as String),
                color: _type == ty['key'] ? accentOf((ty['theme'] as Map?)?.cast()).withValues(alpha: 0.1) : t.surface,
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: accentOf((ty['theme'] as Map?)?.cast()), borderRadius: BorderRadius.circular(14)), child: Icon(typeIcon(((ty['theme'] as Map?)?['icon']) as String?), color: Colors.white)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(ty['label'] as String, style: tt.titleMedium), const SizedBox(width: 8), Pill(ty['family'] == 'order_based' ? context.tr('Orders & quotes') : context.tr('Counter sales'), dense: true)]),
                    Text(ty['description'] as String, style: tt.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: [for (final c in (ty['capabilities'] as List).cast<String>().take(7)) Pill(c.replaceAll('_', ' '), dense: true)]),
                  ])),
                  if (_type == ty['key']) Icon(Icons.check_circle_rounded, color: accentOf((ty['theme'] as Map?)?.cast())),
                ]),
              ),
            ),
        ],
        if (_step == 2) ...[
          Row(children: [Expanded(child: Text(context.tr('Choose a plan'), style: tt.titleMedium)), SegTabs<String>(items: [('monthly', context.tr('Monthly')), ('yearly', context.tr('Yearly'))], value: _cycle, onChanged: (v) => setState(() => _cycle = v))]),
          const FormGap(),
          if (plans.isEmpty) const SkeletonList(rows: 3, height: 80),
          for (final p in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                onTap: () => setState(() {
                  _plan = p['key'] as String;
                  _trial = null;
                }),
                color: _plan == p['key'] ? t.accentSoft : t.surface,
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(_plan == p['key'] ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: _plan == p['key'] ? t.accent : t.faint),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['name'] as String, style: tt.titleSmall), Text(p['tagline'] as String, style: tt.bodySmall)])),
                  NumText(f.money(parsePaisa(_cycle == 'yearly' ? p['yearly_price'] : p['monthly_price'])), size: 18, weight: 800),
                  Text(_cycle == 'yearly' ? '/${context.tr('yr')}' : '/${context.tr('mo')}', style: tt.bodySmall),
                ]),
              ),
            ),
          if (chosenPlan != null) ...[
            const FormHeading('Free trial'),
            Wrap(spacing: 8, children: [for (final d in [null, 0, 7, 14, 30]) ChoiceChip(label: Text(d == null ? '${context.tr('Plan default')} (${f.intN(chosenPlan['trial_days'] as int)} ${context.tr('days')})' : (d == 0 ? context.tr('No trial — active now') : '${f.intN(d)} ${context.tr('days')}')), selected: _trial == d, onSelected: (_) => setState(() => _trial = d))]),
          ],
        ],
        if (_step == 3) ...[
          Surface(
            color: t.surface2,
            child: Column(children: [
              KV(context.tr('Business'), _name.text.trim(), mono: false),
              KV(context.tr('Owner'), '${_owner.text.trim()} · ${_phone.text.trim()}', mono: false),
              KV(context.tr('Type'), chosenType?['label'] as String? ?? '—', mono: false),
              KV(context.tr('Plan'), '${chosenPlan?['name'] ?? '—'} · ${context.tr(_cycle)}', mono: false),
            ]),
          ),
          const FormGap(),
          TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: context.tr('Owner password (optional)'), helperText: context.tr('Leave empty to generate one and show it once'), prefixIcon: const Icon(Icons.lock_rounded, size: 19))),
          const FormGap(),
          SwitchRow(title: context.tr('Load sample products'), subtitle: context.tr('A realistic starter catalogue for this type, so the till is not empty on day one'), value: _sample, onChanged: (v) => setState(() => _sample = v)),
        ],
      ]),
    );
  }
}
