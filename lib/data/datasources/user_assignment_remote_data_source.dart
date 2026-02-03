import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_assignment.dart';
import '../../domain/entities/route.dart';
import 'route_remote_data_source.dart';

abstract class UserAssignmentRemoteDataSource {
  Future<UserAssignment?> getUserAssignment(String userId);
  Future<BusRoute?> getUserAssignedRoute(String userId);
  Stream<UserAssignment?> watchUserAssignment(String userId);
}

class UserAssignmentRemoteDataSourceImpl
    implements UserAssignmentRemoteDataSource {
  final DatabaseReference _dbRef;
  final RouteRemoteDataSource _routeDataSource;

  UserAssignmentRemoteDataSourceImpl({
    DatabaseReference? dbRef,
    required RouteRemoteDataSource routeDataSource,
  }) : _dbRef = dbRef ?? FirebaseDatabase.instance.ref(),
       _routeDataSource = routeDataSource;

  @override
  Future<UserAssignment?> getUserAssignment(String userId) async {
    try {
      final snapshot =
          await _dbRef
              .child('user_assignments')
              .orderByChild('user_id')
              .equalTo(userId)
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
        assignmentData['assignment_id'] = entry.key.toString();
        return UserAssignment.fromJson(assignmentData);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch user assignment: $e');
    }
  }

  @override
  Future<BusRoute?> getUserAssignedRoute(String userId) async {
    try {
      // Get user assignment
      final assignment = await getUserAssignment(userId);
      if (assignment == null) return null;

      // Get bus_route info
      final busRouteSnapshot =
          await _dbRef.child('bus_routes/${assignment.busRouteId}').get();

      if (busRouteSnapshot.value == null || busRouteSnapshot.value is! Map) {
        return null;
      }

      final busRouteData = busRouteSnapshot.value as Map;
      final routeId = busRouteData['route_id'] as String?;

      if (routeId == null) return null;

      // Get full route details
      return await _routeDataSource.getRouteById(routeId);
    } catch (e) {
      throw Exception('Failed to fetch user assigned route: $e');
    }
  }

  @override
  Stream<UserAssignment?> watchUserAssignment(String userId) {
    return _dbRef
        .child('user_assignments')
        .orderByChild('user_id')
        .equalTo(userId)
        .limitToFirst(1)
        .onValue
        .map((event) {
          final snapshot = event.snapshot;

          if (snapshot.value == null || snapshot.value is! Map) {
            return null;
          }

          final data = snapshot.value as Map<Object?, Object?>;
          if (data.isEmpty) return null;

          final entry = data.entries.first;
          if (entry.value is Map) {
            try {
              final assignmentData = Map<String, dynamic>.from(
                entry.value as Map,
              );
              assignmentData['assignment_id'] = entry.key.toString();
              return UserAssignment.fromJson(assignmentData);
            } catch (e) {
              debugPrint('Error parsing user assignment: $e');
              return null;
            }
          }

          return null;
        });
  }
}
