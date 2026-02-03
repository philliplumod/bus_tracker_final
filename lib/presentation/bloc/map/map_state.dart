import 'package:equatable/equatable.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/user_location.dart';
import '../../../core/services/directions_service.dart';

abstract class MapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final UserLocation userLocation;
  final List<Bus> buses;
  final RouteData? routeData;
  final bool isLoadingRoute;

  MapLoaded({
    required this.userLocation,
    this.buses = const [],
    this.routeData,
    this.isLoadingRoute = false,
  });

  MapLoaded copyWith({
    UserLocation? userLocation,
    List<Bus>? buses,
    RouteData? routeData,
    bool? isLoadingRoute,
    bool clearRoute = false,
  }) {
    return MapLoaded(
      userLocation: userLocation ?? this.userLocation,
      buses: buses ?? this.buses,
      routeData: clearRoute ? null : (routeData ?? this.routeData),
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
    );
  }

  @override
  List<Object?> get props => [userLocation, buses, routeData, isLoadingRoute];
}

class MapError extends MapState {
  final String message;

  MapError(this.message);

  @override
  List<Object?> get props => [message];
}
