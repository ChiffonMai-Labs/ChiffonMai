import 'package:flutter/material.dart';

import '../entity/FeatureModels.dart';
import '../l10n/LocalizationsExtension.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/DivingFishProbeManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../service/AccountAuthorizationStore.dart';
import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../utils/LoginStateNotifier.dart';
import '../utils/MaimaiHubLoginNotifier.dart';

/// 我的页和首页收藏共用完成状态；显示标题不写回功能键或收藏键。
class AccountAuthorizationStatus {
  AccountAuthorizationStatus._();

  static final Listenable changes = Listenable.merge([
    LuoXueOAuthManager().authorizationState,
    AccountAuthorizationStore.awmcAccount,
    AwmcQuickIdentityStore.linked,
    // 「绑定与授权管理」的状态标签也要跟随水鱼与 Score Hub 登录态。
    LoginStateNotifier.instance,
    MaimaiHubLoginNotifier.instance,
    DivingFishOAuthManager().authorizationState,
  ]);

  static Future<void> refresh() async {
    await Future.wait([
      _read('落雪授权', () => LuoXueOAuthManager().isLoggedIn()),
      _read('AWMC账号', AccountAuthorizationStore.awmcQQ),
      _read('机台身份', AwmcQuickIdentityStore.read),
      _read('水鱼授权', () => DivingFishOAuthManager().refreshAuthorization()),
      _read('Score Hub 登录态', () async {
        final token = await DivingFishProbeManager().ensureAuthToken();
        MaimaiHubLoginNotifier.instance.value = token != null;
        return token;
      }),
    ]);
  }

  static Future<void> _read(
      String label, Future<Object?> Function() read) async {
    try {
      await read();
    } catch (error) {
      // 单项读取失败不覆盖已有状态，也不影响其它按钮更新。
      debugPrint('读取$label完成状态失败：$error');
    }
  }

  static ButtonItem present(BuildContext context, ButtonItem item) {
    final l10n = context.l10n;
    if (item.title == '落雪账号授权' &&
        LuoXueOAuthManager().authorizationState.value) {
      return ButtonItem(
        icon: Icons.verified_user_outlined,
        title: l10n.accountLXNSAuthorized,
        subtitle: l10n.accountLXNSAuthorizedSubtitle,
      );
    }
    if (item.title == '绑定 AWMC NET 账号' &&
        RegExp(r'^\d{5,12}$')
            .hasMatch(AccountAuthorizationStore.awmcAccount.value)) {
      return ButtonItem(
        icon: Icons.check_circle_outline,
        title: l10n.accountAWMCLinked,
        subtitle: l10n.accountAWMCLinkedSubtitle(
            AccountAuthorizationStore.awmcAccount.value),
      );
    }
    if (item.title == '绑定机台身份' && AwmcQuickIdentityStore.linked.value) {
      return ButtonItem(
        icon: Icons.verified_outlined,
        title: l10n.flowCabinetIdentityLinked,
        subtitle: l10n.accountCabinetLinkedSubtitle,
      );
    }
    return item;
  }
}
