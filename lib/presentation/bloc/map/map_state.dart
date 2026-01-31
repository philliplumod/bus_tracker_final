import 'package:equatable/equatable.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/user_location.dart';

abstract class MapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final UserLocation userLocation;
  final List<Bus> buses;

  MapLoaded({required this.userLocation, this.buses = const []});

  @override
  List<Object?> get props => [userLocation, buses];
}

class MapError extends MapState {
  final String message;

  MapError(this.message);

  @override
  List<Object?> get props => [message];
}
