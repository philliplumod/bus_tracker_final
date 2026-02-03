import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/terminal.dart';
import '../../domain/entities/bus_route_assignment.dart';

abstract class RouteRemoteDataSource {
  Future<List<BusRoute>> getAllRoutes();
  Future<BusRoute> getRouteById(String routeId);
  Future<List<BusRoute>> getRoutesByBusId(String busId);
  Future<List<Terminal>> getAllTerminals();
  Future<Terminal> getTerminalById(String terminalId);
  Future<List<BusRouteAssignment>> getBusRouteAssignments();
  Future<BusRouteAssignment?> getBusRouteAssignmentByBusId(String busId);
  Stream<List<BusRoute>> watchRouteUpdates();
}

class RouteRemoteDataSourceImpl implements RouteRemoteDataSource {
  final DatabaseReference _dbRef;

  RouteRemoteDataSourceImpl({DatabaseReference? dbRef})
    : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  @override
  Future<List<Terminal>> getAllTerminals() async {
    try {
      final snapshot = await _dbRef.child('terminals').get();

      if (snapshot.value == null || snapshot.value is! Map) {
        return [];
      }

      final data = snapshot.value as Map<Object?, Object?>;
      final terminals = <Terminal>[];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            final terminalData = Map<String, dynamic>.from(value);
            terminalData['terminal_id'] = key.toString();
            terminals.add(Terminal.fromJson(terminalData));
          } catch (e) {
            debugPrint('Error parsing terminal $key: $e');
          }
        }
      });

      return terminals;
    } catch (e) {
      throw Exception('Failed to fetch terminals: $e');
    }
  }

  @override
  Future<Terminal> getTerminalById(String terminalId) async {
    try {
      final snapshot = await _dbRef.child('terminals/$terminalId').get();

      if (snapshot.value == null || snapshot.value is! Map) {
        throw Exception('Terminal not found');
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['terminal_id'] = terminalId;
      return Terminal.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch terminal: $e');
    }
  }

  @override
  Future<List<BusRoute>> getAllRoutes() async {
    try {
      final snapshot = await _dbRef.child('routes').get();

      if (snapshot.value == null || snapshot.value is! Map) {
        return [];
      }

      final data = snapshot.value as Map<Object?, Object?>;
      final routes = <BusRoute>[];

      // Fetch all terminals first for mapping
      final terminals = await getAllTerminals();
      final terminalMap = {for (var t in terminals) t.id: t};

      data.forEach((key, value) async {
        if (value is Map) {
          try {
            final routeData = Map<String, dynamic>.from(value);
            routeData['route_id'] = key.toString();

            final startingTerminalId =
                routeData['starting_terminal_id'] as String?;
            final destinationTerminalId =
                routeData['destination_terminal_id'] as String?;

            if (startingTerminalId != null && destinationTerminalId != null) {
              final startingTerminal = terminalMap[startingTerminalId];
              final destinationTerminal = terminalMap[destinationTerminalId];

              if (startingTerminal != null && destinationTerminal != null) {
                routes.add(
                  BusRoute.fromJson(
                    routeData,
                    startingTerminal,
                    destinationTerminal,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error parsing route $key: $e');
          }
        }
      });

      return routes;
    } catch (e) {
      throw Exception('Failed to fetch routes: $e');
    }
  }

  @override
  Future<BusRoute> getRouteById(String routeId) async {
    try {
      final snapshot = await _dbRef.child('routes/$routeId').get();

      if (snapshot.value == null || snapshot.value is! Map) {
        throw Exception('Route not found');
      }

      final routeData = Map<String, dynamic>.from(snapshot.value as Map);
      routeData['route_id'] = routeId;

      final startingTerminalId = routeData['starting_terminal_id'] as String?;
      final destinationTerminalId =
          routeData['destination_terminal_id'] as String?;

      if (startingTerminalId == null || destinationTerminalId == null) {
        throw Exception('Route terminals not found');
      }

      final startingTerminal = await getTerminalById(startingTerminalId);
      final destinationTerminal = await getTerminalById(destinationTerminalId);

      return BusRoute.fromJson(
        routeData,
        startingTerminal,
        destinationTerminal,
      );
    } catch (e) {
      throw Exception('Failed to fetch route: $e');
    }
  }

  @override
  Future<List<BusRoute>> getRoutesByBusId(String busId) async {
    try {
      // Get bus_route_id from bus_routes table
      final busRoutesSnapshot =
          await _dbRef
              .child('bus_routes')
              .orderByChild('bus_id')
              .equalTo(busId)
              .get();

      if (busRoutesSnapshot.value == null || busRoutesSnapshot.value is! Map) {
        return [];
      }

      final busRoutesData = busRoutesSnapshot.value as Map<Object?, Object?>;
      final routes = <BusRoute>[];

      for (var entry in busRoutesData.entries) {
        if (entry.value is Map) {
          final busRouteData = entry.value as Map;
          final routeId = busRouteData['route_id'] as String?;
          if (routeId != null) {
            try {
              final route = await getRouteById(routeId);
              routes.add(route);
            } catch (e) {
              debugPrint('Error fetching route $routeId: $e');
            }
          }
        }
      }

      return routes;
    } catch (e) {
      throw Exception('Failed to fetch routes for bus: $e');
    }
  }

  @override
  Future<List<BusRouteAssignment>> getBusRouteAssignments() async {
    try {
      final snapshot = await _dbRef.child('bus_routes').get();

      if (snapshot.value == null || snapshot.value is! Map) {
        return [];
      }

      final data = snapshot.value as Map<Object?, Object?>;
      final assignments = <BusRouteAssignment>[];

      data.forEach((key, value) {
        if (value is Map) {
          try {
            final assignmentData = Map<String, dynamic>.from(value);
            assignmentData['bus_route_id'] = key.toString();
            assignments.add(BusRouteAssignment.fromJson(assignmentData));
          } catch (e) {
            debugPrint('Error parsing bus route assignment $key: $e');
          }
        }
      });

      return assignments;
    } catch (e) {
      throw Exception('Failed to fetch bus route assignments: $e');
    }
  }

  @override
  Future<BusRouteAssignment?> getBusRouteAssignmentByBusId(String busId) async {
    try {
      final snapshot =
          await _dbRef
              .child('bus_routes')
              .orderByChild('bus_id')
              .equalTo(busId)
              .limitToFirst(1)
              .get();

      if (snapshot.value == null || snapshot.value is! Map) {
        return null;
      }

      final data = snapshot.value as Map<Object?, Object?>;
      if (data.isEmpty) return null;

      final entry = data.entries.first;
      if (entry.value is Map) {
        final assignmentData = Map<String, dynamic>.from(entry.value as Map);
        assignmentData['bus_route_id'] = entry.key.toString();
        return BusRouteAssignment.fromJson(assignmentData);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch bus route assignment: $e');
    }
  }

  @override
  Stream<List<BusRoute>> watchRouteUpdates() {
    return _dbRef.child('routes').onValue.asyncMap((event) async {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        return <BusRoute>[];
      }

      final data = snapshot.value as Map<Object?, Object?>;
      final routes = <BusRoute>[];

      // Fetch all terminals first
      final terminals = await getAllTerminals();
      final terminalMap = {for (var t in terminals) t.id: t};

      data.forEach((key, value) {
        if (value is Map) {
          try {
            final routeData = Map<String, dynamic>.from(value);
            routeData['route_id'] = key.toString();

            final startingTerminalId =
                routeData['starting_terminal_id'] as String?;
            final destinationTerminalId =
                routeData['destination_terminal_id'] as String?;

            if (startingTerminalId != null && destinationTerminalId != null) {
              final startingTerminal = terminalMap[startingTerminalId];
              final destinationTerminal = terminalMap[destinationTerminalId];

              if (startingTerminal != null && destinationTerminal != null) {
                routes.add(
                  BusRoute.fromJson(
                    routeData,
                    startingTerminal,
                    destinationTerminal,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error parsing route $key: $e');
          }
        }
      });

      return routes;
    });
  }
}
