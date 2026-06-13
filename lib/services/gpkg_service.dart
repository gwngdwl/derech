import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/place.dart';
import '../models/road_segment.dart';
import '../rendering/gpkg_geometry_parser.dart';

/// שירות גישה לנתוני ה-GeoPackage (SQLite)
class GpkgService {
  Database? _db;
  final GpkgGeometryParser _parser = const GpkgGeometryParser();

  bool get isOpen => _db != null;

  /// פתיחת בסיס הנתונים
  void open(String path) {
    if (_db != null) return;
    _db = sqlite3.open(path, mode: OpenMode.readOnly);
    debugPrint('GPKG נפתח: $path');
  }

  /// סגירת בסיס הנתונים
  void close() {
    _db?.close();
    _db = null;
  }

  /// שליפת כבישים ב-viewport (bounding box)
  List<RoadSegment> getRoadsInBounds(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon, {
    Set<String>? fclassFilter,
  }) {
    final db = _db;
    if (db == null) return [];

    // שימוש ב-R-Tree spatial index של ה-GPKG
    String fclassWhere = '';
    if (fclassFilter != null && fclassFilter.isNotEmpty) {
      final classes = fclassFilter.map((c) => "'$c'").join(',');
      fclassWhere = 'AND r.fclass IN ($classes)';
    }

    final sql = '''
      SELECT r.fid, r.geom, r.osm_id, r.fclass, r.name, r.ref,
             r.oneway, r.maxspeed, r.layer, r.bridge, r.tunnel
      FROM gis_osm_roads_free r
      INNER JOIN rtree_gis_osm_roads_free_geom idx ON r.fid = idx.id
      WHERE idx.minx <= ? AND idx.maxx >= ?
        AND idx.miny <= ? AND idx.maxy >= ?
        $fclassWhere
    ''';

    final result = db.select(sql, [maxLon, minLon, maxLat, minLat]);
    return result.map(_rowToRoadSegment).toList();
  }

  /// שליפת כל הכבישים הניתנים לניתוב (לבניית גרף)
  List<RoadSegment> getAllRoutableRoads() {
    final db = _db;
    if (db == null) return [];

    final result = db.select('''
      SELECT fid, geom, osm_id, fclass, name, ref,
             oneway, maxspeed, layer, bridge, tunnel
      FROM gis_osm_roads_free
      WHERE fclass IN (
        'motorway','motorway_link','trunk','trunk_link',
        'primary','primary_link','secondary','secondary_link',
        'tertiary','tertiary_link','residential','living_street',
        'unclassified','service','track','track_grade2',
        'footway','path','pedestrian','cycleway','steps'
      )
    ''');

    return result.map(_rowToRoadSegment).toList();
  }

  /// חיפוש מקומות לפי שם
  List<Place> searchPlaces(String query, {int limit = 20}) {
    final db = _db;
    if (db == null) return [];

    final results = <Place>[];

    // חיפוש ב-places
    final placesResult = db.select('''
      SELECT fid, geom, osm_id, fclass, name, population
      FROM gis_osm_places_free
      WHERE name LIKE ?
      ORDER BY
        CASE fclass
          WHEN 'national_capital' THEN 0
          WHEN 'city' THEN 1
          WHEN 'town' THEN 2
          WHEN 'village' THEN 3
          WHEN 'suburb' THEN 4
          ELSE 5
        END,
        population DESC
      LIMIT ?
    ''', ['%$query%', limit]);

    for (final row in placesResult) {
      results.add(_rowToPlace(row, hasPopulation: true));
    }

    // אם יש פחות מ-limit תוצאות, חפש גם ב-POIs
    if (results.length < limit) {
      final poisResult = db.select('''
        SELECT fid, geom, osm_id, fclass, name
        FROM gis_osm_pois_free
        WHERE name LIKE ?
        LIMIT ?
      ''', ['%$query%', limit - results.length]);

      for (final row in poisResult) {
        results.add(_rowToPlace(row));
      }
    }

    return results;
  }

  /// שליפת POIs לפי קטגוריה באזור
  List<Place> getPoisInBounds(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon, {
    Set<String>? fclassFilter,
    int limit = 100,
  }) {
    final db = _db;
    if (db == null) return [];

    String fclassWhere = '';
    if (fclassFilter != null && fclassFilter.isNotEmpty) {
      final classes = fclassFilter.map((c) => "'$c'").join(',');
      fclassWhere = 'AND p.fclass IN ($classes)';
    }

    final sql = '''
      SELECT p.fid, p.geom, p.osm_id, p.fclass, p.name
      FROM gis_osm_pois_free p
      INNER JOIN rtree_gis_osm_pois_free_geom idx ON p.fid = idx.id
      WHERE idx.minx <= ? AND idx.maxx >= ?
        AND idx.miny <= ? AND idx.maxy >= ?
        $fclassWhere
      LIMIT ?
    ''';

    final result = db.select(sql, [maxLon, minLon, maxLat, minLat, limit]);
    return result.map((r) => _rowToPlace(r)).toList();
  }

  /// שליפת מקומות (ערים וכו') באזור
  List<Place> getPlacesInBounds(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon, {
    Set<String>? fclassFilter,
    int limit = 50,
  }) {
    final db = _db;
    if (db == null) return [];

    String fclassWhere = '';
    if (fclassFilter != null && fclassFilter.isNotEmpty) {
      final classes = fclassFilter.map((c) => "'$c'").join(',');
      fclassWhere = 'AND p.fclass IN ($classes)';
    }

    final sql = '''
      SELECT p.fid, p.geom, p.osm_id, p.fclass, p.name, p.population
      FROM gis_osm_places_free p
      INNER JOIN rtree_gis_osm_places_free_geom idx ON p.fid = idx.id
      WHERE idx.minx <= ? AND idx.maxx >= ?
        AND idx.miny <= ? AND idx.maxy >= ?
        $fclassWhere
      LIMIT ?
    ''';

    final result = db.select(sql, [maxLon, minLon, maxLat, minLat, limit]);
    return result.map((r) => _rowToPlace(r, hasPopulation: true)).toList();
  }

  /// שליפת שטחים (מים, שימושי קרקע, וכו') באזור
  List<AreaFeature> getAreasInBounds(
    String tableName,
    double minLat,
    double minLon,
    double maxLat,
    double maxLon, {
    int limit = 200,
  }) {
    final db = _db;
    if (db == null) return [];

    // בדיקה שהטבלה קיימת
    final validTables = {
      'gis_osm_water_a_free',
      'gis_osm_landuse_a_free',
      'gis_osm_natural_a_free',
      'gis_osm_buildings_a_free',
    };
    if (!validTables.contains(tableName)) return [];

    final rtreeName = 'rtree_${tableName}_geom';

    final sql = '''
      SELECT a.fid, a.geom, a.fclass
      FROM $tableName a
      INNER JOIN $rtreeName idx ON a.fid = idx.id
      WHERE idx.minx <= ? AND idx.maxx >= ?
        AND idx.miny <= ? AND idx.maxy >= ?
      LIMIT ?
    ''';

    try {
      final result = db.select(sql, [maxLon, minLon, maxLat, minLat, limit]);
      return result.map((row) {
        final geomBytes = row['geom'] as Uint8List;
        List<List<LatLng>> rings;
        try {
          rings = _parser.parsePolygon(geomBytes);
        } catch (_) {
          // אם זה MULTIPOLYGON, ניקח רק את הפוליגון הראשון
          try {
            final multiPolygon = _parser.parseMultiPolygon(geomBytes);
            rings = multiPolygon.isNotEmpty ? multiPolygon.first : [];
          } catch (_) {
            rings = [];
          }
        }
        return AreaFeature(
          fid: row['fid'] as int,
          fclass: (row['fclass'] as String?) ?? '',
          rings: rings,
        );
      }).where((a) => a.rings.isNotEmpty).toList();
    } catch (e) {
      debugPrint('שגיאה בטעינת שטחים מ-$tableName: $e');
      return [];
    }
  }

  /// חיפוש רחובות לפי שם
  List<RoadSearchResult> searchStreets(String query, {int limit = 10}) {
    final db = _db;
    if (db == null) return [];

    final result = db.select('''
      SELECT fid, geom, name, fclass
      FROM gis_osm_roads_free
      WHERE name LIKE ? AND name != ''
      GROUP BY name
      LIMIT ?
    ''', ['%$query%', limit]);

    return result.map((row) {
      final geomBytes = row['geom'] as Uint8List;
      final points = _parser.parseLineString(geomBytes);
      final midpoint =
          points.isNotEmpty ? points[points.length ~/ 2] : const LatLng(0, 0);
      return RoadSearchResult(
        name: (row['name'] as String?) ?? '',
        fclass: (row['fclass'] as String?) ?? '',
        location: midpoint,
      );
    }).toList();
  }

  RoadSegment _rowToRoadSegment(Row row) {
    final geomBytes = row['geom'] as Uint8List;
    final points = _parser.parseLineString(geomBytes);

    return RoadSegment(
      fid: row['fid'] as int,
      osmId: (row['osm_id'] as String?) ?? '',
      fclass: (row['fclass'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      ref: (row['ref'] as String?) ?? '',
      oneway: (row['oneway'] as String?) == 'F' ? false : true,
      maxspeed: (row['maxspeed'] as int?) ?? 0,
      layer: (row['layer'] as int?) ?? 0,
      bridge: (row['bridge'] as String?) == 'T',
      tunnel: (row['tunnel'] as String?) == 'T',
      points: points,
    );
  }

  Place _rowToPlace(Row row, {bool hasPopulation = false}) {
    final geomBytes = row['geom'] as Uint8List;
    final location = _parser.parsePoint(geomBytes);

    return Place(
      fid: row['fid'] as int,
      osmId: (row['osm_id'] as String?) ?? '',
      fclass: (row['fclass'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      location: location,
      population: hasPopulation ? (row['population'] as int?) : null,
    );
  }
}

/// שטח (פוליגון) — מים, בניינים, שימושי קרקע
class AreaFeature {
  final int fid;
  final String fclass;
  final List<List<LatLng>> rings;

  const AreaFeature({
    required this.fid,
    required this.fclass,
    required this.rings,
  });

  List<LatLng> get outerRing => rings.isNotEmpty ? rings.first : [];
}

/// תוצאת חיפוש רחוב
class RoadSearchResult {
  final String name;
  final String fclass;
  final LatLng location;

  const RoadSearchResult({
    required this.name,
    required this.fclass,
    required this.location,
  });
}
