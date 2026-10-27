import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../utils/SecureCredentialStore.dart';
import '../widgets/RefreshDataDialog.dart'
    show RefreshDataRequest, RefreshDataSource, executeAdvancedRefreshData;
import 'AccountStore.dart';
import 'AccountSwitchService.dart';

/// 同步开始前捕获目标身份；一次同步最多刷新一次，刷新失败保留同步成功结果。
class PostSyncRefreshOperation {
  final RefreshDataSource source;
  final RefreshDataRequest request;
  final String accountId;
  final String? _credential;
  final String? _authorization;
  final int _revision;
  final String? _captureError;
  Future<String?>? _running;
  bool refreshed = false;

  PostSyncRefreshOperation._(
      this.source,
      this.request,
      this.accountId,
      this._credential,
      this._authorization,
      this._revision,
      this._captureError);

  static String _key(RefreshDataSource source) => switch (source) {
        RefreshDataSource.shuiyu => CacheKeyConstant.probeDivingFishImportToken,
        RefreshDataSource.luoxue => CacheKeyConstant.probeLxnsImportToken,
        RefreshDataSource.awmc => CacheKeyConstant.awmcNetImportToken,
      };

  static Future<PostSyncRefreshOperation> capture(RefreshDataSource source,
      {RefreshDataRequest? request}) async {
    try {
      return await _capture(source, request: request);
    } catch (_) {
      // 刷新配置读取失败不能阻断随后上传成绩。
      return PostSyncRefreshOperation._(
          source,
          request ??
              RefreshDataRequest(
                  dataSource: source,
                  qq: '',
                  authCode: '',
                  participateRankings: false,
                  showNickname: false,
                  forceFullRefresh: false),
          '',
          null,
          null,
          AccountSwitchService.revision,
          '刷新配置读取失败，请手动刷新数据');
    }
  }

  static Future<PostSyncRefreshOperation> _capture(RefreshDataSource source,
      {RefreshDataRequest? request}) async {
    await AccountSwitchService.ensureMigrated();
    final revision = AccountSwitchService.revision;
    final prefs = await SharedPreferences.getInstance();
    final metas = await AccountStore.loadAll();
    final settings = await AccountStore.settingsFor(source);
    final storedId = metas[source.key]?.id ?? '';
    final id = storedId.isNotEmpty
        ? storedId
        : switch (source) {
            RefreshDataSource.shuiyu =>
              prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '',
            RefreshDataSource.awmc => request?.qq.trim().isNotEmpty == true
                ? request!.qq.trim()
                : prefs.getString(CacheKeyConstant.awmcNetSyncQQ) ?? '',
            RefreshDataSource.luoxue => '',
          };
    final credential = await SecureCredentialStore.read(_key(source));
    final authorization = await _readAuthorization(source);
    final savedAuthorization = source == RefreshDataSource.luoxue &&
        await LuoXueOAuthManager().isLoggedIn();
    final selected = request ??
        RefreshDataRequest(
          dataSource: source,
          qq: source.idIsQQ ? id : '',
          authCode: '',
          participateRankings:
              settings[CacheKeyConstant.participateRankings] == true,
          showNickname: settings[CacheKeyConstant.showNickname] == true,
          showBriefProfile: settings[CacheKeyConstant.showBriefProfile] == true,
          forceFullRefresh: false,
          forceSourceIds: (prefs.getStringList(
                      CacheKeyConstant.advancedRefreshForceSources) ??
                  const <String>[])
              .toSet(),
          useSavedAuthorization: savedAuthorization,
        );
    final error = selected.dataSource != source
        ? '刷新来源与同步目标不同，已跳过自动刷新'
        : source.idIsQQ && id.isNotEmpty && selected.qq != id
            ? '刷新账号与同步目标不同，已跳过自动刷新'
            : null;
    return PostSyncRefreshOperation._(
        source, selected, id, credential, authorization, revision, error);
  }

  /// 返回刷新错误，null 表示成功；重复调用复用同一 Future，避免重复请求。
  Future<String?> run({required void Function(int, String) onProgress}) =>
      _running ??= _run(onProgress);

  Future<String?> _run(void Function(int, String) onProgress) async {
    // 准备失败时不再读取凭据或获取活动槽锁，确保不会降级成缺少身份保护的刷新。
    if (_captureError != null) return _captureError;
    try {
      final current = (await AccountStore.loadAll())[source.key]?.id ?? '';
      final credential = await SecureCredentialStore.read(_key(source));
      final authorization = await _readAuthorization(source);
      if ((current.isNotEmpty && current != accountId) ||
          credential != _credential ||
          authorization != _authorization) {
        throw StateError('账号或同步凭据已变化，已跳过自动刷新');
      }
      await AccountSwitchService.guardedRefresh(
        () => AccountSwitchService.revision == _revision,
        () => executeAdvancedRefreshData(request, onProgress: onProgress),
        accountId: accountId,
      );
      refreshed = true;
      return null;
    } catch (error) {
      return '$error';
    }
  }

  static Future<String?> _readAuthorization(RefreshDataSource source) =>
      // 落雪 OAuth 会正常轮换；身份由刷新回包中的 friendCode 校验，不能比较短期令牌。
      source != RefreshDataSource.shuiyu
          ? Future.value(null)
          : SecureCredentialStore.read(CacheKeyConstant.probeDivingFishToken);
}
