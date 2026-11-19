class Noticia {
  final int id;
  final DateTime createdAt;
  final String titulo;
  final String categoria; // "Examen", "Convocatoria", "Evento", "Comunicado"
  final String resumen;
  final String contenido;
  final List<String> imagenes; // URLs públicas desde el bucket noticias-img
  final bool destacada;

  Noticia({
    required this.id,
    required this.createdAt,
    required this.titulo,
    required this.categoria,
    required this.resumen,
    required this.contenido,
    required this.imagenes,
    this.destacada = false,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      titulo: json['titulo'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'Comunicado',
      resumen: json['resumen'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      imagenes: (json['imagenes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      destacada: json['destacada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'titulo': titulo,
      'categoria': categoria,
      'resumen': resumen,
      'contenido': contenido,
      'imagenes': imagenes,
      'destacada': destacada,
    };
  }
}
