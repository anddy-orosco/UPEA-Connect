import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../theme/colors.dart';

/// Barra que aparece arriba cuando no hay conexión, y un aviso verde
/// breve cuando vuelve. Vive en lib/widgets/offline_banner.dart
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final offline = !connectivity.isOnline;
    final show = offline || connectivity.justReconnected;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: show
          ? Container(
              width: double.infinity,
              color: offline ? const Color(0xFF374151) : AppColors.verdeExito,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      offline
                          ? 'Sin conexión · Mostrando datos guardados'
                          : 'Conexión restablecida',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
