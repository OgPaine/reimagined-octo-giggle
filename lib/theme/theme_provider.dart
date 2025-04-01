import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _colorKey = 'primaryColor';

  Color _primaryColor = Colors.blue;

  /// Accessor for primary color.
  Color get primaryColor => _primaryColor;

  /// Complete theme data for the app.
  ThemeData get themeData => ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(_primaryColor),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: _primaryColor,
        ),
      );

  /// Constructor calls the loader.
  ThemeProvider() {
    _loadThemeColor();
  }

  /// Loads the theme color from SharedPreferences.
  Future<void> _loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColorValue = prefs.getInt(_colorKey);

      if (savedColorValue != null) {
        _primaryColor = Color(savedColorValue);
        debugPrint('[DEBUG] Loaded theme color from prefs: $_primaryColor');
      } else {
        debugPrint('[DEBUG] No saved theme color found. Using default: $_primaryColor');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[ERROR] Failed to load theme color: $e');
    }
  }

  /// Updates the primary color, saves it to prefs, and notifies listeners.
  Future<void> updatePrimaryColor(Color color) async {
    try {
      _primaryColor = color;
      notifyListeners();
      debugPrint('[DEBUG] Updated theme color: $_primaryColor');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_colorKey, color.toARGB32());
      debugPrint('[DEBUG] Saved theme color to prefs: ${color.toARGB32()}');
    } catch (e) {
      debugPrint('[ERROR] Failed to save theme color: $e');
    }
  }
}