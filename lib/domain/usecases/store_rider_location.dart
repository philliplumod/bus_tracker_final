import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/rider_location_update.dart';
import '../repositories/rider_location_repository.dart';

class StoreRiderLocation {
  final RiderLocationRepository repository;

  StoreRiderLocation(this.repository);

  Future<Either<Failure, void>> call(RiderLocationUpdate update) async {
    return await repository.storeLocationUpdate(update);
  }
}
