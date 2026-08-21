import 'package:flutter/material.dart';

class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class EvaluationItem {
  String name;
  double maxWeight; // Ponderación máxima en la nota final (ej. 25 pts)
  double? score;    // Nota ingresada por el estudiante

  EvaluationItem({
    required this.name,
    required this.maxWeight,
    this.score,
  });

  // Calcula los puntos aportados según la modalidad seleccionada
  double getEarnedPoints(bool useScale100) {
    if (score == null) return 0.0;
    if (useScale100) {
      return (score! / 100.0) * maxWeight;
    } else {
      return score!; // Nota ingresada directamente en puntos (ej. 20/25)
    }
  }
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  // Modalidad de ingreso de nota:
  // false = Puntos directos (ej. 20 / 25)
  // true  = Sobre 100 (ej. 80 / 100)
  bool _useScale100 = false;

  final List<EvaluationItem> _evaluations = [
    EvaluationItem(name: '1° Parcial', maxWeight: 25.0),
    EvaluationItem(name: '2° Parcial', maxWeight: 25.0),
    EvaluationItem(name: '3° Parcial / Final', maxWeight: 25.0),
    EvaluationItem(name: 'Práctica 1', maxWeight: 5.0),
    EvaluationItem(name: 'Práctica 2', maxWeight: 5.0),
    EvaluationItem(name: 'Práctica 3', maxWeight: 5.0),
    EvaluationItem(name: 'Auxiliatura', maxWeight: 10.0),
  ];

  double _extraPoints = 0.0;
  final TextEditingController _extraController = TextEditingController();

  double get _totalWeight =>
      _evaluations.fold(0.0, (sum, item) => sum + item.maxWeight);

  double get _earnedTotal {
    final earnedFromEvals = _evaluations.fold(
        0.0, (sum, item) => sum + item.getEarnedPoints(_useScale100));
    return earnedFromEvals + _extraPoints;
  }

  double get _evaluatedWeight {
    return _evaluations
        .where((e) => e.score != null)
        .fold(0.0, (sum, item) => sum + item.maxWeight);
  }

  double get _pendingWeight => _totalWeight - _evaluatedWeight;

  // Calcula qué porcentaje o puntaje se necesita en lo pendiente para llegar a 51
  double? get _requiredOnPending {
    if (_pendingWeight <= 0) return null;
    final neededPoints = 51.0 - _earnedTotal;
    if (neededPoints <= 0) return 0.0;

    if (_useScale100) {
      return (neededPoints / _pendingWeight) * 100.0; // En escala 0-100
    } else {
      return neededPoints; // En puntos directos requeridos
    }
  }

  @override
  void dispose() {
    _extraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de Modalidad de Calificación
            _buildModeSelector(colorScheme),
            const SizedBox(height: 12),

            // Tarjeta de Resumen / Estado
            _buildScoreCard(colorScheme),
            const SizedBox(height: 16),

            // Advertencia de Ponderación
            if ((_totalWeight - 100.0).abs() > 0.01)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade800),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ponderación total: ${_totalWeight.toStringAsFixed(1)} pts (debe sumar 100 pts).',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Encabezado de Evaluaciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Evaluaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewEvaluationDialog,
                  icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
                  label: Text('Agregar Ítem', style: TextStyle(color: colorScheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de Evaluaciones
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _evaluations.length,
              itemBuilder: (context, index) {
                return _buildEvaluationTile(_evaluations[index], index, colorScheme);
              },
            ),

            const SizedBox(height: 12),

            // Sección de Puntos Extra
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.amberAccent,
                      child: Icon(Icons.star, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Puntos Extra:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _extraController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: '+0 pts',
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _extraPoints = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Interruptor para cambiar el modo de ingreso de nota
  Widget _buildModeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Center(child: Text('Nota Directa (ej. 20/25)')),
              selected: !_useScale100,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: !_useScale100 ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _useScale100 = false);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Center(child: Text('Sobre 100 (ej. 80/100)')),
              selected: _useScale100,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: _useScale100 ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _useScale100 = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de estado y cálculo
  Widget _buildScoreCard(ColorScheme colorScheme) {
    final req = _requiredOnPending;
    final total = _earnedTotal;

    // Determinación del estado académico. statusBgColor por defecto sigue
    // el color primario del tema activo (antes era Colors.indigo fijo, por
    // lo que esta tarjeta siempre se veía azul sin importar el tema).
    String statusText = '';
    Color statusBgColor = colorScheme.primary;

    if (_pendingWeight == 0) {
      // Si no quedan evaluaciones pendientes
      if (total >= 51.0) {
        statusText = '🎉 ¡Aprobado!';
      } else if (total >= 40.5 && total < 51.0) {
        statusText = '⚠️ Examen de Segundo Turno';
        statusBgColor = Colors.orange.shade900;
      } else {
        statusText = '❌ Reprobado (Menos de 41 pts)';
        statusBgColor = Colors.red.shade900;
      }
    } else {
      // Si aún hay notas pendientes
      if (total >= 51.0) {
        statusText = '🎉 ¡Ya alcanzaste la nota de aprobación!';
      } else if (total >= 40.5) {
        statusText = '🛡️ Ya aseguraste el Segundo Turno (41+ pts)';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusBgColor, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusBgColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Nota Acumulada',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                total.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' / 100 pts',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
          if (statusText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const Divider(color: Colors.white24, height: 24),

          // Proyección de notas pendientes
          if (_pendingWeight > 0)
            Column(
              children: [
                if (req != null && req > 0) ...[
                  Text(
                    _useScale100
                        ? (req > 100
                        ? '⚠️ Requiere más del 100% en lo restante.'
                        : 'Necesitas promediar ~${req.toStringAsFixed(1)} / 100')
                        : (req > _pendingWeight
                        ? '⚠️ Necesitas más puntos de los disponibles.'
                        : 'Necesitas hacer ${req.toStringAsFixed(1)} de ${_pendingWeight.toStringAsFixed(1)} pts faltantes'),
                    style: TextStyle(
                      color: (req > (_useScale100 ? 100 : _pendingWeight))
                          ? Colors.redAccent
                          : Colors.amberAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'para aprobar directamente con 51 pts.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            )
          else
            const Text(
              'Has completado todas las evaluaciones del semestre.',
              style: TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  // Fila para cada ítem de evaluación
  Widget _buildEvaluationTile(EvaluationItem item, int index, ColorScheme colorScheme) {
    final earned = item.getEarnedPoints(_useScale100);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ponderación: ${item.maxWeight.toStringAsFixed(1)} pts',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),

            // Campo de entrada adaptativo según modalidad
            SizedBox(
              width: 85,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: _useScale100 ? '0-100' : '0-${item.maxWeight.toStringAsFixed(0)}',
                  labelText: _useScale100 ? 'Sobre 100' : 'Puntos',
                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    item.score = double.tryParse(val);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),

            // Puntos ganados calculados
            SizedBox(
              width: 55,
              child: Column(
                children: [
                  Text(
                    earned.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '/${item.maxWeight.toStringAsFixed(0)}',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
            ),

            // Opciones del ítem
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'edit') {
                  _editEvaluationDialog(item);
                } else if (value == 'delete') {
                  setState(() {
                    _evaluations.removeAt(index);
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar Ponderación'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewEvaluationDialog() {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. Examen Final, Asistencia)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ponderación Máxima (pts)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final weight = double.tryParse(weightCtrl.text) ?? 0.0;
              if (name.isNotEmpty && weight > 0) {
                setState(() {
                  _evaluations.add(
                    EvaluationItem(name: name, maxWeight: weight),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editEvaluationDialog(EvaluationItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final weightCtrl = TextEditingController(text: item.maxWeight.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ponderación Máxima (pts)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final weight = double.tryParse(weightCtrl.text) ?? item.maxWeight;
              if (name.isNotEmpty) {
                setState(() {
                  item.name = name;
                  item.maxWeight = weight;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
