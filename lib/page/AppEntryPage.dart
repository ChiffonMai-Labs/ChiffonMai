import 'package:flutter/material.dart';

import '../service/OnboardingStateStore.dart';
import '../service/AnnouncementService.dart';
import '../widgets/AnnouncementDialog.dart';
import '../manager/LZYCheckUpdateManager.dart';
import 'AppShell.dart';
import 'OnboardingPage.dart';

/// 首帧后依次展示引导、公告、更新提示，等待文件导入和其它路由退出。
class AppEntryPage extends StatefulWidget {
  final VoidCallback? onFirstFrameRendered;
  final bool Function()? canPresentStartup;

  const AppEntryPage(
      {super.key, this.onFirstFrameRendered, this.canPresentStartup});

  @override
  State<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> {
  bool _checked = false;

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

  Future<void> _checkOnboarding() async {
    if (_checked) return;
    _checked = true;
    widget.onFirstFrameRendered?.call();
    final service = AnnouncementService();
    // 提前联网，等待引导时也可以把新公告准备好；网络失败有缓存回退。
    final announcement = service.load().onError((error, stackTrace) => null);
    try {
      if (await OnboardingStateStore.instance.shouldShow()) {
        if (!await _waitForPresentation() || !mounted) return;
        final route =
            MaterialPageRoute<void>(builder: (_) => const OnboardingPage());
        await Navigator.of(context).push<void>(route);
        await route.completed;
      }
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
    return AppShell(onFirstFrameRendered: _checkOnboarding);
  }
}
