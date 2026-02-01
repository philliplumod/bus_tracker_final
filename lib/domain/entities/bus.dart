import 'package:equatable/equatable.dart';

class Bus extends Equatable {
  final String id;
  final String? busNumber;
  final String? route;
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
    this.busNumber,
    this.route,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    this.distanceFromUser,
    this.eta,
    this.direction,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNumber': busNumber,
      'route': route,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp,
      'distanceFromUser': distanceFromUser,
      'eta': eta,
      'direction': direction,
    };
  }

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String,
      busNumber: json['busNumber'] as String?,
      route: json['route'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      distanceFromUser:
          json['distanceFromUser'] != null
              ? (json['distanceFromUser'] as num).toDouble()
              : null,
      eta: json['eta'] as String?,
      direction: json['direction'] as String?,
    );
  }

  Bus copyWith({
    String? id,
    String? busNumber,
    String? route,
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
      busNumber: busNumber ?? this.busNumber,
      route: route ?? this.route,
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
    busNumber,
    route,
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
