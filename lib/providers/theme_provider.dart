import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);
    if (savedMode != null) {
      _mode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.dark,
      );
      AppTheme.activeTheme = _mode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    AppTheme.activeTheme = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }
}
