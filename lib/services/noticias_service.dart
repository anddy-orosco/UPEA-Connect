import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/noticia_model.dart';

class NoticiasService {
  // ===========================================================================
  // CREDENCIALES DE SUPABASE
  // ===========================================================================
  static const String supabaseUrl = 'https://zrdkqnoawkufkrlubppa.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_kuRA6OPsr-U7Xzua9Dw_Cg_ZizuWD9t';

  static const String _cacheKey = 'upea_noticias_cache_v1';
  static const String _destacadasCacheKey = 'upea_noticias_destacadas_cache_v1';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Verifica si las credenciales han sido configuradas
  static bool get isConfigured =>
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('PEGA_AQUI') &&
      !supabaseAnonKey.contains('PEGA_AQUI');

  /// Inicialización segura de Supabase sin bloquear el arranque de la app si está offline
  static Future<void> initializeSupabase() async {
    if (!isConfigured) {
      debugPrint(
          'ℹ️ [NoticiasService] Supabase no tiene credenciales configuradas todavía. Modo offline/local activo.');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey, // ignore: deprecated_member_use
      );
      _initialized = true;
      debugPrint('✅ [NoticiasService] Supabase inicializado correctamente.');
    } catch (e) {
      debugPrint(
          '⚠️ [NoticiasService] No se pudo inicializar Supabase (sin conexión o error de red): $e');
    }
  }

  static SupabaseClient? get _client {
    if (_initialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Obtiene noticias paginadas ordenadas por created_at DESC con filtro por categoría
  static Future<List<Noticia>> fetchNoticias({
    int page = 0,
    int pageSize = 10,
    String? categoria,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isConfigured) {
      final cached = _loadFromCache(prefs);
      return _filterAndSlice(cached, categoria, page, pageSize);
    }

    try {
      // Intentar obtener cliente de Supabase
      var client = _client;
      if (client == null) {
        await initializeSupabase();
        client = _client;
      }

      if (client == null) {
        final cached = _loadFromCache(prefs);
        return _filterAndSlice(cached, categoria, page, pageSize);
      }

      var query = client.from('noticias').select('*');

      if (categoria != null &&
          categoria.isNotEmpty &&
          categoria != 'Todas' &&
          categoria != 'Todos') {
        query = query.eq('categoria', categoria);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final List<dynamic> data = response as List<dynamic>;
      final List<Noticia> remoteNews =
          data.map((item) => Noticia.fromJson(item as Map<String, dynamic>)).toList();

      // Si es la primera página de todas las noticias y trajo datos, actualizar caché local
      if (page == 0 && (categoria == null || categoria == 'Todas' || categoria == 'Todos')) {
        if (remoteNews.isNotEmpty) {
          await _saveToCache(prefs, remoteNews);
        }
      }

      // Si la consulta remota fue exitosa y trajo datos, retornarlos
      if (remoteNews.isNotEmpty || page > 0) {
        return remoteNews;
      }

      // Si la base de datos aún no tiene registros en la página 0, mostrar el contenido de respaldo
      final cached = _loadFromCache(prefs);
      return _filterAndSlice(cached, categoria, page, pageSize);
    } catch (e) {
      debugPrint('⚠️ [NoticiasService] Error al consultar Supabase: $e');
      // Fallback automático a caché local si hay error de red o permisos
      final cached = _loadFromCache(prefs);
      return _filterAndSlice(cached, categoria, page, pageSize);
    }
  }

  /// Obtiene las noticias marcadas como destacadas para el carrusel superior
  static Future<List<Noticia>> fetchNoticiasDestacadas({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isConfigured) {
      final cached = _loadDestacadasFromCache(prefs);
      if (cached.isNotEmpty) return cached;
      return _loadFromCache(prefs).where((n) => n.destacada).toList();
    }

    try {
      var client = _client;
      if (client == null) {
        await initializeSupabase();
        client = _client;
      }

      if (client == null) {
        return _loadFromCache(prefs).where((n) => n.destacada).toList();
      }

      final response = await client
          .from('noticias')
          .select('*')
          .eq('destacada', true)
          .order('created_at', ascending: false)
          .limit(5);

      final List<dynamic> data = response as List<dynamic>;
      final List<Noticia> destacadas =
          data.map((item) => Noticia.fromJson(item as Map<String, dynamic>)).toList();

      if (destacadas.isNotEmpty) {
        await _saveDestacadasToCache(prefs, destacadas);
        return destacadas;
      }

      final cached = _loadDestacadasFromCache(prefs);
      if (cached.isNotEmpty) return cached;
      return _loadFromCache(prefs).where((n) => n.destacada).toList();
    } catch (e) {
      debugPrint('⚠️ [NoticiasService] Error obteniendo noticias destacadas: $e');
      final cached = _loadDestacadasFromCache(prefs);
      if (cached.isNotEmpty) return cached;
      return _loadFromCache(prefs).where((n) => n.destacada).toList();
    }
  }

  // ===========================================================================
  // MÉTODOS DE CACHÉ LOCAL (SharedPreferences)
  // ===========================================================================

  static List<Noticia> _loadFromCache(SharedPreferences prefs) {
    try {
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list
            .map((item) => Noticia.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error leyendo caché de noticias: $e');
    }
    // Si la caché está vacía, retornar las noticias iniciales por defecto de la carrera
    return _getDefaultInitialNews();
  }

  static Future<void> _saveToCache(
      SharedPreferences prefs, List<Noticia> noticias) async {
    try {
      final jsonStr = jsonEncode(noticias.map((n) => n.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
    } catch (e) {
      debugPrint('Error guardando noticias en caché: $e');
    }
  }

  static List<Noticia> _loadDestacadasFromCache(SharedPreferences prefs) {
    try {
      final jsonStr = prefs.getString(_destacadasCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list
            .map((item) => Noticia.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> _saveDestacadasToCache(
      SharedPreferences prefs, List<Noticia> destacadas) async {
    try {
      final jsonStr = jsonEncode(destacadas.map((n) => n.toJson()).toList());
      await prefs.setString(_destacadasCacheKey, jsonStr);
    } catch (_) {}
  }

  static List<Noticia> _filterAndSlice(
    List<Noticia> all,
    String? categoria,
    int page,
    int pageSize,
  ) {
    var filtered = all;
    if (categoria != null &&
        categoria.isNotEmpty &&
        categoria != 'Todas' &&
        categoria != 'Todos') {
      filtered = all
          .where((n) => n.categoria.toLowerCase() == categoria.toLowerCase())
          .toList();
    }

    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
    return filtered.sublist(start, end);
  }

  /// Datos iniciales oficiales de la carrera listos para mostrar antes de sincronizar
  static List<Noticia> _getDefaultInitialNews() {
    return [
      Noticia(
        id: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        titulo: 'Gran Entrada Universitaria 2026: Participación de Ingeniería de Sistemas',
        categoria: 'Evento',
        resumen: 'Estudiantes y docentes de la carrera deslumbraron con la danza de Caporales Troyanos en la entrada oficial.',
        contenido:
            'Con gran fervor, alegría e identidad cultural, la fraternidad de Caporales Troyanos de la Carrera de Ingeniería de Sistemas participó activamente en la Entrada Universitaria UPEA 2026.\n\n'
            'El recorrido inició en la avenida Juan Pablo II y concluyó en el palco oficial ubicado en los predios del Edificio Emblemático.\n\n'
            'Felicitamos a los bloques de varones, cholitas y directiva por el impecable despliegue, entusiasmo y representación institucional de nuestra querida Carrera de Sistemas.',
        imagenes: [
          'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1000&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1000&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1000&auto=format&fit=crop&q=80',
        ],
        destacada: true,
      ),
      Noticia(
        id: 2,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        titulo: 'Convocatoria Oficial a Auxiliares de Docencia e Investigación',
        categoria: 'Convocatoria',
        resumen: 'Concurso de méritos y examen de competencia para auxiliares de docencia en todas las áreas de la carrera.',
        contenido:
            'La Dirección de Carrera de Ingeniería de Sistemas y el Honorable Consejo de Carrera convocan a todos los estudiantes regulares destacados al Concurso de Méritos y Examen de Competencia para Auxiliares de Docencia e Investigación.\n\n'
            '📋 REQUISITOS GENERALES:\n'
            '1. Estar legalmente matriculado en la gestión académica actual.\n'
            '2. Haber aprobado la materia a la que postula con una calificación sobresaliente.\n'
            '3. Presentar récord académico actualizado emitido por Kardex.\n'
            '4. No tener cuentas pendientes ni procesos disciplinarios en la UPEA.\n\n'
            '📁 PRESENTACIÓN DE SOBRES:\n'
            'Ventanillas de Dirección de Carrera (Torre Tecnológica, Piso 3). Horarios: 08:30 a 16:30.',
        imagenes: [
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1000&auto=format&fit=crop&q=80',
        ],
        destacada: true,
      ),
      Noticia(
        id: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        titulo: 'Rol Oficial de Exámenes Finales y Segundos Turnos',
        categoria: 'Examen',
        resumen: 'Cronograma detallado de fechas, aulas y horarios de exámenes finales de 1er a 10mo semestre.',
        contenido:
            'Se comunica a toda la comunidad estudiantil de Ingeniería de Sistemas el Cronograma Oficial de Exámenes Finales y Segundos Turnos.\n\n'
            '⚠️ RECORDATORIO:\n'
            '• Presentarse con carnet universitario y cédula de identidad obligatoria.\n'
            '• Las evaluaciones se llevarán a cabo en las aulas asignadas de la Torre Tecnológica y Edificio Emblemático.\n'
            '• Tolerancia máxima de ingreso: 10 minutos a partir de la hora fijada.',
        imagenes: [
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=1000&auto=format&fit=crop&q=80',
        ],
        destacada: false,
      ),
      Noticia(
        id: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        titulo: 'Feria Científica y Tecnológica de Sistemas, IA y Robótica',
        categoria: 'Evento',
        resumen: 'Exhibición de proyectos de Inteligencia Artificial, desarrollo web, aplicaciones móviles y ciberseguridad.',
        contenido:
            'Invitamos a todos los universitarios a la Gran Feria Tecnológica Anual de Ingeniería de Sistemas.\n\n'
            'Se presentarán más de 60 proyectos innovadores desarrollados por los estudiantes en áreas estratégicas como redes neuronales, automatización IoT, robótica y sistemas distribuidos en la nube.\n\n'
            'Habrá premios para los mejores proyectos y jurados invitados de la industria tech.',
        imagenes: [
          'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1000&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1000&auto=format&fit=crop&q=80',
        ],
        destacada: true,
      ),
      Noticia(
        id: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        titulo: 'Comunicado: Regularización de Boletas y Asignación de Aulas',
        categoria: 'Comunicado',
        resumen: 'Plazo improrrogable para regularización de inscripciones y levantamiento de choques de horarios.',
        contenido:
            'La Dirección de Carrera informa que el periodo extraordinario de regularización de boletas de inscripción y validación de materias concluye esta semana.\n\n'
            'Por favor pasar por ventanillas de Kardex en la Torre Tecnológica respetando los turnos correspondientes.',
        imagenes: [
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1000&auto=format&fit=crop&q=80',
        ],
        destacada: false,
      ),
    ];
  }
}
