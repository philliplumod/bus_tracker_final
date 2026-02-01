import 'package:dartz/dartz.dart';
import '../../data/datasources/recent_searches_data_source.dart';
import '../../core/error/failures.dart';

abstract class RecentSearchesRepository {
  /// Get recent searches
  Future<Either<Failure, List<RecentSearch>>> getRecentSearches();

  /// Add a search query to recent searches
  Future<Either<Failure, void>> addSearch(String query);

  /// Remove a specific search from recent searches
  Future<Either<Failure, void>> removeSearch(String query);

  /// Clear all recent searches
  Future<Either<Failure, void>> clearRecentSearches();
}
