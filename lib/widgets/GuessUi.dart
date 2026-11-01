import 'package:flutter/material.dart';

import '../entity/GuessChartGame/GuessSong.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/StringUtil.dart';
import 'AppUi.dart';
import 'GuessBpmHistoryFields.dart';
import 'GuessCoverImage.dart';
import 'MarqueeText.dart';

/// 猜歌玩法共用的界面组件：色块、猜测卡片、贴底输入栏。
///
/// 色块颜色由各玩法的 Service 算好（[AppColors.guessCorrectBg] 等），
/// 这里只负责显示；文字颜色按底色深浅自动选。

/// 一个比对色块：小标签 + 值 + 方向箭头，出现时翻转进场。
class GuessCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? arrow;

  /// 翻转进场的错开序号。
  final int index;

  const GuessCell({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.arrow,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final fg = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF2B2F2E);
    final valueStyle = AppTheme.font(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: fg,
    );
    return GuessFlipIn(
      index: index,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 9, color: fg.withValues(alpha: 0.85))),
            ),
            Row(
              children: [
                // 曲名、曲师这类长文本横向滚动，不截断
                Expanded(child: MarqueeText(text: value, style: valueStyle)),
                if (arrow != null) ...[
                  const SizedBox(width: 2),
                  Text(arrow!, style: valueStyle),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 翻转进场：沿 X 轴从 -90° 转到 0°，按 [index] 错开。
class GuessFlipIn extends StatelessWidget {
  final Widget child;
  final int index;

  const GuessFlipIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final delay = 90 * index;
    final total = delay + 500;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDesignTokens.motion(context, Duration(milliseconds: total)),
      curve: Interval(delay / total, 1,
          curve: AppDesignTokens.emphasizedCurve),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 1 / 300)
            ..rotateX((1 - t) * -1.5708),
          child: child,
        ),
      ),
    );
  }
}

/// 一次猜测：序号 + 曲绘 + 全部比对项。
class GuessHistoryCard extends StatelessWidget {
  final GuessSong guessSong;
  final int index;
  final String? targetSongId;

  /// 这个玩法是否比对 BPM 变化（部分玩法没有）。
  final bool showBpmHistory;

  /// 多人房间里是谁猜的。
  final String? playerName;

  const GuessHistoryCard({
    super.key,
    required this.guessSong,
    required this.index,
    this.targetSongId,
    this.showBpmHistory = true,
    this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = guessSong;
    const gap = SizedBox(width: 4);
    const rowGap = SizedBox(height: 4);
    Widget cell(int flex, int order, String label, String value, Color? color,
            {String? arrow}) =>
        Expanded(
          flex: flex,
          child: GuessCell(
            index: order,
            label: label,
            value: value,
            color: color ?? Colors.grey,
            arrow: arrow,
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (playerName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
                child: MarqueeText(
                  text: playerName!,
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GuessCoverImage(
                      songId: s.songId.toString(), size: 44),
                ),
                const SizedBox(width: 8),
                Text('#${index + 1}',
                    style: AppTheme.number(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                cell(1, 0, '曲名', s.title, s.titleBgColor),
              ],
            ),
            rowGap,
            Row(
              children: [
                cell(1, 1, '类型', s.type == 'SD' ? 'ST' : s.type, s.typeBgColor),
                gap,
                cell(1, 2, 'BPM', s.bpm.toString(), s.bpmBgColor,
                    arrow: s.bpmArrow),
                gap,
                cell(2, 3, '曲师', s.artist, s.artistBgColor),
              ],
            ),
            if (showBpmHistory) ...[
              rowGap,
              GuessBpmHistoryFields(
                  songId: s.songId.toString(), targetSongId: targetSongId),
            ],
            rowGap,
            Row(
              children: [
                cell(2, 4, 'MASTER定数', s.masterDs, s.masterLevelBgColor,
                    arrow: s.masterLevelArrow),
                gap,
                cell(3, 5, 'MASTER谱师', s.masterCharter,
                    s.masterCharterBgColor),
              ],
            ),
            rowGap,
            Row(
              children: [
                cell(
                    2,
                    6,
                    'Re:MASTER定数',
                    s.remasterDs.isNotEmpty ? s.remasterDs : '-',
                    s.remasterLevelBgColor,
                    arrow: s.remasterLevelArrow),
                gap,
                cell(
                    3,
                    7,
                    'Re:MASTER谱师',
                    s.remasterCharter.isNotEmpty ? s.remasterCharter : '-',
                    s.remasterCharterBgColor),
              ],
            ),
            rowGap,
            Row(
              children: [
                cell(3, 8, '流派', s.genre, s.genreBgColor),
                gap,
                cell(4, 9, '版本', StringUtil.formatVersion2(s.version),
                    s.versionBgColor,
                    arrow: s.versionArrow),
              ],
            ),
            if (s.masterTags?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text('MASTER标签',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < s.masterTags!.length; i++)
                    _GuessTag(
                      text: s.masterTags![i],
                      color: s.tagBgColors?[i] ?? Colors.grey,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuessTag extends StatelessWidget {
  final String text;
  final Color color;

  const _GuessTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final fg = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF2B2F2E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

/// 「猜测历史」标题行：右边切换排序方向。
class GuessHistoryHeader extends StatelessWidget {
  final bool ascending;
  final VoidCallback onToggleSort;
  final int? count;

  const GuessHistoryHeader({
    super.key,
    required this.ascending,
    required this.onToggleSort,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget legend(Color color, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontSize: 11, color: muted)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(count == null ? '猜测历史' : '猜测历史 ($count)',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: onToggleSort,
                icon: Icon(
                  ascending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 16,
                ),
                label: Text(ascending ? '从早到晚' : '从晚到早',
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              legend(AppColors.guessCorrectBg(brightness), '一致'),
              legend(AppColors.guessCloseBg(brightness), '接近（箭头指向答案）'),
              legend(AppColors.guessWrongBg(brightness), '不符'),
            ],
          ),
        ],
      ),
    );
  }
}

/// 贴底输入栏：搜索框 + 投降；结束后换成「新游戏」。搜索结果弹在输入栏上方。
class GuessInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool isGameOver;
  final VoidCallback? onSurrender;
  final VoidCallback onNewGame;
  final bool showResults;

  /// 正在搜索时在输入栏上方显示一条进度。
  final bool searching;
  final int resultCount;
  final IndexedWidgetBuilder resultBuilder;

  /// 还不能作答时（等服务端确认、时间到）禁用输入框。
  final bool enabled;

  /// 有内容时显示清空键。
  final VoidCallback? onClear;

  const GuessInputBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    required this.isGameOver,
    required this.onSurrender,
    required this.onNewGame,
    required this.showResults,
    this.searching = false,
    required this.resultCount,
    required this.resultBuilder,
    this.enabled = true,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showResults && resultCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: EntranceAnimation(
              duration: const Duration(milliseconds: 300),
              offset: const Offset(0, 8),
              scaleFrom: 0.96,
              child: Container(
                constraints: BoxConstraints(maxHeight: media.size.height * 0.3),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppSurfaces.card(context),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ListView.builder(
                  // 去掉 ListView 默认把状态栏安全区算进列表顶部的空白
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: resultCount,
                  itemBuilder: resultBuilder,
                ),
              ),
            ),
          ),
        if (searching) const LinearProgressIndicator(minHeight: 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppSurfaces.card(context),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Padding(
            // 页面不随键盘缩放（§18），输入栏自己让出键盘和手势条。
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              10 +
                  (media.viewInsets.bottom > 0
                      ? media.viewInsets.bottom
                      : media.padding.bottom),
            ),
            child: isGameOver
                ? SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: onNewGame,
                      child: const Text('新游戏',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: onChanged,
                          enabled: enabled,
                          decoration: InputDecoration(
                            hintText: hintText,
                            isDense: true,
                            suffixIcon:
                                onClear == null || controller.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: '清空',
                                        onPressed: onClear,
                                        icon: const Icon(Icons.close_rounded,
                                            size: 18),
                                      ),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 18, color: scheme.onSurfaceVariant),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (onSurrender != null) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: onSurrender,
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.errorContainer,
                              foregroundColor: scheme.onErrorContainer,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text('投降',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
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
