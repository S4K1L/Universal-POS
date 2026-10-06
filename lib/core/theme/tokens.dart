import 'package:flutter/material.dart';

/// Design tokens. One accent per business type re-themes the whole app — a furniture
/// showroom feels walnut, a supershop emerald, a cosmetic shop rose — while ink, paper
/// and type stay constant so every shop still feels like one product.
@immutable
class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.dark,
    required this.canvas,
    required this.surface,
    required this.surface2,
    required this.outline,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.accentDeep,
    required this.onAccent,
    required this.ink,
    required this.inkRaised,
    required this.onInk,
    required this.onInkMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final bool dark;
  final Color canvas, surface, surface2, outline, text, muted, faint;
  final Color accent, accentSoft, accentDeep, onAccent;
  final Color ink, inkRaised, onInk, onInkMuted;
  final Color success, warning, danger, info;

  static const defaultAccent = Color(0xFF0E9F6E);

  factory Tokens.build({required Brightness brightness, Color accent = defaultAccent}) {
    final dark = brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(accent);
    final lum = accent.computeLuminance();
    final deep = hsl.withLightness((hsl.lightness - 0.12).clamp(0.12, 0.9)).toColor();
    return Tokens(
      dark: dark,
      canvas: dark ? const Color(0xFF0B110F) : const Color(0xFFF4F3EE),
      surface: dark ? const Color(0xFF121B17) : const Color(0xFFFFFFFF),
      surface2: dark ? const Color(0xFF18241F) : const Color(0xFFFAF9F5),
      outline: dark ? const Color(0xFF263530) : const Color(0xFFE5E3DA),
      text: dark ? const Color(0xFFEFF3F0) : const Color(0xFF111915),
      muted: dark ? const Color(0xFF93A29B) : const Color(0xFF65706A),
      faint: dark ? const Color(0xFF5E6E67) : const Color(0xFF9AA39E),
      accent: accent,
      accentSoft: accent.withValues(alpha: dark ? 0.18 : 0.11),
      accentDeep: dark ? accent : deep,
      onAccent: lum > 0.55 ? const Color(0xFF111915) : Colors.white,
      ink: const Color(0xFF0A1310),
      inkRaised: const Color(0xFF142019),
      onInk: const Color(0xFFF1F5F2),
      onInkMuted: const Color(0xFF8B9C94),
      success: const Color(0xFF1FA971),
      warning: const Color(0xFFE9A100),
      danger: const Color(0xFFE5484D),
      info: const Color(0xFF3B82F6),
    );
  }

  Color tint(Color c, [double a = 0.12]) => c.withValues(alpha: dark ? a + 0.07 : a);

  @override
  Tokens copyWith({Color? accent}) => Tokens.build(brightness: dark ? Brightness.dark : Brightness.light, accent: accent ?? this.accent);

  @override
  Tokens lerp(ThemeExtension<Tokens>? other, double t) => other is Tokens ? (t < 0.5 ? this : other) : this;
}

extension TokensX on BuildContext {
  Tokens get t => Theme.of(this).extension<Tokens>()!;
}

/// Radii and spacing used everywhere, so rhythm stays consistent.
class R {
  static const card = 18.0;
  static const control = 12.0;
  static const chip = 999.0;
  static const sheet = 26.0;
}

class Sp {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
}
