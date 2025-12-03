import 'package:equatable/equatable.dart';

class Bus extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final String timestamp;
  final double? distanceFromUser;
  final String? eta;
  final String? direction;

  const Bus({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    this.distanceFromUser,
    this.eta,
    this.direction,
  });

  Bus copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    String? timestamp,
    double? distanceFromUser,
    String? eta,
    String? direction,
  }) {
    return Bus(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      eta: eta ?? this.eta,
      direction: direction ?? this.direction,
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
    distanceFromUser,
    eta,
    direction,
  ];
}
