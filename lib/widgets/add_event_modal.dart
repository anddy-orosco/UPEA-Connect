import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/notification_service.dart';

class AddEventModal extends StatefulWidget {
  final DateTime selectedDate;
  final Function(EventModel) onEventAdded;

  const AddEventModal({
    super.key,
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );

  String _selectedCategory = 'Tarea';
  Color _selectedColor = Colors.indigo;
  bool _enableNotification = true;

  final List<String> _categories = [
    'Tarea',
    'Examen',
    'Proyecto',
    'Laboratorio',
    'Otro',
  ];

  final List<Color> _availableColors = [
    Colors.indigo,
    Colors.redAccent,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
  ];

  void _submitData() {
    if (_titleController.text.trim().isEmpty) return;

    final eventDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final newEvent = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: eventDateTime,
      startTime: _startTime,
      endTime: _endTime,
      category: _selectedCategory,
      color: _selectedColor,
      isCompleted: false,
    );

    // Programar Notificación si está activa y la fecha es futura
    if (_enableNotification) {
      final notificationTime =
      eventDateTime.subtract(const Duration(hours: 24));

      if (notificationTime.isAfter(DateTime.now())) {
        NotificationService().scheduleNotification(
          id: newEvent.id.hashCode,
          title: '📌 Recordatorio Académico',
          body: 'Mañana vence: ${newEvent.title}',
          scheduledNotificationDateTime: notificationTime,
        );
      }
    }

    widget.onEventAdded(newEvent);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Nueva Tarea / Examen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de la tarea o examen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción / Notas (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Selector de Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),

            // Selectores de Hora de Inicio y Fin
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Inicio: ${_startTime.format(context)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing:
                    const Icon(Icons.access_time, color: Colors.indigo),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) {
                        setState(() => _startTime = picked);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fin: ${_endTime.format(context)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing:
                    const Icon(Icons.access_time_filled, color: Colors.indigo),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) {
                        setState(() => _endTime = picked);
                      }
                    },
                  ),
                ),
              ],
            ),

            // Switch para Notificaciones
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recordatorio (24h antes)'),
              value: _enableNotification,
              activeColor: Colors.indigo,
              onChanged: (val) => setState(() => _enableNotification = val),
            ),

            const SizedBox(height: 10),

            // Paleta de Colores
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableColors.length,
                itemBuilder: (context, index) {
                  final color = _availableColors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black87, width: 3)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Guardar Tarea',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}