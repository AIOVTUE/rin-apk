import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../utils/app_router.dart';
import 'login_page.dart';
import 'shell_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const routeName = '/';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final token = await ref.read(authTokenProvider.future);
    if (token == null || token.isEmpty) {
      AppRouter.goToNamedAndClear(LoginPage.routeName);
      return;
    }
    AppRouter.goToNamedAndClear(ShellPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

