import 'package:dartz/dartz.dart';
import '../entities/favorite_location.dart';
import '../../core/error/failures.dart';

abstract class FavoritesRepository {
  /// Get all favorite locations
  Future<Either<Failure, List<FavoriteLocation>>> getFavorites();

  /// Add a location to favorites
  Future<Either<Failure, void>> addFavorite(FavoriteLocation location);

  /// Remove a location from favorites by ID
  Future<Either<Failure, void>> removeFavorite(String id);

  /// Check if a location is a favorite
  Future<Either<Failure, bool>> isFavorite(String name);

  /// Clear all favorites
  Future<Either<Failure, void>> clearFavorites();
}
