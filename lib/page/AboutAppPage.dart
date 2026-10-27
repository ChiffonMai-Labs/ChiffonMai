import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api/ApiUrls.dart';
import '../utils/CommonWidgetUtil.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../widgets/PageTopBar.dart';
import '../widgets/AppLauncherIcon.dart';
import 'LegalDocumentPage.dart';

/// 关于页：品牌介绍、维护者与致谢分组直接布局在主题背景上。
class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

/// 一条致谢记录
class _Credit {
  /// 名称（有 [url] 时可点击）
  final String name;

  /// 贡献说明
  final String desc;

  /// 可选的跳转链接
  final String? url;

  /// 可选的头像代理 key（后端白名单），为空时使用分组默认图标
  final String? avatarKey;

  const _Credit(this.name, this.desc, [this.url, this.avatarKey]);
}

class _AboutAppPageState extends State<AboutAppPage> {
  // ---------------------------------------------------------------------------
  // 开发者信息
  // ---------------------------------------------------------------------------
  static const String _developerName = 'ChiffonOwO';
  static const String _email = 'chiffonowo@foxmail.com';
  static const String _bilibiliUrl = 'https://space.bilibili.com/442305158';
  static const String _githubUrl = 'https://github.com/ChiffonOwO';

  static const String _intro =
      'ChiffonMai 是一款专为 舞萌DX 2026（maimai DX 2026）玩家打造的一站式移动端工具类应用，'
      '聚合了曲库查询、成绩统计、Rating 计算、曲目推荐等多种实用功能，助力玩家提升游玩体验。';

  /// 创作与支持（排名不分先后）。
  static const List<_Credit> _creativeCredits = [
    _Credit('Xn1xUfguF1GiNg', '为本项目提供的背景图和戚风小狐狸（真的非常可爱）',
        'https://huajia.163.com/main/profile/RrwM5xQB'),
    _Credit('Takanashi Rikkkkkkka', '为本项目的个性化谱面推荐功能提供宝贵设计思路'),
    _Credit('三由yyyh', '为本项目的页面设计提供了宝贵意见'),
    _Credit('MYD', '提供了用于测试开发的个人游玩数据'),
    _Credit('乐观的熊猫', '提议开发 ChiffonMai，为本项目诞生提供最初契机',
        'https://space.bilibili.com/438391224'),
    _Credit('迪拉熊重度依赖', '为本项目在前端细节与交互体验上提供了诸多宝贵建议',
        'https://github.com/Timome-Sudo', 'dilaxiong'),
    _Credit('Michaelwucoc', '为本项目的开发提供了技术支持和经济支持，为项目的推进提供了极大的帮助',
        'https://github.com/Michaelwucoc'),
    _Credit('ChiffonMai交流群的全体群友', '为本项目开发提供了诸多宝贵建议和反馈'),
  ];

  /// 数据与服务（排名不分先后）。
  static const List<_Credit> _dataCredits = [
    _Credit('水鱼查分器', '提供曲目数据库和玩家游玩记录数据库',
        'https://www.diving-fish.com/maimaidx/prober/'),
    _Credit('DXRating.net', '提供谱面标签数据库和别名数据库', 'https://dxrating.net'),
    _Credit('Yuri-YuzuChaN', '提供别名数据库',
        'https://github.com/Yuri-YuzuChaN/maimaiDX'),
    _Credit(
        '落雪咖啡屋', '提供收藏品数据库、歌曲音源支持、曲目数据库和玩家游玩记录数据库', 'https://maimai.lxns.net'),
    _Credit('Neskol', '提供谱面转换支持',
        'https://github.com/Neskol/Maichart-Converts/tree/master'),
    _Credit('status.awmc.cc', '提供舞萌服务器状态信息',
        'https://status.awmc.cc/status/maimai'),
    _Credit('mai.chongxi.us', '提供舞萌服务器状态信息', 'https://mai.chongxi.us/'),
    _Credit('AWMC NET.', '提供水鱼查分器同步支持、落雪查分器同步支持和对本项目开发的经济支持',
        'https://net.wmc.pub/'),
    _Credit('Bakapiano', '提供水鱼查分器和落雪查分器成绩同步支持',
        'https://github.com/bakapiano/maimai-score-hub'),
    _Credit('k4641321', '提供落雪查分器成绩同步支持',
        'https://github.com/k4641321/chusearchsong_flutter/tree/master'),
    _Credit('Union', '提供曲目数据库', 'https://union.godserver.cn/'),
    _Credit('NearCade', '提供全球机厅相关数据', 'https://nearcade.cn/'),
    _Credit('SilentBlue.RemyWiki', '提供高清版本图片',
        'https://silentblue.remywiki.com/Main_Page'),
  ];

  /// 设计思路借鉴，排名不分先后。
  static const List<_Credit> _designCredits = [
    _Credit('EasyMai', '设计思路借鉴', 'https://github.com/Lista233/EasyMai'),
    _Credit('舞萌猜猜呗之潘一把', '设计思路借鉴',
        'https://github.com/yukineko2233/v0-maimai-wordle'),
    _Credit(
        'MaiScan Rev', '设计思路借鉴', 'https://github.com/PojavAnge/MaiScan-Rev'),
    _Credit(
        '中二查歌', '设计思路借鉴', 'https://github.com/k4641321/chusearchsong_flutter'),
  ];

  /// 捐献支持名单。带了 [avatarKey] 的会通过后端头像代理显示 QQ 头像。
  static const List<_Credit> _donationCredits = [
    _Credit('Pokcet', '感谢对本项目的捐献支持'),
    _Credit('ListaQwQ', '感谢对本项目的捐献支持'),
    _Credit('迪拉熊重度依赖', '感谢对本项目的捐献支持', null, 'dilaxiong'),
    _Credit('白嫖万岁', '感谢对本项目的捐献支持'),
    _Credit('鱼好呆', '感谢对本项目的捐献支持'),
    _Credit('Rinviolet', '感谢对本项目的捐献支持', null, 'rinviolet'),
    _Credit('Redapple_one', '感谢对本项目的捐献支持', 'https://me.redapple.one',
        'redapple_one'),
  ];

  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.buildNumber.isEmpty
            ? 'v${info.version}'
            : 'v${info.version}+${info.buildNumber}';
      });
    } catch (e) {
      debugPrint('[AboutAppPage] 读取版本号失败: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await ExternalLaunchUtil.open(uri)) {
        return;
      }
    } catch (e) {
      debugPrint('[AboutAppPage] 打开链接失败: $e');
    }
    Fluttertoast.showToast(msg: '无法打开链接：$url');
  }

  /// 邮箱优先走邮件客户端；没有可用客户端时退回「复制到剪贴板」，
  /// 保证用户在任何设备上都能拿到地址。
  Future<void> _openEmail() async {
    final uri = Uri(scheme: 'mailto', path: _email);
    try {
      if (await ExternalLaunchUtil.open(uri)) {
        return;
      }
    } catch (e) {
      debugPrint('[AboutAppPage] 打开邮件客户端失败: $e');
    }
    await Clipboard.setData(const ClipboardData(text: _email));
    Fluttertoast.showToast(msg: '邮箱已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 异步背景图显示前先铺主题底色，避免进入页面时闪黑。
          Positioned.fill(child: ColoredBox(color: scheme.surface)),
          CommonWidgetUtil.buildCommonBgWidget(),
          CommonWidgetUtil.buildCommonChiffonBgWidget(context),
          Column(
            children: [
              const PageTopBar(
                title: '关于',
                barBackground: Colors.transparent,
                titleAlign: PageTopBarTitleAlign.start,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(20, 12, 20, 28 + safeBottom),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAppHeader(),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final document in AppLegalDocument.values)
                                  TextButton.icon(
                                    onPressed: () => LegalDocumentPage.open(
                                        context, document),
                                    icon: Icon(
                                        document ==
                                                AppLegalDocument.userAgreement
                                            ? Icons.description_outlined
                                            : Icons.privacy_tip_outlined,
                                        size: 18),
                                    label: Text(document.title),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            _buildSectionTitle('维护者', 'ChiffonMai 背后的开发者。'),
                            _buildDeveloperSection(),
                            const SizedBox(height: 32),
                            _buildSectionTitle('特别致谢', '感谢每一位给予帮助的伙伴，排名不分先后。'),
                            _buildCreditGroup(
                              title: '创作与支持',
                              icon: Icons.favorite_outline_rounded,
                              credits: _creativeCredits,
                              personal: true,
                            ),
                            const SizedBox(height: 24),
                            _buildCreditGroup(
                              title: '捐献致谢',
                              icon: Icons.volunteer_activism_outlined,
                              credits: _donationCredits,
                              personal: true,
                            ),
                            const SizedBox(height: 24),
                            _buildCreditGroup(
                              title: '数据与服务',
                              icon: Icons.hub_outlined,
                              credits: _dataCredits,
                              personal: false,
                            ),
                            const SizedBox(height: 24),
                            _buildCreditGroup(
                              title: '设计思路借鉴',
                              icon: Icons.lightbulb_outline_rounded,
                              credits: _designCredits,
                              personal: false,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              '感谢每一份支持，让 ChiffonMai 不断成长。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 品牌信息直接排在背景上，仅版本号和功能标签有局部填充。
  Widget _buildAppHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLauncherIcon(size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ChiffonMai',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '陪伴每一次舞萌出勤',
                    style:
                        TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            _version.isEmpty ? '版本读取中…' : '版本 $_version',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _intro,
          style:
              TextStyle(fontSize: 13.5, height: 1.7, color: scheme.onSurface),
        ),
        const SizedBox(height: 12),
        SelectableText(
          'APP备案号：津ICP备2024015256号-3A',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          header: true,
          child: Text(title,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              )),
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                fontSize: 13, height: 1.5, color: scheme.onSurfaceVariant)),
      ]),
    );
  }

  /// 局部主题色块代替整页白色容器，圆角与参考图中的人物区域保持一致。
  Widget _buildDeveloperSection() {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: scheme.primaryContainer,
              child: ClipOval(
                child: CachedNetworkImage(
                  // 仅请求自家后端；腾讯请求头、限频和 24 小时磁盘缓存均由后端处理。
                  imageUrl: ApiUrls.MaintainerAvatarUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  memCacheWidth:
                      (50 * MediaQuery.devicePixelRatioOf(context)).round(),
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => Icon(
                      Icons.person_outline_rounded,
                      size: 28,
                      color: scheme.onPrimaryContainer),
                  errorWidget: (context, url, error) => Icon(
                      Icons.person_outline_rounded,
                      size: 28,
                      color: scheme.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_developerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      )),
                  const SizedBox(height: 3),
                  Text('开发与维护',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSecondaryContainer)),
                ])),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _buildContactButton(Icons.play_circle_outline_rounded, 'B 站',
                () => _openUrl(_bilibiliUrl)),
            _buildContactButton(
                FontAwesomeIcons.github, 'GitHub', () => _openUrl(_githubUrl)),
            _buildContactButton(Icons.email_outlined, '邮箱', _openEmail),
          ]),
          const SizedBox(height: 8),
          SelectableText(_email,
              style:
                  TextStyle(fontSize: 12, color: scheme.onSecondaryContainer)),
        ]),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        foregroundColor: scheme.primary,
        backgroundColor: scheme.surface.withValues(alpha: .45),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const StadiumBorder(),
      ),
    );
  }

  Widget _buildCreditGroup({
    required String title,
    required IconData icon,
    required List<_Credit> credits,
    required bool personal,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 7),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary)),
        ]),
      ),
      for (var i = 0; i < credits.length; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == credits.length - 1 ? 0 : 4),
          child: _buildCreditRow(
            credits[i],
            personal: personal,
            radius: BorderRadius.vertical(
              top: Radius.circular(i == 0 ? 24 : 6),
              bottom: Radius.circular(i == credits.length - 1 ? 24 : 6),
            ),
          ),
        ),
    ]);
  }

  Widget _buildCreditRow(
    _Credit credit, {
    required bool personal,
    required BorderRadius radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tappable = credit.url != null;
    return Material(
      color: scheme.secondaryContainer.withValues(alpha: .6),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tappable ? () => _openUrl(credit.url!) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: _buildCreditAvatar(credit, personal: personal),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(credit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      )),
                  const SizedBox(height: 5),
                  Text(credit.desc,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: scheme.onSecondaryContainer,
                      )),
                ])),
            if (tappable) ...[
              const SizedBox(width: 10),
              Icon(Icons.open_in_new_rounded, size: 19, color: scheme.primary),
            ],
          ]),
        ),
      ),
    );
  }

  /// 配置了头像代理 key 的条目显示真实头像；加载中/失败/未配置时退回默认图标。
  Widget _buildCreditAvatar(_Credit credit, {required bool personal}) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      _creditIcon(credit, personal: personal),
      size: 22,
      color: scheme.onPrimaryContainer,
    );
    final key = credit.avatarKey;
    if (key == null) return icon;
    // 与维护者头像保持同一尺寸比例（CircleAvatar 半径 22 → 直径 44）。
    const size = 44.0;
    return ClipOval(
      child: CachedNetworkImage(
        // 仅请求自家后端；QQ 请求头、限频和 24 小时磁盘缓存均由后端处理。
        imageUrl: ApiUrls.AboutAvatarUrl(key),
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => icon,
        errorWidget: (context, url, error) => icon,
      ),
    );
  }

  /// 未配置头像代理的创作与支持、捐献名单使用统一默认头像；服务类致谢按链接性质区分图标。
  IconData _creditIcon(_Credit credit, {required bool personal}) {
    final url = credit.url?.toLowerCase() ?? '';
    final name = credit.name.toLowerCase();
    if (Uri.tryParse(url)?.host == 'github.com') return FontAwesomeIcons.github;
    if (personal) return Icons.person_rounded;
    if (url.contains('bilibili.com') || url.contains('huajia.163.com')) {
      return Icons.play_circle_outline_rounded;
    }
    if (url.contains('status.') || url.contains('mai.chongxi.us')) {
      return Icons.monitor_heart_outlined;
    }
    if (url.contains('diving-fish.com') ||
        url.contains('lxns.net') ||
        url.contains('union.godserver.cn') ||
        name.contains('查分器') ||
        name.contains('曲目数据库')) {
      return Icons.storage_rounded;
    }
    if (url.contains('dxrating.net')) return Icons.insights_outlined;
    if (url.contains('wmc.pub')) return Icons.cloud_sync_outlined;
    return Icons.language_rounded;
  }
}
