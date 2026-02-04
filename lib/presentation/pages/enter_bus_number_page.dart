import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/distance_calculator.dart';
import '../bloc/bus_search/bus_search_bloc.dart';
import '../bloc/bus_search/bus_search_event.dart';
import '../bloc/bus_search/bus_search_state.dart';
import 'bus_route_page.dart';

class EnterBusNumberPage extends StatefulWidget {
  const EnterBusNumberPage({super.key});

  @override
  State<EnterBusNumberPage> createState() => _EnterBusNumberPageState();
}

class _EnterBusNumberPageState extends State<EnterBusNumberPage> {
  final TextEditingController _busNumberController = TextEditingController();
  BusSearchBloc? _busSearchBloc;
  Position? _userPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to bloc early in lifecycle
    _busSearchBloc ??= context.read<BusSearchBloc>();
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _busSearchBloc != null) {
        _busSearchBloc!.add(LoadAllBuses());
      }
    });
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
        });
      }
    } catch (e) {
      // Use default location if unable to get user location
      debugPrint('Error getting user location: $e');
    }
  }

  String _formatETA(double minutes) {
    if (minutes < 60) {
      return '${minutes.round()} min';
    } else {
      final hours = minutes ~/ 60;
      final mins = (minutes % 60).round();
      return '${hours}h ${mins}m';
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _busSearchBloc = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Search'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<BusSearchBloc, BusSearchState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Search for a Bus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _busNumberController,
                          decoration: InputDecoration(
                            hintText: 'Enter bus number',
                            prefixIcon: const Icon(Icons.directions_bus),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted:
                              (_) => context.read<BusSearchBloc>().add(
                                SearchBusByNumber(_busNumberController.text),
                              ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_busNumberController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a bus number'),
                                ),
                              );
                              return;
                            }
                            context.read<BusSearchBloc>().add(
                              SearchBusByNumber(_busNumberController.text),
                            );
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Live update indicator
                if (state is BusSearchLoaded)
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
                        Text(
                          'Live tracking • ${state.allBuses.length} bus(es) online • Real-time updates',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(child: _buildResultsList(state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(BusSearchState state) {
    if (state is BusSearchLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading buses...'),
          ],
        ),
      );
    }

    if (state is BusSearchError) {
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

    if (state is! BusSearchLoaded) {
      return const SizedBox();
    }

    if (!state.hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Enter a bus number to search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (state.filteredBuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bus_alert, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No buses found matching "${state.searchQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or searching for another bus number',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.filteredBuses.length,
      itemBuilder: (context, index) {
        final bus = state.filteredBuses[index];
        final isMoving = (bus.speed ?? 0) > 1.0;

        // Calculate distance and ETA if user position is available
        String? eta;
        double? distanceFromUser;
        String speed = 'N/A';
        if (_userPosition != null &&
            bus.latitude != null &&
            bus.longitude != null) {
          distanceFromUser = DistanceCalculator.calculate(
            _userPosition!.latitude,
            _userPosition!.longitude,
            bus.latitude!,
            bus.longitude!,
          );
          // Calculate ETA using actual bus speed
          if ((bus.speed ?? 0) > 0) {
            final etaMinutes = (distanceFromUser / bus.speed!) * 60;
            eta = _formatETA(etaMinutes);
            speed = '${bus.speed!.toStringAsFixed(1)} km/h';
          } else {
            // Use average speed if bus is stationary
            final etaMinutes = (distanceFromUser / 30) * 60;
            eta = '~${_formatETA(etaMinutes)}';
            speed = '0.0 km/h';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
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
                // Distance and ETA row
                if (distanceFromUser != null && eta != null)
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
                        'ETA: $eta',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (distanceFromUser != null && eta != null)
                  const SizedBox(height: 4),
                if (distanceFromUser != null && eta != null)
                  Row(
                    children: [
                      Icon(Icons.speed, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(speed, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BusRoutePage(bus: bus)),
              );
            },
          ),
        );
      },
    );
  }
}
