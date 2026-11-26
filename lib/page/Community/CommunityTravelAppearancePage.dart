import 'dart:async';

import 'package:flutter/material.dart';

import '../../entity/LuoXue/Collection.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../manager/LuoXue/CollectionsManager.dart';
import '../../service/Account/AccountStore.dart';
import '../../service/Community/CommunityAvatarStore.dart';
import '../../service/Community/CommunityTravelAppearanceStore.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/CollectionCharacterPicker.dart';
import '../../widgets/CommunityTravelAppearancePreview.dart';
import '../../widgets/LxnsAssetImage.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';

class CommunityTravelAppearancePage extends StatefulWidget {
  const CommunityTravelAppearancePage({super.key});

  @override
  State<CommunityTravelAppearancePage> createState() =>
      _CommunityTravelAppearancePageState();
}

class _CommunityTravelAppearancePageState
    extends State<CommunityTravelAppearancePage> {
  CommunityTravelAppearanceStore? _store;
  List<CommunityTravelMember>? _members;
  Collection? _partner;
  List<Collection> _buddies = const [], _partners = const [];
  int _activeSlot = 0;
  bool _loading = true, _saving = false, _accountChanged = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool retry = false}) async {
    if (retry && _loading) return;
    if (retry) setState(() => _loading = true);
    try {
      final store = _store ??
          CommunityTravelAppearanceStore(await AccountStore.accountKey());
      final saved = await CommunityAvatarStore.instance
          .loadTravelAppearance(store.accountKey);
      if (!mounted) return;
      setState(() {
        _store = store;
        _members = saved.members ?? _members;
        _partner = saved.partner ?? _partner;
      });

      final manager = CollectionsManager();
      final catalogs = await Future.wait([
        manager.fetchCatalog('travelBuddies', forceNetwork: retry),
        manager.fetchCatalog('partners', forceNetwork: retry),
      ]);
      final sameAccount = store.accountKey == await AccountStore.accountKey();
      if (!mounted) return;
      if (!sameAccount) {
        setState(() => _accountChanged = true);
        return;
      }
      final buddies = [...?catalogs[0]?.travelBuddies]
        ..sort((a, b) => a.id.compareTo(b.id));
      final partners = [...?catalogs[1]?.partners]
        ..sort((a, b) => a.id.compareTo(b.id));
      setState(() {
        _buddies = buddies;
        _partners = partners;
        if (_members == null &&
            buddies.length >= CommunityTravelMember.slotCount) {
          _members = buddies
              .take(CommunityTravelMember.slotCount)
              .map((item) => CommunityTravelMember(item))
              .toList();
        }
        if (_partner == null && partners.isNotEmpty) _partner = partners.first;
      });
    } catch (error) {
      debugPrint('读取社区角色装扮失败: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(
    Future<void> Function(CommunityTravelAppearanceStore store) write,
    VoidCallback apply,
  ) async {
    final store = _store;
    if (!mounted || _saving || _accountChanged || store == null) return;
    setState(() => _saving = true);
    try {
      final account = await AccountStore.accountKey();
      if (!mounted) return;
      if (account != store.accountKey) {
        setState(() => _accountChanged = true);
        return;
      }
      await write(store);
      if (mounted) setState(apply);
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context.l10n.flowCouldNotSaveYourAppearanceChooseAgain,
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveTeam(List<CommunityTravelMember> team, int activeSlot) =>
      _save((store) async {
        await store.saveTeam(team);
        unawaited(CommunityAvatarStore.instance
            .publishTravelAppearance(store.accountKey, members: team)
            .catchError(_logSyncFailure));
      }, () {
        _members = team;
        _activeSlot = activeSlot;
      });

  Future<void> _setPartner(Collection item) => _save((store) async {
        await store.savePartner(item);
        unawaited(CommunityAvatarStore.instance
            .publishTravelAppearance(store.accountKey, partner: item)
            .catchError(_logSyncFailure));
      }, () => _partner = item);

  void _logSyncFailure(Object error) =>
      debugPrint('暂时无法同步角色装扮: ${error.runtimeType}');

  void _swap(int from, int to) {
    if (from == to) return;
    final team = [..._members!];
    final member = team[from];
    team[from] = team[to];
    team[to] = member;
    unawaited(_saveTeam(team, to));
  }

  String _slotLabel(int slot) => slot == 0
      ? context.l10n.communityTravelLeader
      : context.l10n.communityTravelSlot(slot);

  Future<void> _chooseSwap(int from) async {
    final members = _members!;
    final target = await showDialog<int>(
      context: context,
      builder: (context) => AppAlertDialog(
        title: Text(context.l10n.communityTravelSwap),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var slot = 0; slot < members.length; slot++)
              if (slot != from)
                ListTile(
                  leading: SizedBox.square(
                    dimension: 32,
                    child: LxnsAssetImage(
                      url: travelBuddyImageUrl(members[slot].character.id),
                    ),
                  ),
                  title: Text(_slotLabel(slot)),
                  subtitle: Text(members[slot].character.name),
                  onTap: () => Navigator.pop(context, slot),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
    if (mounted && target != null) _swap(from, target);
  }

  Future<void> _pick({int? slot}) async {
    final isPartner = slot == null;
    final current = isPartner ? _partner : _members![slot].character;
    FocusManager.instance.primaryFocus?.unfocus();
    final item = await Navigator.push<Collection>(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionCharacterPicker(
          items: isPartner ? _partners : _buddies,
          partner: isPartner,
          selectedId: current?.id,
          blockedIds: isPartner
              ? const {}
              : {
                  for (final member in _members!)
                    if (member.character.id != current?.id) member.character.id,
                },
        ),
      ),
    );
    if (!mounted || item == null || item.id == current?.id) return;
    if (isPartner) {
      await _setPartner(item);
    } else {
      final team = [..._members!];
      team[slot] = CommunityTravelMember(item);
      await _saveTeam(team, slot);
    }
  }

  Future<void> _editProgress(int slot) async {
    final member = _members![slot];
    final edited = await showDialog<CommunityTravelMember>(
      context: context,
      builder: (_) => TravelProgressDialog(member: member),
    );
    if (!mounted || edited == null) return;
    final team = [..._members!];
    team[slot] = edited;
    await _saveTeam(team, slot);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canEdit = !_saving && !_accountChanged;
    final canRetry =
        !_loading && !_saving && (_buddies.isEmpty || _partners.isEmpty);
    return BackgroundPageScaffold(
      title: l10n.communityTravelAppearance,
      actions: [
        if (canRetry && !_accountChanged)
          IconButton(
            tooltip: l10n.flowRetry,
            onPressed: () => _load(retry: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
      child: _accountChanged
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.gutter),
                child: Text(l10n.flowAccountChangedChooseYourAppearanceAgain),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 2,
                  child: _loading || _saving
                      ? const SmoothLinearProgressIndicator(minHeight: 2)
                      : null,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDesignTokens.gutter,
                      8,
                      AppDesignTokens.gutter,
                      24,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                        child: Text(
                          l10n.communityTravelLocalNote,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                      AppSectionHeader(title: l10n.flowTravelBuddyCollectible),
                      EntranceAnimation(
                        index: 0,
                        child: _members == null
                            ? _unavailable()
                            : _teamCard(canEdit),
                      ),
                      const SizedBox(height: 18),
                      AppSectionHeader(title: l10n.flowPartnerCollectible),
                      EntranceAnimation(
                        index: 1,
                        child: _partner == null
                            ? _unavailable()
                            : _partnerCard(canEdit),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _unavailable() => AppCard(
        child: _loading
            ? Text(context.l10n.flowLoading2)
            : Row(
                children: [
                  Expanded(child: Text(context.l10n.flowCouldNotLoad)),
                  TextButton(
                    onPressed: () => _load(retry: true),
                    child: Text(context.l10n.flowRetry),
                  ),
                ],
              ),
      );

  Widget _teamCard(bool canEdit) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final members = _members!;
    final member = members[_activeSlot];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var slot = 0; slot < members.length; slot++) ...[
                if (slot > 0) const SizedBox(width: 4),
                Expanded(child: _slotTile(slot, members[slot], canEdit)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(_slotLabel(_activeSlot),
              style: TextStyle(color: scheme.primary)),
          MarqueeText(
            text: member.character.name,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Lv.${member.level}',
                  style: AppTheme.number(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  )),
              TravelAwakeningStars(stars: member.stars),
              if (member.superAwakening > 0)
                TravelSuperAwakeningBadge(count: member.superAwakening),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              FilledButton.tonal(
                onPressed: canEdit ? () => _editProgress(_activeSlot) : null,
                child: Text(l10n.communityTravelEditLevel),
              ),
              TextButton(
                onPressed: canEdit && _buddies.isNotEmpty
                    ? () => _pick(slot: _activeSlot)
                    : null,
                child: Text(l10n.flowChange),
              ),
              TextButton(
                onPressed: canEdit ? () => _chooseSwap(_activeSlot) : null,
                child: Text(l10n.communityTravelSwap),
              ),
              if (_activeSlot != 0)
                TextButton(
                  onPressed: canEdit ? () => _swap(_activeSlot, 0) : null,
                  child: Text(l10n.communityTravelSetLeader),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotTile(int slot, CommunityTravelMember member, bool canEdit) {
    final selected = slot == _activeSlot;
    final scheme = Theme.of(context).colorScheme;
    final label = _slotLabel(slot);
    return Semantics(
      selected: selected,
      child: Tooltip(
        message: '$label · ${member.character.name}',
        child: AppCard(
          radius: AppDesignTokens.radiusSmall,
          padding: const EdgeInsets.all(4),
          outlined: !selected,
          color:
              selected ? scheme.secondaryContainer : AppSurfaces.inset(context),
          onTap: canEdit ? () => setState(() => _activeSlot = slot) : null,
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(18),
                child: Center(
                  child: slot == 0
                      ? Icon(Icons.workspace_premium_rounded,
                          size: 16, color: scheme.primary)
                      : Text('$slot', style: AppTheme.number(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 4),
              AspectRatio(
                aspectRatio: 1,
                child: LxnsAssetImage(
                    url: travelBuddyImageUrl(member.character.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _partnerCard(bool canEdit) {
    final l10n = context.l10n;
    final partner = _partner!;
    final defaultPartner = _partners.firstOrNull;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            ),
            child: SizedBox(
              height: 140,
              child: LxnsAssetImage(url: partnerImageUrl(partner.id)),
            ),
          ),
          const SizedBox(height: 8),
          Text(partner.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              FilledButton.tonal(
                onPressed:
                    canEdit && _partners.isNotEmpty ? () => _pick() : null,
                child: Text(l10n.flowChange),
              ),
              TextButton(
                onPressed: canEdit &&
                        defaultPartner != null &&
                        defaultPartner.id != partner.id
                    ? () => _setPartner(defaultPartner)
                    : null,
                child: Text(l10n.restoreDefaults),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TravelProgressDialog extends StatefulWidget {
  final CommunityTravelMember member;
  const TravelProgressDialog({super.key, required this.member});

  @override
  State<TravelProgressDialog> createState() => _TravelProgressDialogState();
}

class _TravelProgressDialogState extends State<TravelProgressDialog> {
  final _form = GlobalKey<FormState>();
  late int? _level = widget.member.level;
  late int? _superCount = widget.member.superAwakening;

  CommunityTravelMember? get _value {
    final level = _level, superCount = _superCount;
    if (level == null || superCount == null) return null;
    final member = CommunityTravelMember(
      widget.member.character,
      level: level,
      superAwakening: superCount,
    );
    return member.hasValidProgress ? member : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _value;
    return AppAlertDialog(
      title: Text(l10n.communityTravelEditLevel),
      subtitle: widget.member.character.name.isEmpty
          ? '#${widget.member.character.id}'
          : widget.member.character.name,
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(
              label: l10n.flowLevel,
              initialValue: widget.member.level,
              min: 1,
              max: CommunityTravelMember.maxLevel,
              onChange: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 10),
            _field(
              label: l10n.communityTravelSuperCount,
              initialValue: widget.member.superAwakening,
              min: 0,
              max: CommunityTravelMember.maxSuperAwakening,
              onChange: (value) => setState(() => _superCount = value),
            ),
            if (preview != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TravelAwakeningStars(stars: preview.stars),
                  if (preview.superAwakening > 0)
                    TravelSuperAwakeningBadge(count: preview.superAwakening),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            if (_form.currentState?.validate() != true) return;
            final value = _value;
            if (value == null) return;
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context, value);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required int initialValue,
    required int min,
    required int max,
    required ValueChanged<int?> onChange,
  }) {
    return TextFormField(
      initialValue: initialValue.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label).insetLabel(context),
      onChanged: (raw) => onChange(int.tryParse(raw.trim(), radix: 10)),
      validator: (raw) {
        final value = int.tryParse(raw?.trim() ?? '', radix: 10);
        return value != null && value >= min && value <= max
            ? null
            : context.l10n.communityTravelIntegerRange(min, max);
      },
    );
  }
}
