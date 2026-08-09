import 'note_page_model.dart';

class NoteModel {
  String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String? courseName;
  List<NotePageModel> pages;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    List<NotePageModel>? pages,
  }) : pages = pages ?? [NotePageModel()];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'courseName': courseName,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      courseName: json['courseName'] as String?,
      pages: (json['pages'] as List<dynamic>?)
          ?.map((p) => NotePageModel.fromJson(p as Map<String, dynamic>))
          .toList() ??
          [NotePageModel()],
    );
  }
}