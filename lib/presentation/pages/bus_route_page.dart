import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_state.dart';

class BusRoutePage extends StatefulWidget {
  final Bus bus;

  const BusRoutePage({super.key, required this.bus});

  @override
  State<BusRoutePage> createState() => _BusRoutePageState();
}

class _BusRoutePageState extends State<BusRoutePage> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bus.busNumber != null
              ? 'Bus ${widget.bus.busNumber}'
              : 'Bus ${widget.bus.id}',
        ),
      ),
      body: Column(
        children: [
          // Bus info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bus.busNumber != null
                                  ? 'Bus ${widget.bus.busNumber}'
                                  : 'Bus ${widget.bus.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.bus.route != null)
                              Text(
                                'Route: ${widget.bus.route}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.speed,
                    'Speed',
                    '${widget.bus.speed.toStringAsFixed(1)} km/h',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    '${widget.bus.latitude.toStringAsFixed(6)}, ${widget.bus.longitude.toStringAsFixed(6)}',
                  ),
                  if (widget.bus.distanceFromUser != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.social_distance,
                      'Distance',
                      '${widget.bus.distanceFromUser!.toStringAsFixed(2)} km',
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Map view
          Expanded(
            child: BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is MapLoaded) {
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.bus.latitude, widget.bus.longitude),
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(widget.bus.id),
                        position: LatLng(
                          widget.bus.latitude,
                          widget.bus.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                        infoWindow: InfoWindow(
                          title:
                              widget.bus.busNumber != null
                                  ? 'Bus ${widget.bus.busNumber}'
                                  : 'Bus ${widget.bus.id}',
                          snippet: widget.bus.route ?? 'Route not specified',
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('user'),
                        position: LatLng(
                          state.userLocation.latitude,
                          state.userLocation.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                        infoWindow: const InfoWindow(title: 'Your Location'),
                      ),
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: [
                          LatLng(
                            state.userLocation.latitude,
                            state.userLocation.longitude,
                          ),
                          LatLng(widget.bus.latitude, widget.bus.longitude),
                        ],
                        color: Theme.of(context).primaryColor,
                        width: 3,
                        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                      ),
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
