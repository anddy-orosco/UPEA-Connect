import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static const String baseUrl = 'https://upea-connect-backend.vercel.app/api';

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
      throw Exception(data['message'] ?? data['error'] ?? 'Error al registrar');
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
      throw Exception(data['message'] ?? data['error'] ?? 'Error al iniciar sesión');
    }
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String token,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Error al verificar el código');
    }
  }

  static Future<Map<String, dynamic>> resendCode({
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Error al reenviar el código');
    }
  }

  static Future<String> uploadImage(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay sesión activa');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['url'] as String;
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Error al subir la imagen');
    }
  }
}