import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcGatewaySettings.dart';
import '../../service/AWMC/AwmcPlayCountStore.dart';
import '../../service/AWMC/AwmcStore.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/QrQuickFillButtons.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';

/// 独立读取机台游玩次数的结果。
class AwmcPlayCountSyncOutcome {
  final bool cancelled;
  final bool ok;
  final int cachedRecords;
  final String? message;

  const AwmcPlayCountSyncOutcome({
    this.cancelled = false,
    this.ok = false,
    this.cachedRecords = 0,
    this.message,
  });

  static const userCancelled = AwmcPlayCountSyncOutcome(cancelled: true);
}

/// 游玩次数独立功能：一张二维码只发出一次上游 `/v1/user/music` 请求。
class AwmcPlayCountSyncFlow {
  AwmcPlayCountSyncFlow._();

  static Future<AwmcPlayCountSyncOutcome> run(
    BuildContext context, {
    void Function(String label)? onBusy,
    VoidCallback? onIdle,
  }) async {
    // 与其它 AWMC 入口一致：探活超时可在设置页「同步与网关」里调整（默认 15 秒）。
    final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
    final health = await AwmcApiService.health(
      token: '',
      timeout: probeTimeout,
    );
    await AwmcAuditLog.record(health, note: context.l10n.flowGatewayCheckBeforeReadingPlayCounts);
    if (!health.ok) {
      return AwmcPlayCountSyncOutcome(
        message: context.l10n
            .flowAWMCGatewayUnavailableP0((health.displayMessage).toString()),
      );
    }

    if (!context.mounted) return AwmcPlayCountSyncOutcome.userCancelled;
    final qrCode = await _askQrCode(context);
    if (qrCode == null) return AwmcPlayCountSyncOutcome.userCancelled;

    onBusy?.call(context.l10n.flowReadingCabinetPlayCount);
    try {
      final source = AwmcPlayCountStore.activeSource;
      final result = await AwmcPlayCountStore.refreshFromGateway(
        token: '',
        qrcode: qrCode,
        source: source,
      );
      await AwmcAuditLog.record(result, note: context.l10n.flowReadPlayCountsSeparately);
      if (!result.ok) {
        return AwmcPlayCountSyncOutcome(message: result.displayMessage);
      }
      return AwmcPlayCountSyncOutcome(
        ok: true,
        cachedRecords: AwmcPlayCountStore.size,
      );
    } catch (error) {
      return AwmcPlayCountSyncOutcome(message: '$error');
    } finally {
      onIdle?.call();
    }
  }

  static Future<String?> _askQrCode(BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final controller = TextEditingController();
    ModalRoute<dynamic>? dialogRoute;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        dialogRoute ??= ModalRoute.of(dialogContext);
        return AppAlertDialog(
          title: const Row(
            children: [
              Icon(Icons.numbers_rounded, size: 22),
              SizedBox(width: 8),
              Text('刷新机台游玩次数'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.flowThisReadsOnlyTheActiveAccountPlay,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.greyHint(brightness),
                  ),
                ),
                const SizedBox(height: 12),
                QrQuickFillButtons(controller: controller),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: context.l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID2,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    final qr = controller.text.trim();
                    if (qr.isEmpty || !qr.startsWith('SGWCMAID')) {
                      AppToast.show(
                          context.l10n.flowEnterAValidSGWCMAIDCabinetLoginQR,
                          tone: AppToastTone.warning);
                      return;
                    }
                    Navigator.of(dialogContext).pop(qr);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.flowReadPlayCount),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.featureCancel),
            ),
          ],
        );
      },
    );
    await dialogRoute?.completed;
    controller.dispose();
    return result;
  }
}
