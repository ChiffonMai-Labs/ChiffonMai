import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/DivingFish/ProberException.dart';
import 'ExternalUrlPolicy.dart';
import 'ExternalLaunchUtil.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../widgets/AppDialogs.dart';
import '../service/RankingList/RankingUploadGuard.dart';

/// 刷新水鱼成绩失败时，统一给用户的交代。
///
/// 为什么要有这个函数：首页（`HomePage._openRefreshData`）和「系统」Tab
/// （`SystemHubPage`）各有一套刷新入口与进度显示，但**错误处理必须一致**。
/// 原来只有「系统」Tab 处理了 `CONSENT_REQUIRED`（直接拉起水鱼授权页），
/// 首页只弹一句「刷新数据失败：该用户尚未授权本应用，请先完成绑定后再试」——
/// 用户被告知「请先完成绑定」，却没有任何绑定入口，只能自己猜去哪里绑。
///
/// 水鱼 OAuth 文档 §4.3 要求 `consent_required` 时「引导用户完成一次绑定」，
/// 这个函数就是那一步。
///
/// [qq] 是本次要刷新的 QQ；为空时无法发起绑定，只给文案提示。
Future<void> presentRefreshError(
  BuildContext context,
  Object error, {
  String qq = '',
}) async {
  // 排行榜上传没有完成：成绩已经刷新保存，单独说明原因，不当作刷新失败
  if (error is RankingUploadException) {
    await showAppNoticeDialog(
      context,
      title: context.l10n.rankingUploadIncompleteTitle,
      message: '${context.l10n.rankingUploadIncompleteLead}\n\n${error.message}',
      tone: switch (error.issue) {
        RankingUploadIssue.blacklisted => AppDialogTone.error,
        RankingUploadIssue.upgradeRequired => AppDialogTone.info,
        _ => AppDialogTone.warning,
      },
    );
    return;
  }
  if (error is ProberException && error.code == 'CONSENT_REQUIRED') {
    // 好友对比路径会带上现成的授权链接；没有就现发起一次设备码绑定。
    var url = error.bindingUrl ?? '';
    if (url.isEmpty && qq.isNotEmpty) {
      url = await DivingFishOAuthManager().startBinding(qq);
    }
    if (!context.mounted) return;

    if (url.isEmpty) {
      await showErrorMessageDialog(
        context,
        title: context.l10n.flowCouldNotRefreshData,
        message: qq.isEmpty
            ? error.message
            : context.l10n.flowQQP0HasNotAuthorizedThisApp((qq).toString()),
      );
      return;
    }

    // 只打开，不重查授权状态：用户此刻还没点「同意」，
    // 立刻回查必然仍是未授权（真正的重查入口在刷新对话框里）。
    var opened = false;
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && ExternalUrlPolicy.isAllowed(uri)) {
        opened = await ExternalLaunchUtil.open(uri);
      }
    } catch (e) {
      debugPrint('打开水鱼授权页失败: $e');
    }
    if (!context.mounted) return;
    await showErrorMessageDialog(
      context,
      title: opened
          ? context.l10n.flowAuthorizationNeeded
          : context.l10n.flowCouldNotRefreshData,
      message: opened
          ? context.l10n.flowThisQQHasNotAuthorizedTheApp
          : context.l10n.flowThisQQHasNotAuthorizedTheApp2,
    );
    return;
  }

  await showErrorMessageDialog(context,
      message: context.l10n.flowCouldNotRefreshDataP0((error).toString()));
}
