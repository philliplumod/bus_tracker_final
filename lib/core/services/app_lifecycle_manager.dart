import 'package:flutter/material.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../services/hive_service.dart';

/// Manages app lifecycle events and state persistence
class AppLifecycleManager extends WidgetsBindingObserver {
  final AppSettingsRepository settingsRepository;
  final HiveService hiveService;
  final VoidCallback? onResumed;
  final VoidCallback? onPaused;
  final VoidCallback? onInactive;
  final VoidCallback? onDetached;

  AppLifecycleManager({
    required this.settingsRepository,
    required this.hiveService,
    this.onResumed,
    this.onPaused,
    this.onInactive,
    this.onDetached,
  });

  /// Initialize lifecycle observer
  void init() {
    WidgetsBinding.instance.addObserver(this);
    _saveAppState();
  }

  /// Dispose lifecycle observer
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _handleResumed();
        break;
      case AppLifecycleState.inactive:
        _handleInactive();
        break;
      case AppLifecycleState.paused:
        _handlePaused();
        break;
      case AppLifecycleState.detached:
        _handleDetached();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  void _handleResumed() {
    debugPrint('App resumed');

    // Clear expired cache
    hiveService.clearExpiredCache();

    // Restore app state
    _restoreAppState();

    // Callback
    onResumed?.call();
  }

  void _handleInactive() {
    debugPrint('App inactive');
    onInactive?.call();
  }

  void _handlePaused() {
    debugPrint('App paused');

    // Save current state
    _saveAppState();

    // Callback
    onPaused?.call();
  }

  void _handleDetached() {
    debugPrint('App detached');

    // Final save before closing
    _saveAppState();

    // Callback
    onDetached?.call();
  }

  /// Save app state before pausing
  void _saveAppState() {
    try {
      final now = DateTime.now().toIso8601String();
      hiveService.saveSession('last_pause_time', now);
      hiveService.saveSession('app_state', 'saved');
      debugPrint('App state saved at $now');
    } catch (e) {
      debugPrint('Error saving app state: $e');
    }
  }

  /// Restore app state when resuming
  void _restoreAppState() {
    try {
      final lastPauseTime = hiveService.getSession<String>('last_pause_time');
      if (lastPauseTime != null) {
        final pauseTime = DateTime.parse(lastPauseTime);
        final now = DateTime.now();
        final difference = now.difference(pauseTime);

        debugPrint('App was paused for ${difference.inSeconds} seconds');

        // If app was paused for more than 5 minutes, clear session
        if (difference.inMinutes > 5) {
          debugPrint('Session expired, clearing temporary data');
          // You can add logic here to refresh data
        }
      }

      hiveService.saveSession('app_state', 'restored');
      debugPrint('App state restored');
    } catch (e) {
      debugPrint('Error restoring app state: $e');
    }
  }

  /// Save user session data
  Future<void> saveUserSession({
    required String userId,
    String? currentScreen,
    Map<String, dynamic>? additionalData,
  }) async {
    await hiveService.saveSession('user_id', userId);
    if (currentScreen != null) {
      await hiveService.saveSession('current_screen', currentScreen);
    }
    if (additionalData != null) {
      await hiveService.saveSession('additional_data', additionalData);
    }
  }

  /// Restore user session data
  Map<String, dynamic> restoreUserSession() {
    return {
      'user_id': hiveService.getSession<String>('user_id'),
      'current_screen': hiveService.getSession<String>('current_screen'),
      'additional_data': hiveService.getSession<Map<String, dynamic>>(
        'additional_data',
      ),
    };
  }

  /// Clear user session
  Future<void> clearUserSession() async {
    await hiveService.clearSession();
  }
}
