import '../../domain/entities/user_location.dart';

class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.latitude,
    required super.longitude,
    required super.accuracy,
  });
}
