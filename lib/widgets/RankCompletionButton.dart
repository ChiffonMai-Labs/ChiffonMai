import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import '../service/RankTable/RankCompletionStore.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppDialogs.dart';
import '../utils/AppDesignTokens.dart';
import 'AppUi.dart';

/// 段位完成情况的文字标签，同时作为编辑入口。
class RankCompletionButton extends StatelessWidget {
  final String rank;
  final bool showAchievement;
  const RankCompletionButton({
    super.key,
    required this.rank,
    this.showAchievement = true,
  });

  static String label(RankCompletion status) => switch (status) {
        RankCompletion.unplayed => appL10n.flowNotAttempted,
        RankCompletion.failed => appL10n.flowFailed2,
        RankCompletion.passed => appL10n.flowPassed,
        RankCompletion.redPassed => appL10n.flowRedPass,
      };

  static Color color(BuildContext context, RankCompletion status) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return switch (status) {
      RankCompletion.unplayed => scheme.surfaceContainerHighest,
      RankCompletion.failed => scheme.errorContainer,
      RankCompletion.passed => AppColors.successSurface(brightness),
      RankCompletion.redPassed =>
        Color.lerp(scheme.surface, AppColors.warningOrange(brightness), .22)!,
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: RankCompletionStore.instance,
        builder: (_, __) {
          final store = RankCompletionStore.instance;
          final status = store.status(rank);
          final achievement = store.achievement(rank);
          final suffix = !showAchievement ||
                  status == RankCompletion.unplayed ||
                  achievement == null
              ? ''
              : ' · ${achievement.toStringAsFixed(4)}%';
          return InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _RankCompletionDialog(rank: rank),
            ),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color(context, status),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
              ),
              child: Text('${label(status)}$suffix',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          );
        },
      );
}

class _RankCompletionDialog extends StatefulWidget {
  final String rank;
  const _RankCompletionDialog({required this.rank});

  @override
  State<_RankCompletionDialog> createState() => _RankCompletionDialogState();
}

class _RankCompletionDialogState extends State<_RankCompletionDialog> {
  late final TextEditingController _controller;
  late RankCompletion _status;
  String? _achievementError;

  @override
  void initState() {
    super.initState();
    final store = RankCompletionStore.instance;
    _status = store.status(widget.rank);
    _controller = TextEditingController(
        text: store.achievement(widget.rank)?.toStringAsFixed(4) ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    final value = raw.isEmpty ? null : double.tryParse(raw);
    if (_status != RankCompletion.unplayed) {
      setState(() => _achievementError = _validateAchievement(raw));
      if (_achievementError != null) return;
    }
    // 先结束路由退出动画，持久化通知在弹窗销毁后进行。
    Navigator.pop(context);
    await RankCompletionStore.instance.setCompletion(widget.rank, _status,
        _status == RankCompletion.unplayed ? null : value);
  }

  String? _validateAchievement(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite)
      return context.l10n.flowEnterAValidTotalAchievement;
    if (value < 0 || value > 404)
      return context.l10n.flowTotalAchievementMustBeBetween0And;
    final fraction = text.contains('.') ? text.split('.').last : '';
    if (fraction.length > 4)
      return context.l10n.flowTotalAchievementSupportsUpToFourDecimal;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canInput = _status != RankCompletion.unplayed;
    return AppAlertDialog(
      title: Text(context.l10n.flowDanCompletion),
      content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final option in RankCompletion.values)
          InkWell(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            onTap: () {
              if (_status == option) return;
              setState(() => _status = option);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: option == _status
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Row(children: [
                Expanded(child: Text(RankCompletionButton.label(option))),
                if (option == _status) const Icon(Icons.check, size: 18),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          enabled: canInput,
          onChanged: (value) =>
              setState(() => _achievementError = _validateAchievement(value)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
                  labelText: context.l10n.flowTotalAchievementUpTo4040000,
                  suffixText: '%',
                  errorText: canInput ? _achievementError : null,
                  errorMaxLines: 2)
              .insetLabel(context),
        ),
      ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.featureCancel)),
        FilledButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }
}
