import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';

class NotesService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _floatingElementToBackendJson(
      FloatingElement el) {
    return {
      'type': el.isImage ? 'IMAGE' : 'TEXT',
      'positionX': el.position.dx,
      'positionY': el.position.dy,
      'width': el.width,
      'height': el.height,
      'text': el.text,
      if (el.isImage && el.imagePath != null) 'imageUrl': el.imagePath,
    };
  }

  static FloatingElement _floatingElementFromBackendJson(
      Map<String, dynamic> json) {
    return FloatingElement(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      position: Offset(
        (json['positionX'] as num?)?.toDouble() ?? 0.0,
        (json['positionY'] as num?)?.toDouble() ?? 0.0,
      ),
      width: (json['width'] as num?)?.toDouble() ?? 180.0,
      height: (json['height'] as num?)?.toDouble() ?? 140.0,
      text: json['text'] ?? '',
      isImage: json['type'] == 'IMAGE',
      imagePath: json['imageUrl'],
    );
  }

  static NotePageModel _pageFromBackendJson(Map<String, dynamic> json) {
    return NotePageModel(
      id: json['id']?.toString(),
      pageIndex: json['pageIndex'] as int? ?? 0,
      textContent: json['textContent'] ?? '',
      floatingElements: (json['floatingElements'] as List<dynamic>?)
              ?.map((e) =>
                  _floatingElementFromBackendJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static NoteModel _noteFromBackendJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      courseName: json['courseName'],
      pages: (json['pages'] as List<dynamic>?)
              ?.map((p) => _pageFromBackendJson(p as Map<String, dynamic>))
              .toList() ??
          [NotePageModel()],
    );
  }

  static Map<String, dynamic> _noteToBackendJson(NoteModel note) {
    return {
      'title': note.title,
      'content': note.content,
      'courseName': note.courseName,
      'pages': note.pages
          .map((p) => {
                'pageIndex': p.pageIndex,
                'textContent': p.textContent,
                'floatingElements': p.floatingElements
                    .map((e) => _floatingElementToBackendJson(e))
                    .toList(),
              })
          .toList(),
    };
  }

  // Devuelve la lista de notas (sin páginas/elementos flotantes,
  // el backend no los incluye en el listado por rendimiento).
  static Future<List<NoteModel>> getNotes() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notes'),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> notesJson = data['notes'];
      return notesJson.map((n) => _noteFromBackendJson(n)).toList();
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Error al cargar notas');
    }
  }

  // Trae una nota específica completa, con todas sus páginas y
  // elementos flotantes (necesario antes de abrir el editor).
  static Future<NoteModel> getNoteById(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notes/$id'),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return _noteFromBackendJson(data);
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Error al cargar el apunte');
    }
  }

  // Crea o actualiza una nota. Si note.id ya existe en el backend, usa
  // PUT; si es una nota nueva (creada localmente antes de guardar), usa POST.
  static Future<NoteModel> saveNote(NoteModel note, {bool isNew = true}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final body = jsonEncode(_noteToBackendJson(note));

    final response = isNew
        ? await http.post(
            Uri.parse('${ApiService.baseUrl}/notes'),
            headers: _headers(token),
            body: body,
          )
        : await http.put(
            Uri.parse('${ApiService.baseUrl}/notes/${note.id}'),
            headers: _headers(token),
            body: body,
          );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _noteFromBackendJson(data);
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Error al guardar el apunte');
    }
  }

  static Future<void> deleteNote(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/notes/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(
          data['message'] ?? data['error'] ?? 'Error al eliminar el apunte');
    }
  }
}
