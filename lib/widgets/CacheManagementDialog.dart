import 'package:flutter/material.dart';

import '../service/CacheManagementService.dart';
import 'SmoothLinearProgressIndicator.dart';

Future<void> showCacheManagementDialog(BuildContext context) {
  return showDialog<void>(
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
      if (mounted) setState(() => _error = '读取缓存占用失败：$e');
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
      if (mounted) setState(() => _error = '清理缓存失败：$e');
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
    return AlertDialog(
      title: const Text('缓存管理'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                usage == null
                    ? '正在统计缓存占用…'
                    : '总占用 ${_formatBytes(usage.bytesForAll)}（maidata 另列内存占用）',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _cacheRow(
                kind: AppCacheKind.audio,
                icon: Icons.audiotrack_outlined,
                title: '音源缓存',
                subtitle: usage == null
                    ? '统计中…'
                    : '${usage.audioFiles} 个文件 · ${_formatBytes(usage.audioBytes)}',
              ),
              _cacheRow(
                kind: AppCacheKind.pv,
                icon: Icons.movie_outlined,
                title: 'PV 缓存',
                subtitle: usage == null
                    ? '统计中…'
                    : '${usage.pvFiles} 个文件 · ${_formatBytes(usage.pvBytes)}',
              ),
              _cacheRow(
                kind: AppCacheKind.maidata,
                icon: Icons.data_object,
                title: 'maidata 缓存',
                subtitle: usage == null
                    ? '统计中…'
                    : '${usage.maidataFiles} 项缓存 · 存储 ${_formatBytes(usage.maidataBytes)} · 内存 ${_formatBytes(usage.maidataMemoryBytes)}',
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
                  '正在清理… ${(_clearProgress * 100).round()}%',
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
          child: const Text('关闭'),
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
    final disabled = _clearing != null || _usage == null;
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
              child: Text(isClearing ? '清理中…' : '清理'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
