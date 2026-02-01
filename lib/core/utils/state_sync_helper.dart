import 'package:flutter/foundation.dart';

/// A utility class for syncing state between HydratedBloc and SharedPreferences
///
/// This ensures that state persistence is reliable and consistent across
/// both HydratedBloc's automatic state management and manual SharedPreferences storage.
class StateSyncHelper {
  /// Validates that HydratedBloc state is in sync with SharedPreferences data
  ///
  /// This can be called periodically or on app startup to ensure consistency
  static Future<bool> validateSync<T>({
    required T hydratedState,
    required Future<T> Function() loadFromPreferences,
    required bool Function(T, T) compareStates,
  }) async {
    try {
      final prefsState = await loadFromPreferences();
      final isInSync = compareStates(hydratedState, prefsState);

      if (!isInSync) {
        debugPrint(
          'WARNING: State mismatch detected between HydratedBloc and SharedPreferences',
        );
      } else {
        debugPrint('State sync validation passed');
      }

      return isInSync;
    } catch (e, stackTrace) {
      debugPrint('Error validating state sync: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Synchronizes state from SharedPreferences to HydratedBloc
  ///
  /// Useful when SharedPreferences is the source of truth
  static Future<T?> syncFromPreferences<T>({
    required Future<T> Function() loadFromPreferences,
  }) async {
    try {
      final state = await loadFromPreferences();
      debugPrint('Successfully synced state from SharedPreferences');
      return state;
    } catch (e, stackTrace) {
      debugPrint('Error syncing from SharedPreferences: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Synchronizes state from HydratedBloc to SharedPreferences
  ///
  /// Useful when HydratedBloc is the source of truth
  static Future<bool> syncToPreferences<T>({
    required T state,
    required Future<void> Function(T) saveToPreferences,
  }) async {
    try {
      await saveToPreferences(state);
      debugPrint('Successfully synced state to SharedPreferences');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error syncing to SharedPreferences: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Performs a full bidirectional sync
  ///
  /// Compares both sources and uses the most recent data
  static Future<T?> bidirectionalSync<T>({
    required T hydratedState,
    required Future<T> Function() loadFromPreferences,
    required Future<void> Function(T) saveToPreferences,
    required DateTime Function(T) getLastModified,
    required bool Function(T, T) compareStates,
  }) async {
    try {
      final prefsState = await loadFromPreferences();

      // Compare states
      if (compareStates(hydratedState, prefsState)) {
        debugPrint('States are already in sync');
        return hydratedState;
      }

      // Determine which state is more recent
      final hydratedTime = getLastModified(hydratedState);
      final prefsTime = getLastModified(prefsState);

      if (hydratedTime.isAfter(prefsTime)) {
        debugPrint('HydratedBloc state is more recent, syncing to preferences');
        await saveToPreferences(hydratedState);
        return hydratedState;
      } else {
        debugPrint('SharedPreferences state is more recent, returning it');
        return prefsState;
      }
    } catch (e, stackTrace) {
      debugPrint('Error performing bidirectional sync: $e');
      debugPrint('StackTrace: $stackTrace');
      return hydratedState; // Fall back to hydrated state on error
    }
  }
}
