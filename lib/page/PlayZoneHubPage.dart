import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/AppUi.dart';
import 'AttendanceHubPage.dart';
import 'PlayHubPage.dart';

/// 主导航「游玩」：合并原来的「出勤」与「休闲」两个 Hub（2026-11 导航 6 → 5）。
///
/// 两个 Hub 的内容、收藏键和 [FeatureRegistry] 分类都**原样保留**，只是放进同一个
/// 标签页，用页头下方的分段切换来回切。两边各自保留滚动位置（IndexedStack），
/// 上次停留的是哪一边会记住，下次打开 App 直接回到那里。
class PlayZoneHubPage extends StatefulWidget {
  const PlayZoneHubPage({super.key});

  @override
  State<PlayZoneHubPage> createState() => PlayZoneHubPageState();
}

class PlayZoneHubPageState extends State<PlayZoneHubPage> {
  static const String _prefKey = 'play_zone_hub_section';
  static const String _title = '游玩';
  static const List<String> _subtitles = [
    '选曲、安排练习与查找机厅',
    '猜歌挑战、听歌与自定义谱面播放',
  ];

  int _section = 0;

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
    setState(() => _section = next);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_prefKey, next))
        .catchError((Object _) => false);
  }

  Widget _switcher() => SegmentedTabs(
        height: 44,
        items: const [SegmentedTabItem('出勤'), SegmentedTabItem('休闲')],
        selectedIndex: _section,
        onChanged: showSection,
      );

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _section,
      children: [
        AttendanceHubPage(
          title: _title,
          subtitle: _subtitles[0],
          headerBottom: _switcher(),
        ),
        PlayHubPage(
          title: _title,
          subtitle: _subtitles[1],
          headerBottom: _switcher(),
        ),
      ],
    );
  }
}
