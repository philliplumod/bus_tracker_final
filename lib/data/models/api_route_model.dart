import '../../domain/entities/route.dart';
import 'api_terminal_model.dart';

/// API model for Route from /api/routes
class ApiRouteModel {
  final String routeId;
  final String routeName;
  final String? startingTerminalId;
  final String? destinationTerminalId;
  final double? distanceKm;
  final int? durationMinutes;
  final Map<String, dynamic>? routeData;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ApiTerminalModel? startingTerminal;
  final ApiTerminalModel? destinationTerminal;

  ApiRouteModel({
    required this.routeId,
    required this.routeName,
    this.startingTerminalId,
    this.destinationTerminalId,
    this.distanceKm,
    this.durationMinutes,
    this.routeData,
    this.createdAt,
    this.updatedAt,
    this.startingTerminal,
    this.destinationTerminal,
  });

  factory ApiRouteModel.fromJson(Map<String, dynamic> json) {
    // Parse terminals first to potentially extract IDs from them
    ApiTerminalModel? startingTerm;
    ApiTerminalModel? destTerm;

    if (json['starting_terminal'] != null) {
      startingTerm = ApiTerminalModel.fromJson(
        Map<String, dynamic>.from(json['starting_terminal'] as Map),
      );
    }

    if (json['destination_terminal'] != null) {
      destTerm = ApiTerminalModel.fromJson(
        Map<String, dynamic>.from(json['destination_terminal'] as Map),
      );
    }

    // Get terminal IDs from either direct fields or nested terminal objects
    final String startingTerminalId =
        (json['starting_terminal_id'] as String?) ??
        startingTerm?.terminalId ??
        '';

    final String destinationTerminalId =
        (json['destination_terminal_id'] as String?) ??
        destTerm?.terminalId ??
        '';

    return ApiRouteModel(
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      startingTerminalId: startingTerminalId,
      destinationTerminalId: destinationTerminalId,
      distanceKm:
          json['distance_km'] != null
              ? _parseNumeric(json['distance_km'])
              : null,
      durationMinutes: json['duration_minutes'] as int?,
      routeData:
          json['route_data'] != null
              ? Map<String, dynamic>.from(json['route_data'] as Map)
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      startingTerminal: startingTerm,
      destinationTerminal: destTerm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'route_name': routeName,
      'starting_terminal_id': startingTerminalId,
      'destination_terminal_id': destinationTerminalId,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'route_data': routeData,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'starting_terminal': startingTerminal?.toJson(),
      'destination_terminal': destinationTerminal?.toJson(),
    };
  }

  /// Convert to domain entity
  BusRoute toEntity() {
    if (startingTerminal == null || destinationTerminal == null) {
      throw StateError('Terminals must be loaded to convert to entity');
    }

    // Parse waypoints from route_data
    List<Map<String, dynamic>>? waypoints;
    if (routeData != null && routeData!['waypoints'] != null) {
      final waypointsData = routeData!['waypoints'];
      if (waypointsData is List) {
        waypoints =
            waypointsData
                .map((w) => Map<String, dynamic>.from(w as Map))
                .toList();
      }
    }

    return BusRoute(
      id: routeId,
      name: routeName,
      startingTerminal: startingTerminal!.toEntity(),
      destinationTerminal: destinationTerminal!.toEntity(),
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      routeData: waypoints,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _parseNumeric(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Invalid numeric value: $value');
  }
}
