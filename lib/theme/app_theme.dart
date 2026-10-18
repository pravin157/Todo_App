import 'package:flutter/material.dart';

class ThemeColorOption {
  final String name;
  final Color primary;
  final Color secondary;
  final LinearGradient gradient;

  const ThemeColorOption({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.gradient,
  });
}

class AppThemeController extends ChangeNotifier {
  static final AppThemeController instance = AppThemeController._internal();
  AppThemeController._internal();

  static const List<ThemeColorOption> colorOptions = [
    ThemeColorOption(
      name: 'Cyber Indigo',
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      gradient: LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    ThemeColorOption(
      name: 'Neon Cyan',
      primary: Color(0xFF06B6D4),
      secondary: Color(0xFF3B82F6),
      gradient: LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    ThemeColorOption(
      name: 'Sunset Rose',
      primary: Color(0xFFF43F5E),
      secondary: Color(0xFFFB923C),
      gradient: LinearGradient(
        colors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    ThemeColorOption(
      name: 'Emerald Mint',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF06B6D4),
      gradient: LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    ThemeColorOption(
      name: 'Vibrant Purple',
      primary: Color(0xFFA855F7),
      secondary: Color(0xFFEC4899),
      gradient: LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  ThemeMode _themeMode = ThemeMode.dark;
  int _selectedColorIndex = 0;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  ThemeColorOption get currentAccent => colorOptions[_selectedColorIndex];
  int get selectedColorIndex => _selectedColorIndex;

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setAccentColor(int index) {
    if (index >= 0 && index < colorOptions.length) {
      _selectedColorIndex = index;
      notifyListeners();
    }
  }

  ThemeData getLightTheme() {
    final accent = currentAccent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent.primary,
        brightness: Brightness.light,
        primary: accent.primary,
        secondary: accent.secondary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: Colors.white,
          backgroundColor: accent.primary,
        ),
      ),
    );
  }

  ThemeData getDarkTheme() {
    final accent = currentAccent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent.primary,
        brightness: Brightness.dark,
        primary: accent.primary,
        secondary: accent.secondary,
        surface: const Color(0xFF131B2E),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: Colors.white,
          backgroundColor: accent.primary,
        ),
      ),
    );
  }
}
