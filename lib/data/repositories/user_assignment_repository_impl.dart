import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_assignment.dart';
import '../../domain/entities/route.dart';
import '../../domain/repositories/user_assignment_repository.dart';
import '../datasources/user_assignment_remote_data_source.dart';

class UserAssignmentRepositoryImpl implements UserAssignmentRepository {
  final UserAssignmentRemoteDataSource remoteDataSource;

  UserAssignmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserAssignment?>> getUserAssignment(
    String userId,
  ) async {
    try {
      final assignment = await remoteDataSource.getUserAssignment(userId);
      return Right(assignment);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BusRoute?>> getUserAssignedRoute(String userId) async {
    try {
      final route = await remoteDataSource.getUserAssignedRoute(userId);
      return Right(route);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserAssignment?>> watchUserAssignment(String userId) {
    try {
      return remoteDataSource
          .watchUserAssignment(userId)
          .map((assignment) => Right(assignment));
    } catch (e) {
      return Stream.value(Left(FirebaseFailure(e.toString())));
    }
  }
}
