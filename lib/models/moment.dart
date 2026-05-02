import 'package:flutter/foundation.dart';

@immutable
class Moment {
  const Moment({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime? createdAt;

  static Moment fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final content = (json['content'] ?? json['text'] ?? '').toString();
    DateTime? createdAt;
    final raw = json['createdAt'] ?? json['created_at'] ?? json['time'];
    if (raw is String) createdAt = DateTime.tryParse(raw);
    if (raw is int) createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    return Moment(id: id, content: content, createdAt: createdAt);
  }
}

