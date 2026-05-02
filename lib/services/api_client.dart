import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_router.dart';
import '../pages/login_page.dart';
import 'services.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required String? token,
    required FutureOr<void> Function() onUnauthorized,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    dio = Dio(options);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = token;
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            await onUnauthorized();
          }
          handler.next(e);
        },
      ),
    );

    auth = AuthService(dio);
    feed = FeedService(dio);
    comment = CommentService(dio);
    moments = MomentsService(dio);
    friend = FriendService(dio);
    user = UserService(dio);
  }

  late final Dio dio;

  late final AuthService auth;
  late final FeedService feed;
  late final CommentService comment;
  late final MomentsService moments;
  late final FriendService friend;
  late final UserService user;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final token = ref.watch(authTokenProvider).value;
  final baseUrl = settings?.baseUrl ?? kDefaultDemoBaseUrl;

  Future<void> onUnauthorized() async {
    await ref.read(authTokenProvider.notifier).clearToken();
    AppRouter.goToNamedAndClear(LoginPage.routeName);
  }

  return ApiClient(
    baseUrl: baseUrl,
    token: token,
    onUnauthorized: onUnauthorized,
  );
});

