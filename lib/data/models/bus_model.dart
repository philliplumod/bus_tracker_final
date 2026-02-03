import '../../domain/entities/bus.dart';

class BusModel extends Bus {
  const BusModel({
    required super.id,
    super.busNumber,
    super.route,
    required super.latitude,
    required super.longitude,
    required super.altitude,
    required super.speed,
    required super.timestamp,
    super.distanceFromUser,
    super.eta,
    super.direction,
  });

  factory BusModel.fromFirebase(
    String busId,
    String timestampKey,
    Map<Object?, Object?> data,
    String? busNumber,
    String? route,
  ) {
    // Support both old format (lat/lng/alt/speed) and new format (latitude/longitude/speed/heading)
    return BusModel(
      id: busId,
      busNumber: busNumber,
      route: route,
      latitude:
          (data['latitude'] as num?)?.toDouble() ??
          (data['lat'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (data['longitude'] as num?)?.toDouble() ??
          (data['lng'] as num?)?.toDouble() ??
          0.0,
      altitude:
          (data['altitude'] as num?)?.toDouble() ??
          (data['alt'] as num?)?.toDouble() ??
          0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: timestampKey,
      direction: (data['heading'] as num?)?.toDouble().toString(),
    );
  }

  factory BusModel.fromPayload(Map<Object?, Object?> payload) {
    return BusModel(
      id: 'bus_one',
      latitude: (payload['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (payload['lng'] as num?)?.toDouble() ?? 0.0,
      altitude: (payload['alt'] as num?)?.toDouble() ?? 0.0,
      speed: (payload['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: payload['timestamp'] as String? ?? 'Unknown',
    );
  }

  BusModel copyWithCalculations({double? distanceFromUser, String? eta}) {
    return BusModel(
      id: id,
      busNumber: busNumber,
      route: route,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed,
      timestamp: timestamp,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      eta: eta ?? this.eta,
      direction: direction,
    );
  }
}
