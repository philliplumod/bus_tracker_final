import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service to fetch live bus locations from Firebase Realtime Database
class LiveBusLocationService {
  final DatabaseReference _dbRef;
  final Map<String, StreamSubscription> _subscriptions = {};

  LiveBusLocationService({DatabaseReference? dbRef})
    : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  /// Stream of all live bus locations
  /// Structure: {busId: {latitude: double, longitude: double, speed: double, ...}}
  Stream<Map<String, Map<String, double>>> watchAllBusLocations() {
    final controller =
        StreamController<Map<String, Map<String, double>>>.broadcast();

    // Listen to /buses node
    final subscription = _dbRef.child('buses').onValue.listen((event) {
      try {
        if (event.snapshot.value == null) {
          controller.add({});
          return;
        }

        final busesData = event.snapshot.value as Map<Object?, Object?>;
        final locations = <String, Map<String, double>>{};

        for (final entry in busesData.entries) {
          final busId = entry.key as String;
          final busData = entry.value as Map<Object?, Object?>;

          // Get location data
          if (busData['location'] != null) {
            final locationData = busData['location'] as Map<Object?, Object?>;

            // Each bus can have multiple riders, use the first available location
            for (final locationEntry in locationData.entries) {
              final riderLocation =
                  locationEntry.value as Map<Object?, Object?>;

              if (riderLocation['latitude'] != null &&
                  riderLocation['longitude'] != null) {
                locations[busId] = {
                  'latitude': (riderLocation['latitude'] as num).toDouble(),
                  'longitude': (riderLocation['longitude'] as num).toDouble(),
                  'speed':
                      riderLocation['speed'] != null
                          ? (riderLocation['speed'] as num).toDouble()
                          : 0.0,
                  'heading':
                      riderLocation['heading'] != null
                          ? (riderLocation['heading'] as num).toDouble()
                          : 0.0,
                  'accuracy':
                      riderLocation['accuracy'] != null
                          ? (riderLocation['accuracy'] as num).toDouble()
                          : 0.0,
                };
                break; // Use first rider location
              }
            }
          }
        }

        controller.add(locations);
        debugPrint('📍 Updated ${locations.length} bus locations');
      } catch (e) {
        debugPrint('❌ Error processing bus locations: $e');
        controller.addError(e);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Get live location for a specific bus
  Stream<Map<String, double>?> watchBusLocation(String busId) {
    final controller = StreamController<Map<String, double>?>.broadcast();

    final path = 'buses/$busId/location';
    final subscription = _dbRef.child(path).onValue.listen((event) {
      try {
        if (event.snapshot.value == null) {
          controller.add(null);
          return;
        }

        final locationData = event.snapshot.value as Map<Object?, Object?>;

        // Get first rider's location
        for (final entry in locationData.entries) {
          final riderLocation = entry.value as Map<Object?, Object?>;

          if (riderLocation['latitude'] != null &&
              riderLocation['longitude'] != null) {
            controller.add({
              'latitude': (riderLocation['latitude'] as num).toDouble(),
              'longitude': (riderLocation['longitude'] as num).toDouble(),
              'speed':
                  riderLocation['speed'] != null
                      ? (riderLocation['speed'] as num).toDouble()
                      : 0.0,
              'heading':
                  riderLocation['heading'] != null
                      ? (riderLocation['heading'] as num).toDouble()
                      : 0.0,
              'accuracy':
                  riderLocation['accuracy'] != null
                      ? (riderLocation['accuracy'] as num).toDouble()
                      : 0.0,
            });
            return;
          }
        }

        controller.add(null);
      } catch (e) {
        debugPrint('❌ Error getting bus $busId location: $e');
        controller.addError(e);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Get snapshot of all bus locations (one-time fetch)
  Future<Map<String, Map<String, double>>> getAllBusLocations() async {
    try {
      final snapshot = await _dbRef.child('buses').get();

      if (snapshot.value == null) {
        return {};
      }

      final busesData = snapshot.value as Map<Object?, Object?>;
      final locations = <String, Map<String, double>>{};

      for (final entry in busesData.entries) {
        final busId = entry.key as String;
        final busData = entry.value as Map<Object?, Object?>;

        if (busData['location'] != null) {
          final locationData = busData['location'] as Map<Object?, Object?>;

          // Get first rider location
          for (final locationEntry in locationData.entries) {
            final riderLocation = locationEntry.value as Map<Object?, Object?>;

            if (riderLocation['latitude'] != null &&
                riderLocation['longitude'] != null) {
              locations[busId] = {
                'latitude': (riderLocation['latitude'] as num).toDouble(),
                'longitude': (riderLocation['longitude'] as num).toDouble(),
                'speed':
                    riderLocation['speed'] != null
                        ? (riderLocation['speed'] as num).toDouble()
                        : 0.0,
                'heading':
                    riderLocation['heading'] != null
                        ? (riderLocation['heading'] as num).toDouble()
                        : 0.0,
                'accuracy':
                    riderLocation['accuracy'] != null
                        ? (riderLocation['accuracy'] as num).toDouble()
                        : 0.0,
              };
              break;
            }
          }
        }
      }

      debugPrint('✅ Fetched ${locations.length} bus locations');
      return locations;
    } catch (e) {
      debugPrint('❌ Error fetching bus locations: $e');
      return {};
    }
  }

  /// Get snapshot of specific bus location
  Future<Map<String, double>?> getBusLocation(String busId) async {
    try {
      final snapshot = await _dbRef.child('buses/$busId/location').get();

      if (snapshot.value == null) {
        return null;
      }

      final locationData = snapshot.value as Map<Object?, Object?>;

      // Get first rider location
      for (final entry in locationData.entries) {
        final riderLocation = entry.value as Map<Object?, Object?>;

        if (riderLocation['latitude'] != null &&
            riderLocation['longitude'] != null) {
          return {
            'latitude': (riderLocation['latitude'] as num).toDouble(),
            'longitude': (riderLocation['longitude'] as num).toDouble(),
            'speed':
                riderLocation['speed'] != null
                    ? (riderLocation['speed'] as num).toDouble()
                    : 0.0,
            'heading':
                riderLocation['heading'] != null
                    ? (riderLocation['heading'] as num).toDouble()
                    : 0.0,
            'accuracy':
                riderLocation['accuracy'] != null
                    ? (riderLocation['accuracy'] as num).toDouble()
                    : 0.0,
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching bus $busId location: $e');
      return null;
    }
  }

  /// Dispose all subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
