import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../../service/CommunityAvatarStore.dart';
import '../../widgets/RankingPlayerBriefSheet.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../service/RankingList/FittedRatingRankingListService.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AppHeader.dart';
import '../../widgets/ThemeAwareBackground.dart';
import '../../widgets/CommunityAvatar.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/RankingRowExtent.dart';
import '../../widgets/RankingUi.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/AppToast.dart';

class FittedRatingRankingListPage extends StatefulWidget {
  final FittedMode initialMode;

  const FittedRatingRankingListPage(
      {super.key, this.initialMode = FittedMode.a});

  @override
  State<FittedRatingRankingListPage> createState() =>
      _FittedRatingRankingListPageState();
}

class _FittedRatingRankingListPageState
    extends State<FittedRatingRankingListPage> {
  int _requestGeneration = 0;
  // 排行榜（按当前指标排序后取前100）
  List<FittedRankItem> _rankList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // 当前选择的模式
  late FittedMode _currentMode;

  // 当前用户信息
  String? _currentUserId;
  FittedRankItem? _currentUserRankItem;

  // 防抖相关变量
  bool _isButtonDisabled = false;

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 行高实测器（定位按钮要精确落位）：列表用 `prototypeItem` 把每行都排成它的高度。
  final RankingRowExtent _rowExtent = RankingRowExtent();
  final RankingEntrance _entrance = RankingEntrance();

  @override
  void initState() {
    super.initState();
    CommunityAvatarStore.profileChanges.addListener(_onAppearanceChanged);
    _currentMode = widget.initialMode;
    _loadData();
  }

  void _onAppearanceChanged() {
    if (mounted) _loadRankings(refresh: true);
  }

  @override
  void dispose() {
    CommunityAvatarStore.profileChanges.removeListener(_onAppearanceChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadCurrentUserInfo();
    await _loadRankings();
  }

  /// 取当前玩家的排行榜 id（`'<source>:<id>'`）。
  ///
  /// 优先当前活动数据源，拿不到再按 enum 顺序找任一有标记的源；全都没有才退化到
  /// `cachedQQ`（历史上只有水鱼写它）。原来的二元写法只认 水鱼 / 落雪。
  Future<void> _loadCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final current = CurrentDataSourceNotifier.instance.value;
    final ordered = <RefreshDataSource>[
      current,
      ...RefreshDataSource.values.where((s) => s != current),
    ];
    for (final source in ordered) {
      final marker = prefs.getString(source.userIdCacheKey);
      if (marker != null && marker.isNotEmpty) {
        _currentUserId = marker;
        return;
      }
    }
    final qq = prefs.getString(CacheKeyConstant.cachedQQ);
    _currentUserId = (qq != null && qq.isNotEmpty) ? 'shuiyu:$qq' : null;
  }

  // 禁用按钮并在1秒后恢复
  void _disableButtons() {
    setState(() {
      _isButtonDisabled = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isButtonDisabled = false;
      });
    });
  }

  // 带防抖的刷新方法
  Future<void> _onRefresh() async {
    _disableButtons();
    await _loadRankings(refresh: true);
  }

  // 滚动到当前用户位置
  void _scrollToCurrentUser() {
    if (_currentUserRankItem == null) {
      return;
    }
    if (_currentUserRankItem!.rank > 100) {
      AppToast.show(context.l10n.flowYouAreOutsideTheTop100);
      return;
    }
    final userIndex =
        _rankList.indexWhere((item) => item.playerId == _currentUserId);
    if (userIndex != -1) {
      // 精确落位：行高由 [RankingRowExtent] 实测，不再写 `index * 84` 那种估算
      // （真实行高只有 67，估高每行多 17dp，到第 40 名就滑过头 680dp）。
      _rowExtent.scrollRowToTop(_scrollController, userIndex);
    } else {
      AppToast.show(context.l10n.flowYouAreOutsideTheTop100);
    }
  }

  // 切换模式并刷新
  void _onModeChanged(FittedMode mode) {
    if (mode == _currentMode) return;
    setState(() {
      _currentMode = mode;
      _isLoading = true;
      _errorMessage = '';
    });
    _loadRankings();
  }

  Future<void> _loadRankings({bool refresh = false}) async {
    if (!mounted) return;
    final generation = ++_requestGeneration;
    final mode = _currentMode;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await FittedRatingRankingListService.getRankings(
        mode: mode,
        refresh: refresh,
      );

      if (!mounted || generation != _requestGeneration) return;
      final ranked =
          FittedRatingRankingListService.calculateRankedPositions(items);
      final top = ranked.take(100).toList();

      FittedRankItem? userItem;
      if (_currentUserId != null) {
        for (final item in top) {
          if (item.playerId == _currentUserId) {
            userItem = item;
            break;
          }
        }
        userItem ??= await FittedRatingRankingListService.getCurrentUserRank(
          mode: mode,
          userId: _currentUserId!,
        );
      }

      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _rankList = top;
        _currentUserRankItem = userItem;
      });
    } catch (e) {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _errorMessage = appL10n.flowCouldNotLoadP0((e).toString());
        });
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _modeName(FittedMode mode) => switch (mode) {
        FittedMode.a => context.l10n.flowModeATop50ByFittedRating,
        FittedMode.b =>
          context.l10n.flowModeBRecalculateOfficialBest35Best15Using,
        FittedMode.c => context.l10n.flowModeCTop35OlderChartsAnd,
      };

  Widget _buildValueCell(FittedRankItem item) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${item.fittedRating}',
            maxLines: 1,
            style: AppTheme.number(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              context.l10n.flowDifferenceFromBest50P0P1(
                  (item.diff >= 0 ? '+' : '').toString(),
                  (item.diff).toString()),
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.diff >= 0
                    ? AppColors.successGreen(brightness)
                    : AppColors.errorRed(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(FittedRankItem item, {bool isCurrentUser = false}) {
    return CommunityPlayerIdentity(
      avatarId: item.avatarId,
      dataSource: item.dataSource,
      // 开发者白名单按 `<source>:<id>` 整串匹配，见 DataSourceTag
      playerId: item.playerId,
      name: item.playerName.isEmpty
          ? context.l10n.flowUnknownPlayer
          : item.playerName,
      // 头像高度对齐「玩家名 + 数据源标签」两行文字的总高
      avatarMatchesTextHeight: true,
      nameStyle: TextStyle(
        fontSize: 14,
        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildRankItem(
    FittedRankItem item, {
    bool isCurrentUser = false,
    required Brightness brightness,
  }) {
    return RankingPlayerRow(
      playerId: item.playerId,
      nickname: item.playerName,
      child: RankingRow(
        rank: item.rank,
        highlighted: isCurrentUser,
        identity: _buildIdentity(item, isCurrentUser: isCurrentUser),
        value: _buildValueCell(item),
      ),
    );
  }

  /// 定位用的「原型行」：内容最全的一行（第 1 名那 28dp 奖杯 + 拟合值 + 差值小字）。
  /// 列表会先把它排一遍，再让每一行都用它的高度 —— 于是「第 index 行」的偏移
  /// 就是 `index × 行高`，见 [RankingRowExtent]。
  Widget _buildRowPrototype(Brightness brightness) => KeyedSubtree(
        key: _rowExtent.key,
        child: _buildRankItem(_prototypeRankItem, brightness: brightness),
      );

  FittedRankItem get _prototypeRankItem => FittedRankItem(
        rank: 1,
        playerId: '',
        playerName: '',
        dataSource: RefreshDataSource.shuiyu.key,
        mode: _currentMode.name,
        fittedRating: 17000,
        officialRating: 16800,
        diff: 200,
      );

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph,
              size: 64, color: AppColors.greyHint(brightness)),
          const SizedBox(height: 16),
          Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : context.l10n.flowNoRankingDataYet,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyHint(brightness),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: AnimatedChoiceBar<FittedMode>(
            values: FittedMode.values,
            value: _currentMode,
            label: (mode) => context.l10n.flowModeP02((mode.label).toString()),
            onChanged: _onModeChanged),
      );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface),
          ),
          const ThemeAwareBackground(),
          Column(
            children: [
              // 顶部栏统一走公共组件（标题 = 思源黑体 20 / bold / primary / 居中）。
              // 以前是 `Scaffold.appBar: AppBar` + 裸 `Text`，标题会被 AppBar
              // 重新套上的 DefaultTextStyle 顶成系统 Roboto。
              AppHeader(
                title: context.l10n.featureTotalFittedRatingLeaderboard,
                actions: [
                  IconButton(
                    icon: _isLoading
                        ? CircularProgressIndicator(
                            color: AppColors.primaryText(brightness),
                            strokeWidth: 2)
                        : Icon(Icons.refresh,
                            color: AppColors.primaryText(brightness)),
                    onPressed:
                        (_isLoading || _isButtonDisabled) ? null : _onRefresh,
                    tooltip: context.l10n.flowRefresh,
                  ),
                  if (_currentUserRankItem != null)
                    IconButton(
                      icon: Icon(Icons.location_searching,
                          color: AppColors.primaryText(brightness)),
                      onPressed: _scrollToCurrentUser,
                      tooltip: context.l10n.flowGoToMyRank,
                    ),
                ],
              ),
              // 模式切换
              _buildModeSwitcher(),

              // 当前模式说明
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _modeName(_currentMode),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyHint(brightness),
                    ),
                  ),
                ),
              ),

              // 免责声明
              const RankingNotice(),

              // 排行榜列表
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryText(brightness)))
                    : _rankList.isEmpty
                        ? _buildEmptyState(brightness)
                        : ListView.builder(
                            controller: _scrollController,
                            // 必须显式清零：`Scaffold` 在没有 `appBar:` 时不会消耗顶部安全区，
                            // `ListView` 会把 `MediaQuery.padding.top`（状态栏 24dp）当成
                            // 内边距垫在列表最上面，而状态栏已被 `AppHeader` 占掉 ——
                            // 结果就是「第一名那行上方多出一块空白」（实测 24dp）。
                            padding: EdgeInsets.only(
                                bottom: _currentUserRankItem == null
                                    ? MediaQuery.paddingOf(context).bottom
                                    : 0),
                            // 每行都排成原型行的高度：定位按钮才能用
                            // `index × 行高` 精确落位（行高不再靠 84 这种估算）
                            prototypeItem: _buildRowPrototype(brightness),
                            itemCount: _rankList.length,
                            itemBuilder: (context, index) {
                              final item = _rankList[index];
                              final isCurrentUser = _currentUserId != null &&
                                  item.playerId == _currentUserId;
                              return _entrance.wrap(
                                  _rankList,
                                  index,
                                  _buildRankItem(
                                    item,
                                    isCurrentUser: isCurrentUser,
                                    brightness: brightness,
                                  ));
                            },
                          ),
              ),

              // 底部固定显示当前用户
              if (!_isLoading && _currentUserRankItem != null)
                SafeArea(
                  top: false,
                  child: RankingSelfBar(
                    rank: _currentUserRankItem!.rank,
                    onTap: _scrollToCurrentUser,
                    identity: _buildIdentity(_currentUserRankItem!,
                        isCurrentUser: true),
                    value: _buildValueCell(_currentUserRankItem!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
