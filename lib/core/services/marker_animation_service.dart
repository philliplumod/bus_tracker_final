import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sin, atan2, sqrt, pi;

/// Service to handle smooth marker animation along a route
class MarkerAnimationService {
  AnimationController? _controller;
  Animation<double>? _animation;
  Timer? _updateTimer;

  LatLng? _currentPosition;
  LatLng? _targetPosition;
  final List<LatLng> _routePoints;
  int _currentSegmentIndex = 0;

  final void Function(LatLng position, double bearing)? onPositionUpdate;

  MarkerAnimationService({
    required List<LatLng> routePoints,
    this.onPositionUpdate,
  }) : _routePoints = List.from(routePoints) {
    if (_routePoints.isNotEmpty) {
      _currentPosition = _routePoints.first;
    }
  }

  /// Update marker position with new GPS data
  /// Animates smoothly to the new position
  void updatePosition(LatLng newPosition) {
    if (_currentPosition == null) {
      _currentPosition = newPosition;
      _notifyUpdate();
      return;
    }

    // Find the nearest point on route
    final nearestIndex = _findNearestPointOnRoute(newPosition);

    // Update current segment
    if (nearestIndex < _routePoints.length - 1) {
      _currentSegmentIndex = nearestIndex;
      _targetPosition = _routePoints[nearestIndex + 1];
    }

    // Smoothly animate to new position
    _animateToPosition(newPosition);
  }

  /// Animate marker to a target position
  void _animateToPosition(LatLng target) {
    if (_currentPosition == null) return;

    final startPosition = _currentPosition!;
    final distance = _calculateDistance(startPosition, target);

    // Calculate duration based on distance (smoother for longer distances)
    final duration = Duration(
      milliseconds: (distance * 1000).clamp(300, 2000).toInt(),
    );

    _updateTimer?.cancel();

    int elapsedMillis = 0;
    const updateInterval = 16; // ~60 FPS

    _updateTimer = Timer.periodic(
      const Duration(milliseconds: updateInterval),
      (timer) {
        elapsedMillis += updateInterval;
        final progress = (elapsedMillis / duration.inMilliseconds).clamp(
          0.0,
          1.0,
        );

        // Ease-out interpolation for smooth animation
        final easedProgress = _easeOutCubic(progress);

        _currentPosition = LatLng(
          _lerp(startPosition.latitude, target.latitude, easedProgress),
          _lerp(startPosition.longitude, target.longitude, easedProgress),
        );

        _notifyUpdate();

        if (progress >= 1.0) {
          timer.cancel();
          _currentPosition = target;
          _notifyUpdate();
        }
      },
    );
  }

  /// Get remaining route points from current position
  List<LatLng> getRemainingRoute() {
    if (_currentSegmentIndex >= _routePoints.length - 1) {
      return [];
    }
    return _routePoints.sublist(_currentSegmentIndex);
  }

  /// Calculate bearing from current position
  double getCurrentBearing() {
    if (_currentPosition == null || _targetPosition == null) {
      return 0;
    }
    return _calculateBearing(_currentPosition!, _targetPosition!);
  }

  /// Find the nearest point on the route to a given position
  int _findNearestPointOnRoute(LatLng position) {
    if (_routePoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int nearestIndex = _currentSegmentIndex;

    // Search forward from current position
    for (int i = _currentSegmentIndex; i < _routePoints.length; i++) {
      final distance = _calculateDistance(position, _routePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng from, LatLng to) {
    const earthRadius = 6371.0; // km

    final lat1 = from.latitude * pi / 180.0;
    final lat2 = to.latitude * pi / 180.0;
    final dLat = (to.latitude - from.latitude) * pi / 180.0;
    final dLng = (to.longitude - from.longitude) * pi / 180.0;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate bearing from one point to another
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180.0;
    final lat2 = to.latitude * pi / 180.0;
    final dLng = (to.longitude - from.longitude) * pi / 180.0;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final bearing = atan2(y, x) * 180.0 / pi;

    return (bearing + 360) % 360;
  }

  /// Linear interpolation
  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Ease-out cubic easing function for smooth deceleration
  double _easeOutCubic(double t) {
    final f = t - 1.0;
    return f * f * f + 1.0;
  }

  /// Notify position update
  void _notifyUpdate() {
    if (_currentPosition != null && onPositionUpdate != null) {
      onPositionUpdate!(_currentPosition!, getCurrentBearing());
    }
  }

  LatLng? get currentPosition => _currentPosition;

  void dispose() {
    _controller?.dispose();
    _updateTimer?.cancel();
  }
}
