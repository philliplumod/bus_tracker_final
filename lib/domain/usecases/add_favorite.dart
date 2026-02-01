import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/favorite_location.dart';
import '../repositories/favorites_repository.dart';

class AddFavorite {
  final FavoritesRepository repository;

  AddFavorite(this.repository);

  Future<Either<Failure, void>> call(FavoriteLocation location) async {
    return await repository.addFavorite(location);
  }
}
