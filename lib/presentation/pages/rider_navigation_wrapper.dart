import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
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

  @override
  void initState() {
    super.initState();
    // Automatically start tracking when rider logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _riderTrackingBloc = context.read<RiderTrackingBloc>();
        _riderTrackingBloc?.add(StartTracking(widget.rider));
        debugPrint(
          '🚀 Auto-starting rider tracking on login for: ${widget.rider.name}',
        );
      }
    });
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
    final List<Widget> pages = [
      RiderDashboardPage(rider: widget.rider),
      RiderMapPage(rider: widget.rider),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
