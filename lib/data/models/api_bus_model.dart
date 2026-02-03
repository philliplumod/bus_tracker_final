import '../../domain/entities/bus.dart';

/// API model for Bus from /api/buses
class ApiBusModel {
  final String busId;
  final String busName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApiBusModel({
    required this.busId,
    required this.busName,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiBusModel.fromJson(Map<String, dynamic> json) {
    return ApiBusModel(
      busId: json['bus_id'] as String,
      busName: json['bus_name'] as String,
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

  Map<String, dynamic> toJson() {
    return {
      'bus_id': busId,
      'bus_name': busName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Bus toEntity() {
    return Bus(
      id: busId,
      name: busName,
      busNumber: busName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
