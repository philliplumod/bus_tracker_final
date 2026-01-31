import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import '../models/bus_model.dart';

abstract class BusRemoteDataSource {
  Future<List<BusModel>> getNearbyBuses();
  Stream<List<BusModel>> watchBusUpdates();
}

class BusRemoteDataSourceImpl implements BusRemoteDataSource {
  final DatabaseReference _busRef;

  BusRemoteDataSourceImpl({DatabaseReference? busRef})
    : _busRef = busRef ?? FirebaseDatabase.instance.ref();

  @override
  Future<List<BusModel>> getNearbyBuses() async {
    try {
      final snapshot = await _busRef.get();

      if (snapshot.value == null || snapshot.value is! Map) {
        return [];
      }

      List<BusModel> buses = [];
      final data = snapshot.value as Map<Object?, Object?>;

      data.forEach((busId, busData) {
        if (busData is Map && busData.containsKey('location')) {
          final locationData = busData['location'] as Map<Object?, Object?>;
          final busNumber = busData['busNumber'] as String?;
          final route = busData['route'] as String?;

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

          if (latestData != null && latestTimestamp != null) {
            try {
              final bus = BusModel.fromFirebase(
                busId.toString(),
                latestTimestamp!,
                latestData!,
                busNumber,
                route,
              );
              buses.add(bus);
            } catch (e) {
              debugPrint('Error parsing bus $busId: $e');
            }
          }
        }
      });

      return buses;
    } catch (e) {
      throw Exception('Failed to fetch nearby buses: $e');
    }
  }

  @override
  Stream<List<BusModel>> watchBusUpdates() {
    return _busRef.onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        return <BusModel>[];
      }

      List<BusModel> buses = [];
      final data = snapshot.value as Map<Object?, Object?>;

      data.forEach((busId, busData) {
        if (busData is Map && busData.containsKey('location')) {
          final locationData = busData['location'] as Map<Object?, Object?>;
          final busNumber = busData['busNumber'] as String?;
          final route = busData['route'] as String?;

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

          if (latestData != null && latestTimestamp != null) {
            try {
              final bus = BusModel.fromFirebase(
                busId.toString(),
                latestTimestamp!,
                latestData!,
                busNumber,
                route,
              );
              buses.add(bus);
            } catch (e) {
              debugPrint('Error parsing bus $busId: $e');
            }
          }
        }
      });

      return buses;
    });
  }
}
