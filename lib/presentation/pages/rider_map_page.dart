import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/user.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_event.dart';
import '../bloc/map/map_state.dart';
import '../bloc/rider_tracking/rider_tracking_bloc.dart';
import '../bloc/rider_tracking/rider_tracking_event.dart';
import '../bloc/rider_tracking/rider_tracking_state.dart';
import '../../core/utils/eta_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RiderTrackingBloc>().add(StartTracking(widget.rider));
        context.read<MapBloc>().add(LoadUserLocation());
        context.read<MapBloc>().add(SubscribeToBusUpdates());
      }
    });
  }

  @override
  void dispose() {
    context.read<RiderTrackingBloc>().add(const StopTracking());
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Tracking'),
            if (widget.rider.busName != null)
              Text(widget.rider.busName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        automaticallyImplyLeading: false,
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
              // Tracking Status Card
              BlocBuilder<RiderTrackingBloc, RiderTrackingState>(
                builder: (context, trackingState) {
                  return _buildTrackingStatusCard(trackingState);
                },
              ),
              // Route Information Card
              if (widget.rider.assignedRoute != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Route:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.rider.assignedRoute!,
                        style: const TextStyle(
                          fontSize: 14,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${state.userLocation.latitude.toStringAsFixed(4)}, ${state.userLocation.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '±${state.userLocation.accuracy.toStringAsFixed(0)}m',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _buildTrackingStatusCard(RiderTrackingState trackingState) {
    if (trackingState is RiderTrackingActive) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Tracking Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  _formatTime(trackingState.lastUpdate),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.speed,
                  'Speed',
                  '${trackingState.speed.toStringAsFixed(1)} km/h',
                ),
                _buildInfoItem(
                  Icons.explore,
                  'Heading',
                  '${trackingState.heading.toStringAsFixed(0)}° ${_getDirectionName(trackingState.heading)}',
                ),
                if (trackingState.estimatedDurationMinutes != null)
                  _buildInfoItem(
                    Icons.access_time,
                    'ETA',
                    ETAService.formatETA(
                      trackingState.estimatedDurationMinutes!,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    if (trackingState is RiderTrackingError) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                trackingState.message,
                style: TextStyle(color: Colors.red[900], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  String _getDirectionName(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return '';
  }
}
