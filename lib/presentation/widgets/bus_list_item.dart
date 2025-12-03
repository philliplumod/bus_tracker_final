import 'package:flutter/material.dart';
import '../../core/utils/distance_calculator.dart';
import '../../domain/entities/bus.dart';
import '../../theme/app_theme.dart';

class BusListItem extends StatelessWidget {
  final Bus bus;
  final VoidCallback onTap;

  const BusListItem({super.key, required this.bus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${bus.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.speed,
                          '${bus.speed.toStringAsFixed(1)} km/h',
                        ),
                        const SizedBox(width: 8),
                        if (bus.distanceFromUser != null)
                          _buildInfoChip(
                            Icons.location_on,
                            DistanceCalculator.formatDistance(
                              bus.distanceFromUser!,
                            ),
                          ),
                        if (bus.direction != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(Icons.navigation, bus.direction!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (bus.eta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bus.eta!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
