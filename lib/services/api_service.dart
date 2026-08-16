import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // localhost funciona porque corremos en Chrome/Edge en la misma PC.
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
      // Antes: data['error']?['message'], que solo lee cuando 'error' es un
      // objeto anidado con 'message' adentro. Si el backend responde con
      // 'message' plano o con 'error' como string, esto devolvía null y
      // caía siempre al texto genérico 'Error al registrar'.
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

  // Sube una imagen al backend (Vercel Blob) y devuelve la URL pública
  // donde quedó guardada, para usarla en notas (elementos flotantes de
  // imagen). Recibe los bytes ya leídos (en vez de un dart:io File) para
  // que funcione igual en celular y en web, donde no existe un File real
  // detrás de la imagen elegida. mimeType (ej. 'image/jpeg') se manda como
  // Content-Type de la parte del archivo: sin esto, el backend no puede
  // saber qué tipo de archivo es a partir de solo los bytes y lo rechaza
  // con 'Tipo de archivo no permitido'. Si no se tiene el mimeType (puede
  // venir null de XFile.mimeType en algunos dispositivos), se asume
  // image/jpeg como valor por defecto razonable para fotos de galería.
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
