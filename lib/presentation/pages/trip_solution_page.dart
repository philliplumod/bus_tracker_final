import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/utils/distance_calculator.dart';
import '../../core/utils/eta_service.dart';
import '../bloc/trip_solution/trip_solution_bloc.dart';
import '../bloc/trip_solution/trip_solution_event.dart';
import '../bloc/trip_solution/trip_solution_state.dart';
import '../widgets/map_destination_picker.dart';
import 'bus_route_page.dart';

class TripSolutionPage extends StatefulWidget {
  const TripSolutionPage({super.key});

  @override
  State<TripSolutionPage> createState() => _TripSolutionPageState();
}

class _TripSolutionPageState extends State<TripSolutionPage> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TripSolutionBloc>().add(LoadTripSolutionData());
      }
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Solution'),
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<TripSolutionBloc, TripSolutionState>(
        listener: (context, state) {
          if (state is TripSolutionLoaded &&
              state.hasSearched &&
              state.destinationCoordinates == null &&
              state.searchQuery.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location "${state.searchQuery}" not found. Try a different address or use the map picker.',
                ),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'USE MAP',
                  onPressed: () {
                    final userLoc = state.userLocation;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MapDestinationPicker(
                              initialPosition: LatLng(
                                userLoc.latitude,
                                userLoc.longitude,
                              ),
                              onLocationSelected: (coords, name) {
                                _destinationController.text = name;
                                context.read<TripSolutionBloc>().add(
                                  SearchTripByCoordinates(
                                    coords,
                                    locationName: name,
                                  ),
                                );
                              },
                            ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TripSolutionLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading location data...'),
                ],
              ),
            );
          }

          if (state is TripSolutionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (state is! TripSolutionLoaded) {
            return const SizedBox();
          }

          return Column(
            children: [
              // Live update indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: Colors.green[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      'Live bus tracking • Real-time updates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Search section
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Where do you want to go?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Enter any address or location name',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted:
                            (_) => context.read<TripSolutionBloc>().add(
                              SearchTripSolution(_destinationController.text),
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Type any address in Cebu (e.g., Gusa, SM Cebu, IT Park, your complete address)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_destinationController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a destination',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                context.read<TripSolutionBloc>().add(
                                  SearchTripSolution(
                                    _destinationController.text,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MapDestinationPicker(
                                          initialPosition: LatLng(
                                            state.userLocation.latitude,
                                            state.userLocation.longitude,
                                          ),
                                          onLocationSelected: (coords, name) {
                                            _destinationController.text = name;
                                            context
                                                .read<TripSolutionBloc>()
                                                .add(
                                                  SearchTripByCoordinates(
                                                    coords,
                                                    locationName: name,
                                                  ),
                                                );
                                          },
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('Pick on Map'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Results section
              Expanded(child: _buildResultsList(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultsList(TripSolutionLoaded state) {
    if (!state.hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Enter your destination to find available buses',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (state.matchingBuses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bus_alert, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No buses found near "${state.searchQuery}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No buses found within 10km of both your location and "${state.searchQuery}".\n\nThis means:\n• No buses are currently serving this route\n• Try a different destination\n• Check again later when more buses are active',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            'Found ${state.matchingBuses.length} bus(es) to ${state.searchQuery}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: state.matchingBuses.length,
            itemBuilder: (context, index) {
              final bus = state.matchingBuses[index];
              final distanceFromUser = DistanceCalculator.calculate(
                state.userLocation.latitude,
                state.userLocation.longitude,
                bus.latitude!,
                bus.longitude!,
              );

              // Calculate ETA to user's location using actual bus speed
              String etaToUser = 'Calculating...';
              if ((bus.speed ?? 0) > 0) {
                final etaMinutes = (distanceFromUser / bus.speed!) * 60;
                etaToUser = ETAService.formatETA(etaMinutes);
              } else {
                // Use average speed if bus is stationary
                final etaMinutes = (distanceFromUser / 30) * 60;
                etaToUser = '~${ETAService.formatETA(etaMinutes)}';
              }

              // Calculate travel time from user to destination
              String travelTime = 'Unknown';
              if (state.destinationCoordinates != null) {
                final distanceToDestination = DistanceCalculator.calculate(
                  state.userLocation.latitude,
                  state.userLocation.longitude,
                  state.destinationCoordinates!.latitude,
                  state.destinationCoordinates!.longitude,
                );
                final travelMinutes =
                    (distanceToDestination / 30) * 60; // Average bus speed
                travelTime = ETAService.formatETA(travelMinutes);
              }

              final isMoving =
                  (bus.speed ?? 0) > 1.0; // Consider moving if speed > 1 km/h

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMoving ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (isMoving)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        bus.busNumber != null
                            ? 'Bus ${bus.busNumber}'
                            : 'Bus ${bus.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isMoving)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MOVING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bus.route != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Route: ${bus.route}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceFromUser.toStringAsFixed(2)} km away',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ETA: $etaToUser',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.speed, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${bus.speed?.toStringAsFixed(1) ?? 'N/A'} km/h',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (state.destinationCoordinates != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trip: $travelTime',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusRoutePage(bus: bus),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
