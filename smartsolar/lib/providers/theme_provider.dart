import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  light, // Light theme
  dark, // Dark theme
  system, // Follow system theme
}

/// Theme provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  AppThemeMode _currentThemeMode = AppThemeMode.system;
  bool _useAmoled = false; // Extra dark AMOLED mode for OLED screens

  ThemeProvider() {
    _loadThemeMode();
  }

  /// Get current theme mode
  AppThemeMode get currentThemeMode => _currentThemeMode;

  /// Check if using AMOLED mode
  bool get useAmoled => _useAmoled;

  /// Get current theme mode as ThemeMode enum for MaterialApp
  ThemeMode get themeMode {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Check if dark mode is currently active
  bool get isDarkMode {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  /// Get current brightness
  Brightness get currentBrightness {
    return isDarkMode ? Brightness.dark : Brightness.light;
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentThemeMode == mode) return;

    _currentThemeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  /// Toggle between light and dark mode (ignores system)
  Future<void> toggleTheme() async {
    if (_currentThemeMode == AppThemeMode.light) {
      await setThemeMode(AppThemeMode.dark);
    } else if (_currentThemeMode == AppThemeMode.dark) {
      await setThemeMode(AppThemeMode.light);
    } else {
      // If system, check current brightness and switch to opposite
      final isCurrentlyDark = isDarkMode;
      await setThemeMode(
          isCurrentlyDark ? AppThemeMode.light : AppThemeMode.dark);
    }
  }

  /// Enable/Disable AMOLED mode (extra dark background for OLED screens)
  Future<void> setAmoledMode(bool enabled) async {
    if (_useAmoled == enabled) return;

    _useAmoled = enabled;
    await _saveThemeMode();
    notifyListeners();
  }

  /// Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeModeString = prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _currentThemeMode = AppThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeString,
          orElse: () => AppThemeMode.system,
        );
      }

      _useAmoled = prefs.getBool('use_amoled') ?? false;
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }

    notifyListeners();
  }

  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _currentThemeMode.toString());
      await prefs.setBool('use_amoled', _useAmoled);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Get light theme data
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        error: _errorColor,
        surface: Colors.white,
        primaryContainer: Color(0xFFDDF7F1),
        secondaryContainer: Color(0xFFE1ECFF),
      ),
      scaffoldBackgroundColor: _lightBackgroundColor,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDarkColor,
        titleTextStyle: TextStyle(
          color: _textDarkColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _textDarkColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }

  /// Get dark theme data
  ThemeData get darkTheme {
    final backgroundColor = _useAmoled ? Colors.black : _darkBackgroundColor;
    final cardColor = _useAmoled ? const Color(0xFF0A0A0A) : _darkCardColor;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: _primaryColor,
        secondary: _secondaryColor,
        error: _errorColor,
        surface: _darkCardColor,
        primaryContainer: Color(0xFF123F3A),
        secondaryContainer: Color(0xFF172D55),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: Colors.grey.shade800,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _textLightColor,
        titleTextStyle: TextStyle(
          color: _textLightColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _textLightColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
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
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: cardColor,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        backgroundColor: cardColor,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }

  /// Get dynamic theme based on current mode
  ThemeData get currentTheme {
    return isDarkMode ? darkTheme : lightTheme;
  }

  /// Get text theme colors
  Color get textPrimaryColor => isDarkMode ? _textLightColor : _textDarkColor;

  Color get textSecondaryColor =>
      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

  Color get textHintColor =>
      isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;

  /// Get status colors
  Color get successColor => _successColor;
  Color get warningColor => _warningColor;
  Color get errorColor => _errorColor;
  Color get infoColor => _infoColor;

  /// Get gradient backgrounds
  List<Color> get primaryGradient {
    return isDarkMode
        ? [const Color(0xFF8FE8DC), const Color(0xFF14B8A6)]
        : [const Color(0xFF14B8A6), const Color(0xFF0F766E)];
  }

  List<Color> get backgroundGradient {
    return isDarkMode
        ? [const Color(0xFF030B0D), const Color(0xFF123036)]
        : [const Color(0xFFFFF2D7), const Color(0xFFE7F2FF)];
  }

  /// Get card shadow
  List<BoxShadow> get cardShadow {
    if (isDarkMode) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }
  }

  /// Get status bar style
  Brightness get statusBarBrightness {
    return isDarkMode ? Brightness.light : Brightness.dark;
  }
}

// ========== COLOR CONSTANTS ==========

const Color _primaryColor = Color(0xFF14B8A6);
const Color _secondaryColor = Color(0xFF2563EB);
const Color _successColor = Color(0xFF10B981);
const Color _warningColor = Color(0xFFF59E0B);
const Color _errorColor = Color(0xFFEF4444);
const Color _infoColor = Color(0xFF38BDF8);

const Color _textDarkColor = Color(0xFF102326);
const Color _textLightColor = Color(0xFFFFFFFF);

const Color _lightBackgroundColor = Color(0xFFF7FAF7);
const Color _darkBackgroundColor = Color(0xFF071518);
const Color _darkCardColor = Color(0xFF0F2528);

// ========== EXTENSION FOR BUILD CONTEXT ==========

/// Extension to easily access theme provider from BuildContext
extension ThemeProviderExtension on BuildContext {
  ThemeProvider get themeProvider => watch<ThemeProvider>();

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  Color get successColor => _successColor;
  Color get warningColor => _warningColor;
  Color get errorColor => _errorColor;
  Color get infoColor => _infoColor;

  TextStyle get headingStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  TextStyle get subheadingStyle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  TextStyle get bodyStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  TextStyle get captionStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.grey,
      );
}
