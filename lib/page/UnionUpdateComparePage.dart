import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/widgets/NoRipple.dart';
import 'package:flutter/material.dart';

import '../entity/DivingFish/Song.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../service/Union/UnionUpdateCompareService.dart';
import '../utils/AppTheme.dart';
import '../utils/CommonWidgetUtil.dart';
import '../utils/CoverUtil.dart';
import '../utils/SongFilterUtil.dart';
import '../utils/StringUtil.dart';
import '../widgets/EmptyState.dart';
import '../widgets/AppHeader.dart';
import 'SongInfoPage.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';

/// 「国服更新对照」页：把本地曲库按**国服（水鱼）更新前沿**摆开，
/// 让用户一眼看到「日服已上、国服还没上」的歌 = 下次更新最可能补上的曲目。
///
/// 为什么需要这个页面：曲目详情页的「首次上线」是**日服**首发时间，
/// 国服玩家光看这个日期判断不出这首歌自己这边上了没有。本页先按筛选后的
/// 国服常规曲首发日期确定前沿，再按日期补齐 union 独有候选。
///
/// 口径与取舍全部写在 [UnionUpdateCompareService] 的类注释里；页面只负责展示，
/// 并在页内用「口径说明」弹窗把不确定性如实讲清楚（首发日期来自曲库元数据，
/// 不代表国服实际开放日期）。
///
/// 数据完全来自本地已合并曲库（`MaimaiMusicDataManager.getCachedSongs()`），
/// **不需要额外网络**：union 独有曲在合并时已经打了 `Song.isExtra` 标记。
class UnionUpdateComparePage extends StatefulWidget {
  const UnionUpdateComparePage({super.key, this.songsLoader});

  /// 仅供测试：替换曲库读取（widget 测试里没有真实缓存）。
  @visibleForTesting
  final Future<List<Song>?> Function()? songsLoader;

  @override
  State<UnionUpdateComparePage> createState() => _UnionUpdateComparePageState();
}

/// 列表分段：待上线 / 国服未收录的旧曲 / 宴会场 / 国服已上（含前沿）/ 超前上线。
enum _Section { upcoming, skipped, utage, cn, early }

class _UnionUpdateComparePageState extends State<UnionUpdateComparePage> {
  bool _loading = true;
  UnionUpdateCompare? _compare;
  _Section _section = _Section.upcoming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader =
        widget.songsLoader ?? () => MaimaiMusicDataManager().getCachedSongs();
    List<Song>? songs;
    try {
      songs = await loader();
    } catch (e) {
      debugPrint('[UnionUpdateCompare] 读取曲库失败: $e');
    }
    if (!mounted) return;
    setState(() {
      _compare = UnionUpdateCompareService.compare(songs ?? const []);
      _loading = false;
    });
  }

  List<Song> get _currentSongs {
    final compare = _compare;
    if (compare == null) return const [];
    switch (_section) {
      case _Section.upcoming:
        return compare.upcoming;
      case _Section.skipped:
        return compare.skipped;
      case _Section.utage:
        return compare.utage;
      case _Section.cn:
        return compare.cnSongs;
      case _Section.early:
        return compare.earlyReleases;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return BackgroundPageScaffold(
      title: context.l10n.featureChinaUpdateComparison,
      actions: [
        IconButton(
          tooltip: context.l10n.flowAboutThisComparison,
          icon: const Icon(Icons.info_outline),
          onPressed: _showNotes,
        ),
      ],
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : !(_compare?.hasData ?? false)
              ? _buildEmpty()
              : _buildBody(brightness),
    );
  }

  /// 版本显示：**必须与曲目详情页同一个口径**。
  ///
  /// 详情页用的是 `formatVersion2WithFlag(from, isExtra)`；union 独有曲的
  /// `from` 是日服写法（`maimai でらっくす PRiSM PLUS`），而 `formatVersion`
  /// 不带 extra 标记时会把这类版本串判成"未知"、落到官方世代年号那一档 ——
  /// 表现就是同一个 id 在对照页显示 `DX 2026彩`、详情页显示 `PRiSM+ 彩`。
  static String _versionLabel(Song song) => StringUtil.formatVersion2WithFlag(
        song.basicInfo.from,
        SongFilterUtil.isExtra(song),
      );

  Widget _buildBody(Brightness brightness) {
    final compare = _compare!;
    final songs = _currentSongs;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EntranceAnimation(
                    child: _buildFrontierCard(brightness, compare)),
                const SizedBox(height: AppDesignTokens.cardGap),
                _buildSectionChips(brightness, compare),
                const SizedBox(height: 10),
                _buildSectionHint(brightness, compare),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        if (songs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  context.l10n.flowNoSongsInThisSection,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.secondaryText(brightness)),
                ),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) => EntranceAnimation(
              // 换分段时重播
              key: ValueKey('${_section.name}-${songs[index].id}'),
              index: index,
              offset: const Offset(0, 8),
              duration: const Duration(milliseconds: 300),
              child: _buildSongRow(brightness, songs[index], index + 1),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// 前沿卡片：国服（水鱼）当前最新曲 + 三方计数 + 一句话口径。
  Widget _buildFrontierCard(Brightness brightness, UnionUpdateCompare compare) {
    final frontier = compare.frontier;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded,
                  size: 15, color: AppColors.warningOrange(brightness)),
              const SizedBox(width: 6),
              Text(
                context.l10n.flowChinaDivingFishUpdateFrontier,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (frontier != null)
            Text(
              '#${frontier.id}  ${frontier.basicInfo.title}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(brightness),
              ),
            ),
          if (frontier != null) ...[
            const SizedBox(height: 2),
            Text(
              context.l10n.flowJapanDebutP0P1(
                  (_formatDate(frontier.basicInfo.releaseDate)).toString(),
                  (_versionLabel(frontier)).toString()),
              style: TextStyle(
                  fontSize: 11.5, color: AppColors.secondaryText(brightness)),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Row(
              children: [
                _countCell(brightness, context.l10n.flowAllSongs,
                    '${compare.unionSongCount}'),
                _countCell(brightness, context.l10n.flowInChina,
                    '${compare.cnSongCount}'),
                _countCell(
                  brightness,
                  context.l10n.flowPendingRelease,
                  '${compare.upcoming.length}',
                  highlight: true,
                ),
                _countCell(brightness, context.l10n.flowNotIncluded,
                    '${compare.skipped.length}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.flowFirstReleaseMeansTheJapanReleaseDate,
            style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.secondaryText(brightness)),
          ),
          if (compare.earlyReleases.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.flowExcludedP0SongsReleasedEarlyInChina(
                  (compare.earlyReleases.length).toString(),
                  (compare.earlyReleases.map((s) => '#${s.id}').join(' '))
                      .toString()),
              style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.warningOrange(brightness)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countCell(Brightness brightness, String label, String value,
      {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.number(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.warningOrange(brightness)
                  : AppColors.primaryText(brightness),
            ),
          ),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, color: AppColors.secondaryText(brightness))),
        ],
      ),
    );
  }

  Widget _buildSectionChips(Brightness brightness, UnionUpdateCompare compare) {
    final chips = <(_Section, String, int)>[
      (
        _Section.upcoming,
        context.l10n.flowNextUpdateCandidates,
        compare.upcoming.length
      ),
      (
        _Section.skipped,
        context.l10n.flowOlderSongsMissingInChina,
        compare.skipped.length
      ),
      (_Section.utage, context.l10n.flowUTAGE, compare.utage.length),
      // 注意标签与顶部计数不同名：顶部「国服已上」含水鱼宴会（1394），
      // 这一段只有常规曲（不含宴会），同名会让人以为数字对不上。
      (_Section.cn, context.l10n.flowChinaRegularSongs, compare.cnSongs.length),
      (
        _Section.early,
        context.l10n.flowEarlyChinaReleases,
        compare.earlyReleases.length
      ),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (section, label, count) in chips)
          FilterPill(
            label: '$label $count',
            selected: _section == section,
            selectedColor: Theme.of(context).colorScheme.primary,
            selectedForeground: Theme.of(context).colorScheme.onPrimary,
            onTap: () => setState(() => _section = section),
          ),
      ],
    );
  }

  Widget _buildSectionHint(Brightness brightness, UnionUpdateCompare compare) {
    final String hint;
    switch (_section) {
      case _Section.upcoming:
        hint = compare.upcoming.isEmpty
            ? context.l10n.flowNoMissingRegularSongsInTheCurrent
            : context.l10n.flowSortedByIDNotReleaseOrderOfficial(
                (_versionSummary(compare)).toString());
      case _Section.skipped:
        hint = context.l10n.flowTheseSongsPredateTheReferenceStartOr;
      case _Section.utage:
        hint = context.l10n.flowUTAGEDoesNotFollowVersionUpdatesListed;
      case _Section.cn:
        hint = context.l10n.flowRegularDivingFishChinaSongsNewestDebut;
      case _Section.early:
        hint = context.l10n.flowTheseSongsReachedChinaBeforeJapanTheir;
    }
    return Text(
      hint,
      style: TextStyle(
          fontSize: 11,
          height: 1.45,
          color: AppColors.secondaryText(brightness)),
    );
  }

  String _versionSummary(UnionUpdateCompare compare) {
    final parts = compare.upcomingByVersion;
    if (parts.length <= 1) return '';
    return context.l10n.flowVersionsInvolvedP0((parts
            .map((e) => context.l10n.flowP0P1Songs(
                (StringUtil.formatVersion2WithFlag(e.version, true)).toString(),
                (e.count).toString()))
            .join(' · '))
        .toString());
  }

  Widget _buildSongRow(Brightness brightness, Song song, int order) {
    final isUpcoming = _section == _Section.upcoming;
    // 「国服已上」段按首发日期降序，第一行就是前沿 —— 这就是「在 union 全量源里
    // 标注出水鱼最新歌曲」的那一处标注。
    final isFrontierRow = _section == _Section.cn &&
        order == 1 &&
        song.id == _compare?.frontier?.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 8),
      child: AppCard(
        radius: AppDesignTokens.radiusMedium,
        padding: const EdgeInsets.all(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SongInfoPage(songId: song.id),
          ),
        ),
        child: Row(
          children: [
            if (isUpcoming || isFrontierRow)
              SizedBox(
                width: 24,
                child: isFrontierRow
                    ? Icon(Icons.flag_rounded,
                        size: 15, color: AppColors.warningOrange(brightness))
                    : Text(
                        '$order',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText(brightness),
                        ),
                      ),
              ),
            CoverUtil.buildCoverWidgetWithContextRRect(context, song.id, 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.basicInfo.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(brightness),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.flowP0P1JapanP2(
                        (song.id).toString(),
                        (_versionLabel(song)).toString(),
                        (_formatDate(song.basicInfo.releaseDate)).toString()),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText(brightness)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.greyHint(brightness)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return EmptyState(
      icon: Icons.inbox_rounded,
      title: context.l10n.flowNoCachedLibraryYet,
      message: context.l10n.flowThisPageUsesTheLocalDivingFish,
    );
  }

  void _showNotes() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: Text(context.l10n.flowHowThisPageWorks),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.flow1DataSources,
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                context.l10n.flowTheLocalLibraryCombinesDivingFishAll,
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(context.l10n.flow2DefiningTheUpdateFrontier,
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                context.l10n.flowRegularChinaSongsInDivingFishAre,
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(context.l10n.flow3CompletingTheCandidateList,
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                context.l10n.flowStartWithUnionOnlyRegularSongsUsing,
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(context.l10n.flow4WhatFirstReleaseMeans,
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                context.l10n.flowTheDebutDatesFromDivingFishAnd,
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.featureGotIt),
          ),
        ],
      ),
    );
  }

  /// "20260220" → "2026-02-20"；拿不到就显示 '-'（不猜）。
  static String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    if (raw.length == 8) {
      return '${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6, 8)}';
    }
    return raw;
  }
}
