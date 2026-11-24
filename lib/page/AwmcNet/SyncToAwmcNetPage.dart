import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../../service/AWMC/AwmcQrSyncService.dart';
import '../../service/SyncStatsService.dart';
import '../../widgets/RefreshDataDialog.dart'
    show RefreshDataRequest, RefreshDataSource;
import '../../widgets/SyncDialogUi.dart';

/// 用户在「同步成绩到 AWMC NET」对话框里填的内容。
class AwmcNetSyncInput {
  /// `SGWCMAID` 开头的机台登入二维码。
  final String qr;
  final bool quickUpdate;

  /// 要同步的 AWMC NET 玩家 QQ（普通同步免导入 Token 路径使用）。
  final String qq;

  /// 可选旧版成绩导入 Token（仅快速同步或历史回退路径使用）。
  final String importToken;
  final RefreshDataRequest? refreshRequest;

  const AwmcNetSyncInput({
    required this.qr,
    this.qq = '',
    this.importToken = '',
    this.refreshRequest,
    this.quickUpdate = false,
  });
}

/// 打开「同步成绩到 AWMC NET」的**输入对话框**，返回用户填的内容（取消 = null）。
Future<AwmcNetSyncInput?> showAwmcNetSyncInputDialog(
  BuildContext context, {
  String? boundQq,
}) {
  return showDialog<AwmcNetSyncInput>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SyncToAwmcNetPage(boundQq: boundQq),
  );
}

/// 「同步成绩到 AWMC NET」的统一单源输入对话框：同步方式 + 机台二维码 + 同步后刷新数据。
class SyncToAwmcNetPage extends StatelessWidget {
  final String? boundQq;

  const SyncToAwmcNetPage({super.key, this.boundQq});

  @override
  Widget build(BuildContext context) {
    return SingleSourceSyncDialog<AwmcNetSyncInput>(
      title: context.l10n.featureSyncToAWMCNET,
      subtitle: context.l10n.featureImportScoresToAWMCNETUsingA,
      platform: SyncPlatform.awmc,
      refreshSource: RefreshDataSource.awmc,
      allowQuickUpdate: true,
      qrCaption: context.l10n.flowRequestAndOpenALoginQRIn,
      qrHintText: context.l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID3,
      onSubmit: ({
        required context,
        required qrCode,
        required quickUpdate,
        required refreshRequest,
        required showError,
      }) async {
        final preset = boundQq?.trim() ?? '';
        final qq = preset.isNotEmpty
            ? preset
            : (await AwmcQrSyncService.resolveAwmcNetQq() ?? '');
        if (!AwmcQrSyncService.qqPattern.hasMatch(qq)) {
          if (context.mounted) {
            showError(context.l10n.flowEnterA512DigitQQID);
          }
          return null;
        }
        return AwmcNetSyncInput(
          qr: qrCode,
          qq: qq,
          refreshRequest: refreshRequest,
          quickUpdate: quickUpdate,
        );
      },
    );
  }
}
