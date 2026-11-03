import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/service/DsRangeRecommendService.dart';
import 'package:my_first_flutter_app/service/RatingRecommendService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/RecommendUi.dart';

class DsRangeRecommendPage extends StatefulWidget {
  const DsRangeRecommendPage({super.key});

  @override
  State<DsRangeRecommendPage> createState() => _DsRangeRecommendPageState();
}

class _DsRangeRecommendPageState extends State<DsRangeRecommendPage> {
  bool _isLoading = true;
  bool _isLoadingRating = true;
  List<DsRangeRecommendItem> _results = [];
  String _sortMode = 'avg';
  double _minDs = 1.0;
  double _maxDs = 15.0;
  final TextEditingController _minDsController = TextEditingController();
  final TextEditingController _maxDsController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialDsRange();
  }

  Future<void> _loadInitialDsRange() async {
    try {
      final rating = await RatingRecommendService().getUserTotalRating();
      final dsRange = RatingRecommendService().calculateDsRange(rating);
      setState(() {
        _minDs = dsRange['min']!;
        _maxDs = dsRange['max']!;
        _minDsController.text = _minDs.toStringAsFixed(1);
        _maxDsController.text = _maxDs.toStringAsFixed(1);
        _isLoadingRating = false;
      });
    } catch (e) {
      setState(() {
        _minDsController.text = _minDs.toStringAsFixed(1);
        _maxDsController.text = _maxDs.toStringAsFixed(1);
        _isLoadingRating = false;
      });
    }
    _loadRecommendations();
  }

  @override
  void dispose() {
    _minDsController.dispose();
    _maxDsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final results = await DsRangeRecommendService().getRecommendations(
        _minDs,
        _maxDs,
        _sortMode,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  void _onMinDsChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 1.0) {
      _minDs = parsed;
    }
  }

  void _onMaxDsChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed <= 15.0) {
      _maxDs = parsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final totalPages = (_results.length / _pageSize).ceil();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _results.length);
    final paginatedResults = _results.sublist(startIndex, endIndex);

    return BackgroundPageScaffold(
      title: '基于定数区间推荐',
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          _buildControlPanel(brightness, screenWidth),
          Expanded(
            child: _isLoading || _isLoadingRating
                ? _buildLoadingState(screenHeight)
                : _results.isEmpty
                ? _buildEmptyState(brightness, screenHeight)
                : _buildResultsList(brightness, paginatedResults, screenWidth),
          ),
          if (!_isLoading &&
              !_isLoadingRating &&
              _results.isNotEmpty &&
              totalPages > 1)
            _buildPagination(brightness, totalPages, screenWidth),
        ],
      ),
    );
  }

  Widget _buildControlPanel(Brightness brightness, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minDsController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    onChanged: _onMinDsChanged,
                    decoration:
                        recommendInputDecoration(context, label: '最低定数'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '~',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxDsController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    onChanged: _onMaxDsChanged,
                    decoration:
                        recommendInputDecoration(context, label: '最高定数'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loadRecommendations,
                  child: const Text('推荐'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSortTabs(),
            if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '定数范围 ${_minDs.toStringAsFixed(1)} ~ ${_maxDs.toStringAsFixed(1)} · 共 ${_results.length} 条结果',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTabs() {
    const modes = ['avg', 'diff'];
    return SegmentedTabs(
      height: 44,
      items: const [
        SegmentedTabItem('平均达成率推荐'),
        SegmentedTabItem('定数差值推荐'),
      ],
      selectedIndex: modes.indexOf(_sortMode),
      onChanged: (index) {
        setState(() {
          _sortMode = modes[index];
        });
        _loadRecommendations();
      },
    );
  }

  Widget _buildLoadingState(double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenHeight * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载推荐结果...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenHeight * 0.05),
        child: Text(
          '暂无推荐结果，请检查定数区间输入是否正确',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.greyHint(brightness),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(Brightness brightness,
      List<DsRangeRecommendItem> results, double screenWidth) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 0, AppDesignTokens.gutter, 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final card = Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildResultCard(results[index], brightness, screenWidth),
        );
        // 只给首屏做入场，滚回来时不重播
        return index < 8
            ? EntranceAnimation(
                index: index,
                duration: const Duration(milliseconds: 300),
                offset: const Offset(0, 8),
                child: card,
              )
            : card;
      },
    );
  }

  Widget _buildResultCard(
      DsRangeRecommendItem item, Brightness brightness, double screenWidth) {
    final isAvg = _sortMode == 'avg';
    return RecommendResultCard(
      songId: item.songId,
      title: item.songTitle,
      type: item.type,
      levelIndex: item.levelIndex,
      level: item.level,
      ds: item.ds,
      metricValue: isAvg
          ? '${item.avg.toStringAsFixed(2)}%'
          : '${item.diffDifference >= 0 ? "+" : ""}${item.diffDifference.toStringAsFixed(2)}',
      metricLabel: isAvg ? '平均达成' : '定数差值',
      metricColor: isAvg
          ? null
          : (item.diffDifference < 0
              ? AppColors.successGreen(brightness)
              : AppColors.errorRed(brightness)),
      details: [
        if (item.userAchievement != null)
          '个人最佳 ${item.userAchievement!.toStringAsFixed(4)}%',
      ],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: item.songId,
              initialLevelIndex: item.levelIndex,
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildPagination(
      Brightness brightness, int totalPages, double screenWidth) {
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
