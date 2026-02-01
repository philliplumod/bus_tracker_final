import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/distance_calculator.dart';
import '../bloc/trip_solution/trip_solution_bloc.dart';
import '../bloc/trip_solution/trip_solution_event.dart';
import '../bloc/trip_solution/trip_solution_state.dart';
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
            final bloc = context.read<TripSolutionBloc>();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location "${state.searchQuery}" not found. Try: ${bloc.knownLocations.keys.take(5).join(", ")}',
                ),
                duration: const Duration(seconds: 4),
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

          final bloc = context.read<TripSolutionBloc>();

          return Column(
            children: [
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
                          hintText: 'Enter destination (e.g., SM Cebu, Ayala)',
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
                      Text(
                        'Available locations: ${bloc.knownLocations.keys.take(5).join(", ")}, etc.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_destinationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a destination'),
                              ),
                            );
                            return;
                          }
                          context.read<TripSolutionBloc>().add(
                            SearchTripSolution(_destinationController.text),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Find Buses'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
                'No buses found for "${state.searchQuery}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for a different location or check if buses are available',
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
                bus.latitude,
                bus.longitude,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    bus.busNumber != null
                        ? 'Bus ${bus.busNumber}'
                        : 'Bus ${bus.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bus.route != null) Text('Route: ${bus.route}'),
                      Text(
                        'Distance: ${distanceFromUser.toStringAsFixed(2)} km away',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Speed: ${bus.speed.toStringAsFixed(1)} km/h',
                        style: const TextStyle(fontSize: 12),
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
