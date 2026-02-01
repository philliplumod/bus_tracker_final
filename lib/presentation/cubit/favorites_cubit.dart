import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../domain/entities/favorite_location.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/add_favorite.dart';
import '../../domain/usecases/remove_favorite.dart';
import '../../domain/usecases/is_favorite.dart';

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
  final GetFavorites getFavoritesUseCase;
  final AddFavorite addFavoriteUseCase;
  final RemoveFavorite removeFavoriteUseCase;
  final IsFavorite isFavoriteUseCase;

  FavoritesCubit({
    required this.getFavoritesUseCase,
    required this.addFavoriteUseCase,
    required this.removeFavoriteUseCase,
    required this.isFavoriteUseCase,
  }) : super(const FavoritesState()) {
    _initializeWithSync();
  }

  /// Initialize cubit with state synchronization
  /// This ensures HydratedBloc state is consistent with SharedPreferences
  Future<void> _initializeWithSync() async {
    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      final result = await getFavoritesUseCase();

      result.fold(
        (failure) {
          debugPrint('Failed to load favorites: ${failure.message}');
          emit(state.copyWith(isLoading: false, error: failure.message));
        },
        (favorites) {
          debugPrint('Loaded ${favorites.length} favorites');
          emit(state.copyWith(favorites: favorites, isLoading: false));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error loading favorites: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load favorites: $e'),
      );
    }
  }

  Future<void> addFavorite(FavoriteLocation location) async {
    try {
      final result = await addFavoriteUseCase(location);

      result.fold(
        (failure) {
          debugPrint('Failed to add favorite: ${failure.message}');
          emit(state.copyWith(error: failure.message));
        },
        (_) {
          final updatedFavorites = List<FavoriteLocation>.from(state.favorites)
            ..add(location);
          debugPrint('Added favorite: ${location.name}');
          emit(state.copyWith(favorites: updatedFavorites, error: null));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error adding favorite: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(state.copyWith(error: 'Failed to add favorite: $e'));
    }
  }

  Future<void> removeFavorite(String id) async {
    try {
      final result = await removeFavoriteUseCase(id);

      result.fold(
        (failure) {
          debugPrint('Failed to remove favorite: ${failure.message}');
          emit(state.copyWith(error: failure.message));
        },
        (_) {
          final updatedFavorites =
              state.favorites.where((fav) => fav.id != id).toList();
          debugPrint('Removed favorite with id: $id');
          emit(state.copyWith(favorites: updatedFavorites, error: null));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error removing favorite: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(state.copyWith(error: 'Failed to remove favorite: $e'));
    }
  }

  Future<bool> isFavorite(String name) async {
    try {
      final result = await isFavoriteUseCase(name);
      return result.fold((failure) {
        debugPrint('Error checking favorite: ${failure.message}');
        return false;
      }, (isFav) => isFav);
    } catch (e) {
      debugPrint('Unexpected error checking favorite: $e');
      return false;
    }
  }

  Future<void> clearFavorites() async {
    try {
      // Clear from state immediately for better UX
      emit(state.copyWith(favorites: [], error: null));

      // Note: Clear operation would need a use case if needed
      // For now, clearing state is sufficient with HydratedBloc
      debugPrint('Cleared all favorites');
    } catch (e, stackTrace) {
      debugPrint('Unexpected error clearing favorites: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(state.copyWith(error: 'Failed to clear favorites: $e'));
      // Reload favorites on error
      await loadFavorites();
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
