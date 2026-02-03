import 'dart:async';
import 'package:bus_tracker/domain/entities/user_assignment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/rider_location_update.dart';
import '../../../domain/usecases/store_rider_location.dart';
import '../../../domain/repositories/user_assignment_repository.dart';
import '../../../service/location_tracking_service.dart';
import '../../../data/datasources/api_client.dart';
import 'rider_tracking_event.dart';
import 'rider_tracking_state.dart';

class RiderTrackingBloc extends Bloc<RiderTrackingEvent, RiderTrackingState> {
  final LocationTrackingService locationService;
  final StoreRiderLocation storeRiderLocation;
  final UserAssignmentRepository userAssignmentRepository;
  final ApiClient apiClient;
  StreamSubscription<RiderLocationUpdate>? _locationSubscription;

  RiderTrackingBloc({
    required this.locationService,
    required this.storeRiderLocation,
    required this.userAssignmentRepository,
    required this.apiClient,
  }) : super(RiderTrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<LocationUpdateReceived>(_onLocationUpdateReceived);
  }

  Future<void> _onStartTracking(
    StartTracking event,
    Emitter<RiderTrackingState> emit,
  ) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 Starting rider tracking for: ${event.rider.name}');
      debugPrint('   User ID: "${event.rider.id}"');
      debugPrint('   User ID type: ${event.rider.id.runtimeType}');
      debugPrint('   User ID length: ${event.rider.id.length}');
      debugPrint('   User email: ${event.rider.email}');
      debugPrint('   User role: ${event.rider.role}');

      // CRITICAL: Ensure auth token is set before making API calls
      debugPrint('🔐 Checking auth token...');
      if (!apiClient.hasAuthToken()) {
        debugPrint('⚠️ No auth token found in API client!');
        debugPrint('   Attempting to reload token from storage...');

        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          if (token != null && token.isNotEmpty) {
            apiClient.setAuthToken(token);
            debugPrint('✅ Token reloaded from storage');
          } else {
            debugPrint('❌ No token found in storage either!');
            emit(
              RiderTrackingError(
                'Authentication token missing.\n\n'
                'Please logout and login again to refresh your session.',
              ),
            );
            return;
          }
        } catch (e) {
          debugPrint('❌ Failed to reload token: $e');
          emit(
            RiderTrackingError(
              'Failed to reload authentication.\n\n'
              'Please logout and login again.',
            ),
          );
          return;
        }
      } else {
        debugPrint('✅ Auth token is present in API client');
      }

      debugPrint('═══════════════════════════════════════');

      // Fetch actual UserAssignment from repository
      final assignmentResult = await userAssignmentRepository.getUserAssignment(
        event.rider.id,
      );

      // Handle the Either result
      String? errorMessage;
      final UserAssignment? assignment = assignmentResult.fold((failure) {
        debugPrint('⚠️ Failed to fetch user assignment: ${failure.message}');
        errorMessage = failure.message;
        return null;
      }, (assignment) => assignment);

      if (assignment == null) {
        debugPrint('❌ No assignment found for user ${event.rider.id}');

        // Determine if it's a network error or missing assignment
        String message;
        if (errorMessage != null &&
            (errorMessage!.contains('401') ||
                errorMessage!.contains('Unauthorized') ||
                errorMessage!.contains('expired token'))) {
          message =
              'Authentication error. Please check your network connection and try logging in again.';
        } else if (errorMessage != null &&
            (errorMessage!.contains('Failed to host lookup') ||
                errorMessage!.contains('SocketException') ||
                errorMessage!.contains('Connection refused'))) {
          message =
              'Cannot connect to server. Please check:\n'
              '1. Your internet connection\n'
              '2. Backend server is running\n'
              '3. Run: adb reverse tcp:3000 tcp:3000';
        } else {
          message =
              'No bus route assignment found.\n\n'
              'Please contact your administrator to:\n'
              '• Assign you to a bus\n'
              '• Assign you to a route\n\n'
              'Pull down to refresh once assigned.';
        }

        emit(RiderTrackingError(message));
        return;
      }

      debugPrint('📋 Assignment fetched from API:');
      debugPrint('   Bus Name: ${assignment.busName}');
      debugPrint('   Route Name: ${assignment.routeName}');
      debugPrint('   Bus ID: ${assignment.busId}');
      debugPrint('   Route ID: ${assignment.routeId}');
      debugPrint('   Assignment ID: ${assignment.id}');
      debugPrint('   Starting Terminal: ${assignment.startingTerminalName}');
      debugPrint(
        '   Destination Terminal: ${assignment.destinationTerminalName}',
      );

      // Start the location tracking service with actual assignment
      await locationService.startTracking(event.rider, assignment);

      // Subscribe to location updates
      _locationSubscription = locationService.locationStream?.listen(
        (update) async {
          // Store location in Firebase
          final result = await storeRiderLocation(update);

          result.fold(
            (failure) =>
                debugPrint('❌ Failed to store location: ${failure.message}'),
            (_) => debugPrint('✅ Location stored successfully'),
          );

          // Update UI state
          add(
            LocationUpdateReceived(
              latitude: update.latitude,
              longitude: update.longitude,
              speed: update.speed,
              heading: update.heading,
              estimatedDuration: update.estimatedDurationMinutes,
            ),
          );
        },
        onError: (error) {
          debugPrint('❌ Location stream error: $error');
          add(const StopTracking());
        },
      );
    } catch (e) {
      debugPrint('❌ Error starting tracking: $e');
      emit(RiderTrackingError('Failed to start tracking: $e'));
    }
  }

  Future<void> _onStopTracking(
    StopTracking event,
    Emitter<RiderTrackingState> emit,
  ) async {
    debugPrint('🛑 Stopping rider tracking');

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    locationService.stopTracking();

    emit(RiderTrackingStopped());
  }

  Future<void> _onLocationUpdateReceived(
    LocationUpdateReceived event,
    Emitter<RiderTrackingState> emit,
  ) async {
    emit(
      RiderTrackingActive(
        latitude: event.latitude,
        longitude: event.longitude,
        speed: event.speed,
        heading: event.heading,
        estimatedDurationMinutes: event.estimatedDuration,
        lastUpdate: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    locationService.stopTracking();
    return super.close();
  }
}
