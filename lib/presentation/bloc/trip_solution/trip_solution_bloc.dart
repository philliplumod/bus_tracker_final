import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../domain/usecases/get_nearby_buses.dart';
import '../../../domain/usecases/get_user_location.dart';
import 'trip_solution_event.dart';
import 'trip_solution_state.dart';

class TripSolutionBloc extends Bloc<TripSolutionEvent, TripSolutionState> {
  final GetUserLocation getUserLocation;
  final GetNearbyBuses getNearbyBuses;

  // Predefined locations in Cebu
  final Map<String, LatLng> _knownLocations = {
    'sm cebu': const LatLng(10.3113, 123.9183),
    'ayala center': const LatLng(10.3181, 123.9058),
    'it park': const LatLng(10.3204, 123.8939),
    'capitol': const LatLng(10.3106, 123.8939),
    'colon': const LatLng(10.2952, 123.9016),
    'carbon market': const LatLng(10.2935, 123.9021),
    'pier 1': const LatLng(10.2893, 123.9032),
    'mandaue': const LatLng(10.3237, 123.9227),
    'talamban': const LatLng(10.3446, 123.9113),
    'banilad': const LatLng(10.3364, 123.9112),
  };

  TripSolutionBloc({
    required this.getUserLocation,
    required this.getNearbyBuses,
  }) : super(TripSolutionInitial()) {
    on<LoadTripSolutionData>(_onLoadTripSolutionData);
    on<SearchTripSolution>(_onSearchTripSolution);
    on<ClearTripSolution>(_onClearTripSolution);
  }

  Map<String, LatLng> get knownLocations => _knownLocations;

  Future<void> _onLoadTripSolutionData(
    LoadTripSolutionData event,
    Emitter<TripSolutionState> emit,
  ) async {
    emit(TripSolutionLoading());

    final locationResult = await getUserLocation();
    final busesResult = await getNearbyBuses();

    await locationResult.fold(
      (failure) async {
        emit(TripSolutionError(failure.toString()));
      },
      (userLocation) async {
        await busesResult.fold(
          (failure) async {
            emit(TripSolutionError(failure.toString()));
          },
          (buses) async {
            emit(
              TripSolutionLoaded(
                userLocation: userLocation,
                allBuses: buses,
                matchingBuses: [],
                searchQuery: '',
                hasSearched: false,
              ),
            );
          },
        );
      },
    );
  }

  void _onSearchTripSolution(
    SearchTripSolution event,
    Emitter<TripSolutionState> emit,
  ) {
    if (state is TripSolutionLoaded) {
      final currentState = state as TripSolutionLoaded;
      final destination = event.destination.trim().toLowerCase();

      if (destination.isEmpty) {
        emit(
          currentState.copyWith(
            matchingBuses: [],
            searchQuery: '',
            hasSearched: true,
            clearDestination: true,
          ),
        );
        return;
      }

      // Try to find destination in known locations
      LatLng? destCoords = _knownLocations[destination];

      if (destCoords == null) {
        // Try partial match
        for (var entry in _knownLocations.entries) {
          if (entry.key.contains(destination) ||
              destination.contains(entry.key)) {
            destCoords = entry.value;
            break;
          }
        }
      }

      if (destCoords == null) {
        emit(
          currentState.copyWith(
            matchingBuses: [],
            searchQuery: destination,
            hasSearched: true,
            clearDestination: true,
          ),
        );
        return;
      }

      // Find buses that are near both user location and destination
      final matchingBuses =
          currentState.allBuses.where((bus) {
            final distanceFromUser = DistanceCalculator.calculate(
              currentState.userLocation.latitude,
              currentState.userLocation.longitude,
              bus.latitude,
              bus.longitude,
            );

            final distanceFromDestination = DistanceCalculator.calculate(
              destCoords!.latitude,
              destCoords.longitude,
              bus.latitude,
              bus.longitude,
            );

            // Bus should be within 3km of user location and 3km of destination
            return distanceFromUser <= 3.0 && distanceFromDestination <= 3.0;
          }).toList();

      // Sort by distance from user
      matchingBuses.sort((a, b) {
        final distA = DistanceCalculator.calculate(
          currentState.userLocation.latitude,
          currentState.userLocation.longitude,
          a.latitude,
          a.longitude,
        );
        final distB = DistanceCalculator.calculate(
          currentState.userLocation.latitude,
          currentState.userLocation.longitude,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });

      emit(
        currentState.copyWith(
          matchingBuses: matchingBuses,
          searchQuery: destination,
          destinationCoordinates: destCoords,
          hasSearched: true,
        ),
      );
    }
  }

  void _onClearTripSolution(
    ClearTripSolution event,
    Emitter<TripSolutionState> emit,
  ) {
    if (state is TripSolutionLoaded) {
      final currentState = state as TripSolutionLoaded;
      emit(
        currentState.copyWith(
          matchingBuses: [],
          searchQuery: '',
          hasSearched: false,
          clearDestination: true,
        ),
      );
    }
  }
}
