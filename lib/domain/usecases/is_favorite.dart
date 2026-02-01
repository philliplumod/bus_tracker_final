import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/favorites_repository.dart';

class IsFavorite {
  final FavoritesRepository repository;

  IsFavorite(this.repository);

  Future<Either<Failure, bool>> call(String name) async {
    return await repository.isFavorite(name);
  }
}
