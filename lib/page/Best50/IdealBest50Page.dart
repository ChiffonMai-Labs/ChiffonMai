import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../../utils/ChartDifficulty.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../entity/DivingFish/Song.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../service/Account/AccountStore.dart';
import '../../service/Best50/Best50ConvertToImgService.dart';
import '../../service/Best50/IdealBest50Service.dart';
import '../../utils/Best50Order.dart';
import '../../utils/Best50Tie.dart';
import '../../utils/ExportQualitySelector.dart';
import '../../utils/ImageEncodeUtil.dart';
import '../../utils/StringUtil.dart';
import '../song_info/SongInfoPage.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';
import '../../widgets/AppDialogs.dart';
import 'package:my_first_flutter_app/service/System/BackgroundExportService.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
/// 理想 Best50：把全部游玩记录里非 SSS+ 的成绩升一档（100.4 → 100.5），
/// 重算 RA 后重新取 B35 + B15，并列出相对原榜的新进榜歌曲。
class IdealBest50Page extends StatefulWidget {
  const IdealBest50Page({super.key});

  @override
  State<IdealBest50Page> createState() => _IdealBest50PageState();
}

class _IdealBest50PageState extends State<IdealBest50Page> {
  int _segment = 0; // 0 = B35，1 = B15
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _sdSongs = [];
  List<Map<String, dynamic>> _dxSongs = [];
  List<Map<String, dynamic>> _newEntries = [];
  Map<String, Song> _songIndex = {};
  List<dynamic> _maimaiMusicData = [];
  String _accountKey = '';
  int _resultVersion = 0;
  Best50TiePool<Map<String, dynamic>>? _sdTiePool;
  Best50TiePool<Map<String, dynamic>>? _dxTiePool;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await IdealBest50Service().calculate();
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? <Song>[];
    final accountKey = await AccountStore.accountKey();
    final sdSaved = await Best50TieSelectionStore.load(accountKey, 'ideal_sd');
    final dxSaved = await Best50TieSelectionStore.load(accountKey, 'ideal_dx');
    if (!mounted) return;

    final songIndex = {for (final s in songs) s.id: s};
    Best50TiePool<Map<String, dynamic>>? sdPool;
    Best50TiePool<Map<String, dynamic>>? dxPool;
    var sdSongs = <Map<String, dynamic>>[];
    var dxSongs = <Map<String, dynamic>>[];
    var newEntries = <Map<String, dynamic>>[];

    if (data != null) {
      sdPool = Best50TiePool<Map<String, dynamic>>.fromSplit(
        defaultShown: [
          for (final m in data['sd'] as List)
            Map<String, dynamic>.from(m as Map),
        ],
        defaultRemaining: [
          for (final m in (data['sdRemaining'] as List?) ?? const [])
            Map<String, dynamic>.from(m as Map),
        ],
        tieValueOf: (item) => (item['ra'] as num?)?.toInt() ?? 0,
        keyOf: best50MapChartKey,
        savedKeys: sdSaved,
      );
      dxPool = Best50TiePool<Map<String, dynamic>>.fromSplit(
        defaultShown: [
          for (final m in data['dx'] as List)
            Map<String, dynamic>.from(m as Map),
        ],
        defaultRemaining: [
          for (final m in (data['dxRemaining'] as List?) ?? const [])
            Map<String, dynamic>.from(m as Map),
        ],
        tieValueOf: (item) => (item['ra'] as num?)?.toInt() ?? 0,
        keyOf: best50MapChartKey,
        savedKeys: dxSaved,
      );
      sdSongs = sdPool.shown;
      dxSongs = dxPool.shown;
      newEntries = _recomputeNewEntries(
        data,
        sdSongs,
        dxSongs,
        songIndex.values,
      );
    }

    setState(() {
      _accountKey = accountKey;
      _data = data;
      _sdTiePool = sdPool;
      _dxTiePool = dxPool;
      _sdSongs = sdSongs;
      _dxSongs = dxSongs;
      _newEntries = newEntries;
      _songIndex = songIndex;
      _maimaiMusicData = songs.map((s) => s.toJson()).toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _recomputeNewEntries(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> sdSongs,
    List<Map<String, dynamic>> dxSongs,
    Iterable<Song> songs,
  ) {
    final origKeysRaw = data['origKeys'];
    if (origKeysRaw is! List) {
      return List<Map<String, dynamic>>.from(
          (data['newEntries'] as List?) ?? const []);
    }
    final origKeys = {for (final k in origKeysRaw) k.toString()};
    final origRaRaw = data['origRaByKey'];
    final origRaByKey = origRaRaw is Map
        ? {
            for (final e in origRaRaw.entries)
              e.key.toString(): (e.value as num?)?.toInt() ?? 0,
          }
        : const <String, int>{};
    final order = Best50Order.fromSongs(songs);
    final idealEntries = [...sdSongs, ...dxSongs]..sort(order.compareMaps);
    return [
      for (final m in idealEntries)
        if (!origKeys.contains(best50MapChartKey(m)))
          {
            'title': m['title'] ?? '未知歌曲',
            'ds': m['ds'] ?? 0,
            'level_index': m['level_index'] ?? 0,
            'oldRa': origRaByKey[best50MapChartKey(m)] ?? 0,
            'newRa': m['ra'] ?? 0,
          },
    ];
  }

  Future<void> _pickTiesForSegment(int segment) async {
    final pool = segment == 0 ? _sdTiePool : _dxTiePool;
    if (pool == null || !pool.hasTies || pool.shown.isEmpty) return;
    final label = 'RA ${pool.shown.last['ra']}';
    final segTitle = segment == 0 ? 'B35' : 'B15';
    final chosen = await showBest50TieSelectionDialog(
      context,
      candidates: [for (final c in pool.candidates) _cardData(c)],
      candidateKeys: [for (final c in pool.candidates) best50MapChartKey(c)],
      initialSelectedKeys: pool.selectedKeys,
      defaultKeys: pool.defaultKeys,
      slotCount: pool.slotCount,
      label: label,
      segmentTitle: segTitle,
    );
    if (chosen == null || !mounted) return;
    final updated = pool.withSelection(chosen);
    final accountKey =
        _accountKey.isNotEmpty ? _accountKey : await AccountStore.accountKey();
    await Best50TieSelectionStore.saveOrClear(
      accountKey,
      segment == 0 ? 'ideal_sd' : 'ideal_dx',
      updated,
    );
    if (!mounted) return;
    final nextSd = segment == 0 ? updated.shown : _sdSongs;
    final nextDx = segment == 1 ? updated.shown : _dxSongs;
    setState(() {
      _accountKey = accountKey;
      if (segment == 0) {
        _sdTiePool = updated;
        _sdSongs = nextSd;
      } else {
        _dxTiePool = updated;
        _dxSongs = nextDx;
      }
      if (_data != null) {
        _newEntries = _recomputeNewEntries(
          _data!,
          nextSd,
          nextDx,
          _songIndex.values,
        );
      }
      _resultVersion++;
    });
  }

  // ───────────────────────── 卡片计算 ─────────────────────────

  Song? _songOf(Map<String, dynamic> m) =>
      _songIndex[(m['song_id'] ?? 0).toString()];

  int _singleMaxScore(Song? song, int levelIndex) {
    if (song == null) return 0;
    if (levelIndex < 0 || levelIndex >= song.charts.length) return 0;
    final notes = song.charts[levelIndex].notes;
    return notes.fold<int>(0, (sum, n) => sum + n) * 3;
  }

  int _cardMaxScore(Map<String, dynamic> m) =>
      _singleMaxScore(_songOf(m), (m['level_index'] ?? 0) as int);

  int _maxDxScore(Map<String, dynamic> m) {
    final song = _songOf(m);
    if (song == null) return 0;
    if (song.ds.length == 2) {
      return _singleMaxScore(song, 0) + _singleMaxScore(song, 1);
    }
    return _singleMaxScore(song, (m['level_index'] ?? 0) as int);
  }

  // ───────────────────────── 导出 ─────────────────────────

  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) return true; // 写入相册时由 PhotoKit 请求权限。

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

  Future<void> _exportToImage() async {
    if (_data == null || _sdSongs.isEmpty && _dxSongs.isEmpty) {
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

    final title = context.l10n.featureIdealBest50;
    final quality = await ExportQualitySelector.show(
      context,
      estimatedPngSize: ImageEncodeUtil.estimatePngSize(
        songCount: _sdSongs.length + _dxSongs.length,
      ),
      exportingLabel: title,
      enableThunderMode: true,
      enableBest50Background: true,
      extraSectionBuilder: (sheetContext, setSheetState) {
        final items = <Best50ExportTieItem>[
          if (_sdTiePool != null &&
              _sdTiePool!.hasTies &&
              _sdTiePool!.shown.isNotEmpty)
            Best50ExportTieItem(
              segment: 'B35',
              label: 'RA ${_sdTiePool!.shown.last['ra']}',
              selectedCount: _sdTiePool!.slotCount,
              totalCount: _sdTiePool!.candidates.length,
              customized: _sdTiePool!.isCustomized,
              onTap: () => _pickTiesForSegment(0),
            ),
          if (_dxTiePool != null &&
              _dxTiePool!.hasTies &&
              _dxTiePool!.shown.isNotEmpty)
            Best50ExportTieItem(
              segment: 'B15',
              label: 'RA ${_dxTiePool!.shown.last['ra']}',
              selectedCount: _dxTiePool!.slotCount,
              totalCount: _dxTiePool!.candidates.length,
              customized: _dxTiePool!.isCustomized,
              onTap: () => _pickTiesForSegment(1),
            ),
        ];
        return Best50ExportTieSection(
          items: items,
          onUpdated: () => setSheetState(() {}),
        );
      },
      previewBuilder: (previewContext, previewQuality) =>
          B50ConvertToImg.buildPreviewWidget(
        previewContext,
        {
          'rating': _data!['rating'],
          'additional_rating': 0,
          'charts': {'sd': _sdSongs, 'dx': _dxSongs},
        },
        _sdSongs,
        _dxSongs,
        _maimaiMusicData,
        title: title,
        thunderMode: previewQuality.thunderMode,
        thunderVertical: previewQuality.thunderVertical,
        theme: previewQuality.theme,
        background: previewQuality.background,
      ),
    );
    if (!mounted || quality == null) return;

    final b50Data = {
      'rating': _data!['rating'],
      'additional_rating': 0,
      'charts': {'sd': _sdSongs, 'dx': _dxSongs},
    };
    BackgroundExport.run(
      label: title,
      task: (exportContext) => B50ConvertToImg.convertToImage(
        exportContext,
        b50Data,
        _sdSongs,
        _dxSongs,
        _maimaiMusicData,
        title: title,
        jpegQuality: quality.jpegQuality,
        theme: quality.theme,
        background: quality.background,
        thunderMode: quality.thunderMode,
        thunderVertical: quality.thunderVertical,
      ),
    );
  }

  // ───────────────────────── 构建 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BackgroundPageScaffold(
        title: context.l10n.featureIdealBest50,
        resizeToAvoidBottomInset: false,
        child: Center(child: ExpressiveLoadingIndicator.contained(size: 48)),
      );
    }

    return BackgroundPageScaffold(
      title: context.l10n.featureIdealBest50,
      resizeToAvoidBottomInset: false,
      actionsEndInset: 4,
      actions: [
        if (_data != null) ...[
          Best50IconAction(
            tooltip: context.l10n.flowExportAsImage,
            icon: Icons.image_outlined,
            onPressed: _exportToImage,
          ),
        ],
      ],
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: _data == null ? _buildEmptyState() : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined,
                size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              context.l10n.flowNoCachedPlayData,
              style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.flowReturnHomeAndTapRefreshData,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final songs = _segment == 0 ? _sdSongs : _dxSongs;
    int sumOf(List<Map<String, dynamic>> list) =>
        list.fold<int>(0, (sum, m) => sum + ((m['ra'] ?? 0) as int));
    final activePool = _segment == 0 ? _sdTiePool : _dxTiePool;
    final remainingRaw = activePool != null && activePool.hasTies
        ? activePool.remaining
        : (_data?[_segment == 0 ? 'sdRemaining' : 'dxRemaining'] as List?) ??
            const [];
    return ValueListenableBuilder<Best50DisplayMode>(
      valueListenable: Best50DisplayPreference.instance,
      builder: (context, mode, _) => CustomScrollView(
        cacheExtent: 600,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
                AppDesignTokens.gutter, AppDesignTokens.gutter + 8),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatsSection(),
                      const SizedBox(height: AppDesignTokens.cardGap),
                      _buildNewEntriesSection(),
                      const SizedBox(height: AppDesignTokens.cardGap),
                      SegmentedTabs(
                        inlineCaption: true,
                        items: [
                          SegmentedTabItem('B35',
                              caption: '${sumOf(_sdSongs)}'),
                          SegmentedTabItem('B15',
                              caption: '${sumOf(_dxSongs)}'),
                        ],
                        selectedIndex: _segment,
                        onChanged: (i) => setState(() => _segment = i),
                      ),
                      const SizedBox(height: 8),
                      Best50MetaLine(best50MetaText(
                          _segment == 0
                              ? context.l10n.flowOlderVersions
                              : context.l10n.flowCurrentVersion,
                          songs.map((m) => (m['ra'] ?? 0) as int))),
                      const SizedBox(height: AppDesignTokens.cardGap),
                    ],
                  ),
                ),
                if (songs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(context.l10n.flowNoData2,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ),
                    ),
                  )
                else
                  ...Best50Grid.buildSlivers(
                    context: context,
                    mode: mode,
                    contentKey: '$_segment-$_resultVersion',
                    items: [for (final m in songs) _cardData(m)],
                    remaining: [
                      for (final m in remainingRaw)
                        _cardData(Map<String, dynamic>.from(m as Map))
                    ],
                    remainingLabel: 'RA ${songs.last['ra']}',
                    onSelectTies: activePool != null && activePool.hasTies
                        ? () => _pickTiesForSegment(_segment)
                        : null,
                    tieSelectedCount: activePool?.slotCount,
                    tieTotalCount: activePool?.candidates.length,
                    tieCustomized: activePool?.isCustomized ?? false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final originalRating = (_data!['originalRating'] ?? 0) as int;
    final idealRating = (_data!['rating'] ?? 0) as int;
    final delta = idealRating - originalRating;
    final all = [..._sdSongs, ..._dxSongs];
    final avgAchievement = all.isEmpty
        ? 0.0
        : all.fold<double>(
                0.0,
                (sum, m) =>
                    sum +
                    (double.tryParse(m['achievements'].toString()) ?? 0.0)) /
            all.length;

    int sumOf(List<Map<String, dynamic>> list) =>
        list.fold<int>(0, (sum, m) => sum + ((m['ra'] ?? 0) as int));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Best50Hero(
          total: idealRating,
          label: context.l10n.flowIdealRatingRaiseNonSSSScoresTo,
          delta: delta,
          best35Sum: sumOf(_sdSongs),
          best15Sum: sumOf(_dxSongs),
        ),
        const SizedBox(height: AppDesignTokens.cardGap),
        AppCard(
          child: Row(
            children: [
              Expanded(
                  child: StatTile(
                      label: context.l10n.flowOriginalRating,
                      value: '$originalRating')),
              Expanded(
                  child: StatTile(
                      label: context.l10n.flowNewEntries,
                      value: '${_newEntries.length}')),
              Expanded(
                  child: StatTile(
                      label: context.l10n.featureAverageAchievement,
                      value: '${avgAchievement.toStringAsFixed(2)}%')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewEntriesSection() {
    final scheme = Theme.of(context).colorScheme;
    return CollapsibleCard(
      title: context.l10n
          .flowNewEntriesThisTimeP0Songs((_newEntries.length).toString()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _newEntries.isEmpty
            ? Text(
                context.l10n.flowNoNewEntriesTheSameChartsRemain,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in _newEntries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e['title']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.l10n.flowConstantP0RAP1P2(
                                ((e['ds'] as num).toStringAsFixed(1))
                                    .toString(),
                                (e['oldRa']).toString(),
                                (e['newRa']).toString()),
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Best50CardData _cardData(Map<String, dynamic> m) {
    final songId = (m['song_id'] ?? 0) as int;
    final levelIndex = (m['level_index'] ?? 0) as int;
    final maxDx = _maxDxScore(m);
    final score = (m['dxScore'] ?? 0) as int;
    return Best50CardData(
      songId: songId,
      title: m['title'] ?? context.l10n.flowUnknownSong,
      levelIndex: levelIndex,
      type: m['type'] ?? '',
      rating: (m['ra'] ?? 0) as int,
      ds: double.tryParse(m['ds'].toString()) ?? 0.0,
      achievement: double.tryParse(m['achievements'].toString()) ?? 0.0,
      fc: m['fc'] ?? '',
      fs: m['fs'] ?? '',
      stars: StringUtil.formatStars(maxDx > 0 ? score / maxDx : 0.0),
      dxScore: score,
      maxDxScore: _cardMaxScore(m),
      onOpenSong: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongInfoPage(
            songId: songId.toString(),
            initialLevelIndex:
                ChartDifficulty.parseStandardIndex(m['level_index']),
          ),
        ),
      ),
    );
  }
}
