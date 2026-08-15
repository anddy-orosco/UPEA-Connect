import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // localhost funciona porque corremos en Chrome/Edge en la misma PC.
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
    required String carrera,
    required String semestre,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'carrera': carrera,
        'semestre': semestre,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error']?['message'] ?? 'Error al registrar');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error']?['message'] ?? 'Error al iniciar sesión');
    }
  }
}