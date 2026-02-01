import 'package:equatable/equatable.dart';

enum UserRole { admin, rider, passenger }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? assignedRoute;
  final String? busName;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.assignedRoute,
    this.busName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'assignedRoute': assignedRoute,
      'busName': busName,
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
    );
  }

  @override
  List<Object?> get props => [id, email, name, role, assignedRoute, busName];
}
