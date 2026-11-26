import '../service/Account/AccountAuthorizationStore.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/SecureCredentialStore.dart';
import 'AdvancedRefreshDataDialog.dart';
import 'AppUi.dart' show AnimatedReveal;
import 'RefreshDataDialog.dart' show RefreshDataRequest, RefreshDataSource;

/// 同步成功后默认刷新，直接复用高级刷新的配置内容。
class PostSyncRefreshOptions extends StatefulWidget {
  final RefreshDataSource? source;
  final Set<RefreshDataSource>? syncSources;
  final String awmcSyncQQ;

  /// 放进同步对话框的分区时由分区标题代替，这里只保留配置内容。
  final bool showHeader;

  const PostSyncRefreshOptions({
    super.key,
    required RefreshDataSource this.source,
    this.showHeader = true,
  })  : syncSources = null,
        awmcSyncQQ = '';

  const PostSyncRefreshOptions.multi({
    super.key,
    required Set<RefreshDataSource> this.syncSources,
    required this.awmcSyncQQ,
  })  : source = null,
        showHeader = false;

  @override
  State<PostSyncRefreshOptions> createState() => PostSyncRefreshOptionsState();
}

class PostSyncRefreshOptionsState extends State<PostSyncRefreshOptions> {
  late Future<_RefreshCredentials> _credentials;
  final _panelKey = GlobalKey<AdvancedRefreshDataPanelState>();
  bool _expanded = false;

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

  Future<Map<RefreshDataSource, RefreshDataRequest>> collectSyncRequests(
      Set<RefreshDataSource> sources) async {
    try {
      await _credentials;
      if (!mounted) return const {};
      if (_panelKey.currentState == null) {
        await WidgetsBinding.instance.endOfFrame;
      }
      return await _panelKey.currentState?.collectSyncRequests(sources) ?? const {};
    } catch (_) {
      // 刷新配置不可用时由同步后的刷新入口读取已保存的配置。
      return const {};
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
          Text(
              context.l10n.flowRefreshAutomaticallyAfterUploadRefreshErrorsAre),
          const SizedBox(height: 12),
        ],
        Semantics(
          expanded: _expanded,
          child: Material(
            color: AppSurfaces.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.flowAdvancedDataRefresh,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppDesignTokens.motion(
                          context, AppDesignTokens.mediumMotion),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 保留面板状态，收起时提交仍会读取已选配置。
        AnimatedReveal(
          visible: _expanded,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FutureBuilder<_RefreshCredentials>(
            future: _credentials,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context
                          .l10n.flowCouldNotReadRefreshSettingsUploadCan),
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
                syncSources: widget.syncSources,
                hasDivingFishLogin: c.hasDivingFishLogin,
                bindQQ: c.bindQQ,
                  awmcQQ: c.awmcQQ.isNotEmpty ? c.awmcQQ : widget.awmcSyncQQ,
                );
              },
            ),
          ),
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
