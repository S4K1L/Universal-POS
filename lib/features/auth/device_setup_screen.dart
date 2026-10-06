import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';

/// First launch on a till: give it a name and a branch. The server answers with a short code that prefixes
/// every invoice number this device issues — that is what lets it sell offline without ever clashing with
/// another till.
class DeviceSetupScreen extends ConsumerStatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  ConsumerState<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends ConsumerState<DeviceSetupScreen> {
  late final _name = TextEditingController(text: _defaultName());
  String? _branchId;
  bool _busy = false;
  String? _error;

  String _defaultName() {
    if (kIsWeb) return 'Web till';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android till',
      TargetPlatform.windows => 'Windows till',
      TargetPlatform.macOS => 'Mac till',
      _ => 'Counter 1',
    };
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final ctx = ref.read(sessionProvider).ctx!;
    final branch = _branchId ?? ctx.branches.first.id;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).registerDevice(name: _name.text.trim().isEmpty ? 'Counter' : _name.text.trim(), branchId: branch);
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
    final session = ref.watch(sessionProvider);
    final ctx = session.ctx;
    if (ctx == null) return const SizedBox.shrink();
    final canRegister = ctx.can('manage_devices');
    final branches = ctx.branches;
    _branchId ??= branches.isEmpty ? null : branches.first.id;
    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [BrandMark(size: 46, color: ctx.accent), const SizedBox(width: 12), const BrandWordmark(size: 22)]),
                const SizedBox(height: 28),
                Text(context.tr('Set up this till'), style: tt.displaySmall),
                const SizedBox(height: 6),
                Text('${ctx.businessName} · ${ctx.typeLabel}', style: tt.bodyLarge!.copyWith(color: t.muted)),
                const SizedBox(height: 22),
                Surface(
                  color: t.accentSoft,
                  border: false,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.cloud_off_rounded, color: t.accentDeep),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('A registered till can keep selling with no internet. Its invoices are numbered with its own code, and everything syncs automatically when the connection returns.'),
                        style: tt.bodyMedium,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 22),
                if (!canRegister)
                  Surface(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Icon(Icons.lock_person_rounded, color: t.warning), const SizedBox(width: 10), Text(context.tr('A manager needs to set this up'), style: tt.titleMedium)]),
                      const SizedBox(height: 8),
                      Text(context.tr('Ask an owner or manager to sign in on this device once. After that, everyone can use it.'), style: tt.bodyMedium),
                    ]),
                  )
                else ...[
                  TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('Till name'), prefixIcon: const Icon(Icons.point_of_sale_rounded, size: 20))),
                  const SizedBox(height: 16),
                  Text(context.tr('Which branch is this till in?'), style: tt.titleSmall),
                  const SizedBox(height: 8),
                  for (final b in branches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Surface(
                        onTap: () => setState(() => _branchId = b.id),
                        color: _branchId == b.id ? t.accentSoft : t.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Icon(_branchId == b.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: _branchId == b.id ? t.accent : t.faint),
                          const SizedBox(width: 12),
                          Expanded(child: Text(b.name, style: tt.titleSmall)),
                          if (b.isMain) Pill(context.tr('Main'), color: t.accent, dense: true),
                        ]),
                      ),
                    ),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: tt.bodyMedium!.copyWith(color: t.danger))),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _register,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      icon: _busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : const Icon(Icons.check_rounded),
                      label: Text(context.tr('Register this till')),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Center(child: TextButton(onPressed: () => ref.read(sessionProvider.notifier).logout(), child: Text(context.tr('Sign out')))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
