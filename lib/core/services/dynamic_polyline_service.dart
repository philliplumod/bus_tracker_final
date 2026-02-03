import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/route.dart';

/// Service for rendering and animating route polylines dynamically
class DynamicPolylineService {
  static const String _routePolylineId = 'route_polyline';
  static const String _traveledPolylineId = 'traveled_polyline';

  /// Build polyline from route data with waypoints
  static Polyline buildRoutePolyline({
    required BusRoute route,
    required bool showTraveled,
    LatLng? currentPosition,
  }) {
    final points = _buildRoutePoints(route);

    return Polyline(
      polylineId: const PolylineId(_routePolylineId),
      points: points,
      color: const Color(0xFF2196F3), // Blue
      width: 5,
      geodesic: true,
      patterns:
          showTraveled && currentPosition != null
              ? [PatternItem.dot, PatternItem.gap(10)]
              : [],
    );
  }

  /// Build traveled portion of polyline (from start to current position)
  static Polyline? buildTraveledPolyline({
    required BusRoute route,
    required LatLng currentPosition,
  }) {
    final allPoints = _buildRoutePoints(route);
    final traveledPoints = _extractTraveledPoints(allPoints, currentPosition);

    if (traveledPoints.length < 2) return null;

    return Polyline(
      polylineId: const PolylineId(_traveledPolylineId),
      points: traveledPoints,
      color: const Color(0xFF4CAF50), // Green
      width: 6,
      geodesic: true,
    );
  }

  /// Build all polylines for a route (full route + traveled portion)
  static Set<Polyline> buildCompletePolylines({
    required BusRoute route,
    LatLng? currentPosition,
  }) {
    final polylines = <Polyline>{};

    // Add main route polyline
    polylines.add(
      buildRoutePolyline(
        route: route,
        showTraveled: currentPosition != null,
        currentPosition: currentPosition,
      ),
    );

    // Add traveled portion if position is available
    if (currentPosition != null) {
      final traveled = buildTraveledPolyline(
        route: route,
        currentPosition: currentPosition,
      );
      if (traveled != null) {
        polylines.add(traveled);
      }
    }

    return polylines;
  }

  /// Build route points from starting terminal → waypoints → destination
  static List<LatLng> _buildRoutePoints(BusRoute route) {
    final points = <LatLng>[];

    // Add starting terminal
    points.add(
      LatLng(route.startingTerminal.latitude, route.startingTerminal.longitude),
    );

    // Add waypoints if available
    if (route.routeData != null && route.routeData!.isNotEmpty) {
      for (final waypoint in route.routeData!) {
        if (waypoint['latitude'] != null && waypoint['longitude'] != null) {
          points.add(
            LatLng(
              (waypoint['latitude'] as num).toDouble(),
              (waypoint['longitude'] as num).toDouble(),
            ),
          );
        }
      }
    }

    // Add destination terminal
    points.add(
      LatLng(
        route.destinationTerminal.latitude,
        route.destinationTerminal.longitude,
      ),
    );

    return points;
  }

  /// Extract points from start to current position
  static List<LatLng> _extractTraveledPoints(
    List<LatLng> allPoints,
    LatLng currentPosition,
  ) {
    if (allPoints.length < 2) return [];

    final traveledPoints = <LatLng>[allPoints.first];

    // Find the segment where current position is
    int closestSegmentIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < allPoints.length - 1; i++) {
      final distance = _distanceToSegment(
        currentPosition,
        allPoints[i],
        allPoints[i + 1],
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSegmentIndex = i;
      }
    }

    // Add all points up to the closest segment
    for (int i = 1; i <= closestSegmentIndex; i++) {
      traveledPoints.add(allPoints[i]);
    }

    // Add current position
    traveledPoints.add(currentPosition);

    return traveledPoints;
  }

  /// Calculate distance from point to line segment
  static double _distanceToSegment(LatLng point, LatLng start, LatLng end) {
    final x = point.latitude;
    final y = point.longitude;
    final x1 = start.latitude;
    final y1 = start.longitude;
    final x2 = end.latitude;
    final y2 = end.longitude;

    final A = x - x1;
    final B = y - y1;
    final C = x2 - x1;
    final D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    double param = -1;

    if (lenSq != 0) {
      param = dot / lenSq;
    }

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    final dx = x - xx;
    final dy = y - yy;

    return sqrt(dx * dx + dy * dy);
  }

  /// Animate marker along polyline
  static Stream<LatLng> animateMarkerAlongRoute({
    required List<LatLng> routePoints,
    required Duration duration,
  }) async* {
    if (routePoints.length < 2) return;

    final totalDuration = duration.inMilliseconds;
    final segmentDuration = totalDuration / (routePoints.length - 1);

    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      final steps = (segmentDuration / 16).round(); // ~60fps

      for (int step = 0; step <= steps; step++) {
        final t = step / steps;
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lng = start.longitude + (end.longitude - start.longitude) * t;

        yield LatLng(lat, lng);
        await Future.delayed(const Duration(milliseconds: 16));
      }
    }
  }

  /// Update polylines when position changes
  static Set<Polyline> updatePolylinesWithPosition({
    required BusRoute route,
    required LatLng currentPosition,
  }) {
    return buildCompletePolylines(
      route: route,
      currentPosition: currentPosition,
    );
  }

  /// Check if position is on route (within threshold)
  static bool isPositionOnRoute({
    required LatLng position,
    required BusRoute route,
    double thresholdKm = 0.5,
  }) {
    final routePoints = _buildRoutePoints(route);

    for (int i = 0; i < routePoints.length - 1; i++) {
      final distance = _distanceToSegment(
        position,
        routePoints[i],
        routePoints[i + 1],
      );

      // Convert threshold from km to degrees (approximate)
      final thresholdDegrees = thresholdKm / 111.0;

      if (distance <= thresholdDegrees) {
        return true;
      }
    }

    return false;
  }

  /// Get bounds for route to fit camera
  static LatLngBounds getRouteBounds(BusRoute route) {
    final points = _buildRoutePoints(route);

    if (points.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(
          route.startingTerminal.latitude,
          route.startingTerminal.longitude,
        ),
        northeast: LatLng(
          route.destinationTerminal.latitude,
          route.destinationTerminal.longitude,
        ),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

// Helper function
double sqrt(double value) =>
    value < 0
        ? 0
        : value.isNaN
        ? 0
        : value;
