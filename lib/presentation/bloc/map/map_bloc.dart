import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/utils/directions_service.dart';
import '../../../core/services/directions_service.dart' as route_service;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/usecases/get_user_location.dart';
import '../../../domain/usecases/get_nearby_buses.dart';
import '../../../domain/usecases/watch_bus_updates.dart';
import '../../../service/notification_service.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetUserLocation getUserLocation;
  final GetNearbyBuses getNearbyBuses;
  final WatchBusUpdates watchBusUpdates;
  final route_service.DirectionsService directionsService;

  StreamSubscription? _busUpdateSubscription;
  final Set<String> _notifiedBuses = {};

  MapBloc({
    required this.getUserLocation,
    required this.getNearbyBuses,
    required this.watchBusUpdates,
    route_service.DirectionsService? directionsService,
  }) : directionsService =
           directionsService ?? route_service.DirectionsService(),
       super(MapInitial()) {
    on<LoadUserLocation>(_onLoadUserLocation);
    on<LoadNearbyBuses>(_onLoadNearbyBuses);
    on<SubscribeToBusUpdates>(_onSubscribeToBusUpdates);
    on<BusesUpdated>(_onBusesUpdated);
    on<LoadRoute>(_onLoadRoute);
    on<ClearRoute>(_onClearRoute);
  }

  Future<void> _onLoadUserLocation(
    LoadUserLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());

    final result = await getUserLocation();

    result.fold(
      (failure) => emit(MapError(failure.message)),
      (location) => emit(MapLoaded(userLocation: location, buses: const [])),
    );
  }

  Future<void> _onLoadNearbyBuses(
    LoadNearbyBuses event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapLoaded) return;

    emit(MapLoading());

    final result = await getNearbyBuses();

    result.fold((failure) => emit(MapError(failure.message)), (buses) {
      final busesWithDistance = _calculateDistancesAndETA(
        buses,
        currentState.userLocation,
      );
      emit(currentState.copyWith(buses: busesWithDistance));
    });
  }

  void _onSubscribeToBusUpdates(
    SubscribeToBusUpdates event,
    Emitter<MapState> emit,
  ) {
    _busUpdateSubscription?.cancel();

    _busUpdateSubscription = watchBusUpdates().listen((result) {
      result.fold(
        (failure) => add(BusesUpdated([])),
        (buses) => add(BusesUpdated(buses)),
      );
    });
  }

  void _onBusesUpdated(BusesUpdated event, Emitter<MapState> emit) {
    final currentState = state;
    if (currentState is! MapLoaded) return;

    final busesWithDistance = _calculateDistancesAndETA(
      event.buses.cast<Bus>(),
      currentState.userLocation,
    );

    // Check for nearby buses and send notifications
    for (final bus in busesWithDistance) {
      if (bus.distanceFromUser != null &&
          bus.distanceFromUser! < AppConstants.nearbyBusThreshold &&
          !_notifiedBuses.contains(bus.id)) {
        NotificationService.showNotification(
          AppConstants.nearbyBusTitle,
          AppConstants.nearbyBusMessage(bus.id),
        );
        _notifiedBuses.add(bus.id);
      }
    }

    emit(
      MapLoaded(
        userLocation: currentState.userLocation,
        buses: busesWithDistance,
        routeData: currentState.routeData,
      ),
    );
  }

  Future<void> _onLoadRoute(LoadRoute event, Emitter<MapState> emit) async {
    final currentState = state;
    if (currentState is! MapLoaded) return;

    // Mark as loading route
    emit(currentState.copyWith(isLoadingRoute: true));

    try {
      final routeData = await directionsService.getRoute(
        origin: event.origin,
        destination: event.destination,
      );

      if (routeData != null) {
        emit(
          currentState.copyWith(routeData: routeData, isLoadingRoute: false),
        );
      } else {
        emit(currentState.copyWith(isLoadingRoute: false));
      }
    } catch (e) {
      emit(currentState.copyWith(isLoadingRoute: false));
    }
  }

  void _onClearRoute(ClearRoute event, Emitter<MapState> emit) {
    final currentState = state;
    if (currentState is! MapLoaded) return;

    emit(currentState.copyWith(clearRoute: true));
  }

  List<Bus> _calculateDistancesAndETA(List<Bus> buses, dynamic userLocation) {
    return buses
        .where(
          (bus) =>
              bus.latitude != null &&
              bus.longitude != null &&
              bus.speed != null,
        )
        .map((bus) {
          final distance = DistanceCalculator.calculate(
            userLocation.latitude,
            userLocation.longitude,
            bus.latitude!,
            bus.longitude!,
          );

          final eta = DistanceCalculator.calculateETA(distance, bus.speed!);

          // Calculate direction from user to bus
          final bearing = DirectionsService.calculateBearing(
            LatLng(userLocation.latitude, userLocation.longitude),
            LatLng(bus.latitude!, bus.longitude!),
          );
          final direction = DirectionsService.getDirectionName(bearing);

          return bus.copyWith(
            distanceFromUser: distance,
            eta: eta,
            direction: direction,
          );
        })
        .toList();
  }

  @override
  Future<void> close() {
    _busUpdateSubscription?.cancel();
    return super.close();
  }
}
