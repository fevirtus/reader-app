import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _build(_lightScheme);
  static final ThemeData darkTheme = _build(_darkScheme);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.lightAccent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.lightAccent,
    onPrimary: AppColors.lightOnAccent,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    surfaceContainerLowest: AppColors.lightSurface,
    surfaceContainerLow: AppColors.lightSurfaceLow,
    surfaceContainer: AppColors.lightSurfaceLow,
    surfaceContainerHigh: AppColors.lightSurfaceHigh,
    surfaceContainerHighest: AppColors.lightSurfaceHigh,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    error: AppColors.lightError,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.darkAccent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.darkAccent,
    onPrimary: AppColors.darkOnAccent,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    surfaceContainerLowest: AppColors.darkSurfaceLow,
    surfaceContainerLow: AppColors.darkSurfaceLow,
    surfaceContainer: AppColors.darkSurfaceHigh,
    surfaceContainerHigh: AppColors.darkSurfaceHigh,
    surfaceContainerHighest: AppColors.darkSurfaceHigh,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    error: AppColors.darkError,
  );

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textTheme = _textTheme(scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary.withAlpha(31),
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHigh,
          disabledForegroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: onSurface),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: onSurface),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: onSurface),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: onSurface),
      bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.4, color: onSurface),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: onSurface),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: onSurface,
      ),
    );
  }
}
