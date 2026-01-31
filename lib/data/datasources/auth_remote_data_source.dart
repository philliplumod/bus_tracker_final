import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

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
  // TODO: IMPORTANT - Replace with your actual backend API URL
  // This should point to your authentication server that handles:
  // - POST /api/auth/sign-in (for all roles: passenger, rider, admin)
  // - POST /api/auth/sign-up (for passengers only)
  // - POST /api/auth/sign-out
  //
  // NOTE: Rider accounts CANNOT be created through signup.
  // Riders are created by Admin through the web dashboard only.
  static const String baseUrl = 'https://your-api-url.com/api';
  final http.Client client;
  final SharedPreferences prefs;

  AuthRemoteDataSourceImpl({required this.client, required this.prefs});

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/sign-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);

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

        return user;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else {
        throw Exception('Failed to sign in: ${response.body}');
      }
    } catch (e) {
      throw Exception('Sign in error: $e');
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
      final response = await client.post(
        Uri.parse('$baseUrl/auth/sign-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          // Note: Do not send 'role' field - backend will force it to 'passenger'
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);

        // Verify that the user is indeed a passenger
        if (user.role != UserRole.passenger) {
          throw Exception('Invalid user role returned from signup');
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
      await client.post(
        Uri.parse('$baseUrl/auth/sign-out'),
        headers: {'Content-Type': 'application/json'},
      );

      // Clear local storage
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('user_assigned_route');
      await prefs.remove('user_bus_name');
    } catch (e) {
      // Even if API call fails, clear local data
      await prefs.clear();
      throw Exception('Sign out error: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = prefs.getString('user_id');
      if (userId == null) return null;

      final email = prefs.getString('user_email');
      final name = prefs.getString('user_name');
      final roleString = prefs.getString('user_role');

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
      );
    } catch (e) {
      return null;
    }
  }

  String _roleToString(dynamic role) {
    if (role is String) return role;
    switch (role) {
      case UserRole.admin:
        return 'admin';
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
      case 'admin':
        return UserRole.admin;
      case 'rider':
        return UserRole.rider;
      case 'passenger':
        return UserRole.passenger;
      default:
        return UserRole.passenger;
    }
  }
}
