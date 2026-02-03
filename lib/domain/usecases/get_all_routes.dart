import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/route_repository.dart';

class GetAllRoutes {
  final RouteRepository repository;

  GetAllRoutes(this.repository);

  Future<Either<Failure, List<BusRoute>>> call() async {
    return await repository.getAllRoutes();
  }
}
