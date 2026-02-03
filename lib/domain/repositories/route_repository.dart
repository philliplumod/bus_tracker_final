import 'package:dartz/dartz.dart';
import '../entities/route.dart';
import '../entities/terminal.dart';
import '../entities/bus_route_assignment.dart';
import '../../core/error/failures.dart';

abstract class RouteRepository {
  /// Get all available routes
  Future<Either<Failure, List<BusRoute>>> getAllRoutes();

  /// Get a specific route by ID
  Future<Either<Failure, BusRoute>> getRouteById(String routeId);

  /// Get routes for a specific bus
  Future<Either<Failure, List<BusRoute>>> getRoutesByBusId(String busId);

  /// Get all terminals
  Future<Either<Failure, List<Terminal>>> getAllTerminals();

  /// Get a specific terminal by ID
  Future<Either<Failure, Terminal>> getTerminalById(String terminalId);

  /// Get bus-route assignments
  Future<Either<Failure, List<BusRouteAssignment>>> getBusRouteAssignments();

  /// Get bus-route assignment by bus ID
  Future<Either<Failure, BusRouteAssignment?>> getBusRouteAssignmentByBusId(
    String busId,
  );

  /// Watch for route updates
  Stream<Either<Failure, List<BusRoute>>> watchRouteUpdates();
}
