import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../models/plant_calibration.dart';
import '../widgets/potted_plant_view.dart';
import 'focus_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final phase = PlantCalibration.getPhase(progress);
    return SizedBox(
      width: 200,
      height: 200,
      child: PottedPlantView(
        species: species,
        pot: pot,
        phase: phase,
        width: 200,
        height: 200,
        showShadow: true,
        showAura: true,
        showSparkles: true,
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
      // Sincronizar en diferido el estado del widget al iniciar la aplicación
      FocusService().syncWidgetWithActiveState();
    } catch (e) {
      debugPrint('Error configurando AppGroupId en HomeWidget: $e');
    }
  }

  /// Genera una imagen PNG compuesta pixel-perfect de Planta + Maceta usando Canvas
  /// garantizando que las imágenes se carguen de manera 100% asíncrona y no queden en blanco.
  static Future<Uint8List> generateCompositePlantImage({
    required String species,
    required String pot,
    required double progress,
  }) async {
    final phase = PlantCalibration.getPhase(progress);
    final calib = PlantCalibration.getCalibration(
      species: species,
      pot: pot,
      phase: phase,
    );

    final potImagePath = PlantCalibration.getPotImagePath(pot);
    final plantImagePath = PlantCalibration.getPlantImagePath(species, phase);

    // 1. Cargar bytes de assets garantizados
    final potByteData = await rootBundle.load(potImagePath);
    final plantByteData = await rootBundle.load(plantImagePath);

    final potCodec = await ui.instantiateImageCodec(potByteData.buffer.asUint8List());
    final potFrame = await potCodec.getNextFrame();
    final potImage = potFrame.image;

    final plantCodec = await ui.instantiateImageCodec(plantByteData.buffer.asUint8List());
    final plantFrame = await plantCodec.getNextFrame();
    final plantImage = plantFrame.image;

    // 2. Dimensiones del lienzo de referencia (340x340) idénticas a GrowingPlantWidget
    const double refW = 340.0;
    const double refH = 340.0;
    const double offsetY = 100.0;

    final double potWidth = PlantCalibration.basePotWidth * calib.potScale;
    final double plantSize = PlantCalibration.getBasePlantSize(phase) * calib.plantScale;

    final double potBottom = PlantCalibration.getBasePotBottom(phase) + calib.potY + offsetY;
    final double plantBottom = PlantCalibration.getBasePlantBottom(phase) + calib.plantY + offsetY;

    final double potLeft = (refW / 2) - (potWidth / 2) + PlantCalibration.getBasePotLeft(phase) + calib.potX;
    final double plantLeft = (refW / 2) - (plantSize / 2) + PlantCalibration.getBasePlantLeft(phase) + calib.plantX;

    final double potHeight = potWidth * (potImage.height / potImage.width);
    final double potTop = refH - potBottom - potHeight;
    final double plantTop = refH - plantBottom - plantSize;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, refW, refH));

    // Aura sutil detrás de la planta
    Color auraColor;
    switch (species) {
      case 'sp_rose':
        auraColor = const Color(0xFFFF4B4B);
        break;
      case 'sp_sakura':
        auraColor = const Color(0xFFFF80AB);
        break;
      case 'sp_oak':
      default:
        auraColor = const Color(0xFF58CC02);
        break;
    }

    final auraCenter = Offset(refW / 2, refH - potBottom - 35 - (plantSize * 0.85 / 2));
    final auraPaint = Paint()
      ..shader = ui.Gradient.radial(
        auraCenter,
        plantSize * 0.85 / 2,
        [
          auraColor.withValues(alpha: 0.20),
          auraColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(auraCenter, plantSize * 0.85 / 2, auraPaint);

    // Sombra elíptica suave bajo la maceta
    final shadowRect = Rect.fromLTWH(
      (refW / 2) - (potWidth * 0.90 / 2) + PlantCalibration.getBasePotLeft(phase) + calib.potX,
      refH - (potBottom - 6) - 16,
      potWidth * 0.90,
      16,
    );
    final shadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        shadowRect.center,
        shadowRect.width / 2,
        [
          Colors.black.withValues(alpha: 0.40),
          Colors.black.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        [0.0, 0.65, 1.0],
      );
    canvas.drawOval(shadowRect, shadowPaint);

    // Dibujar Maceta (posición calibrada exacta)
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(potLeft, potTop, potWidth, potHeight),
      image: potImage,
      fit: BoxFit.contain,
    );

    // Dibujar Planta (posición calibrada exacta sobre la maceta)
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(plantLeft, plantTop, plantSize, plantSize),
      image: plantImage,
      fit: BoxFit.contain,
    );

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(340, 340);
    final byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static String getMotivationalMessage({
    required double progress,
    required int streak,
    required bool studiedToday,
  }) {
    final phase = PlantCalibration.getPhase(progress);
    if (!studiedToday) {
      switch (phase) {
        case 1:
          return '🌱 ¡Tu brote tiene sed! Enfócate hoy.';
        case 2:
          return '🌿 ¡Cuidado! Riega tu planta hoy.';
        case 3:
          return '🌳 ¡Protege tu racha de $streak días!';
        case 4:
        default:
          return '🌸 ¡Mantén tu floración activa!';
      }
    } else {
      switch (phase) {
        case 1:
          return '🌱 ¡Brote regado! Racha protegida.';
        case 2:
          return '🌿 ¡Creciendo fuerte! Racha de $streak días.';
        case 3:
          return '🌳 ¡Planta radiante! Excelente enfoque.';
        case 4:
        default:
          return '🌸 ¡Floración máxima! Eres imparable.';
      }
    }
  }

  /// Sincroniza el estado actual de la planta Pomodoro con los widgets de iOS y Android
  static Future<void> syncWidgetData({
    required String species,
    required String pot,
    required double progress,
    required String subjectName,
    int streak = 1,
    bool studiedToday = false,
  }) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      // 1. Guardar datos numéricos, booleanos y de texto en el almacenamiento compartido
      final clampedProgress = progress.clamp(0.0, 1.0);
      final progressInt = (clampedProgress * 100).toInt();
      final phaseName = _getPhaseName(clampedProgress);
      final motivation = getMotivationalMessage(
        progress: clampedProgress,
        streak: streak,
        studiedToday: studiedToday,
      );
      final statusText = studiedToday ? '✓ AL DÍA' : '⚡ HOY';

      await HomeWidget.saveWidgetData<String>('species', species);
      await HomeWidget.saveWidgetData<String>('pot', pot);
      await HomeWidget.saveWidgetData<int>('progress', progressInt);
      await HomeWidget.saveWidgetData<int>('progressInt', progressInt);
      await HomeWidget.saveWidgetData<double>('progressDouble', clampedProgress);
      await HomeWidget.saveWidgetData<String>('subject', subjectName);
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<bool>('studiedToday', studiedToday);
      await HomeWidget.saveWidgetData<String>('statusText', statusText);
      await HomeWidget.saveWidgetData<String>('phaseName', phaseName);
      await HomeWidget.saveWidgetData<String>('motivation', motivation);

      // 2. Renderizar y persistir la imagen compuesta real
      try {
        final imageBytes = await generateCompositePlantImage(
          species: species,
          pot: pot,
          progress: clampedProgress,
        );

        final filePath = await HomeWidget.saveFile(
          'plant_graphic',
          imageBytes,
          extension: 'png',
          appGroupId: appGroupId,
        );
        debugPrint('✅ Imagen compuesta de widget guardada en: $filePath');
      } catch (renderError) {
        debugPrint('Aviso al renderizar imagen de widget: $renderError');
      }

      // 3. Solicitar actualización a los widgets nativos de iOS y Android
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      debugPrint('✅ Widget sincronizado con éxito: Especie=$species, Maceta=$pot, Racha=$streak, Progreso=$progressInt%');
    } catch (e) {
      debugPrint('❌ Error al sincronizar con el Home Widget: $e');
    }
  }
}
