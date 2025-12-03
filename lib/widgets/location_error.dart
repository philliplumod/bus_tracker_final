import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationError {
  final String message;
  final String code;

  LocationError({required this.message, this.code = 'UNKNOWN_ERROR'});

  Widget buildErrorWidget(BuildContext context, {VoidCallback? onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            code == 'PERMISSION_DENIED_FOREVER' 
                ? 'Location Permission Denied'
                : 'Location Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (onRetry != null && code != 'PERMISSION_DENIED_FOREVER')
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            )
          else if (code == 'PERMISSION_DENIED_FOREVER')
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}