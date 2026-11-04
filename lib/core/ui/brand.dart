import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

// Geometry of the Orbin mark in tile units (tile = 1.0): a ring with a small orbiting dot, and a clear gap around the dot.
const _ringCenter = Offset(0.483, 0.518);
const _ringR = 0.2847, _ringHole = 0.537 * 0.2847;
const _dotOffset = Offset(0.1955, -0.1966);
const _dotR = 0.0773, _dotGap = 0.108;

/// Paints the ring and orbiting dot into the unit square that fills [box]. The gap around the dot is cut out of the ring,
/// so the mark sits on any background.
void _paintOrbit(Canvas canvas, Rect box, {required Color ring, required Color dot, double scale = 1}) {
  Offset at(Offset u) => Offset(box.left + (0.5 + (u.dx - 0.5) * scale) * box.width, box.top + (0.5 + (u.dy - 0.5) * scale) * box.height);
  final k = box.width * scale;
  final c = at(_ringCenter);
  final d = at(_ringCenter + _dotOffset);
  // The ring is a thick stroked circle; the gap around the dot is erased from that layer only.
  canvas.saveLayer(box.inflate(1), Paint());
  canvas.drawCircle(
    c,
    (_ringR + _ringHole) / 2 * k,
    Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = (_ringR - _ringHole) * k
      ..isAntiAlias = true,
  );
  canvas.drawCircle(d, _dotGap * k, Paint()..blendMode = BlendMode.clear..isAntiAlias = true);
  canvas.restore();
  canvas.drawCircle(d, _dotR * k, Paint()..color = dot..isAntiAlias = true);
}

/// The Orbin app tile: a rounded square in the business accent (brand green by default) with the white orbit mark.
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

/// The orbit mark alone, no tile: a ring in [color] and the orbiting dot in [dot] (brand green by default).
class OrbitGlyph extends StatelessWidget {
  const OrbitGlyph({super.key, this.size = 40, this.color, this.dot});
  final double size;
  final Color? color, dot;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GlyphPainter(color ?? t.text, dot ?? t.accent)));
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.ring, this.dot);
  final Color ring, dot;

  @override
  void paint(Canvas canvas, Size s) => _paintOrbit(canvas, Offset.zero & s, ring: ring, dot: dot);

  @override
  bool shouldRepaint(_GlyphPainter old) => old.ring != ring || old.dot != dot;
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.fg);
  final Color color, fg;

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.227));
    final hsl = HSLColor.fromColor(color);
    final deep = hsl.withLightness((hsl.lightness - 0.10).clamp(0.1, 0.9)).toColor();
    canvas.drawRRect(
      r,
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, deep]).createShader(Offset.zero & s),
    );
    _paintOrbit(canvas, Offset.zero & s, ring: fg, dot: fg);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.fg != fg;
}

/// "orbin" — the lowercase wordmark, with the dot on the i in brand green. [size] is roughly a font size.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 18, this.onInk = false});
  final double size;
  final bool onInk;

  static const _aspect = 904 / 303;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = onInk ? t.onInk : t.text;
    final h = size * 1.15;
    return Semantics(
      label: 'orbin',
      child: ExcludeSemantics(
        child: SizedBox(
          width: h * _aspect,
          height: h,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/brand/orbin_wordmark.png', color: c, colorBlendMode: BlendMode.srcIn, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
            Image.asset('assets/brand/orbin_wordmark_dot.png', color: t.accent, colorBlendMode: BlendMode.srcIn, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ]),
        ),
      ),
    );
  }
}

/// The mark rendered to PNG bytes, for places that cannot draw a widget (the PDF report).
Future<Uint8List> brandMarkPng(Color tile, Color glyph, {int px = 256}) async {
  final recorder = ui.PictureRecorder();
  _MarkPainter(tile, glyph).paint(Canvas(recorder), Size(px.toDouble(), px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
