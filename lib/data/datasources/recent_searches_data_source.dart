import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentSearch {
  final String query;
  final DateTime searchedAt;

  const RecentSearch({required this.query, required this.searchedAt});

  Map<String, dynamic> toJson() {
    return {'query': query, 'searchedAt': searchedAt.toIso8601String()};
  }

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      query: json['query'] as String,
      searchedAt: DateTime.parse(json['searchedAt'] as String),
    );
  }
}

abstract class RecentSearchesDataSource {
  /// Get recent searches
  Future<List<RecentSearch>> getRecentSearches();

  /// Add a search to recent searches
  Future<void> addSearch(String query);

  /// Remove a specific search
  Future<void> removeSearch(String query);

  /// Clear all recent searches
  Future<void> clearRecentSearches();
}

class RecentSearchesDataSourceImpl implements RecentSearchesDataSource {
  final SharedPreferences prefs;

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  RecentSearchesDataSourceImpl({required this.prefs});

  @override
  Future<List<RecentSearch>> getRecentSearches() async {
    try {
      final jsonString = prefs.getString(_recentSearchesKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      final searches =
          jsonList
              .map(
                (json) => RecentSearch.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      // Sort by most recent first
      searches.sort((a, b) => b.searchedAt.compareTo(a.searchedAt));

      debugPrint('Successfully loaded ${searches.length} recent searches');
      return searches;
    } catch (e, stackTrace) {
      debugPrint('Error getting recent searches: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }

  @override
  Future<void> addSearch(String query) async {
    try {
      if (query.trim().isEmpty) {
        debugPrint('Cannot add empty search query');
        return;
      }

      final trimmedQuery = query.trim();
      final searches = await getRecentSearches();

      // Remove existing entry if present (case-insensitive)
      searches.removeWhere(
        (search) => search.query.toLowerCase() == trimmedQuery.toLowerCase(),
      );

      // Add new search at the beginning
      searches.insert(
        0,
        RecentSearch(query: trimmedQuery, searchedAt: DateTime.now()),
      );

      // Keep only the most recent searches
      if (searches.length > _maxRecentSearches) {
        searches.removeRange(_maxRecentSearches, searches.length);
      }

      final jsonList = searches.map((search) => search.toJson()).toList();
      final jsonString = json.encode(jsonList);
      final success = await prefs.setString(_recentSearchesKey, jsonString);

      if (success) {
        debugPrint('Successfully added recent search: $trimmedQuery');
      } else {
        throw Exception('Failed to save recent search');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding search: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> removeSearch(String query) async {
    try {
      final searches = await getRecentSearches();
      final initialCount = searches.length;
      searches.removeWhere(
        (search) => search.query.toLowerCase() == query.toLowerCase(),
      );

      if (searches.length < initialCount) {
        final jsonList = searches.map((search) => search.toJson()).toList();
        final jsonString = json.encode(jsonList);
        final success = await prefs.setString(_recentSearchesKey, jsonString);

        if (success) {
          debugPrint('Successfully removed recent search: $query');
        } else {
          throw Exception('Failed to save searches after removal');
        }
      } else {
        debugPrint('Search query not found: $query');
      }
    } catch (e, stackTrace) {
      debugPrint('Error removing search: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> clearRecentSearches() async {
    try {
      final success = await prefs.remove(_recentSearchesKey);
      if (success) {
        debugPrint('Successfully cleared all recent searches');
      }
    } catch (e, stackTrace) {
      debugPrint('Error clearing recent searches: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
