import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:permission_handler/permission_handler.dart';

import '../service/OnboardingStateStore.dart';
import '../widgets/BackgroundPageScaffold.dart';
import 'LegalDocumentPage.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';
import '../widgets/AppLauncherIcon.dart';

/// ChiffonMai 的首次使用与功能更新引导。
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _closing = false;
  bool _changingPage = false;
  bool _requestingPermission = false;
  bool _hasAgreed = false;
  bool _guardianConsent = false;
  DateTime? _agreedAt;
  late final TapGestureRecognizer _agreementTap;
  late final TapGestureRecognizer _privacyTap;
  DateTime? _lastBack;
  bool _permissionsLoading = true;
  final Map<_OnboardingPermission, PermissionStatus> _permissionStatuses = {};

  static const _steps = <_OnboardingStepData>[
    _OnboardingStepData(
      hero: _OnboardingHero.navigation,
      title: '先认识一下 ChiffonMai',
      description: '五个标签页，想找的东西都在这里。',
      rows: [
        _OnboardingRow(Icons.home_rounded, '首页', '个人概况、常用功能、同步和服务器状态'),
        _OnboardingRow(Icons.library_music_rounded, '曲库', '查歌曲、看谱面、找收藏品'),
        _OnboardingRow(Icons.leaderboard_rounded, '成绩', 'Best50、推分工具和排行榜'),
        _OnboardingRow(Icons.sports_esports_rounded, '游玩', '出勤找机厅，休闲猜歌和听歌'),
        _OnboardingRow(Icons.person_rounded, '我的', '账号、刷新数据和各种设置'),
      ],
    ),
    _OnboardingStepData(
      hero: _OnboardingHero.sync,
      title: '先刷新数据，再开始探索',
      description: '刷新数据会准备曲库、定数、标签和成绩。\n不登录也可以先逛逛。',
      rows: [
        _OnboardingRow(Icons.refresh_rounded, '刷新数据', '在「我的」页，或点首页的 Rating 进入'),
        _OnboardingRow(Icons.sync_rounded, '同步成绩', '水鱼、落雪和 AWMC NET，需先绑定账号'),
        _OnboardingRow(Icons.autorenew_rounded, '自动同步', '开启后每天分时处理，首页随时能看结果'),
      ],
    ),
    _OnboardingStepData(
      hero: _OnboardingHero.theme,
      title: '把体验调成你喜欢的样子',
      description: '都在「我的」页的设置里，随时可以改。',
      rows: [
        _OnboardingRow(Icons.dark_mode_rounded, '主题', '浅色、深色、纯黑或跟随系统，还能换主题色'),
        _OnboardingRow(Icons.wallpaper_rounded, '背景', '自定义背景图、装饰图和覆层'),
        _OnboardingRow(Icons.swipe_rounded, '导航', '三种导航栏样式，动画和滑动切换可开关'),
        _OnboardingRow(Icons.celebration_rounded, '纸屑', '刷新或同步成功时放一点纸屑'),
      ],
    ),
  ];

  static const _permissions = <_OnboardingPermissionData>[
    _OnboardingPermissionData(
      permission: _OnboardingPermission.media,
      icon: Icons.photo_library_outlined,
      title: '相册与媒体',
      description: '用于选择曲绘、保存导出的歌曲信息和成绩图片。',
      fullAccessHint: true,
    ),
    _OnboardingPermissionData(
      permission: _OnboardingPermission.camera,
      icon: Icons.camera_alt_outlined,
      title: '相机',
      description: '用于拍摄曲绘或成绩截图进行识别。',
    ),
    _OnboardingPermissionData(
      permission: _OnboardingPermission.location,
      icon: Icons.location_on_outlined,
      title: '位置',
      description: '用于全球机厅地图中的位置服务。',
    ),
    _OnboardingPermissionData(
      permission: _OnboardingPermission.notifications,
      icon: Icons.notifications_none,
      title: '通知',
      description: '用于随身听后台播放时显示通知栏控制。',
    ),
  ];

  int get _pageCount => _steps.length + 3;
  bool get _isLastPage => _page == _pageCount - 1;
  bool get _isConsentPage => _page == _pageCount - 2;
  bool get _canProceed =>
      !_closing &&
      !_changingPage &&
      !_requestingPermission &&
      (!(_isConsentPage || _isLastPage) || _hasAgreed);

  @override
  void initState() {
    super.initState();
    _agreementTap = TapGestureRecognizer()
      ..onTap =
          () => LegalDocumentPage.open(context, AppLegalDocument.userAgreement);
    _privacyTap = TapGestureRecognizer()
      ..onTap =
          () => LegalDocumentPage.open(context, AppLegalDocument.privacyPolicy);
    _refreshPermissionStatuses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _agreementTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_closing || !_isLastPage || !_hasAgreed || _agreedAt == null) return;
    setState(() => _closing = true);
    try {
      await OnboardingStateStore.instance.markCompleted(
          accepted: _hasAgreed,
          agreedAt: _agreedAt!,
          guardianConsent: _guardianConsent);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _closing = false);
      AppToast.show('确认记录保存失败，请重试');
    }
  }

  void _next() {
    if (!_canProceed) return;
    if (_isLastPage) {
      _finish();
      return;
    }
    _goToPage(_page + 1);
  }

  Future<void> _goToPage(int page) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _changingPage = true;
      _lastBack = null;
    });
    try {
      await _pageController.animateToPage(page,
          duration: AppDesignTokens.motion(
              context, const Duration(milliseconds: 380)),
          curve: AppDesignTokens.emphasizedCurve);
    } finally {
      if (mounted) setState(() => _changingPage = false);
    }
  }

  void _setAgreement(bool agreed, {bool guardianConsent = false}) {
    setState(() {
      _hasAgreed = agreed;
      _guardianConsent = agreed && guardianConsent;
      _agreedAt = agreed ? DateTime.now() : null;
    });
  }

  Future<void> _showGuardianConsent() async {
    if (_requestingPermission) return;
    _setAgreement(false);
    var confirmed = false;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AppAlertDialog(
          title: const Text('监护人单独同意'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('请将设备交由监护人操作。监护人应阅读以下文件，了解所处理的信息、用途，以及查询和删除信息的方式。'),
                const SizedBox(height: 8),
                Wrap(children: [
                  for (final document in AppLegalDocument.values)
                    TextButton(
                      onPressed: () =>
                          LegalDocumentPage.open(context, document),
                      child: Text('《${document.title}》'),
                    ),
                ]),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: confirmed,
                  onChanged: (value) => update(() => confirmed = value == true),
                  title: const Text(
                      '我是该用户的监护人，已阅读并同意《用户协议》和《隐私政策》，同意为提供相应功能处理被监护人的必要个人信息。'),
                ),
                const SizedBox(height: 8),
                const Text('同意后，仍可按需选择权限和相关功能；也可按隐私政策说明撤回授权或申请删除信息。'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消')),
            FilledButton(
                onPressed:
                    confirmed ? () => Navigator.of(context).pop(true) : null,
                child: const Text('监护人同意')),
          ],
        ),
      ),
    );
    if (mounted && agreed == true) _setAgreement(true, guardianConsent: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _closing || _changingPage || _requestingPermission)
          return;
        if (_page > 0) {
          _goToPage(_page - 1);
          return;
        }
        final now = DateTime.now();
        if (_lastBack != null &&
            now.difference(_lastBack!) < const Duration(seconds: 2)) {
          AppToast.hide();
          SystemNavigator.pop();
          return;
        }
        _lastBack = now;
        AppToast.show('再返回一次退出应用', duration: Duration(seconds: 2));
      },
      child: BackgroundPageScaffold(
        title: 'ChiffonMai 入门',
        showBack: false,
        headerOverride: const SizedBox.shrink(),
        contentPadding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 12),
            // 顶部分段进度
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDesignTokens.gutter),
              child: Row(
                children: [
                  for (var i = 0; i < _pageCount; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedContainer(
                        duration: AppDesignTokens.motion(
                            context, const Duration(milliseconds: 280)),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                // 仅通过按钮前进；返回可回到上一页，不把退出应用记作完成。
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pageCount,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildWelcomeStep(context);
                  if (index <= _steps.length) {
                    return _buildStep(context, _steps[index - 1]);
                  }
                  if (index == _steps.length + 1) {
                    return _buildPermissionStep(context);
                  }
                  return _buildCompletionStep(context);
                },
              ),
            ),
            // 系统导航栏会占用底部安全区，按钮要留在它上面。
            Padding(
              padding: EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
                  AppDesignTokens.gutter, 16 + safeBottom),
              child: Row(
                children: [
                  AnimatedSize(
                    duration: AppDesignTokens.motion(
                        context, const Duration(milliseconds: 220)),
                    curve: AppDesignTokens.emphasizedCurve,
                    child: _page == 0
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton.filledTonal(
                              tooltip: '上一步',
                              onPressed: _closing || _changingPage
                                  ? null
                                  : () => _goToPage(_page - 1),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                  ),
                  Expanded(
                    child: PressScale(
                      scale: 0.98,
                      child: FilledButton(
                        onPressed: _canProceed ? _next : null,
                        child: Text(_isLastPage ? '开始探索' : '下一步'),
                      ),
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

  /// 戚风说的话。
  Widget _speechBubble(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  /// 欢迎页和完成页：图标 + 大标题 + 戚风的一句话，整组垂直居中。
  Widget _buildCharacterStep(
    BuildContext context, {
    required Widget visual,
    String? speech,
    required String title,
    required String description,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EntranceAnimation(
                offset: const Offset(0, 16),
                scaleFrom: 0.9,
                child: visual,
              ),
              const SizedBox(height: 24),
              EntranceAnimation(
                baseDelay: const Duration(milliseconds: 80),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              EntranceAnimation(
                baseDelay: const Duration(milliseconds: 140),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (speech != null) ...[
                const SizedBox(height: 24),
                EntranceAnimation(
                  baseDelay: const Duration(milliseconds: 220),
                  scaleFrom: 0.96,
                  child: _speechBubble(speech),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    return _buildCharacterStep(
      context,
      visual: const AppLauncherIcon(size: 96),
      title: '欢迎来到 ChiffonMai',
      // 手动断句：两行长度相近，不会只剩一个字掉到下一行
      description: '歌曲、谱面、成绩与实用工具都在这里，\n从查一首歌到推一次分，慢慢来就好。',
    );
  }

  Widget _buildCompletionStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildCharacterStep(
      context,
      visual: Container(
        width: 96,
        height: 96,
        decoration:
            BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 56, color: scheme.onPrimary),
      ),
      speech: '都准备好了呢。记得先刷新一下数据哦？',
      title: '准备完成！',
      description: '接下来，就从一首歌开始探索吧。',
    );
  }

  Future<void> _refreshPermissionStatuses() async {
    final statuses = <_OnboardingPermission, PermissionStatus>{};
    for (final item in _permissions) {
      statuses[item.permission] = await _statusFor(item.permission);
    }
    if (!mounted) return;
    setState(() {
      _permissionStatuses
        ..clear()
        ..addAll(statuses);
      _permissionsLoading = false;
    });
  }

  Future<PermissionStatus> _statusFor(_OnboardingPermission permission) async {
    try {
      switch (permission) {
        case _OnboardingPermission.media:
          final statuses = await Future.wait([
            Permission.storage.status,
            Permission.photos.status,
            Permission.videos.status,
          ]);
          return _combineMediaStatuses(statuses);
        case _OnboardingPermission.camera:
          return await Permission.camera.status;
        case _OnboardingPermission.location:
          return await Permission.locationWhenInUse.status;
        case _OnboardingPermission.notifications:
          return await Permission.notification.status;
      }
    } catch (_) {
      // 测试环境或不支持该平台时没有原生权限插件，按未授权展示即可。
      return PermissionStatus.denied;
    }
  }

  PermissionStatus _combineMediaStatuses(List<PermissionStatus> statuses) {
    if (statuses.any((status) => status.isLimited)) {
      return PermissionStatus.limited;
    }
    if (statuses.any((status) => status.isGranted)) {
      return PermissionStatus.granted;
    }
    if (statuses.any((status) => status.isPermanentlyDenied)) {
      return PermissionStatus.permanentlyDenied;
    }
    if (statuses.any((status) => status.isRestricted)) {
      return PermissionStatus.restricted;
    }
    return PermissionStatus.denied;
  }

  Future<void> _requestPermission(_OnboardingPermission permission) async {
    if (!_hasAgreed || _requestingPermission) return;
    setState(() => _requestingPermission = true);
    try {
      final current = _permissionStatuses[permission];
      if (current?.isLimited == true ||
          current?.isPermanentlyDenied == true ||
          current?.isRestricted == true) {
        await openAppSettings();
      } else {
        switch (permission) {
          case _OnboardingPermission.media:
            // 同时覆盖 Android 旧版存储、Android 13+ 图片/视频和 iOS 相册。
            await [
              Permission.storage,
              Permission.photos,
              Permission.videos,
            ].request();
          case _OnboardingPermission.camera:
            await Permission.camera.request();
          case _OnboardingPermission.location:
            await Permission.locationWhenInUse.request();
          case _OnboardingPermission.notifications:
            await Permission.notification.request();
        }
      }
      await _refreshPermissionStatuses();
    } catch (error) {
      if (!mounted) return;
      AppToast.show('申请权限失败：$error');
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  String _permissionStatusLabel(PermissionStatus? status) {
    if (_permissionsLoading || status == null) return '检查中';
    if (status.isGranted) return '已允许';
    if (status.isLimited) return '有限访问';
    if (status.isPermanentlyDenied || status.isRestricted) return '请前往设置';
    return '未允许';
  }

  Widget _buildPermissionStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 20, AppDesignTokens.gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '协议与权限',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '先确认协议才能继续。权限可以现在允许，也可以等用到时再说。',
            style: TextStyle(
                fontSize: 14.5, height: 1.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _buildAgreementSection(context),
          const SizedBox(height: 16),
          for (final (index, item) in _permissions.indexed)
            EntranceAnimation(
              index: index,
              offset: const Offset(0, 8),
              duration: const Duration(milliseconds: 300),
              child: _buildPermissionTile(context, item),
            ),
          const SizedBox(height: 4),
          Text(
            '网络、后台播放和安全存储由系统自动管理，不需要在这里单独授权。',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
        fontSize: 13, height: 1.55, color: scheme.onSurfaceVariant);
    final linkStyle =
        TextStyle(color: scheme.primary, decoration: TextDecoration.underline);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _hasAgreed,
                onChanged: _requestingPermission
                    ? null
                    : (value) => _setAgreement(value == true),
                semanticLabel: '我已阅读并同意用户协议和隐私政策',
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: '我已阅读并同意'),
                      TextSpan(
                          text: '《用户协议》',
                          style: linkStyle,
                          recognizer: _agreementTap),
                      const TextSpan(text: '和'),
                      TextSpan(
                          text: '《隐私政策》',
                          style: linkStyle,
                          recognizer: _privacyTap),
                    ]),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                    '为提供游戏服务，我们会处理你的游玩记录、歌曲成绩、账号及设备标识等必要信息；'
                    '多人联机对战会实时传输对局通信数据，仅用于维持联机功能。',
                    style: style),
                const SizedBox(height: 8),
                Text('未满18周岁请在监护人指导下使用。未满14周岁需由监护人单独同意。', style: style),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed:
                      _requestingPermission ? null : _showGuardianConsent,
                  child:
                      Text(_guardianConsent ? '监护人已单独同意' : '未满14周岁，由监护人完成同意'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context,
    _OnboardingPermissionData item,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final status = _permissionStatuses[item.permission];
    final needsSettings = status?.isLimited == true ||
        status?.isPermanentlyDenied == true ||
        status?.isRestricted == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: AppDesignTokens.radiusMedium,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Icon(item.icon, size: 20, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _permissionStatusLabel(status),
                        style: TextStyle(
                          color: _permissionStatusColor(status, scheme),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.fullAccessHint
                        ? '${item.description} 请在系统弹窗中选择“允许完全访问”。'
                        : item.description,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant),
                  ),
                  if (needsSettings)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.fullAccessHint && status?.isLimited == true
                            ? '当前是有限访问，请在系统设置中改为“允许完全访问”。'
                            : '当前未授权，使用相关功能时仍会再次请求。',
                        style: TextStyle(fontSize: 12.5, color: scheme.error),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed:
                  !_hasAgreed || _permissionsLoading || _requestingPermission
                      ? null
                      : () => _requestPermission(item.permission),
              child: Text(needsSettings ? '去设置' : '允许'),
            ),
          ],
        ),
      ),
    );
  }

  Color _permissionStatusColor(
    PermissionStatus? status,
    ColorScheme scheme,
  ) {
    if (status?.isGranted == true) {
      return AppColors.successForeground(Theme.of(context).brightness);
    }
    if (status?.isDenied == true ||
        status?.isPermanentlyDenied == true ||
        status?.isRestricted == true) {
      return scheme.error;
    }
    return scheme.onSurfaceVariant;
  }

  /// 中间几页：插画和标题的位置每页都一样，功能卡片撑满剩下的高度，
  /// 行数不同时只改变行距，页面下方不留空。放不下（大字体、小窗）时整页滚动。
  Widget _buildStep(BuildContext context, _OnboardingStepData step) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const verticalPadding = 32.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 20, AppDesignTokens.gutter, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - verticalPadding,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntranceAnimation(
                    offset: const Offset(0, 12),
                    scaleFrom: 0.96,
                    child: _OnboardingHeroArt(
                      hero: step.hero,
                      height: (constraints.maxHeight * 0.24).clamp(150.0, 200.0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  EntranceAnimation(
                    baseDelay: const Duration(milliseconds: 80),
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  EntranceAnimation(
                    baseDelay: const Duration(milliseconds: 120),
                    child: Text(
                      step.description,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (index, row) in step.rows.indexed)
                            Expanded(
                              child: EntranceAnimation(
                                index: index,
                                baseDelay: const Duration(milliseconds: 160),
                                offset: const Offset(0, 8),
                                duration: const Duration(milliseconds: 320),
                                child: _buildStepRow(context, row, index > 0),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow(
      BuildContext context, _OnboardingRow row, bool showDivider) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Icon(row.icon, size: 21, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  row.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _OnboardingHero { navigation, sync, theme }

/// 每一步顶上的小插画，都用真实的界面元素拼出来，不占安装包体积。
class _OnboardingHeroArt extends StatelessWidget {
  final _OnboardingHero hero;
  final double height;

  const _OnboardingHeroArt({required this.hero, required this.height});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.2),
            scheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: switch (hero) {
        _OnboardingHero.navigation => _navigation(context),
        _OnboardingHero.sync => _sync(context),
        _OnboardingHero.theme => _theme(context),
      },
    );
  }

  Widget _navigation(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const icons = [
      Icons.home_rounded,
      Icons.library_music_rounded,
      Icons.leaderboard_rounded,
      Icons.sports_esports_rounded,
      Icons.person_rounded,
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < icons.length; i++)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: i == 0 ? scheme.primary : null,
                shape: BoxShape.circle,
              ),
              child: Icon(icons[i],
                  size: 22,
                  color: i == 0 ? scheme.onPrimary : scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _sync(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration:
              BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(Icons.cloud_sync_rounded,
              size: 30, color: scheme.onPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [chip('水鱼'), chip('落雪'), chip('AWMC NET')],
        ),
      ],
    );
  }

  Widget _theme(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget card(Color background, Color foreground, String label, double turn,
            double dy) =>
        Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: turn,
            child: Container(
              width: 76,
              height: 96,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusMedium),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                        color: scheme.primary, shape: BoxShape.circle),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        card(const Color(0xFFF7FAF9), const Color(0xFF1B2B2B), '浅色', -0.08, 6),
        card(const Color(0xFF1F2A2A), const Color(0xFFE6EEEE), '深色', 0, -4),
        card(const Color(0xFF000000), const Color(0xFFFFFFFF), '纯黑', 0.08, 6),
      ],
    );
  }
}

class _OnboardingRow {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingRow(this.icon, this.title, this.subtitle);
}

class _OnboardingStepData {
  final _OnboardingHero hero;
  final String title;
  final String description;
  final List<_OnboardingRow> rows;

  const _OnboardingStepData({
    required this.hero,
    required this.title,
    required this.description,
    required this.rows,
  });
}

enum _OnboardingPermission { media, camera, location, notifications }

class _OnboardingPermissionData {
  final _OnboardingPermission permission;
  final IconData icon;
  final String title;
  final String description;
  final bool fullAccessHint;

  const _OnboardingPermissionData({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    this.fullAccessHint = false,
  });
}
