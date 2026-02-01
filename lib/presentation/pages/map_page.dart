import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/bus.dart';
import '../../theme/theme_cubit.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_event.dart';
import '../bloc/map/map_state.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mapBloc = context.read<MapBloc>();
        mapBloc.add(LoadUserLocation());
        mapBloc.add(SubscribeToBusUpdates());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bus> _filterBuses(List<Bus> buses) {
    if (_searchQuery.isEmpty) {
      return buses;
    }
    return buses.where((bus) {
      final searchLower = _searchQuery.toLowerCase();
      final busNumber = bus.busNumber?.toLowerCase() ?? '';
      final busId = bus.id.toLowerCase();
      return busNumber.contains(searchLower) || busId.contains(searchLower);
    }).toList();
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

          // Bus list with search
          Expanded(
            child: Column(
              children: [
                // Compact search bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search bus number...',
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon:
                                  _searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
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
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Refresh buses',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bus list
                Expanded(
                  child: BlocBuilder<MapBloc, MapState>(
                    builder: (context, state) {
                      if (state is MapLoaded) {
                        final filteredBuses = _filterBuses(state.buses);

                        if (filteredBuses.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isSearching
                                        ? 'Searching...'
                                        : _searchQuery.isNotEmpty
                                        ? 'No buses match "$_searchQuery"'
                                        : 'No buses found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (!_isSearching && state.buses.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Tap refresh button to search',
                                        style: TextStyle(
                                          fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filteredBuses.length,
                          itemBuilder: (context, index) {
                            final bus = filteredBuses[index];
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
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
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
                            'Tap refresh button to search for buses',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
