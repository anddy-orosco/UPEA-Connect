class StoreItemModel {
  final String id;
  final String name;
  final String category; // 'pot', 'decoration', 'species'
  final int price;
  final String iconAsset; // o nombre de icono/emoji
  final bool isDefault;

  StoreItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.iconAsset,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'iconAsset': iconAsset,
    'isDefault': isDefault,
  };

  factory StoreItemModel.fromMap(Map<String, dynamic> map) => StoreItemModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    category: map['category'] ?? 'decoration',
    price: map['price'] ?? 0,
    iconAsset: map['iconAsset'] ?? '',
    isDefault: map['isDefault'] ?? false,
  );
}

class AcademicRank {
  final int level;
  final String title;
  final int requiredXp;

  AcademicRank({
    required this.level,
    required this.title,
    required this.requiredXp,
  });
}

// Rangos universitarios
final List<AcademicRank> academicRanks = [
  AcademicRank(level: 1, title: 'Cachimbo / Novato 🎒', requiredXp: 0),
  AcademicRank(level: 2, title: 'Estudiante Regular 📖', requiredXp: 200),
  AcademicRank(level: 3, title: 'Auxiliar de Cátedra 📝', requiredXp: 600),
  AcademicRank(level: 4, title: 'Candidato a Título 🎓', requiredXp: 1200),
  AcademicRank(level: 5, title: 'Decano del Enfoque 👑', requiredXp: 2000),
];

// Catálogo de la Tienda
final List<StoreItemModel> storeCatalog = [
  // Macetas
  StoreItemModel(id: 'pot_default', name: 'Maceta Arcilla', category: 'pot', price: 0, iconAsset: '🪴', isDefault: true),
  StoreItemModel(id: 'pot_neon', name: 'Maceta Cyberpunk', category: 'pot', price: 80, iconAsset: '✨'),
  StoreItemModel(id: 'pot_gold', name: 'Maceta Dorada', category: 'pot', price: 150, iconAsset: '🏆'),

  // Decoraciones
  StoreItemModel(id: 'dec_none', name: 'Sin Decoración', category: 'decoration', price: 0, iconAsset: '❌', isDefault: true),
  StoreItemModel(id: 'dec_lights', name: 'Luces Hada', category: 'decoration', price: 50, iconAsset: '💡'),
  StoreItemModel(id: 'dec_owl', name: 'Búho Sabio', category: 'decoration', price: 100, iconAsset: '🦉'),
  StoreItemModel(id: 'dec_books', name: 'Libros Apilados', category: 'decoration', price: 120, iconAsset: '📚'),

  // Especies
  StoreItemModel(id: 'sp_oak', name: 'Roble Académico', category: 'species', price: 0, iconAsset: '🌳', isDefault: true),
  StoreItemModel(id: 'sp_sakura', name: 'Sakura Campus', category: 'species', price: 200, iconAsset: '🌸'),
  StoreItemModel(id: 'sp_bonsai', name: 'Bonsái Zen', category: 'species', price: 300, iconAsset: '🌲'),
];