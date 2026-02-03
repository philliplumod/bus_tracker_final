import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/rider_tracking/rider_tracking_bloc.dart';
import '../bloc/rider_tracking/rider_tracking_state.dart';
import '../../core/utils/eta_service.dart';
import '../../domain/entities/user.dart';

class RiderTrackingDashboard extends StatelessWidget {
  final User rider;

  const RiderTrackingDashboard({super.key, required this.rider});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiderTrackingBloc, RiderTrackingState>(
      builder: (context, state) {
        if (state is RiderTrackingActive) {
          return _buildActiveTracking(context, state);
        } else if (state is RiderTrackingError) {
          return _buildError(context, state);
        } else if (state is RiderTrackingStopped) {
          return _buildStopped(context);
        } else if (state is RiderTrackingLoading) {
          return _buildLoading(context);
        }

        return _buildInitial(context);
      },
    );
  }

  Widget _buildActiveTracking(BuildContext context, RiderTrackingActive state) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.my_location, color: Colors.green[700]),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          rider.busName ?? 'Bus',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.speed,
                    label: 'Current Speed',
                    value: state.speed.toStringAsFixed(1),
                    unit: 'km/h',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.explore,
                    label: 'Heading',
                    value: '${state.heading.toStringAsFixed(0)}°',
                    unit: _getDirectionName(state.heading),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ETA Card (if available)
            if (state.estimatedDurationMinutes != null &&
                rider.destinationTerminal != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ETA to Destination',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rider.destinationTerminal!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ETAService.formatETA(state.estimatedDurationMinutes!),
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Location Info
            _buildLocationInfo(state),

            const SizedBox(height: 12),

            // Last Update
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Last updated ${_formatTimestamp(state.lastUpdate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(RiderTrackingActive state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.location_on,
            'Latitude',
            state.latitude.toStringAsFixed(6),
          ),
          const Divider(height: 16),
          _buildInfoRow(
            Icons.location_on,
            'Longitude',
            state.longitude.toStringAsFixed(6),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Removed error display widget - errors are now handled silently
  Widget _buildError(BuildContext context, RiderTrackingError state) {
    // Return empty widget instead of showing error
    return const SizedBox.shrink();
  }

  Widget _buildStopped(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tracking Stopped',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparing tracking...',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Fetching assignment from server...',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 10) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  String _getDirectionName(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return '';
  }
}
