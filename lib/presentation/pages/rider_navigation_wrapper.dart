import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
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
