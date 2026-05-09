// THEME LOCK: dark — source: user prompt (explicit dark blue glassmorphism request)
// Scaffold.backgroundColor = AppTheme.backgroundDark — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryContainer = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFF48CAE4);

  // ── Semantic colours ──────────────────────────────────────────
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);

  // ── Dark surfaces ─────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color background2Dark = Color(0xFF0D1426);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceVariantDark = Color(0xFF1C2333);
  static const Color glassSurface = Color(0x12FFFFFF);
  static const Color glassSurfaceVariant = Color(0x1EFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  // ── Subject card accent colours ───────────────────────────────
  static const Color subjectBlue = Color(0xFF1A3A6B);
  static const Color subjectPurple = Color(0xFF2D1B5E);
  static const Color subjectTeal = Color(0xFF0E3D3D);
  static const Color subjectGreen = Color(0xFF0F3B2A);
  static const Color subjectAmber = Color(0xFF3B2800);
  static const Color subjectRose = Color(0xFF3B0F1A);

  // ── Light surfaces ────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFBBDEFB),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF003543),
      onSecondaryContainer: Color(0xFFB3E5FC),
      surface: surfaceDark,
      onSurface: Color(0xFFE8EAF0),
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: Color(0xFFB0B8CC),
      error: error,
      onError: Colors.white,
      outline: Color(0xFF3A4460),
      outlineVariant: Color(0xFF1E2640),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EAF0),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EAF0),
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EAF0),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8EAF0),
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8EAF0),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8EAF0),
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB0B8CC),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFFD0D5E8),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFFB0B8CC),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8899AA),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8EAF0),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: Color(0xFFB0B8CC),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: Color(0xFF8899AA),
        ),
      ),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE8EAF0)),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8EAF0),
      ),
    ),
    cardTheme: CardThemeData(
      color: glassSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: glassSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1AFFFFFF),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: accent,
      unselectedItemColor: Color(0xFF6B7A99),
    ),
  );

  // ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surfaceLight,
      onSurface: const Color(0xFF1A1A2E),
      error: error,
      onError: Colors.white,
      outline: const Color(0xFFCCCCCC),
      outlineVariant: const Color(0xFFEEEEEE),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(),
  );
}
