class UserModel {
  final String nombre;
  final String email;
  final String carrera;
  final String semestre;
  final String? fotoPath;

  UserModel({
    required this.nombre,
    required this.email,
    required this.carrera,
    required this.semestre,
    this.fotoPath,
  });

  Map<String, String> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'carrera': carrera,
      'semestre': semestre,
      'fotoPath': fotoPath ?? '',
    };
  }

  factory UserModel.fromJson(Map<String, String> json) {
    return UserModel(
      nombre: json['nombre']!,
      email: json['email']!,
      carrera: json['carrera']!,
      semestre: json['semestre']!,
      fotoPath: json['fotoPath']!.isEmpty ? null : json['fotoPath'],
    );
  }
}
