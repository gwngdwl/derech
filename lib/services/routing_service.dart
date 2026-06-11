import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import 'graph_builder.dart';

/// מנוע ניתוב A*
class RoutingService extends ChangeNotifier {
  RoutingGraph? _graph;
  RoutingMode _mode = RoutingMode.car;
  RouteResult? _currentRoute;
  bool _isCalculating = false;
  LatLng? _origin;
  LatLng? _destination;

  RoutingGraph? get graph => _graph;
  RoutingMode get mode => _mode;
  RouteResult? get currentRoute => _currentRoute;
  bool get isCalculating => _isCalculating;
  LatLng? get origin => _origin;
  LatLng? get destination => _destination;
  bool get hasRoute => _currentRoute != null;

  /// הגדרת הגרף
  void setGraph(RoutingGraph graph) {
    _graph = graph;
    notifyListeners();
  }

  /// שינוי מצב ניתוב
  void setMode(RoutingMode mode) {
    _mode = mode;
    notifyListeners();
  }

  /// הגדרת נקודת מוצא
  void setOrigin(LatLng? origin) {
    _origin = origin;
    _currentRoute = null;
    notifyListeners();
  }

  /// הגדרת יעד
  void setDestination(LatLng? destination) {
    _destination = destination;
    _currentRoute = null;
    notifyListeners();
  }

  /// ניקוי מסלול
  void clearRoute() {
    _origin = null;
    _destination = null;
    _currentRoute = null;
    notifyListeners();
  }

  /// חישוב מסלול
  Future<RouteResult?> calculateRoute() async {
    final graph = _graph;
    final origin = _origin;
    final destination = _destination;

    if (graph == null || origin == null || destination == null) return null;

    _isCalculating = true;
    notifyListeners();

    try {
      final result = await compute(_aStarSearch, _AStarParams(
        nodes: graph.nodes,
        originLat: origin.latitude,
        originLon: origin.longitude,
        destLat: destination.latitude,
        destLon: destination.longitude,
      ));

      _currentRoute = result;
      return result;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }
}

/// פרמטרים לחיפוש A* (להעברה ל-Isolate)
class _AStarParams {
  final List<GraphNode> nodes;
  final double originLat;
  final double originLon;
  final double destLat;
  final double destLon;

  const _AStarParams({
    required this.nodes,
    required this.originLat,
    required this.originLon,
    required this.destLat,
    required this.destLon,
  });
}

/// חיפוש A* — רץ ב-Isolate
RouteResult? _aStarSearch(_AStarParams params) {
  final stopwatch = Stopwatch()..start();
  final nodes = params.nodes;

  if (nodes.isEmpty) return null;

  // מציאת צמתים קרובים ביותר
  final startId = _findNearest(nodes, params.originLat, params.originLon);
  final endId = _findNearest(nodes, params.destLat, params.destLon);

  if (startId == endId) return null;

  // A* algorithm
  final gScore = <int, double>{};
  final fScore = <int, double>{};
  final cameFrom = <int, int>{};
  final cameFromEdge = <int, GraphEdge>{};

  gScore[startId] = 0;
  fScore[startId] = _heuristic(nodes[startId], nodes[endId]);

  // Priority queue (min-heap)
  final openSet = PriorityQueue<int>(
      (a, b) => (fScore[a] ?? double.infinity)
          .compareTo(fScore[b] ?? double.infinity));
  openSet.add(startId);

  final inOpenSet = <int>{startId};
  final closedSet = <int>{};

  while (openSet.isNotEmpty) {
    final current = openSet.removeFirst();
    inOpenSet.remove(current);

    if (current == endId) {
      // שחזור המסלול
      return _reconstructRoute(
        nodes, cameFrom, cameFromEdge, startId, endId,
        params.originLat, params.originLon,
        params.destLat, params.destLon,
        stopwatch.elapsedMilliseconds,
      );
    }

    closedSet.add(current);

    for (final edge in nodes[current].edges) {
      if (closedSet.contains(edge.targetNodeId)) continue;

      final tentativeG =
          (gScore[current] ?? double.infinity) + edge.durationSeconds;

      if (tentativeG < (gScore[edge.targetNodeId] ?? double.infinity)) {
        cameFrom[edge.targetNodeId] = current;
        cameFromEdge[edge.targetNodeId] = edge;
        gScore[edge.targetNodeId] = tentativeG;
        fScore[edge.targetNodeId] =
            tentativeG + _heuristic(nodes[edge.targetNodeId], nodes[endId]);

        if (!inOpenSet.contains(edge.targetNodeId)) {
          openSet.add(edge.targetNodeId);
          inOpenSet.add(edge.targetNodeId);
        }
      }
    }
  }

  // לא נמצא מסלול
  return null;
}

/// חישוב הוריסטי — מרחק אווירי בשניות (בהנחת מהירות 120 קמ"ש)
double _heuristic(GraphNode a, GraphNode b) {
  const maxSpeedMs = 120 * 1000 / 3600; // מטר/שנייה
  final dist = _haversine(a.lat, a.lon, b.lat, b.lon);
  return dist / maxSpeedMs;
}

/// מרחק Haversine במטרים
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0; // רדיוס כדור הארץ
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRad(double deg) => deg * pi / 180;

/// מציאת הצומת הקרוב ביותר
int _findNearest(List<GraphNode> nodes, double lat, double lon) {
  int bestId = 0;
  double bestDist = double.infinity;
  for (int i = 0; i < nodes.length; i++) {
    final dlat = nodes[i].lat - lat;
    final dlon = nodes[i].lon - lon;
    final dist = dlat * dlat + dlon * dlon;
    if (dist < bestDist) {
      bestDist = dist;
      bestId = i;
    }
  }
  return bestId;
}

/// שחזור מסלול מתוצאות A*
RouteResult? _reconstructRoute(
  List<GraphNode> nodes,
  Map<int, int> cameFrom,
  Map<int, GraphEdge> cameFromEdge,
  int startId,
  int endId,
  double originLat,
  double originLon,
  double destLat,
  double destLon,
  int elapsedMs,
) {
  final path = <int>[];
  int current = endId;
  while (current != startId) {
    path.add(current);
    final prev = cameFrom[current];
    if (prev == null) return null;
    current = prev;
  }
  path.add(startId);
  path.reversed;

  // בניית polyline מהגיאומטריה של הקשתות
  final polyline = <LatLng>[];
  double totalDistance = 0;
  double totalDuration = 0;
  final instructions = <NavigationInstruction>[];

  // נוסיף את נקודת המוצא
  polyline.add(LatLng(originLat, originLon));

  instructions.add(NavigationInstruction(
    type: ManeuverType.start,
    streetName: '',
    distanceMeters: 0,
    location: LatLng(originLat, originLon),
  ));

  final reversedPath = path.reversed.toList();
  String lastStreetName = '';

  for (int i = 0; i < reversedPath.length - 1; i++) {
    final nodeId = reversedPath[i];
    final nextNodeId = reversedPath[i + 1];
    final edge = cameFromEdge[nextNodeId];
    if (edge == null) continue;

    // הוסף גיאומטריה
    for (final point in edge.geometry) {
      if (polyline.isEmpty ||
          polyline.last.latitude != point.latitude ||
          polyline.last.longitude != point.longitude) {
        polyline.add(point);
      }
    }

    totalDistance += edge.distanceMeters;
    totalDuration += edge.durationSeconds;

    // הוראת ניווט אם שם הרחוב השתנה
    if (edge.roadName.isNotEmpty && edge.roadName != lastStreetName) {
      // חשב כיוון פנייה
      ManeuverType turnType = ManeuverType.straight;
      if (i > 0) {
        final prevEdge = cameFromEdge[reversedPath[i]];
        if (prevEdge != null && prevEdge.geometry.length >= 2 && edge.geometry.length >= 2) {
          turnType = _calculateTurn(
            prevEdge.geometry[prevEdge.geometry.length - 2],
            prevEdge.geometry.last,
            edge.geometry.length > 1 ? edge.geometry[1] : edge.geometry.last,
          );
        }
      }

      instructions.add(NavigationInstruction(
        type: turnType,
        streetName: edge.roadName,
        distanceMeters: totalDistance,
        location: nodes[nodeId].latLng,
      ));
      lastStreetName = edge.roadName;
    }
  }

  // הוסף הוראת הגעה
  instructions.add(NavigationInstruction(
    type: ManeuverType.arrive,
    streetName: '',
    distanceMeters: totalDistance,
    location: LatLng(destLat, destLon),
  ));

  polyline.add(LatLng(destLat, destLon));

  debugPrint('מסלול נמצא: ${(totalDistance / 1000).toStringAsFixed(1)} ק"מ, '
      '${(totalDuration / 60).round()} דק\' (${elapsedMs}ms)');

  return RouteResult(
    polyline: polyline,
    distanceMeters: totalDistance,
    durationSeconds: totalDuration,
    instructions: instructions,
  );
}

/// חישוב סוג פנייה מזוויות
ManeuverType _calculateTurn(LatLng prev, LatLng current, LatLng next) {
  final angle1 = atan2(
    current.longitude - prev.longitude,
    current.latitude - prev.latitude,
  );
  final angle2 = atan2(
    next.longitude - current.longitude,
    next.latitude - current.latitude,
  );

  var turn = (angle2 - angle1) * 180 / pi;
  while (turn > 180) {
    turn -= 360;
  }
  while (turn < -180) {
    turn += 360;
  }

  if (turn.abs() < 20) return ManeuverType.straight;
  if (turn > 20 && turn < 60) return ManeuverType.slightRight;
  if (turn >= 60 && turn < 120) return ManeuverType.right;
  if (turn >= 120) return ManeuverType.sharpRight;
  if (turn < -20 && turn > -60) return ManeuverType.slightLeft;
  if (turn <= -60 && turn > -120) return ManeuverType.left;
  if (turn <= -120) return ManeuverType.sharpLeft;
  return ManeuverType.straight;
}
