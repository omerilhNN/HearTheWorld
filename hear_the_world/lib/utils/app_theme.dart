import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF0052CC);
  static const Color primaryDarkColor = Color(0xFF003D99);
  static const Color primaryLightColor = Color(0xFF4C9AFF);

  // Accent colors
  static const Color accentColor = Color(0xFFFF5630);
  static const Color accentLightColor = Color(0xFFFF8F73);

  // Background colors
  static const Color backgroundColor = Color(0xFFF4F5F7);
  static const Color surfaceColor = Colors.white;

  // Text colors - high contrast for accessibility
  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF505F79);
  static const Color textOnPrimary = Colors.white;

  // Feedback colors
  static const Color success = Color(0xFF36B37E);
  static const Color error = Color(0xFFFF5630);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF00B8D9);

  // Large touch targets for accessibility - size constants
  static const double touchTargetSize = 48.0;
  static const double largeTextSize = 18.0;
  static const double regularTextSize = 16.0;
  static const double smallTextSize = 14.0;

  static ThemeData lightTheme() {
    final base = ThemeData.light();

    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryDarkColor,
        secondary: accentColor,
        secondaryContainer: accentLightColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: error,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textOnPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textOnPrimary),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: largeTextSize,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: regularTextSize,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          minimumSize: const Size(88, touchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.nunito(
            fontSize: largeTextSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: primaryColor, size: 24),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
