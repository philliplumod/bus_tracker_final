import 'package:dartz/dartz.dart';
import '../../domain/repositories/recent_searches_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/recent_searches_data_source.dart';

class RecentSearchesRepositoryImpl implements RecentSearchesRepository {
  final RecentSearchesDataSource dataSource;

  RecentSearchesRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<RecentSearch>>> getRecentSearches() async {
    try {
      final searches = await dataSource.getRecentSearches();
      return Right(searches);
    } catch (e) {
      return Left(
        CacheFailure('Failed to get recent searches: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> addSearch(String query) async {
    try {
      await dataSource.addSearch(query);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add search: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeSearch(String query) async {
    try {
      await dataSource.removeSearch(query);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove search: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearRecentSearches() async {
    try {
      await dataSource.clearRecentSearches();
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to clear recent searches: ${e.toString()}'),
      );
    }
  }
}
