import 'package:latlong2/latlong.dart';

import 'gpkg_service.dart';

/// שירות חיפוש אופליין
class SearchService {
  final GpkgService _gpkg;

  SearchService(this._gpkg);

  /// חיפוש כללי — מקומות, POIs, רחובות
  List<SearchResult> search(String query, {LatLng? nearLocation}) {
    if (query.trim().length < 2) return [];

    final results = <SearchResult>[];

    // חיפוש מקומות
    final places = _gpkg.searchPlaces(query, limit: 10);
    for (final place in places) {
      results.add(SearchResult(
        name: place.name,
        category: place.categoryHebrew,
        icon: place.categoryIcon,
        location: place.location,
        type: SearchResultType.place,
      ));
    }

    // חיפוש רחובות
    final streets = _gpkg.searchStreets(query, limit: 5);
    for (final street in streets) {
      results.add(SearchResult(
        name: street.name,
        category: _roadTypeHebrew(street.fclass),
        icon: '🛣️',
        location: street.location,
        type: SearchResultType.street,
      ));
    }

    // מיון לפי מרחק מהמיקום הנוכחי
    if (nearLocation != null) {
      const distance = Distance();
      results.sort((a, b) {
        final distA = distance.as(
            LengthUnit.Meter, nearLocation, a.location);
        final distB = distance.as(
            LengthUnit.Meter, nearLocation, b.location);
        return distA.compareTo(distB);
      });
    }

    return results;
  }

  /// חיפוש מהיר לפי קטגוריה
  List<SearchResult> searchByCategory(
    String fclass,
    LatLng center, {
    double radiusDeg = 0.05,
    int limit = 20,
  }) {
    final pois = _gpkg.getPoisInBounds(
      center.latitude - radiusDeg,
      center.longitude - radiusDeg,
      center.latitude + radiusDeg,
      center.longitude + radiusDeg,
      fclassFilter: {fclass},
      limit: limit,
    );

    const distance = Distance();
    final results = pois.map((poi) => SearchResult(
      name: poi.name.isNotEmpty ? poi.name : poi.categoryHebrew,
      category: poi.categoryHebrew,
      icon: poi.categoryIcon,
      location: poi.location,
      type: SearchResultType.poi,
      distanceMeters: distance.as(LengthUnit.Meter, center, poi.location),
    )).toList();

    results.sort((a, b) =>
        (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return results;
  }

  String _roadTypeHebrew(String fclass) {
    const map = {
      'motorway': 'כביש מהיר',
      'trunk': 'כביש ראשי',
      'primary': 'כביש ראשי',
      'secondary': 'כביש משני',
      'tertiary': 'כביש',
      'residential': 'רחוב',
      'living_street': 'רחוב',
      'service': 'דרך שירות',
    };
    return map[fclass] ?? 'דרך';
  }
}

/// תוצאת חיפוש
class SearchResult {
  final String name;
  final String category;
  final String icon;
  final LatLng location;
  final SearchResultType type;
  final double? distanceMeters;

  const SearchResult({
    required this.name,
    required this.category,
    required this.icon,
    required this.location,
    required this.type,
    this.distanceMeters,
  });

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) return '${distanceMeters!.round()} מ\'';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} ק"מ';
  }
}

enum SearchResultType { place, poi, street }

/// קטגוריות מהירות לחיפוש
class QuickCategory {
  final String fclass;
  final String name;
  final String icon;

  const QuickCategory(this.fclass, this.name, this.icon);

  static const categories = [
    QuickCategory('fuel', 'תחנת דלק', '⛽'),
    QuickCategory('restaurant', 'מסעדה', '🍽️'),
    QuickCategory('supermarket', 'סופרמרקט', '🛒'),
    QuickCategory('pharmacy', 'בית מרקחת', '💊'),
    QuickCategory('cafe', 'בית קפה', '☕'),
    QuickCategory('parking', 'חנייה', '🅿️'),
    QuickCategory('hospital', 'בית חולים', '🏥'),
    QuickCategory('bank', 'בנק', '🏦'),
  ];
}
