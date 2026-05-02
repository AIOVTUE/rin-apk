import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage.dart';
import '../utils/prefs_keys.dart';
import 'storage_provider.dart';

@immutable
class ThemeState {
  const ThemeState({
    required this.themeMode,
    required this.seedColor,
  });

  final ThemeMode themeMode;
  final Color seedColor;

  ThemeState copyWith({ThemeMode? themeMode, Color? seedColor}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

ThemeMode _parseThemeMode(String? raw) {
  switch (raw) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _encodeThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

class ThemeNotifier extends AsyncNotifier<ThemeState> {
  late final LocalStorage _storage;

  @override
  Future<ThemeState> build() async {
    _storage = await ref.watch(localStorageProvider.future);
    final mode = _parseThemeMode(_storage.getString(PrefsKeys.themeMode));
    final seedValue = _storage.getInt(PrefsKeys.themeSeedColor) ?? Colors.indigo.toARGB32();
    return ThemeState(themeMode: mode, seedColor: Color(seedValue));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.setString(PrefsKeys.themeMode, _encodeThemeMode(mode));
    state = AsyncData((state.value ?? await build()).copyWith(themeMode: mode));
  }

  Future<void> setSeedColor(Color color) async {
    await _storage.setInt(PrefsKeys.themeSeedColor, color.toARGB32());
    state = AsyncData((state.value ?? await build()).copyWith(seedColor: color));
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

