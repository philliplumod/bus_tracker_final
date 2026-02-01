import 'dart:convert';
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
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      final searches =
          jsonList
              .map(
                (json) => RecentSearch.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      // Sort by most recent first
      searches.sort((a, b) => b.searchedAt.compareTo(a.searchedAt));

      return searches;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addSearch(String query) async {
    try {
      if (query.trim().isEmpty) return;

      final searches = await getRecentSearches();

      // Remove existing entry if present
      searches.removeWhere(
        (search) => search.query.toLowerCase() == query.toLowerCase(),
      );

      // Add new search at the beginning
      searches.insert(
        0,
        RecentSearch(query: query, searchedAt: DateTime.now()),
      );

      // Keep only the most recent searches
      if (searches.length > _maxRecentSearches) {
        searches.removeRange(_maxRecentSearches, searches.length);
      }

      final jsonList = searches.map((search) => search.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_recentSearchesKey, jsonString);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> removeSearch(String query) async {
    try {
      final searches = await getRecentSearches();
      searches.removeWhere(
        (search) => search.query.toLowerCase() == query.toLowerCase(),
      );

      final jsonList = searches.map((search) => search.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_recentSearchesKey, jsonString);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> clearRecentSearches() async {
    await prefs.remove(_recentSearchesKey);
  }
}
