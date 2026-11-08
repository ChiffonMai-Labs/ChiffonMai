import 'package:flutter/material.dart';

import '../constant/CacheKeyConstant.dart';
import '../l10n/LocalizationsExtension.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../service/AccountAuthorizationStore.dart';
import '../service/AccountStore.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/LoginStateNotifier.dart';
import '../utils/MaimaiHubLoginNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import 'AccountAuthorizationStatus.dart';
import 'AppDialogs.dart';

/// 「绑定与授权管理」管理的目标。
enum AccountBindingTarget {
  scoreHub,
  divingFish,
  divingFishAuth,
  lxns,
  awmc,
  cabinet
}

extension AccountBindingTargetState on AccountBindingTarget {
  /// 当前是否已登录 / 授权 / 绑定；数据全部来自共享通知器，读值不触发 IO。
  bool get done => switch (this) {
        AccountBindingTarget.scoreHub => MaimaiHubLoginNotifier.instance.value,
        AccountBindingTarget.divingFish => LoginStateNotifier.instance.value,
        AccountBindingTarget.divingFishAuth =>
          LoginStateNotifier.instance.value &&
              DivingFishOAuthManager().authorizationState.value == true,
        AccountBindingTarget.lxns =>
          LuoXueOAuthManager().authorizationState.value,
        AccountBindingTarget.awmc => RegExp(r'^\d{5,12}$')
            .hasMatch(AccountAuthorizationStore.awmcAccount.value),
        AccountBindingTarget.cabinet => AwmcQuickIdentityStore.linked.value,
      };

  String name(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccountBindingTarget.scoreHub => l10n.accountBindingScoreHub,
      AccountBindingTarget.divingFish => l10n.accountBindingDivingFish,
      AccountBindingTarget.divingFishAuth => l10n.accountBindingDivingFishAuth,
      AccountBindingTarget.lxns => l10n.accountBindingLxns,
      AccountBindingTarget.awmc => l10n.accountBindingAwmc,
      AccountBindingTarget.cabinet => l10n.accountBindingCabinet,
    };
  }

  String status(BuildContext context) {
    final l10n = context.l10n;
    final ok = done;
    return switch (this) {
      AccountBindingTarget.scoreHub || AccountBindingTarget.divingFish =>
        ok ? l10n.accountBindingSignedIn : l10n.accountBindingSignedOut,
      AccountBindingTarget.divingFishAuth => ok
          ? l10n.accountBindingAuthorized
          : LoginStateNotifier.instance.value &&
                  DivingFishOAuthManager().authorizationState.value == null
              ? l10n.accountBindingUnknown
              : l10n.accountBindingUnauthorized,
      AccountBindingTarget.lxns =>
        ok ? l10n.accountBindingAuthorized : l10n.accountBindingUnauthorized,
      AccountBindingTarget.awmc || AccountBindingTarget.cabinet =>
        ok ? l10n.accountBindingLinked : l10n.accountBindingUnlinked,
    };
  }

  /// 对话框里每一项的操作名称（水鱼已登录时变为登出）。
  String action(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccountBindingTarget.scoreHub => l10n.featureSignInToMaimaiScoreHub,
      AccountBindingTarget.divingFish => done
          ? l10n.featureSignOutOfDivingFish
          : l10n.featureSignInToDivingFish,
      AccountBindingTarget.divingFishAuth => l10n.flowDivingFishAuthorization,
      AccountBindingTarget.lxns => l10n.accountAuthorizeLXNS,
      AccountBindingTarget.awmc => l10n.accountLinkAWMC,
      AccountBindingTarget.cabinet => l10n.flowLinkCabinetIdentity,
    };
  }

  IconData get icon => switch (this) {
        AccountBindingTarget.scoreHub => Icons.document_scanner_outlined,
        AccountBindingTarget.divingFish => Icons.water_outlined,
        AccountBindingTarget.divingFishAuth => Icons.verified_user_outlined,
        AccountBindingTarget.lxns => Icons.ac_unit_outlined,
        AccountBindingTarget.awmc => Icons.link_outlined,
        AccountBindingTarget.cabinet => Icons.qr_code_2,
      };
}

/// 各状态通知器合在一起，任一变化即时刷新标签和对话框。
Listenable get accountBindingChanges => AccountAuthorizationStatus.changes;

/// 单个状态标签：图标 + 「目标 · 状态」。
class AccountBindingStatusChip extends StatelessWidget {
  final AccountBindingTarget target;

  /// 对话框里每行已写明操作名称，只显示状态。
  final bool showName;

  const AccountBindingStatusChip(
      {super.key, required this.target, this.showName = true});

  @override
  Widget build(BuildContext context) => StatusChip(
        done: target.done,
        text: showName
            ? '${target.name(context)} · ${target.status(context)}'
            : target.status(context),
      );
}

/// 完成 / 未完成两态的小胶囊，绑定状态与成绩导入凭据状态共用。
class StatusChip extends StatelessWidget {
  final bool done;
  final String text;

  /// 当前使用中的项用主题色描边标出（如当前数据源）。
  final bool highlighted;

  /// 只显示名称时，把完整状态交给读屏。
  final String? semanticsLabel;

  const StatusChip({
    super.key,
    required this.done,
    required this.text,
    this.highlighted = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final foreground = done
        ? AppColors.successForeground(brightness)
        : scheme.onSurfaceVariant;
    final chip = AnimatedContainer(
      duration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 220)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: done
            ? AppColors.successSurface(brightness)
            : AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(999),
        // 描边始终占位，切换高亮时标签尺寸不变。
        border: Border.all(
            color: highlighted ? scheme.primary : Colors.transparent),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 12, color: foreground),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: foreground)),
      ]),
    );
    if (semanticsLabel == null) return chip;
    return Semantics(
        label: semanticsLabel, excludeSemantics: true, child: chip);
  }
}

/// 一行状态标签：不换行；极端字号下横向滚动，而不是缩小标签。
class StatusChipRow extends StatelessWidget {
  final List<Widget> chips;

  const StatusChipRow({super.key, required this.chips});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            chips[i],
          ],
        ]),
      );
}

/// 「成绩导入凭据」按钮下方的三个状态标签：水鱼 / 落雪 / AWMC NET。
/// 凭据写入或删除后由 [SecureCredentialStore.revision] 触发重新读取。
class ImportCredentialStatusFooter extends StatefulWidget {
  const ImportCredentialStatusFooter({super.key});

  @override
  State<ImportCredentialStatusFooter> createState() =>
      _ImportCredentialStatusFooterState();
}

class _ImportCredentialStatusFooterState
    extends State<ImportCredentialStatusFooter> {
  static const _keys = [
    CacheKeyConstant.probeDivingFishImportToken,
    CacheKeyConstant.probeLxnsImportToken,
    CacheKeyConstant.awmcNetImportToken,
  ];
  List<bool> _saved = const [false, false, false];
  int _request = 0;

  @override
  void initState() {
    super.initState();
    SecureCredentialStore.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    SecureCredentialStore.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final saved = await Future.wait(_keys.map((key) async {
      try {
        return (await SecureCredentialStore.read(key))?.trim().isNotEmpty ??
            false;
      } catch (_) {
        return false;
      }
    }));
    // 旧请求不覆盖新结果。
    if (mounted && request == _request) setState(() => _saved = saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = [
      l10n.accountBindingDivingFish,
      l10n.accountBindingLxns,
      l10n.accountBindingAwmc,
    ];
    // 只显示名称，状态由图标与配色表达，三个标签保持原尺寸放进一行。
    return StatusChipRow(chips: [
      for (var i = 0; i < names.length; i++)
        StatusChip(
          done: _saved[i],
          text: names[i],
          semanticsLabel:
              '${names[i]} · ${_saved[i] ? l10n.flowSet : l10n.flowNotSet}',
        ),
    ]);
  }
}

/// 「绑定与授权管理」按钮下方的状态标签，自己订阅通知器即时更新。
class AccountBindingStatusFooter extends StatelessWidget {
  const AccountBindingStatusFooter({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: accountBindingChanges,
        builder: (context, _) => Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final target in AccountBindingTarget.values)
              AccountBindingStatusChip(target: target),
          ]),
        ),
      );
}

/// 选择要操作的目标；对话框内的状态同样即时更新。返回 null 表示取消。
Future<AccountBindingTarget?> showAccountBindingDialog(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<AccountBindingTarget>(
    context: context,
    builder: (ctx) => ListenableBuilder(
      listenable: accountBindingChanges,
      builder: (ctx, _) => AppAlertDialog(
        title: Text(ctx.l10n.accountBindingManage),
        subtitle: ctx.l10n.accountBindingManageSubtitle,
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final target in AccountBindingTarget.values) ...[
              AppDialogOption(
                title: target.action(ctx),
                leading: Icon(target.icon,
                    size: 22, color: Theme.of(ctx).colorScheme.primary),
                trailing: AccountBindingStatusChip(
                    target: target, showName: false),
                onTap: () => Navigator.of(ctx).pop(target),
              ),
              if (target != AccountBindingTarget.values.last)
                const SizedBox(height: 8),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.featureClose),
          ),
        ],
      ),
    ),
  );
}

/// 「切换账号」下方的三个标签：各数据源是否已保存账号，当前数据源描边标出。
class AccountSwitchStatusFooter extends StatefulWidget {
  const AccountSwitchStatusFooter({super.key});

  @override
  State<AccountSwitchStatusFooter> createState() =>
      _AccountSwitchStatusFooterState();
}

class _AccountSwitchStatusFooterState extends State<AccountSwitchStatusFooter> {
  Set<String> _saved = const {};
  int _request = 0;

  @override
  void initState() {
    super.initState();
    AccountStore.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AccountStore.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final all = await AccountStore.loadAll();
      final saved = {
        for (final e in all.entries)
          if (e.value.id.isNotEmpty) e.key,
      };
      if (mounted && request == _request) setState(() => _saved = saved);
    } catch (_) {
      // 读取失败时保留上次结果。
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<RefreshDataSource>(
      valueListenable: CurrentDataSourceNotifier.instance,
      builder: (context, current, _) => StatusChipRow(chips: [
        for (final source in RefreshDataSource.values)
          StatusChip(
            done: _saved.contains(source.key),
            highlighted: source == current,
            // 当前使用中的账号：描边之外再加「当前：」前缀。
            text: source == current
                ? l10n.accountSwitchCurrentLabel(source.displayName)
                : source.displayName,
            semanticsLabel: [
              source.displayName,
              _saved.contains(source.key)
                  ? l10n.accountSwitchSaved
                  : l10n.accountSwitchNotSaved,
              if (source == current) l10n.accountSwitchCurrent,
            ].join(' · '),
          ),
      ]),
    );
  }
}
