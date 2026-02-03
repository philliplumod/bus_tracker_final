import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/rider_location_update_model.dart';

abstract class RiderLocationRemoteDataSource {
  /// Store location update in Firebase
  Future<void> storeLocationUpdate(RiderLocationUpdateModel update);

  /// Get location history for a rider
  Future<List<RiderLocationUpdateModel>> getLocationHistory({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  });

  /// Watch real-time location updates for a specific bus
  Stream<RiderLocationUpdateModel?> watchBusLocation(String busName);

  /// Get all active buses with their current locations
  Stream<Map<String, dynamic>> watchAllActiveBuses();
}

class RiderLocationRemoteDataSourceImpl
    implements RiderLocationRemoteDataSource {
  final DatabaseReference _dbRef;

  RiderLocationRemoteDataSourceImpl({DatabaseReference? dbRef})
    : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  @override
  Future<void> storeLocationUpdate(RiderLocationUpdateModel update) async {
    try {
      // Store in rider location path: riders/{userId}/location/{timestamp}
      final riderLocationRef = _dbRef
          .child('riders')
          .child(update.userId)
          .child('location')
          .child(update.timestamp.millisecondsSinceEpoch.toString());

      // Store location data
      await riderLocationRef.set(update.toFirebaseJson());

      // Store current location and trip details at rider level for quick access
      await _dbRef.child('riders').child(update.userId).update({
        'userName': update.userName,
        'busName': update.busName,
        'routeName': update.routeName,
        'busRouteAssignmentId': update.busRouteAssignmentId,
        'currentLocation': {
          'latitude': update.latitude,
          'longitude': update.longitude,
          'speed': update.speed,
          'heading': update.heading,
          'accuracy': update.accuracy,
        },
        'startingTerminal': {
          'name': update.startingTerminalName,
          'latitude': update.startingTerminalLat,
          'longitude': update.startingTerminalLng,
        },
        'destinationTerminal': {
          'name': update.destinationTerminalName,
          'latitude': update.destinationTerminalLat,
          'longitude': update.destinationTerminalLng,
        },
        'lastUpdate': update.timestamp.toIso8601String(),
      });

      // Store in bus tracking path for easy passenger lookup:
      // active_buses/{busName}
      await _dbRef.child('active_buses').child(update.busName).update({
        'busName': update.busName,
        'routeName': update.routeName,
        'riderId': update.userId,
        'riderName': update.userName,
        'currentLocation': {
          'latitude': update.latitude,
          'longitude': update.longitude,
          'speed': update.speed,
          'heading': update.heading,
          'accuracy': update.accuracy,
        },
        'startingTerminal': {
          'name': update.startingTerminalName,
          'latitude': update.startingTerminalLat,
          'longitude': update.startingTerminalLng,
        },
        'destinationTerminal': {
          'name': update.destinationTerminalName,
          'latitude': update.destinationTerminalLat,
          'longitude': update.destinationTerminalLng,
        },
        'lastUpdate': update.timestamp.toIso8601String(),
      });

      debugPrint(
        '✅ Location update stored in Firebase for rider: ${update.userName} on bus: ${update.busName}',
      );
      debugPrint('   📍 Location: (${update.latitude}, ${update.longitude})');
      debugPrint(
        '   🚏 Route: ${update.startingTerminalName} → ${update.destinationTerminalName}',
      );
    } catch (e) {
      debugPrint('❌ Error storing location update: $e');
      throw Exception('Failed to store location update: $e');
    }
  }

  @override
  Future<List<RiderLocationUpdateModel>> getLocationHistory({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      Query query = _dbRef.child('rider_tracking').child(userId);

      if (startTime != null) {
        query = query.orderByKey().startAt(
          startTime.millisecondsSinceEpoch.toString(),
        );
      }

      if (endTime != null) {
        query = query.orderByKey().endAt(
          endTime.millisecondsSinceEpoch.toString(),
        );
      }

      if (limit != null) {
        query = query.limitToLast(limit);
      }

      final snapshot = await query.get();

      if (snapshot.value == null || snapshot.value is! Map) {
        return [];
      }

      final data = snapshot.value as Map<Object?, Object?>;
      final updates = <RiderLocationUpdateModel>[];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            final update = RiderLocationUpdateModel.fromJson(
              Map<String, dynamic>.from(value),
            );
            updates.add(update);
          } catch (e) {
            debugPrint('Error parsing location update: $e');
          }
        }
      });

      return updates;
    } catch (e) {
      throw Exception('Failed to get location history: $e');
    }
  }

  @override
  Stream<RiderLocationUpdateModel?> watchBusLocation(String busName) {
    return _dbRef.child('active_buses').child(busName).onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        return null;
      }

      try {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Extract current location
        final currentLocation = data['currentLocation'] as Map?;
        if (currentLocation == null) return null;

        // Extract terminal data
        final startingTerminal = data['startingTerminal'] as Map?;
        final destinationTerminal = data['destinationTerminal'] as Map?;

        return RiderLocationUpdateModel(
          userId: data['riderId'] as String,
          userName: data['riderName'] as String,
          busName: data['busName'] as String,
          routeName: data['routeName'] as String,
          busRouteAssignmentId: null,
          latitude: (currentLocation['latitude'] as num).toDouble(),
          longitude: (currentLocation['longitude'] as num).toDouble(),
          speed: (currentLocation['speed'] as num?)?.toDouble() ?? 0.0,
          heading: (currentLocation['heading'] as num?)?.toDouble() ?? 0.0,
          timestamp: DateTime.parse(data['lastUpdate'] as String),
          accuracy: (currentLocation['accuracy'] as num?)?.toDouble(),
          startingTerminalName: startingTerminal?['name'] as String?,
          startingTerminalLat:
              (startingTerminal?['latitude'] as num?)?.toDouble(),
          startingTerminalLng:
              (startingTerminal?['longitude'] as num?)?.toDouble(),
          destinationTerminalName: destinationTerminal?['name'] as String?,
          destinationTerminalLat:
              (destinationTerminal?['latitude'] as num?)?.toDouble(),
          destinationTerminalLng:
              (destinationTerminal?['longitude'] as num?)?.toDouble(),
        );
      } catch (e) {
        debugPrint('Error parsing bus location: $e');
        return null;
      }
    });
  }

  @override
  Stream<Map<String, dynamic>> watchAllActiveBuses() {
    return _dbRef.child('active_buses').onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        return <String, dynamic>{};
      }

      try {
        final data = snapshot.value as Map<Object?, Object?>;
        final activeBuses = <String, dynamic>{};

        data.forEach((busKey, busData) {
          if (busData is Map) {
            try {
              final busName = busKey.toString();
              final busInfo = Map<String, dynamic>.from(busData);

              // Extract current location
              final currentLocation = busInfo['currentLocation'];
              final startingTerminal = busInfo['startingTerminal'];
              final destinationTerminal = busInfo['destinationTerminal'];

              activeBuses[busName] = {
                'busName': busInfo['busName'],
                'routeName': busInfo['routeName'],
                'riderId': busInfo['riderId'],
                'riderName': busInfo['riderName'],
                'currentLocation':
                    currentLocation != null
                        ? Map<String, dynamic>.from(currentLocation)
                        : null,
                'startingTerminal':
                    startingTerminal != null
                        ? Map<String, dynamic>.from(startingTerminal)
                        : null,
                'destinationTerminal':
                    destinationTerminal != null
                        ? Map<String, dynamic>.from(destinationTerminal)
                        : null,
                'lastUpdate': busInfo['lastUpdate'],
              };
            } catch (e) {
              debugPrint('Error parsing bus data for $busKey: $e');
            }
          }
        });

        debugPrint('📍 Active buses streaming: ${activeBuses.length} buses');
        return activeBuses;
      } catch (e) {
        debugPrint('❌ Error watching active buses: $e');
        return <String, dynamic>{};
      }
    });
  }
}
