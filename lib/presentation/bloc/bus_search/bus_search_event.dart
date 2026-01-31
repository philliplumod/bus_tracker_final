import 'package:equatable/equatable.dart';

abstract class BusSearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAllBuses extends BusSearchEvent {}

class SearchBusByNumber extends BusSearchEvent {
  final String busNumber;

  SearchBusByNumber(this.busNumber);

  @override
  List<Object?> get props => [busNumber];
}

class ClearBusSearch extends BusSearchEvent {}
