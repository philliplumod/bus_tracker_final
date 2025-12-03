import 'package:dartz/dartz.dart';
import '../entities/user_location.dart';
import '../../core/error/failures.dart';

abstract class LocationRepository {
  Future<Either<Failure, UserLocation>> getUserLocation();
  Stream<Either<Failure, UserLocation>> watchUserLocation();
}
