import 'dart:math';
import '../entities/terminal.dart';
import '../entities/route.dart';

class ETAService {
  /// Calculate estimated time of arrival to a terminal in minutes
  ///
  /// [currentLat] and [currentLng] are the current location coordinates
  /// [terminal] is the destination terminal
  /// [currentSpeed] is the current speed in km/h
  /// [route] is optional route information for better estimation
  static double calculateETAToTerminal({
    required double currentLat,
    required double currentLng,
    required Terminal terminal,
    double? currentSpeed,
    BusRoute? route,
  }) {
    // Calculate distance to terminal in km
    final distanceKm = _calculateDistance(
      currentLat,
      currentLng,
      terminal.latitude,
      terminal.longitude,
    );

    // If we have route information and we're on that route, use route-based calculation
    if (route != null && currentSpeed != null && currentSpeed > 0) {
      // Use current speed for calculation (converting km/h to km/min)
      final speedKmPerMin = currentSpeed / 60;
      return distanceKm / speedKmPerMin;
    }

    // Fallback: use average bus speed of 30 km/h in urban areas
    const double averageSpeedKmPerHour = 30.0;
    final speedKmPerMin = averageSpeedKmPerHour / 60;
    return distanceKm / speedKmPerMin;
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Format ETA in minutes to a readable string
  static String formatETA(double minutes) {
    if (minutes < 1) {
      return 'Arriving soon';
    } else if (minutes < 60) {
      return '${minutes.round()} min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = (minutes % 60).round();
      if (remainingMinutes == 0) {
        return '$hours hr';
      }
      return '$hours hr $remainingMinutes min';
    }
  }

  /// Calculate progress percentage along a route
  /// Returns 0-100 representing how far along the route the bus is
  static double calculateRouteProgress({
    required double currentLat,
    required double currentLng,
    required BusRoute route,
  }) {
    // Distance from starting terminal
    final distanceFromStart = _calculateDistance(
      route.startingTerminal.latitude,
      route.startingTerminal.longitude,
      currentLat,
      currentLng,
    );

    // Total route distance
    final totalDistance =
        route.distanceKm ??
        _calculateDistance(
          route.startingTerminal.latitude,
          route.startingTerminal.longitude,
          route.destinationTerminal.latitude,
          route.destinationTerminal.longitude,
        );

    if (totalDistance == 0) return 0;

    // Calculate percentage (capped at 100%)
    final progress = (distanceFromStart / totalDistance) * 100;
    return progress.clamp(0, 100);
  }

  /// Check if a location is near a terminal (within threshold)
  static bool isNearTerminal({
    required double currentLat,
    required double currentLng,
    required Terminal terminal,
    double thresholdKm = 0.5, // 500 meters by default
  }) {
    final distance = _calculateDistance(
      currentLat,
      currentLng,
      terminal.latitude,
      terminal.longitude,
    );
    return distance <= thresholdKm;
  }

  /// Calculate remaining distance to destination terminal
  static double calculateRemainingDistance({
    required double currentLat,
    required double currentLng,
    required Terminal destinationTerminal,
  }) {
    return _calculateDistance(
      currentLat,
      currentLng,
      destinationTerminal.latitude,
      destinationTerminal.longitude,
    );
  }
}
