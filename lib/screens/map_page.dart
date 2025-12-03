import 'package:bus_tracker/bloc/map_bloc.dart';
import 'package:bus_tracker/bloc/map_event.dart';
import 'package:bus_tracker/bloc/map_state.dart';
import 'package:bus_tracker/theme/app_theme.dart';
import 'package:bus_tracker/theme/theme_cubit.dart';
import 'package:bus_tracker/widgets/map_view.dart';
import 'package:bus_tracker/widgets/location_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> with TickerProviderStateMixin {
  LatLng? selectedBusPosition;
  bool isSearchClicked = false;
  late AnimationController _fabAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    final mapBloc = context.read<MapBloc>();
    mapBloc.add(LoadUserLocation());
    mapBloc.add(SubscribeToBusUpdates());

    // Automatically load nearby buses after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isSearchClicked = true;
        });
        mapBloc.add(LoadNearbyBuses());
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusList(List<Map<String, dynamic>> buses) {
    if (!isSearchClicked) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryLight.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Looking for buses nearby",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the bus button below to find them",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).scale();
    }

    if (buses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.orange[300]!, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text(
              "No buses found nearby",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try again in a moment",
              style: TextStyle(fontSize: 14, color: Colors.orange[700]),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms);
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];
          return _buildBusCard(bus, index);
        },
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus, int index) {
    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                selectedBusPosition = LatLng(bus['latitude'], bus['longitude']);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bus ${bus['id']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.successColor
                                                .withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(
                                      onPlay:
                                          (controller) => controller.repeat(),
                                    )
                                    .fadeOut(duration: 1000.ms)
                                    .then()
                                    .fadeIn(duration: 1000.ms),
                                const SizedBox(width: 6),
                                Text(
                                  'Live Tracking',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedBusPosition = LatLng(
                              bus['latitude'],
                              bus['longitude'],
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.speed_rounded,
                    'Speed',
                    bus['speedDisplay'] ??
                        '${bus['speed']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.social_distance_rounded,
                    'Distance',
                    bus['distance'] ?? 'N/A',
                    AppTheme.accentColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'ETA',
                    bus['eta'] ?? 'Unknown',
                    AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.update_rounded,
                    'Last Update',
                    bus['timestamp'] ?? 'Unknown',
                    Colors.grey[600]!,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${bus['latitude']?.toStringAsFixed(6)}, ${bus['longitude']?.toStringAsFixed(6)}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bus_rounded, size: 28),
            const SizedBox(width: 8),
            const Text('Bus Tracker'),
          ],
        ),
        actions: [
          // Theme toggle button
          BlocBuilder<ThemeCubit, dynamic>(
            builder: (context, state) {
              final isDark = state.isDarkMode;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme();
                },
              ).animate(target: isDark ? 1 : 0).rotate(duration: 300.ms);
            },
          ),
          // Real-time indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeOut(duration: 1000.ms)
                    .then()
                    .fadeIn(duration: 1000.ms),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is MapLoading) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading map...',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms);
                } else if (state is MapError) {
                  return LocationError(
                    message: state.error,
                    code: "PERMISSION_DENIED",
                  ).buildErrorWidget(
                    context,
                    onRetry: () {
                      context.read<MapBloc>().add(LoadUserLocation());
                    },
                  );
                } else if (state is MapLoaded) {
                  return MapView(
                    nearbyBuses: state.nearbyBuses,
                    userPosition: state.position,
                    selectedBusPosition: selectedBusPosition,
                  );
                }
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Text(
                      'Initializing...',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                );
              },
            ),
          ),
          BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              if (state is MapLoading && !isSearchClicked) {
                return Expanded(child: _buildLoadingShimmer());
              }
              if (state is MapLoaded) {
                return _buildBusList(state.nearbyBuses);
              }
              return Container();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                isSearchClicked = true;
              });
              _fabAnimationController.forward().then((_) {
                _fabAnimationController.reverse();
              });
              context.read<MapBloc>().add(LoadNearbyBuses());
            },
            icon: const Icon(Icons.search_rounded, size: 24),
            label: const Text(
              'Find Buses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
