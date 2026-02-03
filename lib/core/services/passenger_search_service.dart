import 'package:flutter/foundation.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/bus_route_assignment.dart';
import '../../domain/entities/terminal.dart';
import '../utils/distance_calculator.dart';

/// Trip option for passenger
class TripOption {
  final Bus bus;
  final BusRoute route;
  final BusRouteAssignment busRouteAssignment;
  final double distanceToBusKm;
  final double etaToBusMinutes;
  final double totalTripDistanceKm;
  final double totalTripDurationMinutes;
  final Terminal startingTerminal;
  final Terminal destinationTerminal;
  final double? currentBusLat;
  final double? currentBusLng;

  TripOption({
    required this.bus,
    required this.route,
    required this.busRouteAssignment,
    required this.distanceToBusKm,
    required this.etaToBusMinutes,
    required this.totalTripDistanceKm,
    required this.totalTripDurationMinutes,
    required this.startingTerminal,
    required this.destinationTerminal,
    this.currentBusLat,
    this.currentBusLng,
  });

  String get busName => bus.name ?? 'Unknown Bus';
  String get routeName => route.name;

  String get formattedETA {
    if (etaToBusMinutes < 1) {
      return 'Arriving now';
    } else if (etaToBusMinutes < 60) {
      return '${etaToBusMinutes.round()} min';
    } else {
      final hours = (etaToBusMinutes / 60).floor();
      final minutes = (etaToBusMinutes % 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  String get formattedDistance {
    if (distanceToBusKm < 1) {
      return '${(distanceToBusKm * 1000).round()} m';
    }
    return '${distanceToBusKm.toStringAsFixed(1)} km';
  }
}

/// Service for passenger search and trip planning
class PassengerSearchService {
  static const double _averageBusSpeed = 30.0; // km/h

  /// Search buses by bus number/name
  static List<Bus> searchBusesByName(List<Bus> allBuses, String searchQuery) {
    if (searchQuery.isEmpty) return allBuses;

    final query = searchQuery.toLowerCase();
    return allBuses.where((bus) {
      final name = bus.name?.toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  /// Find trip options based on passenger location and destination
  static Future<List<TripOption>> findTripOptions({
    required double passengerLat,
    required double passengerLng,
    required Terminal destinationTerminal,
    required List<Bus> allBuses,
    required List<BusRoute> allRoutes,
    required List<BusRouteAssignment> allBusRoutes,
    required Map<String, Map<String, double>> liveBusLocations,
  }) async {
    try {
      final tripOptions = <TripOption>[];

      // Filter routes that go to or near the destination
      final relevantRoutes =
          allRoutes.where((route) {
            // Check if destination terminal matches
            if (route.destinationTerminal.id == destinationTerminal.id) {
              return true;
            }

            // Check if destination is near route destination (within 1km)
            final distanceToDestination = DistanceCalculator.calculate(
              route.destinationTerminal.latitude,
              route.destinationTerminal.longitude,
              destinationTerminal.latitude,
              destinationTerminal.longitude,
            );

            return distanceToDestination <= 1.0; // 1km threshold
          }).toList();

      debugPrint('📍 Found ${relevantRoutes.length} relevant routes');

      // For each relevant route, find buses and calculate trip options
      for (final route in relevantRoutes) {
        final busRouteAssignments = allBusRoutes.where(
          (br) => br.routeId == route.id,
        );

        for (final busRouteAssignment in busRouteAssignments) {
          // Find bus
          final bus = allBuses.firstWhere(
            (b) => b.id == busRouteAssignment.busId,
            orElse:
                () => Bus(
                  id: busRouteAssignment.busId,
                  name: busRouteAssignment.busName,
                  busNumber: busRouteAssignment.busName,
                ),
          );

          // Get live bus location
          final busLocation = liveBusLocations[bus.id];
          final double? busLat = busLocation?['latitude'];
          final double? busLng = busLocation?['longitude'];

          // Calculate distance from passenger to bus
          double distanceToBus;
          if (busLat != null && busLng != null) {
            distanceToBus = DistanceCalculator.calculate(
              passengerLat,
              passengerLng,
              busLat,
              busLng,
            );
          } else {
            // Use starting terminal as fallback
            distanceToBus = DistanceCalculator.calculate(
              passengerLat,
              passengerLng,
              route.startingTerminal.latitude,
              route.startingTerminal.longitude,
            );
          }

          // Calculate ETA to bus
          final etaToBus = (distanceToBus / _averageBusSpeed) * 60; // minutes

          // Calculate total trip distance and duration
          final totalDistance = route.distanceKm ?? distanceToBus;
          final totalDuration =
              route.durationMinutes?.toDouble() ??
              (totalDistance / _averageBusSpeed) * 60;

          tripOptions.add(
            TripOption(
              bus: bus,
              route: route,
              busRouteAssignment: busRouteAssignment,
              distanceToBusKm: distanceToBus,
              etaToBusMinutes: etaToBus,
              totalTripDistanceKm: totalDistance,
              totalTripDurationMinutes: totalDuration,
              startingTerminal: route.startingTerminal,
              destinationTerminal: route.destinationTerminal,
              currentBusLat: busLat,
              currentBusLng: busLng,
            ),
          );
        }
      }

      // Sort by ETA (closest first)
      tripOptions.sort(
        (a, b) => a.etaToBusMinutes.compareTo(b.etaToBusMinutes),
      );

      debugPrint('✅ Found ${tripOptions.length} trip options');
      return tripOptions;
    } catch (e) {
      debugPrint('❌ Error finding trip options: $e');
      return [];
    }
  }

  /// Get nearby buses within radius
  static List<Map<String, dynamic>> getNearbyBuses({
    required double passengerLat,
    required double passengerLng,
    required Map<String, Map<String, double>> liveBusLocations,
    required List<Bus> allBuses,
    double radiusKm = 5.0,
  }) {
    final nearbyBuses = <Map<String, dynamic>>[];

    for (final entry in liveBusLocations.entries) {
      final busId = entry.key;
      final location = entry.value;
      final busLat = location['latitude'];
      final busLng = location['longitude'];

      if (busLat == null || busLng == null) continue;

      final distance = DistanceCalculator.calculate(
        passengerLat,
        passengerLng,
        busLat,
        busLng,
      );

      if (distance <= radiusKm) {
        final bus = allBuses.firstWhere(
          (b) => b.id == busId,
          orElse:
              () => Bus(id: busId, name: 'Bus $busId', busNumber: 'Bus $busId'),
        );

        nearbyBuses.add({
          'bus': bus,
          'distance': distance,
          'latitude': busLat,
          'longitude': busLng,
        });
      }
    }

    // Sort by distance
    nearbyBuses.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return nearbyBuses;
  }

  /// Filter routes by direction/area
  static List<BusRoute> filterRoutesByArea({
    required List<BusRoute> allRoutes,
    required String searchQuery,
  }) {
    if (searchQuery.isEmpty) return allRoutes;

    final query = searchQuery.toLowerCase();
    return allRoutes.where((route) {
      final routeName = route.name.toLowerCase();
      final startName = route.startingTerminal.name.toLowerCase();
      final destName = route.destinationTerminal.name.toLowerCase();

      return routeName.contains(query) ||
          startName.contains(query) ||
          destName.contains(query);
    }).toList();
  }
}
