import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/service/RatingRecommendService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/RecommendUi.dart';

class RatingRecommendPage extends StatefulWidget {
  const RatingRecommendPage({super.key});

  @override
  State<RatingRecommendPage> createState() => _RatingRecommendPageState();
}

class _RatingRecommendPageState extends State<RatingRecommendPage> {
  bool _isLoading = true;
  bool _isLoadingRating = true;
  List<RatingRecommendItem> _results = [];
  String _sortMode = 'avg';
  String _resultSortMode = 'avg'; // 屏幕上这批结果所属的排序
  int _loadGeneration = 0;
  int _rating = 0;
  final TextEditingController _ratingController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialRating();
  }

  @override
  void dispose() {
    _ratingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRating() async {
    final rating = await RatingRecommendService().getUserTotalRating();
    setState(() {
      _rating = rating;
      _ratingController.text = rating.toString();
      _isLoadingRating = false;
    });
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final generation = ++_loadGeneration;
    final sortMode = _sortMode;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await RatingRecommendService().getRecommendations(
        _rating,
        sortMode,
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _results = results;
        _resultSortMode = sortMode;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _results = [];
        _currentPage = 1;
        _isLoading = false;
      });
    }
  }

  void _onRatingChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0) {
      _rating = parsed;
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
      title: context.l10n.featureTargetRatingRecommendations,
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          _buildControlPanel(brightness, screenWidth),
          Expanded(
            child: (_isLoading && _results.isEmpty) || _isLoadingRating
                ? _buildLoadingState(screenHeight)
                : _results.isEmpty
                    ? _buildEmptyState(brightness, screenHeight)
                    : _buildResultsList(
                        brightness, paginatedResults, screenWidth),
          ),
          if (!_isLoadingRating &&
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
      child: CollapsibleCard(
        title: context.l10n.flowRecommendationSettings,
        subtitle: _results.isEmpty
            ? null
            : context.l10n.flowConstantsP0P1P2Results(
                (RatingRecommendService()
                        .calculateDsRange(_rating)['min']!
                        .toStringAsFixed(1))
                    .toString(),
                (RatingRecommendService()
                        .calculateDsRange(_rating)['max']!
                        .toStringAsFixed(1))
                    .toString(),
                (_results.length).toString()),
        initiallyExpanded: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ratingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onRatingChanged,
                    decoration: recommendInputDecoration(context,
                        label: context.l10n.flowTargetRating),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loadRecommendations,
                  child: Text(context.l10n.flowRecommend),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSortTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTabs() {
    const modes = ['avg', 'diff'];
    return SegmentedTabs(
      height: 44,
      items: [
        SegmentedTabItem(context.l10n.flowByAverageAchievement),
        SegmentedTabItem(context.l10n.flowByConstantDifference),
      ],
      selectedIndex: modes.indexOf(_sortMode),
      onChanged: (index) {
        if (modes[index] == _sortMode) return;
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
              context.l10n.flowLoadingRecommendations,
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
          context.l10n.flowNoRecommendationsCheckTheRatingYouEntered,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.greyHint(brightness),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(Brightness brightness,
      List<RatingRecommendItem> results, double screenWidth) {
    return ListView.builder(
      // 拿到新结果时重新挂载，首屏才会重新进场。
      key: ObjectKey(_results),
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
                // 换页时重新进场
                key: ValueKey('$_currentPage-$index'),
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
      RatingRecommendItem item, Brightness brightness, double screenWidth) {
    final isAvg = _resultSortMode == 'avg';
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
      metricLabel: isAvg
          ? context.l10n.flowAvgAchievement
          : context.l10n.flowConstantDifference,
      metricColor: isAvg
          ? null
          : (item.diffDifference < 0
              ? AppColors.successGreen(brightness)
              : AppColors.errorRed(brightness)),
      details: [
        if (item.userAchievement != null)
          context.l10n.flowPersonalBestP0(
              (item.userAchievement!.toStringAsFixed(4)).toString()),
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
      onNext:
          _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
    );
  }
}
