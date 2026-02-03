import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class RiderTrackingEvent extends Equatable {
  const RiderTrackingEvent();

  @override
  List<Object?> get props => [];
}

class StartTracking extends RiderTrackingEvent {
  final User rider;

  const StartTracking(this.rider);

  @override
  List<Object?> get props => [rider];
}

class StopTracking extends RiderTrackingEvent {
  const StopTracking();
}

class LocationUpdateReceived extends RiderTrackingEvent {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double? estimatedDuration;

  const LocationUpdateReceived({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    this.estimatedDuration,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    speed,
    heading,
    estimatedDuration,
  ];
}
