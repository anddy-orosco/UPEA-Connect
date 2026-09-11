import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/subject_model.dart';
import '../services/focus_service.dart';
import '../widgets/growing_plant_widget.dart';
import 'focus_store_screen.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with SingleTickerProviderStateMixin {
  static const int _workTime = 25 * 60;
  static const int _breakTime = 5 * 60;

  int _timeLeft = _workTime;
  bool _isRunning = false;
  bool _isWorkMode = true;
  Timer? _timer;

  double? _debugProgress;

  final FocusService _focusService = FocusService();
  int _coins = 0;
  List<SubjectModel> _subjects = [];
  SubjectModel? _activeSubject;

  String _equippedPot = 'pot_default';
  String _equippedDecoration = 'dec_none';
  String _equippedSpecies = 'sp_oak';

  // Controlador para manejar la animación de Lottie (1 sola ejecución)
  late AnimationController _wateringController;
  bool _isWatering = false;

  @override
  void initState() {
    super.initState();
    _wateringController = AnimationController(vsync: this);

    _wateringController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isWatering = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingAndLoadData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wateringController.dispose();
    super.dispose();
  }

  // Función para activar el riego (reproduce la animación 1 vez)
  void _triggerWatering() {
    setState(() {
      _isWatering = true;
    });
    _wateringController.reset();
    _wateringController.forward();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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

    subjects.sort((a, b) => b.totalMinutesStudied.compareTo(a.totalMinutesStudied));

    SubjectModel? active;
    if (subjects.isNotEmpty) {
      active = subjects.firstWhere(
            (s) => s.id == activeId,
        orElse: () => subjects.first,
      );
    }

    final pot = active?.equippedPot ?? await _focusService.getEquippedPot();
    final species = active?.equippedSpecies ?? await _focusService.getEquippedSpecies();

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

  Future<void> _switchActiveSubject(String subjectId) async {
    _timer?.cancel();
    await _focusService.setActiveSubjectId(subjectId);

    setState(() {
      _isRunning = false;
      _timeLeft = _isWorkMode ? _workTime : _breakTime;
      _debugProgress = null;
    });

    await _loadData();
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
                      initialSubjectName: _capitalize(name),
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
                  final formattedName = _capitalize(controller.text.trim());
                  final newSub = SubjectModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: formattedName,
                    colorValue: selectedColor,
                    equippedSpecies: 'sp_oak',
                    equippedPot: 'pot_default',
                    plantProgress: 0.0,
                  );
                  await _focusService.saveSubject(newSub);
                  await _switchActiveSubject(newSub.id);
                  if (context.mounted) Navigator.pop(context);
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
        _debugProgress = null;
      });
      _triggerWatering(); // Al iniciar, regamos una vez
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

      double newProgress = (_activeSubject!.plantProgress + 0.25).clamp(0.0, 1.0);

      await _focusService.updateSubjectPlant(
        subjectId: _activeSubject!.id,
        plantProgress: newProgress,
      );
    }

    _switchMode();
    await _loadData();
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
    final sessionProgress = 1.0 - (_timeLeft / maxTime);
    final basePlantProgress = _activeSubject?.plantProgress ?? 0.0;

    final calculatedProgress = _isRunning
        ? (basePlantProgress + (sessionProgress * 0.25)).clamp(0.0, 1.0)
        : basePlantProgress;

    final displayProgress = _debugProgress ?? calculatedProgress;

    int currentStage = (displayProgress * 4).floor() + 1;
    if (currentStage > 4) currentStage = 4;
    int progressPercentage = (displayProgress * 100).toInt();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo Dinámica
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

          // 2. Capa de oscurecimiento suave
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.12),
            ),
          ),

          // 3. Interfaz Principal
          SafeArea(
            child: Column(
              children: [
                // Barra Superior Única
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'UPEA Connect',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _isWorkMode ? '☀️ Día' : '🌙 Noche',
                              style: const TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ),
                        ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '$_coins',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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

                // Selector de Materias Optimizado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
                  child: _buildSubjectSelector(),
                ),

                // Área Principal de la Planta + Animación de Riego
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none, // Permite sobresalir sin cortarse
                            alignment: Alignment.center,
                            children: [
                              // 1. Widget de la Planta (Capa inferior)
                              GrowingPlantWidget(
                                progress: displayProgress,
                                equippedPot: _equippedPot,
                                equippedDecoration: _equippedDecoration,
                                equippedSpecies: _equippedSpecies,
                              ),

                              // 2. Animación de Regadera (Subida más arriba: top: -190)
                              if (_isWatering)
                                Positioned(
                                  top: -190,  // Subido significativamente para abarcar la parte superior
                                  right: -25, // Mantiene la caída de agua centrada en la maceta
                                  child: IgnorePointer(
                                    child: Transform.scale(
                                      scaleX: -1, // Voltea horizontalmente
                                      child: SizedBox(
                                        width: 550,
                                        height: 550,
                                        child: Lottie.asset(
                                          'assets/animations/Watering.json',
                                          controller: _wateringController,
                                          fit: BoxFit.contain,
                                          onLoaded: (composition) {
                                            _wateringController.duration = composition.duration;
                                            _wateringController.forward();
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Indicador de Progreso de la Planta
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '🌱 Fase $currentStage de 4 • $progressPercentage% de Crecimiento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Panel para Pruebas Rápidas (Debug Controls)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.nature_rounded, size: 16),
                        label: const Text('Fase +', style: TextStyle(fontSize: 11)),
                        onPressed: () async {
                          double current = displayProgress;
                          double next = (current + 0.25) > 1.0 ? 0.0 : current + 0.25;

                          setState(() {
                            _debugProgress = next;
                          });

                          if (_activeSubject != null) {
                            await _focusService.updateSubjectPlant(
                              subjectId: _activeSubject!.id,
                              plantProgress: next,
                            );
                            await _loadData();
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWorkMode ? Colors.indigo : Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: Icon(_isWorkMode ? Icons.nights_stay : Icons.wb_sunny, size: 16),
                        label: Text(_isWorkMode ? 'Ver Noche' : 'Ver Día', style: const TextStyle(fontSize: 11)),
                        onPressed: _switchMode,
                      ),
                    ],
                  ),
                ),

                // Panel del Temporizador con Cristal (Glassmorphism)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: sessionProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isWorkMode ? Colors.amberAccent : Colors.tealAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              _formatTime(_timeLeft),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Controles de Acción
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Botón dedicado para Regar Planta
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.water_drop_rounded, size: 20),
                                  label: const Text(
                                    'Regar Planta',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: _triggerWatering,
                                ),
                                const SizedBox(width: 8),

                                // Botón Principal de Estudiar / Pausar
                                FloatingActionButton.extended(
                                  heroTag: 'btnPlay',
                                  onPressed: _toggleTimer,
                                  backgroundColor: Colors.indigo,
                                  elevation: 2,
                                  icon: Icon(
                                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _isRunning ? 'Pausar' : 'Estudiar',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Botón de Reiniciar
                                IconButton.filledTonal(
                                  onPressed: _resetTimer,
                                  icon: const Icon(Icons.refresh_rounded),
                                  iconSize: 22,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MATERIA ACTIVA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: _showAddSubjectDialog,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    color: Colors.white,
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
                    final displayName = _capitalize(subject.name);

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(displayName),
                        selectedColor: subColor,
                        backgroundColor: Colors.white12,
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.white24,
                        ),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        onSelected: (_) => _switchActiveSubject(subject.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}