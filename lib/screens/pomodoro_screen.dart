import 'dart:async';
import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../services/focus_service.dart';
import '../widgets/growing_plant_widget.dart';
import 'focus_store_screen.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int _workTime = 25 * 60;
  static const int _breakTime = 5 * 60;

  int _timeLeft = _workTime;
  bool _isRunning = false;
  bool _isWorkMode = true;
  Timer? _timer;

  // Variable para pruebas manuales (override)
  double? _debugProgress;

  final FocusService _focusService = FocusService();
  int _coins = 0;
  List<SubjectModel> _subjects = [];
  SubjectModel? _activeSubject;

  String _equippedPot = 'pot_default';
  String _equippedDecoration = 'dec_none';
  String _equippedSpecies = 'sp_oak';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingAndLoadData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkOnboardingAndLoadData() async {
    final bool onboarded = await _focusService.isOnboarded();
    if (!onboarded && mounted) {
      await _showOnboardingDialog();
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    final coins = await _focusService.getCoins();
    final subjects = await _focusService.getSubjects();
    final activeId = await _focusService.getActiveSubjectId();

    final pot = await _focusService.getEquippedPot();
    final species = await _focusService.getEquippedSpecies();

    subjects.sort((a, b) => b.totalMinutesStudied.compareTo(a.totalMinutesStudied));

    SubjectModel? active;
    if (subjects.isNotEmpty) {
      active = subjects.firstWhere(
            (s) => s.id == activeId,
        orElse: () => subjects.first,
      );
    }

    if (mounted) {
      setState(() {
        _coins = coins;
        _subjects = subjects;
        _activeSubject = active;
        _equippedPot = pot;
        _equippedSpecies = species;
      });
    }
  }

  Future<void> _showOnboardingDialog() async {
    final textController = TextEditingController(text: 'Programación I');
    double commitmentDays = 7;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isBonusEligible = commitmentDays > 7;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Bienvenido al Enfoque!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Qué materia vas a estudiar primero?',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Cálculo, Derecho, Física',
                        prefixIcon: const Icon(Icons.book_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Días de compromiso:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${commitmentDays.toInt()} días',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: commitmentDays,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.indigo,
                      onChanged: (val) {
                        setModalState(() {
                          commitmentDays = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBonusEligible
                            ? Colors.amber.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBonusEligible
                              ? Colors.amber.shade400
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBonusEligible
                                ? Icons.card_giftcard_rounded
                                : Icons.info_outline_rounded,
                            color: isBonusEligible
                                ? Colors.amber.shade900
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isBonusEligible
                                  ? '🎉 ¡Genial! Por elegir más de 7 días recibes 100 Monedas de regalo.'
                                  : '💡 Comprométete más de 7 días para ganar un regalo de 100 Monedas.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isBonusEligible
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isBonusEligible
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final name = textController.text.trim().isEmpty
                        ? 'Materia General'
                        : textController.text.trim();

                    final bonus = await _focusService.completeOnboarding(
                      initialSubjectName: name,
                      commitmentDays: commitmentDays.toInt(),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (bonus > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎁 ¡Recibiste $bonus monedas de regalo!'),
                            backgroundColor: Colors.amber.shade800,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Comenzar Mi Enfoque'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    int selectedColor = FocusService.defaultColors[
    _subjects.length % FocusService.defaultColors.length];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva Materia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la materia',
                  hintText: 'Ej. Álgebra, Historia',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  final newSub = SubjectModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text.trim(),
                    colorValue: selectedColor,
                  );
                  await _focusService.saveSubject(newSub);
                  await _focusService.setActiveSubjectId(newSub.id);
                  if (context.mounted) Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() {
        _isRunning = true;
        _debugProgress = null; // Al iniciar el timer real, vuelve a sincronizarse automáticamente
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _completeSession();
        }
      });
    }
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    if (_isWorkMode && _activeSubject != null) {
      await _focusService.addCoins(25);
      await _focusService.addMinutesToSubject(_activeSubject!.id, 25);
    }

    _switchMode();
    _loadData();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _debugProgress = null;
      _timeLeft = _isWorkMode ? _workTime : _breakTime;
    });
  }

  void _switchMode() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _debugProgress = null;
      _isWorkMode = !_isWorkMode;
      _timeLeft = _isWorkMode ? _workTime : _breakTime;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final maxTime = _isWorkMode ? _workTime : _breakTime;

    // Calcula el progreso real del temporizador o toma el valor de prueba si existe
    final realProgress = 1.0 - (_timeLeft / maxTime);
    final displayProgress = _debugProgress ?? realProgress;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo Dinámica con animación Día/Noche
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              child: Image.asset(
                _isWorkMode
                    ? 'assets/images/bg_day.jpeg'
                    : 'assets/images/bg_night.jpeg',
                key: ValueKey<bool>(_isWorkMode),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _isWorkMode ? Colors.lightBlue : Colors.indigo.shade900,
                ),
              ),
            ),
          ),

          // 2. Capa de sombra para lecturabilidad
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.18),
            ),
          ),

          // 3. Interfaz Principal
          SafeArea(
            child: Column(
              children: [
                // Barra Superior
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enfoque Académico',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                            tooltip: 'Tienda de Enfoque',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FocusStoreScreen()),
                              );
                              _loadData();
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: Colors.amber, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '$_coins',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selector de Materias
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSubjectSelector(),
                ),

                // Estado Día / Noche
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _isWorkMode ? '☀️ Modo Estudio (Día)' : '🌙 Modo Descanso (Noche)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                    ),
                  ),
                ),

                // Área de la Planta en Crecimiento
                Expanded(
                  child: Center(
                    child: GrowingPlantWidget(
                      progress: displayProgress,
                      equippedPot: _equippedPot,
                      equippedDecoration: _equippedDecoration,
                      equippedSpecies: _equippedSpecies,
                    ),
                  ),
                ),

                // Panel para Pruebas Rápidas (Debug Controls)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.nature_rounded, size: 18),
                        label: const Text('Fase +', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            double current = _debugProgress ?? realProgress;
                            _debugProgress = (current + 0.25) > 1.0 ? 0.0 : current + 0.25;
                          });
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWorkMode ? Colors.indigo : Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: Icon(_isWorkMode ? Icons.nights_stay : Icons.wb_sunny, size: 18),
                        label: Text(_isWorkMode ? 'Ver Noche' : 'Ver Día', style: const TextStyle(fontSize: 12)),
                        onPressed: _switchMode,
                      ),
                    ],
                  ),
                ),

                // Panel Flotante del Temporizador Principal
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: displayProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isWorkMode ? Colors.amber : Colors.tealAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        _formatTime(_timeLeft),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.extended(
                            heroTag: 'btnPlay',
                            onPressed: _toggleTimer,
                            backgroundColor: _isWorkMode ? Colors.indigoAccent : Colors.teal,
                            elevation: 4,
                            icon: Icon(
                              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isRunning ? 'Pausar' : 'Comenzar',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton.filledTonal(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh_rounded),
                            iconSize: 26,
                            padding: const EdgeInsets.all(14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Materia Activa',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                color: Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _subjects.map((subject) {
                final isSelected = _activeSubject?.id == subject.id;
                final subColor = Color(subject.colorValue);

                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(subject.name),
                    selectedColor: subColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) async {
                      if (selected) {
                        await _focusService.setActiveSubjectId(subject.id);
                        setState(() {
                          _activeSubject = subject;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}