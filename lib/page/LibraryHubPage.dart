import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/FeatureRegistry.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../service/CoverRecognitionService.dart';
import 'SongSearchPage.dart';
import 'UnionUpdateComparePage.dart';
import 'Collection/CollectionSearchPage.dart';
import 'VersionViewPage.dart';
import 'DifficultyDistributionPage.dart';
import 'CoverRecognitionPage.dart';
import 'ScoreOcrPage.dart';

class LibraryHubPage extends StatefulWidget {
  const LibraryHubPage({super.key});
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
          Fluttertoast.showToast(msg: '曲绘索引构建失败: $e');
        }
        return;
      }
    }
    if (!mounted) return;
    _open(context, const CoverRecognitionPage());
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) {
          final features = <String, Widget>{
            '乐曲查询': HubActionTile(
              title: '乐曲查询',
              subtitle: '按歌名、别名、谱师和标签搜索',
              icon: Icons.search_rounded,
              isFavorited: _isFavorited('乐曲查询'),
              onToggleFavorite: () => _toggleFavorite('乐曲查询'),
              onTap: () => _open(context, const SongSearchPage()),
            ),
            '非国服乐曲查询': HubActionTile(
              title: '非国服乐曲查询',
              subtitle: '搜索与筛选非国服曲库',
              icon: Icons.travel_explore_rounded,
              isFavorited: _isFavorited('非国服乐曲查询'),
              onToggleFavorite: () => _toggleFavorite('非国服乐曲查询'),
              onTap: () =>
                  _open(context, const SongSearchPage(extraOnly: true)),
            ),
            '国服更新对照': HubActionTile(
              title: '国服更新对照',
              subtitle: '看日服已上、国服还没上的曲目',
              icon: Icons.flag_rounded,
              isFavorited: _isFavorited('国服更新对照'),
              onToggleFavorite: () => _toggleFavorite('国服更新对照'),
              onTap: () => _open(context, const UnionUpdateComparePage()),
            ),
            '版本对照': HubActionTile(
              title: '版本对照',
              subtitle: '按版本整理可游玩曲目',
              icon: Icons.compare_arrows_rounded,
              isFavorited: _isFavorited('版本对照'),
              onToggleFavorite: () => _toggleFavorite('版本对照'),
              onTap: () => _open(context, VersionView()),
            ),
            '定数分布': HubActionTile(
              title: '定数分布',
              subtitle: '查看谱面定数分布',
              icon: Icons.bar_chart_rounded,
              isFavorited: _isFavorited('定数分布'),
              onToggleFavorite: () => _toggleFavorite('定数分布'),
              onTap: () => _open(context, const DifficultyDistributionPage()),
            ),
            '曲绘识别': HubActionTile(
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
              progressTotal: _coverIndexBuilding ? _coverProgressTotal : null,
            ),
            '结算画面识别': HubActionTile(
              title: '结算画面识别',
              subtitle: '拍摄机台结算画面，自动识别成绩',
              icon: Icons.document_scanner_outlined,
              isFavorited: _isFavorited('结算画面识别'),
              onToggleFavorite: () => _toggleFavorite('结算画面识别'),
              onTap: () => _open(context, const ScoreOcrPage()),
            ),
            '收藏品查询': HubActionTile(
              title: '收藏品查询',
              subtitle: '查看头像、姓名框等收藏品',
              icon: Icons.collections_bookmark_outlined,
              isFavorited: _isFavorited('收藏品查询'),
              onToggleFavorite: () => _toggleFavorite('收藏品查询'),
              onTap: () => _open(context, const CollectionSearchPage()),
            ),
          };

          final sections = FeatureRegistry.sections['曲库']!;
          return HubPageScaffold(
            title: '曲库',
            subtitle: '搜索乐曲、浏览资料与图像识别',
            icon: Icons.library_music_rounded,
            children: [
              for (final section in sections) ...[
                HubSection(
                  title: section.title,
                  subtitle: section.subtitle,
                  icon: section.icon,
                  badgeCount: section.titles.length,
                  children: [
                    for (final title in section.titles) features[title]!
                  ],
                ),
                if (section != sections.last) const SizedBox(height: 24),
              ],
            ],
          );
        },
      );
}
