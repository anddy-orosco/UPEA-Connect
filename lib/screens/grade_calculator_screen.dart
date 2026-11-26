import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class EvaluationItem {
  String name;
  double maxWeight; // Ponderación máxima en la nota final (ej. 25 pts)

  /// Nota canónica siempre almacenada en puntos directos (0 .. maxWeight).
  /// Guardar los puntos directos como fuente de verdad evita pérdida de precisión
  /// al alternar entre "Nota Directa" y "Sobre 100".
  double? directPoints;

  final TextEditingController controller;

  EvaluationItem({
    required this.name,
    required this.maxWeight,
    this.directPoints,
  }) : controller = TextEditingController();

  double getEarnedPoints() => directPoints ?? 0.0;

  double? getDisplayScore(bool useScale100) {
    if (directPoints == null) return null;
    if (useScale100) {
      if (maxWeight <= 0) return 0.0;
      return (directPoints! / maxWeight) * 100.0;
    }
    return directPoints;
  }

  void dispose() {
    controller.dispose();
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

  /// Suma de notas de evaluaciones base (estrictamente limitada a 100.0 pts).
  double get _earnedFromEvaluations {
    final raw =
        _evaluations.fold(0.0, (sum, item) => sum + item.getEarnedPoints());
    return raw.clamp(0.0, 100.0);
  }

  /// Total acumulado: las evaluaciones base nunca superan 100 pts;
  /// únicamente los puntos extra pueden sumar por encima de 100.
  double get _earnedTotal => _earnedFromEvaluations + _extraPoints;

  double get _evaluatedWeight {
    return _evaluations
        .where((e) => e.directPoints != null)
        .fold(0.0, (sum, item) => sum + item.maxWeight);
  }

  double get _pendingWeight => math.max(0.0, _totalWeight - _evaluatedWeight);

  double get _maxRemainingBasePoints => math.min(
        _pendingWeight,
        math.max(0.0, 100.0 - _earnedFromEvaluations),
      );

  // Calcula qué porcentaje o puntaje se necesita en lo pendiente para llegar a 51
  double? get _requiredOnPending {
    if (_pendingWeight <= 0.001) return null;
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
    for (final item in _evaluations) {
      item.dispose();
    }
    _extraController.dispose();
    super.dispose();
  }

  String _formatScore(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    if ((rounded - rounded.roundToDouble()).abs() < 0.001) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  double? _parseNumber(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _showLimitNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Cambia entre "Nota Directa" y "Sobre 100" convirtiendo todos los campos
  /// automáticamente al nuevo sistema sin perder ni distorsionar notas.
  void _switchScaleMode(bool useScale100) {
    if (_useScale100 == useScale100) return;
    setState(() {
      _useScale100 = useScale100;
      for (final item in _evaluations) {
        final displayScore = item.getDisplayScore(_useScale100);
        if (displayScore == null) {
          item.controller.clear();
        } else {
          final formatted = _formatScore(displayScore);
          item.controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });
  }

  void _onEvaluationScoreChanged(EvaluationItem item, String rawVal) {
    final trimmed = rawVal.trim();
    if (trimmed.isEmpty) {
      setState(() {
        item.directPoints = null;
      });
      return;
    }

    final parsed = _parseNumber(trimmed);
    if (parsed == null) return;

    // Puntos ya acumulados en el resto de evaluaciones (para nunca pasar de 100)
    final otherDirectSum = _evaluations
        .where((e) => !identical(e, item))
        .fold(0.0, (sum, e) => sum + e.getEarnedPoints());
    final remainingBaseBudget = math.max(0.0, 100.0 - otherDirectSum);
    final maxAllowedDirect = math.min(item.maxWeight, remainingBaseBudget);

    if (_useScale100) {
      final maxAllowedPercent = item.maxWeight > 0
          ? math.min(100.0, (maxAllowedDirect / item.maxWeight) * 100.0)
          : 0.0;

      double effectivePercent = parsed;
      bool clamped = false;
      if (effectivePercent < 0) {
        effectivePercent = 0.0;
        clamped = true;
      } else if (effectivePercent > maxAllowedPercent) {
        effectivePercent = maxAllowedPercent;
        clamped = true;
        _showLimitNotice(
          maxAllowedDirect < item.maxWeight - 0.01
              ? 'El total de evaluaciones no puede superar 100 pts (solo puntos extra pueden sumarse encima).'
              : 'La calificación máxima en esta escala es 100.',
        );
      }

      if (clamped) {
        final formatted = _formatScore(effectivePercent);
        item.controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }

      setState(() {
        item.directPoints =
            ((effectivePercent / 100.0) * item.maxWeight).clamp(0.0, maxAllowedDirect);
      });
    } else {
      double effectiveDirect = parsed;
      bool clamped = false;
      if (effectiveDirect < 0) {
        effectiveDirect = 0.0;
        clamped = true;
      } else if (effectiveDirect > maxAllowedDirect) {
        effectiveDirect = maxAllowedDirect;
        clamped = true;
        _showLimitNotice(
          maxAllowedDirect < item.maxWeight - 0.01
              ? 'La suma de evaluaciones no puede superar 100 pts (usa Puntos Extra para sumar más).'
              : 'Máximo ${_formatScore(item.maxWeight)} pts en ${item.name}.',
        );
      }

      if (clamped) {
        final formatted = _formatScore(effectiveDirect);
        item.controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }

      setState(() {
        item.directPoints = effectiveDirect;
      });
    }
  }

  /// Ajusta las notas ingresadas si la ponderación de algún ítem cambió,
  /// asegurando siempre que ningún ítem supere su maxWeight ni la suma pase de 100.
  void _reconcileBaseCapAndControllers() {
    double runningBase = 0.0;
    for (final item in _evaluations) {
      if (item.directPoints != null) {
        final allowed = math.min(
          item.maxWeight,
          math.max(0.0, 100.0 - runningBase),
        );
        if (item.directPoints! > allowed) {
          item.directPoints = allowed;
        }
        runningBase += item.directPoints!;
        final display = item.getDisplayScore(_useScale100)!;
        final formatted = _formatScore(display);
        item.controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  void _clearAllScores() {
    FocusScope.of(context).unfocus();
    setState(() {
      for (final item in _evaluations) {
        item.directPoints = null;
        item.controller.clear();
      }
      _extraPoints = 0.0;
      _extraController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      // Solución: Oculta el teclado automáticamente al tocar fuera de los inputs
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          // Solución: Oculta el teclado al hacer scroll hacia abajo o arrastrar
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          _totalWeight > 100.0
                              ? 'Ponderación total: ${_totalWeight.toStringAsFixed(1)} pts (las evaluaciones base tienen tope de 100 pts).'
                              : 'Ponderación total: ${_totalWeight.toStringAsFixed(1)} pts (debe sumar 100 pts).',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_evaluations.any((e) => e.directPoints != null) ||
                          _extraPoints > 0)
                        IconButton(
                          tooltip: 'Limpiar notas',
                          onPressed: _clearAllScores,
                          icon: Icon(
                            Icons.cleaning_services_outlined,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _addNewEvaluationDialog,
                        icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
                        label: Text(
                          'Agregar Ítem',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puntos Extra:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Pueden sumar sobre los 100 pts',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _extraController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: '+0 pts',
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = _parseNumber(val);
                            setState(() {
                              _extraPoints = (parsed == null || parsed < 0) ? 0.0 : parsed;
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
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
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
                if (selected) _switchScaleMode(false);
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
                if (selected) _switchScaleMode(true);
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

    String statusText = '';
    Color statusBgColor = colorScheme.primary;

    if (_pendingWeight <= 0.001) {
      if (total >= 51.0) {
        statusText = total > 100.0
            ? '🎉 ¡Aprobado! (+puntos extra)'
            : '🎉 ¡Aprobado!';
      } else if (total >= 40.5 && total < 51.0) {
        statusText = '⚠️ Examen de Segundo Turno';
        statusBgColor = Colors.orange.shade900;
      } else {
        statusText = '❌ Reprobado (Menos de 41 pts)';
        statusBgColor = Colors.red.shade900;
      }
    } else {
      if (total >= 51.0) {
        statusText = total > 100.0
            ? '🎉 ¡Nota máxima superada con extra!'
            : '🎉 ¡Ya alcanzaste la nota de aprobación!';
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
            color: statusBgColor.withValues(alpha: 0.3),
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
          if (_extraPoints > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Base: ${_earnedFromEvaluations.toStringAsFixed(1)} pts  +  Extra: ${_extraPoints.toStringAsFixed(1)} pts',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
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
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Divider(color: Colors.white24, height: 24),

          // Proyección de notas pendientes
          if (_pendingWeight > 0.001)
            Column(
              children: [
                if (req != null && req > 0) ...[
                  Text(
                    _useScale100
                        ? ((req > 100 || (51.0 - _earnedTotal) > _maxRemainingBasePoints)
                            ? '⚠️ Requiere más del 100% en lo restante.'
                            : 'Necesitas promediar ~${req.toStringAsFixed(1)} / 100')
                        : (req > _maxRemainingBasePoints
                            ? '⚠️ Necesitas más puntos de los disponibles.'
                            : 'Necesitas hacer ${req.toStringAsFixed(1)} de ${_maxRemainingBasePoints.toStringAsFixed(1)} pts faltantes'),
                    style: TextStyle(
                      color: ((_useScale100 && req > 100) ||
                              (51.0 - _earnedTotal) > _maxRemainingBasePoints)
                          ? Colors.redAccent
                          : Colors.amberAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'para aprobar directamente con 51 pts.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ] else
                  const Text(
                    'Aprobación asegurada. Sigue sumando para mejorar tu nota.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
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
  Widget _buildEvaluationTile(
    EvaluationItem item,
    int index,
    ColorScheme colorScheme,
  ) {
    final earned = item.getEarnedPoints();

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
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Campo de entrada controlado adaptativo según modalidad
            SizedBox(
              width: 85,
              child: TextField(
                controller: item.controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText:
                      _useScale100 ? '0-100' : '0-${_formatScore(item.maxWeight)}',
                  labelText: _useScale100 ? 'Sobre 100' : 'Puntos',
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                onChanged: (val) => _onEvaluationScoreChanged(item, val),
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
                    '/${_formatScore(item.maxWeight)}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
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
                    final removed = _evaluations.removeAt(index);
                    removed.dispose();
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Ponderación Máxima (máx. 100 pts)',
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
              final parsedWeight = _parseNumber(weightCtrl.text) ?? 0.0;
              if (name.isNotEmpty && parsedWeight > 0) {
                final clampedWeight = parsedWeight.clamp(0.1, 100.0);
                setState(() {
                  _evaluations.add(
                    EvaluationItem(name: name, maxWeight: clampedWeight),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        nameCtrl.dispose();
        weightCtrl.dispose();
      });
    });
  }

  void _editEvaluationDialog(EvaluationItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final weightCtrl = TextEditingController(text: _formatScore(item.maxWeight));

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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Ponderación Máxima (máx. 100 pts)',
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
              final parsedWeight = _parseNumber(weightCtrl.text) ?? item.maxWeight;
              if (name.isNotEmpty && parsedWeight > 0) {
                setState(() {
                  item.name = name;
                  item.maxWeight = parsedWeight.clamp(0.1, 100.0);
                  _reconcileBaseCapAndControllers();
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        nameCtrl.dispose();
        weightCtrl.dispose();
      });
    });
  }
}
