import 'package:dartz/dartz.dart';
import '../entities/bus.dart';
import '../../core/error/failures.dart';

abstract class BusRepository {
  Future<Either<Failure, List<Bus>>> getNearbyBuses();
  Stream<Either<Failure, List<Bus>>> watchBusUpdates();
}
