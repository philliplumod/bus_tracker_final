import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/rider_location_update.dart';
import '../../domain/repositories/rider_location_repository.dart';
import '../datasources/rider_location_remote_data_source.dart';
import '../models/rider_location_update_model.dart';

class RiderLocationRepositoryImpl implements RiderLocationRepository {
  final RiderLocationRemoteDataSource remoteDataSource;

  RiderLocationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> storeLocationUpdate(
    RiderLocationUpdate update,
  ) async {
    try {
      debugPrint(
        '🔄 Repository: Storing location update for ${update.userName}',
      );
      debugPrint('   Location: (${update.latitude}, ${update.longitude})');
      final model = RiderLocationUpdateModel.fromEntity(update);
      await remoteDataSource.storeLocationUpdate(model);
      debugPrint('✅ Repository: Location stored successfully');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ Repository: Failed to store location - $e');
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RiderLocationUpdate>>> getLocationHistory({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      final updates = await remoteDataSource.getLocationHistory(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        limit: limit,
      );
      return Right(updates);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RiderLocationUpdate?>> watchBusLocation(String busId) {
    try {
      return remoteDataSource
          .watchBusLocation(busId)
          .map((update) => Right(update));
    } catch (e) {
      return Stream.value(Left(FirebaseFailure(e.toString())));
    }
  }
}
