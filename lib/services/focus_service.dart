import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_model.dart';
import 'widget_sync_service.dart';

class FocusService {
  static const String _keyCoins = 'focus_coins';
  static const String _keyOnboarded = 'focus_onboarded';
  static const String _keyCommitmentDays = 'focus_commitment_days';
  static const String _keySubjects = 'focus_subjects';
  static const String _keyActiveSubjectId = 'focus_active_subject_id';

  // Claves para Tienda de Botánica (Plantas, Macetas y Adornos)
  static const String _keyPurchasedSpecies = 'purchased_species';
  static const String _keyEquippedSpecies = 'equipped_species';
  static const String _keyPurchasedPots = 'purchased_pots';
  static const String _keyEquippedPot = 'equipped_pot';
  static const String _keyPurchasedDecorations = 'focus_purchased_decorations';
  static const String _keyEquippedDecoration = 'focus_equipped_decoration';

  // Claves para el Sistema de Rachas Diarias (Estilo Duolingo)
  static const String _keyStreakCount = 'focus_streak_count';
  static const String _keyLastStudyDate = 'focus_last_study_date';

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

  static const List<String> validDecorations = [
    'dec_none',
    'dec_bees',
    'dec_butterflies',
    'dec_owl',
    'dec_stars',
    'dec_glitters',
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

  // Actualizar la planta (especie, maceta o progreso) de una materia específica
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
      await syncWidgetWithActiveState();
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
  // GESTIÓN DE PLANTAS, MACETAS Y ADORNOS
  // ==========================================

  // --- ESPECIES DE PLANTAS ---
  Future<List<String>> getPurchasedSpecies() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPurchasedSpecies) ?? ['sp_oak'];

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

    String? activeId = await getActiveSubjectId();
    final subjects = await getSubjects();
    if (activeId == null && subjects.isNotEmpty) {
      activeId = subjects.first.id;
      await setActiveSubjectId(activeId);
    }

    if (activeId != null) {
      await updateSubjectPlant(subjectId: activeId, equippedSpecies: speciesId);
    } else {
      await syncWidgetWithActiveState();
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

    String? activeId = await getActiveSubjectId();
    final subjects = await getSubjects();
    if (activeId == null && subjects.isNotEmpty) {
      activeId = subjects.first.id;
      await setActiveSubjectId(activeId);
    }

    if (activeId != null) {
      await updateSubjectPlant(subjectId: activeId, equippedPot: potId);
    } else {
      await syncWidgetWithActiveState();
    }
  }

  // ==========================================
  // SISTEMA DE RACHAS DE ESTUDIO (DUOLINGO STYLE)
  // ==========================================

  // Obtener la racha actual calculada según el último día de estudio
  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_keyStreakCount) ?? 1;
    final lastDateStr = prefs.getString(_keyLastStudyDate);
    if (lastDateStr == null) return streak;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime.tryParse(lastDateStr);
    if (lastDate == null) return streak;

    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final diff = today.difference(lastDay).inDays;

    // Si pasaron más de 1 día entero sin estudiar, la racha se reinicia a 0
    if (diff > 1) {
      await prefs.setInt(_keyStreakCount, 0);
      return 0;
    }
    return streak;
  }

  // Verifica si el usuario ya estudió el día de hoy
  Future<bool> hasStudiedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastStudyDate);
    if (lastDateStr == null) return false;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return lastDateStr == todayStr;
  }

  // Registra una sesión completada de Pomodoro y avanza la racha diaria
  Future<int> registerStudySession() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final lastDateStr = prefs.getString(_keyLastStudyDate);

    int currentStreak = prefs.getInt(_keyStreakCount) ?? 0;

    if (lastDateStr == null) {
      currentStreak = 1;
    } else {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) {
          // Ya estudió hoy, mantiene la racha activa
          if (currentStreak == 0) currentStreak = 1;
        } else if (diff == 1) {
          // Estudió ayer consecutivamente, ¡incrementa la racha!
          currentStreak++;
        } else {
          // Dejó pasar más de un día, reinicia en 1
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }
    }

    await prefs.setInt(_keyStreakCount, currentStreak);
    await prefs.setString(_keyLastStudyDate, todayStr);
    await syncWidgetWithActiveState();
    return currentStreak;
  }

  /// Sincroniza automáticamente los Home Widgets (iOS y Android) con el estado real
  Future<void> syncWidgetWithActiveState() async {
    try {
      final subjects = await getSubjects();
      final activeId = await getActiveSubjectId();
      SubjectModel? active;
      if (subjects.isNotEmpty) {
        active = subjects.firstWhere(
          (s) => s.id == activeId,
          orElse: () => subjects.first,
        );
      }
      final species = active?.equippedSpecies ?? await getEquippedSpecies();
      final pot = active?.equippedPot ?? await getEquippedPot();
      final progress = active?.plantProgress ?? 0.0;
      final subjectName = active?.name ?? 'Enfoque Académico';
      final streak = await getStreak();
      final studiedToday = await hasStudiedToday();

      await WidgetSyncService.syncWidgetData(
        species: species,
        pot: pot,
        progress: progress,
        subjectName: subjectName,
        streak: streak,
        studiedToday: studiedToday,
      );
    } catch (e) {
      debugPrint('Aviso al sincronizar widget desde FocusService: $e');
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

  // --- ADORNOS (ANIMACIONES LOTTIE) ---
  Future<List<String>> getPurchasedDecorations() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPurchasedDecorations) ?? ['dec_none'];

    final filtered = rawList.where((id) => validDecorations.contains(id)).toList();
    if (!filtered.contains('dec_none')) {
      filtered.add('dec_none');
    }

    if (filtered.length != rawList.length) {
      await prefs.setStringList(_keyPurchasedDecorations, filtered);
    }
    return filtered;
  }

  Future<bool> buyDecoration(String decorationId, int price) async {
    if (!validDecorations.contains(decorationId)) return false;

    final purchased = await getPurchasedDecorations();
    if (purchased.contains(decorationId)) return true;

    final success = await deductCoins(price);
    if (success) {
      purchased.add(decorationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyPurchasedDecorations, purchased);
      return true;
    }
    return false;
  }

  Future<void> equipDecoration(String decorationId) async {
    if (!validDecorations.contains(decorationId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedDecoration, decorationId);
  }

  Future<String> getEquippedDecoration() async {
    final prefs = await SharedPreferences.getInstance();
    final decoration = prefs.getString(_keyEquippedDecoration) ?? 'dec_none';

    if (!validDecorations.contains(decoration)) {
      await prefs.setString(_keyEquippedDecoration, 'dec_none');
      return 'dec_none';
    }
    return decoration;
  }
}