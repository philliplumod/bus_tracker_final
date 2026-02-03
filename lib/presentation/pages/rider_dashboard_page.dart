import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/distance_calculator.dart';
import '../bloc/map/map_bloc.dart';
import '../bloc/map/map_event.dart';
import '../bloc/map/map_state.dart';
import '../bloc/rider_tracking/rider_tracking_bloc.dart';
import '../bloc/rider_tracking/rider_tracking_event.dart';
import '../widgets/rider_tracking_dashboard.dart';

class RiderDashboardPage extends StatefulWidget {
  final User rider;

  const RiderDashboardPage({super.key, required this.rider});

  @override
  State<RiderDashboardPage> createState() => _RiderDashboardPageState();
}

class _RiderDashboardPageState extends State<RiderDashboardPage> {
  RiderTrackingBloc? _riderTrackingBloc;

  @override
  void initState() {
    super.initState();
    // Start tracking when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _riderTrackingBloc = context.read<RiderTrackingBloc>();
        _riderTrackingBloc?.add(StartTracking(widget.rider));
      }
    });
  }

  @override
  void dispose() {
    // Stop tracking when leaving dashboard
    // Use saved reference to avoid unsafe context access during disposal
    _riderTrackingBloc?.add(const StopTracking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Tracking Dashboard
                RiderTrackingDashboard(rider: widget.rider),
                const SizedBox(height: 14),

                // Welcome Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 28,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.rider.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Route Information Card (with distance and travel time)
                if (widget.rider.startingTerminal != null &&
                    widget.rider.destinationTerminal != null &&
                    widget.rider.startingTerminalLat != null &&
                    widget.rider.startingTerminalLng != null &&
                    widget.rider.destinationTerminalLat != null &&
                    widget.rider.destinationTerminalLng != null)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Route Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            label: 'Starting Point',
                            value: widget.rider.startingTerminal!,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            context,
                            label: 'Destination',
                            value: widget.rider.destinationTerminal!,
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final distance = DistanceCalculator.calculate(
                                widget.rider.startingTerminalLat!,
                                widget.rider.startingTerminalLng!,
                                widget.rider.destinationTerminalLat!,
                                widget.rider.destinationTerminalLng!,
                              );
                              final travelTime =
                                  DistanceCalculator.calculateTravelTime(
                                    distance,
                                  );

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.straighten,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DistanceCalculator.formatDistance(
                                                  distance,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Distance',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                travelTime,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Est. Travel Time',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),

                // Bus Information Card
                if (widget.rider.busName != null)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.directions_bus,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bus Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            label: 'Bus Name',
                            value: widget.rider.busName!,
                          ),
                          if (widget.rider.assignedRoute != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              label: 'Assigned Route',
                              value: widget.rider.assignedRoute!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Location Status Card
                if (state is MapLoaded)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Location Status',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            label: 'Latitude',
                            value: state.userLocation.latitude.toStringAsFixed(
                              6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            context,
                            label: 'Longitude',
                            value: state.userLocation.longitude.toStringAsFixed(
                              6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            context,
                            label: 'Accuracy',
                            value:
                                '${state.userLocation.accuracy.toStringAsFixed(1)}m',
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text('Loading location data...'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Quick Actions Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Refresh Location',
                            style: TextStyle(fontSize: 14),
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            context.read<MapBloc>().add(LoadUserLocation());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing location...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
