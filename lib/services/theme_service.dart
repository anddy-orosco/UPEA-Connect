import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Maneja qué tema está activo durante la sesión actual.
///
/// A propósito NO persiste el tema entre reinicios de la app: cada vez
/// que se abre (o se hace hot restart desde VS Code) arranca siempre
/// en el tema Predeterminado, sin importar cuál se haya elegido antes.
/// El usuario lo cambia manualmente desde el drawer cuando quiera.
class ThemeService extends ChangeNotifier {
  AppThemeVariant _variant = AppThemeVariant.predeterminado;

  AppThemeVariant get variant => _variant;
  ThemeData get themeData => AppTheme.themeFor(_variant);

  void setTheme(AppThemeVariant variant) {
    if (variant == _variant) return;
    _variant = variant;
    notifyListeners();
  }
}
