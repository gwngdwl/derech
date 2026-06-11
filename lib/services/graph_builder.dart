import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/road_segment.dart';
import '../models/route_result.dart';

/// צומת בגרף הניתוב
class GraphNode {
  final int id;
  final double lat;
  final double lon;
  final List<GraphEdge> edges;

  GraphNode({
    required this.id,
    required this.lat,
    required this.lon,
  }) : edges = [];

  LatLng get latLng => LatLng(lat, lon);
}

/// קשת בגרף הניתוב
class GraphEdge {
  final int targetNodeId;
  final double distanceMeters;
  final double durationSeconds;
  final String roadName;
  final String fclass;
  final List<LatLng> geometry;

  const GraphEdge({
    required this.targetNodeId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.roadName,
    required this.fclass,
    required this.geometry,
  });
}

/// בונה גרף ניתוב מקטעי כביש
class GraphBuilder {
  // דיוק ל-snapping של צמתים (בערך 1 מטר)
  static const double _snapPrecision = 0.00001;

  /// בניית גרף מרשימת קטעי כביש
  /// מריצים ב-Isolate נפרד
  static RoutingGraph build(List<RoadSegment> roads, RoutingMode mode) {
    final stopwatch = Stopwatch()..start();

    final nodeMap = <String, int>{}; // key → node id
    final nodes = <GraphNode>[];

    int getOrCreateNode(double lat, double lon) {
      // Snap coordinates to grid
      final snapLat = (lat / _snapPrecision).round() * _snapPrecision;
      final snapLon = (lon / _snapPrecision).round() * _snapPrecision;
      final key = '${snapLat.toStringAsFixed(5)},${snapLon.toStringAsFixed(5)}';

      if (nodeMap.containsKey(key)) {
        return nodeMap[key]!;
      }

      final id = nodes.length;
      nodeMap[key] = id;
      nodes.add(GraphNode(id: id, lat: snapLat, lon: snapLon));
      return id;
    }

    const distanceCalc = Distance();
    int edgeCount = 0;

    for (final road in roads) {
      // סינון לפי מצב ניתוב
      if (mode == RoutingMode.car && !road.isDriveable) continue;
      if (mode == RoutingMode.bicycle && !road.isCycleable) continue;
      // הליכה — הכל מותר

      if (road.points.length < 2) continue;

      final startPoint = road.points.first;
      final endPoint = road.points.last;

      final startNodeId =
          getOrCreateNode(startPoint.latitude, startPoint.longitude);
      final endNodeId =
          getOrCreateNode(endPoint.latitude, endPoint.longitude);

      if (startNodeId == endNodeId) continue;

      // חישוב מרחק
      double dist = 0;
      for (int i = 0; i < road.points.length - 1; i++) {
        dist += distanceCalc.as(
            LengthUnit.Meter, road.points[i], road.points[i + 1]);
      }

      // חישוב זמן
      final speedKmh = mode == RoutingMode.walk
          ? 5.0
          : mode == RoutingMode.bicycle
              ? min(25.0, road.effectiveSpeed.toDouble())
              : road.effectiveSpeed.toDouble();
      final duration = dist / (speedKmh * 1000 / 3600);

      // קשת קדימה
      nodes[startNodeId].edges.add(GraphEdge(
        targetNodeId: endNodeId,
        distanceMeters: dist,
        durationSeconds: duration,
        roadName: road.name,
        fclass: road.fclass,
        geometry: road.points,
      ));
      edgeCount++;

      // קשת חזרה (אם לא חד-כיווני)
      if (!road.oneway) {
        nodes[endNodeId].edges.add(GraphEdge(
          targetNodeId: startNodeId,
          distanceMeters: dist,
          durationSeconds: duration,
          roadName: road.name,
          fclass: road.fclass,
          geometry: road.points.reversed.toList(),
        ));
        edgeCount++;
      }
    }

    stopwatch.stop();
    debugPrint(
        'גרף נבנה: ${nodes.length} צמתים, $edgeCount קשתות (${stopwatch.elapsedMilliseconds}ms)');

    return RoutingGraph(nodes: nodes);
  }
}

/// גרף ניתוב עם KD-Tree לחיפוש צמתים קרובים
class RoutingGraph {
  final List<GraphNode> nodes;

  RoutingGraph({required this.nodes});

  /// מציאת הצומת הקרוב ביותר לנקודה
  int findNearestNode(double lat, double lon) {
    int bestId = 0;
    double bestDist = double.infinity;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final dlat = node.lat - lat;
      final dlon = node.lon - lon;
      final dist = dlat * dlat + dlon * dlon;
      if (dist < bestDist) {
        bestDist = dist;
        bestId = i;
      }
    }
    return bestId;
  }
}
