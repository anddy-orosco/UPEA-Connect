import 'package:flutter/material.dart';
import '../models/plant_calibration.dart';

// --- MODELO DE TIENDA Y EQUIPAMIENTO ---
class PlantSpeciesItem {
  final String id;
  final String name;
  final int price;
  final String iconEmoji;

  const PlantSpeciesItem({
    required this.id,
    required this.name,
    required this.price,
    required this.iconEmoji,
  });
}

final List<PlantSpeciesItem> availableSpeciesInShop = [
  const PlantSpeciesItem(id: 'sp_oak', name: 'Roble Clásico', price: 0, iconEmoji: '🌳'),
  const PlantSpeciesItem(id: 'sp_rose', name: 'Rosa Roja', price: 150, iconEmoji: '🌹'),
  const PlantSpeciesItem(id: 'sp_sakura', name: 'Cerezo Sakura', price: 250, iconEmoji: '🌸'),
];

// --- WIDGET PRINCIPAL ---
class GrowingPlantWidget extends StatefulWidget {
  final double progress;
  final String equippedPot;
  final String equippedDecoration;
  final String equippedSpecies;

  const GrowingPlantWidget({
    super.key,
    required this.progress,
    this.equippedPot = 'pot_default',
    this.equippedDecoration = 'dec_none',
    this.equippedSpecies = 'sp_oak',
  });

  @override
  State<GrowingPlantWidget> createState() => _GrowingPlantWidgetState();
}

class _GrowingPlantWidgetState extends State<GrowingPlantWidget> {
  // Offsets y escalas manuales
  double _manualPlantX = 0.0;
  double _manualPlantY = 0.0;
  double _manualPotX = 0.0;
  double _manualPotY = 0.0;
  double _manualPlantScale = 1.0;
  double _manualPotScale = 1.0;

  // Duración estándar de las animaciones suaves
  static const Duration _animDuration = Duration(milliseconds: 450);

  int get _currentPhase {
    if (widget.progress >= 0.75) return 4;
    if (widget.progress >= 0.50) return 3;
    if (widget.progress >= 0.25) return 2;
    return 1;
  }

  String _getPlantImagePath() =>
      PlantCalibration.getPlantImagePath(widget.equippedSpecies, _currentPhase);

  String _getPotImagePath() =>
      PlantCalibration.getPotImagePath(widget.equippedPot);

  CalibrationData get _currentCalibration => PlantCalibration.getCalibration(
        species: widget.equippedSpecies,
        pot: widget.equippedPot,
        phase: _currentPhase,
      );

  double get _finalPlantX => _currentCalibration.plantX + _manualPlantX;
  double get _finalPlantY => _currentCalibration.plantY + _manualPlantY;
  double get _finalPlantScale => _currentCalibration.plantScale * _manualPlantScale;

  double get _finalPotX => _currentCalibration.potX + _manualPotX;
  double get _finalPotY => _currentCalibration.potY + _manualPotY;
  double get _finalPotScale => _currentCalibration.potScale * _manualPotScale;

  double get _potBottom =>
      PlantCalibration.getBasePotBottom(_currentPhase) + _finalPotY;

  double get _potLeft =>
      PlantCalibration.getBasePotLeft(_currentPhase) + _finalPotX;

  double get _potWidth => PlantCalibration.basePotWidth * _finalPotScale;

  double get _plantBottom =>
      PlantCalibration.getBasePlantBottom(_currentPhase) + _finalPlantY;

  double get _plantLeft =>
      PlantCalibration.getBasePlantLeft(_currentPhase) + _finalPlantX;

  double get _plantSize =>
      PlantCalibration.getBasePlantSize(_currentPhase) * _finalPlantScale;

  void _printCoordinates() {
    debugPrint('\n=============================================');
    debugPrint('📍 DATOS DE CALIBRACIÓN REGISTRADOS:');
    debugPrint('ESPECIE: ${widget.equippedSpecies} | MACETA: ${widget.equippedPot} | FASE: $_currentPhase');
    debugPrint('PLANTA -> Offset X: ${_finalPlantX.toInt()}, Y: ${_finalPlantY.toInt()} | Escala: ${_finalPlantScale.toStringAsFixed(2)}x');
    debugPrint('MACETA -> Offset X: ${_finalPotX.toInt()}, Y: ${_finalPotY.toInt()} | Escala: ${_finalPotScale.toStringAsFixed(2)}x');
    debugPrint('=============================================\n');
  }

  void _openCalibratorMenu() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calibrar: ${widget.equippedSpecies} (Fase $_currentPhase)',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌱 PLANTA', style: TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Pos:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPlantX -= 1);
                            setDialogState(() {});
                          },
                        ),
                        Text('X: ${_finalPlantX.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPlantX += 1);
                            setDialogState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPlantY -= 1);
                            setDialogState(() {});
                          },
                        ),
                        Text('Y: ${_finalPlantY.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPlantY += 1);
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Tamaño:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            if (_manualPlantScale > 0.2) {
                              setState(() => _manualPlantScale -= 0.05);
                              setDialogState(() {});
                            }
                          },
                        ),
                        Text('${(_finalPlantScale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.lightGreenAccent, size: 20),
                          onPressed: () {
                            setState(() => _manualPlantScale += 0.05);
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    const Text('🪴 MACETA', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Pos:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPotX -= 1);
                            setDialogState(() {});
                          },
                        ),
                        Text('X: ${_finalPotX.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPotX += 1);
                            setDialogState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPotY -= 1);
                            setDialogState(() {});
                          },
                        ),
                        Text('Y: ${_finalPotY.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() => _manualPotY += 1);
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Tamaño:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            if (_manualPotScale > 0.2) {
                              setState(() => _manualPotScale -= 0.05);
                              setDialogState(() {});
                            }
                          },
                        ),
                        Text('${(_finalPotScale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.lightGreenAccent, size: 20),
                          onPressed: () {
                            setState(() => _manualPotScale += 0.05);
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _manualPlantX = 0;
                      _manualPlantY = 0;
                      _manualPotX = 0;
                      _manualPotY = 0;
                      _manualPlantScale = 1.0;
                      _manualPotScale = 1.0;
                    });
                    setDialogState(() {});
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  icon: const Icon(Icons.print, color: Colors.black, size: 18),
                  label: const Text('IMPRIMIR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _printCoordinates();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coordenadas impresas en la terminal'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantImagePath = _getPlantImagePath();
    final potImagePath = _getPotImagePath();

    return GestureDetector(
      onLongPress: _openCalibratorMenu,
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // --- MACETA CON ANIMACIÓN FLUIDA ---
            AnimatedPositioned(
              duration: _animDuration,
              curve: Curves.easeInOutCubic,
              bottom: _potBottom,
              left: (MediaQuery.of(context).size.width / 2) - (_potWidth / 2) + _potLeft,
              child: AnimatedContainer(
                duration: _animDuration,
                curve: Curves.easeInOutCubic,
                width: _potWidth,
                child: AnimatedSwitcher(
                  duration: _animDuration,
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: Image.asset(
                    potImagePath,
                    key: ValueKey<String>(potImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // --- PLANTA CON ANIMACIÓN Y TRANSICIÓN DE FASE ---
            AnimatedPositioned(
              duration: _animDuration,
              curve: Curves.easeInOutBack,
              bottom: _plantBottom,
              left: (MediaQuery.of(context).size.width / 2) - (_plantSize / 2) + _plantLeft,
              child: AnimatedContainer(
                duration: _animDuration,
                curve: Curves.easeInOutBack,
                width: _plantSize,
                height: _plantSize,
                child: AnimatedSwitcher(
                  duration: _animDuration,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    plantImagePath,
                    key: ValueKey<String>(plantImagePath),
                    width: _plantSize,
                    height: _plantSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}