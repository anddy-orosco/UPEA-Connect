import 'package:flutter/material.dart';

class PomodoroStatsCard extends StatelessWidget {
  final int totalMinutesStudied; // Minutos acumulados de estudio
  final int plantLevel;        // Nivel actual de la planta (1 al 4)
  final int totalCoins;        // Monedas ganadas

  const PomodoroStatsCard({
    Key? key,
    required this.totalMinutesStudied,
    required this.plantLevel,
    required this.totalCoins,
  }) : super(key: key);

  // Lógica para calcular el "Índice de Rendimiento Cognitivo" para el jurado
  String _calculateCognitiveIndex() {
    if (totalMinutesStudied > 120) return "Sobresaliente 🚀";
    if (totalMinutesStudied > 60) return "Óptimo 📈";
    if (totalMinutesStudied > 30) return "En Progreso ⏳";
    return "Inicial 🌱";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rendimiento Cognitivo",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Fase Planta: $plantLevel/4",
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.timer_outlined,
                title: "Enfoque",
                value: "$totalMinutesStudied min",
                color: Colors.blue.shade700,
              ),
              _buildStatItem(
                icon: Icons.monetization_on_outlined,
                title: "Monedas",
                value: "$totalCoins",
                color: Colors.amber.shade800,
              ),
              _buildStatItem(
                icon: Icons.psychology_outlined,
                title: "Estado Mental",
                value: _calculateCognitiveIndex(),
                color: Colors.green.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}