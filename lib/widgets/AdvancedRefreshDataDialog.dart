import '../service/AccountAuthorizationStore.dart';
import '../l10n/AppMessages.dart';
import '../l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'RankingPrivacyOptions.dart';
import '../widgets/AnimatedChoiceBar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../manager/DivingFishProbeManager.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../service/ConnectivityService.dart';
import '../service/AccountStore.dart';
import '../utils/AppTheme.dart';
import '../utils/ApiClient.dart';
import '../utils/CacheSourceRegistry.dart';
import '../utils/SecureCredentialStore.dart';
import 'RefreshDataDialog.dart'
    show CurrentDataSourceNotifier, RefreshDataRequest, RefreshDataSource;
import 'DivingFishAccountSection.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 高级模式"拉取成绩并更新数据"对话框的入口。
///
/// 与旧版 `_RefreshDataDialog` 的差别：
///   - 同样的"当前数据源 / 已保存的账号授权 / 排行榜选项"区
///   - 用一组复选框替换"强制完整刷新"，每条对应一个缓存源（来自 [CacheSourceRegistry]）
///   - 每条旁边显示剩余有效期 + 一个测试连通性的按钮
///
/// 返回 [RefreshDataRequest]，其 [RefreshDataRequest.forceSourceIds] 非空（高级模式标识）。
Future<RefreshDataRequest?> showAdvancedRefreshDataDialog(
  BuildContext context, {
  RefreshDataSource? initialSource,
}) async {
  await CurrentDataSourceNotifier.load();
  final prefs = await SharedPreferences.getInstance();
  final jwt =
      await SecureCredentialStore.read(CacheKeyConstant.probeDivingFishToken) ??
          '';
  final bindQQ = prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '';

  // AWMC NET 的 QQ 取自它自己的账号存档，不用共用的 cachedQQ
  // （活动槽里的 cachedQQ 此刻可能是另一个账号的 QQ）。
  final awmcQQ = await AccountAuthorizationStore.awmcQQ();

  if (!context.mounted) return null;

  return showDialog<RefreshDataRequest>(
    context: context,
    builder: (_) => AdvancedRefreshDataPanel(
      // 只传「有没有登录」：登录了但没填 QQ 要单独提示，见 DivingFishQqState
      hasDivingFishLogin: jwt.isNotEmpty,
      bindQQ: bindQQ,
      awmcQQ: awmcQQ,
      initialSource: initialSource,
    ),
  );
}

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

  const AdvancedRefreshDataPanel({
    super.key,
    required this.hasDivingFishLogin,
    required this.bindQQ,
    required this.awmcQQ,
    this.initialSource,
    this.embedded = false,
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

  bool _participateRankings = false;
  bool _showNickname = false;
  bool _showBriefProfile = false;
  bool _hasSavedLuoXueToken = false;
  late final Future<void> _settingsReady;

  /// 用户勾选要强制刷新的缓存源 ID 集合。默认空集（全不勾选）；在 initState
  /// 里异步加载上次保存的勾选，被持久化到 SharedPreferences（key 见
  /// CacheKeyConstant.advancedRefreshForceSources）。
  late Set<String> _checkedIds;

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
    _checkedIds = <String>{}; // 同步初始化，避免 late 在 build 之前未赋值
    _settingsReady = Future.wait([
      _loadRankingSettings(),
      _loadCheckedIds(),
      _loadLuoXueToken(),
    ]);
    _loadAllValidities();
    if (_bindQQ.isNotEmpty) {
      _checkAuthorization();
    }
  }

  Future<void> _loadLuoXueToken() async {
    final loggedIn = await LuoXueOAuthManager().isLoggedIn();
    if (mounted) setState(() => _hasSavedLuoXueToken = loggedIn);
  }

  /// 本次选中的数据源要用的 QQ（水鱼取水鱼绑定 QQ，AWMC NET 取独立保存的查询 QQ）。
  String get _activeQq => _currentDataSource == RefreshDataSource.awmc
      ? widget.awmcQQ.trim()
      : _bindQQ;

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

  Future<void> _loadRankingSettings() async {
    final source = _currentDataSource;
    final settings = await AccountStore.settingsFor(source);
    if (!mounted || source != _currentDataSource) return;
    setState(() {
      _participateRankings =
          settings[CacheKeyConstant.participateRankings] == true;
      _showNickname = settings[CacheKeyConstant.showNickname] == true;
      _showBriefProfile = settings[CacheKeyConstant.showBriefProfile] == true;
    });
  }

  /// 加载上次保存的勾选集合；为空则保持空集（全不勾选）。
  Future<void> _loadCheckedIds() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved =
        prefs.getStringList(CacheKeyConstant.advancedRefreshForceSources);
    if (saved == null) return; // 首次使用，保持空集
    setState(() {
      _checkedIds = saved.toSet();
    });
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
    await _settingsReady;
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
      // 离线检查
      final isOnline = await ConnectivityService().hasConnection();
      if (!isOnline) {
        if (mounted) {
          AppToast.show(
              context.l10n.flowCannotRefreshWithoutAConnectionConnectAnd,
              duration: Duration(seconds: 3),
              tone: AppToastTone.error);
        }
        return null;
      }
      if (!mounted) return null;
    }

    // 持久化本次勾选，下次打开对话框时自动恢复
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      CacheKeyConstant.advancedRefreshForceSources,
      _checkedIds.toList(),
    );

    final request = RefreshDataRequest(
      dataSource: _currentDataSource,
      qq: _activeQq,
      authCode: '',
      participateRankings: _participateRankings,
      showNickname: _showNickname,
      showBriefProfile: _showBriefProfile,
      forceFullRefresh: false, // 高级模式不依赖此字段
      forceSourceIds: Set<String>.from(_checkedIds),
      useSavedAuthorization: _currentDataSource == RefreshDataSource.luoxue &&
          _hasSavedLuoXueToken,
    );
    return request;
  }

  Future<void> _onConfirm() async {
    final request = await collectRequest();
    if (request != null && mounted) Navigator.of(context).pop(request);
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
      title: Text(context.l10n.featureAdvancedRefresh),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: _buildPanelContent(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: Text(context.l10n.flowConfirm),
        ),
      ],
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) _buildDataSourceRow(),
        if (!widget.embedded) const SizedBox(height: 12),
        if (_currentDataSource == RefreshDataSource.shuiyu)
          _buildShuiyuPanel(brightness),
        if (_currentDataSource == RefreshDataSource.luoxue)
          _buildLuoXuePanel(brightness),
        if (_currentDataSource == RefreshDataSource.awmc)
          _buildAwmcPanel(brightness),
        _buildRankingOptions(brightness),
        const SizedBox(height: 16),
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
          onChanged: (source) {
            // 只选「本次要刷新的数据源」；真正的切换由 executeAdvancedRefreshData
            // 里的 prepareForRefresh 完成，避免活动槽与数据源不一致。
            setState(() {
              _currentDataSource = source;
            });
            _loadRankingSettings();
          },
        ),
      ],
    );
  }

  /// AWMC NET（net.wmc.pub）面板：只显示独立绑定入口保存的 QQ。
  Widget _buildAwmcPanel(Brightness brightness) => Text(widget.awmcQQ.isEmpty
      ? context.l10n.accountLinkAWMCFirst
      : '${context.l10n.flowQQID}：${widget.awmcQQ}');

  /// 水鱼面板：整个委托给共享的 [DivingFishAccountSection]（同 RefreshDataDialog）。
  Widget _buildShuiyuPanel(Brightness brightness) {
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

  Widget _buildLuoXuePanel(Brightness brightness) => Text(_hasSavedLuoXueToken
      ? context.l10n.flowLXNSAuthorizationSavedItRenewsAutomaticallyNo
      : context.l10n.accountAuthorizeLXNSFirst);

  Widget _buildRankingOptions(Brightness brightness) {
    return Column(
      children: [
        const SizedBox(height: 16),
        RankingPrivacyOptions(
            participate: _participateRankings,
            showNickname: _showNickname,
            showBriefProfile: _showBriefProfile,
            onChanged: (participate, nickname, brief) => setState(() {
                  _participateRankings = participate;
                  _showNickname = nickname;
                  _showBriefProfile = brief;
                })),
      ],
    );
  }

  /// 新增：13 行"强制刷新缓存数据"列表。
  Widget _buildCacheSourceSection() {
    final brightness = Theme.of(context).brightness;
    final mutedColor = AppColors.greyHint(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
