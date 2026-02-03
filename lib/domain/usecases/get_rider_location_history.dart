import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/rider_location_update.dart';
import '../repositories/rider_location_repository.dart';

class GetRiderLocationHistory {
  final RiderLocationRepository repository;

  GetRiderLocationHistory(this.repository);

  Future<Either<Failure, List<RiderLocationUpdate>>> call({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    return await repository.getLocationHistory(
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      limit: limit,
    );
  }
}
