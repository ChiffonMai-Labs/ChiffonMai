import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/FeatureRegistry.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'DailyRecommendPage.dart';
import 'RandomChartPage.dart';
import 'AttendanceWheelPage.dart';
import 'GainRecommendPage.dart';
import 'RecommendByTagsPage.dart';
import 'RatingRecommendPage.dart';
import 'DsRangeRecommendPage.dart';
import 'FavoriteFolderPage.dart';
import 'NextPlayQueuePage.dart';
import 'GlobalArcadeMapPage.dart';

class AttendanceHubPage extends StatefulWidget {
  const AttendanceHubPage({super.key});
  @override
  State<AttendanceHubPage> createState() => _AttendanceHubPageState();
}

class _AttendanceHubPageState extends State<AttendanceHubPage> {
  void _open(BuildContext context, Widget page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  bool _isFavorited(String title) =>
      FavoriteFeaturesNotifier.titles.contains(title);

  Future<void> _toggleFavorite(String title) =>
      FavoriteFeaturesNotifier.toggle(title);

  Future<void> _launchExternal(
      BuildContext context, String url, String fallbackHint) async {
    final uri = Uri.parse(url);
    try {
      if (await ExternalLaunchUtil.open(uri)) {
        return;
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接：$fallbackHint')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) {
          final features = <String, Widget>{
            '每日推荐': HubActionTile(
              title: '每日推荐',
              subtitle: '今天打什么？交给推荐',
              icon: Icons.today_rounded,
              isFavorited: _isFavorited('每日推荐'),
              onToggleFavorite: () => _toggleFavorite('每日推荐'),
              onTap: () => _open(context, const DailyRecommendPage()),
            ),
            '随机乐曲': HubActionTile(
              title: '随机乐曲',
              subtitle: '自定义数量随机抽取歌曲',
              icon: Icons.shuffle_rounded,
              isFavorited: _isFavorited('随机乐曲'),
              onToggleFavorite: () => _toggleFavorite('随机乐曲'),
              onTap: () => _open(context, const RandomChartPage()),
            ),
            '出勤转盘': HubActionTile(
              title: '出勤转盘',
              subtitle: '等分转盘决定本次出勤选项',
              icon: Icons.casino_outlined,
              isFavorited: _isFavorited('出勤转盘'),
              onToggleFavorite: () => _toggleFavorite('出勤转盘'),
              onTap: () => _open(context, const AttendanceWheelPage()),
            ),
            '吃分推荐': HubActionTile(
              title: '吃分推荐',
              subtitle: '按 B50 净收益挑谱 · AWMC 提供算法支持',
              icon: Icons.rocket_launch_rounded,
              isFavorited: _isFavorited('吃分推荐'),
              onToggleFavorite: () => _toggleFavorite('吃分推荐'),
              onTap: () => _open(context, const GainRecommendPage()),
            ),
            '基于标签推荐': HubActionTile(
              title: '基于标签推荐',
              subtitle: '基于你的游玩谱面标签推荐曲目',
              icon: Icons.label_outline_rounded,
              isFavorited: _isFavorited('基于标签推荐'),
              onToggleFavorite: () => _toggleFavorite('基于标签推荐'),
              onTap: () => _open(context, const RecommendByTags()),
            ),
            '基于目标 Rating 推荐': HubActionTile(
              title: '基于目标 Rating 推荐',
              subtitle: '寻找适合上分的谱面',
              icon: Icons.trending_up_rounded,
              isFavorited: _isFavorited('基于目标 Rating 推荐'),
              onToggleFavorite: () => _toggleFavorite('基于目标 Rating 推荐'),
              onTap: () => _open(context, const RatingRecommendPage()),
            ),
            '基于定数区间推荐': HubActionTile(
              title: '基于定数区间推荐',
              subtitle: '按定数范围挑选谱面',
              icon: Icons.tune_rounded,
              isFavorited: _isFavorited('基于定数区间推荐'),
              onToggleFavorite: () => _toggleFavorite('基于定数区间推荐'),
              onTap: () => _open(context, const DsRangeRecommendPage()),
            ),
            '收藏夹': HubActionTile(
              title: '收藏夹',
              subtitle: '管理你收藏的谱面',
              icon: Icons.favorite_outline_rounded,
              isFavorited: _isFavorited('收藏夹'),
              onToggleFavorite: () => _toggleFavorite('收藏夹'),
              onTap: () => _open(context, const FavoriteFolderPage()),
            ),
            '下次想玩': HubActionTile(
              title: '下次想玩',
              subtitle: '排好下次去机台想玩的歌曲',
              icon: Icons.queue_music,
              isFavorited: _isFavorited('下次想玩'),
              onToggleFavorite: () => _toggleFavorite('下次想玩'),
              onTap: () => _open(context, const NextPlayQueuePage()),
            ),
            '全国音游地图': HubActionTile(
              title: '全国音游地图',
              subtitle: '看看哪里有你想玩的机台',
              icon: Icons.map_rounded,
              isFavorited: _isFavorited('全国音游地图'),
              onToggleFavorite: () => _toggleFavorite('全国音游地图'),
              onTap: () => _launchExternal(
                  context, 'https://map.bemanicn.com/', '全国音游地图'),
            ),
            '全球音游街机地图': HubActionTile(
              title: '全球音游街机地图',
              subtitle: '查看 NearCade 全球街机店铺',
              icon: Icons.public_rounded,
              isFavorited: _isFavorited('全球音游街机地图'),
              onToggleFavorite: () => _toggleFavorite('全球音游街机地图'),
              onTap: () => _open(context, const GlobalArcadeMapPage()),
            ),
          };

          final sections = FeatureRegistry.sections['出勤']!;
          return HubPageScaffold(
            title: '出勤',
            subtitle: '选曲、安排练习与查找机厅',
            icon: Icons.explore_rounded,
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
