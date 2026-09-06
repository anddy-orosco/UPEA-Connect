import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Maneja qué tema está activo y lo persiste en SharedPreferences
/// para que la preferencia se mantenga entre reinicios de la aplicación.
class ThemeService extends ChangeNotifier {
  static const _prefsKey = 'app_theme_variant';

  AppThemeVariant _variant = AppThemeVariant.predeterminado;

  AppThemeVariant get variant => _variant;
  ThemeData get themeData => AppTheme.themeFor(_variant);

  /// Carga el tema guardado previamente en SharedPreferences al iniciar la app.
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        _variant = AppThemeVariant.values.firstWhere(
              (v) => v.name == saved,
          orElse: () => AppThemeVariant.predeterminado,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar el tema guardado: $e');
    }
  }

  /// Cambia el tema actual y lo guarda en SharedPreferences.
  Future<void> setTheme(AppThemeVariant variant) async {
    if (variant == _variant) return;
    _variant = variant;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, variant.name);
    } catch (e) {
      debugPrint('Error al guardar el tema: $e');
    }
  }
}