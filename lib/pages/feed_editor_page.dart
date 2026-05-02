import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../services/api_client.dart';
import '../utils/ui.dart';
import '../widgets/markdown_view.dart';

class FeedEditorPage extends ConsumerStatefulWidget {
  const FeedEditorPage({super.key, this.id});

  final String? id;

  @override
  ConsumerState<FeedEditorPage> createState() => _FeedEditorPageState();
}

class _FeedEditorPageState extends ConsumerState<FeedEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _summaryController = TextEditingController();
  final _slugController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _preview = false;
  bool _loading = false;
  bool _isVisible = true;
  final List<String> _tags = <String>[];

  bool get _isEdit => widget.id != null && widget.id!.isNotEmpty;

  List<String> _parseTags(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map<String, dynamic>) {
              return (e['name'] ?? e['tag'] ?? e['title'] ?? '').toString();
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    if (raw is String) {
      final text = raw.trim();
      if (text.startsWith('[') && text.endsWith(']')) {
        try {
          final parsed = jsonDecode(text);
          if (parsed is List) {
            return parsed
                .map((e) {
                  if (e is Map<String, dynamic>) {
                    return (e['name'] ?? e['tag'] ?? e['title'] ?? '').toString();
                  }
                  return e.toString();
                })
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
          }
          if (parsed != null) {
            return parsed
                .toString()
                .split(RegExp(r'[,，\s]+'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
          }
        } catch (_) {}
      }
      return raw
          .split(RegExp(r'[,，\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return <String>[];
  }

  dynamic _findTagSource(dynamic node) {
    if (node is Map<String, dynamic>) {
      const keys = <String>[
        'hashtags',
        'tags',
        'tag_list',
        'tag',
        'labels',
        'label',
        'categories',
        'category',
      ];
      for (final key in keys) {
        if (node.containsKey(key) && node[key] != null) {
          return node[key];
        }
      }
      for (final value in node.values) {
        final found = _findTagSource(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findTagSource(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      Future<void>.microtask(_load);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    _slugController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.feed.detail(widget.id!);
      _titleController.text = (json['title'] ?? '').toString();
      _contentController.text = (json['content'] ?? json['body'] ?? '').toString();
      _summaryController.text = (json['summary'] ?? json['description'] ?? '').toString();
      _slugController.text = (json['slug'] ?? json['alias'] ?? json['path'] ?? '').toString();
      _tags
        ..clear()
        ..addAll(_parseTags(_findTagSource(json)));
      final type = (json['type'] ?? json['status'] ?? '').toString().toLowerCase();
      _isVisible = !(type == 'unlisted' || type == 'draft');
    } catch (e) {
      if (mounted) Ui.toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addTag() {
    final v = _tagsController.text.trim();
    if (v.isEmpty) return;
    if (_tags.contains(v)) {
      _tagsController.clear();
      return;
    }
    setState(() {
      _tags.add(v);
      _tagsController.clear();
    });
  }

  void _editExistingTag(String tag) {
    if (_loading) return;
    setState(() {
      _tags.remove(tag);
      _tagsController.text = tag;
    });
  }

  Future<void> _save() async {
    if (_loading) return;
    final title = _titleController.text.trim();
    final content = _contentController.text;
    if (title.isEmpty) {
      Ui.toast(context, '请输入标题');
      return;
    }
    if (content.trim().isEmpty) {
      Ui.toast(context, '请输入内容');
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final type = _isVisible ? 'normal' : 'unlisted';
      final slug = _slugController.text.trim();
      final extra = <String, dynamic>{
        'summary': _summaryController.text.trim(),
        // 同时发送 slug/alias，兼容不同后端字段；允许传空串以支持“清空别名”
        'slug': slug,
        'alias': slug,
        // 始终回传 tags，支持编辑时删除全部标签
        'tags': List<String>.from(_tags),
        'listed': _isVisible,
      };
      if (_isEdit) {
        await api.feed.update(
          id: widget.id!,
          title: title,
          content: content,
          type: type,
          extra: extra,
        );
      } else {
        await api.feed.create(
          title: title,
          content: content,
          type: type,
          extra: extra,
        );
      }
      if (!mounted) return;
      Ui.toast(context, _isEdit ? '已保存' : '已创建');
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      String msg;
      if (data is Map<String, dynamic>) {
        msg = (data['message'] ?? data['error'] ?? data['msg'] ?? e.message ?? '请求失败').toString();
      } else {
        msg = data?.toString() ?? e.message ?? '请求失败';
      }
      Ui.toast(context, msg);
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    InputDecoration inputStyle(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary),
        ),
      );
    }

    Widget switchTile({
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ),
            Switch(value: value, onChanged: _loading ? null : onChanged),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _preview
            ? MarkdownView(data: _contentController.text)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: '返回',
                              onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '写作',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isEdit ? '更新' : '新建',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _loading ? null : _save,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.publish),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                textStyle: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              label: const Text('发布'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _titleController,
                                decoration: inputStyle('标题'),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _summaryController,
                                      decoration: inputStyle('简介'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _slugController,
                                      decoration: inputStyle('别名'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '标签',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _tagsController,
                                            decoration: inputStyle('输入标签后点击添加'),
                                            onSubmitted: (_) => _addTag(),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        FilledButton(
                                          onPressed: _loading ? null : _addTag,
                                          child: const Text('添加'),
                                        ),
                                      ],
                                    ),
                                    if (_tags.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final tag in _tags)
                                            InputChip(
                                              label: Text(tag),
                                              onPressed: _loading ? null : () => _editExistingTag(tag),
                                              onDeleted: _loading
                                                  ? null
                                                  : () => setState(() => _tags.remove(tag)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              switchTile(
                                title: '列出在文章中（保存后直接展示）',
                                value: _isVisible,
                                onChanged: (v) => setState(() => _isVisible = v),
                              ),
                              const SizedBox(height: 16),
                              Divider(color: cs.outlineVariant, height: 1),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    '内容',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: '预览/编辑',
                                    onPressed: () => setState(() => _preview = !_preview),
                                    icon: Icon(_preview ? Icons.edit : Icons.visibility),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 420,
                                child: TextField(
                                  controller: _contentController,
                                  decoration: inputStyle('内容（Markdown）').copyWith(
                                    alignLabelWithHint: true,
                                    contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  expands: true,
                                  maxLines: null,
                                  minLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
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
      ),
      floatingActionButton: _preview
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _preview = false),
              icon: const Icon(Icons.edit),
              label: const Text('继续编辑'),
            )
          : null,
    );
  }
}

