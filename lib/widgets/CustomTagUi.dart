import 'dart:async';

import 'package:flutter/material.dart';

import '../entity/DivingFish/Song.dart';
import '../l10n/LocalizationsExtension.dart';
import '../service/CustomTagStore.dart';
import '../service/SongSearchService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/CoverUtil.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';
import 'AppUi.dart';

/// 自定义标签的预设色板；也可以用色相滑条取任意颜色。
const List<int> customTagPalette = [
  0xFFE53935, 0xFFF4511E, 0xFFFB8C00, 0xFFFDD835, //
  0xFF7CB342, 0xFF43A047, 0xFF00897B, 0xFF00ACC1,
  0xFF1E88E5, 0xFF3949AB, 0xFF8E24AA, 0xFFD81B60,
];

/// 按明暗模式为用户颜色算出底色、描边和文字色，保证白底 / 深底都看得清。
({Color background, Color border, Color foreground}) customTagColors(
    int argb, Brightness brightness) {
  final base = Color(argb);
  final hsl = HSLColor.fromColor(base);
  final dark = brightness == Brightness.dark;
  final foreground = hsl
      .withLightness(dark ? 0.78 : 0.32)
      .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
      .toColor();
  return (
    background: base.withValues(alpha: dark ? 0.22 : 0.14),
    border: base.withValues(alpha: dark ? 0.6 : 0.45),
    foreground: foreground,
  );
}

/// 自定义标签胶囊，外观与谱面标签一致，颜色取自用户设置。
class CustomTagChip extends StatelessWidget {
  final String name;
  final int color;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const CustomTagChip({
    super.key,
    required this.name,
    required this.color,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = customTagColors(color, Theme.of(context).brightness);
    final chip = AnimatedContainer(
      duration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 200)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected ? c.foreground : c.background,
        border: Border.all(color: selected ? c.foreground : c.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon,
              size: 14,
              color: selected
                  ? Theme.of(context).colorScheme.surface
                  : c.foreground),
          const SizedBox(width: 4),
        ],
        Text(name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Theme.of(context).colorScheme.surface
                  : c.foreground,
            )),
      ]),
    );
    if (onTap == null) return chip;
    return PressScale(
      child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: chip),
    );
  }
}

/// 色板 + 色相滑条。
class CustomTagColorPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const CustomTagColorPicker(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hsl = HSLColor.fromColor(Color(value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final color in customTagPalette)
            Semantics(
              button: true,
              selected: color == value,
              label: '#${color.toRadixString(16).substring(2).toUpperCase()}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(color),
                child: AnimatedContainer(
                  duration: AppDesignTokens.motion(
                      context, const Duration(milliseconds: 160)),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == value ? scheme.onSurface : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: color == value
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text(context.l10n.customTagHue,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(colors: [
                  for (var h = 0; h <= 360; h += 60)
                    HSLColor.fromAHSL(1, h.toDouble(), 0.7, 0.5).toColor(),
                ]),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 0,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbColor: Color(value),
                ),
                child: Slider(
                  value: hsl.hue,
                  min: 0,
                  max: 360,
                  onChanged: (h) => onChanged(
                      HSLColor.fromAHSL(1, h, 0.7, 0.5).toColor().toARGB32()),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

/// 新建 / 编辑标签名称与颜色。返回 null 表示取消。
Future<({String name, int color})?> showCustomTagEditor(BuildContext context,
    {CustomTag? initial}) {
  return showDialog<({String name, int color})>(
    context: context,
    builder: (_) => _CustomTagEditorDialog(initial: initial),
  );
}

class _CustomTagEditorDialog extends StatefulWidget {
  final CustomTag? initial;
  const _CustomTagEditorDialog({this.initial});

  @override
  State<_CustomTagEditorDialog> createState() => _CustomTagEditorDialogState();
}

class _CustomTagEditorDialogState extends State<_CustomTagEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late int _color = widget.initial?.color ?? customTagPalette[8];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final l10n = context.l10n;
    final duplicate = CustomTagStore.instance.tags.any((t) =>
        t.id != widget.initial?.id &&
        t.name.toLowerCase() == name.toLowerCase());
    setState(() => _error = name.isEmpty
        ? l10n.customTagNameRequired
        : duplicate
            ? l10n.customTagNameDuplicate
            : null);
    if (_error != null) return;
    Navigator.pop(context, (name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _name.text.trim();
    return AppAlertDialog(
      title: Text(widget.initial == null
          ? l10n.customTagCreate
          : l10n.customTagEdit),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              maxLength: CustomTagStore.maxNameLength,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.customTagName,
                errorText: _error,
              ).insetLabel(context),
            ),
            const SizedBox(height: 8),
            Text(l10n.customTagColor,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            CustomTagColorPicker(
                value: _color,
                onChanged: (c) => setState(() => _color = c)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: CustomTagChip(
                  name: preview.isEmpty ? l10n.customTagPreview : preview,
                  color: _color),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.featureCancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

/// 给一张谱面选择自定义标签（可直接新建）。
Future<void> showCustomTagChartSheet(
    BuildContext context, CustomTagChart chart) async {
  await CustomTagStore.instance.ensureLoaded();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) => ListenableBuilder(
      listenable: CustomTagStore.instance,
      builder: (ctx, _) {
        final l10n = ctx.l10n;
        final store = CustomTagStore.instance;
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.customTagForChart,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${chart.title} · ${ChartDifficulty.labelOf(chart.levelIndex, isUtage: chart.sheetType == 'utage')}',
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 14),
                if (store.tags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(l10n.customTagEmpty,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                  ),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                  for (final tag in store.tags)
                    CustomTagChip(
                      name: tag.name,
                      color: tag.color,
                      selected: tag.contains(chart),
                      icon: tag.contains(chart) ? Icons.check_rounded : null,
                      onTap: () => _guard(
                          ctx, () => store.toggleChart(tag.id, chart)),
                    ),
                  // 与标签同一种胶囊，高度一致；ActionChip 自带 32dp 最小高度会显得下沉。
                  CustomTagChip(
                    name: l10n.customTagCreate,
                    color: scheme.primary.toARGB32(),
                    icon: Icons.add_rounded,
                    onTap: () async {
                      final result = await showCustomTagEditor(ctx);
                      if (result == null || !ctx.mounted) return;
                      await _guard(ctx, () async {
                        final tag =
                            await store.create(result.name, result.color);
                        await store.addCharts(tag.id, [chart]);
                      });
                    },
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _guard(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    AppToast.show(context.l10n.customTagSaveFailed, tone: AppToastTone.error);
  }
}

/// 搜索选择歌曲（按歌名、别名、曲师、ID 等）。
Future<Song?> showCustomTagSongPicker(BuildContext context) {
  return showModalBottomSheet<Song>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SongPickerSheet(),
  );
}

class _SongPickerSheet extends StatefulWidget {
  const _SongPickerSheet();

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Song> _results = const [];
  bool _searching = false;
  int _request = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final request = ++_request;
      final results = await SongSearchService.searchSongs(query);
      // 旧请求不覆盖新结果。
      if (!mounted || request != _request) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final empty = _controller.text.trim().isEmpty;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: l10n.featureTitleBPMCharterArtistAliasID,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: empty || (_results.isEmpty && !_searching)
              ? Center(
                  child: Text(
                      empty ? l10n.customTagSearchHint : l10n.customTagNoSongs,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final song = _results[i];
                    final utage =
                        ChartDifficulty.isUtageSong(song.id, type: song.type);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppDesignTokens.radiusSmall),
                        child: CoverUtil.buildCoverWidget(song.id, 44),
                      ),
                      title: Text(song.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${utage ? 'UTAGE' : song.type == 'DX' ? 'DX' : 'ST'} · ${song.basicInfo.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, song),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

/// 选完歌曲后选择要加入的难度（可多选，默认全选）。
Future<List<CustomTagChart>?> pickCustomTagCharts(BuildContext context) async {
  final song = await showCustomTagSongPicker(context);
  if (song == null || !context.mounted) return null;
  final utage = ChartDifficulty.isUtageSong(song.id, type: song.type);
  final count = song.ds.isNotEmpty ? song.ds.length : song.level.length;
  final indices = [for (var i = 0; i < count; i++) i];
  if (indices.isEmpty) return null;
  final selected = indices.toSet();
  final sheetType = CustomTagChart.sheetTypeOf(song.id, song.type);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AppAlertDialog(
        title: Text(ctx.l10n.customTagChooseDifficulties),
        subtitle: song.title,
        content: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final i in indices)
            FilterChip(
              selected: selected.contains(i),
              label: Text(utage
                  ? '${ChartDifficulty.labelOf(i, isUtage: true)} ${i + 1}'
                  : ChartDifficulty.labelOf(i)),
              onSelected: (v) =>
                  setState(() => v ? selected.add(i) : selected.remove(i)),
            ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.featureCancel)),
          FilledButton(
              onPressed:
                  selected.isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.customTagAddCharts)),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  return [
    for (final i in indices)
      if (selected.contains(i))
        CustomTagChart(
          songId: song.id,
          title: song.title,
          sheetType: sheetType,
          levelIndex: i,
        ),
  ];
}
