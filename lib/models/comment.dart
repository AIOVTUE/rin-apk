import 'package:flutter/foundation.dart';

@immutable
class Comment {
  const Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.author,
    this.authorId,
    this.avatar,
  });

  final String id;
  final String content;
  final DateTime? createdAt;
  final String? author;
  final String? authorId;
  final String? avatar;

  static Comment fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final content = (json['content'] ?? json['text'] ?? '').toString();
    
    String? author;
    String? authorId;
    String? avatar;
    
    final authorData = json['author'] ?? json['user'];
    if (authorData is Map<String, dynamic>) {
      author = (authorData['username'] ?? authorData['nickname'] ?? authorData['name'] ?? '').toString();
      authorId = (authorData['id'] ?? authorData['_id'] ?? '').toString();
      avatar = authorData['avatar']?.toString();
    } else {
      author = (authorData ?? json['username'] ?? json['nickname'] ?? '').toString();
    }
    
    DateTime? createdAt;
    final raw = json['createdAt'] ?? json['created_at'] ?? json['time'];
    if (raw is String) createdAt = DateTime.tryParse(raw);
    if (raw is int) createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    
    return Comment(
      id: id,
      content: content,
      createdAt: createdAt,
      author: author.isEmpty ? null : author,
      authorId: authorId?.isEmpty != false ? null : authorId,
      avatar: avatar?.isNotEmpty == true ? avatar : null,
    );
  }
}
