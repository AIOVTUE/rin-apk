import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage.dart';
import '../utils/prefs_keys.dart';
import 'storage_provider.dart';

@immutable
class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.showMoments,
    required this.showFriend,
  });

  final String baseUrl;
  final bool showMoments;
  final bool showFriend;

  AppSettings copyWith({
    String? baseUrl,
    bool? showMoments,
    bool? showFriend,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      showMoments: showMoments ?? this.showMoments,
      showFriend: showFriend ?? this.showFriend,
    );
  }
}

const kDefaultDemoBaseUrl = 'https://demo.rin-blog.com/';

String _normalizeBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return kDefaultDemoBaseUrl;
  final withScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  return withScheme.endsWith('/') ? withScheme : '$withScheme/';
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late final LocalStorage _storage;

  @override
  Future<AppSettings> build() async {
    _storage = await ref.watch(localStorageProvider.future);
    final baseUrl = _normalizeBaseUrl(
      _storage.getString(PrefsKeys.baseUrl) ?? kDefaultDemoBaseUrl,
    );
    final showMoments = _storage.getBool(PrefsKeys.showMoments) ?? true;
    final showFriend = _storage.getBool(PrefsKeys.showFriend) ?? true;
    return AppSettings(
      baseUrl: baseUrl,
      showMoments: showMoments,
      showFriend: showFriend,
    );
  }

  Future<void> setBaseUrl(String baseUrl) async {
    final next = _normalizeBaseUrl(baseUrl);
    await _storage.setString(PrefsKeys.baseUrl, next);
    state = AsyncData((state.value ?? await build()).copyWith(baseUrl: next));
  }

  Future<void> setShowMoments(bool value) async {
    await _storage.setBool(PrefsKeys.showMoments, value);
    state = AsyncData((state.value ?? await build()).copyWith(showMoments: value));
  }

  Future<void> setShowFriend(bool value) async {
    await _storage.setBool(PrefsKeys.showFriend, value);
    state = AsyncData((state.value ?? await build()).copyWith(showFriend: value));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

