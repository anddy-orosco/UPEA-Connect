import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../widgets/diagonal_split_painter.dart';
import 'home_screen.dart';

/// Pantalla de verificación de correo con código de 6 dígitos.
/// Vive en lib/screens/verify_email_screen.dart
class VerifyEmailScreen extends StatefulWidget {
  final String token;
  final String email;
  final Map<String, dynamic> user;

  const VerifyEmailScreen({
    super.key,
    required this.token,
    required this.email,
    required this.user,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == 6) {
      _verificar();
    }
  }

  Future<void> _verificar() async {
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa los 6 dígitos del código')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await ApiService.verifyEmail(token: widget.token, code: _code);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', widget.token);
      await prefs.setString('user_nombre', widget.user['nombre'] ?? '');
      await prefs.setString('user_email', widget.user['email'] ?? '');
      await prefs.setString('user_carrera', widget.user['carrera'] ?? '');
      await prefs.setString('user_semestre', widget.user['semestre'] ?? '');
      await prefs.setBool('is_logged_in', true);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mensajeError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _reenviar() async {
    if (_cooldown > 0) return;

    setState(() => _isResending = true);

    try {
      await ApiService.resendCode(token: widget.token);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado. Revisa tu correo (y spam)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mensajeError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _mensajeError(Object e) {
    final texto = e.toString();
    if (texto.contains('CODE_EXPIRED')) return 'El código expiró. Solicita uno nuevo';
    if (texto.contains('INVALID_CODE')) return 'Código incorrecto';
    if (texto.contains('TOO_MANY_ATTEMPTS')) return 'Demasiados intentos. Solicita un código nuevo';
    if (texto.contains('RESEND_COOLDOWN')) return 'Espera unos segundos antes de reenviar';
    if (texto.contains('NO_VERIFICATION_PENDING')) return 'No hay verificación pendiente';
    if (texto.contains('ALREADY_VERIFIED')) return 'Este correo ya está verificado';
    return 'Ocurrió un error. Intenta de nuevo';
  }

  Widget _buildBackground(BuildContext context, Widget child) {
    final colorScheme = Theme.of(context).colorScheme;
    final variant = Provider.of<ThemeService>(context).variant;

    switch (variant) {
      case AppThemeVariant.oscuro:
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        );
      case AppThemeVariant.upea:
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DiagonalSplitPainter(
                  colorA: colorScheme.primary,
                  colorB: colorScheme.secondary,
                ),
              ),
            ),
            child,
          ],
        );
      case AppThemeVariant.predeterminado:
      case AppThemeVariant.rosado:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
    }
  }

  Widget _digitBox(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _buildBackground(
        context,
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_email_read_outlined, size: 56, color: colorScheme.onPrimary),
                        const SizedBox(height: 16),
                        Text(
                          'Verifica tu correo',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enviamos un código a\n${widget.email}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onPrimary.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 340,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (i) => _digitBox(i)),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _verificar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isVerifying
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: colorScheme.onPrimary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Verificar',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: (_cooldown > 0 || _isResending) ? null : _reenviar,
                                child: Text(
                                  _cooldown > 0
                                      ? 'Reenviar código en ${_cooldown}s'
                                      : 'Reenviar código',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _cooldown > 0
                                        ? colorScheme.onSurface.withOpacity(0.4)
                                        : colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Si no ves el código, revisa la carpeta de spam',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}