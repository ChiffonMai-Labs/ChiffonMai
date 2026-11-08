import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../manager/DivingFishProbeManager.dart';
import '../utils/AppTheme.dart';
import 'MaimaiHubLoginDialog.dart';
import '../widgets/AppDialogs.dart';

/// 线路2（maimai Score Hub）同步前确保登录态。
///
/// 上游已限制「一张机台二维码只能处理一个请求」，线路2 不能再用同步二维码
/// 去登录 Score Hub。这里优先**复用本机已保存的登录态**（不消耗二维码）；
/// 没有可用登录态时，先让用户通过独立登录框扫码登录（消耗一张二维码），
/// 之后本次同步再使用另一张二维码创建 cabinet job。
///
/// 返回 true 表示可以继续本次线路2同步；false 表示用户取消或登录失败。
Future<bool> ensureMaimaiHubLogin(
  BuildContext context, {
  String? reason,
}) async {
  final manager = DivingFishProbeManager();
  // 复用已有登录态：只有 token 过期/未登录才会走到下面的登录框。
  if (await manager.hasValidHubSession()) return true;
  if (!context.mounted) return false;

  final goLogin = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final brightness = Theme.of(ctx).brightness;
      return AppAlertDialog(
        title: Row(children: [
          Icon(Icons.hub_outlined, size: 22),
          SizedBox(width: 8),
          Expanded(child: Text(context.l10n.flowSignInToMaimaiScoreHubFirst2)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.flowP0ReusesThisDeviceSMaimaiScore((reason == null
                        ? context.l10n.flowRoute2Sync
                        : context.l10n.flowP0Sync((reason).toString()))
                    .toString()),
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.flowTipGenerateTwoDifferentLoginQRCodes,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greyHint(brightness),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.featureCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.login, size: 18),
            label: Text(context.l10n.flowSignInFirst),
          ),
        ],
      );
    },
  );
  if (goLogin != true || !context.mounted) return false;
  return showMaimaiHubLoginDialog(context);
}
