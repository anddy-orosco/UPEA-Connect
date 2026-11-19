import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/noticia_model.dart';
import '../../theme/colors.dart';

class NoticiaDetalleScreen extends StatefulWidget {
  final Noticia noticia;

  const NoticiaDetalleScreen({
    super.key,
    required this.noticia,
  });

  @override
  State<NoticiaDetalleScreen> createState() => _NoticiaDetalleScreenState();
}

class _NoticiaDetalleScreenState extends State<NoticiaDetalleScreen> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _abrirVisorPantallaCompleta(int initialIndex) {
    if (widget.noticia.imagenes.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VisorImagenesZoomScreen(
          imagenes: widget.noticia.imagenes,
          initialIndex: initialIndex,
          titulo: widget.noticia.titulo,
        ),
      ),
    );
  }

  void _compartirNoticia() {
    final n = widget.noticia;
    final text =
        '📢 *${n.titulo}*\n'
        '📌 _Categoría: ${n.categoria}_\n\n'
        '${n.resumen}\n\n'
        '${n.contenido}\n\n'
        'Compartido desde *UPEA Connect* 🚀';
    Share.share(text);
  }

  Color _obtenerColorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'examen':
        return Colors.red.shade700;
      case 'convocatoria':
        return Colors.purple.shade700;
      case 'evento':
        return Colors.teal.shade700;
      case 'comunicado':
      default:
        return AppColors.azulPrincipal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.noticia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat("d 'de' MMMM, yyyy • HH:mm", 'es_ES');
    final fechaStr = dateFormat.format(n.createdAt);
    final categoriaColor = _obtenerColorCategoria(n.categoria);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          n.categoria.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir comunicado',
            onPressed: _compartirNoticia,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // SECCIÓN DE FOTOS / CARRUSEL DE IMÁGENES
            // =================================================================
            if (n.imagenes.isNotEmpty)
              _buildCarruselImagenes(n.imagenes)
            else
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoriaColor.withValues(alpha: 0.85),
                      categoriaColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _obtenerIconoCategoria(n.categoria),
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),

            // =================================================================
            // DETALLE DEL COMUNICADO
            // =================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadatos: Categoría, Destacada y Fecha
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoriaColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: categoriaColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          n.categoria.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: categoriaColor,
                          ),
                        ),
                      ),
                      if (n.destacada) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 13, color: Colors.amber.shade900),
                              const SizedBox(width: 3),
                              Text(
                                'DESTACADA',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fechaStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Título principal de la noticia
                  Text(
                    n.titulo,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Resumen destacado
                  if (n.resumen.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: categoriaColor,
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Text(
                        n.resumen,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),

                  // Contenido largo de la noticia
                  SelectableText(
                    n.contenido,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.65,
                      color: colorScheme.onSurface.withValues(alpha: 0.90),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Pie de página institucional
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2530)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/escudo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school_rounded,
                                color: AppColors.azulPrincipal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ingeniería de Sistemas • UPEA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dirección de Carrera y Consejo Académico',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarruselImagenes(List<String> imagenes) {
    final total = imagenes.length;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 290,
          child: PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              final url = imagenes[index];
              return GestureDetector(
                onTap: () => _abrirVisorPantallaCompleta(index),
                child: Hero(
                  tag: 'noticia_img_${widget.noticia.id}_$index',
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, _, __) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Barra inferior del carrusel: contador y botón de zoom
        Positioned(
          bottom: 12,
          left: 14,
          right: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicador de imagen (ej. "Foto 1 de 4")
              if (total > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Botón de ampliar
              GestureDetector(
                onTap: () => _abrirVisorPantallaCompleta(_currentImageIndex),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.zoom_in_rounded,
                          size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Ampliar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'examen':
        return Icons.quiz_rounded;
      case 'convocatoria':
        return Icons.campaign_rounded;
      case 'evento':
        return Icons.event_available_rounded;
      case 'comunicado':
      default:
        return Icons.article_rounded;
    }
  }
}

// =============================================================================
// VISOR DE IMÁGENES A PANTALLA COMPLETA CON ZOOM (InteractiveViewer)
// =============================================================================
class _VisorImagenesZoomScreen extends StatefulWidget {
  final List<String> imagenes;
  final int initialIndex;
  final String titulo;

  const _VisorImagenesZoomScreen({
    required this.imagenes,
    required this.initialIndex,
    required this.titulo,
  });

  @override
  State<_VisorImagenesZoomScreen> createState() =>
      _VisorImagenesZoomScreenState();
}

class _VisorImagenesZoomScreenState extends State<_VisorImagenesZoomScreen> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imagenes.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (total > 1)
              Text(
                'Imagen ${_currentIndex + 1} de $total',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              if (_currentIndex < widget.imagenes.length) {
                Share.share(widget.imagenes[_currentIndex]);
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: total,
        onPageChanged: (idx) {
          setState(() => _currentIndex = idx);
        },
        itemBuilder: (context, index) {
          final url = widget.imagenes[index];
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.5,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
