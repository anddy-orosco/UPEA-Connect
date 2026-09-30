import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../services/focus_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FocusService _focusService = FocusService();
  List<SubjectModel> _subjects = [];
  int _totalCoins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final subjects = await _focusService.getSubjects();
    final coins = await _focusService.getCoins();

    // Ordenar de mayor a menor tiempo de estudio
    subjects.sort((a, b) => b.totalMinutesStudied.compareTo(a.totalMinutesStudied));

    if (mounted) {
      setState(() {
        _subjects = subjects;
        _totalCoins = coins;
        _isLoading = false;
      });
    }
  }

  // Calcular el total de minutos de todas las materias combinadas
  int get _grandTotalMinutes {
    return _subjects.fold(0, (sum, sub) => sum + sub.totalMinutesStudied);
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = (_grandTotalMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Analítica y Rendimiento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjetas Resumen Globales
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Tiempo Total',
                    value: '$totalHours hrs',
                    subtitle: '$_grandTotalMinutes minutos',
                    icon: Icons.timer_rounded,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Monedas',
                    value: '$_totalCoins',
                    subtitle: 'Recompensas',
                    icon: Icons.monetization_on_rounded,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Título de la sección de gráficos
            const Text(
              'Distribución de Enfoque por Materia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gráfico comparativo basado en el esfuerzo en tiempo real.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Listado de Materias con Gráficos de Barra Visuales
            _subjects.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No hay materias registradas aún.'),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];

                // Calcular porcentaje relativo respecto al mayor o al total
                double maxMinutes = _grandTotalMinutes == 0 ? 1.0 : _grandTotalMinutes.toDouble();
                double percentage = subject.totalMinutesStudied / maxMinutes;
                if (percentage > 1.0) percentage = 1.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(subject.colorValue),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                subject.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${subject.totalMinutesStudied} min',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(subject.colorValue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Barra de Gráfico Visual Estilizada
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(subject.colorValue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Planta: Fase ${(subject.plantProgress * 4).floor() + 1}/4',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            '${(subject.plantProgress * 100).toInt()}% Crecimiento',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}