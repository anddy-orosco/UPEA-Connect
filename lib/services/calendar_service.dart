import 'package:flutter/material.dart';
import '../models/event_model.dart';

class CalendarService {
  // Lista en memoria para simular la persistencia de datos
  final List<EventModel> _events = [
    EventModel(
      id: '1',
      title: 'Entrega de Proyecto Flutter',
      description: 'Presentación final del sistema UPEA Connect',
      date: DateTime.now(),
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
      category: 'Tarea',
      color: Colors.indigo,
    ),
    EventModel(
      id: '2',
      title: 'Examen de Base de Datos',
      description: 'Capítulos 1 al 4: Consultas SQL avanzadas',
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: const TimeOfDay(hour: 10, minute: 30),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      category: 'Examen',
      color: Colors.redAccent,
    ),
  ];

  // Obtener todos los eventos
  List<EventModel> getAllEvents() {
    return List.unmodifiable(_events);
  }

  // Obtener eventos filtrados por un día específico
  List<EventModel> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.date.year == day.year &&
          event.date.month == day.month &&
          event.date.day == day.day;
    }).toList();
  }

  // Agregar un nuevo evento
  void addEvent(EventModel newEvent) {
    _events.add(newEvent);
  }

  // Cambiar estado de completado
  void toggleEventCompletion(String id) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index] = _events[index].copyWith(
        isCompleted: !_events[index].isCompleted,
      );
    }
  }

  // Eliminar evento
  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
  }
}