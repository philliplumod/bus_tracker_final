import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/entities/rider_location_update.dart';
import '../domain/entities/user.dart';
import '../domain/entities/user_assignment.dart';

/// Service to manage periodic location tracking for riders with Firebase sync
class LocationTrackingService {
  Timer? _trackingTimer;
  StreamController<RiderLocationUpdate>? _locationController;
  Position? _lastPosition;
  User? _currentRider;
  UserAssignment? _currentAssignment;
  final DatabaseReference _dbRef;

  static const Duration _updateInterval = Duration(seconds: 2); // 2 seconds
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update when moved 5 meters
  );

  LocationTrackingService({DatabaseReference? dbRef})
    : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  /// Start tracking location for a rider with their assignment
  Future<void> startTracking(User rider, UserAssignment assignment) async {
    if (_trackingTimer != null) {
      debugPrint('⚠️ Location tracking already active');
      return;
    }

    _currentRider = rider;
    _currentAssignment = assignment;
    _locationController = StreamController<RiderLocationUpdate>.broadcast();

    // Check and request permissions
    final permission = await _checkAndRequestPermissions();
    if (!permission) {
      throw Exception('Location permissions denied');
    }

    debugPrint('🚀 Starting location tracking for rider: ${rider.name}');
    debugPrint('   Bus: ${assignment.busName} (ID: ${assignment.busId})');
    debugPrint('   Route: ${assignment.routeName} (ID: ${assignment.routeId})');
    debugPrint('   Assignment ID: ${assignment.id}');

    // Start periodic updates every 2 seconds
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
    _currentAssignment = null;
  }

  /// Get the stream of location updates
  Stream<RiderLocationUpdate>? get locationStream =>
      _locationController?.stream;

  /// Check if tracking is active
  bool get isTracking => _trackingTimer != null && _trackingTimer!.isActive;

  /// Capture current location and create update
  Future<void> _captureLocation() async {
    try {
      if (_currentRider == null || _currentAssignment == null) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      // Calculate speed and heading
      final speed = position.speed * 3.6; // Convert m/s to km/h
      final heading =
          position.heading >= 0 ? position.heading : 0.0; // Ensure non-negative

      // Calculate ETA to destination if available
      double? estimatedDuration;
      if (_currentAssignment!.destinationTerminalId != null) {
        // We'll calculate this based on route data
        // For now, use a simple calculation
        estimatedDuration = null; // Will be calculated in ETA service
      }

      final update = RiderLocationUpdate(
        userId: _currentRider!.id,
        userName: _currentRider!.name,
        busName:
            _currentAssignment!.busName ??
            _currentRider!.busName ??
            'Unknown Bus',
        routeName:
            _currentAssignment!.routeName ??
            _currentRider!.assignedRoute ??
            'Unknown Route',
        busRouteAssignmentId: _currentAssignment!.id,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speed >= 0 ? speed : 0.0,
        heading: heading,
        timestamp: DateTime.now(),
        accuracy: position.accuracy >= 0 ? position.accuracy : null,
        altitude: position.altitude,
        destinationTerminal: _currentRider!.destinationTerminal,
        estimatedDurationMinutes: estimatedDuration,
      );

      debugPrint('📍 Creating location update:');
      debugPrint('   User: ${update.userName}');
      debugPrint('   Bus: ${update.busName}');
      debugPrint('   Route: ${update.routeName}');

      // Write to Firebase
      await _writeToFirebase(update);

      // Emit to stream
      _locationController?.add(update);

      _lastPosition = position;

      debugPrint(
        '📍 Location updated: (${position.latitude}, ${position.longitude})',
      );
      debugPrint('   Speed: ${speed.toStringAsFixed(1)} km/h');
      debugPrint('   Heading: ${heading.toStringAsFixed(0)}°');
    } catch (e) {
      debugPrint('❌ Error capturing location: $e');
    }
  }

  /// Write location update to Firebase Realtime Database
  Future<void> _writeToFirebase(RiderLocationUpdate update) async {
    try {
      // Structure: /riders/{userId}/location
      final path = 'riders/${update.userId}/location';

      final data = {
        'userId': update.userId,
        'userName': update.userName,
        'busName': update.busName,
        'routeName': update.routeName,
        'busRouteAssignmentId': update.busRouteAssignmentId,
        'destinationTerminal': update.destinationTerminal,
        'latitude': update.latitude,
        'longitude': update.longitude,
        'speed': update.speed,
        'heading': update.heading,
        'accuracy': update.accuracy ?? 0,
        'timestamp': update.timestamp.toIso8601String(),
      };

      await _dbRef.child(path).set(data);

      debugPrint('✅ Firebase updated: $path');
    } catch (e) {
      debugPrint('❌ Error writing to Firebase: $e');
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
