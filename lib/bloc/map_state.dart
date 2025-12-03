import 'package:bus_tracker/widgets/location_error.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final LatLng position;
  final List<Map<String, dynamic>> nearbyBuses;

  MapLoaded({required this.position, this.nearbyBuses = const []});
}

class MapLocationError extends MapState {
  final LocationError error;

  MapLocationError(this.error);
}

class MapError extends MapState {
  final String error;

  MapError(this.error);
}
