import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/location_service.dart';
import '../../domain/entities/bus.dart';
import '../../theme/app_theme.dart';

class CompactMapView extends StatefulWidget {
  final Bus? selectedBus;
  final LatLng userPosition;

  const CompactMapView({
    super.key,
    this.selectedBus,
    required this.userPosition,
  });

  @override
  State<CompactMapView> createState() => _CompactMapViewState();
}

class _CompactMapViewState extends State<CompactMapView> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _passengerIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    // Create custom markers with different colors
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/bus_marker.png',
    ).catchError((_) {
      // Fallback to default marker if custom asset doesn't exist
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    });

    _passengerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/passenger_marker.png',
    ).catchError((_) {
      // Fallback to default marker if custom asset doesn't exist
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(CompactMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBus != null &&
        widget.selectedBus != oldWidget.selectedBus &&
        widget.selectedBus!.latitude != null &&
        widget.selectedBus!.longitude != null) {
      final busPosition = LatLng(
        widget.selectedBus!.latitude!,
        widget.selectedBus!.longitude!,
      );
      _moveCameraToBus(busPosition);
    }
  }

  void _moveCameraToBus(LatLng busPosition) {
    if (mounted && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(busPosition, AppConstants.selectedBusZoom),
      );
    }
  }

  Set<Polyline> _buildPolylines() {
    Set<Polyline> polylines = {};

    // Show path to selected bus
    if (widget.selectedBus != null &&
        widget.selectedBus!.latitude != null &&
        widget.selectedBus!.longitude != null) {
      final busPosition = LatLng(
        widget.selectedBus!.latitude!,
        widget.selectedBus!.longitude!,
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_bus'),
          points: [widget.userPosition, busPosition],
          color: AppTheme.accentColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return polylines;
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // Passenger/User marker with custom icon and detailed info
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: widget.userPosition,
        icon:
            _passengerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: '📍 Your Location',
          snippet: 'Waiting for bus',
        ),
        anchor: const Offset(0.5, 0.5),
      ),
    );

    // Bus marker with ETA and detailed information
    if (widget.selectedBus != null &&
        widget.selectedBus!.latitude != null &&
        widget.selectedBus!.longitude != null) {
      final busPosition = LatLng(
        widget.selectedBus!.latitude!,
        widget.selectedBus!.longitude!,
      );
      final busLabel = widget.selectedBus!.busNumber ?? widget.selectedBus!.id;

      // Calculate ETA
      final eta = LocationService.calculateETA(
        userLat: widget.userPosition.latitude,
        userLon: widget.userPosition.longitude,
        busLat: widget.selectedBus!.latitude!,
        busLon: widget.selectedBus!.longitude!,
        busSpeed: widget.selectedBus!.speed,
      );

      // Calculate distance
      final distance = LocationService.calculateDistance(
        widget.userPosition.latitude,
        widget.userPosition.longitude,
        widget.selectedBus!.latitude!,
        widget.selectedBus!.longitude!,
      );

      final formattedDistance = LocationService.formatDistance(distance);
      final speed = widget.selectedBus!.speed?.toStringAsFixed(1) ?? 'N/A';

      markers.add(
        Marker(
          markerId: MarkerId(widget.selectedBus!.id),
          position: busPosition,
          icon:
              _busIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '🚌 Bus $busLabel',
            snippet: 'ETA: $eta • $formattedDistance away • $speed km/h',
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate ETA and distance for display
    String? eta;
    String? distance;

    if (widget.selectedBus != null &&
        widget.selectedBus!.latitude != null &&
        widget.selectedBus!.longitude != null) {
      eta = LocationService.calculateETA(
        userLat: widget.userPosition.latitude,
        userLon: widget.userPosition.longitude,
        busLat: widget.selectedBus!.latitude!,
        busLon: widget.selectedBus!.longitude!,
        busSpeed: widget.selectedBus!.speed,
      );

      final distanceKm = LocationService.calculateDistance(
        widget.userPosition.latitude,
        widget.userPosition.longitude,
        widget.selectedBus!.latitude!,
        widget.selectedBus!.longitude!,
      );
      distance = LocationService.formatDistance(distanceKm);
    }

    return Stack(
      children: [
        GoogleMap(
          cloudMapId: 'ab6437d57e645dfdb9e48b8f',
          liteModeEnabled: true,
          onMapCreated: (controller) {
            if (mounted) {
              _mapController = controller;
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  widget.userPosition,
                  AppConstants.defaultZoom,
                ),
              );
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
          initialCameraPosition: CameraPosition(
            target: widget.userPosition,
            zoom: AppConstants.defaultZoom,
          ),
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
        ),
        // Bus info badge at top
        if (widget.selectedBus != null)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bus ${widget.selectedBus!.busNumber ?? widget.selectedBus!.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // ETA Display Card at bottom
        if (widget.selectedBus != null && eta != null && distance != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // ETA Section
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eta,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ETA',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  // Distance Section
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.route,
                          color: AppTheme.accentColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Distance',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  // Speed Section
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, color: Colors.green, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.selectedBus!.speed?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'km/h',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
