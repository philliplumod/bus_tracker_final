import '../../domain/entities/user_assignment.dart';
import 'api_bus_route_model.dart';

/// API user model from /api/users
class ApiUserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin', 'rider', 'passenger'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApiUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    return ApiUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// API model for UserAssignment from /api/user-assignments
class ApiUserAssignmentModel {
  final String assignmentId;
  final String userId;
  final String busRouteId;
  final DateTime? assignedAt;
  final DateTime? updatedAt;
  final ApiUserModel? user;
  final ApiBusRouteModel? busRoute;

  ApiUserAssignmentModel({
    required this.assignmentId,
    required this.userId,
    required this.busRouteId,
    this.assignedAt,
    this.updatedAt,
    this.user,
    this.busRoute,
  });

  factory ApiUserAssignmentModel.fromJson(Map<String, dynamic> json) {
    return ApiUserAssignmentModel(
      assignmentId: json['assignment_id'] as String,
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
      user:
          json['user'] != null
              ? ApiUserModel.fromJson(
                Map<String, dynamic>.from(json['user'] as Map),
              )
              : null,
      busRoute:
          json['bus_route'] != null
              ? ApiBusRouteModel.fromJson(
                Map<String, dynamic>.from(json['bus_route'] as Map),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'user_id': userId,
      'bus_route_id': busRouteId,
      'assigned_at': assignedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
      'bus_route': busRoute?.toJson(),
    };
  }

  /// Convert to domain entity
  UserAssignment toEntity() {
    // Detailed validation with helpful error messages
    if (user == null) {
      throw StateError(
        'Backend API Error: Assignment is missing "user" object.\n'
        'Your backend must include nested user data.\n'
        'Expected: { "user": { "id": "...", "name": "...", ... } }\n'
        'See BACKEND_API_REQUIREMENTS.md for the correct structure.',
      );
    }

    if (busRoute == null) {
      throw StateError(
        'Backend API Error: Assignment is missing "bus_route" object.\n'
        'Your backend must JOIN the bus_routes table.\n'
        'Expected: { "bus_route": { "bus_id": "...", "route_id": "...", ... } }\n'
        'See BACKEND_API_REQUIREMENTS.md for the correct SQL query.',
      );
    }

    final route = busRoute!.route;
    if (route == null) {
      throw StateError(
        'Backend API Error: bus_route is missing "route" object.\n'
        'Your backend must JOIN the routes table.\n'
        'Expected: { "bus_route": { "route": { "route_name": "...", ... } } }\n'
        'The backend needs to JOIN: user_assignments → bus_routes → routes.\n'
        'See BACKEND_API_REQUIREMENTS.md for the complete SQL query.',
      );
    }

    if (busRoute!.bus == null) {
      throw StateError(
        'Backend API Error: bus_route is missing "bus" object.\n'
        'Your backend must JOIN the buses table.\n'
        'Expected: { "bus_route": { "bus": { "bus_name": "...", ... } } }\n'
        'See BACKEND_API_REQUIREMENTS.md for the correct structure.',
      );
    }

    return UserAssignment(
      id: assignmentId,
      userId: userId,
      busRouteId: busRouteId,
      busId: busRoute!.busId,
      busName: busRoute!.bus?.busName,
      routeId: busRoute!.routeId,
      routeName: route.routeName,
      startingTerminalId:
          route.startingTerminalId ?? route.startingTerminal?.terminalId,
      startingTerminalName: route.startingTerminal?.terminalName,
      destinationTerminalId:
          route.destinationTerminalId ?? route.destinationTerminal?.terminalId,
      destinationTerminalName: route.destinationTerminal?.terminalName,
      assignedAt: assignedAt,
      updatedAt: updatedAt,
    );
  }
}
