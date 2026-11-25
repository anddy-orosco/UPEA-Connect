import 'package:flutter/material.dart';

enum FloatingElementType {
  stickyNote, // Nota adhesiva estándar
  image,      // Imagen / fotografía
  examAlert,  // Tarjeta Ojo Examen / Alerta de Parcial
  codeSnippet // Bloque de código / Algoritmo interactivo
}

class FloatingElement {
  String id;
  Offset position;
  double width;
  double height;
  String text;
  bool isImage;
  String? imagePath;
  FloatingElementType elementType;
  String? language; // Ej: "Java", "Python", "C++", "SQL", "Dart", "Pseudocódigo"

  FloatingElement({
    required this.id,
    required this.position,
    this.width = 180.0,
    this.height = 140.0,
    this.text = '',
    this.isImage = false,
    this.imagePath,
    FloatingElementType? elementType,
    this.language,
  }) : elementType = elementType ?? (isImage ? FloatingElementType.image : FloatingElementType.stickyNote);

  Map<String, dynamic> toJson() => {
    'id': id,
    'dx': position.dx,
    'dy': position.dy,
    'width': width,
    'height': height,
    'text': text,
    'isImage': isImage,
    'imagePath': imagePath,
    'elementType': elementType.name,
    'language': language,
  };

  factory FloatingElement.fromJson(Map<String, dynamic> json) {
    final bool isImg = json['isImage'] ?? false;
    FloatingElementType type = FloatingElementType.stickyNote;

    final typeStr = json['elementType'] as String?;
    if (isImg) {
      type = FloatingElementType.image;
    } else if (typeStr == 'examAlert') {
      type = FloatingElementType.examAlert;
    } else if (typeStr == 'codeSnippet') {
      type = FloatingElementType.codeSnippet;
    }

    String textContent = json['text'] ?? '';
    String? lang = json['language'] as String?;

    // Detección automática para datos sincronizados desde el backend
    if (!isImg && textContent.startsWith('⚠️ [OJO EXAMEN]\n')) {
      type = FloatingElementType.examAlert;
      textContent = textContent.replaceFirst('⚠️ [OJO EXAMEN]\n', '');
    } else if (!isImg && textContent.startsWith('```')) {
      type = FloatingElementType.codeSnippet;
      final lines = textContent.split('\n');
      if (lines.isNotEmpty && lines.first.length > 3) {
        lang = lines.first.substring(3).trim();
      }
      if (lines.length >= 2) {
        final lastIdx = lines.last == '```' ? lines.length - 1 : lines.length;
        textContent = lines.sublist(1, lastIdx).join('\n');
      }
    }

    final double defaultWidth = type == FloatingElementType.codeSnippet
        ? 270.0
        : (type == FloatingElementType.examAlert ? 230.0 : 180.0);
    final double defaultHeight = type == FloatingElementType.codeSnippet
        ? 170.0
        : (type == FloatingElementType.examAlert ? 130.0 : 140.0);

    return FloatingElement(
      id: json['id'] ?? '',
      position: Offset(
        (json['dx'] as num?)?.toDouble() ?? 0.0,
        (json['dy'] as num?)?.toDouble() ?? 0.0,
      ),
      width: (json['width'] as num?)?.toDouble() ?? defaultWidth,
      height: (json['height'] as num?)?.toDouble() ?? defaultHeight,
      text: textContent,
      isImage: isImg,
      imagePath: json['imagePath'],
      elementType: type,
      language: lang,
    );
  }
}

class NotePageModel {
  String id;
  int pageIndex;
  String textContent;
  List<FloatingElement> floatingElements;

  NotePageModel({
    String? id,
    this.pageIndex = 0,
    this.textContent = '',
    List<FloatingElement>? floatingElements,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        floatingElements = floatingElements ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageIndex': pageIndex,
    'textContent': textContent,
    'floatingElements': floatingElements.map((e) => e.toJson()).toList(),
  };

  factory NotePageModel.fromJson(Map<String, dynamic> json) {
    return NotePageModel(
      id: json['id'] as String?,
      pageIndex: json['pageIndex'] as int? ?? 0,
      textContent: json['textContent'] ?? '',
      floatingElements: (json['floatingElements'] as List<dynamic>?)
          ?.map((e) => FloatingElement.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}
