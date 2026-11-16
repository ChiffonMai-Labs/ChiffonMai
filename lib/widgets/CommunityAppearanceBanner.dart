import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import 'dart:async';

import 'TrophyTitleBadge.dart';
import 'CommunitySyncStatusIcon.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/CacheKeyConstant.dart';
import '../service/CommunityAvatarStore.dart';
import '../utils/AppTheme.dart';
import '../utils/UserProfileNotifier.dart';
import 'CommunityAvatar.dart';
import 'LxnsAssetImage.dart';
import '../utils/AppDesignTokens.dart';
import 'AppUi.dart' show AnimatedReveal, AppCard, PressScale;

/// 系统页的社区装扮入口，含公开装扮和本机角色设置。
class CommunityAppearanceBanner extends StatefulWidget {
  final AvatarSyncState appearance;
  final String nickname;

  /// 打开装扮选择器，参数是初始页：0 头像、1 姓名框、2 背景、3 称号。
  final ValueChanged<int> onPickTap;
  final VoidCallback onRetry;
  final VoidCallback onTravelAppearanceTap;
  const CommunityAppearanceBanner(
      {super.key,
      required this.appearance,
      required this.nickname,
      required this.onPickTap,
      required this.onRetry,
      required this.onTravelAppearanceTap});

  @override
  State<CommunityAppearanceBanner> createState() =>
      _CommunityAppearanceBannerState();
}

class _CommunityAppearanceBannerState extends State<CommunityAppearanceBanner> {
  static bool? _rememberedExpanded;
  static Future<void> _pendingWrites = Future<void>.value();
  bool _expanded = _rememberedExpanded ?? false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExpanded());
  }

  Future<void> _loadExpanded() async {
    if (_rememberedExpanded != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // 用户已操作或页面已重建时，旧读取不能覆盖最新选择。
      if (!mounted || _rememberedExpanded != null) return;
      final expanded =
          prefs.getBool(CacheKeyConstant.communityProfileExpanded) ?? false;
      _rememberedExpanded = expanded;
      if (_expanded != expanded) setState(() => _expanded = expanded);
    } catch (_) {
      // 读取失败仍保持默认收起，用户可继续切换。
    }
  }

  void _toggleExpanded() {
    final expanded = !_expanded;
    _rememberedExpanded = expanded;
    setState(() => _expanded = expanded);
    // 内存立即更新，连续点击的写盘操作按顺序执行。
    _pendingWrites = _pendingWrites.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            CacheKeyConstant.communityProfileExpanded, expanded);
      } catch (_) {
        // 写盘失败不影响当前页面与本次启动期间的显示状态。
      }
    });
    unawaited(_pendingWrites);
  }

  Widget _detail(Widget child) => AnimatedReveal(
        visible: _expanded,
        child: SizedBox(width: double.infinity, child: child),
      );

  /// 展开时点哪张收藏品图片就直达对应选择页；收起时交给外层，固定打开第一页。
  Widget _pickArea(int tab, String label, Widget child) => Semantics(
        button: _expanded,
        label: _expanded ? label : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _expanded ? () => widget.onPickTap(tab) : null,
          child: PressScale(scale: 0.98, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance,
        nickname = widget.nickname,
        onPickTap = widget.onPickTap,
        onRetry = widget.onRetry;
    final scheme = Theme.of(context).colorScheme,
        brightness = Theme.of(context).brightness;
    final color = switch (appearance.level) {
      AvatarSyncLevel.synced => AppColors.successGreen(brightness),
      AvatarSyncLevel.syncing => AppColors.linkBlue(brightness),
      AvatarSyncLevel.error => AppColors.errorRed(brightness),
      _ => AppColors.warningOrange(brightness),
    };
    final statusLabel = switch (appearance.level) {
      AvatarSyncLevel.synced => context.l10n.featureSynced,
      AvatarSyncLevel.syncing => context.l10n.featureSyncing,
      AvatarSyncLevel.error => context.l10n.featureSyncFailed,
      AvatarSyncLevel.pending => context.l10n.featurePendingSync,
      AvatarSyncLevel.localOnly => context.l10n.featureLocalOnly,
    };
    return Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
            onTap: () => onPickTap(0),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: AppSurfaces.card(context),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (appearance.frameId != null)
                        _detail(_pickArea(
                            2,
                            context.featureText('背景'),
                            SizedBox(
                                height: 92,
                                child: LxnsAssetImage(
                                    url: lxnsFrameUrl(appearance.frameId!),
                                    fit: BoxFit.cover)))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  _pickArea(
                                      0,
                                      context.featureText('头像'),
                                      CommunityAvatar(
                                          avatarId: appearance.avatarId,
                                          size: 68)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        // 按钮叠放在昵称右侧，不参与行高计算。
                                        Stack(children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(
                                                    nickname.isEmpty
                                                        ? kUnsetNicknameLabel
                                                        : nickname,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800))),
                                            const SizedBox(width: 40),
                                          ]),
                                          Positioned(
                                            top: 0,
                                            bottom: 0,
                                            right: 0,
                                            width: 36,
                                            child: IconButton(
                                              style: ButtonStyle(
                                                splashFactory:
                                                    NoSplash.splashFactory,
                                                overlayColor: WidgetStateProperty
                                                    .resolveWith<Color?>(
                                                        (states) => states
                                                                .contains(
                                                                    WidgetState
                                                                        .pressed)
                                                            ? Colors.transparent
                                                            : null),
                                              ),
                                              padding: EdgeInsets.zero,
                                              tooltip: _expanded
                                                  ? context
                                                      .featureText('切换为简略信息')
                                                  : context
                                                      .featureText('展开详细信息'),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: _toggleExpanded,
                                              icon: AnimatedRotation(
                                                turns: _expanded ? 0 : 0.5,
                                                duration:
                                                    AppDesignTokens.motion(
                                                        context,
                                                        AppDesignTokens
                                                            .mediumMotion),
                                                curve: AppDesignTokens
                                                    .emphasizedCurve,
                                                child: const Icon(
                                                    Icons.expand_less_rounded,
                                                    size: 22),
                                              ),
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Tooltip(
                                              message: appearance.message,
                                              child: InkWell(
                                                splashFactory:
                                                    NoSplash.splashFactory,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: appearance.playerId !=
                                                            null &&
                                                        appearance.level !=
                                                            AvatarSyncLevel
                                                                .synced
                                                    ? onRetry
                                                    : () => onPickTap(0),
                                                child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // 按中文字形的视觉中心微调，避免图标显得偏高。
                                                      Transform.translate(
                                                        offset:
                                                            const Offset(0, 1),
                                                        child:
                                                            CommunitySyncStatusIcon(
                                                          level:
                                                              appearance.level,
                                                          color: color,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                          context.featureText(
                                                              statusLabel),
                                                          style: TextStyle(
                                                              color: color,
                                                              fontSize: 12)),
                                                    ]),
                                              ),
                                            ),
                                            Text(
                                                context.featureText('点击选择社区装扮'),
                                                style: TextStyle(
                                                    color: scheme.primary,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                            context.featureText('可按需在下方管理账号数据'),
                                            style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 11)),
                                      ]))
                                ]),
                                if (appearance.plateId != null)
                                  _detail(Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _pickArea(
                                          1,
                                          context.featureText('姓名框'),
                                          AspectRatio(
                                              aspectRatio: 720 / 116,
                                              child: LxnsAssetImage(
                                                  url: lxnsPlateUrl(
                                                      appearance.plateId!),
                                                  fit: BoxFit.contain))))),
                                if (appearance.trophy != null)
                                  _detail(Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _pickArea(
                                          3,
                                          context.featureText('称号'),
                                          TrophyTitleBadge(
                                              name: appearance.trophy?['name']
                                                      ?.toString() ??
                                                  context.l10n.homeTrophyId(
                                                      appearance.trophyId
                                                          .toString()),
                                              color: appearance.trophy?['color']
                                                  ?.toString(),
                                              trophyId: appearance.trophyId)))),
                                const SizedBox(height: 12),
                                AppCard(
                                  color: AppSurfaces.inset(context),
                                  radius: AppDesignTokens.radiusSmall,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  onTap: widget.onTravelAppearanceTap,
                                  child: Row(
                                    children: [
                                      Icon(Icons.groups_rounded,
                                          color: scheme.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          context.l10n.communityTravelAppearance,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: scheme.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ])),
                    ]))));
  }
}
