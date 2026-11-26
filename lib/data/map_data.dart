import 'package:flutter/material.dart';
import '../models/map_location_model.dart';

/// Base de datos estructurada de todos los pisos, aulas, laboratorios y
/// servicios de la Torre Tecnológica UPEA - Carrera Ingeniería de Sistemas.
///
/// Todas las coordenadas (`x`, `y`, `stairsEntry`, `routeWaypoints`) están
/// normalizadas entre `0.0` y `1.0` respecto al plano PNG (1792x2400).
class MapData {
  MapData._();

  static const double planAspectRatio = 1792 / 2400;

  static const List<MapFloorModel> floors = [
    // =========================================================================
    // PISO 5
    // =========================================================================
    MapFloorModel(
      code: 'P5',
      floorName: 'Piso 5',
      subtitle: 'Auditorium Víctor Mamani, Aulas 1–3 y Asociación de Docentes',
      imagePath: 'assets/images/piso5.png',
      aspectRatio: planAspectRatio,
      themeColor: Colors.deepPurple,
      stairsEntry: MapPoint(0.51, 0.73),
      locations: [
        MapLocationItem(
          id: 'p5_auditorio',
          floorCode: 'P5',
          name: 'Auditorium "Víctor Mamani"',
          shortLabel: 'Auditorium',
          category: MapLocationCategory.aulas,
          x: 0.79,
          y: 0.415,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Eventos y Defensas • 08:00 - 20:00',
          fullSchedule:
              'Lunes a Viernes: 08:00 - 20:00\nSábados: Según agenda académica o defensas de grado.',
          detailsTitle: 'Espacio y Equipamiento',
          detailsBody:
              'Auditorio principal de Ingeniería de Sistemas para conferencias, seminarios, defensas de tesis y actos académicos.',
          directionsText:
              'Sube al Piso 5 por las gradas centrales, avanza hasta el fondo del pasillo e ingresa por la puerta derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.60, 0.41),
          ],
          keywords: [
            'auditorium',
            'auditorio',
            'victor mamani',
            'mamani',
            'conferencias',
            'defensa',
            'actos',
            'eventos',
          ],
        ),
        MapLocationItem(
          id: 'p5_aula_3',
          floorCode: 'P5',
          name: 'Piso 5to - Aula 3',
          shortLabel: 'Aula 3',
          category: MapLocationCategory.aulas,
          x: 0.205,
          y: 0.418,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Clases de 07:30 a 21:00',
          fullSchedule:
              'Lunes a Viernes: 07:30 - 21:00\nSábados: 08:00 - 13:00',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Pizarra acrílica, proyector multimedia y mobiliario para asignaturas de cursos superiores.',
          directionsText:
              'Sube al Piso 5, camina hasta el fondo del pasillo central y gira a la izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.41, 0.41),
            MapPoint(0.205, 0.41),
          ],
          keywords: ['aula 3', 'piso 5', '5to', 'salon', 'clase'],
        ),
        MapLocationItem(
          id: 'p5_aula_2',
          floorCode: 'P5',
          name: 'Piso 5to - Aula 2',
          shortLabel: 'Aula 2',
          category: MapLocationCategory.aulas,
          x: 0.41,
          y: 0.565,
          statusBadge: 'EN USO',
          scheduleSummary: 'Clases de 07:30 a 21:00',
          fullSchedule:
              'Lunes a Viernes: 07:30 - 21:00\nSábados: 08:00 - 13:00',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Aula teórica con pizarra, proyector y ventilación natural.',
          directionsText:
              'Al subir al Piso 5, avanza por el pasillo central y toma la primera puerta a la izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.475),
            MapPoint(0.41, 0.475),
          ],
          keywords: ['aula 2', 'piso 5', '5to', 'salon', 'clase'],
        ),
        MapLocationItem(
          id: 'p5_aula_1',
          floorCode: 'P5',
          name: 'Piso 5to - Aula 1',
          shortLabel: 'Aula 1',
          category: MapLocationCategory.aulas,
          x: 0.80,
          y: 0.565,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Clases de 07:30 a 21:00',
          fullSchedule:
              'Lunes a Viernes: 07:30 - 21:00\nSábados: 08:00 - 13:00',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Aula teórica amplia para clases magistrales y evaluaciones.',
          directionsText:
              'Subiendo al Piso 5, toma el acceso del pasillo hacia la derecha frente al hall.',
          routeWaypoints: [
            MapPoint(0.51, 0.57),
            MapPoint(0.60, 0.57),
          ],
          keywords: ['aula 1', 'piso 5', '5to', 'salon', 'clase'],
        ),
        MapLocationItem(
          id: 'p5_asociacion_docentes',
          floorCode: 'P5',
          name: 'Asociación de Docentes',
          shortLabel: 'Docentes',
          category: MapLocationCategory.tramites,
          x: 0.80,
          y: 0.68,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 09:00 a 18:00',
          fullSchedule: 'Lunes a Viernes: 09:00 - 12:30 y 14:30 - 18:00',
          detailsTitle: 'Funciones y Trámites',
          detailsBody:
              'Oficina de representación docente, coordinación gremial y reuniones académicas.',
          directionsText:
              'Al llegar por las gradas al Piso 5, gira inmediatamente a la derecha hacia el ingreso amarillo.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.59, 0.67),
            MapPoint(0.59, 0.622),
            MapPoint(0.80, 0.622),
          ],
          keywords: [
            'asociacion',
            'docentes',
            'profesores',
            'oficina',
            'coordinacion',
          ],
        ),
        MapLocationItem(
          id: 'p5_banos',
          floorCode: 'P5',
          name: 'Baños Piso 5',
          category: MapLocationCategory.banos,
          x: 0.22,
          y: 0.675,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Disponible 07:00 - 21:30',
          fullSchedule:
              'Lunes a Sábado: 07:00 - 21:30 • Baños de damas y varones.',
          detailsTitle: 'Servicios',
          detailsBody: 'Sanitarios completos, lavamanos y accesos diferenciados.',
          directionsText:
              'Llegando por las gradas al Piso 5, gira a la izquierda en el hall hacia los sanitarios.',
          routeWaypoints: [
            MapPoint(0.51, 0.675),
            MapPoint(0.35, 0.675),
          ],
          keywords: ['sanitario', 'bano', 'baño', 'wc', 'aseo'],
        ),
        MapLocationItem(
          id: 'p5_extintor',
          floorCode: 'P5',
          name: 'Extintor Piso 5',
          category: MapLocationCategory.extintores,
          x: 0.45,
          y: 0.625,
          statusBadge: 'OPERATIVO',
          scheduleSummary: 'Disponible 24/7',
          fullSchedule: 'Equipo PQS Multipropósito • Inspección vigente.',
          detailsTitle: 'Seguridad',
          detailsBody:
              'Extintor ABC de respuesta rápida en el hall de evacuación hacia las gradas.',
          directionsText:
              'En el hall del Piso 5, justo a la salida hacia el corredor central.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.45, 0.67),
          ],
          keywords: ['fuego', 'incendio', 'emergencia', 'estintor', 'extintor'],
        ),
      ],
    ),

    // =========================================================================
    // PISO 4 (PISO SELECCIONADO POR DEFECTO)
    // =========================================================================
    MapFloorModel(
      code: 'P4',
      floorName: 'Piso 4',
      subtitle: 'Kardex, Biblioteca, Dirección de Carrera e Investigación',
      imagePath: 'assets/images/piso4.png',
      aspectRatio: planAspectRatio,
      themeColor: Colors.blue,
      stairsEntry: MapPoint(0.51, 0.73),
      locations: [
        MapLocationItem(
          id: 'p4_kardex',
          floorCode: 'P4',
          name: 'Kardex Académico',
          shortLabel: 'Kardex',
          category: MapLocationCategory.tramites,
          x: 0.79,
          y: 0.565,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención hasta las 18:00',
          fullSchedule:
              'Lunes a Viernes:\nMañana: 08:30 - 12:30\nTarde: 14:00 - 18:00',
          detailsTitle: 'Trámites',
          detailsBody:
              'Inscripciones, Certificados de notas, Récord Académico, Legalizaciones y Convalidaciones.',
          directionsText:
              'Sube al Piso 4 y avanza por el pasillo hacia la primera puerta del ala derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.57),
            MapPoint(0.60, 0.57),
          ],
          keywords: [
            'inscripcion',
            'certificados',
            'record',
            'kardex',
            'tramites',
            'notas',
          ],
        ),
        MapLocationItem(
          id: 'p4_biblioteca',
          floorCode: 'P4',
          name: 'Biblioteca Especializada',
          shortLabel: 'Biblioteca',
          category: MapLocationCategory.aulas,
          x: 0.79,
          y: 0.415,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Abierto 08:00 - 20:00',
          fullSchedule: 'Lunes a Viernes: 08:00 - 20:00\nSábados: 08:30 - 13:00',
          detailsTitle: 'Servicios y Recursos',
          detailsBody:
              'Sala de lectura silenciosa, préstamos de bibliografía técnica, proyectos de grado y tesis.',
          directionsText:
              'Avanza por el pasillo del Piso 4 hasta el fondo y entra por la puerta derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.60, 0.41),
          ],
          keywords: ['libros', 'leer', 'estudio', 'tesis', 'biblioteca'],
        ),
        MapLocationItem(
          id: 'p4_direccion',
          floorCode: 'P4',
          name: 'Dirección de Carrera',
          shortLabel: 'Dirección',
          category: MapLocationCategory.tramites,
          x: 0.80,
          y: 0.68,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención hasta las 18:00',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:30 - 18:00',
          detailsTitle: 'Trámites y Autoridades',
          detailsBody:
              'Despacho de Dirección de Carrera, cartas de pasantía, modalidades de graduación y autorizaciones.',
          directionsText:
              'Al subir al Piso 4 por las gradas, gira a la derecha junto al hall principal.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.59, 0.67),
            MapPoint(0.59, 0.622),
            MapPoint(0.80, 0.622),
          ],
          keywords: [
            'director',
            'carta',
            'pasantia',
            'direccion',
            'carrera',
            'autorizacion',
          ],
        ),
        MapLocationItem(
          id: 'p4_lab_posgrado',
          floorCode: 'P4',
          name: 'Laboratorio de Posgrado (Lab-Posgrado)',
          shortLabel: 'Lab-Posgrado',
          category: MapLocationCategory.laboratorios,
          x: 0.21,
          y: 0.42,
          statusBadge: 'RESERVADO',
          isOpenNow: false,
          scheduleSummary: 'Prácticas e Investigación 14:00 - 21:00',
          fullSchedule:
              'Lunes a Viernes: 14:00 - 21:00\nSábados: 08:00 - 18:00 (Maestrías y Diplomados)',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Estaciones de alto rendimiento para proyectos de maestría, análisis de datos y simulación.',
          directionsText:
              'Recorre el pasillo central del Piso 4 hasta el fondo y entra por la puerta izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.41, 0.41),
            MapPoint(0.21, 0.41),
          ],
          keywords: [
            'posgrado',
            'postgrado',
            'maestria',
            'investigacion',
            'laboratorio',
            'lab-posgrado',
          ],
        ),
        MapLocationItem(
          id: 'p4_instituto_investigacion',
          floorCode: 'P4',
          name: 'Instituto de Investigación',
          shortLabel: 'Investigación',
          category: MapLocationCategory.laboratorios,
          x: 0.425,
          y: 0.575,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 08:30 a 18:30',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:00 - 18:30',
          detailsTitle: 'Actividades y Proyectos',
          detailsBody:
              'Sociedades científicas, revisión de artículos, feria científica y proyectos de innovación tecnológica.',
          directionsText:
              'Avanza por el pasillo central del Piso 4 y toma el ingreso del ala izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.47),
            MapPoint(0.425, 0.47),
          ],
          keywords: [
            'instituto',
            'investigacion',
            'investigación',
            'ciencia',
            'feria',
            'sociedad cientifica',
          ],
        ),
        MapLocationItem(
          id: 'p4_area_descanso',
          floorCode: 'P4',
          name: 'Área de Descanso (Piso 4)',
          shortLabel: 'Descanso',
          category: MapLocationCategory.accesibilidad,
          x: 0.76,
          y: 0.258,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Libre acceso 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Zona Estudiantil',
          detailsBody:
              'Corredor superior ventilado con área de espera y descanso entre clases y trámites.',
          directionsText:
              'Sigue el pasillo central del Piso 4 recto hasta el extremo norte del piso.',
          routeWaypoints: [
            MapPoint(0.51, 0.25),
          ],
          keywords: ['descanso', 'espera', 'bancas', 'terraza', 'recreo'],
        ),
        MapLocationItem(
          id: 'p4_banos',
          floorCode: 'P4',
          name: 'Baños Piso 4',
          category: MapLocationCategory.banos,
          x: 0.22,
          y: 0.675,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Habilitado 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Servicios',
          detailsBody:
              'Sanitarios diferenciados para damas y varones frente al hall de gradas.',
          directionsText:
              'Al subir al Piso 4, gira a la izquierda en el vestíbulo de las gradas.',
          routeWaypoints: [
            MapPoint(0.51, 0.675),
            MapPoint(0.35, 0.675),
          ],
          keywords: ['sanitario', 'bano', 'baño', 'wc', 'higiene'],
        ),
        MapLocationItem(
          id: 'p4_extintor',
          floorCode: 'P4',
          name: 'Extintor Piso 4',
          category: MapLocationCategory.extintores,
          x: 0.45,
          y: 0.625,
          statusBadge: 'OPERATIVO',
          scheduleSummary: 'Disponible 24/7',
          fullSchedule:
              'Extintor PQS ABC 6 kg • Revisión técnica al día.',
          detailsTitle: 'Seguridad y Emergencias',
          detailsBody:
              'Extintor portátil y punto de evacuación junto a la salida hacia gradas.',
          directionsText:
              'En el hall del Piso 4, esquina izquierda de salida al pasillo.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.45, 0.67),
          ],
          keywords: ['fuego', 'incendio', 'emergencia', 'estintor', 'extintor'],
        ),
      ],
    ),

    // =========================================================================
    // PISO 3
    // =========================================================================
    MapFloorModel(
      code: 'P3',
      floorName: 'Piso 3',
      subtitle: 'Laboratorios de Internet, IA, Redes, TEM y Postgrado 2',
      imagePath: 'assets/images/piso3.png',
      aspectRatio: planAspectRatio,
      themeColor: Colors.teal,
      stairsEntry: MapPoint(0.51, 0.73),
      locations: [
        MapLocationItem(
          id: 'p3_lab_internet',
          floorCode: 'P3',
          name: 'Laboratorio de Internet (Lab-Internet)',
          shortLabel: 'Lab-Internet',
          category: MapLocationCategory.laboratorios,
          x: 0.22,
          y: 0.415,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Prácticas 08:00 - 20:30',
          fullSchedule: 'Lunes a Viernes: 08:00 - 20:30\nSábados: 08:00 - 13:00',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Estaciones conectadas por fibra óptica para programación web, servicios en la nube y prácticas libres.',
          directionsText:
              'Sube al Piso 3, avanza hasta el fondo del pasillo central y gira a la izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.41, 0.41),
            MapPoint(0.22, 0.41),
          ],
          keywords: ['internet', 'web', 'lab-internet', 'computadoras', 'lab'],
        ),
        MapLocationItem(
          id: 'p3_lab_redes',
          floorCode: 'P3',
          name: 'Laboratorio de Redes (Lab-Redes)',
          shortLabel: 'Lab-Redes',
          category: MapLocationCategory.laboratorios,
          x: 0.79,
          y: 0.415,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Prácticas de 08:00 a 20:00',
          fullSchedule:
              'Lunes a Viernes: 08:00 - 20:00\nSábados: 08:30 - 12:30',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Racks Cisco, switches administrables, routers, analizadores de espectro y cableado estructurado.',
          directionsText:
              'Sube al Piso 3, camina hasta el final del pasillo y entra a mano derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.60, 0.41),
          ],
          keywords: [
            'cisco',
            'redes',
            'lab-redes',
            'routers',
            'telecomunicaciones',
            'laboratorio',
          ],
        ),
        MapLocationItem(
          id: 'p3_lab_ia',
          floorCode: 'P3',
          name: 'Laboratorio de Inteligencia Artificial (Lab-IA)',
          shortLabel: 'Lab-IA',
          category: MapLocationCategory.laboratorios,
          x: 0.41,
          y: 0.57,
          statusBadge: 'EN USO',
          scheduleSummary: 'Sesiones 08:30 - 21:00',
          fullSchedule: 'Lunes a Viernes: 08:30 - 21:00',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Estaciones de trabajo con GPU dedicadas para Machine Learning, Deep Learning y visión computacional.',
          directionsText:
              'Subiendo al Piso 3, avanza por el pasillo central y toma la puerta del ala izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.47),
            MapPoint(0.41, 0.47),
          ],
          keywords: [
            'ia',
            'inteligencia artificial',
            'lab-ia',
            'machine learning',
            'gpu',
            'python',
          ],
        ),
        MapLocationItem(
          id: 'p3_lab_tem',
          floorCode: 'P3',
          name: 'Lab. Tecnologías Emergentes (Lab-TEM)',
          shortLabel: 'Lab-TEM',
          category: MapLocationCategory.laboratorios,
          x: 0.82,
          y: 0.575,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Prácticas 08:00 - 20:30',
          fullSchedule: 'Lunes a Viernes: 08:00 - 20:30',
          detailsTitle: 'Equipamiento y Enfoque',
          detailsBody:
              'Espacio equipado para IoT, realidad aumentada, sistemas embebidos y desarrollo de software emergente.',
          directionsText:
              'Subiendo al Piso 3, entra por la primera puerta de la derecha pasando el hall.',
          routeWaypoints: [
            MapPoint(0.51, 0.57),
            MapPoint(0.60, 0.57),
          ],
          keywords: [
            'tem',
            'emergentes',
            'lab-tem',
            'tecnologias emergentes',
            'iot',
            'software',
          ],
        ),
        MapLocationItem(
          id: 'p3_postgrado_2',
          floorCode: 'P3',
          name: 'Postgrado 2',
          shortLabel: 'Postgrado 2',
          category: MapLocationCategory.aulas,
          x: 0.80,
          y: 0.68,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Turnos Tarde y Noche / Fines de semana',
          fullSchedule:
              'Lunes a Viernes: 18:00 - 21:30\nSábados y Domingos: 08:00 - 18:00',
          detailsTitle: 'Actividades',
          detailsBody:
              'Aula multimedia destinada a módulos de especialización, diplomados y programas de postgrado.',
          directionsText:
              'Al llegar por las gradas al Piso 3, gira inmediatamente a la derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.59, 0.67),
            MapPoint(0.59, 0.622),
            MapPoint(0.80, 0.622),
          ],
          keywords: ['postgrado', 'posgrado', 'postgrado 2', 'diplomado', 'aula'],
        ),
        MapLocationItem(
          id: 'p3_area_descanso',
          floorCode: 'P3',
          name: 'Área de Descanso (Piso 3)',
          shortLabel: 'Descanso',
          category: MapLocationCategory.accesibilidad,
          x: 0.76,
          y: 0.258,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Libre acceso 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Zona Estudiantil',
          detailsBody:
              'Pasillo superior de descanso e iluminación natural junto a los laboratorios.',
          directionsText:
              'Recorre el pasillo central del Piso 3 recto hasta el extremo norte.',
          routeWaypoints: [
            MapPoint(0.51, 0.25),
          ],
          keywords: ['descanso', 'bancas', 'espera', 'terraza'],
        ),
        MapLocationItem(
          id: 'p3_banos',
          floorCode: 'P3',
          name: 'Baños Piso 3',
          category: MapLocationCategory.banos,
          x: 0.22,
          y: 0.675,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Habilitado 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Servicios',
          detailsBody: 'Sanitarios de estudiantes junto al hall de salida.',
          directionsText: 'Lado izquierdo saliendo de las gradas del Piso 3.',
          routeWaypoints: [
            MapPoint(0.51, 0.675),
            MapPoint(0.35, 0.675),
          ],
          keywords: ['sanitario', 'bano', 'baño', 'wc'],
        ),
        MapLocationItem(
          id: 'p3_extintor',
          floorCode: 'P3',
          name: 'Extintor Piso 3',
          category: MapLocationCategory.extintores,
          x: 0.45,
          y: 0.625,
          statusBadge: 'OPERATIVO',
          scheduleSummary: 'Disponible 24/7',
          fullSchedule: 'Extintor CO2 y PQS para laboratorios de cómputo.',
          detailsTitle: 'Seguridad Eléctrica',
          detailsBody:
              'Equipo contra incendios en el punto de encuentro del Piso 3.',
          directionsText: 'Junto al corredor de ingreso a los laboratorios.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.45, 0.67),
          ],
          keywords: ['fuego', 'incendio', 'co2', 'estintor', 'extintor'],
        ),
      ],
    ),

    // =========================================================================
    // PISO 2
    // =========================================================================
    MapFloorModel(
      code: 'P2',
      floorName: 'Piso 2',
      subtitle: 'Unidades Área U-TIC y Dirección U-TIC',
      imagePath: 'assets/images/piso2.png',
      aspectRatio: planAspectRatio,
      themeColor: Colors.indigo,
      stairsEntry: MapPoint(0.51, 0.73),
      locations: [
        MapLocationItem(
          id: 'p2_utic_no',
          floorCode: 'P2',
          name: 'Área U-TIC (Soporte y Desarrollo)',
          shortLabel: 'U-TIC Dev',
          category: MapLocationCategory.laboratorios,
          x: 0.22,
          y: 0.415,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 08:30 a 18:30',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:00 - 18:30',
          detailsTitle: 'Servicios U-TIC',
          detailsBody:
              'Desarrollo de sistemas universitarios, mantenimiento de portales y soporte técnico institucional.',
          directionsText:
              'Sube al Piso 2, llega al fondo del pasillo central y entra por la puerta izquierda.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.41, 0.41),
            MapPoint(0.22, 0.41),
          ],
          keywords: ['utic', 'u-tic', 'desarrollo', 'soporte', 'sistemas'],
        ),
        MapLocationItem(
          id: 'p2_utic_ne',
          floorCode: 'P2',
          name: 'Área U-TIC (Servidores e Infraestructura)',
          shortLabel: 'U-TIC Infra',
          category: MapLocationCategory.laboratorios,
          x: 0.79,
          y: 0.415,
          statusBadge: 'RESTRINGIDO',
          isOpenNow: false,
          scheduleSummary: 'Personal técnico 08:30 - 18:30',
          fullSchedule: 'Lunes a Viernes: 08:30 - 18:30 (Acceso autorizado)',
          detailsTitle: 'Infraestructura',
          detailsBody:
              'Administración de centros de datos, servidores institucionales y servicios de red universitaria.',
          directionsText:
              'Al fondo del pasillo central del Piso 2, puerta del ala derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.60, 0.41),
          ],
          keywords: ['utic', 'u-tic', 'servidores', 'datacenter', 'red'],
        ),
        MapLocationItem(
          id: 'p2_utic_so',
          floorCode: 'P2',
          name: 'Área U-TIC (Redes y Conectividad)',
          shortLabel: 'U-TIC Redes',
          category: MapLocationCategory.laboratorios,
          x: 0.41,
          y: 0.565,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 08:30 a 18:30',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:00 - 18:30',
          detailsTitle: 'Servicios',
          detailsBody:
              'Soporte de red Wi-Fi universitaria, credenciales institucionales y equipamiento de conectividad.',
          directionsText:
              'Subiendo al Piso 2, entra al primer ambiente del lado izquierdo del pasillo.',
          routeWaypoints: [
            MapPoint(0.51, 0.47),
            MapPoint(0.41, 0.47),
          ],
          keywords: ['utic', 'u-tic', 'wifi', 'redes', 'cuenta', 'conectividad'],
        ),
        MapLocationItem(
          id: 'p2_utic_se',
          floorCode: 'P2',
          name: 'Área U-TIC (Atención y Cuentas)',
          shortLabel: 'U-TIC Atención',
          category: MapLocationCategory.tramites,
          x: 0.80,
          y: 0.565,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 08:30 a 18:00',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:00 - 18:00',
          detailsTitle: 'Trámites Digitales',
          detailsBody:
              'Habilitación de correo institucional, recuperación de acceso al sistema y soporte estudiantil.',
          directionsText:
              'Sube al Piso 2 y gira hacia la primera puerta del lado derecho del pasillo.',
          routeWaypoints: [
            MapPoint(0.51, 0.57),
            MapPoint(0.60, 0.57),
          ],
          keywords: [
            'utic',
            'u-tic',
            'correo',
            'clave',
            'matriculacion',
            'tramites',
          ],
        ),
        MapLocationItem(
          id: 'p2_direccion',
          floorCode: 'P2',
          name: 'Dirección U-TIC',
          shortLabel: 'Dirección',
          category: MapLocationCategory.tramites,
          x: 0.80,
          y: 0.68,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 08:30 a 18:00',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:30 - 18:00',
          detailsTitle: 'Dirección Administrativa',
          detailsBody:
              'Jefatura y coordinación general de la Unidad de Tecnologías de Información y Comunicación.',
          directionsText:
              'Llegando al Piso 2 por las gradas, gira inmediatamente a la derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.59, 0.67),
            MapPoint(0.59, 0.622),
            MapPoint(0.80, 0.622),
          ],
          keywords: ['direccion', 'dirección', 'jefatura', 'utic', 'u-tic'],
        ),
        MapLocationItem(
          id: 'p2_banos',
          floorCode: 'P2',
          name: 'Baños Piso 2',
          category: MapLocationCategory.banos,
          x: 0.22,
          y: 0.675,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Disponible 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Servicios',
          detailsBody: 'Sanitarios completos para estudiantes y personal.',
          directionsText: 'Sector izquierdo del vestíbulo del Piso 2.',
          routeWaypoints: [
            MapPoint(0.51, 0.675),
            MapPoint(0.35, 0.675),
          ],
          keywords: ['sanitario', 'bano', 'baño', 'wc'],
        ),
        MapLocationItem(
          id: 'p2_extintor',
          floorCode: 'P2',
          name: 'Extintor Piso 2',
          category: MapLocationCategory.extintores,
          x: 0.45,
          y: 0.625,
          statusBadge: 'OPERATIVO',
          scheduleSummary: 'Disponible 24/7',
          fullSchedule: 'Extintor CO2 / PQS ABC • Verificado.',
          detailsTitle: 'Seguridad',
          detailsBody: 'Extintor de emergencia junto al vestíbulo y corredor.',
          directionsText:
              'A un paso del descansillo izquierdo saliendo de las gradas del Piso 2.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.45, 0.67),
          ],
          keywords: ['fuego', 'incendio', 'estintor', 'extintor'],
        ),
      ],
    ),

    // =========================================================================
    // PISO 1
    // =========================================================================
    MapFloorModel(
      code: 'P1',
      floorName: 'Piso 1',
      subtitle: 'Aulas 1–3, Laboratorio de Física y Preuniversitario 1',
      imagePath: 'assets/images/piso1.png',
      aspectRatio: planAspectRatio,
      themeColor: Colors.orange,
      stairsEntry: MapPoint(0.51, 0.73),
      locations: [
        MapLocationItem(
          id: 'p1_lab_fisica',
          floorCode: 'P1',
          name: 'Laboratorio de Física (Lab-Fis)',
          shortLabel: 'Lab-Fis',
          category: MapLocationCategory.laboratorios,
          x: 0.79,
          y: 0.415,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Prácticas hasta las 19:00',
          fullSchedule: 'Lunes a Viernes: 08:00 - 19:00\nSábados: 08:00 - 13:00',
          detailsTitle: 'Equipamiento',
          detailsBody:
              'Mesas de experimentación, osciloscopios, multímetros, fuentes reguladas y kits de física aplicada.',
          directionsText:
              'Sube al Piso 1, recorre el pasillo hasta el final e ingresa por la puerta derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.60, 0.41),
          ],
          keywords: [
            'fisica',
            'física',
            'lab-fis',
            'electronica',
            'laboratorio',
          ],
        ),
        MapLocationItem(
          id: 'p1_aula_2',
          floorCode: 'P1',
          name: 'Piso 1 - Aula 2',
          shortLabel: 'Aula 2',
          category: MapLocationCategory.aulas,
          x: 0.22,
          y: 0.415,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Clases de 07:30 a 21:00',
          fullSchedule: 'Lunes a Sábado: 07:30 - 21:00',
          detailsTitle: 'Actividades',
          detailsBody:
              'Aula de materias básicas: cálculo, álgebra lineal y programación inicial.',
          directionsText:
              'Al fondo del pasillo central del Piso 1, puerta del lado izquierdo.',
          routeWaypoints: [
            MapPoint(0.51, 0.41),
            MapPoint(0.41, 0.41),
            MapPoint(0.22, 0.41),
          ],
          keywords: ['aula 2', 'piso 1', 'salon', 'clase'],
        ),
        MapLocationItem(
          id: 'p1_aula_1',
          floorCode: 'P1',
          name: 'Piso 1 - Aula 1',
          shortLabel: 'Aula 1',
          category: MapLocationCategory.aulas,
          x: 0.40,
          y: 0.565,
          statusBadge: 'EN USO',
          scheduleSummary: 'Clases de 07:30 a 21:00',
          fullSchedule: 'Lunes a Sábado: 07:30 - 21:00',
          detailsTitle: 'Actividades',
          detailsBody:
              'Aula teórica amplia para cursos de primer y segundo semestre.',
          directionsText:
              'Subiendo al Piso 1, entra por la primera puerta a la izquierda del corredor.',
          routeWaypoints: [
            MapPoint(0.51, 0.47),
            MapPoint(0.40, 0.47),
          ],
          keywords: ['aula 1', 'piso 1', 'salon', 'clase'],
        ),
        MapLocationItem(
          id: 'p1_aula_3',
          floorCode: 'P1',
          name: 'Piso 1 - Aula 3',
          shortLabel: 'Aula 3',
          category: MapLocationCategory.aulas,
          x: 0.80,
          y: 0.565,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Clases de 07:30 a 21:00',
          fullSchedule: 'Lunes a Sábado: 07:30 - 21:00',
          detailsTitle: 'Actividades',
          detailsBody:
              'Aula teórica y de ayudantías frente al pasillo central.',
          directionsText:
              'Sube al Piso 1 y toma la primera puerta hacia el lado derecho del corredor.',
          routeWaypoints: [
            MapPoint(0.51, 0.57),
            MapPoint(0.60, 0.57),
          ],
          keywords: ['aula 3', 'piso 1', 'salon', 'clase'],
        ),
        MapLocationItem(
          id: 'p1_preu_1',
          floorCode: 'P1',
          name: 'Preuniversitario 1',
          shortLabel: 'Preu 1',
          category: MapLocationCategory.aulas,
          x: 0.80,
          y: 0.68,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Turnos Mañana, Tarde y Noche',
          fullSchedule: 'Lunes a Sábado: 07:30 - 20:30',
          detailsTitle: 'Actividades',
          detailsBody:
              'Curso preuniversitario, clases de nivelación y auxiliares de docencia.',
          directionsText:
              'Llegando al Piso 1 por las gradas, gira inmediatamente a la derecha.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.59, 0.67),
            MapPoint(0.59, 0.622),
            MapPoint(0.80, 0.622),
          ],
          keywords: ['preu', 'preuniversitario', 'prefacultativo', 'aula'],
        ),
        MapLocationItem(
          id: 'p1_banos',
          floorCode: 'P1',
          name: 'Baños Piso 1',
          category: MapLocationCategory.banos,
          x: 0.22,
          y: 0.675,
          statusBadge: 'DISPONIBLE',
          scheduleSummary: 'Disponible 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Servicios',
          detailsBody: 'Sanitarios estudiantiles del primer piso.',
          directionsText:
              'En el hall del primer piso, gira hacia el corredor izquierdo.',
          routeWaypoints: [
            MapPoint(0.51, 0.675),
            MapPoint(0.35, 0.675),
          ],
          keywords: ['sanitario', 'bano', 'baño', 'wc'],
        ),
        MapLocationItem(
          id: 'p1_extintor',
          floorCode: 'P1',
          name: 'Extintor Piso 1',
          category: MapLocationCategory.extintores,
          x: 0.45,
          y: 0.625,
          statusBadge: 'OPERATIVO',
          scheduleSummary: 'Disponible 24/7',
          fullSchedule: 'Tipo PQS ABC • Revisión vigente.',
          detailsTitle: 'Seguridad',
          detailsBody:
              'Extintor principal en el vestíbulo junto a las gradas de salida.',
          directionsText:
              'Frente a las gradas del primer piso, hacia el inicio del pasillo.',
          routeWaypoints: [
            MapPoint(0.51, 0.67),
            MapPoint(0.45, 0.67),
          ],
          keywords: ['fuego', 'incendio', 'estintor', 'extintor'],
        ),
      ],
    ),

    // =========================================================================
    // PLANTA BAJA
    // =========================================================================
    MapFloorModel(
      code: 'PB',
      floorName: 'Planta Baja',
      subtitle: 'Área de Acceso, Ingreso y Salida y Gradas Centrales',
      imagePath: 'assets/images/planta_baja.png',
      aspectRatio: planAspectRatio,
      themeColor: Colors.green,
      stairsEntry: MapPoint(0.76, 0.72),
      locations: [
        MapLocationItem(
          id: 'pb_area_acceso',
          floorCode: 'PB',
          name: 'Área de Acceso y Hall Central',
          shortLabel: 'Acceso',
          category: MapLocationCategory.accesibilidad,
          x: 0.49,
          y: 0.47,
          statusBadge: 'ACTIVO',
          scheduleSummary: 'Disponible 07:00 - 21:30',
          fullSchedule:
              'Acceso peatonal y circulación continua durante toda la jornada académica.',
          detailsTitle: 'Circulación Principal',
          detailsBody:
              'Amplio vestíbulo central con acceso sin desniveles hacia el interior del bloque tecnológico.',
          directionsText:
              'Desde la puerta de ingreso, sigue el flujo verde hacia el norte hasta el hall central.',
          routeWaypoints: [
            MapPoint(0.76, 0.56),
            MapPoint(0.63, 0.56),
            MapPoint(0.63, 0.47),
          ],
          keywords: [
            'area de acceso',
            'acceso',
            'hall',
            'entrada',
            'rampa',
            'silla de ruedas',
          ],
        ),
        MapLocationItem(
          id: 'pb_gradas_centrales',
          floorCode: 'PB',
          name: 'Gradas Centrales',
          shortLabel: 'Gradas',
          category: MapLocationCategory.accesibilidad,
          x: 0.50,
          y: 0.735,
          statusBadge: 'ACTIVO',
          scheduleSummary: 'Tránsito libre 07:00 - 21:30',
          fullSchedule:
              'Conexión directa hacia Pisos 1, 2, 3, 4 y 5 de Ingeniería de Sistemas.',
          detailsTitle: 'Conexión Vertical',
          detailsBody:
              'Doble cuerpo de gradas principales con pasamanos hacia las plantas superiores.',
          directionsText:
              'Ingresando por la puerta de entrada, gira a la izquierda siguiendo el hall hasta las gradas.',
          routeWaypoints: [
            MapPoint(0.62, 0.72),
            MapPoint(0.50, 0.72),
          ],
          keywords: ['gradas', 'escaleras', 'subir', 'pisos', 'centrales'],
        ),
        MapLocationItem(
          id: 'pb_ingreso_salida',
          floorCode: 'PB',
          name: 'Puerta de Ingreso y Salida',
          shortLabel: 'Ingreso/Salida',
          category: MapLocationCategory.accesibilidad,
          x: 0.85,
          y: 0.655,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Habilitada 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Acceso Lateral',
          detailsBody:
              'Puerta lateral de flujo rápido para ingreso y evacuación hacia el patio exterior.',
          directionsText:
              'Sobre el costado derecho del hall de ingreso en Planta Baja.',
          routeWaypoints: [
            MapPoint(0.76, 0.655),
          ],
          keywords: ['ingreso', 'salida', 'puerta', 'evacuacion', 'acceso'],
        ),
        MapLocationItem(
          id: 'pb_entrada',
          floorCode: 'PB',
          name: 'Entrada Principal Sur',
          shortLabel: 'Entrada',
          category: MapLocationCategory.accesibilidad,
          x: 0.775,
          y: 0.81,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Puerta principal 07:00 - 21:30',
          fullSchedule: 'Lunes a Sábado: 07:00 - 21:30',
          detailsTitle: 'Acceso Estudiantil',
          detailsBody:
              'Ingreso peatonal principal desde la calle hacia el hall de recepción de Planta Baja.',
          directionsText:
              'En el frontis inferior derecho de la Planta Baja.',
          routeWaypoints: [
            MapPoint(0.775, 0.72),
          ],
          keywords: ['entrada', 'puerta principal', 'inicio', 'ingreso'],
        ),
        MapLocationItem(
          id: 'pb_atencion_oeste',
          floorCode: 'PB',
          name: 'Módulo de Informaciones y Atención',
          shortLabel: 'Informaciones',
          category: MapLocationCategory.tramites,
          x: 0.25,
          y: 0.74,
          statusBadge: 'ABIERTO',
          scheduleSummary: 'Atención de 08:30 a 18:00',
          fullSchedule: 'Lunes a Viernes: 08:30 - 12:30 y 14:00 - 18:00',
          detailsTitle: 'Orientación y Servicios',
          detailsBody:
              'Recepción inicial, orientación a visitantes y consulta rápida en el ala suroeste.',
          directionsText:
              'Cruza el Área de Acceso hacia la izquierda y desciende al ambiente suroeste.',
          routeWaypoints: [
            MapPoint(0.76, 0.56),
            MapPoint(0.31, 0.56),
            MapPoint(0.31, 0.74),
          ],
          keywords: ['informaciones', 'recepcion', 'atencion', 'ventanilla'],
        ),
        MapLocationItem(
          id: 'pb_extintor',
          floorCode: 'PB',
          name: 'Punto de Emergencia y Extintor PB',
          shortLabel: 'Extintor',
          category: MapLocationCategory.extintores,
          x: 0.65,
          y: 0.695,
          statusBadge: 'OPERATIVO',
          scheduleSummary: 'Equipo de emergencia disponible 24/7',
          fullSchedule:
              'Extintor PQS ABC, botiquín y señalética hacia salidas de emergencia.',
          detailsTitle: 'Seguridad',
          detailsBody:
              'Punto de respuesta rápida ubicado entre el vestíbulo de entrada y las gradas centrales.',
          directionsText:
              'A un lado del pilar de ingreso entre el pasillo celeste y el hall central.',
          routeWaypoints: [
            MapPoint(0.65, 0.72),
          ],
          keywords: ['fuego', 'incendio', 'botiquin', 'salida', 'estintor', 'extintor'],
        ),
      ],
    ),
  ];

  /// Devuelve el piso correspondiente por código (`P5`..`PB`).
  static MapFloorModel getFloorByCode(String code) {
    return floors.firstWhere(
      (f) => f.code == code,
      orElse: () => floors[1], // P4 por defecto
    );
  }
}
