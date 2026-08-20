import 'package:flutter/material.dart';

/// Pinta un fondo dividido en dos bloques de color separados por una
/// diagonal, SIN degradado entre ellos: colorA ocupa todo el fondo y
/// colorB es una cuña diagonal que entra desde la esquina superior
/// derecha. Se usa en el tema UPEA para el efecto "banner de marca"
/// azul+rojo, en vez de mezclar los colores como antes.
class DiagonalSplitPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;
  final double splitFraction;

  const DiagonalSplitPainter({
    required this.colorA,
    required this.colorB,
    this.splitFraction = 0.55,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colorA);

    final wedge = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * splitFraction, size.height)
      ..close();
    canvas.drawPath(wedge, Paint()..color = colorB);
  }

  @override
  bool shouldRepaint(covariant DiagonalSplitPainter oldDelegate) =>
      oldDelegate.colorA != colorA ||
      oldDelegate.colorB != colorB ||
      oldDelegate.splitFraction != splitFraction;
}
