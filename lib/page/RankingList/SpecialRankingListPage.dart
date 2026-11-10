import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import 'package:flutter/material.dart';
import '../../widgets/EmptyState.dart';
import 'package:my_first_flutter_app/service/RankingList/SpecialRankingListService.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import '../SongInfoPage.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/ChartDifficulty.dart';
import '../../widgets/RankingUi.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/AppDialogs.dart';

class SpecialRankingListPage extends StatefulWidget {
  const SpecialRankingListPage({super.key});

  @override
  State<SpecialRankingListPage> createState() => _SpecialRankingListPageState();
}

enum RankingType {
  breakCount, // 绝赞数排行榜
  regularBreakCount, // 常规谱绝赞数排行榜（宴会场不参与）
  difficultyDiff, // 定数差值排行榜（可正反向切换）
  masterDiff, // MASTER/Re:MASTER定数差值排行榜（可正反向切换）
  expertDiff, // EXPERT定数差值排行榜（可正反向切换）
  sampleCount, // 样本总数排行榜
  noteCount, // 物量排行榜
  avgAchievement, // 平均达成排行榜
  masterAvgAchievement, // MASTER/Re:MASTER平均达成排行榜
  expertAvgAchievement, // EXPERT平均达成排行榜
  bpmRanking, // BPM排行榜（可正反向切换）
  breakRatio, // 绝赞占总物量的比例
  difficultyGap, // 同曲 EXPERT→MASTER / MASTER→Re:MASTER 的官方定数差
  slideRatio, // SLIDE 占比，ST/DX/UT 均参与
  touchRatio, // TOUCH 占比，DX/UT 参与，ST 不参与
  tapRatio, // TAP 占比，ST/DX/UT 均参与
  holdRatio, // HOLD 占比，ST/DX/UT 均参与
}

class _SpecialRankingListPageState extends State<SpecialRankingListPage> {
  final RankingEntrance _entrance = RankingEntrance();
  final SpecialRankingListService _service = SpecialRankingListService();
  bool _isLoading = true;
  RankingType _currentRankingType = RankingType.breakCount;
  RankingType _resultType = RankingType.breakCount; // 屏幕上这份榜单所属的类型
  int _requestGeneration = 0;
  bool _usingCachedData = false;
  bool _isReverse = false; // 当前排行榜是否为反向（仅对支持的排行榜生效）
  List<SpecialRankingEntry> _rankingList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking({bool forceRefresh = false}) async {
    final generation = ++_requestGeneration;
    final type = _currentRankingType;
    if (forceRefresh) {
      _service.forceRefreshNextRead = true;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ranking = await _fetchCachedRanking();
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _rankingList = ranking;
        _resultType = type;
        _usingCachedData = _service.lastReadWasCached;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _errorMessage = appL10n.flowCouldNotFetchLeaderboardP0((e).toString());
        _usingCachedData = false;
        _isLoading = false;
      });
    }
  }

  /// 通过 HTTP 获取排行榜，缓存与计算统一交给服务端。
  Future<List<SpecialRankingEntry>> _fetchCachedRanking() async {
    switch (_currentRankingType) {
      case RankingType.breakRatio:
        return _service.getBreakRatioRanking(reverse: _isReverse);
      case RankingType.difficultyGap:
        return _service.getDifficultyGapRanking(reverse: _isReverse);
      case RankingType.slideRatio:
        return _service.getSlideRatioRanking(reverse: _isReverse);
      case RankingType.touchRatio:
        return _service.getTouchRatioRanking(reverse: _isReverse);
      case RankingType.tapRatio:
        return _service.getTapRatioRanking(reverse: _isReverse);
      case RankingType.holdRatio:
        return _service.getHoldRatioRanking(reverse: _isReverse);
      case RankingType.breakCount:
        return _isReverse
            ? _service.getReverseBreakCountRanking(limit: 100)
            : _service.getBreakCountRanking(limit: 100);
      case RankingType.regularBreakCount:
        return _isReverse
            ? _service.getReverseRegularBreakCountRanking(limit: 100)
            : _service.getRegularBreakCountRanking(limit: 100);
      case RankingType.difficultyDiff:
        return _isReverse
            ? _service.getReverseDifficultyDiffRanking(limit: 100)
            : _service.getDifficultyDiffRanking(limit: 100);
      case RankingType.masterDiff:
        return _isReverse
            ? _service.getReverseMasterDifficultyDiffRanking(limit: 100)
            : _service.getMasterDifficultyDiffRanking(limit: 100);
      case RankingType.expertDiff:
        return _isReverse
            ? _service.getReverseExpertDifficultyDiffRanking(limit: 100)
            : _service.getExpertDifficultyDiffRanking(limit: 100);
      case RankingType.sampleCount:
        return _isReverse
            ? _service.getReverseSampleCountRanking(limit: 100)
            : _service.getSampleCountRanking(limit: 100);
      case RankingType.noteCount:
        return _isReverse
            ? _service.getReverseNoteCountRanking(limit: 100)
            : _service.getNoteCountRanking(limit: 100);
      case RankingType.avgAchievement:
        return _isReverse
            ? _service.getReverseAvgAchievementRanking(limit: 100)
            : _service.getAvgAchievementRanking(limit: 100);
      case RankingType.masterAvgAchievement:
        return _isReverse
            ? _service.getReverseMasterAvgAchievementRanking(limit: 100)
            : _service.getMasterAvgAchievementRanking(limit: 100);
      case RankingType.expertAvgAchievement:
        return _isReverse
            ? _service.getReverseExpertAvgAchievementRanking(limit: 100)
            : _service.getExpertAvgAchievementRanking(limit: 100);
      case RankingType.bpmRanking:
        return _isReverse
            ? _service.getReverseBpmRanking(limit: 100)
            : _service.getBpmRanking(limit: 100);
    }
  }

  /// 当前排行榜是否支持正反向切换（所有排行榜都支持）
  bool _rankingSupportsReverse(RankingType type) {
    return true;
  }

  String _getRankingTypeName(RankingType type) {
    switch (type) {
      case RankingType.breakRatio:
        return context.l10n.flowBREAKShareRanking;
      case RankingType.difficultyGap:
        return context.l10n.flowSameSongDifficultyGapRanking;
      case RankingType.slideRatio:
        return context.l10n.flowSLIDEShareRanking;
      case RankingType.touchRatio:
        return context.l10n.flowTOUCHShareRanking;
      case RankingType.tapRatio:
        return context.l10n.flowTAPShareRanking;
      case RankingType.holdRatio:
        return context.l10n.flowHOLDShareRanking;
      case RankingType.breakCount:
        return context.l10n.flowBREAKCountRanking;
      case RankingType.regularBreakCount:
        return context.l10n.flowNormalChartBREAKCountRanking;
      case RankingType.difficultyDiff:
        return context.l10n.flowConstantDifferenceRanking;
      case RankingType.masterDiff:
        return context.l10n.flowMASTERReMASTERConstantDifferenceRanking;
      case RankingType.expertDiff:
        return context.l10n.flowEXPERTConstantDifferenceRanking;
      case RankingType.sampleCount:
        return context.l10n.flowSampleCountRanking;
      case RankingType.noteCount:
        return context.l10n.flowNoteCountRanking;
      case RankingType.avgAchievement:
        return context.l10n.featureAverageAchievementLeaderboard;
      case RankingType.masterAvgAchievement:
        return context.l10n.flowMASTERReMASTERAverageAchievementRanking;
      case RankingType.expertAvgAchievement:
        return context.l10n.flowEXPERTAverageAchievementRanking;
      case RankingType.bpmRanking:
        return context.l10n.flowBPMRanking;
    }
  }

  Color _getRankingValueColor() {
    switch (_resultType) {
      case RankingType.breakRatio:
      case RankingType.slideRatio:
      case RankingType.touchRatio:
      case RankingType.tapRatio:
      case RankingType.holdRatio:
        return Theme.of(context).colorScheme.primary;
      case RankingType.difficultyGap:
        return Theme.of(context).colorScheme.tertiary;
      case RankingType.breakCount:
      case RankingType.regularBreakCount:
        return Colors.blue;
      case RankingType.difficultyDiff:
      case RankingType.masterDiff:
      case RankingType.expertDiff:
        return Colors.orange;
      case RankingType.sampleCount:
        return Colors.teal;
      case RankingType.noteCount:
        return Colors.green;
      case RankingType.avgAchievement:
      case RankingType.masterAvgAchievement:
      case RankingType.expertAvgAchievement:
        return Colors.purple;
      case RankingType.bpmRanking:
        return Colors.red;
    }
  }

  String _formatRankingValue(SpecialRankingEntry entry) {
    final value = entry.breakCount;
    final precise = entry.metric ?? value.toDouble();
    switch (_resultType) {
      case RankingType.breakRatio:
      case RankingType.slideRatio:
      case RankingType.touchRatio:
      case RankingType.tapRatio:
      case RankingType.holdRatio:
        return '${(precise / 100).toStringAsFixed(2)}%';
      case RankingType.difficultyGap:
        return (precise / 100).toStringAsFixed(2);
      case RankingType.breakCount:
      case RankingType.regularBreakCount:
        return value.toString();
      case RankingType.difficultyDiff:
      case RankingType.masterDiff:
      case RankingType.expertDiff:
        return (value / 100).toStringAsFixed(2);
      case RankingType.sampleCount:
        return value.toString();
      case RankingType.noteCount:
        return value.toString();
      case RankingType.avgAchievement:
      case RankingType.masterAvgAchievement:
      case RankingType.expertAvgAchievement:
        return (value / 100).toStringAsFixed(2);
      case RankingType.bpmRanking:
        return value.toString();
    }
  }

  String _getRankingValueLabel() {
    switch (_resultType) {
      case RankingType.breakRatio:
        return context.l10n.flowBREAKShare;
      case RankingType.difficultyGap:
        return context.l10n.flowConstantGap;
      case RankingType.slideRatio:
        return context.l10n.flowSLIDEShare;
      case RankingType.touchRatio:
        return context.l10n.flowTOUCHShare;
      case RankingType.tapRatio:
        return context.l10n.flowTAPShare;
      case RankingType.holdRatio:
        return context.l10n.flowHOLDShare;
      case RankingType.breakCount:
      case RankingType.regularBreakCount:
        return context.l10n.flowBREAKCount;
      case RankingType.difficultyDiff:
      case RankingType.masterDiff:
      case RankingType.expertDiff:
        return context.l10n.flowConstantDifference;
      case RankingType.sampleCount:
        return context.l10n.flowSampleCount;
      case RankingType.noteCount:
        return context.l10n.flowNotes;
      case RankingType.avgAchievement:
      case RankingType.masterAvgAchievement:
      case RankingType.expertAvgAchievement:
        return context.l10n.featureAverageAchievement;
      case RankingType.bpmRanking:
        return 'BPM';
    }
  }

  void _showRankingTypeDialog() {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          title: Text(dialogContext.l10n.flowChooseRankingType,
              style: TextStyle(color: AppColors.primaryText(brightness))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(dialogContext.l10n.featureClose))
          ],
          backgroundColor: AppColors.cardBackground(brightness),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowBREAKCountRanking,
                  dialogContext.l10n.flowRankByBREAKCountOrderCanBe,
                  RankingType.breakCount,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowNormalChartBREAKCountRanking,
                  dialogContext.l10n.flowRankByBREAKCountExcludingUTAGEOrder,
                  RankingType.regularBreakCount,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowBREAKShareRanking,
                  dialogContext.l10n.flowBREAKCountTotalNotesRankedAsA,
                  RankingType.breakRatio,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowTAPShareRanking,
                  dialogContext.l10n.flowTAPCountTotalNotesIncludesSTDX,
                  RankingType.tapRatio,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowHOLDShareRanking,
                  dialogContext.l10n.flowHOLDCountTotalNotesIncludesSTDX,
                  RankingType.holdRatio,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowSLIDEShareRanking,
                  dialogContext.l10n.flowSLIDECountTotalNotesIncludesSTDX,
                  RankingType.slideRatio,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowTOUCHShareRanking,
                  dialogContext.l10n.flowTOUCHCountTotalNotesIncludesDXUT,
                  RankingType.touchRatio,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowSameSongDifficultyGapRanking,
                  dialogContext.l10n.flowOfficialConstantGapForEXPERTMASTERAnd,
                  RankingType.difficultyGap,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowConstantDifferenceRanking,
                  dialogContext.l10n.flowRankByFittedMinusOfficialConstantOrder,
                  RankingType.difficultyDiff,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext
                      .l10n.flowMASTERReMASTERConstantDifferenceRanking,
                  dialogContext.l10n.flowMASTERReMASTEROnlyOrderCanBe,
                  RankingType.masterDiff,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowEXPERTConstantDifferenceRanking,
                  dialogContext.l10n.flowEXPERTOnlyOrderCanBeReversed,
                  RankingType.expertDiff,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowSampleCountRanking,
                  dialogContext.l10n.flowRankByTotalPlayerSamplesOrderCan,
                  RankingType.sampleCount,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowNoteCountRanking,
                  dialogContext.l10n.flowRankByTheTotalOfAllFive,
                  RankingType.noteCount,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.featureAverageAchievementLeaderboard,
                  dialogContext.l10n.flowRankByAverageAchievementOrderCanBe,
                  RankingType.avgAchievement,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext
                      .l10n.flowMASTERReMASTERAverageAchievementRanking,
                  dialogContext.l10n.flowMASTERReMASTEROnlyOrderCanBe,
                  RankingType.masterAvgAchievement,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowEXPERTAverageAchievementRanking,
                  dialogContext.l10n.flowEXPERTOnlyOrderCanBeReversed,
                  RankingType.expertAvgAchievement,
                ),
                _buildDialogTile(
                  brightness,
                  dialogContext.l10n.flowBPMRanking,
                  dialogContext.l10n.flowRankBySongBPMOrderCanBe,
                  RankingType.bpmRanking,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogTile(
      Brightness brightness, String title, String subtitle, RankingType type) {
    return ListTile(
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText(brightness))),
      subtitle: Text(subtitle,
          style: TextStyle(color: AppColors.secondaryText(brightness))),
      trailing: _currentRankingType == type
          ? Icon(Icons.check, color: AppColors.linkBlue(brightness))
          : null,
      onTap: () {
        Navigator.pop(context);
        if (_currentRankingType == type) return;
        setState(() {
          _currentRankingType = type;
          // 切换到不支持反向的排行榜时，重置为正向
          if (!_rankingSupportsReverse(type)) {
            _isReverse = false;
          }
        });
        _loadRanking();
      },
    );
  }

  Widget _buildEntryCard(SpecialRankingEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: AppDesignTokens.radiusMedium,
        padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongInfoPage(
                songId: entry.songId,
                initialLevelIndex: entry.difficultyIndex,
              ),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
                width: 32,
                child: Center(child: RankingMedal(rank: entry.rank))),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: CoverUtil.buildCoverWidgetWithContext(
                  context, entry.songId, 52),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MarqueeText(
                    text: entry.songTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      SongTypeBadge(songId: entry.songId, type: entry.songType),
                      if (_resultType == RankingType.difficultyGap &&
                          entry.fromDifficultyIndex != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ChartDifficulty.labelOf(entry.fromDifficultyIndex!)} ${entry.fromDs?.toStringAsFixed(1) ?? '-'}',
                                style: AppTheme.number(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant),
                              ),
                              Text(
                                '→ ${ChartDifficulty.labelOf(entry.difficultyIndex)} ${entry.ds.toStringAsFixed(1)}',
                                style: AppTheme.number(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_resultType != RankingType.bpmRanking) ...[
                        const SizedBox(width: 4),
                        ChartDifficultyBadge(
                          levelIndex: entry.difficultyIndex,
                          songId: entry.songId,
                          label: entry.difficultyLabel,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.ds}',
                          style: AppTheme.number(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 排行榜数值
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getRankingValueColor().withValues(alpha: 0.14),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Column(
                children: [
                  Text(
                    _formatRankingValue(entry),
                    style: AppTheme.number(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    _getRankingValueLabel(),
                    style:
                        TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return BackgroundPageScaffold(
      title: context.l10n.featureSpecialLeaderboards,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(children: [
// 排行榜类型选择 + 刷新行
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showRankingTypeDialog,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppSurfaces.card(context),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list,
                            size: 18, color: AppColors.primaryText(brightness)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getRankingTypeName(_currentRankingType),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(brightness),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            size: 20, color: AppColors.primaryText(brightness)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh,
                    size: 20, color: AppColors.primaryText(brightness)),
                onPressed: () => _loadRanking(forceRefresh: true),
                tooltip: context.l10n.flowRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: AppSurfaces.card(context),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
// 正反向切换（仅对支持的排行榜显示）
        if (_rankingSupportsReverse(_currentRankingType))
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedChoiceBar<bool>(
                values: const [false, true],
                value: _isReverse,
                label: (reverse) => reverse
                    ? context.l10n.flowReverse
                    : context.l10n.flowForward,
                onChanged: (reverse) {
                  if (reverse == _isReverse) return;
                  setState(() => _isReverse = reverse);
                  _loadRanking();
                },
              ),
            ),
          ),
        if (_usingCachedData)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                  context
                      .l10n.flowShowingPreviouslySavedDataRefreshWhenConnected,
                  style:
                      TextStyle(color: AppColors.warningOrange(brightness)))),

        // 排行榜列表
        Expanded(
          child: _isLoading && _rankingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(context.l10n.flowLoading3,
                          style: TextStyle(
                              color: AppColors.primaryText(brightness))),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // 主内容区
                    _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48,
                                      color: AppColors.errorRed(brightness)),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.errorRed(brightness)),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _loadRanking(forceRefresh: true),
                                    child: Text(context.l10n.flowRetry),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _rankingList.isEmpty
                            ? EmptyState(
                                message: context.l10n
                                    .flowNoLeaderboardDataYetTryRefreshingLater)
                            : ListView.builder(
                                // 拿到新榜单时重新挂载，首屏的行才会重新进场。
                                key: ObjectKey(_rankingList),
                                padding: const EdgeInsets.fromLTRB(
                                    AppDesignTokens.gutter,
                                    0,
                                    AppDesignTokens.gutter,
                                    8),
                                itemCount: _rankingList.length,
                                itemBuilder: (context, index) => _entrance.wrap(
                                    _rankingList,
                                    index,
                                    _buildEntryCard(_rankingList[index])),
                              ),
                  ],
                ),
        ),
      ]),
    );
  }
}
