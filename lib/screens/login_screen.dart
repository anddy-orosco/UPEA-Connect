import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../widgets/diagonal_split_painter.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Pantalla de inicio de sesión.
/// Vive en lib/screens/login_screen.dart
///
/// Reemplaza al formulario anterior que pedía todos los datos
/// (nombre, carrera, semestre) cada vez. Ahora solo pide email
/// y contraseña; crear cuenta nueva vive en register_screen.dart.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_nombre', user['nombre'] ?? '');
      await prefs.setString('user_email', user['email'] ?? '');
      await prefs.setString('user_carrera', user['carrera'] ?? '');
      await prefs.setString('user_semestre', user['semestre'] ?? '');
      await prefs.setBool('is_logged_in', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mensajeError(Object e) {
    final texto = e.toString();
    if (texto.contains('INVALID_CREDENTIALS') ||
        texto.toLowerCase().contains('credenciales') ||
        texto.toLowerCase().contains('incorrect')) {
      return 'Email o contraseña incorrectos';
    }
    return 'No se pudo iniciar sesión. Intenta de nuevo';
  }

  void _irACrearCuenta() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  // Fondo según el tema activo: negro plano en Oscuro (nada de degradado
  // ni azul), división diagonal azul/rojo en UPEA, degradado
  // primary -> secondary en Predeterminado y Rosado. Mismo criterio que
  // ya se usa en el banner de Inicio y el header del drawer.
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

    return Scaffold(
      body: _buildBackground(
        context,
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school,
                      size: 38,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Inicia sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bienvenido de vuelta a UPEA-Connect',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onPrimary.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu email';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              labelStyle: const TextStyle(fontSize: 13),
                              hintText: 'nombre@ejemplo.com',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: Icon(Icons.email_outlined, size: 20, color: colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: fillColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: Icon(Icons.lock_outline, size: 20, color: colorScheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: fillColor,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _iniciarSesion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿No tienes cuenta?',
                                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _irACrearCuenta,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
