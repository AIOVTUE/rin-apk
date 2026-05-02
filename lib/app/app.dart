import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/login_page.dart';
import '../pages/settings_page.dart';
import '../pages/shell_page.dart';
import '../pages/splash_page.dart';
import '../providers/theme_providers.dart';
import '../utils/app_router.dart';

class RinApp extends ConsumerWidget {
  const RinApp({super.key});

  ThemeData _buildTheme(Color seedColor, {required Brightness brightness}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    const radius = BorderRadius.all(Radius.circular(14));
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(toolbarHeight: 44),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(borderRadius: radius),
        focusedBorder: OutlineInputBorder(borderRadius: radius),
        errorBorder: OutlineInputBorder(borderRadius: radius),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, height: 1.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider).value ??
        const ThemeState(themeMode: ThemeMode.system, seedColor: Colors.indigo);

    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      title: 'Rin Blog',
      themeMode: themeState.themeMode,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.unknown,
        },
      ),
      theme: _buildTheme(themeState.seedColor, brightness: Brightness.light),
      darkTheme: _buildTheme(themeState.seedColor, brightness: Brightness.dark),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case SplashPage.routeName:
            return MaterialPageRoute(builder: (_) => const SplashPage());
          case LoginPage.routeName:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case ShellPage.routeName:
            return MaterialPageRoute(builder: (_) => const ShellPage());
          case SettingsPage.routeName:
            return MaterialPageRoute(builder: (_) => const SettingsPage());
          default:
            return MaterialPageRoute(builder: (_) => const SplashPage());
        }
      },
      initialRoute: SplashPage.routeName,
    );
  }
}

