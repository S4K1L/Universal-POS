import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/models/context.dart';
import '../../data/providers.dart';
import '../../data/session.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _tab = 'app';

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final tabs = <(String, String)>[
      if (ctx.can('manage_settings')) ('business', context.tr('Business')),
      if (ctx.can('manage_staff') && ctx.feature('staff')) ('staff', context.tr('Staff')),
      if (ctx.can('manage_branches')) ('branches', context.tr('Branches')),
      ('app', context.tr('This device')),
    ];
    if (!tabs.any((x) => x.$1 == _tab)) _tab = tabs.first.$1;
    return PageBody(
      maxWidth: 900,
      child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegTabs<String>(items: tabs, value: _tab, onChanged: (v) => setState(() => _tab = v)))),
        const SizedBox(height: 14),
        Expanded(
          child: switch (_tab) {
            'business' => const _BusinessTab(),
            'staff' => const _StaffTab(),
            'branches' => const _BranchesTab(),
            _ => const _DeviceTab(),
          },
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------------------- business

class _BusinessTab extends ConsumerStatefulWidget {
  const _BusinessTab();

  @override
  ConsumerState<_BusinessTab> createState() => _BusinessTabState();
}

class _BusinessTabState extends ConsumerState<_BusinessTab> {
  late final TenantContext _c = ref.read(ctxProvider);
  late final _name = TextEditingController(text: _c.businessName);
  late final _address = TextEditingController(text: (_c.receipt['address'] as String?) ?? _c.businessAddress);
  late final _phone = TextEditingController(text: (_c.receipt['phone'] as String?) ?? _c.businessPhone);
  late final _vat = TextEditingController(text: (_c.receipt['vat_reg_no'] as String?) ?? '');
  late final _header = TextEditingController(text: (_c.receipt['header'] as String?) ?? '');
  late final _footer = TextEditingController(text: (_c.receipt['footer'] as String?) ?? '');
  late final _points = TextEditingController(text: '${_c.pointsPer100}');
  late final _deposit = TextEditingController(text: '${_c.depositPercentMin}');
  late final _scalePrefix = TextEditingController(text: (_c.scale['prefix'] as String?) ?? '20');
  late String _taxMode = _c.taxMode.name;
  late bool _round = _c.cashRounding;
  late bool _negative = _c.allowNegativeStock;
  late bool _loyalty = _c.loyaltyOn;
  late String _scaleMode = (_c.scale['mode'] as String?) ?? 'weight';
  late final List<PayMethod> _methods = [..._c.paymentMethods];
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(apiProvider).patch('/tenants/me/settings', body: {
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'phone': _phone.text.trim(),
        'vat_reg_no': _vat.text.trim(),
        'receipt_header': _header.text.trim(),
        'receipt_footer': _footer.text.trim(),
        'tax_mode': _taxMode,
        'cash_rounding': _round ? 'nearest_1' : 'none',
        'allow_negative_stock': _negative,
        if (_c.cap('loyalty')) 'loyalty_enabled': _loyalty,
        if (_c.cap('loyalty')) 'loyalty_points_per_100': double.tryParse(_points.text.trim()) ?? 0,
        'payment_methods': [for (final m in _methods) {'code': m.code, 'label': m.label, 'label_bn': m.labelBn, 'kind': m.kind, 'enabled': m.enabled}],
        if (_c.cap('scale_barcode')) 'scale_prefix': _scalePrefix.text.trim(),
        if (_c.cap('scale_barcode')) 'scale_mode': _scaleMode,
        if (_c.cap('document_flow')) 'deposit_percent_min': int.tryParse(_deposit.text.trim()) ?? 0,
      });
      ref.read(sessionProvider.notifier).applyContext(res);
      if (mounted) toast(context, context.tr('Settings saved'), good: true);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.offline ? context.tr('Settings can only be changed while online.') : e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
      Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('Your business'), style: tt.titleLarge),
          const FormGap(),
          TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('Business name'), prefixIcon: const Icon(Icons.storefront_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _address, decoration: InputDecoration(labelText: context.tr('Address (printed on receipts)'), prefixIcon: const Icon(Icons.place_rounded, size: 19))),
          const FormGap(),
          Row(children: [
            Expanded(child: TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone'), prefixIcon: const Icon(Icons.phone_rounded, size: 19)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _vat, decoration: InputDecoration(labelText: context.tr('VAT registration no.'), prefixIcon: const Icon(Icons.badge_rounded, size: 19)))),
          ]),
          const FormGap(),
          TextField(controller: _header, decoration: InputDecoration(labelText: context.tr('Receipt heading (defaults to the name)'))),
          const FormGap(),
          TextField(controller: _footer, decoration: InputDecoration(labelText: context.tr('Receipt footer message'))),
        ]),
      ),
      const SizedBox(height: 14),
      Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('Selling'), style: tt.titleLarge),
          const FormGap(),
          Text(context.tr('How prices include VAT'), style: tt.titleSmall),
          const SizedBox(height: 8),
          SegTabs<String>(items: [('inclusive', context.tr('Price includes VAT')), ('exclusive', context.tr('VAT added on top'))], value: _taxMode, onChanged: (v) => setState(() => _taxMode = v)),
          const FormGap(),
          SwitchRow(title: context.tr('Round the bill to the nearest taka'), subtitle: context.tr('Shows a small rounding line on the receipt'), value: _round, onChanged: (v) => setState(() => _round = v)),
          SwitchRow(title: context.tr('Allow selling below zero stock'), subtitle: context.tr('When off, a till refuses to sell more than it thinks is on the shelf'), value: _negative, onChanged: (v) => setState(() => _negative = v)),
          if (_c.cap('loyalty')) ...[
            SwitchRow(title: context.tr('Loyalty points'), subtitle: context.tr('Customers earn points on what they pay'), value: _loyalty, onChanged: (v) => setState(() => _loyalty = v)),
            if (_loyalty) Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: _points, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Points per ৳100 spent')))),
          ],
          if (_c.cap('document_flow')) Padding(padding: const EdgeInsets.only(top: 6), child: TextField(controller: _deposit, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Minimum deposit to confirm an order (%)'), prefixIcon: const Icon(Icons.percent_rounded, size: 19)))),
          if (_c.cap('scale_barcode')) ...[
            const FormGap(),
            Text(context.tr('Weighing-scale labels'), style: tt.titleSmall),
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(width: 130, child: TextField(controller: _scalePrefix, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Label prefix')))),
              const SizedBox(width: 12),
              Expanded(child: SegTabs<String>(items: [('weight', context.tr('Weight in label')), ('price', context.tr('Price in label'))], value: _scaleMode, onChanged: (v) => setState(() => _scaleMode = v), expand: true)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('Ways customers can pay'), style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(context.tr('Cash always stays on.'), style: tt.bodySmall),
          const FormGap(10),
          for (final (i, m) in _methods.indexed)
            SwitchRow(
              title: m.label,
              subtitle: m.kind == 'mobile' ? context.tr('Mobile wallet') : (m.kind == 'cash' ? context.tr('Cash') : (m.kind == 'card' ? context.tr('Card') : context.tr('Bank transfer'))),
              value: m.enabled,
              enabled: m.code != 'cash',
              onChanged: (v) => setState(() => _methods[i] = PayMethod(m.code, m.label, m.labelBn, m.kind, v)),
            ),
        ]),
      ),
      const SizedBox(height: 18),
      Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _busy ? null : _save, icon: _busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: t.onAccent)) : const Icon(Icons.check_rounded), label: Text(context.tr('Save changes')))),
    ]);
  }
}

// ------------------------------------------------------------------------------------------ staff

final _usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return (await ref.watch(apiProvider).getList('/users')).cast<Map<String, dynamic>>();
});
final _rolesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return ref.watch(apiProvider).getMap('/users/roles');
});
final _branchesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return (await ref.watch(apiProvider).getList('/branches')).cast<Map<String, dynamic>>();
});

class _StaffTab extends ConsumerWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final ctx = ref.watch(ctxProvider);
    final users = ref.watch(_usersProvider);
    final limit = ctx.limits['staff'] ?? -1;
    return Column(children: [
      Row(children: [
        Expanded(child: Text('${context.fmt.intN(ctx.usage['staff'] ?? 0)}${limit >= 0 ? ' / ${context.fmt.intN(limit)}' : ''} ${context.tr('staff accounts')}', style: tt.titleSmall)),
        FilledButton.icon(
          onPressed: () async {
            final r = await showPanel<bool>(context, maxWidth: 560, builder: (_) => const _StaffForm());
            if (r == true) ref.invalidate(_usersProvider);
          },
          icon: const Icon(Icons.person_add_rounded, size: 20),
          label: Text(context.tr('Add staff')),
        ),
      ]),
      const SizedBox(height: 10),
      Expanded(
        child: AsyncBody<List<Map<String, dynamic>>>(
          value: users,
          onRetry: () => ref.invalidate(_usersProvider),
          data: (list) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final u = list[i];
              final active = u['active'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: active ? 1 : 0.55,
                  child: Surface(
                    onTap: () async {
                      final r = await showPanel<bool>(context, maxWidth: 560, builder: (_) => _StaffForm(existing: u));
                      if (r == true) ref.invalidate(_usersProvider);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Monogram(u['name'] as String, size: 44, round: true),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['name'] as String, style: tt.titleSmall), Text(context.fmt.digits(u['phone'] as String), style: tt.bodySmall)])),
                      if (u['permission_overrides'] != null) Padding(padding: const EdgeInsets.only(right: 6), child: Pill(context.tr('Custom access'), color: t.info, dense: true)),
                      if (u['branch_ids'] != null) Padding(padding: const EdgeInsets.only(right: 6), child: Pill(context.tr('One branch'), color: t.muted, dense: true)),
                      Pill(u['role_label'] as String, color: u['role'] == 'owner' ? t.accent : t.muted),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }
}

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm> {
  late final _name = TextEditingController(text: widget.existing?['name'] as String?);
  late final _phone = TextEditingController(text: widget.existing?['phone'] as String?);
  final _password = TextEditingController();
  late String _role = (widget.existing?['role'] as String?) ?? 'cashier';
  late bool _active = widget.existing?['active'] != false;
  late bool _custom = widget.existing?['permission_overrides'] != null;
  late final Set<String> _perms = {...((widget.existing?['permission_overrides'] as List?)?.cast<String>() ?? const <String>[])};
  late Set<String>? _branches = (widget.existing?['branch_ids'] as List?)?.cast<String>().toSet();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      if (widget.existing == null) {
        await api.post('/users', body: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'password': _password.text,
          'role': _role,
          if (_custom) 'permissions': _perms.toList(),
          if (_branches != null && _role != 'owner') 'branch_ids': _branches!.toList(),
        });
      } else {
        await api.patch('/users/${widget.existing!['id']}', body: {
          'name': _name.text.trim(),
          'role': _role,
          'active': _active,
          if (_password.text.isNotEmpty) 'password': _password.text,
          if (_custom) 'permissions': _perms.toList() else 'clear_permissions': true,
          if (_branches != null && _role != 'owner') 'branch_ids': _branches!.toList() else 'clear_branch_restriction': true,
        });
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
    final roles = ref.watch(_rolesProvider).value;
    final branches = ref.watch(_branchesProvider).value ?? const [];
    final ctx = ref.watch(ctxProvider);
    final rolePerms = ((roles?['roles'] as List?)?.cast<Map<String, dynamic>>().where((r) => r['key'] == _role).firstOrNull?['permissions'] as List?)?.cast<String>() ?? const <String>[];
    final allPerms = (roles?['permissions'] as List?)?.cast<String>() ?? const <String>[];
    final isSelf = widget.existing?['id'] == ctx.userId;
    return PanelScaffold(
      title: widget.existing == null ? context.tr('Add staff') : (widget.existing!['name'] as String),
      footer: Row(children: [const Spacer(), TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))), const SizedBox(width: 8), FilledButton(onPressed: _busy ? null : _save, child: Text(context.tr('Save')))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12)), child: Text(_error!)),
        TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('Name'), prefixIcon: const Icon(Icons.person_rounded, size: 19))),
        const FormGap(),
        TextField(controller: _phone, enabled: widget.existing == null, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone (their login)'), prefixIcon: const Icon(Icons.phone_rounded, size: 19))),
        const FormGap(),
        TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: widget.existing == null ? context.tr('Password (min 8 characters)') : context.tr('New password (leave empty to keep)'), prefixIcon: const Icon(Icons.lock_rounded, size: 19))),
        const FormHeading('Role'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final r in (roles?['roles'] as List? ?? const []).cast<Map<String, dynamic>>()) ChoiceChip(label: Text(r['label'] as String), selected: _role == r['key'], onSelected: (_) => setState(() => _role = r['key'] as String))]),
        const FormHeading('Access', hint: 'Start from the role, then fine-tune what this person can do.'),
        SwitchRow(title: context.tr('Customise access'), subtitle: _custom ? context.tr('Only the ticked permissions apply') : context.tr('Uses the role defaults'), value: _custom, onChanged: (v) => setState(() {
              _custom = v;
              if (v && _perms.isEmpty) _perms.addAll(rolePerms.where(allPerms.contains));
            })),
        if (_custom)
          Wrap(spacing: 8, runSpacing: 4, children: [for (final p in allPerms) FilterChip(label: Text(p.replaceAll('_', ' ')), selected: _perms.contains(p), onSelected: (on) => setState(() => on ? _perms.add(p) : _perms.remove(p)))]),
        if (branches.length > 1 && _role != 'owner') ...[
          const FormHeading('Branches'),
          SwitchRow(title: context.tr('Limit to specific branches'), subtitle: context.tr('They only see sales and stock of these'), value: _branches != null, onChanged: (v) => setState(() => _branches = v ? {branches.first['id'] as String} : null)),
          if (_branches != null) Wrap(spacing: 8, children: [for (final b in branches) FilterChip(label: Text(b['name'] as String), selected: _branches!.contains(b['id']), onSelected: (on) => setState(() => on ? _branches!.add(b['id'] as String) : _branches!.remove(b['id'])))]),
        ],
        if (widget.existing != null && !isSelf) ...[const FormGap(), SwitchRow(title: context.tr('Account active'), subtitle: context.tr('Turn off to stop them signing in'), value: _active, onChanged: (v) => setState(() => _active = v))],
      ]),
    );
  }
}

// -------------------------------------------------------------------------------------- branches

class _BranchesTab extends ConsumerWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final t = context.t;
    final ctx = ref.watch(ctxProvider);
    final branches = ref.watch(_branchesProvider);
    final limit = ctx.limits['branches'] ?? -1;
    return Column(children: [
      Row(children: [
        Expanded(child: Text('${context.fmt.intN(ctx.usage['branches'] ?? 0)}${limit >= 0 ? ' / ${context.fmt.intN(limit)}' : ''} ${context.tr('branches')}', style: tt.titleSmall)),
        FilledButton.icon(
          onPressed: () async {
            if (!ctx.feature('multi_branch')) {
              toast(context, context.tr('Your plan has a single branch. Upgrade to add more.'), error: true);
              return;
            }
            final r = await showPanel<bool>(context, maxWidth: 460, builder: (_) => const _BranchForm());
            if (r == true) ref.invalidate(_branchesProvider);
          },
          icon: Icon(ctx.feature('multi_branch') ? Icons.add_business_rounded : Icons.lock_rounded, size: 20),
          label: Text(context.tr('Add branch')),
        ),
      ]),
      const SizedBox(height: 10),
      Expanded(
        child: AsyncBody<List<Map<String, dynamic>>>(
          value: branches,
          onRetry: () => ref.invalidate(_branchesProvider),
          data: (list) => ListView(children: [
            for (final b in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Surface(
                  onTap: () async {
                    final r = await showPanel<bool>(context, maxWidth: 460, builder: (_) => _BranchForm(existing: b));
                    if (r == true) ref.invalidate(_branchesProvider);
                  },
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const IconSquare(Icons.storefront_rounded, size: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b['name'] as String, style: tt.titleSmall), if ((b['address'] as String).isNotEmpty) Text(b['address'] as String, style: tt.bodySmall)])),
                    if (b['is_main'] == true) Pill(context.tr('Main'), color: t.accent, dense: true),
                    if (b['active'] != true) Pill(context.tr('Closed'), color: t.faint, dense: true),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }
}

class _BranchForm extends ConsumerStatefulWidget {
  const _BranchForm({this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends ConsumerState<_BranchForm> {
  late final _name = TextEditingController(text: widget.existing?['name'] as String?);
  late final _address = TextEditingController(text: widget.existing?['address'] as String?);
  late final _phone = TextEditingController(text: widget.existing?['phone'] as String?);
  late final _manager = TextEditingController(text: widget.existing?['manager_name'] as String?);
  late bool _active = widget.existing?['active'] != false;

  @override
  Widget build(BuildContext context) => PanelScaffold(
        title: widget.existing == null ? context.tr('Add branch') : (widget.existing!['name'] as String),
        footer: FilledButton(
          onPressed: () async {
            final body = {'name': _name.text.trim(), 'address': _address.text.trim(), 'phone': _phone.text.trim(), 'manager_name': _manager.text.trim(), 'active': _active};
            try {
              if (widget.existing == null) {
                await ref.read(apiProvider).post('/branches', body: body);
              } else {
                await ref.read(apiProvider).patch('/branches/${widget.existing!['id']}', body: body);
              }
              await ref.read(sessionProvider.notifier).refreshContext();
              if (context.mounted) Navigator.pop(context, true);
            } on ApiError catch (e) {
              if (context.mounted) toast(context, e.message, error: true);
            }
          },
          child: Text(context.tr('Save')),
        ),
        child: Column(children: [
          TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('Branch name'), prefixIcon: const Icon(Icons.storefront_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _address, decoration: InputDecoration(labelText: context.tr('Address'), prefixIcon: const Icon(Icons.place_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone'), prefixIcon: const Icon(Icons.phone_rounded, size: 19))),
          const FormGap(),
          TextField(controller: _manager, decoration: InputDecoration(labelText: context.tr('Manager'), prefixIcon: const Icon(Icons.badge_rounded, size: 19))),
          if (widget.existing != null && widget.existing!['is_main'] != true) ...[const FormGap(), SwitchRow(title: context.tr('Open'), value: _active, onChanged: (v) => setState(() => _active = v))],
        ]),
      );
}

// ----------------------------------------------------------------------------------- this device

class _DeviceTab extends ConsumerWidget {
  const _DeviceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final ctx = ref.watch(ctxProvider);
    final lang = ref.watch(langProvider);
    final mode = ref.watch(themeModeProvider);
    return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
      Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('Appearance'), style: tt.titleLarge),
          const FormGap(),
          Text(context.tr('Language'), style: tt.titleSmall),
          const SizedBox(height: 8),
          SegTabs<AppLang>(items: const [(AppLang.en, 'English'), (AppLang.bn, 'বাংলা')], value: lang, onChanged: (l) => ref.read(langProvider.notifier).set(l)),
          const FormGap(),
          Text(context.tr('Theme'), style: tt.titleSmall),
          const SizedBox(height: 8),
          SegTabs<ThemeMode>(items: [(ThemeMode.system, context.tr('Auto')), (ThemeMode.light, context.tr('Light')), (ThemeMode.dark, context.tr('Dark'))], value: mode, onChanged: (m) => ref.read(themeModeProvider.notifier).set(m)),
        ]),
      ),
      const SizedBox(height: 14),
      Surface(
        child: Column(children: [
          KV(context.tr('Business'), ctx.businessName, mono: false),
          KV(context.tr('Type'), ctx.typeLabel, mono: false),
          KV(context.tr('Signed in as'), '${ctx.userName} · ${ctx.roleLabel}', mono: false),
          KV(context.tr('Plan'), '${ctx.planName} · ${context.tr(ctx.subState)}', mono: false),
          KV(context.tr('Server'), Uri.parse(ref.watch(serverUrlProvider)).authority, mono: false),
          const KV('Version', '1.0.0', mono: false),
        ]),
      ),
      const SizedBox(height: 14),
      Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('What your business type switched on'), style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(context.tr('Capabilities decide which screens and fields you see.'), style: tt.bodySmall),
          const FormGap(10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in (ctx.raw['capability_catalogue'] as Map).entries) Pill((c.value as Map)['label'] as String, color: t.accent)]),
        ]),
      ),
    ]);
  }
}
