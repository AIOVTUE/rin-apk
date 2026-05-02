import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../services/api_client.dart';
import '../utils/ui.dart';
import 'feed_detail_page.dart';
import 'feed_editor_page.dart';

class FeedListPage extends ConsumerStatefulWidget {
  const FeedListPage({super.key});

  @override
  ConsumerState<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends ConsumerState<FeedListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(feedListProvider.notifier).refresh());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(feedListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await Ui.confirm(
      context,
      title: '确认删除？',
      content: '删除后不可恢复。',
      confirmText: '删除',
    );
    if (!ok) return;
    try {
      await ref.read(apiClientProvider).feed.delete(id);
      if (!context.mounted) return;
      Ui.toast(context, '已删除');
      await ref.read(feedListProvider.notifier).refresh();
    } catch (e) {
      if (!context.mounted) return;
      Ui.toast(context, e.toString());
    }
  }

  Future<void> _share(BuildContext context, {required String id, required String? url}) async {
    final apiBase = ref.read(apiClientProvider).dio.options.baseUrl;
    final value = url?.isNotEmpty == true ? url! : '${apiBase}feed/$id';
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    Ui.toast(context, '已复制链接到剪贴板');
  }

  Future<void> _toggleTop(BuildContext context, String id, bool isTopped) async {
    try {
      await ref.read(apiClientProvider).feed.top(id, top: isTopped ? 0 : 1);
      if (!context.mounted) return;
      Ui.toast(context, isTopped ? '已取消置顶' : '已置顶');
      await ref.read(feedListProvider.notifier).refresh();
    } catch (e) {
      if (!context.mounted) return;
      Ui.toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedListProvider);
    final notifier = ref.read(feedListProvider.notifier);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final compactTopBar = width < 780;

    return Scaffold(
      appBar: AppBar(
        title: const Text('文章'),
        actions: [
          if (compactTopBar)
            PopupMenuButton<FeedListFilter>(
              tooltip: '筛选',
              icon: const Icon(Icons.filter_list),
              onSelected: notifier.setFilter,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: FeedListFilter.listed,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.visibility),
                    title: Text('展示'),
                  ),
                ),
                PopupMenuItem(
                  value: FeedListFilter.unlisted,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.visibility_off),
                    title: Text('未展示'),
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SegmentedButton<FeedListFilter>(
                segments: const [
                  ButtonSegment(value: FeedListFilter.listed, label: Text('展示'), icon: Icon(Icons.visibility)),
                  ButtonSegment(value: FeedListFilter.unlisted, label: Text('未展示'), icon: Icon(Icons.visibility_off)),
                ],
                selected: {state.filter},
                onSelectionChanged: (s) => notifier.setFilter(s.first),
              ),
            ),
          IconButton(
            tooltip: '新建',
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const FeedEditorPage()),
              );
              if (ok == true) {
                await notifier.refresh();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: state.items.isEmpty && state.isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : state.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('暂无文章')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == state.items.length) {
                        if (state.isLoading) return const SizedBox(height: 24);
                        if (!state.hasMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('没有更多了')),
                          );
                        }
                        return const SizedBox(height: 64);
                      }

                      final item = state.items[i];
                      final date = item.createdAt;
                      final summary = item.summary.trim().isNotEmpty
                          ? item.summary.trim()
                          : item.content.replaceAll('\n', ' ').trim();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: item.isTop ? 4 : 2,
                          color: item.isTop ? theme.colorScheme.surfaceContainerHighest : null,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => FeedDetailPage(id: item.id)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title.isEmpty ? '(无标题)' : item.title,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<_FeedAction>(
                                        tooltip: '更多',
                                        onSelected: (action) async {
                                          switch (action) {
                                            case _FeedAction.edit:
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => FeedEditorPage(id: item.id),
                                                ),
                                              );
                                              await notifier.refresh();
                                              break;
                                            case _FeedAction.preview:
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => FeedDetailPage(id: item.id),
                                                ),
                                              );
                                              break;
                                            case _FeedAction.delete:
                                              await _delete(context, item.id);
                                              break;
                                            case _FeedAction.share:
                                              await _share(context, id: item.id, url: item.url);
                                              break;
                                            case _FeedAction.pin:
                                              await _toggleTop(context, item.id, false);
                                              break;
                                            case _FeedAction.unpin:
                                              await _toggleTop(context, item.id, true);
                                              break;
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: _FeedAction.edit, child: Text('编辑')),
                                          const PopupMenuItem(value: _FeedAction.preview, child: Text('预览')),
                                          if (!item.isTop)
                                            const PopupMenuItem(value: _FeedAction.pin, child: Text('置顶')),
                                          if (item.isTop)
                                            const PopupMenuItem(value: _FeedAction.unpin, child: Text('取消置顶')),
                                          const PopupMenuItem(value: _FeedAction.delete, child: Text('删除')),
                                          const PopupMenuItem(value: _FeedAction.share, child: Text('分享')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (date != null || item.tags.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (date != null)
                                          Text(
                                            '${date.toLocal()}'.split('.').first,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        for (final tag in item.tags)
                                          Text(
                                            tag,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

enum _FeedAction { edit, preview, pin, unpin, delete, share }

