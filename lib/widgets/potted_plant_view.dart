import 'package:flutter/material.dart';
import '../models/plant_calibration.dart';

/// Componente visual unificado de Planta + Maceta que replica con fidelidad
/// absoluta (1:1) la disposición visual de GrowingPlantWidget en pomodoro_screen.
/// 
/// Al renderizar el mismo lienzo de referencia (340x340) con las mismas coordenadas
/// y envolverlo en un FittedBox, garantiza que el aspecto visual sea exactamente
/// idéntico al que se ve en la pantalla principal del Pomodoro en cualquier tamaño.
class PottedPlantView extends StatelessWidget {
  final String species;
  final String pot;
  final int phase;
  final double width;
  final double height;
  final bool showShadow;
  final bool showAura;
  final bool showSparkles;

  const PottedPlantView({
    super.key,
    required this.species,
    required this.pot,
    required this.phase,
    required this.width,
    required this.height,
    this.showShadow = true,
    this.showAura = true,
    this.showSparkles = true,
  });

  Color _getAuraColor() {
    switch (species) {
      case 'sp_rose':
        return const Color(0xFFFF4B4B);
      case 'sp_sakura':
        return const Color(0xFFFF80AB);
      case 'sp_oak':
      default:
        return const Color(0xFF58CC02);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calib = PlantCalibration.getCalibration(
      species: species,
      pot: pot,
      phase: phase,
    );

    // Dimensiones del lienzo de referencia idénticas al espacio de GrowingPlantWidget
    const double refW = 340.0;
    const double refH = 340.0;
    const double offsetY = 100.0; // Desplaza los valores negativos al rango visible

    final double potWidth = PlantCalibration.basePotWidth * calib.potScale;
    final double plantSize = PlantCalibration.getBasePlantSize(phase) * calib.plantScale;

    // Coordenadas verticales exactas de GrowingPlantWidget
    final double potBottom = PlantCalibration.getBasePotBottom(phase) + calib.potY + offsetY;
    final double plantBottom = PlantCalibration.getBasePlantBottom(phase) + calib.plantY + offsetY;

    // Centrado horizontal exacto con micro-calibraciones X de GrowingPlantWidget
    final double potLeft = (refW / 2) - (potWidth / 2) + PlantCalibration.getBasePotLeft(phase) + calib.potX;
    final double plantLeft = (refW / 2) - (plantSize / 2) + PlantCalibration.getBasePlantLeft(phase) + calib.plantX;

    final String potImagePath = PlantCalibration.getPotImagePath(pot);
    final String plantImagePath = PlantCalibration.getPlantImagePath(species, phase);

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox(
          width: refW,
          height: refH,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Resplandor / Aura sutil detrás de la planta
              if (showAura)
                Positioned(
                  bottom: potBottom + 35,
                  left: (refW / 2) - (plantSize * 0.85 / 2),
                  child: IgnorePointer(
                    child: Container(
                      width: plantSize * 0.85,
                      height: plantSize * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getAuraColor().withValues(alpha: 0.18),
                            _getAuraColor().withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Sombra elíptica suave en la base de la maceta
              if (showShadow)
                Positioned(
                  bottom: potBottom - 6,
                  left: (refW / 2) - (potWidth * 0.90 / 2) + PlantCalibration.getBasePotLeft(phase) + calib.potX,
                  child: IgnorePointer(
                    child: Container(
                      width: potWidth * 0.90,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(potWidth * 0.90, 16),
                        ),
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.40),
                            Colors.black.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Maceta Real (proporción y posición idéntica a GrowingPlantWidget)
              Positioned(
                bottom: potBottom,
                left: potLeft,
                child: SizedBox(
                  width: potWidth,
                  child: Image.asset(
                    potImagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 4. Planta Real (proporción y posición idéntica a GrowingPlantWidget)
              Positioned(
                bottom: plantBottom,
                left: plantLeft,
                child: SizedBox(
                  width: plantSize,
                  height: plantSize,
                  child: Image.asset(
                    plantImagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 5. Destellos sutiles de florecimiento en Fase 4
              if (showSparkles && phase == 4) ...[
                Positioned(
                  top: 30,
                  right: (refW / 2) - 100,
                  child: _buildSparkleDot(size: 14, color: Colors.amberAccent),
                ),
                Positioned(
                  top: 70,
                  left: (refW / 2) - 105,
                  child: _buildSparkleDot(size: 10, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkleDot({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.65),
              blurRadius: size * 1.2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
