  import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../widgets/diagonal_split_painter.dart';
import '../data/carreras.dart';
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

  Carrera? _carreraSeleccionada;
  int? _periodoSeleccionado;

  bool _isLoading = false;
  bool _obscurePassword = true;

  String _formatPeriodo(Carrera carrera, int periodo) {
    final unidad = carrera.unidad == UnidadAcademica.anio ? 'Año' : 'Semestre';
    return '$periodo° $unidad';
  }

  Future<void> _seleccionarCarrera() async {
    final colorScheme = Theme.of(context).colorScheme;
    final carrera = await showModalBottomSheet<Carrera>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Selecciona tu carrera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: areasUpea.length,
                    itemBuilder: (context, index) {
                      final area = areasUpea[index];
                      return ExpansionTile(
                        title: Text(
                          area.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        children: area.carreras.map((carrera) {
                          return ListTile(
                            title: Text(
                              carrera.nombre,
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                            ),
                            onTap: () => Navigator.of(context).pop(carrera),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (carrera != null) {
      setState(() {
        _carreraSeleccionada = carrera;
        _periodoSeleccionado = null;
      });
    }
  }

  Future<void> _seleccionarPeriodo() async {
    if (_carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona tu carrera')),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final carrera = _carreraSeleccionada!;
    final unidadTexto = carrera.unidad == UnidadAcademica.anio ? 'Año' : 'Semestre';

    final periodo = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecciona tu $unidadTexto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: carrera.duracion,
                  itemBuilder: (context, index) {
                    final numero = index + 1;
                    return ListTile(
                      title: Text(
                        '$numero° $unidadTexto',
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                      ),
                      onTap: () => Navigator.of(context).pop(numero),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (periodo != null) {
      setState(() {
        _periodoSeleccionado = periodo;
      });
    }
  }

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu carrera')),
      );
      return;
    }
    if (_periodoSeleccionado == null) {
      final unidad = _carreraSeleccionada!.unidad == UnidadAcademica.anio ? 'año' : 'semestre';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona tu $unidad')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.register(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        carrera: _carreraSeleccionada!.nombre,
        semestre: _formatPeriodo(_carreraSeleccionada!, _periodoSeleccionado!),
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

  Widget _selectorField({
    required String label,
    required IconData icon,
    required String? valueText,
    required Color fillColor,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valueText ?? label,
                style: TextStyle(
                  fontSize: 14,
                  color: valueText != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

    final labelPeriodo = _carreraSeleccionada == null
        ? 'Semestre / Año'
        : (_carreraSeleccionada!.unidad == UnidadAcademica.anio ? 'Año' : 'Semestre');

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
                                _selectorField(
                                  label: 'Carrera',
                                  icon: Icons.school_outlined,
                                  valueText: _carreraSeleccionada?.nombre,
                                  fillColor: fillColor,
                                  colorScheme: colorScheme,
                                  onTap: _seleccionarCarrera,
                                ),
                                const SizedBox(height: 12),
                                _selectorField(
                                  label: labelPeriodo,
                                  icon: Icons.grade_outlined,
                                  valueText: _carreraSeleccionada != null && _periodoSeleccionado != null
                                      ? _formatPeriodo(_carreraSeleccionada!, _periodoSeleccionado!)
                                      : null,
                                  fillColor: fillColor,
                                  colorScheme: colorScheme,
                                  onTap: _seleccionarPeriodo,
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

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
