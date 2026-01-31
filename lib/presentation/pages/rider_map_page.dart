import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_event.dart';
import '../bloc/map/map_state.dart';

class RiderMapPage extends StatefulWidget {
  final User rider;

  const RiderMapPage({super.key, required this.rider});

  @override
  State<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends State<RiderMapPage> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Load rider's current location
    context.read<MapBloc>().add(LoadUserLocation());
    context.read<MapBloc>().add(SubscribeToBusUpdates());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(SignOutRequested());
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rider Dashboard'),
            if (widget.rider.busName != null)
              Text(widget.rider.busName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MapLoaded && _mapController != null) {
            // Animate camera to rider's location
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    state.userLocation.latitude,
                    state.userLocation.longitude,
                  ),
                  zoom: 16.0,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MapLoading || state is MapInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading map',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<MapBloc>().add(LoadUserLocation());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is! MapLoaded) {
            return const Center(child: Text('Unknown state'));
          }

          return Column(
            children: [
              // Route Information Card
              if (widget.rider.assignedRoute != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.route,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Assigned Route',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.rider.assignedRoute!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Map
              Expanded(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      state.userLocation.latitude,
                      state.userLocation.longitude,
                    ),
                    zoom: 16.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('rider_location'),
                      position: LatLng(
                        state.userLocation.latitude,
                        state.userLocation.longitude,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                      infoWindow: InfoWindow(
                        title: widget.rider.busName ?? 'Your Location',
                        snippet: widget.rider.assignedRoute ?? 'Rider',
                      ),
                    ),
                  },
                ),
              ),
              // Location Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${state.userLocation.latitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      'Lng: ${state.userLocation.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      'Accuracy: ${state.userLocation.accuracy.toStringAsFixed(2)}m',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
