import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/noticia_model.dart';
import '../../services/noticias_service.dart';
import '../../theme/colors.dart';
import 'noticia_detalle_screen.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Noticia> _noticias = [];
  List<Noticia> _destacadas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  String _selectedCategoria = 'Todas';
  final List<String> _categorias = [
    'Todas',
    'Examen',
    'Convocatoria',
    'Evento',
    'Comunicado',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        !_isLoading &&
        _hasMore) {
      _cargarMasNoticias();
    }
  }

  Future<void> _cargarDatosIniciales({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final futures = await Future.wait([
        NoticiasService.fetchNoticias(
          page: 0,
          pageSize: _pageSize,
          categoria: _selectedCategoria,
          forceRefresh: forceRefresh,
        ),
        NoticiasService.fetchNoticiasDestacadas(forceRefresh: forceRefresh),
      ]);

      if (mounted) {
        final nuevasNoticias = futures[0];
        final destacadas = futures[1];

        setState(() {
          _noticias = nuevasNoticias;
          _destacadas = destacadas;
          _isLoading = false;
          _hasMore = nuevasNoticias.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cargarMasNoticias() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;

    try {
      final masNoticias = await NoticiasService.fetchNoticias(
        page: nextPage,
        pageSize: _pageSize,
        categoria: _selectedCategoria,
      );

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _noticias.addAll(masNoticias);
          _isLoadingMore = false;
          _hasMore = masNoticias.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _cambiarCategoria(String categoria) {
    if (_selectedCategoria == categoria) return;
    setState(() {
      _selectedCategoria = categoria;
    });
    _cargarDatosIniciales();
  }

  void _abrirDetalle(Noticia noticia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoticiaDetalleScreen(noticia: noticia),
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _cargarDatosIniciales(forceRefresh: true),
        color: colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // =================================================================
            // BARRA DE FILTROS POR CATEGORÍA
            // =================================================================
            SliverToBoxAdapter(
              child: _buildSelectorCategorias(colorScheme, isDark),
            ),

            // =================================================================
            // CARRUSEL DE NOTICIAS DESTACADAS
            // =================================================================
            if (_destacadas.isNotEmpty && (_selectedCategoria == 'Todas')) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'DESTACADOS DE LA CARRERA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildCarruselDestacadas(colorScheme, isDark),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],

            // =================================================================
            // TÍTULO DEL FEED PRINCIPAL
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoria == 'Todas'
                          ? 'ÚLTIMOS COMUNICADOS'
                          : 'COMUNICADOS: ${_selectedCategoria.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    if (!NoticiasService.isConfigured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MODO LOCAL / CACHÉ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // =================================================================
            // LISTADO DE NOTICIAS
            // =================================================================
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_noticias.isEmpty)
              SliverFillRemaining(
                child: _buildEstadoVacio(colorScheme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final noticia = _noticias[index];
                      return _buildTarjetaNoticia(noticia, colorScheme, isDark);
                    },
                    childCount: _noticias.length,
                  ),
                ),
              ),

            // Indicador de carga inferior para paginación
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECTOR HORIZONTAL DE CATEGORÍAS
  // ===========================================================================
  Widget _buildSelectorCategorias(ColorScheme colorScheme, bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categorias[index];
          final isSelected = _selectedCategoria == cat;
          final colorCat = _obtenerColorCategoria(cat);

          return FilterChip(
            selected: isSelected,
            label: Text(cat),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1E2530)
                : Colors.white,
            selectedColor: colorCat,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? colorCat
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            onSelected: (_) => _cambiarCategoria(cat),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // CARRUSEL HORIZONTAL DE NOTICIAS DESTACADAS
  // ===========================================================================
  Widget _buildCarruselDestacadas(ColorScheme colorScheme, bool isDark) {
    final dateFormat = DateFormat("d 'de' MMMM", 'es_ES');

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _destacadas.length,
        itemBuilder: (context, index) {
          final noticia = _destacadas[index];
          final tieneImagen = noticia.imagenes.isNotEmpty;
          final catColor = _obtenerColorCategoria(noticia.categoria);

          return GestureDetector(
            onTap: () => _abrirDetalle(noticia),
            child: Container(
              width: 290,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fondo: Imagen con CachedNetworkImage
                    if (tieneImagen)
                      CachedNetworkImage(
                        imageUrl: noticia.imagenes.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade400,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: catColor.withValues(alpha: 0.8),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [catColor, catColor.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                    // Gradiente oscuro superpuesto para garantizar legibilidad del texto
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Contenido textual sobre la tarjeta destacada
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  noticia.categoria.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 11, color: Colors.black),
                                    SizedBox(width: 2),
                                    Text(
                                      'DESTACADO',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            noticia.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(noticia.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TARJETA DE NOTICIA DEL FEED
  // ===========================================================================
  Widget _buildTarjetaNoticia(
    Noticia noticia,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final dateFormat = DateFormat("d 'de' MMMM, yyyy", 'es_ES');
    final fechaStr = dateFormat.format(noticia.createdAt);
    final catColor = _obtenerColorCategoria(noticia.categoria);
    final tieneImagen = noticia.imagenes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2530) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirDetalle(noticia),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen superior (si tiene)
              if (tieneImagen)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 155,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: noticia.imagenes.first,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => Container(
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  size: 36, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      // Badge indicador de múltiples fotos si tiene más de 1
                      if (noticia.imagenes.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${noticia.imagenes.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
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

              // Contenido de la tarjeta
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de categoría y Fecha
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            noticia.categoria.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: catColor,
                            ),
                          ),
                        ),
                        if (noticia.destacada) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '★ DESTACADA',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          fechaStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Título
                    Text(
                      noticia.titulo,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Resumen (2 líneas)
                    if (noticia.resumen.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        noticia.resumen,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Botón "Leer comunicado completo"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Leer comunicado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Text(
              'No hay noticias en esta categoría',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba seleccionando "Todas" o desliza hacia abajo para refrescar.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
