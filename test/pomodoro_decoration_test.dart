import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upea_connect/services/focus_service.dart';
import 'package:upea_connect/screens/focus_store_screen.dart';
import 'package:upea_connect/screens/pomodoro_screen.dart';
import 'package:upea_connect/models/subject_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FocusService saves and restores multi-copy decoration transforms and excludes dec_glitters',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = FocusService();

    // Brillo Áureo / monedas se quitó de los adornos comprables
    expect(FocusService.validDecorations, isNot(contains('dec_glitters')));
    expect(FocusService.growthGlitterTransforms.length, 3);
    expect(FocusService.growthGlitterTransforms[0].dx, -41.2);
    expect(FocusService.growthGlitterTransforms[0].dy, 69.9);
    expect(FocusService.growthGlitterTransforms[1].dx, 22.3);
    expect(FocusService.growthGlitterTransforms[2].dx, 58.6);

    final loaded = await service.getAllDecorationTransforms();
    expect(loaded['dec_bees']?.length, 2);
    expect(loaded['dec_butterflies']?.length, 3);
    expect(loaded['dec_owl']?.length, 1);
    expect(loaded['dec_stars']?.length, 3);

    expect(loaded['dec_owl']!.first.dx, 149.1);
    expect(loaded['dec_owl']!.first.dy, -37.2);
    expect(loaded['dec_owl']!.first.scale, 1.80);

    const customBees = [
      DecorationTransform(dx: -28.5, dy: 14.0, scale: 1.2),
      DecorationTransform(dx: 40.0, dy: 10.0, scale: 0.5),
    ];
    await service.saveDecorationTransforms('dec_bees', customBees);

    final updated = await service.getAllDecorationTransforms();
    expect(updated['dec_bees']?.length, 2);
    expect(updated['dec_bees']?[0].dx, -28.5);
    expect(updated['dec_bees']?[1].scale, 0.5);

    await service.resetDecorationTransforms('dec_bees');
    final reset = await service.getAllDecorationTransforms();
    expect(reset['dec_bees']?[0].dx, 78.9);
    expect(reset['dec_bees']?[1].dx, -71.5);
  });

  testWidgets('FocusStoreScreen excludes Brillo Áureo and still grants +100 coins on tap',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'focus_coins': 50});
    await tester.pumpWidget(
      const MaterialApp(home: FocusStoreScreen()),
    );
    await tester.pump();
    expect(find.text('50'), findsOneWidget);

    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();
    expect(find.text('150'), findsOneWidget);

    await tester.tap(find.text('Adornos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Abejas del Jardín'), findsOneWidget);
    expect(find.text('Brillo Áureo'), findsNothing);
  });

  testWidgets(
      'PomodoroScreen renders multiple decoration copies, saves dragged positions, and bursts glitters when plant grows',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final subject = SubjectModel(
      id: 'sub_1',
      name: 'Calculo',
      colorValue: 0xFF5C6BC0,
    );
    SharedPreferences.setMockInitialValues({
      'focus_onboarded': true,
      'focus_coins': 200,
      'focus_subjects': [jsonEncode(subject.toMap())],
      'focus_active_subject_id': 'sub_1',
      'focus_equipped_decoration': 'dec_butterflies',
      'focus_purchased_decorations': ['dec_none', 'dec_butterflies', 'dec_owl'],
    });

    await tester.pumpWidget(
      const MaterialApp(home: PomodoroScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Mariposas configuradas en 3 posiciones simultáneas -> 3 Lottie en pantalla
    expect(find.byType(Lottie), findsNWidgets(3));

    // Al crecer la planta con "Fase +" aparecen los 3 brillos de monedas -> 3 + 3 = 6 Lottie
    await tester.tap(find.text('Fase +'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Lottie), findsNWidgets(6));

    // Esperar a que termine la animación de crecimiento (1670ms) -> vuelven las 3 mariposas
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.byType(Lottie), findsNWidgets(3));

    // Probar arrastrar y guardar la primera copia desde el control Mover
    await tester.tap(find.text('Mover'));
    await tester.pump();
    expect(find.text('Guardar posición'), findsOneWidget);

    await tester.drag(find.byIcon(Icons.open_with_rounded).first, const Offset(-30, -20));
    await tester.pump();

    await tester.tap(find.text('Guardar posición'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final transforms = await FocusService().getAllDecorationTransforms();
    expect(transforms['dec_butterflies']![0].dx, lessThan(103.2));
  });
}
