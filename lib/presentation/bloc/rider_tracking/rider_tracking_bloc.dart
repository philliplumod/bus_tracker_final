import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/rider_location_update.dart';
import '../../../domain/usecases/store_rider_location.dart';
import '../../../service/location_tracking_service.dart';
import 'rider_tracking_event.dart';
import 'rider_tracking_state.dart';

class RiderTrackingBloc extends Bloc<RiderTrackingEvent, RiderTrackingState> {
  final LocationTrackingService locationService;
  final StoreRiderLocation storeRiderLocation;
  StreamSubscription<RiderLocationUpdate>? _locationSubscription;

  RiderTrackingBloc({
    required this.locationService,
    required this.storeRiderLocation,
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

      // Start the location tracking service
      await locationService.startTracking(event.rider);

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
