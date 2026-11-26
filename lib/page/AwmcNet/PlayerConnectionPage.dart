import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Theme;
import 'package:flutter/services.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../manager/AWMC/AwmcNetUserPlayDataManager.dart';
import '../../service/AWMC/AwmcPlayerConnection.dart';
import '../../service/Account/AccountAuthorizationStore.dart';
import '../../service/Account/AccountSwitchService.dart';
import '../../widgets/QrQuickFillButtons.dart';
import '../../widgets/RefreshDataDialog.dart';
import '../Best50/Best50Page.dart';

enum _Step { qq, code, records, qr, confirm }

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

class _PlayerConnectionPageState extends State<PlayerConnectionPage> {
  final _qq = TextEditingController();
  final _code = TextEditingController();
  final _qr = TextEditingController();
  _Step _step = _Step.qq;
  String _challenge = '', _token = '', _ticket = '', _nickname = '';
  String? _error, _progress, _previousNickname;
  int _count = 0;
  bool _busy = true, _committing = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final session = await AwmcPlayerConnection.restore();
      if (!mounted || session == null) return;
      _qq.text = session.qq;
      _token = session.token;
      _step = _Step.records;
    } catch (_) {
      _error = 'unavailable';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _qq.dispose();
    _code.dispose();
    _qr.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    try {
      await action();
    } on PlayerConnectionError catch (e) {
      if (!mounted) return;
      _error = e.code;
      if (e.code == 'expired_session') {
        _reset(keepQQ: true);
        try {
          await AwmcPlayerConnection.forget();
        } catch (_) {
          // 服务端已拒绝该会话，新验证码验证成功后会覆盖本地凭据。
        }
      } else if (e.code == 'preview_expired' ||
          e.code == 'different_player' ||
          (_step == _Step.confirm && e.code == 'empty_scores')) {
        _ticket = '';
        _step = _Step.qr;
      }
    } on AccountUpdateBusy {
      _error = 'account_changed';
    } catch (_) {
      _error = 'unavailable';
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _committing = false;
        });
    }
  }

  void _reset({bool keepQQ = false}) {
    if (!keepQQ) _qq.clear();
    _code.clear();
    _qr.clear();
    _token = '';
    _ticket = '';
    _challenge = '';
    _step = _Step.qq;
  }

  Future<void> _send() async {
    if (!RegExp(r'^[1-9][0-9]{4,11}$').hasMatch(_qq.text)) {
      throw const PlayerConnectionError('invalid_qq');
    }
    final data =
        await AwmcPlayerConnection.request('code', fields: {'qq': _qq.text});
    if (!mounted) return;
    _challenge = data['challenge'] as String;
    _code.clear();
    _step = _Step.code;
  }

  Future<void> _verify() async {
    final revision = AccountSwitchService.revision;
    final data = await AwmcPlayerConnection.request('verify',
        fields: {'challenge': _challenge, 'code': _code.text});
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (data['qq'] != _qq.text || data['token'] is! String)
      throw const PlayerConnectionError('unavailable');
    _token = data['token'];
    await AwmcPlayerConnection.remember(_qq.text, _token);
    if (!mounted) return;
    _step = _Step.records;
    _code.clear();
    await _read(revision);
  }

  Future<void> _read(int revision) async {
    final qq = _qq.text;
    final result = await AwmcPlayerConnection.request('records', token: _token);
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final player = result['player'];
    final normalized = AwmcNetUserPlayDataManager.normalizeRecords(player);
    if (!result.containsKey('player') || (player != null && normalized == null))
      throw const PlayerConnectionError('unavailable');
    if (normalized == null || (normalized['records'] as List).isEmpty) {
      _step = _Step.qr;
      return;
    }
    bool current() =>
        mounted &&
        ModalRoute.of(context)?.isCurrent == true &&
        AccountSwitchService.revision == revision;
    if (!current()) throw const PlayerConnectionError('account_changed');
    setState(() => _committing = true);
    await AccountSwitchService.guardedRefresh(
        current,
        () => refreshAwmcNetDataWithProgress(qq, (percent, message) {
              if (mounted) setState(() => _progress = '$percent% · $message');
            }, verifiedPlayerData: normalized),
        accountId: qq);
    await AccountAuthorizationStore.saveAwmcQQ(qq);
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pushReplacement<void, void>(
          CupertinoPageRoute(builder: (_) => const B50Page()));
    }
  }

  Future<void> _preview() async {
    final qr = QrQuickFillButtons.gameCode(_qr.text);
    if (qr == null) throw const PlayerConnectionError('qr_failed');
    final data = await AwmcPlayerConnection.request('preview',
        token: _token, fields: {'qr': qr});
    if (!mounted) return;
    _ticket = data['ticket'] as String;
    _nickname = data['nickname'] as String;
    _previousNickname = data['previous_nickname'] as String?;
    _count = data['count'] as int;
    _qr.clear();
    _step = _Step.confirm;
  }

  Future<void> _confirm() async {
    final revision = AccountSwitchService.revision;
    setState(() => _committing = true);
    await AwmcPlayerConnection.request('confirm',
        token: _token, fields: {'ticket': _ticket});
    if (!mounted) return;
    _step = _Step.records;
    _ticket = '';
    await _read(revision);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (_step) {
      _Step.qq => l.qqPlayerConnect,
      _Step.code => l.qqPlayerCode,
      _Step.records => l.qqPlayerVerified,
      _Step.qr => l.qqPlayerImport,
      _Step.confirm => l.qqPlayerConfirm,
    };
    final message = switch (_error) {
      'invalid_qq' => l.flowInvalidQQID512DigitsRequired,
      'invalid_code' => l.qqPlayerInvalid,
      'expired_session' => l.qqPlayerExpired,
      'slow_down' => l.qqPlayerLimited,
      'qr_failed' => l.qqPlayerQrError,
      'different_player' => l.qqPlayerConflict,
      'preview_expired' => l.qqPlayerTicket,
      'empty_scores' => l.qqPlayerEmpty,
      'account_changed' => l.svcTheAccountChangedSoTheDataRefresh,
      null => null,
      _ => l.qqPlayerOffline,
    };
    final action = switch (_step) {
      _Step.qq => _send,
      _Step.code => _verify,
      _Step.records => () => _read(AccountSwitchService.revision),
      _Step.qr => _preview,
      _Step.confirm => _confirm,
    };
    final label = switch (_step) {
      _Step.qq => l.qqPlayerSend,
      _Step.code || _Step.records => l.qqPlayerVerified,
      _Step.qr => l.qqPlayerPreview,
      _Step.confirm => l.qqPlayerConfirm,
    };
    return PopScope(
        canPop: !_committing,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
              automaticallyImplyLeading: false,
              leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _committing
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(l.featureCancel))),
          child: SafeArea(
              child: Material(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                    children: [
                      Semantics(
                          header: true,
                          child: Text(title,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .navLargeTitleTextStyle)),
                      const SizedBox(height: 12),
                      Text(switch (_step) {
                        _Step.qq => l.qqPlayerIntro,
                        _Step.code => '${_qq.text}@qq.com',
                        _Step.records => 'QQ ${_qq.text}',
                        _Step.qr => l.qqPlayerQrHelp,
                        _Step.confirm =>
                          '$_nickname · ${l.qqPlayerScoreCount(_count)}'
                      }),
                      if (_step == _Step.confirm && _previousNickname != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(l.qqPlayerMerge(
                                _previousNickname!, _nickname))),
                      const SizedBox(height: 24),
                      if (_step == _Step.qq || _step == _Step.code)
                        CupertinoTextField(
                            key: ValueKey(_step),
                            controller: _step == _Step.qq ? _qq : _code,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            placeholder:
                                _step == _Step.qq ? l.flowQQID : l.qqPlayerCode,
                            autofillHints: _step == _Step.code
                                ? const [AutofillHints.oneTimeCode]
                                : null,
                            padding: const EdgeInsets.all(14),
                            maxLength: _step == _Step.qq ? 12 : 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) => setState(() {})),
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
                            onFilled: () => _run(_preview)),
                      ],
                      if (message != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(message,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)))),
                      const SizedBox(height: 20),
                      if (_busy)
                        Center(
                            child: Column(children: [
                          const CupertinoActivityIndicator(),
                          const SizedBox(height: 8),
                          Text(_progress ?? l.qqPlayerBusy)
                        ]))
                      else if (_step != _Step.qr || _qr.text.isNotEmpty)
                        CupertinoButton.filled(
                            onPressed: (_step == _Step.code &&
                                        _code.text.length != 6 ||
                                    _step == _Step.qq && _qq.text.length < 5)
                                ? null
                                : () => _run(action),
                            child: Text(label)),
                      if (_step == _Step.code)
                        CupertinoButton(
                            onPressed: _busy ? null : () => _run(_send),
                            child: Text(l.qqPlayerResend)),
                      if (_step == _Step.records || _step == _Step.confirm)
                        CupertinoButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _step = _Step.qr;
                                      _ticket = '';
                                      _error = null;
                                    }),
                            child: Text(l.qqPlayerImport)),
                      if (_step != _Step.qq)
                        CupertinoButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() async {
                                      if (_token.isNotEmpty)
                                        await AwmcPlayerConnection.disconnect();
                                      if (mounted) _reset();
                                    }),
                            child: Text(l.qqPlayerSwitch)),
                    ],
                  ))),
        ));
  }
}
