import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  /// Generate polyline points between two locations
  static List<LatLng> generateRoute(LatLng start, LatLng end) {
    // For now, we'll create a simple straight line
    // In production, you'd integrate with Google Directions API
    return [start, end];
  }

  /// Calculate bearing/direction between two points
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * 3.14159265359 / 180;
    final lat2 = end.latitude * 3.14159265359 / 180;
    final dLon = (end.longitude - start.longitude) * 3.14159265359 / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * 180 / 3.14159265359;

    return (bearing + 360) % 360;
  }

  /// Get direction name from bearing
  static String getDirectionName(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'North';
    if (bearing >= 22.5 && bearing < 67.5) return 'Northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'East';
    if (bearing >= 112.5 && bearing < 157.5) return 'Southeast';
    if (bearing >= 157.5 && bearing < 202.5) return 'South';
    if (bearing >= 202.5 && bearing < 247.5) return 'Southwest';
    if (bearing >= 247.5 && bearing < 292.5) return 'West';
    if (bearing >= 292.5 && bearing < 337.5) return 'Northwest';
    return 'Unknown';
  }

  static double sin(double value) => _sin(value);
  static double cos(double value) => _cos(value);
  static double atan2(double y, double x) => _atan2(y, x);

  static double _sin(double x) {
    // Taylor series approximation for sin
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) {
    // Taylor series approximation for cos
    double result = 1;
    double term = 1;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  static double _atan(double x) {
    // Simple atan approximation
    if (x > 1) return 3.14159265359 / 2 - _atan(1 / x);
    if (x < -1) return -3.14159265359 / 2 - _atan(1 / x);

    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x * (2 * i - 1) / (2 * i + 1);
      result += term;
    }
    return result;
  }
}
