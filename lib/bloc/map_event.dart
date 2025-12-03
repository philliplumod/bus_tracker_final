import 'package:equatable/equatable.dart';

abstract class MapEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserLocation extends MapEvent {}

class LoadNearbyBuses extends MapEvent {}

class UpdateBusLocations extends MapEvent {
  final List<Map<String, dynamic>> buses;
  UpdateBusLocations(this.buses);

  @override
  List<Object?> get props => [buses];
}

class SubscribeToBusUpdates extends MapEvent {}
