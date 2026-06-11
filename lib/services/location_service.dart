import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// שירות מיקום GPS
class LocationService extends ChangeNotifier {
  LatLng? _currentLocation;
  double? _heading;
  bool _isTracking = false;
  bool _hasPermission = false;
  String? _error;

  LatLng? get currentLocation => _currentLocation;
  double? get heading => _heading;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  String? get error => _error;

  /// ברירת מחדל — מרכז ישראל (ירושלים)
  static const defaultLocation = LatLng(31.7683, 35.2137);

  /// אתחול + בקשת הרשאות
  Future<bool> initialize() async {
    // בדיקה אם GPS זמין בפלטפורמה זו
    if (Platform.isWindows || Platform.isLinux) {
      debugPrint('שירות מיקום: פלטפורמת Desktop — שימוש במיקום ברירת מחדל');
      _currentLocation = defaultLocation;
      _hasPermission = true;
      notifyListeners();
      return true;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'שירותי מיקום כבויים';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'הרשאת מיקום נדחתה';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'הרשאת מיקום נחסמה לצמיתות';
        notifyListeners();
        return false;
      }

      _hasPermission = true;

      // קבלת מיקום נוכחי
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _heading = position.heading;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('שגיאת מיקום: $e');
      _error = 'לא ניתן לקבל מיקום';
      _currentLocation = defaultLocation;
      notifyListeners();
      return false;
    }
  }

  /// התחלת מעקב מיקום
  void startTracking() {
    if (_isTracking || !_hasPermission) return;

    if (Platform.isWindows || Platform.isLinux) {
      _isTracking = true;
      notifyListeners();
      return;
    }

    _isTracking = true;
    notifyListeners();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (position) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _heading = position.heading;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('שגיאת מעקב מיקום: $error');
      },
    );
  }

  /// עצירת מעקב מיקום
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
}
