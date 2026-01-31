import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repository;

  SignIn(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    return await repository.signIn(email: email, password: password);
  }
}
