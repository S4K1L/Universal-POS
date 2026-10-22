import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One set of timings and curves so every movement in the app feels like it belongs to the same product.
class Motion {
  static const instant = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 460);

  /// Things settling into place: quick start, soft landing.
  static const settle = Curves.easeOutCubic;

  /// Things that leave: gentle start, quick finish.
  static const exit = Curves.easeInCubic;

  /// Honour the system "reduce motion" switch: no travel, no fades, just the result.
  static bool reduced(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// Page change between two screens of the same shell: the old screen fades out, then the new one fades in with a
/// whisper of upward travel. The two never overlap, so there is no ghosting or flash of both at once.
CustomTransitionPage<void> fadeThroughPage(Widget child, GoRouterState state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondary, child) {
        if (Motion.reduced(context)) return child;
        final incoming = CurvedAnimation(parent: animation, curve: const Interval(0.3, 1, curve: Curves.easeOutCubic));
        final outgoing = CurvedAnimation(parent: secondary, curve: const Interval(0, 0.3, curve: Curves.easeIn));
        return FadeTransition(
          opacity: ReverseAnimation(outgoing),
          child: FadeTransition(
            opacity: incoming,
            child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(incoming), child: child),
          ),
        );
      },
    );

/// Entrance for a block of content: it rises a few pixels while fading in, optionally after a [delay] so a group of
/// cards arrives one after another. Plays once, when the block first appears.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 480), this.dy = 16});
  final Widget child;
  final Duration delay, duration;
  final double dy;

  /// Delay for the [index]-th item of a group, capped so long lists do not make people wait.
  static Duration stagger(int index, {int step = 55, int max = 6}) => Duration(milliseconds: step * (index > max ? max : index));

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + widget.duration);
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Interval(widget.delay.inMilliseconds / (widget.delay + widget.duration).inMilliseconds, 1, curve: Curves.easeOutCubic),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: AnimatedBuilder(
          animation: _a,
          builder: (_, child) => Transform.translate(offset: Offset(0, (1 - _a.value) * widget.dy), child: child),
          child: widget.child,
        ),
      );
}

/// Holds back a loading placeholder for a moment. Most reads finish in well under [delay], and flashing a skeleton
/// for two frames looks like a glitch; if the wait is real, the placeholder fades in gently.
class Deferred extends StatefulWidget {
  const Deferred({super.key, required this.child, this.delay = const Duration(milliseconds: 160)});
  final Widget child;
  final Duration delay;

  @override
  State<Deferred> createState() => _DeferredState();
}

class _DeferredState extends State<Deferred> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + const Duration(milliseconds: 240))..forward();
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Interval(widget.delay.inMilliseconds / (widget.delay.inMilliseconds + 240), 1, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _a, child: widget.child);
}

/// Cross-fades between states of the same slot (loading → content, empty → list) instead of swapping in one frame.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({super.key, required this.child, this.duration = const Duration(milliseconds: 260)});
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: Motion.reduced(context) ? Duration.zero : duration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        layoutBuilder: (current, previous) => Stack(fit: StackFit.passthrough, alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
        child: child,
      );
}

/// A number that counts up to its value on first sight and glides to each new value after that.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.format, required this.builder, this.duration = const Duration(milliseconds: 900)});
  final int value;
  final String Function(int) format;
  final Widget Function(BuildContext, String) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return builder(context, format(value));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (c, v, _) => builder(c, format(v.round())),
    );
  }
}
