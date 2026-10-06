import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// The maintenance page's clock: seconds since it appeared, and how far the big gear has turned. The gear's angle is
/// kept apart from the time so the page can spin it faster while it is checking the server, without a visible jump.
@immutable
class Beat {
  const Beat(this.t, this.spin);
  final double t, spin;
}

/// A mote that drifts up the stage and fades in and out.
class Spark {
  const Spark(this.x, this.phase, this.speed, this.radius, this.alpha, this.sway);
  final double x, phase, speed, radius, alpha, sway;

  static List<Spark> field(int n, {int seed = 11}) {
    final r = math.Random(seed);
    return [for (var i = 0; i < n; i++) Spark(r.nextDouble(), r.nextDouble(), 0.012 + r.nextDouble() * 0.02, 0.8 + r.nextDouble() * 1.8, 0.25 + r.nextDouble() * 0.45, 0.3 + r.nextDouble() * 0.7)];
  }
}

/// Soft glows that wander across the stage, plus the rising sparks.
class AmbientPainter extends CustomPainter {
  AmbientPainter({required this.clock, required this.accent, required this.amber, required this.sparks}) : super(repaint: clock);

  final ValueListenable<Beat> clock;
  final Color accent, amber;
  final List<Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value.t;
    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    }

    final s = size.shortestSide;
    glow(Offset(size.width * (0.16 + 0.06 * math.sin(t * 0.21)), size.height * (0.18 + 0.05 * math.cos(t * 0.17))), s * 0.75, accent.withValues(alpha: 0.22));
    glow(Offset(size.width * (0.86 + 0.05 * math.cos(t * 0.19)), size.height * (0.82 + 0.06 * math.sin(t * 0.23))), s * 0.62, accent.withValues(alpha: 0.15));
    glow(Offset(size.width * (0.62 + 0.07 * math.sin(t * 0.13 + 1)), size.height * (0.30 + 0.07 * math.cos(t * 0.11))), s * 0.38, amber.withValues(alpha: 0.07));

    for (final p in sparks) {
      final y = 1 - ((p.phase + t * p.speed) % 1.0);
      final x = p.x + 0.012 * math.sin(t * p.sway + p.phase * 20);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.radius, Paint()..color = Colors.white.withValues(alpha: math.sin(y * math.pi) * p.alpha));
    }
  }

  @override
  bool shouldRepaint(AmbientPainter old) => old.accent != accent || old.amber != amber || old.sparks != sparks;
}

/// Three meshing gears, turning. Tooth counts decide the radii (one tooth size for all), and each small gear's angle
/// is derived from the big one's so teeth always slot into gaps rather than pass through each other.
class GearsPainter extends CustomPainter {
  GearsPainter({required this.clock, required this.accent, required this.amber}) : super(repaint: clock);

  final ValueListenable<Beat> clock;
  final Color accent, amber;

  static const _nA = 14, _nB = 9, _nC = 7;
  static const _dirB = -0.62, _dirC = 0.72; // radians from the big gear's centre to the others' (y points down)
  static const _addendum = 0.9, _dedendum = 1.0; // tooth height above / below the pitch circle, in modules

  static const _twinkles = [(0.08, 0.16, 7.0), (0.93, 0.30, 9.0), (0.12, 0.88, 6.0), (0.88, 0.92, 8.0), (0.52, 0.03, 6.0)];

  @override
  void paint(Canvas canvas, Size size) {
    final beat = clock.value;

    // Everything is laid out in modules, then scaled so the whole cluster fits the box.
    const rA = _nA / 2, rB = _nB / 2, rC = _nC / 2;
    const cA = Offset.zero;
    final cB = Offset.fromDirection(_dirB, rA + rB);
    final cC = Offset.fromDirection(_dirC, rA + rC);
    final bounds = Rect.fromCircle(center: cA, radius: rA + _addendum).expandToInclude(Rect.fromCircle(center: cB, radius: rB + _addendum)).expandToInclude(Rect.fromCircle(center: cC, radius: rC + _addendum));
    final u = math.min(size.width / bounds.width, size.height / bounds.height) * 0.84;
    final bob = Offset(0, math.sin(beat.t * 1.1) * size.height * 0.012);
    final origin = size.center(Offset.zero) - bounds.center * u + bob;
    Offset at(Offset m) => origin + m * u;

    canvas.drawCircle(size.center(Offset.zero), size.shortestSide * 0.46, Paint()..shader = RadialGradient(colors: [accent.withValues(alpha: 0.20), accent.withValues(alpha: 0)]).createShader(Offset.zero & size));

    // Twinkling four-point stars around the cluster.
    for (final (i, (fx, fy, r)) in _twinkles.indexed) {
      final a = (0.5 + 0.5 * math.sin(beat.t * 1.8 + i * 1.7)).clamp(0.0, 1.0);
      _star(canvas, Offset(fx * size.width, fy * size.height), r * (0.55 + 0.45 * a), Paint()..color = Colors.white.withValues(alpha: 0.15 + 0.6 * a));
    }

    final pitchA = 2 * math.pi / _nA;
    final rotA = beat.spin;
    // How far past this contact line the big gear's nearest tooth is → where the meshing gear's gap must sit.
    double meshed(int n, double dir) {
      final eps = ((dir - rotA) % pitchA + pitchA) % pitchA;
      return dir + math.pi + eps * _nA / n - math.pi / n;
    }

    final light = Color.lerp(accent, Colors.white, 0.28)!;
    final deepAccent = Color.lerp(accent, Colors.black, 0.35)!;
    final lightAmber = Color.lerp(amber, Colors.white, 0.3)!;
    final deepAmber = Color.lerp(amber, Colors.black, 0.35)!;
    final pale = Color.lerp(accent, Colors.white, 0.7)!;
    final paleDeep = Color.lerp(accent, Colors.white, 0.3)!;

    _gear(canvas, at(cC), _nC, rC, meshed(_nC, _dirC), u, pale, paleDeep, holes: 0);
    _gear(canvas, at(cB), _nB, rB, meshed(_nB, _dirB), u, lightAmber, deepAmber, holes: 4);
    _gear(canvas, at(cA), _nA, rA, rotA, u, light, deepAccent, holes: 5);
  }

  void _gear(Canvas canvas, Offset c, int n, double r, double rot, double u, Color light, Color deep, {required int holes}) {
    final tip = (r + _addendum) * u, root = (r - _dedendum) * u, pitch = 2 * math.pi / n;
    final body = Path();
    var first = true;
    for (var k = 0; k < n; k++) {
      final a = rot + k * pitch;
      for (final (rad, off) in [(root, -0.30), (tip, -0.13), (tip, 0.13), (root, 0.30)]) {
        final p = c + Offset.fromDirection(a + off * pitch, rad);
        first ? body.moveTo(p.dx, p.dy) : body.lineTo(p.dx, p.dy);
        first = false;
      }
    }
    body.close();

    // Holes are extra sub-paths inside the body; even-odd filling cuts them out.
    final shape = Path.from(body)..fillType = PathFillType.evenOdd;
    shape.addOval(Rect.fromCircle(center: c, radius: root * 0.26));
    for (var h = 0; h < holes; h++) {
      shape.addOval(Rect.fromCircle(center: c + Offset.fromDirection(rot + (h + 0.5) * 2 * math.pi / holes, root * 0.58), radius: root * 0.17));
    }

    canvas.drawPath(body, Paint()..color = deep.withValues(alpha: 0.5)..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 1.4));
    canvas.drawPath(shape, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, deep]).createShader(Rect.fromCircle(center: c, radius: tip)));
    canvas.drawCircle(c, root * 0.80, Paint()..style = PaintingStyle.stroke..strokeWidth = u * 0.12..color = Colors.white.withValues(alpha: 0.14));
    canvas.drawCircle(c, root * 0.13, Paint()..color = light);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(GearsPainter old) => old.accent != accent || old.amber != amber;
}

/// A dot with a ring that ripples outward — the "live" light on the status pill.
class PulseDotPainter extends CustomPainter {
  PulseDotPainter({required this.clock, required this.color}) : super(repaint: clock);

  final ValueListenable<Beat> clock;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final phase = (clock.value.t % 1.8) / 1.8;
    canvas.drawCircle(c, size.width * (0.22 + 0.28 * phase), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = color.withValues(alpha: (1 - phase) * 0.6));
    canvas.drawCircle(c, size.width * 0.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(PulseDotPainter old) => old.color != color;
}

/// An indeterminate progress bar: a bright segment that eases across the track and starts over.
class SweepPainter extends CustomPainter {
  SweepPainter({required this.clock, required this.color}) : super(repaint: clock);

  final ValueListenable<Beat> clock;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.save();
    canvas.clipRRect(track);
    final seg = size.width * 0.38;
    final eased = Curves.easeInOut.transform((clock.value.t % 2.0) / 2.0);
    final rect = Rect.fromLTWH(-seg + eased * (size.width + seg), 0, seg, size.height);
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)]).createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(SweepPainter old) => old.color != color;
}
