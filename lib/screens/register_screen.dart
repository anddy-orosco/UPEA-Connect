import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../widgets/diagonal_split_painter.dart';
import 'verify_email_screen.dart';

/// Pantalla de creación de cuenta.
/// Vive en lib/screens/register_screen.dart
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _carreraController = TextEditingController();
  final _semestreController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.register(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        carrera: _carreraController.text.trim(),
        semestre: _semestreController.text.trim(),
      );

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(
              token: token,
              email: user['email'] ?? _emailController.text.trim(),
              user: user,
            ),
          ),
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
    if (texto.contains('EMAIL_ALREADY_REGISTERED') ||
        texto.toLowerCase().contains('ya está registrado')) {
      return 'Ese email ya tiene una cuenta. Inicia sesión en su lugar';
    }
    return 'No se pudo crear la cuenta. Intenta de nuevo';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

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
                        Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Únete a UPEA-Connect',
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _campo(
                                  controller: _nombreController,
                                  label: 'Nombre completo',
                                  icon: Icons.person_outline,
                                  fillColor: fillColor,
                                  colorScheme: colorScheme,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                                ),
                                const SizedBox(height: 12),
                                _campo(
                                  controller: _emailController,
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
                                  fillColor: fillColor,
                                  colorScheme: colorScheme,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Ingresa tu email';
                                    if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                                    if (v.length < 8) return 'Mínimo 8 caracteres';
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
                                const SizedBox(height: 12),
                                _campo(
                                  controller: _carreraController,
                                  label: 'Carrera',
                                  icon: Icons.school_outlined,
                                  fillColor: fillColor,
                                  colorScheme: colorScheme,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu carrera' : null,
                                ),
                                const SizedBox(height: 12),
                                _campo(
                                  controller: _semestreController,
                                  label: 'Semestre',
                                  icon: Icons.grade_outlined,
                                  fillColor: fillColor,
                                  colorScheme: colorScheme,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu semestre' : null,
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _crearCuenta,
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
                                            'Crear cuenta',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color fillColor,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: fillColor,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _carreraController.dispose();
    _semestreController.dispose();
    super.dispose();
  }
}