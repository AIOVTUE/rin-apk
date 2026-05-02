import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import 'feed_list_page.dart';
import 'friend_page.dart';
import 'moments_page.dart';
import 'settings_page.dart';

class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});

  static const routeName = '/app';

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  _TabId _currentTab = _TabId.feed;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;

    final tabs = <_TabSpec>[
      const _TabSpec(
        id: _TabId.feed,
        label: '首页',
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        page: FeedListPage(),
      ),
      if (settings?.showMoments ?? true)
        const _TabSpec(
          id: _TabId.moments,
          label: '动态',
          icon: Icons.bolt_outlined,
          selectedIcon: Icons.bolt,
          page: MomentsPage(),
        ),
      if (settings?.showFriend ?? true)
        const _TabSpec(
          id: _TabId.friend,
          label: '友链',
          icon: Icons.link_outlined,
          selectedIcon: Icons.link,
          page: FriendPage(),
        ),
      const _TabSpec(
        id: _TabId.settings,
        label: '设置',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: SettingsPage(),
      ),
    ];

    var selectedIndex = tabs.indexWhere((t) => t.id == _currentTab);
    if (selectedIndex < 0) {
      selectedIndex = tabs.indexWhere((t) => t.id == _TabId.settings);
      if (selectedIndex < 0) selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _currentTab = tabs[selectedIndex].id);
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [for (final t in tabs) t.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => setState(() => _currentTab = tabs[i].id),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final _TabId id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

enum _TabId { feed, moments, friend, settings }

