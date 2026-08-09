import 'package:flutter/material.dart';

class FloatingElement {
  String id;
  Offset position;
  double width;
  double height;
  String text;
  bool isImage;
  String? imagePath;

  FloatingElement({
    required this.id,
    required this.position,
    this.width = 180.0,
    this.height = 140.0,
    this.text = '',
    this.isImage = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dx': position.dx,
    'dy': position.dy,
    'width': width,
    'height': height,
    'text': text,
    'isImage': isImage,
    'imagePath': imagePath,
  };

  factory FloatingElement.fromJson(Map<String, dynamic> json) {
    return FloatingElement(
      id: json['id'] ?? '',
      position: Offset(
        (json['dx'] as num?)?.toDouble() ?? 0.0,
        (json['dy'] as num?)?.toDouble() ?? 0.0,
      ),
      width: (json['width'] as num?)?.toDouble() ?? 180.0,
      height: (json['height'] as num?)?.toDouble() ?? 140.0,
      text: json['text'] ?? '',
      isImage: json['isImage'] ?? false,
      imagePath: json['imagePath'],
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