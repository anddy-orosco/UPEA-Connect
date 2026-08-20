import 'package:flutter/material.dart';

/// Los 4 temas seleccionables de la app, en el orden en que se muestran
/// en el selector: Predeterminado -> Oscuro -> Rosado -> UPEA.
enum AppThemeVariant { predeterminado, oscuro, rosado, upea }

class AppTheme {
  AppTheme._();

  static const Map<AppThemeVariant, String> nombres = {
    AppThemeVariant.predeterminado: 'Predeterminado',
    AppThemeVariant.oscuro: 'Modo oscuro',
    AppThemeVariant.rosado: 'Modo rosado',
    AppThemeVariant.upea: 'Tema UPEA',
  };

  /// Gradiente "de marca" para cada tema. Se usa en el swatch del
  /// selector y, más adelante, cuando migremos el header del drawer y
  /// otras pantallas para que lean del tema activo en vez de AppColors
  /// fijo. Es null para los temas que no tienen un gradiente propio.
  static const Map<AppThemeVariant, LinearGradient?> gradientes = {
    AppThemeVariant.predeterminado: null,
    AppThemeVariant.oscuro: null,
    AppThemeVariant.rosado: null,
    AppThemeVariant.upea: LinearGradient(
      colors: [Color(0xFF1D3E9C), Color(0xFFD1153B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  // ---- Predeterminado: el azul que ya traía la app (ColorScheme.fromSeed
  // con Colors.indigo), tal cual estaba antes de agregar el sistema de temas.
  static final ThemeData predeterminado = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  );

  // ---- Modo oscuro: negro real (no azul grisáceo), acentos discretos ----
  static final ThemeData oscuro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    cardColor: const Color(0xFF121212),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF121212)),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFEF4444),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFF121212),
      onSurface: Color(0xFFE5E7EB),
      error: Color(0xFFF87171),
      onError: Color(0xFF000000),
    ),
  );

  // ---- Modo rosado: rosa fuerte estilo Hello Kitty / My Melody ----
  static final ThemeData rosado = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFE1F0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF3E96),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    cardColor: const Color(0xFFFFC1E3),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF3E96),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFE63950),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFC1E3),
      onSurface: Color(0xFF7A0C43),
      error: Color(0xFFE63950),
      onError: Color(0xFFFFFFFF),
    ),
  );

  // ---- Tema UPEA: rojo y azul institucional mezclados de verdad ----
  static final ThemeData upea = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1D3E9C),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    cardColor: const Color(0xFFEFF1F7),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1D3E9C),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFD1153B),
      onSecondary: Color(0xFFFFFFFF),
      tertiary: Color(0xFF6B2A6E),
      surface: Color(0xFFEFF1F7),
      onSurface: Color(0xFF1F2937),
      error: Color(0xFFD1153B),
      onError: Color(0xFFFFFFFF),
    ),
  );

  static ThemeData themeFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.predeterminado:
        return predeterminado;
      case AppThemeVariant.oscuro:
        return oscuro;
      case AppThemeVariant.rosado:
        return rosado;
      case AppThemeVariant.upea:
        return upea;
    }
  }
}
