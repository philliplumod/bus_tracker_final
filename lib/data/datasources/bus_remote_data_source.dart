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
      final snapshot = await _busRef.child('active_buses').get();

      if (snapshot.value == null || snapshot.value is! Map) {
        debugPrint('❌ No bus data found in Firebase');
        return [];
      }

      List<BusModel> buses = [];
      final data = snapshot.value as Map<Object?, Object?>;
      debugPrint(
        '📡 Fetching buses from Firebase... Found ${data.length} entries',
      );

      data.forEach((busName, busData) {
        if (busData is Map) {
          try {
            // Extract data from active_buses structure
            final currentLocation =
                busData['currentLocation'] as Map<Object?, Object?>?;

            if (currentLocation == null ||
                !currentLocation.containsKey('latitude') ||
                !currentLocation.containsKey('longitude')) {
              debugPrint('⚠️ Skipping $busName: missing location data');
              return;
            }

            // Get bus details
            String busNameStr =
                busData['busName']?.toString() ?? busName.toString();
            String? routeName = busData['routeName']?.toString();
            String lastUpdate =
                busData['lastUpdate']?.toString() ??
                DateTime.now().toIso8601String();

            // Extract bus number from bus name (e.g., "Bus 001" -> "001")
            String? busNumber = busNameStr;
            final match = RegExp(r'\d+').firstMatch(busNameStr);
            if (match != null) {
              busNumber = match.group(0);
            }

            final bus = BusModel.fromFirebase(
              busNameStr,
              lastUpdate,
              currentLocation,
              busNumber,
              routeName,
            );
            buses.add(bus);
            debugPrint(
              '✅ Parsed bus: $busNameStr, Number: ${busNumber ?? "N/A"}, Route: ${routeName ?? "N/A"}, Location: (${bus.latitude}, ${bus.longitude})',
            );
          } catch (e) {
            debugPrint('❌ Error parsing bus $busName: $e');
          }
        }
      });

      debugPrint('📊 Total buses parsed: ${buses.length}');
      return buses;
    } catch (e) {
      debugPrint('❌ Failed to fetch nearby buses: $e');
      throw Exception('Failed to fetch nearby buses: $e');
    }
  }

  @override
  Stream<List<BusModel>> watchBusUpdates() {
    return _busRef.child('active_buses').onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        return <BusModel>[];
      }

      List<BusModel> buses = [];
      final data = snapshot.value as Map<Object?, Object?>;

      data.forEach((busName, busData) {
        if (busData is Map) {
          try {
            // Extract data from active_buses structure
            final currentLocation =
                busData['currentLocation'] as Map<Object?, Object?>?;

            if (currentLocation == null ||
                !currentLocation.containsKey('latitude') ||
                !currentLocation.containsKey('longitude')) {
              return;
            }

            // Get bus details
            String busNameStr =
                busData['busName']?.toString() ?? busName.toString();
            String? routeName = busData['routeName']?.toString();
            String lastUpdate =
                busData['lastUpdate']?.toString() ??
                DateTime.now().toIso8601String();

            // Extract bus number from bus name (e.g., "Bus 001" -> "001")
            String? busNumber = busNameStr;
            final match = RegExp(r'\d+').firstMatch(busNameStr);
            if (match != null) {
              busNumber = match.group(0);
            }

            final bus = BusModel.fromFirebase(
              busNameStr,
              lastUpdate,
              currentLocation,
              busNumber,
              routeName,
            );
            buses.add(bus);
          } catch (e) {
            debugPrint('❌ Error parsing bus $busName in stream: $e');
          }
        }
      });

      if (buses.isNotEmpty) {
        debugPrint('📡 Stream update: ${buses.length} buses');
      }
      return buses;
    });
  }
}
