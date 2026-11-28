import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/CacheKeyConstant.dart';
import '../l10n/LocalizationsExtension.dart';
import '../manager/AWMC/AwmcForumOAuthManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../manager/LuoXue/LuoXueUserPlayDataManager.dart';
import '../service/AWMC/AwmcQrSyncService.dart';
import '../service/Account/AccountAuthorizationStore.dart';
import '../utils/AppTaskActivity.dart';
import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';
import 'AppUi.dart';
import 'RefreshDataDialog.dart' show launchUrlFallback;

/// 账号授权/绑定对话框的操作结果。
class AccountAuthorizationResult {
  /// 本次是否在对话框内新保存了有效的授权或绑定信息。
  final bool saved;

  /// 打开前处于无或未成功状态，且本次新保存变为成功状态时为 true。
  final bool becameSuccessful;

  /// AWMC NET 绑定的 QQ 号（落雪场景为空）。
  final String awmcQQ;

  const AccountAuthorizationResult({
    required this.saved,
    required this.becameSuccessful,
    required this.awmcQQ,
  });
}

/// 账号配置只保存授权或查询账号，刷新由独立入口执行。
Future<AccountAuthorizationResult> showAccountAuthorizationDialog(
  BuildContext context, {
  required bool luoxue,
}) =>
    AppTaskActivity.run<AccountAuthorizationResult>(() async {
      final qq = luoxue ? '' : await AccountAuthorizationStore.awmcQQ();
      final authorized = luoxue && await LuoXueOAuthManager().isLoggedIn();
      if (!context.mounted) {
        return const AccountAuthorizationResult(
          saved: false,
          becameSuccessful: false,
          awmcQQ: '',
        );
      }
      final hadBefore =
          luoxue ? authorized : RegExp(r'^\d{5,12}$').hasMatch(qq);
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AccountAuthorizationDialog(
          luoxue: luoxue,
          initialQQ: qq,
          authorized: authorized,
        ),
      );
      final saved = result != null && result.isNotEmpty;
      final becameSuccessful = saved && !hadBefore;
      final savedAwmcQQ = !luoxue && saved ? result : qq;
      if (luoxue && becameSuccessful && context.mounted) {
        await maybeOfferReverseMigrationToLuoXue(context);
      }
      return AccountAuthorizationResult(
        saved: saved,
        becameSuccessful: becameSuccessful,
        awmcQQ: savedAwmcQQ,
      );
    });

/// 若用户已绑定 AWMC NET，首次完成落雪授权后可选一次性将 AWMC NET 成绩迁入落雪。
Future<void> maybeOfferReverseMigrationToLuoXue(BuildContext context) async {
  try {
    final awmcQq = await AwmcQrSyncService.resolveAwmcNetQq();
    if (awmcQq == null || !AwmcQrSyncService.qqPattern.hasMatch(awmcQq)) return;
    final prefs = await SharedPreferences.getInstance();
    final prompted =
        prefs.getStringList(CacheKeyConstant.proberReverseMigrationPrompted) ??
            const <String>[];
    final key = 'lx:$awmcQq';
    if (prompted.contains(key)) return;
    await prefs.setStringList(
      CacheKeyConstant.proberReverseMigrationPrompted,
      [...prompted, key],
    );
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: const Text('同步已有成绩到落雪？'),
        content: const Text(
          '检测到你已绑定 AWMC NET，是否将 AWMC NET 上已有的成绩一次性迁移至刚授权的落雪账号？（不会消耗机台二维码）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('暂不'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('立即迁移'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    AppToast.show('正在从 AWMC NET 迁移成绩至落雪…');
    final res = await AwmcQrSyncService.migrateAwmcToLuoXue(awmcQq: awmcQq);
    if (!context.mounted) return;
    if (res.ok) {
      AppToast.show(
        '已迁移 ${res.totalRecords} 条成绩到落雪'
        '${res.skipped > 0 ? '（跳过 ${res.skipped} 条）' : ''}',
        tone: AppToastTone.success,
      );
    } else {
      AppToast.show(
        res.message ?? '迁移至落雪失败',
        tone: AppToastTone.error,
      );
    }
  } catch (_) {}
}

/// 若用户已绑定 AWMC NET，首次完成水鱼写入授权后可选一次性将 AWMC NET 成绩迁入水鱼。
Future<void> maybeOfferReverseMigrationToFish(
  BuildContext context, {
  required String fishQq,
}) async {
  try {
    final awmcQq = await AwmcQrSyncService.resolveAwmcNetQq();
    if (awmcQq == null || !AwmcQrSyncService.qqPattern.hasMatch(awmcQq)) return;
    final prefs = await SharedPreferences.getInstance();
    final prompted =
        prefs.getStringList(CacheKeyConstant.proberReverseMigrationPrompted) ??
            const <String>[];
    final key = 'fish:$fishQq';
    if (prompted.contains(key)) return;
    await prefs.setStringList(
      CacheKeyConstant.proberReverseMigrationPrompted,
      [...prompted, key],
    );
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: const Text('同步已有成绩到水鱼？'),
        content: const Text(
          '检测到你已绑定 AWMC NET，是否将 AWMC NET 上已有的成绩一次性迁移至刚授权的水鱼账号？（不会消耗机台二维码）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('暂不'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('立即迁移'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    AppToast.show('正在从 AWMC NET 迁移成绩至水鱼…');
    final res = await AwmcQrSyncService.migrateAwmcToFish(
      awmcQq: awmcQq,
      fishQq: fishQq,
    );
    if (!context.mounted) return;
    if (res.ok) {
      AppToast.show(
        '已迁移 ${res.totalRecords} 条成绩到水鱼'
        '${res.skipped > 0 ? '（跳过 ${res.skipped} 条）' : ''}',
        tone: AppToastTone.success,
      );
    } else {
      AppToast.show(
        res.message ?? '迁移至水鱼失败',
        tone: AppToastTone.error,
      );
    }
  } catch (_) {}
}

class _AccountAuthorizationDialog extends StatefulWidget {
  const _AccountAuthorizationDialog(
      {required this.luoxue,
      required this.initialQQ,
      required this.authorized});
  final bool luoxue;
  final String initialQQ;
  final bool authorized;
  @override
  State<_AccountAuthorizationDialog> createState() =>
      _AccountAuthorizationDialogState();
}

class _AccountAuthorizationDialogState
    extends State<_AccountAuthorizationDialog> with WidgetsBindingObserver {
  final authCodeController = TextEditingController();
  String _boundAwmcQq = '';
  bool _hasAwmcOAuthToken = false;
  bool _saving = false;
  bool _initializingProfile = false;
  String? _boundFishQq;
  bool _hasLxAuth = false;
  AwmcForumOAuthSession? _awmcOAuthSession;
  bool _awmcOAuthStarting = false;
  bool _awmcOAuthPolling = false;
  String? _awmcOAuthError;
  Timer? _awmcOAuthTimer;
  int _awmcOAuthGeneration = 0;
  late final bool _hasSavedLuoXueToken = widget.authorized;

  bool get _hasBoundAwmcQq => RegExp(r'^\d{5,12}$').hasMatch(_boundAwmcQq);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boundAwmcQq = widget.initialQQ.trim();
    if (!widget.luoxue) {
      _loadExternalSources();
      _loadAwmcOAuthState();
    }
  }

  Future<void> _loadAwmcOAuthState() async {
    final qq = _boundAwmcQq.trim();
    if (!RegExp(r'^\d{5,12}$').hasMatch(qq)) return;
    final hasToken =
        await AwmcForumOAuthManager.hasValidOAuthSession(expectedQq: qq);
    if (!mounted) return;
    setState(() => _hasAwmcOAuthToken = hasToken);
  }

  Future<void> _persistAwmcQq(String qq, {String authToken = ''}) async {
    await AwmcForumOAuthManager.saveAuthorizedSession(
      qq: qq,
      authToken: authToken,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _awmcOAuthSession != null &&
        !_saving) {
      unawaited(_pollAwmcOAuthOnce());
    }
  }

  void _stopAwmcOAuth({bool clearError = false}) {
    _awmcOAuthGeneration++;
    _awmcOAuthTimer?.cancel();
    _awmcOAuthTimer = null;
    _awmcOAuthPolling = false;
    _awmcOAuthSession = null;
    if (clearError) _awmcOAuthError = null;
  }

  Future<void> _startAwmcOAuth() async {
    if (_saving || _awmcOAuthStarting) return;
    setState(() {
      _stopAwmcOAuth(clearError: true);
      _awmcOAuthStarting = true;
    });
    final gen = _awmcOAuthGeneration;
    final res = await AwmcForumOAuthManager.instance.startSession();
    if (!mounted || gen != _awmcOAuthGeneration) return;
    if (res.session == null) {
      setState(() {
        _awmcOAuthStarting = false;
        _awmcOAuthError = res.error ?? '发起 AWMC 论坛授权失败，请稍后重试';
      });
      AppToast.show(_awmcOAuthError!, tone: AppToastTone.error);
      return;
    }
    final session = res.session!;
    setState(() {
      _awmcOAuthStarting = false;
      _awmcOAuthSession = session;
      _awmcOAuthError = null;
    });
    _awmcOAuthTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_pollAwmcOAuthOnce()),
    );
    await _openAwmcOAuthUrl(session.authorizeUrl);
  }

  Future<void> _openAwmcOAuthUrl(String url) async {
    try {
      if (await ExternalLaunchUtil.openString(url)) {
        return;
      }
    } catch (e) {
      debugPrint('打开 AWMC 论坛授权链接失败: $e');
    }
    if (!mounted) return;
    launchUrlFallback(url, context);
  }

  Future<void> _pollAwmcOAuthOnce() async {
    final session = _awmcOAuthSession;
    if (session == null || _awmcOAuthPolling || _saving) return;
    final gen = _awmcOAuthGeneration;
    _awmcOAuthPolling = true;
    try {
      final result =
          await AwmcForumOAuthManager.instance.pollStatus(session.sessionId);
      if (!mounted || gen != _awmcOAuthGeneration) return;
      switch (result.status) {
        case AwmcForumOAuthPollStatus.pending:
          return;
        case AwmcForumOAuthPollStatus.completed:
          _stopAwmcOAuth(clearError: true);
          setState(() {
            _boundAwmcQq = result.qq;
            _hasAwmcOAuthToken = result.authToken.isNotEmpty;
            _saving = true;
          });
          try {
            await _persistAwmcQq(
              result.qq,
              authToken: result.authToken,
            );
            if (!mounted) return;
            final label = result.username.isNotEmpty
                ? '${result.username}（QQ ${result.qq}）'
                : 'QQ ${result.qq}';
            AppToast.show('已通过 AWMC 论坛授权绑定 $label',
                tone: AppToastTone.success);
            Navigator.of(context).pop<String?>(result.qq);
          } catch (_) {
            if (!mounted) return;
            setState(() {
              _saving = false;
              _awmcOAuthError = '已识别 QQ ${result.qq}，但本地保存失败，请重新发起授权重试';
            });
          }
          return;
        case AwmcForumOAuthPollStatus.failed:
        case AwmcForumOAuthPollStatus.expired:
          final msg = result.error ?? 'AWMC 论坛授权未完成，请重试';
          setState(() {
            _stopAwmcOAuth();
            _awmcOAuthError = msg;
          });
          AppToast.show(msg, tone: AppToastTone.error);
          return;
      }
    } finally {
      _awmcOAuthPolling = false;
    }
  }

  Future<void> _loadExternalSources() async {
    try {
      final fishQq = await AwmcQrSyncService.resolveDivingFishQq();
      final lxAuth = await AwmcQrSyncService.hasLuoXueSyncAuth();
      if (!mounted) return;
      setState(() {
        _boundFishQq = fishQq;
        _hasLxAuth = lxAuth;
      });
    } catch (_) {}
  }

  Future<void> _initAwmcFromExternal({required bool fromFish}) async {
    if (_saving || _initializingProfile) return;
    final qq = _boundAwmcQq.trim();
    if (!RegExp(r'^\d{5,12}$').hasMatch(qq)) {
      AppToast.show('请先通过 AWMC 论坛授权绑定 QQ');
      return;
    }
    setState(() {
      _saving = true;
      _initializingProfile = true;
    });
    try {
      await AccountAuthorizationStore.saveAwmcQQ(qq);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.awmcNetSyncQQ, qq);
      final res = fromFish
          ? await AwmcQrSyncService.initAwmcProfileFromFish(
              awmcQq: qq,
              fishQq: _boundFishQq!,
            )
          : await AwmcQrSyncService.initAwmcProfileFromLuoXue(awmcQq: qq);
      if (!mounted) return;
      if (res.ok) {
        AppToast.show(
          '已用${fromFish ? '水鱼' : '落雪'}成绩初始化 AWMC NET 档案（${res.totalRecords} 条）',
          tone: AppToastTone.success,
        );
        Navigator.of(context).pop<String?>(qq);
      } else {
        AppToast.show(
          res.message ?? '初始化 AWMC NET 档案失败',
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _initializingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stopAwmcOAuth();
    WidgetsBinding.instance.removeObserver(this);
    authCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !widget.luoxue) return;
    final value = authCodeController.text.trim();
    if (value.isEmpty) {
      if (_hasSavedLuoXueToken) {
        Navigator.of(context).pop<String?>('');
      } else {
        AppToast.show(context.l10n.flowEnterYourLXNSAuthorizationCodeFirst);
      }
      return;
    }
    final failureMessage = context.l10n.accountAuthorizationFailed;
    setState(() => _saving = true);
    try {
      final token = await LuoXueOAuthManager().exchangeCodeForToken(value);
      if (token == null) throw StateError(failureMessage);
      if (!mounted) return;
      AppToast.show(context.l10n.accountConfigurationSaved,
          tone: AppToastTone.success);
      Navigator.of(context).pop<String?>('ok');
    } catch (_) {
      if (mounted) {
        AppToast.show(context.l10n.accountAuthorizationFailed,
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: AppAlertDialog(
        title: Text(widget.luoxue
            ? context.l10n.accountAuthorizeLXNS
            : context.l10n.accountLinkAWMC),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: AbsorbPointer(
                    absorbing: _saving,
                    child: widget.luoxue
                        ? _buildLuoXuePanel(Theme.of(context).brightness)
                        : _buildAwmcPanel(Theme.of(context).brightness)))),
        actions: widget.luoxue
            ? [
                TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(context.l10n.featureCancel)),
                FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving
                        ? context.l10n.flowLoading2
                        : context.l10n.save)),
              ]
            : [
                TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(context.l10n.featureClose)),
              ],
      ));

  Widget _buildLuoXuePanel(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasSavedLuoXueToken)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                context.l10n.flowLXNSAuthorizationSavedItRenewsAutomaticallyNo,
                style: TextStyle(color: AppColors.successGreen(brightness))),
          ),
        ElevatedButton(
          onPressed: () async {
            final url = LuoXueUserPlayDataManager().getAuthorizationUrl();
            try {
              if (await ExternalLaunchUtil.openString(url)) {
                return;
              } else {
                if (!mounted) return;
                launchUrlFallback(url, context);
              }
            } catch (e) {
              debugPrint('打开落雪授权链接失败: $e');
              if (!mounted) return;
              launchUrlFallback(url, context);
            }
          },
          child: Text(context.l10n.flowAuthorize2),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningOrange(brightness).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    AppColors.warningOrange(brightness).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.warningOrange(brightness)),
                  const SizedBox(width: 6),
                  Text(context.l10n.flowAuthorizationButtonNotWorking,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warningOrange(brightness))),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.l10n.flowCopyThisLinkAndOpenItManually,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.greyHint(brightness))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: Text(context.l10n.flowCopyAuthorizationLink,
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final url = LuoXueUserPlayDataManager().getAuthorizationUrl();
                  Clipboard.setData(ClipboardData(text: url));
                  AppToast.show(
                      context.l10n.flowAuthorizationLinkCopiedPasteItIntoYour,
                      tone: AppToastTone.warning);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(context.l10n.flowAfterAuthorizingCopyTheCodeShownOn,
            style:
                TextStyle(fontSize: 12, color: AppColors.greyHint(brightness))),
        const SizedBox(height: 8),
        TextField(
          controller: authCodeController,
          decoration: InputDecoration(
            labelText: context.l10n.flowEnterAuthorizationCode,
            hintText: context.l10n.flowPasteAuthorizationCode,
          ).insetLabel(context),
        ),
      ],
    );
  }

  Widget _buildAwmcPanel(Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final activeSession = _awmcOAuthSession;
    final hasBoundQq = _hasBoundAwmcQq;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBoundQq) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _hasAwmcOAuthToken
                  ? AppColors.successSurface(brightness)
                  : AppColors.warningOrange(brightness).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_hasAwmcOAuthToken
                        ? AppColors.successForeground(brightness)
                        : AppColors.warningOrange(brightness))
                    .withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _hasAwmcOAuthToken
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: _hasAwmcOAuthToken
                      ? AppColors.successForeground(brightness)
                      : AppColors.warningOrange(brightness),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasAwmcOAuthToken
                            ? '已通过 AWMC 论坛授权绑定 QQ：$_boundAwmcQq'
                            : '当前绑定 QQ：$_boundAwmcQq（旧版方式，待完成论坛 OAuth 授权）',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _hasAwmcOAuthToken
                              ? AppColors.successForeground(brightness)
                              : AppColors.warningOrange(brightness),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasAwmcOAuthToken
                            ? '原有绑定会继续保留；如需换绑，请通过下方 AWMC 论坛重新授权。'
                            : '为全面弃用 QQ 号直输，请点击下方按钮通过 AWMC 论坛完成一次 OAuth 授权升级。',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.greyHint(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'AWMC 论坛 OAuth 授权绑定',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '请登录 AWMC 论坛（bbs.wmc.pub）完成授权，系统将自动识别已验证的 QQ 邮箱并提取查分 QQ，不再支持手动输入 QQ 号。',
                style: TextStyle(
                    fontSize: 12, color: AppColors.greyHint(brightness)),
              ),
              const SizedBox(height: 10),
              if (activeSession == null)
                FilledButton.icon(
                  icon: _awmcOAuthStarting
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.login_rounded, size: 16),
                  label: Text(
                    _awmcOAuthStarting
                        ? '正在发起授权…'
                        : (hasBoundQq
                            ? '通过 AWMC 论坛重新授权 / 换绑'
                            : '通过 AWMC 论坛授权绑定'),
                  ),
                  onPressed: (_saving || _awmcOAuthStarting)
                      ? null
                      : _startAwmcOAuth,
                )
              else ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '等待在浏览器中完成 AWMC 论坛授权，完成后切回本应用即可自动识别…',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: const Text('重新打开',
                          style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () =>
                          _openAwmcOAuthUrl(activeSession.authorizeUrl),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('复制链接',
                          style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: activeSession.authorizeUrl));
                        AppToast.show('已复制 AWMC 论坛授权链接，请粘贴到浏览器打开');
                      },
                    ),
                    TextButton(
                      onPressed: () => setState(() => _stopAwmcOAuth()),
                      child: const Text('取消等待',
                          style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
              if (_awmcOAuthError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _awmcOAuthError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.linkBlue(brightness).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.linkBlue(brightness).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.linkBlue(brightness)),
                  const SizedBox(width: 6),
                  Text('AWMC NET 档案与初始化说明',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.linkBlue(brightness))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.flowAWMCNETIsAThirdPartyScore,
                style: TextStyle(
                    fontSize: 12, color: AppColors.greyHint(brightness)),
              ),
              if ((_boundFishQq != null || _hasLxAuth) && hasBoundQq) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_boundFishQq != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: Text(
                          _initializingProfile ? '正在初始化…' : '用水鱼成绩初始化档案',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: _saving
                            ? null
                            : () => _initAwmcFromExternal(fromFish: true),
                      ),
                    if (_hasLxAuth)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: Text(
                          _initializingProfile ? '正在初始化…' : '用落雪成绩初始化档案',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: _saving
                            ? null
                            : () => _initAwmcFromExternal(fromFish: false),
                      ),
                  ],
                ),
              ] else if (_boundFishQq != null || _hasLxAuth) ...[
                const SizedBox(height: 6),
                Text(
                  '完成上方论坛授权后，可在此一键使用已绑定的水鱼/落雪成绩初始化 AWMC NET 档案。',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.greyHint(brightness)),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(context.l10n.flowLinkQQUploadScoresOnAWMCNET,
                    style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  const url = 'https://net.wmc.pub/';
                  try {
                    if (await ExternalLaunchUtil.openString(url)) {
                      return;
                    }
                  } catch (e) {
                    debugPrint('打开 AWMC NET 失败: $e');
                  }
                  if (!mounted) return;
                  launchUrlFallback(url, context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
