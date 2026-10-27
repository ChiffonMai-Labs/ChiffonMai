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

/// 系统页展示与选择的是完整社区装扮，同步状态涵盖全部四项。
class CommunityAppearanceBanner extends StatefulWidget {
  final AvatarSyncState appearance;
  final String nickname;
  final VoidCallback onPickTap, onRetry;
  const CommunityAppearanceBanner(
      {super.key,
      required this.appearance,
      required this.nickname,
      required this.onPickTap,
      required this.onRetry});

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

  Duration _duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 360);

  Widget _detail(BuildContext context, Widget child) => IgnorePointer(
        ignoring: !_expanded,
        child: ExcludeSemantics(
          excluding: !_expanded,
          child: ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _expanded ? 1 : 0,
              duration: _duration(context),
              curve: Curves.easeInOutCubic,
              child: SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  opacity: _expanded ? 1 : 0,
                  duration: _duration(context),
                  curve: Curves.easeInOut,
                  child: TickerMode(enabled: _expanded, child: child),
                ),
              ),
            ),
          ),
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
      AvatarSyncLevel.synced => '已同步',
      AvatarSyncLevel.syncing => '同步中',
      AvatarSyncLevel.error => '同步失败',
      AvatarSyncLevel.pending => '待同步',
      AvatarSyncLevel.localOnly => '仅本机',
    };
    return Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
            onTap: onPickTap,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (appearance.frameId != null)
                        _detail(
                            context,
                            SizedBox(
                                height: 92,
                                child: LxnsAssetImage(
                                    url: lxnsFrameUrl(appearance.frameId!),
                                    fit: BoxFit.cover))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  CommunityAvatar(
                                      avatarId: appearance.avatarId, size: 68),
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
                                                  ? '切换为简略信息'
                                                  : '展开详细信息',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: _toggleExpanded,
                                              icon: AnimatedRotation(
                                                turns: _expanded ? 0 : 0.5,
                                                duration: _duration(context),
                                                curve: Curves.easeInOutCubic,
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
                                                    : onPickTap,
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
                                                      Text(statusLabel,
                                                          style: TextStyle(
                                                              color: color,
                                                              fontSize: 12)),
                                                    ]),
                                              ),
                                            ),
                                            Text('点击选择社区装扮',
                                                style: TextStyle(
                                                    color: scheme.primary,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('可按需在下方管理账号数据',
                                            style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 11)),
                                      ]))
                                ]),
                                if (appearance.plateId != null)
                                  _detail(
                                      context,
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: AspectRatio(
                                              aspectRatio: 720 / 116,
                                              child: LxnsAssetImage(
                                                  url: lxnsPlateUrl(
                                                      appearance.plateId!),
                                                  fit: BoxFit.contain)))),
                                if (appearance.trophy != null)
                                  _detail(
                                      context,
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: TrophyTitleBadge(
                                              name: appearance.trophy?['name']
                                                      ?.toString() ??
                                                  '称号 #${appearance.trophyId}',
                                              color: appearance.trophy?['color']
                                                  ?.toString(),
                                              trophyId: appearance.trophyId))),
                              ])),
                    ]))));
  }
}
