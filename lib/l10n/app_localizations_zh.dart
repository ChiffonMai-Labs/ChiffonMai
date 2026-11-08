// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get autoUpdateSuccessTitle => '自动更新成功';

  @override
  String get autoUpdateSuccessBody => 'ChiffonMai 已在后台完成更新，可以继续使用啦。';

  @override
  String get autoUpdateChangesTitle => '本次更新内容';

  @override
  String get settingsTitle => '系统设置';

  @override
  String get appearance => '外观';

  @override
  String get interaction => '交互';

  @override
  String get effects => '特效';

  @override
  String get other => '其他';

  @override
  String get language => '语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get languageDescription =>
      '界面、提示与系统通知均已支持多语言；歌曲资料、服务端原文和用户内容保持原文。切换后立即生效。';

  @override
  String get languageSaveFailed => '语言设置保存失败，请重试';

  @override
  String get homeSearchScope => '首页搜索范围';

  @override
  String get searchFeatures => '功能';

  @override
  String get searchSongs => '歌曲';

  @override
  String get searchBoth => '功能+歌曲';

  @override
  String get searchMode => '搜索方式';

  @override
  String get searchInline => '原位输入';

  @override
  String get searchOverlay => '展开搜索';

  @override
  String get searchOverlayHint => '首页功能和歌曲搜索使用展开搜索界面（当前默认）';

  @override
  String get searchInlineHint => '直接在原搜索框输入，歌曲搜索历史显示在搜索框下方';

  @override
  String get showMatchInfo => '显示匹配字段';

  @override
  String get showMatchInfoHint => '在歌曲搜索结果里显示命中的定数、BPM、标签等信息';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeColor => '主题色';

  @override
  String get backgroundImage => '背景图';

  @override
  String get decorationImage => '装饰图';

  @override
  String get pureBlackBackgroundDisabled => '纯黑模式下背景图与装饰图调节不可用';

  @override
  String get reading => '读取中…';

  @override
  String get useSystemWallpaperColor => '使用系统壁纸配色';

  @override
  String get systemWallpaperHint => 'Android 12 及以上可用，点击后将当前系统配色应用为主题色。';

  @override
  String get wallpaperColorUnsupported => '系统壁纸配色需要 Android 12 或更新版本';

  @override
  String get wallpaperColorApplied => '已应用系统壁纸配色';

  @override
  String get wallpaperColorFailed => '暂时无法读取系统壁纸配色，请稍后重试';

  @override
  String get wallpaperApplied => '壁纸已设置';

  @override
  String get wallpaperAndThemeApplied => '壁纸已设置，主题色已更新';

  @override
  String get backgroundReset => '已恢复默认背景';

  @override
  String get themeColorUpdated => '主题色已更新';

  @override
  String get themeColorReset => '已恢复默认主题色';

  @override
  String get navigationExperience => '导航体验';

  @override
  String get searchInteraction => '搜索框交互';

  @override
  String get confetti => '纸屑特效';

  @override
  String get appUpdate => '应用更新';

  @override
  String get featureGuide => '功能引导';

  @override
  String get featureGuideHint => '想再看一遍各个功能在哪里，可以随时重新打开。';

  @override
  String get reopenGuide => '重新查看功能引导';

  @override
  String get preview => '预览效果';

  @override
  String get primaryButton => '主要按钮';

  @override
  String get primaryColor => '主色';

  @override
  String get secondaryColor => '辅助色';

  @override
  String get tertiaryColor => '强调色';

  @override
  String get surfaceColor => '背景色';

  @override
  String get customColor => '自定义颜色';

  @override
  String get restoreDefaults => '恢复默认';

  @override
  String get builtInBackground => '当前：内置背景';

  @override
  String get customBackground => '当前：自定义图片';

  @override
  String get processing => '处理中…';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get decorationOpacity => 'chiffon 装饰图透明度';

  @override
  String get decorationOpacityHint => '默认 40%。纯黑模式下自动隐藏；深浅模式共用同一透明度。';

  @override
  String get hide => '隐藏';

  @override
  String get favoriteExportExtension => '收藏夹导出后缀';

  @override
  String get syncAndGateway => '同步与网关';

  @override
  String get gatewayTimeout => 'AWMC 网关检测超时';

  @override
  String get gatewayTimeoutHint =>
      '线路1 同步前会先请求 GET /v1/health 探活；超过这个时间就取消同步（不消耗 Token）。';

  @override
  String get gatewayTimeoutDialogHint =>
      '线路1 同步前会先请求 GET /v1/health 探活；超过这个时间视为网关不可用，直接取消同步（不会消耗 Token）。';

  @override
  String get enterIntegerSeconds => '请输入整数秒数';

  @override
  String get timeout => '超时时间';

  @override
  String get secondsUnit => '秒';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get confirm => '确定';

  @override
  String get backgroundOpacity => '背景透明度';

  @override
  String get backgroundDarkHint => '数值越高背景越暗，0% 为原始背景图';

  @override
  String get backgroundLightHint => '数值越高背景越淡，0% 为原始背景图';

  @override
  String get lightMode => '浅色';

  @override
  String get darkMode => '深色';

  @override
  String get pureBlack => '纯黑背景';

  @override
  String get pureBlackHint => '使用真正的纯黑背景，隐藏背景图';

  @override
  String get navigationStyle => '导航栏样式';

  @override
  String get navigationClassic => '经典悬浮';

  @override
  String get navigationGlass => '液态玻璃';

  @override
  String get navigationPill => '伸缩胶囊';

  @override
  String get navigationClassicHint => '图标与文字上下排列，常驻显示全部分类名称';

  @override
  String get navigationGlassHint => '通透的玻璃质感，选中项带柔和高光';

  @override
  String get navigationPillHint => '选中项展开文字，其余项保留图标，切换时平滑伸缩';

  @override
  String get navigationAnimation => '导航栏切换动画';

  @override
  String get navigationAnimationHint => '切换主界面时使用淡入滑动过渡，并淡化图标状态';

  @override
  String get swipeNavigation => '左右滑动切换主界面';

  @override
  String get swipeNavigationHint => '在主界面内容区域左右滑动即可切换底部导航项';

  @override
  String get immersiveStatusBar => '沉浸式状态栏';

  @override
  String get immersiveStatusBarHint => '隐藏顶部时间、电量等状态信息，保留底部系统导航';

  @override
  String get busyHint => '任务进行中提示';

  @override
  String get busyHintDescription => '同步、刷新等任务进行中时，在不可用入口下方用红字说明原因';

  @override
  String get customHarmonyColor => '自定义调和颜色';

  @override
  String get confettiHint => '刷新数据或同步成绩成功后播放彩纸礼炮';

  @override
  String get gravityEffect => '重力效果';

  @override
  String get gravityEffectHint => '纸屑沿弧线飘落，向上喷出的纸屑会回落';

  @override
  String get harmonyColor => '调和颜色';

  @override
  String get harmonyLevel => '调和等级';

  @override
  String get harmonyHint => '数值越高，彩纸颜色越接近调和颜色；0% 保留鲜艳的多彩效果';

  @override
  String get paperType => '彩纸类型';

  @override
  String get paperMixed => '缤纷混彩';

  @override
  String get paperSquare => '方形纸片';

  @override
  String get paperCircle => '圆润纸片';

  @override
  String get paperRibbon => '轻盈彩带';

  @override
  String get burstPosition => '播放位置';

  @override
  String get burstTopBottom => '上下星落';

  @override
  String get burstLeftRight => '左右流彩';

  @override
  String get burstAllEdges => '四方礼花';

  @override
  String get previewNow => '立即播放预览';

  @override
  String get defaultDifficulty => '歌曲详情默认难度';

  @override
  String get defaultDifficultyHint => '从歌曲搜索等未指定难度的入口打开歌曲时，优先显示所选难度。';

  @override
  String get defaultDifficultyNote => '首次使用默认为 MASTER。成绩、谱面等已指定难度的跳转保持原有难度。';

  @override
  String get settingSaveFailed => '设置保存失败，请重试';

  @override
  String get autoInstall => '自动安装更新';

  @override
  String get experimental => '测试性';

  @override
  String get autoInstallHint =>
      '默认关闭，不会自动下载。仅对你主动选择的 App 内下载生效。安装包校验通过后：前台会先提示，确认后退到后台尝试安装；后台没有同步、刷新、导入导出或下载等任务持续 8 秒后自动尝试安装。任务开始或回到前台会重新计时。';

  @override
  String get autoInstallNote =>
      '需要 Android 12 及以上，并允许此来源安装应用。正在播放音乐或通话时会等待，无需锁屏。实际执行仍可能受系统调度影响，部分系统需要手动确认；延迟或失败时可手动安装。安装会结束旧进程，下次打开即为新版；关闭开关不能撤回系统已开始执行的安装。';

  @override
  String get autoInstallUnsupported => '当前系统不支持此测试功能，请手动安装更新。';

  @override
  String get allowInstallSource => '允许此来源安装应用';

  @override
  String get autoInstallSettingsError => '无法应用自动安装设置，请重试或检查系统安装权限';

  @override
  String get reloadSettings => '重新读取设置';

  @override
  String get hexFormatError => '格式应为 #RRGGBB 或 #AARRGGBB';

  @override
  String get enterHexColor => '输入十六进制颜色';

  @override
  String get hexColorHint => '#RRGGBB 或 #AARRGGBB';

  @override
  String get hue => '色相';

  @override
  String get colorPickerHint => '拖动上方方块选色，或直接输入十六进制';

  @override
  String get enterHex => '输入十六进制';

  @override
  String get wallpaperCropHint => '双指缩放、拖动，选择壁纸显示的范围';

  @override
  String get wallpaperReadFailed => '无法读取这张图片，当前系统可能不支持它的格式';

  @override
  String get wallpaperCropFailed => '裁剪失败，请重试';

  @override
  String get setWallpaper => '设为壁纸';

  @override
  String picturePickFailed(String error) {
    return '选择图片失败：$error';
  }

  @override
  String exportDescription(String extension) {
    return '导出收藏夹会生成 <名字>$extension 文件，放在 Download/ChiffonMai/收藏夹/ 下，文件管理器可以直接找到。\n后缀已固定：自定义后缀会把常见格式的默认打开方式抢过来，所以不再开放。\n导入按文件内容识别、与后缀无关，以前用别的后缀导出的备份照样能导回来。';
  }

  @override
  String secondsValue(int seconds) {
    return '$seconds 秒';
  }

  @override
  String gatewayTimeoutSemantics(int seconds) {
    return 'AWMC 网关检测超时，当前 $seconds 秒';
  }

  @override
  String gatewayTimeoutSaved(int seconds) {
    return 'AWMC 网关检测超时已设为 $seconds 秒';
  }

  @override
  String allowedSeconds(int min, int max) {
    return '允许 $min–$max 秒';
  }

  @override
  String defaultSecondsHint(int defaultSeconds, int min, int max) {
    return '默认 $defaultSeconds 秒，允许 $min–$max 秒';
  }

  @override
  String get foregroundUpdateTitle => '更新已准备好';

  @override
  String get foregroundUpdateBody =>
      '安装包已校验完成。选择“退出并更新”后，App 将退到后台并尝试安装。安装会关闭当前 App，请先保存操作；完成后请重新打开。';

  @override
  String get foregroundUpdateLaterHint =>
      '选择“稍后”可继续使用；退到后台且无任务持续 8 秒后，仍会尝试自动安装。部分系统可能需要手动确认。';

  @override
  String get foregroundUpdateBusy => '正在执行任务或播放内容，请结束后再更新。';

  @override
  String get foregroundUpdateChanged => '下载状态或当前任务已变化，请重新查看后再更新。';

  @override
  String get foregroundUpdateFailed => '暂时无法开始更新，请稍后重试或在更新窗口手动安装。';

  @override
  String get updateLater => '稍后';

  @override
  String get exitAndUpdate => '退出并更新';

  @override
  String get featureSongSearch => '乐曲检索';

  @override
  String get featureSearchTheChinaAndInternationalLibraries => '搜索国服与非国服曲库';

  @override
  String get featureVersionsAndLibraryAnalysis => '版本与曲库分析';

  @override
  String get featureVersionDetailsUpdateComparisonsAndChartConstants =>
      '版本资料、更新对照与谱面定数';

  @override
  String get featureImageRecognition => '图像识别';

  @override
  String get featureFindSongsByCoverArtAndRead => '通过曲绘找歌，识别结算成绩';

  @override
  String get featureCollectibles => '收藏品图鉴';

  @override
  String get featureBrowseIconsNameplatesAndOtherCollectibles =>
      '浏览头像、姓名框等游戏收藏品';

  @override
  String get featureSearchAndFilter => '查询与筛选';

  @override
  String get featureBrowseScoresAndFilterChartResults => '浏览成绩，按条件查找谱面表现';

  @override
  String get featureGrowthAndComparison => '成长与对比';

  @override
  String get featureReviewImprovementsAndCompareWithFriends => '回顾提升记录，对比好友成绩';

  @override
  String get featureBest50Overview => 'Best50 概览';

  @override
  String get featureCurrentPerformanceAndFittedPotential => '当前表现与拟合潜力';

  @override
  String get featurePersonalizedAnalysis => '个性化分析';

  @override
  String get featureFilterBest50ByTagsAndConditions => '按标签和条件筛选 Best50';

  @override
  String get featureGoalsAndScoreCards => '目标与制图';

  @override
  String get featureSimulateIdealScoresAndCreateCustomScore =>
      '模拟理想成绩，制作自定义成绩图';

  @override
  String get featureRatingRankings => 'Rating 排名';

  @override
  String get featureOfficialAndFittedRatingRankings =>
      '官方 Rating 与拟合 Rating 排行';

  @override
  String get featureAchievementRankings => '达成率排名';

  @override
  String get featureCompareAveragePerformanceAcrossAllScores => '比较全量成绩的平均表现';

  @override
  String get featureSpecialRankings => '特殊排名';

  @override
  String get featureExplorePlayerStatisticsFromDifferentAngles => '探索不同角度的玩家数据';

  @override
  String get featureProgressAndChallenges => '进度与挑战';

  @override
  String get featureVersionTitlesRanksAndKALEIDXSCOPE => '牌子、段位与 KALEIDXSCOPE';

  @override
  String get featureCalculators => '数值计算';

  @override
  String get featureRatingAchievementAndJudgementAnalysis => 'Rating、达成率与判定反推';

  @override
  String get featureRandomPicks => '随机选曲';

  @override
  String get featureDecideWhatToPlayToday => '决定今天玩什么';

  @override
  String get featurePracticeRecommendations => '练习推荐';

  @override
  String get featureChooseChartsByGainTagsGoalsOr => '围绕收益、标签、目标与定数挑谱';

  @override
  String get featureFavoritesAndPlayQueue => '收藏与待玩';

  @override
  String get featureOrganizeChartsForYourNextArcadeVisit => '整理谱面，准备下次出勤';

  @override
  String get featureArcadeMaps => '机厅地图';

  @override
  String get featureFindRhythmGameArcadesInChinaAnd => '查找国内与全球音游机厅';

  @override
  String get featureSoloGameSettings => '单人游戏设置';

  @override
  String get featureManageSharedRulesAndModePreferences => '统一管理各模式的规则与偏好';

  @override
  String get featureTextClues => '文字线索';

  @override
  String get featureGuessSongsFromMemoryAliasesAndLetters => '凭记忆、别名与字母线索猜歌';

  @override
  String get featureCoverArtChallenges => '曲绘辨识';

  @override
  String get featureTryCroppedPixelatedBlurredFlashAndPuzzle =>
      '观察局部、像素、模糊、快闪与拼图曲绘';

  @override
  String get featureAudioChallenges => '音频辨识';

  @override
  String get featureIdentifyNormalReversedOrPitchShiftedClips =>
      '通过原速、倒放或变调片段辨认歌曲';

  @override
  String get featureChartChallenges => '谱面辨识';

  @override
  String get featureGuessSongsFromSilentChartClips => '根据无声谱面片段猜歌';

  @override
  String get featureMultiplayer => '多人联机';

  @override
  String get featureChallengeTheSongLibraryWithFriends => '与朋友一起挑战曲库';

  @override
  String get featureMusicAndChartPlayback => '音乐与谱面播放';

  @override
  String get featureListenToMaimaiSongsAndPlayCustom => '听舞萌歌曲，播放自定义谱面';

  @override
  String get featureAccountsAndAuthorization => '账号与授权';

  @override
  String get featureManageAccountsAndDataSourceSignIns => '管理账号与数据源登录状态';

  @override
  String get featureSinglePlatformSync => '单平台同步';

  @override
  String get featureSyncScoresToEachScoreTracker => '分别同步成绩到各查分器';

  @override
  String get featureBatchAndScheduledSync => '批量与定时同步';

  @override
  String get featureSyncToMultiplePlatformsOrAutomatically => '多端同步与自动同步';

  @override
  String get featureRefreshData => '数据刷新';

  @override
  String get featureUpdateCachedScoresAndCabinetPlayCounts => '更新成绩缓存与机台游玩次数';

  @override
  String get featureLocalData => '本地数据管理';

  @override
  String get featureBackUpDataAndManageLocalCaches => '备份数据，管理本地缓存';

  @override
  String get featureAppPreferences => '应用偏好';

  @override
  String get featureThemeInteractionsAndLoadingQuotes => '主题、交互与加载语录';

  @override
  String get featureDiagnostics => '运行诊断';

  @override
  String get featureCheckServicesAndExportLogs => '检查服务状态，导出运行日志';

  @override
  String get featureCommunityActivity => '社区动态';

  @override
  String get featureBrowseRecentCommentsAndRatings => '查看最近评论与评分';

  @override
  String get featureVersionAndProject => '版本与项目';

  @override
  String get featureUpdatesProjectInformationAndLinks => '版本更新、项目介绍与相关链接';

  @override
  String get featureFeedbackAndSupport => '反馈与支持';

  @override
  String get featureReportIssuesShareIdeasAndSupportDevelopment =>
      '反馈问题、交流建议与支持开发';

  @override
  String get featureSongLookup => '乐曲查询';

  @override
  String get featureSearchByTitleAliasCharterOrTag => '按歌名、别名、谱师和标签搜索';

  @override
  String get featureInternationalSongLookup => '非国服乐曲查询';

  @override
  String get featureSearchAndFilterTheInternationalLibrary => '搜索与筛选非国服曲库';

  @override
  String get featureChinaUpdateComparison => '国服更新对照';

  @override
  String get featureFindSongsReleasedInJapanButNot => '看日服已上、国服还没上的曲目';

  @override
  String get featureUpdateCalendar => '更新日历';

  @override
  String get featureBrowseChinaChartUpdatesByDate => '按日期查看国服每次更新的谱面';

  @override
  String get featureVersionComparison => '版本对照';

  @override
  String get featureBrowsePlayableSongsByVersion => '按版本整理可游玩曲目';

  @override
  String get featureChartConstantDistribution => '定数分布';

  @override
  String get featureViewTheDistributionOfChartConstants => '查看谱面定数分布';

  @override
  String get featureCoverRecognition => '曲绘识别';

  @override
  String get featureFindSongsUsingYourCameraOrAn => '用相机或图片快速找歌';

  @override
  String get featureResultScreenRecognition => '结算画面识别';

  @override
  String get featurePhotographAResultScreenToReadScores => '拍摄机台结算画面，自动识别成绩';

  @override
  String get featureCollectibleLookup => '收藏品查询';

  @override
  String get featureViewIconsNameplatesAndOtherCollectibles => '查看头像、姓名框等收藏品';

  @override
  String get featureScoreLookup => '成绩查询';

  @override
  String get featureBrowseAndFilterAllPlayRecords => '浏览全部游玩记录与筛选结果';

  @override
  String get featureCustomScoreLookup => '个性化成绩查询';

  @override
  String get featureViewScoresByLevelOrCharter => '按等级或谱师查看成绩';

  @override
  String get featureScoreImprovementHistory => '成绩提升历史';

  @override
  String get featureReviewDailyChangesToYourBestScores => '按日回顾最佳成绩的变化与提升';

  @override
  String get featureRatingHistory => 'Rating 历史';

  @override
  String get featureTrackRatingOverTime => '看 Rating 随时间的变化';

  @override
  String get featureFriendComparison => '好友对比';

  @override
  String get featureCompareYourScoresWithAFriend => '看看你和好友的成绩差异';

  @override
  String get featureViewYourCurrentBest35AndBest15 => '查看当前 Best35 与 Best15';

  @override
  String get featureFittedBest50 => '拟合 Best50';

  @override
  String get featureAnalyzeYourPotentialRatingCeiling => '分析潜在 Rating 上限';

  @override
  String get featureCustomBest50Analysis => '个性化 Best50';

  @override
  String get featureFilterBest50ByTag => '按标签筛选 Best50';

  @override
  String get featureCustomFittedBest50 => '个性化拟合 Best50';

  @override
  String get featureViewFittedRatingPotentialByTag => '按标签查看拟合 Rating 上限';

  @override
  String get featureIdealBest50 => '理想 Best50';

  @override
  String get featureSimulateBest50WithEveryScoreRaisedOne =>
      '全员升一档后的 Best50 模拟';

  @override
  String get featureCreateBest50 => '自定义 Best50';

  @override
  String get featureFillIn50ScoreCardsManually => '手动填写 50 张成绩卡片';

  @override
  String get featureRatingLeaderboard => 'Rating 排行榜';

  @override
  String get featureViewPlayerRatingRankings => '查看玩家 Rating 排行';

  @override
  String get featureTotalFittedRatingLeaderboard => '拟合总Rating排行榜';

  @override
  String get featureCompareFittedTotalRatingWithOfficialBest50 =>
      '查看拟合总 Rating 与官方 Best50 差值';

  @override
  String get featureAverageAchievementLeaderboard => '平均达成率排行榜';

  @override
  String get featureRankByAverageAchievementAcrossAllScores => '按全量成绩的平均达成率排名';

  @override
  String get featureAverageDXScoreRateLeaderboard => '平均DX分数达成率排行榜';

  @override
  String get featureRankByAverageDXScoreRateAcross => '按全量成绩的平均DX得分达成率排名';

  @override
  String get featureSpecialLeaderboards => '特殊排行榜';

  @override
  String get featureDiscoverInterestingPlayerStatistics => '发现有趣的玩家数据';

  @override
  String get featureVersionTitleProgress => '牌子进度';

  @override
  String get featureViewVersionsAndTargetTitles => '查看各版本与目标牌子';

  @override
  String get featureRankTable => '段位表';

  @override
  String get featureChallengeYourNextRank => '挑战你的下一段位';

  @override
  String get featureExploreAUniqueMaimaiMode => '探索独特的舞萌玩法';

  @override
  String get featureSongRatingCalculator => '单曲 Rating 计算';

  @override
  String get featureCalculateASongRatingFromAchievement => '根据达成率计算单首 rating';

  @override
  String get featureAchievementCalculator => '达成率计算';

  @override
  String get featureCalculateAchievementFromJudgements => '根据判定详情算出达成率';

  @override
  String get featureReverseAchievementCalculator => '达成率反推';

  @override
  String get featureInferBREAKDetailsFromJudgements => '根据判定详情推出绝赞详情';

  @override
  String get featureDailyRecommendations => '每日推荐';

  @override
  String get featureLetRecommendationsPickYourNextSong => '今天打什么？交给推荐';

  @override
  String get featureRandomSongs => '随机乐曲';

  @override
  String get featureDrawACustomNumberOfRandomSongs => '自定义数量随机抽取歌曲';

  @override
  String get featureArcadeRoulette => '出勤转盘';

  @override
  String get featureLetARouletteWheelChooseYourSession => '等分转盘决定本次出勤选项';

  @override
  String get featureRatingGainRecommendations => '吃分推荐';

  @override
  String get featureChooseChartsByNetB50GainAlgorithm =>
      '按 B50 净收益挑谱 · AWMC 提供算法支持';

  @override
  String get featureTagRecommendations => '基于标签推荐';

  @override
  String get featureFindSongsBasedOnTagsFromYour => '基于你的游玩谱面标签推荐曲目';

  @override
  String get featureTargetRatingRecommendations => '基于目标 Rating 推荐';

  @override
  String get featureFindChartsThatCanRaiseYourRating => '寻找适合上分的谱面';

  @override
  String get featureConstantRangeRecommendations => '基于定数区间推荐';

  @override
  String get featureChooseChartsWithinAConstantRange => '按定数范围挑选谱面';

  @override
  String get featureFavoriteFolders => '收藏夹';

  @override
  String get featureManageYourFavoriteCharts => '管理你收藏的谱面';

  @override
  String get featurePlayNext => '下次想玩';

  @override
  String get featureQueueSongsForYourNextArcadeVisit => '排好下次去机台想玩的歌曲';

  @override
  String get featureChinaRhythmGameMap => '全国音游地图';

  @override
  String get featureFindArcadesWithTheGamesYouWant => '看看哪里有你想玩的机台';

  @override
  String get featureWorldwideArcadeMap => '全球音游街机地图';

  @override
  String get featureBrowseArcadesWorldwideOnNearCade => '查看 NearCade 全球街机店铺';

  @override
  String get featureSoloSongGameSettings => '单人猜歌游戏设置';

  @override
  String get featureManageSharedAndModeSpecificRules => '管理共用规则和各模式设置';

  @override
  String get featureNoClueSongQuiz => '无提示猜歌';

  @override
  String get featureChallengeTheSongLibraryFromMemory => '凭记忆挑战曲库';

  @override
  String get featureAliasSongQuiz => '根据别名猜歌';

  @override
  String get featureTestYourKnowledgeOfSongAliases => '用别名挑战你的熟悉度';

  @override
  String get featureMaimaiLetterReveal => '舞萌开字母';

  @override
  String get featureGuessSongsFromRevealedLetters => '看首字母猜歌';

  @override
  String get featureCroppedCoverQuiz => '根据部分曲绘猜歌';

  @override
  String get featureGuessTheSongFromASmallPart => '看一小块曲绘猜出歌曲';

  @override
  String get featureBlurredCoverQuiz => '根据模糊曲绘猜歌';

  @override
  String get featureGuessSongsFromBlurredCoverArt => '根据模糊化处理后的曲绘猜歌';

  @override
  String get featurePixelCoverQuiz => '像素曲绘猜歌';

  @override
  String get featureGuessSongsFromPixelatedColorsAndShapes => '根据像素马赛克的色块与轮廓猜歌';

  @override
  String get featureFlashCoverQuiz => '曲绘快闪猜歌';

  @override
  String get featureRememberABrieflyFlashedCover => '曲绘一闪而过，凭记忆猜歌';

  @override
  String get featureCoverPuzzleQuiz => '曲绘拼图猜歌';

  @override
  String get featureWatchCoverPiecesAppearOverTime => '曲绘碎块随时间逐步拼合显现';

  @override
  String get featureAudioClipQuiz => '根据歌曲片段猜歌';

  @override
  String get featureGuessSongsFromShortAudioClips => '截取音源片段猜歌';

  @override
  String get featureReversedAudioQuiz => '倒放音频猜歌';

  @override
  String get featureGuessSongsFromReversedClips => '听倒放歌曲片段猜歌';

  @override
  String get featureSpeedAndPitchQuiz => '变速变调猜歌';

  @override
  String get featureGuessSongsFromSpeedAndPitchChanges => '根据变速变调的音频猜歌';

  @override
  String get featureChartClipQuiz => '谱面片段猜歌';

  @override
  String get featureGuessSongsFromSilentChartAnimations => '看一段无声谱面动画猜出歌曲';

  @override
  String get featureMultiplayerSongQuiz => '多人猜歌游戏';

  @override
  String get featureGuessMaimaiSongsWithFriends => '和朋友一起猜舞萌曲库';

  @override
  String get featureMusicPlayer => '随身听';

  @override
  String get featurePlayMaimaiMusicInTheBackgroundWith => '后台播放舞萌曲库，带通知栏播放器';

  @override
  String get featureCustomChartPlayback => '自定义谱面播放';

  @override
  String get featurePlayLocalCustomCharts => '播放本地自定义谱面';

  @override
  String get featureAccountManagement => '成绩导入凭据';

  @override
  String get featureViewYourLinkedDivingFishAccount =>
      '管理水鱼、落雪与 AWMC NET 的成绩导入 Token';

  @override
  String get featureAccountSetupGuide => '账号注册引导';

  @override
  String get featureSetUpDivingFishLXNSAndAWMC => '水鱼注册、落雪注册与 AWMC NET 档案创建引导';

  @override
  String get featureSignInToMaimaiScoreHub => '登录 maimai Score Hub';

  @override
  String get featureSignInForOCRAndScoreHub =>
      '仅登录，不同步成绩；用于 OCR 与 maimai Score Hub 功能';

  @override
  String get featureSignOutOfDivingFish => '登出水鱼账号';

  @override
  String get featureClearYourDivingFishSignIn => '清除水鱼登录状态';

  @override
  String get featureSignInToDivingFish => '登录水鱼';

  @override
  String get featureGetAnImportTokenToEnableScoreSync =>
      '获取 ImportToken 以使用同步功能';

  @override
  String get featureSyncToDivingFish => '同步成绩到水鱼';

  @override
  String get featureScanACodeToFetchAndSync => '扫码抓取并同步最新成绩';

  @override
  String get featureSyncToLXNS => '同步成绩到落雪';

  @override
  String get featureSyncLocalScoresToLXNS => '将本地成绩同步到落雪咖啡屋';

  @override
  String get featureSyncToAWMCNET => '同步成绩到 AWMC NET';

  @override
  String get featureImportScoresToAWMCNETUsingA => '用机台二维码导入成绩到 AWMC NET';

  @override
  String get featureSyncToMultiplePlatforms => '同步成绩到多端';

  @override
  String get featureSendTheSameScoresToMultipleTrackers => '一份成绩同步到多个查分器';

  @override
  String get featureAutoSync => '自动同步';

  @override
  String get featureQuickSyncDailyAt0000And => '每天北京时间 0 点和 12 点自动快速同步';

  @override
  String get featureRefreshCachedData => '拉取成绩并更新数据';

  @override
  String get featureFetchAndInitializeAllLocalCachesAgain =>
      '拉取所选账号的成绩并重算 Best50，同时更新曲目、定数与标签';

  @override
  String get featureAdvancedRefresh => '拉取成绩并更新数据（高级）';

  @override
  String get featureChooseCachesToRefreshAndTestAPI =>
      '按数据类型选择是否强制重新下载，并测试各接口连通性';

  @override
  String get featureRefreshCabinetPlayCount => '刷新机台游玩次数';

  @override
  String get featureReadOnlyTheCurrentAccountPlayCount =>
      '单独读取当前账号的 PC 数；不会附带同步成绩';

  @override
  String get featureDataBackup => '数据备份';

  @override
  String get featureImportOrExportLocalData => '导入或导出本地数据';

  @override
  String get featureCacheManagement => '缓存管理';

  @override
  String get featureViewAndClearAudioPVAndMaidata => '查看并清理音源、PV、maidata 缓存';

  @override
  String get featureSystemSettings => '系统设置';

  @override
  String get featureAdjustThemeBackgroundInteractionsAndSync =>
      '调整主题、背景图、交互与同步选项';

  @override
  String get featureLoadingQuotes => '加载语录管理';

  @override
  String get featureChooseQuotesShownWhileLoading => '选择加载时展示的语录';

  @override
  String get featureServerStatus => '服务器状态';

  @override
  String get featureViewMaimaiServiceStatus => '查看舞萌服务状态';

  @override
  String get featureExportLogs => '打印日志';

  @override
  String get featureExportRecentLogsForTroubleshooting => '导出最近运行日志，方便排查问题';

  @override
  String get featureRecentComments => '最近评论';

  @override
  String get featureViewRecentCommunityComments => '查看社区最近评论';

  @override
  String get featureRecentRatings => '最近评分';

  @override
  String get featureViewRecentCommunityRatings => '查看社区最近评分';

  @override
  String get featureCheckForUpdates => '检查更新';

  @override
  String get featureCheckForANewerAppVersion => '检查应用是否有新版本';

  @override
  String get featureAboutTheApp => '关于 APP';

  @override
  String get featureViewProjectAndVersionInformation => '了解项目与版本信息';

  @override
  String get featureOfficialWebsite => '访问官方网站';

  @override
  String get featureVisitTheProjectAtChiffonmaiCloud =>
      '前往 chiffonmai.cloud 查看项目主页';

  @override
  String get featureRelatedProjects => '查看友情链接';

  @override
  String get featureDiscoverCommunityProjects => '发现同好项目';

  @override
  String get featureReportAnIssue => '问题反馈';

  @override
  String get featureReportProblemsYouEncounter => '反馈使用中遇到的问题';

  @override
  String get featureJoinTheQQGroup => '加入 QQ 群';

  @override
  String get featureOpenTheOfficialCommunityGroup => '一键跳转官方交流群';

  @override
  String get featureSurvey => '问卷调查';

  @override
  String get featureHelpImproveChiffonMai => '助力 ChiffonMai 更上一层楼';

  @override
  String get featureSupportDevelopment => '支持开发者';

  @override
  String get featureSupportContinuedProjectUpdates => '支持项目持续更新';

  @override
  String get featureLibrary => '曲库';

  @override
  String get featureSearchSongsBrowseInformationAndRecognizeImages =>
      '搜索乐曲、浏览资料与图像识别';

  @override
  String get featureSiteWideTotalFittedRatingRanking => '拟合总 Rating 站内排行';

  @override
  String get featureRankAllScoresByAverageDXScore => '按全量成绩的平均DX分数达成率排名';

  @override
  String get featureScores => '成绩';

  @override
  String get featureBrowseScoresImprovementsRankingsAndProgress =>
      '查成绩、看提升、比排名与追踪进度';

  @override
  String get featureAllFeatures => '全部功能';

  @override
  String get featureStarAFeatureToAddItTo => '点星标加入首页「常用」';

  @override
  String get featureChallengeYourMelodyMemoryWithReversedClips =>
      '听倒放的歌曲片段，挑战旋律记忆';

  @override
  String get featureChangeBothSpeedAndPitchForA => '速度与音高一起变化，换个耳朵听歌';

  @override
  String get featureSyncScoresOnADailySchedule => '每天定时同步成绩，解放双手';

  @override
  String get featureMe => '我的';

  @override
  String get featureAccountsSyncBackupAndAppPreferences => '账号、同步、备份与应用偏好';

  @override
  String get featureSharedRulesAndSettingsForEachMode => '共用规则与各模式的专属设置';

  @override
  String get featureHome => '首页';

  @override
  String get featurePlay => '游玩';

  @override
  String get featureArcade => '出勤';

  @override
  String get featureCasual => '休闲';

  @override
  String get featureChooseSongsPlanPracticeAndFindArcades => '选曲、安排练习与查找机厅';

  @override
  String get featureSongQuizzesMusicAndCustomCharts => '猜歌挑战、听歌与自定义谱面播放';

  @override
  String get featureSystem => '系统';

  @override
  String get featureBuildingCoverIndex => '正在构建曲绘索引…';

  @override
  String get featureAnotherTaskIsRunningPleaseWait => '正在处理其它任务，请稍候';

  @override
  String get featureLeaderboards => '排行榜';

  @override
  String get featureTotalFittedRating => '拟合总 Rating';

  @override
  String get featureAverageAchievement => '平均达成率';

  @override
  String get featureAverageDXScoreRate => '平均DX分数达成率';

  @override
  String get featureSpecial => '特殊';

  @override
  String get featureCalculators2 => '计算工具';

  @override
  String get featureFindScoresTitleConstantOrSongID => '查成绩：曲名、定数、曲目 ID';

  @override
  String get featureRefreshDataToSeeYourBest35And =>
      '刷新数据后这里会显示 Best35 与 Best15';

  @override
  String get featureFitted => '拟合';

  @override
  String get featureCustom => '个性化';

  @override
  String get featureCustomFitted => '个性化拟合';

  @override
  String get featureIdeal => '理想';

  @override
  String get featureCreate => '自定义';

  @override
  String get featureScoreImprovements => '成绩提升';

  @override
  String get featureRecordsBeginAfterSyncing => '同步后开始记录';

  @override
  String get featureDailyHistory => '按日回顾';

  @override
  String get featureThemeAndNavigationSettings => '主题与导航设置';

  @override
  String get featureSyncDataInMe => '前往「我的」同步数据';

  @override
  String get featureNoMatchingFeatures => '没有找到匹配的功能';

  @override
  String get featureNoFeaturesFound => '未找到匹配的功能';

  @override
  String get featureFavorites => '常用';

  @override
  String get featureDragToReorderTapOrDragTo => '拖动图标调整顺序；点叉号或拖到删除区域可移除收藏';

  @override
  String get featureStarFeaturesInAnyCategoryToShow =>
      '点击分类中的 ⭐ 星标即可收藏功能，收藏后直接显示在此处';

  @override
  String get featureFinishEditingFavorites => '完成收藏功能编辑';

  @override
  String get featureEditFavorites => '编辑收藏功能';

  @override
  String get featureDone => '完成';

  @override
  String get featureEdit => '编辑';

  @override
  String get featureReleaseToRemove => '松手移除收藏';

  @override
  String get featureDragHereToRemove => '拖到这里移除收藏';

  @override
  String get featureRemoveFavorite => '取消收藏';

  @override
  String get featureFavoriteFeature => '收藏功能';

  @override
  String get featureSearchFeaturesOrKeywords => '搜索功能名称或关键词';

  @override
  String get featureSearchSongTitlesAliasesOrIDs => '搜索歌名、别名、歌曲 ID…';

  @override
  String get featureSearchFeaturesOrSongs => '搜索功能或歌曲';

  @override
  String get featureSearch => '搜点什么...';

  @override
  String get featureClear => '清空';

  @override
  String get featureSearch2 => '搜索';

  @override
  String get featureCloseSearch => '收起搜索';

  @override
  String get featureClearInput => '清除输入';

  @override
  String get featureClearSearch => '清空搜索';

  @override
  String get featureSearchHistory => '搜索历史';

  @override
  String get featureLoadingSearchHistory => '正在读取搜索历史…';

  @override
  String get featureNoSearchHistory => '暂无搜索历史';

  @override
  String get featureDeleteThisSearchEntry => '删除这条搜索历史';

  @override
  String get featureCouldNotUpdateSearchHistoryTryAgain => '搜索历史更新失败，请重试';

  @override
  String get featureSearchSongTitlesOnly => '只按歌名搜索';

  @override
  String get featureTitleBPMCharterArtistAliasID => '歌名/BPM/谱师/曲师/别名/歌曲ID/...';

  @override
  String get featureTitleAliasIDArtistCharterBPM => '曲名、别名、ID、曲师、谱师、BPM';

  @override
  String get featureEnterAKeywordToFindSongs => '输入关键词搜索歌曲';

  @override
  String get featureNoMatchingSongs => '没有找到匹配的歌曲';

  @override
  String get featureSongs => '歌曲';

  @override
  String get featureThemeSettings => '主题设置';

  @override
  String get featureMoreSettings => '更多设置';

  @override
  String get featureCancel => '取消';

  @override
  String get featureOK => '确定';

  @override
  String get featureClose => '关闭';

  @override
  String get featureGotIt => '知道了';

  @override
  String get featureNotice => '提示';

  @override
  String get featureOperationFailed => '操作失败';

  @override
  String get featureUnknownError => '未知错误';

  @override
  String get featureDialog => '对话框';

  @override
  String get featureNoDetailsAvailable => '暂无详情';

  @override
  String get featureUnknown => '暂时未知';

  @override
  String get featureOff => '未开启';

  @override
  String get featureWaitingForUpstream => '等待上游';

  @override
  String get featureSyncing => '同步中';

  @override
  String get featureOn => '已开启';

  @override
  String get featureLastRunIncomplete => '上次未完成';

  @override
  String get featureUpToDate => '已是最新';

  @override
  String get featureLoading => '读取中…';

  @override
  String get featureCheckingSyncStatus => '正在获取同步状态';

  @override
  String get featureStatusUnknown => '状态未知';

  @override
  String get featureTemporarilyUnavailable => '暂时读取不到';

  @override
  String get featureTapToSetUp => '点这里设置';

  @override
  String get featureUnavailableRetryingShortly => '暂时读取不到，稍后自动重试';

  @override
  String get featureCheckingServerStatus => '正在获取服务器状态';

  @override
  String get featureSyncing2 => '正在同步…';

  @override
  String get featureReadingCabinetScores => '读取机台成绩…';

  @override
  String get featureCheckingForUpdates => '正在检查更新...';

  @override
  String get featureCouldNotCheckForUpdates => '检查更新失败';

  @override
  String get featureCheckYourConnectionAndTryAgain => '请检查网络连接后重试';

  @override
  String get featureCopyDownloadLink => '复制下载链接';

  @override
  String get featureDownloadLinkCopied => '下载链接已复制到剪贴板';

  @override
  String get featureUpdateAvailable => '发现新版本';

  @override
  String get featureNewVersion => '新版本';

  @override
  String get featureSignedInForOCRAndMaimaiScore =>
      '已登录，可用于 OCR 与 maimai Score Hub 功能';

  @override
  String get featureSignedInOCRAndMaimaiScoreHub =>
      '登录成功，可用于 OCR 与 maimai Score Hub 功能';

  @override
  String get featureRainbow => '彩';

  @override
  String get featurePlatinum => '白金';

  @override
  String get featureGold => '金';

  @override
  String get featureSilver => '银';

  @override
  String get featureBronze => '铜';

  @override
  String get featurePurple => '紫';

  @override
  String get featureRed => '红';

  @override
  String get featureOrange => '橙';

  @override
  String get featureGreen => '绿';

  @override
  String get featureBlue => '蓝';

  @override
  String get featureWhite => '白';

  @override
  String homeWelcome(String name) {
    return '欢迎回来，$name';
  }

  @override
  String homeSwitchSource(String source) {
    return '切换数据源，当前 $source';
  }

  @override
  String homeTotalRatingAction(String rating) {
    return '总 Rating $rating，打开高级刷新';
  }

  @override
  String homeFeatureCount(int count) {
    return '功能（$count）';
  }

  @override
  String homeAllFeatureCount(int count) {
    return '全部功能（$count）';
  }

  @override
  String homeResultCount(int count) {
    return '搜索结果（$count）';
  }

  @override
  String homeSongCount(int count) {
    return '歌曲（$count）';
  }

  @override
  String homeSongCountLimited(int count, int limit) {
    return '歌曲（$count，显示前 $limit 首）';
  }

  @override
  String homeRemoveFavorite(String name) {
    return '移除收藏：$name';
  }

  @override
  String hubRatingRecords(int rating, int count) {
    return '最新 $rating · 共 $count 次记录';
  }

  @override
  String hubFeaturesCount(int count) {
    return '$count 个功能';
  }

  @override
  String hubCoverIndexFailed(String error) {
    return '曲绘索引构建失败：$error';
  }

  @override
  String hubOpenFailed(String error) {
    return '打开失败：$error';
  }

  @override
  String hubLinkUnavailable(String name) {
    return '无法打开链接：$name';
  }

  @override
  String hubJoinGroup(String number) {
    return '一键跳转官方交流群（$number）';
  }

  @override
  String hubUpdateReleased(String version) {
    return '$version 已发布，点击查看更新内容';
  }

  @override
  String homeSyncSubmitted(int count) {
    return '提交 $count 条';
  }

  @override
  String homeSyncIncomplete(int count) {
    return '$count 个未完成';
  }

  @override
  String homeSyncSources(int count) {
    return '$count 个数据源';
  }

  @override
  String homeSyncSourcesWaiting(int count) {
    return '$count 个数据源 · 等待执行';
  }

  @override
  String homeSyncUpload(int completed, int total) {
    return '上传 $completed/$total 条';
  }

  @override
  String homeSyncReadPage(int page) {
    return '读取机台成绩 · 第 $page 页';
  }

  @override
  String homeServerHealthy(int healthy, int total) {
    return '$healthy/$total 正常';
  }

  @override
  String homeTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String get homeInitWorking => '正在初始化应用数据，请稍候...';

  @override
  String homeInitFinished(String duration) {
    return '数据初始化完成！总耗时 $duration';
  }

  @override
  String homeInitFailed(String error) {
    return '初始化失败：$error\n建议检查网络连接后重启应用';
  }

  @override
  String get featureHubSignedIn => '已登录，可直接使用 OCR；点击可重新登录';

  @override
  String get featureFish => '水鱼';

  @override
  String get featureLxns => '落雪';

  @override
  String get featureServerNormal => '服务正常';

  @override
  String get featureServerAbnormal => '服务异常';

  @override
  String get featureTapCommunityAppearance => '点击选择社区装扮';

  @override
  String get featureManageAccountBelow => '可按需在下方管理账号数据';

  @override
  String get featureCollapseProfile => '切换为简略信息';

  @override
  String get featureExpandProfile => '展开详细信息';

  @override
  String get featureSynced => '已同步';

  @override
  String get featureSyncFailed => '同步失败';

  @override
  String get featurePendingSync => '待同步';

  @override
  String get featureLocalOnly => '仅本机';

  @override
  String get featureLoadingGrowth => '正在读取成长记录…';

  @override
  String get featureGrowthRules => '成长规则';

  @override
  String get featureSyncProgress => '同步进行中，请稍候…';

  @override
  String get featurePreparing => '正在准备…';

  @override
  String homeStreak(int days) {
    return '连续签到 $days 天';
  }

  @override
  String homeTrophyId(String id) {
    return '称号 #$id';
  }

  @override
  String get growthRulesBody =>
      '按北京时间，每天首次启动 App 时检查签到；本机登录或验证账号成功后，也会为当天尚未签到的账号自动签到。\n\n首日 20 经验；连续签到每天多 5 点，第 7 天起每天 50 点。中断后从 20 点重新开始，累计经验保留。\n\nLv.1 升级需 100 经验，之后每级多需 20 点。\n\n成长记录跟随对应数据源账号，同一账号同日只能领取一次。';

  @override
  String hubOpenRelatedProject(String name) {
    return '打开友情链接：$name';
  }

  @override
  String hubBusyTask(String task) {
    return '$task正在进行中，不能使用本功能';
  }

  @override
  String get flowEnterYourAWMCNETTokenFirst => '请先输入 AWMC NET Token';

  @override
  String get flowCouldNotSaveYourPersonalKeyTry => '个人 key 保存失败，请重试';

  @override
  String get flowCouldNotDisableAutoSyncYourKey => '无法关闭对应自动同步，个人 key 未清除，请重试';

  @override
  String get flowAWMCNETScoreImportToken => 'AWMC NET 成绩导入 Token';

  @override
  String get flowSet => '已设置';

  @override
  String get flowNotSet => '未设置';

  @override
  String get flowVisit => '访问';

  @override
  String get flowToGenerateOrRotateYourTokenAt => '，在页面底部生成或轮换Token。';

  @override
  String get flowPasteYourAWMCNETScoreImportToken =>
      '在此粘贴 AWMC NET 成绩导入 Token...';

  @override
  String get flowClearToken => '清除 Token';

  @override
  String flowSignOutFailedP0(String p0) {
    return '登出失败：$p0';
  }

  @override
  String get flowSignedOutOfDivingFish => '已登出水鱼账号';

  @override
  String get flowLinkDivingFishAccount => '绑定水鱼账号';

  @override
  String get flowRequestAndOpenALoginQRCode =>
      '在舞萌|中二公众号请求并打开二维码，扫描后将字符串粘贴到下方：';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID =>
      '舞萌DX | 中二节奏 登入二维码(SGWCMAID...)';

  @override
  String get flowJoinLeaderboards => '参与排行榜';

  @override
  String get flowShowNicknameOtherwiseShownAsAnonymous => '展示昵称（不勾选则显示为匿名用户）';

  @override
  String get flowScoresFetchedLinkYourDivingFishAccount =>
      '成绩已抓取成功！但要推送到水鱼，需要先绑定你的水鱼账号：';

  @override
  String get flowDivingFishUsername => '水鱼用户名';

  @override
  String get flowEnterDivingFishUsername => '输入 Diving-Fish 用户名';

  @override
  String get flowDivingFishPassword => '水鱼密码';

  @override
  String get flowEnterDivingFishPassword => '输入 Diving-Fish 密码';

  @override
  String get flowSyncInProgressPleaseWaitAndAvoid => '同步进行中，请耐心等待，不要进行其他操作';

  @override
  String get flowScoresSyncedViewThemOnDivingFish => '成绩已同步！可前往水鱼查看';

  @override
  String flowOKP0(String p0) {
    return '确定 ($p0)';
  }

  @override
  String get flowSkip => '跳过';

  @override
  String get flowLinking => '绑定中...';

  @override
  String get flowLinkAndSync => '绑定并同步';

  @override
  String flowDoneP0ScoresSyncedAndLocalData(String p0) {
    return '全部完成！$p0 条成绩已同步，本地数据已刷新';
  }

  @override
  String get flowStartSync => '开始同步';

  @override
  String get flowPasteTheMaimaiCHUNITHMLoginQRString => '请先粘贴舞萌|中二登入二维码字符串';

  @override
  String get flowSignedIn => '已登录';

  @override
  String get flowEnterYourDivingFishCredentialsToObtain =>
      '输入你的 Diving-Fish 水鱼账号密码以获取 ImportToken：';

  @override
  String get flowUsername => '用户名';

  @override
  String get flowDivingFishUsername2 => 'Diving-Fish 用户名';

  @override
  String get flowPassword => '密码';

  @override
  String get flowDivingFishPassword2 => 'Diving-Fish 密码';

  @override
  String get flowImportTokenRetrievedAndSaved => 'ImportToken 已获取并缓存';

  @override
  String get flowYouCanNowSyncScoresToDiving => '现在可以使用\"同步成绩\"功能一键同步到水鱼了';

  @override
  String get flowSigningIn => '登录中...';

  @override
  String get flowSignIn => '登录';

  @override
  String get flowDataRefreshed => '数据刷新成功!';

  @override
  String get flowDivingFishProfile => '水鱼 成绩导入Token';

  @override
  String get flowNotSignedInToDivingFishOnly => '未登录水鱼账号，仅显示落雪相关设置';

  @override
  String get flowNoQQIDFoundRefreshDataOr => '未找到 QQ 号，请先刷新数据或登录水鱼';

  @override
  String get flowAuthorized => '已授权';

  @override
  String get flowNotAuthorized => '未授权';

  @override
  String get flowReadingDivingFishScoresRequiresBrowserAuthorization =>
      '读取你的水鱼成绩需要先在浏览器里授权本应用。点下方按钮打开授权链接，登录水鱼并同意即可。';

  @override
  String get flowDivingFishAuthorization => '水鱼授权';

  @override
  String get flowAuthorizationOpenedCompleteItInYourBrowser =>
      '已打开授权链接，请在浏览器中完成授权后返回查看';

  @override
  String get flowCouldNotStartAuthorizationTryAgain => '发起授权失败，请稍后重试';

  @override
  String get flowAuthorizeAgain => '重新授权';

  @override
  String get flowOpenAuthorizationLink => '打开授权链接';

  @override
  String get flowLXNSPersonalAPIKey => '落雪 API 密钥';

  @override
  String get flowVisit2 => '访问 ';

  @override
  String get flowAndScrollToTheBottomToGet => '，滑到最底部获取密钥。';

  @override
  String get flowPasteYourLXNSPersonalAPIKey => '在此粘贴落雪个人 API 密钥...';

  @override
  String get flowEnterYourAPIKeyFirst => '请先输入 API 密钥';

  @override
  String get flowClearKey => '清除密钥';

  @override
  String get flowRefreshImportToken => '刷新 ImportToken';

  @override
  String get flowCouldNotRefreshImportTokenTryAgain => 'ImportToken 刷新失败，请稍后重试';

  @override
  String get flowCopyImportToken => '复制 ImportToken';

  @override
  String get flowImportTokenCopied => 'ImportToken 已复制到剪贴板';

  @override
  String get flowConfirmRefresh => '确认刷新';

  @override
  String get flowThisClearsAllMaidataCachesAndDownloads =>
      '将清除所有maidata缓存并从服务器重新拉取全部maidata数据，耗时可能较长。\n\n确定要刷新吗？';

  @override
  String get flowMaidataRefreshed => 'Maidata刷新成功';

  @override
  String flowRefreshFailedP0(String p0) {
    return '刷新失败: $p0';
  }

  @override
  String flowCouldNotOpenABrowserWebsiteLink(String p0) {
    return '无法打开浏览器，官网链接已复制到剪贴板，请粘贴到浏览器访问 $p0';
  }

  @override
  String get flowConfirmSignOut => '确认登出';

  @override
  String get flowSigningOutClearsSavedLoginDetailsAnd =>
      '登出后将清除缓存的登录信息和 ImportToken，确定要登出吗？';

  @override
  String get flowSignOut => '登出';

  @override
  String get flowAccountChangedChooseYourAppearanceAgain => '账号已切换，请重新选择装扮';

  @override
  String get flowCouldNotSaveYourAppearanceChooseAgain => '装扮未能保存，请重新选择';

  @override
  String get flowChooseWhereToSaveLogs => '选择日志保存位置';

  @override
  String get flowLogsExported => '日志已导出';

  @override
  String flowCouldNotExportLogsP0(String p0) {
    return '导出日志失败：$p0';
  }

  @override
  String flowCouldNotOpenABrowserP0Copied(String p0) {
    return '无法打开浏览器，$p0已复制到剪贴板，请手动粘贴打开';
  }

  @override
  String get flowBaseNoteMaidataDownloadedAgain => '基础量 maidata 已重新拉取';

  @override
  String flowDownloadFailedP0(String p0) {
    return '重新拉取失败：$p0';
  }

  @override
  String flowPlayCountsUpdatedP0Records(String p0) {
    return '游玩次数已更新（$p0 条）';
  }

  @override
  String flowCouldNotReadPlayCountsP0(String p0) {
    return '游玩次数读取失败：$p0';
  }

  @override
  String get flowNoConnectionConnectAndTryAgain => '当前无网络连接，请联网后重试';

  @override
  String get flowMaimaiScoreHubSignInSavedOCR =>
      'maimai Score Hub 登录状态已保存，现在可以使用 OCR 了';

  @override
  String get flowSignOutOfDivingFish => '确认登出水鱼账号';

  @override
  String flowCouldNotSignOutOfDivingFish(String p0) {
    return '登出水鱼账号失败：$p0';
  }

  @override
  String get flowCannotSave => '无法保存';

  @override
  String get flowEnterYourAWMCNETScoreImportToken => '请输入 AWMC NET 成绩导入 Token。';

  @override
  String get flowAWMCNETScoreImportTokenSaved => 'AWMC NET 成绩导入 Token 已保存';

  @override
  String get flowAWMCNETScoreImportTokenCleared => 'AWMC NET 成绩导入 Token 已清除';

  @override
  String get flowSignedInToDivingFish => '水鱼账号登录成功';

  @override
  String get flowScoreImportToken => '成绩导入 Token';

  @override
  String get flowPasteATokenGeneratedInAWMCNET => '粘贴 AWMC NET 设置页生成的 Token';

  @override
  String get flowSaveToken => '保存 Token';

  @override
  String flowP0AutoSyncEnabledScheduledDailyBetween(String p0) {
    return '已开启$p0自动同步，每天北京时间 08:00–24:00 分时处理';
  }

  @override
  String flowP0AutoSyncDisabledHostedCredentialsDeleted(String p0) {
    return '已关闭$p0自动同步，并删除服务端托管凭据';
  }

  @override
  String get flowAutoSyncTemporarilyLimited => '自动同步暂时受限';

  @override
  String get flowCouldNotConfigureAutoSyncCheckYour => '自动同步设置失败，请检查账号状态后重试';

  @override
  String get flowRefreshStatus => '刷新状态';

  @override
  String get flowQueueStatus => '排队情况';

  @override
  String get flowSyncSources => '同步数据源';

  @override
  String get flowLoading => '正在读取…';

  @override
  String get flowSourcesEnabled => '个数据源已开启';

  @override
  String get flowScheduledQueueWindow => '分时排队窗口';

  @override
  String get flowChinaTimeUTC8OnceDailyQuick => '北京时间（UTC+8） · 每天一次 · 仅快速同步';

  @override
  String get flowCredentialsAreEncryptedAndHostedWhileEnabled =>
      '开启后加密托管同步凭据，关闭即删除。';

  @override
  String get flowAboutSync => '同步说明';

  @override
  String get flowUsersAreProcessedInDailyBatchesNew =>
      '每天分批排队处理；批次进行中或等待开始时新加入用户会排在当前批次末尾，批次结束后与其他用户一起进入下一轮随机排序；上游限流或队列较长时会顺延到后续窗口。';

  @override
  String get flowEachUserBatchHasAProcessingLimit =>
      '单个用户批次有整体处理时限：上游慢响应、配额不足或大量上传超过时限时，会自动结束本轮并在上轮结果中说明原因，次日窗口继续（排队等待不计入）。';

  @override
  String flowAfterReadingCabinetScoresEachUserHas(String p0) {
    return '机台成绩读取完成后，单个用户最多处理 $p0 分钟；读取前的排队和额度等待不计入。超出处理时限或当天服务窗口会结束本轮，次日窗口继续。';
  }

  @override
  String get flowLinkYourCabinetIdentityUsingAQR =>
      '输入二维码绑定机台身份后，同步凭据可供三个数据源共用；也可以通过一次普通二维码同步自动完成绑定。各数据源仍需配置各自的个人 key 和账号。\n\n每天在北京时间 08:00–24:00 分时安排快速同步：同一用户的三个数据源共用一份机台成绩读取结果，再分别读取目标成绩并上传变化。\n\n执行中会显示当前阶段、已读取页数、上传与已提交条数、已用时长；遇到上游等待会显示原因和预计重试时间。上轮结果会给出耗时、机台数据采集时间和下次重试时间。\n\n自动同步使用统一的上游请求预算和限流；遇到维护、配额不足或网络错误会暂停并显示原因，不会连续重试。\n\n正在执行时关闭，会停止后续批次，已经提交的成绩会保留；上传结果不确定时会先核对，不盲目重复提交。';

  @override
  String get flowSaving => '正在保存…';

  @override
  String flowP0AutoSync(String p0) {
    return '$p0自动同步';
  }

  @override
  String flowRoundStartedP0(String p0) {
    return '本轮开始：$p0';
  }

  @override
  String flowNextRunP0(String p0) {
    return '下次执行：$p0';
  }

  @override
  String get flowLoadingSyncStatus => '正在读取同步状态…';

  @override
  String get flowOffEnableAnytime => '未开启 · 可随时开启';

  @override
  String flowSyncSucceededButLocalRefreshWasIncomplete(String p0) {
    return '同步已成功，本地刷新未完成：$p0';
  }

  @override
  String get flowTheQueueIsBusyYourRunMay => '当前排队人数较多，可能顺延到后续处理窗口';

  @override
  String flowLastProgressP0(String p0) {
    return '上次进度：$p0';
  }

  @override
  String flowP0NoExecutionSlotIsUsedWhile(String p0) {
    return '$p0；等待期间不占用执行名额';
  }

  @override
  String flowRunTimeP0(String p0) {
    return '执行时间：$p0';
  }

  @override
  String flowCabinetDataCollectedP0(String p0) {
    return '机台数据采集：$p0';
  }

  @override
  String get flowTheRoundExceededItsTimeLimitAnd =>
      '已超过单轮处理时限，被自动结束；未完成的部分会在下次定时时间继续。';

  @override
  String flowTheRoundExceededItsP0MinuteLimit(String p0) {
    return '已超过单轮 $p0 分钟处理上限，被自动结束；未完成的部分会在下次定时时间继续。';
  }

  @override
  String get flowNextAutomaticRetry => '下次自动重试';

  @override
  String get flowNextRun => '下次执行';

  @override
  String flowP0Queue(String p0) {
    return '$p0队列';
  }

  @override
  String get flowNextRound => '下轮';

  @override
  String get flowThisRound => '本轮';

  @override
  String get flowChinaTimeUTC8 => '北京时间（UTC+8）';

  @override
  String flowLimitP0MinutesPerRound(String p0) {
    return ' · 单轮上限 $p0 分钟';
  }

  @override
  String get flowWaitingForUpstreamRecovery => '等待上游恢复';

  @override
  String get flowPreviousRoundQueue => '上轮队列处理';

  @override
  String get flowLoadingPreviousRoundStatistics => '上轮统计读取中…';

  @override
  String get flowStatisticsUnavailableRetryingAutomatically => '统计暂不可用，将自动重试';

  @override
  String get flowNoPreviousRound => '暂无上轮记录';

  @override
  String flowSubmittedP0SkippedP1P2(String p0, String p1, String p2) {
    return '提交 $p0 条 · 跳过 $p1 条 · $p2';
  }

  @override
  String get flowCabinetIdentityLinked => '机台身份已绑定';

  @override
  String get flowLinkCabinetIdentityFirst => '先绑定机台身份';

  @override
  String get flowRequestAndOpenALoginQRCode2 =>
      '在舞萌 | 中二公众号请求并打开登入二维码，扫描后把 SGWCMAID 开头的字符串填到下面。三个数据源共用这一次绑定，二维码本身不会保存；完成一次普通二维码同步也会自动绑定。';

  @override
  String get flowCabinetLoginQRCode => '机台登入二维码';

  @override
  String get flowLinking2 => '正在绑定…';

  @override
  String get flowLinkCabinetIdentity => '绑定机台身份';

  @override
  String flowEnterYourP0PersonalKeyToo(String p0) {
    return '还需填写$p0个人 key';
  }

  @override
  String get flowOpenDivingFish => '打开水鱼查分器';

  @override
  String get flowOpenKeyPage => '打开获取页面';

  @override
  String get flowPersonalKey => '个人 key';

  @override
  String get flowPasteImportToken => '在此粘贴 ImportToken...';

  @override
  String get flowSavePersonalKey => '保存个人 key';

  @override
  String get flowInvalidCabinetLoginQRCode => '无效的机台登入二维码';

  @override
  String flowSyncFailedP0(String p0) {
    return '同步失败：$p0';
  }

  @override
  String flowAWMCGatewayUnavailableP0(String p0) {
    return 'AWMC 网关当前不可用：$p0';
  }

  @override
  String get flowThisReadsOnlyTheActiveAccountPlay =>
      '本功能只读取当前活动账号的游玩次数。请使用一张刚生成的二维码；本次操作只会请求一次上游接口。';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID2 =>
      '舞萌DX | 中二节奏登入二维码（SGWCMAID...）';

  @override
  String get flowEnterAValidSGWCMAIDCabinetLoginQR => '请输入有效的 SGWCMAID 机台登入二维码';

  @override
  String get flowReadPlayCount => '开始读取';

  @override
  String get flowNone => '（无）';

  @override
  String get flowViewFullData => '查看完整数据';

  @override
  String get flowDataIsShownOnlyOnThisDevice => '数据仅在本机展示，不会上传到任何第三方。';

  @override
  String get flowSetGatewayToken => '设置网关令牌';

  @override
  String get flowQRCodeContent => '二维码内容';

  @override
  String get flowInvalidQRFormatMustStartWithSGWCMAID =>
      '二维码格式不正确（应以 SGWCMAID 开头）';

  @override
  String get flowConfirmAction => '确认执行';

  @override
  String get flowNoCharge => '不计费';

  @override
  String get flowShow => '显示';

  @override
  String get flowFullData => '完整数据';

  @override
  String flowP0P1CharactersP2LinesShownOnly(String p0, String p1, String p2) {
    return '$p0 · 共 $p1 字符 / $p2 行\n数据仅在本机展示，不会上传到任何第三方。';
  }

  @override
  String get flowEnterYourAWMCNETScoreImportToken2 => '请输入 AWMC NET 成绩导入 Token';

  @override
  String get flowImportTokenSaved => '导入 Token 已保存';

  @override
  String get flowPasteOrScanACabinetLoginQR => '请先粘贴或扫描机台登入二维码（SGWCMAID 开头）';

  @override
  String get flowSetYourAWMCNETScoreImportToken => '请先设置 AWMC NET 成绩导入 Token';

  @override
  String get flowRequestAndOpenALoginQRIn =>
      '在「舞萌|中二」公众号请求登入二维码并打开，再粘贴到下方；也可直接用「扫描」或「从图片识别」。';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID3 =>
      '舞萌DX | 中二节奏 登入二维码（SGWCMAID...）';

  @override
  String get flowScoreImportTokenSet => '成绩导入 Token 已设置';

  @override
  String get flowSetAWMCNETScoreImportToken => '设置 AWMC NET 成绩导入 Token';

  @override
  String get flowChange => '更换';

  @override
  String get flowPasteScoreImportToken => '在此粘贴成绩导入 Token…';

  @override
  String get flowGenerateYourOwnTokenOnAWMCNET =>
      '导入需要在 AWMC NET 官网生成一次 Token（项目自带的密钥在这里用不了）：';

  @override
  String get flow1OpenTheAWMCNETSettingsLink => '① 点击下面的链接打开 AWMC NET 设置页';

  @override
  String get flow2ScrollToTheBottomAndGenerate => '② 滑到页面最底部，点「生成/轮换Token」';

  @override
  String get flow3CopyTheTokenAndPasteIt => '③ 复制生成的 Token，然后粘贴到此处';

  @override
  String get flowCabinetScoresTakePriorityAndOverwriteMatching =>
      '以机台为准，会覆盖 AWMC NET 上已存在的对应成绩。';

  @override
  String flowCouldNotOpenABrowserVisitP0(String p0) {
    return '打不开浏览器，请手动访问 $p0';
  }

  @override
  String flowClearP0AccountData(String p0) {
    return '清除$p0账号数据';
  }

  @override
  String flowThisDeletesLocalP0CachesScoresBest50(String p0) {
    return '将删除 $p0 账号的本地缓存（成绩、Best50、玩家信息、推荐结果等），不影响登录状态。\n\n下次使用该账号需要重新刷新数据，确定清除？';
  }

  @override
  String get flowClear => '清除';

  @override
  String flowCouldNotClearP0(String p0) {
    return '清除失败：$p0';
  }

  @override
  String flowClearedP0AccountData(String p0) {
    return '已清除$p0账号数据';
  }

  @override
  String flowSwitchedToP0Account(String p0) {
    return '已切换到$p0账号';
  }

  @override
  String get flowAccountSwitchFailedAttemptedToRestoreThe => '账号切换失败，已尝试恢复原账号';

  @override
  String get flowSwitchingPleaseWait => '正在切换，请稍候';

  @override
  String get flowNoCachedDataForThisAccount => '该账号暂无缓存';

  @override
  String flowNoDataHasBeenCachedForP0(String p0) {
    return '$p0账号还没有缓存过数据，去刷新数据？';
  }

  @override
  String get flowRefreshNow => '去刷新';

  @override
  String get flowSwitchAccount => '切换账号';

  @override
  String flowSwitchingToP0(String p0) {
    return '正在切换到$p0账号…';
  }

  @override
  String get flowTapAnAccountToSwitchSourceAnd =>
      '点击账号即可切换数据源与玩家信息（使用本地缓存，不联网）';

  @override
  String get flowRefreshToUpdateTheActiveAccountDiving =>
      '刷新数据可更新当前账号；水鱼 / 落雪的登录状态相互独立，AWMC NET 按 QQ 查询无需登录。';

  @override
  String get flowCurrent => '当前';

  @override
  String get flowNoCache => '暂无缓存';

  @override
  String flowCopiedP0(String p0) {
    return '已复制：$p0';
  }

  @override
  String flowAWMCBOTQQIDCopiedP0(String p0) {
    return '已复制 AWMC BOT QQ 号：$p0';
  }

  @override
  String flowCopyP0(String p0) {
    return '复制 $p0';
  }

  @override
  String get flowOpenLXNS => '打开落雪咖啡屋';

  @override
  String get flowSendMymaiFirstIfNoAccountRecord =>
      '先发送 mymai。尚未建立账号记录时，机器人会回复操作步骤。';

  @override
  String get flowThenSendMaiAndFollowTheInstructions => '再发送 mai绑定，按提示创建档案。';

  @override
  String get flowOpenAWMCNET => '打开 AWMC NET';

  @override
  String get flowTapAnImageToEnlargeIt => '点开图片可以放大查看哦';

  @override
  String get flowEnlargeImage => '放大查看图片';

  @override
  String get flowNotSignedInToDivingFish => '还没登录水鱼账号';

  @override
  String get flowYourDivingFishAccountHasNoLinked => '你的水鱼账号还没绑定 QQ 号';

  @override
  String get flowLinkQQOnDivingFish => '去水鱼官网绑定';

  @override
  String get flowISavedItReadAgain => '我已填好，重新读取';

  @override
  String get flowAccount => '账号';

  @override
  String get flowCheckingAuthorization => '正在检查授权状态...';

  @override
  String get flowAuthorizationOpenedFinishInYourBrowserThen =>
      '已打开授权页，请在浏览器中完成授权后点右侧重新检测';

  @override
  String get flowReadingScoresRequiresAuthorizationRefreshWillFail =>
      '读取成绩需先授权本应用，未授权时刷新会失败';

  @override
  String get flowAuthorizedCheckAgain => '我已授权，重新检测';

  @override
  String get flowAuthorize => '去授权';

  @override
  String get flowCouldNotOpenABrowserLinkCopied => '无法打开浏览器，链接已复制到剪贴板，请手动粘贴打开';

  @override
  String flowP0ReusesThisDeviceSMaimaiScore(String p0) {
    return '$p0会复用本机保存的 maimai Score Hub 登录状态。\n\n当前没有可用登录态：请先用一张新的机台二维码完成登录；登录成功后，本次同步还会再要求一张新的二维码用于抓取成绩——同一张二维码不能同时用于登录和同步。\n\n登录状态会保存在本机，之后使用线路2不需要重复登录。';
  }

  @override
  String get flowRoute2Sync => '线路2 同步';

  @override
  String flowP0Sync(String p0) {
    return '$p0 同步';
  }

  @override
  String get flowTipGenerateTwoDifferentLoginQRCodes =>
      '提示：扫码前先在公众号/机台生成两张不同的登入二维码。';

  @override
  String get flowSignInFirst => '去登录';

  @override
  String get flowSignedInToMaimaiScoreHub => 'maimai Score Hub 登录成功';

  @override
  String get flowSignInSavedForOCRAndRoute =>
      '登录状态已保存。可复用于 OCR 与线路2 同步，\n不需要再重复扫码登录。';

  @override
  String get flowAuthenticatesWithMaimaiScoreHubOnlyNo =>
      '只进行 maimai Score Hub 认证，不会抓取或同步成绩。';

  @override
  String get flowInvalidQRCodeUseALoginQR => '无效的二维码，请使用舞萌|中二公众号生成的登入二维码';

  @override
  String get flowSetLXNSPersonalAPIKey => '设置落雪个人 API 密钥';

  @override
  String get flowExportingToLXNSRequiresYourPersonalAPI =>
      '落雪导出需要你本人的个人 API 密钥（不是账号密码）：';

  @override
  String get flow1OpenTheLXNSProfileLinkBelow => '① 点击下面的链接打开落雪个人主页';

  @override
  String get flow2ScrollToTheBottomAndCopy => '② 滑到页面最底部，找到「个人 API 密钥」并复制';

  @override
  String get flow3ReturnToAccountManagementLXNSAPI =>
      '③ 回到 App，打开「成绩导入凭据 → 落雪 API 密钥」粘贴并保存';

  @override
  String get flowReopenThisDialogAfterSavingToSync => '保存后重新打开本对话框即可同步。';

  @override
  String get flowLinkYourDivingFishAccountToObtain =>
      '需要绑定你的水鱼账号以获取 ImportToken：';

  @override
  String flowSyncSucceededButDataRefreshFailedP0(String p0) {
    return '同步成功，但刷新数据失败：$p0';
  }

  @override
  String get flowSignInToYourDivingFishAccount => '请先登录你的水鱼账号，再使用同步功能。';

  @override
  String get flowAccountMismatch => '账号不匹配';

  @override
  String flowTheSignedInDivingFishQQP0(String p0, String p1) {
    return '当前登录水鱼账号绑定的 QQ（$p0）与本机缓存的 QQ（$p1）不一致。\n\n请先登出当前水鱼账号，登录正确的账号后再同步。';
  }

  @override
  String flowSyncCompleteP0ScoresSyncedAndLocal(String p0) {
    return '同步完成！$p0 条成绩已同步，本地数据已刷新';
  }

  @override
  String flowSyncCompleteP0ScoresSentToDiving(String p0) {
    return '同步完成！$p0 条成绩已推送到水鱼';
  }

  @override
  String flowSyncCompleteP0ScoresExportedToLXNS(String p0) {
    return '同步完成！共 $p0 条成绩已导出到落雪';
  }

  @override
  String flowEnterANewQRCodeForP0(String p0) {
    return '为$p0输入新的二维码';
  }

  @override
  String flowMultiPlatformSyncCompleteP0(String p0) {
    return '多端同步完成：$p0';
  }

  @override
  String flowSyncCompleteP0P1P2(String p0, String p1, String p2) {
    return '同步已完成：$p0$p1$p2';
  }

  @override
  String get flowNone2 => '无';

  @override
  String flowSyncFailedP02(String p0) {
    return '\n\n同步失败：\n$p0';
  }

  @override
  String flowSyncSucceededButRefreshFailedP0(String p0) {
    return '\n\n同步成功，但刷新数据失败：\n$p0';
  }

  @override
  String get flowCouldNotSaveCredentialsTryAgain => '凭据保存失败，请重试。';

  @override
  String flowCouldNotOpenTheWebsiteVisitP0(String p0) {
    return '无法打开网站，请在浏览器中访问：$p0';
  }

  @override
  String get flowRoute1 => '线路1';

  @override
  String get flowRoute2 => '线路2';

  @override
  String flowCurrentP0P1(String p0, String p1) {
    return '当前：$p0 · $p1';
  }

  @override
  String get flowQuickSyncAlwaysUsesRoute1 => '快速同步已固定使用线路1';

  @override
  String get flowAvailable => '已存在';

  @override
  String get flowMissing => '未填写';

  @override
  String get flowFillInCredentialsToSelectThisSource => '补齐凭据后即可勾选';

  @override
  String get flowCollapse => '收起';

  @override
  String get flowFillInMissingCredentials => '填写缺少的凭据';

  @override
  String get flowGetYourImportTokenFromTheDivingFish =>
      '在水鱼官网登录后获取 ImportToken；通过 App 的「登录水鱼」保存过的凭据也会自动识别。';

  @override
  String get flowSignInToLXNSAndGetYour => '登录落雪咖啡屋，在账号设置中获取个人 API 密钥。';

  @override
  String get flowEnterTheQQLinkedToAWMCNET =>
      '填写 AWMC NET 账号绑定的 QQ；导入还需在官网设置页底部生成的 Import-Token。';

  @override
  String get flowOpenWebsite => '打开官网';

  @override
  String get flowAWMCNETQQID => 'AWMC NET QQ 号';

  @override
  String get flowSaveAndSelect => '保存并选中';

  @override
  String get flowNormalSyncRequiresANewCabinetQR =>
      '普通同步会在每个目标开始前分别要求一张新的机台二维码；同一张二维码不会用于第二个请求。快速同步不需要二维码。';

  @override
  String get flowSourcesWithSavedCredentialsAreSelectedBy =>
      '凭据存在的端默认勾选；水鱼 → 落雪 → AWMC NET 依次同步。';

  @override
  String get flowReloadCredentials => '重新读取凭据';

  @override
  String get flowAWMCNETOverwritesMatchingRecordsWithCabinet =>
      'AWMC NET 将以机台成绩为准覆盖已有对应成绩。';

  @override
  String flowStartSyncP0(String p0) {
    return '开始同步（$p0）';
  }

  @override
  String get flowRefreshDataAfterSync => '同步成功后刷新数据';

  @override
  String get flowRefreshAutomaticallyAfterUploadRefreshErrorsAre =>
      '成绩上传成功后自动刷新；刷新失败会单独提示。';

  @override
  String get flowCouldNotReadRefreshSettingsUploadCan =>
      '刷新配置读取失败，上传可继续，刷新错误将单独提示。';

  @override
  String get flowReloadRefreshSettings => '重新读取刷新配置';

  @override
  String get flowQuickSync => '快速同步';

  @override
  String get flowCheckingCachedUserCredentials => '正在检查用户凭据缓存…';

  @override
  String get flowCabinetIdentityLinkedNoQRNeededThis => '已绑定机台身份，本次无需二维码';

  @override
  String get flowChooseASyncSourceFirst => '请先选择同步数据源';

  @override
  String get flowEnterAQRToLinkCabinetIdentity => '可直接输入二维码绑定机台身份';

  @override
  String get flowUserCredentialsCached => '用户凭据已缓存';

  @override
  String get flowUserCredentialsNotCached => '用户凭据未缓存';

  @override
  String get flowValidatingQRCode => '正在验证二维码…';

  @override
  String get flowLinkCabinetIdentityUsingQR => '输入二维码绑定机台身份';

  @override
  String get flowUpdatesAchievementAndDXScoresComboAnd =>
      '更新达成率与 DX 分数；连击、同步分别沿用各目标账号现有的标记。暂不更新宴谱和游玩次数。';

  @override
  String get flowCouldNotDeleteCredentialsTryAgain => '用户凭据删除失败，请重试';

  @override
  String get flowDeleteUserCredentials => '删除用户凭据';

  @override
  String get flowAllThreeSourcesShareTheseCredentialsDeleting =>
      '三个数据源共用此凭据，删除时会关闭全部自动同步。';

  @override
  String get flowCabinetIdentityCachedQuickSyncIsReady => '机台身份已缓存，现在可以使用快速同步';

  @override
  String flowCouldNotLinkCabinetIdentityP0(String p0) {
    return '绑定机台身份失败：$p0';
  }

  @override
  String get flowReadsOnlyUserIdForQuickSyncDoes =>
      '只读取 userId 用于快速同步，不读取成绩，也不会执行普通同步。';

  @override
  String get flowVerifyAndSave => '验证并缓存';

  @override
  String get flowValidQRStringDetectedAndFilledIn => '已识别到有效二维码字符串，已自动填入';

  @override
  String get flowClipboardIsEmpty => '剪贴板为空';

  @override
  String get flowClipboardContentIsNotAValidLogin => '剪贴板内容不是有效的登入二维码，仍要填入吗？';

  @override
  String get flowFillIn => '填入';

  @override
  String get flowNoQRCodeFoundInTheImage => '未在图片中检测到二维码';

  @override
  String get flowCouldNotReadQRContentFromThe => '未能从图片中识别到二维码内容';

  @override
  String get flowQRCodeDetectedAndFilledIn => '已识别到二维码，已自动填入';

  @override
  String flowRecognitionFailedP0(String p0) {
    return '识别失败: $p0';
  }

  @override
  String flowScanFailedP0(String p0) {
    return '扫描失败: $p0';
  }

  @override
  String get flowReadClipboard => '读取剪贴板';

  @override
  String get flowReadFromGallery => '从相册识别';

  @override
  String get flowScanQRCode => '扫描二维码';

  @override
  String flowCameraErrorP0(String p0) {
    return '摄像头错误: $p0';
  }

  @override
  String get flowBack => '返回';

  @override
  String get flowCouldNotOpenTheLinkCopiedTo => '无法打开链接，链接已复制到剪贴板，请手动粘贴到浏览器打开';

  @override
  String get flowStillNoQQIDFoundCheckThat =>
      '还是没读到 QQ 号。请确认已在水鱼官网保存，或重新登录一次水鱼账号';

  @override
  String flowLinkedQQFoundP0(String p0) {
    return '已读到绑定 QQ：$p0';
  }

  @override
  String get flowNoQQIDFound => '未找到 QQ 号';

  @override
  String get flowAuthorizationOpenedReturnAfterAuthorizingAndTap =>
      '已打开授权页，完成授权后回到这里点「我已授权，重新检测」';

  @override
  String get flowAuthorizedYouCanNowRefreshData => '授权成功，现在可以刷新数据了';

  @override
  String get flowAuthorizationNotDetectedApproveAccessInYour =>
      '还没检测到授权，请确认在浏览器里点了「同意」';

  @override
  String get flowCheckFailedVerifyYourConnectionAndTry => '检测失败，请检查网络后重试';

  @override
  String get flowCurrentDataSource => '当前数据源：';

  @override
  String get flowConfirm => '确认';

  @override
  String get flowLXNSAuthorizationSavedItRenewsAutomaticallyNo =>
      '已保存落雪授权，将自动续期，无需再次输入授权码。';

  @override
  String get flowAuthorize2 => '点击授权';

  @override
  String get flowAuthorizationButtonNotWorking => '点击授权没反应？';

  @override
  String get flowCopyThisLinkAndOpenItManually => '请复制链接后在浏览器中手动打开完成授权：';

  @override
  String get flowCopyAuthorizationLink => '复制授权链接';

  @override
  String get flowAuthorizationLinkCopiedPasteItIntoYour => '授权链接已复制，请在浏览器中粘贴打开';

  @override
  String get flowAfterAuthorizingCopyTheCodeShownOn =>
      '授权后复制页面上显示的授权码，粘贴到下方输入框';

  @override
  String get flowEnterAuthorizationCode => '请输入授权码';

  @override
  String get flowPasteAuthorizationCode => '粘贴授权码';

  @override
  String get flowQQID => 'QQ 号';

  @override
  String get flowEnterAQQIDAlreadyLinkedOn => '输入已在 AWMC NET 绑定过的 QQ 号';

  @override
  String get flowNoSignInNeeded => '无需登录';

  @override
  String get flowAWMCNETIsAThirdPartyScore =>
      'AWMC NET 是第三方查分器，按 QQ 号公开查询成绩，不用登录、也不用授权。\n前提是该 QQ 已在 net.wmc.pub 绑定并上传过成绩，否则会提示「没有该 QQ 的数据」。';

  @override
  String get flowLinkQQUploadScoresOnAWMCNET => '去 AWMC NET 绑定 / 上传成绩';

  @override
  String get flowForceFullRefreshIgnoreStaticCaches => '强制完整刷新（忽略静态数据缓存）';

  @override
  String get flowMaidataStillUpdatesAsASeparateBackground =>
      'maidata 仍作为独立后台辅助任务更新';

  @override
  String get flowSignInThroughMeSignInTo => '请先在「系统 → 登录水鱼」登录水鱼账号';

  @override
  String get flowYourDivingFishAccountHasNoQQ =>
      '你的水鱼账号还没绑定 QQ 号，请先到水鱼官网「编辑个人资料」里填上';

  @override
  String get flowEnterYourLXNSAuthorizationCodeFirst => '请先填写落雪授权码';

  @override
  String get flowEnterYourAWMCNETQQID => '请输入 AWMC NET 的 QQ 号';

  @override
  String get flowInvalidQQID512DigitsRequired => 'QQ 号格式不对（应为 5–12 位数字）';

  @override
  String get flowCannotRefreshWithoutAConnectionConnectAnd =>
      '当前无网络连接，无法刷新数据。请联网后重试。';

  @override
  String get flowCouldNotOpenABrowserLinkCopied2 =>
      '无法打开浏览器，链接已复制到剪贴板，请手动粘贴到浏览器打开';

  @override
  String get flowAWMCNETOffersPublicScoreLookupBy =>
      'AWMC NET 按 QQ 号公开查询成绩，无需登录或授权。\n前提是该 QQ 已在 net.wmc.pub 绑定并上传过成绩。';

  @override
  String get flowForceRefreshCachedData => '强制刷新缓存数据';

  @override
  String get flowDeselectAll => '全不选';

  @override
  String get flowSelectAll => '全选';

  @override
  String get flowSelectedCachesAreIgnoredAndFetchedFrom =>
      '勾选 = 在本次刷新中忽略该缓存，强制走网络；未勾选 = 命中缓存则跳过。';

  @override
  String get flowLoading2 => '加载中…';

  @override
  String flowConnectedP0P1Ms(String p0, String p1) {
    return '连通：$p0 · ${p1}ms';
  }

  @override
  String flowFailedP0P1Ms(String p0, String p1) {
    return '失败：$p0 (${p1}ms)';
  }

  @override
  String get flowTest => '测试';

  @override
  String get flowRoute => '线路';

  @override
  String flowP0LastRefreshFailedShowingOlderData(String p0) {
    return '$p0 · 上次刷新失败，显示的是旧数据';
  }

  @override
  String flowP0Last100P1SamplesAvgP2(
      String p0, String p1, String p2, String p3) {
    return '$p0近100次 / $p1样本 / 平均$p2 / 成功$p3%';
  }

  @override
  String get flowSyncStatistics => '同步统计';

  @override
  String flowTracksDurationAndOutcomeForTheLatest(String p0) {
    return '记录最近 $p0 次同步的耗时与成败（所有使用者共享，仅含耗时/成败，不含二维码与账号信息）。';
  }

  @override
  String flowNormalSyncP0(String p0) {
    return '普通同步 · $p0';
  }

  @override
  String get flowStatisticsUnavailable => '统计不可用';

  @override
  String get flowNoRecordsYet => '暂无记录';

  @override
  String get flowFailed => '失败';

  @override
  String flowP0P1UsersQueuedP2ItemsProcessing(String p0, String p1, String p2) {
    return '$p0排队用户 $p1 人 · 处理中 $p2 项';
  }

  @override
  String flowP0P1ChinaTime(String p0, String p1) {
    return '\n$p0：$p1（北京时间）';
  }

  @override
  String get flowDifficultyFilter => '难度筛选';

  @override
  String get flowRecentSearches => '最近搜索';

  @override
  String get flowEG137Or134 => '如 13.7 或 13.4-14';

  @override
  String flowClearP0Constant(String p0) {
    return '清空$p0定数';
  }

  @override
  String get flowEveryEnteredDifficultyMustMatchBlankFields =>
      '填写的难度须全部满足，留空不限制。与上方「难度」及其它筛选条件取交集。';

  @override
  String get flowUTAGEIsFilledInSoNormalDifficulties =>
      '已填写 UTAGE，普通难度暂不可用；清空后恢复。';

  @override
  String get flowNormalDifficultiesAreFilledInSoUTAGE =>
      '已填写普通难度，UTAGE 暂不可用；全部清空后恢复。';

  @override
  String get flowConstantFilter => '定数筛选';

  @override
  String get flowAnyDifficulty => '任意难度';

  @override
  String get flowDifficultyCombination => '按难度组合';

  @override
  String get flowClearConstants => '清空定数';

  @override
  String get flowMinimum => '最小值';

  @override
  String get flowMaximum => '最大值';

  @override
  String get flowNoteCountFilter => '物量筛选';

  @override
  String get flowMinimumNotes => '最少物量';

  @override
  String get flowMaximumNotes => '最多物量';

  @override
  String get flowBPMFilter => 'BPM筛选';

  @override
  String get flowMinimumBPM => '最小 BPM';

  @override
  String get flowMaximumBPM => '最大 BPM';

  @override
  String get flowVersionFilter => '版本筛选';

  @override
  String get flowGenreFilter => '流派筛选';

  @override
  String get flowTagFilter => '标签筛选';

  @override
  String get flowNoTagData => '暂无标签数据';

  @override
  String get flowCharterFilter => '谱师筛选';

  @override
  String get flowArtistFilter => '曲师筛选';

  @override
  String get flowClearSelection => '清除选择';

  @override
  String flowLevelP0(String p0) {
    return '等级 $p0';
  }

  @override
  String get flowDXChartsOnly => '仅 DX 谱面';

  @override
  String get flowTitlesOnly => '只搜歌名';

  @override
  String get flowSearching => '正在搜索...';

  @override
  String get flowEnterASearchKeyword => '请输入搜索关键词';

  @override
  String flowP0SongsInTheLibraryEnterA(String p0) {
    return '曲库共 $p0 首，请输入搜索关键词';
  }

  @override
  String flowP0SongsFound15PerPage(String p0) {
    return '找到 $p0 首乐曲，每页 15 首';
  }

  @override
  String get flowReset => '重置';

  @override
  String get flowNoSongsMatchTheseFilters => '没有符合条件的歌曲';

  @override
  String get flowTryAWiderConstantRangeOrClear => '试试放宽定数或清空筛选';

  @override
  String get flowPrevious => '上一页';

  @override
  String get flowNext => '下一页';

  @override
  String flowCoverIndexReadyProcessedP0Covers(String p0) {
    return '曲绘索引建立完成！共处理 $p0 张曲绘';
  }

  @override
  String flowCouldNotBuildIndexP0(String p0) {
    return '索引建立失败: $p0';
  }

  @override
  String get flowChooseImageSource => '选择图片来源';

  @override
  String get flowTakePhoto => '拍照';

  @override
  String get flowPhotographCoverArt => '使用相机拍摄曲绘';

  @override
  String get flowChooseACoverScreenshotFromYourGallery => '从相册中选取曲绘截图';

  @override
  String get flowCameraPermissionRequired => '需要相机权限';

  @override
  String flowCouldNotSelectImageP0(String p0) {
    return '选取图片失败: $p0';
  }

  @override
  String get flowRecognitionFailedTryAgain => '识别失败，请重试';

  @override
  String flowRecognitionErrorP0(String p0) {
    return '识别出错: $p0';
  }

  @override
  String get flowRebuildCoverIndex => '重建曲绘索引';

  @override
  String get flowThisClearsTheIndexAndRecalculatesHashes =>
      '将清除现有索引并重新为全部曲绘计算哈希。这可能需要数十秒，确定继续吗？';

  @override
  String get flowRebuild => '确定重建';

  @override
  String get flowLoading3 => '正在加载...';

  @override
  String get flowBuildingCoverIndex => '正在建立曲绘索引...';

  @override
  String flowComputingFeaturesForP0Covers(String p0) {
    return '为 $p0 张曲绘计算特征';
  }

  @override
  String get flowNeededOnlyOncePleaseWait => '仅首次需要，请耐心等待';

  @override
  String get flowTakeOrChooseACoverImage => '拍摄或选择一张曲绘图片';

  @override
  String get flowCropTheCoverRegionAfterSelectingFor => '选取后可手动框选曲绘区域，提高识别准确率';

  @override
  String get flowImageReady => '图片已就绪';

  @override
  String get flowMatchConfidenceIsTooLowThisMay =>
      '匹配度过低，可能不是曲绘照片，请重新框选裁剪区域后再试';

  @override
  String get flowInputImage => '输入图片';

  @override
  String get flowMatchedCover => '匹配曲绘';

  @override
  String get flowCombinedMatchUnreliable => '综合匹配（不可靠）';

  @override
  String get flowCombinedMatch => '综合匹配';

  @override
  String get flowTop10Matches => '识别结果 Top 10';

  @override
  String flowSongP0(String p0) {
    return '歌曲 #$p0';
  }

  @override
  String get flowChooseImage => '选择图片';

  @override
  String get flowRecognizing => '识别中...';

  @override
  String get flowStartRecognition => '开始识别';

  @override
  String get flowCropAgain => '重新裁剪';

  @override
  String get flowChooseAgain => '重选';

  @override
  String get flowRecognizeAgain => '重新识别';

  @override
  String get flowChooseAnother => '再选一张';

  @override
  String get flowCoverIndexReady => '曲绘索引就绪';

  @override
  String get flowIndexNotBuilt => '索引未建立';

  @override
  String get flowRebuildIndex => '重建索引';

  @override
  String get flowCannotReadThisImageTryAnother => '图片无法读取，请换一张图片重试';

  @override
  String get flowCropFailedContinuingWithTheOriginalImage => '裁剪失败，将使用原图继续';

  @override
  String get flowDragTheCornersToSelectCoverArt => '拖动角点框选曲绘区域';

  @override
  String get flowProcessing => '处理中...';

  @override
  String get flowDragCornersToResizeDragInsideTo => '拖拽四角调整范围  |  拖拽框内移动位置';

  @override
  String get flowNoDivingFishImportTokenSignIn =>
      '还没有水鱼 Import-Token，请先到「登录水鱼」完成登录';

  @override
  String flowAddedToDivingFishP0(String p0) {
    return '已新增到水鱼：$p0';
  }

  @override
  String flowDivingFishScoreUpdatedP0(String p0) {
    return '已更新水鱼成绩：$p0';
  }

  @override
  String get flowCannotParseSongIDForLXNSSync => '无法解析曲目 ID，不能同步到落雪';

  @override
  String get flowNoLXNSPersonalAPIKeySetIt => '还没有落雪个人 API 密钥，请先到「成绩导入凭据」填写';

  @override
  String get flowPhotographTheCabinetResultScreen => '对着机台结算页面拍一张';

  @override
  String get flowChooseAPhotographedResultScreen => '选取已经拍好的结算画面';

  @override
  String get flowNoScoreRecognizedCropCloserToThe => '没有识别出成绩，可裁剪得更贴近结算区域后重试';

  @override
  String get flowCorrectRecognitionResults => '修正识别结果';

  @override
  String get flowRecognitionIsNotAlwaysAccurateEditedValues =>
      '识别不可能百分百准确，这里改过的值会直接替换卡片上的显示';

  @override
  String get flowDifficulty => '难度';

  @override
  String get flowSelectASongFirstToListIts => '先选定一首歌曲，才能列出它实际有的难度';

  @override
  String flowConstantP0(String p0) {
    return '定数 $p0';
  }

  @override
  String flowConstantP02(String p0) {
    return ' · 定数 $p0';
  }

  @override
  String get flowAchievement => '达成率 (%)';

  @override
  String get flowDXScore => 'DX 分数';

  @override
  String get flowCombo => '连击';

  @override
  String get flowSync => '同步';

  @override
  String get flowEmptyMeansNoMarkerSyncMarkersUse =>
      '「空」表示不设置该标记。同步标记会按水鱼的值域提交（FS / FS+ / FDX / FDX+ / SYNC）。';

  @override
  String get flowRestoreRecognizedValues => '恢复为识别结果';

  @override
  String get flowEmpty => '空';

  @override
  String get flowNoSongData => '暂无歌曲数据';

  @override
  String get flowNoMatchingSong => '未找到匹配的歌曲';

  @override
  String get flowRecognizingScores => '正在识别成绩';

  @override
  String get flowMatchingCoverArtAndTitlesUsuallyTakes => '曲绘 + 标题双路匹配，通常需要几秒';

  @override
  String get flowPhotographACabinetResultScreen => '对着机台结算页面拍一张照片';

  @override
  String get flowRecognizesTitleAchievementDXScoreDifficultyAnd =>
      '自动识别曲名、达成率、DX 分数、难度与 FC/FS';

  @override
  String get flowImageReadyTapStartRecognitionBelow => '图片已就绪，点击下方「开始识别」';

  @override
  String flowRecognitionCompleteP0P1Succeeded(String p0, String p1) {
    return '识别完成 · $p0/$p1 张成功';
  }

  @override
  String get flowCouldNotRecognizeAScore => '未能识别出成绩';

  @override
  String get flowSongTitleNotRecognized => '未识别出曲名';

  @override
  String get flowAchievement2 => '达成率';

  @override
  String flowMatchSourceP0(String p0) {
    return '命中来源：$p0';
  }

  @override
  String get flowEditThisResult => '编辑此项';

  @override
  String get flowSyncing => '同步中...';

  @override
  String get flowSyncToDivingFish => '同步到水鱼';

  @override
  String get flowSyncToLXNS => '同步到落雪';

  @override
  String flowCannotSyncYetP0(String p0) {
    return '暂不能同步：$p0';
  }

  @override
  String flowOtherCandidatesP0(String p0) {
    return '其它候选：$p0';
  }

  @override
  String get flowRecognizeAgain2 => '再次识别';

  @override
  String get flowUseAnotherImage => '换一张';

  @override
  String get flowClearAndChooseAgain => '清除重选';

  @override
  String get flowSignInToMaimaiScoreHubFirst => '先登录 maimai Score Hub';

  @override
  String get flowResultRecognitionRequiresSignInRequestA =>
      '识别结算画面需要登录。在舞萌 | 中二公众号请求并打开登入二维码，扫描后把字符串填到下面。只用来认证，不会抓取或同步成绩；登录状态保存在本机，之后不用重复登录。';

  @override
  String get flowSigningIn2 => '登录中…';

  @override
  String get flowDragCornersToSelectTheResultArea => '拖动角点框选成绩区域';

  @override
  String get flowStoragePermissionIsNeededToSaveVersion =>
      '需要存储权限才能保存版本图，请在设置中开启权限';

  @override
  String get flowImageSavedToGallery => '图片已保存到相册';

  @override
  String flowSaveFailedP0(String p0) {
    return '保存失败：$p0';
  }

  @override
  String get flowSaveImage => '保存图片';

  @override
  String get flowJapan => '日服';

  @override
  String get flowChina => '国服';

  @override
  String get flowJapanVersion => '日服版本';

  @override
  String get flowChinaVersion => '国服版本';

  @override
  String flowP0VersionsInReleaseOrderTapAn(String p0) {
    return '共 $p0 个版本，按发行顺序排列。点击版本图可放大查看或保存。';
  }

  @override
  String flowP0VersionImageNotAvailableYet(String p0) {
    return '$p0，版本图待补充';
  }

  @override
  String flowP0ViewVersionImage(String p0) {
    return '$p0，点击查看版本图';
  }

  @override
  String get flowImagePending => '图片待补';

  @override
  String get flowVersionImageNotAvailableYet => '等待补充版本图';

  @override
  String get flowTapToEnlarge => '点击查看大图';

  @override
  String get flowAboutThisComparison => '口径说明';

  @override
  String get flowNoSongsInThisSection => '这一段里没有曲目';

  @override
  String get flowChinaDivingFishUpdateFrontier => '国服（水鱼）更新前沿';

  @override
  String flowJapanDebutP0P1(String p0, String p1) {
    return '日服首发 $p0 · $p1';
  }

  @override
  String get flowFirstReleaseMeansTheJapanReleaseDate =>
      '「首次上线」显示的是日服首发时间，不是国服上线时间。候选按首发日期识别，并从已确认待补批次补齐遗漏；日期缺失时才参考 ID，较小 ID 的新曲也会纳入。';

  @override
  String flowExcludedP0SongsReleasedEarlyInChina(String p0, String p1) {
    return '已排除 $p0 首国服超前上线曲目（$p1）—— 它们会把前沿顶高，让真正待补的曲子排不进候选。';
  }

  @override
  String flowP0P1JapanP2(String p0, String p1, String p2) {
    return '#$p0 · $p1 · 日服 $p2';
  }

  @override
  String get flowNoCachedLibraryYet => '曲库还没有缓存';

  @override
  String get flowThisPageUsesTheLocalDivingFish =>
      '本页的数据来自本地曲库（水鱼 + union）。\n请先在首页执行一次「拉取成绩并更新数据」，把曲库拉下来后再回来查看。';

  @override
  String get flowHowThisPageWorks => '这个页面的口径';

  @override
  String get flow1DataSources => '1. 数据来源';

  @override
  String get flowTheLocalLibraryCombinesDivingFishAll =>
      '本地曲库 = 水鱼（国服全量歌曲）+ union（全量歌曲）。合并时 union 独有的那批会打上 isExtra 标记，本页据此区分来源；已确认的国服超前上线名单优先于这个标记。所以整个页面离线可用，与网络无关。';

  @override
  String get flow2DefiningTheUpdateFrontier => '2. 更新前沿怎么定';

  @override
  String get flowRegularChinaSongsInDivingFishAre =>
      '先筛出水鱼曲库里的国服常规曲，再按首发日期从新到旧排列，第一首作为「国服最新」。日期缺失或格式异常时参考 ID，所以这条前沿近似等于「国服已经追到哪」。\n宴会场（6 位 id）与 maidata 追加曲不参与判定。\n国服**超前上线**的曲目（国服先于日服上，id 却排最新）也不参与 —— 它们会把前沿顶高，让真正待补的曲子排不进候选。';

  @override
  String get flow3CompletingTheCandidateList => '3. 候选怎么补齐';

  @override
  String get flowStartWithUnionOnlyRegularSongsUsing =>
      '先取 union 独有的常规曲，以前沿的日服首发日期作为参考起点；如果已确认待补批次中仍有更早的未收录曲目，起点下移至该批最早日期。\n· 首发不早于起点的曲目都纳入，包含同一天以及 ID 较小的歌曲；\n· 日期缺失或异常时才按 ID 判断，已确认待补曲始终保留；\n· 早于起点的旧曲单独列出，不据此断定区域独占；候选只是参考，实际更新以官方公告为准。';

  @override
  String get flow4WhatFirstReleaseMeans => '4. 「首次上线」是什么时间';

  @override
  String get flowTheDebutDatesFromDivingFishAnd =>
      '水鱼与 union 提供的首发日期都是**日服**时间，不是国服上线时间 —— 这也是「曲目详情页显示首次上线、却看不出国服上没上」的原因。';

  @override
  String get flowUpdateDataTemporarilyUnavailable => '暂时读不到更新数据';

  @override
  String get flowRetry => '重试';

  @override
  String get flowReleaseContents => '配信内容';

  @override
  String get flowCouldNotLoadReleaseDataRetry => '配信数据读取失败，重试';

  @override
  String get flowNoContentDetails => '暂无内容明细';

  @override
  String flowP0OtherItemsNotShown(String p0) {
    return '其余 $p0 项未列出';
  }

  @override
  String get flowLXNSMaimaiDXScoreTracker => '落雪咖啡屋 maimai DX 查分器';

  @override
  String get flowPreviousMonthWithUpdates => '上一个有更新的月份';

  @override
  String flowChooseYearAndMonthCurrentP0P1(String p0, String p1) {
    return '选择年月，当前 $p0 年 $p1 月';
  }

  @override
  String flowP0P1(String p0, String p1) {
    return '$p0 年 $p1 月';
  }

  @override
  String get flowReleaseRecordOnly => '仅有配信记录';

  @override
  String flowP0UpdatesP1Songs(String p0, String p1) {
    return '$p0 次更新 $p1 首歌曲';
  }

  @override
  String get flowNextMonthWithUpdates => '下一个有更新的月份';

  @override
  String get flowRelease => '配信';

  @override
  String flowP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '$p0 月 $p1 日$p2$p3';
  }

  @override
  String flowP0Songs(String p0) {
    return '，$p0 首歌曲';
  }

  @override
  String get flowReleaseRecorded => '，有配信记录';

  @override
  String get flowNotReleasedYet => '  尚未上线';

  @override
  String get flowReleaseRecord => '配信记录';

  @override
  String flowP0SongsP1Charts(String p0, String p1) {
    return '$p0 首歌曲 $p1 张谱面';
  }

  @override
  String flowMonthP0(String p0) {
    return '$p0 月';
  }

  @override
  String get flowChooseYearAndMonth => '选择年月';

  @override
  String flowYearP0(String p0) {
    return '$p0 年';
  }

  @override
  String get flowNoData => '暂无数据';

  @override
  String flowLvP0P1SongsP2Played(String p0, String p1, String p2) {
    return 'Lv.$p0\n共 $p1 首\n已玩 $p2 首';
  }

  @override
  String flowLvP0P1P2Songs(String p0, String p1, String p2) {
    return 'Lv.$p0 $p1 (共 $p2 首)';
  }

  @override
  String get flowFilterTitleBackgroundColors => '筛选称号底色';

  @override
  String get flowChooseMultipleColors => '可同时选择多个底色';

  @override
  String get flowApply => '应用';

  @override
  String get flowCacheClearedReloading => '缓存已清除，重新加载数据中...';

  @override
  String get flowCouldNotClearCache => '清除缓存失败';

  @override
  String get flowSearchCollectibleNamesDescriptionsOrIDs => '搜索收藏品名称、描述或 ID';

  @override
  String get flowSongRequirements => '有歌曲要求';

  @override
  String get flowBackgroundColor => '底色';

  @override
  String get flowIDDescending => 'ID 倒序';

  @override
  String get flowIDAscending => 'ID 正序';

  @override
  String flowP0Items(String p0) {
    return '$p0 个';
  }

  @override
  String get flowHasUnlockRequirements => '有达成条件';

  @override
  String get flowNoMatchingCollectibles => '未找到匹配的收藏品';

  @override
  String get flowClearCacheAndReload => '清除缓存并重新加载';

  @override
  String get flowPermissionRequired => '权限不足';

  @override
  String get flowStoragePermissionIsNeededToSaveImages =>
      '需要存储权限才能保存图片到相册，请在设置中开启权限';

  @override
  String get flowExcludedSongs => '条件外排除曲目';

  @override
  String flowP0SongsExcludedFromRequirements(String p0) {
    return '共 $p0 首，不计入所需条件';
  }

  @override
  String get flowSongList => '歌曲列表';

  @override
  String flowP0SongsTotal(String p0) {
    return '总计 $p0 首歌曲';
  }

  @override
  String flowTranslatedFromP0ByBaiduSLanguage(String p0) {
    return '由百度大模型翻译自$p0';
  }

  @override
  String get flowTranslateToChinese => '翻译为中文';

  @override
  String get flowSaving2 => '保存中';

  @override
  String get flowSaveToGallery => '保存到相册';

  @override
  String get flowCopyLink => '复制链接';

  @override
  String get flowDescription => '描述';

  @override
  String get flowUnlockRequirements => '所需条件';

  @override
  String flowP0Details(String p0) {
    return '$p0详情';
  }

  @override
  String get flowCollectibleNotFound => '未找到收藏品信息';

  @override
  String get flowCouldNotRefreshData => '刷新数据失败';

  @override
  String flowQQP0HasNotAuthorizedThisApp(String p0) {
    return 'QQ $p0 尚未授权本应用，请稍后在「账号与同步」中完成授权';
  }

  @override
  String get flowAuthorizationNeeded => '需要完成授权';

  @override
  String get flowThisQQHasNotAuthorizedTheApp =>
      '该 QQ 尚未授权本应用，已打开授权页；授权完成后请重新刷新';

  @override
  String get flowThisQQHasNotAuthorizedTheApp2 =>
      '该 QQ 尚未授权本应用，请在浏览器中打开授权页完成绑定';

  @override
  String flowCouldNotRefreshDataP0(String p0) {
    return '刷新数据失败：$p0';
  }

  @override
  String get flowSigningOutOfDivingFish => '正在登出水鱼账号…';

  @override
  String get flowEnterYourDivingFishUsernameAndPassword => '请输入水鱼用户名和密码';

  @override
  String get flowCouldNotLinkDivingFishTryAgain => '绑定水鱼账号失败，请稍后重试';

  @override
  String get flowSyncSucceededRefreshingLocalData => '同步成功！正在刷新本地数据...';

  @override
  String get flowExportFailedTryAgain => '导出失败，请稍后重试';

  @override
  String get flowPreparingSync => '准备同步...';

  @override
  String flowP0ScoresSentToDivingFishSign(String p0) {
    return '同步完成！$p0 条成绩已推送到水鱼\n（需先登录水鱼才能自动刷新本地数据）';
  }

  @override
  String get flowSyncCancelled => '同步已取消';

  @override
  String get flowEnterUsernameAndPassword => '请输入用户名和密码';

  @override
  String flowWelcomeP0P1(String p0, String p1) {
    return '欢迎，$p0$p1';
  }

  @override
  String get flowAdvancedDataRefreshInProgress => '正在刷新数据（高级）...';

  @override
  String get flowRefreshingData => '正在刷新数据...';

  @override
  String flowCouldNotLoadAccountDetailsP0(String p0) {
    return '获取账号信息失败 ($p0)';
  }

  @override
  String get flowNickname => '昵称';

  @override
  String get flowVersionTitle => '牌子';

  @override
  String get flowRatingRank => 'Rating段位';

  @override
  String get flowLinkedQQ => '绑定QQ';

  @override
  String get flowChannelID => '频道ID';

  @override
  String get flowBeginner => '初学者';

  @override
  String get flow1stDan => '一段';

  @override
  String get flow2ndDan => '二段';

  @override
  String get flow3rdDan => '三段';

  @override
  String get flow4thDan => '四段';

  @override
  String get flow5thDan => '五段';

  @override
  String get flow6thDan => '六段';

  @override
  String get flow7thDan => '七段';

  @override
  String get flow8thDan => '八段';

  @override
  String get flow9thDan => '九段';

  @override
  String get flow10thDan => '十段';

  @override
  String get flowShin1stDan => '真初段';

  @override
  String get flowShin2ndDan => '真二段';

  @override
  String get flowShin3rdDan => '真三段';

  @override
  String get flowShin4thDan => '真四段';

  @override
  String get flowShin5thDan => '真五段';

  @override
  String get flowShin6thDan => '真六段';

  @override
  String get flowShin7thDan => '真七段';

  @override
  String get flowShin8thDan => '真八段';

  @override
  String get flowShin9thDan => '真九段';

  @override
  String get flowShin10thDan => '真十段';

  @override
  String get flowShinKaiden => '真皆传';

  @override
  String get flowUraKaiden => '里皆传';

  @override
  String get flowRefreshingMaidata => '正在刷新maidata...';

  @override
  String flowCouldNotOpenQQGroupIDP0(String p0) {
    return '没能跳转到 QQ，群号 $p0 已复制到剪贴板，可在 QQ 里搜索加入';
  }

  @override
  String get flowSongSearchFailedTheLibraryMayNot => '歌曲搜索失败，曲库可能还没加载好';

  @override
  String get flowPreparingToReadCabinetPlayCount => '准备读取机台游玩次数…';

  @override
  String get flowSigningOutOfDivingFish2 => '正在登出水鱼账号...';

  @override
  String get flowStartQRSyncFromHome => '请从首页的同步入口开始扫码同步';

  @override
  String get flowStartSyncFromHome => '请从首页的同步入口开始同步';

  @override
  String get flowEnterYourPersonalKeyAboveToEnable => '填好上面的个人 key 后就可以开启';

  @override
  String flowNoP0AccountYetSignInThrough(String p0) {
    return '还没有$p0账号，请先到「绑定与授权管理」登录并刷新数据';
  }

  @override
  String get flowSyncCredentialsReady => '同步凭据已就绪';

  @override
  String get flowLinkTheCabinetIdentityAboveToEnable => '绑定上方的机台身份后就可以开启';

  @override
  String get flowCouldNotReadSyncCredentialsTryAgain => '同步凭据读取失败，请重试';

  @override
  String get flowCouldNotReadAutoSyncStatusTry => '自动同步状态读取失败，请重试';

  @override
  String get flowLinkCabinetIdentityAboveFirst => '请先在上方绑定机台身份';

  @override
  String get flowSyncSetupIncomplete => '同步配置待完善';

  @override
  String flowAccountEndingInP0(String p0) {
    return '账号尾号 $p0';
  }

  @override
  String get flowStatusNotConfirmedYet => '状态暂未确认';

  @override
  String flowP0QueueUserPositionP1(String p0, String p1) {
    return '$p0排队 · 用户第 $p1 位';
  }

  @override
  String get flowEnabledWaitingForSchedule => '已开启 · 等待定时执行';

  @override
  String get flowSyncing2 => '正在同步';

  @override
  String get flowPreviousRoundNoRunYet => '上轮 · 暂无执行记录';

  @override
  String get flowPreviousRoundUpToDateNoUpload => '上轮已是最新 · 无需上传';

  @override
  String flowPreviousRoundCompleteSubmittedP0(String p0) {
    return '上轮已完成 · 提交 $p0 条';
  }

  @override
  String flowPreviousRoundIncompleteP0(String p0) {
    return '上轮未完成$p0';
  }

  @override
  String flowSubmittedP0(String p0) {
    return ' · 已提交 $p0 条';
  }

  @override
  String flowPreviousRoundP0(String p0) {
    return '上轮 · $p0';
  }

  @override
  String get flowLoadingStatistics => '统计加载中';

  @override
  String get flowUpdateFailed => '更新失败';

  @override
  String get flowUpdatesEvery3Seconds => '每 3 秒更新';

  @override
  String get flowQueuedUsers => '排队人数';

  @override
  String get flowPendingTasks => '待处理任务';

  @override
  String get flowProcessing2 => '处理中';

  @override
  String get flowProcessedUsers => '已处理用户';

  @override
  String get flowSuccessfulUsers => '成功用户';

  @override
  String get flowFailedUsers => '失败用户';

  @override
  String flowSubmittedP0P1(String p0, String p1) {
    return '已提交 $p0 条$p1';
  }

  @override
  String flowSkippedP0UnsupportedCharts(String p0) {
    return '，跳过 $p0 条不支持的谱面';
  }

  @override
  String flowConfirmedP0Submitted(String p0) {
    return '（已确认提交 $p0 条）';
  }

  @override
  String get flowWaitingForScheduledRun => '等待定时执行';

  @override
  String get flowWaitingToBeScheduled => '等待安排';

  @override
  String get flowEnterACabinetLoginQRCodeFirst => '请先填写机台登入二维码';

  @override
  String get flowLinkFailedCheckTheQRHasNot => '绑定失败，请确认二维码未过期后重试';

  @override
  String get flowEnterYourPersonalKeyFirst => '请先填写个人 key';

  @override
  String get flowAccountChangedRefreshThisPageAndEnter => '账号已变化，请刷新页面后重新填写';

  @override
  String get flow1SignInThroughMeSignIn =>
      '① 在「我的 → 绑定与授权管理」登录水鱼，输入你的 Diving-Fish 水鱼账号密码以获取 ImportToken。\n② 打开「成绩导入凭据 → 水鱼 成绩导入Token」，点击复制。\n③ 回到这里粘贴并保存。';

  @override
  String get flowQuickSyncing => '正在快速同步…';

  @override
  String get flowCheckingAWMCGateway => '正在检查 AWMC 网关...';

  @override
  String flowAWMCGatewayUnavailableP0SyncCancelledNo(String p0) {
    return 'AWMC 网关当前不可用（$p0），已取消同步、未消耗 Token';
  }

  @override
  String flowSyncingToP0ThroughAWMCGateway(String p0) {
    return '正在通过 AWMC 网关同步到$p0...';
  }

  @override
  String flowP0ScoresAreUpToDateNo(String p0) {
    return '$p0成绩已是最新，无需上传';
  }

  @override
  String flowQuickSyncCompleteSubmittedP1ChangedScores(String p0, String p1) {
    return '快速同步完成，已向$p0提交 $p1 条变化成绩';
  }

  @override
  String flowP0ScoresTotal(String p0) {
    return '共 $p0 条成绩';
  }

  @override
  String get flowSentToDivingFishThroughAWMCGateway => '已通过 AWMC 网关推送到水鱼';

  @override
  String get flowExportedToLXNSThroughAWMCGateway => '已通过 AWMC 网关导出到落雪';

  @override
  String flowSyncCompleteP0P1(String p0, String p1) {
    return '同步完成！$p0$p1';
  }

  @override
  String get flowNoCachedDivingFishImportTokenSignIn =>
      '本机还没有缓存水鱼 ImportToken：请先用线路2（maimai Score Hub）登录并同步一次，它会自动把 ImportToken 存到本机。';

  @override
  String get flowNoCachedLXNSPersonalAPIKeySync =>
      '本机还没有缓存落雪个人 API 密钥：请先同步一次并填好密钥（会保存在本机）。';

  @override
  String get flowReadingCabinetPlayCount => '正在读取机台游玩次数…';

  @override
  String get flowEndpoint => '接口';

  @override
  String get flowResult => '结果';

  @override
  String get flowBusinessOperationSucceeded => '业务成功';

  @override
  String flowUpstreamMessageTruncatedFullLengthP0Characters(String p0) {
    return '上游 msg 过长已截断（完整 $p0 字符）';
  }

  @override
  String get flowDuration => '耗时';

  @override
  String get flowBilling => '计费';

  @override
  String get flowGetThisTokenFromTheAWMCConsole =>
      '令牌来自 AWMC 控制台（api.wmc.pub），形如 gw_xxxx。\n\n⚠️ 令牌等同于你的账户操作权限与余额，请勿截图、勿粘贴到聊天/公开仓库。若怀疑泄露，请立即到控制台吊销并重新生成。';

  @override
  String get flowTokenStaysOnThisDeviceCanBe => '令牌保存在本机（可随时清除），不会随备份导出。';

  @override
  String get flowEnterCabinetQRCode => '输入机台二维码';

  @override
  String get flowUsedOnlyForThisOperationThenDiscarded =>
      '本次输入只用于这一次操作，用完即弃：不保存、不缓存；下一次操作会重新问你一次。';

  @override
  String get flowUse => '使用';

  @override
  String get flowThisKeyIsSentOnlyWithThis =>
      '该密钥只会随本次请求发送给 AWMC 网关转发，不会保存在本机。';

  @override
  String get flowContinue => '继续';

  @override
  String get flowTokenCost => 'Token 消耗';

  @override
  String flowP0ChargedOnlyOnSuccess(String p0) {
    return '$p0（成功才扣）';
  }

  @override
  String get flowNoTokenSpent => '不消耗';

  @override
  String get flowReversible => '可撤销';

  @override
  String get flowYesUploadAgainToOverwrite => '可以（重新上传即可覆盖）';

  @override
  String get flowNo => '不可以';

  @override
  String get flowIUnderstandTheEffectsAboveAndConfirm =>
      '我已确认上述影响，并确认这是我自己账号的二维码';

  @override
  String get flowWrite => '写入';

  @override
  String flowImportingScoresWaitingP0Seconds(String p0) {
    return '正在导入成绩…已等待 $p0 秒';
  }

  @override
  String get flowImportFailed => '导入失败';

  @override
  String get flowScoresAreUpToDateNoUpload => '成绩已是最新，无需上传';

  @override
  String flowQuickSyncCompleteSubmittedP0ChangedScores(String p0) {
    return '快速同步完成，已提交 $p0 条变化成绩';
  }

  @override
  String flowImportCompleteAddedP0UpdatedP1(String p0, String p1) {
    return '导入完成！新增 $p0 / 更新 $p1';
  }

  @override
  String flowSkippedP0(String p0) {
    return ' / 跳过 $p0';
  }

  @override
  String flowP0Seconds(String p0) {
    return '（$p0 秒）';
  }

  @override
  String flowP0ChartsAreNotYetInAWMC(String p0) {
    return '；$p0 条谱面 AWMC NET 暂未收录';
  }

  @override
  String flowP0Account(String p0) {
    return '$p0账号';
  }

  @override
  String get flowNotLinked => '未绑定';

  @override
  String get flowThenChooseRegisterUnderQuickActionsOn => '，点击右侧“快捷操作”区域的“注册”。';

  @override
  String get flowFollowThePageInstructionsToRegisterA => '随页面引导填写信息，即可注册水鱼账号。';

  @override
  String get flowAfterSigningInOpenEditProfileAt =>
      '登录后点页面右上角的“编辑个人资料”，按下面的说明设置：';

  @override
  String get flowScoreImportTokenRotateItUsingThe =>
      '成绩导入 Token：必须轮换！点 Token 右边的刷新图标即可，否则无法在 App 内登录。';

  @override
  String get flowLinkedQQRequiredAvoidUsingTheSame =>
      '绑定 QQ 号：必须填写。如果有小号，尽量不要和小号重复。';

  @override
  String get flowNicknameRecommendedWithoutOneTheAppSaves =>
      '昵称：建议填写。不填的话，App 内会默认以“shuiyu:QQ 号”的形式保存。';

  @override
  String get flowChannelIDAndRankNoSpecificRequirements =>
      '绑定频道 ID 和段位：没有特别要求。';

  @override
  String get flowDisablePreventPublicAPIsFromUsingMy => '“禁止公开接口使用我的成绩”：必须关闭。';

  @override
  String get flowDisableMaskingScoresForNonWebQueries =>
      '“对非网页查询的成绩使用掩码”：建议关闭，开启掩码会影响排行榜排名。';

  @override
  String get flowRememberToSaveAfterMakingChanges => '全部改好后，记得点“保存”。';

  @override
  String get flowThenChooseNewUserRegistrationInThe =>
      '，点击左侧边栏的“新用户注册”或页面中间处的“注册 maimai DX 查分器账号”。';

  @override
  String get flowFollowThePageInstructionsToRegisterAn =>
      '随页面引导填写信息，即可注册落雪咖啡屋账号。';

  @override
  String get flowAfterSigningInOpenAccountDetailsIn =>
      '登录后在侧边栏点“账号详情”，再点页面上方的“第三方应用”：';

  @override
  String get flowOAuthInMeRefreshDataChooseLXNS =>
      'OAuth 授权：在 App 的“我的 → 数据刷新 → 拉取成绩并更新数据 / 拉取成绩并更新数据（高级）”对话框里把数据源切换到落雪，按引导完成授权。授权后，这里的 OAuth 应用列表会出现 ChiffonMai。';

  @override
  String get flowPersonalAPIKeyResetItThenPaste =>
      '个人 API 密钥：点“重置 API 密钥”，然后到 App 的“我的 → 成绩导入凭据”，下滑找到“落雪 API 密钥”并填入。';

  @override
  String get flowYouCanAlsoVisitChiffonChuFromThe =>
      '也欢迎支持一下中二查歌，在“首页游玩 → 出勤”的轮播图里可以跳转过去。';

  @override
  String get flowMessage => '私聊 ';

  @override
  String get flowPrivatelyOrFollowTheseStepsInA => '，或在有机器人的群中，依次完成以下步骤：';

  @override
  String get flowSendTheSGWCMAIDStringOrMaimaiQR =>
      '按提示发送 SGWCMAID 字符串或舞萌二维码，等机器人回复上传完成就好了。';

  @override
  String get flowAndConfigureTheseSettings => '，按下面的说明设置：';

  @override
  String get flowEnableMakeMyScoresPublicOrScores => '“公开我的成绩”：必须开启，否则无法获取成绩。';

  @override
  String get flowImportTokenRegenerateItThenPasteIt =>
      'Import-Token：点“重新生成”轮换，然后到 App 的“我的 → 账号与授权 → 成绩导入凭据”，在对话框里下滑到“AWMC 成绩导入 Token”并填入。';

  @override
  String get flowRotatingATokenReplacesTheOldOne =>
      '注意：已有 Token 时，轮换会覆盖之前的 Token。轮换后请在 App 内手动更新，否则无法同步成绩。';

  @override
  String get flowJoin => '加入 ';

  @override
  String get flowCouldNotOpenQQAWMCGroup1 =>
      '无法打开 QQ，已复制 AWMC 交流 1 群的群号，请在 QQ 中搜索加入';

  @override
  String get flowCouldNotOpenQQAWMCGroup2 =>
      '无法打开 QQ，已复制 AWMC 交流 2 群的群号，请在 QQ 中搜索加入';

  @override
  String get flowCloseImage => '关闭图片';

  @override
  String get flowTheAppNeedsYourLinkedQQBefore =>
      '读取水鱼成绩前，App 要先从水鱼读出你账号上绑定的 QQ 号。\n请到「系统 → 登录水鱼」完成登录后再回来刷新。';

  @override
  String get flowTheAppIdentifiesYourDivingFishAccount =>
      'App 用 QQ 号来识别你的水鱼账号，而你账号里的「绑定 QQ 号」是空的，\n所以现在读不到成绩。这不是登录出了问题，只是少填了一个字段。';

  @override
  String get flow1OpenDivingFishAndSignIn => '① 打开水鱼查分器官网并登录';

  @override
  String get flow2OpenEditProfileEnterLinkedQQ =>
      '② 进入「编辑个人资料」→ 填上「绑定 QQ 号」并保存';

  @override
  String get flow3ReturnAndTapISavedIt => '③ 回到这里点「我已填好，重新读取」';

  @override
  String get flowSignInToMaimaiScoreHubFirst2 => '需要先登录 maimai Score Hub';

  @override
  String get flowPasteOrScanALoginQRCode => '请粘贴或扫描登入二维码';

  @override
  String get flowUseALoginQRFromTheMaimai => '请使用舞萌|中二公众号生成的登入二维码';

  @override
  String get flowMaimaiScoreHubSignInFailedThe =>
      'maimai Score Hub 登录失败，二维码可能已过期，请重新生成';

  @override
  String flowSignInFailedP0(String p0) {
    return '登录失败：$p0';
  }

  @override
  String get flowNoLXNSPersonalAPIKeySetConfigure =>
      '尚未设置落雪个人 API 密钥，请先在「成绩导入凭据」中设置';

  @override
  String get flowQuickSyncSupportsRoute1Only => '快速同步仅支持线路1';

  @override
  String get flowMaimaiScoreHubSessionExpiredSignIn =>
      'maimai Score Hub 登录状态已失效，请重新登录后再使用线路2';

  @override
  String get flowSyncCompleteRefreshingLocalData => '同步完成，正在刷新本地数据...';

  @override
  String get flowLinkDivingFishToObtainAnImportToken =>
      '需要先绑定水鱼账号以获取 ImportToken，请重新点击「同步成绩到水鱼」完成绑定';

  @override
  String get flowDoneLocalDataRefreshed => '全部完成！本地数据已刷新';

  @override
  String get flowSyncComplete => '同步完成！';

  @override
  String flowP0ScoresSentToDivingFishData(String p0, String p1) {
    return '同步完成！$p0 条成绩已推送到水鱼\n刷新数据失败：$p1';
  }

  @override
  String get flowDivingFishRoute2 => '水鱼线路2';

  @override
  String get flowSyncingScores => '正在同步成绩...';

  @override
  String get flowLXNSRoute2 => '落雪线路2';

  @override
  String get flowPreparingSync2 => '准备同步…';

  @override
  String get flowMultiPlatformRoute2 => '多端同步的线路2';

  @override
  String flowEnterANewQRForP0P1(String p0, String p1) {
    return '请为$p0（$p1）输入新的二维码…';
  }

  @override
  String flowThisQRIsUsedOnlyForThis(String p0, String p1) {
    return '这张二维码只用于$p0（$p1）的这一次请求；不能和其它目标用过的二维码相同。';
  }

  @override
  String get flowDirectQRUpload => '二维码直传';

  @override
  String flowSyncingToP0P1(String p0, String p1) {
    return '正在同步到$p0（$p1）…';
  }

  @override
  String flowP0UpToDate(String p0) {
    return '$p0（成绩已是最新）';
  }

  @override
  String flowP0QuickSyncUpdatedP1(String p0, String p1) {
    return '$p0（快速同步，更新 $p1 条）';
  }

  @override
  String flowP0Route1P1(String p0, String p1) {
    return '$p0（线路1）：$p1';
  }

  @override
  String flowP0Route1P1P2(String p0, String p1, String p2) {
    return '$p0（线路1）：$p1 $p2%';
  }

  @override
  String flowP0Route1(String p0) {
    return '$p0（线路1）';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub =>
      '未登录 maimai Score Hub，已跳过水鱼线路2同步';

  @override
  String flowDivingFishRoute2P0P1(String p0, String p1) {
    return '水鱼（线路2）：$p0 $p1%';
  }

  @override
  String flowDivingFishP0(String p0) {
    return '水鱼：$p0';
  }

  @override
  String flowDivingFishRoute2P0Scores(String p0) {
    return '水鱼（线路2，$p0 条）';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub2 =>
      '未登录 maimai Score Hub，已跳过落雪线路2同步';

  @override
  String flowLXNSP0(String p0) {
    return '落雪：$p0';
  }

  @override
  String flowLXNSRoute2P0P1(String p0, String p1) {
    return '落雪（线路2）：$p0 $p1%';
  }

  @override
  String flowLXNSRoute2P0Scores(String p0) {
    return '落雪（线路2，$p0 条）';
  }

  @override
  String get flowAWMCNETScoreImportTokenNotSet => '未设置 AWMC NET 成绩导入 Token';

  @override
  String get flowCouldNotReadSavedCredentialsTryAgain => '无法读取已保存的凭据，请重试。';

  @override
  String flowEnterP0(String p0) {
    return '请填写$p0';
  }

  @override
  String get flowPersonalAPIKey => '个人 API 密钥';

  @override
  String get flowEnterA512DigitQQID => '请填写 5～12 位 QQ 号';

  @override
  String get flowCouldNotSaveQQID => '保存 QQ 失败';

  @override
  String get flowSelectAtLeastOneSourceWithCredentials => '请至少选择一个已具备凭据的数据源';

  @override
  String get flowLXNSAuthorizationCodeMissing => '未填写落雪授权码';

  @override
  String flowNoLookupIDObtainedForP0(String p0) {
    return '未拿到$p0的查询标识';
  }

  @override
  String get flowStartingDataRefresh => '开始刷新数据...';

  @override
  String get flowDataRefreshComplete => '数据刷新完成';

  @override
  String get flowClearingCaches => '正在清除缓存...';

  @override
  String get flowRefreshingDataInParallel => '正在并行刷新数据...';

  @override
  String get flowSongDataRefreshed => '歌曲数据已刷新';

  @override
  String get flowDifficultyDataRefreshed => '难度数据已刷新';

  @override
  String get flowTagDataRefreshed => '标签数据已刷新';

  @override
  String get flowUserDataRetrieved => '用户数据已获取';

  @override
  String get flowCollectibleDataRefreshed => '收藏品数据已刷新';

  @override
  String get flowAliasDataRefreshed => '别名数据已刷新';

  @override
  String get flowUnionDataRefreshed => 'Union 数据已刷新';

  @override
  String get flowCouldNotFetchDivingFishScores => '水鱼成绩获取失败';

  @override
  String get flowCalculatingRating => '正在计算Rating...';

  @override
  String get flowSavingData => '正在保存数据...';

  @override
  String flowUploadingSongRankingsP0P1(String p0, String p1) {
    return '上传单曲排行榜 $p0/$p1...';
  }

  @override
  String get flowCouldNotRemoveLeaderboardEntries => '排行榜删除失败';

  @override
  String get flowAWMCNETScoresRetrieved => 'AWMC NET 成绩已获取';

  @override
  String get flowObtainingAccessToken => '正在换取访问令牌...';

  @override
  String get flowRenewingAccessToken => '正在续期访问令牌...';

  @override
  String get flowAuthorizationFailedCheckYourCode => '授权失败，请检查授权码是否正确';

  @override
  String get flowLXNSAuthorizationExpiredEnterANewAuthorization =>
      '落雪授权已过期，请重新输入授权码';

  @override
  String get flowAuthorizedRefreshingDataInParallel => '授权成功，正在并行刷新数据...';

  @override
  String get flowPreparingLXNSData => '准备落雪数据';

  @override
  String get flowLXNSProfileRetrieved => '落雪玩家信息已获取';

  @override
  String get flowLXNSScoresRetrieved => '落雪成绩已获取';

  @override
  String get flowCouldNotFetchLXNSProfileOrScores => '落雪玩家信息或成绩获取失败';

  @override
  String get flowCouldNotConvertLXNSScores => '落雪成绩转换失败';

  @override
  String get flowCalculatingBest50 => '正在计算 Best50 数据...';

  @override
  String get flowMissingSongDataCannotCalculateLXNSRating =>
      '缺少歌曲数据，无法计算落雪 Rating';

  @override
  String get flowInvalidBest50Data => 'Best50 数据异常';

  @override
  String get flowInvalidBest35Data => 'Best35 数据异常';

  @override
  String get flowInvalidBest15Data => 'Best15 数据异常';

  @override
  String flowP0CheckForInvalidData(String p0) {
    return '$p0，可能存在非法数据，请检查';
  }

  @override
  String flowCouldNotUpdateLeaderboardDataP0(String p0) {
    return '排行榜数据更新失败：$p0';
  }

  @override
  String flowLeaderboardUpdateErrorP0(String p0) {
    return '排行榜数据更新异常: $p0';
  }

  @override
  String get flowSongsAndCharts => '歌曲与谱面';

  @override
  String get flowTagsAndAliases => '标签与别名';

  @override
  String get flowCollectibles => '收藏品';

  @override
  String get flowMetadataAndExtras => '元数据与辅助';

  @override
  String get flowNormal => '普通';

  @override
  String get flowQuick => '快速';

  @override
  String flowLoadingP0Statistics(String p0) {
    return '$p0统计加载中…';
  }

  @override
  String flowP0StatisticsUnavailable(String p0) {
    return '$p0统计不可用';
  }

  @override
  String flowP0Last100NoRecords(String p0) {
    return '$p0近100次 / 暂无记录';
  }

  @override
  String flowP0Last100P1SamplesAvgP22(
      String p0, String p1, String p2, String p3) {
    return '$p0近100次 / $p1样本 / 平均$p2 / 成功$p3';
  }

  @override
  String get flowAverageDuration => '平均时长';

  @override
  String get flowSuccessRate => '成功率';

  @override
  String get flowSuccessfulSamples => '成功样本';

  @override
  String get flowLatestRun => '最近一次';

  @override
  String get flowStatusUnconfirmed => '状态未确认';

  @override
  String get flowExpectedRetry => '预计重试';

  @override
  String get flowLastRun => '最近执行';

  @override
  String get flowRefreshPending => '待刷新';

  @override
  String get flowStatusRefreshFailedTapToViewOr =>
      '状态刷新失败，请点击查看或重试；此前结果不代表本次查询已确认';

  @override
  String get flowSyncStatusNotReadYet => '尚未读取到同步状态';

  @override
  String flowP0UserP1OfP2(String p0, String p1, String p2) {
    return '$p0用户第 $p1 位 / $p2 人';
  }

  @override
  String flowPreviousRoundP02(String p0) {
    return '上轮：$p0';
  }

  @override
  String flowSuccessP0P1(String p0, String p1) {
    return '成功 · $p0 · $p1';
  }

  @override
  String flowFailedP0P1(String p0, String p1) {
    return '失败 · $p0 · $p1';
  }

  @override
  String flowP0UserPositionP1(String p0, String p1) {
    return '$p0用户第$p1位';
  }

  @override
  String flowSyncFailedP03(String p0) {
    return '同步失败·$p0';
  }

  @override
  String get flowSyncSucceeded => '同步成功';

  @override
  String flowSyncSucceededP0(String p0) {
    return '同步成功·$p0';
  }

  @override
  String get flowCorrectTheDifficultyCombinationConstantsFirst =>
      '请先修正按难度组合的定数输入';

  @override
  String flowSearchFailedP0(String p0) {
    return '搜索失败：$p0';
  }

  @override
  String get flowAny => '不限';

  @override
  String get flowChooseACharter => '请选择谱师';

  @override
  String get flowSelectCharter => '选择谱师';

  @override
  String get flowSearchCharters => '搜索谱师';

  @override
  String get flowFilterByCharterName => '输入谱师名称筛选...';

  @override
  String get flowChooseAnArtist => '请选择曲师';

  @override
  String get flowSelectArtist => '选择曲师';

  @override
  String get flowSearchArtists => '搜索曲师';

  @override
  String get flowFilterByArtistName => '输入曲师名称筛选...';

  @override
  String flowP0Items2(String p0) {
    return '$p0 项';
  }

  @override
  String get flowByDifficulty => '按难度';

  @override
  String get flowConstant => '定数';

  @override
  String get flowVersion => '版本';

  @override
  String get flowGenre => '流派';

  @override
  String get flowNotes => '物量';

  @override
  String get flowTags => '标签';

  @override
  String get flowCharter => '谱师';

  @override
  String get flowArtist => '曲师';

  @override
  String get flowSongID => '歌曲ID';

  @override
  String get flowSongTitle => '歌名';

  @override
  String get flowArtist2 => '艺术家';

  @override
  String get flowAlias => '别名';

  @override
  String get flowTakeAPhotoOrChooseAnImage => '拍照或从相册选择图片';

  @override
  String get flowCropTheCoverArtInTheImage => '框选图片里的曲绘区域';

  @override
  String get flowRecognizeAndViewTheClosestSongs => '开始识别，查看最接近的曲目';

  @override
  String get flowTexture => '纹理';

  @override
  String get flowColor => '颜色';

  @override
  String get flowEnterANumber => '请输入数字';

  @override
  String get flowCannotBeNegative => '不能为负数';

  @override
  String flowMustNotExceedP0(String p0) {
    return '不得超过 $p0';
  }

  @override
  String flowDifficultyP0(String p0) {
    return '难度 $p0';
  }

  @override
  String get flowLocalLibraryIsEmptyRefreshItFrom => '本地曲库为空，无法定位曲目。请先到首页刷新曲库';

  @override
  String get flowNoSongMatchedTapEditThisResult => '没匹配到曲目，点「编辑此项」手动指定';

  @override
  String get flowDifficultyNotRecognizedUTAGESyncIsUnsupported =>
      '难度识别不出来（宴会场谱面不支持同步）';

  @override
  String get flowNoChartInformationForThisSongIn => '曲库里这首歌没有谱面信息';

  @override
  String flowDifficultyP0DoesNotExistOnlyP1(String p0, String p1) {
    return '这首歌没有第 $p0 个难度（只有 $p1 个谱面）';
  }

  @override
  String get flowAchievementMissingTapEditThisResultTo => '缺少达成率，点「编辑此项」补上';

  @override
  String flowUpdatedOnLXNSP0(String p0) {
    return '已更新到落雪：$p0';
  }

  @override
  String flowSyncedToLXNSUnchangedP0(String p0) {
    return '已同步到落雪（无变化）：$p0';
  }

  @override
  String flowAchievementP0P1(String p0, String p1) {
    return '达成率 $p0% → $p1%';
  }

  @override
  String flowAchievementP0(String p0) {
    return '达成率 $p0%';
  }

  @override
  String flowDXScoreP0P1(String p0, String p1) {
    return 'DX分数 $p0 → $p1';
  }

  @override
  String flowDXScoreP0(String p0) {
    return 'DX分数 $p0';
  }

  @override
  String flowMaximumP0(String p0) {
    return '上限 $p0%';
  }

  @override
  String flowMaximumP02(String p0) {
    return '上限 $p0';
  }

  @override
  String get flowPhotographOrChooseAResultScreen => '拍照或从相册选择结算画面';

  @override
  String get flowPhotographStraightAndClearlyForBetterRecognition =>
      '尽量拍正、拍清，识别更准';

  @override
  String get flowCheckResultsThenSyncToDivingFish => '核对结果后可同步到水鱼或落雪';

  @override
  String get flowStandard => '标准';

  @override
  String get flowConfidence => '置信度 —';

  @override
  String flowConfidenceP0(String p0) {
    return '置信度 $p0%';
  }

  @override
  String get flowCoverArt => '曲绘';

  @override
  String get flowTitle => '标题';

  @override
  String get flowSignInFailedTheQRMayHave => '登录失败，二维码可能已过期，请重新生成';

  @override
  String get flowAllSongs => '全量';

  @override
  String get flowInChina => '国服已上';

  @override
  String get flowPendingRelease => '待上线';

  @override
  String get flowNotIncluded => '未收录';

  @override
  String get flowNextUpdateCandidates => '下次更新候选';

  @override
  String get flowOlderSongsMissingInChina => '国服未收录旧曲';

  @override
  String get flowUTAGE => '宴会场';

  @override
  String get flowChinaRegularSongs => '国服常规曲';

  @override
  String get flowEarlyChinaReleases => '国服超前上线';

  @override
  String get flowNoMissingRegularSongsInTheCurrent => '当前参考范围内没有未收录的常规曲。';

  @override
  String flowSortedByIDNotReleaseOrderOfficial(String p0) {
    return '按 ID 升序展示，顺序不代表上线先后；实际更新以官方公告为准。$p0';
  }

  @override
  String get flowTheseSongsPredateTheReferenceStartOr =>
      '这些曲早于候选参考起点，或缺少日期且 ID 较小，可能是区域限定、联动独占或尚未补入的旧曲；不代表以后不会上线。';

  @override
  String get flowUTAGEDoesNotFollowVersionUpdatesListed =>
      '宴会场不随版本更新，列在这里仅供参考。';

  @override
  String get flowRegularDivingFishChinaSongsNewestDebut =>
      '水鱼（国服）的常规曲，按首发日期从新到旧排列 —— 第一首就是本页的「更新前沿」。';

  @override
  String get flowTheseSongsReachedChinaBeforeJapanTheir =>
      '这些是**国服先于日服**上线的曲子：国服已经有了，id 却排在最新。它们不能当前沿（会把真正待补的那批顶出候选），所以单独列在这里。';

  @override
  String flowVersionsInvolvedP0(String p0) {
    return '\n涉及版本：$p0';
  }

  @override
  String flowP0P1Songs(String p0, String p1) {
    return '$p0 $p1 首';
  }

  @override
  String get flowChartDateSource => '谱面日期来源：';

  @override
  String get flowReleaseDataSource => '配信数据来源：';

  @override
  String get flowUpdatesOnThisDay => '当天更新';

  @override
  String flowP0P1P2(String p0, String p1, String p2) {
    return '$p0 月 $p1 日 周$p2';
  }

  @override
  String get flowAll => '全部';

  @override
  String get flowPlayed => '已游玩';

  @override
  String get flowUnplayed => '未游玩';

  @override
  String flowP0Types(String p0) {
    return '$p0 种';
  }

  @override
  String get flowThisCollectibleHasNoImage => '该收藏品没有图片';

  @override
  String flowCouldNotSaveImageP0(String p0) {
    return '保存图片失败: $p0';
  }

  @override
  String get flowThisCollectibleHasNoImageLink => '该收藏品没有图片链接';

  @override
  String get flowLinkCopied => '链接已复制到剪贴板';

  @override
  String get flowCouldNotCopyLink => '复制链接失败';

  @override
  String get flowRequiredDifficulty => '所需难度';

  @override
  String get flowMinimumAchievement => '所需最低达成率';

  @override
  String get flowRequiredNoteSpeed => '所需游玩流速';

  @override
  String get flowRequiredCombo => '所需连击';

  @override
  String get flowRequiredSync => '所需同步';

  @override
  String get flowJapaneseEnglish => '日语+英语';

  @override
  String get flowEnglish => '英语';

  @override
  String get flowJapanese => '日语';

  @override
  String flowP0Seconds2(String p0) {
    return '$p0 秒';
  }

  @override
  String flowP0Minutes(String p0) {
    return '$p0 分钟';
  }

  @override
  String flowP0MinP1Sec(String p0, String p1) {
    return '$p0 分 $p1 秒';
  }

  @override
  String get flowJustNow => '刚刚';

  @override
  String get flowWaitingForUpstreamQuota => '等待上游配额恢复';

  @override
  String get flowWaitingForUpstreamService => '等待上游服务恢复';

  @override
  String get flowWaitingForUpstreamGateway => '等待上游网关恢复';

  @override
  String get flowWaitingForUpstreamProcessing => '等待上游处理';

  @override
  String flowP0RetryAroundP1(String p0, String p1) {
    return '$p0，预计 $p1 重试';
  }

  @override
  String get flowProcessingTimedOut => '处理超时';

  @override
  String get flowQuotaInsufficient => '配额不足';

  @override
  String get flowUpstreamUnavailable => '上游不可用';

  @override
  String get flowUploadIncomplete => '上传未完成';

  @override
  String get flowUploadCredentialsExpired => '上传凭据失效';

  @override
  String get flowCouldNotReadTargetScores => '目标成绩读取失败';

  @override
  String get flowCouldNotReadLibrary => '曲库读取失败';

  @override
  String get flowCouldNotReadCabinetData => '机台读取失败';

  @override
  String get flowNoScoresToSync => '没有可同步成绩';

  @override
  String get flowInterruptedByServiceRestart => '服务重启中断';

  @override
  String get flowProcessingWindowEnded => '处理窗口已结束';

  @override
  String get flowRoundDataExpired => '本轮数据已失效';

  @override
  String get flowTaskCancelled => '任务已取消';

  @override
  String get flowPreparingQuickSync => '正在准备快速同步…';

  @override
  String flowElapsedP0P1(String p0, String p1) {
    return '处理已用 $p0$p1';
  }

  @override
  String flowLimitP0Min(String p0) {
    return ' / 上限 $p0 分钟';
  }

  @override
  String get flowWaitingForProcessingToStart => '等待开始处理';

  @override
  String flowCabinetDataCollectedP02(String p0) {
    return '机台数据采集 $p0';
  }

  @override
  String flowUploadingP0P1P2(String p0, String p1, String p2) {
    return '上传 $p0/$p1 条$p2';
  }

  @override
  String flowReadingCabinetScoresPageP0(String p0) {
    return '读取机台成绩 · 第 $p0 页';
  }

  @override
  String flowSubmittedP02(String p0) {
    return '提交 $p0 条';
  }

  @override
  String flowSkippedP0UnsupportedCharts2(String p0) {
    return '跳过 $p0 条不支持的谱面';
  }

  @override
  String flowUnchangedP0(String p0) {
    return '未变化 $p0 条';
  }

  @override
  String flowP0TookP1(String p0, String p1) {
    return '$p0 · 耗时 $p1';
  }

  @override
  String get flowAccountAndSync => '账号与同步';

  @override
  String get flowAccountAndSyncHint => '管理账号、授权状态与成绩同步';

  @override
  String get flowFishAccount => '水鱼账号';

  @override
  String get flowReadingAccountState => '正在读取账号状态';

  @override
  String get flowNotSignedIn => '未登录';

  @override
  String get flowSignInFishAgain => '重新登录水鱼';

  @override
  String get flowUseFishForToken => '使用水鱼账号获取 ImportToken';

  @override
  String get flowScoreSync => '成绩同步';

  @override
  String get flowSyncSourcesHint => '从舞萌数据源同步到第三方服务';

  @override
  String get flowImportTokenNotSet => '未设置成绩导入 Token';

  @override
  String get flowTitleCollectible => '称号';

  @override
  String get flowIconCollectible => '头像';

  @override
  String get flowPlateCollectible => '姓名框';

  @override
  String get flowFrameCollectible => '背景';

  @override
  String get flowAwmcGateway => 'AWMC 网关';

  @override
  String get flowNormalSource => '国服曲库';

  @override
  String get flowExtraSource => '非国服曲库';

  @override
  String get flowQrPrivateNotice =>
      '与「同步成绩」用的是同一串二维码内容（SGWCMAID 开头），可直接从微信/相机识别结果里复制。\n\n⚠️ 该二维码等同于机台登录凭据，只能用于你自己的账号。';

  @override
  String get flowReadingExistingScoresOnTheTargetAccount => '正在读取目标账号已有成绩…';

  @override
  String get flowCheckingChartsSupportedByTheTarget => '正在核对目标源支持的谱面…';

  @override
  String flowReadingCabinetScoresP0PagesRead(String p0) {
    return '正在读取机台成绩，已读取 $p0 页';
  }

  @override
  String get flowReadingCabinetScores => '正在读取机台成绩…';

  @override
  String get flowPreparingChartsComboAndSyncMarkers => '正在整理谱面与连击、同步标记…';

  @override
  String flowUploadingScoresP0P1P2(String p0, String p1, String p2) {
    return '正在上传成绩（$p0 / $p1 条$p2）';
  }

  @override
  String flowP0Submitted(String p0) {
    return '，已提交 $p0 条';
  }

  @override
  String get flowSyncComplete2 => '同步完成';

  @override
  String get flowWaitingForUpstreamQuota2 => '等待上游配额恢复…';

  @override
  String get flowWaitingForUpstreamService2 => '等待上游服务恢复…';

  @override
  String flowReadingExistingScoresOnP0(String p0) {
    return '正在读取 $p0 已有成绩…';
  }

  @override
  String flowCheckingChartsSupportedByP0(String p0) {
    return '正在核对 $p0 支持的谱面…';
  }

  @override
  String get flowComparingChangesAndPreparingUploads => '正在比对差异并整理上传内容…';

  @override
  String flowUploadingToP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '正在上传到$p0：$p1 / $p2 条$p3';
  }

  @override
  String get flowValidatingQRCode2 => '正在验证二维码...';

  @override
  String get flowCreatingScoreFetchTask => '正在创建抓取任务...';

  @override
  String get flowBotIsSendingAFriendRequest => 'Bot 正在发送好友申请...';

  @override
  String get flowFriendAddedCreatingScoreFetchTask => '好友已添加，正在创建抓取任务...';

  @override
  String get flowSyncingToDivingFish => '正在同步到水鱼...';

  @override
  String flowSyncCompleteP0ScoresSynced(String p0) {
    return '同步完成！共同步 $p0 条成绩';
  }

  @override
  String get flowSubmittingQRCode => '正在提交二维码...';

  @override
  String get flowSyncingToLXNS => '正在同步到落雪...';

  @override
  String flowSyncCompleteP0ScoresSyncedToLXNS(String p0) {
    return '同步完成！共同步 $p0 条成绩到落雪';
  }

  @override
  String get flowAcceptTheFriendRequestOnNETOr => '等待你在 NET / 机台上通过好友申请';

  @override
  String flowFetchingScoresP0P1(String p0, String p1) {
    return '正在抓取成绩... ($p0/$p1)';
  }

  @override
  String get flowFetchingScores => '正在抓取成绩...';

  @override
  String get flowFetchingFriendList => '正在拉取好友列表...';

  @override
  String get flowTaskQueuedWaitingForProcessing => '任务已排队，等待处理...';

  @override
  String get flowPreviewingData => '正在预览数据...';

  @override
  String get flowSigningIn3 => '正在登录...';

  @override
  String flowReadingChartScoresP0Records(String p0) {
    return '正在获取谱面成绩... ($p0 条)';
  }

  @override
  String get flowReadingChartScores => '正在获取谱面成绩...';

  @override
  String get flowSigningOut => '正在登出...';

  @override
  String get flowCleaningUp => '正在清理...';

  @override
  String flowSavingScoresP0Records(String p0) {
    return '正在保存成绩... ($p0 条)';
  }

  @override
  String get flowSavingScores => '正在保存成绩...';

  @override
  String flowReadingComboAndSyncMarkersFromP0(String p0) {
    return '正在读取$p0已有的连击与同步标记…';
  }

  @override
  String flowCheckingChartsSupportedByP02(String p0) {
    return '正在核对$p0支持的谱面…';
  }

  @override
  String get flowReadingCabinetScoresForThisRound => '正在读取本轮机台成绩…';

  @override
  String flowUpdatingP0ScoresP1P2(String p0, String p1, String p2) {
    return '正在更新$p0成绩（$p1/$p2）…';
  }

  @override
  String flowQuickSyncCompleteUpdatedP0Scores(String p0) {
    return '快速同步完成：更新 $p0 条成绩';
  }

  @override
  String flowSkippedP0UnchangedScores(String p0) {
    return '，跳过 $p0 条未变化成绩';
  }

  @override
  String flowP0ChartsUnmatchedOrUnsupported(String p0) {
    return '，$p0 条谱面未匹配或目标源不支持';
  }

  @override
  String get flowCheckingAWMCGateway2 => '正在检查 AWMC 网关…';

  @override
  String get flowQuicklyReadingCabinetScores => '正在快速读取机台成绩…';

  @override
  String get flowClearSignIn => '清除当前登录状态';

  @override
  String flowBoundQq(String qq) {
    return '当前绑定 QQ：$qq';
  }

  @override
  String get flowStatsNotUpdated => '尚未更新';

  @override
  String get flowStatsJustUpdated => '刚刚更新';

  @override
  String flowStatsSecondsAgo(String count) {
    return '$count 秒前更新';
  }

  @override
  String flowStatsMinutesAgo(String count) {
    return '$count 分钟前更新';
  }

  @override
  String flowStatsHoursAgo(String count) {
    return '$count 小时前更新';
  }

  @override
  String get flowCacheNeverExpires => '永不过期';

  @override
  String get flowCacheNoTimestamp => '无缓存时间戳';

  @override
  String get flowCacheAbsent => '无缓存';

  @override
  String get flowCacheExpiredPrefix => '已过期';

  @override
  String flowCacheExpired(String duration) {
    return '已过期 $duration';
  }

  @override
  String flowCacheRemaining(String duration) {
    return '剩余 $duration';
  }

  @override
  String flowCacheDaysHours(String days, String hours) {
    return '$days 天 $hours 小时';
  }

  @override
  String flowCacheDays(String days) {
    return '$days 天';
  }

  @override
  String flowCacheHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String flowCacheHours(String hours) {
    return '$hours 小时';
  }

  @override
  String flowCacheMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String get flowRankingShowIdentity => '展示昵称与头像';

  @override
  String get flowRankingIdentityHint => '关闭时显示匿名用户和默认头像；自选头像仍会保存并同步。';

  @override
  String get flowRankingShowBrief => '展示排行榜简要信息';

  @override
  String get flowRankingBriefHint => '公开称号、装扮、等级与 Best 成绩；需登录或完成账号身份验证。默认关闭。';

  @override
  String get flowCacheFishSongs => '歌曲数据（水鱼）';

  @override
  String get flowCacheUnionSongs => '歌曲数据（Union）';

  @override
  String get flowCacheDifficulties => '难度数据';

  @override
  String get flowCacheTags => '标签数据';

  @override
  String get flowCacheAlias1 => '别名数据源1';

  @override
  String get flowCacheAlias2 => '别名数据源2';

  @override
  String get flowCacheAlias3 => '别名数据源3';

  @override
  String get flowCacheTitles => '收藏品-称号';

  @override
  String get flowCacheIcons => '收藏品-头像';

  @override
  String get flowCachePlates => '收藏品-姓名框';

  @override
  String get flowCacheFrames => '收藏品-背景';

  @override
  String get flowCacheUnionMetadata => 'Union 元数据';

  @override
  String get flowCacheFishDescription => '全量歌曲主库（diving-fish）';

  @override
  String get flowCacheUnionDescription => '补充独有歌曲（godserver）';

  @override
  String get flowCacheConstantDescription => '谱面定数（diving-fish chart_stats）';

  @override
  String get flowCacheTagDescription => 'DXRating 谱面标签';

  @override
  String get flowCacheTitleDescription => '落雪称号';

  @override
  String get flowCacheIconDescription => '落雪头像';

  @override
  String get flowCachePlateDescription => '落雪姓名框';

  @override
  String get flowCacheFrameDescription => '落雪背景';

  @override
  String get flowCacheMetadataDescription => 'cn/jp 可游玩地区等';

  @override
  String get flowCacheMaidataDescription => '谱面追加辅助（追加列表 + 完整 maidata）';

  @override
  String get flowSongDetails => '歌曲详情';

  @override
  String get flowExpandOrCollapseSongInformation => '展开或收起歌曲信息';

  @override
  String get flowFavorited => '已收藏';

  @override
  String get flowAddToAFavoritesFolder => '收藏到收藏夹';

  @override
  String flowCreatedP0AndAddedThisChart(String p0) {
    return '已创建收藏夹「$p0」并将当前谱面加入';
  }

  @override
  String get flowNoFavoritesFoldersYet => '还没有收藏夹';

  @override
  String get flowCreateAFavoritesFolderFirst => '请先创建收藏夹';

  @override
  String flowP0Charts(String p0) {
    return '$p0 个谱面';
  }

  @override
  String get flowNewFavoritesFolder => '新建收藏夹';

  @override
  String get flowEnterAFolderName => '请输入收藏夹名称';

  @override
  String get flowCreate => '创建';

  @override
  String get flowPause => '暂停';

  @override
  String get flowPlay => '播放';

  @override
  String flowP0P1SBufferedAhead(String p0, String p1) {
    return '$p0 已向前缓冲 $p1 秒';
  }

  @override
  String get flowCouldNotLoadThePVCheckYour => 'PV 加载失败，请检查网络后重试';

  @override
  String get flowBackToSongDetails => '返回歌曲详情';

  @override
  String get flowCopiedToClipboard => '已复制到剪贴板';

  @override
  String get flowExportZIPZip => '导出压缩包 (.zip)';

  @override
  String get flowMaidataTxtCoverArtAndAudioIn => 'maidata.txt + 曲绘 + 音源，通用谱面包';

  @override
  String get flowExportAstroDXChartAdx => '导出 AstroDX 谱面 (.adx)';

  @override
  String get flowOpenInAstroDXToInstallTheChart => '用 AstroDX 打开即可自动安装谱面';

  @override
  String get flowChooseWhereToSaveTheChartPackage => '选择谱面包保存位置';

  @override
  String get flowChooseWhereToSaveTheAstroDXChart => '选择 AstroDX 谱面保存位置';

  @override
  String flowExportFailedP0(String p0) {
    return '导出失败: $p0';
  }

  @override
  String get flowSelectDifficulty => '选择难度';

  @override
  String get flowRenderedChartsAreForReferenceAndMay =>
      '渲染出的谱面仅供参考，不代表官方谱面。对于高密度谱面，请勿频繁拖动进度条，以免造成应用闪退或卡死。';

  @override
  String get flowLoadAudio => '加载音频';

  @override
  String get flowTurnOffToLoadTheChartWithout => '取消勾选可直接加载谱面，跳过音源下载';

  @override
  String get flowFetchingChartConstants => '获取定数中...';

  @override
  String flowSongIDP0(String p0) {
    return '歌曲ID $p0';
  }

  @override
  String get flowChartCode => '谱面代码';

  @override
  String get flowCopy => '复制';

  @override
  String get flowExporting => '导出中';

  @override
  String get flowExport => '导出';

  @override
  String get flowRender => '渲染';

  @override
  String flowVideoGeneratedTapSaveToPhotosOn(String p0, String p1, String p2) {
    return '视频已生成，请在导出页点击“保存到相册”：$p0×$p1 · $p2 MB';
  }

  @override
  String flowLoadedMaidataWithP0Difficulties(String p0) {
    return '已加载maidata，解析到 $p0 个难度';
  }

  @override
  String get flowUnsupportedEncodingUseUTF8OrShift =>
      '读取失败: 文件编码不受支持，请使用UTF-8或Shift-JIS编码';

  @override
  String flowCouldNotOpenTheFilePickerP0(String p0) {
    return '无法打开文件选择器: $p0';
  }

  @override
  String get flowCoverArtSelected => '已选择曲绘';

  @override
  String get flowCoverArtSelectedUsingItsOriginalPath => '已选择曲绘（使用原始路径）';

  @override
  String flowCouldNotOpenTheImagePickerP0(String p0) {
    return '无法打开图片选择器: $p0';
  }

  @override
  String get flowAudioSelected => '已选择音源';

  @override
  String get flowAudioSelectedUsingItsOriginalPath => '已选择音源（使用原始路径）';

  @override
  String flowCouldNotOpenTheAudioPickerP0(String p0) {
    return '无法打开音频选择器: $p0';
  }

  @override
  String flowTheFileForP0IsMissingAnd(String p0) {
    return '「$p0」的文件已不存在，已从列表移除';
  }

  @override
  String flowCouldNotParseAgainP0(String p0) {
    return '重新解析失败：$p0';
  }

  @override
  String get flowDeleteThisRecord => '删除这条记录';

  @override
  String flowRemoveP0FromRecentlyParsedChartsAnd(String p0) {
    return '将从「最近解析」中移除「$p0」，并删除它的存档文件。';
  }

  @override
  String get flowDelete => '删除';

  @override
  String get flowCouldNotReadThisFileTryAnother => '读不到这个文件的内容，请换一个来源重试';

  @override
  String flowImportFailedP0(String p0) {
    return '导入失败：$p0';
  }

  @override
  String get flowNoMaidataTxtFoundThisIsNot => '这个压缩包里没找到 maidata.txt，不是有效的谱面包';

  @override
  String get flowUnsupportedMaidataTxtEncodingUseAUTF =>
      'maidata.txt 编码不受支持，请使用 UTF-8 或 Shift-JIS 编码的谱面包';

  @override
  String flowImportedAllThreeFilesFromP0Found(String p0, String p1) {
    return '已从 $p0 导入三件套，解析到 $p1 个难度';
  }

  @override
  String flowImportedMaidataP0DifficultiesNoP1In(String p0, String p1) {
    return '已导入 maidata（$p0 个难度）；包内没有$p1，可手动补选';
  }

  @override
  String get flowRecentlyParsed => '最近解析';

  @override
  String get flowTapToParseTheArchivedFilesAgain => '点击即可按存档重新解析；长按可删除';

  @override
  String get flowSelectAMaidataFileFirst => '请先选择maidata文件';

  @override
  String get flowNoValidDifficultiesFound => '未找到有效难度';

  @override
  String get flowTurnOffToLoadTheChartWithout2 => '取消勾选可直接加载谱面，跳过音源加载';

  @override
  String get flowSelectionCleared => '已清除选择';

  @override
  String get flowCustomChart => '上传自定义谱面';

  @override
  String get flowImportAChartPackage => '从谱面包导入';

  @override
  String get flowSelectAnAdxOrZipPackageTo =>
      '选择一个 .adx 或 .zip 谱面包，自动解出 maidata.txt / 曲绘 / 音源';

  @override
  String get flowExtracting => '正在解压...';

  @override
  String get flowSelectChartPackage => '选择谱面包';

  @override
  String get flowOrSelectTheThreeFilesSeparately => '或分别选择下面三个文件';

  @override
  String get flowSelectMaidataTxt => '选择maidata.txt';

  @override
  String get flowRequiredATextFileContainingChartData => '必须选择，包含谱面数据的txt文件';

  @override
  String get flowSelectCoverArt => '选择曲绘图片';

  @override
  String get flowOptionalChartBackgroundImagePNGJPG => '可选，谱面背景图片（png/jpg）';

  @override
  String get flowSelectAudio => '选择音源文件';

  @override
  String get flowOptionalChartMusicMP3WAVOGG => '可选，谱面背景音乐（mp3/wav/ogg）';

  @override
  String get flowParsedDifficulties => '解析到的难度:';

  @override
  String get flowStartPlayback => '开始播放';

  @override
  String get flowInstructions => '使用说明:';

  @override
  String get flowOption1SelectAnAdxOrZip =>
      '方式一：点「选择谱面包」直接选一个 .adx / .zip，三件套一次填好';

  @override
  String get flowOption2TapARecentlyParsedEntry =>
      '方式二：点「最近解析」里的记录，一键重新解析之前用过的谱面包';

  @override
  String get flowOption3SelectMaidataTxtCoverArt =>
      '方式三：分别选择 maidata.txt、曲绘、音源三个文件';

  @override
  String get flow1MaidataTxtIsRequiredTheOther => '1. maidata.txt 为必选，其余两个可留空';

  @override
  String get flow2DifficultiesAreDetectedAutomatically => '2. 系统会自动解析谱面中的难度';

  @override
  String get flow3SelectADifficultyThenStartPlayback => '3. 选择想要渲染的难度后即可开始播放';

  @override
  String flowSelectedP0(String p0) {
    return '已选择: $p0';
  }

  @override
  String get flowChooseAgain2 => '重新选择';

  @override
  String get flowChooseFile => '选择文件';

  @override
  String get flowChooseWhereToSaveTheSong => '选择歌曲保存位置';

  @override
  String get flowDownloaded => '下载成功';

  @override
  String get flowGoToCurrentSong => '定位到正在播放';

  @override
  String get flowRebuildLibrary => '重建曲库';

  @override
  String get flowMusicPlayerSettings => '随身听设置';

  @override
  String get flowShowFloatingPlayerAfterLeavingThisPage => '退出随身听页面时显示悬浮球';

  @override
  String get flowWhenOffLeavingTheMusicPlayerWill => '关闭后，离开随身听页面也不会重新显示悬浮球';

  @override
  String get flowSearchTitleArtistGenreAliasBPMID =>
      '搜索曲名 / 艺术家 / 流派 / 别名 / BPM / id';

  @override
  String get flowNowPlaying => '正在播放';

  @override
  String get flowPaused => '已暂停';

  @override
  String get flowUnknownArtist => '未知艺术家';

  @override
  String get flowDownloadSong => '下载歌曲';

  @override
  String get flowAddToPlayNext => '加入下次想玩';

  @override
  String get flowAddedToPlayNext => '已加入下次想玩';

  @override
  String get flowPlayMusic => '播放音乐';

  @override
  String get flowNothingPlayingYet => '还没有在放的音乐';

  @override
  String get flowPreparingAudio => '正在准备音源…';

  @override
  String get flowPrevious2 => '上一首';

  @override
  String get flowNext2 => '下一首';

  @override
  String get flowChooseSortOrder => '选择排序方式';

  @override
  String get flowDXScoreRate => 'DX分数达成率';

  @override
  String get flowAchievementFilter => '达成率筛选';

  @override
  String get flowComboSyncFilter => '连击/同步筛选';

  @override
  String get flowAnyOptionWithinAGroupMatchesWhen => '同组内满足任意一项，连击和同步都选时需同时满足';

  @override
  String get flowCloseSearch => '关闭搜索';

  @override
  String get flowSearchSongTitleOrConstant => '搜索曲名或定数';

  @override
  String get flowNoCachedDataFound => '没有找到缓存数据';

  @override
  String get flowTapASegmentOrStatisticToFilter => '点色块或统计项筛选 · 共 ';

  @override
  String get flowEntries => ' 条';

  @override
  String flowFilteredByP0TapAgainToClear(String p0) {
    return '已筛选 $p0 · 再点取消';
  }

  @override
  String flowP0P1EntriesTapToFilter(String p0, String p1) {
    return '$p0 $p1 条，点按筛选';
  }

  @override
  String get flowComboSync => '连击/同步';

  @override
  String get flowPerPage => '每页显示';

  @override
  String flowP0Entries(String p0) {
    return '共 $p0 条';
  }

  @override
  String get flowList => '列表';

  @override
  String get flowUnknownSong => '未知歌曲';

  @override
  String get flowSelectMultipleAnySelectedOptionMatches => '可多选，满足任意一项即可';

  @override
  String flowClearP0(String p0) {
    return '清除$p0';
  }

  @override
  String get flowQuickOptions => '快捷选项';

  @override
  String get flowCustomRange => '自定义范围';

  @override
  String get flowExportAsImage => '导出为图片';

  @override
  String get flowSelectCategory => '选择种类';

  @override
  String get flowLevel => '等级';

  @override
  String get flowNoChartDesignerDataFound => '没有找到谱师数据';

  @override
  String get flowSelectVersion => '选择版本';

  @override
  String get flowNoComposerDataFound => '没有找到曲师数据';

  @override
  String get flowNoGenreDataFound => '没有找到流派数据';

  @override
  String get flowSelectGenre => '选择流派';

  @override
  String flowP0P1Songs2(String p0, String p1) {
    return '$p0 ($p1首)';
  }

  @override
  String get flowSelectLevel => '选择等级';

  @override
  String get flowNoCompletedSongsYet => '暂无已完成歌曲';

  @override
  String get flowNoIncompleteSongs => '暂无未完成歌曲';

  @override
  String get flowStoragePermissionIsRequiredToExportImages =>
      '需要存储权限才能导出图片到相册，请在设置中开启权限';

  @override
  String get flowPersonalizedScores => '个性化成绩';

  @override
  String flowExportFailedP02(String p0) {
    return '导出失败：$p0';
  }

  @override
  String get flowCouldNotOpenTheAuthorizationPageLink => '无法打开授权页，链接已复制到剪贴板';

  @override
  String get flowFetchingFriendDataAndComparing => '正在拉取好友数据并对比…';

  @override
  String flowCompareMyP0ScoresWithMyFriend(String p0) {
    return '用我的$p0成绩，对比好友在这里的成绩';
  }

  @override
  String flowEnterYourFriendSP0(String p0) {
    return '输入好友的$p0';
  }

  @override
  String get flowCompare => '开始对比';

  @override
  String get flowCompareWithAFriend => '和好友比比看';

  @override
  String flowEnterYourFriendSP0ToCompare(String p0, String p1) {
    return '输入好友的$p0开始对比\n好友需要在$p1有数据';
  }

  @override
  String get flowClearHistory => '清空历史';

  @override
  String get flowClearAllHistory => '确定要清空全部历史记录吗？';

  @override
  String get flowPastComparisons => '历史对比';

  @override
  String flowP0P1P2SongsInCommon(String p0, String p1, String p2) {
    return '$p0 · $p1 · 共同 $p2 首';
  }

  @override
  String get flowPrivate => '未公开';

  @override
  String get flowSameScore => '同分';

  @override
  String get flowMyCharts => '我的谱面';

  @override
  String get flowFriendSCharts => '好友谱面';

  @override
  String get flowSharedCharts => '共同谱面';

  @override
  String get flowAllDifficulties => '全部难度';

  @override
  String flowConstantHighToLowShowingP0P1(String p0, String p1) {
    return '按定数从高到低 · 显示 $p0 / $p1';
  }

  @override
  String get flowNoMatchingCharts => '没有符合条件的谱面';

  @override
  String flowLoadMoreP0P1(String p0, String p1) {
    return '加载更多（$p0 / $p1）';
  }

  @override
  String get flowTie => '平局';

  @override
  String get flowSelectFirstCharacter => '选择首字';

  @override
  String flowP0SongsExcludedFromPlateProgress(String p0) {
    return '共 $p0 首，不计入牌子进度';
  }

  @override
  String flowP0P1P2Statistics(String p0, String p1, String p2) {
    return '$p0$p1($p2)统计';
  }

  @override
  String get flowRecommendationSettings => '推荐参数';

  @override
  String flowConstantsP0P1P2Results(String p0, String p1, String p2) {
    return '定数范围 $p0 ~ $p1 · 共 $p2 条结果';
  }

  @override
  String get flowTargetRating => '目标 Rating';

  @override
  String get flowRecommend => '推荐';

  @override
  String get flowLoadingRecommendations => '正在加载推荐结果...';

  @override
  String get flowNoRecommendationsCheckTheRatingYouEntered =>
      '暂无推荐结果，请检查Rating输入是否正确';

  @override
  String flowCouldNotSaveHistoryP0(String p0) {
    return '保存历史失败：$p0';
  }

  @override
  String flowCouldNotDeleteDataPointP0(String p0) {
    return '删除记录点失败：$p0';
  }

  @override
  String get flowLinkYourQQThroughSyncScoresTo =>
      'AWMC NET 还没绑定 QQ，请先在「同步成绩到 AWMC NET」入口绑定';

  @override
  String flowNoRatingRecordsForQQP0On(String p0) {
    return 'AWMC NET 上 QQ $p0 近 90 天没有任何 Rating 记录';
  }

  @override
  String flowSyncedRatingHistoryFromAWMCNETAdded(String p0) {
    return '已从 AWMC NET 同步 Rating 趋势，新增 $p0 条';
  }

  @override
  String flowNoNewAWMCNETPointsP0Already(String p0) {
    return 'AWMC NET 没有新数据点（$p0 条都已记录过）';
  }

  @override
  String get flowSyncRatingHistoryFromAWMCNET => '从 AWMC NET 同步 Rating 趋势';

  @override
  String get flowAddHistoryRecord => '添加历史记录';

  @override
  String flowCurrentSourceP0(String p0) {
    return '当前数据源：$p0';
  }

  @override
  String flowBaselinesForP0ChartsP1ScoreChanges(String p0, String p1) {
    return '已记录 $p0 张谱面的成绩基线 · $p1 次成绩变化（曲目详情页里，单谱的达成率 / DX分数曲线就画在这些变化上）';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs(String p0) {
    return '水鱼 / 落雪 / AWMC NET 按账号分别记录历史。$p0（AWMC NET 数据源下可点右上角「云同步」按钮回填历史趋势）';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs2(String p0) {
    return '水鱼 / 落雪 / AWMC NET 按账号分别记录历史。$p0（历史只能从现在开始攒：水鱼与落雪都不提供历史成绩接口）';
  }

  @override
  String get flowHighest => '最高';

  @override
  String get flowDataPoints => '记录点';

  @override
  String flowP0EntriesShowingTheLatest30(String p0) {
    return '共 $p0 条，显示最近 30 条';
  }

  @override
  String get flowNoHistoryYet => '还没有历史数据';

  @override
  String get flowEachDataRefreshRecordsAPointAutomatically =>
      '每次「拉取成绩并更新数据」都会顺手记一笔，不需要额外操作。\n时间精确到秒；同一秒重复刷新会更新该点，不同时间的变化会分别保留。';

  @override
  String get flowAddRatingHistory => '添加 Rating 历史';

  @override
  String get flowCurrentTheoreticalRating => '当前理论 Rating';

  @override
  String get flowBest35Optional => 'Best35（可选）';

  @override
  String get flowCurrentTheoreticalB35 => '当前理论 B35';

  @override
  String get flowBest15Optional => 'Best15（可选）';

  @override
  String get flowCurrentTheoreticalB15 => '当前理论 B15';

  @override
  String get flowAboutScoreImprovementHistory => '关于成绩提升历史';

  @override
  String get flowLocalScoreHistoryForThisAccount => '当前账号的本地成绩历史';

  @override
  String get flowRecordingStartsAfterADataRefreshThe =>
      '刷新数据后开始记录；首次无旧成绩时仅建立基线。';

  @override
  String flowRecordedSinceP0SameDayChangesTo(String p0) {
    return '$p0 起记录 · 同日同谱面自动合并';
  }

  @override
  String get flowCharts => '谱面';

  @override
  String get flowImprovement => '提升';

  @override
  String get flowChanges => '变化次数';

  @override
  String get flowRecordingRules => '记录规则';

  @override
  String flowLoadMoreFromThisDayP0Charts(String p0) {
    return '加载当天更多记录（剩余 $p0 张）';
  }

  @override
  String get flowNoRatingsYet => '暂无评分记录';

  @override
  String get flowNoCommentsYet => '暂无评论';

  @override
  String get flowNoBest50DataYet => '暂无Best50数据';

  @override
  String get flowReturnHomeAndTapRefreshData => '请返回首页点击“拉取成绩并更新数据”按钮获取';

  @override
  String get flowTheoreticalRatingBest50 => '理论Rating Best50';

  @override
  String get flowSaveCurrentRecord => '保存当前记录';

  @override
  String get flowHistory => '历史记录';

  @override
  String get flowAccountDataChangedReopenBest50BeforeSaving =>
      '账号数据已更新，请重新打开 Best50 后保存';

  @override
  String flowBest50RecordSavedP0(String p0) {
    return 'Best50 记录已保存 ($p0)';
  }

  @override
  String get flowBest50History => 'Best50 历史记录';

  @override
  String get flowNoSavedRecordsTapSaveCurrentRecord =>
      '暂无保存的记录，点击\"保存当前记录\"按钮保存';

  @override
  String flowTheoreticalRatingAverageP0(String p0) {
    return '理论 Rating（平均 $p0）';
  }

  @override
  String flowCurrentRatingAverageP0(String p0) {
    return '当前 Rating（平均 $p0）';
  }

  @override
  String get flowTheoretical => '理论值';

  @override
  String get flowAverageAchievementDXScoreRate => '平均达成率 / DX 分数达成率';

  @override
  String get flowTagStatistics => '标签统计';

  @override
  String get flowTheoreticalBest50 => '理论 Best50';

  @override
  String get flowCalculatingFittedBest50 => '正在计算拟合Best50...';

  @override
  String get flowNoFittedBest50DataYet => '暂无拟合Best50数据';

  @override
  String flowFittedTotalRatingDifferenceFromBest50Average(String p0) {
    return '拟合总 Rating · 较 Best50（平均 $p0）';
  }

  @override
  String flowModeP0(String p0) {
    return '模式 $p0';
  }

  @override
  String get flowNoDataToExport => '没有数据可导出';

  @override
  String flowCategoryChartDesigner50P0(String p0) {
    return '选择类型: 谱师50 - $p0';
  }

  @override
  String flowCategoryVersion50P0(String p0) {
    return '选择类型: 版本50 - $p0';
  }

  @override
  String flowCategoryGenre50P0(String p0) {
    return '选择类型: 流派50 - $p0';
  }

  @override
  String flowCategoryStar50P0(String p0) {
    return '选择类型: 星数50 - $p0';
  }

  @override
  String flowCategoryTag50P0(String p0) {
    return '选择类型: 标签50 - $p0';
  }

  @override
  String get flowCategoryRandom50 => '选择类型: 随机50';

  @override
  String get flowCategoryOverreach50 => '选择类型: 越级50';

  @override
  String flowCategoryDifficulty50P0(String p0) {
    return '选择类型: 难度50 - $p0';
  }

  @override
  String flowCategoryBestP0(String p0) {
    return '选择类型: Best $p0';
  }

  @override
  String flowCategoryP0(String p0) {
    return '选择类型: $p0';
  }

  @override
  String get flowChooseCategory => '选择类型';

  @override
  String get flowNoVersionDataFound => '没有找到版本数据';

  @override
  String get flowSelectStars => '选择星数';

  @override
  String get flowGenerateBestN => '生成 Best N';

  @override
  String get flowEnterAnIntegerOf1OrMore => '请输入 ≥ 1 的整数';

  @override
  String get flowNoTagDataFound => '没有找到标签数据';

  @override
  String get flowSelectTag => '选择标签';

  @override
  String get flowNoMatchingChartDesigners => '没有找到符合条件的谱师数据';

  @override
  String flowP0P1Charts(String p0, String p1) {
    return '$p0 ($p1谱面)';
  }

  @override
  String get flowTotalCharts => '总谱面数';

  @override
  String get flowAverageRA => '平均RA值';

  @override
  String get flowInclusionMode => '包含关系模式';

  @override
  String get flowDrawAgain => '再抽一次';

  @override
  String flowNoChartDesigner50DataForP0(String p0) {
    return '暂无谱师50 - $p0 数据';
  }

  @override
  String flowNoVersion50DataForP0(String p0) {
    return '暂无版本50 - $p0 数据';
  }

  @override
  String flowNoGenre50DataForP0(String p0) {
    return '暂无流派50 - $p0 数据';
  }

  @override
  String flowNoStar50DataForP0(String p0) {
    return '暂无星数50 - $p0 数据';
  }

  @override
  String flowNoP0DataYet(String p0) {
    return '暂无$p0数据';
  }

  @override
  String get flowRefreshArcadePlayCountsFromMeBefore =>
      '请先在「我的」页「刷新机台游玩次数」，再查看 PC50';

  @override
  String flowSelectTagP0(String p0) {
    return '选择标签: $p0';
  }

  @override
  String get flowCalculatingPersonalizedFittedBest50 => '正在计算个性化拟合Best50...';

  @override
  String get flowSelectATagFirst => '请先选择一个标签';

  @override
  String get flowSelectATagToShowYourTop =>
      '选择标签后，将显示包含该标签且有游玩记录\n在拟合定数下RA前50的谱面';

  @override
  String flowNoFittedBest50DataForTagP0(String p0) {
    return '暂无标签\"$p0\"的拟合Best50数据';
  }

  @override
  String get flowNoMatchingPlayRecordsMayExistTry =>
      '该标签可能没有对应的游玩记录\n可尝试更换其他标签';

  @override
  String get flowChangeTag => '更换标签';

  @override
  String flowFittedTotalRatingDifferenceFromThisTag(String p0) {
    return '拟合总 Rating · 较该标签 Best50（平均 $p0）';
  }

  @override
  String get flowNoCachedPlayData => '暂无游玩数据缓存';

  @override
  String get flowIdealRatingRaiseNonSSSScoresTo =>
      '理想 Rating · 非 SSS+ 成绩升到上一档的下限';

  @override
  String get flowOriginalRating => '原 Rating';

  @override
  String get flowNewEntries => '新进榜';

  @override
  String flowNewEntriesThisTimeP0Songs(String p0) {
    return '本次新进榜（$p0 首）';
  }

  @override
  String get flowNoNewEntriesTheSameChartsRemain => '无新歌进榜（升档后榜单成员不变）';

  @override
  String flowConstantP0RAP1P2(String p0, String p1, String p2) {
    return '定数 $p0 · RA $p1 → $p2';
  }

  @override
  String get flowNoData2 => '无数据';

  @override
  String flowSlotP0(String p0) {
    return '第 $p0 格';
  }

  @override
  String get flowNotSelected => '未选择';

  @override
  String flowP0P1ConstantP2(String p0, String p1, String p2) {
    return '$p0 · $p1 · 定数 $p2';
  }

  @override
  String get flowSelectASongFirst => '请先选择歌曲';

  @override
  String flowInvalidAchievementExceedsP0(String p0) {
    return '非法数据：达成率超过 $p0%';
  }

  @override
  String flowInvalidDXScoreExceedsTheChartMaximum(String p0) {
    return '非法数据：DX 分数超过谱面上限 $p0';
  }

  @override
  String get flowClearThisCard => '清空本卡';

  @override
  String get flowNoCardsFilledInYet => '还没有填写任何卡片';

  @override
  String flowByP0(String p0) {
    return '按$p0';
  }

  @override
  String get flowClearAll => '清空全部';

  @override
  String get flowClearAll50SlotsThisCannotBe => '确定要清空全部 50 个卡位吗？此操作不可撤销。';

  @override
  String get flowCustomBest50TotalRA => '自定义 Best50 总 RA';

  @override
  String flowCurrentOrderP0ClearedWhenCardsChange(String p0) {
    return '当前排序：$p0（卡片变动后自动清除）';
  }

  @override
  String get flowAutoSort => '一键排序';

  @override
  String get flowTapToFillIn => '点击填写';

  @override
  String flowP0Passed(String p0) {
    return '/ $p0 已合格';
  }

  @override
  String flowRedPassP0(String p0) {
    return '赤合格 $p0';
  }

  @override
  String flowFailedP0(String p0) {
    return '不合格 $p0';
  }

  @override
  String get flowDanCourseSongs => '段位曲目';

  @override
  String get flowDanCertification => '段位认定';

  @override
  String get flowMyChallenges => '我的挑战';

  @override
  String get flowEstimatedResult => '预计结果';

  @override
  String get flowFailed2 => '不合格';

  @override
  String get flowPassed => '合格';

  @override
  String get flowTotalAchievement => '总达成率';

  @override
  String get flowRemainingLife => '剩余血量';

  @override
  String flowSongP02(String p0) {
    return '曲目 $p0';
  }

  @override
  String get flowEstimatedMinimumLifeLoss => '预计最低扣血';

  @override
  String get flowLifeSettings => '血量设置';

  @override
  String get flowStartingLife => '初始血量';

  @override
  String get flowClearRecovery => '通关回复';

  @override
  String get flowNoDanDataFound => '未找到段位数据';

  @override
  String get flowYouAreOutsideTheTop100 => '抱歉，您不在前100名内';

  @override
  String flowP0Entries2(String p0) {
    return '$p0条';
  }

  @override
  String get flowNoRankingDataYet => '暂无排行数据';

  @override
  String get flowRefresh => '刷新';

  @override
  String get flowGoToMyRank => '跳转到我的排名';

  @override
  String flowDifferenceFromBest50P0P1(String p0, String p1) {
    return '与Best50差值 $p0$p1';
  }

  @override
  String flowModeP02(String p0) {
    return '模式$p0';
  }

  @override
  String get flowDisclaimer => '免责声明';

  @override
  String get flowThisLeaderboardIsForReferenceAndEntertainment =>
      '本排行榜数据仅供参考和娱乐使用，不代表任何官方立场或权威性排名。排名数据基于玩家自愿上传的游戏数据，可能存在误差或延迟。请理性看待排名结果，享受游戏乐趣。';

  @override
  String get flowDoNotShowAgain => '不再提示';

  @override
  String flowDXScoreDisplayP0TapToSwitch(String p0) {
    return 'DX分数显示方式：$p0（点击切换）';
  }

  @override
  String get flowDXScoreRanking => 'DX分数榜';

  @override
  String get flowAchievementRanking => '达成率榜';

  @override
  String get flowNoOneIsRankedYetBeThe => '榜上无人哦，快来抢沙发！';

  @override
  String get flowYourPlayDataForThisChartAppears => '您的此谱面游玩数据存在异常，请检查!';

  @override
  String get flowChooseRankingType => '选择排行榜类型';

  @override
  String get flowReverse => '反向';

  @override
  String get flowForward => '正向';

  @override
  String get flowShowingPreviouslySavedDataRefreshWhenConnected =>
      '当前展示上次保存的数据，联网后可刷新。';

  @override
  String get flowNoLeaderboardDataYetTryRefreshingLater => '暂无排行榜数据，稍后刷新试试吧';

  @override
  String get flowBilibiliChartVideoViews => 'B站谱面确认播放量';

  @override
  String flowDifficultyP02(String p0) {
    return '难度: $p0';
  }

  @override
  String flowCurrentViewsP0(String p0) {
    return '当前播放量: $p0';
  }

  @override
  String flowBVIDP0(String p0) {
    return 'BV号: $p0';
  }

  @override
  String flowSourceP0(String p0) {
    return '来源: $p0';
  }

  @override
  String get flowLoadingViews => '正在加载播放量...';

  @override
  String get flowNoViewDataYet => '暂无播放量数据';

  @override
  String get flowEnterBVIDManually => '手动上传 BV 号';

  @override
  String get flowIfViewsCannotBeFetchedAutomaticallyEnter =>
      '当自动获取播放量失败时，可手动输入该歌曲谱面确认视频的 BV 号';

  @override
  String get flowExampleBV1xx411c7mD => '例如: BV1xx411c7mD';

  @override
  String flowViewsP0(String p0) {
    return '播放量: $p0';
  }

  @override
  String flowP010000(String p0) {
    return '$p0万';
  }

  @override
  String get flowCheckBVID => '校验 BV 号';

  @override
  String get flowBVIDUploaded => 'BV 号已上传';

  @override
  String get flowConfirmUpload => '确认上传';

  @override
  String get flowChartScoreCard => '谱面成绩卡';

  @override
  String get flowScoreShareCard => '成绩分享卡片';

  @override
  String get flowSongInformation => '歌曲信息';

  @override
  String get flowSongInformationImage => '曲目信息图片';

  @override
  String get flowStoragePermissionIsRequiredToSaveImages => '需要存储权限才能保存图片';

  @override
  String get flowCouldNotLoadCoverArt => '无法加载封面图片';

  @override
  String get flowCoverArtSavedToPhotos => '曲绘已保存到相册';

  @override
  String flowSaveFailedP02(String p0) {
    return '保存失败: $p0';
  }

  @override
  String get flowPlayPV => '播放 PV';

  @override
  String get flowChooseHowToPlayThePV => '请选择 PV 的播放方式';

  @override
  String get flowOpenBilibili => '前往 B 站';

  @override
  String get flowPlayInApp => 'APP 内播放';

  @override
  String get flowPleaseWait => '请稍候';

  @override
  String get flowLoadingRelatedCollectibles => '正在加载相关收藏品...';

  @override
  String get flowError => '错误';

  @override
  String get flowCouldNotLoadRelatedCollectiblesTryAgain => '获取相关收藏品时出错，请稍后重试';

  @override
  String get flowChartNotes => '谱面笔记';

  @override
  String get flowAddChartNotes => '添加谱面笔记';

  @override
  String get flowWriteYourNotesForThisChartHere =>
      '在这里写下你对这个谱面的笔记...\n例如：结尾的滑星要注意手顺';

  @override
  String flowCreatedP0P1(String p0, String p1) {
    return '创建于: $p0$p1';
  }

  @override
  String flowUpdatedP0(String p0) {
    return '\n更新于: $p0';
  }

  @override
  String get flowConfirmDeletion => '确认删除';

  @override
  String get flowDeleteTheNotesForThisChartThis => '确定要删除这个谱面的笔记吗？此操作不可撤销。';

  @override
  String get flowRelatedCollectibles => '相关收藏品';

  @override
  String get flowNoCollectiblesLinkedToThisSong => '未找到与该歌曲相关的收藏品';

  @override
  String get flowRefreshDataOnTheHomePageTo => '请先在首页刷新数据以获取用户身份';

  @override
  String get flowRatingSubmitted => '评分提交成功';

  @override
  String get flowCouldNotSubmitRating => '评分提交失败';

  @override
  String get flowDeleteYourRating => '确定要删除您的评分吗？';

  @override
  String get flowRatingDeleted => '评分删除成功';

  @override
  String get flowCouldNotDeleteRating => '评分删除失败';

  @override
  String get flowChartRating => '谱面评分';

  @override
  String flowP0Ratings(String p0) {
    return '($p0人评分)';
  }

  @override
  String get flowDistribution => '分布';

  @override
  String get flowRatingsAreForReferencePleaseRateObjectively => '评分仅供参考，请客观评价';

  @override
  String get flowRefreshRatings => '刷新评分';

  @override
  String get flowMyRecentRatings => '我的最近评分';

  @override
  String get flowMyRatingTapToEdit => '我的评分（点击修改）';

  @override
  String get flowRateThisChart => '为这个谱面评分';

  @override
  String get flowDeleteRating => '删除评分';

  @override
  String get flowUpdate => '更新';

  @override
  String get flowSubmit => '提交';

  @override
  String get flowRefreshDataOnTheHomePageTo2 => '请在首页刷新数据以获取身份后再评分';

  @override
  String get flowNoRatingsYet2 => '暂无评分数据';

  @override
  String get flowRatingDistribution => '评分分布';

  @override
  String flowP0Ratings2(String p0) {
    return '共 $p0 人评分';
  }

  @override
  String flowAverageP0(String p0) {
    return '均分 $p0';
  }

  @override
  String get flowSetYourIdentityFirst => '请先设置身份信息';

  @override
  String get flowCommentPosted => '评论发布成功';

  @override
  String get flowCouldNotPostComment => '评论发布失败';

  @override
  String flowCouldNotPostCommentP0(String p0) {
    return '评论发布失败：$p0';
  }

  @override
  String get flowCannotDeleteIdentityInformationIsMissing => '无法删除：身份信息缺失';

  @override
  String get flowDeleteThisComment => '确定要删除这条评论吗？';

  @override
  String get flowCommentDeleted => '评论删除成功';

  @override
  String get flowCouldNotDeleteComment => '评论删除失败';

  @override
  String get flowComments => '评论';

  @override
  String get flowCommentsRefreshed => '已刷新评论';

  @override
  String get flowRefreshComments => '刷新评论';

  @override
  String get flowCommentsAreForReferencePleaseBeRespectful => '评论仅供参考，请文明发言';

  @override
  String get flowRefreshDataOnTheHomePageTo3 => '请在首页刷新数据以获取评论身份';

  @override
  String get flowEnterYourComment => '输入您的评论内容...';

  @override
  String get flowPost => '发表';

  @override
  String get flowNoCommentsYetBeTheFirstTo => '暂无评论，快来发表第一条评论吧！';

  @override
  String get flowMe => '我';

  @override
  String get flowViewNotes => '查看笔记';

  @override
  String get flowAddNotes => '添加笔记';

  @override
  String get flowExportSongInformation => '导出歌曲信息';

  @override
  String get flowShareScore => '分享成绩';

  @override
  String get flowEnlargeCoverArt => '放大曲绘';

  @override
  String get flowSwitchToDX => '切换 DX';

  @override
  String get flowSwitchToST => '切换 ST';

  @override
  String flowP0LevelP1(String p0, String p1) {
    return '$p0 等级 $p1';
  }

  @override
  String flowNoScoreForP0Yet(String p0) {
    return '还没有 $p0 的成绩';
  }

  @override
  String get flowPlayAndSyncToSeeYourScore => '打完同步一下就会显示在这里';

  @override
  String flowDXScoreMAXP0(String p0) {
    return 'DX分数（MAX -$p0）';
  }

  @override
  String get flowShowStarBonus => '显示星级加成';

  @override
  String get flowShowPointsNeededForTheNextStar => '显示距下一星还差多少';

  @override
  String get flowRatingPotential => '上分潜力';

  @override
  String get flowBasicInformation => '基础信息';

  @override
  String get flowNoteDistribution => '物量分布';

  @override
  String get flowBREAKDistribution => '绝赞分布';

  @override
  String get flowNoGlobalGradeOrComboDistributionData => '这张谱面暂时没有全站评级与连击分布数据';

  @override
  String get flowTAPGREATsAllBREAKsCriticalPerfect => '个 TAP GREAT（绝赞全 CP）';

  @override
  String get flowOpenCalculatorWithThisChartSNotes => '带上这张谱面的物量与成绩打开计算器';

  @override
  String get flowNoTagsYet => '暂无标签';

  @override
  String get flowTagDataFrom => '标签数据来源自 ';

  @override
  String get flowUnknownTag => '未知标签';

  @override
  String get flowConstantHistory => '定数历史';

  @override
  String get flowStarsDXScoreTable => '星数-DX分数对照表';

  @override
  String get flowStars => '星数';

  @override
  String get flowDXScore2 => 'DX分数';

  @override
  String get flowPlayers => '玩家';

  @override
  String get flowAchievementScoreTable => '达成率-得分对照表';

  @override
  String get flowScore => '得分';

  @override
  String get flowJudgmentAllowance => '容错计算';

  @override
  String get flowNoteType => '音符类型:';

  @override
  String get flowShareOfTotalWeight => '占总权重比例:';

  @override
  String get flowBREAKLossSoFar => '已打出的BREAK损失';

  @override
  String get flow50PointLosses => '50落数量';

  @override
  String get flowInvalid => '无效';

  @override
  String get flow100PointLosses => '100落数量';

  @override
  String get flow80GREATCount => '80%GREAT数量';

  @override
  String get flow60GREATCount => '60%GREAT数量';

  @override
  String get flow50GREATCount => '50%GREAT数量';

  @override
  String get flowGOODCount => 'GOOD数量';

  @override
  String get flowMISSCount => 'MISS数量';

  @override
  String get flowTotalBREAKLoss => 'BREAK总损失: ';

  @override
  String get flowRemainingBudgetSSS => '剩余预算(SSS+): ';

  @override
  String get flowRemainingBudgetSSS2 => '剩余预算(SSS): ';

  @override
  String get flowRemainingBudgetSS => '剩余预算(SS+): ';

  @override
  String get flowRemainingBudgetSS2 => '剩余预算(SS): ';

  @override
  String get flowGREATLoss => 'GREAT损失';

  @override
  String get flowGOODLoss => 'GOOD损失';

  @override
  String get flowMISSLoss => 'MISS损失';

  @override
  String get flowSSSGREATAllowance => 'SSS+容错(GREAT)';

  @override
  String get flowSSSGOODAllowance => 'SSS+容错(GOOD)';

  @override
  String get flowSSSMISSAllowance => 'SSS+容错(MISS)';

  @override
  String flowP0(String p0) {
    return '$p0个';
  }

  @override
  String get flowSSSGREATAllowance2 => 'SSS容错(GREAT)';

  @override
  String get flowSSSGOODAllowance2 => 'SSS容错(GOOD)';

  @override
  String get flowSSSMISSAllowance2 => 'SSS容错(MISS)';

  @override
  String get flowSSGREATAllowance => 'SS+容错(GREAT)';

  @override
  String get flowSSGOODAllowance => 'SS+容错(GOOD)';

  @override
  String get flowSSMISSAllowance => 'SS+容错(MISS)';

  @override
  String get flowSSGREATAllowance2 => 'SS容错(GREAT)';

  @override
  String get flowSSGOODAllowance2 => 'SS容错(GOOD)';

  @override
  String get flowSSMISSAllowance2 => 'SS容错(MISS)';

  @override
  String get flow50PointLoss => '50落损失';

  @override
  String get flow100PointLoss => '100落损失';

  @override
  String get flow80GREATLoss => '80%GREAT损失';

  @override
  String get flow60GREATLoss => '60%GREAT损失';

  @override
  String get flow50GREATLoss => '50%GREAT损失';

  @override
  String get flow0580GREATAllowance => '-0.5%容错80%GREAT';

  @override
  String get flow0560GREATAllowance => '-0.5%容错60%GREAT';

  @override
  String get flow0550GREATAllowance => '-0.5%容错50%GREAT';

  @override
  String get flow05Allowance => '-0.5%容错';

  @override
  String get flow180GREATAllowance => '-1%容错80%GREAT';

  @override
  String get flow160GREATAllowance => '-1%容错60%GREAT';

  @override
  String get flow150GREATAllowance => '-1%容错50%GREAT';

  @override
  String get flow1Allowance => '-1%容错';

  @override
  String get flowGradeDistributionReferenceOnly => '评级分布(仅供参考)';

  @override
  String get flowComboDistributionReferenceOnly => '连击分布(仅供参考)';

  @override
  String get flowInTheOrderBPMMarkersAppearIn => '按当前谱面中 BPM 标记的出现顺序';

  @override
  String get flowChangeIndex => '变化序号';

  @override
  String get flowPlayOnBilibili => 'B站播放';

  @override
  String get flowPlayableRegions => '可游玩地区';

  @override
  String get flowParsingDataUnavailable => '暂缺解析数据';

  @override
  String get flowExcludesSLIDETOUCHAndBREAKStars => '不含 SLIDE、TOUCH 和绝赞星星。';

  @override
  String get flowAliasesNone => '别名: 无';

  @override
  String flowAliasesForP0(String p0) {
    return '$p0的别名';
  }

  @override
  String get flowTapAnyAliasToCopy => '点击任意别名即可复制';

  @override
  String flowViewAliasesP0(String p0) {
    return '查看别名 ($p0)';
  }

  @override
  String flowDXScoreP02(String p0) {
    return 'DX分数 $p0%';
  }

  @override
  String flowRankP0P1RatingP2(String p0, String p1, String p2) {
    return '第 $p0 名，$p1，Rating $p2';
  }

  @override
  String get flowRatingHeadroom => '推分空间';

  @override
  String flowRaiseToP0P1(String p0, String p1) {
    return '推到 $p0（$p1%）';
  }

  @override
  String flowDXScoreP0P12(String p0, String p1) {
    return 'DX分数 $p0 / $p1';
  }

  @override
  String get flowViewSongDetails => '查看歌曲详情';

  @override
  String flowP0SongsRemaining(String p0) {
    return '剩余 $p0 首';
  }

  @override
  String flowP0EqualToTheLastChartOn(String p0) {
    return '$p0，和榜单最后一首相同';
  }

  @override
  String flowP0ConstantP1RAP2(String p0, String p1, String p2) {
    return '$p0 · 定数 $p1 · RA $p2';
  }

  @override
  String get flowAddScoreHistory => '添加成绩历史';

  @override
  String flowScoreHistoryP0(String p0) {
    return '成绩历史（$p0）';
  }

  @override
  String get flowTheCurveDropsInGameScoresKeep =>
      '曲线出现下降：游戏里成绩取最高，这多半是切换数据源/账号造成的记录差异';

  @override
  String get flowUnknownDate => '日期未知';

  @override
  String flowShowAllP0Entries(String p0) {
    return '展开全部（$p0 条）';
  }

  @override
  String get flowAddChartScoreHistory => '添加谱面成绩历史';

  @override
  String get flowAchievement3 => '达成率（%）';

  @override
  String get flowSumOfUTAGESubcharts => '宴会场子谱相加';

  @override
  String get flowNormalChartLimit => '普通谱面上限';

  @override
  String get flowDXScoreOptional => 'DX 分数（可选）';

  @override
  String get flowChartMaximumScore => '谱面满分';

  @override
  String get flowSelectTime => '选择时间';

  @override
  String get flowSeconds059 => '秒（0-59）';

  @override
  String get flowDeleteThisDataPoint => '删除这个记录点？';

  @override
  String get flowThisCannotBeUndoneIfThisIs =>
      '删除后无法恢复。如果它是自动采集到的当前成绩，下次刷新可能会重新记录。';

  @override
  String get flowDataVoluntarilyUploadedByPlayersForReference =>
      '数据来自玩家自愿上传，仅供参考和娱乐';

  @override
  String get flowBriefProfilesAreHiddenForAnonymousPlayers => '匿名用户不展示简要信息';

  @override
  String get flowCouldNotLoadTheBriefProfileTry => '暂时无法读取简要信息，请稍后重试';

  @override
  String get flowReload => '重新加载';

  @override
  String get flowUnknownPlayer => '未知玩家';

  @override
  String get flowNoTitleSet => '未设置称号';

  @override
  String get flowB1IsTheChartWithTheHighest =>
      'B1 为对应 Best 列表中单曲 Rating 最高的谱面。';

  @override
  String get flowNoScoresYet => '暂无成绩';

  @override
  String get flowDanCompletion => '段位完成情况';

  @override
  String get flowTotalAchievementUpTo4040000 => '总达成率（最高 404.0000%）';

  @override
  String get flowCompletionRate => '完成率';

  @override
  String flowP0Songs2(String p0) {
    return '$p0 首';
  }

  @override
  String get flowExcluded => '不计入';

  @override
  String get flowCompleted => '已完成';

  @override
  String get flowIncomplete => '未完成';

  @override
  String get flowLoading4 => '正在加载';

  @override
  String get flowFirstRecord => '首次记录';

  @override
  String flowP0P1Changes(String p0, String p1) {
    return '–$p0 · $p1 次变化';
  }

  @override
  String get flowRecorded => ' 记录';

  @override
  String get flowTheScoreChangedDuringTheDayBut => '日内成绩有过变化，最新值已回到当日初值。';

  @override
  String get flowNoChange => '无变化';

  @override
  String get flowPlaybackProgressDragTheOuterRingTo => '播放进度，拖动外环调整，左右滑动曲绘切歌';

  @override
  String get flowElapsed => '已播放';

  @override
  String get flowDuration2 => '总时长';

  @override
  String get flowQueue => '队列';

  @override
  String get flowLoadingAudio => '正在加载音源';

  @override
  String get flowOpenPlaybackQueue => '打开播放队列';

  @override
  String get flowPlaybackQueue => '播放队列';

  @override
  String flowPlaybackModeP0TapToSwitchAnd(String p0) {
    return '播放模式：$p0（点一下切换并展开）';
  }

  @override
  String get flowRepeatCount => '循环次数';

  @override
  String get flowNotSet2 => '不设置';

  @override
  String flowP0Times(String p0) {
    return '$p0 次';
  }

  @override
  String get flowUnlimited => '不设置次数';

  @override
  String get flowRepeatTheCurrentSongIndefinitely => '一直循环当前曲目';

  @override
  String get flowSetCount => '设置次数';

  @override
  String get flowDecreaseCount => '减少次数';

  @override
  String get flowIncreaseCount => '增加次数';

  @override
  String get flowHideFloatingPlayer => '隐藏悬浮球';

  @override
  String get flowPlaylist => '播放列表';

  @override
  String get flowKeepPlayingAndReopenTheFloatingPlayer =>
      '可以继续播放并稍后回到随身听重新唤起，或同时暂停播放并移除通知栏音乐。';

  @override
  String get flowKeepPlaying => '继续播放';

  @override
  String get flowPauseAndRemove => '暂停并移除';

  @override
  String get flowSongTitle2 => '歌曲标题';

  @override
  String get flowTranslatedByBaiduSLanguageModel => '由百度大模型翻译';

  @override
  String get flowTranslating => '翻译中…';

  @override
  String get flowDifficultiesToPlayMultipleSelections => '想玩的难度（可多选）';

  @override
  String get flowNotesOptional => '备注（可选）';

  @override
  String get flowExamplePlayWithFriends => '例如：和朋友一起玩';

  @override
  String get flowAdd => '加入';

  @override
  String get flowTotalSongs => '总歌曲数';

  @override
  String get flowPathCopiedToClipboard => '路径已复制到剪贴板';

  @override
  String get flowNoAppAvailableToViewImages => '没有找到能查看图片的应用';

  @override
  String get flowCopied => '已复制';

  @override
  String get flowCopyPath => '复制路径';

  @override
  String flowPublicDirectoryIsNotWritableSavedTo(String p0) {
    return '公开目录不可写，文件已保存到备用路径：$p0';
  }

  @override
  String get flowViewImage => '查看图片';

  @override
  String get flowPerRow => '每行';

  @override
  String get flowFewerAvatarsPerRow => '减少每行头像数';

  @override
  String get flowMoreAvatarsPerRow => '增加每行头像数';

  @override
  String get flowChooseAppearance => '选择装扮';

  @override
  String flowSearchP0ByNameDescriptionOrID(String p0) {
    return '搜索$p0名称、描述或编号';
  }

  @override
  String flowP0Items3(String p0) {
    return '共 $p0 项';
  }

  @override
  String flowLoadingP0(String p0) {
    return '正在加载$p0…';
  }

  @override
  String flowNoP0YetRefreshCollectibleDataFirst(String p0) {
    return '暂无$p0，请先刷新收藏品数据';
  }

  @override
  String flowNoMatchingP0(String p0) {
    return '未找到匹配的$p0';
  }

  @override
  String get flowPNGLosslessOriginalQuality => 'PNG 无损（原始画质）';

  @override
  String get flowJPEGHighQuality => 'JPEG 高质量';

  @override
  String get flowJPEGStandard => 'JPEG 标准';

  @override
  String get flowJPEGCompressed => 'JPEG 压缩';

  @override
  String get flowChooseExportQuality => '选择导出质量';

  @override
  String flowExportingP0(String p0) {
    return '当前正在导出：$p0';
  }

  @override
  String get flowImageTheme => '图片主题';

  @override
  String get flowThunderMode => '雷霆模式';

  @override
  String get flowArrangeCardsIn50RowsOr50 => '将歌曲卡片改为单列 50 行或单行 50 列，适合超长图片';

  @override
  String get flowExportPreview => '导出效果图';

  @override
  String get flowConfirmExport => '确认导出';

  @override
  String flowCouldNotGeneratePreviewP0(String p0) {
    return '预览生成失败：$p0';
  }

  @override
  String flowP0P1EstimatedP2(String p0, String p1, String p2) {
    return '$p0，$p1，预计 $p2';
  }

  @override
  String flowAboutP0(String p0) {
    return '约 $p0';
  }

  @override
  String get flowQuestionPool => '题库范围';

  @override
  String get flowGameRules => '对局规则';

  @override
  String get flowMaximumGuesses => '最大猜测次数';

  @override
  String get flowTimeLimit => '时间限制';

  @override
  String get flowTo => '至';

  @override
  String get flowEnter10150ThenTap => '可填 1.0 至 15.0，点其它位置或按回车生效';

  @override
  String get flowBest35ConstantRange => 'Best35 定数区间';

  @override
  String get flowBest15ConstantRange => 'Best15 定数区间';

  @override
  String get flowBest50Average => 'Best 50 平均';

  @override
  String get flowBest35Average => 'Best 35 平均';

  @override
  String get flowBest15Average => 'Best 15 平均';

  @override
  String get flowSSSCountIn50Charts => '50首 SSS+ 数量';

  @override
  String get flowSSSCountIn50Charts2 => '50首 SSS 数量';

  @override
  String get flowPotentialConstantRATable => '可提升定数 RA 对照';

  @override
  String get flowFittedTotalRating => '拟合总Rating';

  @override
  String get flowDifferenceFromBest50 => '与Best50差值';

  @override
  String get flowAverageAchievementDXScoreRate2 => '平均达成率 / DX分数达成率';

  @override
  String flowCurrentOrderP0(String p0) {
    return '当前排序：$p0';
  }

  @override
  String get flowTotalRA => '总RA';

  @override
  String get flowSongs => '歌曲数';

  @override
  String get flowComparedWithThisTagSBest50 => '较该标签 Best50';

  @override
  String get flowSongAchievement => '单曲达成率';

  @override
  String flowTotalRatingP0(String p0) {
    return '总 Rating $p0';
  }

  @override
  String flowP0ConstantP1(String p0, String p1) {
    return '$p0 (定数 $p1)';
  }

  @override
  String get flowNoteStatistics => '物量统计';

  @override
  String get flowBREAKStatistics => '绝赞统计';

  @override
  String flowP0P1P2Statistics2(String p0, String p1, String p2) {
    return '$p0 $p1($p2)统计';
  }

  @override
  String flowChartDesignerP0(String p0) {
    return '谱师:$p0';
  }

  @override
  String flowVersionP0(String p0) {
    return '版本:$p0';
  }

  @override
  String flowGenreP0(String p0) {
    return '流派:$p0';
  }

  @override
  String flowComposerP0(String p0) {
    return '曲师:$p0';
  }

  @override
  String flowP0P1P2SongsTotal(String p0, String p1, String p2) {
    return '$p0$p1 | 共 $p2 首歌曲';
  }

  @override
  String get flowFolderNameCannotBeEmpty => '收藏夹名称不能为空';

  @override
  String get flowNoAudioIsAvailableForThisSong => '这首歌暂时没有可用的音源';

  @override
  String get flowCouldNotLoadAudioTryAgainLater => '音源加载失败，请稍后重试';

  @override
  String get flowReadingLocalVideo => '正在读取本地视频…';

  @override
  String get flowBufferingVideo => '正在缓冲视频…';

  @override
  String get flowNoMatchingChartCodeFound => '未找到匹配的谱面代码';

  @override
  String flowCouldNotFetchChartCodeP0(String p0) {
    return '获取谱面代码失败: $p0';
  }

  @override
  String get flowExporting2 => '正在导出...';

  @override
  String get flowNoChartCodeAvailable => '暂无谱面代码数据';

  @override
  String get flowAudio => '音源';

  @override
  String flowCouldNotFetchP0ThePackageOnly(String p0) {
    return '未能获取$p0，压缩包里只有谱面数据，导入后需要自行补齐才能正常游玩。';
  }

  @override
  String get flowPreparingChart => '正在准备谱面…';

  @override
  String get flowReadingChartSettings => '正在读取谱面设置…';

  @override
  String get flowFindingAudio => '正在查找音频文件…';

  @override
  String get flowPreparingCoverArt => '正在准备曲绘…';

  @override
  String get flowParsingChartData => '正在解析谱面数据…';

  @override
  String get flowAudioLoadedFromLocalCache => '已从本地缓存读取音频';

  @override
  String get flowAnd => '和';

  @override
  String flowP0MinutesAgo(String p0) {
    return '$p0 分钟前';
  }

  @override
  String flowP0HoursAgo(String p0) {
    return '$p0 小时前';
  }

  @override
  String flowP0DaysAgo(String p0) {
    return '$p0 天前';
  }

  @override
  String get flowCustomChart2 => '自定义谱面';

  @override
  String get flowMaidataFileSelected => '已选择maidata文件';

  @override
  String get flowTheLibraryIsNotReadyRefreshData =>
      '曲库还没准备好。请先回首页「拉取成绩并更新数据」，或检查网络后重试。';

  @override
  String flowCouldNotLoadLibraryP0(String p0) {
    return '加载曲库失败：$p0';
  }

  @override
  String get flowNotificationPermissionWasNotGrantedBackgroundPlayback =>
      '未授予通知权限：音乐仍可后台播放，但不会显示通知栏播放器';

  @override
  String get flowDownloaded2 => '已下载';

  @override
  String flowDownloadFailedP02(String p0) {
    return '下载失败：$p0';
  }

  @override
  String get flowTheCurrentSongIsNotInThis => '当前播放的曲目不在列表里';

  @override
  String get flowNoPlayableSongs => '没有可播放的歌曲';

  @override
  String get flowNoMatchingSongs => '没有匹配的歌曲';

  @override
  String flowP0PlayableSongs(String p0) {
    return '共 $p0 首可播放';
  }

  @override
  String flowExcludedP0UTAGESongs(String p0) {
    return '已排除宴会场 $p0 首';
  }

  @override
  String flowP0SongsHaveNoDivingFishEntry(String p0) {
    return '水鱼无对应条目 $p0 首';
  }

  @override
  String get flowCalculating => '计算中';

  @override
  String get flowSwitchingSongs => '正在切换歌曲…';

  @override
  String get flowThisIsTheLastSong => '已经是最后一首啦';

  @override
  String get flowUpNext => '接下来';

  @override
  String get flowUpToOneDecimalPlaceLeaveBlank => '最多一位小数，留空表示默认值';

  @override
  String get flowUpToFourDecimalPlacesLeaveBlank => '最多四位小数，留空表示默认值';

  @override
  String get flowGrade => '评级';

  @override
  String get flowLowerBound => '下界';

  @override
  String get flowUpperBound => '上界';

  @override
  String get flowCategory => '种类';

  @override
  String get flowSelectALevel => '请选择等级';

  @override
  String get flowSelectAVersion => '请选择版本';

  @override
  String get flowSelectAGenre => '请选择流派';

  @override
  String get flowTitleType => '称号类型';

  @override
  String get flowNoMatchingChartDesigners2 => '没有匹配的谱师';

  @override
  String get flowNoMatchingComposers => '没有匹配的曲师';

  @override
  String get flowSongs2 => '首';

  @override
  String get flowNoSongsMatchThisLevel => '当前等级没有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisChartDesigner => '当前谱师没有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisVersion => '当前版本没有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisGenre => '当前流派没有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisComposer => '当前曲师没有匹配的歌曲';

  @override
  String flowLvP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Lv.$p0($p1)的$p2称号统计';
  }

  @override
  String flowChartDesignerP0P1P2TitleStatistics(
      String p0, String p1, String p2) {
    return '谱师$p0($p1)的$p2称号统计';
  }

  @override
  String flowVersionP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return '版本$p0($p1)的$p2称号统计';
  }

  @override
  String flowGenreP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return '流派$p0($p1)的$p2称号统计';
  }

  @override
  String flowComposerP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return '曲师$p0($p1)的$p2称号统计';
  }

  @override
  String get flowFriendCode => '好友码';

  @override
  String flowEnterYourFriendSP02(String p0) {
    return '请输入好友的$p0';
  }

  @override
  String flowMeP0(String p0) {
    return '我 · $p0';
  }

  @override
  String get flowMyWins => '我赢';

  @override
  String get flowFriendSWins => '好友赢';

  @override
  String get flowFriend => '好友';

  @override
  String get flowFirstCharacter => '首字';

  @override
  String get flowSelectAFirstCharacter => '请选择首字';

  @override
  String get flowNoSongsMatchThisDifficulty => '当前难度没有匹配的歌曲';

  @override
  String get flowByAverageAchievement => '平均达成率推荐';

  @override
  String get flowByConstantDifference => '定数差值推荐';

  @override
  String get flowAvgAchievement => '平均达成';

  @override
  String get flowConstantDifference => '定数差值';

  @override
  String flowPersonalBestP0(String p0) {
    return '个人最佳 $p0%';
  }

  @override
  String get flowLast30Days => '近 30 天';

  @override
  String get flowLast90Days => '近 90 天';

  @override
  String flowLimitP0TheoreticalValueUnavailable(String p0) {
    return '上限 $p0（理论值未取到）';
  }

  @override
  String flowCouldNotLoadImprovementHistoryP0(String p0) {
    return '读取提升历史失败：$p0';
  }

  @override
  String get flowChangesAreRecordedAutomaticallyAfterYourScores =>
      '成功刷新自己的成绩时自动记录，水鱼、落雪和 AWMC NET 按数据源与账号分别保存。\n\n首次没有旧成绩可比时仅建立基线；刷新无变化不新增记录。当天同一谱面的多次变化合成一张卡，展示首次变化前到最新值。\n\n按刷新时的本地日期归档，时间代表发现变化的时间，并非实际游玩时间。卡片按前后值标为成绩提升、成绩回退、成绩无变化，或有升有降的成绩变化；首次出现的谱面另注明首次记录。\n\nRating 是该谱面的 Rating，不代表总 Rating 的增量。历史仅在本机保存，不会自动回填启用前的旧成绩。';

  @override
  String get flowNoScoreImprovementRecordsYet => '还没有成绩提升记录';

  @override
  String get flowNoMatchingRecords => '没有符合条件的记录';

  @override
  String get flowBestScoresThatChangeAfterASuccessful =>
      '成功刷新后，发生变化的最佳成绩会出现在这里。';

  @override
  String get flowTryAnotherKeywordOrDate => '试试其他关键词或日期。';

  @override
  String get flowCouldNotLoad => '加载失败';

  @override
  String flowRequestFailedP0(String p0) {
    return '请求失败 ($p0)';
  }

  @override
  String flowNetworkErrorP0(String p0) {
    return '网络错误: $p0';
  }

  @override
  String flowP0MinutesAgo2(String p0) {
    return '$p0分钟前';
  }

  @override
  String flowP0HoursAgo2(String p0) {
    return '$p0小时前';
  }

  @override
  String flowP0DaysAgo2(String p0) {
    return '$p0天前';
  }

  @override
  String flowP0User(String p0) {
    return '$p0用户';
  }

  @override
  String flowCouldNotSaveSnapshotP0(String p0) {
    return '保存快照失败: $p0';
  }

  @override
  String get flowHighestConstantsFromOlderVersions => '非当前版本最高定数';

  @override
  String get flowBestScoresFromOlderVersions => '非当前版本最好成绩';

  @override
  String get flowHighestConstantsFromThisVersion => '当前版本最高定数';

  @override
  String get flowBestScoresFromThisVersion => '当前版本最好成绩';

  @override
  String get flowPattern => '配置';

  @override
  String get flowEvaluation => '评价';

  @override
  String get flowModeATakeTheTop50Charts =>
      '模式A：不分类Best35和Best15，直接获取拟合定数下的Rating前50的谱面';

  @override
  String get flowModeBReplaceConstantsInYourOfficial =>
      '模式B：将您的Best35和Best15中的所有谱面的定数都替换为其拟合定数，然后计算Rating并降序排序';

  @override
  String get flowModeCTakeTheTop35Older =>
      '模式C：在非当前版本中取拟合定数下的Rating前35的谱面，在当前版本中取拟合定数下Rating前15的谱面';

  @override
  String get flowTop35FromOlderVersions => '非当前版本前 35';

  @override
  String get flowTop15FromThisVersion => '当前版本前 15';

  @override
  String flowP0ChartsHaveNoFittedConstantOfficial(String p0) {
    return '$p0首暂无拟合定数，按照官方定数计算';
  }

  @override
  String flowIncludesP0(String p0) {
    return '包含: $p0';
  }

  @override
  String flowChartDesigner50P0(String p0) {
    return '谱师50 - $p0';
  }

  @override
  String flowVersion50P0(String p0) {
    return '版本50 - $p0';
  }

  @override
  String flowGenre50P0(String p0) {
    return '流派50 - $p0';
  }

  @override
  String flowStar50P0(String p0) {
    return '星数50 - $p0';
  }

  @override
  String flowTag50P0(String p0) {
    return '标签50 - $p0';
  }

  @override
  String flowPersonalizedBest50P0(String p0) {
    return '个性化Best50 - $p0';
  }

  @override
  String flowChartDesigner50P0Statistics(String p0) {
    return '谱师50 - $p0 统计';
  }

  @override
  String flowVersion50P0Statistics(String p0) {
    return '版本50 - $p0 统计';
  }

  @override
  String flowGenre50P0Statistics(String p0) {
    return '流派50 - $p0 统计';
  }

  @override
  String flowStar50P0Statistics(String p0) {
    return '星数50 - $p0 统计';
  }

  @override
  String flowTag50P0Statistics(String p0) {
    return '标签50 - $p0 统计';
  }

  @override
  String flowP0Statistics(String p0) {
    return '$p0 统计';
  }

  @override
  String flowPersonalizedFittedBest50P0(String p0) {
    return '个性化拟合Best50 - $p0';
  }

  @override
  String flowTagP0P1ChartsTop50By(String p0, String p1) {
    return '标签：$p0 · 共$p1张谱面 · 在拟合定数下计算单曲Rating，取前50的谱面';
  }

  @override
  String get flowAverage => '平均';

  @override
  String get flowOlderVersions => '非当前版本';

  @override
  String get flowCurrentVersion => '当前版本';

  @override
  String flowP0InvalidEntriesAchievementOrDXScore(String p0) {
    return '⚠ 存在 $p0 条非法数据（达成率或 DX 分数超过谱面上限）';
  }

  @override
  String get flowEG1005 => '如 100.5';

  @override
  String get flowEG3000 => '如 3000';

  @override
  String get flowEnterAchievement => '请输入达成率';

  @override
  String flowDifficultyP03(String p0) {
    return '难度$p0';
  }

  @override
  String get flowRADescending => 'RA 降序';

  @override
  String get flowRAAscending => 'RA 升序';

  @override
  String get flowConstantDescending => '定数 降序';

  @override
  String get flowConstantAscending => '定数 升序';

  @override
  String get flowFilled => '已填写';

  @override
  String flowCouldNotLoadP0(String p0) {
    return '加载失败: $p0';
  }

  @override
  String get flowModeATop50ByFittedRating => '模式A：不分类，按拟合 Rating 取前50';

  @override
  String get flowModeBRecalculateOfficialBest35Best15Using =>
      '模式B：按官方 Best35/Best15 替换拟合定数重算';

  @override
  String get flowModeCTop35OlderChartsAnd => '模式C：非新曲取前35，新曲取前15';

  @override
  String get flow6MaximumReached => '✦ 6 已满';

  @override
  String get flowCouldNotLoadLeaderboardData => '加载排行榜数据失败';

  @override
  String get flowAchievementRanking2 => '达成率排行榜';

  @override
  String get flowDXScoreRanking2 => 'DX分数排行榜';

  @override
  String flowCouldNotFetchLeaderboardP0(String p0) {
    return '获取排行榜失败: $p0';
  }

  @override
  String get flowBREAKShareRanking => '绝赞占比排行榜';

  @override
  String get flowSameSongDifficultyGapRanking => '同曲难度跨度排行榜';

  @override
  String get flowSLIDEShareRanking => 'SLIDE 占比排行榜';

  @override
  String get flowTOUCHShareRanking => 'TOUCH 占比排行榜';

  @override
  String get flowTAPShareRanking => 'TAP 占比排行榜';

  @override
  String get flowHOLDShareRanking => 'HOLD 占比排行榜';

  @override
  String get flowBREAKCountRanking => '绝赞数排行榜';

  @override
  String get flowNormalChartBREAKCountRanking => '常规谱绝赞数排行榜';

  @override
  String get flowConstantDifferenceRanking => '定数差值排行榜';

  @override
  String get flowMASTERReMASTERConstantDifferenceRanking =>
      'MASTER/Re:MASTER定数差值排行榜';

  @override
  String get flowEXPERTConstantDifferenceRanking => 'EXPERT定数差值排行榜';

  @override
  String get flowSampleCountRanking => '样本总数排行榜';

  @override
  String get flowNoteCountRanking => '物量排行榜';

  @override
  String get flowMASTERReMASTERAverageAchievementRanking =>
      'MASTER/Re:MASTER平均达成率排行榜';

  @override
  String get flowEXPERTAverageAchievementRanking => 'EXPERT平均达成率排行榜';

  @override
  String get flowBPMRanking => 'BPM排行榜';

  @override
  String get flowBREAKShare => '绝赞占比';

  @override
  String get flowConstantGap => '定数跨度';

  @override
  String get flowSLIDEShare => 'SLIDE 占比';

  @override
  String get flowTOUCHShare => 'TOUCH 占比';

  @override
  String get flowTAPShare => 'TAP 占比';

  @override
  String get flowHOLDShare => 'HOLD 占比';

  @override
  String get flowBREAKCount => '绝赞数';

  @override
  String get flowSampleCount => '样本总数';

  @override
  String get flowRankByBREAKCountOrderCanBe => '按谱面绝赞数量排名（可切换正反向）';

  @override
  String get flowRankByBREAKCountExcludingUTAGEOrder =>
      '绝赞数排行榜，但宴会场不参与（可切换正反向）';

  @override
  String get flowBREAKCountTotalNotesRankedAsA => '绝赞数 ÷ 总物量，以百分比排名（可切换正反向）';

  @override
  String get flowTAPCountTotalNotesIncludesSTDX =>
      'TAP 数 ÷ 总物量，ST/DX/UT 均参与（可切换正反向）';

  @override
  String get flowHOLDCountTotalNotesIncludesSTDX =>
      'HOLD 数 ÷ 总物量，ST/DX/UT 均参与（可切换正反向）';

  @override
  String get flowSLIDECountTotalNotesIncludesSTDX =>
      'SLIDE 数 ÷ 总物量，ST/DX/UT 均参与（可切换正反向）';

  @override
  String get flowTOUCHCountTotalNotesIncludesDXUT =>
      'TOUCH 数 ÷ 总物量，DX/UT 参与，ST 不参与（可切换正反向）';

  @override
  String get flowOfficialConstantGapForEXPERTMASTERAnd =>
      '同曲 EXPERT→MASTER、MASTER→Re:MASTER 的官方定数差（后者减前者，可切换正反向）';

  @override
  String get flowRankByFittedMinusOfficialConstantOrder =>
      '拟合定数与官方定数差值排名（可切换正反向）';

  @override
  String get flowMASTERReMASTEROnlyOrderCanBe =>
      '只统计MASTER/Re:MASTER难度（可切换正反向）';

  @override
  String get flowEXPERTOnlyOrderCanBeReversed => '只统计EXPERT难度（可切换正反向）';

  @override
  String get flowRankByTotalPlayerSamplesOrderCan => '玩家样本总量排名（可切换正反向）';

  @override
  String get flowRankByTheTotalOfAllFive => '五种note总数排名（可切换正反向）';

  @override
  String get flowRankByAverageAchievementOrderCanBe => '按平均达成率排名（可切换正反向）';

  @override
  String get flowRankBySongBPMOrderCanBe => '按歌曲BPM排名（可切换正反向）';

  @override
  String get flowEnterABVID => '请输入 BV 号';

  @override
  String get flowInvalidBVIDExpectedBVFollowedBy => 'BV 号格式不正确（应为 BV + 10位字符）';

  @override
  String get flowCheckFailedVideoInformationUnavailableTheBV =>
      '校验失败: 无法获取视频信息（BV 号可能不存在）';

  @override
  String flowVerifiedVideoTitleP0(String p0) {
    return '校验通过！视频标题: \"$p0\"';
  }

  @override
  String flowCheckFailedVideoTitleP0DoesNot(String p0, String p1) {
    return '校验失败: 视频标题 \"$p0\" 不包含歌曲名 \"$p1\"';
  }

  @override
  String flowVerificationErrorP0(String p0) {
    return '校验异常: $p0';
  }

  @override
  String get flowSongPV => '歌曲 PV';

  @override
  String get flowPlayThisChartAtLeastOnceBefore => '至少游玩过一次该谱面才能参与打分';

  @override
  String get flowInvalidScorePleaseCheckIt => '成绩不合法，请检查';

  @override
  String get flowContentCannotBeEmpty => '内容不能为空';

  @override
  String get flowCommentsCannotExceed500Characters => '评论内容不能超过500字';

  @override
  String get flowSending => '发送中...';

  @override
  String get flowOpenBilibili2 => '跳转到B站';

  @override
  String flowRelatedCollectiblesP0(String p0) {
    return '相关收藏品 $p0';
  }

  @override
  String flowMyScoreP0(String p0) {
    return '我的成绩 · $p0';
  }

  @override
  String flowPlayedP0Times(String p0) {
    return '游玩 $p0 次';
  }

  @override
  String flowFittedP0P1(String p0, String p1) {
    return '拟合 $p0$p1';
  }

  @override
  String get flowDuration3 => '时长';

  @override
  String get flowScoreHistory => '成绩历史';

  @override
  String get flowData => '数据';

  @override
  String get flowCommunity => '社区';

  @override
  String get flowTools => '工具';

  @override
  String get flowTrueBREAKTAP => '真绝赞TAP';

  @override
  String get flowTrueBREAKHOLD => '真绝赞HOLD';

  @override
  String get flowProtectedBREAK => '保护套绝赞';

  @override
  String get flowBREAKStar => '绝赞星星';

  @override
  String get flowCategory2 => '类别';

  @override
  String get flowTotal => '共 ';

  @override
  String get flowSSSAllowance => 'SSS+ 容错';

  @override
  String get flowSSSAllowance2 => 'SSS 容错';

  @override
  String get flowChartTagsReferenceOnly => '谱面标签(仅供参考)';

  @override
  String get flowPreview => '试听';

  @override
  String get flowMore => '更多';

  @override
  String get flowViewChartCode => '查看谱面代码';

  @override
  String get flowUTAGESongsAreExcludedFromBest50 => '宴会场歌曲不参与Best50';

  @override
  String flowThisChartIsAlreadyWithinP0With(String p0) {
    return '该谱面已在$p0区间内且无提升空间';
  }

  @override
  String flowThisChartCannotEnterP0(String p0) {
    return '该谱面无法进入$p0';
  }

  @override
  String flowReachP0ToP1P2(String p0, String p1, String p2) {
    return '推到 $p0% 可$p1 $p2';
  }

  @override
  String get flowEnter => '进入';

  @override
  String flowThisChartHasRAP0ReachingThe(String p0, String p1) {
    return '这张谱面当前 RA $p0，推到下面的达成率时 $p1 总分能加：';
  }

  @override
  String flowThisChartIsNotInP0The(String p0, String p1) {
    return '这张谱面还不在 $p0，末位是 RA $p1。推到下面的达成率替换末位后，总分能加：';
  }

  @override
  String flowP0BaseP1(String p0, String p1) {
    return '$p0(基准 $p1)';
  }

  @override
  String get flowUserUpload => '用户上传';

  @override
  String get flowRedisCache => 'Redis 缓存';

  @override
  String get flowAutomaticLookup => '自动获取';

  @override
  String get flowUnknownType => '未知类型';

  @override
  String get flowCountCannotBeNegative => '数量不能为负数';

  @override
  String flowPlayedCountP0CannotExceedTheTotal(String p0, String p1) {
    return '已打出总数（$p0）不能超过BREAK总数（$p1）';
  }

  @override
  String flowBREAKLossIsP0BeyondTheSS(String p0) {
    return 'BREAK损失已达$p0%，超过SS(-2%)上限，无法继续容错';
  }

  @override
  String flowP0DaysApart(String p0) {
    return '(相差$p0天)';
  }

  @override
  String flowFirstReleaseP0(String p0) {
    return '首次上线$p0';
  }

  @override
  String get flowBase => '基准';

  @override
  String get flowProtectedNOTEDistribution => '保护套 NOTE 分布';

  @override
  String get flowProtectedTAP => '保护套TAP';

  @override
  String get flowProtectedHOLD => '保护套HOLD';

  @override
  String get flowUnprotectedNOTEDistribution => '无保护套 NOTE 分布';

  @override
  String get flowUnprotectedTAP => '无保护套TAP';

  @override
  String get flowUnprotectedHOLD => '无保护套HOLD';

  @override
  String get flowTwoColumns => '双列';

  @override
  String get flowOneColumn => '单列';

  @override
  String flowP00Songs(String p0) {
    return '$p0 0 首';
  }

  @override
  String flowP0P1SongsMinP2AvgP3(String p0, String p1, String p2, String p3) {
    return '$p0 $p1 首 · 最低 $p2 · 平均 $p3 · 点卡片看推分空间';
  }

  @override
  String get flowSongLimitReached => '已到单曲上限';

  @override
  String flowChartHistoryCouldNotReadChartHistoryIgnored(String p0) {
    return '[ChartHistory] 读取谱面历史失败（忽略）: $p0';
  }

  @override
  String flowP0AchievementP1P2(String p0, String p1, String p2) {
    return '$p0\n达成率 $p1%$p2';
  }

  @override
  String flowDXScoreP03(String p0) {
    return ' · DX分数 $p0';
  }

  @override
  String get flow1DataPoint => '1 个记录点';

  @override
  String flowP0Changes(String p0) {
    return '$p0 次变化';
  }

  @override
  String get flowDXScoreOfMaximum => 'DX分数（占满分%）';

  @override
  String flowP0AchievementP1DXScoreP2(String p0, String p1, String p2) {
    return '$p0\n达成率 $p1%\nDX分数 $p2';
  }

  @override
  String get flowChartLimit => '谱面上限';

  @override
  String get flowDeleteThisDataPoint2 => '删除这个记录点';

  @override
  String get flowPlayerBriefProfile => '玩家简要信息';

  @override
  String get flowBriefProfileUnavailable => '暂时无法读取简要信息';

  @override
  String get flowLoadingBriefProfile => '正在读取简要信息…';

  @override
  String get flowNoBackgroundSet => '未设置背景';

  @override
  String get flowLoadingBackground => '背景加载中';

  @override
  String get flowBackgroundUnavailable => '背景暂不可用';

  @override
  String get flowNoNameplateSet => '未设置姓名框';

  @override
  String get flowLoadingNameplate => '姓名框加载中';

  @override
  String get flowNameplateUnavailable => '姓名框暂不可用';

  @override
  String flowTitleP0(String p0) {
    return '称号 #$p0';
  }

  @override
  String get flowNotAttempted => '未挑战';

  @override
  String get flowRedPass => '赤合格';

  @override
  String get flowEnterAValidTotalAchievement => '请输入有效的总达成率';

  @override
  String get flowTotalAchievementMustBeBetween0And => '总达成率必须在 0～404% 之间';

  @override
  String get flowTotalAchievementSupportsUpToFourDecimal => '总达成率最多保留 4 位小数';

  @override
  String get flowTotal2 => '总数';

  @override
  String get flowByLevel => '按等级';

  @override
  String get flowByConstant => '按定数';

  @override
  String get flowRegression => '回退';

  @override
  String get flowChange2 => '变化';

  @override
  String get flowClosePlaybackModeSelection => '关闭播放模式选择';

  @override
  String get flowSequential => '顺序播放';

  @override
  String get flowShuffle => '随机播放';

  @override
  String get flowRepeatOne => '单曲循环';

  @override
  String get flowTranslationIsUnavailableTryAgainLater => '暂时无法翻译，请稍后重试';

  @override
  String get flowTranslationFailedTryAgainLater => '翻译失败，请稍后重试';

  @override
  String get flowNumberOfEntries => '添加次数';

  @override
  String flowSourceP02(String p0) {
    return '数据源 $p0';
  }

  @override
  String flowGeneratedByChiffonMaiCommunityGroupP0(String p0) {
    return 'Generated by ChiffonMai · 交流群 $p0';
  }

  @override
  String get flowExportSuccessful => '导出成功';

  @override
  String get flowExported => '已导出';

  @override
  String get flow50Rows1Column => '单列 50 行';

  @override
  String get flow1Row50Columns => '单行 50 列';

  @override
  String get flowZoomOut => '缩小';

  @override
  String get flowZoomIn => '放大';

  @override
  String get flowFitToWindow => '适应窗口';

  @override
  String get flowMustBeGreaterThan0 => '必须大于 0';

  @override
  String flowMustNotExceedP0P1(String p0, String p1) {
    return '不得超过 $p0$p1';
  }

  @override
  String flowLimitP0P1(String p0, String p1) {
    return '上限 $p0（$p1）';
  }

  @override
  String flowRatingP0Best35P1Best15P2Average(
      String p0, String p1, String p2, String p3, String p4) {
    return 'Rating $p0\nBest35 $p1 · Best15 $p2\n平均达成率 $p3%\n平均DX分数达成率 $p4%';
  }

  @override
  String get flowTheoreticalBest35HighestConstantsFromOlderVersions =>
      '理论Best35 | 非当前版本最高定数';

  @override
  String get flowBest35BestScoresFromOlderVersions => 'Best35 | 非当前版本最好成绩';

  @override
  String get flowTheoreticalBest15HighestConstantsFromThisVersion =>
      '理论Best15 | 当前版本最高定数';

  @override
  String get flowBest15BestScoresFromThisVersion => 'Best15 | 当前版本最好成绩';

  @override
  String flowAverageP02(String p0) {
    return '平均 $p0';
  }

  @override
  String flowFittedRatingP0AverageRatingP1Average(
      String p0, String p1, String p2, String p3) {
    return '拟合 Rating $p0\n平均 Rating $p1\n平均达成率 $p2%\n平均DX分数达成率 $p3%';
  }

  @override
  String get flowBest50BasedOnFittedConstants => '基于拟合难度的Best50';

  @override
  String flowP0ChartsTotalRatingP1AverageDX(String p0, String p1, String p2) {
    return '共 $p0 张谱面\nRating 合计 $p1\n平均DX分数达成率 $p2%';
  }

  @override
  String flowAverageRAP0(String p0) {
    return '平均RA $p0';
  }

  @override
  String flowFittedRatingP0VsThisTagS(
      String p0, String p1, String p2, String p3, String p4, String p5) {
    return '拟合 Rating $p0（较该标签 Best50 $p1$p2）\n平均 Rating $p3\n平均达成率 $p4%\n平均DX分数达成率 $p5%';
  }

  @override
  String get flowChartType => '谱面类型';

  @override
  String get flowReferenceDuration => '参考时长';

  @override
  String get flowNOTECountsAndTotalNotes => 'NOTE 数量与总物量';

  @override
  String get flowBREAKCounts => '绝赞数量';

  @override
  String get flowTotalNotes => '总物量';

  @override
  String get flowOfficialConstant => '官方定数';

  @override
  String get flowFittedConstant => '拟合定数';

  @override
  String get flowTotal3 => '总计';

  @override
  String get flowRequestingStoragePermission => '请求存储权限...';

  @override
  String get flowBuildingExportContent => '正在构建导出内容...';

  @override
  String get flowPreloadingImages => '正在预加载图片...';

  @override
  String get flowRenderingExportContent => '正在渲染导出内容...';

  @override
  String get flowGeneratingImage => '正在生成图片...';

  @override
  String get flowSavingImage => '正在保存图片...';

  @override
  String get flowExportComplete => '导出完成';

  @override
  String get flowBPMRange => 'BPM 范围';

  @override
  String get flowBaseBPM => '基准 BPM';

  @override
  String get flowSOrLower => 'S+以下';

  @override
  String get flowNoCombo => '无连击';

  @override
  String get flowNoSync => '无同步';

  @override
  String flowCouldNotLoadDataP0(String p0) {
    return '加载数据出错: $p0';
  }

  @override
  String get flowUncategorized => '未分类';

  @override
  String get flowNarrowPass50 => '寸50';

  @override
  String get flowJustShort50 => '名刀50/锁血50';

  @override
  String get flowNarrowSSS50 => '寸鸟加50';

  @override
  String get flowJustShortOfSSS50 => '锁血鸟加50';

  @override
  String get flowNarrowSSS502 => '寸鸟50';

  @override
  String get flowJustShortOfSSS502 => '锁血鸟50';

  @override
  String get flowChartDesigner50 => '谱师50';

  @override
  String get flowGenre50 => '流派50';

  @override
  String get flowVersion50 => '版本50';

  @override
  String get flowStar50 => '星数50';

  @override
  String get flowTag50 => '标签50';

  @override
  String get flowRandom50 => '随机50';

  @override
  String get flowOverreach50 => '越级50';

  @override
  String get flowDifficulty50 => '难度50';

  @override
  String get flowDan => '段位';

  @override
  String get flowTrueDan => '真段位';

  @override
  String get flowOverallRanking => '总排行榜';

  @override
  String get flowStarBonus => '星+';

  @override
  String get flowToNextStar => '高一级星-';

  @override
  String get flowPNGLossless => 'PNG 无损';

  @override
  String get flowOriginalQuality => '原始画质';

  @override
  String get flowClearImageSmallerFile => '清晰，体积较小';

  @override
  String get flowGoodForSharing => '适合发送和分享';

  @override
  String get flowSmallestFile => '体积最小';

  @override
  String get detailChartBpm => '谱面';

  @override
  String get bestDisplayCover => '曲绘';

  @override
  String get bestDisplayTwoColumns => '双列';

  @override
  String get bestDisplayOneColumn => '单列';

  @override
  String rankingServiceUnavailable(String code) {
    return '排行榜服务暂不可用（$code）';
  }

  @override
  String get rankingInvalidResponse => '排行榜响应格式无效';

  @override
  String get ratingFetchFailed => '获取评分信息失败';

  @override
  String commentPostHttpFailed(String code) {
    return '评论创建失败 ($code)';
  }

  @override
  String commentDeleteHttpFailed(String code) {
    return '评论删除失败 ($code)';
  }

  @override
  String get unknownDataSource => '未知数据源';

  @override
  String get exportBlackTheme => '纯黑';

  @override
  String get songTabHistory => '成绩历史';

  @override
  String get songTabCommunity => '社区';

  @override
  String get flowUnknown => '未知';

  @override
  String get flowChooseDownloadMethod => '选择下载方式';

  @override
  String get flowDownloadInBrowser => '浏览器下载';

  @override
  String get flowOpenDownloadPage => '打开下载网页';

  @override
  String get flowDownloadInApp => 'App 内下载';

  @override
  String get flowDownloadInTheBackgroundWhileYouKeep => '后台下载，不影响当前使用';

  @override
  String get flowChooseDownloadRoute => '选择下载线路';

  @override
  String get flowCouldNotConnectToTheServerCheck => '无法连接到服务器，请检查网络后重试';

  @override
  String get flowYouAreUpToDate => '当前已是最新版本';

  @override
  String flowCurrentVersionP0BuildP1(String p0, String p1) {
    return '当前版本：$p0 (build: $p1)';
  }

  @override
  String flowLatestVersionP0BuildP1(String p0, String p1) {
    return '最新版本：$p0 (build: $p1)';
  }

  @override
  String flowLatestChangesP0(String p0) {
    return '最近更新：\n$p0';
  }

  @override
  String get flowHideFor3Days => '3天内不提示';

  @override
  String get flowDownloadNow => '立即下载';

  @override
  String flowCouldNotOpenLinkP0(String p0) {
    return '无法打开链接：$p0';
  }

  @override
  String get flowEmailAddressCopied => '邮箱已复制到剪贴板';

  @override
  String get flowCreationAndSupport => '创作与支持';

  @override
  String get flowSupporterAcknowledgments => '捐献致谢';

  @override
  String get flowDataAndServices => '数据与服务';

  @override
  String get flowDesignInspiration => '设计思路借鉴';

  @override
  String get flowThankYouForEveryContributionThatHelps =>
      '感谢每一份支持，让 ChiffonMai 不断成长。';

  @override
  String get flowHereForEveryMaimaiVisit => '陪伴每一次舞萌出勤';

  @override
  String get flowReadingVersion => '版本读取中…';

  @override
  String flowVersionP02(String p0) {
    return '版本 $p0';
  }

  @override
  String get flowAppRegistrationICP20240152563A => 'APP备案号：津ICP备2024015256号-3A';

  @override
  String get flowDevelopmentAndMaintenance => '开发与维护';

  @override
  String get flowInputError => '输入错误';

  @override
  String get flowTargetAchievement => '目标达成率';

  @override
  String get flowEG1005000 => '例如 100.5000';

  @override
  String get flowJudgmentDetails => '判定详情';

  @override
  String get flowForBREAKEnterTheMainJudgmentCounts =>
      'BREAK 只需填大类；50落 / 100落与 GREAT 细分由反推得出';

  @override
  String get flowCalculating2 => '计算中...';

  @override
  String get flowCalculateBREAKDetails => '计算绝赞详情';

  @override
  String get flowSolutionFoundError00001 => '找到可行解（误差 ≤ 0.0001%）';

  @override
  String get flowNoExactSolutionShowingTheClosestResult => '没有精确解，下面是最接近的结果';

  @override
  String flowTargetP0BaseP1ExtraP2(String p0, String p1, String p2) {
    return '目标 $p0% · 基础 $p1% · 额外 $p2%';
  }

  @override
  String flowTotalAchievementP0P1P2(String p0, String p1, String p2) {
    return '总达成率 $p0% · $p1 $p2%';
  }

  @override
  String get flowError2 => '误差';

  @override
  String get flowMinimumError => '最小误差';

  @override
  String get flowJudgmentLossPerNote => '单个音符的判定损失';

  @override
  String flowP0BREAKsBaseBonusScoreRatiosBelow(String p0) {
    return 'BREAK 共 $p0 个 · 每行下方是基础分 / 奖励分比例';
  }

  @override
  String flowP0P1NotesRedValuesShowAchievement(String p0, String p1) {
    return '$p0 共 $p1 个 · 红字是这一档判定丢掉的达成率';
  }

  @override
  String get flowViewPerNoteLoss => '查看单音符损失';

  @override
  String get flowLiveAchievement => '实时达成率';

  @override
  String get flowEnterJudgmentCountsBelowToCalculateAutomatically =>
      '在下方填写各档判定数量，结果会自动算出来';

  @override
  String flowTotalAchievementP0GradeP1(String p0, String p1) {
    return '总达成率 $p0%，评级 $p1';
  }

  @override
  String flowBaseP0BonusP1(String p0, String p1) {
    return '基础 $p0% · 奖励 $p1%';
  }

  @override
  String get flowAlreadyAtTheHighestGradeSSS => '已经是最高评级 SSS+';

  @override
  String flowP2NeededForP0P1(String p0, String p1, String p2) {
    return '距 $p0（$p1%）还差 $p2%';
  }

  @override
  String get flowAlternatingPlayRestSegmentsLetTheWheel =>
      '出勤和不出勤交替排布，让转盘决定今天要不要出勤吧。';

  @override
  String get flowSegments => '区域数量';

  @override
  String get flowFewerSegments => '减少区域';

  @override
  String get flowMoreSegments => '增加区域';

  @override
  String get flow20ByDefaultUpTo100Changes => '默认 20，最多 100 区；每次增减 2 区，保持交替';

  @override
  String get flowSpinning => '转盘正在旋转…';

  @override
  String get flowStartWhenYouAreReady => '准备好就开始吧';

  @override
  String flowThisSpinP0(String p0) {
    return '本次：$p0';
  }

  @override
  String get flowSpin => '转一转';

  @override
  String get flowError3 => '误差 +';

  @override
  String get flowEG5 => '如 5';

  @override
  String get flowNoMatchingResults => '没有符合条件的结果';

  @override
  String get flowBREAKDistributionCalculator => '绝赞分布计算';

  @override
  String get flowTAPGREATAllowance => '个 TAP GREAT 的容错';

  @override
  String get flowUserData => '用户数据';

  @override
  String flowP0TAPGREATs(String p0) {
    return '$p0 个 TAP GREAT';
  }

  @override
  String get flowTodaySRecommendations => '今日推荐';

  @override
  String get flowPreparingTodaySRecommendations => '正在准备今日推荐…';

  @override
  String get flowAnotherBatch => '换一批';

  @override
  String get flowPickingTodaySRecommendations => '正在为你挑选今日推荐…';

  @override
  String get flowNoChartsToRecommendYetRefreshData => '暂无可推荐的谱面\n请先在首页刷新数据';

  @override
  String get flowBackupsExportFavoritesChartNotesAccountProfiles =>
      '备份包含收藏夹、谱面笔记、账号资料、设置、猜歌统计、成绩与 Rating 历史、自定义背景及本地谱面包归档，导出为 JSON 文件。\n\n登录凭据、个人 key 和自动同步身份不会导出，换设备后需重新授权。曲库、maidata、音源、PV 和排行榜等可重新获取的缓存不备份。\n\n兼容旧版备份；旧备份仅能恢复其中原本包含的设置和资料。文件总大小上限为 50 MB。';

  @override
  String get flowExportBackup => '导出备份';

  @override
  String get flowExportLocalDataAsAJSONFile => '将当前所有本地数据导出为 JSON 文件';

  @override
  String flowExportedToP0(String p0) {
    return '已导出到: $p0';
  }

  @override
  String get flowImportBackup => '导入备份';

  @override
  String get flowRestoreDataFromAJSONBackup => '从 JSON 文件恢复之前备份的数据';

  @override
  String get flowChooseWhereToSaveTheBackup => '选择备份保存位置';

  @override
  String get flowExportCancelled => '导出已取消';

  @override
  String get flowConfirmRestore => '确认恢复数据';

  @override
  String get flowRestoringOverwritesCurrentLocalSettingsAndProfiles =>
      '恢复将覆盖当前本地设置与用户资料。v3 备份还会恢复用户文件；旧版备份只能恢复它原本包含的内容。建议先导出当前备份。';

  @override
  String flowBackupVersionVP0(String p0) {
    return '备份版本: v$p0';
  }

  @override
  String flowExportedP0(String p0) {
    return '导出时间: $p0';
  }

  @override
  String flowContainsP0DataItems(String p0) {
    return '包含 $p0 个数据项';
  }

  @override
  String flowUserFilesP0(String p0) {
    return '用户文件：$p0 个';
  }

  @override
  String flowExcludedP0CacheItems(String p0) {
    return '已排除 $p0 个缓存项';
  }

  @override
  String get flowSongMaidataAndLeaderboardCachesAreExcluded =>
      '曲库、maidata、排行榜等缓存不参与备份，恢复后按需重新获取，首次加载可能稍慢。登录凭据不会从备份恢复。';

  @override
  String get flowThisCannotBeUndoneContinue => '此操作不可撤销，确定要继续吗？';

  @override
  String get flowRestore => '确认恢复';

  @override
  String flowRestoredP0SettingsAndP1UserFiles(String p0, String p1) {
    return '数据恢复成功！共恢复 $p0 项设置和 $p1 个用户文件。\n建议重启应用以确保完全生效。';
  }

  @override
  String flowImportFailedP02(String p0) {
    return '导入失败: $p0';
  }

  @override
  String get flowMinimumConstant => '最低定数';

  @override
  String get flowMaximumConstant => '最高定数';

  @override
  String get flowNoRecommendationsCheckTheConstantRange =>
      '暂无推荐结果，请检查定数区间输入是否正确';

  @override
  String get flowRenameFavoritesFolder => '重命名收藏夹';

  @override
  String get flowEnterANewName => '请输入新名称';

  @override
  String get flowDeleteFavoritesFolder => '删除收藏夹';

  @override
  String flowDeleteP0ChartsWillRemainButWill(String p0) {
    return '确定要删除收藏夹「$p0」吗？\n收藏夹内的谱面不会被删除，但将不再分组。';
  }

  @override
  String flowDeletedP0(String p0) {
    return '已删除收藏夹「$p0」';
  }

  @override
  String get flowImportFavorites => '导入收藏夹';

  @override
  String get flowAddChartsToFavoritesFoldersFromSong => '在乐曲详情页中可以将谱面收藏到收藏夹';

  @override
  String flowOrUseImportFavoritesAboveP0(String p0) {
    return '也可以点上方「导入收藏夹」按钮，$p0';
  }

  @override
  String get flowRemoveChart => '移除谱面';

  @override
  String flowRemoveP1FromP0(String p0, String p1) {
    return '确定从「$p0」中移除「$p1」吗？';
  }

  @override
  String get flowRemove => '移除';

  @override
  String get flowRemoved => '已移除';

  @override
  String get flowSortOrder => '排序方式';

  @override
  String get flowExportFavorites => '导出收藏夹';

  @override
  String get flowFavoritesFolderIsEmpty => '收藏夹为空';

  @override
  String get flowRemoveFromFavoritesFolder => '从收藏夹移除';

  @override
  String flowP0Selected(String p0) {
    return '已选 $p0 项';
  }

  @override
  String get flowMove => '移动';

  @override
  String get flowRemoveMultipleCharts => '批量移除谱面';

  @override
  String flowRemoveP1ChartsFromP0(String p0, String p1) {
    return '确定要从「$p0」中移除 $p1 个谱面吗？';
  }

  @override
  String flowRemovedP0Charts(String p0) {
    return '已移除 $p0 个谱面';
  }

  @override
  String get flowNoOtherFoldersToMoveTo => '没有其他收藏夹可移动';

  @override
  String get flowMoveTo => '移动到...';

  @override
  String flowMovedP0Charts(String p0) {
    return '已移动 $p0 个谱面';
  }

  @override
  String get flowThisFolderIsEmptyThereAreNo => '这个收藏夹还是空的，没有可导出的谱面';

  @override
  String get flowChooseWhereToExportFavorites => '选择收藏夹导出位置';

  @override
  String flowExportedP02(String p0) {
    return '已导出 $p0';
  }

  @override
  String get flowImportItInTheAppOrOpen =>
      '可以直接在 App 内「导入收藏夹」，或在文件管理器里点开该文件一键导回';

  @override
  String get flowFileSavedTo => '文件已保存到：';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved =>
      '公开目录不可写，文件已保存到应用私有目录，可能无法在系统文件管理器中直接找到。';

  @override
  String get flowInvalidLink => '链接无效';

  @override
  String get flowCouldNotOpenABrowserLinkCopied3 => '无法打开浏览器，链接已复制到剪贴板';

  @override
  String get flowRelatedCommunityProjectsTapACardTo =>
      '这里收录了同好/同行项目的友情链接，点击卡片即可在浏览器中打开。';

  @override
  String flowSkippedP0ForThisSession(String p0) {
    return '已跳过 $p0（仅本次）';
  }

  @override
  String flowCouldNotSaveFeedbackP0(String p0) {
    return '保存反馈失败：$p0';
  }

  @override
  String flowStoppedRecommendingP0UndoInFeedbackManagement(String p0) {
    return '不再推荐 $p0（可在反馈管理里撤销）';
  }

  @override
  String flowPausedRecommendationsForP0For14Days(String p0) {
    return '$p0 暂停推荐 14 天';
  }

  @override
  String get flowUndo => '撤销';

  @override
  String get flowManageFeedback => '反馈管理';

  @override
  String get flowNoChartsCanDirectlyRaiseYourRating =>
      '暂时没有能直接涨 Rating 的谱面。\n刷新成绩后再来看看吧。';

  @override
  String get flowNoUnseenCandidatesMatchStartOverOr =>
      '暂无符合条件的未见候选。\n可以重新开始，或在反馈管理里撤销屏蔽。';

  @override
  String get flowTotalGainIfAllTargetsOnThis => '本页全部达成的合计（按 B50 逐步重算，已扣除互相顶替）';

  @override
  String flowBatchP0P1EntriesEachGainIs(String p0, String p1) {
    return '第 $p0 批 · $p1 条（每条为独立净收益，不可直接相加）';
  }

  @override
  String get flowStartOver => '重新开始';

  @override
  String get flowNoMore => '已无更多';

  @override
  String get flowCurrentB50 => '当前 B50';

  @override
  String flowB35CutoffP0(String p0) {
    return 'B35 · 底线 $p0';
  }

  @override
  String flowB15CutoffP0(String p0) {
    return 'B15 · 底线 $p0';
  }

  @override
  String flowCountedB35P0P1B15P2P3(String p0, String p1, String p2, String p3) {
    return '已计入 B35 $p0/$p1 · B15 $p2/$p3';
  }

  @override
  String get flowNetGain => '净收益';

  @override
  String get flowFeedback => '反馈';

  @override
  String get flowSkipThisTime => '这次跳过';

  @override
  String get flowTemporarilyStuck14Days => '暂时卡住（14 天）';

  @override
  String get flowDislikeThisChart => '不喜欢这张谱';

  @override
  String flowNoScoreRecordedReferenceTargetP0(String p0) {
    return '未记录成绩 → 参考目标 $p0%';
  }

  @override
  String flowP0P1GainP2(String p0, String p1, String p2) {
    return '$p0% → $p1%（提升 $p2%）';
  }

  @override
  String get flowSteadyTargetImprovement020Challenge0 =>
      '稳妥 = 目标提升 ≤ 0.20%，挑战 = 提升 ≤ 0.80%，探索 = 未记录成绩、按你同定数档的中位成绩估算。「稳妥」指差距小，不是成功率。\n基于本地缓存的成绩计算，刷新数据后结果会更新。';

  @override
  String get flowRatingGainRecommendationsPoweredByAWMC => '吃分推荐算法由 AWMC 提供支持';

  @override
  String get flowUndoingDoesNotInsertChartsBackInto =>
      '撤销后谱面不会插回当前这一批，换批或重新开始时才会再出现。';

  @override
  String get flowNoFeedbackYet => '还没有反馈记录';

  @override
  String get flowDislikedUntilUndone => '不喜欢 · 直到撤销';

  @override
  String flowTemporarilyStuckClearsAutomaticallyOnP0(String p0) {
    return '暂时卡住 · $p0 自动解除';
  }

  @override
  String flowP0ArcadesTapToExpand(String p0) {
    return '$p0 家机厅，点击展开';
  }

  @override
  String get flowTurnOnDeviceLocationServicesFirst => '请先开启设备定位服务';

  @override
  String get flowLocationPermissionIsPermanentlyDeniedEnableIt =>
      '定位权限已被永久拒绝，请在系统设置中开启';

  @override
  String get flowCouldNotGetYourLocationCheckThat => '无法获取当前位置，请确认已开启定位服务且信号良好';

  @override
  String flowLocationFailedP0(String p0) {
    return '定位失败: $p0';
  }

  @override
  String get flowFiltered => ' (筛选)';

  @override
  String flowP0ArcadesInViewNearbyPointsGrouped(String p0) {
    return ' 视野内 $p0 家（邻近点自动合并）';
  }

  @override
  String flowLastUpdatedP0(String p0) {
    return '上次更新: $p0';
  }

  @override
  String get flowSearchArcadeNameOrAddress => '搜索店名或地址';

  @override
  String get flowMachineFilters => '机台筛选';

  @override
  String get flowNoArcadeDataYet => '暂无店铺数据';

  @override
  String get flowMachines => '🎮 机台:';

  @override
  String get flowCouldNotOpenTheLinkTryAgain => '无法打开链接，请稍后重试';

  @override
  String get flowCouldNotLoadDocumentTapToRetry => '文档读取失败，点击重试';

  @override
  String get flowSubmitALoadingQuote => '上传语录到云端';

  @override
  String get flowAddALocalQuote => '本地新增语录';

  @override
  String get flowUploadFailedTryAgainLater => '上传失败，请稍后重试';

  @override
  String flowSubmittedForReviewP0ShownOnlyAfter(String p0) {
    return '已提交审核（$p0），审核通过后才会展示';
  }

  @override
  String get flowLocalQuoteAdded => '本地语录添加成功';

  @override
  String get flowCouldNotFetchLoadingQuotesKeptThe => '获取加载语录失败，已保留本地缓存';

  @override
  String get flowRefreshQuotes => '刷新语录';

  @override
  String flowP0QuotesEnabled(String p0) {
    return '/ $p0 条已启用';
  }

  @override
  String get flowAddLocally => '本地新增';

  @override
  String get flowUploadToCloud => '上传到云端';

  @override
  String get flowDeleteLocalQuote => '删除本地语录';

  @override
  String get flowEnterALoadingQuote => '输入加载语录';

  @override
  String get flowDataFromIsMaiDownByChongxi => '数据来源于 isMaiDown by Chongxi';

  @override
  String get flowServiceStatus => '服务状态';

  @override
  String get flowReadingServerStatus => '正在读取服务器状态…';

  @override
  String flowUpdatedP02(String p0) {
    return '更新时间：$p0';
  }

  @override
  String get flowDifficultyNotSpecified => '未指定难度';

  @override
  String flowNoteP0(String p0) {
    return '备注：$p0';
  }

  @override
  String get flowRemoveThisEntry => '移除这一次';

  @override
  String get flowMeetChiffonMai => '先认识一下 ChiffonMai';

  @override
  String get flowFiveTabsKeepEverythingWithinReach => '五个标签页，想找的东西都在这里。';

  @override
  String get flowRefreshDataThenStartExploring => '先刷新数据，再开始探索';

  @override
  String get flowARefreshPreparesSongsConstantsTagsAnd =>
      '刷新数据会准备曲库、定数、标签和成绩。\n不登录也可以先逛逛。';

  @override
  String get flowMakeItFeelLikeYourApp => '把体验调成你喜欢的样子';

  @override
  String get flowFindTheseOptionsInMeSettingsAnd => '都在「我的」页的设置里，随时可以改。';

  @override
  String get flowPhotosAndMedia => '相册与媒体';

  @override
  String get flowChooseCoverArtAndSaveExportedSong => '用于选择曲绘、保存导出的歌曲信息和成绩图片。';

  @override
  String get flowCamera => '相机';

  @override
  String get flowCaptureCoverArtOrScoreImagesFor => '用于拍摄曲绘或成绩截图进行识别。';

  @override
  String get flowLocation => '位置';

  @override
  String get flowUsedForLocationFeaturesOnTheGlobal => '用于全球机厅地图中的位置服务。';

  @override
  String get flowNotifications => '通知';

  @override
  String get flowShowPlaybackControlsDuringBackgroundMusicPlayback =>
      '用于随身听后台播放时显示通知栏控制。';

  @override
  String get flowCouldNotSaveConfirmationPleaseRetry => '确认记录保存失败，请重试';

  @override
  String get flowSeparateGuardianConsent => '监护人单独同意';

  @override
  String get flowPleaseHandTheDeviceToAGuardian =>
      '请将设备交由监护人操作。监护人应阅读以下文件，了解所处理的信息、用途，以及查询和删除信息的方式。';

  @override
  String get flowIAmThisUserSGuardianI =>
      '我是该用户的监护人，已阅读并同意《用户协议》和《隐私政策》，同意为提供相应功能处理被监护人的必要个人信息。';

  @override
  String get flowAfterConsentPermissionsAndFeaturesRemainOptional =>
      '同意后，仍可按需选择权限和相关功能；也可按隐私政策说明撤回授权或申请删除信息。';

  @override
  String get flowGuardianConsent => '监护人同意';

  @override
  String get flowGoBackOnceMoreToExit => '再返回一次退出应用';

  @override
  String get flowGettingStartedWithChiffonMai => 'ChiffonMai 入门';

  @override
  String get flowPrevious3 => '上一步';

  @override
  String get flowStartExploring => '开始探索';

  @override
  String get flowNext3 => '下一步';

  @override
  String get flowWelcomeToChiffonMai => '欢迎来到 ChiffonMai';

  @override
  String get flowSongsChartsScoresAndUsefulToolsAll =>
      '歌曲、谱面、成绩与实用工具都在这里，\n从查一首歌到推一次分，慢慢来就好。';

  @override
  String get flowAllSet => '准备完成！';

  @override
  String get flowStartExploringWithASong => '接下来，就从一首歌开始探索吧。';

  @override
  String flowCouldNotRequestPermissionP0(String p0) {
    return '申请权限失败：$p0';
  }

  @override
  String get flowAgreementsAndPermissions => '协议与权限';

  @override
  String get flowAgreeToTheDocumentsFirstYouCan =>
      '先确认协议才能继续。权限可以现在允许，也可以等用到时再说。';

  @override
  String get flowTheSystemManagesNetworkAccessBackgroundPlayback =>
      '网络、后台播放和安全存储由系统自动管理，不需要在这里单独授权。';

  @override
  String get flowIHaveReadAndAgreeTo => '我已阅读并同意';

  @override
  String get flowUserAgreement => '《用户协议》';

  @override
  String get flowPrivacyPolicy => '《隐私政策》';

  @override
  String get flowToProvideTheGameServiceWeProcess =>
      '为提供游戏服务，我们会处理你的游玩记录、歌曲成绩、账号及设备标识等必要信息；多人联机对战会实时传输对局通信数据，仅用于维持联机功能。';

  @override
  String get flowUsersUnder18ShouldUseTheApp =>
      '未满18周岁请在监护人指导下使用。未满14周岁需由监护人单独同意。';

  @override
  String get flowGuardianHasGivenSeparateConsent => '监护人已单独同意';

  @override
  String get flowUnder14GuardianMustProvideConsent => '未满14周岁，由监护人完成同意';

  @override
  String flowP0SelectAllowFullAccessInThe(String p0) {
    return '$p0 请在系统弹窗中选择“允许完全访问”。';
  }

  @override
  String get flowAccessIsCurrentlyLimitedChangeToAllow =>
      '当前是有限访问，请在系统设置中改为“允许完全访问”。';

  @override
  String get flowNotAuthorizedYetPermissionWillBeRequested =>
      '当前未授权，使用相关功能时仍会再次请求。';

  @override
  String get flowOpenSettings => '去设置';

  @override
  String get flowAllow => '允许';

  @override
  String flowDrawFailedP0(String p0) {
    return '抽取失败：$p0';
  }

  @override
  String get flowNumberToDraw => '抽取数量';

  @override
  String get flowPreparing => '准备中…';

  @override
  String get flowStop => '停！';

  @override
  String get flowStartDrawing => '开始抽奖';

  @override
  String get flowDrawResults => '抽取结果';

  @override
  String flowP0SongsDrawn(String p0) {
    return '本次抽取 $p0 首';
  }

  @override
  String get flowDrawHistory => '历史抽取记录';

  @override
  String get flowNoHistoryYet2 => '暂无历史记录';

  @override
  String get flowRecommendationRange => '推荐范围';

  @override
  String get flowPrioritizeChartsInRange => '范围内谱面优先';

  @override
  String get flowRecalculateByTargetRating => '按目标 Rating 重新计算';

  @override
  String get flowRecalculateByConstantRange => '按定数区间重新计算';

  @override
  String get flowCalculatingRecommendations => '正在计算推荐结果...';

  @override
  String get flowSongConstant => '歌曲定数';

  @override
  String get flowSongRating => '单曲 Rating';

  @override
  String get flowMultiplier => '乘数';

  @override
  String get flowEnterConstantAndAchievementToCalculateSong =>
      '填好定数和达成率后自动计算 · 单曲 Rating = 定数 × 乘数 × 达成率（取整）';

  @override
  String get flowSongRatingConstantMultiplierAchievementRoundedDown =>
      '单曲 Rating = 定数 × 乘数 × 达成率（取整）';

  @override
  String get flowEquivalentConstants => '等效定数对照';

  @override
  String flowEquivalentToP0(String p0) {
    return '相当于 $p0';
  }

  @override
  String get flowMultiplierTable => '乘数对照表';

  @override
  String get flowUseTheMultiplierWhenAchievementMeetsThe =>
      '达成率不低于左列时使用对应乘数；超过 100.5% 按 100.5% 计算';

  @override
  String get flowAchievement4 => '达成率 ≥';

  @override
  String get flowChooseWhereToSaveTheSupportQR => '选择赞赏码保存位置';

  @override
  String get flowSupportQRCodeSaved => '赞赏码已保存';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved2 =>
      '公开目录不可写，已保存到应用文档目录。可通过分享或应用文件访问。';

  @override
  String get flowChiffonMaiIsAFreeOpenSourceTool =>
      'ChiffonMai 是一款完全免费的开源工具，如果它帮到了你，欢迎支持开发者！';

  @override
  String get flowWeChatSupportQRCode => '微信赞赏码';

  @override
  String get flowDownloadQRImage => '下载赞赏码图片';

  @override
  String get flowOrSupportMeOnAfdian => '或通过爱发电支持我';

  @override
  String get flowOpenAfdian => '前往爱发电';

  @override
  String get flowYourSupportKeepsDevelopmentAndMaintenanceGoing =>
      '你的支持是我持续维护与开发的动力，感谢！❤️';

  @override
  String get flowYouAlreadyGuessedThisSong => '已经猜过这首歌了！';

  @override
  String get flowHowToPlay => '规则说明';

  @override
  String get flowGreenTheAttributeMatchesTheTargetExactly =>
      '绿色 - 该属性与你猜的完全一致。';

  @override
  String get flowOrangeTheAttributeIsCloseToThe => '橙色 - 该属性与你猜的\"接近\"：';

  @override
  String get flowBPMDiffersByNoMoreThan20 => 'BPM 相差在 ±20 范围内；';

  @override
  String get flowMASTEROrReMASTERDifficultyDiffersBy =>
      'MASTER 难度或 Re:MASTER 难度相差在 ±0.4范围内；';

  @override
  String get flowVersionsAreOneGenerationApartEG =>
      '版本相差一个世代（例如 maimai ← maimai PLUS → maimai GreeN）。';

  @override
  String get flowGrayTheAttributeIsFarFromThe => '灰色 - 该属性与你猜的\"差距较大\"。';

  @override
  String get flowArrows => '箭头：';

  @override
  String get flowTargetValueIsHigherThanYourGuess => '↑ - 目标值比你猜的更高';

  @override
  String get flowTargetValueIsLowerThanYourGuess => '↓ - 目标值比你猜的更低';

  @override
  String get flowDesignInspiration2 => '设计思路借鉴：';

  @override
  String get flowCouldNotOpenThisLinkLinkCopied => '无法打开该链接，链接已复制到剪贴板';

  @override
  String get flowNoSongsMatchTheseFiltersBroadenYour => '当前筛选条件抽不到曲目，请放宽筛选条件';

  @override
  String get flowGameSettings => '游戏设置';

  @override
  String get flowAppliesFromTheNextGame => '保存后下局生效';

  @override
  String get flowSettingsSavedTheyApplyFromTheNext => '设置已保存，将在下局游戏生效';

  @override
  String get flowLoading5 => '加载中...';

  @override
  String get flowRules => '规则';

  @override
  String get flowSettings => '设置';

  @override
  String get flowNewQuestion => '换一题';

  @override
  String get flowYouGotIt => '恭喜你猜对了！';

  @override
  String get flowThisGameSAnswer => '本局答案';

  @override
  String get flowSearchTitleAliasIDAndMore => '搜索歌名、别名、编号等';

  @override
  String get flowModeSettings => '本模式设置';

  @override
  String get flowDestruction => '破坏程度';

  @override
  String get flowBlur => '模糊程度';

  @override
  String get flowCoverArtIsTurnedIntoAPixel =>
      '曲绘按所选破坏程度处理为像素马赛克，请根据色块、配色和轮廓猜出歌名。0% 为原图，数值越高，像素块越大。';

  @override
  String get flowTheOriginalCoverAppearsAfterACorrect => '猜中、放弃或回合结束后会显示原始曲绘。';

  @override
  String flowDestructionP0(String p0) {
    return '破坏程度 $p0%';
  }

  @override
  String get flowARandomSongIsChosenFromYour =>
      '从你已缓存谱面的曲库中随机选一首，随机播放一段无声的谱面动画片段。';

  @override
  String get flowWatchNoteDensityPatternsAndReachTo =>
      '仔细观察物量密度、键型与出张方式，猜出这是哪首歌。';

  @override
  String flowYouMayReplayTheExcerptUpTo(String p0) {
    return '片段最多可复播 $p0 次。';
  }

  @override
  String get flowTags2 => '标签：';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor =>
      '显示您猜测的曲目的 MASTER 难度的配置、难度和评价标签。';

  @override
  String get flowATagTurnsGreenWhenItMatches => '当一个标签与目标曲目的属性一致时，该标签会变为绿色。';

  @override
  String get flowSomeSongsMayNotHaveTags => '注意，有些曲目可能未添加标签。';

  @override
  String get flowNoSongsMatchBroadenTheDifficultyPool =>
      '当前筛选条件抽不到曲目，请放宽难度池 / 定数范围或筛选条件';

  @override
  String get flowExcerptLength => '片段时长';

  @override
  String get flowNoChartsAvailableCacheMaidataInThe =>
      '没有可用的谱面，请先在谱面库中缓存 maidata';

  @override
  String get flowExcerptFinished => '片段播放完毕';

  @override
  String get flowLoadingAudio2 => '正在加载音频…';

  @override
  String get flowReplayExcerptAudioUnavailable => '复播片段（音频不可用）';

  @override
  String get flowReplayExcerptWithAudio => '复播片段（带音频）';

  @override
  String get flowReplayExcerpt => '复播片段';

  @override
  String get flowPlayExcerpt => '播放片段';

  @override
  String flowReplayP0(String p0) {
    return '复播$p0';
  }

  @override
  String get flowTheCoverFlashesBrieflyAtTheStart =>
      '开局时曲绘会闪现一瞬间（时长可在设置中调整），随后消失。';

  @override
  String get flowRememberTheCoverThenSearchBelowAnd => '凭记忆在下方搜索并猜出这首歌曲。';

  @override
  String get flowFlashDuration => '快闪时长';

  @override
  String get flowPlaybackLength => '播放时长';

  @override
  String flowAudioPlaybackFailedP0(String p0) {
    return '音频播放失败：$p0';
  }

  @override
  String get flowTheCoverIsSplitIntoTilesAt =>
      '曲绘被切成若干小块，每隔一段时间会随机揭示其中一批，已揭示的小块会累积保留 —— 拼图会越来越完整。';

  @override
  String get flowEarlierGuessesImproveYourScoreAverageTime =>
      '越早猜中得分越高（计入平均用时），也可以等拼图更完整后再下手。';

  @override
  String get flowTileCount => '切块数量';

  @override
  String get flowRevealInterval => '揭示间隔';

  @override
  String flowP0RevealedP1P2Tiles(String p0, String p1, String p2) {
    return '已显示 $p0%（$p1 / $p2 块）';
  }

  @override
  String get flowRevealPaused => '揭示已暂停';

  @override
  String flowNextRevealInP0S(String p0) {
    return '$p0 秒后揭示下一批';
  }

  @override
  String get flowResumeReveal => '继续揭示';

  @override
  String get flowPauseReveal => '暂停揭示';

  @override
  String get flowCouldNotReloadSongsCheckYourConnection => '重新拉取曲库失败，请检查网络后重试';

  @override
  String get flowFetchingSongs => '正在拉取曲库...';

  @override
  String get flowReloadSongs => '重新拉取曲库';

  @override
  String get flowOpenSettings2 => '打开设置';

  @override
  String get flowSettingsSavedLocally => '设置已保存到本地';

  @override
  String get flowChangesSaveAutomaticallyAndApplyToThe => '修改会自动保存，下一局生效。';

  @override
  String get flowSongExcerptsReverseAndSpeedPitch => '歌曲片段、倒放与变速变调';

  @override
  String get flowChartExcerpt => '谱面片段';

  @override
  String get flowCoverModes => '曲绘玩法';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate =>
      '破坏程度为 0% 时显示原图，数值越高，像素块越大。';

  @override
  String get flowRevealLetters => '开字母';

  @override
  String get flowDefaultSettingsRestored => '已恢复默认设置';

  @override
  String get flowEnterOneCharacter => '请输入一个字符！';

  @override
  String get flowEnterASongTitle => '请输入歌曲名称！';

  @override
  String get flowCorrect => '猜对了！';

  @override
  String flowGuessP0(String p0) {
    return '猜测 #$p0';
  }

  @override
  String flow1TheGameRandomlySelectsP0Songs(String p0) {
    return '1. 游戏开始时，系统会随机从舞萌曲库中抽取$p0首歌曲。';
  }

  @override
  String get flow2SendXWhereXIsOne =>
      '2. 玩家可以发送 \"开字母 X\"（X 为任意汉字、日文、数字或符号，只能输入一个字符）。';

  @override
  String get flow3IfATitleContainsThatCharacter =>
      '3. 若某首歌曲名包含该字，则揭示该字在歌名中的位置。';

  @override
  String get flow4IfNoTitleContainsItNo => '4. 若不包含，则无提示。';

  @override
  String get flow5UseTheRevealedCharactersToInfer =>
      '5. 玩家根据揭示的文字碎片，推理完整曲名，发送 \"回答 曲名/别名\" 作答。';

  @override
  String get flow6GuessEverySongOrSurrenderTo => '6. 猜中所有歌曲或点击投降结束游戏，会公布游戏结果。';

  @override
  String get flowSongsPerGame => '每次抽取歌曲数';

  @override
  String get flowNonEnglishCharacterFilterPercentage => '非英文字符过滤百分比';

  @override
  String get flowEnterOneCharacter2 => '输入一个字符';

  @override
  String get flowSurrender => '投降';

  @override
  String get flowNewGame => '新游戏';

  @override
  String get flowGuessHistory => '猜测历史';

  @override
  String get flowBlueGateDetails => '蓝色之门详情';

  @override
  String get flowWhiteGateDetails => '白门详情';

  @override
  String get flowPurpleGateDetails => '紫色之门详情';

  @override
  String get flowBlackGateDetails => '黑色之门详情';

  @override
  String get flowYellowGateDetails => '黄色之门详情';

  @override
  String get flowRedGateDetails => '红色之门详情';

  @override
  String get flowPrismTowerDetails => '棱镜塔详情';

  @override
  String get flowGlitchGateDetails => '乱码之门详情';

  @override
  String get flowHopeGateDetails => '希望之门详情';

  @override
  String get flowFinalPhaseDetails => '最终相详情';

  @override
  String get flowNoActiveChallengesCheckTheScheduleBelow =>
      '暂无进行中的挑战，可以看看下方的时间安排';

  @override
  String get flowCurrentPhase => '当前阶段';

  @override
  String get flowLIFEPhase1Phase2 => 'LIFE 一阶段 / 二阶段';

  @override
  String get flowInProgress => '进行中';

  @override
  String flowPhase1P0(String p0) {
    return '一阶段 $p0';
  }

  @override
  String flowPhase2P0(String p0) {
    return '二阶段 $p0';
  }

  @override
  String flowMarkedP0P1(String p0, String p1) {
    return '已标记 $p0 / $p1';
  }

  @override
  String get flowTapASongToToggleCompletion => '点击歌曲可切换完成状态';

  @override
  String get flowEnableMarkingThenTapSongsToRecord => '开启标记后点歌曲记录完成情况';

  @override
  String get flowMarkingMode => '标记模式';

  @override
  String get flowCouldNotLoadTheGuideTryAgain => '攻略加载失败，请稍后重试';

  @override
  String flowSongIDP02(String p0) {
    return '歌曲 ID $p0';
  }

  @override
  String get flowRefreshTheLibraryToShowSongInformation => '刷新曲库后显示歌曲信息';

  @override
  String get flowRefreshGateList => '刷新门列表';

  @override
  String get flowEnterYourLXNSPersonalAPIKey => '请输入落雪个人 API 密钥';

  @override
  String get flowLXNSAPIKeySaved => '落雪 API 密钥已保存';

  @override
  String get flowSavedLocallyItWillBeLinkedTo => '已本地保存，同步时将自动绑定到云端';

  @override
  String get flowSetYourLXNSPersonalAPIKeyFirst => '请先设置落雪个人 API 密钥';

  @override
  String get flowHowDoIGetIt => '如何获取？';

  @override
  String get flowThenScrollToTheBottomToFind => '，滑到页面最底部即可找到个人 API 密钥。';

  @override
  String get flowLXNSAPIKeyIsSet => '落雪 API 密钥已设置';

  @override
  String flowClosesAutomaticallyInP0S(String p0) {
    return '${p0}s 后自动关闭';
  }

  @override
  String flowP0GotItP1Points(String p0, String p1) {
    return '🎉 $p0 答对了! +$p1分';
  }

  @override
  String get flowNoConfirmationReceivedCheckYourConnectionAnd =>
      '操作未收到确认，请检查连接后重试';

  @override
  String get flowTimingStartsWhenTheRoundBeginsNot =>
      '注意：计时是从「回合开始」算的，不是从「猜中上一首」算的。所以后面几首天然比第一首慢 —— 不是你的错觉。';

  @override
  String get flowConfirmLeaving => '确认离开';

  @override
  String get flowLeaveThisRoom => '是否离开当前房间？';

  @override
  String get flowLeave => '离开';

  @override
  String get flowNoConfirmationOfLeavingReceivedPleaseRetry => '退出房间未收到确认，请重试';

  @override
  String flowCouldNotLeaveRoomP0(String p0) {
    return '退出房间失败：$p0';
  }

  @override
  String get flowRestoringGame => '正在恢复对局…';

  @override
  String get flowWaitingForTheGameToStart => '等待游戏开始...';

  @override
  String get flowGameOver => '游戏结束!';

  @override
  String get flowPlayAgain => '再来一局';

  @override
  String get flowRoundOver => '回合结束!';

  @override
  String get flowNextRound2 => '下一轮';

  @override
  String get flowYouSurrenderedWaitingForOtherPlayers => '已投降，请等待其他玩家……';

  @override
  String flowTimeRemainingP0S(String p0) {
    return '⏱️ 剩余时间: $p0 秒';
  }

  @override
  String get flowWaitingForServerConfirmation => '正在等待服务端确认…';

  @override
  String get flowTimeIsUpWaitingForRoundResults => '时间到，正在等待回合结算…';

  @override
  String get flowSearchSongIDBPMChartDesignerAnd => '搜索歌曲、ID、BPM、谱师等';

  @override
  String get flowTimeLeft => '剩余时间';

  @override
  String get flowGuessesLeft => '剩余次数';

  @override
  String flowP0Points(String p0) {
    return '$p0 分';
  }

  @override
  String flowThisSongHasP0Aliases(String p0) {
    return '该歌曲共有 $p0 个别名';
  }

  @override
  String get flowNoAliasesAvailableGuessFromTheSong => '暂无别名数据，请根据歌曲信息猜歌';

  @override
  String get flowThisRoundHasEnded => '本回合已结束';

  @override
  String flowP0P1SongsRemaining(String p0, String p1) {
    return '剩余 $p0 / $p1 首';
  }

  @override
  String get flowRevealed => '已开:';

  @override
  String get flowCharacters => '字';

  @override
  String get flowPreparingCoverClue => '正在准备曲绘线索…';

  @override
  String get flowWaitingForPlayersToLoadTheCover => '等待玩家加载曲绘…';

  @override
  String get flowFlashingRememberIt => '快闪中……记住它！';

  @override
  String get flowTheCoverIsHiddenGuessFromMemory => '曲绘已消失，凭记忆猜歌名';

  @override
  String flowP0P1TilesRevealedP2(String p0, String p1, String p2) {
    return '已揭示 $p0 / $p1 块$p2';
  }

  @override
  String get flowPaused2 => '（已暂停）';

  @override
  String get flowPreparingChartExcerpt => '正在准备谱面片段…';

  @override
  String get flowNoReplaysLeft => '复播次数已用完';

  @override
  String get flowGuessTheSongFromThisCoverFragment => '根据截取的曲绘部分猜歌名';

  @override
  String get flowOriginalCover => '原始曲绘';

  @override
  String flowBlurP0(String p0) {
    return '模糊程度: $p0%';
  }

  @override
  String get flowSongExcerpt => '歌曲片段';

  @override
  String get flowTheGameHasEnded => '游戏已结束';

  @override
  String get flowReplay => '重新播放';

  @override
  String get flowPlaySongExcerpt => '播放歌曲片段';

  @override
  String get flowMultiplayerRoom => '多人房间';

  @override
  String flowP0RoundP1P2(String p0, String p1, String p2) {
    return '$p0 · 第 $p1/$p2 轮';
  }

  @override
  String get flowReconnect => '重新连接';

  @override
  String flowCouldNotCreateRoomP0(String p0) {
    return '创建房间失败：$p0';
  }

  @override
  String flowCouldNotJoinRoomP0(String p0) {
    return '加入房间失败：$p0';
  }

  @override
  String flowYouAreStillInRoomP0(String p0) {
    return '你还在房间 $p0 里';
  }

  @override
  String flowP0P1PlayersTapToReturn(String p0, String p1) {
    return '$p0 · $p1 人 · 点击返回';
  }

  @override
  String get flowCreateRoom => '创建房间';

  @override
  String get flowChooseAModeAndRulesThenInvite => '选择玩法和规则，邀请好友一起猜歌';

  @override
  String get flowJoinRoom => '加入房间';

  @override
  String get flowEnterARoomCodeSharedByA => '输入好友分享的房间码';

  @override
  String get flowCouldNotCreateRoom => '创建房间失败';

  @override
  String flowCouldNotCreateRoomP02(String p0) {
    return '创建房间失败: $p0';
  }

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate2 =>
      '0% 为原图，数值越高，像素块越大。房间内所有玩家使用相同破坏程度。';

  @override
  String get flowSpeedPitchMultiplier => '变速变调倍率';

  @override
  String get flowRestoreDefaults => '恢复默认设置';

  @override
  String get flowGameMode => '游戏模式';

  @override
  String get flowMaximumPlayers => '最大玩家数';

  @override
  String flowP0Settings(String p0) {
    return '$p0设置';
  }

  @override
  String get flowEnterRoomCode => '输入房间码';

  @override
  String get flowEnterA6DigitCodeOrThe => '输入 6 位房间码，也支持完整房间 ID';

  @override
  String get flowPasteRoomCode => '粘贴房间码';

  @override
  String get flowHowDoIGetARoomCode => '如何获取房间码？';

  @override
  String get flowUpdateDownloadedInstallWhenConvenient => '更新已下载，可在方便时安装';

  @override
  String get flowViewInstallation => '查看安装';

  @override
  String get flowView => '查看';

  @override
  String get flowPreparingTheUpdateInTheBackgroundYou => '正在后台准备更新，可以继续使用 App';

  @override
  String flowExportingP0InTheBackgroundYouCan(String p0) {
    return '正在后台导出$p0，可以继续其它操作';
  }

  @override
  String flowCouldNotExportP0PleaseRetry(String p0) {
    return '$p0导出失败，请重试';
  }

  @override
  String flowCouldNotExportP0CheckStoragePermission(String p0) {
    return '$p0导出失败，请检查存储权限后重试';
  }

  @override
  String flowP0Exported(String p0) {
    return '$p0导出成功';
  }

  @override
  String flowCouldNotExportP0P1(String p0, String p1) {
    return '$p0导出失败：$p1';
  }

  @override
  String get flowCouldNotLoadAppearanceReopenThisPage => '装扮未能读取，请重新打开此页';

  @override
  String get flowChiffonMaiClosedUnexpectedlyLastTime => 'ChiffonMai 上次异常退出';

  @override
  String flowReasonP0AutomaticLogExportFailedExport(String p0) {
    return '原因：$p0。\n日志自动导出失败，可以在「我的 → 打印日志」手动导出。';
  }

  @override
  String get flowChiffonChuAnAllInOneCHUNITHMTool => '这是ChiffonChu，一站式中二工具';

  @override
  String get flowWebMiniGamesFromTheAWMCCommunity => '来自AWMC社区出品的网页小游戏，持续迭代中！';

  @override
  String get flowAnInnovativeRhythmGameInspiredByRailways => '融合铁路元素的创新音游';

  @override
  String get flowAnOfflineMaimaiLibraryWithQuickCover =>
      '一个通过封面快速查询的离线本地maimai曲库';

  @override
  String flowRefusedRequestToANonGatewayAddress(String p0) {
    return '拒绝请求非网关地址: $p0';
  }

  @override
  String flowUnsupportedMethodP0(String p0) {
    return '不支持的方法: $p0';
  }

  @override
  String flowRequestTimedOutP0S(String p0) {
    return '请求超时（${p0}s）';
  }

  @override
  String flowCouldNotScheduleWriteP0(String p0) {
    return '写入调度失败: $p0';
  }

  @override
  String flowMusicListMustContain14EntriesCurrently(String p0) {
    return 'musicList 长度必须为 1–4（当前 $p0）';
  }

  @override
  String get flowOnlyChargeId235IsSupported =>
      '仅支持 chargeId = 2 / 3 / 5（2 倍 / 3 倍 / 5 倍票）';

  @override
  String flowOrderP0(String p0) {
    return '排序：$p0';
  }

  @override
  String flowSourceP0ExportedP1GeneratedByChiffonMai(
      String p0, String p1, String p2) {
    return '数据源：$p0\n导出时间：$p1\nGenerated by ChiffonMai\n交流群：$p2';
  }

  @override
  String get flowCouldNotCreateRoomEnvironmentIDIs => '创建房间失败: 环境ID未设置';

  @override
  String get flowCouldNotCreateRoomNotSignedIn => '创建房间失败: 用户未登录';

  @override
  String flowCouldNotJoinRoomP02(String p0) {
    return '加入房间失败: $p0';
  }

  @override
  String flowCouldNotRejoinRoomP0(String p0) {
    return '重新加入房间失败: $p0';
  }

  @override
  String flowCouldNotChangeReadyStatusP0(String p0) {
    return '设置准备状态失败: $p0';
  }

  @override
  String flowCouldNotChangeSurrenderStatusP0(String p0) {
    return '设置投降状态失败: $p0';
  }

  @override
  String flowCouldNotStartGameP0(String p0) {
    return '开始游戏失败: $p0';
  }

  @override
  String flowCouldNotStartNextRoundP0(String p0) {
    return '开始下一回合失败: $p0';
  }

  @override
  String flowCouldNotSubmitGuessP0(String p0) {
    return '提交猜测失败: $p0';
  }

  @override
  String flowCouldNotRevealLetterP0(String p0) {
    return '开字母失败: $p0';
  }

  @override
  String flowCouldNotSurrenderP0(String p0) {
    return '投降失败: $p0';
  }

  @override
  String flowCouldNotUploadSongsP0(String p0) {
    return '上传歌曲失败: $p0';
  }

  @override
  String flowCouldNotGetSongCountP0(String p0) {
    return '获取歌曲数量失败: $p0';
  }

  @override
  String flowCouldNotParseMessageP0(String p0) {
    return '消息解析失败: $p0';
  }

  @override
  String get flowYellow => '黄';

  @override
  String get flowCurrentSaveLocation => '当前保存位置';

  @override
  String get flowUseTheDefaultPublicDirectoryOrChoose =>
      '可以使用应用默认公开目录，或选择一个自定义文件夹。';

  @override
  String flowCouldNotChooseSaveFolderP0(String p0) {
    return '选择保存目录失败：$p0';
  }

  @override
  String get flowChooseAnotherFolder => '选择其他目录';

  @override
  String get flowUseDefaultPath => '使用默认路径';

  @override
  String get flowThisFolderIsNotWritableChooseAnother => '这个目录不可写，请换一个文件夹。';

  @override
  String get flowCannotImport => '无法导入';

  @override
  String flowImportCompleteP0(String p0) {
    return '导入完成：$p0';
  }

  @override
  String flowP0FoldersP1Charts(String p0, String p1) {
    return '共 $p0 个收藏夹、$p1 个谱面';
  }

  @override
  String flowP0P1Charts2(String p0, String p1) {
    return '· $p0（$p1 个谱面）';
  }

  @override
  String flowP0MoreFolders(String p0) {
    return '· 其余 $p0 个收藏夹…';
  }

  @override
  String get flowMergeWithExistingFolders => '合并到现有收藏夹';

  @override
  String get flowFoldersWithTheSameNameAreMerged => '同名收藏夹会合并，重复谱面自动跳过';

  @override
  String get flowReplaceExistingFavorites => '覆盖导入';

  @override
  String get flowClearAllCurrentFoldersThenImportThe => '先清空当前所有收藏夹，再导入文件内容';

  @override
  String get flowImport => '导入';

  @override
  String flowP0Loading(String p0) {
    return '$p0，加载中';
  }

  @override
  String get flowUnavailable => '暂不可用';

  @override
  String get flowIncrease => '，增加';

  @override
  String get flowDecrease => '，减少';

  @override
  String flowP0P1P2BeijingTime(String p0, String p1, String p2) {
    return '$p0-$p1-$p2 · 北京时间';
  }

  @override
  String get flowDoNotShowThisAnnouncementAgain => '不再提示本条公告';

  @override
  String get flowCouldNotLoadImageTapToRetry => '图片加载失败，点击重试';

  @override
  String get flowEnlargeAnnouncementImage => '放大公告图片';

  @override
  String flowDecreaseP0ByOne(String p0) {
    return '$p0减一';
  }

  @override
  String flowIncreaseP0ByOne(String p0) {
    return '$p0加一';
  }

  @override
  String get flowInstallUpdate => '安装更新';

  @override
  String get flowDownloadUpdateInBackground => '后台下载更新';

  @override
  String get flowNoDownloadTask => '暂无下载任务';

  @override
  String get flowKeepUsingTheApp => '继续使用 App';

  @override
  String get flowCancelInstallationTask => '取消安装任务';

  @override
  String get flowCancelDownload => '取消下载';

  @override
  String get flowDownloadAgain => '重新下载';

  @override
  String get flowAllowInstallation => '允许安装';

  @override
  String get flowInstallNow => '立即安装';

  @override
  String get flowCalculatingCacheSize => '正在统计缓存占用…';

  @override
  String flowTotalUsageP0(String p0) {
    return '总占用 $p0';
  }

  @override
  String get flowAudioCache => '音源缓存';

  @override
  String get flowCalculating3 => '统计中…';

  @override
  String flowP0FilesTotalP1(String p0, String p1) {
    return '$p0 个文件\n共计 $p1';
  }

  @override
  String get flowPVCache => 'PV缓存';

  @override
  String get flowMaidataCache => 'maidata缓存';

  @override
  String get flowReloadBaseMaidata => '重新拉取基础量maidata';

  @override
  String flowCleaningP0(String p0) {
    return '正在清理… $p0%';
  }

  @override
  String get flowCleaning => '清理中…';

  @override
  String get flowClear2 => '清理';

  @override
  String flowNoteSpeedP0P1(String p0, String p1) {
    return '流速 $p0 · $p1';
  }

  @override
  String get flowNoteSpeed => '流速';

  @override
  String get flowMirror => '镜像';

  @override
  String get flowRandomDifficultyPool => '难度随机池';

  @override
  String flowP0ConstantP12(String p0, String p1) {
    return '$p0 定数 $p1';
  }

  @override
  String get flowUTAGE2 => '宴会';

  @override
  String get flowResetTodaySStatistics => '重置今日统计？';

  @override
  String get flowClearTodaySCorrectIncorrectGuessesTimes =>
      '将清空当前玩法今日的正确、错误、用时和连胜记录。';

  @override
  String flowP0SRemaining(String p0) {
    return '剩余 $p0 秒';
  }

  @override
  String get flowResetTodaySStatistics2 => '重置今日统计';

  @override
  String get flowResetStatistics => '重置统计';

  @override
  String get flowThisGameHasEnded => '本局已结束';

  @override
  String flowAnswerP0(String p0) {
    return '正确答案：$p0';
  }

  @override
  String get flowOriginalAudioExcerpt => '原声片段';

  @override
  String get flowPreparingOriginalAudio => '正在准备原声…';

  @override
  String get flowTheSameExcerptPlayedForwardAtOriginal => '本轮同一段音源，按原速正向播放';

  @override
  String get flowSelectAll2 => '选择全部';

  @override
  String get flowCurrentAll => '当前：全部';

  @override
  String flowP0SelectedNoneMeansAll(String p0) {
    return '已选 $p0 项，不选表示全部';
  }

  @override
  String get flowMASTERTags => 'MASTER标签';

  @override
  String flowGuessHistoryP0(String p0) {
    return '猜测历史 ($p0)';
  }

  @override
  String get flowOldestFirst => '从早到晚';

  @override
  String get flowNewestFirst => '从晚到早';

  @override
  String get flowCouldNotOpenTheGuideSourceLink => '无法打开攻略来源，链接已复制到剪贴板';

  @override
  String get flowDataSourceAWMCKALEIDXSCOPE => '数据来源：AWMC KALEIDXSCOPE';

  @override
  String get flowRoom => '房间 ';

  @override
  String flowP0PlayersP1(String p0, String p1) {
    return ' · $p0 人 · $p1';
  }

  @override
  String get flowCopyRoomCode => '复制房间码';

  @override
  String get flowRoomCodeCopied => '房间码已复制';

  @override
  String get flowInviteFriendsToGuessSongsTogether => '邀请好友，一起猜歌';

  @override
  String get flowRoomCode => '房间码';

  @override
  String get flowRoomCodeCopiedSendItToA => '房间码已复制，发送给好友即可加入';

  @override
  String get flowPlayerSlots => '玩家席位';

  @override
  String flowP0P1PlayersP2(String p0, String p1, String p2) {
    return '$p0 / $p1 人$p2';
  }

  @override
  String flowP0Ready(String p0) {
    return ' · $p0 人准备';
  }

  @override
  String get flowWaitingForPlayers => '等待加入';

  @override
  String get flowMe2 => ' · 我';

  @override
  String get flowNotReady => '取消准备';

  @override
  String get flowReady => '准备就绪';

  @override
  String get flowStartGame => '开始游戏';

  @override
  String get flowDecreaseCount2 => '减少数量';

  @override
  String get flowIncreaseCount2 => '增加数量';

  @override
  String get flowConnectionRestored => '已恢复网络连接';

  @override
  String get flowOfflineShowingCachedData => '当前离线 - 显示缓存数据';

  @override
  String flowDrawingP0SongsTapStopToReveal(String p0) {
    return '正在抽取 $p0 首 · 点击“停！”揭晓';
  }

  @override
  String flowCardP0WaitingToReveal(String p0) {
    return '第 $p0 张卡片，等待揭晓';
  }

  @override
  String get flowCyclingCoverArt => '曲绘轮播中…';

  @override
  String flowSongP0WaitingForYouToStop(String p0) {
    return '第 $p0 首 · 等待你按停';
  }

  @override
  String get flowChiffonMaiIsAnAllInOneMobile =>
      'ChiffonMai 是一款专为 舞萌DX 2026（maimai DX 2026）玩家打造的一站式移动端工具类应用，聚合了曲库查询、成绩统计、Rating 计算、曲目推荐等多种实用功能，助力玩家提升游玩体验。';

  @override
  String get flowProvidedTheBackgroundArtworkAndTheLovely =>
      '为本项目提供的背景图和戚风小狐狸（真的非常可爱）';

  @override
  String get flowContributedValuableIdeasForPersonalizedChartRecommendations =>
      '为本项目的个性化谱面推荐功能提供宝贵设计思路';

  @override
  String get flowContributedValuableFeedbackOnPageDesign => '为本项目的页面设计提供了宝贵意见';

  @override
  String get flowProvidedPersonalPlayDataForDevelopmentAnd =>
      '提供了用于测试开发的个人游玩数据';

  @override
  String get flowProposedChiffonMaiAndHelpedSparkTheProject =>
      '提议开发 ChiffonMai，为本项目诞生提供最初契机';

  @override
  String get flowContributedManySuggestionsOnInterfaceDetailsAnd =>
      '为本项目在前端细节与交互体验上提供了诸多宝贵建议';

  @override
  String get flowProvidedTechnicalAndFinancialSupportThatGreatly =>
      '为本项目的开发提供了技术支持和经济支持，为项目的推进提供了极大的帮助';

  @override
  String get flowEveryoneInTheChiffonMaiCommunityGroup => 'ChiffonMai交流群的全体群友';

  @override
  String get flowContributedManySuggestionsAndFeedbackDuringDevelopment =>
      '为本项目开发提供了诸多宝贵建议和反馈';

  @override
  String get flowDivingFish => '水鱼查分器';

  @override
  String get flowProvidesSongAndPlayerScoreDatabases => '提供曲目数据库和玩家游玩记录数据库';

  @override
  String get flowProvidesChartTagAndAliasDatabases => '提供谱面标签数据库和别名数据库';

  @override
  String get flowProvidesAnAliasDatabase => '提供别名数据库';

  @override
  String get flowLXNS => '落雪咖啡屋';

  @override
  String get flowProvidesCollectiblesAudioSongAndPlayerScore =>
      '提供收藏品数据库、歌曲音源支持、曲目数据库和玩家游玩记录数据库';

  @override
  String get flowProvidesChartConversionSupport => '提供谱面转换支持';

  @override
  String get flowProvidesMaimaiServerStatus => '提供舞萌服务器状态信息';

  @override
  String get flowProvidesDivingFishLXNSSyncAndFinancial =>
      '提供水鱼查分器同步支持、落雪查分器同步支持和对本项目开发的经济支持';

  @override
  String get flowProvidesScoreSyncToDivingFishAnd => '提供水鱼查分器和落雪查分器成绩同步支持';

  @override
  String get flowProvidesScoreSyncToLXNS => '提供落雪查分器成绩同步支持';

  @override
  String get flowProvidesASongDatabase => '提供曲目数据库';

  @override
  String get flowProvidesWorldwideArcadeData => '提供全球机厅相关数据';

  @override
  String get flowProvidesHighResolutionVersionArtwork => '提供高清版本图片';

  @override
  String get flowThankYouForYourDonations => '感谢对本项目的捐献支持';

  @override
  String get flowMaintainer => '维护者';

  @override
  String get flowTheDeveloperBehindChiffonMai => 'ChiffonMai 背后的开发者。';

  @override
  String get flowSpecialThanks => '特别致谢';

  @override
  String get flowThanksToEveryoneWhoHelpedInNo => '感谢每一位给予帮助的伙伴，排名不分先后。';

  @override
  String get flowBilibili => 'B 站';

  @override
  String get flowEmail => '邮箱';

  @override
  String get flowSignInFailedTryAgainLater => '登录失败，请稍后再试';

  @override
  String get flowEnterTargetAchievement => '请输入目标达成率';

  @override
  String get flowInvalidAchievementEnterANumberSuchAs =>
      '达成率格式错误，请输入有效的数字（如100.5000）';

  @override
  String get flowEnterAchievementBetween0And101 => '达成率请输入0~101之间的数值';

  @override
  String get flow50PointLoss2 => '50落';

  @override
  String get flow100PointLoss2 => '100落';

  @override
  String get flowBase100Bonus100 => '基础 100% · 奖励 100%';

  @override
  String get flowPERFECT50PointLoss => 'PERFECT · 50落';

  @override
  String get flowBase100Bonus75 => '基础 100% · 奖励 75%';

  @override
  String get flowPERFECT100PointLoss => 'PERFECT · 100落';

  @override
  String get flowBase100Bonus50 => '基础 100% · 奖励 50%';

  @override
  String get flowBase80Bonus40 => '基础 80% · 奖励 40%';

  @override
  String get flowBase60Bonus40 => '基础 60% · 奖励 40%';

  @override
  String get flowBase50Bonus40 => '基础 50% · 奖励 40%';

  @override
  String get flowBase40Bonus30 => '基础 40% · 奖励 30%';

  @override
  String get flowBase0Bonus0 => '基础 0% · 奖励 0%';

  @override
  String get flowNoLoss => '无损失';

  @override
  String get flowStayHome => '不出勤';

  @override
  String get flowScoreTargetsBREAKDistribution => '分数线 / 绝赞分布';

  @override
  String get flowRatingTargets => 'Rating 线';

  @override
  String get flowCalculationMode => '计算模式';

  @override
  String get flowByAchievement => '按达成率';

  @override
  String get flowByRating => '按 Rating';

  @override
  String get flowResult2 => '计算结果';

  @override
  String get flowTargetRating2 => '目标Rating';

  @override
  String get flowEG143 => '如 14.3';

  @override
  String get flowEG1005667 => '如 100.5667';

  @override
  String get flowEG321 => '如 321';

  @override
  String flowAchievementP02(String p0) {
    return '达成率$p0';
  }

  @override
  String get flowNoteDistributionEditable => '物量分布（可编辑）';

  @override
  String get flowScoreLossDetails => '得分 / 失分详细';

  @override
  String flowP0P1P2WeekdayP3(String p0, String p1, String p2, String p3) {
    return '$p0年$p1月$p2日 星期$p3';
  }

  @override
  String get flowExporting3 => '导出中...';

  @override
  String get flowExportBackupFile => '导出备份文件';

  @override
  String get flowRestoringData => '正在恢复数据...';

  @override
  String get flowImporting => '导入中...';

  @override
  String get flowChooseBackupFile => '选择备份文件';

  @override
  String get flowImportClearsAllCurrentLocalDataBefore =>
      '⚠ 导入会先清空当前所有本地数据，再写入备份内容；\n　 备份里没有的项目（含各类缓存）会被一并抹掉。\n　 恢复过程中请不要退出页面。';

  @override
  String get flowBackupFile => '备份文件';

  @override
  String get flowFindTheFileInDownloadsChiffonMaiIn =>
      '可在文件管理器的「下载/ChiffonMai/备份」文件夹中找到该文件。';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved3 => '公开目录不可写，已保存到应用文档目录。';

  @override
  String get flowRename => '重命名';

  @override
  String get flowConstantHighLow => '按定数 (高→低)';

  @override
  String get flowConstantLowHigh => '按定数 (低→高)';

  @override
  String get flowAddedNewOld => '按添加时间 (新→旧)';

  @override
  String get flowAddedOldNew => '按添加时间 (旧→新)';

  @override
  String get flowSongTitleAZ => '按歌曲名 (A-Z)';

  @override
  String get flowSignOut2 => '登出账号';

  @override
  String get flowGetAnImportTokenForScoreSync => '获取ImportToken以便同步成绩';

  @override
  String get flowOnlineLinksAreUnavailableShowingLocallyCached =>
      '在线友链暂时不可用，当前显示本地缓存';

  @override
  String flowCouldNotGenerateRecommendationsP0(String p0) {
    return '生成推荐失败：$p0';
  }

  @override
  String get flowMixed => '混合';

  @override
  String flowSourceRatingP0DiffersFromTheLocally(String p0) {
    return '数据源 Rating $p0，与本地按成绩重算的结果不同，以重算为准';
  }

  @override
  String flowP0ScoresAreMissingFromTheSong(String p0) {
    return '$p0 条成绩在曲库里找不到，按旧曲处理；刷新曲库后更准确';
  }

  @override
  String flowP0P12(String p0, String p1) {
    return '$p0月$p1日';
  }

  @override
  String flowP0Arcades(String p0) {
    return '$p0家';
  }

  @override
  String flowP0ArcadesTotal(String p0) {
    return '共$p0家';
  }

  @override
  String get flowDivingFishSignInFailedTryAgain => '水鱼登录失败，请稍后重试';

  @override
  String get flowUserAgreement2 => '用户协议';

  @override
  String get flowPrivacyPolicy2 => '隐私政策';

  @override
  String flowLocalQuotesP0(String p0) {
    return '本地语录 $p0';
  }

  @override
  String flowCloudQuotesP0(String p0) {
    return '云端语录 $p0';
  }

  @override
  String get flowQuoteCannotBeEmpty => '语录内容不能为空';

  @override
  String get flowServerStatusIsTemporarilyUnavailable => '暂时无法获取服务器状态';

  @override
  String get flowCouldNotLoadServerStatus => '加载服务器状态失败';

  @override
  String get flowHealthy => '好';

  @override
  String get flowUnhealthy => '坏';

  @override
  String get flowLatency => '延迟 --';

  @override
  String flowLatencyP0Ms(String p0) {
    return '延迟 $p0 ms';
  }

  @override
  String flowHealthyP0(String p0) {
    return '正常 $p0';
  }

  @override
  String flowIssuesP0(String p0) {
    return '异常 $p0';
  }

  @override
  String get flowNoSongsAddedYetUseAddTo => '还没有加入歌曲\n在歌曲详情或随身听中点「加入下次想玩」吧';

  @override
  String get flowProfileFavoriteFeaturesSyncAndServerStatus =>
      '个人概况、常用功能、同步和服务器状态';

  @override
  String get flowFindSongsInspectChartsAndBrowseCollectibles => '查歌曲、看谱面、找收藏品';

  @override
  String get flowBest50RatingToolsAndLeaderboards => 'Best50、推分工具和排行榜';

  @override
  String get flowFindArcadesPlayGuessingGamesAndListen => '出勤找机厅，休闲猜歌和听歌';

  @override
  String get flowAccountsDataRefreshAndSettings => '账号、刷新数据和各种设置';

  @override
  String get flowOpenFromMeOrTapYourRating => '在「我的」页，或点首页的 Rating 进入';

  @override
  String get flowSyncScores => '同步成绩';

  @override
  String get flowDivingFishLXNSAndAWMCNETLink => '水鱼、落雪和 AWMC NET，需先绑定账号';

  @override
  String get flowRunsThroughoutTheDayWhenEnabledCheck => '开启后每天分时处理，首页随时能看结果';

  @override
  String get flowTheme => '主题';

  @override
  String get flowLightDarkBlackOrSystemThemePlus => '浅色、深色、纯黑或跟随系统，还能换主题色';

  @override
  String get flowCustomBackgroundImagesDecorationsAndOverlays =>
      '自定义背景图、装饰图和覆层';

  @override
  String get flowNavigation => '导航';

  @override
  String get flowThreeNavigationStylesWithOptionalAnimationAnd =>
      '三种导航栏样式，动画和滑动切换可开关';

  @override
  String get flowConfetti => '纸屑';

  @override
  String get flowCelebrateASuccessfulRefreshOrSyncWith => '刷新或同步成功时放一点纸屑';

  @override
  String get flowEverythingIsReadyRememberToRefreshData => '都准备好了呢。记得先刷新一下数据哦？';

  @override
  String get flowChecking => '检查中';

  @override
  String get flowAllowed => '已允许';

  @override
  String get flowLimitedAccess => '有限访问';

  @override
  String get flowOpenSettings3 => '请前往设置';

  @override
  String get flowNotAllowed => '未允许';

  @override
  String get flowIHaveReadAndAgreeToThe => '我已阅读并同意用户协议和隐私政策';

  @override
  String get flowChooseYourFiltersThenDrawSomeSongs => '选好条件后，开始抽歌吧';

  @override
  String get flowEnterAnIntegerFrom2To100 => '请输入 2–100 之间的整数';

  @override
  String get flowDrawCountMustBeBetween2And => '抽取数量需在 2–100 之间';

  @override
  String get flowNoMatchingSongsAdjustTheFilters => '没有符合条件的歌曲，请调整筛选条件';

  @override
  String get flowSongs3 => ' 首';

  @override
  String get flowAllVersions => '全部版本';

  @override
  String flowP0VersionsSelected(String p0) {
    return '已选 $p0 个版本';
  }

  @override
  String get flowTypeFilter => '类型筛选';

  @override
  String get flowAllTypes => '全部类型';

  @override
  String flowP0TypesSelected(String p0) {
    return '已选 $p0 个类型';
  }

  @override
  String get flowConstantRange => '定数范围';

  @override
  String get flowAdvancedMASTER => 'MASTER 上级';

  @override
  String get flowExpertMASTER => 'MASTER 超上级';

  @override
  String flowCouldNotFetchRecommendationsP0(String p0) {
    return '获取推荐结果失败：$p0';
  }

  @override
  String get flowConstantRange2 => '定数区间';

  @override
  String get flowSimilarity => '相似度';

  @override
  String flowCurrentP0TargetP1(String p0, String p1) {
    return '当前 $p0% → 目标 $p1%';
  }

  @override
  String flowEnterAValidP0(String p0) {
    return '请输入有效的$p0';
  }

  @override
  String flowP0MustBeBetweenP1AndP2(String p0, String p1, String p2) {
    return '$p0必须在$p1到$p2之间';
  }

  @override
  String flowP1ForP0(String p0, String p1) {
    return '$p0 的 $p1';
  }

  @override
  String get flowMultiPlatformSync => '多端同步';

  @override
  String get flowAdvancedDataRefresh => '高级数据刷新';

  @override
  String get flowReadPlayCounts => '读取游玩次数';

  @override
  String get flowSignOut3 => '退出账号';

  @override
  String get flowHomeDataRefresh => '首页数据刷新';

  @override
  String get flowWebsiteLink => '官网链接';

  @override
  String get flowFeedbackLink => '反馈链接';

  @override
  String get flowGroupNumber => '群号';

  @override
  String get flowSurveyLink => '问卷链接';

  @override
  String get flowGatewayCheckBeforeReadingPlayCounts => '读取游玩次数前的网关探活';

  @override
  String get flowReadPlayCountsSeparately => '独立读取游玩次数';

  @override
  String get flowPushToDivingFishThroughTheAWMC => '通过 AWMC 网关推送到水鱼';

  @override
  String get flowPushToLXNSThroughTheAWMCGateway => '通过 AWMC 网关推送到落雪';

  @override
  String get flowCouldNotLoadTheMosaicCoverTry => '马赛克曲绘暂时无法加载，请换一题重试';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate3 => '0% 为原图，数值越高，像素块越大。';

  @override
  String get flowNoCachedChartsCacheMaidataInThe => '谱面缓存为空，请先在谱面库中缓存 maidata';

  @override
  String get flowNoCachedSongsMatchTheDifficultyPool =>
      '没有符合当前筛选条件（难度池 / 定数范围）且有谱面缓存的歌曲';

  @override
  String get flowCouldNotReadThisSongSChart => '未能读取该歌曲的谱面内容';

  @override
  String get flowThisSongHasNoChartsInThe => '该歌曲没有难度池内的谱面';

  @override
  String get flowTheChartIsTooShortToExtract => '谱面过短，无法截取片段';

  @override
  String get flowCouldNotParseChart => '谱面解析失败';

  @override
  String flowP0ReplaysLeft(String p0) {
    return '（还可复播 $p0 次）';
  }

  @override
  String get flowNoReplaysLeft2 => '（复播次数已用完）';

  @override
  String get flowFiltersUseEachSelectedDifficultySOwn =>
      '按「难度随机池」里各难度自己的定数筛选（例如只选 EXPERT 时看 EXPERT 的定数，选 EXPERT+MASTER 时两者任一落在范围内即可），不是按 MASTER 定数。';

  @override
  String get flowCouldNotLoadCoverArtPleaseRetry => '曲绘暂时无法加载，请重试';

  @override
  String get flowNoRecognizableCropAreaInThisCover =>
      '当前曲绘没有可辨认的裁剪区域，请重试或放宽筛选条件';

  @override
  String get flowAudioIsTemporarilyUnavailable => '暂时无法获取音源';

  @override
  String get flowCouldNotReadAudioDuration => '无法读取音源时长';

  @override
  String get flowAudioExcerptIsEmpty => '音频片段为空';

  @override
  String get flowPreparingAudio2 => '正在准备音频…';

  @override
  String flowP0Tiles(String p0) {
    return '$p0 块';
  }

  @override
  String get flowTheSongCacheIsEmptyNoSong => '曲库缓存为空，暂时抽不出曲目';

  @override
  String get flowNoSongsMatchBroadenTheFiltersIn => '当前筛选条件抽不到曲目，请在设置中放宽条件';

  @override
  String get flowCouldNotLoadSettingsPleaseRetry => '设置加载失败，请重试';

  @override
  String get flowExcerptPlaybackLength => '片段播放时长';

  @override
  String get flowS => ' 秒';

  @override
  String get flowBlurredCoverBlur => '模糊曲绘：模糊程度';

  @override
  String get flowPixelCoverDestruction => '像素曲绘：破坏程度';

  @override
  String get flowFlashCoverDuration => '曲绘快闪：快闪时长';

  @override
  String get flowTileRevealTileCount => '曲绘拼图：切块数量';

  @override
  String get flowTiles => ' 块';

  @override
  String get flowTileRevealInterval => '曲绘拼图：揭示间隔';

  @override
  String get flowNonEnglishCharacterThreshold => '非英文字符过滤阈值';

  @override
  String get flowExcludeSongsWhoseShareOfJapaneseAnd =>
      '过滤日语+除空格以外的非英文字符在歌名中的占比大于等于此值的歌曲';

  @override
  String get flowRemainingSongs => '剩余歌曲';

  @override
  String get flowYouGuessedEverySong => '恭喜你猜对了所有歌曲！';

  @override
  String get flowSongsFromAllAreas => '所有区域歌曲';

  @override
  String get flowPerfectChallengeSongsFromAllAreas => '所有区域内的完美挑战曲';

  @override
  String get flowFixedTheHiddenSong => '固定，即为隐藏歌曲';

  @override
  String get flowBlueGateEntrance => '青门（蓝色之门）门扉';

  @override
  String get flowSkyStreetArea6 => '天空街区域6';

  @override
  String get flowWhiteGateEntrance => '白门门扉';

  @override
  String get flowHeavenArea8 => '天界区域8';

  @override
  String get flowPurpleGateEntrance => '紫门门扉';

  @override
  String get flowPurpleRoseArea10 => '紫蔷薇区域10';

  @override
  String get flowBlackGateEntrance => '黑门门扉';

  @override
  String get flowMetropolisArea9 => '大都会区域9';

  @override
  String get flowPlayAll11SongsInThePool => '完成下方曲目池内的11首歌曲（全部游玩）';

  @override
  String get flowTrackSkipIsAllowedDanCertificationAnd =>
      '可：跳过（Track Skip）/不可：段位认定和宴会场';

  @override
  String get flowYellowGateEntrance => '黄门门扉';

  @override
  String get flowRainbowArea => '七彩区域（なないろちほー）';

  @override
  String get flowAfterTheGateUpdateUseRandomSong =>
      '在门更新之后，使用随机选曲，随出一次以下曲目池中的任意一首并游玩';

  @override
  String get flowAnyDifficultyRetryingIsAllowedFavoritesCategories =>
      '（不限难度，不需要一次随出可以返回重试，可以使用收藏分类）';

  @override
  String get flowRandomSelectionInTheDepartureArea => '启程区域随机选曲';

  @override
  String get flowRandomPerfectChallengeSongMAXRAGEAndUniTas =>
      '启程区域随机完美挑战曲、MAXRAGE和UniTas';

  @override
  String get flowRedGateEntrance => '赤门（红色之门）门扉';

  @override
  String get flowSongPool => '曲目池';

  @override
  String get flowGateConditions => '门扉条件';

  @override
  String get flowNotSet3 => '（未设置）';

  @override
  String get flowKeyRequiredToChallenge => '钥匙（挑战所需的物品）';

  @override
  String get flowKALEIDXSCOPEMode => 'KALEIDXSCOPE 模式';

  @override
  String flowFirstSongP0(String p0) {
    return '第一首：$p0';
  }

  @override
  String flowSecondSongP0(String p0) {
    return '第二首：$p0';
  }

  @override
  String flowThirdSongP0(String p0) {
    return '第三首：$p0';
  }

  @override
  String get flowPerfectChallengeSong => '完美挑战曲';

  @override
  String get flowClearRewardSong => '通关解锁歌曲';

  @override
  String get flowHiddenSong => '隐藏歌曲';

  @override
  String get flowPerfectChallenge => '小P';

  @override
  String get flowGuide => '攻略';

  @override
  String get flowSongs4 => '曲目';

  @override
  String get flowBlueGate => '青の扉（蓝色之门）';

  @override
  String get flowWhiteGate => '白の扉（白色之门）';

  @override
  String get flowPurpleGate => '紫の扉（紫色之门）';

  @override
  String get flowBlackGate => '黑の扉（黑色之门）';

  @override
  String get flowYellowGate => '黄の扉（黄色之门）';

  @override
  String get flowRedGate => '赤の扉（红色之门）';

  @override
  String get flowCouldNotLoadNewGatesRefreshUsing => '新增门列表加载失败，请点击右上角刷新';

  @override
  String get flowDraw => '🤝 平局';

  @override
  String get flowJointWinners => '🤝 并列获胜';

  @override
  String get flowYouWon => '🏆 你赢了！';

  @override
  String flowP0Won(String p0) {
    return '🏆 $p0 获胜';
  }

  @override
  String get flowNoOneScoredInThisGame => '本局无人得分';

  @override
  String get flowCouldNotConnectToTheRoomCheck => '房间连接失败，请检查网络后重试';

  @override
  String flowP0IsNowTheHost(String p0) {
    return '$p0 成为了房主';
  }

  @override
  String get flowNoCoverArtAvailable => '没有可用曲绘';

  @override
  String get flowScoring => '得分机制';

  @override
  String get flowCorrectAnswer100SecondsSinceTheRound =>
      '答对得分 = 100 − 从回合开始经过的秒数，最低 10 分；答错 0 分。';

  @override
  String get flowFasterAnswersScoreHigherInstantAnswersApproach =>
      '也就是越快猜中分数越高：秒答接近 100 分，拖到最后也有 10 分保底。';

  @override
  String get flowOnlyYourBestAttemptForEachSong =>
      '同一首曲目只按你在这首上最好的一次计分，重复提交不会刷分。';

  @override
  String get flowOnlyTheFirstCorrectPlayerScoresFor =>
      '每一首曲目只给最先猜中的人计分，其余人这首拿 0 分。';

  @override
  String get flowIncorrectGuessesDoNotSubtractPoints => '猜错不扣分，不用怕猜错拖累总分。';

  @override
  String get flowLetterRevealHasSeveralSongsPerRound =>
      '开字母一回合有多首曲目，每首独立计分，单回合满分 = 曲目数 × 100。';

  @override
  String get flowColorMeanings => '颜色含义';

  @override
  String get flowYellowCloseToTheTargetBPMWithin =>
      '黄色 - 该属性与你猜的接近：BPM 相差 ±20 以内；MASTER / Re:MASTER 难度相差 ±0.4 以内；版本相差一个世代（maimai ← maimai PLUS → maimai GreeN）。';

  @override
  String get flowGrayFarFromTheTarget => '灰色 - 该属性与你猜的差距较大。';

  @override
  String get flowArrows2 => '箭头';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor2 =>
      '显示你猜的曲目在 MASTER 难度下的配置、难度和评价标签。';

  @override
  String get flowAMatchingTargetTagTurnsGreen => '当某个标签与目标曲目一致时，该标签会变绿。';

  @override
  String get flowSomeSongsMayNotHaveTags2 => '注意：有些曲目可能未添加标签。';

  @override
  String get flowLetterRevealRules => '开字母玩法';

  @override
  String get flowTitlesAreMaskedWithAnyoneCanReveal =>
      '本回合曲名以 □ 遮蔽，每人可开字母逐字揭示，开出的字母全房间可见。';

  @override
  String get flowEachCharacterCanBeRevealedOnlyOnce => '同一个字母只能开一次。';

  @override
  String get flowOnceASongIsGuessedItsFull => '猜中某首后，该曲名会对全房间公开完整名称。';

  @override
  String get flowGuessingFirstMayRevealTheAnswerBut =>
      '抢先猜中可能要「送答案」，但每首只给最先猜中的人计分，先猜中仍然划算。';

  @override
  String get flowTheRoundEndsOnlyWhenEveryTitle => '把所有曲名都猜中，本回合才结束。';

  @override
  String get flowRoomRules => '房间规则';

  @override
  String get flowRemainingGuessesAreSharedByTheWhole =>
      '剩余猜测次数是全房间共享的，谁先猜都消耗同一个池子，用完本回合即结束。';

  @override
  String get flowAfterSurrenderingYouCannotScoreOrSubmit =>
      '投降后本回合不再计分，也无法再提交猜测；但仍可围观其他人继续。';

  @override
  String get flowWinning => '胜负判定';

  @override
  String get flowTheHighestTotalScoreAfterAllRounds => '全部回合结束后，总分最高的人获胜。';

  @override
  String get flowEqualScoresShareTheWinIfNo => '同分则并列获胜；全场无人得分时算平局。';

  @override
  String get flowScoresAreSettledAtTheEndOf => '分数在每回合结束时结算，排行榜显示的就是结算后的总分。';

  @override
  String get flowNoTimeLimit => '不限时';

  @override
  String get flowTimeIsUp => '时间到';

  @override
  String get flowAlmostOutOfTime => '快没时间了！';

  @override
  String get flowPlentyOfTime => '还很充裕';

  @override
  String get flowAliasClue => '别名提示';

  @override
  String get flowReplayExcerptAudioPreparing => '复播片段（音频准备中）';

  @override
  String flowReplayExcerptP0ReplaysLeft(String p0) {
    return '复播片段（还可复播 $p0 次）';
  }

  @override
  String get flowAnswerUnlimitedReplaysChartOnlyAudioUnavailable =>
      '本局答案：片段可无限复播（音频不可用，仅有谱面）';

  @override
  String get flowAnswerUnlimitedReplaysWithAudio => '本局答案：片段可无限复播，带音频';

  @override
  String get flowAnswerUnlimitedReplaysPreparingAudio =>
      '本局答案：片段可无限复播（正在准备音频…）';

  @override
  String get flowPlaybackStopsAutomaticallyAtTheEndOf => '片段播完会自动停在结尾';

  @override
  String get flowThisChartIsNotCachedOnThis => '本机没有该曲的谱面缓存，自动拉取也没拿到';

  @override
  String get flowNoChartForThisSongMatchesThe => '这首曲没有符合难度池 / 定数范围的谱面';

  @override
  String flowCouldNotReadInoteP0ForThis(String p0) {
    return '未能读取该曲 inote_$p0 谱面';
  }

  @override
  String get flowCouldNotPlayChartExcerptPleaseRetry => '谱面片段播放失败，请重试';

  @override
  String get flowInvalidSongID => '歌曲编号无效';

  @override
  String get flowCouldNotFetchAudioTryAgainLater => '未能获取音频，请稍后重试';

  @override
  String get flowLeavingRoom => '正在退出房间…';

  @override
  String get flowRoomDoesNotExistOrCannotBe => '房间不存在或无法加入';

  @override
  String get flow2Players => '2 人';

  @override
  String get flow3Players => '3 人';

  @override
  String get flow4Players => '4 人';

  @override
  String get flow5Players => '5 人';

  @override
  String get flow6Players => '6 人';

  @override
  String get flowRoomCodeCannotBeEmpty => '房间码不能为空';

  @override
  String get flowAfterCreatingARoomTheHostCan => '房主创建房间后，可在房间页面复制房间码。';

  @override
  String get flowAskYourFriendToSendTheCode => '让好友把房间码发给你，在上面粘贴就能加入。';

  @override
  String get flowCouldNotReadAutomaticInstallationSettingsPlease =>
      '无法读取自动安装设置，请重试';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettingsPlease =>
      '自动安装设置保存失败，请重试';

  @override
  String get flowCouldNotOpenInstallationSourceSettingsAllow =>
      '无法打开安装来源设置，请在系统设置中允许 ChiffonMai 安装应用';

  @override
  String get flowDownloadCancelledByUser => '用户取消下载';

  @override
  String get flowThisVersionHasNotBeenPublishedYet => '该版本尚未正式发布';

  @override
  String get flowCouldNotIdentifyASingleAPKFor => '未找到适合此设备的唯一 APK，请使用网页下载';

  @override
  String get flowReleaseAssetLacksValidAPKInformationOr =>
      '发布附件缺少有效的安装包信息或 SHA-256 校验值';

  @override
  String get flowCouldNotFetchGitHubReleaseInformation => '无法获取 GitHub 发布信息';

  @override
  String get flowFetchingAPKInformation => '正在获取安装包信息…';

  @override
  String get flowPreparingBackgroundDownload => '正在准备后台下载…';

  @override
  String get flowCouldNotStartBackgroundDownload => '无法开始后台下载';

  @override
  String get flowCouldNotStartBackgroundDownloadPleaseRetry => '无法开始后台下载，请重试';

  @override
  String get flowCouldNotReadExcerptDuration => '无法读取片段时长';

  @override
  String get flowAudioExcerptIsIncomplete => '音频片段不完整';

  @override
  String get flowAudioResponseIsNotAValidWAV => '音频响应不是有效的 WAV 文件';

  @override
  String get flowNoAliases => '无别名';

  @override
  String get flowTooLate => '猜晚了';

  @override
  String get flowTooEarly => '猜早了';

  @override
  String get flowInitializationFailed => '初始化失败';

  @override
  String get flowInitializationTimedOut => '初始化超时';

  @override
  String flowRepeatOneP0Times(String p0) {
    return '单曲循环 $p0 次';
  }

  @override
  String get flowCurrentSong => '当前曲目';

  @override
  String flowLXNSAudioFailedForP0TryingWmc(String p0) {
    return '《$p0》落雪音源失败，尝试 wmc 兜底…';
  }

  @override
  String flowNoAudioAvailableForP0Skipped(String p0) {
    return '《$p0》当前暂无可用音源，已跳过';
  }

  @override
  String get flowChiffonMaiMusicPlayer => 'ChiffonMai 随身听';

  @override
  String get flowSeveralSongsFailedToLoadAutomaticSkipping =>
      '连续多首音源都加载失败，已停止自动跳过（请检查网络后重试）';

  @override
  String flowNowPlayingP0(String p0) {
    return '正在播放：$p0';
  }

  @override
  String flowCouldNotSaveAudioP0(String p0) {
    return '音源保存失败：$p0';
  }

  @override
  String get flowInvalidAPKDirectoryRange => 'APK 目录范围无效';

  @override
  String get flowIncompleteAPKDirectoryData => 'APK 目录数据不完整';

  @override
  String get flowCouldNotReadAPKZIPDirectory => '无法读取 APK 的 ZIP 目录';

  @override
  String get flowInvalidAPKManifestSize => 'APK 清单大小无效';

  @override
  String get flowInvalidAPKManifestDirectory => 'APK 清单目录无效';

  @override
  String get flowAPKManifestDecompressedSizeMismatch => 'APK 清单解压大小不一致';

  @override
  String get flowUnsupportedAPKManifestCompression => 'APK 清单压缩格式不支持';

  @override
  String get flowIncompleteAPKManifestData => 'APK 清单数据不完整';

  @override
  String get flowAPKHasNoVersionManifest => 'APK 中没有版本清单';

  @override
  String get flowInvalidBinaryAPKManifest => 'APK 二进制清单无效';

  @override
  String get flowInvalidAPKManifestStringIndex => 'APK 清单字符串索引无效';

  @override
  String get flowInvalidAPKManifestChunk => 'APK 清单分块无效';

  @override
  String get flowInvalidAPKManifestStringTable => 'APK 清单字符串表无效';

  @override
  String get flowInvalidAPKManifestAttribute => 'APK 清单属性无效';

  @override
  String get flowAPKManifestAttributeOutOfBounds => 'APK 清单属性越界';

  @override
  String get flowAPKLacksValidVersionInformation => 'APK 缺少有效版本信息';

  @override
  String get flowAPKHasNoAppVersionInformation => 'APK 中没有应用版本信息';

  @override
  String get flowAPKManifestDataOutOfBounds => 'APK 清单数据越界';

  @override
  String get flowContentContainsDisallowedWordingEditItAnd =>
      '内容包含不合规词句，请修改后重试';

  @override
  String get flowMASTERConstantRange => 'MASTER定数范围';

  @override
  String get flowUnlimited2 => '无限制';

  @override
  String get flowEnterOneValueOrACompleteRange => '请输入单值或完整区间，如 13.7 或 13.4-14';

  @override
  String get flowConstantMustBeAFiniteNumberGreater => '定数必须是大于 0 的有限数字';

  @override
  String get flowLowerBoundCannotExceedUpperBound => '区间下限不能大于上限';

  @override
  String get flowUnknownDifficulty => '未知难度';

  @override
  String get flowUTAGECannotBeCombinedWithNormalDifficulties =>
      'UTAGE 不能与普通难度同时填写';

  @override
  String get flowChooseSaveLocation => '选择保存位置';

  @override
  String get flowPublicExportDirectoryIsNotWritableWriting =>
      '公开导出目录不可写，已拒绝写入应用私有目录';

  @override
  String flowSupportsChiffonMaiFavoritesFilesSuchAsP0(String p0) {
    return '支持 $p0 等 ChiffonMai 收藏夹文件';
  }

  @override
  String get flowCouldNotReadCoverPixels => '无法读取曲绘像素';

  @override
  String get flowCouldNotReadImageData => '无法读取图片数据';

  @override
  String get flowDateToBeUpdated => '日期待更新';

  @override
  String get flowLater => '后续';

  @override
  String get flowWaitForRetryAfterSecondsOrQuotaResetAtBefore =>
      '等待 retryAfterSeconds 或 quota.resetAt 后再重试';

  @override
  String flowRetryAfterSecondsP0S(String p0) {
    return 'retryAfterSeconds（$p0 秒）';
  }

  @override
  String flowRetryAfterP0OrP1(String p0, String p1) {
    return '等待 $p0 或 $p1 后再重试';
  }

  @override
  String get flowYourSelectionIsActiveButCouldNot =>
      '本次选择已生效，但未能保存，请再次点击所选难度重试。';

  @override
  String flowP0ReleasedTapForChanges(String p0) {
    return '$p0 已发布，点击查看更新内容';
  }

  @override
  String get flowPleaseSignIn => '请登录';

  @override
  String get flowSettingsWereNotSavedPleaseRetry => '设置未保存，请重试';

  @override
  String flowP0Count(String p0) {
    return '$p0 数量';
  }

  @override
  String get flowAllowChiffonMaiToInstallUpdates => '请允许 ChiffonMai 安装更新';

  @override
  String get flowCouldNotOpenInstaller => '无法打开安装界面';

  @override
  String get flowCouldNotOpenInstallationPermissionSettings => '无法打开安装权限设置';

  @override
  String get flowActionFailedPleaseRetry => '操作失败，请重试';

  @override
  String flowCouldNotReadCacheUsageP0(String p0) {
    return '读取缓存占用失败：$p0';
  }

  @override
  String flowCouldNotClearCacheP0(String p0) {
    return '清理缓存失败：$p0';
  }

  @override
  String get flowLeftRight => '左右反';

  @override
  String get flowUpDown => '上下反';

  @override
  String get flowBoth => '全反';

  @override
  String get flowNoMirror => '无镜像';

  @override
  String get flowNothingHereYet => '啥都木有';

  @override
  String get flowChoose015SpeedAndPitch =>
      '可选 0.1× 至 5×，速度与音高联动改变；音源不足设置时长时，按实际时长播放。';

  @override
  String get flowBPMChanges => '是否变 BPM';

  @override
  String get flowNotProvided => '未提供';

  @override
  String get flowYes => '是';

  @override
  String get flowNo2 => '否';

  @override
  String get flowBPMChangeCount => 'BPM 变化次数';

  @override
  String get flowCouldNotLoadCoverArt2 => '曲绘加载失败';

  @override
  String get flowCorrect2 => '正确';

  @override
  String get flowAccuracy => '正确率';

  @override
  String get flowAverageTime => '平均用时';

  @override
  String get flowCurrentStreak => '当前连胜';

  @override
  String get flowBestStreak => '最高连胜';

  @override
  String get flowResultOriginalAudio => '结算原声';

  @override
  String get flowOriginalAudioIsUnavailablePleaseRetry => '原声片段暂时无法播放，请重试';

  @override
  String get flowPlayOriginalAudio => '播放原声';

  @override
  String get flowTitle2 => '曲名';

  @override
  String get flowType => '类型';

  @override
  String get flowMASTERConstant => 'MASTER定数';

  @override
  String get flowMASTERChartDesigner => 'MASTER谱师';

  @override
  String get flowReMASTERConstant => 'Re:MASTER定数';

  @override
  String get flowReMASTERChartDesigner => 'Re:MASTER谱师';

  @override
  String get flowMatch => '一致';

  @override
  String get flowCloseArrowsPointToTheAnswer => '接近（箭头指向答案）';

  @override
  String get flowNoMatch => '不符';

  @override
  String flowP0SRound(String p0) {
    return '$p0 秒 / 回合';
  }

  @override
  String flowP0Rounds(String p0) {
    return '$p0 回合';
  }

  @override
  String flowP0SharedGuessesPerRound(String p0) {
    return '每回合共享 $p0 次猜测';
  }

  @override
  String get flowUnlimitedGuesses => '猜测次数不限';

  @override
  String flowConstantsP0P1(String p0, String p1) {
    return '定数 $p0 - $p1';
  }

  @override
  String get flowTemporarilyOffline => '暂时离线';

  @override
  String get flowSurrendered => '已投降';

  @override
  String get flowShareTheRoomCodeToInviteFriends => '分享房间码邀请好友';

  @override
  String get flowReady2 => '已准备';

  @override
  String get flowWaitingToBeReady => '等待准备';

  @override
  String get flowConfirmingPlayerIdentity => '正在确认玩家身份…';

  @override
  String get flowShareTheCodeAndInviteAtLeast => '分享房间码，邀请至少一位好友加入';

  @override
  String flowP0PlayersAreNotReadyYet(String p0) {
    return '还有 $p0 位玩家尚未准备就绪';
  }

  @override
  String get flowEveryoneIsReadyYouCanStart => '全员就绪，可以开始了';

  @override
  String get flowEveryoneIsReadyWaitingForTheHost => '全员就绪，等待房主开始';

  @override
  String get flowCouldNotUpdateSongLeaderboard => '单曲排行榜更新失败';

  @override
  String get flowRoute1SyncFailed => '线路1同步失败';

  @override
  String get flowCoverGuessing => '曲绘猜歌';

  @override
  String get flowBlurredCover => '模糊曲绘';

  @override
  String get flowPixelCover => '像素曲绘';

  @override
  String get flowReverseAudio => '倒放音频';

  @override
  String get flowSpeedPitch => '变速变调';

  @override
  String get flowAliasGuessing => '别名猜歌';

  @override
  String get flowFlashCover => '曲绘快闪';

  @override
  String get flowTileReveal => '曲绘拼图';

  @override
  String get flowGuessTheSongFromItsInformation => '根据歌曲信息猜歌名';

  @override
  String get flowGuessTheSongFromACoverFragment => '根据部分曲绘猜歌名';

  @override
  String get flowGuessTheSongFromABlurredCover => '根据模糊曲绘猜歌名';

  @override
  String get flowGuessTheSongFromPixelBlocksAnd => '根据像素马赛克的色块与轮廓猜歌名';

  @override
  String get flowGuessTheSongFromAReversedExcerpt => '根据倒放的歌曲片段猜歌名';

  @override
  String get flowGuessFromAnExcerptWithLinkedSpeed => '根据速度和音高联动改变的片段猜歌名';

  @override
  String get flowGuessTheSongFromAnAudioExcerpt => '根据歌曲片段猜歌名';

  @override
  String get flowGuessTheSongFromAnAlias => '根据别名猜歌名';

  @override
  String get flowGuessTheSongFromInitialLetters => '根据首字母猜歌名';

  @override
  String get flowRememberABrieflyFlashedCoverToGuess => '曲绘一闪而过，凭记忆猜歌名';

  @override
  String get flowCoverTilesAreRevealedInBatches => '曲绘被切成小块逐批揭示';

  @override
  String get flowGuessFromASilentChartExcerpt => '看无声的谱面片段猜歌名';

  @override
  String get flowAutomaticInstallationTestingRequiresAndroid12Or =>
      '自动安装测试功能需要 Android 12 及以上';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettings => '自动安装设置保存失败';

  @override
  String get flowAutomaticInstallationIsOffYouCanInstall => '已关闭自动安装，可手动安装更新';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo =>
      '更新已下载，等待 App 在后台无任务持续 8 秒后尝试自动安装';

  @override
  String get flowInstallationTaskInformationIsIncomplete => '安装任务信息不完整';

  @override
  String get flowAutomaticInstallationIsOffInstallManually => '自动安装已关闭，请手动安装更新';

  @override
  String get flowFinishActiveTasksOrPlaybackBeforeUpdating =>
      '请先结束正在进行的任务或播放后再更新';

  @override
  String get flowAllowAppsToBeInstalledFromThis => '请先允许此来源安装应用';

  @override
  String get flowInstallationTaskChangedCheckUpdateStatusAgain =>
      '安装任务已变化，请重新查看更新状态';

  @override
  String get flowCouldNotMoveTheAppToThe => '无法将应用退到后台，请稍后重试';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo2 =>
      '更新已下载，等待 App 退到后台后再尝试自动安装';

  @override
  String get flowUpdateDownloadedWaitingForTheCurrentTask =>
      '更新已下载，等待当前任务结束后再尝试自动安装';

  @override
  String get flowTheLastAutomaticInstallationDidNotFinish =>
      '上次自动安装未完成，可手动安装更新';

  @override
  String get flowCannotReadTheAPK => '安装包无法读取';

  @override
  String get flowThisAPKDoesNotMeetTheSystem => '该安装包不满足当前系统的免确认要求，请手动安装';

  @override
  String get flowCouldNotSaveInstallationTask => '无法保存安装任务';

  @override
  String get flowPreparingAutomaticUpdateInstallation => '正在准备自动安装更新…';

  @override
  String get flowAPKVerificationFailedDownloadAgain => '安装包校验失败，请重新下载';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo3 =>
      '更新已下载，等待 App 在后台无任务持续 8 秒后再安装';

  @override
  String get flowTheSystemNeedsInstallationConfirmationTapTo =>
      '系统需要你确认安装，请点按后手动安装更新';

  @override
  String get flowAutomaticInstallationDidNotFinishYouCan => '自动安装未完成，可手动安装更新';

  @override
  String get flowUpdateDownloadDirectoryUnavailable => '更新下载目录不可用';

  @override
  String get flowInvalidDownloadAddress => '下载地址无效';

  @override
  String get flowInvalidAPKVerificationInformation => '安装包校验信息无效';

  @override
  String get flowUpdateTaskChanged => '已切换更新任务';

  @override
  String get flowCouldNotRemoveThePreviousUpdateFile => '无法清理上次的更新文件';

  @override
  String get flowDownloadingInTheBackgroundYouCanKeep => '后台下载中，可继续使用 App';

  @override
  String get flowDownloadingUpdateInTheBackground => '正在后台下载更新…';

  @override
  String get flowTheAPKWasRemovedDownloadAgain => '安装包已被清理，请重新下载';

  @override
  String get flowDownloadCancelled => '下载已取消';

  @override
  String get flowWaitingForNetworkOrTheSystemTo => '等待网络或系统继续下载…';

  @override
  String get flowAutomaticInstallationCancelled => '已取消自动安装';

  @override
  String get flowCheckForUpdatesAgainBeforeDownloading => '请重新检查更新后下载';

  @override
  String get flowDownloadFailed => '下载失败';

  @override
  String get flowVerifyingAPKInTheBackground => '正在后台校验安装包…';

  @override
  String get flowAPKDownloadIsIncomplete => '安装包下载不完整';

  @override
  String get flowAPKIntegrityCheckFailed => '安装包完整性校验失败';

  @override
  String get flowUpdateDownloadFailedPleaseRetry => '更新下载失败，请重试';

  @override
  String get flowChiffonMaiUpdateDownloaded => 'ChiffonMai 更新已下载';

  @override
  String get flowChiffonMaiUpdateDownloadFailed => 'ChiffonMai 更新下载失败';

  @override
  String get flowTapToChooseInstallation => '点按后选择安装';

  @override
  String get flowTapForDetailsOrToDownloadAgain => '点按查看详情或重新下载';

  @override
  String get flowSwitchedToManualInstallation => '已改为手动安装更新';

  @override
  String get flowCouldNotPrepareUpdateInstallation => '无法准备安装更新';

  @override
  String get flowAPKInformationIsMissing => '安装包信息缺失';

  @override
  String get flowAPKIsOutsideTheUpdateCacheDirectory => '安装包不在更新缓存目录中';

  @override
  String get flowTheDownloadedFileIsNotAValid => '下载的文件不是有效 APK';

  @override
  String get flowThisAPKDoesNotBelongToChiffonMai => '安装包不属于 ChiffonMai';

  @override
  String get flowAPKVersionDoesNotMatchTheUpdate => '安装包版本与待更新版本不匹配，请使用网页下载';

  @override
  String get flowAPKSignatureMismatchInstallationStopped => '安装包签名不匹配，已停止安装';

  @override
  String get flowChiffonMaiCrashed => 'ChiffonMai 崩溃了';

  @override
  String get flowLogsWillBeExportedWhenYouReopen => '重新打开后会自动导出日志';

  @override
  String get flowAppCrash => '应用崩溃';

  @override
  String get flowNativeCrash => '原生崩溃';

  @override
  String get flowAppNotResponding => '应用无响应';

  @override
  String get flowCrashAlerts => '崩溃提醒';

  @override
  String get flowOpenTheAppToRefreshData => '打开 App 刷新数据';

  @override
  String get flowUpdatesAutomaticallyWhenOnline => '联网后自动更新';

  @override
  String get flowOpenTheAppToUpdate => '打开 App 更新';

  @override
  String get flowImageExports => '图片导出';

  @override
  String get flowCouldNotReadSystemWallpaperColors => '无法读取系统壁纸配色';

  @override
  String get flowMusicPlayback => '随身听播放';

  @override
  String get flowShowsTheCurrentSongAndPlaybackControls => '显示正在播放的曲目与播放控制';

  @override
  String get flowMusicPlayerPlaying => '随身听 · 正在播放';

  @override
  String get flowMusicPlayerPaused => '随身听 · 已暂停';

  @override
  String get flowSyncNow => '立即同步';

  @override
  String get flowRecognizeScore => '识别成绩';

  @override
  String get flowMaimaiStatus => '舞萌状态';

  @override
  String get flowPlayPause => '播放/暂停';

  @override
  String get flowMaimaiStatusAndSync => '舞萌状态与同步';

  @override
  String get flowChiffonMaiOverview => 'ChiffonMai 概览';

  @override
  String get flowChiffonMaiDetails => 'ChiffonMai 详情';

  @override
  String get flowShowsYourRating => '显示你的 Rating';

  @override
  String get flowShowsMaimaiStatusAndAutomaticSync => '显示舞萌状态和自动同步';

  @override
  String get flowRatingMaimaiStatusAndAutomaticSync => 'Rating、舞萌状态和自动同步';

  @override
  String get flowAddsSourceSyncResultsAndQuickActions => '加上各数据源的同步结果和快捷入口';

  @override
  String flowChiffonMaiVP0Update(String p0) {
    return 'ChiffonMai v$p0 更新';
  }

  @override
  String flowAutomaticInstallationDidNotFinishP0You(String p0) {
    return '自动安装未完成：$p0，可手动安装';
  }

  @override
  String flowP0P1Healthy(String p0, String p1) {
    return '$p0/$p1 正常';
  }

  @override
  String flowTodayP0(String p0) {
    return '今天 $p0';
  }

  @override
  String flowP0P1P22(String p0, String p1, String p2) {
    return '$p0月$p1日 $p2';
  }

  @override
  String flowUpdatedP03(String p0) {
    return '$p0 更新';
  }

  @override
  String get flowImageSavedTapToReturnToChiffonMai => '图片已保存，点按回到 ChiffonMai';

  @override
  String get flowNotSupportedByTheSystemRightNow => '系统暂不支持';

  @override
  String get svcCheckInIsUnavailableRightNowIt => '签到暂时不可用，下次启动会自动重试';

  @override
  String get svcCouldNotReadGrowthRecordsItWill => '成长记录暂时无法读取，下次启动会自动重试';

  @override
  String get svcCheckedInToday => '今日已签到';

  @override
  String get svcSignInToCheckInAndEarn => '登录账号后，每天首次启动可签到领经验';

  @override
  String get svcNoGrowthRecordsYetYouWillBe => '还没有成长记录，下次启动时会自动签到';

  @override
  String get svcCheckingIn => '正在签到…';

  @override
  String get svcCheckInAccountDoesNotMatch => '签到账号不匹配';

  @override
  String svcCheckedInTodayP0EXP(String p0) {
    return '今日签到 +$p0 经验';
  }

  @override
  String get svcSavedOnThisDeviceOnlySyncsAfter => '仅本机保存 · 登录水鱼后自动同步';

  @override
  String get svcSavedOnThisDeviceOnlySignIn => '仅本机保存 · 请先登录并刷新落雪账号';

  @override
  String get svcSavedOnThisDeviceOnlyEnterThe => '仅本机保存 · 请先填写 AWMC 账号的 QQ 号';

  @override
  String get svcLoadingCommunityAppearance => '正在读取社区装扮';

  @override
  String get svcAppearanceWaitingToSync => '装扮待同步';

  @override
  String get svcAppearanceWaitingToSyncSignInOr => '装扮待同步 · 请登录或验证对应账号后重试';

  @override
  String get svcAppearanceWaitingToSyncTapToRetry => '装扮待同步 · 点击重试';

  @override
  String get svcSavedOnThisDeviceOnlySignIn2 => '仅本机保存 · 请先登录或验证对应账号';

  @override
  String get svcSyncingCommunityAppearance => '正在同步社区装扮';

  @override
  String get svcCommunityAppearanceSynced => '社区装扮已同步';

  @override
  String get svcAppearanceWaitingToSyncTheServerHas => '装扮待同步 · 服务端尚未确认所选装扮';

  @override
  String get svcCouldNotGetTheAPKVersionsPublished => '无法获取 GitHub 已发布的 APK 版本';

  @override
  String get svcCouldNotReadTheActualVersionOf => '无法读取 GitHub APK 的实际版本，请稍后重试';

  @override
  String get svcTheAppOrVersionOfTheGitHub => 'GitHub APK 的应用或版本与发布信息不一致';

  @override
  String get svcExperienceImprovements => '优化体验';

  @override
  String get svcNetworkConnectionFailedCheckYourNetworkAnd => '网络连接失败，请检查网络后重试';

  @override
  String svcUpdateCheckFailedP0(String p0) {
    return '检查更新失败：$p0';
  }

  @override
  String get svcSwitchRoutesAutomatically => '自动切换线路';

  @override
  String get svcTriesTheMirrorRoutesThenTheOfficial => '依次尝试加速线路与官方直连';

  @override
  String get svcCommonMirrorRoute => '常用加速线路';

  @override
  String get svcBackupMirrorRoute => '备用加速线路';

  @override
  String get svcGitHubDirect => 'GitHub 直连';

  @override
  String get svcDownloadDirectlyFromGitHub => '直接从 GitHub 官方下载';

  @override
  String get svcQRCodeEntryCancelled => '已取消输入二维码';

  @override
  String svcReasonP0TheLogWasExportedAutomatically(String p0) {
    return '原因：$p0。日志已自动导出为';
  }

  @override
  String get gainRouteStable => '稳妥吃分';

  @override
  String get gainRouteChallenge => '挑战突破';

  @override
  String get gainRouteExplore => '探索';

  @override
  String get svcIncorrectUsernameOrPasswordCheckAndTry => '用户名或密码错误，请检查后重试';

  @override
  String get svcTooManySignInAttemptsTryAgain => '登录请求过于频繁，请稍后再试';

  @override
  String get svcTheDivingFishSignInServiceIs => '水鱼登录服务暂时不可用，请稍后再试';

  @override
  String get svcTheDivingFishSignInServiceReturned => '水鱼登录接口返回异常，请稍后再试';

  @override
  String get svcSignedInButNoSessionWasCreated => '登录成功但未建立会话，请稍后再试';

  @override
  String get svcSignedInButCouldNotGetThe => '登录成功但无法获取账号资料，请稍后再试';

  @override
  String get svcSignedInButNoImportTokenWasReturned =>
      '登录成功但未获取到 ImportToken，请前往水鱼官网轮换并保存';

  @override
  String get svcSignedInButNoLinkedQQNumber => '登录成功但未获取到绑定QQ号，请前往水鱼官网填入并保存';

  @override
  String get svcASyncIsAlreadyInProgressTry => '同步已在进行中，请稍后重试';

  @override
  String get svcTheQRCodeIsInvalidOrHas => '二维码无效或已过期，请重新扫描';

  @override
  String get svcMaimaiScoreHubReturnedAnUnexpectedResponse =>
      'maimai Score Hub 响应异常——缺少 token 或 friendCode，请稍后重试';

  @override
  String get svcCouldNotCreateTheFetchTaskTry => '创建抓取任务失败，请稍后重试';

  @override
  String get svcCouldNotCreateTheFriendRequestTry => '创建好友请求失败，请稍后重试';

  @override
  String get svcMaimaiScoreHubDidNotReturnA => 'maimai Score Hub 未返回好友请求任务 ID';

  @override
  String get svcFriendRequestTimedOutAcceptTheRequest =>
      '好友请求超时——请在 NET / 机台上通过好友申请后重试';

  @override
  String get svcFriendRequestFailed => '好友请求失败';

  @override
  String get svcMaimaiScoreHubDidNotReturnA2 => 'maimai Score Hub 未返回任务 ID';

  @override
  String svcSyncTimedOutFetchingScoresTookMore(String p0) {
    return '同步超时——成绩抓取耗时超过 $p0 分钟，可能是 Bot 好友申请未被通过。请在 NET 上确认好友申请后重试。';
  }

  @override
  String get svcCouldNotCheckTheTaskStatusCheck => '查询任务状态失败，请检查网络后重试';

  @override
  String get svcTaskFailed => '任务失败';

  @override
  String get svcScoresWereFetchedButSyncingToDiving =>
      '成绩抓取成功，但同步水鱼失败。可稍后手动重试导出。';

  @override
  String svcDivingFishExportFailedP0(String p0) {
    return '水鱼导出失败：$p0';
  }

  @override
  String svcSyncErrorP0(String p0) {
    return '同步异常：$p0';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub =>
      '尚未登录 maimai Score Hub，请先完成登录后再使用线路2同步';

  @override
  String get svcCouldNotSubmitTheQRCodeCheck => '提交二维码失败，请检查网络后重试';

  @override
  String svcSyncTimedOutFetchingScoresTookMore2(String p0) {
    return '同步超时——成绩抓取耗时超过 $p0 分钟，请稍后重试';
  }

  @override
  String get svcCouldNotSetTheLXNSAPIKey => '落雪 API 密钥设置失败，请检查网络后重试';

  @override
  String svcSyncTimedOutFetchingCabinetScoresTook(String p0) {
    return '同步超时——机台成绩抓取耗时超过 $p0 分钟';
  }

  @override
  String get svcScoresWereFetchedButSyncingToLXNS =>
      '成绩抓取成功，但同步落雪失败。可稍后手动重试导出。';

  @override
  String svcLXNSExportFailedP0(String p0) {
    return '落雪导出失败：$p0';
  }

  @override
  String get svcQueueStatisticsAreUnavailableTryAgainLater => '队列统计暂不可用，请稍后重试';

  @override
  String get svcCouldNotReadTheAutoSyncSettings => '自动同步设置读取失败，请保留本机数据后重试';

  @override
  String get svcCouldNotReadTheAutoSyncCredentials => '自动同步凭据读取失败，请保留本机数据后重试';

  @override
  String get svcTheAutoSyncServiceIsUnavailableCheck =>
      '自动同步服务暂不可用，请检查网络后重试；设置状态尚未确认';

  @override
  String get svcSyncedButTheLocalDataRefreshDid => '同步成功，本地数据刷新未完成，请手动刷新';

  @override
  String get svcPersonalKeySavedOnThisDeviceThe => '个人 key 已保存在本机，定时任务待更新';

  @override
  String get svcTheAccountChangedTurnOffAutoSync => '账号已切换，请先关闭旧账号自动同步后重新开启';

  @override
  String get svcSaveThePersonalKeyForThisData => '请重新保存该数据源的个人 key';

  @override
  String svcPersonalKeySavedOnThisDeviceThe2(String p0) {
    return '个人 key 已保存在本机，定时任务待更新：$p0';
  }

  @override
  String get svcCheckYourNetworkAndTryAgain => '请检查网络后重试';

  @override
  String get svcEnterThePersonalKey => '请输入个人 key';

  @override
  String get svcPersonalKeySaved => '个人 key 已保存';

  @override
  String get svcPersonalKeySavedAndTheScheduledTask => '个人 key 已保存，并已更新定时任务';

  @override
  String get svcPersonalKeySavedAutoSyncStaysOff => '个人 key 已保存，自动同步保持关闭';

  @override
  String get svcPersonalKeyCleared => '个人 key 已清除';

  @override
  String get svcPersonalKeyClearedAndTheMatchingAuto => '个人 key 已清除，并已关闭对应自动同步';

  @override
  String get svcCouldNotVerifyTheTargetAccountScores =>
      '目标账号成绩或同步凭据校验失败，请检查该数据源的账号状态';

  @override
  String get svcAnAutoSyncTaskAlreadyExistsTrying => '已有自动同步任务，正在尝试恢复当前用户的管理权限';

  @override
  String get svcNoMatchingAutoSyncTaskWasFound => '没有找到匹配的自动同步任务，请重新开启';

  @override
  String get svcTheTaskIsRunningRestoreManagementAccess => '任务正在执行中，请稍后再恢复管理权限';

  @override
  String get svcTheAccountLinkedToTheTaskChanged => '任务绑定的账号已变化，请先关闭自动同步再重新开启';

  @override
  String get svcQuickSyncCredentialsAreIncompleteEnterA =>
      '快速同步凭据不完整，请先输入二维码绑定机台身份';

  @override
  String get svcTooManyRequestsTryAgainLater => '操作过于频繁，请稍后重试';

  @override
  String get svcCouldNotReadTheSongLibraryOf => '目标数据源曲库读取失败，本次未继续同步';

  @override
  String get svcScoreUploadFailedSomeBatchesMayHave =>
      '成绩上传失败，部分批次可能已提交；本次不自动重试';

  @override
  String get svcTheAWMCNETImportTokenIsInvalid =>
      'AWMC NET 的 Import-Token 无效，请在成绩导入凭据重新保存有效 Token，已开启的定时任务会自动更新';

  @override
  String get svcCouldNotReadCabinetScoresTryAgain => '机台成绩读取失败，请稍后重试';

  @override
  String get svcTheUpstreamReturnedPagedScoresReadingStopped =>
      '上游返回了分页成绩，本轮已停止读取，避免连续请求';

  @override
  String get svcNoValidScoresSupportedByTheTarget => '未读取到目标数据源支持的有效成绩';

  @override
  String get svcAServiceRestartInterruptedTheLastSync =>
      '服务重启中断了上次同步，将在下次定时时间继续';

  @override
  String get svcTheAutoSyncSettingChangedRefreshThe => '自动同步设置已变化，请刷新状态';

  @override
  String get svcThisSyncTimedOutAndStoppedIt => '本次同步处理超时，已停止并将在下次定时时间继续';

  @override
  String get svcAutoSyncCapacityIsFullTurnIt => '当前自动同步容量已满，请稍后再开启';

  @override
  String get svcTheUpstreamQuotaCannotBeConfirmedOr =>
      '上游配额暂不可确认或已用尽，任务会在恢复后继续';

  @override
  String get svcTheUpstreamServiceIsUnavailableTheTask =>
      '上游服务暂不可用，任务已暂停，恢复后继续';

  @override
  String get svcThisMorningSProcessingWindowHasEnded => '本次上午处理窗口已结束，将在下一轮继续';

  @override
  String get svcTheUploadResultIsUncertainTheNext => '上传结果暂不确定，下一轮会先核对后处理';

  @override
  String get svcTheAutoSyncServiceIsUnavailableTry => '自动同步服务暂不可用，请稍后重试';

  @override
  String svcSetUpTheSyncCredentialsForP0(String p0) {
    return '请先在「成绩导入凭据」设置$p0的成绩导入 Token';
  }

  @override
  String svcSetUpYourP0AccountFirst(String p0) {
    return '请先设置$p0账号';
  }

  @override
  String svcRefreshYourP0AccountDataBeforeUsing(String p0) {
    return '请先刷新$p0账号的数据，再使用快速同步';
  }

  @override
  String get svcAWMCReportedSuccessWithoutAUserIdThe =>
      'AWMC 返回成功但没有 userId，未缓存机台身份';

  @override
  String get svcQuickSyncIsInProgressPleaseWait => '快速同步正在进行中，请稍候';

  @override
  String get svcUserCredentialsAreNotCachedEnterA => '用户凭据未缓存，请先输入二维码绑定机台身份';

  @override
  String get svcUpdateTheSongLibraryBeforeUsingQuick => '请先更新曲库，再使用快速同步';

  @override
  String get svcNoValidScoresMatchedTheLocalSong => '有效成绩未匹配到本地曲库，未上传任何数据';

  @override
  String svcTheAWMCGatewayIsUnavailableP0(String p0) {
    return 'AWMC 网关暂不可用：$p0';
  }

  @override
  String get svcScorePagingWasAbnormalTheUpdateStopped => '成绩分页异常，已终止更新';

  @override
  String get svcTheServerDoesNotOfferQuickSync => '服务端尚未开放快速同步接口，请更新服务端代理';

  @override
  String get svcTheCurrentGatewayUpstreamCannotReadWithout =>
      '当前网关上游不支持免二维码读取，请使用普通同步';

  @override
  String svcQuickReadFailedP0(String p0) {
    return '快速读取失败：$p0';
  }

  @override
  String get svcTheAWMCGatewayReturnedAnInvalidScore => 'AWMC 网关返回了无效的成绩分页游标';

  @override
  String get svcTheAWMCGatewayReturnedPagedResultsReading =>
      'AWMC 网关返回了分页结果，本次已停止读取，避免连续请求';

  @override
  String get svcNoValidScoresWereReadNothingWas => '没有读取到有效成绩，未上传任何数据';

  @override
  String svcCouldNotReadTheP0SongLibrary(String p0) {
    return '$p0曲库读取失败，未上传成绩';
  }

  @override
  String svcTheP0SongLibraryIsEmptyNo(String p0) {
    return '$p0曲库为空，未上传成绩';
  }

  @override
  String svcCouldNotReadExistingP0ScoresSo(String p0) {
    return '$p0现有成绩读取失败，未进行快速同步，请先检查该源的账号状态';
  }

  @override
  String svcP0ReturnedScoresInAnInvalidFormat(String p0) {
    return '$p0返回的成绩格式无效，未进行快速同步';
  }

  @override
  String svcP0ScoresAreMissingChartOrCombo(String p0) {
    return '$p0成绩缺少谱面或连击同步字段，未进行快速同步';
  }

  @override
  String svcUploadToP0FailedHTTPP1Remaining(String p0, String p1) {
    return '$p0上传未成功（HTTP $p1），已停止后续批次；已提交批次可能已生效';
  }

  @override
  String get svcThereAreNoFavoriteFoldersToExport => '没有可导出的收藏夹';

  @override
  String get svcChooseAChiffonMaiFavoritesFile => '选择 ChiffonMai 收藏夹文件';

  @override
  String get svcCouldNotReadTheSelectedFile => '无法读取所选文件';

  @override
  String svcFileNotFoundP0(String p0) {
    return '文件不存在：$p0';
  }

  @override
  String svcTheFavoritesFileIsTooLargeLimit(String p0) {
    return '收藏夹文件过大（上限 $p0 MB）';
  }

  @override
  String get svcThisFileIsNotInTheChiffonMai =>
      '这个文件不是 ChiffonMai 收藏夹格式。\n（旧版导出的 .txt 纯文本清单不含歌曲 ID，无法还原成收藏夹，请重新导出一次）';

  @override
  String get svcTheFileIsNotValidJSONAnd => '文件内容不是合法的 JSON，可能已损坏';

  @override
  String svcTheFileFormatTagIsP0Not(String p0) {
    return '文件格式标识为 \"$p0\"，不是 ChiffonMai 收藏夹文件';
  }

  @override
  String get svcTheFileContentCouldNotBeRecognized => '文件内容无法识别';

  @override
  String get svcTheFileHasNoFavoritesData => '文件里没有任何收藏夹数据';

  @override
  String get svcTheFileIsMissingTheFoldersField => '文件缺少 folders 字段';

  @override
  String get svcTheFileIsEmpty => '文件是空的';

  @override
  String get svcTheBackupExceedsThe50MBLimit => '备份超过 50 MB 上限，请精简自定义谱面归档后重试';

  @override
  String svcTheBackupFileIsTooLargeLimit(String p0) {
    return '备份文件过大（上限 $p0 MB）';
  }

  @override
  String get svcInvalidBackupFileMissingTheDataField => '无效的备份文件：缺少 data 字段';

  @override
  String get svcInvalidBackupFileMissingTheVersionField =>
      '无效的备份文件：缺少 version 字段';

  @override
  String get svcUnsupportedBackupVersionOrAppFormat => '不支持的备份版本或应用格式';

  @override
  String get svcTheBackupFileIsEmptyThereIs => '备份文件为空，无数据可恢复';

  @override
  String get svcADataRestoreIsAlreadyInProgress => '已有数据恢复正在进行';

  @override
  String get svcSecureCredentialsHaveNotFinishedMigratingTry =>
      '安全凭据尚未完成迁移，请稍后重试恢复';

  @override
  String get svcCouldNotClearTheOldSettings => '清空旧设置失败';

  @override
  String svcCouldNotWriteTheBackupSettingP0(String p0) {
    return '写入备份设置失败：$p0';
  }

  @override
  String get svcTheBackupHasNoUserSettingsTo => '备份没有可恢复的用户设置，已保留当前数据';

  @override
  String get svcSignInAndLinkYourDivingFish => '请先登录并绑定水鱼 QQ';

  @override
  String get svcTheCurrentDivingFishUserHasNo => '当前水鱼用户无游玩数据，请先刷新数据';

  @override
  String get svcNoPlayDataWasFoundForThis => '未找到该好友的游玩数据，请检查 QQ 号是否正确';

  @override
  String get svcAddYourAWMCNETQQNumberIn => '请先在「绑定与授权管理」里绑定 AWMC NET 的 QQ';

  @override
  String get svcSignInToYourLXNSAccountFirst => '请先登录落雪账号';

  @override
  String get svcCouldNotReadYourLXNSScoresTry => '读取你的落雪成绩失败，请稍后重试';

  @override
  String get svcTheSongLibraryHasNotLoadedYet => '曲库还没有加载好，请稍后重试';

  @override
  String get svcTheFriendCodeMustContainOnlyDigits => '好友码只能是数字，请检查后重试';

  @override
  String svcCouldNotLookUpTheFriendS(String p0) {
    return '查询好友成绩失败（HTTP $p0）';
  }

  @override
  String get svcNoLXNSScoresForThisFriendThey =>
      '没有这位好友的落雪成绩，好友需要在 ChiffonMai 参与排行榜并刷新过数据';

  @override
  String get svcChooseAtLeastOneResultScreenImage => '请先选择至少一张结算画面图片';

  @override
  String svcUpToP0ImagesCanBeRecognized(String p0, String p1) {
    return '一次最多识别 $p0 张，当前选了 $p1 张';
  }

  @override
  String svcP0ExceedsThe8MiBLimitP1(String p0, String p1) {
    return '$p0 超过 8 MiB 上限（$p1 MiB）';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub2 =>
      '未登录 maimai Score Hub，无法使用该识别服务';

  @override
  String svcNoImagesOrTooManyImagesP0(String p0) {
    return '图片为空或数量超限$p0';
  }

  @override
  String get svcYourSignInHasExpiredSignIn => '登录状态已失效，请重新登录 maimai Score Hub';

  @override
  String get svcAnImageExceedsThe8MiBLimit => '有图片超过 8 MiB 上限';

  @override
  String get svcUnsupportedImageFormatOnlyJPEGPNGWebP =>
      '图片格式不支持（仅支持 JPEG / PNG / WebP）';

  @override
  String get svcTheOCRServiceReturnedAResultThat => 'OCR 服务返回了无法解析的结果';

  @override
  String get svcTheOCRServiceIsUnavailableTryAgain => 'OCR 服务暂时不可用，请稍后再试';

  @override
  String get svcOCRRecognitionTimedOutTryAgainLater => 'OCR 识别超时，请稍后再试';

  @override
  String svcRecognitionFailedHTTPP0P1(String p0, String p1) {
    return '识别失败（HTTP $p0）$p1';
  }

  @override
  String get svcAccountDataIsUpdatingTryAgainWhen => '账号数据正在更新，请完成后重试';

  @override
  String get svcCouldNotSaveAccountRecoveryInformation => '无法保存账号恢复信息';

  @override
  String get svcTheAccountChangedSoTheDataRefresh => '账号已切换，已跳过本次同步后的数据刷新';

  @override
  String get svcTheReturnedDataBelongsToAnotherAccount =>
      '返回的数据属于其他账号，已取消本次自动刷新';

  @override
  String get svcCouldNotRollBackTheAccountArchive => '账号存档回滚失败';

  @override
  String get svcCouldNotIdentifyTheAccountToRestore => '无法识别待恢复的账号';

  @override
  String get svcCouldNotSaveHistoryMigrationInformation => '无法保存历史迁移信息';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit =>
      '用户文件超过备份容量上限，请先精简自定义谱面归档后重试';

  @override
  String get svcTheUserFilesInTheBackupHave => '备份的用户文件格式无效';

  @override
  String get svcInvalidUserFileEntry => '用户文件条目无效';

  @override
  String get svcInvalidUserFilePath => '用户文件路径无效';

  @override
  String get svcInvalidUserFileContent => '用户文件内容无效';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit2 => '用户文件超过备份容量上限';

  @override
  String get svcTheUserFileFolderCannotBeA => '用户文件目录不能是符号链接';

  @override
  String get svcUserFilesCannotBeSymbolicLinks => '用户文件不能是符号链接';

  @override
  String get svcCouldNotWriteTheAccountArchive => '账号存档写入失败';

  @override
  String get svcTheAccountArchiveHasAnInvalidFormat => '账号存档格式无效';

  @override
  String get svcCouldNotRestoreTheAccountArchive => '账号存档恢复失败';

  @override
  String svcRefreshTheTargetP0AccountSData(String p0) {
    return '请先刷新$p0目标账号的数据，以保留该账号的连击与同步标记';
  }

  @override
  String svcTheP0ScoreCacheIsInvalidRefresh(String p0) {
    return '$p0成绩缓存无效，请先刷新数据';
  }

  @override
  String svcLoadedP0FromTheLocalCache(String p0) {
    return '已从本地缓存读取$p0';
  }

  @override
  String get svcAudio => '音频';

  @override
  String get svcAudioFile => '音频文件';

  @override
  String svcDownloadingP0(String p0) {
    return '正在下载$p0…';
  }

  @override
  String get svcTheResponseIsNotAMediaFile => '响应不是媒体文件';

  @override
  String get svcTheMediaFileIsIncompleteOrHas => '媒体文件不完整或格式无效';

  @override
  String get svcFileCached => '文件已缓存';

  @override
  String svcMediaDownloadFailedP0(String p0) {
    return '媒体下载失败：$p0';
  }

  @override
  String svcP0AddedP1UpdatedP2SkippedP3(
      String p0, String p1, String p2, String p3) {
    return '新增 $p0 条 · 更新 $p1 条 · 跳过 $p2 条（机台共 $p3 条）';
  }

  @override
  String get svcTheAWMCNETScoreImportTokenHas => '还没有设置 AWMC NET 成绩导入 Token';

  @override
  String get svcPasteOrScanTheCabinetSignIn => '请先粘贴或扫描机台登入二维码';

  @override
  String svcRefusedARequestToANonAWMC(String p0) {
    return '拒绝请求非 AWMC NET 地址：$p0';
  }

  @override
  String svcImportTimedOutAfterP0SecondsLarge(String p0) {
    return '导入超时（已等待 $p0 秒）。机台数据量大时会更久，请稍后重试';
  }

  @override
  String svcCouldNotConnectToAWMCNETP0(String p0) {
    return '连接 AWMC NET 失败：$p0';
  }

  @override
  String get svcAWMCNETReturnedUnrecognizedData => 'AWMC NET 返回了无法识别的数据';

  @override
  String svcCouldNotParseTheAWMCNETResponse(String p0) {
    return '解析 AWMC NET 返回失败：$p0';
  }

  @override
  String get svcTheAWMCNETImportTokenIsInvalid2 =>
      'AWMC NET 导入 Token 无效，请到 net.wmc.pub 设置页最底部重新生成';

  @override
  String get svcTheAWMCNETImportTokenIsMissing => '缺少 AWMC NET 导入 Token';

  @override
  String get svcTheCabinetQRCodeIsInvalidOr => '机台二维码无效或已过期，请重新在公众号/机台获取后重试';

  @override
  String svcAWMCNETRejectedTheRequestP0(String p0) {
    return 'AWMC NET 拒绝了请求：$p0';
  }

  @override
  String get svcInvalidParameters => '参数不合法';

  @override
  String svcTooManyAWMCNETRequestsTryAgain(String p0) {
    return 'AWMC NET 请求过于频繁，请稍后再试\n$p0';
  }

  @override
  String svcAWMCNETChimeUserReadFailed(String p0) {
    return '机台成绩读取失败：Chime 获取用户失败（业务码 3002，HTTP $p0）。请使用新二维码重试；若仍失败，请稍后再试，或使用已绑定机台身份的快速同步。';
  }

  @override
  String svcAWMCNETServerErrorHTTPP0Try(String p0) {
    return 'AWMC NET 服务端异常（HTTP $p0），请稍后重试';
  }

  @override
  String svcAWMCNETReturnedHTTPP0(String p0) {
    return 'AWMC NET 返回 HTTP $p0';
  }

  @override
  String get svcNoDivingFishImportTokenYetSign => '还没有水鱼 Import-Token，请先登录水鱼账号';

  @override
  String svcCouldNotConnectToDivingFishP0(String p0) {
    return '无法连接水鱼查分器：$p0';
  }

  @override
  String get svcTheImportTokenIsWrongOrThe => '导入 Token 有误或请求格式不对';

  @override
  String get svcYourSignInIsInvalidSignIn => '登录状态无效，请重新登录水鱼';

  @override
  String svcSyncFailedHTTPP0P1(String p0, String p1) {
    return '同步失败（HTTP $p0）$p1';
  }

  @override
  String get svcDivingFishDidNotAcceptThisScore =>
      '水鱼没有接受这条成绩（歌曲没匹配上，或难度索引对该歌曲不存在），请检查曲名和难度';

  @override
  String get svcUTAGEChartsCannotBeSyncedLXNSDifficulty =>
      '宴会场谱面不支持同步：落雪的难度索引体系与宴会场不通用';

  @override
  String svcDifficultyIndexP0IsOutsideTheLXNS(String p0) {
    return '难度索引 $p0 超出落雪值域（0-4）';
  }

  @override
  String get svcYourLXNSAccountIsNotAuthorizedComplete =>
      '落雪账号未认证：在「绑定与授权管理」完成 OAuth 授权，或在 OCR 页的落雪状态条里粘贴个人 API 密钥';

  @override
  String svcCouldNotConnectToLXNSP0(String p0) {
    return '无法连接落雪咖啡屋：$p0';
  }

  @override
  String get svcLXNSAuthorizationExpiredOrTheKeyIs => '落雪授权已失效或密钥无效，请重新授权或粘贴密钥';

  @override
  String get svcLXNSRejectedThisWriteInsufficientPermissions =>
      '落雪拒绝了这次写入（权限不足）';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatDataIs => '落雪返回格式异常：data 为空';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatData0 => '落雪返回格式异常：data[0] 不是对象';

  @override
  String get svcThisUserHasNotAuthorizedTheApp => '该用户尚未授权本应用，请先完成绑定后再试';

  @override
  String get svcAuthenticationFailedTryAgain => '鉴权失败，请重试';

  @override
  String get svcNoPermissionToAccessThisUserS => '无权限访问该用户数据';

  @override
  String get svcTodaySQueryLimitHasBeenReached => '今日查询次数已达上限，请稍后再试';

  @override
  String svcRequestFailedStatusCodeP0(String p0) {
    return '请求失败（状态码 $p0）';
  }

  @override
  String get svcConnectionCancelled => '连接已取消';

  @override
  String get svcDisconnectedReconnectAndTryAgain => '连接已断开，请重新连接后重试';

  @override
  String get svcDisconnectedTheCoverReadyStatusWasNot => '连接已断开，曲绘准备状态未发送';

  @override
  String get svcDisconnectedThisGuessWasNotSubmittedReconnect =>
      '连接已断开，本次猜测未提交，请连接后重试';

  @override
  String get svcDisconnectedReconnectBeforeLeavingTheRoom =>
      '连接已断开，请重新连接后再退出房间';

  @override
  String get svcEnterAQQNumber => '请输入 QQ 号';

  @override
  String svcAWMCNETQueryTimedOutP0S(String p0) {
    return 'AWMC NET 查询超时（$p0 秒），请检查网络后重试';
  }

  @override
  String svcAWMCNETConnectionFailedP0(String p0) {
    return 'AWMC NET 连接失败：$p0';
  }

  @override
  String svcAWMCNETReturnedDataThatCouldNot(String p0) {
    return 'AWMC NET 返回了无法解析的数据：$p0';
  }

  @override
  String get svcAWMCNETReturnedAnUnrecognizedDataStructure =>
      'AWMC NET 返回的数据结构无法识别（缺少 records）';

  @override
  String svcAWMCNETHasNoDataForQQ(String p0) {
    return 'AWMC NET 上没有 QQ $p0 的数据。\n请确认该 QQ 已在 net.wmc.pub 绑定并上传过成绩。';
  }

  @override
  String svcTheAWMCNETDeveloperKeyIsInvalid(String p0) {
    return 'AWMC NET 开发者密钥无效或已失效（HTTP $p0）';
  }

  @override
  String svcAWMCNETReturnedAnUnknownStatusHTTP(String p0, String p1) {
    return 'AWMC NET 返回未知状态：HTTP $p0$p1';
  }

  @override
  String svcInvalidQQNumber512DigitsExpected(String p0) {
    return 'QQ 号格式不对（应为 5–12 位数字）：$p0';
  }

  @override
  String svcAWMCNETHasNoDataForQQ2(String p0) {
    return 'AWMC NET 没有 QQ $p0 的数据（请确认该 QQ 已在 net.wmc.pub 绑定并上传过成绩）';
  }

  @override
  String get svcAWMCNETRejectedTheRequestDaysIs =>
      'AWMC NET 拒绝了请求：days 参数超出范围（1~365）';

  @override
  String svcAWMCNETReturnedJSONThatCouldNot(String p0) {
    return 'AWMC NET 返回了无法解析的 JSON：$p0';
  }

  @override
  String get svcTheAWMCNETResponseHasNoPoints => 'AWMC NET 返回结构里没有 points 数组';

  @override
  String svcP0MsOfflineMode(String p0) {
    return '${p0}ms（离线模式）';
  }

  @override
  String get svcLoadingTheSongAliasDatabase => '正在加载歌曲别名数据库...';

  @override
  String get svcInitializingTheMaidataManager => '正在初始化Maidata管理器...';

  @override
  String get svcFetchingAllMaidataTheFirstLoadMay =>
      '正在获取全量Maidata数据...\n（首次加载可能较慢，请耐心等待）';

  @override
  String get svcLoadingMaidataFromCache => '从缓存加载Maidata数据...';

  @override
  String get svcSyncingSongInfoAndDifficultyData => '正在同步歌曲信息与难度数据...';

  @override
  String get svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd =>
      '正在加载收藏品、标签、歌曲、知识库等数据...';

  @override
  String get svcBuildingSongMappings => '正在建立歌曲关联映射...';

  @override
  String get svcTheExportCanvasIsNotReady => '导出画布未就绪';

  @override
  String get svcDiscoveringBaseMaidata => '正在发现基础量 maidata…';

  @override
  String svcFetchingMaidataP0P1(String p0, String p1) {
    return '正在拉取 maidata：$p0/$p1';
  }

  @override
  String svcFoundP0MaidataFiles(String p0) {
    return '已发现 $p0 份 maidata';
  }

  @override
  String get svcTheLogWasExportedAutomaticallyYouCan => '日志已自动导出，可以发给开发者排查';

  @override
  String get svcLogExportFailedYouCanExportIt => '日志导出失败，可在「打印日志」手动导出';

  @override
  String get svcTheGatewayCouldNotReachItsOrigin =>
      '网关回源失败：CDN 返回了非法响应头的错误页（SpeedOnline），通常是网关/回源超时，稍后重试即可';

  @override
  String svcRequestFailedP0(String p0) {
    return '请求失败：$p0';
  }

  @override
  String get svcSuccess => '成功';

  @override
  String get svcTheServerHasNoAWMCDeveloperKey => '服务端尚未配置 AWMC 开发者密钥，请联系管理员';

  @override
  String get svcHTTP401TokenMissingOrInvalid => 'HTTP 401：令牌缺失或无效';

  @override
  String get svcHTTP403InsufficientBalanceRedeemTokensIn =>
      'HTTP 403：余额不足，请先在控制台兑换 Token';

  @override
  String svcHTTPP0TheGatewayOrUpstreamFailed(String p0) {
    return 'HTTP $p0：网关或上游转发失败';
  }

  @override
  String svcUsedP0Tokens(String p0) {
    return '本次消耗 $p0 Token';
  }

  @override
  String get svcTheRequestDidNotSucceedNoTokens => '业务未成功，按官方规则不扣 Token';

  @override
  String get svcCouldNotReadTheRefreshSettingsRefresh => '刷新配置读取失败，请手动刷新数据';

  @override
  String get svcTheRefreshSourceDiffersFromTheSync => '刷新来源与同步目标不同，已跳过自动刷新';

  @override
  String get svcTheRefreshAccountDiffersFromTheSync => '刷新账号与同步目标不同，已跳过自动刷新';

  @override
  String get svcTheAccountOrSyncCredentialsChangedAutomatic =>
      '账号或同步凭据已变化，已跳过自动刷新';

  @override
  String get svcCouldNotLoadTheGateListRight => '门列表暂时无法读取';

  @override
  String get svcCouldNotLoadTheGuideRightNow => '攻略暂时无法读取';

  @override
  String get svcTheGuideDataDoesNotMatch => '攻略数据不匹配';

  @override
  String get svcReadAndAcceptTheUserAgreementAnd => '请先阅读并同意用户协议和隐私政策';

  @override
  String get svcCouldNotSaveTheOnboardingConfirmationTry => '无法保存引导确认记录，请重试';

  @override
  String get svcCreatingTheRoomTimedOutCheckYour => '创建房间超时，请检查连接后重试';

  @override
  String get svcJoiningTheRoomTimedOutCheckThe => '加入房间超时，请检查房间码与网络';

  @override
  String svcCouldNotLoadReleaseDataP0(String p0) {
    return '配信数据读取失败 ($p0)';
  }

  @override
  String get svcInvalidReleaseData => '无效的配信数据';

  @override
  String get svcInvalidFriendLinkDataFormat => '友链数据格式错误';

  @override
  String get svcSaveFailed => '保存失败';

  @override
  String svcCouldNotParseTheRecognitionResultJSON(String p0) {
    return '识别结果 JSON 解析失败：$p0';
  }

  @override
  String svcRecognitionRequestFailedP0(String p0) {
    return '识别请求失败：$p0';
  }

  @override
  String get gainBelowS => '未达 S';

  @override
  String gainRaiseTo(String p0) {
    return '冲上 $p0';
  }

  @override
  String gainWithinGrade(String p0) {
    return '$p0 档内提分';
  }

  @override
  String gainBasisMember(String p0, String p1, String p2, String p3) {
    return '$p0；$p1 内单曲 RA $p2→$p3';
  }

  @override
  String gainBasisReplace(
      String p0, String p1, String p2, String p3, String p4) {
    return '$p0；RA $p1 顶替 $p2 最低《$p3》RA $p4';
  }

  @override
  String gainBasisFill(String p0, String p1, String p2) {
    return '$p0；RA $p1 补入 $p2 空位';
  }

  @override
  String gainNetGainReason(String p0, String p1) {
    return '独立净收益+$p0（$p1）';
  }

  @override
  String gainExploreReason(String p0, String p1) {
    return '个人同档最佳成绩中位参考 $p0% · 独立净收益+$p1（条件估算；不是下次成功率）';
  }

  @override
  String gainAlternativeChallenge(String p0, String p1) {
    return '；挑战可选 $p0%（独立净收益+$p1，不与稳妥目标累加）';
  }

  @override
  String gainFillNoteExhausted(String p0) {
    return '合格未见候选 $p0 条，已全部耗尽';
  }

  @override
  String gainFillNoteFiltered(String p0) {
    return '合格未见候选 $p0 条，其余被反馈/资格过滤';
  }

  @override
  String get accountAuthorizeLXNS => '落雪账号授权';

  @override
  String get accountLinkAWMC => '绑定 AWMC NET 账号';

  @override
  String get accountSwitchCachedSubtitle => '切换数据源与玩家信息，使用本地缓存';

  @override
  String get accountAuthorizeLXNSSubtitle => '管理落雪成绩读取授权';

  @override
  String get accountLinkAWMCSubtitle => '设置 AWMC NET 成绩查询 QQ';

  @override
  String get accountCabinetIdentitySubtitle => '绑定快速同步共用的机台身份';

  @override
  String get accountAuthorizeLXNSFirst => '请先在「我的 → 账号与授权 → 绑定与授权管理」完成落雪授权';

  @override
  String get accountLinkAWMCFirst => '请先在「我的 → 账号与授权 → 绑定与授权管理」绑定 AWMC NET 账号';

  @override
  String get accountConfigurationSaved => '账号配置已保存，可通过刷新数据更新成绩';

  @override
  String get accountAuthorizationFailed => '授权或保存失败，请检查网络与输入后重试';

  @override
  String get accountLXNSAuthorized => '落雪账号已授权';

  @override
  String get accountLXNSAuthorizedSubtitle => '已授权，可刷新成绩；点击可重新授权';

  @override
  String get accountAWMCLinked => 'AWMC NET 账号已绑定';

  @override
  String accountAWMCLinkedSubtitle(String qq) {
    return '已绑定 QQ：$qq；点击可更换账号';
  }

  @override
  String get accountCabinetLinkedSubtitle => '快速同步身份已保存，点击可重新绑定';

  @override
  String get accountBindingManage => '绑定与授权管理';

  @override
  String get accountBindingManageSubtitle => '登录、授权与绑定各数据源账号';

  @override
  String get accountBindingScoreHub => 'maimai Score Hub';

  @override
  String get accountBindingDivingFish => '水鱼';

  @override
  String get accountBindingLxns => '落雪';

  @override
  String get accountBindingAwmc => 'AWMC NET';

  @override
  String get accountBindingCabinet => '机台身份';

  @override
  String get accountBindingSignedIn => '已登录';

  @override
  String get accountBindingSignedOut => '未登录';

  @override
  String get accountBindingAuthorized => '已授权';

  @override
  String get accountBindingUnauthorized => '未授权';

  @override
  String get accountBindingLinked => '已绑定';

  @override
  String get accountBindingUnlinked => '未绑定';

  @override
  String get accountBindingDivingFishAuth => '水鱼授权';

  @override
  String get accountBindingUnknown => '未知';

  @override
  String get accountBindingRecheck => '重新检查';

  @override
  String get syncDialogMode => '同步方式';

  @override
  String get syncDialogQrCode => '机台二维码';

  @override
  String get languageTranslationDisclaimer =>
      '除简体中文外，其他语言的界面文案为翻译文本，可能存在不准确或不自然的表达；含义不一致时以简体中文为准。歌曲资料、服务端原文和用户内容不做翻译。发现翻译问题欢迎通过「问题反馈」告诉我们。';

  @override
  String get accountSwitchSaved => '已保存账号';

  @override
  String get accountSwitchNotSaved => '未保存账号';

  @override
  String get accountSwitchCurrent => '当前使用中';

  @override
  String get customTagTitle => '自定义标签';

  @override
  String get customTagFeatureSubtitle => '自定义标签名称、颜色与谱面，接入标签筛选与统计';

  @override
  String get customTagGroupName => '自定义';

  @override
  String get customTagIntro =>
      '自定义标签会与谱面标签一起出现在乐曲查询的标签筛选、谱面详情、Best50 / 收藏夹的标签统计和个性化 Best50 的「标签50」中。标签只保存在本机，随数据备份导出。';

  @override
  String get customTagCreate => '新建标签';

  @override
  String get customTagEdit => '编辑标签';

  @override
  String get customTagName => '标签名称';

  @override
  String get customTagColor => '标签颜色';

  @override
  String get customTagHue => '色相';

  @override
  String get customTagPreview => '预览';

  @override
  String get customTagNameRequired => '请输入标签名称';

  @override
  String get customTagNameDuplicate => '已有同名标签';

  @override
  String get customTagSaveFailed => '保存自定义标签失败，请重试';

  @override
  String get customTagForChart => '为谱面添加自定义标签';

  @override
  String get customTagEmpty => '还没有自定义标签，先新建一个吧。';

  @override
  String get customTagAddToChart => '添加自定义标签';

  @override
  String get customTagManage => '管理';

  @override
  String get customTagSearchHint => '输入歌名、别名、曲师或 ID 搜索';

  @override
  String get customTagNoSongs => '没有找到歌曲';

  @override
  String get customTagChooseDifficulties => '选择难度';

  @override
  String get customTagAddCharts => '添加谱面';

  @override
  String get customTagRemoveChart => '移出此标签';

  @override
  String get customTagDelete => '删除';

  @override
  String get customTagDeleteTitle => '删除标签';

  @override
  String customTagChartCount(int count) {
    return '$count 张谱面';
  }

  @override
  String customTagDeleteMessage(String name) {
    return '删除「$name」后，它会从所有谱面上移除，且无法恢复。';
  }

  @override
  String accountSwitchCurrentLabel(String name) {
    return '当前：$name';
  }

  @override
  String customTagMarked(String name) {
    return '$name（自定义）';
  }

  @override
  String get chartCodeFont => '代码字体';

  @override
  String get chartCodeFontDefault => '默认';

  @override
  String get chartCodeFontSaveFailed => '字体已切换，但未能保存选择';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get autoUpdateSuccessTitle => '自動更新成功';

  @override
  String get autoUpdateSuccessBody => 'ChiffonMai 已在背景完成更新，可以繼續使用囉。';

  @override
  String get autoUpdateChangesTitle => '本次更新內容';

  @override
  String get settingsTitle => '系統設定';

  @override
  String get appearance => '外觀';

  @override
  String get interaction => '互動';

  @override
  String get effects => '特效';

  @override
  String get other => '其他';

  @override
  String get language => '語言';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get languageDescription =>
      '介面、提示與系統通知均已支援多語言；歌曲資料、伺服器原文和使用者內容保持原文。切換後立即生效。';

  @override
  String get languageSaveFailed => '語言設定儲存失敗，請重試';

  @override
  String get homeSearchScope => '首頁搜尋範圍';

  @override
  String get searchFeatures => '功能';

  @override
  String get searchSongs => '歌曲';

  @override
  String get searchBoth => '功能＋歌曲';

  @override
  String get searchMode => '搜尋方式';

  @override
  String get searchInline => '原位輸入';

  @override
  String get searchOverlay => '展開搜尋';

  @override
  String get searchOverlayHint => '首頁功能與歌曲搜尋使用展開的搜尋介面（目前預設）';

  @override
  String get searchInlineHint => '直接在原搜尋框輸入，歌曲搜尋記錄顯示在搜尋框下方';

  @override
  String get showMatchInfo => '顯示符合欄位';

  @override
  String get showMatchInfoHint => '在歌曲搜尋結果中顯示符合的定數、BPM、標籤等資訊';

  @override
  String get themeMode => '主題模式';

  @override
  String get themeColor => '主題色';

  @override
  String get backgroundImage => '背景圖片';

  @override
  String get decorationImage => '裝飾圖片';

  @override
  String get pureBlackBackgroundDisabled => '純黑模式下無法調整背景與裝飾圖片';

  @override
  String get reading => '讀取中…';

  @override
  String get useSystemWallpaperColor => '使用系統桌布配色';

  @override
  String get systemWallpaperHint => '適用於 Android 12 及以上版本，點選後將目前的系統配色套用為主題色。';

  @override
  String get wallpaperColorUnsupported => '系統桌布配色需要 Android 12 或更新版本';

  @override
  String get wallpaperColorApplied => '已套用系統桌布配色';

  @override
  String get wallpaperColorFailed => '暫時無法讀取系統桌布配色，請稍後重試';

  @override
  String get wallpaperApplied => '桌布已設定';

  @override
  String get wallpaperAndThemeApplied => '桌布已設定，主題色已更新';

  @override
  String get backgroundReset => '已恢復預設背景';

  @override
  String get themeColorUpdated => '主題色已更新';

  @override
  String get themeColorReset => '已恢復預設主題色';

  @override
  String get navigationExperience => '導覽體驗';

  @override
  String get searchInteraction => '搜尋框互動';

  @override
  String get confetti => '彩紙特效';

  @override
  String get appUpdate => '應用程式更新';

  @override
  String get featureGuide => '功能導覽';

  @override
  String get featureGuideHint => '想再看一次各個功能的位置，可以隨時重新開啟。';

  @override
  String get reopenGuide => '重新檢視功能導覽';

  @override
  String get preview => '預覽效果';

  @override
  String get primaryButton => '主要按鈕';

  @override
  String get primaryColor => '主色';

  @override
  String get secondaryColor => '輔助色';

  @override
  String get tertiaryColor => '強調色';

  @override
  String get surfaceColor => '背景色';

  @override
  String get customColor => '自訂顏色';

  @override
  String get restoreDefaults => '恢復預設';

  @override
  String get builtInBackground => '目前：內建背景';

  @override
  String get customBackground => '目前：自訂圖片';

  @override
  String get processing => '處理中…';

  @override
  String get chooseFromGallery => '從相簿選擇';

  @override
  String get decorationOpacity => 'chiffon 裝飾圖片透明度';

  @override
  String get decorationOpacityHint => '預設 40%。純黑模式下自動隱藏；深淺模式共用相同透明度。';

  @override
  String get hide => '隱藏';

  @override
  String get favoriteExportExtension => '收藏夾匯出副檔名';

  @override
  String get syncAndGateway => '同步與閘道';

  @override
  String get gatewayTimeout => 'AWMC 閘道檢測逾時';

  @override
  String get gatewayTimeoutHint =>
      '線路 1 同步前會先請求 GET /v1/health 檢查連線；超過此時間就取消同步（不消耗 Token）。';

  @override
  String get gatewayTimeoutDialogHint =>
      '線路 1 同步前會先請求 GET /v1/health 檢查連線；超過此時間視為閘道無法使用，直接取消同步（不會消耗 Token）。';

  @override
  String get enterIntegerSeconds => '請輸入整數秒數';

  @override
  String get timeout => '逾時時間';

  @override
  String get secondsUnit => '秒';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get confirm => '確定';

  @override
  String get backgroundOpacity => '背景透明度';

  @override
  String get backgroundDarkHint => '數值越高背景越暗，0% 為原始背景圖片';

  @override
  String get backgroundLightHint => '數值越高背景越淡，0% 為原始背景圖片';

  @override
  String get lightMode => '淺色';

  @override
  String get darkMode => '深色';

  @override
  String get pureBlack => '純黑背景';

  @override
  String get pureBlackHint => '使用真正的純黑背景，隱藏背景圖片';

  @override
  String get navigationStyle => '導覽列樣式';

  @override
  String get navigationClassic => '經典懸浮';

  @override
  String get navigationGlass => '液態玻璃';

  @override
  String get navigationPill => '伸縮膠囊';

  @override
  String get navigationClassicHint => '圖示與文字上下排列，持續顯示所有分類名稱';

  @override
  String get navigationGlassHint => '通透的玻璃質感，選取項目帶有柔和高光';

  @override
  String get navigationPillHint => '選取項目展開文字，其餘項目保留圖示，切換時平滑伸縮';

  @override
  String get navigationAnimation => '導覽列切換動畫';

  @override
  String get navigationAnimationHint => '切換主畫面時使用淡入滑動轉場，並淡化圖示狀態';

  @override
  String get swipeNavigation => '左右滑動切換主畫面';

  @override
  String get swipeNavigationHint => '在主畫面內容區域左右滑動即可切換底部導覽項目';

  @override
  String get immersiveStatusBar => '沉浸式狀態列';

  @override
  String get immersiveStatusBarHint => '隱藏頂部時間、電量等狀態資訊，保留底部系統導覽';

  @override
  String get busyHint => '工作進行中提示';

  @override
  String get busyHintDescription => '同步、重新整理等工作進行中時，在無法使用的入口下方以紅字說明原因';

  @override
  String get customHarmonyColor => '自訂調和顏色';

  @override
  String get confettiHint => '重新整理資料或同步成績成功後播放彩紙禮炮';

  @override
  String get gravityEffect => '重力效果';

  @override
  String get gravityEffectHint => '彩紙沿弧線飄落，向上噴出的彩紙會落下';

  @override
  String get harmonyColor => '調和顏色';

  @override
  String get harmonyLevel => '調和程度';

  @override
  String get harmonyHint => '數值越高，彩紙顏色越接近調和顏色；0% 保留鮮豔的多彩效果';

  @override
  String get paperType => '彩紙類型';

  @override
  String get paperMixed => '繽紛混彩';

  @override
  String get paperSquare => '方形紙片';

  @override
  String get paperCircle => '圓形紙片';

  @override
  String get paperRibbon => '輕盈彩帶';

  @override
  String get burstPosition => '播放位置';

  @override
  String get burstTopBottom => '上下星落';

  @override
  String get burstLeftRight => '左右流彩';

  @override
  String get burstAllEdges => '四方禮花';

  @override
  String get previewNow => '立即播放預覽';

  @override
  String get defaultDifficulty => '歌曲詳情預設難度';

  @override
  String get defaultDifficultyHint => '從歌曲搜尋等未指定難度的入口開啟歌曲時，優先顯示所選難度。';

  @override
  String get defaultDifficultyNote => '首次使用預設為 MASTER。成績、譜面等已指定難度的連結會保留原本的難度。';

  @override
  String get settingSaveFailed => '設定儲存失敗，請重試';

  @override
  String get autoInstall => '自動安裝更新';

  @override
  String get experimental => '測試性';

  @override
  String get autoInstallHint =>
      '預設關閉，不會自動下載。僅適用於你主動選擇的 App 內下載。安裝包通過驗證後：前景會先提示，確認後退到背景嘗試安裝；背景沒有同步、重新整理、匯入匯出或下載等工作持續 8 秒後自動嘗試安裝。工作開始或回到前景會重新計時。';

  @override
  String get autoInstallNote =>
      '需要 Android 12 及以上版本，並允許此來源安裝應用程式。播放音樂或通話時會等待，不需要鎖定螢幕。實際執行仍可能受系統排程影響，部分系統需要手動確認；延遲或失敗時可手動安裝。安裝會結束舊處理程序，下次開啟即為新版；關閉開關無法撤回系統已開始執行的安裝。';

  @override
  String get autoInstallUnsupported => '目前的系統不支援此測試功能，請手動安裝更新。';

  @override
  String get allowInstallSource => '允許此來源安裝應用程式';

  @override
  String get autoInstallSettingsError => '無法套用自動安裝設定，請重試或檢查系統安裝權限';

  @override
  String get reloadSettings => '重新讀取設定';

  @override
  String get hexFormatError => '格式應為 #RRGGBB 或 #AARRGGBB';

  @override
  String get enterHexColor => '輸入十六進位顏色';

  @override
  String get hexColorHint => '#RRGGBB 或 #AARRGGBB';

  @override
  String get hue => '色相';

  @override
  String get colorPickerHint => '拖曳上方方塊選色，或直接輸入十六進位顏色';

  @override
  String get enterHex => '輸入十六進位';

  @override
  String get wallpaperCropHint => '雙指縮放、拖曳，選擇桌布顯示範圍';

  @override
  String get wallpaperReadFailed => '無法讀取這張圖片，目前的系統可能不支援此格式';

  @override
  String get wallpaperCropFailed => '裁切失敗，請重試';

  @override
  String get setWallpaper => '設為桌布';

  @override
  String picturePickFailed(String error) {
    return '選擇圖片失敗：$error';
  }

  @override
  String exportDescription(String extension) {
    return '匯出收藏夾會產生 <名稱>$extension 檔案，放在 Download/ChiffonMai/收藏夹/ 下，可直接在檔案管理員中找到。\n副檔名已固定，避免變更常見格式的預設開啟方式。\n匯入以檔案內容識別，與副檔名無關；舊備份仍可匯入。';
  }

  @override
  String secondsValue(int seconds) {
    return '$seconds 秒';
  }

  @override
  String gatewayTimeoutSemantics(int seconds) {
    return 'AWMC 閘道檢測逾時，目前 $seconds 秒';
  }

  @override
  String gatewayTimeoutSaved(int seconds) {
    return 'AWMC 閘道檢測逾時已設為 $seconds 秒';
  }

  @override
  String allowedSeconds(int min, int max) {
    return '允許 $min–$max 秒';
  }

  @override
  String defaultSecondsHint(int defaultSeconds, int min, int max) {
    return '預設 $defaultSeconds 秒，允許 $min–$max 秒';
  }

  @override
  String get foregroundUpdateTitle => '更新已準備好';

  @override
  String get foregroundUpdateBody =>
      '安裝包已通過驗證。選擇「離開並更新」後，App 將退到背景並嘗試安裝。安裝會關閉目前的 App，請先儲存操作；完成後請重新開啟。';

  @override
  String get foregroundUpdateLaterHint =>
      '選擇「稍後」可繼續使用；退到背景且沒有工作持續 8 秒後，仍會嘗試自動安裝。部分系統可能需要手動確認。';

  @override
  String get foregroundUpdateBusy => '正在執行工作或播放內容，請結束後再更新。';

  @override
  String get foregroundUpdateChanged => '下載狀態或目前工作已變更，請重新檢視後再更新。';

  @override
  String get foregroundUpdateFailed => '暫時無法開始更新，請稍後重試或在更新視窗手動安裝。';

  @override
  String get updateLater => '稍後';

  @override
  String get exitAndUpdate => '離開並更新';

  @override
  String get featureSongSearch => '樂曲檢索';

  @override
  String get featureSearchTheChinaAndInternationalLibraries => '搜索國服與非國服曲庫';

  @override
  String get featureVersionsAndLibraryAnalysis => '版本與曲庫分析';

  @override
  String get featureVersionDetailsUpdateComparisonsAndChartConstants =>
      '版本資料、更新對照與譜面定數';

  @override
  String get featureImageRecognition => '圖像識別';

  @override
  String get featureFindSongsByCoverArtAndRead => '通過曲繪找歌，識別結算成績';

  @override
  String get featureCollectibles => '收藏品圖鑑';

  @override
  String get featureBrowseIconsNameplatesAndOtherCollectibles =>
      '瀏覽頭像、姓名框等遊戲收藏品';

  @override
  String get featureSearchAndFilter => '查詢與篩選';

  @override
  String get featureBrowseScoresAndFilterChartResults => '瀏覽成績，按條件查找譜面表現';

  @override
  String get featureGrowthAndComparison => '成長與對比';

  @override
  String get featureReviewImprovementsAndCompareWithFriends => '回顧提升記錄，對比好友成績';

  @override
  String get featureBest50Overview => 'Best50 概覽';

  @override
  String get featureCurrentPerformanceAndFittedPotential => '當前表現與擬合潛力';

  @override
  String get featurePersonalizedAnalysis => '個性化分析';

  @override
  String get featureFilterBest50ByTagsAndConditions => '按標籤和條件篩選 Best50';

  @override
  String get featureGoalsAndScoreCards => '目標與製圖';

  @override
  String get featureSimulateIdealScoresAndCreateCustomScore =>
      '模擬理想成績，製作自定義成績圖';

  @override
  String get featureRatingRankings => 'Rating 排名';

  @override
  String get featureOfficialAndFittedRatingRankings =>
      '官方 Rating 與擬合 Rating 排行';

  @override
  String get featureAchievementRankings => '達成率排名';

  @override
  String get featureCompareAveragePerformanceAcrossAllScores => '比較全量成績的平均表現';

  @override
  String get featureSpecialRankings => '特殊排名';

  @override
  String get featureExplorePlayerStatisticsFromDifferentAngles => '探索不同角度的玩家數據';

  @override
  String get featureProgressAndChallenges => '進度與挑戰';

  @override
  String get featureVersionTitlesRanksAndKALEIDXSCOPE => '牌子、段位與 KALEIDXSCOPE';

  @override
  String get featureCalculators => '數值計算';

  @override
  String get featureRatingAchievementAndJudgementAnalysis => 'Rating、達成率與判定反推';

  @override
  String get featureRandomPicks => '隨機選曲';

  @override
  String get featureDecideWhatToPlayToday => '決定今天玩什麼';

  @override
  String get featurePracticeRecommendations => '練習推薦';

  @override
  String get featureChooseChartsByGainTagsGoalsOr => '圍繞收益、標籤、目標與定數挑譜';

  @override
  String get featureFavoritesAndPlayQueue => '收藏與待玩';

  @override
  String get featureOrganizeChartsForYourNextArcadeVisit => '整理譜面，準備下次出勤';

  @override
  String get featureArcadeMaps => '機廳地圖';

  @override
  String get featureFindRhythmGameArcadesInChinaAnd => '查找國內與全球音遊機廳';

  @override
  String get featureSoloGameSettings => '單人遊戲設置';

  @override
  String get featureManageSharedRulesAndModePreferences => '統一管理各模式的規則與偏好';

  @override
  String get featureTextClues => '文字線索';

  @override
  String get featureGuessSongsFromMemoryAliasesAndLetters => '憑記憶、別名與字母線索猜歌';

  @override
  String get featureCoverArtChallenges => '曲繪辨識';

  @override
  String get featureTryCroppedPixelatedBlurredFlashAndPuzzle =>
      '觀察局部、像素、模糊、快閃與拼圖曲繪';

  @override
  String get featureAudioChallenges => '音頻辨識';

  @override
  String get featureIdentifyNormalReversedOrPitchShiftedClips =>
      '通過原速、倒放或變調片段辨認歌曲';

  @override
  String get featureChartChallenges => '譜面辨識';

  @override
  String get featureGuessSongsFromSilentChartClips => '根據無聲譜面片段猜歌';

  @override
  String get featureMultiplayer => '多人聯機';

  @override
  String get featureChallengeTheSongLibraryWithFriends => '與朋友一起挑戰曲庫';

  @override
  String get featureMusicAndChartPlayback => '音樂與譜面播放';

  @override
  String get featureListenToMaimaiSongsAndPlayCustom => '聽舞萌歌曲，播放自定義譜面';

  @override
  String get featureAccountsAndAuthorization => '賬號與授權';

  @override
  String get featureManageAccountsAndDataSourceSignIns => '管理賬號與數據源登錄狀態';

  @override
  String get featureSinglePlatformSync => '單平臺同步';

  @override
  String get featureSyncScoresToEachScoreTracker => '分別同步成績到各查分器';

  @override
  String get featureBatchAndScheduledSync => '批量與定時同步';

  @override
  String get featureSyncToMultiplePlatformsOrAutomatically => '多端同步與自動同步';

  @override
  String get featureRefreshData => '數據刷新';

  @override
  String get featureUpdateCachedScoresAndCabinetPlayCounts => '更新成績緩存與機臺遊玩次數';

  @override
  String get featureLocalData => '本地數據管理';

  @override
  String get featureBackUpDataAndManageLocalCaches => '備份數據，管理本地緩存';

  @override
  String get featureAppPreferences => '應用偏好';

  @override
  String get featureThemeInteractionsAndLoadingQuotes => '主題、交互與加載語錄';

  @override
  String get featureDiagnostics => '運行診斷';

  @override
  String get featureCheckServicesAndExportLogs => '檢查服務狀態，導出運行日誌';

  @override
  String get featureCommunityActivity => '社區動態';

  @override
  String get featureBrowseRecentCommentsAndRatings => '查看最近評論與評分';

  @override
  String get featureVersionAndProject => '版本與項目';

  @override
  String get featureUpdatesProjectInformationAndLinks => '版本更新、項目介紹與相關鏈接';

  @override
  String get featureFeedbackAndSupport => '反饋與支持';

  @override
  String get featureReportIssuesShareIdeasAndSupportDevelopment =>
      '反饋問題、交流建議與支持開發';

  @override
  String get featureSongLookup => '樂曲查詢';

  @override
  String get featureSearchByTitleAliasCharterOrTag => '按歌名、別名、譜師和標籤搜索';

  @override
  String get featureInternationalSongLookup => '非國服樂曲查詢';

  @override
  String get featureSearchAndFilterTheInternationalLibrary => '搜索與篩選非國服曲庫';

  @override
  String get featureChinaUpdateComparison => '國服更新對照';

  @override
  String get featureFindSongsReleasedInJapanButNot => '看日服已上、國服還沒上的曲目';

  @override
  String get featureUpdateCalendar => '更新日曆';

  @override
  String get featureBrowseChinaChartUpdatesByDate => '按日期查看國服每次更新的譜面';

  @override
  String get featureVersionComparison => '版本對照';

  @override
  String get featureBrowsePlayableSongsByVersion => '按版本整理可遊玩曲目';

  @override
  String get featureChartConstantDistribution => '定數分佈';

  @override
  String get featureViewTheDistributionOfChartConstants => '查看譜面定數分佈';

  @override
  String get featureCoverRecognition => '曲繪識別';

  @override
  String get featureFindSongsUsingYourCameraOrAn => '用相機或圖片快速找歌';

  @override
  String get featureResultScreenRecognition => '結算畫面識別';

  @override
  String get featurePhotographAResultScreenToReadScores => '拍攝機臺結算畫面，自動識別成績';

  @override
  String get featureCollectibleLookup => '收藏品查詢';

  @override
  String get featureViewIconsNameplatesAndOtherCollectibles => '查看頭像、姓名框等收藏品';

  @override
  String get featureScoreLookup => '成績查詢';

  @override
  String get featureBrowseAndFilterAllPlayRecords => '瀏覽全部遊玩記錄與篩選結果';

  @override
  String get featureCustomScoreLookup => '個性化成績查詢';

  @override
  String get featureViewScoresByLevelOrCharter => '按等級或譜師查看成績';

  @override
  String get featureScoreImprovementHistory => '成績提升歷史';

  @override
  String get featureReviewDailyChangesToYourBestScores => '按日回顧最佳成績的變化與提升';

  @override
  String get featureRatingHistory => 'Rating 歷史';

  @override
  String get featureTrackRatingOverTime => '看 Rating 隨時間的變化';

  @override
  String get featureFriendComparison => '好友對比';

  @override
  String get featureCompareYourScoresWithAFriend => '看看你和好友的成績差異';

  @override
  String get featureViewYourCurrentBest35AndBest15 => '查看當前 Best35 與 Best15';

  @override
  String get featureFittedBest50 => '擬合 Best50';

  @override
  String get featureAnalyzeYourPotentialRatingCeiling => '分析潛在 Rating 上限';

  @override
  String get featureCustomBest50Analysis => '個性化 Best50';

  @override
  String get featureFilterBest50ByTag => '按標籤篩選 Best50';

  @override
  String get featureCustomFittedBest50 => '個性化擬合 Best50';

  @override
  String get featureViewFittedRatingPotentialByTag => '按標籤查看擬合 Rating 上限';

  @override
  String get featureIdealBest50 => '理想 Best50';

  @override
  String get featureSimulateBest50WithEveryScoreRaisedOne =>
      '全員升一檔後的 Best50 模擬';

  @override
  String get featureCreateBest50 => '自定義 Best50';

  @override
  String get featureFillIn50ScoreCardsManually => '手動填寫 50 張成績卡片';

  @override
  String get featureRatingLeaderboard => 'Rating 排行榜';

  @override
  String get featureViewPlayerRatingRankings => '查看玩家 Rating 排行';

  @override
  String get featureTotalFittedRatingLeaderboard => '擬合總Rating排行榜';

  @override
  String get featureCompareFittedTotalRatingWithOfficialBest50 =>
      '查看擬合總 Rating 與官方 Best50 差值';

  @override
  String get featureAverageAchievementLeaderboard => '平均達成率排行榜';

  @override
  String get featureRankByAverageAchievementAcrossAllScores => '按全量成績的平均達成率排名';

  @override
  String get featureAverageDXScoreRateLeaderboard => '平均DX分數達成率排行榜';

  @override
  String get featureRankByAverageDXScoreRateAcross => '按全量成績的平均DX得分達成率排名';

  @override
  String get featureSpecialLeaderboards => '特殊排行榜';

  @override
  String get featureDiscoverInterestingPlayerStatistics => '發現有趣的玩家數據';

  @override
  String get featureVersionTitleProgress => '牌子進度';

  @override
  String get featureViewVersionsAndTargetTitles => '查看各版本與目標牌子';

  @override
  String get featureRankTable => '段位表';

  @override
  String get featureChallengeYourNextRank => '挑戰你的下一段位';

  @override
  String get featureExploreAUniqueMaimaiMode => '探索獨特的舞萌玩法';

  @override
  String get featureSongRatingCalculator => '單曲 Rating 計算';

  @override
  String get featureCalculateASongRatingFromAchievement => '根據達成率計算單首 rating';

  @override
  String get featureAchievementCalculator => '達成率計算';

  @override
  String get featureCalculateAchievementFromJudgements => '根據判定詳情算出達成率';

  @override
  String get featureReverseAchievementCalculator => '達成率反推';

  @override
  String get featureInferBREAKDetailsFromJudgements => '根據判定詳情推出絕贊詳情';

  @override
  String get featureDailyRecommendations => '每日推薦';

  @override
  String get featureLetRecommendationsPickYourNextSong => '今天打什麼？交給推薦';

  @override
  String get featureRandomSongs => '隨機樂曲';

  @override
  String get featureDrawACustomNumberOfRandomSongs => '自定義數量隨機抽取歌曲';

  @override
  String get featureArcadeRoulette => '出勤轉盤';

  @override
  String get featureLetARouletteWheelChooseYourSession => '等分轉盤決定本次出勤選項';

  @override
  String get featureRatingGainRecommendations => '喫分推薦';

  @override
  String get featureChooseChartsByNetB50GainAlgorithm =>
      '按 B50 淨收益挑譜 · AWMC 提供算法支持';

  @override
  String get featureTagRecommendations => '基於標籤推薦';

  @override
  String get featureFindSongsBasedOnTagsFromYour => '基於你的遊玩譜面標籤推薦曲目';

  @override
  String get featureTargetRatingRecommendations => '基於目標 Rating 推薦';

  @override
  String get featureFindChartsThatCanRaiseYourRating => '尋找適合上分的譜面';

  @override
  String get featureConstantRangeRecommendations => '基於定數區間推薦';

  @override
  String get featureChooseChartsWithinAConstantRange => '按定數範圍挑選譜面';

  @override
  String get featureFavoriteFolders => '收藏夾';

  @override
  String get featureManageYourFavoriteCharts => '管理你收藏的譜面';

  @override
  String get featurePlayNext => '下次想玩';

  @override
  String get featureQueueSongsForYourNextArcadeVisit => '排好下次去機臺想玩的歌曲';

  @override
  String get featureChinaRhythmGameMap => '全國音遊地圖';

  @override
  String get featureFindArcadesWithTheGamesYouWant => '看看哪裏有你想玩的機臺';

  @override
  String get featureWorldwideArcadeMap => '全球音遊街機地圖';

  @override
  String get featureBrowseArcadesWorldwideOnNearCade => '查看 NearCade 全球街機店鋪';

  @override
  String get featureSoloSongGameSettings => '單人猜歌遊戲設置';

  @override
  String get featureManageSharedAndModeSpecificRules => '管理共用規則和各模式設置';

  @override
  String get featureNoClueSongQuiz => '無提示猜歌';

  @override
  String get featureChallengeTheSongLibraryFromMemory => '憑記憶挑戰曲庫';

  @override
  String get featureAliasSongQuiz => '根據別名猜歌';

  @override
  String get featureTestYourKnowledgeOfSongAliases => '用別名挑戰你的熟悉度';

  @override
  String get featureMaimaiLetterReveal => '舞萌開字母';

  @override
  String get featureGuessSongsFromRevealedLetters => '看首字母猜歌';

  @override
  String get featureCroppedCoverQuiz => '根據部分曲繪猜歌';

  @override
  String get featureGuessTheSongFromASmallPart => '看一小塊曲繪猜出歌曲';

  @override
  String get featureBlurredCoverQuiz => '根據模糊曲繪猜歌';

  @override
  String get featureGuessSongsFromBlurredCoverArt => '根據模糊化處理後的曲繪猜歌';

  @override
  String get featurePixelCoverQuiz => '像素曲繪猜歌';

  @override
  String get featureGuessSongsFromPixelatedColorsAndShapes => '根據像素馬賽克的色塊與輪廓猜歌';

  @override
  String get featureFlashCoverQuiz => '曲繪快閃猜歌';

  @override
  String get featureRememberABrieflyFlashedCover => '曲繪一閃而過，憑記憶猜歌';

  @override
  String get featureCoverPuzzleQuiz => '曲繪拼圖猜歌';

  @override
  String get featureWatchCoverPiecesAppearOverTime => '曲繪碎塊隨時間逐步拼合顯現';

  @override
  String get featureAudioClipQuiz => '根據歌曲片段猜歌';

  @override
  String get featureGuessSongsFromShortAudioClips => '截取音源片段猜歌';

  @override
  String get featureReversedAudioQuiz => '倒放音頻猜歌';

  @override
  String get featureGuessSongsFromReversedClips => '聽倒放歌曲片段猜歌';

  @override
  String get featureSpeedAndPitchQuiz => '變速變調猜歌';

  @override
  String get featureGuessSongsFromSpeedAndPitchChanges => '根據變速變調的音頻猜歌';

  @override
  String get featureChartClipQuiz => '譜面片段猜歌';

  @override
  String get featureGuessSongsFromSilentChartAnimations => '看一段無聲譜面動畫猜出歌曲';

  @override
  String get featureMultiplayerSongQuiz => '多人猜歌遊戲';

  @override
  String get featureGuessMaimaiSongsWithFriends => '和朋友一起猜舞萌曲庫';

  @override
  String get featureMusicPlayer => '隨身聽';

  @override
  String get featurePlayMaimaiMusicInTheBackgroundWith => '後臺播放舞萌曲庫，帶通知欄播放器';

  @override
  String get featureCustomChartPlayback => '自定義譜面播放';

  @override
  String get featurePlayLocalCustomCharts => '播放本地自定義譜面';

  @override
  String get featureAccountManagement => '成績導入憑據';

  @override
  String get featureViewYourLinkedDivingFishAccount =>
      '管理水魚、落雪與 AWMC NET 的成績導入 Token';

  @override
  String get featureAccountSetupGuide => '賬號註冊引導';

  @override
  String get featureSetUpDivingFishLXNSAndAWMC => '水魚註冊、落雪註冊與 AWMC NET 檔案創建引導';

  @override
  String get featureSignInToMaimaiScoreHub => '登錄 maimai Score Hub';

  @override
  String get featureSignInForOCRAndScoreHub =>
      '僅登錄，不同步成績；用於 OCR 與 maimai Score Hub 功能';

  @override
  String get featureSignOutOfDivingFish => '登出水魚賬號';

  @override
  String get featureClearYourDivingFishSignIn => '清除水魚登錄狀態';

  @override
  String get featureSignInToDivingFish => '登錄水魚';

  @override
  String get featureGetAnImportTokenToEnableScoreSync =>
      '獲取 ImportToken 以使用同步功能';

  @override
  String get featureSyncToDivingFish => '同步成績到水魚';

  @override
  String get featureScanACodeToFetchAndSync => '掃碼抓取並同步最新成績';

  @override
  String get featureSyncToLXNS => '同步成績到落雪';

  @override
  String get featureSyncLocalScoresToLXNS => '將本地成績同步到落雪咖啡屋';

  @override
  String get featureSyncToAWMCNET => '同步成績到 AWMC NET';

  @override
  String get featureImportScoresToAWMCNETUsingA => '用機臺二維碼導入成績到 AWMC NET';

  @override
  String get featureSyncToMultiplePlatforms => '同步成績到多端';

  @override
  String get featureSendTheSameScoresToMultipleTrackers => '一份成績同步到多個查分器';

  @override
  String get featureAutoSync => '自動同步';

  @override
  String get featureQuickSyncDailyAt0000And => '每天北京時間 0 點和 12 點自動快速同步';

  @override
  String get featureRefreshCachedData => '拉取成績並更新數據';

  @override
  String get featureFetchAndInitializeAllLocalCachesAgain =>
      '拉取所選帳號的成績並重算 Best50，同時更新曲目、定數與標籤';

  @override
  String get featureAdvancedRefresh => '拉取成績並更新數據（高級）';

  @override
  String get featureChooseCachesToRefreshAndTestAPI =>
      '按資料類型選擇是否強制重新下載，並測試各介面連通性';

  @override
  String get featureRefreshCabinetPlayCount => '刷新機臺遊玩次數';

  @override
  String get featureReadOnlyTheCurrentAccountPlayCount =>
      '單獨讀取當前賬號的 PC 數；不會附帶同步成績';

  @override
  String get featureDataBackup => '數據備份';

  @override
  String get featureImportOrExportLocalData => '導入或導出本地數據';

  @override
  String get featureCacheManagement => '緩存管理';

  @override
  String get featureViewAndClearAudioPVAndMaidata => '查看並清理音源、PV、maidata 緩存';

  @override
  String get featureSystemSettings => '系統設置';

  @override
  String get featureAdjustThemeBackgroundInteractionsAndSync =>
      '調整主題、背景圖、交互與同步選項';

  @override
  String get featureLoadingQuotes => '加載語錄管理';

  @override
  String get featureChooseQuotesShownWhileLoading => '選擇加載時展示的語錄';

  @override
  String get featureServerStatus => '服務器狀態';

  @override
  String get featureViewMaimaiServiceStatus => '查看舞萌服務狀態';

  @override
  String get featureExportLogs => '打印日誌';

  @override
  String get featureExportRecentLogsForTroubleshooting => '導出最近運行日誌，方便排查問題';

  @override
  String get featureRecentComments => '最近評論';

  @override
  String get featureViewRecentCommunityComments => '查看社區最近評論';

  @override
  String get featureRecentRatings => '最近評分';

  @override
  String get featureViewRecentCommunityRatings => '查看社區最近評分';

  @override
  String get featureCheckForUpdates => '檢查更新';

  @override
  String get featureCheckForANewerAppVersion => '檢查應用是否有新版本';

  @override
  String get featureAboutTheApp => '關於 APP';

  @override
  String get featureViewProjectAndVersionInformation => '瞭解項目與版本信息';

  @override
  String get featureOfficialWebsite => '訪問官方網站';

  @override
  String get featureVisitTheProjectAtChiffonmaiCloud =>
      '前往 chiffonmai.cloud 查看項目主頁';

  @override
  String get featureRelatedProjects => '查看友情鏈接';

  @override
  String get featureDiscoverCommunityProjects => '發現同好項目';

  @override
  String get featureReportAnIssue => '問題反饋';

  @override
  String get featureReportProblemsYouEncounter => '反饋使用中遇到的問題';

  @override
  String get featureJoinTheQQGroup => '加入 QQ 羣';

  @override
  String get featureOpenTheOfficialCommunityGroup => '一鍵跳轉官方交流羣';

  @override
  String get featureSurvey => '問卷調查';

  @override
  String get featureHelpImproveChiffonMai => '助力 ChiffonMai 更上一層樓';

  @override
  String get featureSupportDevelopment => '支持開發者';

  @override
  String get featureSupportContinuedProjectUpdates => '支持項目持續更新';

  @override
  String get featureLibrary => '曲庫';

  @override
  String get featureSearchSongsBrowseInformationAndRecognizeImages =>
      '搜索樂曲、瀏覽資料與圖像識別';

  @override
  String get featureSiteWideTotalFittedRatingRanking => '擬合總 Rating 站內排行';

  @override
  String get featureRankAllScoresByAverageDXScore => '按全量成績的平均DX分數達成率排名';

  @override
  String get featureScores => '成績';

  @override
  String get featureBrowseScoresImprovementsRankingsAndProgress =>
      '查成績、看提升、比排名與追蹤進度';

  @override
  String get featureAllFeatures => '全部功能';

  @override
  String get featureStarAFeatureToAddItTo => '點星標加入首頁「常用」';

  @override
  String get featureChallengeYourMelodyMemoryWithReversedClips =>
      '聽倒放的歌曲片段，挑戰旋律記憶';

  @override
  String get featureChangeBothSpeedAndPitchForA => '速度與音高一起變化，換個耳朵聽歌';

  @override
  String get featureSyncScoresOnADailySchedule => '每天定時同步成績，解放雙手';

  @override
  String get featureMe => '我的';

  @override
  String get featureAccountsSyncBackupAndAppPreferences => '賬號、同步、備份與應用偏好';

  @override
  String get featureSharedRulesAndSettingsForEachMode => '共用規則與各模式的專屬設置';

  @override
  String get featureHome => '首頁';

  @override
  String get featurePlay => '遊玩';

  @override
  String get featureArcade => '出勤';

  @override
  String get featureCasual => '休閒';

  @override
  String get featureChooseSongsPlanPracticeAndFindArcades => '選曲、安排練習與查找機廳';

  @override
  String get featureSongQuizzesMusicAndCustomCharts => '猜歌挑戰、聽歌與自定義譜面播放';

  @override
  String get featureSystem => '系統';

  @override
  String get featureBuildingCoverIndex => '正在構建曲繪索引…';

  @override
  String get featureAnotherTaskIsRunningPleaseWait => '正在處理其它任務，請稍候';

  @override
  String get featureLeaderboards => '排行榜';

  @override
  String get featureTotalFittedRating => '擬合總 Rating';

  @override
  String get featureAverageAchievement => '平均達成率';

  @override
  String get featureAverageDXScoreRate => '平均DX分數達成率';

  @override
  String get featureSpecial => '特殊';

  @override
  String get featureCalculators2 => '計算工具';

  @override
  String get featureFindScoresTitleConstantOrSongID => '查成績：曲名、定數、曲目 ID';

  @override
  String get featureRefreshDataToSeeYourBest35And =>
      '刷新數據後這裏會顯示 Best35 與 Best15';

  @override
  String get featureFitted => '擬合';

  @override
  String get featureCustom => '個性化';

  @override
  String get featureCustomFitted => '個性化擬合';

  @override
  String get featureIdeal => '理想';

  @override
  String get featureCreate => '自定義';

  @override
  String get featureScoreImprovements => '成績提升';

  @override
  String get featureRecordsBeginAfterSyncing => '同步後開始記錄';

  @override
  String get featureDailyHistory => '按日回顧';

  @override
  String get featureThemeAndNavigationSettings => '主題與導航設置';

  @override
  String get featureSyncDataInMe => '前往「我的」同步數據';

  @override
  String get featureNoMatchingFeatures => '沒有找到匹配的功能';

  @override
  String get featureNoFeaturesFound => '未找到匹配的功能';

  @override
  String get featureFavorites => '常用';

  @override
  String get featureDragToReorderTapOrDragTo => '拖動圖標調整順序；點叉號或拖到刪除區域可移除收藏';

  @override
  String get featureStarFeaturesInAnyCategoryToShow =>
      '點擊分類中的 ⭐ 星標即可收藏功能，收藏後直接顯示在此處';

  @override
  String get featureFinishEditingFavorites => '完成收藏功能編輯';

  @override
  String get featureEditFavorites => '編輯收藏功能';

  @override
  String get featureDone => '完成';

  @override
  String get featureEdit => '編輯';

  @override
  String get featureReleaseToRemove => '鬆手移除收藏';

  @override
  String get featureDragHereToRemove => '拖到這裏移除收藏';

  @override
  String get featureRemoveFavorite => '取消收藏';

  @override
  String get featureFavoriteFeature => '收藏功能';

  @override
  String get featureSearchFeaturesOrKeywords => '搜索功能名稱或關鍵詞';

  @override
  String get featureSearchSongTitlesAliasesOrIDs => '搜索歌名、別名、歌曲 ID…';

  @override
  String get featureSearchFeaturesOrSongs => '搜索功能或歌曲';

  @override
  String get featureSearch => '搜點什麼...';

  @override
  String get featureClear => '清空';

  @override
  String get featureSearch2 => '搜索';

  @override
  String get featureCloseSearch => '收起搜索';

  @override
  String get featureClearInput => '清除輸入';

  @override
  String get featureClearSearch => '清空搜索';

  @override
  String get featureSearchHistory => '搜索歷史';

  @override
  String get featureLoadingSearchHistory => '正在讀取搜索歷史…';

  @override
  String get featureNoSearchHistory => '暫無搜索歷史';

  @override
  String get featureDeleteThisSearchEntry => '刪除這條搜索歷史';

  @override
  String get featureCouldNotUpdateSearchHistoryTryAgain => '搜索歷史更新失敗，請重試';

  @override
  String get featureSearchSongTitlesOnly => '只按歌名搜索';

  @override
  String get featureTitleBPMCharterArtistAliasID => '歌名/BPM/譜師/曲師/別名/歌曲ID/...';

  @override
  String get featureTitleAliasIDArtistCharterBPM => '曲名、別名、ID、曲師、譜師、BPM';

  @override
  String get featureEnterAKeywordToFindSongs => '輸入關鍵詞搜索歌曲';

  @override
  String get featureNoMatchingSongs => '沒有找到匹配的歌曲';

  @override
  String get featureSongs => '歌曲';

  @override
  String get featureThemeSettings => '主題設置';

  @override
  String get featureMoreSettings => '更多設置';

  @override
  String get featureCancel => '取消';

  @override
  String get featureOK => '確定';

  @override
  String get featureClose => '關閉';

  @override
  String get featureGotIt => '知道了';

  @override
  String get featureNotice => '提示';

  @override
  String get featureOperationFailed => '操作失敗';

  @override
  String get featureUnknownError => '未知錯誤';

  @override
  String get featureDialog => '對話框';

  @override
  String get featureNoDetailsAvailable => '暫無詳情';

  @override
  String get featureUnknown => '暫時未知';

  @override
  String get featureOff => '未開啓';

  @override
  String get featureWaitingForUpstream => '等待上游';

  @override
  String get featureSyncing => '同步中';

  @override
  String get featureOn => '已開啓';

  @override
  String get featureLastRunIncomplete => '上次未完成';

  @override
  String get featureUpToDate => '已是最新';

  @override
  String get featureLoading => '讀取中…';

  @override
  String get featureCheckingSyncStatus => '正在獲取同步狀態';

  @override
  String get featureStatusUnknown => '狀態未知';

  @override
  String get featureTemporarilyUnavailable => '暫時讀取不到';

  @override
  String get featureTapToSetUp => '點這裏設置';

  @override
  String get featureUnavailableRetryingShortly => '暫時讀取不到，稍後自動重試';

  @override
  String get featureCheckingServerStatus => '正在獲取服務器狀態';

  @override
  String get featureSyncing2 => '正在同步…';

  @override
  String get featureReadingCabinetScores => '讀取機臺成績…';

  @override
  String get featureCheckingForUpdates => '正在檢查更新...';

  @override
  String get featureCouldNotCheckForUpdates => '檢查更新失敗';

  @override
  String get featureCheckYourConnectionAndTryAgain => '請檢查網絡連接後重試';

  @override
  String get featureCopyDownloadLink => '複製下載鏈接';

  @override
  String get featureDownloadLinkCopied => '下載鏈接已複製到剪貼板';

  @override
  String get featureUpdateAvailable => '發現新版本';

  @override
  String get featureNewVersion => '新版本';

  @override
  String get featureSignedInForOCRAndMaimaiScore =>
      '已登錄，可用於 OCR 與 maimai Score Hub 功能';

  @override
  String get featureSignedInOCRAndMaimaiScoreHub =>
      '登錄成功，可用於 OCR 與 maimai Score Hub 功能';

  @override
  String get featureRainbow => '彩';

  @override
  String get featurePlatinum => '白金';

  @override
  String get featureGold => '金';

  @override
  String get featureSilver => '銀';

  @override
  String get featureBronze => '銅';

  @override
  String get featurePurple => '紫';

  @override
  String get featureRed => '紅';

  @override
  String get featureOrange => '橙';

  @override
  String get featureGreen => '綠';

  @override
  String get featureBlue => '藍';

  @override
  String get featureWhite => '白';

  @override
  String homeWelcome(String name) {
    return '歡迎回來，$name';
  }

  @override
  String homeSwitchSource(String source) {
    return '切換數據源，當前 $source';
  }

  @override
  String homeTotalRatingAction(String rating) {
    return '總 Rating $rating，打開高級刷新';
  }

  @override
  String homeFeatureCount(int count) {
    return '功能（$count）';
  }

  @override
  String homeAllFeatureCount(int count) {
    return '全部功能（$count）';
  }

  @override
  String homeResultCount(int count) {
    return '搜索結果（$count）';
  }

  @override
  String homeSongCount(int count) {
    return '歌曲（$count）';
  }

  @override
  String homeSongCountLimited(int count, int limit) {
    return '歌曲（$count，顯示前 $limit 首）';
  }

  @override
  String homeRemoveFavorite(String name) {
    return '移除收藏：$name';
  }

  @override
  String hubRatingRecords(int rating, int count) {
    return '最新 $rating · 共 $count 次記錄';
  }

  @override
  String hubFeaturesCount(int count) {
    return '$count 個功能';
  }

  @override
  String hubCoverIndexFailed(String error) {
    return '曲繪索引構建失敗：$error';
  }

  @override
  String hubOpenFailed(String error) {
    return '打開失敗：$error';
  }

  @override
  String hubLinkUnavailable(String name) {
    return '無法打開鏈接：$name';
  }

  @override
  String hubJoinGroup(String number) {
    return '一鍵跳轉官方交流羣（$number）';
  }

  @override
  String hubUpdateReleased(String version) {
    return '$version 已發佈，點擊查看更新內容';
  }

  @override
  String homeSyncSubmitted(int count) {
    return '提交 $count 條';
  }

  @override
  String homeSyncIncomplete(int count) {
    return '$count 個未完成';
  }

  @override
  String homeSyncSources(int count) {
    return '$count 個數據源';
  }

  @override
  String homeSyncSourcesWaiting(int count) {
    return '$count 個數據源 · 等待執行';
  }

  @override
  String homeSyncUpload(int completed, int total) {
    return '上傳 $completed/$total 條';
  }

  @override
  String homeSyncReadPage(int page) {
    return '讀取機臺成績 · 第 $page 頁';
  }

  @override
  String homeServerHealthy(int healthy, int total) {
    return '$healthy/$total 正常';
  }

  @override
  String homeTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String get homeInitWorking => '正在初始化應用數據，請稍候...';

  @override
  String homeInitFinished(String duration) {
    return '數據初始化完成！總耗時 $duration';
  }

  @override
  String homeInitFailed(String error) {
    return '初始化失敗：$error\n建議檢查網絡連接後重啓應用';
  }

  @override
  String get featureHubSignedIn => '已登錄，可直接使用 OCR；點擊可重新登錄';

  @override
  String get featureFish => '水魚';

  @override
  String get featureLxns => '落雪';

  @override
  String get featureServerNormal => '服務正常';

  @override
  String get featureServerAbnormal => '服務異常';

  @override
  String get featureTapCommunityAppearance => '點擊選擇社區裝扮';

  @override
  String get featureManageAccountBelow => '可按需在下方管理賬號數據';

  @override
  String get featureCollapseProfile => '切換爲簡略信息';

  @override
  String get featureExpandProfile => '展開詳細信息';

  @override
  String get featureSynced => '已同步';

  @override
  String get featureSyncFailed => '同步失敗';

  @override
  String get featurePendingSync => '待同步';

  @override
  String get featureLocalOnly => '僅本機';

  @override
  String get featureLoadingGrowth => '正在讀取成長記錄…';

  @override
  String get featureGrowthRules => '成長規則';

  @override
  String get featureSyncProgress => '同步進行中，請稍候…';

  @override
  String get featurePreparing => '正在準備…';

  @override
  String homeStreak(int days) {
    return '連續簽到 $days 天';
  }

  @override
  String homeTrophyId(String id) {
    return '稱號 #$id';
  }

  @override
  String get growthRulesBody =>
      '按北京時間，每天首次啓動 App 時檢查簽到；本機登錄或驗證賬號成功後，也會爲當天尚未簽到的賬號自動簽到。\n\n首日 20 經驗；連續簽到每天多 5 點，第 7 天起每天 50 點。中斷後從 20 點重新開始，累計經驗保留。\n\nLv.1 升級需 100 經驗，之後每級多需 20 點。\n\n成長記錄跟隨對應數據源賬號，同一賬號同日只能領取一次。';

  @override
  String hubOpenRelatedProject(String name) {
    return '開啟友情連結：$name';
  }

  @override
  String hubBusyTask(String task) {
    return '$task正在進行中，無法使用此功能';
  }

  @override
  String get flowEnterYourAWMCNETTokenFirst => '請先輸入 AWMC NET Token';

  @override
  String get flowCouldNotSaveYourPersonalKeyTry => '個人 key 保存失敗，請重試';

  @override
  String get flowCouldNotDisableAutoSyncYourKey => '無法關閉對應自動同步，個人 key 未清除，請重試';

  @override
  String get flowAWMCNETScoreImportToken => 'AWMC NET 成績導入 Token';

  @override
  String get flowSet => '已設置';

  @override
  String get flowNotSet => '未設置';

  @override
  String get flowVisit => '訪問';

  @override
  String get flowToGenerateOrRotateYourTokenAt => '，在頁面底部生成或輪換Token。';

  @override
  String get flowPasteYourAWMCNETScoreImportToken =>
      '在此粘貼 AWMC NET 成績導入 Token...';

  @override
  String get flowClearToken => '清除 Token';

  @override
  String flowSignOutFailedP0(String p0) {
    return '登出失敗：$p0';
  }

  @override
  String get flowSignedOutOfDivingFish => '已登出水魚賬號';

  @override
  String get flowLinkDivingFishAccount => '綁定水魚賬號';

  @override
  String get flowRequestAndOpenALoginQRCode =>
      '在舞萌|中二公衆號請求並打開二維碼，掃描後將字符串粘貼到下方：';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID =>
      '舞萌DX | 中二節奏 登入二維碼(SGWCMAID...)';

  @override
  String get flowJoinLeaderboards => '參與排行榜';

  @override
  String get flowShowNicknameOtherwiseShownAsAnonymous => '展示暱稱（不勾選則顯示爲匿名用戶）';

  @override
  String get flowScoresFetchedLinkYourDivingFishAccount =>
      '成績已抓取成功！但要推送到水魚，需要先綁定你的水魚賬號：';

  @override
  String get flowDivingFishUsername => '水魚用戶名';

  @override
  String get flowEnterDivingFishUsername => '輸入 Diving-Fish 用戶名';

  @override
  String get flowDivingFishPassword => '水魚密碼';

  @override
  String get flowEnterDivingFishPassword => '輸入 Diving-Fish 密碼';

  @override
  String get flowSyncInProgressPleaseWaitAndAvoid => '同步進行中，請耐心等待，不要進行其他操作';

  @override
  String get flowScoresSyncedViewThemOnDivingFish => '成績已同步！可前往水魚查看';

  @override
  String flowOKP0(String p0) {
    return '確定 ($p0)';
  }

  @override
  String get flowSkip => '跳過';

  @override
  String get flowLinking => '綁定中...';

  @override
  String get flowLinkAndSync => '綁定並同步';

  @override
  String flowDoneP0ScoresSyncedAndLocalData(String p0) {
    return '全部完成！$p0 條成績已同步，本地數據已刷新';
  }

  @override
  String get flowStartSync => '開始同步';

  @override
  String get flowPasteTheMaimaiCHUNITHMLoginQRString => '請先粘貼舞萌|中二登入二維碼字符串';

  @override
  String get flowSignedIn => '已登錄';

  @override
  String get flowEnterYourDivingFishCredentialsToObtain =>
      '輸入你的 Diving-Fish 水魚賬號密碼以獲取 ImportToken：';

  @override
  String get flowUsername => '用戶名';

  @override
  String get flowDivingFishUsername2 => 'Diving-Fish 用戶名';

  @override
  String get flowPassword => '密碼';

  @override
  String get flowDivingFishPassword2 => 'Diving-Fish 密碼';

  @override
  String get flowImportTokenRetrievedAndSaved => 'ImportToken 已獲取並緩存';

  @override
  String get flowYouCanNowSyncScoresToDiving => '現在可以使用\"同步成績\"功能一鍵同步到水魚了';

  @override
  String get flowSigningIn => '登錄中...';

  @override
  String get flowSignIn => '登錄';

  @override
  String get flowDataRefreshed => '數據刷新成功!';

  @override
  String get flowDivingFishProfile => '水魚 成績導入Token';

  @override
  String get flowNotSignedInToDivingFishOnly => '未登錄水魚賬號，僅顯示落雪相關設置';

  @override
  String get flowNoQQIDFoundRefreshDataOr => '未找到 QQ 號，請先刷新數據或登錄水魚';

  @override
  String get flowAuthorized => '已授權';

  @override
  String get flowNotAuthorized => '未授權';

  @override
  String get flowReadingDivingFishScoresRequiresBrowserAuthorization =>
      '讀取你的水魚成績需要先在瀏覽器裏授權本應用。點下方按鈕打開授權鏈接，登錄水魚並同意即可。';

  @override
  String get flowDivingFishAuthorization => '水魚授權';

  @override
  String get flowAuthorizationOpenedCompleteItInYourBrowser =>
      '已打開授權鏈接，請在瀏覽器中完成授權後返回查看';

  @override
  String get flowCouldNotStartAuthorizationTryAgain => '發起授權失敗，請稍後重試';

  @override
  String get flowAuthorizeAgain => '重新授權';

  @override
  String get flowOpenAuthorizationLink => '打開授權鏈接';

  @override
  String get flowLXNSPersonalAPIKey => '落雪 API 密鑰';

  @override
  String get flowVisit2 => '訪問 ';

  @override
  String get flowAndScrollToTheBottomToGet => '，滑到最底部獲取密鑰。';

  @override
  String get flowPasteYourLXNSPersonalAPIKey => '在此粘貼落雪個人 API 密鑰...';

  @override
  String get flowEnterYourAPIKeyFirst => '請先輸入 API 密鑰';

  @override
  String get flowClearKey => '清除密鑰';

  @override
  String get flowRefreshImportToken => '刷新 ImportToken';

  @override
  String get flowCouldNotRefreshImportTokenTryAgain => 'ImportToken 刷新失敗，請稍後重試';

  @override
  String get flowCopyImportToken => '複製 ImportToken';

  @override
  String get flowImportTokenCopied => 'ImportToken 已複製到剪貼板';

  @override
  String get flowConfirmRefresh => '確認刷新';

  @override
  String get flowThisClearsAllMaidataCachesAndDownloads =>
      '將清除所有maidata緩存並從服務器重新拉取全部maidata數據，耗時可能較長。\n\n確定要刷新嗎？';

  @override
  String get flowMaidataRefreshed => 'Maidata刷新成功';

  @override
  String flowRefreshFailedP0(String p0) {
    return '刷新失敗: $p0';
  }

  @override
  String flowCouldNotOpenABrowserWebsiteLink(String p0) {
    return '無法打開瀏覽器，官網鏈接已複製到剪貼板，請粘貼到瀏覽器訪問 $p0';
  }

  @override
  String get flowConfirmSignOut => '確認登出';

  @override
  String get flowSigningOutClearsSavedLoginDetailsAnd =>
      '登出後將清除緩存的登錄信息和 ImportToken，確定要登出嗎？';

  @override
  String get flowSignOut => '登出';

  @override
  String get flowAccountChangedChooseYourAppearanceAgain => '賬號已切換，請重新選擇裝扮';

  @override
  String get flowCouldNotSaveYourAppearanceChooseAgain => '裝扮未能保存，請重新選擇';

  @override
  String get flowChooseWhereToSaveLogs => '選擇日誌保存位置';

  @override
  String get flowLogsExported => '日誌已導出';

  @override
  String flowCouldNotExportLogsP0(String p0) {
    return '導出日誌失敗：$p0';
  }

  @override
  String flowCouldNotOpenABrowserP0Copied(String p0) {
    return '無法打開瀏覽器，$p0已複製到剪貼板，請手動粘貼打開';
  }

  @override
  String get flowBaseNoteMaidataDownloadedAgain => '基礎量 maidata 已重新拉取';

  @override
  String flowDownloadFailedP0(String p0) {
    return '重新拉取失敗：$p0';
  }

  @override
  String flowPlayCountsUpdatedP0Records(String p0) {
    return '遊玩次數已更新（$p0 條）';
  }

  @override
  String flowCouldNotReadPlayCountsP0(String p0) {
    return '遊玩次數讀取失敗：$p0';
  }

  @override
  String get flowNoConnectionConnectAndTryAgain => '當前無網絡連接，請聯網後重試';

  @override
  String get flowMaimaiScoreHubSignInSavedOCR =>
      'maimai Score Hub 登錄狀態已保存，現在可以使用 OCR 了';

  @override
  String get flowSignOutOfDivingFish => '確認登出水魚賬號';

  @override
  String flowCouldNotSignOutOfDivingFish(String p0) {
    return '登出水魚賬號失敗：$p0';
  }

  @override
  String get flowCannotSave => '無法保存';

  @override
  String get flowEnterYourAWMCNETScoreImportToken => '請輸入 AWMC NET 成績導入 Token。';

  @override
  String get flowAWMCNETScoreImportTokenSaved => 'AWMC NET 成績導入 Token 已保存';

  @override
  String get flowAWMCNETScoreImportTokenCleared => 'AWMC NET 成績導入 Token 已清除';

  @override
  String get flowSignedInToDivingFish => '水魚賬號登錄成功';

  @override
  String get flowScoreImportToken => '成績導入 Token';

  @override
  String get flowPasteATokenGeneratedInAWMCNET => '粘貼 AWMC NET 設置頁生成的 Token';

  @override
  String get flowSaveToken => '保存 Token';

  @override
  String flowP0AutoSyncEnabledScheduledDailyBetween(String p0) {
    return '已開啓$p0自動同步，每天北京時間 08:00–24:00 分時處理';
  }

  @override
  String flowP0AutoSyncDisabledHostedCredentialsDeleted(String p0) {
    return '已關閉$p0自動同步，並刪除服務端託管憑據';
  }

  @override
  String get flowAutoSyncTemporarilyLimited => '自動同步暫時受限';

  @override
  String get flowCouldNotConfigureAutoSyncCheckYour => '自動同步設置失敗，請檢查賬號狀態後重試';

  @override
  String get flowRefreshStatus => '刷新狀態';

  @override
  String get flowQueueStatus => '排隊情況';

  @override
  String get flowSyncSources => '同步數據源';

  @override
  String get flowLoading => '正在讀取…';

  @override
  String get flowSourcesEnabled => '個數據源已開啓';

  @override
  String get flowScheduledQueueWindow => '分時排隊窗口';

  @override
  String get flowChinaTimeUTC8OnceDailyQuick => '北京時間（UTC+8） · 每天一次 · 僅快速同步';

  @override
  String get flowCredentialsAreEncryptedAndHostedWhileEnabled =>
      '開啓後加密託管同步憑據，關閉即刪除。';

  @override
  String get flowAboutSync => '同步說明';

  @override
  String get flowUsersAreProcessedInDailyBatchesNew =>
      '每天分批排隊處理；批次進行中或等待開始時新加入用戶會排在當前批次末尾，批次結束後與其他用戶一起進入下一輪隨機排序；上游限流或隊列較長時會順延到後續窗口。';

  @override
  String get flowEachUserBatchHasAProcessingLimit =>
      '單個用戶批次有整體處理時限：上游慢響應、配額不足或大量上傳超過時限時，會自動結束本輪並在上輪結果中說明原因，次日窗口繼續（排隊等待不計入）。';

  @override
  String flowAfterReadingCabinetScoresEachUserHas(String p0) {
    return '機臺成績讀取完成後，單個用戶最多處理 $p0 分鐘；讀取前的排隊和額度等待不計入。超出處理時限或當天服務窗口會結束本輪，次日窗口繼續。';
  }

  @override
  String get flowLinkYourCabinetIdentityUsingAQR =>
      '輸入二維碼綁定機臺身份後，同步憑據可供三個數據源共用；也可以通過一次普通二維碼同步自動完成綁定。各數據源仍需配置各自的個人 key 和賬號。\n\n每天在北京時間 08:00–24:00 分時安排快速同步：同一用戶的三個數據源共用一份機臺成績讀取結果，再分別讀取目標成績並上傳變化。\n\n執行中會顯示當前階段、已讀取頁數、上傳與已提交條數、已用時長；遇到上游等待會顯示原因和預計重試時間。上輪結果會給出耗時、機臺數據採集時間和下次重試時間。\n\n自動同步使用統一的上游請求預算和限流；遇到維護、配額不足或網絡錯誤會暫停並顯示原因，不會連續重試。\n\n正在執行時關閉，會停止後續批次，已經提交的成績會保留；上傳結果不確定時會先覈對，不盲目重複提交。';

  @override
  String get flowSaving => '正在保存…';

  @override
  String flowP0AutoSync(String p0) {
    return '$p0自動同步';
  }

  @override
  String flowRoundStartedP0(String p0) {
    return '本輪開始：$p0';
  }

  @override
  String flowNextRunP0(String p0) {
    return '下次執行：$p0';
  }

  @override
  String get flowLoadingSyncStatus => '正在讀取同步狀態…';

  @override
  String get flowOffEnableAnytime => '未開啓 · 可隨時開啓';

  @override
  String flowSyncSucceededButLocalRefreshWasIncomplete(String p0) {
    return '同步已成功，本地刷新未完成：$p0';
  }

  @override
  String get flowTheQueueIsBusyYourRunMay => '當前排隊人數較多，可能順延到後續處理窗口';

  @override
  String flowLastProgressP0(String p0) {
    return '上次進度：$p0';
  }

  @override
  String flowP0NoExecutionSlotIsUsedWhile(String p0) {
    return '$p0；等待期間不佔用執行名額';
  }

  @override
  String flowRunTimeP0(String p0) {
    return '執行時間：$p0';
  }

  @override
  String flowCabinetDataCollectedP0(String p0) {
    return '機臺數據採集：$p0';
  }

  @override
  String get flowTheRoundExceededItsTimeLimitAnd =>
      '已超過單輪處理時限，被自動結束；未完成的部分會在下次定時時間繼續。';

  @override
  String flowTheRoundExceededItsP0MinuteLimit(String p0) {
    return '已超過單輪 $p0 分鐘處理上限，被自動結束；未完成的部分會在下次定時時間繼續。';
  }

  @override
  String get flowNextAutomaticRetry => '下次自動重試';

  @override
  String get flowNextRun => '下次執行';

  @override
  String flowP0Queue(String p0) {
    return '$p0隊列';
  }

  @override
  String get flowNextRound => '下輪';

  @override
  String get flowThisRound => '本輪';

  @override
  String get flowChinaTimeUTC8 => '北京時間（UTC+8）';

  @override
  String flowLimitP0MinutesPerRound(String p0) {
    return ' · 單輪上限 $p0 分鐘';
  }

  @override
  String get flowWaitingForUpstreamRecovery => '等待上游恢復';

  @override
  String get flowPreviousRoundQueue => '上輪隊列處理';

  @override
  String get flowLoadingPreviousRoundStatistics => '上輪統計讀取中…';

  @override
  String get flowStatisticsUnavailableRetryingAutomatically => '統計暫不可用，將自動重試';

  @override
  String get flowNoPreviousRound => '暫無上輪記錄';

  @override
  String flowSubmittedP0SkippedP1P2(String p0, String p1, String p2) {
    return '提交 $p0 條 · 跳過 $p1 條 · $p2';
  }

  @override
  String get flowCabinetIdentityLinked => '機臺身份已綁定';

  @override
  String get flowLinkCabinetIdentityFirst => '先綁定機臺身份';

  @override
  String get flowRequestAndOpenALoginQRCode2 =>
      '在舞萌 | 中二公衆號請求並打開登入二維碼，掃描後把 SGWCMAID 開頭的字符串填到下面。三個數據源共用這一次綁定，二維碼本身不會保存；完成一次普通二維碼同步也會自動綁定。';

  @override
  String get flowCabinetLoginQRCode => '機臺登入二維碼';

  @override
  String get flowLinking2 => '正在綁定…';

  @override
  String get flowLinkCabinetIdentity => '綁定機臺身份';

  @override
  String flowEnterYourP0PersonalKeyToo(String p0) {
    return '還需填寫$p0個人 key';
  }

  @override
  String get flowOpenDivingFish => '打開水魚查分器';

  @override
  String get flowOpenKeyPage => '打開獲取頁面';

  @override
  String get flowPersonalKey => '個人 key';

  @override
  String get flowPasteImportToken => '在此粘貼 ImportToken...';

  @override
  String get flowSavePersonalKey => '保存個人 key';

  @override
  String get flowInvalidCabinetLoginQRCode => '無效的機臺登入二維碼';

  @override
  String flowSyncFailedP0(String p0) {
    return '同步失敗：$p0';
  }

  @override
  String flowAWMCGatewayUnavailableP0(String p0) {
    return 'AWMC 網關當前不可用：$p0';
  }

  @override
  String get flowThisReadsOnlyTheActiveAccountPlay =>
      '本功能只讀取當前活動賬號的遊玩次數。請使用一張剛生成的二維碼；本次操作只會請求一次上游接口。';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID2 =>
      '舞萌DX | 中二節奏登入二維碼（SGWCMAID...）';

  @override
  String get flowEnterAValidSGWCMAIDCabinetLoginQR => '請輸入有效的 SGWCMAID 機臺登入二維碼';

  @override
  String get flowReadPlayCount => '開始讀取';

  @override
  String get flowNone => '（無）';

  @override
  String get flowViewFullData => '查看完整數據';

  @override
  String get flowDataIsShownOnlyOnThisDevice => '數據僅在本機展示，不會上傳到任何第三方。';

  @override
  String get flowSetGatewayToken => '設置網關令牌';

  @override
  String get flowQRCodeContent => '二維碼內容';

  @override
  String get flowInvalidQRFormatMustStartWithSGWCMAID =>
      '二維碼格式不正確（應以 SGWCMAID 開頭）';

  @override
  String get flowConfirmAction => '確認執行';

  @override
  String get flowNoCharge => '不計費';

  @override
  String get flowShow => '顯示';

  @override
  String get flowFullData => '完整數據';

  @override
  String flowP0P1CharactersP2LinesShownOnly(String p0, String p1, String p2) {
    return '$p0 · 共 $p1 字符 / $p2 行\n數據僅在本機展示，不會上傳到任何第三方。';
  }

  @override
  String get flowEnterYourAWMCNETScoreImportToken2 => '請輸入 AWMC NET 成績導入 Token';

  @override
  String get flowImportTokenSaved => '導入 Token 已保存';

  @override
  String get flowPasteOrScanACabinetLoginQR => '請先粘貼或掃描機臺登入二維碼（SGWCMAID 開頭）';

  @override
  String get flowSetYourAWMCNETScoreImportToken => '請先設置 AWMC NET 成績導入 Token';

  @override
  String get flowRequestAndOpenALoginQRIn =>
      '在「舞萌|中二」公衆號請求登入二維碼並打開，再粘貼到下方；也可直接用「掃描」或「從圖片識別」。';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID3 =>
      '舞萌DX | 中二節奏 登入二維碼（SGWCMAID...）';

  @override
  String get flowScoreImportTokenSet => '成績導入 Token 已設置';

  @override
  String get flowSetAWMCNETScoreImportToken => '設置 AWMC NET 成績導入 Token';

  @override
  String get flowChange => '更換';

  @override
  String get flowPasteScoreImportToken => '在此粘貼成績導入 Token…';

  @override
  String get flowGenerateYourOwnTokenOnAWMCNET =>
      '導入需要在 AWMC NET 官網生成一次 Token（項目自帶的密鑰在這裏用不了）：';

  @override
  String get flow1OpenTheAWMCNETSettingsLink => '① 點擊下面的鏈接打開 AWMC NET 設置頁';

  @override
  String get flow2ScrollToTheBottomAndGenerate => '② 滑到頁面最底部，點「生成/輪換Token」';

  @override
  String get flow3CopyTheTokenAndPasteIt => '③ 複製生成的 Token，然後粘貼到此處';

  @override
  String get flowCabinetScoresTakePriorityAndOverwriteMatching =>
      '以機臺爲準，會覆蓋 AWMC NET 上已存在的對應成績。';

  @override
  String flowCouldNotOpenABrowserVisitP0(String p0) {
    return '打不開瀏覽器，請手動訪問 $p0';
  }

  @override
  String flowClearP0AccountData(String p0) {
    return '清除$p0賬號數據';
  }

  @override
  String flowThisDeletesLocalP0CachesScoresBest50(String p0) {
    return '將刪除 $p0 賬號的本地緩存（成績、Best50、玩家信息、推薦結果等），不影響登錄狀態。\n\n下次使用該賬號需要重新刷新數據，確定清除？';
  }

  @override
  String get flowClear => '清除';

  @override
  String flowCouldNotClearP0(String p0) {
    return '清除失敗：$p0';
  }

  @override
  String flowClearedP0AccountData(String p0) {
    return '已清除$p0賬號數據';
  }

  @override
  String flowSwitchedToP0Account(String p0) {
    return '已切換到$p0賬號';
  }

  @override
  String get flowAccountSwitchFailedAttemptedToRestoreThe => '賬號切換失敗，已嘗試恢復原賬號';

  @override
  String get flowSwitchingPleaseWait => '正在切換，請稍候';

  @override
  String get flowNoCachedDataForThisAccount => '該賬號暫無緩存';

  @override
  String flowNoDataHasBeenCachedForP0(String p0) {
    return '$p0賬號還沒有緩存過數據，去刷新數據？';
  }

  @override
  String get flowRefreshNow => '去刷新';

  @override
  String get flowSwitchAccount => '切換賬號';

  @override
  String flowSwitchingToP0(String p0) {
    return '正在切換到$p0賬號…';
  }

  @override
  String get flowTapAnAccountToSwitchSourceAnd =>
      '點擊賬號即可切換數據源與玩家信息（使用本地緩存，不聯網）';

  @override
  String get flowRefreshToUpdateTheActiveAccountDiving =>
      '刷新數據可更新當前賬號；水魚 / 落雪的登錄狀態相互獨立，AWMC NET 按 QQ 查詢無需登錄。';

  @override
  String get flowCurrent => '當前';

  @override
  String get flowNoCache => '暫無緩存';

  @override
  String flowCopiedP0(String p0) {
    return '已複製：$p0';
  }

  @override
  String flowAWMCBOTQQIDCopiedP0(String p0) {
    return '已複製 AWMC BOT QQ 號：$p0';
  }

  @override
  String flowCopyP0(String p0) {
    return '複製 $p0';
  }

  @override
  String get flowOpenLXNS => '打開落雪咖啡屋';

  @override
  String get flowSendMymaiFirstIfNoAccountRecord =>
      '先發送 mymai。尚未建立賬號記錄時，機器人會回覆操作步驟。';

  @override
  String get flowThenSendMaiAndFollowTheInstructions => '再發送 mai綁定，按提示創建檔案。';

  @override
  String get flowOpenAWMCNET => '打開 AWMC NET';

  @override
  String get flowTapAnImageToEnlargeIt => '點開圖片可以放大查看哦';

  @override
  String get flowEnlargeImage => '放大查看圖片';

  @override
  String get flowNotSignedInToDivingFish => '還沒登錄水魚賬號';

  @override
  String get flowYourDivingFishAccountHasNoLinked => '你的水魚賬號還沒綁定 QQ 號';

  @override
  String get flowLinkQQOnDivingFish => '去水魚官網綁定';

  @override
  String get flowISavedItReadAgain => '我已填好，重新讀取';

  @override
  String get flowAccount => '賬號';

  @override
  String get flowCheckingAuthorization => '正在檢查授權狀態...';

  @override
  String get flowAuthorizationOpenedFinishInYourBrowserThen =>
      '已打開授權頁，請在瀏覽器中完成授權後點右側重新檢測';

  @override
  String get flowReadingScoresRequiresAuthorizationRefreshWillFail =>
      '讀取成績需先授權本應用，未授權時刷新會失敗';

  @override
  String get flowAuthorizedCheckAgain => '我已授權，重新檢測';

  @override
  String get flowAuthorize => '去授權';

  @override
  String get flowCouldNotOpenABrowserLinkCopied => '無法打開瀏覽器，鏈接已複製到剪貼板，請手動粘貼打開';

  @override
  String flowP0ReusesThisDeviceSMaimaiScore(String p0) {
    return '$p0會複用本機保存的 maimai Score Hub 登錄狀態。\n\n當前沒有可用登錄態：請先用一張新的機臺二維碼完成登錄；登錄成功後，本次同步還會再要求一張新的二維碼用於抓取成績——同一張二維碼不能同時用於登錄和同步。\n\n登錄狀態會保存在本機，之後使用線路2不需要重複登錄。';
  }

  @override
  String get flowRoute2Sync => '線路2 同步';

  @override
  String flowP0Sync(String p0) {
    return '$p0 同步';
  }

  @override
  String get flowTipGenerateTwoDifferentLoginQRCodes =>
      '提示：掃碼前先在公衆號/機臺生成兩張不同的登入二維碼。';

  @override
  String get flowSignInFirst => '去登錄';

  @override
  String get flowSignedInToMaimaiScoreHub => 'maimai Score Hub 登錄成功';

  @override
  String get flowSignInSavedForOCRAndRoute =>
      '登錄狀態已保存。可複用於 OCR 與線路2 同步，\n不需要再重複掃碼登錄。';

  @override
  String get flowAuthenticatesWithMaimaiScoreHubOnlyNo =>
      '只進行 maimai Score Hub 認證，不會抓取或同步成績。';

  @override
  String get flowInvalidQRCodeUseALoginQR => '無效的二維碼，請使用舞萌|中二公衆號生成的登入二維碼';

  @override
  String get flowSetLXNSPersonalAPIKey => '設置落雪個人 API 密鑰';

  @override
  String get flowExportingToLXNSRequiresYourPersonalAPI =>
      '落雪導出需要你本人的個人 API 密鑰（不是賬號密碼）：';

  @override
  String get flow1OpenTheLXNSProfileLinkBelow => '① 點擊下面的鏈接打開落雪個人主頁';

  @override
  String get flow2ScrollToTheBottomAndCopy => '② 滑到頁面最底部，找到「個人 API 密鑰」並複製';

  @override
  String get flow3ReturnToAccountManagementLXNSAPI =>
      '③ 回到 App，打開「成績導入憑據 → 落雪 API 密鑰」粘貼並保存';

  @override
  String get flowReopenThisDialogAfterSavingToSync => '保存後重新打開本對話框即可同步。';

  @override
  String get flowLinkYourDivingFishAccountToObtain =>
      '需要綁定你的水魚賬號以獲取 ImportToken：';

  @override
  String flowSyncSucceededButDataRefreshFailedP0(String p0) {
    return '同步成功，但刷新數據失敗：$p0';
  }

  @override
  String get flowSignInToYourDivingFishAccount => '請先登錄你的水魚賬號，再使用同步功能。';

  @override
  String get flowAccountMismatch => '賬號不匹配';

  @override
  String flowTheSignedInDivingFishQQP0(String p0, String p1) {
    return '當前登錄水魚賬號綁定的 QQ（$p0）與本機緩存的 QQ（$p1）不一致。\n\n請先登出當前水魚賬號，登錄正確的賬號後再同步。';
  }

  @override
  String flowSyncCompleteP0ScoresSyncedAndLocal(String p0) {
    return '同步完成！$p0 條成績已同步，本地數據已刷新';
  }

  @override
  String flowSyncCompleteP0ScoresSentToDiving(String p0) {
    return '同步完成！$p0 條成績已推送到水魚';
  }

  @override
  String flowSyncCompleteP0ScoresExportedToLXNS(String p0) {
    return '同步完成！共 $p0 條成績已導出到落雪';
  }

  @override
  String flowEnterANewQRCodeForP0(String p0) {
    return '爲$p0輸入新的二維碼';
  }

  @override
  String flowMultiPlatformSyncCompleteP0(String p0) {
    return '多端同步完成：$p0';
  }

  @override
  String flowSyncCompleteP0P1P2(String p0, String p1, String p2) {
    return '同步已完成：$p0$p1$p2';
  }

  @override
  String get flowNone2 => '無';

  @override
  String flowSyncFailedP02(String p0) {
    return '\n\n同步失敗：\n$p0';
  }

  @override
  String flowSyncSucceededButRefreshFailedP0(String p0) {
    return '\n\n同步成功，但刷新數據失敗：\n$p0';
  }

  @override
  String get flowCouldNotSaveCredentialsTryAgain => '憑據保存失敗，請重試。';

  @override
  String flowCouldNotOpenTheWebsiteVisitP0(String p0) {
    return '無法打開網站，請在瀏覽器中訪問：$p0';
  }

  @override
  String get flowRoute1 => '線路1';

  @override
  String get flowRoute2 => '線路2';

  @override
  String flowCurrentP0P1(String p0, String p1) {
    return '當前：$p0 · $p1';
  }

  @override
  String get flowQuickSyncAlwaysUsesRoute1 => '快速同步已固定使用線路1';

  @override
  String get flowAvailable => '已存在';

  @override
  String get flowMissing => '未填寫';

  @override
  String get flowFillInCredentialsToSelectThisSource => '補齊憑據後即可勾選';

  @override
  String get flowCollapse => '收起';

  @override
  String get flowFillInMissingCredentials => '填寫缺少的憑據';

  @override
  String get flowGetYourImportTokenFromTheDivingFish =>
      '在水魚官網登錄後獲取 ImportToken；通過 App 的「登錄水魚」保存過的憑據也會自動識別。';

  @override
  String get flowSignInToLXNSAndGetYour => '登錄落雪咖啡屋，在賬號設置中獲取個人 API 密鑰。';

  @override
  String get flowEnterTheQQLinkedToAWMCNET =>
      '填寫 AWMC NET 賬號綁定的 QQ；導入還需在官網設置頁底部生成的 Import-Token。';

  @override
  String get flowOpenWebsite => '打開官網';

  @override
  String get flowAWMCNETQQID => 'AWMC NET QQ 號';

  @override
  String get flowSaveAndSelect => '保存並選中';

  @override
  String get flowNormalSyncRequiresANewCabinetQR =>
      '普通同步會在每個目標開始前分別要求一張新的機臺二維碼；同一張二維碼不會用於第二個請求。快速同步不需要二維碼。';

  @override
  String get flowSourcesWithSavedCredentialsAreSelectedBy =>
      '憑據存在的端默認勾選；水魚 → 落雪 → AWMC NET 依次同步。';

  @override
  String get flowReloadCredentials => '重新讀取憑據';

  @override
  String get flowAWMCNETOverwritesMatchingRecordsWithCabinet =>
      'AWMC NET 將以機臺成績爲準覆蓋已有對應成績。';

  @override
  String flowStartSyncP0(String p0) {
    return '開始同步（$p0）';
  }

  @override
  String get flowRefreshDataAfterSync => '同步成功後刷新數據';

  @override
  String get flowRefreshAutomaticallyAfterUploadRefreshErrorsAre =>
      '成績上傳成功後自動刷新；刷新失敗會單獨提示。';

  @override
  String get flowCouldNotReadRefreshSettingsUploadCan =>
      '刷新配置讀取失敗，上傳可繼續，刷新錯誤將單獨提示。';

  @override
  String get flowReloadRefreshSettings => '重新讀取刷新配置';

  @override
  String get flowQuickSync => '快速同步';

  @override
  String get flowCheckingCachedUserCredentials => '正在檢查用戶憑據緩存…';

  @override
  String get flowCabinetIdentityLinkedNoQRNeededThis => '已綁定機臺身份，本次無需二維碼';

  @override
  String get flowChooseASyncSourceFirst => '請先選擇同步數據源';

  @override
  String get flowEnterAQRToLinkCabinetIdentity => '可直接輸入二維碼綁定機臺身份';

  @override
  String get flowUserCredentialsCached => '用戶憑據已緩存';

  @override
  String get flowUserCredentialsNotCached => '用戶憑據未緩存';

  @override
  String get flowValidatingQRCode => '正在驗證二維碼…';

  @override
  String get flowLinkCabinetIdentityUsingQR => '輸入二維碼綁定機臺身份';

  @override
  String get flowUpdatesAchievementAndDXScoresComboAnd =>
      '更新達成率與 DX 分數；連擊、同步分別沿用各目標賬號現有的標記。暫不更新宴譜和遊玩次數。';

  @override
  String get flowCouldNotDeleteCredentialsTryAgain => '用戶憑據刪除失敗，請重試';

  @override
  String get flowDeleteUserCredentials => '刪除用戶憑據';

  @override
  String get flowAllThreeSourcesShareTheseCredentialsDeleting =>
      '三個數據源共用此憑據，刪除時會關閉全部自動同步。';

  @override
  String get flowCabinetIdentityCachedQuickSyncIsReady => '機臺身份已緩存，現在可以使用快速同步';

  @override
  String flowCouldNotLinkCabinetIdentityP0(String p0) {
    return '綁定機臺身份失敗：$p0';
  }

  @override
  String get flowReadsOnlyUserIdForQuickSyncDoes =>
      '只讀取 userId 用於快速同步，不讀取成績，也不會執行普通同步。';

  @override
  String get flowVerifyAndSave => '驗證並緩存';

  @override
  String get flowValidQRStringDetectedAndFilledIn => '已識別到有效二維碼字符串，已自動填入';

  @override
  String get flowClipboardIsEmpty => '剪貼板爲空';

  @override
  String get flowClipboardContentIsNotAValidLogin => '剪貼板內容不是有效的登入二維碼，仍要填入嗎？';

  @override
  String get flowFillIn => '填入';

  @override
  String get flowNoQRCodeFoundInTheImage => '未在圖片中檢測到二維碼';

  @override
  String get flowCouldNotReadQRContentFromThe => '未能從圖片中識別到二維碼內容';

  @override
  String get flowQRCodeDetectedAndFilledIn => '已識別到二維碼，已自動填入';

  @override
  String flowRecognitionFailedP0(String p0) {
    return '識別失敗: $p0';
  }

  @override
  String flowScanFailedP0(String p0) {
    return '掃描失敗: $p0';
  }

  @override
  String get flowReadClipboard => '讀取剪貼板';

  @override
  String get flowReadFromGallery => '從相冊識別';

  @override
  String get flowScanQRCode => '掃描二維碼';

  @override
  String flowCameraErrorP0(String p0) {
    return '攝像頭錯誤: $p0';
  }

  @override
  String get flowBack => '返回';

  @override
  String get flowCouldNotOpenTheLinkCopiedTo => '無法打開鏈接，鏈接已複製到剪貼板，請手動粘貼到瀏覽器打開';

  @override
  String get flowStillNoQQIDFoundCheckThat =>
      '還是沒讀到 QQ 號。請確認已在水魚官網保存，或重新登錄一次水魚賬號';

  @override
  String flowLinkedQQFoundP0(String p0) {
    return '已讀到綁定 QQ：$p0';
  }

  @override
  String get flowNoQQIDFound => '未找到 QQ 號';

  @override
  String get flowAuthorizationOpenedReturnAfterAuthorizingAndTap =>
      '已打開授權頁，完成授權後回到這裏點「我已授權，重新檢測」';

  @override
  String get flowAuthorizedYouCanNowRefreshData => '授權成功，現在可以刷新數據了';

  @override
  String get flowAuthorizationNotDetectedApproveAccessInYour =>
      '還沒檢測到授權，請確認在瀏覽器裏點了「同意」';

  @override
  String get flowCheckFailedVerifyYourConnectionAndTry => '檢測失敗，請檢查網絡後重試';

  @override
  String get flowCurrentDataSource => '當前數據源：';

  @override
  String get flowConfirm => '確認';

  @override
  String get flowLXNSAuthorizationSavedItRenewsAutomaticallyNo =>
      '已保存落雪授權，將自動續期，無需再次輸入授權碼。';

  @override
  String get flowAuthorize2 => '點擊授權';

  @override
  String get flowAuthorizationButtonNotWorking => '點擊授權沒反應？';

  @override
  String get flowCopyThisLinkAndOpenItManually => '請複製鏈接後在瀏覽器中手動打開完成授權：';

  @override
  String get flowCopyAuthorizationLink => '複製授權鏈接';

  @override
  String get flowAuthorizationLinkCopiedPasteItIntoYour => '授權鏈接已複製，請在瀏覽器中粘貼打開';

  @override
  String get flowAfterAuthorizingCopyTheCodeShownOn =>
      '授權後複製頁面上顯示的授權碼，粘貼到下方輸入框';

  @override
  String get flowEnterAuthorizationCode => '請輸入授權碼';

  @override
  String get flowPasteAuthorizationCode => '粘貼授權碼';

  @override
  String get flowQQID => 'QQ 號';

  @override
  String get flowEnterAQQIDAlreadyLinkedOn => '輸入已在 AWMC NET 綁定過的 QQ 號';

  @override
  String get flowNoSignInNeeded => '無需登錄';

  @override
  String get flowAWMCNETIsAThirdPartyScore =>
      'AWMC NET 是第三方查分器，按 QQ 號公開查詢成績，不用登錄、也不用授權。\n前提是該 QQ 已在 net.wmc.pub 綁定並上傳過成績，否則會提示「沒有該 QQ 的數據」。';

  @override
  String get flowLinkQQUploadScoresOnAWMCNET => '去 AWMC NET 綁定 / 上傳成績';

  @override
  String get flowForceFullRefreshIgnoreStaticCaches => '強制完整刷新（忽略靜態數據緩存）';

  @override
  String get flowMaidataStillUpdatesAsASeparateBackground =>
      'maidata 仍作爲獨立後臺輔助任務更新';

  @override
  String get flowSignInThroughMeSignInTo => '請先在「系統 → 登錄水魚」登錄水魚賬號';

  @override
  String get flowYourDivingFishAccountHasNoQQ =>
      '你的水魚賬號還沒綁定 QQ 號，請先到水魚官網「編輯個人資料」裏填上';

  @override
  String get flowEnterYourLXNSAuthorizationCodeFirst => '請先填寫落雪授權碼';

  @override
  String get flowEnterYourAWMCNETQQID => '請輸入 AWMC NET 的 QQ 號';

  @override
  String get flowInvalidQQID512DigitsRequired => 'QQ 號格式不對（應爲 5–12 位數字）';

  @override
  String get flowCannotRefreshWithoutAConnectionConnectAnd =>
      '當前無網絡連接，無法刷新數據。請聯網後重試。';

  @override
  String get flowCouldNotOpenABrowserLinkCopied2 =>
      '無法打開瀏覽器，鏈接已複製到剪貼板，請手動粘貼到瀏覽器打開';

  @override
  String get flowAWMCNETOffersPublicScoreLookupBy =>
      'AWMC NET 按 QQ 號公開查詢成績，無需登錄或授權。\n前提是該 QQ 已在 net.wmc.pub 綁定並上傳過成績。';

  @override
  String get flowForceRefreshCachedData => '強制刷新緩存數據';

  @override
  String get flowDeselectAll => '全不選';

  @override
  String get flowSelectAll => '全選';

  @override
  String get flowSelectedCachesAreIgnoredAndFetchedFrom =>
      '勾選 = 在本次刷新中忽略該緩存，強制走網絡；未勾選 = 命中緩存則跳過。';

  @override
  String get flowLoading2 => '加載中…';

  @override
  String flowConnectedP0P1Ms(String p0, String p1) {
    return '連通：$p0 · ${p1}ms';
  }

  @override
  String flowFailedP0P1Ms(String p0, String p1) {
    return '失敗：$p0 (${p1}ms)';
  }

  @override
  String get flowTest => '測試';

  @override
  String get flowRoute => '線路';

  @override
  String flowP0LastRefreshFailedShowingOlderData(String p0) {
    return '$p0 · 上次刷新失敗，顯示的是舊數據';
  }

  @override
  String flowP0Last100P1SamplesAvgP2(
      String p0, String p1, String p2, String p3) {
    return '$p0近100次 / $p1樣本 / 平均$p2 / 成功$p3%';
  }

  @override
  String get flowSyncStatistics => '同步統計';

  @override
  String flowTracksDurationAndOutcomeForTheLatest(String p0) {
    return '記錄最近 $p0 次同步的耗時與成敗（所有使用者共享，僅含耗時/成敗，不含二維碼與賬號信息）。';
  }

  @override
  String flowNormalSyncP0(String p0) {
    return '普通同步 · $p0';
  }

  @override
  String get flowStatisticsUnavailable => '統計不可用';

  @override
  String get flowNoRecordsYet => '暫無記錄';

  @override
  String get flowFailed => '失敗';

  @override
  String flowP0P1UsersQueuedP2ItemsProcessing(String p0, String p1, String p2) {
    return '$p0排隊用戶 $p1 人 · 處理中 $p2 項';
  }

  @override
  String flowP0P1ChinaTime(String p0, String p1) {
    return '\n$p0：$p1（北京時間）';
  }

  @override
  String get flowDifficultyFilter => '難度篩選';

  @override
  String get flowRecentSearches => '最近搜索';

  @override
  String get flowEG137Or134 => '如 13.7 或 13.4-14';

  @override
  String flowClearP0Constant(String p0) {
    return '清空$p0定數';
  }

  @override
  String get flowEveryEnteredDifficultyMustMatchBlankFields =>
      '填寫的難度須全部滿足，留空不限制。與上方「難度」及其它篩選條件取交集。';

  @override
  String get flowUTAGEIsFilledInSoNormalDifficulties =>
      '已填寫 UTAGE，普通難度暫不可用；清空後恢復。';

  @override
  String get flowNormalDifficultiesAreFilledInSoUTAGE =>
      '已填寫普通難度，UTAGE 暫不可用；全部清空後恢復。';

  @override
  String get flowConstantFilter => '定數篩選';

  @override
  String get flowAnyDifficulty => '任意難度';

  @override
  String get flowDifficultyCombination => '按難度組合';

  @override
  String get flowClearConstants => '清空定數';

  @override
  String get flowMinimum => '最小值';

  @override
  String get flowMaximum => '最大值';

  @override
  String get flowNoteCountFilter => '物量篩選';

  @override
  String get flowMinimumNotes => '最少物量';

  @override
  String get flowMaximumNotes => '最多物量';

  @override
  String get flowBPMFilter => 'BPM篩選';

  @override
  String get flowMinimumBPM => '最小 BPM';

  @override
  String get flowMaximumBPM => '最大 BPM';

  @override
  String get flowVersionFilter => '版本篩選';

  @override
  String get flowGenreFilter => '流派篩選';

  @override
  String get flowTagFilter => '標籤篩選';

  @override
  String get flowNoTagData => '暫無標籤數據';

  @override
  String get flowCharterFilter => '譜師篩選';

  @override
  String get flowArtistFilter => '曲師篩選';

  @override
  String get flowClearSelection => '清除選擇';

  @override
  String flowLevelP0(String p0) {
    return '等級 $p0';
  }

  @override
  String get flowDXChartsOnly => '僅 DX 譜面';

  @override
  String get flowTitlesOnly => '只搜歌名';

  @override
  String get flowSearching => '正在搜索...';

  @override
  String get flowEnterASearchKeyword => '請輸入搜索關鍵詞';

  @override
  String flowP0SongsInTheLibraryEnterA(String p0) {
    return '曲庫共 $p0 首，請輸入搜索關鍵詞';
  }

  @override
  String flowP0SongsFound15PerPage(String p0) {
    return '找到 $p0 首樂曲，每頁 15 首';
  }

  @override
  String get flowReset => '重置';

  @override
  String get flowNoSongsMatchTheseFilters => '沒有符合條件的歌曲';

  @override
  String get flowTryAWiderConstantRangeOrClear => '試試放寬定數或清空篩選';

  @override
  String get flowPrevious => '上一頁';

  @override
  String get flowNext => '下一頁';

  @override
  String flowCoverIndexReadyProcessedP0Covers(String p0) {
    return '曲繪索引建立完成！共處理 $p0 張曲繪';
  }

  @override
  String flowCouldNotBuildIndexP0(String p0) {
    return '索引建立失敗: $p0';
  }

  @override
  String get flowChooseImageSource => '選擇圖片來源';

  @override
  String get flowTakePhoto => '拍照';

  @override
  String get flowPhotographCoverArt => '使用相機拍攝曲繪';

  @override
  String get flowChooseACoverScreenshotFromYourGallery => '從相冊中選取曲繪截圖';

  @override
  String get flowCameraPermissionRequired => '需要相機權限';

  @override
  String flowCouldNotSelectImageP0(String p0) {
    return '選取圖片失敗: $p0';
  }

  @override
  String get flowRecognitionFailedTryAgain => '識別失敗，請重試';

  @override
  String flowRecognitionErrorP0(String p0) {
    return '識別出錯: $p0';
  }

  @override
  String get flowRebuildCoverIndex => '重建曲繪索引';

  @override
  String get flowThisClearsTheIndexAndRecalculatesHashes =>
      '將清除現有索引並重新爲全部曲繪計算哈希。這可能需要數十秒，確定繼續嗎？';

  @override
  String get flowRebuild => '確定重建';

  @override
  String get flowLoading3 => '正在加載...';

  @override
  String get flowBuildingCoverIndex => '正在建立曲繪索引...';

  @override
  String flowComputingFeaturesForP0Covers(String p0) {
    return '爲 $p0 張曲繪計算特徵';
  }

  @override
  String get flowNeededOnlyOncePleaseWait => '僅首次需要，請耐心等待';

  @override
  String get flowTakeOrChooseACoverImage => '拍攝或選擇一張曲繪圖片';

  @override
  String get flowCropTheCoverRegionAfterSelectingFor => '選取後可手動框選曲繪區域，提高識別準確率';

  @override
  String get flowImageReady => '圖片已就緒';

  @override
  String get flowMatchConfidenceIsTooLowThisMay =>
      '匹配度過低，可能不是曲繪照片，請重新框選裁剪區域後再試';

  @override
  String get flowInputImage => '輸入圖片';

  @override
  String get flowMatchedCover => '匹配曲繪';

  @override
  String get flowCombinedMatchUnreliable => '綜合匹配（不可靠）';

  @override
  String get flowCombinedMatch => '綜合匹配';

  @override
  String get flowTop10Matches => '識別結果 Top 10';

  @override
  String flowSongP0(String p0) {
    return '歌曲 #$p0';
  }

  @override
  String get flowChooseImage => '選擇圖片';

  @override
  String get flowRecognizing => '識別中...';

  @override
  String get flowStartRecognition => '開始識別';

  @override
  String get flowCropAgain => '重新裁剪';

  @override
  String get flowChooseAgain => '重選';

  @override
  String get flowRecognizeAgain => '重新識別';

  @override
  String get flowChooseAnother => '再選一張';

  @override
  String get flowCoverIndexReady => '曲繪索引就緒';

  @override
  String get flowIndexNotBuilt => '索引未建立';

  @override
  String get flowRebuildIndex => '重建索引';

  @override
  String get flowCannotReadThisImageTryAnother => '圖片無法讀取，請換一張圖片重試';

  @override
  String get flowCropFailedContinuingWithTheOriginalImage => '裁剪失敗，將使用原圖繼續';

  @override
  String get flowDragTheCornersToSelectCoverArt => '拖動角點框選曲繪區域';

  @override
  String get flowProcessing => '處理中...';

  @override
  String get flowDragCornersToResizeDragInsideTo => '拖拽四角調整範圍  |  拖拽框內移動位置';

  @override
  String get flowNoDivingFishImportTokenSignIn =>
      '還沒有水魚 Import-Token，請先到「登錄水魚」完成登錄';

  @override
  String flowAddedToDivingFishP0(String p0) {
    return '已新增到水魚：$p0';
  }

  @override
  String flowDivingFishScoreUpdatedP0(String p0) {
    return '已更新水魚成績：$p0';
  }

  @override
  String get flowCannotParseSongIDForLXNSSync => '無法解析曲目 ID，不能同步到落雪';

  @override
  String get flowNoLXNSPersonalAPIKeySetIt => '還沒有落雪個人 API 密鑰，請先到「成績導入憑據」填寫';

  @override
  String get flowPhotographTheCabinetResultScreen => '對着機臺結算頁面拍一張';

  @override
  String get flowChooseAPhotographedResultScreen => '選取已經拍好的結算畫面';

  @override
  String get flowNoScoreRecognizedCropCloserToThe => '沒有識別出成績，可裁剪得更貼近結算區域後重試';

  @override
  String get flowCorrectRecognitionResults => '修正識別結果';

  @override
  String get flowRecognitionIsNotAlwaysAccurateEditedValues =>
      '識別不可能百分百準確，這裏改過的值會直接替換卡片上的顯示';

  @override
  String get flowDifficulty => '難度';

  @override
  String get flowSelectASongFirstToListIts => '先選定一首歌曲，才能列出它實際有的難度';

  @override
  String flowConstantP0(String p0) {
    return '定數 $p0';
  }

  @override
  String flowConstantP02(String p0) {
    return ' · 定數 $p0';
  }

  @override
  String get flowAchievement => '達成率 (%)';

  @override
  String get flowDXScore => 'DX 分數';

  @override
  String get flowCombo => '連擊';

  @override
  String get flowSync => '同步';

  @override
  String get flowEmptyMeansNoMarkerSyncMarkersUse =>
      '「空」表示不設置該標記。同步標記會按水魚的值域提交（FS / FS+ / FDX / FDX+ / SYNC）。';

  @override
  String get flowRestoreRecognizedValues => '恢復爲識別結果';

  @override
  String get flowEmpty => '空';

  @override
  String get flowNoSongData => '暫無歌曲數據';

  @override
  String get flowNoMatchingSong => '未找到匹配的歌曲';

  @override
  String get flowRecognizingScores => '正在識別成績';

  @override
  String get flowMatchingCoverArtAndTitlesUsuallyTakes => '曲繪 + 標題雙路匹配，通常需要幾秒';

  @override
  String get flowPhotographACabinetResultScreen => '對着機臺結算頁面拍一張照片';

  @override
  String get flowRecognizesTitleAchievementDXScoreDifficultyAnd =>
      '自動識別曲名、達成率、DX 分數、難度與 FC/FS';

  @override
  String get flowImageReadyTapStartRecognitionBelow => '圖片已就緒，點擊下方「開始識別」';

  @override
  String flowRecognitionCompleteP0P1Succeeded(String p0, String p1) {
    return '識別完成 · $p0/$p1 張成功';
  }

  @override
  String get flowCouldNotRecognizeAScore => '未能識別出成績';

  @override
  String get flowSongTitleNotRecognized => '未識別出曲名';

  @override
  String get flowAchievement2 => '達成率';

  @override
  String flowMatchSourceP0(String p0) {
    return '命中來源：$p0';
  }

  @override
  String get flowEditThisResult => '編輯此項';

  @override
  String get flowSyncing => '同步中...';

  @override
  String get flowSyncToDivingFish => '同步到水魚';

  @override
  String get flowSyncToLXNS => '同步到落雪';

  @override
  String flowCannotSyncYetP0(String p0) {
    return '暫不能同步：$p0';
  }

  @override
  String flowOtherCandidatesP0(String p0) {
    return '其它候選：$p0';
  }

  @override
  String get flowRecognizeAgain2 => '再次識別';

  @override
  String get flowUseAnotherImage => '換一張';

  @override
  String get flowClearAndChooseAgain => '清除重選';

  @override
  String get flowSignInToMaimaiScoreHubFirst => '先登錄 maimai Score Hub';

  @override
  String get flowResultRecognitionRequiresSignInRequestA =>
      '識別結算畫面需要登錄。在舞萌 | 中二公衆號請求並打開登入二維碼，掃描後把字符串填到下面。只用來認證，不會抓取或同步成績；登錄狀態保存在本機，之後不用重複登錄。';

  @override
  String get flowSigningIn2 => '登錄中…';

  @override
  String get flowDragCornersToSelectTheResultArea => '拖動角點框選成績區域';

  @override
  String get flowStoragePermissionIsNeededToSaveVersion =>
      '需要存儲權限才能保存版本圖，請在設置中開啓權限';

  @override
  String get flowImageSavedToGallery => '圖片已保存到相冊';

  @override
  String flowSaveFailedP0(String p0) {
    return '保存失敗：$p0';
  }

  @override
  String get flowSaveImage => '保存圖片';

  @override
  String get flowJapan => '日服';

  @override
  String get flowChina => '國服';

  @override
  String get flowJapanVersion => '日服版本';

  @override
  String get flowChinaVersion => '國服版本';

  @override
  String flowP0VersionsInReleaseOrderTapAn(String p0) {
    return '共 $p0 個版本，按發行順序排列。點擊版本圖可放大查看或保存。';
  }

  @override
  String flowP0VersionImageNotAvailableYet(String p0) {
    return '$p0，版本圖待補充';
  }

  @override
  String flowP0ViewVersionImage(String p0) {
    return '$p0，點擊查看版本圖';
  }

  @override
  String get flowImagePending => '圖片待補';

  @override
  String get flowVersionImageNotAvailableYet => '等待補充版本圖';

  @override
  String get flowTapToEnlarge => '點擊查看大圖';

  @override
  String get flowAboutThisComparison => '口徑說明';

  @override
  String get flowNoSongsInThisSection => '這一段裏沒有曲目';

  @override
  String get flowChinaDivingFishUpdateFrontier => '國服（水魚）更新前沿';

  @override
  String flowJapanDebutP0P1(String p0, String p1) {
    return '日服首發 $p0 · $p1';
  }

  @override
  String get flowFirstReleaseMeansTheJapanReleaseDate =>
      '「首次上線」顯示的是日服首發時間，不是國服上線時間。候選按首發日期識別，並從已確認待補批次補齊遺漏；日期缺失時才參考 ID，較小 ID 的新曲也會納入。';

  @override
  String flowExcludedP0SongsReleasedEarlyInChina(String p0, String p1) {
    return '已排除 $p0 首國服超前上線曲目（$p1）—— 它們會把前沿頂高，讓真正待補的曲子排不進候選。';
  }

  @override
  String flowP0P1JapanP2(String p0, String p1, String p2) {
    return '#$p0 · $p1 · 日服 $p2';
  }

  @override
  String get flowNoCachedLibraryYet => '曲庫還沒有緩存';

  @override
  String get flowThisPageUsesTheLocalDivingFish =>
      '本頁的數據來自本地曲庫（水魚 + union）。\n請先在首頁執行一次「拉取成績並更新數據」，把曲庫拉下來後再回來查看。';

  @override
  String get flowHowThisPageWorks => '這個頁面的口徑';

  @override
  String get flow1DataSources => '1. 數據來源';

  @override
  String get flowTheLocalLibraryCombinesDivingFishAll =>
      '本地曲庫 = 水魚（國服全量歌曲）+ union（全量歌曲）。合併時 union 獨有的那批會打上 isExtra 標記，本頁據此區分來源；已確認的國服超前上線名單優先於這個標記。所以整個頁面離線可用，與網絡無關。';

  @override
  String get flow2DefiningTheUpdateFrontier => '2. 更新前沿怎麼定';

  @override
  String get flowRegularChinaSongsInDivingFishAre =>
      '先篩出水魚曲庫裏的國服常規曲，再按首發日期從新到舊排列，第一首作爲「國服最新」。日期缺失或格式異常時參考 ID，所以這條前沿近似等於「國服已經追到哪」。\n宴會場（6 位 id）與 maidata 追加曲不參與判定。\n國服**超前上線**的曲目（國服先於日服上，id 卻排最新）也不參與 —— 它們會把前沿頂高，讓真正待補的曲子排不進候選。';

  @override
  String get flow3CompletingTheCandidateList => '3. 候選怎麼補齊';

  @override
  String get flowStartWithUnionOnlyRegularSongsUsing =>
      '先取 union 獨有的常規曲，以前沿的日服首發日期作爲參考起點；如果已確認待補批次中仍有更早的未收錄曲目，起點下移至該批最早日期。\n· 首發不早於起點的曲目都納入，包含同一天以及 ID 較小的歌曲；\n· 日期缺失或異常時才按 ID 判斷，已確認待補曲始終保留；\n· 早於起點的舊曲單獨列出，不據此斷定區域獨佔；候選只是參考，實際更新以官方公告爲準。';

  @override
  String get flow4WhatFirstReleaseMeans => '4. 「首次上線」是什麼時間';

  @override
  String get flowTheDebutDatesFromDivingFishAnd =>
      '水魚與 union 提供的首發日期都是**日服**時間，不是國服上線時間 —— 這也是「曲目詳情頁顯示首次上線、卻看不出國服上沒上」的原因。';

  @override
  String get flowUpdateDataTemporarilyUnavailable => '暫時讀不到更新數據';

  @override
  String get flowRetry => '重試';

  @override
  String get flowReleaseContents => '配信內容';

  @override
  String get flowCouldNotLoadReleaseDataRetry => '配信數據讀取失敗，重試';

  @override
  String get flowNoContentDetails => '暫無內容明細';

  @override
  String flowP0OtherItemsNotShown(String p0) {
    return '其餘 $p0 項未列出';
  }

  @override
  String get flowLXNSMaimaiDXScoreTracker => '落雪咖啡屋 maimai DX 查分器';

  @override
  String get flowPreviousMonthWithUpdates => '上一個有更新的月份';

  @override
  String flowChooseYearAndMonthCurrentP0P1(String p0, String p1) {
    return '選擇年月，當前 $p0 年 $p1 月';
  }

  @override
  String flowP0P1(String p0, String p1) {
    return '$p0 年 $p1 月';
  }

  @override
  String get flowReleaseRecordOnly => '僅有配信記錄';

  @override
  String flowP0UpdatesP1Songs(String p0, String p1) {
    return '$p0 次更新 $p1 首歌曲';
  }

  @override
  String get flowNextMonthWithUpdates => '下一個有更新的月份';

  @override
  String get flowRelease => '配信';

  @override
  String flowP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '$p0 月 $p1 日$p2$p3';
  }

  @override
  String flowP0Songs(String p0) {
    return '，$p0 首歌曲';
  }

  @override
  String get flowReleaseRecorded => '，有配信記錄';

  @override
  String get flowNotReleasedYet => '  尚未上線';

  @override
  String get flowReleaseRecord => '配信記錄';

  @override
  String flowP0SongsP1Charts(String p0, String p1) {
    return '$p0 首歌曲 $p1 張譜面';
  }

  @override
  String flowMonthP0(String p0) {
    return '$p0 月';
  }

  @override
  String get flowChooseYearAndMonth => '選擇年月';

  @override
  String flowYearP0(String p0) {
    return '$p0 年';
  }

  @override
  String get flowNoData => '暫無數據';

  @override
  String flowLvP0P1SongsP2Played(String p0, String p1, String p2) {
    return 'Lv.$p0\n共 $p1 首\n已玩 $p2 首';
  }

  @override
  String flowLvP0P1P2Songs(String p0, String p1, String p2) {
    return 'Lv.$p0 $p1 (共 $p2 首)';
  }

  @override
  String get flowFilterTitleBackgroundColors => '篩選稱號底色';

  @override
  String get flowChooseMultipleColors => '可同時選擇多個底色';

  @override
  String get flowApply => '應用';

  @override
  String get flowCacheClearedReloading => '緩存已清除，重新加載數據中...';

  @override
  String get flowCouldNotClearCache => '清除緩存失敗';

  @override
  String get flowSearchCollectibleNamesDescriptionsOrIDs => '搜索收藏品名稱、描述或 ID';

  @override
  String get flowSongRequirements => '有歌曲要求';

  @override
  String get flowBackgroundColor => '底色';

  @override
  String get flowIDDescending => 'ID 倒序';

  @override
  String get flowIDAscending => 'ID 正序';

  @override
  String flowP0Items(String p0) {
    return '$p0 個';
  }

  @override
  String get flowHasUnlockRequirements => '有達成條件';

  @override
  String get flowNoMatchingCollectibles => '未找到匹配的收藏品';

  @override
  String get flowClearCacheAndReload => '清除緩存並重新加載';

  @override
  String get flowPermissionRequired => '權限不足';

  @override
  String get flowStoragePermissionIsNeededToSaveImages =>
      '需要存儲權限才能保存圖片到相冊，請在設置中開啓權限';

  @override
  String get flowExcludedSongs => '條件外排除曲目';

  @override
  String flowP0SongsExcludedFromRequirements(String p0) {
    return '共 $p0 首，不計入所需條件';
  }

  @override
  String get flowSongList => '歌曲列表';

  @override
  String flowP0SongsTotal(String p0) {
    return '總計 $p0 首歌曲';
  }

  @override
  String flowTranslatedFromP0ByBaiduSLanguage(String p0) {
    return '由百度大模型翻譯自$p0';
  }

  @override
  String get flowTranslateToChinese => '翻譯爲中文';

  @override
  String get flowSaving2 => '保存中';

  @override
  String get flowSaveToGallery => '保存到相冊';

  @override
  String get flowCopyLink => '複製鏈接';

  @override
  String get flowDescription => '描述';

  @override
  String get flowUnlockRequirements => '所需條件';

  @override
  String flowP0Details(String p0) {
    return '$p0詳情';
  }

  @override
  String get flowCollectibleNotFound => '未找到收藏品信息';

  @override
  String get flowCouldNotRefreshData => '刷新數據失敗';

  @override
  String flowQQP0HasNotAuthorizedThisApp(String p0) {
    return 'QQ $p0 尚未授權本應用，請稍後在「賬號與同步」中完成授權';
  }

  @override
  String get flowAuthorizationNeeded => '需要完成授權';

  @override
  String get flowThisQQHasNotAuthorizedTheApp =>
      '該 QQ 尚未授權本應用，已打開授權頁；授權完成後請重新刷新';

  @override
  String get flowThisQQHasNotAuthorizedTheApp2 =>
      '該 QQ 尚未授權本應用，請在瀏覽器中打開授權頁完成綁定';

  @override
  String flowCouldNotRefreshDataP0(String p0) {
    return '刷新數據失敗：$p0';
  }

  @override
  String get flowSigningOutOfDivingFish => '正在登出水魚賬號…';

  @override
  String get flowEnterYourDivingFishUsernameAndPassword => '請輸入水魚用戶名和密碼';

  @override
  String get flowCouldNotLinkDivingFishTryAgain => '綁定水魚賬號失敗，請稍後重試';

  @override
  String get flowSyncSucceededRefreshingLocalData => '同步成功！正在刷新本地數據...';

  @override
  String get flowExportFailedTryAgain => '導出失敗，請稍後重試';

  @override
  String get flowPreparingSync => '準備同步...';

  @override
  String flowP0ScoresSentToDivingFishSign(String p0) {
    return '同步完成！$p0 條成績已推送到水魚\n（需先登錄水魚才能自動刷新本地數據）';
  }

  @override
  String get flowSyncCancelled => '同步已取消';

  @override
  String get flowEnterUsernameAndPassword => '請輸入用戶名和密碼';

  @override
  String flowWelcomeP0P1(String p0, String p1) {
    return '歡迎，$p0$p1';
  }

  @override
  String get flowAdvancedDataRefreshInProgress => '正在刷新數據（高級）...';

  @override
  String get flowRefreshingData => '正在刷新數據...';

  @override
  String flowCouldNotLoadAccountDetailsP0(String p0) {
    return '獲取賬號信息失敗 ($p0)';
  }

  @override
  String get flowNickname => '暱稱';

  @override
  String get flowVersionTitle => '牌子';

  @override
  String get flowRatingRank => 'Rating段位';

  @override
  String get flowLinkedQQ => '綁定QQ';

  @override
  String get flowChannelID => '頻道ID';

  @override
  String get flowBeginner => '初學者';

  @override
  String get flow1stDan => '一段';

  @override
  String get flow2ndDan => '二段';

  @override
  String get flow3rdDan => '三段';

  @override
  String get flow4thDan => '四段';

  @override
  String get flow5thDan => '五段';

  @override
  String get flow6thDan => '六段';

  @override
  String get flow7thDan => '七段';

  @override
  String get flow8thDan => '八段';

  @override
  String get flow9thDan => '九段';

  @override
  String get flow10thDan => '十段';

  @override
  String get flowShin1stDan => '真初段';

  @override
  String get flowShin2ndDan => '真二段';

  @override
  String get flowShin3rdDan => '真三段';

  @override
  String get flowShin4thDan => '真四段';

  @override
  String get flowShin5thDan => '真五段';

  @override
  String get flowShin6thDan => '真六段';

  @override
  String get flowShin7thDan => '真七段';

  @override
  String get flowShin8thDan => '真八段';

  @override
  String get flowShin9thDan => '真九段';

  @override
  String get flowShin10thDan => '真十段';

  @override
  String get flowShinKaiden => '真皆傳';

  @override
  String get flowUraKaiden => '裏皆傳';

  @override
  String get flowRefreshingMaidata => '正在刷新maidata...';

  @override
  String flowCouldNotOpenQQGroupIDP0(String p0) {
    return '沒能跳轉到 QQ，羣號 $p0 已複製到剪貼板，可在 QQ 裏搜索加入';
  }

  @override
  String get flowSongSearchFailedTheLibraryMayNot => '歌曲搜索失敗，曲庫可能還沒加載好';

  @override
  String get flowPreparingToReadCabinetPlayCount => '準備讀取機臺遊玩次數…';

  @override
  String get flowSigningOutOfDivingFish2 => '正在登出水魚賬號...';

  @override
  String get flowStartQRSyncFromHome => '請從首頁的同步入口開始掃碼同步';

  @override
  String get flowStartSyncFromHome => '請從首頁的同步入口開始同步';

  @override
  String get flowEnterYourPersonalKeyAboveToEnable => '填好上面的個人 key 後就可以開啓';

  @override
  String flowNoP0AccountYetSignInThrough(String p0) {
    return '還沒有$p0賬號，請先到「綁定與授權管理」登錄並刷新數據';
  }

  @override
  String get flowSyncCredentialsReady => '同步憑據已就緒';

  @override
  String get flowLinkTheCabinetIdentityAboveToEnable => '綁定上方的機臺身份後就可以開啓';

  @override
  String get flowCouldNotReadSyncCredentialsTryAgain => '同步憑據讀取失敗，請重試';

  @override
  String get flowCouldNotReadAutoSyncStatusTry => '自動同步狀態讀取失敗，請重試';

  @override
  String get flowLinkCabinetIdentityAboveFirst => '請先在上方綁定機臺身份';

  @override
  String get flowSyncSetupIncomplete => '同步配置待完善';

  @override
  String flowAccountEndingInP0(String p0) {
    return '賬號尾號 $p0';
  }

  @override
  String get flowStatusNotConfirmedYet => '狀態暫未確認';

  @override
  String flowP0QueueUserPositionP1(String p0, String p1) {
    return '$p0排隊 · 用戶第 $p1 位';
  }

  @override
  String get flowEnabledWaitingForSchedule => '已開啓 · 等待定時執行';

  @override
  String get flowSyncing2 => '正在同步';

  @override
  String get flowPreviousRoundNoRunYet => '上輪 · 暫無執行記錄';

  @override
  String get flowPreviousRoundUpToDateNoUpload => '上輪已是最新 · 無需上傳';

  @override
  String flowPreviousRoundCompleteSubmittedP0(String p0) {
    return '上輪已完成 · 提交 $p0 條';
  }

  @override
  String flowPreviousRoundIncompleteP0(String p0) {
    return '上輪未完成$p0';
  }

  @override
  String flowSubmittedP0(String p0) {
    return ' · 已提交 $p0 條';
  }

  @override
  String flowPreviousRoundP0(String p0) {
    return '上輪 · $p0';
  }

  @override
  String get flowLoadingStatistics => '統計加載中';

  @override
  String get flowUpdateFailed => '更新失敗';

  @override
  String get flowUpdatesEvery3Seconds => '每 3 秒更新';

  @override
  String get flowQueuedUsers => '排隊人數';

  @override
  String get flowPendingTasks => '待處理任務';

  @override
  String get flowProcessing2 => '處理中';

  @override
  String get flowProcessedUsers => '已處理用戶';

  @override
  String get flowSuccessfulUsers => '成功用戶';

  @override
  String get flowFailedUsers => '失敗用戶';

  @override
  String flowSubmittedP0P1(String p0, String p1) {
    return '已提交 $p0 條$p1';
  }

  @override
  String flowSkippedP0UnsupportedCharts(String p0) {
    return '，跳過 $p0 條不支持的譜面';
  }

  @override
  String flowConfirmedP0Submitted(String p0) {
    return '（已確認提交 $p0 條）';
  }

  @override
  String get flowWaitingForScheduledRun => '等待定時執行';

  @override
  String get flowWaitingToBeScheduled => '等待安排';

  @override
  String get flowEnterACabinetLoginQRCodeFirst => '請先填寫機臺登入二維碼';

  @override
  String get flowLinkFailedCheckTheQRHasNot => '綁定失敗，請確認二維碼未過期後重試';

  @override
  String get flowEnterYourPersonalKeyFirst => '請先填寫個人 key';

  @override
  String get flowAccountChangedRefreshThisPageAndEnter => '賬號已變化，請刷新頁面後重新填寫';

  @override
  String get flow1SignInThroughMeSignIn =>
      '① 在「我的 → 綁定與授權管理」登錄水魚，輸入你的 Diving-Fish 水魚賬號密碼以獲取 ImportToken。\n② 打開「成績導入憑據 → 水魚 成績導入Token」，點擊複製。\n③ 回到這裏粘貼並保存。';

  @override
  String get flowQuickSyncing => '正在快速同步…';

  @override
  String get flowCheckingAWMCGateway => '正在檢查 AWMC 網關...';

  @override
  String flowAWMCGatewayUnavailableP0SyncCancelledNo(String p0) {
    return 'AWMC 網關當前不可用（$p0），已取消同步、未消耗 Token';
  }

  @override
  String flowSyncingToP0ThroughAWMCGateway(String p0) {
    return '正在通過 AWMC 網關同步到$p0...';
  }

  @override
  String flowP0ScoresAreUpToDateNo(String p0) {
    return '$p0成績已是最新，無需上傳';
  }

  @override
  String flowQuickSyncCompleteSubmittedP1ChangedScores(String p0, String p1) {
    return '快速同步完成，已向$p0提交 $p1 條變化成績';
  }

  @override
  String flowP0ScoresTotal(String p0) {
    return '共 $p0 條成績';
  }

  @override
  String get flowSentToDivingFishThroughAWMCGateway => '已通過 AWMC 網關推送到水魚';

  @override
  String get flowExportedToLXNSThroughAWMCGateway => '已通過 AWMC 網關導出到落雪';

  @override
  String flowSyncCompleteP0P1(String p0, String p1) {
    return '同步完成！$p0$p1';
  }

  @override
  String get flowNoCachedDivingFishImportTokenSignIn =>
      '本機還沒有緩存水魚 ImportToken：請先用線路2（maimai Score Hub）登錄並同步一次，它會自動把 ImportToken 存到本機。';

  @override
  String get flowNoCachedLXNSPersonalAPIKeySync =>
      '本機還沒有緩存落雪個人 API 密鑰：請先同步一次並填好密鑰（會保存在本機）。';

  @override
  String get flowReadingCabinetPlayCount => '正在讀取機臺遊玩次數…';

  @override
  String get flowEndpoint => '接口';

  @override
  String get flowResult => '結果';

  @override
  String get flowBusinessOperationSucceeded => '業務成功';

  @override
  String flowUpstreamMessageTruncatedFullLengthP0Characters(String p0) {
    return '上游 msg 過長已截斷（完整 $p0 字符）';
  }

  @override
  String get flowDuration => '耗時';

  @override
  String get flowBilling => '計費';

  @override
  String get flowGetThisTokenFromTheAWMCConsole =>
      '令牌來自 AWMC 控制檯（api.wmc.pub），形如 gw_xxxx。\n\n⚠️ 令牌等同於你的賬戶操作權限與餘額，請勿截圖、勿粘貼到聊天/公開倉庫。若懷疑泄露，請立即到控制檯吊銷並重新生成。';

  @override
  String get flowTokenStaysOnThisDeviceCanBe => '令牌保存在本機（可隨時清除），不會隨備份導出。';

  @override
  String get flowEnterCabinetQRCode => '輸入機臺二維碼';

  @override
  String get flowUsedOnlyForThisOperationThenDiscarded =>
      '本次輸入只用於這一次操作，用完即棄：不保存、不緩存；下一次操作會重新問你一次。';

  @override
  String get flowUse => '使用';

  @override
  String get flowThisKeyIsSentOnlyWithThis =>
      '該密鑰只會隨本次請求發送給 AWMC 網關轉發，不會保存在本機。';

  @override
  String get flowContinue => '繼續';

  @override
  String get flowTokenCost => 'Token 消耗';

  @override
  String flowP0ChargedOnlyOnSuccess(String p0) {
    return '$p0（成功才扣）';
  }

  @override
  String get flowNoTokenSpent => '不消耗';

  @override
  String get flowReversible => '可撤銷';

  @override
  String get flowYesUploadAgainToOverwrite => '可以（重新上傳即可覆蓋）';

  @override
  String get flowNo => '不可以';

  @override
  String get flowIUnderstandTheEffectsAboveAndConfirm =>
      '我已確認上述影響，並確認這是我自己賬號的二維碼';

  @override
  String get flowWrite => '寫入';

  @override
  String flowImportingScoresWaitingP0Seconds(String p0) {
    return '正在導入成績…已等待 $p0 秒';
  }

  @override
  String get flowImportFailed => '導入失敗';

  @override
  String get flowScoresAreUpToDateNoUpload => '成績已是最新，無需上傳';

  @override
  String flowQuickSyncCompleteSubmittedP0ChangedScores(String p0) {
    return '快速同步完成，已提交 $p0 條變化成績';
  }

  @override
  String flowImportCompleteAddedP0UpdatedP1(String p0, String p1) {
    return '導入完成！新增 $p0 / 更新 $p1';
  }

  @override
  String flowSkippedP0(String p0) {
    return ' / 跳過 $p0';
  }

  @override
  String flowP0Seconds(String p0) {
    return '（$p0 秒）';
  }

  @override
  String flowP0ChartsAreNotYetInAWMC(String p0) {
    return '；$p0 條譜面 AWMC NET 暫未收錄';
  }

  @override
  String flowP0Account(String p0) {
    return '$p0賬號';
  }

  @override
  String get flowNotLinked => '未綁定';

  @override
  String get flowThenChooseRegisterUnderQuickActionsOn => '，點擊右側“快捷操作”區域的“註冊”。';

  @override
  String get flowFollowThePageInstructionsToRegisterA => '隨頁面引導填寫信息，即可註冊水魚賬號。';

  @override
  String get flowAfterSigningInOpenEditProfileAt =>
      '登錄後點頁面右上角的“編輯個人資料”，按下面的說明設置：';

  @override
  String get flowScoreImportTokenRotateItUsingThe =>
      '成績導入 Token：必須輪換！點 Token 右邊的刷新圖標即可，否則無法在 App 內登錄。';

  @override
  String get flowLinkedQQRequiredAvoidUsingTheSame =>
      '綁定 QQ 號：必須填寫。如果有小號，儘量不要和小號重複。';

  @override
  String get flowNicknameRecommendedWithoutOneTheAppSaves =>
      '暱稱：建議填寫。不填的話，App 內會默認以“shuiyu:QQ 號”的形式保存。';

  @override
  String get flowChannelIDAndRankNoSpecificRequirements =>
      '綁定頻道 ID 和段位：沒有特別要求。';

  @override
  String get flowDisablePreventPublicAPIsFromUsingMy => '“禁止公開接口使用我的成績”：必須關閉。';

  @override
  String get flowDisableMaskingScoresForNonWebQueries =>
      '“對非網頁查詢的成績使用掩碼”：建議關閉，開啓掩碼會影響排行榜排名。';

  @override
  String get flowRememberToSaveAfterMakingChanges => '全部改好後，記得點“保存”。';

  @override
  String get flowThenChooseNewUserRegistrationInThe =>
      '，點擊左側邊欄的“新用戶註冊”或頁面中間處的“註冊 maimai DX 查分器賬號”。';

  @override
  String get flowFollowThePageInstructionsToRegisterAn =>
      '隨頁面引導填寫信息，即可註冊落雪咖啡屋賬號。';

  @override
  String get flowAfterSigningInOpenAccountDetailsIn =>
      '登錄後在側邊欄點“賬號詳情”，再點頁面上方的“第三方應用”：';

  @override
  String get flowOAuthInMeRefreshDataChooseLXNS =>
      'OAuth 授權：在 App 的“我的 → 數據刷新 → 拉取成績並更新數據 / 拉取成績並更新數據（高級）”對話框裏把數據源切換到落雪，按引導完成授權。授權後，這裏的 OAuth 應用列表會出現 ChiffonMai。';

  @override
  String get flowPersonalAPIKeyResetItThenPaste =>
      '個人 API 密鑰：點“重置 API 密鑰”，然後到 App 的“我的 → 成績導入憑據”，下滑找到“落雪 API 密鑰”並填入。';

  @override
  String get flowYouCanAlsoVisitChiffonChuFromThe =>
      '也歡迎支持一下中二查歌，在“首頁遊玩 → 出勤”的輪播圖裏可以跳轉過去。';

  @override
  String get flowMessage => '私聊 ';

  @override
  String get flowPrivatelyOrFollowTheseStepsInA => '，或在有機器人的羣中，依次完成以下步驟：';

  @override
  String get flowSendTheSGWCMAIDStringOrMaimaiQR =>
      '按提示發送 SGWCMAID 字符串或舞萌二維碼，等機器人回覆上傳完成就好了。';

  @override
  String get flowAndConfigureTheseSettings => '，按下面的說明設置：';

  @override
  String get flowEnableMakeMyScoresPublicOrScores => '“公開我的成績”：必須開啓，否則無法獲取成績。';

  @override
  String get flowImportTokenRegenerateItThenPasteIt =>
      'Import-Token：點“重新生成”輪換，然後到 App 的“我的 → 賬號與授權 → 成績導入憑據”，在對話框裏下滑到“AWMC 成績導入 Token”並填入。';

  @override
  String get flowRotatingATokenReplacesTheOldOne =>
      '注意：已有 Token 時，輪換會覆蓋之前的 Token。輪換後請在 App 內手動更新，否則無法同步成績。';

  @override
  String get flowJoin => '加入 ';

  @override
  String get flowCouldNotOpenQQAWMCGroup1 =>
      '無法打開 QQ，已複製 AWMC 交流 1 羣的羣號，請在 QQ 中搜索加入';

  @override
  String get flowCouldNotOpenQQAWMCGroup2 =>
      '無法打開 QQ，已複製 AWMC 交流 2 羣的羣號，請在 QQ 中搜索加入';

  @override
  String get flowCloseImage => '關閉圖片';

  @override
  String get flowTheAppNeedsYourLinkedQQBefore =>
      '讀取水魚成績前，App 要先從水魚讀出你賬號上綁定的 QQ 號。\n請到「系統 → 登錄水魚」完成登錄後再回來刷新。';

  @override
  String get flowTheAppIdentifiesYourDivingFishAccount =>
      'App 用 QQ 號來識別你的水魚賬號，而你賬號裏的「綁定 QQ 號」是空的，\n所以現在讀不到成績。這不是登錄出了問題，只是少填了一個字段。';

  @override
  String get flow1OpenDivingFishAndSignIn => '① 打開水魚查分器官網並登錄';

  @override
  String get flow2OpenEditProfileEnterLinkedQQ =>
      '② 進入「編輯個人資料」→ 填上「綁定 QQ 號」並保存';

  @override
  String get flow3ReturnAndTapISavedIt => '③ 回到這裏點「我已填好，重新讀取」';

  @override
  String get flowSignInToMaimaiScoreHubFirst2 => '需要先登錄 maimai Score Hub';

  @override
  String get flowPasteOrScanALoginQRCode => '請粘貼或掃描登入二維碼';

  @override
  String get flowUseALoginQRFromTheMaimai => '請使用舞萌|中二公衆號生成的登入二維碼';

  @override
  String get flowMaimaiScoreHubSignInFailedThe =>
      'maimai Score Hub 登錄失敗，二維碼可能已過期，請重新生成';

  @override
  String flowSignInFailedP0(String p0) {
    return '登錄失敗：$p0';
  }

  @override
  String get flowNoLXNSPersonalAPIKeySetConfigure =>
      '尚未設置落雪個人 API 密鑰，請先在「成績導入憑據」中設置';

  @override
  String get flowQuickSyncSupportsRoute1Only => '快速同步僅支持線路1';

  @override
  String get flowMaimaiScoreHubSessionExpiredSignIn =>
      'maimai Score Hub 登錄狀態已失效，請重新登錄後再使用線路2';

  @override
  String get flowSyncCompleteRefreshingLocalData => '同步完成，正在刷新本地數據...';

  @override
  String get flowLinkDivingFishToObtainAnImportToken =>
      '需要先綁定水魚賬號以獲取 ImportToken，請重新點擊「同步成績到水魚」完成綁定';

  @override
  String get flowDoneLocalDataRefreshed => '全部完成！本地數據已刷新';

  @override
  String get flowSyncComplete => '同步完成！';

  @override
  String flowP0ScoresSentToDivingFishData(String p0, String p1) {
    return '同步完成！$p0 條成績已推送到水魚\n刷新數據失敗：$p1';
  }

  @override
  String get flowDivingFishRoute2 => '水魚線路2';

  @override
  String get flowSyncingScores => '正在同步成績...';

  @override
  String get flowLXNSRoute2 => '落雪線路2';

  @override
  String get flowPreparingSync2 => '準備同步…';

  @override
  String get flowMultiPlatformRoute2 => '多端同步的線路2';

  @override
  String flowEnterANewQRForP0P1(String p0, String p1) {
    return '請爲$p0（$p1）輸入新的二維碼…';
  }

  @override
  String flowThisQRIsUsedOnlyForThis(String p0, String p1) {
    return '這張二維碼只用於$p0（$p1）的這一次請求；不能和其它目標用過的二維碼相同。';
  }

  @override
  String get flowDirectQRUpload => '二維碼直傳';

  @override
  String flowSyncingToP0P1(String p0, String p1) {
    return '正在同步到$p0（$p1）…';
  }

  @override
  String flowP0UpToDate(String p0) {
    return '$p0（成績已是最新）';
  }

  @override
  String flowP0QuickSyncUpdatedP1(String p0, String p1) {
    return '$p0（快速同步，更新 $p1 條）';
  }

  @override
  String flowP0Route1P1(String p0, String p1) {
    return '$p0（線路1）：$p1';
  }

  @override
  String flowP0Route1P1P2(String p0, String p1, String p2) {
    return '$p0（線路1）：$p1 $p2%';
  }

  @override
  String flowP0Route1(String p0) {
    return '$p0（線路1）';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub =>
      '未登錄 maimai Score Hub，已跳過水魚線路2同步';

  @override
  String flowDivingFishRoute2P0P1(String p0, String p1) {
    return '水魚（線路2）：$p0 $p1%';
  }

  @override
  String flowDivingFishP0(String p0) {
    return '水魚：$p0';
  }

  @override
  String flowDivingFishRoute2P0Scores(String p0) {
    return '水魚（線路2，$p0 條）';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub2 =>
      '未登錄 maimai Score Hub，已跳過落雪線路2同步';

  @override
  String flowLXNSP0(String p0) {
    return '落雪：$p0';
  }

  @override
  String flowLXNSRoute2P0P1(String p0, String p1) {
    return '落雪（線路2）：$p0 $p1%';
  }

  @override
  String flowLXNSRoute2P0Scores(String p0) {
    return '落雪（線路2，$p0 條）';
  }

  @override
  String get flowAWMCNETScoreImportTokenNotSet => '未設置 AWMC NET 成績導入 Token';

  @override
  String get flowCouldNotReadSavedCredentialsTryAgain => '無法讀取已保存的憑據，請重試。';

  @override
  String flowEnterP0(String p0) {
    return '請填寫$p0';
  }

  @override
  String get flowPersonalAPIKey => '個人 API 密鑰';

  @override
  String get flowEnterA512DigitQQID => '請填寫 5～12 位 QQ 號';

  @override
  String get flowCouldNotSaveQQID => '保存 QQ 失敗';

  @override
  String get flowSelectAtLeastOneSourceWithCredentials => '請至少選擇一個已具備憑據的數據源';

  @override
  String get flowLXNSAuthorizationCodeMissing => '未填寫落雪授權碼';

  @override
  String flowNoLookupIDObtainedForP0(String p0) {
    return '未拿到$p0的查詢標識';
  }

  @override
  String get flowStartingDataRefresh => '開始刷新數據...';

  @override
  String get flowDataRefreshComplete => '數據刷新完成';

  @override
  String get flowClearingCaches => '正在清除緩存...';

  @override
  String get flowRefreshingDataInParallel => '正在並行刷新數據...';

  @override
  String get flowSongDataRefreshed => '歌曲數據已刷新';

  @override
  String get flowDifficultyDataRefreshed => '難度數據已刷新';

  @override
  String get flowTagDataRefreshed => '標籤數據已刷新';

  @override
  String get flowUserDataRetrieved => '用戶數據已獲取';

  @override
  String get flowCollectibleDataRefreshed => '收藏品數據已刷新';

  @override
  String get flowAliasDataRefreshed => '別名數據已刷新';

  @override
  String get flowUnionDataRefreshed => 'Union 數據已刷新';

  @override
  String get flowCouldNotFetchDivingFishScores => '水魚成績獲取失敗';

  @override
  String get flowCalculatingRating => '正在計算Rating...';

  @override
  String get flowSavingData => '正在保存數據...';

  @override
  String flowUploadingSongRankingsP0P1(String p0, String p1) {
    return '上傳單曲排行榜 $p0/$p1...';
  }

  @override
  String get flowCouldNotRemoveLeaderboardEntries => '排行榜刪除失敗';

  @override
  String get flowAWMCNETScoresRetrieved => 'AWMC NET 成績已獲取';

  @override
  String get flowObtainingAccessToken => '正在換取訪問令牌...';

  @override
  String get flowRenewingAccessToken => '正在續期訪問令牌...';

  @override
  String get flowAuthorizationFailedCheckYourCode => '授權失敗，請檢查授權碼是否正確';

  @override
  String get flowLXNSAuthorizationExpiredEnterANewAuthorization =>
      '落雪授權已過期，請重新輸入授權碼';

  @override
  String get flowAuthorizedRefreshingDataInParallel => '授權成功，正在並行刷新數據...';

  @override
  String get flowPreparingLXNSData => '準備落雪數據';

  @override
  String get flowLXNSProfileRetrieved => '落雪玩家信息已獲取';

  @override
  String get flowLXNSScoresRetrieved => '落雪成績已獲取';

  @override
  String get flowCouldNotFetchLXNSProfileOrScores => '落雪玩家信息或成績獲取失敗';

  @override
  String get flowCouldNotConvertLXNSScores => '落雪成績轉換失敗';

  @override
  String get flowCalculatingBest50 => '正在計算 Best50 數據...';

  @override
  String get flowMissingSongDataCannotCalculateLXNSRating =>
      '缺少歌曲數據，無法計算落雪 Rating';

  @override
  String get flowInvalidBest50Data => 'Best50 數據異常';

  @override
  String get flowInvalidBest35Data => 'Best35 數據異常';

  @override
  String get flowInvalidBest15Data => 'Best15 數據異常';

  @override
  String flowP0CheckForInvalidData(String p0) {
    return '$p0，可能存在非法數據，請檢查';
  }

  @override
  String flowCouldNotUpdateLeaderboardDataP0(String p0) {
    return '排行榜數據更新失敗：$p0';
  }

  @override
  String flowLeaderboardUpdateErrorP0(String p0) {
    return '排行榜數據更新異常: $p0';
  }

  @override
  String get flowSongsAndCharts => '歌曲與譜面';

  @override
  String get flowTagsAndAliases => '標籤與別名';

  @override
  String get flowCollectibles => '收藏品';

  @override
  String get flowMetadataAndExtras => '元數據與輔助';

  @override
  String get flowNormal => '普通';

  @override
  String get flowQuick => '快速';

  @override
  String flowLoadingP0Statistics(String p0) {
    return '$p0統計加載中…';
  }

  @override
  String flowP0StatisticsUnavailable(String p0) {
    return '$p0統計不可用';
  }

  @override
  String flowP0Last100NoRecords(String p0) {
    return '$p0近100次 / 暫無記錄';
  }

  @override
  String flowP0Last100P1SamplesAvgP22(
      String p0, String p1, String p2, String p3) {
    return '$p0近100次 / $p1樣本 / 平均$p2 / 成功$p3';
  }

  @override
  String get flowAverageDuration => '平均時長';

  @override
  String get flowSuccessRate => '成功率';

  @override
  String get flowSuccessfulSamples => '成功樣本';

  @override
  String get flowLatestRun => '最近一次';

  @override
  String get flowStatusUnconfirmed => '狀態未確認';

  @override
  String get flowExpectedRetry => '預計重試';

  @override
  String get flowLastRun => '最近執行';

  @override
  String get flowRefreshPending => '待刷新';

  @override
  String get flowStatusRefreshFailedTapToViewOr =>
      '狀態刷新失敗，請點擊查看或重試；此前結果不代表本次查詢已確認';

  @override
  String get flowSyncStatusNotReadYet => '尚未讀取到同步狀態';

  @override
  String flowP0UserP1OfP2(String p0, String p1, String p2) {
    return '$p0用戶第 $p1 位 / $p2 人';
  }

  @override
  String flowPreviousRoundP02(String p0) {
    return '上輪：$p0';
  }

  @override
  String flowSuccessP0P1(String p0, String p1) {
    return '成功 · $p0 · $p1';
  }

  @override
  String flowFailedP0P1(String p0, String p1) {
    return '失敗 · $p0 · $p1';
  }

  @override
  String flowP0UserPositionP1(String p0, String p1) {
    return '$p0用戶第$p1位';
  }

  @override
  String flowSyncFailedP03(String p0) {
    return '同步失敗·$p0';
  }

  @override
  String get flowSyncSucceeded => '同步成功';

  @override
  String flowSyncSucceededP0(String p0) {
    return '同步成功·$p0';
  }

  @override
  String get flowCorrectTheDifficultyCombinationConstantsFirst =>
      '請先修正按難度組合的定數輸入';

  @override
  String flowSearchFailedP0(String p0) {
    return '搜索失敗：$p0';
  }

  @override
  String get flowAny => '不限';

  @override
  String get flowChooseACharter => '請選擇譜師';

  @override
  String get flowSelectCharter => '選擇譜師';

  @override
  String get flowSearchCharters => '搜索譜師';

  @override
  String get flowFilterByCharterName => '輸入譜師名稱篩選...';

  @override
  String get flowChooseAnArtist => '請選擇曲師';

  @override
  String get flowSelectArtist => '選擇曲師';

  @override
  String get flowSearchArtists => '搜索曲師';

  @override
  String get flowFilterByArtistName => '輸入曲師名稱篩選...';

  @override
  String flowP0Items2(String p0) {
    return '$p0 項';
  }

  @override
  String get flowByDifficulty => '按難度';

  @override
  String get flowConstant => '定數';

  @override
  String get flowVersion => '版本';

  @override
  String get flowGenre => '流派';

  @override
  String get flowNotes => '物量';

  @override
  String get flowTags => '標籤';

  @override
  String get flowCharter => '譜師';

  @override
  String get flowArtist => '曲師';

  @override
  String get flowSongID => '歌曲ID';

  @override
  String get flowSongTitle => '歌名';

  @override
  String get flowArtist2 => '藝術家';

  @override
  String get flowAlias => '別名';

  @override
  String get flowTakeAPhotoOrChooseAnImage => '拍照或從相冊選擇圖片';

  @override
  String get flowCropTheCoverArtInTheImage => '框選圖片裏的曲繪區域';

  @override
  String get flowRecognizeAndViewTheClosestSongs => '開始識別，查看最接近的曲目';

  @override
  String get flowTexture => '紋理';

  @override
  String get flowColor => '顏色';

  @override
  String get flowEnterANumber => '請輸入數字';

  @override
  String get flowCannotBeNegative => '不能爲負數';

  @override
  String flowMustNotExceedP0(String p0) {
    return '不得超過 $p0';
  }

  @override
  String flowDifficultyP0(String p0) {
    return '難度 $p0';
  }

  @override
  String get flowLocalLibraryIsEmptyRefreshItFrom => '本地曲庫爲空，無法定位曲目。請先到首頁刷新曲庫';

  @override
  String get flowNoSongMatchedTapEditThisResult => '沒匹配到曲目，點「編輯此項」手動指定';

  @override
  String get flowDifficultyNotRecognizedUTAGESyncIsUnsupported =>
      '難度識別不出來（宴會場譜面不支持同步）';

  @override
  String get flowNoChartInformationForThisSongIn => '曲庫裏這首歌沒有譜面信息';

  @override
  String flowDifficultyP0DoesNotExistOnlyP1(String p0, String p1) {
    return '這首歌沒有第 $p0 個難度（只有 $p1 個譜面）';
  }

  @override
  String get flowAchievementMissingTapEditThisResultTo => '缺少達成率，點「編輯此項」補上';

  @override
  String flowUpdatedOnLXNSP0(String p0) {
    return '已更新到落雪：$p0';
  }

  @override
  String flowSyncedToLXNSUnchangedP0(String p0) {
    return '已同步到落雪（無變化）：$p0';
  }

  @override
  String flowAchievementP0P1(String p0, String p1) {
    return '達成率 $p0% → $p1%';
  }

  @override
  String flowAchievementP0(String p0) {
    return '達成率 $p0%';
  }

  @override
  String flowDXScoreP0P1(String p0, String p1) {
    return 'DX分數 $p0 → $p1';
  }

  @override
  String flowDXScoreP0(String p0) {
    return 'DX分數 $p0';
  }

  @override
  String flowMaximumP0(String p0) {
    return '上限 $p0%';
  }

  @override
  String flowMaximumP02(String p0) {
    return '上限 $p0';
  }

  @override
  String get flowPhotographOrChooseAResultScreen => '拍照或從相冊選擇結算畫面';

  @override
  String get flowPhotographStraightAndClearlyForBetterRecognition =>
      '儘量拍正、拍清，識別更準';

  @override
  String get flowCheckResultsThenSyncToDivingFish => '覈對結果後可同步到水魚或落雪';

  @override
  String get flowStandard => '標準';

  @override
  String get flowConfidence => '置信度 —';

  @override
  String flowConfidenceP0(String p0) {
    return '置信度 $p0%';
  }

  @override
  String get flowCoverArt => '曲繪';

  @override
  String get flowTitle => '標題';

  @override
  String get flowSignInFailedTheQRMayHave => '登錄失敗，二維碼可能已過期，請重新生成';

  @override
  String get flowAllSongs => '全量';

  @override
  String get flowInChina => '國服已上';

  @override
  String get flowPendingRelease => '待上線';

  @override
  String get flowNotIncluded => '未收錄';

  @override
  String get flowNextUpdateCandidates => '下次更新候選';

  @override
  String get flowOlderSongsMissingInChina => '國服未收錄舊曲';

  @override
  String get flowUTAGE => '宴會場';

  @override
  String get flowChinaRegularSongs => '國服常規曲';

  @override
  String get flowEarlyChinaReleases => '國服超前上線';

  @override
  String get flowNoMissingRegularSongsInTheCurrent => '當前參考範圍內沒有未收錄的常規曲。';

  @override
  String flowSortedByIDNotReleaseOrderOfficial(String p0) {
    return '按 ID 升序展示，順序不代表上線先後；實際更新以官方公告爲準。$p0';
  }

  @override
  String get flowTheseSongsPredateTheReferenceStartOr =>
      '這些曲早於候選參考起點，或缺少日期且 ID 較小，可能是區域限定、聯動獨佔或尚未補入的舊曲；不代表以後不會上線。';

  @override
  String get flowUTAGEDoesNotFollowVersionUpdatesListed =>
      '宴會場不隨版本更新，列在這裏僅供參考。';

  @override
  String get flowRegularDivingFishChinaSongsNewestDebut =>
      '水魚（國服）的常規曲，按首發日期從新到舊排列 —— 第一首就是本頁的「更新前沿」。';

  @override
  String get flowTheseSongsReachedChinaBeforeJapanTheir =>
      '這些是**國服先於日服**上線的曲子：國服已經有了，id 卻排在最新。它們不能當前沿（會把真正待補的那批頂出候選），所以單獨列在這裏。';

  @override
  String flowVersionsInvolvedP0(String p0) {
    return '\n涉及版本：$p0';
  }

  @override
  String flowP0P1Songs(String p0, String p1) {
    return '$p0 $p1 首';
  }

  @override
  String get flowChartDateSource => '譜面日期來源：';

  @override
  String get flowReleaseDataSource => '配信數據來源：';

  @override
  String get flowUpdatesOnThisDay => '當天更新';

  @override
  String flowP0P1P2(String p0, String p1, String p2) {
    return '$p0 月 $p1 日 周$p2';
  }

  @override
  String get flowAll => '全部';

  @override
  String get flowPlayed => '已遊玩';

  @override
  String get flowUnplayed => '未遊玩';

  @override
  String flowP0Types(String p0) {
    return '$p0 種';
  }

  @override
  String get flowThisCollectibleHasNoImage => '該收藏品沒有圖片';

  @override
  String flowCouldNotSaveImageP0(String p0) {
    return '保存圖片失敗: $p0';
  }

  @override
  String get flowThisCollectibleHasNoImageLink => '該收藏品沒有圖片鏈接';

  @override
  String get flowLinkCopied => '鏈接已複製到剪貼板';

  @override
  String get flowCouldNotCopyLink => '複製鏈接失敗';

  @override
  String get flowRequiredDifficulty => '所需難度';

  @override
  String get flowMinimumAchievement => '所需最低達成率';

  @override
  String get flowRequiredNoteSpeed => '所需遊玩流速';

  @override
  String get flowRequiredCombo => '所需連擊';

  @override
  String get flowRequiredSync => '所需同步';

  @override
  String get flowJapaneseEnglish => '日語+英語';

  @override
  String get flowEnglish => '英語';

  @override
  String get flowJapanese => '日語';

  @override
  String flowP0Seconds2(String p0) {
    return '$p0 秒';
  }

  @override
  String flowP0Minutes(String p0) {
    return '$p0 分鐘';
  }

  @override
  String flowP0MinP1Sec(String p0, String p1) {
    return '$p0 分 $p1 秒';
  }

  @override
  String get flowJustNow => '剛剛';

  @override
  String get flowWaitingForUpstreamQuota => '等待上游配額恢復';

  @override
  String get flowWaitingForUpstreamService => '等待上游服務恢復';

  @override
  String get flowWaitingForUpstreamGateway => '等待上游網關恢復';

  @override
  String get flowWaitingForUpstreamProcessing => '等待上游處理';

  @override
  String flowP0RetryAroundP1(String p0, String p1) {
    return '$p0，預計 $p1 重試';
  }

  @override
  String get flowProcessingTimedOut => '處理超時';

  @override
  String get flowQuotaInsufficient => '配額不足';

  @override
  String get flowUpstreamUnavailable => '上游不可用';

  @override
  String get flowUploadIncomplete => '上傳未完成';

  @override
  String get flowUploadCredentialsExpired => '上傳憑據失效';

  @override
  String get flowCouldNotReadTargetScores => '目標成績讀取失敗';

  @override
  String get flowCouldNotReadLibrary => '曲庫讀取失敗';

  @override
  String get flowCouldNotReadCabinetData => '機臺讀取失敗';

  @override
  String get flowNoScoresToSync => '沒有可同步成績';

  @override
  String get flowInterruptedByServiceRestart => '服務重啓中斷';

  @override
  String get flowProcessingWindowEnded => '處理窗口已結束';

  @override
  String get flowRoundDataExpired => '本輪數據已失效';

  @override
  String get flowTaskCancelled => '任務已取消';

  @override
  String get flowPreparingQuickSync => '正在準備快速同步…';

  @override
  String flowElapsedP0P1(String p0, String p1) {
    return '處理已用 $p0$p1';
  }

  @override
  String flowLimitP0Min(String p0) {
    return ' / 上限 $p0 分鐘';
  }

  @override
  String get flowWaitingForProcessingToStart => '等待開始處理';

  @override
  String flowCabinetDataCollectedP02(String p0) {
    return '機臺數據採集 $p0';
  }

  @override
  String flowUploadingP0P1P2(String p0, String p1, String p2) {
    return '上傳 $p0/$p1 條$p2';
  }

  @override
  String flowReadingCabinetScoresPageP0(String p0) {
    return '讀取機臺成績 · 第 $p0 頁';
  }

  @override
  String flowSubmittedP02(String p0) {
    return '提交 $p0 條';
  }

  @override
  String flowSkippedP0UnsupportedCharts2(String p0) {
    return '跳過 $p0 條不支持的譜面';
  }

  @override
  String flowUnchangedP0(String p0) {
    return '未變化 $p0 條';
  }

  @override
  String flowP0TookP1(String p0, String p1) {
    return '$p0 · 耗時 $p1';
  }

  @override
  String get flowAccountAndSync => '賬號與同步';

  @override
  String get flowAccountAndSyncHint => '管理賬號、授權狀態與成績同步';

  @override
  String get flowFishAccount => '水魚賬號';

  @override
  String get flowReadingAccountState => '正在讀取賬號狀態';

  @override
  String get flowNotSignedIn => '未登錄';

  @override
  String get flowSignInFishAgain => '重新登錄水魚';

  @override
  String get flowUseFishForToken => '使用水魚賬號獲取 ImportToken';

  @override
  String get flowScoreSync => '成績同步';

  @override
  String get flowSyncSourcesHint => '從舞萌數據源同步到第三方服務';

  @override
  String get flowImportTokenNotSet => '未設置成績導入 Token';

  @override
  String get flowTitleCollectible => '稱號';

  @override
  String get flowIconCollectible => '頭像';

  @override
  String get flowPlateCollectible => '姓名框';

  @override
  String get flowFrameCollectible => '背景';

  @override
  String get flowAwmcGateway => 'AWMC 網關';

  @override
  String get flowNormalSource => '國服曲庫';

  @override
  String get flowExtraSource => '非國服曲庫';

  @override
  String get flowQrPrivateNotice =>
      '與「同步成績」用的是同一串二維碼內容（SGWCMAID 開頭），可直接從微信/相機識別結果裏複製。\n\n⚠️ 該二維碼等同於機臺登錄憑據，只能用於你自己的賬號。';

  @override
  String get flowReadingExistingScoresOnTheTargetAccount => '正在讀取目標賬號已有成績…';

  @override
  String get flowCheckingChartsSupportedByTheTarget => '正在覈對目標源支持的譜面…';

  @override
  String flowReadingCabinetScoresP0PagesRead(String p0) {
    return '正在讀取機臺成績，已讀取 $p0 頁';
  }

  @override
  String get flowReadingCabinetScores => '正在讀取機臺成績…';

  @override
  String get flowPreparingChartsComboAndSyncMarkers => '正在整理譜面與連擊、同步標記…';

  @override
  String flowUploadingScoresP0P1P2(String p0, String p1, String p2) {
    return '正在上傳成績（$p0 / $p1 條$p2）';
  }

  @override
  String flowP0Submitted(String p0) {
    return '，已提交 $p0 條';
  }

  @override
  String get flowSyncComplete2 => '同步完成';

  @override
  String get flowWaitingForUpstreamQuota2 => '等待上游配額恢復…';

  @override
  String get flowWaitingForUpstreamService2 => '等待上游服務恢復…';

  @override
  String flowReadingExistingScoresOnP0(String p0) {
    return '正在讀取 $p0 已有成績…';
  }

  @override
  String flowCheckingChartsSupportedByP0(String p0) {
    return '正在覈對 $p0 支持的譜面…';
  }

  @override
  String get flowComparingChangesAndPreparingUploads => '正在比對差異並整理上傳內容…';

  @override
  String flowUploadingToP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '正在上傳到$p0：$p1 / $p2 條$p3';
  }

  @override
  String get flowValidatingQRCode2 => '正在驗證二維碼...';

  @override
  String get flowCreatingScoreFetchTask => '正在創建抓取任務...';

  @override
  String get flowBotIsSendingAFriendRequest => 'Bot 正在發送好友申請...';

  @override
  String get flowFriendAddedCreatingScoreFetchTask => '好友已添加，正在創建抓取任務...';

  @override
  String get flowSyncingToDivingFish => '正在同步到水魚...';

  @override
  String flowSyncCompleteP0ScoresSynced(String p0) {
    return '同步完成！共同步 $p0 條成績';
  }

  @override
  String get flowSubmittingQRCode => '正在提交二維碼...';

  @override
  String get flowSyncingToLXNS => '正在同步到落雪...';

  @override
  String flowSyncCompleteP0ScoresSyncedToLXNS(String p0) {
    return '同步完成！共同步 $p0 條成績到落雪';
  }

  @override
  String get flowAcceptTheFriendRequestOnNETOr => '等待你在 NET / 機臺上通過好友申請';

  @override
  String flowFetchingScoresP0P1(String p0, String p1) {
    return '正在抓取成績... ($p0/$p1)';
  }

  @override
  String get flowFetchingScores => '正在抓取成績...';

  @override
  String get flowFetchingFriendList => '正在拉取好友列表...';

  @override
  String get flowTaskQueuedWaitingForProcessing => '任務已排隊，等待處理...';

  @override
  String get flowPreviewingData => '正在預覽數據...';

  @override
  String get flowSigningIn3 => '正在登錄...';

  @override
  String flowReadingChartScoresP0Records(String p0) {
    return '正在獲取譜面成績... ($p0 條)';
  }

  @override
  String get flowReadingChartScores => '正在獲取譜面成績...';

  @override
  String get flowSigningOut => '正在登出...';

  @override
  String get flowCleaningUp => '正在清理...';

  @override
  String flowSavingScoresP0Records(String p0) {
    return '正在保存成績... ($p0 條)';
  }

  @override
  String get flowSavingScores => '正在保存成績...';

  @override
  String flowReadingComboAndSyncMarkersFromP0(String p0) {
    return '正在讀取$p0已有的連擊與同步標記…';
  }

  @override
  String flowCheckingChartsSupportedByP02(String p0) {
    return '正在覈對$p0支持的譜面…';
  }

  @override
  String get flowReadingCabinetScoresForThisRound => '正在讀取本輪機臺成績…';

  @override
  String flowUpdatingP0ScoresP1P2(String p0, String p1, String p2) {
    return '正在更新$p0成績（$p1/$p2）…';
  }

  @override
  String flowQuickSyncCompleteUpdatedP0Scores(String p0) {
    return '快速同步完成：更新 $p0 條成績';
  }

  @override
  String flowSkippedP0UnchangedScores(String p0) {
    return '，跳過 $p0 條未變化成績';
  }

  @override
  String flowP0ChartsUnmatchedOrUnsupported(String p0) {
    return '，$p0 條譜面未匹配或目標源不支持';
  }

  @override
  String get flowCheckingAWMCGateway2 => '正在檢查 AWMC 網關…';

  @override
  String get flowQuicklyReadingCabinetScores => '正在快速讀取機臺成績…';

  @override
  String get flowClearSignIn => '清除目前登入狀態';

  @override
  String flowBoundQq(String qq) {
    return '目前綁定 QQ：$qq';
  }

  @override
  String get flowStatsNotUpdated => '尚未更新';

  @override
  String get flowStatsJustUpdated => '剛剛更新';

  @override
  String flowStatsSecondsAgo(String count) {
    return '$count 秒前更新';
  }

  @override
  String flowStatsMinutesAgo(String count) {
    return '$count 分鐘前更新';
  }

  @override
  String flowStatsHoursAgo(String count) {
    return '$count 小時前更新';
  }

  @override
  String get flowCacheNeverExpires => '永不過期';

  @override
  String get flowCacheNoTimestamp => '無緩存時間戳';

  @override
  String get flowCacheAbsent => '無緩存';

  @override
  String get flowCacheExpiredPrefix => '已過期';

  @override
  String flowCacheExpired(String duration) {
    return '已過期 $duration';
  }

  @override
  String flowCacheRemaining(String duration) {
    return '剩餘 $duration';
  }

  @override
  String flowCacheDaysHours(String days, String hours) {
    return '$days 天 $hours 小時';
  }

  @override
  String flowCacheDays(String days) {
    return '$days 天';
  }

  @override
  String flowCacheHoursMinutes(String hours, String minutes) {
    return '$hours 小時 $minutes 分鐘';
  }

  @override
  String flowCacheHours(String hours) {
    return '$hours 小時';
  }

  @override
  String flowCacheMinutes(String minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get flowRankingShowIdentity => '展示暱稱與頭像';

  @override
  String get flowRankingIdentityHint => '關閉時顯示匿名用戶和默認頭像；自選頭像仍會保存並同步。';

  @override
  String get flowRankingShowBrief => '展示排行榜簡要信息';

  @override
  String get flowRankingBriefHint => '公開稱號、裝扮、等級與 Best 成績；需登錄或完成賬號身份驗證。默認關閉。';

  @override
  String get flowCacheFishSongs => '歌曲數據（水魚）';

  @override
  String get flowCacheUnionSongs => '歌曲數據（Union）';

  @override
  String get flowCacheDifficulties => '難度數據';

  @override
  String get flowCacheTags => '標籤數據';

  @override
  String get flowCacheAlias1 => '別名數據源1';

  @override
  String get flowCacheAlias2 => '別名數據源2';

  @override
  String get flowCacheAlias3 => '別名數據源3';

  @override
  String get flowCacheTitles => '收藏品-稱號';

  @override
  String get flowCacheIcons => '收藏品-頭像';

  @override
  String get flowCachePlates => '收藏品-姓名框';

  @override
  String get flowCacheFrames => '收藏品-背景';

  @override
  String get flowCacheUnionMetadata => 'Union 元數據';

  @override
  String get flowCacheFishDescription => '全量歌曲主庫（diving-fish）';

  @override
  String get flowCacheUnionDescription => '補充獨有歌曲（godserver）';

  @override
  String get flowCacheConstantDescription => '譜面定數（diving-fish chart_stats）';

  @override
  String get flowCacheTagDescription => 'DXRating 譜面標籤';

  @override
  String get flowCacheTitleDescription => '落雪稱號';

  @override
  String get flowCacheIconDescription => '落雪頭像';

  @override
  String get flowCachePlateDescription => '落雪姓名框';

  @override
  String get flowCacheFrameDescription => '落雪背景';

  @override
  String get flowCacheMetadataDescription => 'cn/jp 可遊玩地區等';

  @override
  String get flowCacheMaidataDescription => '譜面追加輔助（追加列表 + 完整 maidata）';

  @override
  String get flowSongDetails => '歌曲詳情';

  @override
  String get flowExpandOrCollapseSongInformation => '展開或收起歌曲信息';

  @override
  String get flowFavorited => '已收藏';

  @override
  String get flowAddToAFavoritesFolder => '收藏到收藏夾';

  @override
  String flowCreatedP0AndAddedThisChart(String p0) {
    return '已創建收藏夾「$p0」並將當前譜面加入';
  }

  @override
  String get flowNoFavoritesFoldersYet => '還沒有收藏夾';

  @override
  String get flowCreateAFavoritesFolderFirst => '請先創建收藏夾';

  @override
  String flowP0Charts(String p0) {
    return '$p0 個譜面';
  }

  @override
  String get flowNewFavoritesFolder => '新建收藏夾';

  @override
  String get flowEnterAFolderName => '請輸入收藏夾名稱';

  @override
  String get flowCreate => '創建';

  @override
  String get flowPause => '暫停';

  @override
  String get flowPlay => '播放';

  @override
  String flowP0P1SBufferedAhead(String p0, String p1) {
    return '$p0 已向前緩衝 $p1 秒';
  }

  @override
  String get flowCouldNotLoadThePVCheckYour => 'PV 加載失敗，請檢查網絡後重試';

  @override
  String get flowBackToSongDetails => '返回歌曲詳情';

  @override
  String get flowCopiedToClipboard => '已複製到剪貼板';

  @override
  String get flowExportZIPZip => '導出壓縮包 (.zip)';

  @override
  String get flowMaidataTxtCoverArtAndAudioIn => 'maidata.txt + 曲繪 + 音源，通用譜麪包';

  @override
  String get flowExportAstroDXChartAdx => '導出 AstroDX 譜面 (.adx)';

  @override
  String get flowOpenInAstroDXToInstallTheChart => '用 AstroDX 打開即可自動安裝譜面';

  @override
  String get flowChooseWhereToSaveTheChartPackage => '選擇譜麪包保存位置';

  @override
  String get flowChooseWhereToSaveTheAstroDXChart => '選擇 AstroDX 譜面保存位置';

  @override
  String flowExportFailedP0(String p0) {
    return '導出失敗: $p0';
  }

  @override
  String get flowSelectDifficulty => '選擇難度';

  @override
  String get flowRenderedChartsAreForReferenceAndMay =>
      '渲染出的譜面僅供參考，不代表官方譜面。對於高密度譜面，請勿頻繁拖動進度條，以免造成應用閃退或卡死。';

  @override
  String get flowLoadAudio => '加載音頻';

  @override
  String get flowTurnOffToLoadTheChartWithout => '取消勾選可直接加載譜面，跳過音源下載';

  @override
  String get flowFetchingChartConstants => '獲取定數中...';

  @override
  String flowSongIDP0(String p0) {
    return '歌曲ID $p0';
  }

  @override
  String get flowChartCode => '譜面代碼';

  @override
  String get flowCopy => '複製';

  @override
  String get flowExporting => '導出中';

  @override
  String get flowExport => '導出';

  @override
  String get flowRender => '渲染';

  @override
  String flowVideoGeneratedTapSaveToPhotosOn(String p0, String p1, String p2) {
    return '視頻已生成，請在導出頁點擊“保存到相冊”：$p0×$p1 · $p2 MB';
  }

  @override
  String flowLoadedMaidataWithP0Difficulties(String p0) {
    return '已加載maidata，解析到 $p0 個難度';
  }

  @override
  String get flowUnsupportedEncodingUseUTF8OrShift =>
      '讀取失敗: 文件編碼不受支持，請使用UTF-8或Shift-JIS編碼';

  @override
  String flowCouldNotOpenTheFilePickerP0(String p0) {
    return '無法打開文件選擇器: $p0';
  }

  @override
  String get flowCoverArtSelected => '已選擇曲繪';

  @override
  String get flowCoverArtSelectedUsingItsOriginalPath => '已選擇曲繪（使用原始路徑）';

  @override
  String flowCouldNotOpenTheImagePickerP0(String p0) {
    return '無法打開圖片選擇器: $p0';
  }

  @override
  String get flowAudioSelected => '已選擇音源';

  @override
  String get flowAudioSelectedUsingItsOriginalPath => '已選擇音源（使用原始路徑）';

  @override
  String flowCouldNotOpenTheAudioPickerP0(String p0) {
    return '無法打開音頻選擇器: $p0';
  }

  @override
  String flowTheFileForP0IsMissingAnd(String p0) {
    return '「$p0」的文件已不存在，已從列表移除';
  }

  @override
  String flowCouldNotParseAgainP0(String p0) {
    return '重新解析失敗：$p0';
  }

  @override
  String get flowDeleteThisRecord => '刪除這條記錄';

  @override
  String flowRemoveP0FromRecentlyParsedChartsAnd(String p0) {
    return '將從「最近解析」中移除「$p0」，並刪除它的存檔文件。';
  }

  @override
  String get flowDelete => '刪除';

  @override
  String get flowCouldNotReadThisFileTryAnother => '讀不到這個文件的內容，請換一個來源重試';

  @override
  String flowImportFailedP0(String p0) {
    return '導入失敗：$p0';
  }

  @override
  String get flowNoMaidataTxtFoundThisIsNot => '這個壓縮包裏沒找到 maidata.txt，不是有效的譜麪包';

  @override
  String get flowUnsupportedMaidataTxtEncodingUseAUTF =>
      'maidata.txt 編碼不受支持，請使用 UTF-8 或 Shift-JIS 編碼的譜麪包';

  @override
  String flowImportedAllThreeFilesFromP0Found(String p0, String p1) {
    return '已從 $p0 導入三件套，解析到 $p1 個難度';
  }

  @override
  String flowImportedMaidataP0DifficultiesNoP1In(String p0, String p1) {
    return '已導入 maidata（$p0 個難度）；包內沒有$p1，可手動補選';
  }

  @override
  String get flowRecentlyParsed => '最近解析';

  @override
  String get flowTapToParseTheArchivedFilesAgain => '點擊即可按存檔重新解析；長按可刪除';

  @override
  String get flowSelectAMaidataFileFirst => '請先選擇maidata文件';

  @override
  String get flowNoValidDifficultiesFound => '未找到有效難度';

  @override
  String get flowTurnOffToLoadTheChartWithout2 => '取消勾選可直接加載譜面，跳過音源加載';

  @override
  String get flowSelectionCleared => '已清除選擇';

  @override
  String get flowCustomChart => '上傳自定義譜面';

  @override
  String get flowImportAChartPackage => '從譜麪包導入';

  @override
  String get flowSelectAnAdxOrZipPackageTo =>
      '選擇一個 .adx 或 .zip 譜麪包，自動解出 maidata.txt / 曲繪 / 音源';

  @override
  String get flowExtracting => '正在解壓...';

  @override
  String get flowSelectChartPackage => '選擇譜麪包';

  @override
  String get flowOrSelectTheThreeFilesSeparately => '或分別選擇下面三個文件';

  @override
  String get flowSelectMaidataTxt => '選擇maidata.txt';

  @override
  String get flowRequiredATextFileContainingChartData => '必須選擇，包含譜面數據的txt文件';

  @override
  String get flowSelectCoverArt => '選擇曲繪圖片';

  @override
  String get flowOptionalChartBackgroundImagePNGJPG => '可選，譜面背景圖片（png/jpg）';

  @override
  String get flowSelectAudio => '選擇音源文件';

  @override
  String get flowOptionalChartMusicMP3WAVOGG => '可選，譜面背景音樂（mp3/wav/ogg）';

  @override
  String get flowParsedDifficulties => '解析到的難度:';

  @override
  String get flowStartPlayback => '開始播放';

  @override
  String get flowInstructions => '使用說明:';

  @override
  String get flowOption1SelectAnAdxOrZip =>
      '方式一：點「選擇譜麪包」直接選一個 .adx / .zip，三件套一次填好';

  @override
  String get flowOption2TapARecentlyParsedEntry =>
      '方式二：點「最近解析」裏的記錄，一鍵重新解析之前用過的譜麪包';

  @override
  String get flowOption3SelectMaidataTxtCoverArt =>
      '方式三：分別選擇 maidata.txt、曲繪、音源三個文件';

  @override
  String get flow1MaidataTxtIsRequiredTheOther => '1. maidata.txt 爲必選，其餘兩個可留空';

  @override
  String get flow2DifficultiesAreDetectedAutomatically => '2. 系統會自動解析譜面中的難度';

  @override
  String get flow3SelectADifficultyThenStartPlayback => '3. 選擇想要渲染的難度後即可開始播放';

  @override
  String flowSelectedP0(String p0) {
    return '已選擇: $p0';
  }

  @override
  String get flowChooseAgain2 => '重新選擇';

  @override
  String get flowChooseFile => '選擇文件';

  @override
  String get flowChooseWhereToSaveTheSong => '選擇歌曲保存位置';

  @override
  String get flowDownloaded => '下載成功';

  @override
  String get flowGoToCurrentSong => '定位到正在播放';

  @override
  String get flowRebuildLibrary => '重建曲庫';

  @override
  String get flowMusicPlayerSettings => '隨身聽設置';

  @override
  String get flowShowFloatingPlayerAfterLeavingThisPage => '退出隨身聽頁面時顯示懸浮球';

  @override
  String get flowWhenOffLeavingTheMusicPlayerWill => '關閉後，離開隨身聽頁面也不會重新顯示懸浮球';

  @override
  String get flowSearchTitleArtistGenreAliasBPMID =>
      '搜索曲名 / 藝術家 / 流派 / 別名 / BPM / id';

  @override
  String get flowNowPlaying => '正在播放';

  @override
  String get flowPaused => '已暫停';

  @override
  String get flowUnknownArtist => '未知藝術家';

  @override
  String get flowDownloadSong => '下載歌曲';

  @override
  String get flowAddToPlayNext => '加入下次想玩';

  @override
  String get flowAddedToPlayNext => '已加入下次想玩';

  @override
  String get flowPlayMusic => '播放音樂';

  @override
  String get flowNothingPlayingYet => '還沒有在放的音樂';

  @override
  String get flowPreparingAudio => '正在準備音源…';

  @override
  String get flowPrevious2 => '上一首';

  @override
  String get flowNext2 => '下一首';

  @override
  String get flowChooseSortOrder => '選擇排序方式';

  @override
  String get flowDXScoreRate => 'DX分數達成率';

  @override
  String get flowAchievementFilter => '達成率篩選';

  @override
  String get flowComboSyncFilter => '連擊/同步篩選';

  @override
  String get flowAnyOptionWithinAGroupMatchesWhen => '同組內滿足任意一項，連擊和同步都選時需同時滿足';

  @override
  String get flowCloseSearch => '關閉搜索';

  @override
  String get flowSearchSongTitleOrConstant => '搜索曲名或定數';

  @override
  String get flowNoCachedDataFound => '沒有找到緩存數據';

  @override
  String get flowTapASegmentOrStatisticToFilter => '點色塊或統計項篩選 · 共 ';

  @override
  String get flowEntries => ' 條';

  @override
  String flowFilteredByP0TapAgainToClear(String p0) {
    return '已篩選 $p0 · 再點取消';
  }

  @override
  String flowP0P1EntriesTapToFilter(String p0, String p1) {
    return '$p0 $p1 條，點按篩選';
  }

  @override
  String get flowComboSync => '連擊/同步';

  @override
  String get flowPerPage => '每頁顯示';

  @override
  String flowP0Entries(String p0) {
    return '共 $p0 條';
  }

  @override
  String get flowList => '列表';

  @override
  String get flowUnknownSong => '未知歌曲';

  @override
  String get flowSelectMultipleAnySelectedOptionMatches => '可多選，滿足任意一項即可';

  @override
  String flowClearP0(String p0) {
    return '清除$p0';
  }

  @override
  String get flowQuickOptions => '快捷選項';

  @override
  String get flowCustomRange => '自定義範圍';

  @override
  String get flowExportAsImage => '導出爲圖片';

  @override
  String get flowSelectCategory => '選擇種類';

  @override
  String get flowLevel => '等級';

  @override
  String get flowNoChartDesignerDataFound => '沒有找到譜師數據';

  @override
  String get flowSelectVersion => '選擇版本';

  @override
  String get flowNoComposerDataFound => '沒有找到曲師數據';

  @override
  String get flowNoGenreDataFound => '沒有找到流派數據';

  @override
  String get flowSelectGenre => '選擇流派';

  @override
  String flowP0P1Songs2(String p0, String p1) {
    return '$p0 ($p1首)';
  }

  @override
  String get flowSelectLevel => '選擇等級';

  @override
  String get flowNoCompletedSongsYet => '暫無已完成歌曲';

  @override
  String get flowNoIncompleteSongs => '暫無未完成歌曲';

  @override
  String get flowStoragePermissionIsRequiredToExportImages =>
      '需要存儲權限才能導出圖片到相冊，請在設置中開啓權限';

  @override
  String get flowPersonalizedScores => '個性化成績';

  @override
  String flowExportFailedP02(String p0) {
    return '導出失敗：$p0';
  }

  @override
  String get flowCouldNotOpenTheAuthorizationPageLink => '無法打開授權頁，鏈接已複製到剪貼板';

  @override
  String get flowFetchingFriendDataAndComparing => '正在拉取好友數據並對比…';

  @override
  String flowCompareMyP0ScoresWithMyFriend(String p0) {
    return '用我的$p0成績，對比好友在這裏的成績';
  }

  @override
  String flowEnterYourFriendSP0(String p0) {
    return '輸入好友的$p0';
  }

  @override
  String get flowCompare => '開始對比';

  @override
  String get flowCompareWithAFriend => '和好友比比看';

  @override
  String flowEnterYourFriendSP0ToCompare(String p0, String p1) {
    return '輸入好友的$p0開始對比\n好友需要在$p1有數據';
  }

  @override
  String get flowClearHistory => '清空歷史';

  @override
  String get flowClearAllHistory => '確定要清空全部歷史記錄嗎？';

  @override
  String get flowPastComparisons => '歷史對比';

  @override
  String flowP0P1P2SongsInCommon(String p0, String p1, String p2) {
    return '$p0 · $p1 · 共同 $p2 首';
  }

  @override
  String get flowPrivate => '未公開';

  @override
  String get flowSameScore => '同分';

  @override
  String get flowMyCharts => '我的譜面';

  @override
  String get flowFriendSCharts => '好友譜面';

  @override
  String get flowSharedCharts => '共同譜面';

  @override
  String get flowAllDifficulties => '全部難度';

  @override
  String flowConstantHighToLowShowingP0P1(String p0, String p1) {
    return '按定數從高到低 · 顯示 $p0 / $p1';
  }

  @override
  String get flowNoMatchingCharts => '沒有符合條件的譜面';

  @override
  String flowLoadMoreP0P1(String p0, String p1) {
    return '加載更多（$p0 / $p1）';
  }

  @override
  String get flowTie => '平局';

  @override
  String get flowSelectFirstCharacter => '選擇首字';

  @override
  String flowP0SongsExcludedFromPlateProgress(String p0) {
    return '共 $p0 首，不計入牌子進度';
  }

  @override
  String flowP0P1P2Statistics(String p0, String p1, String p2) {
    return '$p0$p1($p2)統計';
  }

  @override
  String get flowRecommendationSettings => '推薦參數';

  @override
  String flowConstantsP0P1P2Results(String p0, String p1, String p2) {
    return '定數範圍 $p0 ~ $p1 · 共 $p2 條結果';
  }

  @override
  String get flowTargetRating => '目標 Rating';

  @override
  String get flowRecommend => '推薦';

  @override
  String get flowLoadingRecommendations => '正在加載推薦結果...';

  @override
  String get flowNoRecommendationsCheckTheRatingYouEntered =>
      '暫無推薦結果，請檢查Rating輸入是否正確';

  @override
  String flowCouldNotSaveHistoryP0(String p0) {
    return '保存歷史失敗：$p0';
  }

  @override
  String flowCouldNotDeleteDataPointP0(String p0) {
    return '刪除記錄點失敗：$p0';
  }

  @override
  String get flowLinkYourQQThroughSyncScoresTo =>
      'AWMC NET 還沒綁定 QQ，請先在「同步成績到 AWMC NET」入口綁定';

  @override
  String flowNoRatingRecordsForQQP0On(String p0) {
    return 'AWMC NET 上 QQ $p0 近 90 天沒有任何 Rating 記錄';
  }

  @override
  String flowSyncedRatingHistoryFromAWMCNETAdded(String p0) {
    return '已從 AWMC NET 同步 Rating 趨勢，新增 $p0 條';
  }

  @override
  String flowNoNewAWMCNETPointsP0Already(String p0) {
    return 'AWMC NET 沒有新數據點（$p0 條都已記錄過）';
  }

  @override
  String get flowSyncRatingHistoryFromAWMCNET => '從 AWMC NET 同步 Rating 趨勢';

  @override
  String get flowAddHistoryRecord => '添加歷史記錄';

  @override
  String flowCurrentSourceP0(String p0) {
    return '當前數據源：$p0';
  }

  @override
  String flowBaselinesForP0ChartsP1ScoreChanges(String p0, String p1) {
    return '已記錄 $p0 張譜面的成績基線 · $p1 次成績變化（曲目詳情頁裏，單譜的達成率 / DX分數曲線就畫在這些變化上）';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs(String p0) {
    return '水魚 / 落雪 / AWMC NET 按賬號分別記錄歷史。$p0（AWMC NET 數據源下可點右上角「雲同步」按鈕回填歷史趨勢）';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs2(String p0) {
    return '水魚 / 落雪 / AWMC NET 按賬號分別記錄歷史。$p0（歷史只能從現在開始攢：水魚與落雪都不提供歷史成績接口）';
  }

  @override
  String get flowHighest => '最高';

  @override
  String get flowDataPoints => '記錄點';

  @override
  String flowP0EntriesShowingTheLatest30(String p0) {
    return '共 $p0 條，顯示最近 30 條';
  }

  @override
  String get flowNoHistoryYet => '還沒有歷史數據';

  @override
  String get flowEachDataRefreshRecordsAPointAutomatically =>
      '每次「拉取成績並更新數據」都會順手記一筆，不需要額外操作。\n時間精確到秒；同一秒重複刷新會更新該點，不同時間的變化會分別保留。';

  @override
  String get flowAddRatingHistory => '添加 Rating 歷史';

  @override
  String get flowCurrentTheoreticalRating => '當前理論 Rating';

  @override
  String get flowBest35Optional => 'Best35（可選）';

  @override
  String get flowCurrentTheoreticalB35 => '當前理論 B35';

  @override
  String get flowBest15Optional => 'Best15（可選）';

  @override
  String get flowCurrentTheoreticalB15 => '當前理論 B15';

  @override
  String get flowAboutScoreImprovementHistory => '關於成績提升歷史';

  @override
  String get flowLocalScoreHistoryForThisAccount => '當前賬號的本地成績歷史';

  @override
  String get flowRecordingStartsAfterADataRefreshThe =>
      '刷新數據後開始記錄；首次無舊成績時僅建立基線。';

  @override
  String flowRecordedSinceP0SameDayChangesTo(String p0) {
    return '$p0 起記錄 · 同日同譜面自動合併';
  }

  @override
  String get flowCharts => '譜面';

  @override
  String get flowImprovement => '提升';

  @override
  String get flowChanges => '變化次數';

  @override
  String get flowRecordingRules => '記錄規則';

  @override
  String flowLoadMoreFromThisDayP0Charts(String p0) {
    return '加載當天更多記錄（剩餘 $p0 張）';
  }

  @override
  String get flowNoRatingsYet => '暫無評分記錄';

  @override
  String get flowNoCommentsYet => '暫無評論';

  @override
  String get flowNoBest50DataYet => '暫無Best50數據';

  @override
  String get flowReturnHomeAndTapRefreshData => '請返回首頁點擊“拉取成績並更新數據”按鈕獲取';

  @override
  String get flowTheoreticalRatingBest50 => '理論Rating Best50';

  @override
  String get flowSaveCurrentRecord => '保存當前記錄';

  @override
  String get flowHistory => '歷史記錄';

  @override
  String get flowAccountDataChangedReopenBest50BeforeSaving =>
      '賬號數據已更新，請重新打開 Best50 後保存';

  @override
  String flowBest50RecordSavedP0(String p0) {
    return 'Best50 記錄已保存 ($p0)';
  }

  @override
  String get flowBest50History => 'Best50 歷史記錄';

  @override
  String get flowNoSavedRecordsTapSaveCurrentRecord =>
      '暫無保存的記錄，點擊\"保存當前記錄\"按鈕保存';

  @override
  String flowTheoreticalRatingAverageP0(String p0) {
    return '理論 Rating（平均 $p0）';
  }

  @override
  String flowCurrentRatingAverageP0(String p0) {
    return '當前 Rating（平均 $p0）';
  }

  @override
  String get flowTheoretical => '理論值';

  @override
  String get flowAverageAchievementDXScoreRate => '平均達成率 / DX 分數達成率';

  @override
  String get flowTagStatistics => '標籤統計';

  @override
  String get flowTheoreticalBest50 => '理論 Best50';

  @override
  String get flowCalculatingFittedBest50 => '正在計算擬合Best50...';

  @override
  String get flowNoFittedBest50DataYet => '暫無擬合Best50數據';

  @override
  String flowFittedTotalRatingDifferenceFromBest50Average(String p0) {
    return '擬合總 Rating · 較 Best50（平均 $p0）';
  }

  @override
  String flowModeP0(String p0) {
    return '模式 $p0';
  }

  @override
  String get flowNoDataToExport => '沒有數據可導出';

  @override
  String flowCategoryChartDesigner50P0(String p0) {
    return '選擇類型: 譜師50 - $p0';
  }

  @override
  String flowCategoryVersion50P0(String p0) {
    return '選擇類型: 版本50 - $p0';
  }

  @override
  String flowCategoryGenre50P0(String p0) {
    return '選擇類型: 流派50 - $p0';
  }

  @override
  String flowCategoryStar50P0(String p0) {
    return '選擇類型: 星數50 - $p0';
  }

  @override
  String flowCategoryTag50P0(String p0) {
    return '選擇類型: 標籤50 - $p0';
  }

  @override
  String get flowCategoryRandom50 => '選擇類型: 隨機50';

  @override
  String get flowCategoryOverreach50 => '選擇類型: 越級50';

  @override
  String flowCategoryDifficulty50P0(String p0) {
    return '選擇類型: 難度50 - $p0';
  }

  @override
  String flowCategoryBestP0(String p0) {
    return '選擇類型: Best $p0';
  }

  @override
  String flowCategoryP0(String p0) {
    return '選擇類型: $p0';
  }

  @override
  String get flowChooseCategory => '選擇類型';

  @override
  String get flowNoVersionDataFound => '沒有找到版本數據';

  @override
  String get flowSelectStars => '選擇星數';

  @override
  String get flowGenerateBestN => '生成 Best N';

  @override
  String get flowEnterAnIntegerOf1OrMore => '請輸入 ≥ 1 的整數';

  @override
  String get flowNoTagDataFound => '沒有找到標籤數據';

  @override
  String get flowSelectTag => '選擇標籤';

  @override
  String get flowNoMatchingChartDesigners => '沒有找到符合條件的譜師數據';

  @override
  String flowP0P1Charts(String p0, String p1) {
    return '$p0 ($p1譜面)';
  }

  @override
  String get flowTotalCharts => '總譜面數';

  @override
  String get flowAverageRA => '平均RA值';

  @override
  String get flowInclusionMode => '包含關係模式';

  @override
  String get flowDrawAgain => '再抽一次';

  @override
  String flowNoChartDesigner50DataForP0(String p0) {
    return '暫無譜師50 - $p0 數據';
  }

  @override
  String flowNoVersion50DataForP0(String p0) {
    return '暫無版本50 - $p0 數據';
  }

  @override
  String flowNoGenre50DataForP0(String p0) {
    return '暫無流派50 - $p0 數據';
  }

  @override
  String flowNoStar50DataForP0(String p0) {
    return '暫無星數50 - $p0 數據';
  }

  @override
  String flowNoP0DataYet(String p0) {
    return '暫無$p0數據';
  }

  @override
  String get flowRefreshArcadePlayCountsFromMeBefore =>
      '請先在「我的」頁「刷新機臺遊玩次數」，再查看 PC50';

  @override
  String flowSelectTagP0(String p0) {
    return '選擇標籤: $p0';
  }

  @override
  String get flowCalculatingPersonalizedFittedBest50 => '正在計算個性化擬合Best50...';

  @override
  String get flowSelectATagFirst => '請先選擇一個標籤';

  @override
  String get flowSelectATagToShowYourTop =>
      '選擇標籤後，將顯示包含該標籤且有遊玩記錄\n在擬合定數下RA前50的譜面';

  @override
  String flowNoFittedBest50DataForTagP0(String p0) {
    return '暫無標籤\"$p0\"的擬合Best50數據';
  }

  @override
  String get flowNoMatchingPlayRecordsMayExistTry =>
      '該標籤可能沒有對應的遊玩記錄\n可嘗試更換其他標籤';

  @override
  String get flowChangeTag => '更換標籤';

  @override
  String flowFittedTotalRatingDifferenceFromThisTag(String p0) {
    return '擬合總 Rating · 較該標籤 Best50（平均 $p0）';
  }

  @override
  String get flowNoCachedPlayData => '暫無遊玩數據緩存';

  @override
  String get flowIdealRatingRaiseNonSSSScoresTo =>
      '理想 Rating · 非 SSS+ 成績升到上一檔的下限';

  @override
  String get flowOriginalRating => '原 Rating';

  @override
  String get flowNewEntries => '新進榜';

  @override
  String flowNewEntriesThisTimeP0Songs(String p0) {
    return '本次新進榜（$p0 首）';
  }

  @override
  String get flowNoNewEntriesTheSameChartsRemain => '無新歌進榜（升檔後榜單成員不變）';

  @override
  String flowConstantP0RAP1P2(String p0, String p1, String p2) {
    return '定數 $p0 · RA $p1 → $p2';
  }

  @override
  String get flowNoData2 => '無數據';

  @override
  String flowSlotP0(String p0) {
    return '第 $p0 格';
  }

  @override
  String get flowNotSelected => '未選擇';

  @override
  String flowP0P1ConstantP2(String p0, String p1, String p2) {
    return '$p0 · $p1 · 定數 $p2';
  }

  @override
  String get flowSelectASongFirst => '請先選擇歌曲';

  @override
  String flowInvalidAchievementExceedsP0(String p0) {
    return '非法數據：達成率超過 $p0%';
  }

  @override
  String flowInvalidDXScoreExceedsTheChartMaximum(String p0) {
    return '非法數據：DX 分數超過譜面上限 $p0';
  }

  @override
  String get flowClearThisCard => '清空本卡';

  @override
  String get flowNoCardsFilledInYet => '還沒有填寫任何卡片';

  @override
  String flowByP0(String p0) {
    return '按$p0';
  }

  @override
  String get flowClearAll => '清空全部';

  @override
  String get flowClearAll50SlotsThisCannotBe => '確定要清空全部 50 個卡位嗎？此操作不可撤銷。';

  @override
  String get flowCustomBest50TotalRA => '自定義 Best50 總 RA';

  @override
  String flowCurrentOrderP0ClearedWhenCardsChange(String p0) {
    return '當前排序：$p0（卡片變動後自動清除）';
  }

  @override
  String get flowAutoSort => '一鍵排序';

  @override
  String get flowTapToFillIn => '點擊填寫';

  @override
  String flowP0Passed(String p0) {
    return '/ $p0 已合格';
  }

  @override
  String flowRedPassP0(String p0) {
    return '赤合格 $p0';
  }

  @override
  String flowFailedP0(String p0) {
    return '不合格 $p0';
  }

  @override
  String get flowDanCourseSongs => '段位曲目';

  @override
  String get flowDanCertification => '段位認定';

  @override
  String get flowMyChallenges => '我的挑戰';

  @override
  String get flowEstimatedResult => '預計結果';

  @override
  String get flowFailed2 => '不合格';

  @override
  String get flowPassed => '合格';

  @override
  String get flowTotalAchievement => '總達成率';

  @override
  String get flowRemainingLife => '剩餘血量';

  @override
  String flowSongP02(String p0) {
    return '曲目 $p0';
  }

  @override
  String get flowEstimatedMinimumLifeLoss => '預計最低扣血';

  @override
  String get flowLifeSettings => '血量設置';

  @override
  String get flowStartingLife => '初始血量';

  @override
  String get flowClearRecovery => '通關回復';

  @override
  String get flowNoDanDataFound => '未找到段位數據';

  @override
  String get flowYouAreOutsideTheTop100 => '抱歉，您不在前100名內';

  @override
  String flowP0Entries2(String p0) {
    return '$p0條';
  }

  @override
  String get flowNoRankingDataYet => '暫無排行數據';

  @override
  String get flowRefresh => '刷新';

  @override
  String get flowGoToMyRank => '跳轉到我的排名';

  @override
  String flowDifferenceFromBest50P0P1(String p0, String p1) {
    return '與Best50差值 $p0$p1';
  }

  @override
  String flowModeP02(String p0) {
    return '模式$p0';
  }

  @override
  String get flowDisclaimer => '免責聲明';

  @override
  String get flowThisLeaderboardIsForReferenceAndEntertainment =>
      '本排行榜數據僅供參考和娛樂使用，不代表任何官方立場或權威性排名。排名數據基於玩家自願上傳的遊戲數據，可能存在誤差或延遲。請理性看待排名結果，享受遊戲樂趣。';

  @override
  String get flowDoNotShowAgain => '不再提示';

  @override
  String flowDXScoreDisplayP0TapToSwitch(String p0) {
    return 'DX分數顯示方式：$p0（點擊切換）';
  }

  @override
  String get flowDXScoreRanking => 'DX分數榜';

  @override
  String get flowAchievementRanking => '達成率榜';

  @override
  String get flowNoOneIsRankedYetBeThe => '榜上無人哦，快來搶沙發！';

  @override
  String get flowYourPlayDataForThisChartAppears => '您的此譜面遊玩數據存在異常，請檢查!';

  @override
  String get flowChooseRankingType => '選擇排行榜類型';

  @override
  String get flowReverse => '反向';

  @override
  String get flowForward => '正向';

  @override
  String get flowShowingPreviouslySavedDataRefreshWhenConnected =>
      '當前展示上次保存的數據，聯網後可刷新。';

  @override
  String get flowNoLeaderboardDataYetTryRefreshingLater => '暫無排行榜數據，稍後刷新試試吧';

  @override
  String get flowBilibiliChartVideoViews => 'B站譜面確認播放量';

  @override
  String flowDifficultyP02(String p0) {
    return '難度: $p0';
  }

  @override
  String flowCurrentViewsP0(String p0) {
    return '當前播放量: $p0';
  }

  @override
  String flowBVIDP0(String p0) {
    return 'BV號: $p0';
  }

  @override
  String flowSourceP0(String p0) {
    return '來源: $p0';
  }

  @override
  String get flowLoadingViews => '正在加載播放量...';

  @override
  String get flowNoViewDataYet => '暫無播放量數據';

  @override
  String get flowEnterBVIDManually => '手動上傳 BV 號';

  @override
  String get flowIfViewsCannotBeFetchedAutomaticallyEnter =>
      '當自動獲取播放量失敗時，可手動輸入該歌曲譜面確認視頻的 BV 號';

  @override
  String get flowExampleBV1xx411c7mD => '例如: BV1xx411c7mD';

  @override
  String flowViewsP0(String p0) {
    return '播放量: $p0';
  }

  @override
  String flowP010000(String p0) {
    return '$p0萬';
  }

  @override
  String get flowCheckBVID => '校驗 BV 號';

  @override
  String get flowBVIDUploaded => 'BV 號已上傳';

  @override
  String get flowConfirmUpload => '確認上傳';

  @override
  String get flowChartScoreCard => '譜面成績卡';

  @override
  String get flowScoreShareCard => '成績分享卡片';

  @override
  String get flowSongInformation => '歌曲信息';

  @override
  String get flowSongInformationImage => '曲目信息圖片';

  @override
  String get flowStoragePermissionIsRequiredToSaveImages => '需要存儲權限才能保存圖片';

  @override
  String get flowCouldNotLoadCoverArt => '無法加載封面圖片';

  @override
  String get flowCoverArtSavedToPhotos => '曲繪已保存到相冊';

  @override
  String flowSaveFailedP02(String p0) {
    return '保存失敗: $p0';
  }

  @override
  String get flowPlayPV => '播放 PV';

  @override
  String get flowChooseHowToPlayThePV => '請選擇 PV 的播放方式';

  @override
  String get flowOpenBilibili => '前往 B 站';

  @override
  String get flowPlayInApp => 'APP 內播放';

  @override
  String get flowPleaseWait => '請稍候';

  @override
  String get flowLoadingRelatedCollectibles => '正在加載相關收藏品...';

  @override
  String get flowError => '錯誤';

  @override
  String get flowCouldNotLoadRelatedCollectiblesTryAgain => '獲取相關收藏品時出錯，請稍後重試';

  @override
  String get flowChartNotes => '譜面筆記';

  @override
  String get flowAddChartNotes => '添加譜面筆記';

  @override
  String get flowWriteYourNotesForThisChartHere =>
      '在這裏寫下你對這個譜面的筆記...\n例如：結尾的滑星要注意手順';

  @override
  String flowCreatedP0P1(String p0, String p1) {
    return '創建於: $p0$p1';
  }

  @override
  String flowUpdatedP0(String p0) {
    return '\n更新於: $p0';
  }

  @override
  String get flowConfirmDeletion => '確認刪除';

  @override
  String get flowDeleteTheNotesForThisChartThis => '確定要刪除這個譜面的筆記嗎？此操作不可撤銷。';

  @override
  String get flowRelatedCollectibles => '相關收藏品';

  @override
  String get flowNoCollectiblesLinkedToThisSong => '未找到與該歌曲相關的收藏品';

  @override
  String get flowRefreshDataOnTheHomePageTo => '請先在首頁刷新數據以獲取用戶身份';

  @override
  String get flowRatingSubmitted => '評分提交成功';

  @override
  String get flowCouldNotSubmitRating => '評分提交失敗';

  @override
  String get flowDeleteYourRating => '確定要刪除您的評分嗎？';

  @override
  String get flowRatingDeleted => '評分刪除成功';

  @override
  String get flowCouldNotDeleteRating => '評分刪除失敗';

  @override
  String get flowChartRating => '譜面評分';

  @override
  String flowP0Ratings(String p0) {
    return '($p0人評分)';
  }

  @override
  String get flowDistribution => '分佈';

  @override
  String get flowRatingsAreForReferencePleaseRateObjectively => '評分僅供參考，請客觀評價';

  @override
  String get flowRefreshRatings => '刷新評分';

  @override
  String get flowMyRecentRatings => '我的最近評分';

  @override
  String get flowMyRatingTapToEdit => '我的評分（點擊修改）';

  @override
  String get flowRateThisChart => '爲這個譜面評分';

  @override
  String get flowDeleteRating => '刪除評分';

  @override
  String get flowUpdate => '更新';

  @override
  String get flowSubmit => '提交';

  @override
  String get flowRefreshDataOnTheHomePageTo2 => '請在首頁刷新數據以獲取身份後再評分';

  @override
  String get flowNoRatingsYet2 => '暫無評分數據';

  @override
  String get flowRatingDistribution => '評分分佈';

  @override
  String flowP0Ratings2(String p0) {
    return '共 $p0 人評分';
  }

  @override
  String flowAverageP0(String p0) {
    return '均分 $p0';
  }

  @override
  String get flowSetYourIdentityFirst => '請先設置身份信息';

  @override
  String get flowCommentPosted => '評論發佈成功';

  @override
  String get flowCouldNotPostComment => '評論發佈失敗';

  @override
  String flowCouldNotPostCommentP0(String p0) {
    return '評論發佈失敗：$p0';
  }

  @override
  String get flowCannotDeleteIdentityInformationIsMissing => '無法刪除：身份信息缺失';

  @override
  String get flowDeleteThisComment => '確定要刪除這條評論嗎？';

  @override
  String get flowCommentDeleted => '評論刪除成功';

  @override
  String get flowCouldNotDeleteComment => '評論刪除失敗';

  @override
  String get flowComments => '評論';

  @override
  String get flowCommentsRefreshed => '已刷新評論';

  @override
  String get flowRefreshComments => '刷新評論';

  @override
  String get flowCommentsAreForReferencePleaseBeRespectful => '評論僅供參考，請文明發言';

  @override
  String get flowRefreshDataOnTheHomePageTo3 => '請在首頁刷新數據以獲取評論身份';

  @override
  String get flowEnterYourComment => '輸入您的評論內容...';

  @override
  String get flowPost => '發表';

  @override
  String get flowNoCommentsYetBeTheFirstTo => '暫無評論，快來發表第一條評論吧！';

  @override
  String get flowMe => '我';

  @override
  String get flowViewNotes => '查看筆記';

  @override
  String get flowAddNotes => '添加筆記';

  @override
  String get flowExportSongInformation => '導出歌曲信息';

  @override
  String get flowShareScore => '分享成績';

  @override
  String get flowEnlargeCoverArt => '放大麴繪';

  @override
  String get flowSwitchToDX => '切換 DX';

  @override
  String get flowSwitchToST => '切換 ST';

  @override
  String flowP0LevelP1(String p0, String p1) {
    return '$p0 等級 $p1';
  }

  @override
  String flowNoScoreForP0Yet(String p0) {
    return '還沒有 $p0 的成績';
  }

  @override
  String get flowPlayAndSyncToSeeYourScore => '打完同步一下就會顯示在這裏';

  @override
  String flowDXScoreMAXP0(String p0) {
    return 'DX分數（MAX -$p0）';
  }

  @override
  String get flowShowStarBonus => '顯示星級加成';

  @override
  String get flowShowPointsNeededForTheNextStar => '顯示距下一星還差多少';

  @override
  String get flowRatingPotential => '上分潛力';

  @override
  String get flowBasicInformation => '基礎信息';

  @override
  String get flowNoteDistribution => '物量分佈';

  @override
  String get flowBREAKDistribution => '絕贊分佈';

  @override
  String get flowNoGlobalGradeOrComboDistributionData => '這張譜面暫時沒有全站評級與連擊分佈數據';

  @override
  String get flowTAPGREATsAllBREAKsCriticalPerfect => '個 TAP GREAT（絕贊全 CP）';

  @override
  String get flowOpenCalculatorWithThisChartSNotes => '帶上這張譜面的物量與成績打開計算器';

  @override
  String get flowNoTagsYet => '暫無標籤';

  @override
  String get flowTagDataFrom => '標籤數據來源自 ';

  @override
  String get flowUnknownTag => '未知標籤';

  @override
  String get flowConstantHistory => '定數歷史';

  @override
  String get flowStarsDXScoreTable => '星數-DX分數對照表';

  @override
  String get flowStars => '星數';

  @override
  String get flowDXScore2 => 'DX分數';

  @override
  String get flowPlayers => '玩家';

  @override
  String get flowAchievementScoreTable => '達成率-得分對照表';

  @override
  String get flowScore => '得分';

  @override
  String get flowJudgmentAllowance => '容錯計算';

  @override
  String get flowNoteType => '音符類型:';

  @override
  String get flowShareOfTotalWeight => '佔總權重比例:';

  @override
  String get flowBREAKLossSoFar => '已打出的BREAK損失';

  @override
  String get flow50PointLosses => '50落數量';

  @override
  String get flowInvalid => '無效';

  @override
  String get flow100PointLosses => '100落數量';

  @override
  String get flow80GREATCount => '80%GREAT數量';

  @override
  String get flow60GREATCount => '60%GREAT數量';

  @override
  String get flow50GREATCount => '50%GREAT數量';

  @override
  String get flowGOODCount => 'GOOD數量';

  @override
  String get flowMISSCount => 'MISS數量';

  @override
  String get flowTotalBREAKLoss => 'BREAK總損失: ';

  @override
  String get flowRemainingBudgetSSS => '剩餘預算(SSS+): ';

  @override
  String get flowRemainingBudgetSSS2 => '剩餘預算(SSS): ';

  @override
  String get flowRemainingBudgetSS => '剩餘預算(SS+): ';

  @override
  String get flowRemainingBudgetSS2 => '剩餘預算(SS): ';

  @override
  String get flowGREATLoss => 'GREAT損失';

  @override
  String get flowGOODLoss => 'GOOD損失';

  @override
  String get flowMISSLoss => 'MISS損失';

  @override
  String get flowSSSGREATAllowance => 'SSS+容錯(GREAT)';

  @override
  String get flowSSSGOODAllowance => 'SSS+容錯(GOOD)';

  @override
  String get flowSSSMISSAllowance => 'SSS+容錯(MISS)';

  @override
  String flowP0(String p0) {
    return '$p0個';
  }

  @override
  String get flowSSSGREATAllowance2 => 'SSS容錯(GREAT)';

  @override
  String get flowSSSGOODAllowance2 => 'SSS容錯(GOOD)';

  @override
  String get flowSSSMISSAllowance2 => 'SSS容錯(MISS)';

  @override
  String get flowSSGREATAllowance => 'SS+容錯(GREAT)';

  @override
  String get flowSSGOODAllowance => 'SS+容錯(GOOD)';

  @override
  String get flowSSMISSAllowance => 'SS+容錯(MISS)';

  @override
  String get flowSSGREATAllowance2 => 'SS容錯(GREAT)';

  @override
  String get flowSSGOODAllowance2 => 'SS容錯(GOOD)';

  @override
  String get flowSSMISSAllowance2 => 'SS容錯(MISS)';

  @override
  String get flow50PointLoss => '50落損失';

  @override
  String get flow100PointLoss => '100落損失';

  @override
  String get flow80GREATLoss => '80%GREAT損失';

  @override
  String get flow60GREATLoss => '60%GREAT損失';

  @override
  String get flow50GREATLoss => '50%GREAT損失';

  @override
  String get flow0580GREATAllowance => '-0.5%容錯80%GREAT';

  @override
  String get flow0560GREATAllowance => '-0.5%容錯60%GREAT';

  @override
  String get flow0550GREATAllowance => '-0.5%容錯50%GREAT';

  @override
  String get flow05Allowance => '-0.5%容錯';

  @override
  String get flow180GREATAllowance => '-1%容錯80%GREAT';

  @override
  String get flow160GREATAllowance => '-1%容錯60%GREAT';

  @override
  String get flow150GREATAllowance => '-1%容錯50%GREAT';

  @override
  String get flow1Allowance => '-1%容錯';

  @override
  String get flowGradeDistributionReferenceOnly => '評級分佈(僅供參考)';

  @override
  String get flowComboDistributionReferenceOnly => '連擊分佈(僅供參考)';

  @override
  String get flowInTheOrderBPMMarkersAppearIn => '按當前譜面中 BPM 標記的出現順序';

  @override
  String get flowChangeIndex => '變化序號';

  @override
  String get flowPlayOnBilibili => 'B站播放';

  @override
  String get flowPlayableRegions => '可遊玩地區';

  @override
  String get flowParsingDataUnavailable => '暫缺解析數據';

  @override
  String get flowExcludesSLIDETOUCHAndBREAKStars => '不含 SLIDE、TOUCH 和絕贊星星。';

  @override
  String get flowAliasesNone => '別名: 無';

  @override
  String flowAliasesForP0(String p0) {
    return '$p0的別名';
  }

  @override
  String get flowTapAnyAliasToCopy => '點擊任意別名即可複製';

  @override
  String flowViewAliasesP0(String p0) {
    return '查看別名 ($p0)';
  }

  @override
  String flowDXScoreP02(String p0) {
    return 'DX分數 $p0%';
  }

  @override
  String flowRankP0P1RatingP2(String p0, String p1, String p2) {
    return '第 $p0 名，$p1，Rating $p2';
  }

  @override
  String get flowRatingHeadroom => '推分空間';

  @override
  String flowRaiseToP0P1(String p0, String p1) {
    return '推到 $p0（$p1%）';
  }

  @override
  String flowDXScoreP0P12(String p0, String p1) {
    return 'DX分數 $p0 / $p1';
  }

  @override
  String get flowViewSongDetails => '查看歌曲詳情';

  @override
  String flowP0SongsRemaining(String p0) {
    return '剩餘 $p0 首';
  }

  @override
  String flowP0EqualToTheLastChartOn(String p0) {
    return '$p0，和榜單最後一首相同';
  }

  @override
  String flowP0ConstantP1RAP2(String p0, String p1, String p2) {
    return '$p0 · 定數 $p1 · RA $p2';
  }

  @override
  String get flowAddScoreHistory => '添加成績歷史';

  @override
  String flowScoreHistoryP0(String p0) {
    return '成績歷史（$p0）';
  }

  @override
  String get flowTheCurveDropsInGameScoresKeep =>
      '曲線出現下降：遊戲裏成績取最高，這多半是切換數據源/賬號造成的記錄差異';

  @override
  String get flowUnknownDate => '日期未知';

  @override
  String flowShowAllP0Entries(String p0) {
    return '展開全部（$p0 條）';
  }

  @override
  String get flowAddChartScoreHistory => '添加譜面成績歷史';

  @override
  String get flowAchievement3 => '達成率（%）';

  @override
  String get flowSumOfUTAGESubcharts => '宴會場子譜相加';

  @override
  String get flowNormalChartLimit => '普通譜面上限';

  @override
  String get flowDXScoreOptional => 'DX 分數（可選）';

  @override
  String get flowChartMaximumScore => '譜面滿分';

  @override
  String get flowSelectTime => '選擇時間';

  @override
  String get flowSeconds059 => '秒（0-59）';

  @override
  String get flowDeleteThisDataPoint => '刪除這個記錄點？';

  @override
  String get flowThisCannotBeUndoneIfThisIs =>
      '刪除後無法恢復。如果它是自動採集到的當前成績，下次刷新可能會重新記錄。';

  @override
  String get flowDataVoluntarilyUploadedByPlayersForReference =>
      '數據來自玩家自願上傳，僅供參考和娛樂';

  @override
  String get flowBriefProfilesAreHiddenForAnonymousPlayers => '匿名用戶不展示簡要信息';

  @override
  String get flowCouldNotLoadTheBriefProfileTry => '暫時無法讀取簡要信息，請稍後重試';

  @override
  String get flowReload => '重新加載';

  @override
  String get flowUnknownPlayer => '未知玩家';

  @override
  String get flowNoTitleSet => '未設置稱號';

  @override
  String get flowB1IsTheChartWithTheHighest =>
      'B1 爲對應 Best 列表中單曲 Rating 最高的譜面。';

  @override
  String get flowNoScoresYet => '暫無成績';

  @override
  String get flowDanCompletion => '段位完成情況';

  @override
  String get flowTotalAchievementUpTo4040000 => '總達成率（最高 404.0000%）';

  @override
  String get flowCompletionRate => '完成率';

  @override
  String flowP0Songs2(String p0) {
    return '$p0 首';
  }

  @override
  String get flowExcluded => '不計入';

  @override
  String get flowCompleted => '已完成';

  @override
  String get flowIncomplete => '未完成';

  @override
  String get flowLoading4 => '正在加載';

  @override
  String get flowFirstRecord => '首次記錄';

  @override
  String flowP0P1Changes(String p0, String p1) {
    return '–$p0 · $p1 次變化';
  }

  @override
  String get flowRecorded => ' 記錄';

  @override
  String get flowTheScoreChangedDuringTheDayBut => '日內成績有過變化，最新值已回到當日初值。';

  @override
  String get flowNoChange => '無變化';

  @override
  String get flowPlaybackProgressDragTheOuterRingTo => '播放進度，拖動外環調整，左右滑動曲繪切歌';

  @override
  String get flowElapsed => '已播放';

  @override
  String get flowDuration2 => '總時長';

  @override
  String get flowQueue => '隊列';

  @override
  String get flowLoadingAudio => '正在加載音源';

  @override
  String get flowOpenPlaybackQueue => '打開播放隊列';

  @override
  String get flowPlaybackQueue => '播放隊列';

  @override
  String flowPlaybackModeP0TapToSwitchAnd(String p0) {
    return '播放模式：$p0（點一下切換並展開）';
  }

  @override
  String get flowRepeatCount => '循環次數';

  @override
  String get flowNotSet2 => '不設置';

  @override
  String flowP0Times(String p0) {
    return '$p0 次';
  }

  @override
  String get flowUnlimited => '不設置次數';

  @override
  String get flowRepeatTheCurrentSongIndefinitely => '一直循環當前曲目';

  @override
  String get flowSetCount => '設置次數';

  @override
  String get flowDecreaseCount => '減少次數';

  @override
  String get flowIncreaseCount => '增加次數';

  @override
  String get flowHideFloatingPlayer => '隱藏懸浮球';

  @override
  String get flowPlaylist => '播放列表';

  @override
  String get flowKeepPlayingAndReopenTheFloatingPlayer =>
      '可以繼續播放並稍後回到隨身聽重新喚起，或同時暫停播放並移除通知欄音樂。';

  @override
  String get flowKeepPlaying => '繼續播放';

  @override
  String get flowPauseAndRemove => '暫停並移除';

  @override
  String get flowSongTitle2 => '歌曲標題';

  @override
  String get flowTranslatedByBaiduSLanguageModel => '由百度大模型翻譯';

  @override
  String get flowTranslating => '翻譯中…';

  @override
  String get flowDifficultiesToPlayMultipleSelections => '想玩的難度（可多選）';

  @override
  String get flowNotesOptional => '備註（可選）';

  @override
  String get flowExamplePlayWithFriends => '例如：和朋友一起玩';

  @override
  String get flowAdd => '加入';

  @override
  String get flowTotalSongs => '總歌曲數';

  @override
  String get flowPathCopiedToClipboard => '路徑已複製到剪貼板';

  @override
  String get flowNoAppAvailableToViewImages => '沒有找到能查看圖片的應用';

  @override
  String get flowCopied => '已複製';

  @override
  String get flowCopyPath => '複製路徑';

  @override
  String flowPublicDirectoryIsNotWritableSavedTo(String p0) {
    return '公開目錄不可寫，文件已保存到備用路徑：$p0';
  }

  @override
  String get flowViewImage => '查看圖片';

  @override
  String get flowPerRow => '每行';

  @override
  String get flowFewerAvatarsPerRow => '減少每行頭像數';

  @override
  String get flowMoreAvatarsPerRow => '增加每行頭像數';

  @override
  String get flowChooseAppearance => '選擇裝扮';

  @override
  String flowSearchP0ByNameDescriptionOrID(String p0) {
    return '搜索$p0名稱、描述或編號';
  }

  @override
  String flowP0Items3(String p0) {
    return '共 $p0 項';
  }

  @override
  String flowLoadingP0(String p0) {
    return '正在加載$p0…';
  }

  @override
  String flowNoP0YetRefreshCollectibleDataFirst(String p0) {
    return '暫無$p0，請先刷新收藏品數據';
  }

  @override
  String flowNoMatchingP0(String p0) {
    return '未找到匹配的$p0';
  }

  @override
  String get flowPNGLosslessOriginalQuality => 'PNG 無損（原始畫質）';

  @override
  String get flowJPEGHighQuality => 'JPEG 高質量';

  @override
  String get flowJPEGStandard => 'JPEG 標準';

  @override
  String get flowJPEGCompressed => 'JPEG 壓縮';

  @override
  String get flowChooseExportQuality => '選擇導出質量';

  @override
  String flowExportingP0(String p0) {
    return '當前正在導出：$p0';
  }

  @override
  String get flowImageTheme => '圖片主題';

  @override
  String get flowThunderMode => '雷霆模式';

  @override
  String get flowArrangeCardsIn50RowsOr50 => '將歌曲卡片改爲單列 50 行或單行 50 列，適合超長圖片';

  @override
  String get flowExportPreview => '導出效果圖';

  @override
  String get flowConfirmExport => '確認導出';

  @override
  String flowCouldNotGeneratePreviewP0(String p0) {
    return '預覽生成失敗：$p0';
  }

  @override
  String flowP0P1EstimatedP2(String p0, String p1, String p2) {
    return '$p0，$p1，預計 $p2';
  }

  @override
  String flowAboutP0(String p0) {
    return '約 $p0';
  }

  @override
  String get flowQuestionPool => '題庫範圍';

  @override
  String get flowGameRules => '對局規則';

  @override
  String get flowMaximumGuesses => '最大猜測次數';

  @override
  String get flowTimeLimit => '時間限制';

  @override
  String get flowTo => '至';

  @override
  String get flowEnter10150ThenTap => '可填 1.0 至 15.0，點其它位置或按回車生效';

  @override
  String get flowBest35ConstantRange => 'Best35 定數區間';

  @override
  String get flowBest15ConstantRange => 'Best15 定數區間';

  @override
  String get flowBest50Average => 'Best 50 平均';

  @override
  String get flowBest35Average => 'Best 35 平均';

  @override
  String get flowBest15Average => 'Best 15 平均';

  @override
  String get flowSSSCountIn50Charts => '50首 SSS+ 數量';

  @override
  String get flowSSSCountIn50Charts2 => '50首 SSS 數量';

  @override
  String get flowPotentialConstantRATable => '可提升定數 RA 對照';

  @override
  String get flowFittedTotalRating => '擬合總Rating';

  @override
  String get flowDifferenceFromBest50 => '與Best50差值';

  @override
  String get flowAverageAchievementDXScoreRate2 => '平均達成率 / DX分數達成率';

  @override
  String flowCurrentOrderP0(String p0) {
    return '當前排序：$p0';
  }

  @override
  String get flowTotalRA => '總RA';

  @override
  String get flowSongs => '歌曲數';

  @override
  String get flowComparedWithThisTagSBest50 => '較該標籤 Best50';

  @override
  String get flowSongAchievement => '單曲達成率';

  @override
  String flowTotalRatingP0(String p0) {
    return '總 Rating $p0';
  }

  @override
  String flowP0ConstantP1(String p0, String p1) {
    return '$p0 (定數 $p1)';
  }

  @override
  String get flowNoteStatistics => '物量統計';

  @override
  String get flowBREAKStatistics => '絕贊統計';

  @override
  String flowP0P1P2Statistics2(String p0, String p1, String p2) {
    return '$p0 $p1($p2)統計';
  }

  @override
  String flowChartDesignerP0(String p0) {
    return '譜師:$p0';
  }

  @override
  String flowVersionP0(String p0) {
    return '版本:$p0';
  }

  @override
  String flowGenreP0(String p0) {
    return '流派:$p0';
  }

  @override
  String flowComposerP0(String p0) {
    return '曲師:$p0';
  }

  @override
  String flowP0P1P2SongsTotal(String p0, String p1, String p2) {
    return '$p0$p1 | 共 $p2 首歌曲';
  }

  @override
  String get flowFolderNameCannotBeEmpty => '收藏夾名稱不能爲空';

  @override
  String get flowNoAudioIsAvailableForThisSong => '這首歌暫時沒有可用的音源';

  @override
  String get flowCouldNotLoadAudioTryAgainLater => '音源加載失敗，請稍後重試';

  @override
  String get flowReadingLocalVideo => '正在讀取本地視頻…';

  @override
  String get flowBufferingVideo => '正在緩衝視頻…';

  @override
  String get flowNoMatchingChartCodeFound => '未找到匹配的譜面代碼';

  @override
  String flowCouldNotFetchChartCodeP0(String p0) {
    return '獲取譜面代碼失敗: $p0';
  }

  @override
  String get flowExporting2 => '正在導出...';

  @override
  String get flowNoChartCodeAvailable => '暫無譜面代碼數據';

  @override
  String get flowAudio => '音源';

  @override
  String flowCouldNotFetchP0ThePackageOnly(String p0) {
    return '未能獲取$p0，壓縮包裏只有譜面數據，導入後需要自行補齊才能正常遊玩。';
  }

  @override
  String get flowPreparingChart => '正在準備譜面…';

  @override
  String get flowReadingChartSettings => '正在讀取譜面設置…';

  @override
  String get flowFindingAudio => '正在查找音頻文件…';

  @override
  String get flowPreparingCoverArt => '正在準備曲繪…';

  @override
  String get flowParsingChartData => '正在解析譜面數據…';

  @override
  String get flowAudioLoadedFromLocalCache => '已從本地緩存讀取音頻';

  @override
  String get flowAnd => '和';

  @override
  String flowP0MinutesAgo(String p0) {
    return '$p0 分鐘前';
  }

  @override
  String flowP0HoursAgo(String p0) {
    return '$p0 小時前';
  }

  @override
  String flowP0DaysAgo(String p0) {
    return '$p0 天前';
  }

  @override
  String get flowCustomChart2 => '自定義譜面';

  @override
  String get flowMaidataFileSelected => '已選擇maidata文件';

  @override
  String get flowTheLibraryIsNotReadyRefreshData =>
      '曲庫還沒準備好。請先回首頁「拉取成績並更新數據」，或檢查網絡後重試。';

  @override
  String flowCouldNotLoadLibraryP0(String p0) {
    return '加載曲庫失敗：$p0';
  }

  @override
  String get flowNotificationPermissionWasNotGrantedBackgroundPlayback =>
      '未授予通知權限：音樂仍可後臺播放，但不會顯示通知欄播放器';

  @override
  String get flowDownloaded2 => '已下載';

  @override
  String flowDownloadFailedP02(String p0) {
    return '下載失敗：$p0';
  }

  @override
  String get flowTheCurrentSongIsNotInThis => '當前播放的曲目不在列表裏';

  @override
  String get flowNoPlayableSongs => '沒有可播放的歌曲';

  @override
  String get flowNoMatchingSongs => '沒有匹配的歌曲';

  @override
  String flowP0PlayableSongs(String p0) {
    return '共 $p0 首可播放';
  }

  @override
  String flowExcludedP0UTAGESongs(String p0) {
    return '已排除宴會場 $p0 首';
  }

  @override
  String flowP0SongsHaveNoDivingFishEntry(String p0) {
    return '水魚無對應條目 $p0 首';
  }

  @override
  String get flowCalculating => '計算中';

  @override
  String get flowSwitchingSongs => '正在切換歌曲…';

  @override
  String get flowThisIsTheLastSong => '已經是最後一首啦';

  @override
  String get flowUpNext => '接下來';

  @override
  String get flowUpToOneDecimalPlaceLeaveBlank => '最多一位小數，留空表示默認值';

  @override
  String get flowUpToFourDecimalPlacesLeaveBlank => '最多四位小數，留空表示默認值';

  @override
  String get flowGrade => '評級';

  @override
  String get flowLowerBound => '下界';

  @override
  String get flowUpperBound => '上界';

  @override
  String get flowCategory => '種類';

  @override
  String get flowSelectALevel => '請選擇等級';

  @override
  String get flowSelectAVersion => '請選擇版本';

  @override
  String get flowSelectAGenre => '請選擇流派';

  @override
  String get flowTitleType => '稱號類型';

  @override
  String get flowNoMatchingChartDesigners2 => '沒有匹配的譜師';

  @override
  String get flowNoMatchingComposers => '沒有匹配的曲師';

  @override
  String get flowSongs2 => '首';

  @override
  String get flowNoSongsMatchThisLevel => '當前等級沒有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisChartDesigner => '當前譜師沒有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisVersion => '當前版本沒有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisGenre => '當前流派沒有匹配的歌曲';

  @override
  String get flowNoSongsMatchThisComposer => '當前曲師沒有匹配的歌曲';

  @override
  String flowLvP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Lv.$p0($p1)的$p2稱號統計';
  }

  @override
  String flowChartDesignerP0P1P2TitleStatistics(
      String p0, String p1, String p2) {
    return '譜師$p0($p1)的$p2稱號統計';
  }

  @override
  String flowVersionP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return '版本$p0($p1)的$p2稱號統計';
  }

  @override
  String flowGenreP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return '流派$p0($p1)的$p2稱號統計';
  }

  @override
  String flowComposerP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return '曲師$p0($p1)的$p2稱號統計';
  }

  @override
  String get flowFriendCode => '好友碼';

  @override
  String flowEnterYourFriendSP02(String p0) {
    return '請輸入好友的$p0';
  }

  @override
  String flowMeP0(String p0) {
    return '我 · $p0';
  }

  @override
  String get flowMyWins => '我贏';

  @override
  String get flowFriendSWins => '好友贏';

  @override
  String get flowFriend => '好友';

  @override
  String get flowFirstCharacter => '首字';

  @override
  String get flowSelectAFirstCharacter => '請選擇首字';

  @override
  String get flowNoSongsMatchThisDifficulty => '當前難度沒有匹配的歌曲';

  @override
  String get flowByAverageAchievement => '平均達成率推薦';

  @override
  String get flowByConstantDifference => '定數差值推薦';

  @override
  String get flowAvgAchievement => '平均達成';

  @override
  String get flowConstantDifference => '定數差值';

  @override
  String flowPersonalBestP0(String p0) {
    return '個人最佳 $p0%';
  }

  @override
  String get flowLast30Days => '近 30 天';

  @override
  String get flowLast90Days => '近 90 天';

  @override
  String flowLimitP0TheoreticalValueUnavailable(String p0) {
    return '上限 $p0（理論值未取到）';
  }

  @override
  String flowCouldNotLoadImprovementHistoryP0(String p0) {
    return '讀取提升歷史失敗：$p0';
  }

  @override
  String get flowChangesAreRecordedAutomaticallyAfterYourScores =>
      '成功刷新自己的成績時自動記錄，水魚、落雪和 AWMC NET 按數據源與賬號分別保存。\n\n首次沒有舊成績可比時僅建立基線；刷新無變化不新增記錄。當天同一譜面的多次變化合成一張卡，展示首次變化前到最新值。\n\n按刷新時的本地日期歸檔，時間代表發現變化的時間，並非實際遊玩時間。卡片按前後值標爲成績提升、成績回退、成績無變化，或有升有降的成績變化；首次出現的譜面另註明首次記錄。\n\nRating 是該譜面的 Rating，不代表總 Rating 的增量。歷史僅在本機保存，不會自動回填啓用前的舊成績。';

  @override
  String get flowNoScoreImprovementRecordsYet => '還沒有成績提升記錄';

  @override
  String get flowNoMatchingRecords => '沒有符合條件的記錄';

  @override
  String get flowBestScoresThatChangeAfterASuccessful =>
      '成功刷新後，發生變化的最佳成績會出現在這裏。';

  @override
  String get flowTryAnotherKeywordOrDate => '試試其他關鍵詞或日期。';

  @override
  String get flowCouldNotLoad => '加載失敗';

  @override
  String flowRequestFailedP0(String p0) {
    return '請求失敗 ($p0)';
  }

  @override
  String flowNetworkErrorP0(String p0) {
    return '網絡錯誤: $p0';
  }

  @override
  String flowP0MinutesAgo2(String p0) {
    return '$p0分鐘前';
  }

  @override
  String flowP0HoursAgo2(String p0) {
    return '$p0小時前';
  }

  @override
  String flowP0DaysAgo2(String p0) {
    return '$p0天前';
  }

  @override
  String flowP0User(String p0) {
    return '$p0用戶';
  }

  @override
  String flowCouldNotSaveSnapshotP0(String p0) {
    return '保存快照失敗: $p0';
  }

  @override
  String get flowHighestConstantsFromOlderVersions => '非當前版本最高定數';

  @override
  String get flowBestScoresFromOlderVersions => '非當前版本最好成績';

  @override
  String get flowHighestConstantsFromThisVersion => '當前版本最高定數';

  @override
  String get flowBestScoresFromThisVersion => '當前版本最好成績';

  @override
  String get flowPattern => '配置';

  @override
  String get flowEvaluation => '評價';

  @override
  String get flowModeATakeTheTop50Charts =>
      '模式A：不分類Best35和Best15，直接獲取擬合定數下的Rating前50的譜面';

  @override
  String get flowModeBReplaceConstantsInYourOfficial =>
      '模式B：將您的Best35和Best15中的所有譜面的定數都替換爲其擬合定數，然後計算Rating並降序排序';

  @override
  String get flowModeCTakeTheTop35Older =>
      '模式C：在非當前版本中取擬合定數下的Rating前35的譜面，在當前版本中取擬合定數下Rating前15的譜面';

  @override
  String get flowTop35FromOlderVersions => '非當前版本前 35';

  @override
  String get flowTop15FromThisVersion => '當前版本前 15';

  @override
  String flowP0ChartsHaveNoFittedConstantOfficial(String p0) {
    return '$p0首暫無擬合定數，按照官方定數計算';
  }

  @override
  String flowIncludesP0(String p0) {
    return '包含: $p0';
  }

  @override
  String flowChartDesigner50P0(String p0) {
    return '譜師50 - $p0';
  }

  @override
  String flowVersion50P0(String p0) {
    return '版本50 - $p0';
  }

  @override
  String flowGenre50P0(String p0) {
    return '流派50 - $p0';
  }

  @override
  String flowStar50P0(String p0) {
    return '星數50 - $p0';
  }

  @override
  String flowTag50P0(String p0) {
    return '標籤50 - $p0';
  }

  @override
  String flowPersonalizedBest50P0(String p0) {
    return '個性化Best50 - $p0';
  }

  @override
  String flowChartDesigner50P0Statistics(String p0) {
    return '譜師50 - $p0 統計';
  }

  @override
  String flowVersion50P0Statistics(String p0) {
    return '版本50 - $p0 統計';
  }

  @override
  String flowGenre50P0Statistics(String p0) {
    return '流派50 - $p0 統計';
  }

  @override
  String flowStar50P0Statistics(String p0) {
    return '星數50 - $p0 統計';
  }

  @override
  String flowTag50P0Statistics(String p0) {
    return '標籤50 - $p0 統計';
  }

  @override
  String flowP0Statistics(String p0) {
    return '$p0 統計';
  }

  @override
  String flowPersonalizedFittedBest50P0(String p0) {
    return '個性化擬合Best50 - $p0';
  }

  @override
  String flowTagP0P1ChartsTop50By(String p0, String p1) {
    return '標籤：$p0 · 共$p1張譜面 · 在擬合定數下計算單曲Rating，取前50的譜面';
  }

  @override
  String get flowAverage => '平均';

  @override
  String get flowOlderVersions => '非當前版本';

  @override
  String get flowCurrentVersion => '當前版本';

  @override
  String flowP0InvalidEntriesAchievementOrDXScore(String p0) {
    return '⚠ 存在 $p0 條非法數據（達成率或 DX 分數超過譜面上限）';
  }

  @override
  String get flowEG1005 => '如 100.5';

  @override
  String get flowEG3000 => '如 3000';

  @override
  String get flowEnterAchievement => '請輸入達成率';

  @override
  String flowDifficultyP03(String p0) {
    return '難度$p0';
  }

  @override
  String get flowRADescending => 'RA 降序';

  @override
  String get flowRAAscending => 'RA 升序';

  @override
  String get flowConstantDescending => '定數 降序';

  @override
  String get flowConstantAscending => '定數 升序';

  @override
  String get flowFilled => '已填寫';

  @override
  String flowCouldNotLoadP0(String p0) {
    return '加載失敗: $p0';
  }

  @override
  String get flowModeATop50ByFittedRating => '模式A：不分類，按擬合 Rating 取前50';

  @override
  String get flowModeBRecalculateOfficialBest35Best15Using =>
      '模式B：按官方 Best35/Best15 替換擬合定數重算';

  @override
  String get flowModeCTop35OlderChartsAnd => '模式C：非新曲取前35，新曲取前15';

  @override
  String get flow6MaximumReached => '✦ 6 已滿';

  @override
  String get flowCouldNotLoadLeaderboardData => '加載排行榜數據失敗';

  @override
  String get flowAchievementRanking2 => '達成率排行榜';

  @override
  String get flowDXScoreRanking2 => 'DX分數排行榜';

  @override
  String flowCouldNotFetchLeaderboardP0(String p0) {
    return '獲取排行榜失敗: $p0';
  }

  @override
  String get flowBREAKShareRanking => '絕贊佔比排行榜';

  @override
  String get flowSameSongDifficultyGapRanking => '同曲難度跨度排行榜';

  @override
  String get flowSLIDEShareRanking => 'SLIDE 佔比排行榜';

  @override
  String get flowTOUCHShareRanking => 'TOUCH 佔比排行榜';

  @override
  String get flowTAPShareRanking => 'TAP 佔比排行榜';

  @override
  String get flowHOLDShareRanking => 'HOLD 佔比排行榜';

  @override
  String get flowBREAKCountRanking => '絕贊數排行榜';

  @override
  String get flowNormalChartBREAKCountRanking => '常規譜絕贊數排行榜';

  @override
  String get flowConstantDifferenceRanking => '定數差值排行榜';

  @override
  String get flowMASTERReMASTERConstantDifferenceRanking =>
      'MASTER/Re:MASTER定數差值排行榜';

  @override
  String get flowEXPERTConstantDifferenceRanking => 'EXPERT定數差值排行榜';

  @override
  String get flowSampleCountRanking => '樣本總數排行榜';

  @override
  String get flowNoteCountRanking => '物量排行榜';

  @override
  String get flowMASTERReMASTERAverageAchievementRanking =>
      'MASTER/Re:MASTER平均達成率排行榜';

  @override
  String get flowEXPERTAverageAchievementRanking => 'EXPERT平均達成率排行榜';

  @override
  String get flowBPMRanking => 'BPM排行榜';

  @override
  String get flowBREAKShare => '絕贊佔比';

  @override
  String get flowConstantGap => '定數跨度';

  @override
  String get flowSLIDEShare => 'SLIDE 佔比';

  @override
  String get flowTOUCHShare => 'TOUCH 佔比';

  @override
  String get flowTAPShare => 'TAP 佔比';

  @override
  String get flowHOLDShare => 'HOLD 佔比';

  @override
  String get flowBREAKCount => '絕贊數';

  @override
  String get flowSampleCount => '樣本總數';

  @override
  String get flowRankByBREAKCountOrderCanBe => '按譜面絕贊數量排名（可切換正反向）';

  @override
  String get flowRankByBREAKCountExcludingUTAGEOrder =>
      '絕贊數排行榜，但宴會場不參與（可切換正反向）';

  @override
  String get flowBREAKCountTotalNotesRankedAsA => '絕贊數 ÷ 總物量，以百分比排名（可切換正反向）';

  @override
  String get flowTAPCountTotalNotesIncludesSTDX =>
      'TAP 數 ÷ 總物量，ST/DX/UT 均參與（可切換正反向）';

  @override
  String get flowHOLDCountTotalNotesIncludesSTDX =>
      'HOLD 數 ÷ 總物量，ST/DX/UT 均參與（可切換正反向）';

  @override
  String get flowSLIDECountTotalNotesIncludesSTDX =>
      'SLIDE 數 ÷ 總物量，ST/DX/UT 均參與（可切換正反向）';

  @override
  String get flowTOUCHCountTotalNotesIncludesDXUT =>
      'TOUCH 數 ÷ 總物量，DX/UT 參與，ST 不參與（可切換正反向）';

  @override
  String get flowOfficialConstantGapForEXPERTMASTERAnd =>
      '同曲 EXPERT→MASTER、MASTER→Re:MASTER 的官方定數差（後者減前者，可切換正反向）';

  @override
  String get flowRankByFittedMinusOfficialConstantOrder =>
      '擬合定數與官方定數差值排名（可切換正反向）';

  @override
  String get flowMASTERReMASTEROnlyOrderCanBe =>
      '只統計MASTER/Re:MASTER難度（可切換正反向）';

  @override
  String get flowEXPERTOnlyOrderCanBeReversed => '只統計EXPERT難度（可切換正反向）';

  @override
  String get flowRankByTotalPlayerSamplesOrderCan => '玩家樣本總量排名（可切換正反向）';

  @override
  String get flowRankByTheTotalOfAllFive => '五種note總數排名（可切換正反向）';

  @override
  String get flowRankByAverageAchievementOrderCanBe => '按平均達成率排名（可切換正反向）';

  @override
  String get flowRankBySongBPMOrderCanBe => '按歌曲BPM排名（可切換正反向）';

  @override
  String get flowEnterABVID => '請輸入 BV 號';

  @override
  String get flowInvalidBVIDExpectedBVFollowedBy => 'BV 號格式不正確（應爲 BV + 10位字符）';

  @override
  String get flowCheckFailedVideoInformationUnavailableTheBV =>
      '校驗失敗: 無法獲取視頻信息（BV 號可能不存在）';

  @override
  String flowVerifiedVideoTitleP0(String p0) {
    return '校驗通過！視頻標題: \"$p0\"';
  }

  @override
  String flowCheckFailedVideoTitleP0DoesNot(String p0, String p1) {
    return '校驗失敗: 視頻標題 \"$p0\" 不包含歌曲名 \"$p1\"';
  }

  @override
  String flowVerificationErrorP0(String p0) {
    return '校驗異常: $p0';
  }

  @override
  String get flowSongPV => '歌曲 PV';

  @override
  String get flowPlayThisChartAtLeastOnceBefore => '至少遊玩過一次該譜面才能參與打分';

  @override
  String get flowInvalidScorePleaseCheckIt => '成績不合法，請檢查';

  @override
  String get flowContentCannotBeEmpty => '內容不能爲空';

  @override
  String get flowCommentsCannotExceed500Characters => '評論內容不能超過500字';

  @override
  String get flowSending => '發送中...';

  @override
  String get flowOpenBilibili2 => '跳轉到B站';

  @override
  String flowRelatedCollectiblesP0(String p0) {
    return '相關收藏品 $p0';
  }

  @override
  String flowMyScoreP0(String p0) {
    return '我的成績 · $p0';
  }

  @override
  String flowPlayedP0Times(String p0) {
    return '遊玩 $p0 次';
  }

  @override
  String flowFittedP0P1(String p0, String p1) {
    return '擬合 $p0$p1';
  }

  @override
  String get flowDuration3 => '時長';

  @override
  String get flowScoreHistory => '成績歷史';

  @override
  String get flowData => '數據';

  @override
  String get flowCommunity => '社區';

  @override
  String get flowTools => '工具';

  @override
  String get flowTrueBREAKTAP => '真絕贊TAP';

  @override
  String get flowTrueBREAKHOLD => '真絕贊HOLD';

  @override
  String get flowProtectedBREAK => '保護套絕贊';

  @override
  String get flowBREAKStar => '絕贊星星';

  @override
  String get flowCategory2 => '類別';

  @override
  String get flowTotal => '共 ';

  @override
  String get flowSSSAllowance => 'SSS+ 容錯';

  @override
  String get flowSSSAllowance2 => 'SSS 容錯';

  @override
  String get flowChartTagsReferenceOnly => '譜面標籤(僅供參考)';

  @override
  String get flowPreview => '試聽';

  @override
  String get flowMore => '更多';

  @override
  String get flowViewChartCode => '查看譜面代碼';

  @override
  String get flowUTAGESongsAreExcludedFromBest50 => '宴會場歌曲不參與Best50';

  @override
  String flowThisChartIsAlreadyWithinP0With(String p0) {
    return '該譜面已在$p0區間內且無提升空間';
  }

  @override
  String flowThisChartCannotEnterP0(String p0) {
    return '該譜面無法進入$p0';
  }

  @override
  String flowReachP0ToP1P2(String p0, String p1, String p2) {
    return '推到 $p0% 可$p1 $p2';
  }

  @override
  String get flowEnter => '進入';

  @override
  String flowThisChartHasRAP0ReachingThe(String p0, String p1) {
    return '這張譜面當前 RA $p0，推到下面的達成率時 $p1 總分能加：';
  }

  @override
  String flowThisChartIsNotInP0The(String p0, String p1) {
    return '這張譜面還不在 $p0，末位是 RA $p1。推到下面的達成率替換末位後，總分能加：';
  }

  @override
  String flowP0BaseP1(String p0, String p1) {
    return '$p0(基準 $p1)';
  }

  @override
  String get flowUserUpload => '用戶上傳';

  @override
  String get flowRedisCache => 'Redis 緩存';

  @override
  String get flowAutomaticLookup => '自動獲取';

  @override
  String get flowUnknownType => '未知類型';

  @override
  String get flowCountCannotBeNegative => '數量不能爲負數';

  @override
  String flowPlayedCountP0CannotExceedTheTotal(String p0, String p1) {
    return '已打出總數（$p0）不能超過BREAK總數（$p1）';
  }

  @override
  String flowBREAKLossIsP0BeyondTheSS(String p0) {
    return 'BREAK損失已達$p0%，超過SS(-2%)上限，無法繼續容錯';
  }

  @override
  String flowP0DaysApart(String p0) {
    return '(相差$p0天)';
  }

  @override
  String flowFirstReleaseP0(String p0) {
    return '首次上線$p0';
  }

  @override
  String get flowBase => '基準';

  @override
  String get flowProtectedNOTEDistribution => '保護套 NOTE 分佈';

  @override
  String get flowProtectedTAP => '保護套TAP';

  @override
  String get flowProtectedHOLD => '保護套HOLD';

  @override
  String get flowUnprotectedNOTEDistribution => '無保護套 NOTE 分佈';

  @override
  String get flowUnprotectedTAP => '無保護套TAP';

  @override
  String get flowUnprotectedHOLD => '無保護套HOLD';

  @override
  String get flowTwoColumns => '雙列';

  @override
  String get flowOneColumn => '單列';

  @override
  String flowP00Songs(String p0) {
    return '$p0 0 首';
  }

  @override
  String flowP0P1SongsMinP2AvgP3(String p0, String p1, String p2, String p3) {
    return '$p0 $p1 首 · 最低 $p2 · 平均 $p3 · 點卡片看推分空間';
  }

  @override
  String get flowSongLimitReached => '已到單曲上限';

  @override
  String flowChartHistoryCouldNotReadChartHistoryIgnored(String p0) {
    return '[ChartHistory] 讀取譜面歷史失敗（忽略）: $p0';
  }

  @override
  String flowP0AchievementP1P2(String p0, String p1, String p2) {
    return '$p0\n達成率 $p1%$p2';
  }

  @override
  String flowDXScoreP03(String p0) {
    return ' · DX分數 $p0';
  }

  @override
  String get flow1DataPoint => '1 個記錄點';

  @override
  String flowP0Changes(String p0) {
    return '$p0 次變化';
  }

  @override
  String get flowDXScoreOfMaximum => 'DX分數（佔滿分%）';

  @override
  String flowP0AchievementP1DXScoreP2(String p0, String p1, String p2) {
    return '$p0\n達成率 $p1%\nDX分數 $p2';
  }

  @override
  String get flowChartLimit => '譜面上限';

  @override
  String get flowDeleteThisDataPoint2 => '刪除這個記錄點';

  @override
  String get flowPlayerBriefProfile => '玩家簡要信息';

  @override
  String get flowBriefProfileUnavailable => '暫時無法讀取簡要信息';

  @override
  String get flowLoadingBriefProfile => '正在讀取簡要信息…';

  @override
  String get flowNoBackgroundSet => '未設置背景';

  @override
  String get flowLoadingBackground => '背景加載中';

  @override
  String get flowBackgroundUnavailable => '背景暫不可用';

  @override
  String get flowNoNameplateSet => '未設置姓名框';

  @override
  String get flowLoadingNameplate => '姓名框加載中';

  @override
  String get flowNameplateUnavailable => '姓名框暫不可用';

  @override
  String flowTitleP0(String p0) {
    return '稱號 #$p0';
  }

  @override
  String get flowNotAttempted => '未挑戰';

  @override
  String get flowRedPass => '赤合格';

  @override
  String get flowEnterAValidTotalAchievement => '請輸入有效的總達成率';

  @override
  String get flowTotalAchievementMustBeBetween0And => '總達成率必須在 0～404% 之間';

  @override
  String get flowTotalAchievementSupportsUpToFourDecimal => '總達成率最多保留 4 位小數';

  @override
  String get flowTotal2 => '總數';

  @override
  String get flowByLevel => '按等級';

  @override
  String get flowByConstant => '按定數';

  @override
  String get flowRegression => '回退';

  @override
  String get flowChange2 => '變化';

  @override
  String get flowClosePlaybackModeSelection => '關閉播放模式選擇';

  @override
  String get flowSequential => '順序播放';

  @override
  String get flowShuffle => '隨機播放';

  @override
  String get flowRepeatOne => '單曲循環';

  @override
  String get flowTranslationIsUnavailableTryAgainLater => '暫時無法翻譯，請稍後重試';

  @override
  String get flowTranslationFailedTryAgainLater => '翻譯失敗，請稍後重試';

  @override
  String get flowNumberOfEntries => '添加次數';

  @override
  String flowSourceP02(String p0) {
    return '數據源 $p0';
  }

  @override
  String flowGeneratedByChiffonMaiCommunityGroupP0(String p0) {
    return 'Generated by ChiffonMai · 交流羣 $p0';
  }

  @override
  String get flowExportSuccessful => '導出成功';

  @override
  String get flowExported => '已導出';

  @override
  String get flow50Rows1Column => '單列 50 行';

  @override
  String get flow1Row50Columns => '單行 50 列';

  @override
  String get flowZoomOut => '縮小';

  @override
  String get flowZoomIn => '放大';

  @override
  String get flowFitToWindow => '適應窗口';

  @override
  String get flowMustBeGreaterThan0 => '必須大於 0';

  @override
  String flowMustNotExceedP0P1(String p0, String p1) {
    return '不得超過 $p0$p1';
  }

  @override
  String flowLimitP0P1(String p0, String p1) {
    return '上限 $p0（$p1）';
  }

  @override
  String flowRatingP0Best35P1Best15P2Average(
      String p0, String p1, String p2, String p3, String p4) {
    return 'Rating $p0\nBest35 $p1 · Best15 $p2\n平均達成率 $p3%\n平均DX分數達成率 $p4%';
  }

  @override
  String get flowTheoreticalBest35HighestConstantsFromOlderVersions =>
      '理論Best35 | 非當前版本最高定數';

  @override
  String get flowBest35BestScoresFromOlderVersions => 'Best35 | 非當前版本最好成績';

  @override
  String get flowTheoreticalBest15HighestConstantsFromThisVersion =>
      '理論Best15 | 當前版本最高定數';

  @override
  String get flowBest15BestScoresFromThisVersion => 'Best15 | 當前版本最好成績';

  @override
  String flowAverageP02(String p0) {
    return '平均 $p0';
  }

  @override
  String flowFittedRatingP0AverageRatingP1Average(
      String p0, String p1, String p2, String p3) {
    return '擬合 Rating $p0\n平均 Rating $p1\n平均達成率 $p2%\n平均DX分數達成率 $p3%';
  }

  @override
  String get flowBest50BasedOnFittedConstants => '基於擬合難度的Best50';

  @override
  String flowP0ChartsTotalRatingP1AverageDX(String p0, String p1, String p2) {
    return '共 $p0 張譜面\nRating 合計 $p1\n平均DX分數達成率 $p2%';
  }

  @override
  String flowAverageRAP0(String p0) {
    return '平均RA $p0';
  }

  @override
  String flowFittedRatingP0VsThisTagS(
      String p0, String p1, String p2, String p3, String p4, String p5) {
    return '擬合 Rating $p0（較該標籤 Best50 $p1$p2）\n平均 Rating $p3\n平均達成率 $p4%\n平均DX分數達成率 $p5%';
  }

  @override
  String get flowChartType => '譜面類型';

  @override
  String get flowReferenceDuration => '參考時長';

  @override
  String get flowNOTECountsAndTotalNotes => 'NOTE 數量與總物量';

  @override
  String get flowBREAKCounts => '絕贊數量';

  @override
  String get flowTotalNotes => '總物量';

  @override
  String get flowOfficialConstant => '官方定數';

  @override
  String get flowFittedConstant => '擬合定數';

  @override
  String get flowTotal3 => '總計';

  @override
  String get flowRequestingStoragePermission => '請求存儲權限...';

  @override
  String get flowBuildingExportContent => '正在構建導出內容...';

  @override
  String get flowPreloadingImages => '正在預加載圖片...';

  @override
  String get flowRenderingExportContent => '正在渲染導出內容...';

  @override
  String get flowGeneratingImage => '正在生成圖片...';

  @override
  String get flowSavingImage => '正在保存圖片...';

  @override
  String get flowExportComplete => '導出完成';

  @override
  String get flowBPMRange => 'BPM 範圍';

  @override
  String get flowBaseBPM => '基準 BPM';

  @override
  String get flowSOrLower => 'S+以下';

  @override
  String get flowNoCombo => '無連擊';

  @override
  String get flowNoSync => '無同步';

  @override
  String flowCouldNotLoadDataP0(String p0) {
    return '加載數據出錯: $p0';
  }

  @override
  String get flowUncategorized => '未分類';

  @override
  String get flowNarrowPass50 => '寸50';

  @override
  String get flowJustShort50 => '名刀50/鎖血50';

  @override
  String get flowNarrowSSS50 => '寸鳥加50';

  @override
  String get flowJustShortOfSSS50 => '鎖血鳥加50';

  @override
  String get flowNarrowSSS502 => '寸鳥50';

  @override
  String get flowJustShortOfSSS502 => '鎖血鳥50';

  @override
  String get flowChartDesigner50 => '譜師50';

  @override
  String get flowGenre50 => '流派50';

  @override
  String get flowVersion50 => '版本50';

  @override
  String get flowStar50 => '星數50';

  @override
  String get flowTag50 => '標籤50';

  @override
  String get flowRandom50 => '隨機50';

  @override
  String get flowOverreach50 => '越級50';

  @override
  String get flowDifficulty50 => '難度50';

  @override
  String get flowDan => '段位';

  @override
  String get flowTrueDan => '真段位';

  @override
  String get flowOverallRanking => '總排行榜';

  @override
  String get flowStarBonus => '星+';

  @override
  String get flowToNextStar => '高一級星-';

  @override
  String get flowPNGLossless => 'PNG 無損';

  @override
  String get flowOriginalQuality => '原始畫質';

  @override
  String get flowClearImageSmallerFile => '清晰，體積較小';

  @override
  String get flowGoodForSharing => '適合發送和分享';

  @override
  String get flowSmallestFile => '體積最小';

  @override
  String get detailChartBpm => '譜面';

  @override
  String get bestDisplayCover => '曲繪';

  @override
  String get bestDisplayTwoColumns => '雙列';

  @override
  String get bestDisplayOneColumn => '單列';

  @override
  String rankingServiceUnavailable(String code) {
    return '排行榜服務暫不可用（$code）';
  }

  @override
  String get rankingInvalidResponse => '排行榜響應格式無效';

  @override
  String get ratingFetchFailed => '獲取評分信息失敗';

  @override
  String commentPostHttpFailed(String code) {
    return '評論創建失敗 ($code)';
  }

  @override
  String commentDeleteHttpFailed(String code) {
    return '評論刪除失敗 ($code)';
  }

  @override
  String get unknownDataSource => '未知資料來源';

  @override
  String get exportBlackTheme => '純黑';

  @override
  String get songTabHistory => '成績歷史';

  @override
  String get songTabCommunity => '社區';

  @override
  String get flowUnknown => '未知';

  @override
  String get flowChooseDownloadMethod => '選擇下載方式';

  @override
  String get flowDownloadInBrowser => '瀏覽器下載';

  @override
  String get flowOpenDownloadPage => '打開下載網頁';

  @override
  String get flowDownloadInApp => 'App 內下載';

  @override
  String get flowDownloadInTheBackgroundWhileYouKeep => '後臺下載，不影響當前使用';

  @override
  String get flowChooseDownloadRoute => '選擇下載線路';

  @override
  String get flowCouldNotConnectToTheServerCheck => '無法連接到服務器，請檢查網絡後重試';

  @override
  String get flowYouAreUpToDate => '當前已是最新版本';

  @override
  String flowCurrentVersionP0BuildP1(String p0, String p1) {
    return '當前版本：$p0 (build: $p1)';
  }

  @override
  String flowLatestVersionP0BuildP1(String p0, String p1) {
    return '最新版本：$p0 (build: $p1)';
  }

  @override
  String flowLatestChangesP0(String p0) {
    return '最近更新：\n$p0';
  }

  @override
  String get flowHideFor3Days => '3天內不提示';

  @override
  String get flowDownloadNow => '立即下載';

  @override
  String flowCouldNotOpenLinkP0(String p0) {
    return '無法打開鏈接：$p0';
  }

  @override
  String get flowEmailAddressCopied => '郵箱已複製到剪貼板';

  @override
  String get flowCreationAndSupport => '創作與支持';

  @override
  String get flowSupporterAcknowledgments => '捐獻致謝';

  @override
  String get flowDataAndServices => '數據與服務';

  @override
  String get flowDesignInspiration => '設計思路借鑑';

  @override
  String get flowThankYouForEveryContributionThatHelps =>
      '感謝每一份支持，讓 ChiffonMai 不斷成長。';

  @override
  String get flowHereForEveryMaimaiVisit => '陪伴每一次舞萌出勤';

  @override
  String get flowReadingVersion => '版本讀取中…';

  @override
  String flowVersionP02(String p0) {
    return '版本 $p0';
  }

  @override
  String get flowAppRegistrationICP20240152563A => 'APP備案號：津ICP備2024015256號-3A';

  @override
  String get flowDevelopmentAndMaintenance => '開發與維護';

  @override
  String get flowInputError => '輸入錯誤';

  @override
  String get flowTargetAchievement => '目標達成率';

  @override
  String get flowEG1005000 => '例如 100.5000';

  @override
  String get flowJudgmentDetails => '判定詳情';

  @override
  String get flowForBREAKEnterTheMainJudgmentCounts =>
      'BREAK 只需填大類；50落 / 100落與 GREAT 細分由反推得出';

  @override
  String get flowCalculating2 => '計算中...';

  @override
  String get flowCalculateBREAKDetails => '計算絕贊詳情';

  @override
  String get flowSolutionFoundError00001 => '找到可行解（誤差 ≤ 0.0001%）';

  @override
  String get flowNoExactSolutionShowingTheClosestResult => '沒有精確解，下面是最接近的結果';

  @override
  String flowTargetP0BaseP1ExtraP2(String p0, String p1, String p2) {
    return '目標 $p0% · 基礎 $p1% · 額外 $p2%';
  }

  @override
  String flowTotalAchievementP0P1P2(String p0, String p1, String p2) {
    return '總達成率 $p0% · $p1 $p2%';
  }

  @override
  String get flowError2 => '誤差';

  @override
  String get flowMinimumError => '最小誤差';

  @override
  String get flowJudgmentLossPerNote => '單個音符的判定損失';

  @override
  String flowP0BREAKsBaseBonusScoreRatiosBelow(String p0) {
    return 'BREAK 共 $p0 個 · 每行下方是基礎分 / 獎勵分比例';
  }

  @override
  String flowP0P1NotesRedValuesShowAchievement(String p0, String p1) {
    return '$p0 共 $p1 個 · 紅字是這一檔判定丟掉的達成率';
  }

  @override
  String get flowViewPerNoteLoss => '查看單音符損失';

  @override
  String get flowLiveAchievement => '實時達成率';

  @override
  String get flowEnterJudgmentCountsBelowToCalculateAutomatically =>
      '在下方填寫各檔判定數量，結果會自動算出來';

  @override
  String flowTotalAchievementP0GradeP1(String p0, String p1) {
    return '總達成率 $p0%，評級 $p1';
  }

  @override
  String flowBaseP0BonusP1(String p0, String p1) {
    return '基礎 $p0% · 獎勵 $p1%';
  }

  @override
  String get flowAlreadyAtTheHighestGradeSSS => '已經是最高評級 SSS+';

  @override
  String flowP2NeededForP0P1(String p0, String p1, String p2) {
    return '距 $p0（$p1%）還差 $p2%';
  }

  @override
  String get flowAlternatingPlayRestSegmentsLetTheWheel =>
      '出勤和不出勤交替排布，讓轉盤決定今天要不要出勤吧。';

  @override
  String get flowSegments => '區域數量';

  @override
  String get flowFewerSegments => '減少區域';

  @override
  String get flowMoreSegments => '增加區域';

  @override
  String get flow20ByDefaultUpTo100Changes => '默認 20，最多 100 區；每次增減 2 區，保持交替';

  @override
  String get flowSpinning => '轉盤正在旋轉…';

  @override
  String get flowStartWhenYouAreReady => '準備好就開始吧';

  @override
  String flowThisSpinP0(String p0) {
    return '本次：$p0';
  }

  @override
  String get flowSpin => '轉一轉';

  @override
  String get flowError3 => '誤差 +';

  @override
  String get flowEG5 => '如 5';

  @override
  String get flowNoMatchingResults => '沒有符合條件的結果';

  @override
  String get flowBREAKDistributionCalculator => '絕贊分佈計算';

  @override
  String get flowTAPGREATAllowance => '個 TAP GREAT 的容錯';

  @override
  String get flowUserData => '用戶數據';

  @override
  String flowP0TAPGREATs(String p0) {
    return '$p0 個 TAP GREAT';
  }

  @override
  String get flowTodaySRecommendations => '今日推薦';

  @override
  String get flowPreparingTodaySRecommendations => '正在準備今日推薦…';

  @override
  String get flowAnotherBatch => '換一批';

  @override
  String get flowPickingTodaySRecommendations => '正在爲你挑選今日推薦…';

  @override
  String get flowNoChartsToRecommendYetRefreshData => '暫無可推薦的譜面\n請先在首頁刷新數據';

  @override
  String get flowBackupsExportFavoritesChartNotesAccountProfiles =>
      '備份包含收藏夾、譜面筆記、賬號資料、設置、猜歌統計、成績與 Rating 歷史、自定義背景及本地譜麪包歸檔，導出爲 JSON 文件。\n\n登錄憑據、個人 key 和自動同步身份不會導出，換設備後需重新授權。曲庫、maidata、音源、PV 和排行榜等可重新獲取的緩存不備份。\n\n兼容舊版備份；舊備份僅能恢復其中原本包含的設置和資料。文件總大小上限爲 50 MB。';

  @override
  String get flowExportBackup => '導出備份';

  @override
  String get flowExportLocalDataAsAJSONFile => '將當前所有本地數據導出爲 JSON 文件';

  @override
  String flowExportedToP0(String p0) {
    return '已導出到: $p0';
  }

  @override
  String get flowImportBackup => '導入備份';

  @override
  String get flowRestoreDataFromAJSONBackup => '從 JSON 文件恢復之前備份的數據';

  @override
  String get flowChooseWhereToSaveTheBackup => '選擇備份保存位置';

  @override
  String get flowExportCancelled => '導出已取消';

  @override
  String get flowConfirmRestore => '確認恢復數據';

  @override
  String get flowRestoringOverwritesCurrentLocalSettingsAndProfiles =>
      '恢復將覆蓋當前本地設置與用戶資料。v3 備份還會恢復用戶文件；舊版備份只能恢復它原本包含的內容。建議先導出當前備份。';

  @override
  String flowBackupVersionVP0(String p0) {
    return '備份版本: v$p0';
  }

  @override
  String flowExportedP0(String p0) {
    return '導出時間: $p0';
  }

  @override
  String flowContainsP0DataItems(String p0) {
    return '包含 $p0 個數據項';
  }

  @override
  String flowUserFilesP0(String p0) {
    return '用戶文件：$p0 個';
  }

  @override
  String flowExcludedP0CacheItems(String p0) {
    return '已排除 $p0 個緩存項';
  }

  @override
  String get flowSongMaidataAndLeaderboardCachesAreExcluded =>
      '曲庫、maidata、排行榜等緩存不參與備份，恢復後按需重新獲取，首次加載可能稍慢。登錄憑據不會從備份恢復。';

  @override
  String get flowThisCannotBeUndoneContinue => '此操作不可撤銷，確定要繼續嗎？';

  @override
  String get flowRestore => '確認恢復';

  @override
  String flowRestoredP0SettingsAndP1UserFiles(String p0, String p1) {
    return '數據恢復成功！共恢復 $p0 項設置和 $p1 個用戶文件。\n建議重啓應用以確保完全生效。';
  }

  @override
  String flowImportFailedP02(String p0) {
    return '導入失敗: $p0';
  }

  @override
  String get flowMinimumConstant => '最低定數';

  @override
  String get flowMaximumConstant => '最高定數';

  @override
  String get flowNoRecommendationsCheckTheConstantRange =>
      '暫無推薦結果，請檢查定數區間輸入是否正確';

  @override
  String get flowRenameFavoritesFolder => '重命名收藏夾';

  @override
  String get flowEnterANewName => '請輸入新名稱';

  @override
  String get flowDeleteFavoritesFolder => '刪除收藏夾';

  @override
  String flowDeleteP0ChartsWillRemainButWill(String p0) {
    return '確定要刪除收藏夾「$p0」嗎？\n收藏夾內的譜面不會被刪除，但將不再分組。';
  }

  @override
  String flowDeletedP0(String p0) {
    return '已刪除收藏夾「$p0」';
  }

  @override
  String get flowImportFavorites => '導入收藏夾';

  @override
  String get flowAddChartsToFavoritesFoldersFromSong => '在樂曲詳情頁中可以將譜面收藏到收藏夾';

  @override
  String flowOrUseImportFavoritesAboveP0(String p0) {
    return '也可以點上方「導入收藏夾」按鈕，$p0';
  }

  @override
  String get flowRemoveChart => '移除譜面';

  @override
  String flowRemoveP1FromP0(String p0, String p1) {
    return '確定從「$p0」中移除「$p1」嗎？';
  }

  @override
  String get flowRemove => '移除';

  @override
  String get flowRemoved => '已移除';

  @override
  String get flowSortOrder => '排序方式';

  @override
  String get flowExportFavorites => '導出收藏夾';

  @override
  String get flowFavoritesFolderIsEmpty => '收藏夾爲空';

  @override
  String get flowRemoveFromFavoritesFolder => '從收藏夾移除';

  @override
  String flowP0Selected(String p0) {
    return '已選 $p0 項';
  }

  @override
  String get flowMove => '移動';

  @override
  String get flowRemoveMultipleCharts => '批量移除譜面';

  @override
  String flowRemoveP1ChartsFromP0(String p0, String p1) {
    return '確定要從「$p0」中移除 $p1 個譜面嗎？';
  }

  @override
  String flowRemovedP0Charts(String p0) {
    return '已移除 $p0 個譜面';
  }

  @override
  String get flowNoOtherFoldersToMoveTo => '沒有其他收藏夾可移動';

  @override
  String get flowMoveTo => '移動到...';

  @override
  String flowMovedP0Charts(String p0) {
    return '已移動 $p0 個譜面';
  }

  @override
  String get flowThisFolderIsEmptyThereAreNo => '這個收藏夾還是空的，沒有可導出的譜面';

  @override
  String get flowChooseWhereToExportFavorites => '選擇收藏夾導出位置';

  @override
  String flowExportedP02(String p0) {
    return '已導出 $p0';
  }

  @override
  String get flowImportItInTheAppOrOpen =>
      '可以直接在 App 內「導入收藏夾」，或在文件管理器裏點開該文件一鍵導回';

  @override
  String get flowFileSavedTo => '文件已保存到：';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved =>
      '公開目錄不可寫，文件已保存到應用私有目錄，可能無法在系統文件管理器中直接找到。';

  @override
  String get flowInvalidLink => '鏈接無效';

  @override
  String get flowCouldNotOpenABrowserLinkCopied3 => '無法打開瀏覽器，鏈接已複製到剪貼板';

  @override
  String get flowRelatedCommunityProjectsTapACardTo =>
      '這裏收錄了同好/同行項目的友情鏈接，點擊卡片即可在瀏覽器中打開。';

  @override
  String flowSkippedP0ForThisSession(String p0) {
    return '已跳過 $p0（僅本次）';
  }

  @override
  String flowCouldNotSaveFeedbackP0(String p0) {
    return '保存反饋失敗：$p0';
  }

  @override
  String flowStoppedRecommendingP0UndoInFeedbackManagement(String p0) {
    return '不再推薦 $p0（可在反饋管理裏撤銷）';
  }

  @override
  String flowPausedRecommendationsForP0For14Days(String p0) {
    return '$p0 暫停推薦 14 天';
  }

  @override
  String get flowUndo => '撤銷';

  @override
  String get flowManageFeedback => '反饋管理';

  @override
  String get flowNoChartsCanDirectlyRaiseYourRating =>
      '暫時沒有能直接漲 Rating 的譜面。\n刷新成績後再來看看吧。';

  @override
  String get flowNoUnseenCandidatesMatchStartOverOr =>
      '暫無符合條件的未見候選。\n可以重新開始，或在反饋管理裏撤銷屏蔽。';

  @override
  String get flowTotalGainIfAllTargetsOnThis => '本頁全部達成的合計（按 B50 逐步重算，已扣除互相頂替）';

  @override
  String flowBatchP0P1EntriesEachGainIs(String p0, String p1) {
    return '第 $p0 批 · $p1 條（每條爲獨立淨收益，不可直接相加）';
  }

  @override
  String get flowStartOver => '重新開始';

  @override
  String get flowNoMore => '已無更多';

  @override
  String get flowCurrentB50 => '當前 B50';

  @override
  String flowB35CutoffP0(String p0) {
    return 'B35 · 底線 $p0';
  }

  @override
  String flowB15CutoffP0(String p0) {
    return 'B15 · 底線 $p0';
  }

  @override
  String flowCountedB35P0P1B15P2P3(String p0, String p1, String p2, String p3) {
    return '已計入 B35 $p0/$p1 · B15 $p2/$p3';
  }

  @override
  String get flowNetGain => '淨收益';

  @override
  String get flowFeedback => '反饋';

  @override
  String get flowSkipThisTime => '這次跳過';

  @override
  String get flowTemporarilyStuck14Days => '暫時卡住（14 天）';

  @override
  String get flowDislikeThisChart => '不喜歡這張譜';

  @override
  String flowNoScoreRecordedReferenceTargetP0(String p0) {
    return '未記錄成績 → 參考目標 $p0%';
  }

  @override
  String flowP0P1GainP2(String p0, String p1, String p2) {
    return '$p0% → $p1%（提升 $p2%）';
  }

  @override
  String get flowSteadyTargetImprovement020Challenge0 =>
      '穩妥 = 目標提升 ≤ 0.20%，挑戰 = 提升 ≤ 0.80%，探索 = 未記錄成績、按你同定數檔的中位成績估算。「穩妥」指差距小，不是成功率。\n基於本地緩存的成績計算，刷新數據後結果會更新。';

  @override
  String get flowRatingGainRecommendationsPoweredByAWMC => '喫分推薦算法由 AWMC 提供支持';

  @override
  String get flowUndoingDoesNotInsertChartsBackInto =>
      '撤銷後譜面不會插回當前這一批，換批或重新開始時纔會再出現。';

  @override
  String get flowNoFeedbackYet => '還沒有反饋記錄';

  @override
  String get flowDislikedUntilUndone => '不喜歡 · 直到撤銷';

  @override
  String flowTemporarilyStuckClearsAutomaticallyOnP0(String p0) {
    return '暫時卡住 · $p0 自動解除';
  }

  @override
  String flowP0ArcadesTapToExpand(String p0) {
    return '$p0 家機廳，點擊展開';
  }

  @override
  String get flowTurnOnDeviceLocationServicesFirst => '請先開啓設備定位服務';

  @override
  String get flowLocationPermissionIsPermanentlyDeniedEnableIt =>
      '定位權限已被永久拒絕，請在系統設置中開啓';

  @override
  String get flowCouldNotGetYourLocationCheckThat => '無法獲取當前位置，請確認已開啓定位服務且信號良好';

  @override
  String flowLocationFailedP0(String p0) {
    return '定位失敗: $p0';
  }

  @override
  String get flowFiltered => ' (篩選)';

  @override
  String flowP0ArcadesInViewNearbyPointsGrouped(String p0) {
    return ' 視野內 $p0 家（鄰近點自動合併）';
  }

  @override
  String flowLastUpdatedP0(String p0) {
    return '上次更新: $p0';
  }

  @override
  String get flowSearchArcadeNameOrAddress => '搜索店名或地址';

  @override
  String get flowMachineFilters => '機臺篩選';

  @override
  String get flowNoArcadeDataYet => '暫無店鋪數據';

  @override
  String get flowMachines => '🎮 機臺:';

  @override
  String get flowCouldNotOpenTheLinkTryAgain => '無法打開鏈接，請稍後重試';

  @override
  String get flowCouldNotLoadDocumentTapToRetry => '文檔讀取失敗，點擊重試';

  @override
  String get flowSubmitALoadingQuote => '上傳語錄到雲端';

  @override
  String get flowAddALocalQuote => '本地新增語錄';

  @override
  String get flowUploadFailedTryAgainLater => '上傳失敗，請稍後重試';

  @override
  String flowSubmittedForReviewP0ShownOnlyAfter(String p0) {
    return '已提交審覈（$p0），審覈通過後纔會展示';
  }

  @override
  String get flowLocalQuoteAdded => '本地語錄添加成功';

  @override
  String get flowCouldNotFetchLoadingQuotesKeptThe => '獲取加載語錄失敗，已保留本地緩存';

  @override
  String get flowRefreshQuotes => '刷新語錄';

  @override
  String flowP0QuotesEnabled(String p0) {
    return '/ $p0 條已啓用';
  }

  @override
  String get flowAddLocally => '本地新增';

  @override
  String get flowUploadToCloud => '上傳到雲端';

  @override
  String get flowDeleteLocalQuote => '刪除本地語錄';

  @override
  String get flowEnterALoadingQuote => '輸入加載語錄';

  @override
  String get flowDataFromIsMaiDownByChongxi => '數據來源於 isMaiDown by Chongxi';

  @override
  String get flowServiceStatus => '服務狀態';

  @override
  String get flowReadingServerStatus => '正在讀取服務器狀態…';

  @override
  String flowUpdatedP02(String p0) {
    return '更新時間：$p0';
  }

  @override
  String get flowDifficultyNotSpecified => '未指定難度';

  @override
  String flowNoteP0(String p0) {
    return '備註：$p0';
  }

  @override
  String get flowRemoveThisEntry => '移除這一次';

  @override
  String get flowMeetChiffonMai => '先認識一下 ChiffonMai';

  @override
  String get flowFiveTabsKeepEverythingWithinReach => '五個標籤頁，想找的東西都在這裏。';

  @override
  String get flowRefreshDataThenStartExploring => '先刷新數據，再開始探索';

  @override
  String get flowARefreshPreparesSongsConstantsTagsAnd =>
      '刷新數據會準備曲庫、定數、標籤和成績。\n不登錄也可以先逛逛。';

  @override
  String get flowMakeItFeelLikeYourApp => '把體驗調成你喜歡的樣子';

  @override
  String get flowFindTheseOptionsInMeSettingsAnd => '都在「我的」頁的設置裏，隨時可以改。';

  @override
  String get flowPhotosAndMedia => '相冊與媒體';

  @override
  String get flowChooseCoverArtAndSaveExportedSong => '用於選擇曲繪、保存導出的歌曲信息和成績圖片。';

  @override
  String get flowCamera => '相機';

  @override
  String get flowCaptureCoverArtOrScoreImagesFor => '用於拍攝曲繪或成績截圖進行識別。';

  @override
  String get flowLocation => '位置';

  @override
  String get flowUsedForLocationFeaturesOnTheGlobal => '用於全球機廳地圖中的位置服務。';

  @override
  String get flowNotifications => '通知';

  @override
  String get flowShowPlaybackControlsDuringBackgroundMusicPlayback =>
      '用於隨身聽後臺播放時顯示通知欄控制。';

  @override
  String get flowCouldNotSaveConfirmationPleaseRetry => '確認記錄保存失敗，請重試';

  @override
  String get flowSeparateGuardianConsent => '監護人單獨同意';

  @override
  String get flowPleaseHandTheDeviceToAGuardian =>
      '請將設備交由監護人操作。監護人應閱讀以下文件，瞭解所處理的信息、用途，以及查詢和刪除信息的方式。';

  @override
  String get flowIAmThisUserSGuardianI =>
      '我是該用戶的監護人，已閱讀並同意《用戶協議》和《隱私政策》，同意爲提供相應功能處理被監護人的必要個人信息。';

  @override
  String get flowAfterConsentPermissionsAndFeaturesRemainOptional =>
      '同意後，仍可按需選擇權限和相關功能；也可按隱私政策說明撤回授權或申請刪除信息。';

  @override
  String get flowGuardianConsent => '監護人同意';

  @override
  String get flowGoBackOnceMoreToExit => '再返回一次退出應用';

  @override
  String get flowGettingStartedWithChiffonMai => 'ChiffonMai 入門';

  @override
  String get flowPrevious3 => '上一步';

  @override
  String get flowStartExploring => '開始探索';

  @override
  String get flowNext3 => '下一步';

  @override
  String get flowWelcomeToChiffonMai => '歡迎來到 ChiffonMai';

  @override
  String get flowSongsChartsScoresAndUsefulToolsAll =>
      '歌曲、譜面、成績與實用工具都在這裏，\n從查一首歌到推一次分，慢慢來就好。';

  @override
  String get flowAllSet => '準備完成！';

  @override
  String get flowStartExploringWithASong => '接下來，就從一首歌開始探索吧。';

  @override
  String flowCouldNotRequestPermissionP0(String p0) {
    return '申請權限失敗：$p0';
  }

  @override
  String get flowAgreementsAndPermissions => '協議與權限';

  @override
  String get flowAgreeToTheDocumentsFirstYouCan =>
      '先確認協議才能繼續。權限可以現在允許，也可以等用到時再說。';

  @override
  String get flowTheSystemManagesNetworkAccessBackgroundPlayback =>
      '網絡、後臺播放和安全存儲由系統自動管理，不需要在這裏單獨授權。';

  @override
  String get flowIHaveReadAndAgreeTo => '我已閱讀並同意';

  @override
  String get flowUserAgreement => '《用戶協議》';

  @override
  String get flowPrivacyPolicy => '《隱私政策》';

  @override
  String get flowToProvideTheGameServiceWeProcess =>
      '爲提供遊戲服務，我們會處理你的遊玩記錄、歌曲成績、賬號及設備標識等必要信息；多人聯機對戰會實時傳輸對局通信數據，僅用於維持聯機功能。';

  @override
  String get flowUsersUnder18ShouldUseTheApp =>
      '未滿18週歲請在監護人指導下使用。未滿14週歲需由監護人單獨同意。';

  @override
  String get flowGuardianHasGivenSeparateConsent => '監護人已單獨同意';

  @override
  String get flowUnder14GuardianMustProvideConsent => '未滿14週歲，由監護人完成同意';

  @override
  String flowP0SelectAllowFullAccessInThe(String p0) {
    return '$p0 請在系統彈窗中選擇“允許完全訪問”。';
  }

  @override
  String get flowAccessIsCurrentlyLimitedChangeToAllow =>
      '當前是有限訪問，請在系統設置中改爲“允許完全訪問”。';

  @override
  String get flowNotAuthorizedYetPermissionWillBeRequested =>
      '當前未授權，使用相關功能時仍會再次請求。';

  @override
  String get flowOpenSettings => '去設置';

  @override
  String get flowAllow => '允許';

  @override
  String flowDrawFailedP0(String p0) {
    return '抽取失敗：$p0';
  }

  @override
  String get flowNumberToDraw => '抽取數量';

  @override
  String get flowPreparing => '準備中…';

  @override
  String get flowStop => '停！';

  @override
  String get flowStartDrawing => '開始抽獎';

  @override
  String get flowDrawResults => '抽取結果';

  @override
  String flowP0SongsDrawn(String p0) {
    return '本次抽取 $p0 首';
  }

  @override
  String get flowDrawHistory => '歷史抽取記錄';

  @override
  String get flowNoHistoryYet2 => '暫無歷史記錄';

  @override
  String get flowRecommendationRange => '推薦範圍';

  @override
  String get flowPrioritizeChartsInRange => '範圍內譜面優先';

  @override
  String get flowRecalculateByTargetRating => '按目標 Rating 重新計算';

  @override
  String get flowRecalculateByConstantRange => '按定數區間重新計算';

  @override
  String get flowCalculatingRecommendations => '正在計算推薦結果...';

  @override
  String get flowSongConstant => '歌曲定數';

  @override
  String get flowSongRating => '單曲 Rating';

  @override
  String get flowMultiplier => '乘數';

  @override
  String get flowEnterConstantAndAchievementToCalculateSong =>
      '填好定數和達成率後自動計算 · 單曲 Rating = 定數 × 乘數 × 達成率（取整）';

  @override
  String get flowSongRatingConstantMultiplierAchievementRoundedDown =>
      '單曲 Rating = 定數 × 乘數 × 達成率（取整）';

  @override
  String get flowEquivalentConstants => '等效定數對照';

  @override
  String flowEquivalentToP0(String p0) {
    return '相當於 $p0';
  }

  @override
  String get flowMultiplierTable => '乘數對照表';

  @override
  String get flowUseTheMultiplierWhenAchievementMeetsThe =>
      '達成率不低於左列時使用對應乘數；超過 100.5% 按 100.5% 計算';

  @override
  String get flowAchievement4 => '達成率 ≥';

  @override
  String get flowChooseWhereToSaveTheSupportQR => '選擇讚賞碼保存位置';

  @override
  String get flowSupportQRCodeSaved => '讚賞碼已保存';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved2 =>
      '公開目錄不可寫，已保存到應用文檔目錄。可通過分享或應用文件訪問。';

  @override
  String get flowChiffonMaiIsAFreeOpenSourceTool =>
      'ChiffonMai 是一款完全免費的開源工具，如果它幫到了你，歡迎支持開發者！';

  @override
  String get flowWeChatSupportQRCode => '微信讚賞碼';

  @override
  String get flowDownloadQRImage => '下載讚賞碼圖片';

  @override
  String get flowOrSupportMeOnAfdian => '或通過愛發電支持我';

  @override
  String get flowOpenAfdian => '前往愛發電';

  @override
  String get flowYourSupportKeepsDevelopmentAndMaintenanceGoing =>
      '你的支持是我持續維護與開發的動力，感謝！❤️';

  @override
  String get flowYouAlreadyGuessedThisSong => '已經猜過這首歌了！';

  @override
  String get flowHowToPlay => '規則說明';

  @override
  String get flowGreenTheAttributeMatchesTheTargetExactly =>
      '綠色 - 該屬性與你猜的完全一致。';

  @override
  String get flowOrangeTheAttributeIsCloseToThe => '橙色 - 該屬性與你猜的\"接近\"：';

  @override
  String get flowBPMDiffersByNoMoreThan20 => 'BPM 相差在 ±20 範圍內；';

  @override
  String get flowMASTEROrReMASTERDifficultyDiffersBy =>
      'MASTER 難度或 Re:MASTER 難度相差在 ±0.4範圍內；';

  @override
  String get flowVersionsAreOneGenerationApartEG =>
      '版本相差一個世代（例如 maimai ← maimai PLUS → maimai GreeN）。';

  @override
  String get flowGrayTheAttributeIsFarFromThe => '灰色 - 該屬性與你猜的\"差距較大\"。';

  @override
  String get flowArrows => '箭頭：';

  @override
  String get flowTargetValueIsHigherThanYourGuess => '↑ - 目標值比你猜的更高';

  @override
  String get flowTargetValueIsLowerThanYourGuess => '↓ - 目標值比你猜的更低';

  @override
  String get flowDesignInspiration2 => '設計思路借鑑：';

  @override
  String get flowCouldNotOpenThisLinkLinkCopied => '無法打開該鏈接，鏈接已複製到剪貼板';

  @override
  String get flowNoSongsMatchTheseFiltersBroadenYour => '當前篩選條件抽不到曲目，請放寬篩選條件';

  @override
  String get flowGameSettings => '遊戲設置';

  @override
  String get flowAppliesFromTheNextGame => '保存後下局生效';

  @override
  String get flowSettingsSavedTheyApplyFromTheNext => '設置已保存，將在下局遊戲生效';

  @override
  String get flowLoading5 => '加載中...';

  @override
  String get flowRules => '規則';

  @override
  String get flowSettings => '設置';

  @override
  String get flowNewQuestion => '換一題';

  @override
  String get flowYouGotIt => '恭喜你猜對了！';

  @override
  String get flowThisGameSAnswer => '本局答案';

  @override
  String get flowSearchTitleAliasIDAndMore => '搜索歌名、別名、編號等';

  @override
  String get flowModeSettings => '本模式設置';

  @override
  String get flowDestruction => '破壞程度';

  @override
  String get flowBlur => '模糊程度';

  @override
  String get flowCoverArtIsTurnedIntoAPixel =>
      '曲繪按所選破壞程度處理爲像素馬賽克，請根據色塊、配色和輪廓猜出歌名。0% 爲原圖，數值越高，像素塊越大。';

  @override
  String get flowTheOriginalCoverAppearsAfterACorrect => '猜中、放棄或回合結束後會顯示原始曲繪。';

  @override
  String flowDestructionP0(String p0) {
    return '破壞程度 $p0%';
  }

  @override
  String get flowARandomSongIsChosenFromYour =>
      '從你已緩存譜面的曲庫中隨機選一首，隨機播放一段無聲的譜面動畫片段。';

  @override
  String get flowWatchNoteDensityPatternsAndReachTo =>
      '仔細觀察物量密度、鍵型與出張方式，猜出這是哪首歌。';

  @override
  String flowYouMayReplayTheExcerptUpTo(String p0) {
    return '片段最多可復播 $p0 次。';
  }

  @override
  String get flowTags2 => '標籤：';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor =>
      '顯示您猜測的曲目的 MASTER 難度的配置、難度和評價標籤。';

  @override
  String get flowATagTurnsGreenWhenItMatches => '當一個標籤與目標曲目的屬性一致時，該標籤會變爲綠色。';

  @override
  String get flowSomeSongsMayNotHaveTags => '注意，有些曲目可能未添加標籤。';

  @override
  String get flowNoSongsMatchBroadenTheDifficultyPool =>
      '當前篩選條件抽不到曲目，請放寬難度池 / 定數範圍或篩選條件';

  @override
  String get flowExcerptLength => '片段時長';

  @override
  String get flowNoChartsAvailableCacheMaidataInThe =>
      '沒有可用的譜面，請先在譜面庫中緩存 maidata';

  @override
  String get flowExcerptFinished => '片段播放完畢';

  @override
  String get flowLoadingAudio2 => '正在加載音頻…';

  @override
  String get flowReplayExcerptAudioUnavailable => '復播片段（音頻不可用）';

  @override
  String get flowReplayExcerptWithAudio => '復播片段（帶音頻）';

  @override
  String get flowReplayExcerpt => '復播片段';

  @override
  String get flowPlayExcerpt => '播放片段';

  @override
  String flowReplayP0(String p0) {
    return '復播$p0';
  }

  @override
  String get flowTheCoverFlashesBrieflyAtTheStart =>
      '開局時曲繪會閃現一瞬間（時長可在設置中調整），隨後消失。';

  @override
  String get flowRememberTheCoverThenSearchBelowAnd => '憑記憶在下方搜索並猜出這首歌曲。';

  @override
  String get flowFlashDuration => '快閃時長';

  @override
  String get flowPlaybackLength => '播放時長';

  @override
  String flowAudioPlaybackFailedP0(String p0) {
    return '音頻播放失敗：$p0';
  }

  @override
  String get flowTheCoverIsSplitIntoTilesAt =>
      '曲繪被切成若干小塊，每隔一段時間會隨機揭示其中一批，已揭示的小塊會累積保留 —— 拼圖會越來越完整。';

  @override
  String get flowEarlierGuessesImproveYourScoreAverageTime =>
      '越早猜中得分越高（計入平均用時），也可以等拼圖更完整後再下手。';

  @override
  String get flowTileCount => '切塊數量';

  @override
  String get flowRevealInterval => '揭示間隔';

  @override
  String flowP0RevealedP1P2Tiles(String p0, String p1, String p2) {
    return '已顯示 $p0%（$p1 / $p2 塊）';
  }

  @override
  String get flowRevealPaused => '揭示已暫停';

  @override
  String flowNextRevealInP0S(String p0) {
    return '$p0 秒後揭示下一批';
  }

  @override
  String get flowResumeReveal => '繼續揭示';

  @override
  String get flowPauseReveal => '暫停揭示';

  @override
  String get flowCouldNotReloadSongsCheckYourConnection => '重新拉取曲庫失敗，請檢查網絡後重試';

  @override
  String get flowFetchingSongs => '正在拉取曲庫...';

  @override
  String get flowReloadSongs => '重新拉取曲庫';

  @override
  String get flowOpenSettings2 => '打開設置';

  @override
  String get flowSettingsSavedLocally => '設置已保存到本地';

  @override
  String get flowChangesSaveAutomaticallyAndApplyToThe => '修改會自動保存，下一局生效。';

  @override
  String get flowSongExcerptsReverseAndSpeedPitch => '歌曲片段、倒放與變速變調';

  @override
  String get flowChartExcerpt => '譜面片段';

  @override
  String get flowCoverModes => '曲繪玩法';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate =>
      '破壞程度爲 0% 時顯示原圖，數值越高，像素塊越大。';

  @override
  String get flowRevealLetters => '開字母';

  @override
  String get flowDefaultSettingsRestored => '已恢復默認設置';

  @override
  String get flowEnterOneCharacter => '請輸入一個字符！';

  @override
  String get flowEnterASongTitle => '請輸入歌曲名稱！';

  @override
  String get flowCorrect => '猜對了！';

  @override
  String flowGuessP0(String p0) {
    return '猜測 #$p0';
  }

  @override
  String flow1TheGameRandomlySelectsP0Songs(String p0) {
    return '1. 遊戲開始時，系統會隨機從舞萌曲庫中抽取$p0首歌曲。';
  }

  @override
  String get flow2SendXWhereXIsOne =>
      '2. 玩家可以發送 \"開字母 X\"（X 爲任意漢字、日文、數字或符號，只能輸入一個字符）。';

  @override
  String get flow3IfATitleContainsThatCharacter =>
      '3. 若某首歌曲名包含該字，則揭示該字在歌名中的位置。';

  @override
  String get flow4IfNoTitleContainsItNo => '4. 若不包含，則無提示。';

  @override
  String get flow5UseTheRevealedCharactersToInfer =>
      '5. 玩家根據揭示的文字碎片，推理完整曲名，發送 \"回答 曲名/別名\" 作答。';

  @override
  String get flow6GuessEverySongOrSurrenderTo => '6. 猜中所有歌曲或點擊投降結束遊戲，會公佈遊戲結果。';

  @override
  String get flowSongsPerGame => '每次抽取歌曲數';

  @override
  String get flowNonEnglishCharacterFilterPercentage => '非英文字符過濾百分比';

  @override
  String get flowEnterOneCharacter2 => '輸入一個字符';

  @override
  String get flowSurrender => '投降';

  @override
  String get flowNewGame => '新遊戲';

  @override
  String get flowGuessHistory => '猜測歷史';

  @override
  String get flowBlueGateDetails => '藍色之門詳情';

  @override
  String get flowWhiteGateDetails => '白門詳情';

  @override
  String get flowPurpleGateDetails => '紫色之門詳情';

  @override
  String get flowBlackGateDetails => '黑色之門詳情';

  @override
  String get flowYellowGateDetails => '黃色之門詳情';

  @override
  String get flowRedGateDetails => '紅色之門詳情';

  @override
  String get flowPrismTowerDetails => '棱鏡塔詳情';

  @override
  String get flowGlitchGateDetails => '亂碼之門詳情';

  @override
  String get flowHopeGateDetails => '希望之門詳情';

  @override
  String get flowFinalPhaseDetails => '最終相詳情';

  @override
  String get flowNoActiveChallengesCheckTheScheduleBelow =>
      '暫無進行中的挑戰，可以看看下方的時間安排';

  @override
  String get flowCurrentPhase => '當前階段';

  @override
  String get flowLIFEPhase1Phase2 => 'LIFE 一階段 / 二階段';

  @override
  String get flowInProgress => '進行中';

  @override
  String flowPhase1P0(String p0) {
    return '一階段 $p0';
  }

  @override
  String flowPhase2P0(String p0) {
    return '二階段 $p0';
  }

  @override
  String flowMarkedP0P1(String p0, String p1) {
    return '已標記 $p0 / $p1';
  }

  @override
  String get flowTapASongToToggleCompletion => '點擊歌曲可切換完成狀態';

  @override
  String get flowEnableMarkingThenTapSongsToRecord => '開啓標記後點歌曲記錄完成情況';

  @override
  String get flowMarkingMode => '標記模式';

  @override
  String get flowCouldNotLoadTheGuideTryAgain => '攻略加載失敗，請稍後重試';

  @override
  String flowSongIDP02(String p0) {
    return '歌曲 ID $p0';
  }

  @override
  String get flowRefreshTheLibraryToShowSongInformation => '刷新曲庫後顯示歌曲信息';

  @override
  String get flowRefreshGateList => '刷新門列表';

  @override
  String get flowEnterYourLXNSPersonalAPIKey => '請輸入落雪個人 API 密鑰';

  @override
  String get flowLXNSAPIKeySaved => '落雪 API 密鑰已保存';

  @override
  String get flowSavedLocallyItWillBeLinkedTo => '已本地保存，同步時將自動綁定到雲端';

  @override
  String get flowSetYourLXNSPersonalAPIKeyFirst => '請先設置落雪個人 API 密鑰';

  @override
  String get flowHowDoIGetIt => '如何獲取？';

  @override
  String get flowThenScrollToTheBottomToFind => '，滑到頁面最底部即可找到個人 API 密鑰。';

  @override
  String get flowLXNSAPIKeyIsSet => '落雪 API 密鑰已設置';

  @override
  String flowClosesAutomaticallyInP0S(String p0) {
    return '${p0}s 後自動關閉';
  }

  @override
  String flowP0GotItP1Points(String p0, String p1) {
    return '🎉 $p0 答對了! +$p1分';
  }

  @override
  String get flowNoConfirmationReceivedCheckYourConnectionAnd =>
      '操作未收到確認，請檢查連接後重試';

  @override
  String get flowTimingStartsWhenTheRoundBeginsNot =>
      '注意：計時是從「回合開始」算的，不是從「猜中上一首」算的。所以後面幾首天然比第一首慢 —— 不是你的錯覺。';

  @override
  String get flowConfirmLeaving => '確認離開';

  @override
  String get flowLeaveThisRoom => '是否離開當前房間？';

  @override
  String get flowLeave => '離開';

  @override
  String get flowNoConfirmationOfLeavingReceivedPleaseRetry => '退出房間未收到確認，請重試';

  @override
  String flowCouldNotLeaveRoomP0(String p0) {
    return '退出房間失敗：$p0';
  }

  @override
  String get flowRestoringGame => '正在恢復對局…';

  @override
  String get flowWaitingForTheGameToStart => '等待遊戲開始...';

  @override
  String get flowGameOver => '遊戲結束!';

  @override
  String get flowPlayAgain => '再來一局';

  @override
  String get flowRoundOver => '回合結束!';

  @override
  String get flowNextRound2 => '下一輪';

  @override
  String get flowYouSurrenderedWaitingForOtherPlayers => '已投降，請等待其他玩家……';

  @override
  String flowTimeRemainingP0S(String p0) {
    return '⏱️ 剩餘時間: $p0 秒';
  }

  @override
  String get flowWaitingForServerConfirmation => '正在等待服務端確認…';

  @override
  String get flowTimeIsUpWaitingForRoundResults => '時間到，正在等待回合結算…';

  @override
  String get flowSearchSongIDBPMChartDesignerAnd => '搜索歌曲、ID、BPM、譜師等';

  @override
  String get flowTimeLeft => '剩餘時間';

  @override
  String get flowGuessesLeft => '剩餘次數';

  @override
  String flowP0Points(String p0) {
    return '$p0 分';
  }

  @override
  String flowThisSongHasP0Aliases(String p0) {
    return '該歌曲共有 $p0 個別名';
  }

  @override
  String get flowNoAliasesAvailableGuessFromTheSong => '暫無別名數據，請根據歌曲信息猜歌';

  @override
  String get flowThisRoundHasEnded => '本回合已結束';

  @override
  String flowP0P1SongsRemaining(String p0, String p1) {
    return '剩餘 $p0 / $p1 首';
  }

  @override
  String get flowRevealed => '已開:';

  @override
  String get flowCharacters => '字';

  @override
  String get flowPreparingCoverClue => '正在準備曲繪線索…';

  @override
  String get flowWaitingForPlayersToLoadTheCover => '等待玩家加載曲繪…';

  @override
  String get flowFlashingRememberIt => '快閃中……記住它！';

  @override
  String get flowTheCoverIsHiddenGuessFromMemory => '曲繪已消失，憑記憶猜歌名';

  @override
  String flowP0P1TilesRevealedP2(String p0, String p1, String p2) {
    return '已揭示 $p0 / $p1 塊$p2';
  }

  @override
  String get flowPaused2 => '（已暫停）';

  @override
  String get flowPreparingChartExcerpt => '正在準備譜面片段…';

  @override
  String get flowNoReplaysLeft => '復播次數已用完';

  @override
  String get flowGuessTheSongFromThisCoverFragment => '根據截取的曲繪部分猜歌名';

  @override
  String get flowOriginalCover => '原始曲繪';

  @override
  String flowBlurP0(String p0) {
    return '模糊程度: $p0%';
  }

  @override
  String get flowSongExcerpt => '歌曲片段';

  @override
  String get flowTheGameHasEnded => '遊戲已結束';

  @override
  String get flowReplay => '重新播放';

  @override
  String get flowPlaySongExcerpt => '播放歌曲片段';

  @override
  String get flowMultiplayerRoom => '多人房間';

  @override
  String flowP0RoundP1P2(String p0, String p1, String p2) {
    return '$p0 · 第 $p1/$p2 輪';
  }

  @override
  String get flowReconnect => '重新連接';

  @override
  String flowCouldNotCreateRoomP0(String p0) {
    return '創建房間失敗：$p0';
  }

  @override
  String flowCouldNotJoinRoomP0(String p0) {
    return '加入房間失敗：$p0';
  }

  @override
  String flowYouAreStillInRoomP0(String p0) {
    return '你還在房間 $p0 裏';
  }

  @override
  String flowP0P1PlayersTapToReturn(String p0, String p1) {
    return '$p0 · $p1 人 · 點擊返回';
  }

  @override
  String get flowCreateRoom => '創建房間';

  @override
  String get flowChooseAModeAndRulesThenInvite => '選擇玩法和規則，邀請好友一起猜歌';

  @override
  String get flowJoinRoom => '加入房間';

  @override
  String get flowEnterARoomCodeSharedByA => '輸入好友分享的房間碼';

  @override
  String get flowCouldNotCreateRoom => '創建房間失敗';

  @override
  String flowCouldNotCreateRoomP02(String p0) {
    return '創建房間失敗: $p0';
  }

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate2 =>
      '0% 爲原圖，數值越高，像素塊越大。房間內所有玩家使用相同破壞程度。';

  @override
  String get flowSpeedPitchMultiplier => '變速變調倍率';

  @override
  String get flowRestoreDefaults => '恢復默認設置';

  @override
  String get flowGameMode => '遊戲模式';

  @override
  String get flowMaximumPlayers => '最大玩家數';

  @override
  String flowP0Settings(String p0) {
    return '$p0設置';
  }

  @override
  String get flowEnterRoomCode => '輸入房間碼';

  @override
  String get flowEnterA6DigitCodeOrThe => '輸入 6 位房間碼，也支持完整房間 ID';

  @override
  String get flowPasteRoomCode => '粘貼房間碼';

  @override
  String get flowHowDoIGetARoomCode => '如何獲取房間碼？';

  @override
  String get flowUpdateDownloadedInstallWhenConvenient => '更新已下載，可在方便時安裝';

  @override
  String get flowViewInstallation => '查看安裝';

  @override
  String get flowView => '查看';

  @override
  String get flowPreparingTheUpdateInTheBackgroundYou => '正在後臺準備更新，可以繼續使用 App';

  @override
  String flowExportingP0InTheBackgroundYouCan(String p0) {
    return '正在後臺導出$p0，可以繼續其它操作';
  }

  @override
  String flowCouldNotExportP0PleaseRetry(String p0) {
    return '$p0導出失敗，請重試';
  }

  @override
  String flowCouldNotExportP0CheckStoragePermission(String p0) {
    return '$p0導出失敗，請檢查存儲權限後重試';
  }

  @override
  String flowP0Exported(String p0) {
    return '$p0導出成功';
  }

  @override
  String flowCouldNotExportP0P1(String p0, String p1) {
    return '$p0導出失敗：$p1';
  }

  @override
  String get flowCouldNotLoadAppearanceReopenThisPage => '裝扮未能讀取，請重新打開此頁';

  @override
  String get flowChiffonMaiClosedUnexpectedlyLastTime => 'ChiffonMai 上次異常退出';

  @override
  String flowReasonP0AutomaticLogExportFailedExport(String p0) {
    return '原因：$p0。\n日誌自動導出失敗，可以在「我的 → 打印日誌」手動導出。';
  }

  @override
  String get flowChiffonChuAnAllInOneCHUNITHMTool => '這是ChiffonChu，一站式中二工具';

  @override
  String get flowWebMiniGamesFromTheAWMCCommunity => '來自AWMC社區出品的網頁小遊戲，持續迭代中！';

  @override
  String get flowAnInnovativeRhythmGameInspiredByRailways => '融合鐵路元素的創新音遊';

  @override
  String get flowAnOfflineMaimaiLibraryWithQuickCover =>
      '一個通過封面快速查詢的離線本地maimai曲庫';

  @override
  String flowRefusedRequestToANonGatewayAddress(String p0) {
    return '拒絕請求非網關地址: $p0';
  }

  @override
  String flowUnsupportedMethodP0(String p0) {
    return '不支持的方法: $p0';
  }

  @override
  String flowRequestTimedOutP0S(String p0) {
    return '請求超時（${p0}s）';
  }

  @override
  String flowCouldNotScheduleWriteP0(String p0) {
    return '寫入調度失敗: $p0';
  }

  @override
  String flowMusicListMustContain14EntriesCurrently(String p0) {
    return 'musicList 長度必須爲 1–4（當前 $p0）';
  }

  @override
  String get flowOnlyChargeId235IsSupported =>
      '僅支持 chargeId = 2 / 3 / 5（2 倍 / 3 倍 / 5 倍票）';

  @override
  String flowOrderP0(String p0) {
    return '排序：$p0';
  }

  @override
  String flowSourceP0ExportedP1GeneratedByChiffonMai(
      String p0, String p1, String p2) {
    return '數據源：$p0\n導出時間：$p1\nGenerated by ChiffonMai\n交流羣：$p2';
  }

  @override
  String get flowCouldNotCreateRoomEnvironmentIDIs => '創建房間失敗: 環境ID未設置';

  @override
  String get flowCouldNotCreateRoomNotSignedIn => '創建房間失敗: 用戶未登錄';

  @override
  String flowCouldNotJoinRoomP02(String p0) {
    return '加入房間失敗: $p0';
  }

  @override
  String flowCouldNotRejoinRoomP0(String p0) {
    return '重新加入房間失敗: $p0';
  }

  @override
  String flowCouldNotChangeReadyStatusP0(String p0) {
    return '設置準備狀態失敗: $p0';
  }

  @override
  String flowCouldNotChangeSurrenderStatusP0(String p0) {
    return '設置投降狀態失敗: $p0';
  }

  @override
  String flowCouldNotStartGameP0(String p0) {
    return '開始遊戲失敗: $p0';
  }

  @override
  String flowCouldNotStartNextRoundP0(String p0) {
    return '開始下一回合失敗: $p0';
  }

  @override
  String flowCouldNotSubmitGuessP0(String p0) {
    return '提交猜測失敗: $p0';
  }

  @override
  String flowCouldNotRevealLetterP0(String p0) {
    return '開字母失敗: $p0';
  }

  @override
  String flowCouldNotSurrenderP0(String p0) {
    return '投降失敗: $p0';
  }

  @override
  String flowCouldNotUploadSongsP0(String p0) {
    return '上傳歌曲失敗: $p0';
  }

  @override
  String flowCouldNotGetSongCountP0(String p0) {
    return '獲取歌曲數量失敗: $p0';
  }

  @override
  String flowCouldNotParseMessageP0(String p0) {
    return '消息解析失敗: $p0';
  }

  @override
  String get flowYellow => '黃';

  @override
  String get flowCurrentSaveLocation => '當前保存位置';

  @override
  String get flowUseTheDefaultPublicDirectoryOrChoose =>
      '可以使用應用默認公開目錄，或選擇一個自定義文件夾。';

  @override
  String flowCouldNotChooseSaveFolderP0(String p0) {
    return '選擇保存目錄失敗：$p0';
  }

  @override
  String get flowChooseAnotherFolder => '選擇其他目錄';

  @override
  String get flowUseDefaultPath => '使用默認路徑';

  @override
  String get flowThisFolderIsNotWritableChooseAnother => '這個目錄不可寫，請換一個文件夾。';

  @override
  String get flowCannotImport => '無法導入';

  @override
  String flowImportCompleteP0(String p0) {
    return '導入完成：$p0';
  }

  @override
  String flowP0FoldersP1Charts(String p0, String p1) {
    return '共 $p0 個收藏夾、$p1 個譜面';
  }

  @override
  String flowP0P1Charts2(String p0, String p1) {
    return '· $p0（$p1 個譜面）';
  }

  @override
  String flowP0MoreFolders(String p0) {
    return '· 其餘 $p0 個收藏夾…';
  }

  @override
  String get flowMergeWithExistingFolders => '合併到現有收藏夾';

  @override
  String get flowFoldersWithTheSameNameAreMerged => '同名收藏夾會合並，重複譜面自動跳過';

  @override
  String get flowReplaceExistingFavorites => '覆蓋導入';

  @override
  String get flowClearAllCurrentFoldersThenImportThe => '先清空當前所有收藏夾，再導入文件內容';

  @override
  String get flowImport => '導入';

  @override
  String flowP0Loading(String p0) {
    return '$p0，加載中';
  }

  @override
  String get flowUnavailable => '暫不可用';

  @override
  String get flowIncrease => '，增加';

  @override
  String get flowDecrease => '，減少';

  @override
  String flowP0P1P2BeijingTime(String p0, String p1, String p2) {
    return '$p0-$p1-$p2 · 北京時間';
  }

  @override
  String get flowDoNotShowThisAnnouncementAgain => '不再提示本條公告';

  @override
  String get flowCouldNotLoadImageTapToRetry => '圖片加載失敗，點擊重試';

  @override
  String get flowEnlargeAnnouncementImage => '放大公告圖片';

  @override
  String flowDecreaseP0ByOne(String p0) {
    return '$p0減一';
  }

  @override
  String flowIncreaseP0ByOne(String p0) {
    return '$p0加一';
  }

  @override
  String get flowInstallUpdate => '安裝更新';

  @override
  String get flowDownloadUpdateInBackground => '後臺下載更新';

  @override
  String get flowNoDownloadTask => '暫無下載任務';

  @override
  String get flowKeepUsingTheApp => '繼續使用 App';

  @override
  String get flowCancelInstallationTask => '取消安裝任務';

  @override
  String get flowCancelDownload => '取消下載';

  @override
  String get flowDownloadAgain => '重新下載';

  @override
  String get flowAllowInstallation => '允許安裝';

  @override
  String get flowInstallNow => '立即安裝';

  @override
  String get flowCalculatingCacheSize => '正在統計緩存佔用…';

  @override
  String flowTotalUsageP0(String p0) {
    return '總佔用 $p0';
  }

  @override
  String get flowAudioCache => '音源緩存';

  @override
  String get flowCalculating3 => '統計中…';

  @override
  String flowP0FilesTotalP1(String p0, String p1) {
    return '$p0 個文件\n共計 $p1';
  }

  @override
  String get flowPVCache => 'PV緩存';

  @override
  String get flowMaidataCache => 'maidata緩存';

  @override
  String get flowReloadBaseMaidata => '重新拉取基礎量maidata';

  @override
  String flowCleaningP0(String p0) {
    return '正在清理… $p0%';
  }

  @override
  String get flowCleaning => '清理中…';

  @override
  String get flowClear2 => '清理';

  @override
  String flowNoteSpeedP0P1(String p0, String p1) {
    return '流速 $p0 · $p1';
  }

  @override
  String get flowNoteSpeed => '流速';

  @override
  String get flowMirror => '鏡像';

  @override
  String get flowRandomDifficultyPool => '難度隨機池';

  @override
  String flowP0ConstantP12(String p0, String p1) {
    return '$p0 定數 $p1';
  }

  @override
  String get flowUTAGE2 => '宴會';

  @override
  String get flowResetTodaySStatistics => '重置今日統計？';

  @override
  String get flowClearTodaySCorrectIncorrectGuessesTimes =>
      '將清空當前玩法今日的正確、錯誤、用時和連勝記錄。';

  @override
  String flowP0SRemaining(String p0) {
    return '剩餘 $p0 秒';
  }

  @override
  String get flowResetTodaySStatistics2 => '重置今日統計';

  @override
  String get flowResetStatistics => '重置統計';

  @override
  String get flowThisGameHasEnded => '本局已結束';

  @override
  String flowAnswerP0(String p0) {
    return '正確答案：$p0';
  }

  @override
  String get flowOriginalAudioExcerpt => '原聲片段';

  @override
  String get flowPreparingOriginalAudio => '正在準備原聲…';

  @override
  String get flowTheSameExcerptPlayedForwardAtOriginal => '本輪同一段音源，按原速正向播放';

  @override
  String get flowSelectAll2 => '選擇全部';

  @override
  String get flowCurrentAll => '當前：全部';

  @override
  String flowP0SelectedNoneMeansAll(String p0) {
    return '已選 $p0 項，不選表示全部';
  }

  @override
  String get flowMASTERTags => 'MASTER標籤';

  @override
  String flowGuessHistoryP0(String p0) {
    return '猜測歷史 ($p0)';
  }

  @override
  String get flowOldestFirst => '從早到晚';

  @override
  String get flowNewestFirst => '從晚到早';

  @override
  String get flowCouldNotOpenTheGuideSourceLink => '無法打開攻略來源，鏈接已複製到剪貼板';

  @override
  String get flowDataSourceAWMCKALEIDXSCOPE => '數據來源：AWMC KALEIDXSCOPE';

  @override
  String get flowRoom => '房間 ';

  @override
  String flowP0PlayersP1(String p0, String p1) {
    return ' · $p0 人 · $p1';
  }

  @override
  String get flowCopyRoomCode => '複製房間碼';

  @override
  String get flowRoomCodeCopied => '房間碼已複製';

  @override
  String get flowInviteFriendsToGuessSongsTogether => '邀請好友，一起猜歌';

  @override
  String get flowRoomCode => '房間碼';

  @override
  String get flowRoomCodeCopiedSendItToA => '房間碼已複製，發送給好友即可加入';

  @override
  String get flowPlayerSlots => '玩家席位';

  @override
  String flowP0P1PlayersP2(String p0, String p1, String p2) {
    return '$p0 / $p1 人$p2';
  }

  @override
  String flowP0Ready(String p0) {
    return ' · $p0 人準備';
  }

  @override
  String get flowWaitingForPlayers => '等待加入';

  @override
  String get flowMe2 => ' · 我';

  @override
  String get flowNotReady => '取消準備';

  @override
  String get flowReady => '準備就緒';

  @override
  String get flowStartGame => '開始遊戲';

  @override
  String get flowDecreaseCount2 => '減少數量';

  @override
  String get flowIncreaseCount2 => '增加數量';

  @override
  String get flowConnectionRestored => '已恢復網絡連接';

  @override
  String get flowOfflineShowingCachedData => '當前離線 - 顯示緩存數據';

  @override
  String flowDrawingP0SongsTapStopToReveal(String p0) {
    return '正在抽取 $p0 首 · 點擊“停！”揭曉';
  }

  @override
  String flowCardP0WaitingToReveal(String p0) {
    return '第 $p0 張卡片，等待揭曉';
  }

  @override
  String get flowCyclingCoverArt => '曲繪輪播中…';

  @override
  String flowSongP0WaitingForYouToStop(String p0) {
    return '第 $p0 首 · 等待你按停';
  }

  @override
  String get flowChiffonMaiIsAnAllInOneMobile =>
      'ChiffonMai 是一款專爲 舞萌DX 2026（maimai DX 2026）玩家打造的一站式移動端工具類應用，聚合了曲庫查詢、成績統計、Rating 計算、曲目推薦等多種實用功能，助力玩家提升遊玩體驗。';

  @override
  String get flowProvidedTheBackgroundArtworkAndTheLovely =>
      '爲本項目提供的背景圖和戚風小狐狸（真的非常可愛）';

  @override
  String get flowContributedValuableIdeasForPersonalizedChartRecommendations =>
      '爲本項目的個性化譜面推薦功能提供寶貴設計思路';

  @override
  String get flowContributedValuableFeedbackOnPageDesign => '爲本項目的頁面設計提供了寶貴意見';

  @override
  String get flowProvidedPersonalPlayDataForDevelopmentAnd =>
      '提供了用於測試開發的個人遊玩數據';

  @override
  String get flowProposedChiffonMaiAndHelpedSparkTheProject =>
      '提議開發 ChiffonMai，爲本項目誕生提供最初契機';

  @override
  String get flowContributedManySuggestionsOnInterfaceDetailsAnd =>
      '爲本項目在前端細節與交互體驗上提供了諸多寶貴建議';

  @override
  String get flowProvidedTechnicalAndFinancialSupportThatGreatly =>
      '爲本項目的開發提供了技術支持和經濟支持，爲項目的推進提供了極大的幫助';

  @override
  String get flowEveryoneInTheChiffonMaiCommunityGroup => 'ChiffonMai交流羣的全體羣友';

  @override
  String get flowContributedManySuggestionsAndFeedbackDuringDevelopment =>
      '爲本項目開發提供了諸多寶貴建議和反饋';

  @override
  String get flowDivingFish => '水魚查分器';

  @override
  String get flowProvidesSongAndPlayerScoreDatabases => '提供曲目數據庫和玩家遊玩記錄數據庫';

  @override
  String get flowProvidesChartTagAndAliasDatabases => '提供譜面標籤數據庫和別名數據庫';

  @override
  String get flowProvidesAnAliasDatabase => '提供別名數據庫';

  @override
  String get flowLXNS => '落雪咖啡屋';

  @override
  String get flowProvidesCollectiblesAudioSongAndPlayerScore =>
      '提供收藏品數據庫、歌曲音源支持、曲目數據庫和玩家遊玩記錄數據庫';

  @override
  String get flowProvidesChartConversionSupport => '提供譜面轉換支持';

  @override
  String get flowProvidesMaimaiServerStatus => '提供舞萌服務器狀態信息';

  @override
  String get flowProvidesDivingFishLXNSSyncAndFinancial =>
      '提供水魚查分器同步支持、落雪查分器同步支持和對本項目開發的經濟支持';

  @override
  String get flowProvidesScoreSyncToDivingFishAnd => '提供水魚查分器和落雪查分器成績同步支持';

  @override
  String get flowProvidesScoreSyncToLXNS => '提供落雪查分器成績同步支持';

  @override
  String get flowProvidesASongDatabase => '提供曲目數據庫';

  @override
  String get flowProvidesWorldwideArcadeData => '提供全球機廳相關數據';

  @override
  String get flowProvidesHighResolutionVersionArtwork => '提供高清版本圖片';

  @override
  String get flowThankYouForYourDonations => '感謝對本項目的捐獻支持';

  @override
  String get flowMaintainer => '維護者';

  @override
  String get flowTheDeveloperBehindChiffonMai => 'ChiffonMai 背後的開發者。';

  @override
  String get flowSpecialThanks => '特別緻謝';

  @override
  String get flowThanksToEveryoneWhoHelpedInNo => '感謝每一位給予幫助的夥伴，排名不分先後。';

  @override
  String get flowBilibili => 'B 站';

  @override
  String get flowEmail => '郵箱';

  @override
  String get flowSignInFailedTryAgainLater => '登錄失敗，請稍後再試';

  @override
  String get flowEnterTargetAchievement => '請輸入目標達成率';

  @override
  String get flowInvalidAchievementEnterANumberSuchAs =>
      '達成率格式錯誤，請輸入有效的數字（如100.5000）';

  @override
  String get flowEnterAchievementBetween0And101 => '達成率請輸入0~101之間的數值';

  @override
  String get flow50PointLoss2 => '50落';

  @override
  String get flow100PointLoss2 => '100落';

  @override
  String get flowBase100Bonus100 => '基礎 100% · 獎勵 100%';

  @override
  String get flowPERFECT50PointLoss => 'PERFECT · 50落';

  @override
  String get flowBase100Bonus75 => '基礎 100% · 獎勵 75%';

  @override
  String get flowPERFECT100PointLoss => 'PERFECT · 100落';

  @override
  String get flowBase100Bonus50 => '基礎 100% · 獎勵 50%';

  @override
  String get flowBase80Bonus40 => '基礎 80% · 獎勵 40%';

  @override
  String get flowBase60Bonus40 => '基礎 60% · 獎勵 40%';

  @override
  String get flowBase50Bonus40 => '基礎 50% · 獎勵 40%';

  @override
  String get flowBase40Bonus30 => '基礎 40% · 獎勵 30%';

  @override
  String get flowBase0Bonus0 => '基礎 0% · 獎勵 0%';

  @override
  String get flowNoLoss => '無損失';

  @override
  String get flowStayHome => '不出勤';

  @override
  String get flowScoreTargetsBREAKDistribution => '分數線 / 絕贊分佈';

  @override
  String get flowRatingTargets => 'Rating 線';

  @override
  String get flowCalculationMode => '計算模式';

  @override
  String get flowByAchievement => '按達成率';

  @override
  String get flowByRating => '按 Rating';

  @override
  String get flowResult2 => '計算結果';

  @override
  String get flowTargetRating2 => '目標Rating';

  @override
  String get flowEG143 => '如 14.3';

  @override
  String get flowEG1005667 => '如 100.5667';

  @override
  String get flowEG321 => '如 321';

  @override
  String flowAchievementP02(String p0) {
    return '達成率$p0';
  }

  @override
  String get flowNoteDistributionEditable => '物量分佈（可編輯）';

  @override
  String get flowScoreLossDetails => '得分 / 失分詳細';

  @override
  String flowP0P1P2WeekdayP3(String p0, String p1, String p2, String p3) {
    return '$p0年$p1月$p2日 星期$p3';
  }

  @override
  String get flowExporting3 => '導出中...';

  @override
  String get flowExportBackupFile => '導出備份文件';

  @override
  String get flowRestoringData => '正在恢復數據...';

  @override
  String get flowImporting => '導入中...';

  @override
  String get flowChooseBackupFile => '選擇備份文件';

  @override
  String get flowImportClearsAllCurrentLocalDataBefore =>
      '⚠ 導入會先清空當前所有本地數據，再寫入備份內容；\n　 備份裏沒有的項目（含各類緩存）會被一併抹掉。\n　 恢復過程中請不要退出頁面。';

  @override
  String get flowBackupFile => '備份文件';

  @override
  String get flowFindTheFileInDownloadsChiffonMaiIn =>
      '可在文件管理器的「下載/ChiffonMai/備份」文件夾中找到該文件。';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved3 => '公開目錄不可寫，已保存到應用文檔目錄。';

  @override
  String get flowRename => '重命名';

  @override
  String get flowConstantHighLow => '按定數 (高→低)';

  @override
  String get flowConstantLowHigh => '按定數 (低→高)';

  @override
  String get flowAddedNewOld => '按添加時間 (新→舊)';

  @override
  String get flowAddedOldNew => '按添加時間 (舊→新)';

  @override
  String get flowSongTitleAZ => '按歌曲名 (A-Z)';

  @override
  String get flowSignOut2 => '登出賬號';

  @override
  String get flowGetAnImportTokenForScoreSync => '獲取ImportToken以便同步成績';

  @override
  String get flowOnlineLinksAreUnavailableShowingLocallyCached =>
      '在線友鏈暫時不可用，當前顯示本地緩存';

  @override
  String flowCouldNotGenerateRecommendationsP0(String p0) {
    return '生成推薦失敗：$p0';
  }

  @override
  String get flowMixed => '混合';

  @override
  String flowSourceRatingP0DiffersFromTheLocally(String p0) {
    return '數據源 Rating $p0，與本地按成績重算的結果不同，以重算爲準';
  }

  @override
  String flowP0ScoresAreMissingFromTheSong(String p0) {
    return '$p0 條成績在曲庫裏找不到，按舊曲處理；刷新曲庫後更準確';
  }

  @override
  String flowP0P12(String p0, String p1) {
    return '$p0月$p1日';
  }

  @override
  String flowP0Arcades(String p0) {
    return '$p0家';
  }

  @override
  String flowP0ArcadesTotal(String p0) {
    return '共$p0家';
  }

  @override
  String get flowDivingFishSignInFailedTryAgain => '水魚登錄失敗，請稍後重試';

  @override
  String get flowUserAgreement2 => '用戶協議';

  @override
  String get flowPrivacyPolicy2 => '隱私政策';

  @override
  String flowLocalQuotesP0(String p0) {
    return '本地語錄 $p0';
  }

  @override
  String flowCloudQuotesP0(String p0) {
    return '雲端語錄 $p0';
  }

  @override
  String get flowQuoteCannotBeEmpty => '語錄內容不能爲空';

  @override
  String get flowServerStatusIsTemporarilyUnavailable => '暫時無法獲取服務器狀態';

  @override
  String get flowCouldNotLoadServerStatus => '加載服務器狀態失敗';

  @override
  String get flowHealthy => '好';

  @override
  String get flowUnhealthy => '壞';

  @override
  String get flowLatency => '延遲 --';

  @override
  String flowLatencyP0Ms(String p0) {
    return '延遲 $p0 ms';
  }

  @override
  String flowHealthyP0(String p0) {
    return '正常 $p0';
  }

  @override
  String flowIssuesP0(String p0) {
    return '異常 $p0';
  }

  @override
  String get flowNoSongsAddedYetUseAddTo => '還沒有加入歌曲\n在歌曲詳情或隨身聽中點「加入下次想玩」吧';

  @override
  String get flowProfileFavoriteFeaturesSyncAndServerStatus =>
      '個人概況、常用功能、同步和服務器狀態';

  @override
  String get flowFindSongsInspectChartsAndBrowseCollectibles => '查歌曲、看譜面、找收藏品';

  @override
  String get flowBest50RatingToolsAndLeaderboards => 'Best50、推分工具和排行榜';

  @override
  String get flowFindArcadesPlayGuessingGamesAndListen => '出勤找機廳，休閒猜歌和聽歌';

  @override
  String get flowAccountsDataRefreshAndSettings => '賬號、刷新數據和各種設置';

  @override
  String get flowOpenFromMeOrTapYourRating => '在「我的」頁，或點首頁的 Rating 進入';

  @override
  String get flowSyncScores => '同步成績';

  @override
  String get flowDivingFishLXNSAndAWMCNETLink => '水魚、落雪和 AWMC NET，需先綁定賬號';

  @override
  String get flowRunsThroughoutTheDayWhenEnabledCheck => '開啓後每天分時處理，首頁隨時能看結果';

  @override
  String get flowTheme => '主題';

  @override
  String get flowLightDarkBlackOrSystemThemePlus => '淺色、深色、純黑或跟隨系統，還能換主題色';

  @override
  String get flowCustomBackgroundImagesDecorationsAndOverlays =>
      '自定義背景圖、裝飾圖和覆層';

  @override
  String get flowNavigation => '導航';

  @override
  String get flowThreeNavigationStylesWithOptionalAnimationAnd =>
      '三種導航欄樣式，動畫和滑動切換可開關';

  @override
  String get flowConfetti => '紙屑';

  @override
  String get flowCelebrateASuccessfulRefreshOrSyncWith => '刷新或同步成功時放一點紙屑';

  @override
  String get flowEverythingIsReadyRememberToRefreshData => '都準備好了呢。記得先刷新一下數據哦？';

  @override
  String get flowChecking => '檢查中';

  @override
  String get flowAllowed => '已允許';

  @override
  String get flowLimitedAccess => '有限訪問';

  @override
  String get flowOpenSettings3 => '請前往設置';

  @override
  String get flowNotAllowed => '未允許';

  @override
  String get flowIHaveReadAndAgreeToThe => '我已閱讀並同意用戶協議和隱私政策';

  @override
  String get flowChooseYourFiltersThenDrawSomeSongs => '選好條件後，開始抽歌吧';

  @override
  String get flowEnterAnIntegerFrom2To100 => '請輸入 2–100 之間的整數';

  @override
  String get flowDrawCountMustBeBetween2And => '抽取數量需在 2–100 之間';

  @override
  String get flowNoMatchingSongsAdjustTheFilters => '沒有符合條件的歌曲，請調整篩選條件';

  @override
  String get flowSongs3 => ' 首';

  @override
  String get flowAllVersions => '全部版本';

  @override
  String flowP0VersionsSelected(String p0) {
    return '已選 $p0 個版本';
  }

  @override
  String get flowTypeFilter => '類型篩選';

  @override
  String get flowAllTypes => '全部類型';

  @override
  String flowP0TypesSelected(String p0) {
    return '已選 $p0 個類型';
  }

  @override
  String get flowConstantRange => '定數範圍';

  @override
  String get flowAdvancedMASTER => 'MASTER 上級';

  @override
  String get flowExpertMASTER => 'MASTER 超上級';

  @override
  String flowCouldNotFetchRecommendationsP0(String p0) {
    return '獲取推薦結果失敗：$p0';
  }

  @override
  String get flowConstantRange2 => '定數區間';

  @override
  String get flowSimilarity => '相似度';

  @override
  String flowCurrentP0TargetP1(String p0, String p1) {
    return '當前 $p0% → 目標 $p1%';
  }

  @override
  String flowEnterAValidP0(String p0) {
    return '請輸入有效的$p0';
  }

  @override
  String flowP0MustBeBetweenP1AndP2(String p0, String p1, String p2) {
    return '$p0必須在$p1到$p2之間';
  }

  @override
  String flowP1ForP0(String p0, String p1) {
    return '$p0 的 $p1';
  }

  @override
  String get flowMultiPlatformSync => '多端同步';

  @override
  String get flowAdvancedDataRefresh => '高級數據刷新';

  @override
  String get flowReadPlayCounts => '讀取遊玩次數';

  @override
  String get flowSignOut3 => '退出賬號';

  @override
  String get flowHomeDataRefresh => '首頁數據刷新';

  @override
  String get flowWebsiteLink => '官網鏈接';

  @override
  String get flowFeedbackLink => '反饋鏈接';

  @override
  String get flowGroupNumber => '羣號';

  @override
  String get flowSurveyLink => '問卷鏈接';

  @override
  String get flowGatewayCheckBeforeReadingPlayCounts => '讀取遊玩次數前的網關探活';

  @override
  String get flowReadPlayCountsSeparately => '獨立讀取遊玩次數';

  @override
  String get flowPushToDivingFishThroughTheAWMC => '通過 AWMC 網關推送到水魚';

  @override
  String get flowPushToLXNSThroughTheAWMCGateway => '通過 AWMC 網關推送到落雪';

  @override
  String get flowCouldNotLoadTheMosaicCoverTry => '馬賽克曲繪暫時無法加載，請換一題重試';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate3 => '0% 爲原圖，數值越高，像素塊越大。';

  @override
  String get flowNoCachedChartsCacheMaidataInThe => '譜面緩存爲空，請先在譜面庫中緩存 maidata';

  @override
  String get flowNoCachedSongsMatchTheDifficultyPool =>
      '沒有符合當前篩選條件（難度池 / 定數範圍）且有譜面緩存的歌曲';

  @override
  String get flowCouldNotReadThisSongSChart => '未能讀取該歌曲的譜面內容';

  @override
  String get flowThisSongHasNoChartsInThe => '該歌曲沒有難度池內的譜面';

  @override
  String get flowTheChartIsTooShortToExtract => '譜面過短，無法截取片段';

  @override
  String get flowCouldNotParseChart => '譜面解析失敗';

  @override
  String flowP0ReplaysLeft(String p0) {
    return '（還可復播 $p0 次）';
  }

  @override
  String get flowNoReplaysLeft2 => '（復播次數已用完）';

  @override
  String get flowFiltersUseEachSelectedDifficultySOwn =>
      '按「難度隨機池」裏各難度自己的定數篩選（例如只選 EXPERT 時看 EXPERT 的定數，選 EXPERT+MASTER 時兩者任一落在範圍內即可），不是按 MASTER 定數。';

  @override
  String get flowCouldNotLoadCoverArtPleaseRetry => '曲繪暫時無法加載，請重試';

  @override
  String get flowNoRecognizableCropAreaInThisCover =>
      '當前曲繪沒有可辨認的裁剪區域，請重試或放寬篩選條件';

  @override
  String get flowAudioIsTemporarilyUnavailable => '暫時無法獲取音源';

  @override
  String get flowCouldNotReadAudioDuration => '無法讀取音源時長';

  @override
  String get flowAudioExcerptIsEmpty => '音頻片段爲空';

  @override
  String get flowPreparingAudio2 => '正在準備音頻…';

  @override
  String flowP0Tiles(String p0) {
    return '$p0 塊';
  }

  @override
  String get flowTheSongCacheIsEmptyNoSong => '曲庫緩存爲空，暫時抽不出曲目';

  @override
  String get flowNoSongsMatchBroadenTheFiltersIn => '當前篩選條件抽不到曲目，請在設置中放寬條件';

  @override
  String get flowCouldNotLoadSettingsPleaseRetry => '設置加載失敗，請重試';

  @override
  String get flowExcerptPlaybackLength => '片段播放時長';

  @override
  String get flowS => ' 秒';

  @override
  String get flowBlurredCoverBlur => '模糊曲繪：模糊程度';

  @override
  String get flowPixelCoverDestruction => '像素曲繪：破壞程度';

  @override
  String get flowFlashCoverDuration => '曲繪快閃：快閃時長';

  @override
  String get flowTileRevealTileCount => '曲繪拼圖：切塊數量';

  @override
  String get flowTiles => ' 塊';

  @override
  String get flowTileRevealInterval => '曲繪拼圖：揭示間隔';

  @override
  String get flowNonEnglishCharacterThreshold => '非英文字符過濾閾值';

  @override
  String get flowExcludeSongsWhoseShareOfJapaneseAnd =>
      '過濾日語+除空格以外的非英文字符在歌名中的佔比大於等於此值的歌曲';

  @override
  String get flowRemainingSongs => '剩餘歌曲';

  @override
  String get flowYouGuessedEverySong => '恭喜你猜對了所有歌曲！';

  @override
  String get flowSongsFromAllAreas => '所有區域歌曲';

  @override
  String get flowPerfectChallengeSongsFromAllAreas => '所有區域內的完美挑戰曲';

  @override
  String get flowFixedTheHiddenSong => '固定，即爲隱藏歌曲';

  @override
  String get flowBlueGateEntrance => '青門（藍色之門）門扉';

  @override
  String get flowSkyStreetArea6 => '天空街區域6';

  @override
  String get flowWhiteGateEntrance => '白門門扉';

  @override
  String get flowHeavenArea8 => '天界區域8';

  @override
  String get flowPurpleGateEntrance => '紫門門扉';

  @override
  String get flowPurpleRoseArea10 => '紫薔薇區域10';

  @override
  String get flowBlackGateEntrance => '黑門門扉';

  @override
  String get flowMetropolisArea9 => '大都會區域9';

  @override
  String get flowPlayAll11SongsInThePool => '完成下方曲目池內的11首歌曲（全部遊玩）';

  @override
  String get flowTrackSkipIsAllowedDanCertificationAnd =>
      '可：跳過（Track Skip）/不可：段位認定和宴會場';

  @override
  String get flowYellowGateEntrance => '黃門門扉';

  @override
  String get flowRainbowArea => '七彩區域（なないろちほー）';

  @override
  String get flowAfterTheGateUpdateUseRandomSong =>
      '在門更新之後，使用隨機選曲，隨出一次以下曲目池中的任意一首並遊玩';

  @override
  String get flowAnyDifficultyRetryingIsAllowedFavoritesCategories =>
      '（不限難度，不需要一次隨出可以返回重試，可以使用收藏分類）';

  @override
  String get flowRandomSelectionInTheDepartureArea => '啓程區域隨機選曲';

  @override
  String get flowRandomPerfectChallengeSongMAXRAGEAndUniTas =>
      '啓程區域隨機完美挑戰曲、MAXRAGE和UniTas';

  @override
  String get flowRedGateEntrance => '赤門（紅色之門）門扉';

  @override
  String get flowSongPool => '曲目池';

  @override
  String get flowGateConditions => '門扉條件';

  @override
  String get flowNotSet3 => '（未設置）';

  @override
  String get flowKeyRequiredToChallenge => '鑰匙（挑戰所需的物品）';

  @override
  String get flowKALEIDXSCOPEMode => 'KALEIDXSCOPE 模式';

  @override
  String flowFirstSongP0(String p0) {
    return '第一首：$p0';
  }

  @override
  String flowSecondSongP0(String p0) {
    return '第二首：$p0';
  }

  @override
  String flowThirdSongP0(String p0) {
    return '第三首：$p0';
  }

  @override
  String get flowPerfectChallengeSong => '完美挑戰曲';

  @override
  String get flowClearRewardSong => '通關解鎖歌曲';

  @override
  String get flowHiddenSong => '隱藏歌曲';

  @override
  String get flowPerfectChallenge => '小P';

  @override
  String get flowGuide => '攻略';

  @override
  String get flowSongs4 => '曲目';

  @override
  String get flowBlueGate => '青の扉（藍色之門）';

  @override
  String get flowWhiteGate => '白の扉（白色之門）';

  @override
  String get flowPurpleGate => '紫の扉（紫色之門）';

  @override
  String get flowBlackGate => '黑の扉（黑色之門）';

  @override
  String get flowYellowGate => '黃の扉（黃色之門）';

  @override
  String get flowRedGate => '赤の扉（紅色之門）';

  @override
  String get flowCouldNotLoadNewGatesRefreshUsing => '新增門列表加載失敗，請點擊右上角刷新';

  @override
  String get flowDraw => '🤝 平局';

  @override
  String get flowJointWinners => '🤝 並列獲勝';

  @override
  String get flowYouWon => '🏆 你贏了！';

  @override
  String flowP0Won(String p0) {
    return '🏆 $p0 獲勝';
  }

  @override
  String get flowNoOneScoredInThisGame => '本局無人得分';

  @override
  String get flowCouldNotConnectToTheRoomCheck => '房間連接失敗，請檢查網絡後重試';

  @override
  String flowP0IsNowTheHost(String p0) {
    return '$p0 成爲了房主';
  }

  @override
  String get flowNoCoverArtAvailable => '沒有可用曲繪';

  @override
  String get flowScoring => '得分機制';

  @override
  String get flowCorrectAnswer100SecondsSinceTheRound =>
      '答對得分 = 100 − 從回合開始經過的秒數，最低 10 分；答錯 0 分。';

  @override
  String get flowFasterAnswersScoreHigherInstantAnswersApproach =>
      '也就是越快猜中分數越高：秒答接近 100 分，拖到最後也有 10 分保底。';

  @override
  String get flowOnlyYourBestAttemptForEachSong =>
      '同一首曲目只按你在這首上最好的一次計分，重複提交不會刷分。';

  @override
  String get flowOnlyTheFirstCorrectPlayerScoresFor =>
      '每一首曲目只給最先猜中的人計分，其餘人這首拿 0 分。';

  @override
  String get flowIncorrectGuessesDoNotSubtractPoints => '猜錯不扣分，不用怕猜錯拖累總分。';

  @override
  String get flowLetterRevealHasSeveralSongsPerRound =>
      '開字母一回合有多首曲目，每首獨立計分，單回合滿分 = 曲目數 × 100。';

  @override
  String get flowColorMeanings => '顏色含義';

  @override
  String get flowYellowCloseToTheTargetBPMWithin =>
      '黃色 - 該屬性與你猜的接近：BPM 相差 ±20 以內；MASTER / Re:MASTER 難度相差 ±0.4 以內；版本相差一個世代（maimai ← maimai PLUS → maimai GreeN）。';

  @override
  String get flowGrayFarFromTheTarget => '灰色 - 該屬性與你猜的差距較大。';

  @override
  String get flowArrows2 => '箭頭';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor2 =>
      '顯示你猜的曲目在 MASTER 難度下的配置、難度和評價標籤。';

  @override
  String get flowAMatchingTargetTagTurnsGreen => '當某個標籤與目標曲目一致時，該標籤會變綠。';

  @override
  String get flowSomeSongsMayNotHaveTags2 => '注意：有些曲目可能未添加標籤。';

  @override
  String get flowLetterRevealRules => '開字母玩法';

  @override
  String get flowTitlesAreMaskedWithAnyoneCanReveal =>
      '本回合曲名以 □ 遮蔽，每人可開字母逐字揭示，開出的字母全房間可見。';

  @override
  String get flowEachCharacterCanBeRevealedOnlyOnce => '同一個字母只能開一次。';

  @override
  String get flowOnceASongIsGuessedItsFull => '猜中某首後，該曲名會對全房間公開完整名稱。';

  @override
  String get flowGuessingFirstMayRevealTheAnswerBut =>
      '搶先猜中可能要「送答案」，但每首隻給最先猜中的人計分，先猜中仍然划算。';

  @override
  String get flowTheRoundEndsOnlyWhenEveryTitle => '把所有曲名都猜中，本回合才結束。';

  @override
  String get flowRoomRules => '房間規則';

  @override
  String get flowRemainingGuessesAreSharedByTheWhole =>
      '剩餘猜測次數是全房間共享的，誰先猜都消耗同一個池子，用完本回合即結束。';

  @override
  String get flowAfterSurrenderingYouCannotScoreOrSubmit =>
      '投降後本回合不再計分，也無法再提交猜測；但仍可圍觀其他人繼續。';

  @override
  String get flowWinning => '勝負判定';

  @override
  String get flowTheHighestTotalScoreAfterAllRounds => '全部回合結束後，總分最高的人獲勝。';

  @override
  String get flowEqualScoresShareTheWinIfNo => '同分則並列獲勝；全場無人得分時算平局。';

  @override
  String get flowScoresAreSettledAtTheEndOf => '分數在每回合結束時結算，排行榜顯示的就是結算後的總分。';

  @override
  String get flowNoTimeLimit => '不限時';

  @override
  String get flowTimeIsUp => '時間到';

  @override
  String get flowAlmostOutOfTime => '快沒時間了！';

  @override
  String get flowPlentyOfTime => '還很充裕';

  @override
  String get flowAliasClue => '別名提示';

  @override
  String get flowReplayExcerptAudioPreparing => '復播片段（音頻準備中）';

  @override
  String flowReplayExcerptP0ReplaysLeft(String p0) {
    return '復播片段（還可復播 $p0 次）';
  }

  @override
  String get flowAnswerUnlimitedReplaysChartOnlyAudioUnavailable =>
      '本局答案：片段可無限復播（音頻不可用，僅有譜面）';

  @override
  String get flowAnswerUnlimitedReplaysWithAudio => '本局答案：片段可無限復播，帶音頻';

  @override
  String get flowAnswerUnlimitedReplaysPreparingAudio =>
      '本局答案：片段可無限復播（正在準備音頻…）';

  @override
  String get flowPlaybackStopsAutomaticallyAtTheEndOf => '片段播完會自動停在結尾';

  @override
  String get flowThisChartIsNotCachedOnThis => '本機沒有該曲的譜面緩存，自動拉取也沒拿到';

  @override
  String get flowNoChartForThisSongMatchesThe => '這首曲沒有符合難度池 / 定數範圍的譜面';

  @override
  String flowCouldNotReadInoteP0ForThis(String p0) {
    return '未能讀取該曲 inote_$p0 譜面';
  }

  @override
  String get flowCouldNotPlayChartExcerptPleaseRetry => '譜面片段播放失敗，請重試';

  @override
  String get flowInvalidSongID => '歌曲編號無效';

  @override
  String get flowCouldNotFetchAudioTryAgainLater => '未能獲取音頻，請稍後重試';

  @override
  String get flowLeavingRoom => '正在退出房間…';

  @override
  String get flowRoomDoesNotExistOrCannotBe => '房間不存在或無法加入';

  @override
  String get flow2Players => '2 人';

  @override
  String get flow3Players => '3 人';

  @override
  String get flow4Players => '4 人';

  @override
  String get flow5Players => '5 人';

  @override
  String get flow6Players => '6 人';

  @override
  String get flowRoomCodeCannotBeEmpty => '房間碼不能爲空';

  @override
  String get flowAfterCreatingARoomTheHostCan => '房主創建房間後，可在房間頁面複製房間碼。';

  @override
  String get flowAskYourFriendToSendTheCode => '讓好友把房間碼發給你，在上面粘貼就能加入。';

  @override
  String get flowCouldNotReadAutomaticInstallationSettingsPlease =>
      '無法讀取自動安裝設置，請重試';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettingsPlease =>
      '自動安裝設置保存失敗，請重試';

  @override
  String get flowCouldNotOpenInstallationSourceSettingsAllow =>
      '無法打開安裝來源設置，請在系統設置中允許 ChiffonMai 安裝應用';

  @override
  String get flowDownloadCancelledByUser => '用戶取消下載';

  @override
  String get flowThisVersionHasNotBeenPublishedYet => '該版本尚未正式發佈';

  @override
  String get flowCouldNotIdentifyASingleAPKFor => '未找到適合此設備的唯一 APK，請使用網頁下載';

  @override
  String get flowReleaseAssetLacksValidAPKInformationOr =>
      '發佈附件缺少有效的安裝包信息或 SHA-256 校驗值';

  @override
  String get flowCouldNotFetchGitHubReleaseInformation => '無法獲取 GitHub 發佈信息';

  @override
  String get flowFetchingAPKInformation => '正在獲取安裝包信息…';

  @override
  String get flowPreparingBackgroundDownload => '正在準備後臺下載…';

  @override
  String get flowCouldNotStartBackgroundDownload => '無法開始後臺下載';

  @override
  String get flowCouldNotStartBackgroundDownloadPleaseRetry => '無法開始後臺下載，請重試';

  @override
  String get flowCouldNotReadExcerptDuration => '無法讀取片段時長';

  @override
  String get flowAudioExcerptIsIncomplete => '音頻片段不完整';

  @override
  String get flowAudioResponseIsNotAValidWAV => '音頻響應不是有效的 WAV 文件';

  @override
  String get flowNoAliases => '無別名';

  @override
  String get flowTooLate => '猜晚了';

  @override
  String get flowTooEarly => '猜早了';

  @override
  String get flowInitializationFailed => '初始化失敗';

  @override
  String get flowInitializationTimedOut => '初始化超時';

  @override
  String flowRepeatOneP0Times(String p0) {
    return '單曲循環 $p0 次';
  }

  @override
  String get flowCurrentSong => '當前曲目';

  @override
  String flowLXNSAudioFailedForP0TryingWmc(String p0) {
    return '《$p0》落雪音源失敗，嘗試 wmc 兜底…';
  }

  @override
  String flowNoAudioAvailableForP0Skipped(String p0) {
    return '《$p0》當前暫無可用音源，已跳過';
  }

  @override
  String get flowChiffonMaiMusicPlayer => 'ChiffonMai 隨身聽';

  @override
  String get flowSeveralSongsFailedToLoadAutomaticSkipping =>
      '連續多首音源都加載失敗，已停止自動跳過（請檢查網絡後重試）';

  @override
  String flowNowPlayingP0(String p0) {
    return '正在播放：$p0';
  }

  @override
  String flowCouldNotSaveAudioP0(String p0) {
    return '音源保存失敗：$p0';
  }

  @override
  String get flowInvalidAPKDirectoryRange => 'APK 目錄範圍無效';

  @override
  String get flowIncompleteAPKDirectoryData => 'APK 目錄數據不完整';

  @override
  String get flowCouldNotReadAPKZIPDirectory => '無法讀取 APK 的 ZIP 目錄';

  @override
  String get flowInvalidAPKManifestSize => 'APK 清單大小無效';

  @override
  String get flowInvalidAPKManifestDirectory => 'APK 清單目錄無效';

  @override
  String get flowAPKManifestDecompressedSizeMismatch => 'APK 清單解壓大小不一致';

  @override
  String get flowUnsupportedAPKManifestCompression => 'APK 清單壓縮格式不支持';

  @override
  String get flowIncompleteAPKManifestData => 'APK 清單數據不完整';

  @override
  String get flowAPKHasNoVersionManifest => 'APK 中沒有版本清單';

  @override
  String get flowInvalidBinaryAPKManifest => 'APK 二進制清單無效';

  @override
  String get flowInvalidAPKManifestStringIndex => 'APK 清單字符串索引無效';

  @override
  String get flowInvalidAPKManifestChunk => 'APK 清單分塊無效';

  @override
  String get flowInvalidAPKManifestStringTable => 'APK 清單字符串表無效';

  @override
  String get flowInvalidAPKManifestAttribute => 'APK 清單屬性無效';

  @override
  String get flowAPKManifestAttributeOutOfBounds => 'APK 清單屬性越界';

  @override
  String get flowAPKLacksValidVersionInformation => 'APK 缺少有效版本信息';

  @override
  String get flowAPKHasNoAppVersionInformation => 'APK 中沒有應用版本信息';

  @override
  String get flowAPKManifestDataOutOfBounds => 'APK 清單數據越界';

  @override
  String get flowContentContainsDisallowedWordingEditItAnd =>
      '內容包含不合規詞句，請修改後重試';

  @override
  String get flowMASTERConstantRange => 'MASTER定數範圍';

  @override
  String get flowUnlimited2 => '無限制';

  @override
  String get flowEnterOneValueOrACompleteRange => '請輸入單值或完整區間，如 13.7 或 13.4-14';

  @override
  String get flowConstantMustBeAFiniteNumberGreater => '定數必須是大於 0 的有限數字';

  @override
  String get flowLowerBoundCannotExceedUpperBound => '區間下限不能大於上限';

  @override
  String get flowUnknownDifficulty => '未知難度';

  @override
  String get flowUTAGECannotBeCombinedWithNormalDifficulties =>
      'UTAGE 不能與普通難度同時填寫';

  @override
  String get flowChooseSaveLocation => '選擇保存位置';

  @override
  String get flowPublicExportDirectoryIsNotWritableWriting =>
      '公開導出目錄不可寫，已拒絕寫入應用私有目錄';

  @override
  String flowSupportsChiffonMaiFavoritesFilesSuchAsP0(String p0) {
    return '支持 $p0 等 ChiffonMai 收藏夾文件';
  }

  @override
  String get flowCouldNotReadCoverPixels => '無法讀取曲繪像素';

  @override
  String get flowCouldNotReadImageData => '無法讀取圖片數據';

  @override
  String get flowDateToBeUpdated => '日期待更新';

  @override
  String get flowLater => '後續';

  @override
  String get flowWaitForRetryAfterSecondsOrQuotaResetAtBefore =>
      '等待 retryAfterSeconds 或 quota.resetAt 後再重試';

  @override
  String flowRetryAfterSecondsP0S(String p0) {
    return 'retryAfterSeconds（$p0 秒）';
  }

  @override
  String flowRetryAfterP0OrP1(String p0, String p1) {
    return '等待 $p0 或 $p1 後再重試';
  }

  @override
  String get flowYourSelectionIsActiveButCouldNot =>
      '本次選擇已生效，但未能保存，請再次點擊所選難度重試。';

  @override
  String flowP0ReleasedTapForChanges(String p0) {
    return '$p0 已發佈，點擊查看更新內容';
  }

  @override
  String get flowPleaseSignIn => '請登錄';

  @override
  String get flowSettingsWereNotSavedPleaseRetry => '設置未保存，請重試';

  @override
  String flowP0Count(String p0) {
    return '$p0 數量';
  }

  @override
  String get flowAllowChiffonMaiToInstallUpdates => '請允許 ChiffonMai 安裝更新';

  @override
  String get flowCouldNotOpenInstaller => '無法打開安裝界面';

  @override
  String get flowCouldNotOpenInstallationPermissionSettings => '無法打開安裝權限設置';

  @override
  String get flowActionFailedPleaseRetry => '操作失敗，請重試';

  @override
  String flowCouldNotReadCacheUsageP0(String p0) {
    return '讀取緩存佔用失敗：$p0';
  }

  @override
  String flowCouldNotClearCacheP0(String p0) {
    return '清理緩存失敗：$p0';
  }

  @override
  String get flowLeftRight => '左右反';

  @override
  String get flowUpDown => '上下反';

  @override
  String get flowBoth => '全反';

  @override
  String get flowNoMirror => '無鏡像';

  @override
  String get flowNothingHereYet => '啥都木有';

  @override
  String get flowChoose015SpeedAndPitch =>
      '可選 0.1× 至 5×，速度與音高聯動改變；音源不足設置時長時，按實際時長播放。';

  @override
  String get flowBPMChanges => '是否變 BPM';

  @override
  String get flowNotProvided => '未提供';

  @override
  String get flowYes => '是';

  @override
  String get flowNo2 => '否';

  @override
  String get flowBPMChangeCount => 'BPM 變化次數';

  @override
  String get flowCouldNotLoadCoverArt2 => '曲繪加載失敗';

  @override
  String get flowCorrect2 => '正確';

  @override
  String get flowAccuracy => '正確率';

  @override
  String get flowAverageTime => '平均用時';

  @override
  String get flowCurrentStreak => '當前連勝';

  @override
  String get flowBestStreak => '最高連勝';

  @override
  String get flowResultOriginalAudio => '結算原聲';

  @override
  String get flowOriginalAudioIsUnavailablePleaseRetry => '原聲片段暫時無法播放，請重試';

  @override
  String get flowPlayOriginalAudio => '播放原聲';

  @override
  String get flowTitle2 => '曲名';

  @override
  String get flowType => '類型';

  @override
  String get flowMASTERConstant => 'MASTER定數';

  @override
  String get flowMASTERChartDesigner => 'MASTER譜師';

  @override
  String get flowReMASTERConstant => 'Re:MASTER定數';

  @override
  String get flowReMASTERChartDesigner => 'Re:MASTER譜師';

  @override
  String get flowMatch => '一致';

  @override
  String get flowCloseArrowsPointToTheAnswer => '接近（箭頭指向答案）';

  @override
  String get flowNoMatch => '不符';

  @override
  String flowP0SRound(String p0) {
    return '$p0 秒 / 回合';
  }

  @override
  String flowP0Rounds(String p0) {
    return '$p0 回合';
  }

  @override
  String flowP0SharedGuessesPerRound(String p0) {
    return '每回合共享 $p0 次猜測';
  }

  @override
  String get flowUnlimitedGuesses => '猜測次數不限';

  @override
  String flowConstantsP0P1(String p0, String p1) {
    return '定數 $p0 - $p1';
  }

  @override
  String get flowTemporarilyOffline => '暫時離線';

  @override
  String get flowSurrendered => '已投降';

  @override
  String get flowShareTheRoomCodeToInviteFriends => '分享房間碼邀請好友';

  @override
  String get flowReady2 => '已準備';

  @override
  String get flowWaitingToBeReady => '等待準備';

  @override
  String get flowConfirmingPlayerIdentity => '正在確認玩家身份…';

  @override
  String get flowShareTheCodeAndInviteAtLeast => '分享房間碼，邀請至少一位好友加入';

  @override
  String flowP0PlayersAreNotReadyYet(String p0) {
    return '還有 $p0 位玩家尚未準備就緒';
  }

  @override
  String get flowEveryoneIsReadyYouCanStart => '全員就緒，可以開始了';

  @override
  String get flowEveryoneIsReadyWaitingForTheHost => '全員就緒，等待房主開始';

  @override
  String get flowCouldNotUpdateSongLeaderboard => '單曲排行榜更新失敗';

  @override
  String get flowRoute1SyncFailed => '線路1同步失敗';

  @override
  String get flowCoverGuessing => '曲繪猜歌';

  @override
  String get flowBlurredCover => '模糊曲繪';

  @override
  String get flowPixelCover => '像素曲繪';

  @override
  String get flowReverseAudio => '倒放音頻';

  @override
  String get flowSpeedPitch => '變速變調';

  @override
  String get flowAliasGuessing => '別名猜歌';

  @override
  String get flowFlashCover => '曲繪快閃';

  @override
  String get flowTileReveal => '曲繪拼圖';

  @override
  String get flowGuessTheSongFromItsInformation => '根據歌曲信息猜歌名';

  @override
  String get flowGuessTheSongFromACoverFragment => '根據部分曲繪猜歌名';

  @override
  String get flowGuessTheSongFromABlurredCover => '根據模糊曲繪猜歌名';

  @override
  String get flowGuessTheSongFromPixelBlocksAnd => '根據像素馬賽克的色塊與輪廓猜歌名';

  @override
  String get flowGuessTheSongFromAReversedExcerpt => '根據倒放的歌曲片段猜歌名';

  @override
  String get flowGuessFromAnExcerptWithLinkedSpeed => '根據速度和音高聯動改變的片段猜歌名';

  @override
  String get flowGuessTheSongFromAnAudioExcerpt => '根據歌曲片段猜歌名';

  @override
  String get flowGuessTheSongFromAnAlias => '根據別名猜歌名';

  @override
  String get flowGuessTheSongFromInitialLetters => '根據首字母猜歌名';

  @override
  String get flowRememberABrieflyFlashedCoverToGuess => '曲繪一閃而過，憑記憶猜歌名';

  @override
  String get flowCoverTilesAreRevealedInBatches => '曲繪被切成小塊逐批揭示';

  @override
  String get flowGuessFromASilentChartExcerpt => '看無聲的譜面片段猜歌名';

  @override
  String get flowAutomaticInstallationTestingRequiresAndroid12Or =>
      '自動安裝測試功能需要 Android 12 及以上';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettings => '自動安裝設置保存失敗';

  @override
  String get flowAutomaticInstallationIsOffYouCanInstall => '已關閉自動安裝，可手動安裝更新';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo =>
      '更新已下載，等待 App 在後臺無任務持續 8 秒後嘗試自動安裝';

  @override
  String get flowInstallationTaskInformationIsIncomplete => '安裝任務信息不完整';

  @override
  String get flowAutomaticInstallationIsOffInstallManually => '自動安裝已關閉，請手動安裝更新';

  @override
  String get flowFinishActiveTasksOrPlaybackBeforeUpdating =>
      '請先結束正在進行的任務或播放後再更新';

  @override
  String get flowAllowAppsToBeInstalledFromThis => '請先允許此來源安裝應用';

  @override
  String get flowInstallationTaskChangedCheckUpdateStatusAgain =>
      '安裝任務已變化，請重新查看更新狀態';

  @override
  String get flowCouldNotMoveTheAppToThe => '無法將應用退到後臺，請稍後重試';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo2 =>
      '更新已下載，等待 App 退到後臺後再嘗試自動安裝';

  @override
  String get flowUpdateDownloadedWaitingForTheCurrentTask =>
      '更新已下載，等待當前任務結束後再嘗試自動安裝';

  @override
  String get flowTheLastAutomaticInstallationDidNotFinish =>
      '上次自動安裝未完成，可手動安裝更新';

  @override
  String get flowCannotReadTheAPK => '安裝包無法讀取';

  @override
  String get flowThisAPKDoesNotMeetTheSystem => '該安裝包不滿足當前系統的免確認要求，請手動安裝';

  @override
  String get flowCouldNotSaveInstallationTask => '無法保存安裝任務';

  @override
  String get flowPreparingAutomaticUpdateInstallation => '正在準備自動安裝更新…';

  @override
  String get flowAPKVerificationFailedDownloadAgain => '安裝包校驗失敗，請重新下載';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo3 =>
      '更新已下載，等待 App 在後臺無任務持續 8 秒後再安裝';

  @override
  String get flowTheSystemNeedsInstallationConfirmationTapTo =>
      '系統需要你確認安裝，請點按後手動安裝更新';

  @override
  String get flowAutomaticInstallationDidNotFinishYouCan => '自動安裝未完成，可手動安裝更新';

  @override
  String get flowUpdateDownloadDirectoryUnavailable => '更新下載目錄不可用';

  @override
  String get flowInvalidDownloadAddress => '下載地址無效';

  @override
  String get flowInvalidAPKVerificationInformation => '安裝包校驗信息無效';

  @override
  String get flowUpdateTaskChanged => '已切換更新任務';

  @override
  String get flowCouldNotRemoveThePreviousUpdateFile => '無法清理上次的更新文件';

  @override
  String get flowDownloadingInTheBackgroundYouCanKeep => '後臺下載中，可繼續使用 App';

  @override
  String get flowDownloadingUpdateInTheBackground => '正在後臺下載更新…';

  @override
  String get flowTheAPKWasRemovedDownloadAgain => '安裝包已被清理，請重新下載';

  @override
  String get flowDownloadCancelled => '下載已取消';

  @override
  String get flowWaitingForNetworkOrTheSystemTo => '等待網絡或系統繼續下載…';

  @override
  String get flowAutomaticInstallationCancelled => '已取消自動安裝';

  @override
  String get flowCheckForUpdatesAgainBeforeDownloading => '請重新檢查更新後下載';

  @override
  String get flowDownloadFailed => '下載失敗';

  @override
  String get flowVerifyingAPKInTheBackground => '正在後臺校驗安裝包…';

  @override
  String get flowAPKDownloadIsIncomplete => '安裝包下載不完整';

  @override
  String get flowAPKIntegrityCheckFailed => '安裝包完整性校驗失敗';

  @override
  String get flowUpdateDownloadFailedPleaseRetry => '更新下載失敗，請重試';

  @override
  String get flowChiffonMaiUpdateDownloaded => 'ChiffonMai 更新已下載';

  @override
  String get flowChiffonMaiUpdateDownloadFailed => 'ChiffonMai 更新下載失敗';

  @override
  String get flowTapToChooseInstallation => '點按後選擇安裝';

  @override
  String get flowTapForDetailsOrToDownloadAgain => '點按查看詳情或重新下載';

  @override
  String get flowSwitchedToManualInstallation => '已改爲手動安裝更新';

  @override
  String get flowCouldNotPrepareUpdateInstallation => '無法準備安裝更新';

  @override
  String get flowAPKInformationIsMissing => '安裝包信息缺失';

  @override
  String get flowAPKIsOutsideTheUpdateCacheDirectory => '安裝包不在更新緩存目錄中';

  @override
  String get flowTheDownloadedFileIsNotAValid => '下載的文件不是有效 APK';

  @override
  String get flowThisAPKDoesNotBelongToChiffonMai => '安裝包不屬於 ChiffonMai';

  @override
  String get flowAPKVersionDoesNotMatchTheUpdate => '安裝包版本與待更新版本不匹配，請使用網頁下載';

  @override
  String get flowAPKSignatureMismatchInstallationStopped => '安裝包簽名不匹配，已停止安裝';

  @override
  String get flowChiffonMaiCrashed => 'ChiffonMai 崩潰了';

  @override
  String get flowLogsWillBeExportedWhenYouReopen => '重新打開後會自動導出日誌';

  @override
  String get flowAppCrash => '應用崩潰';

  @override
  String get flowNativeCrash => '原生崩潰';

  @override
  String get flowAppNotResponding => '應用無響應';

  @override
  String get flowCrashAlerts => '崩潰提醒';

  @override
  String get flowOpenTheAppToRefreshData => '打開 App 刷新數據';

  @override
  String get flowUpdatesAutomaticallyWhenOnline => '聯網後自動更新';

  @override
  String get flowOpenTheAppToUpdate => '打開 App 更新';

  @override
  String get flowImageExports => '圖片導出';

  @override
  String get flowCouldNotReadSystemWallpaperColors => '無法讀取系統壁紙配色';

  @override
  String get flowMusicPlayback => '隨身聽播放';

  @override
  String get flowShowsTheCurrentSongAndPlaybackControls => '顯示正在播放的曲目與播放控制';

  @override
  String get flowMusicPlayerPlaying => '隨身聽 · 正在播放';

  @override
  String get flowMusicPlayerPaused => '隨身聽 · 已暫停';

  @override
  String get flowSyncNow => '立即同步';

  @override
  String get flowRecognizeScore => '識別成績';

  @override
  String get flowMaimaiStatus => '舞萌狀態';

  @override
  String get flowPlayPause => '播放/暫停';

  @override
  String get flowMaimaiStatusAndSync => '舞萌狀態與同步';

  @override
  String get flowChiffonMaiOverview => 'ChiffonMai 概覽';

  @override
  String get flowChiffonMaiDetails => 'ChiffonMai 詳情';

  @override
  String get flowShowsYourRating => '顯示你的 Rating';

  @override
  String get flowShowsMaimaiStatusAndAutomaticSync => '顯示舞萌狀態和自動同步';

  @override
  String get flowRatingMaimaiStatusAndAutomaticSync => 'Rating、舞萌狀態和自動同步';

  @override
  String get flowAddsSourceSyncResultsAndQuickActions => '加上各數據源的同步結果和快捷入口';

  @override
  String flowChiffonMaiVP0Update(String p0) {
    return 'ChiffonMai v$p0 更新';
  }

  @override
  String flowAutomaticInstallationDidNotFinishP0You(String p0) {
    return '自動安裝未完成：$p0，可手動安裝';
  }

  @override
  String flowP0P1Healthy(String p0, String p1) {
    return '$p0/$p1 正常';
  }

  @override
  String flowTodayP0(String p0) {
    return '今天 $p0';
  }

  @override
  String flowP0P1P22(String p0, String p1, String p2) {
    return '$p0月$p1日 $p2';
  }

  @override
  String flowUpdatedP03(String p0) {
    return '$p0 更新';
  }

  @override
  String get flowImageSavedTapToReturnToChiffonMai => '圖片已保存，點按回到 ChiffonMai';

  @override
  String get flowNotSupportedByTheSystemRightNow => '系統暫不支持';

  @override
  String get svcCheckInIsUnavailableRightNowIt => '簽到暫時不可用，下次啟動會自動重試';

  @override
  String get svcCouldNotReadGrowthRecordsItWill => '成長記錄暫時無法讀取，下次啟動會自動重試';

  @override
  String get svcCheckedInToday => '今日已簽到';

  @override
  String get svcSignInToCheckInAndEarn => '登入帳號後，每天首次啟動可簽到領經驗';

  @override
  String get svcNoGrowthRecordsYetYouWillBe => '還沒有成長記錄，下次啟動時會自動簽到';

  @override
  String get svcCheckingIn => '正在簽到…';

  @override
  String get svcCheckInAccountDoesNotMatch => '簽到帳號不匹配';

  @override
  String svcCheckedInTodayP0EXP(String p0) {
    return '今日簽到 +$p0 經驗';
  }

  @override
  String get svcSavedOnThisDeviceOnlySyncsAfter => '僅本機保存 · 登入水魚後自動同步';

  @override
  String get svcSavedOnThisDeviceOnlySignIn => '僅本機保存 · 請先登入並重新整理落雪帳號';

  @override
  String get svcSavedOnThisDeviceOnlyEnterThe => '僅本機保存 · 請先填寫 AWMC 帳號的 QQ 號';

  @override
  String get svcLoadingCommunityAppearance => '正在讀取社群裝扮';

  @override
  String get svcAppearanceWaitingToSync => '裝扮待同步';

  @override
  String get svcAppearanceWaitingToSyncSignInOr => '裝扮待同步 · 請登入或驗證對應帳號後重試';

  @override
  String get svcAppearanceWaitingToSyncTapToRetry => '裝扮待同步 · 點擊重試';

  @override
  String get svcSavedOnThisDeviceOnlySignIn2 => '僅本機保存 · 請先登入或驗證對應帳號';

  @override
  String get svcSyncingCommunityAppearance => '正在同步社群裝扮';

  @override
  String get svcCommunityAppearanceSynced => '社群裝扮已同步';

  @override
  String get svcAppearanceWaitingToSyncTheServerHas => '裝扮待同步 · 伺服器尚未確認所選裝扮';

  @override
  String get svcCouldNotGetTheAPKVersionsPublished => '無法取得 GitHub 已發佈的 APK 版本';

  @override
  String get svcCouldNotReadTheActualVersionOf => '無法讀取 GitHub APK 的實際版本，請稍後重試';

  @override
  String get svcTheAppOrVersionOfTheGitHub => 'GitHub APK 的應用或版本與發佈資訊不一致';

  @override
  String get svcExperienceImprovements => '優化體驗';

  @override
  String get svcNetworkConnectionFailedCheckYourNetworkAnd => '網路連線失敗，請檢查網路後重試';

  @override
  String svcUpdateCheckFailedP0(String p0) {
    return '檢查更新失敗：$p0';
  }

  @override
  String get svcSwitchRoutesAutomatically => '自動切換線路';

  @override
  String get svcTriesTheMirrorRoutesThenTheOfficial => '依次嘗試加速線路與官方直連';

  @override
  String get svcCommonMirrorRoute => '常用加速線路';

  @override
  String get svcBackupMirrorRoute => '備用加速線路';

  @override
  String get svcGitHubDirect => 'GitHub 直連';

  @override
  String get svcDownloadDirectlyFromGitHub => '直接從 GitHub 官方下載';

  @override
  String get svcQRCodeEntryCancelled => '已取消輸入二維碼';

  @override
  String svcReasonP0TheLogWasExportedAutomatically(String p0) {
    return '原因：$p0。日誌已自動匯出為';
  }

  @override
  String get gainRouteStable => '穩妥吃分';

  @override
  String get gainRouteChallenge => '挑戰突破';

  @override
  String get gainRouteExplore => '探索';

  @override
  String get svcIncorrectUsernameOrPasswordCheckAndTry => '使用者名稱或密碼錯誤，請檢查後重試';

  @override
  String get svcTooManySignInAttemptsTryAgain => '登入請求過於頻繁，請稍後再試';

  @override
  String get svcTheDivingFishSignInServiceIs => '水魚登入服務暫時不可用，請稍後再試';

  @override
  String get svcTheDivingFishSignInServiceReturned => '水魚登入介面回傳異常，請稍後再試';

  @override
  String get svcSignedInButNoSessionWasCreated => '登入成功但未建立工作階段，請稍後再試';

  @override
  String get svcSignedInButCouldNotGetThe => '登入成功但無法取得帳號資料，請稍後再試';

  @override
  String get svcSignedInButNoImportTokenWasReturned =>
      '登入成功但未取得 ImportToken，請前往水魚官網輪換並儲存';

  @override
  String get svcSignedInButNoLinkedQQNumber => '登入成功但未取得綁定 QQ 號，請前往水魚官網填入並儲存';

  @override
  String get svcASyncIsAlreadyInProgressTry => '同步已在進行中，請稍後重試';

  @override
  String get svcTheQRCodeIsInvalidOrHas => '二維碼無效或已過期，請重新掃描';

  @override
  String get svcMaimaiScoreHubReturnedAnUnexpectedResponse =>
      'maimai Score Hub 回應異常——缺少 token 或 friendCode，請稍後重試';

  @override
  String get svcCouldNotCreateTheFetchTaskTry => '建立抓取任務失敗，請稍後重試';

  @override
  String get svcCouldNotCreateTheFriendRequestTry => '建立好友請求失敗，請稍後重試';

  @override
  String get svcMaimaiScoreHubDidNotReturnA => 'maimai Score Hub 未回傳好友請求任務 ID';

  @override
  String get svcFriendRequestTimedOutAcceptTheRequest =>
      '好友請求逾時——請在 NET / 機台上通過好友申請後重試';

  @override
  String get svcFriendRequestFailed => '好友請求失敗';

  @override
  String get svcMaimaiScoreHubDidNotReturnA2 => 'maimai Score Hub 未回傳任務 ID';

  @override
  String svcSyncTimedOutFetchingScoresTookMore(String p0) {
    return '同步逾時——成績抓取耗時超過 $p0 分鐘，可能是 Bot 好友申請未被通過。請在 NET 上確認好友申請後重試。';
  }

  @override
  String get svcCouldNotCheckTheTaskStatusCheck => '查詢任務狀態失敗，請檢查網路後重試';

  @override
  String get svcTaskFailed => '任務失敗';

  @override
  String get svcScoresWereFetchedButSyncingToDiving =>
      '成績抓取成功，但同步水魚失敗。可稍後手動重試匯出。';

  @override
  String svcDivingFishExportFailedP0(String p0) {
    return '水魚匯出失敗：$p0';
  }

  @override
  String svcSyncErrorP0(String p0) {
    return '同步異常：$p0';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub =>
      '尚未登入 maimai Score Hub，請先完成登入後再使用線路2同步';

  @override
  String get svcCouldNotSubmitTheQRCodeCheck => '提交二維碼失敗，請檢查網路後重試';

  @override
  String svcSyncTimedOutFetchingScoresTookMore2(String p0) {
    return '同步逾時——成績抓取耗時超過 $p0 分鐘，請稍後重試';
  }

  @override
  String get svcCouldNotSetTheLXNSAPIKey => '落雪 API 金鑰設定失敗，請檢查網路後重試';

  @override
  String svcSyncTimedOutFetchingCabinetScoresTook(String p0) {
    return '同步逾時——機台成績抓取耗時超過 $p0 分鐘';
  }

  @override
  String get svcScoresWereFetchedButSyncingToLXNS =>
      '成績抓取成功，但同步落雪失敗。可稍後手動重試匯出。';

  @override
  String svcLXNSExportFailedP0(String p0) {
    return '落雪匯出失敗：$p0';
  }

  @override
  String get svcQueueStatisticsAreUnavailableTryAgainLater => '佇列統計暫不可用，請稍後重試';

  @override
  String get svcCouldNotReadTheAutoSyncSettings => '自動同步設定讀取失敗，請保留本機資料後重試';

  @override
  String get svcCouldNotReadTheAutoSyncCredentials => '自動同步憑證讀取失敗，請保留本機資料後重試';

  @override
  String get svcTheAutoSyncServiceIsUnavailableCheck =>
      '自動同步服務暫不可用，請檢查網路後重試；設定狀態尚未確認';

  @override
  String get svcSyncedButTheLocalDataRefreshDid => '同步成功，本機資料重新整理未完成，請手動重新整理';

  @override
  String get svcPersonalKeySavedOnThisDeviceThe => '個人 key 已儲存在本機，定時任務待更新';

  @override
  String get svcTheAccountChangedTurnOffAutoSync => '帳號已切換，請先關閉舊帳號自動同步後重新開啟';

  @override
  String get svcSaveThePersonalKeyForThisData => '請重新儲存該資料來源的個人 key';

  @override
  String svcPersonalKeySavedOnThisDeviceThe2(String p0) {
    return '個人 key 已儲存在本機，定時任務待更新：$p0';
  }

  @override
  String get svcCheckYourNetworkAndTryAgain => '請檢查網路後重試';

  @override
  String get svcEnterThePersonalKey => '請輸入個人 key';

  @override
  String get svcPersonalKeySaved => '個人 key 已儲存';

  @override
  String get svcPersonalKeySavedAndTheScheduledTask => '個人 key 已儲存，並已更新定時任務';

  @override
  String get svcPersonalKeySavedAutoSyncStaysOff => '個人 key 已儲存，自動同步保持關閉';

  @override
  String get svcPersonalKeyCleared => '個人 key 已清除';

  @override
  String get svcPersonalKeyClearedAndTheMatchingAuto => '個人 key 已清除，並已關閉對應自動同步';

  @override
  String get svcCouldNotVerifyTheTargetAccountScores =>
      '目標帳號成績或同步憑證驗證失敗，請檢查該資料來源的帳號狀態';

  @override
  String get svcAnAutoSyncTaskAlreadyExistsTrying =>
      '已有自動同步任務，正在嘗試恢復目前使用者的管理權限';

  @override
  String get svcNoMatchingAutoSyncTaskWasFound => '沒有找到符合的自動同步任務，請重新開啟';

  @override
  String get svcTheTaskIsRunningRestoreManagementAccess => '任務正在執行中，請稍後再恢復管理權限';

  @override
  String get svcTheAccountLinkedToTheTaskChanged => '任務綁定的帳號已變化，請先關閉自動同步再重新開啟';

  @override
  String get svcQuickSyncCredentialsAreIncompleteEnterA =>
      '快速同步憑證不完整，請先輸入二維碼綁定機台身分';

  @override
  String get svcTooManyRequestsTryAgainLater => '操作過於頻繁，請稍後重試';

  @override
  String get svcCouldNotReadTheSongLibraryOf => '目標資料來源曲庫讀取失敗，本次未繼續同步';

  @override
  String get svcScoreUploadFailedSomeBatchesMayHave =>
      '成績上傳失敗，部分批次可能已提交；本次不自動重試';

  @override
  String get svcTheAWMCNETImportTokenIsInvalid =>
      'AWMC NET 的 Import-Token 無效，請在成績導入憑據重新儲存有效 Token，已開啟的定時任務會自動更新';

  @override
  String get svcCouldNotReadCabinetScoresTryAgain => '機台成績讀取失敗，請稍後重試';

  @override
  String get svcTheUpstreamReturnedPagedScoresReadingStopped =>
      '上游回傳了分頁成績，本輪已停止讀取，避免連續請求';

  @override
  String get svcNoValidScoresSupportedByTheTarget => '未讀取到目標資料來源支援的有效成績';

  @override
  String get svcAServiceRestartInterruptedTheLastSync =>
      '服務重啟中斷了上次同步，將在下次定時時間繼續';

  @override
  String get svcTheAutoSyncSettingChangedRefreshThe => '自動同步設定已變化，請重新整理狀態';

  @override
  String get svcThisSyncTimedOutAndStoppedIt => '本次同步處理逾時，已停止並將在下次定時時間繼續';

  @override
  String get svcAutoSyncCapacityIsFullTurnIt => '目前自動同步容量已滿，請稍後再開啟';

  @override
  String get svcTheUpstreamQuotaCannotBeConfirmedOr =>
      '上游配額暫不可確認或已用盡，任務會在恢復後繼續';

  @override
  String get svcTheUpstreamServiceIsUnavailableTheTask =>
      '上游服務暫不可用，任務已暫停，恢復後繼續';

  @override
  String get svcThisMorningSProcessingWindowHasEnded => '本次上午處理時段已結束，將在下一輪繼續';

  @override
  String get svcTheUploadResultIsUncertainTheNext => '上傳結果暫不確定，下一輪會先核對後處理';

  @override
  String get svcTheAutoSyncServiceIsUnavailableTry => '自動同步服務暫不可用，請稍後重試';

  @override
  String svcSetUpTheSyncCredentialsForP0(String p0) {
    return '請先在「成績導入憑據」設定$p0的成績導入 Token';
  }

  @override
  String svcSetUpYourP0AccountFirst(String p0) {
    return '請先設定$p0帳號';
  }

  @override
  String svcRefreshYourP0AccountDataBeforeUsing(String p0) {
    return '請先重新整理$p0帳號的資料，再使用快速同步';
  }

  @override
  String get svcAWMCReportedSuccessWithoutAUserIdThe =>
      'AWMC 回傳成功但沒有 userId，未快取機台身分';

  @override
  String get svcQuickSyncIsInProgressPleaseWait => '快速同步正在進行中，請稍候';

  @override
  String get svcUserCredentialsAreNotCachedEnterA => '使用者憑證未快取，請先輸入二維碼綁定機台身分';

  @override
  String get svcUpdateTheSongLibraryBeforeUsingQuick => '請先更新曲庫，再使用快速同步';

  @override
  String get svcNoValidScoresMatchedTheLocalSong => '有效成績未對應到本機曲庫，未上傳任何資料';

  @override
  String svcTheAWMCGatewayIsUnavailableP0(String p0) {
    return 'AWMC 閘道暫不可用：$p0';
  }

  @override
  String get svcScorePagingWasAbnormalTheUpdateStopped => '成績分頁異常，已終止更新';

  @override
  String get svcTheServerDoesNotOfferQuickSync => '伺服器尚未開放快速同步介面，請更新伺服器代理';

  @override
  String get svcTheCurrentGatewayUpstreamCannotReadWithout =>
      '目前閘道上游不支援免二維碼讀取，請使用一般同步';

  @override
  String svcQuickReadFailedP0(String p0) {
    return '快速讀取失敗：$p0';
  }

  @override
  String get svcTheAWMCGatewayReturnedAnInvalidScore => 'AWMC 閘道回傳了無效的成績分頁游標';

  @override
  String get svcTheAWMCGatewayReturnedPagedResultsReading =>
      'AWMC 閘道回傳了分頁結果，本次已停止讀取，避免連續請求';

  @override
  String get svcNoValidScoresWereReadNothingWas => '沒有讀取到有效成績，未上傳任何資料';

  @override
  String svcCouldNotReadTheP0SongLibrary(String p0) {
    return '$p0曲庫讀取失敗，未上傳成績';
  }

  @override
  String svcTheP0SongLibraryIsEmptyNo(String p0) {
    return '$p0曲庫為空，未上傳成績';
  }

  @override
  String svcCouldNotReadExistingP0ScoresSo(String p0) {
    return '$p0現有成績讀取失敗，未進行快速同步，請先檢查該來源的帳號狀態';
  }

  @override
  String svcP0ReturnedScoresInAnInvalidFormat(String p0) {
    return '$p0回傳的成績格式無效，未進行快速同步';
  }

  @override
  String svcP0ScoresAreMissingChartOrCombo(String p0) {
    return '$p0成績缺少譜面或連擊同步欄位，未進行快速同步';
  }

  @override
  String svcUploadToP0FailedHTTPP1Remaining(String p0, String p1) {
    return '$p0上傳未成功（HTTP $p1），已停止後續批次；已提交批次可能已生效';
  }

  @override
  String get svcThereAreNoFavoriteFoldersToExport => '沒有可匯出的收藏夾';

  @override
  String get svcChooseAChiffonMaiFavoritesFile => '選擇 ChiffonMai 收藏夾檔案';

  @override
  String get svcCouldNotReadTheSelectedFile => '無法讀取所選檔案';

  @override
  String svcFileNotFoundP0(String p0) {
    return '檔案不存在：$p0';
  }

  @override
  String svcTheFavoritesFileIsTooLargeLimit(String p0) {
    return '收藏夾檔案過大（上限 $p0 MB）';
  }

  @override
  String get svcThisFileIsNotInTheChiffonMai =>
      '這個檔案不是 ChiffonMai 收藏夾格式。\n（舊版匯出的 .txt 純文字清單不含歌曲 ID，無法還原成收藏夾，請重新匯出一次）';

  @override
  String get svcTheFileIsNotValidJSONAnd => '檔案內容不是合法的 JSON，可能已損壞';

  @override
  String svcTheFileFormatTagIsP0Not(String p0) {
    return '檔案格式標識為「$p0」，不是 ChiffonMai 收藏夾檔案';
  }

  @override
  String get svcTheFileContentCouldNotBeRecognized => '檔案內容無法識別';

  @override
  String get svcTheFileHasNoFavoritesData => '檔案裡沒有任何收藏夾資料';

  @override
  String get svcTheFileIsMissingTheFoldersField => '檔案缺少 folders 欄位';

  @override
  String get svcTheFileIsEmpty => '檔案是空的';

  @override
  String get svcTheBackupExceedsThe50MBLimit => '備份超過 50 MB 上限，請精簡自訂譜面封存後重試';

  @override
  String svcTheBackupFileIsTooLargeLimit(String p0) {
    return '備份檔案過大（上限 $p0 MB）';
  }

  @override
  String get svcInvalidBackupFileMissingTheDataField => '無效的備份檔案：缺少 data 欄位';

  @override
  String get svcInvalidBackupFileMissingTheVersionField =>
      '無效的備份檔案：缺少 version 欄位';

  @override
  String get svcUnsupportedBackupVersionOrAppFormat => '不支援的備份版本或應用格式';

  @override
  String get svcTheBackupFileIsEmptyThereIs => '備份檔案為空，無資料可恢復';

  @override
  String get svcADataRestoreIsAlreadyInProgress => '已有資料恢復正在進行';

  @override
  String get svcSecureCredentialsHaveNotFinishedMigratingTry =>
      '安全憑證尚未完成遷移，請稍後重試恢復';

  @override
  String get svcCouldNotClearTheOldSettings => '清空舊設定失敗';

  @override
  String svcCouldNotWriteTheBackupSettingP0(String p0) {
    return '寫入備份設定失敗：$p0';
  }

  @override
  String get svcTheBackupHasNoUserSettingsTo => '備份沒有可恢復的使用者設定，已保留目前資料';

  @override
  String get svcSignInAndLinkYourDivingFish => '請先登入並綁定水魚 QQ';

  @override
  String get svcTheCurrentDivingFishUserHasNo => '目前水魚使用者無遊玩資料，請先重新整理資料';

  @override
  String get svcNoPlayDataWasFoundForThis => '未找到該好友的遊玩資料，請檢查 QQ 號是否正確';

  @override
  String get svcAddYourAWMCNETQQNumberIn => '請先在「綁定與授權管理」裡綁定 AWMC NET 的 QQ';

  @override
  String get svcSignInToYourLXNSAccountFirst => '請先登入落雪帳號';

  @override
  String get svcCouldNotReadYourLXNSScoresTry => '讀取你的落雪成績失敗，請稍後重試';

  @override
  String get svcTheSongLibraryHasNotLoadedYet => '曲庫還沒有載入好，請稍後重試';

  @override
  String get svcTheFriendCodeMustContainOnlyDigits => '好友碼只能是數字，請檢查後重試';

  @override
  String svcCouldNotLookUpTheFriendS(String p0) {
    return '查詢好友成績失敗（HTTP $p0）';
  }

  @override
  String get svcNoLXNSScoresForThisFriendThey =>
      '沒有這位好友的落雪成績，好友需要在 ChiffonMai 參與排行榜並重新整理過資料';

  @override
  String get svcChooseAtLeastOneResultScreenImage => '請先選擇至少一張結算畫面圖片';

  @override
  String svcUpToP0ImagesCanBeRecognized(String p0, String p1) {
    return '一次最多識別 $p0 張，目前選了 $p1 張';
  }

  @override
  String svcP0ExceedsThe8MiBLimitP1(String p0, String p1) {
    return '$p0 超過 8 MiB 上限（$p1 MiB）';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub2 =>
      '未登入 maimai Score Hub，無法使用該識別服務';

  @override
  String svcNoImagesOrTooManyImagesP0(String p0) {
    return '圖片為空或數量超限$p0';
  }

  @override
  String get svcYourSignInHasExpiredSignIn => '登入狀態已失效，請重新登入 maimai Score Hub';

  @override
  String get svcAnImageExceedsThe8MiBLimit => '有圖片超過 8 MiB 上限';

  @override
  String get svcUnsupportedImageFormatOnlyJPEGPNGWebP =>
      '圖片格式不支援（僅支援 JPEG / PNG / WebP）';

  @override
  String get svcTheOCRServiceReturnedAResultThat => 'OCR 服務回傳了無法解析的結果';

  @override
  String get svcTheOCRServiceIsUnavailableTryAgain => 'OCR 服務暫時不可用，請稍後再試';

  @override
  String get svcOCRRecognitionTimedOutTryAgainLater => 'OCR 識別逾時，請稍後再試';

  @override
  String svcRecognitionFailedHTTPP0P1(String p0, String p1) {
    return '識別失敗（HTTP $p0）$p1';
  }

  @override
  String get svcAccountDataIsUpdatingTryAgainWhen => '帳號資料正在更新，請完成後重試';

  @override
  String get svcCouldNotSaveAccountRecoveryInformation => '無法儲存帳號恢復資訊';

  @override
  String get svcTheAccountChangedSoTheDataRefresh => '帳號已切換，已略過本次同步後的資料重新整理';

  @override
  String get svcTheReturnedDataBelongsToAnotherAccount =>
      '回傳的資料屬於其他帳號，已取消本次自動重新整理';

  @override
  String get svcCouldNotRollBackTheAccountArchive => '帳號存檔回滾失敗';

  @override
  String get svcCouldNotIdentifyTheAccountToRestore => '無法識別待恢復的帳號';

  @override
  String get svcCouldNotSaveHistoryMigrationInformation => '無法儲存歷史遷移資訊';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit =>
      '使用者檔案超過備份容量上限，請先精簡自訂譜面封存後重試';

  @override
  String get svcTheUserFilesInTheBackupHave => '備份的使用者檔案格式無效';

  @override
  String get svcInvalidUserFileEntry => '使用者檔案條目無效';

  @override
  String get svcInvalidUserFilePath => '使用者檔案路徑無效';

  @override
  String get svcInvalidUserFileContent => '使用者檔案內容無效';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit2 => '使用者檔案超過備份容量上限';

  @override
  String get svcTheUserFileFolderCannotBeA => '使用者檔案目錄不能是符號連結';

  @override
  String get svcUserFilesCannotBeSymbolicLinks => '使用者檔案不能是符號連結';

  @override
  String get svcCouldNotWriteTheAccountArchive => '帳號存檔寫入失敗';

  @override
  String get svcTheAccountArchiveHasAnInvalidFormat => '帳號存檔格式無效';

  @override
  String get svcCouldNotRestoreTheAccountArchive => '帳號存檔恢復失敗';

  @override
  String svcRefreshTheTargetP0AccountSData(String p0) {
    return '請先重新整理$p0目標帳號的資料，以保留該帳號的連擊與同步標記';
  }

  @override
  String svcTheP0ScoreCacheIsInvalidRefresh(String p0) {
    return '$p0成績快取無效，請先重新整理資料';
  }

  @override
  String svcLoadedP0FromTheLocalCache(String p0) {
    return '已從本機快取讀取$p0';
  }

  @override
  String get svcAudio => '音訊';

  @override
  String get svcAudioFile => '音訊檔案';

  @override
  String svcDownloadingP0(String p0) {
    return '正在下載$p0…';
  }

  @override
  String get svcTheResponseIsNotAMediaFile => '回應不是媒體檔案';

  @override
  String get svcTheMediaFileIsIncompleteOrHas => '媒體檔案不完整或格式無效';

  @override
  String get svcFileCached => '檔案已快取';

  @override
  String svcMediaDownloadFailedP0(String p0) {
    return '媒體下載失敗：$p0';
  }

  @override
  String svcP0AddedP1UpdatedP2SkippedP3(
      String p0, String p1, String p2, String p3) {
    return '新增 $p0 筆 · 更新 $p1 筆 · 略過 $p2 筆（機台共 $p3 筆）';
  }

  @override
  String get svcTheAWMCNETScoreImportTokenHas => '還沒有設定 AWMC NET 成績匯入 Token';

  @override
  String get svcPasteOrScanTheCabinetSignIn => '請先貼上或掃描機台登入二維碼';

  @override
  String svcRefusedARequestToANonAWMC(String p0) {
    return '拒絕請求非 AWMC NET 位址：$p0';
  }

  @override
  String svcImportTimedOutAfterP0SecondsLarge(String p0) {
    return '匯入逾時（已等待 $p0 秒）。機台資料量大時會更久，請稍後重試';
  }

  @override
  String svcCouldNotConnectToAWMCNETP0(String p0) {
    return '連線 AWMC NET 失敗：$p0';
  }

  @override
  String get svcAWMCNETReturnedUnrecognizedData => 'AWMC NET 回傳了無法識別的資料';

  @override
  String svcCouldNotParseTheAWMCNETResponse(String p0) {
    return '解析 AWMC NET 回傳失敗：$p0';
  }

  @override
  String get svcTheAWMCNETImportTokenIsInvalid2 =>
      'AWMC NET 匯入 Token 無效，請到 net.wmc.pub 設定頁最底部重新產生';

  @override
  String get svcTheAWMCNETImportTokenIsMissing => '缺少 AWMC NET 匯入 Token';

  @override
  String get svcTheCabinetQRCodeIsInvalidOr => '機台二維碼無效或已過期，請重新在公眾號/機台取得後重試';

  @override
  String svcAWMCNETRejectedTheRequestP0(String p0) {
    return 'AWMC NET 拒絕了請求：$p0';
  }

  @override
  String get svcInvalidParameters => '參數不合法';

  @override
  String svcTooManyAWMCNETRequestsTryAgain(String p0) {
    return 'AWMC NET 請求過於頻繁，請稍後再試\n$p0';
  }

  @override
  String svcAWMCNETChimeUserReadFailed(String p0) {
    return '機台成績讀取失敗：Chime 無法取得使用者（業務碼 3002，HTTP $p0）。請使用新 QR 碼重試；若仍失敗，請稍後再試，或使用已綁定機台身分的快速同步。';
  }

  @override
  String svcAWMCNETServerErrorHTTPP0Try(String p0) {
    return 'AWMC NET 伺服器異常（HTTP $p0），請稍後重試';
  }

  @override
  String svcAWMCNETReturnedHTTPP0(String p0) {
    return 'AWMC NET 回傳 HTTP $p0';
  }

  @override
  String get svcNoDivingFishImportTokenYetSign => '還沒有水魚 Import-Token，請先登入水魚帳號';

  @override
  String svcCouldNotConnectToDivingFishP0(String p0) {
    return '無法連線水魚查分器：$p0';
  }

  @override
  String get svcTheImportTokenIsWrongOrThe => '匯入 Token 有誤或請求格式不對';

  @override
  String get svcYourSignInIsInvalidSignIn => '登入狀態無效，請重新登入水魚';

  @override
  String svcSyncFailedHTTPP0P1(String p0, String p1) {
    return '同步失敗（HTTP $p0）$p1';
  }

  @override
  String get svcDivingFishDidNotAcceptThisScore =>
      '水魚沒有接受這筆成績（歌曲沒對應上，或難度索引對該歌曲不存在），請檢查曲名和難度';

  @override
  String get svcUTAGEChartsCannotBeSyncedLXNSDifficulty =>
      '宴會場譜面不支援同步：落雪的難度索引體系與宴會場不通用';

  @override
  String svcDifficultyIndexP0IsOutsideTheLXNS(String p0) {
    return '難度索引 $p0 超出落雪值域（0-4）';
  }

  @override
  String get svcYourLXNSAccountIsNotAuthorizedComplete =>
      '落雪帳號未認證：在「綁定與授權管理」完成 OAuth 授權，或在 OCR 頁的落雪狀態列裡貼上個人 API 金鑰';

  @override
  String svcCouldNotConnectToLXNSP0(String p0) {
    return '無法連線落雪咖啡屋：$p0';
  }

  @override
  String get svcLXNSAuthorizationExpiredOrTheKeyIs => '落雪授權已失效或金鑰無效，請重新授權或貼上金鑰';

  @override
  String get svcLXNSRejectedThisWriteInsufficientPermissions =>
      '落雪拒絕了這次寫入（權限不足）';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatDataIs => '落雪回傳格式異常：data 為空';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatData0 => '落雪回傳格式異常：data[0] 不是物件';

  @override
  String get svcThisUserHasNotAuthorizedTheApp => '該使用者尚未授權本應用，請先完成綁定後再試';

  @override
  String get svcAuthenticationFailedTryAgain => '驗證失敗，請重試';

  @override
  String get svcNoPermissionToAccessThisUserS => '無權限存取該使用者資料';

  @override
  String get svcTodaySQueryLimitHasBeenReached => '今日查詢次數已達上限，請稍後再試';

  @override
  String svcRequestFailedStatusCodeP0(String p0) {
    return '請求失敗（狀態碼 $p0）';
  }

  @override
  String get svcConnectionCancelled => '連線已取消';

  @override
  String get svcDisconnectedReconnectAndTryAgain => '連線已中斷，請重新連線後重試';

  @override
  String get svcDisconnectedTheCoverReadyStatusWasNot => '連線已中斷，曲繪準備狀態未傳送';

  @override
  String get svcDisconnectedThisGuessWasNotSubmittedReconnect =>
      '連線已中斷，本次猜測未提交，請連線後重試';

  @override
  String get svcDisconnectedReconnectBeforeLeavingTheRoom =>
      '連線已中斷，請重新連線後再退出房間';

  @override
  String get svcEnterAQQNumber => '請輸入 QQ 號';

  @override
  String svcAWMCNETQueryTimedOutP0S(String p0) {
    return 'AWMC NET 查詢逾時（$p0 秒），請檢查網路後重試';
  }

  @override
  String svcAWMCNETConnectionFailedP0(String p0) {
    return 'AWMC NET 連線失敗：$p0';
  }

  @override
  String svcAWMCNETReturnedDataThatCouldNot(String p0) {
    return 'AWMC NET 回傳了無法解析的資料：$p0';
  }

  @override
  String get svcAWMCNETReturnedAnUnrecognizedDataStructure =>
      'AWMC NET 回傳的資料結構無法識別（缺少 records）';

  @override
  String svcAWMCNETHasNoDataForQQ(String p0) {
    return 'AWMC NET 上沒有 QQ $p0 的資料。\n請確認該 QQ 已在 net.wmc.pub 綁定並上傳過成績。';
  }

  @override
  String svcTheAWMCNETDeveloperKeyIsInvalid(String p0) {
    return 'AWMC NET 開發者金鑰無效或已失效（HTTP $p0）';
  }

  @override
  String svcAWMCNETReturnedAnUnknownStatusHTTP(String p0, String p1) {
    return 'AWMC NET 回傳未知狀態：HTTP $p0$p1';
  }

  @override
  String svcInvalidQQNumber512DigitsExpected(String p0) {
    return 'QQ 號格式不對（應為 5–12 位數字）：$p0';
  }

  @override
  String svcAWMCNETHasNoDataForQQ2(String p0) {
    return 'AWMC NET 沒有 QQ $p0 的資料（請確認該 QQ 已在 net.wmc.pub 綁定並上傳過成績）';
  }

  @override
  String get svcAWMCNETRejectedTheRequestDaysIs =>
      'AWMC NET 拒絕了請求：days 參數超出範圍（1~365）';

  @override
  String svcAWMCNETReturnedJSONThatCouldNot(String p0) {
    return 'AWMC NET 回傳了無法解析的 JSON：$p0';
  }

  @override
  String get svcTheAWMCNETResponseHasNoPoints => 'AWMC NET 回傳結構裡沒有 points 陣列';

  @override
  String svcP0MsOfflineMode(String p0) {
    return '${p0}ms（離線模式）';
  }

  @override
  String get svcLoadingTheSongAliasDatabase => '正在載入歌曲別名資料庫...';

  @override
  String get svcInitializingTheMaidataManager => '正在初始化 Maidata 管理器...';

  @override
  String get svcFetchingAllMaidataTheFirstLoadMay =>
      '正在取得全量 Maidata 資料...\n（首次載入可能較慢，請耐心等待）';

  @override
  String get svcLoadingMaidataFromCache => '從快取載入 Maidata 資料...';

  @override
  String get svcSyncingSongInfoAndDifficultyData => '正在同步歌曲資訊與難度資料...';

  @override
  String get svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd =>
      '正在載入收藏品、標籤、歌曲、知識庫等資料...';

  @override
  String get svcBuildingSongMappings => '正在建立歌曲關聯對應...';

  @override
  String get svcTheExportCanvasIsNotReady => '匯出畫布未就緒';

  @override
  String get svcDiscoveringBaseMaidata => '正在探索基礎量 maidata…';

  @override
  String svcFetchingMaidataP0P1(String p0, String p1) {
    return '正在拉取 maidata：$p0/$p1';
  }

  @override
  String svcFoundP0MaidataFiles(String p0) {
    return '已探索 $p0 份 maidata';
  }

  @override
  String get svcTheLogWasExportedAutomaticallyYouCan => '日誌已自動匯出，可以傳給開發者排查';

  @override
  String get svcLogExportFailedYouCanExportIt => '日誌匯出失敗，可在「列印日誌」手動匯出';

  @override
  String get svcTheGatewayCouldNotReachItsOrigin =>
      '閘道回源失敗：CDN 回傳了非法回應標頭的錯誤頁（SpeedOnline），通常是閘道/回源逾時，稍後重試即可';

  @override
  String svcRequestFailedP0(String p0) {
    return '請求失敗：$p0';
  }

  @override
  String get svcSuccess => '成功';

  @override
  String get svcTheServerHasNoAWMCDeveloperKey => '伺服器尚未設定 AWMC 開發者金鑰，請聯絡管理員';

  @override
  String get svcHTTP401TokenMissingOrInvalid => 'HTTP 401：權杖缺失或無效';

  @override
  String get svcHTTP403InsufficientBalanceRedeemTokensIn =>
      'HTTP 403：餘額不足，請先在控制台兌換 Token';

  @override
  String svcHTTPP0TheGatewayOrUpstreamFailed(String p0) {
    return 'HTTP $p0：閘道或上游轉發失敗';
  }

  @override
  String svcUsedP0Tokens(String p0) {
    return '本次消耗 $p0 Token';
  }

  @override
  String get svcTheRequestDidNotSucceedNoTokens => '業務未成功，按官方規則不扣 Token';

  @override
  String get svcCouldNotReadTheRefreshSettingsRefresh => '重新整理設定讀取失敗，請手動重新整理資料';

  @override
  String get svcTheRefreshSourceDiffersFromTheSync => '重新整理來源與同步目標不同，已略過自動重新整理';

  @override
  String get svcTheRefreshAccountDiffersFromTheSync =>
      '重新整理帳號與同步目標不同，已略過自動重新整理';

  @override
  String get svcTheAccountOrSyncCredentialsChangedAutomatic =>
      '帳號或同步憑證已變化，已略過自動重新整理';

  @override
  String get svcCouldNotLoadTheGateListRight => '門列表暫時無法讀取';

  @override
  String get svcCouldNotLoadTheGuideRightNow => '攻略暫時無法讀取';

  @override
  String get svcTheGuideDataDoesNotMatch => '攻略資料不符';

  @override
  String get svcReadAndAcceptTheUserAgreementAnd => '請先閱讀並同意使用者協議和隱私權政策';

  @override
  String get svcCouldNotSaveTheOnboardingConfirmationTry => '無法儲存引導確認記錄，請重試';

  @override
  String get svcCreatingTheRoomTimedOutCheckYour => '建立房間逾時，請檢查連線後重試';

  @override
  String get svcJoiningTheRoomTimedOutCheckThe => '加入房間逾時，請檢查房間碼與網路';

  @override
  String svcCouldNotLoadReleaseDataP0(String p0) {
    return '配信資料讀取失敗 ($p0)';
  }

  @override
  String get svcInvalidReleaseData => '無效的配信資料';

  @override
  String get svcInvalidFriendLinkDataFormat => '友鏈資料格式錯誤';

  @override
  String get svcSaveFailed => '儲存失敗';

  @override
  String svcCouldNotParseTheRecognitionResultJSON(String p0) {
    return '識別結果 JSON 解析失敗：$p0';
  }

  @override
  String svcRecognitionRequestFailedP0(String p0) {
    return '識別請求失敗：$p0';
  }

  @override
  String get gainBelowS => '未達 S';

  @override
  String gainRaiseTo(String p0) {
    return '衝上 $p0';
  }

  @override
  String gainWithinGrade(String p0) {
    return '$p0 檔內提分';
  }

  @override
  String gainBasisMember(String p0, String p1, String p2, String p3) {
    return '$p0；$p1 內單曲 RA $p2→$p3';
  }

  @override
  String gainBasisReplace(
      String p0, String p1, String p2, String p3, String p4) {
    return '$p0；RA $p1 頂替 $p2 最低《$p3》RA $p4';
  }

  @override
  String gainBasisFill(String p0, String p1, String p2) {
    return '$p0；RA $p1 補入 $p2 空位';
  }

  @override
  String gainNetGainReason(String p0, String p1) {
    return '獨立淨收益+$p0（$p1）';
  }

  @override
  String gainExploreReason(String p0, String p1) {
    return '個人同檔最佳成績中位參考 $p0% · 獨立淨收益+$p1（條件估算；不是下次成功率）';
  }

  @override
  String gainAlternativeChallenge(String p0, String p1) {
    return '；挑戰可選 $p0%（獨立淨收益+$p1，不與穩妥目標累加）';
  }

  @override
  String gainFillNoteExhausted(String p0) {
    return '合格未見候選 $p0 條，已全部耗盡';
  }

  @override
  String gainFillNoteFiltered(String p0) {
    return '合格未見候選 $p0 條，其餘被回饋/資格過濾';
  }

  @override
  String get accountAuthorizeLXNS => '落雪帳號授權';

  @override
  String get accountLinkAWMC => '綁定 AWMC NET 帳號';

  @override
  String get accountSwitchCachedSubtitle => '切換資料來源與玩家資訊，使用本機快取';

  @override
  String get accountAuthorizeLXNSSubtitle => '管理落雪成績讀取授權';

  @override
  String get accountLinkAWMCSubtitle => '設定 AWMC NET 成績查詢 QQ';

  @override
  String get accountCabinetIdentitySubtitle => '綁定快速同步共用的機台身分';

  @override
  String get accountAuthorizeLXNSFirst => '請先在「我的 → 帳號與授權 → 綁定與授權管理」完成落雪授權';

  @override
  String get accountLinkAWMCFirst => '請先在「我的 → 帳號與授權 → 綁定與授權管理」綁定 AWMC NET 帳號';

  @override
  String get accountConfigurationSaved => '帳號設定已儲存，可透過重新整理資料更新成績';

  @override
  String get accountAuthorizationFailed => '授權或儲存失敗，請檢查網路與輸入後重試';

  @override
  String get accountLXNSAuthorized => '落雪帳號已授權';

  @override
  String get accountLXNSAuthorizedSubtitle => '已授權，可重新整理成績；點按可重新授權';

  @override
  String get accountAWMCLinked => 'AWMC NET 帳號已綁定';

  @override
  String accountAWMCLinkedSubtitle(String qq) {
    return '已綁定 QQ：$qq；點按可更換帳號';
  }

  @override
  String get accountCabinetLinkedSubtitle => '快速同步身分已儲存，點按可重新綁定';

  @override
  String get accountBindingManage => '綁定與授權管理';

  @override
  String get accountBindingManageSubtitle => '登錄、授權與綁定各數據源賬號';

  @override
  String get accountBindingScoreHub => 'maimai Score Hub';

  @override
  String get accountBindingDivingFish => '水魚';

  @override
  String get accountBindingLxns => '落雪';

  @override
  String get accountBindingAwmc => 'AWMC NET';

  @override
  String get accountBindingCabinet => '機台身份';

  @override
  String get accountBindingSignedIn => '已登錄';

  @override
  String get accountBindingSignedOut => '未登錄';

  @override
  String get accountBindingAuthorized => '已授權';

  @override
  String get accountBindingUnauthorized => '未授權';

  @override
  String get accountBindingLinked => '已綁定';

  @override
  String get accountBindingUnlinked => '未綁定';

  @override
  String get accountBindingDivingFishAuth => '水魚授權';

  @override
  String get accountBindingUnknown => '未知';

  @override
  String get accountBindingRecheck => '重新檢查';

  @override
  String get syncDialogMode => '同步方式';

  @override
  String get syncDialogQrCode => '機台二維碼';

  @override
  String get languageTranslationDisclaimer =>
      '除簡體中文外，其他語言的介面文案為翻譯文本，可能存在不準確或不自然的表達；含義不一致時以簡體中文為準。歌曲資料、伺服器原文和使用者內容不做翻譯。發現翻譯問題歡迎透過「問題回饋」告訴我們。';

  @override
  String get accountSwitchSaved => '已儲存賬號';

  @override
  String get accountSwitchNotSaved => '未儲存賬號';

  @override
  String get accountSwitchCurrent => '目前使用中';

  @override
  String get customTagTitle => '自訂標籤';

  @override
  String get customTagFeatureSubtitle => '自訂標籤名稱、顏色與譜面，接入標籤篩選與統計';

  @override
  String get customTagGroupName => '自訂';

  @override
  String get customTagIntro =>
      '自訂標籤會與譜面標籤一起出現在樂曲查詢的標籤篩選、譜面詳情、Best50 / 收藏夾的標籤統計和個性化 Best50 的「標籤50」中。標籤只保存在本機，隨資料備份匯出。';

  @override
  String get customTagCreate => '新增標籤';

  @override
  String get customTagEdit => '編輯標籤';

  @override
  String get customTagName => '標籤名稱';

  @override
  String get customTagColor => '標籤顏色';

  @override
  String get customTagHue => '色相';

  @override
  String get customTagPreview => '預覽';

  @override
  String get customTagNameRequired => '請輸入標籤名稱';

  @override
  String get customTagNameDuplicate => '已有同名標籤';

  @override
  String get customTagSaveFailed => '儲存自訂標籤失敗，請重試';

  @override
  String get customTagForChart => '為譜面新增自訂標籤';

  @override
  String get customTagEmpty => '還沒有自訂標籤，先新增一個吧。';

  @override
  String get customTagAddToChart => '新增自訂標籤';

  @override
  String get customTagManage => '管理';

  @override
  String get customTagSearchHint => '輸入歌名、別名、曲師或 ID 搜尋';

  @override
  String get customTagNoSongs => '沒有找到歌曲';

  @override
  String get customTagChooseDifficulties => '選擇難度';

  @override
  String get customTagAddCharts => '新增譜面';

  @override
  String get customTagRemoveChart => '移出此標籤';

  @override
  String get customTagDelete => '刪除';

  @override
  String get customTagDeleteTitle => '刪除標籤';

  @override
  String customTagChartCount(int count) {
    return '$count 張譜面';
  }

  @override
  String customTagDeleteMessage(String name) {
    return '刪除「$name」後，它會從所有譜面上移除，且無法恢復。';
  }

  @override
  String accountSwitchCurrentLabel(String name) {
    return '目前：$name';
  }

  @override
  String customTagMarked(String name) {
    return '$name（自訂）';
  }

  @override
  String get chartCodeFont => '代碼字體';

  @override
  String get chartCodeFontDefault => '預設';

  @override
  String get chartCodeFontSaveFailed => '字體已切換，但未能儲存選擇';
}
