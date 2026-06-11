import 'package:flutter/material.dart';

class AppTheme {
  // Solar glass palette
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF8FE8DC);
  static const Color secondary = Color(0xFF2563EB);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentCoral = Color(0xFFF9736B);
  static const Color sunGlow = Color(0xFFFFC857);
  static const Color skyMist = Color(0xFFEAF8F6);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);

  // Background Colors
  static const Color lightBg = Color(0xFFF7FAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceTint = Color(0xFFEFF8F4);
  static const Color lightCream = Color(0xFFFFF2D7);
  static const Color lightSky = Color(0xFFE7F2FF);
  static const Color darkBg = Color(0xFF071518);
  static const Color darkerBg = Color(0xFF030B0D);
  static const Color cardDark = Color(0xFF0F2528);
  static const Color cardDarkAlt = Color(0xFF123036);
  static const Color cardLight = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB7CED5);
  static const Color textDark = Color(0xFF102326);
  static const Color textMuted = Color(0xFF60777B);
  static const Color textLight = Color(0xFFB7CED5);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF00796B).withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 16),
    ),
  ];

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      error: error,
      surfaceContainerHighest: lightSurfaceTint,
      surface: lightSurface,
      primaryContainer: Color(0xFFDDF7F1),
      secondaryContainer: Color(0xFFE1ECFF),
      tertiaryContainer: Color(0xFFFFE8B7),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Color(0xFF2E2100),
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: lightBg,
    cardColor: cardLight,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: textDark,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryDark,
      unselectedItemColor: Color(0xFF8CA0A4),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF0F7F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primary, width: 1.7),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      error: error,
      surface: cardDark,
      primaryContainer: Color(0xFF123F3A),
      secondaryContainer: Color(0xFF172D55),
      tertiaryContainer: Color(0xFF4A3510),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Color(0xFF2E2100),
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: darkBg,
    cardColor: cardDark,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDark,
      selectedItemColor: primaryLight,
      unselectedItemColor: Color(0xFF6D8A90),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        disabledBackgroundColor: const Color(0xFF244448),
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: primary.withValues(alpha: 0.24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    useMaterial3: true,
  );
}
