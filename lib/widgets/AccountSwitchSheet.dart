import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../service/AccountStore.dart';
import '../service/AccountSwitchService.dart';
import '../utils/AppError.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import 'FishIcon.dart';
import 'MarqueeText.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 弹出「切换账号」底部面板。
///
/// 三个数据源（水鱼 / 落雪 / AWMC NET）各占一行；点击即用**缓存**切换数据源与
/// 玩家信息，不联网。目标账号没有缓存时提示并回调 [onNeedRefresh] 引导去刷新。
Future<void> showAccountSwitchSheet(
  BuildContext context, {
  required Future<void> Function(RefreshDataSource source) onNeedRefresh,
}) async {
  final metas = await AccountStore.loadAll();
  if (!context.mounted) return;
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  // 拖拽锁定会更换 Material 面板的包裹层，保留正在处理的表单状态。
  final sheetKey = GlobalKey<_AccountSwitchSheetState>();
  late final _AccountSwitchSheetRoute route;
  route = _AccountSwitchSheetRoute(
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint:
        localizations.scrimOnTapHint(localizations.bottomSheetLabel),
    modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
    isScrollControlled: true,
    constraints:
        BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
    builder: (_) => _AccountSwitchSheet(
      key: sheetKey,
      initialMetas: metas,
      onNeedRefresh: onNeedRefresh,
      onBusyChanged: route.setBusy,
    ),
  );
  await navigator.push(route);
}

/// 处理账号时锁定遮罩、拖拽和系统返回。
class _AccountSwitchSheetRoute extends ModalBottomSheetRoute<void> {
  _AccountSwitchSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.modalBarrierColor,
    super.constraints,
  });

  bool _busy = false;

  @override
  bool get barrierDismissible => !_busy;

  @override
  bool get enableDrag => !_busy;

  @override
  bool get showDragHandle => false;

  @override
  RoutePopDisposition get popDisposition =>
      _busy ? RoutePopDisposition.doNotPop : super.popDisposition;

  void setBusy(bool busy) {
    if (_busy == busy) return;
    _busy = busy;
    changedExternalState();
  }
}

/// 我的页使用对话框，账号操作仍与首页底部面板共用。
Future<void> showAccountSwitchDialog(
  BuildContext context, {
  required Future<void> Function(RefreshDataSource source) onNeedRefresh,
}) async {
  final metas = await AccountStore.loadAll();
  if (!context.mounted) return;
  await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AppAlertDialog(
            title: Text(context.l10n.flowSwitchAccount),
            content: SizedBox(
                width: 520,
                child: _AccountSwitchSheet(
                    initialMetas: metas,
                    onNeedRefresh: onNeedRefresh,
                    dialog: true)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(context.l10n.featureCancel),
              ),
            ],
          ));
}

class _AccountSwitchSheet extends StatefulWidget {
  final bool dialog;
  final Map<String, AccountMeta> initialMetas;
  final Future<void> Function(RefreshDataSource source) onNeedRefresh;
  final ValueChanged<bool>? onBusyChanged;

  const _AccountSwitchSheet({
    super.key,
    this.dialog = false,
    required this.initialMetas,
    required this.onNeedRefresh,
    this.onBusyChanged,
  });

  @override
  State<_AccountSwitchSheet> createState() => _AccountSwitchSheetState();
}

class _AccountSwitchSheetState extends State<_AccountSwitchSheet> {
  late final Map<String, AccountMeta> _metas = widget.initialMetas;
  bool _busy = false;

  /// 正在切换到哪个源（用于在对应行上显示转圈）
  RefreshDataSource? _switchingTo;

  /// 正在清除哪个源的数据
  RefreshDataSource? _clearing;

  /// 清除某个账号的缓存数据（保留登录状态）
  Future<void> _onClearAccount(RefreshDataSource source) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AppAlertDialog(
        title: Text(context.l10n
            .flowClearP0AccountData(appLocalizeLabel(source.displayName))),
        content: Text(context.l10n.flowThisDeletesLocalP0CachesScoresBest50(
            appLocalizeLabel(source.displayName))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(context.l10n.flowClear,
                style: TextStyle(color: Theme.of(dialogCtx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;

    setState(() {
      _busy = true;
      _clearing = source;
    });
    widget.onBusyChanged?.call(true);
    try {
      await AccountSwitchService.clearAccountData(source);
      final loaded = await AccountStore.loadAll();
      if (!mounted) return;
      setState(() => _metas
        ..clear()
        ..addAll(loaded));
      AppToast.show(
          context.l10n
              .flowClearedP0AccountData(appLocalizeLabel(source.displayName)),
          tone: AppToastTone.success);
    } catch (e, stack) {
      if (!mounted) return;
      AppToast.showError(e, stack: stack, stage: '清除账号数据');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _clearing = null;
        });
        widget.onBusyChanged?.call(false);
      }
    }
  }

  Future<void> _onTapAccount(RefreshDataSource source) async {
    if (_busy) return;
    final current = CurrentDataSourceNotifier.instance.value;
    if (source == current) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _busy = true;
      _switchingTo = source;
    });
    widget.onBusyChanged?.call(true);
    var outcome = SwitchOutcome.failed;
    try {
      outcome = await AccountSwitchService.switchTo(source);
    } catch (error) {
      debugPrint('切换账号失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _switchingTo = null;
        });
        widget.onBusyChanged?.call(false);
      }
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    switch (outcome) {
      case SwitchOutcome.switched:
        Navigator.of(context).pop();
        AppToast.show(
            context.l10n
                .flowSwitchedToP0Account(appLocalizeLabel(source.displayName)),
            tone: AppToastTone.success);
        break;
      case SwitchOutcome.sameSource:
        Navigator.of(context).pop();
        break;
      case SwitchOutcome.failed:
        AppToast.showError(
          AppError(
            code: 'DATA-ACCOUNT-SWITCH',
            userMessage: context.l10n.flowAccountSwitchFailedAttemptedToRestoreThe,
            stage: '切换账号',
            source: source.key,
          ),
          stage: '切换账号',
        );
        break;
      case SwitchOutcome.busy:
        AppToast.show(context.l10n.flowSwitchingPleaseWait,
            tone: AppToastTone.warning);
        break;
      case SwitchOutcome.noCache:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AppAlertDialog(
            title: Text(context.l10n.flowNoCachedDataForThisAccount),
            content: Text(context.l10n.flowNoDataHasBeenCachedForP0(
                appLocalizeLabel(source.displayName))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(context.l10n.featureCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(context.l10n.flowRefreshNow),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.of(context).pop();
          await widget.onNeedRefresh(source);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
          child: Padding(
        padding: widget.dialog
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.dialog) ...[
              // 拖拽手柄始终占满 48dp，避免切换期间路由移除原生手柄引发面板高度塌陷。
              SizedBox(
                height: kMinInteractiveDimension,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: _busy ? 0.0 : 1.0,
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Text(context.l10n.flowSwitchAccount,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface)),
            ],
            const SizedBox(height: 4),
            // 切换中：固定最小高度避免状态文案 1~2 行切换引起高度跳动
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _switchingTo != null
                    ? Row(children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              widget.dialog
                                  ? context.l10n.flowSwitchingToP0(
                                      appLocalizeLabel(
                                          _switchingTo!.displayName))
                                  : context.l10n.accountSwitchSheetBusy,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary),
                            ),
                          ),
                        ),
                      ])
                    : Text(context.l10n.flowTapAnAccountToSwitchSourceAnd,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
              ),
            ),
            const SizedBox(height: 12),
            // 逐个源渲染（水鱼 / 落雪 / AWMC NET）。
            // 原来是写死两行，加第三个源时必须记得再加一行；改成枚举就不会漏。
            for (final source in RefreshDataSource.values) ...[
              _buildAccountTile(source),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Text(context.l10n.flowRefreshToUpdateTheActiveAccountDiving,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        ),
      )),
    );
  }

  /// 各数据源的图标：水鱼用自绘的 FishIcon，落雪雪花，AWMC NET 用云（它是 web 查分站）。
  Widget _sourceIcon(RefreshDataSource source, Color color) {
    switch (source) {
      case RefreshDataSource.shuiyu:
        return FishIcon(size: 24, color: color);
      case RefreshDataSource.luoxue:
        return Icon(Icons.ac_unit_outlined, color: color);
      case RefreshDataSource.awmc:
        return Icon(Icons.cloud_outlined, color: color);
    }
  }

  Widget _buildAccountTile(RefreshDataSource source) {
    final scheme = Theme.of(context).colorScheme;
    final bool isCurrent = CurrentDataSourceNotifier.instance.value == source;
    final meta = _metas[source.key];
    final bool hasData = meta?.hasData ?? false;
    final String nickname = (meta?.nickname.isNotEmpty ?? false)
        ? meta!.nickname
        : context.l10n.flowP0Account(appLocalizeLabel(source.displayName));
    // 水鱼 / AWMC NET 都是按 QQ，只有落雪是 friendCode
    final String idLine = (meta?.id.isNotEmpty ?? false)
        ? '${source.idIsQQ ? 'QQ' : 'ID'} ${meta!.id}'
        : context.l10n.flowNotLinked;
    final ratingLine =
        'RA ${meta?.best50TotalRA ?? 0}  B35 ${meta?.best35TotalRA ?? 0}  B15 ${meta?.best15TotalRA ?? 0}';
    final bool isSwitching = _switchingTo == source;
    final bool isClearing = _clearing == source;

    final tile = InkWell(
      borderRadius: BorderRadius.circular(12),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      onTap: _busy ? null : () => _onTapAccount(source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
          color: isCurrent
              ? scheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            _sourceIcon(
                source, isCurrent ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (isCurrent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(context.l10n.flowCurrent,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: scheme.primary)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                        child: MarqueeText(
                            text: nickname,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface))),
                  ]),
                  const SizedBox(height: 2),
                  Text(idLine,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  MarqueeText(
                      text: ratingLine,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSwitching || isClearing)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            else ...[
              if (!isCurrent && !hasData)
                Text(context.l10n.flowNoCache,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))
              else if (!isCurrent)
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              // 只有缓存过数据才显示「清除」入口
              if (hasData)
                IconButton(
                  onPressed: _busy ? null : () => _onClearAccount(source),
                  tooltip: context.l10n.flowClearP0AccountData(
                      appLocalizeLabel(source.displayName)),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: Icon(
                    Icons.cleaning_services_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    // 切换/清除中把其他行压暗，突出正在处理的那一行
    if (_busy && !isSwitching && !isClearing) {
      return Opacity(opacity: 0.45, child: tile);
    }
    return tile;
  }
}
