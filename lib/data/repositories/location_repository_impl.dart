import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;

  LocationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, UserLocation>> getUserLocation() async {
    try {
      final location = await localDataSource.getUserLocation();
      return Right(location);
    } catch (e) {
      return Left(LocationFailure(e.toString(), 'LOCATION_ERROR'));
    }
  }

  @override
  Stream<Either<Failure, UserLocation>> watchUserLocation() {
    try {
      return localDataSource.watchUserLocation().map(
        (location) => Right(location),
      );
    } catch (e) {
      return Stream.value(
        Left(LocationFailure(e.toString(), 'LOCATION_ERROR')),
      );
    }
  }
}
