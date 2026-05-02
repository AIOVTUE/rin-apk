import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/moment.dart';
import '../services/api_client.dart';

@immutable
class MomentsState {
  const MomentsState({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<Moment> items;
  final bool isLoading;
  final String? errorMessage;

  static const initial = MomentsState(items: <Moment>[], isLoading: false, errorMessage: null);

  MomentsState copyWith({List<Moment>? items, bool? isLoading, String? errorMessage}) {
    return MomentsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MomentsNotifier extends Notifier<MomentsState> {
  @override
  MomentsState build() => MomentsState.initial;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.moments.list();
      final items = raw
          .whereType<Map>()
          .map((e) => Moment.fromJson(e.cast<String, dynamic>()))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> create({required String content}) async {
    final api = ref.read(apiClientProvider);
    await api.moments.create({'content': content});
    await refresh();
  }

  Future<void> update({required String id, required String content}) async {
    final api = ref.read(apiClientProvider);
    await api.moments.update(id, {'content': content});
    await refresh();
  }

  Future<void> delete(String id) async {
    final api = ref.read(apiClientProvider);
    await api.moments.delete(id);
    await refresh();
  }
}

final momentsProvider = NotifierProvider<MomentsNotifier, MomentsState>(
  MomentsNotifier.new,
);

