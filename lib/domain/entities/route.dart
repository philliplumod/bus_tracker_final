import 'package:equatable/equatable.dart';
import 'terminal.dart';

class BusRoute extends Equatable {
  final String id;
  final String name;
  final Terminal startingTerminal;
  final Terminal destinationTerminal;
  final double? distanceKm;
  final int? durationMinutes;
  final List<Map<String, dynamic>>?
  routeData; // Polyline coordinates or waypoints
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusRoute({
    required this.id,
    required this.name,
    required this.startingTerminal,
    required this.destinationTerminal,
    this.distanceKm,
    this.durationMinutes,
    this.routeData,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'route_id': id,
      'route_name': name,
      'starting_terminal_id': startingTerminal.id,
      'destination_terminal_id': destinationTerminal.id,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'route_data': routeData,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BusRoute.fromJson(
    Map<String, dynamic> json,
    Terminal startingTerminal,
    Terminal destinationTerminal,
  ) {
    return BusRoute(
      id: json['route_id'] as String,
      name: json['route_name'] as String,
      startingTerminal: startingTerminal,
      destinationTerminal: destinationTerminal,
      distanceKm:
          json['distance_km'] != null
              ? (json['distance_km'] as num).toDouble()
              : null,
      durationMinutes: json['duration_minutes'] as int?,
      routeData:
          json['route_data'] != null
              ? (json['route_data'] as List).cast<Map<String, dynamic>>()
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  BusRoute copyWith({
    String? id,
    String? name,
    Terminal? startingTerminal,
    Terminal? destinationTerminal,
    double? distanceKm,
    int? durationMinutes,
    List<Map<String, dynamic>>? routeData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      startingTerminal: startingTerminal ?? this.startingTerminal,
      destinationTerminal: destinationTerminal ?? this.destinationTerminal,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      routeData: routeData ?? this.routeData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get routeDisplayText =>
      '$name: ${startingTerminal.name} → ${destinationTerminal.name}';

  String? get durationText {
    if (durationMinutes == null) return null;
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? "$minutes min" : ""}';
    }
    return '$minutes min';
  }

  String? get distanceText {
    if (distanceKm == null) return null;
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    startingTerminal,
    destinationTerminal,
    distanceKm,
    durationMinutes,
    routeData,
    createdAt,
    updatedAt,
  ];
}
