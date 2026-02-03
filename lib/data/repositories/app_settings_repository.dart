import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';

/// Keys for app settings
class SettingsKeys {
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String locationPermissionGranted = 'location_permission_granted';
  static const String mapStyle = 'map_style';
  static const String lastViewedScreen = 'last_viewed_screen';
  static const String lastViewedBusRoute = 'last_viewed_bus_route';
  static const String showTrafficLayer = 'show_traffic_layer';
  static const String autoRefreshInterval = 'auto_refresh_interval';
  static const String keepScreenOn = 'keep_screen_on';
  static const String soundEnabled = 'sound_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userRole = 'user_role';
  static const String isFirstLaunch = 'is_first_launch';
}

/// Repository for managing app settings and user preferences
class AppSettingsRepository {
  final HiveService _hiveService;

  AppSettingsRepository(this._hiveService);

  // ============ Theme Settings ============

  Future<void> setThemeMode(ThemeMode mode) async {
    await _hiveService.saveSetting(SettingsKeys.themeMode, mode.index);
  }

  ThemeMode getThemeMode() {
    final index = _hiveService.getSetting<int>(
      SettingsKeys.themeMode,
      defaultValue: ThemeMode.system.index,
    );
    return ThemeMode.values[index!];
  }

  // ============ Notification Settings ============

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _hiveService.saveSetting(SettingsKeys.notificationsEnabled, enabled);
  }

  bool getNotificationsEnabled() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.notificationsEnabled,
      defaultValue: true,
    )!;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _hiveService.saveSetting(SettingsKeys.soundEnabled, enabled);
  }

  bool getSoundEnabled() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.soundEnabled,
      defaultValue: true,
    )!;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _hiveService.saveSetting(SettingsKeys.vibrationEnabled, enabled);
  }

  bool getVibrationEnabled() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.vibrationEnabled,
      defaultValue: true,
    )!;
  }

  // ============ Map Settings ============

  Future<void> setMapStyle(String style) async {
    await _hiveService.saveSetting(SettingsKeys.mapStyle, style);
  }

  String getMapStyle() {
    return _hiveService.getSetting<String>(
      SettingsKeys.mapStyle,
      defaultValue: 'standard',
    )!;
  }

  Future<void> setShowTrafficLayer(bool show) async {
    await _hiveService.saveSetting(SettingsKeys.showTrafficLayer, show);
  }

  bool getShowTrafficLayer() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.showTrafficLayer,
      defaultValue: false,
    )!;
  }

  // ============ Session Management ============

  Future<void> setLastViewedScreen(String screen) async {
    await _hiveService.saveSetting(SettingsKeys.lastViewedScreen, screen);
  }

  String? getLastViewedScreen() {
    return _hiveService.getSetting<String>(SettingsKeys.lastViewedScreen);
  }

  Future<void> setLastViewedBusRoute(String routeId) async {
    await _hiveService.saveSetting(SettingsKeys.lastViewedBusRoute, routeId);
  }

  String? getLastViewedBusRoute() {
    return _hiveService.getSetting<String>(SettingsKeys.lastViewedBusRoute);
  }

  // ============ User Preferences ============

  Future<void> setAutoRefreshInterval(int seconds) async {
    await _hiveService.saveSetting(SettingsKeys.autoRefreshInterval, seconds);
  }

  int getAutoRefreshInterval() {
    return _hiveService.getSetting<int>(
      SettingsKeys.autoRefreshInterval,
      defaultValue: 30,
    )!;
  }

  Future<void> setKeepScreenOn(bool keepOn) async {
    await _hiveService.saveSetting(SettingsKeys.keepScreenOn, keepOn);
  }

  bool getKeepScreenOn() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.keepScreenOn,
      defaultValue: false,
    )!;
  }

  // ============ User Info ============

  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String name,
    required String role,
  }) async {
    await Future.wait([
      _hiveService.saveSetting(SettingsKeys.userId, userId),
      _hiveService.saveSetting(SettingsKeys.userEmail, email),
      _hiveService.saveSetting(SettingsKeys.userName, name),
      _hiveService.saveSetting(SettingsKeys.userRole, role),
    ]);
  }

  String? getUserId() {
    return _hiveService.getSetting<String>(SettingsKeys.userId);
  }

  String? getUserEmail() {
    return _hiveService.getSetting<String>(SettingsKeys.userEmail);
  }

  String? getUserName() {
    return _hiveService.getSetting<String>(SettingsKeys.userName);
  }

  String? getUserRole() {
    return _hiveService.getSetting<String>(SettingsKeys.userRole);
  }

  Future<void> clearUserInfo() async {
    await Future.wait([
      _hiveService.deleteSetting(SettingsKeys.userId),
      _hiveService.deleteSetting(SettingsKeys.userEmail),
      _hiveService.deleteSetting(SettingsKeys.userName),
      _hiveService.deleteSetting(SettingsKeys.userRole),
    ]);
  }

  // ============ First Launch ============

  bool isFirstLaunch() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.isFirstLaunch,
      defaultValue: true,
    )!;
  }

  Future<void> setFirstLaunchComplete() async {
    await _hiveService.saveSetting(SettingsKeys.isFirstLaunch, false);
  }

  // ============ Permissions ============

  Future<void> setLocationPermissionGranted(bool granted) async {
    await _hiveService.saveSetting(
      SettingsKeys.locationPermissionGranted,
      granted,
    );
  }

  bool getLocationPermissionGranted() {
    return _hiveService.getSetting<bool>(
      SettingsKeys.locationPermissionGranted,
      defaultValue: false,
    )!;
  }

  // ============ Utility ============

  Map<String, dynamic> getAllSettings() {
    return _hiveService.getAllSettings();
  }

  Future<void> resetToDefaults() async {
    await _hiveService.getSetting(SettingsKeys.themeMode);
    await setThemeMode(ThemeMode.system);
    await setNotificationsEnabled(true);
    await setMapStyle('standard');
    await setShowTrafficLayer(false);
    await setAutoRefreshInterval(30);
    await setKeepScreenOn(false);
    await setSoundEnabled(true);
    await setVibrationEnabled(true);
  }
}
