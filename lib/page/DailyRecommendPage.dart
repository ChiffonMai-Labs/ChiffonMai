import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/service/DailyRecommendService.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'SongInfoPage.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/DifficultyConstantLabel.dart';

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

  /// 歌曲类型标签：与最近评论页一致。
  /// UTAGE 优先用 songId.length == 6 判断（DivingFish 部分 UTAGE 曲目
  /// 的 type 字段会标为 DX，此处按 6 位数 ID 强纠正为红/UT）；
  /// 其余按 song.type 区分 DX / ST。
  Widget _buildTypeTag(String songId, String songType, Brightness brightness) {
    final bool isUtage = songId.length == 6;
    final String label = isUtage ? 'UT' : (songType == 'DX' ? 'DX' : 'ST');

    Color bgColor;
    Color textColor;
    switch (label) {
      case 'UT':
        // 与 SongInfoPage 一致：粉色主题（背景 = utageCard，文字 = utageAccent）
        bgColor = brightness == Brightness.dark
            ? const Color(0xFF5C3545)
            : const Color(0xFFFFB3D1);
        textColor = brightness == Brightness.dark
            ? const Color(0xFFFF85B9)
            : const Color(0xFFFF69B4);
        break;
      case 'DX':
        bgColor = brightness == Brightness.dark
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.orange.shade100;
        textColor =
            brightness == Brightness.dark ? Colors.orange[300]! : Colors.orange;
        break;
      default:
        bgColor = brightness == Brightness.dark
            ? Colors.blue.withValues(alpha: 0.2)
            : Colors.blue.shade100;
        textColor =
            brightness == Brightness.dark ? Colors.blue[300]! : Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDailyHero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.94),
            scheme.secondaryContainer.withValues(alpha: 0.76),
          ],
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        _todayDate.isEmpty ? '正在准备今日推荐…' : _todayDate,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSongCard(
      BuildContext context, _SongDisplay item, Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final song = item.song;
    int highestIdx = 0;
    for (int i = song.ds.length - 1; i >= 0; i--) {
      if (song.ds[i] > 0) {
        highestIdx = i;
        break;
      }
    }
    final accentColor = ColorUtil.getCardColor(highestIdx);
    final labels = <Widget>[];
    for (var i = 0; i < song.ds.length; i++) {
      if (song.ds[i] <= 0) continue;
      labels.add(DifficultyConstantLabel(
        constant: song.ds[i],
        difficultyIndex: i,
        utage: song.id.length >= 6 || song.type == ChartDifficulty.utageLabel,
      ));
    }

    return Material(
      color: scheme.surface
          .withValues(alpha: brightness == Brightness.dark ? 0.66 : 0.88),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.65), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: CoverUtil.buildCoverWidgetWithContextRRect(
                  context,
                  song.id,
                  88,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 88,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildTypeTag(song.id, song.type, brightness),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  song.basicInfo.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.basicInfo.artist.isEmpty
                                ? '未知艺术家'
                                : song.basicInfo.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (labels.isNotEmpty)
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
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('今日推荐',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    )),
                            const Spacer(),
                            Text('${_songs.length} 首歌曲',
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < _songs.length; i++) ...[
                          _buildSongCard(context, _songs[i], brightness),
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
