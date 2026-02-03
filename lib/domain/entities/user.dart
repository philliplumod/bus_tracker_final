import 'package:equatable/equatable.dart';

enum UserRole { admin, rider, passenger }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? assignedRoute;
  final String? busName;
  final String? busRouteId; // References user_assignments.bus_route_id
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.assignedRoute,
    this.busName,
    this.busRouteId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'assignedRoute': assignedRoute,
      'busName': busName,
      'busRouteId': busRouteId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
      busRouteId: json['busRouteId'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
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
    String? busRouteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      assignedRoute: assignedRoute ?? this.assignedRoute,
      busName: busName ?? this.busName,
      busRouteId: busRouteId ?? this.busRouteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    busRouteId,
    createdAt,
    updatedAt,
  ];
}
