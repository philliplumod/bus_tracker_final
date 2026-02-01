import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/user_location.dart';

abstract class TripSolutionState extends Equatable {
  @override
  List<Object?> get props => [];

  Map<String, dynamic> toJson();
}

class TripSolutionInitial extends TripSolutionState {
  @override
  Map<String, dynamic> toJson() => {'type': 'initial'};
}

class TripSolutionLoading extends TripSolutionState {
  @override
  Map<String, dynamic> toJson() => {'type': 'loading'};
}

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

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'loaded',
      'userLocation': userLocation.toJson(),
      'allBuses': allBuses.map((bus) => bus.toJson()).toList(),
      'matchingBuses': matchingBuses.map((bus) => bus.toJson()).toList(),
      'searchQuery': searchQuery,
      'destinationCoordinates':
          destinationCoordinates != null
              ? {
                'latitude': destinationCoordinates!.latitude,
                'longitude': destinationCoordinates!.longitude,
              }
              : null,
      'hasSearched': hasSearched,
    };
  }

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

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'error', 'message': message};
  }
}
