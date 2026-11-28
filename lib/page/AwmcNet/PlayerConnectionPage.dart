import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Theme;

import '../../l10n/LocalizationsExtension.dart';
import '../../manager/AWMC/AwmcForumOAuthManager.dart';
import '../../manager/AWMC/AwmcNetException.dart';
import '../../manager/AWMC/AwmcNetUserPlayDataManager.dart';
import '../../service/AWMC/AwmcPlayerConnection.dart';
import '../../service/AWMC/AwmcQrSyncService.dart';
import '../../service/Account/AccountAuthorizationStore.dart';
import '../../service/Account/AccountSwitchService.dart';
import '../../utils/ExternalLaunchUtil.dart';
import '../../widgets/ExpressiveLoadingIndicator.dart';
import '../../widgets/QrQuickFillButtons.dart';
import '../../widgets/RefreshDataDialog.dart';
import '../Best50/Best50Page.dart';

enum _Step { oauth, records, qr }

class PlayerConnectionPage extends StatefulWidget {
  const PlayerConnectionPage({super.key});

  static Future<void> open(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<void>(CupertinoPageRoute<void>(
        builder: (_) => const PlayerConnectionPage(), fullscreenDialog: true));
  }

  @override
  State<PlayerConnectionPage> createState() => _PlayerConnectionPageState();
}

class _PlayerConnectionPageState extends State<PlayerConnectionPage>
    with WidgetsBindingObserver {
  final _qr = TextEditingController();
  _Step _step = _Step.oauth;
  String _qq = '', _username = '';
  String? _errorCode, _errorMessage, _progress;
  bool _busy = true, _committing = false;
  AwmcForumOAuthSession? _oauthSession;
  bool _oauthPolling = false;
  Timer? _oauthTimer;
  int _oauthGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  Future<void> _restore() async {
    try {
      final qq = (await AccountAuthorizationStore.awmcQQ()).trim();
      final hasOAuth = qq.isNotEmpty &&
          await AwmcForumOAuthManager.hasValidOAuthSession(expectedQq: qq);
      if (!mounted || !hasOAuth) return;
      _qq = qq;
      _step = _Step.records;
    } catch (_) {
      _errorCode = 'unavailable';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _stopOAuth();
    WidgetsBinding.instance.removeObserver(this);
    _qr.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 浏览器授权完成后切回应用，立即补查一次会话状态，无需等下一轮定时轮询。
    if (state == AppLifecycleState.resumed &&
        _oauthSession != null &&
        !_busy &&
        !_committing) {
      unawaited(_pollOAuthOnce());
    }
  }

  void _stopOAuth({bool clearError = false}) {
    _oauthGeneration++;
    _oauthTimer?.cancel();
    _oauthTimer = null;
    _oauthPolling = false;
    _oauthSession = null;
    if (clearError) {
      _errorCode = null;
      _errorMessage = null;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _committing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _errorCode = null;
      _errorMessage = null;
      _progress = null;
    });
    try {
      await action();
    } on AccountUpdateBusy {
      if (mounted) _errorCode = 'account_changed';
    } catch (_) {
      if (mounted) _errorCode = 'unavailable';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _committing = false;
        });
      }
    }
  }

  void _reset() {
    _stopOAuth(clearError: true);
    _qq = '';
    _username = '';
    _qr.clear();
    _progress = null;
    _step = _Step.oauth;
  }

  Future<void> _startOAuth() async {
    if (_busy || _committing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _stopOAuth(clearError: true);
      _busy = true;
      _progress = null;
    });
    final gen = _oauthGeneration;
    try {
      final res = await AwmcForumOAuthManager.instance.startSession();
      if (!mounted || gen != _oauthGeneration) return;
      if (res.session == null) {
        _errorCode = 'unavailable';
        _errorMessage = res.error;
        return;
      }
      final session = res.session!;
      _oauthSession = session;
      _oauthTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_pollOAuthOnce()),
      );
      await _openOAuthUrl(session.authorizeUrl);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openOAuthUrl(String url) async {
    try {
      if (await ExternalLaunchUtil.openString(url)) return;
    } catch (_) {}
    if (!mounted) return;
    await ExternalLaunchUtil.copyFallback(context, url);
  }

  Future<void> _pollOAuthOnce() async {
    final session = _oauthSession;
    if (session == null || _oauthPolling || _committing) return;
    final gen = _oauthGeneration;
    _oauthPolling = true;
    try {
      final result =
          await AwmcForumOAuthManager.instance.pollStatus(session.sessionId);
      if (!mounted || gen != _oauthGeneration) return;
      switch (result.status) {
        case AwmcForumOAuthPollStatus.pending:
          return;
        case AwmcForumOAuthPollStatus.completed:
          _stopOAuth(clearError: true);
          setState(() {
            _busy = true;
            _progress = null;
          });
          try {
            await AwmcForumOAuthManager.saveAuthorizedSession(
              qq: result.qq,
              authToken: result.authToken,
            );
            // 清掉旧版邮件验证码会话残留，统一收敛到 OAuth 2.0 凭据。
            try {
              await AwmcPlayerConnection.forget();
            } catch (_) {}
            if (!mounted) return;
            _qq = result.qq;
            _username = result.username;
            _step = _Step.records;
            await _read(AccountSwitchService.revision);
          } on AccountUpdateBusy {
            if (mounted) _errorCode = 'account_changed';
          } catch (_) {
            if (mounted) _errorCode = 'unavailable';
          } finally {
            if (mounted) {
              setState(() {
                _busy = false;
                _committing = false;
              });
            }
          }
          return;
        case AwmcForumOAuthPollStatus.failed:
        case AwmcForumOAuthPollStatus.expired:
          setState(() {
            _stopOAuth();
            _errorCode = result.status == AwmcForumOAuthPollStatus.expired
                ? 'expired_session'
                : 'unavailable';
            _errorMessage = result.error;
          });
          return;
      }
    } finally {
      _oauthPolling = false;
    }
  }

  Future<void> _read(int revision) async {
    final qq = _qq;
    final Map<String, dynamic> data;
    try {
      data = await AwmcNetUserPlayDataManager().fetchUserPlayData(qq);
    } on AwmcNetException catch (e) {
      if (!mounted) return;
      if (e.isNotFound) {
        _step = _Step.qr;
        _errorCode = null;
        _errorMessage = null;
        return;
      }
      _errorCode = 'unavailable';
      _errorMessage = e.message;
      return;
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if ((data['records'] as List).isEmpty) {
      _step = _Step.qr;
      return;
    }
    bool current() =>
        mounted &&
        ModalRoute.of(context)?.isCurrent == true &&
        AccountSwitchService.revision == revision;
    if (!current()) {
      _errorCode = 'account_changed';
      return;
    }
    setState(() => _committing = true);
    await AccountSwitchService.guardedRefresh(
      current,
      () => refreshAwmcNetDataWithProgress(
        qq,
        (percent, message) {
          if (mounted) setState(() => _progress = '$percent% · $message');
        },
        verifiedPlayerData: data,
      ),
      accountId: qq,
    );
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pushReplacement<void, void>(
          CupertinoPageRoute(builder: (_) => const B50Page()));
    }
  }

  Future<void> _importQr() async {
    final qr = QrQuickFillButtons.gameCode(_qr.text);
    if (qr == null) {
      _errorCode = 'qr_failed';
      return;
    }
    final res = await AwmcQrSyncService.syncByQr(qrCode: qr, awmcQq: _qq);
    if (!mounted) return;
    if (res.code == 'AWMC_OAUTH_REQUIRED') {
      await AwmcForumOAuthManager.clearAuthorizedSession();
      if (!mounted) return;
      _reset();
      _errorCode = 'expired_session';
      _errorMessage = res.errorMessage;
      return;
    }
    if (!res.ok || !(res.awmc?.ok ?? false)) {
      _errorCode = 'qr_failed';
      _errorMessage = res.awmc?.message ?? res.errorMessage;
      return;
    }
    _qr.clear();
    _step = _Step.records;
    await _read(AccountSwitchService.revision);
  }

  Future<void> _switchAccount() async {
    _stopOAuth(clearError: true);
    await AwmcForumOAuthManager.clearAuthorizedSession();
    try {
      await AwmcPlayerConnection.forget();
    } catch (_) {}
    if (mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (_step) {
      _Step.oauth => l.qqPlayerConnect,
      _Step.records => l.qqPlayerVerified,
      _Step.qr => l.qqPlayerImport,
    };
    final message = _errorMessage ??
        switch (_errorCode) {
          'expired_session' => l.qqPlayerExpired,
          'qr_failed' => l.qqPlayerQrError,
          'account_changed' => l.svcTheAccountChangedSoTheDataRefresh,
          null => null,
          _ => l.qqPlayerOffline,
        };
    final accountSubtitle =
        _username.isNotEmpty ? '$_username · QQ $_qq' : 'QQ $_qq';
    final isWaitingOAuth = _step == _Step.oauth && _oauthSession != null;

    return PopScope(
      canPop: !_committing,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed:
                _committing ? null : () => Navigator.of(context).maybePop(),
            child: Text(l.featureCancel),
          ),
        ),
        child: SafeArea(
          child: Material(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navLargeTitleTextStyle,
                  ),
                ),
                const SizedBox(height: 12),
                Text(switch (_step) {
                  _Step.oauth => l.qqPlayerIntro,
                  _Step.records => accountSubtitle,
                  _Step.qr => '$accountSubtitle\n${l.qqPlayerQrHelp}',
                }),
                const SizedBox(height: 24),
                if (_step == _Step.qr) ...[
                  CupertinoTextField(
                    controller: _qr,
                    enabled: !_busy,
                    placeholder: l.flowQRCodeContent,
                    autocorrect: false,
                    enableSuggestions: false,
                    padding: const EdgeInsets.all(14),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  QrQuickFillButtons(
                    controller: _qr,
                    enabled: !_busy,
                    onFilled: () => _run(_importQr),
                  ),
                ],
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_busy)
                  Center(
                    child: Column(children: [
                      const ExpressiveLoadingIndicator.contained(size: 44),
                      const SizedBox(height: 8),
                      Text(_progress ?? l.qqPlayerBusy),
                    ]),
                  )
                else if (isWaitingOAuth) ...[
                  Center(
                    child: Column(children: [
                      const ExpressiveLoadingIndicator.contained(size: 44),
                      const SizedBox(height: 8),
                      Text(
                        l.qqPlayerOAuthWaiting,
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () =>
                        unawaited(_openOAuthUrl(_oauthSession!.authorizeUrl)),
                    child: Text(l.qqPlayerOAuthReopen),
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        setState(() => _stopOAuth(clearError: true)),
                    child: Text(l.qqPlayerOAuthCancel),
                  ),
                ] else if (_step == _Step.oauth)
                  CupertinoButton.filled(
                    onPressed: _startOAuth,
                    child: Text(l.qqPlayerSend),
                  )
                else if (_step == _Step.records)
                  CupertinoButton.filled(
                    onPressed: () =>
                        _run(() => _read(AccountSwitchService.revision)),
                    child: Text(l.qqPlayerVerified),
                  )
                else if (_qr.text.isNotEmpty)
                  CupertinoButton.filled(
                    onPressed: () => _run(_importQr),
                    child: Text(l.qqPlayerConfirm),
                  ),
                if (!_busy && _step == _Step.records)
                  CupertinoButton(
                    onPressed: () => setState(() {
                      _step = _Step.qr;
                      _errorCode = null;
                      _errorMessage = null;
                    }),
                    child: Text(l.qqPlayerImport),
                  ),
                if (!_busy && _step != _Step.oauth)
                  CupertinoButton(
                    onPressed: () => _run(_switchAccount),
                    child: Text(l.qqPlayerSwitch),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
