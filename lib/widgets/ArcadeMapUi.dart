import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueListenable, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../entity/nearcade/NearCadeShop.dart';
import '../l10n/LocalizationsExtension.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ArcadeShopUtil.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'AppToast.dart';
import 'AppUi.dart';
import 'FavoriteStarButton.dart';

/// 悬浮在地图上的白卡片底：地图内容杂，需要比普通卡片更明显的投影。
BoxDecoration arcadeFloatingDecoration(BuildContext context, double radius) {
  return BoxDecoration(
    color: AppSurfaces.card(context),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.16),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// 地图右侧的一组按钮，同组之间用分隔线连成一张卡片。
class ArcadeMapControlGroup extends StatelessWidget {
  final List<Widget> children;

  const ArcadeMapControlGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      decoration:
          arcadeFloatingDecoration(context, AppDesignTokens.radiusMedium),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(width: 24, height: 1, color: divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class ArcadeMapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool busy;
  final Color? color;

  const ArcadeMapControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: PressScale(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: busy ? null : onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, size: 22, color: color ?? scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 地图顶部的筛选胶囊。带 [dotColor] 时圆点就是该机台在地图上的标记色。
class ArcadeFilterChip extends StatelessWidget {
  final String label;
  final String? count;
  final bool selected;
  final Color? dotColor;
  final IconData? icon;
  final VoidCallback onTap;

  const ArcadeFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.dotColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDesignTokens.motion(
              context, const Duration(milliseconds: 180)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration:
              arcadeFloatingDecoration(context, AppDesignTokens.radiusPill)
                  .copyWith(color: selected ? scheme.primary : null),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 5),
              ] else if (dotColor != null) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: scheme.onPrimary, width: 1)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(count!,
                    style: AppTheme.number(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.7),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 「营业中 · 22:00 打烊」这样的状态文字。
class ArcadeOpenBadge extends StatelessWidget {
  final ArcadeOpenStatus status;

  const ArcadeOpenBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final time = status.time;
    final (String head, String? tail, Color color) = switch (status.state) {
      ArcadeOpenState.open => (
          l10n.arcadeOpenNow,
          time == null ? null : l10n.arcadeClosesAt(time),
          AppColors.successForeground(theme.brightness),
        ),
      ArcadeOpenState.closed => (
          l10n.arcadeClosedNow,
          time == null
              ? null
              : status.nextDay
                  ? l10n.arcadeOpensTomorrowAt(time)
                  : l10n.arcadeOpensAt(time),
          muted,
        ),
      ArcadeOpenState.unknown => (l10n.arcadeHoursUnknown, null, muted),
    };
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: head,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        if (tail != null)
          TextSpan(text: ' · $tail', style: TextStyle(color: muted)),
      ]),
      style: const TextStyle(fontSize: 12),
    );
  }
}

class _GameTag extends StatelessWidget {
  final Game game;

  const _GameTag(this.game);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.arcadeGame(game.titleId, theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        game.quantity > 1 ? '${game.name} ×${game.quantity}' : game.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 抽屉列表和聚合点列表共用的机厅行。
class ArcadeShopRow extends StatelessWidget {
  static const _maxTags = 3;

  final Shop shop;
  final double? distanceMeters;
  final Set<int> selectedTitles;
  final bool favorited;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const ArcadeShopRow({
    super.key,
    required this.shop,
    required this.selectedTitles,
    required this.favorited,
    required this.onToggleFavorite,
    required this.onTap,
    this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = shop.primaryTitle(selectedTitles);
    final color = AppColors.arcadeGame(title, theme.brightness);
    final distance = distanceMeters;
    final region = shop.address.general.skip(1).join(' ');
    // 筛选中的机台排在前面，否则用户要找的那台可能落在「+N」里。
    final games = [...shop.games]..sort((a, b) =>
        (selectedTitles.contains(b.titleId) ? 1 : 0) -
        (selectedTitles.contains(a.titleId) ? 1 : 0));
    final hidden = games.length - _maxTags;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child:
                  Icon(Icons.videogame_asset_rounded, size: 21, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: scheme.onSurface,
                      )),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (distance != null)
                        Text(formatArcadeDistance(distance),
                            style: AppTheme.number(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            )),
                      ArcadeOpenBadge(status: shop.openStatus()),
                    ],
                  ),
                  if (region.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(region,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                  if (games.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final game in games.take(_maxTags)) _GameTag(game),
                        if (hidden > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 3),
                            child: Text('+$hidden',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                )),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: FavoriteStarButton(
                  isFavorited: favorited,
                  onTap: onToggleFavorite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单家机厅的地图标记。选中时放大并加一圈主题色。
class ArcadeShopMarker extends StatelessWidget {
  final Color color;
  final bool selected;

  const ArcadeShopMarker({
    super.key,
    required this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: selected ? 1.35 : 1,
      duration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 200)),
      curve: AppDesignTokens.emphasizedCurve,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? scheme.primary : Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 4, offset: Offset(0, 1.5)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.videogame_asset_rounded,
              color: Colors.white, size: 13),
        ),
      ),
    );
  }
}

/// 聚合点：数字越大底色越实，一眼能看出机厅密集的地方。
class ArcadeClusterMarker extends StatelessWidget {
  final int count;

  const ArcadeClusterMarker({super.key, required this.count});

  /// 地图 Marker 的外框要提前给定，所以尺寸放在这里算。
  static double sizeFor(int count) => count >= 100
      ? 56
      : count >= 20
          ? 48
          : 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alpha = count >= 100
        ? 0.95
        : count >= 20
            ? 0.82
            : 0.68;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.22),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary.withValues(alpha: alpha),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text('$count',
                style: AppTheme.number(
                  color: scheme.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                )),
          ),
        ),
      ),
    );
  }
}

/// 用户当前位置。
class ArcadeUserMarker extends StatelessWidget {
  const ArcadeUserMarker({super.key});

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F80ED);
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: blue.withValues(alpha: 0.2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blue,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ),
    );
  }
}

// ---- 机厅详情 ----

Future<void> showArcadeShopDetail(
  BuildContext context, {
  required Shop shop,
  required LatLng? userLocation,
  required ValueListenable<Set<int>> favorites,
  required VoidCallback onToggleFavorite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _ArcadeShopDetailSheet(
      shop: shop,
      userLocation: userLocation,
      favorites: favorites,
      onToggleFavorite: onToggleFavorite,
    ),
  );
}

class _ArcadeShopDetailSheet extends StatelessWidget {
  final Shop shop;
  final LatLng? userLocation;
  final ValueListenable<Set<int>> favorites;
  final VoidCallback onToggleFavorite;

  const _ArcadeShopDetailSheet({
    required this.shop,
    required this.userLocation,
    required this.favorites,
    required this.onToggleFavorite,
  });

  /// 只有一个可用的地图 App 就直接打开，多个时让用户选，都没有就用网页地图。
  Future<void> _navigate(BuildContext context) async {
    final links =
        shop.mapLinks(isIOS: defaultTargetPlatform == TargetPlatform.iOS);
    final available = <ArcadeMapLink>[];
    for (final link in links) {
      final probe = link.probe;
      try {
        if (probe == null || await canLaunchUrl(probe)) available.add(link);
      } catch (error) {
        debugPrint('[ArcadeMap] 检测地图应用失败: $error');
      }
    }
    if (!context.mounted) return;
    if (available.isEmpty) {
      await _open(context, shop.navigationUri);
    } else if (available.length == 1) {
      await _openMapLink(context, available.single);
    } else {
      await _chooseMapApp(context, available);
    }
  }

  /// 个别 ROM 检测得到却打不开，失败时退回网页地图。
  Future<void> _openMapLink(BuildContext context, ArcadeMapLink link) async {
    if (await ExternalLaunchUtil.open(link.uri) || !context.mounted) return;
    await _open(context, shop.navigationUri);
  }

  Future<void> _chooseMapApp(
      BuildContext context, List<ArcadeMapLink> links) async {
    final l10n = context.l10n;
    String label(ArcadeMapApp app) => switch (app) {
          ArcadeMapApp.amap => l10n.arcadeMapAmap,
          ArcadeMapApp.baidu => l10n.arcadeMapBaidu,
          ArcadeMapApp.tencent => l10n.arcadeMapTencent,
          ArcadeMapApp.google => l10n.arcadeMapGoogle,
          ArcadeMapApp.apple => l10n.arcadeMapApple,
          ArcadeMapApp.system => l10n.arcadeMapOther,
        };

    Widget option(IconData icon, String title, VoidCallback onTap) {
      final scheme = Theme.of(context).colorScheme;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.gutter, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    )),
              ),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) {
        void choose(Future<void> Function() action) {
          Navigator.pop(sheetContext);
          action();
        }

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 6),
                child: Text(l10n.arcadeChooseMapApp,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              for (final link in links)
                option(
                  Icons.map_outlined,
                  label(link.app),
                  () => choose(() => _openMapLink(context, link)),
                ),
              option(
                Icons.language_rounded,
                l10n.arcadeMapWeb,
                () => choose(() => _open(context, shop.navigationUri)),
              ),
              SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, Uri? uri) async {
    final message = context.l10n.arcadeCouldNotOpenLink;
    if (uri == null || !await ExternalLaunchUtil.open(uri)) {
      AppToast.show(message, tone: AppToastTone.error);
    }
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shop.address.detailed));
    AppToast.show(context.l10n.flowCopiedToClipboard,
        tone: AppToastTone.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final point = shop.latLng;
    final user = userLocation;
    final metro = shop.metroInfo(Localizations.localeOf(context).languageCode);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 1,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(shop.name,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: scheme.onSurface,
                          )),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: favorites,
                      builder: (_, ids, __) => FavoriteStarButton(
                        size: 26,
                        isFavorited: ids.contains(shop.shopId),
                        onTap: onToggleFavorite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ArcadeOpenBadge(status: shop.openStatus()),
                    if (user != null && point != null)
                      Text(
                        l10n.arcadeFromYou(formatArcadeDistance(
                            arcadeDistanceMeters(user, point))),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.cardGap),
                _AddressCard(shop: shop, onCopy: () => _copyAddress(context)),
                if (metro != null) ...[
                  const SizedBox(height: AppDesignTokens.cardGap),
                  _MetroCard(metro: metro),
                ],
                if (shop.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.cardGap),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    radius: AppDesignTokens.radiusMedium,
                    color: AppSurfaces.inset(context),
                    child: _LabeledBlock(
                      label: l10n.arcadeNote,
                      child: Text(shop.comment.trim(),
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: scheme.onSurface)),
                    ),
                  ),
                ],
                if (shop.openingHours.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.cardGap),
                  _HoursCard(shop: shop),
                ],
                if (shop.games.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  AppSectionHeader(title: l10n.flowMachines),
                  AppCard(
                    padding: EdgeInsets.zero,
                    radius: AppDesignTokens.radiusMedium,
                    color: AppSurfaces.inset(context),
                    child: Column(
                      children: [
                        for (final (index, game) in shop.games.indexed)
                          _MachineRow(game: game, showDivider: index > 0),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                if (shop.shopId > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _open(context, shop.nearcadeUri),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(l10n.arcadeViewOnNearcade),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 8, AppDesignTokens.gutter, 12 + bottom),
            child: SizedBox(
              width: double.infinity,
              child: PressScale(
                scale: 0.98,
                child: FilledButton.icon(
                  onPressed: () => _navigate(context),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(l10n.arcadeNavigate),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onCopy;

  const _AddressCard({required this.shop, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final region = shop.address.general.join(' ');
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      radius: AppDesignTokens.radiusMedium,
      color: AppSurfaces.inset(context),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.address.detailed,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: scheme.onSurface,
                    )),
                if (region.isNotEmpty)
                  Text(region,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.arcadeCopyAddress,
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded,
                size: 18, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetroCard extends StatelessWidget {
  final ArcadeMetroInfo metro;

  const _MetroCard({required this.metro});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: AppDesignTokens.radiusMedium,
      color: AppSurfaces.inset(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.subway_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metro.walkMinutes > 0
                      ? l10n.arcadeMetroWalk(
                          metro.station, metro.walkMinutes.toString())
                      : l10n.arcadeMetroStation(metro.station),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: scheme.onSurface,
                  ),
                ),
                if (metro.lines.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final line in metro.lines)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: line.color,
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusPill),
                          ),
                          child: Text(line.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: line.color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  final Shop shop;

  const _HoursCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // narrowWeekdays 从周日开始，数据从周一开始。
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    final today = shop.localNow().weekday - 1;
    final perDay = shop.openingHours.length == 7;

    Widget row(String label, List<OpeningHour>? hours, bool highlighted) {
      final color = highlighted ? scheme.primary : scheme.onSurface;
      final weight = highlighted ? FontWeight.w700 : FontWeight.w500;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: weight, color: color)),
            ),
            Text(hours == null ? '—' : formatArcadeHours(hours),
                style: AppTheme.number(
                    fontSize: 13, fontWeight: weight, color: color)),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: AppDesignTokens.radiusMedium,
      color: AppSurfaces.inset(context),
      child: _LabeledBlock(
        label: l10n.arcadeHours,
        child: Column(
          children: [
            if (perDay)
              for (var day = 0; day < 7; day++)
                row(
                  day == today
                      ? '${weekdays[(day + 1) % 7]} · ${l10n.arcadeToday}'
                      : weekdays[(day + 1) % 7],
                  shop.hoursOn(day),
                  day == today,
                )
            else
              row(l10n.arcadeEveryDay, shop.hoursOn(0), false),
          ],
        ),
      ),
    );
  }
}

class _MachineRow extends StatelessWidget {
  final Game game;
  final bool showDivider;

  const _MachineRow({required this.game, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = [
      if (game.version.isNotEmpty) game.version,
      if (game.cost.isNotEmpty) game.cost,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.arcadeGame(game.titleId, theme.brightness),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    )),
                if (details.isNotEmpty)
                  Text(details,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                if (game.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(game.comment.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('×${game.quantity}',
              style: AppTheme.number(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              )),
        ],
      ),
    );
  }
}

// ---- 机台筛选 ----

/// 机台筛选项：每个 titleId 只展示出现次数最多的 name，
/// 避免一个系列（如 titleId=1）被拆成「maimai DX / 舞萌DX」等多种写法。
class ArcadeGameOption {
  final int titleId;
  final String canonicalName;
  final int count;

  const ArcadeGameOption({
    required this.titleId,
    required this.canonicalName,
    required this.count,
  });
}

/// 完整的机台筛选面板：可搜索的多选列表，选择立即生效，地图在背后同步变化。
Future<void> showArcadeGameFilterSheet(
  BuildContext context, {
  required List<ArcadeGameOption> options,
  required Set<int> selected,
  required ValueChanged<int> onToggle,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _ArcadeGameFilterSheet(
      options: options,
      selected: selected,
      onToggle: onToggle,
      onClear: onClear,
    ),
  );
}

class _ArcadeGameFilterSheet extends StatefulWidget {
  final List<ArcadeGameOption> options;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final VoidCallback onClear;

  const _ArcadeGameFilterSheet({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  @override
  State<_ArcadeGameFilterSheet> createState() => _ArcadeGameFilterSheetState();
}

class _ArcadeGameFilterSheetState extends State<_ArcadeGameFilterSheet> {
  final TextEditingController _search = TextEditingController();
  late final Set<int> _selected = {...widget.selected};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(int titleId) {
    setState(() {
      if (!_selected.remove(titleId)) _selected.add(titleId);
    });
    widget.onToggle(titleId);
  }

  void _clear() {
    setState(_selected.clear);
    widget.onClear();
  }

  Widget _buildRow(ArcadeGameOption option) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = _selected.contains(option.titleId);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(option.titleId),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.gutter, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.arcadeGame(option.titleId, theme.brightness),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(option.canonicalName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: scheme.onSurface,
                  )),
            ),
            Text('${option.count}',
                style: AppTheme.number(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                )),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 22,
              color: isSelected ? scheme.primary : scheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final query = _query.toLowerCase();
    final options = [
      for (final option in widget.options)
        if (query.isEmpty || option.canonicalName.toLowerCase().contains(query))
          option
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 1,
      builder: (context, controller) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.flowMachineFilters,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        )),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: _clear,
                      child: Text(l10n.flowClear),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppSurfaces.inset(context),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded,
                        size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: l10n.arcadeFilterSearchHint,
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: options.isEmpty
                  ? ListView(
                      controller: controller,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(l10n.arcadeFilterEmpty,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: scheme.onSurfaceVariant)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: EdgeInsets.only(
                          bottom: 12 + MediaQuery.paddingOf(context).bottom),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: options.length,
                      itemBuilder: (_, index) => _buildRow(options[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 全球分布 ----

class _ArcadeRegion {
  final String name;
  final List<Shop> shops = [];
  final Map<String, _ArcadeRegion> children = {};

  _ArcadeRegion(this.name);
}

/// 按「国家/地区 → 省」统计当前筛选下的机厅，点一项把地图移过去。
Future<void> showArcadeRegionSheet(
  BuildContext context, {
  required List<Shop> shops,
  required ValueChanged<List<Shop>> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _ArcadeRegionSheet(shops: shops, onSelect: onSelect),
  );
}

class _ArcadeRegionSheet extends StatefulWidget {
  final List<Shop> shops;
  final ValueChanged<List<Shop>> onSelect;

  const _ArcadeRegionSheet({required this.shops, required this.onSelect});

  @override
  State<_ArcadeRegionSheet> createState() => _ArcadeRegionSheetState();
}

class _ArcadeRegionSheetState extends State<_ArcadeRegionSheet> {
  late final List<_ArcadeRegion> _countries = _group();
  late final int _machines =
      widget.shops.fold(0, (sum, shop) => sum + shop.machineCount);
  final Set<String> _expanded = {};

  List<_ArcadeRegion> _group() {
    final countries = <String, _ArcadeRegion>{};
    for (final shop in widget.shops) {
      final general = shop.address.general;
      if (general.isEmpty) continue;
      final country = countries.putIfAbsent(
          general.first, () => _ArcadeRegion(general.first));
      country.shops.add(shop);
      if (general.length >= 2) {
        country.children
            .putIfAbsent(general[1], () => _ArcadeRegion(general[1]))
            .shops
            .add(shop);
      }
    }
    return countries.values.toList()
      ..sort((a, b) => b.shops.length.compareTo(a.shops.length));
  }

  void _select(List<Shop> shops) {
    Navigator.of(context).pop();
    widget.onSelect(shops);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rows = <({_ArcadeRegion region, bool child})>[
      for (final country in _countries) ...[
        (region: country, child: false),
        if (_expanded.contains(country.name))
          for (final province
              in country.children.values.toList()
                ..sort((a, b) => b.shops.length.compareTo(a.shops.length)))
            (region: province, child: true),
      ],
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 1,
      builder: (context, controller) => CustomScrollView(
        controller: controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.arcadeRegions,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      )),
                  const SizedBox(height: AppDesignTokens.cardGap),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                            card: true,
                            label: l10n.arcadeRegionCount,
                            value: '${_countries.length}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                            card: true,
                            label: l10n.arcadeShopCount,
                            value: '${widget.shops.length}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                            card: true,
                            label: l10n.arcadeMachineCount,
                            value: '$_machines'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final region = row.region;
              final expanded = _expanded.contains(region.name);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _select(region.shops),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppDesignTokens.gutter + (row.child ? 20 : 0),
                      row.child ? 9 : 12,
                      8,
                      row.child ? 9 : 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(region.name,
                            style: TextStyle(
                              fontSize: row.child ? 14 : 15,
                              fontWeight:
                                  row.child ? FontWeight.w500 : FontWeight.w700,
                              color: scheme.onSurface,
                            )),
                      ),
                      Text('${region.shops.length}',
                          style: AppTheme.number(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          )),
                      SizedBox(
                        width: 40,
                        height: 28,
                        child: !row.child && region.children.isNotEmpty
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() {
                                  expanded
                                      ? _expanded.remove(region.name)
                                      : _expanded.add(region.name);
                                }),
                                child: Icon(
                                  expanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsets.only(
                bottom: 16 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
