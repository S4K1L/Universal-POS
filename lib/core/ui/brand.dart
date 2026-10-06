import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The Universal POS mark: a rounded tile with a bold "U" (everything, everywhere) and a till-button dot.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final base = color ?? t.accent;
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _MarkPainter(base, t.onAccent)));
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.fg);
  final Color color, fg;

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.3));
    final hsl = HSLColor.fromColor(color);
    final deep = hsl.withLightness((hsl.lightness - 0.14).clamp(0.1, 0.9)).toColor();
    canvas.drawRRect(
      r,
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, deep]).createShader(Offset.zero & s),
    );
    final w = s.width, h = s.height;
    final stroke = w * 0.15;
    final p = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(w * 0.3, h * 0.28)
      ..lineTo(w * 0.3, h * 0.55)
      ..arcToPoint(Offset(w * 0.7, h * 0.55), radius: Radius.circular(w * 0.2), clockwise: false)
      ..lineTo(w * 0.7, h * 0.44);
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(w * 0.7, h * 0.27), stroke * 0.55, Paint()..color = fg);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.fg != fg;
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 18, this.onInk = false});
  final double size;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = onInk ? t.onInk : t.text;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'universal', style: TextStyle(fontWeight: FontWeight.w500, color: c)),
        TextSpan(text: 'pos', style: TextStyle(fontWeight: FontWeight.w800, color: t.accent)),
      ]),
      style: TextStyle(fontSize: size, letterSpacing: -0.4, fontVariations: const [FontVariation('wght', 600)]),
    );
  }
}
