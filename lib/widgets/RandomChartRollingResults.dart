import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entity/DivingFish/Song.dart';
import '../utils/CoverUtil.dart';
import '../utils/AppDesignTokens.dart';

/// 结果区的每张卡片各自独立、随机地跳换候选曲；结果由页面在用户按停后统一提交。
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
  /// 轮播用的候选数量上限：曲库可能上千首，只预载这么多张曲绘。
  static const int _poolSize = 48;
  static const int _minHoldMs = 90;
  static const int _holdJitterMs = 80;

  late final AnimationController _ticker;
  final _random = Random();
  late final List<Song> _pool;

  /// 每张卡片当前显示的 [_pool] 下标。
  late final List<ValueNotifier<int>> _shown;

  /// [_pool] 每一首正被几张卡片显示，用来尽量避免同屏重复。
  late final List<int> _useCounts;
  late final List<int> _nextSwapMs;
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
    _pool = widget.candidates.take(_poolSize).toList(growable: false);
    _useCounts = List<int>.filled(_pool.length, 0);
    _nextSwapMs = List<int>.filled(widget.count, 0);
    _shown = List.generate(widget.count, (_) {
      if (_pool.isEmpty) return ValueNotifier<int>(-1);
      final first = _pickOther(-1);
      _useCounts[first]++;
      return ValueNotifier<int>(first);
    });
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
      // 重新启动后 elapsed 从 0 算起，旧的换曲时间点要一起清掉。
      _nextSwapMs.fillRange(0, _nextSwapMs.length, 0);
      _ticker.repeat();
    }
  }

  int _pickOther(int current) {
    final size = _pool.length;
    for (var attempt = 0; attempt < 6; attempt++) {
      final next = _random.nextInt(size);
      if (next != current && _useCounts[next] == 0) return next;
    }
    // 候选不够每张卡片各显示一首时允许重复，只保证和自己上一次不同。
    return size == 1 ? 0 : (current + 1 + _random.nextInt(size - 1)) % size;
  }

  void _advance() {
    if (_pool.length < 2) return;
    final now = _ticker.lastElapsedDuration?.inMilliseconds ?? 0;
    for (var card = 0; card < _shown.length; card++) {
      if (now < _nextSwapMs[card]) continue;
      final shown = _shown[card];
      _useCounts[shown.value]--;
      final next = _pickOther(shown.value);
      _useCounts[next]++;
      shown.value = next;
      _nextSwapMs[card] =
          now + _minHoldMs + _random.nextInt(_holdJitterMs + 1);
    }
  }

  Future<void> _prepareCovers() async {
    if (!mounted) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!mounted) return;
      final assets = manifest.listAssets().toSet();
      final providers = <ImageProvider>{};
      for (final song in _pool) {
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
    for (final shown in _shown) {
      shown.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(context.l10n.flowDrawingP0SongsTapStopToReveal((widget.count).toString()),
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
          label: context.l10n.flowCardP0WaitingToReveal((index + 1).toString()),
          child: ExcludeSemantics(
              child: RepaintBoundary(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppSurfaces.card(context),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ValueListenableBuilder<int>(
                  valueListenable: _shown[index],
                  builder: (context, shown, _) {
                    final song = shown < 0 ? null : _pool[shown];
                    final provider = _covers[song?.id];
                    Widget fallback() => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note_rounded,
                            color: scheme.primary));
                    return Row(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                          child: SizedBox.square(
                              dimension: 64,
                              child: provider == null
                                  ? fallback()
                                  : Image(
                                      image: provider,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, __, ___) =>
                                          fallback()))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(song?.title ?? context.l10n.flowCyclingCoverArt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text(context.l10n.flowSongP0WaitingForYouToStop((index + 1).toString()),
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
