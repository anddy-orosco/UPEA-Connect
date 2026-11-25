// Modelo y configuración de calibración de plantas y macetas del Pomodoro
// Unifica el posicionamiento de GrowingPlantWidget con todos los widgets de la app.

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

class PlantCalibration {
  static const double basePotWidth = 127.6;

  static double getBasePlantSize(int phase) {
    if (phase == 1) return 150.1;
    if (phase == 2 || phase == 3) return 253.4;
    return 258.2;
  }

  static double getBasePotBottom(int phase) {
    if (phase == 1 || phase == 2) return -91.3;
    if (phase == 3) return -88.5;
    return -83.1;
  }

  static double getBasePlantBottom(int phase) {
    if (phase == 1) return -21.6;
    return -72.2;
  }

  static double getBasePotLeft(int phase) {
    return phase == 1 ? 2.9 : 5.6;
  }

  static double getBasePlantLeft(int phase) {
    return phase == 1 ? 0.0 : 2.0;
  }

  static int getPhase(double progress) {
    if (progress >= 0.75) return 4;
    if (progress >= 0.50) return 3;
    if (progress >= 0.25) return 2;
    return 1;
  }

  static String getPlantImagePath(String species, int phase) {
    switch (species) {
      case 'sp_rose':
        if (phase == 1) return 'assets/images/fase1_rosa_brote.png';
        if (phase == 2) return 'assets/images/fase2_rosa_vastago.png';
        if (phase == 3) return 'assets/images/fase3_rosa_capullo.png';
        return 'assets/images/fase4_rosa_floripondio.png';

      case 'sp_sakura':
        if (phase == 1) return 'assets/images/fase1_sakura_brote.png';
        if (phase == 2) return 'assets/images/fase2_sakura_rama.png';
        if (phase == 3) return 'assets/images/fase3_sakura_capullo.png';
        return 'assets/images/fase4_sakura_plena.png';

      case 'sp_oak':
      default:
        if (phase == 1) return 'assets/images/fase1_plantula.png';
        if (phase == 2) return 'assets/images/fase2_planta_joven.png';
        if (phase == 3) return 'assets/images/fase3_planta_madura.png';
        return 'assets/images/fase4_planta_frondosa.png';
    }
  }

  static String getPotImagePath(String pot) {
    switch (pot) {
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

  static CalibrationData getCalibration({
    required String species,
    required String pot,
    required int phase,
  }) {
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

    return const CalibrationData();
  }
}
