import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/service/RankTable/RankTableService.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/manager/DivingFish/UserPlayDataManager.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../../service/RankTable/RankCompletionStore.dart';
import '../../widgets/RankCompletionButton.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';

class RankDetailPage extends StatefulWidget {
  final String rankName;

  const RankDetailPage({super.key, required this.rankName});

  @override
  State<RankDetailPage> createState() => _RankDetailPageState();
}

class _RankDetailPageState extends State<RankDetailPage> {
  final UserPlayDataManager _userPlayDataManager = UserPlayDataManager();
  final MaimaiMusicDataManager _musicDataManager = MaimaiMusicDataManager();

  Map<String, dynamic>? _userPlayData;
  List<Song>? _songs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    RankCompletionStore.instance.load();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playData = await _userPlayDataManager.getCachedUserPlayData();
      final songs = await _musicDataManager.getCachedSongs();

      setState(() {
        _userPlayData = playData;
        _songs = songs;
      });
    } catch (e) {
      debugPrint('加载数据时出错: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getAchievement(String songId, int difficulty) {
    if (_userPlayData == null) return '';

    final records = _userPlayData!['records'] as List?;
    if (records == null) return '';

    for (final record in records) {
      if (record is Map<String, dynamic>) {
        final recordSongId = record['song_id']?.toString();
        final recordDifficulty = record['level_index'] as int?;

        if (recordSongId == songId && recordDifficulty == difficulty) {
          return record['achievements']?.toString() ?? '';
        }
      }
    }

    return '';
  }

  int _parseAchievementToInt(String achievement) {
    if (achievement.isEmpty) return 0;
    String cleaned = achievement.replaceAll('%', '');
    double value = double.tryParse(cleaned) ?? 0.0;
    return (value * 10000).round();
  }

  int _calcMinDamage(
      Song song, int levelIndex, String achievement, RankData rankData) {
    if (achievement.isEmpty) return 0;
    if (levelIndex < 0 || levelIndex >= song.charts.length) return 0;

    final chart = song.charts[levelIndex];
    final notes = chart.notes;
    if (notes.isEmpty) return 0;

    // notes数组: DX=[tap, hold, slide, touch, break], SD=[tap, hold, slide, break]
    final tap = notes[0];
    final hold = notes.length >= 2 ? notes[1] : 0;
    final slide = notes.length >= 3 ? notes[2] : 0;
    final touch = notes.length >= 5 ? notes[3] : 0;
    final breakNote =
        notes.length >= 5 ? notes[4] : (notes.length >= 4 ? notes[3] : 0);

    final totalBase = tap + touch + 2 * hold + 3 * slide + 5 * breakNote;
    if (totalBase == 0) return 0;

    final base = 100000.0 / totalBase;
    final achievementInt = _parseAchievementToInt(achievement);
    if (achievementInt <= 0) return 0;

    final minus = 1010000 - achievementInt;
    final amount = minus / base;

    final greats = (amount / 2).floor();
    final goods = (amount / 5).floor();
    final misses = (amount / 10).floor();

    final damages = <int>[];
    if (rankData.greatDamage != 0) {
      damages.add(rankData.greatDamage * greats);
    }
    if (rankData.goodDamage != 0) {
      damages.add(rankData.goodDamage * goods);
    }
    if (rankData.missDamage != 0) {
      damages.add(rankData.missDamage * misses);
    }

    if (damages.isEmpty) return 0;
    damages.sort();
    return damages.first;
  }

  // 计算剩余血量和总达成率
  Map<String, dynamic> _calcResult(RankData rankData) {
    double totalAchievement = 0;
    int remainingHp = rankData.initialHp;
    bool isDead = false;

    for (int i = 0; i < 4; i++) {
      final songId = rankData.songIds[i];
      final levelIndex = rankData.levelIndexes[i];
      final achievement = _getAchievement(songId, levelIndex);
      final achievementValue = double.tryParse(achievement) ?? 0.0;
      totalAchievement += achievementValue;

      if (!isDead && achievement.isNotEmpty) {
        final song = _getSongById(songId);
        if (song != null) {
          final damage =
              _calcMinDamage(song, levelIndex, achievement, rankData);
          remainingHp -= damage;
          if (remainingHp <= 0) {
            remainingHp = 0;
            isDead = true;
          } else if (i < 3) {
            // 前3首通关后回复（不超过初始血量上限）
            remainingHp = (remainingHp + rankData.healAmount)
                .clamp(0, rankData.initialHp);
          }
          // 最后一首（i==3）不回复，直接以扣血后的血量作为最终结果
        }
      }
    }

    return {
      'totalAchievement': totalAchievement,
      'remainingHp': remainingHp,
      'isDead': isDead,
    };
  }

  Song? _getSongById(String songId) {
    if (_songs == null) return null;
    try {
      return _songs!.firstWhere((song) => song.id == songId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankData = RankListService().getRankData(widget.rankName);
    final isNormalRank = [
      '初段',
      '二段',
      '三段',
      '四段',
      '五段',
      '六段',
      '七段',
      '八段',
      '九段',
      '十段'
    ].contains(widget.rankName);

    return BackgroundPageScaffold(
      title: widget.rankName,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
                  AppDesignTokens.gutter, AppDesignTokens.gutter),
              child: rankData != null
                  ? _buildContent(rankData, isNormalRank)
                  : _buildEmptyContent(),
            ),
    );
  }

  Widget _buildContent(RankData rankData, bool isNormalRank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(rankData, isNormalRank),
        const SizedBox(height: 10),
        _buildCompletionRow(),
        ..._buildResultCard(rankData),
        const SizedBox(height: 16),
        AppSectionHeader(title: context.l10n.flowDanCourseSongs),
        for (int index = 0; index < 4; index++)
          EntranceAnimation(
            index: index,
            duration: const Duration(milliseconds: 300),
            offset: const Offset(0, 8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSongCard(rankData, index),
            ),
          ),
        const SizedBox(height: 6),
        _buildHpSettings(rankData),
      ],
    );
  }

  /// 段位名 + 完成情况。
  Widget _buildHero(RankData rankData, bool isNormalRank) {
    final background =
        isNormalRank ? AppColors.medalColor('bronze') : Colors.purple;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.flowDanCertification,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rankData.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 挑战状态单独一行：点右边的标签修改。
  Widget _buildCompletionRow() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Text(
            context.l10n.flowMyChallenges,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: RankCompletionButton(rank: widget.rankName),
            ),
          ),
        ],
      ),
    );
  }

  /// 预计结果：四首都有成绩才能算，否则不显示。
  List<Widget> _buildResultCard(RankData rankData) {
    for (int i = 0; i < 4; i++) {
      if (_getAchievement(rankData.songIds[i], rankData.levelIndexes[i])
          .isEmpty) {
        return const [];
      }
    }
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final result = _calcResult(rankData);
    final totalAchievement = result['totalAchievement'] as double;
    final remainingHp = result['remainingHp'] as int;
    final isDead = result['isDead'] as bool;
    final resultColor = isDead
        ? AppColors.errorRed(brightness)
        : AppColors.successGreen(brightness);
    return [
      const SizedBox(height: AppDesignTokens.cardGap),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.flowEstimatedResult,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AppBadge(
                  text: isDead
                      ? context.l10n.flowFailed2
                      : context.l10n.flowPassed,
                  numeric: false,
                  fontSize: 14,
                  background: resultColor.withValues(alpha: 0.14),
                  foreground: resultColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${totalAchievement.toStringAsFixed(4)}%',
                maxLines: 1,
                style: AppTheme.number(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: totalAchievement >= 400
                      ? AppColors.successGreen(brightness)
                      : AppColors.errorRed(brightness),
                ),
              ),
            ),
            Text(
              context.l10n.flowTotalAchievement,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  context.l10n.flowRemainingLife,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  '$remainingHp / ${rankData.initialHp}',
                  style: AppTheme.number(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: remainingHp > 0
                        ? AppColors.successGreen(brightness)
                        : AppColors.errorRed(brightness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SmoothLinearProgressIndicator(
              value: rankData.initialHp > 0
                  ? (remainingHp / rankData.initialHp)
                      .clamp(0.0, 1.0)
                      .toDouble()
                  : 0,
              minHeight: 8,
              color: resultColor,
              backgroundColor: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSongCard(RankData rankData, int index) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final songId = rankData.songIds[index];
    final levelIndex = rankData.levelIndexes[index];
    final achievement = _getAchievement(songId, levelIndex);
    final song = _getSongById(songId);
    final hasAchievement = achievement.isNotEmpty;
    final achievementValue = double.tryParse(achievement) ?? 0.0;
    final minDamage = hasAchievement && song != null
        ? _calcMinDamage(song, levelIndex, achievement, rankData)
        : null;

    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: songId,
              initialLevelIndex: levelIndex,
            ),
          ),
        );
      },
      child: Row(
        children: [
          // 曲绘：左上角是第几首，边框是难度色
          SizedBox(
            width: 64,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverUtil.buildCoverWidgetWithContext(
                    context,
                    songId.isNotEmpty ? songId : '0',
                    64,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                      border: Border.all(
                        color: _getDifficultyBorderColor(levelIndex),
                        width: 2,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getDifficultyBorderColor(levelIndex),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTheme.number(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MarqueeText(
                  text: song?.title ??
                      context.l10n.flowSongP02((index + 1).toString()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (song != null) ...[
                      SongTypeBadge(songId: songId, type: song.type),
                      const SizedBox(width: 4),
                    ],
                    ChartDifficultyBadge(
                        levelIndex: levelIndex, songId: songId),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  hasAchievement
                      ? '${achievementValue.toStringAsFixed(4)}%'
                      : context.l10n.flowUnplayed,
                  style: hasAchievement
                      ? AppTheme.number(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: achievementValue >= 100
                              ? AppColors.successGreen(brightness)
                              : scheme.onSurface,
                        )
                      : TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (minDamage != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-$minDamage',
                  style: AppTheme.number(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: minDamage > 0
                        ? AppColors.errorRed(brightness)
                        : scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  context.l10n.flowEstimatedMinimumLifeLoss,
                  style:
                      TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHpSettings(RankData rankData) {
    final brightness = Theme.of(context).brightness;
    final success = AppColors.successGreen(brightness);
    final warning = AppColors.warningOrange(brightness);
    final error = AppColors.errorRed(brightness);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: context.l10n.flowLifeSettings,
            padding: EdgeInsets.only(bottom: 10),
          ),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: context.l10n.flowStartingLife,
                  value: '${rankData.initialHp}',
                  valueColor: success,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'GREAT',
                  value: '-${rankData.greatDamage}',
                  valueColor: warning,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'GOOD',
                  value: '-${rankData.goodDamage}',
                  valueColor: error,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'MISS',
                  value: '-${rankData.missDamage}',
                  valueColor: error,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: context.l10n.flowClearRecovery,
                  value: '+${rankData.healAmount}',
                  valueColor: success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Text(
        context.l10n.flowNoDanDataFound,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Color _getDifficultyBorderColor(int levelIndex) {
    return AppColors.difficultyForegroundByIndex(levelIndex);
  }
}
