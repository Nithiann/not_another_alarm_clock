import 'package:flutter/material.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _themeMode = StorageService.getThemeMode();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ColorScheme? _lightDynamic;
  ColorScheme? _darkDynamic;

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => AppTheme.lightTheme(_lightDynamic);
  ThemeData get darkTheme => AppTheme.darkTheme(_darkDynamic);

  void updateDynamicColors(ColorScheme? light, ColorScheme? dark) {
    final shouldNotify = light != _lightDynamic || dark != _darkDynamic;
    _lightDynamic = light;
    _darkDynamic = dark;

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await StorageService.setThemeMode(mode);
    notifyListeners();
  }
}

