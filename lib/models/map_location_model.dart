import 'package:flutter/material.dart';

/// Categorías principales de búsqueda y filtrado rápido en el mapa del edificio.
enum MapLocationCategory {
  banos,
  aulas,
  laboratorios,
  tramites,
  extintores,
  accesibilidad,
}

extension MapLocationCategoryX on MapLocationCategory {
  String get label {
    switch (this) {
      case MapLocationCategory.banos:
        return 'Baños';
      case MapLocationCategory.aulas:
        return 'Aulas';
      case MapLocationCategory.laboratorios:
        return 'Laboratorios';
      case MapLocationCategory.tramites:
        return 'Trámites';
      case MapLocationCategory.extintores:
        return 'Extintores';
      case MapLocationCategory.accesibilidad:
        return 'Accesibilidad';
    }
  }

  IconData get icon {
    switch (this) {
      case MapLocationCategory.banos:
        return Icons.wc_rounded;
      case MapLocationCategory.aulas:
        return Icons.school_rounded;
      case MapLocationCategory.laboratorios:
        return Icons.science_rounded;
      case MapLocationCategory.tramites:
        return Icons.assignment_rounded;
      case MapLocationCategory.extintores:
        return Icons.fire_extinguisher_rounded;
      case MapLocationCategory.accesibilidad:
        return Icons.accessible_rounded;
    }
  }

  Color get pinColor {
    switch (this) {
      case MapLocationCategory.banos:
        return const Color(0xFF2563EB);
      case MapLocationCategory.aulas:
        return const Color(0xFF0284C7);
      case MapLocationCategory.laboratorios:
        return const Color(0xFFB91C1C);
      case MapLocationCategory.tramites:
        return const Color(0xFF0D9488);
      case MapLocationCategory.extintores:
        return const Color(0xFFDC2626);
      case MapLocationCategory.accesibilidad:
        return const Color(0xFF7C3AED);
    }
  }
}

/// Coordenada normalizada (0.0 a 1.0) relativa al tamaño real del plano.
class MapPoint {
  final double x;
  final double y;

  const MapPoint(this.x, this.y);
}

/// Elemento o punto de interés interactivo dentro de un piso.
class MapLocationItem {
  final String id;
  final String floorCode;
  final String name;
  final String? shortLabel;
  final MapLocationCategory category;
  final double x;
  final double y;
  final String statusBadge;
  final bool isOpenNow;
  final String scheduleSummary;
  final String fullSchedule;
  final String detailsTitle;
  final String detailsBody;
  final String directionsText;
  final List<MapPoint> routeWaypoints;
  final List<String> keywords;

  const MapLocationItem({
    required this.id,
    required this.floorCode,
    required this.name,
    this.shortLabel,
    required this.category,
    required this.x,
    required this.y,
    required this.statusBadge,
    this.isOpenNow = true,
    required this.scheduleSummary,
    required this.fullSchedule,
    required this.detailsTitle,
    required this.detailsBody,
    required this.directionsText,
    this.routeWaypoints = const [],
    this.keywords = const [],
  });

  bool matchesQuery(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q) ||
        detailsTitle.toLowerCase().contains(q) ||
        detailsBody.toLowerCase().contains(q) ||
        floorCode.toLowerCase().contains(q) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// Modelo completo de cada planta de la Torre Tecnológica UPEA.
class MapFloorModel {
  final String code;
  final String floorName;
  final String areaTitle;
  final String subtitle;
  final String imagePath;
  final double aspectRatio;
  final Color themeColor;
  final MapPoint stairsEntry;
  final List<MapLocationItem> locations;

  const MapFloorModel({
    required this.code,
    required this.floorName,
    this.areaTitle = 'CARRERA INGENIERÍA DE SISTEMAS',
    required this.subtitle,
    required this.imagePath,
    this.aspectRatio = 1792 / 2400,
    required this.themeColor,
    this.stairsEntry = const MapPoint(0.49, 0.88),
    required this.locations,
  });
}
