import 'dart:math';
import 'package:latlong2/latlong.dart';

/// המרה בין EPSG:4326 (מעלות) לבין EPSG:3857 (מטרים - Web Mercator)
class ProjectionUtils {
  static const double _a = 6378137.0; // WGS84 semi-major axis

  /// EPSG:3857 (X, Y) -> EPSG:4326 (Lon, Lat)
  static LatLng epsg3857To4326(double x, double y) {
    final lon = (x / _a) * (180.0 / pi);
    final lat = (2 * atan(exp(y / _a)) - pi / 2) * (180.0 / pi);
    return LatLng(lat, lon);
  }

  /// EPSG:4326 (Lon, Lat) -> EPSG:3857 (X, Y)
  static List<double> epsg4326To3857(double lon, double lat) {
    // הגבלת קווי רוחב כדי למנוע אינסוף
    final latClamped = lat.clamp(-85.05112878, 85.05112878);
    final x = _a * lon * pi / 180.0;
    final y = _a * log(tan(pi / 4.0 + latClamped * pi / 360.0));
    return [x, y];
  }
}
