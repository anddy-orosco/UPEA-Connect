import 'dart:convert';

class SubjectModel {
  final String id;
  final String name;
  final int colorValue;
  int totalMinutesStudied;

  SubjectModel({
    required this.id,
    required this.name,
    required this.colorValue,
    this.totalMinutesStudied = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'totalMinutesStudied': totalMinutesStudied,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF3F51B5,
      totalMinutesStudied: map['totalMinutesStudied'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory SubjectModel.fromJson(String source) =>
      SubjectModel.fromMap(json.decode(source));
}