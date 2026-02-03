import 'package:equatable/equatable.dart';

class BusRouteAssignment extends Equatable {
  final String id; // bus_route_id from bus_routes table
  final String busId;
  final String? busName;
  final String routeId;
  final String? routeName;
  final String? startingTerminalId;
  final String? startingTerminalName;
  final String? destinationTerminalId;
  final String? destinationTerminalName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusRouteAssignment({
    required this.id,
    required this.busId,
    this.busName,
    required this.routeId,
    this.routeName,
    this.startingTerminalId,
    this.startingTerminalName,
    this.destinationTerminalId,
    this.destinationTerminalName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'bus_route_id': id,
      'bus_id': busId,
      'bus_name': busName,
      'route_id': routeId,
      'route_name': routeName,
      'starting_terminal_id': startingTerminalId,
      'starting_terminal_name': startingTerminalName,
      'destination_terminal_id': destinationTerminalId,
      'destination_terminal_name': destinationTerminalName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BusRouteAssignment.fromJson(Map<String, dynamic> json) {
    return BusRouteAssignment(
      id: json['bus_route_id'] as String,
      busId: json['bus_id'] as String,
      busName: json['bus_name'] as String?,
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String?,
      startingTerminalId: json['starting_terminal_id'] as String?,
      startingTerminalName: json['starting_terminal_name'] as String?,
      destinationTerminalId: json['destination_terminal_id'] as String?,
      destinationTerminalName: json['destination_terminal_name'] as String?,
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

  BusRouteAssignment copyWith({
    String? id,
    String? busId,
    String? busName,
    String? routeId,
    String? routeName,
    String? startingTerminalId,
    String? startingTerminalName,
    String? destinationTerminalId,
    String? destinationTerminalName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusRouteAssignment(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      busName: busName ?? this.busName,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      startingTerminalId: startingTerminalId ?? this.startingTerminalId,
      startingTerminalName: startingTerminalName ?? this.startingTerminalName,
      destinationTerminalId:
          destinationTerminalId ?? this.destinationTerminalId,
      destinationTerminalName:
          destinationTerminalName ?? this.destinationTerminalName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    busId,
    busName,
    routeId,
    routeName,
    startingTerminalId,
    startingTerminalName,
    destinationTerminalId,
    destinationTerminalName,
    createdAt,
    updatedAt,
  ];
}
