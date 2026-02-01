import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/favorite_location.dart';

abstract class FavoritesLocalDataSource {
  /// Get all favorite locations
  Future<List<FavoriteLocation>> getFavorites();

  /// Add a favorite location
  Future<void> addFavorite(FavoriteLocation location);

  /// Remove a favorite location by id
  Future<void> removeFavorite(String id);

  /// Check if location is favorited
  Future<bool> isFavorite(String name);

  /// Clear all favorites
  Future<void> clearFavorites();
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  final SharedPreferences prefs;

  static const String _favoritesKey = 'favorite_locations';

  FavoritesLocalDataSourceImpl({required this.prefs});

  @override
  Future<List<FavoriteLocation>> getFavorites() async {
    try {
      final jsonString = prefs.getString(_favoritesKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map(
            (json) => FavoriteLocation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addFavorite(FavoriteLocation location) async {
    try {
      final favorites = await getFavorites();

      // Avoid duplicates
      if (!favorites.any((fav) => fav.id == location.id)) {
        favorites.add(location);
        final jsonList = favorites.map((fav) => fav.toJson()).toList();
        final jsonString = json.encode(jsonList);
        await prefs.setString(_favoritesKey, jsonString);
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => fav.id == id);

      final jsonList = favorites.map((fav) => fav.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<bool> isFavorite(String name) async {
    try {
      final favorites = await getFavorites();
      return favorites.any(
        (fav) => fav.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearFavorites() async {
    await prefs.remove(_favoritesKey);
  }
}
