import '../../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/AppModePreferences.dart';
import '../../utils/FavoriteFeaturesNotifier.dart';
import '../../utils/NavigationPreferences.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/MainNavigationViewport.dart';
import 'AttendanceHubPage.dart';
import 'HubComponents.dart';
import 'PlayHubPage.dart';

/// 主导航「游玩」：合并原来的「出勤」与「休闲」两个 Hub（2026-11 导航 6 → 5）。
///
/// 两个 Hub 的内容、收藏键和 [FeatureRegistry] 分类都**原样保留**：
/// - 常规模式：用页头下方的分段切换在「出勤」「休闲」间来回切，页头固定在外层，
///   切换时只有内容区过渡，转场和主导航共用 [MainNavigationViewport]；两边各自
///   保留滚动位置，上次停留的是哪一边会记住，下次打开 App 直接回到那里。
/// - 简洁模式：隐藏顶部分段切换栏与友链轮播，直接复用两边共享的分组构建方法，
///   将出勤与休闲的功能分组按顺序合并到同一个 [HubPageScaffold] 滚动视图中展示。
class PlayZoneHubPage extends StatefulWidget {
  final bool showHeader;
  final int? initialSection;

  const PlayZoneHubPage({
    super.key,
    this.showHeader = true,
    this.initialSection,
  });

  @override
  State<PlayZoneHubPage> createState() => PlayZoneHubPageState();
}

class PlayZoneHubPageState extends State<PlayZoneHubPage> {
  static const String _prefKey = 'play_zone_hub_section';
  static const String _title = '游玩';
  static const String _subtitle = '选曲出勤、猜歌挑战与音乐谱面播放';

  late int _section = (widget.initialSection ?? 0).clamp(0, 1).toInt();

  /// 恢复上次分区时不播转场，否则首次打开这个标签页会看到一次多余的切换。
  bool _userSwitched = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    if (widget.initialSection != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefKey);
      if (!mounted || saved == null || saved < 0 || saved > 1) return;
      setState(() => _section = saved);
    } catch (_) {
      // 读不到就停在「出勤」，不影响使用。
    }
  }

  /// 切到指定分区：0 = 出勤，1 = 休闲。首页「去玩点别的」等入口会调用它。
  ///
  /// 简洁模式下两分区已合并展示，仍安全更新内部状态并落盘，切回常规模式时保持一致。
  void showSection(int section) {
    final next = section.clamp(0, 1).toInt();
    if (next == _section) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _section = next;
      _userSwitched = true;
    });
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_prefKey, next))
        .catchError((Object _) => false);
  }

  /// 简洁模式合并视图：单个滚动容器直接串联出勤与休闲的共享分组，避免双层滚动与重复安全区。
  Widget _buildSimpleMode() {
    return ValueListenableBuilder<FavoritesPayload>(
      valueListenable: FavoriteFeaturesNotifier.instance,
      builder: (context, payload, _) => HubPageScaffold(
        title: _title,
        subtitle: _subtitle,
        showHeader: widget.showHeader,
        icon: Icons.sports_esports_rounded,
        children: [
          ...buildAttendanceHubSections(context),
          const SizedBox(height: 24),
          ...buildPlayHubSections(context),
        ],
      ),
    );
  }

  /// 常规模式分页视图：保留顶部固定页头、分段切换与两页独立滚动状态。
  Widget _buildStandardMode(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                widget.showHeader ? 16 : 8,
                16,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.showHeader) ...[
                    const HubPageTitle(title: _title),
                    const SizedBox(height: 12),
                  ],
                  SegmentedTabs(
                    height: 44,
                    items: [
                      SegmentedTabItem(context.featureText('出勤')),
                      SegmentedTabItem(context.featureText('休闲')),
                    ],
                    selectedIndex: _section,
                    onChanged: showSection,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            // 顶部安全区已由页头占用，内容区不能再让一次。
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListenableBuilder(
                listenable:
                    NavigationPreferences.instance.transitionEnabledListenable,
                builder: (context, _) => MainNavigationViewport(
                  pages: const [
                    AttendanceHubPage(title: _title, showHeader: false),
                    PlayHubPage(title: _title, showHeader: false),
                  ],
                  index: _section,
                  transitionEnabled: _userSwitched &&
                      !reduceMotion &&
                      NavigationPreferences.instance.transitionEnabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppModeScope.isSimpleOf(context)) {
      return _buildSimpleMode();
    }
    return _buildStandardMode(context);
  }
}
