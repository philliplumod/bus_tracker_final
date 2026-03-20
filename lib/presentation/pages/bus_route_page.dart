import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_state.dart';
import '../bloc/map/map_event.dart';

class BusRoutePage extends StatefulWidget {
  final Bus bus;

  const BusRoutePage({super.key, required this.bus});

  @override
  State<BusRoutePage> createState() => _BusRoutePageState();
}

class _BusRoutePageState extends State<BusRoutePage> {
  GoogleMapController? _mapController;

  Bus _getLiveBus(MapState state) {
    if (state is MapLoaded) {
      for (final bus in state.buses) {
        if (bus.id == widget.bus.id) {
          return bus;
        }
      }
    }
    return widget.bus;
  }

  String _buildArrivalStatus(Bus bus) {
    final distance = bus.distanceFromUser;
    if (distance == null) {
      return 'Arrival status unavailable';
    }

    if (distance <= AppConstants.arrivedBusThreshold) {
      return 'Arrived at your location';
    }
    if (distance <= AppConstants.nearbyBusThreshold) {
      return 'Bus is nearby';
    }
    return 'Bus is on the way';
  }

  @override
  void initState() {
    super.initState();
    // Ensure MapBloc has user location loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mapState = context.read<MapBloc>().state;
        if (mapState is! MapLoaded) {
          debugPrint('🗺️ BusRoutePage: Loading user location for map');
          context.read<MapBloc>().add(LoadUserLocation());
        }
        context.read<MapBloc>().add(SubscribeToBusUpdates());
      }
    });
  }

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
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          final liveBus = _getLiveBus(state);
          return Column(
            children: [
              // Bus info card
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                                  liveBus.busNumber != null
                                      ? 'Bus ${liveBus.busNumber}'
                                      : 'Bus ${liveBus.id}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (liveBus.route != null)
                                  Text(
                                    'Route: ${liveBus.route}',
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
                        '${liveBus.speed?.toStringAsFixed(1) ?? 'N/A'} km/h',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        '${liveBus.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${liveBus.longitude?.toStringAsFixed(6) ?? 'N/A'}',
                      ),
                      if (liveBus.distanceFromUser != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.social_distance,
                          'Distance',
                          '${liveBus.distanceFromUser!.toStringAsFixed(2)} km',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Passenger arrival ETA widget
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Arrival to your location',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              liveBus.eta ?? 'ETA unavailable',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _buildArrivalStatus(liveBus),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Map view
              Expanded(
                child:
                    state is MapLoaded &&
                            liveBus.latitude != null &&
                            liveBus.longitude != null
                        ? GoogleMap(
                          onMapCreated: (controller) {
                            if (mounted) {
                              _mapController = controller;
                            }
                          },
                          cloudMapId: 'ab6437d57e645dfdb9e48b8f',
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              liveBus.latitude!,
                              liveBus.longitude!,
                            ),
                            zoom: 15.0,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(liveBus.id),
                              position: LatLng(
                                liveBus.latitude!,
                                liveBus.longitude!,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                              infoWindow: InfoWindow(
                                title:
                                    liveBus.busNumber != null
                                        ? 'Bus ${liveBus.busNumber}'
                                        : 'Bus ${liveBus.id}',
                                snippet: liveBus.route ?? 'Route not specified',
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
                              infoWindow: const InfoWindow(
                                title: 'Your Location',
                              ),
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
                                LatLng(liveBus.latitude!, liveBus.longitude!),
                              ],
                              color: Theme.of(context).primaryColor,
                              width: 3,
                              patterns: [
                                PatternItem.dash(20),
                                PatternItem.gap(10),
                              ],
                            ),
                          },
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                          zoomControlsEnabled: true,
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Loading map...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          );
        },
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
