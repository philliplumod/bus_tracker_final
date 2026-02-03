import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/rider_tracking/rider_tracking_bloc.dart';
import '../bloc/rider_tracking/rider_tracking_event.dart';
import '../bloc/rider_tracking/rider_tracking_state.dart';
import 'rider_dashboard_page.dart';
import 'rider_map_page.dart';
import 'profile_page.dart';

class RiderNavigationWrapper extends StatefulWidget {
  final User rider;

  const RiderNavigationWrapper({super.key, required this.rider});

  @override
  State<RiderNavigationWrapper> createState() => _RiderNavigationWrapperState();
}

class _RiderNavigationWrapperState extends State<RiderNavigationWrapper> {
  int _currentIndex = 1; // Start with Map as the center/default tab
  RiderTrackingBloc? _riderTrackingBloc;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.rider;

    // Get BLoC reference immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeTracking();
      }
    });
  }

  void _initializeTracking() {
    if (!mounted) return;

    try {
      _riderTrackingBloc = context.read<RiderTrackingBloc>();
      final currentState = _riderTrackingBloc?.state;

      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 Initializing rider tracking');
      debugPrint('   Rider: ${widget.rider.name}');
      debugPrint('   User ID: ${widget.rider.id}');
      debugPrint('   Current BLoC state: ${currentState.runtimeType}');

      // Force tracking to start regardless of current state
      // The BLoC will handle stopping previous tracking if needed
      debugPrint('📤 Dispatching StartTracking event...');
      _riderTrackingBloc?.add(StartTracking(widget.rider));

      // Wait a frame and verify the event was received
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final newState = _riderTrackingBloc?.state;
          debugPrint('🔍 State after event dispatch: ${newState.runtimeType}');

          if (newState is RiderTrackingInitial) {
            debugPrint('⚠️ WARNING: State still Initial after event dispatch!');
            debugPrint('   This suggests the event was not processed.');
            debugPrint('   Attempting to dispatch again...');
            _riderTrackingBloc?.add(StartTracking(widget.rider));
          }
        }
      });

      debugPrint('✅ StartTracking event dispatched');
      debugPrint('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing tracking: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  @override
  void didUpdateWidget(RiderNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider != widget.rider) {
      debugPrint('👤 User profile updated in RiderNavigationWrapper');
      setState(() {
        _currentUser = widget.rider;
      });
    }
  }

  @override
  void dispose() {
    // Stop tracking when rider logs out or app closes
    _riderTrackingBloc?.add(const StopTracking());
    debugPrint('🛑 Stopping rider tracking on logout/dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only listen when transitioning to AuthAuthenticated with a different user
        if (current is AuthAuthenticated && previous is AuthAuthenticated) {
          return current.user.id != previous.user.id ||
              current.user.busId != previous.user.busId ||
              current.user.routeId != previous.user.routeId;
        }
        return current is AuthAuthenticated && previous is! AuthAuthenticated;
      },
      listener: (context, state) {
        if (state is AuthAuthenticated && state.user != _currentUser) {
          debugPrint('👤 Auth state updated with new user data');
          if (mounted) {
            setState(() {
              _currentUser = state.user;
            });
          }
        }
      },
      child: Builder(
        builder: (context) {
          // Use the current user from widget or updated state
          final currentRider = _currentUser ?? widget.rider;

          final List<Widget> pages = [
            RiderDashboardPage(rider: currentRider),
            RiderMapPage(rider: currentRider),
            const ProfilePage(),
          ];

          return Scaffold(
            body: IndexedStack(index: _currentIndex, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map, size: 30),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
