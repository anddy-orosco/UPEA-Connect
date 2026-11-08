// lib/screens/splash_screen.dart
// Splash animado de UPEA-Connect hecho con código (sin video, sin paquetes nuevos).
// Todo parte de UN solo centro (el del logo) y el grupo logo + texto queda centrado en pantalla.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

const double _duracionTotal = 3.6; // segundos
const Color _cian = Color(0xFF38BDF8);
const Color _azul = Color(0xFF2B7BFF);
const Color _blancoAzul = Color(0xFFEAF6FF);
const String _textoMarca = 'UPEA-CONNECT';

/// Interpolación suave (smoothstep) de 0 a 1 entre [a] y [b].
double _suave(double x, double a, double b) {
  final double t = ((x - a) / (b - a)).clamp(0.0, 1.0).toDouble();
  return t * t * (3.0 - 2.0 * t);
}

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
    with TickerProviderStateMixin {
  late final AnimationController _principal;
  late final AnimationController _ambiente;
  final List<CurvedAnimation> _curvas = <CurvedAnimation>[];
  late final CurvedAnimation _opLogo;
  late final CurvedAnimation _escalaLogo;
  late final List<CurvedAnimation> _letras;
  late final CurvedAnimation _brillo;
  late final CurvedAnimation _resplandorTexto;

  Timer? _seguridad;
  Timer? _estatico;
  Timer? _vibracion;
  bool _iniciado = false;
  bool _reducido = false;
  bool _navegando = false;

  /// Convierte un tramo en segundos a un Interval (siempre entre 0.0 y 1.0).
  CurvedAnimation _tramo(double inicio, double fin,
      {Curve curva = Curves.linear}) {
    final CurvedAnimation a = CurvedAnimation(
      parent: _principal,
      curve: Interval(inicio / _duracionTotal, fin / _duracionTotal,
          curve: curva),
    );
    _curvas.add(a);
    return a;
  }

  @override
  void initState() {
    super.initState();
    _principal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _ambiente = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _opLogo = _tramo(1.5, 1.9, curva: Curves.easeOut);
    _escalaLogo = _tramo(1.5, 2.2, curva: Curves.easeOutBack);
    _letras = List<CurvedAnimation>.generate(_textoMarca.length, (int i) {
      final double ini = 1.9 + i * 0.07;
      return _tramo(ini, ini + 0.35, curva: Curves.easeOutCubic);
    });
    _brillo = _tramo(2.9, 3.5, curva: Curves.easeInOut);
    _resplandorTexto = _tramo(2.7, 3.4, curva: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _reducido = MediaQuery.of(context).disableAnimations;

    if (_reducido) {
      // Sin animaciones: logo y texto estáticos un momento y se avanza.
      _principal.value = 1.0;
      _estatico = Timer(const Duration(milliseconds: 700), _navegar);
    } else {
      _principal.addStatusListener((AnimationStatus estado) {
        if (estado == AnimationStatus.completed) _navegar();
      });
      _principal.forward();
      _ambiente.repeat();
      _vibracion = Timer(const Duration(milliseconds: 1400), () {
        HapticFeedback.lightImpact();
      });
    }
    // Seguridad: pase lo que pase, se avanza.
    _seguridad = Timer(const Duration(seconds: 7), _navegar);
  }

  void _navegar() {
    if (_navegando || !mounted) return;
    _navegando = true;
    final Widget destino = widget.isLoggedIn
        ? const HomeScreen()
        : (widget.onboardingVisto
            ? const LoginScreen()
            : const OnboardingScreen());
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            destino,
        transitionsBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation, Widget child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _seguridad?.cancel();
    _estatico?.cancel();
    _vibracion?.cancel();
    for (final CurvedAnimation c in _curvas) {
      c.dispose();
    }
    _principal.dispose();
    _ambiente.dispose();
    super.dispose();
  }

  Widget _logoAnimado(double tam) {
    return AnimatedBuilder(
      animation: _principal,
      builder: (BuildContext context, Widget? hijo) {
        final double op = _opLogo.value.clamp(0.0, 1.0).toDouble();
        final double escala = 0.92 + 0.08 * _escalaLogo.value;
        return Opacity(
          opacity: op,
          child: Transform.scale(scale: escala, child: hijo),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tam * 0.22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _cian.withValues(alpha: 0.35),
              blurRadius: tam * 0.25,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/splash_logo.png',
          width: tam,
          height: tam,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _textoAnimado(double fuente) {
    return AnimatedBuilder(
      animation: _principal,
      builder: (BuildContext context, Widget? hijo) {
        final double resplandor = _resplandorTexto.value;
        final List<Widget> letras = <Widget>[];
        for (int i = 0; i < _textoMarca.length; i++) {
          final double v = _letras[i].value.clamp(0.0, 1.0).toDouble();
          final bool fuerte = i < 4; // "UPEA"
          Widget letra = Text(
            _textoMarca[i],
            style: TextStyle(
              fontSize: fuente,
              height: 1.1,
              letterSpacing: fuente * 0.04,
              fontWeight: fuerte ? FontWeight.w800 : FontWeight.w400,
              fontStyle: fuerte ? FontStyle.italic : FontStyle.normal,
              color: _blancoAzul,
              shadows: <Shadow>[
                Shadow(
                  color: _cian.withValues(alpha: 0.55 * resplandor),
                  blurRadius: fuente * 0.55,
                ),
              ],
            ),
          );
          if (v < 0.98) {
            final double sigma = (1.0 - v) * 4.0;
            letra = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: letra,
            );
          }
          letras.add(
            Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, (1.0 - v) * fuente * 0.4),
                child: letra,
              ),
            ),
          );
        }
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect r) {
            final double c = -0.3 + 1.6 * _brillo.value;
            return LinearGradient(
              colors: const <Color>[
                _blancoAzul,
                Color(0xFF7FD8FF),
                _blancoAzul,
              ],
              stops: <double>[
                (c - 0.18).clamp(0.0, 1.0).toDouble(),
                c.clamp(0.0, 1.0).toDouble(),
                (c + 0.18).clamp(0.0, 1.0).toDouble(),
              ],
            ).createShader(r);
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: letras),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navegar,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double ancho = c.maxWidth;
            final double alto = c.maxHeight;

            // UN solo centro: el grupo logo + texto queda centrado en pantalla.
            final double logo =
                math.min(math.min(ancho * 0.46, alto * 0.30), 300.0);
            final double espacio = logo * 0.14;
            final double fuente = logo * 0.17;
            final double altoTexto = fuente * 1.3;
            final double altoGrupo = logo + espacio + altoTexto;
            final double arriba = (alto - altoGrupo) / 2;
            final Offset centro = Offset(ancho / 2, arriba + logo / 2);
            final double anchoTexto = math.min(ancho * 0.86, logo * 2.2);

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _FondoPainter(
                        principal: _principal,
                        ambiente: _ambiente,
                        centro: centro,
                        logo: logo,
                        reducido: _reducido,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: arriba,
                  height: logo,
                  child: Center(
                    child: SizedBox(
                      key: const Key('splash_logo'),
                      width: logo,
                      height: logo,
                      child: _logoAnimado(logo),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: arriba + logo + espacio,
                  height: altoTexto,
                  child: Center(
                    child: SizedBox(
                      width: anchoTexto,
                      child: FittedBox(
                        key: const Key('splash_texto'),
                        fit: BoxFit.scaleDown,
                        child: _textoAnimado(fuente),
                      ),
                    ),
                  ),
                ),
                if (!_reducido)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _EfectosPainter(
                            principal: _principal,
                            centro: centro,
                            logo: logo,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Datos de partículas (generados una sola vez, con semilla fija)
// ---------------------------------------------------------------------------

class _Particula {
  const _Particula({
    required this.angulo,
    required this.radio,
    required this.desfase,
    required this.vueltas,
    required this.tam,
    required this.parpadeo,
  });

  final double angulo;
  final double radio; // en múltiplos del tamaño del logo
  final double desfase;
  final int vueltas;
  final double tam;
  final double parpadeo;
}

class _Chispa {
  const _Chispa({
    required this.angulo,
    required this.velocidad,
    required this.tam,
    required this.clara,
  });

  final double angulo;
  final double velocidad; // en múltiplos del tamaño del logo
  final double tam;
  final bool clara;
}

// ---------------------------------------------------------------------------
// Fondo: degradado, resplandor centrado en el logo, ondas, partículas y viñeta
// ---------------------------------------------------------------------------

class _FondoPainter extends CustomPainter {
  _FondoPainter({
    required this.principal,
    required this.ambiente,
    required this.centro,
    required this.logo,
    required this.reducido,
  }) : super(repaint: Listenable.merge(<Listenable>[principal, ambiente]));

  final Animation<double> principal;
  final Animation<double> ambiente;
  final Offset centro;
  final double logo;
  final bool reducido;

  static final List<_Particula> _particulas = _generarParticulas(42, 7);

  static List<_Particula> _generarParticulas(int n, int semilla) {
    final math.Random rnd = math.Random(semilla);
    return List<_Particula>.generate(n, (int i) {
      return _Particula(
        angulo: rnd.nextDouble() * 2 * math.pi,
        radio: 0.55 + 1.9 * math.pow(rnd.nextDouble(), 1.8).toDouble(),
        desfase: rnd.nextDouble(),
        vueltas: 1 + rnd.nextInt(2),
        tam: 0.8 + rnd.nextDouble() * 1.8,
        parpadeo: rnd.nextDouble() * 2 * math.pi,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect todo = Offset.zero & size;
    final double seg = principal.value * _duracionTotal;

    // Base: degradado vertical.
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF04080F), Color(0xFF071A33)],
        ).createShader(todo),
    );

    // Resplandor azul centrado EXACTAMENTE en el logo, que respira.
    final double respira = 1.0 + 0.04 * math.sin(ambiente.value * 2 * math.pi);
    final double intensidad = 0.22 + 0.78 * _suave(seg, 1.2, 2.0);
    final double radio = logo * 1.8 * respira;
    const Color azulProfundo = Color(0xFF0E3A6B);
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            azulProfundo.withValues(alpha: 0.45 * intensidad),
            azulProfundo.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );

    // Destello cuando explota la luz (alrededor de 1.5 s).
    final double destello =
        _suave(seg, 1.35, 1.6) * (1.0 - _suave(seg, 1.6, 2.3));
    if (destello > 0.0) {
      final double rd = logo * 1.1;
      canvas.drawCircle(
        centro,
        rd,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              _cian.withValues(alpha: 0.35 * destello),
              _cian.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: centro, radius: rd)),
      );
    }

    if (!reducido) {
      _pintarOndas(canvas, size, seg);
      _pintarParticulas(canvas, seg);
    }

    // Viñeta suave en los bordes.
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.95,
          colors: <Color>[Color(0x00000000), Color(0x8C000000)],
          stops: <double>[0.55, 1.0],
        ).createShader(todo),
    );
  }

  void _pintarOndas(Canvas canvas, Size size, double seg) {
    final double op = _suave(seg, 1.8, 2.7) * 0.32;
    if (op <= 0.0) return;
    final double fase = ambiente.value * 2 * math.pi;
    final double amp = logo * 0.12;
    final Rect banda = Rect.fromLTWH(0, 0, size.width, 1);
    // Desvanecidas en los extremos izquierdo y derecho.
    final Shader degradado = LinearGradient(
      colors: <Color>[
        _cian.withValues(alpha: 0.0),
        _cian.withValues(alpha: op),
        _azul.withValues(alpha: op),
        _azul.withValues(alpha: 0.0),
      ],
      stops: const <double>[0.0, 0.3, 0.7, 1.0],
    ).createShader(banda);

    for (int k = 0; k < 2; k++) {
      final Path onda = Path();
      final double signo = k == 0 ? 1.0 : -0.8;
      final double frecuencia = k == 0 ? 1.1 : 1.6;
      final double desplazamiento = k == 0 ? fase : -fase * 0.7 + 1.5;
      for (double x = 0; x <= size.width; x += 8) {
        final double u = x / size.width;
        final double y = centro.dy +
            amp *
                signo *
                math.sin(u * 2 * math.pi * frecuencia + desplazamiento);
        if (x == 0) {
          onda.moveTo(x, y);
        } else {
          onda.lineTo(x, y);
        }
      }
      canvas.drawPath(
        onda,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = k == 0 ? 1.6 : 1.1
          ..shader = degradado
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  void _pintarParticulas(Canvas canvas, double seg) {
    final double entra = _suave(seg, 1.6, 2.4);
    if (entra <= 0.0) return;
    final Paint pincel = Paint();
    for (final _Particula q in _particulas) {
      final double vida = (ambiente.value * q.vueltas + q.desfase) % 1.0;
      final double desvanece = math.sin(vida * math.pi);
      final double brillo =
          0.6 + 0.4 * math.sin(ambiente.value * 4 * math.pi + q.parpadeo);
      final double a =
          (entra * desvanece * brillo * 0.85).clamp(0.0, 1.0).toDouble();
      if (a < 0.02) continue;
      final double r = q.radio * logo;
      final Offset base = centro +
          Offset(math.cos(q.angulo) * r * 1.7, math.sin(q.angulo) * r * 0.9);
      final Offset pos = base.translate(0, -vida * logo * 0.9);
      pincel.color =
          (q.angulo > math.pi ? _blancoAzul : _cian).withValues(alpha: a);
      canvas.drawCircle(pos, q.tam, pincel);
    }
  }

  @override
  bool shouldRepaint(covariant _FondoPainter old) =>
      old.centro != centro || old.logo != logo || old.reducido != reducido;
}

// ---------------------------------------------------------------------------
// Efectos sobre el logo: estelas, contorno que se traza y explosión de luz
// ---------------------------------------------------------------------------

class _EfectosPainter extends CustomPainter {
  _EfectosPainter({
    required this.principal,
    required this.centro,
    required this.logo,
  }) : super(repaint: principal);

  final Animation<double> principal;
  final Offset centro;
  final double logo;

  static final List<_Chispa> _chispas = _generarChispas(60, 11);

  static List<_Chispa> _generarChispas(int n, int semilla) {
    final math.Random rnd = math.Random(semilla);
    return List<_Chispa>.generate(n, (int i) {
      return _Chispa(
        angulo: rnd.nextDouble() * 2 * math.pi,
        velocidad: 0.4 + rnd.nextDouble() * 1.2,
        tam: 1.0 + rnd.nextDouble() * 1.6,
        clara: rnd.nextBool(),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double seg = principal.value * _duracionTotal;
    if (seg < 1.7) _pintarEstelas(canvas, seg);
    if (seg > 0.55 && seg < 2.3) _pintarContorno(canvas, seg);
    if (seg > 1.35 && seg < 3.0) _pintarExplosion(canvas, seg);
  }

  // Tres estelas de luz que giran en espiral y se cierran hacia el logo.
  void _pintarEstelas(Canvas canvas, double seg) {
    final double p =
        Curves.easeInOut.transform((seg / 1.4).clamp(0.0, 1.0).toDouble());
    final double desv = 1.0 - _suave(seg, 1.15, 1.65);
    if (desv <= 0.0) return;
    const int pasos = 22;

    for (int k = 0; k < 3; k++) {
      final double fase = k * (2 * math.pi / 3);
      final double inclinacion = (k - 1) * 0.5;
      final double ci = math.cos(inclinacion);
      final double si = math.sin(inclinacion);

      Offset punto(double u) {
        final double th = fase + u * 2 * math.pi * 1.15;
        final double r = logo * (1.9 - 1.45 * u);
        final double x = math.cos(th) * r;
        final double y = math.sin(th) * r * 0.5;
        return centro + Offset(x * ci - y * si, x * si + y * ci);
      }

      final double ini = (p - 0.30).clamp(0.0, 1.0).toDouble();

      // Brillo difuso: UNA polilínea con blur por estela.
      final Path glow = Path();
      final Offset p0 = punto(ini);
      glow.moveTo(p0.dx, p0.dy);
      for (int i = 1; i <= pasos; i++) {
        final Offset q = punto(ini + (p - ini) * i / pasos);
        glow.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        glow,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = logo * 0.03
          ..strokeCap = StrokeCap.round
          ..color = _cian.withValues(alpha: 0.22 * desv)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Trazo nítido con cola que se hace más fina y transparente.
      Offset a = p0;
      for (int i = 1; i <= pasos; i++) {
        final double u = ini + (p - ini) * i / pasos;
        final Offset b = punto(u);
        final double f = i / pasos;
        final double alpha =
            math.pow(f, 1.6).toDouble() * 0.95 * desv;
        canvas.drawLine(
          a,
          b,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 0.8 + 2.2 * f
            ..color = (k == 1 ? _blancoAzul : _cian).withValues(alpha: alpha),
        );
        a = b;
      }

      // Cabeza luminosa.
      final Offset cabeza = punto(p);
      canvas.drawCircle(cabeza, logo * 0.05,
          Paint()..color = _cian.withValues(alpha: 0.18 * desv));
      canvas.drawCircle(cabeza, logo * 0.014 + 1.2,
          Paint()..color = _blancoAzul.withValues(alpha: 0.95 * desv));
    }
  }

  Path _orbita() {
    final Offset c = centro.translate(0, logo * 0.12);
    final double rx = logo * 0.40;
    final double ry = logo * 0.13;
    const double ang = -0.35;
    final double ca = math.cos(ang);
    final double sa = math.sin(ang);
    final Path path = Path();
    const int pasos = 90;
    for (int i = 0; i <= pasos; i++) {
      final double t = math.pi + 2 * math.pi * i / pasos;
      final double x = rx * math.cos(t);
      final double y = ry * math.sin(t);
      final Offset pt = c + Offset(x * ca - y * sa, x * sa + y * ca);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  // Una luz recorre el borde del logo y la órbita del planeta, dibujándolos.
  void _pintarContorno(Canvas canvas, double seg) {
    final double p = Curves.easeInOut
        .transform(((seg - 0.6) / 0.9).clamp(0.0, 1.0).toDouble());
    final double op = 1.0 - _suave(seg, 1.6, 2.2);
    if (op <= 0.0 || p <= 0.0) return;

    final Rect cuadro =
        Rect.fromCenter(center: centro, width: logo, height: logo);
    final Path borde = Path()
      ..addRRect(RRect.fromRectAndRadius(cuadro, Radius.circular(logo * 0.22)));

    final Paint brillo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = logo * 0.035
      ..strokeCap = StrokeCap.round
      ..color = _cian.withValues(alpha: 0.28 * op)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final Paint linea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = _blancoAzul.withValues(alpha: 0.9 * op);
    final Paint punta = Paint()..color = Colors.white.withValues(alpha: op);

    for (final Path path in <Path>[borde, _orbita()]) {
      for (final ui.PathMetric m in path.computeMetrics()) {
        final Path parte = m.extractPath(0, m.length * p);
        canvas.drawPath(parte, brillo);
        canvas.drawPath(parte, linea);
        final ui.Tangent? t = m.getTangentForOffset(m.length * p);
        if (t != null) {
          canvas.drawCircle(t.position, 2.0 + logo * 0.012, punta);
        }
      }
    }
  }

  // Explosión radial de chispas y un anillo de onda desde el centro del logo.
  void _pintarExplosion(Canvas canvas, double seg) {
    final double b = ((seg - 1.4) / 1.1).clamp(0.0, 1.0).toDouble();
    final double e = Curves.easeOutCubic.transform(b);
    final double alpha = math.pow(1.0 - b, 1.3).toDouble();
    final double escala = (logo / 240.0).clamp(0.6, 1.4).toDouble();
    final Paint pincel = Paint();

    for (final _Chispa c in _chispas) {
      final double d = c.velocidad * logo * e;
      final Offset pos =
          centro + Offset(math.cos(c.angulo) * d, math.sin(c.angulo) * d);
      pincel.color =
          (c.clara ? _blancoAzul : _cian).withValues(alpha: alpha * 0.9);
      canvas.drawCircle(pos, c.tam * escala * (1.0 - 0.5 * b), pincel);
    }

    final double br = ((seg - 1.4) / 0.7).clamp(0.0, 1.0).toDouble();
    if (br < 1.0) {
      final double radio =
          logo * (0.45 + 1.5 * Curves.easeOutCubic.transform(br));
      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5 + 2.0 * (1.0 - br)
          ..color = _cian.withValues(alpha: 0.6 * (1.0 - br)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EfectosPainter old) =>
      old.centro != centro || old.logo != logo;
}
