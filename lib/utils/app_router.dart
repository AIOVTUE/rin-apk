import 'package:flutter/material.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get _nav => navigatorKey.currentState;

  static void goToNamedAndClear(String routeName) {
    final nav = _nav;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    final nav = _nav;
    if (nav == null) return Future.value(null);
    return nav.pushNamed<T>(routeName, arguments: arguments);
  }

  static void pop<T extends Object?>([T? result]) {
    final nav = _nav;
    if (nav == null) return;
    if (nav.canPop()) nav.pop(result);
  }
}

