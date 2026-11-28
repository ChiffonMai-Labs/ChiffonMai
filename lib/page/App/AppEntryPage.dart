import 'dart:async';

import 'package:flutter/material.dart';

import '../../manager/LuoXue/LuoXueOAuthManager.dart';
import '../../service/Account/AccountAuthorizationStore.dart';
import '../../service/Account/AccountStore.dart';
import '../../service/System/OnboardingStateStore.dart';
import '../../service/About/AnnouncementService.dart';
import '../../utils/LoginStateNotifier.dart';
import '../../widgets/AnnouncementDialog.dart';
import '../../manager/AppUpdate/LZYCheckUpdateManager.dart';
import 'AppShell.dart';
import 'FirstAccountBindingPage.dart';
import 'OnboardingPage.dart';
import 'SplashPage.dart';

/// 先完成引导再创建主界面，首帧后依次展示账号引导、公告和更新提示。
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
  bool _justCompletedOnboarding = false;
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

  Future<bool> _hasAnyBoundAccount() async {
    if (LoginStateNotifier.instance.value) return true;
    try {
      final awmcQQ = (await AccountAuthorizationStore.awmcQQ()).trim();
      if (RegExp(r'^\d{5,12}$').hasMatch(awmcQQ)) return true;
    } catch (_) {}
    try {
      if (await LuoXueOAuthManager().isLoggedIn()) return true;
    } catch (_) {}
    try {
      final all = await AccountStore.loadAll();
      if (all.values.any((meta) => meta.id.isNotEmpty)) return true;
    } catch (_) {}
    return false;
  }

  Future<void> _checkStartupNotices() async {
    if (_checked) return;
    _checked = true;
    widget.onFirstFrameRendered?.call();
    if (_justCompletedOnboarding) {
      _justCompletedOnboarding = false;
      final shouldShowBindingGuide =
          await OnboardingStateStore.instance.shouldShowAccountBindingGuide();
      if (!mounted) return;
      if (shouldShowBindingGuide) {
        if (await _hasAnyBoundAccount()) {
          await OnboardingStateStore.instance
              .markAccountBindingGuideCompleted();
        } else if (await _waitForPresentation() && mounted) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const FirstAccountBindingPage(),
            ),
          );
          await OnboardingStateStore.instance
              .markAccountBindingGuideCompleted();
        }
      }
      if (!mounted) return;
    }
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
        onCompleted: () {
          _justCompletedOnboarding = true;
          unawaited(_openMain());
        },
      );
    }
    return AppShell(onFirstFrameRendered: _checkStartupNotices);
  }
}
