import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/rider_location_update.dart';

abstract class RiderLocationRepository {
  /// Store a location update
  Future<Either<Failure, void>> storeLocationUpdate(RiderLocationUpdate update);

  /// Get location history for a rider
  Future<Either<Failure, List<RiderLocationUpdate>>> getLocationHistory({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  });

  /// Watch real-time location updates for a bus
  Stream<Either<Failure, RiderLocationUpdate?>> watchBusLocation(String busId);
}
