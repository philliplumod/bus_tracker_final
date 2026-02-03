import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/route_repository.dart';

class GetRoutesByBusId {
  final RouteRepository repository;

  GetRoutesByBusId(this.repository);

  Future<Either<Failure, List<BusRoute>>> call(String busId) async {
    return await repository.getRoutesByBusId(busId);
  }
}
