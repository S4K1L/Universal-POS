import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';
import 'auth_frame.dart';
import 'signup_state.dart';

/// Shown after "Send for approval" — and whenever someone signs in while their request is still open.
/// It asks the server every few seconds and, the moment the platform owner approves, signs the new owner in.
class SignupPendingScreen extends ConsumerStatefulWidget {
  const SignupPendingScreen({super.key, this.pollEvery = const Duration(seconds: 5)});
  final Duration pollEvery;

  @override
  ConsumerState<SignupPendingScreen> createState() => _SignupPendingScreenState();
}

class _SignupPendingScreenState extends ConsumerState<SignupPendingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  Timer? _timer;
  String _status = 'pending'; // pending | approved | rejected
  String _reason = '';
  bool _checking = false, _unreachable = false, _signingIn = false;

  @override
  void initState() {
    super.initState();
    _loop.repeat();
    _timer = Timer.periodic(widget.pollEvery, (_) => _check());
    Future.microtask(_check);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final p = ref.read(pendingSignupProvider);
    if (p == null || _checking || _status != 'pending') return;
    setState(() => _checking = true);
    try {
      final r = await ref.read(apiProvider).post('/auth/signup/status', noAuth: true, body: {'phone': p.phone, 'password': p.password});
      if (!mounted) return;
      ref.read(pendingSignupProvider.notifier).set(p.copyWith(businessName: r['business_name'] as String?, typeLabel: r['business_type_label'] as String?));
      setState(() {
        _unreachable = false;
        _status = r['status'] as String;
        _reason = (r['reject_reason'] as String?) ?? '';
      });
      if (_status == 'approved') {
        _timer?.cancel();
        _openShop();
      } else if (_status == 'rejected') {
        _timer?.cancel();
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _unreachable = e.offline);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openShop() async {
    final p = ref.read(pendingSignupProvider);
    if (p == null || _signingIn) return;
    _signingIn = true;
    await Future<void>.delayed(const Duration(milliseconds: 1600)); // let the "approved" moment land
    try {
      await ref.read(sessionProvider.notifier).login(p.phone, p.password);
      ref.read(pendingSignupProvider.notifier).clear();
    } on ApiError {
      if (mounted) context.go('/login');
    }
  }

  void _leave(String to) {
    ref.read(pendingSignupProvider.notifier).clear();
    context.go(to);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(pendingSignupProvider);
    if (p == null) {
      // opened directly, with nothing to wait for
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.go('/login') : null);
      return const AuthFrame(child: SizedBox(height: 200));
    }
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final approved = _status == 'approved', rejected = _status == 'rejected';
    return AuthFrame(
      maxWidth: 480,
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          height: 230,
          child: AnimatedSwitcher(
            duration: Motion.slow,
            switchInCurve: Curves.easeOutBack,
            child: approved
                ? const _ApprovedBurst(key: ValueKey('ok'))
                : rejected
                    ? Icon(Icons.do_not_disturb_on_rounded, key: const ValueKey('no'), size: 96, color: t.danger)
                    : _OrbitLoader(key: const ValueKey('wait'), progress: _loop),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: Motion.base,
          child: Column(
            key: ValueKey(_status),
            children: [
              Text(
                approved
                    ? context.tr('You are approved!')
                    : rejected
                        ? context.tr('We could not approve this request')
                        : context.tr('Orbin Business Management is reviewing your data'),
                textAlign: TextAlign.center,
                style: tt.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                approved
                    ? context.tr('Opening your shop…')
                    : rejected
                        ? (_reason.isEmpty ? context.tr('No reason was given. You can correct your details and send the request again.') : _reason)
                        : context.tr('Please wait for approval. This page updates by itself — you can also close it and sign in later to check.'),
                textAlign: TextAlign.center,
                style: tt.bodyMedium!.copyWith(color: t.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Surface(
          child: Column(children: [
            if (p.businessName.isNotEmpty) KV(context.tr('Business'), p.businessName, mono: false),
            if (p.typeLabel.isNotEmpty) KV(context.tr('Type'), p.typeLabel, mono: false),
            KV(context.tr('Phone'), context.fmt.digits(p.phone)),
          ]),
        ),
        const SizedBox(height: 18),
        _Timeline(status: _status, pulse: _loop),
        if (_unreachable) ...[
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_off_rounded, size: 17, color: t.warning),
            const SizedBox(width: 8),
            Flexible(child: Text(context.tr('Cannot reach the server — we will keep trying.'), style: tt.bodySmall!.copyWith(color: t.warning))),
          ]),
        ],
        const SizedBox(height: 22),
        if (rejected)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/signup'), // the form picks the phone and name back up from the pending state
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(context.tr('Edit and try again')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          )
        else if (!approved)
          OutlinedButton.icon(
            onPressed: _checking ? null : _check,
            icon: _checking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.tr('Check now')),
          ),
        const SizedBox(height: 6),
        if (!approved) TextButton(onPressed: () => _leave('/login'), child: Text(context.tr('Back to sign in'))),
      ]),
    );
  }
}

/// The brand ring in the middle, a dot circling it, and soft rings spreading outwards: "someone is looking at this".
class _OrbitLoader extends StatelessWidget {
  const _OrbitLoader({super.key, required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final still = Motion.reduced(context);
    return SizedBox.square(
      dimension: 230,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(animation: progress, builder: (_, __) => CustomPaint(size: const Size.square(230), painter: _OrbitPainter(still ? 0.15 : progress.value, t.accent, t.outline))),
        OrbitGlyph(size: 86, color: t.text, dot: t.accent),
      ]),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t, this.color, this.track);
  final double t;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final base = s.width / 2;
    // spreading rings, offset by a third of the cycle each
    for (var k = 0; k < 3; k++) {
      final ph = (t * 1.5 + k / 3) % 1;
      canvas.drawCircle(c, base * (0.38 + 0.62 * ph), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: (1 - ph) * 0.28));
    }
    final r = base * 0.8;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = track);
    // the orbiting dot with a fading tail
    final a = t * 2 * math.pi - math.pi / 2;
    for (var i = 14; i >= 0; i--) {
      final ang = a - i * 0.075;
      final f = 1 - i / 15;
      canvas.drawCircle(c + Offset(math.cos(ang), math.sin(ang)) * r, 3 + 6 * f * f, Paint()..color = color.withValues(alpha: 0.12 + 0.88 * f * f));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t || old.color != color || old.track != track;
}

class _ApprovedBurst extends StatelessWidget {
  const _ApprovedBurst({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
        Opacity(opacity: (1 - v).clamp(0, 1), child: Container(width: 90 + 120 * v, height: 90 + 120 * v, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.accent, width: 3)))),
        Transform.scale(scale: v.clamp(0, 1.15), child: Container(width: 104, height: 104, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent), child: Icon(Icons.check_rounded, size: 64, color: t.onAccent))),
      ]),
    );
  }
}

/// Request received → under review → package assigned and shop opened.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.status, required this.pulse});
  final String status;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final approved = status == 'approved', rejected = status == 'rejected';
    final steps = <(String, int)>[
      (context.tr('Request received'), 2),
      (rejected ? context.tr('Reviewed') : context.tr('Under review'), approved || rejected ? 2 : 1),
      (context.tr('Package assigned, shop opened'), approved ? 2 : 0),
    ]; // 2 = done, 1 = happening now, 0 = still to come
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (i, (label, state)) in steps.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 26,
              height: 26,
              child: state == 2
                  ? Container(decoration: BoxDecoration(shape: BoxShape.circle, color: (rejected && i == 1) ? t.danger : t.accent), child: Icon(rejected && i == 1 ? Icons.close_rounded : Icons.check_rounded, size: 16, color: Colors.white))
                  : state == 1
                      ? AnimatedBuilder(
                          animation: pulse,
                          builder: (_, __) {
                            final v = 0.5 + 0.5 * math.sin(pulse.value * 2 * math.pi * 2);
                            return Stack(alignment: Alignment.center, children: [
                              Container(width: 14 + 12 * v, height: 14 + 12 * v, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent.withValues(alpha: 0.25 * (1 - v)))),
                              Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent)),
                            ]);
                          },
                        )
                      : Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.outline, width: 2))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: tt.bodyMedium!.copyWith(fontWeight: state == 1 ? FontWeight.w800 : FontWeight.w600, color: state == 0 ? t.muted : t.text))),
          ]),
        ),
    ]);
  }
}
