import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../../service/CommunityAvatarStore.dart';
import '../../widgets/RankingPlayerBriefSheet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/AccountStore.dart';
import '../../service/RankingList/RatingRankListService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ColorUtil.dart';
import '../../widgets/AppHeader.dart';
import '../../widgets/ThemeAwareBackground.dart';
import '../../widgets/CommunityAvatar.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/RankingRowExtent.dart';
import '../../widgets/RankingUi.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppToast.dart';

class RatingRankListPage extends StatefulWidget {
  const RatingRankListPage({super.key});

  @override
  State<RatingRankListPage> createState() => _RatingRankListPageState();
}

class _RatingRankListPageState extends State<RatingRankListPage> {
  int _requestGeneration = 0;
  List<RankItem> _rankList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // 当前选择的排行榜类型
  int _selectedTab = 0; // 0: 总排行榜, 之后依次是 _tabSources 里的数据源
  int? _resultTab; // 屏幕上这份榜单所属的 Tab
  String? _resultUserId; // 这份榜单里要高亮的玩家

  /// Tab 1..N 依次对应的数据源。
  ///
  /// 抽成列表是为了**加源时不用改逻辑**：`_tabNames` 与它一一对应，
  /// `_loadRankings` 按下标取源，不再写死 1→水鱼 / 2→落雪 的 switch。
  static const List<RefreshDataSource> _tabSources = [
    RefreshDataSource.shuiyu,
    RefreshDataSource.luoxue,
    RefreshDataSource.awmc,
  ];

  /// Tab 标题。第 0 个是跨源总榜，其余按 [_tabSources] 的**短名**生成。
  ///
  /// 不写字面量列表：否则「Tab 上写 AWMC、标签里写 AWMC NET」这种两处名字
  /// 不一致的坑早晚会出现，加源时也要记得回来补一个字符串。
  late final List<String> _tabNames = [
    '总排行榜',
    for (final source in _tabSources) source.shortDisplayName,
  ];

  // 当前用户信息
  String? _currentUserId;
  String? _currentDataSource;
  final Map<String, String> _userIdsBySource = <String, String>{};
  RankItem? _currentUserRankItem;

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
    _loadData();
  }

  void _onAppearanceChanged() {
    if (mounted) _loadRankings();
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

  /// 推断当前玩家（数据源 + 排行榜 id）。
  ///
  /// 按源区分的标记键（`shuiyu_user_id` / `luoxue_user_id` / `awmc_user_id`）由各源的
  /// 刷新流程写入，比共用的 `cachedQQ` 权威。优先当前活动数据源，拿不到再按 enum
  /// 顺序兜底，全都没有才退化到 `cachedQQ`（历史上只有水鱼写它）。
  ///
  /// 原来的二元写法只认 水鱼 / 落雪，且 `lastDataSource == 'awmc'` 时会把数据源
  /// 标成水鱼、id 却取水鱼的 QQ —— 拿 AWMC 账号看排行榜会高亮错人。
  Future<void> _loadCurrentUserInfo() async {
    await CurrentDataSourceNotifier.load();
    final prefs = await SharedPreferences.getInstance();
    final accounts = await AccountStore.loadAll();
    final current = CurrentDataSourceNotifier.instance.value;
    final ordered = <RefreshDataSource>[
      current,
      ...RefreshDataSource.values.where((s) => s != current),
    ];

    _currentDataSource = null;
    _currentUserId = null;
    _userIdsBySource.clear();
    for (final source in ordered) {
      final marker = prefs.getString(source.userIdCacheKey);
      final validMarker = marker?.startsWith('${source.key}:') == true &&
              RefreshDataSource.parseUserIdMarker(marker) != null
          ? marker
          : null;
      final archivedId = accounts[source.key]?.id.trim();
      final archivedMarker = archivedId == null || archivedId.isEmpty
          ? null
          : '${source.key}:$archivedId';
      // 非活动源的标记会在切账号时清空，需要从账号存档恢复身份。
      final userId = source == current
          ? validMarker ?? archivedMarker
          : archivedMarker ?? validMarker;
      if (userId != null) {
        _userIdsBySource[source.key] = userId;
        _currentDataSource ??= source.key;
        _currentUserId ??= userId;
      }
    }

    // 共用 cachedQQ 只属于当前活动源，不能把落雪/AWMC 的 ID 当作水鱼 QQ。
    final qq = prefs.getString('cachedQQ');
    if (current == RefreshDataSource.shuiyu &&
        !_userIdsBySource.containsKey(current.key) &&
        qq != null &&
        qq.isNotEmpty) {
      final userId = '${current.key}:$qq';
      _userIdsBySource[current.key] = userId;
      _currentDataSource = current.key;
      _currentUserId = userId;
    }
  }

  // 禁用按钮并在1秒后恢复
  void _disableButtons() {
    setState(() {
      _isButtonDisabled = true;
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _isButtonDisabled = false;
      });
    });
  }

  // 带防抖的刷新方法
  Future<void> _onRefresh() async {
    _disableButtons();
    // 清除缓存以便重新获取最新数据
    await RatingRankListService.clearRankingsCache();
    await _loadCurrentUserInfo();
    await _loadRankings();
  }

  // 滚动到当前用户位置
  void _scrollToCurrentUser() {
    if (_currentUserRankItem == null) {
      return;
    }

    // 查找当前用户在列表中的索引
    final userIndex = _rankList
        .indexWhere((item) => item.userId == _currentUserRankItem!.userId);
    if (userIndex != -1) {
      // 精确落位：行高由 [RankingRowExtent] 实测，不再写 `index * 72` 那种估算
      // （估高每行多 7dp，到第 40 名就滑过头 280dp，自己的行跑到屏幕上方）。
      _rowExtent.scrollRowToTop(_scrollController, userIndex);
    } else {
      _showOutsideTop100Message();
    }
  }

  void _showOutsideTop100Message() {
    AppToast.show(context.l10n.flowYouAreOutsideTheTop100);
  }

  RefreshDataSource? get _selectedSource =>
      _selectedTab == 0 ? null : _tabSources[_selectedTab - 1];

  String? get _selectedUserId {
    final source = _selectedSource;
    if (source != null) return _userIdsBySource[source.key];
    return _userIdsBySource[_currentDataSource] ?? _currentUserId;
  }

  Future<RankItem?> _findCurrentUserRankItem(
    List<RankItem> items, {
    required String? userId,
    required RefreshDataSource? source,
  }) async {
    if (userId == null || userId.isEmpty) return null;

    RankItem? inTop100;
    for (final item in items) {
      if (item.userId == userId) {
        inTop100 = item;
        break;
      }
    }
    if (inTop100 != null) return inTop100;

    // 榜单接口只返回前 100 名；再查详情与名次，才能显示 100 名外用户的真实数据。
    final detail = await RatingRankListService.getUserDetail(userId);
    if (detail == null ||
        detail.userId != userId ||
        (source != null && detail.dataSource != source.key)) return null;
    final rank = await RatingRankListService.getUserRank(
      userId,
      source: source,
    );
    if (rank == null) return null;
    detail.rank = rank;
    return detail;
  }

  Future<void> _loadRankings() async {
    if (!mounted) return;
    final generation = ++_requestGeneration;
    final tab = _selectedTab;
    final source = _selectedSource;
    final userId = _selectedUserId;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<RankItem> items;
      if (source == null) {
        // 第 0 个 Tab 是跨源总榜
        items = await RatingRankListService.getTotalRankings(limit: 500);
      } else {
        // 其余 Tab 按 _tabSources 取对应数据源的榜（水鱼 / 落雪 / AWMC NET）
        items =
            await RatingRankListService.getSourceRankings(source, limit: 500);
      }

      if (!mounted || generation != _requestGeneration) return;
      // 计算并列排名
      items = RatingRankListService.calculateRankedPositions(items);

      final currentUserRankItem = await _findCurrentUserRankItem(
        items,
        userId: userId,
        source: source,
      );
      if (!mounted || generation != _requestGeneration) return;

      setState(() {
        _rankList = items.take(500).toList();
        _currentUserRankItem = currentUserRankItem;
        _resultTab = tab;
        _resultUserId = userId;
      });
    } catch (e) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _errorMessage = appL10n.flowCouldNotLoadP0((e).toString());
        // 换榜失败时不能让旧榜单顶着新 Tab 显示。
        if (_resultTab != tab) {
          _rankList = [];
          _currentUserRankItem = null;
        }
      });
    } finally {
      if (mounted && generation == _requestGeneration)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Widget _buildIdentity(RankItem item, {bool isCurrentUser = false}) {
    return CommunityPlayerIdentity(
      avatarId: item.avatarId,
      dataSource: item.dataSource,
      // 开发者白名单按 `<source>:<id>` 整串匹配，见 DataSourceTag
      playerId: item.userId,
      name: item.nickname ?? context.l10n.flowUnknownPlayer,
      // 头像高度对齐「玩家名 + 数据源标签」两行文字的总高
      avatarMatchesTextHeight: true,
      nameStyle: TextStyle(
        fontSize: 14,
        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildValueCell(RankItem item) {
    final parts = [
      if (item.best35Rating > 0) 'B35 ${item.best35Rating}',
      if (item.best15Rating > 0) 'B15 ${item.best15Rating}',
    ];
    return SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ColorUtil.buildRatingBadge(item.totalRating, height: 24),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              parts.join(' · '),
              maxLines: 1,
              style: AppTheme.number(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(RankItem item,
      {bool isCurrentUser = false, required Brightness brightness}) {
    return RankingPlayerRow(
      playerId: item.userId,
      nickname: item.nickname,
      child: RankingRow(
        rank: item.rank,
        highlighted: isCurrentUser,
        identity: _buildIdentity(item, isCurrentUser: isCurrentUser),
        value: _buildValueCell(item),
      ),
    );
  }

  /// 定位用的「原型行」：内容最全的一行（第 1 名那 28dp 奖杯 + 总 Rating 徽章 +
  /// B35/B15 两行小字）。列表会先把它排一遍，再让每一行都用它的高度 ——
  /// 于是「第 index 行」的偏移就是 `index × 行高`，见 [RankingRowExtent]。
  Widget _buildRowPrototype(Brightness brightness) => KeyedSubtree(
        key: _rowExtent.keyFor(_rankList),
        child: _buildRankItem(_prototypeRankItem, brightness: brightness),
      );

  RankItem get _prototypeRankItem => RankItem(
        rank: 1,
        userId: '',
        dataSource: RefreshDataSource.shuiyu.key,
        originalId: '',
        totalRating: 17000,
        best35Rating: 12000,
        best15Rating: 5000,
      );

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: AppColors.greyHint(brightness),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : context.l10n.flowNoRankingDataYet,
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
              // 顶部栏统一走公共组件：标题 = 思源黑体 20 / bold / primary / 居中，
              // 与 Best50 页、其余 50 多个页面同款。
              //
              // 这里原来直接用 `Scaffold.appBar: AppBar(title: Text(...))`：标题那层
              // `Text` 不带 fontFamily，会被 AppBar 自己的 `DefaultTextStyle`
              // （`appBarTheme.titleTextStyle`）接管，标题就退化成系统 Roboto，
              // 于是出现「同一个 App 里排行榜页的标题字体和别人不一样」。
              AppHeader(
                title: context.l10n.featureRatingLeaderboard,
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
                  // 快速定位到当前用户的按钮
                  if (_currentUserRankItem != null)
                    IconButton(
                      icon: Icon(Icons.location_searching,
                          color: AppColors.primaryText(brightness)),
                      onPressed: _scrollToCurrentUser,
                      tooltip: context.l10n.flowGoToMyRank,
                    ),
                ],
              ),
              // 榜单切换
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
                child: SegmentedTabs(
                  height: 42,
                  items: [
                    for (final name in _tabNames)
                      SegmentedTabItem(context.featureText(name))
                  ],
                  selectedIndex: _selectedTab,
                  onChanged: (index) {
                    if (index == _selectedTab || _isButtonDisabled) return;
                    setState(() => _selectedTab = index);
                    _disableButtons();
                    _loadRankings();
                  },
                ),
              ),
              // 免责声明
              const RankingNotice(),

              // 排行榜列表
              Expanded(
                child: _isLoading && _rankList.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryText(brightness)))
                    : _rankList.isEmpty
                        ? _buildEmptyState(brightness)
                        : ListView.builder(
                            // 拿到新榜单时重新挂载，首屏的行才会重新进场。
                            key: ObjectKey(_rankList),
                            controller: _scrollController,
                            // 必须显式清零：`Scaffold` 在没有 `appBar:` 时不会消耗顶部安全区，
                            // 于是 `ListView` 会把 `MediaQuery.padding.top`（状态栏 24dp）
                            // 当成内边距垫在**列表最上面** —— 而状态栏已经被 `AppHeader`
                            // 占掉了，结果就是「第一名那一行上方多出一块空白」（实测 24dp）。
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
                              final isCurrentUser = _resultUserId != null &&
                                  item.userId == _resultUserId;
                              return _entrance.wrap(
                                  _rankList,
                                  index,
                                  _buildRankItem(item,
                                      isCurrentUser: isCurrentUser,
                                      brightness: brightness));
                            },
                          ),
              ),

              // 底部固定显示当前用户
              if (_currentUserRankItem != null)
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
