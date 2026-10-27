import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:permission_handler/permission_handler.dart';

import '../service/OnboardingStateStore.dart';
import '../widgets/BackgroundPageScaffold.dart';
import 'LegalDocumentPage.dart';

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
      icon: Icons.explore_rounded,
      title: '先认识一下 ChiffonMai',
      description: '从首页出发，快速找到歌曲、谱面、成绩和各种实用工具。',
      bullets: [
        '首页查看个人概况和常用功能',
        '曲库与数据浏览歌曲和谱面',
        'Best50、猜歌和工具各自独立收纳',
      ],
    ),
    _OnboardingStepData(
      icon: Icons.cloud_sync_rounded,
      title: '先刷新数据，再开始探索',
      description: '刷新数据会准备曲库、定数、标签和成绩等内容。同步成绩则需要对应数据源的账号或凭据。',
      bullets: [
        '刷新数据入口位于“系统”页',
        '同步成绩支持水鱼、落雪和 AWMC NET',
        '不登录也可以先浏览应用和本地内容',
      ],
    ),
    _OnboardingStepData(
      icon: Icons.palette_rounded,
      title: '把体验调成你喜欢的样子',
      description: '系统设置可以调整主题、导航、随身听和纸屑特效等体验。',
      bullets: [
        '支持浅色、深色和跟随系统',
        '可以开启导航动画与左右滑动切换',
        '刷新或同步成功后可播放纸屑特效',
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('确认记录保存失败，请重试')));
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
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
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
        builder: (context, update) => AlertDialog(
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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          SystemNavigator.pop();
          return;
        }
        _lastBack = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('再返回一次退出应用'), duration: Duration(seconds: 2)),
        );
      },
      child: BackgroundPageScaffold(
        title: 'ChiffonMai 入门',
        showBack: false,
        // 系统三键导航栏/手势条会占用底部安全区；把它纳入壳层内边距，
        // 避免最后一页的「下一步/开始探索」被导航栏盖住。
        contentPadding: EdgeInsets.fromLTRB(20, 8, 20, 20 + safeBottom),
        child: Column(
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _page ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canProceed ? _next : null,
                child: Text(_isLastPage ? '开始探索' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    return _buildTextOnlyStep(
      context,
      title: '欢迎来到 ChiffonMai',
      description: '歌曲、谱面、成绩与工具，都可以在这里找到。',
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildCompletionStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildTextOnlyStep(
      context,
      title: '准备完成！',
      description: '接下来，就从一首歌开始探索吧。',
      color: scheme.primary,
    );
  }

  Widget _buildTextOnlyStep(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('申请权限失败：$error')),
      );
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.security_outlined, size: 40, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            '协议与权限',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          _buildAgreementSection(context),
          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            '同意后可按需授权，也可稍后在使用对应功能时授权。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          ..._permissions.map((item) => _buildPermissionTile(context, item)),
          const SizedBox(height: 8),
          Text(
            '网络、后台播放和安全存储由系统自动管理，不需要在这里单独授权。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65);
    final linkStyle =
        TextStyle(color: scheme.primary, decoration: TextDecoration.underline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _hasAgreed,
              onChanged: _requestingPermission
                  ? null
                  : (value) => _setAgreement(value == true),
              semanticLabel: '我已阅读并同意用户协议和隐私政策',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 11),
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
                    style: style,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
            '为提供游戏服务，我们会处理你的游玩记录、歌曲成绩、账号及设备标识等必要信息；\n'
            '多人联机对战会实时传输对局通信数据，仅用于维持联机功能。',
            style: style),
        const SizedBox(height: 12),
        Text('未满18周岁请在监护人指导下使用。未满14周岁需由监护人单独同意。', style: style),
        TextButton(
          onPressed: _requestingPermission ? null : _showGuardianConsent,
          child: Text(_guardianConsent ? '监护人已单独同意' : '未满14周岁，由监护人完成同意'),
        ),
      ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _permissionStatusLabel(status),
                  style: TextStyle(
                    color: _permissionStatusColor(status, scheme),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: !_hasAgreed ||
                          _permissionsLoading ||
                          _requestingPermission
                      ? null
                      : () => _requestPermission(item.permission),
                  child: Text(needsSettings ? '去设置' : '允许'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 4, bottom: 4),
              child: Text(
                item.fullAccessHint
                    ? '${item.description} 请在系统弹窗中选择“允许完全访问”。'
                    : item.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (needsSettings)
              Padding(
                padding: const EdgeInsets.only(left: 36, right: 4, bottom: 4),
                child: Text(
                  item.fullAccessHint && status?.isLimited == true
                      ? '当前是有限访问，请在系统设置中改为“允许完全访问”。'
                      : '当前未授权，使用相关功能时仍会再次请求。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                ),
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
    if (status?.isGranted == true) return Colors.green;
    if (status?.isDenied == true ||
        status?.isPermanentlyDenied == true ||
        status?.isRestricted == true) {
      return scheme.error;
    }
    return scheme.onSurfaceVariant;
  }

  Widget _buildStep(BuildContext context, _OnboardingStepData step) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 58, color: scheme.primary),
          ),
          const SizedBox(height: 26),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          ...step.bullets.map(
            (bullet) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_outline, color: scheme.primary),
              title: Text(bullet),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepData {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;

  const _OnboardingStepData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
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
