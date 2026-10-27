import 'package:flutter/material.dart';
import '../page/HubComponents.dart';

/// 猜歌枢纽的设置功能区，沿用其它功能区的主题底色与间距。
class GuessSettingsHubSection extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const GuessSettingsHubSection({
    super.key,
    required this.isFavorited,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => HubSection(
        title: '单人游戏设置',
        subtitle: '统一管理各模式的规则与偏好',
        icon: Icons.tune_rounded,
        children: [
          HubActionTile(
            title: '单人猜歌游戏设置',
            subtitle: '共用规则与各模式的专属设置',
            icon: Icons.settings_outlined,
            isFavorited: isFavorited,
            onToggleFavorite: onToggleFavorite,
            onTap: onTap,
          ),
        ],
      );
}
