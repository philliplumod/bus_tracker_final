import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.assignedRoute,
    super.busName,
    super.startingTerminal,
    super.destinationTerminal,
    super.startingTerminalLat,
    super.startingTerminalLng,
    super.destinationTerminalLat,
    super.destinationTerminalLng,
    super.assignedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
      assignedRoute: json['assignedRoute'] as String?,
      busName: json['busName'] as String?,
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': _roleToString(role),
      'assignedRoute': assignedRoute,
      'busName': busName,
      'startingTerminal': startingTerminal,
      'destinationTerminal': destinationTerminal,
      'startingTerminalLat': startingTerminalLat,
      'startingTerminalLng': startingTerminalLng,
      'destinationTerminalLat': destinationTerminalLat,
      'destinationTerminalLng': destinationTerminalLng,
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }

  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'rider':
        return UserRole.rider;
      case 'passenger':
        return UserRole.passenger;
      default:
        return UserRole.passenger;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.rider:
        return 'rider';
      case UserRole.passenger:
        return 'passenger';
    }
  }
}
