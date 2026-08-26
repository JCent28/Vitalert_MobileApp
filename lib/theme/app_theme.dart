import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand / Interactive Teal (Matching Stitch Design)
  static const Color primary = Color(0xFF007D79);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color primaryContainer = Color(0xFF007D79);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Background & Canvas Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFE2E8F0);
  static const Color surfaceContainerHigh = Color(0xFFCBD5E1);
  static const Color surfaceVariant = Color(0xFFE0F2FE);

  // Text / Typography
  static const Color onBackground = Color(0xFF0F172A);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Structural Dividers & Borders
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBackground = Color(0xFFF8FAFC);

  // Clinical Semantic Statuses
  // Normal / Stable (Emerald Green)
  static const Color secondary = Color(0xFF10B981);
  static const Color normalGreen = Color(0xFF10B981);
  static const Color normalGreenBg = Color(0xFFECFDF5);
  static const Color normalGreenBorder = Color(0xFFA7F3D0);

  // Warning (Amber)
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryContainer = Color(0xFFF59E0B);
  static const Color tertiaryContainerBg = Color(0xFFFFFBEB);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberBg = Color(0xFFFFFBEB);
  static const Color warningAmberBorder = Color(0xFFFDE68A);

  // Critical (Rose / Red)
  static const Color error = Color(0xFFEF4444);
  static const Color criticalRed = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  // Clinical Info (Blue)
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBlueBg = Color(0xFFEFF6FF);
  static const Color infoBlueBorder = Color(0xFFBFDBFE);
}

class AppTypography {
  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
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
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 44,
        height: 52 / 44,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricMono({
    Color color = AppColors.onSurface,
    FontWeight weight = FontWeight.w600,
    double fontSize = 14,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        height: 20 / 14,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle labelCaps({
    Color color = AppColors.onSurfaceVariant,
    FontWeight weight = FontWeight.w700,
    double fontSize = 11,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 0.05 * fontSize,
        height: 16 / 11,
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Extension on BuildContext for quick, adaptive responsive layout queries
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  
  bool get isVerySmallPhone => screenWidth < 350; // iPhone SE 1st gen, small Androids
  bool get isSmallPhone => screenWidth < 380;     // Standard compact phones
  bool get isStandardPhone => screenWidth >= 380 && screenWidth < 500;
  bool get isTablet => screenWidth >= 600;
  
  /// Scales base dimension proportionally to a 390px reference screen
  double scale(double baseValue, {double min = 0.82, double max = 1.25}) {
    final ratio = (screenWidth / 390.0).clamp(min, max);
    return baseValue * ratio;
  }

  /// Responsive horizontal content padding
  EdgeInsets get responsiveHorizontalPadding {
    if (isVerySmallPhone) return const EdgeInsets.symmetric(horizontal: 10.0);
    if (isSmallPhone) return const EdgeInsets.symmetric(horizontal: 12.0);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 24.0);
    return const EdgeInsets.symmetric(horizontal: 16.0);
  }

  /// Responsive page padding
  EdgeInsets get responsivePagePadding {
    if (isVerySmallPhone) return const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0);
    if (isSmallPhone) return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);
    return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
  }
}

