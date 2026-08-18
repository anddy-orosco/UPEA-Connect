import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'account_switcher.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'grade_calculator_screen.dart';
import '../widgets/drawer_menu.dart';
import 'chat_screen.dart';

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
      Navigator.of(context).pushReplacementNamed('/login');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitleForIndex(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.azulPrincipal,
        foregroundColor: AppColors.blanco,
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulPrincipal),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.azulPrincipal,
            AppColors.blanco,
          ],
          stops: [0.0, 0.25],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Avatar de Perfil
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blanco,
                border: Border.all(
                  color: AppColors.blanco,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.azulOscuro.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: _currentUser!.fotoPath != null
                    ? Image.file(
                  File(_currentUser!.fotoPath!),
                  fit: BoxFit.cover,
                )
                    : const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.azulPrincipal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Bienvenido, ${_currentUser!.nombre}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.azulOscuro,
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
                color: AppColors.azulOscuro.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 🤖 BOTÓN DESTACADO Y LARGO PARA LA IA EN EL CENTRO
            _buildAiHeroButton(),

            const SizedBox(height: 24),

            // TÍTULO DE SECCIÓN
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Herramientas Académicas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulOscuro,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🛠️ LAS 3 HERRAMIENTAS PRINCIPALES EN ORDEN
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
    );
  }

  // BOTÓN DESTACADO Y PROMINENTE PARA EL CHAT IA
  Widget _buildAiHeroButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.35),
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
              _selectedIndex = 6; // Navegar a Asistente IA
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Pregúntale a la IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TARJETAS PARA LAS 3 HERRAMIENTAS PRINCIPALES
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
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