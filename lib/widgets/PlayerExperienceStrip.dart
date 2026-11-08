import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';
import '../service/PlayerExperienceService.dart';
import 'SmoothLinearProgressIndicator.dart';
import '../widgets/AppDialogs.dart';

class PlayerExperienceStrip extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? message;

  /// 放在等级这一行末尾，和等级垂直居中。
  final Widget? trailing;
  const PlayerExperienceStrip(
      {super.key, required this.data, this.message, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = (data['levelExperience'] as num?) ?? 0;
    final next = (data['nextLevelExperience'] as num?) ?? 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Lv.${data['level'] ?? 1}',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
              spacing: 10,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(context.l10n.homeStreak((data['streak'] as num?)?.toInt() ?? 0),
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                Text('$current / $next EXP',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              ]),
        ),
        if (trailing != null) trailing!,
      ]),
      const SizedBox(height: 8),
      SmoothLinearProgressIndicator(
          value: (current / next).clamp(0.0, 1.0), minHeight: 6),
      if (message != null && message!.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message!,
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
    ]);
  }
}

/// 自己的成长信息与排行榜公开开关无关，切换账号时读取该账号缓存。
class MyPlayerExperience extends StatelessWidget {
  const MyPlayerExperience({super.key});
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: PlayerExperienceService.instance,
        builder: (context, data, _) => data == null
            ? Row(children: [
                Expanded(
                  child: Text(
                      // 启动后读到缓存之前还没有文案
                      PlayerExperienceService.instance.message.isEmpty
                          ? context.featureText('正在读取成长记录…')
                          : PlayerExperienceService.instance.message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                ),
                const _GrowthRulesButton(),
              ])
            : PlayerExperienceStrip(
                data: data,
                message: PlayerExperienceService.instance.message,
                trailing: const _GrowthRulesButton()),
      );
}

/// 成长规则按钮：图标贴右，和下方经验条的右端对齐。
class _GrowthRulesButton extends StatelessWidget {
  const _GrowthRulesButton();

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.featureText('成长规则'),
        icon: const Icon(Icons.info_outline, size: 20),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AppAlertDialog(
                  title: Text(context.featureText('成长规则')),
                  content: Text(context.l10n.growthRulesBody),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.featureText('知道了')))
                  ],
                )),
      );
}
