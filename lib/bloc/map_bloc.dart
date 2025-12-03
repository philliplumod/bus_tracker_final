import 'dart:async';
import 'package:bus_tracker/bloc/map_event.dart';
import 'package:bus_tracker/bloc/map_state.dart';
import 'package:bus_tracker/data/models/bus_data.dart';
import 'package:bus_tracker/service/calculate_service.dart';
import 'package:bus_tracker/service/location_service.dart';
import 'package:bus_tracker/service/notification_service.dart'; // ✅ Import notifications
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final DatabaseReference _busRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _busSubscription;
  Timer? _periodicTimer;
  final List<StreamSubscription<DatabaseEvent>> _individualBusListeners = [];
  final Map<String, BusData> previousBusData = {};
  final Map<String, DateTime> previousTimestamps = {};
  final Set<String> notifiedBuses = {}; // ✅ Track notified buses to avoid spam

  MapBloc() : super(MapInitial()) {
    on<LoadUserLocation>(_onLoadUserLocation);
    on<LoadNearbyBuses>(_onLoadNearbyBuses);
    on<SubscribeToBusUpdates>(_onSubscribeToBusUpdates);
    on<UpdateBusLocations>(_onUpdateBusLocations);
  }

  Future<void> _onLoadUserLocation(
    LoadUserLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    try {
      final position = await LocationService.getUserCurrentLocation();
      emit(
        MapLoaded(
          position: LatLng(position.latitude, position.longitude),
          nearbyBuses: [],
        ),
      );
    } catch (e) {
      emit(MapError("Error fetching location: ${e.toString()}"));
    }
  }

  Future<void> _onLoadNearbyBuses(
    LoadNearbyBuses event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    emit(MapLoading());
    try {
      final snapshot = await _busRef.get();
      if (snapshot.value == null || snapshot.value is! Map) {
        emit(MapError("No nearby buses found"));
        return;
      }

      List<Map<String, dynamic>> nearbyBuses = [];
      final data = snapshot.value as Map<Object?, Object?>;

      // Iterate through each bus (e.g., "bus_one", "bus_two", etc.)
      data.forEach((busId, busData) {
        if (busData is Map && busData.containsKey('location')) {
          final locationData = busData['location'] as Map<Object?, Object?>;

          // Get the most recent timestamp entry
          String? latestTimestamp;
          Map<Object?, Object?>? latestData;

          locationData.forEach((timestampKey, timestampData) {
            if (timestampData is Map) {
              final timestampStr = timestampKey.toString();
              if (latestTimestamp == null ||
                  timestampStr.compareTo(latestTimestamp!) > 0) {
                latestTimestamp = timestampStr;
                latestData = timestampData as Map<Object?, Object?>;
              }
            }
          });

          if (latestData != null && latestTimestamp != null) {
            try {
              final busDataObj = BusData.fromFirebase(
                busId.toString(),
                latestTimestamp!,
                latestData!,
              );
              nearbyBuses.add({
                "id": busDataObj.id,
                "latitude": busDataObj.latitude,
                "longitude": busDataObj.longitude,
                "altitude": busDataObj.altitude,
                "speed": busDataObj.speed,
                "timestamp": busDataObj.timestamp,
              });
              print(
                "✅ Loaded bus: ${busDataObj.id} - Time: ${busDataObj.timestamp}",
              );
            } catch (e) {
              print("❌ Error processing bus $busId: $e");
            }
          }
        }
      });

      if (currentState is MapLoaded) {
        emit(
          MapLoaded(position: currentState.position, nearbyBuses: nearbyBuses),
        );
      } else {
        emit(MapError("Failed to load map state"));
      }
    } catch (e) {
      emit(MapError("Error fetching nearby buses: ${e.toString()}"));
    }
  }

  void _onSubscribeToBusUpdates(
    SubscribeToBusUpdates event,
    Emitter<MapState> emit,
  ) {
    // Cancel any existing subscription
    _busSubscription?.cancel();
    _periodicTimer?.cancel();

    print("🔔 Setting up real-time Firebase subscription...");
    // First, get initial data to know which buses exist
    _busRef.get().then((snapshot) {
      if (snapshot.value != null && snapshot.value is Map) {
        print("🔍 Setting up listeners for existing buses");

        // Listen specifically to the Arduino payload path
        final busPayloadRef = _busRef
            .child('bus_one')
            .child('location')
            .child('payload');

        final payloadListener = busPayloadRef.onValue.listen((
          DatabaseEvent event,
        ) {
          print("📡 Arduino payload update detected at ${DateTime.now()}");
          final snapshot = event.snapshot;

          if (snapshot.value != null && snapshot.value is Map) {
            print("🚌 Processing Arduino payload update");
            _processArduinoPayload(snapshot.value as Map<Object?, Object?>);
          }
        });

        _individualBusListeners.add(payloadListener);
      }
    });

    // Also set up the main listener as backup
    _busSubscription = _busRef.onValue.listen(
      (DatabaseEvent event) {
        print("📡 Main Firebase listener triggered at ${DateTime.now()}");
        final snapshot = event.snapshot;

        if (snapshot.value != null && snapshot.value is Map) {
          _processFirebaseUpdate(snapshot.value as Map<Object?, Object?>);
        }
      },
      onError: (error) {
        print("❌ Firebase subscription error: $error");
        emit(MapError("Real-time update error: ${error.toString()}"));
      },
    );

    // Aggressive periodic check every 2 seconds to ensure we catch updates
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_busSubscription == null) {
        timer.cancel();
        return;
      }
      print("🔄 Aggressive periodic check for Firebase updates...");
      _busRef
          .get()
          .then((snapshot) {
            if (snapshot.value != null && snapshot.value is Map) {
              _processFirebaseUpdate(snapshot.value as Map<Object?, Object?>);
            }
          })
          .catchError((error) {
            print("❌ Periodic check error: $error");
          });
    });
  }

  void _processFirebaseUpdate(Map<Object?, Object?> data) {
    List<Map<String, dynamic>> updatedBuses = [];

    print("🚌 Processing ${data.keys.length} bus entries");

    // Iterate through each bus (e.g., "bus_one", "bus_two", etc.)
    data.forEach((busId, busData) {
      if (busData is Map && busData.containsKey('location')) {
        final locationData = busData['location'] as Map<Object?, Object?>;

        print(
          "📍 Bus $busId has ${locationData.keys.length} timestamp entries",
        );

        // Get all timestamp keys and sort them
        List<String> timestampKeys =
            locationData.keys.map((key) => key.toString()).toList();
        timestampKeys.sort((a, b) => b.compareTo(a)); // Sort newest first

        print("📊 All timestamps for $busId: ${timestampKeys.join(', ')}");

        if (timestampKeys.isNotEmpty) {
          final latestTimestamp = timestampKeys.first;
          final latestData =
              locationData[latestTimestamp] as Map<Object?, Object?>;

          print("⏰ Using latest timestamp for $busId: $latestTimestamp");

          try {
            final busDataObj = BusData.fromFirebase(
              busId.toString(),
              latestTimestamp,
              latestData,
            );

            // Check if this is actually new data compared to what we had before
            final previousData = previousBusData[busId.toString()];
            bool isNewData =
                previousData == null ||
                previousData.timestamp != busDataObj.timestamp ||
                previousData.latitude != busDataObj.latitude ||
                previousData.longitude != busDataObj.longitude ||
                previousData.speed != busDataObj.speed;

            if (isNewData) {
              print("🆕 NEW DATA detected for $busId!");
              print("   Previous: ${previousData?.timestamp ?? 'None'}");
              print("   Current:  ${busDataObj.timestamp}");
            }

            updatedBuses.add({
              "id": busDataObj.id,
              "latitude": busDataObj.latitude,
              "longitude": busDataObj.longitude,
              "altitude": busDataObj.altitude,
              "speed": busDataObj.speed,
              "timestamp": busDataObj.timestamp,
            });

            // Update our tracking
            previousBusData[busId.toString()] = busDataObj;

            print(
              "✅ Processed bus: ${busDataObj.id} at ${busDataObj.latitude}, ${busDataObj.longitude} - Speed: ${busDataObj.speed} km/h - Time: ${busDataObj.timestamp}",
            );
          } catch (e) {
            print("❌ Error processing bus $busId: $e");
          }
        }
      } else {
        print("⚠️ Bus $busId has no location data");
      }
    });

    print("🔄 Updating ${updatedBuses.length} buses in real-time");

    // Always update even if no new data to refresh the UI
    add(UpdateBusLocations(updatedBuses));
  }

  void _onUpdateBusLocations(UpdateBusLocations event, Emitter<MapState> emit) {
    print("🔄 Processing bus location updates for ${event.buses.length} buses");

    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      List<Map<String, dynamic>> updatedBusesWithETA = [];
      final now = DateTime.now();

      for (var bus in event.buses) {
        String id = bus["id"];
        double currentLat = bus["latitude"];
        double currentLon = bus["longitude"];
        double altitude = bus["altitude"];
        double speed = bus["speed"];
        String timestamp = bus["timestamp"];

        double? speedKmPerSec;
        double realTimeSpeedKmh = speed; // Use GPS speed from Firebase

        // Convert GPS speed from km/h to km/sec for ETA calculation
        if (realTimeSpeedKmh > 0) {
          speedKmPerSec = realTimeSpeedKmh / 3600; // Convert km/h to km/sec
        }

        // Also calculate speed from position changes as backup
        if (previousTimestamps.containsKey(id) &&
            previousBusData.containsKey(id)) {
          final prevData = previousBusData[id]!;
          final prevTimestamp = previousTimestamps[id]!;
          double distance = calculateDistance(
            prevData.latitude,
            prevData.longitude,
            currentLat,
            currentLon,
          );
          int timeDiffSec = now.difference(prevTimestamp).inSeconds;
          if (timeDiffSec > 0) {
            double calculatedSpeedKmSec = distance / timeDiffSec;
            // Use the higher of GPS speed or calculated speed for better accuracy
            if (speedKmPerSec == null || calculatedSpeedKmSec > speedKmPerSec) {
              speedKmPerSec = calculatedSpeedKmSec;
            }
          }
        }

        previousBusData[id] = BusData(
          id: id,
          latitude: currentLat,
          longitude: currentLon,
          altitude: altitude,
          speed: speed,
          timestamp: timestamp,
        );
        previousTimestamps[id] = now;

        double remainingDistance = calculateDistance(
          currentLat,
          currentLon,
          currentState.position.latitude,
          currentState.position.longitude,
        );

        if (remainingDistance < 1.0 && !notifiedBuses.contains(id)) {
          NotificationService.showNotification(
            "Bus is Near!",
            "Bus $id is within 1km of your location!",
          );
          notifiedBuses.add(id); // ✅ Avoid duplicate notifications
        }

        String eta;
        String speedDisplay;

        if (speedKmPerSec != null && speedKmPerSec > 0) {
          // Calculate ETA based on current speed
          double etaSeconds = remainingDistance / speedKmPerSec;

          if (etaSeconds < 60) {
            eta = "${etaSeconds.toStringAsFixed(0)} sec";
          } else if (etaSeconds < 3600) {
            double etaMinutes = etaSeconds / 60;
            eta = "${etaMinutes.toStringAsFixed(1)} min";
          } else {
            double etaHours = etaSeconds / 3600;
            eta = "${etaHours.toStringAsFixed(1)} hr";
          }

          // Show both GPS speed and calculated speed
          double speedKmh = speedKmPerSec * 3600;
          speedDisplay = "${speedKmh.toStringAsFixed(1)} km/h";
        } else if (realTimeSpeedKmh > 0) {
          // Use GPS speed even if we can't calculate position-based speed
          double etaSeconds = remainingDistance / (realTimeSpeedKmh / 3600);

          if (etaSeconds < 60) {
            eta = "${etaSeconds.toStringAsFixed(0)} sec";
          } else if (etaSeconds < 3600) {
            double etaMinutes = etaSeconds / 60;
            eta = "${etaMinutes.toStringAsFixed(1)} min";
          } else {
            double etaHours = etaSeconds / 3600;
            eta = "${etaHours.toStringAsFixed(1)} hr";
          }

          speedDisplay = "${realTimeSpeedKmh.toStringAsFixed(1)} km/h (GPS)";
        } else {
          eta = "Stopped";
          speedDisplay = "0.0 km/h";
        }

        String distanceStr = "${remainingDistance.toStringAsFixed(2)} km";

        updatedBusesWithETA.add({
          "id": id,
          "latitude": currentLat,
          "longitude": currentLon,
          "altitude": altitude,
          "speed": speed,
          "speedDisplay": speedDisplay,
          "timestamp": timestamp,
          "eta": eta,
          "distance": distanceStr,
        });
      }

      print(
        "✅ Emitting updated state with ${updatedBusesWithETA.length} buses",
      );
      emit(
        MapLoaded(
          position: currentState.position,
          nearbyBuses: updatedBusesWithETA,
        ),
      );
    } else {
      print("⚠️ State is not MapLoaded, current state: ${state.runtimeType}");
    }
  }

  void _processArduinoPayload(Map<Object?, Object?> payloadData) {
    print("🤖 Processing Arduino payload data");

    try {
      // Create BusData from Arduino payload
      final busData = BusData(
        id: "bus_one",
        latitude: (payloadData['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (payloadData['lng'] as num?)?.toDouble() ?? 0.0,
        altitude: (payloadData['alt'] as num?)?.toDouble() ?? 0.0,
        speed: (payloadData['speed'] as num?)?.toDouble() ?? 0.0,
        timestamp: payloadData['timestamp'] as String? ?? 'Unknown',
      );

      // Check if this is new data
      final previousData = previousBusData["bus_one"];
      bool isNewData =
          previousData == null ||
          previousData.timestamp != busData.timestamp ||
          previousData.latitude != busData.latitude ||
          previousData.longitude != busData.longitude ||
          previousData.speed != busData.speed;

      if (isNewData) {
        print("🆕 NEW Arduino data detected!");
        print("   Previous: ${previousData?.timestamp ?? 'None'}");
        print("   Current:  ${busData.timestamp}");

        List<Map<String, dynamic>> updatedBuses = [
          {
            "id": busData.id,
            "latitude": busData.latitude,
            "longitude": busData.longitude,
            "altitude": busData.altitude,
            "speed": busData.speed,
            "timestamp": busData.timestamp,
          },
        ];

        print(
          "✅ Arduino data: ${busData.id} at ${busData.latitude}, ${busData.longitude} - Speed: ${busData.speed} km/h - Time: ${busData.timestamp}",
        );

        // Update our tracking
        previousBusData["bus_one"] = busData;

        // Trigger UI update
        add(UpdateBusLocations(updatedBuses));
      } else {
        print("📊 Same Arduino data, no update needed");
      }
    } catch (e) {
      print("❌ Error processing Arduino payload: $e");
    }
  }

  @override
  Future<void> close() {
    _busSubscription?.cancel();
    _periodicTimer?.cancel();
    for (var listener in _individualBusListeners) {
      listener.cancel();
    }
    _individualBusListeners.clear();
    return super.close();
  }
}
