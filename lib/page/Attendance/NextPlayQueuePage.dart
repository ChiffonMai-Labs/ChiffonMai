import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../../service/Attendance/NextPlayQueueStore.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/EmptyState.dart';
import '../../widgets/MarqueeText.dart';
import '../song_info/SongInfoPage.dart';

class NextPlayQueuePage extends StatefulWidget {
  const NextPlayQueuePage({super.key});
  @override
  State<NextPlayQueuePage> createState() => _NextPlayQueuePageState();
}

class _NextPlayQueuePageState extends State<NextPlayQueuePage> {
  final _store = NextPlayQueueStore.instance;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
    _store.addListener(_changed);
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    super.dispose();
  }

  void _changed() => mounted ? setState(() {}) : null;

  Widget _buildReorderProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final scale = 1.0 + 0.02 * t;
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.16 * t),
                  blurRadius: 18 * t,
                  offset: Offset(0, 6 * t),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _store.entries;
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: context.l10n.featurePlayNext,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 14,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.l10n.flowP0Songs2(entries.length.toString()),
                    style: AppTheme.number(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: entries.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_rounded,
              message: context.l10n.flowNoSongsAddedYetUseAddTo,
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter,
                8,
                AppDesignTokens.gutter,
                28,
              ),
              itemCount: entries.length,
              buildDefaultDragHandles: false,
              proxyDecorator: _buildReorderProxyDecorator,
              onReorder: _store.reorder,
              itemBuilder: (context, index) => _buildSongCard(
                context,
                entries[index],
                index,
              ),
            ),
    );
  }

  Widget _buildSongCard(
    BuildContext context,
    NextPlayEntry entry,
    int index,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isUtage = entry.songId.length == 6;
    final accentColor = entry.difficultyIndices.isNotEmpty
        ? AppColors.difficultyForegroundByIndex(
            entry.difficultyIndices.first,
            brightness: brightness,
          )
        : scheme.outlineVariant;
    final coverBorderColor = entry.difficultyIndices.isNotEmpty
        ? accentColor.withValues(alpha: 0.72)
        : scheme.outlineVariant.withValues(alpha: 0.55);

    return Padding(
      key: ValueKey(entry.occurrenceId),
      padding: const EdgeInsets.only(bottom: 10),
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: Material(
          color: AppSurfaces.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SongInfoPage(songId: entry.songId),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: coverBorderColor,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.5),
                          child: CoverUtil.buildCoverWidget(entry.songId, 60),
                        ),
                      ),
                      Positioned(
                        left: 3,
                        top: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: AppTheme.number(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if ((entry.type != null &&
                                    entry.type!.isNotEmpty) ||
                                isUtage) ...[
                              SongTypeBadge(
                                songId: entry.songId,
                                type: entry.type ?? '',
                                fontSize: 9.5,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: MarqueeText(
                                text: entry.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.artist.isEmpty
                              ? context.l10n.flowUnknownArtist
                              : entry.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (entry.difficultyIndices.isNotEmpty)
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: entry.difficultyIndices
                                .map(
                                  (levelIndex) => ChartDifficultyBadge(
                                    levelIndex: levelIndex,
                                    songId: entry.songId,
                                    fontSize: 10,
                                  ),
                                )
                                .toList(),
                          )
                        else
                          AppBadge(
                            text: context.l10n.flowDifficultyNotSpecified,
                            background: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                            foreground: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        if (entry.note.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 13,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    entry.note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: context.l10n.flowRemoveThisEntry,
                        visualDensity: VisualDensity.compact,
                        iconSize: 19,
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => _store.remove(entry.occurrenceId),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 20,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
