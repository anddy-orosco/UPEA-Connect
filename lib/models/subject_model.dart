import 'dart:convert';

class SubjectModel {
  final String id;
  final String name;
  final int colorValue;
  int totalMinutesStudied;

  // 🟢 NUEVOS CAMPOS DE PLANTA INDIVIDUAL
  final String equippedSpecies;
  final String equippedPot;
  final double plantProgress; // Progreso acumulado de 0.0 a 1.0

  SubjectModel({
    required this.id,
    required this.name,
    required this.colorValue,
    this.totalMinutesStudied = 0,
    this.equippedSpecies = 'sp_oak',
    this.equippedPot = 'pot_default',
    this.plantProgress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'totalMinutesStudied': totalMinutesStudied,
      'equippedSpecies': equippedSpecies,
      'equippedPot': equippedPot,
      'plantProgress': plantProgress,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF3F51B5,
      totalMinutesStudied: map['totalMinutesStudied'] ?? 0,
      equippedSpecies: map['equippedSpecies'] ?? 'sp_oak',
      equippedPot: map['equippedPot'] ?? 'pot_default',
      plantProgress: (map['plantProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubjectModel.fromJson(String source) =>
      SubjectModel.fromMap(json.decode(source));

  // Método auxiliar para actualizar campos de forma sencilla
  SubjectModel copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? totalMinutesStudied,
    String? equippedSpecies,
    String? equippedPot,
    double? plantProgress,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      totalMinutesStudied: totalMinutesStudied ?? this.totalMinutesStudied,
      equippedSpecies: equippedSpecies ?? this.equippedSpecies,
      equippedPot: equippedPot ?? this.equippedPot,
      plantProgress: plantProgress ?? this.plantProgress,
    );
  }
}