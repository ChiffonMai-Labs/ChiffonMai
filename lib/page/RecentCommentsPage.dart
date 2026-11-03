import 'package:flutter/material.dart';
import 'dart:convert';
import '../api/ApiUrls.dart';
import '../entity/DivingFish/Song.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../page/SongInfoPage.dart';
import '../service/SongInfoService.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/CommunityAvatar.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';

/// 最近评论页面：展示最近50条评论，每页10条，Redis+MySQL二级缓存
class RecentCommentsPage extends StatefulWidget {
  const RecentCommentsPage({super.key});

  @override
  State<RecentCommentsPage> createState() => _RecentCommentsPageState();
}

class _RecentCommentsPageState extends State<RecentCommentsPage> {
  bool _isLoading = true;
  List<CommentItem> _comments = [];
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
    await _loadComments();
  }

  Future<void> _loadSongCache() async {
    try {
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs != null) {
        _songMap = {for (final s in songs) s.id: s};
      }
    } catch (_) {
      // 歌曲缓存加载失败不影响评论显示
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = '${ApiUrls.CommentsRecentUrl}?page=$_currentPage&pageSize=$_pageSize${refresh ? '&refresh=true' : ''}';
      final response = await ApiClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'] ?? [];
          setState(() {
            _comments = data.map((json) => CommentItem.fromJson(json)).toList();
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
    await _loadComments(refresh: true);
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
  void _navigateToSong(String songId, int? levelIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongInfoPage(
          songId: songId,
          initialLevelIndex: levelIndex ?? 0,
          isDefaultLevelIndex: levelIndex == null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color textPrimaryColor = Theme.of(context).colorScheme.onSurface;
    return BackgroundPageScaffold(
      title: '最近评论',
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
              : _comments.isEmpty
                  ? _buildEmpty(brightness)
                  : _buildCommentList(brightness),
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
          Icon(Icons.comment_outlined, size: 56, color: AppColors.greyHint(brightness)),
          const SizedBox(height: 12),
          Text(
            '暂无评论',
            style: TextStyle(color: AppColors.greyHint(brightness), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList(Brightness brightness) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final card = Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCommentCard(_comments[index], brightness),
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

  Widget _buildCommentCard(CommentItem comment, Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final songId = comment.songId;
    final song = _getSong(songId);
    final levelIndex = comment.levelIndex ?? 0;

    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(12),
      onTap: () => _navigateToSong(songId, levelIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 评论的是哪张谱面
          Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
                child: CoverUtil.buildCoverWidget(songId, 44),
              ),
              const SizedBox(width: 10),
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
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          // 评论内容完整显示
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          // 谁、什么时候
          Row(
            children: [
              CommunityAvatar(avatarId: comment.avatarId, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: MarqueeText(
                  text: comment.displayName,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(comment.createdAt),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadComments();
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
