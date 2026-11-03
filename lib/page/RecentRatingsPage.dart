import 'package:flutter/material.dart';
import 'dart:convert';
import '../api/ApiUrls.dart';
import '../entity/DivingFish/Song.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../page/SongInfoPage.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';

/// 评分记录数据模型
class RatingRecordItem {
  final int id;
  final String songId;
  final int levelIndex;
  final String userId;
  final String? dataSource;
  final String? originalId;
  final double score;
  final double? achievementRate;
  final int? totalRating;
  final int? theoreticalRating;
  final double? weight;
  final String? createdAt;

  RatingRecordItem({
    required this.id,
    required this.songId,
    required this.levelIndex,
    required this.userId,
    this.dataSource,
    this.originalId,
    required this.score,
    this.achievementRate,
    this.totalRating,
    this.theoreticalRating,
    this.weight,
    this.createdAt,
  });

  /// 安全地将 JSON 值转为 double，兼容 String / int / double
  static double _parseDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? fallback;
    }
    return fallback;
  }

  /// 安全地将 JSON 值转为 int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  factory RatingRecordItem.fromJson(Map<String, dynamic> json) {
    return RatingRecordItem(
      id: _parseInt(json['id']) ?? 0,
      songId: (json['songId'] ?? json['song_id'] ?? '').toString(),
      levelIndex: _parseInt(json['levelIndex'] ?? json['level_index']) ?? 0,
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      dataSource: json['dataSource'] ?? json['data_source'],
      originalId: json['originalId'] ?? json['original_id'],
      score: _parseDouble(json['score']),
      achievementRate: json['achievementRate'] != null
          ? _parseDouble(json['achievementRate'], 0)
          : json['achievement_rate'] != null
              ? _parseDouble(json['achievement_rate'], 0)
              : null,
      totalRating: _parseInt(json['totalRating'] ?? json['total_rating']),
      theoreticalRating: _parseInt(json['theoreticalRating'] ?? json['theoretical_rating']),
      weight: json['weight'] != null
          ? _parseDouble(json['weight'], 0)
          : null,
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }
}

/// 最近评分页面：展示最近50条谱面评分记录，每页10条，Redis+MySQL二级缓存
class RecentRatingsPage extends StatefulWidget {
  const RecentRatingsPage({super.key});

  @override
  State<RecentRatingsPage> createState() => _RecentRatingsPageState();
}

class _RecentRatingsPageState extends State<RecentRatingsPage> {
  bool _isLoading = true;
  List<RatingRecordItem> _ratings = [];
  Map<String, Song> _songMap = {};
  int _currentPage = 1;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadSongCache();
    await _loadRatings();
  }

  Future<void> _loadSongCache() async {
    try {
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs != null) {
        _songMap = {for (final s in songs) s.id: s};
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRatings({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = '${ApiUrls.RatingsRecentUrl}?page=$_currentPage&pageSize=$_pageSize${refresh ? '&refresh=true' : ''}';
      final response = await ApiClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'] ?? [];
          setState(() {
            _ratings = data.map((json) => RatingRecordItem.fromJson(json)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['error'] ?? '加载失败';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = '请求失败 (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    await _loadRatings(refresh: true);
  }

  Song? _getSong(String songId) => _songMap[songId];

  String _getSongTitle(String songId) {
    final song = _getSong(songId);
    return song?.title ?? songId;
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  Widget _buildStars(double score, Brightness brightness, {double starSize = 16}) {
    final fullStars = score.floor();
    final hasHalf = (score - fullStars) >= 0.25;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        Color color;

        if (index < fullStars) {
          icon = Icons.star;
          color = AppColors.warningOrange(brightness);
        } else if (index == fullStars && hasHalf) {
          icon = Icons.star_half;
          color = AppColors.warningOrange(brightness);
        } else {
          icon = Icons.star_border;
          color = AppColors.greyHint(brightness, shade: 400);
        }

        return Icon(icon, size: starSize, color: color);
      }),
    );
  }

  String _getUserIdDisplay(RatingRecordItem rating) {
    // 三个源都认（原来只判断 shuiyu / luoxue，AWMC NET 会掉到下面显示原始 uid）。
    // 用短名：这里拼出来是「AWMC用户」，全名会变成「AWMC NET用户」，读着别扭。
    final label = RefreshDataSource.shortDisplayNameOfKey(rating.dataSource);
    if (label.isNotEmpty) return '$label用户';
    final uid = rating.userId;
    return uid.length > 8 ? '${uid.substring(0, 8)}...' : uid;
  }

  void _navigateToSong(String songId, int levelIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongInfoPage(
          songId: songId,
          initialLevelIndex: levelIndex,
          isDefaultLevelIndex: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color textPrimaryColor = Theme.of(context).colorScheme.onSurface;
    return BackgroundPageScaffold(
      title: '最近评分',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: textPrimaryColor),
          onPressed: _isLoading ? null : _refresh,
        ),
      ],
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: _isLoading
          ? _buildLoading(brightness)
          : _errorMessage != null
              ? _buildError(brightness)
              : _ratings.isEmpty
                  ? _buildEmpty(brightness)
                  : _buildRatingList(brightness),
    );
  }

  Widget _buildLoading(Brightness brightness) {
    return Center(
      child: CircularProgressIndicator(color: AppColors.linkBlue(brightness)),
    );
  }

  Widget _buildError(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.errorRed(brightness)),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.errorRed(brightness), fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _refresh, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmpty(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border_outlined, size: 56, color: AppColors.greyHint(brightness)),
          const SizedBox(height: 12),
          Text(
            '暂无评分记录',
            style: TextStyle(color: AppColors.greyHint(brightness), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingList(Brightness brightness) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
            itemCount: _ratings.length,
            itemBuilder: (context, index) {
              final card = Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRatingCard(_ratings[index], brightness),
              );
              // 只给首屏做入场，滚回来时不重播
              return index < 8
                  ? EntranceAnimation(
                      index: index,
                      duration: const Duration(milliseconds: 300),
                      offset: const Offset(0, 8),
                      child: card,
                    )
                  : card;
            },
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildRatingCard(RatingRecordItem rating, Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final songId = rating.songId;
    final song = _getSong(songId);
    final levelIndex = rating.levelIndex;

    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(12),
      onTap: () => _navigateToSong(songId, levelIndex),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            child: CoverUtil.buildCoverWidget(songId, 60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MarqueeText(
                  text: _getSongTitle(songId),
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
                const SizedBox(height: 6),
                Text(
                  '${_getUserIdDisplay(rating)} · ${_formatTime(rating.createdAt)}',
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 评分是这张卡的主角
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  text: rating.score.toStringAsFixed(1),
                  style: AppTheme.number(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warningOrange(brightness),
                  ),
                  children: [
                    TextSpan(
                      text: ' / 5.0',
                      style: AppTheme.number(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              _buildStars(rating.score, brightness, starSize: 13),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadRatings();
  }

  Widget _buildPagination() {
    const int totalRecords = 50;
    final totalPages = (totalRecords / _pageSize).ceil();
    return PagerBar(
      page: _currentPage,
      totalPages: totalPages,
      onPrevious: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
      onNext:
          _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
    );
  }
}
