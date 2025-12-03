import 'dart:math';

import 'package:flutter/material.dart';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371.0;
  double dLat = _deg2rad(lat2 - lat1);
  double dLon = _deg2rad(lon2 - lon1);
  double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  debugPrint("Distance: ${earthRadiusKm * c} km");
  return earthRadiusKm * c;
}

double _deg2rad(double deg) => deg * (pi / 180);
