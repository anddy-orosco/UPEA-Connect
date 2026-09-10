import 'package:flutter/material.dart';
import '../widgets/growing_plant_widget.dart';

class PlantCalibratorScreen extends StatefulWidget {
  const PlantCalibratorScreen({super.key});

  @override
  State<PlantCalibratorScreen> createState() => _PlantCalibratorScreenState();
}

class _PlantCalibratorScreenState extends State<PlantCalibratorScreen> {
  double _progress = 0.0; // 0.0=Fase 1, 0.3=Fase 2, 0.6=Fase 3, 0.8=Fase 4
  String _species = 'sp_oak';
  String _pot = 'pot_default';

  double _plantX = 0.0;
  double _plantY = 0.0;
  double _potX = 0.0;
  double _potY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibrador de Plantas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.teal.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: GrowingPlantWidget(
                  progress: _progress,
                  equippedSpecies: _species,
                  equippedPot: _pot,
                  extraPlantX: _plantX,
                  extraPlantY: _plantY,
                  extraPotX: _potX,
                  extraPotY: _potY,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selectores de pruebas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: _species,
                  items: const [
                    DropdownMenuItem(value: 'sp_oak', child: Text('Roble')),
                    DropdownMenuItem(value: 'sp_rose', child: Text('Rosa')),
                    DropdownMenuItem(value: 'sp_sakura', child: Text('Sakura')),
                  ],
                  onChanged: (v) => setState(() => _species = v!),
                ),
                DropdownButton<String>(
                  value: _pot,
                  items: const [
                    DropdownMenuItem(value: 'pot_default', child: Text('Normal')),
                    DropdownMenuItem(value: 'pot_gold', child: Text('Dorada')),
                    DropdownMenuItem(value: 'pot_japanese', child: Text('Japonesa')),
                    DropdownMenuItem(value: 'pot_volcanic', child: Text('Volcánica')),
                  ],
                  onChanged: (v) => setState(() => _pot = v!),
                ),
              ],
            ),

            Text('Fase actual: ${(_progress * 100).toInt()}%'),
            Slider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
            ),

            const Divider(),
            const Text('Ajustar Planta (Offset Y / X):', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.arrow_downward), onPressed: () => setState(() => _plantY -= 1)),
                Text('Y: ${_plantY.toStringAsFixed(1)}'),
                IconButton(icon: const Icon(Icons.arrow_upward), onPressed: () => setState(() => _plantY += 1)),
                const SizedBox(width: 20),
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _plantX -= 1)),
                Text('X: ${_plantX.toStringAsFixed(1)}'),
                IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => setState(() => _plantX += 1)),
              ],
            ),

            const Text('Ajustar Maceta (Offset Y / X):', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.arrow_downward), onPressed: () => setState(() => _potY -= 1)),
                Text('Y: ${_potY.toStringAsFixed(1)}'),
                IconButton(icon: const Icon(Icons.arrow_upward), onPressed: () => setState(() => _potY += 1)),
                const SizedBox(width: 20),
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _potX -= 1)),
                Text('X: ${_potX.toStringAsFixed(1)}'),
                IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => setState(() => _potX += 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}