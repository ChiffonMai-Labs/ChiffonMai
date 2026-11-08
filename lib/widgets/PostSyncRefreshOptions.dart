import '../service/AccountAuthorizationStore.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../utils/SecureCredentialStore.dart';
import 'AdvancedRefreshDataDialog.dart';
import 'RefreshDataDialog.dart' show RefreshDataRequest, RefreshDataSource;

/// 同步成功后默认刷新，直接复用高级刷新的配置内容。
class PostSyncRefreshOptions extends StatefulWidget {
  final RefreshDataSource source;

  /// 放进同步对话框的分区时由分区标题代替，这里只保留配置内容。
  final bool showHeader;

  const PostSyncRefreshOptions({
    super.key,
    required this.source,
    this.showHeader = true,
  });

  @override
  State<PostSyncRefreshOptions> createState() => PostSyncRefreshOptionsState();
}

class PostSyncRefreshOptionsState extends State<PostSyncRefreshOptions> {
  late Future<_RefreshCredentials> _credentials;
  final _panelKey = GlobalKey<AdvancedRefreshDataPanelState>();

  @override
  void initState() {
    super.initState();
    _credentials = _loadCredentials();
  }

  Future<_RefreshCredentials> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = await SecureCredentialStore.read(
            CacheKeyConstant.probeDivingFishToken) ??
        '';
    final bindQQ =
        prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '';
    final awmcId = await AccountAuthorizationStore.awmcQQ();
    return _RefreshCredentials(
      hasDivingFishLogin: jwt.isNotEmpty,
      bindQQ: bindQQ,
      awmcQQ: awmcId.isNotEmpty
          ? awmcId
          : prefs.getString(CacheKeyConstant.awmcNetSyncQQ) ?? '',
    );
  }

  Future<RefreshDataRequest?> collectRequest() async {
    try {
      await _credentials;
      if (!mounted) return null;
      if (_panelKey.currentState == null)
        await WidgetsBinding.instance.endOfFrame;
      return await _panelKey.currentState?.collectRequest(validate: false);
    } catch (_) {
      // 继续执行同步；刷新阶段会独立给出配置或授权错误。
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          const SizedBox(height: 16),
          Text(context.l10n.flowRefreshDataAfterSync,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(context.l10n.flowRefreshAutomaticallyAfterUploadRefreshErrorsAre),
          const SizedBox(height: 12),
        ],
        FutureBuilder<_RefreshCredentials>(
          future: _credentials,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.flowCouldNotReadRefreshSettingsUploadCan),
                    TextButton(
                        onPressed: () => setState(() {
                              _credentials = _loadCredentials();
                            }),
                        child: Text(context.l10n.flowReloadRefreshSettings)),
                  ]);
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final c = snapshot.data!;
            return AdvancedRefreshDataPanel(
              key: _panelKey,
              embedded: true,
              initialSource: widget.source,
              hasDivingFishLogin: c.hasDivingFishLogin,
              bindQQ: c.bindQQ,
              awmcQQ: c.awmcQQ,
            );
          },
        ),
      ],
    );
  }
}

class _RefreshCredentials {
  final bool hasDivingFishLogin;
  final String bindQQ;
  final String awmcQQ;

  const _RefreshCredentials({
    required this.hasDivingFishLogin,
    required this.bindQQ,
    required this.awmcQQ,
  });
}
