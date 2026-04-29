import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/sign_in.dart';
import '../../../domain/usecases/sign_out.dart';
import '../../../domain/usecases/sign_up.dart';
import '../../../service/location_tracking_service.dart';
import '../../../data/datasources/api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final LocationTrackingService locationTrackingService;
  final ApiClient apiClient;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getCurrentUser,
    required this.locationTrackingService,
    required this.apiClient,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    _initializeApiToken();
  }

  /// Initialize API token from SharedPreferences on app start
  Future<void> _initializeApiToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        apiClient.setAuthToken(token);
        debugPrint('🔑 API token loaded from storage');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load API token: $e');
    }
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String?;
      switch (type) {
        case 'authenticated':
          final userData = json['user'] as Map<String, dynamic>?;
          if (userData != null) {
            return AuthAuthenticated(User.fromJson(userData));
          }
          return null;
        case 'unauthenticated':
          return AuthUnauthenticated();
        case 'loading':
          // Loading is transient and should never be restored from disk.
          return AuthInitial();
        case 'error':
          // Error is transient and should never be restored from disk.
          return AuthInitial();
        case 'initial':
        default:
          return AuthInitial();
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    try {
      if (state is AuthAuthenticated || state is AuthUnauthenticated) {
        return state.toJson();
      }

      // Do not persist transient states (initial/loading/error).
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await getCurrentUser();
    result.fold((failure) => emit(AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔐 AuthBloc: SignInRequested event received');
    emit(AuthLoading());
    debugPrint('🔄 AuthBloc: Emitted AuthLoading state');

    final result = await signIn(email: event.email, password: event.password);

    // Handle result without using fold to properly await token setting
    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null);
      if (failure != null) {
        debugPrint('❌ AuthBloc: Sign in failed - ${failure.message}');
        emit(AuthError(failure.message));
      }
    } else {
      final user = result.fold((l) => null, (r) => r);
      if (user != null) {
        debugPrint(
          '✅ AuthBloc: Sign in successful - ${user.email} (${user.role})',
        );

        // Set API token BEFORE emitting authenticated state
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          debugPrint('🔍 Checking for access token in SharedPreferences...');
          if (token != null) {
            debugPrint('✅ Token found: ${token.length} chars');
            apiClient.setAuthToken(token);
            debugPrint('🔑 API token set for user: ${user.email}');

            // Verify token was set
            final currentToken = apiClient.getCurrentToken();
            if (currentToken != null) {
              debugPrint('✅ Verified: Token is now set in ApiClient');
            } else {
              debugPrint(
                '❌ ERROR: Token not set in ApiClient despite calling setAuthToken!',
              );
            }
          } else {
            debugPrint(
              '❌ CRITICAL: No access token found in SharedPreferences after login!',
            );
            debugPrint('   Available keys: ${prefs.getKeys()}');
          }
        } catch (e) {
          debugPrint('❌ Failed to set API token: $e');
        }

        emit(AuthAuthenticated(user));
        debugPrint('✅ AuthBloc: Emitted AuthAuthenticated state');
      }
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signUp(
      email: event.email,
      password: event.password,
      name: event.name,
    );

    // Handle result without using fold to properly await token setting
    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null);
      if (failure != null) {
        emit(AuthError(failure.message));
      }
    } else {
      final user = result.fold((l) => null, (r) => r);
      if (user != null) {
        // Set API token BEFORE emitting authenticated state
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            apiClient.setAuthToken(token);
            debugPrint('🔑 API token set for new user: ${user.email}');
          }
        } catch (e) {
          debugPrint('❌ Failed to set API token: $e');
        }

        emit(AuthAuthenticated(user));
      }
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔓 AuthBloc: SignOutRequested - Stopping location tracking');

    // Stop location tracking before signing out
    if (locationTrackingService.isTracking) {
      locationTrackingService.stopTracking();
      debugPrint('✅ Location tracking stopped');
    }

    // Clear API token
    apiClient.clearAuthToken();
    debugPrint('🔑 API token cleared');

    emit(AuthLoading());
    final result = await signOut();
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      debugPrint('✅ Sign out successful');
      emit(AuthUnauthenticated());
    });
  }
}
