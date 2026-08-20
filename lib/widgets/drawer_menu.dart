import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'diagonal_split_painter.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final variant = Provider.of<ThemeService>(context).variant;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            _buildHeader(context, variant, colorScheme),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.home,
                    label: 'Inicio',
                    index: 0,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person,
                    label: 'Mi Perfil',
                    index: 1,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.switch_account,
                    label: 'Cambiar Cuenta',
                    index: 2,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.palette_outlined,
                    label: 'Temas',
                    index: -2,
                  ),
                  const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_month,
                    label: 'Calendario Académico',
                    index: 3,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.note,
                    label: 'Apuntes',
                    index: 4,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calculate,
                    label: 'Calculadora de Notas',
                    index: 5,
                  ),
                  const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.smart_toy,
                    label: 'Pregúntale a la IA',
                    index: 6,
                  ),
                  _buildMenuItem(
                    context: context,
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
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header del drawer: mismo criterio por tema que el banner de Inicio
  // (degradado en Predeterminado/Rosado, negro plano en Oscuro, bloque
  // diagonal azul/rojo sin degradado en UPEA).
  Widget _buildHeader(
    BuildContext context,
    AppThemeVariant variant,
    ColorScheme colorScheme,
  ) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.onPrimary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: currentUser?.fotoPath != null
                  ? Image.file(File(currentUser!.fotoPath!), fit: BoxFit.cover)
                  : Container(
                      color: colorScheme.onPrimary,
                      child: Icon(Icons.person, size: 40, color: colorScheme.primary),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentUser?.nombre ?? 'Estudiante',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser?.email ?? 'email@ejemplo.com',
            style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );

    final borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(30),
    );

    switch (variant) {
      case AppThemeVariant.oscuro:
        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: content,
          ),
        );

      case AppThemeVariant.upea:
        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DiagonalSplitPainter(
                    colorA: colorScheme.primary,
                    colorB: colorScheme.secondary,
                  ),
                ),
              ),
              content,
            ],
          ),
        );

      case AppThemeVariant.predeterminado:
      case AppThemeVariant.rosado:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius,
          ),
          child: content,
        );
    }
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = index >= 0 && selectedIndex == index;
    final isLogout = index == -1;

    final iconColor = isLogout
        ? colorScheme.error
        : isSelected
            ? colorScheme.primary
            : colorScheme.onSurface.withOpacity(0.7);

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          color: iconColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? colorScheme.primary.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        if (isLogout) {
          _showLogoutDialog(context);
        } else if (index == -2) {
          _showThemeDialog(context);
        } else {
          onMenuItemSelected(index);
        }
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Elige un tema'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppThemeVariant.values.map((variant) {
                  final isSelected = themeService.variant == variant;
                  final variantScheme = AppTheme.themeFor(variant).colorScheme;

                  return ListTile(
                    leading: ClipOval(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: variant == AppThemeVariant.upea
                            ? CustomPaint(
                                painter: DiagonalSplitPainter(
                                  colorA: variantScheme.primary,
                                  colorB: variantScheme.secondary,
                                ),
                              )
                            : Container(color: variantScheme.primary),
                      ),
                    ),
                    title: Text(AppTheme.nombres[variant]!),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      themeService.setTheme(variant);
                      setDialogState(() {});
                      Navigator.pop(dialogContext);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
