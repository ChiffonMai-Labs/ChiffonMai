import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import '../l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../widgets/SongTitleDialog.dart';
import '../utils/ChartBpmInfo.dart';
import '../utils/RatingSegmentPreferences.dart';
import '../utils/SongDetailPreferences.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:my_first_flutter_app/manager/SongAliasManager.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/entity/DivingFish/DiffSong.dart';
import 'package:my_first_flutter_app/entity/LuoXue/Collection.dart';
import 'package:my_first_flutter_app/manager/LuoXue/LuoXueSongsManager.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/page/SongMaidataPage.dart';
import 'package:my_first_flutter_app/service/SongInfoService.dart';
import 'package:my_first_flutter_app/service/SongMaidataPageService.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/CommentTextValidator.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/MaidataDecodeUtil.dart';
import 'package:my_first_flutter_app/utils/ExternalLaunchUtil.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import 'Collection/CollectionInfoPage.dart';
import 'SongPvPage.dart';
import 'SongPlayPage.dart';
import 'RankingList/SongRankingPage.dart';
import 'package:my_first_flutter_app/entity/FavoriteFolder.dart';
import 'package:my_first_flutter_app/service/FavoriteFolderService.dart';
import 'package:my_first_flutter_app/service/RankingList/SongRankingService.dart';
import 'package:my_first_flutter_app/service/BiliSearchService.dart';
import 'package:my_first_flutter_app/service/BiliRedisService.dart';
import 'package:my_first_flutter_app/service/SongInfo/SongScoreShareService.dart';
import 'package:my_first_flutter_app/service/SongInfo/SongInfoExportToImgService.dart';
import 'package:my_first_flutter_app/service/ChartNoteService.dart';
import 'package:my_first_flutter_app/entity/ChartNote.dart';
import 'package:my_first_flutter_app/manager/DivingFish/UnionManager.dart';
import 'package:my_first_flutter_app/entity/DXRating/DXDataEntity.dart';
import 'package:my_first_flutter_app/manager/DXDataManager.dart';
import 'package:my_first_flutter_app/page/CalculatorPage.dart';
import 'package:my_first_flutter_app/service/AWMC/AwmcPlayCountStore.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/AppDesignTokens.dart';
import 'package:my_first_flutter_app/widgets/AppUi.dart';
import 'package:my_first_flutter_app/service/CustomTagStore.dart';
import 'package:my_first_flutter_app/widgets/CustomTagUi.dart';
import 'package:my_first_flutter_app/utils/ScoreInputValidator.dart';
import 'package:my_first_flutter_app/utils/SongFilterUtil.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import 'package:my_first_flutter_app/widgets/AppHeader.dart';
import 'package:my_first_flutter_app/widgets/NextPlayAddDialog.dart';
import 'package:my_first_flutter_app/widgets/ChartHistorySection.dart';
import 'package:my_first_flutter_app/widgets/CommunityAvatar.dart';
import '../widgets/MarqueeText.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/Best50Ui.dart';
import '../widgets/AppToast.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';

part 'song_info/SongInfoLoaders.dart';
part 'song_info/SongInfoCommunity.dart';
part 'song_info/SongInfoTables.dart';
part 'song_info/SongInfoActions.dart';
part 'song_info/SongInfoWidgets.dart';
part 'song_info/SongInfoLayout.dart';

// ===== 从 _SongInfoPageState 提升为库级私有常量 / 函数 =====
// （拆分 part 文件后，扩展方法无法不带类名访问 static 成员）
// 各音符权重（参考AchievementRateCalculatorPage）
const int _tapWeight = 1;
const int _holdWeight = 2;
const int _slideWeight = 3;
const int _touchWeight = 1;
const int _breakWeight = 5;
const int _commentsPerPage = 10;
// 难度索引 → dxrating 难度名
const List<String> _dxDifficultyNames = ChartDifficulty.apiNames;

/// 对齐 DXRating 与水鱼使用的 5 位 DX 谱面编号：DX 条目可能带 10000 偏移。
String _normalizeDxInternalId(String raw) {
  final value = int.tryParse(raw.trim());
  if (value == null) return raw.trim();
  if (value >= 10000 && value < 20000) return '${value - 10000}';
  return '$value';
}

const _bpmRangeLabel = 'BPM 范围';
const _defaultBpmLabel = '基准 BPM';

class SongInfoPage extends StatefulWidget {
  final String songId;
  final int initialLevelIndex;
  final bool isDefaultLevelIndex; // 仅由是否提供有效索引决定，调用方不能绕过偏好。

  const SongInfoPage({super.key, required this.songId, int? initialLevelIndex})
      : initialLevelIndex = initialLevelIndex != null &&
                initialLevelIndex >= ChartDifficulty.basic &&
                initialLevelIndex <= ChartDifficulty.reMaster
            ? initialLevelIndex
            : ChartDifficulty.master,
        // 显式传入 BASIC（0）也属于明确指定，不能再被默认难度覆盖。
        isDefaultLevelIndex = initialLevelIndex == null ||
            initialLevelIndex < ChartDifficulty.basic ||
            initialLevelIndex > ChartDifficulty.reMaster;

  @override
  State<SongInfoPage> createState() => _SongInfoSwitcherState();
}

/// 在同一个路由里切换 ST / DX：页面状态不换，新歌的数据到了就地过渡，
/// 返回键也直接回到进入歌曲详情前的页面。
class _SongInfoSwitcherState extends State<SongInfoPage> {
  late String _songId = widget.songId;
  late int _levelIndex = widget.initialLevelIndex;
  late bool _isDefaultLevelIndex = widget.isDefaultLevelIndex;

  void _switchTo(String songId, int levelIndex) {
    setState(() {
      _songId = songId;
      _levelIndex = levelIndex;
      _isDefaultLevelIndex = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SongInfoView(
      songId: _songId,
      initialLevelIndex: _levelIndex,
      isDefaultLevelIndex: _isDefaultLevelIndex,
      onSwitchSong: _switchTo,
    );
  }
}

class _SongInfoView extends StatefulWidget {
  final String songId;
  final int initialLevelIndex;
  final bool isDefaultLevelIndex;
  final void Function(String songId, int levelIndex) onSwitchSong;

  const _SongInfoView({
    required this.songId,
    required this.initialLevelIndex,
    required this.isDefaultLevelIndex,
    required this.onSwitchSong,
  });

  @override
  State<_SongInfoView> createState() => _SongInfoPageState();
}

/// 信息抽屉压住头图的高度。
const double _songDrawerOverlap = 24;

/// 加载任务所属歌曲代数的 Zone 键。
const Object _songLoadZoneKey = #songLoadGeneration;

class _SongInfoPageState extends State<_SongInfoView> {
  final ScrollController _songScrollController = ScrollController();
  final GlobalKey _songHeroKey = GlobalKey();
  bool _showSongTitleInAppBar = false;
  bool _titleVisibilityCheckScheduled = false;

  // 数据加载状态
  bool _isLoading = true;
  bool _defaultDifficultyApplied = false;

  /// 切换 ST / DX 的状态：见 [_switchSong]、[_onSongChanged]。
  int _songGeneration = 0;
  bool _songSwitching = false;
  Map<String, dynamic>? _preloadedSong;

  /// union 全量歌曲里的版本字段（日服版本）。
  String? _unionFrom;

  /// 同上，DX 谱的版本；取不到时为空，不拿 ST 谱的版本顶替。
  String? _unionDxFrom;

  /// 当前谱面类型的国服首次上线日期，来自落雪曲目列表；没上国服时为空。
  String? _cnReleaseDate;

  /// 当前谱面类型各难度的国服上线日期（yyyy-MM-dd），用来提示尚未上线谱面的异常成绩。
  Map<int, String> _cnChartReleaseDates = const {};
  Map<String, dynamic>? _songData;
  List<dynamic>? _diffData; // 保持为dynamic类型，兼容Map和DiffData
  Map<String, dynamic>? _userData;
  List<dynamic>? _tagData;
  List<dynamic>? _tagSongsData;

  // 定数历史（dxrating 静态数据）
  DXDataEntity? _dxData;

  // Maidata解析的物量统计（优先使用）
  Map<int, List<int>> _maidataNoteCounts =
      {}; // key: 难度索引(0-4), value: [tap, hold, slide, touch, break]
  // Maidata解析的break统计
  Map<int, List<int>> _maidataBreakCounts =
      {}; // key: 难度索引(0-4), value: [trueZettaiTap, trueZettaiHold, protectedZettai, star]
  // 仅 maidata 可识别保护套，不能用曲库总物量推算。
  Map<int, NoteStats> _maidataProtectionStats = {};
  Map<int, String> _maidataBpmByDiffIndex =
      {}; // key: 难度索引，value: maidata 中该谱面的 BPM 或 BPM 区间
  Map<int, List<double>> _maidataBpmChangesByDiffIndex = {};
  bool _maidataDecodedSuccessfully = false;
  bool _isBookmarked = false;

  // 谱面笔记相关
  bool _hasNote = false;

  // 参考时长
  int? _referenceDurationSeconds;
  bool _referenceDurationLoading = false;

  // B站谱面确认播放量
  int? _biliPlayCount;
  bool _biliPlayCountLoading = false;
  int? _biliLoadedDiffIndex; // 记录上次加载 B站播放量时的难度索引
  String? _biliBvid; // 当前显示的播放量对应的 BV 号
  bool _biliFromRedis = false; // 是否从 Redis 缓存加载
  bool _biliFromUser = false; // 是否来自用户上传的 BV

  // 舞萌DX 完成度-评级-乘数对照表
  final List<Map<String, dynamic>> maimaiRatingMultiplier = [
    {"completion": 100.5, "rating": "SSS+", "multiplier": 0.224},
    {"completion": 100.4999, "rating": "SSS", "multiplier": 0.222},
    {"completion": 100.0, "rating": "SSS", "multiplier": 0.216},
    {"completion": 99.9999, "rating": "SS+", "multiplier": 0.214},
    {"completion": 99.5, "rating": "SS+", "multiplier": 0.211},
    {"completion": 99.0, "rating": "SS", "multiplier": 0.208},
    {"completion": 98.9999, "rating": "S+", "multiplier": 0.206},
    {"completion": 98.0, "rating": "S+", "multiplier": 0.203},
    {"completion": 97.0, "rating": "S", "multiplier": 0.2},
    {"completion": 96.9999, "rating": "AAA", "multiplier": 0.176},
    {"completion": 94.0, "rating": "AAA", "multiplier": 0.168},
    {"completion": 90.0, "rating": "AA", "multiplier": 0.152},
    {"completion": 80.0, "rating": "A", "multiplier": 0.136},
    {"completion": 79.9999, "rating": "BBB", "multiplier": 0.128},
    {"completion": 75.0, "rating": "BBB", "multiplier": 0.120},
    {"completion": 70.0, "rating": "BB", "multiplier": 0.112},
    {"completion": 60.0, "rating": "B", "multiplier": 0.096},
    {"completion": 50.0, "rating": "C", "multiplier": 0.08},
  ];

  // 当前选中的难度索引
  late int _currentDiffIndex; // 初始值将在initState中设置

  // 表格展开状态
  bool _starScoreTableExpanded = false; // 星星等级表格默认收起
  bool _showNextStarDiff = false; // 是否显示到下一星级的差距
  bool _achievementScoreTableExpanded = false; // 达成率表格默认收起
  bool _toleranceCalculationExpanded = false; // 容错计算默认收起
  bool _ratingDistributionExpanded = false; // 评级分布默认收起
  bool _comboDistributionExpanded = false; // 连击分布默认收起

  // 容错计算相关
  String _selectedNoteType = 'TAP'; // 当前选中的音符类型
  final List<String> _noteTypes = [
    'TAP',
    'HOLD',
    'SLIDE',
    'TOUCH',
    'BREAK'
  ]; // 五种音符类型
  // 自定义BREAK输入（用于非BREAK音符的容错计算）
  int _break50Count = 0; // 已打出的50落数量
  int _break100Count = 0; // 已打出的100落数量
  int _break80Count = 0; // 已打出的80%GREAT数量
  int _break60Count = 0; // 已打出的60%GREAT数量
  int _break50gCount = 0; // 已打出的50%GREAT数量
  int _breakGoodCount = 0; // 已打出的GOOD数量
  int _breakMissCount = 0; // 已打出的MISS数量
  TextEditingController _break50Controller = TextEditingController();
  TextEditingController _break100Controller = TextEditingController();
  TextEditingController _break80Controller = TextEditingController();
  TextEditingController _break60Controller = TextEditingController();
  TextEditingController _break50gController = TextEditingController();
  TextEditingController _breakGoodController = TextEditingController();
  TextEditingController _breakMissController = TextEditingController();

  // 相关收藏品数量
  int _relatedCollectionsCount = 0;

  // 另一种谱面的歌曲ID（如果存在）
  String? _alternativeSongId;

  // 评论相关状态
  List<CommentItem> _comments = [];
  bool _commentsLoading = false;
  int _commentPage = 0;
  final GlobalKey _commentsSectionKey = GlobalKey();
  final TextEditingController _commentInputController = TextEditingController();
  String? _commentError;
  bool _commentSubmitting = false;
  String? _commentDataSource;
  bool _commentRefreshCooldown = false;
  String? _commentOriginalId;
  String? _commentNickname;

  // 谱面评分相关状态
  double? _chartAverageScore;
  int _chartTotalVotes = 0;

  double? _chartUserScore;
  Map<String, dynamic>? _chartUserRatingData;
  Map<String, int>? _chartRatingDistribution; // 评分分布：key 为 "5.0" 等，value 为投票数
  bool _chartRatingLoading = false;
  String? _chartRatingError;
  int _chartRatingRequest = 0;
  double _selectedRating = 3.0;
  int? _userTotalRating;
  int? _theoreticalRating;
  String? _best50OpportunityText;

  /// 上分潜力的首次结果是否已显示；此后才允许尺寸过渡。
  bool _best50OpportunitySettled = false;

  /// 上分潜力能加多少分；null 表示没有可加的分（只显示说明）。
  int? _best50OpportunityGain;

  /// 上分潜力的分档和说明；没有可加的分时为空，横幅不能点。
  List<Best50OpportunityTier> _best50OpportunityTiers = const [];
  String _best50OpportunityNote = '';

  /// 详情区当前标签：0 谱面 / 1 数据 / 2 社区 / 3 工具（2026-11 新布局）。
  int _detailTab = 0;

  @override
  void initState() {
    super.initState();
    _currentDiffIndex = widget.initialLevelIndex;
    _songScrollController.addListener(_updateSongTitleVisibility);
    _commentInputController.addListener(_onCommentInputChanged);
    _startSongLoaders();
  }

  @override
  void didUpdateWidget(_SongInfoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) _onSongChanged(oldWidget.songId);
  }

  @override
  void dispose() {
    _songScrollController
      ..removeListener(_updateSongTitleVisibility)
      ..dispose();
    _break50Controller.dispose();
    _break100Controller.dispose();
    _break80Controller.dispose();
    _break60Controller.dispose();
    _break50gController.dispose();
    _breakGoodController.dispose();
    _breakMissController.dispose();
    _commentInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _songData == null) {
      return BackgroundPageScaffold(
        title: context.l10n.flowSongDetails,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final basicInfo = _songData!['basic_info'];
    final charts = _songData!['charts'];
    final levels = _songData!['level'];
    final currentChart = charts[_currentDiffIndex];
    final currentDiffData =
        _diffData != null && _diffData!.length > _currentDiffIndex
            ? _diffData![_currentDiffIndex]
            : null;
    final userRecord = _getUserBestRecord();
    final brightness = Theme.of(context).brightness;
    final accentColor = _getAccentColor(_currentDiffIndex, brightness);

    _scheduleSongTitleVisibilityCheck();

    // 布局（各块的实现见 song_info/SongInfoLayout.dart）：
    //   全出血的难度色头图（返回 / 笔记 / 收藏 / 分享、曲绘、标题、别名、难度切换）
    //   → 压在头图上的圆角内容区：玩家最佳成绩（含上分潜力）→ 关键数值
    //   → 物量 → 基础信息 → 定数历史 → 谱面标签
    //   → 成绩历史 / 数据 / 社区 / 工具 四个标签页
    //   → 贴底操作栏
    final surface = Theme.of(context).colorScheme.surface;
    final title = _songData!['basic_info']?['title']?.toString() ??
        context.l10n.flowSongDetails;
    return BackgroundPageScaffold(
      title: title,
      headerOverride: const SizedBox.shrink(),
      resizeToAvoidBottomInset: false,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnnotatedRegion<SystemUiOverlayStyle>(
                  // 头图是深色的，状态栏图标用浅色；滚过头图后由顶部栏接管。
                  value: AppTheme.systemUiOverlayStyle(
                    Brightness.dark,
                    navigationBarColor: surface,
                  ),
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: _snapSongDrawer,
                    child: LayoutBuilder(
                      builder: (context, viewport) => SingleChildScrollView(
                        controller: _songScrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 头图固定在抽屉后面；拖头图也能拉动抽屉。
                            _SongDrawerHero(
                              controller: _songScrollController,
                              child: KeyedSubtree(
                                key: _songHeroKey,
                                child: _buildSongHero(
                                    basicInfo, levels, accentColor, userRecord),
                              ),
                            ),
                            // 信息抽屉：向上压住头图 24dp。内容少时也撑够高度，
                            // 保证抽屉能拉到顶。
                            Transform.translate(
                              offset: const Offset(0, -_songDrawerOverlap),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: viewport.maxHeight -
                                      MediaQuery.paddingOf(context).top -
                                      AppHeader.toolbarHeight,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 抽屉把手：点一下收起或拉开，也可以直接拖。
                                    Semantics(
                                      button: true,
                                      label: context.l10n
                                          .flowExpandOrCollapseSongInformation,
                                      onTap: _toggleSongDrawer,
                                      excludeSemantics: true,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _toggleSongDrawer,
                                        child: SizedBox(
                                          height: 28,
                                          child: Center(
                                            child: Container(
                                              width: 36,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outlineVariant,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppDesignTokens
                                                            .radiusPill),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // 玩家最佳成绩
                                          // 玩家最佳成绩：切难度时数字滚动、文字淡入淡出，
                                          // 卡片本身不重新入场。
                                          _buildBestScoreCard(
                                              userRecord, basicInfo, levels),
                                          const SizedBox(height: 12),
                                          _buildKeyStatsRow(currentDiffData),
                                          const SizedBox(height: 12),
                                          // 物量、基础信息、定数历史、谱面标签
                                          ..._buildChartInfo(basicInfo,
                                              currentChart, accentColor),
                                          const SizedBox(height: 4),
                                          _buildDetailTabBar(accentColor),
                                          const SizedBox(height: 12),
                                          _buildDetailTabContent(
                                            chartHistory:
                                                _buildChartHistoryCard(),
                                            currentDiffData: currentDiffData,
                                            accentColor: accentColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 抽屉拉到顶后出现的顶部栏（标题换成歌名）。
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showSongTitleInAppBar,
                    child: AnimatedOpacity(
                      opacity: _showSongTitleInAppBar ? 1 : 0,
                      duration: AppDesignTokens.motion(
                          context, AppDesignTokens.fastMotion),
                      child: AppHeader(
                        title: title,
                        barBackground: surface,
                        actions: [
                          IconButton(
                            tooltip: _isBookmarked
                                ? context.l10n.flowFavorited
                                : context.l10n.flowAddToAFavoritesFolder,
                            onPressed: () => _showBookmarkDialog(),
                            icon: Icon(_isBookmarked
                                ? Icons.favorite
                                : Icons.favorite_border),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 按钮行（跳转到B站、播放音乐、查看谱面代码等）→ 贴底操作栏
          _buildSongActionBar(accentColor),
        ],
      ),
    );
  }

  /// 供 song_info/ 下各 part 文件里的扩展方法刷新界面。
  ///
  /// `setState` 是 State 的 protected 成员，扩展方法里直接调用会触发
  /// `invalid_use_of_protected_member`，所以统一转发到这里。
  void _update(VoidCallback fn) {
    // 已经切走的歌，迟到的结果直接丢弃。
    final generation = Zone.current[_songLoadZoneKey];
    if (generation != null && generation != _songGeneration) return;
    setState(fn);
  }
}

/// 收藏夹选择对话框：选择要将当前谱面加入哪些收藏夹
class _BookmarkFolderSelectorDialog extends StatefulWidget {
  final FavoriteChart chart;

  const _BookmarkFolderSelectorDialog({required this.chart});

  @override
  State<_BookmarkFolderSelectorDialog> createState() =>
      _BookmarkFolderSelectorDialogState();
}

class _BookmarkFolderSelectorDialogState
    extends State<_BookmarkFolderSelectorDialog> {
  final FavoriteFolderService _service = FavoriteFolderService();
  List<FavoriteFolder> _folders = [];
  Set<String> _selectedFolderIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final folders = await _service.getFolders();
    // 查找当前谱面已在哪些收藏夹中
    final containingIds =
        await _service.findFoldersContainingChart(widget.chart.uniqueKey);
    if (mounted) {
      setState(() {
        _folders = List<FavoriteFolder>.from(folders);
        _selectedFolderIds = containingIds.toSet();
        _isLoading = false;
      });
    }
  }

  /// 创建新收藏夹
  Future<void> _createNewFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _BookmarkFolderNameDialog(),
    );
    if (name != null && name.isNotEmpty) {
      final newFolder = await _service.createFolder(name);
      // 自动将当前谱面加入新创建的收藏夹
      await _service.addChartToFolder(newFolder.id, widget.chart);
      if (mounted) {
        setState(() {
          _folders.add(newFolder);
          _selectedFolderIds.add(newFolder.id);
        });
        AppToast.show(
            context.l10n.flowCreatedP0AndAddedThisChart((name).toString()),
            tone: AppToastTone.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final screenWidth = MediaQuery.of(context).size.width;
    final levelNames = ChartDifficulty.labels;
    final bool isUtage = widget.chart.songId.length == 6;
    final String levelName;
    if (isUtage) {
      levelName = ChartDifficulty.utageLabel;
    } else {
      levelName = widget.chart.levelIndex >= 0 &&
              widget.chart.levelIndex < levelNames.length
          ? levelNames[widget.chart.levelIndex]
          : 'Lv.${widget.chart.levelIndex}';
    }

    return AppAlertDialog(
      scrollable: true,
      title: Text(context.l10n.flowAddToAFavoritesFolder),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: screenWidth * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 当前谱面信息：左侧曲绘 + 右侧歌名+定数
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Row(
                children: [
                  // 左侧：曲绘
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                    child: CoverUtil.buildCoverWidget(widget.chart.songId, 60),
                  ),
                  const SizedBox(width: 12),
                  // 右侧：两行信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 第一行：类型标签 + 歌名
                        Row(
                          children: [
                            _buildTypeTag(
                                widget.chart.songType, widget.chart.songId),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.chart.songTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 第二行：难度标签 + 定数
                        Row(
                          children: [
                            _buildDifficultyTag(levelName,
                                widget.chart.levelIndex, widget.chart.songId),
                            const SizedBox(width: 6),
                            Text(
                              'Lv.${widget.chart.ds.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 收藏夹列表
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                : _folders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.favorite_border,
                                size: 48,
                                color: AppColors.greyHint(brightness)),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.flowNoFavoritesFoldersYet,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.flowCreateAFavoritesFolderFirst,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyHint(brightness)),
                            ),
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: screenWidth * 0.9,
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: _folders.map((folder) {
                            final isSelected =
                                _selectedFolderIds.contains(folder.id);
                            return CheckboxListTile(
                              title: Text(
                                folder.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                context.l10n.flowP0Charts(
                                    (folder.charts.length).toString()),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                              value: isSelected,
                              dense: true,
                              onChanged: (checked) async {
                                if (checked == true) {
                                  final added = await _service.addChartToFolder(
                                      folder.id, widget.chart);
                                  if (added && mounted) {
                                    setState(() {
                                      _selectedFolderIds.add(folder.id);
                                    });
                                  }
                                } else {
                                  final removed =
                                      await _service.removeChartFromFolder(
                                          folder.id, widget.chart.uniqueKey);
                                  if (removed && mounted) {
                                    setState(() {
                                      _selectedFolderIds.remove(folder.id);
                                    });
                                  }
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.l10n.flowNewFavoritesFolder),
          onPressed: _createNewFolder,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureDone),
        ),
      ],
    );
  }

  /// 构建类型标签（DX/ST/UT）
  Widget _buildTypeTag(String type, String songId) {
    final brightness = Theme.of(context).brightness;
    final isUtage = songId.length == 6;
    if (isUtage) {
      return const Text(
        'UT',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      );
    } else if (type == 'DX') {
      return Text(
        'DX',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.warningOrange(brightness),
        ),
      );
    } else {
      return Text(
        'ST',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.linkBlue(brightness),
        ),
      );
    }
  }

  /// 构建难度标签（Basic/Advanced/Expert/Master/Re:MASTER）
  Widget _buildDifficultyTag(
      String difficultyLabel, int levelIndex, String songId) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    Color bgColor;
    Color textColor;

    if (songId.length == 6) {
      bgColor = isDark ? const Color(0xFF4A2020) : Colors.red.shade100;
      textColor = isDark ? const Color(0xFFEF5350) : Colors.red;
    } else {
      switch (levelIndex) {
        case ChartDifficulty.basic: // BASIC
          bgColor = isDark ? const Color(0xFF1B3D1B) : Colors.green.shade100;
          textColor = isDark ? const Color(0xFF66BB6A) : Colors.green.shade700;
          break;
        case ChartDifficulty.advanced: // ADVANCED
          bgColor = isDark ? const Color(0xFF3D2E00) : Colors.orange.shade100;
          textColor = isDark ? const Color(0xFFFFB74D) : Colors.orange.shade700;
          break;
        case ChartDifficulty.expert: // EXPERT
          bgColor = isDark ? const Color(0xFF4A2020) : Colors.red.shade100;
          textColor = isDark ? const Color(0xFFEF5350) : Colors.red;
          break;
        case ChartDifficulty.master: // MASTER
          bgColor = isDark ? const Color(0xFF2A1A3D) : Colors.purple.shade100;
          textColor = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade700;
          break;
        case ChartDifficulty.reMaster: // Re:MASTER
          bgColor = isDark ? const Color(0xFF2A1A3D) : Colors.purple.shade100;
          textColor = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade700;
          break;
        default:
          bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
          textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficultyLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

/// 进入或切换谱面时直接定位，保留用户随后手动滑动的位置。
class _DxHistoryScrollView extends StatefulWidget {
  const _DxHistoryScrollView(
      {super.key,
      required this.initialOffset,
      required this.contentWidth,
      required this.child});

  final double initialOffset;
  final double contentWidth;
  final Widget child;

  @override
  State<_DxHistoryScrollView> createState() => _DxHistoryScrollViewState();
}

class _DxHistoryScrollViewState extends State<_DxHistoryScrollView> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          // 仅在实际内容范围内定位，末尾版本无需为左对齐额外预留空白。
          final maxOffset =
              math.max(0.0, widget.contentWidth - constraints.maxWidth);
          final controller = _controller ??= ScrollController(
              initialScrollOffset:
                  widget.initialOffset.clamp(0.0, maxOffset).toDouble(),
              keepScrollOffset: false);
          return SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          );
        },
      );
}

class _BookmarkFolderNameDialog extends StatefulWidget {
  const _BookmarkFolderNameDialog();

  @override
  State<_BookmarkFolderNameDialog> createState() =>
      _BookmarkFolderNameDialogState();
}

class _BookmarkFolderNameDialogState extends State<_BookmarkFolderNameDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final error =
        value.trim().isEmpty ? context.l10n.flowFolderNameCannotBeEmpty : null;
    if (error != _error) setState(() => _error = error);
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = context.l10n.flowFolderNameCannotBeEmpty);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppAlertDialog(
      title: Text(context.l10n.flowNewFavoritesFolder),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onChanged: _validate,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: context.l10n.flowEnterAFolderName,
          errorText: _error,
        ),
        inputFormatters: [LengthLimitingTextInputFormatter(30)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        TextButton(onPressed: _submit, child: Text(context.l10n.flowCreate)),
      ],
    );
  }
}
