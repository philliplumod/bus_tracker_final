import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/user_location.dart';

abstract class TripSolutionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TripSolutionInitial extends TripSolutionState {}

class TripSolutionLoading extends TripSolutionState {}

class TripSolutionLoaded extends TripSolutionState {
  final UserLocation userLocation;
  final List<Bus> allBuses;
  final List<Bus> matchingBuses;
  final String searchQuery;
  final LatLng? destinationCoordinates;
  final bool hasSearched;

  TripSolutionLoaded({
    required this.userLocation,
    required this.allBuses,
    required this.matchingBuses,
    required this.searchQuery,
    this.destinationCoordinates,
    this.hasSearched = false,
  });

  @override
  List<Object?> get props => [
    userLocation,
    allBuses,
    matchingBuses,
    searchQuery,
    destinationCoordinates,
    hasSearched,
  ];

  TripSolutionLoaded copyWith({
    UserLocation? userLocation,
    List<Bus>? allBuses,
    List<Bus>? matchingBuses,
    String? searchQuery,
    LatLng? destinationCoordinates,
    bool? hasSearched,
    bool clearDestination = false,
  }) {
    return TripSolutionLoaded(
      userLocation: userLocation ?? this.userLocation,
      allBuses: allBuses ?? this.allBuses,
      matchingBuses: matchingBuses ?? this.matchingBuses,
      searchQuery: searchQuery ?? this.searchQuery,
      destinationCoordinates:
          clearDestination
              ? null
              : (destinationCoordinates ?? this.destinationCoordinates),
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class TripSolutionError extends TripSolutionState {
  final String message;

  TripSolutionError(this.message);

  @override
  List<Object?> get props => [message];
}
