import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../core/util/responsive.dart';
import '../../data/providers.dart';
import '../../data/session.dart';

const _demo = bool.fromEnvironment('DEMO');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _passFocus = FocusNode();
  bool _busy = false, _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final phone = _phone.text.trim(), pass = _pass.text;
    if (phone.isEmpty || pass.isEmpty) {
      setState(() => _error = context.tr('Enter your phone number and password.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(phone, pass);
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _error = e.offline ? context.tr('No connection to the server. The first sign-in on a device needs the internet.') : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final wide = context.width >= 900;
    final message = ref.watch(sessionProvider.select((s) => s.message));
    final form = _Form(
      phone: _phone,
      pass: _pass,
      passFocus: _passFocus,
      busy: _busy,
      obscure: _obscure,
      error: _error ?? message,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onSubmit: _submit,
      onDemo: (phone, pw) {
        _phone.text = phone;
        _pass.text = pw;
        _submit();
      },
    );
    return Scaffold(
      backgroundColor: t.canvas,
      body: wide
          ? Row(children: [
              const Expanded(flex: 11, child: _BrandPanel()),
              Expanded(flex: 9, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: form)))),
            ])
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(children: [
                      const BrandMark(size: 58),
                      const SizedBox(height: 14),
                      const BrandWordmark(size: 24),
                      const SizedBox(height: 28),
                      form,
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    const types = [
      (Icons.shopping_basket_rounded, 'Supershop', Color(0xFF0E9F6E)),
      (Icons.store_rounded, 'Local shop', Color(0xFFE8A200)),
      (Icons.spa_rounded, 'Cosmetics', Color(0xFFD6336C)),
      (Icons.chair_rounded, 'Furniture', Color(0xFFB5651D)),
      (Icons.medication_rounded, 'Pharmacy', Color(0xFF0891B2)),
    ];
    return Container(
      margin: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: t.ink,
        gradient: const RadialGradient(center: Alignment(-0.7, -0.8), radius: 1.3, colors: [Color(0xFF14352A), Color(0xFF0A1310)]),
      ),
      child: Stack(children: [
        Positioned(right: -90, bottom: -90, child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent.withValues(alpha: 0.10)))),
        Positioned(right: 60, bottom: 110, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.accent.withValues(alpha: 0.25), width: 1.5)))),
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [BrandMark(size: 46), SizedBox(width: 14), BrandWordmark(size: 26, onInk: true)]),
            const Spacer(),
            Text(context.tr('One POS.\nEvery kind of shop.'), style: tt.displayLarge!.copyWith(color: t.onInk, height: 1.05)),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                context.tr('Sell at the counter, in the showroom or at the weighing scale — even when the internet is down. Every sale syncs on its own the moment you are back online.'),
                style: tt.bodyLarge!.copyWith(color: t.onInkMuted, height: 1.55),
              ),
            ),
            const SizedBox(height: 30),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final (icon, label, c) in types)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 26, height: 26, decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Icon(icon, size: 15, color: Colors.white)),
                    const SizedBox(width: 9),
                    Text(context.tr(label), style: TextStyle(color: t.onInk, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
            ]),
            const SizedBox(height: 34),
            Row(children: [
              for (final (icon, text) in [(Icons.cloud_off_rounded, 'Works offline'), (Icons.phone_android_rounded, 'bKash · Nagad'), (Icons.translate_rounded, 'বাংলা + English')]) ...[
                Icon(icon, size: 16, color: t.accent),
                const SizedBox(width: 7),
                Text(context.tr(text), style: TextStyle(color: t.onInkMuted, fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(width: 22),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.phone, required this.pass, required this.passFocus, required this.busy, required this.obscure, required this.error, required this.onToggleObscure, required this.onSubmit, required this.onDemo});
  final TextEditingController phone, pass;
  final FocusNode passFocus;
  final bool busy, obscure;
  final String? error;
  final VoidCallback onToggleObscure, onSubmit;
  final void Function(String phone, String password) onDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final lang = ref.watch(langProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(context.tr('Welcome back'), style: tt.displaySmall)),
        SegTabs<AppLang>(items: const [(AppLang.en, 'EN'), (AppLang.bn, 'বাংলা')], value: lang, onChanged: (l) => ref.read(langProvider.notifier).set(l)),
      ]),
      const SizedBox(height: 6),
      Text(context.tr('Sign in with your phone number to open the till.'), style: tt.bodyMedium!.copyWith(color: t.muted)),
      const SizedBox(height: 26),
      TextField(
        controller: phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
        onSubmitted: (_) => passFocus.requestFocus(),
        decoration: InputDecoration(labelText: context.tr('Phone number'), hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_rounded, size: 20)),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: pass,
        focusNode: passFocus,
        obscureText: obscure,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          labelText: context.tr('Password'),
          prefixIcon: const Icon(Icons.lock_rounded, size: 20),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20), onPressed: onToggleObscure),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: t.danger.withValues(alpha: 0.3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.error_outline_rounded, size: 19, color: t.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(error!, style: tt.bodyMedium)),
          ]),
        ),
      ],
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onSubmit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: busy ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: t.onAccent)) : Text(context.tr('Sign in')),
        ),
      ),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton.icon(
          onPressed: () => _server(context, ref),
          icon: const Icon(Icons.dns_rounded, size: 17),
          label: Text(Uri.parse(ref.watch(serverUrlProvider)).authority),
          style: TextButton.styleFrom(foregroundColor: t.muted, textStyle: tt.labelMedium),
        ),
      ]),
      if (_demo) ...[
        const SizedBox(height: 18),
        Text(context.tr('TRY A DEMO SHOP'), style: tt.labelSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (name, phone, icon, c) in _demoShops)
            ActionChip(
              avatar: Icon(icon, size: 16, color: c),
              label: Text(context.tr(name)),
              onPressed: busy ? null : () => onDemo(phone, phone == '01700000000' ? 'admin12345' : 'demo12345'),
            ),
        ]),
      ],
    ]);
  }

  Future<void> _server(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: ref.read(serverUrlProvider));
    await showPanel<void>(
      context,
      maxWidth: 460,
      builder: (ctx) => PanelScaffold(
        title: context.tr('Server address'),
        subtitle: context.tr('Where this app finds your Universal POS server.'),
        footer: Row(children: [
          TextButton(onPressed: () => c.text = ServerConfig.fallback, child: Text(context.tr('Reset'))),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              var v = c.text.trim();
              if (v.isEmpty) return;
              if (!v.startsWith('http')) v = 'http://$v';
              if (!v.contains('/api/')) v = '${v.replaceAll(RegExp(r'/+$'), '')}/api/v1';
              await ref.read(serverUrlProvider.notifier).set(v);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(context.tr('Save')),
          ),
        ]),
        child: TextField(controller: c, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'http://192.168.0.10:8000/api/v1', prefixIcon: Icon(Icons.dns_rounded))),
      ),
    );
  }
}

const _demoShops = <(String, String, IconData, Color)>[
  ('Supershop', '01722000001', Icons.shopping_basket_rounded, Color(0xFF0E9F6E)),
  ('Local shop', '01711000001', Icons.store_rounded, Color(0xFFE8A200)),
  ('Cosmetics', '01733000001', Icons.spa_rounded, Color(0xFFD6336C)),
  ('Furniture', '01744000001', Icons.chair_rounded, Color(0xFFB5651D)),
  ('Pharmacy', '01755000001', Icons.medication_rounded, Color(0xFF0891B2)),
  ('Platform admin', '01700000000', Icons.admin_panel_settings_rounded, Color(0xFF6D28D9)),
];
