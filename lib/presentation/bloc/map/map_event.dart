import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class MapEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserLocation extends MapEvent {}

class LoadNearbyBuses extends MapEvent {}

class SubscribeToBusUpdates extends MapEvent {}

class BusesUpdated extends MapEvent {
  final List<dynamic> buses;

  BusesUpdated(this.buses);

  @override
  List<Object?> get props => [buses];
}

class LoadRoute extends MapEvent {
  final LatLng origin;
  final LatLng destination;

  LoadRoute({required this.origin, required this.destination});

  @override
  List<Object?> get props => [origin, destination];
}

class ClearRoute extends MapEvent {}
