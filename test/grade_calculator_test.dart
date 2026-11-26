import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_universitaria/screens/grade_calculator_screen.dart';

void main() {
  testWidgets(
      'Converts grades cleanly between Direct and Scale 100 and caps base at 100 unless extra points are added',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GradeCalculatorScreen(),
      ),
    );

    // Hay 7 evaluaciones por defecto + 1 campo de puntos extra = 8 TextFields
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(8));

    // 1. Ingresar 20 pts en 1° Parcial (ponderación 25 pts) en modo Nota Directa
    await tester.enterText(textFields.at(0), '20');
    await tester.pump();
    expect(find.text('20.0'), findsAtLeastNWidgets(1));

    // 2. Cambiar a modo "Sobre 100 (ej. 80/100)" -> debe convertir 20/25 a "80"
    await tester.tap(find.text('Sobre 100 (ej. 80/100)'));
    await tester.pump();
    final tfAfterTo100 = tester.widget<TextField>(textFields.at(0));
    expect(tfAfterTo100.controller?.text, '80');
    expect(find.text('20.0'), findsAtLeastNWidgets(1));

    // 3. Cambiar de vuelta a "Nota Directa (ej. 20/25)" -> debe convertir 80/100 a "20"
    await tester.tap(find.text('Nota Directa (ej. 20/25)'));
    await tester.pump();
    final tfBackToDirect = tester.widget<TextField>(textFields.at(0));
    expect(tfBackToDirect.controller?.text, '20');
    expect(find.text('20.0'), findsAtLeastNWidgets(1));

    // 4. Intentar ingresar 99 en 1° Parcial (max 25) -> debe limitarse a "25"
    await tester.enterText(textFields.at(0), '99');
    await tester.pump();
    expect(tester.widget<TextField>(textFields.at(0)).controller?.text, '25');

    // 5. Llenar todas las evaluaciones al máximo -> total base 100.0
    await tester.enterText(textFields.at(1), '25'); // 2° Parcial (25)
    await tester.enterText(textFields.at(2), '25'); // 3° Parcial (25)
    await tester.enterText(textFields.at(3), '5');  // Práctica 1 (5)
    await tester.enterText(textFields.at(4), '5');  // Práctica 2 (5)
    await tester.enterText(textFields.at(5), '5');  // Práctica 3 (5)
    await tester.enterText(textFields.at(6), '10'); // Auxiliatura (10)
    await tester.pump();
    expect(find.text('100.0'), findsOneWidget);

    // 6. Agregar ítem extra de 20 pts y tratar de ingresar 15 -> tope base sigue en 100.0
    await tester.ensureVisible(find.text('Agregar Ítem'));
    await tester.tap(find.text('Agregar Ítem'));
    await tester.pumpAndSettle();
    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Asistencia');
    await tester.enterText(dialogFields.at(1), '20');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    final updatedFields = find.byType(TextField);
    expect(updatedFields, findsNWidgets(9));
    // Campo 7 es el nuevo ítem; campo 8 es Puntos Extra
    await tester.ensureVisible(updatedFields.at(7));
    await tester.enterText(updatedFields.at(7), '15');
    await tester.pump();
    expect(tester.widget<TextField>(updatedFields.at(7)).controller?.text, '0');
    expect(find.text('100.0'), findsOneWidget);

    // 7. Sumar 8 puntos extra -> sí debe superar los 100 pts (108.0)
    await tester.ensureVisible(updatedFields.at(8));
    await tester.enterText(updatedFields.at(8), '8');
    await tester.pump();
    expect(find.text('108.0'), findsOneWidget);
  });
}
