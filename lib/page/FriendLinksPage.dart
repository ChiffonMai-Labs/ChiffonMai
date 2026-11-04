import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/FriendLinksService.dart';
import '../utils/AppTheme.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/FriendLinkUi.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppToast.dart';

/// 友情链接页面：以卡片形式展示推广同行的项目，点击通过外部浏览器打开。
class FriendLinksPage extends StatefulWidget {
  const FriendLinksPage({super.key});

  @override
  State<FriendLinksPage> createState() => _FriendLinksPageState();
}

class _FriendLinksPageState extends State<FriendLinksPage> {
  List<FriendLinkRecord> _friendLinks = FriendLinksService.fallback;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFriendLinks();
  }

  Future<void> _loadFriendLinks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final records = await const FriendLinksService().fetch();
      if (!mounted) return;
      setState(() {
        _friendLinks = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[FriendLinksPage] 获取友链失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = '在线友链暂时不可用，当前显示本地缓存';
      });
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppToast.show('链接无效');
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _copyFallback(url);
      }
    } catch (e) {
      debugPrint('打开友链失败: $e');
      _copyFallback(url);
    }
  }

  void _copyFallback(String url) {
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      AppToast.show('无法打开浏览器，链接已复制到剪贴板', duration: Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final Color textSecondaryColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return BackgroundPageScaffold(
      title: '查看友情链接',
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(bottom: safeBottom + 10),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.04,
          16,
          screenWidth * 0.04,
          20,
        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 顶部说明
                          Text(
                            '这里收录了同好/同行项目的友情链接，'
                            '点击卡片即可在浏览器中打开。',
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: SmoothLinearProgressIndicator(minHeight: 2),
                            ),
                          if (_loadError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _loadError!,
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _loadFriendLinks,
                                    child: const Text('重试'),
                                  ),
                                ],
                              ),
                            ),
                          // 友链列表（1列N行）
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _friendLinks.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: screenWidth * 0.025),
                            itemBuilder: (ctx, i) => _FriendLinkCard(
                              link: _friendLinks[i],
                              onOpen: _open,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

/// 友链卡片：图标区 + 名称 + 简介 + 跳转按钮
class _FriendLinkCard extends StatelessWidget {
  final FriendLinkRecord link;
  final Future<void> Function(String url) onOpen;

  const _FriendLinkCard({required this.link, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final screenWidth = MediaQuery.of(context).size.width;
    final Color textPrimaryColor = Theme.of(context).colorScheme.onSurface;
    final Color textSecondaryColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        // 用透明外框划分链接条目，点击效果仍由内部 Material 承载。
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onOpen(link.url),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.015,
            ),
            child: Row(
              children: [
                // 左侧：配图，和轮播用同一张
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                  child: SizedBox.square(
                    dimension: screenWidth * 0.13,
                    child: link.imageUrl.isEmpty
                        ? ColoredBox(
                            color: friendLinkColor(link.iconColor),
                            child: Icon(
                              friendLinkIcon(
                                  friendLinkIconType(link.iconType)),
                              color: Colors.white,
                              size: screenWidth * 0.07,
                            ),
                          )
                        : FriendLinkCover(link: link),
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                // 中间：项目名称 + 简介
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        link.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.008),
                      // 参考 SongInfoPage：先用 LayoutBuilder + TextPainter 测量文本宽度
                      // 当文本能完整显示时不滚动（直接省略号），溢出时才用 Marquee
                      // 同时移除 startPadding，避免每轮滚动开头出现空白
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final descStyle = TextStyle(
                            color: textSecondaryColor,
                            fontSize: 12,
                          );
                          final textPainter = TextPainter(
                            text: TextSpan(
                              text: link.description,
                              style: descStyle,
                            ),
                            maxLines: 1,
                            textDirection: TextDirection.ltr,
                          )..layout(
                              minWidth: 0,
                              maxWidth: double.infinity,
                            );
                          final textWidth = textPainter.width;
                          final safeWidth = constraints.maxWidth;
                          if (textWidth <= safeWidth) {
                            return Text(
                              link.description,
                              style: descStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return SizedBox(
                            height: screenWidth * 0.04,
                            child: Marquee(
                              text: link.description,
                              style: descStyle,
                              velocity: 30.0,
                              blankSpace: 30.0,
                              pauseAfterRound: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                // 右侧：前往图标
                Icon(
                  Icons.open_in_new,
                  size: screenWidth * 0.045,
                  color: AppColors.greyHint(brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
