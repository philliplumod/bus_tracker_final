import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/entities/rider_location_update.dart';
import '../domain/entities/user.dart';
import '../domain/entities/user_assignment.dart';
import '../domain/entities/terminal.dart';
import '../core/services/firebase_realtime_service.dart';

/// Service to manage real-time location tracking for riders with Firebase sync
class LocationTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<RiderLocationUpdate>? _locationController;
  Position? _lastPosition;
  bool _isTrackingActive = false;
  User? _currentRider;
  UserAssignment? _currentAssignment;
  Terminal? _startingTerminal;
  Terminal? _destinationTerminal;
  final DatabaseReference _dbRef;
  final FirebaseRealtimeService _firebaseService;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
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

    if (_isTrackingActive) {
      debugPrint('⚠️ Location tracking already active');
      return;
    }

    _currentRider = rider;
    _currentAssignment = assignment;
    _startingTerminal = startingTerminal;
    _destinationTerminal = destinationTerminal;
    _locationController = StreamController<RiderLocationUpdate>.broadcast();

    debugPrint('   Tracking status before: $_isTrackingActive');
    debugPrint('   Controller created: ${_locationController != null}');

    // Check and request permissions
    final permission = await _checkAndRequestPermissions();
    if (!permission) {
      debugPrint('❌ Location permissions denied');
      _locationController?.close();
      _locationController = null;
      _currentRider = null;
      _currentAssignment = null;
      _startingTerminal = null;
      _destinationTerminal = null;
      throw Exception('Location permissions denied');
    }

    debugPrint('✅ Location permissions granted');
    debugPrint('🚀 Starting location tracking for rider: ${rider.name}');
    debugPrint('   Bus: ${assignment.busName} (ID: ${assignment.busId})');
    debugPrint('   Route: ${assignment.routeName} (ID: ${assignment.routeId})');
    debugPrint('   Assignment ID: ${assignment.id}');

    // Start continuous location stream updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      _handlePosition,
      onError: (error) {
        debugPrint('❌ Position stream error: $error');
      },
    );
    _isTrackingActive = true;

    debugPrint(
      '   Position stream subscribed: ${_positionSubscription != null}',
    );

    // Capture first location immediately
    debugPrint('📍 Capturing initial location...');
    await _captureCurrentLocation();
  }

  /// Stop tracking location
  void stopTracking() {
    debugPrint('🛑 Stopping location tracking');
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationController?.close();
    _locationController = null;
    _lastPosition = null;
    _isTrackingActive = false;
    _currentRider = null;
    _currentAssignment = null;
    _startingTerminal = null;
    _destinationTerminal = null;
  }

  /// Get the stream of location updates
  Stream<RiderLocationUpdate>? get locationStream =>
      _locationController?.stream;

  /// Check if tracking is active
  bool get isTracking => _isTrackingActive;

  /// Capture one location immediately and process it
  Future<void> _captureCurrentLocation() async {
    try {
      debugPrint('📍 _captureCurrentLocation called');

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

      _handlePosition(position);
    } catch (e, stackTrace) {
      debugPrint('❌ Error capturing location: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  void _handlePosition(Position position) {
    if (_currentRider == null || _currentAssignment == null) {
      debugPrint('⚠️ No current rider or assignment, skipping location update');
      return;
    }

    debugPrint(
      '   ✅ Position received: (${position.latitude}, ${position.longitude})',
    );
    debugPrint('   Accuracy: ${position.accuracy.toStringAsFixed(1)}m');

    final speed = position.speed * 3.6;
    final heading = position.heading >= 0 ? position.heading : 0.0;

    double? estimatedDuration;
    if (_currentAssignment!.destinationTerminalId != null) {
      estimatedDuration = null;
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
      startingTerminalName:
          _startingTerminal?.name ?? _currentAssignment!.startingTerminalName,
      startingTerminalLat: _startingTerminal?.latitude,
      startingTerminalLng: _startingTerminal?.longitude,
      destinationTerminalName:
          _destinationTerminal?.name ??
          _currentAssignment!.destinationTerminalName,
      destinationTerminalLat: _destinationTerminal?.latitude,
      destinationTerminalLng: _destinationTerminal?.longitude,
    );

    _locationController?.add(update);
    _lastPosition = position;

    debugPrint(
      '📍 Location updated: (${position.latitude}, ${position.longitude})',
    );
    debugPrint('   Speed: ${speed.toStringAsFixed(1)} km/h');
    debugPrint('   Heading: ${heading.toStringAsFixed(0)}°');
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
