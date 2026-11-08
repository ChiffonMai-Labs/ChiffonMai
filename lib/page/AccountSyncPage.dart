import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../manager/DivingFishProbeManager.dart';
import '../widgets/ThemeAwareBackground.dart';
import '../utils/UserProfileNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import 'HubComponents.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';

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
        title: context.l10n.flowCannotSave,
        message: context.l10n.flowEnterYourAWMCNETScoreImportToken,
      );
      return;
    }
    await SecureCredentialStore.write(
        CacheKeyConstant.awmcNetImportToken, token);
    if (!mounted) return;
    setState(() => _awmcToken = token);
    AppToast.show(context.l10n.flowAWMCNETScoreImportTokenSaved);
  }

  Future<void> _clearAwmcToken() async {
    await SecureCredentialStore.delete(CacheKeyConstant.awmcNetImportToken);
    if (!mounted) return;
    _awmcTokenController.clear();
    setState(() => _awmcToken = null);
    AppToast.show(context.l10n.flowAWMCNETScoreImportTokenCleared);
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
            return manager.lastLoginFailure?.message ?? context.l10n.flowSignInFailedTryAgainLater;
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
      AppToast.show(context.l10n.flowSignedInToDivingFish,
          tone: AppToastTone.success);
    }
  }

  Future<void> _logout() async {
    try {
      await UserProfileNotifier.clearShuiyuAccountCache();
    } catch (e) {
      if (mounted) {
        await showErrorMessageDialog(context,
            message: context.l10n.flowSignOutFailedP0((e).toString()));
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
                    title: context.l10n.flowSignOut,
                    subtitle: _cachedQQ.isEmpty
                        ? context.l10n.flowClearSignIn
                        : context.l10n.flowBoundQq(_cachedQQ),
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
                      labelText: context.l10n.flowScoreImportToken,
                      hintText: context.l10n.flowPasteATokenGeneratedInAWMCNET,
                      suffixIcon: _awmcToken == null
                          ? null
                          : IconButton(
                              tooltip: context.l10n.flowClearToken,
                              icon: const Icon(Icons.clear),
                              onPressed: _clearAwmcToken,
                            ),
                    ).insetLabel(context),
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
                        label: Text(context.l10n.flowSaveToken),
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
                  onTap: () => _showUnavailableMessage(
                      context.l10n.flowStartQRSyncFromHome),
                ),
                HubActionTile(
                  title: '同步成绩到落雪',
                  subtitle: '将本地成绩同步到落雪咖啡屋',
                  icon: Icons.cloud_sync_outlined,
                  onTap: () => _showUnavailableMessage(
                      context.l10n.flowStartSyncFromHome),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUnavailableMessage(String message) {
    AppToast.show(message);
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
      setState(() => _errorMessage = context.l10n.flowEnterUsernameAndPassword);
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
    return AppAlertDialog(
      title: Text(context.l10n.featureSignInToDivingFish),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: context.l10n.flowUsername)
                .insetLabel(context),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: context.l10n.flowPassword)
                .insetLabel(context),
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
          child: Text(context.l10n.featureCancel),
        ),
        FilledButton(
          onPressed: _isLoggingIn ? null : _submit,
          child: _isLoggingIn
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.flowSignIn),
        ),
      ],
    );
  }
}
