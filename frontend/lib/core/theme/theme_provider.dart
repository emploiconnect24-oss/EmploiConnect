import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/theme_constants.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;
  SharedPreferences? _prefs;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool isDark(BuildContext context) {
    if (_mode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _mode == AppThemeMode.dark;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(ThemeConstants.prefsThemeModeKey);
    if (saved != null) {
      _mode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs?.setString(ThemeConstants.prefsThemeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme(BuildContext context) async {
    final next = isDark(context) ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(next);
  }
}
