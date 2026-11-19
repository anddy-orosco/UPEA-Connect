import 'package:flutter/material.dart';
import '../services/widget_sync_service.dart';

class PomodoroHomeWidgetPreviewModal extends StatefulWidget {
  final String equippedSpecies;
  final String equippedPot;
  final String equippedDecoration;
  final double progress;
  final String? subjectName;

  const PomodoroHomeWidgetPreviewModal({
    super.key,
    this.equippedSpecies = 'sp_oak',
    this.equippedPot = 'pot_default',
    this.equippedDecoration = 'dec_none',
    this.progress = 0.65,
    this.subjectName,
  });

  @override
  State<PomodoroHomeWidgetPreviewModal> createState() => _PomodoroHomeWidgetPreviewModalState();
}

class _PomodoroHomeWidgetPreviewModalState extends State<PomodoroHomeWidgetPreviewModal> {
  // 0 = iOS (iPhone), 1 = Android
  int _selectedPlatform = 0;
  // 0 = Pequeño (2x2), 1 = Mediano (4x2)
  int _selectedWidgetSize = 1;
  // Progreso interactivo para probar el crecimiento
  late double _previewProgress;

  @override
  void initState() {
    super.initState();
    _previewProgress = widget.progress.clamp(0.1, 1.0);
  }

  int get _currentPhase {
    if (_previewProgress >= 0.75) return 4;
    if (_previewProgress >= 0.50) return 3;
    if (_previewProgress >= 0.25) return 2;
    return 1;
  }

  String _getPhaseName() {
    switch (_currentPhase) {
      case 1:
        return 'Brote Inicial';
      case 2:
        return 'En Crecimiento';
      case 3:
        return 'Planta Madura';
      case 4:
        return 'Floración Total';
      default:
        return 'En Crecimiento';
    }
  }

  String _getPlantImagePath() {
    switch (widget.equippedSpecies) {
      case 'sp_rose':
        if (_currentPhase == 1) return 'assets/images/fase1_rosa_brote.png';
        if (_currentPhase == 2) return 'assets/images/fase2_rosa_vastago.png';
        if (_currentPhase == 3) return 'assets/images/fase3_rosa_capullo.png';
        return 'assets/images/fase4_rosa_floripondio.png';

      case 'sp_sakura':
        if (_currentPhase == 1) return 'assets/images/fase1_sakura_brote.png';
        if (_currentPhase == 2) return 'assets/images/fase2_sakura_rama.png';
        if (_currentPhase == 3) return 'assets/images/fase3_sakura_capullo.png';
        return 'assets/images/fase4_sakura_plena.png';

      case 'sp_oak':
      default:
        if (_currentPhase == 1) return 'assets/images/fase1_plantula.png';
        if (_currentPhase == 2) return 'assets/images/fase2_planta_joven.png';
        if (_currentPhase == 3) return 'assets/images/fase3_planta_madura.png';
        return 'assets/images/fase4_planta_frondosa.png';
    }
  }

  String _getPotImagePath() {
    switch (widget.equippedPot) {
      case 'pot_gold':
        return 'assets/images/maceta_dorada.png';
      case 'pot_japanese':
        return 'assets/images/maceta_japonesa.png';
      case 'pot_volcanic':
        return 'assets/images/maceta_volcanica.png';
      case 'pot_default':
      default:
        return 'assets/images/maceta_normal.png';
    }
  }

  String _getSpeciesLabel() {
    switch (widget.equippedSpecies) {
      case 'sp_rose':
        return 'Rosa Silvestre';
      case 'sp_sakura':
        return 'Cerezo Sakura';
      case 'sp_oak':
      default:
        return 'Roble Andino';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E242B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            children: [
              // Barra superior estilo Duolingo con botón cerrar
              _buildHeader(isDark),

              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Badge y Título Duolingo
                      _buildTitleSection(isDark),
                      const SizedBox(height: 18),

                      // Selector de Plataforma (iOS / Android)
                      _buildPlatformSelector(),
                      const SizedBox(height: 14),

                      // Selector de Tamaño de Widget
                      _buildSizeSelector(isDark),
                      const SizedBox(height: 18),

                      // Simulación visual en vivo del Widget
                      _buildLiveWidgetPreview(isDark),
                      const SizedBox(height: 14),

                      // Slider interactivo de prueba de crecimiento
                      _buildGrowthTester(isDark),
                      const SizedBox(height: 24),

                      // Globo de diálogo de la mascota Duolingo
                      _buildDuolingoMascotSpeech(isDark),
                      const SizedBox(height: 26),

                      // Tutorial Paso a Paso
                      _buildStepByStepTutorial(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Botón inferior 3D estilo Duolingo
              _buildBottomActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 14, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF58CC02).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text(
                      'NUEVA FUNCIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF58CC02),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white60 : Colors.black45,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Column(
      children: [
        Text(
          '¡Tu Planta en tu Pantalla!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF2C3E50),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Añade el widget de UPEA Connect a tu escritorio para cuidar tu planta y no romper tu racha de estudio diaria.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.35,
            color: isDark ? Colors.white70 : const Color(0xFF7F8C8D),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPlatformTab(
              index: 0,
              icon: Icons.apple_rounded,
              label: 'iPhone (iOS)',
              isSelected: _selectedPlatform == 0,
            ),
          ),
          Expanded(
            child: _buildPlatformTab(
              index: 1,
              icon: Icons.android_rounded,
              label: 'Android',
              isSelected: _selectedPlatform == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformTab({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlatform = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF1CB0F6) : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF1CB0F6) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSelector(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Tamaño del widget: ',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('2x2 Cuadrado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          selected: _selectedWidgetSize == 0,
          onSelected: (val) => setState(() => _selectedWidgetSize = 0),
          selectedColor: const Color(0xFF58CC02).withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: _selectedWidgetSize == 0 ? const Color(0xFF58CC02) : (isDark ? Colors.white70 : Colors.black54),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('4x2 Rectangular', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          selected: _selectedWidgetSize == 1,
          onSelected: (val) => setState(() => _selectedWidgetSize = 1),
          selectedColor: const Color(0xFF58CC02).withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: _selectedWidgetSize == 1 ? const Color(0xFF58CC02) : (isDark ? Colors.white70 : Colors.black54),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }

  Widget _buildLiveWidgetPreview(bool isDark) {
    // Fondo de pantalla de celular simulado (wallpaper estético)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: _selectedPlatform == 0
              ? [const Color(0xFF1A2639), const Color(0xFF111827), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A5F), const Color(0xFF0F2027), const Color(0xFF203A43)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Barra de estado simulada del celular
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '09:41',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(
                      _selectedPlatform == 0 ? Icons.apple_rounded : Icons.android_rounded,
                      size: 11,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedPlatform == 0 ? 'iOS WidgetKit' : 'Material You',
                      style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // EL WIDGET (Cuadrado o Rectangular)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedWidgetSize == 0
                ? _buildSmallSquareWidget()
                : _buildMediumRectangularWidget(),
          ),

          const SizedBox(height: 12),
          // Nombre del widget en la pantalla de inicio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF58CC02),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'UPEA Pomodoro',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET PEQUEÑO (2x2)
  Widget _buildSmallSquareWidget() {
    return Container(
      key: const ValueKey('small_widget'),
      width: 175,
      height: 175,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(_selectedPlatform == 0 ? 24 : 28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Fila superior: Racha y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 2),
                    Text(
                      '3 DÍAS',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFFF9600)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ENFOQUE',
                  style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),

          // Centro: La Planta viva y su Maceta
          _buildMiniPlantArt(width: 80, height: 78),

          // Fila inferior: Barra de progreso de enfoque
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getPhaseName(),
                    style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(_previewProgress * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFF58CC02), fontSize: 9.5, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _previewProgress,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET MEDIANO (4x2)
  Widget _buildMediumRectangularWidget() {
    final subject = widget.subjectName ?? 'Cálculo I';

    return Container(
      key: const ValueKey('medium_widget'),
      width: double.infinity,
      height: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(_selectedPlatform == 0 ? 24 : 28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lado Izquierdo: Cuadro de la Planta
          Container(
            width: 105,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF58CC02).withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.03),
                ],
                radius: 0.8,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: _buildMiniPlantArt(width: 95, height: 95),
            ),
          ),
          const SizedBox(width: 14),

          // Lado Derecho: Datos de la sesión, racha y progreso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cabecera: Materia y Racha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9600).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 10)),
                          SizedBox(width: 2),
                          Text(
                            '5 DÍAS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF9600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Especie y Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌱 ', style: TextStyle(fontSize: 11)),
                        Text(
                          _getSpeciesLabel(),
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fase actual: ${_getPhaseName()}',
                      style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                    ),
                  ],
                ),

                // Barra de Progreso y Porcentaje
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Crecimiento',
                          style: TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${(_previewProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF58CC02),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _previewProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
                      ),
                    ),
                  ],
                ),

                // Pie: Aviso motivacional
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFFFC800)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Toca para regar y continuar sesión',
                          style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cuadro visual de la planta con su maceta real
  Widget _buildMiniPlantArt({required double width, required double height}) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Maceta
          Positioned(
            bottom: 2,
            child: Image.asset(
              _getPotImagePath(),
              width: width * 0.62,
              height: height * 0.38,
              fit: BoxFit.contain,
            ),
          ),
          // Planta
          Positioned(
            bottom: height * 0.22,
            child: Image.asset(
              _getPlantImagePath(),
              width: width * 0.85,
              height: height * 0.75,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTester(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🧪 Probar fases de crecimiento en el widget:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                '${(_previewProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF58CC02)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF58CC02),
              thumbColor: const Color(0xFF58CC02),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _previewProgress,
              min: 0.1,
              max: 1.0,
              onChanged: (val) => setState(() => _previewProgress = val),
            ),
          ),
        ],
      ),
    );
  }

  // Globo de diálogo al estilo Duolingo
  Widget _buildDuolingoMascotSpeech(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC800).withValues(alpha: isDark ? 0.15 : 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC800).withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC800),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🦉', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Consejo del Búho Sabio!',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Si dejas pasar más de 24 horas sin estudiar Pomodoro, tu planta empezará a marchitarse. ¡Ten tu widget siempre a la vista para proteger tu racha!',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : const Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TUTORIAL PASO A PASO ESTILO DUOLINGO
  Widget _buildStepByStepTutorial(bool isDark) {
    final isIos = _selectedPlatform == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1CB0F6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1CB0F6), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              isIos ? 'Tutorial para iPhone (iOS)' : 'Tutorial para Android',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (isIos) ...[
          _buildTutorialCard(
            stepNumber: '1',
            icon: Icons.touch_app_rounded,
            color: const Color(0xFF58CC02),
            title: 'Mantén presionada la pantalla',
            description: 'En tu pantalla de inicio, mantén presionado cualquier espacio vacío hasta que las apps comiencen a vibrar.',
            isDark: isDark,
          ),
          _buildTutorialCard(
            stepNumber: '2',
            icon: Icons.add_circle_rounded,
            color: const Color(0xFF1CB0F6),
            title: 'Toca el botón (+)',
            description: 'Presiona el botón "+" ubicado en la esquina superior izquierda de tu iPhone.',
            isDark: isDark,
          ),
          _buildTutorialCard(
            stepNumber: '3',
            icon: Icons.search_rounded,
            color: const Color(0xFFFF9600),
            title: 'Busca "UPEA Connect"',
            description: 'Escribe "UPEA Connect" en el buscador de widgets o deslízate hasta la lista de aplicaciones.',
            isDark: isDark,
          ),
          _buildTutorialCard(
            stepNumber: '4',
            icon: Icons.view_quilt_rounded,
            color: const Color(0xFFCE82FF),
            title: 'Selecciona y agrega el widget',
            description: 'Elige tu formato favorito (Cuadrado 2x2 o Rectangular 4x2) y pulsa "Agregar widget".',
            isDark: isDark,
          ),
        ] else ...[
          _buildTutorialCard(
            stepNumber: '1',
            icon: Icons.touch_app_rounded,
            color: const Color(0xFF58CC02),
            title: 'Mantén presionado el fondo',
            description: 'En tu pantalla principal, mantén pulsado durante 2 segundos un espacio vacío.',
            isDark: isDark,
          ),
          _buildTutorialCard(
            stepNumber: '2',
            icon: Icons.widgets_rounded,
            color: const Color(0xFF1CB0F6),
            title: 'Selecciona "Widgets"',
            description: 'Toca la opción "Widgets" que aparece en la barra o menú emergente inferior.',
            isDark: isDark,
          ),
          _buildTutorialCard(
            stepNumber: '3',
            icon: Icons.search_rounded,
            color: const Color(0xFFFF9600),
            title: 'Encuentra UPEA Connect',
            description: 'Busca la categoría "UPEA Connect" y localiza el widget de Enfoque Académico.',
            isDark: isDark,
          ),
          _buildTutorialCard(
            stepNumber: '4',
            icon: Icons.drag_indicator_rounded,
            color: const Color(0xFFCE82FF),
            title: 'Arrastra y ajusta el tamaño',
            description: 'Mantén pulsado el widget de la planta y arrástralo hasta tu lugar favorito del escritorio.',
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildTutorialCard({
    required String stepNumber,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF28303A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número con estilo Duolingo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BOTÓN 3D ESTILO DUOLINGO
  Widget _buildBottomActionButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF46A302), // Sombra 3D del botón
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4), // Efecto de botón físico presionado
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02), // Verde Duolingo
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);

              // Sincronizar inmediatamente el widget nativo con los valores probados
              WidgetSyncService.syncWidgetData(
                species: widget.equippedSpecies,
                pot: widget.equippedPot,
                progress: _previewProgress,
                subjectName: widget.subjectName ?? 'Cálculo I',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Text('🌿', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Excelente! Ve a tu pantalla principal para colocar tu widget.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xFF58CC02),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¡ENTENDIDO, A CULTIVAR!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
