import 'package:bus_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  final List<Map<String, dynamic>> nearbyBuses;
  final LatLng? userPosition;
  final LatLng? selectedBusPosition;
  const MapView({
    super.key,
    required this.nearbyBuses,
    this.userPosition,
    this.selectedBusPosition,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _busMarkerIcon;
  BitmapDescriptor? _userMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    // Use default markers with custom colors
    _busMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
    _userMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBusPosition != null &&
        widget.selectedBusPosition != oldWidget.selectedBusPosition) {
      _moveCameraToBus(widget.selectedBusPosition!);
    }
  }

  void _moveCameraToBus(LatLng busPosition) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(busPosition, 16.0),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // Add user marker
    if (widget.userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user"),
          position: widget.userPosition!,
          icon:
              _userMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: "📍 Your Location",
            snippet: "You are here",
          ),
        ),
      );
    }

    // Add bus markers
    for (var bus in widget.nearbyBuses) {
      final busPosition = LatLng(bus["latitude"], bus["longitude"]);
      final isSelected = widget.selectedBusPosition == busPosition;

      markers.add(
        Marker(
          markerId: MarkerId(bus["id"]),
          position: busPosition,
          icon:
              _busMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                isSelected
                    ? BitmapDescriptor.hueOrange
                    : BitmapDescriptor.hueRed,
              ),
          infoWindow: InfoWindow(
            title: "🚌 Bus ${bus['id']}",
            snippet:
                "Speed: ${bus['speedDisplay'] ?? '${bus['speed']?.toStringAsFixed(1) ?? 'N/A'} km/h'}\n"
                "Distance: ${bus['distance'] ?? 'N/A'} • ETA: ${bus['eta'] ?? 'N/A'}",
          ),
          onTap: () {
            _mapController?.showMarkerInfoWindow(MarkerId(bus["id"]));
          },
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    Set<Circle> circles = {};

    // Add a circle around user location
    if (widget.userPosition != null) {
      circles.add(
        Circle(
          circleId: const CircleId("user_range"),
          center: widget.userPosition!,
          radius: 1000, // 1km radius
          fillColor: AppTheme.primaryColor.withOpacity(0.1),
          strokeColor: AppTheme.primaryColor.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    }

    // Add circles around selected bus
    if (widget.selectedBusPosition != null) {
      circles.add(
        Circle(
          circleId: const CircleId("selected_bus"),
          center: widget.selectedBusPosition!,
          radius: 300,
          fillColor: Colors.orange.withOpacity(0.2),
          strokeColor: Colors.orange.withOpacity(0.8),
          strokeWidth: 3,
        ),
      );
    }

    return circles;
  }

  Set<Polyline> _buildPolylines() {
    Set<Polyline> polylines = {};

    // Draw lines from user to each bus
    if (widget.userPosition != null) {
      for (var bus in widget.nearbyBuses) {
        final busPosition = LatLng(bus["latitude"], bus["longitude"]);

        polylines.add(
          Polyline(
            polylineId: PolylineId("line_${bus['id']}"),
            points: [widget.userPosition!, busPosition],
            color: AppTheme.primaryColor.withOpacity(0.4),
            width: 2,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            if (widget.userPosition != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(widget.userPosition!, 14.0),
              );
            }
            // Set custom map style (optional)
            _setMapStyle();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
          initialCameraPosition: CameraPosition(
            target: widget.userPosition ?? const LatLng(0.0, 0.0),
            zoom: 14.0,
          ),
          markers: _buildMarkers(),
          circles: _buildCircles(),
          polylines: _buildPolylines(),
        ),
        // Bus count badge
        if (widget.nearbyBuses.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.nearbyBuses.length} Bus${widget.nearbyBuses.length > 1 ? 'es' : ''}',
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

  void _setMapStyle() {
    // You can customize map style here
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark && _mapController != null) {
      _mapController!.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#242f3e"}]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#242f3e"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#746855"}]
          }
        ]
      ''');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
