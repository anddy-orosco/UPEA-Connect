import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NotesService {
  static const String _notesKey = 'user_notes';

  static Future<List<NoteModel>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString(_notesKey);

    if (notesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(notesJson);
    return decoded.map((item) => NoteModel.fromJson(item)).toList();
  }

  static Future<void> saveNote(NoteModel note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    // Verificar si la nota ya existe (actualizar)
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.add(note);
    }

    final notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_notesKey, notesJson);
  }

  static Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();
    notes.removeWhere((note) => note.id == id);

    final notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_notesKey, notesJson);
  }

  static Future<void> updateNote(NoteModel note) async {
    await saveNote(note); // Reutilizamos saveNote que ya maneja actualización
  }
}