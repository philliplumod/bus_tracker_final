abstract class MapEvent {}

class LoadUserLocation extends MapEvent {}

class LoadNearbyBuses extends MapEvent {}

class UpdateBusLocations extends MapEvent {
  final List<Map<String, dynamic>> buses;
  UpdateBusLocations(this.buses);
}

class SubscribeToBusUpdates extends MapEvent {}
