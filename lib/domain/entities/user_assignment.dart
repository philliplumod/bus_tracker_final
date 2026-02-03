import 'package:equatable/equatable.dart';

/// User assignment entity linking users to bus routes with full details
class UserAssignment extends Equatable {
  final String id; // assignment_id
  final String userId;
  final String busRouteId; // References bus_routes.bus_route_id
  final String busId;
  final String? busName;
  final String routeId;
  final String? routeName;
  final String? startingTerminalId;
  final String? startingTerminalName;
  final String? destinationTerminalId;
  final String? destinationTerminalName;
  final DateTime? assignedAt;
  final DateTime? updatedAt;

  const UserAssignment({
    required this.id,
    required this.userId,
    required this.busRouteId,
    required this.busId,
    this.busName,
    required this.routeId,
    this.routeName,
    this.startingTerminalId,
    this.startingTerminalName,
    this.destinationTerminalId,
    this.destinationTerminalName,
    this.assignedAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': id,
      'user_id': userId,
      'bus_route_id': busRouteId,
      'bus_id': busId,
      'bus_name': busName,
      'route_id': routeId,
      'route_name': routeName,
      'starting_terminal_id': startingTerminalId,
      'starting_terminal_name': startingTerminalName,
      'destination_terminal_id': destinationTerminalId,
      'destination_terminal_name': destinationTerminalName,
      'assigned_at': assignedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserAssignment.fromJson(Map<String, dynamic> json) {
    return UserAssignment(
      id: json['assignment_id'] as String,
      userId: json['user_id'] as String,
      busRouteId: json['bus_route_id'] as String,
      busId: json['bus_id'] as String,
      busName: json['bus_name'] as String?,
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String?,
      startingTerminalId: json['starting_terminal_id'] as String?,
      startingTerminalName: json['starting_terminal_name'] as String?,
      destinationTerminalId: json['destination_terminal_id'] as String?,
      destinationTerminalName: json['destination_terminal_name'] as String?,
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
    String? busId,
    String? busName,
    String? routeId,
    String? routeName,
    String? startingTerminalId,
    String? startingTerminalName,
    String? destinationTerminalId,
    String? destinationTerminalName,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return UserAssignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      busRouteId: busRouteId ?? this.busRouteId,
      busId: busId ?? this.busId,
      busName: busName ?? this.busName,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      startingTerminalId: startingTerminalId ?? this.startingTerminalId,
      startingTerminalName: startingTerminalName ?? this.startingTerminalName,
      destinationTerminalId:
          destinationTerminalId ?? this.destinationTerminalId,
      destinationTerminalName:
          destinationTerminalName ?? this.destinationTerminalName,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    busRouteId,
    busId,
    busName,
    routeId,
    routeName,
    startingTerminalId,
    startingTerminalName,
    destinationTerminalId,
    destinationTerminalName,
    assignedAt,
    updatedAt,
  ];
}
