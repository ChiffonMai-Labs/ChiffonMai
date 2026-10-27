import 'package:flutter/material.dart';
import '../service/PlayerExperienceService.dart';
import 'SmoothLinearProgressIndicator.dart';

class PlayerExperienceStrip extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? message;
  const PlayerExperienceStrip({super.key, required this.data, this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = (data['levelExperience'] as num?) ?? 0;
    final next = (data['nextLevelExperience'] as num?) ?? 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Lv.${data['level'] ?? 1}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary)),
            Text('连续签到 ${data['streak'] ?? 0} 天',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            Text('$current / $next EXP',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
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
        builder: (context, data, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: data == null
                    ? Text(PlayerExperienceService.instance.message,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12))
                    : PlayerExperienceStrip(
                        data: data,
                        message: PlayerExperienceService.instance.message)),
            IconButton(
                tooltip: '成长规则',
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text('成长规则'),
                          content: const Text(
                              '按北京时间，每天首次启动 App 时检查签到；本机登录或验证账号成功后，也会为当天尚未签到的账号自动签到。\n\n'
                              '首日 20 经验；连续签到每天多 5 点，第 7 天起每天 50 点。中断后从 20 点重新开始，累计经验保留。\n\n'
                              'Lv.1 升级需 100 经验，之后每级多需 20 点。\n\n'
                              '成长记录跟随对应数据源账号，同一账号同日只能领取一次。'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('知道了'))
                          ],
                        ))),
          ],
        ),
      );
}
