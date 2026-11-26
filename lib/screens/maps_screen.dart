import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/map_data.dart';
import '../models/map_location_model.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class BuildingMapScreen extends StatefulWidget {
  const BuildingMapScreen({super.key});

  @override
  State<BuildingMapScreen> createState() => _BuildingMapScreenState();
}

class _BuildingMapScreenState extends State<BuildingMapScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFloorIndex = 1; // Por defecto Piso 4 (referencia principal)
  MapLocationItem? _selectedLocation;
  MapLocationCategory? _selectedCategory;
  bool _showRoute = true;
  bool _isSheetExpanded = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  late final TransformationController _transformationController;
  late final AnimationController _routeAnimController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Seleccionar Kardex Académico del Piso 4 por defecto para mostrar la ficha activa
    final initialFloor = MapData.floors[_selectedFloorIndex];
    if (initialFloor.locations.isNotEmpty) {
      _selectedLocation = initialFloor.locations.first;
    }
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _transformationController.dispose();
    _routeAnimController.dispose();
    super.dispose();
  }

  MapFloorModel get _currentFloor => MapData.floors[_selectedFloorIndex];

  /// Color de acento coherente con los 4 temas de UPEA Connect.
  Color _resolveAccentColor(BuildContext context) {
    final variant = Provider.of<ThemeService>(context, listen: false).variant;
    final colorScheme = Theme.of(context).colorScheme;
    switch (variant) {
      case AppThemeVariant.oscuro:
        return const Color(0xFF2563EB); // Azul vivo legible sobre fondo negro
      case AppThemeVariant.predeterminado:
      case AppThemeVariant.rosado:
      case AppThemeVariant.upea:
        return colorScheme.primary;
    }
  }

  List<MapLocationItem> get _visibleFloorLocations {
    final locations = _currentFloor.locations;
    if (_selectedCategory == null) return locations;
    return locations.where((l) => l.category == _selectedCategory).toList();
  }

  List<MapLocationItem> get _globalSearchResults {
    final q = _searchQuery.trim();
    if (q.isEmpty) return const [];

    final matches = <MapLocationItem>[];
    for (final floor in MapData.floors) {
      for (final loc in floor.locations) {
        if (loc.matchesQuery(q)) {
          matches.add(loc);
        }
      }
    }

    // Priorizar coincidencias del piso actual primero
    matches.sort((a, b) {
      final aCurrent = a.floorCode == _currentFloor.code ? 0 : 1;
      final bCurrent = b.floorCode == _currentFloor.code ? 0 : 1;
      return aCurrent.compareTo(bCurrent);
    });
    return matches;
  }

  void _selectFloor(int index, {bool autoSelectFirst = false}) {
    if (index < 0 || index >= MapData.floors.length) return;
    setState(() {
      _selectedFloorIndex = index;
      _transformationController.value = Matrix4.identity();
      final floor = MapData.floors[index];

      if (_selectedCategory != null) {
        final filtered = floor.locations
            .where((l) => l.category == _selectedCategory)
            .toList();
        _selectedLocation = filtered.isNotEmpty ? filtered.first : null;
      } else if (autoSelectFirst && floor.locations.isNotEmpty) {
        _selectedLocation = floor.locations.first;
      } else {
        _selectedLocation =
            floor.locations.isNotEmpty ? floor.locations.first : null;
      }
      _showRoute = false;
    });
  }

  void _toggleCategoryFilter(MapLocationCategory category) {
    _searchFocusNode.unfocus();
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        return;
      }
      _selectedCategory = category;

      // Buscar coincidencias primero en el piso actual
      final onCurrent = _currentFloor.locations
          .where((l) => l.category == category)
          .toList();

      if (onCurrent.isNotEmpty) {
        _selectedLocation = onCurrent.first;
        _showRoute = true;
      } else {
        // Si este piso no tiene de esa categoría, saltar al primer piso que sí tenga
        for (int i = 0; i < MapData.floors.length; i++) {
          final matches = MapData.floors[i].locations
              .where((l) => l.category == category)
              .toList();
          if (matches.isNotEmpty) {
            _selectedFloorIndex = i;
            _selectedLocation = matches.first;
            _showRoute = true;
            _transformationController.value = Matrix4.identity();
            break;
          }
        }
      }
    });
  }

  void _selectLocationFromSearchOrTap(
    MapLocationItem loc, {
    bool enableRoute = true,
  }) {
    final floorIdx = MapData.floors.indexWhere((f) => f.code == loc.floorCode);
    _searchFocusNode.unfocus();
    setState(() {
      if (floorIdx >= 0 && floorIdx != _selectedFloorIndex) {
        _selectedFloorIndex = floorIdx;
        _transformationController.value = Matrix4.identity();
      }
      _selectedLocation = loc;
      _showRoute = enableRoute;
      if (_selectedCategory != null && _selectedCategory != loc.category) {
        _selectedCategory = null;
      }
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  void _openScheduleModal(MapLocationItem loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    final accent = _resolveAccentColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: loc.category.pinColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(loc.category.icon, color: loc.category.pinColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _currentFloor.floorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (loc.isOpenNow ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 9,
                    color: loc.isOpenNow ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${loc.statusBadge} • ${loc.scheduleSummary}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: loc.isOpenNow
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Horarios detallados',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.fullSchedule,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              loc.detailsTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.detailsBody,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _showRoute = true);
              _resetZoom();
            },
            icon: const Icon(Icons.near_me_rounded, size: 17),
            label: const Text('Trazar ruta'),
          ),
        ],
      ),
    );
  }

  void _openBuildingOverviewModal() {
    final cardColor = Theme.of(context).cardColor;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _resolveAccentColor(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment_rounded, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Torre Tecnológica UPEA - Vista General',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: Image.asset(
                      'assets/images/edificioA.PNG',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          'Vista general del bloque no disponible',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pellizca para hacer zoom o selecciona un piso en la barra derecha del mapa.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = _resolveAccentColor(context);
    final searchResults = _globalSearchResults;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // 1. BUSCADOR + CHIPS DE CATEGORÍA (coherente con NotesScreen/NoticiasScreen)
            _buildTopSearchAndFilters(theme, colorScheme, isDark, accent),

            // 2. ZONA CENTRAL: TÍTULO DE PLANTA, PLANO INTERACTIVO Y BARRA P5-PB
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      // Encabezado del plano actual
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'Planta de ${_currentFloor.floorName} de',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _currentFloor.areaTitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Plano + Barra vertical de pisos P5..PB
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 10, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInteractiveFloorCanvas(
                                  theme,
                                  colorScheme,
                                  isDark,
                                  accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildFloorSelectorRail(
                                theme,
                                colorScheme,
                                isDark,
                                accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Resultados de búsqueda flotantes cuando el usuario escribe
                  if (_searchQuery.trim().isNotEmpty)
                    _buildSearchResultsOverlay(
                      theme,
                      colorScheme,
                      isDark,
                      accent,
                      searchResults,
                    ),
                ],
              ),
            ),

            // 3. PANEL INFERIOR DINÁMICO (cambia según el punto elegido)
            _buildDynamicBottomSheet(theme, colorScheme, isDark, accent),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUSCADOR Y FILTROS RÁPIDOS
  // ===========================================================================
  Widget _buildTopSearchAndFilters(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color accent,
  ) {
    final cardColor = theme.cardColor;
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.045);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _searchFocusNode.hasFocus
                    ? accent.withValues(alpha: 0.6)
                    : colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar aula, laboratorio, baño o extintor...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Chips de categorías rápidas (Baños, Aulas, Laboratorios, Trámites, Extintores...)
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: MapLocationCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final cat = MapLocationCategory.values[index];
                final isSelected = _selectedCategory == cat;
                final chipBg = isSelected
                    ? accent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.scaffoldBackgroundColor);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _toggleCategoryFilter(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : colorScheme.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // OVERLAY DE RESULTADOS DEL BUSCADOR EN TODOS LOS PISOS
  // ===========================================================================
  Widget _buildSearchResultsOverlay(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color accent,
    List<MapLocationItem> results,
  ) {
    return Positioned(
      top: 6,
      left: 14,
      right: 14,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No se encontraron coincidencias para "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, idx) {
                    final item = results[idx];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            item.category.pinColor.withValues(alpha: 0.15),
                        child: Icon(
                          item.category.icon,
                          size: 16,
                          color: item.category.pinColor,
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${item.category.label} • ${item.scheduleSummary}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.floorCode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      onTap: () => _selectLocationFromSearchOrTap(item),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // VISOR INTERACTIVO DEL PLANO CON PINES Y RUTA ANIMADA
  // ===========================================================================
  Widget _buildInteractiveFloorCanvas(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color accent,
  ) {
    final visiblePins = _visibleFloorLocations;
    final activeLoc = _selectedLocation;
    final showRoutePath =
        _showRoute &&
        activeLoc != null &&
        activeLoc.floorCode == _currentFloor.code &&
        (_selectedCategory == null || activeLoc.category == _selectedCategory);

    final canvasBg = isDark
        ? const Color(0xFF0E131B)
        : Color.alphaBlend(
            accent.withValues(alpha: 0.05),
            const Color(0xFFC9D6E6),
          );

    return Container(
      decoration: BoxDecoration(
        color: canvasBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
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
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.9,
              maxScale: 4.5,
              boundaryMargin: const EdgeInsets.all(40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _currentFloor.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. Imagen del plano del piso actual (1:1 con dimensiones del PNG)
                            Positioned.fill(
                              child: Image.asset(
                                _currentFloor.imagePath,
                                fit: BoxFit.fill,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.layers_clear_rounded,
                                        size: 42,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Plano de ${_currentFloor.floorName} no disponible',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 2. Ruta punteada animada desde acceso/gradas al destino elegido
                            if (showRoutePath)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _routeAnimController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: _DashedRoutePainter(
                                          start: _currentFloor.stairsEntry,
                                          waypoints: activeLoc.routeWaypoints,
                                          end: MapPoint(activeLoc.x, activeLoc.y),
                                          color: accent,
                                          phaseOffset: _routeAnimController.value,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // 3. Pines interactivos sobre el plano
                            ...visiblePins.map((loc) {
                              final isSelected = activeLoc?.id == loc.id;
                              const double pinWidth = 26;
                              const double pinHeight = 33;

                              return Positioned(
                                left: (loc.x * w) - (pinWidth / 2),
                                top: (loc.y * h) - pinHeight,
                                child: _MapPinMarker(
                                  location: loc,
                                  isSelected: isSelected,
                                  highlightRingColor: accent,
                                  onTap: () => _selectLocationFromSearchOrTap(
                                    loc,
                                    enableRoute: isSelected ? !_showRoute : true,
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Controles compactos en la esquina superior izquierda (Torre, Reset Zoom, Pantalla Completa)
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  _buildCanvasIconButton(
                    icon: Icons.apartment_rounded,
                    tooltip: 'Ver vista del edificio',
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onTap: _openBuildingOverviewModal,
                  ),
                  const SizedBox(width: 6),
                  _buildCanvasIconButton(
                    icon: Icons.center_focus_strong_rounded,
                    tooltip: 'Centrar plano',
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onTap: _resetZoom,
                  ),
                  const SizedBox(width: 6),
                  _buildCanvasIconButton(
                    icon: Icons.fullscreen_rounded,
                    tooltip: 'Pantalla completa',
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FloorDetailScreen(
                            floor: _currentFloor,
                            initialLocation: _selectedLocation,
                            showRoute: _showRoute,
                            accentColor: accent,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Pill indicadora cuando hay filtro activo
            if (_selectedCategory != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategory!.icon,
                        size: 13,
                        color: accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${visiblePins.length} ${_selectedCategory!.label.toLowerCase()} aquí',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasIconButton({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark
            ? Colors.black.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.88),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 17,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECTOR VERTICAL DE PISOS (P5 .. PB) AL ESTILO DEL MOCKUP
  // ===========================================================================
  Widget _buildFloorSelectorRail(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color accent,
  ) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(MapData.floors.length, (index) {
              final floor = MapData.floors[index];
              final isSelected = index == _selectedFloorIndex;
              final hasCategoryMatch = _selectedCategory != null &&
                  floor.locations.any((l) => l.category == _selectedCategory);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _selectFloor(index, autoSelectFirst: true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            floor.code,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          if (hasCategoryMatch && !isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _selectedCategory!.pinColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PANEL INFERIOR DINÁMICO (CAMBIA SEGÚN LO SELECCIONADO EN EL PLANO)
  // ===========================================================================
  Widget _buildDynamicBottomSheet(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color accent,
  ) {
    final loc = _selectedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra superior (Handle para expandir/colapsar lista del piso)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isSheetExpanded = !_isSheetExpanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            if (loc != null) ...[
              // Encabezado con nombre del lugar seleccionado + botón de directorio
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${loc.name} - ${_currentFloor.floorName}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: _isSheetExpanded
                        ? 'Ocultar lugares del piso'
                        : 'Ver todos los lugares del piso',
                    icon: Icon(
                      _isSheetExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.list_alt_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    onPressed: () =>
                        setState(() => _isSheetExpanded = !_isSheetExpanded),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // Línea de estado en vivo: ● ABIERTO - Atención hasta las 18:00
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: loc.isOpenNow
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: loc.statusBadge,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: loc.isOpenNow
                                  ? const Color(0xFF10B981)
                                  : Colors.orange.shade700,
                            ),
                          ),
                          TextSpan(
                            text: ' - ${loc.scheduleSummary}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // Botones de acción principales ("Cómo llegar" y "Ver horarios")
              Row(
                children: [
                  Expanded(
                    child: _buildSheetActionButton(
                      icon: _showRoute
                          ? Icons.alt_route_rounded
                          : Icons.near_me_outlined,
                      label: _showRoute ? 'Ruta activa' : 'Cómo llegar',
                      isPrimary: _showRoute,
                      accent: accent,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _showRoute = !_showRoute);
                        if (_showRoute) _resetZoom();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSheetActionButton(
                      icon: Icons.access_time_rounded,
                      label: 'Ver horarios',
                      isPrimary: false,
                      accent: accent,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      onTap: () => _openScheduleModal(loc),
                    ),
                  ),
                ],
              ),

              // Indicaciones paso a paso cuando la ruta está activa
              if (_showRoute) ...[
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 15, color: accent),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          loc.directionsText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.88),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Bloque inferior de trámites / servicios / equipamiento
              Text(
                loc.detailsTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                loc.detailsBody,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Text(
                '${_currentFloor.floorName} • ${_currentFloor.subtitle}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca un marcador en el plano o elige un punto abajo para ver horarios y cómo llegar.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],

            // Carrusel horizontal rápido para cambiar de lugar en este piso
            if (_isSheetExpanded || loc == null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _currentFloor.locations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = _currentFloor.locations[idx];
                    final selected = item.id == loc?.id;
                    return ActionChip(
                      avatar: Icon(
                        item.category.icon,
                        size: 15,
                        color: selected ? Colors.white : item.category.pinColor,
                      ),
                      label: Text(
                        item.shortLabel ?? item.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      backgroundColor: selected
                          ? accent
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : theme.scaffoldBackgroundColor),
                      side: BorderSide(
                        color: selected
                            ? accent
                            : colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                      onPressed: () => _selectLocationFromSearchOrTap(item),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required Color accent,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bg = isPrimary
        ? accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : colorScheme.onSurface.withValues(alpha: 0.06));
    final fg = isPrimary ? Colors.white : colorScheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isPrimary
                  ? accent
                  : colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MARCADOR TIPO PIN DE MAPA (gota con ícono blanco y halo de selección)
// =============================================================================
class _MapPinMarker extends StatelessWidget {
  final MapLocationItem location;
  final bool isSelected;
  final Color highlightRingColor;
  final VoidCallback onTap;

  const _MapPinMarker({
    required this.location,
    required this.isSelected,
    required this.highlightRingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pinColor = location.category.pinColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.18 : 1.0,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: pinColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  width: isSelected ? 2.2 : 1.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: highlightRingColor.withValues(alpha: 0.65),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                location.category.icon,
                size: 14,
                color: Colors.white,
              ),
            ),
            CustomPaint(
              size: const Size(9, 7),
              painter: _PinTipPainter(color: pinColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;

  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}

// =============================================================================
// PINTOR DE RUTA PUNTEADA ANIMADA CON FLECHA DE DIRECCIÓN
// =============================================================================
class _DashedRoutePainter extends CustomPainter {
  final MapPoint start;
  final List<MapPoint> waypoints;
  final MapPoint end;
  final Color color;
  final double phaseOffset;

  const _DashedRoutePainter({
    required this.start,
    required this.waypoints,
    required this.end,
    required this.color,
    required this.phaseOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(start.x * size.width, start.y * size.height),
      ...waypoints.map((p) => Offset(p.x * size.width, p.y * size.height)),
      Offset(end.x * size.width, end.y * size.height),
    ];

    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Resplandor suave bajo la ruta punteada
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // Línea punteada animada
    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double dashLength = 7.0;
    const double gapLength = 5.0;
    const double cycle = dashLength + gapLength;

    for (final metric in path.computeMetrics()) {
      double distance = (phaseOffset * cycle) % cycle - cycle;
      while (distance < metric.length - 10) {
        final startDist = math.max(0.0, distance);
        final endDist = math.min(metric.length - 8, distance + dashLength);
        if (endDist > startDist) {
          final extract = metric.extractPath(startDist, endDist);
          canvas.drawPath(extract, dashPaint);
        }
        distance += cycle;
      }

      // Flecha al final de la ruta
      if (metric.length > 10) {
        final tangent = metric.getTangentForOffset(metric.length - 4);
        if (tangent != null) {
          final pos = tangent.position;
          final angle = -tangent.angle;
          const double arrowSize = 9.0;
          final arrowPath = Path()
            ..moveTo(pos.dx, pos.dy)
            ..lineTo(
              pos.dx - arrowSize * math.cos(angle - math.pi / 6),
              pos.dy - arrowSize * math.sin(angle - math.pi / 6),
            )
            ..lineTo(
              pos.dx - arrowSize * math.cos(angle + math.pi / 6),
              pos.dy - arrowSize * math.sin(angle + math.pi / 6),
            )
            ..close();
          canvas.drawPath(
            arrowPath,
            Paint()
              ..color = color
              ..style = PaintingStyle.fill,
          );
        }
      }
    }

    // Punto de inicio en las gradas
    canvas.drawCircle(
      points.first,
      5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      points.first,
      2.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedRoutePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.waypoints != waypoints ||
        oldDelegate.color != color ||
        oldDelegate.phaseOffset != phaseOffset;
  }
}

// =============================================================================
// PANTALLA DE DETALLE EN PANTALLA COMPLETA (mantiene coherencia con temas de la app)
// =============================================================================
class FloorDetailScreen extends StatefulWidget {
  final MapFloorModel floor;
  final MapLocationItem? initialLocation;
  final bool showRoute;
  final Color accentColor;

  const FloorDetailScreen({
    super.key,
    required this.floor,
    this.initialLocation,
    this.showRoute = true,
    required this.accentColor,
  });

  @override
  State<FloorDetailScreen> createState() => _FloorDetailScreenState();
}

class _FloorDetailScreenState extends State<FloorDetailScreen> {
  late final TransformationController _transformationController;
  MapLocationItem? _selected;
  late bool _showRoute;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _selected = widget.initialLocation;
    _showRoute = widget.showRoute;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvasBg = isDark
        ? const Color(0xFF0E131B)
        : Color.alphaBlend(
            widget.accentColor.withValues(alpha: 0.05),
            const Color(0xFFC9D6E6),
          );

    return Scaffold(
      backgroundColor: canvasBg,
      appBar: AppBar(
        title: Text(
          '${widget.floor.floorName} • ${widget.floor.subtitle}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Centrar plano',
            onPressed: () {
              setState(() {
                _transformationController.value = Matrix4.identity();
              });
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.8,
            maxScale: 4.5,
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.floor.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            widget.floor.imagePath,
                            fit: BoxFit.fill,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                'Plano detallado de ${widget.floor.floorName} no disponible.',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ),
                          ),
                        ),
                        if (_showRoute && _selected != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _DashedRoutePainter(
                                  start: widget.floor.stairsEntry,
                                  waypoints: _selected!.routeWaypoints,
                                  end: MapPoint(_selected!.x, _selected!.y),
                                  color: widget.accentColor,
                                  phaseOffset: 0.0,
                                ),
                              ),
                            ),
                          ),
                        ...widget.floor.locations.map((loc) {
                          const double pinWidth = 26;
                          const double pinHeight = 33;
                          return Positioned(
                            left: (loc.x * w) - (pinWidth / 2),
                            top: (loc.y * h) - pinHeight,
                            child: _MapPinMarker(
                              location: loc,
                              isSelected: _selected?.id == loc.id,
                              highlightRingColor: widget.accentColor,
                              onTap: () {
                                setState(() {
                                  _selected = loc;
                                  _showRoute = true;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  _selected != null
                      ? '${_selected!.name} • ${_selected!.scheduleSummary}'
                      : 'Pellizca para hacer zoom o toca un marcador',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
