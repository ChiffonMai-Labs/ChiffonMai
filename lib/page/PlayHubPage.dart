import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/FeatureRegistry.dart';
import '../service/GuessChartGame/GuessAudioService.dart';
import '../widgets/GuessSettingsHubSection.dart';
import 'GuessChartGame/GuessGameSettingsPage.dart';
import 'GuessChartGame/GuessChartByInfoPage.dart';
import 'GuessChartGame/GuessChartByAliaPage.dart';
import 'GuessChartGame/GuessChartByCoverPage.dart';
import 'GuessChartGame/GuessChartByBlurredCoverPage.dart';
import 'GuessChartGame/GuessChartBySongExcerptPage.dart';
import 'GuessChartGame/GuessSongByOpenLettersPage.dart';
import 'GuessChartGame/GuessChartByFlashCoverPage.dart';
import 'GuessChartGame/GuessChartByTileRevealPage.dart';
import 'GuessChartGame/GuessChartByChartPeekPage.dart';
import 'Multiplayer/MultiplayerLobbyPage.dart';
import 'Portable/PortablePlayerPage.dart';
import 'PersonalizedChartPlayConfigure.dart';

class PlayHubPage extends StatefulWidget {
  const PlayHubPage({super.key});
  @override
  State<PlayHubPage> createState() => _PlayHubPageState();
}

class _PlayHubPageState extends State<PlayHubPage> {
  void _open(BuildContext context, Widget page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  bool _isFavorited(String title) =>
      FavoriteFeaturesNotifier.titles.contains(title);

  Future<void> _toggleFavorite(String title) =>
      FavoriteFeaturesNotifier.toggle(title);

  Future<void> _openPortablePlayer(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PortablePlayerPage()));
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) {
          final features = <String, Widget>{
            '单人猜歌游戏设置': GuessSettingsHubSection(
                isFavorited: _isFavorited('单人猜歌游戏设置'),
                onToggleFavorite: () => _toggleFavorite('单人猜歌游戏设置'),
                onTap: () => _open(context, const GuessGameSettingsPage())),
            '无提示猜歌': HubActionTile(
              title: '无提示猜歌',
              subtitle: '凭记忆挑战曲库',
              icon: Icons.visibility_off_outlined,
              isFavorited: _isFavorited('无提示猜歌'),
              onToggleFavorite: () => _toggleFavorite('无提示猜歌'),
              onTap: () => _open(context, const GuessChartByInfoPage()),
            ),
            '根据别名猜歌': HubActionTile(
              title: '根据别名猜歌',
              subtitle: '用别名挑战你的熟悉度',
              icon: Icons.abc_rounded,
              isFavorited: _isFavorited('根据别名猜歌'),
              onToggleFavorite: () => _toggleFavorite('根据别名猜歌'),
              onTap: () => _open(context, const GuessChartByAliaPage()),
            ),
            '舞萌开字母': HubActionTile(
              title: '舞萌开字母',
              subtitle: '看首字母猜歌',
              icon: Icons.text_fields_outlined,
              isFavorited: _isFavorited('舞萌开字母'),
              onToggleFavorite: () => _toggleFavorite('舞萌开字母'),
              onTap: () => _open(context, const GuessSongByOpenLettersPage()),
            ),
            '根据部分曲绘猜歌': HubActionTile(
              title: '根据部分曲绘猜歌',
              subtitle: '看一小块曲绘猜出歌曲',
              icon: Icons.image_outlined,
              isFavorited: _isFavorited('根据部分曲绘猜歌'),
              onToggleFavorite: () => _toggleFavorite('根据部分曲绘猜歌'),
              onTap: () => _open(context, const GuessChartByCoverPage()),
            ),
            '根据模糊曲绘猜歌': HubActionTile(
              title: '根据模糊曲绘猜歌',
              subtitle: '根据模糊化处理后的曲绘猜歌',
              icon: Icons.blur_on_outlined,
              isFavorited: _isFavorited('根据模糊曲绘猜歌'),
              onToggleFavorite: () => _toggleFavorite('根据模糊曲绘猜歌'),
              onTap: () => _open(context, const GuessChartByBlurredCoverPage()),
            ),
            '曲绘快闪猜歌': HubActionTile(
              title: '曲绘快闪猜歌',
              subtitle: '曲绘一闪而过，凭记忆猜歌',
              icon: Icons.flash_on_outlined,
              isFavorited: _isFavorited('曲绘快闪猜歌'),
              onToggleFavorite: () => _toggleFavorite('曲绘快闪猜歌'),
              onTap: () => _open(context, const GuessChartByFlashCoverPage()),
            ),
            '曲绘拼图猜歌': HubActionTile(
              title: '曲绘拼图猜歌',
              subtitle: '曲绘碎块随时间逐步拼合显现',
              icon: Icons.grid_on_outlined,
              isFavorited: _isFavorited('曲绘拼图猜歌'),
              onToggleFavorite: () => _toggleFavorite('曲绘拼图猜歌'),
              onTap: () => _open(context, const GuessChartByTileRevealPage()),
            ),
            '根据歌曲片段猜歌': HubActionTile(
              title: '根据歌曲片段猜歌',
              subtitle: '截取音源片段猜歌',
              icon: Icons.music_note_outlined,
              isFavorited: _isFavorited('根据歌曲片段猜歌'),
              onToggleFavorite: () => _toggleFavorite('根据歌曲片段猜歌'),
              onTap: () => _open(context, const GuessChartBySongExcerptPage()),
            ),
            '倒放音频猜歌': HubActionTile(
              title: '倒放音频猜歌',
              subtitle: '听倒放的歌曲片段，挑战旋律记忆',
              icon: Icons.fast_rewind_rounded,
              isFavorited: _isFavorited('倒放音频猜歌'),
              onToggleFavorite: () => _toggleFavorite('倒放音频猜歌'),
              onTap: () => _open(
                  context,
                  const GuessChartBySongExcerptPage(
                      mode: GuessAudioMode.reverseAudio)),
            ),
            '变速变调猜歌': HubActionTile(
              title: '变速变调猜歌',
              subtitle: '速度与音高一起变化，换个耳朵听歌',
              icon: Icons.speed_rounded,
              isFavorited: _isFavorited('变速变调猜歌'),
              onToggleFavorite: () => _toggleFavorite('变速变调猜歌'),
              onTap: () => _open(
                  context,
                  const GuessChartBySongExcerptPage(
                      mode: GuessAudioMode.pitchAudio)),
            ),
            '谱面片段猜歌': HubActionTile(
              title: '谱面片段猜歌',
              subtitle: '看一段无声谱面动画猜出歌曲',
              icon: Icons.graphic_eq_outlined,
              isFavorited: _isFavorited('谱面片段猜歌'),
              onToggleFavorite: () => _toggleFavorite('谱面片段猜歌'),
              onTap: () => _open(context, const GuessChartByChartPeekPage()),
            ),
            '多人猜歌游戏': HubActionTile(
              title: '多人猜歌游戏',
              subtitle: '和朋友一起猜舞萌曲库',
              icon: Icons.groups_rounded,
              isFavorited: _isFavorited('多人猜歌游戏'),
              onToggleFavorite: () => _toggleFavorite('多人猜歌游戏'),
              onTap: () => _open(context, const MultiplayerLobbyPage()),
            ),
            '随身听': HubActionTile(
              title: '随身听',
              subtitle: '后台播放舞萌曲库，带通知栏播放器',
              icon: Icons.headphones_rounded,
              isFavorited: _isFavorited('随身听'),
              onToggleFavorite: () => _toggleFavorite('随身听'),
              onTap: () => _openPortablePlayer(context),
            ),
            '自定义谱面播放': HubActionTile(
              title: '自定义谱面播放',
              subtitle: '播放本地自定义谱面',
              icon: Icons.play_circle_outline_rounded,
              isFavorited: _isFavorited('自定义谱面播放'),
              onToggleFavorite: () => _toggleFavorite('自定义谱面播放'),
              onTap: () =>
                  _open(context, const PersonalizedChartPlayConfigure()),
            ),
          };

          final sections = FeatureRegistry.sections['休闲']!;
          return HubPageScaffold(
            title: '休闲',
            subtitle: '猜歌挑战、听歌与自定义谱面播放',
            icon: Icons.sports_esports_rounded,
            children: [
              for (final section in sections) ...[
                if (section.title == '单人游戏设置')
                  features['单人猜歌游戏设置']!
                else
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
