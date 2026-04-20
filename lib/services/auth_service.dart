import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthService {
  static const String _currentUserKey = 'current_user';
  static const String _usersKey = 'saved_users';
  static const String _isLoggedKey = 'is_logged_in';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar usuario actual
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedKey, true);

    // Guardar en lista de usuarios guardados
    final savedUsers = await getSavedUsers();
    savedUsers[user.email] = user.toJson();
    await prefs.setString(_usersKey, jsonEncode(savedUsers));
  }

  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool(_isLoggedKey) ?? false;

    if (!isLogged) return null;

    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;

    return UserModel.fromJson(jsonDecode(userJson));
  }

  static Future<Map<String, Map<String, String>>> getSavedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return {};

    return Map<String, Map<String, String>>.from(
        jsonDecode(usersJson).map((key, value) => MapEntry(key, Map<String, String>.from(value)))
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedKey);
    await prefs.remove(_currentUserKey);
    // Nota: NO removemos _usersKey para mantener las cuentas guardadas
  }

  static Future<void> switchToUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsers = await getSavedUsers();

    if (savedUsers.containsKey(email)) {
      await prefs.setString(_currentUserKey, jsonEncode(savedUsers[email]));
      await prefs.setBool(_isLoggedKey, true);
    }
  }
}