import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_model.dart';

class FocusService {
  static const String _keyCoins = 'focus_coins';
  static const String _keyOnboarded = 'focus_onboarded';
  static const String _keyCommitmentDays = 'focus_commitment_days';
  static const String _keySubjects = 'focus_subjects';
  static const String _keyActiveSubjectId = 'focus_active_subject_id';

  // Claves para Tienda de Botánica (Plantas y Macetas)
  static const String _keyPurchasedSpecies = 'purchased_species';
  static const String _keyEquippedSpecies = 'equipped_species';
  static const String _keyPurchasedPots = 'purchased_pots';
  static const String _keyEquippedPot = 'equipped_pot';

  // --- VALIDACIONES DE TIENDA (Bonsái excluido) ---
  static const List<String> validSpecies = [
    'sp_oak',
    'sp_rose',
    'sp_sakura',
  ];

  static const List<String> validPots = [
    'pot_default',
    'pot_gold',
    'pot_japanese',
    'pot_volcanic',
  ];

  // Lista de colores predefinidos para asignar automáticamente a materias
  static const List<int> defaultColors = [
    0xFF5C6BC0, // Índigo
    0xFF26A69A, // Teal
    0xFFFF7043, // Naranja
    0xFFAB47BC, // Púrpura
    0xFF42A5F5, // Azul
    0xFF66BB6A, // Verde
    0xFFEC407A, // Rosa
  ];

  // Obtener saldo de monedas
  Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? 0;
  }

  // Sumar monedas
  Future<int> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyCoins) ?? 0;
    current += amount;
    await prefs.setInt(_keyCoins, current);
    return current;
  }

  // Restar monedas
  Future<bool> deductCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyCoins) ?? 0;
    if (current >= amount) {
      await prefs.setInt(_keyCoins, current - amount);
      return true;
    }
    return false;
  }

  // Verificar si el usuario ya realizó la configuración inicial
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  // Guardar configuración inicial
  Future<int> completeOnboarding({
    required String initialSubjectName,
    required int commitmentDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
    await prefs.setInt(_keyCommitmentDays, commitmentDays);

    // Crear primera materia
    final firstSubject = SubjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: initialSubjectName,
      colorValue: defaultColors[0],
      equippedSpecies: 'sp_oak',
      equippedPot: 'pot_default',
      plantProgress: 0.0,
    );

    await saveSubject(firstSubject);
    await setActiveSubjectId(firstSubject.id);

    // Regalo de monedas si se compromete más de 7 días
    int bonusCoins = 0;
    if (commitmentDays > 7) {
      bonusCoins = 500;
      await addCoins(bonusCoins);
    }

    return bonusCoins;
  }

  // Obtener lista de materias
  Future<List<SubjectModel>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_keySubjects) ?? [];
    return rawList.map((e) => SubjectModel.fromJson(e)).toList();
  }

  // Guardar o actualizar materia
  Future<void> saveSubject(SubjectModel subject) async {
    final prefs = await SharedPreferences.getInstance();
    List<SubjectModel> list = await getSubjects();
    int index = list.indexWhere((element) => element.id == subject.id);

    if (index >= 0) {
      list[index] = subject;
    } else {
      list.add(subject);
    }

    List<String> rawList = list.map((e) => e.toJson()).toList();
    await prefs.setStringList(_keySubjects, rawList);
  }

  // 🟢 NUEVO: Actualizar la planta (especie, maceta o progreso) de una materia específica
  Future<void> updateSubjectPlant({
    required String subjectId,
    String? equippedSpecies,
    String? equippedPot,
    double? plantProgress,
  }) async {
    List<SubjectModel> list = await getSubjects();
    int index = list.indexWhere((element) => element.id == subjectId);
    if (index >= 0) {
      final updated = list[index].copyWith(
        equippedSpecies: equippedSpecies,
        equippedPot: equippedPot,
        plantProgress: plantProgress,
      );
      await saveSubject(updated);
    }
  }

  // Sumar minutos de estudio a la materia activa
  Future<void> addMinutesToSubject(String subjectId, int minutes) async {
    List<SubjectModel> list = await getSubjects();
    int index = list.indexWhere((element) => element.id == subjectId);
    if (index >= 0) {
      list[index].totalMinutesStudied += minutes;
      await saveSubject(list[index]);
    }
  }

  // Materia seleccionada actualmente
  Future<String?> getActiveSubjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveSubjectId);
  }

  Future<void> setActiveSubjectId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveSubjectId, id);
  }

  // ==========================================
  // GESTIÓN DE PLANTAS Y MACETAS (TIENDA Y POR MATERIA)
  // ==========================================

  // --- ESPECIES DE PLANTAS ---
  Future<List<String>> getPurchasedSpecies() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPurchasedSpecies) ?? ['sp_oak'];

    // Filtra cualquier ID no válido
    final filtered = rawList.where((id) => validSpecies.contains(id)).toList();
    if (!filtered.contains('sp_oak')) {
      filtered.add('sp_oak');
    }

    if (filtered.length != rawList.length) {
      await prefs.setStringList(_keyPurchasedSpecies, filtered);
    }
    return filtered;
  }

  Future<bool> buySpecies(String speciesId, int price) async {
    if (!validSpecies.contains(speciesId)) return false;

    final purchased = await getPurchasedSpecies();
    if (purchased.contains(speciesId)) return true;

    final success = await deductCoins(price);
    if (success) {
      purchased.add(speciesId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyPurchasedSpecies, purchased);
      return true;
    }
    return false;
  }

  Future<void> equipSpecies(String speciesId) async {
    if (!validSpecies.contains(speciesId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedSpecies, speciesId);

    // Equipar en la materia activa actual
    final activeId = await getActiveSubjectId();
    if (activeId != null) {
      await updateSubjectPlant(subjectId: activeId, equippedSpecies: speciesId);
    }
  }

  Future<String> getEquippedSpecies() async {
    final activeId = await getActiveSubjectId();
    if (activeId != null) {
      final subjects = await getSubjects();
      final active = subjects.firstWhere((s) => s.id == activeId, orElse: () => subjects.first);
      if (validSpecies.contains(active.equippedSpecies)) {
        return active.equippedSpecies;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final species = prefs.getString(_keyEquippedSpecies) ?? 'sp_oak';

    if (!validSpecies.contains(species)) {
      await prefs.setString(_keyEquippedSpecies, 'sp_oak');
      return 'sp_oak';
    }
    return species;
  }

  // --- MACETAS ---
  Future<List<String>> getPurchasedPots() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPurchasedPots) ?? ['pot_default'];

    final filtered = rawList.where((id) => validPots.contains(id)).toList();
    if (!filtered.contains('pot_default')) {
      filtered.add('pot_default');
    }

    if (filtered.length != rawList.length) {
      await prefs.setStringList(_keyPurchasedPots, filtered);
    }
    return filtered;
  }

  Future<bool> buyPot(String potId, int price) async {
    if (!validPots.contains(potId)) return false;

    final purchased = await getPurchasedPots();
    if (purchased.contains(potId)) return true;

    final success = await deductCoins(price);
    if (success) {
      purchased.add(potId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyPurchasedPots, purchased);
      return true;
    }
    return false;
  }

  Future<void> equipPot(String potId) async {
    if (!validPots.contains(potId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedPot, potId);

    // Equipar en la materia activa actual
    final activeId = await getActiveSubjectId();
    if (activeId != null) {
      await updateSubjectPlant(subjectId: activeId, equippedPot: potId);
    }
  }

  Future<String> getEquippedPot() async {
    final activeId = await getActiveSubjectId();
    if (activeId != null) {
      final subjects = await getSubjects();
      final active = subjects.firstWhere((s) => s.id == activeId, orElse: () => subjects.first);
      if (validPots.contains(active.equippedPot)) {
        return active.equippedPot;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final pot = prefs.getString(_keyEquippedPot) ?? 'pot_default';

    if (!validPots.contains(pot)) {
      await prefs.setString(_keyEquippedPot, 'pot_default');
      return 'pot_default';
    }
    return pot;
  }
}