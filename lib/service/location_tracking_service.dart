import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/entities/rider_location_update.dart';
import '../domain/entities/user.dart';
import '../domain/entities/user_assignment.dart';
import '../domain/entities/terminal.dart';
import '../core/services/firebase_realtime_service.dart';

/// Service to manage periodic location tracking for riders with Firebase sync
class LocationTrackingService {
  Timer? _trackingTimer;
  StreamController<RiderLocationUpdate>? _locationController;
  Position? _lastPosition;
  User? _currentRider;
  UserAssignment? _currentAssignment;
  Terminal? _startingTerminal;
  Terminal? _destinationTerminal;
  final DatabaseReference _dbRef;
  final FirebaseRealtimeService _firebaseService;

  static const Duration _updateInterval = Duration(seconds: 2); // 2 seconds
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update when moved 5 meters
  );

  LocationTrackingService({
    DatabaseReference? dbRef,
    FirebaseRealtimeService? firebaseService,
  }) : _dbRef = dbRef ?? FirebaseDatabase.instance.ref(),
       _firebaseService =
           firebaseService ?? FirebaseRealtimeService(dbRef: dbRef) {
    debugPrint('🔥 LocationTrackingService initialized');
    _testFirebaseConnectivity();
  }

  /// Test Firebase connectivity
  Future<void> _testFirebaseConnectivity() async {
    try {
      debugPrint(
        '🧪 Testing Firebase connectivity from LocationTrackingService...',
      );
      final isConnected = await _firebaseService.testConnectivity();

      if (isConnected) {
        debugPrint('✅ Firebase is ready for location tracking');
      } else {
        debugPrint('⚠️ Firebase connectivity check failed');
      }
    } catch (e) {
      debugPrint('❌ Firebase connectivity test error: $e');
    }
  }

  /// Start tracking location for a rider with their assignment
  Future<void> startTracking(
    User rider,
    UserAssignment assignment, {
    Terminal? startingTerminal,
    Terminal? destinationTerminal,
  }) async {
    debugPrint('🚀 LocationTrackingService.startTracking called');

    if (_trackingTimer != null) {
      debugPrint('⚠️ Location tracking already active');
      return;
    }

    _currentRider = rider;
    _currentAssignment = assignment;
    _startingTerminal = startingTerminal;
    _destinationTerminal = destinationTerminal;
    _locationController = StreamController<RiderLocationUpdate>.broadcast();

    debugPrint('   Timer status before: ${_trackingTimer?.isActive ?? false}');
    debugPrint('   Controller created: ${_locationController != null}');

    // Check and request permissions
    final permission = await _checkAndRequestPermissions();
    if (!permission) {
      debugPrint('❌ Location permissions denied');
      throw Exception('Location permissions denied');
    }

    debugPrint('✅ Location permissions granted');
    debugPrint('🚀 Starting location tracking for rider: ${rider.name}');
    debugPrint('   Bus: ${assignment.busName} (ID: ${assignment.busId})');
    debugPrint('   Route: ${assignment.routeName} (ID: ${assignment.routeId})');
    debugPrint('   Assignment ID: ${assignment.id}');

    // Start periodic updates every 2 seconds
    _trackingTimer = Timer.periodic(_updateInterval, (_) {
      debugPrint('⏰ Timer fired, calling _captureLocation');
      _captureLocation();
    });

    debugPrint('   Timer started: ${_trackingTimer?.isActive ?? false}');
    debugPrint('   Update interval: ${_updateInterval.inSeconds} seconds');

    // Capture first location immediately
    debugPrint('📍 Capturing initial location...');
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
    _startingTerminal = null;
    _destinationTerminal = null;
  }

  /// Get the stream of location updates
  Stream<RiderLocationUpdate>? get locationStream =>
      _locationController?.stream;

  /// Check if tracking is active
  bool get isTracking => _trackingTimer != null && _trackingTimer!.isActive;

  /// Capture current location and create update
  Future<void> _captureLocation() async {
    try {
      debugPrint('📍 _captureLocation called');

      if (_currentRider == null || _currentAssignment == null) {
        debugPrint(
          '⚠️ No current rider or assignment, skipping location capture',
        );
        return;
      }

      debugPrint('   Current rider: ${_currentRider!.name}');
      debugPrint('   Current assignment: ${_currentAssignment!.id}');

      debugPrint('   Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Location request timed out after 10 seconds');
          throw TimeoutException('Failed to get location within 10 seconds');
        },
      );

      debugPrint(
        '   ✅ Position obtained: (${position.latitude}, ${position.longitude})',
      );
      debugPrint('   Accuracy: ${position.accuracy.toStringAsFixed(1)}m');

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
        // Starting terminal information
        startingTerminalName:
            _startingTerminal?.name ?? _currentAssignment!.startingTerminalName,
        startingTerminalLat: _startingTerminal?.latitude,
        startingTerminalLng: _startingTerminal?.longitude,
        // Destination terminal information
        destinationTerminalName:
            _destinationTerminal?.name ??
            _currentAssignment!.destinationTerminalName,
        destinationTerminalLat: _destinationTerminal?.latitude,
        destinationTerminalLng: _destinationTerminal?.longitude,
      );

      debugPrint('📍 Creating location update:');
      debugPrint('   User: ${update.userName}');
      debugPrint('   Bus: ${update.busName}');
      debugPrint('   Route: ${update.routeName}');
      debugPrint('   Starting: ${update.startingTerminalName}');
      debugPrint('   Destination: ${update.destinationTerminalName}');

      // Emit to stream (Firebase storage handled by bloc through use case)
      _locationController?.add(update);

      _lastPosition = position;

      debugPrint(
        '📍 Location updated: (${position.latitude}, ${position.longitude})',
      );
      debugPrint('   Speed: ${speed.toStringAsFixed(1)} km/h');
      debugPrint('   Heading: ${heading.toStringAsFixed(0)}°');
    } catch (e, stackTrace) {
      debugPrint('❌ Error capturing location: $e');
      debugPrint('   Stack trace: $stackTrace');
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
