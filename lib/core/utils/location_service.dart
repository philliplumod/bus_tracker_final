import 'package:geocoding/geocoding.dart';
import 'dart:math' show sqrt, asin;

class LocationService {
  /// Get human-readable address from latitude and longitude
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      }

      final place = placemarks.first;
      List<String> addressParts = [];

      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.subAdministrativeArea != null &&
          place.subAdministrativeArea!.isNotEmpty) {
        addressParts.add(place.subAdministrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      return addressParts.isNotEmpty
          ? addressParts.join(', ')
          : '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  /// Calculate distance between two coordinates in kilometers using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  static double sin(double x) {
    return _sin(x);
  }

  static double cos(double x) {
    return _cos(x);
  }

  static double _sin(double x) {
    // Taylor series for sin(x)
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) {
    // Taylor series for cos(x)
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static const double pi = 3.14159265359;

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(2)} km';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Estimate travel time based on distance and average speed
  /// Returns time in minutes
  static int estimateTravelTime(
    double distanceKm, {
    double averageSpeedKmh = 30.0,
  }) {
    if (distanceKm <= 0 || averageSpeedKmh <= 0) return 0;
    return (distanceKm / averageSpeedKmh * 60).round();
  }

  /// Format travel time for display
  static String formatTravelTime(int minutes) {
    if (minutes < 1) {
      return '< 1 min';
    } else if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }

  /// Get short location name (city or locality)
  static Future<String> getShortLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Unknown Location';
      }

      final place = placemarks.first;
      return place.locality ??
          place.subAdministrativeArea ??
          'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  /// Calculate ETA (Estimated Time of Arrival) for a bus
  /// Returns formatted ETA string like "5 min" or "15 min"
  static String calculateETA({
    required double userLat,
    required double userLon,
    required double busLat,
    required double busLon,
    double? busSpeed,
  }) {
    // Calculate distance between user and bus
    final distanceKm = calculateDistance(userLat, userLon, busLat, busLon);

    // If bus is very close (less than 100m), return "Arriving"
    if (distanceKm < 0.1) {
      return 'Arriving';
    }

    // Use bus speed if available and reasonable (between 5 and 100 km/h)
    double effectiveSpeed = 25.0; // Default average city speed

    if (busSpeed != null && busSpeed > 5 && busSpeed < 100) {
      effectiveSpeed = busSpeed;
    } else if (busSpeed != null && busSpeed > 0 && busSpeed <= 5) {
      // If bus is moving slowly, use a minimum reasonable speed
      effectiveSpeed = 15.0;
    }

    // Calculate ETA in minutes
    final etaMinutes = estimateTravelTime(
      distanceKm,
      averageSpeedKmh: effectiveSpeed,
    );

    return formatTravelTime(etaMinutes);
  }

  /// Calculate bearing (direction) between two points in degrees
  /// Returns angle from north (0-360)
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final y = sin(dLon) * cos(lat2Rad);
    final x =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  static double atan2(double y, double x) {
    if (x > 0) {
      return atan(y / x);
    } else if (x < 0 && y >= 0) {
      return atan(y / x) + pi;
    } else if (x < 0 && y < 0) {
      return atan(y / x) - pi;
    } else if (x == 0 && y > 0) {
      return pi / 2;
    } else if (x == 0 && y < 0) {
      return -pi / 2;
    }
    return 0;
  }

  static double atan(double x) {
    // Taylor series approximation for atan
    if (x.abs() > 1) {
      final sign = x < 0 ? -1 : 1;
      return sign * (pi / 2 - atan(1 / x.abs()));
    }
    double result = x;
    double term = x;
    for (int i = 1; i < 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  /// Get compass direction from bearing
  static String getCompassDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}
