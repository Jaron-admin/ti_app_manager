import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material theme built only from Ti design tokens.
class TiTheme {
  const TiTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final ink = isDark ? TiColors.inkDark : TiColors.ink;
    final paper = isDark ? TiColors.paperDark : TiColors.paper;
    final surface = isDark ? TiColors.surfaceDark : TiColors.surface;
    final primary = isDark ? TiColors.primaryDark : TiColors.primary;
    final line = isDark ? TiColors.lineDark : TiColors.line;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? TiColors.paperDark : TiColors.paper,
      secondary: primary,
      onSecondary: isDark ? TiColors.paperDark : TiColors.paper,
      error: TiColors.danger,
      onError: TiColors.paper,
      surface: surface,
      onSurface: ink,
      outline: line,
      outlineVariant: line,
      onSurfaceVariant: TiColors.muted,
    );

    TextStyle text(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: TiType.family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: ink,
    );

    final textTheme = TextTheme(
      displaySmall: text(
        TiType.display,
        FontWeight.w600,
        TiType.lineHeightTitle,
      ),
      headlineSmall: text(
        TiType.headline,
        FontWeight.w600,
        TiType.lineHeightTitle,
      ),
      titleMedium: text(TiType.title, FontWeight.w600, TiType.lineHeightTitle),
      bodyMedium: text(TiType.body, FontWeight.w400, TiType.lineHeightBody),
      bodySmall: text(
        TiType.caption,
        FontWeight.w400,
        TiType.lineHeightBody,
      ).copyWith(color: TiColors.muted),
      labelSmall: text(
        TiType.small,
        FontWeight.w500,
        TiType.lineHeightBody,
      ).copyWith(color: TiColors.muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      fontFamily: TiType.family,
      textTheme: textTheme,
      dividerColor: line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
    );
  }
}
