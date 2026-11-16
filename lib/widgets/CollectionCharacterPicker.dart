import 'package:flutter/material.dart';

import '../entity/LuoXue/Collection.dart';
import '../l10n/LocalizationsExtension.dart';
import '../utils/AppDesignTokens.dart';
import 'AppDialogs.dart';
import 'AppUi.dart';
import 'BackgroundPageScaffold.dart';
import 'LxnsAssetImage.dart';
import 'MarqueeText.dart';

/// 角色图鉴较长，网格只构建可见的条目；搭档可先看大图再应用。
class CollectionCharacterPicker extends StatefulWidget {
  final List<Collection> items;
  final bool partner;
  final int? selectedId;
  final Set<int> blockedIds;

  const CollectionCharacterPicker({
    super.key,
    required this.items,
    required this.partner,
    required this.selectedId,
    required this.blockedIds,
  });

  @override
  State<CollectionCharacterPicker> createState() =>
      _CollectionCharacterPickerState();
}

class _CollectionCharacterPickerState extends State<CollectionCharacterPicker> {
  late final _available = [
    for (final item in widget.items)
      if (!widget.blockedIds.contains(item.id)) item,
  ];
  late List<Collection> _results = _available;

  String _imageUrl(int id) =>
      widget.partner ? partnerImageUrl(id) : travelBuddyImageUrl(id);

  void _search(String text) {
    final query = text.trim().toLowerCase();
    setState(() => _results = query.isEmpty
        ? _available
        : _available.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.id.toString().contains(query);
          }).toList());
  }

  Future<void> _select(Collection item) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.partner) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AppAlertDialog(
          title: Text(item.name),
          content: SizedBox(
            height: 190,
            child: LxnsAssetImage(url: _imageUrl(item.id)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final nameStyle = Theme.of(context).textTheme.labelLarge!;
    final height = 108 + MediaQuery.textScalerOf(context).scale(22);
    return BackgroundPageScaffold(
      title: widget.partner
          ? l10n.flowPartnerCollectible
          : l10n.flowTravelBuddyCollectible,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter,
              6,
              AppDesignTokens.gutter,
              12,
            ),
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                hintText: l10n.communityTravelSearch,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(child: Text(l10n.flowNoMatchingResults))
                : GridView.builder(
                    key: ValueKey(_results),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppDesignTokens.gutter,
                      0,
                      AppDesignTokens.gutter,
                      24,
                    ),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 146,
                      mainAxisExtent: height,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final selected = item.id == widget.selectedId;
                      return Semantics(
                        selected: selected,
                        child: AppCard(
                          padding: const EdgeInsets.all(8),
                          radius: AppDesignTokens.radiusMedium,
                          color: selected ? scheme.secondaryContainer : null,
                          onTap: () => _select(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    LxnsAssetImage(url: _imageUrl(item.id)),
                                    if (selected)
                                      Align(
                                        alignment: AlignmentDirectional.topEnd,
                                        child: Icon(Icons.check_circle_rounded,
                                            color: scheme.primary),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              MarqueeText(text: item.name, style: nameStyle),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
