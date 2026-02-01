import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class LocationFailure extends Failure {
  final String code;

  const LocationFailure(super.message, this.code);

  @override
  List<Object> get props => [message, code];
}

class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
