import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'local_cache.dart';
import '../models/event_model.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final List<EventModel> _events = [];

  /// true si la última carga de eventos salió del caché (sin internet).
  bool _fromCache = false;
  bool get isFromCache => _fromCache;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Convierte un color ARGB32 sin signo (32 bits) a un entero con signo,
  // porque la columna 'color' en PostgreSQL es un int32 con signo
  // y valores como 0xFF2196F3 (4282339765) exceden su rango máximo (2147483647).
  int _colorToSignedInt(Color color) {
    final unsigned = color.toARGB32();
    return unsigned > 0x7FFFFFFF ? unsigned - 0x100000000 : unsigned;
  }

  // Proceso inverso: reconstruye el color ARGB32 sin signo desde el
  // entero con signo que devuelve la base de datos.
  Color _colorFromSignedInt(int signedValue) {
    final unsigned = signedValue < 0 ? signedValue + 0x100000000 : signedValue;
    return Color(unsigned);
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> _eventToBackendJson(EventModel event) {
    // Combina date + startTime en un solo DateTime con hora completa
    final fullDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      event.startTime.hour,
      event.startTime.minute,
    );

    return {
      'title': event.title,
      'description': event.description,
      'date': fullDate.toIso8601String(),
      'endTime': _hhmm(event.endTime),
      'category': event.category,
      'color': _colorToSignedInt(event.color),
      'type': 'OTHER',
    };
  }

  EventModel _eventFromBackendJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    final endParts = (json['endTime'] as String? ?? '00:00').split(':');

    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      date: DateTime(date.year, date.month, date.day),
      startTime: TimeOfDay(hour: date.hour, minute: date.minute),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      category: json['category'] ?? '',
      color: _colorFromSignedInt(json['color'] as int? ?? -14251616),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // Formato "como lo devuelve el backend", para guardarlo en el caché local
  // y poder leerlo después con _eventFromBackendJson.
  Map<String, dynamic> _eventToCacheJson(EventModel e) {
    return {
      'id': e.id,
      'title': e.title,
      'description': e.description,
      'date': DateTime(e.date.year, e.date.month, e.date.day,
              e.startTime.hour, e.startTime.minute)
          .toIso8601String(),
      'endTime': _hhmm(e.endTime),
      'category': e.category,
      'color': _colorToSignedInt(e.color),
      'isCompleted': e.isCompleted,
    };
  }

  Future<void> _saveCache() async {
    await LocalCache.saveJson(
        'events', _events.map(_eventToCacheJson).toList());
  }

  void _requireOnline() {
    if (!ConnectivityService.instance.isOnline) {
      throw Exception(ConnectivityService.offlineWriteMessage);
    }
  }

  // Carga los eventos desde el backend. Si no hay internet, usa los que
  // quedaron guardados en el teléfono la última vez.
  Future<void> loadEvents() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      // limit=100 (el máximo del backend): sin esto solo llegaban 20 eventos.
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/events?limit=100'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = data['events'];
        _events.clear();
        _events.addAll(eventsJson.map((e) => _eventFromBackendJson(e)));
        _fromCache = false;
        ConnectivityService.instance.reportSuccess();
        await LocalCache.saveJson('events', eventsJson);
      } else {
        throw Exception(data['message'] ?? data['error'] ?? 'Error al cargar eventos');
      }
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;

      ConnectivityService.instance.reportFailure();
      final cached = await LocalCache.readJson('events');

      if (cached is List) {
        _events.clear();
        _events.addAll(cached
            .map((e) => _eventFromBackendJson(Map<String, dynamic>.from(e as Map))));
        _fromCache = true;
        return;
      }

      throw Exception(
          'Sin conexión y todavía no hay eventos guardados en este dispositivo.');
    }
  }

  List<EventModel> getAllEvents() => List.unmodifiable(_events);

  List<EventModel> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.date.year == day.year &&
          event.date.month == day.month &&
          event.date.day == day.day;
    }).toList();
  }

  Future<void> addEvent(EventModel event) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');
    _requireOnline();

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiService.baseUrl}/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(_eventToBackendJson(event)),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
        throw Exception(ConnectivityService.offlineWriteMessage);
      }
      rethrow;
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      // ok() del backend devuelve el evento directo, sin envolver en 'data'
      _events.add(_eventFromBackendJson(data));
      await _saveCache();
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Error al crear evento');
    }
  }

  Future<void> toggleEventCompletion(String eventId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    _requireOnline();

    final newValue = !_events[index].isCompleted;

    late final http.Response response;
    try {
      response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/events/$eventId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isCompleted': newValue}),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
        throw Exception(ConnectivityService.offlineWriteMessage);
      }
      rethrow;
    }

    if (response.statusCode == 200) {
      _events[index] = _events[index].copyWith(isCompleted: newValue);
      await _saveCache();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? data['error'] ?? 'Error al actualizar evento');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');
    _requireOnline();

    late final http.Response response;
    try {
      response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
        throw Exception(ConnectivityService.offlineWriteMessage);
      }
      rethrow;
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      _events.removeWhere((e) => e.id == eventId);
      await _saveCache();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? data['error'] ?? 'Error al eliminar evento');
    }
  }
}
