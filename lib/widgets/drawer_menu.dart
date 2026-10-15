import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'diagonal_split_painter.dart';
import 'user_photo.dart';
import '../screens/credits_screen.dart'; // <--- Importación de la pantalla de Créditos / Easter Egg

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
      width: 310,
      elevation: 16,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(context, variant, colorScheme),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildSectionHeader(context, 'MENÚ PRINCIPAL'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.home_rounded,
                      label: 'Inicio',
                      index: 0,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person_rounded,
                      label: 'Mi Perfil',
                      index: 1,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.switch_account_rounded,
                      label: 'Cambiar Cuenta',
                      index: 2,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.palette_outlined,
                      label: 'Personalizar Tema',
                      index: -2,
                    ),

                    const SizedBox(height: 12),
                    _buildSectionHeader(context, 'INTELIGENCIA ARTIFICIAL'),
                    _buildAiHighlightTile(context),

                    const SizedBox(height: 12),
                    _buildSectionHeader(context, 'HERRAMIENTAS ACADÉMICAS'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.timer_rounded,
                      label: 'Modo Enfoque (Pomodoro)',
                      index: 7,
                      badgeColor: Colors.deepOrange,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.calendar_month_rounded,
                      label: 'Calendario Académico',
                      index: 3,
                      badgeColor: Colors.blue,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.edit_note_rounded,
                      label: 'Mis Apuntes',
                      index: 4,
                      badgeColor: Colors.amber.shade800,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.folder_special_rounded,
                      label: 'Bóveda de Documentos',
                      index: 8,
                      badgeColor: Colors.indigo,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.calculate_rounded,
                      label: 'Calculadora de Notas',
                      index: 5,
                      badgeColor: Colors.teal,
                    ),
                    // MAPA UPEA HABILITADO CON COLOR ÚNICO (Rojo Carmesí)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.map_rounded,
                      label: 'Mapa del Campus UPEA',
                      index: 9,
                      badgeColor: Colors.red.shade600, // Color diferenciado
                      isComingSoon: false, // Habilitado
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1),
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.logout_rounded,
                      label: 'Cerrar Sesión',
                      index: -1,
                      isLogout: true,
                    ),
                  ],
                ),
              ),

              // ==========================================
              // FOOTER CON EASTER EGG INTERACTIVO (CRÉDITOS)
              // ==========================================
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context); // Cierra el Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreditsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.12)),
                      ),
                      color: colorScheme.primary.withOpacity(0.04),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'UPEA Connect',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'v1.0.0 • 2026',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Colors.amber.shade700,
                            ),
                          ],
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      AppThemeVariant variant,
      ColorScheme colorScheme,
      ) {
    final hasPhoto = currentUser?.fotoPath != null && currentUser!.fotoPath!.isNotEmpty;

    final headerContent = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? UserPhoto(
                            path: currentUser!.fotoPath!,
                            fallback: Icon(Icons.person_rounded, size: 38, color: colorScheme.primary),
                          )
                        : Container(
                      color: Colors.white,
                      child: Icon(Icons.person_rounded, size: 38, color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Colors.greenAccent),
                            SizedBox(width: 5),
                            Text(
                              'Estudiante Activo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentUser?.nombre.isNotEmpty == true ? currentUser!.nombre : 'Estudiante UPEA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentUser?.email.isNotEmpty == true ? currentUser!.email : 'estudiante@upea.bo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    const borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );

    switch (variant) {
      case AppThemeVariant.oscuro:
        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            child: headerContent,
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
              headerContent,
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
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: headerContent,
        );
    }
  }

  Widget _buildAiHighlightTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == 6;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isSelected
              ? [colorScheme.primary, colorScheme.secondary]
              : [colorScheme.primary.withOpacity(0.12), colorScheme.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSelected ? Colors.transparent : colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onMenuItemSelected(6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pregúntale a la IA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amberAccent : Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Asistente Inteligente 24/7',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white.withOpacity(0.85)
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isSelected ? Colors.white : colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    Color? badgeColor,
    bool isLogout = false,
    bool isComingSoon = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = index >= 0 && selectedIndex == index;

    final baseColor = isLogout
        ? colorScheme.error
        : isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.75);

    final iconBgColor = isLogout
        ? colorScheme.error.withOpacity(0.1)
        : isSelected
        ? colorScheme.primary.withOpacity(0.12)
        : (badgeColor?.withOpacity(0.1) ?? colorScheme.onSurface.withOpacity(0.06));

    final iconColor = isLogout
        ? colorScheme.error
        : isSelected
        ? colorScheme.primary
        : (badgeColor ?? colorScheme.onSurface.withOpacity(0.7));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: baseColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pronto',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
          ],
        ),
        onTap: () {
          if (isComingSoon) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚀 Mapa del campus próximamente disponible.')),
            );
          } else if (isLogout) {
            _showLogoutDialog(context);
          } else if (index == -2) {
            _showThemeDialog(context);
          } else {
            onMenuItemSelected(index);
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('¿Estás seguro de que quieres salir de UPEA Connect?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              title: const Text('Personalizar Tema', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppThemeVariant.values.map((variant) {
                  final isSelected = themeService.variant == variant;
                  final variantScheme = AppTheme.themeFor(variant).colorScheme;

                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    title: Text(
                      AppTheme.nombres[variant]!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green)
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