import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/kit.dart';
import '../../data/providers.dart';
import '../../data/session.dart';
import '../admin/admin_businesses_screen.dart' show accentOf, typeIcon;
import 'auth_frame.dart';
import 'signup_state.dart';

final _bdPhone = RegExp(r'^01[3-9]\d{8}$');

String _normalisePhone(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('880') && d.length == 13) d = '0${d.substring(3)}';
  return d;
}

/// Two steps: who you are (phone and password), then what you run (business name and type). Nothing is created yet —
/// the request goes to the platform owner, who approves it and assigns a package.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  int _step = 0;
  bool _forward = true, _tried0 = false, _tried1 = false, _busy = false, _obscure = true;
  String? _typeKey, _typeLabel, _error;

  @override
  void initState() {
    super.initState();
    // Coming back from "edit and try again": keep what was typed.
    final p = ref.read(pendingSignupProvider);
    if (p != null) {
      _phone.text = p.phone;
      _name.text = p.businessName;
    }
  }

  @override
  void dispose() {
    for (final c in [_phone, _pass, _confirm, _name]) {
      c.dispose();
    }
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? get _phoneError => _bdPhone.hasMatch(_normalisePhone(_phone.text)) ? null : context.tr('Enter a Bangladesh mobile number like 01712345678');
  String? get _passError => _pass.text.length >= 8 ? null : context.tr('Use at least 8 characters.');
  String? get _confirmError => _confirm.text == _pass.text && _confirm.text.isNotEmpty ? null : context.tr('The two passwords do not match.');
  String? get _nameError => _name.text.trim().length >= 2 ? null : context.tr('Enter your business name.');

  void _next() {
    setState(() => _tried0 = true);
    if (_phoneError != null || _passError != null || _confirmError != null) return;
    setState(() {
      _forward = true;
      _step = 1;
      _error = null;
    });
  }

  void _back() => setState(() {
        _forward = false;
        _step = 0;
        _error = null;
      });

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _tried1 = true);
    if (_nameError != null || _typeKey == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone = _normalisePhone(_phone.text);
    try {
      await ref.read(apiProvider).post('/auth/signup', noAuth: true, body: {
        'phone': phone,
        'password': _pass.text,
        'business_name': _name.text.trim(),
        'business_type_key': _typeKey,
        'language': ref.read(langProvider).name,
      });
      ref.read(pendingSignupProvider.notifier).set(PendingSignup(phone: phone, password: _pass.text, businessName: _name.text.trim(), typeLabel: _typeLabel ?? ''));
      if (mounted) context.go('/signup/pending');
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.offline ? context.tr('No connection to the server. Signing up needs the internet.') : e.message;
        if (e.code == 'phone_taken') {
          _forward = false;
          _step = 0;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final lang = ref.watch(langProvider);
    final reduced = Motion.reduced(context);
    return AuthFrame(
      maxWidth: 480,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(context.tr('Create your account'), style: tt.displaySmall)),
          SegTabs<AppLang>(items: const [(AppLang.en, 'EN'), (AppLang.bn, 'বাংলা')], value: lang, onChanged: (l) => ref.read(langProvider.notifier).set(l)),
        ]),
        const SizedBox(height: 6),
        Text(context.tr('Tell us about you and your shop. We review every request before opening an account.'), style: tt.bodyMedium!.copyWith(color: t.muted)),
        const SizedBox(height: 22),
        _Stepper(step: _step, labels: [context.tr('Your account'), context.tr('Your business')]),
        const SizedBox(height: 22),
        AnimatedSize(
          duration: reduced ? Duration.zero : Motion.base,
          curve: Motion.settle,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: reduced ? Duration.zero : Motion.slow,
            switchInCurve: Motion.settle,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, anim) {
              // the incoming page slides in from the side we are travelling towards; the outgoing one fades away
              final incoming = child.key == ValueKey(_step);
              final dx = (incoming ? 1 : -1) * (_forward ? 0.12 : -0.12);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(anim), child: child),
              );
            },
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
            child: KeyedSubtree(key: ValueKey(_step), child: _step == 0 ? _accountStep(context) : _businessStep(context)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: t.tint(t.danger, 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: t.danger.withValues(alpha: 0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.error_outline_rounded, size: 19, color: t.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(_error!, style: tt.bodyMedium)),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          if (_step == 1) ...[
            OutlinedButton.icon(onPressed: _busy ? null : _back, icon: const Icon(Icons.arrow_back_rounded, size: 18), label: Text(context.tr('Back')), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54))),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: _busy ? null : (_step == 0 ? _next : _submit),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: _busy
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: t.onAccent))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_step == 0 ? context.tr('Continue') : context.tr('Send for approval')),
                      const SizedBox(width: 8),
                      Icon(_step == 0 ? Icons.arrow_forward_rounded : Icons.send_rounded, size: 18),
                    ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Center(
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(context.tr('Already have an account?'), style: tt.bodyMedium!.copyWith(color: t.muted)),
            TextButton(onPressed: _busy ? null : () => context.go('/login'), child: Text(context.tr('Sign in'))),
          ]),
        ),
      ]),
    );
  }

  Widget _accountStep(BuildContext context) {
    return Column(children: [
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _passFocus.requestFocus(),
        decoration: InputDecoration(labelText: context.tr('Phone number'), hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_rounded, size: 20), errorText: _tried0 ? _phoneError : null),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _pass,
        focusNode: _passFocus,
        obscureText: _obscure,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _confirmFocus.requestFocus(),
        decoration: InputDecoration(
          labelText: context.tr('Password'),
          helperText: context.tr('At least 8 characters'),
          prefixIcon: const Icon(Icons.lock_rounded, size: 20),
          errorText: _tried0 ? _passError : null,
          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _confirm,
        focusNode: _confirmFocus,
        obscureText: _obscure,
        autofillHints: const [AutofillHints.newPassword],
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _next(),
        decoration: InputDecoration(labelText: context.tr('Confirm password'), prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20), errorText: _tried0 ? _confirmError : null),
      ),
    ]);
  }

  Widget _businessStep(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final types = ref.watch(publicBusinessTypesProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _name,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: context.tr('Business name'), prefixIcon: const Icon(Icons.storefront_rounded, size: 20), errorText: _tried1 ? _nameError : null),
      ),
      const SizedBox(height: 18),
      Text(context.tr('What kind of business is it?'), style: tt.titleSmall),
      const SizedBox(height: 4),
      Text(context.tr('This decides which fields, screens and behaviours the business gets — you can fine-tune it later.'), style: tt.bodySmall),
      const SizedBox(height: 12),
      types.when(
        loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6)))),
        error: (e, _) => Surface(
          child: Row(children: [
            Icon(Icons.cloud_off_rounded, color: t.warning),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr('Could not load the business types. Check the connection and try again.'), style: tt.bodyMedium)),
            TextButton(onPressed: () => ref.invalidate(publicBusinessTypesProvider), child: Text(context.tr('Retry'))),
          ]),
        ),
        data: (list) => Column(children: [
          for (final (i, ty) in list.indexed)
            Reveal(
              delay: Reveal.stagger(i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TypeTile(
                  label: ty['label'] as String,
                  description: (ty['description'] as String?) ?? '',
                  icon: typeIcon(((ty['theme'] as Map?)?['icon']) as String?),
                  color: accentOf((ty['theme'] as Map?)?.cast<String, dynamic>()),
                  selected: _typeKey == ty['key'],
                  onTap: () => setState(() {
                    _typeKey = ty['key'] as String;
                    _typeLabel = ty['label'] as String;
                  }),
                ),
              ),
            ),
          if (_tried1 && _typeKey == null) Align(alignment: Alignment.centerLeft, child: Text(context.tr('Choose a business type.'), style: tt.bodySmall!.copyWith(color: t.danger))),
        ]),
      ),
    ]);
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.label, required this.description, required this.icon, required this.color, required this.selected, required this.onTap});
  final String label, description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.settle,
        decoration: BoxDecoration(
          color: selected ? t.accentSoft : t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? t.accent : t.outline, width: selected ? 2 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: Motion.base,
                  curve: Curves.easeOutBack,
                  child: Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Colors.white, size: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: tt.titleSmall),
                    if (description.isNotEmpty) Text(description, style: tt.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: Motion.fast,
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: selected ? Icon(Icons.check_circle_rounded, key: const ValueKey('on'), color: t.accent) : Icon(Icons.circle_outlined, key: const ValueKey('off'), color: t.faint),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// "1 Your account ——— 2 Your business": the connecting line fills as you move on.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    Widget dot(int i) {
      final done = step > i, current = step == i;
      return AnimatedContainer(
        duration: Motion.base,
        curve: Motion.settle,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done || current ? t.accent : t.surface2,
          border: Border.all(color: done || current ? t.accent : t.outline),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: Motion.fast,
            child: done
                ? Icon(Icons.check_rounded, key: const ValueKey('done'), size: 18, color: t.onAccent)
                : Text('${i + 1}', key: ValueKey('n$i'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: current ? t.onAccent : t.muted)),
          ),
        ),
      );
    }

    Widget label(int i) => Text(labels[i], style: Theme.of(context).textTheme.labelMedium!.copyWith(color: step >= i ? t.text : t.muted, fontWeight: FontWeight.w700));

    return Row(children: [
      dot(0),
      const SizedBox(width: 8),
      label(0),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: step >= 1 ? 1 : 0),
            duration: Motion.slow,
            curve: Motion.settle,
            builder: (_, v, __) => ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: t.outline, color: t.accent)),
          ),
        ),
      ),
      label(1),
      const SizedBox(width: 8),
      dot(1),
    ]);
  }
}
