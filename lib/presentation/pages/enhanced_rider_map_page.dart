import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/route.dart';
import '../../core/utils/eta_service.dart';
import '../../domain/usecases/get_user_assigned_route.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_event.dart';
import '../bloc/map/map_state.dart';

class EnhancedRiderMapPage extends StatefulWidget {
  final User rider;
  final GetUserAssignedRoute getUserAssignedRoute;

  const EnhancedRiderMapPage({
    super.key,
    required this.rider,
    required this.getUserAssignedRoute,
  });

  @override
  State<EnhancedRiderMapPage> createState() => _EnhancedRiderMapPageState();
}

class _EnhancedRiderMapPageState extends State<EnhancedRiderMapPage> {
  GoogleMapController? _mapController;
  BusRoute? _assignedRoute;
  bool _isLoadingRoute = true;
  String? _routeError;
  double? _etaToDestination;
  double? _routeProgress;

  @override
  void initState() {
    super.initState();
    _loadAssignedRoute();
    context.read<MapBloc>().add(LoadUserLocation());
    context.read<MapBloc>().add(SubscribeToBusUpdates());
  }

  Future<void> _loadAssignedRoute() async {
    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    final result = await widget.getUserAssignedRoute(widget.rider.id);

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoadingRoute = false;
            _routeError = 'Failed to load route';
          });
        }
      },
      (route) {
        if (mounted) {
          setState(() {
            _assignedRoute = route;
            _isLoadingRoute = false;
          });
        }
      },
    );
  }

  void _updateETAAndProgress(double currentLat, double currentLng) {
    if (_assignedRoute == null) return;

    // Calculate ETA to destination terminal (currentSpeed not available)
    final eta = ETAService.calculateETAToTerminal(
      currentLat: currentLat,
      currentLng: currentLng,
      terminal: _assignedRoute!.destinationTerminal,
      route: _assignedRoute,
    );

    // Calculate route progress
    final progress = ETAService.calculateRouteProgress(
      currentLat: currentLat,
      currentLng: currentLng,
      route: _assignedRoute!,
    );

    setState(() {
      _etaToDestination = eta;
      _routeProgress = progress;
    });
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
    // Capture the AuthBloc reference before showing the dialog to avoid context issues
    final authBloc = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  authBloc.add(SignOutRequested());
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  Set<Marker> _buildMarkers(double currentLat, double currentLng) {
    final markers = <Marker>{
      // Rider's current location
      Marker(
        markerId: const MarkerId('rider_location'),
        position: LatLng(currentLat, currentLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: widget.rider.busName ?? 'Your Location',
          snippet: _assignedRoute?.name ?? 'Rider',
        ),
      ),
    };

    // Add terminal markers if route is loaded
    if (_assignedRoute != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('starting_terminal'),
          position: LatLng(
            _assignedRoute!.startingTerminal.latitude,
            _assignedRoute!.startingTerminal.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Start: ${_assignedRoute!.startingTerminal.name}',
            snippet: 'Starting Terminal',
          ),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('destination_terminal'),
          position: LatLng(
            _assignedRoute!.destinationTerminal.latitude,
            _assignedRoute!.destinationTerminal.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'End: ${_assignedRoute!.destinationTerminal.name}',
            snippet: 'Destination Terminal',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_assignedRoute == null) return {};

    // Draw a simple line between start and end terminals
    // In a real app, you would use the route_data from the database for the actual route polyline
    return {
      Polyline(
        polylineId: const PolylineId('route_line'),
        points: [
          LatLng(
            _assignedRoute!.startingTerminal.latitude,
            _assignedRoute!.startingTerminal.longitude,
          ),
          LatLng(
            _assignedRoute!.destinationTerminal.latitude,
            _assignedRoute!.destinationTerminal.longitude,
          ),
        ],
        color: Colors.blue,
        width: 5,
      ),
    };
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedRoute,
            tooltip: 'Refresh Route',
          ),
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
          } else if (state is MapLoaded) {
            // Update ETA and progress when location changes
            _updateETAAndProgress(
              state.userLocation.latitude,
              state.userLocation.longitude,
            );

            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(
                      state.userLocation.latitude,
                      state.userLocation.longitude,
                    ),
                    zoom: 14.0,
                  ),
                ),
              );
            }
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
              if (_isLoadingRoute)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading route information...'),
                    ],
                  ),
                )
              else if (_routeError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_routeError!)),
                    ],
                  ),
                )
              else if (_assignedRoute != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                    ),
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
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assigned Route',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _assignedRoute!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRouteDetailRow(
                        Icons.my_location,
                        'From',
                        _assignedRoute!.startingTerminal.name,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildRouteDetailRow(
                        Icons.location_on,
                        'To',
                        _assignedRoute!.destinationTerminal.name,
                        Colors.red,
                      ),
                      if (_assignedRoute!.distanceKm != null ||
                          _assignedRoute!.durationMinutes != null)
                        const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_assignedRoute!.distanceKm != null) ...[
                            Icon(
                              Icons.straighten,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _assignedRoute!.distanceText!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_assignedRoute!.durationMinutes != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _assignedRoute!.durationText!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_etaToDestination != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'ETA to destination: ${ETAService.formatETA(_etaToDestination!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_routeProgress != null) ...[
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Progress: ${_routeProgress!.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _routeProgress! / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  markers: _buildMarkers(
                    state.userLocation.latitude,
                    state.userLocation.longitude,
                  ),
                  polylines: _buildPolylines(),
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
                          Icons.gps_fixed,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lat: ${state.userLocation.latitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Lng: ${state.userLocation.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: ±${state.userLocation.accuracy.toStringAsFixed(1)}m',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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

  Widget _buildRouteDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
