import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simai_flutter/simai_flutter.dart';

import '../service/ChartPlay/ChartPlayCustomAssetsService.dart';
import 'AppToast.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
/// 谱面设置抽屉 / 视频导出页共用的「自定义正解音」配置条目。
class ChartPlayCustomHitSoundTile extends StatefulWidget {
  final SimaiPlayerController controller;
  final VoidCallback onChanged;

  const ChartPlayCustomHitSoundTile({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<ChartPlayCustomHitSoundTile> createState() =>
      _ChartPlayCustomHitSoundTileState();
}

class _ChartPlayCustomHitSoundTileState
    extends State<ChartPlayCustomHitSoundTile> {
  bool _picking = false;

  Future<void> _pickAudio() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final nextPath = await ChartPlayCustomAssetsService.pickAndImportHitSound();
      if (!mounted || nextPath == null) return;
      final oldPath = widget.controller.customHitSoundPath;
      widget.controller.customHitSoundPath = nextPath;
      widget.onChanged();
      if (oldPath != null && oldPath != nextPath) {
        unawaited(ChartPlayCustomAssetsService.deleteManagedFileIfOwned(oldPath));
      }
      if (mounted) {
        setState(() {});
        AppToast.show(
          '已更换正解音：${ChartPlayCustomAssetsService.displayNameForPath(nextPath)}',
          tone: AppToastTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          e is FormatException ? e.message : '导入正解音失败：$e',
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _previewAudio() async {
    try {
      await previewSimaiHitSound(
        customFilePath: widget.controller.customHitSoundPath,
        volume: widget.controller.hitSoundVolume.clamp(0.0, 1.5),
      );
    } catch (e) {
      if (mounted) {
        AppToast.show('试听失败：$e', tone: AppToastTone.warning);
      }
    }
  }

  Future<void> _resetDefault() async {
    final oldPath = widget.controller.customHitSoundPath;
    widget.controller.customHitSoundPath = null;
    widget.onChanged();
    if (oldPath != null) {
      unawaited(ChartPlayCustomAssetsService.deleteManagedFileIfOwned(oldPath));
    }
    if (mounted) {
      setState(() {});
      AppToast.show('已恢复默认正解音', tone: AppToastTone.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final customPath = widget.controller.customHitSoundPath;
    final hasCustom = customPath != null && customPath.trim().isNotEmpty;
    final subtitle = hasCustom
        ? ChartPlayCustomAssetsService.displayNameForPath(customPath)
        : '默认内置音效（answer.wav）';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.audio_file_outlined,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '自定义正解音',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasCustom
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : _pickAudio,
                    icon: _picking
                        ? const ExpressiveLoadingIndicator(size: 14)
                        : const Icon(Icons.folder_open_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('选择音频', maxLines: 1),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewAudio,
                    icon: const Icon(Icons.volume_up_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('试听', maxLines: 1),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasCustom) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resetDefault,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('恢复默认'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 谱面设置抽屉 / 视频导出页共用的「自定义 NOTE 贴图」入口卡片。
class ChartPlayCustomNoteSkinTile extends StatelessWidget {
  final SimaiPlayerController controller;
  final VoidCallback onChanged;

  const ChartPlayCustomNoteSkinTile({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final count = controller.customNoteSkin.customizedCount;
        final subtitle = count == 0
            ? '未自定义（沿用当前内置皮肤）'
            : '已自定义 $count 项纹理（其余沿用内置）';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: scheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showChartPlayCustomNoteSkinSheet(
                context,
                controller: controller,
                onChanged: onChanged,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined,
                        size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '自定义 NOTE 贴图',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: count > 0
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 打开分槽位自定义 NOTE 贴图与皮肤包导入抽屉。
Future<void> showChartPlayCustomNoteSkinSheet(
  BuildContext context, {
  required SimaiPlayerController controller,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CustomNoteSkinSheet(
      controller: controller,
      onChanged: onChanged,
    ),
  );
}

class _CustomNoteSkinSheet extends StatefulWidget {
  final SimaiPlayerController controller;
  final VoidCallback onChanged;

  const _CustomNoteSkinSheet({
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_CustomNoteSkinSheet> createState() => _CustomNoteSkinSheetState();
}

class _CustomNoteSkinSheetState extends State<_CustomNoteSkinSheet> {
  bool _busy = false;

  Future<void> _importZip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ChartPlayCustomAssetsService.pickAndImportNoteSkinZip(
        widget.controller.customNoteSkin,
      );
      if (!mounted || result == null) return;
      widget.controller.customNoteSkin = result.skin;
      widget.onChanged();
      setState(() {});
      AppToast.show(
        '已导入 ${result.importedCount} 项 NOTE 贴图，其余沿用内置皮肤',
        tone: AppToastTone.success,
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          e is FormatException ? e.message : '导入皮肤包失败：$e',
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickSlot(SimaiCustomNoteSlot slot) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final nextPath =
          await ChartPlayCustomAssetsService.pickAndImportNoteSlot(slot.key);
      if (!mounted || nextPath == null) return;
      final oldPath = widget.controller.customNoteSkin.pathFor(slot.key);
      widget.controller.customNoteSkin =
          widget.controller.customNoteSkin.withSlot(slot.key, nextPath);
      widget.onChanged();
      if (oldPath != null && oldPath != nextPath) {
        unawaited(
          widget.controller.waitForNoteAssetsReady().whenComplete(
                () => ChartPlayCustomAssetsService.deleteManagedFileIfOwned(
                  oldPath,
                ),
              ),
        );
      }
      if (mounted) {
        setState(() {});
        AppToast.show('已更新「${slot.label}」贴图', tone: AppToastTone.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          e is FormatException ? e.message : '导入贴图失败：$e',
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearSlot(SimaiCustomNoteSlot slot) {
    final oldPath = widget.controller.customNoteSkin.pathFor(slot.key);
    widget.controller.customNoteSkin =
        widget.controller.customNoteSkin.withSlot(slot.key, null);
    widget.onChanged();
    if (oldPath != null) {
      unawaited(
        widget.controller.waitForNoteAssetsReady().whenComplete(
              () => ChartPlayCustomAssetsService.deleteManagedFileIfOwned(
                oldPath,
              ),
            ),
      );
    }
    setState(() {});
  }

  void _clearAll() {
    final oldPaths = widget.controller.customNoteSkin.texturePaths.values.toList();
    widget.controller.customNoteSkin = SimaiCustomNoteSkin.empty;
    widget.onChanged();
    if (oldPaths.isNotEmpty) {
      unawaited(
        widget.controller.waitForNoteAssetsReady().whenComplete(() async {
          for (final path in oldPaths) {
            await ChartPlayCustomAssetsService.deleteManagedFileIfOwned(path);
          }
        }),
      );
    }
    setState(() {});
    AppToast.show('已全部恢复为内置 NOTE 样式', tone: AppToastTone.info);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final skin = widget.controller.customNoteSkin;

    final Map<String, List<SimaiCustomNoteSlot>> grouped =
        <String, List<SimaiCustomNoteSlot>>{};
    for (final slot in SimaiCustomNoteSkin.slots) {
      grouped.putIfAbsent(slot.group, () => <SimaiCustomNoteSlot>[]).add(slot);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '自定义 NOTE 样式',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '仅替换已选择的槽位；未设置的音符仍沿用当前内置皮肤（立体经典 / 简洁 / 条形 / 扁平），播放与视频导出实时同步。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : _importZip,
                        icon: _busy
                            ? const ExpressiveLoadingIndicator(size: 15)
                            : const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('导入 .zip 皮肤包'),
                      ),
                    ),
                    if (skin.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _clearAll,
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('全部恢复内置'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (index, slot) in entry.value.indexed) ...[
                          if (index > 0)
                            Divider(
                              height: 1,
                              indent: 64,
                              color: scheme.outlineVariant,
                            ),
                          _buildSlotRow(
                            context,
                            slot,
                            skin.pathFor(slot.key),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotRow(
    BuildContext context,
    SimaiCustomNoteSlot slot,
    String? path,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasCustom = path != null && path.isNotEmpty;
    final file = hasCustom ? File(path) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: file != null
                ? Image.file(
                    file,
                    fit: BoxFit.contain,
                    cacheWidth: 96,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      '内置',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCustom
                      ? ChartPlayCustomAssetsService.displayNameForPath(path)
                      : (slot.hint.isNotEmpty
                            ? '皮肤包文件名：${slot.aliases.first}.png\n${slot.hint}'
                            : '皮肤包文件名：${slot.aliases.first}.png'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasCustom ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _pickSlot(slot),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(hasCustom ? '更换' : '选图'),
          ),
          if (hasCustom)
            IconButton(
              tooltip: '恢复内置',
              visualDensity: VisualDensity.compact,
              onPressed: _busy ? null : () => _clearSlot(slot),
              icon: Icon(Icons.close_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// 谱面设置抽屉共用的「自定义判定音效」入口卡片，点击打开各音色配置抽屉。
class ChartPlayCustomJudgementSoundsTile extends StatelessWidget {
  final SimaiPlayerController controller;
  final VoidCallback onChanged;

  const ChartPlayCustomJudgementSoundsTile({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final count = controller.customJudgementSounds.customizedCount;
        final subtitle = count == 0
            ? '未自定义（使用内置机台判定音效）'
            : '已自定义 $count 项音色（其余沿用内置）';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Material(
            color: scheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showChartPlayCustomJudgementSoundsSheet(
                context,
                controller: controller,
                onChanged: onChanged,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '自定义判定音效',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: count > 0
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 打开按音色分项配置自定义判定音效的底部抽屉。
Future<void> showChartPlayCustomJudgementSoundsSheet(
  BuildContext context, {
  required SimaiPlayerController controller,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CustomJudgementSoundsSheet(
      controller: controller,
      onChanged: onChanged,
    ),
  );
}

class _CustomJudgementSoundsSheet extends StatefulWidget {
  final SimaiPlayerController controller;
  final VoidCallback onChanged;

  const _CustomJudgementSoundsSheet({
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_CustomJudgementSoundsSheet> createState() =>
      _CustomJudgementSoundsSheetState();
}

class _CustomJudgementSoundsSheetState
    extends State<_CustomJudgementSoundsSheet> {
  SimaiJudgementSoundKind? _pickingKind;

  bool get _busy => _pickingKind != null;

  Future<void> _pickSound(SimaiJudgementSoundKind kind) async {
    if (_busy) return;
    setState(() => _pickingKind = kind);
    try {
      final nextPath =
          await ChartPlayCustomAssetsService.pickAndImportJudgementSound(kind);
      if (!mounted || nextPath == null) return;
      final oldPath = widget.controller.customJudgementSounds.pathFor(kind);
      widget.controller.customJudgementSounds =
          widget.controller.customJudgementSounds.withSound(kind, nextPath);
      widget.onChanged();
      if (oldPath != null && oldPath != nextPath) {
        unawaited(ChartPlayCustomAssetsService.deleteManagedFileIfOwned(oldPath));
      }
      if (mounted) {
        setState(() {});
        AppToast.show(
          '已更新「${kind.label}」音效：${ChartPlayCustomAssetsService.displayNameForPath(nextPath)}',
          tone: AppToastTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          e is FormatException ? e.message : '导入判定音效失败：$e',
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _pickingKind = null);
    }
  }

  Future<void> _previewSound(SimaiJudgementSoundKind kind) async {
    try {
      await previewSimaiJudgementSound(
        kind,
        volume: widget.controller.judgementSoundVolumes.volumeFor(kind),
        customFilePath: widget.controller.customJudgementSounds.pathFor(kind),
      );
    } catch (e) {
      if (mounted) {
        AppToast.show('试听失败：$e', tone: AppToastTone.warning);
      }
    }
  }

  Future<void> _clearSound(SimaiJudgementSoundKind kind) async {
    final oldPath = widget.controller.customJudgementSounds.pathFor(kind);
    widget.controller.customJudgementSounds =
        widget.controller.customJudgementSounds.withSound(kind, null);
    widget.onChanged();
    if (oldPath != null) {
      unawaited(ChartPlayCustomAssetsService.deleteManagedFileIfOwned(oldPath));
    }
    if (mounted) {
      setState(() {});
      AppToast.show('已恢复「${kind.label}」默认音效', tone: AppToastTone.info);
    }
  }

  Future<void> _clearAll() async {
    final oldPaths =
        widget.controller.customJudgementSounds.soundPaths.values.toList();
    widget.controller.customJudgementSounds = SimaiCustomJudgementSounds.empty;
    widget.onChanged();
    for (final path in oldPaths) {
      unawaited(ChartPlayCustomAssetsService.deleteManagedFileIfOwned(path));
    }
    if (mounted) {
      setState(() {});
      AppToast.show('已全部恢复默认判定音效', tone: AppToastTone.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final customSounds = widget.controller.customJudgementSounds;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '自定义判定音效',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (customSounds.isNotEmpty)
                      TextButton.icon(
                        onPressed: _busy ? null : _clearAll,
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('全部恢复默认'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '支持 wav / mp3 / ogg / m4a / flac / aac（≤ 10 MB）；未替换的音色仍沿用内置机台判定音效。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (index, kind)
                          in SimaiJudgementSoundKind.values.indexed) ...[
                        if (index > 0)
                          Divider(
                            height: 1,
                            color: scheme.outlineVariant,
                          ),
                        _buildKindRow(
                          context,
                          kind,
                          customSounds.pathFor(kind),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKindRow(
    BuildContext context,
    SimaiJudgementSoundKind kind,
    String? customPath,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasCustom = customPath != null && customPath.isNotEmpty;
    final isPickingThis = _pickingKind == kind;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          kind.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            kind.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCustom
                          ? ChartPlayCustomAssetsService.displayNameForPath(
                              customPath,
                            )
                          : '内置机台音效',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            hasCustom ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCustom)
                IconButton(
                  tooltip: '恢复默认',
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : () => _clearSound(kind),
                  icon: Icon(
                    Icons.restart_alt_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickSound(kind),
                  icon: isPickingThis
                      ? const ExpressiveLoadingIndicator(size: 14)
                      : const Icon(Icons.folder_open_rounded, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('选择音频', maxLines: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_previewSound(kind)),
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('试听', maxLines: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
