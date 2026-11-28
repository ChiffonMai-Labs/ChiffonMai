import '../../l10n/FeatureLocalizations.dart';
import '../../l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../Library/CustomTagsPage.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/FavoriteFeaturesNotifier.dart';
import '../../service/Recognition/CoverRecognitionService.dart';
import '../Library/SongSearchPage.dart';
import '../Library/UnionUpdateComparePage.dart';
import '../Library/UpdateCalendarPage.dart';
import '../Collection/CollectionSearchPage.dart';
import '../Library/VersionViewPage.dart';
import '../Library/DifficultyDistributionPage.dart';
import '../Recognition/CoverRecognitionPage.dart';
import '../Recognition/ScoreOcrPage.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';

class LibraryHubPage extends StatefulWidget {
  final bool showHeader;

  const LibraryHubPage({super.key, this.showHeader = true});
  @override
  State<LibraryHubPage> createState() => _LibraryHubPageState();
}

class _LibraryHubPageState extends State<LibraryHubPage> {
  void _open(BuildContext context, Widget page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  bool _isFavorited(String title) =>
      FavoriteFeaturesNotifier.titles.contains(title);

  Future<void> _toggleFavorite(String title) =>
      FavoriteFeaturesNotifier.toggle(title);

  // ===== 曲绘索引构建状态 =====
  bool _coverIndexReady = false;
  bool _coverIndexBuilding = false;
  int _coverProgressCurrent = 0;
  int _coverProgressTotal = 0;

  @override
  void initState() {
    super.initState();
    _checkCoverIndexStatus();
  }

  Future<void> _checkCoverIndexStatus() async {
    final valid = await CoverRecognitionService.instance.isHashCacheValid();
    if (mounted) setState(() => _coverIndexReady = valid);
  }

  /// 点曲绘识别：索引已就绪 → 直接打开；未就绪 → 在按钮上构建索引，
  /// 构建完后再导航（按钮在构建期间显示进度且不可重复点）。
  Future<void> _openCoverRecognition() async {
    if (_coverIndexBuilding) return;
    if (!_coverIndexReady) {
      setState(() {
        _coverIndexBuilding = true;
        _coverProgressCurrent = 0;
        _coverProgressTotal = 0;
      });
      try {
        await CoverRecognitionService.instance.precomputeHashes(
          onProgress: (current, total) {
            if (mounted) {
              setState(() {
                _coverProgressCurrent = current;
                _coverProgressTotal = total;
              });
            }
          },
        );
        if (!mounted) return;
        setState(() {
          _coverIndexReady = true;
          _coverIndexBuilding = false;
          _coverProgressCurrent = 0;
          _coverProgressTotal = 0;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _coverIndexBuilding = false;
          });
          AppToast.show(context.l10n.hubCoverIndexFailed(e.toString()), tone: AppToastTone.error);
        }
        return;
      }
    }
    if (!mounted) return;
    _open(context, const CoverRecognitionPage());
  }

  void _showSearchGroupSheet(BuildContext context) {
    showHubGroupSheet(
      context,
      title: '乐曲检索',
      subtitle: '搜索国服与非国服曲库',
      itemsBuilder: (sheetContext) => [
        HubActionTile(
          title: '乐曲查询',
          subtitle: '按歌名、别名、谱师和标签搜索',
          icon: Icons.search_rounded,
          isFavorited: _isFavorited('乐曲查询'),
          onToggleFavorite: () => _toggleFavorite('乐曲查询'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _open(context, const SongSearchPage());
          },
        ),
        HubActionTile(
          title: '非国服乐曲查询',
          subtitle: '搜索与筛选非国服曲库',
          icon: Icons.travel_explore_rounded,
          isFavorited: _isFavorited('非国服乐曲查询'),
          onToggleFavorite: () => _toggleFavorite('非国服乐曲查询'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _open(context, const SongSearchPage(extraOnly: true));
          },
        ),
        HubActionTile(
          title: '自定义标签',
          subtitle: '自定义标签名称、颜色与谱面，接入标签筛选与统计',
          icon: Icons.sell_outlined,
          isFavorited: _isFavorited('自定义标签'),
          onToggleFavorite: () => _toggleFavorite('自定义标签'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _open(context, const CustomTagsPage());
          },
        ),
      ],
    );
  }

  void _showVersionAndConstantSheet(BuildContext context) {
    showHubGroupSheet(
      context,
      title: '版本与定数分析',
      subtitle: '国服更新对照 · 版本对照 · 定数分布',
      itemsBuilder: (sheetContext) => [
        HubActionTile(
          title: '国服更新对照',
          subtitle: '看日服已上、国服还没上的曲目',
          icon: Icons.flag_rounded,
          isFavorited: _isFavorited('国服更新对照'),
          onToggleFavorite: () => _toggleFavorite('国服更新对照'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _open(context, const UnionUpdateComparePage());
          },
        ),
        HubActionTile(
          title: '版本对照',
          subtitle: '按版本整理可游玩曲目',
          icon: Icons.compare_arrows_rounded,
          isFavorited: _isFavorited('版本对照'),
          onToggleFavorite: () => _toggleFavorite('版本对照'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _open(context, VersionView());
          },
        ),
        HubActionTile(
          title: '定数分布',
          subtitle: '查看谱面定数分布',
          icon: Icons.bar_chart_rounded,
          isFavorited: _isFavorited('定数分布'),
          onToggleFavorite: () => _toggleFavorite('定数分布'),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _open(context, const DifficultyDistributionPage());
          },
        ),
      ],
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusCard,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _open(context, const SongSearchPage()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 20, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.hubLibrarySearchHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: context.l10n.hubMoreActionsTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: () => _showSearchGroupSheet(context),
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              LinkPill(
                label: context.featureText('乐曲查询'),
                onTap: () => _open(context, const SongSearchPage()),
              ),
              LinkPill(
                label: context.featureText('非国服乐曲查询'),
                onTap: () =>
                    _open(context, const SongSearchPage(extraOnly: true)),
              ),
              LinkPill(
                label: context.featureText('自定义标签'),
                onTap: () => _open(context, const CustomTagsPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) => HubPageScaffold(
          title: '曲库',
          subtitle: '搜索乐曲、浏览资料与图像识别',
          icon: Icons.library_music_rounded,
          showHeader: widget.showHeader,
          hero: _buildSearchCard(context),
          children: [
            HubSection(
              title: '图鉴与资料',
              subtitle: '更新日历、收藏品与定数分析',
              icon: Icons.library_books_outlined,
              children: [
                HubActionTile(
                  title: '更新日历',
                  subtitle: '按日期查看国服每次更新的谱面',
                  icon: Icons.calendar_month_rounded,
                  isFavorited: _isFavorited('更新日历'),
                  onToggleFavorite: () => _toggleFavorite('更新日历'),
                  onTap: () => _open(context, const UpdateCalendarPage()),
                ),
                HubActionTile(
                  title: '收藏品查询',
                  subtitle: '查看头像、姓名框等收藏品',
                  icon: Icons.collections_bookmark_outlined,
                  isFavorited: _isFavorited('收藏品查询'),
                  onToggleFavorite: () => _toggleFavorite('收藏品查询'),
                  onTap: () => _open(context, const CollectionSearchPage()),
                ),
                HubActionTile(
                  title: '版本与定数分析',
                  subtitle: '国服更新对照 · 版本对照 · 定数分布',
                  icon: Icons.library_books_outlined,
                  onTap: () => _showVersionAndConstantSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            HubSection(
              title: '图像识别',
              subtitle: '通过曲绘找歌，识别结算成绩',
              icon: Icons.image_search_outlined,
              children: [
                HubActionTile(
                  title: '曲绘识别',
                  subtitle: '用相机或图片快速找歌',
                  icon: Icons.image_search_outlined,
                  isFavorited: _isFavorited('曲绘识别'),
                  onToggleFavorite: () => _toggleFavorite('曲绘识别'),
                  onTap: _openCoverRecognition,
                  loading: _coverIndexBuilding,
                  loadingText: _coverIndexBuilding ? '正在构建曲绘索引…' : null,
                  progressCurrent:
                      _coverIndexBuilding ? _coverProgressCurrent : null,
                  progressTotal:
                      _coverIndexBuilding ? _coverProgressTotal : null,
                ),
                HubActionTile(
                  title: '结算画面识别',
                  subtitle: '拍摄结算画面，自动识别成绩',
                  icon: Icons.document_scanner_outlined,
                  isFavorited: _isFavorited('结算画面识别'),
                  onToggleFavorite: () => _toggleFavorite('结算画面识别'),
                  onTap: () => _open(context, const ScoreOcrPage()),
                ),
              ],
            ),
          ],
        ),
      );
}
