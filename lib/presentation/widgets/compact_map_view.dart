import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/directions_service.dart';
import '../../domain/entities/bus.dart';
import '../../theme/app_theme.dart';

class CompactMapView extends StatefulWidget {
  final List<Bus> buses;
  final LatLng userPosition;
  final LatLng? selectedBusPosition;

  const CompactMapView({
    super.key,
    required this.buses,
    required this.userPosition,
    this.selectedBusPosition,
  });

  @override
  State<CompactMapView> createState() => _CompactMapViewState();
}

class _CompactMapViewState extends State<CompactMapView> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(CompactMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBusPosition != null &&
        widget.selectedBusPosition != oldWidget.selectedBusPosition) {
      _moveCameraToBus(widget.selectedBusPosition!);
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
    if (widget.selectedBusPosition != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_bus'),
          points: [widget.userPosition, widget.selectedBusPosition!],
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

    // Bus markers
    for (var bus in widget.buses) {
      final busPosition = LatLng(bus.latitude, bus.longitude);
      final isSelected = widget.selectedBusPosition == busPosition;

      markers.add(
        Marker(
          markerId: MarkerId(bus.id),
          position: busPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: '🚌 Bus ${bus.id}',
            snippet:
                '${bus.speed.toStringAsFixed(1)} km/h • ${bus.eta ?? "N/A"}',
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
        if (widget.buses.isNotEmpty)
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
                    '${widget.buses.length}',
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
