part of '../SongInfoPage.dart';

/// SongInfoPage · 谱面评分与评论区
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoCommunity on _SongInfoPageState {

  void _onCommentInputChanged() {
    if (_commentError != null) {
      _update(() => _commentError = null);
    }
  }

  // ============== 谱面评分相关方法 ==============

  Future<void> _preloadRatingData() async {
    final totalRating = await SongInfoService.getUserTotalRating();
    final theoreticalRating = await SongInfoService.getTheoreticalRating();
    if (mounted) {
      _update(() {
        _userTotalRating = totalRating;
        _theoreticalRating = theoreticalRating;
      });
    }
  }

  Future<void> _loadChartRating() async {
    if (!mounted) return;
    final request = ++_chartRatingRequest;
    final difficulty = _currentDiffIndex;
    _update(() {
      _chartRatingLoading = true;
      _chartAverageScore = null;
      _chartTotalVotes = 0;
      _chartRatingDistribution = null;
      _chartUserRatingData = null;
      _chartUserScore = null;
      _selectedRating = 3.0;
    });

    try {
      // 总评分、分布和本账号评分由同一次后端请求返回。
      final result = await SongInfoService.getChartRating(
        songId: widget.songId,
        levelIndex: difficulty,
      );
      if (!mounted ||
          request != _chartRatingRequest ||
          difficulty != _currentDiffIndex) return;

      if (result['success'] == true) {
        _update(() {
          _chartAverageScore = result['averageScore'] != null
              ? (result['averageScore'] as num).toDouble()
              : null;
          _chartTotalVotes = result['totalVotes'] ?? 0;
          // 解析评分分布数据
          final distRaw = result['distribution'];
          if (distRaw is Map) {
            _chartRatingDistribution = {};
            for (var entry in distRaw.entries) {
              final key = entry.key.toString();
              final val = entry.value;
              if (val is int) {
                _chartRatingDistribution![key] = val;
              } else if (val is num) {
                _chartRatingDistribution![key] = val.toInt();
              }
            }
          }
          _chartUserRatingData = result['userRating'] as Map<String, dynamic>?;
          _chartUserScore = _chartUserRatingData != null &&
                  _chartUserRatingData!['score'] != null
              ? (_chartUserRatingData!['score'] as num).toDouble()
              : null;
          if (_chartUserScore != null) {
            _selectedRating = _chartUserScore!;
          }
        });
      }
    } catch (e) {
      debugPrint('加载谱面评分失败: $e');
    } finally {
      if (mounted &&
          request == _chartRatingRequest &&
          difficulty == _currentDiffIndex) {
        _update(() => _chartRatingLoading = false);
      }
    }
  }

  String? _getChartRatingValidationMessage() {
    final userRecord = SongInfoService()
        .getUserBestRecord(_userData, widget.songId, _currentDiffIndex);

    if (userRecord == null) {
      return '至少游玩过一次该谱面才能参与打分';
    }

    double achievement = 0.0;
    if (userRecord['achievements'] != null) {
      achievement = (userRecord['achievements'] as num).toDouble();
    }

    List<dynamic> ds = _songData?['ds'] ?? [];
    bool isUtage = ds.length == 2 && widget.songId.length == 6;
    double maxAchievement = isUtage ? 202.0 : 101.0;

    if (achievement <= 0 || achievement > maxAchievement) {
      return '成绩不合法，请检查';
    }

    int totalRating = _userTotalRating ?? 0;
    int theoreticalRating = _theoreticalRating ?? 0;

    if (totalRating <= 0 || theoreticalRating <= 0) {
      return '成绩不合法，请检查';
    }

    return null;
  }

  Future<void> _submitChartRating() async {
    if (_commentDataSource == null || _commentOriginalId == null) {
      AppToast.show('请先在首页刷新数据以获取用户身份');
      return;
    }

    final userRecord = SongInfoService()
        .getUserBestRecord(_userData, widget.songId, _currentDiffIndex);
    double achievementRate = 0.0;
    if (userRecord != null && userRecord['achievements'] != null) {
      achievementRate = (userRecord['achievements'] as num).toDouble();
    }

    int totalRating = _userTotalRating ?? 0;
    int theoreticalRating = _theoreticalRating ?? 1;

    if (theoreticalRating == 0) theoreticalRating = 1;

    try {
      final result = await SongInfoService.submitChartRating(
        songId: widget.songId,
        levelIndex: _currentDiffIndex,
        score: _selectedRating,
        achievementRate: achievementRate,
        totalRating: totalRating,
        theoreticalRating: theoreticalRating,
      );

      if (result['success'] == true) {
        AppToast.show('评分提交成功');
        _loadChartRating();
      } else {
        AppToast.show(result['message'] ?? '评分提交失败');
      }
    } catch (e) {
      debugPrint('提交谱面评分失败: $e');
      AppToast.show('评分提交失败');
    }
  }

  Future<void> _deleteChartRating() async {
    if (_commentDataSource == null || _commentOriginalId == null) {
      AppToast.show('请先在首页刷新数据以获取用户身份');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        return AppAlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除您的评分吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final result = await SongInfoService.deleteChartRating(
                    songId: widget.songId,
                    levelIndex: _currentDiffIndex,
                  );
                  if (result['success'] == true) {
                    AppToast.show('评分删除成功');
                    _loadChartRating();
                  } else {
                    AppToast.show(result['message'] ?? '评分删除失败');
                  }
                } catch (e) {
                  debugPrint('删除谱面评分失败: $e');
                  AppToast.show('评分删除失败');
                }
              },
              child: Text('删除',
                  style: TextStyle(color: AppColors.errorRed(brightness))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartRatingSection(Color accentColor) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      // 2026-11：与新版白卡片一致（无投影、20 圆角）
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '谱面评分',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '($_chartTotalVotes人评分)',
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      if (_chartRatingDistribution != null)
                        GestureDetector(
                          onTap: () =>
                              _showRatingDistributionDialog(accentColor),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    size: 14, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  '分布',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.linkBlue(brightness).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.linkBlue(brightness)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '评分仅供参考，请客观公正地评价谱面，自觉维护社区环境',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.linkBlue(brightness)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_chartRatingLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // 总评分显示
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _chartAverageScore != null
                              ? _chartAverageScore!.toStringAsFixed(2)
                              : '-',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _chartAverageScore != null
                                ? _getRatingColor(_chartAverageScore!)
                                : AppColors.ratingColor("D"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_chartAverageScore != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (index) {
                                final fill = _chartAverageScore! - index;
                                if (fill >= 1) {
                                  return Icon(Icons.star_rounded,
                                      color:
                                          _getRatingColor(_chartAverageScore!),
                                      size: 24);
                                } else if (fill > 0) {
                                  return Icon(Icons.star_half_rounded,
                                      color:
                                          _getRatingColor(_chartAverageScore!),
                                      size: 24);
                                } else {
                                  return Icon(Icons.star_outline_rounded,
                                      color: AppColors.greyHint(brightness),
                                      size: 24);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  icon: Icon(
                    Icons.refresh,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _loadChartRating,
                  tooltip: '刷新评分',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 我的最近评分卡片（由后端按账号读取）
            if (_chartUserRatingData != null &&
                _chartUserRatingData!['score'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded,
                            color: accentColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '我的最近评分',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 星级 + 评分
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                (_chartUserRatingData!['score'] as num)
                                    .toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getRatingColor(
                                      (_chartUserRatingData!['score'] as num)
                                          .toDouble()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) {
                                    double fill =
                                        (_chartUserRatingData!['score'] as num)
                                                .toDouble() -
                                            index;
                                    if (fill >= 1) {
                                      return Icon(Icons.star_rounded,
                                          color: _getRatingColor(
                                              (_chartUserRatingData!['score']
                                                      as num)
                                                  .toDouble()),
                                          size: 16);
                                    } else if (fill > 0) {
                                      return Icon(Icons.star_half_rounded,
                                          color: _getRatingColor(
                                              (_chartUserRatingData!['score']
                                                      as num)
                                                  .toDouble()),
                                          size: 16);
                                    } else {
                                      return Icon(Icons.star_outline_rounded,
                                          color: AppColors.greyHint(brightness),
                                          size: 16);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 时间信息
                        if (_chartUserRatingData!['createdAt'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.greyHint(brightness)),
                            ),
                            child: Text(
                              _formatChartRatingTime(
                                  _chartUserRatingData!['createdAt']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // 用户评分区域
            if (_commentDataSource != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _chartUserScore != null ? '我的评分（点击修改）' : '为这个谱面评分',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _selectedRating,
                            min: 1.0,
                            max: 5.0,
                            divisions: 8,
                            activeColor: accentColor,
                            label: _selectedRating.toStringAsFixed(1),
                            onChanged: (value) {
                              _update(() {
                                _selectedRating = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            _selectedRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final validationMsg =
                            _getChartRatingValidationMessage();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (validationMsg != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 16,
                                        color: AppColors.errorRed(brightness)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        validationMsg,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.errorRed(brightness),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_chartUserScore != null)
                                  TextButton(
                                    onPressed: _deleteChartRating,
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          AppColors.errorRed(brightness),
                                    ),
                                    child: const Text('删除评分'),
                                  ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: validationMsg == null
                                        ? _submitChartRating
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          AppColors.greyHint(brightness),
                                      disabledForegroundColor:
                                          brightness == Brightness.dark
                                              ? Colors.white54
                                              : Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      _chartUserScore != null ? '更新' : '提交',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange(brightness),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppColors.warningOrange(brightness)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '请在首页刷新数据以获取身份后再评分',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor(double score) {
    if (score >= 5.5) return Colors.yellow;
    if (score >= 4.0) return AppColors.ratingColor('S');
    if (score >= 3.0) return AppColors.ratingColor('A');
    if (score >= 2.0) return AppColors.ratingColor('B');
    return AppColors.ratingColor('D');
  }

  // 显示评分分布对话框
  void _showRatingDistributionDialog(Color accentColor) {
    final dist = _chartRatingDistribution;
    if (dist == null || _chartTotalVotes == 0) {
      AppToast.show('暂无评分数据', duration: Duration(seconds: 1));
      return;
    }

    // 评分等级从高到低（5.0 到 1.0）
    final List<String> scoreKeys = [
      '5.0',
      '4.5',
      '4.0',
      '3.5',
      '3.0',
      '2.5',
      '2.0',
      '1.5',
      '1.0'
    ];

    // 找到最大样本数用于计算进度条长度
    int maxCount = 0;
    for (var key in scoreKeys) {
      final c = dist[key] ?? 0;
      if (c > maxCount) maxCount = c;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
          title: Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: accentColor),
              const SizedBox(width: 8),
              const Text('评分分布'),
            ],
          ),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 总评分人数
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '共 $_chartTotalVotes 人评分',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_chartAverageScore != null)
                        Text(
                          '均分 ${_chartAverageScore!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getRatingColor(_chartAverageScore!),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 横向进度条分布
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: scoreKeys.map((key) {
                        final count = dist[key] ?? 0;
                        final double percentage =
                            maxCount > 0 ? count / maxCount : 0.0;
                        final double ratingValue = double.parse(key);
                        final Color barColor = _getRatingColor(ratingValue);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              // 星级标签
                              SizedBox(
                                width: 60,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: barColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      key,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 进度条
                              Expanded(
                                child: SmoothLinearProgressIndicator(
                                  value: percentage > 0
                                      ? percentage.clamp(0.02, 1.0)
                                      : 0.0,
                                  minHeight: 20,
                                  color: barColor.withOpacity(0.85),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 人数
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('关闭', style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );
  }

  // 格式化评分时间
  String _formatChartRatingTime(dynamic rawTime) {
    try {
      if (rawTime == null) return '';
      DateTime time;
      if (rawTime is String) {
        time = DateTime.parse(rawTime);
      } else if (rawTime is int) {
        // 可能是时间戳
        time = DateTime.fromMillisecondsSinceEpoch(rawTime);
      } else {
        return rawTime.toString();
      }
      DateTime now = DateTime.now();
      Duration diff = now.difference(time);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // ============== 评论相关方法 ==============

  // 加载评论列表
  Future<void> _loadComments({bool serverRefresh = false}) async {
    if (!mounted) return;
    _update(() {
      _commentsLoading = true;
    });

    try {
      final comments = await SongInfoService.getCommentsForSong(widget.songId,
          levelIndex: _currentDiffIndex,
          forceRefresh: true,
          serverRefresh: serverRefresh);
      if (!mounted) return;
      _update(() {
        _comments = comments;
        _commentPage = 0;
        _commentsLoading = false;
      });
      debugPrint(
          'SongInfoPage: 评论加载完成，数量=${comments.length}，levelIndex=$_currentDiffIndex');
    } catch (e) {
      debugPrint('SongInfoPage: 评论加载失败: $e');
      if (!mounted) return;
      _update(() {
        _commentsLoading = false;
      });
    }
  }

  // 提交评论（自动构建评论身份）
  Future<void> _submitComment() async {
    if (_commentSubmitting) return;
    _update(() => _commentSubmitting = true);

    final content = _commentInputController.text.trim();
    final levelIndex = _currentDiffIndex;
    DialogRoute<void>? sendingDialog;
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      if (content.isEmpty) {
        _update(() => _commentError = '内容不能为空');
        return;
      }
      if (content.length > 500) {
        _update(() => _commentError = '评论内容不能超过500字');
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();
      sendingDialog = _createCommentSendingDialog();
      // 先显示忙碌状态，再进行异步词句校验和身份查询，避免首轮校验时没有反馈。
      unawaited(navigator.push(sendingDialog));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final validationError = await CommentTextValidator.validate(content);
      if (!mounted) return;
      if (validationError != null) {
        _update(() => _commentError = validationError);
        return;
      }

      // 如果尚未加载身份信息，自动从HomePage缓存构建
      if (_commentDataSource == null || _commentOriginalId == null) {
        final identity = await SongInfoService.getCommentIdentity();
        if (identity != null) {
          if (!mounted) return;
          _update(() {
            _commentDataSource = identity.dataSource;
            _commentOriginalId = identity.originalId;
            _commentNickname = identity.nickname;
          });
        } else {
          AppToast.show('请先在首页刷新数据以获取用户身份');
          return;
        }
      }

      if (_commentDataSource == null || _commentOriginalId == null) {
        AppToast.show('请先设置身份信息');
        return;
      }

      final result = await SongInfoService.createComment(
        songId: widget.songId,
        levelIndex: levelIndex,
        dataSource: _commentDataSource!,
        originalId: _commentOriginalId!,
        nickname: _commentNickname,
        content: content,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        _commentInputController.clear();
        _update(() => _commentError = null);
        AppToast.show('评论发布成功');
        // 重新加载评论
        _loadComments();
      } else {
        AppToast.show(result['message'] ?? '评论发布失败');
      }
    } catch (e) {
      if (mounted) AppToast.show('评论发布失败：$e');
    } finally {
      // 只关闭本次发送框，避免其它路由被弹出；返回键也不能绕过发送锁。
      if (navigator.mounted && sendingDialog?.isActive == true) {
        if (sendingDialog!.isCurrent) {
          navigator.pop();
        } else {
          navigator.removeRoute(sendingDialog);
        }
      }
      if (mounted) _update(() => _commentSubmitting = false);
    }
  }

  DialogRoute<void> _createCommentSendingDialog() {
    return DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AppAlertDialog(
          constraints: BoxConstraints(maxWidth: 260),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 14),
              Flexible(child: Text('发送中...')),
            ],
          ),
        ),
      ),
    );
  }

  // 删除评论
  Future<void> _deleteComment(int commentId) async {
    if (_commentDataSource == null || _commentOriginalId == null) {
      AppToast.show('无法删除：身份信息缺失');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        return AppAlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条评论吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('删除',
                  style: TextStyle(color: AppColors.errorRed(brightness))),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final result = await SongInfoService.deleteComment(
      commentId: commentId,
      songId: widget.songId,
      levelIndex: _currentDiffIndex,
      dataSource: _commentDataSource!,
      originalId: _commentOriginalId!,
    );

    if (result['success'] == true) {
      AppToast.show('评论删除成功');
      _loadComments();
    } else {
      AppToast.show(result['message'] ?? '评论删除失败');
    }
  }

  // 格式化时间
  String _formatDateTime(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return '';
    try {
      // 尝试解析多种可能的时间格式
      DateTime dt;
      if (createdAtStr.contains('T')) {
        dt = DateTime.parse(createdAtStr);
      } else {
        dt = DateTime.parse(createdAtStr.replaceAll(' ', 'T'));
      }
      // 转换为本地时间
      dt = dt.toLocal();
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAtStr;
    }
  }

  // 检查是否为当前用户的评论
  bool _isOwnComment(CommentItem comment) {
    if (_commentDataSource == null || _commentOriginalId == null) return false;
    return comment.dataSource == _commentDataSource &&
        comment.originalId == _commentOriginalId;
  }

  // 获取当前页评论
  List<CommentItem> get _pageComments {
    final start = _commentPage * _commentsPerPage;
    final end = (start + _commentsPerPage).clamp(0, _comments.length);
    if (start >= _comments.length) return [];
    return _comments.sublist(start, end);
  }

  int get _totalPages => (_comments.length / _commentsPerPage).ceil();

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
    final brightness = Theme.of(context).brightness;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.linkBlue(brightness).withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled
                ? AppColors.linkBlue(brightness).withOpacity(0.3)
                : AppColors.tableBorder(brightness),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? AppColors.linkBlue(brightness)
                : AppColors.greyHint(brightness)),
      ),
    );
  }

  // 构建评论区域
  /// 评论换页：回到评论区开头，开头正好在顶部栏下面。
  void _changeCommentPage(int page) {
    _update(() => _commentPage = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_songScrollController.hasClients) return;
      final box =
          _commentsSectionKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final top = MediaQuery.paddingOf(context).top + AppHeader.toolbarHeight + 8;
      final position = _songScrollController.position;
      final target = position.pixels + box.localToGlobal(Offset.zero).dy - top;
      _songScrollController.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    });
  }

  Widget _buildCommentsSection() {
    final brightness = Theme.of(context).brightness;
    return Container(
      key: _commentsSectionKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      // 2026-11：与新版白卡片一致（无投影、20 圆角）
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment,
                  color: AppColors.linkBlue(brightness), size: 20),
              const SizedBox(width: 8),
              Text(
                '评论',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_comments.length})',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh,
                    size: 20,
                    color: _commentRefreshCooldown
                        ? AppColors.greyHint(brightness)
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: _commentRefreshCooldown
                    ? null
                    : () {
                        _update(() {
                          _commentRefreshCooldown = true;
                        });
                        SongInfoService.clearAllCommentsCache();
                        _loadComments(serverRefresh: true);
                        AppToast.show('已刷新评论');
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) {
                            _update(() {
                              _commentRefreshCooldown = false;
                            });
                          }
                        });
                      },
                tooltip: '刷新评论',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.linkBlue(brightness).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.linkBlue(brightness)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '他人评论仅供参考，请文明发言，自觉维护网络环境',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.linkBlue(brightness)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 评论输入框
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // 自动构建的身份信息显示
                if (_commentDataSource != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 18,
                        color: AppColors.linkBlue(brightness),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_commentDataSource:$_commentOriginalId${_commentNickname != null ? ' ($_commentNickname)' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ] else
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange(brightness),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.warningOrange(brightness)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '请在首页刷新数据以获取评论身份',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _commentInputController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '输入您的评论内容...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.tableBorder(brightness)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.tableBorder(brightness)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.linkBlue(brightness)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                    counterStyle: TextStyle(
                        fontSize: 11, color: AppColors.greyHint(brightness)),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                if (_commentError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _commentError!,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.errorRed(brightness)),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: _commentSubmitting ? null : _submitComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.linkBlue(brightness),
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '发表',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 评论列表
          if (_commentsLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    color: AppColors.linkBlue(brightness)),
              ),
            )
          else if (_comments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 40, color: AppColors.greyHint(brightness)),
                  const SizedBox(height: 12),
                  Text(
                    '暂无评论，快来发表第一条评论吧！',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.greyHint(brightness)),
                  ),
                ],
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pageComments.length,
              separatorBuilder: (ctx, idx) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(color: AppColors.greyHint(brightness), height: 1),
              ),
              itemBuilder: (ctx, idx) {
                final comment = _pageComments[idx];
                final isOwn = _isOwnComment(comment);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommunityAvatar(avatarId: comment.avatarId, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    comment.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                                if (isOwn) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.linkBlue(brightness)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '我',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.linkBlue(brightness),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(comment.createdAt),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.greyHint(brightness)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment.content,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                            if (isOwn) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => _deleteComment(comment.id),
                                  child: Text(
                                    '删除',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.errorRed(brightness)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // 分页控制
            if (_totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageButton(
                      icon: Icons.chevron_left,
                      onTap: _commentPage > 0
                          ? () => _changeCommentPage(_commentPage - 1)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.linkBlue(brightness).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_commentPage + 1} / $_totalPages',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.linkBlue(brightness),
                        ),
                      ),
                    ),
                    _buildPageButton(
                      icon: Icons.chevron_right,
                      onTap: _commentPage < _totalPages - 1
                          ? () => _changeCommentPage(_commentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
