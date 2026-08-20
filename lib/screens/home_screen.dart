import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import '../widgets/diagonal_split_painter.dart';
import 'profile_screen.dart';
import 'account_switcher.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'grade_calculator_screen.dart';
import '../widgets/drawer_menu.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('user_nombre') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final carrera = prefs.getString('user_carrera') ?? '';
      final semestre = prefs.getString('user_semestre') ?? '';

      setState(() {
        _currentUser = UserModel(
          nombre: nombre,
          email: email,
          carrera: carrera,
          semestre: semestre,
        );
      });

      debugPrint('✅ Usuario cargado: $nombre');
    } catch (e) {
      debugPrint('❌ Error cargando usuario: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  void _updateUser(UserModel updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuenta cambiada a ${updatedUser.nombre}'),
          backgroundColor: AppColors.verdeExito,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitleForIndex(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: DrawerMenu(
        currentUser: _currentUser,
        onMenuItemSelected: _onMenuItemSelected,
        onLogout: _cerrarSesion,
        selectedIndex: _selectedIndex,
      ),
      body: _buildBody(),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Mi Perfil';
      case 2:
        return 'Cambiar Cuenta';
      case 3:
        return 'Calendario Académico';
      case 4:
        return 'Mis Apuntes';
      case 5:
        return 'Calculadora de Notas';
      case 6:
        return 'Asistente IA';
      default:
        return 'Inicio';
    }
  }

  Widget _buildBody() {
    if (_currentUser == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ProfileScreen(
          user: _currentUser!,
          onUserUpdated: _updateUser,
        );
      case 2:
        return AccountSwitcher(
          currentUser: _currentUser!,
          onAccountSelected: (user) {
            _updateUser(user);
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 3:
        return const CalendarScreen();
      case 4:
        return const NotesScreen();
      case 5:
        return const GradeCalculatorScreen();
      case 6:
        return const ChatScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final variant = Provider.of<ThemeService>(context).variant;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: scaffoldBg,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderBanner(variant, colorScheme, scaffoldBg),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildAiHeroButton(variant, colorScheme),
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Herramientas Académicas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    title: 'Calendario Académico',
                    subtitle: 'Fechas importantes y exámenes',
                    icon: Icons.calendar_month_rounded,
                    color: Colors.blue.shade600,
                    index: 3,
                  ),
                  const SizedBox(height: 10),

                  _buildFeatureCard(
                    title: 'Mis Apuntes',
                    subtitle: 'Tus notas y resúmenes de clase',
                    icon: Icons.note_alt_rounded,
                    color: Colors.amber.shade700,
                    index: 4,
                  ),
                  const SizedBox(height: 10),

                  _buildFeatureCard(
                    title: 'Calculadora de Notas',
                    subtitle: 'Control de promedio y nota requerida',
                    icon: Icons.calculate_rounded,
                    color: Colors.teal.shade600,
                    index: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Banner superior con avatar + nombre + carrera. El tratamiento de color
  // depende del tema activo: degradado para Predeterminado/Rosado, negro
  // plano para Oscuro, bloque diagonal azul/rojo (sin degradado) para UPEA.
  Widget _buildHeaderBanner(
    AppThemeVariant variant,
    ColorScheme colorScheme,
    Color scaffoldBg,
  ) {
    final avatarAndText = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.onPrimary,
              border: Border.all(color: colorScheme.onPrimary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _currentUser!.fotoPath != null
                  ? Image.file(File(_currentUser!.fotoPath!), fit: BoxFit.cover)
                  : Icon(Icons.person, size: 50, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '¡Bienvenido, ${_currentUser!.nombre}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser!.carrera.isNotEmpty
                ? '${_currentUser!.carrera} • Semestre ${_currentUser!.semestre}'
                : 'Estudiante Universitario',
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    switch (variant) {
      case AppThemeVariant.oscuro:
        // Netamente negro, sin degradado.
        return Container(
          width: double.infinity,
          color: scaffoldBg,
          child: avatarAndText,
        );

      case AppThemeVariant.upea:
        // Bloque diagonal azul/rojo, sin mezcla de color.
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
            avatarAndText,
          ],
        );

      case AppThemeVariant.predeterminado:
      case AppThemeVariant.rosado:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: avatarAndText,
        );
    }
  }

  // Botón destacado de la IA. El tratamiento de color sigue el tema activo:
  // degradado primary→secondary en Predeterminado/Rosado, color sólido
  // (sin degradado) en Oscuro, bloque azul con filo rojo en UPEA.
  Widget _buildAiHeroButton(AppThemeVariant variant, ColorScheme colorScheme) {
    late final BoxDecoration decoration;

    switch (variant) {
      case AppThemeVariant.oscuro:
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: colorScheme.primary,
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
        );
        break;
      case AppThemeVariant.upea:
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: colorScheme.primary,
          border: Border(
            left: BorderSide(color: colorScheme.secondary, width: 6),
          ),
        );
        break;
      case AppThemeVariant.predeterminado:
      case AppThemeVariant.rosado:
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
        break;
    }

    return Container(
      width: double.infinity,
      decoration: decoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            setState(() {
              _selectedIndex = 6;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Pregúntale a la IA',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ASISTENTE',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resuelve tus dudas académicas al instante',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.onPrimary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
