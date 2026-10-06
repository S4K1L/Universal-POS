import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/util/responsive.dart';
import '../../data/platform_status.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import 'maintenance_art.dart';

/// Shown to every business user while the platform owner has maintenance switched on (Platform console → Settings).
/// It leaves by itself: the status is re-checked every few seconds and the router moves on once it is off.
///
/// A dark stage tinted with the business's own accent, a set of gears that turn (faster while it checks the server),
/// and content that settles in one piece at a time. With "reduce motion" on, it is the same page held still.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> with TickerProviderStateMixin {
  static const _idleSpin = 0.45; // radians per second
  static const _checkingBoost = 6.0;

  final _clock = ValueNotifier<Beat>(const Beat(0, 0));
  final _sparks = Spark.field(26);
  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  Duration _last = Duration.zero;
  double _speed = 1, _spin = 0;
  bool? _reduced;
  bool _checking = false, _checked = false;

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _speed += ((_checking ? _checkingBoost : 1.0) - _speed) * math.min(1.0, dt * 3);
    _spin += dt * _idleSpin * _speed;
    _clock.value = Beat(elapsed.inMicroseconds / 1e6, _spin);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduced) return;
    _reduced = reduce;
    if (reduce) {
      _ticker.stop();
      _clock.value = const Beat(6, 0.9);
      _intro.value = 1;
    } else {
      _last = Duration.zero;
      if (!_ticker.isActive) _ticker.start();
      if (_intro.value == 0) _intro.forward();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _intro.dispose();
    _clock.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    // The server usually answers in a blink; hold the spin long enough that the tap visibly did something.
    await Future.wait([ref.read(platformStatusProvider.notifier).refresh(), Future<void>.delayed(const Duration(milliseconds: 900))]);
    if (mounted) {
      setState(() {
        _checking = false;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final status = ref.watch(platformStatusProvider);
    final waiting = ref.watch(syncProvider.select((s) => s.pending));
    final size = MediaQuery.sizeOf(context);
    final wide = context.isWide;
    final accent = t.accent;
    final light = Color.lerp(accent, Colors.white, 0.3)!;
    final message = status.message.trim().isEmpty ? context.tr('We are making improvements and will be back shortly.') : status.message.trim();
    final support = [
      if (status.support['phone'] != null) (Icons.phone_rounded, status.support['phone']!),
      if (status.support['whatsapp'] != null) (Icons.chat_rounded, status.support['whatsapp']!),
      if (status.support['email'] != null) (Icons.mail_rounded, status.support['email']!),
    ];

    Widget reveal(int i, Widget child, {bool scale = false}) => _Reveal(animation: _intro, index: i, scale: scale, child: child);

    final brand = reveal(0, Row(children: [BrandMark(size: 42, color: accent), const SizedBox(width: 12), const BrandWordmark(size: 21, onInk: true)]));

    final heroSize = wide ? math.min(440.0, size.height * 0.72) : (size.height < 640 ? 150.0 : 210.0);
    final hero = reveal(
      1,
      ExcludeSemantics(
        child: SizedBox.square(dimension: heroSize, child: RepaintBoundary(child: CustomPaint(painter: GearsPainter(clock: _clock, accent: accent, amber: t.warning)))),
      ),
      scale: true,
    );

    final pill = Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(30), border: Border.all(color: accent.withValues(alpha: 0.35))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 16, height: 16, child: CustomPaint(painter: PulseDotPainter(clock: _clock, color: light))),
        const SizedBox(width: 8),
        Text(context.tr('MAINTENANCE IN PROGRESS'), style: tt.labelSmall!.copyWith(color: light, letterSpacing: 1.0)),
      ]),
    );

    final messageCard = _Glass(
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 14),
          Expanded(child: Text(message, key: const Key('maintenance-message'), style: tt.bodyLarge!.copyWith(color: t.onInk, fontSize: 16.5, height: 1.5))),
        ]),
      ),
    );

    final waitingCard = _Glass(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.cloud_done_rounded, color: light),
        const SizedBox(width: 12),
        Expanded(child: Text(context.trf('Sales waiting to sync: {n}. They are saved on this device and will sync when we are back.', {'n': context.fmt.digits('$waiting')}), style: tt.bodyMedium!.copyWith(color: t.onInk))),
      ]),
    );

    final sweep = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 4, width: double.infinity, child: CustomPaint(painter: SweepPainter(clock: _clock, color: light))),
      const SizedBox(height: 10),
      Text(_checked ? context.tr('Still under maintenance. We will keep checking.') : context.tr('We check again automatically.'), style: tt.labelMedium!.copyWith(color: t.onInkMuted)),
    ]);

    final actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        onPressed: _checking ? null : _check,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        icon: _checking ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : const Icon(Icons.refresh_rounded),
        label: Text(context.tr('Check again')),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () => ref.read(sessionProvider.notifier).logout(),
        style: TextButton.styleFrom(foregroundColor: t.onInkMuted),
        child: Text(context.tr('Sign out')),
      ),
    ]);

    final help = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.tr('Need help?'), style: tt.titleSmall!.copyWith(color: t.onInkMuted)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (icon, value) in support)
          _Glass(
            radius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: light),
              const SizedBox(width: 8),
              Flexible(child: SelectableText(value, style: tt.bodyMedium!.copyWith(color: t.onInk))),
            ]),
          ),
      ]),
    ]);

    final copy = <Widget>[
      reveal(2, pill),
      const SizedBox(height: 18),
      reveal(3, Text(context.tr("We'll be right back"), style: tt.displaySmall!.copyWith(color: t.onInk, fontSize: wide ? 42 : 30, height: 1.1))),
      const SizedBox(height: 14),
      reveal(4, messageCard),
      if (waiting > 0) ...[const SizedBox(height: 12), reveal(5, waitingCard)],
      const SizedBox(height: 22),
      reveal(6, sweep),
      const SizedBox(height: 26),
      reveal(7, actions),
      if (support.isNotEmpty) ...[const SizedBox(height: 22), reveal(8, help)],
    ];

    final layout = wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 11, child: Padding(padding: const EdgeInsets.only(right: 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [brand, const SizedBox(height: 44), ...copy]))),
            Expanded(flex: 10, child: Center(child: hero)),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [brand, const SizedBox(height: 8), Center(child: hero), const SizedBox(height: 8), ...copy]);

    return Scaffold(
      backgroundColor: t.ink,
      body: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(-0.7, -0.8), radius: 1.4, colors: [Color.lerp(t.ink, accent, 0.30)!, t.ink])),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: AmbientPainter(clock: _clock, accent: accent, amber: t.warning, sparks: _sparks)))),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 48)),
                child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 1120 : 480), child: layout)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A frosted card on the dark stage.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(16), this.radius = 18});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
        child: Padding(padding: padding, child: child),
      );
}

/// Fades and slides [child] in, each [index] a beat after the one before it.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.index, required this.child, this.scale = false});
  final Animation<double> animation;
  final int index;
  final bool scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curve = Interval(index * 0.06, index * 0.06 + 0.4, curve: scale ? Curves.easeOutBack : Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = curve.transform(animation.value);
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: scale ? Transform.scale(scale: 0.78 + 0.22 * v, child: child) : Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
        );
      },
    );
  }
}
