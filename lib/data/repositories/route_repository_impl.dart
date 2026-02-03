import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/terminal.dart';
import '../../domain/entities/bus_route_assignment.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_remote_data_source.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource remoteDataSource;

  RouteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<BusRoute>>> getAllRoutes() async {
    try {
      final routes = await remoteDataSource.getAllRoutes();
      return Right(routes);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BusRoute>> getRouteById(String routeId) async {
    try {
      final route = await remoteDataSource.getRouteById(routeId);
      return Right(route);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BusRoute>>> getRoutesByBusId(String busId) async {
    try {
      final routes = await remoteDataSource.getRoutesByBusId(busId);
      return Right(routes);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Terminal>>> getAllTerminals() async {
    try {
      final terminals = await remoteDataSource.getAllTerminals();
      return Right(terminals);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Terminal>> getTerminalById(String terminalId) async {
    try {
      final terminal = await remoteDataSource.getTerminalById(terminalId);
      return Right(terminal);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BusRouteAssignment>>>
  getBusRouteAssignments() async {
    try {
      final assignments = await remoteDataSource.getBusRouteAssignments();
      return Right(assignments);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BusRouteAssignment?>> getBusRouteAssignmentByBusId(
    String busId,
  ) async {
    try {
      final assignment = await remoteDataSource.getBusRouteAssignmentByBusId(
        busId,
      );
      return Right(assignment);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<BusRoute>>> watchRouteUpdates() {
    try {
      return remoteDataSource.watchRouteUpdates().map(
        (routes) => Right(routes),
      );
    } catch (e) {
      return Stream.value(Left(FirebaseFailure(e.toString())));
    }
  }
}
