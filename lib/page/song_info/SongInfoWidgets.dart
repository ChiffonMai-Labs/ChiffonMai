part of '../SongInfoPage.dart';

/// SongInfoPage · 小部件：统计项、物量格、徽章、别名
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoWidgets on _SongInfoPageState {
  /// [value] 已经是「谱面：x」「基准：y」两行，不再另加标签。
  Widget _buildBpmDialogContent(String value) {
    // 使用当前谱面的完整顺序，保留降速后再次升回同一 BPM 的记录。
    final values =
        _maidataBpmChangesByDiffIndex[_currentDiffIndex] ?? const <double>[];
    Widget cell(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(child: child),
        );
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(value),
            if (values.toSet().length > 1) ...[
              const SizedBox(height: 16),
              Text(context.l10n.flowInTheOrderBPMMarkersAppearIn),
              const SizedBox(height: 8),
              Center(
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  children: [
                    TableRow(children: [
                      cell(Text(context.l10n.flowChangeIndex)),
                      cell(const Text('BPM')),
                    ]),
                    for (var i = 0; i < values.length; i++)
                      TableRow(children: [
                        cell(Text('${i + 1}')),
                        cell(_valueWithDirection(
                            _formatBpm(values[i]),
                            i == 0
                                ? null
                                : values[i].compareTo(values[i - 1]))),
                      ]),
                  ],
                ),
              ),
            ],
          ])),
    );
  }

  /// 构建 B站播放量统计项（带 BV 上传功能）
  Widget _buildBiliPlayCountStat() {
    return Expanded(
      child: GestureDetector(
        onTap: _showBvUploadDialog,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.flowPlayOnBilibili,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _formatBiliPlayCount(),
                    style: AppTheme.number(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _biliBvid != null ? Icons.edit : Icons.upload_file,
                  size: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
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
  Widget _buildRegionStat(String label, List<(String, String)> rows) {
    final scheme = Theme.of(context).colorScheme;
    // 内容不滚动也不换行，放不下时缩小字号。小标签和文字都按中线摆放：
    // 标签在固定行高里居中，文字的字形中线（基线上方约 0.36 个字号，实测）落在同一高度，
    // 不依赖字体的行高；按基线对齐时标签底块会偏下。
    const valueSize = 15.0;
    final scaledSize = MediaQuery.textScalerOf(context).scale(valueSize);
    final lineHeight = scaledSize * 1.3;
    Widget line(String region, String value) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: lineHeight,
              child: Center(
                child: AppBadge(
                  text: region,
                  numeric: false,
                  fontSize: 10,
                  centered: true,
                  background: AppSurfaces.inset(context),
                  foreground: scheme.onSurfaceVariant,
                ),
              ),
            ),
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
    final isDivingFishSong = !_isExtraSong;
    const regionLabels = <String>['CN', 'JP', 'INTL', 'USA'];
    const regionIds = <String>['cn', 'jp', 'intl', 'usa'];

    return Expanded(
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
                    (i == 0 && isDivingFishSong) ||
                        serverIds.contains(regionIds[i]),
                    screenWidth,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(label),
          content: label == 'BPM' ? _buildBpmDialogContent(value) : Text(value),
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
      {Color? valueColor, bool scrollable = true}) {
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
          onTap: () => _showStatDialog(label, value),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final painter = TextPainter(
                      text: TextSpan(text: value, style: textStyle),
                      maxLines: 1,
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout();
                    final fits = painter.width <= constraints.maxWidth;
                    painter.dispose();
                    return fits
                        ? Text(value, style: textStyle, maxLines: 1)
                        : MarqueeText(text: value, style: textStyle);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 分段比例条（物量、绝赞共用）：切难度时色块宽度过渡。
  Widget _buildDistributionBar(List<int> counts, List<Color> colors) {
    final motion = AppDesignTokens.motion(context, AppDesignTokens.slowMotion);
    final total = counts.fold<int>(0, (sum, n) => sum + n);
    final lastNonZero = counts.lastIndexWhere((c) => c > 0);
    final gapCount = counts.where((c) => c > 0).length - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - (gapCount < 0 ? 0 : gapCount) * 2;
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
                    width: total == 0 ? 0 : usable * counts[i] / total,
                    margin: EdgeInsets.only(
                        right: counts[i] > 0 && i != lastNonZero ? 2 : 0),
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

  // 构建别名区域
  Widget _buildAliasSection(String songTitle) {
    final brightness = Theme.of(context).brightness;
    // 从 SongAliasManager 获取别名数据
    final aliases = SongAliasManager.instance.aliases[songTitle] ?? [];

    if (aliases.isEmpty) {
      // 2026-11：别名区放在难度色头图里，空状态改成半透明白色小标签。
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          context.l10n.flowAliasesNone,
          style: AppTheme.number(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // 显示弹窗查看所有别名
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AppAlertDialog(
              title:
                  Text(context.l10n.flowAliasesForP0((songTitle).toString())),
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
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.tableBorder(brightness), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.flowViewAliasesP0((aliases.length).toString()),
              style: AppTheme.number(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            0, controller.hasClients ? controller.offset.clamp(0.0, 1e6) : 0),
        child: child,
      ),
      child: ClipPath(
        clipper: _SongDrawerHeroClipper(controller),
        child: child,
      ),
    );
  }
}

class _SongDrawerHeroClipper extends CustomClipper<Path> {
  final ScrollController controller;

  _SongDrawerHeroClipper(this.controller) : super(reclip: controller);

  @override
  Path getClip(Size size) {
    final offset =
        controller.hasClients ? controller.offset.clamp(0.0, 1e6) : 0.0;
    final top = size.height - _songDrawerOverlap - offset;
    const radius = AppDesignTokens.radiusLarge + 4;
    // 抽屉顶边已经滑过头图顶端，头图完全不用露出来。
    if (top + radius <= 0) return Path();
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()
        // 下边固定在头图之外：抽屉滑得再远，这块也要盖住头图下半部分。
        ..addRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(0, top, size.width, size.height + _songDrawerOverlap),
          topLeft: const Radius.circular(radius),
          topRight: const Radius.circular(radius),
        )),
    );
  }

  @override
  bool shouldReclip(_SongDrawerHeroClipper oldClipper) =>
      oldClipper.controller != controller;
}
