import 'package:flutter/foundation.dart';
import '../../domain/entities/terminal.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/bus_route_assignment.dart';
import '../../domain/entities/user_assignment.dart';
import '../models/api_terminal_model.dart';
import '../models/api_route_model.dart';
import '../models/api_bus_model.dart';
import '../models/api_bus_route_model.dart';
import '../models/api_user_assignment_model.dart';
import 'api_client.dart';

/// Backend API service for Bus Tracking Dashboard
class BackendApiService {
  final ApiClient apiClient;

  BackendApiService({required this.apiClient});

  /// GET /api/terminals - Retrieves all bus terminals
  Future<List<Terminal>> getTerminals() async {
    try {
      debugPrint('🚀 Fetching terminals from API...');
      final response = await apiClient.get('/api/terminals');

      if (response == null || response['terminals'] == null) {
        return [];
      }

      final List<dynamic> terminalsJson = response['terminals'] as List;
      final terminals =
          terminalsJson
              .map(
                (json) =>
                    ApiTerminalModel.fromJson(
                      Map<String, dynamic>.from(json as Map),
                    ).toEntity(),
              )
              .toList();

      debugPrint('✅ Fetched ${terminals.length} terminals');
      return terminals;
    } catch (e) {
      debugPrint('❌ Error fetching terminals: $e');
      rethrow;
    }
  }

  /// GET /api/buses - Retrieves all buses
  Future<List<Bus>> getBuses() async {
    try {
      debugPrint('🚀 Fetching buses from API...');
      final response = await apiClient.get('/api/buses');

      if (response == null || response['buses'] == null) {
        return [];
      }

      final List<dynamic> busesJson = response['buses'] as List;
      final buses =
          busesJson
              .map(
                (json) =>
                    ApiBusModel.fromJson(
                      Map<String, dynamic>.from(json as Map),
                    ).toEntity(),
              )
              .toList();

      debugPrint('✅ Fetched ${buses.length} buses');
      return buses;
    } catch (e) {
      debugPrint('❌ Error fetching buses: $e');
      rethrow;
    }
  }

  /// GET /api/routes - Retrieves all routes with terminal information
  Future<List<BusRoute>> getRoutes() async {
    try {
      debugPrint('🚀 Fetching routes from API...');
      final response = await apiClient.get('/api/routes');

      if (response == null || response['routes'] == null) {
        return [];
      }

      final List<dynamic> routesJson = response['routes'] as List;
      final routes =
          routesJson
              .map(
                (json) =>
                    ApiRouteModel.fromJson(
                      Map<String, dynamic>.from(json as Map),
                    ).toEntity(),
              )
              .toList();

      debugPrint('✅ Fetched ${routes.length} routes');
      return routes;
    } catch (e) {
      debugPrint('❌ Error fetching routes: $e');
      rethrow;
    }
  }

  /// GET /api/bus-routes - Retrieves all bus-route assignments
  Future<List<BusRouteAssignment>> getBusRoutes() async {
    try {
      debugPrint('🚀 Fetching bus-routes from API...');
      final response = await apiClient.get('/api/bus-routes');

      if (response == null || response['busRoutes'] == null) {
        return [];
      }

      final List<dynamic> busRoutesJson = response['busRoutes'] as List;
      final busRoutes =
          busRoutesJson
              .map(
                (json) =>
                    ApiBusRouteModel.fromJson(
                      Map<String, dynamic>.from(json as Map),
                    ).toEntity(),
              )
              .toList();

      debugPrint('✅ Fetched ${busRoutes.length} bus-routes');
      return busRoutes;
    } catch (e) {
      debugPrint('❌ Error fetching bus-routes: $e');
      rethrow;
    }
  }

  /// GET /api/user-assignments - Retrieves all user assignments
  Future<List<UserAssignment>> getUserAssignments() async {
    try {
      debugPrint('🚀 Fetching user-assignments from API...');
      final response = await apiClient.get('/api/user-assignments');

      if (response == null || response['userAssignments'] == null) {
        return [];
      }

      final List<dynamic> assignmentsJson = response['userAssignments'] as List;
      final assignments =
          assignmentsJson
              .map(
                (json) =>
                    ApiUserAssignmentModel.fromJson(
                      Map<String, dynamic>.from(json as Map),
                    ).toEntity(),
              )
              .toList();

      debugPrint('✅ Fetched ${assignments.length} user-assignments');
      return assignments;
    } catch (e) {
      debugPrint('❌ Error fetching user-assignments: $e');
      rethrow;
    }
  }

  /// GET /api/user-assignments for a specific user
  Future<UserAssignment?> getUserAssignment(String userId) async {
    try {
      final assignments = await getUserAssignments();
      return assignments.where((a) => a.userId == userId).firstOrNull;
    } catch (e) {
      debugPrint('❌ Error fetching user assignment for $userId: $e');
      rethrow;
    }
  }

  /// GET specific bus route by busId
  Future<BusRouteAssignment?> getBusRouteByBusId(String busId) async {
    try {
      final busRoutes = await getBusRoutes();
      return busRoutes.where((br) => br.busId == busId).firstOrNull;
    } catch (e) {
      debugPrint('❌ Error fetching bus route for $busId: $e');
      rethrow;
    }
  }

  /// GET specific route by routeId
  Future<BusRoute?> getRouteById(String routeId) async {
    try {
      final routes = await getRoutes();
      return routes.where((r) => r.id == routeId).firstOrNull;
    } catch (e) {
      debugPrint('❌ Error fetching route $routeId: $e');
      rethrow;
    }
  }
}
