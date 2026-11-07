import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/escudo_vector.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Pantalla de presentación animada con el escudo de la UPEA.
/// Diseño oscuro fijo (estilo intro web), sin depender del tema activo.
class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final bool onboardingVisto;

  const SplashScreen({
    super.key,
    required this.isLoggedIn,
    required this.onboardingVisto,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duracionSeg = 2.4; // 2.4 s

  // Colores fijos (diseño oscuro, independiente del tema).
  static const Color _fondo = Color(0xFF0B1220);
  static const Color _contorno = Color(0xFF9FB3D1);
  static const Color _rellenoAzul = Color(0xFFF2F1EC);
  static const Color _acento = Color(0xFFE0284F);

  late AnimationController _controller;
  late Animation<double> _trazo;
  late Animation<double> _rellenoAnim;
  late Animation<double> _texto;
  late Animation<double> _telon;

  // Métricas de camino calculadas una sola vez para el trazo progresivo.
  late final PathMetric _metroAzul;
  late final PathMetric _metroRojo;
  late final double _largoAzul;
  late final double _largoRojo;

  bool _navigating = false;
  bool _disableAnimations = false;
  bool _iniciado = false;
  bool _hapticDisparado = false;

  /// Crea un CurvedAnimation usando segundos (0.0–2.4 s) divididos por la
  /// duración total, para que begin <= end y ambos estén en [0, 1].
  Animation<double> _tramo(
    double inicioSeg,
    double finSeg, {
    Curve curva = Curves.easeOut,
  }) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          inicioSeg / _duracionSeg,
          finSeg / _duracionSeg,
          curve: curva,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Calcular métricas de los caminos una sola vez.
    final metricasAzul = EscudoVector.azul.computeMetrics();
    final metricasRojo = EscudoVector.rojo.computeMetrics();
    _metroAzul = metricasAzul.first;
    _metroRojo = metricasRojo.first;
    _largoAzul = _metroAzul.length;
    _largoRojo = _metroRojo.length;

    _trazo = _tramo(0.0, 0.55);
    _rellenoAnim = _tramo(0.85, 1.15);
    _texto = _tramo(0.95, 1.45);
    _telon = _tramo(1.55, 1.95, curva: const Cubic(0.7, 0, 0.2, 1));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigating) {
        _irASiguiente();
      }
    });

    _controller.addListener(() {
      const hapticUmbral = 0.85 / 2.4;
      if (!_hapticDisparado && _controller.value >= hapticUmbral) {
        _hapticDisparado = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;

    _disableAnimations = MediaQuery.of(context).disableAnimations;

    if (_disableAnimations) {
      _controller.value = 1.0;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _irASiguiente();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _irASiguiente() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    _controller.stop();

    Widget siguiente;
    if (widget.isLoggedIn) {
      siguiente = const HomeScreen();
    } else if (!widget.onboardingVisto) {
      siguiente = const OnboardingScreen();
    } else {
      siguiente = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => siguiente,
        transitionsBuilder: (context, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _saltar() {
    _irASiguiente();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _saltar,
      child: Scaffold(
        backgroundColor: _fondo,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final anchoDisponible = constraints.maxWidth;
              final altoDisponible = constraints.maxHeight;
              final tamanoLogo = math.min(
                anchoDisponible * 0.70,
                math.min(altoDisponible * 0.42, 380.0),
              );
              final escala = tamanoLogo / EscudoVector.ancho;
              final altoLogo = EscudoVector.alto * escala;

              if (_disableAnimations) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: escala,
                        child: CustomPaint(
                          size: Size(EscudoVector.ancho, EscudoVector.alto),
                          painter: const _EscudoCompletoPainter(
                            colorContorno: Color(0xFF9FB3D1),
                            colorRellenoAzul: Color(0xFFF2F1EC),
                            colorAcento: Color(0xFFE0284F),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RepaintBoundary(
                child: SizedBox.expand(
                  child: ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -_telon.value * altoDisponible),
                      child: SingleChildScrollView(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            // Logo con trazo progresivo y luego relleno.
                            Transform.scale(
                              scale: escala,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(
                                      EscudoVector.ancho,
                                      EscudoVector.alto,
                                    ),
                                    painter: _EscudoTrazoPainter(
                                      progresoTrazo: _trazo.value,
                                      progresoRelleno: _rellenoAnim.value,
                                      largoAzul: _largoAzul,
                                      largoRojo: _largoRojo,
                                      metroAzul: _metroAzul,
                                      metroRojo: _metroRojo,
                                      colorContorno: _contorno,
                                      colorRellenoAzul: _rellenoAzul,
                                      colorAcento: _acento,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: altoLogo * 0.12),
                            // Texto "UPEA Connect" revelado de izquierda a derecha.
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: ClipRect(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _texto.value,
                                        child: RichText(
                                          text: const TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'UPEA',
                                                style: TextStyle(
                                                  color: _rellenoAzul,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' Connect',
                                                style: TextStyle(
                                                  color: _acento,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                           ],
                         ),
                       ),
                     ),    // cierra SingleChildScrollView
                   ),    // cierra Transform.translate
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dibuja el escudo con trazo progresivo del contorno y luego relleno.
class _EscudoTrazoPainter extends CustomPainter {
  final double progresoTrazo;
  final double progresoRelleno;
  final double largoAzul;
  final double largoRojo;
  final PathMetric metroAzul;
  final PathMetric metroRojo;
  final Color colorContorno;
  final Color colorRellenoAzul;
  final Color colorAcento;

  const _EscudoTrazoPainter({
    required this.progresoTrazo,
    required this.progresoRelleno,
    required this.largoAzul,
    required this.largoRojo,
    required this.metroAzul,
    required this.metroRojo,
    required this.colorContorno,
    required this.colorRellenoAzul,
    required this.colorAcento,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Relleno (aparece después del trazo).
    if (progresoRelleno > 0) {
      final paintRelleno = Paint()..style = PaintingStyle.fill;
      // Dibujar azul.
      paintRelleno.color = colorRellenoAzul;
      canvas.drawPath(EscudoVector.azul, paintRelleno);
      // Dibujar rojo como acento (cabeza).
      paintRelleno.color = colorAcento;
      canvas.drawPath(EscudoVector.rojo, paintRelleno);
    }

    // Trazo progresivo del contorno.
    final paintTrazo = Paint()
      ..color = colorContorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    if (largoAzul > 0) {
      final finAzul = largoAzul * progresoTrazo;
      final segmentoAzul =
          metroAzul.extractPath(0.0, finAzul.clamp(0.0, largoAzul));
      canvas.drawPath(segmentoAzul, paintTrazo);
    }
    if (largoRojo > 0) {
      final finRojo = largoRojo * progresoTrazo;
      final segmentoRojo =
          metroRojo.extractPath(0.0, finRojo.clamp(0.0, largoRojo));
      canvas.drawPath(segmentoRojo, paintTrazo);
    }
  }

  @override
  bool shouldRepaint(covariant _EscudoTrazoPainter old) =>
      old.progresoTrazo != progresoTrazo ||
      old.progresoRelleno != progresoRelleno;
}

/// Dibuja el escudo completo (usado cuando desactivan las animaciones).
class _EscudoCompletoPainter extends CustomPainter {
  final Color colorContorno;
  final Color colorRellenoAzul;
  final Color colorAcento;

  const _EscudoCompletoPainter({
    required this.colorContorno,
    required this.colorRellenoAzul,
    required this.colorAcento,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintAzul = Paint()..color = colorRellenoAzul;
    final paintRojo = Paint()..color = colorAcento;
    final paintTrazo = Paint()
      ..color = colorContorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(EscudoVector.azul, paintAzul);
    canvas.drawPath(EscudoVector.rojo, paintRojo);
    canvas.drawPath(EscudoVector.azul, paintTrazo);
    canvas.drawPath(EscudoVector.rojo, paintTrazo);
  }

  @override
  bool shouldRepaint(covariant _EscudoCompletoPainter old) => false;
}
