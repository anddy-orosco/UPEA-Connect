import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

/// Onboarding de 4 pantallas que se muestra solo la primera vez.
/// Al finalizar o saltar guarda 'onboarding_visto' y navega a LoginScreen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _navigating = false;

  static const List<Map<String, String>> _pages = [
    {
      'icon': 'school',
      'title': 'Tu universidad en el bolsillo',
      'description':
          'Accede a tus datos académicos, horarios y avisos desde cualquier lugar.',
    },
    {
      'icon': 'event_note',
      'title': 'Apuntes y calendario siempre contigo',
      'description':
          'Organiza tus materias, tareas y fechas importantes en un solo sitio.',
    },
    {
      'icon': 'timer',
      'title': 'Enfócate y haz crecer tu planta',
      'description':
          'Usa el temporizador Pomodoro y cuida tu planta mientras estudias.',
    },
    {
      'icon': 'robot_2',
      'title': 'Un asistente que conoce la UPEA',
      'description':
          'Consulta dudas sobre la universidad con tu asistente de IA integrado.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finalizar() async {
    if (_navigating || !mounted) return;
    _navigating = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_visto', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (context, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _irASiguiente() {
    if (_navigating || !mounted) return;
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finalizar();
    }
  }

  Widget _barraProgreso(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final activo = _currentPage == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: activo ? 32 : 16,
      decoration: BoxDecoration(
        color: activo
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _pagina(int index, Map<String, String> pagina) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconData = _iconoDe(pagina['icon']!);

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double paginaActual = _pageController.page?.toDouble() ?? 0.0;
        double valor =
            1 - ((paginaActual - index).abs().clamp(0.0, 1.0).toDouble());
        return Opacity(
          opacity: 0.4 + 0.6 * valor,
          child: Transform.scale(
            scale: 0.85 + 0.15 * valor,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              pagina['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pagina['description']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconoDe(String nombre) {
    switch (nombre) {
      case 'school':
        return Icons.school;
      case 'event_note':
        return Icons.event_note;
      case 'timer':
        return Icons.timer;
      case 'robot_2':
        return Icons.smart_toy;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final esUltima = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => _barraProgreso(i),
                ),
              ),
            ),
            if (!esUltima)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 24, 0),
                  child: TextButton(
                    onPressed: _navigating ? null : _finalizar,
                    child: Text(
                      'Saltar',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _pagina(i, _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _navigating ? null : _irASiguiente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text(
                    esUltima ? 'Comenzar' : 'Siguiente',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
