import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/TranslationUtil.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

class SongTitleDialog extends StatefulWidget {
  final String title;
  const SongTitleDialog({super.key, required this.title});
  @override
  State<SongTitleDialog> createState() => _SongTitleDialogState();
}

class _SongTitleDialogState extends State<SongTitleDialog> {
  bool _loading = false;
  String? _translation, _error;
  Future<void> _translate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final translated = await TranslateService.translate(widget.title,
          from: 'auto', to: 'zh');
      if (!mounted) return;
      setState(() {
        _translation = translated;
        if (translated == null || translated.isEmpty)
          _error = context.l10n.flowTranslationIsUnavailableTryAgainLater;
      });
    } catch (_) {
      if (mounted)
        setState(
            () => _error = context.l10n.flowTranslationFailedTryAgainLater);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppAlertDialog(
        title: Text(context.l10n.flowSongTitle2),
        content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              SelectableText(widget.title),
              if (_translation != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                SelectableText(_translation!),
                const SizedBox(height: 8),
                Text(context.l10n.flowTranslatedByBaiduSLanguageModel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))
              ],
              if (_translation == null || _translation!.isEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                    onPressed: _loading ? null : _translate,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.translate),
                    label: Text(_loading
                        ? context.l10n.flowTranslating
                        : context.l10n.flowTranslateToChinese)),
              ],
            ])),
        actions: [
          TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.title));
                if (context.mounted)
                  AppToast.show(context.l10n.flowCopiedToClipboard,
                      tone: AppToastTone.success);
              },
              child: Text(context.l10n.flowCopy)),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.featureClose)),
        ],
      );
}
