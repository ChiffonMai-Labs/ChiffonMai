import '../../l10n/LocalizationsExtension.dart';
import '../../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../../utils/AppModePreferences.dart';
import '../../utils/FavoriteFeaturesNotifier.dart';
import '../../utils/ExternalLaunchUtil.dart';
import '../Recommend/DailyRecommendPage.dart';
import '../Recommend/RandomChartPage.dart';
import '../Attendance/AttendanceWheelPage.dart';
import '../Recommend/GainRecommendPage.dart';
import '../Recommend/RecommendByTagsPage.dart';
import '../Recommend/RatingRecommendPage.dart';
import '../Recommend/DsRangeRecommendPage.dart';
import '../Attendance/FavoriteFolderPage.dart';
import '../Attendance/NextPlayQueuePage.dart';
import '../Attendance/GlobalArcadeMapPage.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/FriendLinkUi.dart';

void _openAttendancePage(BuildContext context, Widget page) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

bool _isAttendanceFavorited(String title) =>
    FavoriteFeaturesNotifier.titles.contains(title);

Future<void> _toggleAttendanceFavorite(String title) =>
    FavoriteFeaturesNotifier.toggle(title);

Future<void> _launchAttendanceExternal(
  BuildContext context,
  String url,
  String fallbackHint,
) async {
  final uri = Uri.parse(url);
  try {
    if (await ExternalLaunchUtil.open(uri)) {
      return;
    } else if (context.mounted) {
      AppToast.show(
        context.l10n.hubLinkUnavailable(context.featureText(fallbackHint)),
        tone: AppToastTone.error,
      );
    }
  } catch (e) {
    if (context.mounted) {
      AppToast.show(
        context.l10n.hubOpenFailed(e.toString()),
        tone: AppToastTone.error,
      );
    }
  }
}

void _showMapsSheet(BuildContext context) {
  showHubGroupSheet(
    context,
    title: '机厅地图',
    subtitle: '查找国内与全球音游机厅',
    itemsBuilder: (sheetContext) => [
      HubActionTile(
        title: '全国音游地图',
        subtitle: '看看附近有哪些机厅与音游',
        icon: Icons.map_rounded,
        isFavorited: _isAttendanceFavorited('全国音游地图'),
        onToggleFavorite: () => _toggleAttendanceFavorite('全国音游地图'),
        onTap: () {
          Navigator.of(sheetContext).pop();
          _launchAttendanceExternal(
            context,
            'https://map.bemanicn.com/',
            '全国音游地图',
          );
        },
      ),
      HubActionTile(
        title: '全球音游街机地图',
        subtitle: '查看 NearCade 全球街机店铺',
        icon: Icons.public_rounded,
        isFavorited: _isAttendanceFavorited('全球音游街机地图'),
        onToggleFavorite: () => _toggleAttendanceFavorite('全球音游街机地图'),
        onTap: () {
          Navigator.of(sheetContext).pop();
          _openAttendancePage(context, const GlobalArcadeMapPage());
        },
      ),
    ],
  );
}

void _openMorePicksPage(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => HubSubPage(
        title: '选曲与推荐',
        builder: (pageContext) => [
          HubSection(
            title: '随机选曲',
            subtitle: '决定今天玩什么',
            icon: Icons.shuffle_rounded,
            children: [
              HubActionTile(
                title: '随机乐曲',
                subtitle: '自定义数量随机抽取歌曲',
                icon: Icons.shuffle_rounded,
                isFavorited: _isAttendanceFavorited('随机乐曲'),
                onToggleFavorite: () => _toggleAttendanceFavorite('随机乐曲'),
                onTap: () =>
                    _openAttendancePage(pageContext, const RandomChartPage()),
              ),
              HubActionTile(
                title: '出勤转盘',
                subtitle: '等分转盘决定本次出勤选项',
                icon: Icons.casino_outlined,
                isFavorited: _isAttendanceFavorited('出勤转盘'),
                onToggleFavorite: () => _toggleAttendanceFavorite('出勤转盘'),
                onTap: () => _openAttendancePage(
                    pageContext, const AttendanceWheelPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          HubSection(
            title: '练习推荐',
            subtitle: '围绕收益、标签、目标与定数挑谱',
            icon: Icons.trending_up_rounded,
            children: [
              HubActionTile(
                title: '基于标签推荐',
                subtitle: '基于你的游玩谱面标签推荐曲目',
                icon: Icons.label_outline_rounded,
                isFavorited: _isAttendanceFavorited('基于标签推荐'),
                onToggleFavorite: () => _toggleAttendanceFavorite('基于标签推荐'),
                onTap: () =>
                    _openAttendancePage(pageContext, const RecommendByTags()),
              ),
              HubActionTile(
                title: '基于目标 Rating 推荐',
                subtitle: '寻找适合上分的谱面',
                icon: Icons.trending_up_rounded,
                isFavorited: _isAttendanceFavorited('基于目标 Rating 推荐'),
                onToggleFavorite: () =>
                    _toggleAttendanceFavorite('基于目标 Rating 推荐'),
                onTap: () => _openAttendancePage(
                    pageContext, const RatingRecommendPage()),
              ),
              HubActionTile(
                title: '基于定数区间推荐',
                subtitle: '按定数范围挑选谱面',
                icon: Icons.tune_rounded,
                isFavorited: _isAttendanceFavorited('基于定数区间推荐'),
                onToggleFavorite: () => _toggleAttendanceFavorite('基于定数区间推荐'),
                onTap: () => _openAttendancePage(
                    pageContext, const DsRangeRecommendPage()),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// 构建「出勤」分区的功能分组列表，供常规模式 [AttendanceHubPage] 与简洁模式
/// 合并后的「游玩」页共同复用。
///
/// 返回的列表包含「出勤常用」与「选曲与推荐」两组（不含 [FriendLinkCarousel]），
/// 组间已以 `SizedBox(height: 24)` 分隔；调用方需在监听
/// [FavoriteFeaturesNotifier.instance] 的上下文中调用，以确保星标状态实时同步。
List<Widget> buildAttendanceHubSections(BuildContext context) {
  return [
    HubSection(
      title: '出勤常用',
      subtitle: '收藏谱面、待玩清单与机厅地图',
      icon: Icons.queue_music_rounded,
      children: [
        HubActionTile(
          title: '收藏夹',
          subtitle: '管理你收藏的谱面',
          icon: Icons.favorite_outline_rounded,
          isFavorited: _isAttendanceFavorited('收藏夹'),
          onToggleFavorite: () => _toggleAttendanceFavorite('收藏夹'),
          onTap: () =>
              _openAttendancePage(context, const FavoriteFolderPage()),
        ),
        HubActionTile(
          title: '下次想玩',
          subtitle: '排好下次出勤想玩的歌曲',
          icon: Icons.queue_music,
          isFavorited: _isAttendanceFavorited('下次想玩'),
          onToggleFavorite: () => _toggleAttendanceFavorite('下次想玩'),
          onTap: () => _openAttendancePage(context, const NextPlayQueuePage()),
        ),
        HubActionTile(
          title: '机厅地图',
          subtitle: '全国音游地图 · 全球音游街机地图',
          icon: Icons.map_outlined,
          onTap: () => _showMapsSheet(context),
        ),
      ],
    ),
    const SizedBox(height: 24),
    HubSection(
      title: '选曲与推荐',
      subtitle: '每日推荐、吃分与定向挑谱',
      icon: Icons.trending_up_rounded,
      children: [
        HubActionTile(
          title: '每日推荐',
          subtitle: '今天打什么？交给推荐',
          icon: Icons.today_rounded,
          isFavorited: _isAttendanceFavorited('每日推荐'),
          onToggleFavorite: () => _toggleAttendanceFavorite('每日推荐'),
          onTap: () =>
              _openAttendancePage(context, const DailyRecommendPage()),
        ),
        HubActionTile(
          title: '吃分推荐',
          subtitle: '按 B50 净收益挑谱 · AWMC 提供算法支持',
          icon: Icons.rocket_launch_rounded,
          isFavorited: _isAttendanceFavorited('吃分推荐'),
          onToggleFavorite: () => _toggleAttendanceFavorite('吃分推荐'),
          onTap: () => _openAttendancePage(context, const GainRecommendPage()),
        ),
        HubActionTile(
          title: '更多选曲与推荐',
          subtitle: '随机乐曲 · 出勤转盘 · 标签 / 目标 Rating / 定数区间',
          icon: Icons.auto_awesome_outlined,
          onTap: () => _openMorePicksPage(context),
        ),
      ],
    ),
  ];
}

class AttendanceHubPage extends StatefulWidget {
  final String title;
  final String subtitle;

  /// 嵌在「游玩」页里时为 false，页头由外层固定显示（见 PlayZoneHubPage）。
  final bool showHeader;

  const AttendanceHubPage({
    super.key,
    this.title = '出勤',
    this.subtitle = '选曲、安排练习与查找机厅',
    this.showHeader = true,
  });
  @override
  State<AttendanceHubPage> createState() => _AttendanceHubPageState();
}

class _AttendanceHubPageState extends State<AttendanceHubPage> {
  @override
  Widget build(BuildContext context) {
    final isSimple = AppModeScope.isSimpleOf(context);
    return ValueListenableBuilder<FavoritesPayload>(
      valueListenable: FavoriteFeaturesNotifier.instance,
      builder: (context, payload, _) => HubPageScaffold(
        title: widget.title,
        subtitle: widget.subtitle,
        showHeader: widget.showHeader,
        icon: Icons.explore_rounded,
        children: [
          ...buildAttendanceHubSections(context),
          if (!isSimple) ...[
            const SizedBox(height: 24),
            const FriendLinkCarousel(),
          ],
        ],
      ),
    );
  }
}
