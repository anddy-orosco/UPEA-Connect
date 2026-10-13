import 'package:flutter/material.dart';

class BuildingModel {
  final String floorName;
  final String subtitle;
  final String imagePath;
  final Color themeColor;

  BuildingModel({
    required this.floorName,
    required this.subtitle,
    required this.imagePath,
    required this.themeColor,
  });
}

class BuildingMapScreen extends StatelessWidget {
  const BuildingMapScreen({super.key});

  // Lista de datos para cada nivel
  List<BuildingModel> get _floorsList => [
    BuildingModel(
      floorName: 'Piso 5',
      subtitle: 'Aulas y Oficinas Superiores',
      imagePath: 'assets/images/piso5.jpeg',
      themeColor: Colors.deepPurple,
    ),
    BuildingModel(
      floorName: 'Piso 4',
      subtitle: 'Aulas Teóricas y Gabinetes',
      imagePath: 'assets/images/piso4.jpeg',
      themeColor: Colors.indigo,
    ),
    BuildingModel(
      floorName: 'Piso 3',
      subtitle: 'Laboratorios de Computación',
      imagePath: 'assets/images/piso3.jpeg',
      themeColor: Colors.blue,
    ),
    BuildingModel(
      floorName: 'Piso 2',
      subtitle: 'Área Académica y Docentes',
      imagePath: 'assets/images/piso2.jpeg',
      themeColor: Colors.teal,
    ),
    BuildingModel(
      floorName: '1er Piso',
      subtitle: 'Laboratorio de Física y Preuniversitario',
      imagePath: 'assets/images/piso1.jpeg',
      themeColor: Colors.orange,
    ),
    BuildingModel(
      floorName: 'Planta Baja',
      subtitle: 'Ingreso Principal, Secretaría y Accesos',
      imagePath: 'assets/images/planta_baja.jpeg',
      themeColor: Colors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final listFloors = _floorsList;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagen del edificio en grande ocupando toda la pantalla con zoom opcional
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: Center(
              child: Image.asset(
                'assets/images/edificioA.PNG',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Text(
                      'No se encontró la imagen "edificioA.PNG" en assets/images/',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Título flotante elegante en la parte superior
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Torre Tecnológica UPEA - Selecciona un Piso',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // 3. Botones interactivos con su tamaño original distribuidos verticalmente
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFloorButton(context, listFloors[0]), // Piso 5
                  const SizedBox(height: 12),
                  _buildFloorButton(context, listFloors[1]), // Piso 4
                  const SizedBox(height: 12),
                  _buildFloorButton(context, listFloors[2]), // Piso 3
                  const SizedBox(height: 12),
                  _buildFloorButton(context, listFloors[3]), // Piso 2
                  const SizedBox(height: 12),
                  _buildFloorButton(context, listFloors[4]), // 1er Piso
                  const SizedBox(height: 12),
                  _buildFloorButton(context, listFloors[5]), // Planta Baja
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para crear el botón interactivo con el tamaño original destacado
  Widget _buildFloorButton(BuildContext context, BuildingModel floor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FloorDetailScreen(floor: floor),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: floor.themeColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.layers_rounded, color: floor.themeColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  floor.floorName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla de detalle con control de transformación ajustado ligeramente a la derecha
/// e indicador flotante en la parte inferior informando sobre el zoom.
class FloorDetailScreen extends StatefulWidget {
  final BuildingModel floor;

  const FloorDetailScreen({super.key, required this.floor});

  @override
  State<FloorDetailScreen> createState() => _FloorDetailScreenState();
}

class _FloorDetailScreenState extends State<FloorDetailScreen> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // Ajustado a -20.0 para centrarlo perfecto un poco más a la derecha que el anterior
    _transformationController.value = Matrix4.identity()
      ..translate(-20.0, 0.0)
      ..scale(1.15);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Visor interactivo con control unificado de posición y zoom
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Image.asset(
                widget.floor.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_rounded, size: 80, color: Colors.white54),
                    const SizedBox(height: 12),
                    Text(
                      'Plano detallado de ${widget.floor.floorName} no disponible.',
                      style: const TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barra superior flotante elegante con nombre del piso y opciones de salida/reseteo
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.floor.themeColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.floor.floorName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() {
                        _transformationController.value = Matrix4.identity()
                          ..translate(-20.0, 0.0)
                          ..scale(1.15);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Indicador inferior que avisa que se puede hacer zoom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.pinch_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Pellizca para hacer zoom y muévete libremente',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
}