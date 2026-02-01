import 'package:equatable/equatable.dart';
import '../../../domain/entities/bus.dart';

abstract class BusSearchState extends Equatable {
  @override
  List<Object?> get props => [];

  Map<String, dynamic> toJson();
}

class BusSearchInitial extends BusSearchState {
  @override
  Map<String, dynamic> toJson() => {'type': 'initial'};
}

class BusSearchLoading extends BusSearchState {
  @override
  Map<String, dynamic> toJson() => {'type': 'loading'};
}

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

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'loaded',
      'allBuses': allBuses.map((bus) => bus.toJson()).toList(),
      'filteredBuses': filteredBuses.map((bus) => bus.toJson()).toList(),
      'searchQuery': searchQuery,
      'hasSearched': hasSearched,
    };
  }

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

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'error', 'message': message};
  }
}
