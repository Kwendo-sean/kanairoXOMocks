import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _darkKey = 'dark_mode';
  static const _systemKey = 'follow_system';

  bool _isDarkMode = false;
  bool _followSystem = false;

  bool get isDarkMode => _isDarkMode;
  bool get followSystem => _followSystem;

  ThemeMode get themeMode {
    if (_followSystem) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _followSystem = prefs.getBool(_systemKey) ?? false;
    _isDarkMode = prefs.getBool(_darkKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
    notifyListeners();
  }

  Future<void> setFollowSystem(bool value) async {
    _followSystem = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemKey, value);
    notifyListeners();
  }
}
