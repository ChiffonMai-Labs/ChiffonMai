import 'package:flutter/material.dart';
import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import 'GuessChartGame/LocalSongQuizPage.dart';
import 'HubComponents.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../service/GuessChartGame/GuessAudioService.dart';
import '../widgets/AppUi.dart';
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
  final String title;
  final String subtitle;

  /// 嵌在「游玩」页里时为 false，页头由外层固定显示（见 PlayZoneHubPage）。
  final bool showHeader;

  const PlayHubPage({
    super.key,
    this.title = '休闲',
    this.subtitle = '猜歌挑战、听歌与自定义谱面播放',
    this.showHeader = true,
  });
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

  void _openSoloGuessPage(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HubSubPage(
          title: '单人猜歌',
          actions: [
            Builder(
              builder: (headerContext) => IconButton(
                tooltip: headerContext.featureText('单人猜歌游戏设置'),
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    _open(headerContext, const GuessGameSettingsPage()),
              ),
            ),
          ],
          builder: (pageContext) => [
            HubSection(
              title: '文字线索',
              subtitle: '凭记忆、别名与字母线索猜歌',
              icon: Icons.text_fields_rounded,
              children: [
                HubActionTile(
                  title: '无提示猜歌',
                  subtitle: '凭记忆挑战曲库',
                  icon: Icons.visibility_off_outlined,
                  isFavorited: _isFavorited('无提示猜歌'),
                  onToggleFavorite: () => _toggleFavorite('无提示猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartByInfoPage()),
                ),
                HubActionTile(
                  title: '根据别名猜歌',
                  subtitle: '用别名挑战你的熟悉度',
                  icon: Icons.abc_rounded,
                  isFavorited: _isFavorited('根据别名猜歌'),
                  onToggleFavorite: () => _toggleFavorite('根据别名猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartByAliaPage()),
                ),
                HubActionTile(
                  title: '舞萌开字母',
                  subtitle: '看首字母猜歌',
                  icon: Icons.text_fields_outlined,
                  isFavorited: _isFavorited('舞萌开字母'),
                  onToggleFavorite: () => _toggleFavorite('舞萌开字母'),
                  onTap: () =>
                      _open(pageContext, const GuessSongByOpenLettersPage()),
                ),
                HubActionTile(
                  title: '离线挑战',
                  subtitle: '极限二选一 · 规则版 20 问',
                  icon: Icons.quiz_outlined,
                  isFavorited: _isFavorited('离线挑战'),
                  onToggleFavorite: () => _toggleFavorite('离线挑战'),
                  onTap: () => _open(pageContext, const LocalSongQuizPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            HubSection(
              title: '曲绘辨识',
              subtitle: '观察局部、像素、模糊、快闪与拼图曲绘',
              icon: Icons.image_outlined,
              children: [
                HubActionTile(
                  title: '根据部分曲绘猜歌',
                  subtitle: '看一小块曲绘猜出歌曲',
                  icon: Icons.image_outlined,
                  isFavorited: _isFavorited('根据部分曲绘猜歌'),
                  onToggleFavorite: () => _toggleFavorite('根据部分曲绘猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartByCoverPage()),
                ),
                HubActionTile(
                  title: '像素曲绘猜歌',
                  subtitle: '根据像素马赛克的色块与轮廓猜歌',
                  icon: Icons.grid_view_rounded,
                  isFavorited: _isFavorited('像素曲绘猜歌'),
                  onToggleFavorite: () => _toggleFavorite('像素曲绘猜歌'),
                  onTap: () => _open(pageContext,
                      const GuessChartByBlurredCoverPage(pixelated: true)),
                ),
                HubActionTile(
                  title: '根据模糊曲绘猜歌',
                  subtitle: '根据模糊化处理后的曲绘猜歌',
                  icon: Icons.blur_on_outlined,
                  isFavorited: _isFavorited('根据模糊曲绘猜歌'),
                  onToggleFavorite: () => _toggleFavorite('根据模糊曲绘猜歌'),
                  onTap: () => _open(
                      pageContext, const GuessChartByBlurredCoverPage()),
                ),
                HubActionTile(
                  title: '曲绘快闪猜歌',
                  subtitle: '曲绘一闪而过，凭记忆猜歌',
                  icon: Icons.flash_on_outlined,
                  isFavorited: _isFavorited('曲绘快闪猜歌'),
                  onToggleFavorite: () => _toggleFavorite('曲绘快闪猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartByFlashCoverPage()),
                ),
                HubActionTile(
                  title: '曲绘拼图猜歌',
                  subtitle: '曲绘碎块随时间逐步拼合显现',
                  icon: Icons.grid_on_outlined,
                  isFavorited: _isFavorited('曲绘拼图猜歌'),
                  onToggleFavorite: () => _toggleFavorite('曲绘拼图猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartByTileRevealPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            HubSection(
              title: '音频辨识',
              subtitle: '通过原速、倒放或变调片段辨认歌曲',
              icon: Icons.headphones_outlined,
              children: [
                HubActionTile(
                  title: '根据歌曲片段猜歌',
                  subtitle: '截取音源片段猜歌',
                  icon: Icons.music_note_outlined,
                  isFavorited: _isFavorited('根据歌曲片段猜歌'),
                  onToggleFavorite: () => _toggleFavorite('根据歌曲片段猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartBySongExcerptPage()),
                ),
                HubActionTile(
                  title: '倒放音频猜歌',
                  subtitle: '听倒放的歌曲片段，挑战旋律记忆',
                  icon: Icons.fast_rewind_rounded,
                  isFavorited: _isFavorited('倒放音频猜歌'),
                  onToggleFavorite: () => _toggleFavorite('倒放音频猜歌'),
                  onTap: () => _open(
                    pageContext,
                    const GuessChartBySongExcerptPage(
                        mode: GuessAudioMode.reverseAudio),
                  ),
                ),
                HubActionTile(
                  title: '变速变调猜歌',
                  subtitle: '速度与音高一起变化，换个耳朵听歌',
                  icon: Icons.speed_rounded,
                  isFavorited: _isFavorited('变速变调猜歌'),
                  onToggleFavorite: () => _toggleFavorite('变速变调猜歌'),
                  onTap: () => _open(
                    pageContext,
                    const GuessChartBySongExcerptPage(
                        mode: GuessAudioMode.pitchAudio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            HubSection(
              title: '谱面辨识',
              subtitle: '根据无声谱面片段猜歌',
              icon: Icons.graphic_eq_rounded,
              children: [
                HubActionTile(
                  title: '谱面片段猜歌',
                  subtitle: '看一段无声谱面动画猜出歌曲',
                  icon: Icons.graphic_eq_outlined,
                  isFavorited: _isFavorited('谱面片段猜歌'),
                  onToggleFavorite: () => _toggleFavorite('谱面片段猜歌'),
                  onTap: () =>
                      _open(pageContext, const GuessChartByChartPeekPage()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) => HubPageScaffold(
            title: widget.title,
            subtitle: widget.subtitle,
            showHeader: widget.showHeader,
            icon: Icons.sports_esports_rounded,
            children: [
              HubSection(
                title: '音乐与谱面播放',
                subtitle: '听舞萌歌曲，播放自定义谱面',
                icon: Icons.play_circle_outline_rounded,
                children: [
                  HubActionTile(
                    title: '随身听',
                    subtitle: '后台播放舞萌曲库，带通知栏播放器',
                    icon: Icons.headphones_rounded,
                    isFavorited: _isFavorited('随身听'),
                    onToggleFavorite: () => _toggleFavorite('随身听'),
                    onTap: () => _openPortablePlayer(context),
                  ),
                  HubActionTile(
                    title: '自定义谱面播放',
                    subtitle: '播放本地自定义谱面',
                    icon: Icons.play_circle_outline_rounded,
                    isFavorited: _isFavorited('自定义谱面播放'),
                    onToggleFavorite: () => _toggleFavorite('自定义谱面播放'),
                    onTap: () =>
                        _open(context, const PersonalizedChartPlayConfigure()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              HubSection(
                title: '猜歌挑战',
                subtitle: '单人模式、多人联机与游戏设置',
                icon: Icons.quiz_outlined,
                children: [
                  HubActionTile(
                    title: '单人猜歌',
                    subtitle: '文字 · 曲绘 · 音频 · 谱面，共 13 种玩法',
                    icon: Icons.quiz_outlined,
                    onTap: () => _openSoloGuessPage(context),
                    footer: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        LinkPill(
                          label: context.l10n.hubPillNoClue,
                          onTap: () =>
                              _open(context, const GuessChartByInfoPage()),
                        ),
                        LinkPill(
                          label: context.l10n.hubPillPartialCover,
                          onTap: () =>
                              _open(context, const GuessChartByCoverPage()),
                        ),
                        LinkPill(
                          label: context.l10n.flowSongExcerpt,
                          onTap: () => _open(
                              context, const GuessChartBySongExcerptPage()),
                        ),
                        LinkPill(
                          label: context.l10n.flowChartExcerpt,
                          onTap: () =>
                              _open(context, const GuessChartByChartPeekPage()),
                        ),
                      ],
                    ),
                  ),
                  HubActionTile(
                    title: '多人猜歌游戏',
                    subtitle: '和朋友一起猜舞萌曲库',
                    icon: Icons.groups_rounded,
                    isFavorited: _isFavorited('多人猜歌游戏'),
                    onToggleFavorite: () => _toggleFavorite('多人猜歌游戏'),
                    onTap: () => _open(context, const MultiplayerLobbyPage()),
                  ),
                  HubActionTile(
                    title: '单人猜歌游戏设置',
                    subtitle: '管理共用规则和各模式设置',
                    icon: Icons.settings_outlined,
                    isFavorited: _isFavorited('单人猜歌游戏设置'),
                    onToggleFavorite: () => _toggleFavorite('单人猜歌游戏设置'),
                    onTap: () => _open(context, const GuessGameSettingsPage()),
                  ),
                ],
              ),
            ],
          ),
      );
}
