import 'dart:io';
import 'package:flutter/material.dart';

/// Foto de perfil: si [path] es una URL (foto subida al servidor) la descarga;
/// si es una ruta local, la lee del celular. Si falla, muestra [fallback].
class UserPhoto extends StatelessWidget {
  final String path;
  final Widget fallback;
  final BoxFit fit;

  const UserPhoto({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              fallback,
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          );
        },
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
