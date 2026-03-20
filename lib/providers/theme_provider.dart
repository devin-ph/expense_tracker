import 'package:flutter/foundation.dart';
import '../models/index.dart';

// Theme notifier
class ThemeNotifier extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  void setThemeMode(AppThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme() {
    switch (_themeMode) {
      case AppThemeMode.light:
        _themeMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        _themeMode = AppThemeMode.system;
        break;
      case AppThemeMode.system:
        _themeMode = AppThemeMode.light;
        break;
    }
    notifyListeners();
  }
}
