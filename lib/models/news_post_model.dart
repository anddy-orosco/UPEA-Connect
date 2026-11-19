class NewsPostModel {
  final String id;
  final String title;
  final String content;
  final DateTime publishedAt;
  final List<String> imageUrls;
  final String category; // 'Comunicado', 'Convocatoria', 'Evento', 'Académico'
  final String facebookUrl;
  final int likesCount;
  final int sharesCount;
  final int commentsCount;
  final bool isPinned;
  final bool isLiveFromFacebook;
  final String? attachmentType;
  final int? albumPhotoCount;
  final String author;
  final String? authorAvatar;

  NewsPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    this.imageUrls = const [],
    this.category = 'Comunicado',
    required this.facebookUrl,
    this.likesCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    this.isLiveFromFacebook = false,
    this.attachmentType,
    this.albumPhotoCount,
    this.author = 'Carrera Ingenieria de Sistemas - UPEA',
    this.authorAvatar,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'publishedAt': publishedAt.toIso8601String(),
    'imageUrls': imageUrls,
    'category': category,
    'facebookUrl': facebookUrl,
    'likesCount': likesCount,
    'sharesCount': sharesCount,
    'commentsCount': commentsCount,
    'isPinned': isPinned,
    'isLiveFromFacebook': isLiveFromFacebook,
    'attachmentType': attachmentType,
    'albumPhotoCount': albumPhotoCount,
    'author': author,
    'authorAvatar': authorAvatar,
  };

  factory NewsPostModel.fromJson(Map<String, dynamic> json) {
    return NewsPostModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : DateTime.now(),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      category: json['category'] as String? ?? 'Comunicado',
      facebookUrl: json['facebookUrl'] as String? ??
          'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      isLiveFromFacebook: json['isLiveFromFacebook'] as bool? ?? false,
      attachmentType: json['attachmentType'] as String?,
      albumPhotoCount: (json['albumPhotoCount'] as num?)?.toInt(),
      author: json['author'] as String? ?? 'Carrera Ingenieria de Sistemas - UPEA',
      authorAvatar: json['authorAvatar'] as String?,
    );
  }
}
