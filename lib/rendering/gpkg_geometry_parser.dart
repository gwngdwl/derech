import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

import '../services/projection_utils.dart';

/// פירוש GeoPackage Binary Geometry
///
/// פורמט:
/// Header: GP (2) + version (1) + flags (1) + srs_id (4) + envelope (0-64 bytes)
/// Body: Standard WKB
class GpkgGeometryParser {
  const GpkgGeometryParser();

  /// פירוש LINESTRING (כבישים) → רשימת נקודות
  List<LatLng> parseLineString(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final is3857 = _isEpsg3857(data);
    final wkbOffset = _getWkbOffset(data);
    return _readWkbLineString(data, wkbOffset, is3857);
  }

  /// פירוש POINT (מקומות, POI) → נקודה
  LatLng parsePoint(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final is3857 = _isEpsg3857(data);
    final wkbOffset = _getWkbOffset(data);
    return _readWkbPoint(data, wkbOffset, is3857);
  }

  /// פירוש שטח (POLYGON או MULTIPOLYGON) → רשימת פוליגונים, כל פוליגון = רשימת טבעות.
  /// בודק את סוג הגיאומטריה בפועל מתוך ה-WKB במקום להניח אותו, כדי למנוע פירוש שגוי
  /// שמייצר קואורדינטות זבל (וקריסה בשכבת ה-Polygon).
  List<List<List<LatLng>>> parseAreas(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final is3857 = _isEpsg3857(data);
    final wkbOffset = _getWkbOffset(data);
    final geomType = _readGeometryType(data, wkbOffset);
    // מסכה לטיפול בדגלי Z/M של EWKB (סיביות גבוהות)
    switch (geomType & 0xFF) {
      case 3: // POLYGON
        return [_readWkbPolygon(data, wkbOffset, is3857)];
      case 6: // MULTIPOLYGON
        return _readWkbMultiPolygon(data, wkbOffset, is3857);
      default:
        return const [];
    }
  }

  /// חילוץ envelope (bounding box) מהגיאומטריה
  /// מחזיר [minX, maxX, minY, maxY] או null
  List<double>? parseEnvelope(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);

    // בדיקת magic number
    if (bytes.length < 8) return null;
    if (bytes[0] != 0x47 || bytes[1] != 0x50) return null; // "GP"

    final flags = bytes[3];
    final envelopeIndicator = (flags >> 1) & 0x07;

    if (envelopeIndicator == 0) return null;

    // Envelope starts at byte 8
    final endian = (flags & 0x01) == 1 ? Endian.little : Endian.big;
    final minX = data.getFloat64(8, endian);
    final maxX = data.getFloat64(16, endian);
    final minY = data.getFloat64(24, endian);
    final maxY = data.getFloat64(32, endian);

    return [minX, maxX, minY, maxY];
  }

  bool _isEpsg3857(ByteData data) {
    if (data.lengthInBytes < 8) return false;
    final flags = data.getUint8(3);
    final endian = (flags & 0x01) == 1 ? Endian.little : Endian.big;
    final srsId = data.getInt32(4, endian);
    return srsId == 3857;
  }

  /// חישוב offset של ה-WKB בתוך ה-GPKG header
  int _getWkbOffset(ByteData data) {
    // Flags byte
    final flags = data.getUint8(3);
    final envelopeIndicator = (flags >> 1) & 0x07;

    // גודל ה-envelope לפי ה-indicator
    const envelopeSizes = <int, int>{
      0: 0,
      1: 32, // [minX, maxX, minY, maxY]
      2: 48, // + [minZ, maxZ]
      3: 48, // + [minM, maxM]
      4: 64, // + [minZ, maxZ, minM, maxM]
    };

    final envelopeSize = envelopeSizes[envelopeIndicator] ?? 0;
    return 8 + envelopeSize; // 8 = GP(2) + version(1) + flags(1) + srs_id(4)
  }

  /// קריאת סוג הגיאומטריה (geom_type) מתוך כותרת ה-WKB
  int _readGeometryType(ByteData data, int offset) {
    final byteOrder = data.getUint8(offset);
    final endian = byteOrder == 1 ? Endian.little : Endian.big;
    return data.getUint32(offset + 1, endian);
  }

  /// קריאת WKB LINESTRING
  List<LatLng> _readWkbLineString(ByteData data, int offset, bool is3857) {
    final byteOrder = data.getUint8(offset);
    final endian = byteOrder == 1 ? Endian.little : Endian.big;
    // geom_type at offset+1 (should be 2 for LINESTRING)
    final numPoints = data.getUint32(offset + 5, endian);

    final points = <LatLng>[];
    var pos = offset + 9;
    for (var i = 0; i < numPoints; i++) {
      final x = data.getFloat64(pos, endian);
      final y = data.getFloat64(pos + 8, endian);
      points.add(is3857 ? ProjectionUtils.epsg3857To4326(x, y) : LatLng(y, x));
      pos += 16;
    }
    return points;
  }

  /// קריאת WKB POINT
  LatLng _readWkbPoint(ByteData data, int offset, bool is3857) {
    final byteOrder = data.getUint8(offset);
    final endian = byteOrder == 1 ? Endian.little : Endian.big;
    // geom_type at offset+1 (should be 1 for POINT)
    final x = data.getFloat64(offset + 5, endian);
    final y = data.getFloat64(offset + 13, endian);
    return is3857 ? ProjectionUtils.epsg3857To4326(x, y) : LatLng(y, x);
  }

  /// קריאת WKB POLYGON
  List<List<LatLng>> _readWkbPolygon(ByteData data, int offset, bool is3857) {
    final byteOrder = data.getUint8(offset);
    final endian = byteOrder == 1 ? Endian.little : Endian.big;
    // geom_type at offset+1 (should be 3 for POLYGON)
    final numRings = data.getUint32(offset + 5, endian);

    final rings = <List<LatLng>>[];
    var pos = offset + 9;
    for (var r = 0; r < numRings; r++) {
      final numPoints = data.getUint32(pos, endian);
      pos += 4;
      final ring = <LatLng>[];
      for (var i = 0; i < numPoints; i++) {
        final x = data.getFloat64(pos, endian);
        final y = data.getFloat64(pos + 8, endian);
        ring.add(is3857 ? ProjectionUtils.epsg3857To4326(x, y) : LatLng(y, x));
        pos += 16;
      }
      rings.add(ring);
    }
    return rings;
  }

  /// קריאת WKB MULTIPOLYGON
  List<List<List<LatLng>>> _readWkbMultiPolygon(ByteData data, int offset, bool is3857) {
    final byteOrder = data.getUint8(offset);
    final endian = byteOrder == 1 ? Endian.little : Endian.big;
    // geom_type at offset+1 (should be 6 for MULTIPOLYGON)
    final numPolygons = data.getUint32(offset + 5, endian);

    final polygons = <List<List<LatLng>>>[];
    var pos = offset + 9;
    for (var p = 0; p < numPolygons; p++) {
      // כל polygon מתחיל עם WKB header משלו
      final pByteOrder = data.getUint8(pos);
      final pEndian = pByteOrder == 1 ? Endian.little : Endian.big;
      // skip byte_order(1) + geom_type(4)
      final numRings = data.getUint32(pos + 5, pEndian);
      pos += 9;

      final rings = <List<LatLng>>[];
      for (var r = 0; r < numRings; r++) {
        final numPoints = data.getUint32(pos, pEndian);
        pos += 4;
        final ring = <LatLng>[];
        for (var i = 0; i < numPoints; i++) {
          final x = data.getFloat64(pos, pEndian);
          final y = data.getFloat64(pos + 8, pEndian);
          ring.add(is3857 ? ProjectionUtils.epsg3857To4326(x, y) : LatLng(y, x));
          pos += 16;
        }
        rings.add(ring);
      }
      polygons.add(rings);
    }
    return polygons;
  }
}
