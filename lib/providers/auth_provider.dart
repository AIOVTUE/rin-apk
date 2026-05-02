import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage.dart';
import '../utils/prefs_keys.dart';
import 'storage_provider.dart';

class AuthNotifier extends AsyncNotifier<String?> {
  late final LocalStorage _storage;

  @override
  Future<String?> build() async {
    _storage = await ref.watch(localStorageProvider.future);
    return _storage.getString(PrefsKeys.token);
  }

  Future<void> setToken(String token) async {
    await _storage.setString(PrefsKeys.token, token);
    state = AsyncData(token);
  }

  Future<void> clearToken() async {
    await _storage.remove(PrefsKeys.token);
    state = const AsyncData(null);
  }
}

final authTokenProvider = AsyncNotifierProvider<AuthNotifier, String?>(
  AuthNotifier.new,
);

