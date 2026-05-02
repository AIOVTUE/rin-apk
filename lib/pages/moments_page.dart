import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/moments_provider.dart';
import '../utils/ui.dart';
import 'moments_detail_page.dart';

class MomentsPage extends ConsumerStatefulWidget {
  const MomentsPage({super.key});

  @override
  ConsumerState<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends ConsumerState<MomentsPage> {
  String _oneLinePreview(String input) {
    var t = input.trim();
    if (t.isEmpty) return '';
    // 尽量让 Markdown/HTML 在列表里显示成“一行摘要”
    t = t
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('```', ' ')
        .replaceAll(RegExp(r'[`*_>#=-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return t;
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(momentsProvider.notifier).refresh());
  }

  Future<void> _editDialog({
    String? id,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(id == null ? '新增动态' : '编辑动态'),
          content: SizedBox(
            width: 680,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 12,
              minLines: 8,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final updated = await Navigator.of(ctx).push<String>(
                  MaterialPageRoute(
                    builder: (_) => _MomentsFullEditorPage(
                      title: id == null ? '新增动态' : '编辑动态',
                      initial: controller.text,
                    ),
                  ),
                );
                if (updated != null) controller.text = updated;
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('全屏编辑'),
            ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('保存')),
          ],
        );
      },
    );
    if (ok != true) return;
    if (!mounted) return;
    final text = controller.text.trim();
    if (text.isEmpty) {
      Ui.toast(context, '内容不能为空');
      return;
    }
    try {
      if (id == null) {
        await ref.read(momentsProvider.notifier).create(content: text);
      } else {
        await ref.read(momentsProvider.notifier).update(id: id, content: text);
      }
      if (!mounted) return;
      Ui.toast(context, '已保存');
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    }
  }

  Future<void> _delete(String id) async {
    final ok = await Ui.confirm(
      context,
      title: '确认删除？',
      content: '删除后不可恢复。',
      confirmText: '删除',
    );
    if (!ok) return;
    if (!mounted) return;
    try {
      await ref.read(momentsProvider.notifier).delete(id);
      if (!mounted) return;
      Ui.toast(context, '已删除');
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(momentsProvider);
    final notifier = ref.read(momentsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('动态'),
        actions: [
          IconButton(
            tooltip: '新增',
            onPressed: () => _editDialog(),
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
                      Center(child: Text('暂无动态')),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final m = state.items[i];
                      final date = m.createdAt;
                      final preview = _oneLinePreview(m.content);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => MomentsDetailPage(moment: m)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        tooltip: '更多',
                                        onSelected: (v) {
                                          if (v == 'edit') {
                                            _editDialog(id: m.id, initial: m.content);
                                          } else if (v == 'delete') {
                                            _delete(m.id);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('编辑')),
                                          PopupMenuItem(value: 'delete', child: Text('删除')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preview.isEmpty ? '(空内容)' : preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (date != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${date.toLocal()}'.split('.').first,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
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

class _MomentsFullEditorPage extends StatefulWidget {
  const _MomentsFullEditorPage({
    required this.title,
    required this.initial,
  });

  final String title;
  final String initial;

  @override
  State<_MomentsFullEditorPage> createState() => _MomentsFullEditorPageState();
}

class _MomentsFullEditorPageState extends State<_MomentsFullEditorPage> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('完成'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            labelText: '内容',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

