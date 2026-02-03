import 'dart:async';
import 'package:bus_tracker/domain/entities/user_assignment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/rider_location_update.dart';
import '../../../domain/usecases/store_rider_location.dart';
import '../../../domain/repositories/user_assignment_repository.dart';
import '../../../service/location_tracking_service.dart';
import 'rider_tracking_event.dart';
import 'rider_tracking_state.dart';

class RiderTrackingBloc extends Bloc<RiderTrackingEvent, RiderTrackingState> {
  final LocationTrackingService locationService;
  final StoreRiderLocation storeRiderLocation;
  final UserAssignmentRepository userAssignmentRepository;
  StreamSubscription<RiderLocationUpdate>? _locationSubscription;

  RiderTrackingBloc({
    required this.locationService,
    required this.storeRiderLocation,
    required this.userAssignmentRepository,
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
      debugPrint('🚀 Starting rider tracking for: ${event.rider.name}');
      debugPrint('   User ID: ${event.rider.id}');

      // Fetch actual UserAssignment from repository
      final assignmentResult = await userAssignmentRepository.getUserAssignment(
        event.rider.id,
      );

      // Handle the Either result
      final UserAssignment? assignment = assignmentResult.fold((failure) {
        debugPrint('⚠️ Failed to fetch user assignment: ${failure.message}');
        return null;
      }, (assignment) => assignment);

      if (assignment == null) {
        debugPrint('❌ No assignment found for user ${event.rider.id}');
        emit(
          RiderTrackingError(
            'No bus route assignment found. Please contact admin.',
          ),
        );
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
