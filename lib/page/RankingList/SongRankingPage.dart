import '../../service/CommunityAvatarStore.dart';
import '../../widgets/RankingPlayerBriefSheet.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/service/RankingList/SongRankingService.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/service/SongInfoService.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import 'package:my_first_flutter_app/widgets/CommunityAvatar.dart';
import 'package:my_first_flutter_app/utils/RankingRowExtent.dart';
import '../../utils/AppDesignTokens.dart';
import 'package:my_first_flutter_app/widgets/RankingUi.dart';
import 'package:my_first_flutter_app/widgets/AppUi.dart';
import 'package:my_first_flutter_app/widgets/MarqueeText.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';

enum _DxScoreDisplayMode {
  starsBonus('星+'),
  nextStar('高一级星-'),
  maxDiff('MAX-');

  const _DxScoreDisplayMode(this.label);
  final String label;
}

class SongRankingPage extends StatefulWidget {
  final String songId;
  final int difficultyIndex;
  final RankingType rankingType;
  final String songTitle;
  final String difficultyLabel;
  final String songType;
  final String artist;
  final String genre;
  final String from;

  /// 该曲是否 extra（宴会场 / maidata 追加 / union 独有）。
  ///
  /// 其它追加曲使用 extra 版本名；宴谱虽属于非正曲，版本仍按常规世代显示。
  final bool isExtra;
  final double difficultyDs;

  const SongRankingPage({
    super.key,
    required this.songId,
    required this.difficultyIndex,
    required this.rankingType,
    required this.songTitle,
    required this.difficultyLabel,
    required this.songType,
    required this.artist,
    required this.genre,
    required this.from,
    this.isExtra = false,
    required this.difficultyDs,
  });

  @override
  State<SongRankingPage> createState() => _SongRankingPageState();
}

class _SongRankingPageState extends State<SongRankingPage> {
  final SongRankingService _service = SongRankingService();

  // 切难度、切榜都在本页换数据，初始值来自 widget。
  late int _difficultyIndex = widget.difficultyIndex;
  late String _difficultyLabel = widget.difficultyLabel;
  late double _difficultyDs = widget.difficultyDs;
  late RankingType _rankingType = widget.rankingType;

  int _requestGeneration = 0;
  bool _isLoading = true;
  List<RankingEntry> _rankingList = [];
  RankingEntry? _currentUserEntry;
  String? _errorMessage;
  int? _maxDxScore;
  Map<String, dynamic>? _songData;
  String _currentPlayerId = '';
  final ScrollController _scrollController = ScrollController();
  final RankingRowExtent _rowExtent = RankingRowExtent();
  final RankingEntrance _entrance = RankingEntrance();
  bool _showInvalidScoreWarning = false;
  bool _dontShowAgain = false;
  _DxScoreDisplayMode _dxScoreDisplayMode = _DxScoreDisplayMode.starsBonus;

  /// 数值区（达成率 / DX 分数 + 同步时间）的**上限**宽度。
  ///
  /// 这里以前是写死的 `SizedBox(width: 130)`：数值和同步时间都右对齐，靠不满的
  /// 那一截左边**全是空白**，而昵称却要为这点空白提前打成省略号 ——
  /// DX 分数那一列数字很短（`3199`），浪费最明显。
  ///
  /// 现在改成「按内容宽度收缩、上限不变」：省下的宽度全部让给昵称。留上限是兜底，
  /// 免得异常提示 / 超长时间文案反过来把昵称挤没。
  static const double _valueColumnMaxWidth = 130;

  /// 底部「当前玩家」固定条的数值区上限（比列表行宽一点，原来写死 150）。
  static const double _currentUserValueColumnMaxWidth = 150;

  @override
  void initState() {
    super.initState();
    CommunityAvatarStore.profileChanges.addListener(_onAppearanceChanged);
    _loadSongData();
    // 延迟显示免责声明对话框（等待 context 初始化完成）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDisclaimer();
    });
  }

  void _onAppearanceChanged() {
    if (mounted) _loadRankingData();
  }

  @override
  void dispose() {
    CommunityAvatarStore.profileChanges.removeListener(_onAppearanceChanged);
    _scrollController.dispose();
    super.dispose();
  }

  // 检查是否需要显示免责声明
  Future<void> _checkDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShown =
        prefs.getBool(CacheKeyConstant.songRankingDisclaimerShown) ?? false;
    if (!hasShown) {
      _showDisclaimerDialogFunc();
    }
  }

  // 显示免责声明对话框
  void _showDisclaimerDialogFunc({bool showCheckbox = true}) {
    bool localDontShowAgain = _dontShowAgain;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final dialogBrightness = Theme.of(context).brightness;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppAlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 24,
                    color: AppColors.warningOrange(dialogBrightness),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '免责声明',
                    style: TextStyle(
                      color: AppColors.warningOrange(dialogBrightness),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本排行榜数据仅供参考和娱乐使用，不代表任何官方立场或权威性排名。排名数据基于玩家自愿上传的游戏数据，可能存在误差或延迟。请理性看待排名结果，享受游戏乐趣。',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.greyHint(dialogBrightness),
                        height: 1.6,
                      ),
                    ),
                    if (showCheckbox) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: localDontShowAgain,
                            onChanged: (value) {
                              setDialogState(() {
                                localDontShowAgain = value ?? false;
                              });
                              _dontShowAgain = value ?? false;
                            },
                          ),
                          Text('不再提示'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _closeDisclaimer(
                        dontShowAgain:
                            showCheckbox ? localDontShowAgain : false);
                  },
                  child: Text('知道了'),
                ),
              ],
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
            );
          },
        );
      },
    );
  }

  // 显示免责声明对话框（从按钮点击调用）
  void _showDisclaimer() {
    _dontShowAgain = false;
    _showDisclaimerDialogFunc(showCheckbox: false);
  }

  // 关闭免责声明对话框
  void _closeDisclaimer({bool dontShowAgain = false}) async {
    Navigator.of(context).pop();
    if (dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeyConstant.songRankingDisclaimerShown, true);
    }
  }

  Future<void> _loadSongData() async {
    try {
      final result = await SongInfoService().loadData(widget.songId);
      _songData = result['songData'];
      _calculateMaxDxScore();
    } catch (e) {
      debugPrint('[SongRankingPage] Error loading song data: $e');
      _maxDxScore = 0;
    }
    await _loadRankingData();
  }

  void _calculateMaxDxScore() {
    if (_songData == null) {
      _maxDxScore = 0;
      return;
    }

    int levelIndex = _difficultyIndex;
    List<dynamic> ds = _songData!['ds'];

    if (ds.length == 2) {
      _maxDxScore = _calculateMaxScore(0) + _calculateMaxScore(1);
    } else {
      _maxDxScore = _calculateMaxScore(levelIndex);
    }
  }

  int _calculateMaxScore(int levelIndex) {
    if (_songData == null) return 0;

    List<dynamic> charts = _songData!['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0;

    dynamic chart = charts[levelIndex];
    if (chart['notes'] == null) return 0;

    List<dynamic> notes = chart['notes'];
    int notesSum = notes.fold(0, (sum, note) => sum + (note as int));
    return notesSum * 3;
  }

  String _calculateStarsBonus(int score) {
    if (_maxDxScore == null || _maxDxScore == 0) return '';

    double scoreRate = score / _maxDxScore!;
    dynamic starLevel = 0;
    double minRate = 0.0;

    if (scoreRate >= 0.99) {
      starLevel = 6;
      minRate = 0.99;
    } else if (scoreRate >= 0.98) {
      starLevel = 5.5;
      minRate = 0.98;
    } else if (scoreRate >= 0.97) {
      starLevel = 5;
      minRate = 0.97;
    } else if (scoreRate >= 0.95) {
      starLevel = 4;
      minRate = 0.95;
    } else if (scoreRate >= 0.93) {
      starLevel = 3;
      minRate = 0.93;
    } else if (scoreRate >= 0.90) {
      starLevel = 2;
      minRate = 0.90;
    } else if (scoreRate >= 0.85) {
      starLevel = 1;
      minRate = 0.85;
    } else {
      starLevel = 0;
      minRate = 0.85;
    }

    int minScore = (_maxDxScore! * minRate).ceil();
    int difference = score - minScore;
    String symbol = difference >= 0 ? '+' : '';

    dynamic displayStarLevel = starLevel == 0 ? 1 : starLevel;

    return '\u2726 $displayStarLevel $symbol$difference';
  }

  /// 与歌曲详情页一致：星级门槛向上取整，6 星显示「已满」。
  String _calculateNextStarDiff(int score) {
    final maxScore = _maxDxScore ?? 0;
    if (maxScore <= 0) return '';
    final scoreRate = score / maxScore;
    const stars = [1, 2, 3, 4, 5, 5.5, 6];
    const rates = [0.85, 0.90, 0.93, 0.95, 0.97, 0.98, 0.99];
    for (var i = 0; i < rates.length; i++) {
      if (scoreRate < rates[i]) {
        final difference = (maxScore * rates[i]).ceil() - score;
        return '\u2726 ${stars[i]} -$difference';
      }
    }
    return '\u2726 6 已满';
  }

  String _dxScoreDisplayText(int score) {
    if ((_maxDxScore ?? 0) <= 0) return '';
    return switch (_dxScoreDisplayMode) {
      _DxScoreDisplayMode.starsBonus => _calculateStarsBonus(score),
      _DxScoreDisplayMode.nextStar => _calculateNextStarDiff(score),
      _DxScoreDisplayMode.maxDiff => 'MAX -${_maxDxScore! - score}',
    };
  }

  /// 列表和底部固定行共用，深色模式的高星级只用金色文字。
  Widget _buildDxScoreLabel(int score, Brightness brightness) {
    final highStar = _isHighStarLevel(score);
    final filled = highStar && brightness == Brightness.light;
    return Container(
      padding: filled
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : EdgeInsets.zero,
      decoration: filled
          ? BoxDecoration(
              color: _getStarsColor(score),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Text(
        _dxScoreDisplayText(score),
        style: TextStyle(
          fontSize: 12,
          color: filled ? Colors.black : _getStarsColor(score),
          fontWeight: highStar ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDxScoreDisplaySwitcher() {
    return Tooltip(
      message: 'DX分数显示方式：${_dxScoreDisplayMode.label}（点击切换）',
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            final modes = _DxScoreDisplayMode.values;
            _dxScoreDisplayMode =
                modes[(_dxScoreDisplayMode.index + 1) % modes.length];
          });
        },
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
        label: AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          child: Text(_dxScoreDisplayMode.label,
              style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Color _getStarsColor(int score) {
    if (_maxDxScore == null || _maxDxScore == 0) return Colors.grey;

    double scoreRate = score / _maxDxScore!;

    if (scoreRate >= 0.97) {
      return Colors.yellow;
    } else if (scoreRate >= 0.93) {
      return Colors.orange;
    } else if (scoreRate >= 0.85) {
      return Colors.green.shade300;
    } else {
      return Colors.grey;
    }
  }

  bool _isHighStarLevel(int score) {
    if (_maxDxScore == null || _maxDxScore == 0) return false;
    double scoreRate = score / _maxDxScore!;
    return scoreRate >= 0.97; // 5星、5.5星、6星
  }

  Color _getDifficultyColor(int difficultyIndex) {
    // UTAGE类型歌曲（6位ID）显示粉色
    if (widget.songId.length == 6) {
      return Color(0xFFFF1493); // 粉色（深粉）
    }

    switch (difficultyIndex) {
      case ChartDifficulty.basic: // BASIC
        return Color(0xFF4CAF50); // 绿色
      case ChartDifficulty.advanced: // ADVANCED
        return Color(0xFFFF9800); // 橙色
      case ChartDifficulty.expert: // EXPERT
        return Color(0xFFE91E63); // 红色
      case ChartDifficulty.master: // MASTER
        return Color(0xFF9966CC); // 紫色
      case ChartDifficulty.reMaster: // Re:MASTER
        return Color(0xFF9C27B0); // 深紫色
      default:
        return Color(0xFF9966CC);
    }
  }

  Color _getDifficultyBackgroundColor(int difficultyIndex) {
    // UTAGE类型歌曲（6位ID）显示粉色背景
    if (widget.songId.length == 6) {
      return Color(0xFFFFB6C1); // 浅粉色
    }

    switch (difficultyIndex) {
      case ChartDifficulty.basic: // BASIC
        return Color(0xFFE8F5E9); // 浅绿色
      case ChartDifficulty.advanced: // ADVANCED
        return Color(0xFFFFF3E0); // 浅橙色
      case ChartDifficulty.expert: // EXPERT
        return Color(0xFFFCE4EC); // 浅红色
      case ChartDifficulty.master: // MASTER
        return Color(0xFFE9D8FF); // 浅紫色
      case ChartDifficulty.reMaster: // Re:MASTER
        return Color(0xFFF3E5F5); // 浅粉色
      default:
        return Color(0xFFE9D8FF);
    }
  }

  void _showDifficultySelector() {
    if (_songData == null) return;

    List<dynamic> dsList = _songData!['ds'];
    // UTAGE歌曲全部显示为UTAGE，否则按下标显示标准标签
    final bool isUtage = widget.songId.length == 6;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          title: const Text('选择难度'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < dsList.length; index++)
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 6),
                    child: AppDialogOption(
                      title: isUtage
                          ? ChartDifficulty.utageLabel
                          : _getDifficultyLabelByIndex(index),
                      selected: index == _difficultyIndex,
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      trailing: Text(
                        (dsList[index] is num
                                ? (dsList[index] as num).toDouble()
                                : 0.0)
                            .toStringAsFixed(1),
                        style: AppTheme.number(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _getDifficultyColor(index),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _switchDifficulty(index);
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 在本页换难度。再次选中当前难度不重新加载。
  void _switchDifficulty(int index) {
    if (index == _difficultyIndex) return;
    final dsList = _songData?['ds'] as List<dynamic>?;
    final raw = dsList != null && index < dsList.length ? dsList[index] : null;
    setState(() {
      _difficultyIndex = index;
      _difficultyLabel = widget.songId.length == 6
          ? ChartDifficulty.utageLabel
          : _getDifficultyLabelByIndex(index);
      _difficultyDs = raw is num ? raw.toDouble() : 0.0;
      _calculateMaxDxScore();
    });
    _loadRankingData();
  }

  /// 在本页切到另一个排行榜，难度不变。
  void _switchRankingType() {
    setState(() {
      _rankingType = _rankingType == RankingType.achievementRate
          ? RankingType.dxScore
          : RankingType.achievementRate;
    });
    _loadRankingData();
  }

  String _getDifficultyLabelByIndex(int index) {
    return ChartDifficulty.labelOf(index, fallback: ChartDifficulty.basicLabel);
  }

  String _formatDifficultyLabel(String label) {
    final index = ChartDifficulty.indexOf(label);
    if (index != null) return ChartDifficulty.labelOf(index);
    // 兼容调用方传入“难度名 + 等级”的旧文案，先检查 Re:MASTER，避免误认成 MASTER。
    final compact = label.toUpperCase().replaceAll(':', '');
    for (final index in [
      ChartDifficulty.reMaster,
      ...ChartDifficulty.indices
    ]) {
      if (compact.contains(
          ChartDifficulty.labelOf(index).toUpperCase().replaceAll(':', ''))) {
        return ChartDifficulty.labelOf(index);
      }
    }
    return label.toUpperCase();
  }

  // 格式化更新时间
  String _formatUpdateTime(int updateTime) {
    if (updateTime == 0) {
      return '';
    }
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(updateTime);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    // 超过7天显示绝对时间，否则显示相对时间
    if (difference.inDays >= 7) {
      return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 数字补零
  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  Future<void> _loadRankingData() async {
    if (!mounted) return;
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showInvalidScoreWarning = false;
    });

    try {
      List<RankingEntry> rankingList = await _service.getSongRanking(
        widget.songId,
        _difficultyIndex,
        _rankingType,
        limit: 100,
      );

      String currentPlayerId = await _service.getCurrentPlayerId();
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _currentPlayerId = currentPlayerId;
      });
      RankingEntry? userEntry = await _service.getUserRanking(
        widget.songId,
        _difficultyIndex,
        _rankingType,
        currentPlayerId,
      );
      if (!mounted || generation != _requestGeneration) return;
      // 榜内用户沿用当前列表快照，避免两次请求之间更新或并列口径差异。
      userEntry = rankingList
              .where((entry) => entry.playerId == currentPlayerId)
              .firstOrNull ??
          userEntry;

      // 校验当前用户数据是否合法
      if (userEntry != null) {
        bool isValid = await _service.validateUserRecord(
          widget.songId,
          _difficultyIndex,
          userEntry.achievementRate,
          userEntry.dxScore,
        );
        if (!mounted || generation != _requestGeneration) return;
        if (!isValid) {
          setState(() {
            _showInvalidScoreWarning = true;
          });
        }
      }

      setState(() {
        _rankingList = rankingList;
        _currentUserEntry = userEntry;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _requestGeneration) return;
      debugPrint('[SongRankingPage] Error loading ranking data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载排行榜数据失败';
      });
    }
  }

  void _scrollToCurrentUser() {
    final entry = _currentUserEntry;
    if (entry == null) return;
    if (entry.rank > 100) {
      AppToast.show('抱歉，您不在前100名内');
      return;
    }
    final index = _rankingList.indexWhere(
      (item) => item.playerId == entry.playerId,
    );
    if (index == -1) {
      AppToast.show('抱歉，您不在前100名内');
      return;
    }
    _rowExtent.scrollRowToTop(_scrollController, index);
  }

  Widget _buildIdentity(RankingEntry entry, {bool isCurrentUser = false}) {
    return CommunityPlayerIdentity(
      avatarId: entry.avatarId,
      dataSource: entry.dataSource,
      // 开发者白名单按 `<source>:<id>` 整串匹配，见 DataSourceTag
      playerId: entry.playerId,
      name: entry.playerName,
      // 头像高度对齐「玩家名 + 数据源标签」两行文字的总高
      // （单曲排行榜 / DX 分数排行榜共用这一行）
      avatarMatchesTextHeight: true,
      nameStyle: TextStyle(
        fontSize: 14,
        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// 数值区按内容收缩（上限 [maxWidth]），右对齐靠不满的空白让给昵称。
  Widget _buildValueCell(RankingEntry entry, Brightness brightness,
      {double maxWidth = _valueColumnMaxWidth}) {
    final scheme = Theme.of(context).colorScheme;
    final isAchievement = _rankingType == RankingType.achievementRate;
    final fc = entry.fc?.toLowerCase();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DX分数排行榜显示星星等级
                if (!isAchievement) ...[
                  _buildDxScoreLabel(entry.dxScore, brightness),
                  const SizedBox(width: 6),
                ],
                // AP/AP+ 标签
                if (isAchievement && (fc == 'ap' || fc == 'app')) ...[
                  ComboLabelBadge(raw: fc!),
                  const SizedBox(width: 6),
                ],
                Text(
                  isAchievement
                      ? '${entry.achievementRate.toStringAsFixed(4)}%'
                      : entry.dxScore.toString(),
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
          // 同步时间：数值区没有固定宽度兜着，超长时缩小而不是换行把行撑高。
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _formatUpdateTime(entry.updateTime),
              maxLines: 1,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(
      RankingEntry entry, bool isCurrentUser, Brightness brightness) {
    return RankingPlayerRow(
      playerId: entry.playerId,
      nickname: entry.playerName,
      child: RankingRow(
        rank: entry.rank,
        highlighted: isCurrentUser,
        identity: _buildIdentity(entry, isCurrentUser: isCurrentUser),
        value: _buildValueCell(entry, brightness),
      ),
    );
  }

  RankingEntry get _prototypeEntry => RankingEntry(
        rank: 1,
        playerId: '',
        playerName: '',
        achievementRate: 101.5,
        dxScore: 10000,
        fc: 'AP+',
        dataSource: 'shuiyu',
        updateTime: DateTime.now().millisecondsSinceEpoch,
      );

  Widget _buildRowPrototype(Brightness brightness) => KeyedSubtree(
        key: _rowExtent.key,
        child: _buildRankingItem(_prototypeEntry, false, brightness),
      );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final title = _rankingType == RankingType.achievementRate
        ? '达成率排行榜'
        : 'DX分数排行榜';

    return BackgroundPageScaffold(
      title: title,
      actions: [
        // 免责声明按钮
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showDisclaimer,
        ),
        if (_currentUserEntry != null)
          IconButton(
            icon: const Icon(Icons.location_searching),
            onPressed: _scrollToCurrentUser,
            tooltip: '跳转到我的排名',
          ),
      ],
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(children: [
        // 歌曲信息卡片
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 10),
          child: AppCard(
            radius: AppDesignTokens.radiusMedium,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                  child: CoverUtil.buildCoverWidgetWithContext(
                      context, widget.songId, 84),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：谱面类型 + 歌名
                      Row(
                        children: [
                          SongTypeBadge(
                              songId: widget.songId, type: widget.songType),
                          const SizedBox(width: 6),
                          Expanded(
                            child: MarqueeText(
                              text: widget.songTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 第二行：版本与紧凑的显示切换，避免挤压难度标签。
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              StringUtil.formatVersion2WithFlag(
                                  widget.from,
                                  widget.isExtra &&
                                      !ChartDifficulty.isUtageSong(
                                          widget.songId,
                                          type: widget.songType)),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_rankingType == RankingType.dxScore) ...[
                            const SizedBox(width: 4),
                            _buildDxScoreDisplaySwitcher(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 第三行：难度和定数（可点击切换难度）+ 切到另一个榜
                      Row(
                        children: [
                      Material(
                        color: _getDifficultyBackgroundColor(
                            _difficultyIndex),
                        clipBehavior: Clip.antiAlias,
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                        child: InkWell(
                          onTap: _showDifficultySelector,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDifficultyLabel(
                                      _difficultyLabel),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getDifficultyColor(
                                        _difficultyIndex),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _difficultyDs.toStringAsFixed(1),
                                  style: AppTheme.number(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _getDifficultyColor(
                                        _difficultyIndex),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: _getDifficultyColor(
                                      _difficultyIndex),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: PressScale(
                          child: GestureDetector(
                            onTap: _switchRankingType,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppSurfaces.inset(context),
                                borderRadius: BorderRadius.circular(
                                    AppDesignTokens.radiusSmall),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 15,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _rankingType ==
                                              RankingType.achievementRate
                                          ? 'DX分数榜'
                                          : '达成率榜',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
        ),
        Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _rankingList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 64,
                                  color: AppColors.greyHint(brightness),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '榜上无人哦，快来抢沙发！',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.greyHint(brightness),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.zero,
                                  prototypeItem: _buildRowPrototype(brightness),
                                  itemCount: _rankingList.length,
                                  itemBuilder: (context, index) {
                                    RankingEntry entry = _rankingList[index];
                                    bool isCurrentUser =
                                        entry.playerId == _currentPlayerId;
                                    return _entrance.wrap(_rankingList, index, _buildRankingItem(
                                        entry, isCurrentUser, brightness));
                                  },
                                ),
                              ),
                              if (_currentUserEntry != null)
                                RankingSelfBar(
                                  rank: _currentUserEntry!.rank,
                                  onTap: _scrollToCurrentUser,
                                  identity: _buildIdentity(_currentUserEntry!,
                                      isCurrentUser: true),
                                  // 成绩异常时用警告替换数值和同步时间
                                  value: _showInvalidScoreWarning
                                      ? ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth:
                                                  _currentUserValueColumnMaxWidth),
                                          child: Text(
                                            '您的此谱面游玩数据存在异常，请检查!',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.warningOrange(
                                                  brightness),
                                            ),
                                          ),
                                        )
                                      : _buildValueCell(
                                          _currentUserEntry!, brightness,
                                          maxWidth:
                                              _currentUserValueColumnMaxWidth),
                                ),
                            ],
                          )),
      ]),
    );
  }
}
