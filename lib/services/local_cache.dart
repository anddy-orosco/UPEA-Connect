import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Guardado local (en el teléfono) de datos del backend para usarlos sin internet.
/// Vive en lib/services/local_cache.dart
///
/// Las claves incluyen el correo del usuario, así cada cuenta tiene su propio
/// caché y no se mezclan al cambiar de cuenta.
class LocalCache {
  static Future<String> _key(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final email = (prefs.getString('user_email') ?? 'anon').toLowerCase();
    return 'cache:$email:$name';
  }

  static Future<void> saveJson(String name, Object json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _key(name), jsonEncode(json));
    } catch (_) {
      // El caché es "de cortesía": si falla, la app sigue funcionando.
    }
  }

  /// Devuelve el JSON guardado (Map o List), o null si no hay o está dañado.
  static Future<dynamic> readJson(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(await _key(name));
      if (raw == null) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(await _key(name));
    } catch (_) {}
  }
}
