import 'package:latlong2/latlong.dart';

/// מודל קטע כביש מהנתונים של ה-GPKG
class RoadSegment {
  final int fid;
  final String osmId;
  final String fclass;
  final String name;
  final String ref;
  final bool oneway;
  final int maxspeed;
  final int layer;
  final bool bridge;
  final bool tunnel;
  final List<LatLng> points;

  const RoadSegment({
    required this.fid,
    required this.osmId,
    required this.fclass,
    required this.name,
    required this.ref,
    required this.oneway,
    required this.maxspeed,
    required this.layer,
    required this.bridge,
    required this.tunnel,
    required this.points,
  });

  /// האם הכביש ניתן לניתוב ברכב
  bool get isDriveable => _driveableFclasses.contains(fclass);

  /// האם הכביש ניתן להליכה
  bool get isWalkable => true; // ברגל אפשר בכל מקום

  /// האם הכביש ניתן לרכיבת אופניים
  bool get isCycleable =>
      !_noCycleFclasses.contains(fclass);

  /// מהירות ברירת מחדל לפי סוג כביש (קמ"ש)
  int get defaultSpeed => _defaultSpeeds[fclass] ?? 50;

  /// מהירות בפועל (maxspeed אם קיים, אחרת ברירת מחדל)
  int get effectiveSpeed => maxspeed > 0 ? maxspeed : defaultSpeed;

  /// חישוב אורך הקטע במטרים
  double get lengthMeters {
    const distance = Distance();
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    return total;
  }

  /// חישוב זמן נסיעה בשניות
  double get travelTimeSeconds {
    return lengthMeters / (effectiveSpeed * 1000 / 3600);
  }

  static const _driveableFclasses = {
    'motorway',
    'motorway_link',
    'trunk',
    'trunk_link',
    'primary',
    'primary_link',
    'secondary',
    'secondary_link',
    'tertiary',
    'tertiary_link',
    'residential',
    'living_street',
    'unclassified',
    'service',
  };

  static const _noCycleFclasses = {
    'motorway',
    'motorway_link',
    'steps',
  };

  static const _defaultSpeeds = <String, int>{
    'motorway': 110,
    'motorway_link': 70,
    'trunk': 90,
    'trunk_link': 60,
    'primary': 80,
    'primary_link': 50,
    'secondary': 60,
    'secondary_link': 40,
    'tertiary': 50,
    'tertiary_link': 40,
    'residential': 30,
    'living_street': 20,
    'unclassified': 40,
    'service': 20,
    'track': 20,
    'track_grade2': 15,
    'track_grade3': 10,
    'track_grade4': 10,
    'track_grade5': 5,
    'footway': 5,
    'path': 5,
    'pedestrian': 5,
    'steps': 3,
    'cycleway': 20,
  };
}
