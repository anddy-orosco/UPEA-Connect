import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';

class DrawerMenu extends StatelessWidget {
  final UserModel? currentUser;
  final Function(int) onMenuItemSelected;
  final VoidCallback onLogout;
  final int selectedIndex;

  const DrawerMenu({
    super.key,
    required this.currentUser,
    required this.onMenuItemSelected,
    required this.onLogout,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.blanco,
        child: Column(
          children: [
            // Header con datos del usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: AppColors.azulGradiente,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Foto de perfil
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
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
                      child: currentUser?.fotoPath != null
                          ? Image.file(
                        File(currentUser!.fotoPath!),
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: AppColors.grisClaro,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.azulPrincipal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.nombre ?? 'Estudiante',
                    style: const TextStyle(
                      color: AppColors.blanco,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? 'email@ejemplo.com',
                    style: TextStyle(
                      color: AppColors.blanco.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menú de opciones
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(
                    icon: Icons.home,
                    label: 'Inicio',
                    index: 0,
                  ),
                  _buildMenuItem(
                    icon: Icons.person,
                    label: 'Mi Perfil',
                    index: 1,
                  ),
                  _buildMenuItem(
                    icon: Icons.switch_account,
                    label: 'Cambiar Cuenta',
                    index: 2,
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_month,
                    label: 'Horario',
                    index: 3,
                  ),
                  _buildMenuItem(
                    icon: Icons.note,
                    label: 'Apuntes',
                    index: 4,
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment,
                    label: 'Tareas',
                    index: 5,
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    label: 'Cerrar Sesión',
                    index: -1,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return Builder(
      builder: (context) {
        final isSelected = index >= 0 && selectedIndex == index;
        final isLogout = index == -1;

        return ListTile(
          leading: Icon(
            icon,
            color: isLogout
                ? AppColors.rojoAlerta
                : isSelected
                ? AppColors.azulPrincipal
                : Colors.grey[700],
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isLogout
                  ? AppColors.rojoAlerta
                  : isSelected
                  ? AppColors.azulPrincipal
                  : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          tileColor: isSelected ? AppColors.grisClaro : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: () {
            if (isLogout) {
              _showLogoutDialog(context);
            } else {
              onMenuItemSelected(index);
            }
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rojoAlerta,
                foregroundColor: AppColors.blanco,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}