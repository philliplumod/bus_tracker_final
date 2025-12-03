import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/bus.dart';
import '../../domain/repositories/bus_repository.dart';
import '../datasources/bus_remote_data_source.dart';

class BusRepositoryImpl implements BusRepository {
  final BusRemoteDataSource remoteDataSource;

  BusRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Bus>>> getNearbyBuses() async {
    try {
      final buses = await remoteDataSource.getNearbyBuses();
      return Right(buses);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Bus>>> watchBusUpdates() {
    try {
      return remoteDataSource.watchBusUpdates().map((buses) => Right(buses));
    } catch (e) {
      return Stream.value(Left(FirebaseFailure(e.toString())));
    }
  }
}
