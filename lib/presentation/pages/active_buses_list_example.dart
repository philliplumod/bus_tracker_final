import 'package:flutter/material.dart';
import '../../core/services/realtime_bus_tracking_service.dart';

/// Example widget showing how to use the realtime bus tracking service
/// in the passenger app to display active buses dynamically
class ActiveBusesListExample extends StatefulWidget {
  const ActiveBusesListExample({super.key});

  @override
  State<ActiveBusesListExample> createState() => _ActiveBusesListExampleState();
}

class _ActiveBusesListExampleState extends State<ActiveBusesListExample> {
  final _trackingService = RealtimeBusTrackingService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Buses'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by bus name or route...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ActiveBusInfo>>(
        stream:
            _searchQuery.isEmpty
                ? _trackingService.watchAllActiveBuses()
                : _trackingService.searchBusesByName(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active buses found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buses will appear here when riders start tracking',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final buses = snapshot.data!;

          return ListView.builder(
            itemCount: buses.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final bus = buses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        bus.speed > 0 ? Colors.green : Colors.orange,
                    child: Icon(
                      bus.speed > 0 ? Icons.directions_bus : Icons.bus_alert,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    bus.busName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(bus.routeDescription),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${bus.speed.toStringAsFixed(1)} km/h',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            bus.riderName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.red[400], size: 20),
                      const SizedBox(height: 4),
                      Text(
                        _formatLastUpdate(bus.lastUpdate),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to map view showing this bus
                    _showBusOnMap(context, bus);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  void _showBusOnMap(BuildContext context, ActiveBusInfo bus) {
    // TODO: Navigate to map page and show bus location
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(bus.busName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route: ${bus.routeName}'),
                const SizedBox(height: 8),
                Text('Location: ${bus.currentLat}, ${bus.currentLng}'),
                const SizedBox(height: 8),
                Text('Speed: ${bus.speed.toStringAsFixed(1)} km/h'),
                const SizedBox(height: 8),
                if (bus.startingTerminalName != null)
                  Text('From: ${bus.startingTerminalName}'),
                if (bus.destinationTerminalName != null)
                  Text('To: ${bus.destinationTerminalName}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to actual map view
                },
                child: const Text('View on Map'),
              ),
            ],
          ),
    );
  }
}
