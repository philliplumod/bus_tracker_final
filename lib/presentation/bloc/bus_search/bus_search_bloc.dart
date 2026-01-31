import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_nearby_buses.dart';
import 'bus_search_event.dart';
import 'bus_search_state.dart';

class BusSearchBloc extends Bloc<BusSearchEvent, BusSearchState> {
  final GetNearbyBuses getNearbyBuses;

  BusSearchBloc({required this.getNearbyBuses}) : super(BusSearchInitial()) {
    on<LoadAllBuses>(_onLoadAllBuses);
    on<SearchBusByNumber>(_onSearchBusByNumber);
    on<ClearBusSearch>(_onClearBusSearch);
  }

  Future<void> _onLoadAllBuses(
    LoadAllBuses event,
    Emitter<BusSearchState> emit,
  ) async {
    emit(BusSearchLoading());

    final result = await getNearbyBuses();

    result.fold(
      (failure) => emit(BusSearchError(failure.toString())),
      (buses) => emit(
        BusSearchLoaded(
          allBuses: buses,
          filteredBuses: [],
          searchQuery: '',
          hasSearched: false,
        ),
      ),
    );
  }

  void _onSearchBusByNumber(
    SearchBusByNumber event,
    Emitter<BusSearchState> emit,
  ) {
    if (state is BusSearchLoaded) {
      final currentState = state as BusSearchLoaded;
      final query = event.busNumber.trim().toLowerCase();

      if (query.isEmpty) {
        emit(
          currentState.copyWith(
            filteredBuses: [],
            searchQuery: '',
            hasSearched: true,
          ),
        );
        return;
      }

      final filteredBuses =
          currentState.allBuses.where((bus) {
            final busNumber = bus.busNumber?.toLowerCase() ?? '';
            final busId = bus.id.toLowerCase();
            return busNumber.contains(query) || busId.contains(query);
          }).toList();

      emit(
        currentState.copyWith(
          filteredBuses: filteredBuses,
          searchQuery: query,
          hasSearched: true,
        ),
      );
    }
  }

  void _onClearBusSearch(ClearBusSearch event, Emitter<BusSearchState> emit) {
    if (state is BusSearchLoaded) {
      final currentState = state as BusSearchLoaded;
      emit(
        currentState.copyWith(
          filteredBuses: [],
          searchQuery: '',
          hasSearched: false,
        ),
      );
    }
  }
}
