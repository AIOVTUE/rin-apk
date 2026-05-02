import 'package:flutter/foundation.dart';

@immutable
class FriendLink {
  const FriendLink({
    required this.id,
    required this.name,
    required this.url,
    required this.avatar,
    required this.desc,
  });

  final String id;
  final String name;
  final String url;
  final String? avatar;
  final String? desc;

  static Map<String, dynamic> _flatten(Map<String, dynamic> json) {
    dynamic cursor = json;
    for (var i = 0; i < 3; i++) {
      if (cursor is! Map<String, dynamic>) break;
      final nested = cursor['friend'] ?? cursor['item'] ?? cursor['data'] ?? cursor['attributes'];
      if (nested is Map<String, dynamic>) {
        cursor = nested;
        continue;
      }
      break;
    }
    return (cursor is Map<String, dynamic>) ? cursor : json;
  }

  static FriendLink fromJson(Map<String, dynamic> json) {
    final j = _flatten(json);
    final id = (j['id'] ?? j['_id'] ?? j['friendId'] ?? '').toString();
    final name = (j['name'] ?? j['title'] ?? j['siteName'] ?? j['nickname'] ?? '').toString();
    final url = (j['url'] ?? j['link'] ?? j['homepage'] ?? j['site'] ?? '').toString();
    final avatar = (j['avatar'] ?? j['icon'] ?? j['logo'])?.toString();
    final desc = (j['desc'] ?? j['description'] ?? j['bio'] ?? j['intro'])?.toString();
    return FriendLink(id: id, name: name, url: url, avatar: avatar, desc: desc);
  }
}

