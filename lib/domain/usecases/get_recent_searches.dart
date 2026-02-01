import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../data/datasources/recent_searches_data_source.dart';
import '../repositories/recent_searches_repository.dart';

class GetRecentSearches {
  final RecentSearchesRepository repository;

  GetRecentSearches(this.repository);

  Future<Either<Failure, List<RecentSearch>>> call() async {
    return await repository.getRecentSearches();
  }
}
