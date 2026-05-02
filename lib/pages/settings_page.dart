import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_providers.dart';
import '../services/api_client.dart';
import '../utils/app_router.dart';
import '../utils/ui.dart';
import 'login_page.dart';

class _PresetColor {
  const _PresetColor(this.name, this.color);

  final String name;
  final Color color;
}

const _morandiColors = <_PresetColor>[
  _PresetColor('雾蓝', Color(0xFF8DA2B5)),
  _PresetColor('豆绿', Color(0xFF9BAF9D)),
  _PresetColor('灰粉', Color(0xFFC5A3A3)),
  _PresetColor('燕麦', Color(0xFFC9B8A3)),
  _PresetColor('烟紫', Color(0xFFA79BB7)),
  _PresetColor('雾灰', Color(0xFF9A9FA6)),
  _PresetColor('岩棕', Color(0xFF9F8B7A)),
  _PresetColor('鼠尾草', Color(0xFF8FA08A)),
];

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _baseUrlController = TextEditingController();

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickColor(Color current) async {
    Color temp = current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('主题颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: current,
              onColorChanged: (c) => temp = c,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('确定')),
          ],
        );
      },
    );
    if (ok == true) {
      await ref.read(themeProvider.notifier).setSeedColor(temp);
    }
  }

  Future<void> _logout({required bool callApi}) async {
    final ok = await Ui.confirm(
      context,
      title: callApi ? '退出登录？' : '切换账号？',
      content: callApi ? '将调用接口退出登录。' : '将清除本地 token。',
      confirmText: '确定',
    );
    if (!ok) return;
    try {
      if (callApi) {
        await ref.read(apiClientProvider).user.logout();
      }
    } catch (_) {
      // 即使接口失败，也允许本地退出，避免卡死
    } finally {
      await ref.read(authTokenProvider.notifier).clearToken();
      if (mounted) {
        Ui.toast(context, '已退出');
        AppRouter.goToNamedAndClear(LoginPage.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeAsync = ref.watch(themeProvider);
    final token = ref.watch(authTokenProvider).valueOrNull;

    final settings = settingsAsync.value;
    final themeState = themeAsync.value;
    if (settings != null && _baseUrlController.text.isEmpty) {
      _baseUrlController.text = settings.baseUrl;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('页面显示开关', style: TextStyle(fontWeight: FontWeight.w700)),
                  SwitchListTile(
                    title: const Text('显示动态页'),
                    value: settings?.showMoments ?? true,
                    onChanged: settings == null
                        ? null
                        : (v) => ref.read(settingsProvider.notifier).setShowMoments(v),
                  ),
                  SwitchListTile(
                    title: const Text('显示友链页'),
                    value: settings?.showFriend ?? true,
                    onChanged: settings == null
                        ? null
                        : (v) => ref.read(settingsProvider.notifier).setShowFriend(v),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('主题', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: themeState?.themeMode ?? ThemeMode.system,
                    borderRadius: BorderRadius.circular(14),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
                    ],
                    onChanged: themeState == null
                        ? null
                        : (m) {
                            if (m == null) return;
                            ref.read(themeProvider.notifier).setThemeMode(m);
                          },
                    decoration: const InputDecoration(labelText: '模式'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: themeState == null ? null : () => _pickColor(themeState.seedColor),
                    icon: Icon(Icons.palette, color: themeState?.seedColor),
                    label: const Text('选择主题色'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '莫兰迪色系',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in _morandiColors)
                        _MorandiColorChip(
                          preset: preset,
                          selected: themeState?.seedColor.toARGB32() == preset.color.toARGB32(),
                          onTap: () => ref.read(themeProvider.notifier).setSeedColor(preset.color),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('账号与博客地址', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: '博客地址（BaseURL）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: settings == null
                        ? null
                        : () async {
                            await ref
                                .read(settingsProvider.notifier)
                                .setBaseUrl(_baseUrlController.text);
                            if (!context.mounted) return;
                            Ui.toast(context, '已更新 BaseURL');
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('保存地址'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: token == null ? null : () => _logout(callApi: true),
                    child: const Text('退出登录'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: token == null ? null : () => _logout(callApi: false),
                    child: const Text('切换账号'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MorandiColorChip extends StatelessWidget {
  const _MorandiColorChip({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _PresetColor preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.secondaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: preset.color,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
            ),
            const SizedBox(width: 6),
            Text(preset.name),
          ],
        ),
      ),
    );
  }
}

