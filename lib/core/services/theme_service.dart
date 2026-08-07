import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._();

  static final ThemeService instance = ThemeService._();
  static const _preferenceKey = 'snow_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_preferenceKey) ?? false;
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    final nextMode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == nextMode) return;

    _themeMode = nextMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, enabled);
  }
}
