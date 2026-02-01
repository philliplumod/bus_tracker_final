import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../data/datasources/recent_searches_data_source.dart';
import '../../domain/usecases/get_recent_searches.dart';
import '../../domain/usecases/add_recent_search.dart';
import '../../domain/usecases/remove_recent_search.dart';

class RecentSearchesState {
  final List<RecentSearch> searches;
  final bool isLoading;
  final String? error;

  const RecentSearchesState({
    this.searches = const [],
    this.isLoading = false,
    this.error,
  });

  RecentSearchesState copyWith({
    List<RecentSearch>? searches,
    bool? isLoading,
    String? error,
  }) {
    return RecentSearchesState(
      searches: searches ?? this.searches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {'searches': searches.map((search) => search.toJson()).toList()};
  }

  factory RecentSearchesState.fromJson(Map<String, dynamic> json) {
    try {
      final searchesJson = json['searches'] as List?;
      return RecentSearchesState(
        searches:
            searchesJson
                ?.map((e) => RecentSearch.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      return const RecentSearchesState();
    }
  }
}

class RecentSearchesCubit extends HydratedCubit<RecentSearchesState> {
  final GetRecentSearches getRecentSearchesUseCase;
  final AddRecentSearch addRecentSearchUseCase;
  final RemoveRecentSearch removeRecentSearchUseCase;

  RecentSearchesCubit({
    required this.getRecentSearchesUseCase,
    required this.addRecentSearchUseCase,
    required this.removeRecentSearchUseCase,
  }) : super(const RecentSearchesState()) {
    _initializeWithSync();
  }

  /// Initialize cubit with state synchronization
  /// This ensures HydratedBloc state is consistent with SharedPreferences
  Future<void> _initializeWithSync() async {
    await loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      final result = await getRecentSearchesUseCase();

      result.fold(
        (failure) {
          debugPrint('Failed to load recent searches: ${failure.message}');
          emit(state.copyWith(isLoading: false, error: failure.message));
        },
        (searches) {
          debugPrint('Loaded ${searches.length} recent searches');
          emit(state.copyWith(searches: searches, isLoading: false));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error loading recent searches: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load recent searches: $e',
        ),
      );
    }
  }

  Future<void> addSearch(String query) async {
    try {
      if (query.trim().isEmpty) {
        debugPrint('Cannot add empty search query');
        return;
      }

      final result = await addRecentSearchUseCase(query);

      result.fold(
        (failure) {
          debugPrint('Failed to add search: ${failure.message}');
          emit(state.copyWith(error: failure.message));
        },
        (_) async {
          // Reload searches to get updated list
          await loadRecentSearches();
          debugPrint('Added search: $query');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error adding search: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(state.copyWith(error: 'Failed to add search: $e'));
    }
  }

  Future<void> removeSearch(String query) async {
    try {
      final result = await removeRecentSearchUseCase(query);

      result.fold(
        (failure) {
          debugPrint('Failed to remove search: ${failure.message}');
          emit(state.copyWith(error: failure.message));
        },
        (_) {
          final updatedSearches =
              state.searches
                  .where(
                    (search) =>
                        search.query.toLowerCase() != query.toLowerCase(),
                  )
                  .toList();
          debugPrint('Removed search: $query');
          emit(state.copyWith(searches: updatedSearches, error: null));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error removing search: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(state.copyWith(error: 'Failed to remove search: $e'));
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      // Clear from state immediately for better UX
      emit(state.copyWith(searches: [], error: null));
      debugPrint('Cleared all recent searches');
    } catch (e, stackTrace) {
      debugPrint('Unexpected error clearing searches: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(state.copyWith(error: 'Failed to clear recent searches: $e'));
      // Reload searches on error
      await loadRecentSearches();
    }
  }

  List<String> getRecentQueries() {
    return state.searches.map((search) => search.query).toList();
  }

  @override
  RecentSearchesState? fromJson(Map<String, dynamic> json) {
    try {
      return RecentSearchesState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(RecentSearchesState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }
}
