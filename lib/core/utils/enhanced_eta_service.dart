import 'package:flutter/foundation.dart';
import '../../domain/entities/terminal.dart';
import 'distance_calculator.dart';

/// Enhanced ETA calculation service with dual ETA support
class EnhancedETAService {
  // Average speeds
  static const double _defaultAverageSpeed = 30.0; // km/h
  static const double _walkingSpeed = 5.0; // km/h

  /// Calculate rider ETA to next terminal
  static Map<String, dynamic> calculateRiderETAToNextTerminal({
    required double currentLat,
    required double currentLng,
    required Terminal nextTerminal,
    required List<Map<String, dynamic>>? waypoints,
    double? currentSpeed,
  }) {
    try {
      // If we have waypoints, find the closest waypoint and calculate to next terminal
      if (waypoints != null && waypoints.isNotEmpty) {
        final distanceToNext = _calculateDistanceAlongRoute(
          currentLat: currentLat,
          currentLng: currentLng,
          destination: nextTerminal,
          waypoints: waypoints,
        );

        final speed = currentSpeed ?? _defaultAverageSpeed;
        final durationMinutes = (distanceToNext / speed) * 60;

        return {
          'distanceKm': distanceToNext,
          'durationMinutes': durationMinutes,
          'etaTimestamp': DateTime.now().add(
            Duration(minutes: durationMinutes.round()),
          ),
        };
      }

      // Fallback to direct distance
      final distance = DistanceCalculator.calculate(
        currentLat,
        currentLng,
        nextTerminal.latitude,
        nextTerminal.longitude,
      );

      final speed = currentSpeed ?? _defaultAverageSpeed;
      final durationMinutes = (distance / speed) * 60;

      return {
        'distanceKm': distance,
        'durationMinutes': durationMinutes,
        'etaTimestamp': DateTime.now().add(
          Duration(minutes: durationMinutes.round()),
        ),
      };
    } catch (e) {
      debugPrint('❌ Error calculating rider ETA to next terminal: $e');
      return {
        'distanceKm': 0.0,
        'durationMinutes': 0.0,
        'etaTimestamp': DateTime.now(),
      };
    }
  }

  /// Calculate rider ETA to destination terminal
  static Map<String, dynamic> calculateRiderETAToDestination({
    required double currentLat,
    required double currentLng,
    required Terminal destination,
    required List<Map<String, dynamic>>? waypoints,
    double? currentSpeed,
    int? routeDurationMinutes,
  }) {
    try {
      // If we have route duration, use it as reference
      if (routeDurationMinutes != null && waypoints != null) {
        final totalRouteDistance = _calculateTotalRouteDistance(waypoints);
        final distanceToDestination = _calculateDistanceAlongRoute(
          currentLat: currentLat,
          currentLng: currentLng,
          destination: destination,
          waypoints: waypoints,
        );

        // Estimate time based on proportion of route remaining
        final proportionRemaining =
            totalRouteDistance > 0
                ? distanceToDestination / totalRouteDistance
                : 1.0;

        final estimatedDuration = routeDurationMinutes * proportionRemaining;

        return {
          'distanceKm': distanceToDestination,
          'durationMinutes': estimatedDuration,
          'etaTimestamp': DateTime.now().add(
            Duration(minutes: estimatedDuration.round()),
          ),
        };
      }

      // Fallback calculation
      final distance = DistanceCalculator.calculate(
        currentLat,
        currentLng,
        destination.latitude,
        destination.longitude,
      );

      final speed = currentSpeed ?? _defaultAverageSpeed;
      final durationMinutes = (distance / speed) * 60;

      return {
        'distanceKm': distance,
        'durationMinutes': durationMinutes,
        'etaTimestamp': DateTime.now().add(
          Duration(minutes: durationMinutes.round()),
        ),
      };
    } catch (e) {
      debugPrint('❌ Error calculating rider ETA to destination: $e');
      return {
        'distanceKm': 0.0,
        'durationMinutes': 0.0,
        'etaTimestamp': DateTime.now(),
      };
    }
  }

  /// Calculate passenger ETA - bus to passenger location
  static Map<String, dynamic> calculateBusToPassengerETA({
    required double busLat,
    required double busLng,
    required double passengerLat,
    required double passengerLng,
    required List<Map<String, dynamic>>? waypoints,
    double? busSpeed,
  }) {
    try {
      final distance = DistanceCalculator.calculate(
        busLat,
        busLng,
        passengerLat,
        passengerLng,
      );

      final speed = busSpeed ?? _defaultAverageSpeed;
      final durationMinutes = (distance / speed) * 60;

      return {
        'distanceKm': distance,
        'durationMinutes': durationMinutes,
        'etaTimestamp': DateTime.now().add(
          Duration(minutes: durationMinutes.round()),
        ),
      };
    } catch (e) {
      debugPrint('❌ Error calculating bus to passenger ETA: $e');
      return {
        'distanceKm': 0.0,
        'durationMinutes': 0.0,
        'etaTimestamp': DateTime.now(),
      };
    }
  }

  /// Calculate passenger ETA - passenger to destination
  static Map<String, dynamic> calculatePassengerToDestinationETA({
    required double passengerLat,
    required double passengerLng,
    required Terminal destination,
    required List<Map<String, dynamic>>? waypoints,
    int? routeDurationMinutes,
  }) {
    try {
      final distance = DistanceCalculator.calculate(
        passengerLat,
        passengerLng,
        destination.latitude,
        destination.longitude,
      );

      // Passenger travel time = bus to passenger + passenger on bus to destination
      // This is simplified - in real scenario, use route-based calculation
      final speed = _defaultAverageSpeed;
      final durationMinutes = (distance / speed) * 60;

      return {
        'distanceKm': distance,
        'durationMinutes': durationMinutes,
        'etaTimestamp': DateTime.now().add(
          Duration(minutes: durationMinutes.round()),
        ),
      };
    } catch (e) {
      debugPrint('❌ Error calculating passenger to destination ETA: $e');
      return {
        'distanceKm': 0.0,
        'durationMinutes': 0.0,
        'etaTimestamp': DateTime.now(),
      };
    }
  }

  /// Calculate distance along route considering waypoints
  static double _calculateDistanceAlongRoute({
    required double currentLat,
    required double currentLng,
    required Terminal destination,
    required List<Map<String, dynamic>> waypoints,
  }) {
    double totalDistance = 0.0;

    // Find closest waypoint to current location
    int closestIndex = _findClosestWaypointIndex(
      currentLat,
      currentLng,
      waypoints,
    );

    // Calculate from current position to closest waypoint
    if (closestIndex < waypoints.length) {
      final waypoint = waypoints[closestIndex];
      totalDistance += DistanceCalculator.calculate(
        currentLat,
        currentLng,
        (waypoint['latitude'] as num).toDouble(),
        (waypoint['longitude'] as num).toDouble(),
      );

      // Calculate through remaining waypoints
      for (int i = closestIndex; i < waypoints.length - 1; i++) {
        final current = waypoints[i];
        final next = waypoints[i + 1];
        totalDistance += DistanceCalculator.calculate(
          (current['latitude'] as num).toDouble(),
          (current['longitude'] as num).toDouble(),
          (next['latitude'] as num).toDouble(),
          (next['longitude'] as num).toDouble(),
        );
      }

      // Add distance from last waypoint to destination
      final lastWaypoint = waypoints.last;
      totalDistance += DistanceCalculator.calculate(
        (lastWaypoint['latitude'] as num).toDouble(),
        (lastWaypoint['longitude'] as num).toDouble(),
        destination.latitude,
        destination.longitude,
      );
    }

    return totalDistance;
  }

  /// Calculate total route distance
  static double _calculateTotalRouteDistance(
    List<Map<String, dynamic>> waypoints,
  ) {
    double total = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final current = waypoints[i];
      final next = waypoints[i + 1];
      total += DistanceCalculator.calculate(
        (current['latitude'] as num).toDouble(),
        (current['longitude'] as num).toDouble(),
        (next['latitude'] as num).toDouble(),
        (next['longitude'] as num).toDouble(),
      );
    }
    return total;
  }

  /// Find index of closest waypoint
  static int _findClosestWaypointIndex(
    double lat,
    double lng,
    List<Map<String, dynamic>> waypoints,
  ) {
    if (waypoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < waypoints.length; i++) {
      final waypoint = waypoints[i];
      final distance = DistanceCalculator.calculate(
        lat,
        lng,
        (waypoint['latitude'] as num).toDouble(),
        (waypoint['longitude'] as num).toDouble(),
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Format duration as readable string
  static String formatDuration(double durationMinutes) {
    if (durationMinutes < 1) {
      return '< 1 min';
    } else if (durationMinutes < 60) {
      return '${durationMinutes.round()} min';
    } else {
      final hours = (durationMinutes / 60).floor();
      final minutes = (durationMinutes % 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  /// Format distance as readable string
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
}
