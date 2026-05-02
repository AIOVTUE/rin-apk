class FriendListResponse {
  FriendListResponse({required this.list});

  final List<Map<String, dynamic>> list;

  static FriendListResponse fromAny(dynamic data) {
    // 允许多种后端返回：
    // 1) [ {...}, {...} ]
    // 2) { list: [...] } / { items: [...] } / { friends: [...] }
    // 3) { data: { list/items/... } } 在 services.dart 里已 unwrap，但这里再兜底一次
    dynamic root = data;
    if (root is Map<String, dynamic> && root['data'] != null) root = root['data'];

    List<dynamic>? rawList;
    if (root is List) rawList = root;
    if (root is Map<String, dynamic>) {
      // 兼容常见结构：
      // - { data: Friend[] }
      // - { data: { data: Friend[] } }
      // - { list/items/friends/friend_list: Friend[] }
      dynamic cursor = root;
      for (var i = 0; i < 3; i++) {
        if (cursor is List) {
          rawList = cursor;
          break;
        }
        if (cursor is Map<String, dynamic>) {
          final direct = [
            cursor['list'],
            cursor['items'],
            cursor['friends'],
            cursor['friend_list'],
            cursor['data'],
          ];
          final foundList = direct.whereType<List>().cast<List>().firstOrNull;
          if (foundList != null) {
            rawList = foundList;
            break;
          }

          // 兜底：某些接口只给单条对象字段
          final single = cursor['apply_list'];
          if (single is Map<String, dynamic>) {
            rawList = [single];
            break;
          }

          cursor = cursor['data'];
          continue;
        }
        break;
      }
    }

    final list = (rawList ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return FriendListResponse(list: list);
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

