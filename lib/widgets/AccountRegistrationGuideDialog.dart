import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
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
    AppToast.show(context.l10n.flowCopiedP0((command).toString()),
        tone: AppToastTone.success);
  }

  Future<void> _copyBotQq() async {
    await Clipboard.setData(const ClipboardData(text: AppLinks.awmcBotNumber));
    if (!mounted) return;
    AppToast.show(
        context.l10n
            .flowAWMCBOTQQIDCopiedP0((AppLinks.awmcBotNumber).toString()),
        tone: AppToastTone.success);
  }

  Widget _copyButton(String command) => OutlinedButton.icon(
        onPressed: () => _copyCommand(command),
        icon: const Icon(Icons.copy_outlined, size: 16),
        label: Text(context.l10n.flowCopyP0((command).toString())),
      );

  Widget _buildDivingFish() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuideStep(
            index: 1,
            body: GuideLinkText(
              before: context.l10n.flowVisit2,
              label: AppLinks.divingFishRegistrationUrl,
              url: AppLinks.divingFishRegistrationUrl,
              after: context.l10n.flowThenChooseRegisterUnderQuickActionsOn,
            ),
            image: const _GuideImage(
                'assets/guide/divingfish-homepage.webp', 1400 / 752),
            action: FilledButton.tonalIcon(
              onPressed: () => _openSite(AppLinks.divingFishRegistrationUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(context.l10n.flowOpenDivingFish),
            ),
          ),
          _GuideStep(
            index: 2,
            body: Text(context.l10n.flowFollowThePageInstructionsToRegisterA),
            image: _GuideImage(
                'assets/guide/divingfish-register.webp', 1400 / 752),
          ),
          _GuideStep(
            index: 3,
            isLast: true,
            body: _GuideDetails(
              intro: context.l10n.flowAfterSigningInOpenEditProfileAt,
              items: [
                context.l10n.flowScoreImportTokenRotateItUsingThe,
                context.l10n.flowLinkedQQRequiredAvoidUsingTheSame,
                context.l10n.flowNicknameRecommendedWithoutOneTheAppSaves,
                context.l10n.flowChannelIDAndRankNoSpecificRequirements,
                context.l10n.flowDisablePreventPublicAPIsFromUsingMy,
                context.l10n.flowDisableMaskingScoresForNonWebQueries,
                context.l10n.flowRememberToSaveAfterMakingChanges,
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
            body: GuideLinkText(
              before: context.l10n.flowVisit2,
              label: AppLinks.luoXueRegistrationUrl,
              url: AppLinks.luoXueRegistrationUrl,
              after: context.l10n.flowThenChooseNewUserRegistrationInThe,
            ),
            image: const _GuideImage(
                'assets/guide/lxns-homepage.webp', 1400 / 752),
            action: FilledButton.tonalIcon(
              onPressed: () => _openSite(AppLinks.luoXueRegistrationUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(context.l10n.flowOpenLXNS),
            ),
          ),
          _GuideStep(
            index: 2,
            body: Text(context.l10n.flowFollowThePageInstructionsToRegisterAn),
            image: _GuideImage('assets/guide/lxns-register.webp', 1400 / 752),
          ),
          _GuideStep(
            index: 3,
            isLast: true,
            body: _GuideDetails(
              intro: context.l10n.flowAfterSigningInOpenAccountDetailsIn,
              items: [
                context.l10n.flowOAuthInMeRefreshDataChooseLXNS,
                context.l10n.flowPersonalAPIKeyResetItThenPaste,
                context.l10n.flowYouCanAlsoVisitChiffonChuFromThe,
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
            before: context.l10n.flowMessage,
            label: AppLinks.awmcBotName,
            onTap: _copyBotQq,
            after: context.l10n.flowPrivatelyOrFollowTheseStepsInA,
          ),
          const SizedBox(height: 12),
          _GuideStep(
            index: 1,
            body: Text(context.l10n.flowSendMymaiFirstIfNoAccountRecord),
            image:
                const _GuideImage('assets/guide/awmcbot-mymai.webp', 620 / 282),
            action: _copyButton('mymai'),
          ),
          _GuideStep(
            index: 2,
            body: Text(context.l10n.flowThenSendMaiAndFollowTheInstructions),
            image: const _GuideImage(
                'assets/guide/awmcbot-maibind.webp', 624 / 298),
            action: _copyButton('mai绑定'),
          ),
          _GuideStep(
            index: 3,
            body: Text(context.l10n.flowSendTheSGWCMAIDStringOrMaimaiQR),
            image: _GuideImage('assets/guide/awmcbot-qrcode.webp', 620 / 578),
          ),
          _GuideStep(
            index: 4,
            isLast: true,
            body: _GuideDetails(
              introWidget: GuideLinkText(
                before: context.l10n.flowVisit2,
                label: AppLinks.awmcNetSettingsUrl,
                url: AppLinks.awmcNetSettingsUrl,
                after: context.l10n.flowAndConfigureTheseSettings,
              ),
              items: [
                context.l10n.flowEnableMakeMyScoresPublicOrScores,
                context.l10n.flowImportTokenRegenerateItThenPasteIt,
                context.l10n.flowRotatingATokenReplacesTheOldOne,
              ],
            ),
            image: const _GuideImage(
                'assets/guide/awmcnet-settings.webp', 1400 / 752),
            action: FilledButton.tonalIcon(
              onPressed: () => _openSite(AppLinks.awmcNetUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(context.l10n.flowOpenAWMCNET),
            ),
          ),
          const SizedBox(height: 4),
          GuideLinkText(
            before: context.l10n.flowJoin,
            label: AppLinks.awmcGroupOneName,
            url: AppLinks.awmcGroupOneJoinUrl,
            fallbackText: AppLinks.awmcGroupOneNumber,
            fallbackMessage: context.l10n.flowCouldNotOpenQQAWMCGroup1,
          ),
          const SizedBox(height: 6),
          GuideLinkText(
            before: context.l10n.flowJoin,
            label: AppLinks.awmcGroupTwoName,
            url: AppLinks.awmcGroupTwoJoinUrl,
            fallbackText: AppLinks.awmcGroupTwoNumber,
            fallbackMessage: context.l10n.flowCouldNotOpenQQAWMCGroup2,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return AppAlertDialog(
      title: Text(context.l10n.featureAccountSetupGuide),
      subtitle: context.l10n.flowTapAnImageToEnlargeIt,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            height: 42,
            selectedIndex: _tab,
            onChanged: _selectTab,
            items: [
              SegmentedTabItem(context.l10n.featureFish),
              SegmentedTabItem(context.l10n.featureLxns),
              const SegmentedTabItem('AWMC NET'),
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
          child: Text(context.l10n.featureGotIt),
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
      label: context.l10n.flowEnlargeImage,
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
    barrierLabel: context.l10n.flowCloseImage,
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
              tooltip: context.l10n.featureClose,
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
