import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  static const String _storageKey = 'university_events';
  final List<EventModel> _events = [];

  // Carga los eventos guardados en el almacenamiento local
  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString(_storageKey);

    if (eventsJson != null) {
      final List<dynamic> decoded = jsonDecode(eventsJson);
      _events.clear();
      _events.addAll(decoded.map((item) => EventModel.fromMap(item)));
    }
  }

  // Guarda la lista actual de eventos en SharedPreferences
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_events.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
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
    _events.add(event);
    await _saveEvents();
  }

  Future<void> toggleEventCompletion(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(
        isCompleted: !_events[index].isCompleted,
      );
      await _saveEvents();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    await _saveEvents();
  }
}