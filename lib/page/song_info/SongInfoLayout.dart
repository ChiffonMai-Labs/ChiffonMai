part of '../SongInfoPage.dart';

/// SongInfoPage · 2026-11 页面布局。
///
/// 结构（自上而下）：
/// 1. [_buildSongHero]：全出血难度色头图 —— 返回 / 笔记 / 收藏 / 分享、曲绘、标题、曲师、
///    类型 / 编号 / DX·ST 切换、别名、难度切换；
/// 2. [_buildBestScoreCard]：玩家最佳成绩（达成率 + 评级 + 连击同步 + 四项数值）；
/// 3. [_buildKeyStatsRow]：定数 / 拟合（含差值）/ 平均达成 / 时长；
/// 4. [_buildChartInfo]：基础信息、物量分布与绝赞、定数历史、谱面标签；
/// 5. [_buildDetailTabBar] + [_buildDetailTabContent]：成绩历史 / 数据 / 社区 / 工具；
/// 6. [_buildSongActionBar]：贴底操作栏（原两列十个按钮，常用三个 + 更多 + 主按钮）。
///
/// 各板块的**数据与交互逻辑沿用原实现**（统计项、物量、分布图、对照表、
/// 评分、评论、容错计算都直接调用原方法），这里只负责排版和外观。
extension _SongInfoLayout on _SongInfoPageState {
  // -------------------------------------------------------------------------
  // 交互
  // -------------------------------------------------------------------------

  /// 切换难度：与旧版难度标签页的点击逻辑一致。
  void _selectDifficulty(int index) {
    BiliSearchService().cancel();
    _update(() {
      _currentDiffIndex = index;
      _biliPlayCount = null;
      _biliPlayCountLoading = false;
      _biliBvid = null;
      _biliFromRedis = false;
      _biliFromUser = false;
    });
    _loadChartRating();
    _loadComments();
    _checkBookmarkStatus();
    _checkNoteStatus();
    _loadBiliPlayCount();
    _loadBest50Opportunity();
  }

  /// 点曲绘：放大查看并可保存到相册（与旧版一致）。
  void _showCoverDialog(dynamic basicInfo, Color accentColor) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          title: Text(basicInfo['title'].toString()),
          content: EntranceAnimation(
            duration: const Duration(milliseconds: 380),
            offset: Offset.zero,
            scaleFrom: 0.4,
            // Center 默认会撑满可用高度，这里只让它管水平居中。
            child: Center(
              heightFactor: 1,
              child: SizedBox(
                width: 250,
                height: 250,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium),
                  child: CoverUtil.buildCoverWidgetWithContext(
                      dialogContext, widget.songId.toString(), 300),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.featureClose),
            ),
            FilledButton(
              onPressed: () async {
                await _saveCoverToGallery(widget.songId.toString(),
                    basicInfo['title']?.toString() ?? 'cover');
              },
              child: Text(dialogContext.l10n.flowSaveToGallery),
            ),
          ],
        );
      },
    );
  }

  /// 「更多」操作面板：原按钮网格里不常用的几项。
  void _showMoreSongActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppSurfaces.card(context),
      builder: (sheetContext) {
        Widget item(IconData icon, String title, VoidCallback? onTap) {
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            enabled: onTap != null,
            onTap: onTap == null
                ? null
                : () {
                    Navigator.of(sheetContext).pop();
                    onTap();
                  },
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                item(Icons.ondemand_video_outlined,
                    context.l10n.flowOpenBilibili2, _jumpToBilibili),
                item(
                    Icons.leaderboard_outlined,
                    context.l10n.flowAchievementRanking2,
                    _viewAchievementRanking),
                item(Icons.emoji_events_outlined,
                    context.l10n.flowDXScoreRanking2, _viewDxScoreRanking),
                item(
                    Icons.collections_bookmark_outlined,
                    context.l10n.flowRelatedCollectiblesP0(
                        (_relatedCollectionsCount).toString()),
                    _viewRelatedCollectibles),
                item(
                    Icons.playlist_add_outlined,
                    context.l10n.flowAddToPlayNext,
                    _isLoading ? null : _addToNextPlayQueue),
                item(
                    Icons.image_outlined,
                    context.l10n.flowExportSongInformation,
                    _exportSongInfoToImage),
                item(Icons.calculate_outlined, context.l10n.featureCalculators2,
                    _openCalculator),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 达成率 → 评级文字（与达成率计算器使用同一组下限）。
  String _rankLabelFor(double achievement) {
    const tiers = <(double, String)>[
      (100.5, 'SSS+'),
      (100.0, 'SSS'),
      (99.5, 'SS+'),
      (99.0, 'SS'),
      (98.0, 'S+'),
      (97.0, 'S'),
      (94.0, 'AAA'),
      (90.0, 'AA'),
      (80.0, 'A'),
      (75.0, 'BBB'),
      (70.0, 'BB'),
      (60.0, 'B'),
      (50.0, 'C'),
    ];
    for (final (threshold, label) in tiers) {
      if (achievement >= threshold) return label;
    }
    return 'D';
  }

  /// 头图底色：当前难度强调色压暗，保证白字对比度。
  Color _heroColor(Color accentColor) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Color.lerp(accentColor, Colors.black, dark ? 0.5 : 0.3)!;
  }

  // -------------------------------------------------------------------------
  // 1. 头图
  // -------------------------------------------------------------------------

  Widget _buildSongHero(dynamic basicInfo, dynamic levels, Color accentColor,
      Map<String, dynamic>? userRecord) {
    final title = basicInfo['title'].toString();
    final artist = basicInfo['artist']?.toString() ?? '';

    Widget circleButton({
      required String tooltip,
      required Widget icon,
      required VoidCallback onPressed,
    }) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            foregroundColor: Colors.white,
            fixedSize: const Size(44, 44),
          ),
          icon: icon,
        );

    return AnimatedContainer(
      duration: AppDesignTokens.motion(context, AppDesignTokens.slowMotion),
      curve: AppDesignTokens.emphasizedCurve,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.paddingOf(context).top + 4, 16, 44),
      decoration: BoxDecoration(
        color: _heroColor(accentColor),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.3, 1],
          colors: [
            _heroColor(accentColor),
            Color.lerp(_heroColor(accentColor), Colors.black, 0.32)!,
          ],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                circleButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                circleButton(
                  tooltip: _hasNote
                      ? context.l10n.flowViewNotes
                      : context.l10n.flowAddNotes,
                  icon: Icon(_hasNote ? Icons.note : Icons.note_add_outlined,
                      size: 20),
                  onPressed: () => _showNoteDialog(),
                ),
                const SizedBox(width: 8),
                circleButton(
                  tooltip: _isBookmarked
                      ? context.l10n.flowFavorited
                      : context.l10n.flowAddToAFavoritesFolder,
                  // 收藏状态变化时心跳一下
                  icon: TweenAnimationBuilder<double>(
                    key: ValueKey(_isBookmarked),
                    tween: Tween(begin: 0, end: 1),
                    duration: AppDesignTokens.motion(
                        context, const Duration(milliseconds: 400)),
                    builder: (context, t, child) => Transform.scale(
                      scale: t < 0.4
                          ? 1 + 0.35 * (t / 0.4)
                          : 1 + 0.35 * ((1 - t) / 0.6),
                      child: child,
                    ),
                    child: Icon(
                        _isBookmarked ? Icons.favorite : Icons.favorite_border,
                        size: 20),
                  ),
                  onPressed: () => _showBookmarkDialog(),
                ),
                const SizedBox(width: 8),
                circleButton(
                  tooltip: userRecord == null
                      ? context.l10n.flowExportSongInformation
                      : context.l10n.flowShareScore,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  onPressed: () {
                    if (userRecord == null) {
                      _exportSongInfoToImage();
                    } else {
                      _shareScoreCard(
                        userRecord: userRecord,
                        basicInfo: basicInfo,
                        levels: levels,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FadeSwitcher(
                  value: 'cover-${widget.songId}',
                  child: _buildHeroCover(basicInfo, accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSwitcher(
                        value: 'title-${widget.songId}',
                        child: _buildHeroTitle(title),
                      ),
                      if (artist.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () =>
                              _showStatDialog(context.l10n.flowArtist, artist),
                          child: MarqueeText(
                            text: artist,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      FadeSwitcher(
                        value: 'type-${widget.songId}',
                        child: _buildHeroTypeRow(),
                      ),
                      const SizedBox(height: 6),
                      _buildAliasSection(title),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildDifficultySelector(levels),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCover(dynamic basicInfo, Color accentColor) {
    final size =
        (MediaQuery.sizeOf(context).width * 0.3).clamp(96.0, 128.0).toDouble();
    return Semantics(
      button: true,
      label: context.l10n.flowEnlargeCoverArt,
      child: GestureDetector(
        onTap: () => _showCoverDialog(basicInfo, accentColor),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusMedium),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CoverUtil.buildCoverWidgetWithContext(
                      context, widget.songId.toString(), 120),
                ),
              ),
              if (widget.songId == '11820' || widget.songId == '11821')
                Positioned(
                  top: -2,
                  left: -14,
                  child: Image.asset(
                    'assets/cover/UI_Long_Song.webp',
                    width: size * 0.53,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 歌名：放得下就静态显示，放不下才横向滚动；点按查看完整标题。
  Widget _buildHeroTitle(String title) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => SongTitleDialog(title: title),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final style = DefaultTextStyle.of(context).style.merge(
                const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              );
          final painter = TextPainter(
            text: TextSpan(text: title, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(minWidth: 0, maxWidth: double.infinity);
          final fits = painter.width <= constraints.maxWidth;
          final height = painter.height;
          painter.dispose();
          if (fits) {
            return Text(
              title,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }
          return SizedBox(
            height: height,
            child: Marquee(
              text: title,
              style: style,
              scrollAxis: Axis.horizontal,
              blankSpace: 24.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  /// 类型标签（DX / ST / 宴）+ 曲目编号 + 另一种谱面的切换入口。
  Widget _buildHeroTypeRow() {
    final isUtage = widget.songId.length == 6;
    final type = _songData!['type'];
    final label =
        isUtage ? ChartDifficulty.utageLabel : (type == 'SD' ? 'ST' : '$type');
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final labelColor = isUtage
        ? (dark ? const Color(0xFFFF8FB1) : const Color(0xFFB0164A))
        : type == 'SD'
            ? (dark ? const Color(0xFF8FC1FF) : const Color(0xFF1F5FA8))
            : (dark ? const Color(0xFFFFB877) : const Color(0xFFA34E00));
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: dark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTheme.number(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ),
        Text(
          '#${widget.songId}',
          style: AppTheme.number(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        // 如果存在另一种谱面，显示切换按钮
        if (_alternativeSongId != null)
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _switchSong(_alternativeSongId!, _currentDiffIndex),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _songSwitching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.8, color: Colors.white),
                          )
                        : const Icon(Icons.swap_horiz_rounded,
                            size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      type == 'SD'
                          ? context.l10n.flowSwitchToDX
                          : context.l10n.flowSwitchToST,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 难度切换：每个难度一块按钮，选中的变成白底；圆点是该难度的颜色。
  Widget _buildDifficultySelector(dynamic levels) {
    final brightness = Theme.of(context).brightness;
    final count = (levels as List).length;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: PressScale(
              scale: 0.94,
              child:
                  _buildDifficultyButton(i, levels[i].toString(), brightness),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDifficultyButton(
      int index, String level, Brightness brightness) {
    final selected = index == _currentDiffIndex;
    final dot = _getAccentColor(index, brightness);
    final dark = brightness == Brightness.dark;
    // 深色下选中块用深色底配提亮的难度色，不用刺眼的白块。
    final selectedFg = Color.lerp(
        _getAccentColor(_currentDiffIndex, brightness),
        dark ? Colors.white : Colors.black,
        dark ? 0.45 : 0.35)!;
    final fg = selected ? selectedFg : Colors.white;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n
          .flowP0LevelP1((_getDiffLabel(index)).toString(), (level).toString()),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
        curve: AppDesignTokens.emphasizedCurve,
        decoration: BoxDecoration(
          color: selected
              ? (dark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : Colors.white)
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: () => _selectDifficulty(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          const {
                                'BASIC': 'BAS',
                                'ADVANCED': 'ADV',
                                'EXPERT': 'EXP',
                                'MASTER': 'MAS',
                                'Re:MASTER': 'ReM',
                              }[_getDiffLabel(index)] ??
                              _getDiffLabel(index),
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level,
                    style: AppTheme.number(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. 玩家最佳成绩
  // -------------------------------------------------------------------------

  Widget _buildBestScoreCard(
      Map<String, dynamic>? userRecord, dynamic basicInfo, dynamic levels) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final title = context.l10n
        .flowMyScoreP0((_getDiffLabel(_currentDiffIndex)).toString());
    final plays = _currentPlayCount == null
        ? ''
        : context.l10n.flowPlayedP0Times((_currentPlayCount!).toString());
    // AnimatedSize 不能用 Duration.zero：子项尺寸一变，它会在自己的布局过程里
    // 同步把动画跑完并再次标脏（框架断言「mutated in its own performLayout」）。
    // 不需要过渡时用 1 微秒代替，下一帧直接到位，观感与「无动画」相同。
    const instant = Duration(microseconds: 1);
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    final sizeMotion = motion == Duration.zero ? instant : motion;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FadeSwitcher(
                  value: title,
                  child: Text(
                    title,
                    style: muted.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              FadeSwitcher(
                value: plays,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(plays, style: muted),
              ),
            ],
          ),
          const SizedBox(height: 1),
          AnimatedSize(
            duration: sizeMotion,
            curve: AppDesignTokens.emphasizedCurve,
            alignment: Alignment.topCenter,
            // 有成绩 ↔ 有成绩之间 Key 不变，数字才能从旧值滚到新值。
            child: FadeSwitcher(
              value: userRecord != null,
              alignment: AlignmentDirectional.topStart,
              sizeFollowsCurrent: true,
              child: userRecord != null
                  ? _buildBestScoreBody(userRecord)
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 难度名长短不一，放不下时整行缩小，避免末字单独换行。
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.l10n.flowNoScoreForP0Yet(
                                      (_getDiffLabel(_currentDiffIndex))
                                          .toString()),
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(context.l10n.flowPlayAndSyncToSeeYourScore,
                                  style: muted),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isLoading ? null : _addToNextPlayQueue,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppSurfaces.inset(context),
                            foregroundColor: scheme.onSurface,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            textStyle: AppTheme.font(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: Text(context.l10n.flowAddToPlayNext),
                        ),
                      ],
                    ),
            ),
          ),
          AnimatedSize(
            // 进入页面时结果是异步到达的，首次显示不做展开，之后切难度才过渡。
            duration: _best50OpportunitySettled ? sizeMotion : instant,
            curve: AppDesignTokens.emphasizedCurve,
            alignment: Alignment.topCenter,
            child: _best50OpportunityText == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _buildBest50OpportunityBanner(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestScoreBody(Map<String, dynamic> userRecord) {
    final scheme = Theme.of(context).colorScheme;
    final songIdInt = int.parse(widget.songId);
    final achievement = (userRecord['achievements'] as num).toDouble();
    final int dxScore = (userRecord['dxScore'] as num).toInt();
    final maxDx = _calculateMaxDxScore(songIdInt, _currentDiffIndex);
    final fc = (userRecord['fc'] ?? '').toString();
    final fs = (userRecord['fs'] ?? '').toString();
    final rank = _rankLabelFor(achievement);
    final starsText = _showNextStarDiff
        ? _calculateNextStarDiff(songIdInt, _currentDiffIndex, dxScore)
        : _calculateStarsBonus(songIdInt, _currentDiffIndex, dxScore);
    final statStyle = AppTheme.number(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 两个数字字号不同，按盒子底边对齐时字的下沿对不齐，所以按基线对齐。
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RollingNumber(
                  value: achievement,
                  fractionDigits: 4,
                  suffix: '%',
                  style: AppTheme.number(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Column 的基线取第一个子项：倒序排列，让参与对齐的是数值而不是上方的标签。
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              verticalDirection: VerticalDirection.up,
              children: [
                RollingNumber(
                  value: userRecord['ra'] as num,
                  style: AppTheme.number(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
                Text('Rating',
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 评级，连击，同步
        FadeSwitcher(
          value: '$rank|$fc|$fs',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              RankBadge(rank: rank, uniformWidth: true),
              if (fc.isNotEmpty) _buildBadge(fc),
              if (fs.isNotEmpty) _buildBadge(fs),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // DX分数 / DX分数达成率
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatTile(
                // 异常成绩可能超过上限，差值为负时显示「MAX +n」
                label: dxScore > maxDx
                    ? context.l10n
                        .flowDXScoreMAXOverP0((dxScore - maxDx).toString())
                    : context.l10n
                        .flowDXScoreMAXP0((maxDx - dxScore).toString()),
                value: '$dxScore / $maxDx',
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RollingNumber(value: dxScore, style: statStyle),
                    Text(' / ', style: statStyle),
                    RollingNumber(value: maxDx, style: statStyle),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: _showNextStarDiff
                    ? context.l10n.flowShowStarBonus
                    : context.l10n.flowShowPointsNeededForTheNextStar,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      _update(() => _showNextStarDiff = !_showNextStarDiff),
                  child: StatTile(
                    label: context.l10n.flowDXScoreRate,
                    value: '${(dxScore / maxDx * 100).toStringAsFixed(2)}%',
                    valueWidget: RollingNumber(
                      value: dxScore / maxDx * 100,
                      fractionDigits: 2,
                      suffix: '%',
                      style: statStyle,
                    ),
                    trailing: FadeSwitcher(
                      value: starsText,
                      child: Text(
                        starsText,
                        style: AppTheme.number(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _getStarsColor(
                                _calculateStars(
                                    songIdInt, _currentDiffIndex, dxScore),
                                scheme.brightness)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 成绩超出谱面上限：说明原因，提示不会上传到排行榜
        if (_illegalScoreReasons(achievement, dxScore, maxDx)
            case final reasons when reasons.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildIllegalScoreNotice(reasons),
        ],
      ],
    );
  }

  /// 与排行榜守卫同一口径：Buddy 宴谱（ds 长度为 2）达成率上限 202，其余 101；
  /// DX 分只检查常规谱（宴谱物量数据不可靠，服务端同样不查）；
  /// 谱面国服上线日期（落雪 release_date）晚于今天（北京时间）时也视为异常。
  List<String> _illegalScoreReasons(
      double achievement, int dxScore, int maxDx) {
    final isUtage = widget.songId.length >= 6;
    final isBuddy = isUtage && (_songData?['ds'] as List?)?.length == 2;
    final cap = isBuddy ? 202 : 101;
    return [
      if (achievement > cap)
        context.l10n.songScoreIllegalAchievement(cap.toString()),
      if (!isUtage && maxDx > 0 && dxScore > maxDx)
        context.l10n.songScoreIllegalDx(maxDx.toString()),
      if (_unreleasedChartDate() case final date?)
        context.l10n.songScoreIllegalUnreleased(date),
    ];
  }

  /// 当前谱面尚未在国服上线时返回上线日期，否则返回 null。
  String? _unreleasedChartDate() {
    final date = _cnChartReleaseDates[_currentDiffIndex] ?? _cnReleaseDate;
    if (date == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return null;
    }
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return date.compareTo(today) > 0 ? date : null;
  }

  Widget _buildIllegalScoreNotice(List<String> reasons) {
    final color = AppColors.warningOrange(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.songScoreIllegalWarning(reasons.join('、')),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 上分潜力：成绩卡底部的凹槽，左边说明、右边能加多少分。
  Widget _buildBest50OpportunityBanner() {
    final scheme = Theme.of(context).colorScheme;
    final brightness = scheme.brightness;
    final text = _best50OpportunityText!;
    final gain = _best50OpportunityGain;
    final positive = gain != null && gain > 0;
    final tiers = _best50OpportunityTiers;
    final banner = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.flowRatingPotential,
                  style: AppTheme.number(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                FadeSwitcher(
                  value: text,
                  child: Text(
                    text,
                    style: AppTheme.number(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (gain != null) ...[
            const SizedBox(width: 12),
            RollingNumber(
              value: gain,
              prefix: '+',
              style: AppTheme.number(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: positive
                    ? AppColors.successGreen(brightness)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (tiers.isNotEmpty) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    if (tiers.isEmpty) return banner;
    return PressScale(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showBest50OpportunityDialog(
            context,
            note: _best50OpportunityNote,
            tiers: tiers,
          ),
          child: banner,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 4. 关键数值
  // -------------------------------------------------------------------------

  Widget _buildKeyStatsRow(dynamic currentDiffData) {
    final brightness = Theme.of(context).brightness;
    final ds = (_songData!['ds'][_currentDiffIndex] as num).toDouble();
    double? fit;
    double? avg;
    if (currentDiffData != null) {
      fit = currentDiffData is DiffData
          ? currentDiffData.fitDiff.toDouble()
          : (currentDiffData['fit_diff'] as num).toDouble();
      avg = currentDiffData is DiffData
          ? currentDiffData.avg.toDouble()
          : (currentDiffData['avg'] as num).toDouble();
    }
    final diff = fit == null ? null : fit - ds;

    final onSurface = Theme.of(context).colorScheme.onSurface;
    // 有数值的格子切难度时数字滚动，没有数值时显示「-」。
    Widget tile(String label, String value,
            {Color? color,
            double? number,
            int digits = 1,
            String suffix = ''}) =>
        Expanded(
          child: StatTile(
            label: label,
            value: value,
            valueColor: color,
            card: true,
            centered: true,
            valueSize: 16,
            valueWidget: number == null
                ? null
                : RollingNumber(
                    value: number,
                    fractionDigits: digits,
                    suffix: suffix,
                    style: AppTheme.number(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color ?? onSurface,
                    ),
                  ),
          ),
        );

    return Row(
      children: [
        tile(context.l10n.flowConstant, ds.toStringAsFixed(1), number: ds),
        const SizedBox(width: 8),
        tile(
          diff == null
              ? context.l10n.featureFitted
              : context.l10n.flowFittedP0P1((diff >= 0 ? "+" : "").toString(),
                  (diff.toStringAsFixed(2)).toString()),
          fit == null ? '-' : fit.toStringAsFixed(2),
          number: fit,
          digits: 2,
          color: diff == null
              ? null
              : (diff < 0
                  ? AppColors.successGreen(brightness)
                  : AppColors.errorRed(brightness)),
        ),
        const SizedBox(width: 8),
        tile(context.l10n.flowAvgAchievement,
            avg == null ? '-' : '${avg.toStringAsFixed(2)}%',
            number: avg, digits: 2, suffix: '%'),
        const SizedBox(width: 8),
        tile(context.l10n.flowDuration3, _formatReferenceDuration()),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 5. 标签页
  // -------------------------------------------------------------------------

  Widget _buildDetailTabBar(Color accentColor) {
    return UnderlineTabs(
      labels: [
        context.l10n.songTabHistory,
        context.l10n.flowData,
        context.l10n.songTabCommunity,
        context.l10n.flowTools
      ],
      selectedIndex: _detailTab,
      indicatorColor: _heroColor(accentColor),
      onChanged: (index) => _update(() => _detailTab = index),
    );
  }

  Widget _buildDetailTabContent({
    required Widget chartHistory,
    required dynamic currentDiffData,
    required Color accentColor,
  }) {
    final List<Widget> children;
    switch (_detailTab) {
      case 1:
        children = _buildDataTab(currentDiffData);
        break;
      case 2:
        children = [
          // 谱面评分
          _buildChartRatingSection(accentColor),
          const SizedBox(height: 12),
          // 评论区
          _buildCommentsSection(),
        ];
        break;
      case 3:
        children = _buildToolsTab();
        break;
      default:
        children = [chartHistory];
    }
    return AnimatedSwitcher(
      duration: AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
      switchInCurve: AppDesignTokens.emphasizedCurve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previous,
          if (current != null) current,
        ],
      ),
      child: Column(
        key: ValueKey<int>(_detailTab),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// 谱面信息：物量分布与绝赞 → 基础信息 → 定数历史 → 谱面标签。
  List<Widget> _buildChartInfo(
      dynamic basicInfo, dynamic currentChart, Color accentColor) {
    final scheme = Theme.of(context).colorScheme;
    final noteCounts = _getNoteCounts(currentChart);
    final totalNotes = noteCounts.fold<int>(0, (sum, n) => sum + n);
    final hasDxHistory = _buildDxHistory().isNotEmpty;
    const noteOrder = <(String, int)>[
      ('TAP', 0),
      ('HOLD', 1),
      ('SLIDE', 2),
      ('BREAK', 4),
      ('TOUCH', 3),
    ];
    final breakLabels = [
      context.l10n.flowTrueBREAKTAP,
      context.l10n.flowTrueBREAKHOLD,
      context.l10n.flowProtectedBREAK,
      context.l10n.flowBREAKStar
    ];
    final ordered = [for (final n in noteOrder) noteCounts[n.$2]];
    // 没有解析结果时是「-」，不计入比例条
    final breakCounts = [
      for (var i = 0; i < breakLabels.length; i++)
        int.tryParse(_getBreakCountDisplay(i)),
    ];
    final breakValues = [for (final c in breakCounts) c ?? 0];
    final totalBreaks = breakValues.fold<int>(0, (sum, n) => sum + n);
    final protectionStats = _maidataProtectionStats[_currentDiffIndex];

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: context.l10n.flowBasicInformation,
              padding: EdgeInsets.only(bottom: 12),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem(context.l10n.flowCategory2, basicInfo['genre']),
                _buildVersionStat(basicInfo),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBpmStat(basicInfo),
                _buildReleaseDateStat(basicInfo),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem(context.l10n.flowCharter,
                    currentChart['charter']?.toString() ?? '-'),
                _buildBiliPlayCountStat(),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [_buildPlayableRegionStat(context)]),
          ],
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: context.l10n.flowNoteDistribution,
              padding: const EdgeInsets.only(bottom: 10),
              trailing: RollingNumber(
                value: totalNotes,
                prefix: context.l10n.flowTotal,
                style: AppTheme.number(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            // 比例条（优先使用Maidata解析的物量统计）
            _buildDistributionBar(ordered, AppColors.noteDistribution),
            const SizedBox(height: 10),
            _buildDistributionLegend(
              [for (final n in noteOrder) n.$1],
              ordered,
              AppColors.noteDistribution,
              dotOffsetY: 0.5,
            ),
            // 全部缺少解析数据时，标题、比例条和图例一起隐藏。
            if (breakCounts.any((count) => count != null)) ...[
              const SizedBox(height: 16),
              AppSectionHeader(
                title: context.l10n.flowBREAKDistribution,
                padding: const EdgeInsets.only(bottom: 10),
                trailing: RollingNumber(
                  value: totalBreaks,
                  prefix: context.l10n.flowTotal,
                  style: AppTheme.number(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              _buildDistributionBar(breakValues, AppColors.breakDistribution),
              const SizedBox(height: 10),
              _buildDistributionLegend(
                breakLabels,
                breakCounts,
                AppColors.breakDistribution,
              ),
            ],
            _buildProtectionDistributions(protectionStats, breakCounts),
          ],
        ),
      ),
      // 定数历史（横向滑动表格）；没有历史数据时整块不占位
      if (hasDxHistory) ...[
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: _buildDxHistoryTable(),
        ),
      ],
      const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _buildTagsSection(accentColor),
      ),
    ];
  }

  /// 标签页「数据」：全站评级 / 连击分布、星级与达成率对照表。
  List<Widget> _buildDataTab(dynamic currentDiffData) {
    final scheme = Theme.of(context).colorScheme;
    final hasRating = _hasDistributionData(currentDiffData, false);
    final hasCombo = _hasDistributionData(currentDiffData, true);
    return [
      // 评级分布
      if (hasRating) ...[
        AppCard(child: _buildRatingDistribution(currentDiffData)),
        const SizedBox(height: 12),
      ],
      // 连击分布
      if (hasCombo) ...[
        AppCard(child: _buildComboDistribution(currentDiffData)),
        const SizedBox(height: 12),
      ],
      if (!hasRating && !hasCombo) ...[
        AppCard(
          child: Text(
            context.l10n.flowNoGlobalGradeOrComboDistributionData,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
      ],
      // 星星等级最低DX分对照表
      AppCard(child: _buildStarScoreTable()),
      const SizedBox(height: 12),
      // 达成率-得分对照表
      AppCard(
        child: ListenableBuilder(
          listenable: RatingSegmentPreferences.instance,
          builder: (context, _) => _buildAchievementScoreTable(),
        ),
      ),
    ];
  }

  /// 标签页「工具」：容错计算 + 计算工具入口。
  List<Widget> _buildToolsTab() {
    final scheme = Theme.of(context).colorScheme;
    final counts = _getNoteCounts(_songData!['charts'][_currentDiffIndex]);
    final weight = counts[0] * _tapWeight +
        counts[1] * _holdWeight +
        counts[2] * _slideWeight +
        counts[3] * _touchWeight +
        counts[4] * _breakWeight;
    // 一个 TAP GREAT 丢掉的达成率（百分点）
    final tapGreatLoss = weight == 0 ? 0.0 : 0.2 * _tapWeight / weight * 100;
    Widget toleranceTile(String label, double margin) => Expanded(
          child: AppCard(
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('${(margin / tapGreatLoss).floor()}',
                    style: AppTheme.number(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
                Text(context.l10n.flowTAPGREATsAllBREAKsCriticalPerfect,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
    return [
      // 容错速览（宴谱的达成率口径不同，不显示）
      if (tapGreatLoss > 0 && widget.songId.length != 6) ...[
        Row(
          children: [
            toleranceTile(context.l10n.flowSSSAllowance, 0.5),
            const SizedBox(width: 10),
            toleranceTile(context.l10n.flowSSSAllowance2, 1.0),
          ],
        ),
        const SizedBox(height: 12),
      ],
      // 容错计算
      AppCard(child: _buildToleranceCalculation()),
      const SizedBox(height: 12),
      AppCard(
        onTap: _openCalculator,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Icon(Icons.calculate_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.featureCalculators2,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(context.l10n.flowOpenCalculatorWithThisChartSNotes,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    ];
  }

  /// 谱面标签(仅供参考)：常驻展开，点标签弹出说明。
  Widget _buildTagsSection(Color accentColor) {
    final brightness = Theme.of(context).brightness;
    final groupedTags = _getTagsByGroup();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            context.l10n.flowChartTagsReferenceOnly,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // 不分行显示分类，所有标签按顺序铺开，满了换行
        if (groupedTags.values.every((tags) => tags.isEmpty))
          Text(
            context.l10n.flowNoTagsYet,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in groupedTags.entries)
                for (final tag in group.value)
                  _buildTagChip(tag, group.key, brightness),
            ],
          ),
        const SizedBox(height: 12),
        _buildCustomTagsRow(),
      ],
    );
  }

  /// 当前谱面的自定义标签：用户颜色显示，末尾一个入口可增删标签。
  CustomTagChart? _currentCustomTagChart() {
    final data = _songData;
    final title = data?['basic_info']?['title']?.toString() ?? '';
    if (data == null || title.isEmpty) return null;
    return CustomTagChart(
      songId: widget.songId,
      title: title,
      sheetType:
          CustomTagChart.sheetTypeOf(widget.songId, data['type']?.toString() ?? ''),
      levelIndex: _currentDiffIndex,
    );
  }

  Widget _buildCustomTagsRow() {
    final chart = _currentCustomTagChart();
    if (chart == null) return const SizedBox.shrink();
    final store = CustomTagStore.instance;
    store.ensureLoaded();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tags = store.tagsOf(chart.songId, chart.levelIndex);
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.customTagTitle,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final tag in tags)
                  CustomTagChip(
                    name: tag.name,
                    color: tag.color,
                    onTap: () => showCustomTagChartSheet(context, chart),
                  ),
                CustomTagChip(
                  name: tags.isEmpty
                      ? context.l10n.customTagAddToChart
                      : context.l10n.customTagManage,
                  color: scheme.primary.toARGB32(),
                  icon: tags.isEmpty ? Icons.add_rounded : Icons.tune_rounded,
                  onTap: () => showCustomTagChartSheet(context, chart),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagChip(dynamic tag, String groupKey, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        final description = tag['description']?.toString();
        if (description == null || description.isEmpty) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AppAlertDialog(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag['name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11),
                    children: [
                      TextSpan(
                        text: context.l10n.flowTagDataFrom,
                        style: TextStyle(color: AppColors.greyHint(brightness)),
                      ),
                      TextSpan(
                        text: 'https://dxrating.net/',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final uri = Uri.parse('https://dxrating.net/');
                            await ExternalLaunchUtil.open(uri);
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(context.l10n.featureClose),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _getTagColor(groupKey),
          border: Border.all(color: _getTagBorderColor(groupKey), width: 1),
        ),
        child: Text(
          tag['name']?.toString() ?? context.l10n.flowUnknownTag,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getTagTextColor(groupKey),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 6. 贴底操作栏
  // -------------------------------------------------------------------------

  Widget _buildSongActionBar(Color accentColor) {
    final scheme = Theme.of(context).colorScheme;

    Widget iconAction(IconData icon, String label, VoidCallback? onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Material(
            color: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: scheme.onSurface),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(fontSize: 10.5, color: scheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BottomActionBar(
      children: [
        iconAction(
            Icons.music_note_rounded, context.l10n.flowPreview, _playMusic),
        iconAction(Icons.play_circle_outline_rounded, 'PV', _playPv),
        iconAction(Icons.more_horiz_rounded, context.l10n.flowMore,
            _showMoreSongActions),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _viewMaidata,
              style: FilledButton.styleFrom(
                backgroundColor: _heroColor(accentColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium),
                ),
                textStyle:
                    AppTheme.font(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.code_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(context.l10n.flowViewChartCode,
                    maxLines: 1, softWrap: false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
