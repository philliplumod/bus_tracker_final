import 'package:equatable/equatable.dart';

/// Represents a rider's location update with complete tracking information
class RiderLocationUpdate extends Equatable {
  final String userId;
  final String userName;
  final String busName;
  final String routeName;
  final String? busRouteAssignmentId;
  final double latitude;
  final double longitude;
  final double speed; // km/h
  final double heading; // degrees (0-360)
  final DateTime timestamp;
  final double? accuracy; // meters
  final double? altitude; // meters
  final String? destinationTerminal;
  final double? estimatedDurationMinutes; // to destination

  // Starting terminal information
  final String? startingTerminalName;
  final double? startingTerminalLat;
  final double? startingTerminalLng;

  // Destination terminal information
  final String? destinationTerminalName;
  final double? destinationTerminalLat;
  final double? destinationTerminalLng;

  const RiderLocationUpdate({
    required this.userId,
    required this.userName,
    required this.busName,
    required this.routeName,
    this.busRouteAssignmentId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.destinationTerminal,
    this.estimatedDurationMinutes,
    this.startingTerminalName,
    this.startingTerminalLat,
    this.startingTerminalLng,
    this.destinationTerminalName,
    this.destinationTerminalLat,
    this.destinationTerminalLng,
  });

  Map<String, dynamic> toJson() {
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
      'startingTerminalName': startingTerminalName,
      'startingTerminalLat': startingTerminalLat,
      'startingTerminalLng': startingTerminalLng,
      'destinationTerminalName': destinationTerminalName,
      'destinationTerminalLat': destinationTerminalLat,
      'destinationTerminalLng': destinationTerminalLng,
    };
  }

  factory RiderLocationUpdate.fromJson(Map<String, dynamic> json) {
    return RiderLocationUpdate(
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

  RiderLocationUpdate copyWith({
    String? userId,
    String? userName,
    String? busName,
    String? routeName,
    String? busRouteAssignmentId,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    double? accuracy,
    double? altitude,
    String? destinationTerminal,
    double? estimatedDurationMinutes,
    String? startingTerminalName,
    double? startingTerminalLat,
    double? startingTerminalLng,
    String? destinationTerminalName,
    double? destinationTerminalLat,
    double? destinationTerminalLng,
  }) {
    return RiderLocationUpdate(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      busName: busName ?? this.busName,
      routeName: routeName ?? this.routeName,
      busRouteAssignmentId: busRouteAssignmentId ?? this.busRouteAssignmentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      destinationTerminal: destinationTerminal ?? this.destinationTerminal,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      startingTerminalName: startingTerminalName ?? this.startingTerminalName,
      startingTerminalLat: startingTerminalLat ?? this.startingTerminalLat,
      startingTerminalLng: startingTerminalLng ?? this.startingTerminalLng,
      destinationTerminalName:
          destinationTerminalName ?? this.destinationTerminalName,
      destinationTerminalLat:
          destinationTerminalLat ?? this.destinationTerminalLat,
      destinationTerminalLng:
          destinationTerminalLng ?? this.destinationTerminalLng,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    userName,
    busName,
    routeName,
    busRouteAssignmentId,
    latitude,
    longitude,
    speed,
    heading,
    timestamp,
    accuracy,
    altitude,
    destinationTerminal,
    estimatedDurationMinutes,
    startingTerminalName,
    startingTerminalLat,
    startingTerminalLng,
    destinationTerminalName,
    destinationTerminalLat,
    destinationTerminalLng,
  ];
}
