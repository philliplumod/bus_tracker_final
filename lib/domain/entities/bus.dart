import 'package:equatable/equatable.dart';

class Bus extends Equatable {
  final String id;
  final String? busNumber;
  final String? name; // Added for API compatibility
  final String? route;
  final double? latitude; // Made optional for API-only buses
  final double? longitude;
  final double? altitude;
  final double? speed;
  final String? timestamp;
  final double? distanceFromUser;
  final String? eta;
  final String? direction;
  final DateTime? createdAt; // Added for API compatibility
  final DateTime? updatedAt;

  const Bus({
    required this.id,
    this.busNumber,
    this.name,
    this.route,
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.timestamp,
    this.distanceFromUser,
    this.eta,
    this.direction,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNumber': busNumber,
      'name': name,
      'route': route,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp,
      'distanceFromUser': distanceFromUser,
      'eta': eta,
      'direction': direction,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String,
      busNumber: json['busNumber'] as String?,
      name: json['name'] as String?,
      route: json['route'] as String?,
      latitude:
          json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      longitude:
          json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,
      altitude:
          json['altitude'] != null
              ? (json['altitude'] as num).toDouble()
              : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      timestamp: json['timestamp'] as String?,
      distanceFromUser:
          json['distanceFromUser'] != null
              ? (json['distanceFromUser'] as num).toDouble()
              : null,
      eta: json['eta'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
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
