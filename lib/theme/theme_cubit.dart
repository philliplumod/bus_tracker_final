import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'theme_state.dart';

class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  void toggleTheme() {
    final newMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: newMode));
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  void setLightMode() {
    emit(state.copyWith(themeMode: ThemeMode.light));
  }

  void setDarkMode() {
    emit(state.copyWith(themeMode: ThemeMode.dark));
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      return ThemeState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }
}
