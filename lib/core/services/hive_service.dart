import 'package:hive_flutter/hive_flutter.dart';

/// Central service for managing Hive local storage
class HiveService {
  // Box names
  static const String _settingsBox = 'settings';
  static const String _recentSearchesBox = 'recent_searches';
  static const String _favoritesBox = 'favorites';
  static const String _sessionBox = 'session';
  static const String _cacheBox = 'cache';

  // Singleton pattern
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Boxes
  late Box<dynamic> _settings;
  late Box<dynamic> _recentSearches;
  late Box<dynamic> _favorites;
  late Box<dynamic> _session;
  late Box<dynamic> _cache;

  /// Initialize Hive and open all boxes
  Future<void> init() async {
    await Hive.initFlutter();

    _settings = await Hive.openBox(_settingsBox);
    _recentSearches = await Hive.openBox(_recentSearchesBox);
    _favorites = await Hive.openBox(_favoritesBox);
    _session = await Hive.openBox(_sessionBox);
    _cache = await Hive.openBox(_cacheBox);
  }

  // ============ Settings Methods ============

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue) as T?;
  }

  /// Save a setting value
  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await _settings.delete(key);
  }

  /// Get all settings
  Map<String, dynamic> getAllSettings() {
    return Map<String, dynamic>.from(_settings.toMap());
  }

  // ============ Recent Searches Methods ============

  /// Add a recent search
  Future<void> addRecentSearch(String searchTerm) async {
    final searches = getRecentSearches();

    // Remove if already exists
    searches.remove(searchTerm);

    // Add to beginning
    searches.insert(0, searchTerm);

    // Keep only last 20 searches
    if (searches.length > 20) {
      searches.removeRange(20, searches.length);
    }

    await _recentSearches.put('searches', searches);
  }

  /// Get recent searches
  List<String> getRecentSearches() {
    final searches = _recentSearches.get('searches', defaultValue: <String>[]);
    return List<String>.from(searches);
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    await _recentSearches.clear();
  }

  // ============ Favorites Methods ============

  /// Add a favorite
  Future<void> addFavorite(String id, Map<String, dynamic> data) async {
    await _favorites.put(id, data);
  }

  /// Remove a favorite
  Future<void> removeFavorite(String id) async {
    await _favorites.delete(id);
  }

  /// Check if item is favorite
  bool isFavorite(String id) {
    return _favorites.containsKey(id);
  }

  /// Get all favorites
  Map<String, dynamic> getAllFavorites() {
    return Map<String, dynamic>.from(_favorites.toMap());
  }

  /// Get favorite by ID
  Map<String, dynamic>? getFavorite(String id) {
    final data = _favorites.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // ============ Session Methods ============

  /// Save session data
  Future<void> saveSession(String key, dynamic value) async {
    await _session.put(key, value);
  }

  /// Get session data
  T? getSession<T>(String key, {T? defaultValue}) {
    return _session.get(key, defaultValue: defaultValue) as T?;
  }

  /// Clear session
  Future<void> clearSession() async {
    await _session.clear();
  }

  /// Delete session key
  Future<void> deleteSession(String key) async {
    await _session.delete(key);
  }

  // ============ Cache Methods ============

  /// Cache data with expiry
  Future<void> cacheData(
    String key,
    dynamic value, {
    Duration expiry = const Duration(hours: 1),
  }) async {
    final cacheItem = {
      'value': value,
      'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
    };
    await _cache.put(key, cacheItem);
  }

  /// Get cached data
  T? getCachedData<T>(String key) {
    final cacheItem = _cache.get(key);
    if (cacheItem == null) return null;

    final expiry = cacheItem['expiry'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      // Expired, delete it
      _cache.delete(key);
      return null;
    }

    return cacheItem['value'] as T?;
  }

  /// Clear expired cache
  Future<void> clearExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];

    for (var key in _cache.keys) {
      final cacheItem = _cache.get(key);
      if (cacheItem != null) {
        final expiry = cacheItem['expiry'] as int;
        if (now > expiry) {
          keysToDelete.add(key);
        }
      }
    }

    for (var key in keysToDelete) {
      await _cache.delete(key);
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _cache.clear();
  }

  // ============ Utility Methods ============

  /// Clear all data
  Future<void> clearAll() async {
    await Future.wait([
      _settings.clear(),
      _recentSearches.clear(),
      _favorites.clear(),
      _session.clear(),
      _cache.clear(),
    ]);
  }

  /// Close all boxes
  Future<void> close() async {
    await Future.wait([
      _settings.close(),
      _recentSearches.close(),
      _favorites.close(),
      _session.close(),
      _cache.close(),
    ]);
  }
}
