import 'package:equatable/equatable.dart';
import '../../../domain/entities/bus.dart';

abstract class BusSearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BusSearchInitial extends BusSearchState {}

class BusSearchLoading extends BusSearchState {}

class BusSearchLoaded extends BusSearchState {
  final List<Bus> allBuses;
  final List<Bus> filteredBuses;
  final String searchQuery;
  final bool hasSearched;

  BusSearchLoaded({
    required this.allBuses,
    required this.filteredBuses,
    required this.searchQuery,
    this.hasSearched = false,
  });

  @override
  List<Object?> get props => [
    allBuses,
    filteredBuses,
    searchQuery,
    hasSearched,
  ];

  BusSearchLoaded copyWith({
    List<Bus>? allBuses,
    List<Bus>? filteredBuses,
    String? searchQuery,
    bool? hasSearched,
  }) {
    return BusSearchLoaded(
      allBuses: allBuses ?? this.allBuses,
      filteredBuses: filteredBuses ?? this.filteredBuses,
      searchQuery: searchQuery ?? this.searchQuery,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class BusSearchError extends BusSearchState {
  final String message;

  BusSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
