import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../entity/DivingFish/Song.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../service/Best50/Best50ConvertToImgService.dart';
import '../../service/Best50/IdealBest50Service.dart';
import '../../utils/ExportQualitySelector.dart';
import '../../utils/ImageEncodeUtil.dart';
import '../../utils/StringUtil.dart';
import '../SongInfoPage.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await IdealBest50Service().calculate();
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? <Song>[];
    if (!mounted) return;
    setState(() {
      _data = data;
      _sdSongs = data == null
          ? []
          : List<Map<String, dynamic>>.from(data['sd'] as List);
      _dxSongs = data == null
          ? []
          : List<Map<String, dynamic>>.from(data['dx'] as List);
      _newEntries = data == null
          ? []
          : List<Map<String, dynamic>>.from(data['newEntries'] as List);
      _songIndex = {for (final s in songs) s.id: s};
      _maimaiMusicData = songs.map((s) => s.toJson()).toList();
      _isLoading = false;
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToImage() async {
    if (_data == null || _sdSongs.isEmpty && _dxSongs.isEmpty) {
      _showMessage('提示', '没有数据可导出');
      return;
    }

    final hasPermission = await _requestStoragePermission();
    if (!mounted) return;
    if (!hasPermission) {
      _showMessage('权限不足', '需要存储权限才能导出图片到相册，请在设置中开启权限');
      return;
    }

    final quality = await ExportQualitySelector.show(
      context,
      estimatedPngSize: ImageEncodeUtil.estimatePngSize(
        songCount: _sdSongs.length + _dxSongs.length,
      ),
      exportingLabel: '拟合 Best50',
      enableThunderMode: true,
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
        thunderMode: previewQuality.thunderMode,
        thunderVertical: previewQuality.thunderVertical,
      ),
    );
    if (!mounted || quality == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('导出中'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16.0),
            Text('正在生成图片...'),
          ],
        ),
      ),
    );

    try {
      final b50Data = {
        'rating': _data!['rating'],
        'additional_rating': 0,
        'charts': {'sd': _sdSongs, 'dx': _dxSongs},
      };
      final file = await B50ConvertToImg.convertToImage(
        context,
        b50Data,
        _sdSongs,
        _dxSongs,
        _maimaiMusicData,
        jpegQuality: quality.jpegQuality,
        thunderMode: quality.thunderMode,
        thunderVertical: quality.thunderVertical,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (file != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导出成功'),
            content: Text('图片已保存到：\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: file.path));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('路径已复制到剪贴板')),
                    );
                  }
                },
                child: const Text('复制路径'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        _showMessage('导出失败', '图片导出失败，请重试');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('导出失败', '导出过程中出现错误：\n$e');
      }
    }
  }

  // ───────────────────────── 构建 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BackgroundPageScaffold(
        title: '理想 Best50',
        resizeToAvoidBottomInset: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BackgroundPageScaffold(
      title: '理想 Best50',
      resizeToAvoidBottomInset: false,
      actions: [
        if (_data != null) ...[
          Best50IconAction(
            tooltip: '导出为图片',
            icon: Icons.image_outlined,
            onPressed: _exportToImage,
          ),
          const SizedBox(width: 4),
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
              '暂无游玩数据缓存',
              style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '请返回首页点击"刷新数据"按钮获取',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
          AppDesignTokens.gutter, AppDesignTokens.gutter + 8),
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
              SegmentedTabItem('B35', caption: '${sumOf(_sdSongs)}'),
              SegmentedTabItem('B15', caption: '${sumOf(_dxSongs)}'),
            ],
            selectedIndex: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: 8),
          Best50MetaLine(best50MetaText(_segment == 0 ? '非当前版本' : '当前版本',
              songs.map((m) => (m['ra'] ?? 0) as int))),
          const SizedBox(height: AppDesignTokens.cardGap),
          _buildGrid(songs),
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
          label: '理想 Rating · 非 SSS+ 成绩升到上一档的下限',
          delta: delta,
          best35Sum: sumOf(_sdSongs),
          best15Sum: sumOf(_dxSongs),
        ),
        const SizedBox(height: AppDesignTokens.cardGap),
        AppCard(
          child: Row(
            children: [
              Expanded(
                  child: StatTile(label: '原 Rating', value: '$originalRating')),
              Expanded(
                  child: StatTile(
                      label: '新进榜', value: '${_newEntries.length}')),
              Expanded(
                  child: StatTile(
                      label: '平均达成率',
                      value: '${avgAchievement.toStringAsFixed(2)}%')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewEntriesSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '本次新进榜（${_newEntries.length} 首）',
            padding: const EdgeInsets.only(bottom: 6),
          ),
          if (_newEntries.isEmpty)
            Text(
              '无新歌进榜（升档后榜单成员不变）',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            )
          else
            for (final e in _newEntries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '· ${e['title']}  · 定数 ${(e['ds'] as num).toStringAsFixed(1)}  · RA ${e['oldRa']} → ${e['newRa']}',
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
              ),
        ],
      ),
    );
  }



  Widget _buildGrid(List<Map<String, dynamic>> songs) {
    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('无数据',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }
    return Best50Grid(
      key: ValueKey(_segment),
      items: [for (final m in songs) _cardData(m)],
    );
  }

  Best50CardData _cardData(Map<String, dynamic> m) {
    final songId = (m['song_id'] ?? 0) as int;
    final levelIndex = (m['level_index'] ?? 0) as int;
    final maxDx = _maxDxScore(m);
    final score = (m['dxScore'] ?? 0) as int;
    return Best50CardData(
      songId: songId,
      title: m['title'] ?? '未知歌曲',
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
            initialLevelIndex: levelIndex,
            isDefaultLevelIndex: false,
          ),
        ),
      ),
    );
  }

}
