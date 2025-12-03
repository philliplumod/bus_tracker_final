import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_location.dart';
import '../repositories/location_repository.dart';

class GetUserLocation {
  final LocationRepository repository;

  GetUserLocation(this.repository);

  Future<Either<Failure, UserLocation>> call() async {
    return await repository.getUserLocation();
  }
}
