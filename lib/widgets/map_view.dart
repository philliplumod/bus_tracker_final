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

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        if (widget.userPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(widget.userPosition!, 14.0),
          );
        }
      },
      myLocationEnabled: true,
      initialCameraPosition: CameraPosition(
        target: widget.userPosition ?? const LatLng(0.0, 0.0),
        zoom: 14.0,
      ),
      markers: {
        if (widget.userPosition != null)
          Marker(
            markerId: const MarkerId("user"),
            position: widget.userPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: "You"),
          ),
        for (var bus in widget.nearbyBuses)
          Marker(
            markerId: MarkerId(bus["id"]),
            position: LatLng(bus["latitude"], bus["longitude"]),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: "Bus ${bus['id']}",
              snippet:
                  "Speed: ${bus['speedDisplay'] ?? '${bus['speed']?.toStringAsFixed(1) ?? 'N/A'} km/h'}\n"
                  "Distance: ${bus['distance'] ?? 'N/A'}\n"
                  "ETA: ${bus['eta'] ?? 'N/A'}",
            ),
          ),
      },
    );
  }
}
