import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../widgets/diagonal_split_painter.dart';
import 'reset_password_screen.dart';

/// Pantalla 1 de recuperación de contraseña: pide el correo y envía el código.
/// Vive en lib/screens/forgot_password_screen.dart
class ForgotPasswordScreen extends StatefulWidget {
  final String? emailPrellenado;

  const ForgotPasswordScreen({
    super.key,
    this.emailPrellenado,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.emailPrellenado != null && widget.emailPrellenado!.isNotEmpty) {
      _emailController.text = widget.emailPrellenado!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      await ApiService.forgotPassword(email: email);
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
      if (mounted) setState(() => _isLoading = false);
    }

    // Siempre se muestra el mismo mensaje sin revelar si el correo existe,
    // y se avanza al paso 2 sin importar el resultado del servidor.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si el correo está registrado, te enviamos un código de 6 dígitos'),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: email),
        ),
      );
    }
  }

  String _mensajeError(Object e) {
    final texto = e.toString();
    if (texto.contains('TOO_MANY_REQUESTS') ||
        texto.toLowerCase().contains('demasiado')) {
      return 'Demasiados intentos. Espera un minuto antes de volver a enviar';
    }
    return 'No se pudo enviar el código. Intenta de nuevo';
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
                      Icons.lock_reset,
                      size: 38,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Olvidaste tu contraseña',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ingresa tu correo para recuperar el acceso',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onPrimary.withOpacity(0.85),
                    ),
                    textAlign: TextAlign.center,
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
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _enviarCodigo,
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
                                      'Enviar código',
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
      ),
    );
  }
}
