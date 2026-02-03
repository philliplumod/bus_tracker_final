import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/user_location.dart';
import '../../../domain/usecases/get_nearby_buses.dart';
import '../../../domain/usecases/get_user_location.dart';
import '../../../domain/repositories/bus_repository.dart';
import 'trip_solution_event.dart';
import 'trip_solution_state.dart';

class TripSolutionBloc
    extends HydratedBloc<TripSolutionEvent, TripSolutionState> {
  final GetUserLocation getUserLocation;
  final GetNearbyBuses getNearbyBuses;
  final BusRepository busRepository;
  StreamSubscription? _busStreamSubscription;

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
    required this.busRepository,
  }) : super(TripSolutionInitial()) {
    on<LoadTripSolutionData>(_onLoadTripSolutionData);
    on<SearchTripSolution>(_onSearchTripSolution);
    on<SearchTripByCoordinates>(_onSearchTripByCoordinates);
    on<ClearTripSolution>(_onClearTripSolution);
    on<UpdateBusesFromStream>(_onUpdateBusesFromStream);
  }

  @override
  Future<void> close() {
    _busStreamSubscription?.cancel();
    return super.close();
  }

  @override
  TripSolutionState? fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String?;
      switch (type) {
        case 'loaded':
          final userLocationJson =
              json['userLocation'] as Map<String, dynamic>?;
          final allBusesJson = json['allBuses'] as List?;
          final matchingBusesJson = json['matchingBuses'] as List?;

          if (userLocationJson != null &&
              allBusesJson != null &&
              matchingBusesJson != null) {
            final destCoords =
                json['destinationCoordinates'] as Map<String, dynamic>?;
            return TripSolutionLoaded(
              userLocation: UserLocation.fromJson(userLocationJson),
              allBuses:
                  allBusesJson
                      .map((e) => Bus.fromJson(e as Map<String, dynamic>))
                      .toList(),
              matchingBuses:
                  matchingBusesJson
                      .map((e) => Bus.fromJson(e as Map<String, dynamic>))
                      .toList(),
              searchQuery: json['searchQuery'] as String? ?? '',
              destinationCoordinates:
                  destCoords != null
                      ? LatLng(
                        (destCoords['latitude'] as num).toDouble(),
                        (destCoords['longitude'] as num).toDouble(),
                      )
                      : null,
              hasSearched: json['hasSearched'] as bool? ?? false,
            );
          }
          return null;
        case 'loading':
          return TripSolutionLoading();
        case 'error':
          return TripSolutionError(
            json['message'] as String? ?? 'Unknown error',
          );
        case 'initial':
        default:
          return TripSolutionInitial();
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(TripSolutionState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }

  Map<String, LatLng> get knownLocations => _knownLocations;

  Future<void> _onLoadTripSolutionData(
    LoadTripSolutionData event,
    Emitter<TripSolutionState> emit,
  ) async {
    emit(TripSolutionLoading());

    final locationResult = await getUserLocation();

    await locationResult.fold(
      (failure) async {
        emit(TripSolutionError(failure.toString()));
      },
      (userLocation) async {
        // Cancel previous subscription if exists
        await _busStreamSubscription?.cancel();

        // Start listening to real-time bus updates
        _busStreamSubscription = busRepository.watchBusUpdates().listen((
          result,
        ) {
          result.fold(
            (failure) {
              if (!isClosed) {
                add(
                  UpdateBusesFromStream(
                    [],
                    isError: true,
                    errorMessage: failure.toString(),
                  ),
                );
              }
            },
            (buses) {
              if (!isClosed) {
                add(UpdateBusesFromStream(buses));
              }
            },
          );
        });

        // Emit initial state with user location
        emit(
          TripSolutionLoaded(
            userLocation: userLocation,
            allBuses: [],
            matchingBuses: [],
            searchQuery: '',
            hasSearched: false,
          ),
        );
      },
    );
  }

  void _onUpdateBusesFromStream(
    UpdateBusesFromStream event,
    Emitter<TripSolutionState> emit,
  ) {
    if (event.isError) {
      emit(TripSolutionError(event.errorMessage ?? 'Unknown error'));
      return;
    }

    if (state is TripSolutionLoaded) {
      final currentState = state as TripSolutionLoaded;
      final updatedBuses = event.buses;

      debugPrint('📡 Received bus updates: ${updatedBuses.length} buses');
      if (updatedBuses.isNotEmpty) {
        debugPrint('   Sample buses:');
        for (
          var i = 0;
          i < (updatedBuses.length > 3 ? 3 : updatedBuses.length);
          i++
        ) {
          final bus = updatedBuses[i];
          debugPrint(
            '   - Bus ${bus.busNumber ?? bus.id}: (${bus.latitude}, ${bus.longitude}) at ${bus.speed}km/h',
          );
        }
      }

      // Reapply current search filter if there is one
      List<Bus> matchingBuses = [];
      if (currentState.hasSearched &&
          currentState.searchQuery.isNotEmpty &&
          currentState.destinationCoordinates != null) {
        final destCoords = currentState.destinationCoordinates!;

        // Find buses near user or destination
        matchingBuses =
            updatedBuses.where((bus) {
              if (bus.latitude == null ||
                  bus.longitude == null ||
                  bus.speed == null) {
                return false;
              }

              final distanceFromUser = DistanceCalculator.calculate(
                currentState.userLocation.latitude,
                currentState.userLocation.longitude,
                bus.latitude!,
                bus.longitude!,
              );

              final distanceFromDestination = DistanceCalculator.calculate(
                destCoords.latitude,
                destCoords.longitude,
                bus.latitude!,
                bus.longitude!,
              );

              // Bus should be within 5km of user OR within 5km of destination
              return distanceFromUser <= 5.0 || distanceFromDestination <= 5.0;
            }).toList();

        // Sort by distance from user
        matchingBuses.sort((a, b) {
          final distA = DistanceCalculator.calculate(
            currentState.userLocation.latitude,
            currentState.userLocation.longitude,
            a.latitude!,
            a.longitude!,
          );
          final distB = DistanceCalculator.calculate(
            currentState.userLocation.latitude,
            currentState.userLocation.longitude,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        });
      }

      emit(
        currentState.copyWith(
          allBuses: updatedBuses,
          matchingBuses: matchingBuses,
        ),
      );
    }
  }

  Future<void> _onSearchTripSolution(
    SearchTripSolution event,
    Emitter<TripSolutionState> emit,
  ) async {
    if (state is TripSolutionLoaded) {
      final currentState = state as TripSolutionLoaded;
      final destination = event.destination.trim();

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

      try {
        // First try known locations for fast lookup
        LatLng? destCoords = _knownLocations[destination.toLowerCase()];

        if (destCoords == null) {
          // Try partial match in known locations
          for (var entry in _knownLocations.entries) {
            if (entry.key.contains(destination.toLowerCase()) ||
                destination.toLowerCase().contains(entry.key)) {
              destCoords = entry.value;
              break;
            }
          }
        }

        // If not found in known locations, use geocoding
        if (destCoords == null) {
          debugPrint('🗺️ Geocoding location: $destination');

          // Try geocoding with "Cebu" context for better results
          final searchQuery =
              destination.contains('Cebu')
                  ? destination
                  : '$destination, Cebu City, Philippines';

          final locations = await locationFromAddress(searchQuery);

          if (locations.isNotEmpty) {
            destCoords = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
            debugPrint(
              '✅ Location found: ${destCoords.latitude}, ${destCoords.longitude}',
            );
          } else {
            debugPrint('❌ Location not found via geocoding');
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
        }

        // Find buses that can take you from your location to destination
        debugPrint('🔍 Searching for buses...');
        debugPrint('   Total buses available: ${currentState.allBuses.length}');
        debugPrint(
          '   User location: ${currentState.userLocation.latitude}, ${currentState.userLocation.longitude}',
        );
        debugPrint(
          '   Destination: ${destCoords.latitude}, ${destCoords.longitude}',
        );

        final matchingBuses =
            currentState.allBuses.where((bus) {
              if (bus.latitude == null ||
                  bus.longitude == null ||
                  bus.speed == null) {
                return false;
              }
              final distanceFromUser = DistanceCalculator.calculate(
                currentState.userLocation.latitude,
                currentState.userLocation.longitude,
                bus.latitude!,
                bus.longitude!,
              );

              final distanceFromDestination = DistanceCalculator.calculate(
                destCoords!.latitude,
                destCoords.longitude,
                bus.latitude!,
                bus.longitude!,
              );

              // Bus should be within 5km of user OR within 5km of destination
              // This allows finding buses that are on route between you and your destination
              final isRelevant =
                  distanceFromUser <= 5.0 || distanceFromDestination <= 5.0;

              if (isRelevant) {
                debugPrint(
                  '   ✓ Bus ${bus.busNumber ?? bus.id}: ${distanceFromUser.toStringAsFixed(2)}km from user, ${distanceFromDestination.toStringAsFixed(2)}km from destination',
                );
              }

              return isRelevant;
            }).toList();

        debugPrint('✅ Found ${matchingBuses.length} matching buses');

        // Sort by distance from user
        matchingBuses.sort((a, b) {
          final distA = DistanceCalculator.calculate(
            currentState.userLocation.latitude,
            currentState.userLocation.longitude,
            a.latitude!,
            a.longitude!,
          );
          final distB = DistanceCalculator.calculate(
            currentState.userLocation.latitude,
            currentState.userLocation.longitude,
            b.latitude!,
            b.longitude!,
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
      } catch (e) {
        debugPrint('❌ Geocoding error: $e');
        emit(
          currentState.copyWith(
            matchingBuses: [],
            searchQuery: destination,
            hasSearched: true,
            clearDestination: true,
          ),
        );
      }
    }
  }

  void _onSearchTripByCoordinates(
    SearchTripByCoordinates event,
    Emitter<TripSolutionState> emit,
  ) {
    if (state is TripSolutionLoaded) {
      final currentState = state as TripSolutionLoaded;
      final destCoords = event.coordinates;
      final locationName = event.locationName ?? 'Selected Location';

      debugPrint('🗺️ Map-based search initiated');
      debugPrint('   Total buses available: ${currentState.allBuses.length}');
      debugPrint(
        '   User location: ${currentState.userLocation.latitude}, ${currentState.userLocation.longitude}',
      );
      debugPrint(
        '   Destination: ${destCoords.latitude}, ${destCoords.longitude}',
      );
      debugPrint('   Location name: $locationName');

      // Find buses that can take you from your location to destination
      final matchingBuses =
          currentState.allBuses.where((bus) {
            if (bus.latitude == null ||
                bus.longitude == null ||
                bus.speed == null) {
              return false;
            }
            final distanceFromUser = DistanceCalculator.calculate(
              currentState.userLocation.latitude,
              currentState.userLocation.longitude,
              bus.latitude!,
              bus.longitude!,
            );

            final distanceFromDestination = DistanceCalculator.calculate(
              destCoords.latitude,
              destCoords.longitude,
              bus.latitude!,
              bus.longitude!,
            );

            // Bus should be within 5km of user OR within 5km of destination
            final isRelevant =
                distanceFromUser <= 5.0 || distanceFromDestination <= 5.0;

            if (isRelevant) {
              debugPrint(
                '   ✓ Bus ${bus.busNumber ?? bus.id}: ${distanceFromUser.toStringAsFixed(2)}km from user, ${distanceFromDestination.toStringAsFixed(2)}km from destination',
              );
            }

            return isRelevant;
          }).toList();

      debugPrint('✅ Found ${matchingBuses.length} matching buses');

      // Sort by distance from user
      matchingBuses.sort((a, b) {
        final distA = DistanceCalculator.calculate(
          currentState.userLocation.latitude,
          currentState.userLocation.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distB = DistanceCalculator.calculate(
          currentState.userLocation.latitude,
          currentState.userLocation.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distA.compareTo(distB);
      });

      emit(
        currentState.copyWith(
          matchingBuses: matchingBuses,
          searchQuery: locationName,
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
