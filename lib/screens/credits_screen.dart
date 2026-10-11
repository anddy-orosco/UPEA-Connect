import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _showEscudoPrimary = true;
  late Timer _switchTimer;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Bucle de transición continua entre el escudo y el icono
    _switchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _showEscudoPrimary = !_showEscudoPrimary;
        });
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _switchTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B), // Azul espacial profundo muy elegante
      appBar: AppBar(
        title: const Text(
          '¡GRACIAS POR SU ATENCIÓN!',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Fondo con difuminado ambiental de luces institucionales
          Positioned(
            top: -60,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade800.withOpacity(0.35),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade900.withOpacity(0.4),
                ),
              ),
            ),
          ),

          // Contenido Principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Insignia Superior
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade700, Colors.orange.shade800],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade700.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'PROYECTO FINAL • FERIA CIENTÍFICA 2026',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===============================================
                    // ISOLOGOTIPO CENTRAL GIGANTE, BLANCO Y ENCAJADO
                    // ===============================================
                    ScaleTransition(
                      scale: _glowAnimation,
                      child: Container(
                        width: 180, // ¡Agrandado e imponente!
                        height: 180,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amberAccent,
                              colorScheme.primary,
                              Colors.redAccent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, // Fondo blanco para que combine con tus imágenes
                          ),
                          child: ClipOval(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: AnimatedCrossFade(
                                  firstChild: Image.asset(
                                    'assets/images/escudo.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.school_rounded, size: 85, color: Colors.amber),
                                  ),
                                  secondChild: Image.asset(
                                    'assets/images/icon.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.hub_rounded, size: 85, color: Colors.indigo),
                                  ),
                                  crossFadeState: _showEscudoPrimary
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  duration: const Duration(milliseconds: 900),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Título Principal
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Colors.cyanAccent],
                      ).createShader(bounds),
                      child: const Text(
                        'UPEA CONNECT',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ecosistema Inteligente de Gestión Académica',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // ===============================================
                    // TARJETA DE AUTORES / DESARROLLADORES
                    // ===============================================
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_rounded, size: 18, color: Colors.amberAccent),
                              const SizedBox(width: 8),
                              Text(
                                'EQUIPO DE DESARROLLO OFICIAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amberAccent.shade100,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ANDDY JHAIR OROSCO UMEREZ
                          _buildDeveloperRow(
                            name: 'Anddy Jhair Orosco Umerez',
                            role: 'Lead Developer & Software Architect',
                            semester: '3er Semestre • Paralelo B',
                            icon: Icons.code_rounded,
                            accentColor: Colors.amberAccent,
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.white10, height: 1),
                          ),

                          // CRISTIAN CHOQUE CHOQUE
                          _buildDeveloperRow(
                            name: 'Cristian Choque Choque',
                            role: 'AI Engine & Backend Integration',
                            semester: '3er Semestre • Paralelo A',
                            icon: Icons.psychology_rounded,
                            accentColor: Colors.cyanAccent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===============================================
                    // BANNER INSTITUCIONAL
                    // ===============================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade900.withOpacity(0.7),
                            Colors.red.shade900.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.amber.shade600.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/escudo.png',
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                const Icon(Icons.account_balance_rounded, size: 20, color: Colors.amber),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'INGENIERÍA DE SISTEMAS • UPEA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Universidad Pública de El Alto • Bolivia 2026',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón de Retorno al Ecosistema
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 16),
                      label: const Text(
                        'Volver al Menú Principal',
                        style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperRow({
    required String name,
    required String role,
    required String semester,
    required IconData icon,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                semester,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}