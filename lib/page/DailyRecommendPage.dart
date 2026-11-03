import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/service/DailyRecommendService.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'SongInfoPage.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/DifficultyConstantLabel.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';

class DailyRecommendPage extends StatefulWidget {
  const DailyRecommendPage({super.key});

  @override
  State<DailyRecommendPage> createState() => _DailyRecommendPageState();
}

class _DailyRecommendPageState extends State<DailyRecommendPage> {
  final DailyRecommendService _service = DailyRecommendService();

  bool _isLoading = true;
  List<_SongDisplay> _songs = [];
  String _todayDate = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  String _getTodayDisplay() {
    final now = DateTime.now();
    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${now.year}年${now.month}月${now.day}日 星期${weekDays[now.weekday - 1]}';
  }

  Future<void> _loadRecommendations({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final songs = await _service.getDailyRecommendations(
        forceRefresh: forceRefresh,
      );
      final displaySongs = songs.map((song) {
        return _SongDisplay(song: song);
      }).toList();

      if (mounted) {
        setState(() {
          // 页面只展示四张卡片，避免推荐接口返回更多结果时把页面撑得过长。
          _songs = displaySongs.take(4).toList();
          _todayDate = _getTodayDisplay();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载当日推荐失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDailyHero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日推荐',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayDate.isEmpty ? '正在准备今日推荐…' : _todayDate,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_songs.length} 首',
            style: AppTheme.number(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(BuildContext context, _SongDisplay item) {
    final scheme = Theme.of(context).colorScheme;
    final song = item.song;
    int highestIdx = 0;
    for (int i = song.ds.length - 1; i >= 0; i--) {
      if (song.ds[i] > 0) {
        highestIdx = i;
        break;
      }
    }
    final labels = <Widget>[];
    for (var i = 0; i < song.ds.length; i++) {
      if (song.ds[i] <= 0) continue;
      labels.add(DifficultyConstantLabel(
        constant: song.ds[i],
        difficultyIndex: i,
        utage: song.id.length >= 6 || song.type == ChartDifficulty.utageLabel,
      ));
    }

    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SongInfoPage(
            songId: song.id,
            initialLevelIndex: highestIdx,
            isDefaultLevelIndex: false,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            child: CoverUtil.buildCoverWidget(song.id, 84),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SongTypeBadge(songId: song.id, type: song.type),
                    const SizedBox(width: 6),
                    Expanded(
                      child: MarqueeText(
                        text: song.basicInfo.title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                MarqueeText(
                  text: song.basicInfo.artist.isEmpty
                      ? '未知艺术家'
                      : song.basicInfo.artist,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                if (labels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < labels.length; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          labels[i],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: '每日推荐',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: '换一批',
          onPressed: _isLoading
              ? null
              : () => _loadRecommendations(forceRefresh: true),
        ),
      ],
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.passthrough,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: _isLoading
            ? Center(
                key: const ValueKey('loading'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text('正在为你挑选今日推荐…',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              )
            : _songs.isEmpty
                ? Center(
                    key: const ValueKey('empty'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_off_rounded,
                            size: 56, color: AppColors.greyHint(brightness)),
                        const SizedBox(height: 14),
                        Text('暂无可推荐的谱面\n请先在首页刷新数据',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 20),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              _loadRecommendations(forceRefresh: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    key: const ValueKey('content'),
                    padding: const EdgeInsets.only(top: 0, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDailyHero(context),
                        const SizedBox(height: AppDesignTokens.cardGap),
                        for (var i = 0; i < _songs.length; i++) ...[
                          EntranceAnimation(
                            index: i,
                            duration: const Duration(milliseconds: 300),
                            offset: const Offset(0, 8),
                            child: _buildSongCard(context, _songs[i]),
                          ),
                          if (i < _songs.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

/// 显示用的歌曲数据
class _SongDisplay {
  final Song song;

  _SongDisplay({required this.song});
}
