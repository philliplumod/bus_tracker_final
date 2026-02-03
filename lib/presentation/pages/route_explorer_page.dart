import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/bus.dart';
import '../../domain/usecases/get_all_routes.dart';
import '../../domain/usecases/get_nearby_buses.dart';

class RouteExplorerPage extends StatefulWidget {
  final GetAllRoutes getAllRoutes;
  final GetNearbyBuses getNearbyBuses;

  const RouteExplorerPage({
    super.key,
    required this.getAllRoutes,
    required this.getNearbyBuses,
  });

  @override
  State<RouteExplorerPage> createState() => _RouteExplorerPageState();
}

class _RouteExplorerPageState extends State<RouteExplorerPage> {
  List<BusRoute> _routes = [];
  List<Bus> _buses = [];
  bool _isLoadingRoutes = true;
  bool _isLoadingBuses = true;
  String? _error;
  BusRoute? _selectedRoute;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadBuses();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
      _error = null;
    });

    final result = await widget.getAllRoutes();

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoadingRoutes = false;
            _error = 'Failed to load routes';
          });
        }
      },
      (routes) {
        if (mounted) {
          setState(() {
            _routes = routes;
            _isLoadingRoutes = false;
          });
        }
      },
    );
  }

  Future<void> _loadBuses() async {
    setState(() {
      _isLoadingBuses = true;
    });

    final result = await widget.getNearbyBuses();

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoadingBuses = false;
          });
        }
      },
      (buses) {
        if (mounted) {
          setState(() {
            _buses = buses;
            _isLoadingBuses = false;
          });
        }
      },
    );
  }

  List<Bus> _getBusesOnRoute(BusRoute route) {
    // Filter buses that are on this route
    return _buses.where((bus) => bus.route == route.name).toList();
  }

  void _selectRoute(BusRoute route) {
    setState(() {
      _selectedRoute = route;
    });

    // Animate camera to show the route
    if (_mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          route.startingTerminal.latitude < route.destinationTerminal.latitude
              ? route.startingTerminal.latitude
              : route.destinationTerminal.latitude,
          route.startingTerminal.longitude < route.destinationTerminal.longitude
              ? route.startingTerminal.longitude
              : route.destinationTerminal.longitude,
        ),
        northeast: LatLng(
          route.startingTerminal.latitude > route.destinationTerminal.latitude
              ? route.startingTerminal.latitude
              : route.destinationTerminal.latitude,
          route.startingTerminal.longitude > route.destinationTerminal.longitude
              ? route.startingTerminal.longitude
              : route.destinationTerminal.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_selectedRoute != null) {
      // Add terminal markers
      markers.add(
        Marker(
          markerId: const MarkerId('start_terminal'),
          position: LatLng(
            _selectedRoute!.startingTerminal.latitude,
            _selectedRoute!.startingTerminal.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: _selectedRoute!.startingTerminal.name,
            snippet: 'Starting Terminal',
          ),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('end_terminal'),
          position: LatLng(
            _selectedRoute!.destinationTerminal.latitude,
            _selectedRoute!.destinationTerminal.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: _selectedRoute!.destinationTerminal.name,
            snippet: 'Destination Terminal',
          ),
        ),
      );

      // Add buses on this route
      final busesOnRoute = _getBusesOnRoute(_selectedRoute!);
      for (var bus in busesOnRoute.where(
        (b) => b.latitude != null && b.longitude != null && b.speed != null,
      )) {
        markers.add(
          Marker(
            markerId: MarkerId('bus_${bus.id}'),
            position: LatLng(bus.latitude!, bus.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: bus.busNumber ?? 'Bus ${bus.id}',
              snippet: 'Speed: ${(bus.speed! * 3.6).toStringAsFixed(1)} km/h',
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_selectedRoute == null) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route_line'),
        points: [
          LatLng(
            _selectedRoute!.startingTerminal.latitude,
            _selectedRoute!.startingTerminal.longitude,
          ),
          LatLng(
            _selectedRoute!.destinationTerminal.latitude,
            _selectedRoute!.destinationTerminal.longitude,
          ),
        ],
        color: Theme.of(context).primaryColor,
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRoutes();
              _loadBuses();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 2,
            child:
                _selectedRoute == null
                    ? Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Select a route to view on map',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : GoogleMap(
                      cloudMapId: 'ab6437d57e645dfdb9e48b8f',
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _selectedRoute!.startingTerminal.latitude,
                          _selectedRoute!.startingTerminal.longitude,
                        ),
                        zoom: 12.0,
                      ),
                      markers: _buildMarkers(),
                      polylines: _buildPolylines(),
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                    ),
          ),
          // Selected Route Info
          if (_selectedRoute != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedRoute!.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedRoute = null;
                          });
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.trip_origin,
                    _selectedRoute!.startingTerminal.name,
                    Colors.green,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.location_on,
                    _selectedRoute!.destinationTerminal.name,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_selectedRoute!.distanceKm != null) ...[
                        const Icon(Icons.straighten, size: 16),
                        const SizedBox(width: 4),
                        Text(_selectedRoute!.distanceText!),
                        const SizedBox(width: 16),
                      ],
                      if (_selectedRoute!.durationMinutes != null) ...[
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(_selectedRoute!.durationText!),
                        const SizedBox(width: 16),
                      ],
                      const Icon(Icons.directions_bus, size: 16),
                      const SizedBox(width: 4),
                      Text('${_getBusesOnRoute(_selectedRoute!).length} buses'),
                    ],
                  ),
                ],
              ),
            ),
          // Routes List
          Expanded(
            flex: 1,
            child:
                _isLoadingRoutes
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 8),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadRoutes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _routes.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No routes available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _routes.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        final busesOnRoute = _getBusesOnRoute(route);
                        final isSelected = _selectedRoute == route;

                        return Card(
                          elevation: isSelected ? 4 : 1,
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                busesOnRoute.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              route.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${route.startingTerminal.name} → ${route.destinationTerminal.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (route.distanceKm != null)
                                  Text(
                                    route.distanceText!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.chevron_right,
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : null,
                                ),
                              ],
                            ),
                            onTap: () => _selectRoute(route),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
