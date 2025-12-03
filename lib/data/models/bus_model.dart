import '../../domain/entities/bus.dart';

class BusModel extends Bus {
  const BusModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    required super.altitude,
    required super.speed,
    required super.timestamp,
    super.distanceFromUser,
    super.eta,
  });

  factory BusModel.fromFirebase(
    String busId,
    String timestampKey,
    Map<Object?, Object?> data,
  ) {
    final payload = Map<String, dynamic>.from(data.values.first as Map);
    return BusModel(
      id: busId,
      latitude: (payload['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (payload['lng'] as num?)?.toDouble() ?? 0.0,
      altitude: (payload['alt'] as num?)?.toDouble() ?? 0.0,
      speed: (payload['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: payload['timestamp'] as String? ?? timestampKey,
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
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed,
      timestamp: timestamp,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      eta: eta ?? this.eta,
    );
  }
}
