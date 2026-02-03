import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_state.dart';
import '../../presentation/bloc/rider_tracking/rider_tracking_bloc.dart';
import '../../presentation/bloc/rider_tracking/rider_tracking_event.dart';

/// Widget that handles app lifecycle and refreshes data when app resumes
class LifecycleAwareWidget extends StatefulWidget {
  final Widget child;

  const LifecycleAwareWidget({super.key, required this.child});

  @override
  State<LifecycleAwareWidget> createState() => _LifecycleAwareWidgetState();
}

class _LifecycleAwareWidgetState extends State<LifecycleAwareWidget>
    with WidgetsBindingObserver {
  DateTime? _lastPausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _lastPausedTime = DateTime.now();
        debugPrint('App paused at ${_lastPausedTime}');
        break;

      case AppLifecycleState.resumed:
        if (_lastPausedTime != null) {
          final pauseDuration = DateTime.now().difference(_lastPausedTime!);
          debugPrint('App resumed after ${pauseDuration.inSeconds} seconds');

          // Only refresh if app was paused for more than 5 seconds
          if (pauseDuration.inSeconds > 5) {
            _refreshData();
          }
        } else {
          debugPrint('App resumed');
        }
        break;

      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;

      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;

      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  void _refreshData() {
    if (!mounted) return;

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      if (authState is AuthAuthenticated) {
        debugPrint('🔄 Refreshing data for ${authState.user.role}');

        if (authState.user.role == UserRole.rider) {
          // Restart tracking for riders
          final riderTrackingBloc = context.read<RiderTrackingBloc>();
          riderTrackingBloc.add(StartTracking(authState.user));
          debugPrint('✅ Restarted rider tracking');
        }
        // Add more refresh logic for passengers if needed
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
