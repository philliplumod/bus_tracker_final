import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide preferences and settings
abstract class AppPreferencesDataSource {
  /// Get notification enabled status
  Future<bool> getNotificationsEnabled();

  /// Set notification enabled status
  Future<void> setNotificationsEnabled(bool enabled);

  /// Get tracking enabled status (for riders)
  Future<bool> getTrackingEnabled();

  /// Set tracking enabled status
  Future<void> setTrackingEnabled(bool enabled);

  /// Get map type preference
  Future<String> getMapType();

  /// Set map type preference
  Future<void> setMapType(String mapType);

  /// Get show traffic overlay preference
  Future<bool> getShowTraffic();

  /// Set show traffic overlay preference
  Future<void> setShowTraffic(bool show);
}

class AppPreferencesDataSourceImpl implements AppPreferencesDataSource {
  final SharedPreferences prefs;

  static const String _notificationsKey = 'notifications_enabled';
  static const String _trackingKey = 'tracking_enabled';
  static const String _mapTypeKey = 'map_type';
  static const String _showTrafficKey = 'show_traffic';

  AppPreferencesDataSourceImpl({required this.prefs});

  @override
  Future<bool> getNotificationsEnabled() async {
    return prefs.getBool(_notificationsKey) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await prefs.setBool(_notificationsKey, enabled);
  }

  @override
  Future<bool> getTrackingEnabled() async {
    return prefs.getBool(_trackingKey) ?? true;
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    await prefs.setBool(_trackingKey, enabled);
  }

  @override
  Future<String> getMapType() async {
    return prefs.getString(_mapTypeKey) ?? 'normal';
  }

  @override
  Future<void> setMapType(String mapType) async {
    await prefs.setString(_mapTypeKey, mapType);
  }

  @override
  Future<bool> getShowTraffic() async {
    return prefs.getBool(_showTrafficKey) ?? false;
  }

  @override
  Future<void> setShowTraffic(bool show) async {
    await prefs.setBool(_showTrafficKey, show);
  }
}
