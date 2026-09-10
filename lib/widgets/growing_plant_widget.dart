import 'package:flutter/material.dart';

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

// --- ESTRUCTURA DE CONFIGURACIÓN DE CALIBRACIÓN ---
class CalibrationData {
  final double plantX;
  final double plantY;
  final double plantScale;
  final double potX;
  final double potY;
  final double potScale;

  const CalibrationData({
    this.plantX = 0.0,
    this.plantY = 0.0,
    this.plantScale = 1.0,
    this.potX = 0.0,
    this.potY = 0.0,
    this.potScale = 1.0,
  });
}

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
  // Offsets y escalas manuales de emergencia / reajuste
  double _manualPlantX = 0.0;
  double _manualPlantY = 0.0;
  double _manualPotX = 0.0;
  double _manualPotY = 0.0;
  double _manualPlantScale = 1.0;
  double _manualPotScale = 1.0;

  // Determinar fase actual (1 a 4)
  int get _currentPhase {
    if (widget.progress >= 0.75) return 4;
    if (widget.progress >= 0.50) return 3;
    if (widget.progress >= 0.25) return 2;
    return 1;
  }

  // --- SELECCIÓN DINÁMICA DE IMÁGENES ---
  String _getPlantImagePath() {
    switch (widget.equippedSpecies) {
      case 'sp_rose':
        if (_currentPhase == 1) return 'assets/images/fase1_rosa_brote.png';
        if (_currentPhase == 2) return 'assets/images/fase2_rosa_vastago.png';
        if (_currentPhase == 3) return 'assets/images/fase3_rosa_capullo.png';
        return 'assets/images/fase4_rosa_floripondio.png';

      case 'sp_sakura':
        if (_currentPhase == 1) return 'assets/images/fase1_sakura_brote.png';
        if (_currentPhase == 2) return 'assets/images/fase2_sakura_rama.png';
        if (_currentPhase == 3) return 'assets/images/fase3_sakura_capullo.png';
        return 'assets/images/fase4_sakura_plena.png';

      case 'sp_oak':
      default:
        if (_currentPhase == 1) return 'assets/images/fase1_plantula.png';
        if (_currentPhase == 2) return 'assets/images/fase2_planta_joven.png';
        if (_currentPhase == 3) return 'assets/images/fase3_planta_madura.png';
        return 'assets/images/fase4_planta_frondosa.png';
    }
  }

  String _getPotImagePath() {
    switch (widget.equippedPot) {
      case 'pot_gold':
        return 'assets/images/maceta_dorada.png';
      case 'pot_japanese':
        return 'assets/images/maceta_japonesa.png';
      case 'pot_volcanic':
        return 'assets/images/maceta_volcanica.png';
      case 'pot_default':
      default:
        return 'assets/images/maceta_normal.png';
    }
  }

  // --- MATRIZ COMPLETA DE CALIBRACIÓN RECOPILADA ---
  CalibrationData get _currentCalibration {
    final species = widget.equippedSpecies;
    final pot = widget.equippedPot;
    final phase = _currentPhase;

    // --- ROSA (sp_rose) ---
    if (species == 'sp_rose') {
      if (pot == 'pot_default') {
        if (phase == 1) return const CalibrationData(plantX: 1, plantY: -17, plantScale: 1.15);
        if (phase == 2) return const CalibrationData(plantX: 0, plantY: -8, plantScale: 1.15);
        if (phase == 3) return const CalibrationData(plantX: 0, plantY: -5, plantScale: 1.15);
        if (phase == 4) return const CalibrationData(plantX: 0, plantY: -3, plantScale: 1.10);
      } else if (pot == 'pot_gold') {
        if (phase == 1) return const CalibrationData(plantX: 0, plantY: -15, plantScale: 1.20, potScale: 1.10);
        if (phase == 2) return const CalibrationData(plantX: -2, plantY: 0, plantScale: 1.10, potScale: 1.10);
        if (phase == 3) return const CalibrationData(plantX: -2, plantY: 4, plantScale: 1.10, potScale: 1.10);
        if (phase == 4) return const CalibrationData(plantX: -2, plantY: 4, plantScale: 1.10, potScale: 1.10);
      } else if (pot == 'pot_japanese') {
        if (phase == 1) return const CalibrationData(plantX: 1, plantY: -26, plantScale: 1.35, potScale: 1.05);
        if (phase == 2) return const CalibrationData(plantX: -1, plantY: -17, plantScale: 1.20);
        if (phase == 3) return const CalibrationData(plantX: -1, plantY: -14, plantScale: 1.20);
        if (phase == 4) return const CalibrationData(plantX: -1, plantY: -7, plantScale: 1.10);
      } else if (pot == 'pot_volcanic') {
        if (phase == 1) return const CalibrationData(plantX: 1, plantY: -18, plantScale: 1.15, potScale: 1.05);
        if (phase == 2) return const CalibrationData(plantX: 1, plantY: -7, plantScale: 1.15, potScale: 1.05);
        if (phase == 3) return const CalibrationData(plantX: 1, plantY: -4, plantScale: 1.15, potScale: 1.05);
        if (phase == 4) return const CalibrationData(plantX: 1, plantY: -2, plantScale: 1.15, potScale: 1.05);
      }
    }

    // --- SAKURA (sp_sakura) ---
    if (species == 'sp_sakura') {
      if (pot == 'pot_default') {
        if (phase == 1) return const CalibrationData(plantX: 0, plantY: -20, plantScale: 1.20);
        if (phase == 2) return const CalibrationData(plantX: 0, plantY: -6, plantScale: 1.10);
        if (phase == 3) return const CalibrationData(plantX: -1, plantY: -2, plantScale: 1.10);
        if (phase == 4) return const CalibrationData(plantX: -1, plantY: -2, plantScale: 1.10);
      } else if (pot == 'pot_gold') {
        if (phase == 1) return const CalibrationData(plantX: 0, plantY: -20, plantScale: 1.10);
        if (phase == 2) return const CalibrationData(plantX: 0, plantY: -9, plantScale: 1.10);
        if (phase == 3) return const CalibrationData(plantX: 0, plantY: -4, plantScale: 1.10);
        if (phase == 4) return const CalibrationData(plantX: 0, plantY: 0, plantScale: 1.05);
      } else if (pot == 'pot_japanese') {
        if (phase == 1) return const CalibrationData(plantX: 1, plantY: -30, plantScale: 1.35);
        if (phase == 2) return const CalibrationData(plantX: 0, plantY: -20, plantScale: 1.25);
        if (phase == 3) return const CalibrationData(plantX: 0, plantY: -13, plantScale: 1.20);
        if (phase == 4) return const CalibrationData(plantX: 0, plantY: -13, plantScale: 1.20);
      } else if (pot == 'pot_volcanic') {
        if (phase == 1) return const CalibrationData(plantX: 1, plantY: -20, plantScale: 1.10);
        if (phase == 2) return const CalibrationData(plantX: 1, plantY: -7, plantScale: 1.10);
        if (phase == 3) return const CalibrationData(plantX: 1, plantY: -4, plantScale: 1.10);
        if (phase == 4) return const CalibrationData(plantX: 1, plantY: 0, plantScale: 1.05);
      }
    }

    // --- PLANTA BASE / ROBLE (sp_oak) ---
    if (species == 'sp_oak') {
      if (pot == 'pot_default') {
        if (phase == 1) return const CalibrationData(plantX: 0, plantY: -4, plantScale: 1.10);
        if (phase == 2) return const CalibrationData(plantX: -1, plantY: -7, plantScale: 1.10);
        if (phase == 3) return const CalibrationData(plantX: 0, plantY: -12, plantScale: 1.15);
        if (phase == 4) return const CalibrationData(plantX: 1, plantY: -12, plantScale: 1.15);
      } else if (pot == 'pot_gold') {
        if (phase == 1) return const CalibrationData(plantX: 0, plantY: -6, plantScale: 1.00);
        if (phase == 2) return const CalibrationData(plantX: 0, plantY: -4, plantScale: 1.00);
        if (phase == 3) return const CalibrationData(plantX: 0, plantY: -15, plantScale: 1.15);
        if (phase == 4) return const CalibrationData(plantX: 1, plantY: -15, plantScale: 1.15);
      } else if (pot == 'pot_japanese') {
        if (phase == 1) return const CalibrationData(plantX: 1, plantY: -11, plantScale: 1.15);
        if (phase == 2) return const CalibrationData(plantX: -1, plantY: -20, plantScale: 1.20);
        if (phase == 3) return const CalibrationData(plantX: 1, plantY: -20, plantScale: 1.20);
        if (phase == 4) return const CalibrationData(plantX: 1, plantY: -22, plantScale: 1.20);
      } else if (pot == 'pot_volcanic') {
        if (phase == 1) return const CalibrationData(plantX: 0, plantY: -5, plantScale: 1.00);
        if (phase == 2) return const CalibrationData(plantX: 0, plantY: -7, plantScale: 1.05);
        if (phase == 3) return const CalibrationData(plantX: 1, plantY: -10, plantScale: 1.10);
        if (phase == 4) return const CalibrationData(plantX: 1, plantY: -11, plantScale: 1.10);
      }
    }

    // Valores por defecto
    return const CalibrationData();
  }

  // --- CÁLCULOS FINALES COMBINANDO BASE Y REAJUSTES ---
  double get _finalPlantX => _currentCalibration.plantX + _manualPlantX;
  double get _finalPlantY => _currentCalibration.plantY + _manualPlantY;
  double get _finalPlantScale => _currentCalibration.plantScale * _manualPlantScale;

  double get _finalPotX => _currentCalibration.potX + _manualPotX;
  double get _finalPotY => _currentCalibration.potY + _manualPotY;
  double get _finalPotScale => _currentCalibration.potScale * _manualPotScale;

  double get _potBottom {
    double base = -83.1;
    if (_currentPhase == 1 || _currentPhase == 2) base = -91.3;
    else if (_currentPhase == 3) base = -88.5;
    return base + _finalPotY;
  }

  double get _potLeft {
    double base = 5.6;
    if (_currentPhase == 1) base = 2.9;
    return base + _finalPotX;
  }

  double get _potWidth => 127.6 * _finalPotScale;

  double get _plantBottom {
    double base = -72.2;
    if (_currentPhase == 1) base = -21.6;
    return base + _finalPlantY;
  }

  double get _plantLeft {
    double base = 2.0;
    if (_currentPhase == 1) base = 0.0;
    return base + _finalPlantX;
  }

  double get _plantSize {
    double base = 258.2;
    if (_currentPhase == 1) base = 150.1;
    else if (_currentPhase == 2 || _currentPhase == 3) base = 253.4;
    return base * _finalPlantScale;
  }

  // IMPRIMIR EN TERMINAL
  void _printCoordinates() {
    print('\n=============================================');
    print('📍 DATOS DE CALIBRACIÓN REGISTRADOS:');
    print('ESPECIE: ${widget.equippedSpecies} | MACETA: ${widget.equippedPot} | FASE: $_currentPhase');
    print('PLANTA -> Offset X: ${_finalPlantX.toInt()}, Y: ${_finalPlantY.toInt()} | Escala: ${_finalPlantScale.toStringAsFixed(2)}x');
    print('MACETA -> Offset X: ${_finalPotX.toInt()}, Y: ${_finalPotY.toInt()} | Escala: ${_finalPotScale.toStringAsFixed(2)}x');
    print('=============================================\n');
  }

  // MENÚ MODAL DE AJUSTE
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
            // MACETA
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              bottom: _potBottom,
              child: Transform.translate(
                offset: Offset(_potLeft, 0),
                child: SizedBox(
                  width: _potWidth,
                  child: Image.asset(
                    potImagePath,
                    key: ValueKey<String>(potImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // PLANTA
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              bottom: _plantBottom,
              child: Transform.translate(
                offset: Offset(_plantLeft, 0),
                child: SizedBox(
                  width: _plantSize,
                  height: _plantSize,
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