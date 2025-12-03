import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/bus.dart';
import '../repositories/bus_repository.dart';

class GetNearbyBuses {
  final BusRepository repository;

  GetNearbyBuses(this.repository);

  Future<Either<Failure, List<Bus>>> call() async {
    return await repository.getNearbyBuses();
  }
}
