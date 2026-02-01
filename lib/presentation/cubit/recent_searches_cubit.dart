import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../data/datasources/recent_searches_data_source.dart';

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
  final RecentSearchesDataSource dataSource;

  RecentSearchesCubit({required this.dataSource})
    : super(const RecentSearchesState()) {
    loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    try {
      emit(state.copyWith(isLoading: true));
      final searches = await dataSource.getRecentSearches();
      emit(state.copyWith(searches: searches, isLoading: false));
    } catch (e) {
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
      await dataSource.addSearch(query);
      await loadRecentSearches();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add search: $e'));
    }
  }

  Future<void> removeSearch(String query) async {
    try {
      await dataSource.removeSearch(query);
      final updatedSearches =
          state.searches
              .where(
                (search) => search.query.toLowerCase() != query.toLowerCase(),
              )
              .toList();
      emit(state.copyWith(searches: updatedSearches, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to remove search: $e'));
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      await dataSource.clearRecentSearches();
      emit(state.copyWith(searches: [], error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to clear recent searches: $e'));
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
