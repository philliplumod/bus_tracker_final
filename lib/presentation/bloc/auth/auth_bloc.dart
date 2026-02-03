import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/sign_in.dart';
import '../../../domain/usecases/sign_out.dart';
import '../../../domain/usecases/sign_up.dart';
import '../../../service/location_tracking_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final LocationTrackingService locationTrackingService;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getCurrentUser,
    required this.locationTrackingService,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
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
          return AuthLoading();
        case 'error':
          return AuthError(json['message'] as String? ?? 'Unknown error');
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
      return state.toJson();
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
    result.fold(
      (failure) {
        debugPrint('❌ AuthBloc: Sign in failed - ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint(
          '✅ AuthBloc: Sign in successful - ${user.email} (${user.role})',
        );
        emit(AuthAuthenticated(user));
        debugPrint('✅ AuthBloc: Emitted AuthAuthenticated state');
      },
    );
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
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
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

    emit(AuthLoading());
    final result = await signOut();
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      debugPrint('✅ Sign out successful');
      emit(AuthUnauthenticated());
    });
  }
}
