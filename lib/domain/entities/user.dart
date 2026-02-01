import 'package:equatable/equatable.dart';

enum UserRole { admin, rider, passenger }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? assignedRoute;
  final String? busName;
  final String? startingTerminal;
  final String? destinationTerminal;
  final double? startingTerminalLat;
  final double? startingTerminalLng;
  final double? destinationTerminalLat;
  final double? destinationTerminalLng;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.assignedRoute,
    this.busName,
    this.startingTerminal,
    this.destinationTerminal,
    this.startingTerminalLat,
    this.startingTerminalLng,
    this.destinationTerminalLat,
    this.destinationTerminalLng,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'assignedRoute': assignedRoute,
      'busName': busName,
      'startingTerminal': startingTerminal,
      'destinationTerminal': destinationTerminal,
      'startingTerminalLat': startingTerminalLat,
      'startingTerminalLng': startingTerminalLng,
      'destinationTerminalLat': destinationTerminalLat,
      'destinationTerminalLng': destinationTerminalLng,
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
    startingTerminal,
    destinationTerminal,
    startingTerminalLat,
    startingTerminalLng,
    destinationTerminalLat,
    destinationTerminalLng,
  ];
}
