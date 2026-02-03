import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../data/datasources/rider_location_remote_data_source.dart';

/// Active bus information for passenger tracking
class ActiveBusInfo {
  final String busName;
  final String routeName;
  final String riderId;
  final String riderName;
  final double currentLat;
  final double currentLng;
  final double speed;
  final double heading;
  final double? accuracy;
  final String? startingTerminalName;
  final double? startingTerminalLat;
  final double? startingTerminalLng;
  final String? destinationTerminalName;
  final double? destinationTerminalLat;
  final double? destinationTerminalLng;
  final DateTime lastUpdate;

  ActiveBusInfo({
    required this.busName,
    required this.routeName,
    required this.riderId,
    required this.riderName,
    required this.currentLat,
    required this.currentLng,
    required this.speed,
    required this.heading,
    this.accuracy,
    this.startingTerminalName,
    this.startingTerminalLat,
    this.startingTerminalLng,
    this.destinationTerminalName,
    this.destinationTerminalLat,
    this.destinationTerminalLng,
    required this.lastUpdate,
  });

  factory ActiveBusInfo.fromJson(String busName, Map<String, dynamic> json) {
    final currentLocation = json['currentLocation'] as Map<String, dynamic>?;
    final startingTerminal = json['startingTerminal'] as Map<String, dynamic>?;
    final destinationTerminal =
        json['destinationTerminal'] as Map<String, dynamic>?;

    return ActiveBusInfo(
      busName: json['busName'] as String? ?? busName,
      routeName: json['routeName'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      currentLat: (currentLocation?['latitude'] as num).toDouble(),
      currentLng: (currentLocation?['longitude'] as num).toDouble(),
      speed: (currentLocation?['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (currentLocation?['heading'] as num?)?.toDouble() ?? 0.0,
      accuracy: (currentLocation?['accuracy'] as num?)?.toDouble(),
      startingTerminalName: startingTerminal?['name'] as String?,
      startingTerminalLat: (startingTerminal?['latitude'] as num?)?.toDouble(),
      startingTerminalLng: (startingTerminal?['longitude'] as num?)?.toDouble(),
      destinationTerminalName: destinationTerminal?['name'] as String?,
      destinationTerminalLat:
          (destinationTerminal?['latitude'] as num?)?.toDouble(),
      destinationTerminalLng:
          (destinationTerminal?['longitude'] as num?)?.toDouble(),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  /// Check if bus data is stale (older than 30 seconds)
  bool get isStale {
    return DateTime.now().difference(lastUpdate).inSeconds > 30;
  }

  /// Get human-readable route description
  String get routeDescription {
    if (startingTerminalName != null && destinationTerminalName != null) {
      return '$startingTerminalName → $destinationTerminalName';
    }
    return routeName;
  }
}

/// Service for real-time bus tracking for passengers
class RealtimeBusTrackingService {
  final RiderLocationRemoteDataSource _dataSource;

  RealtimeBusTrackingService({RiderLocationRemoteDataSource? dataSource})
    : _dataSource =
          dataSource ??
          RiderLocationRemoteDataSourceImpl(
            dbRef: FirebaseDatabase.instance.ref(),
          );

  /// Stream all active buses in real-time
  Stream<List<ActiveBusInfo>> watchAllActiveBuses() {
    return _dataSource.watchAllActiveBuses().map((busesData) {
      final activeBuses = <ActiveBusInfo>[];

      busesData.forEach((busName, busData) {
        try {
          if (busData is Map<String, dynamic>) {
            final busInfo = ActiveBusInfo.fromJson(busName, busData);

            // Only include buses with recent updates (not stale)
            if (!busInfo.isStale) {
              activeBuses.add(busInfo);
            }
          }
        } catch (e) {
          debugPrint('Error parsing bus info for $busName: $e');
        }
      });

      debugPrint('🚌 Active buses: ${activeBuses.length}');
      return activeBuses;
    });
  }

  /// Search for buses by name
  Stream<List<ActiveBusInfo>> searchBusesByName(String query) {
    return watchAllActiveBuses().map((buses) {
      if (query.isEmpty) return buses;

      final lowerQuery = query.toLowerCase();
      return buses.where((bus) {
        return bus.busName.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  /// Search for buses by route
  Stream<List<ActiveBusInfo>> searchBusesByRoute(String routeQuery) {
    return watchAllActiveBuses().map((buses) {
      if (routeQuery.isEmpty) return buses;

      final lowerQuery = routeQuery.toLowerCase();
      return buses.where((bus) {
        return bus.routeName.toLowerCase().contains(lowerQuery) ||
            (bus.startingTerminalName?.toLowerCase().contains(lowerQuery) ??
                false) ||
            (bus.destinationTerminalName?.toLowerCase().contains(lowerQuery) ??
                false);
      }).toList();
    });
  }

  /// Find buses going to a specific destination terminal
  Stream<List<ActiveBusInfo>> findBusesToDestination({
    required double destinationLat,
    required double destinationLng,
    double maxDistanceKm = 1.0,
  }) {
    return watchAllActiveBuses().map((buses) {
      return buses.where((bus) {
        if (bus.destinationTerminalLat == null ||
            bus.destinationTerminalLng == null) {
          return false;
        }

        final distance = _calculateDistance(
          destinationLat,
          destinationLng,
          bus.destinationTerminalLat!,
          bus.destinationTerminalLng!,
        );

        return distance <= maxDistanceKm;
      }).toList();
    });
  }

  /// Calculate distance between two points in kilometers using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
