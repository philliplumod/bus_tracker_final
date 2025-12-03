import 'package:equatable/equatable.dart';

class BusData extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final String timestamp;

  const BusData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  factory BusData.fromFirebase(
    String busId,
    String timestampKey,
    Map<Object?, Object?> data,
  ) {
    final payload = Map<String, dynamic>.from(data.values.first as Map);
    return BusData(
      id: busId,
      latitude: (payload['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (payload['lng'] as num?)?.toDouble() ?? 0.0,
      altitude: (payload['alt'] as num?)?.toDouble() ?? 0.0,
      speed: (payload['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: payload['timestamp'] as String? ?? timestampKey,
    );
  }

  @override
  List<Object?> get props => [
    id,
    latitude,
    longitude,
    altitude,
    speed,
    timestamp,
  ];
}
