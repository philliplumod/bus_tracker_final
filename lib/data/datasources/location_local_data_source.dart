import 'package:geolocator/geolocator.dart';
import '../models/user_location_model.dart';

abstract class LocationLocalDataSource {
  Future<UserLocationModel> getUserLocation();
  Stream<UserLocationModel> watchUserLocation();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  @override
  Future<UserLocationModel> getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      return UserLocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      throw Exception('Failed to get user location: $e');
    }
  }

  @override
  Stream<UserLocationModel> watchUserLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).map(
      (position) => UserLocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      ),
    );
  }
}
