import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';
import 'login_screen.dart'; // <-- IMPORTANTE: Importar LoginScreen

class AccountSwitcher extends StatefulWidget {
  final UserModel currentUser;
  final Function(UserModel) onAccountSelected;

  const AccountSwitcher({
    super.key,
    required this.currentUser,
    required this.onAccountSelected,
  });

  @override
  State<AccountSwitcher> createState() => _AccountSwitcherState();
}

class _AccountSwitcherState extends State<AccountSwitcher> {
  List<Map<String, String>> _savedAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString('saved_accounts');

      if (accountsJson != null && accountsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(accountsJson);
        setState(() {
          _savedAccounts = decoded.map((item) =>
          Map<String, String>.from(item as Map)
          ).toList();
        });
      }
    } catch (e) {
      print('Error cargando cuentas: $e');
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
    } catch (e) {
      print('Error guardando cuentas: $e');
    }
  }

  Future<void> _deleteAccount(String email) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta cuenta?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rojoAlerta,
              foregroundColor: AppColors.blanco,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _savedAccounts.removeWhere((acc) => acc['email'] == email);
      });
      await _saveAccounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada'),
            backgroundColor: AppColors.rojoAlerta,
          ),
        );
      }
    }
  }

  Future<void> _switchToAccount(Map<String, String> account) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar como usuario actual
      await prefs.setString('user_nombre', account['nombre']!);
      await prefs.setString('user_email', account['email']!);
      await prefs.setString('user_carrera', account['carrera']!);
      await prefs.setString('user_semestre', account['semestre']!);
      await prefs.setBool('is_logged_in', true);

      final user = UserModel(
        nombre: account['nombre']!,
        email: account['email']!,
        carrera: account['carrera']!,
        semestre: account['semestre']!,
      );

      if (mounted) {
        // Actualizar el estado en HomeScreen
        widget.onAccountSelected(user);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Cambiado a ${user.nombre}'),
            backgroundColor: AppColors.verdeExito,
            duration: const Duration(seconds: 1),
          ),
        );

        // Pequeña pausa para que se vea el mensaje
        await Future.delayed(const Duration(milliseconds: 500));

        // Cerrar AccountSwitcher y volver
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar de cuenta: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Cuenta'),
        backgroundColor: AppColors.azulPrincipal,
        foregroundColor: AppColors.blanco,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulPrincipal),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          // Cuenta actual (destacada)
          _buildCurrentAccountCard(),

          const SizedBox(height: 30),

          // Título de otras cuentas
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.azulPrincipal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Otras cuentas guardadas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de cuentas guardadas
          if (_savedAccounts.isEmpty)
            _buildEmptyState()
          else
            ..._buildOtherAccountsList(),

          const SizedBox(height: 24),

          // Botón para agregar nueva cuenta
          _buildAddAccountButton(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCurrentAccountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.azulPrincipal,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blanco,
              AppColors.azulPrincipal.withOpacity(0.05),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.azulPrincipal,
            child: Text(
              widget.currentUser.nombre[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.blanco,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            widget.currentUser.nombre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                widget.currentUser.email,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.currentUser.carrera} • ${widget.currentUser.semestre}',
                style: TextStyle(
                  color: AppColors.azulPrincipal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.verdeExito.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.verdeExito),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.verdeExito,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Actual',
                  style: TextStyle(
                    color: AppColors.verdeExito,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay otras cuentas guardadas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las cuentas se guardan automáticamente\nal iniciar sesión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOtherAccountsList() {
    return _savedAccounts
        .where((acc) => acc['email'] != widget.currentUser.email)
        .map((account) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.azulPrincipal.withOpacity(0.1),
          child: Text(
            account['nombre']![0].toUpperCase(),
            style: TextStyle(
              color: AppColors.azulPrincipal,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          account['nombre']!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account['email']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${account['carrera']} • ${account['semestre']}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.azulPrincipal.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: ElevatedButton(
                onPressed: () => _switchToAccount(account),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrincipal,
                  foregroundColor: AppColors.blanco,
                  minimumSize: const Size(50, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Usar',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.rojoAlerta,
                size: 20,
              ),
              onPressed: () => _deleteAccount(account['email']!),
            ),
          ],
        ),
      ),
    )).toList();
  }

  Widget _buildAddAccountButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', false);
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Agregar Nueva Cuenta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulPrincipal,
          foregroundColor: AppColors.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}