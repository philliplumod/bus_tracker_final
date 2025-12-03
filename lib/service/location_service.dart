import 'package:bus_tracker/widgets/location_error.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getUserCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationError(
            message:
                'Location permissions are denied. Please enable location services to use this feature.',
            code: 'PERMISSION_DENIED',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationError(
          message:
              'Location permissions are permanently denied. Please enable location in app settings to use this feature.',
          code: 'PERMISSION_DENIED_FOREVER',
        );
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
    } catch (e) {
      if (e is LocationError) {
        rethrow;
      } else {
        throw LocationError(
          message: 'Failed to get location: ${e.toString()}',
          code: 'LOCATION_ERROR',
        );
      }
    }
  }
}
