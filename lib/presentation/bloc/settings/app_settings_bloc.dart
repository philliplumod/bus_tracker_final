import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/app_settings_repository.dart';
import 'app_settings_event.dart';
import 'app_settings_state.dart';

/// BLoC for managing app settings
class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  final AppSettingsRepository _settingsRepository;

  AppSettingsBloc(this._settingsRepository)
    : super(const AppSettingsInitial()) {
    on<LoadAppSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ToggleSound>(_onToggleSound);
    on<ToggleVibration>(_onToggleVibration);
    on<UpdateMapStyle>(_onUpdateMapStyle);
    on<ToggleTrafficLayer>(_onToggleTrafficLayer);
    on<UpdateAutoRefreshInterval>(_onUpdateAutoRefreshInterval);
    on<ToggleKeepScreenOn>(_onToggleKeepScreenOn);
    on<UpdateLastViewedScreen>(_onUpdateLastViewedScreen);
    on<UpdateLastViewedBusRoute>(_onUpdateLastViewedBusRoute);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadAppSettings event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      final themeMode = _settingsRepository.getThemeMode();
      final notificationsEnabled =
          _settingsRepository.getNotificationsEnabled();
      final soundEnabled = _settingsRepository.getSoundEnabled();
      final vibrationEnabled = _settingsRepository.getVibrationEnabled();
      final mapStyle = _settingsRepository.getMapStyle();
      final showTrafficLayer = _settingsRepository.getShowTrafficLayer();
      final autoRefreshInterval = _settingsRepository.getAutoRefreshInterval();
      final keepScreenOn = _settingsRepository.getKeepScreenOn();
      final lastViewedScreen = _settingsRepository.getLastViewedScreen();
      final lastViewedBusRoute = _settingsRepository.getLastViewedBusRoute();

      emit(
        AppSettingsLoaded(
          themeMode: themeMode,
          notificationsEnabled: notificationsEnabled,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
          mapStyle: mapStyle,
          showTrafficLayer: showTrafficLayer,
          autoRefreshInterval: autoRefreshInterval,
          keepScreenOn: keepScreenOn,
          lastViewedScreen: lastViewedScreen,
          lastViewedBusRoute: lastViewedBusRoute,
        ),
      );
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setThemeMode(event.themeMode);
      if (state is AppSettingsLoaded) {
        emit((state as AppSettingsLoaded).copyWith(themeMode: event.themeMode));
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setNotificationsEnabled(event.enabled);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(
            notificationsEnabled: event.enabled,
          ),
        );
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onToggleSound(
    ToggleSound event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setSoundEnabled(event.enabled);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(soundEnabled: event.enabled),
        );
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onToggleVibration(
    ToggleVibration event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setVibrationEnabled(event.enabled);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(
            vibrationEnabled: event.enabled,
          ),
        );
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onUpdateMapStyle(
    UpdateMapStyle event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setMapStyle(event.style);
      if (state is AppSettingsLoaded) {
        emit((state as AppSettingsLoaded).copyWith(mapStyle: event.style));
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onToggleTrafficLayer(
    ToggleTrafficLayer event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setShowTrafficLayer(event.show);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(showTrafficLayer: event.show),
        );
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onUpdateAutoRefreshInterval(
    UpdateAutoRefreshInterval event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setAutoRefreshInterval(event.seconds);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(
            autoRefreshInterval: event.seconds,
          ),
        );
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onToggleKeepScreenOn(
    ToggleKeepScreenOn event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setKeepScreenOn(event.keepOn);
      if (state is AppSettingsLoaded) {
        emit((state as AppSettingsLoaded).copyWith(keepScreenOn: event.keepOn));
      }
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }

  Future<void> _onUpdateLastViewedScreen(
    UpdateLastViewedScreen event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setLastViewedScreen(event.screen);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(lastViewedScreen: event.screen),
        );
      }
    } catch (e) {
      // Silent fail for screen tracking
    }
  }

  Future<void> _onUpdateLastViewedBusRoute(
    UpdateLastViewedBusRoute event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setLastViewedBusRoute(event.routeId);
      if (state is AppSettingsLoaded) {
        emit(
          (state as AppSettingsLoaded).copyWith(
            lastViewedBusRoute: event.routeId,
          ),
        );
      }
    } catch (e) {
      // Silent fail for route tracking
    }
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      await _settingsRepository.resetToDefaults();
      add(const LoadAppSettings());
    } catch (e) {
      emit(
        AppSettingsError(
          message: e.toString(),
          themeMode: state.themeMode,
          notificationsEnabled: state.notificationsEnabled,
          soundEnabled: state.soundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          mapStyle: state.mapStyle,
          showTrafficLayer: state.showTrafficLayer,
          autoRefreshInterval: state.autoRefreshInterval,
          keepScreenOn: state.keepScreenOn,
          lastViewedScreen: state.lastViewedScreen,
          lastViewedBusRoute: state.lastViewedBusRoute,
        ),
      );
    }
  }
}
