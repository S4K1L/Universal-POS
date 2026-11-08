import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/session.dart';
import 'admin_users_screen.dart' show UserRow;

final _platformSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return ref.watch(apiProvider).getMap('/admin/settings');
});

final _adminsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return (await ref.watch(apiProvider).getList('/admin/admins')).cast<Map<String, dynamic>>();
});

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _grace = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _whatsapp = TextEditingController();
  final _message = TextEditingController();
  bool _maintenance = false, _loaded = false;

  void _fill(Map<String, dynamic> d) {
    if (_loaded) return;
    _loaded = true;
    _grace.text = '${(d['grace_days'] as Map)['days'] ?? 3}';
    final s = (d['support'] as Map).cast<String, dynamic>();
    _phone.text = (s['phone'] as String?) ?? '';
    _email.text = (s['email'] as String?) ?? '';
    _whatsapp.text = (s['whatsapp'] as String?) ?? '';
    final m = (d['maintenance'] as Map).cast<String, dynamic>();
    _maintenance = m['enabled'] == true;
    _message.text = (m['message'] as String?) ?? '';
  }

  Future<void> _put(String key, Map<String, dynamic> body, String done) async {
    try {
      await ref.read(apiProvider).put('/admin/settings/$key', body: body);
      if (mounted) toast(context, done, good: true);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _addAdmin() async {
    final added = await showPanel<bool>(context, maxWidth: 460, builder: (_) => const _AddAdminPanel());
    if (added == true) {
      ref.invalidate(_adminsProvider);
      if (mounted) toast(context, context.tr('Admin added — they can sign in now'), good: true);
    }
  }

  Future<void> _removeAdmin(Map<String, dynamic> a) async {
    final ok = await confirmDialog(
      context,
      title: context.tr('Remove this admin?'),
      message: context.trf('{name} is signed out straight away and can no longer use the console. Their past actions stay in the audit log.', {'name': a['name']}),
      confirm: context.tr('Remove'),
      danger: true,
    );
    if (!ok) return;
    try {
      await ref.read(apiProvider).delete('/admin/admins/${a['id']}');
      ref.invalidate(_adminsProvider);
      if (mounted) toast(context, context.tr('Admin removed'));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Widget _adminsCard(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final me = ref.watch(sessionProvider).user?['id'];
    final admins = ref.watch(_adminsProvider);
    return Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(context.tr('Platform admins'), style: tt.titleLarge)),
          FilledButton.icon(onPressed: _addAdmin, icon: const Icon(Icons.person_add_alt_1_rounded, size: 19), label: Text(context.tr('Add admin'))),
        ]),
        const SizedBox(height: 4),
        Text(context.tr('People who can run this console: approve businesses, set prices and manage other admins.'), style: tt.bodySmall),
        const SizedBox(height: 12),
        admins.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4)))),
          error: (e, _) => Row(children: [
            Expanded(child: Text(e is ApiError ? e.message : '$e', style: tt.bodyMedium!.copyWith(color: t.danger))),
            TextButton(onPressed: () => ref.invalidate(_adminsProvider), child: Text(context.tr('Retry'))),
          ]),
          data: (list) => Column(children: [
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: UserRow(
                  user: a,
                  trailing: a['id'] == me
                      ? Pill(context.tr('You'), color: t.accent, dense: true)
                      : (a['active'] == true ? IconButton(tooltip: context.tr('Remove'), icon: Icon(Icons.person_remove_rounded, color: t.danger), onPressed: () => _removeAdmin(a)) : null),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final data = ref.watch(_platformSettingsProvider);
    return PageBody(
      maxWidth: 760,
      child: AsyncBody<Map<String, dynamic>>(
        value: data,
        onRetry: () => ref.invalidate(_platformSettingsProvider),
        data: (d) {
          _fill(d);
          return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
            _adminsCard(context),
            const SizedBox(height: 14),
            Surface(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('Grace period'), style: tt.titleLarge),
                const SizedBox(height: 4),
                Text(context.tr('How many days a business can keep selling after its subscription ends before the till locks.'), style: tt.bodySmall),
                const FormGap(),
                Row(children: [SizedBox(width: 140, child: TextField(controller: _grace, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('Days'), suffixText: context.tr('days')))), const SizedBox(width: 12), FilledButton(onPressed: () => _put('grace_days', {'days': int.tryParse(_grace.text.trim()) ?? 3}, context.tr('Grace period saved')), child: Text(context.tr('Save')))]),
              ]),
            ),
            const SizedBox(height: 14),
            Surface(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('Support contacts'), style: tt.titleLarge),
                const SizedBox(height: 4),
                Text(context.tr('Shown to businesses when something needs your help.'), style: tt.bodySmall),
                const FormGap(),
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone'), prefixIcon: const Icon(Icons.phone_rounded, size: 19))),
                const FormGap(),
                TextField(controller: _whatsapp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp', prefixIcon: Icon(Icons.chat_rounded, size: 19))),
                const FormGap(),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.tr('Email'), prefixIcon: const Icon(Icons.email_rounded, size: 19))),
                const FormGap(),
                Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => _put('support', {'phone': _phone.text.trim(), 'email': _email.text.trim(), 'whatsapp': _whatsapp.text.trim()}, context.tr('Support contacts saved')), child: Text(context.tr('Save')))),
              ]),
            ),
            const SizedBox(height: 14),
            Surface(
              color: _maintenance ? t.tint(t.danger, 0.07) : t.surface,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('Maintenance mode'), style: tt.titleLarge),
                const SizedBox(height: 4),
                Text(context.tr('Turns every business’s online features off with a message. Tills keep selling offline and sync afterwards.'), style: tt.bodySmall),
                const FormGap(),
                SwitchRow(title: context.tr('Maintenance on'), value: _maintenance, onChanged: (v) => setState(() => _maintenance = v)),
                TextField(controller: _message, decoration: InputDecoration(labelText: context.tr('Message shown to users'), hintText: context.tr('Upgrading — back at 3pm'))),
                const FormGap(),
                Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => _put('maintenance', {'enabled': _maintenance, 'message': _message.text.trim()}, _maintenance ? context.tr('Maintenance mode is ON') : context.tr('Maintenance mode is off')), style: FilledButton.styleFrom(backgroundColor: _maintenance ? t.danger : t.accent), child: Text(context.tr('Apply')))),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _AddAdminPanel extends ConsumerStatefulWidget {
  const _AddAdminPanel();

  @override
  ConsumerState<_AddAdminPanel> createState() => _AddAdminPanelState();
}

class _AddAdminPanelState extends ConsumerState<_AddAdminPanel> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false, _obscure = true, _tried = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  String? get _nameError => _name.text.trim().length >= 2 ? null : context.tr('Enter their name.');
  String? get _phoneError => RegExp(r'^01[3-9]\d{8}$').hasMatch(_phone.text.replaceAll(RegExp(r'[^0-9]'), '')) ? null : context.tr('Enter a Bangladesh mobile number like 01712345678');
  String? get _passError => _pass.text.length >= 8 ? null : context.tr('Use at least 8 characters.');

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (_nameError != null || _phoneError != null || _passError != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).post('/admin/admins', body: {'name': _name.text.trim(), 'phone': _phone.text.replaceAll(RegExp(r'[^0-9]'), ''), 'password': _pass.text});
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
    return PanelScaffold(
      title: context.tr('Add admin'),
      subtitle: context.tr('They sign in with this phone number and password.'),
      footer: Row(children: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const Spacer(),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : const Icon(Icons.person_add_alt_1_rounded, size: 19),
          label: Text(context.tr('Add admin')),
        ),
      ]),
      child: Column(children: [
        TextField(controller: _name, autofocus: true, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Name'), prefixIcon: const Icon(Icons.badge_rounded, size: 19), errorText: _tried ? _nameError : null)),
        const FormGap(),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: context.tr('Phone number'), hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_rounded, size: 19), errorText: _tried ? _phoneError : null),
        ),
        const FormGap(),
        TextField(
          controller: _pass,
          obscureText: _obscure,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.tr('Password'),
            helperText: context.tr('At least 8 characters'),
            prefixIcon: const Icon(Icons.lock_rounded, size: 19),
            errorText: _tried ? _passError : null,
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 12), Align(alignment: Alignment.centerLeft, child: Text(_error!, style: tt.bodyMedium!.copyWith(color: t.danger)))],
      ]),
    );
  }
}
