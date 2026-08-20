import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Maneja qué tema está activo y lo persiste en SharedPreferences
/// para que se mantenga entre sesiones (igual que auth_token).
class ThemeService extends ChangeNotifier {
  static const _prefsKey = 'app_theme_variant';

  AppThemeVariant _variant = AppThemeVariant.predeterminado;

  AppThemeVariant get variant => _variant;
  ThemeData get themeData => AppTheme.themeFor(_variant);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _variant = AppThemeVariant.values.firstWhere(
        (v) => v.name == saved,
        orElse: () => AppThemeVariant.predeterminado,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeVariant variant) async {
    if (variant == _variant) return;
    _variant = variant;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, variant.name);
  }
}
