import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_first_flutter_app/entity/nearcade/NearCadeShop.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/service/NearCadeService.dart';

import '../service/ArcadeMapStore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTaskActivity.dart';
import '../utils/AppTheme.dart';
import '../utils/ArcadeMarkerCluster.dart';
import '../utils/ArcadeShopUtil.dart';
import '../widgets/AppHeader.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';
import '../widgets/ArcadeMapUi.dart';
import '../widgets/EmptyState.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';

/// 全球机厅地图：全屏地图 + 悬浮搜索筛选 + 可拖动的机厅抽屉。
class GlobalArcadeMapPage extends StatefulWidget {
  const GlobalArcadeMapPage({super.key});

  @override
  State<GlobalArcadeMapPage> createState() => _GlobalArcadeMapPageState();
}

class _GlobalArcadeMapPageState extends State<GlobalArcadeMapPage>
    with SingleTickerProviderStateMixin {
  static const _defaultCenter = LatLng(35.0, 115.0);
  static const _defaultZoom = 4.0;
  static const _minZoom = 2.0;
  static const _maxZoom = 18.0;

  // 抽屉收起（也是进入页面时）和中间吸附档的高度（不含底部安全区）。
  static const _sheetMinPixels = 128.0;
  static const _sheetSnapPixels = 300.0;

  // 顶部标题、搜索框和筛选胶囊占用的高度（不含状态栏）。
  static const _topPanelHeight = 164.0;

  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Shop> _shops = const [];
  List<String> _searchable = const [];
  List<Shop> _filtered = const [];
  List<Shop> _viewShops = const [];
  List<ArcadeGameOption> _gameOptions = const [];
  double? _sheetSnapSize;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLegacyData = false;
  bool _isLocating = false;
  bool _mapReady = false;
  String? _error;
  DateTime? _lastFetchTime;
  (int, int)? _progress;

  String _searchQuery = '';
  bool _showSearchResults = false;
  bool _openOnly = false;
  Set<int> _selectedTitleIds = {};
  int _sheetTab = 0;
  LatLng? _userLocation;

  int _zoomStep = (_defaultZoom * 4).round();
  double _zoom = _defaultZoom;
  int _clusterRevision = 0;
  Timer? _viewDebounce;

  // 平移和缩放每帧都在变，这几项单独通知，不重建整页。
  final ValueNotifier<List<ArcadeMarkerCluster<Shop>>> _clusters =
      ValueNotifier(const []);
  final ValueNotifier<Shop?> _selectedShop = ValueNotifier(null);
  final ValueNotifier<Set<int>> _favorites = ValueNotifier(const {});
  final ValueNotifier<double> _rotation = ValueNotifier(0);
  final ValueNotifier<double?> _sheetPixels = ValueNotifier(null);

  late final AnimationController _flyController;
  Tween<double>? _flyLat;
  Tween<double>? _flyLng;
  Tween<double>? _flyZoom;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(vsync: this)
      ..addListener(_onFlyTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _syncCamera(force: true);
      });
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _initLoad();
  }

  @override
  void dispose() {
    _viewDebounce?.cancel();
    _flyController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _sheetController.dispose();
    _mapController.dispose();
    _clusters.dispose();
    _selectedShop.dispose();
    _favorites.dispose();
    _rotation.dispose();
    _sheetPixels.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    // 只在获得焦点时展开。拖动结果列表会收起键盘并失焦，这里若跟着隐藏，
    // 列表一拖就消失，表现就是滑不动；收起交给点地图、选结果和清空。
    if (_searchFocusNode.hasFocus &&
        _searchQuery.isNotEmpty &&
        !_showSearchResults) {
      setState(() => _showSearchResults = true);
    }
  }

  // ---- 数据 ----

  /// 只读本地缓存：全量数据要拉七十多页，由用户决定什么时候更新。
  Future<void> _initLoad() async {
    final favorites = await ArcadeMapStore.loadFavorites();
    final titles = await ArcadeMapStore.loadSelectedTitles();
    ArcadeMapSnapshot? snapshot;
    try {
      snapshot = await ArcadeMapStore.load();
    } catch (error) {
      debugPrint('[ArcadeMap] 读取本地机厅数据失败: $error');
    }
    if (!mounted) return;
    _favorites.value = favorites;
    setState(() {
      _selectedTitleIds = titles;
      if (snapshot != null) {
        _applyShops(snapshot.shops);
        _lastFetchTime = snapshot.fetchedAt;
        _isLegacyData = snapshot.isLegacy;
      }
      _isLoading = false;
    });
    // 抽屉默认收在最低处，没有数据时下载按钮会被藏住，要拉起来露出。
    if (_shops.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSheet());
    }
  }

  void _revealSheet() {
    final size = _sheetSnapSize;
    if (!mounted || size == null || !_sheetController.isAttached) return;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    if (duration == Duration.zero) {
      _sheetController.jumpTo(size);
    } else {
      _sheetController.animateTo(size,
          duration: duration, curve: AppDesignTokens.emphasizedCurve);
    }
  }

  void _applyShops(List<Shop> shops) {
    _shops = shops;
    _searchable = [
      for (final shop in shops)
        '${shop.name}\n${shop.address.detailed}\n${shop.address.general.join(' ')}'
            .toLowerCase()
    ];

    // 同一系列在源数据里有多种写法，筛选项只保留出现最多的那个名字。
    final nameCounts = <int, Map<String, int>>{};
    for (final shop in shops) {
      for (final game in shop.games) {
        if (game.name.isEmpty) continue;
        final counts = nameCounts.putIfAbsent(game.titleId, () => {});
        counts[game.name] = (counts[game.name] ?? 0) + 1;
      }
    }
    _gameOptions = [
      for (final entry in nameCounts.entries)
        ArcadeGameOption(
          titleId: entry.key,
          canonicalName: (entry.value.entries.toList()
                ..sort((a, b) {
                  final byCount = b.value.compareTo(a.value);
                  return byCount != 0 ? byCount : a.key.compareTo(b.key);
                }))
              .first
              .key,
          count: entry.value.values.fold(0, (sum, count) => sum + count),
        )
    ]..sort((a, b) => b.count.compareTo(a.count));
    _selectedTitleIds = {
      for (final option in _gameOptions)
        if (_selectedTitleIds.contains(option.titleId)) option.titleId
    };
    _recomputeFilter();
  }

  /// 手动更新。失败时保留现有内容，新数据到手才一次性替换。
  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _error = null;
      _progress = null;
    });
    try {
      final shops = await AppTaskActivity.run(
        () => NearCadeService().getAllShops(
          onProgress: (loaded, total) {
            if (mounted) setState(() => _progress = (loaded, total));
          },
        ),
      );
      if (!mounted) return;
      if (shops.isEmpty) throw StateError('NearCade 返回了空列表');
      final now = DateTime.now();
      setState(() {
        _applyShops(shops);
        _lastFetchTime = now;
        _isLegacyData = false;
      });
      await ArcadeMapStore.save(shops, now);
    } catch (error) {
      debugPrint('[ArcadeMap] 更新机厅数据失败: $error');
      if (!mounted) return;
      if (_shops.isEmpty) {
        setState(() => _error = error.toString());
      } else {
        AppToast.show(context.l10n.arcadeUpdateFailed,
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ---- 筛选与视野 ----

  void _recomputeFilter() {
    final query = _searchQuery.toLowerCase();
    _filtered = [
      for (var i = 0; i < _shops.length; i++)
        if (_matches(_shops[i], _searchable[i], query)) _shops[i]
    ];
    _rebuildClusters();
    _recomputeView();
  }

  bool _matches(Shop shop, String searchable, String query) {
    if (query.isNotEmpty && !searchable.contains(query)) return false;
    // 按 titleId 匹配：同一系列无论写成「maimai DX」还是「舞萌DX」都命中。
    if (_selectedTitleIds.isNotEmpty &&
        !shop.games.any((g) => _selectedTitleIds.contains(g.titleId))) {
      return false;
    }
    if (_openOnly && shop.openStatus().state != ArcadeOpenState.open) {
      return false;
    }
    return true;
  }

  void _applyFilterChange(VoidCallback change) {
    setState(() {
      change();
      _recomputeFilter();
    });
  }

  void _toggleTitle(int titleId) {
    _applyFilterChange(() {
      final next = {..._selectedTitleIds};
      if (!next.remove(titleId)) next.add(titleId);
      _selectedTitleIds = next;
    });
    unawaited(ArcadeMapStore.saveSelectedTitles(_selectedTitleIds));
  }

  void _clearFilters() {
    _applyFilterChange(() {
      _selectedTitleIds = {};
      _openOnly = false;
    });
    unawaited(ArcadeMapStore.saveSelectedTitles(const {}));
  }

  void _clearTitles() {
    _applyFilterChange(() => _selectedTitleIds = {});
    unawaited(ArcadeMapStore.saveSelectedTitles(const {}));
  }

  /// 筛选条只放常用项：已选的机台在前，其余用音游补足，完整列表在筛选面板里。
  List<ArcadeGameOption> get _quickGameOptions {
    const quickCount = 4;
    final selected = [
      for (final option in _gameOptions)
        if (_selectedTitleIds.contains(option.titleId)) option
    ];
    final music = [
      for (final option in _gameOptions)
        if (!_selectedTitleIds.contains(option.titleId) &&
            arcadeMusicTitlePriority.contains(option.titleId))
          option
    ];
    return [
      ...selected,
      ...music.take(math.max(0, quickCount - selected.length)),
    ];
  }

  void _rebuildClusters() {
    final located = [
      for (final shop in _filtered)
        if (shop.latLng != null) shop
    ];
    var clusters = clusterArcadeMarkers<Shop>(
        located, (shop) => shop.latLng!, _zoomStep / 4);
    if (_zoom >= 17) {
      clusters = [
        for (final cluster in clusters)
          for (final shop in cluster.items)
            ArcadeMarkerCluster<Shop>(shop.latLng!, [shop])
      ];
    }
    _clusterRevision++;
    _clusters.value = clusters;
  }

  void _recomputeView() {
    if (!_mapReady) {
      _viewShops = _filtered;
      return;
    }
    final camera = _mapController.camera;
    final bounds = camera.visibleBounds;
    final origin = _userLocation ?? camera.center;
    final entries = <(double, Shop)>[
      for (final shop in _filtered)
        if (shop.latLng case final point? when bounds.contains(point))
          (arcadeSortDistance(origin, point), shop)
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    _viewShops = [for (final entry in entries) entry.$2];
  }

  /// 收藏夹不受机台筛选影响，距离近的排前面。
  List<Shop> get _favoriteShops {
    final origin = _userLocation;
    final ids = _favorites.value;
    final shops = [
      for (final shop in _shops)
        if (ids.contains(shop.shopId)) shop
    ];
    if (origin != null) {
      double distance(Shop shop) {
        final point = shop.latLng;
        return point == null
            ? double.infinity
            : arcadeSortDistance(origin, point);
      }

      shops.sort((a, b) => distance(a).compareTo(distance(b)));
    }
    return shops;
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart &&
        event.source != MapEventSource.mapController &&
        _flyController.isAnimating) {
      _flyController.stop();
    }
    _rotation.value = event.camera.rotation;
    _syncCamera();
  }

  void _syncCamera({bool force = false}) {
    if (!_mapReady) return;
    final zoom = _mapController.camera.zoom;
    final step = (zoom * 4).round();
    _zoom = zoom;
    // 飞行途中每帧都跨缩放档位，等落地后再算一次聚合。
    if (force || (step != _zoomStep && !_flyController.isAnimating)) {
      _zoomStep = step;
      _rebuildClusters();
    }
    _viewDebounce?.cancel();
    _viewDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(_recomputeView);
    });
  }

  // ---- 相机 ----

  void _onFlyTick() {
    final progress =
        AppDesignTokens.emphasizedCurve.transform(_flyController.value);
    _mapController.move(
      LatLng(_flyLat!.transform(progress), _flyLng!.transform(progress)),
      _flyZoom!.transform(progress),
    );
  }

  void _flyTo(LatLng center, double zoom) {
    final target = zoom.clamp(_minZoom, _maxZoom).toDouble();
    final duration =
        AppDesignTokens.motion(context, const Duration(milliseconds: 620));
    if (duration == Duration.zero) {
      _flyController.stop();
      _mapController.move(center, target);
      _syncCamera(force: true);
      return;
    }
    final camera = _mapController.camera;
    _flyLat = Tween(begin: camera.center.latitude, end: center.latitude);
    _flyLng = Tween(begin: camera.center.longitude, end: center.longitude);
    _flyZoom = Tween(begin: camera.zoom, end: target);
    _flyController
      ..duration = duration
      ..forward(from: 0);
  }

  /// 把镜头对准机厅，并让它落在详情面板上方的可见区域。
  void _flyToAboveSheet(LatLng point, double zoom) {
    final camera = _mapController.camera;
    final target = zoom.clamp(_minZoom, _maxZoom).toDouble();
    final shift = MediaQuery.sizeOf(context).height * 0.24;
    final projected = camera.project(point, target);
    _flyTo(
      camera.unproject(math.Point(projected.x, projected.y + shift), target),
      target,
    );
  }

  void _fitShops(List<Shop> shops) {
    final points = [
      for (final shop in shops)
        if (shop.latLng != null) shop.latLng!
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _flyTo(points.first, 15);
      return;
    }
    final fitted = CameraFit.coordinates(
      coordinates: points,
      maxZoom: 16,
      padding: EdgeInsets.fromLTRB(
        48,
        MediaQuery.paddingOf(context).top + _topPanelHeight + 32,
        48,
        (_sheetPixels.value ?? _sheetMinPixels) + 32,
      ),
    ).fit(_mapController.camera);
    _flyTo(fitted.center, fitted.zoom);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _flyTo(camera.center, camera.zoom + delta);
  }

  // ---- 交互 ----

  Future<void> _locateUser() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          AppToast.show(context.l10n.flowTurnOnDeviceLocationServicesFirst,
              tone: AppToastTone.warning);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppToast.show(
              context.l10n.flowLocationPermissionIsPermanentlyDeniedEnableIt,
              tone: AppToastTone.warning);
        }
        return;
      }

      // 优先用最近已知位置（即时返回），没有才实时定位。
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {
        position = null;
      }
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          position = null;
        }
      }
      if (!mounted) return;
      if (position == null) {
        AppToast.show(context.l10n.flowCouldNotGetYourLocationCheckThat,
            tone: AppToastTone.error);
        return;
      }

      final located = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = located;
        _recomputeView();
      });
      _flyTo(located, 14);
    } catch (error) {
      debugPrint('[ArcadeMap] 定位失败: $error');
      if (mounted) {
        AppToast.show(context.l10n.flowLocationFailedP0(error.toString()),
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _toggleFavorite(Shop shop) {
    if (shop.shopId <= 0) {
      AppToast.show(context.l10n.arcadeNeedsUpdateToFavorite,
          tone: AppToastTone.warning);
      return;
    }
    final next = {..._favorites.value};
    if (!next.remove(shop.shopId)) next.add(shop.shopId);
    _favorites.value = next;
    unawaited(ArcadeMapStore.saveFavorites(next));
    setState(() {});
  }

  void _dismissSearch() {
    _searchFocusNode.unfocus();
    if (_showSearchResults) setState(() => _showSearchResults = false);
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilterChange(() {
      _searchQuery = '';
      _showSearchResults = false;
    });
  }

  Future<void> _showShopDetail(Shop shop) async {
    _selectedShop.value = shop;
    await showArcadeShopDetail(
      context,
      shop: shop,
      userLocation: _userLocation,
      favorites: _favorites,
      onToggleFavorite: () => _toggleFavorite(shop),
    );
    if (mounted && identical(_selectedShop.value, shop)) {
      _selectedShop.value = null;
    }
  }

  void _focusOnShop(Shop shop) {
    _dismissSearch();
    final point = shop.latLng;
    if (point != null && _mapReady) {
      _flyToAboveSheet(point, math.max(_zoom, 15.5));
    }
    _showShopDetail(shop);
  }

  void _pickRandomShop() {
    final rows = _sheetTab == 0 ? _viewShops : _favoriteShops;
    if (rows.isEmpty) {
      AppToast.show(context.l10n.arcadeRandomEmpty, tone: AppToastTone.warning);
      return;
    }
    _focusOnShop(rows[math.Random().nextInt(rows.length)]);
  }

  void _onClusterTap(ArcadeMarkerCluster<Shop> cluster) {
    _dismissSearch();
    if (_zoom >= _maxZoom - 0.5) {
      _showClusterList(cluster.items);
    } else {
      _fitShops(cluster.items);
    }
  }

  void _showClusterList(List<Shop> shops) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => ListView.builder(
        padding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 12),
        itemCount: shops.length,
        itemBuilder: (_, index) => _buildShopRow(shops[index], onTap: () {
          Navigator.pop(sheetContext);
          _showShopDetail(shops[index]);
        }),
      ),
    );
  }

  String _formatLastFetchTime(DateTime time) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.flowStatsJustUpdated;
    if (diff.inMinutes < 60) {
      return l10n.flowP0MinutesAgo2(diff.inMinutes.toString());
    }
    if (diff.inHours < 24) return l10n.flowP0HoursAgo2(diff.inHours.toString());
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  // ---- 界面 ----

  bool get _isFiltering =>
      _searchQuery.isNotEmpty || _selectedTitleIds.isNotEmpty || _openOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Stack(
          children: [
            Positioned.fill(child: _buildMap()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: safeTop + _topPanelHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.92),
                        scheme.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildControls(height, safeBottom),
            _buildSheet(height, safeTop, safeBottom),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopPanel(height, safeTop),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMap() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final user = _userLocation;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        onMapReady: () {
          _mapReady = true;
          if (mounted) setState(_recomputeView);
        },
        onMapEvent: _onMapEvent,
        onTap: (_, __) => _dismissSearch(),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
          subdomains: const ['1', '2', '3', '4'],
          // 必须与 android/app/build.gradle.kts 的 applicationId 一致：
          // 高德瓦片服务按 UA 区分调用方，写错等于以别人的身份请求。
          userAgentPackageName: 'cloud.chiffonmai.app',
          tileBuilder: dark ? darkModeTileBuilder : null,
        ),
        ListenableBuilder(
          listenable: Listenable.merge([_clusters, _selectedShop]),
          builder: (context, _) => _AnimatedMarkerLayer(
            markers: _buildMarkers(),
            signature: _clusterRevision,
          ),
        ),
        if (user != null)
          MarkerLayer(markers: [
            Marker(
              point: user,
              width: ArcadeUserMarker.size,
              height: ArcadeUserMarker.size,
              child: const ArcadeUserMarker(),
            ),
          ]),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final selected = _selectedShop.value;
    return [
      for (final cluster in _clusters.value)
        if (cluster.items.length > 1)
          Marker(
            point: cluster.center,
            width: ArcadeClusterMarker.sizeFor(cluster.items.length),
            height: ArcadeClusterMarker.sizeFor(cluster.items.length),
            child: Semantics(
              button: true,
              label:
                  l10n.flowP0ArcadesTapToExpand(cluster.items.length.toString()),
              child: GestureDetector(
                onTap: () => _onClusterTap(cluster),
                child: ArcadeClusterMarker(count: cluster.items.length),
              ),
            ),
          )
        else
          Marker(
            point: cluster.center,
            width: 28,
            height: 28,
            child: Semantics(
              button: true,
              label: cluster.items.first.name,
              child: GestureDetector(
                onTap: () {
                  _dismissSearch();
                  _showShopDetail(cluster.items.first);
                },
                child: ArcadeShopMarker(
                  color: AppColors.arcadeGame(
                      cluster.items.first.primaryTitle(_selectedTitleIds),
                      brightness),
                  selected: identical(selected, cluster.items.first),
                ),
              ),
            ),
          ),
    ];
  }

  Widget _buildTopPanel(double height, double safeTop) {
    final showResults = _showSearchResults && _searchQuery.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(
          title: context.l10n.featureWorldwideArcadeMap,
          actions: [
            IconButton(
              tooltip: context.l10n.arcadeRegions,
              icon: const Icon(Icons.public_rounded),
              onPressed: _filtered.isEmpty
                  ? null
                  : () => showArcadeRegionSheet(context,
                      shops: _filtered, onSelect: _fitShops),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading || _isRefreshing ? null : _refresh,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
          child: _buildSearchField(),
        ),
        if (showResults)
          _buildSearchResults(height, safeTop)
        else if (_gameOptions.isNotEmpty)
          _buildFilterBar(),
      ],
    );
  }

  Widget _buildSearchField() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      decoration:
          arcadeFloatingDecoration(context, AppDesignTokens.radiusMedium),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 21, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: context.l10n.flowSearchArcadeNameOrAddress,
                hintStyle: const TextStyle(fontSize: 14),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                final query = value.trim();
                _applyFilterChange(() {
                  _searchQuery = query;
                  _showSearchResults = query.isNotEmpty;
                });
              },
              onTap: () {
                if (_searchQuery.isNotEmpty) {
                  setState(() => _showSearchResults = true);
                }
              },
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            Text('${_filtered.length}',
                style: AppTheme.number(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                )),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _clearSearch,
              icon: Icon(Icons.close_rounded,
                  size: 19, color: scheme.onSurfaceVariant),
            ),
          ] else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildSearchResults(double height, double safeTop) {
    final results = _filtered.take(30).toList();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // 结果卡片从搜索框下方开始，再留一点底边距。
    final maxHeight =
        (height - safeTop - keyboard - AppHeader.toolbarHeight - 74)
            .clamp(120.0, height * 0.7);
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 8),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration:
          arcadeFloatingDecoration(context, AppDesignTokens.radiusMedium),
      clipBehavior: Clip.antiAlias,
      child: results.isEmpty
          ? SizedBox(
              height: 200,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: context.l10n.arcadeNoMatchTitle,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: results.length,
              itemBuilder: (_, index) => _buildShopRow(results[index]),
            ),
    );
  }

  Widget _buildFilterBar() {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final selectedCount = _selectedTitleIds.length;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding:
            const EdgeInsets.symmetric(horizontal: AppDesignTokens.gutter),
        children: [
          ArcadeFilterChip(
            label: l10n.arcadeFilterAction,
            icon: Icons.tune_rounded,
            count: selectedCount > 0 ? '$selectedCount' : null,
            selected: selectedCount > 0,
            onTap: () => showArcadeGameFilterSheet(
              context,
              options: _gameOptions,
              selected: _selectedTitleIds,
              onToggle: _toggleTitle,
              onClear: _clearTitles,
            ),
          ),
          const SizedBox(width: 6),
          ArcadeFilterChip(
            label: l10n.arcadeOpenNow,
            icon: Icons.schedule_rounded,
            selected: _openOnly,
            onTap: () => _applyFilterChange(() => _openOnly = !_openOnly),
          ),
          for (final option in _quickGameOptions) ...[
            const SizedBox(width: 6),
            ArcadeFilterChip(
              label: option.canonicalName,
              count: '${option.count}',
              dotColor: AppColors.arcadeGame(option.titleId, brightness),
              selected: _selectedTitleIds.contains(option.titleId),
              onTap: () => _toggleTitle(option.titleId),
            ),
          ],
        ],
      ),
    );
  }

  /// 右侧按钮贴着抽屉上沿走，抽屉拉高后淡出，让位给列表。
  Widget _buildControls(double height, double safeBottom) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<double?>(
      valueListenable: _sheetPixels,
      builder: (context, pixels, child) {
        final sheet = pixels ?? _sheetMinPixels + safeBottom;
        final visible = sheet < height * 0.6;
        return Positioned(
          right: 12,
          bottom: sheet + 12,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: AppDesignTokens.motion(
                  context, const Duration(milliseconds: 160)),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _rotation,
            builder: (context, rotation, _) {
              if (rotation.abs() < 0.5) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ArcadeMapControlGroup(children: [
                  ArcadeMapControlButton(
                    icon: Icons.navigation_rounded,
                    tooltip: l10n.arcadeResetNorth,
                    color: scheme.error,
                    onTap: () => _mapController.rotate(0),
                  ),
                ]),
              );
            },
          ),
          ArcadeMapControlGroup(children: [
            ArcadeMapControlButton(
              icon: Icons.add_rounded,
              tooltip: l10n.arcadeZoomIn,
              onTap: () => _zoomBy(1),
            ),
            ArcadeMapControlButton(
              icon: Icons.remove_rounded,
              tooltip: l10n.arcadeZoomOut,
              onTap: () => _zoomBy(-1),
            ),
          ]),
          const SizedBox(height: 8),
          ArcadeMapControlGroup(children: [
            ArcadeMapControlButton(
              icon: Icons.my_location_rounded,
              tooltip: l10n.arcadeLocate,
              busy: _isLocating,
              onTap: _locateUser,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSheet(double height, double safeTop, double safeBottom) {
    final minSize = ((_sheetMinPixels + safeBottom) / height).clamp(0.08, 0.4);
    final snapSize =
        ((_sheetSnapPixels + safeBottom) / height).clamp(minSize + 0.02, 0.6);
    final maxSize = ((height - safeTop - _topPanelHeight) / height)
        .clamp(snapSize + 0.02, 0.95);
    _sheetSnapSize = snapSize;
    final scheme = Theme.of(context).colorScheme;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        _sheetPixels.value = notification.extent * height;
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: minSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        snap: true,
        snapSizes: [snapSize],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppSurfaces.card(context),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDesignTokens.radiusCard)),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                PinnedHeaderSliver(child: _buildSheetHeader()),
                ..._buildSheetBody(safeBottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetHeader() {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final progress = _progress;
    final total = _isFiltering
        ? l10n.flowP0Arcades(_filtered.length.toString())
        : l10n.flowP0ArcadesTotal(_shops.length.toString());
    final fetched = _lastFetchTime;
    final subtitle = [
      total,
      if (fetched != null)
        l10n.flowLastUpdatedP0(_formatLastFetchTime(fetched)),
    ].join(' · ');

    return ColoredBox(
      color: AppSurfaces.card(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.gutter, 8, AppDesignTokens.gutter, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
                ArcadeMapControlButton(
                  icon: Icons.casino_outlined,
                  tooltip: l10n.arcadeRandomPick,
                  onTap: _pickRandomShop,
                ),
              ],
            ),
            SegmentedTabs(
              height: 38,
              inlineCaption: true,
              selectedIndex: _sheetTab,
              onChanged: (index) {
                if (index != _sheetTab) setState(() => _sheetTab = index);
              },
              items: [
                SegmentedTabItem(l10n.arcadeTabInView,
                    caption: '${_viewShops.length}'),
                SegmentedTabItem(l10n.arcadeTabFavorites,
                    caption: '${_favorites.value.length}'),
              ],
            ),
            if (_isRefreshing) ...[
              const SizedBox(height: 8),
              SmoothLinearProgressIndicator(
                value: progress == null || progress.$2 == 0
                    ? null
                    : progress.$1 / progress.$2,
              ),
              const SizedBox(height: 4),
              Text(
                progress == null
                    ? l10n.arcadeUpdating('0', '…')
                    : l10n.arcadeUpdating(
                        progress.$1.toString(), progress.$2.toString()),
                style: AppTheme.number(
                    fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ] else if (_isLegacyData) ...[
              const SizedBox(height: 8),
              Text(l10n.arcadeLegacyHint,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warningOrange(
                          Theme.of(context).brightness))),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSheetBody(double safeBottom) {
    final l10n = context.l10n;

    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: false, child: child);

    if (_isLoading) {
      return [fill(const Center(child: CircularProgressIndicator()))];
    }
    if (_error != null) {
      return [
        fill(EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.flowCouldNotLoad,
          message: _error,
          actionLabel: l10n.flowRetry,
          actionIcon: Icons.refresh_rounded,
          onAction: _refresh,
        ))
      ];
    }
    if (_shops.isEmpty) {
      return [
        fill(EmptyState(
          icon: Icons.travel_explore_rounded,
          title: l10n.flowNoArcadeDataYet,
          message: l10n.arcadeNoDataHint,
          actionLabel: _isRefreshing ? null : l10n.arcadeDownloadData,
          actionIcon: Icons.download_rounded,
          onAction: _isRefreshing ? null : _refresh,
        ))
      ];
    }

    final rows = _sheetTab == 0 ? _viewShops : _favoriteShops;
    if (rows.isEmpty) {
      return [
        fill(_sheetTab == 0
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: l10n.arcadeNoMatchTitle,
                message: l10n.arcadeNoMatchHint,
                actionLabel: _selectedTitleIds.isNotEmpty || _openOnly
                    ? l10n.arcadeClearFilters
                    : null,
                onAction: _selectedTitleIds.isNotEmpty || _openOnly
                    ? _clearFilters
                    : null,
              )
            : EmptyState(
                icon: Icons.star_outline_rounded,
                title: l10n.arcadeNoFavoritesTitle,
                message: l10n.arcadeNoFavoritesHint,
              ))
      ];
    }

    return [
      SliverList.separated(
        itemCount: rows.length,
        separatorBuilder: (context, _) => Divider(
          height: 1,
          indent: AppDesignTokens.gutter + 52,
          endIndent: AppDesignTokens.gutter,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (_, index) => _buildShopRow(rows[index]),
      ),
      SliverPadding(padding: EdgeInsets.only(bottom: safeBottom + 16)),
    ];
  }

  Widget _buildShopRow(Shop shop, {VoidCallback? onTap}) {
    final user = _userLocation;
    final point = shop.latLng;
    return ArcadeShopRow(
      shop: shop,
      selectedTitles: _selectedTitleIds,
      distanceMeters: user != null && point != null
          ? arcadeDistanceMeters(user, point)
          : null,
      favorited: _favorites.value.contains(shop.shopId),
      onToggleFavorite: () => _toggleFavorite(shop),
      onTap: onTap ?? () => _focusOnShop(shop),
    );
  }
}

/// 聚合结果变化时整层淡入一次。只用一个 MarkerLayer，避免在缩放时同时挂载
/// 新旧图层触发地图图层依赖错误。
class _AnimatedMarkerLayer extends StatefulWidget {
  final List<Marker> markers;
  final int signature;

  const _AnimatedMarkerLayer({required this.markers, required this.signature});

  @override
  State<_AnimatedMarkerLayer> createState() => _AnimatedMarkerLayerState();
}

class _AnimatedMarkerLayerState extends State<_AnimatedMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(begin: 0.4, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(covariant _AnimatedMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signature != widget.signature &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: MarkerLayer(markers: widget.markers),
    );
  }
}
