import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/rider_location_update_model.dart';
import '../../core/services/firebase_realtime_service.dart';

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
  final FirebaseRealtimeService _firebaseService;

  RiderLocationRemoteDataSourceImpl({
    DatabaseReference? dbRef,
    FirebaseRealtimeService? firebaseService,
  }) : _dbRef = dbRef ?? FirebaseDatabase.instance.ref(),
       _firebaseService =
           firebaseService ?? FirebaseRealtimeService(dbRef: dbRef);

  @override
  Future<void> storeLocationUpdate(RiderLocationUpdateModel update) async {
    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('📍 STORING LOCATION UPDATE TO FIREBASE');
      debugPrint('═══════════════════════════════════════');
      debugPrint('   Rider: ${update.userName}');
      debugPrint('   Bus: ${update.busName}');
      debugPrint('   Route: ${update.routeName}');
      debugPrint('   Location: (${update.latitude}, ${update.longitude})');
      debugPrint('   Speed: ${update.speed.toStringAsFixed(1)} km/h');
      debugPrint(
        '   Route: ${update.startingTerminalName} → ${update.destinationTerminalName}',
      );
      debugPrint('═══════════════════════════════════════');

      final locationData = update.toFirebaseJson();

      // Use the Firebase service to write with retry logic
      await _firebaseService.writeLocationUpdate(
        userId: update.userId,
        busName: update.busName,
        locationData: locationData,
      );

      debugPrint('');
      debugPrint('✅ LOCATION UPDATE STORED SUCCESSFULLY');
      debugPrint('   All Firebase paths updated');
      debugPrint('   Timestamp: ${update.timestamp.toIso8601String()}');
      debugPrint('═══════════════════════════════════════');
      debugPrint('');
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ FAILED TO STORE LOCATION UPDATE');
      debugPrint('═══════════════════════════════════════');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════');
      debugPrint('');
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
    debugPrint('👂 Setting up listener for bus: $busName');

    return _firebaseService.listenToPath('active_buses/$busName').map((data) {
      if (data == null) {
        debugPrint('   ℹ️ No data for bus: $busName');
        return null;
      }

      try {
        // Extract current location
        final currentLocation =
            data['currentLocation'] as Map<String, dynamic>?;
        if (currentLocation == null) {
          debugPrint('   ⚠️ No current location for bus: $busName');
          return null;
        }

        // Extract terminal data
        final startingTerminal =
            data['startingTerminal'] as Map<String, dynamic>?;
        final destinationTerminal =
            data['destinationTerminal'] as Map<String, dynamic>?;

        final update = RiderLocationUpdateModel(
          userId: data['riderId'] as String,
          userName: data['riderName'] as String,
          busName: data['busName'] as String,
          routeName: data['routeName'] as String,
          busRouteAssignmentId: data['busRouteAssignmentId'] as String?,
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

        debugPrint('   ✅ Bus location update received: ${update.busName}');
        return update;
      } catch (e) {
        debugPrint('   ❌ Error parsing bus location: $e');
        return null;
      }
    });
  }

  @override
  Stream<Map<String, dynamic>> watchAllActiveBuses() {
    debugPrint('👂 Setting up listener for all active buses');

    return _firebaseService.listenToPath('active_buses').map((data) {
      if (data == null) {
        debugPrint('   ℹ️ No active buses');
        return <String, dynamic>{};
      }

      try {
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
                'busRouteAssignmentId': busInfo['busRouteAssignmentId'],
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
              debugPrint('   ❌ Error parsing bus data for $busKey: $e');
            }
          }
        });

        debugPrint('   ✅ Active buses update: ${activeBuses.length} buses');
        return activeBuses;
      } catch (e) {
        debugPrint('   ❌ Error watching active buses: $e');
        return <String, dynamic>{};
      }
    });
  }
}
