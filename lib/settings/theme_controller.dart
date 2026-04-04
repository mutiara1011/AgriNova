import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool isDark = false;

  void toggleTheme(bool value) {
    isDark = value;
    notifyListeners();
  }

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;
}
