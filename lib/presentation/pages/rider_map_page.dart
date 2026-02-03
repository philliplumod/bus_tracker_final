import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/utils/location_service.dart';
import '../../core/services/marker_animation_service.dart';
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
  String? _currentLocationAddress;
  String? _destinationLocationAddress;
  double? _distanceToDestination;
  int? _estimatedTravelTime;
  MarkerAnimationService? _markerAnimation;
  LatLng? _animatedMarkerPosition;
  double _markerRotation = 0;
  Set<Polyline> _polylines = {};
  bool _routeLoaded = false;

  RiderTrackingBloc? _riderTrackingBloc;

  @override
  void initState() {
    super.initState();

    // Debug: Check destination data
    debugPrint('🗺️ RiderMapPage initialized');
    debugPrint('   Rider: ${widget.rider.name}');
    debugPrint('   Destination: ${widget.rider.destinationTerminal}');
    debugPrint('   Dest Lat: ${widget.rider.destinationTerminalLat}');
    debugPrint('   Dest Lng: ${widget.rider.destinationTerminalLng}');

    // Load rider's current location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _riderTrackingBloc = context.read<RiderTrackingBloc>();
        _riderTrackingBloc?.add(StartTracking(widget.rider));
        context.read<MapBloc>().add(LoadUserLocation());
        context.read<MapBloc>().add(SubscribeToBusUpdates());
        _loadLocationDetails();
      }
    });
  }

  @override
  void dispose() {
    // Use saved reference to avoid unsafe context access during disposal
    _riderTrackingBloc?.add(const StopTracking());
    _mapController?.dispose();
    _markerAnimation?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _loadLocationDetails() async {
    final mapState = context.read<MapBloc>().state;
    if (mapState is MapLoaded) {
      _updateLocationDetails(
        mapState.userLocation.latitude,
        mapState.userLocation.longitude,
      );
    }
  }

  Future<void> _updateLocationDetails(double lat, double lon) async {
    try {
      // Get current location address
      final address = await LocationService.getAddressFromCoordinates(lat, lon);

      // Calculate distance to destination if available
      double? distance;
      int? travelTime;
      String? destAddress;

      if (widget.rider.destinationTerminalLat != null &&
          widget.rider.destinationTerminalLng != null) {
        debugPrint('📍 Calculating distance to destination...');
        distance = LocationService.calculateDistance(
          lat,
          lon,
          widget.rider.destinationTerminalLat!,
          widget.rider.destinationTerminalLng!,
        );
        travelTime = LocationService.estimateTravelTime(distance);
        debugPrint('   Distance: ${distance.toStringAsFixed(2)} km');
        debugPrint('   ETA: $travelTime minutes');

        // Get destination address if not already set
        if (widget.rider.destinationTerminal != null) {
          destAddress = widget.rider.destinationTerminal;
        } else {
          destAddress = await LocationService.getAddressFromCoordinates(
            widget.rider.destinationTerminalLat!,
            widget.rider.destinationTerminalLng!,
          );
        }

        // Load route polyline if not already loaded
        if (!_routeLoaded && widget.rider.destinationTerminalLat != null) {
          debugPrint('🛣️ Loading route polyline...');
          _loadRoutePolyline(lat, lon);
        }
      } else {
        debugPrint('⚠️ Destination coordinates not available');
        debugPrint(
          '   destinationTerminalLat: ${widget.rider.destinationTerminalLat}',
        );
        debugPrint(
          '   destinationTerminalLng: ${widget.rider.destinationTerminalLng}',
        );
      }

      if (mounted) {
        setState(() {
          _currentLocationAddress = address;
          _distanceToDestination = distance;
          _estimatedTravelTime = travelTime;
          _destinationLocationAddress = destAddress;
        });

        // Update animated marker position
        if (_markerAnimation != null) {
          _markerAnimation!.updatePosition(LatLng(lat, lon));
        }
      }
    } catch (e) {
      debugPrint('Error updating location details: $e');
    }
  }

  /// Load route polyline from current location to destination
  Future<void> _loadRoutePolyline(double lat, double lon) async {
    if (widget.rider.destinationTerminalLat == null ||
        widget.rider.destinationTerminalLng == null) {
      debugPrint('❌ Cannot load route: destination coordinates missing');
      return;
    }

    final origin = LatLng(lat, lon);
    final destination = LatLng(
      widget.rider.destinationTerminalLat!,
      widget.rider.destinationTerminalLng!,
    );

    debugPrint('🗺️ Requesting route from MapBloc');
    debugPrint('   Origin: ${origin.latitude}, ${origin.longitude}');
    debugPrint(
      '   Destination: ${destination.latitude}, ${destination.longitude}',
    );

    // Request route from MapBloc
    context.read<MapBloc>().add(
      LoadRoute(origin: origin, destination: destination),
    );

    _routeLoaded = true;
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
            // Update location details when location changes
            _updateLocationDetails(
              state.userLocation.latitude,
              state.userLocation.longitude,
            );

            // Update polyline if route data available
            if (state.routeData != null && _polylines.isEmpty) {
              debugPrint('📍 Route data received from MapBloc');
              debugPrint(
                '   Polyline points: ${state.routeData!.polylinePoints.length}',
              );
              _updatePolyline(state.routeData!.polylinePoints);

              // Initialize marker animation
              if (_markerAnimation == null) {
                _markerAnimation = MarkerAnimationService(
                  routePoints: state.routeData!.polylinePoints,
                  onPositionUpdate: (position, bearing) {
                    if (mounted) {
                      setState(() {
                        _animatedMarkerPosition = position;
                        _markerRotation = bearing;
                      });
                    }
                  },
                );

                // Set initial position
                _markerAnimation!.updatePosition(
                  LatLng(
                    state.userLocation.latitude,
                    state.userLocation.longitude,
                  ),
                );
              }
            } else if (state.routeData == null) {
              debugPrint('⚠️ No route data in MapLoaded state');
            } else if (_polylines.isNotEmpty) {
              debugPrint('ℹ️ Polyline already loaded');
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
              // Tracking Status Card
              BlocBuilder<RiderTrackingBloc, RiderTrackingState>(
                builder: (context, trackingState) {
                  return _buildTrackingStatusCard(trackingState);
                },
              ),

              // Route & Assignment Information Card
              if (widget.rider.assignedRoute != null ||
                  widget.rider.busName != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.15),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.rider.busName != null) ...[
                        Icon(
                          Icons.directions_bus,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.rider.busName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (widget.rider.busName != null &&
                          widget.rider.assignedRoute != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 1,
                            height: 20,
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      if (widget.rider.assignedRoute != null) ...[
                        Icon(
                          Icons.route,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.rider.assignedRoute!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          state.userLocation.latitude,
                          state.userLocation.longitude,
                        ),
                        zoom: 16.0,
                      ),
                      myLocationEnabled: false, // Use custom marker instead
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      markers: _buildMarkers(state),
                      polylines: _polylines,
                    ),
                    // Route loading indicator
                    if (state.isLoadingRoute)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading route...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Enhanced Location Information Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Current Location Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Current Location',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_currentLocationAddress != null)
                            Text(
                              _currentLocationAddress!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            )
                          else
                            Text(
                              '${state.userLocation.latitude.toStringAsFixed(6)}, ${state.userLocation.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Accuracy: ±${state.userLocation.accuracy.toStringAsFixed(0)}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Destination Section
                    if (_destinationLocationAddress != null &&
                        _distanceToDestination != null) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Destination Terminal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _destinationLocationAddress!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.straighten,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Distance',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          LocationService.formatDistance(
                                            _distanceToDestination!,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_estimatedTravelTime != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.purple.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.purple,
                                            size: 18,
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Est. Time',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            LocationService.formatTravelTime(
                                              _estimatedTravelTime!,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Update polyline with route points
  void _updatePolyline(List<LatLng> points) {
    debugPrint('🛣️ Updating polyline with ${points.length} points');
    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.red,
            width: 5,
            geodesic: true,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      });
      debugPrint('✅ Polyline updated successfully');
    }
  }

  Set<Marker> _buildMarkers(MapLoaded state) {
    debugPrint('📍 Building markers...');
    final markers = <Marker>{
      // Current location marker (animated)
      Marker(
        markerId: const MarkerId('rider_location'),
        position:
            _animatedMarkerPosition ??
            LatLng(state.userLocation.latitude, state.userLocation.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: _markerRotation,
        anchor: const Offset(0.5, 0.5),
        flat: true, // Enable rotation
        infoWindow: InfoWindow(
          title: widget.rider.busName ?? 'Your Location',
          snippet: _currentLocationAddress ?? 'Current Position',
        ),
      ),
    };
    debugPrint('   ✅ Added rider location marker');

    // Add destination marker if available
    if (widget.rider.destinationTerminalLat != null &&
        widget.rider.destinationTerminalLng != null) {
      debugPrint(
        '   🏁 Adding destination marker at (${widget.rider.destinationTerminalLat}, ${widget.rider.destinationTerminalLng})',
      );
      markers.add(
        Marker(
          markerId: const MarkerId('destination_terminal'),
          position: LatLng(
            widget.rider.destinationTerminalLat!,
            widget.rider.destinationTerminalLng!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.rider.destinationTerminal ?? 'Terminal',
          ),
        ),
      );
      debugPrint('   ✅ Added destination marker');
    } else {
      debugPrint('   ⚠️ No destination terminal coordinates available');
    }

    debugPrint('🎯 Total markers: ${markers.length}');
    return markers;
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
