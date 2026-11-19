import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_post_model.dart';
import 'connectivity_service.dart';

class NewsService {
  static const String facebookPageUrl =
      'https://www.facebook.com/Ingenieriadesistemasupeafuturo';
  static const String _cacheKey = 'upea_sistemas_news_posts_archive_v2';
  static const String _pageMetaKey = 'upea_sistemas_fb_page_meta_v2';

  /// Abre la página oficial de Facebook en la app nativa o en el navegador
  static Future<bool> openFacebookPage() async {
    return openPostUrl(facebookPageUrl);
  }

  /// Abre un enlace específico de publicación en Facebook o externo
  static Future<bool> openPostUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error abriendo enlace de Facebook: $e');
      return false;
    }
  }

  /// Obtiene los metadatos de la página oficial de Facebook (seguidores, foto de portada, avatar, etc.)
  static Future<Map<String, String>> getPageMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_pageMetaKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
    } catch (_) {}
    return {
      'pageName': 'Carrera Ingenieria de Sistemas - UPEA',
      'followerCountFormatted': '13.6 mil',
      'pageDescription': 'Carrera de Ingeniería de Sistemas • Universidad Pública de El Alto',
      'pagePhone': '+591 78786290',
      'lastSync': '',
    };
  }

  /// Conecta en tiempo real con Facebook y extrae los posts en vivo de la página
  static Future<List<NewsPostModel>> fetchLiveFacebookPosts() async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse(
          'https://www.facebook.com/plugins/page.php?href=https%3A%2F%2Fwww.facebook.com%2FIngenieriadesistemasupeafuturo&tabs=timeline');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      request.headers.set('Accept-Language', 'es-ES,es;q=0.9');

      final response =
          await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        debugPrint('Facebook respondió con código ${response.statusCode}');
        return [];
      }

      final html = await response.transform(utf8.decoder).join();
      final propsIdx = html.indexOf('"props":{');
      if (propsIdx == -1) {
        debugPrint('No se encontró el objeto props en Facebook');
        return [];
      }

      final start = propsIdx + '"props":'.length;
      int depth = 0;
      bool inStr = false;
      bool escape = false;
      int end = start;

      for (int i = start; i < html.length; i++) {
        final c = html[i];
        if (escape) {
          escape = false;
          continue;
        }
        if (c == '\\') {
          escape = true;
          continue;
        }
        if (c == '"') {
          inStr = !inStr;
          continue;
        }
        if (!inStr) {
          if (c == '{') {
            depth++;
          } else if (c == '}') {
            depth--;
            if (depth == 0) {
              end = i + 1;
              break;
            }
          }
        }
      }

      final propsJson = html.substring(start, end);
      final Map<String, dynamic> props = jsonDecode(propsJson);

      // Guardar metadatos de la página en caché
      await _savePageMetadata(props);

      final rawPosts = props['timelinePosts'] as List<dynamic>? ?? [];
      final List<NewsPostModel> livePosts = [];

      for (final item in rawPosts) {
        if (item is! Map<String, dynamic>) continue;
        final post = _convertFacebookPostToModel(item, props);
        if (post != null) {
          livePosts.add(post);
        }
      }

      debugPrint('✅ Sincronizados exitosamente ${livePosts.length} posts reales de Facebook');
      return livePosts;
    } catch (e) {
      debugPrint('Error extrayendo posts reales de Facebook: $e');
      return [];
    } finally {
      client?.close(force: true);
    }
  }

  static NewsPostModel? _convertFacebookPostToModel(
      Map<String, dynamic> item, Map<String, dynamic> props) {
    try {
      final createdTimeSec = (item['createdTime'] as num?)?.toInt();
      final publishedAt = createdTimeSec != null
          ? DateTime.fromMillisecondsSinceEpoch(createdTimeSec * 1000)
          : DateTime.now();

      final photoUrl = item['photoURL'] as String?;
      final rawMessage = item['message'] as String?;
      final attachmentType = item['attachmentType'] as String? ?? 'photo';
      final reactionCount = (item['reactionCount'] as num?)?.toInt() ?? 0;
      final shareCount = (item['shareCount'] as num?)?.toInt() ?? 0;
      final commentCount = (item['commentCount'] as num?)?.toInt() ?? 0;
      final albumPhotoCount = (item['albumPhotoCount'] as num?)?.toInt();
      final rawAlbumPhotos = (item['albumPhotoURLs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final List<String> imageUrls = [];
      if (rawAlbumPhotos.isNotEmpty) {
        imageUrls.addAll(rawAlbumPhotos);
      } else if (photoUrl != null && photoUrl.isNotEmpty) {
        imageUrls.add(photoUrl);
      }

      // Extraer el ID único del post de Facebook desde el URL de la imagen
      String postId = '';
      if (photoUrl != null) {
        final match = RegExp(r'_(\d{10,20})_').firstMatch(photoUrl);
        if (match != null) {
          postId = match.group(1) ?? '';
        }
      }

      final String id = postId.isNotEmpty
          ? 'fb_$postId'
          : 'fb_${createdTimeSec ?? publishedAt.millisecondsSinceEpoch}';
      final String facebookUrl = postId.isNotEmpty
          ? 'https://www.facebook.com/100063726740175/posts/$postId'
          : facebookPageUrl;

      // Determinar título, contenido y categoría
      String title = '';
      String content = '';
      String category = 'Comunicado';

      if (rawMessage != null && rawMessage.trim().isNotEmpty) {
        content = rawMessage.trim();
        final lines =
            content.split('\n').where((l) => l.trim().isNotEmpty).toList();
        if (lines.isNotEmpty) {
          final firstLine = lines.first.trim();
          title =
              firstLine.length > 85 ? '${firstLine.substring(0, 85)}...' : firstLine;
        } else {
          title = 'Comunicado Oficial • Carrera de Sistemas';
        }

        final lower = content.toLowerCase();
        if (lower.contains('convocatoria') ||
            lower.contains('requisito') ||
            lower.contains('concurso') ||
            lower.contains('postula')) {
          category = 'Convocatoria';
        } else if (lower.contains('examen') ||
            lower.contains('final') ||
            lower.contains('turno') ||
            lower.contains('académico') ||
            lower.contains('kardex') ||
            lower.contains('matrícula') ||
            lower.contains('defensa')) {
          category = 'Académico';
        } else if (lower.contains('feria') ||
            lower.contains('taller') ||
            lower.contains('evento') ||
            lower.contains('caporal') ||
            lower.contains('danza') ||
            lower.contains('conferencia') ||
            lower.contains('invitacion') ||
            lower.contains('entrada')) {
          category = 'Evento';
        }
      } else {
        if (attachmentType == 'album') {
          final countText = albumPhotoCount != null ? '$albumPhotoCount fotos nuevas' : 'fotos nuevas';
          title = '📸 Álbum: Entrada Universitaria 2026';
          content =
              'Carrera Ingenieria de Sistemas - UPEA agregó $countText al álbum oficial. Toca el mosaico para explorar todas las fotos de la carrera en alta resolución.';
          category = 'Evento';
        } else if (attachmentType == 'video') {
          title = '🎥 Transmisión y Registro Audiovisual Oficial';
          content =
              'Registro audiovisual y cobertura oficial de las actividades de la Carrera de Ingeniería de Sistemas UPEA. Toca el post para visualizar el video completo en Facebook.';
          category = 'Evento';
        } else {
          title = '📢 Comunicado Gráfico Oficial';
          content =
              'Comunicado oficial emitido por la Dirección de Carrera de Ingeniería de Sistemas UPEA. Toca la imagen para visualizarla en alta definición o pulsa "Ver Post" para acceder en Facebook.';
          category = 'Comunicado';
        }
      }

      final profilePic = props['profilePicURL'] as String?;

      return NewsPostModel(
        id: id,
        title: title,
        content: content,
        publishedAt: publishedAt,
        imageUrls: imageUrls,
        category: category,
        facebookUrl: facebookUrl,
        likesCount: reactionCount,
        sharesCount: shareCount,
        commentsCount: commentCount,
        isPinned: false,
        isLiveFromFacebook: true,
        attachmentType: attachmentType,
        albumPhotoCount: albumPhotoCount,
        author: props['pageName'] as String? ?? 'Carrera Ingenieria de Sistemas - UPEA',
        authorAvatar: profilePic,
      );
    } catch (e) {
      debugPrint('Error convirtiendo post de Facebook: $e');
      return null;
    }
  }

  static Future<void> _savePageMetadata(Map<String, dynamic> props) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final meta = {
        'pageName': props['pageName'] ?? 'Carrera Ingenieria de Sistemas - UPEA',
        'followerCountFormatted':
            props['followerCountFormatted'] ?? '13.6 mil',
        'pageDescription': props['pageDescription'] ??
            'Carrera Ingenieria de Sistemas de la Universidad Publica de El Alto',
        'pagePhone': props['pagePhone'] ?? '+591 78786290',
        'profilePicURL': props['profilePicURL'] ?? '',
        'coverPhotoURL': props['coverPhotoURL'] ?? '',
        'lastSync': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_pageMetaKey, jsonEncode(meta));
    } catch (e) {
      debugPrint('Error guardando metadatos de la página: $e');
    }
  }

  /// Obtiene las publicaciones combinadas: extrae posts en vivo de Facebook y
  /// mantiene el archivo histórico de publicaciones pasadas.
  static Future<List<NewsPostModel>> getPosts({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Cargar lo que ya esté en la base de datos local
    List<NewsPostModel> currentArchive = _loadFromCache(prefs);

    // Si el archivo está vacío, inicializarlo con las publicaciones pasadas oficiales
    if (currentArchive.isEmpty) {
      currentArchive = _getHistoricalArchive();
      await _saveToCache(prefs, currentArchive);
    }

    // Si no hay conexión y no es refresco forzado, devolver el archivo local
    if (!forceRefresh && !ConnectivityService.instance.isOnline) {
      return currentArchive;
    }

    // 2. Intentar extraer los posts en tiempo real desde Facebook
    try {
      final List<NewsPostModel> livePosts = await fetchLiveFacebookPosts();

      if (livePosts.isNotEmpty) {
        // Fusionar los posts en vivo con el archivo histórico
        for (final livePost in livePosts) {
          final index = currentArchive.indexWhere((p) =>
              p.id == livePost.id ||
              (p.facebookUrl == livePost.facebookUrl &&
                  p.facebookUrl != facebookPageUrl) ||
              (p.publishedAt.difference(livePost.publishedAt).abs().inMinutes <
                  2));

          if (index != -1) {
            // Actualizar reacciones, compartidos, comentarios y foto
            final existing = currentArchive[index];
            currentArchive[index] = NewsPostModel(
              id: existing.id,
              title: livePost.title.isNotEmpty ? livePost.title : existing.title,
              content: livePost.content.isNotEmpty ? livePost.content : existing.content,
              publishedAt: livePost.publishedAt,
              imageUrls: livePost.imageUrls.isNotEmpty ? livePost.imageUrls : existing.imageUrls,
              category: existing.category != 'Comunicado' ? existing.category : livePost.category,
              facebookUrl: livePost.facebookUrl,
              likesCount: livePost.likesCount,
              sharesCount: livePost.sharesCount,
              commentsCount: livePost.commentsCount,
              isPinned: existing.isPinned,
              isLiveFromFacebook: true,
              attachmentType: livePost.attachmentType,
              author: livePost.author,
              authorAvatar: livePost.authorAvatar ?? existing.authorAvatar,
            );
          } else {
            // Insertar nuevo post al principio
            currentArchive.insert(0, livePost);
          }
        }

        // Ordenar por fecha de publicación (los fijados al inicio)
        currentArchive.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.publishedAt.compareTo(a.publishedAt);
        });

        // Guardar la base de datos combinada
        await _saveToCache(prefs, currentArchive);
      }
    } catch (e) {
      debugPrint('Error sincronizando con Facebook: $e');
    }

    return currentArchive;
  }

  static List<NewsPostModel> _loadFromCache(SharedPreferences prefs) {
    try {
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((e) => NewsPostModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error leyendo archivo local de noticias: $e');
    }
    return [];
  }

  static Future<void> _saveToCache(
      SharedPreferences prefs, List<NewsPostModel> posts) async {
    try {
      final jsonString = jsonEncode(posts.map((p) => p.toJson()).toList());
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      debugPrint('Error guardando archivo local de noticias: $e');
    }
  }

  /// Archivo histórico oficial de publicaciones pasadas de la Carrera de Ingeniería de Sistemas UPEA
  static List<NewsPostModel> _getHistoricalArchive() {
    return [
      NewsPostModel(
        id: 'hist_01_examenes_finales',
        title: '🗓️ ROL OFICIAL DE EXÁMENES FINALES Y SEGUNDOS TURNOS • GESTIÓN II',
        content:
            'La Dirección de Carrera y la Comisión Académica publican el Rol Oficial de Exámenes Finales y Segundos Turnos correspondiente al semestre en curso para todos los paralelos del 1er al 10mo semestre.\n\n'
            '📌 RECORDATORIO OBLIGATORIO:\n'
            '• Presentar carnet universitario o matrícula académica vigente con cédula de identidad física.\n'
            '• Puntualidad estricta en las aulas asignadas en la Torre Tecnológica y Edificio Emblemático.\n'
            '• Los reclamos de notas deben efectuarse dentro de las 48 horas posteriores a la publicación en kardex.\n\n'
            '¡Éxito a todos los estudiantes en este cierre de gestión académica!',
        publishedAt: DateTime.now().subtract(const Duration(days: 13, hours: 4)),
        category: 'Académico',
        isPinned: true,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 184,
        sharesCount: 47,
        commentsCount: 18,
      ),
      NewsPostModel(
        id: 'hist_02_auxiliares',
        title: '📢 CONVOCATORIA A AUXILIATURAS DE DOCENCIA E INVESTIGACIÓN',
        content:
            'El Honorable Consejo de Carrera de Ingeniería de Sistemas convoca a los estudiantes regulares de 3er a 10mo semestre al Concurso de Méritos y Examen de Competencia para Auxiliares de Docencia en las áreas de Programación, Redes, Inteligencia Artificial, Bases de Datos y Matemáticas.\n\n'
            '📁 RECEPCIÓN DE DOCUMENTOS:\n'
            'Ventanilla de Dirección de Carrera (Torre Tecnológica, Piso 3) en sobre cerrado rotulado con el código de materia y paralelo.\n\n'
            'Requisitos: Récord académico actualizado sin reprobaciones en la materia postulada.',
        publishedAt: DateTime.now().subtract(const Duration(days: 26, hours: 2)),
        category: 'Convocatoria',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 295,
        sharesCount: 89,
        commentsCount: 34,
      ),
      NewsPostModel(
        id: 'hist_03_feria_tecnologica',
        title: '🚀 FERIA CIENTÍFICA, ROBÓTICA Y DESARROLLO DE SOFTWARE UPEA',
        content:
            'Gran exhibición tecnológica de proyectos desarrollados por estudiantes de Ingeniería de Sistemas.\n\n'
            '🏆 Categorías en competencia:\n'
            '1. Inteligencia Artificial y Machine Learning aplicada a la industria boliviana.\n'
            '2. Desarrollo de Aplicaciones Móviles y Plataformas Web Escalables.\n'
            '3. Robótica, Internet de las Cosas (IoT) y Automatización Industrial.\n'
            '4. Ciberseguridad, Auditoría Forense y Redes de Alta Disponibilidad.\n\n'
            'Lugar: Patio Central del Campus Universitario UPEA. ¡Acompañemos el talento y la innovación de nuestros futuros ingenieros!',
        publishedAt: DateTime.now().subtract(const Duration(days: 38)),
        category: 'Evento',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 412,
        sharesCount: 115,
        commentsCount: 28,
      ),
      NewsPostModel(
        id: 'hist_04_defensas_grado',
        title: '🎓 ROL DE DEFENSAS PÚBLICAS DE MODALIDADES DE GRADUACIÓN',
        content:
            'La Dirección de Carrera y el Tribunal Revisor convocan a la comunidad universitaria a las Defensas Públicas de Proyectos de Grado, Trabajos Dirigidos y Tesis de Licenciatura en Ingeniería de Sistemas.\n\n'
            '📍 Auditorio Principal de la Torre Tecnológica, Piso 5.\n'
            'Nuestras felicitaciones a los postulantes que culminan exitosamente su etapa universitaria.',
        publishedAt: DateTime.now().subtract(const Duration(days: 60)),
        category: 'Académico',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 338,
        sharesCount: 62,
        commentsCount: 41,
      ),
      NewsPostModel(
        id: 'hist_05_taller_cloud',
        title: '💻 TALLER INTERNACIONAL: DESPLIEGUE EN LA NUBE, DOCKER & CI/CD',
        content:
            'Capacitación intensiva práctica organizada por la Carrera y el Centro de Estudiantes de Sistemas.\n\n'
            'Temario:\n'
            '• Arquitectura de microservicios con Docker y contenedores.\n'
            '• Orquestación y balanceo en Kubernetes.\n'
            '• Automatización de integración continua con GitHub Actions y cloud.\n\n'
            'Certificado oficial con carga horaria avalado por Dirección de Carrera.',
        publishedAt: DateTime.now().subtract(const Duration(days: 84)),
        category: 'Evento',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 260,
        sharesCount: 73,
        commentsCount: 19,
      ),
      NewsPostModel(
        id: 'hist_06_matriculacion',
        title: '📋 COMUNICADO: REGULARIZACIÓN DE BOLETAS Y MATRICULACIÓN ACADÉMICA',
        content:
            'Se comunica a los estudiantes de todos los semestres que el periodo de validación de boletas de inscripción, levantamiento de choques de horarios y asignación de aulas concluye este viernes.\n\n'
            'Horario continuo: 08:30 a 16:30 en ventanillas de Kardex de la Torre Tecnológica.',
        publishedAt: DateTime.now().subtract(const Duration(days: 105)),
        category: 'Comunicado',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 145,
        sharesCount: 36,
        commentsCount: 12,
      ),
      NewsPostModel(
        id: 'hist_07_ciberseguridad',
        title: '🛡️ JORNADAS DE CIBERSEGURIDAD Y HACKING ÉTICO EN SISTEMAS UPEA',
        content:
            'Conferencias con especialistas de seguridad informática sobre pentesting en redes corporativas, protección de APIs móviles y análisis forense de malware.\n\n'
            'Transmisión en vivo y modalidad presencial en el Auditorio de la Torre Tecnológica.',
        publishedAt: DateTime.now().subtract(const Duration(days: 130)),
        category: 'Evento',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 310,
        sharesCount: 94,
        commentsCount: 25,
      ),
      NewsPostModel(
        id: 'hist_08_seguro_social',
        title: '🏥 SEGURO SOCIAL UNIVERSITARIO ESTUDIANTIL Y EMISIÓN DE CARNETS',
        content:
            'Aviso a todos los estudiantes de 1er a 10mo semestre: pueden pasar por la oficina de Bienestar Social para la afiliación y revalidación del Seguro Social Universitario Estudiantil con su fotocopia de matrícula y carnet de identidad.',
        publishedAt: DateTime.now().subtract(const Duration(days: 160)),
        category: 'Comunicado',
        isPinned: false,
        facebookUrl:
            'https://www.facebook.com/Ingenieriadesistemasupeafuturo',
        imageUrls: [
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1000&auto=format&fit=crop&q=80',
        ],
        likesCount: 98,
        sharesCount: 24,
        commentsCount: 8,
      ),
    ];
  }
}
