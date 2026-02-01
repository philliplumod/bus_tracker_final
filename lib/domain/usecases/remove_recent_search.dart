import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/recent_searches_repository.dart';

class RemoveRecentSearch {
  final RecentSearchesRepository repository;

  RemoveRecentSearch(this.repository);

  Future<Either<Failure, void>> call(String query) async {
    return await repository.removeSearch(query);
  }
}
