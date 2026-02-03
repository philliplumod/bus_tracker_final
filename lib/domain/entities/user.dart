import 'package:equatable/equatable.dart';

enum UserRole { rider, passenger }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? assignedRoute;
  final String? busName;
  // IDs for backend tracking
  final String? busId; // Actual bus ID from backend
  final String? routeId; // Actual route ID from backend
  // Enhanced schema-based properties
  final String? busRouteId; // References user_assignments.bus_route_id
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Terminal information from fix-features
  final String? startingTerminal;
  final String? destinationTerminal;
  final double? startingTerminalLat;
  final double? startingTerminalLng;
  final double? destinationTerminalLat;
  final double? destinationTerminalLng;
  final DateTime? assignedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.assignedRoute,
    this.busName,
    this.busId,
    this.routeId,
    this.busRouteId,
    this.createdAt,
    this.updatedAt,
    this.startingTerminal,
    this.destinationTerminal,
    this.startingTerminalLat,
    this.startingTerminalLng,
    this.destinationTerminalLat,
    this.destinationTerminalLng,
    this.assignedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'assignedRoute': assignedRoute,
      'busName': busName,
      'busId': busId,
      'routeId': routeId,
      'busRouteId': busRouteId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'startingTerminal': startingTerminal,
      'destinationTerminal': destinationTerminal,
      'startingTerminalLat': startingTerminalLat,
      'startingTerminalLng': startingTerminalLng,
      'destinationTerminalLat': destinationTerminalLat,
      'destinationTerminalLng': destinationTerminalLng,
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.passenger,
      ),
      assignedRoute: json['assignedRoute'] as String?,
      busName: json['busName'] as String?,
      busId: json['busId'] as String?,
      routeId: json['routeId'] as String?,
      busRouteId: json['busRouteId'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      startingTerminal: json['startingTerminal'] as String?,
      destinationTerminal: json['destinationTerminal'] as String?,
      startingTerminalLat:
          json['startingTerminalLat'] != null
              ? (json['startingTerminalLat'] as num).toDouble()
              : null,
      startingTerminalLng:
          json['startingTerminalLng'] != null
              ? (json['startingTerminalLng'] as num).toDouble()
              : null,
      destinationTerminalLat:
          json['destinationTerminalLat'] != null
              ? (json['destinationTerminalLat'] as num).toDouble()
              : null,
      destinationTerminalLng:
          json['destinationTerminalLng'] != null
              ? (json['destinationTerminalLng'] as num).toDouble()
              : null,
      assignedAt:
          json['assignedAt'] != null
              ? DateTime.parse(json['assignedAt'] as String)
              : null,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? assignedRoute,
    String? busName,
    String? busId,
    String? routeId,
    String? busRouteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? startingTerminal,
    String? destinationTerminal,
    double? startingTerminalLat,
    double? startingTerminalLng,
    double? destinationTerminalLat,
    double? destinationTerminalLng,
    DateTime? assignedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      assignedRoute: assignedRoute ?? this.assignedRoute,
      busName: busName ?? this.busName,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      busRouteId: busRouteId ?? this.busRouteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startingTerminal: startingTerminal ?? this.startingTerminal,
      destinationTerminal: destinationTerminal ?? this.destinationTerminal,
      startingTerminalLat: startingTerminalLat ?? this.startingTerminalLat,
      startingTerminalLng: startingTerminalLng ?? this.startingTerminalLng,
      destinationTerminalLat:
          destinationTerminalLat ?? this.destinationTerminalLat,
      destinationTerminalLng:
          destinationTerminalLng ?? this.destinationTerminalLng,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    assignedRoute,
    busName,
    busId,
    routeId,
    busRouteId,
    createdAt,
    updatedAt,
    startingTerminal,
    destinationTerminal,
    startingTerminalLat,
    startingTerminalLng,
    destinationTerminalLat,
    destinationTerminalLng,
    assignedAt,
  ];
}
