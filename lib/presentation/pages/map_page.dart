import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/bus.dart';
import '../../theme/theme_cubit.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/bus_list_item.dart';
import '../widgets/compact_map_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Bus? _selectedBus;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final mapBloc = context.read<MapBloc>();
    mapBloc.add(LoadUserLocation());
    mapBloc.add(SubscribeToBusUpdates());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, size: 24),
            SizedBox(width: 8),
            Text('Bus Tracker'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact map view
          SizedBox(
            height: AppConstants.mapHeight,
            child: BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is MapLoading && !_isSearching) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (state is MapError) {
                  return Container(
                    color: Colors.red[50],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 48, color: Colors.red[700]),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<MapBloc>().add(LoadUserLocation());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is MapLoaded) {
                  return CompactMapView(
                    selectedBus: _selectedBus,
                    userPosition: LatLng(
                      state.userLocation.latitude,
                      state.userLocation.longitude,
                    ),
                  );
                }
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Initializing...')),
                );
              },
            ),
          ),

          // Bus list
          Expanded(
            child: BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is MapLoaded) {
                  if (state.buses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching ? 'Searching...' : 'No buses found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (!_isSearching)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Tap search button below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: state.buses.length,
                    itemBuilder: (context, index) {
                      final bus = state.buses[index];
                      return BusListItem(
                        bus: bus,
                        onTap: () {
                          setState(() {
                            _selectedBus = bus;
                          });
                        },
                      );
                    },
                  );
                }

                if (_isSearching) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Searching for buses...'),
                        ],
                      ),
                    ),
                  );
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Tap search button below',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
          context.read<MapBloc>().add(LoadNearbyBuses());

          // Reset searching state after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isSearching = false;
              });
            }
          });
        },
        child: const Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
