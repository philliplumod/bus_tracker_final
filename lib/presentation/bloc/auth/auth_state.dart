import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];

  Map<String, dynamic> toJson();
}

class AuthInitial extends AuthState {
  @override
  Map<String, dynamic> toJson() => {'type': 'initial'};
}

class AuthLoading extends AuthState {
  @override
  Map<String, dynamic> toJson() => {'type': 'loading'};
}

class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'authenticated', 'user': user.toJson()};
  }
}

class AuthUnauthenticated extends AuthState {
  @override
  Map<String, dynamic> toJson() => {'type': 'unauthenticated'};
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'error', 'message': message};
  }
}
