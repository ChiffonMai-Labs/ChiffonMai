import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/widgets/NoRipple.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../entity/DivingFish/Song.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../service/Best50/CustomBest50Store.dart';
import '../../service/Best50/DiffBest50Service.dart';
import '../../service/Best50/PersonalizedBest50ConvertToImgService.dart';
import '../../service/SongSearchService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/ExportQualitySelector.dart';
import '../../utils/ImageEncodeUtil.dart';
import '../../utils/ScoreInputValidator.dart';
import '../../utils/SongFilterUtil.dart';
import '../../utils/StringUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';
import '../../widgets/AppDialogs.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';

/// 自定义 Best50 的一键排序方式。
enum _SortMode { raDesc, raAsc, dsDesc, dsAsc }

/// 自定义 Best50：手动录入最多 50 张成绩卡片（谱面可重复）。
///
/// 定数 / RA / 评级图 / 星数均由所选谱面与达成率自动计算。
/// 达成率可超过 101%、DX 分数可超过谱面上限（硬上限分别为 999.9999 / 9999），
/// 超上限的条目视为非法数据，在统计区与导出图片中以红字告警。
class CustomBest50Page extends StatefulWidget {
  const CustomBest50Page({super.key});

  @override
  State<CustomBest50Page> createState() => _CustomBest50PageState();
}

class _CustomBest50PageState extends State<CustomBest50Page> {
  // 硬上限（达成率 / DX 分数）与成绩历史的录入校验共用一份，见 ScoreInputValidator。
  static const double _achievementHardMax = achievementHardMax;
  static const int _dxScoreHardMax = dxScoreHardMax;

  final CustomBest50Store _store = CustomBest50Store();

  List<CustomBest50Entry?> _entries =
      List<CustomBest50Entry?>.filled(CustomBest50Store.slotCount, null);
  List<Song> _songs = [];
  List<dynamic> _maimaiMusicData = [];
  bool _isLoading = true;

  /// 一键排序后的排序状态标注；卡片发生变动时清除。
  String? _sortLabel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.load();
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? <Song>[];
    if (!mounted) return;
    setState(() {
      _entries = List<CustomBest50Entry?>.of(_store.entries);
      _songs = songs;
      _maimaiMusicData = songs.map((s) => s.toJson()).toList();
      _isLoading = false;
    });
  }

  // ───────────────────────── 数据工具 ─────────────────────────

  Song? _findSong(int songId) {
    for (final s in _songs) {
      if (s.id == songId.toString()) return s;
    }
    return null;
  }

  List<CustomBest50Entry> get _filledEntries =>
      _entries.whereType<CustomBest50Entry>().toList();

  double _effectiveDs(CustomBest50Entry e) {
    final song = _findSong(e.songId);
    if (song != null && e.levelIndex >= 0 && e.levelIndex < song.ds.length) {
      return song.ds[e.levelIndex];
    }
    return e.ds;
  }

  String _effectiveLevel(CustomBest50Entry e) {
    final song = _findSong(e.songId);
    if (song != null && e.levelIndex >= 0 && e.levelIndex < song.level.length) {
      return song.level[e.levelIndex];
    }
    return e.level;
  }

  String _effectiveType(CustomBest50Entry e) {
    final song = _findSong(e.songId);
    return song?.type ?? e.type;
  }

  String _effectiveTitle(CustomBest50Entry e) {
    final song = _findSong(e.songId);
    return song?.basicInfo.title ?? e.title;
  }

  int _singleMaxScore(Song? song, int levelIndex) {
    if (song == null) return 0;
    if (levelIndex < 0 || levelIndex >= song.charts.length) return 0;
    final notes = song.charts[levelIndex].notes;
    return notes.fold<int>(0, (sum, n) => sum + n) * 3;
  }

  /// 卡片显示用的当前难度满分（与 PersonalizedBest50Page 一致）。
  int _cardMaxScore(CustomBest50Entry e) =>
      _singleMaxScore(_findSong(e.songId), e.levelIndex);

  /// 判定/星数用的 DX 满分：宴会场（ds 长度 2）取两个难度之和。
  int _maxDxScore(CustomBest50Entry e) {
    final song = _findSong(e.songId);
    if (song == null) return 0;
    if (song.ds.length == 2) {
      return _singleMaxScore(song, 0) + _singleMaxScore(song, 1);
    }
    return _singleMaxScore(song, e.levelIndex);
  }

  int _raOf(CustomBest50Entry e) => DiffBest50Service()
      .calculateSingleRating(_effectiveDs(e), e.achievements);

  /// 达成率上限：普通曲 101%；宴会场（6 位 id）内部多张子谱相加，
  /// 上限 = 101 × 谱面数（2 个谱面即 202%）。
  ///
  /// ⚠️ 规则本体在 [maxAchievementFor]（`lib/utils/ScoreInputValidator.dart`）：
  /// 成绩历史的录入校验用的是同一份，别在这里另写一套。
  double _maxAchievementFor(Song? song) => maxAchievementFor(
        isUtage: song?.id.length == 6,
        chartCount: song?.ds.length ?? 1,
      );

  /// 非法数据：达成率超过谱面上限，或 DX 分数超过谱面上限。
  bool _isIllegal(CustomBest50Entry e) {
    if (e.achievements > _maxAchievementFor(_findSong(e.songId))) return true;
    final maxDx = _maxDxScore(e);
    return maxDx > 0 && e.dxScore > maxDx;
  }

  int get _illegalCount => _filledEntries.where(_isIllegal).length;

  String? get _warningText {
    final count = _illegalCount;
    if (count <= 0) return null;
    return context.l10n
        .flowP0InvalidEntriesAchievementOrDXScore((count).toString());
  }

  // ───────────────────────── 编辑弹窗 ─────────────────────────

  /// 选曲底部面板：搜索逻辑复用 SongSearchPage（歌名/ID/曲师/谱师/流派/版本/别名/BPM）。
  Future<Song?> _showSongPicker() async {
    var query = '';
    var results = <Song>[];
    var searching = false;
    Timer? debounce;

    try {
      return await showModalBottomSheet<Song>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final brightness = Theme.of(ctx).brightness;
            final scheme = Theme.of(ctx).colorScheme;
            final q = query.trim();
            final filtered = q.isEmpty ? _songs : results;

            Future<void> runSearch(String value) async {
              final r = await SongSearchService.searchSongs(value);
              if (!ctx.mounted || value != query) return;
              setSheetState(() {
                results = r;
                searching = false;
              });
            }

            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText:
                            context.l10n.featureTitleBPMCharterArtistAliasID,
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        debounce?.cancel();
                        setSheetState(() {
                          query = v;
                          searching = v.trim().isNotEmpty;
                          if (v.trim().isEmpty) results = [];
                        });
                        if (v.trim().isEmpty) return;
                        debounce = Timer(
                          const Duration(milliseconds: 500),
                          () => runSearch(v),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: searching
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  q.isEmpty
                                      ? context.l10n.flowNoSongData
                                      : context.l10n.flowNoMatchingSong,
                                  style:
                                      TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _buildPickerRow(
                                    ctx, filtered[i], brightness),
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      debounce?.cancel();
    }
  }

  Widget _buildPickerRow(BuildContext ctx, Song song, Brightness brightness) {
    final bool isUtage = song.id.length == 6;
    final String typeLabel = isUtage
        ? ChartDifficulty.utageLabel
        : (song.type == 'SD' ? 'ST' : 'DX');
    final Color typeColor = isUtage
        ? const Color(0xFFFF6B8B)
        : (song.type == 'SD'
            ? AppColors.linkBlue(brightness)
            : AppColors.warningOrange(brightness));

    const double nameFontSize = 16.0;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CoverUtil.buildCoverWidget(song.id, 44),
      ),
      title: Row(
        children: [
          Text(
            typeLabel,
            style: TextStyle(
              fontSize: nameFontSize,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              song.basicInfo.title,
              style: const TextStyle(fontSize: nameFontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        // extra 曲目（宴会场 / maidata 追加 / union 独有）没有国服世代年号
        '${song.basicInfo.artist} · '
        '${StringUtil.formatVersion2WithFlag(song.basicInfo.from, SongFilterUtil.isExtra(song))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.pop(ctx, song),
    );
  }

  Future<void> _showEditSheet(int index) async {
    final existing = _entries[index];

    Song? song = existing != null ? _findSong(existing.songId) : null;
    int levelIndex = existing?.levelIndex ?? 3;
    double? achievements = existing?.achievements;
    int? dxScore = existing?.dxScore;
    String fc = existing?.fc ?? '';
    String fs = existing?.fs ?? '';
    String? saveError;
    // 谱面在曲库中找不到时，用已保存的快照兜底
    final String snapshotTitle = existing?.title ?? '';
    final double snapshotDs = existing?.ds ?? 0.0;
    final String snapshotLevel = existing?.level ?? '';
    final String snapshotType = existing?.type ?? '';

    String effectiveTitle() => song?.basicInfo.title ?? snapshotTitle;

    String effectiveLevel() {
      if (song != null && levelIndex < song!.level.length) {
        return song!.level[levelIndex];
      }
      return snapshotLevel;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final scheme = Theme.of(ctx).colorScheme;
          final ds = song != null
              ? (levelIndex < song!.ds.length ? song!.ds[levelIndex] : 0.0)
              : snapshotDs;
          final int maxDx = (song != null && song!.ds.length == 2)
              ? _singleMaxScore(song, 0) + _singleMaxScore(song, 1)
              : _singleMaxScore(song, levelIndex);
          final double maxAchievement = _maxAchievementFor(song);
          final achievementIllegal =
              achievements != null && achievements! > maxAchievement;
          final dxIllegal = dxScore != null && maxDx > 0 && dxScore! > maxDx;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.flowSlotP0((index + 1).toString()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 歌曲
                  InkWell(
                    onTap: () async {
                      final picked = await _showSongPicker();
                      if (picked == null || !sheetCtx.mounted) return;
                      setSheetState(() {
                        song = picked;
                        saveError = null;
                        // 新曲目默认 Master（第 4 个难度），不足则取最高难度
                        levelIndex = picked.charts.length > 3 ? 3 : 0;
                        if (levelIndex >= picked.ds.length) levelIndex = 0;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outline),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          // 已选歌曲曲绘
                          if (song != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: CoverUtil.buildCoverWidget(song!.id, 40),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Icon(Icons.music_note,
                                  size: 22, color: scheme.onSurfaceVariant),
                            ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(context.l10n.featureSongs,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant)),
                                Text(
                                  effectiveTitle().isEmpty
                                      ? context.l10n.flowNotSelected
                                      : effectiveTitle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 16, color: scheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 难度
                  if (song != null) ...[
                    Text(context.l10n.flowDifficulty,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < song!.charts.length; i++)
                          NoRipple(
                            child: ChoiceChip(
                              label: Text(_difficultyName(i)),
                              selected: levelIndex == i,
                              onSelected: (_) =>
                                  setSheetState(() => levelIndex = i),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.flowP0P1ConstantP2(
                          (_difficultyName(levelIndex)).toString(),
                          (effectiveLevel().isEmpty ? '?' : effectiveLevel())
                              .toString(),
                          (ds.toStringAsFixed(1)).toString()),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(context.l10n.flowSelectASongFirst,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                  ],

                  // 达成率 / DX 分数
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _NumberInputField(
                          label: context.l10n.flowAchievement,
                          hint: context.l10n.flowEG1005,
                          initial: existing?.achievements.toString(),
                          hardMax: _achievementHardMax,
                          helperText: context.l10n.flowMaximumP0(
                              (maxAchievement.toStringAsFixed(0)).toString()),
                          onChanged: (v) => setSheetState(() {
                            achievements = v;
                            saveError = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberInputField(
                          label: context.l10n.flowDXScore,
                          hint: context.l10n.flowEG3000,
                          initial: existing?.dxScore.toString(),
                          hardMax: _dxScoreHardMax.toDouble(),
                          helperText: maxDx > 0
                              ? context.l10n.flowMaximumP02((maxDx).toString())
                              : null,
                          onChanged: (v) => setSheetState(() {
                            dxScore = v?.round();
                            saveError = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (achievementIllegal)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        context.l10n.flowInvalidAchievementExceedsP0(
                            (maxAchievement.toStringAsFixed(0)).toString()),
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.error,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (dxIllegal)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        context.l10n.flowInvalidDXScoreExceedsTheChartMaximum(
                            (maxDx).toString()),
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.error,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // FC / FS
                  _buildChoiceRow(
                    ctx,
                    label: context.l10n.flowCombo,
                    options: const ['', 'fc', 'fcp', 'ap', 'app'],
                    current: fc,
                    labelOf: (v) => v.isEmpty
                        ? context.l10n.flowNone2
                        : StringUtil.formatFC(v),
                    onPick: (v) => setSheetState(() => fc = v),
                  ),
                  const SizedBox(height: 8),
                  _buildChoiceRow(
                    ctx,
                    label: context.l10n.flowSync,
                    options: const ['', 'fs', 'fsp', 'fsd', 'fsdp', 'sync'],
                    current: fs,
                    labelOf: (v) => v.isEmpty
                        ? context.l10n.flowNone2
                        : (v == 'sync' ? 'SYNC' : StringUtil.formatFS(v)),
                    onPick: (v) => setSheetState(() => fs = v),
                  ),
                  const SizedBox(height: 12),

                  // RA 预览
                  if (achievements != null && ds > 0)
                    Text(
                      'RA：${DiffBest50Service().calculateSingleRating(ds, achievements!)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 12),

                  if (saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        saveError!,
                        style: TextStyle(
                          color: scheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // 动作按钮
                  Row(
                    children: [
                      if (existing != null)
                        TextButton(
                          onPressed: () async {
                            await _store.setEntry(index, null);
                            if (!mounted) return;
                            setState(() {
                              _entries =
                                  List<CustomBest50Entry?>.of(_store.entries);
                              _sortLabel = null;
                            });
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          },
                          child: Text(context.l10n.flowClearThisCard,
                              style: TextStyle(color: scheme.error)),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(context.l10n.featureCancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          if (song == null && snapshotTitle.isEmpty) {
                            setSheetState(() =>
                                saveError = context.l10n.flowSelectASongFirst);
                            return;
                          }
                          if (achievements == null) {
                            setSheetState(() =>
                                saveError = context.l10n.flowEnterAchievement);
                            return;
                          }
                          final entry = CustomBest50Entry(
                            songId: song != null
                                ? int.tryParse(song!.id) ?? 0
                                : existing?.songId ?? 0,
                            title: effectiveTitle(),
                            type: song?.type ?? snapshotType,
                            levelIndex: levelIndex,
                            level: effectiveLevel(),
                            ds: ds,
                            achievements: achievements!,
                            dxScore: dxScore ?? 0,
                            fc: fc,
                            fs: fs,
                          );
                          await _store.setEntry(index, entry);
                          if (!mounted) return;
                          setState(() {
                            _entries =
                                List<CustomBest50Entry?>.of(_store.entries);
                            _sortLabel = null;
                          });
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        },
                        child: Text(context.l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChoiceRow(
    BuildContext ctx, {
    required String label,
    required List<String> options,
    required String current,
    required String Function(String) labelOf,
    required ValueChanged<String> onPick,
  }) {
    final scheme = Theme.of(ctx).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in options)
                NoRipple(
                  child: ChoiceChip(
                    label: Text(labelOf(v)),
                    selected: current == v,
                    onSelected: (_) => onPick(v),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _difficultyName(int index) {
    const names = ChartDifficulty.standardLabels;
    if (index < 0 || index >= names.length)
      return appL10n.flowDifficultyP03((index).toString());
    return names[index];
  }

  // ───────────────────────── 一键排序 ─────────────────────────

  static String _sortLabelOf(_SortMode mode) {
    switch (mode) {
      case _SortMode.raDesc:
        return appL10n.flowRADescending;
      case _SortMode.raAsc:
        return appL10n.flowRAAscending;
      case _SortMode.dsDesc:
        return appL10n.flowConstantDescending;
      case _SortMode.dsAsc:
        return appL10n.flowConstantAscending;
    }
  }

  static IconData _sortIconOf(_SortMode mode) {
    switch (mode) {
      case _SortMode.raDesc:
      case _SortMode.dsDesc:
        return Icons.arrow_downward_rounded;
      case _SortMode.raAsc:
      case _SortMode.dsAsc:
        return Icons.arrow_upward_rounded;
    }
  }

  Future<void> _showSortDialog() async {
    if (_filledEntries.isEmpty) {
      _showMessage(
          context.l10n.featureNotice, context.l10n.flowNoCardsFilledInYet);
      return;
    }
    final mode = await showModalBottomSheet<_SortMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in _SortMode.values)
              ListTile(
                leading: Icon(_sortIconOf(m)),
                title:
                    Text(context.l10n.flowByP0((_sortLabelOf(m)).toString())),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (mode == null) return;
    await _applySort(mode);
  }

  Future<void> _applySort(_SortMode mode) async {
    final filled = _filledEntries;
    if (filled.isEmpty) return;

    int compare(CustomBest50Entry a, CustomBest50Entry b) {
      switch (mode) {
        case _SortMode.raDesc:
          final c = _raOf(b).compareTo(_raOf(a));
          return c != 0 ? c : _effectiveDs(b).compareTo(_effectiveDs(a));
        case _SortMode.raAsc:
          final c = _raOf(a).compareTo(_raOf(b));
          return c != 0 ? c : _effectiveDs(a).compareTo(_effectiveDs(b));
        case _SortMode.dsDesc:
          final c = _effectiveDs(b).compareTo(_effectiveDs(a));
          return c != 0 ? c : _raOf(b).compareTo(_raOf(a));
        case _SortMode.dsAsc:
          final c = _effectiveDs(a).compareTo(_effectiveDs(b));
          return c != 0 ? c : _raOf(a).compareTo(_raOf(b));
      }
    }

    filled.sort(compare);

    final newEntries =
        List<CustomBest50Entry?>.filled(CustomBest50Store.slotCount, null);
    for (int i = 0; i < filled.length; i++) {
      newEntries[i] = filled[i];
    }
    await _store.setEntries(newEntries);
    if (!mounted) return;
    setState(() {
      _entries = List<CustomBest50Entry?>.of(_store.entries);
      _sortLabel = _sortLabelOf(mode);
    });
  }

  // ───────────────────────── 导出 ─────────────────────────

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final storage = await Permission.storage.status;
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      if (storage.isGranted || photos.isGranted || videos.isGranted) {
        return true;
      }
      final statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();
      return (statuses[Permission.storage]?.isGranted ?? false) ||
          (statuses[Permission.photos]?.isGranted ?? false) ||
          (statuses[Permission.videos]?.isGranted ?? false);
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  List<Map<String, dynamic>> _buildExportMaps() {
    final maps = <Map<String, dynamic>>[];
    for (final e in _filledEntries) {
      final ds = _effectiveDs(e);
      maps.add({
        'song_id': e.songId,
        'title': _effectiveTitle(e),
        'type': _effectiveType(e),
        'level_index': e.levelIndex,
        'level': _effectiveLevel(e),
        'ds': ds,
        'achievements': e.achievements,
        'dxScore': e.dxScore,
        'fc': e.fc,
        'fs': e.fs,
        'rate': StringUtil.rateCodeFromAchievement(e.achievements),
        'ra': _raOf(e),
      });
    }
    return maps;
  }

  Future<void> _exportToImage() async {
    if (_filledEntries.isEmpty) {
      _showMessage(context.l10n.featureNotice, context.l10n.flowNoDataToExport);
      return;
    }

    final hasPermission = await _requestStoragePermission();
    if (!mounted) return;
    if (!hasPermission) {
      _showMessage(context.l10n.flowPermissionRequired,
          context.l10n.flowStoragePermissionIsRequiredToExportImages);
      return;
    }

    final quality = await ExportQualitySelector.show(
      context,
      estimatedPngSize: ImageEncodeUtil.estimatePngSize(
        songCount: _filledEntries.length,
      ),
      exportingLabel: context.l10n.featureCreateBest50,
      enableThunderMode: true,
      previewBuilder: (previewContext, previewQuality) =>
          PersonalizedB50ConvertToImg.buildPreviewWidget(
        previewContext,
        context.l10n.featureCreateBest50,
        _buildExportMaps(),
        _maimaiMusicData,
        _warningText,
        _sortLabel,
        thunderMode: previewQuality.thunderMode,
        thunderVertical: previewQuality.thunderVertical,
        theme: previewQuality.theme,
      ),
    );
    if (!mounted || quality == null) return;

    BackgroundExport.run(
      label: context.l10n.featureCreateBest50,
      task: (exportContext) => PersonalizedB50ConvertToImg.convertToImage(
        exportContext,
        context.l10n.featureCreateBest50,
        _buildExportMaps(),
        _maimaiMusicData,
        jpegQuality: quality.jpegQuality,
        theme: quality.theme,
        warningText: _warningText,
        sortLabel: _sortLabel,
        thunderMode: quality.thunderMode,
        thunderVertical: quality.thunderVertical,
      ),
    );
  }

  void _showMessage(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AppAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.featureOK),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    if (_filledEntries.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppAlertDialog(
        title: Text(context.l10n.flowClearAll),
        content: Text(context.l10n.flowClearAll50SlotsThisCannotBe),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.featureClear,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.clearAll();
    if (!mounted) return;
    setState(() {
      _entries = List<CustomBest50Entry?>.of(_store.entries);
      _sortLabel = null;
    });
  }

  // ───────────────────────── 构建 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BackgroundPageScaffold(
        title: context.l10n.featureCreateBest50,
        resizeToAvoidBottomInset: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BackgroundPageScaffold(
      title: context.l10n.featureCreateBest50,
      resizeToAvoidBottomInset: false,
      actionsEndInset: 4,
      actions: [
        Best50IconAction(
          tooltip: context.l10n.flowExportAsImage,
          icon: Icons.image_outlined,
          onPressed: _exportToImage,
        ),
      ],
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 12.0),
            _buildActionButtons(),
            const SizedBox(height: 12.0),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final filled = _filledEntries;
    final int totalSongs = filled.length;
    final int totalRa = filled.fold<int>(0, (sum, e) => sum + _raOf(e));
    final double averageRa = totalSongs > 0 ? totalRa / totalSongs : 0.0;
    final double totalAchievement =
        filled.fold<double>(0.0, (sum, e) => sum + e.achievements);
    final double averageAchievement =
        totalSongs > 0 ? totalAchievement / totalSongs : 0.0;
    final warning = _warningText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Best50Hero(total: totalRa, label: context.l10n.flowCustomBest50TotalRA),
        const SizedBox(height: AppDesignTokens.cardGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statColumn(context.l10n.flowFilled,
                      '$totalSongs / ${CustomBest50Store.slotCount}'),
                  _statColumn(
                      context.l10n.flowAverageRA, averageRa.toStringAsFixed(1)),
                  _statColumn(context.l10n.featureAverageAchievement,
                      '${averageAchievement.toStringAsFixed(2)}%'),
                ],
              ),
              if (_sortLabel != null) ...[
                const SizedBox(height: 8.0),
                Text(
                  context.l10n.flowCurrentOrderP0ClearedWhenCardsChange(
                      (_sortLabel).toString()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (warning != null) ...[
                const SizedBox(height: 10.0),
                Text(
                  warning,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statColumn(String label, String value) =>
      Expanded(child: StatTile(label: label, value: value));

  Widget _buildActionButtons() {
    final error = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Expanded(
          child: Best50ActionButton(
            icon: Icons.sort_rounded,
            label: context.l10n.flowAutoSort,
            onPressed: _showSortDialog,
          ),
        ),
        const SizedBox(width: AppDesignTokens.itemGap),
        TextButton.icon(
          onPressed: _confirmClearAll,
          icon: Icon(Icons.delete_outline, color: error, size: 18),
          label:
              Text(context.l10n.flowClearAll, style: TextStyle(color: error)),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return ValueListenableBuilder<Best50DisplayMode>(
      valueListenable: Best50DisplayPreference.instance,
      builder: (context, mode, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Best50DisplayModeBar(),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              key: ValueKey(mode),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: Best50Grid.delegate(context, constraints.maxWidth,
                  mode: mode),
              itemCount: CustomBest50Store.slotCount,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                if (entry == null) return _buildEmptySlot(index);
                return _buildEntryCard(entry, index, mode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: EdgeInsets.zero,
      color: AppSurfaces.card(context).withValues(alpha: 0.7),
      outlined: true,
      onTap: () => _showEditSheet(index),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 28, color: scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(context.l10n.flowTapToFillIn,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
      CustomBest50Entry entry, int index, Best50DisplayMode mode) {
    final maxDx = _maxDxScore(entry);
    final scoreRate = maxDx > 0 ? entry.dxScore / maxDx : 0.0;
    // 非法条目：红色描边便于定位（统计区 / 导出图另有红字告警）
    final outlineColor =
        _isIllegal(entry) ? Theme.of(context).colorScheme.error : null;
    final data = Best50CardData(
      songId: entry.songId,
      title: _effectiveTitle(entry),
      levelIndex: entry.levelIndex,
      type: _effectiveType(entry),
      rating: _raOf(entry),
      ds: _effectiveDs(entry),
      achievement: entry.achievements,
      fc: entry.fc,
      fs: entry.fs,
      stars: StringUtil.formatStars(scoreRate),
      dxScore: entry.dxScore,
      maxDxScore: _cardMaxScore(entry),
      onOpenSong: () => _showEditSheet(index),
    );
    // 点卡片是编辑这一格，不走详情面板。
    return mode == Best50DisplayMode.cover
        ? Best50CoverCard(
            rank: index + 1,
            entranceIndex: index,
            onTap: () => _showEditSheet(index),
            outlineColor: outlineColor,
            data: data,
          )
        : mode == Best50DisplayMode.twoColumns
            ? Best50ScoreCard(
                rank: index + 1,
                entranceIndex: index,
                onTap: () => _showEditSheet(index),
                outlineColor: outlineColor,
                data: data,
              )
            : Best50StripCard(
                rank: index + 1,
                entranceIndex: index,
                onTap: () => _showEditSheet(index),
                outlineColor: outlineColor,
                data: data,
              );
  }
}

/// 带硬上限校验的数字输入框。
///
/// 超过 [hardMax] 直接拒绝输入并提示；解析成功的值通过 [onChanged] 回传。
/// 是否属于"非法数据"（如达成率 > 101%）由调用方判断并另行提示。
class _NumberInputField extends StatefulWidget {
  final String label;
  final String hint;
  final String? initial;
  final double hardMax;
  final String? helperText;
  final ValueChanged<double?> onChanged;

  const _NumberInputField({
    required this.label,
    required this.hint,
    required this.initial,
    required this.hardMax,
    required this.onChanged,
    this.helperText,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      setState(() => _error = null);
      widget.onChanged(null);
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      setState(() => _error = context.l10n.flowEnterANumber);
      return;
    }
    if (v < 0) {
      setState(() => _error = context.l10n.flowCannotBeNegative);
      return;
    }
    if (v > widget.hardMax) {
      setState(() => _error = context.l10n
          .flowMustNotExceedP0((_formatMax(widget.hardMax)).toString()));
      return;
    }
    setState(() => _error = null);
    widget.onChanged(v);
  }

  static String _formatMax(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTheme.font(fontSize: 12),
        floatingLabelStyle: AppTheme.font(fontSize: 12),
        hintText: widget.hint,
        helperText: widget.helperText,
        helperMaxLines: 3,
        helperStyle: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        errorText: _error,
        errorMaxLines: 3,
        errorStyle: const TextStyle(fontSize: 11),
        isDense: true,
      ).insetLabel(context),
      onChanged: _handleChanged,
    );
  }
}
