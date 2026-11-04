import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../page/FriendLinksPage.dart';
import '../service/FriendLinksService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'AppUi.dart';
import 'MarqueeText.dart';
import 'ImageLoadingIndicator.dart';

/// 友链可用的图标类型枚举
///
/// 限定友链图标的可选范围，新增友链时从此枚举中选择一个最贴合的类型。
enum FriendLinkIconType {
  /// GitHub 开源项目（仓库 / 工具 / CLI）
  github,

  /// 网页应用 / Web 服务
  web,

  /// App / 移动端应用
  app,

  /// 游戏 / 互动娱乐
  game,

  /// 音乐相关
  music,

  /// 工具 / 计算 / 实用程序
  tool,

  /// 文档 / Wiki / 百科
  docs,

  /// 视频 / 直播 / 流媒体
  video,

  /// 社区 / 论坛 / 群组
  community,
}

FriendLinkIconType friendLinkIconType(String name) =>
    FriendLinkIconType.values.asNameMap()[name] ?? FriendLinkIconType.web;

IconData friendLinkIcon(FriendLinkIconType type) => switch (type) {
      FriendLinkIconType.github => FontAwesomeIcons.github,
      FriendLinkIconType.web => Icons.language,
      FriendLinkIconType.app => Icons.phone_android,
      FriendLinkIconType.game => Icons.sports_esports,
      FriendLinkIconType.music => Icons.music_note,
      FriendLinkIconType.tool => Icons.build,
      FriendLinkIconType.docs => Icons.menu_book,
      FriendLinkIconType.video => Icons.play_circle_outline,
      FriendLinkIconType.community => Icons.forum,
    };

Color friendLinkColor(String hex) {
  final parsed = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return Color(parsed == null ? 0xFF5C6BC0 : 0xFF000000 | parsed);
}

/// 友链配图。接口给了 `image_url` 就显示图片，没给或加载失败时显示
/// 用项目主题色和图标生成的封面，不占安装包体积。
class FriendLinkCover extends StatelessWidget {
  final FriendLinkRecord link;

  const FriendLinkCover({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    final generated = _GeneratedCover(link: link);
    if (link.imageUrl.isEmpty) return generated;
    return CachedNetworkImage(
      imageUrl: link.imageUrl,
      fit: BoxFit.cover,
      fadeInDuration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 240)),
      placeholder: (_, __) => Stack(
        fit: StackFit.expand,
        children: [
          generated,
          const ImageLoadingIndicator(background: Colors.transparent),
        ],
      ),
      errorWidget: (_, __, ___) => generated,
    );
  }
}

class _GeneratedCover extends StatelessWidget {
  final FriendLinkRecord link;

  const _GeneratedCover({required this.link});

  @override
  Widget build(BuildContext context) {
    final color = friendLinkColor(link.iconColor);
    final deep = Color.lerp(color, Colors.black, 0.45)!;
    final icon = friendLinkIcon(friendLinkIconType(link.iconType));
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, deep],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            top: -14,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(icon,
                  size: 148, color: Colors.white.withValues(alpha: 0.16)),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hub 页的友链轮播：每 5 秒自动翻一张，手指拖动时暂停，点击用浏览器打开。
class FriendLinkCarousel extends StatefulWidget {
  const FriendLinkCarousel({super.key});

  @override
  State<FriendLinkCarousel> createState() => _FriendLinkCarouselState();
}

class _FriendLinkCarouselState extends State<FriendLinkCarousel>
    with WidgetsBindingObserver {
  static const Duration _interval = Duration(seconds: 5);

  /// 从很大的页码起步，向左向右都能一直滑。
  static const int _startPage = 10000;

  final PageController _controller = PageController(initialPage: _startPage);
  List<FriendLinkRecord> _links = FriendLinksService.fallback;
  int _page = _startPage;
  bool _dragging = false;
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final links = await const FriendLinksService().fetch();
      if (!mounted || links.isEmpty) return;
      setState(() => _links = links);
    } catch (e) {
      // 拿不到在线数据时继续显示内置友链
      debugPrint('[FriendLinkCarousel] 获取友链失败: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 切到别的标签页、被功能页盖住时 TickerMode 会关闭，这时不翻页。
    _visible = TickerMode.of(context);
    _restartTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    // 系统开启「减少动态效果」时不自动翻页，手动滑动不受影响。
    final autoPlay = MediaQuery.maybeDisableAnimationsOf(context) != true;
    if (!_visible || !resumed || _dragging || !autoPlay) return;
    _timer = Timer.periodic(_interval, (_) => _next());
  }

  void _next() {
    if (!mounted || _links.length < 2 || !_controller.hasClients) return;
    _controller.nextPage(
      duration: AppDesignTokens.slowMotion,
      curve: AppDesignTokens.emphasizedCurve,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    final dragging = switch (notification) {
      ScrollStartNotification(dragDetails: != null) => true,
      ScrollEndNotification() => false,
      _ => _dragging,
    };
    if (dragging != _dragging) {
      _dragging = dragging;
      _restartTimer();
    }
    return false;
  }

  Future<void> _open(FriendLinkRecord link) async {
    if (await ExternalLaunchUtil.openString(link.url)) return;
    if (mounted) await ExternalLaunchUtil.copyFallback(context, link.url);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPage(FriendLinkRecord link) {
    return Semantics(
      button: true,
      label: '打开友情链接：${link.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(link),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FriendLinkCover(link: link),
            // 底部压暗，换成任意配图时文字都看得清
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.name,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MarqueeText(
                    text: link.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _links.length;
    if (count == 0) return const SizedBox.shrink();
    final current = _page % count;
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      child: AspectRatio(
        aspectRatio: 20 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (_, index) => _buildPage(_links[index % count]),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: PressScale(
                child: Semantics(
                  button: true,
                  label: '查看全部友情链接',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const FriendLinksPage())),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.36),
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('友情链接',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (count > 1)
              Positioned(
                left: 16,
                bottom: 10,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        AnimatedContainer(
                          duration: motion,
                          curve: AppDesignTokens.emphasizedCurve,
                          width: i == current ? 16 : 6,
                          height: 4,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: i == current ? 0.95 : 0.45),
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusPill),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
