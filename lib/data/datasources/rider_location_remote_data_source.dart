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
  Stream<RiderLocationUpdateModel?> watchBusLocation(String busId);
}

class RiderLocationRemoteDataSourceImpl
    implements RiderLocationRemoteDataSource {
  final DatabaseReference _dbRef;

  RiderLocationRemoteDataSourceImpl({DatabaseReference? dbRef})
    : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  @override
  Future<void> storeLocationUpdate(RiderLocationUpdateModel update) async {
    try {
      // Store in bus location path: buses/{busId}/location/{timestamp}
      final busLocationRef = _dbRef
          .child('buses')
          .child(update.busId)
          .child('location')
          .child(update.timestamp.millisecondsSinceEpoch.toString());

      // Store location data
      await busLocationRef.set(update.toFirebaseJson());

      // Also store metadata at bus level
      await _dbRef.child('buses').child(update.busId).update({
        'busNumber': update.busId,
        'route': update.routeId,
        'lastUpdate': update.timestamp.toIso8601String(),
      });

      // Store in rider tracking path: rider_tracking/{userId}/{timestamp}
      final riderTrackingRef = _dbRef
          .child('rider_tracking')
          .child(update.userId)
          .child(update.timestamp.millisecondsSinceEpoch.toString());

      await riderTrackingRef.set(update.toJson());

      debugPrint(
        '✅ Location update stored in Firebase for bus: ${update.busId}',
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
  Stream<RiderLocationUpdateModel?> watchBusLocation(String busId) {
    return _dbRef.child('buses').child(busId).child('location').onValue.map((
      event,
    ) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        return null;
      }

      final locationData = snapshot.value as Map<Object?, Object?>;

      // Get the most recent timestamp entry
      String? latestTimestamp;
      Map<Object?, Object?>? latestData;

      locationData.forEach((timestampKey, timestampData) {
        if (timestampData is Map) {
          final timestampStr = timestampKey.toString();
          if (latestTimestamp == null ||
              timestampStr.compareTo(latestTimestamp!) > 0) {
            latestTimestamp = timestampStr;
            latestData = timestampData as Map<Object?, Object?>;
          }
        }
      });

      if (latestData == null) return null;

      // Note: This is a simplified version. For full updates,
      // you'd need to store more metadata at the bus level
      return null;
    });
  }
}
