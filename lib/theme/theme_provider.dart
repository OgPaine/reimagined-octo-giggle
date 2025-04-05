import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProviderRiverpod = ChangeNotifierProvider<ThemeProvider>((_) => ThemeProvider());

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = Colors.blue;
  static const String _colorKey = 'primaryColor';

  ThemeProvider() {
    _loadColor();
  }

  Color get primaryColor => _primaryColor;

  ThemeData get themeData => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
        ),
      );

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_colorKey) ?? Colors.blue.value;
    _primaryColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> updatePrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }
}
