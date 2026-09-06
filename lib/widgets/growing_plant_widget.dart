import 'package:flutter/material.dart';

// --- MODELO DE TIENDA Y EQUIPAMIENTO ---
class PlantSpeciesItem {
  final String id;
  final String name;
  final int price;
  final String iconEmoji;

  const PlantSpeciesItem({
    required this.id,
    required this.name,
    required this.price,
    required this.iconEmoji,
  });
}

// Catálogo de la tienda
final List<PlantSpeciesItem> availableSpeciesInShop = [
  const PlantSpeciesItem(id: 'sp_oak', name: 'Roble Clásico', price: 0, iconEmoji: '🌳'),
  const PlantSpeciesItem(id: 'sp_rose', name: 'Rosa Roja', price: 150, iconEmoji: '🌹'),
  const PlantSpeciesItem(id: 'sp_sakura', name: 'Cerezo Sakura', price: 250, iconEmoji: '🌸'),
];

// --- WIDGET PRINCIPAL ---
class GrowingPlantWidget extends StatelessWidget {
  final double progress;
  final String equippedPot;
  final String equippedDecoration;
  final String equippedSpecies;

  const GrowingPlantWidget({
    super.key,
    required this.progress,
    this.equippedPot = 'pot_default',
    this.equippedDecoration = 'dec_none',
    this.equippedSpecies = 'sp_oak',
  });

  // --- SELECCIÓN DINÁMICA DE PLANTA SEGÚN FASE Y ESPECIE ---
  String _getPlantImagePath() {
    int phase = 1;
    if (progress >= 0.75) {
      phase = 4;
    } else if (progress >= 0.50) {
      phase = 3;
    } else if (progress >= 0.25) {
      phase = 2;
    }

    switch (equippedSpecies) {
      case 'sp_rose':
        if (phase == 1) return 'assets/images/fase1_rosa_brote.png';
        if (phase == 2) return 'assets/images/fase2_rosa_vastago.png';
        if (phase == 3) return 'assets/images/fase3_rosa_capullo.png';
        return 'assets/images/fase4_rosa_floripondio.png';

      case 'sp_sakura':
        if (phase == 1) return 'assets/images/fase1_sakura_brote.png';
        if (phase == 2) return 'assets/images/fase2_sakura_rama.png';
        if (phase == 3) return 'assets/images/fase3_sakura_capullo.png';
        return 'assets/images/fase4_sakura_plena.png';

      case 'sp_oak':
      default:
        if (phase == 1) return 'assets/images/fase1_plantula.png';
        if (phase == 2) return 'assets/images/fase2_planta_joven.png';
        if (phase == 3) return 'assets/images/fase3_planta_madura.png';
        return 'assets/images/fase4_planta_frondosa.png';
    }
  }

  // --- SELECCIÓN DINÁMICA DE MACETA ---
  String _getPotImagePath() {
    switch (equippedPot) {
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

  // --- COORDENADAS COMPARTIDAS POR FASE ---
  double get _potBottom {
    if (progress < 0.25) return -91.3;
    if (progress < 0.50) return -91.3;
    if (progress < 0.75) return -88.5;
    return -83.1;
  }

  double get _potLeft {
    if (progress < 0.25) return 2.9;
    if (progress < 0.50) return 5.6;
    if (progress < 0.75) return 5.6;
    return 5.6;
  }

  double get _potWidth {
    if (progress < 0.25) return 127.6;
    if (progress < 0.50) return 127.6;
    if (progress < 0.75) return 127.6;
    return 127.6;
  }

  double get _plantBottom {
    if (progress < 0.25) return -21.6;
    if (progress < 0.50) return -72.2;
    if (progress < 0.75) return -72.2;
    return -72.2;
  }

  double get _plantLeft {
    if (progress < 0.25) return 0.0;
    if (progress < 0.50) return 2.0;
    if (progress < 0.75) return 2.0;
    return 2.0;
  }

  double get _plantSize {
    if (progress < 0.25) return 150.1;
    if (progress < 0.50) return 253.4;
    if (progress < 0.75) return 253.4;
    return 258.2;
  }

  String _getDecorationEmoji() {
    switch (equippedDecoration) {
      case 'dec_lights':
        return '💡';
      case 'dec_owl':
        return '🦉';
      case 'dec_books':
        return '📚';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantImagePath = _getPlantImagePath();
    final potImagePath = _getPotImagePath();

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Decoración lateral
          if (equippedDecoration != 'dec_none')
            Positioned(
              right: -30,
              bottom: 10,
              child: Text(
                _getDecorationEmoji(),
                style: const TextStyle(fontSize: 30),
              ),
            ),

          // 2. MACETA DINÁMICA
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            bottom: _potBottom,
            child: Transform.translate(
              offset: Offset(_potLeft, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                width: _potWidth,
                child: Image.asset(
                  potImagePath,
                  key: ValueKey<String>(potImagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),

          // 3. PLANTA DINÁMICA (Roble, Rosa o Sakura)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            bottom: _plantBottom,
            child: Transform.translate(
              offset: Offset(_plantLeft, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                width: _plantSize,
                height: _plantSize,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    plantImagePath,
                    key: ValueKey<String>(plantImagePath),
                    width: _plantSize,
                    height: _plantSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}