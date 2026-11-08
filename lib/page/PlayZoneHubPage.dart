import '../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/NavigationPreferences.dart';
import '../widgets/AppUi.dart';
import '../widgets/MainNavigationViewport.dart';
import 'AttendanceHubPage.dart';
import 'HubComponents.dart';
import 'PlayHubPage.dart';

/// 主导航「游玩」：合并原来的「出勤」与「休闲」两个 Hub（2026-11 导航 6 → 5）。
///
/// 两个 Hub 的内容、收藏键和 [FeatureRegistry] 分类都**原样保留**，只是放进同一个
/// 标签页，用页头下方的分段切换来回切。页头固定在外层，切换时只有内容区过渡，转场
/// 和主导航共用 [MainNavigationViewport]。两边各自保留滚动位置，
/// 上次停留的是哪一边会记住，下次打开 App 直接回到那里。
class PlayZoneHubPage extends StatefulWidget {
  const PlayZoneHubPage({super.key});

  @override
  State<PlayZoneHubPage> createState() => PlayZoneHubPageState();
}

class PlayZoneHubPageState extends State<PlayZoneHubPage> {
  static const String _prefKey = 'play_zone_hub_section';
  static const String _title = '游玩';

  int _section = 0;

  /// 恢复上次分区时不播转场，否则首次打开这个标签页会看到一次多余的切换。
  bool _userSwitched = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
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

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HubPageTitle(title: _title),
                  const SizedBox(height: 12),
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
                listenable: NavigationPreferences.instance,
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
}
