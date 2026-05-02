import 'package:flutter/foundation.dart';

@immutable
class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.tags,
    required this.createdAt,
    required this.url,
    this.isTop = false,
    this.aiSummary = '',
  });

  final String id;
  final String title;
  final String content;
  final String summary;
  final List<String> tags;
  final DateTime? createdAt;
  final String? url;
  final bool isTop;
  final String aiSummary;

  static dynamic _findTagSource(dynamic node) {
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

  static List<String> _parseTags(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map<String, dynamic>) {
              return (e['name'] ?? e['tag'] ?? e['title'] ?? e['label'] ?? '').toString();
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[,，\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return const [];
  }

  static FeedItem fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final content = (json['content'] ?? json['body'] ?? '').toString();
    final summary = (json['summary'] ?? json['description'] ?? json['desc'] ?? '').toString();
    final tagSource = _findTagSource(json);
    final tags = _parseTags(tagSource);
    final url = json['url']?.toString();
    DateTime? createdAt;
    final raw = json['createdAt'] ?? json['created_at'] ?? json['time'];
    if (raw is String) createdAt = DateTime.tryParse(raw);
    if (raw is int) createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    final topValue = json['isTop'] ?? json['top'] ?? json['is_top'] ?? json['topStatus'] ?? json['top_status'];
    bool isTop = false;
    if (topValue == true) {
      isTop = true;
    } else if (topValue is int) {
      isTop = topValue > 0;
    } else if (topValue is String) {
      isTop = topValue.toLowerCase() == 'true' || topValue == '1';
    }
    final aiSummary = (json['aiSummary'] ?? json['ai_summary'] ?? json['ai_summary'] ?? json['ai'] ?? json['summary_ai'] ?? '').toString();
    return FeedItem(
      id: id,
      title: title,
      content: content,
      summary: summary,
      tags: tags,
      createdAt: createdAt,
      url: url,
      isTop: isTop,
      aiSummary: aiSummary,
    );
  }
}

