import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service for fetching road-aligned routes using Google Directions API
class DirectionsService {
  // TODO: Replace with your actual Google Maps API Key
  // Get one from: https://console.cloud.google.com/apis/credentials
  // Make sure to enable "Directions API" and "Maps SDK for Android/iOS"
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  final http.Client _client;

  DirectionsService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches route polyline from origin to destination
  /// Returns list of LatLng points representing the road-aligned path
  Future<RouteData?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    if (_apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      debugPrint('⚠️ WARNING: Google Maps API Key not configured');
      // Return a fallback straight line for development
      return RouteData(
        polylinePoints: [origin, destination],
        distanceMeters: 0,
        durationSeconds: 0,
        bounds: LatLngBounds(southwest: origin, northeast: destination),
      );
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&key=$_apiKey',
      );

      debugPrint('🗺️ Fetching route from Directions API...');

      final response = await _client
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Directions API request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          debugPrint('❌ Directions API error: ${data['status']}');
          if (data['error_message'] != null) {
            debugPrint('   Error message: ${data['error_message']}');
          }
          return null;
        }

        final routes = data['routes'] as List;
        if (routes.isEmpty) {
          debugPrint('❌ No routes found');
          return null;
        }

        final route = routes.first;
        final legs = route['legs'] as List;
        if (legs.isEmpty) {
          return null;
        }

        final leg = legs.first;

        // Extract distance and duration
        final distanceMeters = leg['distance']['value'] as int;
        final durationSeconds = leg['duration']['value'] as int;

        // Extract polyline
        final polyline = route['overview_polyline']['points'] as String;
        final polylinePoints = _decodePolyline(polyline);

        // Extract bounds
        final bounds = route['bounds'];
        final southwest = LatLng(
          bounds['southwest']['lat'],
          bounds['southwest']['lng'],
        );
        final northeast = LatLng(
          bounds['northeast']['lat'],
          bounds['northeast']['lng'],
        );

        debugPrint(
          '✅ Route fetched: ${polylinePoints.length} points, '
          '${(distanceMeters / 1000).toStringAsFixed(2)} km, '
          '${(durationSeconds / 60).round()} min',
        );

        return RouteData(
          polylinePoints: polylinePoints,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
          bounds: LatLngBounds(southwest: southwest, northeast: northeast),
        );
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching route: $e');
      return null;
    }
  }

  /// Decodes a polyline string into list of LatLng points
  /// Implementation of Google's polyline encoding algorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void dispose() {
    _client.close();
  }
}

/// Data class for route information
class RouteData {
  final List<LatLng> polylinePoints;
  final int distanceMeters;
  final int durationSeconds;
  final LatLngBounds bounds;

  RouteData({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
  });

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60).round();
}
