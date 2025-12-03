import 'dart:math';

class DistanceCalculator {
  /// Calculate distance between two coordinates in kilometers
  static double calculate(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Earth's radius in km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }

  /// Format distance to human readable string
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1.0) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(2)} km';
  }

  /// Calculate ETA based on distance and speed
  static String calculateETA(double distanceInKm, double speedKmPerHour) {
    if (speedKmPerHour <= 0) {
      return 'Stopped';
    }

    final etaHours = distanceInKm / speedKmPerHour;
    final etaSeconds = etaHours * 3600;

    if (etaSeconds < 60) {
      return '${etaSeconds.toStringAsFixed(0)} sec';
    } else if (etaSeconds < 3600) {
      final etaMinutes = etaSeconds / 60;
      return '${etaMinutes.toStringAsFixed(1)} min';
    } else {
      return '${etaHours.toStringAsFixed(1)} hr';
    }
  }
}
