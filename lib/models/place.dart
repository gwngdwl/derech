import 'package:latlong2/latlong.dart';

/// מודל מקום או נקודת עניין
class Place {
  final int fid;
  final String osmId;
  final String fclass;
  final String name;
  final LatLng location;
  final int? population;

  const Place({
    required this.fid,
    required this.osmId,
    required this.fclass,
    required this.name,
    required this.location,
    this.population,
  });

  /// שם הקטגוריה בעברית
  String get categoryHebrew => _categoryNames[fclass] ?? fclass;

  /// אייקון הקטגוריה
  String get categoryIcon => _categoryIcons[fclass] ?? '📍';

  static const _categoryNames = <String, String>{
    // מקומות
    'city': 'עיר',
    'town': 'עיירה',
    'village': 'כפר',
    'hamlet': 'כפר קטן',
    'suburb': 'שכונה',
    'locality': 'מקום',
    'national_capital': 'בירה',
    'island': 'אי',
    'farm': 'חווה',
    'region': 'אזור',
    // נקודות עניין
    'supermarket': 'סופרמרקט',
    'restaurant': 'מסעדה',
    'cafe': 'בית קפה',
    'fast_food': 'מזון מהיר',
    'pharmacy': 'בית מרקחת',
    'school': 'בית ספר',
    'kindergarten': 'גן ילדים',
    'hospital': 'בית חולים',
    'clinic': 'מרפאה',
    'fuel': 'תחנת דלק',
    'bank': 'בנק',
    'atm': 'כספומט',
    'post_office': 'דואר',
    'police': 'משטרה',
    'fire_station': 'תחנת כיבוי',
    'parking': 'חנייה',
    'bus_station': 'תחנת אוטובוס',
    'train_station': 'תחנת רכבת',
    'viewpoint': 'תצפית',
    'playground': 'גן משחקים',
    'convenience': 'מכולת',
    'clothes': 'ביגוד',
    'bakery': 'מאפייה',
    'butcher': 'אטליז',
    'library': 'ספרייה',
    'cinema': 'קולנוע',
    'theatre': 'תיאטרון',
    'museum': 'מוזיאון',
    'hotel': 'מלון',
    'hostel': 'אכסניה',
    'swimming_pool': 'בריכה',
    'sports_centre': 'מרכז ספורט',
    'drinking_water': 'מי שתייה',
    'bench': 'ספסל',
    'recycling': 'מיחזור',
    'waste_basket': 'פח',
  };

  static const _categoryIcons = <String, String>{
    'city': '🏙️',
    'town': '🏘️',
    'village': '🏡',
    'hamlet': '🏡',
    'suburb': '🏘️',
    'national_capital': '🏛️',
    'supermarket': '🛒',
    'restaurant': '🍽️',
    'cafe': '☕',
    'fast_food': '🍔',
    'pharmacy': '💊',
    'school': '🏫',
    'hospital': '🏥',
    'fuel': '⛽',
    'bank': '🏦',
    'parking': '🅿️',
    'bus_station': '🚌',
    'train_station': '🚂',
    'viewpoint': '👀',
    'playground': '🎪',
    'hotel': '🏨',
    'museum': '🏛️',
    'cinema': '🎬',
    'swimming_pool': '🏊',
    'drinking_water': '🚰',
  };
}
