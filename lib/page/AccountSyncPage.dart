import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../manager/DivingFishProbeManager.dart';
import '../widgets/ThemeAwareBackground.dart';
import '../utils/UserProfileNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import 'HubComponents.dart';
import '../widgets/ErrorMessageDialog.dart';

class AccountSyncPage extends StatefulWidget {
  const AccountSyncPage({super.key});

  @override
  State<AccountSyncPage> createState() => _AccountSyncPageState();
}

class _AccountSyncPageState extends State<AccountSyncPage> {
  bool _loggedIn = false;
  String _cachedQQ = '';
  final _awmcTokenController = TextEditingController();
  String? _awmcToken;
  bool _loading = true;

  @override
  void dispose() {
    _awmcTokenController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAccountState();
  }

  Future<void> _loadAccountState() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt =
        await SecureCredentialStore.read(CacheKeyConstant.probeDivingFishToken);
    final awmcToken =
        await SecureCredentialStore.read(CacheKeyConstant.awmcNetImportToken);
    if (!mounted) return;
    _awmcTokenController.text = awmcToken ?? '';
    setState(() {
      _loggedIn = jwt?.isNotEmpty == true;
      _cachedQQ = prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '';
      _awmcToken = awmcToken?.isNotEmpty == true ? awmcToken : null;
      _loading = false;
    });
  }

  Future<void> _saveAwmcToken() async {
    final token = _awmcTokenController.text.trim();
    if (token.isEmpty) {
      await showErrorMessageDialog(
        context,
        title: '无法保存',
        message: '请输入 AWMC NET 成绩导入 Token。',
      );
      return;
    }
    await SecureCredentialStore.write(
        CacheKeyConstant.awmcNetImportToken, token);
    if (!mounted) return;
    setState(() => _awmcToken = token);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AWMC NET 成绩导入 Token 已保存')),
    );
  }

  Future<void> _clearAwmcToken() async {
    await SecureCredentialStore.delete(CacheKeyConstant.awmcNetImportToken);
    if (!mounted) return;
    _awmcTokenController.clear();
    setState(() => _awmcToken = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AWMC NET 成绩导入 Token 已清除')),
    );
  }

  Future<void> _login() async {
    final loggedIn = await showDialog<bool>(
      context: context,
      builder: (_) => _LoginDialog(
        onSubmit: (username, password) async {
          final manager = DivingFishProbeManager();
          final response = await manager.loginDivingFishDirect(
            username,
            password,
          );
          if (response == null) {
            return manager.lastLoginFailure?.message ?? '登录失败，请稍后再试';
          }
          final bindQQ = response.tryGet<String>('bind_qq')?.trim() ?? '';
          if (bindQQ.isEmpty) return divingFishMissingBindQqMessage;
          return null;
        },
      ),
    );
    if (loggedIn != true || !mounted) return;
    await _loadAccountState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('水鱼账号登录成功')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await UserProfileNotifier.clearShuiyuAccountCache();
    } catch (e) {
      if (mounted) {
        await showErrorMessageDialog(context, message: '登出失败：$e');
      }
      return;
    }
    await _loadAccountState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: ThemeAwareBackground(
        child: HubPageScaffold(
          title: '账号与同步',
          subtitle: '管理账号、授权状态与成绩同步',
          icon: Icons.manage_accounts,
          children: [
            HubSection(
              title: '水鱼账号',
              subtitle: _loading ? '正在读取账号状态' : (_loggedIn ? '已登录' : '未登录'),
              icon: Icons.account_circle_outlined,
              children: [
                HubActionTile(
                  title: _loggedIn ? '重新登录水鱼' : '登录水鱼',
                  subtitle: '使用水鱼账号获取 ImportToken',
                  icon: Icons.login,
                  onTap: _login,
                ),
                if (_loggedIn)
                  HubActionTile(
                    title: '登出账号',
                    subtitle:
                        _cachedQQ.isEmpty ? '清除当前登录状态' : '当前绑定 QQ：$_cachedQQ',
                    icon: Icons.logout,
                    iconColor: Theme.of(context).colorScheme.error,
                    onTap: _logout,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            HubSection(
              title: 'AWMC NET',
              subtitle: _awmcToken == null ? '未设置成绩导入 Token' : '成绩导入 Token 已设置',
              icon: Icons.cloud_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: TextField(
                    controller: _awmcTokenController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: '成绩导入 Token',
                      hintText: '粘贴 AWMC NET 设置页生成的 Token',
                      suffixIcon: _awmcToken == null
                          ? null
                          : IconButton(
                              tooltip: '清除 Token',
                              icon: const Icon(Icons.clear),
                              onPressed: _clearAwmcToken,
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: _saveAwmcToken,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存 Token'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            HubSection(
              title: '成绩同步',
              subtitle: '从舞萌数据源同步到第三方服务',
              icon: Icons.sync,
              children: [
                HubActionTile(
                  title: '同步成绩到水鱼',
                  subtitle: '扫码抓取并同步最新成绩',
                  icon: Icons.cloud_upload_outlined,
                  onTap: () => _showUnavailableMessage('请从首页的同步入口开始扫码同步'),
                ),
                HubActionTile(
                  title: '同步成绩到落雪',
                  subtitle: '将本地成绩同步到落雪咖啡屋',
                  icon: Icons.cloud_sync_outlined,
                  onTap: () => _showUnavailableMessage('请从首页的同步入口开始同步'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUnavailableMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoginDialog extends StatefulWidget {
  /// 返回 null 表示成功，否则返回要在输入框下方显示的红色错误提示。
  final Future<String?> Function(String username, String password) onSubmit;

  const _LoginDialog({required this.onSubmit});

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '请输入用户名和密码');
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });
    final error = await widget.onSubmit(username, password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isLoggingIn = false;
        _errorMessage = error;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('登录水鱼'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: '用户名'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoggingIn ? null : _submit,
          child: _isLoggingIn
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('登录'),
        ),
      ],
    );
  }
}
