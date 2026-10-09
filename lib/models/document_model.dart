class DocumentModel {
  final String id;
  final String title;
  final String category; // 'Matrícula', 'Identificación', 'Académico', etc.
  final String filePath; // Ruta local del archivo o imagen guardada
  final String fileType; // 'image', 'pdf', 'excel', 'presentation'
  final DateTime dateAdded;

  DocumentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.filePath,
    required this.fileType,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'filePath': filePath,
    'fileType': fileType,
    'dateAdded': dateAdded.toIso8601String(),
  };

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    filePath: json['filePath'],
    fileType: json['fileType'],
    dateAdded: DateTime.parse(json['dateAdded']),
  );
}