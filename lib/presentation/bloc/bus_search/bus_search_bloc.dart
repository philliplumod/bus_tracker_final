import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/usecases/get_nearby_buses.dart';
import '../../../domain/repositories/bus_repository.dart';
import 'bus_search_event.dart';
import 'bus_search_state.dart';

class BusSearchBloc extends HydratedBloc<BusSearchEvent, BusSearchState> {
  final GetNearbyBuses getNearbyBuses;
  final BusRepository busRepository;
  StreamSubscription? _busStreamSubscription;

  BusSearchBloc({required this.getNearbyBuses, required this.busRepository})
    : super(BusSearchInitial()) {
    on<LoadAllBuses>(_onLoadAllBuses);
    on<SearchBusByNumber>(_onSearchBusByNumber);
    on<ClearBusSearch>(_onClearBusSearch);
    on<UpdateBusesFromStream>(_onUpdateBusesFromStream);
  }

  @override
  Future<void> close() {
    _busStreamSubscription?.cancel();
    return super.close();
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

    // Cancel previous subscription if exists
    await _busStreamSubscription?.cancel();

    // Start listening to real-time bus updates
    _busStreamSubscription = busRepository.watchBusUpdates().listen((result) {
      result.fold(
        (failure) {
          if (!isClosed) {
            add(
              UpdateBusesFromStream(
                [],
                isError: true,
                errorMessage: failure.toString(),
              ),
            );
          }
        },
        (buses) {
          if (!isClosed) {
            add(UpdateBusesFromStream(buses));
          }
        },
      );
    });
  }

  void _onUpdateBusesFromStream(
    UpdateBusesFromStream event,
    Emitter<BusSearchState> emit,
  ) {
    if (event.isError) {
      emit(BusSearchError(event.errorMessage ?? 'Unknown error'));
      return;
    }

    if (state is BusSearchLoaded) {
      final currentState = state as BusSearchLoaded;
      final updatedBuses = event.buses;

      // Reapply current search filter if there is one
      List<Bus> filteredBuses = [];
      if (currentState.hasSearched && currentState.searchQuery.isNotEmpty) {
        final query = currentState.searchQuery.toLowerCase();
        filteredBuses =
            updatedBuses.where((bus) {
              final busNumber = (bus.busNumber ?? '').toLowerCase();
              final busId = bus.id.toLowerCase();
              final route = (bus.route ?? '').toLowerCase();

              // Check direct matches
              if (busNumber.contains(query) ||
                  busId.contains(query) ||
                  route.contains(query)) {
                return true;
              }

              // Extract numbers from query and bus data for flexible matching
              final queryNumbers =
                  RegExp(
                    r'\d+',
                  ).allMatches(query).map((m) => m.group(0)).join();

              if (queryNumbers.isNotEmpty) {
                final busNumberDigits =
                    RegExp(
                      r'\d+',
                    ).allMatches(busNumber).map((m) => m.group(0)).join();
                final busIdDigits =
                    RegExp(
                      r'\d+',
                    ).allMatches(busId).map((m) => m.group(0)).join();

                if (busNumberDigits.contains(queryNumbers) ||
                    busIdDigits.contains(queryNumbers)) {
                  return true;
                }
              }

              return false;
            }).toList();
      } else {
        filteredBuses = currentState.filteredBuses;
      }

      emit(
        currentState.copyWith(
          allBuses: updatedBuses,
          filteredBuses: filteredBuses,
        ),
      );
    } else {
      // Initial load - Show all buses by default for bus search page
      // Unlike trip solution, bus search shows all active buses
      emit(
        BusSearchLoaded(
          allBuses: event.buses,
          filteredBuses: event.buses, // Show all buses initially
          searchQuery: '',
          hasSearched: false,
        ),
      );
    }
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

      debugPrint('🔍 Searching for: "$query"');
      debugPrint('📊 Total buses available: ${currentState.allBuses.length}');

      // Log all available buses for debugging
      for (var bus in currentState.allBuses) {
        debugPrint(
          '  Bus: id="${bus.id}", number="${bus.busNumber}", route="${bus.route}"',
        );
      }

      final filteredBuses =
          currentState.allBuses.where((bus) {
            final busNumber = (bus.busNumber ?? '').toLowerCase();
            final busId = bus.id.toLowerCase();
            final route = (bus.route ?? '').toLowerCase();

            // Check direct matches
            if (busNumber.contains(query) ||
                busId.contains(query) ||
                route.contains(query)) {
              debugPrint('  ✅ Match found: ${bus.id} (direct match)');
              return true;
            }

            // Extract numbers from query and bus data for flexible matching
            final queryNumbers =
                RegExp(r'\d+').allMatches(query).map((m) => m.group(0)).join();

            if (queryNumbers.isNotEmpty) {
              final busNumberDigits =
                  RegExp(
                    r'\d+',
                  ).allMatches(busNumber).map((m) => m.group(0)).join();
              final busIdDigits =
                  RegExp(
                    r'\d+',
                  ).allMatches(busId).map((m) => m.group(0)).join();

              if (busNumberDigits.contains(queryNumbers) ||
                  busIdDigits.contains(queryNumbers)) {
                debugPrint('  ✅ Match found: ${bus.id} (number match)');
                return true;
              }
            }

            return false;
          }).toList();

      debugPrint('📍 Found ${filteredBuses.length} matching buses');

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
