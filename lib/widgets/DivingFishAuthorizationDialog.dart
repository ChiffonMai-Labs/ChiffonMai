import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../l10n/AppMessages.dart';
import '../l10n/LocalizationsExtension.dart';
import '../l10n/app_localizations.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/DivingFishProbeManager.dart' show SafeMapAccess;
import '../utils/ApiClient.dart';
import '../utils/AppTheme.dart';
import '../utils/SecureCredentialStore.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';

/// 读取水鱼账号资料；未登录水鱼时返回 null。
Future<Map<String, dynamic>?> fetchDivingFishProfile() async {
  final jwt =
      await SecureCredentialStore.read(CacheKeyConstant.probeDivingFishToken);
  if (jwt == null || jwt.isEmpty) return null;
  final response = await ApiClient.get(
    Uri.parse(ApiUrls.DivingFishProfileApi),
    headers: {
      'Content-Type': 'application/json',
      'Cookie': 'jwt_token=$jwt',
    },
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(appL10n
      .flowCouldNotLoadAccountDetailsP0((response.statusCode).toString()));
}

/// 水鱼授权：账号资料 + 授权状态 + 打开授权链接 / 重新授权。
Future<void> showDivingFishAuthorizationDialog(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<void>(
    context: context,
    builder: (_) => const _DivingFishAuthorizationDialog(),
  );
}

class _DivingFishAuthorizationDialog extends StatefulWidget {
  const _DivingFishAuthorizationDialog();

  @override
  State<_DivingFishAuthorizationDialog> createState() =>
      _DivingFishAuthorizationDialogState();
}

class _DivingFishAuthorizationDialogState
    extends State<_DivingFishAuthorizationDialog> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  bool _checking = false;
  bool _opening = false;

  String get _qq => _profile?.tryGet<String>('bind_qq') ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await fetchDivingFishProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
      await _check();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _check() async {
    final qq = _qq;
    if (qq.isEmpty) return;
    setState(() => _checking = true);
    // 结果写进共享通知器，绑定与授权管理的状态标签同步更新。
    await DivingFishOAuthManager().checkAuthorization(qq);
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _authorize() async {
    final l10n = context.l10n;
    final qq = _qq;
    if (qq.isEmpty) {
      AppToast.show(l10n.flowNoQQIDFoundRefreshDataOr,
          tone: AppToastTone.warning);
      return;
    }
    setState(() => _opening = true);
    final ok = await DivingFishOAuthManager().openBindingLink(qq);
    if (!mounted) return;
    setState(() => _opening = false);
    AppToast.show(
        ok
            ? l10n.flowAuthorizationOpenedCompleteItInYourBrowser
            : l10n.flowCouldNotStartAuthorizationTryAgain,
        tone: ok ? AppToastTone.success : AppToastTone.error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final profile = _profile;
    final Widget body;
    if (_loading) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      body = Text(_error!,
          style: TextStyle(color: AppColors.errorRed(brightness)));
    } else if (profile == null) {
      body = Text(l10n.flowNotSignedInToDivingFish,
          style:
              TextStyle(fontSize: 13, color: AppColors.greyHint(brightness)));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._profileRows(l10n, profile, brightness),
          const Divider(height: 24),
          ValueListenableBuilder<bool?>(
            valueListenable: DivingFishOAuthManager().authorizationState,
            builder: (context, authorized, _) =>
                _statusSection(l10n, brightness, authorized),
          ),
        ],
      );
    }
    return AppAlertDialog(
      title: Text(l10n.flowDivingFishAuthorization),
      content: SingleChildScrollView(child: body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.featureClose),
        ),
      ],
    );
  }

  List<Widget> _profileRows(AppLocalizations l10n, Map<String, dynamic> p,
      Brightness brightness) {
    String text(String key, String fallback) {
      final value = p.tryGet<String>(key) ?? '';
      return value.isEmpty ? fallback : value;
    }

    return [
      _infoRow(l10n.flowUsername, text('username', l10n.flowNone2), brightness),
      _infoRow(l10n.flowNickname, text('nickname', l10n.flowNone2), brightness),
      _infoRow(
          l10n.flowVersionTitle, text('plate', l10n.flowNone2), brightness),
      _infoRow(l10n.flowRatingRank,
          _ratingName(l10n, p.tryGet<int>('additional_rating') ?? 0), brightness),
      _infoRow(
          l10n.flowLinkedQQ, text('bind_qq', l10n.flowNotLinked), brightness),
      _infoRow(l10n.flowChannelID, text('qq_channel_uid', l10n.flowNotLinked),
          brightness),
    ];
  }

  Widget _statusSection(
      AppLocalizations l10n, Brightness brightness, bool? authorized) {
    final known = _qq.isNotEmpty && !_checking;
    final color = !known || authorized == null
        ? AppColors.greyHint(brightness)
        : authorized
            ? AppColors.successGreen(brightness)
            : AppColors.warningOrange(brightness);
    final icon = !known || authorized == null
        ? Icons.verified_user_outlined
        : authorized
            ? Icons.check_circle
            : Icons.warning_amber;
    final Widget status;
    if (_checking) {
      status = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_qq.isEmpty) {
      status = Text(l10n.flowNoQQIDFoundRefreshDataOr,
          style: TextStyle(color: color, fontSize: 13));
    } else if (authorized == false) {
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.flowNotAuthorized,
              style: TextStyle(color: color, fontSize: 13)),
          const SizedBox(height: 6),
          Text(l10n.flowReadingDivingFishScoresRequiresBrowserAuthorization,
              style: TextStyle(
                  fontSize: 12, color: AppColors.greyHint(brightness))),
        ],
      );
    } else {
      status = Text(
          authorized == true ? l10n.flowAuthorized : l10n.featureStatusUnknown,
          style: TextStyle(color: color, fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(l10n.accountBindingDivingFishAuth,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              )),
        ]),
        const SizedBox(height: 8),
        status,
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
            onPressed: _opening || _checking ? null : _authorize,
            child: Text(
              authorized == true
                  ? l10n.flowAuthorizeAgain
                  : l10n.flowOpenAuthorizationLink,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          OutlinedButton(
            onPressed: _checking || _qq.isEmpty ? null : _check,
            child: Text(l10n.accountBindingRecheck,
                style: const TextStyle(fontSize: 13)),
          ),
        ]),
      ],
    );
  }

  Widget _infoRow(String label, String value, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: AppColors.greyHint(brightness), fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _ratingName(AppLocalizations l10n, int rating) {
    final names = [
      l10n.flowBeginner,
      l10n.flow1stDan,
      l10n.flow2ndDan,
      l10n.flow3rdDan,
      l10n.flow4thDan,
      l10n.flow5thDan,
      l10n.flow6thDan,
      l10n.flow7thDan,
      l10n.flow8thDan,
      l10n.flow9thDan,
      l10n.flow10thDan,
      l10n.flowShin1stDan,
      l10n.flowShin2ndDan,
      l10n.flowShin3rdDan,
      l10n.flowShin4thDan,
      l10n.flowShin5thDan,
      l10n.flowShin6thDan,
      l10n.flowShin7thDan,
      l10n.flowShin8thDan,
      l10n.flowShin9thDan,
      l10n.flowShin10thDan,
      l10n.flowShinKaiden,
      l10n.flowUraKaiden,
    ];
    if (rating < 0 || rating >= names.length) return '$rating';
    return '${names[rating]} ($rating)';
  }
}
