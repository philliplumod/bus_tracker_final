import 'package:bus_tracker/bloc/map_bloc.dart';
import 'package:bus_tracker/bloc/map_event.dart';
import 'package:bus_tracker/bloc/map_state.dart';
import 'package:bus_tracker/widgets/map_view.dart';
import 'package:bus_tracker/widgets/location_error.dart'; // ✅ Import LocationError widget
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  LatLng? selectedBusPosition;
  bool isSearchClicked = false;

  @override
  void initState() {
    super.initState();
    final mapBloc = context.read<MapBloc>();
    mapBloc.add(LoadUserLocation());
    mapBloc.add(SubscribeToBusUpdates());

    // Automatically load nearby buses after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isSearchClicked = true;
        });
        mapBloc.add(LoadNearbyBuses());
      }
    });
  }

  Widget _buildBusList(List<Map<String, dynamic>> buses) {
    if (!isSearchClicked) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Text(
          "There are no buses nearby. Click the bus button to find them.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children:
              buses.map((bus) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    title: Text(
                      "Bus: ${bus['id']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Lat: ${bus['latitude']?.toStringAsFixed(6)}, Lng: ${bus['longitude']?.toStringAsFixed(6)}\n"
                      "Speed: ${bus['speedDisplay'] ?? '${bus['speed']?.toStringAsFixed(1) ?? 'N/A'} km/h'}, Alt: ${bus['altitude']?.toStringAsFixed(1) ?? 'N/A'}m\n"
                      "ETA: ${bus['eta'] ?? 'Unknown'}, Distance: ${bus["distance"]}\n"
                      "Last Update: ${bus['timestamp'] ?? 'Unknown'}",
                      style: const TextStyle(height: 1.3, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedBusPosition = LatLng(
                            bus['latitude'],
                            bus['longitude'],
                          );
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracker'),
        actions: [
          // Real-time indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Live',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is MapLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MapError) {
                  return LocationError(
                    message: state.error,
                    code: "PERMISSION_DENIED",
                  ).buildErrorWidget(
                    context,
                    onRetry: () {
                      context.read<MapBloc>().add(LoadUserLocation());
                    },
                  );
                } else if (state is MapLoaded) {
                  return MapView(
                    nearbyBuses: state.nearbyBuses,
                    userPosition: state.position,
                    selectedBusPosition: selectedBusPosition,
                  );
                }
                return const Center(
                  child: Text('Waiting for user location...'),
                );
              },
            ),
          ),
          BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              if (state is MapLoaded) {
                return _buildBusList(state.nearbyBuses);
              }
              return Container();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isSearchClicked = true;
          });
          context.read<MapBloc>().add(LoadNearbyBuses());
        },
        child: const Icon(Icons.bus_alert_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
