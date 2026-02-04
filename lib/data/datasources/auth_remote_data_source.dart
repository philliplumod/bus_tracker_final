import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'api_client.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // This should point to your authentication server that handles:
  // - POST /api/auth/sign-in (for all roles: passenger, rider, admin)
  // - POST /api/auth/sign-up (for passengers only)
  // - POST /api/auth/sign-out
  //
  // NOTE: Rider accounts CANNOT be created through signup.
  // Riders are created by Admin through the web dashboard only.

  // For Android Emulator, use: http://10.0.2.2:3000/api
  // For iOS Simulator, use: http://localhost:3000/api
  // For physical device via USB/ADB, use: http://localhost:3000/api (after: adb reverse tcp:3000 tcp:3000)
  // For physical device via Wi-Fi, use your computer's IP: http://192.168.x.x:3000/api
  // For production, use: https://your-production-domain.com/api
  static const String baseUrl = 'http://localhost:3000/api';
  final http.Client client;
  final SharedPreferences prefs;
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.prefs,
    required this.apiClient,
  });

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting login for: $email');
      debugPrint('📡 Backend URL: $baseUrl/auth/sign-in');

      final response = await client
          .post(
            Uri.parse('$baseUrl/auth/sign-in'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏱️ Request timed out');
              throw Exception(
                'Connection timed out. Please check your backend server is running.',
              );
            },
          );

      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug: Show what keys are in the response
        debugPrint('🔍 Response keys: ${data.keys.toList()}');

        // Handle both 'user' and 'profile' response formats
        final userData = data['user'] ?? data['profile'];
        if (userData == null) {
          throw Exception('No user or profile data in response');
        }

        final user = UserModel.fromJson(userData);

        debugPrint('✅ Login successful for user: ${user.email} (${user.role}');
        debugPrint('   Bus: ${user.busName} (${user.busId})');
        debugPrint('   Route: ${user.assignedRoute} (${user.routeId})');
        debugPrint('   Assignment ID: ${user.busRouteId}');

        // Store tokens from session object (new format) or root level (old format)
        final session = data['session'];
        debugPrint('🔍 Session object: ${session != null ? "exists" : "null"}');
        if (session != null) {
          debugPrint('🔍 Session keys: ${session.keys.toList()}');
          // New format: tokens are in session object
          if (session['access_token'] != null) {
            final token = session['access_token'] as String;
            await prefs.setString('access_token', token);
            debugPrint('🔑 Access token stored from session');
            debugPrint('🔑 Token length: ${token.length} chars');
            debugPrint(
              '🔑 Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...',
            );
          } else {
            debugPrint('⚠️ No access_token in session object!');
          }
          if (session['refresh_token'] != null) {
            await prefs.setString('refresh_token', session['refresh_token']);
            debugPrint('🔑 Refresh token stored from session');
          }
          if (session['expires_at'] != null) {
            await prefs.setInt('token_expires_at', session['expires_at']);
            debugPrint('⏰ Token expiry time stored');
          }
        } else {
          // Old format: tokens at root level (backward compatibility)
          if (data.containsKey('accessToken')) {
            await prefs.setString('access_token', data['accessToken']);
            debugPrint('🔑 Access token stored');
          }
          if (data.containsKey('refreshToken')) {
            await prefs.setString('refresh_token', data['refreshToken']);
            debugPrint('🔑 Refresh token stored');
          }
        }

        // Store user data locally
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_name', user.name);
        await prefs.setString('user_role', _roleToString(user.role));
        if (user.assignedRoute != null) {
          await prefs.setString('user_assigned_route', user.assignedRoute!);
        }
        if (user.busName != null) {
          await prefs.setString('user_bus_name', user.busName!);
        }
        if (user.busId != null) {
          await prefs.setString('user_bus_id', user.busId!);
        }
        if (user.routeId != null) {
          await prefs.setString('user_route_id', user.routeId!);
        }
        if (user.busRouteId != null) {
          await prefs.setString('user_bus_route_id', user.busRouteId!);
        }
        if (user.startingTerminal != null) {
          await prefs.setString(
            'user_starting_terminal',
            user.startingTerminal!,
          );
        }
        if (user.destinationTerminal != null) {
          await prefs.setString(
            'user_destination_terminal',
            user.destinationTerminal!,
          );
        }
        if (user.startingTerminalLat != null) {
          await prefs.setDouble(
            'user_starting_terminal_lat',
            user.startingTerminalLat!,
          );
        }
        if (user.startingTerminalLng != null) {
          await prefs.setDouble(
            'user_starting_terminal_lng',
            user.startingTerminalLng!,
          );
        }
        if (user.destinationTerminalLat != null) {
          await prefs.setDouble(
            'user_destination_terminal_lat',
            user.destinationTerminalLat!,
          );
        }
        if (user.destinationTerminalLng != null) {
          await prefs.setDouble(
            'user_destination_terminal_lng',
            user.destinationTerminalLng!,
          );
        }
        if (user.assignedAt != null) {
          await prefs.setString(
            'user_assigned_at',
            user.assignedAt!.toIso8601String(),
          );
        }

        debugPrint('💾 User data stored in SharedPreferences');
        return user;
      } else if (response.statusCode == 401) {
        // Parse error body to check for specific auth errors
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? '';
          final errorCode = errorData['code'] ?? '';

          debugPrint(
            '❌ Authentication failed: $errorMessage (code: $errorCode)',
          );

          // Check for specific error codes
          if (errorMessage.toLowerCase().contains('email not confirmed') ||
              errorCode == 'email_not_confirmed') {
            throw Exception(
              'Email not verified. Please check your email inbox and click the verification link, or contact your administrator.',
            );
          }

          if (errorMessage.toLowerCase().contains(
                'invalid login credentials',
              ) ||
              errorMessage.toLowerCase().contains('invalid credentials') ||
              errorCode == 'invalid_credentials') {
            throw Exception(
              'Invalid email or password. Please double-check your credentials.',
            );
          }

          // If we have a message from the backend, use it
          if (errorMessage.isNotEmpty) {
            throw Exception(errorMessage);
          }
        } catch (e) {
          // If we already threw a formatted exception, rethrow it
          if (e is Exception) {
            rethrow;
          }
        }

        // Default error message for 401
        debugPrint('❌ Authentication failed: Invalid credentials');
        throw Exception(
          'Invalid email or password. Please check your credentials and try again.',
        );
      } else if (response.statusCode == 404) {
        debugPrint('❌ Backend endpoint not found');
        throw Exception(
          'Authentication service not found. Please check if the backend server is running.',
        );
      } else {
        final errorBody = response.body;
        try {
          final errorData = jsonDecode(errorBody);
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          debugPrint('❌ Server error: $errorMessage');
          throw Exception(errorMessage);
        } catch (_) {
          debugPrint('❌ Server error: ${response.statusCode}');
          throw Exception(
            'Server error: ${response.statusCode}. Please try again later.',
          );
        }
      }
    } on Exception {
      rethrow; // Re-throw our formatted exceptions
    } catch (e) {
      debugPrint('❌ Network error: $e');
      // Catch network errors and other unexpected errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check:\n1. Backend server is running\n2. Network connection is active\n3. Firewall settings',
        );
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // IMPORTANT: This endpoint only allows PASSENGER registration.
    // Rider and Admin accounts must be created through the web dashboard.
    // The backend should enforce role = "passenger" for all signup requests.

    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/auth/sign-up'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'name': name,
              // Note: Do not send 'role' field - backend will force it to 'passenger'
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timed out. Check: 1) Backend is running, 2) Firewall allows port 3000, 3) Phone and PC on same Wi-Fi',
              );
            },
          );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);

        // Verify that the user is indeed a passenger
        if (user.role != UserRole.passenger) {
          throw Exception('Invalid user role returned from signup');
        }

        // Store tokens from session object (new format) or root level (old format)
        final session = data['session'];
        if (session != null) {
          // New format: tokens are in session object
          if (session['access_token'] != null) {
            await prefs.setString('access_token', session['access_token']);
            debugPrint('🔑 Access token stored from session');
          }
          if (session['refresh_token'] != null) {
            await prefs.setString('refresh_token', session['refresh_token']);
            debugPrint('🔑 Refresh token stored from session');
          }
          if (session['expires_at'] != null) {
            await prefs.setInt('token_expires_at', session['expires_at']);
            debugPrint('⏰ Token expiry time stored');
          }
        } else {
          // Old format: tokens at root level (backward compatibility)
          if (data.containsKey('accessToken')) {
            await prefs.setString('access_token', data['accessToken']);
          }
          if (data.containsKey('refreshToken')) {
            await prefs.setString('refresh_token', data['refreshToken']);
          }
        }

        // Store user data locally
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_name', user.name);
        await prefs.setString('user_role', _roleToString(user.role));

        return user;
      } else if (response.statusCode == 409) {
        throw Exception('Email already exists');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid input data');
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final accessToken = prefs.getString('access_token');
      final headers = {'Content-Type': 'application/json'};

      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      await client.post(Uri.parse('$baseUrl/auth/sign-out'), headers: headers);

      // Clear local storage
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('user_assigned_route');
      await prefs.remove('user_bus_name');
      await prefs.remove('user_bus_id');
      await prefs.remove('user_route_id');
      await prefs.remove('user_bus_route_id');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expires_at');
    } catch (e) {
      // Even if API call fails, clear local data
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('user_assigned_route');
      await prefs.remove('user_bus_name');
      await prefs.remove('user_bus_id');
      await prefs.remove('user_route_id');
      await prefs.remove('user_bus_route_id');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expires_at');
      throw Exception('Sign out error: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id');
      final roleString = prefs.getString('user_role');

      // For riders, skip backend API and use local storage + Supabase
      // Rider assignments are now fetched directly from Supabase
      if (roleString == 'rider') {
        debugPrint(
          '👤 Rider detected - using local storage (Supabase handles assignments)',
        );
        // Skip to local storage fallback for riders
      } else if (accessToken != null) {
        // For non-riders, try to fetch from backend
        // Ensure the ApiClient has the token
        apiClient.setAuthToken(accessToken);

        try {
          // Use generic auth endpoint for passengers and other roles
          String endpoint = '/auth/user';
          debugPrint('📡 Fetching user profile from: $endpoint');

          // Use ApiClient instead of raw HTTP client for consistent token handling
          final data = await apiClient.get(endpoint);

          if (data != null) {
            debugPrint('📦 Response data keys: ${data.keys.toList()}');

            // Handle rider profile response format
            // Try multiple possible keys: 'rider', 'user', 'profile', or direct data
            final userData =
                data['rider'] ??
                data['user'] ??
                data['profile'] ??
                (data.containsKey('id') ? data : null);

            if (userData == null) {
              debugPrint(
                '❌ No user data found in response. Keys: ${data.keys.toList()}',
              );
              debugPrint('📄 Full response: $data');
              throw Exception('No user data in response');
            }

            final user = UserModel.fromJson(userData);

            debugPrint('✅ User profile loaded:');
            debugPrint('   Role: ${user.role}');
            debugPrint('   Bus: ${user.busName} (${user.busId})');
            debugPrint('   Route: ${user.assignedRoute} (${user.routeId})');
            debugPrint('   Destination: ${user.destinationTerminal}');
            debugPrint(
              '   Dest Coords: (${user.destinationTerminalLat}, ${user.destinationTerminalLng})',
            );

            // Update local storage with fresh data
            await prefs.setString('user_id', user.id);
            await prefs.setString('user_email', user.email);
            await prefs.setString('user_name', user.name);
            await prefs.setString('user_role', _roleToString(user.role));
            if (user.assignedRoute != null) {
              await prefs.setString('user_assigned_route', user.assignedRoute!);
            }
            if (user.busName != null) {
              await prefs.setString('user_bus_name', user.busName!);
            }
            if (user.busId != null) {
              await prefs.setString('user_bus_id', user.busId!);
            }
            if (user.routeId != null) {
              await prefs.setString('user_route_id', user.routeId!);
            }
            if (user.busRouteId != null) {
              await prefs.setString('user_bus_route_id', user.busRouteId!);
            }
            if (user.startingTerminal != null) {
              await prefs.setString(
                'user_starting_terminal',
                user.startingTerminal!,
              );
            }
            if (user.destinationTerminal != null) {
              await prefs.setString(
                'user_destination_terminal',
                user.destinationTerminal!,
              );
            }
            if (user.startingTerminalLat != null) {
              await prefs.setDouble(
                'user_starting_terminal_lat',
                user.startingTerminalLat!,
              );
            }
            if (user.startingTerminalLng != null) {
              await prefs.setDouble(
                'user_starting_terminal_lng',
                user.startingTerminalLng!,
              );
            }
            if (user.destinationTerminalLat != null) {
              await prefs.setDouble(
                'user_destination_terminal_lat',
                user.destinationTerminalLat!,
              );
            }
            if (user.destinationTerminalLng != null) {
              await prefs.setDouble(
                'user_destination_terminal_lng',
                user.destinationTerminalLng!,
              );
            }
            if (user.assignedAt != null) {
              await prefs.setString(
                'user_assigned_at',
                user.assignedAt!.toIso8601String(),
              );
            }

            return user;
          } else {
            debugPrint('❌ API returned null response');
          }
        } catch (e, stackTrace) {
          // If backend call fails, fall back to local storage
          debugPrint('⚠️ Backend fetch failed, using local storage: $e');
          debugPrint('📍 Stack trace: $stackTrace');
        }
      }

      // Fall back to local storage
      if (userId == null) return null;

      final email = prefs.getString('user_email');
      final name = prefs.getString('user_name');

      if (email == null || name == null || roleString == null) {
        return null;
      }

      return UserModel(
        id: userId,
        email: email,
        name: name,
        role: _roleFromString(roleString),
        assignedRoute: prefs.getString('user_assigned_route'),
        busName: prefs.getString('user_bus_name'),
        busId: prefs.getString('user_bus_id'),
        routeId: prefs.getString('user_route_id'),
        busRouteId: prefs.getString('user_bus_route_id'),
        startingTerminal: prefs.getString('user_starting_terminal'),
        destinationTerminal: prefs.getString('user_destination_terminal'),
        startingTerminalLat: prefs.getDouble('user_starting_terminal_lat'),
        startingTerminalLng: prefs.getDouble('user_starting_terminal_lng'),
        destinationTerminalLat: prefs.getDouble(
          'user_destination_terminal_lat',
        ),
        destinationTerminalLng: prefs.getDouble(
          'user_destination_terminal_lng',
        ),
        assignedAt:
            prefs.getString('user_assigned_at') != null
                ? DateTime.parse(prefs.getString('user_assigned_at')!)
                : null,
      );
    } catch (e) {
      return null;
    }
  }

  String _roleToString(dynamic role) {
    if (role is String) return role;
    switch (role) {
      case UserRole.rider:
        return 'rider';
      case UserRole.passenger:
        return 'passenger';
      default:
        return 'passenger';
    }
  }

  UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'rider':
        return UserRole.rider;
      case 'passenger':
        return UserRole.passenger;
      default:
        return UserRole.passenger;
    }
  }
}
