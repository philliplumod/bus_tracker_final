import 'package:equatable/equatable.dart';

abstract class RiderTrackingState extends Equatable {
  const RiderTrackingState();

  @override
  List<Object?> get props => [];
}

class RiderTrackingInitial extends RiderTrackingState {}

class RiderTrackingLoading extends RiderTrackingState {}

class RiderTrackingActive extends RiderTrackingState {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double? estimatedDurationMinutes;
  final DateTime lastUpdate;

  const RiderTrackingActive({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    this.estimatedDurationMinutes,
    required this.lastUpdate,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    speed,
    heading,
    estimatedDurationMinutes,
    lastUpdate,
  ];
}

class RiderTrackingError extends RiderTrackingState {
  final String message;

  const RiderTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

class RiderTrackingStopped extends RiderTrackingState {}
