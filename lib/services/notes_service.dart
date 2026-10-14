import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'local_cache.dart';
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

  static void _requireOnline() {
    if (!ConnectivityService.instance.isOnline) {
      throw Exception(ConnectivityService.offlineWriteMessage);
    }
  }

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

  // Convierte un fallo de red en un mensaje claro para el usuario.
  static Never _throwOffline() {
    ConnectivityService.instance.reportFailure();
    throw Exception(ConnectivityService.offlineWriteMessage);
  }

  // Descarga en segundo plano cada nota completa (con páginas y elementos
  // flotantes) para poder abrirla sin internet. Solo baja las que cambiaron.
  static Future<void> _prefetchFullNotes(
      List<dynamic> notesJson, String token) async {
    for (final raw in notesJson.take(60)) {
      final n = Map<String, dynamic>.from(raw as Map);
      final id = n['id']?.toString();
      if (id == null) continue;

      final cached = await LocalCache.readJson('note_$id');
      if (cached is Map && cached['updatedAt'] == n['updatedAt']) continue;

      try {
        final res = await http
            .get(Uri.parse('${ApiService.baseUrl}/notes/$id'),
                headers: _headers(token))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          await LocalCache.saveJson('note_$id', jsonDecode(res.body));
        }
      } catch (_) {
        return; // si hay problemas de red, se deja para la próxima vez
      }
    }
  }

  // Devuelve la lista de notas (sin páginas/elementos flotantes,
  // el backend no los incluye en el listado por rendimiento).
  // Sin internet, devuelve las que quedaron guardadas en el teléfono.
  static Future<List<NoteModel>> getNotes() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      // limit=100 (el máximo del backend): sin esto solo llegaban 20 notas.
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/notes?limit=100'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> notesJson = data['notes'];
        ConnectivityService.instance.reportSuccess();
        await LocalCache.saveJson('notes', notesJson);
        unawaited(_prefetchFullNotes(notesJson, token));
        return notesJson
            .map((n) => _noteFromBackendJson(Map<String, dynamic>.from(n as Map)))
            .toList();
      } else {
        throw Exception(
            data['message'] ?? data['error'] ?? 'Error al cargar notas');
      }
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;

      ConnectivityService.instance.reportFailure();
      final cached = await LocalCache.readJson('notes');
      if (cached is List) {
        return cached
            .map((n) => _noteFromBackendJson(Map<String, dynamic>.from(n as Map)))
            .toList();
      }
      throw Exception(
          'Sin conexión y todavía no hay notas guardadas en este dispositivo.');
    }
  }

  // Trae una nota específica completa, con todas sus páginas y
  // elementos flotantes (necesario antes de abrir el editor).
  // Sin internet, usa la copia guardada (si la nota ya se abrió o se
  // descargó antes con conexión).
  static Future<NoteModel> getNoteById(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/notes/$id'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ConnectivityService.instance.reportSuccess();
        await LocalCache.saveJson('note_$id', data);
        return _noteFromBackendJson(data);
      } else {
        throw Exception(
            data['message'] ?? data['error'] ?? 'Error al cargar el apunte');
      }
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;

      ConnectivityService.instance.reportFailure();
      final cached = await LocalCache.readJson('note_$id');
      if (cached is Map) {
        return _noteFromBackendJson(Map<String, dynamic>.from(cached));
      }
      throw Exception(
          'Esta nota aún no está guardada para verla sin conexión. Ábrela una vez con internet.');
    }
  }

  // Crea o actualiza una nota. Si note.id ya existe en el backend, usa
  // PUT; si es una nota nueva (creada localmente antes de guardar), usa POST.
  static Future<NoteModel> saveNote(NoteModel note, {bool isNew = true}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');
    _requireOnline();

    final body = jsonEncode(_noteToBackendJson(note));

    late final http.Response response;
    try {
      response = isNew
          ? await http
              .post(
                Uri.parse('${ApiService.baseUrl}/notes'),
                headers: _headers(token),
                body: body,
              )
              .timeout(const Duration(seconds: 30))
          : await http
              .put(
                Uri.parse('${ApiService.baseUrl}/notes/${note.id}'),
                headers: _headers(token),
                body: body,
              )
              .timeout(const Duration(seconds: 30));
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) _throwOffline();
      rethrow;
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final saved = _noteFromBackendJson(data);
      await LocalCache.saveJson('note_${saved.id}', data);
      return saved;
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Error al guardar el apunte');
    }
  }

  static Future<void> deleteNote(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');
    _requireOnline();

    late final http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiService.baseUrl}/notes/$id'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) _throwOffline();
      rethrow;
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(
          data['message'] ?? data['error'] ?? 'Error al eliminar el apunte');
    }

    await LocalCache.remove('note_$id');
  }
}
