import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/storage_provider.dart';
import '../services/api_client.dart';
import '../utils/app_router.dart';
import '../utils/prefs_keys.dart';
import '../utils/ui.dart';
import 'shell_page.dart';
import 'settings_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _filledBaseUrl = false;
  bool _filledSaved = false;
  bool _saveLogin = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      // 登录时允许直接输入 BaseURL，并持久化到设置（shared_preferences）
      await ref.read(settingsProvider.notifier).setBaseUrl(_baseUrlController.text);

      // 可选保存登录信息（账号/密码）
      final storage = await ref.read(localStorageProvider.future);
      await storage.setBool(PrefsKeys.saveLogin, _saveLogin);
      if (_saveLogin) {
        await storage.setString(PrefsKeys.savedUsername, _userController.text.trim());
        await storage.setString(PrefsKeys.savedPassword, _passController.text);
      } else {
        await storage.remove(PrefsKeys.savedUsername);
        await storage.remove(PrefsKeys.savedPassword);
      }

      ref.invalidate(apiClientProvider);
      final api = ref.read(apiClientProvider);
      final data = await api.auth.login(
        username: _userController.text.trim(),
        password: _passController.text,
      );
      final token = (data['token'] ?? data['access_token'] ?? data['jwt'])?.toString();
      if (token == null || token.isEmpty) {
        throw StateError('登录成功但未返回 token');
      }
      await ref.read(authTokenProvider.notifier).setToken(token);
      if (!mounted) return;
      Ui.toast(context, '登录成功');
      AppRouter.goToNamedAndClear(ShellPage.routeName);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? '网络错误';
      if (!mounted) return;
      Ui.toast(context, msg);
    } catch (e) {
      if (!mounted) return;
      Ui.toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!_filledBaseUrl && settings != null) {
      _filledBaseUrl = true;
      _baseUrlController.text = settings.baseUrl;
    }

    final storageAsync = ref.watch(localStorageProvider);
    if (!_filledSaved && storageAsync.hasValue) {
      _filledSaved = true;
      final storage = storageAsync.value!;
      _saveLogin = storage.getBool(PrefsKeys.saveLogin) ?? false;
      if (_saveLogin) {
        _userController.text = storage.getString(PrefsKeys.savedUsername) ?? '';
        _passController.text = storage.getString(PrefsKeys.savedPassword) ?? '';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () => AppRouter.pushNamed(SettingsPage.routeName),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _baseUrlController,
                          decoration: const InputDecoration(
                            labelText: '博客地址（BaseURL）',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '请输入博客地址' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _userController,
                          decoration: const InputDecoration(
                            labelText: '账号',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '请输入账号' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passController,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.isEmpty) ? '请输入密码' : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _saveLogin,
                          onChanged: _loading
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  setState(() => _saveLogin = v);
                                },
                          title: const Text('保存登录信息'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: const Text('登录'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

