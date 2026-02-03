import 'package:equatable/equatable.dart';

class UserAssignment extends Equatable {
  final String id; // assignment_id
  final String userId;
  final String busRouteId; // References bus_routes.bus_route_id
  final DateTime? assignedAt;
  final DateTime? updatedAt;

  const UserAssignment({
    required this.id,
    required this.userId,
    required this.busRouteId,
    this.assignedAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': id,
      'user_id': userId,
      'bus_route_id': busRouteId,
      'assigned_at': assignedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserAssignment.fromJson(Map<String, dynamic> json) {
    return UserAssignment(
      id: json['assignment_id'] as String,
      userId: json['user_id'] as String,
      busRouteId: json['bus_route_id'] as String,
      assignedAt:
          json['assigned_at'] != null
              ? DateTime.parse(json['assigned_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  UserAssignment copyWith({
    String? id,
    String? userId,
    String? busRouteId,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return UserAssignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      busRouteId: busRouteId ?? this.busRouteId,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, busRouteId, assignedAt, updatedAt];
}
