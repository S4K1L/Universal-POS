import 'package:flutter/material.dart';

import 'tokens.dart';

const _latin = 'PJS';
const _bangla = ['Hind'];

TextStyle _ts(double size, int weight, {double? height, double? ls, Color? color}) => TextStyle(
      fontFamily: _latin,
      fontFamilyFallback: _bangla,
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      height: height,
      letterSpacing: ls,
      color: color,
    );

/// Tabular numerals keep columns of money from jittering.
const tabular = [FontFeature.tabularFigures()];

TextTheme _textTheme(Tokens t) => TextTheme(
      displayLarge: _ts(40, 800, height: 1.1, ls: -1.2, color: t.text),
      displayMedium: _ts(32, 800, height: 1.12, ls: -0.8, color: t.text),
      displaySmall: _ts(26, 700, height: 1.15, ls: -0.5, color: t.text),
      headlineMedium: _ts(22, 700, height: 1.2, ls: -0.3, color: t.text),
      headlineSmall: _ts(19, 700, height: 1.25, ls: -0.2, color: t.text),
      titleLarge: _ts(17, 700, height: 1.3, color: t.text),
      titleMedium: _ts(15, 650, height: 1.3, color: t.text),
      titleSmall: _ts(13.5, 650, height: 1.3, color: t.text),
      bodyLarge: _ts(15.5, 500, height: 1.45, color: t.text),
      bodyMedium: _ts(14, 500, height: 1.45, color: t.text),
      bodySmall: _ts(12.5, 500, height: 1.4, color: t.muted),
      labelLarge: _ts(14, 650, height: 1.2, color: t.text),
      labelMedium: _ts(12.5, 650, height: 1.2, color: t.text),
      labelSmall: _ts(11, 650, height: 1.2, ls: 0.4, color: t.muted),
    );

ThemeData buildTheme(Brightness brightness, {Color accent = Tokens.defaultAccent}) {
  final t = Tokens.build(brightness: brightness, accent: accent);
  final text = _textTheme(t);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.accent,
    onPrimary: t.onAccent,
    secondary: t.accentDeep,
    onSecondary: t.onAccent,
    error: t.danger,
    onError: Colors.white,
    surface: t.surface,
    onSurface: t.text,
    surfaceContainerLowest: t.canvas,
    surfaceContainerLow: t.surface2,
    surfaceContainer: t.surface2,
    surfaceContainerHigh: t.surface2,
    surfaceContainerHighest: t.surface2,
    outline: t.outline,
    outlineVariant: t.outline,
    onSurfaceVariant: t.muted,
  );
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(R.control), borderSide: BorderSide(color: c, width: w));
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.canvas,
    canvasColor: t.surface,
    fontFamily: _latin,
    fontFamilyFallback: _bangla,
    textTheme: text,
    primaryTextTheme: text,
    extensions: [t],
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: DividerThemeData(color: t.outline, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(t.outline),
      enabledBorder: border(t.outline),
      focusedBorder: border(t.accent, 1.6),
      errorBorder: border(t.danger),
      focusedErrorBorder: border(t.danger, 1.6),
      labelStyle: text.bodyMedium!.copyWith(color: t.muted),
      floatingLabelStyle: text.labelMedium!.copyWith(color: t.accentDeep),
      hintStyle: text.bodyMedium!.copyWith(color: t.faint),
      prefixIconColor: t.muted,
      suffixIconColor: t.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        elevation: 0,
        minimumSize: const Size(64, 50),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: t.outline),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.accentDeep, shape: shape, textStyle: text.labelLarge),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: t.text)),
    chipTheme: ChipThemeData(
      backgroundColor: t.surface2,
      selectedColor: t.accentSoft,
      side: BorderSide(color: t.outline),
      labelStyle: text.labelMedium,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.onAccent : t.faint),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : t.outline),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : Colors.transparent),
      checkColor: WidgetStatePropertyAll(t.onAccent),
      side: BorderSide(color: t.faint, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sheet)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: t.onInk),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: text.labelMedium!.copyWith(color: t.onInk),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: t.outline)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent, linearTrackColor: t.outline),
    listTileTheme: ListTileThemeData(shape: shape, iconColor: t.muted),
    scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(t.outline), radius: const Radius.circular(8)),
  );
}
