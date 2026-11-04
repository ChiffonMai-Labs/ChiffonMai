import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/AppLinks.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'AppUi.dart';
import 'GuideLinkText.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

Future<void> showAccountRegistrationGuide(BuildContext context) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await showDialog<void>(
    context: context,
    builder: (_) => const _AccountRegistrationGuideDialog(),
  );
}

/// 只展示注册步骤；外链交给系统浏览器，BOT 指令由用户复制后自行发送。
class _AccountRegistrationGuideDialog extends StatefulWidget {
  const _AccountRegistrationGuideDialog();

  @override
  State<_AccountRegistrationGuideDialog> createState() =>
      _AccountRegistrationGuideDialogState();
}

class _AccountRegistrationGuideDialogState
    extends State<_AccountRegistrationGuideDialog> {
  final ScrollController _scrollController = ScrollController();
  int _tab = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _openSite(String url) async {
    if (await ExternalLaunchUtil.openString(url)) return;
    if (mounted) await ExternalLaunchUtil.copyFallback(context, url);
  }

  Future<void> _copyCommand(String command) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (!mounted) return;
    AppToast.show('已复制：$command');
  }

  Future<void> _copyBotQq() async {
    await Clipboard.setData(const ClipboardData(text: AppLinks.awmcBotNumber));
    if (!mounted) return;
    AppToast.show('已复制 AWMC BOT QQ 号：${AppLinks.awmcBotNumber}');
  }

  Widget _copyButton(String command) => OutlinedButton.icon(
        onPressed: () => _copyCommand(command),
        icon: const Icon(Icons.copy_outlined, size: 16),
        label: Text('复制 $command'),
      );

  Widget _buildDivingFish() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuideStep(
            index: 1,
            body: const GuideLinkText(
              before: '访问 ',
              label: AppLinks.divingFishRegistrationUrl,
              url: AppLinks.divingFishRegistrationUrl,
              after: '，点击右侧“快捷操作”区域的“注册”。',
            ),
            image: const _GuideImage(
                'assets/guide/divingfish-homepage.webp', 1400 / 752),
            action: FilledButton.tonalIcon(
              onPressed: () => _openSite(AppLinks.divingFishRegistrationUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('打开水鱼查分器'),
            ),
          ),
          const _GuideStep(
            index: 2,
            body: Text('随页面引导填写信息，即可注册水鱼账号。'),
            image: _GuideImage(
                'assets/guide/divingfish-register.webp', 1400 / 752),
          ),
          const _GuideStep(
            index: 3,
            isLast: true,
            body: _GuideDetails(
              intro: '登录后点页面右上角的“编辑个人资料”，按下面的说明设置：',
              items: [
                '成绩导入 Token：必须轮换！点 Token 右边的刷新图标即可，否则无法在 App 内登录。',
                '绑定 QQ 号：必须填写。如果有小号，尽量不要和小号重复。',
                '昵称：建议填写。不填的话，App 内会默认以“shuiyu:QQ 号”的形式保存。',
                '绑定频道 ID 和段位：没有特别要求。',
                '“禁止公开接口使用我的成绩”：必须关闭。',
                '“对非网页查询的成绩使用掩码”：建议关闭，开启掩码会影响排行榜排名。',
                '全部改好后，记得点“保存”。',
              ],
            ),
            image: _GuideImage(
                'assets/guide/divingfish-settings.webp', 1400 / 752),
          ),
        ],
      );

  Widget _buildLuoXue() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuideStep(
            index: 1,
            body: const GuideLinkText(
              before: '访问 ',
              label: AppLinks.luoXueRegistrationUrl,
              url: AppLinks.luoXueRegistrationUrl,
              after: '，点击左侧边栏的“新用户注册”或页面中间处的“注册 maimai DX 查分器账号”。',
            ),
            image: const _GuideImage(
                'assets/guide/lxns-homepage.webp', 1400 / 752),
            action: FilledButton.tonalIcon(
              onPressed: () => _openSite(AppLinks.luoXueRegistrationUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('打开落雪咖啡屋'),
            ),
          ),
          const _GuideStep(
            index: 2,
            body: Text('随页面引导填写信息，即可注册落雪咖啡屋账号。'),
            image: _GuideImage('assets/guide/lxns-register.webp', 1400 / 752),
          ),
          const _GuideStep(
            index: 3,
            isLast: true,
            body: _GuideDetails(
              intro: '登录后在侧边栏点“账号详情”，再点页面上方的“第三方应用”：',
              items: [
                'OAuth 授权：在 App 的“我的 → 数据刷新 → 刷新数据 / 刷新数据（高级）”对话框里把数据源切换到落雪，按引导完成授权。授权后，这里的 OAuth 应用列表会出现 ChiffonMai。',
                '个人 API 密钥：点“重置 API 密钥”，然后到 App 的“我的 → 账号管理”，下滑找到“落雪 API 密钥”并填入。',
                '也欢迎支持一下中二查歌，在“首页游玩 → 出勤”的轮播图里可以跳转过去。',
              ],
            ),
            image: _GuideImage('assets/guide/lxns-settings.webp', 1400 / 752),
          ),
        ],
      );

  Widget _buildAwmc() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuideLinkText(
            before: '私聊 ',
            label: AppLinks.awmcBotName,
            onTap: _copyBotQq,
            after: '，或在有机器人的群中，依次完成以下步骤：',
          ),
          const SizedBox(height: 12),
          _GuideStep(
            index: 1,
            body: const Text('先发送 mymai。尚未建立账号记录时，机器人会回复操作步骤。'),
            image:
                const _GuideImage('assets/guide/awmcbot-mymai.webp', 620 / 282),
            action: _copyButton('mymai'),
          ),
          _GuideStep(
            index: 2,
            body: const Text('再发送 mai绑定，按提示创建档案。'),
            image: const _GuideImage(
                'assets/guide/awmcbot-maibind.webp', 624 / 298),
            action: _copyButton('mai绑定'),
          ),
          const _GuideStep(
            index: 3,
            body: Text('按提示发送 SGWCMAID 字符串或舞萌二维码，等机器人回复上传完成就好了。'),
            image: _GuideImage('assets/guide/awmcbot-qrcode.webp', 620 / 578),
          ),
          _GuideStep(
            index: 4,
            isLast: true,
            body: const _GuideDetails(
              introWidget: GuideLinkText(
                before: '访问 ',
                label: AppLinks.awmcNetSettingsUrl,
                url: AppLinks.awmcNetSettingsUrl,
                after: '，按下面的说明设置：',
              ),
              items: [
                '“公开我的成绩”：必须开启，否则无法获取成绩。',
                'Import-Token：点“重新生成”轮换，然后到 App 的“我的 → 账号与授权 → 账号管理”，在对话框里下滑到“AWMC 成绩导入 Token”并填入。',
                '注意：已有 Token 时，轮换会覆盖之前的 Token。轮换后请在 App 内手动更新，否则无法同步成绩。',
              ],
            ),
            image:
                const _GuideImage('assets/guide/awmcnet-settings.webp', 1400 / 752),
            action: FilledButton.tonalIcon(
              onPressed: () => _openSite(AppLinks.awmcNetUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('打开 AWMC NET'),
            ),
          ),
          const SizedBox(height: 4),
          const GuideLinkText(
            before: '加入 ',
            label: AppLinks.awmcGroupOneName,
            url: AppLinks.awmcGroupOneJoinUrl,
            fallbackText: AppLinks.awmcGroupOneNumber,
            fallbackMessage: '无法打开 QQ，已复制 AWMC 交流 1 群的群号，请在 QQ 中搜索加入',
          ),
          const SizedBox(height: 6),
          const GuideLinkText(
            before: '加入 ',
            label: AppLinks.awmcGroupTwoName,
            url: AppLinks.awmcGroupTwoJoinUrl,
            fallbackText: AppLinks.awmcGroupTwoNumber,
            fallbackMessage: '无法打开 QQ，已复制 AWMC 交流 2 群的群号，请在 QQ 中搜索加入',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return AppAlertDialog(
      title: const Text('账号注册引导'),
      subtitle: '点开图片可以放大查看哦',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            height: 42,
            selectedIndex: _tab,
            onChanged: _selectTab,
            items: const [
              SegmentedTabItem('水鱼'),
              SegmentedTabItem('落雪'),
              SegmentedTabItem('AWMC NET'),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: AnimatedSize(
                duration: motion,
                curve: AppDesignTokens.emphasizedCurve,
                alignment: Alignment.topCenter,
                child: FadeSwitcher(
                  value: _tab,
                  sizeFollowsCurrent: true,
                  alignment: Alignment.topCenter,
                  child: switch (_tab) {
                    0 => _buildDivingFish(),
                    1 => _buildLuoXue(),
                    _ => _buildAwmc(),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    );
  }
}

/// 一个步骤：左边序号和连接线，右边说明、配图和操作按钮。
class _GuideStep extends StatelessWidget {
  final int index;
  final Widget body;
  final Widget? image;
  final Widget? action;
  final bool isLast;

  const _GuideStep({
    required this.index,
    required this.body,
    this.image,
    this.action,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // 连接线随步骤内容一起伸长，不用 IntrinsicHeight（里面有图片和换行文字）
        if (!isLast)
          Positioned(
            left: 11,
            top: 28,
            bottom: 4,
            child: Container(width: 2, color: scheme.outlineVariant),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text('$index',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 1, bottom: isLast ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    body,
                    if (image != null) ...[
                      const SizedBox(height: 8),
                      image!,
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: action),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 步骤说明：一句引导 + 逐条要点，长步骤比一整段话好读。
class _GuideDetails extends StatelessWidget {
  final String? intro;

  /// 引导句里要放链接时用它，优先于 [intro]。
  final Widget? introWidget;
  final List<String> items;

  const _GuideDetails({this.intro, this.introWidget, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        introWidget ?? Text(intro ?? ''),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

/// 引导配图：先按比例占位，图片解码前后版面都不跳；点开全屏查看。
class _GuideImage extends StatelessWidget {
  final String asset;
  final double aspectRatio;

  const _GuideImage(this.asset, this.aspectRatio);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDesignTokens.radiusSmall);
    return Semantics(
      button: true,
      label: '放大查看图片',
      child: PressScale(
        child: GestureDetector(
          onTap: () => _showGuideImageViewer(context, asset),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: scheme.outlineVariant),
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: AppSurfaces.inset(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(asset, fit: BoxFit.cover, cacheWidth: 900),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showGuideImageViewer(BuildContext context, String asset) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭图片',
    barrierColor: Colors.black.withValues(alpha: 0.88),
    transitionDuration:
        AppDesignTokens.motion(context, const Duration(milliseconds: 200)),
    pageBuilder: (context, animation, secondaryAnimation) {
      final topInset = MediaQuery.paddingOf(context).top;
      return Stack(
        fit: StackFit.expand,
        children: [
          // 点一下关闭；双指缩放看细节
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(child: Image.asset(asset)),
            ),
          ),
          Positioned(
            top: topInset + 8,
            right: 12,
            child: IconButton.filledTonal(
              tooltip: '关闭',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
