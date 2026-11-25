part of '../SongInfoPage.dart';

/// SongInfoPage · 小部件：统计项、物量格、徽章、别名
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoWidgets on _SongInfoPageState {
  /// [value] 已经是「谱面：x」「基准：y」两行，不再另加标签。
  Widget _buildBpmDialogContent(
    BuildContext context,
    String value,
    List<double> fallbackValues,
    AsyncSnapshot<List<ChartBpmSegment>> snapshot,
  ) {
    final segments = snapshot.data ?? const <ChartBpmSegment>[];
    final values = segments.isEmpty
        ? fallbackValues
        : segments.map((segment) => segment.bpm).toList(growable: false);
    final hasTimeline = segments.isNotEmpty;
    final loading = snapshot.connectionState == ConnectionState.waiting;
    final scheme = Theme.of(context).colorScheme;

    Widget cell(Widget child, {int flex = 1}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        );

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (hasTimeline || values.length > 1) ...[
            const SizedBox(height: 12),
            if (!hasTimeline)
              Text(context.l10n.flowInTheOrderBPMMarkersAppearIn),
            SizedBox(
              height: 36,
              child: Row(children: [
                cell(Text(context.l10n.flowChangeIndex)),
                cell(const Text('BPM')),
                if (hasTimeline)
                  cell(Text(context.l10n.chartBpmTimeRange), flex: 2),
              ]),
            ),
            Flexible(
              child: SizedBox(
                height: values.length * 40.0,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemExtent: 40,
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final bpm = values[index];
                    final segment = hasTimeline ? segments[index] : null;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      child: Row(children: [
                        cell(Text('${index + 1}')),
                        cell(_valueWithDirection(
                          _formatBpm(bpm),
                          index == 0 ? null : bpm.compareTo(values[index - 1]),
                          displayContext: context,
                        )),
                        if (segment != null)
                          cell(
                            Text(
                              '${_formatBpmChartTime(segment.startSeconds)}'
                              ' – ${_formatBpmChartTime(segment.endSeconds)}',
                              style: AppTheme.number(fontSize: 12),
                            ),
                            flex: 2,
                          ),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBpmChartTime(double seconds) {
    final milliseconds = (seconds * 1000).round();
    final minutes = milliseconds ~/ 60000;
    final wholeSeconds = (milliseconds ~/ 1000 % 60).toString().padLeft(2, '0');
    final fraction = (milliseconds % 1000).toString().padLeft(3, '0');
    return '$minutes:$wholeSeconds.$fraction';
  }

  /// 平均物量密度：总物量 ÷ 参考时长，与左侧「谱师」同属当前难度核心谱面特征。
  Widget _buildNoteDensityStat(dynamic currentChart) {
    final totalNotes = _getNoteCounts(currentChart).fold<int>(0, (s, n) => s + n);
    final seconds = _referenceDurationSeconds;
    final String display;
    if (seconds == null) {
      display = _referenceDurationLoading ? '...' : '-';
    } else if (seconds <= 0 || totalNotes <= 0) {
      display = '-';
    } else {
      display = '${(totalNotes / seconds).toStringAsFixed(2)} /s';
    }
    final detail = (seconds != null && seconds > 0 && totalNotes > 0)
        ? context.l10n.songAvgNoteDensityDetail(
            '$totalNotes',
            _formatReferenceDuration(),
            (totalNotes / seconds).toStringAsFixed(2),
          )
        : display;
    return _buildStatItem(
      context.l10n.songAvgNoteDensity,
      display,
      scrollable: false,
      dialogValue: detail,
    );
  }

  /// 版本：国服曲目同时显示国服和日服版本；日服版本来自 union 全量歌曲。
  Widget _buildVersionStat(dynamic basicInfo) {
    final cnVersion = StringUtil.formatVersion2WithFlag(
        basicInfo['from'], _usesExtraVersionName);
    final jpFrom = _songData?['type'] == 'DX' ? _unionDxFrom : _unionFrom;
    if (_isExtraSong || jpFrom == null || jpFrom.isEmpty) {
      return _buildStatItem(context.l10n.flowVersion, cnVersion,
          scrollable: false);
    }
    // 年号是国服的叫法，日服版本用世代名。
    final jpVersion = StringUtil.formatVersion2WithFlag(jpFrom, true);
    return _buildRegionStat(context.l10n.flowVersion, [
      (context.l10n.flowChina, cnVersion),
      (context.l10n.flowJapan, jpVersion)
    ]);
  }

  /// 首次上线：国服来自落雪，日服来自 union；没上国服的歌只有日服一行。
  Widget _buildReleaseDateStat(dynamic basicInfo) {
    final cnDate = _cnReleaseDate;
    final jpDate = _formatReleaseDate(basicInfo['release_date'] ?? '');
    final cnTime = cnDate == null ? null : DateTime.tryParse(cnDate);
    final jpTime = DateTime.tryParse(jpDate);
    final gap = cnTime == null || jpTime == null
        ? ''
        : context.l10n.flowP0DaysApart(
            (cnTime.difference(jpTime).inDays.abs()).toString());
    return _buildRegionStat(context.l10n.flowFirstReleaseP0((gap).toString()), [
      if (cnDate != null) (context.l10n.flowChina, cnDate),
      (context.l10n.flowJapan, jpDate),
    ]);
  }

  /// BPM：谱面 BPM 和基准固定分两行。
  Widget _buildBpmStat(dynamic basicInfo) {
    return _buildRegionStat('BPM', [
      (context.l10n.detailChartBpm, _displayBpm(basicInfo)),
      (context.l10n.flowBase, _defaultBpm(basicInfo)),
    ]);
  }

  /// 分行显示的统计项：每行一个小标签（国服 / 日服、谱面 / 基准）加内容。
  Widget _buildRegionStat(String label, List<(String, String)> rows,
      {bool scrollable = false}) {
    final scheme = Theme.of(context).colorScheme;
    // 内容默认不滚动也不换行，放不下时缩小字号；传 scrollable: true 时保持原字号并用跑马灯滚动。
    // 小标签和文字都按中线摆放：标签在固定行高里居中，文字的字形中线（基线上方约 0.36 个字号，实测）
    // 落在同一高度，不依赖字体的行高；按基线对齐时标签底块会偏下。
    const valueSize = 15.0;
    final scaledSize = MediaQuery.textScalerOf(context).scale(valueSize);
    final lineHeight = scaledSize * 1.3;
    const tagFontSize = 10.0;
    final tagSize = MediaQuery.textScalerOf(context).scale(tagFontSize);
    final tagHeight = tagSize * 1.3;
    Widget tag(String region) => SizedBox(
          height: lineHeight,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius: BorderRadius.circular(5),
              ),
              child: SizedBox(
                height: tagHeight,
                child: Baseline(
                  // 思源黑体 10sp 在该胶囊内视觉中心略高于 0.33，基线下移至 0.39 使其垂直居中。
                  baseline: tagHeight / 2 + tagSize * 0.39,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(
                    region,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: tagFontSize,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    Widget line(String region, String value) {
      if (scrollable) {
        final style = AppTheme.number(
          fontSize: valueSize,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            tag(region),
            const SizedBox(width: 6),
            Expanded(
              child: MarqueeText(text: value, style: style),
            ),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tag(region),
          const SizedBox(width: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final style = AppTheme.number(
                  fontSize: valueSize,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                );
                final painter = TextPainter(
                  text: TextSpan(
                    text: value,
                    style: DefaultTextStyle.of(context).style.merge(style),
                  ),
                  maxLines: 1,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final width = painter.width;
                painter.dispose();
                final fit = width > constraints.maxWidth
                    ? constraints.maxWidth / width
                    : 1.0;
                return Baseline(
                  baseline: lineHeight / 2 + scaledSize * fit * 0.36,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: style.copyWith(fontSize: valueSize * fit),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showStatDialog(
              label, rows.map((row) => '${row.$1}：${row.$2}').join('\n')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              for (final row in rows) ...[
                const SizedBox(height: 4),
                line(row.$1, row.$2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 构建统计项
  // 可游玩地区：使用 dxdata 的 serverIds（cn/jp/intl/usa），命中则点亮
  Widget _buildPlayableRegionStat(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final serverIds = _findMatchedSheet()?.serverIds ?? const <String>[];
    // 水鱼正曲库中的歌曲默认视为国服可游玩。dxdata 的 serverIds 偶尔会
    // 漏掉 cn，因此这里强制点亮 CN；宴会场、maidata 追加和 union 独有曲
    // 仍沿用 dxdata 的地区数据。
    // 另外，落雪曲库里有这首歌且国服上线日期已到（北京时间）时也强制点亮 CN。
    final forceCn = !_isExtraSong || _isReleasedOnLxnsCn();
    const regionLabels = <String>['CN', 'JP', 'INTL', 'USA'];
    const regionIds = <String>['cn', 'jp', 'intl', 'usa'];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.flowPlayableRegions,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < regionLabels.length; i++) ...[
                    if (i > 0) SizedBox(width: screenWidth * 0.012),
                    _buildRegionBadge(
                      regionLabels[i],
                      (i == 0 && forceCn) ||
                          serverIds.contains(regionIds[i]),
                      screenWidth,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 解禁条件：国服来自落雪（locked + map），日服来自 DXRating（isLocked）。
  /// 两国服与日服结论一致时合并为单行，不一致时拆成国服 / 日服双行。
  Widget _buildUnlockConditionStat() {
    final l10n = context.l10n;
    String? cnText;
    if (_cnSongLocked != null) {
      final cnLocked =
          _cnSongLocked == true || (_cnChartLockedByDiff[_currentDiffIndex] == true);
      if (!cnLocked) {
        cnText = l10n.songUnlockNone;
      } else {
        cnText = _cnUnlockMap ?? l10n.songUnlockRequired;
      }
    }

    final matchedDx = _findMatchedDxEntry();
    final String? jpText =
        matchedDx != null && matchedDx.sheet.serverIds.contains('jp')
            ? (matchedDx.song.isLocked
                ? l10n.songUnlockRequired
                : l10n.songUnlockNone)
            : null;

    final label = l10n.songUnlockCondition;
    if (cnText != null && jpText != null) {
      if (cnText == jpText) {
        return _buildStatItem(label, cnText);
      }
      return _buildRegionStat(
        label,
        [
          (l10n.flowChina, cnText),
          (l10n.flowJapan, jpText),
        ],
        scrollable: true,
      );
    }
    if (cnText != null || jpText != null) {
      return _buildStatItem(label, (cnText ?? jpText)!);
    }
    return _buildStatItem(label, '-');
  }

  Widget _buildRegionBadge(String label, bool active, double screenWidth) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: screenWidth * 0.018, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.successGreen(brightness)
            : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: screenWidth * 0.033,
          fontWeight: FontWeight.bold,
          color: active
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ),
    );
  }

  /// 查看完整内容并复制（BPM 额外显示变速明细）。
  void _showStatDialog(String label, String value) {
    final isBpm = label == 'BPM';
    final inote = isBpm ? _maidataInoteByDiffIndex[_currentDiffIndex] : null;
    final bpmValues =
        _maidataBpmChangesByDiffIndex[_currentDiffIndex] ?? const <double>[];
    final timeline = inote == null
        ? null
        : compute(ChartBpmInfo.parseTimeline, inote);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(label),
          content: isBpm
              ? FutureBuilder<List<ChartBpmSegment>>(
                  future: timeline,
                  builder: (context, snapshot) => _buildBpmDialogContent(
                    context,
                    value,
                    bpmValues,
                    snapshot,
                  ),
                )
              : Text(value),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                Navigator.of(context).pop();
                AppToast.show(context.l10n.flowCopiedToClipboard,
                    tone: AppToastTone.success);
              },
              child: Text(context.l10n.flowCopy),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.featureClose),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value,
      {Color? valueColor, bool scrollable = true, String? dialogValue}) {
    // 2026-11：数值放在白卡片上，统一用正文色；标签用次要文字色。
    // （难度色只留给头图和难度切换，避免浅色难度色在白底上看不清）
    final scheme = Theme.of(context).colorScheme;
    final textStyle = AppTheme.number(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: valueColor ?? scheme.onSurface,
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showStatDialog(label, dialogValue ?? value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              // 放不下时横向滚动；不能滚动的内容缩小字号，保持一行显示完整
              if (!scrollable)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: textStyle, maxLines: 1),
                )
              else
                MarqueeText(text: value, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }

  /// 分段比例条（物量、绝赞、保护套共用）：保留外层圆角与 2dp 紧贴分隔，
  /// 通过 [stackedBarWidths] 给极少 NOTE 分配保底最小宽度，并兼容极窄容器。
  Widget _buildDistributionBar(List<int> counts, List<Color> colors) {
    final motion = AppDesignTokens.motion(context, AppDesignTokens.slowMotion);
    final lastNonZero = counts.lastIndexWhere((c) => c > 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = stackedBarWidths(
          counts,
          constraints.maxWidth,
          gap: 2,
          minWidth: 6,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (var i = 0; i < counts.length; i++)
                  AnimatedContainer(
                    duration: motion,
                    curve: AppDesignTokens.emphasizedCurve,
                    width: widths[i],
                    margin: EdgeInsets.only(
                        right: widths[i] > 0 && i != lastNonZero ? 2 : 0),
                    color: colors[i],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 分段条下方的图例：色点 + 名称 + 滚动数字。[counts] 为 null 表示没有数据，显示「-」。
  Widget _buildDistributionLegend(
      List<String> labels, List<int?> counts, List<Color> colors,
      {double dotOffsetY = 1.5}) {
    final scheme = Theme.of(context).colorScheme;
    final numberStyle = AppTheme.number(
        fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Transform.translate(
                      offset: Offset(0, dotOffsetY),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(labels[i],
                            style: AppTheme.number(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurfaceVariant)),
                      ),
                    ),
                  ],
                ),
                counts[i] == null
                    ? Text('-', style: numberStyle)
                    : RollingNumber(value: counts[i]!, style: numberStyle),
              ],
            ),
          ),
      ],
    );
  }

  /// 按原有分类口径拆开两组 NOTE，不把 SLIDE、TOUCH 或绝赞星星混入。
  Widget _buildProtectionDistributions(
      NoteStats? stats, List<int?> breakCounts) {
    final type = _songData?['type']?.toString().toUpperCase();
    final isUtage = ChartDifficulty.isUtageSong(widget.songId, type: type);
    if (!isUtage && (type == 'SD' || type == 'ST')) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final groups = [
      (
        context.l10n.flowProtectedNOTEDistribution,
        [
          context.l10n.flowProtectedTAP,
          context.l10n.flowProtectedHOLD,
          context.l10n.flowProtectedBREAK
        ],
        <int?>[stats?.protectedTap, stats?.protectedHold, breakCounts[2]],
        [
          AppColors.noteDistribution[0],
          AppColors.noteDistribution[1],
          AppColors.breakDistribution[2]
        ],
        stats?.protectedNotes,
      ),
      (
        context.l10n.flowUnprotectedNOTEDistribution,
        [
          context.l10n.flowUnprotectedTAP,
          context.l10n.flowUnprotectedHOLD,
          context.l10n.flowTrueBREAKTAP,
          context.l10n.flowTrueBREAKHOLD
        ],
        <int?>[
          stats == null ? null : stats.tap - stats.protectedTap,
          stats == null ? null : stats.hold - stats.protectedHold,
          breakCounts[0],
          breakCounts[1]
        ],
        [
          AppColors.noteDistribution[0],
          AppColors.noteDistribution[1],
          AppColors.breakDistribution[0],
          AppColors.breakDistribution[1]
        ],
        stats?.unprotectedNotes,
      ),
    ]
        .where((group) =>
            !group.$3.every((count) => count == 0) &&
            group.$3.any((count) => count != null))
        .toList();
    // 全为 0 或全为「-」时隐藏对应分组，混合数据保留各自的占位。
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          const SizedBox(height: 16),
          AppSectionHeader(
            title: group.$1,
            padding: const EdgeInsets.only(bottom: 10),
            trailing: group.$5 == null
                ? Text(context.l10n.flowParsingDataUnavailable,
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
                : RollingNumber(
                    value: group.$5!,
                    prefix: context.l10n.flowTotal,
                    style: AppTheme.number(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          _buildDistributionBar(
              [for (final count in group.$3) count ?? 0], group.$4),
          const SizedBox(height: 10),
          _buildDistributionLegend(group.$2, group.$3, group.$4),
        ],
        const SizedBox(height: 8),
        Text(
          context.l10n.flowExcludesSLIDETOUCHAndBREAKStars,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // 构建占位符

  // 构建徽章
  Widget _buildBadge(String text) => ComboLabelBadge(raw: text);

  /// 显示所有别名弹窗，每条别名点击即可复制到剪贴板。
  void _showAliasesDialog(String songTitle, List<String> aliases) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowAliasesForP0((songTitle).toString())),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.flowTapAnyAliasToCopy,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                // 每条别名可点击复制到剪贴板（点击后不关闭弹窗，方便连续复制）
                ...aliases.map((alias) => InkWell(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: alias));
                        AppToast.show(
                            context.l10n.flowCopiedP0((alias).toString()),
                            tone: AppToastTone.success);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        // 用 Expanded 撑满宽度，保证整行都是可点区域
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                alias,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.featureClose),
            ),
          ],
        );
      },
    );
  }

  /// 基础信息卡片底部的别名预览通栏（按真实可用宽度动态铺满最多两行，点击展开全部别名）。
  Widget _buildBasicInfoAliasFooter(String songTitle, List<String> aliases) {
    final scheme = Theme.of(context).colorScheme;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    TextStyle chipTextStyle({bool muted = false}) => defaultStyle.merge(
          AppTheme.number(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        );

    double measureChipWidth(String label, {bool muted = false}) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: chipTextStyle(muted: muted)),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      // 左右内边距各 8dp + 1dp 舍入余量，避免浮点误差误换行。
      final width = painter.width.ceilToDouble() + 16.0 + 1.0;
      painter.dispose();
      return width;
    }

    Widget chip(String label, double maxWidth, {bool muted = false}) =>
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.number(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
          ),
        );

    return Semantics(
      button: true,
      label: context.l10n.flowViewAliasesP0((aliases.length).toString()),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showAliasesDialog(songTitle, aliases),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.flowAlias,
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  '${context.l10n.flowAll} (${aliases.length})',
                  style: AppTheme.number(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                if (!maxWidth.isFinite || maxWidth <= 0) {
                  return const SizedBox.shrink();
                }
                const spacing = 6.0;
                bool fitsInTwoRows(List<double> widths) {
                  if (widths.isEmpty) return true;
                  int row = 1;
                  double used = 0;
                  for (final rawW in widths) {
                    final w = math.min(rawW, maxWidth);
                    if (used == 0) {
                      used = w;
                    } else if (used + spacing + w <= maxWidth + 0.5) {
                      used += spacing + w;
                    } else {
                      row++;
                      if (row > 2) return false;
                      used = w;
                    }
                  }
                  return true;
                }

                final chipWidths = [
                  for (final alias in aliases)
                    math.min(measureChipWidth(alias), maxWidth),
                ];

                int shownCount = aliases.length;
                if (!fitsInTwoRows(chipWidths)) {
                  shownCount = 1;
                  for (var k = aliases.length - 1; k >= 1; k--) {
                    final restWidth = measureChipWidth(
                      '+${aliases.length - k}',
                      muted: true,
                    );
                    if (fitsInTwoRows([
                      ...chipWidths.take(k),
                      restWidth,
                    ])) {
                      shownCount = k;
                      break;
                    }
                  }
                }
                final restCount = aliases.length - shownCount;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final alias in aliases.take(shownCount))
                      chip(alias, maxWidth),
                    if (restCount > 0)
                      chip('+$restCount', maxWidth, muted: true),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 抽屉后面的头图：滚动时固定在原位，只露出抽屉顶边以上的部分。
///
/// 抽屉本身不铺底色，用户的自定义背景图从抽屉里透出来；
/// 头图裁掉的那一块才是抽屉，顶边的圆角也是裁出来的。
class _SongDrawerHero extends StatelessWidget {
  final ScrollController controller;
  final Widget child;

  const _SongDrawerHero({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final cachedChild = RepaintBoundary(child: child);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            0, controller.hasClients ? controller.offset.clamp(0.0, 1e6) : 0),
        child: child,
      ),
      child: ClipPath(
        clipper: _SongDrawerHeroClipper(controller),
        child: cachedChild,
      ),
    );
  }
}

class _SongDrawerHeroClipper extends CustomClipper<Path> {
  final ScrollController controller;
  static final Path _emptyPath = Path();

  _SongDrawerHeroClipper(this.controller) : super(reclip: controller);

  @override
  Path getClip(Size size) {
    final offset =
        controller.hasClients ? controller.offset.clamp(0.0, 1e6) : 0.0;
    final top = size.height - _songDrawerOverlap - offset;
    final r = math.min(AppDesignTokens.radiusLarge + 4, size.width / 2);
    // 抽屉顶边已经滑过头图顶端，头图完全不用露出来。
    if (top + r <= 0) return _emptyPath;
    if (top >= size.height) return Path()..addRect(Offset.zero & size);
    if (top >= 0) {
      // 单路径直接描出「头图可见区域」，省去每帧 Path.combine 布尔差集运算。
      final arcBottom = top + r;
      return Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, arcBottom)
        ..arcToPoint(
          Offset(size.width - r, top),
          radius: Radius.circular(r),
          clockwise: false,
        )
        ..lineTo(r, top)
        ..arcToPoint(
          Offset(0, arcBottom),
          radius: Radius.circular(r),
          clockwise: false,
        )
        ..close();
    }
    // -r < top < 0 时仅左右两角在顶边露出一小段圆弧三角，避免单路径自交。
    final dy = top + r;
    final dx = math.sqrt((r * r - dy * dy).clamp(0.0, r * r));
    final leftEdgeX = (r - dx).clamp(0.0, size.width / 2);
    final rightEdgeX = (size.width - r + dx).clamp(size.width / 2, size.width);
    return Path()
      ..moveTo(0, 0)
      ..lineTo(leftEdgeX, 0)
      ..arcToPoint(
        Offset(0, dy),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..close()
      ..moveTo(rightEdgeX, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, dy)
      ..arcToPoint(
        Offset(rightEdgeX, 0),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..close();
  }

  @override
  bool shouldReclip(_SongDrawerHeroClipper oldClipper) =>
      oldClipper.controller != controller;
}
