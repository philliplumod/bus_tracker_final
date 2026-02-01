import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'enter_bus_number_page.dart';
import 'trip_solution_page.dart';

class PassengerNavigationWrapper extends StatefulWidget {
  const PassengerNavigationWrapper({super.key});

  @override
  State<PassengerNavigationWrapper> createState() =>
      _PassengerNavigationWrapperState();
}

class _PassengerNavigationWrapperState
    extends State<PassengerNavigationWrapper> {
  int _currentIndex = 1; // Start with Bus Search as the center/default tab

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = const [
      ProfilePage(),
      EnterBusNumberPage(),
      TripSolutionPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 30),
            label: 'Bus Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Trip Solution',
          ),
        ],
      ),
    );
  }
}
