import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_assignment.dart';
import '../../domain/entities/route.dart';
import '../../domain/repositories/user_assignment_repository.dart';
import '../datasources/supabase_user_assignment_data_source.dart';

class UserAssignmentRepositoryImpl implements UserAssignmentRepository {
  final SupabaseUserAssignmentDataSource supabaseDataSource;

  UserAssignmentRepositoryImpl({required this.supabaseDataSource});

  @override
  Future<Either<Failure, UserAssignment?>> getUserAssignment(
    String userId,
  ) async {
    try {
      final assignment = await supabaseDataSource.getUserAssignment(userId);
      return Right(assignment);
    } catch (e) {
      return Left(FirebaseFailure('Supabase error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BusRoute?>> getUserAssignedRoute(String userId) async {
    try {
      // This would need a separate Supabase query if you want to get the full route
      // For now, returning null as this might not be needed with direct Supabase access
      return const Right(null);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserAssignment?>> watchUserAssignment(String userId) {
    try {
      // Convert Supabase real-time subscription to stream
      final streamController =
          StreamController<Either<Failure, UserAssignment?>>();

      final channel = supabaseDataSource.subscribeToUserAssignment(userId, (
        assignment,
      ) {
        if (!streamController.isClosed) {
          streamController.add(Right(assignment));
        }
      });

      // Clean up on stream close
      streamController.onCancel = () {
        supabaseDataSource.unsubscribe(channel);
      };

      return streamController.stream;
    } catch (e) {
      return Stream.value(Left(FirebaseFailure(e.toString())));
    }
  }
}
