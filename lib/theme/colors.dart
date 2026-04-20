import 'package:flutter/material.dart';

class AppColors {
  static const Color azulPrincipal = Color(0xFF2563EB);
  static const Color azulOscuro = Color(0xFF1E3A8A);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF3F4F6);
  static const Color verdeExito = Color(0xFF10B981);
  static const Color rojoAlerta = Color(0xFFEF4444);
  
  static const LinearGradient azulGradiente = LinearGradient(
    colors: [azulPrincipal, azulOscuro],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
