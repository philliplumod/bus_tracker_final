import 'package:bus_tracker/widgets/location_error.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:equatable/equatable.dart';

abstract class MapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final LatLng position;
  final List<Map<String, dynamic>> nearbyBuses;

  MapLoaded({required this.position, this.nearbyBuses = const []});

  @override
  List<Object?> get props => [position, nearbyBuses];
}

class MapLocationError extends MapState {
  final LocationError error;

  MapLocationError(this.error);

  @override
  List<Object?> get props => [error];
}

class MapError extends MapState {
  final String error;

  MapError(this.error);

  @override
  List<Object?> get props => [error];
}
