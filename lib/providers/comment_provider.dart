import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../services/api_client.dart';

@immutable
class CommentState {
  const CommentState({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<Comment> items;
  final bool isLoading;
  final String? errorMessage;

  static const initial = CommentState(items: <Comment>[], isLoading: false, errorMessage: null);

  CommentState copyWith({List<Comment>? items, bool? isLoading, String? errorMessage}) {
    return CommentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CommentNotifier extends FamilyNotifier<CommentState, String> {
  @override
  CommentState build(String feedId) => CommentState.initial;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.comment.list(arg);
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => Comment.fromJson(e))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> create(String content) async {
    final api = ref.read(apiClientProvider);
    await api.comment.create(arg, content);
    await refresh();
  }

  Future<void> delete(String id) async {
    final api = ref.read(apiClientProvider);
    await api.comment.delete(id);
    await refresh();
  }
}

final commentProvider = NotifierProvider.family<CommentNotifier, CommentState, String>(
  CommentNotifier.new,
);