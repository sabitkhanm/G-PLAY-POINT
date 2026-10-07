import 'package:flutter/material.dart';
import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      surface: AppColors.lightSurface,
      onSurface: const Color(0xFF171923),
      error: AppColors.danger,
    );

    return _build(
      scheme: scheme,
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      surfaceAlt: AppColors.lightSurfaceAlt,
      border: AppColors.lightBorder,
      primary: AppColors.primary,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryDark,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDark,
      surface: AppColors.darkSurface,
      onSurface: const Color(0xFFF4F5F7),
      error: const Color(0xFFFF6B7A),
    );

    return _build(
      scheme: scheme,
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      surfaceAlt: AppColors.darkSurfaceAlt,
      border: AppColors.darkBorder,
      primary: AppColors.primaryDark,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color primary,
  }) {
    final text = scheme.onSurface;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Noto Sans Bengali', 'Noto Sans', 'sans-serif'],
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: TextStyle(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: text,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        color: text,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: text,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: text,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: text.withValues(alpha: .68),
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.card,
        shadowColor: Colors.black.withValues(alpha: brightness == Brightness.dark ? .18 : .08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        height: 72,
        indicatorColor: primary.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(color: border),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}
