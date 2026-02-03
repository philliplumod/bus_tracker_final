import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Base event for app settings
abstract class AppSettingsEvent extends Equatable {
  const AppSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load settings
class LoadAppSettings extends AppSettingsEvent {
  const LoadAppSettings();
}

/// Update theme mode
class UpdateThemeMode extends AppSettingsEvent {
  final ThemeMode themeMode;

  const UpdateThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

/// Toggle notifications
class ToggleNotifications extends AppSettingsEvent {
  final bool enabled;

  const ToggleNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Toggle sound
class ToggleSound extends AppSettingsEvent {
  final bool enabled;

  const ToggleSound(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Toggle vibration
class ToggleVibration extends AppSettingsEvent {
  final bool enabled;

  const ToggleVibration(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Update map style
class UpdateMapStyle extends AppSettingsEvent {
  final String style;

  const UpdateMapStyle(this.style);

  @override
  List<Object?> get props => [style];
}

/// Toggle traffic layer
class ToggleTrafficLayer extends AppSettingsEvent {
  final bool show;

  const ToggleTrafficLayer(this.show);

  @override
  List<Object?> get props => [show];
}

/// Update auto refresh interval
class UpdateAutoRefreshInterval extends AppSettingsEvent {
  final int seconds;

  const UpdateAutoRefreshInterval(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

/// Toggle keep screen on
class ToggleKeepScreenOn extends AppSettingsEvent {
  final bool keepOn;

  const ToggleKeepScreenOn(this.keepOn);

  @override
  List<Object?> get props => [keepOn];
}

/// Update last viewed screen
class UpdateLastViewedScreen extends AppSettingsEvent {
  final String screen;

  const UpdateLastViewedScreen(this.screen);

  @override
  List<Object?> get props => [screen];
}

/// Update last viewed bus route
class UpdateLastViewedBusRoute extends AppSettingsEvent {
  final String routeId;

  const UpdateLastViewedBusRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

/// Reset settings to defaults
class ResetSettings extends AppSettingsEvent {
  const ResetSettings();
}
