import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage.dart';

final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  return LocalStorage.create();
});

