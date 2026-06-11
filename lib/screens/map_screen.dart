import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/route_result.dart';
import '../services/gpkg_service.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../services/search_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_controls.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/search_bar_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 8.0;
  LatLng _currentCenter = const LatLng(31.5, 34.8); // מרכז ישראל

  // נתוני מפה
  List<Polyline> _roadPolylines = [];
  List<Polygon> _areaPolygons = [];
  List<Marker> _placeMarkers = [];
  bool _isLoading = false;

  // ניתוב
  bool _isSelectingOrigin = false;
  bool _isSelectingDestination = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final locationService = context.read<LocationService>();
    await locationService.initialize();
    final loc = locationService.currentLocation;
    if (loc != null) {
      _mapController.move(loc, 13);
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      _loadVisibleData();
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentZoom = camera.zoom;
    _currentCenter = camera.center;
  }

  void _loadVisibleData() {
    if (_isLoading) return;

    final gpkg = context.read<GpkgService>();
    if (!gpkg.isOpen) return;

    setState(() => _isLoading = true);

    final bounds = _mapController.camera.visibleBounds;
    final zoom = _mapController.camera.zoom;

    // טעינת כבישים
    final visibleClasses = AppTheme.getVisibleRoadClasses(zoom);
    final roads = gpkg.getRoadsInBounds(
      bounds.south,
      bounds.west,
      bounds.north,
      bounds.east,
      fclassFilter: visibleClasses,
    );

    final polylines = <Polyline>[];
    for (final road in roads) {
      if (road.points.length < 2) continue;
      polylines.add(Polyline(
        points: road.points,
        strokeWidth: AppTheme.getRoadWidth(road.fclass, zoom),
        color: AppTheme.getRoadColor(road.fclass),
      ));
    }

    // טעינת שטחים (ברמות זום גבוהות)
    final polygons = <Polygon>[];
    if (zoom >= 12) {
      // מים
      final water = gpkg.getAreasInBounds(
        'gis_osm_water_a_free',
        bounds.south, bounds.west, bounds.north, bounds.east,
        limit: 100,
      );
      for (final area in water) {
        polygons.add(Polygon(
          points: area.outerRing,
          color: AppTheme.mapWater.withAlpha(180),
          borderColor: AppTheme.mapWater,
          borderStrokeWidth: 0.5,
        ));
      }

      // שימושי קרקע
      if (zoom >= 13) {
        final landuse = gpkg.getAreasInBounds(
          'gis_osm_landuse_a_free',
          bounds.south, bounds.west, bounds.north, bounds.east,
          limit: 100,
        );
        for (final area in landuse) {
          polygons.add(Polygon(
            points: area.outerRing,
            color: _getLanduseColor(area.fclass),
            borderStrokeWidth: 0,
          ));
        }
      }

      // בניינים
      if (zoom >= 15) {
        final buildings = gpkg.getAreasInBounds(
          'gis_osm_buildings_a_free',
          bounds.south, bounds.west, bounds.north, bounds.east,
          limit: 500,
        );
        for (final area in buildings) {
          polygons.add(Polygon(
            points: area.outerRing,
            color: AppTheme.mapBuilding.withAlpha(200),
            borderColor: AppTheme.mapBuilding.withAlpha(128),
            borderStrokeWidth: 0.3,
          ));
        }
      }
    }

    // מקומות (ברמות זום מסוימות)
    final markers = <Marker>[];
    if (zoom >= 10) {
      final placeFilter = zoom >= 14
          ? null
          : zoom >= 12
              ? {'city', 'town', 'national_capital'}
              : {'city', 'national_capital'};
      final places = gpkg.getPlacesInBounds(
        bounds.south, bounds.west, bounds.north, bounds.east,
        fclassFilter: placeFilter,
        limit: 30,
      );
      for (final place in places) {
        if (place.name.isEmpty) continue;
        markers.add(Marker(
          point: place.location,
          width: 120,
          height: 30,
          child: Text(
            place.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: zoom >= 14 ? 12 : 14,
              fontWeight:
                  place.fclass == 'city' ? FontWeight.bold : FontWeight.w500,
              shadows: const [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ));
      }
    }

    setState(() {
      _roadPolylines = polylines;
      _areaPolygons = polygons;
      _placeMarkers = markers;
      _isLoading = false;
    });
  }

  Color _getLanduseColor(String fclass) {
    switch (fclass) {
      case 'forest':
      case 'park':
      case 'grass':
      case 'recreation_ground':
        return AppTheme.mapGreen.withAlpha(120);
      case 'residential':
        return AppTheme.mapLanduse.withAlpha(80);
      case 'industrial':
      case 'commercial':
        return const Color(0xFF2A2228).withAlpha(100);
      case 'cemetery':
        return const Color(0xFF1E2A20).withAlpha(100);
      default:
        return AppTheme.mapLanduse.withAlpha(60);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    final routing = context.read<RoutingService>();

    if (_isSelectingOrigin) {
      routing.setOrigin(point);
      setState(() => _isSelectingOrigin = false);
      _tryCalculateRoute();
    } else if (_isSelectingDestination) {
      routing.setDestination(point);
      setState(() => _isSelectingDestination = false);
      _tryCalculateRoute();
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    final routing = context.read<RoutingService>();

    if (routing.origin == null) {
      routing.setOrigin(point);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נקודת מוצא נקבעה. לחץ ארוך שוב ליעד.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (routing.destination == null) {
      routing.setDestination(point);
      _tryCalculateRoute();
    } else {
      routing.clearRoute();
    }
  }

  Future<void> _tryCalculateRoute() async {
    final routing = context.read<RoutingService>();
    if (routing.origin != null && routing.destination != null) {
      await routing.calculateRoute();
      if (routing.currentRoute != null && mounted) {
        _fitRouteInView(routing.currentRoute!);
      }
    }
  }

  void _fitRouteInView(RouteResult route) {
    if (route.polyline.isEmpty) return;

    double minLat = 90, maxLat = -90;
    double minLon = 180, maxLon = -180;
    for (final point in route.polyline) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLon = min(minLon, point.longitude);
      maxLon = max(maxLon, point.longitude);
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLon),
          LatLng(maxLat, maxLon),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _goToMyLocation() {
    final loc = context.read<LocationService>().currentLocation;
    if (loc != null) {
      _mapController.move(loc, 15);
    }
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  void _onSearchResultSelected(SearchResult result) {
    _mapController.move(result.location, 15);

    final routing = context.read<RoutingService>();
    if (routing.origin == null) {
      routing.setOrigin(result.location);
    } else {
      routing.setDestination(result.location);
      _tryCalculateRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // שכבת המפה
          _buildMap(),

          // שורת חיפוש
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: DerSearchBar(
              onResultSelected: _onSearchResultSelected,
            ),
          ),

          // כפתורי שליטה
          Positioned(
            right: 16,
            bottom: 200,
            child: MapControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onMyLocation: _goToMyLocation,
              onClearRoute: () {
                context.read<RoutingService>().clearRoute();
              },
            ),
          ),

          // אינדיקטור טעינה
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          // פאנל ניווט
          Consumer<RoutingService>(
            builder: (context, routing, _) {
              if (!routing.hasRoute && routing.origin == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: NavigationPanel(
                  route: routing.currentRoute,
                  origin: routing.origin,
                  destination: routing.destination,
                  mode: routing.mode,
                  isCalculating: routing.isCalculating,
                  onModeChanged: (mode) {
                    routing.setMode(mode);
                    _tryCalculateRoute();
                  },
                  onClear: routing.clearRoute,
                  onSelectOrigin: () =>
                      setState(() => _isSelectingOrigin = true),
                  onSelectDestination: () =>
                      setState(() => _isSelectingDestination = true),
                ),
              );
            },
          ),

          // הודעה על בחירת נקודה
          if (_isSelectingOrigin || _isSelectingDestination)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 40,
              right: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: AppTheme.glassDecoration,
                child: Text(
                  _isSelectingOrigin
                      ? 'הקש על המפה לבחירת נקודת מוצא'
                      : 'הקש על המפה לבחירת יעד',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer2<RoutingService, LocationService>(
      builder: (context, routing, location, _) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: _currentZoom,
            minZoom: 6,
            maxZoom: 18,
            backgroundColor: AppTheme.mapBackground,
            onTap: _onMapTap,
            onLongPress: _onMapLongPress,
            onMapEvent: _onMapEvent,
            onPositionChanged: _onPositionChanged,
            onMapReady: _loadVisibleData,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // שכבת שטחים
            if (_areaPolygons.isNotEmpty)
              PolygonLayer(polygons: _areaPolygons),

            // שכבת כבישים
            if (_roadPolylines.isNotEmpty)
              PolylineLayer(polylines: _roadPolylines),

            // שכבת מסלול
            if (routing.currentRoute != null)
              PolylineLayer(
                polylines: [
                  // outline
                  Polyline(
                    points: routing.currentRoute!.polyline,
                    strokeWidth: 8,
                    color: AppTheme.routeOutline,
                  ),
                  // inner
                  Polyline(
                    points: routing.currentRoute!.polyline,
                    strokeWidth: 5,
                    color: AppTheme.routeColor,
                  ),
                ],
              ),

            // שכבת שמות מקומות
            if (_placeMarkers.isNotEmpty)
              MarkerLayer(markers: _placeMarkers),

            // מרקר מוצא
            if (routing.origin != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: routing.origin!,
                    width: 40,
                    height: 40,
                    child: const _RouteMarker(
                      color: AppTheme.routeColor,
                      icon: Icons.trip_origin,
                    ),
                  ),
                ],
              ),

            // מרקר יעד
            if (routing.destination != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: routing.destination!,
                    width: 40,
                    height: 40,
                    child: const _RouteMarker(
                      color: Colors.red,
                      icon: Icons.location_on,
                    ),
                  ),
                ],
              ),

            // מרקר מיקום נוכחי
            if (location.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: location.currentLocation!,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.routeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.routeColor.withAlpha(128),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _RouteMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _RouteMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(128),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
