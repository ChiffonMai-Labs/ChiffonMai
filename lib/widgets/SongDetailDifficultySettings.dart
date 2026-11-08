import '../l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ColorUtil.dart';
import '../utils/SongDetailPreferences.dart';
import 'AppUi.dart';
import 'GuessSettingsUi.dart';

class SongDetailDifficultySettings extends StatefulWidget {
  const SongDetailDifficultySettings({super.key});

  @override
  State<SongDetailDifficultySettings> createState() =>
      _SongDetailDifficultySettingsState();
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
