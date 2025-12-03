class AppConstants {
  // Firebase constants
  static const String busesPath = 'buses';
  static const String locationPath = 'location';
  static const String payloadPath = 'payload';

  // Map constants
  static const double defaultZoom = 14.0;
  static const double selectedBusZoom = 16.0;
  static const double userRangeRadius = 1000.0; // 1km
  static const double selectedBusRadius = 300.0;
  static const double nearbyBusThreshold = 1.0; // 1km for notifications

  // Update intervals
  static const Duration busUpdateInterval = Duration(seconds: 2);
  static const Duration locationUpdateInterval = Duration(seconds: 5);

  // Map heights
  static const double mapHeight = 280.0;

  // Notification constants
  static const String nearbyBusTitle = 'Bus is Near!';
  static String nearbyBusMessage(String busId) =>
      'Bus $busId is within 1km of your location!';
}
