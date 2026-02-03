import 'package:equatable/equatable.dart';
import '../../../domain/entities/bus.dart';

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

class UpdateBusesFromStream extends BusSearchEvent {
  final List<Bus> buses;
  final bool isError;
  final String? errorMessage;

  UpdateBusesFromStream(this.buses, {this.isError = false, this.errorMessage});

  @override
  List<Object?> get props => [buses, isError, errorMessage];
}
