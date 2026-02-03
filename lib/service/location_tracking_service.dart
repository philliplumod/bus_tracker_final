import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/entities/rider_location_update.dart';
import '../domain/entities/user.dart';
import '../core/utils/eta_service.dart';
import '../domain/entities/terminal.dart';

/// Service to manage periodic location tracking for riders
class LocationTrackingService {
  Timer? _trackingTimer;
  StreamController<RiderLocationUpdate>? _locationController;
  Position? _lastPosition;
  User? _currentRider;

  static const Duration _updateInterval = Duration(seconds: 5);
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update when moved 5 meters
  );

  /// Start tracking location for a rider
  Future<void> startTracking(User rider) async {
    if (_trackingTimer != null) {
      debugPrint('⚠️ Location tracking already active');
      return;
    }

    _currentRider = rider;
    _locationController = StreamController<RiderLocationUpdate>.broadcast();

    // Check and request permissions
    final permission = await _checkAndRequestPermissions();
    if (!permission) {
      throw Exception('Location permissions denied');
    }

    debugPrint('🚀 Starting location tracking for rider: ${rider.name}');

    // Start periodic updates
    _trackingTimer = Timer.periodic(_updateInterval, (_) => _captureLocation());

    // Capture first location immediately
    await _captureLocation();
  }

  /// Stop tracking location
  void stopTracking() {
    debugPrint('🛑 Stopping location tracking');
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _locationController?.close();
    _locationController = null;
    _lastPosition = null;
    _currentRider = null;
  }

  /// Get the stream of location updates
  Stream<RiderLocationUpdate>? get locationStream =>
      _locationController?.stream;

  /// Check if tracking is active
  bool get isTracking => _trackingTimer != null && _trackingTimer!.isActive;

  /// Capture current location and create update
  Future<void> _captureLocation() async {
    try {
      if (_currentRider == null) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      // Calculate speed and heading
      final speed = position.speed * 3.6; // Convert m/s to km/h
      final heading = position.heading; // Already in degrees

      // Calculate ETA to destination if available
      double? estimatedDuration;
      if (_currentRider!.destinationTerminalLat != null &&
          _currentRider!.destinationTerminalLng != null) {
        final terminal = Terminal(
          id: _currentRider!.destinationTerminal ?? 'unknown',
          name: _currentRider!.destinationTerminal ?? 'Destination',
          latitude: _currentRider!.destinationTerminalLat!,
          longitude: _currentRider!.destinationTerminalLng!,
        );

        estimatedDuration = ETAService.calculateETAToTerminal(
          currentLat: position.latitude,
          currentLng: position.longitude,
          terminal: terminal,
          currentSpeed: speed > 0 ? speed : null,
        );
      }

      final update = RiderLocationUpdate(
        userId: _currentRider!.id,
        busId: _currentRider!.busName ?? 'unknown',
        routeId: _currentRider!.assignedRoute ?? 'unknown',
        busRouteAssignmentId: _currentRider!.busRouteId ?? 'unknown',
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speed,
        heading: heading >= 0 ? heading : 0, // Handle invalid heading
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        destinationTerminalId: _currentRider!.destinationTerminal,
        estimatedDurationMinutes: estimatedDuration,
      );

      _lastPosition = position;
      _locationController?.add(update);

      debugPrint(
        '📍 Location update: Lat=${position.latitude.toStringAsFixed(6)}, '
        'Lng=${position.longitude.toStringAsFixed(6)}, '
        'Speed=${speed.toStringAsFixed(1)} km/h, '
        'Heading=${heading.toStringAsFixed(0)}°',
      );
    } catch (e) {
      debugPrint('❌ Error capturing location: $e');
    }
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions permanently denied');
      return false;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      return false;
    }

    return true;
  }
}
