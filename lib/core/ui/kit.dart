import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../i18n/lang.dart';
import '../util/responsive.dart';
import 'barcode_scanner.dart';
import 'motion.dart';

export 'motion.dart';

/// A surface. Cards are flat with a hairline border — depth comes from contrast, not heavy shadow. A tappable one
/// answers the pointer: it sinks slightly under a press and its edge warms up under a mouse.
class Surface extends StatefulWidget {
  const Surface({super.key, required this.child, this.padding = const EdgeInsets.all(Sp.l), this.onTap, this.color, this.border = true, this.radius = R.card, this.raised = false, this.clip = true});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool border, raised, clip;
  final double radius;

  @override
  State<Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<Surface> {
  bool _pressed = false, _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tappable = widget.onTap != null;
    final hot = tappable && _hover && !_pressed;
    final deco = BoxDecoration(
      color: widget.color ?? t.surface,
      borderRadius: BorderRadius.circular(widget.radius),
      border: widget.border ? Border.all(color: hot ? Color.lerp(t.outline, t.accent, 0.45)! : t.outline) : null,
      boxShadow: widget.raised || hot ? [BoxShadow(color: Colors.black.withValues(alpha: t.dark ? 0.35 : (hot ? 0.06 : 0.07)), blurRadius: hot ? 20 : 24, offset: Offset(0, hot ? 8 : 10))] : null,
    );
    final inner = Padding(padding: widget.padding, child: widget.child);
    final card = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.settle,
      decoration: deco,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(widget.radius),
        clipBehavior: widget.clip ? Clip.antiAlias : Clip.none,
        child: tappable ? InkWell(onTap: widget.onTap, onHover: (v) => setState(() => _hover = v), onHighlightChanged: (v) => setState(() => _pressed = v), child: inner) : inner,
      ),
    );
    if (!tappable) return card;
    return AnimatedScale(scale: _pressed ? 0.985 : 1, duration: Motion.instant, curve: Curves.easeOut, child: card);
  }
}

/// The one panel on a page that carries the number that matters (today's sales). Deep ink with a soft accent glow and
/// two fine "coin edge" arcs, so it reads as the focal point without any heavy imagery.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child, this.padding = const EdgeInsets.all(24), this.radius = 26});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [BoxShadow(color: t.accent.withValues(alpha: t.dark ? 0.10 : 0.14), blurRadius: 36, offset: const Offset(0, 16))],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: CustomPaint(
          painter: _HeroPainter(accent: t.accent, ink: t.ink, outline: Colors.white.withValues(alpha: t.dark ? 0.08 : 0)),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.accent, required this.ink, required this.outline});
  final Color accent, ink, outline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(ink, accent, 0.20)!, ink, Color.lerp(ink, accent, 0.08)!]).createShader(rect),
    );
    void glow(Offset c, double r, Color color) => canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    final w = size.width, h = size.height, big = math.max(w, h);
    glow(Offset(w * 0.9, h * 0.02), big * 0.55, accent.withValues(alpha: 0.5));
    glow(Offset(w * 0.04, h * 1.08), big * 0.4, Color.lerp(accent, Colors.white, 0.4)!.withValues(alpha: 0.16));
    final line = Paint()..color = Colors.white.withValues(alpha: 0.06)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final c = Offset(w * 0.93, h * 0.08);
    canvas.drawCircle(c, h * 0.62, line);
    canvas.drawCircle(c, h * 0.92, line);
    if (outline.a > 0) canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(26)), Paint()..color = outline..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_HeroPainter o) => o.accent != accent || o.ink != ink || o.outline != outline;
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.icon, this.filled = false, this.dense = false, this.mono = false});
  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled, dense, mono;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = color ?? t.muted;
    final bg = filled ? c : t.tint(c, 0.12);
    final fg = filled ? (c.computeLuminance() > 0.6 ? Colors.black87 : Colors.white) : (t.dark ? Color.lerp(c, Colors.white, 0.35)! : Color.lerp(c, Colors.black, 0.25)!);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.chip)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: dense ? 11 : 13, color: fg), const SizedBox(width: 4)],
        Text(context.tr(label), style: TextStyle(fontSize: dense ? 10.5 : 11.5, fontWeight: FontWeight.w700, color: fg, fontFeatures: mono ? tabular : null, height: 1.25)),
      ]),
    );
  }
}

class Section extends StatelessWidget {
  const Section({super.key, required this.title, this.subtitle, this.action, required this.child, this.pad = true});
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final bool pad;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(title), style: tt.titleLarge),
            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(context.tr(subtitle!), style: tt.bodySmall)),
          ]),
        ),
        if (action != null) action!,
      ]),
      SizedBox(height: pad ? Sp.m : 0),
      child,
    ]);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action, this.compact = false});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Reveal(
        dy: 10,
        child: Padding(
        padding: EdgeInsets.all(compact ? Sp.l : Sp.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: compact ? 52 : 68,
            height: compact ? 52 : 68,
            decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(compact ? 16 : 22)),
            child: Icon(icon, size: compact ? 24 : 30, color: t.accentDeep),
          ),
          SizedBox(height: compact ? Sp.m : Sp.l),
          Text(context.tr(title), style: tt.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: Text(context.tr(message!), style: tt.bodySmall, textAlign: TextAlign.center)),
          ],
          if (action != null) ...[const SizedBox(height: Sp.l), action!],
        ]),
      ),
      ),
    );
  }
}

/// Soft loading placeholder.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height, radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _c.value * 3, 0),
            end: Alignment(-0.5 + _c.value * 3, 0),
            colors: [t.outline.withValues(alpha: 0.55), t.outline.withValues(alpha: 0.2), t.outline.withValues(alpha: 0.55)],
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6, this.height = 64});
  final int rows;
  final double height;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < rows; i++)
          Padding(padding: const EdgeInsets.only(bottom: Sp.s), child: Skeleton(height: height, radius: 14)),
      ]);
}

/// An avatar for things without a picture: initials on a soft colour derived from the name.
class Monogram extends StatelessWidget {
  const Monogram(this.name, {super.key, this.size = 44, this.round = false, this.seed});
  final String name;
  final double size;
  final bool round;
  final String? seed;

  static int hue(String s) {
    var h = 7;
    for (final r in s.runes) {
      h = (h * 31 + r) & 0x7fffffff;
    }
    return h % 360;
  }

  static String initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String first(String s) => String.fromCharCode(s.runes.first).toUpperCase();
    if (parts.length == 1) return first(parts[0]);
    return first(parts[0]) + first(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final h = hue(seed ?? name).toDouble();
    final bg = HSLColor.fromAHSL(1, h, t.dark ? 0.32 : 0.55, t.dark ? 0.22 : 0.9).toColor();
    final fg = HSLColor.fromAHSL(1, h, t.dark ? 0.6 : 0.6, t.dark ? 0.78 : 0.3).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(round ? size : size * 0.3),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg, HSLColor.fromAHSL(1, (h + 24) % 360, t.dark ? 0.3 : 0.5, t.dark ? 0.18 : 0.84).toColor()]),
      ),
      child: Text(initials(name), style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w800, color: fg, letterSpacing: -0.3, fontVariations: const [FontVariation('wght', 800)])),
    );
  }
}

/// Number that stays put as it changes.
class NumText extends StatelessWidget {
  const NumText(this.text, {super.key, this.size = 15, this.weight = 700, this.color, this.align});
  final String text;
  final double size;
  final int weight;
  final Color? color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.values[(weight ~/ 100) - 1], fontVariations: [FontVariation('wght', weight.toDouble())], fontFeatures: tabular, color: color ?? context.t.text, height: 1.15, letterSpacing: -0.2),
      );
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.delta, this.deltaGood = true, this.icon, this.spark, this.hint, this.onTap, this.color});
  final String label, value;
  final double? delta; // fraction, e.g. 0.12 = +12 %
  final bool deltaGood;
  final IconData? icon;
  final List<double>? spark;
  final String? hint;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = color ?? t.accent;
    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.all(Sp.l),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          if (icon != null)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: t.tint(c, 0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: t.dark ? Color.lerp(c, Colors.white, 0.3) : Color.lerp(c, Colors.black, 0.2)),
            ),
          Expanded(child: Text(context.tr(label), style: Theme.of(context).textTheme.labelMedium!.copyWith(color: t.muted), maxLines: 2, overflow: TextOverflow.ellipsis)),
          if (delta != null) _Delta(delta!, deltaGood),
        ]),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: NumText(value, size: 27, weight: 800)),
        if (hint != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(context.tr(hint!), style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
        if (spark != null && spark!.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(height: 34, child: Sparkline(values: spark!, color: c)),
        ],
      ]),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta(this.v, this.good);
  final double v;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final up = v >= 0;
    final c = (up == good) ? t.success : t.danger;
    return Pill('${up ? '▲' : '▼'} ${(v.abs() * 100).toStringAsFixed(v.abs() >= 1 ? 0 : 1)}%', color: c, dense: true, mono: true);
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color, this.fill = true, this.stroke = 2.2});
  final List<double> values;
  final Color color;
  final bool fill;
  final double stroke;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(size: Size.infinite, painter: _SparkPainter(values, color, fill, stroke, v)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v, this.color, this.fill, this.stroke, this.t);
  final List<double> v;
  final Color color;
  final bool fill;
  final double stroke, t;

  @override
  void paint(Canvas canvas, Size s) {
    if (v.length < 2) return;
    final lo = v.reduce(math.min), hi = v.reduce(math.max);
    final span = (hi - lo) == 0 ? 1 : (hi - lo);
    final pad = stroke + 1;
    Offset pt(int i) => Offset(s.width * i / (v.length - 1), pad + (s.height - pad * 2) * (1 - (v[i] - lo) / span) * 1.0);
    final pts = [for (var i = 0; i < v.length; i++) pt(i)];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final metric = path.computeMetrics().first;
    final shown = metric.extractPath(0, metric.length * t);
    if (fill) {
      final area = Path.from(shown)
        ..lineTo(shown.getBounds().right, s.height)
        ..lineTo(0, s.height)
        ..close();
      canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)]).createShader(Offset.zero & s));
    }
    canvas.drawPath(shown, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
    if (t >= 1) canvas.drawCircle(pts.last, stroke + 1.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t || o.v != v || o.color != color;
}

/// Rounded vertical bars, last one emphasised.
class MiniBars extends StatelessWidget {
  const MiniBars({super.key, required this.values, required this.labels, this.color, this.highlightLast = true, this.height = 150, this.fmt});
  final List<double> values;
  final List<String> labels;
  final Color? color;
  final bool highlightLast;
  final double height;
  final String Function(double)? fmt;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = color ?? t.accent;
    final hi = values.isEmpty ? 1.0 : values.reduce(math.max).clamp(1, double.infinity);
    return SizedBox(
      height: height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Tooltip(
                message: fmt?.call(values[i]) ?? values[i].toStringAsFixed(0),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 52),
                        child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: values[i] / hi),
                        duration: Duration(milliseconds: 500 + i * 30),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => FractionallySizedBox(
                          heightFactor: v.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: (highlightLast && i == values.length - 1) ? c : c.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.clip),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class DonutSlice {
  const DonutSlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class Donut extends StatelessWidget {
  const Donut({super.key, required this.slices, this.size = 120, this.center});
  final List<DonutSlice> slices;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(size: Size.square(size), painter: _DonutPainter(slices, context.t.outline, v)),
          ),
          if (center != null) center!,
        ]),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.track, this.t);
  final List<DonutSlice> slices;
  final Color track;
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = s.width * 0.14;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s.width - stroke, s.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..color = track.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = stroke);
    final total = slices.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    final gap = slices.length > 1 ? 0.06 : 0.0;
    for (final sl in slices) {
      final sweep = (sl.value / total) * math.pi * 2 * t;
      canvas.drawArc(rect, start + gap / 2, math.max(sweep - gap, 0.001), false, Paint()..color = sl.color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.t != t || o.slices != slices;
}

/// Horizontal share bar with a label.
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.label, required this.value, required this.fraction, this.color});
  final String label, value;
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = color ?? t.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(context.tr(label), style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          NumText(value, size: 13.5),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 7, color: c, backgroundColor: t.outline.withValues(alpha: 0.6)),
          ),
        ),
      ]),
    );
  }
}

class SegTabs<T> extends StatelessWidget {
  const SegTabs({super.key, required this.items, required this.value, required this.onChanged, this.expand = false});
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final row = Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
      for (final (v, label) in items)
        Flexible(
          fit: expand ? FlexFit.tight : FlexFit.loose,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v == value ? t.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: v == value ? [BoxShadow(color: Colors.black.withValues(alpha: t.dark ? 0.3 : 0.07), blurRadius: 6, offset: const Offset(0, 2))] : null,
              ),
              child: Text(context.tr(label), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: v == value ? t.text : t.muted, fontVariations: const [FontVariation('wght', 650)]), maxLines: 1),
            ),
          ),
        ),
    ]);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(13), border: Border.all(color: t.outline)),
      child: row,
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({super.key, required this.controller, required this.hint, this.onChanged, this.onSubmitted, this.focusNode, this.autofocus = false, this.trailing, this.scannable = false, this.onScan});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged, onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget? trailing;

  /// Shows a camera button that reads one barcode into the box and searches for it.
  final bool scannable;

  /// Replaces the default camera behaviour (the till keeps the camera open and rings items up as they are read).
  final VoidCallback? onScan;

  Future<void> _scanIntoBox(BuildContext context) async {
    final code = await scanBarcode(context);
    if (code == null) return;
    controller.text = code;
    onChanged?.call(code);
    onSubmitted?.call(code);
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.tr(hint),
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: trailing ??
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, v, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                  if (v.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 19),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                    ),
                  if ((scannable || onScan != null) && cameraScanSupported)
                    IconButton(
                      tooltip: context.tr('Scan with camera'),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                      onPressed: onScan ?? () => _scanIntoBox(context),
                    ),
                ]),
              ),
        ),
      );
}

/// A labelled value row used in detail panels.
class KV extends StatelessWidget {
  const KV(this.k, this.v, {super.key, this.bold = false, this.color, this.mono = true});
  final String k, v;
  final bool bold, mono;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      // Label left, value flush right. Both may wrap rather than overflow; `spaceBetween` keeps the value at the edge.
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Flexible(flex: 3, child: Text(context.tr(k), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: bold ? t.text : t.muted, fontWeight: bold ? FontWeight.w700 : null))),
        const SizedBox(width: 12),
        Flexible(flex: 2, child: NumText(v, size: bold ? 16 : 14, weight: bold ? 800 : 650, color: color, align: TextAlign.end)),
      ]),
    );
  }
}

void toast(BuildContext context, String message, {bool error = false, bool good = false, IconData? icon}) {
  final t = context.t;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      duration: Duration(milliseconds: error ? 4200 : 2400),
      content: Row(children: [
        Icon(icon ?? (error ? Icons.error_outline_rounded : (good ? Icons.check_circle_rounded : Icons.info_outline_rounded)), size: 19, color: error ? t.danger : (good ? t.success : t.onInk)),
        const SizedBox(width: 10),
        Expanded(child: Text(context.tr(message))),
      ]),
    ));
}

class IconSquare extends StatelessWidget {
  const IconSquare(this.icon, {super.key, this.color, this.size = 40});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = color ?? t.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.tint(c, 0.12), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.5, color: t.dark ? Color.lerp(c, Colors.white, 0.3) : Color.lerp(c, Colors.black, 0.2)),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirm = 'Confirm', bool danger = false}) async {
  final t = context.t;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.tr(title)),
      content: Text(context.tr(message)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: t.danger, foregroundColor: Colors.white, minimumSize: const Size(64, 44)) : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.tr(confirm)),
        ),
      ],
    ),
  );
  return r ?? false;
}

void haptic() => HapticFeedback.selectionClick();

/// Vertical bars with a faint grid and a scale on the left. The highlighted bar carries the accent. Needs a bounded
/// width and must not sit inside an `IntrinsicHeight` (it measures itself with a `LayoutBuilder`).
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, required this.labels, required this.tips, required this.axis, required this.highlight, required this.height});
  final List<double> values;
  final List<String> labels, tips;
  final String Function(double) axis;
  final int highlight;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final hi = values.isEmpty ? 1.0 : math.max(values.reduce(math.max), 1.0);
    const labelH = 24.0;
    final axisW = context.isCompact ? 46.0 : 54.0;
    final labelStyle = tt.labelSmall!.copyWith(color: t.faint, fontSize: 10.5, letterSpacing: 0);
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (c, box) {
        const top = 10.0;
        final plotH = box.maxHeight - labelH - top;
        return Stack(children: [
          for (final frac in const [0.0, 0.5, 1.0]) ...[
            Positioned(left: axisW, right: 0, bottom: labelH + frac * (plotH - 1), child: Container(height: 1, color: t.outline.withValues(alpha: frac == 0 ? 1 : 0.55))),
            Positioned(left: 0, width: axisW - 8, bottom: labelH + frac * (plotH - 1) - 7, child: Text(frac == 0 ? '' : axis(hi * frac), style: labelStyle, textAlign: TextAlign.end, maxLines: 1, softWrap: false, overflow: TextOverflow.visible)),
          ],
          Positioned(
            left: axisW,
            right: 0,
            top: top,
            bottom: 0,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Tooltip(
                    message: tips[i],
                    child: Column(children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 34),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: values[i] / hi),
                                duration: Duration(milliseconds: 450 + i * 28),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => FractionallySizedBox(
                                  heightFactor: math.max(v, 0.012),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7), bottom: Radius.circular(2)),
                                      gradient: i == highlight
                                          ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(t.accent, Colors.white, 0.18)!, t.accent])
                                          : null,
                                      color: i == highlight ? null : t.accent.withValues(alpha: t.dark ? 0.32 : 0.24),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: labelH,
                        child: Center(child: Text(labels[i], style: labelStyle.copyWith(color: i == highlight ? t.text : t.faint, fontWeight: i == highlight ? FontWeight.w800 : FontWeight.w600), maxLines: 1, overflow: TextOverflow.clip)),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
        ]);
      }),
    );
  }
}

/// Cards in equal-height rows. The column count follows the width available (never narrower than [minWidth] a card),
/// every card in a row stretches to the tallest, and a short last row keeps its cards the same width as the rest.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.children, this.minWidth = 400, this.maxColumns = 2, this.gap = 14, this.fillLast = false});
  final List<Widget> children;
  final double minWidth, gap;
  final int maxColumns;

  /// A short last row shares the full width among its cards instead of leaving empty cells.
  final bool fillLast;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final cols = math.max(1, math.min(maxColumns, ((box.maxWidth + gap) / (minWidth + gap)).floor()));
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final slice = children.skip(i).take(cols).toList();
          final span = fillLast ? slice.length : cols;
          rows.add(IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var j = 0; j < span; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
              ],
            ]),
          ));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, r) in rows.indexed) ...[if (i > 0) SizedBox(height: gap), r],
        ]);
      });
}
