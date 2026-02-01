import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      final favorites =
          jsonList
              .map(
                (json) =>
                    FavoriteLocation.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      debugPrint('Successfully loaded ${favorites.length} favorites');
      return favorites;
    } catch (e, stackTrace) {
      debugPrint('Error getting favorites: $e');
      debugPrint('StackTrace: $stackTrace');
      // Return empty list on error but log it
      return [];
    }
  }

  @override
  Future<void> addFavorite(FavoriteLocation location) async {
    try {
      // Validate location
      if (location.name.trim().isEmpty) {
        throw ArgumentError('Favorite location name cannot be empty');
      }

      final favorites = await getFavorites();

      // Avoid duplicates by checking both id and name
      final isDuplicate = favorites.any(
        (fav) =>
            fav.id == location.id ||
            fav.name.toLowerCase() == location.name.toLowerCase(),
      );

      if (!isDuplicate) {
        favorites.add(location);
        final jsonList = favorites.map((fav) => fav.toJson()).toList();
        final jsonString = json.encode(jsonList);
        final success = await prefs.setString(_favoritesKey, jsonString);

        if (success) {
          debugPrint('Successfully added favorite: ${location.name}');
        } else {
          throw Exception('Failed to save favorite to SharedPreferences');
        }
      } else {
        debugPrint('Favorite already exists: ${location.name}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding favorite: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    try {
      final favorites = await getFavorites();
      final initialCount = favorites.length;
      favorites.removeWhere((fav) => fav.id == id);

      if (favorites.length < initialCount) {
        final jsonList = favorites.map((fav) => fav.toJson()).toList();
        final jsonString = json.encode(jsonList);
        final success = await prefs.setString(_favoritesKey, jsonString);

        if (success) {
          debugPrint('Successfully removed favorite with id: $id');
        } else {
          throw Exception('Failed to save favorites after removal');
        }
      } else {
        debugPrint('Favorite with id $id not found');
      }
    } catch (e, stackTrace) {
      debugPrint('Error removing favorite: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
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
    try {
      final success = await prefs.remove(_favoritesKey);
      if (success) {
        debugPrint('Successfully cleared all favorites');
      }
    } catch (e, stackTrace) {
      debugPrint('Error clearing favorites: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
