import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_link.dart';
import '../models/friend_list_response.dart';
import '../services/api_client.dart';

@immutable
class FriendState {
  const FriendState({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<FriendLink> items;
  final bool isLoading;
  final String? errorMessage;

  static const initial = FriendState(items: <FriendLink>[], isLoading: false, errorMessage: null);

  FriendState copyWith({List<FriendLink>? items, bool? isLoading, String? errorMessage}) {
    return FriendState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FriendNotifier extends Notifier<FriendState> {
  @override
  FriendState build() => FriendState.initial;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.friend.list();
      final resp = FriendListResponse.fromAny(raw);
      final items = resp.list.map(FriendLink.fromJson).toList();
      debugPrint('[FriendProvider] parsed friends count=${items.length}');
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> create({
    required String name,
    required String url,
    String? avatar,
    String? desc,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.friend.create({
      'name': name,
      'url': url,
      if (avatar?.isNotEmpty ?? false) 'avatar': avatar,
      if (desc?.isNotEmpty ?? false) 'desc': desc,
    });
    await refresh();
  }

  Future<void> update({
    required String id,
    required String name,
    required String url,
    String? avatar,
    String? desc,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.friend.update(id, {
      'name': name,
      'url': url,
      if (avatar?.isNotEmpty ?? false) 'avatar': avatar,
      if (desc?.isNotEmpty ?? false) 'desc': desc,
    });
    await refresh();
  }

  Future<void> delete(String id) async {
    final api = ref.read(apiClientProvider);
    await api.friend.delete(id);
    await refresh();
  }
}

final friendProvider = NotifierProvider<FriendNotifier, FriendState>(
  FriendNotifier.new,
);

