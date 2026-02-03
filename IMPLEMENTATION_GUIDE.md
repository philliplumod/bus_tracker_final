# Bus Tracker Mobile App - Complete Implementation Guide

## Overview

This document provides a comprehensive guide to the redesigned and enhanced bus tracking mobile app. The system is now fully dynamic, real-time, and synced with both the Backend API and Firebase Realtime Database.

---

## Architecture

### Data Flow

```
Backend API (Supabase) ←→ Mobile App ←→ Firebase Realtime Database
      (Static Data)                         (Live GPS Data)
```

**Backend API** provides:

- Terminals
- Buses
- Routes with waypoints
- Bus-Route assignments
- User assignments

**Firebase** provides:

- Real-time GPS coordinates (every 2 seconds)
- Live bus locations
- Speed, heading, accuracy

**Mobile App** displays:

- Dynamic maps with polylines
- Real-time ETAs
- Live tracking
- Trip planning

---

## 1. Backend API Integration

### API Client (`api_client.dart`)

Generic HTTP client for all API requests with authentication support.

```dart
final apiClient = ApiClient(baseUrl: 'http://your-backend-url.com');
apiClient.setAuthToken('your-auth-token');
```

### Backend API Service (`backend_api_service.dart`)

Provides methods to fetch data from all endpoints:

```dart
final backendService = BackendApiService(apiClient: apiClient);

// Fetch all terminals
final terminals = await backendService.getTerminals();

// Fetch all buses
final buses = await backendService.getBuses();

// Fetch all routes (with terminals and waypoints)
final routes = await backendService.getRoutes();

// Fetch bus-route assignments
final busRoutes = await backendService.getBusRoutes();

// Fetch user assignments
final userAssignments = await backendService.getUserAssignments();
```

### API Models

All API responses are parsed using dedicated models:

- `ApiTerminalModel` → `Terminal`
- `ApiBusModel` → `Bus`
- `ApiRouteModel` → `BusRoute`
- `ApiBusRouteModel` → `BusRouteAssignment`
- `ApiUserAssignmentModel` → `UserAssignment`

---

## 2. Firebase Real-Time Location Tracking

### Location Tracking Service (`location_tracking_service.dart`)

Captures GPS data every **2 seconds** and writes to Firebase.

#### Starting Tracking

```dart
final locationService = LocationTrackingService();

// Start tracking (requires user and assignment)
await locationService.startTracking(rider, assignment);

// Listen to location updates
locationService.locationStream?.listen((update) {
  print('Location: ${update.latitude}, ${update.longitude}');
  print('Speed: ${update.speed} km/h');
  print('Heading: ${update.heading}°');
});

// Stop tracking
locationService.stopTracking();
```

#### Firebase Structure

```
/buses
  /{busId}
    /location
      /{userId}
        - userId: "..."
        - busId: "..."
        - routeId: "..."
        - busRouteAssignmentId: "..."
        - latitude: 0.0
        - longitude: 0.0
        - speed: 0.0
        - heading: 0.0
        - accuracy: 0.0
        - timestamp: "ISO-8601"
```

**❗ No field is ever "unknown"** - all values come from the API assignment.

---

## 3. Dynamic Route Polyline Rendering

### Dynamic Polyline Service (`dynamic_polyline_service.dart`)

Draws polylines from route data with live updates.

#### Building Polylines

```dart
// Build complete route polyline
final polylines = DynamicPolylineService.buildCompletePolylines(
  route: busRoute,
  currentPosition: LatLng(lat, lng), // Optional
);

// Update polylines when position changes
final updatedPolylines = DynamicPolylineService.updatePolylinesWithPosition(
  route: busRoute,
  currentPosition: currentBusPosition,
);

// Get camera bounds for route
final bounds = DynamicPolylineService.getRouteBounds(busRoute);
```

#### Polyline Structure

- **Blue polyline**: Full route (starting terminal → waypoints → destination)
- **Green polyline**: Traveled portion (start → current position)

#### Smooth Marker Animation

```dart
final routePoints = DynamicPolylineService._buildRoutePoints(route);

DynamicPolylineService.animateMarkerAlongRoute(
  routePoints: routePoints,
  duration: Duration(seconds: 30),
).listen((position) {
  // Update marker position
  setState(() {
    markerPosition = position;
  });
});
```

---

## 4. Dual ETA System

### Enhanced ETA Service (`enhanced_eta_service.dart`)

Provides separate ETA calculations for riders and passengers.

#### Rider ETAs

```dart
// ETA to next terminal
final etaToNext = EnhancedETAService.calculateRiderETAToNextTerminal(
  currentLat: riderLat,
  currentLng: riderLng,
  nextTerminal: nextTerminal,
  waypoints: route.routeData,
  currentSpeed: currentSpeed,
);

// ETA to destination terminal
final etaToDestination = EnhancedETAService.calculateRiderETAToDestination(
  currentLat: riderLat,
  currentLng: riderLng,
  destination: destinationTerminal,
  waypoints: route.routeData,
  routeDurationMinutes: route.durationMinutes,
);

print('Distance: ${etaToNext['distanceKm']} km');
print('Duration: ${etaToNext['durationMinutes']} min');
print('ETA: ${etaToNext['etaTimestamp']}');
```

#### Passenger ETAs

```dart
// Bus to passenger location
final busToPassenger = EnhancedETAService.calculateBusToPassengerETA(
  busLat: busLat,
  busLng: busLng,
  passengerLat: passengerLat,
  passengerLng: passengerLng,
  waypoints: route.routeData,
  busSpeed: busSpeed,
);

// Passenger to destination (after boarding)
final passengerToDestination = EnhancedETAService.calculatePassengerToDestinationETA(
  passengerLat: passengerLat,
  passengerLng: passengerLng,
  destination: destinationTerminal,
  waypoints: route.routeData,
  routeDurationMinutes: route.durationMinutes,
);
```

#### Formatting Helpers

```dart
final formattedDuration = EnhancedETAService.formatDuration(45.5); // "46 min"
final formattedDistance = EnhancedETAService.formatDistance(2.3);   // "2.3 km"
```

---

## 5. Passenger Search Flow

### Live Bus Location Service (`live_bus_location_service.dart`)

Fetches real-time bus locations from Firebase.

```dart
final locationService = LiveBusLocationService();

// Watch all bus locations (stream)
locationService.watchAllBusLocations().listen((locations) {
  // locations: {busId: {latitude: ..., longitude: ..., speed: ...}}
  print('${locations.length} buses online');
});

// Watch specific bus location
locationService.watchBusLocation(busId).listen((location) {
  if (location != null) {
    print('Bus at ${location['latitude']}, ${location['longitude']}');
  }
});

// One-time fetch
final allLocations = await locationService.getAllBusLocations();
```

### Passenger Search Service (`passenger_search_service.dart`)

Implements search and trip planning features.

#### A. Search by Bus Number

```dart
final matchingBuses = PassengerSearchService.searchBusesByName(
  allBuses,
  'Bus 001', // Search query
);
```

#### B. Trip Planner

```dart
// Get live bus locations
final liveBusLocations = await locationService.getAllBusLocations();

// Find trip options
final tripOptions = await PassengerSearchService.findTripOptions(
  passengerLat: userLatitude,
  passengerLng: userLongitude,
  destinationTerminal: selectedDestination,
  allBuses: buses,
  allRoutes: routes,
  allBusRoutes: busRoutes,
  liveBusLocations: liveBusLocations,
);

// Display trip options
for (final option in tripOptions) {
  print('Bus: ${option.busName}');
  print('Route: ${option.routeName}');
  print('ETA: ${option.formattedETA}');
  print('Distance: ${option.formattedDistance}');
}
```

#### C. Nearby Buses

```dart
final nearbyBuses = PassengerSearchService.getNearbyBuses(
  passengerLat: userLat,
  passengerLng: userLng,
  liveBusLocations: liveBusLocations,
  allBuses: buses,
  radiusKm: 5.0,
);
```

---

## 6. UI Implementation Guidelines

### Rider UI

#### Required Components

1. **Live Map View**
   - Google Maps with current location
   - Bus marker (animated)
   - Route polyline (blue + green)
   - Terminal markers

2. **Dynamic ETA Display**
   - ETA to next terminal (updating)
   - ETA to destination (updating)
   - Distance remaining
   - Current speed

3. **Real-Time Updates**
   - GPS data sent every 2 seconds
   - Map updates smoothly
   - No flickering or lag

#### Example Structure

```dart
class RiderTrackingPage extends StatefulWidget {
  final User rider;
  final UserAssignment assignment;
  final BusRoute route;

  // ... implementation
}

class _RiderTrackingPageState extends State<RiderTrackingPage> {
  late LocationTrackingService _locationService;
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _loadRoutePolyline();
  }

  Future<void> _initializeTracking() async {
    _locationService = LocationTrackingService();
    await _locationService.startTracking(widget.rider, widget.assignment);

    _locationService.locationStream?.listen((update) {
      setState(() {
        // Update map with new location
        _updateMapPosition(update);
        _updatePolylines(update);
        _updateETAs(update);
      });
    });
  }

  void _loadRoutePolyline() {
    setState(() {
      _polylines = DynamicPolylineService.buildCompletePolylines(
        route: widget.route,
      );
    });
  }

  void _updatePolylines(RiderLocationUpdate update) {
    setState(() {
      _polylines = DynamicPolylineService.updatePolylinesWithPosition(
        route: widget.route,
        currentPosition: LatLng(update.latitude, update.longitude),
      );
    });
  }

  // ... rest of implementation
}
```

---

### Passenger UI

#### A. Bus Search Page

```dart
class BusSearchPage extends StatefulWidget {
  @override
  _BusSearchPageState createState() => _BusSearchPageState();
}

class _BusSearchPageState extends State<BusSearchPage> {
  final _searchController = TextEditingController();
  List<Bus> _filteredBuses = [];
  Map<String, Map<String, double>> _liveBusLocations = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _watchBusLocations();
  }

  Future<void> _loadData() async {
    // Load buses from API
    final buses = await backendService.getBuses();
    setState(() {
      _filteredBuses = buses;
    });
  }

  void _watchBusLocations() {
    final locationService = LiveBusLocationService();
    locationService.watchAllBusLocations().listen((locations) {
      setState(() {
        _liveBusLocations = locations;
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredBuses = PassengerSearchService.searchBusesByName(
        allBuses,
        query,
      );
    });
  }

  void _onBusSelected(Bus bus) {
    // Navigate to live tracking page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusLiveTrackingPage(
          bus: bus,
          busLocation: _liveBusLocations[bus.id],
        ),
      ),
    );
  }

  // ... UI implementation
}
```

#### B. Trip Planner Page

```dart
class TripPlannerPage extends StatefulWidget {
  @override
  _TripPlannerPageState createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  Terminal? _selectedDestination;
  List<TripOption> _tripOptions = [];
  bool _loading = false;

  Future<void> _searchTrips() async {
    if (_selectedDestination == null) return;

    setState(() {
      _loading = true;
    });

    // Get user location
    final position = await Geolocator.getCurrentPosition();

    // Get live bus locations
    final locationService = LiveBusLocationService();
    final liveBusLocations = await locationService.getAllBusLocations();

    // Find trip options
    final options = await PassengerSearchService.findTripOptions(
      passengerLat: position.latitude,
      passengerLng: position.longitude,
      destinationTerminal: _selectedDestination!,
      allBuses: buses,
      allRoutes: routes,
      allBusRoutes: busRoutes,
      liveBusLocations: liveBusLocations,
    );

    setState(() {
      _tripOptions = options;
      _loading = false;
    });
  }

  void _onTripSelected(TripOption option) {
    // Navigate to live tracking with selected trip
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassengerTrackingPage(
          tripOption: option,
        ),
      ),
    );
  }

  // ... UI implementation with trip cards
}
```

---

## 7. Data Synchronization

### Initialization Flow

```dart
Future<void> initializeApp() async {
  // 1. Initialize API client
  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  apiClient.setAuthToken(authToken);

  // 2. Initialize backend service
  final backendService = BackendApiService(apiClient: apiClient);

  // 3. Fetch static data from API
  final terminals = await backendService.getTerminals();
  final buses = await backendService.getBuses();
  final routes = await backendService.getRoutes();
  final busRoutes = await backendService.getBusRoutes();
  final userAssignments = await backendService.getUserAssignments();

  // 4. Initialize Firebase services
  final locationService = LocationTrackingService();
  final liveBusService = LiveBusLocationService();

  // 5. For riders: Start location tracking
  if (user.role == UserRole.rider) {
    final assignment = await backendService.getUserAssignment(user.id);
    if (assignment != null) {
      await locationService.startTracking(user, assignment);
    }
  }

  // 6. For passengers: Watch live bus locations
  if (user.role == UserRole.passenger) {
    liveBusService.watchAllBusLocations().listen((locations) {
      // Update UI with live data
    });
  }
}
```

### Real-Time Sync Loop

```
┌─────────────────────────────────────────┐
│  Every 2 seconds (Rider)                │
│  1. Capture GPS location                │
│  2. Calculate ETAs                      │
│  3. Write to Firebase                   │
│  4. Update local UI                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Real-Time (Passenger)                  │
│  1. Listen to Firebase changes          │
│  2. Calculate passenger ETAs            │
│  3. Update map markers                  │
│  4. Update polylines                    │
│  5. Refresh UI                          │
└─────────────────────────────────────────┘
```

---

## 8. Error Handling

### Graceful Degradation

```dart
// No buses available
if (buses.isEmpty) {
  return Center(
    child: Text('No buses currently operating'),
  );
}

// Lost GPS signal
if (locationUpdate == null) {
  return AlertDialog(
    title: Text('GPS Signal Lost'),
    content: Text('Please check your location settings'),
  );
}

// Network error
try {
  final routes = await backendService.getRoutes();
} catch (e) {
  showSnackBar('Network error: ${e.message}');
  // Use cached data if available
}

// No live location available
final busLocation = liveBusLocations[busId];
if (busLocation == null) {
  // Show last known position or starting terminal
  final fallbackPosition = route.startingTerminal;
}
```

---

## 9. Configuration

### App Constants

Update `app_constants.dart`:

```dart
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://your-backend-url.com';

  // Firebase constants
  static const String busesPath = 'buses';
  static const String locationPath = 'location';

  // Update intervals
  static const Duration locationUpdateInterval = Duration(seconds: 2);
  static const Duration mapRefreshInterval = Duration(milliseconds: 500);

  // Map constants
  static const double defaultZoom = 14.0;
  static const double selectedBusZoom = 16.0;

  // Distance thresholds
  static const double nearbyBusThreshold = 5.0; // km
  static const double routeProximityThreshold = 0.5; // km
}
```

---

## 10. Testing

### Unit Tests

```dart
// Test API service
test('Fetches terminals from API', () async {
  final terminals = await backendService.getTerminals();
  expect(terminals, isNotEmpty);
  expect(terminals.first.name, isNotNull);
});

// Test ETA calculation
test('Calculates rider ETA correctly', () {
  final eta = EnhancedETAService.calculateRiderETAToNextTerminal(
    currentLat: 14.5995,
    currentLng: 120.9842,
    nextTerminal: terminal,
    waypoints: waypoints,
  );
  expect(eta['durationMinutes'], greaterThan(0));
});

// Test polyline building
test('Builds polyline with waypoints', () {
  final polylines = DynamicPolylineService.buildCompletePolylines(
    route: route,
  );
  expect(polylines, isNotEmpty);
});
```

---

## 11. Performance Optimization

### Best Practices

1. **Debounce map updates** (500ms)
2. **Cache API responses** (5 minutes)
3. **Batch Firebase writes** (2-second interval)
4. **Optimize polyline rendering** (simplify points if > 100)
5. **Use StreamBuilder** for real-time data
6. **Dispose subscriptions** properly

---

## 12. Deployment Checklist

- [ ] Configure API base URL
- [ ] Set up Firebase project
- [ ] Enable Firebase Realtime Database
- [ ] Configure authentication tokens
- [ ] Test all API endpoints
- [ ] Test Firebase read/write permissions
- [ ] Test location permissions on devices
- [ ] Test in low-network conditions
- [ ] Verify polyline rendering
- [ ] Validate ETA calculations
- [ ] Test passenger search flow
- [ ] Test rider tracking flow

---

## Summary

This implementation provides:

✅ **Fully dynamic UI** - All data from API and Firebase  
✅ **Real-time tracking** - GPS updates every 2 seconds  
✅ **Live polylines** - Route visualization with traveled portion  
✅ **Dual ETA system** - Separate calculations for riders and passengers  
✅ **Passenger search** - Bus search + trip planner  
✅ **No hardcoded data** - Everything from backend sources  
✅ **Graceful error handling** - Network, GPS, and edge cases covered  
✅ **Smooth animations** - Marker and polyline updates

**All fields are properly mapped, no "unknown" values, and the system maintains real-time synchronization between Supabase API, Firebase, and the mobile UI.**
