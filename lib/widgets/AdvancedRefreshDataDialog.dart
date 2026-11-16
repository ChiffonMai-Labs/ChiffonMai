import '../l10n/AppMessages.dart';
import '../l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'RankingPrivacyOptions.dart';
import '../widgets/AnimatedChoiceBar.dart';
import 'package:flutter/material.dart';

import '../constant/CacheKeyConstant.dart';
import '../manager/DivingFishProbeManager.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../service/AccountStore.dart';
import '../utils/AppTheme.dart';
import '../utils/ApiClient.dart';
import '../utils/CacheSourceRegistry.dart';
import '../utils/AppDesignTokens.dart';
import 'RefreshDataDialog.dart'
    show CurrentDataSourceNotifier, RefreshDataRequest, RefreshDataSource;
import 'DivingFishAccountSection.dart';
import '../widgets/AppDialogs.dart';
import 'AppUi.dart' show AnimatedReveal, FadeSwitcher;
import '../widgets/AppToast.dart';

/// 单条连通性测试结果。
class _TestResult {
  final bool success;
  final int? statusCode;
  final int latencyMs;
  final String? error;
  const _TestResult({
    required this.success,
    required this.statusCode,
    required this.latencyMs,
    this.error,
  });
}

class AdvancedRefreshDataPanel extends StatefulWidget {
  /// 只表示「有没有登录水鱼」（JWT 非空）；「登录了但没填 QQ」是另一档，见 [DivingFishQqState]。
  final bool hasDivingFishLogin;

  /// 从水鱼 `/player/profile` 读到的 `bind_qq`（只认可信来源，不使用 `cachedQQ`）。
  final String bindQQ;

  /// AWMC NET 账号存档里的 QQ（按源区分，不会串到别的账号）。
  final String awmcQQ;

  /// 打开对话框时预选的数据源（账号切换面板「去刷新」时传入）。
  final RefreshDataSource? initialSource;
  final bool embedded;
  final Set<RefreshDataSource>? syncSources;

  const AdvancedRefreshDataPanel({
    super.key,
    required this.hasDivingFishLogin,
    required this.bindQQ,
    required this.awmcQQ,
    this.initialSource,
    this.embedded = false,
    this.syncSources,
  });

  @override
  State<AdvancedRefreshDataPanel> createState() =>
      AdvancedRefreshDataPanelState();
}

class AdvancedRefreshDataPanelState extends State<AdvancedRefreshDataPanel> {
  late RefreshDataSource _currentDataSource;

  /// 当前生效的水鱼 QQ（「我已填好，重新读取」后可变）。
  late String _bindQQ = widget.bindQQ;

  /// 正在重新读取水鱼账号里的「绑定 QQ 号」。
  bool _reloadingQq = false;

  bool? _isAuthorized;
  bool _isCheckingAuth = false;

  /// 已经把用户送去授权页、正等他回来点「重新检测」。
  bool _consentPending = false;

  /// 正在手动重新检测授权状态。
  bool _recheckingAuth = false;

  final _rankingSettings =
      <RefreshDataSource, ({bool participate, bool nickname, bool brief})>{};
  bool _hasSavedLuoXueToken = false;
  bool _confirming = false;
  late final Future<void> _settingsReady;
  late Future<void> _rankingSettingsReady;

  /// 是否强制刷新。默认关闭，勾选后才展开缓存源选择区域并默认全选。
  bool _forceRefresh = false;

  /// 用户勾选要强制刷新的缓存源 ID 集合（仅在 [_forceRefresh] 开启时生效）。
  final Set<String> _checkedIds = <String>{};

  /// 每个缓存源当前显示的剩余有效期文案（异步加载）
  late Map<String, String> _validities;

  /// 正在测试的缓存源 ID（同一时刻只允许一个）
  String? _testingId;

  /// 每个缓存源最近的连通性测试结果
  final Map<String, _TestResult> _testResults = {};

  @override
  void initState() {
    super.initState();
    _currentDataSource =
        widget.initialSource ?? CurrentDataSourceNotifier.instance.value;
    _validities = {
      for (final s in CacheSourceRegistry.all) s.id: appL10n.flowLoading2
    };
    _rankingSettingsReady = _loadRankingSettings(widget.syncSources == null
        ? [_currentDataSource]
        : RefreshDataSource.values);
    _settingsReady = _loadLuoXueToken();
    _loadAllValidities();
    if (_bindQQ.isNotEmpty) {
      _checkAuthorization();
    }
  }

  Future<void> _loadLuoXueToken() async {
    final loggedIn = await LuoXueOAuthManager().isLoggedIn();
    if (mounted) setState(() => _hasSavedLuoXueToken = loggedIn);
  }

  Future<void> _checkAuthorization() async {
    final qq = _bindQQ;
    if (qq.isEmpty) return;
    setState(() => _isCheckingAuth = true);
    final result = await DivingFishOAuthManager().checkAuthorization(qq);
    if (!mounted) return;
    setState(() {
      _isAuthorized = result;
      _isCheckingAuth = false;
    });
  }

  /// 「我已填好，重新读取」：重新读一次水鱼账号上的 `bind_qq`（见 RefreshDataDialog 同名方法）。
  Future<void> _reloadBindQq() async {
    setState(() => _reloadingQq = true);
    String? qq;
    try {
      qq = await DivingFishProbeManager().fetchBindQQ();
    } catch (e) {
      debugPrint('重新读取水鱼绑定 QQ 失败: $e');
    }
    if (!mounted) return;
    setState(() {
      _reloadingQq = false;
      if (qq != null && qq.isNotEmpty) _bindQQ = qq;
    });

    if (qq == null || qq.isEmpty) {
      AppToast.show(context.l10n.flowStillNoQQIDFoundCheckThat,
          tone: AppToastTone.warning);
      return;
    }
    AppToast.show(context.l10n.flowLinkedQQFoundP0((qq).toString()),
        tone: AppToastTone.success);
    await _checkAuthorization();
  }

  /// 「去授权」：发起设备码绑定并打开授权页（不自动重查，见下方注释）。
  Future<void> _startAuthorization() async {
    final qq = _bindQQ;
    if (qq.isEmpty) {
      AppToast.show(context.l10n.flowNoQQIDFound, tone: AppToastTone.warning);
      return;
    }
    setState(() => _recheckingAuth = true);
    final ok = await DivingFishOAuthManager().openBindingLink(qq);
    if (!mounted) return;
    setState(() {
      _recheckingAuth = false;
      if (ok) _consentPending = true;
    });
    AppToast.show(
        ok
            ? context.l10n.flowAuthorizationOpenedReturnAfterAuthorizingAndTap
            : context.l10n.flowCouldNotStartAuthorizationTryAgain,
        tone: AppToastTone.success);
  }

  /// 「我已授权，重新检测」：显式重查一次授权状态。
  Future<void> _recheckAuthorization() async {
    final qq = _bindQQ;
    if (qq.isEmpty) {
      AppToast.show(context.l10n.flowNoQQIDFound, tone: AppToastTone.warning);
      return;
    }
    setState(() => _recheckingAuth = true);
    final result = await DivingFishOAuthManager().checkAuthorization(qq);
    if (!mounted) return;
    setState(() {
      _recheckingAuth = false;
      _isAuthorized = result;
      if (result == true) _consentPending = false;
    });
    if (result == true) {
      AppToast.show(context.l10n.flowAuthorizedYouCanNowRefreshData,
          tone: AppToastTone.success);
    } else if (result == false) {
      AppToast.show(
          context.l10n.flowAuthorizationNotDetectedApproveAccessInYour,
          tone: AppToastTone.warning);
    } else {
      AppToast.show(context.l10n.flowCheckFailedVerifyYourConnectionAndTry,
          tone: AppToastTone.error);
    }
  }

  Future<void> _loadRankingSettings(Iterable<RefreshDataSource> sources) async {
    await Future.wait(sources.map((source) async {
      try {
        final settings = await AccountStore.settingsFor(source);
        if (!mounted || _rankingSettings.containsKey(source)) return;
        setState(() {
          _rankingSettings[source] = (
            participate: settings[CacheKeyConstant.participateRankings] == true,
            nickname: settings[CacheKeyConstant.showNickname] == true,
            brief: settings[CacheKeyConstant.showBriefProfile] == true,
          );
        });
      } catch (error) {
        debugPrint('读取 ${source.key} 的排行榜隐私设置失败：$error');
      }
    }));
  }

  Future<void> _loadAllValidities() async {
    // 并行预取所有缓存源的剩余有效期
    final futures = <Future<void>>[];
    for (final source in CacheSourceRegistry.all) {
      futures.add(() async {
        final v = await formatRemainingValidity(source);
        if (!mounted) return;
        setState(() => _validities[source.id] = v);
      }());
    }
    await Future.wait(futures);
  }

  /// 测试 [sourceId] 对应 API 的连通性：发 GET、测延迟、显示 ✓/✗ + 状态码/延迟。
  Future<void> _testSource(String sourceId) async {
    final source = CacheSourceRegistry.all.firstWhere((s) => s.id == sourceId);
    setState(() => _testingId = sourceId);
    final sw = Stopwatch()..start();
    try {
      final response = await ApiClient.get(
        Uri.parse(source.apiUrl),
        timeout: const Duration(seconds: 8),
      );
      sw.stop();
      if (!mounted) return;
      final ok = response.statusCode >= 200 && response.statusCode < 400;
      setState(() {
        _testResults[sourceId] = _TestResult(
          success: ok,
          statusCode: response.statusCode,
          latencyMs: sw.elapsedMilliseconds,
          error: ok ? null : 'HTTP ${response.statusCode}',
        );
        _testingId = null;
      });
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _testResults[sourceId] = _TestResult(
          success: false,
          statusCode: null,
          latencyMs: sw.elapsedMilliseconds,
          error: e.toString().split('\n').first,
        );
        _testingId = null;
      });
    }
  }

  Future<RefreshDataRequest?> collectRequest({bool validate = true}) async {
    await Future.wait([_settingsReady, _rankingSettingsReady]);
    if (!mounted) return null;
    // 同步表单先收集配置；缺少刷新授权只影响同步后的刷新，不阻止成绩上传。
    if (validate) {
      // 水鱼：三态分别给不同交代（同 RefreshDataDialog）
      if (_currentDataSource == RefreshDataSource.shuiyu) {
        switch (resolveDivingFishQqState(
          loggedIn: widget.hasDivingFishLogin,
          bindQq: _bindQQ,
        )) {
          case DivingFishQqState.notLoggedIn:
            AppToast.show(context.l10n.flowSignInThroughMeSignInTo,
                tone: AppToastTone.warning);
            return null;
          case DivingFishQqState.noBindQq:
            AppToast.show(context.l10n.flowYourDivingFishAccountHasNoQQ,
                tone: AppToastTone.warning);
            return null;
          case DivingFishQqState.bound:
            break;
        }
      }
      // 落雪必须先在独立授权入口保存令牌，刷新表单不处理授权码。
      if (_currentDataSource == RefreshDataSource.luoxue &&
          !_hasSavedLuoXueToken) {
        AppToast.show(context.l10n.accountAuthorizeLXNSFirst,
            tone: AppToastTone.warning);
        return null;
      }
      // AWMC NET 无需登录，但必须有 QQ 号才查得到
      if (_currentDataSource == RefreshDataSource.awmc) {
        final qq = widget.awmcQQ.trim();
        if (qq.isEmpty) {
          AppToast.show(context.l10n.accountLinkAWMCFirst,
              tone: AppToastTone.warning);
          return null;
        }
        if (!RegExp(r'^\d{5,12}$').hasMatch(qq)) {
          AppToast.show(context.l10n.flowInvalidQQID512DigitsRequired);
          return null;
        }
      }
    }

    return _requestFor(_currentDataSource, _selectedCacheIds);
  }

  Set<String> get _selectedCacheIds =>
      _forceRefresh ? Set<String>.unmodifiable(_checkedIds) : const {};

  Future<Map<RefreshDataSource, RefreshDataRequest>> collectSyncRequests(
      Set<RefreshDataSource> sources) async {
    await Future.wait([_settingsReady, _rankingSettingsReady]);
    if (!mounted) return const {};
    final cacheIds = _selectedCacheIds;
    return {
      for (final source in sources) source: _requestFor(source, cacheIds)
    };
  }

  RefreshDataRequest _requestFor(
      RefreshDataSource source, Set<String> cacheIds) {
    final settings = _rankingSettings[source];
    return RefreshDataRequest(
      dataSource: source,
      qq: source == RefreshDataSource.awmc ? widget.awmcQQ.trim() : _bindQQ,
      authCode: '',
      participateRankings: settings?.participate ?? false,
      showNickname: settings?.nickname ?? false,
      showBriefProfile: settings?.brief ?? false,
      forceFullRefresh: false,
      forceSourceIds: cacheIds,
      useSavedAuthorization:
          source == RefreshDataSource.luoxue && _hasSavedLuoXueToken,
    );
  }

  Future<void> _onConfirm() async {
    final route = ModalRoute.of(context);
    if (_confirming || route == null || !route.isCurrent) return;
    setState(() => _confirming = true);
    try {
      final request = await collectRequest();
      if (request != null && mounted && route.isCurrent) {
        route.navigator!.pop(request);
      }
    } catch (error) {
      debugPrint('读取刷新设置失败: $error');
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        AppToast.show(context.l10n.flowCouldNotRefreshData,
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted && route.isActive) setState(() => _confirming = false);
    }
  }

  // ====================================================================
  // UI 构建
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildPanelContent(context);
    }
    return AppAlertDialog(
      title: Text(context.l10n.featureRefreshCachedData),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: _buildPanelContent(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final route = ModalRoute.of(context);
            if (route != null && route.isCurrent) route.navigator!.pop();
          },
          child: Text(context.l10n.featureCancel),
        ),
        TextButton(
          onPressed: _confirming ? null : _onConfirm,
          child: Text(_confirming
              ? context.l10n.flowLoading2
              : context.l10n.flowConfirm),
        ),
      ],
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    final syncSources = widget.syncSources;
    if (syncSources != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCacheSourceSection(),
          AppDialogAnimatedHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final source in RefreshDataSource.values)
                  if (syncSources.contains(source))
                    Column(
                      key: ValueKey(source),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        Text(source.displayName,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        _buildAccountOptions(source),
                        _buildRankingOptions(source),
                      ],
                    ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) _buildDataSourceRow(),
        if (!widget.embedded) const SizedBox(height: 12),
        ClipRect(
          child: AnimatedSize(
            duration:
                AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
            curve: AppDesignTokens.emphasizedCurve,
            alignment: Alignment.topCenter,
            child: FadeSwitcher(
              value: _currentDataSource,
              sizeFollowsCurrent: true,
              alignment: AlignmentDirectional.topStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAccountOptions(_currentDataSource),
                  const SizedBox(height: 16),
                  _buildRankingOptions(_currentDataSource),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildCacheSourceSection(),
      ],
    );
  }

  Widget _buildDataSourceRow() {
    // 三个选项在窄屏一行放不下（还有「当前数据源：」标题），
    // 所以标题单独一行，避免 RenderFlex overflow。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.flowCurrentDataSource),
        const SizedBox(height: 6),
        AnimatedChoiceBar<RefreshDataSource>(
          values: RefreshDataSource.values,
          value: _currentDataSource,
          label: (source) => context.featureText(source.shortDisplayName),
          onChanged: _confirming
              ? null
              : (source) {
                  // 这里只选本次请求的数据源，提交后才切换活动账号。
                  setState(() {
                    _currentDataSource = source;
                    _rankingSettings.remove(source);
                    _rankingSettingsReady = _loadRankingSettings([source]);
                  });
                },
        ),
      ],
    );
  }

  /// AWMC NET（net.wmc.pub）面板：只显示独立绑定入口保存的 QQ。
  Widget _buildAwmcPanel() => Text(widget.awmcQQ.isEmpty
      ? context.l10n.accountLinkAWMCFirst
      : '${context.l10n.flowQQID}：${widget.awmcQQ}');

  /// 水鱼面板：整个委托给共享的 [DivingFishAccountSection]（同 RefreshDataDialog）。
  Widget _buildShuiyuPanel() {
    return DivingFishAccountSection(
      state: resolveDivingFishQqState(
        loggedIn: widget.hasDivingFishLogin,
        bindQq: _bindQQ,
      ),
      qq: _bindQQ,
      authorized: _isAuthorized,
      checkingAuth: _isCheckingAuth,
      consentPending: _consentPending,
      recheckingAuth: _recheckingAuth,
      reloadingQq: _reloadingQq,
      onStartAuthorization: _startAuthorization,
      onRecheckAuthorization: _recheckAuthorization,
      onReloadQq: _reloadBindQq,
    );
  }

  Widget _buildLuoXuePanel() => Text(_hasSavedLuoXueToken
      ? context.l10n.flowLXNSAuthorizationSavedItRenewsAutomaticallyNo
      : context.l10n.accountAuthorizeLXNSFirst);

  Widget _buildAccountOptions(RefreshDataSource source) => switch (source) {
        RefreshDataSource.shuiyu => _buildShuiyuPanel(),
        RefreshDataSource.luoxue => _buildLuoXuePanel(),
        RefreshDataSource.awmc => _buildAwmcPanel(),
      };

  Widget _buildRankingOptions(RefreshDataSource source) {
    final settings = _rankingSettings[source];
    return RankingPrivacyOptions(
      key: ValueKey(source),
      participate: settings?.participate ?? false,
      showNickname: settings?.nickname ?? false,
      showBriefProfile: settings?.brief ?? false,
      divingFishSource: source == RefreshDataSource.shuiyu,
      dataSourceKey: source.key,
      onChanged: (participate, nickname, brief) {
        if (widget.syncSources == null && source != _currentDataSource) return;
        setState(() {
          _rankingSettings[source] = (
            participate: participate,
            nickname: nickname,
            brief: brief,
          );
        });
      },
    );
  }

  /// 「强制刷新」开关 + 展开后的缓存源选择列表（默认收起）。
  Widget _buildCacheSourceSection() {
    final brightness = Theme.of(context).brightness;
    final mutedColor = AppColors.greyHint(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(context.l10n.flowForceFullRefreshIgnoreStaticCaches),
          value: _forceRefresh,
          onChanged: (value) {
            setState(() {
              _forceRefresh = value ?? false;
              // 每次勾选都从全选开始，用户再按需取消。
              if (_forceRefresh) {
                _checkedIds
                  ..clear()
                  ..addAll(CacheSourceRegistry.all.map((s) => s.id));
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        AnimatedReveal(
          visible: _forceRefresh,
          child: _buildCacheSourceList(mutedColor),
        ),
      ],
    );
  }

  Widget _buildCacheSourceList(Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(context.l10n.flowForceRefreshCachedData,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_checkedIds.length == CacheSourceRegistry.all.length) {
                    _checkedIds.clear();
                  } else {
                    _checkedIds
                      ..clear()
                      ..addAll(CacheSourceRegistry.all.map((s) => s.id));
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _checkedIds.length == CacheSourceRegistry.all.length
                    ? context.l10n.flowDeselectAll
                    : context.l10n.flowSelectAll,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.flowSelectedCachesAreIgnoredAndFetchedFrom,
          style: TextStyle(fontSize: 11, color: mutedColor),
        ),
        const SizedBox(height: 8),
        // 分隔小标题：曲目 / 标签 / 别名 / 收藏品 / 元数据 / maidata
        ..._groupedSources().entries.map(
              (entry) => _buildGroup(entry.key, entry.value),
            ),
      ],
    );
  }

  /// 按语义分组（用于在对话框里加小标题），但实际 force-refresh 按 groupKey。
  Map<String, List<CacheSourceInfo>> _groupedSources() {
    return {
      '歌曲与谱面': CacheSourceRegistry.all
          .where((s) => s.groupKey == 'songs' || s.groupKey == 'diff')
          .toList(),
      '标签与别名': CacheSourceRegistry.all
          .where((s) => s.groupKey == 'tags' || s.groupKey == 'aliases')
          .toList(),
      '收藏品': CacheSourceRegistry.all
          .where((s) => s.groupKey == 'collections')
          .toList(),
      '元数据与辅助': CacheSourceRegistry.all
          .where((s) => s.groupKey == 'union' || s.groupKey == 'maidata')
          .toList(),
    };
  }

  Widget _buildGroup(String title, List<CacheSourceInfo> sources) {
    final brightness = Theme.of(context).brightness;
    final mutedColor = AppColors.greyHint(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(context.featureText(title),
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
                fontWeight: FontWeight.w600,
              )),
        ),
        ...sources.map((s) => _buildSourceRow(s)),
      ],
    );
  }

  Widget _buildSourceRow(CacheSourceInfo source) {
    final brightness = Theme.of(context).brightness;
    final mutedColor = AppColors.greyHint(brightness);
    final result = _testResults[source.id];
    final isTesting = _testingId == source.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 复选框
          Checkbox(
            value: _checkedIds.contains(source.id),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _checkedIds.add(source.id);
                } else {
                  _checkedIds.remove(source.id);
                }
              });
            },
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          // 名称 + 描述 + 有效期（独立一行）+ 测试按钮
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.featureText(source.displayName),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _validities[source.id] ?? context.l10n.flowLoading2,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: (_validities[source.id] ?? '')
                            .startsWith(context.l10n.flowCacheExpiredPrefix)
                        ? Colors.orange
                        : mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${context.featureText(source.description)}${result != null ? " · ${_formatTestResult(result)}" : ""}',
                  style: TextStyle(fontSize: 11, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 测试按钮
          _buildTestButton(source.id, result, isTesting),
        ],
      ),
    );
  }

  String _formatTestResult(_TestResult r) {
    if (r.success) {
      return '✓ ${r.statusCode} ${r.latencyMs}ms';
    }
    return '✗ ${r.error ?? context.l10n.flowFailed} (${r.latencyMs}ms)';
  }

  Widget _buildTestButton(
      String sourceId, _TestResult? result, bool isTesting) {
    if (isTesting) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (result != null && result.success) {
      // 成功：✓ 在上，延迟在下（点击重测）
      return InkWell(
        onTap: () => _testSource(sourceId),
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: context.l10n.flowConnectedP0P1Ms(
              (result.statusCode).toString(), (result.latencyMs).toString()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(height: 2),
                Text(
                  '${result.latencyMs}ms',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (result != null) {
      // 失败：保留错误图标（点击重测），延迟 tooltip 中可见
      return IconButton(
        tooltip: context.l10n.flowFailedP0P1Ms(
            (result.error ?? context.l10n.featureUnknownError).toString(),
            (result.latencyMs).toString()),
        icon: const Icon(Icons.error, color: Colors.red, size: 20),
        onPressed: () => _testSource(sourceId),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      );
    }
    return TextButton(
      onPressed: () => _testSource(sourceId),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(context.l10n.flowTest, style: TextStyle(fontSize: 12)),
    );
  }
}
