import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entity/DivingFish/Song.dart';
import '../utils/CoverUtil.dart';

/// 在结果区的每张卡片中轮播候选曲绘；结果由页面在用户按停后统一提交。
class RandomChartRollingResults extends StatefulWidget {
  final int count;
  final List<Song> candidates;
  const RandomChartRollingResults(
      {super.key, required this.count, required this.candidates});

  @override
  State<RandomChartRollingResults> createState() =>
      _RandomChartRollingResultsState();
}

class _RandomChartRollingResultsState extends State<RandomChartRollingResults>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ticker;
  final _phase = ValueNotifier<int>(0);
  final Map<String, ImageProvider> _covers = {};
  bool _reduceMotion = false;
  bool _routeActive = true;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appActive = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_advance);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCovers());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _routeActive = ModalRoute.of(context)?.isCurrent ?? true;
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  void _syncTicker() {
    if (_reduceMotion || !_routeActive || !_appActive) {
      _ticker.stop();
    } else if (!_ticker.isAnimating) {
      _ticker.repeat();
    }
  }

  void _advance() {
    final next = (_ticker.lastElapsedDuration?.inMilliseconds ?? 0) ~/ 120;
    if (next != _phase.value) _phase.value = next;
  }

  Future<void> _prepareCovers() async {
    if (!mounted) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!mounted) return;
      final assets = manifest.listAssets().toSet();
      final providers = <ImageProvider>{};
      for (final song in widget.candidates.take(8)) {
        final paths = [
          CoverUtil.buildCoverPath(song.id),
          CoverUtil.getLocalCoverPath(song.id),
          CoverUtil.getLocalCoverPathRetry1(song.id),
          CoverUtil.getLocalCoverPathRetry2(song.id),
          CoverUtil.buildCoverPath('0')
        ];
        final path = paths.where(assets.contains).firstOrNull;
        if (path == null) continue;
        final provider = ResizeImage(AssetImage(path), width: 144, height: 144);
        _covers[song.id] = provider;
        providers.add(provider);
      }
      await Future.wait([
        for (final provider in providers)
          precacheImage(provider, context, onError: (_, __) {}),
      ]);
    } catch (error) {
      // 曲绘准备失败仍可按停；不影响已经确定的本轮结果。
      debugPrint('[RandomChart] 轮播曲绘暂不可用：$error');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('正在抽取 ${widget.count} 首 · 点击“停！”揭晓',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Semantics(
          label: '第 ${index + 1} 张卡片，等待揭晓',
          child: ExcludeSemantics(
              child: RepaintBoundary(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: scheme.outlineVariant)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ValueListenableBuilder<int>(
                  valueListenable: _phase,
                  builder: (context, phase, _) {
                    final song = widget.candidates.isEmpty
                        ? null
                        : widget.candidates[
                            (phase + index) % widget.candidates.length];
                    final provider = _covers[song?.id];
                    Widget fallback() => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note_rounded,
                            color: scheme.primary));
                    return Row(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox.square(
                              dimension: 72,
                              child: provider == null
                                  ? fallback()
                                  : Image(
                                      image: provider,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          fallback()))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(song?.title ?? '曲绘轮播中…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text('第 ${index + 1} 首 · 等待你按停',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          ])),
                    ]);
                  },
                ),
              ),
            ),
          )),
        ),
      ),
    ]);
  }
}
