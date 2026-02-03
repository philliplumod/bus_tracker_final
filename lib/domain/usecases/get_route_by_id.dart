import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/route_repository.dart';

class GetRouteById {
  final RouteRepository repository;

  GetRouteById(this.repository);

  Future<Either<Failure, BusRoute>> call(String routeId) async {
    return await repository.getRouteById(routeId);
  }
}
