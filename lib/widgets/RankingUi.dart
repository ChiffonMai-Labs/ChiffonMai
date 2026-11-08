import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';

/// 排行榜共用的部件：名次、玩家行、固定在底部的「我的排名」、说明条。
///
/// Rating / 拟合 / 平均达成率 / 单曲 / DX 分数榜都用这一套，特殊榜（列的是谱面）
/// 只用 [RankingMedal]。

/// 名次：前三名是奖牌色圆片，其余是数字。
class RankingMedal extends StatelessWidget {
  final int rank;

  const RankingMedal({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    final style = switch (rank) {
      1 => (AppColors.medalColor('gold'), const Color(0xFF4A3800)),
      2 => (AppColors.medalColor('silver'), const Color(0xFF3A3A3A)),
      3 => (AppColors.medalColor('bronze'), Colors.white),
      _ => null,
    };
    if (style == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$rank',
          maxLines: 1,
          style: AppTheme.number(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: style.$1, shape: BoxShape.circle),
      child: Text(
        '$rank',
        style: AppTheme.number(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: style.$2,
        ),
      ),
    );
  }
}

/// 名次 + 玩家身份 + 数值这一排内容，列表行和底部栏共用。
class _RankingRowContent extends StatelessWidget {
  final int rank;
  final Widget identity;
  final Widget value;

  const _RankingRowContent({
    required this.rank,
    required this.identity,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 32, child: Center(child: RankingMedal(rank: rank))),
        const SizedBox(width: 8),
        Expanded(child: identity),
        const SizedBox(width: 8),
        value,
      ],
    );
  }
}

/// 排行榜的一行白卡片。
///
/// 卡片间距算在行内：列表用 `prototypeItem` 等高排布，「第 index 行的偏移 =
/// index × 行高」才成立（见 RankingRowExtent）。
class RankingRow extends StatelessWidget {
  final int rank;
  final Widget identity;
  final Widget value;

  /// 当前用户自己那一行。
  final bool highlighted;

  const RankingRow({
    super.key,
    required this.rank,
    required this.identity,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 8),
      child: PressScale(
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? Theme.of(context).colorScheme.primaryContainer
                : AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          ),
          child:
              _RankingRowContent(rank: rank, identity: identity, value: value),
        ),
      ),
    );
  }
}

/// 固定在列表下方的「我的排名」，点击定位到自己那一行。
class RankingSelfBar extends StatelessWidget {
  final int rank;
  final Widget identity;
  final Widget value;
  final VoidCallback onTap;

  const RankingSelfBar({
    super.key,
    required this.rank,
    required this.identity,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
      child: PressScale(
        scale: 0.98,
        child: Material(
          color: scheme.primaryContainer,
          elevation: 3,
          shadowColor: scheme.shadow.withValues(alpha: 0.3),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _RankingRowContent(
                  rank: rank, identity: identity, value: value),
            ),
          ),
        ),
      ),
    );
  }
}

/// 排行榜顶部说明：四个榜共用同一句话，固定一行，放不下时等比缩小。
class RankingNotice extends StatelessWidget {
  const RankingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.warningOrange(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 15, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.flowDataVoluntarilyUploadedByPlayersForReference,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 排行榜加载成功后，让首屏的行依次进场。
///
/// 行是 `ListView.builder` 懒建的，滚走再滚回来会重新挂载；这里只在拿到新列表后的
/// 短时间内播放，滚动时不重播。换榜、刷新都会换一个新列表，自然又播一次。
class RankingEntrance {
  static const _window = Duration(milliseconds: 1000);
  static const _maxAnimatedIndex = 14;

  Object? _list;
  DateTime _shownAt = DateTime.now();

  Widget wrap(List<Object?> list, int index, Widget child) {
    if (!identical(list, _list)) {
      _list = list;
      _shownAt = DateTime.now();
    }
    return EntranceAnimation(
      index: index,
      enabled: index < _maxAnimatedIndex &&
          DateTime.now().difference(_shownAt) < _window,
      duration: const Duration(milliseconds: 300),
      offset: const Offset(0, 8),
      child: child,
    );
  }
}
