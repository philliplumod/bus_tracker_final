import '../../domain/entities/terminal.dart';

/// API model for Terminal from /api/terminals
class ApiTerminalModel {
  final String terminalId;
  final String terminalName;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApiTerminalModel({
    required this.terminalId,
    required this.terminalName,
    required this.latitude,
    required this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiTerminalModel.fromJson(Map<String, dynamic> json) {
    return ApiTerminalModel(
      terminalId: json['terminal_id'] as String,
      terminalName: json['terminal_name'] as String,
      latitude: _parseNumeric(json['latitude']),
      longitude: _parseNumeric(json['longitude']),
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
      'terminal_id': terminalId,
      'terminal_name': terminalName,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Terminal toEntity() {
    return Terminal(
      id: terminalId,
      name: terminalName,
      latitude: latitude,
      longitude: longitude,
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
