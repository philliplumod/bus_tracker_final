import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/user_assignment_repository.dart';

class GetUserAssignedRoute {
  final UserAssignmentRepository repository;

  GetUserAssignedRoute(this.repository);

  Future<Either<Failure, BusRoute?>> call(String userId) async {
    return await repository.getUserAssignedRoute(userId);
  }
}
