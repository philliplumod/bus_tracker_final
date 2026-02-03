import '../../domain/entities/bus_route_assignment.dart';
import 'api_bus_model.dart';
import 'api_route_model.dart';

/// API model for BusRoute from /api/bus-routes
class ApiBusRouteModel {
  final String busRouteId;
  final String busId;
  final String routeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ApiBusModel? bus;
  final ApiRouteModel? route;

  ApiBusRouteModel({
    required this.busRouteId,
    required this.busId,
    required this.routeId,
    this.createdAt,
    this.updatedAt,
    this.bus,
    this.route,
  });

  factory ApiBusRouteModel.fromJson(Map<String, dynamic> json) {
    return ApiBusRouteModel(
      busRouteId: json['bus_route_id'] as String,
      busId: json['bus_id'] as String,
      routeId: json['route_id'] as String,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      bus:
          json['bus'] != null
              ? ApiBusModel.fromJson(
                Map<String, dynamic>.from(json['bus'] as Map),
              )
              : null,
      route:
          json['route'] != null
              ? ApiRouteModel.fromJson(
                Map<String, dynamic>.from(json['route'] as Map),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_route_id': busRouteId,
      'bus_id': busId,
      'route_id': routeId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'bus': bus?.toJson(),
      'route': route?.toJson(),
    };
  }

  /// Convert to domain entity
  BusRouteAssignment toEntity() {
    if (bus == null || route == null) {
      throw StateError('Bus and route must be loaded to convert to entity');
    }

    return BusRouteAssignment(
      id: busRouteId,
      busId: busId,
      busName: bus!.busName,
      routeId: routeId,
      routeName: route!.routeName,
      startingTerminalId: route!.startingTerminalId,
      destinationTerminalId: route!.destinationTerminalId,
      startingTerminalName: route!.startingTerminal?.terminalName,
      destinationTerminalName: route!.destinationTerminal?.terminalName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
