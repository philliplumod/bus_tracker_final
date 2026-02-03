import '../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/route_repository.dart';
import 'package:dartz/dartz.dart';

class WatchRouteUpdates {
  final RouteRepository repository;

  WatchRouteUpdates(this.repository);

  Stream<Either<Failure, List<BusRoute>>> call() {
    return repository.watchRouteUpdates();
  }
}
