import 'package:equatable/equatable.dart';

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
