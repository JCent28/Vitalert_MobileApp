import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand / Interactive Teal
  static const Color primary = Color(0xFF006063);
  static const Color primaryContainer = Color(0xFF007B7F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFC4FDFF);
  static const Color primaryFixed = Color(0xFF96F1F5);

  // Background & Canvas Surfaces
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceVariant = Color(0xFFD3E4FE);

  // Text / Typography Ink
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF6E7979);

  // Structural Dividers & Borders
  static const Color outline = Color(0xFF6E7979);
  static const Color outlineVariant = Color(0xFFBDC9C9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBackground = Color(0xFFF1F5F9);

  // Clinical Semantic Statuses
  // Normal / Stable (Green)
  static const Color secondary = Color(0xFF1B6D24);
  static const Color normalGreen = Color(0xFF2E7D32);
  static const Color normalGreenBg = Color(0x1A1B6D24); // 10% opacity
  static const Color normalGreenBorder = Color(0x331B6D24);

  // Warning (Amber / Ochre)
  static const Color tertiary = Color(0xFF84451D);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberBg = Color(0x1AF59E0B); // 10% opacity
  static const Color warningAmberBorder = Color(0x33F59E0B);
  static const Color tertiaryContainer = Color(0xFFA25D33);
  static const Color tertiaryContainerBg = Color(0x1AA25D33);

  // Critical (Red)
  static const Color error = Color(0xFFBA1A1A);
  static const Color criticalRed = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorBg = Color(0x1ABA1A1A); // 10% opacity
  static const Color errorBorder = Color(0x33BA1A1A);
}

class AppTypography {
  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: color,
      );

  static TextStyle bodyLg({Color color = AppColors.onSurface, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: weight,
        height: 24 / 16,
        color: color,
      );

  static TextStyle bodyMd({
    Color color = AppColors.onSurfaceVariant,
    FontWeight weight = FontWeight.w400,
    double fontSize = 14,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        height: 20 / 14,
        color: color,
      );

  static TextStyle displayVitals({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 48,
        height: 56 / 48,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricMono({
    Color color = AppColors.onSurface,
    FontWeight weight = FontWeight.w500,
    double fontSize = 14,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: weight,
        height: 20 / 14,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle labelCaps({
    Color color = AppColors.onSurfaceVariant,
    FontWeight weight = FontWeight.w700,
    double fontSize = 12,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 0.05 * fontSize,
        height: 16 / 12,
        color: color,
      );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
