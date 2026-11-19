import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WidgetPlantGraphic extends StatelessWidget {
  final String species;
  final String pot;
  final double progress;

  const WidgetPlantGraphic({
    super.key,
    required this.species,
    required this.pot,
    required this.progress,
  });

  int get _phase {
    if (progress >= 0.75) return 4;
    if (progress >= 0.50) return 3;
    if (progress >= 0.25) return 2;
    return 1;
  }

  String get _plantImage {
    switch (species) {
      case 'sp_rose':
        if (_phase == 1) return 'assets/images/fase1_rosa_brote.png';
        if (_phase == 2) return 'assets/images/fase2_rosa_vastago.png';
        if (_phase == 3) return 'assets/images/fase3_rosa_capullo.png';
        return 'assets/images/fase4_rosa_floripondio.png';
      case 'sp_sakura':
        if (_phase == 1) return 'assets/images/fase1_sakura_brote.png';
        if (_phase == 2) return 'assets/images/fase2_sakura_rama.png';
        if (_phase == 3) return 'assets/images/fase3_sakura_capullo.png';
        return 'assets/images/fase4_sakura_plena.png';
      case 'sp_oak':
      default:
        if (_phase == 1) return 'assets/images/fase1_plantula.png';
        if (_phase == 2) return 'assets/images/fase2_planta_joven.png';
        if (_phase == 3) return 'assets/images/fase3_planta_madura.png';
        return 'assets/images/fase4_planta_frondosa.png';
    }
  }

  String get _potImage {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Image.asset(
              _potImage,
              width: 120,
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 42,
            child: Image.asset(
              _plantImage,
              width: 160,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetSyncService {
  static const String appGroupId = 'group.com.example.miAppUniversitaria';
  static const String iOSWidgetName = 'PomodoroWidget';
  static const String androidWidgetName = 'PomodoroWidgetProvider';

  static String _getPhaseName(double progress) {
    if (progress >= 0.75) return 'Floración Total';
    if (progress >= 0.50) return 'Planta Madura';
    if (progress >= 0.25) return 'En Crecimiento';
    return 'Brote Inicial';
  }

  /// Inicializa la configuración de HomeWidget y maneja clics
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error configurando AppGroupId en HomeWidget: $e');
    }
  }

  /// Sincroniza el estado actual de la planta Pomodoro con los widgets de iOS y Android
  static Future<void> syncWidgetData({
    required String species,
    required String pot,
    required double progress,
    required String subjectName,
    int streak = 3,
  }) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      // 1. Guardar datos numéricos y de texto en el almacenamiento compartido
      await HomeWidget.saveWidgetData<String>('species', species);
      await HomeWidget.saveWidgetData<String>('pot', pot);
      await HomeWidget.saveWidgetData<double>('progress', progress.clamp(0.0, 1.0));
      await HomeWidget.saveWidgetData<String>('subject', subjectName);
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<String>('phaseName', _getPhaseName(progress));

      // 2. Renderizar la planta visual idéntica a la app y guardarla como imagen compartida
      try {
        await HomeWidget.renderFlutterWidget(
          WidgetPlantGraphic(
            species: species,
            pot: pot,
            progress: progress,
          ),
          key: 'plant_graphic',
          logicalSize: const Size(200, 200),
          appGroupId: appGroupId,
        );
      } catch (renderError) {
        debugPrint('Aviso al renderizar imagen de widget: $renderError');
      }

      // 3. Solicitar actualización a los widgets nativos de iOS y Android
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      debugPrint('✅ Widget sincronizado con éxito: Especie=$species, Maceta=$pot, Progreso=${(progress * 100).toInt()}%');
    } catch (e) {
      debugPrint('❌ Error al sincronizar con el Home Widget: $e');
    }
  }
}
