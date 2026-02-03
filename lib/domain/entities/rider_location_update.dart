import 'package:equatable/equatable.dart';

/// Represents a rider's location update with complete tracking information
class RiderLocationUpdate extends Equatable {
  final String userId;
  final String busId;
  final String routeId;
  final String busRouteAssignmentId;
  final double latitude;
  final double longitude;
  final double speed; // km/h
  final double heading; // degrees (0-360)
  final DateTime timestamp;
  final double? accuracy; // meters
  final double? altitude; // meters
  final String? destinationTerminalId;
  final double? estimatedDurationMinutes; // to destination

  const RiderLocationUpdate({
    required this.userId,
    required this.busId,
    required this.routeId,
    required this.busRouteAssignmentId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.destinationTerminalId,
    this.estimatedDurationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'busId': busId,
      'routeId': routeId,
      'busRouteAssignmentId': busRouteAssignmentId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'altitude': altitude,
      'destinationTerminalId': destinationTerminalId,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    };
  }

  /// Firebase-specific format for storing location updates
  Map<String, dynamic> toFirebaseJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'altitude': altitude,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    };
  }

  factory RiderLocationUpdate.fromJson(Map<String, dynamic> json) {
    return RiderLocationUpdate(
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

  RiderLocationUpdate copyWith({
    String? userId,
    String? busId,
    String? routeId,
    String? busRouteAssignmentId,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    double? accuracy,
    double? altitude,
    String? destinationTerminalId,
    double? estimatedDurationMinutes,
  }) {
    return RiderLocationUpdate(
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      busRouteAssignmentId: busRouteAssignmentId ?? this.busRouteAssignmentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      destinationTerminalId:
          destinationTerminalId ?? this.destinationTerminalId,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    busId,
    routeId,
    busRouteAssignmentId,
    latitude,
    longitude,
    speed,
    heading,
    timestamp,
    accuracy,
    altitude,
    destinationTerminalId,
    estimatedDurationMinutes,
  ];
}
