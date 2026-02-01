import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bus.dart';

abstract class BusLocalDataSource {
  /// Get cached buses from local storage
  Future<List<Bus>> getCachedBuses();

  /// Cache buses to local storage
  Future<void> cacheBuses(List<Bus> buses);

  /// Clear cached buses
  Future<void> clearCachedBuses();

  /// Get last update timestamp
  Future<DateTime?> getLastUpdateTime();

  /// Set last update timestamp
  Future<void> setLastUpdateTime(DateTime time);
}

class BusLocalDataSourceImpl implements BusLocalDataSource {
  final SharedPreferences prefs;

  static const String _cachedBusesKey = 'cached_buses';
  static const String _lastUpdateKey = 'buses_last_update';
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  BusLocalDataSourceImpl({required this.prefs});

  @override
  Future<List<Bus>> getCachedBuses() async {
    try {
      final jsonString = prefs.getString(_cachedBusesKey);
      if (jsonString == null) return [];

      // Check if cache is still valid
      final lastUpdate = await getLastUpdateTime();
      if (lastUpdate != null) {
        final now = DateTime.now();
        if (now.difference(lastUpdate) > _cacheValidDuration) {
          // Cache expired, clear it
          await clearCachedBuses();
          return [];
        }
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Bus.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheBuses(List<Bus> buses) async {
    try {
      final jsonList = buses.map((bus) => bus.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_cachedBusesKey, jsonString);
      await setLastUpdateTime(DateTime.now());
    } catch (e) {
      // Silently fail if caching fails
    }
  }

  @override
  Future<void> clearCachedBuses() async {
    await prefs.remove(_cachedBusesKey);
    await prefs.remove(_lastUpdateKey);
  }

  @override
  Future<DateTime?> getLastUpdateTime() async {
    final timestamp = prefs.getInt(_lastUpdateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  Future<void> setLastUpdateTime(DateTime time) async {
    await prefs.setInt(_lastUpdateKey, time.millisecondsSinceEpoch);
  }
}
