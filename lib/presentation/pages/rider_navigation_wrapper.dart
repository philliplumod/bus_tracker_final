import 'package:bus_tracker/presentation/bloc/rider_tracking/rider_tracking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/rider_tracking/rider_tracking_bloc.dart';
import '../bloc/rider_tracking/rider_tracking_event.dart';
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
    // Automatically start tracking when rider logs in
    // Use both immediate and post-frame callback to ensure it triggers
    _startTrackingImmediately();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startTrackingImmediately();
      }
    });
  }

  void _startTrackingImmediately() {
    if (!mounted) return;

    _riderTrackingBloc = context.read<RiderTrackingBloc>();

    // Check if already tracking to avoid duplicate starts
    if (_riderTrackingBloc?.state is! RiderTrackingActive) {
      _riderTrackingBloc?.add(StartTracking(widget.rider));
      debugPrint(
        '🚀 Auto-starting rider tracking on login for: ${widget.rider.name}',
      );
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
