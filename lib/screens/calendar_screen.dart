import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event_model.dart';
import '../services/calendar_service.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_modal.dart';
import '../widgets/countdown_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadInitialData();
  }

  // Carga inicial de eventos desde el backend. Antes, si loadEvents()
  // fallaba (sin internet, token vencido, error del servidor), no había
  // catch: la excepción quedaba sin manejar y _isLoading nunca pasaba a
  // false, dejando el spinner girando para siempre sin ningún aviso.
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await _calendarService.loadEvents();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'No se pudieron cargar los eventos: $e';
        });
      }
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _calendarService.getEventsForDay(day);
  }

  // Obtiene el evento/evaluación pendiente más cercano en el futuro
  EventModel? _getNextUpcomingEvent() {
    final now = DateTime.now();
    final upcoming = _calendarService
        .getAllEvents()
        .where((e) => e.date.isAfter(now) && !e.isCompleted)
        .toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.first;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _openAddEventModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEventModal(
        selectedDate: _selectedDay ?? DateTime.now(),
        onEventAdded: (newEvent) async {
          try {
            await _calendarService.addEvent(newEvent);
            if (mounted) setState(() {});
          } catch (e) {
            _showError('No se pudo crear el evento: $e');
          }
        },
      ),
    );
  }

  Future<void> _handleToggleComplete(EventModel event) async {
    try {
      await _calendarService.toggleEventCompletion(event.id);
      if (mounted) setState(() {});
    } catch (e) {
      _showError('No se pudo actualizar el evento: $e');
    }
  }

  Future<void> _handleDelete(EventModel event) async {
    try {
      await _calendarService.deleteEvent(event.id);
      if (mounted) setState(() {});
    } catch (e) {
      _showError('No se pudo eliminar el evento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
    final upcomingEvent = _getNextUpcomingEvent();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // Se eliminó el appBar para no duplicar la barra superior con HomeScreen
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      )
          : _loadError != null
          ? _buildLoadErrorState()
          : Column(
        children: [
          // Widget de Cuenta Regresiva (Solo si hay eventos pendientes)
          if (upcomingEvent != null)
            CountdownCard(upcomingEvent: upcomingEvent),

          // Tarjeta contenedor del Calendario
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TableCalendar<EventModel>(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.twoWeeks: '2 Semanas',
                CalendarFormat.week: 'Semana',
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonShowsNext: false,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                formatButtonDecoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                leftChevronIcon:
                const Icon(Icons.chevron_left, color: Colors.indigo),
                rightChevronIcon:
                const Icon(Icons.chevron_right, color: Colors.indigo),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle:
                const TextStyle(fontWeight: FontWeight.w500),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigoAccent,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                singleMarkerBuilder: (context, date, event) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.color,
                    ),
                    width: 7.0,
                    height: 7.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 1.5,
                      vertical: 4.0,
                    ),
                  );
                },
              ),
            ),
          ),

          // Título de la sección
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Tareas y Eventos (${selectedEvents.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),

          // Lista de Tareas
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note,
                      size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text(
                    'No hay tareas ni eventos programados.',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return EventCard(
                  event: event,
                  onToggleComplete: () => _handleToggleComplete(event),
                  onDelete: () => _handleDelete(event),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEventModal,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Tarea',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Se muestra en vez del calendario si la carga inicial de eventos falló,
  // con un botón para reintentar en vez de dejar la pantalla vacía o
  // colgada sin ninguna explicación.
  Widget _buildLoadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
