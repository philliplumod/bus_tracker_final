import '../../domain/entities/rider_location_update.dart';

class RiderLocationUpdateModel extends RiderLocationUpdate {
  const RiderLocationUpdateModel({
    required super.userId,
    required super.userName,
    required super.busName,
    required super.routeName,
    super.busRouteAssignmentId,
    required super.latitude,
    required super.longitude,
    required super.speed,
    required super.heading,
    required super.timestamp,
    super.accuracy,
    super.altitude,
    super.destinationTerminal,
    super.estimatedDurationMinutes,
    super.startingTerminalName,
    super.startingTerminalLat,
    super.startingTerminalLng,
    super.destinationTerminalName,
    super.destinationTerminalLat,
    super.destinationTerminalLng,
  });

  factory RiderLocationUpdateModel.fromEntity(RiderLocationUpdate entity) {
    return RiderLocationUpdateModel(
      userId: entity.userId,
      userName: entity.userName,
      busName: entity.busName,
      routeName: entity.routeName,
      busRouteAssignmentId: entity.busRouteAssignmentId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      heading: entity.heading,
      timestamp: entity.timestamp,
      accuracy: entity.accuracy,
      altitude: entity.altitude,
      destinationTerminal: entity.destinationTerminal,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      startingTerminalName: entity.startingTerminalName,
      startingTerminalLat: entity.startingTerminalLat,
      startingTerminalLng: entity.startingTerminalLng,
      destinationTerminalName: entity.destinationTerminalName,
      destinationTerminalLat: entity.destinationTerminalLat,
      destinationTerminalLng: entity.destinationTerminalLng,
    );
  }

  factory RiderLocationUpdateModel.fromJson(Map<String, dynamic> json) {
    return RiderLocationUpdateModel(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      busName: json['busName'] as String,
      routeName: json['routeName'] as String,
      busRouteAssignmentId: json['busRouteAssignmentId'] as String?,
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
      destinationTerminal: json['destinationTerminal'] as String?,
      estimatedDurationMinutes:
          json['estimatedDurationMinutes'] != null
              ? (json['estimatedDurationMinutes'] as num).toDouble()
              : null,
      startingTerminalName: json['startingTerminalName'] as String?,
      startingTerminalLat:
          json['startingTerminalLat'] != null
              ? (json['startingTerminalLat'] as num).toDouble()
              : null,
      startingTerminalLng:
          json['startingTerminalLng'] != null
              ? (json['startingTerminalLng'] as num).toDouble()
              : null,
      destinationTerminalName: json['destinationTerminalName'] as String?,
      destinationTerminalLat:
          json['destinationTerminalLat'] != null
              ? (json['destinationTerminalLat'] as num).toDouble()
              : null,
      destinationTerminalLng:
          json['destinationTerminalLng'] != null
              ? (json['destinationTerminalLng'] as num).toDouble()
              : null,
    );
  }

  /// Convert to Firebase-specific JSON format for storage
  Map<String, dynamic> toFirebaseJson() {
    return {
      'userId': userId,
      'userName': userName,
      'busName': busName,
      'routeName': routeName,
      'busRouteAssignmentId': busRouteAssignmentId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'altitude': altitude,
      'destinationTerminal': destinationTerminal,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'startingTerminalName': startingTerminalName,
      'startingTerminalLat': startingTerminalLat,
      'startingTerminalLng': startingTerminalLng,
      'destinationTerminalName': destinationTerminalName,
      'destinationTerminalLat': destinationTerminalLat,
      'destinationTerminalLng': destinationTerminalLng,
    };
  }

  /// Convert to standard JSON format
  Map<String, dynamic> toJson() => toFirebaseJson();
}
