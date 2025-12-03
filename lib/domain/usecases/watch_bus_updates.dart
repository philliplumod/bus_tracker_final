import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/bus.dart';
import '../repositories/bus_repository.dart';

class WatchBusUpdates {
  final BusRepository repository;

  WatchBusUpdates(this.repository);

  Stream<Either<Failure, List<Bus>>> call() {
    return repository.watchBusUpdates();
  }
}
