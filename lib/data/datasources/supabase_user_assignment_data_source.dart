import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/entities/user_assignment.dart';

/// Supabase data source for user assignments
/// Connects directly to Supabase database instead of going through backend API
class SupabaseUserAssignmentDataSource {
  static SupabaseClient? _client;

  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_client != null) return;

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: kDebugMode,
    );
    _client = Supabase.instance.client;
    debugPrint('✅ Supabase client initialized');
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase not initialized! Call SupabaseUserAssignmentDataSource.initialize() first',
      );
    }
    return _client!;
  }

  /// Fetch user assignment from user_assignments_detailed view
  Future<UserAssignment?> getUserAssignment(String userId) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔍 Fetching user assignment from Supabase');
      debugPrint('   User ID: $userId');
      debugPrint('   Table: user_assignments_detailed');

      final response =
          await client
              .from('user_assignments_detailed')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) {
        debugPrint('❌ No assignment found for user: $userId');
        return null;
      }

      debugPrint('✅ Assignment data retrieved from Supabase');
      debugPrint('   Bus: ${response['bus_name']}');
      debugPrint('   Route: ${response['route_name']}');

      // Convert Supabase response to UserAssignment entity
      return UserAssignment(
        id: response['assignment_id'] as String,
        userId: response['user_id'] as String,
        busRouteId: response['bus_route_id'] as String,
        busId: response['bus_id'] as String,
        busName: response['bus_name'] as String?,
        routeId: response['route_id'] as String,
        routeName: response['route_name'] as String?,
        startingTerminalId: response['starting_terminal_id'] as String?,
        startingTerminalName: response['starting_terminal_name'] as String?,
        destinationTerminalId: response['destination_terminal_id'] as String?,
        destinationTerminalName:
            response['destination_terminal_name'] as String?,
        assignedAt:
            response['assigned_at'] != null
                ? DateTime.parse(response['assigned_at'] as String)
                : null,
        updatedAt:
            response['updated_at'] != null
                ? DateTime.parse(response['updated_at'] as String)
                : null,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Supabase error fetching user assignment: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch all user assignments (for admin use)
  Future<List<UserAssignment>> getAllUserAssignments() async {
    try {
      debugPrint('🔍 Fetching all user assignments from Supabase');

      final response = await client
          .from('user_assignments_detailed')
          .select()
          .order('assigned_at', ascending: false);

      if (response.isEmpty) {
        debugPrint('⚠️ No assignments found in database');
        return [];
      }

      debugPrint('✅ Retrieved ${response.length} assignments from Supabase');

      return response.map<UserAssignment>((data) {
        return UserAssignment(
          id: data['assignment_id'] as String,
          userId: data['user_id'] as String,
          busRouteId: data['bus_route_id'] as String,
          busId: data['bus_id'] as String,
          busName: data['bus_name'] as String?,
          routeId: data['route_id'] as String,
          routeName: data['route_name'] as String?,
          startingTerminalId: data['starting_terminal_id'] as String?,
          startingTerminalName: data['starting_terminal_name'] as String?,
          destinationTerminalId: data['destination_terminal_id'] as String?,
          destinationTerminalName: data['destination_terminal_name'] as String?,
          assignedAt:
              data['assigned_at'] != null
                  ? DateTime.parse(data['assigned_at'] as String)
                  : null,
          updatedAt:
              data['updated_at'] != null
                  ? DateTime.parse(data['updated_at'] as String)
                  : null,
        );
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Supabase error fetching all assignments: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Subscribe to real-time updates for a user's assignment
  RealtimeChannel subscribeToUserAssignment(
    String userId,
    void Function(UserAssignment?) onUpdate,
  ) {
    debugPrint('👂 Subscribing to real-time updates for user: $userId');

    final channel =
        client
            .channel('user_assignment_$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'user_assignments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) async {
                debugPrint('🔔 Real-time update received for user assignment');
                // Fetch fresh data when change detected
                final assignment = await getUserAssignment(userId);
                onUpdate(assignment);
              },
            )
            .subscribe();

    return channel;
  }

  /// Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
    debugPrint('👋 Unsubscribed from real-time updates');
  }
}
