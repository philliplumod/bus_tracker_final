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

  @override
  List<Object?> get props => [id, email, name, role, assignedRoute, busName];
}
