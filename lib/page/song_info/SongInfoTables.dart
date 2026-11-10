part of '../SongInfoPage.dart';

/// SongInfoPage · 数据类板块：定数历史、成绩趋势、分布图、对照表、容错计算
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoTables on _SongInfoPageState {
  /// 成绩趋势（达成率 / DX 分曲线）板块。
  ///
  /// **它是一块独立于「玩家最佳成绩」的卡片**，排在后者下方 —— 以前这条曲线
  /// 是嵌在「玩家最佳成绩」容器内部的一段，看起来像是成绩卡的一部分，
  /// 而它其实是"这张谱面的历史成绩"，粒度是谱面而不是这一次成绩。
  ///
  /// 卡片自身不给内边距：没有历史时 [ChartHistorySection] 返回 `SizedBox.shrink()`，
  /// 外壳也必须跟着收缩成 0 高度，所以 padding 只能按**渲染形态**分三档给
  /// （空 / 基线文字 / 完整曲线），否则会在页面上凭空留一块空白。
  Widget _buildChartHistoryCard() {
    final songId = int.tryParse(widget.songId) ?? 0;
    // ⚠️ 卡片**不做外层 padding**：`ChartHistorySection` 在没有历史时返回
    // `SizedBox.shrink()`，外面再垫一个 SizedBox 就会在页面上留一块空白。
    // 「与上方成绩卡的空隙」由 section 自己的 `chartPadding.top` 提供
    // （只有真正画出曲线时才存在）。见那里的参数说明。
    return ChartHistorySection(
      songId: songId,
      levelIndex: _currentDiffIndex,
      maxDxScore: _calculateMaxDxScore(songId, _currentDiffIndex),
      // 手动录入时的达成率上限（普通曲 101%；宴会场子谱相加 → 202%）
      maxAchievement: _calculateMaxAchievement(),
      // 有曲线时的卡片样式（垫一层 surface 底 + 圆角）
      cardStyle: true,
      // 完全没有历史 → 整块高度 0，不占位、不留白
      emptyPadding: EdgeInsets.zero,
      // 只有基线且还没有变化 → 基本水平内边距
      textPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      // 有曲线 → 完整卡片内边距。
      // 卡片之间的间距由 build 里的 SizedBox 提供，这里只管卡片内部。
      chartPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    );
  }

  // 定数历史表格（横向滑动，2行：版本列表 + 对应定数）
  Widget _buildDxHistoryTable() {
    final entries = _buildDxHistory();
    if (entries.isEmpty) return const SizedBox.shrink();
    final firstValueIndex =
        math.max(0, entries.indexWhere((entry) => entry.value != null));

    final colorScheme = Theme.of(context).colorScheme;

    // 计算每个版本（除第一个外）相对前一个版本的定数变化方向：1=升 -1=降 0=不变 null=首个
    final directions = <int?>[];
    double? previous;
    for (final entry in entries) {
      final value = entry.value;
      directions.add(
          value == null || previous == null ? null : value.compareTo(previous));
      if (value != null) previous = value;
    }

    // 版本表头单元格（仅保留底部一条横线分隔）
    Widget headerCell(String text) {
      return Container(
        width: 84,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: AppTheme.number(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // 定数单元格（带相对前一版本的变化箭头）
    Widget valueCell(String text, int? direction) {
      return Container(
        width: 84,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: Alignment.center,
        child: _valueWithDirection(text, direction),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            context.l10n.flowConstantHistory,
            textAlign: TextAlign.center,
            style: AppTheme.number(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _DxHistoryScrollView(
          key: ValueKey((
            _currentDiffIndex,
            entries.map((entry) => entry.version).join('|'),
            firstValueIndex,
          )),
          initialOffset: firstValueIndex * 84.0,
          contentWidth: entries.length * 84.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (int i = 0; i < entries.length; i++)
                    headerCell(_formatDxHistoryVersion(entries[i].version)),
                ],
              ),
              Row(
                children: [
                  for (int i = 0; i < entries.length; i++)
                    valueCell(entries[i].value?.toStringAsFixed(1) ?? '',
                        directions[i]),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建星星等级最低DX分对照表
  Widget _buildStarScoreTable() {
    if (_songData == null) return Container();

    final brightness = Theme.of(context).brightness;

    int maxScore =
        _calculateMaxDxScore(int.parse(widget.songId), _currentDiffIndex);

    // 星星等级对应的最低达成率（降序排列）
    List<Map<String, dynamic>> starLevels = [
      {"star": 6, "rate": 0.99, "color": Colors.yellow},
      {"star": 5.5, "rate": 0.98, "color": Colors.yellow},
      {"star": 5, "rate": 0.97, "color": Colors.yellow},
      {"star": 4, "rate": 0.95, "color": AppColors.warningOrange(brightness)},
      {"star": 3, "rate": 0.93, "color": AppColors.warningOrange(brightness)},
      {
        "star": 2,
        "rate": 0.90,
        "color": brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade300
      },
      {
        "star": 1,
        "rate": 0.85,
        "color": brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade300
      },
    ];

    // 计算每个星星等级的最低DX分
    List<Map<String, dynamic>> starScoreData = [];
    for (var item in starLevels) {
      num star = item['star'];
      double rate = item['rate'];
      Color color = item['color'];
      int minScore = (maxScore * rate).ceil();
      starScoreData.add(
          {"star": star, "rate": rate, "minScore": minScore, "color": color});
    }

    // 获取玩家最佳成绩
    final userRecord = _getUserBestRecord();

    // 如果存在玩家最佳成绩，将其添加到表格中
    if (userRecord != null && userRecord['dxScore'] != null) {
      int userScore = (userRecord['dxScore'] as num).toInt();

      // 找到合适的插入位置
      int insertIndex = 0;
      while (insertIndex < starScoreData.length &&
          userScore < starScoreData[insertIndex]['minScore']) {
        insertIndex++;
      }

      // 计算玩家成绩对应的达成率
      double userRate = userScore / maxScore;

      // 确定玩家成绩的颜色
      Color userColor = AppColors.linkBlue(brightness);

      // 插入玩家成绩
      starScoreData.insert(insertIndex, {
        "star": "玩家",
        "rate": userRate,
        "minScore": userScore,
        "color": userColor,
        "isUserRecord": true
      });
    }

    // 计算提升值
    for (int i = starScoreData.length - 1; i > 0; i--) {
      int currentScore = starScoreData[i]['minScore'];
      int nextScore = starScoreData[i - 1]['minScore'];
      starScoreData[i]['delta'] = nextScore - currentScore;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和展开收起按钮（整行可点击）
        InkWell(
          onTap: () {
            _update(() {
              _starScoreTableExpanded = !_starScoreTableExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.flowStarsDXScoreTable,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getAccentColor(_currentDiffIndex, brightness),
                  ),
                ),
                AnimatedRotation(
                  turns: _starScoreTableExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more,
                      color: _getAccentColor(_currentDiffIndex, brightness)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 表格内容（根据展开状态显示）
                if (_starScoreTableExpanded) ...[
                  // 表头
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.tableBorder(brightness))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3, // 星数列占3份
                          child: Text(context.l10n.flowStars,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ),
                        Expanded(
                          flex: 2, // DX分数列占2份
                          child: Text(context.l10n.flowDXScore2,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              textAlign: TextAlign.center),
                        ),
                        Expanded(
                          flex: 1, // MAX-列占1份
                          child: Text('MAX-',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),

                  // 表格内容
                  Column(
                    children: starScoreData.asMap().entries.map((entry) {
                      var item = entry.value;
                      dynamic star = item['star'];
                      double rate = item['rate'];
                      int minScore = item['minScore'];
                      int? delta = item['delta'];
                      Color color = item['color'];
                      bool isUserRecord = item['isUserRecord'] ?? false;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: AppColors.tableBorder(brightness))),
                          color: isUserRecord
                              ? AppColors.linkBlue(brightness)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, // 星数列占3份
                              child: Row(
                                children: [
                                  Text(
                                    star == '玩家'
                                        ? context.l10n.flowPlayers
                                        : '\u2726 ${star.toString()}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isUserRecord ? Colors.white : color,
                                      shadows: [
                                        Shadow(
                                          color: isUserRecord
                                              ? Colors.white.withOpacity(0.5)
                                              : color.withOpacity(0.5),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(rate * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: isUserRecord
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2, // 最低DX分数列占2份
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (delta != null)
                                    Text(
                                      '↑$delta',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isUserRecord
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                    ),
                                  Text(
                                    minScore.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isUserRecord
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontWeight: isUserRecord
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1, // MAX-列占1份
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '-${maxScore - minScore}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isUserRecord
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontWeight: isUserRecord
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建达成率-得分对照表
  Widget _buildAchievementScoreTable() {
    if (_songData == null) return Container();

    final brightness = Theme.of(context).brightness;

    // 检查歌曲id是否为6位数
    bool isSixDigitId = widget.songId.length == 6;

    double difficulty =
        double.tryParse(_songData!['ds'][_currentDiffIndex].toString()) ?? 0.0;

    // 计算每个达成率对应的得分
    List<Map<String, dynamic>> scoreData = [];
    for (var item in _displayedRatingSegments) {
      double completion = item['completion'];
      String rating = item['rating'];
      // 如果是6位数id的歌曲，得分设为0
      int score =
          isSixDigitId ? 0 : _calculateSingleRating(difficulty, completion);
      scoreData
          .add({"completion": completion, "rating": rating, "score": score});
    }

    // 对于定数大于等于12.0的谱面，添加额外的达成率点（每个可达成的 score 都加边界）
    // 但6位数id的歌曲不添加额外达成率点
    if (difficulty >= 12.0 &&
        !isSixDigitId &&
        RatingSegmentPreferences.instance.isDetailed) {
      // 在 [lo, hi] 内二分找最小 c 使 _calculateSingleRating(difficulty, c) >= targetScore
      double binarySearchMinCompletion(double lo, double hi, int targetScore) {
        double mid = lo;
        int iters = 0;
        while (hi - lo > 0.0001 && iters < 100) {
          mid = (lo + hi) / 2;
          int currentScore = _calculateSingleRating(difficulty, mid);
          if (currentScore < targetScore) {
            lo = mid;
          } else {
            hi = mid;
          }
          iters++;
        }
        return mid;
      }

      // 给定 c 找对应评级
      String lookupRating(double c) {
        for (var item in maimaiRatingMultiplier) {
          if (c >= item['completion']) {
            return item['rating'] as String;
          }
        }
        return '';
      }

      // 把每个区间内所有可达 score 的边界都加进 scoreData
      void addBoundariesInRange(double baseCompletion, double upperCompletion) {
        int baseScore = _calculateSingleRating(difficulty, baseCompletion);
        int upperScore = _calculateSingleRating(difficulty, upperCompletion);
        if (upperScore <= baseScore + 1) return; // 没有中间可达 score

        double lowerBound = baseCompletion;
        for (int target = baseScore + 1; target < upperScore; target++) {
          final mid =
              binarySearchMinCompletion(lowerBound, upperCompletion, target);
          if (_calculateSingleRating(difficulty, mid) < target) {
            // 该 score 在本区间不可达（安全兜底，正常不应发生）
            break;
          }
          scoreData.add({
            "completion": mid,
            "rating": lookupRating(mid),
            "score": target,
          });
          lowerBound = mid; // 下一个边界一定在 mid 之后
        }
      }

      // 1. 高达成率大区间（5 段）：和原代码范围一致
      const ranges = <List<double>>[
        [97.0, 98.0],
        [98.0, 98.9999],
        [99.0, 99.5],
        [99.5, 99.9999],
        [100.0, 100.4999],
      ];
      for (final range in ranges) {
        addBoundariesInRange(range[0], range[1]);
      }

      // 2. 跨倍率的 0.0001 窄段（原代码漏掉）
      //    这些段里两个端点的倍率不同，中间可能有不可达的 score 跳变
      const narrowRanges = <List<double>>[
        [96.9999, 97.0], // AAA 0.176 → S 0.200
        [98.9999, 99.0], // S+ 0.206 → SS 0.208
        [99.9999, 100.0], // SS+ 0.214 → SSS 0.216
        [100.4999, 100.5], // SSS 0.222 → SSS+ 0.224
      ];
      for (final range in narrowRanges) {
        addBoundariesInRange(range[0], range[1]);
      }

      // 按达成率降序排序
      scoreData.sort((a, b) => b['completion'].compareTo(a['completion']));
    }

    // 获取玩家最佳成绩
    final userRecord = _getUserBestRecord();

    // 如果存在玩家最佳成绩，将其添加到表格中
    if (userRecord != null &&
        userRecord['achievements'] != null &&
        userRecord['ra'] != null) {
      double userCompletion = (userRecord['achievements'] as num).toDouble();
      int userScore = (userRecord['ra'] as num).toInt();

      // 找到合适的插入位置：对比玩家的达成率与每一行的达成率
      int insertIndex = 0;
      while (insertIndex < scoreData.length &&
          userCompletion < scoreData[insertIndex]['completion']) {
        insertIndex++;
      }

      // 插入玩家成绩（暂时不计算差距值）
      scoreData.insert(insertIndex, {
        "completion": userCompletion,
        "rating": "玩家",
        "score": userScore,
        "isUserRecord": true
      });
    }

    // 计算得分提升值
    for (int i = scoreData.length - 1; i > 0; i--) {
      int currentScore = scoreData[i]['score'];
      int nextScore = scoreData[i - 1]['score'];
      scoreData[i]['delta'] = nextScore - currentScore;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和展开收起按钮（整行可点击）
        InkWell(
          onTap: () {
            _update(() {
              _achievementScoreTableExpanded = !_achievementScoreTableExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.flowAchievementScoreTable,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getAccentColor(_currentDiffIndex, brightness),
                  ),
                ),
                AnimatedRotation(
                  turns: _achievementScoreTableExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more,
                      color: _getAccentColor(_currentDiffIndex, brightness)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 表格内容（根据展开状态显示）
                if (_achievementScoreTableExpanded) ...[
                  // 表头
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.tableBorder(brightness))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.flowAchievement2,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(context.l10n.flowScore,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),

                  // 表格内容
                  Column(
                    children: scoreData.asMap().entries.map((entry) {
                      var item = entry.value;
                      dynamic rating = item['rating'];
                      double completion = item['completion'];
                      int score = item['score'];
                      int? delta = item['delta'];
                      bool isUserRecord = item['isUserRecord'] ?? false;

                      // 获取评级颜色
                      Color ratingColor =
                          Theme.of(context).colorScheme.onSurface;
                      if (rating == '玩家') {
                        ratingColor = Colors.white;
                      } else {
                        switch (rating) {
                          case 'SSS+':
                          case 'SSS':
                            ratingColor = Colors.yellow;
                            break;
                          case 'SS+':
                          case 'SS':
                            ratingColor = Color(0xFFFFAA00);
                            break;
                          case 'S+':
                          case 'S':
                            ratingColor = Color(0xFFFF9900);
                            break;
                          case 'AAA':
                          case 'AA':
                          case 'A':
                            ratingColor = Color(0xFFFF4444);
                            break;
                          case 'BBB':
                          case 'BB':
                          case 'B':
                            ratingColor = Color(0xFF44AAFF);
                            break;
                          case 'C':
                            ratingColor = Color(0xFFFF4444);
                            break;
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: AppColors.tableBorder(brightness))),
                          color: isUserRecord
                              ? AppColors.linkBlue(brightness)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isUserRecord
                                      ? context.l10n.flowPlayers
                                      : rating.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: ratingColor,
                                    shadows: [
                                      Shadow(
                                        color: isUserRecord
                                            ? Colors.white.withOpacity(0.5)
                                            : ratingColor.withOpacity(0.5),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${completion.toStringAsFixed(4)}%',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: isUserRecord
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (delta != null)
                                  Text(
                                    '↑$delta',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: isUserRecord
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                  ),
                                Text(
                                  score.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isUserRecord
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight: isUserRecord
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建容错计算区域
  Widget _buildToleranceCalculation() {
    if (_songData == null) return Container();

    final brightness = Theme.of(context).brightness;
    final currentChart = _songData!['charts'][_currentDiffIndex];
    // 优先使用Maidata解析的物量统计
    List<int> noteCounts = _getNoteCounts(currentChart);

    // 计算总音符权重
    int totalTap = noteCounts[0];
    int totalHold = noteCounts[1];
    int totalSlide = noteCounts[2];
    int totalTouch = noteCounts[3];
    int totalBreak = noteCounts[4];

    int totalWeight = totalTap * _tapWeight +
        totalHold * _holdWeight +
        totalSlide * _slideWeight +
        totalTouch * _touchWeight +
        totalBreak * _breakWeight;

    // 获取当前选中音符的信息
    int noteCount = 0;
    int noteWeight = 0;
    switch (_selectedNoteType) {
      case 'TAP':
        noteCount = totalTap;
        noteWeight = _tapWeight;
        break;
      case 'HOLD':
        noteCount = totalHold;
        noteWeight = _holdWeight;
        break;
      case 'SLIDE':
        noteCount = totalSlide;
        noteWeight = _slideWeight;
        break;
      case 'TOUCH':
        noteCount = totalTouch;
        noteWeight = _touchWeight;
        break;
      case 'BREAK':
        noteCount = totalBreak;
        noteWeight = _breakWeight;
        break;
    }

    double weightRatio =
        totalWeight > 0 ? (noteCount * noteWeight) / totalWeight : 0;

    // 计算判定损失（参考AchievementRateCalculatorPage）
    double greatLoss =
        totalWeight > 0 ? (0.20 * 100.00 * noteWeight / totalWeight) : 0;
    double goodLoss =
        totalWeight > 0 ? (0.50 * 100.00 * noteWeight / totalWeight) : 0;
    double missLoss =
        totalWeight > 0 ? (1.00 * 100.00 * noteWeight / totalWeight) : 0;

    // BREAK音符特殊判定损失
    // 50落：基础部分权重相同，额外部分损失0.25 (1.0 - 0.75)
    double break50Loss = noteCount > 0 ? 0.25 / noteCount : 0; // 50落 -> 损失25%
    // 100落：基础部分权重相同，额外部分损失0.50 (1.0 - 0.50)
    double break100Loss = noteCount > 0 ? 0.5 / noteCount : 0; // 100落 -> 损失50%
    double break80Loss = totalWeight > 0
        ? (0.20 * 100.00 * noteWeight / totalWeight)
        : 0; // 80% -> 损失20%
    double break60Loss = totalWeight > 0
        ? (0.40 * 100.00 * noteWeight / totalWeight)
        : 0; // 60% -> 损失40%
    double break50gLoss = totalWeight > 0
        ? (0.50 * 100.00 * noteWeight / totalWeight)
        : 0; // 50% -> 损失50%
    double breakGoLoss = totalWeight > 0
        ? (0.60 * 100.00 * noteWeight / totalWeight)
        : 0; // 40% -> 损失60%

    // 计算容错数量
    int tolerance05Miss = missLoss > 0 ? (0.5 / missLoss).floor() : 0;
    int tolerance10Miss = missLoss > 0 ? (1.0 / missLoss).floor() : 0;

    // BREAK音符容错数量
    int tolerance05Break80 = break80Loss > 0 ? (0.5 / break80Loss).floor() : 0;
    int tolerance05Break60 = break60Loss > 0 ? (0.5 / break60Loss).floor() : 0;
    int tolerance05Break50g =
        break50gLoss > 0 ? (0.5 / break50gLoss).floor() : 0;
    int tolerance05BreakGo = breakGoLoss > 0 ? (0.5 / breakGoLoss).floor() : 0;
    int tolerance10Break80 = break80Loss > 0 ? (1.0 / break80Loss).floor() : 0;
    int tolerance10Break60 = break60Loss > 0 ? (1.0 / break60Loss).floor() : 0;
    int tolerance10Break50g =
        break50gLoss > 0 ? (1.0 / break50gLoss).floor() : 0;
    int tolerance10BreakGo = breakGoLoss > 0 ? (1.0 / breakGoLoss).floor() : 0;

    // 自定义BREAK输入相关的调整计算（用于非BREAK音符）
    // 计算已输入的BREAK判定的总损失（占整体的百分比），与BREAK选项卡保持一致
    // 注意：BREAK判定损失必须使用BREAK权重（_breakWeight=5），而非当前选中音符的权重
    double breakInputLoss = 0;
    if (totalBreak > 0) {
      breakInputLoss =
          (_break50Count * 0.25 + _break100Count * 0.50) / totalBreak;
    }
    if (totalWeight > 0) {
      breakInputLoss +=
          _break80Count * (0.20 * 100.00 * _breakWeight / totalWeight) +
              _break60Count * (0.40 * 100.00 * _breakWeight / totalWeight) +
              _break50gCount * (0.50 * 100.00 * _breakWeight / totalWeight) +
              _breakGoodCount * (0.60 * 100.00 * _breakWeight / totalWeight) +
              _breakMissCount * (1.00 * 100.00 * _breakWeight / totalWeight);
    }

    // 调整后的容错数量（扣除自定义BREAK损失后）
    double remainingBudget05 = (0.5 - breakInputLoss).clamp(0, 0.5);
    double remainingBudget10 = (1.0 - breakInputLoss).clamp(0, 1.0);
    double remainingBudget15 = (1.5 - breakInputLoss).clamp(0, 1.5);
    double remainingBudget20 = (2.0 - breakInputLoss).clamp(0, 2.0);

    int adjustedTolerance05Great = (greatLoss > 0 && remainingBudget05 > 0)
        ? (remainingBudget05 / greatLoss).floor()
        : 0;
    int adjustedTolerance05Good = (goodLoss > 0 && remainingBudget05 > 0)
        ? (remainingBudget05 / goodLoss).floor()
        : 0;
    int adjustedTolerance05Miss = (missLoss > 0 && remainingBudget05 > 0)
        ? (remainingBudget05 / missLoss).floor()
        : 0;
    int adjustedTolerance10Great = (greatLoss > 0 && remainingBudget10 > 0)
        ? (remainingBudget10 / greatLoss).floor()
        : 0;
    int adjustedTolerance10Good = (goodLoss > 0 && remainingBudget10 > 0)
        ? (remainingBudget10 / goodLoss).floor()
        : 0;
    int adjustedTolerance10Miss = (missLoss > 0 && remainingBudget10 > 0)
        ? (remainingBudget10 / missLoss).floor()
        : 0;
    int adjustedTolerance15Great = (greatLoss > 0 && remainingBudget15 > 0)
        ? (remainingBudget15 / greatLoss).floor()
        : 0;
    int adjustedTolerance15Good = (goodLoss > 0 && remainingBudget15 > 0)
        ? (remainingBudget15 / goodLoss).floor()
        : 0;
    int adjustedTolerance15Miss = (missLoss > 0 && remainingBudget15 > 0)
        ? (remainingBudget15 / missLoss).floor()
        : 0;
    int adjustedTolerance20Great = (greatLoss > 0 && remainingBudget20 > 0)
        ? (remainingBudget20 / greatLoss).floor()
        : 0;
    int adjustedTolerance20Good = (goodLoss > 0 && remainingBudget20 > 0)
        ? (remainingBudget20 / goodLoss).floor()
        : 0;
    int adjustedTolerance20Miss = (missLoss > 0 && remainingBudget20 > 0)
        ? (remainingBudget20 / missLoss).floor()
        : 0;

    // 校验输入提示
    String? breakInputError;
    final int totalInputCount = _break50Count +
        _break100Count +
        _break80Count +
        _break60Count +
        _break50gCount +
        _breakGoodCount +
        _breakMissCount;
    if (_break50Count < 0 ||
        _break100Count < 0 ||
        _break80Count < 0 ||
        _break60Count < 0 ||
        _break50gCount < 0 ||
        _breakGoodCount < 0 ||
        _breakMissCount < 0) {
      breakInputError = context.l10n.flowCountCannotBeNegative;
    } else if (totalInputCount > totalBreak) {
      breakInputError = context.l10n.flowPlayedCountP0CannotExceedTheTotal(
          (totalInputCount).toString(), (totalBreak).toString());
    } else if (breakInputLoss >= 2.0) {
      breakInputError = context.l10n.flowBREAKLossIsP0BeyondTheSS(
          (breakInputLoss.toStringAsFixed(2)).toString());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和展开收起按钮（整行可点击）
        InkWell(
          onTap: () {
            _update(() {
              _toleranceCalculationExpanded = !_toleranceCalculationExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.flowJudgmentAllowance,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getAccentColor(_currentDiffIndex, brightness),
                  ),
                ),
                AnimatedRotation(
                  turns: _toleranceCalculationExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more,
                      color: _getAccentColor(_currentDiffIndex, brightness)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 表格内容（根据展开状态显示）
                if (_toleranceCalculationExpanded) ...[
                  // 音符类型选择器
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _noteTypes
                        .where((noteType) =>
                            !(noteType == 'TOUCH' && totalTouch == 0))
                        .map((noteType) => ElevatedButton(
                              onPressed: () {
                                _update(() {
                                  _selectedNoteType = noteType;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedNoteType == noteType
                                    ? _getAccentColor(
                                        _currentDiffIndex, brightness)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                foregroundColor: _selectedNoteType == noteType
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              child: Text(noteType),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 15),

                  // 容错信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyHint(brightness)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                child: Text(context.l10n.flowNoteType,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant))),
                            Text(_selectedNoteType,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                child: Text(context.l10n.flowShareOfTotalWeight,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant))),
                            Text('${(weightRatio * 100).toStringAsFixed(2)}%',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 仅当选中非BREAK音符时显示常规判定损失和自定义BREAK输入
                        if (_selectedNoteType != 'BREAK') ...[
                          // 自定义BREAK损失输入区域
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange(brightness),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.warningOrange(brightness)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.flowBREAKLossSoFar,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _break50Controller,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText:
                                              context.l10n.flow50PointLosses,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _break50Count < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _break50Count =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _break100Controller,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText:
                                              context.l10n.flow100PointLosses,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _break100Count < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _break100Count =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _break80Controller,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText:
                                              context.l10n.flow80GREATCount,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _break80Count < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _break80Count =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _break60Controller,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText:
                                              context.l10n.flow60GREATCount,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _break60Count < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _break60Count =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _break50gController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText:
                                              context.l10n.flow50GREATCount,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _break50gCount < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _break50gCount =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _breakGoodController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: context.l10n.flowGOODCount,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _breakGoodCount < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _breakGoodCount =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _breakMissController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: context.l10n.flowMISSCount,
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          errorText: _breakMissCount < 0 ||
                                                  totalInputCount > totalBreak
                                              ? context.l10n.flowInvalid
                                              : null,
                                        ).insetLabel(context),
                                        onChanged: (value) {
                                          _update(() {
                                            _breakMissCount =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // 校验错误提示
                                if (breakInputError != null) ...[
                                  const SizedBox(height: 4),
                                  Text(breakInputError,
                                      style: TextStyle(
                                          color: AppColors.errorRed(brightness),
                                          fontSize: 12)),
                                ],
                                // BREAK损失摘要
                                if (_break50Count > 0 ||
                                    _break100Count > 0 ||
                                    _break80Count > 0 ||
                                    _break60Count > 0 ||
                                    _break50gCount > 0 ||
                                    _breakGoodCount > 0 ||
                                    _breakMissCount > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: Text(
                                              context.l10n.flowTotalBREAKLoss,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12))),
                                      Text(
                                          '${breakInputLoss.toStringAsFixed(4)}%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: breakInputLoss >= 2.0
                                                  ? AppColors.errorRed(
                                                      brightness)
                                                  : AppColors.warningOrange(
                                                      brightness))),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: Text(
                                              context
                                                  .l10n.flowRemainingBudgetSSS,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12))),
                                      Text(
                                          '${remainingBudget05.toStringAsFixed(4)}%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: remainingBudget05 <= 0
                                                  ? AppColors.errorRed(
                                                      brightness)
                                                  : AppColors.successGreen(
                                                      brightness))),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: Text(
                                              context
                                                  .l10n.flowRemainingBudgetSSS2,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12))),
                                      Text(
                                          '${remainingBudget10.toStringAsFixed(4)}%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: remainingBudget10 <= 0
                                                  ? AppColors.errorRed(
                                                      brightness)
                                                  : AppColors.successGreen(
                                                      brightness))),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: Text(
                                              context
                                                  .l10n.flowRemainingBudgetSS,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12))),
                                      Text(
                                          '${remainingBudget15.toStringAsFixed(4)}%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: remainingBudget15 <= 0
                                                  ? AppColors.errorRed(
                                                      brightness)
                                                  : AppColors.successGreen(
                                                      brightness))),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: Text(
                                              context
                                                  .l10n.flowRemainingBudgetSS2,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12))),
                                      Text(
                                          '${remainingBudget20.toStringAsFixed(4)}%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: remainingBudget20 <= 0
                                                  ? AppColors.errorRed(
                                                      brightness)
                                                  : AppColors.successGreen(
                                                      brightness))),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 损失部分：三列两行布局
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(context.l10n.flowGREATLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowGOODLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowMISSLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      '${greatLoss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text('${goodLoss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text('${missLoss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 容错部分 SSS+：三列两行布局
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowSSSGREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowSSSGOODAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowSSSMISSAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance05Great)
                                              .toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance05Great == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance05Good).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance05Good == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance05Miss).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance05Miss == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 容错部分 SSS：三列两行布局
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowSSSGREATAllowance2,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowSSSGOODAllowance2,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowSSSMISSAllowance2,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance10Great)
                                              .toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance10Great == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance10Good).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance10Good == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance10Miss).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance10Miss == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 容错部分 SS+：三列两行布局
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(context.l10n.flowSSGREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowSSGOODAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowSSMISSAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance15Great)
                                              .toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance15Great == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance15Good).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance15Good == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance15Miss).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance15Miss == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 容错部分 SS：三列两行布局
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowSSGREATAllowance2,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowSSGOODAllowance2,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowSSMISSAllowance2,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance20Great)
                                              .toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance20Great == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance20Good).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance20Good == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (adjustedTolerance20Miss).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (_break50Count > 0 ||
                                                      _break100Count > 0) &&
                                                  adjustedTolerance20Miss == 0
                                              ? AppColors.errorRed(brightness)
                                              : null),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ],

                        // BREAK音符特殊判定损失（仅当选中BREAK时显示）
                        if (_selectedNoteType == 'BREAK') ...[
                          // 损失部分
                          // 第一行：50落、100落
                          Row(
                            children: [
                              Expanded(
                                  child: Text(context.l10n.flow50PointLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flow100PointLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      '${break50Loss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      '${break100Loss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第三行：三种GREAT
                          Row(
                            children: [
                              Expanded(
                                  child: Text(context.l10n.flow80GREATLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flow60GREATLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flow50GREATLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第四行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      '${break80Loss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      '${break60Loss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      '${break50gLoss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第五行：GOOD、MISS
                          Row(
                            children: [
                              Expanded(
                                  child: Text(context.l10n.flowGOODLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(context.l10n.flowMISSLoss,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第六行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      '${breakGoLoss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text('${missLoss.toStringAsFixed(4)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 容错部分 -0.5%：三列两行布局（5项分2组）
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flow0580GREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flow0560GREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flow0550GREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance05Break80).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance05Break60).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance05Break50g).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第三行：标题
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(context.l10n.flow05Allowance,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                    Text('GOOD',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(context.l10n.flow05Allowance,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                    Text('MISS',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第四行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance05BreakGo).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n
                                          .flowP0((tolerance05Miss).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 容错部分 -1%：三列两行布局（5项分2组）
                          // 第一行：标题
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flow180GREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flow160GREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flow150GREATAllowance,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第二行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance10Break80).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance10Break60).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance10Break50g).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第三行：标题
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(context.l10n.flow1Allowance,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                    Text('GOOD',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(context.l10n.flow1Allowance,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                    Text('MISS',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 第四行：值
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      context.l10n.flowP0(
                                          (tolerance10BreakGo).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text(
                                      context.l10n
                                          .flowP0((tolerance10Miss).toString()),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建评级分布
  Widget _buildRatingDistribution(dynamic currentDiffData) {
    if (currentDiffData == null) return Container();
    final brightness = Theme.of(context).brightness;

    List<num> dist = currentDiffData is DiffData
        ? currentDiffData.dist
        : currentDiffData['dist'];
    if (dist.isEmpty) return Container();

    // 评级标签
    List<String> ratingLabels = [
      'D',
      'C',
      'B',
      'BB',
      'BBB',
      'A',
      'AA',
      'AAA',
      'S',
      'S+',
      'SS',
      'SS+',
      'SSS',
      'SSS+'
    ];

    // 确保dist长度与标签长度匹配
    if (dist.length > ratingLabels.length) {
      dist = dist.sublist(0, ratingLabels.length);
    } else if (dist.length < ratingLabels.length) {
      while (dist.length < ratingLabels.length) {
        dist.add(0);
      }
    }

    // 计算总数量
    num total = dist.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和展开收起按钮（整行可点击）
        InkWell(
          onTap: () {
            _update(() {
              _ratingDistributionExpanded = !_ratingDistributionExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.flowGradeDistributionReferenceOnly,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getAccentColor(_currentDiffIndex, brightness),
                  ),
                ),
                AnimatedRotation(
                  turns: _ratingDistributionExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more,
                      color: _getAccentColor(_currentDiffIndex, brightness)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 分布图表（根据展开状态显示）
                if (_ratingDistributionExpanded) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.tableBorder(brightness)),
                    ),
                    child: Column(
                      children: [
                        for (int i = ratingLabels.length - 1; i >= 0; i--)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(ratingLabels[i],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryText(
                                              brightness))),
                                  Text(
                                      '${dist[i]} / ${total > 0 ? ((dist[i] / total) * 100).toStringAsFixed(2) : '0.00'}%',
                                      style: TextStyle(
                                          color: AppColors.primaryText(
                                              brightness))),
                                ],
                              ),
                              SizedBox(height: 4),
                              SmoothLinearProgressIndicator(
                                value: dist[i] > 0 ? dist[i] / total : 0,
                                backgroundColor:
                                    AppColors.tableBorder(brightness),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getAccentColor(
                                        _currentDiffIndex, brightness)),
                                minHeight: 8,
                              ),
                              SizedBox(height: 12),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建连击分布
  Widget _buildComboDistribution(dynamic currentDiffData) {
    if (currentDiffData == null) return Container();
    final brightness = Theme.of(context).brightness;

    List<num> fcDist = currentDiffData is DiffData
        ? currentDiffData.fcDist
        : currentDiffData['fc_dist'];
    if (fcDist.isEmpty) return Container();

    // 连击标签
    List<String> comboLabels = [
      context.l10n.flowNone2,
      'FC',
      'FC+',
      'AP',
      'AP+'
    ];

    // 确保fcDist长度与标签长度匹配
    if (fcDist.length > comboLabels.length) {
      fcDist = fcDist.sublist(0, comboLabels.length);
    } else if (fcDist.length < comboLabels.length) {
      while (fcDist.length < comboLabels.length) {
        fcDist.add(0);
      }
    }

    // 计算总数量
    num total = fcDist.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和展开收起按钮（整行可点击）
        InkWell(
          onTap: () {
            _update(() {
              _comboDistributionExpanded = !_comboDistributionExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.flowComboDistributionReferenceOnly,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getAccentColor(_currentDiffIndex, brightness),
                  ),
                ),
                AnimatedRotation(
                  turns: _comboDistributionExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more,
                      color: _getAccentColor(_currentDiffIndex, brightness)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 分布图表（根据展开状态显示）
                if (_comboDistributionExpanded) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.tableBorder(brightness)),
                    ),
                    child: Column(
                      children: [
                        for (int i = comboLabels.length - 1; i >= 0; i--)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(comboLabels[i],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryText(
                                              brightness))),
                                  Text(
                                      '${fcDist[i].toInt()} / ${total > 0 ? ((fcDist[i] / total) * 100).toStringAsFixed(2) : '0.00'}%',
                                      style: TextStyle(
                                          color: AppColors.primaryText(
                                              brightness))),
                                ],
                              ),
                              SizedBox(height: 4),
                              SmoothLinearProgressIndicator(
                                value: fcDist[i] > 0 ? fcDist[i] / total : 0,
                                backgroundColor:
                                    AppColors.tableBorder(brightness),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getAccentColor(
                                        _currentDiffIndex, brightness)),
                                minHeight: 8,
                              ),
                              SizedBox(height: 12),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
