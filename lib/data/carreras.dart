/// Catálogo de áreas y carreras de la UPEA, con su duración y unidad
/// académica (semestre o año), usado en register_screen.dart para los
/// selectores de Carrera y Semestre/Año.
/// Vive en lib/data/carreras.dart

enum UnidadAcademica { semestre, anio }

class Carrera {
  final String nombre;
  final int duracion;
  final UnidadAcademica unidad;

  const Carrera({
    required this.nombre,
    required this.duracion,
    required this.unidad,
  });
}

class AreaCarreras {
  final String nombre;
  final List<Carrera> carreras;

  const AreaCarreras({
    required this.nombre,
    required this.carreras,
  });
}

const List<AreaCarreras> areasUpea = [
  AreaCarreras(
    nombre: 'Área Salud',
    carreras: [
      Carrera(nombre: 'Enfermería', duracion: 5, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Medicina', duracion: 6, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Nutrición y Dietética', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
  AreaCarreras(
    nombre: 'Área de Desarrollo Tecnológico y Productivo',
    carreras: [
      Carrera(nombre: 'Ingeniería Electrónica', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería Textil', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería Autotrónica', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería Ambiental', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería Eléctrica', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería en Producción Empresarial', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
  AreaCarreras(
    nombre: 'Área Ciencias Agrícolas Pecuarias y Recursos Naturales',
    carreras: [
      Carrera(nombre: 'Medicina Veterinaria y Zootecnia', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería en Zootecnia e Industria Pecuaria', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería Agronómica', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
  AreaCarreras(
    nombre: 'Área Ciencias y Artes del Hábitat',
    carreras: [
      Carrera(nombre: 'Arquitectura', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Artes Plásticas', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
  AreaCarreras(
    nombre: 'Área Ciencias de la Educación',
    carreras: [
      Carrera(nombre: 'Ciencias de la Educación', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Educación Parvularia', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Psicomotricidad y Deportes', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
  AreaCarreras(
    nombre: 'Área de Estomatología',
    carreras: [
      Carrera(nombre: 'Tecnología en Mecánica Dental', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Odontología', duracion: 5, unidad: UnidadAcademica.anio),
    ],
  ),
  AreaCarreras(
    nombre: 'Área Ciencias Sociales',
    carreras: [
      Carrera(nombre: 'Comunicación Social', duracion: 5, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Trabajo Social', duracion: 5, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Ciencias del Desarrollo', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Lingüística e Idiomas', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Historia', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Psicología', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Sociología', duracion: 5, unidad: UnidadAcademica.anio),
    ],
  ),
  AreaCarreras(
    nombre: 'Áreas Ciencias Financieras y Administrativas',
    carreras: [
      Carrera(nombre: 'Administración de Empresas', duracion: 5, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Contaduría Pública', duracion: 5, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Gestión Turísticas y Hoteleras', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Comercio Internacional', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Economía', duracion: 5, unidad: UnidadAcademica.anio),
    ],
  ),
  AreaCarreras(
    nombre: 'Carreras sin Áreas',
    carreras: [
      Carrera(nombre: 'Ingeniería en Sistemas', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Derecho', duracion: 5, unidad: UnidadAcademica.anio),
      Carrera(nombre: 'Ciencias Políticas', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ciencias Físicas y Energías Alternativas', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
  AreaCarreras(
    nombre: 'Área Ciencia y Tecnología',
    carreras: [
      Carrera(nombre: 'Ingeniería Gas y Petroquímica', duracion: 10, unidad: UnidadAcademica.semestre),
      Carrera(nombre: 'Ingeniería Civil', duracion: 10, unidad: UnidadAcademica.semestre),
    ],
  ),
];
