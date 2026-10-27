import 'package:flutter/material.dart';
import '../entity/FeatureModels.dart';

/// Hub 分组与首页搜索共用的分类定义；标题同时是现有收藏的键。
class FeatureSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> titles;

  const FeatureSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.titles});
}

/// 五个功能 Hub 的统一目录；首页保留收藏与快捷访问。
class FeatureRegistry {
  FeatureRegistry._();

  static const Map<String, List<FeatureSection>> sections = {
    '曲库': [
      FeatureSection(
          title: '乐曲检索',
          subtitle: '搜索国服与非国服曲库',
          icon: Icons.search_rounded,
          titles: ['乐曲查询', '非国服乐曲查询']),
      FeatureSection(
          title: '版本与曲库分析',
          subtitle: '版本资料、更新对照与谱面定数',
          icon: Icons.library_books_outlined,
          titles: ['国服更新对照', '版本对照', '定数分布']),
      FeatureSection(
          title: '图像识别',
          subtitle: '通过曲绘找歌，识别结算成绩',
          icon: Icons.image_search_outlined,
          titles: ['曲绘识别', '结算画面识别']),
      FeatureSection(
          title: '收藏品图鉴',
          subtitle: '浏览头像、姓名框等游戏收藏品',
          icon: Icons.collections_bookmark_outlined,
          titles: ['收藏品查询']),
    ],
    '成绩': [
      FeatureSection(
          title: '查询与筛选',
          subtitle: '浏览成绩，按条件查找谱面表现',
          icon: Icons.search_rounded,
          titles: ['成绩查询', '个性化成绩查询']),
      FeatureSection(
          title: '成长与对比',
          subtitle: '回顾提升记录，对比好友成绩',
          icon: Icons.auto_graph_rounded,
          titles: ['成绩提升历史', 'Rating 历史', '好友对比']),
      FeatureSection(
          title: 'Best50 概览',
          subtitle: '当前表现与拟合潜力',
          icon: Icons.analytics_outlined,
          titles: ['Best50', '拟合 Best50']),
      FeatureSection(
          title: '个性化分析',
          subtitle: '按标签和条件筛选 Best50',
          icon: Icons.tune_rounded,
          titles: ['个性化 Best50', '个性化拟合 Best50']),
      FeatureSection(
          title: '目标与制图',
          subtitle: '模拟理想成绩，制作自定义成绩图',
          icon: Icons.edit_note_rounded,
          titles: ['理想 Best50', '自定义 Best50']),
      FeatureSection(
          title: 'Rating 排名',
          subtitle: '官方 Rating 与拟合 Rating 排行',
          icon: Icons.leaderboard_outlined,
          titles: ['Rating 排行榜', '拟合总Rating排行榜']),
      FeatureSection(
          title: '达成率排名',
          subtitle: '比较全量成绩的平均表现',
          icon: Icons.percent_rounded,
          titles: ['平均达成率排行榜', '平均DX分数达成率排行榜']),
      FeatureSection(
          title: '特殊排名',
          subtitle: '探索不同角度的玩家数据',
          icon: Icons.workspace_premium_outlined,
          titles: ['特殊排行榜']),
      FeatureSection(
          title: '进度与挑战',
          subtitle: '牌子、段位与 KALEIDXSCOPE',
          icon: Icons.flag_outlined,
          titles: ['牌子进度', '段位表', 'KALEIDXSCOPE']),
      FeatureSection(
          title: '数值计算',
          subtitle: 'Rating、达成率与判定反推',
          icon: Icons.calculate_outlined,
          titles: ['单曲 Rating 计算', '达成率计算', '达成率反推']),
    ],
    '出勤': [
      FeatureSection(
          title: '随机选曲',
          subtitle: '决定今天玩什么',
          icon: Icons.shuffle_rounded,
          titles: ['每日推荐', '随机乐曲', '出勤转盘']),
      FeatureSection(
          title: '练习推荐',
          subtitle: '围绕收益、标签、目标与定数挑谱',
          icon: Icons.trending_up_rounded,
          titles: ['吃分推荐', '基于标签推荐', '基于目标 Rating 推荐', '基于定数区间推荐']),
      FeatureSection(
          title: '收藏与待玩',
          subtitle: '整理谱面，准备下次出勤',
          icon: Icons.queue_music_rounded,
          titles: ['收藏夹', '下次想玩']),
      FeatureSection(
          title: '机厅地图',
          subtitle: '查找国内与全球音游机厅',
          icon: Icons.map_outlined,
          titles: ['全国音游地图', '全球音游街机地图']),
    ],
    '休闲': [
      FeatureSection(
          title: '单人游戏设置',
          subtitle: '统一管理各模式的规则与偏好',
          icon: Icons.tune_rounded,
          titles: ['单人猜歌游戏设置']),
      FeatureSection(
          title: '文字线索',
          subtitle: '凭记忆、别名与字母线索猜歌',
          icon: Icons.text_fields_rounded,
          titles: ['无提示猜歌', '根据别名猜歌', '舞萌开字母']),
      FeatureSection(
          title: '曲绘辨识',
          subtitle: '观察局部、模糊、快闪与拼图曲绘',
          icon: Icons.image_outlined,
          titles: ['根据部分曲绘猜歌', '根据模糊曲绘猜歌', '曲绘快闪猜歌', '曲绘拼图猜歌']),
      FeatureSection(
          title: '音频辨识',
          subtitle: '通过原速、倒放或变调片段辨认歌曲',
          icon: Icons.headphones_outlined,
          titles: ['根据歌曲片段猜歌', '倒放音频猜歌', '变速变调猜歌']),
      FeatureSection(
          title: '谱面辨识',
          subtitle: '根据无声谱面片段猜歌',
          icon: Icons.graphic_eq_rounded,
          titles: ['谱面片段猜歌']),
      FeatureSection(
          title: '多人联机',
          subtitle: '与朋友一起挑战曲库',
          icon: Icons.groups_outlined,
          titles: ['多人猜歌游戏']),
      FeatureSection(
          title: '音乐与谱面播放',
          subtitle: '听舞萌歌曲，播放自定义谱面',
          icon: Icons.play_circle_outline_rounded,
          titles: ['随身听', '自定义谱面播放']),
    ],
    '我的': [
      FeatureSection(
          title: '账号与授权',
          subtitle: '管理账号与数据源登录状态',
          icon: Icons.manage_accounts_outlined,
          titles: ['账号注册引导', '账号管理', '登录 maimai Score Hub', '登录水鱼']),
      FeatureSection(
          title: '单平台同步',
          subtitle: '分别同步成绩到各查分器',
          icon: Icons.cloud_sync_outlined,
          titles: ['同步成绩到水鱼', '同步成绩到落雪', '同步成绩到 AWMC NET']),
      FeatureSection(
          title: '批量与定时同步',
          subtitle: '多端同步与自动同步',
          icon: Icons.schedule_outlined,
          titles: ['同步成绩到多端', '自动同步']),
      FeatureSection(
          title: '数据刷新',
          subtitle: '更新成绩缓存与机台游玩次数',
          icon: Icons.refresh_rounded,
          titles: ['刷新数据', '刷新数据（高级）', '刷新机台游玩次数']),
      FeatureSection(
          title: '本地数据管理',
          subtitle: '备份数据，管理本地缓存',
          icon: Icons.storage_outlined,
          titles: ['数据备份', '缓存管理']),
      FeatureSection(
          title: '应用偏好',
          subtitle: '主题、交互与加载语录',
          icon: Icons.tune_rounded,
          titles: ['系统设置', '加载语录管理']),
      FeatureSection(
          title: '运行诊断',
          subtitle: '检查服务状态，导出运行日志',
          icon: Icons.network_check_rounded,
          titles: ['服务器状态', '打印日志']),
      FeatureSection(
          title: '社区动态',
          subtitle: '查看最近评论与评分',
          icon: Icons.forum_outlined,
          titles: ['最近评论', '最近评分']),
      FeatureSection(
          title: '版本与项目',
          subtitle: '版本更新、项目介绍与相关链接',
          icon: Icons.info_outline_rounded,
          titles: ['检查更新', '关于 APP', '访问官方网站', '查看友情链接']),
      FeatureSection(
          title: '反馈与支持',
          subtitle: '反馈问题、交流建议与支持开发',
          icon: Icons.support_agent_rounded,
          titles: ['问题反馈', '加入 QQ 群', '问卷调查', '支持开发者']),
    ],
  };

  /// 状态文案变化不改变功能的分类和收藏身份。
  static String canonicalTitle(String title) => switch (title) {
        '登出水鱼账号' || '登出账号' => '登录水鱼',
        '发现新版本' => '检查更新',
        _ => title,
      };

  static List<String> pathFor(ButtonCategory category, ButtonItem item) {
    final title = canonicalTitle(item.title);
    for (final section in sections[category.name] ?? const <FeatureSection>[]) {
      if (section.titles.contains(title)) {
        return [category.name, section.title, item.title];
      }
    }
    return [category.name, item.title];
  }

  static List<ButtonCategory> allCategories(bool isDivingFishLoggedIn) {
    final items = <String, ButtonItem>{
      '乐曲查询': const ButtonItem(
          icon: Icons.music_note, title: '乐曲查询', subtitle: '按歌名、别名、谱师和标签搜索'),
      '非国服乐曲查询': const ButtonItem(
          icon: Icons.travel_explore_rounded,
          title: '非国服乐曲查询',
          subtitle: '搜索与筛选非国服曲库'),
      '国服更新对照': const ButtonItem(
          icon: Icons.flag_rounded,
          title: '国服更新对照',
          subtitle: '看日服已上、国服还没上的曲目'),
      '版本对照': const ButtonItem(
          icon: Icons.compare_arrows, title: '版本对照', subtitle: '按版本整理可游玩曲目'),
      '定数分布': const ButtonItem(
          icon: Icons.bar_chart, title: '定数分布', subtitle: '查看谱面定数分布'),
      '曲绘识别': const ButtonItem(
          icon: Icons.image_search, title: '曲绘识别', subtitle: '用相机或图片快速找歌'),
      '结算画面识别': const ButtonItem(
          icon: Icons.document_scanner,
          title: '结算画面识别',
          subtitle: '拍摄机台结算画面，自动识别成绩'),
      '收藏品查询': const ButtonItem(
          icon: Icons.collections_bookmark,
          title: '收藏品查询',
          subtitle: '查看头像、姓名框等收藏品'),
      '成绩查询': const ButtonItem(
          icon: Icons.score, title: '成绩查询', subtitle: '浏览全部游玩记录与筛选结果'),
      '个性化成绩查询': const ButtonItem(
          icon: Icons.grading_rounded,
          title: '个性化成绩查询',
          subtitle: '按等级或谱师查看成绩'),
      '成绩提升历史': const ButtonItem(
          icon: Icons.auto_graph_rounded,
          title: '成绩提升历史',
          subtitle: '按日回顾最佳成绩的变化与提升'),
      'Rating 历史': const ButtonItem(
          icon: Icons.timeline_rounded,
          title: 'Rating 历史',
          subtitle: '看 Rating 随时间的变化'),
      '好友对比': const ButtonItem(
          icon: Icons.people, title: '好友对比', subtitle: '看看你和好友的成绩差异'),
      'Best50': const ButtonItem(
          icon: Icons.leaderboard,
          title: 'Best50',
          subtitle: '查看当前 Best35 与 Best15'),
      '拟合 Best50': const ButtonItem(
          icon: Icons.analytics,
          title: '拟合 Best50',
          subtitle: '分析潜在 Rating 上限'),
      '个性化 Best50': const ButtonItem(
          icon: Icons.person_search_outlined,
          title: '个性化 Best50',
          subtitle: '按标签筛选 Best50'),
      '个性化拟合 Best50': const ButtonItem(
          icon: Icons.analytics_outlined,
          title: '个性化拟合 Best50',
          subtitle: '按标签查看拟合 Rating 上限'),
      '理想 Best50': const ButtonItem(
          icon: Icons.auto_fix_high_rounded,
          title: '理想 Best50',
          subtitle: '全员升一档后的 Best50 模拟'),
      '自定义 Best50': const ButtonItem(
          icon: Icons.edit_note_rounded,
          title: '自定义 Best50',
          subtitle: '手动填写 50 张成绩卡片'),
      'Rating 排行榜': const ButtonItem(
          icon: Icons.leaderboard,
          title: 'Rating 排行榜',
          subtitle: '查看玩家 Rating 排行'),
      '拟合总Rating排行榜': const ButtonItem(
          icon: Icons.auto_graph_rounded,
          title: '拟合总Rating排行榜',
          subtitle: '查看拟合总 Rating 与官方 Best50 差值'),
      '平均达成率排行榜': const ButtonItem(
          icon: Icons.percent, title: '平均达成率排行榜', subtitle: '按全量成绩的平均达成率排名'),
      '平均DX分数达成率排行榜': const ButtonItem(
          icon: Icons.score_outlined,
          title: '平均DX分数达成率排行榜',
          subtitle: '按全量成绩的平均DX得分达成率排名'),
      '特殊排行榜': const ButtonItem(
          icon: Icons.leaderboard_outlined,
          title: '特殊排行榜',
          subtitle: '发现有趣的玩家数据'),
      '牌子进度': const ButtonItem(
          icon: Icons.wysiwyg_rounded, title: '牌子进度', subtitle: '查看各版本与目标牌子'),
      '段位表': const ButtonItem(
          icon: Icons.arrow_circle_up, title: '段位表', subtitle: '挑战你的下一段位'),
      'KALEIDXSCOPE': const ButtonItem(
          icon: Icons.door_back_door,
          title: 'KALEIDXSCOPE',
          subtitle: '探索独特的舞萌玩法'),
      '单曲 Rating 计算': const ButtonItem(
          icon: Icons.calculate,
          title: '单曲 Rating 计算',
          subtitle: '根据达成率计算单首 rating'),
      '达成率计算': const ButtonItem(
          icon: Icons.percent, title: '达成率计算', subtitle: '根据判定详情算出达成率'),
      '达成率反推': const ButtonItem(
          icon: Icons.replay, title: '达成率反推', subtitle: '根据判定详情推出绝赞详情'),
      '每日推荐': const ButtonItem(
          icon: Icons.today, title: '每日推荐', subtitle: '今天打什么？交给推荐'),
      '随机乐曲': const ButtonItem(
          icon: Icons.shuffle, title: '随机乐曲', subtitle: '自定义数量随机抽取歌曲'),
      '出勤转盘': const ButtonItem(
          icon: Icons.casino_outlined, title: '出勤转盘', subtitle: '等分转盘决定本次出勤选项'),
      '吃分推荐': const ButtonItem(
          icon: Icons.rocket_launch_rounded,
          title: '吃分推荐',
          subtitle: '按 B50 净收益挑谱 · AWMC 提供算法支持'),
      '基于标签推荐': const ButtonItem(
          icon: Icons.label, title: '基于标签推荐', subtitle: '基于你的游玩谱面标签推荐曲目'),
      '基于目标 Rating 推荐': const ButtonItem(
          icon: Icons.trending_up,
          title: '基于目标 Rating 推荐',
          subtitle: '寻找适合上分的谱面'),
      '基于定数区间推荐': const ButtonItem(
          icon: Icons.tune, title: '基于定数区间推荐', subtitle: '按定数范围挑选谱面'),
      '收藏夹': const ButtonItem(
          icon: Icons.favorite, title: '收藏夹', subtitle: '管理你收藏的谱面'),
      '下次想玩': const ButtonItem(
          icon: Icons.queue_music, title: '下次想玩', subtitle: '排好下次去机台想玩的歌曲'),
      '全国音游地图': const ButtonItem(
          icon: Icons.map, title: '全国音游地图', subtitle: '看看哪里有你想玩的机台'),
      '全球音游街机地图': const ButtonItem(
          icon: Icons.public,
          title: '全球音游街机地图',
          subtitle: '查看 NearCade 全球街机店铺'),
      '单人猜歌游戏设置': const ButtonItem(
          icon: Icons.tune_rounded,
          title: '单人猜歌游戏设置',
          subtitle: '管理共用规则和各模式设置'),
      '无提示猜歌': const ButtonItem(
          icon: Icons.gamepad, title: '无提示猜歌', subtitle: '凭记忆挑战曲库'),
      '根据别名猜歌': const ButtonItem(
          icon: Icons.gamepad, title: '根据别名猜歌', subtitle: '用别名挑战你的熟悉度'),
      '舞萌开字母': const ButtonItem(
          icon: Icons.gamepad, title: '舞萌开字母', subtitle: '看首字母猜歌'),
      '根据部分曲绘猜歌': const ButtonItem(
          icon: Icons.gamepad, title: '根据部分曲绘猜歌', subtitle: '看一小块曲绘猜出歌曲'),
      '根据模糊曲绘猜歌': const ButtonItem(
          icon: Icons.gamepad, title: '根据模糊曲绘猜歌', subtitle: '根据模糊化处理后的曲绘猜歌'),
      '曲绘快闪猜歌': const ButtonItem(
          icon: Icons.flash_on_outlined,
          title: '曲绘快闪猜歌',
          subtitle: '曲绘一闪而过，凭记忆猜歌'),
      '曲绘拼图猜歌': const ButtonItem(
          icon: Icons.grid_on_outlined,
          title: '曲绘拼图猜歌',
          subtitle: '曲绘碎块随时间逐步拼合显现'),
      '根据歌曲片段猜歌': const ButtonItem(
          icon: Icons.gamepad, title: '根据歌曲片段猜歌', subtitle: '截取音源片段猜歌'),
      '倒放音频猜歌': const ButtonItem(
          icon: Icons.fast_rewind_rounded,
          title: '倒放音频猜歌',
          subtitle: '听倒放歌曲片段猜歌'),
      '变速变调猜歌': const ButtonItem(
          icon: Icons.speed_rounded, title: '变速变调猜歌', subtitle: '根据变速变调的音频猜歌'),
      '谱面片段猜歌': const ButtonItem(
          icon: Icons.graphic_eq_outlined,
          title: '谱面片段猜歌',
          subtitle: '看一段无声谱面动画猜出歌曲'),
      '多人猜歌游戏': const ButtonItem(
          icon: Icons.gamepad, title: '多人猜歌游戏', subtitle: '和朋友一起猜舞萌曲库'),
      '随身听': const ButtonItem(
          icon: Icons.headphones, title: '随身听', subtitle: '后台播放舞萌曲库，带通知栏播放器'),
      '自定义谱面播放': const ButtonItem(
          icon: Icons.play_arrow, title: '自定义谱面播放', subtitle: '播放本地自定义谱面'),
      '账号管理': const ButtonItem(
          icon: Icons.manage_accounts, title: '账号管理', subtitle: '查看已绑定的水鱼账号信息'),
      '账号注册引导': const ButtonItem(
          icon: Icons.person_add_alt_1_outlined,
          title: '账号注册引导',
          subtitle: '水鱼注册、落雪注册与 AWMC NET 档案创建引导'),
      '登录 maimai Score Hub': const ButtonItem(
          icon: Icons.login_rounded,
          title: '登录 maimai Score Hub',
          subtitle: '仅登录，不同步成绩；用于 OCR 与 maimai Score Hub 功能'),
      '登录水鱼': isDivingFishLoggedIn
          ? const ButtonItem(
              icon: Icons.logout, title: '登出水鱼账号', subtitle: '清除水鱼登录状态')
          : const ButtonItem(
              icon: Icons.login,
              title: '登录水鱼',
              subtitle: '获取 ImportToken 以使用同步功能'),
      '同步成绩到水鱼': const ButtonItem(
          icon: Icons.qr_code_scanner,
          title: '同步成绩到水鱼',
          subtitle: '扫码抓取并同步最新成绩'),
      '同步成绩到落雪': const ButtonItem(
          icon: Icons.cloud_sync, title: '同步成绩到落雪', subtitle: '将本地成绩同步到落雪咖啡屋'),
      '同步成绩到 AWMC NET': const ButtonItem(
          icon: Icons.cloud_upload_outlined,
          title: '同步成绩到 AWMC NET',
          subtitle: '用机台二维码导入成绩到 AWMC NET'),
      '同步成绩到多端': const ButtonItem(
          icon: Icons.devices_other_outlined,
          title: '同步成绩到多端',
          subtitle: '一份成绩同步到多个查分器'),
      '自动同步': const ButtonItem(
          icon: Icons.schedule_outlined,
          title: '自动同步',
          subtitle: '每天北京时间 0 点和 12 点自动快速同步'),
      '刷新数据': const ButtonItem(
          icon: Icons.file_upload_sharp,
          title: '刷新数据',
          subtitle: '重新拉取并初始化所有本地缓存'),
      '刷新数据（高级）': const ButtonItem(
          icon: Icons.tune_rounded,
          title: '刷新数据（高级）',
          subtitle: '按缓存源勾选强制刷新，并测试各 API 连通性'),
      '刷新机台游玩次数': const ButtonItem(
          icon: Icons.numbers_outlined,
          title: '刷新机台游玩次数',
          subtitle: '单独读取当前账号的 PC 数；不会附带同步成绩'),
      '数据备份': const ButtonItem(
          icon: Icons.backup, title: '数据备份', subtitle: '导入或导出本地数据'),
      '缓存管理': const ButtonItem(
          icon: Icons.storage_outlined,
          title: '缓存管理',
          subtitle: '查看并清理音源、PV、maidata 缓存'),
      '系统设置': const ButtonItem(
          icon: Icons.dark_mode, title: '系统设置', subtitle: '调整主题、背景图、交互与同步选项'),
      '加载语录管理': const ButtonItem(
          icon: Icons.format_quote, title: '加载语录管理', subtitle: '选择加载时展示的语录'),
      '服务器状态': const ButtonItem(
          icon: Icons.network_check, title: '服务器状态', subtitle: '查看舞萌服务状态'),
      '打印日志': const ButtonItem(
          icon: Icons.receipt_long_outlined,
          title: '打印日志',
          subtitle: '导出最近运行日志，方便排查问题'),
      '最近评论': const ButtonItem(
          icon: Icons.comment, title: '最近评论', subtitle: '查看社区最近评论'),
      '最近评分': const ButtonItem(
          icon: Icons.star, title: '最近评分', subtitle: '查看社区最近评分'),
      '检查更新': const ButtonItem(
          icon: Icons.update, title: '检查更新', subtitle: '检查应用是否有新版本'),
      '关于 APP': const ButtonItem(
          icon: Icons.info_outline, title: '关于 APP', subtitle: '了解项目与版本信息'),
      '访问官方网站': const ButtonItem(
          icon: Icons.public,
          title: '访问官方网站',
          subtitle: '前往 chiffonmai.cloud 查看项目主页'),
      '查看友情链接': const ButtonItem(
        icon: Icons.link,
        title: '查看友情链接',
        subtitle: '发现同好项目',
      ),
      '问题反馈': const ButtonItem(
          icon: Icons.feedback_outlined, title: '问题反馈', subtitle: '反馈使用中遇到的问题'),
      '加入 QQ 群': const ButtonItem(
          icon: Icons.groups_outlined, title: '加入 QQ 群', subtitle: '一键跳转官方交流群'),
      '问卷调查': const ButtonItem(
          icon: Icons.poll_outlined,
          title: '问卷调查',
          subtitle: '助力 ChiffonMai 更上一层楼'),
      '支持开发者': const ButtonItem(
          icon: Icons.volunteer_activism, title: '支持开发者', subtitle: '支持项目持续更新'),
    };
    return [
      for (final category in sections.entries)
        ButtonCategory(
          name: category.key,
          icon: switch (category.key) {
            '曲库' => Icons.library_music_rounded,
            '成绩' => Icons.analytics_rounded,
            '出勤' => Icons.explore_rounded,
            '休闲' => Icons.sports_esports_rounded,
            '我的' => Icons.person_rounded,
            _ => Icons.apps_rounded,
          },
          items: [
            for (final section in category.value)
              for (final title in section.titles) items[title]!,
          ],
        ),
    ];
  }
}
