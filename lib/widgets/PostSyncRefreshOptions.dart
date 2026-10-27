import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../service/AccountStore.dart';
import '../utils/SecureCredentialStore.dart';
import 'AdvancedRefreshDataDialog.dart';
import 'RefreshDataDialog.dart' show RefreshDataRequest, RefreshDataSource;

/// 同步成功后默认刷新，直接复用高级刷新的配置内容。
class PostSyncRefreshOptions extends StatefulWidget {
  final RefreshDataSource source;

  const PostSyncRefreshOptions({
    super.key,
    required this.source,
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
    final metas = await AccountStore.loadAll();
    final awmcId = metas[RefreshDataSource.awmc.key]?.id ?? '';
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
        const SizedBox(height: 16),
        Text('同步成功后刷新数据', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        const Text('成绩上传成功后自动刷新；刷新失败会单独提示。'),
        const SizedBox(height: 12),
        FutureBuilder<_RefreshCredentials>(
          future: _credentials,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('刷新配置读取失败，上传可继续，刷新错误将单独提示。'),
                    TextButton(
                        onPressed: () => setState(() {
                              _credentials = _loadCredentials();
                            }),
                        child: const Text('重新读取刷新配置')),
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
