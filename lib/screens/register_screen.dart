import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_nombre', user['nombre'] ?? '');
      await prefs.setString('user_email', user['email'] ?? '');
      await prefs.setString('user_carrera', user['carrera'] ?? '');
      await prefs.setString('user_semestre', user['semestre'] ?? '');
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
            backgroundColor: AppColors.rojoAlerta,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.azulGradiente,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
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
                        const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blanco,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Únete a UPEA-Connect',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.blanco.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 340,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.blanco,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.azulOscuro.withOpacity(0.12),
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
                                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                                ),
                                const SizedBox(height: 12),
                                _campo(
                                  controller: _emailController,
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
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
                                  style: const TextStyle(fontSize: 14),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                                    if (v.length < 8) return 'Mínimo 8 caracteres';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle: const TextStyle(fontSize: 13),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.azulPrincipal),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: Colors.grey,
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
                                    fillColor: AppColors.grisClaro,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _campo(
                                  controller: _carreraController,
                                  label: 'Carrera',
                                  icon: Icons.school_outlined,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu carrera' : null,
                                ),
                                const SizedBox(height: 12),
                                _campo(
                                  controller: _semestreController,
                                  label: 'Semestre',
                                  icon: Icons.grade_outlined,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu semestre' : null,
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _crearCuenta,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.azulPrincipal,
                                      foregroundColor: AppColors.blanco,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: AppColors.blanco,
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
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: Icon(icon, size: 20, color: AppColors.azulPrincipal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.grisClaro,
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
