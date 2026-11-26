import 'package:flutter/material.dart';

import '../entity/LuoXue/Collection.dart';
import '../l10n/LocalizationsExtension.dart';
import '../service/Community/CommunityTravelAppearanceStore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';
import 'LxnsAssetImage.dart';

class CommunityTravelAppearancePreview extends StatelessWidget {
  final List<CommunityTravelMember>? members;
  final Collection? partner;

  const CommunityTravelAppearancePreview({
    super.key,
    required this.members,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = members, companion = partner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (team != null) ...[
          AppSectionHeader(title: l10n.flowTravelBuddyCollectible),
          AppCard(
            color: AppSurfaces.inset(context),
            padding: const EdgeInsets.all(10),
            radius: AppDesignTokens.radiusMedium,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var slot = 0; slot < team.length; slot++) ...[
                  if (slot > 0) const SizedBox(width: 4),
                  Expanded(child: _member(context, slot, team[slot])),
                ],
              ],
            ),
          ),
        ],
        if (companion != null) ...[
          if (team != null) const SizedBox(height: 12),
          AppSectionHeader(title: l10n.flowPartnerCollectible),
          AppCard(
            color: AppSurfaces.inset(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            radius: AppDesignTokens.radiusMedium,
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 60,
                  child: LxnsAssetImage(url: partnerImageUrl(companion.id)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(companion.name)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _member(BuildContext context, int slot, CommunityTravelMember member) {
    final l10n = context.l10n;
    final label =
        slot == 0 ? l10n.communityTravelLeader : l10n.communityTravelSlot(slot);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$label · ${member.character.name}',
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: slot == 0
                ? Icon(Icons.workspace_premium_rounded,
                    size: 16, color: scheme.primary)
                : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 62),
            child: AspectRatio(
              aspectRatio: 1,
              child:
                  LxnsAssetImage(url: travelBuddyImageUrl(member.character.id)),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Lv.${member.level}',
                style: AppTheme.number(fontSize: 12)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: TravelAwakeningStars(stars: member.stars, size: 10),
          ),
          if (member.superAwakening > 0) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: TravelSuperAwakeningBadge(
                  count: member.superAwakening, compact: true),
            ),
          ],
        ],
      ),
    );
  }
}

class TravelAwakeningStars extends StatelessWidget {
  final int stars;
  final double size;
  const TravelAwakeningStars({super.key, required this.stars, this.size = 17});

  @override
  Widget build(BuildContext context) {
    final full = stars > 5;
    final filled = full ? 5 : stars;
    final scheme = Theme.of(context).colorScheme;
    final gradient = AppColors.travelAwakeningGradient(
      Theme.of(context).brightness,
      full: full,
    );
    return Semantics(
      label: context.l10n.communityTravelStars(stars),
      child: Tooltip(
        message: context.l10n.communityTravelStars(stars),
        excludeFromSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filled > 0)
              ShaderMask(
                shaderCallback: gradient.createShader,
                blendMode: BlendMode.srcIn,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < filled; i++)
                      Icon(Icons.star_rounded, color: Colors.white, size: size),
                  ],
                ),
              ),
            for (var i = filled; i < 5; i++)
              Icon(Icons.star_outline_rounded,
                  color: scheme.onSurfaceVariant, size: size),
          ],
        ),
      ),
    );
  }
}

class TravelSuperAwakeningBadge extends StatelessWidget {
  final int count;
  final bool compact;
  const TravelSuperAwakeningBadge(
      {super.key, required this.count, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.travelSuperAwakening(Theme.of(context).brightness);
    final label = context.l10n.communityTravelSuperBadge(count);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
        gradient: colors.background,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          compact ? '×$count' : label,
          semanticsLabel: label,
          style: AppTheme.font(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}
