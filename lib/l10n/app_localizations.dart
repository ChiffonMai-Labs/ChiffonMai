import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @autoUpdateSuccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'自动更新成功'**
  String get autoUpdateSuccessTitle;

  /// No description provided for @autoUpdateSuccessBody.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 已在后台完成更新，可以继续使用啦。'**
  String get autoUpdateSuccessBody;

  /// No description provided for @autoUpdateChangesTitle.
  ///
  /// In zh, this message translates to:
  /// **'本次更新内容'**
  String get autoUpdateChangesTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'系统设置'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @interaction.
  ///
  /// In zh, this message translates to:
  /// **'交互'**
  String get interaction;

  /// No description provided for @effects.
  ///
  /// In zh, this message translates to:
  /// **'特效'**
  String get effects;

  /// No description provided for @other.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get other;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @languageDescription.
  ///
  /// In zh, this message translates to:
  /// **'界面、提示与系统通知均已支持多语言；歌曲资料、服务端原文和用户内容保持原文。切换后立即生效。'**
  String get languageDescription;

  /// No description provided for @languageSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'语言设置保存失败，请重试'**
  String get languageSaveFailed;

  /// No description provided for @homeSearchScope.
  ///
  /// In zh, this message translates to:
  /// **'首页搜索范围'**
  String get homeSearchScope;

  /// No description provided for @searchFeatures.
  ///
  /// In zh, this message translates to:
  /// **'功能'**
  String get searchFeatures;

  /// No description provided for @searchSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲'**
  String get searchSongs;

  /// No description provided for @searchBoth.
  ///
  /// In zh, this message translates to:
  /// **'功能+歌曲'**
  String get searchBoth;

  /// No description provided for @searchMode.
  ///
  /// In zh, this message translates to:
  /// **'搜索方式'**
  String get searchMode;

  /// No description provided for @searchInline.
  ///
  /// In zh, this message translates to:
  /// **'原位输入'**
  String get searchInline;

  /// No description provided for @searchOverlay.
  ///
  /// In zh, this message translates to:
  /// **'展开搜索'**
  String get searchOverlay;

  /// No description provided for @searchOverlayHint.
  ///
  /// In zh, this message translates to:
  /// **'首页功能和歌曲搜索使用展开搜索界面（当前默认）'**
  String get searchOverlayHint;

  /// No description provided for @searchInlineHint.
  ///
  /// In zh, this message translates to:
  /// **'直接在原搜索框输入，歌曲搜索历史显示在搜索框下方'**
  String get searchInlineHint;

  /// No description provided for @showMatchInfo.
  ///
  /// In zh, this message translates to:
  /// **'显示匹配字段'**
  String get showMatchInfo;

  /// No description provided for @showMatchInfoHint.
  ///
  /// In zh, this message translates to:
  /// **'在歌曲搜索结果里显示命中的定数、BPM、标签等信息'**
  String get showMatchInfoHint;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get themeColor;

  /// No description provided for @backgroundImage.
  ///
  /// In zh, this message translates to:
  /// **'背景图'**
  String get backgroundImage;

  /// No description provided for @decorationImage.
  ///
  /// In zh, this message translates to:
  /// **'装饰图'**
  String get decorationImage;

  /// No description provided for @pureBlackBackgroundDisabled.
  ///
  /// In zh, this message translates to:
  /// **'纯黑模式下背景图与装饰图调节不可用'**
  String get pureBlackBackgroundDisabled;

  /// No description provided for @reading.
  ///
  /// In zh, this message translates to:
  /// **'读取中…'**
  String get reading;

  /// No description provided for @useSystemWallpaperColor.
  ///
  /// In zh, this message translates to:
  /// **'使用系统壁纸配色'**
  String get useSystemWallpaperColor;

  /// No description provided for @systemWallpaperHint.
  ///
  /// In zh, this message translates to:
  /// **'Android 12 及以上可用，点击后将当前系统配色应用为主题色。'**
  String get systemWallpaperHint;

  /// No description provided for @wallpaperColorUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'系统壁纸配色需要 Android 12 或更新版本'**
  String get wallpaperColorUnsupported;

  /// No description provided for @wallpaperColorApplied.
  ///
  /// In zh, this message translates to:
  /// **'已应用系统壁纸配色'**
  String get wallpaperColorApplied;

  /// No description provided for @wallpaperColorFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取系统壁纸配色，请稍后重试'**
  String get wallpaperColorFailed;

  /// No description provided for @wallpaperApplied.
  ///
  /// In zh, this message translates to:
  /// **'壁纸已设置'**
  String get wallpaperApplied;

  /// No description provided for @wallpaperAndThemeApplied.
  ///
  /// In zh, this message translates to:
  /// **'壁纸已设置，主题色已更新'**
  String get wallpaperAndThemeApplied;

  /// No description provided for @backgroundReset.
  ///
  /// In zh, this message translates to:
  /// **'已恢复默认背景'**
  String get backgroundReset;

  /// No description provided for @themeColorUpdated.
  ///
  /// In zh, this message translates to:
  /// **'主题色已更新'**
  String get themeColorUpdated;

  /// No description provided for @themeColorReset.
  ///
  /// In zh, this message translates to:
  /// **'已恢复默认主题色'**
  String get themeColorReset;

  /// No description provided for @navigationExperience.
  ///
  /// In zh, this message translates to:
  /// **'导航体验'**
  String get navigationExperience;

  /// No description provided for @searchInteraction.
  ///
  /// In zh, this message translates to:
  /// **'搜索框交互'**
  String get searchInteraction;

  /// No description provided for @confetti.
  ///
  /// In zh, this message translates to:
  /// **'纸屑特效'**
  String get confetti;

  /// No description provided for @appUpdate.
  ///
  /// In zh, this message translates to:
  /// **'应用更新'**
  String get appUpdate;

  /// No description provided for @featureGuide.
  ///
  /// In zh, this message translates to:
  /// **'功能引导'**
  String get featureGuide;

  /// No description provided for @featureGuideHint.
  ///
  /// In zh, this message translates to:
  /// **'想再看一遍各个功能在哪里，可以随时重新打开。'**
  String get featureGuideHint;

  /// No description provided for @reopenGuide.
  ///
  /// In zh, this message translates to:
  /// **'重新查看功能引导'**
  String get reopenGuide;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览效果'**
  String get preview;

  /// No description provided for @primaryButton.
  ///
  /// In zh, this message translates to:
  /// **'主要按钮'**
  String get primaryButton;

  /// No description provided for @primaryColor.
  ///
  /// In zh, this message translates to:
  /// **'主色'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In zh, this message translates to:
  /// **'辅助色'**
  String get secondaryColor;

  /// No description provided for @tertiaryColor.
  ///
  /// In zh, this message translates to:
  /// **'强调色'**
  String get tertiaryColor;

  /// No description provided for @surfaceColor.
  ///
  /// In zh, this message translates to:
  /// **'背景色'**
  String get surfaceColor;

  /// No description provided for @customColor.
  ///
  /// In zh, this message translates to:
  /// **'自定义颜色'**
  String get customColor;

  /// No description provided for @restoreDefaults.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get restoreDefaults;

  /// No description provided for @builtInBackground.
  ///
  /// In zh, this message translates to:
  /// **'当前：内置背景'**
  String get builtInBackground;

  /// No description provided for @customBackground.
  ///
  /// In zh, this message translates to:
  /// **'当前：自定义图片'**
  String get customBackground;

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get processing;

  /// No description provided for @chooseFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get chooseFromGallery;

  /// No description provided for @decorationOpacity.
  ///
  /// In zh, this message translates to:
  /// **'chiffon 装饰图透明度'**
  String get decorationOpacity;

  /// No description provided for @decorationOpacityHint.
  ///
  /// In zh, this message translates to:
  /// **'默认 40%。纯黑模式下自动隐藏；深浅模式共用同一透明度。'**
  String get decorationOpacityHint;

  /// No description provided for @hide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get hide;

  /// No description provided for @favoriteExportExtension.
  ///
  /// In zh, this message translates to:
  /// **'收藏夹导出后缀'**
  String get favoriteExportExtension;

  /// No description provided for @syncAndGateway.
  ///
  /// In zh, this message translates to:
  /// **'同步与网关'**
  String get syncAndGateway;

  /// No description provided for @gatewayTimeout.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关检测超时'**
  String get gatewayTimeout;

  /// No description provided for @gatewayTimeoutHint.
  ///
  /// In zh, this message translates to:
  /// **'线路1 同步前会先请求 GET /v1/health 探活；超过这个时间就取消同步（不消耗 Token）。'**
  String get gatewayTimeoutHint;

  /// No description provided for @gatewayTimeoutDialogHint.
  ///
  /// In zh, this message translates to:
  /// **'线路1 同步前会先请求 GET /v1/health 探活；超过这个时间视为网关不可用，直接取消同步（不会消耗 Token）。'**
  String get gatewayTimeoutDialogHint;

  /// No description provided for @enterIntegerSeconds.
  ///
  /// In zh, this message translates to:
  /// **'请输入整数秒数'**
  String get enterIntegerSeconds;

  /// No description provided for @timeout.
  ///
  /// In zh, this message translates to:
  /// **'超时时间'**
  String get timeout;

  /// No description provided for @secondsUnit.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get secondsUnit;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @backgroundOpacity.
  ///
  /// In zh, this message translates to:
  /// **'背景透明度'**
  String get backgroundOpacity;

  /// No description provided for @backgroundDarkHint.
  ///
  /// In zh, this message translates to:
  /// **'数值越高背景越暗，0% 为原始背景图'**
  String get backgroundDarkHint;

  /// No description provided for @backgroundLightHint.
  ///
  /// In zh, this message translates to:
  /// **'数值越高背景越淡，0% 为原始背景图'**
  String get backgroundLightHint;

  /// No description provided for @lightMode.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get darkMode;

  /// No description provided for @pureBlack.
  ///
  /// In zh, this message translates to:
  /// **'纯黑背景'**
  String get pureBlack;

  /// No description provided for @pureBlackHint.
  ///
  /// In zh, this message translates to:
  /// **'使用真正的纯黑背景，隐藏背景图'**
  String get pureBlackHint;

  /// No description provided for @navigationStyle.
  ///
  /// In zh, this message translates to:
  /// **'导航栏样式'**
  String get navigationStyle;

  /// No description provided for @navigationClassic.
  ///
  /// In zh, this message translates to:
  /// **'经典悬浮'**
  String get navigationClassic;

  /// No description provided for @navigationGlass.
  ///
  /// In zh, this message translates to:
  /// **'液态玻璃'**
  String get navigationGlass;

  /// No description provided for @navigationPill.
  ///
  /// In zh, this message translates to:
  /// **'伸缩胶囊'**
  String get navigationPill;

  /// No description provided for @navigationClassicHint.
  ///
  /// In zh, this message translates to:
  /// **'图标与文字上下排列，常驻显示全部分类名称'**
  String get navigationClassicHint;

  /// No description provided for @navigationGlassHint.
  ///
  /// In zh, this message translates to:
  /// **'通透的玻璃质感，选中项带柔和高光'**
  String get navigationGlassHint;

  /// No description provided for @navigationPillHint.
  ///
  /// In zh, this message translates to:
  /// **'选中项展开文字，其余项保留图标，切换时平滑伸缩'**
  String get navigationPillHint;

  /// No description provided for @navigationAnimation.
  ///
  /// In zh, this message translates to:
  /// **'导航栏切换动画'**
  String get navigationAnimation;

  /// No description provided for @navigationAnimationHint.
  ///
  /// In zh, this message translates to:
  /// **'切换主界面时使用淡入滑动过渡，并淡化图标状态'**
  String get navigationAnimationHint;

  /// No description provided for @swipeNavigation.
  ///
  /// In zh, this message translates to:
  /// **'左右滑动切换主界面'**
  String get swipeNavigation;

  /// No description provided for @swipeNavigationHint.
  ///
  /// In zh, this message translates to:
  /// **'在主界面内容区域左右滑动即可切换底部导航项'**
  String get swipeNavigationHint;

  /// No description provided for @immersiveStatusBar.
  ///
  /// In zh, this message translates to:
  /// **'沉浸式状态栏'**
  String get immersiveStatusBar;

  /// No description provided for @immersiveStatusBarHint.
  ///
  /// In zh, this message translates to:
  /// **'隐藏顶部时间、电量等状态信息，保留底部系统导航'**
  String get immersiveStatusBarHint;

  /// No description provided for @busyHint.
  ///
  /// In zh, this message translates to:
  /// **'任务进行中提示'**
  String get busyHint;

  /// No description provided for @busyHintDescription.
  ///
  /// In zh, this message translates to:
  /// **'同步、刷新等任务进行中时，在不可用入口下方用红字说明原因'**
  String get busyHintDescription;

  /// No description provided for @customHarmonyColor.
  ///
  /// In zh, this message translates to:
  /// **'自定义调和颜色'**
  String get customHarmonyColor;

  /// No description provided for @confettiHint.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据或同步成绩成功后播放彩纸礼炮'**
  String get confettiHint;

  /// No description provided for @gravityEffect.
  ///
  /// In zh, this message translates to:
  /// **'重力效果'**
  String get gravityEffect;

  /// No description provided for @gravityEffectHint.
  ///
  /// In zh, this message translates to:
  /// **'纸屑沿弧线飘落，向上喷出的纸屑会回落'**
  String get gravityEffectHint;

  /// No description provided for @harmonyColor.
  ///
  /// In zh, this message translates to:
  /// **'调和颜色'**
  String get harmonyColor;

  /// No description provided for @harmonyLevel.
  ///
  /// In zh, this message translates to:
  /// **'调和等级'**
  String get harmonyLevel;

  /// No description provided for @harmonyHint.
  ///
  /// In zh, this message translates to:
  /// **'数值越高，彩纸颜色越接近调和颜色；0% 保留鲜艳的多彩效果'**
  String get harmonyHint;

  /// No description provided for @paperType.
  ///
  /// In zh, this message translates to:
  /// **'彩纸类型'**
  String get paperType;

  /// No description provided for @paperMixed.
  ///
  /// In zh, this message translates to:
  /// **'缤纷混彩'**
  String get paperMixed;

  /// No description provided for @paperSquare.
  ///
  /// In zh, this message translates to:
  /// **'方形纸片'**
  String get paperSquare;

  /// No description provided for @paperCircle.
  ///
  /// In zh, this message translates to:
  /// **'圆润纸片'**
  String get paperCircle;

  /// No description provided for @paperRibbon.
  ///
  /// In zh, this message translates to:
  /// **'轻盈彩带'**
  String get paperRibbon;

  /// No description provided for @burstPosition.
  ///
  /// In zh, this message translates to:
  /// **'播放位置'**
  String get burstPosition;

  /// No description provided for @burstTopBottom.
  ///
  /// In zh, this message translates to:
  /// **'上下星落'**
  String get burstTopBottom;

  /// No description provided for @burstLeftRight.
  ///
  /// In zh, this message translates to:
  /// **'左右流彩'**
  String get burstLeftRight;

  /// No description provided for @burstAllEdges.
  ///
  /// In zh, this message translates to:
  /// **'四方礼花'**
  String get burstAllEdges;

  /// No description provided for @previewNow.
  ///
  /// In zh, this message translates to:
  /// **'立即播放预览'**
  String get previewNow;

  /// No description provided for @defaultDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'歌曲详情默认难度'**
  String get defaultDifficulty;

  /// No description provided for @defaultDifficultyHint.
  ///
  /// In zh, this message translates to:
  /// **'从歌曲搜索等未指定难度的入口打开歌曲时，优先显示所选难度。'**
  String get defaultDifficultyHint;

  /// No description provided for @defaultDifficultyNote.
  ///
  /// In zh, this message translates to:
  /// **'首次使用默认为 MASTER。成绩、谱面等已指定难度的跳转保持原有难度。'**
  String get defaultDifficultyNote;

  /// No description provided for @settingSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'设置保存失败，请重试'**
  String get settingSaveFailed;

  /// No description provided for @autoInstall.
  ///
  /// In zh, this message translates to:
  /// **'自动安装更新'**
  String get autoInstall;

  /// No description provided for @experimental.
  ///
  /// In zh, this message translates to:
  /// **'测试性'**
  String get experimental;

  /// No description provided for @autoInstallHint.
  ///
  /// In zh, this message translates to:
  /// **'默认关闭，不会自动下载。仅对你主动选择的 App 内下载生效。安装包校验通过后：前台会先提示，确认后退到后台尝试安装；后台没有同步、刷新、导入导出或下载等任务持续 8 秒后自动尝试安装。任务开始或回到前台会重新计时。'**
  String get autoInstallHint;

  /// No description provided for @autoInstallNote.
  ///
  /// In zh, this message translates to:
  /// **'需要 Android 12 及以上，并允许此来源安装应用。正在播放音乐或通话时会等待，无需锁屏。实际执行仍可能受系统调度影响，部分系统需要手动确认；延迟或失败时可手动安装。安装会结束旧进程，下次打开即为新版；关闭开关不能撤回系统已开始执行的安装。'**
  String get autoInstallNote;

  /// No description provided for @autoInstallUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前系统不支持此测试功能，请手动安装更新。'**
  String get autoInstallUnsupported;

  /// No description provided for @allowInstallSource.
  ///
  /// In zh, this message translates to:
  /// **'允许此来源安装应用'**
  String get allowInstallSource;

  /// No description provided for @autoInstallSettingsError.
  ///
  /// In zh, this message translates to:
  /// **'无法应用自动安装设置，请重试或检查系统安装权限'**
  String get autoInstallSettingsError;

  /// No description provided for @reloadSettings.
  ///
  /// In zh, this message translates to:
  /// **'重新读取设置'**
  String get reloadSettings;

  /// No description provided for @hexFormatError.
  ///
  /// In zh, this message translates to:
  /// **'格式应为 #RRGGBB 或 #AARRGGBB'**
  String get hexFormatError;

  /// No description provided for @enterHexColor.
  ///
  /// In zh, this message translates to:
  /// **'输入十六进制颜色'**
  String get enterHexColor;

  /// No description provided for @hexColorHint.
  ///
  /// In zh, this message translates to:
  /// **'#RRGGBB 或 #AARRGGBB'**
  String get hexColorHint;

  /// No description provided for @hue.
  ///
  /// In zh, this message translates to:
  /// **'色相'**
  String get hue;

  /// No description provided for @colorPickerHint.
  ///
  /// In zh, this message translates to:
  /// **'拖动上方方块选色，或直接输入十六进制'**
  String get colorPickerHint;

  /// No description provided for @enterHex.
  ///
  /// In zh, this message translates to:
  /// **'输入十六进制'**
  String get enterHex;

  /// No description provided for @wallpaperCropHint.
  ///
  /// In zh, this message translates to:
  /// **'双指缩放、拖动，选择壁纸显示的范围'**
  String get wallpaperCropHint;

  /// No description provided for @wallpaperReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取这张图片，当前系统可能不支持它的格式'**
  String get wallpaperReadFailed;

  /// No description provided for @wallpaperCropFailed.
  ///
  /// In zh, this message translates to:
  /// **'裁剪失败，请重试'**
  String get wallpaperCropFailed;

  /// No description provided for @setWallpaper.
  ///
  /// In zh, this message translates to:
  /// **'设为壁纸'**
  String get setWallpaper;

  /// No description provided for @picturePickFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择图片失败：{error}'**
  String picturePickFailed(String error);

  /// No description provided for @exportDescription.
  ///
  /// In zh, this message translates to:
  /// **'导出收藏夹会生成 <名字>{extension} 文件，放在 Download/ChiffonMai/收藏夹/ 下，文件管理器可以直接找到。\n后缀已固定：自定义后缀会把常见格式的默认打开方式抢过来，所以不再开放。\n导入按文件内容识别、与后缀无关，以前用别的后缀导出的备份照样能导回来。'**
  String exportDescription(String extension);

  /// No description provided for @secondsValue.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String secondsValue(int seconds);

  /// No description provided for @gatewayTimeoutSemantics.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关检测超时，当前 {seconds} 秒'**
  String gatewayTimeoutSemantics(int seconds);

  /// No description provided for @gatewayTimeoutSaved.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关检测超时已设为 {seconds} 秒'**
  String gatewayTimeoutSaved(int seconds);

  /// No description provided for @allowedSeconds.
  ///
  /// In zh, this message translates to:
  /// **'允许 {min}–{max} 秒'**
  String allowedSeconds(int min, int max);

  /// No description provided for @defaultSecondsHint.
  ///
  /// In zh, this message translates to:
  /// **'默认 {defaultSeconds} 秒，允许 {min}–{max} 秒'**
  String defaultSecondsHint(int defaultSeconds, int min, int max);

  /// No description provided for @foregroundUpdateTitle.
  ///
  /// In zh, this message translates to:
  /// **'更新已准备好'**
  String get foregroundUpdateTitle;

  /// No description provided for @foregroundUpdateBody.
  ///
  /// In zh, this message translates to:
  /// **'安装包已校验完成。选择“退出并更新”后，App 将退到后台并尝试安装。安装会关闭当前 App，请先保存操作；完成后请重新打开。'**
  String get foregroundUpdateBody;

  /// No description provided for @foregroundUpdateLaterHint.
  ///
  /// In zh, this message translates to:
  /// **'选择“稍后”可继续使用；退到后台且无任务持续 8 秒后，仍会尝试自动安装。部分系统可能需要手动确认。'**
  String get foregroundUpdateLaterHint;

  /// No description provided for @foregroundUpdateBusy.
  ///
  /// In zh, this message translates to:
  /// **'正在执行任务或播放内容，请结束后再更新。'**
  String get foregroundUpdateBusy;

  /// No description provided for @foregroundUpdateChanged.
  ///
  /// In zh, this message translates to:
  /// **'下载状态或当前任务已变化，请重新查看后再更新。'**
  String get foregroundUpdateChanged;

  /// No description provided for @foregroundUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法开始更新，请稍后重试或在更新窗口手动安装。'**
  String get foregroundUpdateFailed;

  /// No description provided for @updateLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get updateLater;

  /// No description provided for @exitAndUpdate.
  ///
  /// In zh, this message translates to:
  /// **'退出并更新'**
  String get exitAndUpdate;

  /// No description provided for @featureSongSearch.
  ///
  /// In zh, this message translates to:
  /// **'乐曲检索'**
  String get featureSongSearch;

  /// No description provided for @featureSearchTheChinaAndInternationalLibraries.
  ///
  /// In zh, this message translates to:
  /// **'搜索国服与非国服曲库'**
  String get featureSearchTheChinaAndInternationalLibraries;

  /// No description provided for @featureVersionsAndLibraryAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'版本与曲库分析'**
  String get featureVersionsAndLibraryAnalysis;

  /// No description provided for @featureVersionDetailsUpdateComparisonsAndChartConstants.
  ///
  /// In zh, this message translates to:
  /// **'版本资料、更新对照与谱面定数'**
  String get featureVersionDetailsUpdateComparisonsAndChartConstants;

  /// No description provided for @featureImageRecognition.
  ///
  /// In zh, this message translates to:
  /// **'图像识别'**
  String get featureImageRecognition;

  /// No description provided for @featureFindSongsByCoverArtAndRead.
  ///
  /// In zh, this message translates to:
  /// **'通过曲绘找歌，识别结算成绩'**
  String get featureFindSongsByCoverArtAndRead;

  /// No description provided for @featureCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'收藏品图鉴'**
  String get featureCollectibles;

  /// No description provided for @featureBrowseIconsNameplatesAndOtherCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'浏览头像、姓名框等游戏收藏品'**
  String get featureBrowseIconsNameplatesAndOtherCollectibles;

  /// No description provided for @featureSearchAndFilter.
  ///
  /// In zh, this message translates to:
  /// **'查询与筛选'**
  String get featureSearchAndFilter;

  /// No description provided for @featureBrowseScoresAndFilterChartResults.
  ///
  /// In zh, this message translates to:
  /// **'浏览成绩，按条件查找谱面表现'**
  String get featureBrowseScoresAndFilterChartResults;

  /// No description provided for @featureGrowthAndComparison.
  ///
  /// In zh, this message translates to:
  /// **'成长与对比'**
  String get featureGrowthAndComparison;

  /// No description provided for @featureReviewImprovementsAndCompareWithFriends.
  ///
  /// In zh, this message translates to:
  /// **'回顾提升记录，对比好友成绩'**
  String get featureReviewImprovementsAndCompareWithFriends;

  /// No description provided for @featureBest50Overview.
  ///
  /// In zh, this message translates to:
  /// **'Best50 概览'**
  String get featureBest50Overview;

  /// No description provided for @featureCurrentPerformanceAndFittedPotential.
  ///
  /// In zh, this message translates to:
  /// **'当前表现与拟合潜力'**
  String get featureCurrentPerformanceAndFittedPotential;

  /// No description provided for @featurePersonalizedAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'个性化分析'**
  String get featurePersonalizedAnalysis;

  /// No description provided for @featureFilterBest50ByTagsAndConditions.
  ///
  /// In zh, this message translates to:
  /// **'按标签和条件筛选 Best50'**
  String get featureFilterBest50ByTagsAndConditions;

  /// No description provided for @featureGoalsAndScoreCards.
  ///
  /// In zh, this message translates to:
  /// **'目标与制图'**
  String get featureGoalsAndScoreCards;

  /// No description provided for @featureSimulateIdealScoresAndCreateCustomScore.
  ///
  /// In zh, this message translates to:
  /// **'模拟理想成绩，制作自定义成绩图'**
  String get featureSimulateIdealScoresAndCreateCustomScore;

  /// No description provided for @featureRatingRankings.
  ///
  /// In zh, this message translates to:
  /// **'Rating 排名'**
  String get featureRatingRankings;

  /// No description provided for @featureOfficialAndFittedRatingRankings.
  ///
  /// In zh, this message translates to:
  /// **'官方 Rating 与拟合 Rating 排行'**
  String get featureOfficialAndFittedRatingRankings;

  /// No description provided for @featureAchievementRankings.
  ///
  /// In zh, this message translates to:
  /// **'达成率排名'**
  String get featureAchievementRankings;

  /// No description provided for @featureCompareAveragePerformanceAcrossAllScores.
  ///
  /// In zh, this message translates to:
  /// **'比较全量成绩的平均表现'**
  String get featureCompareAveragePerformanceAcrossAllScores;

  /// No description provided for @featureSpecialRankings.
  ///
  /// In zh, this message translates to:
  /// **'特殊排名'**
  String get featureSpecialRankings;

  /// No description provided for @featureExplorePlayerStatisticsFromDifferentAngles.
  ///
  /// In zh, this message translates to:
  /// **'探索不同角度的玩家数据'**
  String get featureExplorePlayerStatisticsFromDifferentAngles;

  /// No description provided for @featureProgressAndChallenges.
  ///
  /// In zh, this message translates to:
  /// **'进度与挑战'**
  String get featureProgressAndChallenges;

  /// No description provided for @featureVersionTitlesRanksAndKALEIDXSCOPE.
  ///
  /// In zh, this message translates to:
  /// **'牌子、段位与 KALEIDXSCOPE'**
  String get featureVersionTitlesRanksAndKALEIDXSCOPE;

  /// No description provided for @featureCalculators.
  ///
  /// In zh, this message translates to:
  /// **'数值计算'**
  String get featureCalculators;

  /// No description provided for @featureRatingAchievementAndJudgementAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'Rating、达成率与判定反推'**
  String get featureRatingAchievementAndJudgementAnalysis;

  /// No description provided for @featureRandomPicks.
  ///
  /// In zh, this message translates to:
  /// **'随机选曲'**
  String get featureRandomPicks;

  /// No description provided for @featureDecideWhatToPlayToday.
  ///
  /// In zh, this message translates to:
  /// **'决定今天玩什么'**
  String get featureDecideWhatToPlayToday;

  /// No description provided for @featurePracticeRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'练习推荐'**
  String get featurePracticeRecommendations;

  /// No description provided for @featureChooseChartsByGainTagsGoalsOr.
  ///
  /// In zh, this message translates to:
  /// **'围绕收益、标签、目标与定数挑谱'**
  String get featureChooseChartsByGainTagsGoalsOr;

  /// No description provided for @featureFavoritesAndPlayQueue.
  ///
  /// In zh, this message translates to:
  /// **'收藏与待玩'**
  String get featureFavoritesAndPlayQueue;

  /// No description provided for @featureOrganizeChartsForYourNextArcadeVisit.
  ///
  /// In zh, this message translates to:
  /// **'整理谱面，准备下次出勤'**
  String get featureOrganizeChartsForYourNextArcadeVisit;

  /// No description provided for @featureArcadeMaps.
  ///
  /// In zh, this message translates to:
  /// **'机厅地图'**
  String get featureArcadeMaps;

  /// No description provided for @featureFindRhythmGameArcadesInChinaAnd.
  ///
  /// In zh, this message translates to:
  /// **'查找国内与全球音游机厅'**
  String get featureFindRhythmGameArcadesInChinaAnd;

  /// No description provided for @featureSoloGameSettings.
  ///
  /// In zh, this message translates to:
  /// **'单人游戏设置'**
  String get featureSoloGameSettings;

  /// No description provided for @featureManageSharedRulesAndModePreferences.
  ///
  /// In zh, this message translates to:
  /// **'统一管理各模式的规则与偏好'**
  String get featureManageSharedRulesAndModePreferences;

  /// No description provided for @featureTextClues.
  ///
  /// In zh, this message translates to:
  /// **'文字线索'**
  String get featureTextClues;

  /// No description provided for @featureGuessSongsFromMemoryAliasesAndLetters.
  ///
  /// In zh, this message translates to:
  /// **'凭记忆、别名与字母线索猜歌'**
  String get featureGuessSongsFromMemoryAliasesAndLetters;

  /// No description provided for @featureCoverArtChallenges.
  ///
  /// In zh, this message translates to:
  /// **'曲绘辨识'**
  String get featureCoverArtChallenges;

  /// No description provided for @featureTryCroppedPixelatedBlurredFlashAndPuzzle.
  ///
  /// In zh, this message translates to:
  /// **'观察局部、像素、模糊、快闪与拼图曲绘'**
  String get featureTryCroppedPixelatedBlurredFlashAndPuzzle;

  /// No description provided for @featureAudioChallenges.
  ///
  /// In zh, this message translates to:
  /// **'音频辨识'**
  String get featureAudioChallenges;

  /// No description provided for @featureIdentifyNormalReversedOrPitchShiftedClips.
  ///
  /// In zh, this message translates to:
  /// **'通过原速、倒放或变调片段辨认歌曲'**
  String get featureIdentifyNormalReversedOrPitchShiftedClips;

  /// No description provided for @featureChartChallenges.
  ///
  /// In zh, this message translates to:
  /// **'谱面辨识'**
  String get featureChartChallenges;

  /// No description provided for @featureGuessSongsFromSilentChartClips.
  ///
  /// In zh, this message translates to:
  /// **'根据无声谱面片段猜歌'**
  String get featureGuessSongsFromSilentChartClips;

  /// No description provided for @featureMultiplayer.
  ///
  /// In zh, this message translates to:
  /// **'多人联机'**
  String get featureMultiplayer;

  /// No description provided for @featureChallengeTheSongLibraryWithFriends.
  ///
  /// In zh, this message translates to:
  /// **'与朋友一起挑战曲库'**
  String get featureChallengeTheSongLibraryWithFriends;

  /// No description provided for @featureMusicAndChartPlayback.
  ///
  /// In zh, this message translates to:
  /// **'音乐与谱面播放'**
  String get featureMusicAndChartPlayback;

  /// No description provided for @featureListenToMaimaiSongsAndPlayCustom.
  ///
  /// In zh, this message translates to:
  /// **'听舞萌歌曲，播放自定义谱面'**
  String get featureListenToMaimaiSongsAndPlayCustom;

  /// No description provided for @featureAccountsAndAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'账号与授权'**
  String get featureAccountsAndAuthorization;

  /// No description provided for @featureManageAccountsAndDataSourceSignIns.
  ///
  /// In zh, this message translates to:
  /// **'管理账号与数据源登录状态'**
  String get featureManageAccountsAndDataSourceSignIns;

  /// No description provided for @featureSinglePlatformSync.
  ///
  /// In zh, this message translates to:
  /// **'单平台同步'**
  String get featureSinglePlatformSync;

  /// No description provided for @featureSyncScoresToEachScoreTracker.
  ///
  /// In zh, this message translates to:
  /// **'分别同步成绩到各查分器'**
  String get featureSyncScoresToEachScoreTracker;

  /// No description provided for @featureBatchAndScheduledSync.
  ///
  /// In zh, this message translates to:
  /// **'批量与定时同步'**
  String get featureBatchAndScheduledSync;

  /// No description provided for @featureSyncToMultiplePlatformsOrAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'多端同步与自动同步'**
  String get featureSyncToMultiplePlatformsOrAutomatically;

  /// No description provided for @featureRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'数据刷新'**
  String get featureRefreshData;

  /// No description provided for @featureUpdateCachedScoresAndCabinetPlayCounts.
  ///
  /// In zh, this message translates to:
  /// **'更新成绩缓存与机台游玩次数'**
  String get featureUpdateCachedScoresAndCabinetPlayCounts;

  /// No description provided for @featureLocalData.
  ///
  /// In zh, this message translates to:
  /// **'本地数据管理'**
  String get featureLocalData;

  /// No description provided for @featureBackUpDataAndManageLocalCaches.
  ///
  /// In zh, this message translates to:
  /// **'备份数据，管理本地缓存'**
  String get featureBackUpDataAndManageLocalCaches;

  /// No description provided for @featureAppPreferences.
  ///
  /// In zh, this message translates to:
  /// **'应用偏好'**
  String get featureAppPreferences;

  /// No description provided for @featureThemeInteractionsAndLoadingQuotes.
  ///
  /// In zh, this message translates to:
  /// **'主题、交互与加载语录'**
  String get featureThemeInteractionsAndLoadingQuotes;

  /// No description provided for @featureDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'运行诊断'**
  String get featureDiagnostics;

  /// No description provided for @featureCheckServicesAndExportLogs.
  ///
  /// In zh, this message translates to:
  /// **'检查服务状态，导出运行日志'**
  String get featureCheckServicesAndExportLogs;

  /// No description provided for @featureCommunityActivity.
  ///
  /// In zh, this message translates to:
  /// **'社区动态'**
  String get featureCommunityActivity;

  /// No description provided for @featureBrowseRecentCommentsAndRatings.
  ///
  /// In zh, this message translates to:
  /// **'查看最近评论与评分'**
  String get featureBrowseRecentCommentsAndRatings;

  /// No description provided for @featureVersionAndProject.
  ///
  /// In zh, this message translates to:
  /// **'版本与项目'**
  String get featureVersionAndProject;

  /// No description provided for @featureUpdatesProjectInformationAndLinks.
  ///
  /// In zh, this message translates to:
  /// **'版本更新、项目介绍与相关链接'**
  String get featureUpdatesProjectInformationAndLinks;

  /// No description provided for @featureFeedbackAndSupport.
  ///
  /// In zh, this message translates to:
  /// **'反馈与支持'**
  String get featureFeedbackAndSupport;

  /// No description provided for @featureReportIssuesShareIdeasAndSupportDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'反馈问题、交流建议与支持开发'**
  String get featureReportIssuesShareIdeasAndSupportDevelopment;

  /// No description provided for @featureSongLookup.
  ///
  /// In zh, this message translates to:
  /// **'乐曲查询'**
  String get featureSongLookup;

  /// No description provided for @featureSearchByTitleAliasCharterOrTag.
  ///
  /// In zh, this message translates to:
  /// **'按歌名、别名、谱师和标签搜索'**
  String get featureSearchByTitleAliasCharterOrTag;

  /// No description provided for @featureInternationalSongLookup.
  ///
  /// In zh, this message translates to:
  /// **'非国服乐曲查询'**
  String get featureInternationalSongLookup;

  /// No description provided for @featureSearchAndFilterTheInternationalLibrary.
  ///
  /// In zh, this message translates to:
  /// **'搜索与筛选非国服曲库'**
  String get featureSearchAndFilterTheInternationalLibrary;

  /// No description provided for @featureChinaUpdateComparison.
  ///
  /// In zh, this message translates to:
  /// **'国服更新对照'**
  String get featureChinaUpdateComparison;

  /// No description provided for @featureFindSongsReleasedInJapanButNot.
  ///
  /// In zh, this message translates to:
  /// **'看日服已上、国服还没上的曲目'**
  String get featureFindSongsReleasedInJapanButNot;

  /// No description provided for @featureUpdateCalendar.
  ///
  /// In zh, this message translates to:
  /// **'更新日历'**
  String get featureUpdateCalendar;

  /// No description provided for @featureBrowseChinaChartUpdatesByDate.
  ///
  /// In zh, this message translates to:
  /// **'按日期查看国服每次更新的谱面'**
  String get featureBrowseChinaChartUpdatesByDate;

  /// No description provided for @featureVersionComparison.
  ///
  /// In zh, this message translates to:
  /// **'版本对照'**
  String get featureVersionComparison;

  /// No description provided for @featureBrowsePlayableSongsByVersion.
  ///
  /// In zh, this message translates to:
  /// **'按版本整理可游玩曲目'**
  String get featureBrowsePlayableSongsByVersion;

  /// No description provided for @featureChartConstantDistribution.
  ///
  /// In zh, this message translates to:
  /// **'定数分布'**
  String get featureChartConstantDistribution;

  /// No description provided for @featureViewTheDistributionOfChartConstants.
  ///
  /// In zh, this message translates to:
  /// **'查看谱面定数分布'**
  String get featureViewTheDistributionOfChartConstants;

  /// No description provided for @featureCoverRecognition.
  ///
  /// In zh, this message translates to:
  /// **'曲绘识别'**
  String get featureCoverRecognition;

  /// No description provided for @featureFindSongsUsingYourCameraOrAn.
  ///
  /// In zh, this message translates to:
  /// **'用相机或图片快速找歌'**
  String get featureFindSongsUsingYourCameraOrAn;

  /// No description provided for @featureResultScreenRecognition.
  ///
  /// In zh, this message translates to:
  /// **'结算画面识别'**
  String get featureResultScreenRecognition;

  /// No description provided for @featurePhotographAResultScreenToReadScores.
  ///
  /// In zh, this message translates to:
  /// **'拍摄机台结算画面，自动识别成绩'**
  String get featurePhotographAResultScreenToReadScores;

  /// No description provided for @featureCollectibleLookup.
  ///
  /// In zh, this message translates to:
  /// **'收藏品查询'**
  String get featureCollectibleLookup;

  /// No description provided for @featureViewIconsNameplatesAndOtherCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'查看头像、姓名框等收藏品'**
  String get featureViewIconsNameplatesAndOtherCollectibles;

  /// No description provided for @featureScoreLookup.
  ///
  /// In zh, this message translates to:
  /// **'成绩查询'**
  String get featureScoreLookup;

  /// No description provided for @featureBrowseAndFilterAllPlayRecords.
  ///
  /// In zh, this message translates to:
  /// **'浏览全部游玩记录与筛选结果'**
  String get featureBrowseAndFilterAllPlayRecords;

  /// No description provided for @featureCustomScoreLookup.
  ///
  /// In zh, this message translates to:
  /// **'个性化成绩查询'**
  String get featureCustomScoreLookup;

  /// No description provided for @featureViewScoresByLevelOrCharter.
  ///
  /// In zh, this message translates to:
  /// **'按等级或谱师查看成绩'**
  String get featureViewScoresByLevelOrCharter;

  /// No description provided for @featureScoreImprovementHistory.
  ///
  /// In zh, this message translates to:
  /// **'成绩提升历史'**
  String get featureScoreImprovementHistory;

  /// No description provided for @featureReviewDailyChangesToYourBestScores.
  ///
  /// In zh, this message translates to:
  /// **'按日回顾最佳成绩的变化与提升'**
  String get featureReviewDailyChangesToYourBestScores;

  /// No description provided for @featureRatingHistory.
  ///
  /// In zh, this message translates to:
  /// **'Rating 历史'**
  String get featureRatingHistory;

  /// No description provided for @featureTrackRatingOverTime.
  ///
  /// In zh, this message translates to:
  /// **'看 Rating 随时间的变化'**
  String get featureTrackRatingOverTime;

  /// No description provided for @featureFriendComparison.
  ///
  /// In zh, this message translates to:
  /// **'好友对比'**
  String get featureFriendComparison;

  /// No description provided for @featureCompareYourScoresWithAFriend.
  ///
  /// In zh, this message translates to:
  /// **'看看你和好友的成绩差异'**
  String get featureCompareYourScoresWithAFriend;

  /// No description provided for @featureViewYourCurrentBest35AndBest15.
  ///
  /// In zh, this message translates to:
  /// **'查看当前 Best35 与 Best15'**
  String get featureViewYourCurrentBest35AndBest15;

  /// No description provided for @featureFittedBest50.
  ///
  /// In zh, this message translates to:
  /// **'拟合 Best50'**
  String get featureFittedBest50;

  /// No description provided for @featureAnalyzeYourPotentialRatingCeiling.
  ///
  /// In zh, this message translates to:
  /// **'分析潜在 Rating 上限'**
  String get featureAnalyzeYourPotentialRatingCeiling;

  /// No description provided for @featureCustomBest50Analysis.
  ///
  /// In zh, this message translates to:
  /// **'个性化 Best50'**
  String get featureCustomBest50Analysis;

  /// No description provided for @featureFilterBest50ByTag.
  ///
  /// In zh, this message translates to:
  /// **'按标签筛选 Best50'**
  String get featureFilterBest50ByTag;

  /// No description provided for @featureCustomFittedBest50.
  ///
  /// In zh, this message translates to:
  /// **'个性化拟合 Best50'**
  String get featureCustomFittedBest50;

  /// No description provided for @featureViewFittedRatingPotentialByTag.
  ///
  /// In zh, this message translates to:
  /// **'按标签查看拟合 Rating 上限'**
  String get featureViewFittedRatingPotentialByTag;

  /// No description provided for @featureIdealBest50.
  ///
  /// In zh, this message translates to:
  /// **'理想 Best50'**
  String get featureIdealBest50;

  /// No description provided for @featureSimulateBest50WithEveryScoreRaisedOne.
  ///
  /// In zh, this message translates to:
  /// **'全员升一档后的 Best50 模拟'**
  String get featureSimulateBest50WithEveryScoreRaisedOne;

  /// No description provided for @featureCreateBest50.
  ///
  /// In zh, this message translates to:
  /// **'自定义 Best50'**
  String get featureCreateBest50;

  /// No description provided for @featureFillIn50ScoreCardsManually.
  ///
  /// In zh, this message translates to:
  /// **'手动填写 50 张成绩卡片'**
  String get featureFillIn50ScoreCardsManually;

  /// No description provided for @featureRatingLeaderboard.
  ///
  /// In zh, this message translates to:
  /// **'Rating 排行榜'**
  String get featureRatingLeaderboard;

  /// No description provided for @featureViewPlayerRatingRankings.
  ///
  /// In zh, this message translates to:
  /// **'查看玩家 Rating 排行'**
  String get featureViewPlayerRatingRankings;

  /// No description provided for @featureTotalFittedRatingLeaderboard.
  ///
  /// In zh, this message translates to:
  /// **'拟合总Rating排行榜'**
  String get featureTotalFittedRatingLeaderboard;

  /// No description provided for @featureCompareFittedTotalRatingWithOfficialBest50.
  ///
  /// In zh, this message translates to:
  /// **'查看拟合总 Rating 与官方 Best50 差值'**
  String get featureCompareFittedTotalRatingWithOfficialBest50;

  /// No description provided for @featureAverageAchievementLeaderboard.
  ///
  /// In zh, this message translates to:
  /// **'平均达成率排行榜'**
  String get featureAverageAchievementLeaderboard;

  /// No description provided for @featureRankByAverageAchievementAcrossAllScores.
  ///
  /// In zh, this message translates to:
  /// **'按全量成绩的平均达成率排名'**
  String get featureRankByAverageAchievementAcrossAllScores;

  /// No description provided for @featureAverageDXScoreRateLeaderboard.
  ///
  /// In zh, this message translates to:
  /// **'平均DX分数达成率排行榜'**
  String get featureAverageDXScoreRateLeaderboard;

  /// No description provided for @featureRankByAverageDXScoreRateAcross.
  ///
  /// In zh, this message translates to:
  /// **'按全量成绩的平均DX得分达成率排名'**
  String get featureRankByAverageDXScoreRateAcross;

  /// No description provided for @featureSpecialLeaderboards.
  ///
  /// In zh, this message translates to:
  /// **'特殊排行榜'**
  String get featureSpecialLeaderboards;

  /// No description provided for @featureDiscoverInterestingPlayerStatistics.
  ///
  /// In zh, this message translates to:
  /// **'发现有趣的玩家数据'**
  String get featureDiscoverInterestingPlayerStatistics;

  /// No description provided for @featureVersionTitleProgress.
  ///
  /// In zh, this message translates to:
  /// **'牌子进度'**
  String get featureVersionTitleProgress;

  /// No description provided for @featureViewVersionsAndTargetTitles.
  ///
  /// In zh, this message translates to:
  /// **'查看各版本与目标牌子'**
  String get featureViewVersionsAndTargetTitles;

  /// No description provided for @featureRankTable.
  ///
  /// In zh, this message translates to:
  /// **'段位表'**
  String get featureRankTable;

  /// No description provided for @featureChallengeYourNextRank.
  ///
  /// In zh, this message translates to:
  /// **'挑战你的下一段位'**
  String get featureChallengeYourNextRank;

  /// No description provided for @featureExploreAUniqueMaimaiMode.
  ///
  /// In zh, this message translates to:
  /// **'探索独特的舞萌玩法'**
  String get featureExploreAUniqueMaimaiMode;

  /// No description provided for @featureSongRatingCalculator.
  ///
  /// In zh, this message translates to:
  /// **'单曲 Rating 计算'**
  String get featureSongRatingCalculator;

  /// No description provided for @featureCalculateASongRatingFromAchievement.
  ///
  /// In zh, this message translates to:
  /// **'根据达成率计算单首 rating'**
  String get featureCalculateASongRatingFromAchievement;

  /// No description provided for @featureAchievementCalculator.
  ///
  /// In zh, this message translates to:
  /// **'达成率计算'**
  String get featureAchievementCalculator;

  /// No description provided for @featureCalculateAchievementFromJudgements.
  ///
  /// In zh, this message translates to:
  /// **'根据判定详情算出达成率'**
  String get featureCalculateAchievementFromJudgements;

  /// No description provided for @featureReverseAchievementCalculator.
  ///
  /// In zh, this message translates to:
  /// **'达成率反推'**
  String get featureReverseAchievementCalculator;

  /// No description provided for @featureInferBREAKDetailsFromJudgements.
  ///
  /// In zh, this message translates to:
  /// **'根据判定详情推出绝赞详情'**
  String get featureInferBREAKDetailsFromJudgements;

  /// No description provided for @featureDailyRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'每日推荐'**
  String get featureDailyRecommendations;

  /// No description provided for @featureLetRecommendationsPickYourNextSong.
  ///
  /// In zh, this message translates to:
  /// **'今天打什么？交给推荐'**
  String get featureLetRecommendationsPickYourNextSong;

  /// No description provided for @featureRandomSongs.
  ///
  /// In zh, this message translates to:
  /// **'随机乐曲'**
  String get featureRandomSongs;

  /// No description provided for @featureDrawACustomNumberOfRandomSongs.
  ///
  /// In zh, this message translates to:
  /// **'自定义数量随机抽取歌曲'**
  String get featureDrawACustomNumberOfRandomSongs;

  /// No description provided for @featureArcadeRoulette.
  ///
  /// In zh, this message translates to:
  /// **'出勤转盘'**
  String get featureArcadeRoulette;

  /// No description provided for @featureLetARouletteWheelChooseYourSession.
  ///
  /// In zh, this message translates to:
  /// **'等分转盘决定本次出勤选项'**
  String get featureLetARouletteWheelChooseYourSession;

  /// No description provided for @featureRatingGainRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'吃分推荐'**
  String get featureRatingGainRecommendations;

  /// No description provided for @featureChooseChartsByNetB50GainAlgorithm.
  ///
  /// In zh, this message translates to:
  /// **'按 B50 净收益挑谱 · AWMC 提供算法支持'**
  String get featureChooseChartsByNetB50GainAlgorithm;

  /// No description provided for @featureTagRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'基于标签推荐'**
  String get featureTagRecommendations;

  /// No description provided for @featureFindSongsBasedOnTagsFromYour.
  ///
  /// In zh, this message translates to:
  /// **'基于你的游玩谱面标签推荐曲目'**
  String get featureFindSongsBasedOnTagsFromYour;

  /// No description provided for @featureTargetRatingRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'基于目标 Rating 推荐'**
  String get featureTargetRatingRecommendations;

  /// No description provided for @featureFindChartsThatCanRaiseYourRating.
  ///
  /// In zh, this message translates to:
  /// **'寻找适合上分的谱面'**
  String get featureFindChartsThatCanRaiseYourRating;

  /// No description provided for @featureConstantRangeRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'基于定数区间推荐'**
  String get featureConstantRangeRecommendations;

  /// No description provided for @featureChooseChartsWithinAConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'按定数范围挑选谱面'**
  String get featureChooseChartsWithinAConstantRange;

  /// No description provided for @featureFavoriteFolders.
  ///
  /// In zh, this message translates to:
  /// **'收藏夹'**
  String get featureFavoriteFolders;

  /// No description provided for @featureManageYourFavoriteCharts.
  ///
  /// In zh, this message translates to:
  /// **'管理你收藏的谱面'**
  String get featureManageYourFavoriteCharts;

  /// No description provided for @featurePlayNext.
  ///
  /// In zh, this message translates to:
  /// **'下次想玩'**
  String get featurePlayNext;

  /// No description provided for @featureQueueSongsForYourNextArcadeVisit.
  ///
  /// In zh, this message translates to:
  /// **'排好下次去机台想玩的歌曲'**
  String get featureQueueSongsForYourNextArcadeVisit;

  /// No description provided for @featureChinaRhythmGameMap.
  ///
  /// In zh, this message translates to:
  /// **'全国音游地图'**
  String get featureChinaRhythmGameMap;

  /// No description provided for @featureFindArcadesWithTheGamesYouWant.
  ///
  /// In zh, this message translates to:
  /// **'看看哪里有你想玩的机台'**
  String get featureFindArcadesWithTheGamesYouWant;

  /// No description provided for @featureWorldwideArcadeMap.
  ///
  /// In zh, this message translates to:
  /// **'全球音游街机地图'**
  String get featureWorldwideArcadeMap;

  /// No description provided for @featureBrowseArcadesWorldwideOnNearCade.
  ///
  /// In zh, this message translates to:
  /// **'查看 NearCade 全球街机店铺'**
  String get featureBrowseArcadesWorldwideOnNearCade;

  /// No description provided for @featureSoloSongGameSettings.
  ///
  /// In zh, this message translates to:
  /// **'单人猜歌游戏设置'**
  String get featureSoloSongGameSettings;

  /// No description provided for @featureManageSharedAndModeSpecificRules.
  ///
  /// In zh, this message translates to:
  /// **'管理共用规则和各模式设置'**
  String get featureManageSharedAndModeSpecificRules;

  /// No description provided for @featureNoClueSongQuiz.
  ///
  /// In zh, this message translates to:
  /// **'无提示猜歌'**
  String get featureNoClueSongQuiz;

  /// No description provided for @featureChallengeTheSongLibraryFromMemory.
  ///
  /// In zh, this message translates to:
  /// **'凭记忆挑战曲库'**
  String get featureChallengeTheSongLibraryFromMemory;

  /// No description provided for @featureAliasSongQuiz.
  ///
  /// In zh, this message translates to:
  /// **'根据别名猜歌'**
  String get featureAliasSongQuiz;

  /// No description provided for @featureTestYourKnowledgeOfSongAliases.
  ///
  /// In zh, this message translates to:
  /// **'用别名挑战你的熟悉度'**
  String get featureTestYourKnowledgeOfSongAliases;

  /// No description provided for @featureMaimaiLetterReveal.
  ///
  /// In zh, this message translates to:
  /// **'舞萌开字母'**
  String get featureMaimaiLetterReveal;

  /// No description provided for @featureGuessSongsFromRevealedLetters.
  ///
  /// In zh, this message translates to:
  /// **'看首字母猜歌'**
  String get featureGuessSongsFromRevealedLetters;

  /// No description provided for @featureCroppedCoverQuiz.
  ///
  /// In zh, this message translates to:
  /// **'根据部分曲绘猜歌'**
  String get featureCroppedCoverQuiz;

  /// No description provided for @featureGuessTheSongFromASmallPart.
  ///
  /// In zh, this message translates to:
  /// **'看一小块曲绘猜出歌曲'**
  String get featureGuessTheSongFromASmallPart;

  /// No description provided for @featureBlurredCoverQuiz.
  ///
  /// In zh, this message translates to:
  /// **'根据模糊曲绘猜歌'**
  String get featureBlurredCoverQuiz;

  /// No description provided for @featureGuessSongsFromBlurredCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'根据模糊化处理后的曲绘猜歌'**
  String get featureGuessSongsFromBlurredCoverArt;

  /// No description provided for @featurePixelCoverQuiz.
  ///
  /// In zh, this message translates to:
  /// **'像素曲绘猜歌'**
  String get featurePixelCoverQuiz;

  /// No description provided for @featureGuessSongsFromPixelatedColorsAndShapes.
  ///
  /// In zh, this message translates to:
  /// **'根据像素马赛克的色块与轮廓猜歌'**
  String get featureGuessSongsFromPixelatedColorsAndShapes;

  /// No description provided for @featureFlashCoverQuiz.
  ///
  /// In zh, this message translates to:
  /// **'曲绘快闪猜歌'**
  String get featureFlashCoverQuiz;

  /// No description provided for @featureRememberABrieflyFlashedCover.
  ///
  /// In zh, this message translates to:
  /// **'曲绘一闪而过，凭记忆猜歌'**
  String get featureRememberABrieflyFlashedCover;

  /// No description provided for @featureCoverPuzzleQuiz.
  ///
  /// In zh, this message translates to:
  /// **'曲绘拼图猜歌'**
  String get featureCoverPuzzleQuiz;

  /// No description provided for @featureWatchCoverPiecesAppearOverTime.
  ///
  /// In zh, this message translates to:
  /// **'曲绘碎块随时间逐步拼合显现'**
  String get featureWatchCoverPiecesAppearOverTime;

  /// No description provided for @featureAudioClipQuiz.
  ///
  /// In zh, this message translates to:
  /// **'根据歌曲片段猜歌'**
  String get featureAudioClipQuiz;

  /// No description provided for @featureGuessSongsFromShortAudioClips.
  ///
  /// In zh, this message translates to:
  /// **'截取音源片段猜歌'**
  String get featureGuessSongsFromShortAudioClips;

  /// No description provided for @featureReversedAudioQuiz.
  ///
  /// In zh, this message translates to:
  /// **'倒放音频猜歌'**
  String get featureReversedAudioQuiz;

  /// No description provided for @featureGuessSongsFromReversedClips.
  ///
  /// In zh, this message translates to:
  /// **'听倒放歌曲片段猜歌'**
  String get featureGuessSongsFromReversedClips;

  /// No description provided for @featureSpeedAndPitchQuiz.
  ///
  /// In zh, this message translates to:
  /// **'变速变调猜歌'**
  String get featureSpeedAndPitchQuiz;

  /// No description provided for @featureGuessSongsFromSpeedAndPitchChanges.
  ///
  /// In zh, this message translates to:
  /// **'根据变速变调的音频猜歌'**
  String get featureGuessSongsFromSpeedAndPitchChanges;

  /// No description provided for @featureChartClipQuiz.
  ///
  /// In zh, this message translates to:
  /// **'谱面片段猜歌'**
  String get featureChartClipQuiz;

  /// No description provided for @featureGuessSongsFromSilentChartAnimations.
  ///
  /// In zh, this message translates to:
  /// **'看一段无声谱面动画猜出歌曲'**
  String get featureGuessSongsFromSilentChartAnimations;

  /// No description provided for @featureMultiplayerSongQuiz.
  ///
  /// In zh, this message translates to:
  /// **'多人猜歌游戏'**
  String get featureMultiplayerSongQuiz;

  /// No description provided for @featureGuessMaimaiSongsWithFriends.
  ///
  /// In zh, this message translates to:
  /// **'和朋友一起猜舞萌曲库'**
  String get featureGuessMaimaiSongsWithFriends;

  /// No description provided for @featureMusicPlayer.
  ///
  /// In zh, this message translates to:
  /// **'随身听'**
  String get featureMusicPlayer;

  /// No description provided for @featurePlayMaimaiMusicInTheBackgroundWith.
  ///
  /// In zh, this message translates to:
  /// **'后台播放舞萌曲库，带通知栏播放器'**
  String get featurePlayMaimaiMusicInTheBackgroundWith;

  /// No description provided for @featureCustomChartPlayback.
  ///
  /// In zh, this message translates to:
  /// **'自定义谱面播放'**
  String get featureCustomChartPlayback;

  /// No description provided for @featurePlayLocalCustomCharts.
  ///
  /// In zh, this message translates to:
  /// **'播放本地自定义谱面'**
  String get featurePlayLocalCustomCharts;

  /// No description provided for @featureAccountManagement.
  ///
  /// In zh, this message translates to:
  /// **'成绩导入凭据'**
  String get featureAccountManagement;

  /// No description provided for @featureViewYourLinkedDivingFishAccount.
  ///
  /// In zh, this message translates to:
  /// **'管理水鱼、落雪与 AWMC NET 的成绩导入 Token'**
  String get featureViewYourLinkedDivingFishAccount;

  /// No description provided for @featureAccountSetupGuide.
  ///
  /// In zh, this message translates to:
  /// **'账号注册引导'**
  String get featureAccountSetupGuide;

  /// No description provided for @featureSetUpDivingFishLXNSAndAWMC.
  ///
  /// In zh, this message translates to:
  /// **'水鱼注册、落雪注册与 AWMC NET 档案创建引导'**
  String get featureSetUpDivingFishLXNSAndAWMC;

  /// No description provided for @featureSignInToMaimaiScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'登录 maimai Score Hub'**
  String get featureSignInToMaimaiScoreHub;

  /// No description provided for @featureSignInForOCRAndScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'仅登录，不同步成绩；用于 OCR 与 maimai Score Hub 功能'**
  String get featureSignInForOCRAndScoreHub;

  /// No description provided for @featureSignOutOfDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'登出水鱼账号'**
  String get featureSignOutOfDivingFish;

  /// No description provided for @featureClearYourDivingFishSignIn.
  ///
  /// In zh, this message translates to:
  /// **'清除水鱼登录状态'**
  String get featureClearYourDivingFishSignIn;

  /// No description provided for @featureSignInToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'登录水鱼'**
  String get featureSignInToDivingFish;

  /// No description provided for @featureGetAnImportTokenToEnableScoreSync.
  ///
  /// In zh, this message translates to:
  /// **'获取 ImportToken 以使用同步功能'**
  String get featureGetAnImportTokenToEnableScoreSync;

  /// No description provided for @featureSyncToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'同步成绩到水鱼'**
  String get featureSyncToDivingFish;

  /// No description provided for @featureScanACodeToFetchAndSync.
  ///
  /// In zh, this message translates to:
  /// **'扫码抓取并同步最新成绩'**
  String get featureScanACodeToFetchAndSync;

  /// No description provided for @featureSyncToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'同步成绩到落雪'**
  String get featureSyncToLXNS;

  /// No description provided for @featureSyncLocalScoresToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'将本地成绩同步到落雪咖啡屋'**
  String get featureSyncLocalScoresToLXNS;

  /// No description provided for @featureSyncToAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'同步成绩到 AWMC NET'**
  String get featureSyncToAWMCNET;

  /// No description provided for @featureImportScoresToAWMCNETUsingA.
  ///
  /// In zh, this message translates to:
  /// **'用机台二维码导入成绩到 AWMC NET'**
  String get featureImportScoresToAWMCNETUsingA;

  /// No description provided for @featureSyncToMultiplePlatforms.
  ///
  /// In zh, this message translates to:
  /// **'同步成绩到多端'**
  String get featureSyncToMultiplePlatforms;

  /// No description provided for @featureSendTheSameScoresToMultipleTrackers.
  ///
  /// In zh, this message translates to:
  /// **'一份成绩同步到多个查分器'**
  String get featureSendTheSameScoresToMultipleTrackers;

  /// No description provided for @featureAutoSync.
  ///
  /// In zh, this message translates to:
  /// **'自动同步'**
  String get featureAutoSync;

  /// No description provided for @featureQuickSyncDailyAt0000And.
  ///
  /// In zh, this message translates to:
  /// **'每天北京时间 0 点和 12 点自动快速同步'**
  String get featureQuickSyncDailyAt0000And;

  /// No description provided for @featureRefreshCachedData.
  ///
  /// In zh, this message translates to:
  /// **'拉取成绩并更新数据'**
  String get featureRefreshCachedData;

  /// No description provided for @featureFetchAndInitializeAllLocalCachesAgain.
  ///
  /// In zh, this message translates to:
  /// **'拉取所选账号的成绩并重算 Best50，同时更新曲目、定数与标签'**
  String get featureFetchAndInitializeAllLocalCachesAgain;

  /// No description provided for @featureAdvancedRefresh.
  ///
  /// In zh, this message translates to:
  /// **'拉取成绩并更新数据（高级）'**
  String get featureAdvancedRefresh;

  /// No description provided for @featureChooseCachesToRefreshAndTestAPI.
  ///
  /// In zh, this message translates to:
  /// **'按数据类型选择是否强制重新下载，并测试各接口连通性'**
  String get featureChooseCachesToRefreshAndTestAPI;

  /// No description provided for @featureRefreshCabinetPlayCount.
  ///
  /// In zh, this message translates to:
  /// **'刷新机台游玩次数'**
  String get featureRefreshCabinetPlayCount;

  /// No description provided for @featureReadOnlyTheCurrentAccountPlayCount.
  ///
  /// In zh, this message translates to:
  /// **'单独读取当前账号的 PC 数；不会附带同步成绩'**
  String get featureReadOnlyTheCurrentAccountPlayCount;

  /// No description provided for @featureDataBackup.
  ///
  /// In zh, this message translates to:
  /// **'数据备份'**
  String get featureDataBackup;

  /// No description provided for @featureImportOrExportLocalData.
  ///
  /// In zh, this message translates to:
  /// **'导入或导出本地数据'**
  String get featureImportOrExportLocalData;

  /// No description provided for @featureCacheManagement.
  ///
  /// In zh, this message translates to:
  /// **'缓存管理'**
  String get featureCacheManagement;

  /// No description provided for @featureViewAndClearAudioPVAndMaidata.
  ///
  /// In zh, this message translates to:
  /// **'查看并清理音源、PV、maidata 缓存'**
  String get featureViewAndClearAudioPVAndMaidata;

  /// No description provided for @featureSystemSettings.
  ///
  /// In zh, this message translates to:
  /// **'系统设置'**
  String get featureSystemSettings;

  /// No description provided for @featureAdjustThemeBackgroundInteractionsAndSync.
  ///
  /// In zh, this message translates to:
  /// **'调整主题、背景图、交互与同步选项'**
  String get featureAdjustThemeBackgroundInteractionsAndSync;

  /// No description provided for @featureLoadingQuotes.
  ///
  /// In zh, this message translates to:
  /// **'加载语录管理'**
  String get featureLoadingQuotes;

  /// No description provided for @featureChooseQuotesShownWhileLoading.
  ///
  /// In zh, this message translates to:
  /// **'选择加载时展示的语录'**
  String get featureChooseQuotesShownWhileLoading;

  /// No description provided for @featureServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'服务器状态'**
  String get featureServerStatus;

  /// No description provided for @featureViewMaimaiServiceStatus.
  ///
  /// In zh, this message translates to:
  /// **'查看舞萌服务状态'**
  String get featureViewMaimaiServiceStatus;

  /// No description provided for @featureExportLogs.
  ///
  /// In zh, this message translates to:
  /// **'打印日志'**
  String get featureExportLogs;

  /// No description provided for @featureExportRecentLogsForTroubleshooting.
  ///
  /// In zh, this message translates to:
  /// **'导出最近运行日志，方便排查问题'**
  String get featureExportRecentLogsForTroubleshooting;

  /// No description provided for @featureRecentComments.
  ///
  /// In zh, this message translates to:
  /// **'最近评论'**
  String get featureRecentComments;

  /// No description provided for @featureViewRecentCommunityComments.
  ///
  /// In zh, this message translates to:
  /// **'查看社区最近评论'**
  String get featureViewRecentCommunityComments;

  /// No description provided for @featureRecentRatings.
  ///
  /// In zh, this message translates to:
  /// **'最近评分'**
  String get featureRecentRatings;

  /// No description provided for @featureViewRecentCommunityRatings.
  ///
  /// In zh, this message translates to:
  /// **'查看社区最近评分'**
  String get featureViewRecentCommunityRatings;

  /// No description provided for @featureCheckForUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get featureCheckForUpdates;

  /// No description provided for @featureCheckForANewerAppVersion.
  ///
  /// In zh, this message translates to:
  /// **'检查应用是否有新版本'**
  String get featureCheckForANewerAppVersion;

  /// No description provided for @featureAboutTheApp.
  ///
  /// In zh, this message translates to:
  /// **'关于 APP'**
  String get featureAboutTheApp;

  /// No description provided for @featureViewProjectAndVersionInformation.
  ///
  /// In zh, this message translates to:
  /// **'了解项目与版本信息'**
  String get featureViewProjectAndVersionInformation;

  /// No description provided for @featureOfficialWebsite.
  ///
  /// In zh, this message translates to:
  /// **'访问官方网站'**
  String get featureOfficialWebsite;

  /// No description provided for @featureVisitTheProjectAtChiffonmaiCloud.
  ///
  /// In zh, this message translates to:
  /// **'前往 chiffonmai.cloud 查看项目主页'**
  String get featureVisitTheProjectAtChiffonmaiCloud;

  /// No description provided for @featureRelatedProjects.
  ///
  /// In zh, this message translates to:
  /// **'查看友情链接'**
  String get featureRelatedProjects;

  /// No description provided for @featureDiscoverCommunityProjects.
  ///
  /// In zh, this message translates to:
  /// **'发现同好项目'**
  String get featureDiscoverCommunityProjects;

  /// No description provided for @featureReportAnIssue.
  ///
  /// In zh, this message translates to:
  /// **'问题反馈'**
  String get featureReportAnIssue;

  /// No description provided for @featureReportProblemsYouEncounter.
  ///
  /// In zh, this message translates to:
  /// **'反馈使用中遇到的问题'**
  String get featureReportProblemsYouEncounter;

  /// No description provided for @featureJoinTheQQGroup.
  ///
  /// In zh, this message translates to:
  /// **'加入 QQ 群'**
  String get featureJoinTheQQGroup;

  /// No description provided for @featureOpenTheOfficialCommunityGroup.
  ///
  /// In zh, this message translates to:
  /// **'一键跳转官方交流群'**
  String get featureOpenTheOfficialCommunityGroup;

  /// No description provided for @featureSurvey.
  ///
  /// In zh, this message translates to:
  /// **'问卷调查'**
  String get featureSurvey;

  /// No description provided for @featureHelpImproveChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'助力 ChiffonMai 更上一层楼'**
  String get featureHelpImproveChiffonMai;

  /// No description provided for @featureSupportDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'支持开发者'**
  String get featureSupportDevelopment;

  /// No description provided for @featureSupportContinuedProjectUpdates.
  ///
  /// In zh, this message translates to:
  /// **'支持项目持续更新'**
  String get featureSupportContinuedProjectUpdates;

  /// No description provided for @featureLibrary.
  ///
  /// In zh, this message translates to:
  /// **'曲库'**
  String get featureLibrary;

  /// No description provided for @featureSearchSongsBrowseInformationAndRecognizeImages.
  ///
  /// In zh, this message translates to:
  /// **'搜索乐曲、浏览资料与图像识别'**
  String get featureSearchSongsBrowseInformationAndRecognizeImages;

  /// No description provided for @featureSiteWideTotalFittedRatingRanking.
  ///
  /// In zh, this message translates to:
  /// **'拟合总 Rating 站内排行'**
  String get featureSiteWideTotalFittedRatingRanking;

  /// No description provided for @featureRankAllScoresByAverageDXScore.
  ///
  /// In zh, this message translates to:
  /// **'按全量成绩的平均DX分数达成率排名'**
  String get featureRankAllScoresByAverageDXScore;

  /// No description provided for @featureScores.
  ///
  /// In zh, this message translates to:
  /// **'成绩'**
  String get featureScores;

  /// No description provided for @featureBrowseScoresImprovementsRankingsAndProgress.
  ///
  /// In zh, this message translates to:
  /// **'查成绩、看提升、比排名与追踪进度'**
  String get featureBrowseScoresImprovementsRankingsAndProgress;

  /// No description provided for @featureAllFeatures.
  ///
  /// In zh, this message translates to:
  /// **'全部功能'**
  String get featureAllFeatures;

  /// No description provided for @featureStarAFeatureToAddItTo.
  ///
  /// In zh, this message translates to:
  /// **'点星标加入首页「常用」'**
  String get featureStarAFeatureToAddItTo;

  /// No description provided for @featureChallengeYourMelodyMemoryWithReversedClips.
  ///
  /// In zh, this message translates to:
  /// **'听倒放的歌曲片段，挑战旋律记忆'**
  String get featureChallengeYourMelodyMemoryWithReversedClips;

  /// No description provided for @featureChangeBothSpeedAndPitchForA.
  ///
  /// In zh, this message translates to:
  /// **'速度与音高一起变化，换个耳朵听歌'**
  String get featureChangeBothSpeedAndPitchForA;

  /// No description provided for @featureSyncScoresOnADailySchedule.
  ///
  /// In zh, this message translates to:
  /// **'每天定时同步成绩，解放双手'**
  String get featureSyncScoresOnADailySchedule;

  /// No description provided for @featureMe.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get featureMe;

  /// No description provided for @featureAccountsSyncBackupAndAppPreferences.
  ///
  /// In zh, this message translates to:
  /// **'账号、同步、备份与应用偏好'**
  String get featureAccountsSyncBackupAndAppPreferences;

  /// No description provided for @featureSharedRulesAndSettingsForEachMode.
  ///
  /// In zh, this message translates to:
  /// **'共用规则与各模式的专属设置'**
  String get featureSharedRulesAndSettingsForEachMode;

  /// No description provided for @featureHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get featureHome;

  /// No description provided for @featurePlay.
  ///
  /// In zh, this message translates to:
  /// **'游玩'**
  String get featurePlay;

  /// No description provided for @featureArcade.
  ///
  /// In zh, this message translates to:
  /// **'出勤'**
  String get featureArcade;

  /// No description provided for @featureCasual.
  ///
  /// In zh, this message translates to:
  /// **'休闲'**
  String get featureCasual;

  /// No description provided for @featureChooseSongsPlanPracticeAndFindArcades.
  ///
  /// In zh, this message translates to:
  /// **'选曲、安排练习与查找机厅'**
  String get featureChooseSongsPlanPracticeAndFindArcades;

  /// No description provided for @featureSongQuizzesMusicAndCustomCharts.
  ///
  /// In zh, this message translates to:
  /// **'猜歌挑战、听歌与自定义谱面播放'**
  String get featureSongQuizzesMusicAndCustomCharts;

  /// No description provided for @featureSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get featureSystem;

  /// No description provided for @featureBuildingCoverIndex.
  ///
  /// In zh, this message translates to:
  /// **'正在构建曲绘索引…'**
  String get featureBuildingCoverIndex;

  /// No description provided for @featureAnotherTaskIsRunningPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'正在处理其它任务，请稍候'**
  String get featureAnotherTaskIsRunningPleaseWait;

  /// No description provided for @featureLeaderboards.
  ///
  /// In zh, this message translates to:
  /// **'排行榜'**
  String get featureLeaderboards;

  /// No description provided for @featureTotalFittedRating.
  ///
  /// In zh, this message translates to:
  /// **'拟合总 Rating'**
  String get featureTotalFittedRating;

  /// No description provided for @featureAverageAchievement.
  ///
  /// In zh, this message translates to:
  /// **'平均达成率'**
  String get featureAverageAchievement;

  /// No description provided for @featureAverageDXScoreRate.
  ///
  /// In zh, this message translates to:
  /// **'平均DX分数达成率'**
  String get featureAverageDXScoreRate;

  /// No description provided for @featureSpecial.
  ///
  /// In zh, this message translates to:
  /// **'特殊'**
  String get featureSpecial;

  /// No description provided for @featureCalculators2.
  ///
  /// In zh, this message translates to:
  /// **'计算工具'**
  String get featureCalculators2;

  /// No description provided for @featureFindScoresTitleConstantOrSongID.
  ///
  /// In zh, this message translates to:
  /// **'查成绩：曲名、定数、曲目 ID'**
  String get featureFindScoresTitleConstantOrSongID;

  /// No description provided for @featureRefreshDataToSeeYourBest35And.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据后这里会显示 Best35 与 Best15'**
  String get featureRefreshDataToSeeYourBest35And;

  /// No description provided for @featureFitted.
  ///
  /// In zh, this message translates to:
  /// **'拟合'**
  String get featureFitted;

  /// No description provided for @featureCustom.
  ///
  /// In zh, this message translates to:
  /// **'个性化'**
  String get featureCustom;

  /// No description provided for @featureCustomFitted.
  ///
  /// In zh, this message translates to:
  /// **'个性化拟合'**
  String get featureCustomFitted;

  /// No description provided for @featureIdeal.
  ///
  /// In zh, this message translates to:
  /// **'理想'**
  String get featureIdeal;

  /// No description provided for @featureCreate.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get featureCreate;

  /// No description provided for @featureScoreImprovements.
  ///
  /// In zh, this message translates to:
  /// **'成绩提升'**
  String get featureScoreImprovements;

  /// No description provided for @featureRecordsBeginAfterSyncing.
  ///
  /// In zh, this message translates to:
  /// **'同步后开始记录'**
  String get featureRecordsBeginAfterSyncing;

  /// No description provided for @featureDailyHistory.
  ///
  /// In zh, this message translates to:
  /// **'按日回顾'**
  String get featureDailyHistory;

  /// No description provided for @featureThemeAndNavigationSettings.
  ///
  /// In zh, this message translates to:
  /// **'主题与导航设置'**
  String get featureThemeAndNavigationSettings;

  /// No description provided for @featureSyncDataInMe.
  ///
  /// In zh, this message translates to:
  /// **'前往「我的」同步数据'**
  String get featureSyncDataInMe;

  /// No description provided for @featureNoMatchingFeatures.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的功能'**
  String get featureNoMatchingFeatures;

  /// No description provided for @featureNoFeaturesFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的功能'**
  String get featureNoFeaturesFound;

  /// No description provided for @featureFavorites.
  ///
  /// In zh, this message translates to:
  /// **'常用'**
  String get featureFavorites;

  /// No description provided for @featureDragToReorderTapOrDragTo.
  ///
  /// In zh, this message translates to:
  /// **'拖动图标调整顺序；点叉号或拖到删除区域可移除收藏'**
  String get featureDragToReorderTapOrDragTo;

  /// No description provided for @featureStarFeaturesInAnyCategoryToShow.
  ///
  /// In zh, this message translates to:
  /// **'点击分类中的 ⭐ 星标即可收藏功能，收藏后直接显示在此处'**
  String get featureStarFeaturesInAnyCategoryToShow;

  /// No description provided for @featureFinishEditingFavorites.
  ///
  /// In zh, this message translates to:
  /// **'完成收藏功能编辑'**
  String get featureFinishEditingFavorites;

  /// No description provided for @featureEditFavorites.
  ///
  /// In zh, this message translates to:
  /// **'编辑收藏功能'**
  String get featureEditFavorites;

  /// No description provided for @featureDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get featureDone;

  /// No description provided for @featureEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get featureEdit;

  /// No description provided for @featureReleaseToRemove.
  ///
  /// In zh, this message translates to:
  /// **'松手移除收藏'**
  String get featureReleaseToRemove;

  /// No description provided for @featureDragHereToRemove.
  ///
  /// In zh, this message translates to:
  /// **'拖到这里移除收藏'**
  String get featureDragHereToRemove;

  /// No description provided for @featureRemoveFavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get featureRemoveFavorite;

  /// No description provided for @featureFavoriteFeature.
  ///
  /// In zh, this message translates to:
  /// **'收藏功能'**
  String get featureFavoriteFeature;

  /// No description provided for @featureSearchFeaturesOrKeywords.
  ///
  /// In zh, this message translates to:
  /// **'搜索功能名称或关键词'**
  String get featureSearchFeaturesOrKeywords;

  /// No description provided for @featureSearchSongTitlesAliasesOrIDs.
  ///
  /// In zh, this message translates to:
  /// **'搜索歌名、别名、歌曲 ID…'**
  String get featureSearchSongTitlesAliasesOrIDs;

  /// No description provided for @featureSearchFeaturesOrSongs.
  ///
  /// In zh, this message translates to:
  /// **'搜索功能或歌曲'**
  String get featureSearchFeaturesOrSongs;

  /// No description provided for @featureSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜点什么...'**
  String get featureSearch;

  /// No description provided for @featureClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get featureClear;

  /// No description provided for @featureSearch2.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get featureSearch2;

  /// No description provided for @featureCloseSearch.
  ///
  /// In zh, this message translates to:
  /// **'收起搜索'**
  String get featureCloseSearch;

  /// No description provided for @featureClearInput.
  ///
  /// In zh, this message translates to:
  /// **'清除输入'**
  String get featureClearInput;

  /// No description provided for @featureClearSearch.
  ///
  /// In zh, this message translates to:
  /// **'清空搜索'**
  String get featureClearSearch;

  /// No description provided for @featureSearchHistory.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史'**
  String get featureSearchHistory;

  /// No description provided for @featureLoadingSearchHistory.
  ///
  /// In zh, this message translates to:
  /// **'正在读取搜索历史…'**
  String get featureLoadingSearchHistory;

  /// No description provided for @featureNoSearchHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无搜索历史'**
  String get featureNoSearchHistory;

  /// No description provided for @featureDeleteThisSearchEntry.
  ///
  /// In zh, this message translates to:
  /// **'删除这条搜索历史'**
  String get featureDeleteThisSearchEntry;

  /// No description provided for @featureCouldNotUpdateSearchHistoryTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史更新失败，请重试'**
  String get featureCouldNotUpdateSearchHistoryTryAgain;

  /// No description provided for @featureSearchSongTitlesOnly.
  ///
  /// In zh, this message translates to:
  /// **'只按歌名搜索'**
  String get featureSearchSongTitlesOnly;

  /// No description provided for @featureTitleBPMCharterArtistAliasID.
  ///
  /// In zh, this message translates to:
  /// **'歌名/BPM/谱师/曲师/别名/歌曲ID/...'**
  String get featureTitleBPMCharterArtistAliasID;

  /// No description provided for @featureTitleAliasIDArtistCharterBPM.
  ///
  /// In zh, this message translates to:
  /// **'曲名、别名、ID、曲师、谱师、BPM'**
  String get featureTitleAliasIDArtistCharterBPM;

  /// No description provided for @featureEnterAKeywordToFindSongs.
  ///
  /// In zh, this message translates to:
  /// **'输入关键词搜索歌曲'**
  String get featureEnterAKeywordToFindSongs;

  /// No description provided for @featureNoMatchingSongs.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的歌曲'**
  String get featureNoMatchingSongs;

  /// No description provided for @featureSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲'**
  String get featureSongs;

  /// No description provided for @featureThemeSettings.
  ///
  /// In zh, this message translates to:
  /// **'主题设置'**
  String get featureThemeSettings;

  /// No description provided for @featureMoreSettings.
  ///
  /// In zh, this message translates to:
  /// **'更多设置'**
  String get featureMoreSettings;

  /// No description provided for @featureCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get featureCancel;

  /// No description provided for @featureOK.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get featureOK;

  /// No description provided for @featureClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get featureClose;

  /// No description provided for @featureGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get featureGotIt;

  /// No description provided for @featureNotice.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get featureNotice;

  /// No description provided for @featureOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get featureOperationFailed;

  /// No description provided for @featureUnknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get featureUnknownError;

  /// No description provided for @featureDialog.
  ///
  /// In zh, this message translates to:
  /// **'对话框'**
  String get featureDialog;

  /// No description provided for @featureNoDetailsAvailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无详情'**
  String get featureNoDetailsAvailable;

  /// No description provided for @featureUnknown.
  ///
  /// In zh, this message translates to:
  /// **'暂时未知'**
  String get featureUnknown;

  /// No description provided for @featureOff.
  ///
  /// In zh, this message translates to:
  /// **'未开启'**
  String get featureOff;

  /// No description provided for @featureWaitingForUpstream.
  ///
  /// In zh, this message translates to:
  /// **'等待上游'**
  String get featureWaitingForUpstream;

  /// No description provided for @featureSyncing.
  ///
  /// In zh, this message translates to:
  /// **'同步中'**
  String get featureSyncing;

  /// No description provided for @featureOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get featureOn;

  /// No description provided for @featureLastRunIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'上次未完成'**
  String get featureLastRunIncomplete;

  /// No description provided for @featureUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'已是最新'**
  String get featureUpToDate;

  /// No description provided for @featureLoading.
  ///
  /// In zh, this message translates to:
  /// **'读取中…'**
  String get featureLoading;

  /// No description provided for @featureCheckingSyncStatus.
  ///
  /// In zh, this message translates to:
  /// **'正在获取同步状态'**
  String get featureCheckingSyncStatus;

  /// No description provided for @featureStatusUnknown.
  ///
  /// In zh, this message translates to:
  /// **'状态未知'**
  String get featureStatusUnknown;

  /// No description provided for @featureTemporarilyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时读取不到'**
  String get featureTemporarilyUnavailable;

  /// No description provided for @featureTapToSetUp.
  ///
  /// In zh, this message translates to:
  /// **'点这里设置'**
  String get featureTapToSetUp;

  /// No description provided for @featureUnavailableRetryingShortly.
  ///
  /// In zh, this message translates to:
  /// **'暂时读取不到，稍后自动重试'**
  String get featureUnavailableRetryingShortly;

  /// No description provided for @featureCheckingServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'正在获取服务器状态'**
  String get featureCheckingServerStatus;

  /// No description provided for @featureSyncing2.
  ///
  /// In zh, this message translates to:
  /// **'正在同步…'**
  String get featureSyncing2;

  /// No description provided for @featureReadingCabinetScores.
  ///
  /// In zh, this message translates to:
  /// **'读取机台成绩…'**
  String get featureReadingCabinetScores;

  /// No description provided for @featureCheckingForUpdates.
  ///
  /// In zh, this message translates to:
  /// **'正在检查更新...'**
  String get featureCheckingForUpdates;

  /// No description provided for @featureCouldNotCheckForUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败'**
  String get featureCouldNotCheckForUpdates;

  /// No description provided for @featureCheckYourConnectionAndTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'请检查网络连接后重试'**
  String get featureCheckYourConnectionAndTryAgain;

  /// No description provided for @featureCopyDownloadLink.
  ///
  /// In zh, this message translates to:
  /// **'复制下载链接'**
  String get featureCopyDownloadLink;

  /// No description provided for @featureDownloadLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'下载链接已复制到剪贴板'**
  String get featureDownloadLinkCopied;

  /// No description provided for @featureUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get featureUpdateAvailable;

  /// No description provided for @featureNewVersion.
  ///
  /// In zh, this message translates to:
  /// **'新版本'**
  String get featureNewVersion;

  /// No description provided for @featureSignedInForOCRAndMaimaiScore.
  ///
  /// In zh, this message translates to:
  /// **'已登录，可用于 OCR 与 maimai Score Hub 功能'**
  String get featureSignedInForOCRAndMaimaiScore;

  /// No description provided for @featureSignedInOCRAndMaimaiScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'登录成功，可用于 OCR 与 maimai Score Hub 功能'**
  String get featureSignedInOCRAndMaimaiScoreHub;

  /// No description provided for @featureRainbow.
  ///
  /// In zh, this message translates to:
  /// **'彩'**
  String get featureRainbow;

  /// No description provided for @featurePlatinum.
  ///
  /// In zh, this message translates to:
  /// **'白金'**
  String get featurePlatinum;

  /// No description provided for @featureGold.
  ///
  /// In zh, this message translates to:
  /// **'金'**
  String get featureGold;

  /// No description provided for @featureSilver.
  ///
  /// In zh, this message translates to:
  /// **'银'**
  String get featureSilver;

  /// No description provided for @featureBronze.
  ///
  /// In zh, this message translates to:
  /// **'铜'**
  String get featureBronze;

  /// No description provided for @featurePurple.
  ///
  /// In zh, this message translates to:
  /// **'紫'**
  String get featurePurple;

  /// No description provided for @featureRed.
  ///
  /// In zh, this message translates to:
  /// **'红'**
  String get featureRed;

  /// No description provided for @featureOrange.
  ///
  /// In zh, this message translates to:
  /// **'橙'**
  String get featureOrange;

  /// No description provided for @featureGreen.
  ///
  /// In zh, this message translates to:
  /// **'绿'**
  String get featureGreen;

  /// No description provided for @featureBlue.
  ///
  /// In zh, this message translates to:
  /// **'蓝'**
  String get featureBlue;

  /// No description provided for @featureWhite.
  ///
  /// In zh, this message translates to:
  /// **'白'**
  String get featureWhite;

  /// No description provided for @homeWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来，{name}'**
  String homeWelcome(String name);

  /// No description provided for @homeSwitchSource.
  ///
  /// In zh, this message translates to:
  /// **'切换数据源，当前 {source}'**
  String homeSwitchSource(String source);

  /// No description provided for @homeTotalRatingAction.
  ///
  /// In zh, this message translates to:
  /// **'总 Rating {rating}，打开高级刷新'**
  String homeTotalRatingAction(String rating);

  /// No description provided for @homeFeatureCount.
  ///
  /// In zh, this message translates to:
  /// **'功能（{count}）'**
  String homeFeatureCount(int count);

  /// No description provided for @homeAllFeatureCount.
  ///
  /// In zh, this message translates to:
  /// **'全部功能（{count}）'**
  String homeAllFeatureCount(int count);

  /// No description provided for @homeResultCount.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果（{count}）'**
  String homeResultCount(int count);

  /// No description provided for @homeSongCount.
  ///
  /// In zh, this message translates to:
  /// **'歌曲（{count}）'**
  String homeSongCount(int count);

  /// No description provided for @homeSongCountLimited.
  ///
  /// In zh, this message translates to:
  /// **'歌曲（{count}，显示前 {limit} 首）'**
  String homeSongCountLimited(int count, int limit);

  /// No description provided for @homeRemoveFavorite.
  ///
  /// In zh, this message translates to:
  /// **'移除收藏：{name}'**
  String homeRemoveFavorite(String name);

  /// No description provided for @hubRatingRecords.
  ///
  /// In zh, this message translates to:
  /// **'最新 {rating} · 共 {count} 次记录'**
  String hubRatingRecords(int rating, int count);

  /// No description provided for @hubFeaturesCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个功能'**
  String hubFeaturesCount(int count);

  /// No description provided for @hubCoverIndexFailed.
  ///
  /// In zh, this message translates to:
  /// **'曲绘索引构建失败：{error}'**
  String hubCoverIndexFailed(String error);

  /// No description provided for @hubOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开失败：{error}'**
  String hubOpenFailed(String error);

  /// No description provided for @hubLinkUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接：{name}'**
  String hubLinkUnavailable(String name);

  /// No description provided for @hubJoinGroup.
  ///
  /// In zh, this message translates to:
  /// **'一键跳转官方交流群（{number}）'**
  String hubJoinGroup(String number);

  /// No description provided for @hubUpdateReleased.
  ///
  /// In zh, this message translates to:
  /// **'{version} 已发布，点击查看更新内容'**
  String hubUpdateReleased(String version);

  /// No description provided for @homeSyncSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'提交 {count} 条'**
  String homeSyncSubmitted(int count);

  /// No description provided for @homeSyncIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个未完成'**
  String homeSyncIncomplete(int count);

  /// No description provided for @homeSyncSources.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个数据源'**
  String homeSyncSources(int count);

  /// No description provided for @homeSyncSourcesWaiting.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个数据源 · 等待执行'**
  String homeSyncSourcesWaiting(int count);

  /// No description provided for @homeSyncUpload.
  ///
  /// In zh, this message translates to:
  /// **'上传 {completed}/{total} 条'**
  String homeSyncUpload(int completed, int total);

  /// No description provided for @homeSyncReadPage.
  ///
  /// In zh, this message translates to:
  /// **'读取机台成绩 · 第 {page} 页'**
  String homeSyncReadPage(int page);

  /// No description provided for @homeServerHealthy.
  ///
  /// In zh, this message translates to:
  /// **'{healthy}/{total} 正常'**
  String homeServerHealthy(int healthy, int total);

  /// No description provided for @homeTodayAt.
  ///
  /// In zh, this message translates to:
  /// **'今天 {time}'**
  String homeTodayAt(String time);

  /// No description provided for @homeInitWorking.
  ///
  /// In zh, this message translates to:
  /// **'正在初始化应用数据，请稍候...'**
  String get homeInitWorking;

  /// No description provided for @homeInitFinished.
  ///
  /// In zh, this message translates to:
  /// **'数据初始化完成！总耗时 {duration}'**
  String homeInitFinished(String duration);

  /// No description provided for @homeInitFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始化失败：{error}\n建议检查网络连接后重启应用'**
  String homeInitFailed(String error);

  /// No description provided for @featureHubSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'已登录，可直接使用 OCR；点击可重新登录'**
  String get featureHubSignedIn;

  /// No description provided for @featureFish.
  ///
  /// In zh, this message translates to:
  /// **'水鱼'**
  String get featureFish;

  /// No description provided for @featureLxns.
  ///
  /// In zh, this message translates to:
  /// **'落雪'**
  String get featureLxns;

  /// No description provided for @featureServerNormal.
  ///
  /// In zh, this message translates to:
  /// **'服务正常'**
  String get featureServerNormal;

  /// No description provided for @featureServerAbnormal.
  ///
  /// In zh, this message translates to:
  /// **'服务异常'**
  String get featureServerAbnormal;

  /// No description provided for @featureTapCommunityAppearance.
  ///
  /// In zh, this message translates to:
  /// **'点击选择社区装扮'**
  String get featureTapCommunityAppearance;

  /// No description provided for @featureManageAccountBelow.
  ///
  /// In zh, this message translates to:
  /// **'可按需在下方管理账号数据'**
  String get featureManageAccountBelow;

  /// No description provided for @featureCollapseProfile.
  ///
  /// In zh, this message translates to:
  /// **'切换为简略信息'**
  String get featureCollapseProfile;

  /// No description provided for @featureExpandProfile.
  ///
  /// In zh, this message translates to:
  /// **'展开详细信息'**
  String get featureExpandProfile;

  /// No description provided for @featureSynced.
  ///
  /// In zh, this message translates to:
  /// **'已同步'**
  String get featureSynced;

  /// No description provided for @featureSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败'**
  String get featureSyncFailed;

  /// No description provided for @featurePendingSync.
  ///
  /// In zh, this message translates to:
  /// **'待同步'**
  String get featurePendingSync;

  /// No description provided for @featureLocalOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅本机'**
  String get featureLocalOnly;

  /// No description provided for @featureLoadingGrowth.
  ///
  /// In zh, this message translates to:
  /// **'正在读取成长记录…'**
  String get featureLoadingGrowth;

  /// No description provided for @featureGrowthRules.
  ///
  /// In zh, this message translates to:
  /// **'成长规则'**
  String get featureGrowthRules;

  /// No description provided for @featureSyncProgress.
  ///
  /// In zh, this message translates to:
  /// **'同步进行中，请稍候…'**
  String get featureSyncProgress;

  /// No description provided for @featurePreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备…'**
  String get featurePreparing;

  /// No description provided for @homeStreak.
  ///
  /// In zh, this message translates to:
  /// **'连续签到 {days} 天'**
  String homeStreak(int days);

  /// No description provided for @homeTrophyId.
  ///
  /// In zh, this message translates to:
  /// **'称号 #{id}'**
  String homeTrophyId(String id);

  /// No description provided for @growthRulesBody.
  ///
  /// In zh, this message translates to:
  /// **'按北京时间，每天首次启动 App 时检查签到；本机登录或验证账号成功后，也会为当天尚未签到的账号自动签到。\n\n首日 20 经验；连续签到每天多 5 点，第 7 天起每天 50 点。中断后从 20 点重新开始，累计经验保留。\n\nLv.1 升级需 100 经验，之后每级多需 20 点。\n\n成长记录跟随对应数据源账号，同一账号同日只能领取一次。'**
  String get growthRulesBody;

  /// No description provided for @hubOpenRelatedProject.
  ///
  /// In zh, this message translates to:
  /// **'打开友情链接：{name}'**
  String hubOpenRelatedProject(String name);

  /// No description provided for @hubBusyTask.
  ///
  /// In zh, this message translates to:
  /// **'{task}正在进行中，不能使用本功能'**
  String hubBusyTask(String task);

  /// No description provided for @flowEnterYourAWMCNETTokenFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先输入 AWMC NET Token'**
  String get flowEnterYourAWMCNETTokenFirst;

  /// No description provided for @flowCouldNotSaveYourPersonalKeyTry.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 保存失败，请重试'**
  String get flowCouldNotSaveYourPersonalKeyTry;

  /// No description provided for @flowCouldNotDisableAutoSyncYourKey.
  ///
  /// In zh, this message translates to:
  /// **'无法关闭对应自动同步，个人 key 未清除，请重试'**
  String get flowCouldNotDisableAutoSyncYourKey;

  /// No description provided for @flowAWMCNETScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 成绩导入 Token'**
  String get flowAWMCNETScoreImportToken;

  /// No description provided for @flowSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get flowSet;

  /// No description provided for @flowNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get flowNotSet;

  /// No description provided for @flowVisit.
  ///
  /// In zh, this message translates to:
  /// **'访问'**
  String get flowVisit;

  /// No description provided for @flowToGenerateOrRotateYourTokenAt.
  ///
  /// In zh, this message translates to:
  /// **'，在页面底部生成或轮换Token。'**
  String get flowToGenerateOrRotateYourTokenAt;

  /// No description provided for @flowPasteYourAWMCNETScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'在此粘贴 AWMC NET 成绩导入 Token...'**
  String get flowPasteYourAWMCNETScoreImportToken;

  /// No description provided for @flowClearToken.
  ///
  /// In zh, this message translates to:
  /// **'清除 Token'**
  String get flowClearToken;

  /// No description provided for @flowSignOutFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'登出失败：{p0}'**
  String flowSignOutFailedP0(String p0);

  /// No description provided for @flowSignedOutOfDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'已登出水鱼账号'**
  String get flowSignedOutOfDivingFish;

  /// No description provided for @flowLinkDivingFishAccount.
  ///
  /// In zh, this message translates to:
  /// **'绑定水鱼账号'**
  String get flowLinkDivingFishAccount;

  /// No description provided for @flowRequestAndOpenALoginQRCode.
  ///
  /// In zh, this message translates to:
  /// **'在舞萌|中二公众号请求并打开二维码，扫描后将字符串粘贴到下方：'**
  String get flowRequestAndOpenALoginQRCode;

  /// No description provided for @flowMaimaiDXCHUNITHMLoginQRSGWCMAID.
  ///
  /// In zh, this message translates to:
  /// **'舞萌DX | 中二节奏 登入二维码(SGWCMAID...)'**
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID;

  /// No description provided for @flowJoinLeaderboards.
  ///
  /// In zh, this message translates to:
  /// **'参与排行榜'**
  String get flowJoinLeaderboards;

  /// No description provided for @flowRankingDivingFishMasked.
  ///
  /// In zh, this message translates to:
  /// **'你的水鱼账号开启了「对非网页查询的成绩使用掩码」，App 读到的水鱼成绩不准确，暂不能用水鱼数据参与排行榜。可在水鱼查分器网页的个人资料里关闭后再试。'**
  String get flowRankingDivingFishMasked;

  /// No description provided for @songScoreIllegalWarning.
  ///
  /// In zh, this message translates to:
  /// **'这条成绩数据异常：{p0}，不会上传到排行榜。'**
  String songScoreIllegalWarning(String p0);

  /// No description provided for @songScoreIllegalAchievement.
  ///
  /// In zh, this message translates to:
  /// **'达成率超过上限 {p0}%'**
  String songScoreIllegalAchievement(String p0);

  /// No description provided for @songScoreIllegalDx.
  ///
  /// In zh, this message translates to:
  /// **'DX 分数超过谱面上限 {p0}'**
  String songScoreIllegalDx(String p0);

  /// No description provided for @songScoreIllegalUnreleased.
  ///
  /// In zh, this message translates to:
  /// **'谱面尚未在国服上线（{p0}）'**
  String songScoreIllegalUnreleased(String p0);

  /// No description provided for @flowDXScoreMAXOverP0.
  ///
  /// In zh, this message translates to:
  /// **'DX分数（MAX +{p0}）'**
  String flowDXScoreMAXOverP0(String p0);

  /// No description provided for @rankingUploadIncompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'排行榜上传未完成'**
  String get rankingUploadIncompleteTitle;

  /// No description provided for @rankingUploadIncompleteLead.
  ///
  /// In zh, this message translates to:
  /// **'成绩已刷新并保存，只是这次没有更新排行榜。'**
  String get rankingUploadIncompleteLead;

  /// No description provided for @rankingGuardFrozen.
  ///
  /// In zh, this message translates to:
  /// **'排行榜上传资格已暂停，正在人工审核。审核期间你在排行榜上的数据会暂时隐藏。'**
  String get rankingGuardFrozen;

  /// No description provided for @rankingGuardBlacklisted.
  ///
  /// In zh, this message translates to:
  /// **'该账号已被禁止参与排行榜。'**
  String get rankingGuardBlacklisted;

  /// No description provided for @rankingGuardUpgradeRequired.
  ///
  /// In zh, this message translates to:
  /// **'请更新到最新版本后再上传排行榜。'**
  String get rankingGuardUpgradeRequired;

  /// No description provided for @rankingGuardRejected.
  ///
  /// In zh, this message translates to:
  /// **'本次排行榜上传已全部拒绝：{p0}。剩余 {p1} 次警告机会，用完后上传资格会被暂停并转人工审核。'**
  String rankingGuardRejected(String p0, String p1);

  /// No description provided for @rankingGuardReasonRating.
  ///
  /// In zh, this message translates to:
  /// **'Rating 超过当前理论值'**
  String get rankingGuardReasonRating;

  /// No description provided for @rankingGuardReasonUnknownSong.
  ///
  /// In zh, this message translates to:
  /// **'包含曲库中不存在的歌曲（{p0}）'**
  String rankingGuardReasonUnknownSong(String p0);

  /// No description provided for @rankingGuardReasonUnreleased.
  ///
  /// In zh, this message translates to:
  /// **'包含尚未上线的歌曲（{p0}）'**
  String rankingGuardReasonUnreleased(String p0);

  /// No description provided for @rankingGuardReasonLevel.
  ///
  /// In zh, this message translates to:
  /// **'难度不存在（{p0}）'**
  String rankingGuardReasonLevel(String p0);

  /// No description provided for @rankingGuardReasonAchievement.
  ///
  /// In zh, this message translates to:
  /// **'达成率超出上限（{p0}）'**
  String rankingGuardReasonAchievement(String p0);

  /// No description provided for @rankingGuardReasonDx.
  ///
  /// In zh, this message translates to:
  /// **'DX 分数超出谱面上限（{p0}）'**
  String rankingGuardReasonDx(String p0);

  /// No description provided for @rankingGuardReasonInvalid.
  ///
  /// In zh, this message translates to:
  /// **'成绩数据无效'**
  String get rankingGuardReasonInvalid;

  /// No description provided for @flowShowNicknameOtherwiseShownAsAnonymous.
  ///
  /// In zh, this message translates to:
  /// **'展示昵称（不勾选则显示为匿名用户）'**
  String get flowShowNicknameOtherwiseShownAsAnonymous;

  /// No description provided for @flowScoresFetchedLinkYourDivingFishAccount.
  ///
  /// In zh, this message translates to:
  /// **'成绩已抓取成功！但要推送到水鱼，需要先绑定你的水鱼账号：'**
  String get flowScoresFetchedLinkYourDivingFishAccount;

  /// No description provided for @flowDivingFishUsername.
  ///
  /// In zh, this message translates to:
  /// **'水鱼用户名'**
  String get flowDivingFishUsername;

  /// No description provided for @flowEnterDivingFishUsername.
  ///
  /// In zh, this message translates to:
  /// **'输入 Diving-Fish 用户名'**
  String get flowEnterDivingFishUsername;

  /// No description provided for @flowDivingFishPassword.
  ///
  /// In zh, this message translates to:
  /// **'水鱼密码'**
  String get flowDivingFishPassword;

  /// No description provided for @flowEnterDivingFishPassword.
  ///
  /// In zh, this message translates to:
  /// **'输入 Diving-Fish 密码'**
  String get flowEnterDivingFishPassword;

  /// No description provided for @flowSyncInProgressPleaseWaitAndAvoid.
  ///
  /// In zh, this message translates to:
  /// **'同步进行中，请耐心等待，不要进行其他操作'**
  String get flowSyncInProgressPleaseWaitAndAvoid;

  /// No description provided for @flowScoresSyncedViewThemOnDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'成绩已同步！可前往水鱼查看'**
  String get flowScoresSyncedViewThemOnDivingFish;

  /// No description provided for @flowOKP0.
  ///
  /// In zh, this message translates to:
  /// **'确定 ({p0})'**
  String flowOKP0(String p0);

  /// No description provided for @flowSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get flowSkip;

  /// No description provided for @flowLinking.
  ///
  /// In zh, this message translates to:
  /// **'绑定中...'**
  String get flowLinking;

  /// No description provided for @flowLinkAndSync.
  ///
  /// In zh, this message translates to:
  /// **'绑定并同步'**
  String get flowLinkAndSync;

  /// No description provided for @flowDoneP0ScoresSyncedAndLocalData.
  ///
  /// In zh, this message translates to:
  /// **'全部完成！{p0} 条成绩已同步，本地数据已刷新'**
  String flowDoneP0ScoresSyncedAndLocalData(String p0);

  /// No description provided for @flowStartSync.
  ///
  /// In zh, this message translates to:
  /// **'开始同步'**
  String get flowStartSync;

  /// No description provided for @flowPasteTheMaimaiCHUNITHMLoginQRString.
  ///
  /// In zh, this message translates to:
  /// **'请先粘贴舞萌|中二登入二维码字符串'**
  String get flowPasteTheMaimaiCHUNITHMLoginQRString;

  /// No description provided for @flowSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'已登录'**
  String get flowSignedIn;

  /// No description provided for @flowEnterYourDivingFishCredentialsToObtain.
  ///
  /// In zh, this message translates to:
  /// **'输入你的 Diving-Fish 水鱼账号密码以获取 ImportToken：'**
  String get flowEnterYourDivingFishCredentialsToObtain;

  /// No description provided for @flowUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get flowUsername;

  /// No description provided for @flowDivingFishUsername2.
  ///
  /// In zh, this message translates to:
  /// **'Diving-Fish 用户名'**
  String get flowDivingFishUsername2;

  /// No description provided for @flowPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get flowPassword;

  /// No description provided for @flowDivingFishPassword2.
  ///
  /// In zh, this message translates to:
  /// **'Diving-Fish 密码'**
  String get flowDivingFishPassword2;

  /// No description provided for @flowImportTokenRetrievedAndSaved.
  ///
  /// In zh, this message translates to:
  /// **'ImportToken 已获取并缓存'**
  String get flowImportTokenRetrievedAndSaved;

  /// No description provided for @flowYouCanNowSyncScoresToDiving.
  ///
  /// In zh, this message translates to:
  /// **'现在可以使用\"同步成绩\"功能一键同步到水鱼了'**
  String get flowYouCanNowSyncScoresToDiving;

  /// No description provided for @flowSigningIn.
  ///
  /// In zh, this message translates to:
  /// **'登录中...'**
  String get flowSigningIn;

  /// No description provided for @flowSignIn.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get flowSignIn;

  /// No description provided for @flowDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'数据刷新成功!'**
  String get flowDataRefreshed;

  /// No description provided for @flowDivingFishProfile.
  ///
  /// In zh, this message translates to:
  /// **'水鱼 成绩导入Token'**
  String get flowDivingFishProfile;

  /// No description provided for @flowNotSignedInToDivingFishOnly.
  ///
  /// In zh, this message translates to:
  /// **'未登录水鱼账号，仅显示落雪相关设置'**
  String get flowNotSignedInToDivingFishOnly;

  /// No description provided for @flowNoQQIDFoundRefreshDataOr.
  ///
  /// In zh, this message translates to:
  /// **'未找到 QQ 号，请先刷新数据或登录水鱼'**
  String get flowNoQQIDFoundRefreshDataOr;

  /// No description provided for @flowAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'已授权'**
  String get flowAuthorized;

  /// No description provided for @flowNotAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'未授权'**
  String get flowNotAuthorized;

  /// No description provided for @flowReadingDivingFishScoresRequiresBrowserAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'读取你的水鱼成绩需要先在浏览器里授权本应用。点下方按钮打开授权链接，登录水鱼并同意即可。'**
  String get flowReadingDivingFishScoresRequiresBrowserAuthorization;

  /// No description provided for @flowDivingFishAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'水鱼授权'**
  String get flowDivingFishAuthorization;

  /// No description provided for @flowAuthorizationOpenedCompleteItInYourBrowser.
  ///
  /// In zh, this message translates to:
  /// **'已打开授权链接，请在浏览器中完成授权后返回查看'**
  String get flowAuthorizationOpenedCompleteItInYourBrowser;

  /// No description provided for @flowCouldNotStartAuthorizationTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'发起授权失败，请稍后重试'**
  String get flowCouldNotStartAuthorizationTryAgain;

  /// No description provided for @flowAuthorizeAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新授权'**
  String get flowAuthorizeAgain;

  /// No description provided for @flowOpenAuthorizationLink.
  ///
  /// In zh, this message translates to:
  /// **'打开授权链接'**
  String get flowOpenAuthorizationLink;

  /// No description provided for @flowLXNSPersonalAPIKey.
  ///
  /// In zh, this message translates to:
  /// **'落雪 API 密钥'**
  String get flowLXNSPersonalAPIKey;

  /// No description provided for @flowVisit2.
  ///
  /// In zh, this message translates to:
  /// **'访问 '**
  String get flowVisit2;

  /// No description provided for @flowAndScrollToTheBottomToGet.
  ///
  /// In zh, this message translates to:
  /// **'，滑到最底部获取密钥。'**
  String get flowAndScrollToTheBottomToGet;

  /// No description provided for @flowPasteYourLXNSPersonalAPIKey.
  ///
  /// In zh, this message translates to:
  /// **'在此粘贴落雪个人 API 密钥...'**
  String get flowPasteYourLXNSPersonalAPIKey;

  /// No description provided for @flowEnterYourAPIKeyFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先输入 API 密钥'**
  String get flowEnterYourAPIKeyFirst;

  /// No description provided for @flowClearKey.
  ///
  /// In zh, this message translates to:
  /// **'清除密钥'**
  String get flowClearKey;

  /// No description provided for @flowRefreshImportToken.
  ///
  /// In zh, this message translates to:
  /// **'刷新 ImportToken'**
  String get flowRefreshImportToken;

  /// No description provided for @flowCouldNotRefreshImportTokenTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'ImportToken 刷新失败，请稍后重试'**
  String get flowCouldNotRefreshImportTokenTryAgain;

  /// No description provided for @flowCopyImportToken.
  ///
  /// In zh, this message translates to:
  /// **'复制 ImportToken'**
  String get flowCopyImportToken;

  /// No description provided for @flowImportTokenCopied.
  ///
  /// In zh, this message translates to:
  /// **'ImportToken 已复制到剪贴板'**
  String get flowImportTokenCopied;

  /// No description provided for @flowConfirmRefresh.
  ///
  /// In zh, this message translates to:
  /// **'确认刷新'**
  String get flowConfirmRefresh;

  /// No description provided for @flowThisClearsAllMaidataCachesAndDownloads.
  ///
  /// In zh, this message translates to:
  /// **'将清除所有maidata缓存并从服务器重新拉取全部maidata数据，耗时可能较长。\n\n确定要刷新吗？'**
  String get flowThisClearsAllMaidataCachesAndDownloads;

  /// No description provided for @flowMaidataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'Maidata刷新成功'**
  String get flowMaidataRefreshed;

  /// No description provided for @flowRefreshFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'刷新失败: {p0}'**
  String flowRefreshFailedP0(String p0);

  /// No description provided for @flowCouldNotOpenABrowserWebsiteLink.
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器，官网链接已复制到剪贴板，请粘贴到浏览器访问 {p0}'**
  String flowCouldNotOpenABrowserWebsiteLink(String p0);

  /// No description provided for @flowConfirmSignOut.
  ///
  /// In zh, this message translates to:
  /// **'确认登出'**
  String get flowConfirmSignOut;

  /// No description provided for @flowSigningOutClearsSavedLoginDetailsAnd.
  ///
  /// In zh, this message translates to:
  /// **'登出后将清除缓存的登录信息和 ImportToken，确定要登出吗？'**
  String get flowSigningOutClearsSavedLoginDetailsAnd;

  /// No description provided for @flowSignOut.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get flowSignOut;

  /// No description provided for @flowAccountChangedChooseYourAppearanceAgain.
  ///
  /// In zh, this message translates to:
  /// **'账号已切换，请重新选择装扮'**
  String get flowAccountChangedChooseYourAppearanceAgain;

  /// No description provided for @flowCouldNotSaveYourAppearanceChooseAgain.
  ///
  /// In zh, this message translates to:
  /// **'装扮未能保存，请重新选择'**
  String get flowCouldNotSaveYourAppearanceChooseAgain;

  /// No description provided for @flowChooseWhereToSaveLogs.
  ///
  /// In zh, this message translates to:
  /// **'选择日志保存位置'**
  String get flowChooseWhereToSaveLogs;

  /// No description provided for @flowLogsExported.
  ///
  /// In zh, this message translates to:
  /// **'日志已导出'**
  String get flowLogsExported;

  /// No description provided for @flowCouldNotExportLogsP0.
  ///
  /// In zh, this message translates to:
  /// **'导出日志失败：{p0}'**
  String flowCouldNotExportLogsP0(String p0);

  /// No description provided for @flowCouldNotOpenABrowserP0Copied.
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器，{p0}已复制到剪贴板，请手动粘贴打开'**
  String flowCouldNotOpenABrowserP0Copied(String p0);

  /// No description provided for @flowBaseNoteMaidataDownloadedAgain.
  ///
  /// In zh, this message translates to:
  /// **'基础量 maidata 已重新拉取'**
  String get flowBaseNoteMaidataDownloadedAgain;

  /// No description provided for @flowDownloadFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'重新拉取失败：{p0}'**
  String flowDownloadFailedP0(String p0);

  /// No description provided for @flowPlayCountsUpdatedP0Records.
  ///
  /// In zh, this message translates to:
  /// **'游玩次数已更新（{p0} 条）'**
  String flowPlayCountsUpdatedP0Records(String p0);

  /// No description provided for @flowCouldNotReadPlayCountsP0.
  ///
  /// In zh, this message translates to:
  /// **'游玩次数读取失败：{p0}'**
  String flowCouldNotReadPlayCountsP0(String p0);

  /// No description provided for @flowNoConnectionConnectAndTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'当前无网络连接，请联网后重试'**
  String get flowNoConnectionConnectAndTryAgain;

  /// No description provided for @flowMaimaiScoreHubSignInSavedOCR.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 登录状态已保存，现在可以使用 OCR 了'**
  String get flowMaimaiScoreHubSignInSavedOCR;

  /// No description provided for @flowSignOutOfDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'确认登出水鱼账号'**
  String get flowSignOutOfDivingFish;

  /// No description provided for @flowCouldNotSignOutOfDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'登出水鱼账号失败：{p0}'**
  String flowCouldNotSignOutOfDivingFish(String p0);

  /// No description provided for @flowCannotSave.
  ///
  /// In zh, this message translates to:
  /// **'无法保存'**
  String get flowCannotSave;

  /// No description provided for @flowEnterYourAWMCNETScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'请输入 AWMC NET 成绩导入 Token。'**
  String get flowEnterYourAWMCNETScoreImportToken;

  /// No description provided for @flowAWMCNETScoreImportTokenSaved.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 成绩导入 Token 已保存'**
  String get flowAWMCNETScoreImportTokenSaved;

  /// No description provided for @flowAWMCNETScoreImportTokenCleared.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 成绩导入 Token 已清除'**
  String get flowAWMCNETScoreImportTokenCleared;

  /// No description provided for @flowSignedInToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'水鱼账号登录成功'**
  String get flowSignedInToDivingFish;

  /// No description provided for @flowScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'成绩导入 Token'**
  String get flowScoreImportToken;

  /// No description provided for @flowPasteATokenGeneratedInAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'粘贴 AWMC NET 设置页生成的 Token'**
  String get flowPasteATokenGeneratedInAWMCNET;

  /// No description provided for @flowSaveToken.
  ///
  /// In zh, this message translates to:
  /// **'保存 Token'**
  String get flowSaveToken;

  /// No description provided for @flowP0AutoSyncEnabledScheduledDailyBetween.
  ///
  /// In zh, this message translates to:
  /// **'已开启{p0}自动同步，每天北京时间 08:00–24:00 分时处理'**
  String flowP0AutoSyncEnabledScheduledDailyBetween(String p0);

  /// No description provided for @flowP0AutoSyncDisabledHostedCredentialsDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已关闭{p0}自动同步，并删除服务端托管凭据'**
  String flowP0AutoSyncDisabledHostedCredentialsDeleted(String p0);

  /// No description provided for @flowAutoSyncTemporarilyLimited.
  ///
  /// In zh, this message translates to:
  /// **'自动同步暂时受限'**
  String get flowAutoSyncTemporarilyLimited;

  /// No description provided for @flowCouldNotConfigureAutoSyncCheckYour.
  ///
  /// In zh, this message translates to:
  /// **'自动同步设置失败，请检查账号状态后重试'**
  String get flowCouldNotConfigureAutoSyncCheckYour;

  /// No description provided for @flowRefreshStatus.
  ///
  /// In zh, this message translates to:
  /// **'刷新状态'**
  String get flowRefreshStatus;

  /// No description provided for @flowQueueStatus.
  ///
  /// In zh, this message translates to:
  /// **'排队情况'**
  String get flowQueueStatus;

  /// No description provided for @flowSyncSources.
  ///
  /// In zh, this message translates to:
  /// **'同步数据源'**
  String get flowSyncSources;

  /// No description provided for @flowLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在读取…'**
  String get flowLoading;

  /// No description provided for @flowSourcesEnabled.
  ///
  /// In zh, this message translates to:
  /// **'个数据源已开启'**
  String get flowSourcesEnabled;

  /// No description provided for @flowScheduledQueueWindow.
  ///
  /// In zh, this message translates to:
  /// **'分时排队窗口'**
  String get flowScheduledQueueWindow;

  /// No description provided for @flowChinaTimeUTC8OnceDailyQuick.
  ///
  /// In zh, this message translates to:
  /// **'北京时间（UTC+8） · 每天一次 · 仅快速同步'**
  String get flowChinaTimeUTC8OnceDailyQuick;

  /// No description provided for @flowCredentialsAreEncryptedAndHostedWhileEnabled.
  ///
  /// In zh, this message translates to:
  /// **'开启后加密托管同步凭据，关闭即删除。'**
  String get flowCredentialsAreEncryptedAndHostedWhileEnabled;

  /// No description provided for @flowAboutSync.
  ///
  /// In zh, this message translates to:
  /// **'同步说明'**
  String get flowAboutSync;

  /// No description provided for @flowUsersAreProcessedInDailyBatchesNew.
  ///
  /// In zh, this message translates to:
  /// **'每天分批排队处理；批次进行中或等待开始时新加入用户会排在当前批次末尾，批次结束后与其他用户一起进入下一轮随机排序；上游限流或队列较长时会顺延到后续窗口。'**
  String get flowUsersAreProcessedInDailyBatchesNew;

  /// No description provided for @flowEachUserBatchHasAProcessingLimit.
  ///
  /// In zh, this message translates to:
  /// **'单个用户批次有整体处理时限：上游慢响应、配额不足或大量上传超过时限时，会自动结束本轮并在上轮结果中说明原因，次日窗口继续（排队等待不计入）。'**
  String get flowEachUserBatchHasAProcessingLimit;

  /// No description provided for @flowAfterReadingCabinetScoresEachUserHas.
  ///
  /// In zh, this message translates to:
  /// **'机台成绩读取完成后，单个用户最多处理 {p0} 分钟；读取前的排队和额度等待不计入。超出处理时限或当天服务窗口会结束本轮，次日窗口继续。'**
  String flowAfterReadingCabinetScoresEachUserHas(String p0);

  /// No description provided for @flowLinkYourCabinetIdentityUsingAQR.
  ///
  /// In zh, this message translates to:
  /// **'输入二维码绑定机台身份后，同步凭据可供三个数据源共用；也可以通过一次普通二维码同步自动完成绑定。各数据源仍需配置各自的个人 key 和账号。\n\n每天在北京时间 08:00–24:00 分时安排快速同步：同一用户的三个数据源共用一份机台成绩读取结果，再分别读取目标成绩并上传变化。\n\n执行中会显示当前阶段、已读取页数、上传与已提交条数、已用时长；遇到上游等待会显示原因和预计重试时间。上轮结果会给出耗时、机台数据采集时间和下次重试时间。\n\n自动同步使用统一的上游请求预算和限流；遇到维护、配额不足或网络错误会暂停并显示原因，不会连续重试。\n\n正在执行时关闭，会停止后续批次，已经提交的成绩会保留；上传结果不确定时会先核对，不盲目重复提交。'**
  String get flowLinkYourCabinetIdentityUsingAQR;

  /// No description provided for @flowSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存…'**
  String get flowSaving;

  /// No description provided for @flowP0AutoSync.
  ///
  /// In zh, this message translates to:
  /// **'{p0}自动同步'**
  String flowP0AutoSync(String p0);

  /// No description provided for @flowRoundStartedP0.
  ///
  /// In zh, this message translates to:
  /// **'本轮开始：{p0}'**
  String flowRoundStartedP0(String p0);

  /// No description provided for @flowNextRunP0.
  ///
  /// In zh, this message translates to:
  /// **'下次执行：{p0}'**
  String flowNextRunP0(String p0);

  /// No description provided for @flowLoadingSyncStatus.
  ///
  /// In zh, this message translates to:
  /// **'正在读取同步状态…'**
  String get flowLoadingSyncStatus;

  /// No description provided for @flowOffEnableAnytime.
  ///
  /// In zh, this message translates to:
  /// **'未开启 · 可随时开启'**
  String get flowOffEnableAnytime;

  /// No description provided for @flowSyncSucceededButLocalRefreshWasIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'同步已成功，本地刷新未完成：{p0}'**
  String flowSyncSucceededButLocalRefreshWasIncomplete(String p0);

  /// No description provided for @flowTheQueueIsBusyYourRunMay.
  ///
  /// In zh, this message translates to:
  /// **'当前排队人数较多，可能顺延到后续处理窗口'**
  String get flowTheQueueIsBusyYourRunMay;

  /// No description provided for @flowLastProgressP0.
  ///
  /// In zh, this message translates to:
  /// **'上次进度：{p0}'**
  String flowLastProgressP0(String p0);

  /// No description provided for @flowP0NoExecutionSlotIsUsedWhile.
  ///
  /// In zh, this message translates to:
  /// **'{p0}；等待期间不占用执行名额'**
  String flowP0NoExecutionSlotIsUsedWhile(String p0);

  /// No description provided for @flowRunTimeP0.
  ///
  /// In zh, this message translates to:
  /// **'执行时间：{p0}'**
  String flowRunTimeP0(String p0);

  /// No description provided for @flowCabinetDataCollectedP0.
  ///
  /// In zh, this message translates to:
  /// **'机台数据采集：{p0}'**
  String flowCabinetDataCollectedP0(String p0);

  /// No description provided for @flowTheRoundExceededItsTimeLimitAnd.
  ///
  /// In zh, this message translates to:
  /// **'已超过单轮处理时限，被自动结束；未完成的部分会在下次定时时间继续。'**
  String get flowTheRoundExceededItsTimeLimitAnd;

  /// No description provided for @flowTheRoundExceededItsP0MinuteLimit.
  ///
  /// In zh, this message translates to:
  /// **'已超过单轮 {p0} 分钟处理上限，被自动结束；未完成的部分会在下次定时时间继续。'**
  String flowTheRoundExceededItsP0MinuteLimit(String p0);

  /// No description provided for @flowNextAutomaticRetry.
  ///
  /// In zh, this message translates to:
  /// **'下次自动重试'**
  String get flowNextAutomaticRetry;

  /// No description provided for @flowNextRun.
  ///
  /// In zh, this message translates to:
  /// **'下次执行'**
  String get flowNextRun;

  /// No description provided for @flowP0Queue.
  ///
  /// In zh, this message translates to:
  /// **'{p0}队列'**
  String flowP0Queue(String p0);

  /// No description provided for @flowNextRound.
  ///
  /// In zh, this message translates to:
  /// **'下轮'**
  String get flowNextRound;

  /// No description provided for @flowThisRound.
  ///
  /// In zh, this message translates to:
  /// **'本轮'**
  String get flowThisRound;

  /// No description provided for @flowChinaTimeUTC8.
  ///
  /// In zh, this message translates to:
  /// **'北京时间（UTC+8）'**
  String get flowChinaTimeUTC8;

  /// No description provided for @flowLimitP0MinutesPerRound.
  ///
  /// In zh, this message translates to:
  /// **' · 单轮上限 {p0} 分钟'**
  String flowLimitP0MinutesPerRound(String p0);

  /// No description provided for @flowWaitingForUpstreamRecovery.
  ///
  /// In zh, this message translates to:
  /// **'等待上游恢复'**
  String get flowWaitingForUpstreamRecovery;

  /// No description provided for @flowPreviousRoundQueue.
  ///
  /// In zh, this message translates to:
  /// **'上轮队列处理'**
  String get flowPreviousRoundQueue;

  /// No description provided for @flowLoadingPreviousRoundStatistics.
  ///
  /// In zh, this message translates to:
  /// **'上轮统计读取中…'**
  String get flowLoadingPreviousRoundStatistics;

  /// No description provided for @flowStatisticsUnavailableRetryingAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'统计暂不可用，将自动重试'**
  String get flowStatisticsUnavailableRetryingAutomatically;

  /// No description provided for @flowNoPreviousRound.
  ///
  /// In zh, this message translates to:
  /// **'暂无上轮记录'**
  String get flowNoPreviousRound;

  /// No description provided for @flowSubmittedP0SkippedP1P2.
  ///
  /// In zh, this message translates to:
  /// **'提交 {p0} 条 · 跳过 {p1} 条 · {p2}'**
  String flowSubmittedP0SkippedP1P2(String p0, String p1, String p2);

  /// No description provided for @flowCabinetIdentityLinked.
  ///
  /// In zh, this message translates to:
  /// **'机台身份已绑定'**
  String get flowCabinetIdentityLinked;

  /// No description provided for @flowLinkCabinetIdentityFirst.
  ///
  /// In zh, this message translates to:
  /// **'先绑定机台身份'**
  String get flowLinkCabinetIdentityFirst;

  /// No description provided for @flowRequestAndOpenALoginQRCode2.
  ///
  /// In zh, this message translates to:
  /// **'在舞萌 | 中二公众号请求并打开登入二维码，扫描后把 SGWCMAID 开头的字符串填到下面。三个数据源共用这一次绑定，二维码本身不会保存；完成一次普通二维码同步也会自动绑定。'**
  String get flowRequestAndOpenALoginQRCode2;

  /// No description provided for @flowCabinetLoginQRCode.
  ///
  /// In zh, this message translates to:
  /// **'机台登入二维码'**
  String get flowCabinetLoginQRCode;

  /// No description provided for @flowLinking2.
  ///
  /// In zh, this message translates to:
  /// **'正在绑定…'**
  String get flowLinking2;

  /// No description provided for @flowLinkCabinetIdentity.
  ///
  /// In zh, this message translates to:
  /// **'绑定机台身份'**
  String get flowLinkCabinetIdentity;

  /// No description provided for @flowEnterYourP0PersonalKeyToo.
  ///
  /// In zh, this message translates to:
  /// **'还需填写{p0}个人 key'**
  String flowEnterYourP0PersonalKeyToo(String p0);

  /// No description provided for @flowOpenDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'打开水鱼查分器'**
  String get flowOpenDivingFish;

  /// No description provided for @flowOpenKeyPage.
  ///
  /// In zh, this message translates to:
  /// **'打开获取页面'**
  String get flowOpenKeyPage;

  /// No description provided for @flowPersonalKey.
  ///
  /// In zh, this message translates to:
  /// **'个人 key'**
  String get flowPersonalKey;

  /// No description provided for @flowPasteImportToken.
  ///
  /// In zh, this message translates to:
  /// **'在此粘贴 ImportToken...'**
  String get flowPasteImportToken;

  /// No description provided for @flowSavePersonalKey.
  ///
  /// In zh, this message translates to:
  /// **'保存个人 key'**
  String get flowSavePersonalKey;

  /// No description provided for @flowInvalidCabinetLoginQRCode.
  ///
  /// In zh, this message translates to:
  /// **'无效的机台登入二维码'**
  String get flowInvalidCabinetLoginQRCode;

  /// No description provided for @flowSyncFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'同步失败：{p0}'**
  String flowSyncFailedP0(String p0);

  /// No description provided for @flowAWMCGatewayUnavailableP0.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关当前不可用：{p0}'**
  String flowAWMCGatewayUnavailableP0(String p0);

  /// No description provided for @flowThisReadsOnlyTheActiveAccountPlay.
  ///
  /// In zh, this message translates to:
  /// **'本功能只读取当前活动账号的游玩次数。请使用一张刚生成的二维码；本次操作只会请求一次上游接口。'**
  String get flowThisReadsOnlyTheActiveAccountPlay;

  /// No description provided for @flowMaimaiDXCHUNITHMLoginQRSGWCMAID2.
  ///
  /// In zh, this message translates to:
  /// **'舞萌DX | 中二节奏登入二维码（SGWCMAID...）'**
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID2;

  /// No description provided for @flowEnterAValidSGWCMAIDCabinetLoginQR.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的 SGWCMAID 机台登入二维码'**
  String get flowEnterAValidSGWCMAIDCabinetLoginQR;

  /// No description provided for @flowReadPlayCount.
  ///
  /// In zh, this message translates to:
  /// **'开始读取'**
  String get flowReadPlayCount;

  /// No description provided for @flowNone.
  ///
  /// In zh, this message translates to:
  /// **'（无）'**
  String get flowNone;

  /// No description provided for @flowViewFullData.
  ///
  /// In zh, this message translates to:
  /// **'查看完整数据'**
  String get flowViewFullData;

  /// No description provided for @flowDataIsShownOnlyOnThisDevice.
  ///
  /// In zh, this message translates to:
  /// **'数据仅在本机展示，不会上传到任何第三方。'**
  String get flowDataIsShownOnlyOnThisDevice;

  /// No description provided for @flowSetGatewayToken.
  ///
  /// In zh, this message translates to:
  /// **'设置网关令牌'**
  String get flowSetGatewayToken;

  /// No description provided for @flowQRCodeContent.
  ///
  /// In zh, this message translates to:
  /// **'二维码内容'**
  String get flowQRCodeContent;

  /// No description provided for @flowInvalidQRFormatMustStartWithSGWCMAID.
  ///
  /// In zh, this message translates to:
  /// **'二维码格式不正确（应以 SGWCMAID 开头）'**
  String get flowInvalidQRFormatMustStartWithSGWCMAID;

  /// No description provided for @flowConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'确认执行'**
  String get flowConfirmAction;

  /// No description provided for @flowNoCharge.
  ///
  /// In zh, this message translates to:
  /// **'不计费'**
  String get flowNoCharge;

  /// No description provided for @flowShow.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get flowShow;

  /// No description provided for @flowFullData.
  ///
  /// In zh, this message translates to:
  /// **'完整数据'**
  String get flowFullData;

  /// No description provided for @flowP0P1CharactersP2LinesShownOnly.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 共 {p1} 字符 / {p2} 行\n数据仅在本机展示，不会上传到任何第三方。'**
  String flowP0P1CharactersP2LinesShownOnly(String p0, String p1, String p2);

  /// No description provided for @flowEnterYourAWMCNETScoreImportToken2.
  ///
  /// In zh, this message translates to:
  /// **'请输入 AWMC NET 成绩导入 Token'**
  String get flowEnterYourAWMCNETScoreImportToken2;

  /// No description provided for @flowImportTokenSaved.
  ///
  /// In zh, this message translates to:
  /// **'导入 Token 已保存'**
  String get flowImportTokenSaved;

  /// No description provided for @flowPasteOrScanACabinetLoginQR.
  ///
  /// In zh, this message translates to:
  /// **'请先粘贴或扫描机台登入二维码（SGWCMAID 开头）'**
  String get flowPasteOrScanACabinetLoginQR;

  /// No description provided for @flowSetYourAWMCNETScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'请先设置 AWMC NET 成绩导入 Token'**
  String get flowSetYourAWMCNETScoreImportToken;

  /// No description provided for @flowRequestAndOpenALoginQRIn.
  ///
  /// In zh, this message translates to:
  /// **'在「舞萌|中二」公众号请求登入二维码并打开，再粘贴到下方；也可直接用「扫描」或「从图片识别」。'**
  String get flowRequestAndOpenALoginQRIn;

  /// No description provided for @flowMaimaiDXCHUNITHMLoginQRSGWCMAID3.
  ///
  /// In zh, this message translates to:
  /// **'舞萌DX | 中二节奏 登入二维码（SGWCMAID...）'**
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID3;

  /// No description provided for @flowScoreImportTokenSet.
  ///
  /// In zh, this message translates to:
  /// **'成绩导入 Token 已设置'**
  String get flowScoreImportTokenSet;

  /// No description provided for @flowSetAWMCNETScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'设置 AWMC NET 成绩导入 Token'**
  String get flowSetAWMCNETScoreImportToken;

  /// No description provided for @flowChange.
  ///
  /// In zh, this message translates to:
  /// **'更换'**
  String get flowChange;

  /// No description provided for @flowPasteScoreImportToken.
  ///
  /// In zh, this message translates to:
  /// **'在此粘贴成绩导入 Token…'**
  String get flowPasteScoreImportToken;

  /// No description provided for @flowGenerateYourOwnTokenOnAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'导入需要在 AWMC NET 官网生成一次 Token（项目自带的密钥在这里用不了）：'**
  String get flowGenerateYourOwnTokenOnAWMCNET;

  /// No description provided for @flow1OpenTheAWMCNETSettingsLink.
  ///
  /// In zh, this message translates to:
  /// **'① 点击下面的链接打开 AWMC NET 设置页'**
  String get flow1OpenTheAWMCNETSettingsLink;

  /// No description provided for @flow2ScrollToTheBottomAndGenerate.
  ///
  /// In zh, this message translates to:
  /// **'② 滑到页面最底部，点「生成/轮换Token」'**
  String get flow2ScrollToTheBottomAndGenerate;

  /// No description provided for @flow3CopyTheTokenAndPasteIt.
  ///
  /// In zh, this message translates to:
  /// **'③ 复制生成的 Token，然后粘贴到此处'**
  String get flow3CopyTheTokenAndPasteIt;

  /// No description provided for @flowCabinetScoresTakePriorityAndOverwriteMatching.
  ///
  /// In zh, this message translates to:
  /// **'以机台为准，会覆盖 AWMC NET 上已存在的对应成绩。'**
  String get flowCabinetScoresTakePriorityAndOverwriteMatching;

  /// No description provided for @flowCouldNotOpenABrowserVisitP0.
  ///
  /// In zh, this message translates to:
  /// **'打不开浏览器，请手动访问 {p0}'**
  String flowCouldNotOpenABrowserVisitP0(String p0);

  /// No description provided for @flowClearP0AccountData.
  ///
  /// In zh, this message translates to:
  /// **'清除{p0}账号数据'**
  String flowClearP0AccountData(String p0);

  /// No description provided for @flowThisDeletesLocalP0CachesScoresBest50.
  ///
  /// In zh, this message translates to:
  /// **'将删除 {p0} 账号的本地缓存（成绩、Best50、玩家信息、推荐结果等），不影响登录状态。\n\n下次使用该账号需要重新刷新数据，确定清除？'**
  String flowThisDeletesLocalP0CachesScoresBest50(String p0);

  /// No description provided for @flowClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get flowClear;

  /// No description provided for @flowCouldNotClearP0.
  ///
  /// In zh, this message translates to:
  /// **'清除失败：{p0}'**
  String flowCouldNotClearP0(String p0);

  /// No description provided for @flowClearedP0AccountData.
  ///
  /// In zh, this message translates to:
  /// **'已清除{p0}账号数据'**
  String flowClearedP0AccountData(String p0);

  /// No description provided for @flowSwitchedToP0Account.
  ///
  /// In zh, this message translates to:
  /// **'已切换到{p0}账号'**
  String flowSwitchedToP0Account(String p0);

  /// No description provided for @flowAccountSwitchFailedAttemptedToRestoreThe.
  ///
  /// In zh, this message translates to:
  /// **'账号切换失败，已尝试恢复原账号'**
  String get flowAccountSwitchFailedAttemptedToRestoreThe;

  /// No description provided for @flowSwitchingPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'正在切换，请稍候'**
  String get flowSwitchingPleaseWait;

  /// No description provided for @flowNoCachedDataForThisAccount.
  ///
  /// In zh, this message translates to:
  /// **'该账号暂无缓存'**
  String get flowNoCachedDataForThisAccount;

  /// No description provided for @flowNoDataHasBeenCachedForP0.
  ///
  /// In zh, this message translates to:
  /// **'{p0}账号还没有缓存过数据，去刷新数据？'**
  String flowNoDataHasBeenCachedForP0(String p0);

  /// No description provided for @flowRefreshNow.
  ///
  /// In zh, this message translates to:
  /// **'去刷新'**
  String get flowRefreshNow;

  /// No description provided for @flowSwitchAccount.
  ///
  /// In zh, this message translates to:
  /// **'切换账号'**
  String get flowSwitchAccount;

  /// No description provided for @flowSwitchingToP0.
  ///
  /// In zh, this message translates to:
  /// **'正在切换到{p0}账号…'**
  String flowSwitchingToP0(String p0);

  /// No description provided for @flowTapAnAccountToSwitchSourceAnd.
  ///
  /// In zh, this message translates to:
  /// **'点击账号即可切换数据源与玩家信息（使用本地缓存，不联网）'**
  String get flowTapAnAccountToSwitchSourceAnd;

  /// No description provided for @flowRefreshToUpdateTheActiveAccountDiving.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据可更新当前账号；水鱼 / 落雪的登录状态相互独立，AWMC NET 按 QQ 查询无需登录。'**
  String get flowRefreshToUpdateTheActiveAccountDiving;

  /// No description provided for @flowCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get flowCurrent;

  /// No description provided for @flowNoCache.
  ///
  /// In zh, this message translates to:
  /// **'暂无缓存'**
  String get flowNoCache;

  /// No description provided for @flowCopiedP0.
  ///
  /// In zh, this message translates to:
  /// **'已复制：{p0}'**
  String flowCopiedP0(String p0);

  /// No description provided for @flowAWMCBOTQQIDCopiedP0.
  ///
  /// In zh, this message translates to:
  /// **'已复制 AWMC BOT QQ 号：{p0}'**
  String flowAWMCBOTQQIDCopiedP0(String p0);

  /// No description provided for @flowCopyP0.
  ///
  /// In zh, this message translates to:
  /// **'复制 {p0}'**
  String flowCopyP0(String p0);

  /// No description provided for @flowOpenLXNS.
  ///
  /// In zh, this message translates to:
  /// **'打开落雪咖啡屋'**
  String get flowOpenLXNS;

  /// No description provided for @flowSendMymaiFirstIfNoAccountRecord.
  ///
  /// In zh, this message translates to:
  /// **'先发送 mymai。尚未建立账号记录时，机器人会回复操作步骤。'**
  String get flowSendMymaiFirstIfNoAccountRecord;

  /// No description provided for @flowThenSendMaiAndFollowTheInstructions.
  ///
  /// In zh, this message translates to:
  /// **'再发送 mai绑定，按提示创建档案。'**
  String get flowThenSendMaiAndFollowTheInstructions;

  /// No description provided for @flowOpenAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'打开 AWMC NET'**
  String get flowOpenAWMCNET;

  /// No description provided for @flowTapAnImageToEnlargeIt.
  ///
  /// In zh, this message translates to:
  /// **'点开图片可以放大查看哦'**
  String get flowTapAnImageToEnlargeIt;

  /// No description provided for @flowEnlargeImage.
  ///
  /// In zh, this message translates to:
  /// **'放大查看图片'**
  String get flowEnlargeImage;

  /// No description provided for @flowNotSignedInToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'还没登录水鱼账号'**
  String get flowNotSignedInToDivingFish;

  /// No description provided for @flowYourDivingFishAccountHasNoLinked.
  ///
  /// In zh, this message translates to:
  /// **'你的水鱼账号还没绑定 QQ 号'**
  String get flowYourDivingFishAccountHasNoLinked;

  /// No description provided for @flowLinkQQOnDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'去水鱼官网绑定'**
  String get flowLinkQQOnDivingFish;

  /// No description provided for @flowISavedItReadAgain.
  ///
  /// In zh, this message translates to:
  /// **'我已填好，重新读取'**
  String get flowISavedItReadAgain;

  /// No description provided for @flowAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get flowAccount;

  /// No description provided for @flowCheckingAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'正在检查授权状态...'**
  String get flowCheckingAuthorization;

  /// No description provided for @flowAuthorizationOpenedFinishInYourBrowserThen.
  ///
  /// In zh, this message translates to:
  /// **'已打开授权页，请在浏览器中完成授权后点右侧重新检测'**
  String get flowAuthorizationOpenedFinishInYourBrowserThen;

  /// No description provided for @flowReadingScoresRequiresAuthorizationRefreshWillFail.
  ///
  /// In zh, this message translates to:
  /// **'读取成绩需先授权本应用，未授权时刷新会失败'**
  String get flowReadingScoresRequiresAuthorizationRefreshWillFail;

  /// No description provided for @flowAuthorizedCheckAgain.
  ///
  /// In zh, this message translates to:
  /// **'我已授权，重新检测'**
  String get flowAuthorizedCheckAgain;

  /// No description provided for @flowAuthorize.
  ///
  /// In zh, this message translates to:
  /// **'去授权'**
  String get flowAuthorize;

  /// No description provided for @flowCouldNotOpenABrowserLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器，链接已复制到剪贴板，请手动粘贴打开'**
  String get flowCouldNotOpenABrowserLinkCopied;

  /// No description provided for @flowP0ReusesThisDeviceSMaimaiScore.
  ///
  /// In zh, this message translates to:
  /// **'{p0}会复用本机保存的 maimai Score Hub 登录状态。\n\n当前没有可用登录态：请先用一张新的机台二维码完成登录；登录成功后，本次同步还会再要求一张新的二维码用于抓取成绩——同一张二维码不能同时用于登录和同步。\n\n登录状态会保存在本机，之后使用线路2不需要重复登录。'**
  String flowP0ReusesThisDeviceSMaimaiScore(String p0);

  /// No description provided for @flowRoute2Sync.
  ///
  /// In zh, this message translates to:
  /// **'线路2 同步'**
  String get flowRoute2Sync;

  /// No description provided for @flowP0Sync.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 同步'**
  String flowP0Sync(String p0);

  /// No description provided for @flowTipGenerateTwoDifferentLoginQRCodes.
  ///
  /// In zh, this message translates to:
  /// **'提示：扫码前先在公众号/机台生成两张不同的登入二维码。'**
  String get flowTipGenerateTwoDifferentLoginQRCodes;

  /// No description provided for @flowSignInFirst.
  ///
  /// In zh, this message translates to:
  /// **'去登录'**
  String get flowSignInFirst;

  /// No description provided for @flowSignedInToMaimaiScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 登录成功'**
  String get flowSignedInToMaimaiScoreHub;

  /// No description provided for @flowSignInSavedForOCRAndRoute.
  ///
  /// In zh, this message translates to:
  /// **'登录状态已保存。可复用于 OCR 与线路2 同步，\n不需要再重复扫码登录。'**
  String get flowSignInSavedForOCRAndRoute;

  /// No description provided for @flowAuthenticatesWithMaimaiScoreHubOnlyNo.
  ///
  /// In zh, this message translates to:
  /// **'只进行 maimai Score Hub 认证，不会抓取或同步成绩。'**
  String get flowAuthenticatesWithMaimaiScoreHubOnlyNo;

  /// No description provided for @flowInvalidQRCodeUseALoginQR.
  ///
  /// In zh, this message translates to:
  /// **'无效的二维码，请使用舞萌|中二公众号生成的登入二维码'**
  String get flowInvalidQRCodeUseALoginQR;

  /// No description provided for @flowSetLXNSPersonalAPIKey.
  ///
  /// In zh, this message translates to:
  /// **'设置落雪个人 API 密钥'**
  String get flowSetLXNSPersonalAPIKey;

  /// No description provided for @flowExportingToLXNSRequiresYourPersonalAPI.
  ///
  /// In zh, this message translates to:
  /// **'落雪导出需要你本人的个人 API 密钥（不是账号密码）：'**
  String get flowExportingToLXNSRequiresYourPersonalAPI;

  /// No description provided for @flow1OpenTheLXNSProfileLinkBelow.
  ///
  /// In zh, this message translates to:
  /// **'① 点击下面的链接打开落雪个人主页'**
  String get flow1OpenTheLXNSProfileLinkBelow;

  /// No description provided for @flow2ScrollToTheBottomAndCopy.
  ///
  /// In zh, this message translates to:
  /// **'② 滑到页面最底部，找到「个人 API 密钥」并复制'**
  String get flow2ScrollToTheBottomAndCopy;

  /// No description provided for @flow3ReturnToAccountManagementLXNSAPI.
  ///
  /// In zh, this message translates to:
  /// **'③ 回到 App，打开「成绩导入凭据 → 落雪 API 密钥」粘贴并保存'**
  String get flow3ReturnToAccountManagementLXNSAPI;

  /// No description provided for @flowReopenThisDialogAfterSavingToSync.
  ///
  /// In zh, this message translates to:
  /// **'保存后重新打开本对话框即可同步。'**
  String get flowReopenThisDialogAfterSavingToSync;

  /// No description provided for @flowLinkYourDivingFishAccountToObtain.
  ///
  /// In zh, this message translates to:
  /// **'需要绑定你的水鱼账号以获取 ImportToken：'**
  String get flowLinkYourDivingFishAccountToObtain;

  /// No description provided for @flowSyncSucceededButDataRefreshFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'同步成功，但刷新数据失败：{p0}'**
  String flowSyncSucceededButDataRefreshFailedP0(String p0);

  /// No description provided for @flowSignInToYourDivingFishAccount.
  ///
  /// In zh, this message translates to:
  /// **'请先登录你的水鱼账号，再使用同步功能。'**
  String get flowSignInToYourDivingFishAccount;

  /// No description provided for @flowAccountMismatch.
  ///
  /// In zh, this message translates to:
  /// **'账号不匹配'**
  String get flowAccountMismatch;

  /// No description provided for @flowTheSignedInDivingFishQQP0.
  ///
  /// In zh, this message translates to:
  /// **'当前登录水鱼账号绑定的 QQ（{p0}）与本机缓存的 QQ（{p1}）不一致。\n\n请先登出当前水鱼账号，登录正确的账号后再同步。'**
  String flowTheSignedInDivingFishQQP0(String p0, String p1);

  /// No description provided for @flowSyncCompleteP0ScoresSyncedAndLocal.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！{p0} 条成绩已同步，本地数据已刷新'**
  String flowSyncCompleteP0ScoresSyncedAndLocal(String p0);

  /// No description provided for @flowSyncCompleteP0ScoresSentToDiving.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！{p0} 条成绩已推送到水鱼'**
  String flowSyncCompleteP0ScoresSentToDiving(String p0);

  /// No description provided for @flowSyncCompleteP0ScoresExportedToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！共 {p0} 条成绩已导出到落雪'**
  String flowSyncCompleteP0ScoresExportedToLXNS(String p0);

  /// No description provided for @flowEnterANewQRCodeForP0.
  ///
  /// In zh, this message translates to:
  /// **'为{p0}输入新的二维码'**
  String flowEnterANewQRCodeForP0(String p0);

  /// No description provided for @flowMultiPlatformSyncCompleteP0.
  ///
  /// In zh, this message translates to:
  /// **'多端同步完成：{p0}'**
  String flowMultiPlatformSyncCompleteP0(String p0);

  /// No description provided for @flowSyncCompleteP0P1P2.
  ///
  /// In zh, this message translates to:
  /// **'同步已完成：{p0}{p1}{p2}'**
  String flowSyncCompleteP0P1P2(String p0, String p1, String p2);

  /// No description provided for @flowNone2.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get flowNone2;

  /// No description provided for @flowSyncFailedP02.
  ///
  /// In zh, this message translates to:
  /// **'\n\n同步失败：\n{p0}'**
  String flowSyncFailedP02(String p0);

  /// No description provided for @flowSyncSucceededButRefreshFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'\n\n同步成功，但刷新数据失败：\n{p0}'**
  String flowSyncSucceededButRefreshFailedP0(String p0);

  /// No description provided for @flowCouldNotSaveCredentialsTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'凭据保存失败，请重试。'**
  String get flowCouldNotSaveCredentialsTryAgain;

  /// No description provided for @flowCouldNotOpenTheWebsiteVisitP0.
  ///
  /// In zh, this message translates to:
  /// **'无法打开网站，请在浏览器中访问：{p0}'**
  String flowCouldNotOpenTheWebsiteVisitP0(String p0);

  /// No description provided for @flowRoute1.
  ///
  /// In zh, this message translates to:
  /// **'线路1'**
  String get flowRoute1;

  /// No description provided for @flowRoute2.
  ///
  /// In zh, this message translates to:
  /// **'线路2'**
  String get flowRoute2;

  /// No description provided for @flowCurrentP0P1.
  ///
  /// In zh, this message translates to:
  /// **'当前：{p0} · {p1}'**
  String flowCurrentP0P1(String p0, String p1);

  /// No description provided for @flowQuickSyncAlwaysUsesRoute1.
  ///
  /// In zh, this message translates to:
  /// **'快速同步已固定使用线路1'**
  String get flowQuickSyncAlwaysUsesRoute1;

  /// No description provided for @flowAvailable.
  ///
  /// In zh, this message translates to:
  /// **'已存在'**
  String get flowAvailable;

  /// No description provided for @flowMissing.
  ///
  /// In zh, this message translates to:
  /// **'未填写'**
  String get flowMissing;

  /// No description provided for @flowFillInCredentialsToSelectThisSource.
  ///
  /// In zh, this message translates to:
  /// **'补齐凭据后即可勾选'**
  String get flowFillInCredentialsToSelectThisSource;

  /// No description provided for @flowCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get flowCollapse;

  /// No description provided for @flowFillInMissingCredentials.
  ///
  /// In zh, this message translates to:
  /// **'填写缺少的凭据'**
  String get flowFillInMissingCredentials;

  /// No description provided for @flowGetYourImportTokenFromTheDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'在水鱼官网登录后获取 ImportToken；通过 App 的「登录水鱼」保存过的凭据也会自动识别。'**
  String get flowGetYourImportTokenFromTheDivingFish;

  /// No description provided for @flowSignInToLXNSAndGetYour.
  ///
  /// In zh, this message translates to:
  /// **'登录落雪咖啡屋，在账号设置中获取个人 API 密钥。'**
  String get flowSignInToLXNSAndGetYour;

  /// No description provided for @flowEnterTheQQLinkedToAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'填写 AWMC NET 账号绑定的 QQ；导入还需在官网设置页底部生成的 Import-Token。'**
  String get flowEnterTheQQLinkedToAWMCNET;

  /// No description provided for @flowOpenWebsite.
  ///
  /// In zh, this message translates to:
  /// **'打开官网'**
  String get flowOpenWebsite;

  /// No description provided for @flowAWMCNETQQID.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET QQ 号'**
  String get flowAWMCNETQQID;

  /// No description provided for @flowSaveAndSelect.
  ///
  /// In zh, this message translates to:
  /// **'保存并选中'**
  String get flowSaveAndSelect;

  /// No description provided for @flowNormalSyncRequiresANewCabinetQR.
  ///
  /// In zh, this message translates to:
  /// **'普通同步会在每个目标开始前分别要求一张新的机台二维码；同一张二维码不会用于第二个请求。快速同步不需要二维码。'**
  String get flowNormalSyncRequiresANewCabinetQR;

  /// No description provided for @flowSourcesWithSavedCredentialsAreSelectedBy.
  ///
  /// In zh, this message translates to:
  /// **'凭据存在的端默认勾选；水鱼 → 落雪 → AWMC NET 依次同步。'**
  String get flowSourcesWithSavedCredentialsAreSelectedBy;

  /// No description provided for @flowReloadCredentials.
  ///
  /// In zh, this message translates to:
  /// **'重新读取凭据'**
  String get flowReloadCredentials;

  /// No description provided for @flowAWMCNETOverwritesMatchingRecordsWithCabinet.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 将以机台成绩为准覆盖已有对应成绩。'**
  String get flowAWMCNETOverwritesMatchingRecordsWithCabinet;

  /// No description provided for @flowStartSyncP0.
  ///
  /// In zh, this message translates to:
  /// **'开始同步（{p0}）'**
  String flowStartSyncP0(String p0);

  /// No description provided for @flowRefreshDataAfterSync.
  ///
  /// In zh, this message translates to:
  /// **'同步成功后刷新数据'**
  String get flowRefreshDataAfterSync;

  /// No description provided for @flowRefreshAutomaticallyAfterUploadRefreshErrorsAre.
  ///
  /// In zh, this message translates to:
  /// **'成绩上传成功后自动刷新；刷新失败会单独提示。'**
  String get flowRefreshAutomaticallyAfterUploadRefreshErrorsAre;

  /// No description provided for @flowCouldNotReadRefreshSettingsUploadCan.
  ///
  /// In zh, this message translates to:
  /// **'刷新配置读取失败，上传可继续，刷新错误将单独提示。'**
  String get flowCouldNotReadRefreshSettingsUploadCan;

  /// No description provided for @flowReloadRefreshSettings.
  ///
  /// In zh, this message translates to:
  /// **'重新读取刷新配置'**
  String get flowReloadRefreshSettings;

  /// No description provided for @flowQuickSync.
  ///
  /// In zh, this message translates to:
  /// **'快速同步'**
  String get flowQuickSync;

  /// No description provided for @flowCheckingCachedUserCredentials.
  ///
  /// In zh, this message translates to:
  /// **'正在检查用户凭据缓存…'**
  String get flowCheckingCachedUserCredentials;

  /// No description provided for @flowCabinetIdentityLinkedNoQRNeededThis.
  ///
  /// In zh, this message translates to:
  /// **'已绑定机台身份，本次无需二维码'**
  String get flowCabinetIdentityLinkedNoQRNeededThis;

  /// No description provided for @flowChooseASyncSourceFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择同步数据源'**
  String get flowChooseASyncSourceFirst;

  /// No description provided for @flowEnterAQRToLinkCabinetIdentity.
  ///
  /// In zh, this message translates to:
  /// **'可直接输入二维码绑定机台身份'**
  String get flowEnterAQRToLinkCabinetIdentity;

  /// No description provided for @flowUserCredentialsCached.
  ///
  /// In zh, this message translates to:
  /// **'用户凭据已缓存'**
  String get flowUserCredentialsCached;

  /// No description provided for @flowUserCredentialsNotCached.
  ///
  /// In zh, this message translates to:
  /// **'用户凭据未缓存'**
  String get flowUserCredentialsNotCached;

  /// No description provided for @flowValidatingQRCode.
  ///
  /// In zh, this message translates to:
  /// **'正在验证二维码…'**
  String get flowValidatingQRCode;

  /// No description provided for @flowLinkCabinetIdentityUsingQR.
  ///
  /// In zh, this message translates to:
  /// **'输入二维码绑定机台身份'**
  String get flowLinkCabinetIdentityUsingQR;

  /// No description provided for @flowUpdatesAchievementAndDXScoresComboAnd.
  ///
  /// In zh, this message translates to:
  /// **'更新达成率与 DX 分数；连击、同步分别沿用各目标账号现有的标记。暂不更新宴谱和游玩次数。'**
  String get flowUpdatesAchievementAndDXScoresComboAnd;

  /// No description provided for @flowCouldNotDeleteCredentialsTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'用户凭据删除失败，请重试'**
  String get flowCouldNotDeleteCredentialsTryAgain;

  /// No description provided for @flowDeleteUserCredentials.
  ///
  /// In zh, this message translates to:
  /// **'删除用户凭据'**
  String get flowDeleteUserCredentials;

  /// No description provided for @flowAllThreeSourcesShareTheseCredentialsDeleting.
  ///
  /// In zh, this message translates to:
  /// **'三个数据源共用此凭据，删除时会关闭全部自动同步。'**
  String get flowAllThreeSourcesShareTheseCredentialsDeleting;

  /// No description provided for @flowCabinetIdentityCachedQuickSyncIsReady.
  ///
  /// In zh, this message translates to:
  /// **'机台身份已缓存，现在可以使用快速同步'**
  String get flowCabinetIdentityCachedQuickSyncIsReady;

  /// No description provided for @flowCouldNotLinkCabinetIdentityP0.
  ///
  /// In zh, this message translates to:
  /// **'绑定机台身份失败：{p0}'**
  String flowCouldNotLinkCabinetIdentityP0(String p0);

  /// No description provided for @flowReadsOnlyUserIdForQuickSyncDoes.
  ///
  /// In zh, this message translates to:
  /// **'只读取 userId 用于快速同步，不读取成绩，也不会执行普通同步。'**
  String get flowReadsOnlyUserIdForQuickSyncDoes;

  /// No description provided for @flowVerifyAndSave.
  ///
  /// In zh, this message translates to:
  /// **'验证并缓存'**
  String get flowVerifyAndSave;

  /// No description provided for @flowValidQRStringDetectedAndFilledIn.
  ///
  /// In zh, this message translates to:
  /// **'已识别到有效二维码字符串，已自动填入'**
  String get flowValidQRStringDetectedAndFilledIn;

  /// No description provided for @flowClipboardIsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'剪贴板为空'**
  String get flowClipboardIsEmpty;

  /// No description provided for @flowClipboardContentIsNotAValidLogin.
  ///
  /// In zh, this message translates to:
  /// **'剪贴板内容不是有效的登入二维码，仍要填入吗？'**
  String get flowClipboardContentIsNotAValidLogin;

  /// No description provided for @flowFillIn.
  ///
  /// In zh, this message translates to:
  /// **'填入'**
  String get flowFillIn;

  /// No description provided for @flowNoQRCodeFoundInTheImage.
  ///
  /// In zh, this message translates to:
  /// **'未在图片中检测到二维码'**
  String get flowNoQRCodeFoundInTheImage;

  /// No description provided for @flowCouldNotReadQRContentFromThe.
  ///
  /// In zh, this message translates to:
  /// **'未能从图片中识别到二维码内容'**
  String get flowCouldNotReadQRContentFromThe;

  /// No description provided for @flowQRCodeDetectedAndFilledIn.
  ///
  /// In zh, this message translates to:
  /// **'已识别到二维码，已自动填入'**
  String get flowQRCodeDetectedAndFilledIn;

  /// No description provided for @flowRecognitionFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'识别失败: {p0}'**
  String flowRecognitionFailedP0(String p0);

  /// No description provided for @flowScanFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'扫描失败: {p0}'**
  String flowScanFailedP0(String p0);

  /// No description provided for @flowReadClipboard.
  ///
  /// In zh, this message translates to:
  /// **'读取剪贴板'**
  String get flowReadClipboard;

  /// No description provided for @flowReadFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册识别'**
  String get flowReadFromGallery;

  /// No description provided for @flowScanQRCode.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码'**
  String get flowScanQRCode;

  /// No description provided for @flowCameraErrorP0.
  ///
  /// In zh, this message translates to:
  /// **'摄像头错误: {p0}'**
  String flowCameraErrorP0(String p0);

  /// No description provided for @flowBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get flowBack;

  /// No description provided for @flowCouldNotOpenTheLinkCopiedTo.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接，链接已复制到剪贴板，请手动粘贴到浏览器打开'**
  String get flowCouldNotOpenTheLinkCopiedTo;

  /// No description provided for @flowStillNoQQIDFoundCheckThat.
  ///
  /// In zh, this message translates to:
  /// **'还是没读到 QQ 号。请确认已在水鱼官网保存，或重新登录一次水鱼账号'**
  String get flowStillNoQQIDFoundCheckThat;

  /// No description provided for @flowLinkedQQFoundP0.
  ///
  /// In zh, this message translates to:
  /// **'已读到绑定 QQ：{p0}'**
  String flowLinkedQQFoundP0(String p0);

  /// No description provided for @flowNoQQIDFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到 QQ 号'**
  String get flowNoQQIDFound;

  /// No description provided for @flowAuthorizationOpenedReturnAfterAuthorizingAndTap.
  ///
  /// In zh, this message translates to:
  /// **'已打开授权页，完成授权后回到这里点「我已授权，重新检测」'**
  String get flowAuthorizationOpenedReturnAfterAuthorizingAndTap;

  /// No description provided for @flowAuthorizedYouCanNowRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'授权成功，现在可以刷新数据了'**
  String get flowAuthorizedYouCanNowRefreshData;

  /// No description provided for @flowAuthorizationNotDetectedApproveAccessInYour.
  ///
  /// In zh, this message translates to:
  /// **'还没检测到授权，请确认在浏览器里点了「同意」'**
  String get flowAuthorizationNotDetectedApproveAccessInYour;

  /// No description provided for @flowCheckFailedVerifyYourConnectionAndTry.
  ///
  /// In zh, this message translates to:
  /// **'检测失败，请检查网络后重试'**
  String get flowCheckFailedVerifyYourConnectionAndTry;

  /// No description provided for @flowCurrentDataSource.
  ///
  /// In zh, this message translates to:
  /// **'当前数据源：'**
  String get flowCurrentDataSource;

  /// No description provided for @flowConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get flowConfirm;

  /// No description provided for @flowLXNSAuthorizationSavedItRenewsAutomaticallyNo.
  ///
  /// In zh, this message translates to:
  /// **'已保存落雪授权，将自动续期，无需再次输入授权码。'**
  String get flowLXNSAuthorizationSavedItRenewsAutomaticallyNo;

  /// No description provided for @flowAuthorize2.
  ///
  /// In zh, this message translates to:
  /// **'点击授权'**
  String get flowAuthorize2;

  /// No description provided for @flowAuthorizationButtonNotWorking.
  ///
  /// In zh, this message translates to:
  /// **'点击授权没反应？'**
  String get flowAuthorizationButtonNotWorking;

  /// No description provided for @flowCopyThisLinkAndOpenItManually.
  ///
  /// In zh, this message translates to:
  /// **'请复制链接后在浏览器中手动打开完成授权：'**
  String get flowCopyThisLinkAndOpenItManually;

  /// No description provided for @flowCopyAuthorizationLink.
  ///
  /// In zh, this message translates to:
  /// **'复制授权链接'**
  String get flowCopyAuthorizationLink;

  /// No description provided for @flowAuthorizationLinkCopiedPasteItIntoYour.
  ///
  /// In zh, this message translates to:
  /// **'授权链接已复制，请在浏览器中粘贴打开'**
  String get flowAuthorizationLinkCopiedPasteItIntoYour;

  /// No description provided for @flowAfterAuthorizingCopyTheCodeShownOn.
  ///
  /// In zh, this message translates to:
  /// **'授权后复制页面上显示的授权码，粘贴到下方输入框'**
  String get flowAfterAuthorizingCopyTheCodeShownOn;

  /// No description provided for @flowEnterAuthorizationCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入授权码'**
  String get flowEnterAuthorizationCode;

  /// No description provided for @flowPasteAuthorizationCode.
  ///
  /// In zh, this message translates to:
  /// **'粘贴授权码'**
  String get flowPasteAuthorizationCode;

  /// No description provided for @flowQQID.
  ///
  /// In zh, this message translates to:
  /// **'QQ 号'**
  String get flowQQID;

  /// No description provided for @flowEnterAQQIDAlreadyLinkedOn.
  ///
  /// In zh, this message translates to:
  /// **'输入已在 AWMC NET 绑定过的 QQ 号'**
  String get flowEnterAQQIDAlreadyLinkedOn;

  /// No description provided for @flowNoSignInNeeded.
  ///
  /// In zh, this message translates to:
  /// **'无需登录'**
  String get flowNoSignInNeeded;

  /// No description provided for @flowAWMCNETIsAThirdPartyScore.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 是第三方查分器，按 QQ 号公开查询成绩，不用登录、也不用授权。\n前提是该 QQ 已在 net.wmc.pub 绑定并上传过成绩，否则会提示「没有该 QQ 的数据」。'**
  String get flowAWMCNETIsAThirdPartyScore;

  /// No description provided for @flowLinkQQUploadScoresOnAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'去 AWMC NET 绑定 / 上传成绩'**
  String get flowLinkQQUploadScoresOnAWMCNET;

  /// No description provided for @flowForceFullRefreshIgnoreStaticCaches.
  ///
  /// In zh, this message translates to:
  /// **'强制完整刷新（忽略静态数据缓存）'**
  String get flowForceFullRefreshIgnoreStaticCaches;

  /// No description provided for @flowMaidataStillUpdatesAsASeparateBackground.
  ///
  /// In zh, this message translates to:
  /// **'maidata 仍作为独立后台辅助任务更新'**
  String get flowMaidataStillUpdatesAsASeparateBackground;

  /// No description provided for @flowSignInThroughMeSignInTo.
  ///
  /// In zh, this message translates to:
  /// **'请先在「系统 → 登录水鱼」登录水鱼账号'**
  String get flowSignInThroughMeSignInTo;

  /// No description provided for @flowYourDivingFishAccountHasNoQQ.
  ///
  /// In zh, this message translates to:
  /// **'你的水鱼账号还没绑定 QQ 号，请先到水鱼官网「编辑个人资料」里填上'**
  String get flowYourDivingFishAccountHasNoQQ;

  /// No description provided for @flowEnterYourLXNSAuthorizationCodeFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先填写落雪授权码'**
  String get flowEnterYourLXNSAuthorizationCodeFirst;

  /// No description provided for @flowEnterYourAWMCNETQQID.
  ///
  /// In zh, this message translates to:
  /// **'请输入 AWMC NET 的 QQ 号'**
  String get flowEnterYourAWMCNETQQID;

  /// No description provided for @flowInvalidQQID512DigitsRequired.
  ///
  /// In zh, this message translates to:
  /// **'QQ 号格式不对（应为 5–12 位数字）'**
  String get flowInvalidQQID512DigitsRequired;

  /// No description provided for @flowCannotRefreshWithoutAConnectionConnectAnd.
  ///
  /// In zh, this message translates to:
  /// **'当前无网络连接，无法刷新数据。请联网后重试。'**
  String get flowCannotRefreshWithoutAConnectionConnectAnd;

  /// No description provided for @flowCouldNotOpenABrowserLinkCopied2.
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器，链接已复制到剪贴板，请手动粘贴到浏览器打开'**
  String get flowCouldNotOpenABrowserLinkCopied2;

  /// No description provided for @flowAWMCNETOffersPublicScoreLookupBy.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 按 QQ 号公开查询成绩，无需登录或授权。\n前提是该 QQ 已在 net.wmc.pub 绑定并上传过成绩。'**
  String get flowAWMCNETOffersPublicScoreLookupBy;

  /// No description provided for @flowForceRefreshCachedData.
  ///
  /// In zh, this message translates to:
  /// **'强制刷新缓存数据'**
  String get flowForceRefreshCachedData;

  /// No description provided for @flowDeselectAll.
  ///
  /// In zh, this message translates to:
  /// **'全不选'**
  String get flowDeselectAll;

  /// No description provided for @flowSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get flowSelectAll;

  /// No description provided for @flowSelectedCachesAreIgnoredAndFetchedFrom.
  ///
  /// In zh, this message translates to:
  /// **'勾选 = 在本次刷新中忽略该缓存，强制走网络；未勾选 = 命中缓存则跳过。'**
  String get flowSelectedCachesAreIgnoredAndFetchedFrom;

  /// No description provided for @flowLoading2.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get flowLoading2;

  /// No description provided for @flowConnectedP0P1Ms.
  ///
  /// In zh, this message translates to:
  /// **'连通：{p0} · {p1}ms'**
  String flowConnectedP0P1Ms(String p0, String p1);

  /// No description provided for @flowFailedP0P1Ms.
  ///
  /// In zh, this message translates to:
  /// **'失败：{p0} ({p1}ms)'**
  String flowFailedP0P1Ms(String p0, String p1);

  /// No description provided for @flowTest.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get flowTest;

  /// No description provided for @flowRoute.
  ///
  /// In zh, this message translates to:
  /// **'线路'**
  String get flowRoute;

  /// No description provided for @flowP0LastRefreshFailedShowingOlderData.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 上次刷新失败，显示的是旧数据'**
  String flowP0LastRefreshFailedShowingOlderData(String p0);

  /// No description provided for @flowP0Last100P1SamplesAvgP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}近100次 / {p1}样本 / 平均{p2} / 成功{p3}%'**
  String flowP0Last100P1SamplesAvgP2(
      String p0, String p1, String p2, String p3);

  /// No description provided for @flowSyncStatistics.
  ///
  /// In zh, this message translates to:
  /// **'同步统计'**
  String get flowSyncStatistics;

  /// No description provided for @flowTracksDurationAndOutcomeForTheLatest.
  ///
  /// In zh, this message translates to:
  /// **'记录最近 {p0} 次同步的耗时与成败（所有使用者共享，仅含耗时/成败，不含二维码与账号信息）。'**
  String flowTracksDurationAndOutcomeForTheLatest(String p0);

  /// No description provided for @flowNormalSyncP0.
  ///
  /// In zh, this message translates to:
  /// **'普通同步 · {p0}'**
  String flowNormalSyncP0(String p0);

  /// No description provided for @flowStatisticsUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'统计不可用'**
  String get flowStatisticsUnavailable;

  /// No description provided for @flowNoRecordsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无记录'**
  String get flowNoRecordsYet;

  /// No description provided for @flowFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get flowFailed;

  /// No description provided for @flowP0P1UsersQueuedP2ItemsProcessing.
  ///
  /// In zh, this message translates to:
  /// **'{p0}排队用户 {p1} 人 · 处理中 {p2} 项'**
  String flowP0P1UsersQueuedP2ItemsProcessing(String p0, String p1, String p2);

  /// No description provided for @flowP0P1ChinaTime.
  ///
  /// In zh, this message translates to:
  /// **'\n{p0}：{p1}（北京时间）'**
  String flowP0P1ChinaTime(String p0, String p1);

  /// No description provided for @flowDifficultyFilter.
  ///
  /// In zh, this message translates to:
  /// **'难度筛选'**
  String get flowDifficultyFilter;

  /// No description provided for @flowRecentSearches.
  ///
  /// In zh, this message translates to:
  /// **'最近搜索'**
  String get flowRecentSearches;

  /// No description provided for @flowEG137Or134.
  ///
  /// In zh, this message translates to:
  /// **'如 13.7 或 13.4-14'**
  String get flowEG137Or134;

  /// No description provided for @flowClearP0Constant.
  ///
  /// In zh, this message translates to:
  /// **'清空{p0}定数'**
  String flowClearP0Constant(String p0);

  /// No description provided for @flowEveryEnteredDifficultyMustMatchBlankFields.
  ///
  /// In zh, this message translates to:
  /// **'填写的难度须全部满足，留空不限制。与上方「难度」及其它筛选条件取交集。'**
  String get flowEveryEnteredDifficultyMustMatchBlankFields;

  /// No description provided for @flowUTAGEIsFilledInSoNormalDifficulties.
  ///
  /// In zh, this message translates to:
  /// **'已填写 UTAGE，普通难度暂不可用；清空后恢复。'**
  String get flowUTAGEIsFilledInSoNormalDifficulties;

  /// No description provided for @flowNormalDifficultiesAreFilledInSoUTAGE.
  ///
  /// In zh, this message translates to:
  /// **'已填写普通难度，UTAGE 暂不可用；全部清空后恢复。'**
  String get flowNormalDifficultiesAreFilledInSoUTAGE;

  /// No description provided for @flowConstantFilter.
  ///
  /// In zh, this message translates to:
  /// **'定数筛选'**
  String get flowConstantFilter;

  /// No description provided for @flowAnyDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'任意难度'**
  String get flowAnyDifficulty;

  /// No description provided for @flowDifficultyCombination.
  ///
  /// In zh, this message translates to:
  /// **'按难度组合'**
  String get flowDifficultyCombination;

  /// No description provided for @flowClearConstants.
  ///
  /// In zh, this message translates to:
  /// **'清空定数'**
  String get flowClearConstants;

  /// No description provided for @flowMinimum.
  ///
  /// In zh, this message translates to:
  /// **'最小值'**
  String get flowMinimum;

  /// No description provided for @flowMaximum.
  ///
  /// In zh, this message translates to:
  /// **'最大值'**
  String get flowMaximum;

  /// No description provided for @flowNoteCountFilter.
  ///
  /// In zh, this message translates to:
  /// **'物量筛选'**
  String get flowNoteCountFilter;

  /// No description provided for @flowMinimumNotes.
  ///
  /// In zh, this message translates to:
  /// **'最少物量'**
  String get flowMinimumNotes;

  /// No description provided for @flowMaximumNotes.
  ///
  /// In zh, this message translates to:
  /// **'最多物量'**
  String get flowMaximumNotes;

  /// No description provided for @flowBPMFilter.
  ///
  /// In zh, this message translates to:
  /// **'BPM筛选'**
  String get flowBPMFilter;

  /// No description provided for @flowMinimumBPM.
  ///
  /// In zh, this message translates to:
  /// **'最小 BPM'**
  String get flowMinimumBPM;

  /// No description provided for @flowMaximumBPM.
  ///
  /// In zh, this message translates to:
  /// **'最大 BPM'**
  String get flowMaximumBPM;

  /// No description provided for @flowVersionFilter.
  ///
  /// In zh, this message translates to:
  /// **'版本筛选'**
  String get flowVersionFilter;

  /// No description provided for @flowGenreFilter.
  ///
  /// In zh, this message translates to:
  /// **'流派筛选'**
  String get flowGenreFilter;

  /// No description provided for @flowTagFilter.
  ///
  /// In zh, this message translates to:
  /// **'标签筛选'**
  String get flowTagFilter;

  /// No description provided for @flowNoTagData.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签数据'**
  String get flowNoTagData;

  /// No description provided for @flowCharterFilter.
  ///
  /// In zh, this message translates to:
  /// **'谱师筛选'**
  String get flowCharterFilter;

  /// No description provided for @flowArtistFilter.
  ///
  /// In zh, this message translates to:
  /// **'曲师筛选'**
  String get flowArtistFilter;

  /// No description provided for @flowClearSelection.
  ///
  /// In zh, this message translates to:
  /// **'清除选择'**
  String get flowClearSelection;

  /// No description provided for @flowLevelP0.
  ///
  /// In zh, this message translates to:
  /// **'等级 {p0}'**
  String flowLevelP0(String p0);

  /// No description provided for @flowDXChartsOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅 DX 谱面'**
  String get flowDXChartsOnly;

  /// No description provided for @flowTitlesOnly.
  ///
  /// In zh, this message translates to:
  /// **'只搜歌名'**
  String get flowTitlesOnly;

  /// No description provided for @flowSearching.
  ///
  /// In zh, this message translates to:
  /// **'正在搜索...'**
  String get flowSearching;

  /// No description provided for @flowEnterASearchKeyword.
  ///
  /// In zh, this message translates to:
  /// **'请输入搜索关键词'**
  String get flowEnterASearchKeyword;

  /// No description provided for @flowP0SongsInTheLibraryEnterA.
  ///
  /// In zh, this message translates to:
  /// **'曲库共 {p0} 首，请输入搜索关键词'**
  String flowP0SongsInTheLibraryEnterA(String p0);

  /// No description provided for @flowP0SongsFound15PerPage.
  ///
  /// In zh, this message translates to:
  /// **'找到 {p0} 首乐曲，每页 15 首'**
  String flowP0SongsFound15PerPage(String p0);

  /// No description provided for @flowReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get flowReset;

  /// No description provided for @flowNoSongsMatchTheseFilters.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的歌曲'**
  String get flowNoSongsMatchTheseFilters;

  /// No description provided for @flowTryAWiderConstantRangeOrClear.
  ///
  /// In zh, this message translates to:
  /// **'试试放宽定数或清空筛选'**
  String get flowTryAWiderConstantRangeOrClear;

  /// No description provided for @flowPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get flowPrevious;

  /// No description provided for @flowNext.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get flowNext;

  /// No description provided for @flowCoverIndexReadyProcessedP0Covers.
  ///
  /// In zh, this message translates to:
  /// **'曲绘索引建立完成！共处理 {p0} 张曲绘'**
  String flowCoverIndexReadyProcessedP0Covers(String p0);

  /// No description provided for @flowCouldNotBuildIndexP0.
  ///
  /// In zh, this message translates to:
  /// **'索引建立失败: {p0}'**
  String flowCouldNotBuildIndexP0(String p0);

  /// No description provided for @flowChooseImageSource.
  ///
  /// In zh, this message translates to:
  /// **'选择图片来源'**
  String get flowChooseImageSource;

  /// No description provided for @flowTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get flowTakePhoto;

  /// No description provided for @flowPhotographCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'使用相机拍摄曲绘'**
  String get flowPhotographCoverArt;

  /// No description provided for @flowChooseACoverScreenshotFromYourGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册中选取曲绘截图'**
  String get flowChooseACoverScreenshotFromYourGallery;

  /// No description provided for @flowCameraPermissionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限'**
  String get flowCameraPermissionRequired;

  /// No description provided for @flowCouldNotSelectImageP0.
  ///
  /// In zh, this message translates to:
  /// **'选取图片失败: {p0}'**
  String flowCouldNotSelectImageP0(String p0);

  /// No description provided for @flowRecognitionFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'识别失败，请重试'**
  String get flowRecognitionFailedTryAgain;

  /// No description provided for @flowRecognitionErrorP0.
  ///
  /// In zh, this message translates to:
  /// **'识别出错: {p0}'**
  String flowRecognitionErrorP0(String p0);

  /// No description provided for @flowRebuildCoverIndex.
  ///
  /// In zh, this message translates to:
  /// **'重建曲绘索引'**
  String get flowRebuildCoverIndex;

  /// No description provided for @flowThisClearsTheIndexAndRecalculatesHashes.
  ///
  /// In zh, this message translates to:
  /// **'将清除现有索引并重新为全部曲绘计算哈希。这可能需要数十秒，确定继续吗？'**
  String get flowThisClearsTheIndexAndRecalculatesHashes;

  /// No description provided for @flowRebuild.
  ///
  /// In zh, this message translates to:
  /// **'确定重建'**
  String get flowRebuild;

  /// No description provided for @flowLoading3.
  ///
  /// In zh, this message translates to:
  /// **'正在加载...'**
  String get flowLoading3;

  /// No description provided for @flowBuildingCoverIndex.
  ///
  /// In zh, this message translates to:
  /// **'正在建立曲绘索引...'**
  String get flowBuildingCoverIndex;

  /// No description provided for @flowComputingFeaturesForP0Covers.
  ///
  /// In zh, this message translates to:
  /// **'为 {p0} 张曲绘计算特征'**
  String flowComputingFeaturesForP0Covers(String p0);

  /// No description provided for @flowNeededOnlyOncePleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'仅首次需要，请耐心等待'**
  String get flowNeededOnlyOncePleaseWait;

  /// No description provided for @flowTakeOrChooseACoverImage.
  ///
  /// In zh, this message translates to:
  /// **'拍摄或选择一张曲绘图片'**
  String get flowTakeOrChooseACoverImage;

  /// No description provided for @flowCropTheCoverRegionAfterSelectingFor.
  ///
  /// In zh, this message translates to:
  /// **'选取后可手动框选曲绘区域，提高识别准确率'**
  String get flowCropTheCoverRegionAfterSelectingFor;

  /// No description provided for @flowImageReady.
  ///
  /// In zh, this message translates to:
  /// **'图片已就绪'**
  String get flowImageReady;

  /// No description provided for @flowMatchConfidenceIsTooLowThisMay.
  ///
  /// In zh, this message translates to:
  /// **'匹配度过低，可能不是曲绘照片，请重新框选裁剪区域后再试'**
  String get flowMatchConfidenceIsTooLowThisMay;

  /// No description provided for @flowInputImage.
  ///
  /// In zh, this message translates to:
  /// **'输入图片'**
  String get flowInputImage;

  /// No description provided for @flowMatchedCover.
  ///
  /// In zh, this message translates to:
  /// **'匹配曲绘'**
  String get flowMatchedCover;

  /// No description provided for @flowCombinedMatchUnreliable.
  ///
  /// In zh, this message translates to:
  /// **'综合匹配（不可靠）'**
  String get flowCombinedMatchUnreliable;

  /// No description provided for @flowCombinedMatch.
  ///
  /// In zh, this message translates to:
  /// **'综合匹配'**
  String get flowCombinedMatch;

  /// No description provided for @flowTop10Matches.
  ///
  /// In zh, this message translates to:
  /// **'识别结果 Top 10'**
  String get flowTop10Matches;

  /// No description provided for @flowSongP0.
  ///
  /// In zh, this message translates to:
  /// **'歌曲 #{p0}'**
  String flowSongP0(String p0);

  /// No description provided for @flowChooseImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get flowChooseImage;

  /// No description provided for @flowRecognizing.
  ///
  /// In zh, this message translates to:
  /// **'识别中...'**
  String get flowRecognizing;

  /// No description provided for @flowStartRecognition.
  ///
  /// In zh, this message translates to:
  /// **'开始识别'**
  String get flowStartRecognition;

  /// No description provided for @flowCropAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新裁剪'**
  String get flowCropAgain;

  /// No description provided for @flowChooseAgain.
  ///
  /// In zh, this message translates to:
  /// **'重选'**
  String get flowChooseAgain;

  /// No description provided for @flowRecognizeAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新识别'**
  String get flowRecognizeAgain;

  /// No description provided for @flowChooseAnother.
  ///
  /// In zh, this message translates to:
  /// **'再选一张'**
  String get flowChooseAnother;

  /// No description provided for @flowCoverIndexReady.
  ///
  /// In zh, this message translates to:
  /// **'曲绘索引就绪'**
  String get flowCoverIndexReady;

  /// No description provided for @flowIndexNotBuilt.
  ///
  /// In zh, this message translates to:
  /// **'索引未建立'**
  String get flowIndexNotBuilt;

  /// No description provided for @flowRebuildIndex.
  ///
  /// In zh, this message translates to:
  /// **'重建索引'**
  String get flowRebuildIndex;

  /// No description provided for @flowCannotReadThisImageTryAnother.
  ///
  /// In zh, this message translates to:
  /// **'图片无法读取，请换一张图片重试'**
  String get flowCannotReadThisImageTryAnother;

  /// No description provided for @flowCropFailedContinuingWithTheOriginalImage.
  ///
  /// In zh, this message translates to:
  /// **'裁剪失败，将使用原图继续'**
  String get flowCropFailedContinuingWithTheOriginalImage;

  /// No description provided for @flowDragTheCornersToSelectCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'拖动角点框选曲绘区域'**
  String get flowDragTheCornersToSelectCoverArt;

  /// No description provided for @flowProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get flowProcessing;

  /// No description provided for @flowDragCornersToResizeDragInsideTo.
  ///
  /// In zh, this message translates to:
  /// **'拖拽四角调整范围  |  拖拽框内移动位置'**
  String get flowDragCornersToResizeDragInsideTo;

  /// No description provided for @flowNoDivingFishImportTokenSignIn.
  ///
  /// In zh, this message translates to:
  /// **'还没有水鱼 Import-Token，请先到「登录水鱼」完成登录'**
  String get flowNoDivingFishImportTokenSignIn;

  /// No description provided for @flowAddedToDivingFishP0.
  ///
  /// In zh, this message translates to:
  /// **'已新增到水鱼：{p0}'**
  String flowAddedToDivingFishP0(String p0);

  /// No description provided for @flowDivingFishScoreUpdatedP0.
  ///
  /// In zh, this message translates to:
  /// **'已更新水鱼成绩：{p0}'**
  String flowDivingFishScoreUpdatedP0(String p0);

  /// No description provided for @flowCannotParseSongIDForLXNSSync.
  ///
  /// In zh, this message translates to:
  /// **'无法解析曲目 ID，不能同步到落雪'**
  String get flowCannotParseSongIDForLXNSSync;

  /// No description provided for @flowNoLXNSPersonalAPIKeySetIt.
  ///
  /// In zh, this message translates to:
  /// **'还没有落雪个人 API 密钥，请先到「成绩导入凭据」填写'**
  String get flowNoLXNSPersonalAPIKeySetIt;

  /// No description provided for @flowPhotographTheCabinetResultScreen.
  ///
  /// In zh, this message translates to:
  /// **'对着机台结算页面拍一张'**
  String get flowPhotographTheCabinetResultScreen;

  /// No description provided for @flowChooseAPhotographedResultScreen.
  ///
  /// In zh, this message translates to:
  /// **'选取已经拍好的结算画面'**
  String get flowChooseAPhotographedResultScreen;

  /// No description provided for @flowNoScoreRecognizedCropCloserToThe.
  ///
  /// In zh, this message translates to:
  /// **'没有识别出成绩，可裁剪得更贴近结算区域后重试'**
  String get flowNoScoreRecognizedCropCloserToThe;

  /// No description provided for @flowCorrectRecognitionResults.
  ///
  /// In zh, this message translates to:
  /// **'修正识别结果'**
  String get flowCorrectRecognitionResults;

  /// No description provided for @flowRecognitionIsNotAlwaysAccurateEditedValues.
  ///
  /// In zh, this message translates to:
  /// **'识别不可能百分百准确，这里改过的值会直接替换卡片上的显示'**
  String get flowRecognitionIsNotAlwaysAccurateEditedValues;

  /// No description provided for @flowDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'难度'**
  String get flowDifficulty;

  /// No description provided for @flowSelectASongFirstToListIts.
  ///
  /// In zh, this message translates to:
  /// **'先选定一首歌曲，才能列出它实际有的难度'**
  String get flowSelectASongFirstToListIts;

  /// No description provided for @flowConstantP0.
  ///
  /// In zh, this message translates to:
  /// **'定数 {p0}'**
  String flowConstantP0(String p0);

  /// No description provided for @flowConstantP02.
  ///
  /// In zh, this message translates to:
  /// **' · 定数 {p0}'**
  String flowConstantP02(String p0);

  /// No description provided for @flowAchievement.
  ///
  /// In zh, this message translates to:
  /// **'达成率 (%)'**
  String get flowAchievement;

  /// No description provided for @flowDXScore.
  ///
  /// In zh, this message translates to:
  /// **'DX 分数'**
  String get flowDXScore;

  /// No description provided for @flowCombo.
  ///
  /// In zh, this message translates to:
  /// **'连击'**
  String get flowCombo;

  /// No description provided for @flowSync.
  ///
  /// In zh, this message translates to:
  /// **'同步'**
  String get flowSync;

  /// No description provided for @flowEmptyMeansNoMarkerSyncMarkersUse.
  ///
  /// In zh, this message translates to:
  /// **'「空」表示不设置该标记。同步标记会按水鱼的值域提交（FS / FS+ / FDX / FDX+ / SYNC）。'**
  String get flowEmptyMeansNoMarkerSyncMarkersUse;

  /// No description provided for @flowRestoreRecognizedValues.
  ///
  /// In zh, this message translates to:
  /// **'恢复为识别结果'**
  String get flowRestoreRecognizedValues;

  /// No description provided for @flowEmpty.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get flowEmpty;

  /// No description provided for @flowNoSongData.
  ///
  /// In zh, this message translates to:
  /// **'暂无歌曲数据'**
  String get flowNoSongData;

  /// No description provided for @flowNoMatchingSong.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的歌曲'**
  String get flowNoMatchingSong;

  /// No description provided for @flowRecognizingScores.
  ///
  /// In zh, this message translates to:
  /// **'正在识别成绩'**
  String get flowRecognizingScores;

  /// No description provided for @flowMatchingCoverArtAndTitlesUsuallyTakes.
  ///
  /// In zh, this message translates to:
  /// **'曲绘 + 标题双路匹配，通常需要几秒'**
  String get flowMatchingCoverArtAndTitlesUsuallyTakes;

  /// No description provided for @flowPhotographACabinetResultScreen.
  ///
  /// In zh, this message translates to:
  /// **'对着机台结算页面拍一张照片'**
  String get flowPhotographACabinetResultScreen;

  /// No description provided for @flowRecognizesTitleAchievementDXScoreDifficultyAnd.
  ///
  /// In zh, this message translates to:
  /// **'自动识别曲名、达成率、DX 分数、难度与 FC/FS'**
  String get flowRecognizesTitleAchievementDXScoreDifficultyAnd;

  /// No description provided for @flowImageReadyTapStartRecognitionBelow.
  ///
  /// In zh, this message translates to:
  /// **'图片已就绪，点击下方「开始识别」'**
  String get flowImageReadyTapStartRecognitionBelow;

  /// No description provided for @flowRecognitionCompleteP0P1Succeeded.
  ///
  /// In zh, this message translates to:
  /// **'识别完成 · {p0}/{p1} 张成功'**
  String flowRecognitionCompleteP0P1Succeeded(String p0, String p1);

  /// No description provided for @flowCouldNotRecognizeAScore.
  ///
  /// In zh, this message translates to:
  /// **'未能识别出成绩'**
  String get flowCouldNotRecognizeAScore;

  /// No description provided for @flowSongTitleNotRecognized.
  ///
  /// In zh, this message translates to:
  /// **'未识别出曲名'**
  String get flowSongTitleNotRecognized;

  /// No description provided for @flowAchievement2.
  ///
  /// In zh, this message translates to:
  /// **'达成率'**
  String get flowAchievement2;

  /// No description provided for @flowMatchSourceP0.
  ///
  /// In zh, this message translates to:
  /// **'命中来源：{p0}'**
  String flowMatchSourceP0(String p0);

  /// No description provided for @flowEditThisResult.
  ///
  /// In zh, this message translates to:
  /// **'编辑此项'**
  String get flowEditThisResult;

  /// No description provided for @flowSyncing.
  ///
  /// In zh, this message translates to:
  /// **'同步中...'**
  String get flowSyncing;

  /// No description provided for @flowSyncToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'同步到水鱼'**
  String get flowSyncToDivingFish;

  /// No description provided for @flowSyncToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'同步到落雪'**
  String get flowSyncToLXNS;

  /// No description provided for @flowCannotSyncYetP0.
  ///
  /// In zh, this message translates to:
  /// **'暂不能同步：{p0}'**
  String flowCannotSyncYetP0(String p0);

  /// No description provided for @flowOtherCandidatesP0.
  ///
  /// In zh, this message translates to:
  /// **'其它候选：{p0}'**
  String flowOtherCandidatesP0(String p0);

  /// No description provided for @flowRecognizeAgain2.
  ///
  /// In zh, this message translates to:
  /// **'再次识别'**
  String get flowRecognizeAgain2;

  /// No description provided for @flowUseAnotherImage.
  ///
  /// In zh, this message translates to:
  /// **'换一张'**
  String get flowUseAnotherImage;

  /// No description provided for @flowClearAndChooseAgain.
  ///
  /// In zh, this message translates to:
  /// **'清除重选'**
  String get flowClearAndChooseAgain;

  /// No description provided for @flowSignInToMaimaiScoreHubFirst.
  ///
  /// In zh, this message translates to:
  /// **'先登录 maimai Score Hub'**
  String get flowSignInToMaimaiScoreHubFirst;

  /// No description provided for @flowResultRecognitionRequiresSignInRequestA.
  ///
  /// In zh, this message translates to:
  /// **'识别结算画面需要登录。在舞萌 | 中二公众号请求并打开登入二维码，扫描后把字符串填到下面。只用来认证，不会抓取或同步成绩；登录状态保存在本机，之后不用重复登录。'**
  String get flowResultRecognitionRequiresSignInRequestA;

  /// No description provided for @flowSigningIn2.
  ///
  /// In zh, this message translates to:
  /// **'登录中…'**
  String get flowSigningIn2;

  /// No description provided for @flowDragCornersToSelectTheResultArea.
  ///
  /// In zh, this message translates to:
  /// **'拖动角点框选成绩区域'**
  String get flowDragCornersToSelectTheResultArea;

  /// No description provided for @flowStoragePermissionIsNeededToSaveVersion.
  ///
  /// In zh, this message translates to:
  /// **'需要存储权限才能保存版本图，请在设置中开启权限'**
  String get flowStoragePermissionIsNeededToSaveVersion;

  /// No description provided for @flowImageSavedToGallery.
  ///
  /// In zh, this message translates to:
  /// **'图片已保存到相册'**
  String get flowImageSavedToGallery;

  /// No description provided for @flowSaveFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{p0}'**
  String flowSaveFailedP0(String p0);

  /// No description provided for @flowSaveImage.
  ///
  /// In zh, this message translates to:
  /// **'保存图片'**
  String get flowSaveImage;

  /// No description provided for @flowJapan.
  ///
  /// In zh, this message translates to:
  /// **'日服'**
  String get flowJapan;

  /// No description provided for @flowChina.
  ///
  /// In zh, this message translates to:
  /// **'国服'**
  String get flowChina;

  /// No description provided for @flowJapanVersion.
  ///
  /// In zh, this message translates to:
  /// **'日服版本'**
  String get flowJapanVersion;

  /// No description provided for @flowChinaVersion.
  ///
  /// In zh, this message translates to:
  /// **'国服版本'**
  String get flowChinaVersion;

  /// No description provided for @flowP0VersionsInReleaseOrderTapAn.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 个版本，按发行顺序排列。点击版本图可放大查看或保存。'**
  String flowP0VersionsInReleaseOrderTapAn(String p0);

  /// No description provided for @flowP0VersionImageNotAvailableYet.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，版本图待补充'**
  String flowP0VersionImageNotAvailableYet(String p0);

  /// No description provided for @flowP0ViewVersionImage.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，点击查看版本图'**
  String flowP0ViewVersionImage(String p0);

  /// No description provided for @flowImagePending.
  ///
  /// In zh, this message translates to:
  /// **'图片待补'**
  String get flowImagePending;

  /// No description provided for @flowVersionImageNotAvailableYet.
  ///
  /// In zh, this message translates to:
  /// **'等待补充版本图'**
  String get flowVersionImageNotAvailableYet;

  /// No description provided for @flowTapToEnlarge.
  ///
  /// In zh, this message translates to:
  /// **'点击查看大图'**
  String get flowTapToEnlarge;

  /// No description provided for @flowAboutThisComparison.
  ///
  /// In zh, this message translates to:
  /// **'口径说明'**
  String get flowAboutThisComparison;

  /// No description provided for @flowNoSongsInThisSection.
  ///
  /// In zh, this message translates to:
  /// **'这一段里没有曲目'**
  String get flowNoSongsInThisSection;

  /// No description provided for @flowChinaDivingFishUpdateFrontier.
  ///
  /// In zh, this message translates to:
  /// **'国服（水鱼）更新前沿'**
  String get flowChinaDivingFishUpdateFrontier;

  /// No description provided for @flowJapanDebutP0P1.
  ///
  /// In zh, this message translates to:
  /// **'日服首发 {p0} · {p1}'**
  String flowJapanDebutP0P1(String p0, String p1);

  /// No description provided for @flowFirstReleaseMeansTheJapanReleaseDate.
  ///
  /// In zh, this message translates to:
  /// **'「首次上线」显示的是日服首发时间，不是国服上线时间。候选按首发日期识别，并从已确认待补批次补齐遗漏；日期缺失时才参考 ID，较小 ID 的新曲也会纳入。'**
  String get flowFirstReleaseMeansTheJapanReleaseDate;

  /// No description provided for @flowExcludedP0SongsReleasedEarlyInChina.
  ///
  /// In zh, this message translates to:
  /// **'已排除 {p0} 首国服超前上线曲目（{p1}）—— 它们会把前沿顶高，让真正待补的曲子排不进候选。'**
  String flowExcludedP0SongsReleasedEarlyInChina(String p0, String p1);

  /// No description provided for @flowP0P1JapanP2.
  ///
  /// In zh, this message translates to:
  /// **'#{p0} · {p1} · 日服 {p2}'**
  String flowP0P1JapanP2(String p0, String p1, String p2);

  /// No description provided for @flowNoCachedLibraryYet.
  ///
  /// In zh, this message translates to:
  /// **'曲库还没有缓存'**
  String get flowNoCachedLibraryYet;

  /// No description provided for @flowThisPageUsesTheLocalDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'本页的数据来自本地曲库（水鱼 + union）。\n请先在首页执行一次「拉取成绩并更新数据」，把曲库拉下来后再回来查看。'**
  String get flowThisPageUsesTheLocalDivingFish;

  /// No description provided for @flowHowThisPageWorks.
  ///
  /// In zh, this message translates to:
  /// **'这个页面的口径'**
  String get flowHowThisPageWorks;

  /// No description provided for @flow1DataSources.
  ///
  /// In zh, this message translates to:
  /// **'1. 数据来源'**
  String get flow1DataSources;

  /// No description provided for @flowTheLocalLibraryCombinesDivingFishAll.
  ///
  /// In zh, this message translates to:
  /// **'本地曲库 = 水鱼（国服全量歌曲）+ union（全量歌曲）。合并时 union 独有的那批会打上 isExtra 标记，本页据此区分来源；已确认的国服超前上线名单优先于这个标记。所以整个页面离线可用，与网络无关。'**
  String get flowTheLocalLibraryCombinesDivingFishAll;

  /// No description provided for @flow2DefiningTheUpdateFrontier.
  ///
  /// In zh, this message translates to:
  /// **'2. 更新前沿怎么定'**
  String get flow2DefiningTheUpdateFrontier;

  /// No description provided for @flowRegularChinaSongsInDivingFishAre.
  ///
  /// In zh, this message translates to:
  /// **'先筛出水鱼曲库里的国服常规曲，再按首发日期从新到旧排列，第一首作为「国服最新」。日期缺失或格式异常时参考 ID，所以这条前沿近似等于「国服已经追到哪」。\n宴会场（6 位 id）与 maidata 追加曲不参与判定。\n国服**超前上线**的曲目（国服先于日服上，id 却排最新）也不参与 —— 它们会把前沿顶高，让真正待补的曲子排不进候选。'**
  String get flowRegularChinaSongsInDivingFishAre;

  /// No description provided for @flow3CompletingTheCandidateList.
  ///
  /// In zh, this message translates to:
  /// **'3. 候选怎么补齐'**
  String get flow3CompletingTheCandidateList;

  /// No description provided for @flowStartWithUnionOnlyRegularSongsUsing.
  ///
  /// In zh, this message translates to:
  /// **'先取 union 独有的常规曲，以前沿的日服首发日期作为参考起点；如果已确认待补批次中仍有更早的未收录曲目，起点下移至该批最早日期。\n· 首发不早于起点的曲目都纳入，包含同一天以及 ID 较小的歌曲；\n· 日期缺失或异常时才按 ID 判断，已确认待补曲始终保留；\n· 早于起点的旧曲单独列出，不据此断定区域独占；候选只是参考，实际更新以官方公告为准。'**
  String get flowStartWithUnionOnlyRegularSongsUsing;

  /// No description provided for @flow4WhatFirstReleaseMeans.
  ///
  /// In zh, this message translates to:
  /// **'4. 「首次上线」是什么时间'**
  String get flow4WhatFirstReleaseMeans;

  /// No description provided for @flowTheDebutDatesFromDivingFishAnd.
  ///
  /// In zh, this message translates to:
  /// **'水鱼与 union 提供的首发日期都是**日服**时间，不是国服上线时间 —— 这也是「曲目详情页显示首次上线、却看不出国服上没上」的原因。'**
  String get flowTheDebutDatesFromDivingFishAnd;

  /// No description provided for @flowUpdateDataTemporarilyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时读不到更新数据'**
  String get flowUpdateDataTemporarilyUnavailable;

  /// No description provided for @flowRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get flowRetry;

  /// No description provided for @flowReleaseContents.
  ///
  /// In zh, this message translates to:
  /// **'配信内容'**
  String get flowReleaseContents;

  /// No description provided for @flowCouldNotLoadReleaseDataRetry.
  ///
  /// In zh, this message translates to:
  /// **'配信数据读取失败，重试'**
  String get flowCouldNotLoadReleaseDataRetry;

  /// No description provided for @flowNoContentDetails.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容明细'**
  String get flowNoContentDetails;

  /// No description provided for @flowP0OtherItemsNotShown.
  ///
  /// In zh, this message translates to:
  /// **'其余 {p0} 项未列出'**
  String flowP0OtherItemsNotShown(String p0);

  /// No description provided for @flowLXNSMaimaiDXScoreTracker.
  ///
  /// In zh, this message translates to:
  /// **'落雪咖啡屋 maimai DX 查分器'**
  String get flowLXNSMaimaiDXScoreTracker;

  /// No description provided for @flowPreviousMonthWithUpdates.
  ///
  /// In zh, this message translates to:
  /// **'上一个有更新的月份'**
  String get flowPreviousMonthWithUpdates;

  /// No description provided for @flowChooseYearAndMonthCurrentP0P1.
  ///
  /// In zh, this message translates to:
  /// **'选择年月，当前 {p0} 年 {p1} 月'**
  String flowChooseYearAndMonthCurrentP0P1(String p0, String p1);

  /// No description provided for @flowP0P1.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 年 {p1} 月'**
  String flowP0P1(String p0, String p1);

  /// No description provided for @flowReleaseRecordOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅有配信记录'**
  String get flowReleaseRecordOnly;

  /// No description provided for @flowP0UpdatesP1Songs.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 次更新 {p1} 首歌曲'**
  String flowP0UpdatesP1Songs(String p0, String p1);

  /// No description provided for @flowNextMonthWithUpdates.
  ///
  /// In zh, this message translates to:
  /// **'下一个有更新的月份'**
  String get flowNextMonthWithUpdates;

  /// No description provided for @flowRelease.
  ///
  /// In zh, this message translates to:
  /// **'配信'**
  String get flowRelease;

  /// No description provided for @flowP0P1P2P3.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 月 {p1} 日{p2}{p3}'**
  String flowP0P1P2P3(String p0, String p1, String p2, String p3);

  /// No description provided for @flowP0Songs.
  ///
  /// In zh, this message translates to:
  /// **'，{p0} 首歌曲'**
  String flowP0Songs(String p0);

  /// No description provided for @flowReleaseRecorded.
  ///
  /// In zh, this message translates to:
  /// **'，有配信记录'**
  String get flowReleaseRecorded;

  /// No description provided for @flowNotReleasedYet.
  ///
  /// In zh, this message translates to:
  /// **'  尚未上线'**
  String get flowNotReleasedYet;

  /// No description provided for @flowReleaseRecord.
  ///
  /// In zh, this message translates to:
  /// **'配信记录'**
  String get flowReleaseRecord;

  /// No description provided for @flowP0SongsP1Charts.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 首歌曲 {p1} 张谱面'**
  String flowP0SongsP1Charts(String p0, String p1);

  /// No description provided for @flowMonthP0.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 月'**
  String flowMonthP0(String p0);

  /// No description provided for @flowChooseYearAndMonth.
  ///
  /// In zh, this message translates to:
  /// **'选择年月'**
  String get flowChooseYearAndMonth;

  /// No description provided for @flowYearP0.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 年'**
  String flowYearP0(String p0);

  /// No description provided for @flowNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get flowNoData;

  /// No description provided for @flowLvP0P1SongsP2Played.
  ///
  /// In zh, this message translates to:
  /// **'Lv.{p0}\n共 {p1} 首\n已玩 {p2} 首'**
  String flowLvP0P1SongsP2Played(String p0, String p1, String p2);

  /// No description provided for @flowLvP0P1P2Songs.
  ///
  /// In zh, this message translates to:
  /// **'Lv.{p0} {p1} (共 {p2} 首)'**
  String flowLvP0P1P2Songs(String p0, String p1, String p2);

  /// No description provided for @flowFilterTitleBackgroundColors.
  ///
  /// In zh, this message translates to:
  /// **'筛选称号底色'**
  String get flowFilterTitleBackgroundColors;

  /// No description provided for @flowChooseMultipleColors.
  ///
  /// In zh, this message translates to:
  /// **'可同时选择多个底色'**
  String get flowChooseMultipleColors;

  /// No description provided for @flowApply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get flowApply;

  /// No description provided for @flowCacheClearedReloading.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清除，重新加载数据中...'**
  String get flowCacheClearedReloading;

  /// No description provided for @flowCouldNotClearCache.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存失败'**
  String get flowCouldNotClearCache;

  /// No description provided for @flowSearchCollectibleNamesDescriptionsOrIDs.
  ///
  /// In zh, this message translates to:
  /// **'搜索收藏品名称、描述或 ID'**
  String get flowSearchCollectibleNamesDescriptionsOrIDs;

  /// No description provided for @flowSongRequirements.
  ///
  /// In zh, this message translates to:
  /// **'有歌曲要求'**
  String get flowSongRequirements;

  /// No description provided for @flowBackgroundColor.
  ///
  /// In zh, this message translates to:
  /// **'底色'**
  String get flowBackgroundColor;

  /// No description provided for @flowIDDescending.
  ///
  /// In zh, this message translates to:
  /// **'ID 倒序'**
  String get flowIDDescending;

  /// No description provided for @flowIDAscending.
  ///
  /// In zh, this message translates to:
  /// **'ID 正序'**
  String get flowIDAscending;

  /// No description provided for @flowP0Items.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个'**
  String flowP0Items(String p0);

  /// No description provided for @flowHasUnlockRequirements.
  ///
  /// In zh, this message translates to:
  /// **'有达成条件'**
  String get flowHasUnlockRequirements;

  /// No description provided for @flowNoMatchingCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的收藏品'**
  String get flowNoMatchingCollectibles;

  /// No description provided for @flowClearCacheAndReload.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存并重新加载'**
  String get flowClearCacheAndReload;

  /// No description provided for @flowPermissionRequired.
  ///
  /// In zh, this message translates to:
  /// **'权限不足'**
  String get flowPermissionRequired;

  /// No description provided for @flowStoragePermissionIsNeededToSaveImages.
  ///
  /// In zh, this message translates to:
  /// **'需要存储权限才能保存图片到相册，请在设置中开启权限'**
  String get flowStoragePermissionIsNeededToSaveImages;

  /// No description provided for @flowExcludedSongs.
  ///
  /// In zh, this message translates to:
  /// **'条件外排除曲目'**
  String get flowExcludedSongs;

  /// No description provided for @flowP0SongsExcludedFromRequirements.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 首，不计入所需条件'**
  String flowP0SongsExcludedFromRequirements(String p0);

  /// No description provided for @flowSongList.
  ///
  /// In zh, this message translates to:
  /// **'歌曲列表'**
  String get flowSongList;

  /// No description provided for @flowP0SongsTotal.
  ///
  /// In zh, this message translates to:
  /// **'总计 {p0} 首歌曲'**
  String flowP0SongsTotal(String p0);

  /// No description provided for @flowTranslatedFromP0ByBaiduSLanguage.
  ///
  /// In zh, this message translates to:
  /// **'由百度大模型翻译自{p0}'**
  String flowTranslatedFromP0ByBaiduSLanguage(String p0);

  /// No description provided for @flowTranslateToChinese.
  ///
  /// In zh, this message translates to:
  /// **'翻译为中文'**
  String get flowTranslateToChinese;

  /// No description provided for @flowSaving2.
  ///
  /// In zh, this message translates to:
  /// **'保存中'**
  String get flowSaving2;

  /// No description provided for @flowSaveToGallery.
  ///
  /// In zh, this message translates to:
  /// **'保存到相册'**
  String get flowSaveToGallery;

  /// No description provided for @flowCopyLink.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get flowCopyLink;

  /// No description provided for @flowDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get flowDescription;

  /// No description provided for @flowUnlockRequirements.
  ///
  /// In zh, this message translates to:
  /// **'所需条件'**
  String get flowUnlockRequirements;

  /// No description provided for @flowP0Details.
  ///
  /// In zh, this message translates to:
  /// **'{p0}详情'**
  String flowP0Details(String p0);

  /// No description provided for @flowCollectibleNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到收藏品信息'**
  String get flowCollectibleNotFound;

  /// No description provided for @flowCouldNotRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据失败'**
  String get flowCouldNotRefreshData;

  /// No description provided for @flowQQP0HasNotAuthorizedThisApp.
  ///
  /// In zh, this message translates to:
  /// **'QQ {p0} 尚未授权本应用，请稍后在「账号与同步」中完成授权'**
  String flowQQP0HasNotAuthorizedThisApp(String p0);

  /// No description provided for @flowAuthorizationNeeded.
  ///
  /// In zh, this message translates to:
  /// **'需要完成授权'**
  String get flowAuthorizationNeeded;

  /// No description provided for @flowThisQQHasNotAuthorizedTheApp.
  ///
  /// In zh, this message translates to:
  /// **'该 QQ 尚未授权本应用，已打开授权页；授权完成后请重新刷新'**
  String get flowThisQQHasNotAuthorizedTheApp;

  /// No description provided for @flowThisQQHasNotAuthorizedTheApp2.
  ///
  /// In zh, this message translates to:
  /// **'该 QQ 尚未授权本应用，请在浏览器中打开授权页完成绑定'**
  String get flowThisQQHasNotAuthorizedTheApp2;

  /// No description provided for @flowCouldNotRefreshDataP0.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据失败：{p0}'**
  String flowCouldNotRefreshDataP0(String p0);

  /// No description provided for @flowSigningOutOfDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'正在登出水鱼账号…'**
  String get flowSigningOutOfDivingFish;

  /// No description provided for @flowEnterYourDivingFishUsernameAndPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入水鱼用户名和密码'**
  String get flowEnterYourDivingFishUsernameAndPassword;

  /// No description provided for @flowCouldNotLinkDivingFishTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'绑定水鱼账号失败，请稍后重试'**
  String get flowCouldNotLinkDivingFishTryAgain;

  /// No description provided for @flowSyncSucceededRefreshingLocalData.
  ///
  /// In zh, this message translates to:
  /// **'同步成功！正在刷新本地数据...'**
  String get flowSyncSucceededRefreshingLocalData;

  /// No description provided for @flowExportFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'导出失败，请稍后重试'**
  String get flowExportFailedTryAgain;

  /// No description provided for @flowPreparingSync.
  ///
  /// In zh, this message translates to:
  /// **'准备同步...'**
  String get flowPreparingSync;

  /// No description provided for @flowP0ScoresSentToDivingFishSign.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！{p0} 条成绩已推送到水鱼\n（需先登录水鱼才能自动刷新本地数据）'**
  String flowP0ScoresSentToDivingFishSign(String p0);

  /// No description provided for @flowSyncCancelled.
  ///
  /// In zh, this message translates to:
  /// **'同步已取消'**
  String get flowSyncCancelled;

  /// No description provided for @flowEnterUsernameAndPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入用户名和密码'**
  String get flowEnterUsernameAndPassword;

  /// No description provided for @flowWelcomeP0P1.
  ///
  /// In zh, this message translates to:
  /// **'欢迎，{p0}{p1}'**
  String flowWelcomeP0P1(String p0, String p1);

  /// No description provided for @flowAdvancedDataRefreshInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在刷新数据（高级）...'**
  String get flowAdvancedDataRefreshInProgress;

  /// No description provided for @flowRefreshingData.
  ///
  /// In zh, this message translates to:
  /// **'正在刷新数据...'**
  String get flowRefreshingData;

  /// No description provided for @flowCouldNotLoadAccountDetailsP0.
  ///
  /// In zh, this message translates to:
  /// **'获取账号信息失败 ({p0})'**
  String flowCouldNotLoadAccountDetailsP0(String p0);

  /// No description provided for @flowNickname.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get flowNickname;

  /// No description provided for @flowVersionTitle.
  ///
  /// In zh, this message translates to:
  /// **'牌子'**
  String get flowVersionTitle;

  /// No description provided for @flowRatingRank.
  ///
  /// In zh, this message translates to:
  /// **'Rating段位'**
  String get flowRatingRank;

  /// No description provided for @flowLinkedQQ.
  ///
  /// In zh, this message translates to:
  /// **'绑定QQ'**
  String get flowLinkedQQ;

  /// No description provided for @flowChannelID.
  ///
  /// In zh, this message translates to:
  /// **'频道ID'**
  String get flowChannelID;

  /// No description provided for @flowBeginner.
  ///
  /// In zh, this message translates to:
  /// **'初学者'**
  String get flowBeginner;

  /// No description provided for @flow1stDan.
  ///
  /// In zh, this message translates to:
  /// **'一段'**
  String get flow1stDan;

  /// No description provided for @flow2ndDan.
  ///
  /// In zh, this message translates to:
  /// **'二段'**
  String get flow2ndDan;

  /// No description provided for @flow3rdDan.
  ///
  /// In zh, this message translates to:
  /// **'三段'**
  String get flow3rdDan;

  /// No description provided for @flow4thDan.
  ///
  /// In zh, this message translates to:
  /// **'四段'**
  String get flow4thDan;

  /// No description provided for @flow5thDan.
  ///
  /// In zh, this message translates to:
  /// **'五段'**
  String get flow5thDan;

  /// No description provided for @flow6thDan.
  ///
  /// In zh, this message translates to:
  /// **'六段'**
  String get flow6thDan;

  /// No description provided for @flow7thDan.
  ///
  /// In zh, this message translates to:
  /// **'七段'**
  String get flow7thDan;

  /// No description provided for @flow8thDan.
  ///
  /// In zh, this message translates to:
  /// **'八段'**
  String get flow8thDan;

  /// No description provided for @flow9thDan.
  ///
  /// In zh, this message translates to:
  /// **'九段'**
  String get flow9thDan;

  /// No description provided for @flow10thDan.
  ///
  /// In zh, this message translates to:
  /// **'十段'**
  String get flow10thDan;

  /// No description provided for @flowShin1stDan.
  ///
  /// In zh, this message translates to:
  /// **'真初段'**
  String get flowShin1stDan;

  /// No description provided for @flowShin2ndDan.
  ///
  /// In zh, this message translates to:
  /// **'真二段'**
  String get flowShin2ndDan;

  /// No description provided for @flowShin3rdDan.
  ///
  /// In zh, this message translates to:
  /// **'真三段'**
  String get flowShin3rdDan;

  /// No description provided for @flowShin4thDan.
  ///
  /// In zh, this message translates to:
  /// **'真四段'**
  String get flowShin4thDan;

  /// No description provided for @flowShin5thDan.
  ///
  /// In zh, this message translates to:
  /// **'真五段'**
  String get flowShin5thDan;

  /// No description provided for @flowShin6thDan.
  ///
  /// In zh, this message translates to:
  /// **'真六段'**
  String get flowShin6thDan;

  /// No description provided for @flowShin7thDan.
  ///
  /// In zh, this message translates to:
  /// **'真七段'**
  String get flowShin7thDan;

  /// No description provided for @flowShin8thDan.
  ///
  /// In zh, this message translates to:
  /// **'真八段'**
  String get flowShin8thDan;

  /// No description provided for @flowShin9thDan.
  ///
  /// In zh, this message translates to:
  /// **'真九段'**
  String get flowShin9thDan;

  /// No description provided for @flowShin10thDan.
  ///
  /// In zh, this message translates to:
  /// **'真十段'**
  String get flowShin10thDan;

  /// No description provided for @flowShinKaiden.
  ///
  /// In zh, this message translates to:
  /// **'真皆传'**
  String get flowShinKaiden;

  /// No description provided for @flowUraKaiden.
  ///
  /// In zh, this message translates to:
  /// **'里皆传'**
  String get flowUraKaiden;

  /// No description provided for @flowRefreshingMaidata.
  ///
  /// In zh, this message translates to:
  /// **'正在刷新maidata...'**
  String get flowRefreshingMaidata;

  /// No description provided for @flowCouldNotOpenQQGroupIDP0.
  ///
  /// In zh, this message translates to:
  /// **'没能跳转到 QQ，群号 {p0} 已复制到剪贴板，可在 QQ 里搜索加入'**
  String flowCouldNotOpenQQGroupIDP0(String p0);

  /// No description provided for @flowSongSearchFailedTheLibraryMayNot.
  ///
  /// In zh, this message translates to:
  /// **'歌曲搜索失败，曲库可能还没加载好'**
  String get flowSongSearchFailedTheLibraryMayNot;

  /// No description provided for @flowPreparingToReadCabinetPlayCount.
  ///
  /// In zh, this message translates to:
  /// **'准备读取机台游玩次数…'**
  String get flowPreparingToReadCabinetPlayCount;

  /// No description provided for @flowSigningOutOfDivingFish2.
  ///
  /// In zh, this message translates to:
  /// **'正在登出水鱼账号...'**
  String get flowSigningOutOfDivingFish2;

  /// No description provided for @flowStartQRSyncFromHome.
  ///
  /// In zh, this message translates to:
  /// **'请从首页的同步入口开始扫码同步'**
  String get flowStartQRSyncFromHome;

  /// No description provided for @flowStartSyncFromHome.
  ///
  /// In zh, this message translates to:
  /// **'请从首页的同步入口开始同步'**
  String get flowStartSyncFromHome;

  /// No description provided for @flowEnterYourPersonalKeyAboveToEnable.
  ///
  /// In zh, this message translates to:
  /// **'填好上面的个人 key 后就可以开启'**
  String get flowEnterYourPersonalKeyAboveToEnable;

  /// No description provided for @flowNoP0AccountYetSignInThrough.
  ///
  /// In zh, this message translates to:
  /// **'还没有{p0}账号，请先到「绑定与授权管理」登录并刷新数据'**
  String flowNoP0AccountYetSignInThrough(String p0);

  /// No description provided for @flowSyncCredentialsReady.
  ///
  /// In zh, this message translates to:
  /// **'同步凭据已就绪'**
  String get flowSyncCredentialsReady;

  /// No description provided for @flowLinkTheCabinetIdentityAboveToEnable.
  ///
  /// In zh, this message translates to:
  /// **'绑定上方的机台身份后就可以开启'**
  String get flowLinkTheCabinetIdentityAboveToEnable;

  /// No description provided for @flowCouldNotReadSyncCredentialsTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'同步凭据读取失败，请重试'**
  String get flowCouldNotReadSyncCredentialsTryAgain;

  /// No description provided for @flowCouldNotReadAutoSyncStatusTry.
  ///
  /// In zh, this message translates to:
  /// **'自动同步状态读取失败，请重试'**
  String get flowCouldNotReadAutoSyncStatusTry;

  /// No description provided for @flowLinkCabinetIdentityAboveFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先在上方绑定机台身份'**
  String get flowLinkCabinetIdentityAboveFirst;

  /// No description provided for @flowSyncSetupIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'同步配置待完善'**
  String get flowSyncSetupIncomplete;

  /// No description provided for @flowAccountEndingInP0.
  ///
  /// In zh, this message translates to:
  /// **'账号尾号 {p0}'**
  String flowAccountEndingInP0(String p0);

  /// No description provided for @flowStatusNotConfirmedYet.
  ///
  /// In zh, this message translates to:
  /// **'状态暂未确认'**
  String get flowStatusNotConfirmedYet;

  /// No description provided for @flowP0QueueUserPositionP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}排队 · 用户第 {p1} 位'**
  String flowP0QueueUserPositionP1(String p0, String p1);

  /// No description provided for @flowEnabledWaitingForSchedule.
  ///
  /// In zh, this message translates to:
  /// **'已开启 · 等待定时执行'**
  String get flowEnabledWaitingForSchedule;

  /// No description provided for @flowSyncing2.
  ///
  /// In zh, this message translates to:
  /// **'正在同步'**
  String get flowSyncing2;

  /// No description provided for @flowPreviousRoundNoRunYet.
  ///
  /// In zh, this message translates to:
  /// **'上轮 · 暂无执行记录'**
  String get flowPreviousRoundNoRunYet;

  /// No description provided for @flowPreviousRoundUpToDateNoUpload.
  ///
  /// In zh, this message translates to:
  /// **'上轮已是最新 · 无需上传'**
  String get flowPreviousRoundUpToDateNoUpload;

  /// No description provided for @flowPreviousRoundCompleteSubmittedP0.
  ///
  /// In zh, this message translates to:
  /// **'上轮已完成 · 提交 {p0} 条'**
  String flowPreviousRoundCompleteSubmittedP0(String p0);

  /// No description provided for @flowPreviousRoundIncompleteP0.
  ///
  /// In zh, this message translates to:
  /// **'上轮未完成{p0}'**
  String flowPreviousRoundIncompleteP0(String p0);

  /// No description provided for @flowSubmittedP0.
  ///
  /// In zh, this message translates to:
  /// **' · 已提交 {p0} 条'**
  String flowSubmittedP0(String p0);

  /// No description provided for @flowPreviousRoundP0.
  ///
  /// In zh, this message translates to:
  /// **'上轮 · {p0}'**
  String flowPreviousRoundP0(String p0);

  /// No description provided for @flowLoadingStatistics.
  ///
  /// In zh, this message translates to:
  /// **'统计加载中'**
  String get flowLoadingStatistics;

  /// No description provided for @flowUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败'**
  String get flowUpdateFailed;

  /// No description provided for @flowUpdatesEvery3Seconds.
  ///
  /// In zh, this message translates to:
  /// **'每 3 秒更新'**
  String get flowUpdatesEvery3Seconds;

  /// No description provided for @flowQueuedUsers.
  ///
  /// In zh, this message translates to:
  /// **'排队人数'**
  String get flowQueuedUsers;

  /// No description provided for @flowPendingTasks.
  ///
  /// In zh, this message translates to:
  /// **'待处理任务'**
  String get flowPendingTasks;

  /// No description provided for @flowProcessing2.
  ///
  /// In zh, this message translates to:
  /// **'处理中'**
  String get flowProcessing2;

  /// No description provided for @flowProcessedUsers.
  ///
  /// In zh, this message translates to:
  /// **'已处理用户'**
  String get flowProcessedUsers;

  /// No description provided for @flowSuccessfulUsers.
  ///
  /// In zh, this message translates to:
  /// **'成功用户'**
  String get flowSuccessfulUsers;

  /// No description provided for @flowFailedUsers.
  ///
  /// In zh, this message translates to:
  /// **'失败用户'**
  String get flowFailedUsers;

  /// No description provided for @flowSubmittedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'已提交 {p0} 条{p1}'**
  String flowSubmittedP0P1(String p0, String p1);

  /// No description provided for @flowSkippedP0UnsupportedCharts.
  ///
  /// In zh, this message translates to:
  /// **'，跳过 {p0} 条不支持的谱面'**
  String flowSkippedP0UnsupportedCharts(String p0);

  /// No description provided for @flowConfirmedP0Submitted.
  ///
  /// In zh, this message translates to:
  /// **'（已确认提交 {p0} 条）'**
  String flowConfirmedP0Submitted(String p0);

  /// No description provided for @flowWaitingForScheduledRun.
  ///
  /// In zh, this message translates to:
  /// **'等待定时执行'**
  String get flowWaitingForScheduledRun;

  /// No description provided for @flowWaitingToBeScheduled.
  ///
  /// In zh, this message translates to:
  /// **'等待安排'**
  String get flowWaitingToBeScheduled;

  /// No description provided for @flowEnterACabinetLoginQRCodeFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先填写机台登入二维码'**
  String get flowEnterACabinetLoginQRCodeFirst;

  /// No description provided for @flowLinkFailedCheckTheQRHasNot.
  ///
  /// In zh, this message translates to:
  /// **'绑定失败，请确认二维码未过期后重试'**
  String get flowLinkFailedCheckTheQRHasNot;

  /// No description provided for @flowEnterYourPersonalKeyFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先填写个人 key'**
  String get flowEnterYourPersonalKeyFirst;

  /// No description provided for @flowAccountChangedRefreshThisPageAndEnter.
  ///
  /// In zh, this message translates to:
  /// **'账号已变化，请刷新页面后重新填写'**
  String get flowAccountChangedRefreshThisPageAndEnter;

  /// No description provided for @flow1SignInThroughMeSignIn.
  ///
  /// In zh, this message translates to:
  /// **'① 在「我的 → 绑定与授权管理」登录水鱼，输入你的 Diving-Fish 水鱼账号密码以获取 ImportToken。\n② 打开「成绩导入凭据 → 水鱼 成绩导入Token」，点击复制。\n③ 回到这里粘贴并保存。'**
  String get flow1SignInThroughMeSignIn;

  /// No description provided for @flowQuickSyncing.
  ///
  /// In zh, this message translates to:
  /// **'正在快速同步…'**
  String get flowQuickSyncing;

  /// No description provided for @flowCheckingAWMCGateway.
  ///
  /// In zh, this message translates to:
  /// **'正在检查 AWMC 网关...'**
  String get flowCheckingAWMCGateway;

  /// No description provided for @flowAWMCGatewayUnavailableP0SyncCancelledNo.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关当前不可用（{p0}），已取消同步、未消耗 Token'**
  String flowAWMCGatewayUnavailableP0SyncCancelledNo(String p0);

  /// No description provided for @flowSyncingToP0ThroughAWMCGateway.
  ///
  /// In zh, this message translates to:
  /// **'正在通过 AWMC 网关同步到{p0}...'**
  String flowSyncingToP0ThroughAWMCGateway(String p0);

  /// No description provided for @flowP0ScoresAreUpToDateNo.
  ///
  /// In zh, this message translates to:
  /// **'{p0}成绩已是最新，无需上传'**
  String flowP0ScoresAreUpToDateNo(String p0);

  /// No description provided for @flowQuickSyncCompleteSubmittedP1ChangedScores.
  ///
  /// In zh, this message translates to:
  /// **'快速同步完成，已向{p0}提交 {p1} 条变化成绩'**
  String flowQuickSyncCompleteSubmittedP1ChangedScores(String p0, String p1);

  /// No description provided for @flowP0ScoresTotal.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 条成绩'**
  String flowP0ScoresTotal(String p0);

  /// No description provided for @flowSentToDivingFishThroughAWMCGateway.
  ///
  /// In zh, this message translates to:
  /// **'已通过 AWMC 网关推送到水鱼'**
  String get flowSentToDivingFishThroughAWMCGateway;

  /// No description provided for @flowExportedToLXNSThroughAWMCGateway.
  ///
  /// In zh, this message translates to:
  /// **'已通过 AWMC 网关导出到落雪'**
  String get flowExportedToLXNSThroughAWMCGateway;

  /// No description provided for @flowSyncCompleteP0P1.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！{p0}{p1}'**
  String flowSyncCompleteP0P1(String p0, String p1);

  /// No description provided for @flowNoCachedDivingFishImportTokenSignIn.
  ///
  /// In zh, this message translates to:
  /// **'本机还没有缓存水鱼 ImportToken：请先用线路2（maimai Score Hub）登录并同步一次，它会自动把 ImportToken 存到本机。'**
  String get flowNoCachedDivingFishImportTokenSignIn;

  /// No description provided for @flowNoCachedLXNSPersonalAPIKeySync.
  ///
  /// In zh, this message translates to:
  /// **'本机还没有缓存落雪个人 API 密钥：请先同步一次并填好密钥（会保存在本机）。'**
  String get flowNoCachedLXNSPersonalAPIKeySync;

  /// No description provided for @flowReadingCabinetPlayCount.
  ///
  /// In zh, this message translates to:
  /// **'正在读取机台游玩次数…'**
  String get flowReadingCabinetPlayCount;

  /// No description provided for @flowEndpoint.
  ///
  /// In zh, this message translates to:
  /// **'接口'**
  String get flowEndpoint;

  /// No description provided for @flowResult.
  ///
  /// In zh, this message translates to:
  /// **'结果'**
  String get flowResult;

  /// No description provided for @flowBusinessOperationSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'业务成功'**
  String get flowBusinessOperationSucceeded;

  /// No description provided for @flowUpstreamMessageTruncatedFullLengthP0Characters.
  ///
  /// In zh, this message translates to:
  /// **'上游 msg 过长已截断（完整 {p0} 字符）'**
  String flowUpstreamMessageTruncatedFullLengthP0Characters(String p0);

  /// No description provided for @flowDuration.
  ///
  /// In zh, this message translates to:
  /// **'耗时'**
  String get flowDuration;

  /// No description provided for @flowBilling.
  ///
  /// In zh, this message translates to:
  /// **'计费'**
  String get flowBilling;

  /// No description provided for @flowGetThisTokenFromTheAWMCConsole.
  ///
  /// In zh, this message translates to:
  /// **'令牌来自 AWMC 控制台（api.wmc.pub），形如 gw_xxxx。\n\n⚠️ 令牌等同于你的账户操作权限与余额，请勿截图、勿粘贴到聊天/公开仓库。若怀疑泄露，请立即到控制台吊销并重新生成。'**
  String get flowGetThisTokenFromTheAWMCConsole;

  /// No description provided for @flowTokenStaysOnThisDeviceCanBe.
  ///
  /// In zh, this message translates to:
  /// **'令牌保存在本机（可随时清除），不会随备份导出。'**
  String get flowTokenStaysOnThisDeviceCanBe;

  /// No description provided for @flowEnterCabinetQRCode.
  ///
  /// In zh, this message translates to:
  /// **'输入机台二维码'**
  String get flowEnterCabinetQRCode;

  /// No description provided for @flowUsedOnlyForThisOperationThenDiscarded.
  ///
  /// In zh, this message translates to:
  /// **'本次输入只用于这一次操作，用完即弃：不保存、不缓存；下一次操作会重新问你一次。'**
  String get flowUsedOnlyForThisOperationThenDiscarded;

  /// No description provided for @flowUse.
  ///
  /// In zh, this message translates to:
  /// **'使用'**
  String get flowUse;

  /// No description provided for @flowThisKeyIsSentOnlyWithThis.
  ///
  /// In zh, this message translates to:
  /// **'该密钥只会随本次请求发送给 AWMC 网关转发，不会保存在本机。'**
  String get flowThisKeyIsSentOnlyWithThis;

  /// No description provided for @flowContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get flowContinue;

  /// No description provided for @flowTokenCost.
  ///
  /// In zh, this message translates to:
  /// **'Token 消耗'**
  String get flowTokenCost;

  /// No description provided for @flowP0ChargedOnlyOnSuccess.
  ///
  /// In zh, this message translates to:
  /// **'{p0}（成功才扣）'**
  String flowP0ChargedOnlyOnSuccess(String p0);

  /// No description provided for @flowNoTokenSpent.
  ///
  /// In zh, this message translates to:
  /// **'不消耗'**
  String get flowNoTokenSpent;

  /// No description provided for @flowReversible.
  ///
  /// In zh, this message translates to:
  /// **'可撤销'**
  String get flowReversible;

  /// No description provided for @flowYesUploadAgainToOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'可以（重新上传即可覆盖）'**
  String get flowYesUploadAgainToOverwrite;

  /// No description provided for @flowNo.
  ///
  /// In zh, this message translates to:
  /// **'不可以'**
  String get flowNo;

  /// No description provided for @flowIUnderstandTheEffectsAboveAndConfirm.
  ///
  /// In zh, this message translates to:
  /// **'我已确认上述影响，并确认这是我自己账号的二维码'**
  String get flowIUnderstandTheEffectsAboveAndConfirm;

  /// No description provided for @flowWrite.
  ///
  /// In zh, this message translates to:
  /// **'写入'**
  String get flowWrite;

  /// No description provided for @flowImportingScoresWaitingP0Seconds.
  ///
  /// In zh, this message translates to:
  /// **'正在导入成绩…已等待 {p0} 秒'**
  String flowImportingScoresWaitingP0Seconds(String p0);

  /// No description provided for @flowImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get flowImportFailed;

  /// No description provided for @flowScoresAreUpToDateNoUpload.
  ///
  /// In zh, this message translates to:
  /// **'成绩已是最新，无需上传'**
  String get flowScoresAreUpToDateNoUpload;

  /// No description provided for @flowQuickSyncCompleteSubmittedP0ChangedScores.
  ///
  /// In zh, this message translates to:
  /// **'快速同步完成，已提交 {p0} 条变化成绩'**
  String flowQuickSyncCompleteSubmittedP0ChangedScores(String p0);

  /// No description provided for @flowImportCompleteAddedP0UpdatedP1.
  ///
  /// In zh, this message translates to:
  /// **'导入完成！新增 {p0} / 更新 {p1}'**
  String flowImportCompleteAddedP0UpdatedP1(String p0, String p1);

  /// No description provided for @flowSkippedP0.
  ///
  /// In zh, this message translates to:
  /// **' / 跳过 {p0}'**
  String flowSkippedP0(String p0);

  /// No description provided for @flowP0Seconds.
  ///
  /// In zh, this message translates to:
  /// **'（{p0} 秒）'**
  String flowP0Seconds(String p0);

  /// No description provided for @flowP0ChartsAreNotYetInAWMC.
  ///
  /// In zh, this message translates to:
  /// **'；{p0} 条谱面 AWMC NET 暂未收录'**
  String flowP0ChartsAreNotYetInAWMC(String p0);

  /// No description provided for @flowP0Account.
  ///
  /// In zh, this message translates to:
  /// **'{p0}账号'**
  String flowP0Account(String p0);

  /// No description provided for @flowNotLinked.
  ///
  /// In zh, this message translates to:
  /// **'未绑定'**
  String get flowNotLinked;

  /// No description provided for @flowThenChooseRegisterUnderQuickActionsOn.
  ///
  /// In zh, this message translates to:
  /// **'，点击右侧“快捷操作”区域的“注册”。'**
  String get flowThenChooseRegisterUnderQuickActionsOn;

  /// No description provided for @flowFollowThePageInstructionsToRegisterA.
  ///
  /// In zh, this message translates to:
  /// **'随页面引导填写信息，即可注册水鱼账号。'**
  String get flowFollowThePageInstructionsToRegisterA;

  /// No description provided for @flowAfterSigningInOpenEditProfileAt.
  ///
  /// In zh, this message translates to:
  /// **'登录后点页面右上角的“编辑个人资料”，按下面的说明设置：'**
  String get flowAfterSigningInOpenEditProfileAt;

  /// No description provided for @flowScoreImportTokenRotateItUsingThe.
  ///
  /// In zh, this message translates to:
  /// **'成绩导入 Token：必须轮换！点 Token 右边的刷新图标即可，否则无法在 App 内登录。'**
  String get flowScoreImportTokenRotateItUsingThe;

  /// No description provided for @flowLinkedQQRequiredAvoidUsingTheSame.
  ///
  /// In zh, this message translates to:
  /// **'绑定 QQ 号：必须填写。如果有小号，尽量不要和小号重复。'**
  String get flowLinkedQQRequiredAvoidUsingTheSame;

  /// No description provided for @flowNicknameRecommendedWithoutOneTheAppSaves.
  ///
  /// In zh, this message translates to:
  /// **'昵称：建议填写。不填的话，App 内会默认以“shuiyu:QQ 号”的形式保存。'**
  String get flowNicknameRecommendedWithoutOneTheAppSaves;

  /// No description provided for @flowChannelIDAndRankNoSpecificRequirements.
  ///
  /// In zh, this message translates to:
  /// **'绑定频道 ID 和段位：没有特别要求。'**
  String get flowChannelIDAndRankNoSpecificRequirements;

  /// No description provided for @flowDisablePreventPublicAPIsFromUsingMy.
  ///
  /// In zh, this message translates to:
  /// **'“禁止公开接口使用我的成绩”：必须关闭。'**
  String get flowDisablePreventPublicAPIsFromUsingMy;

  /// No description provided for @flowDisableMaskingScoresForNonWebQueries.
  ///
  /// In zh, this message translates to:
  /// **'“对非网页查询的成绩使用掩码”：建议关闭，开启掩码会影响排行榜排名。'**
  String get flowDisableMaskingScoresForNonWebQueries;

  /// No description provided for @flowRememberToSaveAfterMakingChanges.
  ///
  /// In zh, this message translates to:
  /// **'全部改好后，记得点“保存”。'**
  String get flowRememberToSaveAfterMakingChanges;

  /// No description provided for @flowThenChooseNewUserRegistrationInThe.
  ///
  /// In zh, this message translates to:
  /// **'，点击左侧边栏的“新用户注册”或页面中间处的“注册 maimai DX 查分器账号”。'**
  String get flowThenChooseNewUserRegistrationInThe;

  /// No description provided for @flowFollowThePageInstructionsToRegisterAn.
  ///
  /// In zh, this message translates to:
  /// **'随页面引导填写信息，即可注册落雪咖啡屋账号。'**
  String get flowFollowThePageInstructionsToRegisterAn;

  /// No description provided for @flowAfterSigningInOpenAccountDetailsIn.
  ///
  /// In zh, this message translates to:
  /// **'登录后在侧边栏点“账号详情”，再点页面上方的“第三方应用”：'**
  String get flowAfterSigningInOpenAccountDetailsIn;

  /// No description provided for @flowOAuthInMeRefreshDataChooseLXNS.
  ///
  /// In zh, this message translates to:
  /// **'OAuth 授权：在 App 的“我的 → 数据刷新 → 拉取成绩并更新数据 / 拉取成绩并更新数据（高级）”对话框里把数据源切换到落雪，按引导完成授权。授权后，这里的 OAuth 应用列表会出现 ChiffonMai。'**
  String get flowOAuthInMeRefreshDataChooseLXNS;

  /// No description provided for @flowPersonalAPIKeyResetItThenPaste.
  ///
  /// In zh, this message translates to:
  /// **'个人 API 密钥：点“重置 API 密钥”，然后到 App 的“我的 → 成绩导入凭据”，下滑找到“落雪 API 密钥”并填入。'**
  String get flowPersonalAPIKeyResetItThenPaste;

  /// No description provided for @flowYouCanAlsoVisitChiffonChuFromThe.
  ///
  /// In zh, this message translates to:
  /// **'也欢迎支持一下中二查歌，在“首页游玩 → 出勤”的轮播图里可以跳转过去。'**
  String get flowYouCanAlsoVisitChiffonChuFromThe;

  /// No description provided for @flowMessage.
  ///
  /// In zh, this message translates to:
  /// **'私聊 '**
  String get flowMessage;

  /// No description provided for @flowPrivatelyOrFollowTheseStepsInA.
  ///
  /// In zh, this message translates to:
  /// **'，或在有机器人的群中，依次完成以下步骤：'**
  String get flowPrivatelyOrFollowTheseStepsInA;

  /// No description provided for @flowSendTheSGWCMAIDStringOrMaimaiQR.
  ///
  /// In zh, this message translates to:
  /// **'按提示发送 SGWCMAID 字符串或舞萌二维码，等机器人回复上传完成就好了。'**
  String get flowSendTheSGWCMAIDStringOrMaimaiQR;

  /// No description provided for @flowAndConfigureTheseSettings.
  ///
  /// In zh, this message translates to:
  /// **'，按下面的说明设置：'**
  String get flowAndConfigureTheseSettings;

  /// No description provided for @flowEnableMakeMyScoresPublicOrScores.
  ///
  /// In zh, this message translates to:
  /// **'“公开我的成绩”：必须开启，否则无法获取成绩。'**
  String get flowEnableMakeMyScoresPublicOrScores;

  /// No description provided for @flowImportTokenRegenerateItThenPasteIt.
  ///
  /// In zh, this message translates to:
  /// **'Import-Token：点“重新生成”轮换，然后到 App 的“我的 → 账号与授权 → 成绩导入凭据”，在对话框里下滑到“AWMC 成绩导入 Token”并填入。'**
  String get flowImportTokenRegenerateItThenPasteIt;

  /// No description provided for @flowRotatingATokenReplacesTheOldOne.
  ///
  /// In zh, this message translates to:
  /// **'注意：已有 Token 时，轮换会覆盖之前的 Token。轮换后请在 App 内手动更新，否则无法同步成绩。'**
  String get flowRotatingATokenReplacesTheOldOne;

  /// No description provided for @flowJoin.
  ///
  /// In zh, this message translates to:
  /// **'加入 '**
  String get flowJoin;

  /// No description provided for @flowCouldNotOpenQQAWMCGroup1.
  ///
  /// In zh, this message translates to:
  /// **'无法打开 QQ，已复制 AWMC 交流 1 群的群号，请在 QQ 中搜索加入'**
  String get flowCouldNotOpenQQAWMCGroup1;

  /// No description provided for @flowCouldNotOpenQQAWMCGroup2.
  ///
  /// In zh, this message translates to:
  /// **'无法打开 QQ，已复制 AWMC 交流 2 群的群号，请在 QQ 中搜索加入'**
  String get flowCouldNotOpenQQAWMCGroup2;

  /// No description provided for @flowCloseImage.
  ///
  /// In zh, this message translates to:
  /// **'关闭图片'**
  String get flowCloseImage;

  /// No description provided for @flowTheAppNeedsYourLinkedQQBefore.
  ///
  /// In zh, this message translates to:
  /// **'读取水鱼成绩前，App 要先从水鱼读出你账号上绑定的 QQ 号。\n请到「系统 → 登录水鱼」完成登录后再回来刷新。'**
  String get flowTheAppNeedsYourLinkedQQBefore;

  /// No description provided for @flowTheAppIdentifiesYourDivingFishAccount.
  ///
  /// In zh, this message translates to:
  /// **'App 用 QQ 号来识别你的水鱼账号，而你账号里的「绑定 QQ 号」是空的，\n所以现在读不到成绩。这不是登录出了问题，只是少填了一个字段。'**
  String get flowTheAppIdentifiesYourDivingFishAccount;

  /// No description provided for @flow1OpenDivingFishAndSignIn.
  ///
  /// In zh, this message translates to:
  /// **'① 打开水鱼查分器官网并登录'**
  String get flow1OpenDivingFishAndSignIn;

  /// No description provided for @flow2OpenEditProfileEnterLinkedQQ.
  ///
  /// In zh, this message translates to:
  /// **'② 进入「编辑个人资料」→ 填上「绑定 QQ 号」并保存'**
  String get flow2OpenEditProfileEnterLinkedQQ;

  /// No description provided for @flow3ReturnAndTapISavedIt.
  ///
  /// In zh, this message translates to:
  /// **'③ 回到这里点「我已填好，重新读取」'**
  String get flow3ReturnAndTapISavedIt;

  /// No description provided for @flowSignInToMaimaiScoreHubFirst2.
  ///
  /// In zh, this message translates to:
  /// **'需要先登录 maimai Score Hub'**
  String get flowSignInToMaimaiScoreHubFirst2;

  /// No description provided for @flowPasteOrScanALoginQRCode.
  ///
  /// In zh, this message translates to:
  /// **'请粘贴或扫描登入二维码'**
  String get flowPasteOrScanALoginQRCode;

  /// No description provided for @flowUseALoginQRFromTheMaimai.
  ///
  /// In zh, this message translates to:
  /// **'请使用舞萌|中二公众号生成的登入二维码'**
  String get flowUseALoginQRFromTheMaimai;

  /// No description provided for @flowMaimaiScoreHubSignInFailedThe.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 登录失败，二维码可能已过期，请重新生成'**
  String get flowMaimaiScoreHubSignInFailedThe;

  /// No description provided for @flowSignInFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'登录失败：{p0}'**
  String flowSignInFailedP0(String p0);

  /// No description provided for @flowNoLXNSPersonalAPIKeySetConfigure.
  ///
  /// In zh, this message translates to:
  /// **'尚未设置落雪个人 API 密钥，请先在「成绩导入凭据」中设置'**
  String get flowNoLXNSPersonalAPIKeySetConfigure;

  /// No description provided for @flowQuickSyncSupportsRoute1Only.
  ///
  /// In zh, this message translates to:
  /// **'快速同步仅支持线路1'**
  String get flowQuickSyncSupportsRoute1Only;

  /// No description provided for @flowMaimaiScoreHubSessionExpiredSignIn.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 登录状态已失效，请重新登录后再使用线路2'**
  String get flowMaimaiScoreHubSessionExpiredSignIn;

  /// No description provided for @flowSyncCompleteRefreshingLocalData.
  ///
  /// In zh, this message translates to:
  /// **'同步完成，正在刷新本地数据...'**
  String get flowSyncCompleteRefreshingLocalData;

  /// No description provided for @flowLinkDivingFishToObtainAnImportToken.
  ///
  /// In zh, this message translates to:
  /// **'需要先绑定水鱼账号以获取 ImportToken，请重新点击「同步成绩到水鱼」完成绑定'**
  String get flowLinkDivingFishToObtainAnImportToken;

  /// No description provided for @flowDoneLocalDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'全部完成！本地数据已刷新'**
  String get flowDoneLocalDataRefreshed;

  /// No description provided for @flowSyncComplete.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！'**
  String get flowSyncComplete;

  /// No description provided for @flowP0ScoresSentToDivingFishData.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！{p0} 条成绩已推送到水鱼\n刷新数据失败：{p1}'**
  String flowP0ScoresSentToDivingFishData(String p0, String p1);

  /// No description provided for @flowDivingFishRoute2.
  ///
  /// In zh, this message translates to:
  /// **'水鱼线路2'**
  String get flowDivingFishRoute2;

  /// No description provided for @flowSyncingScores.
  ///
  /// In zh, this message translates to:
  /// **'正在同步成绩...'**
  String get flowSyncingScores;

  /// No description provided for @flowLXNSRoute2.
  ///
  /// In zh, this message translates to:
  /// **'落雪线路2'**
  String get flowLXNSRoute2;

  /// No description provided for @flowPreparingSync2.
  ///
  /// In zh, this message translates to:
  /// **'准备同步…'**
  String get flowPreparingSync2;

  /// No description provided for @flowMultiPlatformRoute2.
  ///
  /// In zh, this message translates to:
  /// **'多端同步的线路2'**
  String get flowMultiPlatformRoute2;

  /// No description provided for @flowEnterANewQRForP0P1.
  ///
  /// In zh, this message translates to:
  /// **'请为{p0}（{p1}）输入新的二维码…'**
  String flowEnterANewQRForP0P1(String p0, String p1);

  /// No description provided for @flowThisQRIsUsedOnlyForThis.
  ///
  /// In zh, this message translates to:
  /// **'这张二维码只用于{p0}（{p1}）的这一次请求；不能和其它目标用过的二维码相同。'**
  String flowThisQRIsUsedOnlyForThis(String p0, String p1);

  /// No description provided for @flowDirectQRUpload.
  ///
  /// In zh, this message translates to:
  /// **'二维码直传'**
  String get flowDirectQRUpload;

  /// No description provided for @flowSyncingToP0P1.
  ///
  /// In zh, this message translates to:
  /// **'正在同步到{p0}（{p1}）…'**
  String flowSyncingToP0P1(String p0, String p1);

  /// No description provided for @flowP0UpToDate.
  ///
  /// In zh, this message translates to:
  /// **'{p0}（成绩已是最新）'**
  String flowP0UpToDate(String p0);

  /// No description provided for @flowP0QuickSyncUpdatedP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}（快速同步，更新 {p1} 条）'**
  String flowP0QuickSyncUpdatedP1(String p0, String p1);

  /// No description provided for @flowP0Route1P1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}（线路1）：{p1}'**
  String flowP0Route1P1(String p0, String p1);

  /// No description provided for @flowP0Route1P1P2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}（线路1）：{p1} {p2}%'**
  String flowP0Route1P1P2(String p0, String p1, String p2);

  /// No description provided for @flowP0Route1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}（线路1）'**
  String flowP0Route1(String p0);

  /// No description provided for @flowNotSignedInToMaimaiScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'未登录 maimai Score Hub，已跳过水鱼线路2同步'**
  String get flowNotSignedInToMaimaiScoreHub;

  /// No description provided for @flowDivingFishRoute2P0P1.
  ///
  /// In zh, this message translates to:
  /// **'水鱼（线路2）：{p0} {p1}%'**
  String flowDivingFishRoute2P0P1(String p0, String p1);

  /// No description provided for @flowDivingFishP0.
  ///
  /// In zh, this message translates to:
  /// **'水鱼：{p0}'**
  String flowDivingFishP0(String p0);

  /// No description provided for @flowDivingFishRoute2P0Scores.
  ///
  /// In zh, this message translates to:
  /// **'水鱼（线路2，{p0} 条）'**
  String flowDivingFishRoute2P0Scores(String p0);

  /// No description provided for @flowNotSignedInToMaimaiScoreHub2.
  ///
  /// In zh, this message translates to:
  /// **'未登录 maimai Score Hub，已跳过落雪线路2同步'**
  String get flowNotSignedInToMaimaiScoreHub2;

  /// No description provided for @flowLXNSP0.
  ///
  /// In zh, this message translates to:
  /// **'落雪：{p0}'**
  String flowLXNSP0(String p0);

  /// No description provided for @flowLXNSRoute2P0P1.
  ///
  /// In zh, this message translates to:
  /// **'落雪（线路2）：{p0} {p1}%'**
  String flowLXNSRoute2P0P1(String p0, String p1);

  /// No description provided for @flowLXNSRoute2P0Scores.
  ///
  /// In zh, this message translates to:
  /// **'落雪（线路2，{p0} 条）'**
  String flowLXNSRoute2P0Scores(String p0);

  /// No description provided for @flowAWMCNETScoreImportTokenNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置 AWMC NET 成绩导入 Token'**
  String get flowAWMCNETScoreImportTokenNotSet;

  /// No description provided for @flowCouldNotReadSavedCredentialsTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'无法读取已保存的凭据，请重试。'**
  String get flowCouldNotReadSavedCredentialsTryAgain;

  /// No description provided for @flowEnterP0.
  ///
  /// In zh, this message translates to:
  /// **'请填写{p0}'**
  String flowEnterP0(String p0);

  /// No description provided for @flowPersonalAPIKey.
  ///
  /// In zh, this message translates to:
  /// **'个人 API 密钥'**
  String get flowPersonalAPIKey;

  /// No description provided for @flowEnterA512DigitQQID.
  ///
  /// In zh, this message translates to:
  /// **'请填写 5～12 位 QQ 号'**
  String get flowEnterA512DigitQQID;

  /// No description provided for @flowCouldNotSaveQQID.
  ///
  /// In zh, this message translates to:
  /// **'保存 QQ 失败'**
  String get flowCouldNotSaveQQID;

  /// No description provided for @flowSelectAtLeastOneSourceWithCredentials.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个已具备凭据的数据源'**
  String get flowSelectAtLeastOneSourceWithCredentials;

  /// No description provided for @flowLXNSAuthorizationCodeMissing.
  ///
  /// In zh, this message translates to:
  /// **'未填写落雪授权码'**
  String get flowLXNSAuthorizationCodeMissing;

  /// No description provided for @flowNoLookupIDObtainedForP0.
  ///
  /// In zh, this message translates to:
  /// **'未拿到{p0}的查询标识'**
  String flowNoLookupIDObtainedForP0(String p0);

  /// No description provided for @flowStartingDataRefresh.
  ///
  /// In zh, this message translates to:
  /// **'开始刷新数据...'**
  String get flowStartingDataRefresh;

  /// No description provided for @flowDataRefreshComplete.
  ///
  /// In zh, this message translates to:
  /// **'数据刷新完成'**
  String get flowDataRefreshComplete;

  /// No description provided for @flowClearingCaches.
  ///
  /// In zh, this message translates to:
  /// **'正在清除缓存...'**
  String get flowClearingCaches;

  /// No description provided for @flowRefreshingDataInParallel.
  ///
  /// In zh, this message translates to:
  /// **'正在并行刷新数据...'**
  String get flowRefreshingDataInParallel;

  /// No description provided for @flowSongDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'歌曲数据已刷新'**
  String get flowSongDataRefreshed;

  /// No description provided for @flowDifficultyDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'难度数据已刷新'**
  String get flowDifficultyDataRefreshed;

  /// No description provided for @flowTagDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'标签数据已刷新'**
  String get flowTagDataRefreshed;

  /// No description provided for @flowUserDataRetrieved.
  ///
  /// In zh, this message translates to:
  /// **'用户数据已获取'**
  String get flowUserDataRetrieved;

  /// No description provided for @flowCollectibleDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'收藏品数据已刷新'**
  String get flowCollectibleDataRefreshed;

  /// No description provided for @flowAliasDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'别名数据已刷新'**
  String get flowAliasDataRefreshed;

  /// No description provided for @flowUnionDataRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'Union 数据已刷新'**
  String get flowUnionDataRefreshed;

  /// No description provided for @flowCouldNotFetchDivingFishScores.
  ///
  /// In zh, this message translates to:
  /// **'水鱼成绩获取失败'**
  String get flowCouldNotFetchDivingFishScores;

  /// No description provided for @flowCalculatingRating.
  ///
  /// In zh, this message translates to:
  /// **'正在计算Rating...'**
  String get flowCalculatingRating;

  /// No description provided for @flowSavingData.
  ///
  /// In zh, this message translates to:
  /// **'正在保存数据...'**
  String get flowSavingData;

  /// No description provided for @flowUploadingSongRankingsP0P1.
  ///
  /// In zh, this message translates to:
  /// **'上传单曲排行榜 {p0}/{p1}...'**
  String flowUploadingSongRankingsP0P1(String p0, String p1);

  /// No description provided for @flowCouldNotRemoveLeaderboardEntries.
  ///
  /// In zh, this message translates to:
  /// **'排行榜删除失败'**
  String get flowCouldNotRemoveLeaderboardEntries;

  /// No description provided for @flowAWMCNETScoresRetrieved.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 成绩已获取'**
  String get flowAWMCNETScoresRetrieved;

  /// No description provided for @flowObtainingAccessToken.
  ///
  /// In zh, this message translates to:
  /// **'正在换取访问令牌...'**
  String get flowObtainingAccessToken;

  /// No description provided for @flowRenewingAccessToken.
  ///
  /// In zh, this message translates to:
  /// **'正在续期访问令牌...'**
  String get flowRenewingAccessToken;

  /// No description provided for @flowAuthorizationFailedCheckYourCode.
  ///
  /// In zh, this message translates to:
  /// **'授权失败，请检查授权码是否正确'**
  String get flowAuthorizationFailedCheckYourCode;

  /// No description provided for @flowLXNSAuthorizationExpiredEnterANewAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'落雪授权已过期，请重新输入授权码'**
  String get flowLXNSAuthorizationExpiredEnterANewAuthorization;

  /// No description provided for @flowAuthorizedRefreshingDataInParallel.
  ///
  /// In zh, this message translates to:
  /// **'授权成功，正在并行刷新数据...'**
  String get flowAuthorizedRefreshingDataInParallel;

  /// No description provided for @flowPreparingLXNSData.
  ///
  /// In zh, this message translates to:
  /// **'准备落雪数据'**
  String get flowPreparingLXNSData;

  /// No description provided for @flowLXNSProfileRetrieved.
  ///
  /// In zh, this message translates to:
  /// **'落雪玩家信息已获取'**
  String get flowLXNSProfileRetrieved;

  /// No description provided for @flowLXNSScoresRetrieved.
  ///
  /// In zh, this message translates to:
  /// **'落雪成绩已获取'**
  String get flowLXNSScoresRetrieved;

  /// No description provided for @flowCouldNotFetchLXNSProfileOrScores.
  ///
  /// In zh, this message translates to:
  /// **'落雪玩家信息或成绩获取失败'**
  String get flowCouldNotFetchLXNSProfileOrScores;

  /// No description provided for @flowCouldNotConvertLXNSScores.
  ///
  /// In zh, this message translates to:
  /// **'落雪成绩转换失败'**
  String get flowCouldNotConvertLXNSScores;

  /// No description provided for @flowCalculatingBest50.
  ///
  /// In zh, this message translates to:
  /// **'正在计算 Best50 数据...'**
  String get flowCalculatingBest50;

  /// No description provided for @flowMissingSongDataCannotCalculateLXNSRating.
  ///
  /// In zh, this message translates to:
  /// **'缺少歌曲数据，无法计算落雪 Rating'**
  String get flowMissingSongDataCannotCalculateLXNSRating;

  /// No description provided for @flowInvalidBest50Data.
  ///
  /// In zh, this message translates to:
  /// **'Best50 数据异常'**
  String get flowInvalidBest50Data;

  /// No description provided for @flowInvalidBest35Data.
  ///
  /// In zh, this message translates to:
  /// **'Best35 数据异常'**
  String get flowInvalidBest35Data;

  /// No description provided for @flowInvalidBest15Data.
  ///
  /// In zh, this message translates to:
  /// **'Best15 数据异常'**
  String get flowInvalidBest15Data;

  /// No description provided for @flowP0CheckForInvalidData.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，可能存在非法数据，请检查'**
  String flowP0CheckForInvalidData(String p0);

  /// No description provided for @flowCouldNotUpdateLeaderboardDataP0.
  ///
  /// In zh, this message translates to:
  /// **'排行榜数据更新失败：{p0}'**
  String flowCouldNotUpdateLeaderboardDataP0(String p0);

  /// No description provided for @flowLeaderboardUpdateErrorP0.
  ///
  /// In zh, this message translates to:
  /// **'排行榜数据更新异常: {p0}'**
  String flowLeaderboardUpdateErrorP0(String p0);

  /// No description provided for @flowSongsAndCharts.
  ///
  /// In zh, this message translates to:
  /// **'歌曲与谱面'**
  String get flowSongsAndCharts;

  /// No description provided for @flowTagsAndAliases.
  ///
  /// In zh, this message translates to:
  /// **'标签与别名'**
  String get flowTagsAndAliases;

  /// No description provided for @flowCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'收藏品'**
  String get flowCollectibles;

  /// No description provided for @flowMetadataAndExtras.
  ///
  /// In zh, this message translates to:
  /// **'元数据与辅助'**
  String get flowMetadataAndExtras;

  /// No description provided for @flowNormal.
  ///
  /// In zh, this message translates to:
  /// **'普通'**
  String get flowNormal;

  /// No description provided for @flowQuick.
  ///
  /// In zh, this message translates to:
  /// **'快速'**
  String get flowQuick;

  /// No description provided for @flowLoadingP0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'{p0}统计加载中…'**
  String flowLoadingP0Statistics(String p0);

  /// No description provided for @flowP0StatisticsUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'{p0}统计不可用'**
  String flowP0StatisticsUnavailable(String p0);

  /// No description provided for @flowP0Last100NoRecords.
  ///
  /// In zh, this message translates to:
  /// **'{p0}近100次 / 暂无记录'**
  String flowP0Last100NoRecords(String p0);

  /// No description provided for @flowP0Last100P1SamplesAvgP22.
  ///
  /// In zh, this message translates to:
  /// **'{p0}近100次 / {p1}样本 / 平均{p2} / 成功{p3}'**
  String flowP0Last100P1SamplesAvgP22(
      String p0, String p1, String p2, String p3);

  /// No description provided for @flowAverageDuration.
  ///
  /// In zh, this message translates to:
  /// **'平均时长'**
  String get flowAverageDuration;

  /// No description provided for @flowSuccessRate.
  ///
  /// In zh, this message translates to:
  /// **'成功率'**
  String get flowSuccessRate;

  /// No description provided for @flowSuccessfulSamples.
  ///
  /// In zh, this message translates to:
  /// **'成功样本'**
  String get flowSuccessfulSamples;

  /// No description provided for @flowLatestRun.
  ///
  /// In zh, this message translates to:
  /// **'最近一次'**
  String get flowLatestRun;

  /// No description provided for @flowStatusUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'状态未确认'**
  String get flowStatusUnconfirmed;

  /// No description provided for @flowExpectedRetry.
  ///
  /// In zh, this message translates to:
  /// **'预计重试'**
  String get flowExpectedRetry;

  /// No description provided for @flowLastRun.
  ///
  /// In zh, this message translates to:
  /// **'最近执行'**
  String get flowLastRun;

  /// No description provided for @flowRefreshPending.
  ///
  /// In zh, this message translates to:
  /// **'待刷新'**
  String get flowRefreshPending;

  /// No description provided for @flowStatusRefreshFailedTapToViewOr.
  ///
  /// In zh, this message translates to:
  /// **'状态刷新失败，请点击查看或重试；此前结果不代表本次查询已确认'**
  String get flowStatusRefreshFailedTapToViewOr;

  /// No description provided for @flowSyncStatusNotReadYet.
  ///
  /// In zh, this message translates to:
  /// **'尚未读取到同步状态'**
  String get flowSyncStatusNotReadYet;

  /// No description provided for @flowP0UserP1OfP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}用户第 {p1} 位 / {p2} 人'**
  String flowP0UserP1OfP2(String p0, String p1, String p2);

  /// No description provided for @flowPreviousRoundP02.
  ///
  /// In zh, this message translates to:
  /// **'上轮：{p0}'**
  String flowPreviousRoundP02(String p0);

  /// No description provided for @flowSuccessP0P1.
  ///
  /// In zh, this message translates to:
  /// **'成功 · {p0} · {p1}'**
  String flowSuccessP0P1(String p0, String p1);

  /// No description provided for @flowFailedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'失败 · {p0} · {p1}'**
  String flowFailedP0P1(String p0, String p1);

  /// No description provided for @flowP0UserPositionP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}用户第{p1}位'**
  String flowP0UserPositionP1(String p0, String p1);

  /// No description provided for @flowSyncFailedP03.
  ///
  /// In zh, this message translates to:
  /// **'同步失败·{p0}'**
  String flowSyncFailedP03(String p0);

  /// No description provided for @flowSyncSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'同步成功'**
  String get flowSyncSucceeded;

  /// No description provided for @flowSyncSucceededP0.
  ///
  /// In zh, this message translates to:
  /// **'同步成功·{p0}'**
  String flowSyncSucceededP0(String p0);

  /// No description provided for @flowCorrectTheDifficultyCombinationConstantsFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先修正按难度组合的定数输入'**
  String get flowCorrectTheDifficultyCombinationConstantsFirst;

  /// No description provided for @flowSearchFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'搜索失败：{p0}'**
  String flowSearchFailedP0(String p0);

  /// No description provided for @flowAny.
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get flowAny;

  /// No description provided for @flowChooseACharter.
  ///
  /// In zh, this message translates to:
  /// **'请选择谱师'**
  String get flowChooseACharter;

  /// No description provided for @flowSelectCharter.
  ///
  /// In zh, this message translates to:
  /// **'选择谱师'**
  String get flowSelectCharter;

  /// No description provided for @flowSearchCharters.
  ///
  /// In zh, this message translates to:
  /// **'搜索谱师'**
  String get flowSearchCharters;

  /// No description provided for @flowFilterByCharterName.
  ///
  /// In zh, this message translates to:
  /// **'输入谱师名称筛选...'**
  String get flowFilterByCharterName;

  /// No description provided for @flowChooseAnArtist.
  ///
  /// In zh, this message translates to:
  /// **'请选择曲师'**
  String get flowChooseAnArtist;

  /// No description provided for @flowSelectArtist.
  ///
  /// In zh, this message translates to:
  /// **'选择曲师'**
  String get flowSelectArtist;

  /// No description provided for @flowSearchArtists.
  ///
  /// In zh, this message translates to:
  /// **'搜索曲师'**
  String get flowSearchArtists;

  /// No description provided for @flowFilterByArtistName.
  ///
  /// In zh, this message translates to:
  /// **'输入曲师名称筛选...'**
  String get flowFilterByArtistName;

  /// No description provided for @flowP0Items2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 项'**
  String flowP0Items2(String p0);

  /// No description provided for @flowByDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'按难度'**
  String get flowByDifficulty;

  /// No description provided for @flowConstant.
  ///
  /// In zh, this message translates to:
  /// **'定数'**
  String get flowConstant;

  /// No description provided for @flowVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get flowVersion;

  /// No description provided for @flowGenre.
  ///
  /// In zh, this message translates to:
  /// **'流派'**
  String get flowGenre;

  /// No description provided for @flowNotes.
  ///
  /// In zh, this message translates to:
  /// **'物量'**
  String get flowNotes;

  /// No description provided for @flowTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get flowTags;

  /// No description provided for @flowCharter.
  ///
  /// In zh, this message translates to:
  /// **'谱师'**
  String get flowCharter;

  /// No description provided for @flowArtist.
  ///
  /// In zh, this message translates to:
  /// **'曲师'**
  String get flowArtist;

  /// No description provided for @flowSongID.
  ///
  /// In zh, this message translates to:
  /// **'歌曲ID'**
  String get flowSongID;

  /// No description provided for @flowSongTitle.
  ///
  /// In zh, this message translates to:
  /// **'歌名'**
  String get flowSongTitle;

  /// No description provided for @flowArtist2.
  ///
  /// In zh, this message translates to:
  /// **'艺术家'**
  String get flowArtist2;

  /// No description provided for @flowAlias.
  ///
  /// In zh, this message translates to:
  /// **'别名'**
  String get flowAlias;

  /// No description provided for @flowTakeAPhotoOrChooseAnImage.
  ///
  /// In zh, this message translates to:
  /// **'拍照或从相册选择图片'**
  String get flowTakeAPhotoOrChooseAnImage;

  /// No description provided for @flowCropTheCoverArtInTheImage.
  ///
  /// In zh, this message translates to:
  /// **'框选图片里的曲绘区域'**
  String get flowCropTheCoverArtInTheImage;

  /// No description provided for @flowRecognizeAndViewTheClosestSongs.
  ///
  /// In zh, this message translates to:
  /// **'开始识别，查看最接近的曲目'**
  String get flowRecognizeAndViewTheClosestSongs;

  /// No description provided for @flowTexture.
  ///
  /// In zh, this message translates to:
  /// **'纹理'**
  String get flowTexture;

  /// No description provided for @flowColor.
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get flowColor;

  /// No description provided for @flowEnterANumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入数字'**
  String get flowEnterANumber;

  /// No description provided for @flowCannotBeNegative.
  ///
  /// In zh, this message translates to:
  /// **'不能为负数'**
  String get flowCannotBeNegative;

  /// No description provided for @flowMustNotExceedP0.
  ///
  /// In zh, this message translates to:
  /// **'不得超过 {p0}'**
  String flowMustNotExceedP0(String p0);

  /// No description provided for @flowDifficultyP0.
  ///
  /// In zh, this message translates to:
  /// **'难度 {p0}'**
  String flowDifficultyP0(String p0);

  /// No description provided for @flowLocalLibraryIsEmptyRefreshItFrom.
  ///
  /// In zh, this message translates to:
  /// **'本地曲库为空，无法定位曲目。请先到首页刷新曲库'**
  String get flowLocalLibraryIsEmptyRefreshItFrom;

  /// No description provided for @flowNoSongMatchedTapEditThisResult.
  ///
  /// In zh, this message translates to:
  /// **'没匹配到曲目，点「编辑此项」手动指定'**
  String get flowNoSongMatchedTapEditThisResult;

  /// No description provided for @flowDifficultyNotRecognizedUTAGESyncIsUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'难度识别不出来（宴会场谱面不支持同步）'**
  String get flowDifficultyNotRecognizedUTAGESyncIsUnsupported;

  /// No description provided for @flowNoChartInformationForThisSongIn.
  ///
  /// In zh, this message translates to:
  /// **'曲库里这首歌没有谱面信息'**
  String get flowNoChartInformationForThisSongIn;

  /// No description provided for @flowDifficultyP0DoesNotExistOnlyP1.
  ///
  /// In zh, this message translates to:
  /// **'这首歌没有第 {p0} 个难度（只有 {p1} 个谱面）'**
  String flowDifficultyP0DoesNotExistOnlyP1(String p0, String p1);

  /// No description provided for @flowAchievementMissingTapEditThisResultTo.
  ///
  /// In zh, this message translates to:
  /// **'缺少达成率，点「编辑此项」补上'**
  String get flowAchievementMissingTapEditThisResultTo;

  /// No description provided for @flowUpdatedOnLXNSP0.
  ///
  /// In zh, this message translates to:
  /// **'已更新到落雪：{p0}'**
  String flowUpdatedOnLXNSP0(String p0);

  /// No description provided for @flowSyncedToLXNSUnchangedP0.
  ///
  /// In zh, this message translates to:
  /// **'已同步到落雪（无变化）：{p0}'**
  String flowSyncedToLXNSUnchangedP0(String p0);

  /// No description provided for @flowAchievementP0P1.
  ///
  /// In zh, this message translates to:
  /// **'达成率 {p0}% → {p1}%'**
  String flowAchievementP0P1(String p0, String p1);

  /// No description provided for @flowAchievementP0.
  ///
  /// In zh, this message translates to:
  /// **'达成率 {p0}%'**
  String flowAchievementP0(String p0);

  /// No description provided for @flowDXScoreP0P1.
  ///
  /// In zh, this message translates to:
  /// **'DX分数 {p0} → {p1}'**
  String flowDXScoreP0P1(String p0, String p1);

  /// No description provided for @flowDXScoreP0.
  ///
  /// In zh, this message translates to:
  /// **'DX分数 {p0}'**
  String flowDXScoreP0(String p0);

  /// No description provided for @flowMaximumP0.
  ///
  /// In zh, this message translates to:
  /// **'上限 {p0}%'**
  String flowMaximumP0(String p0);

  /// No description provided for @flowMaximumP02.
  ///
  /// In zh, this message translates to:
  /// **'上限 {p0}'**
  String flowMaximumP02(String p0);

  /// No description provided for @flowPhotographOrChooseAResultScreen.
  ///
  /// In zh, this message translates to:
  /// **'拍照或从相册选择结算画面'**
  String get flowPhotographOrChooseAResultScreen;

  /// No description provided for @flowPhotographStraightAndClearlyForBetterRecognition.
  ///
  /// In zh, this message translates to:
  /// **'尽量拍正、拍清，识别更准'**
  String get flowPhotographStraightAndClearlyForBetterRecognition;

  /// No description provided for @flowCheckResultsThenSyncToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'核对结果后可同步到水鱼或落雪'**
  String get flowCheckResultsThenSyncToDivingFish;

  /// No description provided for @flowStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get flowStandard;

  /// No description provided for @flowConfidence.
  ///
  /// In zh, this message translates to:
  /// **'置信度 —'**
  String get flowConfidence;

  /// No description provided for @flowConfidenceP0.
  ///
  /// In zh, this message translates to:
  /// **'置信度 {p0}%'**
  String flowConfidenceP0(String p0);

  /// No description provided for @flowCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'曲绘'**
  String get flowCoverArt;

  /// No description provided for @flowTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get flowTitle;

  /// No description provided for @flowSignInFailedTheQRMayHave.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，二维码可能已过期，请重新生成'**
  String get flowSignInFailedTheQRMayHave;

  /// No description provided for @flowAllSongs.
  ///
  /// In zh, this message translates to:
  /// **'全量'**
  String get flowAllSongs;

  /// No description provided for @flowInChina.
  ///
  /// In zh, this message translates to:
  /// **'国服已上'**
  String get flowInChina;

  /// No description provided for @flowPendingRelease.
  ///
  /// In zh, this message translates to:
  /// **'待上线'**
  String get flowPendingRelease;

  /// No description provided for @flowNotIncluded.
  ///
  /// In zh, this message translates to:
  /// **'未收录'**
  String get flowNotIncluded;

  /// No description provided for @flowNextUpdateCandidates.
  ///
  /// In zh, this message translates to:
  /// **'下次更新候选'**
  String get flowNextUpdateCandidates;

  /// No description provided for @flowOlderSongsMissingInChina.
  ///
  /// In zh, this message translates to:
  /// **'国服未收录旧曲'**
  String get flowOlderSongsMissingInChina;

  /// No description provided for @flowUTAGE.
  ///
  /// In zh, this message translates to:
  /// **'宴会场'**
  String get flowUTAGE;

  /// No description provided for @flowChinaRegularSongs.
  ///
  /// In zh, this message translates to:
  /// **'国服常规曲'**
  String get flowChinaRegularSongs;

  /// No description provided for @flowEarlyChinaReleases.
  ///
  /// In zh, this message translates to:
  /// **'国服超前上线'**
  String get flowEarlyChinaReleases;

  /// No description provided for @flowNoMissingRegularSongsInTheCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前参考范围内没有未收录的常规曲。'**
  String get flowNoMissingRegularSongsInTheCurrent;

  /// No description provided for @flowSortedByIDNotReleaseOrderOfficial.
  ///
  /// In zh, this message translates to:
  /// **'按 ID 升序展示，顺序不代表上线先后；实际更新以官方公告为准。{p0}'**
  String flowSortedByIDNotReleaseOrderOfficial(String p0);

  /// No description provided for @flowTheseSongsPredateTheReferenceStartOr.
  ///
  /// In zh, this message translates to:
  /// **'这些曲早于候选参考起点，或缺少日期且 ID 较小，可能是区域限定、联动独占或尚未补入的旧曲；不代表以后不会上线。'**
  String get flowTheseSongsPredateTheReferenceStartOr;

  /// No description provided for @flowUTAGEDoesNotFollowVersionUpdatesListed.
  ///
  /// In zh, this message translates to:
  /// **'宴会场不随版本更新，列在这里仅供参考。'**
  String get flowUTAGEDoesNotFollowVersionUpdatesListed;

  /// No description provided for @flowRegularDivingFishChinaSongsNewestDebut.
  ///
  /// In zh, this message translates to:
  /// **'水鱼（国服）的常规曲，按首发日期从新到旧排列 —— 第一首就是本页的「更新前沿」。'**
  String get flowRegularDivingFishChinaSongsNewestDebut;

  /// No description provided for @flowTheseSongsReachedChinaBeforeJapanTheir.
  ///
  /// In zh, this message translates to:
  /// **'这些是**国服先于日服**上线的曲子：国服已经有了，id 却排在最新。它们不能当前沿（会把真正待补的那批顶出候选），所以单独列在这里。'**
  String get flowTheseSongsReachedChinaBeforeJapanTheir;

  /// No description provided for @flowVersionsInvolvedP0.
  ///
  /// In zh, this message translates to:
  /// **'\n涉及版本：{p0}'**
  String flowVersionsInvolvedP0(String p0);

  /// No description provided for @flowP0P1Songs.
  ///
  /// In zh, this message translates to:
  /// **'{p0} {p1} 首'**
  String flowP0P1Songs(String p0, String p1);

  /// No description provided for @flowChartDateSource.
  ///
  /// In zh, this message translates to:
  /// **'谱面日期来源：'**
  String get flowChartDateSource;

  /// No description provided for @flowReleaseDataSource.
  ///
  /// In zh, this message translates to:
  /// **'配信数据来源：'**
  String get flowReleaseDataSource;

  /// No description provided for @flowUpdatesOnThisDay.
  ///
  /// In zh, this message translates to:
  /// **'当天更新'**
  String get flowUpdatesOnThisDay;

  /// No description provided for @flowP0P1P2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 月 {p1} 日 周{p2}'**
  String flowP0P1P2(String p0, String p1, String p2);

  /// No description provided for @flowAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get flowAll;

  /// No description provided for @flowPlayed.
  ///
  /// In zh, this message translates to:
  /// **'已游玩'**
  String get flowPlayed;

  /// No description provided for @flowUnplayed.
  ///
  /// In zh, this message translates to:
  /// **'未游玩'**
  String get flowUnplayed;

  /// No description provided for @flowP0Types.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 种'**
  String flowP0Types(String p0);

  /// No description provided for @flowThisCollectibleHasNoImage.
  ///
  /// In zh, this message translates to:
  /// **'该收藏品没有图片'**
  String get flowThisCollectibleHasNoImage;

  /// No description provided for @flowCouldNotSaveImageP0.
  ///
  /// In zh, this message translates to:
  /// **'保存图片失败: {p0}'**
  String flowCouldNotSaveImageP0(String p0);

  /// No description provided for @flowThisCollectibleHasNoImageLink.
  ///
  /// In zh, this message translates to:
  /// **'该收藏品没有图片链接'**
  String get flowThisCollectibleHasNoImageLink;

  /// No description provided for @flowLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'链接已复制到剪贴板'**
  String get flowLinkCopied;

  /// No description provided for @flowCouldNotCopyLink.
  ///
  /// In zh, this message translates to:
  /// **'复制链接失败'**
  String get flowCouldNotCopyLink;

  /// No description provided for @flowRequiredDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'所需难度'**
  String get flowRequiredDifficulty;

  /// No description provided for @flowMinimumAchievement.
  ///
  /// In zh, this message translates to:
  /// **'所需最低达成率'**
  String get flowMinimumAchievement;

  /// No description provided for @flowRequiredNoteSpeed.
  ///
  /// In zh, this message translates to:
  /// **'所需游玩流速'**
  String get flowRequiredNoteSpeed;

  /// No description provided for @flowRequiredCombo.
  ///
  /// In zh, this message translates to:
  /// **'所需连击'**
  String get flowRequiredCombo;

  /// No description provided for @flowRequiredSync.
  ///
  /// In zh, this message translates to:
  /// **'所需同步'**
  String get flowRequiredSync;

  /// No description provided for @flowJapaneseEnglish.
  ///
  /// In zh, this message translates to:
  /// **'日语+英语'**
  String get flowJapaneseEnglish;

  /// No description provided for @flowEnglish.
  ///
  /// In zh, this message translates to:
  /// **'英语'**
  String get flowEnglish;

  /// No description provided for @flowJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日语'**
  String get flowJapanese;

  /// No description provided for @flowP0Seconds2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 秒'**
  String flowP0Seconds2(String p0);

  /// No description provided for @flowP0Minutes.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 分钟'**
  String flowP0Minutes(String p0);

  /// No description provided for @flowP0MinP1Sec.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 分 {p1} 秒'**
  String flowP0MinP1Sec(String p0, String p1);

  /// No description provided for @flowJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get flowJustNow;

  /// No description provided for @flowWaitingForUpstreamQuota.
  ///
  /// In zh, this message translates to:
  /// **'等待上游配额恢复'**
  String get flowWaitingForUpstreamQuota;

  /// No description provided for @flowWaitingForUpstreamService.
  ///
  /// In zh, this message translates to:
  /// **'等待上游服务恢复'**
  String get flowWaitingForUpstreamService;

  /// No description provided for @flowWaitingForUpstreamGateway.
  ///
  /// In zh, this message translates to:
  /// **'等待上游网关恢复'**
  String get flowWaitingForUpstreamGateway;

  /// No description provided for @flowWaitingForUpstreamProcessing.
  ///
  /// In zh, this message translates to:
  /// **'等待上游处理'**
  String get flowWaitingForUpstreamProcessing;

  /// No description provided for @flowP0RetryAroundP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，预计 {p1} 重试'**
  String flowP0RetryAroundP1(String p0, String p1);

  /// No description provided for @flowProcessingTimedOut.
  ///
  /// In zh, this message translates to:
  /// **'处理超时'**
  String get flowProcessingTimedOut;

  /// No description provided for @flowQuotaInsufficient.
  ///
  /// In zh, this message translates to:
  /// **'配额不足'**
  String get flowQuotaInsufficient;

  /// No description provided for @flowUpstreamUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'上游不可用'**
  String get flowUpstreamUnavailable;

  /// No description provided for @flowUploadIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'上传未完成'**
  String get flowUploadIncomplete;

  /// No description provided for @flowUploadCredentialsExpired.
  ///
  /// In zh, this message translates to:
  /// **'上传凭据失效'**
  String get flowUploadCredentialsExpired;

  /// No description provided for @flowCouldNotReadTargetScores.
  ///
  /// In zh, this message translates to:
  /// **'目标成绩读取失败'**
  String get flowCouldNotReadTargetScores;

  /// No description provided for @flowCouldNotReadLibrary.
  ///
  /// In zh, this message translates to:
  /// **'曲库读取失败'**
  String get flowCouldNotReadLibrary;

  /// No description provided for @flowCouldNotReadCabinetData.
  ///
  /// In zh, this message translates to:
  /// **'机台读取失败'**
  String get flowCouldNotReadCabinetData;

  /// No description provided for @flowNoScoresToSync.
  ///
  /// In zh, this message translates to:
  /// **'没有可同步成绩'**
  String get flowNoScoresToSync;

  /// No description provided for @flowInterruptedByServiceRestart.
  ///
  /// In zh, this message translates to:
  /// **'服务重启中断'**
  String get flowInterruptedByServiceRestart;

  /// No description provided for @flowProcessingWindowEnded.
  ///
  /// In zh, this message translates to:
  /// **'处理窗口已结束'**
  String get flowProcessingWindowEnded;

  /// No description provided for @flowRoundDataExpired.
  ///
  /// In zh, this message translates to:
  /// **'本轮数据已失效'**
  String get flowRoundDataExpired;

  /// No description provided for @flowTaskCancelled.
  ///
  /// In zh, this message translates to:
  /// **'任务已取消'**
  String get flowTaskCancelled;

  /// No description provided for @flowPreparingQuickSync.
  ///
  /// In zh, this message translates to:
  /// **'正在准备快速同步…'**
  String get flowPreparingQuickSync;

  /// No description provided for @flowElapsedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'处理已用 {p0}{p1}'**
  String flowElapsedP0P1(String p0, String p1);

  /// No description provided for @flowLimitP0Min.
  ///
  /// In zh, this message translates to:
  /// **' / 上限 {p0} 分钟'**
  String flowLimitP0Min(String p0);

  /// No description provided for @flowWaitingForProcessingToStart.
  ///
  /// In zh, this message translates to:
  /// **'等待开始处理'**
  String get flowWaitingForProcessingToStart;

  /// No description provided for @flowCabinetDataCollectedP02.
  ///
  /// In zh, this message translates to:
  /// **'机台数据采集 {p0}'**
  String flowCabinetDataCollectedP02(String p0);

  /// No description provided for @flowUploadingP0P1P2.
  ///
  /// In zh, this message translates to:
  /// **'上传 {p0}/{p1} 条{p2}'**
  String flowUploadingP0P1P2(String p0, String p1, String p2);

  /// No description provided for @flowReadingCabinetScoresPageP0.
  ///
  /// In zh, this message translates to:
  /// **'读取机台成绩 · 第 {p0} 页'**
  String flowReadingCabinetScoresPageP0(String p0);

  /// No description provided for @flowSubmittedP02.
  ///
  /// In zh, this message translates to:
  /// **'提交 {p0} 条'**
  String flowSubmittedP02(String p0);

  /// No description provided for @flowSkippedP0UnsupportedCharts2.
  ///
  /// In zh, this message translates to:
  /// **'跳过 {p0} 条不支持的谱面'**
  String flowSkippedP0UnsupportedCharts2(String p0);

  /// No description provided for @flowUnchangedP0.
  ///
  /// In zh, this message translates to:
  /// **'未变化 {p0} 条'**
  String flowUnchangedP0(String p0);

  /// No description provided for @flowP0TookP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 耗时 {p1}'**
  String flowP0TookP1(String p0, String p1);

  /// No description provided for @flowAccountAndSync.
  ///
  /// In zh, this message translates to:
  /// **'账号与同步'**
  String get flowAccountAndSync;

  /// No description provided for @flowAccountAndSyncHint.
  ///
  /// In zh, this message translates to:
  /// **'管理账号、授权状态与成绩同步'**
  String get flowAccountAndSyncHint;

  /// No description provided for @flowFishAccount.
  ///
  /// In zh, this message translates to:
  /// **'水鱼账号'**
  String get flowFishAccount;

  /// No description provided for @flowReadingAccountState.
  ///
  /// In zh, this message translates to:
  /// **'正在读取账号状态'**
  String get flowReadingAccountState;

  /// No description provided for @flowNotSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get flowNotSignedIn;

  /// No description provided for @flowSignInFishAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新登录水鱼'**
  String get flowSignInFishAgain;

  /// No description provided for @flowUseFishForToken.
  ///
  /// In zh, this message translates to:
  /// **'使用水鱼账号获取 ImportToken'**
  String get flowUseFishForToken;

  /// No description provided for @flowScoreSync.
  ///
  /// In zh, this message translates to:
  /// **'成绩同步'**
  String get flowScoreSync;

  /// No description provided for @flowSyncSourcesHint.
  ///
  /// In zh, this message translates to:
  /// **'从舞萌数据源同步到第三方服务'**
  String get flowSyncSourcesHint;

  /// No description provided for @flowImportTokenNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置成绩导入 Token'**
  String get flowImportTokenNotSet;

  /// No description provided for @flowTitleCollectible.
  ///
  /// In zh, this message translates to:
  /// **'称号'**
  String get flowTitleCollectible;

  /// No description provided for @flowIconCollectible.
  ///
  /// In zh, this message translates to:
  /// **'头像'**
  String get flowIconCollectible;

  /// No description provided for @flowPlateCollectible.
  ///
  /// In zh, this message translates to:
  /// **'姓名框'**
  String get flowPlateCollectible;

  /// No description provided for @flowFrameCollectible.
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get flowFrameCollectible;

  /// No description provided for @flowAwmcGateway.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关'**
  String get flowAwmcGateway;

  /// No description provided for @flowNormalSource.
  ///
  /// In zh, this message translates to:
  /// **'国服曲库'**
  String get flowNormalSource;

  /// No description provided for @flowExtraSource.
  ///
  /// In zh, this message translates to:
  /// **'非国服曲库'**
  String get flowExtraSource;

  /// No description provided for @flowQrPrivateNotice.
  ///
  /// In zh, this message translates to:
  /// **'与「同步成绩」用的是同一串二维码内容（SGWCMAID 开头），可直接从微信/相机识别结果里复制。\n\n⚠️ 该二维码等同于机台登录凭据，只能用于你自己的账号。'**
  String get flowQrPrivateNotice;

  /// No description provided for @flowReadingExistingScoresOnTheTargetAccount.
  ///
  /// In zh, this message translates to:
  /// **'正在读取目标账号已有成绩…'**
  String get flowReadingExistingScoresOnTheTargetAccount;

  /// No description provided for @flowCheckingChartsSupportedByTheTarget.
  ///
  /// In zh, this message translates to:
  /// **'正在核对目标源支持的谱面…'**
  String get flowCheckingChartsSupportedByTheTarget;

  /// No description provided for @flowReadingCabinetScoresP0PagesRead.
  ///
  /// In zh, this message translates to:
  /// **'正在读取机台成绩，已读取 {p0} 页'**
  String flowReadingCabinetScoresP0PagesRead(String p0);

  /// No description provided for @flowReadingCabinetScores.
  ///
  /// In zh, this message translates to:
  /// **'正在读取机台成绩…'**
  String get flowReadingCabinetScores;

  /// No description provided for @flowPreparingChartsComboAndSyncMarkers.
  ///
  /// In zh, this message translates to:
  /// **'正在整理谱面与连击、同步标记…'**
  String get flowPreparingChartsComboAndSyncMarkers;

  /// No description provided for @flowUploadingScoresP0P1P2.
  ///
  /// In zh, this message translates to:
  /// **'正在上传成绩（{p0} / {p1} 条{p2}）'**
  String flowUploadingScoresP0P1P2(String p0, String p1, String p2);

  /// No description provided for @flowP0Submitted.
  ///
  /// In zh, this message translates to:
  /// **'，已提交 {p0} 条'**
  String flowP0Submitted(String p0);

  /// No description provided for @flowSyncComplete2.
  ///
  /// In zh, this message translates to:
  /// **'同步完成'**
  String get flowSyncComplete2;

  /// No description provided for @flowWaitingForUpstreamQuota2.
  ///
  /// In zh, this message translates to:
  /// **'等待上游配额恢复…'**
  String get flowWaitingForUpstreamQuota2;

  /// No description provided for @flowWaitingForUpstreamService2.
  ///
  /// In zh, this message translates to:
  /// **'等待上游服务恢复…'**
  String get flowWaitingForUpstreamService2;

  /// No description provided for @flowReadingExistingScoresOnP0.
  ///
  /// In zh, this message translates to:
  /// **'正在读取 {p0} 已有成绩…'**
  String flowReadingExistingScoresOnP0(String p0);

  /// No description provided for @flowCheckingChartsSupportedByP0.
  ///
  /// In zh, this message translates to:
  /// **'正在核对 {p0} 支持的谱面…'**
  String flowCheckingChartsSupportedByP0(String p0);

  /// No description provided for @flowComparingChangesAndPreparingUploads.
  ///
  /// In zh, this message translates to:
  /// **'正在比对差异并整理上传内容…'**
  String get flowComparingChangesAndPreparingUploads;

  /// No description provided for @flowUploadingToP0P1P2P3.
  ///
  /// In zh, this message translates to:
  /// **'正在上传到{p0}：{p1} / {p2} 条{p3}'**
  String flowUploadingToP0P1P2P3(String p0, String p1, String p2, String p3);

  /// No description provided for @flowValidatingQRCode2.
  ///
  /// In zh, this message translates to:
  /// **'正在验证二维码...'**
  String get flowValidatingQRCode2;

  /// No description provided for @flowCreatingScoreFetchTask.
  ///
  /// In zh, this message translates to:
  /// **'正在创建抓取任务...'**
  String get flowCreatingScoreFetchTask;

  /// No description provided for @flowBotIsSendingAFriendRequest.
  ///
  /// In zh, this message translates to:
  /// **'Bot 正在发送好友申请...'**
  String get flowBotIsSendingAFriendRequest;

  /// No description provided for @flowFriendAddedCreatingScoreFetchTask.
  ///
  /// In zh, this message translates to:
  /// **'好友已添加，正在创建抓取任务...'**
  String get flowFriendAddedCreatingScoreFetchTask;

  /// No description provided for @flowSyncingToDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'正在同步到水鱼...'**
  String get flowSyncingToDivingFish;

  /// No description provided for @flowSyncCompleteP0ScoresSynced.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！共同步 {p0} 条成绩'**
  String flowSyncCompleteP0ScoresSynced(String p0);

  /// No description provided for @flowSubmittingQRCode.
  ///
  /// In zh, this message translates to:
  /// **'正在提交二维码...'**
  String get flowSubmittingQRCode;

  /// No description provided for @flowSyncingToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'正在同步到落雪...'**
  String get flowSyncingToLXNS;

  /// No description provided for @flowSyncCompleteP0ScoresSyncedToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'同步完成！共同步 {p0} 条成绩到落雪'**
  String flowSyncCompleteP0ScoresSyncedToLXNS(String p0);

  /// No description provided for @flowAcceptTheFriendRequestOnNETOr.
  ///
  /// In zh, this message translates to:
  /// **'等待你在 NET / 机台上通过好友申请'**
  String get flowAcceptTheFriendRequestOnNETOr;

  /// No description provided for @flowFetchingScoresP0P1.
  ///
  /// In zh, this message translates to:
  /// **'正在抓取成绩... ({p0}/{p1})'**
  String flowFetchingScoresP0P1(String p0, String p1);

  /// No description provided for @flowFetchingScores.
  ///
  /// In zh, this message translates to:
  /// **'正在抓取成绩...'**
  String get flowFetchingScores;

  /// No description provided for @flowFetchingFriendList.
  ///
  /// In zh, this message translates to:
  /// **'正在拉取好友列表...'**
  String get flowFetchingFriendList;

  /// No description provided for @flowTaskQueuedWaitingForProcessing.
  ///
  /// In zh, this message translates to:
  /// **'任务已排队，等待处理...'**
  String get flowTaskQueuedWaitingForProcessing;

  /// No description provided for @flowPreviewingData.
  ///
  /// In zh, this message translates to:
  /// **'正在预览数据...'**
  String get flowPreviewingData;

  /// No description provided for @flowSigningIn3.
  ///
  /// In zh, this message translates to:
  /// **'正在登录...'**
  String get flowSigningIn3;

  /// No description provided for @flowReadingChartScoresP0Records.
  ///
  /// In zh, this message translates to:
  /// **'正在获取谱面成绩... ({p0} 条)'**
  String flowReadingChartScoresP0Records(String p0);

  /// No description provided for @flowReadingChartScores.
  ///
  /// In zh, this message translates to:
  /// **'正在获取谱面成绩...'**
  String get flowReadingChartScores;

  /// No description provided for @flowSigningOut.
  ///
  /// In zh, this message translates to:
  /// **'正在登出...'**
  String get flowSigningOut;

  /// No description provided for @flowCleaningUp.
  ///
  /// In zh, this message translates to:
  /// **'正在清理...'**
  String get flowCleaningUp;

  /// No description provided for @flowSavingScoresP0Records.
  ///
  /// In zh, this message translates to:
  /// **'正在保存成绩... ({p0} 条)'**
  String flowSavingScoresP0Records(String p0);

  /// No description provided for @flowSavingScores.
  ///
  /// In zh, this message translates to:
  /// **'正在保存成绩...'**
  String get flowSavingScores;

  /// No description provided for @flowReadingComboAndSyncMarkersFromP0.
  ///
  /// In zh, this message translates to:
  /// **'正在读取{p0}已有的连击与同步标记…'**
  String flowReadingComboAndSyncMarkersFromP0(String p0);

  /// No description provided for @flowCheckingChartsSupportedByP02.
  ///
  /// In zh, this message translates to:
  /// **'正在核对{p0}支持的谱面…'**
  String flowCheckingChartsSupportedByP02(String p0);

  /// No description provided for @flowReadingCabinetScoresForThisRound.
  ///
  /// In zh, this message translates to:
  /// **'正在读取本轮机台成绩…'**
  String get flowReadingCabinetScoresForThisRound;

  /// No description provided for @flowUpdatingP0ScoresP1P2.
  ///
  /// In zh, this message translates to:
  /// **'正在更新{p0}成绩（{p1}/{p2}）…'**
  String flowUpdatingP0ScoresP1P2(String p0, String p1, String p2);

  /// No description provided for @flowQuickSyncCompleteUpdatedP0Scores.
  ///
  /// In zh, this message translates to:
  /// **'快速同步完成：更新 {p0} 条成绩'**
  String flowQuickSyncCompleteUpdatedP0Scores(String p0);

  /// No description provided for @flowSkippedP0UnchangedScores.
  ///
  /// In zh, this message translates to:
  /// **'，跳过 {p0} 条未变化成绩'**
  String flowSkippedP0UnchangedScores(String p0);

  /// No description provided for @flowP0ChartsUnmatchedOrUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'，{p0} 条谱面未匹配或目标源不支持'**
  String flowP0ChartsUnmatchedOrUnsupported(String p0);

  /// No description provided for @flowCheckingAWMCGateway2.
  ///
  /// In zh, this message translates to:
  /// **'正在检查 AWMC 网关…'**
  String get flowCheckingAWMCGateway2;

  /// No description provided for @flowQuicklyReadingCabinetScores.
  ///
  /// In zh, this message translates to:
  /// **'正在快速读取机台成绩…'**
  String get flowQuicklyReadingCabinetScores;

  /// No description provided for @flowClearSignIn.
  ///
  /// In zh, this message translates to:
  /// **'清除当前登录状态'**
  String get flowClearSignIn;

  /// No description provided for @flowBoundQq.
  ///
  /// In zh, this message translates to:
  /// **'当前绑定 QQ：{qq}'**
  String flowBoundQq(String qq);

  /// No description provided for @flowStatsNotUpdated.
  ///
  /// In zh, this message translates to:
  /// **'尚未更新'**
  String get flowStatsNotUpdated;

  /// No description provided for @flowStatsJustUpdated.
  ///
  /// In zh, this message translates to:
  /// **'刚刚更新'**
  String get flowStatsJustUpdated;

  /// No description provided for @flowStatsSecondsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 秒前更新'**
  String flowStatsSecondsAgo(String count);

  /// No description provided for @flowStatsMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前更新'**
  String flowStatsMinutesAgo(String count);

  /// No description provided for @flowStatsHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前更新'**
  String flowStatsHoursAgo(String count);

  /// No description provided for @flowCacheNeverExpires.
  ///
  /// In zh, this message translates to:
  /// **'永不过期'**
  String get flowCacheNeverExpires;

  /// No description provided for @flowCacheNoTimestamp.
  ///
  /// In zh, this message translates to:
  /// **'无缓存时间戳'**
  String get flowCacheNoTimestamp;

  /// No description provided for @flowCacheAbsent.
  ///
  /// In zh, this message translates to:
  /// **'无缓存'**
  String get flowCacheAbsent;

  /// No description provided for @flowCacheExpiredPrefix.
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get flowCacheExpiredPrefix;

  /// No description provided for @flowCacheExpired.
  ///
  /// In zh, this message translates to:
  /// **'已过期 {duration}'**
  String flowCacheExpired(String duration);

  /// No description provided for @flowCacheRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {duration}'**
  String flowCacheRemaining(String duration);

  /// No description provided for @flowCacheDaysHours.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天 {hours} 小时'**
  String flowCacheDaysHours(String days, String hours);

  /// No description provided for @flowCacheDays.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天'**
  String flowCacheDays(String days);

  /// No description provided for @flowCacheHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时 {minutes} 分钟'**
  String flowCacheHoursMinutes(String hours, String minutes);

  /// No description provided for @flowCacheHours.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时'**
  String flowCacheHours(String hours);

  /// No description provided for @flowCacheMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String flowCacheMinutes(String minutes);

  /// No description provided for @flowRankingShowIdentity.
  ///
  /// In zh, this message translates to:
  /// **'展示昵称与头像'**
  String get flowRankingShowIdentity;

  /// No description provided for @flowRankingIdentityHint.
  ///
  /// In zh, this message translates to:
  /// **'关闭时显示匿名用户和默认头像；自选头像仍会保存并同步。'**
  String get flowRankingIdentityHint;

  /// No description provided for @flowRankingShowBrief.
  ///
  /// In zh, this message translates to:
  /// **'展示排行榜简要信息'**
  String get flowRankingShowBrief;

  /// No description provided for @flowRankingBriefHint.
  ///
  /// In zh, this message translates to:
  /// **'公开称号、装扮、等级与 Best 成绩；需登录或完成账号身份验证。默认关闭。'**
  String get flowRankingBriefHint;

  /// No description provided for @flowCacheFishSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲数据（水鱼）'**
  String get flowCacheFishSongs;

  /// No description provided for @flowCacheUnionSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲数据（Union）'**
  String get flowCacheUnionSongs;

  /// No description provided for @flowCacheDifficulties.
  ///
  /// In zh, this message translates to:
  /// **'难度数据'**
  String get flowCacheDifficulties;

  /// No description provided for @flowCacheTags.
  ///
  /// In zh, this message translates to:
  /// **'标签数据'**
  String get flowCacheTags;

  /// No description provided for @flowCacheAlias1.
  ///
  /// In zh, this message translates to:
  /// **'别名数据源1'**
  String get flowCacheAlias1;

  /// No description provided for @flowCacheAlias2.
  ///
  /// In zh, this message translates to:
  /// **'别名数据源2'**
  String get flowCacheAlias2;

  /// No description provided for @flowCacheAlias3.
  ///
  /// In zh, this message translates to:
  /// **'别名数据源3'**
  String get flowCacheAlias3;

  /// No description provided for @flowCacheTitles.
  ///
  /// In zh, this message translates to:
  /// **'收藏品-称号'**
  String get flowCacheTitles;

  /// No description provided for @flowCacheIcons.
  ///
  /// In zh, this message translates to:
  /// **'收藏品-头像'**
  String get flowCacheIcons;

  /// No description provided for @flowCachePlates.
  ///
  /// In zh, this message translates to:
  /// **'收藏品-姓名框'**
  String get flowCachePlates;

  /// No description provided for @flowCacheFrames.
  ///
  /// In zh, this message translates to:
  /// **'收藏品-背景'**
  String get flowCacheFrames;

  /// No description provided for @flowCacheUnionMetadata.
  ///
  /// In zh, this message translates to:
  /// **'Union 元数据'**
  String get flowCacheUnionMetadata;

  /// No description provided for @flowCacheFishDescription.
  ///
  /// In zh, this message translates to:
  /// **'全量歌曲主库（diving-fish）'**
  String get flowCacheFishDescription;

  /// No description provided for @flowCacheUnionDescription.
  ///
  /// In zh, this message translates to:
  /// **'补充独有歌曲（godserver）'**
  String get flowCacheUnionDescription;

  /// No description provided for @flowCacheConstantDescription.
  ///
  /// In zh, this message translates to:
  /// **'谱面定数（diving-fish chart_stats）'**
  String get flowCacheConstantDescription;

  /// No description provided for @flowCacheTagDescription.
  ///
  /// In zh, this message translates to:
  /// **'DXRating 谱面标签'**
  String get flowCacheTagDescription;

  /// No description provided for @flowCacheTitleDescription.
  ///
  /// In zh, this message translates to:
  /// **'落雪称号'**
  String get flowCacheTitleDescription;

  /// No description provided for @flowCacheIconDescription.
  ///
  /// In zh, this message translates to:
  /// **'落雪头像'**
  String get flowCacheIconDescription;

  /// No description provided for @flowCachePlateDescription.
  ///
  /// In zh, this message translates to:
  /// **'落雪姓名框'**
  String get flowCachePlateDescription;

  /// No description provided for @flowCacheFrameDescription.
  ///
  /// In zh, this message translates to:
  /// **'落雪背景'**
  String get flowCacheFrameDescription;

  /// No description provided for @flowCacheMetadataDescription.
  ///
  /// In zh, this message translates to:
  /// **'cn/jp 可游玩地区等'**
  String get flowCacheMetadataDescription;

  /// No description provided for @flowCacheMaidataDescription.
  ///
  /// In zh, this message translates to:
  /// **'谱面追加辅助（追加列表 + 完整 maidata）'**
  String get flowCacheMaidataDescription;

  /// No description provided for @flowSongDetails.
  ///
  /// In zh, this message translates to:
  /// **'歌曲详情'**
  String get flowSongDetails;

  /// No description provided for @flowExpandOrCollapseSongInformation.
  ///
  /// In zh, this message translates to:
  /// **'展开或收起歌曲信息'**
  String get flowExpandOrCollapseSongInformation;

  /// No description provided for @flowFavorited.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get flowFavorited;

  /// No description provided for @flowAddToAFavoritesFolder.
  ///
  /// In zh, this message translates to:
  /// **'收藏到收藏夹'**
  String get flowAddToAFavoritesFolder;

  /// No description provided for @flowCreatedP0AndAddedThisChart.
  ///
  /// In zh, this message translates to:
  /// **'已创建收藏夹「{p0}」并将当前谱面加入'**
  String flowCreatedP0AndAddedThisChart(String p0);

  /// No description provided for @flowNoFavoritesFoldersYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有收藏夹'**
  String get flowNoFavoritesFoldersYet;

  /// No description provided for @flowCreateAFavoritesFolderFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先创建收藏夹'**
  String get flowCreateAFavoritesFolderFirst;

  /// No description provided for @flowP0Charts.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个谱面'**
  String flowP0Charts(String p0);

  /// No description provided for @flowNewFavoritesFolder.
  ///
  /// In zh, this message translates to:
  /// **'新建收藏夹'**
  String get flowNewFavoritesFolder;

  /// No description provided for @flowEnterAFolderName.
  ///
  /// In zh, this message translates to:
  /// **'请输入收藏夹名称'**
  String get flowEnterAFolderName;

  /// No description provided for @flowCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get flowCreate;

  /// No description provided for @flowPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get flowPause;

  /// No description provided for @flowPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get flowPlay;

  /// No description provided for @flowP0P1SBufferedAhead.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 已向前缓冲 {p1} 秒'**
  String flowP0P1SBufferedAhead(String p0, String p1);

  /// No description provided for @flowCouldNotLoadThePVCheckYour.
  ///
  /// In zh, this message translates to:
  /// **'PV 加载失败，请检查网络后重试'**
  String get flowCouldNotLoadThePVCheckYour;

  /// No description provided for @flowBackToSongDetails.
  ///
  /// In zh, this message translates to:
  /// **'返回歌曲详情'**
  String get flowBackToSongDetails;

  /// No description provided for @flowCopiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get flowCopiedToClipboard;

  /// No description provided for @flowExportZIPZip.
  ///
  /// In zh, this message translates to:
  /// **'导出压缩包 (.zip)'**
  String get flowExportZIPZip;

  /// No description provided for @flowMaidataTxtCoverArtAndAudioIn.
  ///
  /// In zh, this message translates to:
  /// **'maidata.txt + 曲绘 + 音源，通用谱面包'**
  String get flowMaidataTxtCoverArtAndAudioIn;

  /// No description provided for @flowExportAstroDXChartAdx.
  ///
  /// In zh, this message translates to:
  /// **'导出 AstroDX 谱面 (.adx)'**
  String get flowExportAstroDXChartAdx;

  /// No description provided for @flowOpenInAstroDXToInstallTheChart.
  ///
  /// In zh, this message translates to:
  /// **'用 AstroDX 打开即可自动安装谱面'**
  String get flowOpenInAstroDXToInstallTheChart;

  /// No description provided for @flowChooseWhereToSaveTheChartPackage.
  ///
  /// In zh, this message translates to:
  /// **'选择谱面包保存位置'**
  String get flowChooseWhereToSaveTheChartPackage;

  /// No description provided for @flowChooseWhereToSaveTheAstroDXChart.
  ///
  /// In zh, this message translates to:
  /// **'选择 AstroDX 谱面保存位置'**
  String get flowChooseWhereToSaveTheAstroDXChart;

  /// No description provided for @flowExportFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {p0}'**
  String flowExportFailedP0(String p0);

  /// No description provided for @flowSelectDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'选择难度'**
  String get flowSelectDifficulty;

  /// No description provided for @flowRenderedChartsAreForReferenceAndMay.
  ///
  /// In zh, this message translates to:
  /// **'渲染出的谱面仅供参考，不代表官方谱面。对于高密度谱面，请勿频繁拖动进度条，以免造成应用闪退或卡死。'**
  String get flowRenderedChartsAreForReferenceAndMay;

  /// No description provided for @flowLoadAudio.
  ///
  /// In zh, this message translates to:
  /// **'加载音频'**
  String get flowLoadAudio;

  /// No description provided for @flowTurnOffToLoadTheChartWithout.
  ///
  /// In zh, this message translates to:
  /// **'取消勾选可直接加载谱面，跳过音源下载'**
  String get flowTurnOffToLoadTheChartWithout;

  /// No description provided for @flowFetchingChartConstants.
  ///
  /// In zh, this message translates to:
  /// **'获取定数中...'**
  String get flowFetchingChartConstants;

  /// No description provided for @flowSongIDP0.
  ///
  /// In zh, this message translates to:
  /// **'歌曲ID {p0}'**
  String flowSongIDP0(String p0);

  /// No description provided for @flowChartCode.
  ///
  /// In zh, this message translates to:
  /// **'谱面代码'**
  String get flowChartCode;

  /// No description provided for @flowCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get flowCopy;

  /// No description provided for @flowExporting.
  ///
  /// In zh, this message translates to:
  /// **'导出中'**
  String get flowExporting;

  /// No description provided for @flowExport.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get flowExport;

  /// No description provided for @flowRender.
  ///
  /// In zh, this message translates to:
  /// **'渲染'**
  String get flowRender;

  /// No description provided for @flowVideoGeneratedTapSaveToPhotosOn.
  ///
  /// In zh, this message translates to:
  /// **'视频已生成，请在导出页点击“保存到相册”：{p0}×{p1} · {p2} MB'**
  String flowVideoGeneratedTapSaveToPhotosOn(String p0, String p1, String p2);

  /// No description provided for @flowLoadedMaidataWithP0Difficulties.
  ///
  /// In zh, this message translates to:
  /// **'已加载maidata，解析到 {p0} 个难度'**
  String flowLoadedMaidataWithP0Difficulties(String p0);

  /// No description provided for @flowUnsupportedEncodingUseUTF8OrShift.
  ///
  /// In zh, this message translates to:
  /// **'读取失败: 文件编码不受支持，请使用UTF-8或Shift-JIS编码'**
  String get flowUnsupportedEncodingUseUTF8OrShift;

  /// No description provided for @flowCouldNotOpenTheFilePickerP0.
  ///
  /// In zh, this message translates to:
  /// **'无法打开文件选择器: {p0}'**
  String flowCouldNotOpenTheFilePickerP0(String p0);

  /// No description provided for @flowCoverArtSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择曲绘'**
  String get flowCoverArtSelected;

  /// No description provided for @flowCoverArtSelectedUsingItsOriginalPath.
  ///
  /// In zh, this message translates to:
  /// **'已选择曲绘（使用原始路径）'**
  String get flowCoverArtSelectedUsingItsOriginalPath;

  /// No description provided for @flowCouldNotOpenTheImagePickerP0.
  ///
  /// In zh, this message translates to:
  /// **'无法打开图片选择器: {p0}'**
  String flowCouldNotOpenTheImagePickerP0(String p0);

  /// No description provided for @flowAudioSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择音源'**
  String get flowAudioSelected;

  /// No description provided for @flowAudioSelectedUsingItsOriginalPath.
  ///
  /// In zh, this message translates to:
  /// **'已选择音源（使用原始路径）'**
  String get flowAudioSelectedUsingItsOriginalPath;

  /// No description provided for @flowCouldNotOpenTheAudioPickerP0.
  ///
  /// In zh, this message translates to:
  /// **'无法打开音频选择器: {p0}'**
  String flowCouldNotOpenTheAudioPickerP0(String p0);

  /// No description provided for @flowTheFileForP0IsMissingAnd.
  ///
  /// In zh, this message translates to:
  /// **'「{p0}」的文件已不存在，已从列表移除'**
  String flowTheFileForP0IsMissingAnd(String p0);

  /// No description provided for @flowCouldNotParseAgainP0.
  ///
  /// In zh, this message translates to:
  /// **'重新解析失败：{p0}'**
  String flowCouldNotParseAgainP0(String p0);

  /// No description provided for @flowDeleteThisRecord.
  ///
  /// In zh, this message translates to:
  /// **'删除这条记录'**
  String get flowDeleteThisRecord;

  /// No description provided for @flowRemoveP0FromRecentlyParsedChartsAnd.
  ///
  /// In zh, this message translates to:
  /// **'将从「最近解析」中移除「{p0}」，并删除它的存档文件。'**
  String flowRemoveP0FromRecentlyParsedChartsAnd(String p0);

  /// No description provided for @flowDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get flowDelete;

  /// No description provided for @flowCouldNotReadThisFileTryAnother.
  ///
  /// In zh, this message translates to:
  /// **'读不到这个文件的内容，请换一个来源重试'**
  String get flowCouldNotReadThisFileTryAnother;

  /// No description provided for @flowImportFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{p0}'**
  String flowImportFailedP0(String p0);

  /// No description provided for @flowNoMaidataTxtFoundThisIsNot.
  ///
  /// In zh, this message translates to:
  /// **'这个压缩包里没找到 maidata.txt，不是有效的谱面包'**
  String get flowNoMaidataTxtFoundThisIsNot;

  /// No description provided for @flowUnsupportedMaidataTxtEncodingUseAUTF.
  ///
  /// In zh, this message translates to:
  /// **'maidata.txt 编码不受支持，请使用 UTF-8 或 Shift-JIS 编码的谱面包'**
  String get flowUnsupportedMaidataTxtEncodingUseAUTF;

  /// No description provided for @flowImportedAllThreeFilesFromP0Found.
  ///
  /// In zh, this message translates to:
  /// **'已从 {p0} 导入三件套，解析到 {p1} 个难度'**
  String flowImportedAllThreeFilesFromP0Found(String p0, String p1);

  /// No description provided for @flowImportedMaidataP0DifficultiesNoP1In.
  ///
  /// In zh, this message translates to:
  /// **'已导入 maidata（{p0} 个难度）；包内没有{p1}，可手动补选'**
  String flowImportedMaidataP0DifficultiesNoP1In(String p0, String p1);

  /// No description provided for @flowRecentlyParsed.
  ///
  /// In zh, this message translates to:
  /// **'最近解析'**
  String get flowRecentlyParsed;

  /// No description provided for @flowTapToParseTheArchivedFilesAgain.
  ///
  /// In zh, this message translates to:
  /// **'点击即可按存档重新解析；长按可删除'**
  String get flowTapToParseTheArchivedFilesAgain;

  /// No description provided for @flowSelectAMaidataFileFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择maidata文件'**
  String get flowSelectAMaidataFileFirst;

  /// No description provided for @flowNoValidDifficultiesFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到有效难度'**
  String get flowNoValidDifficultiesFound;

  /// No description provided for @flowTurnOffToLoadTheChartWithout2.
  ///
  /// In zh, this message translates to:
  /// **'取消勾选可直接加载谱面，跳过音源加载'**
  String get flowTurnOffToLoadTheChartWithout2;

  /// No description provided for @flowSelectionCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清除选择'**
  String get flowSelectionCleared;

  /// No description provided for @flowCustomChart.
  ///
  /// In zh, this message translates to:
  /// **'上传自定义谱面'**
  String get flowCustomChart;

  /// No description provided for @flowImportAChartPackage.
  ///
  /// In zh, this message translates to:
  /// **'从谱面包导入'**
  String get flowImportAChartPackage;

  /// No description provided for @flowSelectAnAdxOrZipPackageTo.
  ///
  /// In zh, this message translates to:
  /// **'选择一个 .adx 或 .zip 谱面包，自动解出 maidata.txt / 曲绘 / 音源'**
  String get flowSelectAnAdxOrZipPackageTo;

  /// No description provided for @flowExtracting.
  ///
  /// In zh, this message translates to:
  /// **'正在解压...'**
  String get flowExtracting;

  /// No description provided for @flowSelectChartPackage.
  ///
  /// In zh, this message translates to:
  /// **'选择谱面包'**
  String get flowSelectChartPackage;

  /// No description provided for @flowOrSelectTheThreeFilesSeparately.
  ///
  /// In zh, this message translates to:
  /// **'或分别选择下面三个文件'**
  String get flowOrSelectTheThreeFilesSeparately;

  /// No description provided for @flowSelectMaidataTxt.
  ///
  /// In zh, this message translates to:
  /// **'选择maidata.txt'**
  String get flowSelectMaidataTxt;

  /// No description provided for @flowRequiredATextFileContainingChartData.
  ///
  /// In zh, this message translates to:
  /// **'必须选择，包含谱面数据的txt文件'**
  String get flowRequiredATextFileContainingChartData;

  /// No description provided for @flowSelectCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'选择曲绘图片'**
  String get flowSelectCoverArt;

  /// No description provided for @flowOptionalChartBackgroundImagePNGJPG.
  ///
  /// In zh, this message translates to:
  /// **'可选，谱面背景图片（png/jpg）'**
  String get flowOptionalChartBackgroundImagePNGJPG;

  /// No description provided for @flowSelectAudio.
  ///
  /// In zh, this message translates to:
  /// **'选择音源文件'**
  String get flowSelectAudio;

  /// No description provided for @flowOptionalChartMusicMP3WAVOGG.
  ///
  /// In zh, this message translates to:
  /// **'可选，谱面背景音乐（mp3/wav/ogg）'**
  String get flowOptionalChartMusicMP3WAVOGG;

  /// No description provided for @flowParsedDifficulties.
  ///
  /// In zh, this message translates to:
  /// **'解析到的难度:'**
  String get flowParsedDifficulties;

  /// No description provided for @flowStartPlayback.
  ///
  /// In zh, this message translates to:
  /// **'开始播放'**
  String get flowStartPlayback;

  /// No description provided for @flowInstructions.
  ///
  /// In zh, this message translates to:
  /// **'使用说明:'**
  String get flowInstructions;

  /// No description provided for @flowOption1SelectAnAdxOrZip.
  ///
  /// In zh, this message translates to:
  /// **'方式一：点「选择谱面包」直接选一个 .adx / .zip，三件套一次填好'**
  String get flowOption1SelectAnAdxOrZip;

  /// No description provided for @flowOption2TapARecentlyParsedEntry.
  ///
  /// In zh, this message translates to:
  /// **'方式二：点「最近解析」里的记录，一键重新解析之前用过的谱面包'**
  String get flowOption2TapARecentlyParsedEntry;

  /// No description provided for @flowOption3SelectMaidataTxtCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'方式三：分别选择 maidata.txt、曲绘、音源三个文件'**
  String get flowOption3SelectMaidataTxtCoverArt;

  /// No description provided for @flow1MaidataTxtIsRequiredTheOther.
  ///
  /// In zh, this message translates to:
  /// **'1. maidata.txt 为必选，其余两个可留空'**
  String get flow1MaidataTxtIsRequiredTheOther;

  /// No description provided for @flow2DifficultiesAreDetectedAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'2. 系统会自动解析谱面中的难度'**
  String get flow2DifficultiesAreDetectedAutomatically;

  /// No description provided for @flow3SelectADifficultyThenStartPlayback.
  ///
  /// In zh, this message translates to:
  /// **'3. 选择想要渲染的难度后即可开始播放'**
  String get flow3SelectADifficultyThenStartPlayback;

  /// No description provided for @flowSelectedP0.
  ///
  /// In zh, this message translates to:
  /// **'已选择: {p0}'**
  String flowSelectedP0(String p0);

  /// No description provided for @flowChooseAgain2.
  ///
  /// In zh, this message translates to:
  /// **'重新选择'**
  String get flowChooseAgain2;

  /// No description provided for @flowChooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get flowChooseFile;

  /// No description provided for @flowChooseWhereToSaveTheSong.
  ///
  /// In zh, this message translates to:
  /// **'选择歌曲保存位置'**
  String get flowChooseWhereToSaveTheSong;

  /// No description provided for @flowDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'下载成功'**
  String get flowDownloaded;

  /// No description provided for @flowGoToCurrentSong.
  ///
  /// In zh, this message translates to:
  /// **'定位到正在播放'**
  String get flowGoToCurrentSong;

  /// No description provided for @flowRebuildLibrary.
  ///
  /// In zh, this message translates to:
  /// **'重建曲库'**
  String get flowRebuildLibrary;

  /// No description provided for @flowMusicPlayerSettings.
  ///
  /// In zh, this message translates to:
  /// **'随身听设置'**
  String get flowMusicPlayerSettings;

  /// No description provided for @flowShowFloatingPlayerAfterLeavingThisPage.
  ///
  /// In zh, this message translates to:
  /// **'退出随身听页面时显示悬浮球'**
  String get flowShowFloatingPlayerAfterLeavingThisPage;

  /// No description provided for @flowWhenOffLeavingTheMusicPlayerWill.
  ///
  /// In zh, this message translates to:
  /// **'关闭后，离开随身听页面也不会重新显示悬浮球'**
  String get flowWhenOffLeavingTheMusicPlayerWill;

  /// No description provided for @flowSearchTitleArtistGenreAliasBPMID.
  ///
  /// In zh, this message translates to:
  /// **'搜索曲名 / 艺术家 / 流派 / 别名 / BPM / id'**
  String get flowSearchTitleArtistGenreAliasBPMID;

  /// No description provided for @flowNowPlaying.
  ///
  /// In zh, this message translates to:
  /// **'正在播放'**
  String get flowNowPlaying;

  /// No description provided for @flowPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get flowPaused;

  /// No description provided for @flowUnknownArtist.
  ///
  /// In zh, this message translates to:
  /// **'未知艺术家'**
  String get flowUnknownArtist;

  /// No description provided for @flowDownloadSong.
  ///
  /// In zh, this message translates to:
  /// **'下载歌曲'**
  String get flowDownloadSong;

  /// No description provided for @flowAddToPlayNext.
  ///
  /// In zh, this message translates to:
  /// **'加入下次想玩'**
  String get flowAddToPlayNext;

  /// No description provided for @flowAddedToPlayNext.
  ///
  /// In zh, this message translates to:
  /// **'已加入下次想玩'**
  String get flowAddedToPlayNext;

  /// No description provided for @flowPlayMusic.
  ///
  /// In zh, this message translates to:
  /// **'播放音乐'**
  String get flowPlayMusic;

  /// No description provided for @flowNothingPlayingYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有在放的音乐'**
  String get flowNothingPlayingYet;

  /// No description provided for @flowPreparingAudio.
  ///
  /// In zh, this message translates to:
  /// **'正在准备音源…'**
  String get flowPreparingAudio;

  /// No description provided for @flowPrevious2.
  ///
  /// In zh, this message translates to:
  /// **'上一首'**
  String get flowPrevious2;

  /// No description provided for @flowNext2.
  ///
  /// In zh, this message translates to:
  /// **'下一首'**
  String get flowNext2;

  /// No description provided for @flowChooseSortOrder.
  ///
  /// In zh, this message translates to:
  /// **'选择排序方式'**
  String get flowChooseSortOrder;

  /// No description provided for @flowDXScoreRate.
  ///
  /// In zh, this message translates to:
  /// **'DX分数达成率'**
  String get flowDXScoreRate;

  /// No description provided for @flowAchievementFilter.
  ///
  /// In zh, this message translates to:
  /// **'达成率筛选'**
  String get flowAchievementFilter;

  /// No description provided for @flowComboSyncFilter.
  ///
  /// In zh, this message translates to:
  /// **'连击/同步筛选'**
  String get flowComboSyncFilter;

  /// No description provided for @flowAnyOptionWithinAGroupMatchesWhen.
  ///
  /// In zh, this message translates to:
  /// **'同组内满足任意一项，连击和同步都选时需同时满足'**
  String get flowAnyOptionWithinAGroupMatchesWhen;

  /// No description provided for @flowCloseSearch.
  ///
  /// In zh, this message translates to:
  /// **'关闭搜索'**
  String get flowCloseSearch;

  /// No description provided for @flowSearchSongTitleOrConstant.
  ///
  /// In zh, this message translates to:
  /// **'搜索曲名或定数'**
  String get flowSearchSongTitleOrConstant;

  /// No description provided for @flowNoCachedDataFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到缓存数据'**
  String get flowNoCachedDataFound;

  /// No description provided for @flowTapASegmentOrStatisticToFilter.
  ///
  /// In zh, this message translates to:
  /// **'点色块或统计项筛选 · 共 '**
  String get flowTapASegmentOrStatisticToFilter;

  /// No description provided for @flowEntries.
  ///
  /// In zh, this message translates to:
  /// **' 条'**
  String get flowEntries;

  /// No description provided for @flowFilteredByP0TapAgainToClear.
  ///
  /// In zh, this message translates to:
  /// **'已筛选 {p0} · 再点取消'**
  String flowFilteredByP0TapAgainToClear(String p0);

  /// No description provided for @flowP0P1EntriesTapToFilter.
  ///
  /// In zh, this message translates to:
  /// **'{p0} {p1} 条，点按筛选'**
  String flowP0P1EntriesTapToFilter(String p0, String p1);

  /// No description provided for @flowComboSync.
  ///
  /// In zh, this message translates to:
  /// **'连击/同步'**
  String get flowComboSync;

  /// No description provided for @flowPerPage.
  ///
  /// In zh, this message translates to:
  /// **'每页显示'**
  String get flowPerPage;

  /// No description provided for @flowP0Entries.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 条'**
  String flowP0Entries(String p0);

  /// No description provided for @flowList.
  ///
  /// In zh, this message translates to:
  /// **'列表'**
  String get flowList;

  /// No description provided for @flowUnknownSong.
  ///
  /// In zh, this message translates to:
  /// **'未知歌曲'**
  String get flowUnknownSong;

  /// No description provided for @flowSelectMultipleAnySelectedOptionMatches.
  ///
  /// In zh, this message translates to:
  /// **'可多选，满足任意一项即可'**
  String get flowSelectMultipleAnySelectedOptionMatches;

  /// No description provided for @flowClearP0.
  ///
  /// In zh, this message translates to:
  /// **'清除{p0}'**
  String flowClearP0(String p0);

  /// No description provided for @flowQuickOptions.
  ///
  /// In zh, this message translates to:
  /// **'快捷选项'**
  String get flowQuickOptions;

  /// No description provided for @flowCustomRange.
  ///
  /// In zh, this message translates to:
  /// **'自定义范围'**
  String get flowCustomRange;

  /// No description provided for @flowExportAsImage.
  ///
  /// In zh, this message translates to:
  /// **'导出为图片'**
  String get flowExportAsImage;

  /// No description provided for @flowSelectCategory.
  ///
  /// In zh, this message translates to:
  /// **'选择种类'**
  String get flowSelectCategory;

  /// No description provided for @flowLevel.
  ///
  /// In zh, this message translates to:
  /// **'等级'**
  String get flowLevel;

  /// No description provided for @flowNoChartDesignerDataFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到谱师数据'**
  String get flowNoChartDesignerDataFound;

  /// No description provided for @flowSelectVersion.
  ///
  /// In zh, this message translates to:
  /// **'选择版本'**
  String get flowSelectVersion;

  /// No description provided for @flowNoComposerDataFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到曲师数据'**
  String get flowNoComposerDataFound;

  /// No description provided for @flowNoGenreDataFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到流派数据'**
  String get flowNoGenreDataFound;

  /// No description provided for @flowSelectGenre.
  ///
  /// In zh, this message translates to:
  /// **'选择流派'**
  String get flowSelectGenre;

  /// No description provided for @flowP0P1Songs2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} ({p1}首)'**
  String flowP0P1Songs2(String p0, String p1);

  /// No description provided for @flowSelectLevel.
  ///
  /// In zh, this message translates to:
  /// **'选择等级'**
  String get flowSelectLevel;

  /// No description provided for @flowNoCompletedSongsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无已完成歌曲'**
  String get flowNoCompletedSongsYet;

  /// No description provided for @flowNoIncompleteSongs.
  ///
  /// In zh, this message translates to:
  /// **'暂无未完成歌曲'**
  String get flowNoIncompleteSongs;

  /// No description provided for @flowStoragePermissionIsRequiredToExportImages.
  ///
  /// In zh, this message translates to:
  /// **'需要存储权限才能导出图片到相册，请在设置中开启权限'**
  String get flowStoragePermissionIsRequiredToExportImages;

  /// No description provided for @flowPersonalizedScores.
  ///
  /// In zh, this message translates to:
  /// **'个性化成绩'**
  String get flowPersonalizedScores;

  /// No description provided for @flowExportFailedP02.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{p0}'**
  String flowExportFailedP02(String p0);

  /// No description provided for @flowCouldNotOpenTheAuthorizationPageLink.
  ///
  /// In zh, this message translates to:
  /// **'无法打开授权页，链接已复制到剪贴板'**
  String get flowCouldNotOpenTheAuthorizationPageLink;

  /// No description provided for @flowFetchingFriendDataAndComparing.
  ///
  /// In zh, this message translates to:
  /// **'正在拉取好友数据并对比…'**
  String get flowFetchingFriendDataAndComparing;

  /// No description provided for @flowCompareMyP0ScoresWithMyFriend.
  ///
  /// In zh, this message translates to:
  /// **'用我的{p0}成绩，对比好友在这里的成绩'**
  String flowCompareMyP0ScoresWithMyFriend(String p0);

  /// No description provided for @flowEnterYourFriendSP0.
  ///
  /// In zh, this message translates to:
  /// **'输入好友的{p0}'**
  String flowEnterYourFriendSP0(String p0);

  /// No description provided for @flowCompare.
  ///
  /// In zh, this message translates to:
  /// **'开始对比'**
  String get flowCompare;

  /// No description provided for @flowCompareWithAFriend.
  ///
  /// In zh, this message translates to:
  /// **'和好友比比看'**
  String get flowCompareWithAFriend;

  /// No description provided for @flowEnterYourFriendSP0ToCompare.
  ///
  /// In zh, this message translates to:
  /// **'输入好友的{p0}开始对比\n好友需要在{p1}有数据'**
  String flowEnterYourFriendSP0ToCompare(String p0, String p1);

  /// No description provided for @flowClearHistory.
  ///
  /// In zh, this message translates to:
  /// **'清空历史'**
  String get flowClearHistory;

  /// No description provided for @flowClearAllHistory.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空全部历史记录吗？'**
  String get flowClearAllHistory;

  /// No description provided for @flowPastComparisons.
  ///
  /// In zh, this message translates to:
  /// **'历史对比'**
  String get flowPastComparisons;

  /// No description provided for @flowP0P1P2SongsInCommon.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · {p1} · 共同 {p2} 首'**
  String flowP0P1P2SongsInCommon(String p0, String p1, String p2);

  /// No description provided for @flowPrivate.
  ///
  /// In zh, this message translates to:
  /// **'未公开'**
  String get flowPrivate;

  /// No description provided for @flowSameScore.
  ///
  /// In zh, this message translates to:
  /// **'同分'**
  String get flowSameScore;

  /// No description provided for @flowMyCharts.
  ///
  /// In zh, this message translates to:
  /// **'我的谱面'**
  String get flowMyCharts;

  /// No description provided for @flowFriendSCharts.
  ///
  /// In zh, this message translates to:
  /// **'好友谱面'**
  String get flowFriendSCharts;

  /// No description provided for @flowSharedCharts.
  ///
  /// In zh, this message translates to:
  /// **'共同谱面'**
  String get flowSharedCharts;

  /// No description provided for @flowAllDifficulties.
  ///
  /// In zh, this message translates to:
  /// **'全部难度'**
  String get flowAllDifficulties;

  /// No description provided for @flowConstantHighToLowShowingP0P1.
  ///
  /// In zh, this message translates to:
  /// **'按定数从高到低 · 显示 {p0} / {p1}'**
  String flowConstantHighToLowShowingP0P1(String p0, String p1);

  /// No description provided for @flowNoMatchingCharts.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的谱面'**
  String get flowNoMatchingCharts;

  /// No description provided for @flowLoadMoreP0P1.
  ///
  /// In zh, this message translates to:
  /// **'加载更多（{p0} / {p1}）'**
  String flowLoadMoreP0P1(String p0, String p1);

  /// No description provided for @flowTie.
  ///
  /// In zh, this message translates to:
  /// **'平局'**
  String get flowTie;

  /// No description provided for @flowSelectFirstCharacter.
  ///
  /// In zh, this message translates to:
  /// **'选择首字'**
  String get flowSelectFirstCharacter;

  /// No description provided for @flowP0SongsExcludedFromPlateProgress.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 首，不计入牌子进度'**
  String flowP0SongsExcludedFromPlateProgress(String p0);

  /// No description provided for @flowP0P1P2Statistics.
  ///
  /// In zh, this message translates to:
  /// **'{p0}{p1}({p2})统计'**
  String flowP0P1P2Statistics(String p0, String p1, String p2);

  /// No description provided for @flowRecommendationSettings.
  ///
  /// In zh, this message translates to:
  /// **'推荐参数'**
  String get flowRecommendationSettings;

  /// No description provided for @flowConstantsP0P1P2Results.
  ///
  /// In zh, this message translates to:
  /// **'定数范围 {p0} ~ {p1} · 共 {p2} 条结果'**
  String flowConstantsP0P1P2Results(String p0, String p1, String p2);

  /// No description provided for @flowTargetRating.
  ///
  /// In zh, this message translates to:
  /// **'目标 Rating'**
  String get flowTargetRating;

  /// No description provided for @flowRecommend.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get flowRecommend;

  /// No description provided for @flowLoadingRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'正在加载推荐结果...'**
  String get flowLoadingRecommendations;

  /// No description provided for @flowNoRecommendationsCheckTheRatingYouEntered.
  ///
  /// In zh, this message translates to:
  /// **'暂无推荐结果，请检查Rating输入是否正确'**
  String get flowNoRecommendationsCheckTheRatingYouEntered;

  /// No description provided for @flowCouldNotSaveHistoryP0.
  ///
  /// In zh, this message translates to:
  /// **'保存历史失败：{p0}'**
  String flowCouldNotSaveHistoryP0(String p0);

  /// No description provided for @flowCouldNotDeleteDataPointP0.
  ///
  /// In zh, this message translates to:
  /// **'删除记录点失败：{p0}'**
  String flowCouldNotDeleteDataPointP0(String p0);

  /// No description provided for @flowLinkYourQQThroughSyncScoresTo.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 还没绑定 QQ，请先在「同步成绩到 AWMC NET」入口绑定'**
  String get flowLinkYourQQThroughSyncScoresTo;

  /// No description provided for @flowNoRatingRecordsForQQP0On.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 上 QQ {p0} 近 90 天没有任何 Rating 记录'**
  String flowNoRatingRecordsForQQP0On(String p0);

  /// No description provided for @flowSyncedRatingHistoryFromAWMCNETAdded.
  ///
  /// In zh, this message translates to:
  /// **'已从 AWMC NET 同步 Rating 趋势，新增 {p0} 条'**
  String flowSyncedRatingHistoryFromAWMCNETAdded(String p0);

  /// No description provided for @flowNoNewAWMCNETPointsP0Already.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 没有新数据点（{p0} 条都已记录过）'**
  String flowNoNewAWMCNETPointsP0Already(String p0);

  /// No description provided for @flowSyncRatingHistoryFromAWMCNET.
  ///
  /// In zh, this message translates to:
  /// **'从 AWMC NET 同步 Rating 趋势'**
  String get flowSyncRatingHistoryFromAWMCNET;

  /// No description provided for @flowAddHistoryRecord.
  ///
  /// In zh, this message translates to:
  /// **'添加历史记录'**
  String get flowAddHistoryRecord;

  /// No description provided for @flowCurrentSourceP0.
  ///
  /// In zh, this message translates to:
  /// **'当前数据源：{p0}'**
  String flowCurrentSourceP0(String p0);

  /// No description provided for @flowBaselinesForP0ChartsP1ScoreChanges.
  ///
  /// In zh, this message translates to:
  /// **'已记录 {p0} 张谱面的成绩基线 · {p1} 次成绩变化（曲目详情页里，单谱的达成率 / DX分数曲线就画在这些变化上）'**
  String flowBaselinesForP0ChartsP1ScoreChanges(String p0, String p1);

  /// No description provided for @flowDivingFishLXNSAWMCNETHistoryIs.
  ///
  /// In zh, this message translates to:
  /// **'水鱼 / 落雪 / AWMC NET 按账号分别记录历史。{p0}（AWMC NET 数据源下可点右上角「云同步」按钮回填历史趋势）'**
  String flowDivingFishLXNSAWMCNETHistoryIs(String p0);

  /// No description provided for @flowDivingFishLXNSAWMCNETHistoryIs2.
  ///
  /// In zh, this message translates to:
  /// **'水鱼 / 落雪 / AWMC NET 按账号分别记录历史。{p0}（历史只能从现在开始攒：水鱼与落雪都不提供历史成绩接口）'**
  String flowDivingFishLXNSAWMCNETHistoryIs2(String p0);

  /// No description provided for @flowHighest.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get flowHighest;

  /// No description provided for @flowDataPoints.
  ///
  /// In zh, this message translates to:
  /// **'记录点'**
  String get flowDataPoints;

  /// No description provided for @flowP0EntriesShowingTheLatest30.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 条，显示最近 30 条'**
  String flowP0EntriesShowingTheLatest30(String p0);

  /// No description provided for @flowNoHistoryYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有历史数据'**
  String get flowNoHistoryYet;

  /// No description provided for @flowEachDataRefreshRecordsAPointAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'每次「拉取成绩并更新数据」都会顺手记一笔，不需要额外操作。\n时间精确到秒；同一秒重复刷新会更新该点，不同时间的变化会分别保留。'**
  String get flowEachDataRefreshRecordsAPointAutomatically;

  /// No description provided for @flowAddRatingHistory.
  ///
  /// In zh, this message translates to:
  /// **'添加 Rating 历史'**
  String get flowAddRatingHistory;

  /// No description provided for @flowCurrentTheoreticalRating.
  ///
  /// In zh, this message translates to:
  /// **'当前理论 Rating'**
  String get flowCurrentTheoreticalRating;

  /// No description provided for @flowBest35Optional.
  ///
  /// In zh, this message translates to:
  /// **'Best35（可选）'**
  String get flowBest35Optional;

  /// No description provided for @flowCurrentTheoreticalB35.
  ///
  /// In zh, this message translates to:
  /// **'当前理论 B35'**
  String get flowCurrentTheoreticalB35;

  /// No description provided for @flowBest15Optional.
  ///
  /// In zh, this message translates to:
  /// **'Best15（可选）'**
  String get flowBest15Optional;

  /// No description provided for @flowCurrentTheoreticalB15.
  ///
  /// In zh, this message translates to:
  /// **'当前理论 B15'**
  String get flowCurrentTheoreticalB15;

  /// No description provided for @flowAboutScoreImprovementHistory.
  ///
  /// In zh, this message translates to:
  /// **'关于成绩提升历史'**
  String get flowAboutScoreImprovementHistory;

  /// No description provided for @flowLocalScoreHistoryForThisAccount.
  ///
  /// In zh, this message translates to:
  /// **'当前账号的本地成绩历史'**
  String get flowLocalScoreHistoryForThisAccount;

  /// No description provided for @flowRecordingStartsAfterADataRefreshThe.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据后开始记录；首次无旧成绩时仅建立基线。'**
  String get flowRecordingStartsAfterADataRefreshThe;

  /// No description provided for @flowRecordedSinceP0SameDayChangesTo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 起记录 · 同日同谱面自动合并'**
  String flowRecordedSinceP0SameDayChangesTo(String p0);

  /// No description provided for @flowCharts.
  ///
  /// In zh, this message translates to:
  /// **'谱面'**
  String get flowCharts;

  /// No description provided for @flowImprovement.
  ///
  /// In zh, this message translates to:
  /// **'提升'**
  String get flowImprovement;

  /// No description provided for @flowChanges.
  ///
  /// In zh, this message translates to:
  /// **'变化次数'**
  String get flowChanges;

  /// No description provided for @flowRecordingRules.
  ///
  /// In zh, this message translates to:
  /// **'记录规则'**
  String get flowRecordingRules;

  /// No description provided for @flowLoadMoreFromThisDayP0Charts.
  ///
  /// In zh, this message translates to:
  /// **'加载当天更多记录（剩余 {p0} 张）'**
  String flowLoadMoreFromThisDayP0Charts(String p0);

  /// No description provided for @flowNoRatingsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无评分记录'**
  String get flowNoRatingsYet;

  /// No description provided for @flowNoCommentsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无评论'**
  String get flowNoCommentsYet;

  /// No description provided for @flowNoBest50DataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无Best50数据'**
  String get flowNoBest50DataYet;

  /// No description provided for @flowReturnHomeAndTapRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'请返回首页点击“拉取成绩并更新数据”按钮获取'**
  String get flowReturnHomeAndTapRefreshData;

  /// No description provided for @flowTheoreticalRatingBest50.
  ///
  /// In zh, this message translates to:
  /// **'理论Rating Best50'**
  String get flowTheoreticalRatingBest50;

  /// No description provided for @flowSaveCurrentRecord.
  ///
  /// In zh, this message translates to:
  /// **'保存当前记录'**
  String get flowSaveCurrentRecord;

  /// No description provided for @flowHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get flowHistory;

  /// No description provided for @flowAccountDataChangedReopenBest50BeforeSaving.
  ///
  /// In zh, this message translates to:
  /// **'账号数据已更新，请重新打开 Best50 后保存'**
  String get flowAccountDataChangedReopenBest50BeforeSaving;

  /// No description provided for @flowBest50RecordSavedP0.
  ///
  /// In zh, this message translates to:
  /// **'Best50 记录已保存 ({p0})'**
  String flowBest50RecordSavedP0(String p0);

  /// No description provided for @flowBest50History.
  ///
  /// In zh, this message translates to:
  /// **'Best50 历史记录'**
  String get flowBest50History;

  /// No description provided for @flowNoSavedRecordsTapSaveCurrentRecord.
  ///
  /// In zh, this message translates to:
  /// **'暂无保存的记录，点击\"保存当前记录\"按钮保存'**
  String get flowNoSavedRecordsTapSaveCurrentRecord;

  /// No description provided for @flowTheoreticalRatingAverageP0.
  ///
  /// In zh, this message translates to:
  /// **'理论 Rating（平均 {p0}）'**
  String flowTheoreticalRatingAverageP0(String p0);

  /// No description provided for @flowCurrentRatingAverageP0.
  ///
  /// In zh, this message translates to:
  /// **'当前 Rating（平均 {p0}）'**
  String flowCurrentRatingAverageP0(String p0);

  /// No description provided for @flowTheoretical.
  ///
  /// In zh, this message translates to:
  /// **'理论值'**
  String get flowTheoretical;

  /// No description provided for @flowAverageAchievementDXScoreRate.
  ///
  /// In zh, this message translates to:
  /// **'平均达成率 / DX 分数达成率'**
  String get flowAverageAchievementDXScoreRate;

  /// No description provided for @flowTagStatistics.
  ///
  /// In zh, this message translates to:
  /// **'标签统计'**
  String get flowTagStatistics;

  /// No description provided for @flowTheoreticalBest50.
  ///
  /// In zh, this message translates to:
  /// **'理论 Best50'**
  String get flowTheoreticalBest50;

  /// No description provided for @flowCalculatingFittedBest50.
  ///
  /// In zh, this message translates to:
  /// **'正在计算拟合Best50...'**
  String get flowCalculatingFittedBest50;

  /// No description provided for @flowNoFittedBest50DataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无拟合Best50数据'**
  String get flowNoFittedBest50DataYet;

  /// No description provided for @flowFittedTotalRatingDifferenceFromBest50Average.
  ///
  /// In zh, this message translates to:
  /// **'拟合总 Rating · 较 Best50（平均 {p0}）'**
  String flowFittedTotalRatingDifferenceFromBest50Average(String p0);

  /// No description provided for @flowModeP0.
  ///
  /// In zh, this message translates to:
  /// **'模式 {p0}'**
  String flowModeP0(String p0);

  /// No description provided for @flowNoDataToExport.
  ///
  /// In zh, this message translates to:
  /// **'没有数据可导出'**
  String get flowNoDataToExport;

  /// No description provided for @flowCategoryChartDesigner50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 谱师50 - {p0}'**
  String flowCategoryChartDesigner50P0(String p0);

  /// No description provided for @flowCategoryVersion50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 版本50 - {p0}'**
  String flowCategoryVersion50P0(String p0);

  /// No description provided for @flowCategoryGenre50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 流派50 - {p0}'**
  String flowCategoryGenre50P0(String p0);

  /// No description provided for @flowCategoryStar50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 星数50 - {p0}'**
  String flowCategoryStar50P0(String p0);

  /// No description provided for @flowCategoryTag50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 标签50 - {p0}'**
  String flowCategoryTag50P0(String p0);

  /// No description provided for @flowCategoryRandom50.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 随机50'**
  String get flowCategoryRandom50;

  /// No description provided for @flowCategoryOverreach50.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 越级50'**
  String get flowCategoryOverreach50;

  /// No description provided for @flowCategoryDifficulty50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 难度50 - {p0}'**
  String flowCategoryDifficulty50P0(String p0);

  /// No description provided for @flowCategoryBestP0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: Best {p0}'**
  String flowCategoryBestP0(String p0);

  /// No description provided for @flowCategoryP0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: {p0}'**
  String flowCategoryP0(String p0);

  /// No description provided for @flowChooseCategory.
  ///
  /// In zh, this message translates to:
  /// **'选择类型'**
  String get flowChooseCategory;

  /// No description provided for @flowNoVersionDataFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到版本数据'**
  String get flowNoVersionDataFound;

  /// No description provided for @flowSelectStars.
  ///
  /// In zh, this message translates to:
  /// **'选择星数'**
  String get flowSelectStars;

  /// No description provided for @flowGenerateBestN.
  ///
  /// In zh, this message translates to:
  /// **'生成 Best N'**
  String get flowGenerateBestN;

  /// No description provided for @flowEnterAnIntegerOf1OrMore.
  ///
  /// In zh, this message translates to:
  /// **'请输入 ≥ 1 的整数'**
  String get flowEnterAnIntegerOf1OrMore;

  /// No description provided for @flowNoTagDataFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到标签数据'**
  String get flowNoTagDataFound;

  /// No description provided for @flowSelectTag.
  ///
  /// In zh, this message translates to:
  /// **'选择标签'**
  String get flowSelectTag;

  /// No description provided for @flowNoMatchingChartDesigners.
  ///
  /// In zh, this message translates to:
  /// **'没有找到符合条件的谱师数据'**
  String get flowNoMatchingChartDesigners;

  /// No description provided for @flowP0P1Charts.
  ///
  /// In zh, this message translates to:
  /// **'{p0} ({p1}谱面)'**
  String flowP0P1Charts(String p0, String p1);

  /// No description provided for @flowTotalCharts.
  ///
  /// In zh, this message translates to:
  /// **'总谱面数'**
  String get flowTotalCharts;

  /// No description provided for @flowAverageRA.
  ///
  /// In zh, this message translates to:
  /// **'平均RA值'**
  String get flowAverageRA;

  /// No description provided for @flowInclusionMode.
  ///
  /// In zh, this message translates to:
  /// **'包含关系模式'**
  String get flowInclusionMode;

  /// No description provided for @flowDrawAgain.
  ///
  /// In zh, this message translates to:
  /// **'再抽一次'**
  String get flowDrawAgain;

  /// No description provided for @flowNoChartDesigner50DataForP0.
  ///
  /// In zh, this message translates to:
  /// **'暂无谱师50 - {p0} 数据'**
  String flowNoChartDesigner50DataForP0(String p0);

  /// No description provided for @flowNoVersion50DataForP0.
  ///
  /// In zh, this message translates to:
  /// **'暂无版本50 - {p0} 数据'**
  String flowNoVersion50DataForP0(String p0);

  /// No description provided for @flowNoGenre50DataForP0.
  ///
  /// In zh, this message translates to:
  /// **'暂无流派50 - {p0} 数据'**
  String flowNoGenre50DataForP0(String p0);

  /// No description provided for @flowNoStar50DataForP0.
  ///
  /// In zh, this message translates to:
  /// **'暂无星数50 - {p0} 数据'**
  String flowNoStar50DataForP0(String p0);

  /// No description provided for @flowNoP0DataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无{p0}数据'**
  String flowNoP0DataYet(String p0);

  /// No description provided for @flowRefreshArcadePlayCountsFromMeBefore.
  ///
  /// In zh, this message translates to:
  /// **'请先在「我的」页「刷新机台游玩次数」，再查看 PC50'**
  String get flowRefreshArcadePlayCountsFromMeBefore;

  /// No description provided for @flowSelectTagP0.
  ///
  /// In zh, this message translates to:
  /// **'选择标签: {p0}'**
  String flowSelectTagP0(String p0);

  /// No description provided for @flowCalculatingPersonalizedFittedBest50.
  ///
  /// In zh, this message translates to:
  /// **'正在计算个性化拟合Best50...'**
  String get flowCalculatingPersonalizedFittedBest50;

  /// No description provided for @flowSelectATagFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择一个标签'**
  String get flowSelectATagFirst;

  /// No description provided for @flowSelectATagToShowYourTop.
  ///
  /// In zh, this message translates to:
  /// **'选择标签后，将显示包含该标签且有游玩记录\n在拟合定数下RA前50的谱面'**
  String get flowSelectATagToShowYourTop;

  /// No description provided for @flowNoFittedBest50DataForTagP0.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签\"{p0}\"的拟合Best50数据'**
  String flowNoFittedBest50DataForTagP0(String p0);

  /// No description provided for @flowNoMatchingPlayRecordsMayExistTry.
  ///
  /// In zh, this message translates to:
  /// **'该标签可能没有对应的游玩记录\n可尝试更换其他标签'**
  String get flowNoMatchingPlayRecordsMayExistTry;

  /// No description provided for @flowChangeTag.
  ///
  /// In zh, this message translates to:
  /// **'更换标签'**
  String get flowChangeTag;

  /// No description provided for @flowFittedTotalRatingDifferenceFromThisTag.
  ///
  /// In zh, this message translates to:
  /// **'拟合总 Rating · 较该标签 Best50（平均 {p0}）'**
  String flowFittedTotalRatingDifferenceFromThisTag(String p0);

  /// No description provided for @flowNoCachedPlayData.
  ///
  /// In zh, this message translates to:
  /// **'暂无游玩数据缓存'**
  String get flowNoCachedPlayData;

  /// No description provided for @flowIdealRatingRaiseNonSSSScoresTo.
  ///
  /// In zh, this message translates to:
  /// **'理想 Rating · 非 SSS+ 成绩升到上一档的下限'**
  String get flowIdealRatingRaiseNonSSSScoresTo;

  /// No description provided for @flowOriginalRating.
  ///
  /// In zh, this message translates to:
  /// **'原 Rating'**
  String get flowOriginalRating;

  /// No description provided for @flowNewEntries.
  ///
  /// In zh, this message translates to:
  /// **'新进榜'**
  String get flowNewEntries;

  /// No description provided for @flowNewEntriesThisTimeP0Songs.
  ///
  /// In zh, this message translates to:
  /// **'本次新进榜（{p0} 首）'**
  String flowNewEntriesThisTimeP0Songs(String p0);

  /// No description provided for @flowNoNewEntriesTheSameChartsRemain.
  ///
  /// In zh, this message translates to:
  /// **'无新歌进榜（升档后榜单成员不变）'**
  String get flowNoNewEntriesTheSameChartsRemain;

  /// No description provided for @flowConstantP0RAP1P2.
  ///
  /// In zh, this message translates to:
  /// **'定数 {p0} · RA {p1} → {p2}'**
  String flowConstantP0RAP1P2(String p0, String p1, String p2);

  /// No description provided for @flowNoData2.
  ///
  /// In zh, this message translates to:
  /// **'无数据'**
  String get flowNoData2;

  /// No description provided for @flowSlotP0.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 格'**
  String flowSlotP0(String p0);

  /// No description provided for @flowNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get flowNotSelected;

  /// No description provided for @flowP0P1ConstantP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · {p1} · 定数 {p2}'**
  String flowP0P1ConstantP2(String p0, String p1, String p2);

  /// No description provided for @flowSelectASongFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择歌曲'**
  String get flowSelectASongFirst;

  /// No description provided for @flowInvalidAchievementExceedsP0.
  ///
  /// In zh, this message translates to:
  /// **'非法数据：达成率超过 {p0}%'**
  String flowInvalidAchievementExceedsP0(String p0);

  /// No description provided for @flowInvalidDXScoreExceedsTheChartMaximum.
  ///
  /// In zh, this message translates to:
  /// **'非法数据：DX 分数超过谱面上限 {p0}'**
  String flowInvalidDXScoreExceedsTheChartMaximum(String p0);

  /// No description provided for @flowClearThisCard.
  ///
  /// In zh, this message translates to:
  /// **'清空本卡'**
  String get flowClearThisCard;

  /// No description provided for @flowNoCardsFilledInYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有填写任何卡片'**
  String get flowNoCardsFilledInYet;

  /// No description provided for @flowByP0.
  ///
  /// In zh, this message translates to:
  /// **'按{p0}'**
  String flowByP0(String p0);

  /// No description provided for @flowClearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空全部'**
  String get flowClearAll;

  /// No description provided for @flowClearAll50SlotsThisCannotBe.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空全部 50 个卡位吗？此操作不可撤销。'**
  String get flowClearAll50SlotsThisCannotBe;

  /// No description provided for @flowCustomBest50TotalRA.
  ///
  /// In zh, this message translates to:
  /// **'自定义 Best50 总 RA'**
  String get flowCustomBest50TotalRA;

  /// No description provided for @flowCurrentOrderP0ClearedWhenCardsChange.
  ///
  /// In zh, this message translates to:
  /// **'当前排序：{p0}（卡片变动后自动清除）'**
  String flowCurrentOrderP0ClearedWhenCardsChange(String p0);

  /// No description provided for @flowAutoSort.
  ///
  /// In zh, this message translates to:
  /// **'一键排序'**
  String get flowAutoSort;

  /// No description provided for @flowTapToFillIn.
  ///
  /// In zh, this message translates to:
  /// **'点击填写'**
  String get flowTapToFillIn;

  /// No description provided for @flowP0Passed.
  ///
  /// In zh, this message translates to:
  /// **'/ {p0} 已合格'**
  String flowP0Passed(String p0);

  /// No description provided for @flowRedPassP0.
  ///
  /// In zh, this message translates to:
  /// **'赤合格 {p0}'**
  String flowRedPassP0(String p0);

  /// No description provided for @flowFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'不合格 {p0}'**
  String flowFailedP0(String p0);

  /// No description provided for @flowDanCourseSongs.
  ///
  /// In zh, this message translates to:
  /// **'段位曲目'**
  String get flowDanCourseSongs;

  /// No description provided for @flowDanCertification.
  ///
  /// In zh, this message translates to:
  /// **'段位认定'**
  String get flowDanCertification;

  /// No description provided for @flowMyChallenges.
  ///
  /// In zh, this message translates to:
  /// **'我的挑战'**
  String get flowMyChallenges;

  /// No description provided for @flowEstimatedResult.
  ///
  /// In zh, this message translates to:
  /// **'预计结果'**
  String get flowEstimatedResult;

  /// No description provided for @flowFailed2.
  ///
  /// In zh, this message translates to:
  /// **'不合格'**
  String get flowFailed2;

  /// No description provided for @flowPassed.
  ///
  /// In zh, this message translates to:
  /// **'合格'**
  String get flowPassed;

  /// No description provided for @flowTotalAchievement.
  ///
  /// In zh, this message translates to:
  /// **'总达成率'**
  String get flowTotalAchievement;

  /// No description provided for @flowRemainingLife.
  ///
  /// In zh, this message translates to:
  /// **'剩余血量'**
  String get flowRemainingLife;

  /// No description provided for @flowSongP02.
  ///
  /// In zh, this message translates to:
  /// **'曲目 {p0}'**
  String flowSongP02(String p0);

  /// No description provided for @flowEstimatedMinimumLifeLoss.
  ///
  /// In zh, this message translates to:
  /// **'预计最低扣血'**
  String get flowEstimatedMinimumLifeLoss;

  /// No description provided for @flowLifeSettings.
  ///
  /// In zh, this message translates to:
  /// **'血量设置'**
  String get flowLifeSettings;

  /// No description provided for @flowStartingLife.
  ///
  /// In zh, this message translates to:
  /// **'初始血量'**
  String get flowStartingLife;

  /// No description provided for @flowClearRecovery.
  ///
  /// In zh, this message translates to:
  /// **'通关回复'**
  String get flowClearRecovery;

  /// No description provided for @flowNoDanDataFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到段位数据'**
  String get flowNoDanDataFound;

  /// No description provided for @flowYouAreOutsideTheTop100.
  ///
  /// In zh, this message translates to:
  /// **'抱歉，您不在前100名内'**
  String get flowYouAreOutsideTheTop100;

  /// No description provided for @flowP0Entries2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}条'**
  String flowP0Entries2(String p0);

  /// No description provided for @flowNoRankingDataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无排行数据'**
  String get flowNoRankingDataYet;

  /// No description provided for @flowRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get flowRefresh;

  /// No description provided for @flowGoToMyRank.
  ///
  /// In zh, this message translates to:
  /// **'跳转到我的排名'**
  String get flowGoToMyRank;

  /// No description provided for @flowDifferenceFromBest50P0P1.
  ///
  /// In zh, this message translates to:
  /// **'与Best50差值 {p0}{p1}'**
  String flowDifferenceFromBest50P0P1(String p0, String p1);

  /// No description provided for @flowModeP02.
  ///
  /// In zh, this message translates to:
  /// **'模式{p0}'**
  String flowModeP02(String p0);

  /// No description provided for @flowDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'免责声明'**
  String get flowDisclaimer;

  /// No description provided for @flowThisLeaderboardIsForReferenceAndEntertainment.
  ///
  /// In zh, this message translates to:
  /// **'本排行榜数据仅供参考和娱乐使用，不代表任何官方立场或权威性排名。排名数据基于玩家自愿上传的游戏数据，可能存在误差或延迟。请理性看待排名结果，享受游戏乐趣。'**
  String get flowThisLeaderboardIsForReferenceAndEntertainment;

  /// No description provided for @flowDoNotShowAgain.
  ///
  /// In zh, this message translates to:
  /// **'不再提示'**
  String get flowDoNotShowAgain;

  /// No description provided for @flowDXScoreDisplayP0TapToSwitch.
  ///
  /// In zh, this message translates to:
  /// **'DX分数显示方式：{p0}（点击切换）'**
  String flowDXScoreDisplayP0TapToSwitch(String p0);

  /// No description provided for @flowDXScoreRanking.
  ///
  /// In zh, this message translates to:
  /// **'DX分数榜'**
  String get flowDXScoreRanking;

  /// No description provided for @flowAchievementRanking.
  ///
  /// In zh, this message translates to:
  /// **'达成率榜'**
  String get flowAchievementRanking;

  /// No description provided for @flowNoOneIsRankedYetBeThe.
  ///
  /// In zh, this message translates to:
  /// **'榜上无人哦，快来抢沙发！'**
  String get flowNoOneIsRankedYetBeThe;

  /// No description provided for @flowYourPlayDataForThisChartAppears.
  ///
  /// In zh, this message translates to:
  /// **'您的此谱面游玩数据存在异常，请检查!'**
  String get flowYourPlayDataForThisChartAppears;

  /// No description provided for @flowChooseRankingType.
  ///
  /// In zh, this message translates to:
  /// **'选择排行榜类型'**
  String get flowChooseRankingType;

  /// No description provided for @flowReverse.
  ///
  /// In zh, this message translates to:
  /// **'反向'**
  String get flowReverse;

  /// No description provided for @flowForward.
  ///
  /// In zh, this message translates to:
  /// **'正向'**
  String get flowForward;

  /// No description provided for @flowShowingPreviouslySavedDataRefreshWhenConnected.
  ///
  /// In zh, this message translates to:
  /// **'当前展示上次保存的数据，联网后可刷新。'**
  String get flowShowingPreviouslySavedDataRefreshWhenConnected;

  /// No description provided for @flowNoLeaderboardDataYetTryRefreshingLater.
  ///
  /// In zh, this message translates to:
  /// **'暂无排行榜数据，稍后刷新试试吧'**
  String get flowNoLeaderboardDataYetTryRefreshingLater;

  /// No description provided for @flowBilibiliChartVideoViews.
  ///
  /// In zh, this message translates to:
  /// **'B站谱面确认播放量'**
  String get flowBilibiliChartVideoViews;

  /// No description provided for @flowDifficultyP02.
  ///
  /// In zh, this message translates to:
  /// **'难度: {p0}'**
  String flowDifficultyP02(String p0);

  /// No description provided for @flowCurrentViewsP0.
  ///
  /// In zh, this message translates to:
  /// **'当前播放量: {p0}'**
  String flowCurrentViewsP0(String p0);

  /// No description provided for @flowBVIDP0.
  ///
  /// In zh, this message translates to:
  /// **'BV号: {p0}'**
  String flowBVIDP0(String p0);

  /// No description provided for @flowSourceP0.
  ///
  /// In zh, this message translates to:
  /// **'来源: {p0}'**
  String flowSourceP0(String p0);

  /// No description provided for @flowLoadingViews.
  ///
  /// In zh, this message translates to:
  /// **'正在加载播放量...'**
  String get flowLoadingViews;

  /// No description provided for @flowNoViewDataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无播放量数据'**
  String get flowNoViewDataYet;

  /// No description provided for @flowEnterBVIDManually.
  ///
  /// In zh, this message translates to:
  /// **'手动上传 BV 号'**
  String get flowEnterBVIDManually;

  /// No description provided for @flowIfViewsCannotBeFetchedAutomaticallyEnter.
  ///
  /// In zh, this message translates to:
  /// **'当自动获取播放量失败时，可手动输入该歌曲谱面确认视频的 BV 号'**
  String get flowIfViewsCannotBeFetchedAutomaticallyEnter;

  /// No description provided for @flowExampleBV1xx411c7mD.
  ///
  /// In zh, this message translates to:
  /// **'例如: BV1xx411c7mD'**
  String get flowExampleBV1xx411c7mD;

  /// No description provided for @flowViewsP0.
  ///
  /// In zh, this message translates to:
  /// **'播放量: {p0}'**
  String flowViewsP0(String p0);

  /// No description provided for @flowP010000.
  ///
  /// In zh, this message translates to:
  /// **'{p0}万'**
  String flowP010000(String p0);

  /// No description provided for @flowCheckBVID.
  ///
  /// In zh, this message translates to:
  /// **'校验 BV 号'**
  String get flowCheckBVID;

  /// No description provided for @flowBVIDUploaded.
  ///
  /// In zh, this message translates to:
  /// **'BV 号已上传'**
  String get flowBVIDUploaded;

  /// No description provided for @flowConfirmUpload.
  ///
  /// In zh, this message translates to:
  /// **'确认上传'**
  String get flowConfirmUpload;

  /// No description provided for @flowChartScoreCard.
  ///
  /// In zh, this message translates to:
  /// **'谱面成绩卡'**
  String get flowChartScoreCard;

  /// No description provided for @flowScoreShareCard.
  ///
  /// In zh, this message translates to:
  /// **'成绩分享卡片'**
  String get flowScoreShareCard;

  /// No description provided for @flowSongInformation.
  ///
  /// In zh, this message translates to:
  /// **'歌曲信息'**
  String get flowSongInformation;

  /// No description provided for @flowSongInformationImage.
  ///
  /// In zh, this message translates to:
  /// **'曲目信息图片'**
  String get flowSongInformationImage;

  /// No description provided for @flowStoragePermissionIsRequiredToSaveImages.
  ///
  /// In zh, this message translates to:
  /// **'需要存储权限才能保存图片'**
  String get flowStoragePermissionIsRequiredToSaveImages;

  /// No description provided for @flowCouldNotLoadCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'无法加载封面图片'**
  String get flowCouldNotLoadCoverArt;

  /// No description provided for @flowCoverArtSavedToPhotos.
  ///
  /// In zh, this message translates to:
  /// **'曲绘已保存到相册'**
  String get flowCoverArtSavedToPhotos;

  /// No description provided for @flowSaveFailedP02.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {p0}'**
  String flowSaveFailedP02(String p0);

  /// No description provided for @flowPlayPV.
  ///
  /// In zh, this message translates to:
  /// **'播放 PV'**
  String get flowPlayPV;

  /// No description provided for @flowChooseHowToPlayThePV.
  ///
  /// In zh, this message translates to:
  /// **'请选择 PV 的播放方式'**
  String get flowChooseHowToPlayThePV;

  /// No description provided for @flowOpenBilibili.
  ///
  /// In zh, this message translates to:
  /// **'前往 B 站'**
  String get flowOpenBilibili;

  /// No description provided for @flowPlayInApp.
  ///
  /// In zh, this message translates to:
  /// **'APP 内播放'**
  String get flowPlayInApp;

  /// No description provided for @flowPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'请稍候'**
  String get flowPleaseWait;

  /// No description provided for @flowLoadingRelatedCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'正在加载相关收藏品...'**
  String get flowLoadingRelatedCollectibles;

  /// No description provided for @flowError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get flowError;

  /// No description provided for @flowCouldNotLoadRelatedCollectiblesTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'获取相关收藏品时出错，请稍后重试'**
  String get flowCouldNotLoadRelatedCollectiblesTryAgain;

  /// No description provided for @flowChartNotes.
  ///
  /// In zh, this message translates to:
  /// **'谱面笔记'**
  String get flowChartNotes;

  /// No description provided for @flowAddChartNotes.
  ///
  /// In zh, this message translates to:
  /// **'添加谱面笔记'**
  String get flowAddChartNotes;

  /// No description provided for @flowWriteYourNotesForThisChartHere.
  ///
  /// In zh, this message translates to:
  /// **'在这里写下你对这个谱面的笔记...\n例如：结尾的滑星要注意手顺'**
  String get flowWriteYourNotesForThisChartHere;

  /// No description provided for @flowCreatedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'创建于: {p0}{p1}'**
  String flowCreatedP0P1(String p0, String p1);

  /// No description provided for @flowUpdatedP0.
  ///
  /// In zh, this message translates to:
  /// **'\n更新于: {p0}'**
  String flowUpdatedP0(String p0);

  /// No description provided for @flowConfirmDeletion.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get flowConfirmDeletion;

  /// No description provided for @flowDeleteTheNotesForThisChartThis.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个谱面的笔记吗？此操作不可撤销。'**
  String get flowDeleteTheNotesForThisChartThis;

  /// No description provided for @flowRelatedCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'相关收藏品'**
  String get flowRelatedCollectibles;

  /// No description provided for @flowNoCollectiblesLinkedToThisSong.
  ///
  /// In zh, this message translates to:
  /// **'未找到与该歌曲相关的收藏品'**
  String get flowNoCollectiblesLinkedToThisSong;

  /// No description provided for @flowRefreshDataOnTheHomePageTo.
  ///
  /// In zh, this message translates to:
  /// **'请先在首页刷新数据以获取用户身份'**
  String get flowRefreshDataOnTheHomePageTo;

  /// No description provided for @flowRatingSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'评分提交成功'**
  String get flowRatingSubmitted;

  /// No description provided for @flowCouldNotSubmitRating.
  ///
  /// In zh, this message translates to:
  /// **'评分提交失败'**
  String get flowCouldNotSubmitRating;

  /// No description provided for @flowDeleteYourRating.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除您的评分吗？'**
  String get flowDeleteYourRating;

  /// No description provided for @flowRatingDeleted.
  ///
  /// In zh, this message translates to:
  /// **'评分删除成功'**
  String get flowRatingDeleted;

  /// No description provided for @flowCouldNotDeleteRating.
  ///
  /// In zh, this message translates to:
  /// **'评分删除失败'**
  String get flowCouldNotDeleteRating;

  /// No description provided for @flowChartRating.
  ///
  /// In zh, this message translates to:
  /// **'谱面评分'**
  String get flowChartRating;

  /// No description provided for @flowP0Ratings.
  ///
  /// In zh, this message translates to:
  /// **'({p0}人评分)'**
  String flowP0Ratings(String p0);

  /// No description provided for @flowDistribution.
  ///
  /// In zh, this message translates to:
  /// **'分布'**
  String get flowDistribution;

  /// No description provided for @flowRatingsAreForReferencePleaseRateObjectively.
  ///
  /// In zh, this message translates to:
  /// **'评分仅供参考，请客观评价'**
  String get flowRatingsAreForReferencePleaseRateObjectively;

  /// No description provided for @flowRefreshRatings.
  ///
  /// In zh, this message translates to:
  /// **'刷新评分'**
  String get flowRefreshRatings;

  /// No description provided for @flowMyRecentRatings.
  ///
  /// In zh, this message translates to:
  /// **'我的最近评分'**
  String get flowMyRecentRatings;

  /// No description provided for @flowMyRatingTapToEdit.
  ///
  /// In zh, this message translates to:
  /// **'我的评分（点击修改）'**
  String get flowMyRatingTapToEdit;

  /// No description provided for @flowRateThisChart.
  ///
  /// In zh, this message translates to:
  /// **'为这个谱面评分'**
  String get flowRateThisChart;

  /// No description provided for @flowDeleteRating.
  ///
  /// In zh, this message translates to:
  /// **'删除评分'**
  String get flowDeleteRating;

  /// No description provided for @flowUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get flowUpdate;

  /// No description provided for @flowSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get flowSubmit;

  /// No description provided for @flowRefreshDataOnTheHomePageTo2.
  ///
  /// In zh, this message translates to:
  /// **'请在首页刷新数据以获取身份后再评分'**
  String get flowRefreshDataOnTheHomePageTo2;

  /// No description provided for @flowNoRatingsYet2.
  ///
  /// In zh, this message translates to:
  /// **'暂无评分数据'**
  String get flowNoRatingsYet2;

  /// No description provided for @flowRatingDistribution.
  ///
  /// In zh, this message translates to:
  /// **'评分分布'**
  String get flowRatingDistribution;

  /// No description provided for @flowP0Ratings2.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 人评分'**
  String flowP0Ratings2(String p0);

  /// No description provided for @flowAverageP0.
  ///
  /// In zh, this message translates to:
  /// **'均分 {p0}'**
  String flowAverageP0(String p0);

  /// No description provided for @flowSetYourIdentityFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先设置身份信息'**
  String get flowSetYourIdentityFirst;

  /// No description provided for @flowCommentPosted.
  ///
  /// In zh, this message translates to:
  /// **'评论发布成功'**
  String get flowCommentPosted;

  /// No description provided for @flowCouldNotPostComment.
  ///
  /// In zh, this message translates to:
  /// **'评论发布失败'**
  String get flowCouldNotPostComment;

  /// No description provided for @flowCouldNotPostCommentP0.
  ///
  /// In zh, this message translates to:
  /// **'评论发布失败：{p0}'**
  String flowCouldNotPostCommentP0(String p0);

  /// No description provided for @flowCannotDeleteIdentityInformationIsMissing.
  ///
  /// In zh, this message translates to:
  /// **'无法删除：身份信息缺失'**
  String get flowCannotDeleteIdentityInformationIsMissing;

  /// No description provided for @flowDeleteThisComment.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这条评论吗？'**
  String get flowDeleteThisComment;

  /// No description provided for @flowCommentDeleted.
  ///
  /// In zh, this message translates to:
  /// **'评论删除成功'**
  String get flowCommentDeleted;

  /// No description provided for @flowCouldNotDeleteComment.
  ///
  /// In zh, this message translates to:
  /// **'评论删除失败'**
  String get flowCouldNotDeleteComment;

  /// No description provided for @flowComments.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get flowComments;

  /// No description provided for @flowCommentsRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'已刷新评论'**
  String get flowCommentsRefreshed;

  /// No description provided for @flowRefreshComments.
  ///
  /// In zh, this message translates to:
  /// **'刷新评论'**
  String get flowRefreshComments;

  /// No description provided for @flowCommentsAreForReferencePleaseBeRespectful.
  ///
  /// In zh, this message translates to:
  /// **'评论仅供参考，请文明发言'**
  String get flowCommentsAreForReferencePleaseBeRespectful;

  /// No description provided for @flowRefreshDataOnTheHomePageTo3.
  ///
  /// In zh, this message translates to:
  /// **'请在首页刷新数据以获取评论身份'**
  String get flowRefreshDataOnTheHomePageTo3;

  /// No description provided for @flowEnterYourComment.
  ///
  /// In zh, this message translates to:
  /// **'输入您的评论内容...'**
  String get flowEnterYourComment;

  /// No description provided for @flowPost.
  ///
  /// In zh, this message translates to:
  /// **'发表'**
  String get flowPost;

  /// No description provided for @flowNoCommentsYetBeTheFirstTo.
  ///
  /// In zh, this message translates to:
  /// **'暂无评论，快来发表第一条评论吧！'**
  String get flowNoCommentsYetBeTheFirstTo;

  /// No description provided for @flowMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get flowMe;

  /// No description provided for @flowViewNotes.
  ///
  /// In zh, this message translates to:
  /// **'查看笔记'**
  String get flowViewNotes;

  /// No description provided for @flowAddNotes.
  ///
  /// In zh, this message translates to:
  /// **'添加笔记'**
  String get flowAddNotes;

  /// No description provided for @flowExportSongInformation.
  ///
  /// In zh, this message translates to:
  /// **'导出歌曲信息'**
  String get flowExportSongInformation;

  /// No description provided for @flowShareScore.
  ///
  /// In zh, this message translates to:
  /// **'分享成绩'**
  String get flowShareScore;

  /// No description provided for @flowEnlargeCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'放大曲绘'**
  String get flowEnlargeCoverArt;

  /// No description provided for @flowSwitchToDX.
  ///
  /// In zh, this message translates to:
  /// **'切换 DX'**
  String get flowSwitchToDX;

  /// No description provided for @flowSwitchToST.
  ///
  /// In zh, this message translates to:
  /// **'切换 ST'**
  String get flowSwitchToST;

  /// No description provided for @flowP0LevelP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 等级 {p1}'**
  String flowP0LevelP1(String p0, String p1);

  /// No description provided for @flowNoScoreForP0Yet.
  ///
  /// In zh, this message translates to:
  /// **'还没有 {p0} 的成绩'**
  String flowNoScoreForP0Yet(String p0);

  /// No description provided for @flowPlayAndSyncToSeeYourScore.
  ///
  /// In zh, this message translates to:
  /// **'打完同步一下就会显示在这里'**
  String get flowPlayAndSyncToSeeYourScore;

  /// No description provided for @flowDXScoreMAXP0.
  ///
  /// In zh, this message translates to:
  /// **'DX分数（MAX -{p0}）'**
  String flowDXScoreMAXP0(String p0);

  /// No description provided for @flowShowStarBonus.
  ///
  /// In zh, this message translates to:
  /// **'显示星级加成'**
  String get flowShowStarBonus;

  /// No description provided for @flowShowPointsNeededForTheNextStar.
  ///
  /// In zh, this message translates to:
  /// **'显示距下一星还差多少'**
  String get flowShowPointsNeededForTheNextStar;

  /// No description provided for @flowRatingPotential.
  ///
  /// In zh, this message translates to:
  /// **'上分潜力'**
  String get flowRatingPotential;

  /// No description provided for @flowBasicInformation.
  ///
  /// In zh, this message translates to:
  /// **'基础信息'**
  String get flowBasicInformation;

  /// No description provided for @flowNoteDistribution.
  ///
  /// In zh, this message translates to:
  /// **'物量分布'**
  String get flowNoteDistribution;

  /// No description provided for @flowBREAKDistribution.
  ///
  /// In zh, this message translates to:
  /// **'绝赞分布'**
  String get flowBREAKDistribution;

  /// No description provided for @flowNoGlobalGradeOrComboDistributionData.
  ///
  /// In zh, this message translates to:
  /// **'这张谱面暂时没有全站评级与连击分布数据'**
  String get flowNoGlobalGradeOrComboDistributionData;

  /// No description provided for @flowTAPGREATsAllBREAKsCriticalPerfect.
  ///
  /// In zh, this message translates to:
  /// **'个 TAP GREAT（绝赞全 CP）'**
  String get flowTAPGREATsAllBREAKsCriticalPerfect;

  /// No description provided for @flowOpenCalculatorWithThisChartSNotes.
  ///
  /// In zh, this message translates to:
  /// **'带上这张谱面的物量与成绩打开计算器'**
  String get flowOpenCalculatorWithThisChartSNotes;

  /// No description provided for @flowNoTagsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签'**
  String get flowNoTagsYet;

  /// No description provided for @flowTagDataFrom.
  ///
  /// In zh, this message translates to:
  /// **'标签数据来源自 '**
  String get flowTagDataFrom;

  /// No description provided for @flowUnknownTag.
  ///
  /// In zh, this message translates to:
  /// **'未知标签'**
  String get flowUnknownTag;

  /// No description provided for @flowConstantHistory.
  ///
  /// In zh, this message translates to:
  /// **'定数历史'**
  String get flowConstantHistory;

  /// No description provided for @flowStarsDXScoreTable.
  ///
  /// In zh, this message translates to:
  /// **'星数-DX分数对照表'**
  String get flowStarsDXScoreTable;

  /// No description provided for @flowStars.
  ///
  /// In zh, this message translates to:
  /// **'星数'**
  String get flowStars;

  /// No description provided for @flowDXScore2.
  ///
  /// In zh, this message translates to:
  /// **'DX分数'**
  String get flowDXScore2;

  /// No description provided for @flowPlayers.
  ///
  /// In zh, this message translates to:
  /// **'玩家'**
  String get flowPlayers;

  /// No description provided for @flowAchievementScoreTable.
  ///
  /// In zh, this message translates to:
  /// **'达成率-得分对照表'**
  String get flowAchievementScoreTable;

  /// No description provided for @flowScore.
  ///
  /// In zh, this message translates to:
  /// **'得分'**
  String get flowScore;

  /// No description provided for @flowJudgmentAllowance.
  ///
  /// In zh, this message translates to:
  /// **'容错计算'**
  String get flowJudgmentAllowance;

  /// No description provided for @flowNoteType.
  ///
  /// In zh, this message translates to:
  /// **'音符类型:'**
  String get flowNoteType;

  /// No description provided for @flowShareOfTotalWeight.
  ///
  /// In zh, this message translates to:
  /// **'占总权重比例:'**
  String get flowShareOfTotalWeight;

  /// No description provided for @flowBREAKLossSoFar.
  ///
  /// In zh, this message translates to:
  /// **'已打出的BREAK损失'**
  String get flowBREAKLossSoFar;

  /// No description provided for @flow50PointLosses.
  ///
  /// In zh, this message translates to:
  /// **'50落数量'**
  String get flow50PointLosses;

  /// No description provided for @flowInvalid.
  ///
  /// In zh, this message translates to:
  /// **'无效'**
  String get flowInvalid;

  /// No description provided for @flow100PointLosses.
  ///
  /// In zh, this message translates to:
  /// **'100落数量'**
  String get flow100PointLosses;

  /// No description provided for @flow80GREATCount.
  ///
  /// In zh, this message translates to:
  /// **'80%GREAT数量'**
  String get flow80GREATCount;

  /// No description provided for @flow60GREATCount.
  ///
  /// In zh, this message translates to:
  /// **'60%GREAT数量'**
  String get flow60GREATCount;

  /// No description provided for @flow50GREATCount.
  ///
  /// In zh, this message translates to:
  /// **'50%GREAT数量'**
  String get flow50GREATCount;

  /// No description provided for @flowGOODCount.
  ///
  /// In zh, this message translates to:
  /// **'GOOD数量'**
  String get flowGOODCount;

  /// No description provided for @flowMISSCount.
  ///
  /// In zh, this message translates to:
  /// **'MISS数量'**
  String get flowMISSCount;

  /// No description provided for @flowTotalBREAKLoss.
  ///
  /// In zh, this message translates to:
  /// **'BREAK总损失: '**
  String get flowTotalBREAKLoss;

  /// No description provided for @flowRemainingBudgetSSS.
  ///
  /// In zh, this message translates to:
  /// **'剩余预算(SSS+): '**
  String get flowRemainingBudgetSSS;

  /// No description provided for @flowRemainingBudgetSSS2.
  ///
  /// In zh, this message translates to:
  /// **'剩余预算(SSS): '**
  String get flowRemainingBudgetSSS2;

  /// No description provided for @flowRemainingBudgetSS.
  ///
  /// In zh, this message translates to:
  /// **'剩余预算(SS+): '**
  String get flowRemainingBudgetSS;

  /// No description provided for @flowRemainingBudgetSS2.
  ///
  /// In zh, this message translates to:
  /// **'剩余预算(SS): '**
  String get flowRemainingBudgetSS2;

  /// No description provided for @flowGREATLoss.
  ///
  /// In zh, this message translates to:
  /// **'GREAT损失'**
  String get flowGREATLoss;

  /// No description provided for @flowGOODLoss.
  ///
  /// In zh, this message translates to:
  /// **'GOOD损失'**
  String get flowGOODLoss;

  /// No description provided for @flowMISSLoss.
  ///
  /// In zh, this message translates to:
  /// **'MISS损失'**
  String get flowMISSLoss;

  /// No description provided for @flowSSSGREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SSS+容错(GREAT)'**
  String get flowSSSGREATAllowance;

  /// No description provided for @flowSSSGOODAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SSS+容错(GOOD)'**
  String get flowSSSGOODAllowance;

  /// No description provided for @flowSSSMISSAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SSS+容错(MISS)'**
  String get flowSSSMISSAllowance;

  /// No description provided for @flowP0.
  ///
  /// In zh, this message translates to:
  /// **'{p0}个'**
  String flowP0(String p0);

  /// No description provided for @flowSSSGREATAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SSS容错(GREAT)'**
  String get flowSSSGREATAllowance2;

  /// No description provided for @flowSSSGOODAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SSS容错(GOOD)'**
  String get flowSSSGOODAllowance2;

  /// No description provided for @flowSSSMISSAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SSS容错(MISS)'**
  String get flowSSSMISSAllowance2;

  /// No description provided for @flowSSGREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SS+容错(GREAT)'**
  String get flowSSGREATAllowance;

  /// No description provided for @flowSSGOODAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SS+容错(GOOD)'**
  String get flowSSGOODAllowance;

  /// No description provided for @flowSSMISSAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SS+容错(MISS)'**
  String get flowSSMISSAllowance;

  /// No description provided for @flowSSGREATAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SS容错(GREAT)'**
  String get flowSSGREATAllowance2;

  /// No description provided for @flowSSGOODAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SS容错(GOOD)'**
  String get flowSSGOODAllowance2;

  /// No description provided for @flowSSMISSAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SS容错(MISS)'**
  String get flowSSMISSAllowance2;

  /// No description provided for @flow50PointLoss.
  ///
  /// In zh, this message translates to:
  /// **'50落损失'**
  String get flow50PointLoss;

  /// No description provided for @flow100PointLoss.
  ///
  /// In zh, this message translates to:
  /// **'100落损失'**
  String get flow100PointLoss;

  /// No description provided for @flow80GREATLoss.
  ///
  /// In zh, this message translates to:
  /// **'80%GREAT损失'**
  String get flow80GREATLoss;

  /// No description provided for @flow60GREATLoss.
  ///
  /// In zh, this message translates to:
  /// **'60%GREAT损失'**
  String get flow60GREATLoss;

  /// No description provided for @flow50GREATLoss.
  ///
  /// In zh, this message translates to:
  /// **'50%GREAT损失'**
  String get flow50GREATLoss;

  /// No description provided for @flow0580GREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'-0.5%容错80%GREAT'**
  String get flow0580GREATAllowance;

  /// No description provided for @flow0560GREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'-0.5%容错60%GREAT'**
  String get flow0560GREATAllowance;

  /// No description provided for @flow0550GREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'-0.5%容错50%GREAT'**
  String get flow0550GREATAllowance;

  /// No description provided for @flow05Allowance.
  ///
  /// In zh, this message translates to:
  /// **'-0.5%容错'**
  String get flow05Allowance;

  /// No description provided for @flow180GREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'-1%容错80%GREAT'**
  String get flow180GREATAllowance;

  /// No description provided for @flow160GREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'-1%容错60%GREAT'**
  String get flow160GREATAllowance;

  /// No description provided for @flow150GREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'-1%容错50%GREAT'**
  String get flow150GREATAllowance;

  /// No description provided for @flow1Allowance.
  ///
  /// In zh, this message translates to:
  /// **'-1%容错'**
  String get flow1Allowance;

  /// No description provided for @flowGradeDistributionReferenceOnly.
  ///
  /// In zh, this message translates to:
  /// **'评级分布(仅供参考)'**
  String get flowGradeDistributionReferenceOnly;

  /// No description provided for @flowComboDistributionReferenceOnly.
  ///
  /// In zh, this message translates to:
  /// **'连击分布(仅供参考)'**
  String get flowComboDistributionReferenceOnly;

  /// No description provided for @flowInTheOrderBPMMarkersAppearIn.
  ///
  /// In zh, this message translates to:
  /// **'按当前谱面中 BPM 标记的出现顺序'**
  String get flowInTheOrderBPMMarkersAppearIn;

  /// No description provided for @flowChangeIndex.
  ///
  /// In zh, this message translates to:
  /// **'变化序号'**
  String get flowChangeIndex;

  /// No description provided for @flowPlayOnBilibili.
  ///
  /// In zh, this message translates to:
  /// **'B站播放'**
  String get flowPlayOnBilibili;

  /// No description provided for @flowPlayableRegions.
  ///
  /// In zh, this message translates to:
  /// **'可游玩地区'**
  String get flowPlayableRegions;

  /// No description provided for @flowParsingDataUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂缺解析数据'**
  String get flowParsingDataUnavailable;

  /// No description provided for @flowExcludesSLIDETOUCHAndBREAKStars.
  ///
  /// In zh, this message translates to:
  /// **'不含 SLIDE、TOUCH 和绝赞星星。'**
  String get flowExcludesSLIDETOUCHAndBREAKStars;

  /// No description provided for @flowAliasesNone.
  ///
  /// In zh, this message translates to:
  /// **'别名: 无'**
  String get flowAliasesNone;

  /// No description provided for @flowAliasesForP0.
  ///
  /// In zh, this message translates to:
  /// **'{p0}的别名'**
  String flowAliasesForP0(String p0);

  /// No description provided for @flowTapAnyAliasToCopy.
  ///
  /// In zh, this message translates to:
  /// **'点击任意别名即可复制'**
  String get flowTapAnyAliasToCopy;

  /// No description provided for @flowViewAliasesP0.
  ///
  /// In zh, this message translates to:
  /// **'查看别名 ({p0})'**
  String flowViewAliasesP0(String p0);

  /// No description provided for @flowDXScoreP02.
  ///
  /// In zh, this message translates to:
  /// **'DX分数 {p0}%'**
  String flowDXScoreP02(String p0);

  /// No description provided for @flowRankP0P1RatingP2.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 名，{p1}，Rating {p2}'**
  String flowRankP0P1RatingP2(String p0, String p1, String p2);

  /// No description provided for @flowRatingHeadroom.
  ///
  /// In zh, this message translates to:
  /// **'推分空间'**
  String get flowRatingHeadroom;

  /// No description provided for @flowRaiseToP0P1.
  ///
  /// In zh, this message translates to:
  /// **'推到 {p0}（{p1}%）'**
  String flowRaiseToP0P1(String p0, String p1);

  /// No description provided for @flowDXScoreP0P12.
  ///
  /// In zh, this message translates to:
  /// **'DX分数 {p0} / {p1}'**
  String flowDXScoreP0P12(String p0, String p1);

  /// No description provided for @flowViewSongDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看歌曲详情'**
  String get flowViewSongDetails;

  /// No description provided for @flowP0SongsRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {p0} 首'**
  String flowP0SongsRemaining(String p0);

  /// No description provided for @flowP0EqualToTheLastChartOn.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，和榜单最后一首相同'**
  String flowP0EqualToTheLastChartOn(String p0);

  /// No description provided for @flowP0ConstantP1RAP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 定数 {p1} · RA {p2}'**
  String flowP0ConstantP1RAP2(String p0, String p1, String p2);

  /// No description provided for @flowAddScoreHistory.
  ///
  /// In zh, this message translates to:
  /// **'添加成绩历史'**
  String get flowAddScoreHistory;

  /// No description provided for @flowScoreHistoryP0.
  ///
  /// In zh, this message translates to:
  /// **'成绩历史（{p0}）'**
  String flowScoreHistoryP0(String p0);

  /// No description provided for @flowTheCurveDropsInGameScoresKeep.
  ///
  /// In zh, this message translates to:
  /// **'曲线出现下降：游戏里成绩取最高，这多半是切换数据源/账号造成的记录差异'**
  String get flowTheCurveDropsInGameScoresKeep;

  /// No description provided for @flowUnknownDate.
  ///
  /// In zh, this message translates to:
  /// **'日期未知'**
  String get flowUnknownDate;

  /// No description provided for @flowShowAllP0Entries.
  ///
  /// In zh, this message translates to:
  /// **'展开全部（{p0} 条）'**
  String flowShowAllP0Entries(String p0);

  /// No description provided for @flowAddChartScoreHistory.
  ///
  /// In zh, this message translates to:
  /// **'添加谱面成绩历史'**
  String get flowAddChartScoreHistory;

  /// No description provided for @flowAchievement3.
  ///
  /// In zh, this message translates to:
  /// **'达成率（%）'**
  String get flowAchievement3;

  /// No description provided for @flowSumOfUTAGESubcharts.
  ///
  /// In zh, this message translates to:
  /// **'宴会场子谱相加'**
  String get flowSumOfUTAGESubcharts;

  /// No description provided for @flowNormalChartLimit.
  ///
  /// In zh, this message translates to:
  /// **'普通谱面上限'**
  String get flowNormalChartLimit;

  /// No description provided for @flowDXScoreOptional.
  ///
  /// In zh, this message translates to:
  /// **'DX 分数（可选）'**
  String get flowDXScoreOptional;

  /// No description provided for @flowChartMaximumScore.
  ///
  /// In zh, this message translates to:
  /// **'谱面满分'**
  String get flowChartMaximumScore;

  /// No description provided for @flowSelectTime.
  ///
  /// In zh, this message translates to:
  /// **'选择时间'**
  String get flowSelectTime;

  /// No description provided for @flowSeconds059.
  ///
  /// In zh, this message translates to:
  /// **'秒（0-59）'**
  String get flowSeconds059;

  /// No description provided for @flowDeleteThisDataPoint.
  ///
  /// In zh, this message translates to:
  /// **'删除这个记录点？'**
  String get flowDeleteThisDataPoint;

  /// No description provided for @flowThisCannotBeUndoneIfThisIs.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复。如果它是自动采集到的当前成绩，下次刷新可能会重新记录。'**
  String get flowThisCannotBeUndoneIfThisIs;

  /// No description provided for @flowDataVoluntarilyUploadedByPlayersForReference.
  ///
  /// In zh, this message translates to:
  /// **'数据来自玩家自愿上传，仅供参考和娱乐'**
  String get flowDataVoluntarilyUploadedByPlayersForReference;

  /// No description provided for @flowBriefProfilesAreHiddenForAnonymousPlayers.
  ///
  /// In zh, this message translates to:
  /// **'匿名用户不展示简要信息'**
  String get flowBriefProfilesAreHiddenForAnonymousPlayers;

  /// No description provided for @flowCouldNotLoadTheBriefProfileTry.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取简要信息，请稍后重试'**
  String get flowCouldNotLoadTheBriefProfileTry;

  /// No description provided for @flowReload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get flowReload;

  /// No description provided for @flowUnknownPlayer.
  ///
  /// In zh, this message translates to:
  /// **'未知玩家'**
  String get flowUnknownPlayer;

  /// No description provided for @flowNoTitleSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置称号'**
  String get flowNoTitleSet;

  /// No description provided for @flowB1IsTheChartWithTheHighest.
  ///
  /// In zh, this message translates to:
  /// **'B1 为对应 Best 列表中单曲 Rating 最高的谱面。'**
  String get flowB1IsTheChartWithTheHighest;

  /// No description provided for @flowNoScoresYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无成绩'**
  String get flowNoScoresYet;

  /// No description provided for @flowDanCompletion.
  ///
  /// In zh, this message translates to:
  /// **'段位完成情况'**
  String get flowDanCompletion;

  /// No description provided for @flowTotalAchievementUpTo4040000.
  ///
  /// In zh, this message translates to:
  /// **'总达成率（最高 404.0000%）'**
  String get flowTotalAchievementUpTo4040000;

  /// No description provided for @flowCompletionRate.
  ///
  /// In zh, this message translates to:
  /// **'完成率'**
  String get flowCompletionRate;

  /// No description provided for @flowP0Songs2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 首'**
  String flowP0Songs2(String p0);

  /// No description provided for @flowExcluded.
  ///
  /// In zh, this message translates to:
  /// **'不计入'**
  String get flowExcluded;

  /// No description provided for @flowCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get flowCompleted;

  /// No description provided for @flowIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'未完成'**
  String get flowIncomplete;

  /// No description provided for @flowLoading4.
  ///
  /// In zh, this message translates to:
  /// **'正在加载'**
  String get flowLoading4;

  /// No description provided for @flowFirstRecord.
  ///
  /// In zh, this message translates to:
  /// **'首次记录'**
  String get flowFirstRecord;

  /// No description provided for @flowP0P1Changes.
  ///
  /// In zh, this message translates to:
  /// **'–{p0} · {p1} 次变化'**
  String flowP0P1Changes(String p0, String p1);

  /// No description provided for @flowRecorded.
  ///
  /// In zh, this message translates to:
  /// **' 记录'**
  String get flowRecorded;

  /// No description provided for @flowTheScoreChangedDuringTheDayBut.
  ///
  /// In zh, this message translates to:
  /// **'日内成绩有过变化，最新值已回到当日初值。'**
  String get flowTheScoreChangedDuringTheDayBut;

  /// No description provided for @flowNoChange.
  ///
  /// In zh, this message translates to:
  /// **'无变化'**
  String get flowNoChange;

  /// No description provided for @flowPlaybackProgressDragTheOuterRingTo.
  ///
  /// In zh, this message translates to:
  /// **'播放进度，拖动外环调整，左右滑动曲绘切歌'**
  String get flowPlaybackProgressDragTheOuterRingTo;

  /// No description provided for @flowElapsed.
  ///
  /// In zh, this message translates to:
  /// **'已播放'**
  String get flowElapsed;

  /// No description provided for @flowDuration2.
  ///
  /// In zh, this message translates to:
  /// **'总时长'**
  String get flowDuration2;

  /// No description provided for @flowQueue.
  ///
  /// In zh, this message translates to:
  /// **'队列'**
  String get flowQueue;

  /// No description provided for @flowLoadingAudio.
  ///
  /// In zh, this message translates to:
  /// **'正在加载音源'**
  String get flowLoadingAudio;

  /// No description provided for @flowOpenPlaybackQueue.
  ///
  /// In zh, this message translates to:
  /// **'打开播放队列'**
  String get flowOpenPlaybackQueue;

  /// No description provided for @flowPlaybackQueue.
  ///
  /// In zh, this message translates to:
  /// **'播放队列'**
  String get flowPlaybackQueue;

  /// No description provided for @flowPlaybackModeP0TapToSwitchAnd.
  ///
  /// In zh, this message translates to:
  /// **'播放模式：{p0}（点一下切换并展开）'**
  String flowPlaybackModeP0TapToSwitchAnd(String p0);

  /// No description provided for @flowRepeatCount.
  ///
  /// In zh, this message translates to:
  /// **'循环次数'**
  String get flowRepeatCount;

  /// No description provided for @flowNotSet2.
  ///
  /// In zh, this message translates to:
  /// **'不设置'**
  String get flowNotSet2;

  /// No description provided for @flowP0Times.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 次'**
  String flowP0Times(String p0);

  /// No description provided for @flowUnlimited.
  ///
  /// In zh, this message translates to:
  /// **'不设置次数'**
  String get flowUnlimited;

  /// No description provided for @flowRepeatTheCurrentSongIndefinitely.
  ///
  /// In zh, this message translates to:
  /// **'一直循环当前曲目'**
  String get flowRepeatTheCurrentSongIndefinitely;

  /// No description provided for @flowSetCount.
  ///
  /// In zh, this message translates to:
  /// **'设置次数'**
  String get flowSetCount;

  /// No description provided for @flowDecreaseCount.
  ///
  /// In zh, this message translates to:
  /// **'减少次数'**
  String get flowDecreaseCount;

  /// No description provided for @flowIncreaseCount.
  ///
  /// In zh, this message translates to:
  /// **'增加次数'**
  String get flowIncreaseCount;

  /// No description provided for @flowHideFloatingPlayer.
  ///
  /// In zh, this message translates to:
  /// **'隐藏悬浮球'**
  String get flowHideFloatingPlayer;

  /// No description provided for @flowPlaylist.
  ///
  /// In zh, this message translates to:
  /// **'播放列表'**
  String get flowPlaylist;

  /// No description provided for @flowKeepPlayingAndReopenTheFloatingPlayer.
  ///
  /// In zh, this message translates to:
  /// **'可以继续播放并稍后回到随身听重新唤起，或同时暂停播放并移除通知栏音乐。'**
  String get flowKeepPlayingAndReopenTheFloatingPlayer;

  /// No description provided for @flowKeepPlaying.
  ///
  /// In zh, this message translates to:
  /// **'继续播放'**
  String get flowKeepPlaying;

  /// No description provided for @flowPauseAndRemove.
  ///
  /// In zh, this message translates to:
  /// **'暂停并移除'**
  String get flowPauseAndRemove;

  /// No description provided for @flowSongTitle2.
  ///
  /// In zh, this message translates to:
  /// **'歌曲标题'**
  String get flowSongTitle2;

  /// No description provided for @flowTranslatedByBaiduSLanguageModel.
  ///
  /// In zh, this message translates to:
  /// **'由百度大模型翻译'**
  String get flowTranslatedByBaiduSLanguageModel;

  /// No description provided for @flowTranslating.
  ///
  /// In zh, this message translates to:
  /// **'翻译中…'**
  String get flowTranslating;

  /// No description provided for @flowDifficultiesToPlayMultipleSelections.
  ///
  /// In zh, this message translates to:
  /// **'想玩的难度（可多选）'**
  String get flowDifficultiesToPlayMultipleSelections;

  /// No description provided for @flowNotesOptional.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get flowNotesOptional;

  /// No description provided for @flowExamplePlayWithFriends.
  ///
  /// In zh, this message translates to:
  /// **'例如：和朋友一起玩'**
  String get flowExamplePlayWithFriends;

  /// No description provided for @flowAdd.
  ///
  /// In zh, this message translates to:
  /// **'加入'**
  String get flowAdd;

  /// No description provided for @flowTotalSongs.
  ///
  /// In zh, this message translates to:
  /// **'总歌曲数'**
  String get flowTotalSongs;

  /// No description provided for @flowPathCopiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'路径已复制到剪贴板'**
  String get flowPathCopiedToClipboard;

  /// No description provided for @flowNoAppAvailableToViewImages.
  ///
  /// In zh, this message translates to:
  /// **'没有找到能查看图片的应用'**
  String get flowNoAppAvailableToViewImages;

  /// No description provided for @flowCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get flowCopied;

  /// No description provided for @flowCopyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get flowCopyPath;

  /// No description provided for @flowPublicDirectoryIsNotWritableSavedTo.
  ///
  /// In zh, this message translates to:
  /// **'公开目录不可写，文件已保存到备用路径：{p0}'**
  String flowPublicDirectoryIsNotWritableSavedTo(String p0);

  /// No description provided for @flowViewImage.
  ///
  /// In zh, this message translates to:
  /// **'查看图片'**
  String get flowViewImage;

  /// No description provided for @flowPerRow.
  ///
  /// In zh, this message translates to:
  /// **'每行'**
  String get flowPerRow;

  /// No description provided for @flowFewerAvatarsPerRow.
  ///
  /// In zh, this message translates to:
  /// **'减少每行头像数'**
  String get flowFewerAvatarsPerRow;

  /// No description provided for @flowMoreAvatarsPerRow.
  ///
  /// In zh, this message translates to:
  /// **'增加每行头像数'**
  String get flowMoreAvatarsPerRow;

  /// No description provided for @flowChooseAppearance.
  ///
  /// In zh, this message translates to:
  /// **'选择装扮'**
  String get flowChooseAppearance;

  /// No description provided for @flowSearchP0ByNameDescriptionOrID.
  ///
  /// In zh, this message translates to:
  /// **'搜索{p0}名称、描述或编号'**
  String flowSearchP0ByNameDescriptionOrID(String p0);

  /// No description provided for @flowP0Items3.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 项'**
  String flowP0Items3(String p0);

  /// No description provided for @flowLoadingP0.
  ///
  /// In zh, this message translates to:
  /// **'正在加载{p0}…'**
  String flowLoadingP0(String p0);

  /// No description provided for @flowNoP0YetRefreshCollectibleDataFirst.
  ///
  /// In zh, this message translates to:
  /// **'暂无{p0}，请先刷新收藏品数据'**
  String flowNoP0YetRefreshCollectibleDataFirst(String p0);

  /// No description provided for @flowNoMatchingP0.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的{p0}'**
  String flowNoMatchingP0(String p0);

  /// No description provided for @flowPNGLosslessOriginalQuality.
  ///
  /// In zh, this message translates to:
  /// **'PNG 无损（原始画质）'**
  String get flowPNGLosslessOriginalQuality;

  /// No description provided for @flowJPEGHighQuality.
  ///
  /// In zh, this message translates to:
  /// **'JPEG 高质量'**
  String get flowJPEGHighQuality;

  /// No description provided for @flowJPEGStandard.
  ///
  /// In zh, this message translates to:
  /// **'JPEG 标准'**
  String get flowJPEGStandard;

  /// No description provided for @flowJPEGCompressed.
  ///
  /// In zh, this message translates to:
  /// **'JPEG 压缩'**
  String get flowJPEGCompressed;

  /// No description provided for @flowChooseExportQuality.
  ///
  /// In zh, this message translates to:
  /// **'选择导出质量'**
  String get flowChooseExportQuality;

  /// No description provided for @flowExportingP0.
  ///
  /// In zh, this message translates to:
  /// **'当前正在导出：{p0}'**
  String flowExportingP0(String p0);

  /// No description provided for @flowImageTheme.
  ///
  /// In zh, this message translates to:
  /// **'图片主题'**
  String get flowImageTheme;

  /// No description provided for @flowThunderMode.
  ///
  /// In zh, this message translates to:
  /// **'雷霆模式'**
  String get flowThunderMode;

  /// No description provided for @flowArrangeCardsIn50RowsOr50.
  ///
  /// In zh, this message translates to:
  /// **'将歌曲卡片改为单列 50 行或单行 50 列，适合超长图片'**
  String get flowArrangeCardsIn50RowsOr50;

  /// No description provided for @flowExportPreview.
  ///
  /// In zh, this message translates to:
  /// **'导出效果图'**
  String get flowExportPreview;

  /// No description provided for @flowConfirmExport.
  ///
  /// In zh, this message translates to:
  /// **'确认导出'**
  String get flowConfirmExport;

  /// No description provided for @flowCouldNotGeneratePreviewP0.
  ///
  /// In zh, this message translates to:
  /// **'预览生成失败：{p0}'**
  String flowCouldNotGeneratePreviewP0(String p0);

  /// No description provided for @flowP0P1EstimatedP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，{p1}，预计 {p2}'**
  String flowP0P1EstimatedP2(String p0, String p1, String p2);

  /// No description provided for @flowAboutP0.
  ///
  /// In zh, this message translates to:
  /// **'约 {p0}'**
  String flowAboutP0(String p0);

  /// No description provided for @flowQuestionPool.
  ///
  /// In zh, this message translates to:
  /// **'题库范围'**
  String get flowQuestionPool;

  /// No description provided for @flowGameRules.
  ///
  /// In zh, this message translates to:
  /// **'对局规则'**
  String get flowGameRules;

  /// No description provided for @flowMaximumGuesses.
  ///
  /// In zh, this message translates to:
  /// **'最大猜测次数'**
  String get flowMaximumGuesses;

  /// No description provided for @flowTimeLimit.
  ///
  /// In zh, this message translates to:
  /// **'时间限制'**
  String get flowTimeLimit;

  /// No description provided for @flowTo.
  ///
  /// In zh, this message translates to:
  /// **'至'**
  String get flowTo;

  /// No description provided for @flowEnter10150ThenTap.
  ///
  /// In zh, this message translates to:
  /// **'可填 1.0 至 15.0，点其它位置或按回车生效'**
  String get flowEnter10150ThenTap;

  /// No description provided for @flowBest35ConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'Best35 定数区间'**
  String get flowBest35ConstantRange;

  /// No description provided for @flowBest15ConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'Best15 定数区间'**
  String get flowBest15ConstantRange;

  /// No description provided for @flowBest50Average.
  ///
  /// In zh, this message translates to:
  /// **'Best 50 平均'**
  String get flowBest50Average;

  /// No description provided for @flowBest35Average.
  ///
  /// In zh, this message translates to:
  /// **'Best 35 平均'**
  String get flowBest35Average;

  /// No description provided for @flowBest15Average.
  ///
  /// In zh, this message translates to:
  /// **'Best 15 平均'**
  String get flowBest15Average;

  /// No description provided for @flowSSSCountIn50Charts.
  ///
  /// In zh, this message translates to:
  /// **'50首 SSS+ 数量'**
  String get flowSSSCountIn50Charts;

  /// No description provided for @flowSSSCountIn50Charts2.
  ///
  /// In zh, this message translates to:
  /// **'50首 SSS 数量'**
  String get flowSSSCountIn50Charts2;

  /// No description provided for @flowPotentialConstantRATable.
  ///
  /// In zh, this message translates to:
  /// **'可提升定数 RA 对照'**
  String get flowPotentialConstantRATable;

  /// No description provided for @flowFittedTotalRating.
  ///
  /// In zh, this message translates to:
  /// **'拟合总Rating'**
  String get flowFittedTotalRating;

  /// No description provided for @flowDifferenceFromBest50.
  ///
  /// In zh, this message translates to:
  /// **'与Best50差值'**
  String get flowDifferenceFromBest50;

  /// No description provided for @flowAverageAchievementDXScoreRate2.
  ///
  /// In zh, this message translates to:
  /// **'平均达成率 / DX分数达成率'**
  String get flowAverageAchievementDXScoreRate2;

  /// No description provided for @flowCurrentOrderP0.
  ///
  /// In zh, this message translates to:
  /// **'当前排序：{p0}'**
  String flowCurrentOrderP0(String p0);

  /// No description provided for @flowTotalRA.
  ///
  /// In zh, this message translates to:
  /// **'总RA'**
  String get flowTotalRA;

  /// No description provided for @flowSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲数'**
  String get flowSongs;

  /// No description provided for @flowComparedWithThisTagSBest50.
  ///
  /// In zh, this message translates to:
  /// **'较该标签 Best50'**
  String get flowComparedWithThisTagSBest50;

  /// No description provided for @flowSongAchievement.
  ///
  /// In zh, this message translates to:
  /// **'单曲达成率'**
  String get flowSongAchievement;

  /// No description provided for @flowTotalRatingP0.
  ///
  /// In zh, this message translates to:
  /// **'总 Rating {p0}'**
  String flowTotalRatingP0(String p0);

  /// No description provided for @flowP0ConstantP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0} (定数 {p1})'**
  String flowP0ConstantP1(String p0, String p1);

  /// No description provided for @flowNoteStatistics.
  ///
  /// In zh, this message translates to:
  /// **'物量统计'**
  String get flowNoteStatistics;

  /// No description provided for @flowBREAKStatistics.
  ///
  /// In zh, this message translates to:
  /// **'绝赞统计'**
  String get flowBREAKStatistics;

  /// No description provided for @flowP0P1P2Statistics2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} {p1}({p2})统计'**
  String flowP0P1P2Statistics2(String p0, String p1, String p2);

  /// No description provided for @flowChartDesignerP0.
  ///
  /// In zh, this message translates to:
  /// **'谱师:{p0}'**
  String flowChartDesignerP0(String p0);

  /// No description provided for @flowVersionP0.
  ///
  /// In zh, this message translates to:
  /// **'版本:{p0}'**
  String flowVersionP0(String p0);

  /// No description provided for @flowGenreP0.
  ///
  /// In zh, this message translates to:
  /// **'流派:{p0}'**
  String flowGenreP0(String p0);

  /// No description provided for @flowComposerP0.
  ///
  /// In zh, this message translates to:
  /// **'曲师:{p0}'**
  String flowComposerP0(String p0);

  /// No description provided for @flowP0P1P2SongsTotal.
  ///
  /// In zh, this message translates to:
  /// **'{p0}{p1} | 共 {p2} 首歌曲'**
  String flowP0P1P2SongsTotal(String p0, String p1, String p2);

  /// No description provided for @flowFolderNameCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'收藏夹名称不能为空'**
  String get flowFolderNameCannotBeEmpty;

  /// No description provided for @flowNoAudioIsAvailableForThisSong.
  ///
  /// In zh, this message translates to:
  /// **'这首歌暂时没有可用的音源'**
  String get flowNoAudioIsAvailableForThisSong;

  /// No description provided for @flowCouldNotLoadAudioTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'音源加载失败，请稍后重试'**
  String get flowCouldNotLoadAudioTryAgainLater;

  /// No description provided for @flowReadingLocalVideo.
  ///
  /// In zh, this message translates to:
  /// **'正在读取本地视频…'**
  String get flowReadingLocalVideo;

  /// No description provided for @flowBufferingVideo.
  ///
  /// In zh, this message translates to:
  /// **'正在缓冲视频…'**
  String get flowBufferingVideo;

  /// No description provided for @flowNoMatchingChartCodeFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的谱面代码'**
  String get flowNoMatchingChartCodeFound;

  /// No description provided for @flowCouldNotFetchChartCodeP0.
  ///
  /// In zh, this message translates to:
  /// **'获取谱面代码失败: {p0}'**
  String flowCouldNotFetchChartCodeP0(String p0);

  /// No description provided for @flowExporting2.
  ///
  /// In zh, this message translates to:
  /// **'正在导出...'**
  String get flowExporting2;

  /// No description provided for @flowNoChartCodeAvailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无谱面代码数据'**
  String get flowNoChartCodeAvailable;

  /// No description provided for @flowAudio.
  ///
  /// In zh, this message translates to:
  /// **'音源'**
  String get flowAudio;

  /// No description provided for @flowCouldNotFetchP0ThePackageOnly.
  ///
  /// In zh, this message translates to:
  /// **'未能获取{p0}，压缩包里只有谱面数据，导入后需要自行补齐才能正常游玩。'**
  String flowCouldNotFetchP0ThePackageOnly(String p0);

  /// No description provided for @flowPreparingChart.
  ///
  /// In zh, this message translates to:
  /// **'正在准备谱面…'**
  String get flowPreparingChart;

  /// No description provided for @flowReadingChartSettings.
  ///
  /// In zh, this message translates to:
  /// **'正在读取谱面设置…'**
  String get flowReadingChartSettings;

  /// No description provided for @flowFindingAudio.
  ///
  /// In zh, this message translates to:
  /// **'正在查找音频文件…'**
  String get flowFindingAudio;

  /// No description provided for @flowPreparingCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'正在准备曲绘…'**
  String get flowPreparingCoverArt;

  /// No description provided for @flowParsingChartData.
  ///
  /// In zh, this message translates to:
  /// **'正在解析谱面数据…'**
  String get flowParsingChartData;

  /// No description provided for @flowAudioLoadedFromLocalCache.
  ///
  /// In zh, this message translates to:
  /// **'已从本地缓存读取音频'**
  String get flowAudioLoadedFromLocalCache;

  /// No description provided for @flowAnd.
  ///
  /// In zh, this message translates to:
  /// **'和'**
  String get flowAnd;

  /// No description provided for @flowP0MinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 分钟前'**
  String flowP0MinutesAgo(String p0);

  /// No description provided for @flowP0HoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 小时前'**
  String flowP0HoursAgo(String p0);

  /// No description provided for @flowP0DaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 天前'**
  String flowP0DaysAgo(String p0);

  /// No description provided for @flowCustomChart2.
  ///
  /// In zh, this message translates to:
  /// **'自定义谱面'**
  String get flowCustomChart2;

  /// No description provided for @flowMaidataFileSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择maidata文件'**
  String get flowMaidataFileSelected;

  /// No description provided for @flowTheLibraryIsNotReadyRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'曲库还没准备好。请先回首页「拉取成绩并更新数据」，或检查网络后重试。'**
  String get flowTheLibraryIsNotReadyRefreshData;

  /// No description provided for @flowCouldNotLoadLibraryP0.
  ///
  /// In zh, this message translates to:
  /// **'加载曲库失败：{p0}'**
  String flowCouldNotLoadLibraryP0(String p0);

  /// No description provided for @flowNotificationPermissionWasNotGrantedBackgroundPlayback.
  ///
  /// In zh, this message translates to:
  /// **'未授予通知权限：音乐仍可后台播放，但不会显示通知栏播放器'**
  String get flowNotificationPermissionWasNotGrantedBackgroundPlayback;

  /// No description provided for @flowDownloaded2.
  ///
  /// In zh, this message translates to:
  /// **'已下载'**
  String get flowDownloaded2;

  /// No description provided for @flowDownloadFailedP02.
  ///
  /// In zh, this message translates to:
  /// **'下载失败：{p0}'**
  String flowDownloadFailedP02(String p0);

  /// No description provided for @flowTheCurrentSongIsNotInThis.
  ///
  /// In zh, this message translates to:
  /// **'当前播放的曲目不在列表里'**
  String get flowTheCurrentSongIsNotInThis;

  /// No description provided for @flowNoPlayableSongs.
  ///
  /// In zh, this message translates to:
  /// **'没有可播放的歌曲'**
  String get flowNoPlayableSongs;

  /// No description provided for @flowNoMatchingSongs.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的歌曲'**
  String get flowNoMatchingSongs;

  /// No description provided for @flowP0PlayableSongs.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 首可播放'**
  String flowP0PlayableSongs(String p0);

  /// No description provided for @flowExcludedP0UTAGESongs.
  ///
  /// In zh, this message translates to:
  /// **'已排除宴会场 {p0} 首'**
  String flowExcludedP0UTAGESongs(String p0);

  /// No description provided for @flowP0SongsHaveNoDivingFishEntry.
  ///
  /// In zh, this message translates to:
  /// **'水鱼无对应条目 {p0} 首'**
  String flowP0SongsHaveNoDivingFishEntry(String p0);

  /// No description provided for @flowCalculating.
  ///
  /// In zh, this message translates to:
  /// **'计算中'**
  String get flowCalculating;

  /// No description provided for @flowSwitchingSongs.
  ///
  /// In zh, this message translates to:
  /// **'正在切换歌曲…'**
  String get flowSwitchingSongs;

  /// No description provided for @flowThisIsTheLastSong.
  ///
  /// In zh, this message translates to:
  /// **'已经是最后一首啦'**
  String get flowThisIsTheLastSong;

  /// No description provided for @flowUpNext.
  ///
  /// In zh, this message translates to:
  /// **'接下来'**
  String get flowUpNext;

  /// No description provided for @flowUpToOneDecimalPlaceLeaveBlank.
  ///
  /// In zh, this message translates to:
  /// **'最多一位小数，留空表示默认值'**
  String get flowUpToOneDecimalPlaceLeaveBlank;

  /// No description provided for @flowUpToFourDecimalPlacesLeaveBlank.
  ///
  /// In zh, this message translates to:
  /// **'最多四位小数，留空表示默认值'**
  String get flowUpToFourDecimalPlacesLeaveBlank;

  /// No description provided for @flowGrade.
  ///
  /// In zh, this message translates to:
  /// **'评级'**
  String get flowGrade;

  /// No description provided for @flowLowerBound.
  ///
  /// In zh, this message translates to:
  /// **'下界'**
  String get flowLowerBound;

  /// No description provided for @flowUpperBound.
  ///
  /// In zh, this message translates to:
  /// **'上界'**
  String get flowUpperBound;

  /// No description provided for @flowCategory.
  ///
  /// In zh, this message translates to:
  /// **'种类'**
  String get flowCategory;

  /// No description provided for @flowSelectALevel.
  ///
  /// In zh, this message translates to:
  /// **'请选择等级'**
  String get flowSelectALevel;

  /// No description provided for @flowSelectAVersion.
  ///
  /// In zh, this message translates to:
  /// **'请选择版本'**
  String get flowSelectAVersion;

  /// No description provided for @flowSelectAGenre.
  ///
  /// In zh, this message translates to:
  /// **'请选择流派'**
  String get flowSelectAGenre;

  /// No description provided for @flowTitleType.
  ///
  /// In zh, this message translates to:
  /// **'称号类型'**
  String get flowTitleType;

  /// No description provided for @flowNoMatchingChartDesigners2.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的谱师'**
  String get flowNoMatchingChartDesigners2;

  /// No description provided for @flowNoMatchingComposers.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的曲师'**
  String get flowNoMatchingComposers;

  /// No description provided for @flowSongs2.
  ///
  /// In zh, this message translates to:
  /// **'首'**
  String get flowSongs2;

  /// No description provided for @flowNoSongsMatchThisLevel.
  ///
  /// In zh, this message translates to:
  /// **'当前等级没有匹配的歌曲'**
  String get flowNoSongsMatchThisLevel;

  /// No description provided for @flowNoSongsMatchThisChartDesigner.
  ///
  /// In zh, this message translates to:
  /// **'当前谱师没有匹配的歌曲'**
  String get flowNoSongsMatchThisChartDesigner;

  /// No description provided for @flowNoSongsMatchThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本没有匹配的歌曲'**
  String get flowNoSongsMatchThisVersion;

  /// No description provided for @flowNoSongsMatchThisGenre.
  ///
  /// In zh, this message translates to:
  /// **'当前流派没有匹配的歌曲'**
  String get flowNoSongsMatchThisGenre;

  /// No description provided for @flowNoSongsMatchThisComposer.
  ///
  /// In zh, this message translates to:
  /// **'当前曲师没有匹配的歌曲'**
  String get flowNoSongsMatchThisComposer;

  /// No description provided for @flowLvP0P1P2TitleStatistics.
  ///
  /// In zh, this message translates to:
  /// **'Lv.{p0}({p1})的{p2}称号统计'**
  String flowLvP0P1P2TitleStatistics(String p0, String p1, String p2);

  /// No description provided for @flowChartDesignerP0P1P2TitleStatistics.
  ///
  /// In zh, this message translates to:
  /// **'谱师{p0}({p1})的{p2}称号统计'**
  String flowChartDesignerP0P1P2TitleStatistics(
      String p0, String p1, String p2);

  /// No description provided for @flowVersionP0P1P2TitleStatistics.
  ///
  /// In zh, this message translates to:
  /// **'版本{p0}({p1})的{p2}称号统计'**
  String flowVersionP0P1P2TitleStatistics(String p0, String p1, String p2);

  /// No description provided for @flowGenreP0P1P2TitleStatistics.
  ///
  /// In zh, this message translates to:
  /// **'流派{p0}({p1})的{p2}称号统计'**
  String flowGenreP0P1P2TitleStatistics(String p0, String p1, String p2);

  /// No description provided for @flowComposerP0P1P2TitleStatistics.
  ///
  /// In zh, this message translates to:
  /// **'曲师{p0}({p1})的{p2}称号统计'**
  String flowComposerP0P1P2TitleStatistics(String p0, String p1, String p2);

  /// No description provided for @flowFriendCode.
  ///
  /// In zh, this message translates to:
  /// **'好友码'**
  String get flowFriendCode;

  /// No description provided for @flowEnterYourFriendSP02.
  ///
  /// In zh, this message translates to:
  /// **'请输入好友的{p0}'**
  String flowEnterYourFriendSP02(String p0);

  /// No description provided for @flowMeP0.
  ///
  /// In zh, this message translates to:
  /// **'我 · {p0}'**
  String flowMeP0(String p0);

  /// No description provided for @flowMyWins.
  ///
  /// In zh, this message translates to:
  /// **'我赢'**
  String get flowMyWins;

  /// No description provided for @flowFriendSWins.
  ///
  /// In zh, this message translates to:
  /// **'好友赢'**
  String get flowFriendSWins;

  /// No description provided for @flowFriend.
  ///
  /// In zh, this message translates to:
  /// **'好友'**
  String get flowFriend;

  /// No description provided for @flowFirstCharacter.
  ///
  /// In zh, this message translates to:
  /// **'首字'**
  String get flowFirstCharacter;

  /// No description provided for @flowSelectAFirstCharacter.
  ///
  /// In zh, this message translates to:
  /// **'请选择首字'**
  String get flowSelectAFirstCharacter;

  /// No description provided for @flowNoSongsMatchThisDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'当前难度没有匹配的歌曲'**
  String get flowNoSongsMatchThisDifficulty;

  /// No description provided for @flowByAverageAchievement.
  ///
  /// In zh, this message translates to:
  /// **'平均达成率推荐'**
  String get flowByAverageAchievement;

  /// No description provided for @flowByConstantDifference.
  ///
  /// In zh, this message translates to:
  /// **'定数差值推荐'**
  String get flowByConstantDifference;

  /// No description provided for @flowAvgAchievement.
  ///
  /// In zh, this message translates to:
  /// **'平均达成'**
  String get flowAvgAchievement;

  /// No description provided for @flowConstantDifference.
  ///
  /// In zh, this message translates to:
  /// **'定数差值'**
  String get flowConstantDifference;

  /// No description provided for @flowPersonalBestP0.
  ///
  /// In zh, this message translates to:
  /// **'个人最佳 {p0}%'**
  String flowPersonalBestP0(String p0);

  /// No description provided for @flowLast30Days.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get flowLast30Days;

  /// No description provided for @flowLast90Days.
  ///
  /// In zh, this message translates to:
  /// **'近 90 天'**
  String get flowLast90Days;

  /// No description provided for @flowLimitP0TheoreticalValueUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'上限 {p0}（理论值未取到）'**
  String flowLimitP0TheoreticalValueUnavailable(String p0);

  /// No description provided for @flowCouldNotLoadImprovementHistoryP0.
  ///
  /// In zh, this message translates to:
  /// **'读取提升历史失败：{p0}'**
  String flowCouldNotLoadImprovementHistoryP0(String p0);

  /// No description provided for @flowChangesAreRecordedAutomaticallyAfterYourScores.
  ///
  /// In zh, this message translates to:
  /// **'成功刷新自己的成绩时自动记录，水鱼、落雪和 AWMC NET 按数据源与账号分别保存。\n\n首次没有旧成绩可比时仅建立基线；刷新无变化不新增记录。当天同一谱面的多次变化合成一张卡，展示首次变化前到最新值。\n\n按刷新时的本地日期归档，时间代表发现变化的时间，并非实际游玩时间。卡片按前后值标为成绩提升、成绩回退、成绩无变化，或有升有降的成绩变化；首次出现的谱面另注明首次记录。\n\nRating 是该谱面的 Rating，不代表总 Rating 的增量。历史仅在本机保存，不会自动回填启用前的旧成绩。'**
  String get flowChangesAreRecordedAutomaticallyAfterYourScores;

  /// No description provided for @flowNoScoreImprovementRecordsYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有成绩提升记录'**
  String get flowNoScoreImprovementRecordsYet;

  /// No description provided for @flowNoMatchingRecords.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的记录'**
  String get flowNoMatchingRecords;

  /// No description provided for @flowBestScoresThatChangeAfterASuccessful.
  ///
  /// In zh, this message translates to:
  /// **'成功刷新后，发生变化的最佳成绩会出现在这里。'**
  String get flowBestScoresThatChangeAfterASuccessful;

  /// No description provided for @flowTryAnotherKeywordOrDate.
  ///
  /// In zh, this message translates to:
  /// **'试试其他关键词或日期。'**
  String get flowTryAnotherKeywordOrDate;

  /// No description provided for @flowCouldNotLoad.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get flowCouldNotLoad;

  /// No description provided for @flowRequestFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'请求失败 ({p0})'**
  String flowRequestFailedP0(String p0);

  /// No description provided for @flowNetworkErrorP0.
  ///
  /// In zh, this message translates to:
  /// **'网络错误: {p0}'**
  String flowNetworkErrorP0(String p0);

  /// No description provided for @flowP0MinutesAgo2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}分钟前'**
  String flowP0MinutesAgo2(String p0);

  /// No description provided for @flowP0HoursAgo2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}小时前'**
  String flowP0HoursAgo2(String p0);

  /// No description provided for @flowP0DaysAgo2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}天前'**
  String flowP0DaysAgo2(String p0);

  /// No description provided for @flowP0User.
  ///
  /// In zh, this message translates to:
  /// **'{p0}用户'**
  String flowP0User(String p0);

  /// No description provided for @flowCouldNotSaveSnapshotP0.
  ///
  /// In zh, this message translates to:
  /// **'保存快照失败: {p0}'**
  String flowCouldNotSaveSnapshotP0(String p0);

  /// No description provided for @flowHighestConstantsFromOlderVersions.
  ///
  /// In zh, this message translates to:
  /// **'非当前版本最高定数'**
  String get flowHighestConstantsFromOlderVersions;

  /// No description provided for @flowBestScoresFromOlderVersions.
  ///
  /// In zh, this message translates to:
  /// **'非当前版本最好成绩'**
  String get flowBestScoresFromOlderVersions;

  /// No description provided for @flowHighestConstantsFromThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本最高定数'**
  String get flowHighestConstantsFromThisVersion;

  /// No description provided for @flowBestScoresFromThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本最好成绩'**
  String get flowBestScoresFromThisVersion;

  /// No description provided for @flowPattern.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get flowPattern;

  /// No description provided for @flowEvaluation.
  ///
  /// In zh, this message translates to:
  /// **'评价'**
  String get flowEvaluation;

  /// No description provided for @flowModeATakeTheTop50Charts.
  ///
  /// In zh, this message translates to:
  /// **'模式A：不分类Best35和Best15，直接获取拟合定数下的Rating前50的谱面'**
  String get flowModeATakeTheTop50Charts;

  /// No description provided for @flowModeBReplaceConstantsInYourOfficial.
  ///
  /// In zh, this message translates to:
  /// **'模式B：将您的Best35和Best15中的所有谱面的定数都替换为其拟合定数，然后计算Rating并降序排序'**
  String get flowModeBReplaceConstantsInYourOfficial;

  /// No description provided for @flowModeCTakeTheTop35Older.
  ///
  /// In zh, this message translates to:
  /// **'模式C：在非当前版本中取拟合定数下的Rating前35的谱面，在当前版本中取拟合定数下Rating前15的谱面'**
  String get flowModeCTakeTheTop35Older;

  /// No description provided for @flowTop35FromOlderVersions.
  ///
  /// In zh, this message translates to:
  /// **'非当前版本前 35'**
  String get flowTop35FromOlderVersions;

  /// No description provided for @flowTop15FromThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本前 15'**
  String get flowTop15FromThisVersion;

  /// No description provided for @flowP0ChartsHaveNoFittedConstantOfficial.
  ///
  /// In zh, this message translates to:
  /// **'{p0}首暂无拟合定数，按照官方定数计算'**
  String flowP0ChartsHaveNoFittedConstantOfficial(String p0);

  /// No description provided for @flowIncludesP0.
  ///
  /// In zh, this message translates to:
  /// **'包含: {p0}'**
  String flowIncludesP0(String p0);

  /// No description provided for @flowChartDesigner50P0.
  ///
  /// In zh, this message translates to:
  /// **'谱师50 - {p0}'**
  String flowChartDesigner50P0(String p0);

  /// No description provided for @flowVersion50P0.
  ///
  /// In zh, this message translates to:
  /// **'版本50 - {p0}'**
  String flowVersion50P0(String p0);

  /// No description provided for @flowGenre50P0.
  ///
  /// In zh, this message translates to:
  /// **'流派50 - {p0}'**
  String flowGenre50P0(String p0);

  /// No description provided for @flowStar50P0.
  ///
  /// In zh, this message translates to:
  /// **'星数50 - {p0}'**
  String flowStar50P0(String p0);

  /// No description provided for @flowTag50P0.
  ///
  /// In zh, this message translates to:
  /// **'标签50 - {p0}'**
  String flowTag50P0(String p0);

  /// No description provided for @flowPersonalizedBest50P0.
  ///
  /// In zh, this message translates to:
  /// **'个性化Best50 - {p0}'**
  String flowPersonalizedBest50P0(String p0);

  /// No description provided for @flowChartDesigner50P0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'谱师50 - {p0} 统计'**
  String flowChartDesigner50P0Statistics(String p0);

  /// No description provided for @flowVersion50P0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'版本50 - {p0} 统计'**
  String flowVersion50P0Statistics(String p0);

  /// No description provided for @flowGenre50P0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'流派50 - {p0} 统计'**
  String flowGenre50P0Statistics(String p0);

  /// No description provided for @flowStar50P0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'星数50 - {p0} 统计'**
  String flowStar50P0Statistics(String p0);

  /// No description provided for @flowTag50P0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'标签50 - {p0} 统计'**
  String flowTag50P0Statistics(String p0);

  /// No description provided for @flowP0Statistics.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 统计'**
  String flowP0Statistics(String p0);

  /// No description provided for @flowPersonalizedFittedBest50P0.
  ///
  /// In zh, this message translates to:
  /// **'个性化拟合Best50 - {p0}'**
  String flowPersonalizedFittedBest50P0(String p0);

  /// No description provided for @flowTagP0P1ChartsTop50By.
  ///
  /// In zh, this message translates to:
  /// **'标签：{p0} · 共{p1}张谱面 · 在拟合定数下计算单曲Rating，取前50的谱面'**
  String flowTagP0P1ChartsTop50By(String p0, String p1);

  /// No description provided for @flowAverage.
  ///
  /// In zh, this message translates to:
  /// **'平均'**
  String get flowAverage;

  /// No description provided for @flowOlderVersions.
  ///
  /// In zh, this message translates to:
  /// **'非当前版本'**
  String get flowOlderVersions;

  /// No description provided for @flowCurrentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本'**
  String get flowCurrentVersion;

  /// No description provided for @flowP0InvalidEntriesAchievementOrDXScore.
  ///
  /// In zh, this message translates to:
  /// **'⚠ 存在 {p0} 条非法数据（达成率或 DX 分数超过谱面上限）'**
  String flowP0InvalidEntriesAchievementOrDXScore(String p0);

  /// No description provided for @flowEG1005.
  ///
  /// In zh, this message translates to:
  /// **'如 100.5'**
  String get flowEG1005;

  /// No description provided for @flowEG3000.
  ///
  /// In zh, this message translates to:
  /// **'如 3000'**
  String get flowEG3000;

  /// No description provided for @flowEnterAchievement.
  ///
  /// In zh, this message translates to:
  /// **'请输入达成率'**
  String get flowEnterAchievement;

  /// No description provided for @flowDifficultyP03.
  ///
  /// In zh, this message translates to:
  /// **'难度{p0}'**
  String flowDifficultyP03(String p0);

  /// No description provided for @flowRADescending.
  ///
  /// In zh, this message translates to:
  /// **'RA 降序'**
  String get flowRADescending;

  /// No description provided for @flowRAAscending.
  ///
  /// In zh, this message translates to:
  /// **'RA 升序'**
  String get flowRAAscending;

  /// No description provided for @flowConstantDescending.
  ///
  /// In zh, this message translates to:
  /// **'定数 降序'**
  String get flowConstantDescending;

  /// No description provided for @flowConstantAscending.
  ///
  /// In zh, this message translates to:
  /// **'定数 升序'**
  String get flowConstantAscending;

  /// No description provided for @flowFilled.
  ///
  /// In zh, this message translates to:
  /// **'已填写'**
  String get flowFilled;

  /// No description provided for @flowCouldNotLoadP0.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {p0}'**
  String flowCouldNotLoadP0(String p0);

  /// No description provided for @flowModeATop50ByFittedRating.
  ///
  /// In zh, this message translates to:
  /// **'模式A：不分类，按拟合 Rating 取前50'**
  String get flowModeATop50ByFittedRating;

  /// No description provided for @flowModeBRecalculateOfficialBest35Best15Using.
  ///
  /// In zh, this message translates to:
  /// **'模式B：按官方 Best35/Best15 替换拟合定数重算'**
  String get flowModeBRecalculateOfficialBest35Best15Using;

  /// No description provided for @flowModeCTop35OlderChartsAnd.
  ///
  /// In zh, this message translates to:
  /// **'模式C：非新曲取前35，新曲取前15'**
  String get flowModeCTop35OlderChartsAnd;

  /// No description provided for @flow6MaximumReached.
  ///
  /// In zh, this message translates to:
  /// **'✦ 6 已满'**
  String get flow6MaximumReached;

  /// No description provided for @flowCouldNotLoadLeaderboardData.
  ///
  /// In zh, this message translates to:
  /// **'加载排行榜数据失败'**
  String get flowCouldNotLoadLeaderboardData;

  /// No description provided for @flowAchievementRanking2.
  ///
  /// In zh, this message translates to:
  /// **'达成率排行榜'**
  String get flowAchievementRanking2;

  /// No description provided for @flowDXScoreRanking2.
  ///
  /// In zh, this message translates to:
  /// **'DX分数排行榜'**
  String get flowDXScoreRanking2;

  /// No description provided for @flowCouldNotFetchLeaderboardP0.
  ///
  /// In zh, this message translates to:
  /// **'获取排行榜失败: {p0}'**
  String flowCouldNotFetchLeaderboardP0(String p0);

  /// No description provided for @flowBREAKShareRanking.
  ///
  /// In zh, this message translates to:
  /// **'绝赞占比排行榜'**
  String get flowBREAKShareRanking;

  /// No description provided for @flowSameSongDifficultyGapRanking.
  ///
  /// In zh, this message translates to:
  /// **'同曲难度跨度排行榜'**
  String get flowSameSongDifficultyGapRanking;

  /// No description provided for @flowSLIDEShareRanking.
  ///
  /// In zh, this message translates to:
  /// **'SLIDE 占比排行榜'**
  String get flowSLIDEShareRanking;

  /// No description provided for @flowTOUCHShareRanking.
  ///
  /// In zh, this message translates to:
  /// **'TOUCH 占比排行榜'**
  String get flowTOUCHShareRanking;

  /// No description provided for @flowTAPShareRanking.
  ///
  /// In zh, this message translates to:
  /// **'TAP 占比排行榜'**
  String get flowTAPShareRanking;

  /// No description provided for @flowHOLDShareRanking.
  ///
  /// In zh, this message translates to:
  /// **'HOLD 占比排行榜'**
  String get flowHOLDShareRanking;

  /// No description provided for @flowBREAKCountRanking.
  ///
  /// In zh, this message translates to:
  /// **'绝赞数排行榜'**
  String get flowBREAKCountRanking;

  /// No description provided for @flowNormalChartBREAKCountRanking.
  ///
  /// In zh, this message translates to:
  /// **'常规谱绝赞数排行榜'**
  String get flowNormalChartBREAKCountRanking;

  /// No description provided for @flowConstantDifferenceRanking.
  ///
  /// In zh, this message translates to:
  /// **'定数差值排行榜'**
  String get flowConstantDifferenceRanking;

  /// No description provided for @flowMASTERReMASTERConstantDifferenceRanking.
  ///
  /// In zh, this message translates to:
  /// **'MASTER/Re:MASTER定数差值排行榜'**
  String get flowMASTERReMASTERConstantDifferenceRanking;

  /// No description provided for @flowEXPERTConstantDifferenceRanking.
  ///
  /// In zh, this message translates to:
  /// **'EXPERT定数差值排行榜'**
  String get flowEXPERTConstantDifferenceRanking;

  /// No description provided for @flowSampleCountRanking.
  ///
  /// In zh, this message translates to:
  /// **'样本总数排行榜'**
  String get flowSampleCountRanking;

  /// No description provided for @flowNoteCountRanking.
  ///
  /// In zh, this message translates to:
  /// **'物量排行榜'**
  String get flowNoteCountRanking;

  /// No description provided for @flowMASTERReMASTERAverageAchievementRanking.
  ///
  /// In zh, this message translates to:
  /// **'MASTER/Re:MASTER平均达成率排行榜'**
  String get flowMASTERReMASTERAverageAchievementRanking;

  /// No description provided for @flowEXPERTAverageAchievementRanking.
  ///
  /// In zh, this message translates to:
  /// **'EXPERT平均达成率排行榜'**
  String get flowEXPERTAverageAchievementRanking;

  /// No description provided for @flowBPMRanking.
  ///
  /// In zh, this message translates to:
  /// **'BPM排行榜'**
  String get flowBPMRanking;

  /// No description provided for @flowBREAKShare.
  ///
  /// In zh, this message translates to:
  /// **'绝赞占比'**
  String get flowBREAKShare;

  /// No description provided for @flowConstantGap.
  ///
  /// In zh, this message translates to:
  /// **'定数跨度'**
  String get flowConstantGap;

  /// No description provided for @flowSLIDEShare.
  ///
  /// In zh, this message translates to:
  /// **'SLIDE 占比'**
  String get flowSLIDEShare;

  /// No description provided for @flowTOUCHShare.
  ///
  /// In zh, this message translates to:
  /// **'TOUCH 占比'**
  String get flowTOUCHShare;

  /// No description provided for @flowTAPShare.
  ///
  /// In zh, this message translates to:
  /// **'TAP 占比'**
  String get flowTAPShare;

  /// No description provided for @flowHOLDShare.
  ///
  /// In zh, this message translates to:
  /// **'HOLD 占比'**
  String get flowHOLDShare;

  /// No description provided for @flowBREAKCount.
  ///
  /// In zh, this message translates to:
  /// **'绝赞数'**
  String get flowBREAKCount;

  /// No description provided for @flowSampleCount.
  ///
  /// In zh, this message translates to:
  /// **'样本总数'**
  String get flowSampleCount;

  /// No description provided for @flowRankByBREAKCountOrderCanBe.
  ///
  /// In zh, this message translates to:
  /// **'按谱面绝赞数量排名（可切换正反向）'**
  String get flowRankByBREAKCountOrderCanBe;

  /// No description provided for @flowRankByBREAKCountExcludingUTAGEOrder.
  ///
  /// In zh, this message translates to:
  /// **'绝赞数排行榜，但宴会场不参与（可切换正反向）'**
  String get flowRankByBREAKCountExcludingUTAGEOrder;

  /// No description provided for @flowBREAKCountTotalNotesRankedAsA.
  ///
  /// In zh, this message translates to:
  /// **'绝赞数 ÷ 总物量，以百分比排名（可切换正反向）'**
  String get flowBREAKCountTotalNotesRankedAsA;

  /// No description provided for @flowTAPCountTotalNotesIncludesSTDX.
  ///
  /// In zh, this message translates to:
  /// **'TAP 数 ÷ 总物量，ST/DX/UT 均参与（可切换正反向）'**
  String get flowTAPCountTotalNotesIncludesSTDX;

  /// No description provided for @flowHOLDCountTotalNotesIncludesSTDX.
  ///
  /// In zh, this message translates to:
  /// **'HOLD 数 ÷ 总物量，ST/DX/UT 均参与（可切换正反向）'**
  String get flowHOLDCountTotalNotesIncludesSTDX;

  /// No description provided for @flowSLIDECountTotalNotesIncludesSTDX.
  ///
  /// In zh, this message translates to:
  /// **'SLIDE 数 ÷ 总物量，ST/DX/UT 均参与（可切换正反向）'**
  String get flowSLIDECountTotalNotesIncludesSTDX;

  /// No description provided for @flowTOUCHCountTotalNotesIncludesDXUT.
  ///
  /// In zh, this message translates to:
  /// **'TOUCH 数 ÷ 总物量，DX/UT 参与，ST 不参与（可切换正反向）'**
  String get flowTOUCHCountTotalNotesIncludesDXUT;

  /// No description provided for @flowOfficialConstantGapForEXPERTMASTERAnd.
  ///
  /// In zh, this message translates to:
  /// **'同曲 EXPERT→MASTER、MASTER→Re:MASTER 的官方定数差（后者减前者，可切换正反向）'**
  String get flowOfficialConstantGapForEXPERTMASTERAnd;

  /// No description provided for @flowRankByFittedMinusOfficialConstantOrder.
  ///
  /// In zh, this message translates to:
  /// **'拟合定数与官方定数差值排名（可切换正反向）'**
  String get flowRankByFittedMinusOfficialConstantOrder;

  /// No description provided for @flowMASTERReMASTEROnlyOrderCanBe.
  ///
  /// In zh, this message translates to:
  /// **'只统计MASTER/Re:MASTER难度（可切换正反向）'**
  String get flowMASTERReMASTEROnlyOrderCanBe;

  /// No description provided for @flowEXPERTOnlyOrderCanBeReversed.
  ///
  /// In zh, this message translates to:
  /// **'只统计EXPERT难度（可切换正反向）'**
  String get flowEXPERTOnlyOrderCanBeReversed;

  /// No description provided for @flowRankByTotalPlayerSamplesOrderCan.
  ///
  /// In zh, this message translates to:
  /// **'玩家样本总量排名（可切换正反向）'**
  String get flowRankByTotalPlayerSamplesOrderCan;

  /// No description provided for @flowRankByTheTotalOfAllFive.
  ///
  /// In zh, this message translates to:
  /// **'五种note总数排名（可切换正反向）'**
  String get flowRankByTheTotalOfAllFive;

  /// No description provided for @flowRankByAverageAchievementOrderCanBe.
  ///
  /// In zh, this message translates to:
  /// **'按平均达成率排名（可切换正反向）'**
  String get flowRankByAverageAchievementOrderCanBe;

  /// No description provided for @flowRankBySongBPMOrderCanBe.
  ///
  /// In zh, this message translates to:
  /// **'按歌曲BPM排名（可切换正反向）'**
  String get flowRankBySongBPMOrderCanBe;

  /// No description provided for @flowEnterABVID.
  ///
  /// In zh, this message translates to:
  /// **'请输入 BV 号'**
  String get flowEnterABVID;

  /// No description provided for @flowInvalidBVIDExpectedBVFollowedBy.
  ///
  /// In zh, this message translates to:
  /// **'BV 号格式不正确（应为 BV + 10位字符）'**
  String get flowInvalidBVIDExpectedBVFollowedBy;

  /// No description provided for @flowCheckFailedVideoInformationUnavailableTheBV.
  ///
  /// In zh, this message translates to:
  /// **'校验失败: 无法获取视频信息（BV 号可能不存在）'**
  String get flowCheckFailedVideoInformationUnavailableTheBV;

  /// No description provided for @flowVerifiedVideoTitleP0.
  ///
  /// In zh, this message translates to:
  /// **'校验通过！视频标题: \"{p0}\"'**
  String flowVerifiedVideoTitleP0(String p0);

  /// No description provided for @flowCheckFailedVideoTitleP0DoesNot.
  ///
  /// In zh, this message translates to:
  /// **'校验失败: 视频标题 \"{p0}\" 不包含歌曲名 \"{p1}\"'**
  String flowCheckFailedVideoTitleP0DoesNot(String p0, String p1);

  /// No description provided for @flowVerificationErrorP0.
  ///
  /// In zh, this message translates to:
  /// **'校验异常: {p0}'**
  String flowVerificationErrorP0(String p0);

  /// No description provided for @flowSongPV.
  ///
  /// In zh, this message translates to:
  /// **'歌曲 PV'**
  String get flowSongPV;

  /// No description provided for @flowPlayThisChartAtLeastOnceBefore.
  ///
  /// In zh, this message translates to:
  /// **'至少游玩过一次该谱面才能参与打分'**
  String get flowPlayThisChartAtLeastOnceBefore;

  /// No description provided for @flowInvalidScorePleaseCheckIt.
  ///
  /// In zh, this message translates to:
  /// **'成绩不合法，请检查'**
  String get flowInvalidScorePleaseCheckIt;

  /// No description provided for @flowContentCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'内容不能为空'**
  String get flowContentCannotBeEmpty;

  /// No description provided for @flowCommentsCannotExceed500Characters.
  ///
  /// In zh, this message translates to:
  /// **'评论内容不能超过500字'**
  String get flowCommentsCannotExceed500Characters;

  /// No description provided for @flowSending.
  ///
  /// In zh, this message translates to:
  /// **'发送中...'**
  String get flowSending;

  /// No description provided for @flowOpenBilibili2.
  ///
  /// In zh, this message translates to:
  /// **'跳转到B站'**
  String get flowOpenBilibili2;

  /// No description provided for @flowRelatedCollectiblesP0.
  ///
  /// In zh, this message translates to:
  /// **'相关收藏品 {p0}'**
  String flowRelatedCollectiblesP0(String p0);

  /// No description provided for @flowMyScoreP0.
  ///
  /// In zh, this message translates to:
  /// **'我的成绩 · {p0}'**
  String flowMyScoreP0(String p0);

  /// No description provided for @flowPlayedP0Times.
  ///
  /// In zh, this message translates to:
  /// **'游玩 {p0} 次'**
  String flowPlayedP0Times(String p0);

  /// No description provided for @flowFittedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'拟合 {p0}{p1}'**
  String flowFittedP0P1(String p0, String p1);

  /// No description provided for @flowDuration3.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get flowDuration3;

  /// No description provided for @flowScoreHistory.
  ///
  /// In zh, this message translates to:
  /// **'成绩历史'**
  String get flowScoreHistory;

  /// No description provided for @flowData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get flowData;

  /// No description provided for @flowCommunity.
  ///
  /// In zh, this message translates to:
  /// **'社区'**
  String get flowCommunity;

  /// No description provided for @flowTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get flowTools;

  /// No description provided for @flowTrueBREAKTAP.
  ///
  /// In zh, this message translates to:
  /// **'真绝赞TAP'**
  String get flowTrueBREAKTAP;

  /// No description provided for @flowTrueBREAKHOLD.
  ///
  /// In zh, this message translates to:
  /// **'真绝赞HOLD'**
  String get flowTrueBREAKHOLD;

  /// No description provided for @flowProtectedBREAK.
  ///
  /// In zh, this message translates to:
  /// **'保护套绝赞'**
  String get flowProtectedBREAK;

  /// No description provided for @flowBREAKStar.
  ///
  /// In zh, this message translates to:
  /// **'绝赞星星'**
  String get flowBREAKStar;

  /// No description provided for @flowCategory2.
  ///
  /// In zh, this message translates to:
  /// **'类别'**
  String get flowCategory2;

  /// No description provided for @flowTotal.
  ///
  /// In zh, this message translates to:
  /// **'共 '**
  String get flowTotal;

  /// No description provided for @flowSSSAllowance.
  ///
  /// In zh, this message translates to:
  /// **'SSS+ 容错'**
  String get flowSSSAllowance;

  /// No description provided for @flowSSSAllowance2.
  ///
  /// In zh, this message translates to:
  /// **'SSS 容错'**
  String get flowSSSAllowance2;

  /// No description provided for @flowChartTagsReferenceOnly.
  ///
  /// In zh, this message translates to:
  /// **'谱面标签(仅供参考)'**
  String get flowChartTagsReferenceOnly;

  /// No description provided for @flowPreview.
  ///
  /// In zh, this message translates to:
  /// **'试听'**
  String get flowPreview;

  /// No description provided for @flowMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get flowMore;

  /// No description provided for @flowViewChartCode.
  ///
  /// In zh, this message translates to:
  /// **'查看谱面代码'**
  String get flowViewChartCode;

  /// No description provided for @flowUTAGESongsAreExcludedFromBest50.
  ///
  /// In zh, this message translates to:
  /// **'宴会场歌曲不参与Best50'**
  String get flowUTAGESongsAreExcludedFromBest50;

  /// No description provided for @flowThisChartIsAlreadyWithinP0With.
  ///
  /// In zh, this message translates to:
  /// **'该谱面已在{p0}区间内且无提升空间'**
  String flowThisChartIsAlreadyWithinP0With(String p0);

  /// No description provided for @flowThisChartCannotEnterP0.
  ///
  /// In zh, this message translates to:
  /// **'该谱面无法进入{p0}'**
  String flowThisChartCannotEnterP0(String p0);

  /// No description provided for @flowReachP0ToP1P2.
  ///
  /// In zh, this message translates to:
  /// **'推到 {p0}% 可{p1} {p2}'**
  String flowReachP0ToP1P2(String p0, String p1, String p2);

  /// No description provided for @flowEnter.
  ///
  /// In zh, this message translates to:
  /// **'进入'**
  String get flowEnter;

  /// No description provided for @flowThisChartHasRAP0ReachingThe.
  ///
  /// In zh, this message translates to:
  /// **'这张谱面当前 RA {p0}，推到下面的达成率时 {p1} 总分能加：'**
  String flowThisChartHasRAP0ReachingThe(String p0, String p1);

  /// No description provided for @flowThisChartIsNotInP0The.
  ///
  /// In zh, this message translates to:
  /// **'这张谱面还不在 {p0}，末位是 RA {p1}。推到下面的达成率替换末位后，总分能加：'**
  String flowThisChartIsNotInP0The(String p0, String p1);

  /// No description provided for @flowP0BaseP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}(基准 {p1})'**
  String flowP0BaseP1(String p0, String p1);

  /// No description provided for @flowUserUpload.
  ///
  /// In zh, this message translates to:
  /// **'用户上传'**
  String get flowUserUpload;

  /// No description provided for @flowRedisCache.
  ///
  /// In zh, this message translates to:
  /// **'Redis 缓存'**
  String get flowRedisCache;

  /// No description provided for @flowAutomaticLookup.
  ///
  /// In zh, this message translates to:
  /// **'自动获取'**
  String get flowAutomaticLookup;

  /// No description provided for @flowUnknownType.
  ///
  /// In zh, this message translates to:
  /// **'未知类型'**
  String get flowUnknownType;

  /// No description provided for @flowCountCannotBeNegative.
  ///
  /// In zh, this message translates to:
  /// **'数量不能为负数'**
  String get flowCountCannotBeNegative;

  /// No description provided for @flowPlayedCountP0CannotExceedTheTotal.
  ///
  /// In zh, this message translates to:
  /// **'已打出总数（{p0}）不能超过BREAK总数（{p1}）'**
  String flowPlayedCountP0CannotExceedTheTotal(String p0, String p1);

  /// No description provided for @flowBREAKLossIsP0BeyondTheSS.
  ///
  /// In zh, this message translates to:
  /// **'BREAK损失已达{p0}%，超过SS(-2%)上限，无法继续容错'**
  String flowBREAKLossIsP0BeyondTheSS(String p0);

  /// No description provided for @flowP0DaysApart.
  ///
  /// In zh, this message translates to:
  /// **'(相差{p0}天)'**
  String flowP0DaysApart(String p0);

  /// No description provided for @flowFirstReleaseP0.
  ///
  /// In zh, this message translates to:
  /// **'首次上线{p0}'**
  String flowFirstReleaseP0(String p0);

  /// No description provided for @flowBase.
  ///
  /// In zh, this message translates to:
  /// **'基准'**
  String get flowBase;

  /// No description provided for @flowProtectedNOTEDistribution.
  ///
  /// In zh, this message translates to:
  /// **'保护套 NOTE 分布'**
  String get flowProtectedNOTEDistribution;

  /// No description provided for @flowProtectedTAP.
  ///
  /// In zh, this message translates to:
  /// **'保护套TAP'**
  String get flowProtectedTAP;

  /// No description provided for @flowProtectedHOLD.
  ///
  /// In zh, this message translates to:
  /// **'保护套HOLD'**
  String get flowProtectedHOLD;

  /// No description provided for @flowUnprotectedNOTEDistribution.
  ///
  /// In zh, this message translates to:
  /// **'无保护套 NOTE 分布'**
  String get flowUnprotectedNOTEDistribution;

  /// No description provided for @flowUnprotectedTAP.
  ///
  /// In zh, this message translates to:
  /// **'无保护套TAP'**
  String get flowUnprotectedTAP;

  /// No description provided for @flowUnprotectedHOLD.
  ///
  /// In zh, this message translates to:
  /// **'无保护套HOLD'**
  String get flowUnprotectedHOLD;

  /// No description provided for @flowTwoColumns.
  ///
  /// In zh, this message translates to:
  /// **'双列'**
  String get flowTwoColumns;

  /// No description provided for @flowOneColumn.
  ///
  /// In zh, this message translates to:
  /// **'单列'**
  String get flowOneColumn;

  /// No description provided for @flowP00Songs.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 0 首'**
  String flowP00Songs(String p0);

  /// No description provided for @flowP0P1SongsMinP2AvgP3.
  ///
  /// In zh, this message translates to:
  /// **'{p0} {p1} 首 · 最低 {p2} · 平均 {p3} · 点卡片看推分空间'**
  String flowP0P1SongsMinP2AvgP3(String p0, String p1, String p2, String p3);

  /// No description provided for @flowSongLimitReached.
  ///
  /// In zh, this message translates to:
  /// **'已到单曲上限'**
  String get flowSongLimitReached;

  /// No description provided for @flowChartHistoryCouldNotReadChartHistoryIgnored.
  ///
  /// In zh, this message translates to:
  /// **'[ChartHistory] 读取谱面历史失败（忽略）: {p0}'**
  String flowChartHistoryCouldNotReadChartHistoryIgnored(String p0);

  /// No description provided for @flowP0AchievementP1P2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}\n达成率 {p1}%{p2}'**
  String flowP0AchievementP1P2(String p0, String p1, String p2);

  /// No description provided for @flowDXScoreP03.
  ///
  /// In zh, this message translates to:
  /// **' · DX分数 {p0}'**
  String flowDXScoreP03(String p0);

  /// No description provided for @flow1DataPoint.
  ///
  /// In zh, this message translates to:
  /// **'1 个记录点'**
  String get flow1DataPoint;

  /// No description provided for @flowP0Changes.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 次变化'**
  String flowP0Changes(String p0);

  /// No description provided for @flowDXScoreOfMaximum.
  ///
  /// In zh, this message translates to:
  /// **'DX分数（占满分%）'**
  String get flowDXScoreOfMaximum;

  /// No description provided for @flowP0AchievementP1DXScoreP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}\n达成率 {p1}%\nDX分数 {p2}'**
  String flowP0AchievementP1DXScoreP2(String p0, String p1, String p2);

  /// No description provided for @flowChartLimit.
  ///
  /// In zh, this message translates to:
  /// **'谱面上限'**
  String get flowChartLimit;

  /// No description provided for @flowDeleteThisDataPoint2.
  ///
  /// In zh, this message translates to:
  /// **'删除这个记录点'**
  String get flowDeleteThisDataPoint2;

  /// No description provided for @flowPlayerBriefProfile.
  ///
  /// In zh, this message translates to:
  /// **'玩家简要信息'**
  String get flowPlayerBriefProfile;

  /// No description provided for @flowBriefProfileUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取简要信息'**
  String get flowBriefProfileUnavailable;

  /// No description provided for @flowLoadingBriefProfile.
  ///
  /// In zh, this message translates to:
  /// **'正在读取简要信息…'**
  String get flowLoadingBriefProfile;

  /// No description provided for @flowNoBackgroundSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置背景'**
  String get flowNoBackgroundSet;

  /// No description provided for @flowLoadingBackground.
  ///
  /// In zh, this message translates to:
  /// **'背景加载中'**
  String get flowLoadingBackground;

  /// No description provided for @flowBackgroundUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'背景暂不可用'**
  String get flowBackgroundUnavailable;

  /// No description provided for @flowNoNameplateSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置姓名框'**
  String get flowNoNameplateSet;

  /// No description provided for @flowLoadingNameplate.
  ///
  /// In zh, this message translates to:
  /// **'姓名框加载中'**
  String get flowLoadingNameplate;

  /// No description provided for @flowNameplateUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'姓名框暂不可用'**
  String get flowNameplateUnavailable;

  /// No description provided for @flowTitleP0.
  ///
  /// In zh, this message translates to:
  /// **'称号 #{p0}'**
  String flowTitleP0(String p0);

  /// No description provided for @flowNotAttempted.
  ///
  /// In zh, this message translates to:
  /// **'未挑战'**
  String get flowNotAttempted;

  /// No description provided for @flowRedPass.
  ///
  /// In zh, this message translates to:
  /// **'赤合格'**
  String get flowRedPass;

  /// No description provided for @flowEnterAValidTotalAchievement.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的总达成率'**
  String get flowEnterAValidTotalAchievement;

  /// No description provided for @flowTotalAchievementMustBeBetween0And.
  ///
  /// In zh, this message translates to:
  /// **'总达成率必须在 0～404% 之间'**
  String get flowTotalAchievementMustBeBetween0And;

  /// No description provided for @flowTotalAchievementSupportsUpToFourDecimal.
  ///
  /// In zh, this message translates to:
  /// **'总达成率最多保留 4 位小数'**
  String get flowTotalAchievementSupportsUpToFourDecimal;

  /// No description provided for @flowTotal2.
  ///
  /// In zh, this message translates to:
  /// **'总数'**
  String get flowTotal2;

  /// No description provided for @flowByLevel.
  ///
  /// In zh, this message translates to:
  /// **'按等级'**
  String get flowByLevel;

  /// No description provided for @flowByConstant.
  ///
  /// In zh, this message translates to:
  /// **'按定数'**
  String get flowByConstant;

  /// No description provided for @flowRegression.
  ///
  /// In zh, this message translates to:
  /// **'回退'**
  String get flowRegression;

  /// No description provided for @flowChange2.
  ///
  /// In zh, this message translates to:
  /// **'变化'**
  String get flowChange2;

  /// No description provided for @flowClosePlaybackModeSelection.
  ///
  /// In zh, this message translates to:
  /// **'关闭播放模式选择'**
  String get flowClosePlaybackModeSelection;

  /// No description provided for @flowSequential.
  ///
  /// In zh, this message translates to:
  /// **'顺序播放'**
  String get flowSequential;

  /// No description provided for @flowShuffle.
  ///
  /// In zh, this message translates to:
  /// **'随机播放'**
  String get flowShuffle;

  /// No description provided for @flowRepeatOne.
  ///
  /// In zh, this message translates to:
  /// **'单曲循环'**
  String get flowRepeatOne;

  /// No description provided for @flowTranslationIsUnavailableTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法翻译，请稍后重试'**
  String get flowTranslationIsUnavailableTryAgainLater;

  /// No description provided for @flowTranslationFailedTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'翻译失败，请稍后重试'**
  String get flowTranslationFailedTryAgainLater;

  /// No description provided for @flowNumberOfEntries.
  ///
  /// In zh, this message translates to:
  /// **'添加次数'**
  String get flowNumberOfEntries;

  /// No description provided for @flowSourceP02.
  ///
  /// In zh, this message translates to:
  /// **'数据源 {p0}'**
  String flowSourceP02(String p0);

  /// No description provided for @flowGeneratedByChiffonMaiCommunityGroupP0.
  ///
  /// In zh, this message translates to:
  /// **'Generated by ChiffonMai · 交流群 {p0}'**
  String flowGeneratedByChiffonMaiCommunityGroupP0(String p0);

  /// No description provided for @flowExportSuccessful.
  ///
  /// In zh, this message translates to:
  /// **'导出成功'**
  String get flowExportSuccessful;

  /// No description provided for @flowExported.
  ///
  /// In zh, this message translates to:
  /// **'已导出'**
  String get flowExported;

  /// No description provided for @flow50Rows1Column.
  ///
  /// In zh, this message translates to:
  /// **'单列 50 行'**
  String get flow50Rows1Column;

  /// No description provided for @flow1Row50Columns.
  ///
  /// In zh, this message translates to:
  /// **'单行 50 列'**
  String get flow1Row50Columns;

  /// No description provided for @flowZoomOut.
  ///
  /// In zh, this message translates to:
  /// **'缩小'**
  String get flowZoomOut;

  /// No description provided for @flowZoomIn.
  ///
  /// In zh, this message translates to:
  /// **'放大'**
  String get flowZoomIn;

  /// No description provided for @flowFitToWindow.
  ///
  /// In zh, this message translates to:
  /// **'适应窗口'**
  String get flowFitToWindow;

  /// No description provided for @flowMustBeGreaterThan0.
  ///
  /// In zh, this message translates to:
  /// **'必须大于 0'**
  String get flowMustBeGreaterThan0;

  /// No description provided for @flowMustNotExceedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'不得超过 {p0}{p1}'**
  String flowMustNotExceedP0P1(String p0, String p1);

  /// No description provided for @flowLimitP0P1.
  ///
  /// In zh, this message translates to:
  /// **'上限 {p0}（{p1}）'**
  String flowLimitP0P1(String p0, String p1);

  /// No description provided for @flowRatingP0Best35P1Best15P2Average.
  ///
  /// In zh, this message translates to:
  /// **'Rating {p0}\nBest35 {p1} · Best15 {p2}\n平均达成率 {p3}%\n平均DX分数达成率 {p4}%'**
  String flowRatingP0Best35P1Best15P2Average(
      String p0, String p1, String p2, String p3, String p4);

  /// No description provided for @flowTheoreticalBest35HighestConstantsFromOlderVersions.
  ///
  /// In zh, this message translates to:
  /// **'理论Best35 | 非当前版本最高定数'**
  String get flowTheoreticalBest35HighestConstantsFromOlderVersions;

  /// No description provided for @flowBest35BestScoresFromOlderVersions.
  ///
  /// In zh, this message translates to:
  /// **'Best35 | 非当前版本最好成绩'**
  String get flowBest35BestScoresFromOlderVersions;

  /// No description provided for @flowTheoreticalBest15HighestConstantsFromThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'理论Best15 | 当前版本最高定数'**
  String get flowTheoreticalBest15HighestConstantsFromThisVersion;

  /// No description provided for @flowBest15BestScoresFromThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'Best15 | 当前版本最好成绩'**
  String get flowBest15BestScoresFromThisVersion;

  /// No description provided for @flowAverageP02.
  ///
  /// In zh, this message translates to:
  /// **'平均 {p0}'**
  String flowAverageP02(String p0);

  /// No description provided for @flowFittedRatingP0AverageRatingP1Average.
  ///
  /// In zh, this message translates to:
  /// **'拟合 Rating {p0}\n平均 Rating {p1}\n平均达成率 {p2}%\n平均DX分数达成率 {p3}%'**
  String flowFittedRatingP0AverageRatingP1Average(
      String p0, String p1, String p2, String p3);

  /// No description provided for @flowBest50BasedOnFittedConstants.
  ///
  /// In zh, this message translates to:
  /// **'基于拟合难度的Best50'**
  String get flowBest50BasedOnFittedConstants;

  /// No description provided for @flowP0ChartsTotalRatingP1AverageDX.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 张谱面\nRating 合计 {p1}\n平均DX分数达成率 {p2}%'**
  String flowP0ChartsTotalRatingP1AverageDX(String p0, String p1, String p2);

  /// No description provided for @flowAverageRAP0.
  ///
  /// In zh, this message translates to:
  /// **'平均RA {p0}'**
  String flowAverageRAP0(String p0);

  /// No description provided for @flowFittedRatingP0VsThisTagS.
  ///
  /// In zh, this message translates to:
  /// **'拟合 Rating {p0}（较该标签 Best50 {p1}{p2}）\n平均 Rating {p3}\n平均达成率 {p4}%\n平均DX分数达成率 {p5}%'**
  String flowFittedRatingP0VsThisTagS(
      String p0, String p1, String p2, String p3, String p4, String p5);

  /// No description provided for @flowChartType.
  ///
  /// In zh, this message translates to:
  /// **'谱面类型'**
  String get flowChartType;

  /// No description provided for @flowReferenceDuration.
  ///
  /// In zh, this message translates to:
  /// **'参考时长'**
  String get flowReferenceDuration;

  /// No description provided for @flowNOTECountsAndTotalNotes.
  ///
  /// In zh, this message translates to:
  /// **'NOTE 数量与总物量'**
  String get flowNOTECountsAndTotalNotes;

  /// No description provided for @flowBREAKCounts.
  ///
  /// In zh, this message translates to:
  /// **'绝赞数量'**
  String get flowBREAKCounts;

  /// No description provided for @flowTotalNotes.
  ///
  /// In zh, this message translates to:
  /// **'总物量'**
  String get flowTotalNotes;

  /// No description provided for @flowOfficialConstant.
  ///
  /// In zh, this message translates to:
  /// **'官方定数'**
  String get flowOfficialConstant;

  /// No description provided for @flowFittedConstant.
  ///
  /// In zh, this message translates to:
  /// **'拟合定数'**
  String get flowFittedConstant;

  /// No description provided for @flowTotal3.
  ///
  /// In zh, this message translates to:
  /// **'总计'**
  String get flowTotal3;

  /// No description provided for @flowRequestingStoragePermission.
  ///
  /// In zh, this message translates to:
  /// **'请求存储权限...'**
  String get flowRequestingStoragePermission;

  /// No description provided for @flowBuildingExportContent.
  ///
  /// In zh, this message translates to:
  /// **'正在构建导出内容...'**
  String get flowBuildingExportContent;

  /// No description provided for @flowPreloadingImages.
  ///
  /// In zh, this message translates to:
  /// **'正在预加载图片...'**
  String get flowPreloadingImages;

  /// No description provided for @flowRenderingExportContent.
  ///
  /// In zh, this message translates to:
  /// **'正在渲染导出内容...'**
  String get flowRenderingExportContent;

  /// No description provided for @flowGeneratingImage.
  ///
  /// In zh, this message translates to:
  /// **'正在生成图片...'**
  String get flowGeneratingImage;

  /// No description provided for @flowSavingImage.
  ///
  /// In zh, this message translates to:
  /// **'正在保存图片...'**
  String get flowSavingImage;

  /// No description provided for @flowExportComplete.
  ///
  /// In zh, this message translates to:
  /// **'导出完成'**
  String get flowExportComplete;

  /// No description provided for @flowBPMRange.
  ///
  /// In zh, this message translates to:
  /// **'BPM 范围'**
  String get flowBPMRange;

  /// No description provided for @flowBaseBPM.
  ///
  /// In zh, this message translates to:
  /// **'基准 BPM'**
  String get flowBaseBPM;

  /// No description provided for @flowSOrLower.
  ///
  /// In zh, this message translates to:
  /// **'S+以下'**
  String get flowSOrLower;

  /// No description provided for @flowNoCombo.
  ///
  /// In zh, this message translates to:
  /// **'无连击'**
  String get flowNoCombo;

  /// No description provided for @flowNoSync.
  ///
  /// In zh, this message translates to:
  /// **'无同步'**
  String get flowNoSync;

  /// No description provided for @flowCouldNotLoadDataP0.
  ///
  /// In zh, this message translates to:
  /// **'加载数据出错: {p0}'**
  String flowCouldNotLoadDataP0(String p0);

  /// No description provided for @flowUncategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get flowUncategorized;

  /// No description provided for @flowNarrowPass50.
  ///
  /// In zh, this message translates to:
  /// **'寸50'**
  String get flowNarrowPass50;

  /// No description provided for @flowJustShort50.
  ///
  /// In zh, this message translates to:
  /// **'名刀50/锁血50'**
  String get flowJustShort50;

  /// No description provided for @flowNarrowSSS50.
  ///
  /// In zh, this message translates to:
  /// **'寸鸟加50'**
  String get flowNarrowSSS50;

  /// No description provided for @flowJustShortOfSSS50.
  ///
  /// In zh, this message translates to:
  /// **'锁血鸟加50'**
  String get flowJustShortOfSSS50;

  /// No description provided for @flowNarrowSSS502.
  ///
  /// In zh, this message translates to:
  /// **'寸鸟50'**
  String get flowNarrowSSS502;

  /// No description provided for @flowJustShortOfSSS502.
  ///
  /// In zh, this message translates to:
  /// **'锁血鸟50'**
  String get flowJustShortOfSSS502;

  /// No description provided for @flowChartDesigner50.
  ///
  /// In zh, this message translates to:
  /// **'谱师50'**
  String get flowChartDesigner50;

  /// No description provided for @flowGenre50.
  ///
  /// In zh, this message translates to:
  /// **'流派50'**
  String get flowGenre50;

  /// No description provided for @flowVersion50.
  ///
  /// In zh, this message translates to:
  /// **'版本50'**
  String get flowVersion50;

  /// No description provided for @flowLevel50.
  ///
  /// In zh, this message translates to:
  /// **'等级50'**
  String get flowLevel50;

  /// No description provided for @flowLevel50P0.
  ///
  /// In zh, this message translates to:
  /// **'等级50 - {p0}'**
  String flowLevel50P0(String p0);

  /// No description provided for @flowCategoryLevel50P0.
  ///
  /// In zh, this message translates to:
  /// **'选择类型: 等级50 - {p0}'**
  String flowCategoryLevel50P0(String p0);

  /// No description provided for @flowStar50.
  ///
  /// In zh, this message translates to:
  /// **'星数50'**
  String get flowStar50;

  /// No description provided for @flowTag50.
  ///
  /// In zh, this message translates to:
  /// **'标签50'**
  String get flowTag50;

  /// No description provided for @flowRandom50.
  ///
  /// In zh, this message translates to:
  /// **'随机50'**
  String get flowRandom50;

  /// No description provided for @flowOverreach50.
  ///
  /// In zh, this message translates to:
  /// **'越级50'**
  String get flowOverreach50;

  /// No description provided for @flowDifficulty50.
  ///
  /// In zh, this message translates to:
  /// **'难度50'**
  String get flowDifficulty50;

  /// No description provided for @flowDan.
  ///
  /// In zh, this message translates to:
  /// **'段位'**
  String get flowDan;

  /// No description provided for @flowTrueDan.
  ///
  /// In zh, this message translates to:
  /// **'真段位'**
  String get flowTrueDan;

  /// No description provided for @flowOverallRanking.
  ///
  /// In zh, this message translates to:
  /// **'总排行榜'**
  String get flowOverallRanking;

  /// No description provided for @flowStarBonus.
  ///
  /// In zh, this message translates to:
  /// **'星+'**
  String get flowStarBonus;

  /// No description provided for @flowToNextStar.
  ///
  /// In zh, this message translates to:
  /// **'高一级星-'**
  String get flowToNextStar;

  /// No description provided for @flowPNGLossless.
  ///
  /// In zh, this message translates to:
  /// **'PNG 无损'**
  String get flowPNGLossless;

  /// No description provided for @flowOriginalQuality.
  ///
  /// In zh, this message translates to:
  /// **'原始画质'**
  String get flowOriginalQuality;

  /// No description provided for @flowClearImageSmallerFile.
  ///
  /// In zh, this message translates to:
  /// **'清晰，体积较小'**
  String get flowClearImageSmallerFile;

  /// No description provided for @flowGoodForSharing.
  ///
  /// In zh, this message translates to:
  /// **'适合发送和分享'**
  String get flowGoodForSharing;

  /// No description provided for @flowSmallestFile.
  ///
  /// In zh, this message translates to:
  /// **'体积最小'**
  String get flowSmallestFile;

  /// No description provided for @detailChartBpm.
  ///
  /// In zh, this message translates to:
  /// **'谱面'**
  String get detailChartBpm;

  /// No description provided for @bestDisplayCover.
  ///
  /// In zh, this message translates to:
  /// **'曲绘'**
  String get bestDisplayCover;

  /// No description provided for @bestDisplayTwoColumns.
  ///
  /// In zh, this message translates to:
  /// **'双列'**
  String get bestDisplayTwoColumns;

  /// No description provided for @bestDisplayOneColumn.
  ///
  /// In zh, this message translates to:
  /// **'单列'**
  String get bestDisplayOneColumn;

  /// No description provided for @rankingServiceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'排行榜服务暂不可用（{code}）'**
  String rankingServiceUnavailable(String code);

  /// No description provided for @rankingInvalidResponse.
  ///
  /// In zh, this message translates to:
  /// **'排行榜响应格式无效'**
  String get rankingInvalidResponse;

  /// No description provided for @ratingFetchFailed.
  ///
  /// In zh, this message translates to:
  /// **'获取评分信息失败'**
  String get ratingFetchFailed;

  /// No description provided for @commentPostHttpFailed.
  ///
  /// In zh, this message translates to:
  /// **'评论创建失败 ({code})'**
  String commentPostHttpFailed(String code);

  /// No description provided for @commentDeleteHttpFailed.
  ///
  /// In zh, this message translates to:
  /// **'评论删除失败 ({code})'**
  String commentDeleteHttpFailed(String code);

  /// No description provided for @unknownDataSource.
  ///
  /// In zh, this message translates to:
  /// **'未知数据源'**
  String get unknownDataSource;

  /// No description provided for @exportBlackTheme.
  ///
  /// In zh, this message translates to:
  /// **'纯黑'**
  String get exportBlackTheme;

  /// No description provided for @songTabHistory.
  ///
  /// In zh, this message translates to:
  /// **'成绩历史'**
  String get songTabHistory;

  /// No description provided for @songTabCommunity.
  ///
  /// In zh, this message translates to:
  /// **'社区'**
  String get songTabCommunity;

  /// No description provided for @flowUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get flowUnknown;

  /// No description provided for @flowChooseDownloadMethod.
  ///
  /// In zh, this message translates to:
  /// **'选择下载方式'**
  String get flowChooseDownloadMethod;

  /// No description provided for @flowDownloadInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'浏览器下载'**
  String get flowDownloadInBrowser;

  /// No description provided for @flowOpenDownloadPage.
  ///
  /// In zh, this message translates to:
  /// **'打开下载网页'**
  String get flowOpenDownloadPage;

  /// No description provided for @flowDownloadInApp.
  ///
  /// In zh, this message translates to:
  /// **'App 内下载'**
  String get flowDownloadInApp;

  /// No description provided for @flowDownloadInTheBackgroundWhileYouKeep.
  ///
  /// In zh, this message translates to:
  /// **'后台下载，不影响当前使用'**
  String get flowDownloadInTheBackgroundWhileYouKeep;

  /// No description provided for @flowChooseDownloadRoute.
  ///
  /// In zh, this message translates to:
  /// **'选择下载线路'**
  String get flowChooseDownloadRoute;

  /// No description provided for @flowCouldNotConnectToTheServerCheck.
  ///
  /// In zh, this message translates to:
  /// **'无法连接到服务器，请检查网络后重试'**
  String get flowCouldNotConnectToTheServerCheck;

  /// No description provided for @flowYouAreUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本'**
  String get flowYouAreUpToDate;

  /// No description provided for @flowCurrentVersionP0BuildP1.
  ///
  /// In zh, this message translates to:
  /// **'当前版本：{p0} (build: {p1})'**
  String flowCurrentVersionP0BuildP1(String p0, String p1);

  /// No description provided for @flowLatestVersionP0BuildP1.
  ///
  /// In zh, this message translates to:
  /// **'最新版本：{p0} (build: {p1})'**
  String flowLatestVersionP0BuildP1(String p0, String p1);

  /// No description provided for @flowLatestChangesP0.
  ///
  /// In zh, this message translates to:
  /// **'最近更新：\n{p0}'**
  String flowLatestChangesP0(String p0);

  /// No description provided for @flowHideFor3Days.
  ///
  /// In zh, this message translates to:
  /// **'3天内不提示'**
  String get flowHideFor3Days;

  /// No description provided for @flowDownloadNow.
  ///
  /// In zh, this message translates to:
  /// **'立即下载'**
  String get flowDownloadNow;

  /// No description provided for @flowCouldNotOpenLinkP0.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接：{p0}'**
  String flowCouldNotOpenLinkP0(String p0);

  /// No description provided for @flowEmailAddressCopied.
  ///
  /// In zh, this message translates to:
  /// **'邮箱已复制到剪贴板'**
  String get flowEmailAddressCopied;

  /// No description provided for @flowCreationAndSupport.
  ///
  /// In zh, this message translates to:
  /// **'创作与支持'**
  String get flowCreationAndSupport;

  /// No description provided for @flowSupporterAcknowledgments.
  ///
  /// In zh, this message translates to:
  /// **'捐献致谢'**
  String get flowSupporterAcknowledgments;

  /// No description provided for @flowDataAndServices.
  ///
  /// In zh, this message translates to:
  /// **'数据与服务'**
  String get flowDataAndServices;

  /// No description provided for @flowDesignInspiration.
  ///
  /// In zh, this message translates to:
  /// **'设计思路借鉴'**
  String get flowDesignInspiration;

  /// No description provided for @flowThankYouForEveryContributionThatHelps.
  ///
  /// In zh, this message translates to:
  /// **'感谢每一份支持，让 ChiffonMai 不断成长。'**
  String get flowThankYouForEveryContributionThatHelps;

  /// No description provided for @flowHereForEveryMaimaiVisit.
  ///
  /// In zh, this message translates to:
  /// **'陪伴每一次舞萌出勤'**
  String get flowHereForEveryMaimaiVisit;

  /// No description provided for @flowReadingVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本读取中…'**
  String get flowReadingVersion;

  /// No description provided for @flowVersionP02.
  ///
  /// In zh, this message translates to:
  /// **'版本 {p0}'**
  String flowVersionP02(String p0);

  /// No description provided for @flowAppRegistrationICP20240152563A.
  ///
  /// In zh, this message translates to:
  /// **'APP备案号：津ICP备2024015256号-3A'**
  String get flowAppRegistrationICP20240152563A;

  /// No description provided for @flowDevelopmentAndMaintenance.
  ///
  /// In zh, this message translates to:
  /// **'开发与维护'**
  String get flowDevelopmentAndMaintenance;

  /// No description provided for @flowInputError.
  ///
  /// In zh, this message translates to:
  /// **'输入错误'**
  String get flowInputError;

  /// No description provided for @flowTargetAchievement.
  ///
  /// In zh, this message translates to:
  /// **'目标达成率'**
  String get flowTargetAchievement;

  /// No description provided for @flowEG1005000.
  ///
  /// In zh, this message translates to:
  /// **'例如 100.5000'**
  String get flowEG1005000;

  /// No description provided for @flowJudgmentDetails.
  ///
  /// In zh, this message translates to:
  /// **'判定详情'**
  String get flowJudgmentDetails;

  /// No description provided for @flowForBREAKEnterTheMainJudgmentCounts.
  ///
  /// In zh, this message translates to:
  /// **'BREAK 只需填大类；50落 / 100落与 GREAT 细分由反推得出'**
  String get flowForBREAKEnterTheMainJudgmentCounts;

  /// No description provided for @flowCalculating2.
  ///
  /// In zh, this message translates to:
  /// **'计算中...'**
  String get flowCalculating2;

  /// No description provided for @flowCalculateBREAKDetails.
  ///
  /// In zh, this message translates to:
  /// **'计算绝赞详情'**
  String get flowCalculateBREAKDetails;

  /// No description provided for @flowSolutionFoundError00001.
  ///
  /// In zh, this message translates to:
  /// **'找到可行解（误差 ≤ 0.0001%）'**
  String get flowSolutionFoundError00001;

  /// No description provided for @flowNoExactSolutionShowingTheClosestResult.
  ///
  /// In zh, this message translates to:
  /// **'没有精确解，下面是最接近的结果'**
  String get flowNoExactSolutionShowingTheClosestResult;

  /// No description provided for @flowTargetP0BaseP1ExtraP2.
  ///
  /// In zh, this message translates to:
  /// **'目标 {p0}% · 基础 {p1}% · 额外 {p2}%'**
  String flowTargetP0BaseP1ExtraP2(String p0, String p1, String p2);

  /// No description provided for @flowTotalAchievementP0P1P2.
  ///
  /// In zh, this message translates to:
  /// **'总达成率 {p0}% · {p1} {p2}%'**
  String flowTotalAchievementP0P1P2(String p0, String p1, String p2);

  /// No description provided for @flowError2.
  ///
  /// In zh, this message translates to:
  /// **'误差'**
  String get flowError2;

  /// No description provided for @flowMinimumError.
  ///
  /// In zh, this message translates to:
  /// **'最小误差'**
  String get flowMinimumError;

  /// No description provided for @flowJudgmentLossPerNote.
  ///
  /// In zh, this message translates to:
  /// **'单个音符的判定损失'**
  String get flowJudgmentLossPerNote;

  /// No description provided for @flowP0BREAKsBaseBonusScoreRatiosBelow.
  ///
  /// In zh, this message translates to:
  /// **'BREAK 共 {p0} 个 · 每行下方是基础分 / 奖励分比例'**
  String flowP0BREAKsBaseBonusScoreRatiosBelow(String p0);

  /// No description provided for @flowP0P1NotesRedValuesShowAchievement.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 共 {p1} 个 · 红字是这一档判定丢掉的达成率'**
  String flowP0P1NotesRedValuesShowAchievement(String p0, String p1);

  /// No description provided for @flowViewPerNoteLoss.
  ///
  /// In zh, this message translates to:
  /// **'查看单音符损失'**
  String get flowViewPerNoteLoss;

  /// No description provided for @flowLiveAchievement.
  ///
  /// In zh, this message translates to:
  /// **'实时达成率'**
  String get flowLiveAchievement;

  /// No description provided for @flowEnterJudgmentCountsBelowToCalculateAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'在下方填写各档判定数量，结果会自动算出来'**
  String get flowEnterJudgmentCountsBelowToCalculateAutomatically;

  /// No description provided for @flowTotalAchievementP0GradeP1.
  ///
  /// In zh, this message translates to:
  /// **'总达成率 {p0}%，评级 {p1}'**
  String flowTotalAchievementP0GradeP1(String p0, String p1);

  /// No description provided for @flowBaseP0BonusP1.
  ///
  /// In zh, this message translates to:
  /// **'基础 {p0}% · 奖励 {p1}%'**
  String flowBaseP0BonusP1(String p0, String p1);

  /// No description provided for @flowAlreadyAtTheHighestGradeSSS.
  ///
  /// In zh, this message translates to:
  /// **'已经是最高评级 SSS+'**
  String get flowAlreadyAtTheHighestGradeSSS;

  /// No description provided for @flowP2NeededForP0P1.
  ///
  /// In zh, this message translates to:
  /// **'距 {p0}（{p1}%）还差 {p2}%'**
  String flowP2NeededForP0P1(String p0, String p1, String p2);

  /// No description provided for @flowAlternatingPlayRestSegmentsLetTheWheel.
  ///
  /// In zh, this message translates to:
  /// **'出勤和不出勤交替排布，让转盘决定今天要不要出勤吧。'**
  String get flowAlternatingPlayRestSegmentsLetTheWheel;

  /// No description provided for @flowSegments.
  ///
  /// In zh, this message translates to:
  /// **'区域数量'**
  String get flowSegments;

  /// No description provided for @flowFewerSegments.
  ///
  /// In zh, this message translates to:
  /// **'减少区域'**
  String get flowFewerSegments;

  /// No description provided for @flowMoreSegments.
  ///
  /// In zh, this message translates to:
  /// **'增加区域'**
  String get flowMoreSegments;

  /// No description provided for @flow20ByDefaultUpTo100Changes.
  ///
  /// In zh, this message translates to:
  /// **'默认 20，最多 100 区；每次增减 2 区，保持交替'**
  String get flow20ByDefaultUpTo100Changes;

  /// No description provided for @flowSpinning.
  ///
  /// In zh, this message translates to:
  /// **'转盘正在旋转…'**
  String get flowSpinning;

  /// No description provided for @flowStartWhenYouAreReady.
  ///
  /// In zh, this message translates to:
  /// **'准备好就开始吧'**
  String get flowStartWhenYouAreReady;

  /// No description provided for @flowThisSpinP0.
  ///
  /// In zh, this message translates to:
  /// **'本次：{p0}'**
  String flowThisSpinP0(String p0);

  /// No description provided for @flowSpin.
  ///
  /// In zh, this message translates to:
  /// **'转一转'**
  String get flowSpin;

  /// No description provided for @flowError3.
  ///
  /// In zh, this message translates to:
  /// **'误差 +'**
  String get flowError3;

  /// No description provided for @flowEG5.
  ///
  /// In zh, this message translates to:
  /// **'如 5'**
  String get flowEG5;

  /// No description provided for @flowNoMatchingResults.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的结果'**
  String get flowNoMatchingResults;

  /// No description provided for @flowBREAKDistributionCalculator.
  ///
  /// In zh, this message translates to:
  /// **'绝赞分布计算'**
  String get flowBREAKDistributionCalculator;

  /// No description provided for @flowTAPGREATAllowance.
  ///
  /// In zh, this message translates to:
  /// **'个 TAP GREAT 的容错'**
  String get flowTAPGREATAllowance;

  /// No description provided for @flowUserData.
  ///
  /// In zh, this message translates to:
  /// **'用户数据'**
  String get flowUserData;

  /// No description provided for @flowP0TAPGREATs.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个 TAP GREAT'**
  String flowP0TAPGREATs(String p0);

  /// No description provided for @flowTodaySRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'今日推荐'**
  String get flowTodaySRecommendations;

  /// No description provided for @flowPreparingTodaySRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'正在准备今日推荐…'**
  String get flowPreparingTodaySRecommendations;

  /// No description provided for @flowAnotherBatch.
  ///
  /// In zh, this message translates to:
  /// **'换一批'**
  String get flowAnotherBatch;

  /// No description provided for @flowPickingTodaySRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'正在为你挑选今日推荐…'**
  String get flowPickingTodaySRecommendations;

  /// No description provided for @flowNoChartsToRecommendYetRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'暂无可推荐的谱面\n请先在首页刷新数据'**
  String get flowNoChartsToRecommendYetRefreshData;

  /// No description provided for @flowBackupsExportFavoritesChartNotesAccountProfiles.
  ///
  /// In zh, this message translates to:
  /// **'备份包含收藏夹、谱面笔记、账号资料、设置、猜歌统计、成绩与 Rating 历史、自定义背景及本地谱面包归档，导出为 JSON 文件。\n\n登录凭据、个人 key 和自动同步身份不会导出，换设备后需重新授权。曲库、maidata、音源、PV 和排行榜等可重新获取的缓存不备份。\n\n兼容旧版备份；旧备份仅能恢复其中原本包含的设置和资料。文件总大小上限为 50 MB。'**
  String get flowBackupsExportFavoritesChartNotesAccountProfiles;

  /// No description provided for @flowExportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份'**
  String get flowExportBackup;

  /// No description provided for @flowExportLocalDataAsAJSONFile.
  ///
  /// In zh, this message translates to:
  /// **'将当前所有本地数据导出为 JSON 文件'**
  String get flowExportLocalDataAsAJSONFile;

  /// No description provided for @flowExportedToP0.
  ///
  /// In zh, this message translates to:
  /// **'已导出到: {p0}'**
  String flowExportedToP0(String p0);

  /// No description provided for @flowImportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导入备份'**
  String get flowImportBackup;

  /// No description provided for @flowRestoreDataFromAJSONBackup.
  ///
  /// In zh, this message translates to:
  /// **'从 JSON 文件恢复之前备份的数据'**
  String get flowRestoreDataFromAJSONBackup;

  /// No description provided for @flowChooseWhereToSaveTheBackup.
  ///
  /// In zh, this message translates to:
  /// **'选择备份保存位置'**
  String get flowChooseWhereToSaveTheBackup;

  /// No description provided for @flowExportCancelled.
  ///
  /// In zh, this message translates to:
  /// **'导出已取消'**
  String get flowExportCancelled;

  /// No description provided for @flowConfirmRestore.
  ///
  /// In zh, this message translates to:
  /// **'确认恢复数据'**
  String get flowConfirmRestore;

  /// No description provided for @flowRestoringOverwritesCurrentLocalSettingsAndProfiles.
  ///
  /// In zh, this message translates to:
  /// **'恢复将覆盖当前本地设置与用户资料。v3 备份还会恢复用户文件；旧版备份只能恢复它原本包含的内容。建议先导出当前备份。'**
  String get flowRestoringOverwritesCurrentLocalSettingsAndProfiles;

  /// No description provided for @flowBackupVersionVP0.
  ///
  /// In zh, this message translates to:
  /// **'备份版本: v{p0}'**
  String flowBackupVersionVP0(String p0);

  /// No description provided for @flowExportedP0.
  ///
  /// In zh, this message translates to:
  /// **'导出时间: {p0}'**
  String flowExportedP0(String p0);

  /// No description provided for @flowContainsP0DataItems.
  ///
  /// In zh, this message translates to:
  /// **'包含 {p0} 个数据项'**
  String flowContainsP0DataItems(String p0);

  /// No description provided for @flowUserFilesP0.
  ///
  /// In zh, this message translates to:
  /// **'用户文件：{p0} 个'**
  String flowUserFilesP0(String p0);

  /// No description provided for @flowExcludedP0CacheItems.
  ///
  /// In zh, this message translates to:
  /// **'已排除 {p0} 个缓存项'**
  String flowExcludedP0CacheItems(String p0);

  /// No description provided for @flowSongMaidataAndLeaderboardCachesAreExcluded.
  ///
  /// In zh, this message translates to:
  /// **'曲库、maidata、排行榜等缓存不参与备份，恢复后按需重新获取，首次加载可能稍慢。登录凭据不会从备份恢复。'**
  String get flowSongMaidataAndLeaderboardCachesAreExcluded;

  /// No description provided for @flowThisCannotBeUndoneContinue.
  ///
  /// In zh, this message translates to:
  /// **'此操作不可撤销，确定要继续吗？'**
  String get flowThisCannotBeUndoneContinue;

  /// No description provided for @flowRestore.
  ///
  /// In zh, this message translates to:
  /// **'确认恢复'**
  String get flowRestore;

  /// No description provided for @flowRestoredP0SettingsAndP1UserFiles.
  ///
  /// In zh, this message translates to:
  /// **'数据恢复成功！共恢复 {p0} 项设置和 {p1} 个用户文件。\n建议重启应用以确保完全生效。'**
  String flowRestoredP0SettingsAndP1UserFiles(String p0, String p1);

  /// No description provided for @flowImportFailedP02.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {p0}'**
  String flowImportFailedP02(String p0);

  /// No description provided for @flowMinimumConstant.
  ///
  /// In zh, this message translates to:
  /// **'最低定数'**
  String get flowMinimumConstant;

  /// No description provided for @flowMaximumConstant.
  ///
  /// In zh, this message translates to:
  /// **'最高定数'**
  String get flowMaximumConstant;

  /// No description provided for @flowNoRecommendationsCheckTheConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'暂无推荐结果，请检查定数区间输入是否正确'**
  String get flowNoRecommendationsCheckTheConstantRange;

  /// No description provided for @flowRenameFavoritesFolder.
  ///
  /// In zh, this message translates to:
  /// **'重命名收藏夹'**
  String get flowRenameFavoritesFolder;

  /// No description provided for @flowEnterANewName.
  ///
  /// In zh, this message translates to:
  /// **'请输入新名称'**
  String get flowEnterANewName;

  /// No description provided for @flowDeleteFavoritesFolder.
  ///
  /// In zh, this message translates to:
  /// **'删除收藏夹'**
  String get flowDeleteFavoritesFolder;

  /// No description provided for @flowDeleteP0ChartsWillRemainButWill.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除收藏夹「{p0}」吗？\n收藏夹内的谱面不会被删除，但将不再分组。'**
  String flowDeleteP0ChartsWillRemainButWill(String p0);

  /// No description provided for @flowDeletedP0.
  ///
  /// In zh, this message translates to:
  /// **'已删除收藏夹「{p0}」'**
  String flowDeletedP0(String p0);

  /// No description provided for @flowImportFavorites.
  ///
  /// In zh, this message translates to:
  /// **'导入收藏夹'**
  String get flowImportFavorites;

  /// No description provided for @flowAddChartsToFavoritesFoldersFromSong.
  ///
  /// In zh, this message translates to:
  /// **'在乐曲详情页中可以将谱面收藏到收藏夹'**
  String get flowAddChartsToFavoritesFoldersFromSong;

  /// No description provided for @flowOrUseImportFavoritesAboveP0.
  ///
  /// In zh, this message translates to:
  /// **'也可以点上方「导入收藏夹」按钮，{p0}'**
  String flowOrUseImportFavoritesAboveP0(String p0);

  /// No description provided for @flowRemoveChart.
  ///
  /// In zh, this message translates to:
  /// **'移除谱面'**
  String get flowRemoveChart;

  /// No description provided for @flowRemoveP1FromP0.
  ///
  /// In zh, this message translates to:
  /// **'确定从「{p0}」中移除「{p1}」吗？'**
  String flowRemoveP1FromP0(String p0, String p1);

  /// No description provided for @flowRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get flowRemove;

  /// No description provided for @flowRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移除'**
  String get flowRemoved;

  /// No description provided for @flowSortOrder.
  ///
  /// In zh, this message translates to:
  /// **'排序方式'**
  String get flowSortOrder;

  /// No description provided for @flowExportFavorites.
  ///
  /// In zh, this message translates to:
  /// **'导出收藏夹'**
  String get flowExportFavorites;

  /// No description provided for @flowFavoritesFolderIsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'收藏夹为空'**
  String get flowFavoritesFolderIsEmpty;

  /// No description provided for @flowRemoveFromFavoritesFolder.
  ///
  /// In zh, this message translates to:
  /// **'从收藏夹移除'**
  String get flowRemoveFromFavoritesFolder;

  /// No description provided for @flowP0Selected.
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 项'**
  String flowP0Selected(String p0);

  /// No description provided for @flowMove.
  ///
  /// In zh, this message translates to:
  /// **'移动'**
  String get flowMove;

  /// No description provided for @flowRemoveMultipleCharts.
  ///
  /// In zh, this message translates to:
  /// **'批量移除谱面'**
  String get flowRemoveMultipleCharts;

  /// No description provided for @flowRemoveP1ChartsFromP0.
  ///
  /// In zh, this message translates to:
  /// **'确定要从「{p0}」中移除 {p1} 个谱面吗？'**
  String flowRemoveP1ChartsFromP0(String p0, String p1);

  /// No description provided for @flowRemovedP0Charts.
  ///
  /// In zh, this message translates to:
  /// **'已移除 {p0} 个谱面'**
  String flowRemovedP0Charts(String p0);

  /// No description provided for @flowNoOtherFoldersToMoveTo.
  ///
  /// In zh, this message translates to:
  /// **'没有其他收藏夹可移动'**
  String get flowNoOtherFoldersToMoveTo;

  /// No description provided for @flowMoveTo.
  ///
  /// In zh, this message translates to:
  /// **'移动到...'**
  String get flowMoveTo;

  /// No description provided for @flowMovedP0Charts.
  ///
  /// In zh, this message translates to:
  /// **'已移动 {p0} 个谱面'**
  String flowMovedP0Charts(String p0);

  /// No description provided for @flowThisFolderIsEmptyThereAreNo.
  ///
  /// In zh, this message translates to:
  /// **'这个收藏夹还是空的，没有可导出的谱面'**
  String get flowThisFolderIsEmptyThereAreNo;

  /// No description provided for @flowChooseWhereToExportFavorites.
  ///
  /// In zh, this message translates to:
  /// **'选择收藏夹导出位置'**
  String get flowChooseWhereToExportFavorites;

  /// No description provided for @flowExportedP02.
  ///
  /// In zh, this message translates to:
  /// **'已导出 {p0}'**
  String flowExportedP02(String p0);

  /// No description provided for @flowImportItInTheAppOrOpen.
  ///
  /// In zh, this message translates to:
  /// **'可以直接在 App 内「导入收藏夹」，或在文件管理器里点开该文件一键导回'**
  String get flowImportItInTheAppOrOpen;

  /// No description provided for @flowFileSavedTo.
  ///
  /// In zh, this message translates to:
  /// **'文件已保存到：'**
  String get flowFileSavedTo;

  /// No description provided for @flowThePublicDirectoryIsNotWritableSaved.
  ///
  /// In zh, this message translates to:
  /// **'公开目录不可写，文件已保存到应用私有目录，可能无法在系统文件管理器中直接找到。'**
  String get flowThePublicDirectoryIsNotWritableSaved;

  /// No description provided for @flowInvalidLink.
  ///
  /// In zh, this message translates to:
  /// **'链接无效'**
  String get flowInvalidLink;

  /// No description provided for @flowCouldNotOpenABrowserLinkCopied3.
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器，链接已复制到剪贴板'**
  String get flowCouldNotOpenABrowserLinkCopied3;

  /// No description provided for @flowRelatedCommunityProjectsTapACardTo.
  ///
  /// In zh, this message translates to:
  /// **'这里收录了同好/同行项目的友情链接，点击卡片即可在浏览器中打开。'**
  String get flowRelatedCommunityProjectsTapACardTo;

  /// No description provided for @flowSkippedP0ForThisSession.
  ///
  /// In zh, this message translates to:
  /// **'已跳过 {p0}（仅本次）'**
  String flowSkippedP0ForThisSession(String p0);

  /// No description provided for @flowCouldNotSaveFeedbackP0.
  ///
  /// In zh, this message translates to:
  /// **'保存反馈失败：{p0}'**
  String flowCouldNotSaveFeedbackP0(String p0);

  /// No description provided for @flowStoppedRecommendingP0UndoInFeedbackManagement.
  ///
  /// In zh, this message translates to:
  /// **'不再推荐 {p0}（可在反馈管理里撤销）'**
  String flowStoppedRecommendingP0UndoInFeedbackManagement(String p0);

  /// No description provided for @flowPausedRecommendationsForP0For14Days.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 暂停推荐 14 天'**
  String flowPausedRecommendationsForP0For14Days(String p0);

  /// No description provided for @flowUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get flowUndo;

  /// No description provided for @flowManageFeedback.
  ///
  /// In zh, this message translates to:
  /// **'反馈管理'**
  String get flowManageFeedback;

  /// No description provided for @flowNoChartsCanDirectlyRaiseYourRating.
  ///
  /// In zh, this message translates to:
  /// **'暂时没有能直接涨 Rating 的谱面。\n刷新成绩后再来看看吧。'**
  String get flowNoChartsCanDirectlyRaiseYourRating;

  /// No description provided for @flowNoUnseenCandidatesMatchStartOverOr.
  ///
  /// In zh, this message translates to:
  /// **'暂无符合条件的未见候选。\n可以重新开始，或在反馈管理里撤销屏蔽。'**
  String get flowNoUnseenCandidatesMatchStartOverOr;

  /// No description provided for @flowTotalGainIfAllTargetsOnThis.
  ///
  /// In zh, this message translates to:
  /// **'本页全部达成的合计（按 B50 逐步重算，已扣除互相顶替）'**
  String get flowTotalGainIfAllTargetsOnThis;

  /// No description provided for @flowBatchP0P1EntriesEachGainIs.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 批 · {p1} 条（每条为独立净收益，不可直接相加）'**
  String flowBatchP0P1EntriesEachGainIs(String p0, String p1);

  /// No description provided for @flowStartOver.
  ///
  /// In zh, this message translates to:
  /// **'重新开始'**
  String get flowStartOver;

  /// No description provided for @flowNoMore.
  ///
  /// In zh, this message translates to:
  /// **'已无更多'**
  String get flowNoMore;

  /// No description provided for @flowCurrentB50.
  ///
  /// In zh, this message translates to:
  /// **'当前 B50'**
  String get flowCurrentB50;

  /// No description provided for @flowB35CutoffP0.
  ///
  /// In zh, this message translates to:
  /// **'B35 · 底线 {p0}'**
  String flowB35CutoffP0(String p0);

  /// No description provided for @flowB15CutoffP0.
  ///
  /// In zh, this message translates to:
  /// **'B15 · 底线 {p0}'**
  String flowB15CutoffP0(String p0);

  /// No description provided for @flowCountedB35P0P1B15P2P3.
  ///
  /// In zh, this message translates to:
  /// **'已计入 B35 {p0}/{p1} · B15 {p2}/{p3}'**
  String flowCountedB35P0P1B15P2P3(String p0, String p1, String p2, String p3);

  /// No description provided for @flowNetGain.
  ///
  /// In zh, this message translates to:
  /// **'净收益'**
  String get flowNetGain;

  /// No description provided for @flowFeedback.
  ///
  /// In zh, this message translates to:
  /// **'反馈'**
  String get flowFeedback;

  /// No description provided for @flowSkipThisTime.
  ///
  /// In zh, this message translates to:
  /// **'这次跳过'**
  String get flowSkipThisTime;

  /// No description provided for @flowTemporarilyStuck14Days.
  ///
  /// In zh, this message translates to:
  /// **'暂时卡住（14 天）'**
  String get flowTemporarilyStuck14Days;

  /// No description provided for @flowDislikeThisChart.
  ///
  /// In zh, this message translates to:
  /// **'不喜欢这张谱'**
  String get flowDislikeThisChart;

  /// No description provided for @flowNoScoreRecordedReferenceTargetP0.
  ///
  /// In zh, this message translates to:
  /// **'未记录成绩 → 参考目标 {p0}%'**
  String flowNoScoreRecordedReferenceTargetP0(String p0);

  /// No description provided for @flowP0P1GainP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}% → {p1}%（提升 {p2}%）'**
  String flowP0P1GainP2(String p0, String p1, String p2);

  /// No description provided for @flowSteadyTargetImprovement020Challenge0.
  ///
  /// In zh, this message translates to:
  /// **'稳妥 = 目标提升 ≤ 0.20%，挑战 = 提升 ≤ 0.80%，探索 = 未记录成绩、按你同定数档的中位成绩估算。「稳妥」指差距小，不是成功率。\n基于本地缓存的成绩计算，刷新数据后结果会更新。'**
  String get flowSteadyTargetImprovement020Challenge0;

  /// No description provided for @flowRatingGainRecommendationsPoweredByAWMC.
  ///
  /// In zh, this message translates to:
  /// **'吃分推荐算法由 AWMC 提供支持'**
  String get flowRatingGainRecommendationsPoweredByAWMC;

  /// No description provided for @flowUndoingDoesNotInsertChartsBackInto.
  ///
  /// In zh, this message translates to:
  /// **'撤销后谱面不会插回当前这一批，换批或重新开始时才会再出现。'**
  String get flowUndoingDoesNotInsertChartsBackInto;

  /// No description provided for @flowNoFeedbackYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有反馈记录'**
  String get flowNoFeedbackYet;

  /// No description provided for @flowDislikedUntilUndone.
  ///
  /// In zh, this message translates to:
  /// **'不喜欢 · 直到撤销'**
  String get flowDislikedUntilUndone;

  /// No description provided for @flowTemporarilyStuckClearsAutomaticallyOnP0.
  ///
  /// In zh, this message translates to:
  /// **'暂时卡住 · {p0} 自动解除'**
  String flowTemporarilyStuckClearsAutomaticallyOnP0(String p0);

  /// No description provided for @flowP0ArcadesTapToExpand.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 家机厅，点击展开'**
  String flowP0ArcadesTapToExpand(String p0);

  /// No description provided for @flowTurnOnDeviceLocationServicesFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先开启设备定位服务'**
  String get flowTurnOnDeviceLocationServicesFirst;

  /// No description provided for @flowLocationPermissionIsPermanentlyDeniedEnableIt.
  ///
  /// In zh, this message translates to:
  /// **'定位权限已被永久拒绝，请在系统设置中开启'**
  String get flowLocationPermissionIsPermanentlyDeniedEnableIt;

  /// No description provided for @flowCouldNotGetYourLocationCheckThat.
  ///
  /// In zh, this message translates to:
  /// **'无法获取当前位置，请确认已开启定位服务且信号良好'**
  String get flowCouldNotGetYourLocationCheckThat;

  /// No description provided for @flowLocationFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'定位失败: {p0}'**
  String flowLocationFailedP0(String p0);

  /// No description provided for @flowFiltered.
  ///
  /// In zh, this message translates to:
  /// **' (筛选)'**
  String get flowFiltered;

  /// No description provided for @flowP0ArcadesInViewNearbyPointsGrouped.
  ///
  /// In zh, this message translates to:
  /// **' 视野内 {p0} 家（邻近点自动合并）'**
  String flowP0ArcadesInViewNearbyPointsGrouped(String p0);

  /// No description provided for @flowLastUpdatedP0.
  ///
  /// In zh, this message translates to:
  /// **'上次更新: {p0}'**
  String flowLastUpdatedP0(String p0);

  /// No description provided for @flowSearchArcadeNameOrAddress.
  ///
  /// In zh, this message translates to:
  /// **'搜索店名或地址'**
  String get flowSearchArcadeNameOrAddress;

  /// No description provided for @flowMachineFilters.
  ///
  /// In zh, this message translates to:
  /// **'机台筛选'**
  String get flowMachineFilters;

  /// No description provided for @flowNoArcadeDataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无店铺数据'**
  String get flowNoArcadeDataYet;

  /// No description provided for @flowMachines.
  ///
  /// In zh, this message translates to:
  /// **'🎮 机台:'**
  String get flowMachines;

  /// No description provided for @flowCouldNotOpenTheLinkTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接，请稍后重试'**
  String get flowCouldNotOpenTheLinkTryAgain;

  /// No description provided for @flowCouldNotLoadDocumentTapToRetry.
  ///
  /// In zh, this message translates to:
  /// **'文档读取失败，点击重试'**
  String get flowCouldNotLoadDocumentTapToRetry;

  /// No description provided for @flowSubmitALoadingQuote.
  ///
  /// In zh, this message translates to:
  /// **'上传语录到云端'**
  String get flowSubmitALoadingQuote;

  /// No description provided for @flowAddALocalQuote.
  ///
  /// In zh, this message translates to:
  /// **'本地新增语录'**
  String get flowAddALocalQuote;

  /// No description provided for @flowUploadFailedTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'上传失败，请稍后重试'**
  String get flowUploadFailedTryAgainLater;

  /// No description provided for @flowSubmittedForReviewP0ShownOnlyAfter.
  ///
  /// In zh, this message translates to:
  /// **'已提交审核（{p0}），审核通过后才会展示'**
  String flowSubmittedForReviewP0ShownOnlyAfter(String p0);

  /// No description provided for @flowLocalQuoteAdded.
  ///
  /// In zh, this message translates to:
  /// **'本地语录添加成功'**
  String get flowLocalQuoteAdded;

  /// No description provided for @flowCouldNotFetchLoadingQuotesKeptThe.
  ///
  /// In zh, this message translates to:
  /// **'获取加载语录失败，已保留本地缓存'**
  String get flowCouldNotFetchLoadingQuotesKeptThe;

  /// No description provided for @flowRefreshQuotes.
  ///
  /// In zh, this message translates to:
  /// **'刷新语录'**
  String get flowRefreshQuotes;

  /// No description provided for @flowP0QuotesEnabled.
  ///
  /// In zh, this message translates to:
  /// **'/ {p0} 条已启用'**
  String flowP0QuotesEnabled(String p0);

  /// No description provided for @flowAddLocally.
  ///
  /// In zh, this message translates to:
  /// **'本地新增'**
  String get flowAddLocally;

  /// No description provided for @flowUploadToCloud.
  ///
  /// In zh, this message translates to:
  /// **'上传到云端'**
  String get flowUploadToCloud;

  /// No description provided for @flowDeleteLocalQuote.
  ///
  /// In zh, this message translates to:
  /// **'删除本地语录'**
  String get flowDeleteLocalQuote;

  /// No description provided for @flowEnterALoadingQuote.
  ///
  /// In zh, this message translates to:
  /// **'输入加载语录'**
  String get flowEnterALoadingQuote;

  /// No description provided for @flowDataFromIsMaiDownByChongxi.
  ///
  /// In zh, this message translates to:
  /// **'数据来源于 isMaiDown by Chongxi'**
  String get flowDataFromIsMaiDownByChongxi;

  /// No description provided for @flowServiceStatus.
  ///
  /// In zh, this message translates to:
  /// **'服务状态'**
  String get flowServiceStatus;

  /// No description provided for @flowReadingServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'正在读取服务器状态…'**
  String get flowReadingServerStatus;

  /// No description provided for @flowUpdatedP02.
  ///
  /// In zh, this message translates to:
  /// **'更新时间：{p0}'**
  String flowUpdatedP02(String p0);

  /// No description provided for @flowDifficultyNotSpecified.
  ///
  /// In zh, this message translates to:
  /// **'未指定难度'**
  String get flowDifficultyNotSpecified;

  /// No description provided for @flowNoteP0.
  ///
  /// In zh, this message translates to:
  /// **'备注：{p0}'**
  String flowNoteP0(String p0);

  /// No description provided for @flowRemoveThisEntry.
  ///
  /// In zh, this message translates to:
  /// **'移除这一次'**
  String get flowRemoveThisEntry;

  /// No description provided for @flowMeetChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'先认识一下 ChiffonMai'**
  String get flowMeetChiffonMai;

  /// No description provided for @flowFiveTabsKeepEverythingWithinReach.
  ///
  /// In zh, this message translates to:
  /// **'五个标签页，想找的东西都在这里。'**
  String get flowFiveTabsKeepEverythingWithinReach;

  /// No description provided for @flowRefreshDataThenStartExploring.
  ///
  /// In zh, this message translates to:
  /// **'先刷新数据，再开始探索'**
  String get flowRefreshDataThenStartExploring;

  /// No description provided for @flowARefreshPreparesSongsConstantsTagsAnd.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据会准备曲库、定数、标签和成绩。\n不登录也可以先逛逛。'**
  String get flowARefreshPreparesSongsConstantsTagsAnd;

  /// No description provided for @flowMakeItFeelLikeYourApp.
  ///
  /// In zh, this message translates to:
  /// **'把体验调成你喜欢的样子'**
  String get flowMakeItFeelLikeYourApp;

  /// No description provided for @flowFindTheseOptionsInMeSettingsAnd.
  ///
  /// In zh, this message translates to:
  /// **'都在「我的」页的设置里，随时可以改。'**
  String get flowFindTheseOptionsInMeSettingsAnd;

  /// No description provided for @flowPhotosAndMedia.
  ///
  /// In zh, this message translates to:
  /// **'相册与媒体'**
  String get flowPhotosAndMedia;

  /// No description provided for @flowChooseCoverArtAndSaveExportedSong.
  ///
  /// In zh, this message translates to:
  /// **'用于选择曲绘、保存导出的歌曲信息和成绩图片。'**
  String get flowChooseCoverArtAndSaveExportedSong;

  /// No description provided for @flowCamera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get flowCamera;

  /// No description provided for @flowCaptureCoverArtOrScoreImagesFor.
  ///
  /// In zh, this message translates to:
  /// **'用于拍摄曲绘或成绩截图进行识别。'**
  String get flowCaptureCoverArtOrScoreImagesFor;

  /// No description provided for @flowLocation.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get flowLocation;

  /// No description provided for @flowUsedForLocationFeaturesOnTheGlobal.
  ///
  /// In zh, this message translates to:
  /// **'用于全球机厅地图中的位置服务。'**
  String get flowUsedForLocationFeaturesOnTheGlobal;

  /// No description provided for @flowNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get flowNotifications;

  /// No description provided for @flowShowPlaybackControlsDuringBackgroundMusicPlayback.
  ///
  /// In zh, this message translates to:
  /// **'用于随身听后台播放时显示通知栏控制。'**
  String get flowShowPlaybackControlsDuringBackgroundMusicPlayback;

  /// No description provided for @flowCouldNotSaveConfirmationPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'确认记录保存失败，请重试'**
  String get flowCouldNotSaveConfirmationPleaseRetry;

  /// No description provided for @flowSeparateGuardianConsent.
  ///
  /// In zh, this message translates to:
  /// **'监护人单独同意'**
  String get flowSeparateGuardianConsent;

  /// No description provided for @flowPleaseHandTheDeviceToAGuardian.
  ///
  /// In zh, this message translates to:
  /// **'请将设备交由监护人操作。监护人应阅读以下文件，了解所处理的信息、用途，以及查询和删除信息的方式。'**
  String get flowPleaseHandTheDeviceToAGuardian;

  /// No description provided for @flowIAmThisUserSGuardianI.
  ///
  /// In zh, this message translates to:
  /// **'我是该用户的监护人，已阅读并同意《用户协议》和《隐私政策》，同意为提供相应功能处理被监护人的必要个人信息。'**
  String get flowIAmThisUserSGuardianI;

  /// No description provided for @flowAfterConsentPermissionsAndFeaturesRemainOptional.
  ///
  /// In zh, this message translates to:
  /// **'同意后，仍可按需选择权限和相关功能；也可按隐私政策说明撤回授权或申请删除信息。'**
  String get flowAfterConsentPermissionsAndFeaturesRemainOptional;

  /// No description provided for @flowGuardianConsent.
  ///
  /// In zh, this message translates to:
  /// **'监护人同意'**
  String get flowGuardianConsent;

  /// No description provided for @flowGoBackOnceMoreToExit.
  ///
  /// In zh, this message translates to:
  /// **'再返回一次退出应用'**
  String get flowGoBackOnceMoreToExit;

  /// No description provided for @flowGettingStartedWithChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 入门'**
  String get flowGettingStartedWithChiffonMai;

  /// No description provided for @flowPrevious3.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get flowPrevious3;

  /// No description provided for @flowStartExploring.
  ///
  /// In zh, this message translates to:
  /// **'开始探索'**
  String get flowStartExploring;

  /// No description provided for @flowNext3.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get flowNext3;

  /// No description provided for @flowWelcomeToChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'欢迎来到 ChiffonMai'**
  String get flowWelcomeToChiffonMai;

  /// No description provided for @flowSongsChartsScoresAndUsefulToolsAll.
  ///
  /// In zh, this message translates to:
  /// **'歌曲、谱面、成绩与实用工具都在这里，\n从查一首歌到推一次分，慢慢来就好。'**
  String get flowSongsChartsScoresAndUsefulToolsAll;

  /// No description provided for @flowAllSet.
  ///
  /// In zh, this message translates to:
  /// **'准备完成！'**
  String get flowAllSet;

  /// No description provided for @flowStartExploringWithASong.
  ///
  /// In zh, this message translates to:
  /// **'接下来，就从一首歌开始探索吧。'**
  String get flowStartExploringWithASong;

  /// No description provided for @flowCouldNotRequestPermissionP0.
  ///
  /// In zh, this message translates to:
  /// **'申请权限失败：{p0}'**
  String flowCouldNotRequestPermissionP0(String p0);

  /// No description provided for @flowAgreementsAndPermissions.
  ///
  /// In zh, this message translates to:
  /// **'协议与权限'**
  String get flowAgreementsAndPermissions;

  /// No description provided for @flowAgreeToTheDocumentsFirstYouCan.
  ///
  /// In zh, this message translates to:
  /// **'先确认协议才能继续。权限可以现在允许，也可以等用到时再说。'**
  String get flowAgreeToTheDocumentsFirstYouCan;

  /// No description provided for @flowTheSystemManagesNetworkAccessBackgroundPlayback.
  ///
  /// In zh, this message translates to:
  /// **'网络、后台播放和安全存储由系统自动管理，不需要在这里单独授权。'**
  String get flowTheSystemManagesNetworkAccessBackgroundPlayback;

  /// No description provided for @flowIHaveReadAndAgreeTo.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意'**
  String get flowIHaveReadAndAgreeTo;

  /// No description provided for @flowUserAgreement.
  ///
  /// In zh, this message translates to:
  /// **'《用户协议》'**
  String get flowUserAgreement;

  /// No description provided for @flowPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'《隐私政策》'**
  String get flowPrivacyPolicy;

  /// No description provided for @flowToProvideTheGameServiceWeProcess.
  ///
  /// In zh, this message translates to:
  /// **'为提供游戏服务，我们会处理你的游玩记录、歌曲成绩、账号及设备标识等必要信息；多人联机对战会实时传输对局通信数据，仅用于维持联机功能。'**
  String get flowToProvideTheGameServiceWeProcess;

  /// No description provided for @flowUsersUnder18ShouldUseTheApp.
  ///
  /// In zh, this message translates to:
  /// **'未满18周岁请在监护人指导下使用。未满14周岁需由监护人单独同意。'**
  String get flowUsersUnder18ShouldUseTheApp;

  /// No description provided for @flowGuardianHasGivenSeparateConsent.
  ///
  /// In zh, this message translates to:
  /// **'监护人已单独同意'**
  String get flowGuardianHasGivenSeparateConsent;

  /// No description provided for @flowUnder14GuardianMustProvideConsent.
  ///
  /// In zh, this message translates to:
  /// **'未满14周岁，由监护人完成同意'**
  String get flowUnder14GuardianMustProvideConsent;

  /// No description provided for @flowP0SelectAllowFullAccessInThe.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 请在系统弹窗中选择“允许完全访问”。'**
  String flowP0SelectAllowFullAccessInThe(String p0);

  /// No description provided for @flowAccessIsCurrentlyLimitedChangeToAllow.
  ///
  /// In zh, this message translates to:
  /// **'当前是有限访问，请在系统设置中改为“允许完全访问”。'**
  String get flowAccessIsCurrentlyLimitedChangeToAllow;

  /// No description provided for @flowNotAuthorizedYetPermissionWillBeRequested.
  ///
  /// In zh, this message translates to:
  /// **'当前未授权，使用相关功能时仍会再次请求。'**
  String get flowNotAuthorizedYetPermissionWillBeRequested;

  /// No description provided for @flowOpenSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get flowOpenSettings;

  /// No description provided for @flowAllow.
  ///
  /// In zh, this message translates to:
  /// **'允许'**
  String get flowAllow;

  /// No description provided for @flowDrawFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'抽取失败：{p0}'**
  String flowDrawFailedP0(String p0);

  /// No description provided for @flowNumberToDraw.
  ///
  /// In zh, this message translates to:
  /// **'抽取数量'**
  String get flowNumberToDraw;

  /// No description provided for @flowPreparing.
  ///
  /// In zh, this message translates to:
  /// **'准备中…'**
  String get flowPreparing;

  /// No description provided for @flowStop.
  ///
  /// In zh, this message translates to:
  /// **'停！'**
  String get flowStop;

  /// No description provided for @flowStartDrawing.
  ///
  /// In zh, this message translates to:
  /// **'开始抽奖'**
  String get flowStartDrawing;

  /// No description provided for @flowDrawResults.
  ///
  /// In zh, this message translates to:
  /// **'抽取结果'**
  String get flowDrawResults;

  /// No description provided for @flowP0SongsDrawn.
  ///
  /// In zh, this message translates to:
  /// **'本次抽取 {p0} 首'**
  String flowP0SongsDrawn(String p0);

  /// No description provided for @flowDrawHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史抽取记录'**
  String get flowDrawHistory;

  /// No description provided for @flowNoHistoryYet2.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史记录'**
  String get flowNoHistoryYet2;

  /// No description provided for @flowRecommendationRange.
  ///
  /// In zh, this message translates to:
  /// **'推荐范围'**
  String get flowRecommendationRange;

  /// No description provided for @flowPrioritizeChartsInRange.
  ///
  /// In zh, this message translates to:
  /// **'范围内谱面优先'**
  String get flowPrioritizeChartsInRange;

  /// No description provided for @flowRecalculateByTargetRating.
  ///
  /// In zh, this message translates to:
  /// **'按目标 Rating 重新计算'**
  String get flowRecalculateByTargetRating;

  /// No description provided for @flowRecalculateByConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'按定数区间重新计算'**
  String get flowRecalculateByConstantRange;

  /// No description provided for @flowCalculatingRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'正在计算推荐结果...'**
  String get flowCalculatingRecommendations;

  /// No description provided for @flowSongConstant.
  ///
  /// In zh, this message translates to:
  /// **'歌曲定数'**
  String get flowSongConstant;

  /// No description provided for @flowSongRating.
  ///
  /// In zh, this message translates to:
  /// **'单曲 Rating'**
  String get flowSongRating;

  /// No description provided for @flowMultiplier.
  ///
  /// In zh, this message translates to:
  /// **'乘数'**
  String get flowMultiplier;

  /// No description provided for @flowEnterConstantAndAchievementToCalculateSong.
  ///
  /// In zh, this message translates to:
  /// **'填好定数和达成率后自动计算 · 单曲 Rating = 定数 × 乘数 × 达成率（取整）'**
  String get flowEnterConstantAndAchievementToCalculateSong;

  /// No description provided for @flowSongRatingConstantMultiplierAchievementRoundedDown.
  ///
  /// In zh, this message translates to:
  /// **'单曲 Rating = 定数 × 乘数 × 达成率（取整）'**
  String get flowSongRatingConstantMultiplierAchievementRoundedDown;

  /// No description provided for @flowEquivalentConstants.
  ///
  /// In zh, this message translates to:
  /// **'等效定数对照'**
  String get flowEquivalentConstants;

  /// No description provided for @flowEquivalentToP0.
  ///
  /// In zh, this message translates to:
  /// **'相当于 {p0}'**
  String flowEquivalentToP0(String p0);

  /// No description provided for @flowMultiplierTable.
  ///
  /// In zh, this message translates to:
  /// **'乘数对照表'**
  String get flowMultiplierTable;

  /// No description provided for @flowUseTheMultiplierWhenAchievementMeetsThe.
  ///
  /// In zh, this message translates to:
  /// **'达成率不低于左列时使用对应乘数；超过 100.5% 按 100.5% 计算'**
  String get flowUseTheMultiplierWhenAchievementMeetsThe;

  /// No description provided for @flowAchievement4.
  ///
  /// In zh, this message translates to:
  /// **'达成率 ≥'**
  String get flowAchievement4;

  /// No description provided for @flowChooseWhereToSaveTheSupportQR.
  ///
  /// In zh, this message translates to:
  /// **'选择赞赏码保存位置'**
  String get flowChooseWhereToSaveTheSupportQR;

  /// No description provided for @flowSupportQRCodeSaved.
  ///
  /// In zh, this message translates to:
  /// **'赞赏码已保存'**
  String get flowSupportQRCodeSaved;

  /// No description provided for @flowThePublicDirectoryIsNotWritableSaved2.
  ///
  /// In zh, this message translates to:
  /// **'公开目录不可写，已保存到应用文档目录。可通过分享或应用文件访问。'**
  String get flowThePublicDirectoryIsNotWritableSaved2;

  /// No description provided for @flowChiffonMaiIsAFreeOpenSourceTool.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 是一款完全免费的开源工具，如果它帮到了你，欢迎支持开发者！'**
  String get flowChiffonMaiIsAFreeOpenSourceTool;

  /// No description provided for @flowWeChatSupportQRCode.
  ///
  /// In zh, this message translates to:
  /// **'微信赞赏码'**
  String get flowWeChatSupportQRCode;

  /// No description provided for @flowDownloadQRImage.
  ///
  /// In zh, this message translates to:
  /// **'下载赞赏码图片'**
  String get flowDownloadQRImage;

  /// No description provided for @flowOrSupportMeOnAfdian.
  ///
  /// In zh, this message translates to:
  /// **'或通过爱发电支持我'**
  String get flowOrSupportMeOnAfdian;

  /// No description provided for @flowOpenAfdian.
  ///
  /// In zh, this message translates to:
  /// **'前往爱发电'**
  String get flowOpenAfdian;

  /// No description provided for @flowYourSupportKeepsDevelopmentAndMaintenanceGoing.
  ///
  /// In zh, this message translates to:
  /// **'你的支持是我持续维护与开发的动力，感谢！❤️'**
  String get flowYourSupportKeepsDevelopmentAndMaintenanceGoing;

  /// No description provided for @flowYouAlreadyGuessedThisSong.
  ///
  /// In zh, this message translates to:
  /// **'已经猜过这首歌了！'**
  String get flowYouAlreadyGuessedThisSong;

  /// No description provided for @flowHowToPlay.
  ///
  /// In zh, this message translates to:
  /// **'规则说明'**
  String get flowHowToPlay;

  /// No description provided for @flowGreenTheAttributeMatchesTheTargetExactly.
  ///
  /// In zh, this message translates to:
  /// **'绿色 - 该属性与你猜的完全一致。'**
  String get flowGreenTheAttributeMatchesTheTargetExactly;

  /// No description provided for @flowOrangeTheAttributeIsCloseToThe.
  ///
  /// In zh, this message translates to:
  /// **'橙色 - 该属性与你猜的\"接近\"：'**
  String get flowOrangeTheAttributeIsCloseToThe;

  /// No description provided for @flowBPMDiffersByNoMoreThan20.
  ///
  /// In zh, this message translates to:
  /// **'BPM 相差在 ±20 范围内；'**
  String get flowBPMDiffersByNoMoreThan20;

  /// No description provided for @flowMASTEROrReMASTERDifficultyDiffersBy.
  ///
  /// In zh, this message translates to:
  /// **'MASTER 难度或 Re:MASTER 难度相差在 ±0.4范围内；'**
  String get flowMASTEROrReMASTERDifficultyDiffersBy;

  /// No description provided for @flowVersionsAreOneGenerationApartEG.
  ///
  /// In zh, this message translates to:
  /// **'版本相差一个世代（例如 maimai ← maimai PLUS → maimai GreeN）。'**
  String get flowVersionsAreOneGenerationApartEG;

  /// No description provided for @flowGrayTheAttributeIsFarFromThe.
  ///
  /// In zh, this message translates to:
  /// **'灰色 - 该属性与你猜的\"差距较大\"。'**
  String get flowGrayTheAttributeIsFarFromThe;

  /// No description provided for @flowArrows.
  ///
  /// In zh, this message translates to:
  /// **'箭头：'**
  String get flowArrows;

  /// No description provided for @flowTargetValueIsHigherThanYourGuess.
  ///
  /// In zh, this message translates to:
  /// **'↑ - 目标值比你猜的更高'**
  String get flowTargetValueIsHigherThanYourGuess;

  /// No description provided for @flowTargetValueIsLowerThanYourGuess.
  ///
  /// In zh, this message translates to:
  /// **'↓ - 目标值比你猜的更低'**
  String get flowTargetValueIsLowerThanYourGuess;

  /// No description provided for @flowDesignInspiration2.
  ///
  /// In zh, this message translates to:
  /// **'设计思路借鉴：'**
  String get flowDesignInspiration2;

  /// No description provided for @flowCouldNotOpenThisLinkLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'无法打开该链接，链接已复制到剪贴板'**
  String get flowCouldNotOpenThisLinkLinkCopied;

  /// No description provided for @flowNoSongsMatchTheseFiltersBroadenYour.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选条件抽不到曲目，请放宽筛选条件'**
  String get flowNoSongsMatchTheseFiltersBroadenYour;

  /// No description provided for @flowGameSettings.
  ///
  /// In zh, this message translates to:
  /// **'游戏设置'**
  String get flowGameSettings;

  /// No description provided for @flowAppliesFromTheNextGame.
  ///
  /// In zh, this message translates to:
  /// **'保存后下局生效'**
  String get flowAppliesFromTheNextGame;

  /// No description provided for @flowSettingsSavedTheyApplyFromTheNext.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存，将在下局游戏生效'**
  String get flowSettingsSavedTheyApplyFromTheNext;

  /// No description provided for @flowLoading5.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get flowLoading5;

  /// No description provided for @flowRules.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get flowRules;

  /// No description provided for @flowSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get flowSettings;

  /// No description provided for @flowNewQuestion.
  ///
  /// In zh, this message translates to:
  /// **'换一题'**
  String get flowNewQuestion;

  /// No description provided for @flowYouGotIt.
  ///
  /// In zh, this message translates to:
  /// **'恭喜你猜对了！'**
  String get flowYouGotIt;

  /// No description provided for @flowThisGameSAnswer.
  ///
  /// In zh, this message translates to:
  /// **'本局答案'**
  String get flowThisGameSAnswer;

  /// No description provided for @flowSearchTitleAliasIDAndMore.
  ///
  /// In zh, this message translates to:
  /// **'搜索歌名、别名、编号等'**
  String get flowSearchTitleAliasIDAndMore;

  /// No description provided for @flowModeSettings.
  ///
  /// In zh, this message translates to:
  /// **'本模式设置'**
  String get flowModeSettings;

  /// No description provided for @flowDestruction.
  ///
  /// In zh, this message translates to:
  /// **'破坏程度'**
  String get flowDestruction;

  /// No description provided for @flowBlur.
  ///
  /// In zh, this message translates to:
  /// **'模糊程度'**
  String get flowBlur;

  /// No description provided for @flowCoverArtIsTurnedIntoAPixel.
  ///
  /// In zh, this message translates to:
  /// **'曲绘按所选破坏程度处理为像素马赛克，请根据色块、配色和轮廓猜出歌名。0% 为原图，数值越高，像素块越大。'**
  String get flowCoverArtIsTurnedIntoAPixel;

  /// No description provided for @flowTheOriginalCoverAppearsAfterACorrect.
  ///
  /// In zh, this message translates to:
  /// **'猜中、放弃或回合结束后会显示原始曲绘。'**
  String get flowTheOriginalCoverAppearsAfterACorrect;

  /// No description provided for @flowDestructionP0.
  ///
  /// In zh, this message translates to:
  /// **'破坏程度 {p0}%'**
  String flowDestructionP0(String p0);

  /// No description provided for @flowARandomSongIsChosenFromYour.
  ///
  /// In zh, this message translates to:
  /// **'从你已缓存谱面的曲库中随机选一首，随机播放一段无声的谱面动画片段。'**
  String get flowARandomSongIsChosenFromYour;

  /// No description provided for @flowWatchNoteDensityPatternsAndReachTo.
  ///
  /// In zh, this message translates to:
  /// **'仔细观察物量密度、键型与出张方式，猜出这是哪首歌。'**
  String get flowWatchNoteDensityPatternsAndReachTo;

  /// No description provided for @flowYouMayReplayTheExcerptUpTo.
  ///
  /// In zh, this message translates to:
  /// **'片段最多可复播 {p0} 次。'**
  String flowYouMayReplayTheExcerptUpTo(String p0);

  /// No description provided for @flowTags2.
  ///
  /// In zh, this message translates to:
  /// **'标签：'**
  String get flowTags2;

  /// No description provided for @flowShowsPatternDifficultyAndEvaluationTagsFor.
  ///
  /// In zh, this message translates to:
  /// **'显示您猜测的曲目的 MASTER 难度的配置、难度和评价标签。'**
  String get flowShowsPatternDifficultyAndEvaluationTagsFor;

  /// No description provided for @flowATagTurnsGreenWhenItMatches.
  ///
  /// In zh, this message translates to:
  /// **'当一个标签与目标曲目的属性一致时，该标签会变为绿色。'**
  String get flowATagTurnsGreenWhenItMatches;

  /// No description provided for @flowSomeSongsMayNotHaveTags.
  ///
  /// In zh, this message translates to:
  /// **'注意，有些曲目可能未添加标签。'**
  String get flowSomeSongsMayNotHaveTags;

  /// No description provided for @flowNoSongsMatchBroadenTheDifficultyPool.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选条件抽不到曲目，请放宽难度池 / 定数范围或筛选条件'**
  String get flowNoSongsMatchBroadenTheDifficultyPool;

  /// No description provided for @flowExcerptLength.
  ///
  /// In zh, this message translates to:
  /// **'片段时长'**
  String get flowExcerptLength;

  /// No description provided for @flowNoChartsAvailableCacheMaidataInThe.
  ///
  /// In zh, this message translates to:
  /// **'没有可用的谱面，请先在谱面库中缓存 maidata'**
  String get flowNoChartsAvailableCacheMaidataInThe;

  /// No description provided for @flowExcerptFinished.
  ///
  /// In zh, this message translates to:
  /// **'片段播放完毕'**
  String get flowExcerptFinished;

  /// No description provided for @flowLoadingAudio2.
  ///
  /// In zh, this message translates to:
  /// **'正在加载音频…'**
  String get flowLoadingAudio2;

  /// No description provided for @flowReplayExcerptAudioUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'复播片段（音频不可用）'**
  String get flowReplayExcerptAudioUnavailable;

  /// No description provided for @flowReplayExcerptWithAudio.
  ///
  /// In zh, this message translates to:
  /// **'复播片段（带音频）'**
  String get flowReplayExcerptWithAudio;

  /// No description provided for @flowReplayExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'复播片段'**
  String get flowReplayExcerpt;

  /// No description provided for @flowPlayExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'播放片段'**
  String get flowPlayExcerpt;

  /// No description provided for @flowReplayP0.
  ///
  /// In zh, this message translates to:
  /// **'复播{p0}'**
  String flowReplayP0(String p0);

  /// No description provided for @flowTheCoverFlashesBrieflyAtTheStart.
  ///
  /// In zh, this message translates to:
  /// **'开局时曲绘会闪现一瞬间（时长可在设置中调整），随后消失。'**
  String get flowTheCoverFlashesBrieflyAtTheStart;

  /// No description provided for @flowRememberTheCoverThenSearchBelowAnd.
  ///
  /// In zh, this message translates to:
  /// **'凭记忆在下方搜索并猜出这首歌曲。'**
  String get flowRememberTheCoverThenSearchBelowAnd;

  /// No description provided for @flowFlashDuration.
  ///
  /// In zh, this message translates to:
  /// **'快闪时长'**
  String get flowFlashDuration;

  /// No description provided for @flowPlaybackLength.
  ///
  /// In zh, this message translates to:
  /// **'播放时长'**
  String get flowPlaybackLength;

  /// No description provided for @flowAudioPlaybackFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'音频播放失败：{p0}'**
  String flowAudioPlaybackFailedP0(String p0);

  /// No description provided for @flowTheCoverIsSplitIntoTilesAt.
  ///
  /// In zh, this message translates to:
  /// **'曲绘被切成若干小块，每隔一段时间会随机揭示其中一批，已揭示的小块会累积保留 —— 拼图会越来越完整。'**
  String get flowTheCoverIsSplitIntoTilesAt;

  /// No description provided for @flowEarlierGuessesImproveYourScoreAverageTime.
  ///
  /// In zh, this message translates to:
  /// **'越早猜中得分越高（计入平均用时），也可以等拼图更完整后再下手。'**
  String get flowEarlierGuessesImproveYourScoreAverageTime;

  /// No description provided for @flowTileCount.
  ///
  /// In zh, this message translates to:
  /// **'切块数量'**
  String get flowTileCount;

  /// No description provided for @flowRevealInterval.
  ///
  /// In zh, this message translates to:
  /// **'揭示间隔'**
  String get flowRevealInterval;

  /// No description provided for @flowP0RevealedP1P2Tiles.
  ///
  /// In zh, this message translates to:
  /// **'已显示 {p0}%（{p1} / {p2} 块）'**
  String flowP0RevealedP1P2Tiles(String p0, String p1, String p2);

  /// No description provided for @flowRevealPaused.
  ///
  /// In zh, this message translates to:
  /// **'揭示已暂停'**
  String get flowRevealPaused;

  /// No description provided for @flowNextRevealInP0S.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 秒后揭示下一批'**
  String flowNextRevealInP0S(String p0);

  /// No description provided for @flowResumeReveal.
  ///
  /// In zh, this message translates to:
  /// **'继续揭示'**
  String get flowResumeReveal;

  /// No description provided for @flowPauseReveal.
  ///
  /// In zh, this message translates to:
  /// **'暂停揭示'**
  String get flowPauseReveal;

  /// No description provided for @flowCouldNotReloadSongsCheckYourConnection.
  ///
  /// In zh, this message translates to:
  /// **'重新拉取曲库失败，请检查网络后重试'**
  String get flowCouldNotReloadSongsCheckYourConnection;

  /// No description provided for @flowFetchingSongs.
  ///
  /// In zh, this message translates to:
  /// **'正在拉取曲库...'**
  String get flowFetchingSongs;

  /// No description provided for @flowReloadSongs.
  ///
  /// In zh, this message translates to:
  /// **'重新拉取曲库'**
  String get flowReloadSongs;

  /// No description provided for @flowOpenSettings2.
  ///
  /// In zh, this message translates to:
  /// **'打开设置'**
  String get flowOpenSettings2;

  /// No description provided for @flowSettingsSavedLocally.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存到本地'**
  String get flowSettingsSavedLocally;

  /// No description provided for @flowChangesSaveAutomaticallyAndApplyToThe.
  ///
  /// In zh, this message translates to:
  /// **'修改会自动保存，下一局生效。'**
  String get flowChangesSaveAutomaticallyAndApplyToThe;

  /// No description provided for @flowSongExcerptsReverseAndSpeedPitch.
  ///
  /// In zh, this message translates to:
  /// **'歌曲片段、倒放与变速变调'**
  String get flowSongExcerptsReverseAndSpeedPitch;

  /// No description provided for @flowChartExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'谱面片段'**
  String get flowChartExcerpt;

  /// No description provided for @flowCoverModes.
  ///
  /// In zh, this message translates to:
  /// **'曲绘玩法'**
  String get flowCoverModes;

  /// No description provided for @flow0ShowsTheOriginalHigherValuesCreate.
  ///
  /// In zh, this message translates to:
  /// **'破坏程度为 0% 时显示原图，数值越高，像素块越大。'**
  String get flow0ShowsTheOriginalHigherValuesCreate;

  /// No description provided for @flowRevealLetters.
  ///
  /// In zh, this message translates to:
  /// **'开字母'**
  String get flowRevealLetters;

  /// No description provided for @flowDefaultSettingsRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢复默认设置'**
  String get flowDefaultSettingsRestored;

  /// No description provided for @flowEnterOneCharacter.
  ///
  /// In zh, this message translates to:
  /// **'请输入一个字符！'**
  String get flowEnterOneCharacter;

  /// No description provided for @flowEnterASongTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入歌曲名称！'**
  String get flowEnterASongTitle;

  /// No description provided for @flowCorrect.
  ///
  /// In zh, this message translates to:
  /// **'猜对了！'**
  String get flowCorrect;

  /// No description provided for @flowGuessP0.
  ///
  /// In zh, this message translates to:
  /// **'猜测 #{p0}'**
  String flowGuessP0(String p0);

  /// No description provided for @flow1TheGameRandomlySelectsP0Songs.
  ///
  /// In zh, this message translates to:
  /// **'1. 游戏开始时，系统会随机从舞萌曲库中抽取{p0}首歌曲。'**
  String flow1TheGameRandomlySelectsP0Songs(String p0);

  /// No description provided for @flow2SendXWhereXIsOne.
  ///
  /// In zh, this message translates to:
  /// **'2. 玩家可以发送 \"开字母 X\"（X 为任意汉字、日文、数字或符号，只能输入一个字符）。'**
  String get flow2SendXWhereXIsOne;

  /// No description provided for @flow3IfATitleContainsThatCharacter.
  ///
  /// In zh, this message translates to:
  /// **'3. 若某首歌曲名包含该字，则揭示该字在歌名中的位置。'**
  String get flow3IfATitleContainsThatCharacter;

  /// No description provided for @flow4IfNoTitleContainsItNo.
  ///
  /// In zh, this message translates to:
  /// **'4. 若不包含，则无提示。'**
  String get flow4IfNoTitleContainsItNo;

  /// No description provided for @flow5UseTheRevealedCharactersToInfer.
  ///
  /// In zh, this message translates to:
  /// **'5. 玩家根据揭示的文字碎片，推理完整曲名，发送 \"回答 曲名/别名\" 作答。'**
  String get flow5UseTheRevealedCharactersToInfer;

  /// No description provided for @flow6GuessEverySongOrSurrenderTo.
  ///
  /// In zh, this message translates to:
  /// **'6. 猜中所有歌曲或点击投降结束游戏，会公布游戏结果。'**
  String get flow6GuessEverySongOrSurrenderTo;

  /// No description provided for @flowSongsPerGame.
  ///
  /// In zh, this message translates to:
  /// **'每次抽取歌曲数'**
  String get flowSongsPerGame;

  /// No description provided for @flowNonEnglishCharacterFilterPercentage.
  ///
  /// In zh, this message translates to:
  /// **'非英文字符过滤百分比'**
  String get flowNonEnglishCharacterFilterPercentage;

  /// No description provided for @flowEnterOneCharacter2.
  ///
  /// In zh, this message translates to:
  /// **'输入一个字符'**
  String get flowEnterOneCharacter2;

  /// No description provided for @flowSurrender.
  ///
  /// In zh, this message translates to:
  /// **'投降'**
  String get flowSurrender;

  /// No description provided for @flowNewGame.
  ///
  /// In zh, this message translates to:
  /// **'新游戏'**
  String get flowNewGame;

  /// No description provided for @flowGuessHistory.
  ///
  /// In zh, this message translates to:
  /// **'猜测历史'**
  String get flowGuessHistory;

  /// No description provided for @flowBlueGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'蓝色之门详情'**
  String get flowBlueGateDetails;

  /// No description provided for @flowWhiteGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'白门详情'**
  String get flowWhiteGateDetails;

  /// No description provided for @flowPurpleGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'紫色之门详情'**
  String get flowPurpleGateDetails;

  /// No description provided for @flowBlackGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'黑色之门详情'**
  String get flowBlackGateDetails;

  /// No description provided for @flowYellowGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'黄色之门详情'**
  String get flowYellowGateDetails;

  /// No description provided for @flowRedGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'红色之门详情'**
  String get flowRedGateDetails;

  /// No description provided for @flowPrismTowerDetails.
  ///
  /// In zh, this message translates to:
  /// **'棱镜塔详情'**
  String get flowPrismTowerDetails;

  /// No description provided for @flowGlitchGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'乱码之门详情'**
  String get flowGlitchGateDetails;

  /// No description provided for @flowHopeGateDetails.
  ///
  /// In zh, this message translates to:
  /// **'希望之门详情'**
  String get flowHopeGateDetails;

  /// No description provided for @flowFinalPhaseDetails.
  ///
  /// In zh, this message translates to:
  /// **'最终相详情'**
  String get flowFinalPhaseDetails;

  /// No description provided for @flowNoActiveChallengesCheckTheScheduleBelow.
  ///
  /// In zh, this message translates to:
  /// **'暂无进行中的挑战，可以看看下方的时间安排'**
  String get flowNoActiveChallengesCheckTheScheduleBelow;

  /// No description provided for @flowCurrentPhase.
  ///
  /// In zh, this message translates to:
  /// **'当前阶段'**
  String get flowCurrentPhase;

  /// No description provided for @flowLIFEPhase1Phase2.
  ///
  /// In zh, this message translates to:
  /// **'LIFE 一阶段 / 二阶段'**
  String get flowLIFEPhase1Phase2;

  /// No description provided for @flowInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get flowInProgress;

  /// No description provided for @flowPhase1P0.
  ///
  /// In zh, this message translates to:
  /// **'一阶段 {p0}'**
  String flowPhase1P0(String p0);

  /// No description provided for @flowPhase2P0.
  ///
  /// In zh, this message translates to:
  /// **'二阶段 {p0}'**
  String flowPhase2P0(String p0);

  /// No description provided for @flowMarkedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'已标记 {p0} / {p1}'**
  String flowMarkedP0P1(String p0, String p1);

  /// No description provided for @flowTapASongToToggleCompletion.
  ///
  /// In zh, this message translates to:
  /// **'点击歌曲可切换完成状态'**
  String get flowTapASongToToggleCompletion;

  /// No description provided for @flowEnableMarkingThenTapSongsToRecord.
  ///
  /// In zh, this message translates to:
  /// **'开启标记后点歌曲记录完成情况'**
  String get flowEnableMarkingThenTapSongsToRecord;

  /// No description provided for @flowMarkingMode.
  ///
  /// In zh, this message translates to:
  /// **'标记模式'**
  String get flowMarkingMode;

  /// No description provided for @flowCouldNotLoadTheGuideTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'攻略加载失败，请稍后重试'**
  String get flowCouldNotLoadTheGuideTryAgain;

  /// No description provided for @flowSongIDP02.
  ///
  /// In zh, this message translates to:
  /// **'歌曲 ID {p0}'**
  String flowSongIDP02(String p0);

  /// No description provided for @flowRefreshTheLibraryToShowSongInformation.
  ///
  /// In zh, this message translates to:
  /// **'刷新曲库后显示歌曲信息'**
  String get flowRefreshTheLibraryToShowSongInformation;

  /// No description provided for @flowRefreshGateList.
  ///
  /// In zh, this message translates to:
  /// **'刷新门列表'**
  String get flowRefreshGateList;

  /// No description provided for @flowEnterYourLXNSPersonalAPIKey.
  ///
  /// In zh, this message translates to:
  /// **'请输入落雪个人 API 密钥'**
  String get flowEnterYourLXNSPersonalAPIKey;

  /// No description provided for @flowLXNSAPIKeySaved.
  ///
  /// In zh, this message translates to:
  /// **'落雪 API 密钥已保存'**
  String get flowLXNSAPIKeySaved;

  /// No description provided for @flowSavedLocallyItWillBeLinkedTo.
  ///
  /// In zh, this message translates to:
  /// **'已本地保存，同步时将自动绑定到云端'**
  String get flowSavedLocallyItWillBeLinkedTo;

  /// No description provided for @flowSetYourLXNSPersonalAPIKeyFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先设置落雪个人 API 密钥'**
  String get flowSetYourLXNSPersonalAPIKeyFirst;

  /// No description provided for @flowHowDoIGetIt.
  ///
  /// In zh, this message translates to:
  /// **'如何获取？'**
  String get flowHowDoIGetIt;

  /// No description provided for @flowThenScrollToTheBottomToFind.
  ///
  /// In zh, this message translates to:
  /// **'，滑到页面最底部即可找到个人 API 密钥。'**
  String get flowThenScrollToTheBottomToFind;

  /// No description provided for @flowLXNSAPIKeyIsSet.
  ///
  /// In zh, this message translates to:
  /// **'落雪 API 密钥已设置'**
  String get flowLXNSAPIKeyIsSet;

  /// No description provided for @flowClosesAutomaticallyInP0S.
  ///
  /// In zh, this message translates to:
  /// **'{p0}s 后自动关闭'**
  String flowClosesAutomaticallyInP0S(String p0);

  /// No description provided for @flowP0GotItP1Points.
  ///
  /// In zh, this message translates to:
  /// **'🎉 {p0} 答对了! +{p1}分'**
  String flowP0GotItP1Points(String p0, String p1);

  /// No description provided for @flowNoConfirmationReceivedCheckYourConnectionAnd.
  ///
  /// In zh, this message translates to:
  /// **'操作未收到确认，请检查连接后重试'**
  String get flowNoConfirmationReceivedCheckYourConnectionAnd;

  /// No description provided for @flowTimingStartsWhenTheRoundBeginsNot.
  ///
  /// In zh, this message translates to:
  /// **'注意：计时是从「回合开始」算的，不是从「猜中上一首」算的。所以后面几首天然比第一首慢 —— 不是你的错觉。'**
  String get flowTimingStartsWhenTheRoundBeginsNot;

  /// No description provided for @flowConfirmLeaving.
  ///
  /// In zh, this message translates to:
  /// **'确认离开'**
  String get flowConfirmLeaving;

  /// No description provided for @flowLeaveThisRoom.
  ///
  /// In zh, this message translates to:
  /// **'是否离开当前房间？'**
  String get flowLeaveThisRoom;

  /// No description provided for @flowLeave.
  ///
  /// In zh, this message translates to:
  /// **'离开'**
  String get flowLeave;

  /// No description provided for @flowNoConfirmationOfLeavingReceivedPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'退出房间未收到确认，请重试'**
  String get flowNoConfirmationOfLeavingReceivedPleaseRetry;

  /// No description provided for @flowCouldNotLeaveRoomP0.
  ///
  /// In zh, this message translates to:
  /// **'退出房间失败：{p0}'**
  String flowCouldNotLeaveRoomP0(String p0);

  /// No description provided for @flowRestoringGame.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复对局…'**
  String get flowRestoringGame;

  /// No description provided for @flowWaitingForTheGameToStart.
  ///
  /// In zh, this message translates to:
  /// **'等待游戏开始...'**
  String get flowWaitingForTheGameToStart;

  /// No description provided for @flowGameOver.
  ///
  /// In zh, this message translates to:
  /// **'游戏结束!'**
  String get flowGameOver;

  /// No description provided for @flowPlayAgain.
  ///
  /// In zh, this message translates to:
  /// **'再来一局'**
  String get flowPlayAgain;

  /// No description provided for @flowRoundOver.
  ///
  /// In zh, this message translates to:
  /// **'回合结束!'**
  String get flowRoundOver;

  /// No description provided for @flowNextRound2.
  ///
  /// In zh, this message translates to:
  /// **'下一轮'**
  String get flowNextRound2;

  /// No description provided for @flowYouSurrenderedWaitingForOtherPlayers.
  ///
  /// In zh, this message translates to:
  /// **'已投降，请等待其他玩家……'**
  String get flowYouSurrenderedWaitingForOtherPlayers;

  /// No description provided for @flowTimeRemainingP0S.
  ///
  /// In zh, this message translates to:
  /// **'⏱️ 剩余时间: {p0} 秒'**
  String flowTimeRemainingP0S(String p0);

  /// No description provided for @flowWaitingForServerConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'正在等待服务端确认…'**
  String get flowWaitingForServerConfirmation;

  /// No description provided for @flowTimeIsUpWaitingForRoundResults.
  ///
  /// In zh, this message translates to:
  /// **'时间到，正在等待回合结算…'**
  String get flowTimeIsUpWaitingForRoundResults;

  /// No description provided for @flowSearchSongIDBPMChartDesignerAnd.
  ///
  /// In zh, this message translates to:
  /// **'搜索歌曲、ID、BPM、谱师等'**
  String get flowSearchSongIDBPMChartDesignerAnd;

  /// No description provided for @flowTimeLeft.
  ///
  /// In zh, this message translates to:
  /// **'剩余时间'**
  String get flowTimeLeft;

  /// No description provided for @flowGuessesLeft.
  ///
  /// In zh, this message translates to:
  /// **'剩余次数'**
  String get flowGuessesLeft;

  /// No description provided for @flowP0Points.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 分'**
  String flowP0Points(String p0);

  /// No description provided for @flowThisSongHasP0Aliases.
  ///
  /// In zh, this message translates to:
  /// **'该歌曲共有 {p0} 个别名'**
  String flowThisSongHasP0Aliases(String p0);

  /// No description provided for @flowNoAliasesAvailableGuessFromTheSong.
  ///
  /// In zh, this message translates to:
  /// **'暂无别名数据，请根据歌曲信息猜歌'**
  String get flowNoAliasesAvailableGuessFromTheSong;

  /// No description provided for @flowThisRoundHasEnded.
  ///
  /// In zh, this message translates to:
  /// **'本回合已结束'**
  String get flowThisRoundHasEnded;

  /// No description provided for @flowP0P1SongsRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {p0} / {p1} 首'**
  String flowP0P1SongsRemaining(String p0, String p1);

  /// No description provided for @flowRevealed.
  ///
  /// In zh, this message translates to:
  /// **'已开:'**
  String get flowRevealed;

  /// No description provided for @flowCharacters.
  ///
  /// In zh, this message translates to:
  /// **'字'**
  String get flowCharacters;

  /// No description provided for @flowPreparingCoverClue.
  ///
  /// In zh, this message translates to:
  /// **'正在准备曲绘线索…'**
  String get flowPreparingCoverClue;

  /// No description provided for @flowWaitingForPlayersToLoadTheCover.
  ///
  /// In zh, this message translates to:
  /// **'等待玩家加载曲绘…'**
  String get flowWaitingForPlayersToLoadTheCover;

  /// No description provided for @flowFlashingRememberIt.
  ///
  /// In zh, this message translates to:
  /// **'快闪中……记住它！'**
  String get flowFlashingRememberIt;

  /// No description provided for @flowTheCoverIsHiddenGuessFromMemory.
  ///
  /// In zh, this message translates to:
  /// **'曲绘已消失，凭记忆猜歌名'**
  String get flowTheCoverIsHiddenGuessFromMemory;

  /// No description provided for @flowP0P1TilesRevealedP2.
  ///
  /// In zh, this message translates to:
  /// **'已揭示 {p0} / {p1} 块{p2}'**
  String flowP0P1TilesRevealedP2(String p0, String p1, String p2);

  /// No description provided for @flowPaused2.
  ///
  /// In zh, this message translates to:
  /// **'（已暂停）'**
  String get flowPaused2;

  /// No description provided for @flowPreparingChartExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'正在准备谱面片段…'**
  String get flowPreparingChartExcerpt;

  /// No description provided for @flowNoReplaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'复播次数已用完'**
  String get flowNoReplaysLeft;

  /// No description provided for @flowGuessTheSongFromThisCoverFragment.
  ///
  /// In zh, this message translates to:
  /// **'根据截取的曲绘部分猜歌名'**
  String get flowGuessTheSongFromThisCoverFragment;

  /// No description provided for @flowOriginalCover.
  ///
  /// In zh, this message translates to:
  /// **'原始曲绘'**
  String get flowOriginalCover;

  /// No description provided for @flowBlurP0.
  ///
  /// In zh, this message translates to:
  /// **'模糊程度: {p0}%'**
  String flowBlurP0(String p0);

  /// No description provided for @flowSongExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'歌曲片段'**
  String get flowSongExcerpt;

  /// No description provided for @flowTheGameHasEnded.
  ///
  /// In zh, this message translates to:
  /// **'游戏已结束'**
  String get flowTheGameHasEnded;

  /// No description provided for @flowReplay.
  ///
  /// In zh, this message translates to:
  /// **'重新播放'**
  String get flowReplay;

  /// No description provided for @flowPlaySongExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'播放歌曲片段'**
  String get flowPlaySongExcerpt;

  /// No description provided for @flowMultiplayerRoom.
  ///
  /// In zh, this message translates to:
  /// **'多人房间'**
  String get flowMultiplayerRoom;

  /// No description provided for @flowP0RoundP1P2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 第 {p1}/{p2} 轮'**
  String flowP0RoundP1P2(String p0, String p1, String p2);

  /// No description provided for @flowReconnect.
  ///
  /// In zh, this message translates to:
  /// **'重新连接'**
  String get flowReconnect;

  /// No description provided for @flowCouldNotCreateRoomP0.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败：{p0}'**
  String flowCouldNotCreateRoomP0(String p0);

  /// No description provided for @flowCouldNotJoinRoomP0.
  ///
  /// In zh, this message translates to:
  /// **'加入房间失败：{p0}'**
  String flowCouldNotJoinRoomP0(String p0);

  /// No description provided for @flowYouAreStillInRoomP0.
  ///
  /// In zh, this message translates to:
  /// **'你还在房间 {p0} 里'**
  String flowYouAreStillInRoomP0(String p0);

  /// No description provided for @flowP0P1PlayersTapToReturn.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · {p1} 人 · 点击返回'**
  String flowP0P1PlayersTapToReturn(String p0, String p1);

  /// No description provided for @flowCreateRoom.
  ///
  /// In zh, this message translates to:
  /// **'创建房间'**
  String get flowCreateRoom;

  /// No description provided for @flowChooseAModeAndRulesThenInvite.
  ///
  /// In zh, this message translates to:
  /// **'选择玩法和规则，邀请好友一起猜歌'**
  String get flowChooseAModeAndRulesThenInvite;

  /// No description provided for @flowJoinRoom.
  ///
  /// In zh, this message translates to:
  /// **'加入房间'**
  String get flowJoinRoom;

  /// No description provided for @flowEnterARoomCodeSharedByA.
  ///
  /// In zh, this message translates to:
  /// **'输入好友分享的房间码'**
  String get flowEnterARoomCodeSharedByA;

  /// No description provided for @flowCouldNotCreateRoom.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败'**
  String get flowCouldNotCreateRoom;

  /// No description provided for @flowCouldNotCreateRoomP02.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败: {p0}'**
  String flowCouldNotCreateRoomP02(String p0);

  /// No description provided for @flow0ShowsTheOriginalHigherValuesCreate2.
  ///
  /// In zh, this message translates to:
  /// **'0% 为原图，数值越高，像素块越大。房间内所有玩家使用相同破坏程度。'**
  String get flow0ShowsTheOriginalHigherValuesCreate2;

  /// No description provided for @flowSpeedPitchMultiplier.
  ///
  /// In zh, this message translates to:
  /// **'变速变调倍率'**
  String get flowSpeedPitchMultiplier;

  /// No description provided for @flowRestoreDefaults.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认设置'**
  String get flowRestoreDefaults;

  /// No description provided for @flowGameMode.
  ///
  /// In zh, this message translates to:
  /// **'游戏模式'**
  String get flowGameMode;

  /// No description provided for @flowMaximumPlayers.
  ///
  /// In zh, this message translates to:
  /// **'最大玩家数'**
  String get flowMaximumPlayers;

  /// No description provided for @flowP0Settings.
  ///
  /// In zh, this message translates to:
  /// **'{p0}设置'**
  String flowP0Settings(String p0);

  /// No description provided for @flowEnterRoomCode.
  ///
  /// In zh, this message translates to:
  /// **'输入房间码'**
  String get flowEnterRoomCode;

  /// No description provided for @flowEnterA6DigitCodeOrThe.
  ///
  /// In zh, this message translates to:
  /// **'输入 6 位房间码，也支持完整房间 ID'**
  String get flowEnterA6DigitCodeOrThe;

  /// No description provided for @flowPasteRoomCode.
  ///
  /// In zh, this message translates to:
  /// **'粘贴房间码'**
  String get flowPasteRoomCode;

  /// No description provided for @flowHowDoIGetARoomCode.
  ///
  /// In zh, this message translates to:
  /// **'如何获取房间码？'**
  String get flowHowDoIGetARoomCode;

  /// No description provided for @flowUpdateDownloadedInstallWhenConvenient.
  ///
  /// In zh, this message translates to:
  /// **'更新已下载，可在方便时安装'**
  String get flowUpdateDownloadedInstallWhenConvenient;

  /// No description provided for @flowViewInstallation.
  ///
  /// In zh, this message translates to:
  /// **'查看安装'**
  String get flowViewInstallation;

  /// No description provided for @flowView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get flowView;

  /// No description provided for @flowPreparingTheUpdateInTheBackgroundYou.
  ///
  /// In zh, this message translates to:
  /// **'正在后台准备更新，可以继续使用 App'**
  String get flowPreparingTheUpdateInTheBackgroundYou;

  /// No description provided for @flowExportingP0InTheBackgroundYouCan.
  ///
  /// In zh, this message translates to:
  /// **'正在后台导出{p0}，可以继续其它操作'**
  String flowExportingP0InTheBackgroundYouCan(String p0);

  /// No description provided for @flowCouldNotExportP0PleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'{p0}导出失败，请重试'**
  String flowCouldNotExportP0PleaseRetry(String p0);

  /// No description provided for @flowCouldNotExportP0CheckStoragePermission.
  ///
  /// In zh, this message translates to:
  /// **'{p0}导出失败，请检查存储权限后重试'**
  String flowCouldNotExportP0CheckStoragePermission(String p0);

  /// No description provided for @flowP0Exported.
  ///
  /// In zh, this message translates to:
  /// **'{p0}导出成功'**
  String flowP0Exported(String p0);

  /// No description provided for @flowCouldNotExportP0P1.
  ///
  /// In zh, this message translates to:
  /// **'{p0}导出失败：{p1}'**
  String flowCouldNotExportP0P1(String p0, String p1);

  /// No description provided for @flowCouldNotLoadAppearanceReopenThisPage.
  ///
  /// In zh, this message translates to:
  /// **'装扮未能读取，请重新打开此页'**
  String get flowCouldNotLoadAppearanceReopenThisPage;

  /// No description provided for @flowChiffonMaiClosedUnexpectedlyLastTime.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 上次异常退出'**
  String get flowChiffonMaiClosedUnexpectedlyLastTime;

  /// No description provided for @flowReasonP0AutomaticLogExportFailedExport.
  ///
  /// In zh, this message translates to:
  /// **'原因：{p0}。\n日志自动导出失败，可以在「我的 → 打印日志」手动导出。'**
  String flowReasonP0AutomaticLogExportFailedExport(String p0);

  /// No description provided for @flowChiffonChuAnAllInOneCHUNITHMTool.
  ///
  /// In zh, this message translates to:
  /// **'这是ChiffonChu，一站式中二工具'**
  String get flowChiffonChuAnAllInOneCHUNITHMTool;

  /// No description provided for @flowWebMiniGamesFromTheAWMCCommunity.
  ///
  /// In zh, this message translates to:
  /// **'来自AWMC社区出品的网页小游戏，持续迭代中！'**
  String get flowWebMiniGamesFromTheAWMCCommunity;

  /// No description provided for @flowAnInnovativeRhythmGameInspiredByRailways.
  ///
  /// In zh, this message translates to:
  /// **'融合铁路元素的创新音游'**
  String get flowAnInnovativeRhythmGameInspiredByRailways;

  /// No description provided for @flowAnOfflineMaimaiLibraryWithQuickCover.
  ///
  /// In zh, this message translates to:
  /// **'一个通过封面快速查询的离线本地maimai曲库'**
  String get flowAnOfflineMaimaiLibraryWithQuickCover;

  /// No description provided for @flowRefusedRequestToANonGatewayAddress.
  ///
  /// In zh, this message translates to:
  /// **'拒绝请求非网关地址: {p0}'**
  String flowRefusedRequestToANonGatewayAddress(String p0);

  /// No description provided for @flowUnsupportedMethodP0.
  ///
  /// In zh, this message translates to:
  /// **'不支持的方法: {p0}'**
  String flowUnsupportedMethodP0(String p0);

  /// No description provided for @flowRequestTimedOutP0S.
  ///
  /// In zh, this message translates to:
  /// **'请求超时（{p0}s）'**
  String flowRequestTimedOutP0S(String p0);

  /// No description provided for @flowCouldNotScheduleWriteP0.
  ///
  /// In zh, this message translates to:
  /// **'写入调度失败: {p0}'**
  String flowCouldNotScheduleWriteP0(String p0);

  /// No description provided for @flowMusicListMustContain14EntriesCurrently.
  ///
  /// In zh, this message translates to:
  /// **'musicList 长度必须为 1–4（当前 {p0}）'**
  String flowMusicListMustContain14EntriesCurrently(String p0);

  /// No description provided for @flowOnlyChargeId235IsSupported.
  ///
  /// In zh, this message translates to:
  /// **'仅支持 chargeId = 2 / 3 / 5（2 倍 / 3 倍 / 5 倍票）'**
  String get flowOnlyChargeId235IsSupported;

  /// No description provided for @flowOrderP0.
  ///
  /// In zh, this message translates to:
  /// **'排序：{p0}'**
  String flowOrderP0(String p0);

  /// No description provided for @flowSourceP0ExportedP1GeneratedByChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'数据源：{p0}\n导出时间：{p1}\nGenerated by ChiffonMai\n交流群：{p2}'**
  String flowSourceP0ExportedP1GeneratedByChiffonMai(
      String p0, String p1, String p2);

  /// No description provided for @flowCouldNotCreateRoomEnvironmentIDIs.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败: 环境ID未设置'**
  String get flowCouldNotCreateRoomEnvironmentIDIs;

  /// No description provided for @flowCouldNotCreateRoomNotSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败: 用户未登录'**
  String get flowCouldNotCreateRoomNotSignedIn;

  /// No description provided for @flowCouldNotJoinRoomP02.
  ///
  /// In zh, this message translates to:
  /// **'加入房间失败: {p0}'**
  String flowCouldNotJoinRoomP02(String p0);

  /// No description provided for @flowCouldNotRejoinRoomP0.
  ///
  /// In zh, this message translates to:
  /// **'重新加入房间失败: {p0}'**
  String flowCouldNotRejoinRoomP0(String p0);

  /// No description provided for @flowCouldNotChangeReadyStatusP0.
  ///
  /// In zh, this message translates to:
  /// **'设置准备状态失败: {p0}'**
  String flowCouldNotChangeReadyStatusP0(String p0);

  /// No description provided for @flowCouldNotChangeSurrenderStatusP0.
  ///
  /// In zh, this message translates to:
  /// **'设置投降状态失败: {p0}'**
  String flowCouldNotChangeSurrenderStatusP0(String p0);

  /// No description provided for @flowCouldNotStartGameP0.
  ///
  /// In zh, this message translates to:
  /// **'开始游戏失败: {p0}'**
  String flowCouldNotStartGameP0(String p0);

  /// No description provided for @flowCouldNotStartNextRoundP0.
  ///
  /// In zh, this message translates to:
  /// **'开始下一回合失败: {p0}'**
  String flowCouldNotStartNextRoundP0(String p0);

  /// No description provided for @flowCouldNotSubmitGuessP0.
  ///
  /// In zh, this message translates to:
  /// **'提交猜测失败: {p0}'**
  String flowCouldNotSubmitGuessP0(String p0);

  /// No description provided for @flowCouldNotRevealLetterP0.
  ///
  /// In zh, this message translates to:
  /// **'开字母失败: {p0}'**
  String flowCouldNotRevealLetterP0(String p0);

  /// No description provided for @flowCouldNotSurrenderP0.
  ///
  /// In zh, this message translates to:
  /// **'投降失败: {p0}'**
  String flowCouldNotSurrenderP0(String p0);

  /// No description provided for @flowCouldNotUploadSongsP0.
  ///
  /// In zh, this message translates to:
  /// **'上传歌曲失败: {p0}'**
  String flowCouldNotUploadSongsP0(String p0);

  /// No description provided for @flowCouldNotGetSongCountP0.
  ///
  /// In zh, this message translates to:
  /// **'获取歌曲数量失败: {p0}'**
  String flowCouldNotGetSongCountP0(String p0);

  /// No description provided for @flowCouldNotParseMessageP0.
  ///
  /// In zh, this message translates to:
  /// **'消息解析失败: {p0}'**
  String flowCouldNotParseMessageP0(String p0);

  /// No description provided for @flowYellow.
  ///
  /// In zh, this message translates to:
  /// **'黄'**
  String get flowYellow;

  /// No description provided for @flowCurrentSaveLocation.
  ///
  /// In zh, this message translates to:
  /// **'当前保存位置'**
  String get flowCurrentSaveLocation;

  /// No description provided for @flowUseTheDefaultPublicDirectoryOrChoose.
  ///
  /// In zh, this message translates to:
  /// **'可以使用应用默认公开目录，或选择一个自定义文件夹。'**
  String get flowUseTheDefaultPublicDirectoryOrChoose;

  /// No description provided for @flowCouldNotChooseSaveFolderP0.
  ///
  /// In zh, this message translates to:
  /// **'选择保存目录失败：{p0}'**
  String flowCouldNotChooseSaveFolderP0(String p0);

  /// No description provided for @flowChooseAnotherFolder.
  ///
  /// In zh, this message translates to:
  /// **'选择其他目录'**
  String get flowChooseAnotherFolder;

  /// No description provided for @flowUseDefaultPath.
  ///
  /// In zh, this message translates to:
  /// **'使用默认路径'**
  String get flowUseDefaultPath;

  /// No description provided for @flowThisFolderIsNotWritableChooseAnother.
  ///
  /// In zh, this message translates to:
  /// **'这个目录不可写，请换一个文件夹。'**
  String get flowThisFolderIsNotWritableChooseAnother;

  /// No description provided for @flowCannotImport.
  ///
  /// In zh, this message translates to:
  /// **'无法导入'**
  String get flowCannotImport;

  /// No description provided for @flowImportCompleteP0.
  ///
  /// In zh, this message translates to:
  /// **'导入完成：{p0}'**
  String flowImportCompleteP0(String p0);

  /// No description provided for @flowP0FoldersP1Charts.
  ///
  /// In zh, this message translates to:
  /// **'共 {p0} 个收藏夹、{p1} 个谱面'**
  String flowP0FoldersP1Charts(String p0, String p1);

  /// No description provided for @flowP0P1Charts2.
  ///
  /// In zh, this message translates to:
  /// **'· {p0}（{p1} 个谱面）'**
  String flowP0P1Charts2(String p0, String p1);

  /// No description provided for @flowP0MoreFolders.
  ///
  /// In zh, this message translates to:
  /// **'· 其余 {p0} 个收藏夹…'**
  String flowP0MoreFolders(String p0);

  /// No description provided for @flowMergeWithExistingFolders.
  ///
  /// In zh, this message translates to:
  /// **'合并到现有收藏夹'**
  String get flowMergeWithExistingFolders;

  /// No description provided for @flowFoldersWithTheSameNameAreMerged.
  ///
  /// In zh, this message translates to:
  /// **'同名收藏夹会合并，重复谱面自动跳过'**
  String get flowFoldersWithTheSameNameAreMerged;

  /// No description provided for @flowReplaceExistingFavorites.
  ///
  /// In zh, this message translates to:
  /// **'覆盖导入'**
  String get flowReplaceExistingFavorites;

  /// No description provided for @flowClearAllCurrentFoldersThenImportThe.
  ///
  /// In zh, this message translates to:
  /// **'先清空当前所有收藏夹，再导入文件内容'**
  String get flowClearAllCurrentFoldersThenImportThe;

  /// No description provided for @flowImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get flowImport;

  /// No description provided for @flowP0Loading.
  ///
  /// In zh, this message translates to:
  /// **'{p0}，加载中'**
  String flowP0Loading(String p0);

  /// No description provided for @flowUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂不可用'**
  String get flowUnavailable;

  /// No description provided for @flowIncrease.
  ///
  /// In zh, this message translates to:
  /// **'，增加'**
  String get flowIncrease;

  /// No description provided for @flowDecrease.
  ///
  /// In zh, this message translates to:
  /// **'，减少'**
  String get flowDecrease;

  /// No description provided for @flowP0P1P2BeijingTime.
  ///
  /// In zh, this message translates to:
  /// **'{p0}-{p1}-{p2} · 北京时间'**
  String flowP0P1P2BeijingTime(String p0, String p1, String p2);

  /// No description provided for @flowDoNotShowThisAnnouncementAgain.
  ///
  /// In zh, this message translates to:
  /// **'不再提示本条公告'**
  String get flowDoNotShowThisAnnouncementAgain;

  /// No description provided for @flowCouldNotLoadImageTapToRetry.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败，点击重试'**
  String get flowCouldNotLoadImageTapToRetry;

  /// No description provided for @flowEnlargeAnnouncementImage.
  ///
  /// In zh, this message translates to:
  /// **'放大公告图片'**
  String get flowEnlargeAnnouncementImage;

  /// No description provided for @flowDecreaseP0ByOne.
  ///
  /// In zh, this message translates to:
  /// **'{p0}减一'**
  String flowDecreaseP0ByOne(String p0);

  /// No description provided for @flowIncreaseP0ByOne.
  ///
  /// In zh, this message translates to:
  /// **'{p0}加一'**
  String flowIncreaseP0ByOne(String p0);

  /// No description provided for @flowInstallUpdate.
  ///
  /// In zh, this message translates to:
  /// **'安装更新'**
  String get flowInstallUpdate;

  /// No description provided for @flowDownloadUpdateInBackground.
  ///
  /// In zh, this message translates to:
  /// **'后台下载更新'**
  String get flowDownloadUpdateInBackground;

  /// No description provided for @flowNoDownloadTask.
  ///
  /// In zh, this message translates to:
  /// **'暂无下载任务'**
  String get flowNoDownloadTask;

  /// No description provided for @flowKeepUsingTheApp.
  ///
  /// In zh, this message translates to:
  /// **'继续使用 App'**
  String get flowKeepUsingTheApp;

  /// No description provided for @flowCancelInstallationTask.
  ///
  /// In zh, this message translates to:
  /// **'取消安装任务'**
  String get flowCancelInstallationTask;

  /// No description provided for @flowCancelDownload.
  ///
  /// In zh, this message translates to:
  /// **'取消下载'**
  String get flowCancelDownload;

  /// No description provided for @flowDownloadAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新下载'**
  String get flowDownloadAgain;

  /// No description provided for @flowAllowInstallation.
  ///
  /// In zh, this message translates to:
  /// **'允许安装'**
  String get flowAllowInstallation;

  /// No description provided for @flowInstallNow.
  ///
  /// In zh, this message translates to:
  /// **'立即安装'**
  String get flowInstallNow;

  /// No description provided for @flowCalculatingCacheSize.
  ///
  /// In zh, this message translates to:
  /// **'正在统计缓存占用…'**
  String get flowCalculatingCacheSize;

  /// No description provided for @flowTotalUsageP0.
  ///
  /// In zh, this message translates to:
  /// **'总占用 {p0}'**
  String flowTotalUsageP0(String p0);

  /// No description provided for @flowAudioCache.
  ///
  /// In zh, this message translates to:
  /// **'音源缓存'**
  String get flowAudioCache;

  /// No description provided for @flowCalculating3.
  ///
  /// In zh, this message translates to:
  /// **'统计中…'**
  String get flowCalculating3;

  /// No description provided for @flowP0FilesTotalP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个文件\n共计 {p1}'**
  String flowP0FilesTotalP1(String p0, String p1);

  /// No description provided for @flowPVCache.
  ///
  /// In zh, this message translates to:
  /// **'PV缓存'**
  String get flowPVCache;

  /// No description provided for @flowMaidataCache.
  ///
  /// In zh, this message translates to:
  /// **'maidata缓存'**
  String get flowMaidataCache;

  /// No description provided for @flowReloadBaseMaidata.
  ///
  /// In zh, this message translates to:
  /// **'重新拉取基础量maidata'**
  String get flowReloadBaseMaidata;

  /// No description provided for @flowCleaningP0.
  ///
  /// In zh, this message translates to:
  /// **'正在清理… {p0}%'**
  String flowCleaningP0(String p0);

  /// No description provided for @flowCleaning.
  ///
  /// In zh, this message translates to:
  /// **'清理中…'**
  String get flowCleaning;

  /// No description provided for @flowClear2.
  ///
  /// In zh, this message translates to:
  /// **'清理'**
  String get flowClear2;

  /// No description provided for @flowNoteSpeedP0P1.
  ///
  /// In zh, this message translates to:
  /// **'流速 {p0} · {p1}'**
  String flowNoteSpeedP0P1(String p0, String p1);

  /// No description provided for @flowNoteSpeed.
  ///
  /// In zh, this message translates to:
  /// **'流速'**
  String get flowNoteSpeed;

  /// No description provided for @flowMirror.
  ///
  /// In zh, this message translates to:
  /// **'镜像'**
  String get flowMirror;

  /// No description provided for @flowRandomDifficultyPool.
  ///
  /// In zh, this message translates to:
  /// **'难度随机池'**
  String get flowRandomDifficultyPool;

  /// No description provided for @flowP0ConstantP12.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 定数 {p1}'**
  String flowP0ConstantP12(String p0, String p1);

  /// No description provided for @flowUTAGE2.
  ///
  /// In zh, this message translates to:
  /// **'宴会'**
  String get flowUTAGE2;

  /// No description provided for @flowResetTodaySStatistics.
  ///
  /// In zh, this message translates to:
  /// **'重置今日统计？'**
  String get flowResetTodaySStatistics;

  /// No description provided for @flowClearTodaySCorrectIncorrectGuessesTimes.
  ///
  /// In zh, this message translates to:
  /// **'将清空当前玩法今日的正确、错误、用时和连胜记录。'**
  String get flowClearTodaySCorrectIncorrectGuessesTimes;

  /// No description provided for @flowP0SRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {p0} 秒'**
  String flowP0SRemaining(String p0);

  /// No description provided for @flowResetTodaySStatistics2.
  ///
  /// In zh, this message translates to:
  /// **'重置今日统计'**
  String get flowResetTodaySStatistics2;

  /// No description provided for @flowResetStatistics.
  ///
  /// In zh, this message translates to:
  /// **'重置统计'**
  String get flowResetStatistics;

  /// No description provided for @flowThisGameHasEnded.
  ///
  /// In zh, this message translates to:
  /// **'本局已结束'**
  String get flowThisGameHasEnded;

  /// No description provided for @flowAnswerP0.
  ///
  /// In zh, this message translates to:
  /// **'正确答案：{p0}'**
  String flowAnswerP0(String p0);

  /// No description provided for @flowOriginalAudioExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'原声片段'**
  String get flowOriginalAudioExcerpt;

  /// No description provided for @flowPreparingOriginalAudio.
  ///
  /// In zh, this message translates to:
  /// **'正在准备原声…'**
  String get flowPreparingOriginalAudio;

  /// No description provided for @flowTheSameExcerptPlayedForwardAtOriginal.
  ///
  /// In zh, this message translates to:
  /// **'本轮同一段音源，按原速正向播放'**
  String get flowTheSameExcerptPlayedForwardAtOriginal;

  /// No description provided for @flowSelectAll2.
  ///
  /// In zh, this message translates to:
  /// **'选择全部'**
  String get flowSelectAll2;

  /// No description provided for @flowCurrentAll.
  ///
  /// In zh, this message translates to:
  /// **'当前：全部'**
  String get flowCurrentAll;

  /// No description provided for @flowP0SelectedNoneMeansAll.
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 项，不选表示全部'**
  String flowP0SelectedNoneMeansAll(String p0);

  /// No description provided for @flowMASTERTags.
  ///
  /// In zh, this message translates to:
  /// **'MASTER标签'**
  String get flowMASTERTags;

  /// No description provided for @flowGuessHistoryP0.
  ///
  /// In zh, this message translates to:
  /// **'猜测历史 ({p0})'**
  String flowGuessHistoryP0(String p0);

  /// No description provided for @flowOldestFirst.
  ///
  /// In zh, this message translates to:
  /// **'从早到晚'**
  String get flowOldestFirst;

  /// No description provided for @flowNewestFirst.
  ///
  /// In zh, this message translates to:
  /// **'从晚到早'**
  String get flowNewestFirst;

  /// No description provided for @flowCouldNotOpenTheGuideSourceLink.
  ///
  /// In zh, this message translates to:
  /// **'无法打开攻略来源，链接已复制到剪贴板'**
  String get flowCouldNotOpenTheGuideSourceLink;

  /// No description provided for @flowDataSourceAWMCKALEIDXSCOPE.
  ///
  /// In zh, this message translates to:
  /// **'数据来源：AWMC KALEIDXSCOPE'**
  String get flowDataSourceAWMCKALEIDXSCOPE;

  /// No description provided for @flowRoom.
  ///
  /// In zh, this message translates to:
  /// **'房间 '**
  String get flowRoom;

  /// No description provided for @flowP0PlayersP1.
  ///
  /// In zh, this message translates to:
  /// **' · {p0} 人 · {p1}'**
  String flowP0PlayersP1(String p0, String p1);

  /// No description provided for @flowCopyRoomCode.
  ///
  /// In zh, this message translates to:
  /// **'复制房间码'**
  String get flowCopyRoomCode;

  /// No description provided for @flowRoomCodeCopied.
  ///
  /// In zh, this message translates to:
  /// **'房间码已复制'**
  String get flowRoomCodeCopied;

  /// No description provided for @flowInviteFriendsToGuessSongsTogether.
  ///
  /// In zh, this message translates to:
  /// **'邀请好友，一起猜歌'**
  String get flowInviteFriendsToGuessSongsTogether;

  /// No description provided for @flowRoomCode.
  ///
  /// In zh, this message translates to:
  /// **'房间码'**
  String get flowRoomCode;

  /// No description provided for @flowRoomCodeCopiedSendItToA.
  ///
  /// In zh, this message translates to:
  /// **'房间码已复制，发送给好友即可加入'**
  String get flowRoomCodeCopiedSendItToA;

  /// No description provided for @flowPlayerSlots.
  ///
  /// In zh, this message translates to:
  /// **'玩家席位'**
  String get flowPlayerSlots;

  /// No description provided for @flowP0P1PlayersP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0} / {p1} 人{p2}'**
  String flowP0P1PlayersP2(String p0, String p1, String p2);

  /// No description provided for @flowP0Ready.
  ///
  /// In zh, this message translates to:
  /// **' · {p0} 人准备'**
  String flowP0Ready(String p0);

  /// No description provided for @flowWaitingForPlayers.
  ///
  /// In zh, this message translates to:
  /// **'等待加入'**
  String get flowWaitingForPlayers;

  /// No description provided for @flowMe2.
  ///
  /// In zh, this message translates to:
  /// **' · 我'**
  String get flowMe2;

  /// No description provided for @flowNotReady.
  ///
  /// In zh, this message translates to:
  /// **'取消准备'**
  String get flowNotReady;

  /// No description provided for @flowReady.
  ///
  /// In zh, this message translates to:
  /// **'准备就绪'**
  String get flowReady;

  /// No description provided for @flowStartGame.
  ///
  /// In zh, this message translates to:
  /// **'开始游戏'**
  String get flowStartGame;

  /// No description provided for @flowDecreaseCount2.
  ///
  /// In zh, this message translates to:
  /// **'减少数量'**
  String get flowDecreaseCount2;

  /// No description provided for @flowIncreaseCount2.
  ///
  /// In zh, this message translates to:
  /// **'增加数量'**
  String get flowIncreaseCount2;

  /// No description provided for @flowConnectionRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢复网络连接'**
  String get flowConnectionRestored;

  /// No description provided for @flowOfflineShowingCachedData.
  ///
  /// In zh, this message translates to:
  /// **'当前离线 - 显示缓存数据'**
  String get flowOfflineShowingCachedData;

  /// No description provided for @flowDrawingP0SongsTapStopToReveal.
  ///
  /// In zh, this message translates to:
  /// **'正在抽取 {p0} 首 · 点击“停！”揭晓'**
  String flowDrawingP0SongsTapStopToReveal(String p0);

  /// No description provided for @flowCardP0WaitingToReveal.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 张卡片，等待揭晓'**
  String flowCardP0WaitingToReveal(String p0);

  /// No description provided for @flowCyclingCoverArt.
  ///
  /// In zh, this message translates to:
  /// **'曲绘轮播中…'**
  String get flowCyclingCoverArt;

  /// No description provided for @flowSongP0WaitingForYouToStop.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 首 · 等待你按停'**
  String flowSongP0WaitingForYouToStop(String p0);

  /// No description provided for @flowChiffonMaiIsAnAllInOneMobile.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 是一款专为 舞萌DX 2026（maimai DX 2026）玩家打造的一站式移动端工具类应用，聚合了曲库查询、成绩统计、Rating 计算、曲目推荐等多种实用功能，助力玩家提升游玩体验。'**
  String get flowChiffonMaiIsAnAllInOneMobile;

  /// No description provided for @flowProvidedTheBackgroundArtworkAndTheLovely.
  ///
  /// In zh, this message translates to:
  /// **'为本项目提供的背景图和戚风小狐狸（真的非常可爱）'**
  String get flowProvidedTheBackgroundArtworkAndTheLovely;

  /// No description provided for @flowContributedValuableIdeasForPersonalizedChartRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'为本项目的个性化谱面推荐功能提供宝贵设计思路'**
  String get flowContributedValuableIdeasForPersonalizedChartRecommendations;

  /// No description provided for @flowContributedValuableFeedbackOnPageDesign.
  ///
  /// In zh, this message translates to:
  /// **'为本项目的页面设计提供了宝贵意见'**
  String get flowContributedValuableFeedbackOnPageDesign;

  /// No description provided for @flowProvidedPersonalPlayDataForDevelopmentAnd.
  ///
  /// In zh, this message translates to:
  /// **'提供了用于测试开发的个人游玩数据'**
  String get flowProvidedPersonalPlayDataForDevelopmentAnd;

  /// No description provided for @flowProposedChiffonMaiAndHelpedSparkTheProject.
  ///
  /// In zh, this message translates to:
  /// **'提议开发 ChiffonMai，为本项目诞生提供最初契机'**
  String get flowProposedChiffonMaiAndHelpedSparkTheProject;

  /// No description provided for @flowContributedManySuggestionsOnInterfaceDetailsAnd.
  ///
  /// In zh, this message translates to:
  /// **'为本项目在前端细节与交互体验上提供了诸多宝贵建议'**
  String get flowContributedManySuggestionsOnInterfaceDetailsAnd;

  /// No description provided for @flowProvidedTechnicalAndFinancialSupportThatGreatly.
  ///
  /// In zh, this message translates to:
  /// **'为本项目的开发提供了技术支持和经济支持，为项目的推进提供了极大的帮助'**
  String get flowProvidedTechnicalAndFinancialSupportThatGreatly;

  /// No description provided for @flowEveryoneInTheChiffonMaiCommunityGroup.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai交流群的全体群友'**
  String get flowEveryoneInTheChiffonMaiCommunityGroup;

  /// No description provided for @flowContributedManySuggestionsAndFeedbackDuringDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'为本项目开发提供了诸多宝贵建议和反馈'**
  String get flowContributedManySuggestionsAndFeedbackDuringDevelopment;

  /// No description provided for @flowDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'水鱼查分器'**
  String get flowDivingFish;

  /// No description provided for @flowProvidesSongAndPlayerScoreDatabases.
  ///
  /// In zh, this message translates to:
  /// **'提供曲目数据库和玩家游玩记录数据库'**
  String get flowProvidesSongAndPlayerScoreDatabases;

  /// No description provided for @flowProvidesChartTagAndAliasDatabases.
  ///
  /// In zh, this message translates to:
  /// **'提供谱面标签数据库和别名数据库'**
  String get flowProvidesChartTagAndAliasDatabases;

  /// No description provided for @flowProvidesAnAliasDatabase.
  ///
  /// In zh, this message translates to:
  /// **'提供别名数据库'**
  String get flowProvidesAnAliasDatabase;

  /// No description provided for @flowLXNS.
  ///
  /// In zh, this message translates to:
  /// **'落雪咖啡屋'**
  String get flowLXNS;

  /// No description provided for @flowProvidesCollectiblesAudioSongAndPlayerScore.
  ///
  /// In zh, this message translates to:
  /// **'提供收藏品数据库、歌曲音源支持、曲目数据库和玩家游玩记录数据库'**
  String get flowProvidesCollectiblesAudioSongAndPlayerScore;

  /// No description provided for @flowProvidesChartConversionSupport.
  ///
  /// In zh, this message translates to:
  /// **'提供谱面转换支持'**
  String get flowProvidesChartConversionSupport;

  /// No description provided for @flowProvidesMaimaiServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'提供舞萌服务器状态信息'**
  String get flowProvidesMaimaiServerStatus;

  /// No description provided for @flowProvidesDivingFishLXNSSyncAndFinancial.
  ///
  /// In zh, this message translates to:
  /// **'提供水鱼查分器同步支持、落雪查分器同步支持和对本项目开发的经济支持'**
  String get flowProvidesDivingFishLXNSSyncAndFinancial;

  /// No description provided for @flowProvidesScoreSyncToDivingFishAnd.
  ///
  /// In zh, this message translates to:
  /// **'提供水鱼查分器和落雪查分器成绩同步支持'**
  String get flowProvidesScoreSyncToDivingFishAnd;

  /// No description provided for @flowProvidesScoreSyncToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'提供落雪查分器成绩同步支持'**
  String get flowProvidesScoreSyncToLXNS;

  /// No description provided for @flowProvidesASongDatabase.
  ///
  /// In zh, this message translates to:
  /// **'提供曲目数据库'**
  String get flowProvidesASongDatabase;

  /// No description provided for @flowProvidesWorldwideArcadeData.
  ///
  /// In zh, this message translates to:
  /// **'提供全球机厅相关数据'**
  String get flowProvidesWorldwideArcadeData;

  /// No description provided for @flowProvidesHighResolutionVersionArtwork.
  ///
  /// In zh, this message translates to:
  /// **'提供高清版本图片'**
  String get flowProvidesHighResolutionVersionArtwork;

  /// No description provided for @flowThankYouForYourDonations.
  ///
  /// In zh, this message translates to:
  /// **'感谢对本项目的捐献支持'**
  String get flowThankYouForYourDonations;

  /// No description provided for @flowMaintainer.
  ///
  /// In zh, this message translates to:
  /// **'维护者'**
  String get flowMaintainer;

  /// No description provided for @flowTheDeveloperBehindChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 背后的开发者。'**
  String get flowTheDeveloperBehindChiffonMai;

  /// No description provided for @flowSpecialThanks.
  ///
  /// In zh, this message translates to:
  /// **'特别致谢'**
  String get flowSpecialThanks;

  /// No description provided for @flowThanksToEveryoneWhoHelpedInNo.
  ///
  /// In zh, this message translates to:
  /// **'感谢每一位给予帮助的伙伴，排名不分先后。'**
  String get flowThanksToEveryoneWhoHelpedInNo;

  /// No description provided for @flowBilibili.
  ///
  /// In zh, this message translates to:
  /// **'B 站'**
  String get flowBilibili;

  /// No description provided for @flowEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get flowEmail;

  /// No description provided for @flowSignInFailedTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请稍后再试'**
  String get flowSignInFailedTryAgainLater;

  /// No description provided for @flowEnterTargetAchievement.
  ///
  /// In zh, this message translates to:
  /// **'请输入目标达成率'**
  String get flowEnterTargetAchievement;

  /// No description provided for @flowInvalidAchievementEnterANumberSuchAs.
  ///
  /// In zh, this message translates to:
  /// **'达成率格式错误，请输入有效的数字（如100.5000）'**
  String get flowInvalidAchievementEnterANumberSuchAs;

  /// No description provided for @flowEnterAchievementBetween0And101.
  ///
  /// In zh, this message translates to:
  /// **'达成率请输入0~101之间的数值'**
  String get flowEnterAchievementBetween0And101;

  /// No description provided for @flow50PointLoss2.
  ///
  /// In zh, this message translates to:
  /// **'50落'**
  String get flow50PointLoss2;

  /// No description provided for @flow100PointLoss2.
  ///
  /// In zh, this message translates to:
  /// **'100落'**
  String get flow100PointLoss2;

  /// No description provided for @flowBase100Bonus100.
  ///
  /// In zh, this message translates to:
  /// **'基础 100% · 奖励 100%'**
  String get flowBase100Bonus100;

  /// No description provided for @flowPERFECT50PointLoss.
  ///
  /// In zh, this message translates to:
  /// **'PERFECT · 50落'**
  String get flowPERFECT50PointLoss;

  /// No description provided for @flowBase100Bonus75.
  ///
  /// In zh, this message translates to:
  /// **'基础 100% · 奖励 75%'**
  String get flowBase100Bonus75;

  /// No description provided for @flowPERFECT100PointLoss.
  ///
  /// In zh, this message translates to:
  /// **'PERFECT · 100落'**
  String get flowPERFECT100PointLoss;

  /// No description provided for @flowBase100Bonus50.
  ///
  /// In zh, this message translates to:
  /// **'基础 100% · 奖励 50%'**
  String get flowBase100Bonus50;

  /// No description provided for @flowBase80Bonus40.
  ///
  /// In zh, this message translates to:
  /// **'基础 80% · 奖励 40%'**
  String get flowBase80Bonus40;

  /// No description provided for @flowBase60Bonus40.
  ///
  /// In zh, this message translates to:
  /// **'基础 60% · 奖励 40%'**
  String get flowBase60Bonus40;

  /// No description provided for @flowBase50Bonus40.
  ///
  /// In zh, this message translates to:
  /// **'基础 50% · 奖励 40%'**
  String get flowBase50Bonus40;

  /// No description provided for @flowBase40Bonus30.
  ///
  /// In zh, this message translates to:
  /// **'基础 40% · 奖励 30%'**
  String get flowBase40Bonus30;

  /// No description provided for @flowBase0Bonus0.
  ///
  /// In zh, this message translates to:
  /// **'基础 0% · 奖励 0%'**
  String get flowBase0Bonus0;

  /// No description provided for @flowNoLoss.
  ///
  /// In zh, this message translates to:
  /// **'无损失'**
  String get flowNoLoss;

  /// No description provided for @flowStayHome.
  ///
  /// In zh, this message translates to:
  /// **'不出勤'**
  String get flowStayHome;

  /// No description provided for @flowScoreTargetsBREAKDistribution.
  ///
  /// In zh, this message translates to:
  /// **'分数线 / 绝赞分布'**
  String get flowScoreTargetsBREAKDistribution;

  /// No description provided for @flowRatingTargets.
  ///
  /// In zh, this message translates to:
  /// **'Rating 线'**
  String get flowRatingTargets;

  /// No description provided for @flowCalculationMode.
  ///
  /// In zh, this message translates to:
  /// **'计算模式'**
  String get flowCalculationMode;

  /// No description provided for @flowByAchievement.
  ///
  /// In zh, this message translates to:
  /// **'按达成率'**
  String get flowByAchievement;

  /// No description provided for @flowByRating.
  ///
  /// In zh, this message translates to:
  /// **'按 Rating'**
  String get flowByRating;

  /// No description provided for @flowResult2.
  ///
  /// In zh, this message translates to:
  /// **'计算结果'**
  String get flowResult2;

  /// No description provided for @flowTargetRating2.
  ///
  /// In zh, this message translates to:
  /// **'目标Rating'**
  String get flowTargetRating2;

  /// No description provided for @flowEG143.
  ///
  /// In zh, this message translates to:
  /// **'如 14.3'**
  String get flowEG143;

  /// No description provided for @flowEG1005667.
  ///
  /// In zh, this message translates to:
  /// **'如 100.5667'**
  String get flowEG1005667;

  /// No description provided for @flowEG321.
  ///
  /// In zh, this message translates to:
  /// **'如 321'**
  String get flowEG321;

  /// No description provided for @flowAchievementP02.
  ///
  /// In zh, this message translates to:
  /// **'达成率{p0}'**
  String flowAchievementP02(String p0);

  /// No description provided for @flowNoteDistributionEditable.
  ///
  /// In zh, this message translates to:
  /// **'物量分布（可编辑）'**
  String get flowNoteDistributionEditable;

  /// No description provided for @flowScoreLossDetails.
  ///
  /// In zh, this message translates to:
  /// **'得分 / 失分详细'**
  String get flowScoreLossDetails;

  /// No description provided for @flowP0P1P2WeekdayP3.
  ///
  /// In zh, this message translates to:
  /// **'{p0}年{p1}月{p2}日 星期{p3}'**
  String flowP0P1P2WeekdayP3(String p0, String p1, String p2, String p3);

  /// No description provided for @flowExporting3.
  ///
  /// In zh, this message translates to:
  /// **'导出中...'**
  String get flowExporting3;

  /// No description provided for @flowExportBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'导出备份文件'**
  String get flowExportBackupFile;

  /// No description provided for @flowRestoringData.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复数据...'**
  String get flowRestoringData;

  /// No description provided for @flowImporting.
  ///
  /// In zh, this message translates to:
  /// **'导入中...'**
  String get flowImporting;

  /// No description provided for @flowChooseBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'选择备份文件'**
  String get flowChooseBackupFile;

  /// No description provided for @flowImportClearsAllCurrentLocalDataBefore.
  ///
  /// In zh, this message translates to:
  /// **'⚠ 导入会先清空当前所有本地数据，再写入备份内容；\n　 备份里没有的项目（含各类缓存）会被一并抹掉。\n　 恢复过程中请不要退出页面。'**
  String get flowImportClearsAllCurrentLocalDataBefore;

  /// No description provided for @flowBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'备份文件'**
  String get flowBackupFile;

  /// No description provided for @flowFindTheFileInDownloadsChiffonMaiIn.
  ///
  /// In zh, this message translates to:
  /// **'可在文件管理器的「下载/ChiffonMai/备份」文件夹中找到该文件。'**
  String get flowFindTheFileInDownloadsChiffonMaiIn;

  /// No description provided for @flowThePublicDirectoryIsNotWritableSaved3.
  ///
  /// In zh, this message translates to:
  /// **'公开目录不可写，已保存到应用文档目录。'**
  String get flowThePublicDirectoryIsNotWritableSaved3;

  /// No description provided for @flowRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get flowRename;

  /// No description provided for @flowConstantHighLow.
  ///
  /// In zh, this message translates to:
  /// **'按定数 (高→低)'**
  String get flowConstantHighLow;

  /// No description provided for @flowConstantLowHigh.
  ///
  /// In zh, this message translates to:
  /// **'按定数 (低→高)'**
  String get flowConstantLowHigh;

  /// No description provided for @flowAddedNewOld.
  ///
  /// In zh, this message translates to:
  /// **'按添加时间 (新→旧)'**
  String get flowAddedNewOld;

  /// No description provided for @flowAddedOldNew.
  ///
  /// In zh, this message translates to:
  /// **'按添加时间 (旧→新)'**
  String get flowAddedOldNew;

  /// No description provided for @flowSongTitleAZ.
  ///
  /// In zh, this message translates to:
  /// **'按歌曲名 (A-Z)'**
  String get flowSongTitleAZ;

  /// No description provided for @flowSignOut2.
  ///
  /// In zh, this message translates to:
  /// **'登出账号'**
  String get flowSignOut2;

  /// No description provided for @flowGetAnImportTokenForScoreSync.
  ///
  /// In zh, this message translates to:
  /// **'获取ImportToken以便同步成绩'**
  String get flowGetAnImportTokenForScoreSync;

  /// No description provided for @flowOnlineLinksAreUnavailableShowingLocallyCached.
  ///
  /// In zh, this message translates to:
  /// **'在线友链暂时不可用，当前显示本地缓存'**
  String get flowOnlineLinksAreUnavailableShowingLocallyCached;

  /// No description provided for @flowCouldNotGenerateRecommendationsP0.
  ///
  /// In zh, this message translates to:
  /// **'生成推荐失败：{p0}'**
  String flowCouldNotGenerateRecommendationsP0(String p0);

  /// No description provided for @flowMixed.
  ///
  /// In zh, this message translates to:
  /// **'混合'**
  String get flowMixed;

  /// No description provided for @flowSourceRatingP0DiffersFromTheLocally.
  ///
  /// In zh, this message translates to:
  /// **'数据源 Rating {p0}，与本地按成绩重算的结果不同，以重算为准'**
  String flowSourceRatingP0DiffersFromTheLocally(String p0);

  /// No description provided for @flowP0ScoresAreMissingFromTheSong.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 条成绩在曲库里找不到，按旧曲处理；刷新曲库后更准确'**
  String flowP0ScoresAreMissingFromTheSong(String p0);

  /// No description provided for @flowP0P12.
  ///
  /// In zh, this message translates to:
  /// **'{p0}月{p1}日'**
  String flowP0P12(String p0, String p1);

  /// No description provided for @flowP0Arcades.
  ///
  /// In zh, this message translates to:
  /// **'{p0}家'**
  String flowP0Arcades(String p0);

  /// No description provided for @flowP0ArcadesTotal.
  ///
  /// In zh, this message translates to:
  /// **'共{p0}家'**
  String flowP0ArcadesTotal(String p0);

  /// No description provided for @flowDivingFishSignInFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'水鱼登录失败，请稍后重试'**
  String get flowDivingFishSignInFailedTryAgain;

  /// No description provided for @flowUserAgreement2.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get flowUserAgreement2;

  /// No description provided for @flowPrivacyPolicy2.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get flowPrivacyPolicy2;

  /// No description provided for @flowLocalQuotesP0.
  ///
  /// In zh, this message translates to:
  /// **'本地语录 {p0}'**
  String flowLocalQuotesP0(String p0);

  /// No description provided for @flowCloudQuotesP0.
  ///
  /// In zh, this message translates to:
  /// **'云端语录 {p0}'**
  String flowCloudQuotesP0(String p0);

  /// No description provided for @flowQuoteCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'语录内容不能为空'**
  String get flowQuoteCannotBeEmpty;

  /// No description provided for @flowServerStatusIsTemporarilyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法获取服务器状态'**
  String get flowServerStatusIsTemporarilyUnavailable;

  /// No description provided for @flowCouldNotLoadServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'加载服务器状态失败'**
  String get flowCouldNotLoadServerStatus;

  /// No description provided for @flowHealthy.
  ///
  /// In zh, this message translates to:
  /// **'好'**
  String get flowHealthy;

  /// No description provided for @flowUnhealthy.
  ///
  /// In zh, this message translates to:
  /// **'坏'**
  String get flowUnhealthy;

  /// No description provided for @flowLatency.
  ///
  /// In zh, this message translates to:
  /// **'延迟 --'**
  String get flowLatency;

  /// No description provided for @flowLatencyP0Ms.
  ///
  /// In zh, this message translates to:
  /// **'延迟 {p0} ms'**
  String flowLatencyP0Ms(String p0);

  /// No description provided for @flowHealthyP0.
  ///
  /// In zh, this message translates to:
  /// **'正常 {p0}'**
  String flowHealthyP0(String p0);

  /// No description provided for @flowIssuesP0.
  ///
  /// In zh, this message translates to:
  /// **'异常 {p0}'**
  String flowIssuesP0(String p0);

  /// No description provided for @flowNoSongsAddedYetUseAddTo.
  ///
  /// In zh, this message translates to:
  /// **'还没有加入歌曲\n在歌曲详情或随身听中点「加入下次想玩」吧'**
  String get flowNoSongsAddedYetUseAddTo;

  /// No description provided for @flowProfileFavoriteFeaturesSyncAndServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'个人概况、常用功能、同步和服务器状态'**
  String get flowProfileFavoriteFeaturesSyncAndServerStatus;

  /// No description provided for @flowFindSongsInspectChartsAndBrowseCollectibles.
  ///
  /// In zh, this message translates to:
  /// **'查歌曲、看谱面、找收藏品'**
  String get flowFindSongsInspectChartsAndBrowseCollectibles;

  /// No description provided for @flowBest50RatingToolsAndLeaderboards.
  ///
  /// In zh, this message translates to:
  /// **'Best50、推分工具和排行榜'**
  String get flowBest50RatingToolsAndLeaderboards;

  /// No description provided for @flowFindArcadesPlayGuessingGamesAndListen.
  ///
  /// In zh, this message translates to:
  /// **'出勤找机厅，休闲猜歌和听歌'**
  String get flowFindArcadesPlayGuessingGamesAndListen;

  /// No description provided for @flowAccountsDataRefreshAndSettings.
  ///
  /// In zh, this message translates to:
  /// **'账号、刷新数据和各种设置'**
  String get flowAccountsDataRefreshAndSettings;

  /// No description provided for @flowOpenFromMeOrTapYourRating.
  ///
  /// In zh, this message translates to:
  /// **'在「我的」页，或点首页的 Rating 进入'**
  String get flowOpenFromMeOrTapYourRating;

  /// No description provided for @flowSyncScores.
  ///
  /// In zh, this message translates to:
  /// **'同步成绩'**
  String get flowSyncScores;

  /// No description provided for @flowDivingFishLXNSAndAWMCNETLink.
  ///
  /// In zh, this message translates to:
  /// **'水鱼、落雪和 AWMC NET，需先绑定账号'**
  String get flowDivingFishLXNSAndAWMCNETLink;

  /// No description provided for @flowRunsThroughoutTheDayWhenEnabledCheck.
  ///
  /// In zh, this message translates to:
  /// **'开启后每天分时处理，首页随时能看结果'**
  String get flowRunsThroughoutTheDayWhenEnabledCheck;

  /// No description provided for @flowTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get flowTheme;

  /// No description provided for @flowLightDarkBlackOrSystemThemePlus.
  ///
  /// In zh, this message translates to:
  /// **'浅色、深色、纯黑或跟随系统，还能换主题色'**
  String get flowLightDarkBlackOrSystemThemePlus;

  /// No description provided for @flowCustomBackgroundImagesDecorationsAndOverlays.
  ///
  /// In zh, this message translates to:
  /// **'自定义背景图、装饰图和覆层'**
  String get flowCustomBackgroundImagesDecorationsAndOverlays;

  /// No description provided for @flowNavigation.
  ///
  /// In zh, this message translates to:
  /// **'导航'**
  String get flowNavigation;

  /// No description provided for @flowThreeNavigationStylesWithOptionalAnimationAnd.
  ///
  /// In zh, this message translates to:
  /// **'三种导航栏样式，动画和滑动切换可开关'**
  String get flowThreeNavigationStylesWithOptionalAnimationAnd;

  /// No description provided for @flowConfetti.
  ///
  /// In zh, this message translates to:
  /// **'纸屑'**
  String get flowConfetti;

  /// No description provided for @flowCelebrateASuccessfulRefreshOrSyncWith.
  ///
  /// In zh, this message translates to:
  /// **'刷新或同步成功时放一点纸屑'**
  String get flowCelebrateASuccessfulRefreshOrSyncWith;

  /// No description provided for @flowEverythingIsReadyRememberToRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'都准备好了呢。记得先刷新一下数据哦？'**
  String get flowEverythingIsReadyRememberToRefreshData;

  /// No description provided for @flowChecking.
  ///
  /// In zh, this message translates to:
  /// **'检查中'**
  String get flowChecking;

  /// No description provided for @flowAllowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get flowAllowed;

  /// No description provided for @flowLimitedAccess.
  ///
  /// In zh, this message translates to:
  /// **'有限访问'**
  String get flowLimitedAccess;

  /// No description provided for @flowOpenSettings3.
  ///
  /// In zh, this message translates to:
  /// **'请前往设置'**
  String get flowOpenSettings3;

  /// No description provided for @flowNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'未允许'**
  String get flowNotAllowed;

  /// No description provided for @flowIHaveReadAndAgreeToThe.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意用户协议和隐私政策'**
  String get flowIHaveReadAndAgreeToThe;

  /// No description provided for @flowChooseYourFiltersThenDrawSomeSongs.
  ///
  /// In zh, this message translates to:
  /// **'选好条件后，开始抽歌吧'**
  String get flowChooseYourFiltersThenDrawSomeSongs;

  /// No description provided for @flowEnterAnIntegerFrom2To100.
  ///
  /// In zh, this message translates to:
  /// **'请输入 2–100 之间的整数'**
  String get flowEnterAnIntegerFrom2To100;

  /// No description provided for @flowDrawCountMustBeBetween2And.
  ///
  /// In zh, this message translates to:
  /// **'抽取数量需在 2–100 之间'**
  String get flowDrawCountMustBeBetween2And;

  /// No description provided for @flowNoMatchingSongsAdjustTheFilters.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的歌曲，请调整筛选条件'**
  String get flowNoMatchingSongsAdjustTheFilters;

  /// No description provided for @flowSongs3.
  ///
  /// In zh, this message translates to:
  /// **' 首'**
  String get flowSongs3;

  /// No description provided for @flowAllVersions.
  ///
  /// In zh, this message translates to:
  /// **'全部版本'**
  String get flowAllVersions;

  /// No description provided for @flowP0VersionsSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 个版本'**
  String flowP0VersionsSelected(String p0);

  /// No description provided for @flowTypeFilter.
  ///
  /// In zh, this message translates to:
  /// **'类型筛选'**
  String get flowTypeFilter;

  /// No description provided for @flowAllTypes.
  ///
  /// In zh, this message translates to:
  /// **'全部类型'**
  String get flowAllTypes;

  /// No description provided for @flowP0TypesSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 个类型'**
  String flowP0TypesSelected(String p0);

  /// No description provided for @flowConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'定数范围'**
  String get flowConstantRange;

  /// No description provided for @flowAdvancedMASTER.
  ///
  /// In zh, this message translates to:
  /// **'MASTER 上级'**
  String get flowAdvancedMASTER;

  /// No description provided for @flowExpertMASTER.
  ///
  /// In zh, this message translates to:
  /// **'MASTER 超上级'**
  String get flowExpertMASTER;

  /// No description provided for @flowCouldNotFetchRecommendationsP0.
  ///
  /// In zh, this message translates to:
  /// **'获取推荐结果失败：{p0}'**
  String flowCouldNotFetchRecommendationsP0(String p0);

  /// No description provided for @flowConstantRange2.
  ///
  /// In zh, this message translates to:
  /// **'定数区间'**
  String get flowConstantRange2;

  /// No description provided for @flowSimilarity.
  ///
  /// In zh, this message translates to:
  /// **'相似度'**
  String get flowSimilarity;

  /// No description provided for @flowCurrentP0TargetP1.
  ///
  /// In zh, this message translates to:
  /// **'当前 {p0}% → 目标 {p1}%'**
  String flowCurrentP0TargetP1(String p0, String p1);

  /// No description provided for @flowEnterAValidP0.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的{p0}'**
  String flowEnterAValidP0(String p0);

  /// No description provided for @flowP0MustBeBetweenP1AndP2.
  ///
  /// In zh, this message translates to:
  /// **'{p0}必须在{p1}到{p2}之间'**
  String flowP0MustBeBetweenP1AndP2(String p0, String p1, String p2);

  /// No description provided for @flowP1ForP0.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 的 {p1}'**
  String flowP1ForP0(String p0, String p1);

  /// No description provided for @flowMultiPlatformSync.
  ///
  /// In zh, this message translates to:
  /// **'多端同步'**
  String get flowMultiPlatformSync;

  /// No description provided for @flowAdvancedDataRefresh.
  ///
  /// In zh, this message translates to:
  /// **'高级数据刷新'**
  String get flowAdvancedDataRefresh;

  /// No description provided for @flowReadPlayCounts.
  ///
  /// In zh, this message translates to:
  /// **'读取游玩次数'**
  String get flowReadPlayCounts;

  /// No description provided for @flowSignOut3.
  ///
  /// In zh, this message translates to:
  /// **'退出账号'**
  String get flowSignOut3;

  /// No description provided for @flowHomeDataRefresh.
  ///
  /// In zh, this message translates to:
  /// **'首页数据刷新'**
  String get flowHomeDataRefresh;

  /// No description provided for @flowWebsiteLink.
  ///
  /// In zh, this message translates to:
  /// **'官网链接'**
  String get flowWebsiteLink;

  /// No description provided for @flowFeedbackLink.
  ///
  /// In zh, this message translates to:
  /// **'反馈链接'**
  String get flowFeedbackLink;

  /// No description provided for @flowGroupNumber.
  ///
  /// In zh, this message translates to:
  /// **'群号'**
  String get flowGroupNumber;

  /// No description provided for @flowSurveyLink.
  ///
  /// In zh, this message translates to:
  /// **'问卷链接'**
  String get flowSurveyLink;

  /// No description provided for @flowGatewayCheckBeforeReadingPlayCounts.
  ///
  /// In zh, this message translates to:
  /// **'读取游玩次数前的网关探活'**
  String get flowGatewayCheckBeforeReadingPlayCounts;

  /// No description provided for @flowReadPlayCountsSeparately.
  ///
  /// In zh, this message translates to:
  /// **'独立读取游玩次数'**
  String get flowReadPlayCountsSeparately;

  /// No description provided for @flowPushToDivingFishThroughTheAWMC.
  ///
  /// In zh, this message translates to:
  /// **'通过 AWMC 网关推送到水鱼'**
  String get flowPushToDivingFishThroughTheAWMC;

  /// No description provided for @flowPushToLXNSThroughTheAWMCGateway.
  ///
  /// In zh, this message translates to:
  /// **'通过 AWMC 网关推送到落雪'**
  String get flowPushToLXNSThroughTheAWMCGateway;

  /// No description provided for @flowCouldNotLoadTheMosaicCoverTry.
  ///
  /// In zh, this message translates to:
  /// **'马赛克曲绘暂时无法加载，请换一题重试'**
  String get flowCouldNotLoadTheMosaicCoverTry;

  /// No description provided for @flow0ShowsTheOriginalHigherValuesCreate3.
  ///
  /// In zh, this message translates to:
  /// **'0% 为原图，数值越高，像素块越大。'**
  String get flow0ShowsTheOriginalHigherValuesCreate3;

  /// No description provided for @flowNoCachedChartsCacheMaidataInThe.
  ///
  /// In zh, this message translates to:
  /// **'谱面缓存为空，请先在谱面库中缓存 maidata'**
  String get flowNoCachedChartsCacheMaidataInThe;

  /// No description provided for @flowNoCachedSongsMatchTheDifficultyPool.
  ///
  /// In zh, this message translates to:
  /// **'没有符合当前筛选条件（难度池 / 定数范围）且有谱面缓存的歌曲'**
  String get flowNoCachedSongsMatchTheDifficultyPool;

  /// No description provided for @flowCouldNotReadThisSongSChart.
  ///
  /// In zh, this message translates to:
  /// **'未能读取该歌曲的谱面内容'**
  String get flowCouldNotReadThisSongSChart;

  /// No description provided for @flowThisSongHasNoChartsInThe.
  ///
  /// In zh, this message translates to:
  /// **'该歌曲没有难度池内的谱面'**
  String get flowThisSongHasNoChartsInThe;

  /// No description provided for @flowTheChartIsTooShortToExtract.
  ///
  /// In zh, this message translates to:
  /// **'谱面过短，无法截取片段'**
  String get flowTheChartIsTooShortToExtract;

  /// No description provided for @flowCouldNotParseChart.
  ///
  /// In zh, this message translates to:
  /// **'谱面解析失败'**
  String get flowCouldNotParseChart;

  /// No description provided for @flowP0ReplaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'（还可复播 {p0} 次）'**
  String flowP0ReplaysLeft(String p0);

  /// No description provided for @flowNoReplaysLeft2.
  ///
  /// In zh, this message translates to:
  /// **'（复播次数已用完）'**
  String get flowNoReplaysLeft2;

  /// No description provided for @flowFiltersUseEachSelectedDifficultySOwn.
  ///
  /// In zh, this message translates to:
  /// **'按「难度随机池」里各难度自己的定数筛选（例如只选 EXPERT 时看 EXPERT 的定数，选 EXPERT+MASTER 时两者任一落在范围内即可），不是按 MASTER 定数。'**
  String get flowFiltersUseEachSelectedDifficultySOwn;

  /// No description provided for @flowCouldNotLoadCoverArtPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'曲绘暂时无法加载，请重试'**
  String get flowCouldNotLoadCoverArtPleaseRetry;

  /// No description provided for @flowNoRecognizableCropAreaInThisCover.
  ///
  /// In zh, this message translates to:
  /// **'当前曲绘没有可辨认的裁剪区域，请重试或放宽筛选条件'**
  String get flowNoRecognizableCropAreaInThisCover;

  /// No description provided for @flowAudioIsTemporarilyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法获取音源'**
  String get flowAudioIsTemporarilyUnavailable;

  /// No description provided for @flowCouldNotReadAudioDuration.
  ///
  /// In zh, this message translates to:
  /// **'无法读取音源时长'**
  String get flowCouldNotReadAudioDuration;

  /// No description provided for @flowAudioExcerptIsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'音频片段为空'**
  String get flowAudioExcerptIsEmpty;

  /// No description provided for @flowPreparingAudio2.
  ///
  /// In zh, this message translates to:
  /// **'正在准备音频…'**
  String get flowPreparingAudio2;

  /// No description provided for @flowP0Tiles.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 块'**
  String flowP0Tiles(String p0);

  /// No description provided for @flowTheSongCacheIsEmptyNoSong.
  ///
  /// In zh, this message translates to:
  /// **'曲库缓存为空，暂时抽不出曲目'**
  String get flowTheSongCacheIsEmptyNoSong;

  /// No description provided for @flowNoSongsMatchBroadenTheFiltersIn.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选条件抽不到曲目，请在设置中放宽条件'**
  String get flowNoSongsMatchBroadenTheFiltersIn;

  /// No description provided for @flowCouldNotLoadSettingsPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'设置加载失败，请重试'**
  String get flowCouldNotLoadSettingsPleaseRetry;

  /// No description provided for @flowExcerptPlaybackLength.
  ///
  /// In zh, this message translates to:
  /// **'片段播放时长'**
  String get flowExcerptPlaybackLength;

  /// No description provided for @flowS.
  ///
  /// In zh, this message translates to:
  /// **' 秒'**
  String get flowS;

  /// No description provided for @flowBlurredCoverBlur.
  ///
  /// In zh, this message translates to:
  /// **'模糊曲绘：模糊程度'**
  String get flowBlurredCoverBlur;

  /// No description provided for @flowPixelCoverDestruction.
  ///
  /// In zh, this message translates to:
  /// **'像素曲绘：破坏程度'**
  String get flowPixelCoverDestruction;

  /// No description provided for @flowFlashCoverDuration.
  ///
  /// In zh, this message translates to:
  /// **'曲绘快闪：快闪时长'**
  String get flowFlashCoverDuration;

  /// No description provided for @flowTileRevealTileCount.
  ///
  /// In zh, this message translates to:
  /// **'曲绘拼图：切块数量'**
  String get flowTileRevealTileCount;

  /// No description provided for @flowTiles.
  ///
  /// In zh, this message translates to:
  /// **' 块'**
  String get flowTiles;

  /// No description provided for @flowTileRevealInterval.
  ///
  /// In zh, this message translates to:
  /// **'曲绘拼图：揭示间隔'**
  String get flowTileRevealInterval;

  /// No description provided for @flowNonEnglishCharacterThreshold.
  ///
  /// In zh, this message translates to:
  /// **'非英文字符过滤阈值'**
  String get flowNonEnglishCharacterThreshold;

  /// No description provided for @flowExcludeSongsWhoseShareOfJapaneseAnd.
  ///
  /// In zh, this message translates to:
  /// **'过滤日语+除空格以外的非英文字符在歌名中的占比大于等于此值的歌曲'**
  String get flowExcludeSongsWhoseShareOfJapaneseAnd;

  /// No description provided for @flowRemainingSongs.
  ///
  /// In zh, this message translates to:
  /// **'剩余歌曲'**
  String get flowRemainingSongs;

  /// No description provided for @flowYouGuessedEverySong.
  ///
  /// In zh, this message translates to:
  /// **'恭喜你猜对了所有歌曲！'**
  String get flowYouGuessedEverySong;

  /// No description provided for @flowSongsFromAllAreas.
  ///
  /// In zh, this message translates to:
  /// **'所有区域歌曲'**
  String get flowSongsFromAllAreas;

  /// No description provided for @flowPerfectChallengeSongsFromAllAreas.
  ///
  /// In zh, this message translates to:
  /// **'所有区域内的完美挑战曲'**
  String get flowPerfectChallengeSongsFromAllAreas;

  /// No description provided for @flowFixedTheHiddenSong.
  ///
  /// In zh, this message translates to:
  /// **'固定，即为隐藏歌曲'**
  String get flowFixedTheHiddenSong;

  /// No description provided for @flowBlueGateEntrance.
  ///
  /// In zh, this message translates to:
  /// **'青门（蓝色之门）门扉'**
  String get flowBlueGateEntrance;

  /// No description provided for @flowSkyStreetArea6.
  ///
  /// In zh, this message translates to:
  /// **'天空街区域6'**
  String get flowSkyStreetArea6;

  /// No description provided for @flowWhiteGateEntrance.
  ///
  /// In zh, this message translates to:
  /// **'白门门扉'**
  String get flowWhiteGateEntrance;

  /// No description provided for @flowHeavenArea8.
  ///
  /// In zh, this message translates to:
  /// **'天界区域8'**
  String get flowHeavenArea8;

  /// No description provided for @flowPurpleGateEntrance.
  ///
  /// In zh, this message translates to:
  /// **'紫门门扉'**
  String get flowPurpleGateEntrance;

  /// No description provided for @flowPurpleRoseArea10.
  ///
  /// In zh, this message translates to:
  /// **'紫蔷薇区域10'**
  String get flowPurpleRoseArea10;

  /// No description provided for @flowBlackGateEntrance.
  ///
  /// In zh, this message translates to:
  /// **'黑门门扉'**
  String get flowBlackGateEntrance;

  /// No description provided for @flowMetropolisArea9.
  ///
  /// In zh, this message translates to:
  /// **'大都会区域9'**
  String get flowMetropolisArea9;

  /// No description provided for @flowPlayAll11SongsInThePool.
  ///
  /// In zh, this message translates to:
  /// **'完成下方曲目池内的11首歌曲（全部游玩）'**
  String get flowPlayAll11SongsInThePool;

  /// No description provided for @flowTrackSkipIsAllowedDanCertificationAnd.
  ///
  /// In zh, this message translates to:
  /// **'可：跳过（Track Skip）/不可：段位认定和宴会场'**
  String get flowTrackSkipIsAllowedDanCertificationAnd;

  /// No description provided for @flowYellowGateEntrance.
  ///
  /// In zh, this message translates to:
  /// **'黄门门扉'**
  String get flowYellowGateEntrance;

  /// No description provided for @flowRainbowArea.
  ///
  /// In zh, this message translates to:
  /// **'七彩区域（なないろちほー）'**
  String get flowRainbowArea;

  /// No description provided for @flowAfterTheGateUpdateUseRandomSong.
  ///
  /// In zh, this message translates to:
  /// **'在门更新之后，使用随机选曲，随出一次以下曲目池中的任意一首并游玩'**
  String get flowAfterTheGateUpdateUseRandomSong;

  /// No description provided for @flowAnyDifficultyRetryingIsAllowedFavoritesCategories.
  ///
  /// In zh, this message translates to:
  /// **'（不限难度，不需要一次随出可以返回重试，可以使用收藏分类）'**
  String get flowAnyDifficultyRetryingIsAllowedFavoritesCategories;

  /// No description provided for @flowRandomSelectionInTheDepartureArea.
  ///
  /// In zh, this message translates to:
  /// **'启程区域随机选曲'**
  String get flowRandomSelectionInTheDepartureArea;

  /// No description provided for @flowRandomPerfectChallengeSongMAXRAGEAndUniTas.
  ///
  /// In zh, this message translates to:
  /// **'启程区域随机完美挑战曲、MAXRAGE和UniTas'**
  String get flowRandomPerfectChallengeSongMAXRAGEAndUniTas;

  /// No description provided for @flowRedGateEntrance.
  ///
  /// In zh, this message translates to:
  /// **'赤门（红色之门）门扉'**
  String get flowRedGateEntrance;

  /// No description provided for @flowSongPool.
  ///
  /// In zh, this message translates to:
  /// **'曲目池'**
  String get flowSongPool;

  /// No description provided for @flowGateConditions.
  ///
  /// In zh, this message translates to:
  /// **'门扉条件'**
  String get flowGateConditions;

  /// No description provided for @flowNotSet3.
  ///
  /// In zh, this message translates to:
  /// **'（未设置）'**
  String get flowNotSet3;

  /// No description provided for @flowKeyRequiredToChallenge.
  ///
  /// In zh, this message translates to:
  /// **'钥匙（挑战所需的物品）'**
  String get flowKeyRequiredToChallenge;

  /// No description provided for @flowKALEIDXSCOPEMode.
  ///
  /// In zh, this message translates to:
  /// **'KALEIDXSCOPE 模式'**
  String get flowKALEIDXSCOPEMode;

  /// No description provided for @flowFirstSongP0.
  ///
  /// In zh, this message translates to:
  /// **'第一首：{p0}'**
  String flowFirstSongP0(String p0);

  /// No description provided for @flowSecondSongP0.
  ///
  /// In zh, this message translates to:
  /// **'第二首：{p0}'**
  String flowSecondSongP0(String p0);

  /// No description provided for @flowThirdSongP0.
  ///
  /// In zh, this message translates to:
  /// **'第三首：{p0}'**
  String flowThirdSongP0(String p0);

  /// No description provided for @flowPerfectChallengeSong.
  ///
  /// In zh, this message translates to:
  /// **'完美挑战曲'**
  String get flowPerfectChallengeSong;

  /// No description provided for @flowClearRewardSong.
  ///
  /// In zh, this message translates to:
  /// **'通关解锁歌曲'**
  String get flowClearRewardSong;

  /// No description provided for @flowHiddenSong.
  ///
  /// In zh, this message translates to:
  /// **'隐藏歌曲'**
  String get flowHiddenSong;

  /// No description provided for @flowPerfectChallenge.
  ///
  /// In zh, this message translates to:
  /// **'小P'**
  String get flowPerfectChallenge;

  /// No description provided for @flowGuide.
  ///
  /// In zh, this message translates to:
  /// **'攻略'**
  String get flowGuide;

  /// No description provided for @flowSongs4.
  ///
  /// In zh, this message translates to:
  /// **'曲目'**
  String get flowSongs4;

  /// No description provided for @flowBlueGate.
  ///
  /// In zh, this message translates to:
  /// **'青の扉（蓝色之门）'**
  String get flowBlueGate;

  /// No description provided for @flowWhiteGate.
  ///
  /// In zh, this message translates to:
  /// **'白の扉（白色之门）'**
  String get flowWhiteGate;

  /// No description provided for @flowPurpleGate.
  ///
  /// In zh, this message translates to:
  /// **'紫の扉（紫色之门）'**
  String get flowPurpleGate;

  /// No description provided for @flowBlackGate.
  ///
  /// In zh, this message translates to:
  /// **'黑の扉（黑色之门）'**
  String get flowBlackGate;

  /// No description provided for @flowYellowGate.
  ///
  /// In zh, this message translates to:
  /// **'黄の扉（黄色之门）'**
  String get flowYellowGate;

  /// No description provided for @flowRedGate.
  ///
  /// In zh, this message translates to:
  /// **'赤の扉（红色之门）'**
  String get flowRedGate;

  /// No description provided for @flowCouldNotLoadNewGatesRefreshUsing.
  ///
  /// In zh, this message translates to:
  /// **'新增门列表加载失败，请点击右上角刷新'**
  String get flowCouldNotLoadNewGatesRefreshUsing;

  /// No description provided for @flowDraw.
  ///
  /// In zh, this message translates to:
  /// **'🤝 平局'**
  String get flowDraw;

  /// No description provided for @flowJointWinners.
  ///
  /// In zh, this message translates to:
  /// **'🤝 并列获胜'**
  String get flowJointWinners;

  /// No description provided for @flowYouWon.
  ///
  /// In zh, this message translates to:
  /// **'🏆 你赢了！'**
  String get flowYouWon;

  /// No description provided for @flowP0Won.
  ///
  /// In zh, this message translates to:
  /// **'🏆 {p0} 获胜'**
  String flowP0Won(String p0);

  /// No description provided for @flowNoOneScoredInThisGame.
  ///
  /// In zh, this message translates to:
  /// **'本局无人得分'**
  String get flowNoOneScoredInThisGame;

  /// No description provided for @flowCouldNotConnectToTheRoomCheck.
  ///
  /// In zh, this message translates to:
  /// **'房间连接失败，请检查网络后重试'**
  String get flowCouldNotConnectToTheRoomCheck;

  /// No description provided for @flowP0IsNowTheHost.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 成为了房主'**
  String flowP0IsNowTheHost(String p0);

  /// No description provided for @flowNoCoverArtAvailable.
  ///
  /// In zh, this message translates to:
  /// **'没有可用曲绘'**
  String get flowNoCoverArtAvailable;

  /// No description provided for @flowScoring.
  ///
  /// In zh, this message translates to:
  /// **'得分机制'**
  String get flowScoring;

  /// No description provided for @flowCorrectAnswer100SecondsSinceTheRound.
  ///
  /// In zh, this message translates to:
  /// **'答对得分 = 100 − 从回合开始经过的秒数，最低 10 分；答错 0 分。'**
  String get flowCorrectAnswer100SecondsSinceTheRound;

  /// No description provided for @flowFasterAnswersScoreHigherInstantAnswersApproach.
  ///
  /// In zh, this message translates to:
  /// **'也就是越快猜中分数越高：秒答接近 100 分，拖到最后也有 10 分保底。'**
  String get flowFasterAnswersScoreHigherInstantAnswersApproach;

  /// No description provided for @flowOnlyYourBestAttemptForEachSong.
  ///
  /// In zh, this message translates to:
  /// **'同一首曲目只按你在这首上最好的一次计分，重复提交不会刷分。'**
  String get flowOnlyYourBestAttemptForEachSong;

  /// No description provided for @flowOnlyTheFirstCorrectPlayerScoresFor.
  ///
  /// In zh, this message translates to:
  /// **'每一首曲目只给最先猜中的人计分，其余人这首拿 0 分。'**
  String get flowOnlyTheFirstCorrectPlayerScoresFor;

  /// No description provided for @flowIncorrectGuessesDoNotSubtractPoints.
  ///
  /// In zh, this message translates to:
  /// **'猜错不扣分，不用怕猜错拖累总分。'**
  String get flowIncorrectGuessesDoNotSubtractPoints;

  /// No description provided for @flowLetterRevealHasSeveralSongsPerRound.
  ///
  /// In zh, this message translates to:
  /// **'开字母一回合有多首曲目，每首独立计分，单回合满分 = 曲目数 × 100。'**
  String get flowLetterRevealHasSeveralSongsPerRound;

  /// No description provided for @flowColorMeanings.
  ///
  /// In zh, this message translates to:
  /// **'颜色含义'**
  String get flowColorMeanings;

  /// No description provided for @flowYellowCloseToTheTargetBPMWithin.
  ///
  /// In zh, this message translates to:
  /// **'黄色 - 该属性与你猜的接近：BPM 相差 ±20 以内；MASTER / Re:MASTER 难度相差 ±0.4 以内；版本相差一个世代（maimai ← maimai PLUS → maimai GreeN）。'**
  String get flowYellowCloseToTheTargetBPMWithin;

  /// No description provided for @flowGrayFarFromTheTarget.
  ///
  /// In zh, this message translates to:
  /// **'灰色 - 该属性与你猜的差距较大。'**
  String get flowGrayFarFromTheTarget;

  /// No description provided for @flowArrows2.
  ///
  /// In zh, this message translates to:
  /// **'箭头'**
  String get flowArrows2;

  /// No description provided for @flowShowsPatternDifficultyAndEvaluationTagsFor2.
  ///
  /// In zh, this message translates to:
  /// **'显示你猜的曲目在 MASTER 难度下的配置、难度和评价标签。'**
  String get flowShowsPatternDifficultyAndEvaluationTagsFor2;

  /// No description provided for @flowAMatchingTargetTagTurnsGreen.
  ///
  /// In zh, this message translates to:
  /// **'当某个标签与目标曲目一致时，该标签会变绿。'**
  String get flowAMatchingTargetTagTurnsGreen;

  /// No description provided for @flowSomeSongsMayNotHaveTags2.
  ///
  /// In zh, this message translates to:
  /// **'注意：有些曲目可能未添加标签。'**
  String get flowSomeSongsMayNotHaveTags2;

  /// No description provided for @flowLetterRevealRules.
  ///
  /// In zh, this message translates to:
  /// **'开字母玩法'**
  String get flowLetterRevealRules;

  /// No description provided for @flowTitlesAreMaskedWithAnyoneCanReveal.
  ///
  /// In zh, this message translates to:
  /// **'本回合曲名以 □ 遮蔽，每人可开字母逐字揭示，开出的字母全房间可见。'**
  String get flowTitlesAreMaskedWithAnyoneCanReveal;

  /// No description provided for @flowEachCharacterCanBeRevealedOnlyOnce.
  ///
  /// In zh, this message translates to:
  /// **'同一个字母只能开一次。'**
  String get flowEachCharacterCanBeRevealedOnlyOnce;

  /// No description provided for @flowOnceASongIsGuessedItsFull.
  ///
  /// In zh, this message translates to:
  /// **'猜中某首后，该曲名会对全房间公开完整名称。'**
  String get flowOnceASongIsGuessedItsFull;

  /// No description provided for @flowGuessingFirstMayRevealTheAnswerBut.
  ///
  /// In zh, this message translates to:
  /// **'抢先猜中可能要「送答案」，但每首只给最先猜中的人计分，先猜中仍然划算。'**
  String get flowGuessingFirstMayRevealTheAnswerBut;

  /// No description provided for @flowTheRoundEndsOnlyWhenEveryTitle.
  ///
  /// In zh, this message translates to:
  /// **'把所有曲名都猜中，本回合才结束。'**
  String get flowTheRoundEndsOnlyWhenEveryTitle;

  /// No description provided for @flowRoomRules.
  ///
  /// In zh, this message translates to:
  /// **'房间规则'**
  String get flowRoomRules;

  /// No description provided for @flowRemainingGuessesAreSharedByTheWhole.
  ///
  /// In zh, this message translates to:
  /// **'剩余猜测次数是全房间共享的，谁先猜都消耗同一个池子，用完本回合即结束。'**
  String get flowRemainingGuessesAreSharedByTheWhole;

  /// No description provided for @flowAfterSurrenderingYouCannotScoreOrSubmit.
  ///
  /// In zh, this message translates to:
  /// **'投降后本回合不再计分，也无法再提交猜测；但仍可围观其他人继续。'**
  String get flowAfterSurrenderingYouCannotScoreOrSubmit;

  /// No description provided for @flowWinning.
  ///
  /// In zh, this message translates to:
  /// **'胜负判定'**
  String get flowWinning;

  /// No description provided for @flowTheHighestTotalScoreAfterAllRounds.
  ///
  /// In zh, this message translates to:
  /// **'全部回合结束后，总分最高的人获胜。'**
  String get flowTheHighestTotalScoreAfterAllRounds;

  /// No description provided for @flowEqualScoresShareTheWinIfNo.
  ///
  /// In zh, this message translates to:
  /// **'同分则并列获胜；全场无人得分时算平局。'**
  String get flowEqualScoresShareTheWinIfNo;

  /// No description provided for @flowScoresAreSettledAtTheEndOf.
  ///
  /// In zh, this message translates to:
  /// **'分数在每回合结束时结算，排行榜显示的就是结算后的总分。'**
  String get flowScoresAreSettledAtTheEndOf;

  /// No description provided for @flowNoTimeLimit.
  ///
  /// In zh, this message translates to:
  /// **'不限时'**
  String get flowNoTimeLimit;

  /// No description provided for @flowTimeIsUp.
  ///
  /// In zh, this message translates to:
  /// **'时间到'**
  String get flowTimeIsUp;

  /// No description provided for @flowAlmostOutOfTime.
  ///
  /// In zh, this message translates to:
  /// **'快没时间了！'**
  String get flowAlmostOutOfTime;

  /// No description provided for @flowPlentyOfTime.
  ///
  /// In zh, this message translates to:
  /// **'还很充裕'**
  String get flowPlentyOfTime;

  /// No description provided for @flowAliasClue.
  ///
  /// In zh, this message translates to:
  /// **'别名提示'**
  String get flowAliasClue;

  /// No description provided for @flowReplayExcerptAudioPreparing.
  ///
  /// In zh, this message translates to:
  /// **'复播片段（音频准备中）'**
  String get flowReplayExcerptAudioPreparing;

  /// No description provided for @flowReplayExcerptP0ReplaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'复播片段（还可复播 {p0} 次）'**
  String flowReplayExcerptP0ReplaysLeft(String p0);

  /// No description provided for @flowAnswerUnlimitedReplaysChartOnlyAudioUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'本局答案：片段可无限复播（音频不可用，仅有谱面）'**
  String get flowAnswerUnlimitedReplaysChartOnlyAudioUnavailable;

  /// No description provided for @flowAnswerUnlimitedReplaysWithAudio.
  ///
  /// In zh, this message translates to:
  /// **'本局答案：片段可无限复播，带音频'**
  String get flowAnswerUnlimitedReplaysWithAudio;

  /// No description provided for @flowAnswerUnlimitedReplaysPreparingAudio.
  ///
  /// In zh, this message translates to:
  /// **'本局答案：片段可无限复播（正在准备音频…）'**
  String get flowAnswerUnlimitedReplaysPreparingAudio;

  /// No description provided for @flowPlaybackStopsAutomaticallyAtTheEndOf.
  ///
  /// In zh, this message translates to:
  /// **'片段播完会自动停在结尾'**
  String get flowPlaybackStopsAutomaticallyAtTheEndOf;

  /// No description provided for @flowThisChartIsNotCachedOnThis.
  ///
  /// In zh, this message translates to:
  /// **'本机没有该曲的谱面缓存，自动拉取也没拿到'**
  String get flowThisChartIsNotCachedOnThis;

  /// No description provided for @flowNoChartForThisSongMatchesThe.
  ///
  /// In zh, this message translates to:
  /// **'这首曲没有符合难度池 / 定数范围的谱面'**
  String get flowNoChartForThisSongMatchesThe;

  /// No description provided for @flowCouldNotReadInoteP0ForThis.
  ///
  /// In zh, this message translates to:
  /// **'未能读取该曲 inote_{p0} 谱面'**
  String flowCouldNotReadInoteP0ForThis(String p0);

  /// No description provided for @flowCouldNotPlayChartExcerptPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'谱面片段播放失败，请重试'**
  String get flowCouldNotPlayChartExcerptPleaseRetry;

  /// No description provided for @flowInvalidSongID.
  ///
  /// In zh, this message translates to:
  /// **'歌曲编号无效'**
  String get flowInvalidSongID;

  /// No description provided for @flowCouldNotFetchAudioTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'未能获取音频，请稍后重试'**
  String get flowCouldNotFetchAudioTryAgainLater;

  /// No description provided for @flowLeavingRoom.
  ///
  /// In zh, this message translates to:
  /// **'正在退出房间…'**
  String get flowLeavingRoom;

  /// No description provided for @flowRoomDoesNotExistOrCannotBe.
  ///
  /// In zh, this message translates to:
  /// **'房间不存在或无法加入'**
  String get flowRoomDoesNotExistOrCannotBe;

  /// No description provided for @flow2Players.
  ///
  /// In zh, this message translates to:
  /// **'2 人'**
  String get flow2Players;

  /// No description provided for @flow3Players.
  ///
  /// In zh, this message translates to:
  /// **'3 人'**
  String get flow3Players;

  /// No description provided for @flow4Players.
  ///
  /// In zh, this message translates to:
  /// **'4 人'**
  String get flow4Players;

  /// No description provided for @flow5Players.
  ///
  /// In zh, this message translates to:
  /// **'5 人'**
  String get flow5Players;

  /// No description provided for @flow6Players.
  ///
  /// In zh, this message translates to:
  /// **'6 人'**
  String get flow6Players;

  /// No description provided for @flowRoomCodeCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'房间码不能为空'**
  String get flowRoomCodeCannotBeEmpty;

  /// No description provided for @flowAfterCreatingARoomTheHostCan.
  ///
  /// In zh, this message translates to:
  /// **'房主创建房间后，可在房间页面复制房间码。'**
  String get flowAfterCreatingARoomTheHostCan;

  /// No description provided for @flowAskYourFriendToSendTheCode.
  ///
  /// In zh, this message translates to:
  /// **'让好友把房间码发给你，在上面粘贴就能加入。'**
  String get flowAskYourFriendToSendTheCode;

  /// No description provided for @flowCouldNotReadAutomaticInstallationSettingsPlease.
  ///
  /// In zh, this message translates to:
  /// **'无法读取自动安装设置，请重试'**
  String get flowCouldNotReadAutomaticInstallationSettingsPlease;

  /// No description provided for @flowCouldNotSaveAutomaticInstallationSettingsPlease.
  ///
  /// In zh, this message translates to:
  /// **'自动安装设置保存失败，请重试'**
  String get flowCouldNotSaveAutomaticInstallationSettingsPlease;

  /// No description provided for @flowCouldNotOpenInstallationSourceSettingsAllow.
  ///
  /// In zh, this message translates to:
  /// **'无法打开安装来源设置，请在系统设置中允许 ChiffonMai 安装应用'**
  String get flowCouldNotOpenInstallationSourceSettingsAllow;

  /// No description provided for @flowDownloadCancelledByUser.
  ///
  /// In zh, this message translates to:
  /// **'用户取消下载'**
  String get flowDownloadCancelledByUser;

  /// No description provided for @flowThisVersionHasNotBeenPublishedYet.
  ///
  /// In zh, this message translates to:
  /// **'该版本尚未正式发布'**
  String get flowThisVersionHasNotBeenPublishedYet;

  /// No description provided for @flowCouldNotIdentifyASingleAPKFor.
  ///
  /// In zh, this message translates to:
  /// **'未找到适合此设备的唯一 APK，请使用网页下载'**
  String get flowCouldNotIdentifyASingleAPKFor;

  /// No description provided for @flowReleaseAssetLacksValidAPKInformationOr.
  ///
  /// In zh, this message translates to:
  /// **'发布附件缺少有效的安装包信息或 SHA-256 校验值'**
  String get flowReleaseAssetLacksValidAPKInformationOr;

  /// No description provided for @flowCouldNotFetchGitHubReleaseInformation.
  ///
  /// In zh, this message translates to:
  /// **'无法获取 GitHub 发布信息'**
  String get flowCouldNotFetchGitHubReleaseInformation;

  /// No description provided for @flowFetchingAPKInformation.
  ///
  /// In zh, this message translates to:
  /// **'正在获取安装包信息…'**
  String get flowFetchingAPKInformation;

  /// No description provided for @flowPreparingBackgroundDownload.
  ///
  /// In zh, this message translates to:
  /// **'正在准备后台下载…'**
  String get flowPreparingBackgroundDownload;

  /// No description provided for @flowCouldNotStartBackgroundDownload.
  ///
  /// In zh, this message translates to:
  /// **'无法开始后台下载'**
  String get flowCouldNotStartBackgroundDownload;

  /// No description provided for @flowCouldNotStartBackgroundDownloadPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'无法开始后台下载，请重试'**
  String get flowCouldNotStartBackgroundDownloadPleaseRetry;

  /// No description provided for @flowCouldNotReadExcerptDuration.
  ///
  /// In zh, this message translates to:
  /// **'无法读取片段时长'**
  String get flowCouldNotReadExcerptDuration;

  /// No description provided for @flowAudioExcerptIsIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'音频片段不完整'**
  String get flowAudioExcerptIsIncomplete;

  /// No description provided for @flowAudioResponseIsNotAValidWAV.
  ///
  /// In zh, this message translates to:
  /// **'音频响应不是有效的 WAV 文件'**
  String get flowAudioResponseIsNotAValidWAV;

  /// No description provided for @flowNoAliases.
  ///
  /// In zh, this message translates to:
  /// **'无别名'**
  String get flowNoAliases;

  /// No description provided for @flowTooLate.
  ///
  /// In zh, this message translates to:
  /// **'猜晚了'**
  String get flowTooLate;

  /// No description provided for @flowTooEarly.
  ///
  /// In zh, this message translates to:
  /// **'猜早了'**
  String get flowTooEarly;

  /// No description provided for @flowInitializationFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始化失败'**
  String get flowInitializationFailed;

  /// No description provided for @flowInitializationTimedOut.
  ///
  /// In zh, this message translates to:
  /// **'初始化超时'**
  String get flowInitializationTimedOut;

  /// No description provided for @flowRepeatOneP0Times.
  ///
  /// In zh, this message translates to:
  /// **'单曲循环 {p0} 次'**
  String flowRepeatOneP0Times(String p0);

  /// No description provided for @flowCurrentSong.
  ///
  /// In zh, this message translates to:
  /// **'当前曲目'**
  String get flowCurrentSong;

  /// No description provided for @flowLXNSAudioFailedForP0TryingWmc.
  ///
  /// In zh, this message translates to:
  /// **'《{p0}》落雪音源失败，尝试 wmc 兜底…'**
  String flowLXNSAudioFailedForP0TryingWmc(String p0);

  /// No description provided for @flowNoAudioAvailableForP0Skipped.
  ///
  /// In zh, this message translates to:
  /// **'《{p0}》当前暂无可用音源，已跳过'**
  String flowNoAudioAvailableForP0Skipped(String p0);

  /// No description provided for @flowChiffonMaiMusicPlayer.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 随身听'**
  String get flowChiffonMaiMusicPlayer;

  /// No description provided for @flowSeveralSongsFailedToLoadAutomaticSkipping.
  ///
  /// In zh, this message translates to:
  /// **'连续多首音源都加载失败，已停止自动跳过（请检查网络后重试）'**
  String get flowSeveralSongsFailedToLoadAutomaticSkipping;

  /// No description provided for @flowNowPlayingP0.
  ///
  /// In zh, this message translates to:
  /// **'正在播放：{p0}'**
  String flowNowPlayingP0(String p0);

  /// No description provided for @flowCouldNotSaveAudioP0.
  ///
  /// In zh, this message translates to:
  /// **'音源保存失败：{p0}'**
  String flowCouldNotSaveAudioP0(String p0);

  /// No description provided for @flowInvalidAPKDirectoryRange.
  ///
  /// In zh, this message translates to:
  /// **'APK 目录范围无效'**
  String get flowInvalidAPKDirectoryRange;

  /// No description provided for @flowIncompleteAPKDirectoryData.
  ///
  /// In zh, this message translates to:
  /// **'APK 目录数据不完整'**
  String get flowIncompleteAPKDirectoryData;

  /// No description provided for @flowCouldNotReadAPKZIPDirectory.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 APK 的 ZIP 目录'**
  String get flowCouldNotReadAPKZIPDirectory;

  /// No description provided for @flowInvalidAPKManifestSize.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单大小无效'**
  String get flowInvalidAPKManifestSize;

  /// No description provided for @flowInvalidAPKManifestDirectory.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单目录无效'**
  String get flowInvalidAPKManifestDirectory;

  /// No description provided for @flowAPKManifestDecompressedSizeMismatch.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单解压大小不一致'**
  String get flowAPKManifestDecompressedSizeMismatch;

  /// No description provided for @flowUnsupportedAPKManifestCompression.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单压缩格式不支持'**
  String get flowUnsupportedAPKManifestCompression;

  /// No description provided for @flowIncompleteAPKManifestData.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单数据不完整'**
  String get flowIncompleteAPKManifestData;

  /// No description provided for @flowAPKHasNoVersionManifest.
  ///
  /// In zh, this message translates to:
  /// **'APK 中没有版本清单'**
  String get flowAPKHasNoVersionManifest;

  /// No description provided for @flowInvalidBinaryAPKManifest.
  ///
  /// In zh, this message translates to:
  /// **'APK 二进制清单无效'**
  String get flowInvalidBinaryAPKManifest;

  /// No description provided for @flowInvalidAPKManifestStringIndex.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单字符串索引无效'**
  String get flowInvalidAPKManifestStringIndex;

  /// No description provided for @flowInvalidAPKManifestChunk.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单分块无效'**
  String get flowInvalidAPKManifestChunk;

  /// No description provided for @flowInvalidAPKManifestStringTable.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单字符串表无效'**
  String get flowInvalidAPKManifestStringTable;

  /// No description provided for @flowInvalidAPKManifestAttribute.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单属性无效'**
  String get flowInvalidAPKManifestAttribute;

  /// No description provided for @flowAPKManifestAttributeOutOfBounds.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单属性越界'**
  String get flowAPKManifestAttributeOutOfBounds;

  /// No description provided for @flowAPKLacksValidVersionInformation.
  ///
  /// In zh, this message translates to:
  /// **'APK 缺少有效版本信息'**
  String get flowAPKLacksValidVersionInformation;

  /// No description provided for @flowAPKHasNoAppVersionInformation.
  ///
  /// In zh, this message translates to:
  /// **'APK 中没有应用版本信息'**
  String get flowAPKHasNoAppVersionInformation;

  /// No description provided for @flowAPKManifestDataOutOfBounds.
  ///
  /// In zh, this message translates to:
  /// **'APK 清单数据越界'**
  String get flowAPKManifestDataOutOfBounds;

  /// No description provided for @flowContentContainsDisallowedWordingEditItAnd.
  ///
  /// In zh, this message translates to:
  /// **'内容包含不合规词句，请修改后重试'**
  String get flowContentContainsDisallowedWordingEditItAnd;

  /// No description provided for @flowMASTERConstantRange.
  ///
  /// In zh, this message translates to:
  /// **'MASTER定数范围'**
  String get flowMASTERConstantRange;

  /// No description provided for @flowUnlimited2.
  ///
  /// In zh, this message translates to:
  /// **'无限制'**
  String get flowUnlimited2;

  /// No description provided for @flowEnterOneValueOrACompleteRange.
  ///
  /// In zh, this message translates to:
  /// **'请输入单值或完整区间，如 13.7 或 13.4-14'**
  String get flowEnterOneValueOrACompleteRange;

  /// No description provided for @flowConstantMustBeAFiniteNumberGreater.
  ///
  /// In zh, this message translates to:
  /// **'定数必须是大于 0 的有限数字'**
  String get flowConstantMustBeAFiniteNumberGreater;

  /// No description provided for @flowLowerBoundCannotExceedUpperBound.
  ///
  /// In zh, this message translates to:
  /// **'区间下限不能大于上限'**
  String get flowLowerBoundCannotExceedUpperBound;

  /// No description provided for @flowUnknownDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'未知难度'**
  String get flowUnknownDifficulty;

  /// No description provided for @flowUTAGECannotBeCombinedWithNormalDifficulties.
  ///
  /// In zh, this message translates to:
  /// **'UTAGE 不能与普通难度同时填写'**
  String get flowUTAGECannotBeCombinedWithNormalDifficulties;

  /// No description provided for @flowChooseSaveLocation.
  ///
  /// In zh, this message translates to:
  /// **'选择保存位置'**
  String get flowChooseSaveLocation;

  /// No description provided for @flowPublicExportDirectoryIsNotWritableWriting.
  ///
  /// In zh, this message translates to:
  /// **'公开导出目录不可写，已拒绝写入应用私有目录'**
  String get flowPublicExportDirectoryIsNotWritableWriting;

  /// No description provided for @flowSupportsChiffonMaiFavoritesFilesSuchAsP0.
  ///
  /// In zh, this message translates to:
  /// **'支持 {p0} 等 ChiffonMai 收藏夹文件'**
  String flowSupportsChiffonMaiFavoritesFilesSuchAsP0(String p0);

  /// No description provided for @flowCouldNotReadCoverPixels.
  ///
  /// In zh, this message translates to:
  /// **'无法读取曲绘像素'**
  String get flowCouldNotReadCoverPixels;

  /// No description provided for @flowCouldNotReadImageData.
  ///
  /// In zh, this message translates to:
  /// **'无法读取图片数据'**
  String get flowCouldNotReadImageData;

  /// No description provided for @flowDateToBeUpdated.
  ///
  /// In zh, this message translates to:
  /// **'日期待更新'**
  String get flowDateToBeUpdated;

  /// No description provided for @flowLater.
  ///
  /// In zh, this message translates to:
  /// **'后续'**
  String get flowLater;

  /// No description provided for @flowWaitForRetryAfterSecondsOrQuotaResetAtBefore.
  ///
  /// In zh, this message translates to:
  /// **'等待 retryAfterSeconds 或 quota.resetAt 后再重试'**
  String get flowWaitForRetryAfterSecondsOrQuotaResetAtBefore;

  /// No description provided for @flowRetryAfterSecondsP0S.
  ///
  /// In zh, this message translates to:
  /// **'retryAfterSeconds（{p0} 秒）'**
  String flowRetryAfterSecondsP0S(String p0);

  /// No description provided for @flowRetryAfterP0OrP1.
  ///
  /// In zh, this message translates to:
  /// **'等待 {p0} 或 {p1} 后再重试'**
  String flowRetryAfterP0OrP1(String p0, String p1);

  /// No description provided for @flowYourSelectionIsActiveButCouldNot.
  ///
  /// In zh, this message translates to:
  /// **'本次选择已生效，但未能保存，请再次点击所选难度重试。'**
  String get flowYourSelectionIsActiveButCouldNot;

  /// No description provided for @flowP0ReleasedTapForChanges.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 已发布，点击查看更新内容'**
  String flowP0ReleasedTapForChanges(String p0);

  /// No description provided for @flowPleaseSignIn.
  ///
  /// In zh, this message translates to:
  /// **'请登录'**
  String get flowPleaseSignIn;

  /// No description provided for @flowSettingsWereNotSavedPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'设置未保存，请重试'**
  String get flowSettingsWereNotSavedPleaseRetry;

  /// No description provided for @flowP0Count.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 数量'**
  String flowP0Count(String p0);

  /// No description provided for @flowAllowChiffonMaiToInstallUpdates.
  ///
  /// In zh, this message translates to:
  /// **'请允许 ChiffonMai 安装更新'**
  String get flowAllowChiffonMaiToInstallUpdates;

  /// No description provided for @flowCouldNotOpenInstaller.
  ///
  /// In zh, this message translates to:
  /// **'无法打开安装界面'**
  String get flowCouldNotOpenInstaller;

  /// No description provided for @flowCouldNotOpenInstallationPermissionSettings.
  ///
  /// In zh, this message translates to:
  /// **'无法打开安装权限设置'**
  String get flowCouldNotOpenInstallationPermissionSettings;

  /// No description provided for @flowActionFailedPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get flowActionFailedPleaseRetry;

  /// No description provided for @flowCouldNotReadCacheUsageP0.
  ///
  /// In zh, this message translates to:
  /// **'读取缓存占用失败：{p0}'**
  String flowCouldNotReadCacheUsageP0(String p0);

  /// No description provided for @flowCouldNotClearCacheP0.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存失败：{p0}'**
  String flowCouldNotClearCacheP0(String p0);

  /// No description provided for @flowLeftRight.
  ///
  /// In zh, this message translates to:
  /// **'左右反'**
  String get flowLeftRight;

  /// No description provided for @flowUpDown.
  ///
  /// In zh, this message translates to:
  /// **'上下反'**
  String get flowUpDown;

  /// No description provided for @flowBoth.
  ///
  /// In zh, this message translates to:
  /// **'全反'**
  String get flowBoth;

  /// No description provided for @flowNoMirror.
  ///
  /// In zh, this message translates to:
  /// **'无镜像'**
  String get flowNoMirror;

  /// No description provided for @flowNothingHereYet.
  ///
  /// In zh, this message translates to:
  /// **'啥都木有'**
  String get flowNothingHereYet;

  /// No description provided for @flowChoose015SpeedAndPitch.
  ///
  /// In zh, this message translates to:
  /// **'可选 0.1× 至 5×，速度与音高联动改变；音源不足设置时长时，按实际时长播放。'**
  String get flowChoose015SpeedAndPitch;

  /// No description provided for @flowBPMChanges.
  ///
  /// In zh, this message translates to:
  /// **'是否变 BPM'**
  String get flowBPMChanges;

  /// No description provided for @flowNotProvided.
  ///
  /// In zh, this message translates to:
  /// **'未提供'**
  String get flowNotProvided;

  /// No description provided for @flowYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get flowYes;

  /// No description provided for @flowNo2.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get flowNo2;

  /// No description provided for @flowBPMChangeCount.
  ///
  /// In zh, this message translates to:
  /// **'BPM 变化次数'**
  String get flowBPMChangeCount;

  /// No description provided for @flowCouldNotLoadCoverArt2.
  ///
  /// In zh, this message translates to:
  /// **'曲绘加载失败'**
  String get flowCouldNotLoadCoverArt2;

  /// No description provided for @flowCorrect2.
  ///
  /// In zh, this message translates to:
  /// **'正确'**
  String get flowCorrect2;

  /// No description provided for @flowAccuracy.
  ///
  /// In zh, this message translates to:
  /// **'正确率'**
  String get flowAccuracy;

  /// No description provided for @flowAverageTime.
  ///
  /// In zh, this message translates to:
  /// **'平均用时'**
  String get flowAverageTime;

  /// No description provided for @flowCurrentStreak.
  ///
  /// In zh, this message translates to:
  /// **'当前连胜'**
  String get flowCurrentStreak;

  /// No description provided for @flowBestStreak.
  ///
  /// In zh, this message translates to:
  /// **'最高连胜'**
  String get flowBestStreak;

  /// No description provided for @flowResultOriginalAudio.
  ///
  /// In zh, this message translates to:
  /// **'结算原声'**
  String get flowResultOriginalAudio;

  /// No description provided for @flowOriginalAudioIsUnavailablePleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'原声片段暂时无法播放，请重试'**
  String get flowOriginalAudioIsUnavailablePleaseRetry;

  /// No description provided for @flowPlayOriginalAudio.
  ///
  /// In zh, this message translates to:
  /// **'播放原声'**
  String get flowPlayOriginalAudio;

  /// No description provided for @flowTitle2.
  ///
  /// In zh, this message translates to:
  /// **'曲名'**
  String get flowTitle2;

  /// No description provided for @flowType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get flowType;

  /// No description provided for @flowMASTERConstant.
  ///
  /// In zh, this message translates to:
  /// **'MASTER定数'**
  String get flowMASTERConstant;

  /// No description provided for @flowMASTERChartDesigner.
  ///
  /// In zh, this message translates to:
  /// **'MASTER谱师'**
  String get flowMASTERChartDesigner;

  /// No description provided for @flowReMASTERConstant.
  ///
  /// In zh, this message translates to:
  /// **'Re:MASTER定数'**
  String get flowReMASTERConstant;

  /// No description provided for @flowReMASTERChartDesigner.
  ///
  /// In zh, this message translates to:
  /// **'Re:MASTER谱师'**
  String get flowReMASTERChartDesigner;

  /// No description provided for @flowMatch.
  ///
  /// In zh, this message translates to:
  /// **'一致'**
  String get flowMatch;

  /// No description provided for @flowCloseArrowsPointToTheAnswer.
  ///
  /// In zh, this message translates to:
  /// **'接近（箭头指向答案）'**
  String get flowCloseArrowsPointToTheAnswer;

  /// No description provided for @flowNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'不符'**
  String get flowNoMatch;

  /// No description provided for @flowP0SRound.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 秒 / 回合'**
  String flowP0SRound(String p0);

  /// No description provided for @flowP0Rounds.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 回合'**
  String flowP0Rounds(String p0);

  /// No description provided for @flowP0SharedGuessesPerRound.
  ///
  /// In zh, this message translates to:
  /// **'每回合共享 {p0} 次猜测'**
  String flowP0SharedGuessesPerRound(String p0);

  /// No description provided for @flowUnlimitedGuesses.
  ///
  /// In zh, this message translates to:
  /// **'猜测次数不限'**
  String get flowUnlimitedGuesses;

  /// No description provided for @flowConstantsP0P1.
  ///
  /// In zh, this message translates to:
  /// **'定数 {p0} - {p1}'**
  String flowConstantsP0P1(String p0, String p1);

  /// No description provided for @flowTemporarilyOffline.
  ///
  /// In zh, this message translates to:
  /// **'暂时离线'**
  String get flowTemporarilyOffline;

  /// No description provided for @flowSurrendered.
  ///
  /// In zh, this message translates to:
  /// **'已投降'**
  String get flowSurrendered;

  /// No description provided for @flowShareTheRoomCodeToInviteFriends.
  ///
  /// In zh, this message translates to:
  /// **'分享房间码邀请好友'**
  String get flowShareTheRoomCodeToInviteFriends;

  /// No description provided for @flowReady2.
  ///
  /// In zh, this message translates to:
  /// **'已准备'**
  String get flowReady2;

  /// No description provided for @flowWaitingToBeReady.
  ///
  /// In zh, this message translates to:
  /// **'等待准备'**
  String get flowWaitingToBeReady;

  /// No description provided for @flowConfirmingPlayerIdentity.
  ///
  /// In zh, this message translates to:
  /// **'正在确认玩家身份…'**
  String get flowConfirmingPlayerIdentity;

  /// No description provided for @flowShareTheCodeAndInviteAtLeast.
  ///
  /// In zh, this message translates to:
  /// **'分享房间码，邀请至少一位好友加入'**
  String get flowShareTheCodeAndInviteAtLeast;

  /// No description provided for @flowP0PlayersAreNotReadyYet.
  ///
  /// In zh, this message translates to:
  /// **'还有 {p0} 位玩家尚未准备就绪'**
  String flowP0PlayersAreNotReadyYet(String p0);

  /// No description provided for @flowEveryoneIsReadyYouCanStart.
  ///
  /// In zh, this message translates to:
  /// **'全员就绪，可以开始了'**
  String get flowEveryoneIsReadyYouCanStart;

  /// No description provided for @flowEveryoneIsReadyWaitingForTheHost.
  ///
  /// In zh, this message translates to:
  /// **'全员就绪，等待房主开始'**
  String get flowEveryoneIsReadyWaitingForTheHost;

  /// No description provided for @flowCouldNotUpdateSongLeaderboard.
  ///
  /// In zh, this message translates to:
  /// **'单曲排行榜更新失败'**
  String get flowCouldNotUpdateSongLeaderboard;

  /// No description provided for @flowRoute1SyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'线路1同步失败'**
  String get flowRoute1SyncFailed;

  /// No description provided for @flowCoverGuessing.
  ///
  /// In zh, this message translates to:
  /// **'曲绘猜歌'**
  String get flowCoverGuessing;

  /// No description provided for @flowBlurredCover.
  ///
  /// In zh, this message translates to:
  /// **'模糊曲绘'**
  String get flowBlurredCover;

  /// No description provided for @flowPixelCover.
  ///
  /// In zh, this message translates to:
  /// **'像素曲绘'**
  String get flowPixelCover;

  /// No description provided for @flowReverseAudio.
  ///
  /// In zh, this message translates to:
  /// **'倒放音频'**
  String get flowReverseAudio;

  /// No description provided for @flowSpeedPitch.
  ///
  /// In zh, this message translates to:
  /// **'变速变调'**
  String get flowSpeedPitch;

  /// No description provided for @flowAliasGuessing.
  ///
  /// In zh, this message translates to:
  /// **'别名猜歌'**
  String get flowAliasGuessing;

  /// No description provided for @flowFlashCover.
  ///
  /// In zh, this message translates to:
  /// **'曲绘快闪'**
  String get flowFlashCover;

  /// No description provided for @flowTileReveal.
  ///
  /// In zh, this message translates to:
  /// **'曲绘拼图'**
  String get flowTileReveal;

  /// No description provided for @flowGuessTheSongFromItsInformation.
  ///
  /// In zh, this message translates to:
  /// **'根据歌曲信息猜歌名'**
  String get flowGuessTheSongFromItsInformation;

  /// No description provided for @flowGuessTheSongFromACoverFragment.
  ///
  /// In zh, this message translates to:
  /// **'根据部分曲绘猜歌名'**
  String get flowGuessTheSongFromACoverFragment;

  /// No description provided for @flowGuessTheSongFromABlurredCover.
  ///
  /// In zh, this message translates to:
  /// **'根据模糊曲绘猜歌名'**
  String get flowGuessTheSongFromABlurredCover;

  /// No description provided for @flowGuessTheSongFromPixelBlocksAnd.
  ///
  /// In zh, this message translates to:
  /// **'根据像素马赛克的色块与轮廓猜歌名'**
  String get flowGuessTheSongFromPixelBlocksAnd;

  /// No description provided for @flowGuessTheSongFromAReversedExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'根据倒放的歌曲片段猜歌名'**
  String get flowGuessTheSongFromAReversedExcerpt;

  /// No description provided for @flowGuessFromAnExcerptWithLinkedSpeed.
  ///
  /// In zh, this message translates to:
  /// **'根据速度和音高联动改变的片段猜歌名'**
  String get flowGuessFromAnExcerptWithLinkedSpeed;

  /// No description provided for @flowGuessTheSongFromAnAudioExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'根据歌曲片段猜歌名'**
  String get flowGuessTheSongFromAnAudioExcerpt;

  /// No description provided for @flowGuessTheSongFromAnAlias.
  ///
  /// In zh, this message translates to:
  /// **'根据别名猜歌名'**
  String get flowGuessTheSongFromAnAlias;

  /// No description provided for @flowGuessTheSongFromInitialLetters.
  ///
  /// In zh, this message translates to:
  /// **'根据首字母猜歌名'**
  String get flowGuessTheSongFromInitialLetters;

  /// No description provided for @flowRememberABrieflyFlashedCoverToGuess.
  ///
  /// In zh, this message translates to:
  /// **'曲绘一闪而过，凭记忆猜歌名'**
  String get flowRememberABrieflyFlashedCoverToGuess;

  /// No description provided for @flowCoverTilesAreRevealedInBatches.
  ///
  /// In zh, this message translates to:
  /// **'曲绘被切成小块逐批揭示'**
  String get flowCoverTilesAreRevealedInBatches;

  /// No description provided for @flowGuessFromASilentChartExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'看无声的谱面片段猜歌名'**
  String get flowGuessFromASilentChartExcerpt;

  /// No description provided for @flowAutomaticInstallationTestingRequiresAndroid12Or.
  ///
  /// In zh, this message translates to:
  /// **'自动安装测试功能需要 Android 12 及以上'**
  String get flowAutomaticInstallationTestingRequiresAndroid12Or;

  /// No description provided for @flowCouldNotSaveAutomaticInstallationSettings.
  ///
  /// In zh, this message translates to:
  /// **'自动安装设置保存失败'**
  String get flowCouldNotSaveAutomaticInstallationSettings;

  /// No description provided for @flowAutomaticInstallationIsOffYouCanInstall.
  ///
  /// In zh, this message translates to:
  /// **'已关闭自动安装，可手动安装更新'**
  String get flowAutomaticInstallationIsOffYouCanInstall;

  /// No description provided for @flowUpdateDownloadedWaitingForTheAppTo.
  ///
  /// In zh, this message translates to:
  /// **'更新已下载，等待 App 在后台无任务持续 8 秒后尝试自动安装'**
  String get flowUpdateDownloadedWaitingForTheAppTo;

  /// No description provided for @flowInstallationTaskInformationIsIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'安装任务信息不完整'**
  String get flowInstallationTaskInformationIsIncomplete;

  /// No description provided for @flowAutomaticInstallationIsOffInstallManually.
  ///
  /// In zh, this message translates to:
  /// **'自动安装已关闭，请手动安装更新'**
  String get flowAutomaticInstallationIsOffInstallManually;

  /// No description provided for @flowFinishActiveTasksOrPlaybackBeforeUpdating.
  ///
  /// In zh, this message translates to:
  /// **'请先结束正在进行的任务或播放后再更新'**
  String get flowFinishActiveTasksOrPlaybackBeforeUpdating;

  /// No description provided for @flowAllowAppsToBeInstalledFromThis.
  ///
  /// In zh, this message translates to:
  /// **'请先允许此来源安装应用'**
  String get flowAllowAppsToBeInstalledFromThis;

  /// No description provided for @flowInstallationTaskChangedCheckUpdateStatusAgain.
  ///
  /// In zh, this message translates to:
  /// **'安装任务已变化，请重新查看更新状态'**
  String get flowInstallationTaskChangedCheckUpdateStatusAgain;

  /// No description provided for @flowCouldNotMoveTheAppToThe.
  ///
  /// In zh, this message translates to:
  /// **'无法将应用退到后台，请稍后重试'**
  String get flowCouldNotMoveTheAppToThe;

  /// No description provided for @flowUpdateDownloadedWaitingForTheAppTo2.
  ///
  /// In zh, this message translates to:
  /// **'更新已下载，等待 App 退到后台后再尝试自动安装'**
  String get flowUpdateDownloadedWaitingForTheAppTo2;

  /// No description provided for @flowUpdateDownloadedWaitingForTheCurrentTask.
  ///
  /// In zh, this message translates to:
  /// **'更新已下载，等待当前任务结束后再尝试自动安装'**
  String get flowUpdateDownloadedWaitingForTheCurrentTask;

  /// No description provided for @flowTheLastAutomaticInstallationDidNotFinish.
  ///
  /// In zh, this message translates to:
  /// **'上次自动安装未完成，可手动安装更新'**
  String get flowTheLastAutomaticInstallationDidNotFinish;

  /// No description provided for @flowCannotReadTheAPK.
  ///
  /// In zh, this message translates to:
  /// **'安装包无法读取'**
  String get flowCannotReadTheAPK;

  /// No description provided for @flowThisAPKDoesNotMeetTheSystem.
  ///
  /// In zh, this message translates to:
  /// **'该安装包不满足当前系统的免确认要求，请手动安装'**
  String get flowThisAPKDoesNotMeetTheSystem;

  /// No description provided for @flowCouldNotSaveInstallationTask.
  ///
  /// In zh, this message translates to:
  /// **'无法保存安装任务'**
  String get flowCouldNotSaveInstallationTask;

  /// No description provided for @flowPreparingAutomaticUpdateInstallation.
  ///
  /// In zh, this message translates to:
  /// **'正在准备自动安装更新…'**
  String get flowPreparingAutomaticUpdateInstallation;

  /// No description provided for @flowAPKVerificationFailedDownloadAgain.
  ///
  /// In zh, this message translates to:
  /// **'安装包校验失败，请重新下载'**
  String get flowAPKVerificationFailedDownloadAgain;

  /// No description provided for @flowUpdateDownloadedWaitingForTheAppTo3.
  ///
  /// In zh, this message translates to:
  /// **'更新已下载，等待 App 在后台无任务持续 8 秒后再安装'**
  String get flowUpdateDownloadedWaitingForTheAppTo3;

  /// No description provided for @flowTheSystemNeedsInstallationConfirmationTapTo.
  ///
  /// In zh, this message translates to:
  /// **'系统需要你确认安装，请点按后手动安装更新'**
  String get flowTheSystemNeedsInstallationConfirmationTapTo;

  /// No description provided for @flowAutomaticInstallationDidNotFinishYouCan.
  ///
  /// In zh, this message translates to:
  /// **'自动安装未完成，可手动安装更新'**
  String get flowAutomaticInstallationDidNotFinishYouCan;

  /// No description provided for @flowUpdateDownloadDirectoryUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'更新下载目录不可用'**
  String get flowUpdateDownloadDirectoryUnavailable;

  /// No description provided for @flowInvalidDownloadAddress.
  ///
  /// In zh, this message translates to:
  /// **'下载地址无效'**
  String get flowInvalidDownloadAddress;

  /// No description provided for @flowInvalidAPKVerificationInformation.
  ///
  /// In zh, this message translates to:
  /// **'安装包校验信息无效'**
  String get flowInvalidAPKVerificationInformation;

  /// No description provided for @flowUpdateTaskChanged.
  ///
  /// In zh, this message translates to:
  /// **'已切换更新任务'**
  String get flowUpdateTaskChanged;

  /// No description provided for @flowCouldNotRemoveThePreviousUpdateFile.
  ///
  /// In zh, this message translates to:
  /// **'无法清理上次的更新文件'**
  String get flowCouldNotRemoveThePreviousUpdateFile;

  /// No description provided for @flowDownloadingInTheBackgroundYouCanKeep.
  ///
  /// In zh, this message translates to:
  /// **'后台下载中，可继续使用 App'**
  String get flowDownloadingInTheBackgroundYouCanKeep;

  /// No description provided for @flowDownloadingUpdateInTheBackground.
  ///
  /// In zh, this message translates to:
  /// **'正在后台下载更新…'**
  String get flowDownloadingUpdateInTheBackground;

  /// No description provided for @flowTheAPKWasRemovedDownloadAgain.
  ///
  /// In zh, this message translates to:
  /// **'安装包已被清理，请重新下载'**
  String get flowTheAPKWasRemovedDownloadAgain;

  /// No description provided for @flowDownloadCancelled.
  ///
  /// In zh, this message translates to:
  /// **'下载已取消'**
  String get flowDownloadCancelled;

  /// No description provided for @flowWaitingForNetworkOrTheSystemTo.
  ///
  /// In zh, this message translates to:
  /// **'等待网络或系统继续下载…'**
  String get flowWaitingForNetworkOrTheSystemTo;

  /// No description provided for @flowAutomaticInstallationCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消自动安装'**
  String get flowAutomaticInstallationCancelled;

  /// No description provided for @flowCheckForUpdatesAgainBeforeDownloading.
  ///
  /// In zh, this message translates to:
  /// **'请重新检查更新后下载'**
  String get flowCheckForUpdatesAgainBeforeDownloading;

  /// No description provided for @flowDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败'**
  String get flowDownloadFailed;

  /// No description provided for @flowVerifyingAPKInTheBackground.
  ///
  /// In zh, this message translates to:
  /// **'正在后台校验安装包…'**
  String get flowVerifyingAPKInTheBackground;

  /// No description provided for @flowAPKDownloadIsIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'安装包下载不完整'**
  String get flowAPKDownloadIsIncomplete;

  /// No description provided for @flowAPKIntegrityCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装包完整性校验失败'**
  String get flowAPKIntegrityCheckFailed;

  /// No description provided for @flowUpdateDownloadFailedPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'更新下载失败，请重试'**
  String get flowUpdateDownloadFailedPleaseRetry;

  /// No description provided for @flowChiffonMaiUpdateDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 更新已下载'**
  String get flowChiffonMaiUpdateDownloaded;

  /// No description provided for @flowChiffonMaiUpdateDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 更新下载失败'**
  String get flowChiffonMaiUpdateDownloadFailed;

  /// No description provided for @flowTapToChooseInstallation.
  ///
  /// In zh, this message translates to:
  /// **'点按后选择安装'**
  String get flowTapToChooseInstallation;

  /// No description provided for @flowTapForDetailsOrToDownloadAgain.
  ///
  /// In zh, this message translates to:
  /// **'点按查看详情或重新下载'**
  String get flowTapForDetailsOrToDownloadAgain;

  /// No description provided for @flowSwitchedToManualInstallation.
  ///
  /// In zh, this message translates to:
  /// **'已改为手动安装更新'**
  String get flowSwitchedToManualInstallation;

  /// No description provided for @flowCouldNotPrepareUpdateInstallation.
  ///
  /// In zh, this message translates to:
  /// **'无法准备安装更新'**
  String get flowCouldNotPrepareUpdateInstallation;

  /// No description provided for @flowAPKInformationIsMissing.
  ///
  /// In zh, this message translates to:
  /// **'安装包信息缺失'**
  String get flowAPKInformationIsMissing;

  /// No description provided for @flowAPKIsOutsideTheUpdateCacheDirectory.
  ///
  /// In zh, this message translates to:
  /// **'安装包不在更新缓存目录中'**
  String get flowAPKIsOutsideTheUpdateCacheDirectory;

  /// No description provided for @flowTheDownloadedFileIsNotAValid.
  ///
  /// In zh, this message translates to:
  /// **'下载的文件不是有效 APK'**
  String get flowTheDownloadedFileIsNotAValid;

  /// No description provided for @flowThisAPKDoesNotBelongToChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'安装包不属于 ChiffonMai'**
  String get flowThisAPKDoesNotBelongToChiffonMai;

  /// No description provided for @flowAPKVersionDoesNotMatchTheUpdate.
  ///
  /// In zh, this message translates to:
  /// **'安装包版本与待更新版本不匹配，请使用网页下载'**
  String get flowAPKVersionDoesNotMatchTheUpdate;

  /// No description provided for @flowAPKSignatureMismatchInstallationStopped.
  ///
  /// In zh, this message translates to:
  /// **'安装包签名不匹配，已停止安装'**
  String get flowAPKSignatureMismatchInstallationStopped;

  /// No description provided for @flowChiffonMaiCrashed.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 崩溃了'**
  String get flowChiffonMaiCrashed;

  /// No description provided for @flowLogsWillBeExportedWhenYouReopen.
  ///
  /// In zh, this message translates to:
  /// **'重新打开后会自动导出日志'**
  String get flowLogsWillBeExportedWhenYouReopen;

  /// No description provided for @flowAppCrash.
  ///
  /// In zh, this message translates to:
  /// **'应用崩溃'**
  String get flowAppCrash;

  /// No description provided for @flowNativeCrash.
  ///
  /// In zh, this message translates to:
  /// **'原生崩溃'**
  String get flowNativeCrash;

  /// No description provided for @flowAppNotResponding.
  ///
  /// In zh, this message translates to:
  /// **'应用无响应'**
  String get flowAppNotResponding;

  /// No description provided for @flowCrashAlerts.
  ///
  /// In zh, this message translates to:
  /// **'崩溃提醒'**
  String get flowCrashAlerts;

  /// No description provided for @flowOpenTheAppToRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'打开 App 刷新数据'**
  String get flowOpenTheAppToRefreshData;

  /// No description provided for @flowUpdatesAutomaticallyWhenOnline.
  ///
  /// In zh, this message translates to:
  /// **'联网后自动更新'**
  String get flowUpdatesAutomaticallyWhenOnline;

  /// No description provided for @flowOpenTheAppToUpdate.
  ///
  /// In zh, this message translates to:
  /// **'打开 App 更新'**
  String get flowOpenTheAppToUpdate;

  /// No description provided for @flowImageExports.
  ///
  /// In zh, this message translates to:
  /// **'图片导出'**
  String get flowImageExports;

  /// No description provided for @flowCouldNotReadSystemWallpaperColors.
  ///
  /// In zh, this message translates to:
  /// **'无法读取系统壁纸配色'**
  String get flowCouldNotReadSystemWallpaperColors;

  /// No description provided for @flowMusicPlayback.
  ///
  /// In zh, this message translates to:
  /// **'随身听播放'**
  String get flowMusicPlayback;

  /// No description provided for @flowShowsTheCurrentSongAndPlaybackControls.
  ///
  /// In zh, this message translates to:
  /// **'显示正在播放的曲目与播放控制'**
  String get flowShowsTheCurrentSongAndPlaybackControls;

  /// No description provided for @flowMusicPlayerPlaying.
  ///
  /// In zh, this message translates to:
  /// **'随身听 · 正在播放'**
  String get flowMusicPlayerPlaying;

  /// No description provided for @flowMusicPlayerPaused.
  ///
  /// In zh, this message translates to:
  /// **'随身听 · 已暂停'**
  String get flowMusicPlayerPaused;

  /// No description provided for @flowSyncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get flowSyncNow;

  /// No description provided for @flowRecognizeScore.
  ///
  /// In zh, this message translates to:
  /// **'识别成绩'**
  String get flowRecognizeScore;

  /// No description provided for @flowMaimaiStatus.
  ///
  /// In zh, this message translates to:
  /// **'舞萌状态'**
  String get flowMaimaiStatus;

  /// No description provided for @flowPlayPause.
  ///
  /// In zh, this message translates to:
  /// **'播放/暂停'**
  String get flowPlayPause;

  /// No description provided for @flowMaimaiStatusAndSync.
  ///
  /// In zh, this message translates to:
  /// **'舞萌状态与同步'**
  String get flowMaimaiStatusAndSync;

  /// No description provided for @flowChiffonMaiOverview.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 概览'**
  String get flowChiffonMaiOverview;

  /// No description provided for @flowChiffonMaiDetails.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai 详情'**
  String get flowChiffonMaiDetails;

  /// No description provided for @flowShowsYourRating.
  ///
  /// In zh, this message translates to:
  /// **'显示你的 Rating'**
  String get flowShowsYourRating;

  /// No description provided for @flowShowsMaimaiStatusAndAutomaticSync.
  ///
  /// In zh, this message translates to:
  /// **'显示舞萌状态和自动同步'**
  String get flowShowsMaimaiStatusAndAutomaticSync;

  /// No description provided for @flowRatingMaimaiStatusAndAutomaticSync.
  ///
  /// In zh, this message translates to:
  /// **'Rating、舞萌状态和自动同步'**
  String get flowRatingMaimaiStatusAndAutomaticSync;

  /// No description provided for @flowAddsSourceSyncResultsAndQuickActions.
  ///
  /// In zh, this message translates to:
  /// **'加上各数据源的同步结果和快捷入口'**
  String get flowAddsSourceSyncResultsAndQuickActions;

  /// No description provided for @flowChiffonMaiVP0Update.
  ///
  /// In zh, this message translates to:
  /// **'ChiffonMai v{p0} 更新'**
  String flowChiffonMaiVP0Update(String p0);

  /// No description provided for @flowAutomaticInstallationDidNotFinishP0You.
  ///
  /// In zh, this message translates to:
  /// **'自动安装未完成：{p0}，可手动安装'**
  String flowAutomaticInstallationDidNotFinishP0You(String p0);

  /// No description provided for @flowP0P1Healthy.
  ///
  /// In zh, this message translates to:
  /// **'{p0}/{p1} 正常'**
  String flowP0P1Healthy(String p0, String p1);

  /// No description provided for @flowTodayP0.
  ///
  /// In zh, this message translates to:
  /// **'今天 {p0}'**
  String flowTodayP0(String p0);

  /// No description provided for @flowP0P1P22.
  ///
  /// In zh, this message translates to:
  /// **'{p0}月{p1}日 {p2}'**
  String flowP0P1P22(String p0, String p1, String p2);

  /// No description provided for @flowUpdatedP03.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 更新'**
  String flowUpdatedP03(String p0);

  /// No description provided for @flowImageSavedTapToReturnToChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'图片已保存，点按回到 ChiffonMai'**
  String get flowImageSavedTapToReturnToChiffonMai;

  /// No description provided for @flowNotSupportedByTheSystemRightNow.
  ///
  /// In zh, this message translates to:
  /// **'系统暂不支持'**
  String get flowNotSupportedByTheSystemRightNow;

  /// No description provided for @svcCheckInIsUnavailableRightNowIt.
  ///
  /// In zh, this message translates to:
  /// **'签到暂时不可用，下次启动会自动重试'**
  String get svcCheckInIsUnavailableRightNowIt;

  /// No description provided for @svcCouldNotReadGrowthRecordsItWill.
  ///
  /// In zh, this message translates to:
  /// **'成长记录暂时无法读取，下次启动会自动重试'**
  String get svcCouldNotReadGrowthRecordsItWill;

  /// No description provided for @svcCheckedInToday.
  ///
  /// In zh, this message translates to:
  /// **'今日已签到'**
  String get svcCheckedInToday;

  /// No description provided for @svcSignInToCheckInAndEarn.
  ///
  /// In zh, this message translates to:
  /// **'登录账号后，每天首次启动可签到领经验'**
  String get svcSignInToCheckInAndEarn;

  /// No description provided for @svcNoGrowthRecordsYetYouWillBe.
  ///
  /// In zh, this message translates to:
  /// **'还没有成长记录，下次启动时会自动签到'**
  String get svcNoGrowthRecordsYetYouWillBe;

  /// No description provided for @svcCheckingIn.
  ///
  /// In zh, this message translates to:
  /// **'正在签到…'**
  String get svcCheckingIn;

  /// No description provided for @svcCheckInAccountDoesNotMatch.
  ///
  /// In zh, this message translates to:
  /// **'签到账号不匹配'**
  String get svcCheckInAccountDoesNotMatch;

  /// No description provided for @svcCheckedInTodayP0EXP.
  ///
  /// In zh, this message translates to:
  /// **'今日签到 +{p0} 经验'**
  String svcCheckedInTodayP0EXP(String p0);

  /// No description provided for @svcSavedOnThisDeviceOnlySyncsAfter.
  ///
  /// In zh, this message translates to:
  /// **'仅本机保存 · 登录水鱼后自动同步'**
  String get svcSavedOnThisDeviceOnlySyncsAfter;

  /// No description provided for @svcSavedOnThisDeviceOnlySignIn.
  ///
  /// In zh, this message translates to:
  /// **'仅本机保存 · 请先登录并刷新落雪账号'**
  String get svcSavedOnThisDeviceOnlySignIn;

  /// No description provided for @svcSavedOnThisDeviceOnlyEnterThe.
  ///
  /// In zh, this message translates to:
  /// **'仅本机保存 · 请先填写 AWMC 账号的 QQ 号'**
  String get svcSavedOnThisDeviceOnlyEnterThe;

  /// No description provided for @svcLoadingCommunityAppearance.
  ///
  /// In zh, this message translates to:
  /// **'正在读取社区装扮'**
  String get svcLoadingCommunityAppearance;

  /// No description provided for @svcAppearanceWaitingToSync.
  ///
  /// In zh, this message translates to:
  /// **'装扮待同步'**
  String get svcAppearanceWaitingToSync;

  /// No description provided for @svcAppearanceWaitingToSyncSignInOr.
  ///
  /// In zh, this message translates to:
  /// **'装扮待同步 · 请登录或验证对应账号后重试'**
  String get svcAppearanceWaitingToSyncSignInOr;

  /// No description provided for @svcAppearanceWaitingToSyncTapToRetry.
  ///
  /// In zh, this message translates to:
  /// **'装扮待同步 · 点击重试'**
  String get svcAppearanceWaitingToSyncTapToRetry;

  /// No description provided for @svcSavedOnThisDeviceOnlySignIn2.
  ///
  /// In zh, this message translates to:
  /// **'仅本机保存 · 请先登录或验证对应账号'**
  String get svcSavedOnThisDeviceOnlySignIn2;

  /// No description provided for @svcSyncingCommunityAppearance.
  ///
  /// In zh, this message translates to:
  /// **'正在同步社区装扮'**
  String get svcSyncingCommunityAppearance;

  /// No description provided for @svcCommunityAppearanceSynced.
  ///
  /// In zh, this message translates to:
  /// **'社区装扮已同步'**
  String get svcCommunityAppearanceSynced;

  /// No description provided for @svcAppearanceWaitingToSyncTheServerHas.
  ///
  /// In zh, this message translates to:
  /// **'装扮待同步 · 服务端尚未确认所选装扮'**
  String get svcAppearanceWaitingToSyncTheServerHas;

  /// No description provided for @svcCouldNotGetTheAPKVersionsPublished.
  ///
  /// In zh, this message translates to:
  /// **'无法获取 GitHub 已发布的 APK 版本'**
  String get svcCouldNotGetTheAPKVersionsPublished;

  /// No description provided for @svcCouldNotReadTheActualVersionOf.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 GitHub APK 的实际版本，请稍后重试'**
  String get svcCouldNotReadTheActualVersionOf;

  /// No description provided for @svcTheAppOrVersionOfTheGitHub.
  ///
  /// In zh, this message translates to:
  /// **'GitHub APK 的应用或版本与发布信息不一致'**
  String get svcTheAppOrVersionOfTheGitHub;

  /// No description provided for @svcExperienceImprovements.
  ///
  /// In zh, this message translates to:
  /// **'优化体验'**
  String get svcExperienceImprovements;

  /// No description provided for @svcNetworkConnectionFailedCheckYourNetworkAnd.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败，请检查网络后重试'**
  String get svcNetworkConnectionFailedCheckYourNetworkAnd;

  /// No description provided for @svcUpdateCheckFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败：{p0}'**
  String svcUpdateCheckFailedP0(String p0);

  /// No description provided for @svcSwitchRoutesAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'自动切换线路'**
  String get svcSwitchRoutesAutomatically;

  /// No description provided for @svcTriesTheMirrorRoutesThenTheOfficial.
  ///
  /// In zh, this message translates to:
  /// **'依次尝试加速线路与官方直连'**
  String get svcTriesTheMirrorRoutesThenTheOfficial;

  /// No description provided for @svcCommonMirrorRoute.
  ///
  /// In zh, this message translates to:
  /// **'常用加速线路'**
  String get svcCommonMirrorRoute;

  /// No description provided for @svcBackupMirrorRoute.
  ///
  /// In zh, this message translates to:
  /// **'备用加速线路'**
  String get svcBackupMirrorRoute;

  /// No description provided for @svcGitHubDirect.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 直连'**
  String get svcGitHubDirect;

  /// No description provided for @svcDownloadDirectlyFromGitHub.
  ///
  /// In zh, this message translates to:
  /// **'直接从 GitHub 官方下载'**
  String get svcDownloadDirectlyFromGitHub;

  /// No description provided for @svcQRCodeEntryCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消输入二维码'**
  String get svcQRCodeEntryCancelled;

  /// No description provided for @svcReasonP0TheLogWasExportedAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'原因：{p0}。日志已自动导出为'**
  String svcReasonP0TheLogWasExportedAutomatically(String p0);

  /// No description provided for @gainRouteStable.
  ///
  /// In zh, this message translates to:
  /// **'稳妥吃分'**
  String get gainRouteStable;

  /// No description provided for @gainRouteChallenge.
  ///
  /// In zh, this message translates to:
  /// **'挑战突破'**
  String get gainRouteChallenge;

  /// No description provided for @gainRouteExplore.
  ///
  /// In zh, this message translates to:
  /// **'探索'**
  String get gainRouteExplore;

  /// No description provided for @svcIncorrectUsernameOrPasswordCheckAndTry.
  ///
  /// In zh, this message translates to:
  /// **'用户名或密码错误，请检查后重试'**
  String get svcIncorrectUsernameOrPasswordCheckAndTry;

  /// No description provided for @svcTooManySignInAttemptsTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'登录请求过于频繁，请稍后再试'**
  String get svcTooManySignInAttemptsTryAgain;

  /// No description provided for @svcTheDivingFishSignInServiceIs.
  ///
  /// In zh, this message translates to:
  /// **'水鱼登录服务暂时不可用，请稍后再试'**
  String get svcTheDivingFishSignInServiceIs;

  /// No description provided for @svcTheDivingFishSignInServiceReturned.
  ///
  /// In zh, this message translates to:
  /// **'水鱼登录接口返回异常，请稍后再试'**
  String get svcTheDivingFishSignInServiceReturned;

  /// No description provided for @svcSignedInButNoSessionWasCreated.
  ///
  /// In zh, this message translates to:
  /// **'登录成功但未建立会话，请稍后再试'**
  String get svcSignedInButNoSessionWasCreated;

  /// No description provided for @svcSignedInButCouldNotGetThe.
  ///
  /// In zh, this message translates to:
  /// **'登录成功但无法获取账号资料，请稍后再试'**
  String get svcSignedInButCouldNotGetThe;

  /// No description provided for @svcSignedInButNoImportTokenWasReturned.
  ///
  /// In zh, this message translates to:
  /// **'登录成功但未获取到 ImportToken，请前往水鱼官网轮换并保存'**
  String get svcSignedInButNoImportTokenWasReturned;

  /// No description provided for @svcSignedInButNoLinkedQQNumber.
  ///
  /// In zh, this message translates to:
  /// **'登录成功但未获取到绑定QQ号，请前往水鱼官网填入并保存'**
  String get svcSignedInButNoLinkedQQNumber;

  /// No description provided for @svcASyncIsAlreadyInProgressTry.
  ///
  /// In zh, this message translates to:
  /// **'同步已在进行中，请稍后重试'**
  String get svcASyncIsAlreadyInProgressTry;

  /// No description provided for @svcTheQRCodeIsInvalidOrHas.
  ///
  /// In zh, this message translates to:
  /// **'二维码无效或已过期，请重新扫描'**
  String get svcTheQRCodeIsInvalidOrHas;

  /// No description provided for @svcMaimaiScoreHubReturnedAnUnexpectedResponse.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 响应异常——缺少 token 或 friendCode，请稍后重试'**
  String get svcMaimaiScoreHubReturnedAnUnexpectedResponse;

  /// No description provided for @svcCouldNotCreateTheFetchTaskTry.
  ///
  /// In zh, this message translates to:
  /// **'创建抓取任务失败，请稍后重试'**
  String get svcCouldNotCreateTheFetchTaskTry;

  /// No description provided for @svcCouldNotCreateTheFriendRequestTry.
  ///
  /// In zh, this message translates to:
  /// **'创建好友请求失败，请稍后重试'**
  String get svcCouldNotCreateTheFriendRequestTry;

  /// No description provided for @svcMaimaiScoreHubDidNotReturnA.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 未返回好友请求任务 ID'**
  String get svcMaimaiScoreHubDidNotReturnA;

  /// No description provided for @svcFriendRequestTimedOutAcceptTheRequest.
  ///
  /// In zh, this message translates to:
  /// **'好友请求超时——请在 NET / 机台上通过好友申请后重试'**
  String get svcFriendRequestTimedOutAcceptTheRequest;

  /// No description provided for @svcFriendRequestFailed.
  ///
  /// In zh, this message translates to:
  /// **'好友请求失败'**
  String get svcFriendRequestFailed;

  /// No description provided for @svcMaimaiScoreHubDidNotReturnA2.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub 未返回任务 ID'**
  String get svcMaimaiScoreHubDidNotReturnA2;

  /// No description provided for @svcSyncTimedOutFetchingScoresTookMore.
  ///
  /// In zh, this message translates to:
  /// **'同步超时——成绩抓取耗时超过 {p0} 分钟，可能是 Bot 好友申请未被通过。请在 NET 上确认好友申请后重试。'**
  String svcSyncTimedOutFetchingScoresTookMore(String p0);

  /// No description provided for @svcCouldNotCheckTheTaskStatusCheck.
  ///
  /// In zh, this message translates to:
  /// **'查询任务状态失败，请检查网络后重试'**
  String get svcCouldNotCheckTheTaskStatusCheck;

  /// No description provided for @svcTaskFailed.
  ///
  /// In zh, this message translates to:
  /// **'任务失败'**
  String get svcTaskFailed;

  /// No description provided for @svcScoresWereFetchedButSyncingToDiving.
  ///
  /// In zh, this message translates to:
  /// **'成绩抓取成功，但同步水鱼失败。可稍后手动重试导出。'**
  String get svcScoresWereFetchedButSyncingToDiving;

  /// No description provided for @svcDivingFishExportFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'水鱼导出失败：{p0}'**
  String svcDivingFishExportFailedP0(String p0);

  /// No description provided for @svcSyncErrorP0.
  ///
  /// In zh, this message translates to:
  /// **'同步异常：{p0}'**
  String svcSyncErrorP0(String p0);

  /// No description provided for @svcNotSignedInToMaimaiScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'尚未登录 maimai Score Hub，请先完成登录后再使用线路2同步'**
  String get svcNotSignedInToMaimaiScoreHub;

  /// No description provided for @svcCouldNotSubmitTheQRCodeCheck.
  ///
  /// In zh, this message translates to:
  /// **'提交二维码失败，请检查网络后重试'**
  String get svcCouldNotSubmitTheQRCodeCheck;

  /// No description provided for @svcSyncTimedOutFetchingScoresTookMore2.
  ///
  /// In zh, this message translates to:
  /// **'同步超时——成绩抓取耗时超过 {p0} 分钟，请稍后重试'**
  String svcSyncTimedOutFetchingScoresTookMore2(String p0);

  /// No description provided for @svcCouldNotSetTheLXNSAPIKey.
  ///
  /// In zh, this message translates to:
  /// **'落雪 API 密钥设置失败，请检查网络后重试'**
  String get svcCouldNotSetTheLXNSAPIKey;

  /// No description provided for @svcSyncTimedOutFetchingCabinetScoresTook.
  ///
  /// In zh, this message translates to:
  /// **'同步超时——机台成绩抓取耗时超过 {p0} 分钟'**
  String svcSyncTimedOutFetchingCabinetScoresTook(String p0);

  /// No description provided for @svcScoresWereFetchedButSyncingToLXNS.
  ///
  /// In zh, this message translates to:
  /// **'成绩抓取成功，但同步落雪失败。可稍后手动重试导出。'**
  String get svcScoresWereFetchedButSyncingToLXNS;

  /// No description provided for @svcLXNSExportFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'落雪导出失败：{p0}'**
  String svcLXNSExportFailedP0(String p0);

  /// No description provided for @svcQueueStatisticsAreUnavailableTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'队列统计暂不可用，请稍后重试'**
  String get svcQueueStatisticsAreUnavailableTryAgainLater;

  /// No description provided for @svcCouldNotReadTheAutoSyncSettings.
  ///
  /// In zh, this message translates to:
  /// **'自动同步设置读取失败，请保留本机数据后重试'**
  String get svcCouldNotReadTheAutoSyncSettings;

  /// No description provided for @svcCouldNotReadTheAutoSyncCredentials.
  ///
  /// In zh, this message translates to:
  /// **'自动同步凭据读取失败，请保留本机数据后重试'**
  String get svcCouldNotReadTheAutoSyncCredentials;

  /// No description provided for @svcTheAutoSyncServiceIsUnavailableCheck.
  ///
  /// In zh, this message translates to:
  /// **'自动同步服务暂不可用，请检查网络后重试；设置状态尚未确认'**
  String get svcTheAutoSyncServiceIsUnavailableCheck;

  /// No description provided for @svcSyncedButTheLocalDataRefreshDid.
  ///
  /// In zh, this message translates to:
  /// **'同步成功，本地数据刷新未完成，请手动刷新'**
  String get svcSyncedButTheLocalDataRefreshDid;

  /// No description provided for @svcPersonalKeySavedOnThisDeviceThe.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已保存在本机，定时任务待更新'**
  String get svcPersonalKeySavedOnThisDeviceThe;

  /// No description provided for @svcTheAccountChangedTurnOffAutoSync.
  ///
  /// In zh, this message translates to:
  /// **'账号已切换，请先关闭旧账号自动同步后重新开启'**
  String get svcTheAccountChangedTurnOffAutoSync;

  /// No description provided for @svcSaveThePersonalKeyForThisData.
  ///
  /// In zh, this message translates to:
  /// **'请重新保存该数据源的个人 key'**
  String get svcSaveThePersonalKeyForThisData;

  /// No description provided for @svcPersonalKeySavedOnThisDeviceThe2.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已保存在本机，定时任务待更新：{p0}'**
  String svcPersonalKeySavedOnThisDeviceThe2(String p0);

  /// No description provided for @svcCheckYourNetworkAndTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'请检查网络后重试'**
  String get svcCheckYourNetworkAndTryAgain;

  /// No description provided for @svcEnterThePersonalKey.
  ///
  /// In zh, this message translates to:
  /// **'请输入个人 key'**
  String get svcEnterThePersonalKey;

  /// No description provided for @svcPersonalKeySaved.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已保存'**
  String get svcPersonalKeySaved;

  /// No description provided for @svcPersonalKeySavedAndTheScheduledTask.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已保存，并已更新定时任务'**
  String get svcPersonalKeySavedAndTheScheduledTask;

  /// No description provided for @svcPersonalKeySavedAutoSyncStaysOff.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已保存，自动同步保持关闭'**
  String get svcPersonalKeySavedAutoSyncStaysOff;

  /// No description provided for @svcPersonalKeyCleared.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已清除'**
  String get svcPersonalKeyCleared;

  /// No description provided for @svcPersonalKeyClearedAndTheMatchingAuto.
  ///
  /// In zh, this message translates to:
  /// **'个人 key 已清除，并已关闭对应自动同步'**
  String get svcPersonalKeyClearedAndTheMatchingAuto;

  /// No description provided for @svcCouldNotVerifyTheTargetAccountScores.
  ///
  /// In zh, this message translates to:
  /// **'目标账号成绩或同步凭据校验失败，请检查该数据源的账号状态'**
  String get svcCouldNotVerifyTheTargetAccountScores;

  /// No description provided for @svcAnAutoSyncTaskAlreadyExistsTrying.
  ///
  /// In zh, this message translates to:
  /// **'已有自动同步任务，正在尝试恢复当前用户的管理权限'**
  String get svcAnAutoSyncTaskAlreadyExistsTrying;

  /// No description provided for @svcNoMatchingAutoSyncTaskWasFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的自动同步任务，请重新开启'**
  String get svcNoMatchingAutoSyncTaskWasFound;

  /// No description provided for @svcTheTaskIsRunningRestoreManagementAccess.
  ///
  /// In zh, this message translates to:
  /// **'任务正在执行中，请稍后再恢复管理权限'**
  String get svcTheTaskIsRunningRestoreManagementAccess;

  /// No description provided for @svcTheAccountLinkedToTheTaskChanged.
  ///
  /// In zh, this message translates to:
  /// **'任务绑定的账号已变化，请先关闭自动同步再重新开启'**
  String get svcTheAccountLinkedToTheTaskChanged;

  /// No description provided for @svcQuickSyncCredentialsAreIncompleteEnterA.
  ///
  /// In zh, this message translates to:
  /// **'快速同步凭据不完整，请先输入二维码绑定机台身份'**
  String get svcQuickSyncCredentialsAreIncompleteEnterA;

  /// No description provided for @svcTooManyRequestsTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'操作过于频繁，请稍后重试'**
  String get svcTooManyRequestsTryAgainLater;

  /// No description provided for @svcCouldNotReadTheSongLibraryOf.
  ///
  /// In zh, this message translates to:
  /// **'目标数据源曲库读取失败，本次未继续同步'**
  String get svcCouldNotReadTheSongLibraryOf;

  /// No description provided for @svcScoreUploadFailedSomeBatchesMayHave.
  ///
  /// In zh, this message translates to:
  /// **'成绩上传失败，部分批次可能已提交；本次不自动重试'**
  String get svcScoreUploadFailedSomeBatchesMayHave;

  /// No description provided for @svcTheAWMCNETImportTokenIsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 的 Import-Token 无效，请在成绩导入凭据重新保存有效 Token，已开启的定时任务会自动更新'**
  String get svcTheAWMCNETImportTokenIsInvalid;

  /// No description provided for @svcCouldNotReadCabinetScoresTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'机台成绩读取失败，请稍后重试'**
  String get svcCouldNotReadCabinetScoresTryAgain;

  /// No description provided for @svcTheUpstreamReturnedPagedScoresReadingStopped.
  ///
  /// In zh, this message translates to:
  /// **'上游返回了分页成绩，本轮已停止读取，避免连续请求'**
  String get svcTheUpstreamReturnedPagedScoresReadingStopped;

  /// No description provided for @svcNoValidScoresSupportedByTheTarget.
  ///
  /// In zh, this message translates to:
  /// **'未读取到目标数据源支持的有效成绩'**
  String get svcNoValidScoresSupportedByTheTarget;

  /// No description provided for @svcAServiceRestartInterruptedTheLastSync.
  ///
  /// In zh, this message translates to:
  /// **'服务重启中断了上次同步，将在下次定时时间继续'**
  String get svcAServiceRestartInterruptedTheLastSync;

  /// No description provided for @svcTheAutoSyncSettingChangedRefreshThe.
  ///
  /// In zh, this message translates to:
  /// **'自动同步设置已变化，请刷新状态'**
  String get svcTheAutoSyncSettingChangedRefreshThe;

  /// No description provided for @svcThisSyncTimedOutAndStoppedIt.
  ///
  /// In zh, this message translates to:
  /// **'本次同步处理超时，已停止并将在下次定时时间继续'**
  String get svcThisSyncTimedOutAndStoppedIt;

  /// No description provided for @svcAutoSyncCapacityIsFullTurnIt.
  ///
  /// In zh, this message translates to:
  /// **'当前自动同步容量已满，请稍后再开启'**
  String get svcAutoSyncCapacityIsFullTurnIt;

  /// No description provided for @svcTheUpstreamQuotaCannotBeConfirmedOr.
  ///
  /// In zh, this message translates to:
  /// **'上游配额暂不可确认或已用尽，任务会在恢复后继续'**
  String get svcTheUpstreamQuotaCannotBeConfirmedOr;

  /// No description provided for @svcTheUpstreamServiceIsUnavailableTheTask.
  ///
  /// In zh, this message translates to:
  /// **'上游服务暂不可用，任务已暂停，恢复后继续'**
  String get svcTheUpstreamServiceIsUnavailableTheTask;

  /// No description provided for @svcThisMorningSProcessingWindowHasEnded.
  ///
  /// In zh, this message translates to:
  /// **'本次上午处理窗口已结束，将在下一轮继续'**
  String get svcThisMorningSProcessingWindowHasEnded;

  /// No description provided for @svcTheUploadResultIsUncertainTheNext.
  ///
  /// In zh, this message translates to:
  /// **'上传结果暂不确定，下一轮会先核对后处理'**
  String get svcTheUploadResultIsUncertainTheNext;

  /// No description provided for @svcTheAutoSyncServiceIsUnavailableTry.
  ///
  /// In zh, this message translates to:
  /// **'自动同步服务暂不可用，请稍后重试'**
  String get svcTheAutoSyncServiceIsUnavailableTry;

  /// No description provided for @svcSetUpTheSyncCredentialsForP0.
  ///
  /// In zh, this message translates to:
  /// **'请先在「成绩导入凭据」设置{p0}的成绩导入 Token'**
  String svcSetUpTheSyncCredentialsForP0(String p0);

  /// No description provided for @svcSetUpYourP0AccountFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先设置{p0}账号'**
  String svcSetUpYourP0AccountFirst(String p0);

  /// No description provided for @svcRefreshYourP0AccountDataBeforeUsing.
  ///
  /// In zh, this message translates to:
  /// **'请先刷新{p0}账号的数据，再使用快速同步'**
  String svcRefreshYourP0AccountDataBeforeUsing(String p0);

  /// No description provided for @svcAWMCReportedSuccessWithoutAUserIdThe.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 返回成功但没有 userId，未缓存机台身份'**
  String get svcAWMCReportedSuccessWithoutAUserIdThe;

  /// No description provided for @svcQuickSyncIsInProgressPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'快速同步正在进行中，请稍候'**
  String get svcQuickSyncIsInProgressPleaseWait;

  /// No description provided for @svcUserCredentialsAreNotCachedEnterA.
  ///
  /// In zh, this message translates to:
  /// **'用户凭据未缓存，请先输入二维码绑定机台身份'**
  String get svcUserCredentialsAreNotCachedEnterA;

  /// No description provided for @svcUpdateTheSongLibraryBeforeUsingQuick.
  ///
  /// In zh, this message translates to:
  /// **'请先更新曲库，再使用快速同步'**
  String get svcUpdateTheSongLibraryBeforeUsingQuick;

  /// No description provided for @svcNoValidScoresMatchedTheLocalSong.
  ///
  /// In zh, this message translates to:
  /// **'有效成绩未匹配到本地曲库，未上传任何数据'**
  String get svcNoValidScoresMatchedTheLocalSong;

  /// No description provided for @svcTheAWMCGatewayIsUnavailableP0.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关暂不可用：{p0}'**
  String svcTheAWMCGatewayIsUnavailableP0(String p0);

  /// No description provided for @svcScorePagingWasAbnormalTheUpdateStopped.
  ///
  /// In zh, this message translates to:
  /// **'成绩分页异常，已终止更新'**
  String get svcScorePagingWasAbnormalTheUpdateStopped;

  /// No description provided for @svcTheServerDoesNotOfferQuickSync.
  ///
  /// In zh, this message translates to:
  /// **'服务端尚未开放快速同步接口，请更新服务端代理'**
  String get svcTheServerDoesNotOfferQuickSync;

  /// No description provided for @svcTheCurrentGatewayUpstreamCannotReadWithout.
  ///
  /// In zh, this message translates to:
  /// **'当前网关上游不支持免二维码读取，请使用普通同步'**
  String get svcTheCurrentGatewayUpstreamCannotReadWithout;

  /// No description provided for @svcQuickReadFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'快速读取失败：{p0}'**
  String svcQuickReadFailedP0(String p0);

  /// No description provided for @svcTheAWMCGatewayReturnedAnInvalidScore.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关返回了无效的成绩分页游标'**
  String get svcTheAWMCGatewayReturnedAnInvalidScore;

  /// No description provided for @svcTheAWMCGatewayReturnedPagedResultsReading.
  ///
  /// In zh, this message translates to:
  /// **'AWMC 网关返回了分页结果，本次已停止读取，避免连续请求'**
  String get svcTheAWMCGatewayReturnedPagedResultsReading;

  /// No description provided for @svcNoValidScoresWereReadNothingWas.
  ///
  /// In zh, this message translates to:
  /// **'没有读取到有效成绩，未上传任何数据'**
  String get svcNoValidScoresWereReadNothingWas;

  /// No description provided for @svcCouldNotReadTheP0SongLibrary.
  ///
  /// In zh, this message translates to:
  /// **'{p0}曲库读取失败，未上传成绩'**
  String svcCouldNotReadTheP0SongLibrary(String p0);

  /// No description provided for @svcTheP0SongLibraryIsEmptyNo.
  ///
  /// In zh, this message translates to:
  /// **'{p0}曲库为空，未上传成绩'**
  String svcTheP0SongLibraryIsEmptyNo(String p0);

  /// No description provided for @svcCouldNotReadExistingP0ScoresSo.
  ///
  /// In zh, this message translates to:
  /// **'{p0}现有成绩读取失败，未进行快速同步，请先检查该源的账号状态'**
  String svcCouldNotReadExistingP0ScoresSo(String p0);

  /// No description provided for @svcP0ReturnedScoresInAnInvalidFormat.
  ///
  /// In zh, this message translates to:
  /// **'{p0}返回的成绩格式无效，未进行快速同步'**
  String svcP0ReturnedScoresInAnInvalidFormat(String p0);

  /// No description provided for @svcP0ScoresAreMissingChartOrCombo.
  ///
  /// In zh, this message translates to:
  /// **'{p0}成绩缺少谱面或连击同步字段，未进行快速同步'**
  String svcP0ScoresAreMissingChartOrCombo(String p0);

  /// No description provided for @svcUploadToP0FailedHTTPP1Remaining.
  ///
  /// In zh, this message translates to:
  /// **'{p0}上传未成功（HTTP {p1}），已停止后续批次；已提交批次可能已生效'**
  String svcUploadToP0FailedHTTPP1Remaining(String p0, String p1);

  /// No description provided for @svcThereAreNoFavoriteFoldersToExport.
  ///
  /// In zh, this message translates to:
  /// **'没有可导出的收藏夹'**
  String get svcThereAreNoFavoriteFoldersToExport;

  /// No description provided for @svcChooseAChiffonMaiFavoritesFile.
  ///
  /// In zh, this message translates to:
  /// **'选择 ChiffonMai 收藏夹文件'**
  String get svcChooseAChiffonMaiFavoritesFile;

  /// No description provided for @svcCouldNotReadTheSelectedFile.
  ///
  /// In zh, this message translates to:
  /// **'无法读取所选文件'**
  String get svcCouldNotReadTheSelectedFile;

  /// No description provided for @svcFileNotFoundP0.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在：{p0}'**
  String svcFileNotFoundP0(String p0);

  /// No description provided for @svcTheFavoritesFileIsTooLargeLimit.
  ///
  /// In zh, this message translates to:
  /// **'收藏夹文件过大（上限 {p0} MB）'**
  String svcTheFavoritesFileIsTooLargeLimit(String p0);

  /// No description provided for @svcThisFileIsNotInTheChiffonMai.
  ///
  /// In zh, this message translates to:
  /// **'这个文件不是 ChiffonMai 收藏夹格式。\n（旧版导出的 .txt 纯文本清单不含歌曲 ID，无法还原成收藏夹，请重新导出一次）'**
  String get svcThisFileIsNotInTheChiffonMai;

  /// No description provided for @svcTheFileIsNotValidJSONAnd.
  ///
  /// In zh, this message translates to:
  /// **'文件内容不是合法的 JSON，可能已损坏'**
  String get svcTheFileIsNotValidJSONAnd;

  /// No description provided for @svcTheFileFormatTagIsP0Not.
  ///
  /// In zh, this message translates to:
  /// **'文件格式标识为 \"{p0}\"，不是 ChiffonMai 收藏夹文件'**
  String svcTheFileFormatTagIsP0Not(String p0);

  /// No description provided for @svcTheFileContentCouldNotBeRecognized.
  ///
  /// In zh, this message translates to:
  /// **'文件内容无法识别'**
  String get svcTheFileContentCouldNotBeRecognized;

  /// No description provided for @svcTheFileHasNoFavoritesData.
  ///
  /// In zh, this message translates to:
  /// **'文件里没有任何收藏夹数据'**
  String get svcTheFileHasNoFavoritesData;

  /// No description provided for @svcTheFileIsMissingTheFoldersField.
  ///
  /// In zh, this message translates to:
  /// **'文件缺少 folders 字段'**
  String get svcTheFileIsMissingTheFoldersField;

  /// No description provided for @svcTheFileIsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'文件是空的'**
  String get svcTheFileIsEmpty;

  /// No description provided for @svcTheBackupExceedsThe50MBLimit.
  ///
  /// In zh, this message translates to:
  /// **'备份超过 50 MB 上限，请精简自定义谱面归档后重试'**
  String get svcTheBackupExceedsThe50MBLimit;

  /// No description provided for @svcTheBackupFileIsTooLargeLimit.
  ///
  /// In zh, this message translates to:
  /// **'备份文件过大（上限 {p0} MB）'**
  String svcTheBackupFileIsTooLargeLimit(String p0);

  /// No description provided for @svcInvalidBackupFileMissingTheDataField.
  ///
  /// In zh, this message translates to:
  /// **'无效的备份文件：缺少 data 字段'**
  String get svcInvalidBackupFileMissingTheDataField;

  /// No description provided for @svcInvalidBackupFileMissingTheVersionField.
  ///
  /// In zh, this message translates to:
  /// **'无效的备份文件：缺少 version 字段'**
  String get svcInvalidBackupFileMissingTheVersionField;

  /// No description provided for @svcUnsupportedBackupVersionOrAppFormat.
  ///
  /// In zh, this message translates to:
  /// **'不支持的备份版本或应用格式'**
  String get svcUnsupportedBackupVersionOrAppFormat;

  /// No description provided for @svcTheBackupFileIsEmptyThereIs.
  ///
  /// In zh, this message translates to:
  /// **'备份文件为空，无数据可恢复'**
  String get svcTheBackupFileIsEmptyThereIs;

  /// No description provided for @svcADataRestoreIsAlreadyInProgress.
  ///
  /// In zh, this message translates to:
  /// **'已有数据恢复正在进行'**
  String get svcADataRestoreIsAlreadyInProgress;

  /// No description provided for @svcSecureCredentialsHaveNotFinishedMigratingTry.
  ///
  /// In zh, this message translates to:
  /// **'安全凭据尚未完成迁移，请稍后重试恢复'**
  String get svcSecureCredentialsHaveNotFinishedMigratingTry;

  /// No description provided for @svcCouldNotClearTheOldSettings.
  ///
  /// In zh, this message translates to:
  /// **'清空旧设置失败'**
  String get svcCouldNotClearTheOldSettings;

  /// No description provided for @svcCouldNotWriteTheBackupSettingP0.
  ///
  /// In zh, this message translates to:
  /// **'写入备份设置失败：{p0}'**
  String svcCouldNotWriteTheBackupSettingP0(String p0);

  /// No description provided for @svcTheBackupHasNoUserSettingsTo.
  ///
  /// In zh, this message translates to:
  /// **'备份没有可恢复的用户设置，已保留当前数据'**
  String get svcTheBackupHasNoUserSettingsTo;

  /// No description provided for @svcSignInAndLinkYourDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'请先登录并绑定水鱼 QQ'**
  String get svcSignInAndLinkYourDivingFish;

  /// No description provided for @svcTheCurrentDivingFishUserHasNo.
  ///
  /// In zh, this message translates to:
  /// **'当前水鱼用户无游玩数据，请先刷新数据'**
  String get svcTheCurrentDivingFishUserHasNo;

  /// No description provided for @svcNoPlayDataWasFoundForThis.
  ///
  /// In zh, this message translates to:
  /// **'未找到该好友的游玩数据，请检查 QQ 号是否正确'**
  String get svcNoPlayDataWasFoundForThis;

  /// No description provided for @svcAddYourAWMCNETQQNumberIn.
  ///
  /// In zh, this message translates to:
  /// **'请先在「绑定与授权管理」里绑定 AWMC NET 的 QQ'**
  String get svcAddYourAWMCNETQQNumberIn;

  /// No description provided for @svcSignInToYourLXNSAccountFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先登录落雪账号'**
  String get svcSignInToYourLXNSAccountFirst;

  /// No description provided for @svcCouldNotReadYourLXNSScoresTry.
  ///
  /// In zh, this message translates to:
  /// **'读取你的落雪成绩失败，请稍后重试'**
  String get svcCouldNotReadYourLXNSScoresTry;

  /// No description provided for @svcTheSongLibraryHasNotLoadedYet.
  ///
  /// In zh, this message translates to:
  /// **'曲库还没有加载好，请稍后重试'**
  String get svcTheSongLibraryHasNotLoadedYet;

  /// No description provided for @svcTheFriendCodeMustContainOnlyDigits.
  ///
  /// In zh, this message translates to:
  /// **'好友码只能是数字，请检查后重试'**
  String get svcTheFriendCodeMustContainOnlyDigits;

  /// No description provided for @svcCouldNotLookUpTheFriendS.
  ///
  /// In zh, this message translates to:
  /// **'查询好友成绩失败（HTTP {p0}）'**
  String svcCouldNotLookUpTheFriendS(String p0);

  /// No description provided for @svcNoLXNSScoresForThisFriendThey.
  ///
  /// In zh, this message translates to:
  /// **'没有这位好友的落雪成绩，好友需要在 ChiffonMai 参与排行榜并刷新过数据'**
  String get svcNoLXNSScoresForThisFriendThey;

  /// No description provided for @svcChooseAtLeastOneResultScreenImage.
  ///
  /// In zh, this message translates to:
  /// **'请先选择至少一张结算画面图片'**
  String get svcChooseAtLeastOneResultScreenImage;

  /// No description provided for @svcUpToP0ImagesCanBeRecognized.
  ///
  /// In zh, this message translates to:
  /// **'一次最多识别 {p0} 张，当前选了 {p1} 张'**
  String svcUpToP0ImagesCanBeRecognized(String p0, String p1);

  /// No description provided for @svcP0ExceedsThe8MiBLimitP1.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 超过 8 MiB 上限（{p1} MiB）'**
  String svcP0ExceedsThe8MiBLimitP1(String p0, String p1);

  /// No description provided for @svcNotSignedInToMaimaiScoreHub2.
  ///
  /// In zh, this message translates to:
  /// **'未登录 maimai Score Hub，无法使用该识别服务'**
  String get svcNotSignedInToMaimaiScoreHub2;

  /// No description provided for @svcNoImagesOrTooManyImagesP0.
  ///
  /// In zh, this message translates to:
  /// **'图片为空或数量超限{p0}'**
  String svcNoImagesOrTooManyImagesP0(String p0);

  /// No description provided for @svcYourSignInHasExpiredSignIn.
  ///
  /// In zh, this message translates to:
  /// **'登录状态已失效，请重新登录 maimai Score Hub'**
  String get svcYourSignInHasExpiredSignIn;

  /// No description provided for @svcAnImageExceedsThe8MiBLimit.
  ///
  /// In zh, this message translates to:
  /// **'有图片超过 8 MiB 上限'**
  String get svcAnImageExceedsThe8MiBLimit;

  /// No description provided for @svcUnsupportedImageFormatOnlyJPEGPNGWebP.
  ///
  /// In zh, this message translates to:
  /// **'图片格式不支持（仅支持 JPEG / PNG / WebP）'**
  String get svcUnsupportedImageFormatOnlyJPEGPNGWebP;

  /// No description provided for @svcTheOCRServiceReturnedAResultThat.
  ///
  /// In zh, this message translates to:
  /// **'OCR 服务返回了无法解析的结果'**
  String get svcTheOCRServiceReturnedAResultThat;

  /// No description provided for @svcTheOCRServiceIsUnavailableTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'OCR 服务暂时不可用，请稍后再试'**
  String get svcTheOCRServiceIsUnavailableTryAgain;

  /// No description provided for @svcOCRRecognitionTimedOutTryAgainLater.
  ///
  /// In zh, this message translates to:
  /// **'OCR 识别超时，请稍后再试'**
  String get svcOCRRecognitionTimedOutTryAgainLater;

  /// No description provided for @svcRecognitionFailedHTTPP0P1.
  ///
  /// In zh, this message translates to:
  /// **'识别失败（HTTP {p0}）{p1}'**
  String svcRecognitionFailedHTTPP0P1(String p0, String p1);

  /// No description provided for @svcAccountDataIsUpdatingTryAgainWhen.
  ///
  /// In zh, this message translates to:
  /// **'账号数据正在更新，请完成后重试'**
  String get svcAccountDataIsUpdatingTryAgainWhen;

  /// No description provided for @svcCouldNotSaveAccountRecoveryInformation.
  ///
  /// In zh, this message translates to:
  /// **'无法保存账号恢复信息'**
  String get svcCouldNotSaveAccountRecoveryInformation;

  /// No description provided for @svcTheAccountChangedSoTheDataRefresh.
  ///
  /// In zh, this message translates to:
  /// **'账号已切换，已跳过本次同步后的数据刷新'**
  String get svcTheAccountChangedSoTheDataRefresh;

  /// No description provided for @svcTheReturnedDataBelongsToAnotherAccount.
  ///
  /// In zh, this message translates to:
  /// **'返回的数据属于其他账号，已取消本次自动刷新'**
  String get svcTheReturnedDataBelongsToAnotherAccount;

  /// No description provided for @svcCouldNotRollBackTheAccountArchive.
  ///
  /// In zh, this message translates to:
  /// **'账号存档回滚失败'**
  String get svcCouldNotRollBackTheAccountArchive;

  /// No description provided for @svcCouldNotIdentifyTheAccountToRestore.
  ///
  /// In zh, this message translates to:
  /// **'无法识别待恢复的账号'**
  String get svcCouldNotIdentifyTheAccountToRestore;

  /// No description provided for @svcCouldNotSaveHistoryMigrationInformation.
  ///
  /// In zh, this message translates to:
  /// **'无法保存历史迁移信息'**
  String get svcCouldNotSaveHistoryMigrationInformation;

  /// No description provided for @svcUserFilesExceedTheBackupSizeLimit.
  ///
  /// In zh, this message translates to:
  /// **'用户文件超过备份容量上限，请先精简自定义谱面归档后重试'**
  String get svcUserFilesExceedTheBackupSizeLimit;

  /// No description provided for @svcTheUserFilesInTheBackupHave.
  ///
  /// In zh, this message translates to:
  /// **'备份的用户文件格式无效'**
  String get svcTheUserFilesInTheBackupHave;

  /// No description provided for @svcInvalidUserFileEntry.
  ///
  /// In zh, this message translates to:
  /// **'用户文件条目无效'**
  String get svcInvalidUserFileEntry;

  /// No description provided for @svcInvalidUserFilePath.
  ///
  /// In zh, this message translates to:
  /// **'用户文件路径无效'**
  String get svcInvalidUserFilePath;

  /// No description provided for @svcInvalidUserFileContent.
  ///
  /// In zh, this message translates to:
  /// **'用户文件内容无效'**
  String get svcInvalidUserFileContent;

  /// No description provided for @svcUserFilesExceedTheBackupSizeLimit2.
  ///
  /// In zh, this message translates to:
  /// **'用户文件超过备份容量上限'**
  String get svcUserFilesExceedTheBackupSizeLimit2;

  /// No description provided for @svcTheUserFileFolderCannotBeA.
  ///
  /// In zh, this message translates to:
  /// **'用户文件目录不能是符号链接'**
  String get svcTheUserFileFolderCannotBeA;

  /// No description provided for @svcUserFilesCannotBeSymbolicLinks.
  ///
  /// In zh, this message translates to:
  /// **'用户文件不能是符号链接'**
  String get svcUserFilesCannotBeSymbolicLinks;

  /// No description provided for @svcCouldNotWriteTheAccountArchive.
  ///
  /// In zh, this message translates to:
  /// **'账号存档写入失败'**
  String get svcCouldNotWriteTheAccountArchive;

  /// No description provided for @svcTheAccountArchiveHasAnInvalidFormat.
  ///
  /// In zh, this message translates to:
  /// **'账号存档格式无效'**
  String get svcTheAccountArchiveHasAnInvalidFormat;

  /// No description provided for @svcCouldNotRestoreTheAccountArchive.
  ///
  /// In zh, this message translates to:
  /// **'账号存档恢复失败'**
  String get svcCouldNotRestoreTheAccountArchive;

  /// No description provided for @svcRefreshTheTargetP0AccountSData.
  ///
  /// In zh, this message translates to:
  /// **'请先刷新{p0}目标账号的数据，以保留该账号的连击与同步标记'**
  String svcRefreshTheTargetP0AccountSData(String p0);

  /// No description provided for @svcTheP0ScoreCacheIsInvalidRefresh.
  ///
  /// In zh, this message translates to:
  /// **'{p0}成绩缓存无效，请先刷新数据'**
  String svcTheP0ScoreCacheIsInvalidRefresh(String p0);

  /// No description provided for @svcLoadedP0FromTheLocalCache.
  ///
  /// In zh, this message translates to:
  /// **'已从本地缓存读取{p0}'**
  String svcLoadedP0FromTheLocalCache(String p0);

  /// No description provided for @svcAudio.
  ///
  /// In zh, this message translates to:
  /// **'音频'**
  String get svcAudio;

  /// No description provided for @svcAudioFile.
  ///
  /// In zh, this message translates to:
  /// **'音频文件'**
  String get svcAudioFile;

  /// No description provided for @svcDownloadingP0.
  ///
  /// In zh, this message translates to:
  /// **'正在下载{p0}…'**
  String svcDownloadingP0(String p0);

  /// No description provided for @svcTheResponseIsNotAMediaFile.
  ///
  /// In zh, this message translates to:
  /// **'响应不是媒体文件'**
  String get svcTheResponseIsNotAMediaFile;

  /// No description provided for @svcTheMediaFileIsIncompleteOrHas.
  ///
  /// In zh, this message translates to:
  /// **'媒体文件不完整或格式无效'**
  String get svcTheMediaFileIsIncompleteOrHas;

  /// No description provided for @svcFileCached.
  ///
  /// In zh, this message translates to:
  /// **'文件已缓存'**
  String get svcFileCached;

  /// No description provided for @svcMediaDownloadFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'媒体下载失败：{p0}'**
  String svcMediaDownloadFailedP0(String p0);

  /// No description provided for @svcP0AddedP1UpdatedP2SkippedP3.
  ///
  /// In zh, this message translates to:
  /// **'新增 {p0} 条 · 更新 {p1} 条 · 跳过 {p2} 条（机台共 {p3} 条）'**
  String svcP0AddedP1UpdatedP2SkippedP3(
      String p0, String p1, String p2, String p3);

  /// No description provided for @svcTheAWMCNETScoreImportTokenHas.
  ///
  /// In zh, this message translates to:
  /// **'还没有设置 AWMC NET 成绩导入 Token'**
  String get svcTheAWMCNETScoreImportTokenHas;

  /// No description provided for @svcPasteOrScanTheCabinetSignIn.
  ///
  /// In zh, this message translates to:
  /// **'请先粘贴或扫描机台登入二维码'**
  String get svcPasteOrScanTheCabinetSignIn;

  /// No description provided for @svcRefusedARequestToANonAWMC.
  ///
  /// In zh, this message translates to:
  /// **'拒绝请求非 AWMC NET 地址：{p0}'**
  String svcRefusedARequestToANonAWMC(String p0);

  /// No description provided for @svcImportTimedOutAfterP0SecondsLarge.
  ///
  /// In zh, this message translates to:
  /// **'导入超时（已等待 {p0} 秒）。机台数据量大时会更久，请稍后重试'**
  String svcImportTimedOutAfterP0SecondsLarge(String p0);

  /// No description provided for @svcCouldNotConnectToAWMCNETP0.
  ///
  /// In zh, this message translates to:
  /// **'连接 AWMC NET 失败：{p0}'**
  String svcCouldNotConnectToAWMCNETP0(String p0);

  /// No description provided for @svcAWMCNETReturnedUnrecognizedData.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回了无法识别的数据'**
  String get svcAWMCNETReturnedUnrecognizedData;

  /// No description provided for @svcCouldNotParseTheAWMCNETResponse.
  ///
  /// In zh, this message translates to:
  /// **'解析 AWMC NET 返回失败：{p0}'**
  String svcCouldNotParseTheAWMCNETResponse(String p0);

  /// No description provided for @svcTheAWMCNETImportTokenIsInvalid2.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 导入 Token 无效，请到 net.wmc.pub 设置页最底部重新生成'**
  String get svcTheAWMCNETImportTokenIsInvalid2;

  /// No description provided for @svcTheAWMCNETImportTokenIsMissing.
  ///
  /// In zh, this message translates to:
  /// **'缺少 AWMC NET 导入 Token'**
  String get svcTheAWMCNETImportTokenIsMissing;

  /// No description provided for @svcTheCabinetQRCodeIsInvalidOr.
  ///
  /// In zh, this message translates to:
  /// **'机台二维码无效或已过期，请重新在公众号/机台获取后重试'**
  String get svcTheCabinetQRCodeIsInvalidOr;

  /// No description provided for @svcAWMCNETRejectedTheRequestP0.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 拒绝了请求：{p0}'**
  String svcAWMCNETRejectedTheRequestP0(String p0);

  /// No description provided for @svcInvalidParameters.
  ///
  /// In zh, this message translates to:
  /// **'参数不合法'**
  String get svcInvalidParameters;

  /// No description provided for @svcTooManyAWMCNETRequestsTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 请求过于频繁，请稍后再试\n{p0}'**
  String svcTooManyAWMCNETRequestsTryAgain(String p0);

  /// No description provided for @svcAWMCNETChimeUserReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'机台成绩读取失败：Chime 获取用户失败（业务码 3002，HTTP {p0}）。请使用新二维码重试；若仍失败，请稍后再试，或使用已绑定机台身份的快速同步。'**
  String svcAWMCNETChimeUserReadFailed(String p0);

  /// No description provided for @svcAWMCNETServerErrorHTTPP0Try.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 服务端异常（HTTP {p0}），请稍后重试'**
  String svcAWMCNETServerErrorHTTPP0Try(String p0);

  /// No description provided for @svcAWMCNETReturnedHTTPP0.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回 HTTP {p0}'**
  String svcAWMCNETReturnedHTTPP0(String p0);

  /// No description provided for @svcNoDivingFishImportTokenYetSign.
  ///
  /// In zh, this message translates to:
  /// **'还没有水鱼 Import-Token，请先登录水鱼账号'**
  String get svcNoDivingFishImportTokenYetSign;

  /// No description provided for @svcCouldNotConnectToDivingFishP0.
  ///
  /// In zh, this message translates to:
  /// **'无法连接水鱼查分器：{p0}'**
  String svcCouldNotConnectToDivingFishP0(String p0);

  /// No description provided for @svcTheImportTokenIsWrongOrThe.
  ///
  /// In zh, this message translates to:
  /// **'导入 Token 有误或请求格式不对'**
  String get svcTheImportTokenIsWrongOrThe;

  /// No description provided for @svcYourSignInIsInvalidSignIn.
  ///
  /// In zh, this message translates to:
  /// **'登录状态无效，请重新登录水鱼'**
  String get svcYourSignInIsInvalidSignIn;

  /// No description provided for @svcSyncFailedHTTPP0P1.
  ///
  /// In zh, this message translates to:
  /// **'同步失败（HTTP {p0}）{p1}'**
  String svcSyncFailedHTTPP0P1(String p0, String p1);

  /// No description provided for @svcDivingFishDidNotAcceptThisScore.
  ///
  /// In zh, this message translates to:
  /// **'水鱼没有接受这条成绩（歌曲没匹配上，或难度索引对该歌曲不存在），请检查曲名和难度'**
  String get svcDivingFishDidNotAcceptThisScore;

  /// No description provided for @svcUTAGEChartsCannotBeSyncedLXNSDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'宴会场谱面不支持同步：落雪的难度索引体系与宴会场不通用'**
  String get svcUTAGEChartsCannotBeSyncedLXNSDifficulty;

  /// No description provided for @svcDifficultyIndexP0IsOutsideTheLXNS.
  ///
  /// In zh, this message translates to:
  /// **'难度索引 {p0} 超出落雪值域（0-4）'**
  String svcDifficultyIndexP0IsOutsideTheLXNS(String p0);

  /// No description provided for @svcYourLXNSAccountIsNotAuthorizedComplete.
  ///
  /// In zh, this message translates to:
  /// **'落雪账号未认证：在「绑定与授权管理」完成 OAuth 授权，或在 OCR 页的落雪状态条里粘贴个人 API 密钥'**
  String get svcYourLXNSAccountIsNotAuthorizedComplete;

  /// No description provided for @svcCouldNotConnectToLXNSP0.
  ///
  /// In zh, this message translates to:
  /// **'无法连接落雪咖啡屋：{p0}'**
  String svcCouldNotConnectToLXNSP0(String p0);

  /// No description provided for @svcLXNSAuthorizationExpiredOrTheKeyIs.
  ///
  /// In zh, this message translates to:
  /// **'落雪授权已失效或密钥无效，请重新授权或粘贴密钥'**
  String get svcLXNSAuthorizationExpiredOrTheKeyIs;

  /// No description provided for @svcLXNSRejectedThisWriteInsufficientPermissions.
  ///
  /// In zh, this message translates to:
  /// **'落雪拒绝了这次写入（权限不足）'**
  String get svcLXNSRejectedThisWriteInsufficientPermissions;

  /// No description provided for @svcLXNSReturnedAnUnexpectedFormatDataIs.
  ///
  /// In zh, this message translates to:
  /// **'落雪返回格式异常：data 为空'**
  String get svcLXNSReturnedAnUnexpectedFormatDataIs;

  /// No description provided for @svcLXNSReturnedAnUnexpectedFormatData0.
  ///
  /// In zh, this message translates to:
  /// **'落雪返回格式异常：data[0] 不是对象'**
  String get svcLXNSReturnedAnUnexpectedFormatData0;

  /// No description provided for @svcThisUserHasNotAuthorizedTheApp.
  ///
  /// In zh, this message translates to:
  /// **'该用户尚未授权本应用，请先完成绑定后再试'**
  String get svcThisUserHasNotAuthorizedTheApp;

  /// No description provided for @svcAuthenticationFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'鉴权失败，请重试'**
  String get svcAuthenticationFailedTryAgain;

  /// No description provided for @svcNoPermissionToAccessThisUserS.
  ///
  /// In zh, this message translates to:
  /// **'无权限访问该用户数据'**
  String get svcNoPermissionToAccessThisUserS;

  /// No description provided for @svcTodaySQueryLimitHasBeenReached.
  ///
  /// In zh, this message translates to:
  /// **'今日查询次数已达上限，请稍后再试'**
  String get svcTodaySQueryLimitHasBeenReached;

  /// No description provided for @svcRequestFailedStatusCodeP0.
  ///
  /// In zh, this message translates to:
  /// **'请求失败（状态码 {p0}）'**
  String svcRequestFailedStatusCodeP0(String p0);

  /// No description provided for @svcConnectionCancelled.
  ///
  /// In zh, this message translates to:
  /// **'连接已取消'**
  String get svcConnectionCancelled;

  /// No description provided for @svcDisconnectedReconnectAndTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开，请重新连接后重试'**
  String get svcDisconnectedReconnectAndTryAgain;

  /// No description provided for @svcDisconnectedTheCoverReadyStatusWasNot.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开，曲绘准备状态未发送'**
  String get svcDisconnectedTheCoverReadyStatusWasNot;

  /// No description provided for @svcDisconnectedThisGuessWasNotSubmittedReconnect.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开，本次猜测未提交，请连接后重试'**
  String get svcDisconnectedThisGuessWasNotSubmittedReconnect;

  /// No description provided for @svcDisconnectedReconnectBeforeLeavingTheRoom.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开，请重新连接后再退出房间'**
  String get svcDisconnectedReconnectBeforeLeavingTheRoom;

  /// No description provided for @svcEnterAQQNumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入 QQ 号'**
  String get svcEnterAQQNumber;

  /// No description provided for @svcAWMCNETQueryTimedOutP0S.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 查询超时（{p0} 秒），请检查网络后重试'**
  String svcAWMCNETQueryTimedOutP0S(String p0);

  /// No description provided for @svcAWMCNETConnectionFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 连接失败：{p0}'**
  String svcAWMCNETConnectionFailedP0(String p0);

  /// No description provided for @svcAWMCNETReturnedDataThatCouldNot.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回了无法解析的数据：{p0}'**
  String svcAWMCNETReturnedDataThatCouldNot(String p0);

  /// No description provided for @svcAWMCNETReturnedAnUnrecognizedDataStructure.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回的数据结构无法识别（缺少 records）'**
  String get svcAWMCNETReturnedAnUnrecognizedDataStructure;

  /// No description provided for @svcAWMCNETHasNoDataForQQ.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 上没有 QQ {p0} 的数据。\n请确认该 QQ 已在 net.wmc.pub 绑定并上传过成绩。'**
  String svcAWMCNETHasNoDataForQQ(String p0);

  /// No description provided for @svcTheAWMCNETDeveloperKeyIsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 开发者密钥无效或已失效（HTTP {p0}）'**
  String svcTheAWMCNETDeveloperKeyIsInvalid(String p0);

  /// No description provided for @svcAWMCNETReturnedAnUnknownStatusHTTP.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回未知状态：HTTP {p0}{p1}'**
  String svcAWMCNETReturnedAnUnknownStatusHTTP(String p0, String p1);

  /// No description provided for @svcInvalidQQNumber512DigitsExpected.
  ///
  /// In zh, this message translates to:
  /// **'QQ 号格式不对（应为 5–12 位数字）：{p0}'**
  String svcInvalidQQNumber512DigitsExpected(String p0);

  /// No description provided for @svcAWMCNETHasNoDataForQQ2.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 没有 QQ {p0} 的数据（请确认该 QQ 已在 net.wmc.pub 绑定并上传过成绩）'**
  String svcAWMCNETHasNoDataForQQ2(String p0);

  /// No description provided for @svcAWMCNETRejectedTheRequestDaysIs.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 拒绝了请求：days 参数超出范围（1~365）'**
  String get svcAWMCNETRejectedTheRequestDaysIs;

  /// No description provided for @svcAWMCNETReturnedJSONThatCouldNot.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回了无法解析的 JSON：{p0}'**
  String svcAWMCNETReturnedJSONThatCouldNot(String p0);

  /// No description provided for @svcTheAWMCNETResponseHasNoPoints.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 返回结构里没有 points 数组'**
  String get svcTheAWMCNETResponseHasNoPoints;

  /// No description provided for @svcP0MsOfflineMode.
  ///
  /// In zh, this message translates to:
  /// **'{p0}ms（离线模式）'**
  String svcP0MsOfflineMode(String p0);

  /// No description provided for @svcLoadingTheSongAliasDatabase.
  ///
  /// In zh, this message translates to:
  /// **'正在加载歌曲别名数据库...'**
  String get svcLoadingTheSongAliasDatabase;

  /// No description provided for @svcInitializingTheMaidataManager.
  ///
  /// In zh, this message translates to:
  /// **'正在初始化Maidata管理器...'**
  String get svcInitializingTheMaidataManager;

  /// No description provided for @svcFetchingAllMaidataTheFirstLoadMay.
  ///
  /// In zh, this message translates to:
  /// **'正在获取全量Maidata数据...\n（首次加载可能较慢，请耐心等待）'**
  String get svcFetchingAllMaidataTheFirstLoadMay;

  /// No description provided for @svcLoadingMaidataFromCache.
  ///
  /// In zh, this message translates to:
  /// **'从缓存加载Maidata数据...'**
  String get svcLoadingMaidataFromCache;

  /// No description provided for @svcSyncingSongInfoAndDifficultyData.
  ///
  /// In zh, this message translates to:
  /// **'正在同步歌曲信息与难度数据...'**
  String get svcSyncingSongInfoAndDifficultyData;

  /// No description provided for @svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd.
  ///
  /// In zh, this message translates to:
  /// **'正在加载收藏品、标签、歌曲、知识库等数据...'**
  String get svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd;

  /// No description provided for @svcBuildingSongMappings.
  ///
  /// In zh, this message translates to:
  /// **'正在建立歌曲关联映射...'**
  String get svcBuildingSongMappings;

  /// No description provided for @svcTheExportCanvasIsNotReady.
  ///
  /// In zh, this message translates to:
  /// **'导出画布未就绪'**
  String get svcTheExportCanvasIsNotReady;

  /// No description provided for @svcDiscoveringBaseMaidata.
  ///
  /// In zh, this message translates to:
  /// **'正在发现基础量 maidata…'**
  String get svcDiscoveringBaseMaidata;

  /// No description provided for @svcFetchingMaidataP0P1.
  ///
  /// In zh, this message translates to:
  /// **'正在拉取 maidata：{p0}/{p1}'**
  String svcFetchingMaidataP0P1(String p0, String p1);

  /// No description provided for @svcFoundP0MaidataFiles.
  ///
  /// In zh, this message translates to:
  /// **'已发现 {p0} 份 maidata'**
  String svcFoundP0MaidataFiles(String p0);

  /// No description provided for @svcTheLogWasExportedAutomaticallyYouCan.
  ///
  /// In zh, this message translates to:
  /// **'日志已自动导出，可以发给开发者排查'**
  String get svcTheLogWasExportedAutomaticallyYouCan;

  /// No description provided for @svcLogExportFailedYouCanExportIt.
  ///
  /// In zh, this message translates to:
  /// **'日志导出失败，可在「打印日志」手动导出'**
  String get svcLogExportFailedYouCanExportIt;

  /// No description provided for @svcTheGatewayCouldNotReachItsOrigin.
  ///
  /// In zh, this message translates to:
  /// **'网关回源失败：CDN 返回了非法响应头的错误页（SpeedOnline），通常是网关/回源超时，稍后重试即可'**
  String get svcTheGatewayCouldNotReachItsOrigin;

  /// No description provided for @svcRequestFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'请求失败：{p0}'**
  String svcRequestFailedP0(String p0);

  /// No description provided for @svcSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get svcSuccess;

  /// No description provided for @svcTheServerHasNoAWMCDeveloperKey.
  ///
  /// In zh, this message translates to:
  /// **'服务端尚未配置 AWMC 开发者密钥，请联系管理员'**
  String get svcTheServerHasNoAWMCDeveloperKey;

  /// No description provided for @svcHTTP401TokenMissingOrInvalid.
  ///
  /// In zh, this message translates to:
  /// **'HTTP 401：令牌缺失或无效'**
  String get svcHTTP401TokenMissingOrInvalid;

  /// No description provided for @svcHTTP403InsufficientBalanceRedeemTokensIn.
  ///
  /// In zh, this message translates to:
  /// **'HTTP 403：余额不足，请先在控制台兑换 Token'**
  String get svcHTTP403InsufficientBalanceRedeemTokensIn;

  /// No description provided for @svcHTTPP0TheGatewayOrUpstreamFailed.
  ///
  /// In zh, this message translates to:
  /// **'HTTP {p0}：网关或上游转发失败'**
  String svcHTTPP0TheGatewayOrUpstreamFailed(String p0);

  /// No description provided for @svcUsedP0Tokens.
  ///
  /// In zh, this message translates to:
  /// **'本次消耗 {p0} Token'**
  String svcUsedP0Tokens(String p0);

  /// No description provided for @svcTheRequestDidNotSucceedNoTokens.
  ///
  /// In zh, this message translates to:
  /// **'业务未成功，按官方规则不扣 Token'**
  String get svcTheRequestDidNotSucceedNoTokens;

  /// No description provided for @svcCouldNotReadTheRefreshSettingsRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新配置读取失败，请手动刷新数据'**
  String get svcCouldNotReadTheRefreshSettingsRefresh;

  /// No description provided for @svcTheRefreshSourceDiffersFromTheSync.
  ///
  /// In zh, this message translates to:
  /// **'刷新来源与同步目标不同，已跳过自动刷新'**
  String get svcTheRefreshSourceDiffersFromTheSync;

  /// No description provided for @svcTheRefreshAccountDiffersFromTheSync.
  ///
  /// In zh, this message translates to:
  /// **'刷新账号与同步目标不同，已跳过自动刷新'**
  String get svcTheRefreshAccountDiffersFromTheSync;

  /// No description provided for @svcTheAccountOrSyncCredentialsChangedAutomatic.
  ///
  /// In zh, this message translates to:
  /// **'账号或同步凭据已变化，已跳过自动刷新'**
  String get svcTheAccountOrSyncCredentialsChangedAutomatic;

  /// No description provided for @svcCouldNotLoadTheGateListRight.
  ///
  /// In zh, this message translates to:
  /// **'门列表暂时无法读取'**
  String get svcCouldNotLoadTheGateListRight;

  /// No description provided for @svcCouldNotLoadTheGuideRightNow.
  ///
  /// In zh, this message translates to:
  /// **'攻略暂时无法读取'**
  String get svcCouldNotLoadTheGuideRightNow;

  /// No description provided for @svcTheGuideDataDoesNotMatch.
  ///
  /// In zh, this message translates to:
  /// **'攻略数据不匹配'**
  String get svcTheGuideDataDoesNotMatch;

  /// No description provided for @svcReadAndAcceptTheUserAgreementAnd.
  ///
  /// In zh, this message translates to:
  /// **'请先阅读并同意用户协议和隐私政策'**
  String get svcReadAndAcceptTheUserAgreementAnd;

  /// No description provided for @svcCouldNotSaveTheOnboardingConfirmationTry.
  ///
  /// In zh, this message translates to:
  /// **'无法保存引导确认记录，请重试'**
  String get svcCouldNotSaveTheOnboardingConfirmationTry;

  /// No description provided for @svcCreatingTheRoomTimedOutCheckYour.
  ///
  /// In zh, this message translates to:
  /// **'创建房间超时，请检查连接后重试'**
  String get svcCreatingTheRoomTimedOutCheckYour;

  /// No description provided for @svcJoiningTheRoomTimedOutCheckThe.
  ///
  /// In zh, this message translates to:
  /// **'加入房间超时，请检查房间码与网络'**
  String get svcJoiningTheRoomTimedOutCheckThe;

  /// No description provided for @svcCouldNotLoadReleaseDataP0.
  ///
  /// In zh, this message translates to:
  /// **'配信数据读取失败 ({p0})'**
  String svcCouldNotLoadReleaseDataP0(String p0);

  /// No description provided for @svcInvalidReleaseData.
  ///
  /// In zh, this message translates to:
  /// **'无效的配信数据'**
  String get svcInvalidReleaseData;

  /// No description provided for @svcInvalidFriendLinkDataFormat.
  ///
  /// In zh, this message translates to:
  /// **'友链数据格式错误'**
  String get svcInvalidFriendLinkDataFormat;

  /// No description provided for @svcSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get svcSaveFailed;

  /// No description provided for @svcCouldNotParseTheRecognitionResultJSON.
  ///
  /// In zh, this message translates to:
  /// **'识别结果 JSON 解析失败：{p0}'**
  String svcCouldNotParseTheRecognitionResultJSON(String p0);

  /// No description provided for @svcRecognitionRequestFailedP0.
  ///
  /// In zh, this message translates to:
  /// **'识别请求失败：{p0}'**
  String svcRecognitionRequestFailedP0(String p0);

  /// No description provided for @gainBelowS.
  ///
  /// In zh, this message translates to:
  /// **'未达 S'**
  String get gainBelowS;

  /// No description provided for @gainRaiseTo.
  ///
  /// In zh, this message translates to:
  /// **'冲上 {p0}'**
  String gainRaiseTo(String p0);

  /// No description provided for @gainWithinGrade.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 档内提分'**
  String gainWithinGrade(String p0);

  /// No description provided for @gainBasisMember.
  ///
  /// In zh, this message translates to:
  /// **'{p0}；{p1} 内单曲 RA {p2}→{p3}'**
  String gainBasisMember(String p0, String p1, String p2, String p3);

  /// No description provided for @gainBasisReplace.
  ///
  /// In zh, this message translates to:
  /// **'{p0}；RA {p1} 顶替 {p2} 最低《{p3}》RA {p4}'**
  String gainBasisReplace(
      String p0, String p1, String p2, String p3, String p4);

  /// No description provided for @gainBasisFill.
  ///
  /// In zh, this message translates to:
  /// **'{p0}；RA {p1} 补入 {p2} 空位'**
  String gainBasisFill(String p0, String p1, String p2);

  /// No description provided for @gainNetGainReason.
  ///
  /// In zh, this message translates to:
  /// **'独立净收益+{p0}（{p1}）'**
  String gainNetGainReason(String p0, String p1);

  /// No description provided for @gainExploreReason.
  ///
  /// In zh, this message translates to:
  /// **'个人同档最佳成绩中位参考 {p0}% · 独立净收益+{p1}（条件估算；不是下次成功率）'**
  String gainExploreReason(String p0, String p1);

  /// No description provided for @gainAlternativeChallenge.
  ///
  /// In zh, this message translates to:
  /// **'；挑战可选 {p0}%（独立净收益+{p1}，不与稳妥目标累加）'**
  String gainAlternativeChallenge(String p0, String p1);

  /// No description provided for @gainFillNoteExhausted.
  ///
  /// In zh, this message translates to:
  /// **'合格未见候选 {p0} 条，已全部耗尽'**
  String gainFillNoteExhausted(String p0);

  /// No description provided for @gainFillNoteFiltered.
  ///
  /// In zh, this message translates to:
  /// **'合格未见候选 {p0} 条，其余被反馈/资格过滤'**
  String gainFillNoteFiltered(String p0);

  /// No description provided for @accountAuthorizeLXNS.
  ///
  /// In zh, this message translates to:
  /// **'落雪账号授权'**
  String get accountAuthorizeLXNS;

  /// No description provided for @accountLinkAWMC.
  ///
  /// In zh, this message translates to:
  /// **'绑定 AWMC NET 账号'**
  String get accountLinkAWMC;

  /// No description provided for @accountSwitchCachedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'切换数据源与玩家信息，使用本地缓存'**
  String get accountSwitchCachedSubtitle;

  /// No description provided for @accountAuthorizeLXNSSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理落雪成绩读取授权'**
  String get accountAuthorizeLXNSSubtitle;

  /// No description provided for @accountLinkAWMCSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设置 AWMC NET 成绩查询 QQ'**
  String get accountLinkAWMCSubtitle;

  /// No description provided for @accountCabinetIdentitySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'绑定快速同步共用的机台身份'**
  String get accountCabinetIdentitySubtitle;

  /// No description provided for @accountAuthorizeLXNSFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先在「我的 → 账号与授权 → 绑定与授权管理」完成落雪授权'**
  String get accountAuthorizeLXNSFirst;

  /// No description provided for @accountLinkAWMCFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先在「我的 → 账号与授权 → 绑定与授权管理」绑定 AWMC NET 账号'**
  String get accountLinkAWMCFirst;

  /// No description provided for @accountConfigurationSaved.
  ///
  /// In zh, this message translates to:
  /// **'账号配置已保存，可通过刷新数据更新成绩'**
  String get accountConfigurationSaved;

  /// No description provided for @accountAuthorizationFailed.
  ///
  /// In zh, this message translates to:
  /// **'授权或保存失败，请检查网络与输入后重试'**
  String get accountAuthorizationFailed;

  /// No description provided for @accountLXNSAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'落雪账号已授权'**
  String get accountLXNSAuthorized;

  /// No description provided for @accountLXNSAuthorizedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'已授权，可刷新成绩；点击可重新授权'**
  String get accountLXNSAuthorizedSubtitle;

  /// No description provided for @accountAWMCLinked.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET 账号已绑定'**
  String get accountAWMCLinked;

  /// No description provided for @accountAWMCLinkedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'已绑定 QQ：{qq}；点击可更换账号'**
  String accountAWMCLinkedSubtitle(String qq);

  /// No description provided for @accountCabinetLinkedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'快速同步身份已保存，点击可重新绑定'**
  String get accountCabinetLinkedSubtitle;

  /// No description provided for @accountBindingManage.
  ///
  /// In zh, this message translates to:
  /// **'绑定与授权管理'**
  String get accountBindingManage;

  /// No description provided for @accountBindingManageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'登录、授权与绑定各数据源账号'**
  String get accountBindingManageSubtitle;

  /// No description provided for @accountBindingScoreHub.
  ///
  /// In zh, this message translates to:
  /// **'maimai Score Hub'**
  String get accountBindingScoreHub;

  /// No description provided for @accountBindingDivingFish.
  ///
  /// In zh, this message translates to:
  /// **'水鱼'**
  String get accountBindingDivingFish;

  /// No description provided for @accountBindingLxns.
  ///
  /// In zh, this message translates to:
  /// **'落雪'**
  String get accountBindingLxns;

  /// No description provided for @accountBindingAwmc.
  ///
  /// In zh, this message translates to:
  /// **'AWMC NET'**
  String get accountBindingAwmc;

  /// No description provided for @accountBindingCabinet.
  ///
  /// In zh, this message translates to:
  /// **'机台身份'**
  String get accountBindingCabinet;

  /// No description provided for @accountBindingSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'已登录'**
  String get accountBindingSignedIn;

  /// No description provided for @accountBindingSignedOut.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get accountBindingSignedOut;

  /// No description provided for @accountBindingAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'已授权'**
  String get accountBindingAuthorized;

  /// No description provided for @accountBindingUnauthorized.
  ///
  /// In zh, this message translates to:
  /// **'未授权'**
  String get accountBindingUnauthorized;

  /// No description provided for @accountBindingLinked.
  ///
  /// In zh, this message translates to:
  /// **'已绑定'**
  String get accountBindingLinked;

  /// No description provided for @accountBindingUnlinked.
  ///
  /// In zh, this message translates to:
  /// **'未绑定'**
  String get accountBindingUnlinked;

  /// No description provided for @accountBindingDivingFishAuth.
  ///
  /// In zh, this message translates to:
  /// **'水鱼授权'**
  String get accountBindingDivingFishAuth;

  /// No description provided for @accountBindingUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get accountBindingUnknown;

  /// No description provided for @accountBindingRecheck.
  ///
  /// In zh, this message translates to:
  /// **'重新检查'**
  String get accountBindingRecheck;

  /// No description provided for @syncDialogMode.
  ///
  /// In zh, this message translates to:
  /// **'同步方式'**
  String get syncDialogMode;

  /// No description provided for @syncDialogQrCode.
  ///
  /// In zh, this message translates to:
  /// **'机台二维码'**
  String get syncDialogQrCode;

  /// No description provided for @languageTranslationDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'除简体中文外，其他语言的界面文案为翻译文本，可能存在不准确或不自然的表达；含义不一致时以简体中文为准。歌曲资料、服务端原文和用户内容不做翻译。发现翻译问题欢迎通过「问题反馈」告诉我们。'**
  String get languageTranslationDisclaimer;

  /// No description provided for @accountSwitchSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存账号'**
  String get accountSwitchSaved;

  /// No description provided for @accountSwitchNotSaved.
  ///
  /// In zh, this message translates to:
  /// **'未保存账号'**
  String get accountSwitchNotSaved;

  /// No description provided for @accountSwitchCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前使用中'**
  String get accountSwitchCurrent;

  /// No description provided for @customTagTitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义标签'**
  String get customTagTitle;

  /// No description provided for @customTagFeatureSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义标签名称、颜色与谱面，接入标签筛选与统计'**
  String get customTagFeatureSubtitle;

  /// No description provided for @customTagGroupName.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get customTagGroupName;

  /// No description provided for @customTagIntro.
  ///
  /// In zh, this message translates to:
  /// **'自定义标签会与谱面标签一起出现在乐曲查询的标签筛选、谱面详情、Best50 / 收藏夹的标签统计和个性化 Best50 的「标签50」中。标签只保存在本机，随数据备份导出。'**
  String get customTagIntro;

  /// No description provided for @customTagCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建标签'**
  String get customTagCreate;

  /// No description provided for @customTagEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑标签'**
  String get customTagEdit;

  /// No description provided for @customTagName.
  ///
  /// In zh, this message translates to:
  /// **'标签名称'**
  String get customTagName;

  /// No description provided for @customTagColor.
  ///
  /// In zh, this message translates to:
  /// **'标签颜色'**
  String get customTagColor;

  /// No description provided for @customTagHue.
  ///
  /// In zh, this message translates to:
  /// **'色相'**
  String get customTagHue;

  /// No description provided for @customTagPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get customTagPreview;

  /// No description provided for @customTagNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入标签名称'**
  String get customTagNameRequired;

  /// No description provided for @customTagNameDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'已有同名标签'**
  String get customTagNameDuplicate;

  /// No description provided for @customTagSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存自定义标签失败，请重试'**
  String get customTagSaveFailed;

  /// No description provided for @customTagForChart.
  ///
  /// In zh, this message translates to:
  /// **'为谱面添加自定义标签'**
  String get customTagForChart;

  /// No description provided for @customTagEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有自定义标签，先新建一个吧。'**
  String get customTagEmpty;

  /// No description provided for @customTagAddToChart.
  ///
  /// In zh, this message translates to:
  /// **'添加自定义标签'**
  String get customTagAddToChart;

  /// No description provided for @customTagManage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get customTagManage;

  /// No description provided for @customTagSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'输入歌名、别名、曲师或 ID 搜索'**
  String get customTagSearchHint;

  /// No description provided for @customTagNoSongs.
  ///
  /// In zh, this message translates to:
  /// **'没有找到歌曲'**
  String get customTagNoSongs;

  /// No description provided for @customTagChooseDifficulties.
  ///
  /// In zh, this message translates to:
  /// **'选择难度'**
  String get customTagChooseDifficulties;

  /// No description provided for @customTagAddCharts.
  ///
  /// In zh, this message translates to:
  /// **'添加谱面'**
  String get customTagAddCharts;

  /// No description provided for @customTagRemoveChart.
  ///
  /// In zh, this message translates to:
  /// **'移出此标签'**
  String get customTagRemoveChart;

  /// No description provided for @customTagDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get customTagDelete;

  /// No description provided for @customTagDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除标签'**
  String get customTagDeleteTitle;

  /// No description provided for @customTagChartCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 张谱面'**
  String customTagChartCount(int count);

  /// No description provided for @customTagDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」后，它会从所有谱面上移除，且无法恢复。'**
  String customTagDeleteMessage(String name);

  /// No description provided for @accountSwitchCurrentLabel.
  ///
  /// In zh, this message translates to:
  /// **'当前：{name}'**
  String accountSwitchCurrentLabel(String name);

  /// No description provided for @customTagMarked.
  ///
  /// In zh, this message translates to:
  /// **'{name}（自定义）'**
  String customTagMarked(String name);

  /// No description provided for @chartCodeFont.
  ///
  /// In zh, this message translates to:
  /// **'代码字体'**
  String get chartCodeFont;

  /// No description provided for @chartCodeFontDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get chartCodeFontDefault;

  /// No description provided for @chartCodeFontSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'字体已切换，但未能保存选择'**
  String get chartCodeFontSaveFailed;

  /// No description provided for @ratingSegmentTitle.
  ///
  /// In zh, this message translates to:
  /// **'上分潜力与对照表分段'**
  String get ratingSegmentTitle;

  /// No description provided for @ratingSegmentStandard.
  ///
  /// In zh, this message translates to:
  /// **'常用分段'**
  String get ratingSegmentStandard;

  /// No description provided for @ratingSegmentDetailed.
  ///
  /// In zh, this message translates to:
  /// **'详细分段'**
  String get ratingSegmentDetailed;

  /// No description provided for @ratingSegmentStandardHint.
  ///
  /// In zh, this message translates to:
  /// **'只显示各评级对应的达成率分段。'**
  String get ratingSegmentStandardHint;

  /// No description provided for @ratingSegmentDetailedHint.
  ///
  /// In zh, this message translates to:
  /// **'在评级分段之外，再细分每提升 1 Rating 需要的达成率。'**
  String get ratingSegmentDetailedHint;

  /// No description provided for @searchAvoidKeyboard.
  ///
  /// In zh, this message translates to:
  /// **'搜索区域避让输入法'**
  String get searchAvoidKeyboard;

  /// No description provided for @searchAvoidKeyboardHint.
  ///
  /// In zh, this message translates to:
  /// **'首页搜索、乐曲查询、非国服乐曲查询和成绩查询时，结果可以完整滚动到输入法上方；背景不会被挤压。'**
  String get searchAvoidKeyboardHint;

  /// No description provided for @arcadeTabInView.
  ///
  /// In zh, this message translates to:
  /// **'视野内'**
  String get arcadeTabInView;

  /// No description provided for @arcadeTabFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get arcadeTabFavorites;

  /// No description provided for @arcadeOpenNow.
  ///
  /// In zh, this message translates to:
  /// **'营业中'**
  String get arcadeOpenNow;

  /// No description provided for @arcadeClosedNow.
  ///
  /// In zh, this message translates to:
  /// **'已打烊'**
  String get arcadeClosedNow;

  /// No description provided for @arcadeHoursUnknown.
  ///
  /// In zh, this message translates to:
  /// **'营业时间未知'**
  String get arcadeHoursUnknown;

  /// No description provided for @arcadeClosesAt.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 打烊'**
  String arcadeClosesAt(String p0);

  /// No description provided for @arcadeOpensAt.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 开门'**
  String arcadeOpensAt(String p0);

  /// No description provided for @arcadeOpensTomorrowAt.
  ///
  /// In zh, this message translates to:
  /// **'明天 {p0} 开门'**
  String arcadeOpensTomorrowAt(String p0);

  /// No description provided for @arcadeClearFilters.
  ///
  /// In zh, this message translates to:
  /// **'清除筛选'**
  String get arcadeClearFilters;

  /// No description provided for @arcadeRandomPick.
  ///
  /// In zh, this message translates to:
  /// **'随机挑一家'**
  String get arcadeRandomPick;

  /// No description provided for @arcadeRandomEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前范围内没有可挑选的机厅'**
  String get arcadeRandomEmpty;

  /// No description provided for @arcadeZoomIn.
  ///
  /// In zh, this message translates to:
  /// **'放大'**
  String get arcadeZoomIn;

  /// No description provided for @arcadeZoomOut.
  ///
  /// In zh, this message translates to:
  /// **'缩小'**
  String get arcadeZoomOut;

  /// No description provided for @arcadeResetNorth.
  ///
  /// In zh, this message translates to:
  /// **'朝北'**
  String get arcadeResetNorth;

  /// No description provided for @arcadeLocate.
  ///
  /// In zh, this message translates to:
  /// **'定位到我'**
  String get arcadeLocate;

  /// No description provided for @arcadeRegions.
  ///
  /// In zh, this message translates to:
  /// **'全球分布'**
  String get arcadeRegions;

  /// No description provided for @arcadeRegionCount.
  ///
  /// In zh, this message translates to:
  /// **'国家和地区'**
  String get arcadeRegionCount;

  /// No description provided for @arcadeShopCount.
  ///
  /// In zh, this message translates to:
  /// **'机厅'**
  String get arcadeShopCount;

  /// No description provided for @arcadeMachineCount.
  ///
  /// In zh, this message translates to:
  /// **'机台'**
  String get arcadeMachineCount;

  /// No description provided for @arcadeDownloadData.
  ///
  /// In zh, this message translates to:
  /// **'下载机厅数据'**
  String get arcadeDownloadData;

  /// No description provided for @arcadeNoDataHint.
  ///
  /// In zh, this message translates to:
  /// **'下载后可以离线浏览机厅信息。'**
  String get arcadeNoDataHint;

  /// No description provided for @arcadeUpdating.
  ///
  /// In zh, this message translates to:
  /// **'正在更新 {p0} / {p1}'**
  String arcadeUpdating(String p0, String p1);

  /// No description provided for @arcadeUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败，已保留当前数据'**
  String get arcadeUpdateFailed;

  /// No description provided for @arcadeNoMatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的机厅'**
  String get arcadeNoMatchTitle;

  /// No description provided for @arcadeNoMatchHint.
  ///
  /// In zh, this message translates to:
  /// **'换个筛选条件，或者移动一下地图吧。'**
  String get arcadeNoMatchHint;

  /// No description provided for @arcadeNoFavoritesTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有收藏的机厅'**
  String get arcadeNoFavoritesTitle;

  /// No description provided for @arcadeNoFavoritesHint.
  ///
  /// In zh, this message translates to:
  /// **'点星标收藏常去的机厅，就能在这里找到它们。'**
  String get arcadeNoFavoritesHint;

  /// No description provided for @arcadeNeedsUpdateToFavorite.
  ///
  /// In zh, this message translates to:
  /// **'请先更新机厅数据，才能收藏机厅'**
  String get arcadeNeedsUpdateToFavorite;

  /// No description provided for @arcadeLegacyHint.
  ///
  /// In zh, this message translates to:
  /// **'机厅数据是旧版本，更新后可以收藏机厅并查看地铁信息。'**
  String get arcadeLegacyHint;

  /// No description provided for @arcadeNavigate.
  ///
  /// In zh, this message translates to:
  /// **'导航'**
  String get arcadeNavigate;

  /// No description provided for @arcadeCopyAddress.
  ///
  /// In zh, this message translates to:
  /// **'复制地址'**
  String get arcadeCopyAddress;

  /// No description provided for @arcadeViewOnNearcade.
  ///
  /// In zh, this message translates to:
  /// **'在 nearcade 查看'**
  String get arcadeViewOnNearcade;

  /// No description provided for @arcadeCouldNotOpenLink.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接'**
  String get arcadeCouldNotOpenLink;

  /// No description provided for @arcadeHours.
  ///
  /// In zh, this message translates to:
  /// **'营业时间'**
  String get arcadeHours;

  /// No description provided for @arcadeEveryDay.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get arcadeEveryDay;

  /// No description provided for @arcadeToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get arcadeToday;

  /// No description provided for @arcadeMetroWalk.
  ///
  /// In zh, this message translates to:
  /// **'{p0}站 · 步行约 {p1} 分钟'**
  String arcadeMetroWalk(String p0, String p1);

  /// No description provided for @arcadeMetroStation.
  ///
  /// In zh, this message translates to:
  /// **'{p0}站'**
  String arcadeMetroStation(String p0);

  /// No description provided for @arcadeNote.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get arcadeNote;

  /// No description provided for @arcadeFromYou.
  ///
  /// In zh, this message translates to:
  /// **'距你 {p0}'**
  String arcadeFromYou(String p0);

  /// No description provided for @arcadeFilterAction.
  ///
  /// In zh, this message translates to:
  /// **'筛选'**
  String get arcadeFilterAction;

  /// No description provided for @arcadeFilterSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索机台'**
  String get arcadeFilterSearchHint;

  /// No description provided for @arcadeFilterEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的机台'**
  String get arcadeFilterEmpty;

  /// No description provided for @arcadeChooseMapApp.
  ///
  /// In zh, this message translates to:
  /// **'选择地图应用'**
  String get arcadeChooseMapApp;

  /// No description provided for @arcadeMapAmap.
  ///
  /// In zh, this message translates to:
  /// **'高德地图'**
  String get arcadeMapAmap;

  /// No description provided for @arcadeMapBaidu.
  ///
  /// In zh, this message translates to:
  /// **'百度地图'**
  String get arcadeMapBaidu;

  /// No description provided for @arcadeMapTencent.
  ///
  /// In zh, this message translates to:
  /// **'腾讯地图'**
  String get arcadeMapTencent;

  /// No description provided for @arcadeMapGoogle.
  ///
  /// In zh, this message translates to:
  /// **'Google 地图'**
  String get arcadeMapGoogle;

  /// No description provided for @arcadeMapApple.
  ///
  /// In zh, this message translates to:
  /// **'Apple 地图'**
  String get arcadeMapApple;

  /// No description provided for @arcadeMapOther.
  ///
  /// In zh, this message translates to:
  /// **'其他地图应用'**
  String get arcadeMapOther;

  /// No description provided for @arcadeMapWeb.
  ///
  /// In zh, this message translates to:
  /// **'在浏览器中打开'**
  String get arcadeMapWeb;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
