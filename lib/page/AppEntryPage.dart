import 'dart:async';

import 'package:flutter/material.dart';

import '../service/OnboardingStateStore.dart';
import '../service/AnnouncementService.dart';
import '../widgets/AnnouncementDialog.dart';
import '../manager/LZYCheckUpdateManager.dart';
import 'AppShell.dart';
import 'OnboardingPage.dart';
import 'SplashPage.dart';

/// 先完成引导再创建主界面，首帧后依次展示公告和更新提示。
class AppEntryPage extends StatefulWidget {
  final VoidCallback? onFirstFrameRendered;
  final bool Function()? canPresentStartup;

  /// 引导完成后再准备主界面状态，首次引导不与账号、播放器初始化竞争。
  final Future<void> Function()? prepareMain;

  const AppEntryPage(
      {super.key,
      this.onFirstFrameRendered,
      this.canPresentStartup,
      this.prepareMain});

  @override
  State<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> {
  bool _checked = false;
  bool? _needsOnboarding;
  bool _preparingMain = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveInitialPage());
  }

  Future<void> _resolveInitialPage() async {
    final needsOnboarding = await OnboardingStateStore.instance.shouldShow();
    if (!mounted) return;
    if (needsOnboarding) {
      setState(() => _needsOnboarding = true);
    } else {
      await _openMain();
    }
  }

  Future<void> _openMain() async {
    if (_preparingMain) return;
    _preparingMain = true;
    setState(() => _needsOnboarding = null);
    try {
      await widget.prepareMain?.call();
    } catch (error) {
      debugPrint('[Startup] 主界面准备失败，继续启动: $error');
    }
    if (mounted) setState(() => _needsOnboarding = false);
  }

  // 只有入口路由在前台且导入流程空闲时才弹启动内容。
  Future<bool> _waitForPresentation() async {
    final route = ModalRoute.of(context);
    while (mounted) {
      final state = WidgetsBinding.instance.lifecycleState;
      if ((state == null || state == AppLifecycleState.resumed) &&
          route?.isCurrent == true &&
          (widget.canPresentStartup?.call() ?? true)) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  Future<void> _checkStartupNotices() async {
    if (_checked) return;
    _checked = true;
    widget.onFirstFrameRendered?.call();
    final service = AnnouncementService();
    // 主界面就绪后再加载公告，不在引导期间触发额外请求和解析。
    final announcement = service.load().onError((error, stackTrace) => null);
    try {
      final value = await announcement;
      if (!mounted) return;
      if (value != null && await service.shouldShow(value)) {
        if (!await _waitForPresentation() || !mounted) return;
        if (value.activeAt(DateTime.now())) {
          await showAnnouncementDialog(context, value, service: service);
        }
      }
    } catch (_) {
      // 公告缓存/设置读取失败不能阻止应用使用及原有更新检查。
    }
    if (!mounted) return;
    final updates = LZYCheckUpdateManager();
    try {
      if (await updates.shouldShowUpdateDialog()) {
        final info = await updates.checkUpdate();
        if (info['hasUpdate'] == true &&
            await _waitForPresentation() &&
            mounted) {
          await updates.showUpdateDialog(context);
        }
      }
    } catch (_) {/* 更新检查失败不打断启动。 */}
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding == null) return const SplashPage();
    if (_needsOnboarding!) {
      // 不在引导背后创建五个 Hub：首页首次拉取全量曲库会严重干扰引导动画。
      return OnboardingPage(
        onCompleted: () => unawaited(_openMain()),
      );
    }
    return AppShell(onFirstFrameRendered: _checkStartupNotices);
  }
}
