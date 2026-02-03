import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/entities/bus.dart';

abstract class TripSolutionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTripSolutionData extends TripSolutionEvent {}

class SearchTripSolution extends TripSolutionEvent {
  final String destination;

  SearchTripSolution(this.destination);

  @override
  List<Object?> get props => [destination];
}

class SearchTripByCoordinates extends TripSolutionEvent {
  final LatLng coordinates;
  final String? locationName;

  SearchTripByCoordinates(this.coordinates, {this.locationName});

  @override
  List<Object?> get props => [coordinates, locationName];
}

class ClearTripSolution extends TripSolutionEvent {}

class UpdateBusesFromStream extends TripSolutionEvent {
  final List<Bus> buses;
  final bool isError;
  final String? errorMessage;

  UpdateBusesFromStream(this.buses, {this.isError = false, this.errorMessage});

  @override
  List<Object?> get props => [buses, isError, errorMessage];
}
