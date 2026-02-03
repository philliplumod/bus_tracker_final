import 'package:dartz/dartz.dart';
import '../entities/user_assignment.dart';
import '../entities/route.dart';
import '../../core/error/failures.dart';

abstract class UserAssignmentRepository {
  /// Get user assignment by user ID
  Future<Either<Failure, UserAssignment?>> getUserAssignment(String userId);

  /// Get the full route details for a user's assignment
  Future<Either<Failure, BusRoute?>> getUserAssignedRoute(String userId);

  /// Watch for changes to user assignments
  Stream<Either<Failure, UserAssignment?>> watchUserAssignment(String userId);
}
