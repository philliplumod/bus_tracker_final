import 'package:dartz/dartz.dart';
import '../../domain/entities/favorite_location.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/favorites_local_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource localDataSource;

  FavoritesRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<FavoriteLocation>>> getFavorites() async {
    try {
      final favorites = await localDataSource.getFavorites();
      return Right(favorites);
    } catch (e) {
      return Left(CacheFailure('Failed to get favorites: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addFavorite(FavoriteLocation location) async {
    try {
      await localDataSource.addFavorite(location);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add favorite: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeFavorite(String id) async {
    try {
      await localDataSource.removeFavorite(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove favorite: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite(String name) async {
    try {
      final favorites = await localDataSource.getFavorites();
      final isFav = favorites.any(
        (fav) => fav.name.toLowerCase() == name.toLowerCase(),
      );
      return Right(isFav);
    } catch (e) {
      return Left(CacheFailure('Failed to check favorite: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearFavorites() async {
    try {
      await localDataSource.clearFavorites();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear favorites: ${e.toString()}'));
    }
  }
}
