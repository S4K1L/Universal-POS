import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';

final _platformSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheForSession(revalidate: true);
  return ref.watch(apiProvider).getMap('/admin/settings');
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
