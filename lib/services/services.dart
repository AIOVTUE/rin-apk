import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Object? _unwrapData(dynamic data) {
  if (data is Map<String, dynamic> && data.containsKey('data')) {
    return data['data'];
  }
  return data;
}

class AuthService {
  AuthService(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> status() async {
    final res = await _dio.get('/api/auth/status');
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }
}

class FeedService {
  FeedService(this._dio);
  final Dio _dio;

  Future<List<dynamic>> feed({int page = 1, String? type}) async {
    final res = await _dio.get(
      '/api/feed',
      queryParameters: {
        'page': page,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final data = _unwrapData(res.data);
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['list'] is List) return data['list'] as List;
    return const [];
  }

  Future<List<dynamic>> timeline({int page = 1}) async {
    final res = await _dio.get('/api/feed/timeline', queryParameters: {'page': page});
    final data = _unwrapData(res.data);
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['list'] is List) return data['list'] as List;
    return const [];
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final res = await _dio.get('/api/feed/$id');
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> create({
    required String title,
    required String content,
    required String type,
    Map<String, dynamic>? extra,
  }) async {
    final res = await _dio.post('/api/feed', data: {
      'title': title,
      'content': content,
      'type': type,
      ...?extra,
    });
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update({
    required String id,
    required String title,
    required String content,
    required String type,
    Map<String, dynamic>? extra,
  }) async {
    final res = await _dio.post('/api/feed/$id', data: {
      'title': title,
      'content': content,
      'type': type,
      ...?extra,
    });
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/feed/$id');
  }

  Future<Map<String, dynamic>> top(String id, {int top = 1}) async {
    final res = await _dio.post('/api/feed/top/$id', data: {'top': top});
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }
}

class CommentService {
  CommentService(this._dio);
  final Dio _dio;

  Future<List<dynamic>> list(String feedId) async {
    final res = await _dio.get('/api/comment/$feedId');
    final data = _unwrapData(res.data);
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['list'] is List) return data['list'] as List;
    return const [];
  }

  Future<Map<String, dynamic>> create(String feedId, String content) async {
    final res = await _dio.post('/api/comment/$feedId', data: {'content': content});
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/comment/$id');
  }
}

class MomentsService {
  MomentsService(this._dio);
  final Dio _dio;

  Future<List<dynamic>> list() async {
    final res = await _dio.get('/api/moments');
    final data = _unwrapData(res.data);
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['list'] is List) return data['list'] as List;
    return const [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final res = await _dio.post('/api/moments', data: payload);
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) async {
    final res = await _dio.post('/api/moments/$id', data: payload);
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/moments/$id');
  }
}

class FriendService {
  FriendService(this._dio);
  final Dio _dio;

  String _truncate(String s, [int max = 2000]) => s.length <= max ? s : '${s.substring(0, max)}…(truncated)';

  Future<dynamic> list() async {
    final res = await _dio.get('/api/friend');
    final baseUrl = _dio.options.baseUrl;
    final status = res.statusCode;
    final raw = res.data;

    String printable;
    try {
      printable = _truncate(jsonEncode(raw));
    } catch (_) {
      printable = _truncate(raw.toString());
    }
    debugPrint('[FriendService] GET $baseUrl/api/friend status=$status data=$printable');

    // 这里不做强行结构抽取，交给 FriendListResponse 做兼容解析
    return _unwrapData(raw);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final res = await _dio.post('/api/friend', data: payload);
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) async {
    final res = await _dio.put('/api/friend/$id', data: payload);
    final data = _unwrapData(res.data);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/friend/$id');
  }
}

class UserService {
  UserService(this._dio);
  final Dio _dio;

  Future<void> logout() async {
    await _dio.post('/api/user/logout');
  }
}

