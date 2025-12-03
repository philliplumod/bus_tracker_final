import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.light});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  @override
  List<Object> get props => [themeMode];

  // Serialization for persistence
  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.index};
  }

  factory ThemeState.fromJson(Map<String, dynamic> json) {
    return ThemeState(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
    );
  }
}
