import 'package:equatable/equatable.dart';

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

class ClearTripSolution extends TripSolutionEvent {}
