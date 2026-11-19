import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_post_model.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsPostModel> _allPosts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _pageMeta = {
    'pageName': 'Carrera Ingenieria de Sistemas - UPEA',
    'followerCountFormatted': '13.6 mil',
    'profilePicURL': '',
    'pageDescription': 'Carrera de Ingeniería de Sistemas • Universidad Pública de El Alto',
  };

  final List<String> _categories = [
    'Todos',
    'Comunicado',
    'Convocatoria',
    'Evento',
    'Académico',
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final posts = await NewsService.getPosts(forceRefresh: forceRefresh);
    final meta = await NewsService.getPageMetadata();
    if (mounted) {
      setState(() {
        _allPosts = posts;
        _pageMeta = meta;
        _isLoading = false;
      });
    }
  }

  List<NewsPostModel> get _filteredPosts {
    return _allPosts.where((post) {
      final matchesCategory = _selectedCategory == 'Todos' ||
          post.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openGalleryViewer(List<String> imageUrls, int initialIndex, String title) {
    if (imageUrls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGalleryViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _fetchNews(forceRefresh: true),
        color: colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Cabecera Oficial de Facebook (Ingeniería de Sistemas - UPEA Futuro)
            SliverToBoxAdapter(
              child: _buildFacebookHeaderBanner(colorScheme, isDark),
            ),

            // Barra de búsqueda y selector de categorías
            SliverToBoxAdapter(
              child: _buildSearchAndFilterSection(colorScheme, isDark),
            ),

            // Lista de publicaciones
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredPosts.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(colorScheme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _filteredPosts[index];
                      return _buildPostCard(post, colorScheme, isDark);
                    },
                    childCount: _filteredPosts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Banner informativo superior de la página de Facebook oficial
  Widget _buildFacebookHeaderBanner(ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1877F2), // Azul Facebook oficial
            Color(0xFF0D47A1), // Azul UPEA profundo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo / Avatar Oficial
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: (_pageMeta['profilePicURL']?.isNotEmpty == true)
                      ? Image.network(
                          _pageMeta['profilePicURL']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/escudo.png',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          'assets/images/escudo.png',
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _pageMeta['pageName'] ?? 'Carrera Ing. de Sistemas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF40C4FF),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '@Ingenieriadesistemasupeafuturo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_pageMeta['followerCountFormatted'] ?? '13 mil'} seguidores • En vivo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _pageMeta['pageDescription'] ??
                'Todos los comunicados, avisos de exámenes, eventos y convocatorias oficiales directamente de la cuenta de Facebook de la Carrera.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Botón para ir a Facebook
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: NewsService.openFacebookPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1877F2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'Visitar Facebook de la Carrera',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Buscador y Filtros
  Widget _buildSearchAndFilterSection(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Campo de búsqueda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: colorScheme.onSurface, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Buscar convocatorias, exámenes, avisos...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filtro horizontal por categoría
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;

              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: isSelected,
                selectedColor: colorScheme.primary,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                onSelected: (_) {
                  setState(() => _selectedCategory = cat);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Tarjeta de Publicación
  Widget _buildPostCard(NewsPostModel post, ColorScheme colorScheme, bool isDark) {
    final dateFormat = DateFormat("d 'de' MMMM, yyyy • HH:mm", 'es_ES');
    final formattedDate = dateFormat.format(post.publishedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2530) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Post (Avatar, Título, Fecha y Pin)
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1877F2).withValues(alpha: 0.15),
                  child: ClipOval(
                    child: (post.authorAvatar?.isNotEmpty == true)
                        ? Image.network(
                            post.authorAvatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/escudo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/images/escudo.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF1877F2),
                            size: 14,
                          ),
                        ],
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de Categoría, FB Live y Pin
                Row(
                  children: [
                    if (post.isLiveFromFacebook)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1877F2).withValues(alpha: 0.30),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.facebook_rounded, size: 11, color: Color(0xFF1877F2)),
                            SizedBox(width: 3),
                            Text(
                              'FB LIVE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1877F2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (post.isPinned)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.push_pin_rounded, size: 12, color: Colors.amber.shade900),
                            const SizedBox(width: 2),
                            Text(
                              'FIJADO',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildCategoryBadge(post.category),
                  ],
                ),
              ],
            ),
          ),

          // Título de la Noticia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text(
              post.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                height: 1.25,
              ),
            ),
          ),

          // Contenido de la Noticia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: _ExpandableText(
              text: post.content,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),

          // Contenido multimedia (Foto individual, Video o Mosaico de Álbum)
          _buildPostMedia(post, colorScheme, isDark),

          const Divider(height: 1),

          // Footer de Interacción (Reacciones, Compartir en WhatsApp, Ver en Facebook)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reacciones y Comentarios
                Row(
                  children: [
                    const Icon(Icons.thumb_up_rounded, size: 14, color: Color(0xFF1877F2)),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    if (post.commentsCount > 0) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.50),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    if (post.sharesCount > 0) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.reply_rounded,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.50),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${post.sharesCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),

                Row(
                  children: [
                    // Botón Compartir
                    TextButton.icon(
                      onPressed: () {
                        Share.share(
                          '${post.title}\n\n${post.content}\n\n🔗 Ver publicación oficial en Facebook: ${post.facebookUrl}\n\nCompartido desde UPEA Connect 🚀',
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Compartir', style: TextStyle(fontSize: 12)),
                    ),

                    const SizedBox(width: 4),

                    // Botón Ver en Facebook
                    ElevatedButton.icon(
                      onPressed: () => NewsService.openPostUrl(post.facebookUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.facebook_rounded, size: 16),
                      label: const Text(
                        'Ver Post',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(
      NewsPostModel post, ColorScheme colorScheme, bool isDark) {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    final images = post.imageUrls;

    // Caso 1: 1 sola imagen o video
    if (images.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: GestureDetector(
          onTap: () => _openGalleryViewer(images, 0, post.title),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildNetworkImage(images.first, isDark),
                ),
                if (post.attachmentType == 'video')
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.60),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                _buildZoomPill(
                    post.attachmentType == 'video' ? 'Video FB' : 'Ampliar'),
              ],
            ),
          ),
        ),
      );
    }

    // Caso 2: 2 imágenes
    if (images.length == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 190,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGalleryViewer(images, 0, post.title),
                    child: _buildNetworkImage(images[0], isDark),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGalleryViewer(images, 1, post.title),
                    child: _buildNetworkImage(images[1], isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Caso 3: 3 imágenes
    if (images.length == 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _openGalleryViewer(images, 0, post.title),
                    child: _buildNetworkImage(images[0], isDark),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _openGalleryViewer(images, 1, post.title),
                          child: _buildNetworkImage(images[1], isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _openGalleryViewer(images, 2, post.title),
                          child: _buildNetworkImage(images[2], isDark),
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
    }

    // Caso 4: 4 o más imágenes (ÁLBUM MOSAICO ESTILO FACEBOOK CON +N FOTOS)
    final totalCount = post.albumPhotoCount ?? images.length;
    final extraCount = totalCount > 4 ? totalCount - 4 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 270,
          child: Row(
            children: [
              // Columna Izquierda (Foto 1 y Foto 2)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openGalleryViewer(images, 0, post.title),
                        child: _buildNetworkImage(images[0], isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openGalleryViewer(images, 1, post.title),
                        child: _buildNetworkImage(images[1], isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Columna Derecha (Foto 3 y Foto 4 con Badge +N)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openGalleryViewer(images, 2, post.title),
                        child: _buildNetworkImage(images[2], isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openGalleryViewer(images, 3, post.title),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildNetworkImage(images[3], isDark),
                            if (extraCount > 0)
                              Container(
                                color: Colors.black.withValues(alpha: 0.58),
                                alignment: Alignment.center,
                                child: Text(
                                  '+$extraCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url, bool isDark) {
    return SizedBox.expand(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: isDark ? Colors.white10 : Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: isDark ? Colors.white10 : Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                size: 36, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomPill(String label) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color bg;
    Color text;

    switch (category.toLowerCase()) {
      case 'convocatoria':
        bg = Colors.purple.shade50;
        text = Colors.purple.shade800;
        break;
      case 'evento':
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        break;
      case 'académico':
      case 'academico':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        break;
      case 'comunicado':
      default:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: text,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron publicaciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otra palabra clave o categoría.',
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

// Widget auxiliar para expandir o contraer texto largo de noticias
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ExpandableText({
    required this.text,
    required this.style,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > 220;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : 4,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _isExpanded ? 'Ver menos' : '... Ver comunicado completo',
                style: const TextStyle(
                  color: Color(0xFF1877F2),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Visor interactivo de galería de pantalla completa con zoom y swipe para álbumes
class _FullScreenGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  const _FullScreenGalleryViewer({
    required this.imageUrls,
    this.initialIndex = 0,
    required this.title,
  });

  @override
  State<_FullScreenGalleryViewer> createState() =>
      _FullScreenGalleryViewerState();
}

class _FullScreenGalleryViewerState extends State<_FullScreenGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (images.length > 1)
              Text(
                'Foto ${_currentIndex + 1} de ${images.length}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              if (_currentIndex < images.length) {
                Share.share(images[_currentIndex]);
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 60,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
