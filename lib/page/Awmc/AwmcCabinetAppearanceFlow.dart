import 'package:flutter/material.dart';

import '../../entity/AWMC/AwmcCabinetAppearance.dart';
import '../../entity/LuoXue/Collection.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../manager/LuoXue/CollectionsManager.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcStore.dart';
import '../../service/CommunityAvatarStore.dart';
import '../../service/CommunityTravelAppearanceStore.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/LxnsAssetImage.dart';
import '../../widgets/SyncDialogUi.dart';
import '../../widgets/TrophyTitleBadge.dart';
import '../CommunityTravelAppearancePage.dart';

abstract final class AwmcCabinetAppearanceFlow {
  static Future<void> run(
    BuildContext context, {
    required ValueChanged<String> onProgress,
  }) async {
    final l10n = context.l10n;
    final store = CommunityAvatarStore.instance;
    final player = await store.cabinetImportPlayer();
    if (!context.mounted) return;
    if (player == null) {
      AppToast.show(l10n.cabinetAppearanceSignIn, tone: AppToastTone.warning);
      return;
    }
    await store.sync(player);
    if (!context.mounted || store.value.playerId != player) return;
    if (store.value.level != AvatarSyncLevel.synced) {
      AppToast.show(l10n.cabinetAppearanceCouldNotCheckCloud,
          tone: AppToastTone.warning);
      return;
    }

    final qr = await showDialog<String>(
      context: context,
      builder: (_) => const _CabinetAppearanceQrDialog(),
    );
    if (qr == null || !context.mounted || store.value.playerId != player)
      return;
    onProgress(l10n.cabinetAppearanceReading);
    final response = await AwmcApiService.userData(token: '', qrcode: qr);
    await AwmcAuditLog.record(response, note: l10n.cabinetAppearanceSync);
    if (!context.mounted || store.value.playerId != player) return;
    if (!response.ok) {
      AppToast.show(response.displayMessage, tone: AppToastTone.error);
      return;
    }
    final cabinet =
        AwmcCabinetAppearance.fromBusinessData(response.businessData);
    if (cabinet == null || !cabinet.hasImportableChoices) {
      AppToast.show(l10n.cabinetAppearanceEmpty, tone: AppToastTone.warning);
      return;
    }
    final collections = CollectionsManager();
    final requested = <String, Iterable<int?>>{
      'icons': [cabinet.avatarId],
      'plates': [cabinet.plateId],
      'frames': [cabinet.frameId],
      'trophies': [cabinet.trophyId],
      'partners': [cabinet.partnerId],
      'travelBuddies': cabinet.travelSlots ?? const [],
    };
    final catalogs = Map.fromEntries(await Future.wait([
      for (final entry in requested.entries)
        if (entry.value.any((id) => id != null && id > 0))
          collections.fetchCatalog(entry.key).then((catalog) {
            return MapEntry(entry.key, {
              for (final item
                  in catalog?.entriesFor(entry.key) ?? <Collection>[])
                if (entry.value.contains(item.id)) item.id: item,
            });
          }),
    ]));
    if (!context.mounted || store.value.playerId != player) return;

    Collection? resolve(String catalog, int? id) => id == null || id <= 0
        ? null
        : catalogs[catalog]?[id] ?? Collection(id: id, name: '');
    final avatar = resolve('icons', cabinet.avatarId);
    final plate = resolve('plates', cabinet.plateId);
    final frame = resolve('frames', cabinet.frameId);
    final trophy = resolve('trophies', cabinet.trophyId);
    final partner = resolve('partners', cabinet.partnerId);
    final slots = cabinet.travelSlots
        ?.map((id) => resolve('travelBuddies', id))
        .toList(growable: false);
    final saved =
        CommunityTravelAppearanceStore.parseTeam(store.value.travelTeam);
    final progress = {
      for (final member in saved ?? <CommunityTravelMember>[])
        member.character.id: member,
    };
    final team = cabinet.hasCompleteTeam
        ? [
            for (final slot in slots!.cast<Collection>())
              CommunityTravelMember(slot,
                  level: progress[slot.id]?.level ?? 1,
                  superAwakening: progress[slot.id]?.superAwakening ?? 0),
          ]
        : null;
    final confirmed = await showDialog<({List<CommunityTravelMember>? team})>(
      context: context,
      builder: (_) => _CabinetAppearanceReview(
        cabinet: cabinet,
        avatar: avatar,
        plate: plate,
        frame: frame,
        trophy: trophy,
        partner: partner,
        slots: slots,
        team: team,
      ),
    );
    if (!context.mounted || confirmed == null) return;
    onProgress(l10n.cabinetAppearanceSaving);
    final synced = await store.importCabinetAppearance(
      player,
      avatarId: avatar?.id,
      collectibles: {
        if (cabinet.plateId != null) 'nameplate': plate,
        if (cabinet.frameId != null) 'frame': frame,
        if (cabinet.trophyId != null) 'trophy': trophy,
      },
      members: confirmed.team,
      partner: partner,
    );
    if (!context.mounted) return;
    AppToast.show(
      switch (synced) {
        true => l10n.svcCommunityAppearanceSynced,
        false => l10n.svcAppearanceWaitingToSyncTapToRetry,
        null => l10n.cabinetAppearanceAccountChanged,
      },
      tone: synced == true ? AppToastTone.success : AppToastTone.warning,
    );
  }
}

class _CabinetAppearanceQrDialog extends StatefulWidget {
  const _CabinetAppearanceQrDialog();

  @override
  State<_CabinetAppearanceQrDialog> createState() =>
      _CabinetAppearanceQrDialogState();
}

class _CabinetAppearanceQrDialogState
    extends State<_CabinetAppearanceQrDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppAlertDialog(
      title: Text(l10n.cabinetAppearanceSync),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cabinetAppearanceQrHint),
          const SizedBox(height: 12),
          SyncQrInput(
            controller: _controller,
            hintText: l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final qr = _controller.text.trim();
            if (!AwmcCredentials.isValidQrcode(qr)) {
              AppToast.show(l10n.flowEnterAValidSGWCMAIDCabinetLoginQR,
                  tone: AppToastTone.warning);
              return;
            }
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context, qr);
          },
          child: Text(l10n.cabinetAppearanceRead),
        ),
      ],
    );
  }
}

class _CabinetAppearanceReview extends StatefulWidget {
  final AwmcCabinetAppearance cabinet;
  final Collection? avatar, plate, frame, trophy, partner;
  final List<Collection?>? slots;
  final List<CommunityTravelMember>? team;

  const _CabinetAppearanceReview({
    required this.cabinet,
    required this.avatar,
    required this.plate,
    required this.frame,
    required this.trophy,
    required this.partner,
    required this.slots,
    required this.team,
  });

  @override
  State<_CabinetAppearanceReview> createState() =>
      _CabinetAppearanceReviewState();
}

class _CabinetAppearanceReviewState extends State<_CabinetAppearanceReview> {
  late final _team = widget.team?.toList();

  Future<void> _editProgress(int slot) async {
    final edited = await showDialog<CommunityTravelMember>(
      context: context,
      builder: (_) => TravelProgressDialog(member: _team![slot]),
    );
    if (mounted && edited != null) setState(() => _team![slot] = edited);
  }

  Widget _item(
    String label,
    Collection? item, {
    String Function(int)? image,
    IconData? placeholderIcon,
    String? empty,
    int? slot,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final member = slot == null ? null : _team?[slot];
    final fallback = empty ?? l10n.flowNotSet;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 36,
                width: 48,
                child: item != null
                    ? LxnsAssetImage(url: image(item.id))
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppSurfaces.inset(context),
                        ),
                        child: Icon(
                          placeholderIcon ?? Icons.image_outlined,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                Text(
                  item == null
                      ? fallback
                      : [
                          if (item.name.isNotEmpty) item.name,
                          '#${item.id}',
                        ].join(' · '),
                  style: theme.textTheme.bodyMedium,
                ),
                if (member != null)
                  Text(
                    'Lv.${member.level} · ${l10n.communityTravelSuperCount} ${member.superAwakening}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (member != null && slot != null)
            IconButton(
              tooltip: l10n.communityTravelEditLevel,
              onPressed: () => _editProgress(slot),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
    );
  }

  /// 称号需展示宽幅底图与文字，使用独立凹槽容器以免打断上方左图右文列表的对齐轴线。
  Widget _trophyItem(
    String label,
    Collection? trophy, {
    String? empty,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fallback = empty ?? l10n.flowNotSet;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.labelMedium),
              ),
              if (trophy != null)
                Text(
                  '#${trophy.id}',
                  style: AppTheme.number(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (trophy != null) ...[
            const SizedBox(height: 6),
            TrophyTitleBadge(
              name: trophy.name.isNotEmpty
                  ? trophy.name
                  : l10n.homeTrophyId(trophy.id.toString()),
              color: trophy.color,
              trophyId: trophy.id,
            ),
          ] else ...[
            const SizedBox(height: 2),
            Text(
              fallback,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cabinet = widget.cabinet;
    final slots = widget.slots ?? const [];
    final unchanged = l10n.cabinetAppearanceKeepCurrent;
    return AppAlertDialog(
      icon: const Icon(Icons.fact_check_outlined),
      title: Text(l10n.cabinetAppearanceReview),
      subtitle: cabinet.userName.isEmpty ? null : cabinet.userName,
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SyncNoticeCard(
            icon: Icons.info_outline_rounded,
            color: AppColors.warningOrange(theme.brightness),
            title: l10n.cabinetAppearanceCommunityOnly,
            child: Text(l10n.cabinetAppearanceNotice),
          ),
          const SizedBox(height: 14),
          _item(l10n.flowIconCollectible, widget.avatar,
              image: lxnsIconUrl,
              placeholderIcon: Icons.account_circle_outlined,
              empty: unchanged),
          _item(l10n.flowPlateCollectible, widget.plate,
              image: lxnsPlateUrl,
              placeholderIcon: Icons.badge_outlined,
              empty: cabinet.plateId == null ? unchanged : null),
          _item(l10n.flowFrameCollectible, widget.frame,
              image: lxnsFrameUrl,
              placeholderIcon: Icons.photo_outlined,
              empty: cabinet.frameId == null ? unchanged : null),
          _item(l10n.flowPartnerCollectible, widget.partner,
              image: partnerImageUrl,
              placeholderIcon: Icons.face_outlined,
              empty: unchanged),
          _trophyItem(l10n.flowTitleCollectible, widget.trophy,
              empty: cabinet.trophyId == null ? unchanged : null),
          const Divider(height: 24),
          Text(l10n.flowTravelBuddyCollectible,
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 5),
          Text(
              _team == null
                  ? l10n.cabinetAppearanceKeepTeam
                  : l10n.cabinetAppearanceProgressDefaults,
              style: theme.textTheme.bodySmall),
          for (var slot = 0;
              slot < slots.length && slot < CommunityTravelMember.slotCount;
              slot++)
            _item(
              slot == 0
                  ? l10n.communityTravelLeader
                  : l10n.communityTravelSlot(slot),
              slots[slot],
              image: travelBuddyImageUrl,
              placeholderIcon: Icons.person_outline_rounded,
              slot: slot,
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (team: _team,)),
          child: Text(l10n.cabinetAppearanceConfirm),
        ),
      ],
    );
  }
}
