import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'account_switcher.dart';
import 'notes_screen.dart'; // <-- IMPORTANTE: Importar NotesScreen
import '../widgets/drawer_menu.dart';

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

      print('✅ Usuario cargado: $nombre');
    } catch (e) {
      print('❌ Error cargando usuario: $e');
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

    // Mostrar mensaje de confirmación
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
        return 'Horario';
      case 4:
        return 'Mis Apuntes';
      case 5:
        return 'Tareas';
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
            // Volver a la pantalla de inicio después de cambiar cuenta
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 3:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                size: 80,
                color: AppColors.azulPrincipal,
              ),
              SizedBox(height: 20),
              Text(
                'Pantalla de Horario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulOscuro,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Próximamente...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      case 4:
        return const NotesScreen(); // <-- Pantalla de notas implementada
      case 5:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment,
                size: 80,
                color: AppColors.azulPrincipal,
              ),
              SizedBox(height: 20),
              Text(
                'Pantalla de Tareas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulOscuro,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Próximamente...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.azulPrincipal,
            AppColors.blanco,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto de perfil
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blanco,
                  border: Border.all(
                    color: AppColors.azulPrincipal,
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
                      : Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.azulPrincipal,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Mensaje de bienvenida personalizado
              Text(
                '¡Bienvenido, ${_currentUser!.nombre}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.azulOscuro,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Carrera
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  _currentUser!.carrera.isNotEmpty
                      ? _currentUser!.carrera
                      : 'Carrera no especificada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.azulOscuro.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Semestre
              Text(
                _currentUser!.semestre.isNotEmpty
                    ? 'Semestre: ${_currentUser!.semestre}'
                    : 'Semestre no especificado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.azulOscuro.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 30),

              // Tarjetas de acceso rápido (opcional)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAccessCard(
                      icon: Icons.note,
                      label: 'Apuntes',
                      index: 4,
                    ),
                    _buildQuickAccessCard(
                      icon: Icons.calendar_month,
                      label: 'Horario',
                      index: 3,
                    ),
                    _buildQuickAccessCard(
                      icon: Icons.assignment,
                      label: 'Tareas',
                      index: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: AppColors.azulPrincipal,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}