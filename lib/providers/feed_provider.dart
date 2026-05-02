import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_item.dart';
import '../services/api_client.dart';

enum FeedListFilter { listed, unlisted }

@immutable
class FeedListState {
  const FeedListState({
    required this.filter,
    required this.items,
    required this.page,
    required this.isLoading,
    required this.hasMore,
    required this.errorMessage,
  });

  final FeedListFilter filter;
  final List<FeedItem> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  FeedListState copyWith({
    FeedListFilter? filter,
    List<FeedItem>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
  }) {
    return FeedListState(
      filter: filter ?? this.filter,
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  static const initial = FeedListState(
    filter: FeedListFilter.listed,
    items: <FeedItem>[],
    page: 1,
    isLoading: false,
    hasMore: true,
    errorMessage: null,
  );
}

class FeedListNotifier extends Notifier<FeedListState> {
  @override
  FeedListState build() => FeedListState.initial;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, page: 1, hasMore: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final type = state.filter == FeedListFilter.unlisted ? 'unlisted' : 'normal';
      final raw = await api.feed.feed(page: 1, type: type);
      final items = raw
          .whereType<Map>()
          .map((e) => FeedItem.fromJson(e.cast<String, dynamic>()))
          .toList();
      final seen = <String>{};
      final unique = <FeedItem>[];
      for (final it in items) {
        if (it.id.isEmpty) continue;
        if (seen.add(it.id)) unique.add(it);
      }
      state = state.copyWith(
        items: unique,
        page: 1,
        isLoading: false,
        hasMore: unique.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final nextPage = state.page + 1;
      final type = state.filter == FeedListFilter.unlisted ? 'unlisted' : 'normal';
      final raw = await api.feed.feed(page: nextPage, type: type);
      final more = raw
          .whereType<Map>()
          .map((e) => FeedItem.fromJson(e.cast<String, dynamic>()))
          .toList();
      final existingIds = state.items.map((e) => e.id).where((e) => e.isNotEmpty).toSet();
      final uniqueMore = <FeedItem>[];
      for (final it in more) {
        if (it.id.isEmpty) continue;
        if (existingIds.add(it.id)) uniqueMore.add(it);
      }
      state = state.copyWith(
        items: [...state.items, ...uniqueMore],
        page: nextPage,
        isLoading: false,
        hasMore: uniqueMore.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> setFilter(FeedListFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    await refresh();
  }
}

final feedListProvider = NotifierProvider<FeedListNotifier, FeedListState>(
  FeedListNotifier.new,
);

