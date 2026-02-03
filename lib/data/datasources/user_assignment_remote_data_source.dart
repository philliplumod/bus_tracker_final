import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_assignment.dart';
import '../../domain/entities/route.dart';
import 'backend_api_service.dart';

abstract class UserAssignmentRemoteDataSource {
  Future<UserAssignment?> getUserAssignment(String userId);
  Future<BusRoute?> getUserAssignedRoute(String userId);
  Stream<UserAssignment?> watchUserAssignment(String userId);
}

class UserAssignmentRemoteDataSourceImpl
    implements UserAssignmentRemoteDataSource {
  final BackendApiService _backendApi;
  final DatabaseReference _dbRef;

  UserAssignmentRemoteDataSourceImpl({
    required BackendApiService backendApi,
    DatabaseReference? dbRef,
  }) : _backendApi = backendApi,
       _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  @override
  Future<UserAssignment?> getUserAssignment(String userId) async {
    try {
      debugPrint(
        '📡 Fetching user assignment from backend API for user: $userId',
      );
      final assignment = await _backendApi.getUserAssignment(userId);

      if (assignment != null) {
        debugPrint('✅ User assignment found:');
        debugPrint('   Bus: ${assignment.busName}');
        debugPrint('   Route: ${assignment.routeName}');
      } else {
        debugPrint('⚠️ No assignment found for user $userId in database');
        debugPrint('   This user may not be assigned to any bus/route yet');
      }

      return assignment;
    } on Exception catch (e) {
      debugPrint('❌ Failed to fetch user assignment from API: $e');
      // Re-throw with more context
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        throw Exception(
          'Authentication failed. Please check network connection and try logging in again.',
        );
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Make sure backend is running and network is configured.',
        );
      } else {
        throw Exception('Failed to fetch user assignment: $e');
      }
    }
  }

  @override
  Future<BusRoute?> getUserAssignedRoute(String userId) async {
    try {
      // Get user assignment from backend API
      final assignment = await getUserAssignment(userId);
      if (assignment == null) return null;

      // Get full route details from backend API
      final route = await _backendApi.getRouteById(assignment.routeId);
      return route;
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
