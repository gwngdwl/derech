import 'package:latlong2/latlong.dart';

/// תוצאת ניתוב
class RouteResult {
  /// נקודות המסלול לציור על המפה
  final List<LatLng> polyline;

  /// מרחק כולל במטרים
  final double distanceMeters;

  /// זמן משוער בשניות
  final double durationSeconds;

  /// הוראות ניווט
  final List<NavigationInstruction> instructions;

  const RouteResult({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.instructions,
  });

  /// מרחק מפורמט לתצוגה
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} מ\'';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} ק"מ';
  }

  /// זמן מפורמט לתצוגה
  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes דק\'';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours שע\'';
    }
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')} שע\'';
  }
}

/// הוראת ניווט בודדת
class NavigationInstruction {
  final ManeuverType type;
  final String streetName;
  final double distanceMeters;
  final LatLng location;

  const NavigationInstruction({
    required this.type,
    required this.streetName,
    required this.distanceMeters,
    required this.location,
  });

  String get text {
    final street = streetName.isNotEmpty ? ' ל-$streetName' : '';
    return '${type.hebrew}$street';
  }

  String get distanceText {
    if (distanceMeters < 1000) {
      return 'בעוד ${distanceMeters.round()} מ\'';
    }
    return 'בעוד ${(distanceMeters / 1000).toStringAsFixed(1)} ק"מ';
  }
}

/// סוגי פניות
enum ManeuverType {
  start('התחל נסיעה', '🚗'),
  straight('המשך ישר', '⬆️'),
  slightRight('סטה ימינה', '↗️'),
  right('פנה ימינה', '➡️'),
  sharpRight('פנייה חדה ימינה', '↪️'),
  slightLeft('סטה שמאלה', '↖️'),
  left('פנה שמאלה', '⬅️'),
  sharpLeft('פנייה חדה שמאלה', '↩️'),
  uturn('פניית פרסה', '🔄'),
  arrive('הגעת ליעד', '🏁');

  final String hebrew;
  final String icon;

  const ManeuverType(this.hebrew, this.icon);
}

/// מצב ניתוב
enum RoutingMode {
  car('רכב', '🚗'),
  walk('הליכה', '🚶'),
  bicycle('אופניים', '🚲');

  final String hebrew;
  final String icon;

  const RoutingMode(this.hebrew, this.icon);
}
