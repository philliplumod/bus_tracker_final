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
        debugPrint('⚠️ Empty or null response from API');
        return [];
      }

      final List<dynamic> assignmentsJson = response['userAssignments'] as List;
      debugPrint('📦 Received ${assignmentsJson.length} assignments from API');

      final List<UserAssignment> assignments = [];

      for (var i = 0; i < assignmentsJson.length; i++) {
        try {
          final json = Map<String, dynamic>.from(assignmentsJson[i] as Map);
          final model = ApiUserAssignmentModel.fromJson(json);

          // Validate the model has required nested data
          if (model.user == null) {
            debugPrint('⚠️ Assignment [$i] missing "user" object');
            debugPrint(
              '   This indicates backend is not returning nested data',
            );
            debugPrint('   See BACKEND_API_REQUIREMENTS.md for correct format');
            continue;
          }

          if (model.busRoute == null) {
            debugPrint('⚠️ Assignment [$i] missing "bus_route" object');
            debugPrint('   Backend needs to JOIN bus_routes table');
            continue;
          }

          if (model.busRoute!.route == null) {
            debugPrint('⚠️ Assignment [$i] missing "bus_route.route" object');
            debugPrint('   Backend needs to JOIN routes table');
            continue;
          }

          final entity = model.toEntity();
          assignments.add(entity);
        } catch (e) {
          debugPrint('❌ Error converting assignment [$i]: $e');
          debugPrint('   JSON: ${assignmentsJson[i]}');
          // Continue processing other assignments
          continue;
        }
      }

      if (assignments.isEmpty && assignmentsJson.isNotEmpty) {
        debugPrint(
          '❌ CRITICAL: Backend returned ${assignmentsJson.length} assignments',
        );
        debugPrint('   but NONE could be converted to entities!');
        debugPrint('   ');
        debugPrint('   This means your backend is NOT returning the required');
        debugPrint(
          '   nested structure with user, bus_route, and route objects.',
        );
        debugPrint('   ');
        debugPrint('   ⚠️  ACTION REQUIRED:');
        debugPrint(
          '   See BACKEND_API_REQUIREMENTS.md for the exact SQL query',
        );
        debugPrint('   and JSON structure your backend MUST return.');
      }

      debugPrint(
        '✅ Successfully converted ${assignments.length} user-assignments',
      );
      return assignments;
    } catch (e) {
      debugPrint('❌ Error fetching user-assignments: $e');
      rethrow;
    }
  }

  /// GET /api/user-assignments for a specific user
  Future<UserAssignment?> getUserAssignment(String userId) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔍 getUserAssignment called');
      debugPrint('   Looking for userId: "$userId"');
      debugPrint('   userId type: ${userId.runtimeType}');
      debugPrint('   userId length: ${userId.length}');

      final assignments = await getUserAssignments();

      debugPrint('📊 Fetched ${assignments.length} total assignments from API');

      if (assignments.isEmpty) {
        debugPrint('❌ No assignments exist in database at all!');
        debugPrint('   → Admin needs to create assignments first');
        debugPrint('═══════════════════════════════════════');
        return null;
      }

      // Debug: Print all available assignments
      debugPrint('📋 All assignments in database:');
      for (var i = 0; i < assignments.length; i++) {
        final a = assignments[i];
        debugPrint('   [$i] userId: "${a.userId}"');
        debugPrint('       busName: ${a.busName}');
        debugPrint('       routeName: ${a.routeName}');
        debugPrint('       exact match: ${a.userId == userId}');
        debugPrint(
          '       case-insensitive match: ${a.userId.toLowerCase() == userId.toLowerCase()}',
        );
      }

      // Find matching assignment (exact match)
      var match = assignments.where((a) => a.userId == userId).firstOrNull;

      // Try case-insensitive match if exact match fails
      if (match == null) {
        debugPrint('⚠️ No exact match found, trying case-insensitive match...');
        match =
            assignments
                .where((a) => a.userId.toLowerCase() == userId.toLowerCase())
                .firstOrNull;
      }

      if (match != null) {
        debugPrint('✅ MATCH FOUND!');
        debugPrint('   Assignment ID: ${match.id}');
        debugPrint('   User ID: ${match.userId}');
        debugPrint('   Bus: ${match.busName} (${match.busId})');
        debugPrint('   Route: ${match.routeName} (${match.routeId})');
        debugPrint('   Starting Terminal: ${match.startingTerminalName}');
        debugPrint('   Destination Terminal: ${match.destinationTerminalName}');
      } else {
        debugPrint('❌ NO MATCH FOUND!');
        debugPrint('   Searched for userId: "$userId"');
        debugPrint('   Available userIds in database:');
        for (var a in assignments) {
          debugPrint('     - "${a.userId}"');
        }
        debugPrint('   ');
        debugPrint('   Possible reasons:');
        debugPrint('   1. User is not assigned to any bus/route');
        debugPrint('   2. User ID mismatch (check spelling/format)');
        debugPrint('   3. Assignment was deleted');
      }

      debugPrint('═══════════════════════════════════════');
      return match;
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
