import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/service/RecommendByTagsService.dart';
import 'package:my_first_flutter_app/service/RatingRecommendService.dart';
import 'package:my_first_flutter_app/entity/RecommendationResult.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:flutter/services.dart';
import '../constant/LoadingTipsConstant.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/RecommendUi.dart';

class RecommendByTags extends StatefulWidget {
  const RecommendByTags({super.key});

  @override
  State<RecommendByTags> createState() => _RecommendByTagsState();
}

class _RecommendByTagsState extends State<RecommendByTags> {
  // 状态变量
  Map<String, List<RecommendationResult>> _recommendations = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _currentLoadingTip = '';

  // 新增状态变量
  String _currentTab = 'Best55'; // 当前选中的标签，默认为Best55
  int _currentPage = 1; // 当前页码
  int _pageSize = 10; // 每页显示的推荐项数量
  ScrollController _scrollController = ScrollController(); // 滚动控制器
  bool _isDisposed = false; // 页面是否已销毁，用于取消正在进行的异步操作
  StreamSubscription<String>? _tipSubscription; // 加载提示的流订阅
  String _rangeMode = 'rating';
  int _targetRating = 0;
  double _minDs = 1.0;
  double _maxDs = 15.0;
  bool _rangeSettingsLoaded = false;
  bool _rangeSettingsExpanded = true;
  late final TextEditingController _ratingController;
  late final TextEditingController _minDsController;
  late final TextEditingController _maxDsController;

  @override
  void initState() {
    super.initState();
    _ratingController = TextEditingController();
    _minDsController = TextEditingController();
    _maxDsController = TextEditingController();
    _initializeLoadingTip();
    // 延迟一小段时间再开始获取推荐结果，确保页面能够完全加载并显示加载动画
    // 这样可以避免在首页点击标签时出现卡顿
    Future.delayed(Duration(milliseconds: 1000), () {
      if (!_isDisposed && mounted) {
        _fetchRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tipSubscription?.cancel();
    // 加载提示用的是**全局静态**定时器：只 cancel 自己的订阅不够，
    // 定时器仍会 3 秒一次地往广播流里推（订阅都取消了，纯属空转，
    // 但会一直活到进程结束）。与项目里其它页面的做法保持一致。
    LoadingTipsConstant.stopAutoSwitch();
    _scrollController.dispose();
    _ratingController.dispose();
    _minDsController.dispose();
    _maxDsController.dispose();
    super.dispose();
  }

  void _initializeLoadingTip() {
    // 立即设置第一条提示，避免初始空白
    setState(() {
      _currentLoadingTip = LoadingTipsConstant.getRandomLoadingTip();
    });
    LoadingTipsConstant.startAutoSwitch();
    _tipSubscription = LoadingTipsConstant.tipStream.listen((newTip) {
      if (mounted && !_isDisposed) {
        setState(() {
          _currentLoadingTip = newTip;
        });
      }
    });
  }

  // 获取推荐结果
  Future<void> _fetchRecommendations() async {
    try {
      if (!mounted || _isDisposed) return;
      if (!_rangeSettingsLoaded) {
        _targetRating = await RatingRecommendService().getUserTotalRating();
        _applyRatingRange();
        _rangeSettingsLoaded = true;
      }
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 记录开始时间
      final startTime = DateTime.now();

      // 直接异步执行推荐算法，让UI先显示加载状态
      final result = await recommendSongs(
        minDsOverride: _minDs,
        maxDsOverride: _maxDs,
      );

      // 计算已用时间
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;

      // 确保加载动画至少显示2秒，避免闪烁
      if (elapsedTime < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsedTime));
      }

      if (!mounted || _isDisposed) return;
      setState(() {
        _recommendations = _prioritizeByRange(result);
        _isLoading = false;
        _errorMessage = null; // 成功时清除错误信息
      });
    } catch (e) {
      // 即使出错，也要确保加载动画至少显示2秒
      await Future.delayed(Duration(milliseconds: 2000));

      if (!mounted || _isDisposed) return;
      setState(() {
        _errorMessage = '获取推荐结果失败：$e';
        _isLoading = false;
      });
    }
  }

  void _applyRatingRange() {
    final range = RatingRecommendService().calculateDsRange(_targetRating);
    _minDs = range['min']!;
    _maxDs = range['max']!;
    _ratingController.text = _targetRating.toString();
    _minDsController.text = _minDs.toStringAsFixed(1);
    _maxDsController.text = _maxDs.toStringAsFixed(1);
  }

  void _applyManualRange() {
    final minValue = double.tryParse(_minDsController.text);
    final maxValue = double.tryParse(_maxDsController.text);
    if (minValue == null || maxValue == null || minValue > maxValue) return;
    setState(() {
      _minDs = minValue.clamp(1.0, 15.0);
      _maxDs = maxValue.clamp(_minDs, 15.0);
    });
  }

  Map<String, List<RecommendationResult>> _prioritizeByRange(
      Map<String, List<RecommendationResult>> source) {
    final result = <String, List<RecommendationResult>>{};
    for (final entry in source.entries) {
      final items = [...entry.value];
      items.sort((a, b) {
        final aIn = a.ds >= _minDs && a.ds <= _maxDs;
        final bIn = b.ds >= _minDs && b.ds <= _maxDs;
        if (aIn != bIn) return aIn ? -1 : 1;
        return b.similarity.compareTo(a.similarity);
      });
      result[entry.key] = items;
    }
    return result;
  }

  Widget _buildRangeSettings(Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final fieldDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppSurfaces.inset(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        borderSide: BorderSide.none,
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 8, AppDesignTokens.gutter, 8),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 将收起控制放在表单区标题上，收起后仍保留当前条件摘要。
          InkWell(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            onTap: () => setState(() {
              _rangeSettingsExpanded = !_rangeSettingsExpanded;
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 19, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text('推荐范围',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('范围内谱面优先',
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    ),
                  ),
                  Text(
                    !_rangeSettingsExpanded && _rangeMode == 'rating'
                        ? 'Rating $_targetRating'
                        : '${_minDs.toStringAsFixed(1)} ~ ${_maxDs.toStringAsFixed(1)}',
                    style: AppTheme.number(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _rangeSettingsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _rangeSettingsExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 两组切换并排放，把展开高度压到「切换 + 输入」两行。
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedTabs(
                                height: 38,
                                items: const [
                                  SegmentedTabItem('目标Rating'),
                                  SegmentedTabItem('定数区间'),
                                ],
                                selectedIndex: _rangeMode == 'rating' ? 0 : 1,
                                onChanged: (index) {
                                  setState(() {
                                    _rangeMode = index == 0 ? 'rating' : 'ds';
                                    if (_rangeMode == 'rating') {
                                      _applyRatingRange();
                                    }
                                  });
                                  _fetchRecommendations();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SegmentedTabs(
                                height: 38,
                                items: const [
                                  SegmentedTabItem('Best55'),
                                  SegmentedTabItem('Best15'),
                                ],
                                selectedIndex: _currentTab == 'Best55' ? 0 : 1,
                                onChanged: (index) => setState(() {
                                  _currentTab = index == 0 ? 'Best55' : 'Best15';
                                  _currentPage = 1;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_rangeMode == 'rating')
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ratingController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: fieldDecoration.copyWith(
                                    labelText: '目标 Rating',
                                  ),
                                  onSubmitted: (_) {
                                    _targetRating =
                                        int.tryParse(_ratingController.text) ??
                                            0;
                                    _applyRatingRange();
                                    _fetchRecommendations();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: '按目标 Rating 重新计算',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  _targetRating =
                                      int.tryParse(_ratingController.text) ?? 0;
                                  _applyRatingRange();
                                  _fetchRecommendations();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _minDsController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: fieldDecoration.copyWith(
                                      labelText: '最低定数'),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('至',
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant)),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _maxDsController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: fieldDecoration.copyWith(
                                      labelText: '最高定数'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: '按定数区间重新计算',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  _applyManualRange();
                                  _fetchRecommendations();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BackgroundPageScaffold(
      title: '根据标签推荐',
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          // 高度随内容走，收起后推荐区平滑接管释放出来的空间。
          _buildRangeSettings(brightness),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(screenWidth * 0.04,
                        4, screenWidth * 0.04, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isLoading)
                          Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(screenHeight * 0.05),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                      color: scheme.primary),
                                  SizedBox(
                                      height: screenHeight * 0.02),
                                  Text('正在计算推荐结果...',
                                      style: TextStyle(
                                          color: scheme
                                              .onSurfaceVariant)),
                                  SizedBox(
                                      height: screenHeight * 0.01),
                                  Text(
                                    _currentLoadingTip,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_errorMessage != null)
                          Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(screenHeight * 0.05),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: AppColors.errorRed(
                                          brightness),
                                      size: screenWidth * 0.12),
                                  SizedBox(
                                      height: screenHeight * 0.02),
                                  Text(_errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.errorRed(
                                              brightness))),
                                  SizedBox(
                                      height: screenHeight * 0.02),
                                  FilledButton.tonal(
                                      onPressed:
                                          _fetchRecommendations,
                                      child: const Text('重试')),
                                ],
                              ),
                            ),
                          )
                        else
                          _buildRecommendationContent(brightness),
                      ],
                    ),
                  ),
                ),
                if (!_isLoading && _errorMessage == null)
                  _buildPagination(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建推荐内容
  Widget _buildRecommendationContent(Brightness brightness) {
    final screenWidth = MediaQuery.of(context).size.width;
    List<RecommendationResult> results = _recommendations[_currentTab] ?? [];
    int totalItems = results.length;
    int startIndex = (_currentPage - 1) * _pageSize;
    int endIndex = min(startIndex + _pageSize, totalItems);
    List<RecommendationResult> paginatedResults = [];

    if (startIndex < totalItems) {
      paginatedResults = results.sublist(startIndex, endIndex);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paginatedResults.length; i++)
          EntranceAnimation(
            // 换页、换榜时重新进场
            key: ValueKey('$_currentTab-$_currentPage-$i'),
            index: i,
            duration: const Duration(milliseconds: 300),
            offset: const Offset(0, 8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  _buildResultCard(brightness, paginatedResults[i], screenWidth),
            ),
          ),
      ],
    );
  }

  // 构建单个推荐卡片
  Widget _buildResultCard(
      Brightness brightness, RecommendationResult result, double screenWidth) {
    return RecommendResultCard(
      songId: result.songId,
      title: result.songTitle,
      type: result.type,
      levelIndex: result.levelIndex,
      level: result.level,
      ds: result.ds,
      metricValue: '${(result.similarity * 100).toStringAsFixed(1)}%',
      metricLabel: '相似度',
      highlight: result.ableRiseTotalRating ? result.riseTotalRating : null,
      details: [
        '当前 ${result.nowAchievement.toStringAsFixed(4)}% → 目标 ${result.minAchievement.toStringAsFixed(4)}%',
        if (!result.ableRiseTotalRating) result.riseTotalRating,
      ],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: result.songId,
              initialLevelIndex: result.levelIndex,
            ),
          ),
        );
      },
    );
  }

  // 构建分页组件
  void _goToPage(int page) {
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPagination() {
    List<RecommendationResult> results = _recommendations[_currentTab] ?? [];
    int totalPages = (results.length / _pageSize).ceil();

    if (totalPages <= 1) {
      return const SizedBox.shrink(); // 只有一页时不显示分页
    }

    return PagerBar(
      page: _currentPage,
      totalPages: totalPages,
      onPrevious: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
      onNext: _currentPage < totalPages
          ? () => _goToPage(_currentPage + 1)
          : null,
    );
  }
}
