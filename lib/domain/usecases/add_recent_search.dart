import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/recent_searches_repository.dart';

class AddRecentSearch {
  final RecentSearchesRepository repository;

  AddRecentSearch(this.repository);

  Future<Either<Failure, void>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }
    return await repository.addSearch(query);
  }
}
