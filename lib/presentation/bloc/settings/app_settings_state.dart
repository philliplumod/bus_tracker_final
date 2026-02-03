import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Base state for app settings
abstract class AppSettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String mapStyle;
  final bool showTrafficLayer;
  final int autoRefreshInterval;
  final bool keepScreenOn;
  final String? lastViewedScreen;
  final String? lastViewedBusRoute;

  const AppSettingsState({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.mapStyle,
    required this.showTrafficLayer,
    required this.autoRefreshInterval,
    required this.keepScreenOn,
    this.lastViewedScreen,
    this.lastViewedBusRoute,
  });

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    soundEnabled,
    vibrationEnabled,
    mapStyle,
    showTrafficLayer,
    autoRefreshInterval,
    keepScreenOn,
    lastViewedScreen,
    lastViewedBusRoute,
  ];
}

/// Initial state
class AppSettingsInitial extends AppSettingsState {
  const AppSettingsInitial()
    : super(
        themeMode: ThemeMode.system,
        notificationsEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        mapStyle: 'standard',
        showTrafficLayer: false,
        autoRefreshInterval: 30,
        keepScreenOn: false,
      );
}

/// Loading state
class AppSettingsLoading extends AppSettingsState {
  const AppSettingsLoading({
    required super.themeMode,
    required super.notificationsEnabled,
    required super.soundEnabled,
    required super.vibrationEnabled,
    required super.mapStyle,
    required super.showTrafficLayer,
    required super.autoRefreshInterval,
    required super.keepScreenOn,
    super.lastViewedScreen,
    super.lastViewedBusRoute,
  });
}

/// Loaded state
class AppSettingsLoaded extends AppSettingsState {
  const AppSettingsLoaded({
    required super.themeMode,
    required super.notificationsEnabled,
    required super.soundEnabled,
    required super.vibrationEnabled,
    required super.mapStyle,
    required super.showTrafficLayer,
    required super.autoRefreshInterval,
    required super.keepScreenOn,
    super.lastViewedScreen,
    super.lastViewedBusRoute,
  });

  AppSettingsLoaded copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? mapStyle,
    bool? showTrafficLayer,
    int? autoRefreshInterval,
    bool? keepScreenOn,
    String? lastViewedScreen,
    String? lastViewedBusRoute,
  }) {
    return AppSettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      mapStyle: mapStyle ?? this.mapStyle,
      showTrafficLayer: showTrafficLayer ?? this.showTrafficLayer,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      lastViewedScreen: lastViewedScreen ?? this.lastViewedScreen,
      lastViewedBusRoute: lastViewedBusRoute ?? this.lastViewedBusRoute,
    );
  }
}

/// Error state
class AppSettingsError extends AppSettingsState {
  final String message;

  const AppSettingsError({
    required this.message,
    required super.themeMode,
    required super.notificationsEnabled,
    required super.soundEnabled,
    required super.vibrationEnabled,
    required super.mapStyle,
    required super.showTrafficLayer,
    required super.autoRefreshInterval,
    required super.keepScreenOn,
    super.lastViewedScreen,
    super.lastViewedBusRoute,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
