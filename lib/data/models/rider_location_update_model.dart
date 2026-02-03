import '../../domain/entities/rider_location_update.dart';

class RiderLocationUpdateModel extends RiderLocationUpdate {
  const RiderLocationUpdateModel({
    required super.userId,
    required super.busId,
    required super.routeId,
    required super.busRouteAssignmentId,
    required super.latitude,
    required super.longitude,
    required super.speed,
    required super.heading,
    required super.timestamp,
    super.accuracy,
    super.altitude,
    super.destinationTerminalId,
    super.estimatedDurationMinutes,
  });

  factory RiderLocationUpdateModel.fromEntity(RiderLocationUpdate entity) {
    return RiderLocationUpdateModel(
      userId: entity.userId,
      busId: entity.busId,
      routeId: entity.routeId,
      busRouteAssignmentId: entity.busRouteAssignmentId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      heading: entity.heading,
      timestamp: entity.timestamp,
      accuracy: entity.accuracy,
      altitude: entity.altitude,
      destinationTerminalId: entity.destinationTerminalId,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
    );
  }

  factory RiderLocationUpdateModel.fromJson(Map<String, dynamic> json) {
    return RiderLocationUpdateModel(
      userId: json['userId'] as String,
      busId: json['busId'] as String,
      routeId: json['routeId'] as String,
      busRouteAssignmentId: json['busRouteAssignmentId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy:
          json['accuracy'] != null
              ? (json['accuracy'] as num).toDouble()
              : null,
      altitude:
          json['altitude'] != null
              ? (json['altitude'] as num).toDouble()
              : null,
      destinationTerminalId: json['destinationTerminalId'] as String?,
      estimatedDurationMinutes:
          json['estimatedDurationMinutes'] != null
              ? (json['estimatedDurationMinutes'] as num).toDouble()
              : null,
    );
  }
}
