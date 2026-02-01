import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/favorite_location.dart';
import '../repositories/favorites_repository.dart';

class GetFavorites {
  final FavoritesRepository repository;

  GetFavorites(this.repository);

  Future<Either<Failure, List<FavoriteLocation>>> call() async {
    return await repository.getFavorites();
  }
}
