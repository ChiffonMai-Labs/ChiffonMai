import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../service/AnnouncementService.dart';
import 'SmoothLinearProgressIndicator.dart';
import '../widgets/AppDialogs.dart';

Future<void> showAnnouncementDialog(BuildContext context, Announcement value,
    {AnnouncementService? service}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final route = DialogRoute<void>(
      context: context,
      builder: (_) => _AnnouncementDialog(
          value: value, service: service ?? AnnouncementService()));
  await Navigator.of(context, rootNavigator: true).push(route);
  // 等退出动画结束，下一条启动提示才可以接着显示。
  await route.completed;
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({required this.value, required this.service});
  final Announcement value;
  final AnnouncementService service;

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  bool _dismiss = false;
  bool _saving = false;
  String? _error;

  Future<void> _confirm() async {
    if (_saving) return;
    if (_dismiss) {
      setState(() {
        _saving = true;
        _error = null;
      });
      try {
        await widget.service.dismiss(widget.value);
      } catch (_) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error = context.l10n.flowSettingsWereNotSavedPleaseRetry;
          });
        }
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.value;
    final published = value.publishedAt?.toUtc().add(const Duration(hours: 8));
    return PopScope(
      canPop: !_saving,
      child: AppAlertDialog(
        title: Row(children: [
          Icon(Icons.campaign_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(value.title)),
        ]),
        content: SizedBox(
          width: 440,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .55),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (published != null) ...[
                      Text(
                          context.l10n.flowP0P1P2BeijingTime((published.year).toString(), (published.month.toString().padLeft(2, '0')).toString(), (published.day.toString().padLeft(2, '0')).toString()),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                    ],
                    for (final block in value.blocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: block.type == 'text'
                            ? SelectableText(block.content,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.6))
                            : _AnnouncementImage(
                                block: block, version: value.version),
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title:  Text(context.l10n.flowDoNotShowThisAnnouncementAgain),
                      value: _dismiss,
                      onChanged: _saving
                          ? null
                          : (value) =>
                              setState(() => _dismiss = value ?? false),
                    ),
                    if (_error != null)
                      Text(_error!, style: TextStyle(color: scheme.error)),
                  ]),
            ),
          ),
        ),
        actions: [
          FilledButton(
              onPressed: _saving ? null : _confirm,
              child: Text(_saving ? context.l10n.flowSaving : context.l10n.featureGotIt))
        ],
      ),
    );
  }
}

class _AnnouncementImage extends StatefulWidget {
  const _AnnouncementImage({required this.block, required this.version});
  final AnnouncementBlock block;
  final String version;
  @override
  State<_AnnouncementImage> createState() => _AnnouncementImageState();
}

class _AnnouncementImageState extends State<_AnnouncementImage> {
  int _retry = 0;
  bool _retrying = false;
  String get _cacheKey =>
      'announcement:${widget.version}:${widget.block.content}';

  Future<void> _retryImage() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await CachedNetworkImage.evictFromCache(widget.block.content,
          cacheKey: _cacheKey);
    } finally {
      if (mounted) {
        setState(() {
          _retry++;
          _retrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          key: ValueKey(_retry),
          imageUrl: widget.block.content,
          cacheKey: _cacheKey,
          memCacheWidth: 1200,
          width: double.infinity,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.image_outlined),
                SizedBox(height: 12),
                SmoothLinearProgressIndicator()
              ])),
          errorWidget: (context, url, error) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: scheme.surfaceContainerHighest,
            child: Column(children: [
              const Icon(Icons.broken_image_outlined),
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: _retrying ? null : _retryImage,
                  icon: const Icon(Icons.refresh),
                  label:  Text(context.l10n.flowCouldNotLoadImageTapToRetry)),
            ]),
          ),
          imageBuilder: (_, provider) => Semantics(
            button: true,
            label:
                widget.block.caption.isEmpty ? context.l10n.flowEnlargeAnnouncementImage : widget.block.caption,
            child: GestureDetector(
              onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => Dialog(
                        clipBehavior: Clip.antiAlias,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(
                              child: InteractiveViewer(
                                  minScale: .5,
                                  maxScale: 5,
                                  child: Image(
                                      image: provider, fit: BoxFit.contain))),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child:  Text(context.l10n.flowCloseImage)),
                        ]),
                      )),
              child: Image(
                  image: provider, width: double.infinity, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      if (widget.block.caption.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(widget.block.caption,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ),
    ]);
  }
}
