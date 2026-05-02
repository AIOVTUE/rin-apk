import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/comment_provider.dart';
import '../services/api_client.dart';
import '../utils/ui.dart';
import '../widgets/markdown_view.dart';
import 'feed_editor_page.dart';

class FeedDetailPage extends ConsumerStatefulWidget {
  const FeedDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends ConsumerState<FeedDetailPage> {
  bool _loading = true;
  String? _error;
  String _title = '';
  String _content = '';
  String _aiSummary = '';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.feed.detail(widget.id);
      setState(() {
        _title = (json['title'] ?? '').toString();
        _content = (json['content'] ?? json['body'] ?? '').toString();
        _aiSummary = (json['aiSummary'] ?? json['ai_summary'] ?? json['ai'] ?? json['summary_ai'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = _title.isEmpty ? '文章详情' : _title;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: false,
              snap: false,
              pinned: false,
              toolbarHeight: 48,
              titleSpacing: 4,
              title: Text(
                titleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: '编辑',
                  onPressed: _loading
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => FeedEditorPage(id: widget.id)),
                          );
                          if (!context.mounted) return;
                          Ui.toast(context, '已返回');
                          await _load();
                        },
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                ),
              )
            else ...[
              if (_aiSummary.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI 总结',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _aiSummary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: MarkdownView(
                  data: _content,
                  asBody: true,
                ),
              ),
              SliverToBoxAdapter(
                child: _CommentSection(feedId: widget.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentSection extends ConsumerStatefulWidget {
  const _CommentSection({required this.feedId});

  final String feedId;

  @override
  ConsumerState<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<_CommentSection> {
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(commentProvider(widget.feedId).notifier).refresh());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await ref.read(commentProvider(widget.feedId).notifier).create(content);
      _commentController.clear();
      if (!mounted) return;
      Ui.toast(context, '评论成功');
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final ok = await Ui.confirm(
      context,
      title: '确认删除评论？',
      content: '删除后不可恢复。',
      confirmText: '删除',
    );
    if (!ok) return;
    try {
      await ref.read(commentProvider(widget.feedId).notifier).delete(commentId);
      if (!mounted) return;
      Ui.toast(context, '已删除');
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(commentProvider(widget.feedId));
    final notifier = ref.read(commentProvider(widget.feedId).notifier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.comment_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text('评论', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('(${state.items.length})', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '写下你的评论...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _submitting ? null : _submitComment,
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (state.errorMessage != null && state.items.isEmpty)
            Center(
              child: Column(
                children: [
                  Text('加载失败', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => notifier.refresh(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          else if (state.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('暂无评论，快来抢沙发！', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              itemBuilder: (ctx, i) {
                final comment = state.items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: comment.avatar != null ? NetworkImage(comment.avatar!) : null,
                              backgroundColor: cs.primaryContainer,
                              child: comment.avatar == null
                                  ? Text(
                                      (comment.author?.isNotEmpty == true ? comment.author![0] : '?').toUpperCase(),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              comment.author ?? '匿名用户',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (comment.createdAt != null)
                              Text(
                                '${comment.createdAt!.toLocal()}'.split('.').first,
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
                              onSelected: (v) {
                                if (v == 'delete') _deleteComment(comment.id);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'delete', child: Text('删除')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment.content, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
