import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../service/CacheManagementService.dart';
import 'SmoothLinearProgressIndicator.dart';
import '../widgets/AppDialogs.dart';

Future<bool?> showCacheManagementDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const _CacheManagementDialog(),
  );
}

class _CacheManagementDialog extends StatefulWidget {
  const _CacheManagementDialog();

  @override
  State<_CacheManagementDialog> createState() => _CacheManagementDialogState();
}

class _CacheManagementDialogState extends State<_CacheManagementDialog> {
  final _service = CacheManagementService.instance;
  CacheUsage? _usage;
  AppCacheKind? _clearing;
  double _clearProgress = 0;
  String? _error;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    try {
      final usage = await _service.inspect();
      if (mounted) setState(() => _usage = usage);
    } catch (e) {
      if (mounted) setState(() => _error = appL10n.flowCouldNotReadCacheUsageP0((e).toString()));
    }
  }

  Future<void> _clear(AppCacheKind kind) async {
    if (_clearing != null) return;
    setState(() {
      _clearing = kind;
      _clearProgress = 0;
      _error = null;
    });
    try {
      await _service.clear(
        kind,
        onProgress: (progress) {
          if (mounted) setState(() => _clearProgress = progress);
        },
      );
      final usage = await _service.inspect();
      if (mounted) setState(() => _usage = usage);
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.flowCouldNotClearCacheP0((e).toString()));
    } finally {
      if (mounted) {
        setState(() {
          _clearing = null;
          _clearProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;
    return AppAlertDialog(
      title:  Text(context.l10n.featureCacheManagement),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                usage == null
                    ? context.l10n.flowCalculatingCacheSize
                    : context.l10n.flowTotalUsageP0((_formatBytes(usage.bytesForAll)).toString()),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _cacheRow(
                kind: AppCacheKind.audio,
                icon: Icons.audiotrack_outlined,
                title: context.l10n.flowAudioCache,
                subtitle: usage == null
                    ? context.l10n.flowCalculating3
                    : context.l10n.flowP0FilesTotalP1((usage.audioFiles).toString(), (_formatBytes(usage.audioBytes)).toString()),
              ),
              _cacheRow(
                kind: AppCacheKind.pv,
                icon: Icons.movie_outlined,
                title: context.l10n.flowPVCache,
                subtitle: usage == null
                    ? context.l10n.flowCalculating3
                    : context.l10n.flowP0FilesTotalP1((usage.pvFiles).toString(), (_formatBytes(usage.pvBytes)).toString()),
              ),
              _cacheRow(
                kind: AppCacheKind.maidata,
                icon: Icons.data_object,
                title: context.l10n.flowMaidataCache,
                subtitle: usage == null
                    ? context.l10n.flowCalculating3
                    : context.l10n.flowP0FilesTotalP1((usage.maidataFiles).toString(), (_formatBytes(usage.maidataBytes)).toString()),
              ),
              TextButton.icon(
                onPressed: _clearing == null && usage != null && !_closing
                    ? () {
                        setState(() => _closing = true);
                        Navigator.of(context).pop(true);
                      }
                    : null,
                icon: const Icon(Icons.refresh),
                label:  Text(context.l10n.flowReloadBaseMaidata),
              ),
              if (_clearing != null) ...[
                const SizedBox(height: 8),
                SmoothLinearProgressIndicator(
                  value: _clearProgress,
                  minHeight: 6,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.flowCleaningP0(((_clearProgress * 100).round()).toString()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _clearing == null ? () => Navigator.of(context).pop() : null,
          child:  Text(context.l10n.featureClose),
        ),
      ],
    );
  }

  Widget _cacheRow({
    required AppCacheKind kind,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isClearing = _clearing == kind;
    final disabled = _clearing != null || _usage == null || _closing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: disabled ? null : () => _clear(kind),
              child: Text(isClearing ? context.l10n.flowCleaning : context.l10n.flowClear2),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}
