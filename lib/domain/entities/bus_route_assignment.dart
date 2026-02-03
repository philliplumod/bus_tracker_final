import 'package:equatable/equatable.dart';

class BusRouteAssignment extends Equatable {
  final String id; // bus_route_id from bus_routes table
  final String busId;
  final String routeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusRouteAssignment({
    required this.id,
    required this.busId,
    required this.routeId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'bus_route_id': id,
      'bus_id': busId,
      'route_id': routeId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BusRouteAssignment.fromJson(Map<String, dynamic> json) {
    return BusRouteAssignment(
      id: json['bus_route_id'] as String,
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
    );
  }

  BusRouteAssignment copyWith({
    String? id,
    String? busId,
    String? routeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusRouteAssignment(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, busId, routeId, createdAt, updatedAt];
}
