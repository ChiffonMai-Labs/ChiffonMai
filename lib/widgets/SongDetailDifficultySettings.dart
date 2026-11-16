import '../l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ColorUtil.dart';
import '../utils/SongDetailPreferences.dart';
import 'AppUi.dart';
import 'AppDialogs.dart';
import 'AppSwitch.dart';
import 'GuessSettingsUi.dart';

class SongDetailDifficultySettings extends StatefulWidget {
  const SongDetailDifficultySettings({super.key});

  @override
  State<SongDetailDifficultySettings> createState() =>
      _SongDetailDifficultySettingsState();
}

class SongDetailDifficultyMemorySettings extends StatelessWidget {
  const SongDetailDifficultyMemorySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = SongDetailPreferences.instance;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => GuessSettingSection(
        card: true,
        title: l10n.songDifficultyMemory,
        icon: Icons.history_rounded,
        trailing: Semantics(
          label: l10n.songDifficultyMemory,
          child: AppSwitch(
            value: preferences.rememberEnabled,
            onChanged:
                preferences.loaded ? preferences.setRememberEnabled : null,
          ),
        ),
        children: [
          Text(l10n.songDifficultyMemoryHint,
              style: Theme.of(context).textTheme.bodySmall),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: preferences.loaded
                  ? () => showDialog<void>(
                        context: context,
                        builder: (_) => const _DifficultyMemoryDialog(),
                      )
                  : null,
              icon: const Icon(Icons.list_alt_outlined, size: 18),
              label: Text(l10n.songDifficultyMemoryManage),
            ),
          ),
          if (preferences.memorySaveFailed) const _DifficultyMemorySaveError(),
        ],
      ),
    );
  }
}

class _DifficultyMemoryDialog extends StatefulWidget {
  const _DifficultyMemoryDialog();

  @override
  State<_DifficultyMemoryDialog> createState() =>
      _DifficultyMemoryDialogState();
}

class _DifficultyMemoryDialogState extends State<_DifficultyMemoryDialog> {
  final _preferences = SongDetailPreferences.instance;
  final _selected = <String>{};

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppAlertDialog(
        title: Text(context.l10n.flowClearAll),
        content: Text(context.l10n.songDifficultyMemoryClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.featureCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.flowClearAll),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _clear(_preferences.remembered.keys.toSet());
    }
  }

  Future<void> _clear(Set<String> songIds) async {
    setState(_selected.clear);
    await _preferences.clearRememberedDifficulties(songIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _preferences,
      builder: (context, _) {
        final songs = _preferences.remembered;
        final ids = songs.keys.toList().reversed.toList();
        return AppAlertDialog(
          icon: const Icon(Icons.history_rounded),
          title: Text(l10n.songDifficultyMemoryManage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: songs.isEmpty
                    ? SingleChildScrollView(
                        child: AppDialogEmpty(
                          icon: Icons.history_rounded,
                          message: l10n.songDifficultyMemoryEmpty,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: ids.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final id = ids[index];
                          final song = songs[id]!;
                          final isUtage =
                              ChartDifficulty.isUtageSong(id, type: song.type);
                          return CheckboxListTile(
                            key: ValueKey(id),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(song.title),
                            subtitle: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                SongTypeBadge(songId: id, type: song.type),
                                ChartDifficultyBadge(
                                  songId: id,
                                  levelIndex: song.index,
                                  label: isUtage
                                      ? '${ChartDifficulty.utageLabel} ${song.index + 1}'
                                      : null,
                                ),
                              ],
                            ),
                            value: _selected.contains(id),
                            onChanged: (selected) => setState(() {
                              if (selected == true) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            }),
                          );
                        },
                      ),
              ),
              if (_preferences.memorySaveFailed)
                const _DifficultyMemorySaveError(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.featureClose),
            ),
            if (songs.isNotEmpty) ...[
              TextButton(
                onPressed: _clearAll,
                child: Text(l10n.flowClearAll),
              ),
              FilledButton(
                onPressed: _selected.any(songs.containsKey)
                    ? () => _clear(Set.of(_selected))
                    : null,
                child: Text(l10n.songDifficultyMemoryClearSelected),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DifficultyMemorySaveError extends StatelessWidget {
  const _DifficultyMemorySaveError();

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: SongDetailPreferences.instance.retryMemorySave,
          icon: const Icon(Icons.error_outline, size: 16),
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          label: Text(context.l10n.settingSaveFailed),
        ),
      );
}

class _SongDetailDifficultySettingsState
    extends State<SongDetailDifficultySettings> {
  final _preferences = SongDetailPreferences.instance;

  @override
  void initState() {
    super.initState();
    _preferences.load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _preferences,
      builder: (context, _) => GuessSettingSection(
        card: true,
        title: context.l10n.defaultDifficulty,
        icon: Icons.layers_outlined,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.defaultDifficultyHint,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 14),
                for (final pair in const [
                  [ChartDifficulty.basic, ChartDifficulty.advanced],
                  [ChartDifficulty.expert, ChartDifficulty.master],
                ]) ...[
                  Row(children: [
                    Expanded(child: _choice(context, pair[0])),
                    const SizedBox(width: 10),
                    Expanded(child: _choice(context, pair[1])),
                  ]),
                  if (pair[0] == ChartDifficulty.basic)
                    const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 7),
                  Expanded(
                      child: Text(context.l10n.defaultDifficultyNote,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: scheme.onSurfaceVariant))),
                ]),
                if (_preferences.error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(context.l10n.settingSaveFailed,
                          style: TextStyle(fontSize: 12, color: scheme.error))),
              ])
        ],
      ),
    );
  }

  Widget _choice(BuildContext context, int difficulty) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final selected = _preferences.difficulty == difficulty;
    final palette = AppColors.difficultyBadge(difficulty, brightness);
    final color = palette.foreground;
    final accent = ColorUtil.getCardColor(difficulty);
    final label = ChartDifficulty.labelOf(difficulty);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: AnimatedContainer(
          duration: AppDesignTokens.motion(context, AppDesignTokens.fastMotion),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: .14), AppSurfaces.card(context))
                : AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            border: Border.all(
                color: selected ? accent : scheme.outlineVariant,
                width: selected ? 1.5 : 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              onTap: !_preferences.loaded ||
                      (selected && _preferences.error == null)
                  ? null
                  : () => _preferences.setDifficulty(difficulty),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
                child: Row(children: [
                  Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: selected ? color : scheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      selected ? color : scheme.onSurface)))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
