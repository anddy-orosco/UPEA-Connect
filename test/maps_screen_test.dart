import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upea_connect/data/map_data.dart';
import 'package:upea_connect/models/map_location_model.dart';
import 'package:upea_connect/screens/maps_screen.dart';
import 'package:upea_connect/services/theme_service.dart';
import 'package:upea_connect/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapData & PNG assets validation', () {
    test('All 6 floor plans reference existing .png files and valid coordinates',
        () {
      expect(
        MapData.floors.map((f) => f.code).toList(),
        equals(['P5', 'P4', 'P3', 'P2', 'P1', 'PB']),
      );

      final seenIds = <String>{};
      for (final floor in MapData.floors) {
        expect(floor.imagePath, endsWith('.png'));
        expect(
          File(floor.imagePath).existsSync(),
          isTrue,
          reason: 'Asset missing on disk: ${floor.imagePath}',
        );
        expect(floor.aspectRatio, closeTo(1792 / 2400, 0.0001));
        expect(floor.stairsEntry.x, inInclusiveRange(0.05, 0.95));
        expect(floor.stairsEntry.y, inInclusiveRange(0.05, 0.95));
        expect(floor.locations, isNotEmpty);

        for (final loc in floor.locations) {
          expect(seenIds.add(loc.id), isTrue, reason: 'Duplicate id ${loc.id}');
          expect(loc.floorCode, floor.code);
          expect(loc.x, inInclusiveRange(0.05, 0.95));
          expect(loc.y, inInclusiveRange(0.05, 0.95));
          for (final wp in loc.routeWaypoints) {
            expect(wp.x, inInclusiveRange(0.05, 0.95));
            expect(wp.y, inInclusiveRange(0.05, 0.95));
          }
        }
      }
    });
  });

  group('BuildingMapScreen widget & theme continuity', () {
    Widget buildHarness(ThemeService themeService) {
      return ChangeNotifierProvider<ThemeService>.value(
        value: themeService,
        child: MaterialApp(
          theme: themeService.themeData,
          home: const BuildingMapScreen(),
        ),
      );
    }

    testWidgets(
      'Renders calibrated floors P5..PB, filters, searches, and supports fullscreen & themes',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeService = ThemeService();
        await tester.pumpWidget(buildHarness(themeService));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Piso por defecto: P4 -> Kardex Académico
        expect(find.text('Planta de Piso 4 de'), findsOneWidget);
        expect(find.textContaining('Kardex Académico'), findsWidgets);

        // Cambiar a P5
        await tester.tap(find.text('P5'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Planta de Piso 5 de'), findsOneWidget);
        expect(find.textContaining('Auditorium "Víctor Mamani"'), findsWidgets);

        // Cambiar a PB
        await tester.tap(find.text('PB'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Planta de Planta Baja de'), findsOneWidget);
        expect(find.textContaining('Área de Acceso'), findsWidgets);

        // Filtrar Baños desde PB debe saltar a un piso con baños (P5)
        await tester.tap(find.text(MapLocationCategory.banos.label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Baños'), findsWidgets);

        // Quitar filtro tocando el chip nuevamente y buscar "Redes"
        await tester.tap(find.text(MapLocationCategory.banos.label));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'Redes');
        await tester.pump();
        await tester.tap(find.text('Laboratorio de Redes (Lab-Redes)').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Planta de Piso 3 de'), findsOneWidget);

        // Cambiar por todos los temas de la app sin errores de render
        for (final variant in AppThemeVariant.values) {
          await themeService.setTheme(variant);
          await tester.pumpWidget(buildHarness(themeService));
          await tester.pump();
        }

        // Abrir detalle en pantalla completa y volver atrás
        await tester.tap(find.byTooltip('Pantalla completa'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(FloorDetailScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
