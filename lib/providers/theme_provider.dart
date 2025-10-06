import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Режим по умолчанию
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}