import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
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
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(busPosition, AppConstants.selectedBusZoom),
    );
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

    // User marker
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: widget.userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '📍 Your Location'),
      ),
    );

    // Only show selected bus marker
    if (widget.selectedBus != null &&
        widget.selectedBus!.latitude != null &&
        widget.selectedBus!.longitude != null) {
      final busPosition = LatLng(
        widget.selectedBus!.latitude!,
        widget.selectedBus!.longitude!,
      );
      final busLabel = widget.selectedBus!.busNumber ?? widget.selectedBus!.id;
      markers.add(
        Marker(
          markerId: MarkerId(widget.selectedBus!.id),
          position: busPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '🚌 Bus $busLabel',
            snippet:
                '${widget.selectedBus!.speed?.toStringAsFixed(1) ?? 'N/A'} km/h • ${widget.selectedBus!.eta ?? "N/A"}',
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                widget.userPosition,
                AppConstants.defaultZoom,
              ),
            );
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          initialCameraPosition: CameraPosition(
            target: widget.userPosition,
            zoom: AppConstants.defaultZoom,
          ),
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
        ),
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
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
