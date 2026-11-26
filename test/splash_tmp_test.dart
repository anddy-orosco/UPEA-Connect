import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/screens/splash_screen.dart';
import '../lib/services/theme_service.dart';
import '../lib/services/connectivity_service.dart';

void main() {
  final List<Size> tamanos = [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1280, 800),
    const Size(1920, 1080),
  ];

  for (final tamano in tamanos) {
    testWidgets(
      'SplashScreen sin overflow en ${tamano.width}x${tamano.height}',
      (WidgetTester tester) async {
        tester.view.physicalSize = tamano;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeService>.value(
                value: ThemeService(),
              ),
              ChangeNotifierProvider<ConnectivityService>.value(
                value: ConnectivityService.instance,
              ),
            ],
            child: MaterialApp(
              home: SplashScreen(
                isLoggedIn: false,
                onboardingVisto: true,
              ),
            ),
          ),
        );

        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 3000));

        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'Excepcion en $tamano @ 3000ms',
        );

        // Verificar centrado horizontal del logo (Key('splash_logo'))
        final logoFinder = find.byKey(const Key('splash_logo'));
        expect(logoFinder, findsOneWidget, reason: 'Logo no encontrado en $tamano');
        final logoRect = tester.getRect(logoFinder);
        final centroXLogo = logoRect.center.dx;
        expect(
          (centroXLogo - tamano.width / 2).abs(),
          lessThan(1.5),
          reason: 'Centro X del logo desviado en $tamano: $centroXLogo vs ${tamano.width / 2}',
        );

        // Verificar centrado horizontal del texto (Key('splash_texto'))
        final textoFinder = find.byKey(const Key('splash_texto'));
        expect(textoFinder, findsOneWidget, reason: 'Texto no encontrado en $tamano');
        final textoRect = tester.getRect(textoFinder);
        final centroXTexto = textoRect.center.dx;
        expect(
          (centroXTexto - tamano.width / 2).abs(),
          lessThan(1.5),
          reason: 'Centro X del texto desviado en $tamano: $centroXTexto vs ${tamano.width / 2}',
        );

        // Verificar centrado vertical del grupo (logo + texto)
        // El grupo va desde el borde superior del logo hasta el borde inferior del texto
        final grupoTop = logoRect.top;
        final grupoBottom = textoRect.bottom;
        final centroYGrupo = (grupoTop + grupoBottom) / 2;
        expect(
          (centroYGrupo - tamano.height / 2).abs(),
          lessThan(3.0),
          reason: 'Centro Y del grupo desviado en $tamano: $centroYGrupo vs ${tamano.height / 2}',
        );
      },
    );
  }
}
