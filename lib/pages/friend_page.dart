import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/friend_link.dart';
import '../providers/friend_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/ui.dart';

class FriendPage extends ConsumerStatefulWidget {
  const FriendPage({super.key});

  @override
  ConsumerState<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends ConsumerState<FriendPage> {
  ProviderSubscription<AsyncValue<AppSettings>>? _settingsSub;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(friendProvider.notifier).refresh());

    // BaseURL/设置是异步加载的：避免首次刷新打到默认地址导致“空白”
    _settingsSub = ref.listenManual<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      final prevUrl = prev?.valueOrNull?.baseUrl;
      final nextUrl = next.valueOrNull?.baseUrl;
      if (prevUrl != nextUrl) {
        ref.read(friendProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _settingsSub?.close();
    super.dispose();
  }

  Future<void> _editDialog({FriendLink? link}) async {
    final name = TextEditingController(text: link?.name ?? '');
    final url = TextEditingController(text: link?.url ?? '');
    final avatar = TextEditingController(text: link?.avatar ?? '');
    final desc = TextEditingController(text: link?.desc ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(link == null ? '新增友链' : '编辑友链'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(labelText: '链接 URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: avatar,
                  decoration: const InputDecoration(labelText: '头像', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('保存')),
          ],
        );
      },
    );
    if (ok != true) return;
    if (!mounted) return;

    final n = name.text.trim();
    final u = url.text.trim();
    if (n.isEmpty || u.isEmpty) {
      Ui.toast(context, '名称和 URL 不能为空');
      return;
    }
    try {
      final notifier = ref.read(friendProvider.notifier);
      if (link == null) {
        await notifier.create(
          name: n,
          url: u,
          avatar: avatar.text.trim().isEmpty ? null : avatar.text.trim(),
          desc: desc.text.trim().isEmpty ? null : desc.text.trim(),
        );
      } else {
        await notifier.update(
          id: link.id,
          name: n,
          url: u,
          avatar: avatar.text.trim().isEmpty ? null : avatar.text.trim(),
          desc: desc.text.trim().isEmpty ? null : desc.text.trim(),
        );
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
      await ref.read(friendProvider.notifier).delete(id);
      if (!mounted) return;
      Ui.toast(context, '已删除');
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    }
  }

  Future<void> _openLink(String rawUrl) async {
    final text = rawUrl.trim();
    if (text.isEmpty) return;
    final normalized = text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      Ui.toast(context, '链接格式不正确');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      Ui.toast(context, '无法打开链接');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);
    final notifier = ref.read(friendProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('友链'),
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
            : state.items.isEmpty && state.errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      const Center(child: Text('加载失败')),
                      const SizedBox(height: 8),
                      Center(child: Text(state.errorMessage!, textAlign: TextAlign.center)),
                      const SizedBox(height: 12),
                      Center(
                        child: FilledButton(
                          onPressed: () => notifier.refresh(),
                          child: const Text('重试'),
                        ),
                      ),
                    ],
                  )
            : state.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('暂无友链')),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final f = state.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: InkWell(
                            onTap: f.url.isEmpty ? null : () => _openLink(f.url),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    backgroundImage: (f.avatar != null && f.avatar!.isNotEmpty)
                                        ? NetworkImage(f.avatar!)
                                        : null,
                                    child: (f.avatar == null || f.avatar!.isEmpty)
                                        ? const Icon(Icons.link, size: 20)
                                        : null,
                                    onBackgroundImageError: (exception, stackTrace) {},
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                f.name.isEmpty ? '(未命名友链)' : f.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      height: 1.15,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 28,
                                              height: 24,
                                              child: PopupMenuButton<String>(
                                                tooltip: '更多',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
                                                onSelected: (v) {
                                                  if (v == 'edit') _editDialog(link: f);
                                                  if (v == 'delete') _delete(f.id);
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                                                  PopupMenuItem(value: 'delete', child: Text('删除')),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if ((f.desc ?? '').trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 0),
                                            child: Text(
                                              f.desc!.trim(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    height: 1.2,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
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

