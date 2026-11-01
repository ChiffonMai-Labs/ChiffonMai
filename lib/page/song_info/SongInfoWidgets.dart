part of '../SongInfoPage.dart';

/// SongInfoPage · 小部件：统计项、物量格、徽章、别名
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoWidgets on _SongInfoPageState {

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
            Text(_hasBpmChanges ? '$_bpmRangeLabel：$value' : '谱面 BPM：$value'),
            const SizedBox(height: 8),
            Text('$_defaultBpmLabel：${_defaultBpm(_songData?['basic_info'])}'),
            if (values.toSet().length > 1) ...[
              const SizedBox(height: 16),
              const Text('按当前谱面中 BPM 标记的出现顺序'),
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
                      cell(const Text('变化序号')),
                      cell(const Text('BPM')),
                    ]),
                    for (var i = 0; i < values.length; i++)
                      TableRow(children: [
                        cell(Text('${i + 1}')),
                        cell(_valueWithDirection(_formatBpm(values[i]),
                            i == 0 ? null : values[i].compareTo(values[i - 1]))),
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
          children: [
            Text(
              'B站播放',
              style: TextStyle(
                fontSize: 11.5,
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
        children: [
          Text('可游玩地区',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
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
        return AlertDialog(
          title: Text(label),
          content:
              label == 'BPM' ? _buildBpmDialogContent(value) : Text(value),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已复制到剪贴板')),
                );
              },
              child: Text('复制'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, {Color? valueColor}) {
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showStatDialog(label, value),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              // 放得下居中显示，放不下横向滚动
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



  // 构建Break统计项
  Widget _buildBreakItem(String type, String count) {
    final screenWidth = MediaQuery.of(context).size.width;
    final brightness = Theme.of(context).brightness;

    Color textColor;
    switch (type) {
      case '真绝赞TAP':
        textColor = AppColors.errorRed(brightness);
        break;
      case '真绝赞HOLD':
        textColor = const Color(0xFFFF6B6B); // 浅红色
        break;
      case '保护套绝赞':
        textColor = AppColors.linkBlue(brightness);
        break;
      case '绝赞星星':
        textColor = Colors.yellow[700] ?? Colors.yellow;
        break;
      default:
        textColor = Theme.of(context).colorScheme.onSurface;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              type,
              maxLines: 1,
              style: TextStyle(
                fontSize: (screenWidth * 0.024).clamp(9.0, 10.5).toDouble(),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            count,
            style: AppTheme.number(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
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
          '别名: 无',
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
            return AlertDialog(
              title: Text('${songTitle}的别名'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '点击任意别名即可复制',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 每条别名可点击复制到剪贴板（点击后不关闭弹窗，方便连续复制）
                    ...aliases.map((alias) => InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: alias));
                            Fluttertoast.showToast(msg: '已复制：$alias');
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
                  child: Text('关闭'),
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
              '查看别名 (${aliases.length})',
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
