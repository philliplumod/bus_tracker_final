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
  // ⚠️ DEMO MODE: Set to true to test without a backend server
  // Set to false when you have a real backend running
  static const bool useDemoMode = true;

  // TODO: IMPORTANT - Replace with your actual backend API URL
  // This should point to your authentication server that handles:
  // - POST /api/auth/sign-in (for all roles: passenger, rider, admin)
  // - POST /api/auth/sign-up (for passengers only)
  // - POST /api/auth/sign-out
  //
  // NOTE: Rider accounts CANNOT be created through signup.
  // Riders are created by Admin through the web dashboard only.

  // For Android Emulator, use: http://10.0.2.2:3000/api
  // For iOS Simulator, use: http://localhost:3000/api
  // For physical device, use your computer's IP: http://192.168.x.x:3000/api
  // For production, use: https://your-production-domain.com/api
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  final http.Client client;
  final SharedPreferences prefs;

  AuthRemoteDataSourceImpl({required this.client, required this.prefs});

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (useDemoMode) {
      return _demoSignIn(email: email, password: password);
    }

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
    if (useDemoMode) {
      return _demoSignUp(email: email, password: password, name: name);
    }

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
    if (useDemoMode) {
      // Clear local storage in demo mode
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('user_assigned_route');
      await prefs.remove('user_bus_name');
      await prefs.remove('demo_password');
      return;
    }

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

  // ============ DEMO MODE METHODS ============
  // These methods simulate backend responses for testing without a server

  Future<UserModel> _demoSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user already exists
    final existingEmail = prefs.getString('user_email');
    if (existingEmail == email) {
      throw Exception('Email already exists');
    }

    // Validate inputs
    if (!email.contains('@')) {
      throw Exception('Invalid email format');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (name.isEmpty) {
      throw Exception('Name is required');
    }

    // Create passenger user
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: UserRole.passenger, // Always passenger for signup
    );

    // Store user data locally
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_role', _roleToString(user.role));
    await prefs.setString('demo_password', password); // Store for demo login

    return user;
  }

  Future<UserModel> _demoSignIn({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Demo accounts for testing different roles
    final demoAccounts = {
      'passenger@test.com': {
        'password': 'password123',
        'name': 'Test Passenger',
        'role': UserRole.passenger,
      },
      'rider@test.com': {
        'password': 'password123',
        'name': 'Test Rider',
        'role': UserRole.rider,
        'busName': 'Bus 101',
        'assignedRoute': 'SM Cebu - Ayala Center',
      },
      'admin@test.com': {
        'password': 'password123',
        'name': 'Test Admin',
        'role': UserRole.admin,
      },
    };

    // Check demo accounts first
    if (demoAccounts.containsKey(email)) {
      final account = demoAccounts[email]!;
      if (account['password'] == password) {
        final user = UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: account['name'] as String,
          role: account['role'] as UserRole,
          busName: account['busName'] as String?,
          assignedRoute: account['assignedRoute'] as String?,
        );

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
      }
    }

    // Check if user created via signup
    final storedEmail = prefs.getString('user_email');
    final storedPassword = prefs.getString('demo_password');

    if (storedEmail == email && storedPassword == password) {
      // Return the stored user
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        return currentUser;
      }
    }

    // Invalid credentials
    throw Exception('Invalid email or password');
  }
}
