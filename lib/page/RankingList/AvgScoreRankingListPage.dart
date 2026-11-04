import '../../service/CommunityAvatarStore.dart';
import '../../widgets/RankingPlayerBriefSheet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../service/RankingList/AvgRankingListService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/StringUtil.dart';
import '../../widgets/AppHeader.dart';
import '../../widgets/ThemeAwareBackground.dart';
import '../../widgets/CommunityAvatar.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/RankingRowExtent.dart';
import '../../widgets/RankingUi.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/AppToast.dart';

class AvgScoreRankingListPage extends StatefulWidget {
  final AvgMetric initialMetric;

  const AvgScoreRankingListPage(
      {super.key, this.initialMetric = AvgMetric.achievement});

  @override
  State<AvgScoreRankingListPage> createState() =>
      _AvgScoreRankingListPageState();
}

class _AvgScoreRankingListPageState extends State<AvgScoreRankingListPage> {
  // 原始（未排序）全量玩家数据
  List<AvgRankItem> _allItems = [];
  // 按当前指标排序后取前100
  List<AvgRankItem> _rankList = [];
  int _requestGeneration = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  // 当前选择的指标
  late AvgMetric _currentMetric;

  // 当前用户信息
  String? _currentUserId;
  AvgRankItem? _currentUserRankItem;

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
    _currentMetric = widget.initialMetric;
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
  /// `cachedQQ`（历史上只有水鱼写它）。原来的二元写法只认 水鱼 / 落雪，
  /// 且 `lastDataSource == 'awmc'` 时会落到 `shuiyu` 分支，把水鱼的 id 当自己。
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
      AppToast.show('抱歉，您不在前100名内');
      return;
    }
    final userIndex =
        _rankList.indexWhere((item) => item.playerId == _currentUserId);
    if (userIndex != -1) {
      // 精确落位：行高由 [RankingRowExtent] 实测，不再写 `index * 72` 那种估算
      // （真实行高只有 64，估高每行多 8dp，到第 40 名就滑过头 320dp）。
      _rowExtent.scrollRowToTop(_scrollController, userIndex);
    } else {
      AppToast.show('抱歉，您不在前100名内');
    }
  }

  // 重新按当前指标排序并划分排名（从 _allItems 计算，不触发网络）
  void _applyRanking() {
    final ranked = AvgRankingListService.calculateRankedPositions(
        _allItems, _currentMetric);

    AvgRankItem? userItem;
    if (_currentUserId != null) {
      for (final item in ranked) {
        if (item.playerId == _currentUserId) {
          userItem = item;
          break;
        }
      }
    }

    setState(() {
      _rankList = ranked.take(100).toList();
      _currentUserRankItem = userItem;
    });
  }

  Future<void> _loadRankings({bool refresh = false}) async {
    if (!mounted) return;
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await AvgRankingListService.getAverages(refresh: refresh);

      if (!mounted || generation != _requestGeneration) return;
      _allItems = items;
      _applyRanking();
    } catch (e) {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _errorMessage = '加载失败: $e';
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

  // 当前指标对应的数值
  double _valueOf(AvgRankItem item) => _currentMetric == AvgMetric.achievement
      ? item.avgAchievement
      : item.avgDxAchievement;

  // 数值格式化：均为达成率，保留四位小数并带百分号
  String _formatValue(double value) => '${value.toStringAsFixed(4)}%';

  // 指标名称
  String _metricName() =>
      _currentMetric == AvgMetric.achievement ? '平均达成率排行榜' : '平均DX分数达成率排行榜';

  // 记录条目数
  int _recordCountOf(AvgRankItem item) =>
      _currentMetric == AvgMetric.achievement
          ? item.achievementCount
          : item.dxCount;

  Widget _buildValueCell(AvgRankItem item) {
    final scheme = Theme.of(context).colorScheme;
    // 仅在平均DX分数达成率榜单显示星级（scoreRate = 平均DX达成率 / 100）
    final String? stars = _currentMetric == AvgMetric.dx
        ? StringUtil.formatStars(item.avgDxAchievement / 100)
        : null;
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stars != null) ...[
                  StarBadge(stars: stars, fontSize: 11),
                  const SizedBox(width: 5),
                ],
                Text(
                  _formatValue(_valueOf(item)),
                  maxLines: 1,
                  style: AppTheme.number(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_recordCountOf(item)}条',
            maxLines: 1,
            style: AppTheme.number(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(AvgRankItem item, {bool isCurrentUser = false}) {
    return CommunityPlayerIdentity(
      avatarId: item.avatarId,
      dataSource: item.dataSource,
      // 开发者白名单按 `<source>:<id>` 整串匹配，见 DataSourceTag
      playerId: item.playerId,
      name: item.playerName.isEmpty ? '未知玩家' : item.playerName,
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
    AvgRankItem item, {
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

  /// 定位用的「原型行」：内容最全的一行（第 1 名那 28dp 奖杯 + 星级/达成率 +
  /// 「N 条」小字）。列表会先把它排一遍，再让每一行都用它的高度 —— 于是
  /// 「第 index 行」的偏移就是 `index × 行高`，见 [RankingRowExtent]。
  Widget _buildRowPrototype(Brightness brightness) => KeyedSubtree(
        key: _rowExtent.key,
        child: _buildRankItem(_prototypeRankItem, brightness: brightness),
      );

  AvgRankItem get _prototypeRankItem => AvgRankItem(
        rank: 1,
        playerId: '',
        playerName: '',
        dataSource: RefreshDataSource.shuiyu.key,
        avgAchievement: 101.5,
        avgDxAchievement: 99.5,
        achievementCount: 1100,
        dxCount: 900,
      );

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart,
              size: 64, color: AppColors.greyHint(brightness)),
          const SizedBox(height: 16),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : '暂无排行数据',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyHint(brightness),
            ),
          ),
        ],
      ),
    );
  }

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
              // 以前是 `Scaffold.appBar: AppBar`，标题被 `Text('…')` 自带的空
              // TextStyle 顶掉了全局字体族，会渲染成系统 Roboto —— 与其它页面不一致。
              AppHeader(
                title: _metricName(),
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
                    tooltip: '刷新',
                  ),
                  if (_currentUserRankItem != null)
                    IconButton(
                      icon: Icon(Icons.location_searching,
                          color: AppColors.primaryText(brightness)),
                      onPressed: _scrollToCurrentUser,
                      tooltip: '跳转到我的排名',
                    ),
                ],
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
                            // `index × 行高` 精确落位（行高不再靠 72 这种估算）
                            prototypeItem: _buildRowPrototype(brightness),
                            itemCount: _rankList.length,
                            itemBuilder: (context, index) {
                              final item = _rankList[index];
                              final isCurrentUser = _currentUserId != null &&
                                  item.playerId == _currentUserId;
                              return _entrance.wrap(_rankList, index, _buildRankItem(
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
                    identity: _buildIdentity(_currentUserRankItem!, isCurrentUser: true),
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
