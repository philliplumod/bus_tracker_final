import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/usecases/get_nearby_buses.dart';
import 'bus_search_event.dart';
import 'bus_search_state.dart';

class BusSearchBloc extends HydratedBloc<BusSearchEvent, BusSearchState> {
  final GetNearbyBuses getNearbyBuses;

  BusSearchBloc({required this.getNearbyBuses}) : super(BusSearchInitial()) {
    on<LoadAllBuses>(_onLoadAllBuses);
    on<SearchBusByNumber>(_onSearchBusByNumber);
    on<ClearBusSearch>(_onClearBusSearch);
  }

  @override
  BusSearchState? fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String?;
      switch (type) {
        case 'loaded':
          final allBusesJson = json['allBuses'] as List?;
          final filteredBusesJson = json['filteredBuses'] as List?;
          if (allBusesJson != null && filteredBusesJson != null) {
            return BusSearchLoaded(
              allBuses:
                  allBusesJson
                      .map((e) => Bus.fromJson(e as Map<String, dynamic>))
                      .toList(),
              filteredBuses:
                  filteredBusesJson
                      .map((e) => Bus.fromJson(e as Map<String, dynamic>))
                      .toList(),
              searchQuery: json['searchQuery'] as String? ?? '',
              hasSearched: json['hasSearched'] as bool? ?? false,
            );
          }
          return null;
        case 'loading':
          return BusSearchLoading();
        case 'error':
          return BusSearchError(json['message'] as String? ?? 'Unknown error');
        case 'initial':
        default:
          return BusSearchInitial();
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(BusSearchState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
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
