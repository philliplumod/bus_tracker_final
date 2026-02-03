import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive Firebase Realtime Database Service
/// Handles all Firebase operations with proper error handling, retry logic, and logging
class FirebaseRealtimeService {
  final DatabaseReference _dbRef;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _operationTimeout = Duration(seconds: 10);

  FirebaseRealtimeService({DatabaseReference? dbRef})
    : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  /// Write data to Firebase with retry logic
  Future<void> writeData({
    required String path,
    required Map<String, dynamic> data,
    int retryCount = 0,
  }) async {
    try {
      debugPrint('📝 Firebase Write: $path');
      debugPrint('   Data: ${data.keys.join(", ")}');

      await _dbRef
          .child(path)
          .set(data)
          .timeout(
            _operationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Write operation timed out after ${_operationTimeout.inSeconds}s',
              );
            },
          );

      debugPrint('✅ Firebase write successful: $path');
    } catch (e) {
      debugPrint(
        '❌ Firebase write failed (attempt ${retryCount + 1}/$_maxRetries): $e',
      );

      if (retryCount < _maxRetries) {
        debugPrint('   Retrying in ${_retryDelay.inSeconds} seconds...');
        await Future.delayed(_retryDelay);
        return writeData(path: path, data: data, retryCount: retryCount + 1);
      }

      debugPrint('   ❌ All retry attempts exhausted');
      _logFirebaseError(e, 'write', path);
      rethrow;
    }
  }

  /// Update data in Firebase with retry logic
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
    int retryCount = 0,
  }) async {
    try {
      debugPrint('🔄 Firebase Update: $path');
      debugPrint('   Fields: ${data.keys.join(", ")}');

      await _dbRef
          .child(path)
          .update(data)
          .timeout(
            _operationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Update operation timed out after ${_operationTimeout.inSeconds}s',
              );
            },
          );

      debugPrint('✅ Firebase update successful: $path');
    } catch (e) {
      debugPrint(
        '❌ Firebase update failed (attempt ${retryCount + 1}/$_maxRetries): $e',
      );

      if (retryCount < _maxRetries) {
        debugPrint('   Retrying in ${_retryDelay.inSeconds} seconds...');
        await Future.delayed(_retryDelay);
        return updateData(path: path, data: data, retryCount: retryCount + 1);
      }

      debugPrint('   ❌ All retry attempts exhausted');
      _logFirebaseError(e, 'update', path);
      rethrow;
    }
  }

  /// Delete data from Firebase with retry logic
  Future<void> deleteData({required String path, int retryCount = 0}) async {
    try {
      debugPrint('🗑️ Firebase Delete: $path');

      await _dbRef
          .child(path)
          .remove()
          .timeout(
            _operationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Delete operation timed out after ${_operationTimeout.inSeconds}s',
              );
            },
          );

      debugPrint('✅ Firebase delete successful: $path');
    } catch (e) {
      debugPrint(
        '❌ Firebase delete failed (attempt ${retryCount + 1}/$_maxRetries): $e',
      );

      if (retryCount < _maxRetries) {
        debugPrint('   Retrying in ${_retryDelay.inSeconds} seconds...');
        await Future.delayed(_retryDelay);
        return deleteData(path: path, retryCount: retryCount + 1);
      }

      debugPrint('   ❌ All retry attempts exhausted');
      _logFirebaseError(e, 'delete', path);
      rethrow;
    }
  }

  /// Read data from Firebase once
  Future<Map<String, dynamic>?> readData({
    required String path,
    int retryCount = 0,
  }) async {
    try {
      debugPrint('📖 Firebase Read: $path');

      final snapshot = await _dbRef
          .child(path)
          .get()
          .timeout(
            _operationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Read operation timed out after ${_operationTimeout.inSeconds}s',
              );
            },
          );

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('   ℹ️ No data found at path: $path');
        return null;
      }

      final data = snapshot.value;
      if (data is Map) {
        debugPrint('✅ Firebase read successful: $path');
        return Map<String, dynamic>.from(data);
      }

      debugPrint('   ⚠️ Data at path is not a map: ${data.runtimeType}');
      return null;
    } catch (e) {
      debugPrint(
        '❌ Firebase read failed (attempt ${retryCount + 1}/$_maxRetries): $e',
      );

      if (retryCount < _maxRetries) {
        debugPrint('   Retrying in ${_retryDelay.inSeconds} seconds...');
        await Future.delayed(_retryDelay);
        return readData(path: path, retryCount: retryCount + 1);
      }

      debugPrint('   ❌ All retry attempts exhausted');
      _logFirebaseError(e, 'read', path);
      rethrow;
    }
  }

  /// Listen to real-time updates at a path
  Stream<Map<String, dynamic>?> listenToPath(String path) {
    debugPrint('👂 Firebase Listen: $path');

    return _dbRef
        .child(path)
        .onValue
        .map((event) {
          final snapshot = event.snapshot;

          if (!snapshot.exists || snapshot.value == null) {
            debugPrint('   ℹ️ Listener: No data at $path');
            return null;
          }

          final data = snapshot.value;
          if (data is Map) {
            debugPrint('   ✅ Listener: Data received at $path');
            return Map<String, dynamic>.from(data);
          }

          debugPrint('   ⚠️ Listener: Data is not a map: ${data.runtimeType}');
          return null;
        })
        .handleError((error) {
          debugPrint('❌ Firebase listener error at $path: $error');
          _logFirebaseError(error, 'listen', path);
        });
  }

  /// Test Firebase connectivity
  Future<bool> testConnectivity() async {
    try {
      debugPrint('🧪 Testing Firebase connectivity...');

      final testPath =
          'connectivity_test/${DateTime.now().millisecondsSinceEpoch}';
      final testData = {
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      };

      // Try to write test data
      await writeData(path: testPath, data: testData);

      // Try to read it back
      final readData = await this.readData(path: testPath);

      // Clean up
      await deleteData(path: testPath);

      if (readData != null && readData['test'] == true) {
        debugPrint('✅ Firebase connectivity test passed');
        return true;
      }

      debugPrint('⚠️ Firebase connectivity test: data mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ Firebase connectivity test failed: $e');
      return false;
    }
  }

  /// Write location update to Firebase
  Future<void> writeLocationUpdate({
    required String userId,
    required String busName,
    required Map<String, dynamic> locationData,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Write to multiple paths for different query patterns
    await Future.wait([
      // 1. Rider's location history
      writeData(path: 'riders/$userId/location/$timestamp', data: locationData),

      // 2. Current rider info (for quick access)
      updateData(
        path: 'riders/$userId',
        data: {
          'userName': locationData['userName'],
          'busName': locationData['busName'],
          'routeName': locationData['routeName'],
          'busRouteAssignmentId': locationData['busRouteAssignmentId'],
          'currentLocation': {
            'latitude': locationData['latitude'],
            'longitude': locationData['longitude'],
            'speed': locationData['speed'],
            'heading': locationData['heading'],
            'accuracy': locationData['accuracy'],
          },
          'startingTerminal': {
            'name': locationData['startingTerminalName'],
            'latitude': locationData['startingTerminalLat'],
            'longitude': locationData['startingTerminalLng'],
          },
          'destinationTerminal': {
            'name': locationData['destinationTerminalName'],
            'latitude': locationData['destinationTerminalLat'],
            'longitude': locationData['destinationTerminalLng'],
          },
          'lastUpdate': locationData['timestamp'],
        },
      ),

      // 3. Active bus tracking (for passenger view)
      updateData(
        path: 'active_buses/$busName',
        data: {
          'busName': locationData['busName'],
          'routeName': locationData['routeName'],
          'riderId': locationData['userId'],
          'riderName': locationData['userName'],
          'currentLocation': {
            'latitude': locationData['latitude'],
            'longitude': locationData['longitude'],
            'speed': locationData['speed'],
            'heading': locationData['heading'],
            'accuracy': locationData['accuracy'],
          },
          'startingTerminal': {
            'name': locationData['startingTerminalName'],
            'latitude': locationData['startingTerminalLat'],
            'longitude': locationData['startingTerminalLng'],
          },
          'destinationTerminal': {
            'name': locationData['destinationTerminalName'],
            'latitude': locationData['destinationTerminalLat'],
            'longitude': locationData['destinationTerminalLng'],
          },
          'lastUpdate': locationData['timestamp'],
        },
      ),
    ]);

    debugPrint('✅ Location update written to all Firebase paths');
  }

  /// Log Firebase errors with context
  void _logFirebaseError(dynamic error, String operation, String path) {
    final errorString = error.toString();

    if (errorString.contains('PERMISSION_DENIED')) {
      debugPrint('');
      debugPrint('🚨 FIREBASE PERMISSION DENIED ERROR!');
      debugPrint('   Operation: $operation');
      debugPrint('   Path: $path');
      debugPrint('');
      debugPrint(
        '   Your Firebase Realtime Database rules are blocking $operation operations.',
      );
      debugPrint('');
      debugPrint('   📋 To fix this:');
      debugPrint('   1. Go to: https://console.firebase.google.com');
      debugPrint('   2. Select project: minibustracker-b2264');
      debugPrint('   3. Navigate to: Realtime Database → Rules');
      debugPrint('   4. Update rules to:');
      debugPrint('');
      debugPrint('   {');
      debugPrint('     "rules": {');
      debugPrint('       ".read": true,');
      debugPrint('       ".write": true');
      debugPrint('     }');
      debugPrint('   }');
      debugPrint('');
      debugPrint(
        '   ⚠️  NOTE: These are open rules for testing/development only!',
      );
      debugPrint('   For production, restrict access properly.');
      debugPrint('');
    } else if (errorString.contains('NETWORK_ERROR') ||
        errorString.contains('Failed host lookup')) {
      debugPrint('');
      debugPrint('🌐 FIREBASE NETWORK ERROR!');
      debugPrint('   Operation: $operation');
      debugPrint('   Path: $path');
      debugPrint('');
      debugPrint('   Check:');
      debugPrint('   1. Internet connection is active');
      debugPrint('   2. Firebase project is accessible');
      debugPrint('   3. Database URL is correct');
      debugPrint('');
    } else if (errorString.contains('TimeoutException')) {
      debugPrint('');
      debugPrint('⏱️ FIREBASE TIMEOUT ERROR!');
      debugPrint('   Operation: $operation');
      debugPrint('   Path: $path');
      debugPrint('   Timeout: ${_operationTimeout.inSeconds}s');
      debugPrint('');
      debugPrint('   This might indicate:');
      debugPrint('   1. Slow internet connection');
      debugPrint('   2. Firebase service issues');
      debugPrint('   3. Large data transfer');
      debugPrint('');
    }
  }
}
