import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../domain/entities/favorite_location.dart';
import '../../data/datasources/favorites_local_data_source.dart';

class FavoritesState {
  final List<FavoriteLocation> favorites;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<FavoriteLocation>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {'favorites': favorites.map((fav) => fav.toJson()).toList()};
  }

  factory FavoritesState.fromJson(Map<String, dynamic> json) {
    try {
      final favoritesJson = json['favorites'] as List?;
      return FavoritesState(
        favorites:
            favoritesJson
                ?.map(
                  (e) => FavoriteLocation.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
    } catch (e) {
      return const FavoritesState();
    }
  }
}

class FavoritesCubit extends HydratedCubit<FavoritesState> {
  final FavoritesLocalDataSource dataSource;

  FavoritesCubit({required this.dataSource}) : super(const FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      emit(state.copyWith(isLoading: true));
      final favorites = await dataSource.getFavorites();
      emit(state.copyWith(favorites: favorites, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load favorites: $e'),
      );
    }
  }

  Future<void> addFavorite(FavoriteLocation location) async {
    try {
      await dataSource.addFavorite(location);
      final updatedFavorites = List<FavoriteLocation>.from(state.favorites)
        ..add(location);
      emit(state.copyWith(favorites: updatedFavorites, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add favorite: $e'));
    }
  }

  Future<void> removeFavorite(String id) async {
    try {
      await dataSource.removeFavorite(id);
      final updatedFavorites =
          state.favorites.where((fav) => fav.id != id).toList();
      emit(state.copyWith(favorites: updatedFavorites, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to remove favorite: $e'));
    }
  }

  bool isFavorite(String name) {
    return state.favorites.any(
      (fav) => fav.name.toLowerCase() == name.toLowerCase(),
    );
  }

  Future<void> clearFavorites() async {
    try {
      await dataSource.clearFavorites();
      emit(state.copyWith(favorites: [], error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to clear favorites: $e'));
    }
  }

  @override
  FavoritesState? fromJson(Map<String, dynamic> json) {
    try {
      return FavoritesState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(FavoritesState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }
}
