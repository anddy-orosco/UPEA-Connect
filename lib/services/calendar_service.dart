import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/event_model.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final List<EventModel> _events = [];

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
      'endTime':
          '${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
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

  // Carga los eventos desde el backend
  Future<void> loadEvents() async {
    final token = await _getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> eventsJson = data['events'];
      _events.clear();
      _events.addAll(eventsJson.map((e) => _eventFromBackendJson(e)));
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Error al cargar eventos');
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

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_eventToBackendJson(event)),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      // ok() del backend devuelve el evento directo, sin envolver en 'data'
      _events.add(_eventFromBackendJson(data));
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Error al crear evento');
    }
  }

  Future<void> toggleEventCompletion(String eventId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final newValue = !_events[index].isCompleted;

    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/events/$eventId/complete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isCompleted': newValue}),
    );

    if (response.statusCode == 200) {
      _events[index] = _events[index].copyWith(isCompleted: newValue);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? data['error'] ?? 'Error al actualizar evento');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/events/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _events.removeWhere((e) => e.id == eventId);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? data['error'] ?? 'Error al eliminar evento');
    }
  }
}
