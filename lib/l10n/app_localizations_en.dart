// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get autoUpdateSuccessTitle => 'Automatic update complete';

  @override
  String get autoUpdateSuccessBody =>
      'ChiffonMai has finished updating in the background and is ready to use.';

  @override
  String get autoUpdateChangesTitle => 'What\'s new in this update';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Display';

  @override
  String get interaction => 'Controls';

  @override
  String get effects => 'Effects';

  @override
  String get other => 'Other';

  @override
  String get language => 'Language';

  @override
  String get followSystem => 'System';

  @override
  String get languageDescription =>
      'The interface, messages, and system notifications support multiple languages. Song data, server text, and user content stay in their original language. Changes apply immediately.';

  @override
  String get languageSaveFailed =>
      'Could not save the language. Please try again.';

  @override
  String get homeSearchScope => 'Home search scope';

  @override
  String get searchFeatures => 'Features';

  @override
  String get searchSongs => 'Songs';

  @override
  String get searchBoth => 'Both';

  @override
  String get searchMode => 'Search mode';

  @override
  String get searchInline => 'Inline';

  @override
  String get searchOverlay => 'Expanded';

  @override
  String get searchOverlayHint =>
      'Open an expanded search view for features and songs.';

  @override
  String get searchInlineHint =>
      'Type in the original search field, with song search history below it.';

  @override
  String get showMatchInfo => 'Show matching fields';

  @override
  String get showMatchInfoHint =>
      'Show matching chart constants, BPM, tags and other fields in song results.';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get themeColor => 'Theme color';

  @override
  String get backgroundImage => 'Background image';

  @override
  String get decorationImage => 'Decorative image';

  @override
  String get pureBlackBackgroundDisabled =>
      'Background and decorative images cannot be adjusted in pure black mode.';

  @override
  String get reading => 'Reading…';

  @override
  String get useSystemWallpaperColor => 'Use wallpaper colors';

  @override
  String get systemWallpaperHint =>
      'On Android 12 or later, apply the current system wallpaper colors to the app theme.';

  @override
  String get wallpaperColorUnsupported =>
      'Wallpaper colors require Android 12 or later.';

  @override
  String get wallpaperColorApplied => 'Wallpaper colors applied.';

  @override
  String get wallpaperColorFailed =>
      'Could not read wallpaper colors. Please try again later.';

  @override
  String get wallpaperApplied => 'Wallpaper set.';

  @override
  String get wallpaperAndThemeApplied =>
      'Wallpaper set and theme color updated.';

  @override
  String get backgroundReset => 'Default background restored.';

  @override
  String get themeColorUpdated => 'Theme color updated.';

  @override
  String get themeColorReset => 'Default theme color restored.';

  @override
  String get navigationExperience => 'Navigation';

  @override
  String get searchInteraction => 'Search behavior';

  @override
  String get confetti => 'Confetti';

  @override
  String get appUpdate => 'App updates';

  @override
  String get featureGuide => 'Feature guide';

  @override
  String get featureGuideHint =>
      'Reopen the guide whenever you want a tour of the app\'s features.';

  @override
  String get reopenGuide => 'Reopen feature guide';

  @override
  String get preview => 'Preview';

  @override
  String get primaryButton => 'Primary button';

  @override
  String get primaryColor => 'Primary';

  @override
  String get secondaryColor => 'Secondary';

  @override
  String get tertiaryColor => 'Accent';

  @override
  String get surfaceColor => 'Surface';

  @override
  String get customColor => 'Custom color';

  @override
  String get restoreDefaults => 'Reset';

  @override
  String get builtInBackground => 'Current: built-in image';

  @override
  String get customBackground => 'Current: custom image';

  @override
  String get processing => 'Processing…';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get decorationOpacity => 'Chiffon image opacity';

  @override
  String get decorationOpacityHint =>
      'Default: 40%. Hidden in pure black mode; light and dark themes share this value.';

  @override
  String get hide => 'Hide';

  @override
  String get favoriteExportExtension => 'Favorites file extension';

  @override
  String get syncAndGateway => 'Sync and gateway';

  @override
  String get gatewayTimeout => 'AWMC gateway timeout';

  @override
  String get gatewayTimeoutHint =>
      'Route 1 checks GET /v1/health before syncing. If it times out, sync is cancelled without spending tokens.';

  @override
  String get gatewayTimeoutDialogHint =>
      'Route 1 checks GET /v1/health before syncing. If the gateway does not respond in time, sync is cancelled without spending tokens.';

  @override
  String get enterIntegerSeconds => 'Enter a whole number of seconds.';

  @override
  String get timeout => 'Timeout';

  @override
  String get secondsUnit => 's';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'OK';

  @override
  String get backgroundOpacity => 'Background overlay';

  @override
  String get backgroundDarkHint =>
      'Higher values darken the background; 0% shows the original image.';

  @override
  String get backgroundLightHint =>
      'Higher values fade the background; 0% shows the original image.';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get pureBlack => 'Pure black';

  @override
  String get pureBlackHint =>
      'Use a true black background and hide the background image.';

  @override
  String get navigationStyle => 'Navigation bar style';

  @override
  String get navigationClassic => 'Classic';

  @override
  String get navigationGlass => 'Glass';

  @override
  String get navigationPill => 'Pill';

  @override
  String get navigationClassicHint =>
      'Show every category name below its icon.';

  @override
  String get navigationGlassHint =>
      'Translucent glass with a soft highlight on the selected item.';

  @override
  String get navigationPillHint =>
      'Expand the selected label and keep other items as icons, with smooth transitions.';

  @override
  String get navigationAnimation => 'Navigation animations';

  @override
  String get navigationAnimationHint =>
      'Slide and fade between main pages and animate icon states.';

  @override
  String get swipeNavigation => 'Swipe between main pages';

  @override
  String get swipeNavigationHint =>
      'Swipe horizontally over the main content to switch navigation tabs.';

  @override
  String get immersiveStatusBar => 'Hide status bar';

  @override
  String get immersiveStatusBarHint =>
      'Hide the clock and battery indicators while keeping system navigation.';

  @override
  String get busyHint => 'Busy task hints';

  @override
  String get busyHintDescription =>
      'Explain unavailable actions in red while sync or refresh tasks are running.';

  @override
  String get customHarmonyColor => 'Custom harmony color';

  @override
  String get confettiHint =>
      'Show confetti after refreshing data or syncing scores successfully.';

  @override
  String get gravityEffect => 'Gravity';

  @override
  String get gravityEffectHint =>
      'Confetti follows an arc and falls back after being launched upward.';

  @override
  String get harmonyColor => 'Harmony color';

  @override
  String get harmonyLevel => 'Harmony strength';

  @override
  String get harmonyHint =>
      'Higher values blend confetti toward the harmony color; 0% keeps vivid multicolor effects.';

  @override
  String get paperType => 'Confetti shape';

  @override
  String get paperMixed => 'Mixed';

  @override
  String get paperSquare => 'Squares';

  @override
  String get paperCircle => 'Circles';

  @override
  String get paperRibbon => 'Ribbons';

  @override
  String get burstPosition => 'Burst position';

  @override
  String get burstTopBottom => 'Top and bottom';

  @override
  String get burstLeftRight => 'Left and right';

  @override
  String get burstAllEdges => 'All edges';

  @override
  String get previewNow => 'Preview now';

  @override
  String get defaultDifficulty => 'Default song difficulty';

  @override
  String get defaultDifficultyHint =>
      'Use this difficulty when opening a song without an explicitly selected chart difficulty.';

  @override
  String get defaultDifficultyNote =>
      'Defaults to MASTER on first use. Links from scores or charts that specify a difficulty keep that difficulty.';

  @override
  String get settingSaveFailed =>
      'Could not save the setting. Please try again.';

  @override
  String get autoInstall => 'Install updates automatically';

  @override
  String get experimental => 'Experimental';

  @override
  String get autoInstallHint =>
      'Off by default; updates are not downloaded automatically. Applies only to downloads you start in the app. After verification, a foreground prompt lets you confirm before the app moves to the background to attempt installation. In the background, installation is attempted after 8 seconds without sync, refresh, import, export or download tasks. Starting a task or returning to the app resets the timer.';

  @override
  String get autoInstallNote =>
      'Requires Android 12 or later and permission to install apps from this source. Music playback or calls postpone installation; locking the screen is not required. System scheduling may delay installation, and some devices still require confirmation. Manual installation remains available. Installation ends the old process. Disabling this option cannot undo installation once the system has started it.';

  @override
  String get autoInstallUnsupported =>
      'This system does not support this experimental feature. Install updates manually.';

  @override
  String get allowInstallSource => 'Allow app installation';

  @override
  String get autoInstallSettingsError =>
      'Could not apply automatic installation settings. Retry or check installation permissions.';

  @override
  String get reloadSettings => 'Reload settings';

  @override
  String get hexFormatError => 'Use #RRGGBB or #AARRGGBB.';

  @override
  String get enterHexColor => 'Enter hex color';

  @override
  String get hexColorHint => '#RRGGBB or #AARRGGBB';

  @override
  String get hue => 'Hue';

  @override
  String get colorPickerHint =>
      'Drag in the square above, or enter a hex color.';

  @override
  String get enterHex => 'Enter hex';

  @override
  String get wallpaperCropHint =>
      'Pinch to zoom and drag to frame your wallpaper.';

  @override
  String get wallpaperReadFailed =>
      'Could not read this image. Its format may not be supported on this system.';

  @override
  String get wallpaperCropFailed =>
      'Could not crop the image. Please try again.';

  @override
  String get setWallpaper => 'Set wallpaper';

  @override
  String picturePickFailed(String error) {
    return 'Could not select the image: $error';
  }

  @override
  String exportDescription(String extension) {
    return 'Exported favorites are saved as <name>$extension in Download/ChiffonMai/收藏夹/, accessible from a file manager.\nThe extension is fixed to avoid taking over other formats.\nImports are identified by their contents, so older backups with different extensions still work.';
  }

  @override
  String secondsValue(int seconds) {
    return '$seconds s';
  }

  @override
  String gatewayTimeoutSemantics(int seconds) {
    return 'AWMC gateway timeout, currently $seconds seconds';
  }

  @override
  String gatewayTimeoutSaved(int seconds) {
    return 'AWMC gateway timeout set to $seconds seconds.';
  }

  @override
  String allowedSeconds(int min, int max) {
    return 'Use $min–$max seconds.';
  }

  @override
  String defaultSecondsHint(int defaultSeconds, int min, int max) {
    return 'Default: $defaultSeconds s. Range: $min–$max s.';
  }

  @override
  String get foregroundUpdateTitle => 'Update ready';

  @override
  String get foregroundUpdateBody =>
      'The update has been verified. Choosing “Leave and update” moves the app to the background and attempts installation. Installation closes the app, so save your work first. Reopen the app after the update.';

  @override
  String get foregroundUpdateLaterHint =>
      'Choose “Later” to keep using the app. Automatic installation will still be attempted after 8 seconds in the background with no active tasks. Some devices may require confirmation.';

  @override
  String get foregroundUpdateBusy =>
      'Finish active tasks or playback before updating.';

  @override
  String get foregroundUpdateChanged =>
      'The download or task status has changed. Check the update again before installing.';

  @override
  String get foregroundUpdateFailed =>
      'Could not start the update. Try again later or install manually from the update window.';

  @override
  String get updateLater => 'Later';

  @override
  String get exitAndUpdate => 'Leave and update';

  @override
  String get featureSongSearch => 'Song search';

  @override
  String get featureSearchTheChinaAndInternationalLibraries =>
      'Search the China and international libraries';

  @override
  String get featureVersionsAndLibraryAnalysis =>
      'Versions and library analysis';

  @override
  String get featureVersionDetailsUpdateComparisonsAndChartConstants =>
      'Version details, update comparisons and chart constants';

  @override
  String get featureImageRecognition => 'Image recognition';

  @override
  String get featureFindSongsByCoverArtAndRead =>
      'Find songs by cover art and read result screens';

  @override
  String get featureCollectibles => 'Collectibles';

  @override
  String get featureBrowseIconsNameplatesAndOtherCollectibles =>
      'Browse icons, nameplates and other collectibles';

  @override
  String get featureSearchAndFilter => 'Search and filter';

  @override
  String get featureBrowseScoresAndFilterChartResults =>
      'Browse scores and filter chart results';

  @override
  String get featureGrowthAndComparison => 'Growth and comparison';

  @override
  String get featureReviewImprovementsAndCompareWithFriends =>
      'Review improvements and compare with friends';

  @override
  String get featureBest50Overview => 'Best50 overview';

  @override
  String get featureCurrentPerformanceAndFittedPotential =>
      'Current performance and fitted potential';

  @override
  String get featurePersonalizedAnalysis => 'Personalized analysis';

  @override
  String get featureFilterBest50ByTagsAndConditions =>
      'Filter Best50 by tags and conditions';

  @override
  String get featureGoalsAndScoreCards => 'Goals and score cards';

  @override
  String get featureSimulateIdealScoresAndCreateCustomScore =>
      'Simulate ideal scores and create custom score cards';

  @override
  String get featureRatingRankings => 'Rating rankings';

  @override
  String get featureOfficialAndFittedRatingRankings =>
      'Official and fitted Rating rankings';

  @override
  String get featureAchievementRankings => 'Achievement rankings';

  @override
  String get featureCompareAveragePerformanceAcrossAllScores =>
      'Compare average performance across all scores';

  @override
  String get featureSpecialRankings => 'Special rankings';

  @override
  String get featureExplorePlayerStatisticsFromDifferentAngles =>
      'Explore player statistics from different angles';

  @override
  String get featureProgressAndChallenges => 'Progress and challenges';

  @override
  String get featureVersionTitlesRanksAndKALEIDXSCOPE =>
      'Version titles, ranks and KALEIDXSCOPE';

  @override
  String get featureCalculators => 'Calculators';

  @override
  String get featureRatingAchievementAndJudgementAnalysis =>
      'Rating, achievement and judgement analysis';

  @override
  String get featureRandomPicks => 'Random picks';

  @override
  String get featureDecideWhatToPlayToday => 'Decide what to play today';

  @override
  String get featurePracticeRecommendations => 'Practice recommendations';

  @override
  String get featureChooseChartsByGainTagsGoalsOr =>
      'Choose charts by gain, tags, goals or constants';

  @override
  String get featureFavoritesAndPlayQueue => 'Favorites and play queue';

  @override
  String get featureOrganizeChartsForYourNextArcadeVisit =>
      'Organize charts for your next arcade visit';

  @override
  String get featureArcadeMaps => 'Arcade maps';

  @override
  String get featureFindRhythmGameArcadesInChinaAnd =>
      'Find rhythm game arcades in China and worldwide';

  @override
  String get featureSoloGameSettings => 'Solo game settings';

  @override
  String get featureManageSharedRulesAndModePreferences =>
      'Manage shared rules and mode preferences';

  @override
  String get featureTextClues => 'Text clues';

  @override
  String get featureGuessSongsFromMemoryAliasesAndLetters =>
      'Guess songs from memory, aliases and letters';

  @override
  String get featureCoverArtChallenges => 'Cover art challenges';

  @override
  String get featureTryCroppedPixelatedBlurredFlashAndPuzzle =>
      'Try cropped, pixelated, blurred, flash and puzzle covers';

  @override
  String get featureAudioChallenges => 'Audio challenges';

  @override
  String get featureIdentifyNormalReversedOrPitchShiftedClips =>
      'Identify normal, reversed or pitch-shifted clips';

  @override
  String get featureChartChallenges => 'Chart challenges';

  @override
  String get featureGuessSongsFromSilentChartClips =>
      'Guess songs from silent chart clips';

  @override
  String get featureMultiplayer => 'Multiplayer';

  @override
  String get featureChallengeTheSongLibraryWithFriends =>
      'Challenge the song library with friends';

  @override
  String get featureMusicAndChartPlayback => 'Music and chart playback';

  @override
  String get featureListenToMaimaiSongsAndPlayCustom =>
      'Listen to maimai songs and play custom charts';

  @override
  String get featureAccountsAndAuthorization => 'Accounts and authorization';

  @override
  String get featureManageAccountsAndDataSourceSignIns =>
      'Manage accounts and data source sign-ins';

  @override
  String get featureSinglePlatformSync => 'Single-platform sync';

  @override
  String get featureSyncScoresToEachScoreTracker =>
      'Sync scores to each score tracker';

  @override
  String get featureBatchAndScheduledSync => 'Batch and scheduled sync';

  @override
  String get featureSyncToMultiplePlatformsOrAutomatically =>
      'Sync to multiple platforms or automatically';

  @override
  String get featureRefreshData => 'Refresh data';

  @override
  String get featureUpdateCachedScoresAndCabinetPlayCounts =>
      'Update cached scores and cabinet play counts';

  @override
  String get featureLocalData => 'Local data';

  @override
  String get featureBackUpDataAndManageLocalCaches =>
      'Back up data and manage local caches';

  @override
  String get featureAppPreferences => 'App preferences';

  @override
  String get featureThemeInteractionsAndLoadingQuotes =>
      'Theme, interactions and loading quotes';

  @override
  String get featureDiagnostics => 'Diagnostics';

  @override
  String get featureCheckServicesAndExportLogs =>
      'Check services and export logs';

  @override
  String get featureCommunityActivity => 'Community activity';

  @override
  String get featureBrowseRecentCommentsAndRatings =>
      'Browse recent comments and ratings';

  @override
  String get featureVersionAndProject => 'Version and project';

  @override
  String get featureUpdatesProjectInformationAndLinks =>
      'Updates, project information and links';

  @override
  String get featureFeedbackAndSupport => 'Feedback and support';

  @override
  String get featureReportIssuesShareIdeasAndSupportDevelopment =>
      'Report issues, share ideas and support development';

  @override
  String get featureSongLookup => 'Song lookup';

  @override
  String get featureSearchByTitleAliasCharterOrTag =>
      'Search by title, alias, charter or tag';

  @override
  String get featureInternationalSongLookup => 'International song lookup';

  @override
  String get featureSearchAndFilterTheInternationalLibrary =>
      'Search and filter the international library';

  @override
  String get featureChinaUpdateComparison => 'China update comparison';

  @override
  String get featureFindSongsReleasedInJapanButNot =>
      'Find songs released in Japan but not yet in China';

  @override
  String get featureUpdateCalendar => 'Update calendar';

  @override
  String get featureBrowseChinaChartUpdatesByDate =>
      'Browse China chart updates by date';

  @override
  String get featureVersionComparison => 'Version comparison';

  @override
  String get featureBrowsePlayableSongsByVersion =>
      'Browse playable songs by version';

  @override
  String get featureChartConstantDistribution => 'Chart constant distribution';

  @override
  String get featureViewTheDistributionOfChartConstants =>
      'View the distribution of chart constants';

  @override
  String get featureCoverRecognition => 'Cover recognition';

  @override
  String get featureFindSongsUsingYourCameraOrAn =>
      'Find songs using your camera or an image';

  @override
  String get featureResultScreenRecognition => 'Result screen recognition';

  @override
  String get featurePhotographAResultScreenToReadScores =>
      'Photograph a result screen to read scores';

  @override
  String get featureCollectibleLookup => 'Collectible lookup';

  @override
  String get featureViewIconsNameplatesAndOtherCollectibles =>
      'View icons, nameplates and other collectibles';

  @override
  String get featureScoreLookup => 'Score lookup';

  @override
  String get featureBrowseAndFilterAllPlayRecords =>
      'Browse and filter all play records';

  @override
  String get featureCustomScoreLookup => 'Custom score lookup';

  @override
  String get featureViewScoresByLevelOrCharter =>
      'View scores by level or charter';

  @override
  String get featureScoreImprovementHistory => 'Score improvement history';

  @override
  String get featureReviewDailyChangesToYourBestScores =>
      'Review daily changes to your best scores';

  @override
  String get featureRatingHistory => 'Rating history';

  @override
  String get featureTrackRatingOverTime => 'Track Rating over time';

  @override
  String get featureFriendComparison => 'Friend comparison';

  @override
  String get featureCompareYourScoresWithAFriend =>
      'Compare your scores with a friend';

  @override
  String get featureViewYourCurrentBest35AndBest15 =>
      'View your current Best35 and Best15';

  @override
  String get featureFittedBest50 => 'Fitted Best50';

  @override
  String get featureAnalyzeYourPotentialRatingCeiling =>
      'Analyze your potential Rating ceiling';

  @override
  String get featureCustomBest50Analysis => 'Custom Best50 analysis';

  @override
  String get featureFilterBest50ByTag => 'Filter Best50 by tag';

  @override
  String get featureCustomFittedBest50 => 'Custom fitted Best50';

  @override
  String get featureViewFittedRatingPotentialByTag =>
      'View fitted Rating potential by tag';

  @override
  String get featureIdealBest50 => 'Ideal Best50';

  @override
  String get featureSimulateBest50WithEveryScoreRaisedOne =>
      'Simulate Best50 with every score raised one grade';

  @override
  String get featureCreateBest50 => 'Create Best50';

  @override
  String get featureFillIn50ScoreCardsManually =>
      'Fill in 50 score cards manually';

  @override
  String get featureRatingLeaderboard => 'Rating leaderboard';

  @override
  String get featureViewPlayerRatingRankings => 'View player Rating rankings';

  @override
  String get featureTotalFittedRatingLeaderboard =>
      'Total fitted Rating leaderboard';

  @override
  String get featureCompareFittedTotalRatingWithOfficialBest50 =>
      'Compare fitted total Rating with official Best50';

  @override
  String get featureAverageAchievementLeaderboard =>
      'Average achievement leaderboard';

  @override
  String get featureRankByAverageAchievementAcrossAllScores =>
      'Rank by average achievement across all scores';

  @override
  String get featureAverageDXScoreRateLeaderboard =>
      'Average DX score rate leaderboard';

  @override
  String get featureRankByAverageDXScoreRateAcross =>
      'Rank by average DX score rate across all scores';

  @override
  String get featureSpecialLeaderboards => 'Special leaderboards';

  @override
  String get featureDiscoverInterestingPlayerStatistics =>
      'Discover interesting player statistics';

  @override
  String get featureVersionTitleProgress => 'Version title progress';

  @override
  String get featureViewVersionsAndTargetTitles =>
      'View versions and target titles';

  @override
  String get featureRankTable => 'Rank table';

  @override
  String get featureChallengeYourNextRank => 'Challenge your next rank';

  @override
  String get featureExploreAUniqueMaimaiMode => 'Explore a unique maimai mode';

  @override
  String get featureSongRatingCalculator => 'Song Rating calculator';

  @override
  String get featureCalculateASongRatingFromAchievement =>
      'Calculate a song Rating from achievement';

  @override
  String get featureAchievementCalculator => 'Achievement calculator';

  @override
  String get featureCalculateAchievementFromJudgements =>
      'Calculate achievement from judgements';

  @override
  String get featureReverseAchievementCalculator =>
      'Reverse achievement calculator';

  @override
  String get featureInferBREAKDetailsFromJudgements =>
      'Infer BREAK details from judgements';

  @override
  String get featureDailyRecommendations => 'Daily recommendations';

  @override
  String get featureLetRecommendationsPickYourNextSong =>
      'Let recommendations pick your next song';

  @override
  String get featureRandomSongs => 'Random songs';

  @override
  String get featureDrawACustomNumberOfRandomSongs =>
      'Draw a custom number of random songs';

  @override
  String get featureArcadeRoulette => 'Arcade roulette';

  @override
  String get featureLetARouletteWheelChooseYourSession =>
      'Let a roulette wheel choose your session';

  @override
  String get featureRatingGainRecommendations => 'Rating gain recommendations';

  @override
  String get featureChooseChartsByNetB50GainAlgorithm =>
      'Choose charts by net B50 gain · Algorithm by AWMC';

  @override
  String get featureTagRecommendations => 'Tag recommendations';

  @override
  String get featureFindSongsBasedOnTagsFromYour =>
      'Find songs based on tags from your played charts';

  @override
  String get featureTargetRatingRecommendations =>
      'Target Rating recommendations';

  @override
  String get featureFindChartsThatCanRaiseYourRating =>
      'Find charts that can raise your Rating';

  @override
  String get featureConstantRangeRecommendations =>
      'Constant range recommendations';

  @override
  String get featureChooseChartsWithinAConstantRange =>
      'Choose charts within a constant range';

  @override
  String get featureFavoriteFolders => 'Favorite folders';

  @override
  String get featureManageYourFavoriteCharts => 'Manage your favorite charts';

  @override
  String get featurePlayNext => 'Play next';

  @override
  String get featureQueueSongsForYourNextArcadeVisit =>
      'Queue songs for your next arcade visit';

  @override
  String get featureChinaRhythmGameMap => 'China rhythm game map';

  @override
  String get featureFindArcadesWithTheGamesYouWant =>
      'Find arcades with the games you want';

  @override
  String get featureWorldwideArcadeMap => 'Worldwide arcade map';

  @override
  String get featureBrowseArcadesWorldwideOnNearCade =>
      'Browse arcades worldwide on NearCade';

  @override
  String get featureSoloSongGameSettings => 'Solo song game settings';

  @override
  String get featureManageSharedAndModeSpecificRules =>
      'Manage shared and mode-specific rules';

  @override
  String get featureNoClueSongQuiz => 'No-clue song quiz';

  @override
  String get featureChallengeTheSongLibraryFromMemory =>
      'Challenge the song library from memory';

  @override
  String get featureAliasSongQuiz => 'Alias song quiz';

  @override
  String get featureTestYourKnowledgeOfSongAliases =>
      'Test your knowledge of song aliases';

  @override
  String get featureMaimaiLetterReveal => 'maimai letter reveal';

  @override
  String get featureGuessSongsFromRevealedLetters =>
      'Guess songs from revealed letters';

  @override
  String get featureCroppedCoverQuiz => 'Cropped cover quiz';

  @override
  String get featureGuessTheSongFromASmallPart =>
      'Guess the song from a small part of its cover';

  @override
  String get featureBlurredCoverQuiz => 'Blurred cover quiz';

  @override
  String get featureGuessSongsFromBlurredCoverArt =>
      'Guess songs from blurred cover art';

  @override
  String get featurePixelCoverQuiz => 'Pixel cover quiz';

  @override
  String get featureGuessSongsFromPixelatedColorsAndShapes =>
      'Guess songs from pixelated colors and shapes';

  @override
  String get featureFlashCoverQuiz => 'Flash cover quiz';

  @override
  String get featureRememberABrieflyFlashedCover =>
      'Remember a briefly flashed cover';

  @override
  String get featureCoverPuzzleQuiz => 'Cover puzzle quiz';

  @override
  String get featureWatchCoverPiecesAppearOverTime =>
      'Watch cover pieces appear over time';

  @override
  String get featureAudioClipQuiz => 'Audio clip quiz';

  @override
  String get featureGuessSongsFromShortAudioClips =>
      'Guess songs from short audio clips';

  @override
  String get featureReversedAudioQuiz => 'Reversed audio quiz';

  @override
  String get featureGuessSongsFromReversedClips =>
      'Guess songs from reversed clips';

  @override
  String get featureSpeedAndPitchQuiz => 'Speed and pitch quiz';

  @override
  String get featureGuessSongsFromSpeedAndPitchChanges =>
      'Guess songs from speed and pitch changes';

  @override
  String get featureChartClipQuiz => 'Chart clip quiz';

  @override
  String get featureGuessSongsFromSilentChartAnimations =>
      'Guess songs from silent chart animations';

  @override
  String get featureMultiplayerSongQuiz => 'Multiplayer song quiz';

  @override
  String get featureGuessMaimaiSongsWithFriends =>
      'Guess maimai songs with friends';

  @override
  String get featureMusicPlayer => 'Music player';

  @override
  String get featurePlayMaimaiMusicInTheBackgroundWith =>
      'Play maimai music in the background with media controls';

  @override
  String get featureCustomChartPlayback => 'Custom chart playback';

  @override
  String get featurePlayLocalCustomCharts => 'Play local custom charts';

  @override
  String get featureAccountManagement => 'Score import credentials';

  @override
  String get featureViewYourLinkedDivingFishAccount =>
      'Manage score import tokens for Diving-Fish, LXNS and AWMC NET';

  @override
  String get featureAccountSetupGuide => 'Account setup guide';

  @override
  String get featureSetUpDivingFishLXNSAndAWMC =>
      'Set up Diving-Fish, LXNS and AWMC NET accounts';

  @override
  String get featureSignInToMaimaiScoreHub => 'Sign in to maimai Score Hub';

  @override
  String get featureSignInForOCRAndScoreHub =>
      'Sign in for OCR and Score Hub without syncing scores';

  @override
  String get featureSignOutOfDivingFish => 'Sign out of Diving-Fish';

  @override
  String get featureClearYourDivingFishSignIn =>
      'Clear your Diving-Fish sign-in';

  @override
  String get featureSignInToDivingFish => 'Sign in to Diving-Fish';

  @override
  String get featureGetAnImportTokenToEnableScoreSync =>
      'Get an ImportToken to enable score sync';

  @override
  String get featureSyncToDivingFish => 'Sync to Diving-Fish';

  @override
  String get featureScanACodeToFetchAndSync =>
      'Scan a code to fetch and sync your latest scores';

  @override
  String get featureSyncToLXNS => 'Sync to LXNS';

  @override
  String get featureSyncLocalScoresToLXNS => 'Sync local scores to LXNS';

  @override
  String get featureSyncToAWMCNET => 'Sync to AWMC NET';

  @override
  String get featureImportScoresToAWMCNETUsingA =>
      'Import scores to AWMC NET using a cabinet QR code';

  @override
  String get featureSyncToMultiplePlatforms => 'Sync to multiple platforms';

  @override
  String get featureSendTheSameScoresToMultipleTrackers =>
      'Send the same scores to multiple trackers';

  @override
  String get featureAutoSync => 'Auto sync';

  @override
  String get featureQuickSyncDailyAt0000And =>
      'Quick sync daily at 00:00 and 12:00 China time';

  @override
  String get featureRefreshCachedData => 'Pull scores & update data';

  @override
  String get featureFetchAndInitializeAllLocalCachesAgain =>
      'Pull scores for the chosen account, recalculate Best50, and update songs, constants and tags';

  @override
  String get featureAdvancedRefresh => 'Pull scores & update data (advanced)';

  @override
  String get featureChooseCachesToRefreshAndTestAPI =>
      'Choose which data types to force re-download and test API connections';

  @override
  String get featureRefreshCabinetPlayCount => 'Refresh cabinet play count';

  @override
  String get featureReadOnlyTheCurrentAccountPlayCount =>
      'Read only the current account play count without syncing scores';

  @override
  String get featureDataBackup => 'Data backup';

  @override
  String get featureImportOrExportLocalData => 'Import or export local data';

  @override
  String get featureCacheManagement => 'Cache management';

  @override
  String get featureViewAndClearAudioPVAndMaidata =>
      'View and clear audio, PV and maidata caches';

  @override
  String get featureSystemSettings => 'System settings';

  @override
  String get featureAdjustThemeBackgroundInteractionsAndSync =>
      'Adjust theme, background, interactions and sync';

  @override
  String get featureLoadingQuotes => 'Loading quotes';

  @override
  String get featureChooseQuotesShownWhileLoading =>
      'Choose quotes shown while loading';

  @override
  String get featureServerStatus => 'Server status';

  @override
  String get featureViewMaimaiServiceStatus => 'View maimai service status';

  @override
  String get featureExportLogs => 'Export logs';

  @override
  String get featureExportRecentLogsForTroubleshooting =>
      'Export recent logs for troubleshooting';

  @override
  String get featureRecentComments => 'Recent comments';

  @override
  String get featureViewRecentCommunityComments =>
      'View recent community comments';

  @override
  String get featureRecentRatings => 'Recent ratings';

  @override
  String get featureViewRecentCommunityRatings =>
      'View recent community ratings';

  @override
  String get featureCheckForUpdates => 'Check for updates';

  @override
  String get featureCheckForANewerAppVersion => 'Check for a newer app version';

  @override
  String get featureAboutTheApp => 'About the app';

  @override
  String get featureViewProjectAndVersionInformation =>
      'View project and version information';

  @override
  String get featureOfficialWebsite => 'Official website';

  @override
  String get featureVisitTheProjectAtChiffonmaiCloud =>
      'Visit the project at chiffonmai.cloud';

  @override
  String get featureRelatedProjects => 'Related projects';

  @override
  String get featureDiscoverCommunityProjects => 'Discover community projects';

  @override
  String get featureReportAnIssue => 'Report an issue';

  @override
  String get featureReportProblemsYouEncounter =>
      'Report problems you encounter';

  @override
  String get featureJoinTheQQGroup => 'Join the QQ group';

  @override
  String get featureOpenTheOfficialCommunityGroup =>
      'Open the official community group';

  @override
  String get featureSurvey => 'Survey';

  @override
  String get featureHelpImproveChiffonMai => 'Help improve ChiffonMai';

  @override
  String get featureSupportDevelopment => 'Support development';

  @override
  String get featureSupportContinuedProjectUpdates =>
      'Support continued project updates';

  @override
  String get featureLibrary => 'Library';

  @override
  String get featureSearchSongsBrowseInformationAndRecognizeImages =>
      'Search songs, browse information and recognize images';

  @override
  String get featureSiteWideTotalFittedRatingRanking =>
      'Site-wide total fitted Rating ranking';

  @override
  String get featureRankAllScoresByAverageDXScore =>
      'Rank all scores by average DX score achievement';

  @override
  String get featureScores => 'Scores';

  @override
  String get featureBrowseScoresImprovementsRankingsAndProgress =>
      'Browse scores, improvements, rankings and progress';

  @override
  String get featureAllFeatures => 'All features';

  @override
  String get featureStarAFeatureToAddItTo =>
      'Star a feature to add it to Home favorites';

  @override
  String get featureChallengeYourMelodyMemoryWithReversedClips =>
      'Challenge your melody memory with reversed clips';

  @override
  String get featureChangeBothSpeedAndPitchForA =>
      'Change both speed and pitch for a new listening challenge';

  @override
  String get featureSyncScoresOnADailySchedule =>
      'Sync scores on a daily schedule';

  @override
  String get featureMe => 'Me';

  @override
  String get featureAccountsSyncBackupAndAppPreferences =>
      'Accounts, sync, backup and app preferences';

  @override
  String get featureSharedRulesAndSettingsForEachMode =>
      'Shared rules and settings for each mode';

  @override
  String get featureHome => 'Home';

  @override
  String get featurePlay => 'Play';

  @override
  String get featureArcade => 'Arcade';

  @override
  String get featureCasual => 'Casual';

  @override
  String get featureChooseSongsPlanPracticeAndFindArcades =>
      'Choose songs, plan practice and find arcades';

  @override
  String get featureSongQuizzesMusicAndCustomCharts =>
      'Song quizzes, music and custom charts';

  @override
  String get featureSystem => 'System';

  @override
  String get featureBuildingCoverIndex => 'Building cover index…';

  @override
  String get featureAnotherTaskIsRunningPleaseWait =>
      'Another task is running. Please wait.';

  @override
  String get featureLeaderboards => 'Leaderboards';

  @override
  String get featureTotalFittedRating => 'Total fitted Rating';

  @override
  String get featureAverageAchievement => 'Average achievement';

  @override
  String get featureAverageDXScoreRate => 'Average DX score rate';

  @override
  String get featureSpecial => 'Special';

  @override
  String get featureCalculators2 => 'Calculators';

  @override
  String get featureFindScoresTitleConstantOrSongID =>
      'Find scores: title, constant or song ID';

  @override
  String get featureRefreshDataToSeeYourBest35And =>
      'Refresh data to see your Best35 and Best15 here';

  @override
  String get featureFitted => 'Fitted';

  @override
  String get featureCustom => 'Custom';

  @override
  String get featureCustomFitted => 'Custom fitted';

  @override
  String get featureIdeal => 'Ideal';

  @override
  String get featureCreate => 'Create';

  @override
  String get featureScoreImprovements => 'Score improvements';

  @override
  String get featureRecordsBeginAfterSyncing => 'Records begin after syncing';

  @override
  String get featureDailyHistory => 'Daily history';

  @override
  String get featureThemeAndNavigationSettings =>
      'Theme and navigation settings';

  @override
  String get featureSyncDataInMe => 'Sync data in Me';

  @override
  String get featureNoMatchingFeatures => 'No matching features';

  @override
  String get featureNoFeaturesFound => 'No features found';

  @override
  String get featureFavorites => 'Favorites';

  @override
  String get featureDragToReorderTapOrDragTo =>
      'Drag to reorder. Tap × or drag to the removal area to remove a favorite.';

  @override
  String get featureStarFeaturesInAnyCategoryToShow =>
      'Star features in any category to show them here.';

  @override
  String get featureFinishEditingFavorites => 'Finish editing favorites';

  @override
  String get featureEditFavorites => 'Edit favorites';

  @override
  String get featureDone => 'Done';

  @override
  String get featureEdit => 'Edit';

  @override
  String get featureReleaseToRemove => 'Release to remove';

  @override
  String get featureDragHereToRemove => 'Drag here to remove';

  @override
  String get featureRemoveFavorite => 'Remove favorite';

  @override
  String get featureFavoriteFeature => 'Favorite feature';

  @override
  String get featureSearchFeaturesOrKeywords => 'Search features or keywords';

  @override
  String get featureSearchSongTitlesAliasesOrIDs =>
      'Search song titles, aliases or IDs…';

  @override
  String get featureSearchFeaturesOrSongs => 'Search features or songs';

  @override
  String get featureSearch => 'Search…';

  @override
  String get featureClear => 'Clear';

  @override
  String get featureSearch2 => 'Search';

  @override
  String get featureCloseSearch => 'Close search';

  @override
  String get featureClearInput => 'Clear input';

  @override
  String get featureClearSearch => 'Clear search';

  @override
  String get featureSearchHistory => 'Search history';

  @override
  String get featureLoadingSearchHistory => 'Loading search history…';

  @override
  String get featureNoSearchHistory => 'No search history';

  @override
  String get featureDeleteThisSearchEntry => 'Delete this search entry';

  @override
  String get featureCouldNotUpdateSearchHistoryTryAgain =>
      'Could not update search history. Try again.';

  @override
  String get featureSearchSongTitlesOnly => 'Search song titles only';

  @override
  String get featureTitleBPMCharterArtistAliasID =>
      'Title / BPM / charter / artist / alias / ID…';

  @override
  String get featureTitleAliasIDArtistCharterBPM =>
      'Title, alias, ID, artist, charter, BPM';

  @override
  String get featureEnterAKeywordToFindSongs => 'Enter a keyword to find songs';

  @override
  String get featureNoMatchingSongs => 'No matching songs';

  @override
  String get featureSongs => 'Songs';

  @override
  String get featureThemeSettings => 'Theme settings';

  @override
  String get featureMoreSettings => 'More settings';

  @override
  String get featureCancel => 'Cancel';

  @override
  String get featureOK => 'OK';

  @override
  String get featureClose => 'Close';

  @override
  String get featureGotIt => 'Got it';

  @override
  String get featureNotice => 'Notice';

  @override
  String get featureOperationFailed => 'Operation failed';

  @override
  String get featureUnknownError => 'Unknown error';

  @override
  String get featureDialog => 'Dialog';

  @override
  String get featureNoDetailsAvailable => 'No details available';

  @override
  String get featureUnknown => 'Unknown';

  @override
  String get featureOff => 'Off';

  @override
  String get featureWaitingForUpstream => 'Waiting for upstream';

  @override
  String get featureSyncing => 'Syncing';

  @override
  String get featureOn => 'On';

  @override
  String get featureLastRunIncomplete => 'Last run incomplete';

  @override
  String get featureUpToDate => 'Up to date';

  @override
  String get featureLoading => 'Loading…';

  @override
  String get featureCheckingSyncStatus => 'Checking sync status';

  @override
  String get featureStatusUnknown => 'Status unknown';

  @override
  String get featureTemporarilyUnavailable => 'Temporarily unavailable';

  @override
  String get featureTapToSetUp => 'Tap to set up';

  @override
  String get featureUnavailableRetryingShortly =>
      'Unavailable. Retrying shortly.';

  @override
  String get featureCheckingServerStatus => 'Checking server status';

  @override
  String get featureSyncing2 => 'Syncing…';

  @override
  String get featureReadingCabinetScores => 'Reading cabinet scores…';

  @override
  String get featureCheckingForUpdates => 'Checking for updates…';

  @override
  String get featureCouldNotCheckForUpdates => 'Could not check for updates';

  @override
  String get featureCheckYourConnectionAndTryAgain =>
      'Check your connection and try again';

  @override
  String get featureCopyDownloadLink => 'Copy download link';

  @override
  String get featureDownloadLinkCopied => 'Download link copied';

  @override
  String get featureUpdateAvailable => 'Update available';

  @override
  String get featureNewVersion => 'New version';

  @override
  String get featureSignedInForOCRAndMaimaiScore =>
      'Signed in for OCR and maimai Score Hub';

  @override
  String get featureSignedInOCRAndMaimaiScoreHub =>
      'Signed in. OCR and maimai Score Hub are ready.';

  @override
  String get featureRainbow => 'Rainbow';

  @override
  String get featurePlatinum => 'Platinum';

  @override
  String get featureGold => 'Gold';

  @override
  String get featureSilver => 'Silver';

  @override
  String get featureBronze => 'Bronze';

  @override
  String get featurePurple => 'Purple';

  @override
  String get featureRed => 'Red';

  @override
  String get featureOrange => 'Orange';

  @override
  String get featureGreen => 'Green';

  @override
  String get featureBlue => 'Blue';

  @override
  String get featureWhite => 'White';

  @override
  String homeWelcome(String name) {
    return 'Welcome back, $name';
  }

  @override
  String homeSwitchSource(String source) {
    return 'Switch data source, currently $source';
  }

  @override
  String homeTotalRatingAction(String rating) {
    return 'Total Rating $rating. Open advanced refresh.';
  }

  @override
  String homeFeatureCount(int count) {
    return 'Features ($count)';
  }

  @override
  String homeAllFeatureCount(int count) {
    return 'All features ($count)';
  }

  @override
  String homeResultCount(int count) {
    return 'Results ($count)';
  }

  @override
  String homeSongCount(int count) {
    return 'Songs ($count)';
  }

  @override
  String homeSongCountLimited(int count, int limit) {
    return 'Songs ($count, showing first $limit)';
  }

  @override
  String homeRemoveFavorite(String name) {
    return 'Remove favorite: $name';
  }

  @override
  String hubRatingRecords(int rating, int count) {
    return 'Latest $rating · $count records';
  }

  @override
  String hubFeaturesCount(int count) {
    return '$count features';
  }

  @override
  String hubCoverIndexFailed(String error) {
    return 'Could not build cover index: $error';
  }

  @override
  String hubOpenFailed(String error) {
    return 'Could not open: $error';
  }

  @override
  String hubLinkUnavailable(String name) {
    return 'Could not open link: $name';
  }

  @override
  String hubJoinGroup(String number) {
    return 'Open the official QQ group ($number)';
  }

  @override
  String hubUpdateReleased(String version) {
    return '$version is available. View what’s new.';
  }

  @override
  String homeSyncSubmitted(int count) {
    return 'Submitted $count';
  }

  @override
  String homeSyncIncomplete(int count) {
    return '$count incomplete';
  }

  @override
  String homeSyncSources(int count) {
    return '$count data sources';
  }

  @override
  String homeSyncSourcesWaiting(int count) {
    return '$count sources · Waiting to run';
  }

  @override
  String homeSyncUpload(int completed, int total) {
    return 'Uploading $completed/$total';
  }

  @override
  String homeSyncReadPage(int page) {
    return 'Reading scores · Page $page';
  }

  @override
  String homeServerHealthy(int healthy, int total) {
    return '$healthy/$total healthy';
  }

  @override
  String homeTodayAt(String time) {
    return 'Today $time';
  }

  @override
  String get homeInitWorking => 'Initializing app data. Please wait…';

  @override
  String homeInitFinished(String duration) {
    return 'Data initialized in $duration';
  }

  @override
  String homeInitFailed(String error) {
    return 'Initialization failed: $error\nCheck your connection and restart the app.';
  }

  @override
  String get featureHubSignedIn => 'Signed in for OCR. Tap to sign in again.';

  @override
  String get featureFish => 'Diving-Fish';

  @override
  String get featureLxns => 'LXNS';

  @override
  String get featureServerNormal => 'Services healthy';

  @override
  String get featureServerAbnormal => 'Service disruption';

  @override
  String get featureTapCommunityAppearance =>
      'Tap to choose community appearance';

  @override
  String get featureManageAccountBelow => 'Manage account data below';

  @override
  String get featureCollapseProfile => 'Show less profile information';

  @override
  String get featureExpandProfile => 'Show more profile information';

  @override
  String get featureSynced => 'Synced';

  @override
  String get featureSyncFailed => 'Sync failed';

  @override
  String get featurePendingSync => 'Pending sync';

  @override
  String get featureLocalOnly => 'On this device only';

  @override
  String get featureLoadingGrowth => 'Loading growth records…';

  @override
  String get featureGrowthRules => 'Growth rules';

  @override
  String get featureSyncProgress => 'Syncing. Please wait…';

  @override
  String get featurePreparing => 'Preparing…';

  @override
  String homeStreak(int days) {
    return '$days-day check-in streak';
  }

  @override
  String homeTrophyId(String id) {
    return 'Title #$id';
  }

  @override
  String get growthRulesBody =>
      'Check-in is checked on the first app launch each day, using China time. Signing in or verifying an account on this device also checks in that account if needed.\n\nEarn 20 EXP on day one, then 5 more per consecutive day, up to 50 EXP daily from day seven. A missed day resets the daily reward to 20 EXP; total EXP is kept.\n\nLv.1 needs 100 EXP to level up. Each later level needs 20 EXP more.\n\nGrowth records belong to the account on each data source. Each account can claim once per day.';

  @override
  String hubOpenRelatedProject(String name) {
    return 'Open related project: $name';
  }

  @override
  String hubBusyTask(String task) {
    return '$task is running. This feature is unavailable.';
  }

  @override
  String get flowEnterYourAWMCNETTokenFirst =>
      'Enter your AWMC NET Token first';

  @override
  String get flowCouldNotSaveYourPersonalKeyTry =>
      'Could not save your personal key. Try again.';

  @override
  String get flowCouldNotDisableAutoSyncYourKey =>
      'Could not disable auto sync. Your key was kept. Try again.';

  @override
  String get flowAWMCNETScoreImportToken => 'AWMC NET score import Token';

  @override
  String get flowSet => 'Set';

  @override
  String get flowNotSet => 'Not set';

  @override
  String get flowVisit => 'Visit';

  @override
  String get flowToGenerateOrRotateYourTokenAt =>
      ' to generate or rotate your Token at the bottom of the page.';

  @override
  String get flowPasteYourAWMCNETScoreImportToken =>
      'Paste your AWMC NET score import Token…';

  @override
  String get flowClearToken => 'Clear Token';

  @override
  String flowSignOutFailedP0(String p0) {
    return 'Sign-out failed: $p0';
  }

  @override
  String get flowSignedOutOfDivingFish => 'Signed out of Diving-Fish';

  @override
  String get flowLinkDivingFishAccount => 'Link Diving-Fish account';

  @override
  String get flowRequestAndOpenALoginQRCode =>
      'Request and open a login QR code in the maimai/chunithm WeChat account. Scan it and paste the string below:';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID =>
      'maimai DX / CHUNITHM login QR (SGWCMAID…)';

  @override
  String get flowJoinLeaderboards => 'Join leaderboards';

  @override
  String get flowRankingDivingFishMasked =>
      'Your Diving-Fish account has \"Mask scores for non-web queries\" turned on, so the scores the app reads from Diving-Fish are not accurate and can\'t be used for leaderboards. Turn it off in your profile on the Diving-Fish website and try again.';

  @override
  String songScoreIllegalWarning(String p0) {
    return 'This score looks invalid: $p0. It will not be uploaded to the leaderboards.';
  }

  @override
  String songScoreIllegalAchievement(String p0) {
    return 'achievement exceeds the $p0% limit';
  }

  @override
  String songScoreIllegalDx(String p0) {
    return 'DX score exceeds the chart maximum of $p0';
  }

  @override
  String songScoreIllegalUnreleased(String p0) {
    return 'the chart is not yet released in China ($p0)';
  }

  @override
  String flowDXScoreMAXOverP0(String p0) {
    return 'DX score (MAX +$p0)';
  }

  @override
  String get rankingUploadIncompleteTitle => 'Leaderboard upload not completed';

  @override
  String get rankingUploadIncompleteLead =>
      'Your scores were refreshed and saved, but the leaderboards were not updated this time.';

  @override
  String get rankingGuardFrozen =>
      'Your leaderboard uploads are paused pending a manual review. Your leaderboard entries are hidden during the review.';

  @override
  String get rankingGuardBlacklisted =>
      'This account is banned from the leaderboards.';

  @override
  String get rankingGuardUpgradeRequired =>
      'Please update to the latest version before uploading to the leaderboards.';

  @override
  String rankingGuardRejected(String p0, String p1) {
    return 'This leaderboard upload was rejected: $p0. $p1 warning(s) left. After that, uploads are paused for a manual review.';
  }

  @override
  String get rankingGuardReasonRating =>
      'Rating exceeds the current theoretical maximum';

  @override
  String rankingGuardReasonUnknownSong(String p0) {
    return 'includes a song that is not in the song list ($p0)';
  }

  @override
  String rankingGuardReasonUnreleased(String p0) {
    return 'includes a song that has not been released yet ($p0)';
  }

  @override
  String rankingGuardReasonLevel(String p0) {
    return 'difficulty does not exist ($p0)';
  }

  @override
  String rankingGuardReasonAchievement(String p0) {
    return 'achievement exceeds the limit ($p0)';
  }

  @override
  String rankingGuardReasonDx(String p0) {
    return 'DX score exceeds the chart maximum ($p0)';
  }

  @override
  String get rankingGuardReasonInvalid => 'invalid score data';

  @override
  String get flowShowNicknameOtherwiseShownAsAnonymous =>
      'Show nickname (otherwise shown as anonymous)';

  @override
  String get flowScoresFetchedLinkYourDivingFishAccount =>
      'Scores fetched. Link your Diving-Fish account to upload them:';

  @override
  String get flowDivingFishUsername => 'Diving-Fish username';

  @override
  String get flowEnterDivingFishUsername => 'Enter Diving-Fish username';

  @override
  String get flowDivingFishPassword => 'Diving-Fish password';

  @override
  String get flowEnterDivingFishPassword => 'Enter Diving-Fish password';

  @override
  String get flowSyncInProgressPleaseWaitAndAvoid =>
      'Sync in progress. Please wait and avoid other operations.';

  @override
  String get flowScoresSyncedViewThemOnDivingFish =>
      'Scores synced. View them on Diving-Fish.';

  @override
  String flowOKP0(String p0) {
    return 'OK ($p0)';
  }

  @override
  String get flowSkip => 'Skip';

  @override
  String get flowLinking => 'Linking…';

  @override
  String get flowLinkAndSync => 'Link and sync';

  @override
  String flowDoneP0ScoresSyncedAndLocalData(String p0) {
    return 'Done. $p0 scores synced and local data refreshed.';
  }

  @override
  String get flowStartSync => 'Start sync';

  @override
  String get flowPasteTheMaimaiCHUNITHMLoginQRString =>
      'Paste the maimai/CHUNITHM login QR string first';

  @override
  String get flowSignedIn => 'Signed in';

  @override
  String get flowEnterYourDivingFishCredentialsToObtain =>
      'Enter your Diving-Fish credentials to obtain an ImportToken:';

  @override
  String get flowUsername => 'Username';

  @override
  String get flowDivingFishUsername2 => 'Diving-Fish username';

  @override
  String get flowPassword => 'Password';

  @override
  String get flowDivingFishPassword2 => 'Diving-Fish password';

  @override
  String get flowImportTokenRetrievedAndSaved =>
      'ImportToken retrieved and saved';

  @override
  String get flowYouCanNowSyncScoresToDiving =>
      'You can now sync scores to Diving-Fish with one tap.';

  @override
  String get flowSigningIn => 'Signing in…';

  @override
  String get flowSignIn => 'Sign in';

  @override
  String get flowDataRefreshed => 'Data refreshed';

  @override
  String get flowDivingFishProfile => 'Diving-Fish score import Token';

  @override
  String get flowNotSignedInToDivingFishOnly =>
      'Not signed in to Diving-Fish. Only LXNS settings are shown.';

  @override
  String get flowNoQQIDFoundRefreshDataOr =>
      'No QQ ID found. Refresh data or sign in to Diving-Fish first.';

  @override
  String get flowAuthorized => 'Authorized';

  @override
  String get flowNotAuthorized => 'Not authorized';

  @override
  String get flowReadingDivingFishScoresRequiresBrowserAuthorization =>
      'Reading Diving-Fish scores requires browser authorization. Open the link below, sign in and approve access.';

  @override
  String get flowDivingFishAuthorization => 'Diving-Fish authorization';

  @override
  String get flowAuthorizationOpenedCompleteItInYourBrowser =>
      'Authorization opened. Complete it in your browser, then return.';

  @override
  String get flowCouldNotStartAuthorizationTryAgain =>
      'Could not start authorization. Try again.';

  @override
  String get flowAuthorizeAgain => 'Authorize again';

  @override
  String get flowOpenAuthorizationLink => 'Open authorization link';

  @override
  String get flowLXNSPersonalAPIKey => 'LXNS personal API key';

  @override
  String get flowVisit2 => 'Visit ';

  @override
  String get flowAndScrollToTheBottomToGet =>
      ' and scroll to the bottom to get your key.';

  @override
  String get flowPasteYourLXNSPersonalAPIKey =>
      'Paste your LXNS personal API key…';

  @override
  String get flowEnterYourAPIKeyFirst => 'Enter your API key first';

  @override
  String get flowClearKey => 'Clear key';

  @override
  String get flowRefreshImportToken => 'Refresh ImportToken';

  @override
  String get flowCouldNotRefreshImportTokenTryAgain =>
      'Could not refresh ImportToken. Try again.';

  @override
  String get flowCopyImportToken => 'Copy ImportToken';

  @override
  String get flowImportTokenCopied => 'ImportToken copied';

  @override
  String get flowConfirmRefresh => 'Confirm refresh';

  @override
  String get flowThisClearsAllMaidataCachesAndDownloads =>
      'This clears all maidata caches and downloads them again. It may take some time.\n\nContinue?';

  @override
  String get flowMaidataRefreshed => 'Maidata refreshed';

  @override
  String flowRefreshFailedP0(String p0) {
    return 'Refresh failed: $p0';
  }

  @override
  String flowCouldNotOpenABrowserWebsiteLink(String p0) {
    return 'Could not open a browser. Website link copied. Open $p0 manually.';
  }

  @override
  String get flowConfirmSignOut => 'Confirm sign out';

  @override
  String get flowSigningOutClearsSavedLoginDetailsAnd =>
      'Signing out clears saved login details and ImportToken. Continue?';

  @override
  String get flowSignOut => 'Sign out';

  @override
  String get flowAccountChangedChooseYourAppearanceAgain =>
      'Account changed. Choose your appearance again.';

  @override
  String get flowCouldNotSaveYourAppearanceChooseAgain =>
      'Could not save your appearance. Choose again.';

  @override
  String get flowChooseWhereToSaveLogs => 'Choose where to save logs';

  @override
  String get flowLogsExported => 'Logs exported';

  @override
  String flowCouldNotExportLogsP0(String p0) {
    return 'Could not export logs: $p0';
  }

  @override
  String flowCouldNotOpenABrowserP0Copied(String p0) {
    return 'Could not open a browser. $p0 copied. Open it manually.';
  }

  @override
  String get flowBaseNoteMaidataDownloadedAgain =>
      'Base-note maidata downloaded again';

  @override
  String flowDownloadFailedP0(String p0) {
    return 'Download failed: $p0';
  }

  @override
  String flowPlayCountsUpdatedP0Records(String p0) {
    return 'Play counts updated ($p0 records)';
  }

  @override
  String flowCouldNotReadPlayCountsP0(String p0) {
    return 'Could not read play counts: $p0';
  }

  @override
  String get flowNoConnectionConnectAndTryAgain =>
      'No connection. Connect and try again.';

  @override
  String get flowMaimaiScoreHubSignInSavedOCR =>
      'maimai Score Hub sign-in saved. OCR is now available.';

  @override
  String get flowSignOutOfDivingFish => 'Sign out of Diving-Fish?';

  @override
  String flowCouldNotSignOutOfDivingFish(String p0) {
    return 'Could not sign out of Diving-Fish: $p0';
  }

  @override
  String get flowCannotSave => 'Cannot save';

  @override
  String get flowEnterYourAWMCNETScoreImportToken =>
      'Enter your AWMC NET score import Token.';

  @override
  String get flowAWMCNETScoreImportTokenSaved =>
      'AWMC NET score import Token saved';

  @override
  String get flowAWMCNETScoreImportTokenCleared =>
      'AWMC NET score import Token cleared';

  @override
  String get flowSignedInToDivingFish => 'Signed in to Diving-Fish';

  @override
  String get flowScoreImportToken => 'Score import Token';

  @override
  String get flowPasteATokenGeneratedInAWMCNET =>
      'Paste a Token generated in AWMC NET settings';

  @override
  String get flowSaveToken => 'Save Token';

  @override
  String flowP0AutoSyncEnabledScheduledDailyBetween(String p0) {
    return '$p0 auto sync enabled. Scheduled daily between 08:00 and 24:00 China time.';
  }

  @override
  String flowP0AutoSyncDisabledHostedCredentialsDeleted(String p0) {
    return '$p0 auto sync disabled. Hosted credentials deleted.';
  }

  @override
  String get flowAutoSyncTemporarilyLimited => 'Auto sync temporarily limited';

  @override
  String get flowCouldNotConfigureAutoSyncCheckYour =>
      'Could not configure auto sync. Check your account and try again.';

  @override
  String get flowRefreshStatus => 'Refresh status';

  @override
  String get flowQueueStatus => 'Queue status';

  @override
  String get flowSyncSources => 'Sync sources';

  @override
  String get flowLoading => 'Loading…';

  @override
  String get flowSourcesEnabled => ' sources enabled';

  @override
  String get flowScheduledQueueWindow => 'Scheduled queue window';

  @override
  String get flowChinaTimeUTC8OnceDailyQuick =>
      'China time (UTC+8) · Once daily · Quick sync only';

  @override
  String get flowCredentialsAreEncryptedAndHostedWhileEnabled =>
      'Credentials are encrypted and hosted while enabled, then deleted when disabled.';

  @override
  String get flowAboutSync => 'About sync';

  @override
  String get flowUsersAreProcessedInDailyBatchesNew =>
      'Users are processed in daily batches. New users join the end of an active or pending batch, then enter the next round of random ordering. Rate limits or long queues may defer processing to a later window.';

  @override
  String get flowEachUserBatchHasAProcessingLimit =>
      'Each user batch has a processing limit. Slow upstream responses, quota limits or large uploads can end the round; the reason appears in the last result. Processing resumes in the next daily window. Queue time is excluded.';

  @override
  String flowAfterReadingCabinetScoresEachUserHas(String p0) {
    return 'After reading cabinet scores, each user has up to $p0 minutes of processing time. Queue and quota waits before reading are excluded. Processing ends at the time limit or daily closing time and resumes the next day.';
  }

  @override
  String get flowLinkYourCabinetIdentityUsingAQR =>
      'Link your cabinet identity using a QR code to share credentials across all three sources. A normal QR sync also links it automatically. Each source still needs its own personal key and account.\n\nQuick sync is scheduled between 08:00 and 24:00 China time. The three sources share one cabinet score fetch, then compare and upload changes separately.\n\nProgress shows the current stage, pages read, uploaded and submitted scores, and elapsed time. Upstream waits show a reason and estimated retry time. Last results include duration, cabinet data collection time and the next retry.\n\nAuto sync shares an upstream request budget and rate limit. It pauses with a reason during maintenance, quota shortages or network errors instead of continuously retrying.\n\nDisabling during a run stops later batches; submitted scores remain. Uncertain uploads are checked before retrying to avoid duplicates.';

  @override
  String get flowSaving => 'Saving…';

  @override
  String flowP0AutoSync(String p0) {
    return '$p0 auto sync';
  }

  @override
  String flowRoundStartedP0(String p0) {
    return 'Round started: $p0';
  }

  @override
  String flowNextRunP0(String p0) {
    return 'Next run: $p0';
  }

  @override
  String get flowLoadingSyncStatus => 'Loading sync status…';

  @override
  String get flowOffEnableAnytime => 'Off · Enable anytime';

  @override
  String flowSyncSucceededButLocalRefreshWasIncomplete(String p0) {
    return 'Sync succeeded, but local refresh was incomplete: $p0';
  }

  @override
  String get flowTheQueueIsBusyYourRunMay =>
      'The queue is busy. Your run may move to a later window.';

  @override
  String flowLastProgressP0(String p0) {
    return 'Last progress: $p0';
  }

  @override
  String flowP0NoExecutionSlotIsUsedWhile(String p0) {
    return '$p0; no execution slot is used while waiting';
  }

  @override
  String flowRunTimeP0(String p0) {
    return 'Run time: $p0';
  }

  @override
  String flowCabinetDataCollectedP0(String p0) {
    return 'Cabinet data collected: $p0';
  }

  @override
  String get flowTheRoundExceededItsTimeLimitAnd =>
      'The round exceeded its time limit and ended. Remaining work resumes at the next scheduled run.';

  @override
  String flowTheRoundExceededItsP0MinuteLimit(String p0) {
    return 'The round exceeded its $p0-minute limit and ended. Remaining work resumes at the next scheduled run.';
  }

  @override
  String get flowNextAutomaticRetry => 'Next automatic retry';

  @override
  String get flowNextRun => 'Next run';

  @override
  String flowP0Queue(String p0) {
    return '$p0 queue';
  }

  @override
  String get flowNextRound => 'Next round';

  @override
  String get flowThisRound => 'This round';

  @override
  String get flowChinaTimeUTC8 => 'China time (UTC+8)';

  @override
  String flowLimitP0MinutesPerRound(String p0) {
    return ' · Limit $p0 minutes per round';
  }

  @override
  String get flowWaitingForUpstreamRecovery => 'Waiting for upstream recovery';

  @override
  String get flowPreviousRoundQueue => 'Previous round queue';

  @override
  String get flowLoadingPreviousRoundStatistics =>
      'Loading previous round statistics…';

  @override
  String get flowStatisticsUnavailableRetryingAutomatically =>
      'Statistics unavailable. Retrying automatically.';

  @override
  String get flowNoPreviousRound => 'No previous round';

  @override
  String flowSubmittedP0SkippedP1P2(String p0, String p1, String p2) {
    return 'Submitted $p0 · Skipped $p1 · $p2';
  }

  @override
  String get flowCabinetIdentityLinked => 'Cabinet identity linked';

  @override
  String get flowLinkCabinetIdentityFirst => 'Link cabinet identity first';

  @override
  String get flowRequestAndOpenALoginQRCode2 =>
      'Request and open a login QR code in the maimai/CHUNITHM WeChat account, then enter its SGWCMAID string below. One link is shared by all three sources; the QR code itself is not saved. A normal QR sync also links it automatically.';

  @override
  String get flowCabinetLoginQRCode => 'Cabinet login QR code';

  @override
  String get flowLinking2 => 'Linking…';

  @override
  String get flowLinkCabinetIdentity => 'Link cabinet identity';

  @override
  String flowEnterYourP0PersonalKeyToo(String p0) {
    return 'Enter your $p0 personal key too';
  }

  @override
  String get flowOpenDivingFish => 'Open Diving-Fish';

  @override
  String get flowOpenKeyPage => 'Open key page';

  @override
  String get flowPersonalKey => 'Personal key';

  @override
  String get flowPasteImportToken => 'Paste ImportToken…';

  @override
  String get flowSavePersonalKey => 'Save personal key';

  @override
  String get flowInvalidCabinetLoginQRCode => 'Invalid cabinet login QR code';

  @override
  String flowSyncFailedP0(String p0) {
    return 'Sync failed: $p0';
  }

  @override
  String flowAWMCGatewayUnavailableP0(String p0) {
    return 'AWMC gateway unavailable: $p0';
  }

  @override
  String get flowThisReadsOnlyTheActiveAccountPlay =>
      'This reads only the active account play count. Use a newly generated QR code. Only one upstream request will be made.';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID2 =>
      'maimai DX / CHUNITHM login QR (SGWCMAID…)';

  @override
  String get flowEnterAValidSGWCMAIDCabinetLoginQR =>
      'Enter a valid SGWCMAID cabinet login QR code';

  @override
  String get flowReadPlayCount => 'Read play count';

  @override
  String get flowNone => '(None)';

  @override
  String get flowViewFullData => 'View full data';

  @override
  String get flowDataIsShownOnlyOnThisDevice =>
      'Data is shown only on this device and is not uploaded to third parties.';

  @override
  String get flowSetGatewayToken => 'Set gateway Token';

  @override
  String get flowQRCodeContent => 'QR code content';

  @override
  String get flowInvalidQRFormatMustStartWithSGWCMAID =>
      'Invalid QR format (must start with SGWCMAID)';

  @override
  String get flowConfirmAction => 'Confirm action';

  @override
  String get flowNoCharge => 'No charge';

  @override
  String get flowShow => 'Show';

  @override
  String get flowFullData => 'Full data';

  @override
  String flowP0P1CharactersP2LinesShownOnly(String p0, String p1, String p2) {
    return '$p0 · $p1 characters / $p2 lines\nShown only on this device; never uploaded to third parties.';
  }

  @override
  String get flowEnterYourAWMCNETScoreImportToken2 =>
      'Enter your AWMC NET score import Token';

  @override
  String get flowImportTokenSaved => 'Import Token saved';

  @override
  String get flowPasteOrScanACabinetLoginQR =>
      'Paste or scan a cabinet login QR code starting with SGWCMAID';

  @override
  String get flowSetYourAWMCNETScoreImportToken =>
      'Set your AWMC NET score import Token first';

  @override
  String get flowRequestAndOpenALoginQRIn =>
      'Request and open a login QR in the maimai/CHUNITHM WeChat account, then paste it below, scan it or read it from an image.';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID3 =>
      'maimai DX / CHUNITHM login QR (SGWCMAID…)';

  @override
  String get flowScoreImportTokenSet => 'Score import Token set';

  @override
  String get flowSetAWMCNETScoreImportToken =>
      'Set AWMC NET score import Token';

  @override
  String get flowChange => 'Change';

  @override
  String get flowPasteScoreImportToken => 'Paste score import Token…';

  @override
  String get flowGenerateYourOwnTokenOnAWMCNET =>
      'Generate your own Token on AWMC NET (the project key cannot be used here):';

  @override
  String get flow1OpenTheAWMCNETSettingsLink =>
      '1. Open the AWMC NET settings link below';

  @override
  String get flow2ScrollToTheBottomAndGenerate =>
      '2. Scroll to the bottom and generate or rotate a Token';

  @override
  String get flow3CopyTheTokenAndPasteIt =>
      '3. Copy the Token and paste it here';

  @override
  String get flowCabinetScoresTakePriorityAndOverwriteMatching =>
      'Cabinet scores take priority and overwrite matching AWMC NET scores.';

  @override
  String flowCouldNotOpenABrowserVisitP0(String p0) {
    return 'Could not open a browser. Visit $p0 manually.';
  }

  @override
  String flowClearP0AccountData(String p0) {
    return 'Clear $p0 account data';
  }

  @override
  String flowThisDeletesLocalP0CachesScoresBest50(String p0) {
    return 'This deletes local $p0 caches (scores, Best50, profile and recommendations) without signing out.\n\nYou will need to refresh data before using this account again. Continue?';
  }

  @override
  String get flowClear => 'Clear';

  @override
  String flowCouldNotClearP0(String p0) {
    return 'Could not clear: $p0';
  }

  @override
  String flowClearedP0AccountData(String p0) {
    return 'Cleared $p0 account data';
  }

  @override
  String flowSwitchedToP0Account(String p0) {
    return 'Switched to $p0 account';
  }

  @override
  String get flowAccountSwitchFailedAttemptedToRestoreThe =>
      'Account switch failed. Attempted to restore the original account.';

  @override
  String get flowSwitchingPleaseWait => 'Switching. Please wait.';

  @override
  String get flowNoCachedDataForThisAccount =>
      'No cached data for this account';

  @override
  String flowNoDataHasBeenCachedForP0(String p0) {
    return 'No data has been cached for $p0. Refresh now?';
  }

  @override
  String get flowRefreshNow => 'Refresh now';

  @override
  String get flowSwitchAccount => 'Switch account';

  @override
  String flowSwitchingToP0(String p0) {
    return 'Switching to $p0…';
  }

  @override
  String get flowTapAnAccountToSwitchSourceAnd =>
      'Tap an account to switch source and profile using local data without network access.';

  @override
  String get flowRefreshToUpdateTheActiveAccountDiving =>
      'Refresh to update the active account. Diving-Fish and LXNS sign-ins are separate; AWMC NET uses a QQ ID without sign-in.';

  @override
  String get flowCurrent => 'Current';

  @override
  String get flowNoCache => 'No cache';

  @override
  String flowCopiedP0(String p0) {
    return 'Copied: $p0';
  }

  @override
  String flowAWMCBOTQQIDCopiedP0(String p0) {
    return 'AWMC BOT QQ ID copied: $p0';
  }

  @override
  String flowCopyP0(String p0) {
    return 'Copy $p0';
  }

  @override
  String get flowOpenLXNS => 'Open LXNS';

  @override
  String get flowSendMymaiFirstIfNoAccountRecord =>
      'Send mymai first. If no account record exists, the bot replies with instructions.';

  @override
  String get flowThenSendMaiAndFollowTheInstructions =>
      'Then send mai绑定 and follow the instructions to create a profile.';

  @override
  String get flowOpenAWMCNET => 'Open AWMC NET';

  @override
  String get flowTapAnImageToEnlargeIt => 'Tap an image to enlarge it';

  @override
  String get flowEnlargeImage => 'Enlarge image';

  @override
  String get flowNotSignedInToDivingFish => 'Not signed in to Diving-Fish';

  @override
  String get flowYourDivingFishAccountHasNoLinked =>
      'Your Diving-Fish account has no linked QQ ID';

  @override
  String get flowLinkQQOnDivingFish => 'Link QQ on Diving-Fish';

  @override
  String get flowISavedItReadAgain => 'I saved it. Read again.';

  @override
  String get flowAccount => 'Account';

  @override
  String get flowCheckingAuthorization => 'Checking authorization…';

  @override
  String get flowAuthorizationOpenedFinishInYourBrowserThen =>
      'Authorization opened. Finish in your browser, then check again.';

  @override
  String get flowReadingScoresRequiresAuthorizationRefreshWillFail =>
      'Reading scores requires authorization. Refresh will fail without it.';

  @override
  String get flowAuthorizedCheckAgain => 'Authorized. Check again.';

  @override
  String get flowAuthorize => 'Authorize';

  @override
  String get flowCouldNotOpenABrowserLinkCopied =>
      'Could not open a browser. Link copied. Open it manually.';

  @override
  String flowP0ReusesThisDeviceSMaimaiScore(String p0) {
    return '$p0 reuses this device’s maimai Score Hub sign-in.\n\nNo valid session is available. Sign in with a new cabinet QR code first. Sync then requires another new QR code to fetch scores; a single code cannot be used for both.\n\nThe session is saved locally, so later Route 2 syncs need no repeat sign-in.';
  }

  @override
  String get flowRoute2Sync => 'Route 2 sync';

  @override
  String flowP0Sync(String p0) {
    return '$p0 sync';
  }

  @override
  String get flowTipGenerateTwoDifferentLoginQRCodes =>
      'Tip: Generate two different login QR codes before scanning.';

  @override
  String get flowSignInFirst => 'Sign in first';

  @override
  String get flowSignedInToMaimaiScoreHub => 'Signed in to maimai Score Hub';

  @override
  String get flowSignInSavedForOCRAndRoute =>
      'Sign-in saved for OCR and Route 2 sync.\nYou do not need to scan again to sign in.';

  @override
  String get flowAuthenticatesWithMaimaiScoreHubOnlyNo =>
      'Authenticates with maimai Score Hub only. No scores are fetched or synced.';

  @override
  String get flowInvalidQRCodeUseALoginQR =>
      'Invalid QR code. Use a login QR from the maimai/CHUNITHM WeChat account.';

  @override
  String get flowSetLXNSPersonalAPIKey => 'Set LXNS personal API key';

  @override
  String get flowExportingToLXNSRequiresYourPersonalAPI =>
      'Exporting to LXNS requires your personal API key, not your password:';

  @override
  String get flow1OpenTheLXNSProfileLinkBelow =>
      '1. Open the LXNS profile link below';

  @override
  String get flow2ScrollToTheBottomAndCopy =>
      '2. Scroll to the bottom and copy your personal API key';

  @override
  String get flow3ReturnToAccountManagementLXNSAPI =>
      '3. Return to Score import credentials → LXNS API key, then paste and save';

  @override
  String get flowReopenThisDialogAfterSavingToSync =>
      'Reopen this dialog after saving to sync.';

  @override
  String get flowLinkYourDivingFishAccountToObtain =>
      'Link your Diving-Fish account to obtain an ImportToken:';

  @override
  String flowSyncSucceededButDataRefreshFailedP0(String p0) {
    return 'Sync succeeded, but data refresh failed: $p0';
  }

  @override
  String get flowSignInToYourDivingFishAccount =>
      'Sign in to your Diving-Fish account before syncing.';

  @override
  String get flowAccountMismatch => 'Account mismatch';

  @override
  String flowTheSignedInDivingFishQQP0(String p0, String p1) {
    return 'The signed-in Diving-Fish QQ ($p0) differs from the cached QQ ($p1).\n\nSign out and sign in to the correct account before syncing.';
  }

  @override
  String flowSyncCompleteP0ScoresSyncedAndLocal(String p0) {
    return 'Sync complete. $p0 scores synced and local data refreshed.';
  }

  @override
  String flowSyncCompleteP0ScoresSentToDiving(String p0) {
    return 'Sync complete. $p0 scores sent to Diving-Fish.';
  }

  @override
  String flowSyncCompleteP0ScoresExportedToLXNS(String p0) {
    return 'Sync complete. $p0 scores exported to LXNS.';
  }

  @override
  String flowEnterANewQRCodeForP0(String p0) {
    return 'Enter a new QR code for $p0';
  }

  @override
  String flowMultiPlatformSyncCompleteP0(String p0) {
    return 'Multi-platform sync complete: $p0';
  }

  @override
  String flowSyncCompleteP0P1P2(String p0, String p1, String p2) {
    return 'Sync complete: $p0$p1$p2';
  }

  @override
  String get flowNone2 => 'None';

  @override
  String flowSyncFailedP02(String p0) {
    return '\n\nSync failed:\n$p0';
  }

  @override
  String flowSyncSucceededButRefreshFailedP0(String p0) {
    return '\n\nSync succeeded, but refresh failed:\n$p0';
  }

  @override
  String get flowCouldNotSaveCredentialsTryAgain =>
      'Could not save credentials. Try again.';

  @override
  String flowCouldNotOpenTheWebsiteVisitP0(String p0) {
    return 'Could not open the website. Visit $p0 in your browser.';
  }

  @override
  String get flowRoute1 => 'Route 1';

  @override
  String get flowRoute2 => 'Route 2';

  @override
  String flowCurrentP0P1(String p0, String p1) {
    return 'Current: $p0 · $p1';
  }

  @override
  String get flowQuickSyncAlwaysUsesRoute1 => 'Quick sync always uses Route 1';

  @override
  String get flowAvailable => 'Available';

  @override
  String get flowMissing => 'Missing';

  @override
  String get flowFillInCredentialsToSelectThisSource =>
      'Fill in credentials to select this source';

  @override
  String get flowCollapse => 'Collapse';

  @override
  String get flowFillInMissingCredentials => 'Fill in missing credentials';

  @override
  String get flowGetYourImportTokenFromTheDivingFish =>
      'Get your ImportToken from the Diving-Fish website. Credentials saved through the app sign-in are detected automatically.';

  @override
  String get flowSignInToLXNSAndGetYour =>
      'Sign in to LXNS and get your personal API key in account settings.';

  @override
  String get flowEnterTheQQLinkedToAWMCNET =>
      'Enter the QQ linked to AWMC NET. Import also needs the Import-Token generated at the bottom of its website settings.';

  @override
  String get flowOpenWebsite => 'Open website';

  @override
  String get flowAWMCNETQQID => 'AWMC NET QQ ID';

  @override
  String get flowSaveAndSelect => 'Save and select';

  @override
  String get flowNormalSyncRequiresANewCabinetQR =>
      'Normal sync requires a new cabinet QR before each target. A QR is never reused for a second request. Quick sync needs no QR.';

  @override
  String get flowSourcesWithSavedCredentialsAreSelectedBy =>
      'Sources with saved credentials are selected by default. Sync order: Diving-Fish → LXNS → AWMC NET.';

  @override
  String get flowReloadCredentials => 'Reload credentials';

  @override
  String get flowAWMCNETOverwritesMatchingRecordsWithCabinet =>
      'AWMC NET overwrites matching records with cabinet scores.';

  @override
  String flowStartSyncP0(String p0) {
    return 'Start sync ($p0)';
  }

  @override
  String get flowRefreshDataAfterSync => 'Refresh data after sync';

  @override
  String get flowRefreshAutomaticallyAfterUploadRefreshErrorsAre =>
      'Refresh automatically after upload. Refresh errors are reported separately.';

  @override
  String get flowCouldNotReadRefreshSettingsUploadCan =>
      'Could not read refresh settings. Upload can continue; refresh errors are reported separately.';

  @override
  String get flowReloadRefreshSettings => 'Reload refresh settings';

  @override
  String get flowQuickSync => 'Quick sync';

  @override
  String get flowCheckingCachedUserCredentials =>
      'Checking cached user credentials…';

  @override
  String get flowCabinetIdentityLinkedNoQRNeededThis =>
      'Cabinet identity linked. No QR needed this time.';

  @override
  String get flowChooseASyncSourceFirst => 'Choose a sync source first';

  @override
  String get flowEnterAQRToLinkCabinetIdentity =>
      'Enter a QR to link cabinet identity';

  @override
  String get flowUserCredentialsCached => 'User credentials cached';

  @override
  String get flowUserCredentialsNotCached => 'User credentials not cached';

  @override
  String get flowValidatingQRCode => 'Validating QR code…';

  @override
  String get flowLinkCabinetIdentityUsingQR => 'Link cabinet identity using QR';

  @override
  String get flowUpdatesAchievementAndDXScoresComboAnd =>
      'Updates achievement and DX scores. Combo and sync markers keep each target’s existing values. UTAGE charts and play counts are not updated yet.';

  @override
  String get flowCouldNotDeleteCredentialsTryAgain =>
      'Could not delete credentials. Try again.';

  @override
  String get flowDeleteUserCredentials => 'Delete user credentials';

  @override
  String get flowAllThreeSourcesShareTheseCredentialsDeleting =>
      'All three sources share these credentials. Deleting them disables all auto sync.';

  @override
  String get flowCabinetIdentityCachedQuickSyncIsReady =>
      'Cabinet identity cached. Quick sync is ready.';

  @override
  String flowCouldNotLinkCabinetIdentityP0(String p0) {
    return 'Could not link cabinet identity: $p0';
  }

  @override
  String get flowReadsOnlyUserIdForQuickSyncDoes =>
      'Reads only userId for quick sync. Does not fetch scores or run normal sync.';

  @override
  String get flowVerifyAndSave => 'Verify and save';

  @override
  String get flowValidQRStringDetectedAndFilledIn =>
      'Valid QR string detected and filled in';

  @override
  String get flowClipboardIsEmpty => 'Clipboard is empty';

  @override
  String get flowClipboardContentIsNotAValidLogin =>
      'Clipboard content is not a valid login QR. Fill it in anyway?';

  @override
  String get flowFillIn => 'Fill in';

  @override
  String get flowNoQRCodeFoundInTheImage => 'No QR code found in the image';

  @override
  String get flowCouldNotReadQRContentFromThe =>
      'Could not read QR content from the image';

  @override
  String get flowQRCodeDetectedAndFilledIn => 'QR code detected and filled in';

  @override
  String flowRecognitionFailedP0(String p0) {
    return 'Recognition failed: $p0';
  }

  @override
  String flowScanFailedP0(String p0) {
    return 'Scan failed: $p0';
  }

  @override
  String get flowReadClipboard => 'Read clipboard';

  @override
  String get flowReadFromGallery => 'Read from gallery';

  @override
  String get flowScanQRCode => 'Scan QR code';

  @override
  String flowCameraErrorP0(String p0) {
    return 'Camera error: $p0';
  }

  @override
  String get flowBack => 'Back';

  @override
  String get flowCouldNotOpenTheLinkCopiedTo =>
      'Could not open the link. Copied to clipboard; paste it into your browser.';

  @override
  String get flowStillNoQQIDFoundCheckThat =>
      'Still no QQ ID found. Check that it is saved on Diving-Fish, or sign in again.';

  @override
  String flowLinkedQQFoundP0(String p0) {
    return 'Linked QQ found: $p0';
  }

  @override
  String get flowNoQQIDFound => 'No QQ ID found';

  @override
  String get flowAuthorizationOpenedReturnAfterAuthorizingAndTap =>
      'Authorization opened. Return after authorizing and tap “Authorized. Check again.”';

  @override
  String get flowAuthorizedYouCanNowRefreshData =>
      'Authorized. You can now refresh data.';

  @override
  String get flowAuthorizationNotDetectedApproveAccessInYour =>
      'Authorization not detected. Approve access in your browser.';

  @override
  String get flowCheckFailedVerifyYourConnectionAndTry =>
      'Check failed. Verify your connection and try again.';

  @override
  String get flowCurrentDataSource => 'Current data source: ';

  @override
  String get flowConfirm => 'Confirm';

  @override
  String get flowLXNSAuthorizationSavedItRenewsAutomaticallyNo =>
      'LXNS authorization saved. It renews automatically; no new code is needed.';

  @override
  String get flowAuthorize2 => 'Authorize';

  @override
  String get flowAuthorizationButtonNotWorking =>
      'Authorization button not working?';

  @override
  String get flowCopyThisLinkAndOpenItManually =>
      'Copy this link and open it manually in your browser to authorize:';

  @override
  String get flowCopyAuthorizationLink => 'Copy authorization link';

  @override
  String get flowAuthorizationLinkCopiedPasteItIntoYour =>
      'Authorization link copied. Paste it into your browser.';

  @override
  String get flowAfterAuthorizingCopyTheCodeShownOn =>
      'After authorizing, copy the code shown on the page and paste it below';

  @override
  String get flowEnterAuthorizationCode => 'Enter authorization code';

  @override
  String get flowPasteAuthorizationCode => 'Paste authorization code';

  @override
  String get flowQQID => 'QQ ID';

  @override
  String get flowEnterAQQIDAlreadyLinkedOn =>
      'Enter a QQ ID already linked on AWMC NET';

  @override
  String get flowNoSignInNeeded => 'No sign-in needed';

  @override
  String get flowAWMCNETIsAThirdPartyScore =>
      'AWMC NET is a third-party score tracker with public QQ-based lookup. No sign-in or authorization is needed.\nThe QQ must already be linked and have uploaded scores on net.wmc.pub, or no data will be found.';

  @override
  String get flowLinkQQUploadScoresOnAWMCNET =>
      'Link QQ / upload scores on AWMC NET';

  @override
  String get flowForceFullRefreshIgnoreStaticCaches =>
      'Force full refresh (ignore static caches)';

  @override
  String get flowMaidataStillUpdatesAsASeparateBackground =>
      'maidata still updates as a separate background task';

  @override
  String get flowSignInThroughMeSignInTo =>
      'Sign in through Me → Sign in to Diving-Fish first';

  @override
  String get flowYourDivingFishAccountHasNoQQ =>
      'Your Diving-Fish account has no QQ ID. Add it in Edit profile on the website.';

  @override
  String get flowEnterYourLXNSAuthorizationCodeFirst =>
      'Enter your LXNS authorization code first';

  @override
  String get flowEnterYourAWMCNETQQID => 'Enter your AWMC NET QQ ID';

  @override
  String get flowInvalidQQID512DigitsRequired =>
      'Invalid QQ ID (5–12 digits required)';

  @override
  String get flowCannotRefreshWithoutAConnectionConnectAnd =>
      'Cannot refresh without a connection. Connect and try again.';

  @override
  String get flowCouldNotOpenABrowserLinkCopied2 =>
      'Could not open a browser. Link copied; paste it into your browser.';

  @override
  String get flowAWMCNETOffersPublicScoreLookupBy =>
      'AWMC NET offers public score lookup by QQ, without sign-in or authorization.\nThe QQ must be linked and have uploaded scores on net.wmc.pub.';

  @override
  String get flowForceRefreshCachedData => 'Force refresh cached data';

  @override
  String get flowDeselectAll => 'Deselect all';

  @override
  String get flowSelectAll => 'Select all';

  @override
  String get flowSelectedCachesAreIgnoredAndFetchedFrom =>
      'Selected caches are ignored and fetched from the network this time. Unselected caches are reused when available.';

  @override
  String get flowLoading2 => 'Loading…';

  @override
  String flowConnectedP0P1Ms(String p0, String p1) {
    return 'Connected: $p0 · $p1 ms';
  }

  @override
  String flowFailedP0P1Ms(String p0, String p1) {
    return 'Failed: $p0 ($p1 ms)';
  }

  @override
  String get flowTest => 'Test';

  @override
  String get flowRoute => 'Route';

  @override
  String flowP0LastRefreshFailedShowingOlderData(String p0) {
    return '$p0 · Last refresh failed; showing older data';
  }

  @override
  String flowP0Last100P1SamplesAvgP2(
      String p0, String p1, String p2, String p3) {
    return '$p0: last 100 / $p1 samples / avg $p2 / $p3% success';
  }

  @override
  String get flowSyncStatistics => 'Sync statistics';

  @override
  String flowTracksDurationAndOutcomeForTheLatest(String p0) {
    return 'Tracks duration and outcome for the latest $p0 syncs. Shared across users; no QR or account details are included.';
  }

  @override
  String flowNormalSyncP0(String p0) {
    return 'Normal sync · $p0';
  }

  @override
  String get flowStatisticsUnavailable => 'Statistics unavailable';

  @override
  String get flowNoRecordsYet => 'No records yet';

  @override
  String get flowFailed => 'Failed';

  @override
  String flowP0P1UsersQueuedP2ItemsProcessing(String p0, String p1, String p2) {
    return '$p0: $p1 users queued · $p2 items processing';
  }

  @override
  String flowP0P1ChinaTime(String p0, String p1) {
    return '\n$p0: $p1 (China time)';
  }

  @override
  String get flowDifficultyFilter => 'Difficulty filter';

  @override
  String get flowRecentSearches => 'Recent searches';

  @override
  String get flowEG137Or134 => 'e.g. 13.7 or 13.4-14';

  @override
  String flowClearP0Constant(String p0) {
    return 'Clear $p0 constant';
  }

  @override
  String get flowEveryEnteredDifficultyMustMatchBlankFields =>
      'Every entered difficulty must match. Blank fields impose no limit. Combined with Difficulty above and all other filters.';

  @override
  String get flowUTAGEIsFilledInSoNormalDifficulties =>
      'UTAGE is filled in, so normal difficulties are unavailable. Clear it to restore.';

  @override
  String get flowNormalDifficultiesAreFilledInSoUTAGE =>
      'Normal difficulties are filled in, so UTAGE is unavailable. Clear all to restore.';

  @override
  String get flowConstantFilter => 'Constant filter';

  @override
  String get flowAnyDifficulty => 'Any difficulty';

  @override
  String get flowDifficultyCombination => 'Difficulty combination';

  @override
  String get flowClearConstants => 'Clear constants';

  @override
  String get flowMinimum => 'Minimum';

  @override
  String get flowMaximum => 'Maximum';

  @override
  String get flowNoteCountFilter => 'Note count filter';

  @override
  String get flowMinimumNotes => 'Minimum notes';

  @override
  String get flowMaximumNotes => 'Maximum notes';

  @override
  String get flowBPMFilter => 'BPM filter';

  @override
  String get flowMinimumBPM => 'Minimum BPM';

  @override
  String get flowMaximumBPM => 'Maximum BPM';

  @override
  String get flowVersionFilter => 'Version filter';

  @override
  String get flowGenreFilter => 'Genre filter';

  @override
  String get flowTagFilter => 'Tag filter';

  @override
  String get flowNoTagData => 'No tag data';

  @override
  String get flowCharterFilter => 'Charter filter';

  @override
  String get flowArtistFilter => 'Artist filter';

  @override
  String get flowClearSelection => 'Clear selection';

  @override
  String flowLevelP0(String p0) {
    return 'Level $p0';
  }

  @override
  String get flowDXChartsOnly => 'DX charts only';

  @override
  String get flowTitlesOnly => 'Titles only';

  @override
  String get flowSearching => 'Searching…';

  @override
  String get flowEnterASearchKeyword => 'Enter a search keyword';

  @override
  String flowP0SongsInTheLibraryEnterA(String p0) {
    return '$p0 songs in the library. Enter a keyword.';
  }

  @override
  String flowP0SongsFound15PerPage(String p0) {
    return '$p0 songs found · 15 per page';
  }

  @override
  String get flowReset => 'Reset';

  @override
  String get flowNoSongsMatchTheseFilters => 'No songs match these filters';

  @override
  String get flowTryAWiderConstantRangeOrClear =>
      'Try a wider constant range or clear filters';

  @override
  String get flowPrevious => 'Previous';

  @override
  String get flowNext => 'Next';

  @override
  String flowCoverIndexReadyProcessedP0Covers(String p0) {
    return 'Cover index ready. Processed $p0 covers.';
  }

  @override
  String flowCouldNotBuildIndexP0(String p0) {
    return 'Could not build index: $p0';
  }

  @override
  String get flowChooseImageSource => 'Choose image source';

  @override
  String get flowTakePhoto => 'Take photo';

  @override
  String get flowPhotographCoverArt => 'Photograph cover art';

  @override
  String get flowChooseACoverScreenshotFromYourGallery =>
      'Choose a cover screenshot from your gallery';

  @override
  String get flowCameraPermissionRequired => 'Camera permission required';

  @override
  String flowCouldNotSelectImageP0(String p0) {
    return 'Could not select image: $p0';
  }

  @override
  String get flowRecognitionFailedTryAgain => 'Recognition failed. Try again.';

  @override
  String flowRecognitionErrorP0(String p0) {
    return 'Recognition error: $p0';
  }

  @override
  String get flowRebuildCoverIndex => 'Rebuild cover index';

  @override
  String get flowThisClearsTheIndexAndRecalculatesHashes =>
      'This clears the index and recalculates hashes for all covers. It may take tens of seconds. Continue?';

  @override
  String get flowRebuild => 'Rebuild';

  @override
  String get flowLoading3 => 'Loading…';

  @override
  String get flowBuildingCoverIndex => 'Building cover index…';

  @override
  String flowComputingFeaturesForP0Covers(String p0) {
    return 'Computing features for $p0 covers';
  }

  @override
  String get flowNeededOnlyOncePleaseWait => 'Needed only once. Please wait.';

  @override
  String get flowTakeOrChooseACoverImage => 'Take or choose a cover image';

  @override
  String get flowCropTheCoverRegionAfterSelectingFor =>
      'Crop the cover region after selecting for more accurate recognition';

  @override
  String get flowImageReady => 'Image ready';

  @override
  String get flowMatchConfidenceIsTooLowThisMay =>
      'Match confidence is too low. This may not be cover art; adjust the crop and try again.';

  @override
  String get flowInputImage => 'Input image';

  @override
  String get flowMatchedCover => 'Matched cover';

  @override
  String get flowCombinedMatchUnreliable => 'Combined match (unreliable)';

  @override
  String get flowCombinedMatch => 'Combined match';

  @override
  String get flowTop10Matches => 'Top 10 matches';

  @override
  String flowSongP0(String p0) {
    return 'Song #$p0';
  }

  @override
  String get flowChooseImage => 'Choose image';

  @override
  String get flowRecognizing => 'Recognizing…';

  @override
  String get flowStartRecognition => 'Start recognition';

  @override
  String get flowCropAgain => 'Crop again';

  @override
  String get flowChooseAgain => 'Choose again';

  @override
  String get flowRecognizeAgain => 'Recognize again';

  @override
  String get flowChooseAnother => 'Choose another';

  @override
  String get flowCoverIndexReady => 'Cover index ready';

  @override
  String get flowIndexNotBuilt => 'Index not built';

  @override
  String get flowRebuildIndex => 'Rebuild index';

  @override
  String get flowCannotReadThisImageTryAnother =>
      'Cannot read this image. Try another.';

  @override
  String get flowCropFailedContinuingWithTheOriginalImage =>
      'Crop failed. Continuing with the original image.';

  @override
  String get flowDragTheCornersToSelectCoverArt =>
      'Drag the corners to select cover art';

  @override
  String get flowProcessing => 'Processing…';

  @override
  String get flowDragCornersToResizeDragInsideTo =>
      'Drag corners to resize · Drag inside to move';

  @override
  String get flowNoDivingFishImportTokenSignIn =>
      'No Diving-Fish Import-Token. Sign in to Diving-Fish first.';

  @override
  String flowAddedToDivingFishP0(String p0) {
    return 'Added to Diving-Fish: $p0';
  }

  @override
  String flowDivingFishScoreUpdatedP0(String p0) {
    return 'Diving-Fish score updated: $p0';
  }

  @override
  String get flowCannotParseSongIDForLXNSSync =>
      'Cannot parse song ID for LXNS sync';

  @override
  String get flowNoLXNSPersonalAPIKeySetIt =>
      'No LXNS personal API key. Set it in Score import credentials first.';

  @override
  String get flowPhotographTheCabinetResultScreen =>
      'Photograph the cabinet result screen';

  @override
  String get flowChooseAPhotographedResultScreen =>
      'Choose a photographed result screen';

  @override
  String get flowNoScoreRecognizedCropCloserToThe =>
      'No score recognized. Crop closer to the result area and try again.';

  @override
  String get flowCorrectRecognitionResults => 'Correct recognition results';

  @override
  String get flowRecognitionIsNotAlwaysAccurateEditedValues =>
      'Recognition is not always accurate. Edited values replace the displayed card values.';

  @override
  String get flowDifficulty => 'Difficulty';

  @override
  String get flowSelectASongFirstToListIts =>
      'Select a song first to list its available difficulties';

  @override
  String flowConstantP0(String p0) {
    return 'Constant $p0';
  }

  @override
  String flowConstantP02(String p0) {
    return ' · Constant $p0';
  }

  @override
  String get flowAchievement => 'Achievement (%)';

  @override
  String get flowDXScore => 'DX score';

  @override
  String get flowCombo => 'Combo';

  @override
  String get flowSync => 'Sync';

  @override
  String get flowEmptyMeansNoMarkerSyncMarkersUse =>
      'Empty means no marker. Sync markers use Diving-Fish values (FS / FS+ / FDX / FDX+ / SYNC).';

  @override
  String get flowRestoreRecognizedValues => 'Restore recognized values';

  @override
  String get flowEmpty => 'Empty';

  @override
  String get flowNoSongData => 'No song data';

  @override
  String get flowNoMatchingSong => 'No matching song';

  @override
  String get flowRecognizingScores => 'Recognizing scores';

  @override
  String get flowMatchingCoverArtAndTitlesUsuallyTakes =>
      'Matching cover art and titles. Usually takes a few seconds.';

  @override
  String get flowPhotographACabinetResultScreen =>
      'Photograph a cabinet result screen';

  @override
  String get flowRecognizesTitleAchievementDXScoreDifficultyAnd =>
      'Recognizes title, achievement, DX score, difficulty and FC/FS';

  @override
  String get flowImageReadyTapStartRecognitionBelow =>
      'Image ready. Tap Start recognition below.';

  @override
  String flowRecognitionCompleteP0P1Succeeded(String p0, String p1) {
    return 'Recognition complete · $p0/$p1 succeeded';
  }

  @override
  String get flowCouldNotRecognizeAScore => 'Could not recognize a score';

  @override
  String get flowSongTitleNotRecognized => 'Song title not recognized';

  @override
  String get flowAchievement2 => 'Achievement';

  @override
  String flowMatchSourceP0(String p0) {
    return 'Match source: $p0';
  }

  @override
  String get flowEditThisResult => 'Edit this result';

  @override
  String get flowSyncing => 'Syncing…';

  @override
  String get flowSyncToDivingFish => 'Sync to Diving-Fish';

  @override
  String get flowSyncToLXNS => 'Sync to LXNS';

  @override
  String flowCannotSyncYetP0(String p0) {
    return 'Cannot sync yet: $p0';
  }

  @override
  String flowOtherCandidatesP0(String p0) {
    return 'Other candidates: $p0';
  }

  @override
  String get flowRecognizeAgain2 => 'Recognize again';

  @override
  String get flowUseAnotherImage => 'Use another image';

  @override
  String get flowClearAndChooseAgain => 'Clear and choose again';

  @override
  String get flowSignInToMaimaiScoreHubFirst =>
      'Sign in to maimai Score Hub first';

  @override
  String get flowResultRecognitionRequiresSignInRequestA =>
      'Result recognition requires sign-in. Request a login QR from the maimai/CHUNITHM WeChat account and paste the scanned string below. Used only for authentication; no scores are fetched or synced. Sign-in is saved on this device.';

  @override
  String get flowSigningIn2 => 'Signing in…';

  @override
  String get flowDragCornersToSelectTheResultArea =>
      'Drag corners to select the result area';

  @override
  String get flowStoragePermissionIsNeededToSaveVersion =>
      'Storage permission is needed to save version images. Enable it in settings.';

  @override
  String get flowImageSavedToGallery => 'Image saved to gallery';

  @override
  String flowSaveFailedP0(String p0) {
    return 'Save failed: $p0';
  }

  @override
  String get flowSaveImage => 'Save image';

  @override
  String get flowJapan => 'Japan';

  @override
  String get flowChina => 'China';

  @override
  String get flowJapanVersion => 'Japan version';

  @override
  String get flowChinaVersion => 'China version';

  @override
  String flowP0VersionsInReleaseOrderTapAn(String p0) {
    return '$p0 versions in release order. Tap an image to enlarge or save it.';
  }

  @override
  String flowP0VersionImageNotAvailableYet(String p0) {
    return '$p0, version image not available yet';
  }

  @override
  String flowP0ViewVersionImage(String p0) {
    return '$p0, view version image';
  }

  @override
  String get flowImagePending => 'Image pending';

  @override
  String get flowVersionImageNotAvailableYet =>
      'Version image not available yet';

  @override
  String get flowTapToEnlarge => 'Tap to enlarge';

  @override
  String get flowAboutThisComparison => 'About this comparison';

  @override
  String get flowNoSongsInThisSection => 'No songs in this section';

  @override
  String get flowChinaDivingFishUpdateFrontier =>
      'China (Diving-Fish) update frontier';

  @override
  String flowJapanDebutP0P1(String p0, String p1) {
    return 'Japan debut $p0 · $p1';
  }

  @override
  String get flowFirstReleaseMeansTheJapanReleaseDate =>
      'First release means the Japan release date, not the China date. Candidates use debut dates and confirmed pending batches; IDs are a fallback only when dates are missing. New songs with smaller IDs are included.';

  @override
  String flowExcludedP0SongsReleasedEarlyInChina(String p0, String p1) {
    return 'Excluded $p0 songs released early in China ($p1); they would raise the frontier and hide truly pending songs.';
  }

  @override
  String flowP0P1JapanP2(String p0, String p1, String p2) {
    return '#$p0 · $p1 · Japan $p2';
  }

  @override
  String get flowNoCachedLibraryYet => 'No cached library yet';

  @override
  String get flowThisPageUsesTheLocalDivingFish =>
      'This page uses the local Diving-Fish + union library.\nRun Pull scores & update data from Home first, then return.';

  @override
  String get flowHowThisPageWorks => 'How this page works';

  @override
  String get flow1DataSources => '1. Data sources';

  @override
  String get flowTheLocalLibraryCombinesDivingFishAll =>
      'The local library combines Diving-Fish (all China songs) and union (all songs). union-only entries are marked isExtra. Confirmed early-China releases override this flag. This page works fully offline.';

  @override
  String get flow2DefiningTheUpdateFrontier =>
      '2. Defining the update frontier';

  @override
  String get flowRegularChinaSongsInDivingFishAre =>
      'Regular China songs in Diving-Fish are sorted by debut date; the newest sets the China frontier. Missing or invalid dates use IDs.\nUTAGE (six-digit IDs) and extra maidata songs are excluded.\nEarly-China releases are also excluded so they do not hide genuinely pending songs.';

  @override
  String get flow3CompletingTheCandidateList =>
      '3. Completing the candidate list';

  @override
  String get flowStartWithUnionOnlyRegularSongsUsing =>
      'Start with union-only regular songs, using the frontier Japan debut date. Move the start earlier if a confirmed pending batch contains older missing songs.\nInclude all songs from that date onward, including the same day and smaller IDs.\nUse IDs only for missing or invalid dates; confirmed pending songs are always retained.\nOlder songs are listed separately without claiming regional exclusivity. Candidates are a reference; official announcements decide actual updates.';

  @override
  String get flow4WhatFirstReleaseMeans => '4. What First release means';

  @override
  String get flowTheDebutDatesFromDivingFishAnd =>
      'The debut dates from Diving-Fish and union are Japan dates, not China release dates. This is why a song detail debut date alone does not show whether it has reached China.';

  @override
  String get flowUpdateDataTemporarilyUnavailable =>
      'Update data temporarily unavailable';

  @override
  String get flowRetry => 'Retry';

  @override
  String get flowReleaseContents => 'Release contents';

  @override
  String get flowCouldNotLoadReleaseDataRetry =>
      'Could not load release data. Retry.';

  @override
  String get flowNoContentDetails => 'No content details';

  @override
  String flowP0OtherItemsNotShown(String p0) {
    return '$p0 other items not shown';
  }

  @override
  String get flowLXNSMaimaiDXScoreTracker => 'LXNS maimai DX score tracker';

  @override
  String get flowPreviousMonthWithUpdates => 'Previous month with updates';

  @override
  String flowChooseYearAndMonthCurrentP0P1(String p0, String p1) {
    return 'Choose year and month. Current: $p0/$p1';
  }

  @override
  String flowP0P1(String p0, String p1) {
    return '$p0/$p1';
  }

  @override
  String get flowReleaseRecordOnly => 'Release record only';

  @override
  String flowP0UpdatesP1Songs(String p0, String p1) {
    return '$p0 updates · $p1 songs';
  }

  @override
  String get flowNextMonthWithUpdates => 'Next month with updates';

  @override
  String get flowRelease => 'Release';

  @override
  String flowP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '$p0/$p1$p2$p3';
  }

  @override
  String flowP0Songs(String p0) {
    return ', $p0 songs';
  }

  @override
  String get flowReleaseRecorded => ', release recorded';

  @override
  String get flowNotReleasedYet => '  Not released yet';

  @override
  String get flowReleaseRecord => 'Release record';

  @override
  String flowP0SongsP1Charts(String p0, String p1) {
    return '$p0 songs · $p1 charts';
  }

  @override
  String flowMonthP0(String p0) {
    return 'Month $p0';
  }

  @override
  String get flowChooseYearAndMonth => 'Choose year and month';

  @override
  String flowYearP0(String p0) {
    return 'Year $p0';
  }

  @override
  String get flowNoData => 'No data';

  @override
  String flowLvP0P1SongsP2Played(String p0, String p1, String p2) {
    return 'Lv.$p0\n$p1 songs\n$p2 played';
  }

  @override
  String flowLvP0P1P2Songs(String p0, String p1, String p2) {
    return 'Lv.$p0 $p1 ($p2 songs)';
  }

  @override
  String get flowFilterTitleBackgroundColors =>
      'Filter title background colors';

  @override
  String get flowChooseMultipleColors => 'Choose multiple colors';

  @override
  String get flowApply => 'Apply';

  @override
  String get flowCacheClearedReloading => 'Cache cleared. Reloading…';

  @override
  String get flowCouldNotClearCache => 'Could not clear cache';

  @override
  String get flowSearchCollectibleNamesDescriptionsOrIDs =>
      'Search collectible names, descriptions or IDs';

  @override
  String get flowSongRequirements => 'Song requirements';

  @override
  String get flowBackgroundColor => 'Background color';

  @override
  String get flowIDDescending => 'ID descending';

  @override
  String get flowIDAscending => 'ID ascending';

  @override
  String flowP0Items(String p0) {
    return '$p0 items';
  }

  @override
  String get flowHasUnlockRequirements => 'Has unlock requirements';

  @override
  String get flowNoMatchingCollectibles => 'No matching collectibles';

  @override
  String get flowClearCacheAndReload => 'Clear cache and reload';

  @override
  String get flowPermissionRequired => 'Permission required';

  @override
  String get flowStoragePermissionIsNeededToSaveImages =>
      'Storage permission is needed to save images. Enable it in settings.';

  @override
  String get flowExcludedSongs => 'Excluded songs';

  @override
  String flowP0SongsExcludedFromRequirements(String p0) {
    return '$p0 songs, excluded from requirements';
  }

  @override
  String get flowSongList => 'Song list';

  @override
  String flowP0SongsTotal(String p0) {
    return '$p0 songs total';
  }

  @override
  String flowTranslatedFromP0ByBaiduSLanguage(String p0) {
    return 'Translated from $p0 by Baidu’s language model';
  }

  @override
  String get flowTranslateToChinese => 'Translate to Chinese';

  @override
  String get flowSaving2 => 'Saving';

  @override
  String get flowSaveToGallery => 'Save to gallery';

  @override
  String get flowCopyLink => 'Copy link';

  @override
  String get flowDescription => 'Description';

  @override
  String get flowUnlockRequirements => 'Unlock requirements';

  @override
  String flowP0Details(String p0) {
    return '$p0 details';
  }

  @override
  String get flowCollectibleNotFound => 'Collectible not found';

  @override
  String get flowCouldNotRefreshData => 'Could not refresh data';

  @override
  String flowQQP0HasNotAuthorizedThisApp(String p0) {
    return 'QQ $p0 has not authorized this app. Complete authorization in Accounts and sync.';
  }

  @override
  String get flowAuthorizationNeeded => 'Authorization needed';

  @override
  String get flowThisQQHasNotAuthorizedTheApp =>
      'This QQ has not authorized the app. The authorization page is open; refresh again after completing it.';

  @override
  String get flowThisQQHasNotAuthorizedTheApp2 =>
      'This QQ has not authorized the app. Open the authorization page in your browser to link it.';

  @override
  String flowCouldNotRefreshDataP0(String p0) {
    return 'Could not refresh data: $p0';
  }

  @override
  String get flowSigningOutOfDivingFish => 'Signing out of Diving-Fish…';

  @override
  String get flowEnterYourDivingFishUsernameAndPassword =>
      'Enter your Diving-Fish username and password';

  @override
  String get flowCouldNotLinkDivingFishTryAgain =>
      'Could not link Diving-Fish. Try again.';

  @override
  String get flowSyncSucceededRefreshingLocalData =>
      'Sync succeeded. Refreshing local data…';

  @override
  String get flowExportFailedTryAgain => 'Export failed. Try again.';

  @override
  String get flowPreparingSync => 'Preparing sync…';

  @override
  String flowP0ScoresSentToDivingFishSign(String p0) {
    return '$p0 scores sent to Diving-Fish.\nSign in to Diving-Fish to refresh local data automatically.';
  }

  @override
  String get flowSyncCancelled => 'Sync cancelled';

  @override
  String get flowEnterUsernameAndPassword => 'Enter username and password';

  @override
  String flowWelcomeP0P1(String p0, String p1) {
    return 'Welcome, $p0$p1';
  }

  @override
  String get flowAdvancedDataRefreshInProgress =>
      'Advanced data refresh in progress…';

  @override
  String get flowRefreshingData => 'Refreshing data…';

  @override
  String flowCouldNotLoadAccountDetailsP0(String p0) {
    return 'Could not load account details ($p0)';
  }

  @override
  String get flowNickname => 'Nickname';

  @override
  String get flowVersionTitle => 'Version title';

  @override
  String get flowRatingRank => 'Rating rank';

  @override
  String get flowLinkedQQ => 'Linked QQ';

  @override
  String get flowChannelID => 'Channel ID';

  @override
  String get flowBeginner => 'Beginner';

  @override
  String get flow1stDan => '1st Dan';

  @override
  String get flow2ndDan => '2nd Dan';

  @override
  String get flow3rdDan => '3rd Dan';

  @override
  String get flow4thDan => '4th Dan';

  @override
  String get flow5thDan => '5th Dan';

  @override
  String get flow6thDan => '6th Dan';

  @override
  String get flow7thDan => '7th Dan';

  @override
  String get flow8thDan => '8th Dan';

  @override
  String get flow9thDan => '9th Dan';

  @override
  String get flow10thDan => '10th Dan';

  @override
  String get flowShin1stDan => 'Shin 1st Dan';

  @override
  String get flowShin2ndDan => 'Shin 2nd Dan';

  @override
  String get flowShin3rdDan => 'Shin 3rd Dan';

  @override
  String get flowShin4thDan => 'Shin 4th Dan';

  @override
  String get flowShin5thDan => 'Shin 5th Dan';

  @override
  String get flowShin6thDan => 'Shin 6th Dan';

  @override
  String get flowShin7thDan => 'Shin 7th Dan';

  @override
  String get flowShin8thDan => 'Shin 8th Dan';

  @override
  String get flowShin9thDan => 'Shin 9th Dan';

  @override
  String get flowShin10thDan => 'Shin 10th Dan';

  @override
  String get flowShinKaiden => 'Shin Kaiden';

  @override
  String get flowUraKaiden => 'Ura Kaiden';

  @override
  String get flowRefreshingMaidata => 'Refreshing maidata…';

  @override
  String flowCouldNotOpenQQGroupIDP0(String p0) {
    return 'Could not open QQ. Group ID $p0 copied; search for it in QQ.';
  }

  @override
  String get flowSongSearchFailedTheLibraryMayNot =>
      'Song search failed. The library may not be loaded yet.';

  @override
  String get flowPreparingToReadCabinetPlayCount =>
      'Preparing to read cabinet play count…';

  @override
  String get flowSigningOutOfDivingFish2 => 'Signing out of Diving-Fish…';

  @override
  String get flowStartQRSyncFromHome => 'Start QR sync from Home';

  @override
  String get flowStartSyncFromHome => 'Start sync from Home';

  @override
  String get flowEnterYourPersonalKeyAboveToEnable =>
      'Enter your personal key above to enable this';

  @override
  String flowNoP0AccountYetSignInThrough(String p0) {
    return 'No $p0 account yet. Sign in through Links & authorization and refresh data first.';
  }

  @override
  String get flowSyncCredentialsReady => 'Sync credentials ready';

  @override
  String get flowLinkTheCabinetIdentityAboveToEnable =>
      'Link the cabinet identity above to enable this';

  @override
  String get flowCouldNotReadSyncCredentialsTryAgain =>
      'Could not read sync credentials. Try again.';

  @override
  String get flowCouldNotReadAutoSyncStatusTry =>
      'Could not read auto sync status. Try again.';

  @override
  String get flowLinkCabinetIdentityAboveFirst =>
      'Link cabinet identity above first';

  @override
  String get flowSyncSetupIncomplete => 'Sync setup incomplete';

  @override
  String flowAccountEndingInP0(String p0) {
    return 'Account ending in $p0';
  }

  @override
  String get flowStatusNotConfirmedYet => 'Status not confirmed yet';

  @override
  String flowP0QueueUserPositionP1(String p0, String p1) {
    return '$p0 queue · User position $p1';
  }

  @override
  String get flowEnabledWaitingForSchedule => 'Enabled · Waiting for schedule';

  @override
  String get flowSyncing2 => 'Syncing';

  @override
  String get flowPreviousRoundNoRunYet => 'Previous round · No run yet';

  @override
  String get flowPreviousRoundUpToDateNoUpload =>
      'Previous round up to date · No upload needed';

  @override
  String flowPreviousRoundCompleteSubmittedP0(String p0) {
    return 'Previous round complete · Submitted $p0';
  }

  @override
  String flowPreviousRoundIncompleteP0(String p0) {
    return 'Previous round incomplete$p0';
  }

  @override
  String flowSubmittedP0(String p0) {
    return ' · Submitted $p0';
  }

  @override
  String flowPreviousRoundP0(String p0) {
    return 'Previous round · $p0';
  }

  @override
  String get flowLoadingStatistics => 'Loading statistics';

  @override
  String get flowUpdateFailed => 'Update failed';

  @override
  String get flowUpdatesEvery3Seconds => 'Updates every 3 seconds';

  @override
  String get flowQueuedUsers => 'Queued users';

  @override
  String get flowPendingTasks => 'Pending tasks';

  @override
  String get flowProcessing2 => 'Processing';

  @override
  String get flowProcessedUsers => 'Processed users';

  @override
  String get flowSuccessfulUsers => 'Successful users';

  @override
  String get flowFailedUsers => 'Failed users';

  @override
  String flowSubmittedP0P1(String p0, String p1) {
    return 'Submitted $p0$p1';
  }

  @override
  String flowSkippedP0UnsupportedCharts(String p0) {
    return ', skipped $p0 unsupported charts';
  }

  @override
  String flowConfirmedP0Submitted(String p0) {
    return '(Confirmed $p0 submitted)';
  }

  @override
  String get flowWaitingForScheduledRun => 'Waiting for scheduled run';

  @override
  String get flowWaitingToBeScheduled => 'Waiting to be scheduled';

  @override
  String get flowEnterACabinetLoginQRCodeFirst =>
      'Enter a cabinet login QR code first';

  @override
  String get flowLinkFailedCheckTheQRHasNot =>
      'Link failed. Check the QR has not expired and try again.';

  @override
  String get flowEnterYourPersonalKeyFirst => 'Enter your personal key first';

  @override
  String get flowAccountChangedRefreshThisPageAndEnter =>
      'Account changed. Refresh this page and enter it again.';

  @override
  String get flow1SignInThroughMeSignIn =>
      '1. Sign in to Diving-Fish through Me → Links & authorization to get an ImportToken.\n2. Open Score import credentials → Diving-Fish score import Token and copy it.\n3. Paste it here and save.';

  @override
  String get flowQuickSyncing => 'Quick syncing…';

  @override
  String get flowCheckingAWMCGateway => 'Checking AWMC gateway…';

  @override
  String flowAWMCGatewayUnavailableP0SyncCancelledNo(String p0) {
    return 'AWMC gateway unavailable ($p0). Sync cancelled; no Token spent.';
  }

  @override
  String flowSyncingToP0ThroughAWMCGateway(String p0) {
    return 'Syncing to $p0 through AWMC gateway…';
  }

  @override
  String flowP0ScoresAreUpToDateNo(String p0) {
    return '$p0 scores are up to date. No upload needed.';
  }

  @override
  String flowQuickSyncCompleteSubmittedP1ChangedScores(String p0, String p1) {
    return 'Quick sync complete. Submitted $p1 changed scores to $p0.';
  }

  @override
  String flowP0ScoresTotal(String p0) {
    return '$p0 scores total';
  }

  @override
  String get flowSentToDivingFishThroughAWMCGateway =>
      'Sent to Diving-Fish through AWMC gateway';

  @override
  String get flowExportedToLXNSThroughAWMCGateway =>
      'Exported to LXNS through AWMC gateway';

  @override
  String flowSyncCompleteP0P1(String p0, String p1) {
    return 'Sync complete. $p0$p1';
  }

  @override
  String get flowNoCachedDivingFishImportTokenSignIn =>
      'No cached Diving-Fish ImportToken. Sign in and sync once using Route 2 (maimai Score Hub) to save it locally.';

  @override
  String get flowNoCachedLXNSPersonalAPIKeySync =>
      'No cached LXNS personal API key. Sync once and enter your key to save it locally.';

  @override
  String get flowReadingCabinetPlayCount => 'Reading cabinet play count…';

  @override
  String get flowEndpoint => 'Endpoint';

  @override
  String get flowResult => 'Result';

  @override
  String get flowBusinessOperationSucceeded => 'Business operation succeeded';

  @override
  String flowUpstreamMessageTruncatedFullLengthP0Characters(String p0) {
    return 'Upstream message truncated (full length: $p0 characters)';
  }

  @override
  String get flowDuration => 'Duration';

  @override
  String get flowBilling => 'Billing';

  @override
  String get flowGetThisTokenFromTheAWMCConsole =>
      'Get this Token from the AWMC console (api.wmc.pub); it looks like gw_xxxx.\n\n⚠️ It grants access to account operations and balance. Do not screenshot it or paste it into chats or public repositories. If exposed, revoke it in the console and generate a new one.';

  @override
  String get flowTokenStaysOnThisDeviceCanBe =>
      'Token stays on this device, can be cleared anytime and is excluded from backups.';

  @override
  String get flowEnterCabinetQRCode => 'Enter cabinet QR code';

  @override
  String get flowUsedOnlyForThisOperationThenDiscarded =>
      'Used only for this operation, then discarded. Not saved or cached; the next operation asks again.';

  @override
  String get flowUse => 'Use';

  @override
  String get flowThisKeyIsSentOnlyWithThis =>
      'This key is sent only with this request to the AWMC gateway and is not stored locally.';

  @override
  String get flowContinue => 'Continue';

  @override
  String get flowTokenCost => 'Token cost';

  @override
  String flowP0ChargedOnlyOnSuccess(String p0) {
    return '$p0 (charged only on success)';
  }

  @override
  String get flowNoTokenSpent => 'No Token spent';

  @override
  String get flowReversible => 'Reversible';

  @override
  String get flowYesUploadAgainToOverwrite => 'Yes (upload again to overwrite)';

  @override
  String get flowNo => 'No';

  @override
  String get flowIUnderstandTheEffectsAboveAndConfirm =>
      'I understand the effects above and confirm this QR belongs to my own account';

  @override
  String get flowWrite => 'Write';

  @override
  String flowImportingScoresWaitingP0Seconds(String p0) {
    return 'Importing scores… Waiting $p0 seconds';
  }

  @override
  String get flowImportFailed => 'Import failed';

  @override
  String get flowScoresAreUpToDateNoUpload =>
      'Scores are up to date. No upload needed.';

  @override
  String flowQuickSyncCompleteSubmittedP0ChangedScores(String p0) {
    return 'Quick sync complete. Submitted $p0 changed scores.';
  }

  @override
  String flowImportCompleteAddedP0UpdatedP1(String p0, String p1) {
    return 'Import complete. Added $p0 / Updated $p1';
  }

  @override
  String flowSkippedP0(String p0) {
    return ' / Skipped $p0';
  }

  @override
  String flowP0Seconds(String p0) {
    return ' ($p0 seconds)';
  }

  @override
  String flowP0ChartsAreNotYetInAWMC(String p0) {
    return '; $p0 charts are not yet in AWMC NET';
  }

  @override
  String flowP0Account(String p0) {
    return '$p0 account';
  }

  @override
  String get flowNotLinked => 'Not linked';

  @override
  String get flowThenChooseRegisterUnderQuickActionsOn =>
      ', then choose Register under Quick actions on the right.';

  @override
  String get flowFollowThePageInstructionsToRegisterA =>
      'Follow the page instructions to register a Diving-Fish account.';

  @override
  String get flowAfterSigningInOpenEditProfileAt =>
      'After signing in, open Edit profile at the top right and configure these settings:';

  @override
  String get flowScoreImportTokenRotateItUsingThe =>
      'Score import Token: rotate it using the refresh icon, or app sign-in will not work.';

  @override
  String get flowLinkedQQRequiredAvoidUsingTheSame =>
      'Linked QQ: required. Avoid using the same QQ for alternate accounts.';

  @override
  String get flowNicknameRecommendedWithoutOneTheAppSaves =>
      'Nickname: recommended. Without one, the app saves the account as shuiyu:QQ.';

  @override
  String get flowChannelIDAndRankNoSpecificRequirements =>
      'Channel ID and rank: no specific requirements.';

  @override
  String get flowDisablePreventPublicAPIsFromUsingMy =>
      'Disable “Prevent public APIs from using my scores”.';

  @override
  String get flowDisableMaskingScoresForNonWebQueries =>
      'Disable masking scores for non-web queries; masking affects leaderboards.';

  @override
  String get flowRememberToSaveAfterMakingChanges =>
      'Remember to save after making changes.';

  @override
  String get flowThenChooseNewUserRegistrationInThe =>
      ', then choose New user registration in the sidebar or Register a maimai DX tracker account in the center.';

  @override
  String get flowFollowThePageInstructionsToRegisterAn =>
      'Follow the page instructions to register an LXNS account.';

  @override
  String get flowAfterSigningInOpenAccountDetailsIn =>
      'After signing in, open Account details in the sidebar, then Third-party apps:';

  @override
  String get flowOAuthInMeRefreshDataChooseLXNS =>
      'OAuth: in Me → Pull scores & update data, choose LXNS and follow the authorization guide. ChiffonMai then appears in the OAuth app list.';

  @override
  String get flowPersonalAPIKeyResetItThenPaste =>
      'Personal API key: reset it, then paste it into Me → Score import credentials → LXNS API key.';

  @override
  String get flowYouCanAlsoVisitChiffonChuFromThe =>
      'You can also visit ChiffonChu from the Play → Arcade carousel.';

  @override
  String get flowMessage => 'Message ';

  @override
  String get flowPrivatelyOrFollowTheseStepsInA =>
      ' privately, or follow these steps in a group with the bot:';

  @override
  String get flowSendTheSGWCMAIDStringOrMaimaiQR =>
      'Send the SGWCMAID string or maimai QR as instructed and wait for the bot to confirm upload.';

  @override
  String get flowAndConfigureTheseSettings => ' and configure these settings:';

  @override
  String get flowEnableMakeMyScoresPublicOrScores =>
      'Enable “Make my scores public”, or scores cannot be read.';

  @override
  String get flowImportTokenRegenerateItThenPasteIt =>
      'Import-Token: regenerate it, then paste it in Me → Score import credentials → AWMC score import Token.';

  @override
  String get flowRotatingATokenReplacesTheOldOne =>
      'Rotating a Token replaces the old one. Update it manually in the app afterward, or sync will fail.';

  @override
  String get flowJoin => 'Join ';

  @override
  String get flowCouldNotOpenQQAWMCGroup1 =>
      'Could not open QQ. AWMC group 1 ID copied; search for it in QQ.';

  @override
  String get flowCouldNotOpenQQAWMCGroup2 =>
      'Could not open QQ. AWMC group 2 ID copied; search for it in QQ.';

  @override
  String get flowCloseImage => 'Close image';

  @override
  String get flowTheAppNeedsYourLinkedQQBefore =>
      'The app needs your linked QQ before reading Diving-Fish scores.\nSign in through Me → Sign in to Diving-Fish, then return.';

  @override
  String get flowTheAppIdentifiesYourDivingFishAccount =>
      'The app identifies your Diving-Fish account by QQ, but Linked QQ is empty.\nFill in this missing profile field to read scores.';

  @override
  String get flow1OpenDivingFishAndSignIn => '1. Open Diving-Fish and sign in';

  @override
  String get flow2OpenEditProfileEnterLinkedQQ =>
      '2. Open Edit profile, enter Linked QQ and save';

  @override
  String get flow3ReturnAndTapISavedIt =>
      '3. Return and tap “I saved it. Read again.”';

  @override
  String get flowSignInToMaimaiScoreHubFirst2 =>
      'Sign in to maimai Score Hub first';

  @override
  String get flowPasteOrScanALoginQRCode => 'Paste or scan a login QR code';

  @override
  String get flowUseALoginQRFromTheMaimai =>
      'Use a login QR from the maimai/CHUNITHM WeChat account';

  @override
  String get flowMaimaiScoreHubSignInFailedThe =>
      'maimai Score Hub sign-in failed. The QR may have expired; generate a new one.';

  @override
  String flowSignInFailedP0(String p0) {
    return 'Sign-in failed: $p0';
  }

  @override
  String get flowNoLXNSPersonalAPIKeySetConfigure =>
      'No LXNS personal API key set. Configure it in Score import credentials first.';

  @override
  String get flowQuickSyncSupportsRoute1Only =>
      'Quick sync supports Route 1 only';

  @override
  String get flowMaimaiScoreHubSessionExpiredSignIn =>
      'maimai Score Hub session expired. Sign in again before Route 2 sync.';

  @override
  String get flowSyncCompleteRefreshingLocalData =>
      'Sync complete. Refreshing local data…';

  @override
  String get flowLinkDivingFishToObtainAnImportToken =>
      'Link Diving-Fish to obtain an ImportToken. Reopen Sync to Diving-Fish to finish linking.';

  @override
  String get flowDoneLocalDataRefreshed => 'Done. Local data refreshed.';

  @override
  String get flowSyncComplete => 'Sync complete!';

  @override
  String flowP0ScoresSentToDivingFishData(String p0, String p1) {
    return '$p0 scores sent to Diving-Fish.\nData refresh failed: $p1';
  }

  @override
  String get flowDivingFishRoute2 => 'Diving-Fish Route 2';

  @override
  String get flowSyncingScores => 'Syncing scores…';

  @override
  String get flowLXNSRoute2 => 'LXNS Route 2';

  @override
  String get flowPreparingSync2 => 'Preparing sync…';

  @override
  String get flowMultiPlatformRoute2 => 'Multi-platform Route 2';

  @override
  String flowEnterANewQRForP0P1(String p0, String p1) {
    return 'Enter a new QR for $p0 ($p1)…';
  }

  @override
  String flowThisQRIsUsedOnlyForThis(String p0, String p1) {
    return 'This QR is used only for this $p0 ($p1) request. Do not reuse a QR used for another target.';
  }

  @override
  String get flowDirectQRUpload => 'Direct QR upload';

  @override
  String flowSyncingToP0P1(String p0, String p1) {
    return 'Syncing to $p0 ($p1)…';
  }

  @override
  String flowP0UpToDate(String p0) {
    return '$p0 (up to date)';
  }

  @override
  String flowP0QuickSyncUpdatedP1(String p0, String p1) {
    return '$p0 (quick sync, updated $p1)';
  }

  @override
  String flowP0Route1P1(String p0, String p1) {
    return '$p0 (Route 1): $p1';
  }

  @override
  String flowP0Route1P1P2(String p0, String p1, String p2) {
    return '$p0 (Route 1): $p1 $p2%';
  }

  @override
  String flowP0Route1(String p0) {
    return '$p0 (Route 1)';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub =>
      'Not signed in to maimai Score Hub; skipped Diving-Fish Route 2.';

  @override
  String flowDivingFishRoute2P0P1(String p0, String p1) {
    return 'Diving-Fish (Route 2): $p0 $p1%';
  }

  @override
  String flowDivingFishP0(String p0) {
    return 'Diving-Fish: $p0';
  }

  @override
  String flowDivingFishRoute2P0Scores(String p0) {
    return 'Diving-Fish (Route 2, $p0 scores)';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub2 =>
      'Not signed in to maimai Score Hub; skipped LXNS Route 2.';

  @override
  String flowLXNSP0(String p0) {
    return 'LXNS: $p0';
  }

  @override
  String flowLXNSRoute2P0P1(String p0, String p1) {
    return 'LXNS (Route 2): $p0 $p1%';
  }

  @override
  String flowLXNSRoute2P0Scores(String p0) {
    return 'LXNS (Route 2, $p0 scores)';
  }

  @override
  String get flowAWMCNETScoreImportTokenNotSet =>
      'AWMC NET score import Token not set';

  @override
  String get flowCouldNotReadSavedCredentialsTryAgain =>
      'Could not read saved credentials. Try again.';

  @override
  String flowEnterP0(String p0) {
    return 'Enter $p0';
  }

  @override
  String get flowPersonalAPIKey => 'Personal API key';

  @override
  String get flowEnterA512DigitQQID => 'Enter a 5–12 digit QQ ID';

  @override
  String get flowCouldNotSaveQQID => 'Could not save QQ ID';

  @override
  String get flowSelectAtLeastOneSourceWithCredentials =>
      'Select at least one source with credentials ready';

  @override
  String get flowLXNSAuthorizationCodeMissing =>
      'LXNS authorization code missing';

  @override
  String flowNoLookupIDObtainedForP0(String p0) {
    return 'No lookup ID obtained for $p0';
  }

  @override
  String get flowStartingDataRefresh => 'Starting data refresh…';

  @override
  String get flowDataRefreshComplete => 'Data refresh complete';

  @override
  String get flowClearingCaches => 'Clearing caches…';

  @override
  String get flowRefreshingDataInParallel => 'Refreshing data in parallel…';

  @override
  String get flowSongDataRefreshed => 'Song data refreshed';

  @override
  String get flowDifficultyDataRefreshed => 'Difficulty data refreshed';

  @override
  String get flowTagDataRefreshed => 'Tag data refreshed';

  @override
  String get flowUserDataRetrieved => 'User data retrieved';

  @override
  String get flowCollectibleDataRefreshed => 'Collectible data refreshed';

  @override
  String get flowAliasDataRefreshed => 'Alias data refreshed';

  @override
  String get flowUnionDataRefreshed => 'Union data refreshed';

  @override
  String get flowCouldNotFetchDivingFishScores =>
      'Could not fetch Diving-Fish scores';

  @override
  String get flowCalculatingRating => 'Calculating Rating…';

  @override
  String get flowSavingData => 'Saving data…';

  @override
  String flowUploadingSongRankingsP0P1(String p0, String p1) {
    return 'Uploading song rankings $p0/$p1…';
  }

  @override
  String get flowCouldNotRemoveLeaderboardEntries =>
      'Could not remove leaderboard entries';

  @override
  String get flowAWMCNETScoresRetrieved => 'AWMC NET scores retrieved';

  @override
  String get flowObtainingAccessToken => 'Obtaining access Token…';

  @override
  String get flowRenewingAccessToken => 'Renewing access Token…';

  @override
  String get flowAuthorizationFailedCheckYourCode =>
      'Authorization failed. Check your code.';

  @override
  String get flowLXNSAuthorizationExpiredEnterANewAuthorization =>
      'LXNS authorization expired. Enter a new authorization code.';

  @override
  String get flowAuthorizedRefreshingDataInParallel =>
      'Authorized. Refreshing data in parallel…';

  @override
  String get flowPreparingLXNSData => 'Preparing LXNS data';

  @override
  String get flowLXNSProfileRetrieved => 'LXNS profile retrieved';

  @override
  String get flowLXNSScoresRetrieved => 'LXNS scores retrieved';

  @override
  String get flowCouldNotFetchLXNSProfileOrScores =>
      'Could not fetch LXNS profile or scores';

  @override
  String get flowCouldNotConvertLXNSScores => 'Could not convert LXNS scores';

  @override
  String get flowCalculatingBest50 => 'Calculating Best50…';

  @override
  String get flowMissingSongDataCannotCalculateLXNSRating =>
      'Missing song data; cannot calculate LXNS Rating';

  @override
  String get flowInvalidBest50Data => 'Invalid Best50 data';

  @override
  String get flowInvalidBest35Data => 'Invalid Best35 data';

  @override
  String get flowInvalidBest15Data => 'Invalid Best15 data';

  @override
  String flowP0CheckForInvalidData(String p0) {
    return '$p0. Check for invalid data.';
  }

  @override
  String flowCouldNotUpdateLeaderboardDataP0(String p0) {
    return 'Could not update leaderboard data: $p0';
  }

  @override
  String flowLeaderboardUpdateErrorP0(String p0) {
    return 'Leaderboard update error: $p0';
  }

  @override
  String get flowSongsAndCharts => 'Songs and charts';

  @override
  String get flowTagsAndAliases => 'Tags and aliases';

  @override
  String get flowCollectibles => 'Collectibles';

  @override
  String get flowMetadataAndExtras => 'Metadata and extras';

  @override
  String get flowNormal => 'Normal';

  @override
  String get flowQuick => 'Quick';

  @override
  String flowLoadingP0Statistics(String p0) {
    return 'Loading $p0 statistics…';
  }

  @override
  String flowP0StatisticsUnavailable(String p0) {
    return '$p0 statistics unavailable';
  }

  @override
  String flowP0Last100NoRecords(String p0) {
    return '$p0: last 100 / No records';
  }

  @override
  String flowP0Last100P1SamplesAvgP22(
      String p0, String p1, String p2, String p3) {
    return '$p0: last 100 / $p1 samples / avg $p2 / success $p3';
  }

  @override
  String get flowAverageDuration => 'Average duration';

  @override
  String get flowSuccessRate => 'Success rate';

  @override
  String get flowSuccessfulSamples => 'Successful samples';

  @override
  String get flowLatestRun => 'Latest run';

  @override
  String get flowStatusUnconfirmed => 'Status unconfirmed';

  @override
  String get flowExpectedRetry => 'Expected retry';

  @override
  String get flowLastRun => 'Last run';

  @override
  String get flowRefreshPending => 'Refresh pending';

  @override
  String get flowStatusRefreshFailedTapToViewOr =>
      'Status refresh failed. Tap to view or retry; previous results do not confirm the current status.';

  @override
  String get flowSyncStatusNotReadYet => 'Sync status not read yet';

  @override
  String flowP0UserP1OfP2(String p0, String p1, String p2) {
    return '$p0: user $p1 of $p2';
  }

  @override
  String flowPreviousRoundP02(String p0) {
    return 'Previous round: $p0';
  }

  @override
  String flowSuccessP0P1(String p0, String p1) {
    return 'Success · $p0 · $p1';
  }

  @override
  String flowFailedP0P1(String p0, String p1) {
    return 'Failed · $p0 · $p1';
  }

  @override
  String flowP0UserPositionP1(String p0, String p1) {
    return '$p0: user position $p1';
  }

  @override
  String flowSyncFailedP03(String p0) {
    return 'Sync failed · $p0';
  }

  @override
  String get flowSyncSucceeded => 'Sync succeeded';

  @override
  String flowSyncSucceededP0(String p0) {
    return 'Sync succeeded · $p0';
  }

  @override
  String get flowCorrectTheDifficultyCombinationConstantsFirst =>
      'Correct the difficulty combination constants first';

  @override
  String flowSearchFailedP0(String p0) {
    return 'Search failed: $p0';
  }

  @override
  String get flowAny => 'Any';

  @override
  String get flowChooseACharter => 'Choose a charter';

  @override
  String get flowSelectCharter => 'Select charter';

  @override
  String get flowSearchCharters => 'Search charters';

  @override
  String get flowFilterByCharterName => 'Filter by charter name…';

  @override
  String get flowChooseAnArtist => 'Choose an artist';

  @override
  String get flowSelectArtist => 'Select artist';

  @override
  String get flowSearchArtists => 'Search artists';

  @override
  String get flowFilterByArtistName => 'Filter by artist name…';

  @override
  String flowP0Items2(String p0) {
    return '$p0 items';
  }

  @override
  String get flowByDifficulty => 'By difficulty';

  @override
  String get flowConstant => 'Constant';

  @override
  String get flowVersion => 'Version';

  @override
  String get flowGenre => 'Genre';

  @override
  String get flowNotes => 'Notes';

  @override
  String get flowTags => 'Tags';

  @override
  String get flowCharter => 'Charter';

  @override
  String get flowArtist => 'Artist';

  @override
  String get flowSongID => 'Song ID';

  @override
  String get flowSongTitle => 'Song title';

  @override
  String get flowArtist2 => 'Artist';

  @override
  String get flowAlias => 'Alias';

  @override
  String get flowTakeAPhotoOrChooseAnImage => 'Take a photo or choose an image';

  @override
  String get flowCropTheCoverArtInTheImage => 'Crop the cover art in the image';

  @override
  String get flowRecognizeAndViewTheClosestSongs =>
      'Recognize and view the closest songs';

  @override
  String get flowTexture => 'Texture';

  @override
  String get flowColor => 'Color';

  @override
  String get flowEnterANumber => 'Enter a number';

  @override
  String get flowCannotBeNegative => 'Cannot be negative';

  @override
  String flowMustNotExceedP0(String p0) {
    return 'Must not exceed $p0';
  }

  @override
  String flowDifficultyP0(String p0) {
    return 'Difficulty $p0';
  }

  @override
  String get flowLocalLibraryIsEmptyRefreshItFrom =>
      'Local library is empty. Refresh it from Home first.';

  @override
  String get flowNoSongMatchedTapEditThisResult =>
      'No song matched. Tap Edit this result to choose one.';

  @override
  String get flowDifficultyNotRecognizedUTAGESyncIsUnsupported =>
      'Difficulty not recognized (UTAGE sync is unsupported)';

  @override
  String get flowNoChartInformationForThisSongIn =>
      'No chart information for this song in the library';

  @override
  String flowDifficultyP0DoesNotExistOnlyP1(String p0, String p1) {
    return 'Difficulty $p0 does not exist (only $p1 charts)';
  }

  @override
  String get flowAchievementMissingTapEditThisResultTo =>
      'Achievement missing. Tap Edit this result to add it.';

  @override
  String flowUpdatedOnLXNSP0(String p0) {
    return 'Updated on LXNS: $p0';
  }

  @override
  String flowSyncedToLXNSUnchangedP0(String p0) {
    return 'Synced to LXNS (unchanged): $p0';
  }

  @override
  String flowAchievementP0P1(String p0, String p1) {
    return 'Achievement $p0% → $p1%';
  }

  @override
  String flowAchievementP0(String p0) {
    return 'Achievement $p0%';
  }

  @override
  String flowDXScoreP0P1(String p0, String p1) {
    return 'DX score $p0 → $p1';
  }

  @override
  String flowDXScoreP0(String p0) {
    return 'DX score $p0';
  }

  @override
  String flowMaximumP0(String p0) {
    return 'Maximum $p0%';
  }

  @override
  String flowMaximumP02(String p0) {
    return 'Maximum $p0';
  }

  @override
  String get flowPhotographOrChooseAResultScreen =>
      'Photograph or choose a result screen';

  @override
  String get flowPhotographStraightAndClearlyForBetterRecognition =>
      'Photograph straight and clearly for better recognition';

  @override
  String get flowCheckResultsThenSyncToDivingFish =>
      'Check results, then sync to Diving-Fish or LXNS';

  @override
  String get flowStandard => 'Standard';

  @override
  String get flowConfidence => 'Confidence —';

  @override
  String flowConfidenceP0(String p0) {
    return 'Confidence $p0%';
  }

  @override
  String get flowCoverArt => 'Cover art';

  @override
  String get flowTitle => 'Title';

  @override
  String get flowSignInFailedTheQRMayHave =>
      'Sign-in failed. The QR may have expired; generate a new one.';

  @override
  String get flowAllSongs => 'All songs';

  @override
  String get flowInChina => 'In China';

  @override
  String get flowPendingRelease => 'Pending release';

  @override
  String get flowNotIncluded => 'Not included';

  @override
  String get flowNextUpdateCandidates => 'Next update candidates';

  @override
  String get flowOlderSongsMissingInChina => 'Older songs missing in China';

  @override
  String get flowUTAGE => 'UTAGE';

  @override
  String get flowChinaRegularSongs => 'China regular songs';

  @override
  String get flowEarlyChinaReleases => 'Early China releases';

  @override
  String get flowNoMissingRegularSongsInTheCurrent =>
      'No missing regular songs in the current reference range.';

  @override
  String flowSortedByIDNotReleaseOrderOfficial(String p0) {
    return 'Sorted by ID, not release order. Official announcements decide actual updates.$p0';
  }

  @override
  String get flowTheseSongsPredateTheReferenceStartOr =>
      'These songs predate the reference start or lack a date and have a smaller ID. They may be regional, collaboration-exclusive or older pending songs; this does not mean they will never be released.';

  @override
  String get flowUTAGEDoesNotFollowVersionUpdatesListed =>
      'UTAGE does not follow version updates; listed for reference only.';

  @override
  String get flowRegularDivingFishChinaSongsNewestDebut =>
      'Regular Diving-Fish China songs, newest debut first. The first song is this page’s update frontier.';

  @override
  String get flowTheseSongsReachedChinaBeforeJapanTheir =>
      'These songs reached China before Japan. Their new IDs would raise the frontier and hide pending songs, so they are listed separately.';

  @override
  String flowVersionsInvolvedP0(String p0) {
    return '\nVersions involved: $p0';
  }

  @override
  String flowP0P1Songs(String p0, String p1) {
    return '$p0: $p1 songs';
  }

  @override
  String get flowChartDateSource => 'Chart date source: ';

  @override
  String get flowReleaseDataSource => 'Release data source: ';

  @override
  String get flowUpdatesOnThisDay => 'Updates on this day';

  @override
  String flowP0P1P2(String p0, String p1, String p2) {
    return '$p0/$p1 $p2';
  }

  @override
  String get flowAll => 'All';

  @override
  String get flowPlayed => 'Played';

  @override
  String get flowUnplayed => 'Unplayed';

  @override
  String flowP0Types(String p0) {
    return '$p0 types';
  }

  @override
  String get flowThisCollectibleHasNoImage => 'This collectible has no image';

  @override
  String flowCouldNotSaveImageP0(String p0) {
    return 'Could not save image: $p0';
  }

  @override
  String get flowThisCollectibleHasNoImageLink =>
      'This collectible has no image link';

  @override
  String get flowLinkCopied => 'Link copied';

  @override
  String get flowCouldNotCopyLink => 'Could not copy link';

  @override
  String get flowRequiredDifficulty => 'Required difficulty';

  @override
  String get flowMinimumAchievement => 'Minimum achievement';

  @override
  String get flowRequiredNoteSpeed => 'Required note speed';

  @override
  String get flowRequiredCombo => 'Required combo';

  @override
  String get flowRequiredSync => 'Required sync';

  @override
  String get flowJapaneseEnglish => 'Japanese + English';

  @override
  String get flowEnglish => 'English';

  @override
  String get flowJapanese => 'Japanese';

  @override
  String flowP0Seconds2(String p0) {
    return '$p0 seconds';
  }

  @override
  String flowP0Minutes(String p0) {
    return '$p0 minutes';
  }

  @override
  String flowP0MinP1Sec(String p0, String p1) {
    return '$p0 min $p1 sec';
  }

  @override
  String get flowJustNow => 'Just now';

  @override
  String get flowWaitingForUpstreamQuota => 'Waiting for upstream quota';

  @override
  String get flowWaitingForUpstreamService => 'Waiting for upstream service';

  @override
  String get flowWaitingForUpstreamGateway => 'Waiting for upstream gateway';

  @override
  String get flowWaitingForUpstreamProcessing =>
      'Waiting for upstream processing';

  @override
  String flowP0RetryAroundP1(String p0, String p1) {
    return '$p0, retry around $p1';
  }

  @override
  String get flowProcessingTimedOut => 'Processing timed out';

  @override
  String get flowQuotaInsufficient => 'Quota insufficient';

  @override
  String get flowUpstreamUnavailable => 'Upstream unavailable';

  @override
  String get flowUploadIncomplete => 'Upload incomplete';

  @override
  String get flowUploadCredentialsExpired => 'Upload credentials expired';

  @override
  String get flowCouldNotReadTargetScores => 'Could not read target scores';

  @override
  String get flowCouldNotReadLibrary => 'Could not read library';

  @override
  String get flowCouldNotReadCabinetData => 'Could not read cabinet data';

  @override
  String get flowNoScoresToSync => 'No scores to sync';

  @override
  String get flowInterruptedByServiceRestart =>
      'Interrupted by service restart';

  @override
  String get flowProcessingWindowEnded => 'Processing window ended';

  @override
  String get flowRoundDataExpired => 'Round data expired';

  @override
  String get flowTaskCancelled => 'Task cancelled';

  @override
  String get flowPreparingQuickSync => 'Preparing quick sync…';

  @override
  String flowElapsedP0P1(String p0, String p1) {
    return 'Elapsed $p0$p1';
  }

  @override
  String flowLimitP0Min(String p0) {
    return ' / limit $p0 min';
  }

  @override
  String get flowWaitingForProcessingToStart =>
      'Waiting for processing to start';

  @override
  String flowCabinetDataCollectedP02(String p0) {
    return 'Cabinet data collected $p0';
  }

  @override
  String flowUploadingP0P1P2(String p0, String p1, String p2) {
    return 'Uploading $p0/$p1$p2';
  }

  @override
  String flowReadingCabinetScoresPageP0(String p0) {
    return 'Reading cabinet scores · Page $p0';
  }

  @override
  String flowSubmittedP02(String p0) {
    return 'Submitted $p0';
  }

  @override
  String flowSkippedP0UnsupportedCharts2(String p0) {
    return 'Skipped $p0 unsupported charts';
  }

  @override
  String flowUnchangedP0(String p0) {
    return 'Unchanged $p0';
  }

  @override
  String flowP0TookP1(String p0, String p1) {
    return '$p0 · Took $p1';
  }

  @override
  String get flowAccountAndSync => 'Accounts and sync';

  @override
  String get flowAccountAndSyncHint =>
      'Manage accounts, authorization and score sync';

  @override
  String get flowFishAccount => 'Diving-Fish account';

  @override
  String get flowReadingAccountState => 'Reading account status';

  @override
  String get flowNotSignedIn => 'Not signed in';

  @override
  String get flowSignInFishAgain => 'Sign in to Diving-Fish again';

  @override
  String get flowUseFishForToken =>
      'Use Diving-Fish credentials to get ImportToken';

  @override
  String get flowScoreSync => 'Score sync';

  @override
  String get flowSyncSourcesHint =>
      'Sync maimai scores to third-party services';

  @override
  String get flowImportTokenNotSet => 'Score import Token not set';

  @override
  String get flowTitleCollectible => 'Titles';

  @override
  String get flowIconCollectible => 'Icons';

  @override
  String get flowPlateCollectible => 'Nameplates';

  @override
  String get flowFrameCollectible => 'Frames';

  @override
  String get flowAwmcGateway => 'AWMC gateway';

  @override
  String get flowNormalSource => 'China library';

  @override
  String get flowExtraSource => 'International library';

  @override
  String get flowQrPrivateNotice =>
      'Use the same SGWCMAID QR string as score sync; copy it from WeChat or camera recognition.\n\n⚠️ This QR grants cabinet sign-in access. Use only your own account.';

  @override
  String get flowReadingExistingScoresOnTheTargetAccount =>
      'Reading existing scores on the target account…';

  @override
  String get flowCheckingChartsSupportedByTheTarget =>
      'Checking charts supported by the target…';

  @override
  String flowReadingCabinetScoresP0PagesRead(String p0) {
    return 'Reading cabinet scores; $p0 pages read';
  }

  @override
  String get flowReadingCabinetScores => 'Reading cabinet scores…';

  @override
  String get flowPreparingChartsComboAndSyncMarkers =>
      'Preparing charts, combo and sync markers…';

  @override
  String flowUploadingScoresP0P1P2(String p0, String p1, String p2) {
    return 'Uploading scores ($p0 / $p1$p2)';
  }

  @override
  String flowP0Submitted(String p0) {
    return ', $p0 submitted';
  }

  @override
  String get flowSyncComplete2 => 'Sync complete';

  @override
  String get flowWaitingForUpstreamQuota2 => 'Waiting for upstream quota…';

  @override
  String get flowWaitingForUpstreamService2 => 'Waiting for upstream service…';

  @override
  String flowReadingExistingScoresOnP0(String p0) {
    return 'Reading existing scores on $p0…';
  }

  @override
  String flowCheckingChartsSupportedByP0(String p0) {
    return 'Checking charts supported by $p0…';
  }

  @override
  String get flowComparingChangesAndPreparingUploads =>
      'Comparing changes and preparing uploads…';

  @override
  String flowUploadingToP0P1P2P3(String p0, String p1, String p2, String p3) {
    return 'Uploading to $p0: $p1 / $p2$p3';
  }

  @override
  String get flowValidatingQRCode2 => 'Validating QR code…';

  @override
  String get flowCreatingScoreFetchTask => 'Creating score fetch task…';

  @override
  String get flowBotIsSendingAFriendRequest =>
      'Bot is sending a friend request…';

  @override
  String get flowFriendAddedCreatingScoreFetchTask =>
      'Friend added. Creating score fetch task…';

  @override
  String get flowSyncingToDivingFish => 'Syncing to Diving-Fish…';

  @override
  String flowSyncCompleteP0ScoresSynced(String p0) {
    return 'Sync complete. $p0 scores synced.';
  }

  @override
  String get flowSubmittingQRCode => 'Submitting QR code…';

  @override
  String get flowSyncingToLXNS => 'Syncing to LXNS…';

  @override
  String flowSyncCompleteP0ScoresSyncedToLXNS(String p0) {
    return 'Sync complete. $p0 scores synced to LXNS.';
  }

  @override
  String get flowAcceptTheFriendRequestOnNETOr =>
      'Accept the friend request on NET or the cabinet';

  @override
  String flowFetchingScoresP0P1(String p0, String p1) {
    return 'Fetching scores… ($p0/$p1)';
  }

  @override
  String get flowFetchingScores => 'Fetching scores…';

  @override
  String get flowFetchingFriendList => 'Fetching friend list…';

  @override
  String get flowTaskQueuedWaitingForProcessing =>
      'Task queued. Waiting for processing…';

  @override
  String get flowPreviewingData => 'Previewing data…';

  @override
  String get flowSigningIn3 => 'Signing in…';

  @override
  String flowReadingChartScoresP0Records(String p0) {
    return 'Reading chart scores… ($p0 records)';
  }

  @override
  String get flowReadingChartScores => 'Reading chart scores…';

  @override
  String get flowSigningOut => 'Signing out…';

  @override
  String get flowCleaningUp => 'Cleaning up…';

  @override
  String flowSavingScoresP0Records(String p0) {
    return 'Saving scores… ($p0 records)';
  }

  @override
  String get flowSavingScores => 'Saving scores…';

  @override
  String flowReadingComboAndSyncMarkersFromP0(String p0) {
    return 'Reading combo and sync markers from $p0…';
  }

  @override
  String flowCheckingChartsSupportedByP02(String p0) {
    return 'Checking charts supported by $p0…';
  }

  @override
  String get flowReadingCabinetScoresForThisRound =>
      'Reading cabinet scores for this round…';

  @override
  String flowUpdatingP0ScoresP1P2(String p0, String p1, String p2) {
    return 'Updating $p0 scores ($p1/$p2)…';
  }

  @override
  String flowQuickSyncCompleteUpdatedP0Scores(String p0) {
    return 'Quick sync complete: updated $p0 scores';
  }

  @override
  String flowSkippedP0UnchangedScores(String p0) {
    return ', skipped $p0 unchanged scores';
  }

  @override
  String flowP0ChartsUnmatchedOrUnsupported(String p0) {
    return ', $p0 charts unmatched or unsupported';
  }

  @override
  String get flowCheckingAWMCGateway2 => 'Checking AWMC gateway…';

  @override
  String get flowQuicklyReadingCabinetScores =>
      'Quickly reading cabinet scores…';

  @override
  String get flowClearSignIn => 'Clear current sign-in';

  @override
  String flowBoundQq(String qq) {
    return 'Linked QQ: $qq';
  }

  @override
  String get flowStatsNotUpdated => 'Not updated yet';

  @override
  String get flowStatsJustUpdated => 'Just updated';

  @override
  String flowStatsSecondsAgo(String count) {
    return 'Updated $count sec ago';
  }

  @override
  String flowStatsMinutesAgo(String count) {
    return 'Updated $count min ago';
  }

  @override
  String flowStatsHoursAgo(String count) {
    return 'Updated $count hr ago';
  }

  @override
  String get flowCacheNeverExpires => 'Never expires';

  @override
  String get flowCacheNoTimestamp => 'No cache timestamp';

  @override
  String get flowCacheAbsent => 'No cache';

  @override
  String get flowCacheExpiredPrefix => 'Expired';

  @override
  String flowCacheExpired(String duration) {
    return 'Expired $duration ago';
  }

  @override
  String flowCacheRemaining(String duration) {
    return '$duration remaining';
  }

  @override
  String flowCacheDaysHours(String days, String hours) {
    return '${days}d ${hours}h';
  }

  @override
  String flowCacheDays(String days) {
    return '${days}d';
  }

  @override
  String flowCacheHoursMinutes(String hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String flowCacheHours(String hours) {
    return '${hours}h';
  }

  @override
  String flowCacheMinutes(String minutes) {
    return '${minutes}m';
  }

  @override
  String get flowRankingShowIdentity => 'Show nickname and avatar';

  @override
  String get flowRankingIdentityHint =>
      'When off, show an anonymous name and default avatar. Your chosen avatar is still saved and synced.';

  @override
  String get flowRankingShowBrief => 'Show brief leaderboard profile';

  @override
  String get flowRankingBriefHint =>
      'Share titles, appearance, level and best scores. Requires sign-in or identity verification. Off by default.';

  @override
  String get flowCacheFishSongs => 'Songs (Diving-Fish)';

  @override
  String get flowCacheUnionSongs => 'Songs (Union)';

  @override
  String get flowCacheDifficulties => 'Chart constants';

  @override
  String get flowCacheTags => 'Tags';

  @override
  String get flowCacheAlias1 => 'Aliases: source 1';

  @override
  String get flowCacheAlias2 => 'Aliases: source 2';

  @override
  String get flowCacheAlias3 => 'Aliases: source 3';

  @override
  String get flowCacheTitles => 'Collectibles: titles';

  @override
  String get flowCacheIcons => 'Collectibles: icons';

  @override
  String get flowCachePlates => 'Collectibles: nameplates';

  @override
  String get flowCacheFrames => 'Collectibles: frames';

  @override
  String get flowCacheUnionMetadata => 'Union metadata';

  @override
  String get flowCacheFishDescription => 'Full song library (Diving-Fish)';

  @override
  String get flowCacheUnionDescription => 'Additional unique songs (godserver)';

  @override
  String get flowCacheConstantDescription =>
      'Chart constants (Diving-Fish chart_stats)';

  @override
  String get flowCacheTagDescription => 'DXRating chart tags';

  @override
  String get flowCacheTitleDescription => 'LXNS titles';

  @override
  String get flowCacheIconDescription => 'LXNS icons';

  @override
  String get flowCachePlateDescription => 'LXNS nameplates';

  @override
  String get flowCacheFrameDescription => 'LXNS frames';

  @override
  String get flowCacheMetadataDescription =>
      'Playable regions (cn/jp) and more';

  @override
  String get flowCacheMaidataDescription =>
      'Chart additions (list + full maidata)';

  @override
  String get flowSongDetails => 'Song details';

  @override
  String get flowExpandOrCollapseSongInformation =>
      'Expand or collapse song information';

  @override
  String get flowFavorited => 'Favorited';

  @override
  String get flowAddToAFavoritesFolder => 'Add to a favorites folder';

  @override
  String flowCreatedP0AndAddedThisChart(String p0) {
    return 'Created “$p0” and added this chart';
  }

  @override
  String get flowNoFavoritesFoldersYet => 'No favorites folders yet';

  @override
  String get flowCreateAFavoritesFolderFirst =>
      'Create a favorites folder first';

  @override
  String flowP0Charts(String p0) {
    return '$p0 charts';
  }

  @override
  String get flowNewFavoritesFolder => 'New favorites folder';

  @override
  String get flowEnterAFolderName => 'Enter a folder name';

  @override
  String get flowCreate => 'Create';

  @override
  String get flowPause => 'Pause';

  @override
  String get flowPlay => 'Play';

  @override
  String flowP0P1SBufferedAhead(String p0, String p1) {
    return '$p0: ${p1}s buffered ahead';
  }

  @override
  String get flowCouldNotLoadThePVCheckYour =>
      'Could not load the PV. Check your connection and retry.';

  @override
  String get flowBackToSongDetails => 'Back to song details';

  @override
  String get flowCopiedToClipboard => 'Copied to clipboard';

  @override
  String get flowExportZIPZip => 'Export ZIP (.zip)';

  @override
  String get flowMaidataTxtCoverArtAndAudioIn =>
      'maidata.txt, cover art and audio in a standard chart package';

  @override
  String get flowExportAstroDXChartAdx => 'Export AstroDX chart (.adx)';

  @override
  String get flowOpenInAstroDXToInstallTheChart =>
      'Open in AstroDX to install the chart';

  @override
  String get flowChooseWhereToSaveTheChartPackage =>
      'Choose where to save the chart package';

  @override
  String get flowChooseWhereToSaveTheAstroDXChart =>
      'Choose where to save the AstroDX chart';

  @override
  String flowExportFailedP0(String p0) {
    return 'Export failed: $p0';
  }

  @override
  String get flowSelectDifficulty => 'Select difficulty';

  @override
  String get flowRenderedChartsAreForReferenceAndMay =>
      'Rendered charts are for reference and may differ from official charts. Avoid seeking repeatedly in dense charts, as this may freeze or crash the app.';

  @override
  String get flowLoadAudio => 'Load audio';

  @override
  String get flowTurnOffToLoadTheChartWithout =>
      'Turn off to load the chart without downloading audio';

  @override
  String get flowFetchingChartConstants => 'Fetching chart constants…';

  @override
  String flowSongIDP0(String p0) {
    return 'Song ID $p0';
  }

  @override
  String get flowChartCode => 'Chart code';

  @override
  String get flowCopy => 'Copy';

  @override
  String get flowExporting => 'Exporting';

  @override
  String get flowExport => 'Export';

  @override
  String get flowRender => 'Render';

  @override
  String flowVideoGeneratedTapSaveToPhotosOn(String p0, String p1, String p2) {
    return 'Video generated. Tap “Save to photos” on the export page: $p0×$p1 · $p2 MB';
  }

  @override
  String flowLoadedMaidataWithP0Difficulties(String p0) {
    return 'Loaded maidata with $p0 difficulties';
  }

  @override
  String get flowUnsupportedEncodingUseUTF8OrShift =>
      'Unsupported encoding. Use UTF-8 or Shift-JIS.';

  @override
  String flowCouldNotOpenTheFilePickerP0(String p0) {
    return 'Could not open the file picker: $p0';
  }

  @override
  String get flowCoverArtSelected => 'Cover art selected';

  @override
  String get flowCoverArtSelectedUsingItsOriginalPath =>
      'Cover art selected using its original path';

  @override
  String flowCouldNotOpenTheImagePickerP0(String p0) {
    return 'Could not open the image picker: $p0';
  }

  @override
  String get flowAudioSelected => 'Audio selected';

  @override
  String get flowAudioSelectedUsingItsOriginalPath =>
      'Audio selected using its original path';

  @override
  String flowCouldNotOpenTheAudioPickerP0(String p0) {
    return 'Could not open the audio picker: $p0';
  }

  @override
  String flowTheFileForP0IsMissingAnd(String p0) {
    return 'The file for “$p0” is missing and was removed from the list';
  }

  @override
  String flowCouldNotParseAgainP0(String p0) {
    return 'Could not parse again: $p0';
  }

  @override
  String get flowDeleteThisRecord => 'Delete this record';

  @override
  String flowRemoveP0FromRecentlyParsedChartsAnd(String p0) {
    return 'Remove “$p0” from recently parsed charts and delete its archived files?';
  }

  @override
  String get flowDelete => 'Delete';

  @override
  String get flowCouldNotReadThisFileTryAnother =>
      'Could not read this file. Try another source.';

  @override
  String flowImportFailedP0(String p0) {
    return 'Import failed: $p0';
  }

  @override
  String get flowNoMaidataTxtFoundThisIsNot =>
      'No maidata.txt found. This is not a valid chart package.';

  @override
  String get flowUnsupportedMaidataTxtEncodingUseAUTF =>
      'Unsupported maidata.txt encoding. Use a UTF-8 or Shift-JIS chart package.';

  @override
  String flowImportedAllThreeFilesFromP0Found(String p0, String p1) {
    return 'Imported all three files from $p0; found $p1 difficulties';
  }

  @override
  String flowImportedMaidataP0DifficultiesNoP1In(String p0, String p1) {
    return 'Imported maidata ($p0 difficulties). No $p1 in the package; select it manually if needed.';
  }

  @override
  String get flowRecentlyParsed => 'Recently parsed';

  @override
  String get flowTapToParseTheArchivedFilesAgain =>
      'Tap to parse the archived files again; hold to delete';

  @override
  String get flowSelectAMaidataFileFirst => 'Select a maidata file first';

  @override
  String get flowNoValidDifficultiesFound => 'No valid difficulties found';

  @override
  String get flowTurnOffToLoadTheChartWithout2 =>
      'Turn off to load the chart without audio';

  @override
  String get flowSelectionCleared => 'Selection cleared';

  @override
  String get flowCustomChart => 'Custom chart';

  @override
  String get flowImportAChartPackage => 'Import a chart package';

  @override
  String get flowSelectAnAdxOrZipPackageTo =>
      'Select an .adx or .zip package to extract maidata.txt, cover art and audio';

  @override
  String get flowExtracting => 'Extracting…';

  @override
  String get flowSelectChartPackage => 'Select chart package';

  @override
  String get flowOrSelectTheThreeFilesSeparately =>
      'Or select the three files separately';

  @override
  String get flowSelectMaidataTxt => 'Select maidata.txt';

  @override
  String get flowRequiredATextFileContainingChartData =>
      'Required: a text file containing chart data';

  @override
  String get flowSelectCoverArt => 'Select cover art';

  @override
  String get flowOptionalChartBackgroundImagePNGJPG =>
      'Optional: chart background image (PNG/JPG)';

  @override
  String get flowSelectAudio => 'Select audio';

  @override
  String get flowOptionalChartMusicMP3WAVOGG =>
      'Optional: chart music (MP3/WAV/OGG)';

  @override
  String get flowParsedDifficulties => 'Parsed difficulties:';

  @override
  String get flowStartPlayback => 'Start playback';

  @override
  String get flowInstructions => 'Instructions:';

  @override
  String get flowOption1SelectAnAdxOrZip =>
      'Option 1: select an .adx or .zip chart package to fill all three files at once';

  @override
  String get flowOption2TapARecentlyParsedEntry =>
      'Option 2: tap a recently parsed entry to parse a previous package again';

  @override
  String get flowOption3SelectMaidataTxtCoverArt =>
      'Option 3: select maidata.txt, cover art and audio separately';

  @override
  String get flow1MaidataTxtIsRequiredTheOther =>
      '1. maidata.txt is required; the other files are optional';

  @override
  String get flow2DifficultiesAreDetectedAutomatically =>
      '2. Difficulties are detected automatically';

  @override
  String get flow3SelectADifficultyThenStartPlayback =>
      '3. Select a difficulty, then start playback';

  @override
  String flowSelectedP0(String p0) {
    return 'Selected: $p0';
  }

  @override
  String get flowChooseAgain2 => 'Choose again';

  @override
  String get flowChooseFile => 'Choose file';

  @override
  String get flowChooseWhereToSaveTheSong => 'Choose where to save the song';

  @override
  String get flowDownloaded => 'Downloaded';

  @override
  String get flowGoToCurrentSong => 'Go to current song';

  @override
  String get flowRebuildLibrary => 'Rebuild library';

  @override
  String get flowMusicPlayerSettings => 'Music player settings';

  @override
  String get flowShowFloatingPlayerAfterLeavingThisPage =>
      'Show floating player after leaving this page';

  @override
  String get flowWhenOffLeavingTheMusicPlayerWill =>
      'When off, leaving the music player will not show the floating player';

  @override
  String get flowSearchTitleArtistGenreAliasBPMID =>
      'Search title / artist / genre / alias / BPM / ID';

  @override
  String get flowNowPlaying => 'Now playing';

  @override
  String get flowPaused => 'Paused';

  @override
  String get flowUnknownArtist => 'Unknown artist';

  @override
  String get flowDownloadSong => 'Download song';

  @override
  String get flowAddToPlayNext => 'Add to play next';

  @override
  String get flowAddedToPlayNext => 'Added to play next';

  @override
  String get flowPlayMusic => 'Play music';

  @override
  String get flowNothingPlayingYet => 'Nothing playing yet';

  @override
  String get flowPreparingAudio => 'Preparing audio…';

  @override
  String get flowPrevious2 => 'Previous';

  @override
  String get flowNext2 => 'Next';

  @override
  String get flowChooseSortOrder => 'Choose sort order';

  @override
  String get flowDXScoreRate => 'DX score rate';

  @override
  String get flowAchievementFilter => 'Achievement filter';

  @override
  String get flowComboSyncFilter => 'Combo / sync filter';

  @override
  String get flowAnyOptionWithinAGroupMatchesWhen =>
      'Any option within a group matches. When both combo and sync are selected, both must match.';

  @override
  String get flowCloseSearch => 'Close search';

  @override
  String get flowSearchSongTitleOrConstant => 'Search song title or constant';

  @override
  String get flowNoCachedDataFound => 'No cached data found';

  @override
  String get flowTapASegmentOrStatisticToFilter =>
      'Tap a segment or statistic to filter · Total ';

  @override
  String get flowEntries => ' entries';

  @override
  String flowFilteredByP0TapAgainToClear(String p0) {
    return 'Filtered by $p0 · Tap again to clear';
  }

  @override
  String flowP0P1EntriesTapToFilter(String p0, String p1) {
    return '$p0: $p1 entries. Tap to filter.';
  }

  @override
  String get flowComboSync => 'Combo / sync';

  @override
  String get flowPerPage => 'Per page';

  @override
  String flowP0Entries(String p0) {
    return '$p0 entries';
  }

  @override
  String get flowList => 'List';

  @override
  String get flowUnknownSong => 'Unknown song';

  @override
  String get flowSelectMultipleAnySelectedOptionMatches =>
      'Select multiple; any selected option matches';

  @override
  String flowClearP0(String p0) {
    return 'Clear $p0';
  }

  @override
  String get flowQuickOptions => 'Quick options';

  @override
  String get flowCustomRange => 'Custom range';

  @override
  String get flowExportAsImage => 'Export as image';

  @override
  String get flowSelectCategory => 'Select category';

  @override
  String get flowLevel => 'Level';

  @override
  String get flowNoChartDesignerDataFound => 'No chart designer data found';

  @override
  String get flowSelectVersion => 'Select version';

  @override
  String get flowNoComposerDataFound => 'No composer data found';

  @override
  String get flowNoGenreDataFound => 'No genre data found';

  @override
  String get flowSelectGenre => 'Select genre';

  @override
  String flowP0P1Songs2(String p0, String p1) {
    return '$p0 ($p1 songs)';
  }

  @override
  String get flowSelectLevel => 'Select level';

  @override
  String get flowNoCompletedSongsYet => 'No completed songs yet';

  @override
  String get flowNoIncompleteSongs => 'No incomplete songs';

  @override
  String get flowStoragePermissionIsRequiredToExportImages =>
      'Storage permission is required to export images to photos. Enable it in settings.';

  @override
  String get flowPersonalizedScores => 'Personalized scores';

  @override
  String flowExportFailedP02(String p0) {
    return 'Export failed: $p0';
  }

  @override
  String get flowCouldNotOpenTheAuthorizationPageLink =>
      'Could not open the authorization page. Link copied to clipboard.';

  @override
  String get flowFetchingFriendDataAndComparing =>
      'Fetching friend data and comparing…';

  @override
  String flowCompareMyP0ScoresWithMyFriend(String p0) {
    return 'Compare my $p0 scores with my friend’s scores here';
  }

  @override
  String flowEnterYourFriendSP0(String p0) {
    return 'Enter your friend’s $p0';
  }

  @override
  String get flowCompare => 'Compare';

  @override
  String get flowCompareWithAFriend => 'Compare with a friend';

  @override
  String flowEnterYourFriendSP0ToCompare(String p0, String p1) {
    return 'Enter your friend’s $p0 to compare\nYour friend needs data on $p1';
  }

  @override
  String get flowClearHistory => 'Clear history';

  @override
  String get flowClearAllHistory => 'Clear all history?';

  @override
  String get flowPastComparisons => 'Past comparisons';

  @override
  String flowP0P1P2SongsInCommon(String p0, String p1, String p2) {
    return '$p0 · $p1 · $p2 songs in common';
  }

  @override
  String get flowPrivate => 'Private';

  @override
  String get flowSameScore => 'Same score';

  @override
  String get flowMyCharts => 'My charts';

  @override
  String get flowFriendSCharts => 'Friend’s charts';

  @override
  String get flowSharedCharts => 'Shared charts';

  @override
  String get flowAllDifficulties => 'All difficulties';

  @override
  String flowConstantHighToLowShowingP0P1(String p0, String p1) {
    return 'Constant: high to low · Showing $p0 / $p1';
  }

  @override
  String get flowNoMatchingCharts => 'No matching charts';

  @override
  String flowLoadMoreP0P1(String p0, String p1) {
    return 'Load more ($p0 / $p1)';
  }

  @override
  String get flowTie => 'Tie';

  @override
  String get flowSelectFirstCharacter => 'Select first character';

  @override
  String flowP0SongsExcludedFromPlateProgress(String p0) {
    return '$p0 songs, excluded from plate progress';
  }

  @override
  String flowP0P1P2Statistics(String p0, String p1, String p2) {
    return '$p0$p1 ($p2) statistics';
  }

  @override
  String get flowRecommendationSettings => 'Recommendation settings';

  @override
  String flowConstantsP0P1P2Results(String p0, String p1, String p2) {
    return 'Constants $p0–$p1 · $p2 results';
  }

  @override
  String get flowTargetRating => 'Target Rating';

  @override
  String get flowRecommend => 'Recommend';

  @override
  String get flowLoadingRecommendations => 'Loading recommendations…';

  @override
  String get flowNoRecommendationsCheckTheRatingYouEntered =>
      'No recommendations. Check the Rating you entered.';

  @override
  String flowCouldNotSaveHistoryP0(String p0) {
    return 'Could not save history: $p0';
  }

  @override
  String flowCouldNotDeleteDataPointP0(String p0) {
    return 'Could not delete data point: $p0';
  }

  @override
  String get flowLinkYourQQThroughSyncScoresTo =>
      'Link your QQ through “Sync scores to AWMC NET” first';

  @override
  String flowNoRatingRecordsForQQP0On(String p0) {
    return 'No Rating records for QQ $p0 on AWMC NET in the last 90 days';
  }

  @override
  String flowSyncedRatingHistoryFromAWMCNETAdded(String p0) {
    return 'Synced Rating history from AWMC NET; added $p0 points';
  }

  @override
  String flowNoNewAWMCNETPointsP0Already(String p0) {
    return 'No new AWMC NET points ($p0 already recorded)';
  }

  @override
  String get flowSyncRatingHistoryFromAWMCNET =>
      'Sync Rating history from AWMC NET';

  @override
  String get flowAddHistoryRecord => 'Add history record';

  @override
  String flowCurrentSourceP0(String p0) {
    return 'Current source: $p0';
  }

  @override
  String flowBaselinesForP0ChartsP1ScoreChanges(String p0, String p1) {
    return 'Baselines for $p0 charts · $p1 score changes (individual achievement / DX score charts in song details use these changes)';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs(String p0) {
    return 'Diving-Fish / LXNS / AWMC NET history is recorded per account. $p0 (On AWMC NET, use the cloud sync button above to backfill trends.)';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs2(String p0) {
    return 'Diving-Fish / LXNS / AWMC NET history is recorded per account. $p0 (Records start now; Diving-Fish and LXNS have no historical score API.)';
  }

  @override
  String get flowHighest => 'Highest';

  @override
  String get flowDataPoints => 'Data points';

  @override
  String flowP0EntriesShowingTheLatest30(String p0) {
    return '$p0 entries; showing the latest 30';
  }

  @override
  String get flowNoHistoryYet => 'No history yet';

  @override
  String get flowEachDataRefreshRecordsAPointAutomatically =>
      'Each Pull scores & update data run records a point automatically.\nTimestamps include seconds. Refreshing within the same second updates that point; changes at different times are kept separately.';

  @override
  String get flowAddRatingHistory => 'Add Rating history';

  @override
  String get flowCurrentTheoreticalRating => 'Current theoretical Rating';

  @override
  String get flowBest35Optional => 'Best35 (optional)';

  @override
  String get flowCurrentTheoreticalB35 => 'Current theoretical B35';

  @override
  String get flowBest15Optional => 'Best15 (optional)';

  @override
  String get flowCurrentTheoreticalB15 => 'Current theoretical B15';

  @override
  String get flowAboutScoreImprovementHistory =>
      'About score improvement history';

  @override
  String get flowLocalScoreHistoryForThisAccount =>
      'Local score history for this account';

  @override
  String get flowRecordingStartsAfterADataRefreshThe =>
      'Recording starts after a data refresh. The first refresh creates a baseline when no previous scores exist.';

  @override
  String flowRecordedSinceP0SameDayChangesTo(String p0) {
    return 'Recorded since $p0 · Same-day changes to one chart are merged';
  }

  @override
  String get flowCharts => 'Charts';

  @override
  String get flowImprovement => 'Improvement';

  @override
  String get flowChanges => 'Changes';

  @override
  String get flowRecordingRules => 'Recording rules';

  @override
  String flowLoadMoreFromThisDayP0Charts(String p0) {
    return 'Load more from this day ($p0 charts left)';
  }

  @override
  String get flowNoRatingsYet => 'No ratings yet';

  @override
  String get flowNoCommentsYet => 'No comments yet';

  @override
  String get flowNoBest50DataYet => 'No Best50 data yet';

  @override
  String get flowReturnHomeAndTapRefreshData =>
      'Return home and tap “Pull scores & update data”';

  @override
  String get flowTheoreticalRatingBest50 => 'Theoretical Rating Best50';

  @override
  String get flowSaveCurrentRecord => 'Save current record';

  @override
  String get flowHistory => 'History';

  @override
  String get flowAccountDataChangedReopenBest50BeforeSaving =>
      'Account data changed. Reopen Best50 before saving.';

  @override
  String flowBest50RecordSavedP0(String p0) {
    return 'Best50 record saved ($p0)';
  }

  @override
  String get flowBest50History => 'Best50 history';

  @override
  String get flowNoSavedRecordsTapSaveCurrentRecord =>
      'No saved records. Tap “Save current record” to save one.';

  @override
  String flowTheoreticalRatingAverageP0(String p0) {
    return 'Theoretical Rating (average $p0)';
  }

  @override
  String flowCurrentRatingAverageP0(String p0) {
    return 'Current Rating (average $p0)';
  }

  @override
  String get flowTheoretical => 'Theoretical';

  @override
  String get flowAverageAchievementDXScoreRate =>
      'Average achievement / DX score rate';

  @override
  String get flowTagStatistics => 'Tag statistics';

  @override
  String get flowTheoreticalBest50 => 'Theoretical Best50';

  @override
  String get flowCalculatingFittedBest50 => 'Calculating fitted Best50…';

  @override
  String get flowNoFittedBest50DataYet => 'No fitted Best50 data yet';

  @override
  String flowFittedTotalRatingDifferenceFromBest50Average(String p0) {
    return 'Fitted total Rating · Difference from Best50 (average $p0)';
  }

  @override
  String flowModeP0(String p0) {
    return 'Mode $p0';
  }

  @override
  String get flowNoDataToExport => 'No data to export';

  @override
  String flowCategoryChartDesigner50P0(String p0) {
    return 'Category: chart designer 50 – $p0';
  }

  @override
  String flowCategoryVersion50P0(String p0) {
    return 'Category: version 50 – $p0';
  }

  @override
  String flowCategoryGenre50P0(String p0) {
    return 'Category: genre 50 – $p0';
  }

  @override
  String flowCategoryStar50P0(String p0) {
    return 'Category: star 50 – $p0';
  }

  @override
  String flowCategoryTag50P0(String p0) {
    return 'Category: tag 50 – $p0';
  }

  @override
  String get flowCategoryRandom50 => 'Category: random 50';

  @override
  String get flowCategoryOverreach50 => 'Category: overreach 50';

  @override
  String flowCategoryDifficulty50P0(String p0) {
    return 'Category: difficulty 50 – $p0';
  }

  @override
  String flowCategoryBestP0(String p0) {
    return 'Category: Best $p0';
  }

  @override
  String flowCategoryP0(String p0) {
    return 'Category: $p0';
  }

  @override
  String get flowChooseCategory => 'Choose category';

  @override
  String get flowNoVersionDataFound => 'No version data found';

  @override
  String get flowSelectStars => 'Select stars';

  @override
  String get flowGenerateBestN => 'Generate Best N';

  @override
  String get flowEnterAnIntegerOf1OrMore => 'Enter an integer of 1 or more';

  @override
  String get flowNoTagDataFound => 'No tag data found';

  @override
  String get flowSelectTag => 'Select tag';

  @override
  String get flowNoMatchingChartDesigners => 'No matching chart designers';

  @override
  String flowP0P1Charts(String p0, String p1) {
    return '$p0 ($p1 charts)';
  }

  @override
  String get flowTotalCharts => 'Total charts';

  @override
  String get flowAverageRA => 'Average RA';

  @override
  String get flowInclusionMode => 'Inclusion mode';

  @override
  String get flowDrawAgain => 'Draw again';

  @override
  String flowNoChartDesigner50DataForP0(String p0) {
    return 'No chart designer 50 data for $p0';
  }

  @override
  String flowNoVersion50DataForP0(String p0) {
    return 'No version 50 data for $p0';
  }

  @override
  String flowNoGenre50DataForP0(String p0) {
    return 'No genre 50 data for $p0';
  }

  @override
  String flowNoStar50DataForP0(String p0) {
    return 'No star 50 data for $p0';
  }

  @override
  String flowNoP0DataYet(String p0) {
    return 'No $p0 data yet';
  }

  @override
  String get flowRefreshArcadePlayCountsFromMeBefore =>
      'Refresh arcade play counts from Me before viewing PC50';

  @override
  String flowSelectTagP0(String p0) {
    return 'Select tag: $p0';
  }

  @override
  String get flowCalculatingPersonalizedFittedBest50 =>
      'Calculating personalized fitted Best50…';

  @override
  String get flowSelectATagFirst => 'Select a tag first';

  @override
  String get flowSelectATagToShowYourTop =>
      'Select a tag to show your top 50 played charts with that tag, ranked by RA using fitted constants';

  @override
  String flowNoFittedBest50DataForTagP0(String p0) {
    return 'No fitted Best50 data for tag “$p0”';
  }

  @override
  String get flowNoMatchingPlayRecordsMayExistTry =>
      'No matching play records may exist.\nTry another tag.';

  @override
  String get flowChangeTag => 'Change tag';

  @override
  String flowFittedTotalRatingDifferenceFromThisTag(String p0) {
    return 'Fitted total Rating · Difference from this tag’s Best50 (average $p0)';
  }

  @override
  String get flowNoCachedPlayData => 'No cached play data';

  @override
  String get flowIdealRatingRaiseNonSSSScoresTo =>
      'Ideal Rating · Raise non-SSS+ scores to the minimum of the next grade';

  @override
  String get flowOriginalRating => 'Original Rating';

  @override
  String get flowNewEntries => 'New entries';

  @override
  String flowNewEntriesThisTimeP0Songs(String p0) {
    return 'New entries this time ($p0 songs)';
  }

  @override
  String get flowNoNewEntriesTheSameChartsRemain =>
      'No new entries (the same charts remain after the grade increase)';

  @override
  String flowConstantP0RAP1P2(String p0, String p1, String p2) {
    return 'Constant $p0 · RA $p1 → $p2';
  }

  @override
  String get flowNoData2 => 'No data';

  @override
  String flowSlotP0(String p0) {
    return 'Slot $p0';
  }

  @override
  String get flowNotSelected => 'Not selected';

  @override
  String flowP0P1ConstantP2(String p0, String p1, String p2) {
    return '$p0 · $p1 · Constant $p2';
  }

  @override
  String get flowSelectASongFirst => 'Select a song first';

  @override
  String flowInvalidAchievementExceedsP0(String p0) {
    return 'Invalid: achievement exceeds $p0%';
  }

  @override
  String flowInvalidDXScoreExceedsTheChartMaximum(String p0) {
    return 'Invalid: DX score exceeds the chart maximum of $p0';
  }

  @override
  String get flowClearThisCard => 'Clear this card';

  @override
  String get flowNoCardsFilledInYet => 'No cards filled in yet';

  @override
  String flowByP0(String p0) {
    return 'By $p0';
  }

  @override
  String get flowClearAll => 'Clear all';

  @override
  String get flowClearAll50SlotsThisCannotBe =>
      'Clear all 50 slots? This cannot be undone.';

  @override
  String get flowCustomBest50TotalRA => 'Custom Best50 total RA';

  @override
  String flowCurrentOrderP0ClearedWhenCardsChange(String p0) {
    return 'Current order: $p0 (cleared when cards change)';
  }

  @override
  String get flowAutoSort => 'Auto-sort';

  @override
  String get flowTapToFillIn => 'Tap to fill in';

  @override
  String flowP0Passed(String p0) {
    return '/ $p0 passed';
  }

  @override
  String flowRedPassP0(String p0) {
    return 'Red pass $p0';
  }

  @override
  String flowFailedP0(String p0) {
    return 'Failed $p0';
  }

  @override
  String get flowDanCourseSongs => 'Dan course songs';

  @override
  String get flowDanCertification => 'Dan certification';

  @override
  String get flowMyChallenges => 'My challenges';

  @override
  String get flowEstimatedResult => 'Estimated result';

  @override
  String get flowFailed2 => 'Failed';

  @override
  String get flowPassed => 'Passed';

  @override
  String get flowTotalAchievement => 'Total achievement';

  @override
  String get flowRemainingLife => 'Remaining life';

  @override
  String flowSongP02(String p0) {
    return 'Song $p0';
  }

  @override
  String get flowEstimatedMinimumLifeLoss => 'Estimated minimum life loss';

  @override
  String get flowLifeSettings => 'Life settings';

  @override
  String get flowStartingLife => 'Starting life';

  @override
  String get flowClearRecovery => 'Clear recovery';

  @override
  String get flowNoDanDataFound => 'No dan data found';

  @override
  String get flowYouAreOutsideTheTop100 => 'You are outside the top 100';

  @override
  String flowP0Entries2(String p0) {
    return '$p0 entries';
  }

  @override
  String get flowNoRankingDataYet => 'No ranking data yet';

  @override
  String get flowRefresh => 'Refresh';

  @override
  String get flowGoToMyRank => 'Go to my rank';

  @override
  String flowDifferenceFromBest50P0P1(String p0, String p1) {
    return 'Difference from Best50 $p0$p1';
  }

  @override
  String flowModeP02(String p0) {
    return 'Mode $p0';
  }

  @override
  String get flowDisclaimer => 'Disclaimer';

  @override
  String get flowThisLeaderboardIsForReferenceAndEntertainment =>
      'This leaderboard is for reference and entertainment and is not an official or authoritative ranking. It uses game data voluntarily uploaded by players and may contain errors or delays. Please treat rankings reasonably and enjoy the game.';

  @override
  String get flowDoNotShowAgain => 'Do not show again';

  @override
  String flowDXScoreDisplayP0TapToSwitch(String p0) {
    return 'DX score display: $p0 (tap to switch)';
  }

  @override
  String get flowDXScoreRanking => 'DX score ranking';

  @override
  String get flowAchievementRanking => 'Achievement ranking';

  @override
  String get flowNoOneIsRankedYetBeThe => 'No one is ranked yet. Be the first!';

  @override
  String get flowYourPlayDataForThisChartAppears =>
      'Your play data for this chart appears invalid. Please check it.';

  @override
  String get flowChooseRankingType => 'Choose ranking type';

  @override
  String get flowReverse => 'Reverse';

  @override
  String get flowForward => 'Forward';

  @override
  String get flowShowingPreviouslySavedDataRefreshWhenConnected =>
      'Showing previously saved data. Refresh when connected.';

  @override
  String get flowNoLeaderboardDataYetTryRefreshingLater =>
      'No leaderboard data yet. Try refreshing later.';

  @override
  String get flowBilibiliChartVideoViews => 'Bilibili chart video views';

  @override
  String flowDifficultyP02(String p0) {
    return 'Difficulty: $p0';
  }

  @override
  String flowCurrentViewsP0(String p0) {
    return 'Current views: $p0';
  }

  @override
  String flowBVIDP0(String p0) {
    return 'BV ID: $p0';
  }

  @override
  String flowSourceP0(String p0) {
    return 'Source: $p0';
  }

  @override
  String get flowLoadingViews => 'Loading views…';

  @override
  String get flowNoViewDataYet => 'No view data yet';

  @override
  String get flowEnterBVIDManually => 'Enter BV ID manually';

  @override
  String get flowIfViewsCannotBeFetchedAutomaticallyEnter =>
      'If views cannot be fetched automatically, enter the BV ID of this song’s chart confirmation video.';

  @override
  String get flowExampleBV1xx411c7mD => 'Example: BV1xx411c7mD';

  @override
  String flowViewsP0(String p0) {
    return 'Views: $p0';
  }

  @override
  String flowP010000(String p0) {
    return '$p0 × 10,000';
  }

  @override
  String get flowCheckBVID => 'Check BV ID';

  @override
  String get flowBVIDUploaded => 'BV ID uploaded';

  @override
  String get flowConfirmUpload => 'Confirm upload';

  @override
  String get flowChartScoreCard => 'Chart score card';

  @override
  String get flowScoreShareCard => 'Score share card';

  @override
  String get flowSongInformation => 'Song information';

  @override
  String get flowSongInformationImage => 'Song information image';

  @override
  String get flowStoragePermissionIsRequiredToSaveImages =>
      'Storage permission is required to save images';

  @override
  String get flowCouldNotLoadCoverArt => 'Could not load cover art';

  @override
  String get flowCoverArtSavedToPhotos => 'Cover art saved to photos';

  @override
  String flowSaveFailedP02(String p0) {
    return 'Save failed: $p0';
  }

  @override
  String get flowPlayPV => 'Play PV';

  @override
  String get flowChooseHowToPlayThePV => 'Choose how to play the PV';

  @override
  String get flowOpenBilibili => 'Open Bilibili';

  @override
  String get flowPlayInApp => 'Play in app';

  @override
  String get flowPleaseWait => 'Please wait';

  @override
  String get flowLoadingRelatedCollectibles => 'Loading related collectibles…';

  @override
  String get flowError => 'Error';

  @override
  String get flowCouldNotLoadRelatedCollectiblesTryAgain =>
      'Could not load related collectibles. Try again later.';

  @override
  String get flowChartNotes => 'Chart notes';

  @override
  String get flowAddChartNotes => 'Add chart notes';

  @override
  String get flowWriteYourNotesForThisChartHere =>
      'Write your notes for this chart here…\nFor example: watch the hand order on the final slides.';

  @override
  String flowCreatedP0P1(String p0, String p1) {
    return 'Created: $p0$p1';
  }

  @override
  String flowUpdatedP0(String p0) {
    return '\nUpdated: $p0';
  }

  @override
  String get flowConfirmDeletion => 'Confirm deletion';

  @override
  String get flowDeleteTheNotesForThisChartThis =>
      'Delete the notes for this chart? This cannot be undone.';

  @override
  String get flowRelatedCollectibles => 'Related collectibles';

  @override
  String get flowNoCollectiblesLinkedToThisSong =>
      'No collectibles linked to this song';

  @override
  String get flowRefreshDataOnTheHomePageTo =>
      'Refresh data on the home page to obtain your identity first';

  @override
  String get flowRatingSubmitted => 'Rating submitted';

  @override
  String get flowCouldNotSubmitRating => 'Could not submit rating';

  @override
  String get flowDeleteYourRating => 'Delete your rating?';

  @override
  String get flowRatingDeleted => 'Rating deleted';

  @override
  String get flowCouldNotDeleteRating => 'Could not delete rating';

  @override
  String get flowChartRating => 'Chart rating';

  @override
  String flowP0Ratings(String p0) {
    return '($p0 ratings)';
  }

  @override
  String get flowDistribution => 'Distribution';

  @override
  String get flowRatingsAreForReferencePleaseRateObjectively =>
      'Ratings are for reference. Please rate objectively.';

  @override
  String get flowRefreshRatings => 'Refresh ratings';

  @override
  String get flowMyRecentRatings => 'My recent ratings';

  @override
  String get flowMyRatingTapToEdit => 'My rating (tap to edit)';

  @override
  String get flowRateThisChart => 'Rate this chart';

  @override
  String get flowDeleteRating => 'Delete rating';

  @override
  String get flowUpdate => 'Update';

  @override
  String get flowSubmit => 'Submit';

  @override
  String get flowRefreshDataOnTheHomePageTo2 =>
      'Refresh data on the home page to obtain your identity before rating';

  @override
  String get flowNoRatingsYet2 => 'No ratings yet';

  @override
  String get flowRatingDistribution => 'Rating distribution';

  @override
  String flowP0Ratings2(String p0) {
    return '$p0 ratings';
  }

  @override
  String flowAverageP0(String p0) {
    return 'Average $p0';
  }

  @override
  String get flowSetYourIdentityFirst => 'Set your identity first';

  @override
  String get flowCommentPosted => 'Comment posted';

  @override
  String get flowCouldNotPostComment => 'Could not post comment';

  @override
  String flowCouldNotPostCommentP0(String p0) {
    return 'Could not post comment: $p0';
  }

  @override
  String get flowCannotDeleteIdentityInformationIsMissing =>
      'Cannot delete: identity information is missing';

  @override
  String get flowDeleteThisComment => 'Delete this comment?';

  @override
  String get flowCommentDeleted => 'Comment deleted';

  @override
  String get flowCouldNotDeleteComment => 'Could not delete comment';

  @override
  String get flowComments => 'Comments';

  @override
  String get flowCommentsRefreshed => 'Comments refreshed';

  @override
  String get flowRefreshComments => 'Refresh comments';

  @override
  String get flowCommentsAreForReferencePleaseBeRespectful =>
      'Comments are for reference. Please be respectful.';

  @override
  String get flowRefreshDataOnTheHomePageTo3 =>
      'Refresh data on the home page to obtain your comment identity';

  @override
  String get flowEnterYourComment => 'Enter your comment…';

  @override
  String get flowPost => 'Post';

  @override
  String get flowNoCommentsYetBeTheFirstTo =>
      'No comments yet. Be the first to post!';

  @override
  String get flowMe => 'Me';

  @override
  String get flowViewNotes => 'View notes';

  @override
  String get flowAddNotes => 'Add notes';

  @override
  String get flowExportSongInformation => 'Export song information';

  @override
  String get flowShareScore => 'Share score';

  @override
  String get flowEnlargeCoverArt => 'Enlarge cover art';

  @override
  String get flowSwitchToDX => 'Switch to DX';

  @override
  String get flowSwitchToST => 'Switch to ST';

  @override
  String flowP0LevelP1(String p0, String p1) {
    return '$p0 level $p1';
  }

  @override
  String flowNoScoreForP0Yet(String p0) {
    return 'No score for $p0 yet';
  }

  @override
  String get flowPlayAndSyncToSeeYourScore =>
      'Play and sync to see your score here';

  @override
  String flowDXScoreMAXP0(String p0) {
    return 'DX score (MAX −$p0)';
  }

  @override
  String get flowShowStarBonus => 'Show star bonus';

  @override
  String get flowShowPointsNeededForTheNextStar =>
      'Show points needed for the next star';

  @override
  String get flowRatingPotential => 'Rating potential';

  @override
  String get flowBasicInformation => 'Basic information';

  @override
  String get flowNoteDistribution => 'Note distribution';

  @override
  String get flowBREAKDistribution => 'BREAK distribution';

  @override
  String get flowNoGlobalGradeOrComboDistributionData =>
      'No global grade or combo distribution data for this chart yet';

  @override
  String get flowTAPGREATsAllBREAKsCriticalPerfect =>
      ' TAP GREATs (all BREAKs critical perfect)';

  @override
  String get flowOpenCalculatorWithThisChartSNotes =>
      'Open calculator with this chart’s notes and score';

  @override
  String get flowNoTagsYet => 'No tags yet';

  @override
  String get flowTagDataFrom => 'Tag data from ';

  @override
  String get flowUnknownTag => 'Unknown tag';

  @override
  String get flowConstantHistory => 'Constant history';

  @override
  String get flowStarsDXScoreTable => 'Stars / DX score table';

  @override
  String get flowStars => 'Stars';

  @override
  String get flowDXScore2 => 'DX score';

  @override
  String get flowPlayers => 'Players';

  @override
  String get flowAchievementScoreTable => 'Achievement / score table';

  @override
  String get flowScore => 'Score';

  @override
  String get flowJudgmentAllowance => 'Judgment allowance';

  @override
  String get flowNoteType => 'Note type:';

  @override
  String get flowShareOfTotalWeight => 'Share of total weight:';

  @override
  String get flowBREAKLossSoFar => 'BREAK loss so far';

  @override
  String get flow50PointLosses => '50-point losses';

  @override
  String get flowInvalid => 'Invalid';

  @override
  String get flow100PointLosses => '100-point losses';

  @override
  String get flow80GREATCount => '80% GREAT count';

  @override
  String get flow60GREATCount => '60% GREAT count';

  @override
  String get flow50GREATCount => '50% GREAT count';

  @override
  String get flowGOODCount => 'GOOD count';

  @override
  String get flowMISSCount => 'MISS count';

  @override
  String get flowTotalBREAKLoss => 'Total BREAK loss: ';

  @override
  String get flowRemainingBudgetSSS => 'Remaining budget (SSS+): ';

  @override
  String get flowRemainingBudgetSSS2 => 'Remaining budget (SSS): ';

  @override
  String get flowRemainingBudgetSS => 'Remaining budget (SS+): ';

  @override
  String get flowRemainingBudgetSS2 => 'Remaining budget (SS): ';

  @override
  String get flowGREATLoss => 'GREAT loss';

  @override
  String get flowGOODLoss => 'GOOD loss';

  @override
  String get flowMISSLoss => 'MISS loss';

  @override
  String get flowSSSGREATAllowance => 'SSS+ GREAT allowance';

  @override
  String get flowSSSGOODAllowance => 'SSS+ GOOD allowance';

  @override
  String get flowSSSMISSAllowance => 'SSS+ MISS allowance';

  @override
  String flowP0(String p0) {
    return '$p0';
  }

  @override
  String get flowSSSGREATAllowance2 => 'SSS GREAT allowance';

  @override
  String get flowSSSGOODAllowance2 => 'SSS GOOD allowance';

  @override
  String get flowSSSMISSAllowance2 => 'SSS MISS allowance';

  @override
  String get flowSSGREATAllowance => 'SS+ GREAT allowance';

  @override
  String get flowSSGOODAllowance => 'SS+ GOOD allowance';

  @override
  String get flowSSMISSAllowance => 'SS+ MISS allowance';

  @override
  String get flowSSGREATAllowance2 => 'SS GREAT allowance';

  @override
  String get flowSSGOODAllowance2 => 'SS GOOD allowance';

  @override
  String get flowSSMISSAllowance2 => 'SS MISS allowance';

  @override
  String get flow50PointLoss => '50-point loss';

  @override
  String get flow100PointLoss => '100-point loss';

  @override
  String get flow80GREATLoss => '80% GREAT loss';

  @override
  String get flow60GREATLoss => '60% GREAT loss';

  @override
  String get flow50GREATLoss => '50% GREAT loss';

  @override
  String get flow0580GREATAllowance => '−0.5%: 80% GREAT allowance';

  @override
  String get flow0560GREATAllowance => '−0.5%: 60% GREAT allowance';

  @override
  String get flow0550GREATAllowance => '−0.5%: 50% GREAT allowance';

  @override
  String get flow05Allowance => '−0.5% allowance';

  @override
  String get flow180GREATAllowance => '−1%: 80% GREAT allowance';

  @override
  String get flow160GREATAllowance => '−1%: 60% GREAT allowance';

  @override
  String get flow150GREATAllowance => '−1%: 50% GREAT allowance';

  @override
  String get flow1Allowance => '−1% allowance';

  @override
  String get flowGradeDistributionReferenceOnly =>
      'Grade distribution (reference only)';

  @override
  String get flowComboDistributionReferenceOnly =>
      'Combo distribution (reference only)';

  @override
  String get flowInTheOrderBPMMarkersAppearIn =>
      'In the order BPM markers appear in this chart';

  @override
  String get flowChangeIndex => 'Change index';

  @override
  String get flowPlayOnBilibili => 'Play on Bilibili';

  @override
  String get flowPlayableRegions => 'Playable regions';

  @override
  String get flowParsingDataUnavailable => 'Parsing data unavailable';

  @override
  String get flowExcludesSLIDETOUCHAndBREAKStars =>
      'Excludes SLIDE, TOUCH and BREAK stars.';

  @override
  String get flowAliasesNone => 'Aliases: none';

  @override
  String flowAliasesForP0(String p0) {
    return 'Aliases for $p0';
  }

  @override
  String get flowTapAnyAliasToCopy => 'Tap any alias to copy';

  @override
  String flowViewAliasesP0(String p0) {
    return 'View aliases ($p0)';
  }

  @override
  String flowDXScoreP02(String p0) {
    return 'DX score $p0%';
  }

  @override
  String flowRankP0P1RatingP2(String p0, String p1, String p2) {
    return 'Rank $p0, $p1, Rating $p2';
  }

  @override
  String get flowRatingHeadroom => 'Rating headroom';

  @override
  String flowRaiseToP0P1(String p0, String p1) {
    return 'Raise to $p0 ($p1%)';
  }

  @override
  String flowDXScoreP0P12(String p0, String p1) {
    return 'DX score $p0 / $p1';
  }

  @override
  String get flowViewSongDetails => 'View song details';

  @override
  String flowP0SongsRemaining(String p0) {
    return '$p0 songs remaining';
  }

  @override
  String flowP0EqualToTheLastChartOn(String p0) {
    return '$p0, equal to the last chart on the list';
  }

  @override
  String flowP0ConstantP1RAP2(String p0, String p1, String p2) {
    return '$p0 · Constant $p1 · RA $p2';
  }

  @override
  String get flowAddScoreHistory => 'Add score history';

  @override
  String flowScoreHistoryP0(String p0) {
    return 'Score history ($p0)';
  }

  @override
  String get flowTheCurveDropsInGameScoresKeep =>
      'The curve drops: in-game scores keep the best result, so this is usually a recording difference caused by switching accounts or sources.';

  @override
  String get flowUnknownDate => 'Unknown date';

  @override
  String flowShowAllP0Entries(String p0) {
    return 'Show all ($p0 entries)';
  }

  @override
  String get flowAddChartScoreHistory => 'Add chart score history';

  @override
  String get flowAchievement3 => 'Achievement (%)';

  @override
  String get flowSumOfUTAGESubcharts => 'Sum of UTAGE subcharts';

  @override
  String get flowNormalChartLimit => 'Normal chart limit';

  @override
  String get flowDXScoreOptional => 'DX score (optional)';

  @override
  String get flowChartMaximumScore => 'Chart maximum score';

  @override
  String get flowSelectTime => 'Select time';

  @override
  String get flowSeconds059 => 'Seconds (0–59)';

  @override
  String get flowDeleteThisDataPoint => 'Delete this data point?';

  @override
  String get flowThisCannotBeUndoneIfThisIs =>
      'This cannot be undone. If this is an automatically recorded current score, the next refresh may record it again.';

  @override
  String get flowDataVoluntarilyUploadedByPlayersForReference =>
      'Data voluntarily uploaded by players, for reference and entertainment';

  @override
  String get flowBriefProfilesAreHiddenForAnonymousPlayers =>
      'Brief profiles are hidden for anonymous players';

  @override
  String get flowCouldNotLoadTheBriefProfileTry =>
      'Could not load the brief profile. Try again later.';

  @override
  String get flowReload => 'Reload';

  @override
  String get flowUnknownPlayer => 'Unknown player';

  @override
  String get flowNoTitleSet => 'No title set';

  @override
  String get flowB1IsTheChartWithTheHighest =>
      'B1 is the chart with the highest song Rating in the corresponding Best list.';

  @override
  String get flowNoScoresYet => 'No scores yet';

  @override
  String get flowDanCompletion => 'Dan completion';

  @override
  String get flowTotalAchievementUpTo4040000 =>
      'Total achievement (up to 404.0000%)';

  @override
  String get flowCompletionRate => 'Completion rate';

  @override
  String flowP0Songs2(String p0) {
    return '$p0 songs';
  }

  @override
  String get flowExcluded => 'Excluded';

  @override
  String get flowCompleted => 'Completed';

  @override
  String get flowIncomplete => 'Incomplete';

  @override
  String get flowLoading4 => 'Loading';

  @override
  String get flowFirstRecord => 'First record';

  @override
  String flowP0P1Changes(String p0, String p1) {
    return '−$p0 · $p1 changes';
  }

  @override
  String get flowRecorded => ' Recorded';

  @override
  String get flowTheScoreChangedDuringTheDayBut =>
      'The score changed during the day, but the latest value is back to the day’s starting value.';

  @override
  String get flowNoChange => 'No change';

  @override
  String get flowPlaybackProgressDragTheOuterRingTo =>
      'Playback progress: drag the outer ring to seek; swipe the cover left or right to change songs';

  @override
  String get flowElapsed => 'Elapsed';

  @override
  String get flowDuration2 => 'Duration';

  @override
  String get flowQueue => 'Queue';

  @override
  String get flowLoadingAudio => 'Loading audio';

  @override
  String get flowOpenPlaybackQueue => 'Open playback queue';

  @override
  String get flowPlaybackQueue => 'Playback queue';

  @override
  String flowPlaybackModeP0TapToSwitchAnd(String p0) {
    return 'Playback mode: $p0 (tap to switch and expand)';
  }

  @override
  String get flowRepeatCount => 'Repeat count';

  @override
  String get flowNotSet2 => 'Not set';

  @override
  String flowP0Times(String p0) {
    return '$p0 times';
  }

  @override
  String get flowUnlimited => 'Unlimited';

  @override
  String get flowRepeatTheCurrentSongIndefinitely =>
      'Repeat the current song indefinitely';

  @override
  String get flowSetCount => 'Set count';

  @override
  String get flowDecreaseCount => 'Decrease count';

  @override
  String get flowIncreaseCount => 'Increase count';

  @override
  String get flowHideFloatingPlayer => 'Hide floating player';

  @override
  String get flowPlaylist => 'Playlist';

  @override
  String get flowKeepPlayingAndReopenTheFloatingPlayer =>
      'Keep playing and reopen the floating player from the music player later, or pause and remove the media notification.';

  @override
  String get flowKeepPlaying => 'Keep playing';

  @override
  String get flowPauseAndRemove => 'Pause and remove';

  @override
  String get flowSongTitle2 => 'Song title';

  @override
  String get flowTranslatedByBaiduSLanguageModel =>
      'Translated by Baidu’s language model';

  @override
  String get flowTranslating => 'Translating…';

  @override
  String get flowDifficultiesToPlayMultipleSelections =>
      'Difficulties to play (multiple selections)';

  @override
  String get flowNotesOptional => 'Notes (optional)';

  @override
  String get flowExamplePlayWithFriends => 'Example: play with friends';

  @override
  String get flowAdd => 'Add';

  @override
  String get flowTotalSongs => 'Total songs';

  @override
  String get flowPathCopiedToClipboard => 'Path copied to clipboard';

  @override
  String get flowNoAppAvailableToViewImages =>
      'No app available to view images';

  @override
  String get flowCopied => 'Copied';

  @override
  String get flowCopyPath => 'Copy path';

  @override
  String flowPublicDirectoryIsNotWritableSavedTo(String p0) {
    return 'Public directory is not writable. Saved to the fallback path: $p0';
  }

  @override
  String get flowViewImage => 'View image';

  @override
  String get flowPerRow => 'Per row';

  @override
  String get flowFewerAvatarsPerRow => 'Fewer avatars per row';

  @override
  String get flowMoreAvatarsPerRow => 'More avatars per row';

  @override
  String get flowChooseAppearance => 'Choose appearance';

  @override
  String flowSearchP0ByNameDescriptionOrID(String p0) {
    return 'Search $p0 by name, description or ID';
  }

  @override
  String flowP0Items3(String p0) {
    return '$p0 items';
  }

  @override
  String flowLoadingP0(String p0) {
    return 'Loading $p0…';
  }

  @override
  String flowNoP0YetRefreshCollectibleDataFirst(String p0) {
    return 'No $p0 yet. Refresh collectible data first.';
  }

  @override
  String flowNoMatchingP0(String p0) {
    return 'No matching $p0';
  }

  @override
  String get flowPNGLosslessOriginalQuality =>
      'PNG lossless (original quality)';

  @override
  String get flowJPEGHighQuality => 'JPEG high quality';

  @override
  String get flowJPEGStandard => 'JPEG standard';

  @override
  String get flowJPEGCompressed => 'JPEG compressed';

  @override
  String get flowChooseExportQuality => 'Choose export quality';

  @override
  String flowExportingP0(String p0) {
    return 'Exporting: $p0';
  }

  @override
  String get flowImageTheme => 'Image theme';

  @override
  String get flowThunderMode => 'Thunder mode';

  @override
  String get flowArrangeCardsIn50RowsOr50 =>
      'Arrange cards in 50 rows or 50 columns for a very long image';

  @override
  String get flowExportPreview => 'Export preview';

  @override
  String get flowConfirmExport => 'Confirm export';

  @override
  String flowCouldNotGeneratePreviewP0(String p0) {
    return 'Could not generate preview: $p0';
  }

  @override
  String flowP0P1EstimatedP2(String p0, String p1, String p2) {
    return '$p0, $p1, estimated $p2';
  }

  @override
  String flowAboutP0(String p0) {
    return 'About $p0';
  }

  @override
  String get flowQuestionPool => 'Question pool';

  @override
  String get flowGameRules => 'Game rules';

  @override
  String get flowMaximumGuesses => 'Maximum guesses';

  @override
  String get flowTimeLimit => 'Time limit';

  @override
  String get flowTo => 'to';

  @override
  String get flowEnter10150ThenTap =>
      'Enter 1.0–15.0, then tap elsewhere or press Enter to apply';

  @override
  String get flowBest35ConstantRange => 'Best35 constant range';

  @override
  String get flowBest15ConstantRange => 'Best15 constant range';

  @override
  String get flowBest50Average => 'Best 50 average';

  @override
  String get flowBest35Average => 'Best 35 average';

  @override
  String get flowBest15Average => 'Best 15 average';

  @override
  String get flowSSSCountIn50Charts => 'SSS+ count in 50 charts';

  @override
  String get flowSSSCountIn50Charts2 => 'SSS count in 50 charts';

  @override
  String get flowPotentialConstantRATable => 'Potential constant / RA table';

  @override
  String get flowFittedTotalRating => 'Fitted total Rating';

  @override
  String get flowDifferenceFromBest50 => 'Difference from Best50';

  @override
  String get flowAverageAchievementDXScoreRate2 =>
      'Average achievement / DX score rate';

  @override
  String flowCurrentOrderP0(String p0) {
    return 'Current order: $p0';
  }

  @override
  String get flowTotalRA => 'Total RA';

  @override
  String get flowSongs => 'Songs';

  @override
  String get flowComparedWithThisTagSBest50 =>
      'Compared with this tag’s Best50';

  @override
  String get flowSongAchievement => 'Song achievement';

  @override
  String flowTotalRatingP0(String p0) {
    return 'Total Rating $p0';
  }

  @override
  String flowP0ConstantP1(String p0, String p1) {
    return '$p0 (constant $p1)';
  }

  @override
  String get flowNoteStatistics => 'Note statistics';

  @override
  String get flowBREAKStatistics => 'BREAK statistics';

  @override
  String flowP0P1P2Statistics2(String p0, String p1, String p2) {
    return '$p0 $p1 ($p2) statistics';
  }

  @override
  String flowChartDesignerP0(String p0) {
    return 'Chart designer: $p0';
  }

  @override
  String flowVersionP0(String p0) {
    return 'Version: $p0';
  }

  @override
  String flowGenreP0(String p0) {
    return 'Genre: $p0';
  }

  @override
  String flowComposerP0(String p0) {
    return 'Composer: $p0';
  }

  @override
  String flowP0P1P2SongsTotal(String p0, String p1, String p2) {
    return '$p0$p1 · $p2 songs total';
  }

  @override
  String get flowFolderNameCannotBeEmpty => 'Folder name cannot be empty';

  @override
  String get flowNoAudioIsAvailableForThisSong =>
      'No audio is available for this song yet';

  @override
  String get flowCouldNotLoadAudioTryAgainLater =>
      'Could not load audio. Try again later.';

  @override
  String get flowReadingLocalVideo => 'Reading local video…';

  @override
  String get flowBufferingVideo => 'Buffering video…';

  @override
  String get flowNoMatchingChartCodeFound => 'No matching chart code found';

  @override
  String flowCouldNotFetchChartCodeP0(String p0) {
    return 'Could not fetch chart code: $p0';
  }

  @override
  String get flowExporting2 => 'Exporting…';

  @override
  String get flowNoChartCodeAvailable => 'No chart code available';

  @override
  String get flowAudio => 'Audio';

  @override
  String flowCouldNotFetchP0ThePackageOnly(String p0) {
    return 'Could not fetch $p0. The package only contains chart data; add the missing files after importing to play properly.';
  }

  @override
  String get flowPreparingChart => 'Preparing chart…';

  @override
  String get flowReadingChartSettings => 'Reading chart settings…';

  @override
  String get flowFindingAudio => 'Finding audio…';

  @override
  String get flowPreparingCoverArt => 'Preparing cover art…';

  @override
  String get flowParsingChartData => 'Parsing chart data…';

  @override
  String get flowAudioLoadedFromLocalCache => 'Audio loaded from local cache';

  @override
  String get flowAnd => ' and ';

  @override
  String flowP0MinutesAgo(String p0) {
    return '$p0 minutes ago';
  }

  @override
  String flowP0HoursAgo(String p0) {
    return '$p0 hours ago';
  }

  @override
  String flowP0DaysAgo(String p0) {
    return '$p0 days ago';
  }

  @override
  String get flowCustomChart2 => 'Custom chart';

  @override
  String get flowMaidataFileSelected => 'maidata file selected';

  @override
  String get flowTheLibraryIsNotReadyRefreshData =>
      'The library is not ready. Run Pull scores & update data from home, or check your connection and retry.';

  @override
  String flowCouldNotLoadLibraryP0(String p0) {
    return 'Could not load library: $p0';
  }

  @override
  String get flowNotificationPermissionWasNotGrantedBackgroundPlayback =>
      'Notification permission was not granted. Background playback still works, but the notification player will be hidden.';

  @override
  String get flowDownloaded2 => 'Downloaded';

  @override
  String flowDownloadFailedP02(String p0) {
    return 'Download failed: $p0';
  }

  @override
  String get flowTheCurrentSongIsNotInThis =>
      'The current song is not in this list';

  @override
  String get flowNoPlayableSongs => 'No playable songs';

  @override
  String get flowNoMatchingSongs => 'No matching songs';

  @override
  String flowP0PlayableSongs(String p0) {
    return '$p0 playable songs';
  }

  @override
  String flowExcludedP0UTAGESongs(String p0) {
    return 'Excluded $p0 UTAGE songs';
  }

  @override
  String flowP0SongsHaveNoDivingFishEntry(String p0) {
    return '$p0 songs have no Diving-Fish entry';
  }

  @override
  String get flowCalculating => 'Calculating';

  @override
  String get flowSwitchingSongs => 'Switching songs…';

  @override
  String get flowThisIsTheLastSong => 'This is the last song';

  @override
  String get flowUpNext => 'Up next';

  @override
  String get flowUpToOneDecimalPlaceLeaveBlank =>
      'Up to one decimal place. Leave blank for the default.';

  @override
  String get flowUpToFourDecimalPlacesLeaveBlank =>
      'Up to four decimal places. Leave blank for the default.';

  @override
  String get flowGrade => 'Grade';

  @override
  String get flowLowerBound => 'Lower bound';

  @override
  String get flowUpperBound => 'Upper bound';

  @override
  String get flowCategory => 'Category';

  @override
  String get flowSelectALevel => 'Select a level';

  @override
  String get flowSelectAVersion => 'Select a version';

  @override
  String get flowSelectAGenre => 'Select a genre';

  @override
  String get flowTitleType => 'Title type';

  @override
  String get flowNoMatchingChartDesigners2 => 'No matching chart designers';

  @override
  String get flowNoMatchingComposers => 'No matching composers';

  @override
  String get flowSongs2 => 'songs';

  @override
  String get flowNoSongsMatchThisLevel => 'No songs match this level';

  @override
  String get flowNoSongsMatchThisChartDesigner =>
      'No songs match this chart designer';

  @override
  String get flowNoSongsMatchThisVersion => 'No songs match this version';

  @override
  String get flowNoSongsMatchThisGenre => 'No songs match this genre';

  @override
  String get flowNoSongsMatchThisComposer => 'No songs match this composer';

  @override
  String flowLvP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Lv.$p0 ($p1) · $p2 title statistics';
  }

  @override
  String flowChartDesignerP0P1P2TitleStatistics(
      String p0, String p1, String p2) {
    return 'Chart designer $p0 ($p1) · $p2 title statistics';
  }

  @override
  String flowVersionP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Version $p0 ($p1) · $p2 title statistics';
  }

  @override
  String flowGenreP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Genre $p0 ($p1) · $p2 title statistics';
  }

  @override
  String flowComposerP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Composer $p0 ($p1) · $p2 title statistics';
  }

  @override
  String get flowFriendCode => 'Friend code';

  @override
  String flowEnterYourFriendSP02(String p0) {
    return 'Enter your friend’s $p0';
  }

  @override
  String flowMeP0(String p0) {
    return 'Me · $p0';
  }

  @override
  String get flowMyWins => 'My wins';

  @override
  String get flowFriendSWins => 'Friend’s wins';

  @override
  String get flowFriend => 'Friend';

  @override
  String get flowFirstCharacter => 'First character';

  @override
  String get flowSelectAFirstCharacter => 'Select a first character';

  @override
  String get flowNoSongsMatchThisDifficulty => 'No songs match this difficulty';

  @override
  String get flowByAverageAchievement => 'By average achievement';

  @override
  String get flowByConstantDifference => 'By constant difference';

  @override
  String get flowAvgAchievement => 'Avg. achievement';

  @override
  String get flowConstantDifference => 'Constant difference';

  @override
  String flowPersonalBestP0(String p0) {
    return 'Personal best $p0%';
  }

  @override
  String get flowLast30Days => 'Last 30 days';

  @override
  String get flowLast90Days => 'Last 90 days';

  @override
  String flowLimitP0TheoreticalValueUnavailable(String p0) {
    return 'Limit $p0 (theoretical value unavailable)';
  }

  @override
  String flowCouldNotLoadImprovementHistoryP0(String p0) {
    return 'Could not load improvement history: $p0';
  }

  @override
  String get flowChangesAreRecordedAutomaticallyAfterYourScores =>
      'Changes are recorded automatically after your scores refresh successfully. Diving-Fish, LXNS and AWMC NET records are kept separately by source and account.\n\nThe first refresh creates a baseline if no old scores exist. Unchanged refreshes add nothing. Multiple changes to one chart on the same day merge into one card showing the value before the first change and the latest value.\n\nRecords use the local date of the refresh. The timestamp is when a change was detected, not when you played. Cards show improvement, regression, no change or mixed changes. Newly seen charts are marked as first records.\n\nRating refers to that chart’s Rating, not a change in total Rating. History stays on this device and does not backfill scores from before recording began.';

  @override
  String get flowNoScoreImprovementRecordsYet =>
      'No score improvement records yet';

  @override
  String get flowNoMatchingRecords => 'No matching records';

  @override
  String get flowBestScoresThatChangeAfterASuccessful =>
      'Best scores that change after a successful refresh will appear here.';

  @override
  String get flowTryAnotherKeywordOrDate => 'Try another keyword or date.';

  @override
  String get flowCouldNotLoad => 'Could not load';

  @override
  String flowRequestFailedP0(String p0) {
    return 'Request failed ($p0)';
  }

  @override
  String flowNetworkErrorP0(String p0) {
    return 'Network error: $p0';
  }

  @override
  String flowP0MinutesAgo2(String p0) {
    return '$p0 minutes ago';
  }

  @override
  String flowP0HoursAgo2(String p0) {
    return '$p0 hours ago';
  }

  @override
  String flowP0DaysAgo2(String p0) {
    return '$p0 days ago';
  }

  @override
  String flowP0User(String p0) {
    return '$p0 user';
  }

  @override
  String flowCouldNotSaveSnapshotP0(String p0) {
    return 'Could not save snapshot: $p0';
  }

  @override
  String get flowHighestConstantsFromOlderVersions =>
      'Highest constants from older versions';

  @override
  String get flowBestScoresFromOlderVersions =>
      'Best scores from older versions';

  @override
  String get flowHighestConstantsFromThisVersion =>
      'Highest constants from this version';

  @override
  String get flowBestScoresFromThisVersion => 'Best scores from this version';

  @override
  String get flowPattern => 'Pattern';

  @override
  String get flowEvaluation => 'Evaluation';

  @override
  String get flowModeATakeTheTop50Charts =>
      'Mode A: take the top 50 charts by Rating using fitted constants, without separating Best35 and Best15.';

  @override
  String get flowModeBReplaceConstantsInYourOfficial =>
      'Mode B: replace constants in your official Best35 and Best15 with fitted constants, recalculate Rating and sort descending.';

  @override
  String get flowModeCTakeTheTop35Older =>
      'Mode C: take the top 35 older-version charts and top 15 current-version charts by Rating using fitted constants.';

  @override
  String get flowTop35FromOlderVersions => 'Top 35 from older versions';

  @override
  String get flowTop15FromThisVersion => 'Top 15 from this version';

  @override
  String flowP0ChartsHaveNoFittedConstantOfficial(String p0) {
    return '$p0 charts have no fitted constant; official constants are used.';
  }

  @override
  String flowIncludesP0(String p0) {
    return 'Includes: $p0';
  }

  @override
  String flowChartDesigner50P0(String p0) {
    return 'Chart designer 50 – $p0';
  }

  @override
  String flowVersion50P0(String p0) {
    return 'Version 50 – $p0';
  }

  @override
  String flowGenre50P0(String p0) {
    return 'Genre 50 – $p0';
  }

  @override
  String flowStar50P0(String p0) {
    return 'Star 50 – $p0';
  }

  @override
  String flowTag50P0(String p0) {
    return 'Tag 50 – $p0';
  }

  @override
  String flowPersonalizedBest50P0(String p0) {
    return 'Personalized Best50 – $p0';
  }

  @override
  String flowChartDesigner50P0Statistics(String p0) {
    return 'Chart designer 50 – $p0 statistics';
  }

  @override
  String flowVersion50P0Statistics(String p0) {
    return 'Version 50 – $p0 statistics';
  }

  @override
  String flowGenre50P0Statistics(String p0) {
    return 'Genre 50 – $p0 statistics';
  }

  @override
  String flowStar50P0Statistics(String p0) {
    return 'Star 50 – $p0 statistics';
  }

  @override
  String flowTag50P0Statistics(String p0) {
    return 'Tag 50 – $p0 statistics';
  }

  @override
  String flowP0Statistics(String p0) {
    return '$p0 statistics';
  }

  @override
  String flowPersonalizedFittedBest50P0(String p0) {
    return 'Personalized fitted Best50 – $p0';
  }

  @override
  String flowTagP0P1ChartsTop50By(String p0, String p1) {
    return 'Tag: $p0 · $p1 charts · Top 50 by song Rating using fitted constants';
  }

  @override
  String get flowAverage => 'Average';

  @override
  String get flowOlderVersions => 'Older versions';

  @override
  String get flowCurrentVersion => 'Current version';

  @override
  String flowP0InvalidEntriesAchievementOrDXScore(String p0) {
    return '⚠ $p0 invalid entries (achievement or DX score exceeds the chart limit)';
  }

  @override
  String get flowEG1005 => 'e.g. 100.5';

  @override
  String get flowEG3000 => 'e.g. 3000';

  @override
  String get flowEnterAchievement => 'Enter achievement';

  @override
  String flowDifficultyP03(String p0) {
    return 'Difficulty $p0';
  }

  @override
  String get flowRADescending => 'RA descending';

  @override
  String get flowRAAscending => 'RA ascending';

  @override
  String get flowConstantDescending => 'Constant descending';

  @override
  String get flowConstantAscending => 'Constant ascending';

  @override
  String get flowFilled => 'Filled';

  @override
  String flowCouldNotLoadP0(String p0) {
    return 'Could not load: $p0';
  }

  @override
  String get flowModeATop50ByFittedRating =>
      'Mode A: top 50 by fitted Rating, without categories';

  @override
  String get flowModeBRecalculateOfficialBest35Best15Using =>
      'Mode B: recalculate official Best35/Best15 using fitted constants';

  @override
  String get flowModeCTop35OlderChartsAnd =>
      'Mode C: top 35 older charts and top 15 new charts';

  @override
  String get flow6MaximumReached => '✦ 6 maximum reached';

  @override
  String get flowCouldNotLoadLeaderboardData =>
      'Could not load leaderboard data';

  @override
  String get flowAchievementRanking2 => 'Achievement ranking';

  @override
  String get flowDXScoreRanking2 => 'DX score ranking';

  @override
  String flowCouldNotFetchLeaderboardP0(String p0) {
    return 'Could not fetch leaderboard: $p0';
  }

  @override
  String get flowBREAKShareRanking => 'BREAK share ranking';

  @override
  String get flowSameSongDifficultyGapRanking =>
      'Same-song difficulty gap ranking';

  @override
  String get flowSLIDEShareRanking => 'SLIDE share ranking';

  @override
  String get flowTOUCHShareRanking => 'TOUCH share ranking';

  @override
  String get flowTAPShareRanking => 'TAP share ranking';

  @override
  String get flowHOLDShareRanking => 'HOLD share ranking';

  @override
  String get flowBREAKCountRanking => 'BREAK count ranking';

  @override
  String get flowNormalChartBREAKCountRanking =>
      'Normal-chart BREAK count ranking';

  @override
  String get flowConstantDifferenceRanking => 'Constant difference ranking';

  @override
  String get flowMASTERReMASTERConstantDifferenceRanking =>
      'MASTER/Re:MASTER constant difference ranking';

  @override
  String get flowEXPERTConstantDifferenceRanking =>
      'EXPERT constant difference ranking';

  @override
  String get flowSampleCountRanking => 'Sample count ranking';

  @override
  String get flowNoteCountRanking => 'Note count ranking';

  @override
  String get flowMASTERReMASTERAverageAchievementRanking =>
      'MASTER/Re:MASTER average achievement ranking';

  @override
  String get flowEXPERTAverageAchievementRanking =>
      'EXPERT average achievement ranking';

  @override
  String get flowBPMRanking => 'BPM ranking';

  @override
  String get flowBREAKShare => 'BREAK share';

  @override
  String get flowConstantGap => 'Constant gap';

  @override
  String get flowSLIDEShare => 'SLIDE share';

  @override
  String get flowTOUCHShare => 'TOUCH share';

  @override
  String get flowTAPShare => 'TAP share';

  @override
  String get flowHOLDShare => 'HOLD share';

  @override
  String get flowBREAKCount => 'BREAK count';

  @override
  String get flowSampleCount => 'Sample count';

  @override
  String get flowRankByBREAKCountOrderCanBe =>
      'Rank by BREAK count (order can be reversed)';

  @override
  String get flowRankByBREAKCountExcludingUTAGEOrder =>
      'Rank by BREAK count, excluding UTAGE (order can be reversed)';

  @override
  String get flowBREAKCountTotalNotesRankedAsA =>
      'BREAK count ÷ total notes, ranked as a percentage (order can be reversed)';

  @override
  String get flowTAPCountTotalNotesIncludesSTDX =>
      'TAP count ÷ total notes; includes ST/DX/UT (order can be reversed)';

  @override
  String get flowHOLDCountTotalNotesIncludesSTDX =>
      'HOLD count ÷ total notes; includes ST/DX/UT (order can be reversed)';

  @override
  String get flowSLIDECountTotalNotesIncludesSTDX =>
      'SLIDE count ÷ total notes; includes ST/DX/UT (order can be reversed)';

  @override
  String get flowTOUCHCountTotalNotesIncludesDXUT =>
      'TOUCH count ÷ total notes; includes DX/UT, excludes ST (order can be reversed)';

  @override
  String get flowOfficialConstantGapForEXPERTMASTERAnd =>
      'Official constant gap for EXPERT→MASTER and MASTER→Re:MASTER of the same song, later minus earlier (order can be reversed)';

  @override
  String get flowRankByFittedMinusOfficialConstantOrder =>
      'Rank by fitted minus official constant (order can be reversed)';

  @override
  String get flowMASTERReMASTEROnlyOrderCanBe =>
      'MASTER/Re:MASTER only (order can be reversed)';

  @override
  String get flowEXPERTOnlyOrderCanBeReversed =>
      'EXPERT only (order can be reversed)';

  @override
  String get flowRankByTotalPlayerSamplesOrderCan =>
      'Rank by total player samples (order can be reversed)';

  @override
  String get flowRankByTheTotalOfAllFive =>
      'Rank by the total of all five note types (order can be reversed)';

  @override
  String get flowRankByAverageAchievementOrderCanBe =>
      'Rank by average achievement (order can be reversed)';

  @override
  String get flowRankBySongBPMOrderCanBe =>
      'Rank by song BPM (order can be reversed)';

  @override
  String get flowEnterABVID => 'Enter a BV ID';

  @override
  String get flowInvalidBVIDExpectedBVFollowedBy =>
      'Invalid BV ID (expected BV followed by 10 characters)';

  @override
  String get flowCheckFailedVideoInformationUnavailableTheBV =>
      'Check failed: video information unavailable (the BV ID may not exist)';

  @override
  String flowVerifiedVideoTitleP0(String p0) {
    return 'Verified! Video title: “$p0”';
  }

  @override
  String flowCheckFailedVideoTitleP0DoesNot(String p0, String p1) {
    return 'Check failed: video title “$p0” does not contain song title “$p1”';
  }

  @override
  String flowVerificationErrorP0(String p0) {
    return 'Verification error: $p0';
  }

  @override
  String get flowSongPV => 'Song PV';

  @override
  String get flowPlayThisChartAtLeastOnceBefore =>
      'Play this chart at least once before rating';

  @override
  String get flowInvalidScorePleaseCheckIt => 'Invalid score. Please check it.';

  @override
  String get flowContentCannotBeEmpty => 'Content cannot be empty';

  @override
  String get flowCommentsCannotExceed500Characters =>
      'Comments cannot exceed 500 characters';

  @override
  String get flowSending => 'Sending…';

  @override
  String get flowOpenBilibili2 => 'Open Bilibili';

  @override
  String flowRelatedCollectiblesP0(String p0) {
    return 'Related collectibles $p0';
  }

  @override
  String flowMyScoreP0(String p0) {
    return 'My score · $p0';
  }

  @override
  String flowPlayedP0Times(String p0) {
    return 'Played $p0 times';
  }

  @override
  String flowFittedP0P1(String p0, String p1) {
    return 'Fitted $p0$p1';
  }

  @override
  String get flowDuration3 => 'Duration';

  @override
  String get flowScoreHistory => 'Score history';

  @override
  String get flowData => 'Data';

  @override
  String get flowCommunity => 'Community';

  @override
  String get flowTools => 'Tools';

  @override
  String get flowTrueBREAKTAP => 'True BREAK TAP';

  @override
  String get flowTrueBREAKHOLD => 'True BREAK HOLD';

  @override
  String get flowProtectedBREAK => 'Protected BREAK';

  @override
  String get flowBREAKStar => 'BREAK star';

  @override
  String get flowCategory2 => 'Category';

  @override
  String get flowTotal => 'Total ';

  @override
  String get flowSSSAllowance => 'SSS+ allowance';

  @override
  String get flowSSSAllowance2 => 'SSS allowance';

  @override
  String get flowChartTagsReferenceOnly => 'Chart tags (reference only)';

  @override
  String get flowPreview => 'Preview';

  @override
  String get flowMore => 'More';

  @override
  String get flowViewChartCode => 'View chart code';

  @override
  String get flowUTAGESongsAreExcludedFromBest50 =>
      'UTAGE songs are excluded from Best50';

  @override
  String flowThisChartIsAlreadyWithinP0With(String p0) {
    return 'This chart is already within $p0 with no room to improve';
  }

  @override
  String flowThisChartCannotEnterP0(String p0) {
    return 'This chart cannot enter $p0';
  }

  @override
  String flowReachP0ToP1P2(String p0, String p1, String p2) {
    return 'Reach $p0% to $p1 $p2';
  }

  @override
  String get flowEnter => 'Enter';

  @override
  String flowThisChartHasRAP0ReachingThe(String p0, String p1) {
    return 'This chart has RA $p0. Reaching the achievement below can add to the $p1 total:';
  }

  @override
  String flowThisChartIsNotInP0The(String p0, String p1) {
    return 'This chart is not in $p0; the last chart has RA $p1. Replacing it at the achievement below adds to the total:';
  }

  @override
  String flowP0BaseP1(String p0, String p1) {
    return '$p0 (base $p1)';
  }

  @override
  String get flowUserUpload => 'User upload';

  @override
  String get flowRedisCache => 'Redis cache';

  @override
  String get flowAutomaticLookup => 'Automatic lookup';

  @override
  String get flowUnknownType => 'Unknown type';

  @override
  String get flowCountCannotBeNegative => 'Count cannot be negative';

  @override
  String flowPlayedCountP0CannotExceedTheTotal(String p0, String p1) {
    return 'Played count ($p0) cannot exceed the total BREAK count ($p1)';
  }

  @override
  String flowBREAKLossIsP0BeyondTheSS(String p0) {
    return 'BREAK loss is $p0%, beyond the SS (−2%) limit. No allowance remains.';
  }

  @override
  String flowP0DaysApart(String p0) {
    return '($p0 days apart)';
  }

  @override
  String flowFirstReleaseP0(String p0) {
    return 'First release $p0';
  }

  @override
  String get flowBase => 'Base';

  @override
  String get flowProtectedNOTEDistribution => 'Protected NOTE distribution';

  @override
  String get flowProtectedTAP => 'Protected TAP';

  @override
  String get flowProtectedHOLD => 'Protected HOLD';

  @override
  String get flowUnprotectedNOTEDistribution => 'Unprotected NOTE distribution';

  @override
  String get flowUnprotectedTAP => 'Unprotected TAP';

  @override
  String get flowUnprotectedHOLD => 'Unprotected HOLD';

  @override
  String get flowTwoColumns => 'Two columns';

  @override
  String get flowOneColumn => 'One column';

  @override
  String flowP00Songs(String p0) {
    return '$p0: 0 songs';
  }

  @override
  String flowP0P1SongsMinP2AvgP3(String p0, String p1, String p2, String p3) {
    return '$p0: $p1 songs · Min $p2 · Avg $p3 · Tap a card for Rating potential';
  }

  @override
  String get flowSongLimitReached => 'Song limit reached';

  @override
  String flowChartHistoryCouldNotReadChartHistoryIgnored(String p0) {
    return '[ChartHistory] Could not read chart history (ignored): $p0';
  }

  @override
  String flowP0AchievementP1P2(String p0, String p1, String p2) {
    return '$p0\nAchievement $p1%$p2';
  }

  @override
  String flowDXScoreP03(String p0) {
    return ' · DX score $p0';
  }

  @override
  String get flow1DataPoint => '1 data point';

  @override
  String flowP0Changes(String p0) {
    return '$p0 changes';
  }

  @override
  String get flowDXScoreOfMaximum => 'DX score (% of maximum)';

  @override
  String flowP0AchievementP1DXScoreP2(String p0, String p1, String p2) {
    return '$p0\nAchievement $p1%\nDX score $p2';
  }

  @override
  String get flowChartLimit => 'Chart limit';

  @override
  String get flowDeleteThisDataPoint2 => 'Delete this data point';

  @override
  String get flowPlayerBriefProfile => 'Player brief profile';

  @override
  String get flowBriefProfileUnavailable => 'Brief profile unavailable';

  @override
  String get flowLoadingBriefProfile => 'Loading brief profile…';

  @override
  String get flowNoBackgroundSet => 'No background set';

  @override
  String get flowLoadingBackground => 'Loading background';

  @override
  String get flowBackgroundUnavailable => 'Background unavailable';

  @override
  String get flowNoNameplateSet => 'No nameplate set';

  @override
  String get flowLoadingNameplate => 'Loading nameplate';

  @override
  String get flowNameplateUnavailable => 'Nameplate unavailable';

  @override
  String flowTitleP0(String p0) {
    return 'Title #$p0';
  }

  @override
  String get flowNotAttempted => 'Not attempted';

  @override
  String get flowRedPass => 'Red pass';

  @override
  String get flowEnterAValidTotalAchievement =>
      'Enter a valid total achievement';

  @override
  String get flowTotalAchievementMustBeBetween0And =>
      'Total achievement must be between 0 and 404%';

  @override
  String get flowTotalAchievementSupportsUpToFourDecimal =>
      'Total achievement supports up to four decimal places';

  @override
  String get flowTotal2 => 'Total';

  @override
  String get flowByLevel => 'By level';

  @override
  String get flowByConstant => 'By constant';

  @override
  String get flowRegression => 'Regression';

  @override
  String get flowChange2 => 'Change';

  @override
  String get flowClosePlaybackModeSelection => 'Close playback mode selection';

  @override
  String get flowSequential => 'Sequential';

  @override
  String get flowShuffle => 'Shuffle';

  @override
  String get flowRepeatOne => 'Repeat one';

  @override
  String get flowTranslationIsUnavailableTryAgainLater =>
      'Translation is unavailable. Try again later.';

  @override
  String get flowTranslationFailedTryAgainLater =>
      'Translation failed. Try again later.';

  @override
  String get flowNumberOfEntries => 'Number of entries';

  @override
  String flowSourceP02(String p0) {
    return 'Source $p0';
  }

  @override
  String flowGeneratedByChiffonMaiCommunityGroupP0(String p0) {
    return 'Generated by ChiffonMai · Community group $p0';
  }

  @override
  String get flowExportSuccessful => 'Export successful';

  @override
  String get flowExported => 'Exported';

  @override
  String get flow50Rows1Column => '50 rows, 1 column';

  @override
  String get flow1Row50Columns => '1 row, 50 columns';

  @override
  String get flowZoomOut => 'Zoom out';

  @override
  String get flowZoomIn => 'Zoom in';

  @override
  String get flowFitToWindow => 'Fit to window';

  @override
  String get flowMustBeGreaterThan0 => 'Must be greater than 0';

  @override
  String flowMustNotExceedP0P1(String p0, String p1) {
    return 'Must not exceed $p0$p1';
  }

  @override
  String flowLimitP0P1(String p0, String p1) {
    return 'Limit $p0 ($p1)';
  }

  @override
  String flowRatingP0Best35P1Best15P2Average(
      String p0, String p1, String p2, String p3, String p4) {
    return 'Rating $p0\nBest35 $p1 · Best15 $p2\nAverage achievement $p3%\nAverage DX score rate $p4%';
  }

  @override
  String get flowTheoreticalBest35HighestConstantsFromOlderVersions =>
      'Theoretical Best35 · Highest constants from older versions';

  @override
  String get flowBest35BestScoresFromOlderVersions =>
      'Best35 · Best scores from older versions';

  @override
  String get flowTheoreticalBest15HighestConstantsFromThisVersion =>
      'Theoretical Best15 · Highest constants from this version';

  @override
  String get flowBest15BestScoresFromThisVersion =>
      'Best15 · Best scores from this version';

  @override
  String flowAverageP02(String p0) {
    return 'Average $p0';
  }

  @override
  String flowFittedRatingP0AverageRatingP1Average(
      String p0, String p1, String p2, String p3) {
    return 'Fitted Rating $p0\nAverage Rating $p1\nAverage achievement $p2%\nAverage DX score rate $p3%';
  }

  @override
  String get flowBest50BasedOnFittedConstants =>
      'Best50 based on fitted constants';

  @override
  String flowP0ChartsTotalRatingP1AverageDX(String p0, String p1, String p2) {
    return '$p0 charts\nTotal Rating $p1\nAverage DX score rate $p2%';
  }

  @override
  String flowAverageRAP0(String p0) {
    return 'Average RA $p0';
  }

  @override
  String flowFittedRatingP0VsThisTagS(
      String p0, String p1, String p2, String p3, String p4, String p5) {
    return 'Fitted Rating $p0 (vs. this tag’s Best50 $p1$p2)\nAverage Rating $p3\nAverage achievement $p4%\nAverage DX score rate $p5%';
  }

  @override
  String get flowChartType => 'Chart type';

  @override
  String get flowReferenceDuration => 'Reference duration';

  @override
  String get flowNOTECountsAndTotalNotes => 'NOTE counts and total notes';

  @override
  String get flowBREAKCounts => 'BREAK counts';

  @override
  String get flowTotalNotes => 'Total notes';

  @override
  String get flowOfficialConstant => 'Official constant';

  @override
  String get flowFittedConstant => 'Fitted constant';

  @override
  String get flowTotal3 => 'Total';

  @override
  String get flowRequestingStoragePermission =>
      'Requesting storage permission…';

  @override
  String get flowBuildingExportContent => 'Building export content…';

  @override
  String get flowPreloadingImages => 'Preloading images…';

  @override
  String get flowRenderingExportContent => 'Rendering export content…';

  @override
  String get flowGeneratingImage => 'Generating image…';

  @override
  String get flowSavingImage => 'Saving image…';

  @override
  String get flowExportComplete => 'Export complete';

  @override
  String get flowBPMRange => 'BPM range';

  @override
  String get flowBaseBPM => 'Base BPM';

  @override
  String get flowSOrLower => 'S+ or lower';

  @override
  String get flowNoCombo => 'No combo';

  @override
  String get flowNoSync => 'No sync';

  @override
  String flowCouldNotLoadDataP0(String p0) {
    return 'Could not load data: $p0';
  }

  @override
  String get flowUncategorized => 'Uncategorized';

  @override
  String get flowNarrowPass50 => 'Narrow pass 50';

  @override
  String get flowJustShort50 => 'Just short 50';

  @override
  String get flowNarrowSSS50 => 'Narrow SSS+ 50';

  @override
  String get flowJustShortOfSSS50 => 'Just short of SSS+ 50';

  @override
  String get flowNarrowSSS502 => 'Narrow SSS 50';

  @override
  String get flowJustShortOfSSS502 => 'Just short of SSS 50';

  @override
  String get flowChartDesigner50 => 'Chart designer 50';

  @override
  String get flowGenre50 => 'Genre 50';

  @override
  String get flowVersion50 => 'Version 50';

  @override
  String get flowLevel50 => 'Level 50';

  @override
  String flowLevel50P0(String p0) {
    return 'Level 50 – $p0';
  }

  @override
  String flowCategoryLevel50P0(String p0) {
    return 'Category: level 50 – $p0';
  }

  @override
  String get flowStar50 => 'Star 50';

  @override
  String get flowTag50 => 'Tag 50';

  @override
  String get flowRandom50 => 'Random 50';

  @override
  String get flowOverreach50 => 'Overreach 50';

  @override
  String get flowDifficulty50 => 'Difficulty 50';

  @override
  String get flowDan => 'Dan';

  @override
  String get flowTrueDan => 'True Dan';

  @override
  String get flowOverallRanking => 'Overall ranking';

  @override
  String get flowStarBonus => 'Star bonus';

  @override
  String get flowToNextStar => 'To next star';

  @override
  String get flowPNGLossless => 'PNG lossless';

  @override
  String get flowOriginalQuality => 'Original quality';

  @override
  String get flowClearImageSmallerFile => 'Clear image, smaller file';

  @override
  String get flowGoodForSharing => 'Good for sharing';

  @override
  String get flowSmallestFile => 'Smallest file';

  @override
  String get detailChartBpm => 'Chart';

  @override
  String get bestDisplayCover => 'Cover';

  @override
  String get bestDisplayTwoColumns => '2 cols';

  @override
  String get bestDisplayOneColumn => '1 col';

  @override
  String rankingServiceUnavailable(String code) {
    return 'Leaderboard service unavailable ($code)';
  }

  @override
  String get rankingInvalidResponse => 'Invalid leaderboard response';

  @override
  String get ratingFetchFailed => 'Could not fetch ratings';

  @override
  String commentPostHttpFailed(String code) {
    return 'Could not post comment ($code)';
  }

  @override
  String commentDeleteHttpFailed(String code) {
    return 'Could not delete comment ($code)';
  }

  @override
  String get unknownDataSource => 'Unknown source';

  @override
  String get exportBlackTheme => 'Black';

  @override
  String get songTabHistory => 'History';

  @override
  String get songTabCommunity => 'Social';

  @override
  String get flowUnknown => 'Unknown';

  @override
  String get flowChooseDownloadMethod => 'Choose download method';

  @override
  String get flowDownloadInBrowser => 'Download in browser';

  @override
  String get flowOpenDownloadPage => 'Open download page';

  @override
  String get flowDownloadInApp => 'Download in app';

  @override
  String get flowDownloadInTheBackgroundWhileYouKeep =>
      'Download in the background while you keep using the app';

  @override
  String get flowChooseDownloadRoute => 'Choose download route';

  @override
  String get flowCouldNotConnectToTheServerCheck =>
      'Could not connect to the server. Check your connection and retry.';

  @override
  String get flowYouAreUpToDate => 'You are up to date';

  @override
  String flowCurrentVersionP0BuildP1(String p0, String p1) {
    return 'Current version: $p0 (build: $p1)';
  }

  @override
  String flowLatestVersionP0BuildP1(String p0, String p1) {
    return 'Latest version: $p0 (build: $p1)';
  }

  @override
  String flowLatestChangesP0(String p0) {
    return 'Latest changes:\n$p0';
  }

  @override
  String get flowHideFor3Days => 'Hide for 3 days';

  @override
  String get flowDownloadNow => 'Download now';

  @override
  String flowCouldNotOpenLinkP0(String p0) {
    return 'Could not open link: $p0';
  }

  @override
  String get flowEmailAddressCopied => 'Email address copied';

  @override
  String get flowCreationAndSupport => 'Creation and support';

  @override
  String get flowSupporterAcknowledgments => 'Supporter acknowledgments';

  @override
  String get flowDataAndServices => 'Data and services';

  @override
  String get flowDesignInspiration => 'Design inspiration';

  @override
  String get flowThankYouForEveryContributionThatHelps =>
      'Thank you for every contribution that helps ChiffonMai grow.';

  @override
  String get flowHereForEveryMaimaiVisit => 'Here for every maimai visit';

  @override
  String get flowReadingVersion => 'Reading version…';

  @override
  String flowVersionP02(String p0) {
    return 'Version $p0';
  }

  @override
  String get flowAppRegistrationICP20240152563A =>
      'App registration: 津ICP备2024015256号-3A';

  @override
  String get flowDevelopmentAndMaintenance => 'Development and maintenance';

  @override
  String get flowInputError => 'Input error';

  @override
  String get flowTargetAchievement => 'Target achievement';

  @override
  String get flowEG1005000 => 'e.g. 100.5000';

  @override
  String get flowJudgmentDetails => 'Judgment details';

  @override
  String get flowForBREAKEnterTheMainJudgmentCounts =>
      'For BREAK, enter the main judgment counts. The 50/100-point losses and GREAT subtypes are calculated in reverse.';

  @override
  String get flowCalculating2 => 'Calculating…';

  @override
  String get flowCalculateBREAKDetails => 'Calculate BREAK details';

  @override
  String get flowSolutionFoundError00001 => 'Solution found (error ≤ 0.0001%)';

  @override
  String get flowNoExactSolutionShowingTheClosestResult =>
      'No exact solution; showing the closest result';

  @override
  String flowTargetP0BaseP1ExtraP2(String p0, String p1, String p2) {
    return 'Target $p0% · Base $p1% · Extra $p2%';
  }

  @override
  String flowTotalAchievementP0P1P2(String p0, String p1, String p2) {
    return 'Total achievement $p0% · $p1 $p2%';
  }

  @override
  String get flowError2 => 'Error';

  @override
  String get flowMinimumError => 'Minimum error';

  @override
  String get flowJudgmentLossPerNote => 'Judgment loss per note';

  @override
  String flowP0BREAKsBaseBonusScoreRatiosBelow(String p0) {
    return '$p0 BREAKs · Base / bonus score ratios below each row';
  }

  @override
  String flowP0P1NotesRedValuesShowAchievement(String p0, String p1) {
    return '$p0: $p1 notes · Red values show achievement lost for that judgment';
  }

  @override
  String get flowViewPerNoteLoss => 'View per-note loss';

  @override
  String get flowLiveAchievement => 'Live achievement';

  @override
  String get flowEnterJudgmentCountsBelowToCalculateAutomatically =>
      'Enter judgment counts below to calculate automatically';

  @override
  String flowTotalAchievementP0GradeP1(String p0, String p1) {
    return 'Total achievement $p0%, grade $p1';
  }

  @override
  String flowBaseP0BonusP1(String p0, String p1) {
    return 'Base $p0% · Bonus $p1%';
  }

  @override
  String get flowAlreadyAtTheHighestGradeSSS =>
      'Already at the highest grade, SSS+';

  @override
  String flowP2NeededForP0P1(String p0, String p1, String p2) {
    return '$p2% needed for $p0 ($p1%)';
  }

  @override
  String get flowAlternatingPlayRestSegmentsLetTheWheel =>
      'Alternating play / rest segments let the wheel decide whether you visit the arcade today.';

  @override
  String get flowSegments => 'Segments';

  @override
  String get flowFewerSegments => 'Fewer segments';

  @override
  String get flowMoreSegments => 'More segments';

  @override
  String get flow20ByDefaultUpTo100Changes =>
      '20 by default, up to 100. Changes in steps of 2 to keep the segments alternating.';

  @override
  String get flowSpinning => 'Spinning…';

  @override
  String get flowStartWhenYouAreReady => 'Start when you are ready';

  @override
  String flowThisSpinP0(String p0) {
    return 'This spin: $p0';
  }

  @override
  String get flowSpin => 'Spin';

  @override
  String get flowError3 => 'Error +';

  @override
  String get flowEG5 => 'e.g. 5';

  @override
  String get flowNoMatchingResults => 'No matching results';

  @override
  String get flowBREAKDistributionCalculator => 'BREAK distribution calculator';

  @override
  String get flowTAPGREATAllowance => ' TAP GREAT allowance';

  @override
  String get flowUserData => 'User data';

  @override
  String flowP0TAPGREATs(String p0) {
    return '$p0 TAP GREATs';
  }

  @override
  String get flowTodaySRecommendations => 'Today’s recommendations';

  @override
  String get flowPreparingTodaySRecommendations =>
      'Preparing today’s recommendations…';

  @override
  String get flowAnotherBatch => 'Another batch';

  @override
  String get flowPickingTodaySRecommendations =>
      'Picking today’s recommendations…';

  @override
  String get flowNoChartsToRecommendYetRefreshData =>
      'No charts to recommend yet.\nRefresh data from home first.';

  @override
  String get flowBackupsExportFavoritesChartNotesAccountProfiles =>
      'Backups export favorites, chart notes, account profiles, settings, guessing statistics, score and Rating history, custom backgrounds and archived local chart packages as JSON.\n\nSign-in credentials, personal keys and automatic sync identities are excluded; authorize again on a new device. Downloadable caches such as the song library, maidata, audio, PVs and leaderboards are excluded.\n\nOlder backups are supported but can only restore the settings and data they contain. Maximum file size: 50 MB.';

  @override
  String get flowExportBackup => 'Export backup';

  @override
  String get flowExportLocalDataAsAJSONFile =>
      'Export local data as a JSON file';

  @override
  String flowExportedToP0(String p0) {
    return 'Exported to: $p0';
  }

  @override
  String get flowImportBackup => 'Import backup';

  @override
  String get flowRestoreDataFromAJSONBackup =>
      'Restore data from a JSON backup';

  @override
  String get flowChooseWhereToSaveTheBackup =>
      'Choose where to save the backup';

  @override
  String get flowExportCancelled => 'Export cancelled';

  @override
  String get flowConfirmRestore => 'Confirm restore';

  @override
  String get flowRestoringOverwritesCurrentLocalSettingsAndProfiles =>
      'Restoring overwrites current local settings and profiles. v3 backups also restore user files; older backups restore only their original contents. Export your current backup first if needed.';

  @override
  String flowBackupVersionVP0(String p0) {
    return 'Backup version: v$p0';
  }

  @override
  String flowExportedP0(String p0) {
    return 'Exported: $p0';
  }

  @override
  String flowContainsP0DataItems(String p0) {
    return 'Contains $p0 data items';
  }

  @override
  String flowUserFilesP0(String p0) {
    return 'User files: $p0';
  }

  @override
  String flowExcludedP0CacheItems(String p0) {
    return 'Excluded $p0 cache items';
  }

  @override
  String get flowSongMaidataAndLeaderboardCachesAreExcluded =>
      'Song, maidata and leaderboard caches are excluded and fetched again when needed; the first load may be slower. Sign-in credentials are not restored.';

  @override
  String get flowThisCannotBeUndoneContinue =>
      'This cannot be undone. Continue?';

  @override
  String get flowRestore => 'Restore';

  @override
  String flowRestoredP0SettingsAndP1UserFiles(String p0, String p1) {
    return 'Restored $p0 settings and $p1 user files.\nRestart the app for all changes to take effect.';
  }

  @override
  String flowImportFailedP02(String p0) {
    return 'Import failed: $p0';
  }

  @override
  String get flowMinimumConstant => 'Minimum constant';

  @override
  String get flowMaximumConstant => 'Maximum constant';

  @override
  String get flowNoRecommendationsCheckTheConstantRange =>
      'No recommendations. Check the constant range.';

  @override
  String get flowRenameFavoritesFolder => 'Rename favorites folder';

  @override
  String get flowEnterANewName => 'Enter a new name';

  @override
  String get flowDeleteFavoritesFolder => 'Delete favorites folder';

  @override
  String flowDeleteP0ChartsWillRemainButWill(String p0) {
    return 'Delete “$p0”?\nCharts will remain but will no longer be grouped.';
  }

  @override
  String flowDeletedP0(String p0) {
    return 'Deleted “$p0”';
  }

  @override
  String get flowImportFavorites => 'Import favorites';

  @override
  String get flowAddChartsToFavoritesFoldersFromSong =>
      'Add charts to favorites folders from song details';

  @override
  String flowOrUseImportFavoritesAboveP0(String p0) {
    return 'Or use “Import favorites” above, $p0';
  }

  @override
  String get flowRemoveChart => 'Remove chart';

  @override
  String flowRemoveP1FromP0(String p0, String p1) {
    return 'Remove “$p1” from “$p0”?';
  }

  @override
  String get flowRemove => 'Remove';

  @override
  String get flowRemoved => 'Removed';

  @override
  String get flowSortOrder => 'Sort order';

  @override
  String get flowExportFavorites => 'Export favorites';

  @override
  String get flowFavoritesFolderIsEmpty => 'Favorites folder is empty';

  @override
  String get flowRemoveFromFavoritesFolder => 'Remove from favorites folder';

  @override
  String flowP0Selected(String p0) {
    return '$p0 selected';
  }

  @override
  String get flowMove => 'Move';

  @override
  String get flowRemoveMultipleCharts => 'Remove multiple charts';

  @override
  String flowRemoveP1ChartsFromP0(String p0, String p1) {
    return 'Remove $p1 charts from “$p0”?';
  }

  @override
  String flowRemovedP0Charts(String p0) {
    return 'Removed $p0 charts';
  }

  @override
  String get flowNoOtherFoldersToMoveTo => 'No other folders to move to';

  @override
  String get flowMoveTo => 'Move to…';

  @override
  String flowMovedP0Charts(String p0) {
    return 'Moved $p0 charts';
  }

  @override
  String get flowThisFolderIsEmptyThereAreNo =>
      'This folder is empty; there are no charts to export.';

  @override
  String get flowChooseWhereToExportFavorites =>
      'Choose where to export favorites';

  @override
  String flowExportedP02(String p0) {
    return 'Exported $p0';
  }

  @override
  String get flowImportItInTheAppOrOpen =>
      'Import it in the app, or open the file in a file manager to import it directly.';

  @override
  String get flowFileSavedTo => 'File saved to:';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved =>
      'The public directory is not writable. Saved to the app’s private directory, which may not be visible in file managers.';

  @override
  String get flowInvalidLink => 'Invalid link';

  @override
  String get flowCouldNotOpenABrowserLinkCopied3 =>
      'Could not open a browser. Link copied to clipboard.';

  @override
  String get flowRelatedCommunityProjectsTapACardTo =>
      'Related community projects. Tap a card to open its website.';

  @override
  String flowSkippedP0ForThisSession(String p0) {
    return 'Skipped $p0 for this session';
  }

  @override
  String flowCouldNotSaveFeedbackP0(String p0) {
    return 'Could not save feedback: $p0';
  }

  @override
  String flowStoppedRecommendingP0UndoInFeedbackManagement(String p0) {
    return 'Stopped recommending $p0 (undo in feedback management)';
  }

  @override
  String flowPausedRecommendationsForP0For14Days(String p0) {
    return 'Paused recommendations for $p0 for 14 days';
  }

  @override
  String get flowUndo => 'Undo';

  @override
  String get flowManageFeedback => 'Manage feedback';

  @override
  String get flowNoChartsCanDirectlyRaiseYourRating =>
      'No charts can directly raise your Rating right now.\nRefresh your scores and check again.';

  @override
  String get flowNoUnseenCandidatesMatchStartOverOr =>
      'No unseen candidates match.\nStart over or undo exclusions in feedback management.';

  @override
  String get flowTotalGainIfAllTargetsOnThis =>
      'Total gain if all targets on this page are met (B50 recalculated step by step, accounting for replacements)';

  @override
  String flowBatchP0P1EntriesEachGainIs(String p0, String p1) {
    return 'Batch $p0 · $p1 entries (each gain is independent; do not add them directly)';
  }

  @override
  String get flowStartOver => 'Start over';

  @override
  String get flowNoMore => 'No more';

  @override
  String get flowCurrentB50 => 'Current B50';

  @override
  String flowB35CutoffP0(String p0) {
    return 'B35 · Cutoff $p0';
  }

  @override
  String flowB15CutoffP0(String p0) {
    return 'B15 · Cutoff $p0';
  }

  @override
  String flowCountedB35P0P1B15P2P3(String p0, String p1, String p2, String p3) {
    return 'Counted: B35 $p0/$p1 · B15 $p2/$p3';
  }

  @override
  String get flowNetGain => 'Net gain';

  @override
  String get flowFeedback => 'Feedback';

  @override
  String get flowSkipThisTime => 'Skip this time';

  @override
  String get flowTemporarilyStuck14Days => 'Temporarily stuck (14 days)';

  @override
  String get flowDislikeThisChart => 'Dislike this chart';

  @override
  String flowNoScoreRecordedReferenceTargetP0(String p0) {
    return 'No score recorded → Reference target $p0%';
  }

  @override
  String flowP0P1GainP2(String p0, String p1, String p2) {
    return '$p0% → $p1% (gain $p2%)';
  }

  @override
  String get flowSteadyTargetImprovement020Challenge0 =>
      'Steady = target improvement ≤ 0.20%; Challenge = ≤ 0.80%; Explore = no recorded score, estimated from your median at the same constant. “Steady” means a small gap, not a success probability.\nBased on locally cached scores; results change after refreshing data.';

  @override
  String get flowRatingGainRecommendationsPoweredByAWMC =>
      'Rating gain recommendations powered by AWMC';

  @override
  String get flowUndoingDoesNotInsertChartsBackInto =>
      'Undoing does not insert charts back into this batch. They may appear in the next batch or after starting over.';

  @override
  String get flowNoFeedbackYet => 'No feedback yet';

  @override
  String get flowDislikedUntilUndone => 'Disliked · Until undone';

  @override
  String flowTemporarilyStuckClearsAutomaticallyOnP0(String p0) {
    return 'Temporarily stuck · Clears automatically on $p0';
  }

  @override
  String flowP0ArcadesTapToExpand(String p0) {
    return '$p0 arcades; tap to expand';
  }

  @override
  String get flowTurnOnDeviceLocationServicesFirst =>
      'Turn on device location services first';

  @override
  String get flowLocationPermissionIsPermanentlyDeniedEnableIt =>
      'Location permission is permanently denied. Enable it in system settings.';

  @override
  String get flowCouldNotGetYourLocationCheckThat =>
      'Could not get your location. Check that location services are on and reception is good.';

  @override
  String flowLocationFailedP0(String p0) {
    return 'Location failed: $p0';
  }

  @override
  String get flowFiltered => ' (filtered)';

  @override
  String flowP0ArcadesInViewNearbyPointsGrouped(String p0) {
    return ' $p0 arcades in view (nearby points grouped automatically)';
  }

  @override
  String flowLastUpdatedP0(String p0) {
    return 'Last updated: $p0';
  }

  @override
  String get flowSearchArcadeNameOrAddress => 'Search arcade name or address';

  @override
  String get flowMachineFilters => 'Machine filters';

  @override
  String get flowNoArcadeDataYet => 'No arcade data yet';

  @override
  String get flowMachines => '🎮 Machines:';

  @override
  String get flowCouldNotOpenTheLinkTryAgain =>
      'Could not open the link. Try again later.';

  @override
  String get flowCouldNotLoadDocumentTapToRetry =>
      'Could not load document. Tap to retry.';

  @override
  String get flowSubmitALoadingQuote => 'Submit a loading quote';

  @override
  String get flowAddALocalQuote => 'Add a local quote';

  @override
  String get flowUploadFailedTryAgainLater => 'Upload failed. Try again later.';

  @override
  String flowSubmittedForReviewP0ShownOnlyAfter(String p0) {
    return 'Submitted for review ($p0); shown only after approval';
  }

  @override
  String get flowLocalQuoteAdded => 'Local quote added';

  @override
  String get flowCouldNotFetchLoadingQuotesKeptThe =>
      'Could not fetch loading quotes. Kept the local cache.';

  @override
  String get flowRefreshQuotes => 'Refresh quotes';

  @override
  String flowP0QuotesEnabled(String p0) {
    return '/ $p0 quotes enabled';
  }

  @override
  String get flowAddLocally => 'Add locally';

  @override
  String get flowUploadToCloud => 'Upload to cloud';

  @override
  String get flowDeleteLocalQuote => 'Delete local quote';

  @override
  String get flowEnterALoadingQuote => 'Enter a loading quote';

  @override
  String get flowDataFromIsMaiDownByChongxi => 'Data from isMaiDown by Chongxi';

  @override
  String get flowServiceStatus => 'Service status';

  @override
  String get flowReadingServerStatus => 'Reading server status…';

  @override
  String flowUpdatedP02(String p0) {
    return 'Updated: $p0';
  }

  @override
  String get flowDifficultyNotSpecified => 'Difficulty not specified';

  @override
  String flowNoteP0(String p0) {
    return 'Note: $p0';
  }

  @override
  String get flowRemoveThisEntry => 'Remove this entry';

  @override
  String get flowMeetChiffonMai => 'Meet ChiffonMai';

  @override
  String get flowFiveTabsKeepEverythingWithinReach =>
      'Five tabs keep everything within reach.';

  @override
  String get flowRefreshDataThenStartExploring =>
      'Refresh data, then start exploring';

  @override
  String get flowARefreshPreparesSongsConstantsTagsAnd =>
      'A refresh prepares songs, constants, tags and scores.\nYou can browse without signing in.';

  @override
  String get flowMakeItFeelLikeYourApp => 'Make it feel like your app';

  @override
  String get flowFindTheseOptionsInMeSettingsAnd =>
      'Find these options in Me → Settings, and change them anytime.';

  @override
  String get flowPhotosAndMedia => 'Photos and media';

  @override
  String get flowChooseCoverArtAndSaveExportedSong =>
      'Choose cover art and save exported song information and score images.';

  @override
  String get flowCamera => 'Camera';

  @override
  String get flowCaptureCoverArtOrScoreImagesFor =>
      'Capture cover art or score images for recognition.';

  @override
  String get flowLocation => 'Location';

  @override
  String get flowUsedForLocationFeaturesOnTheGlobal =>
      'Used for location features on the global arcade map.';

  @override
  String get flowNotifications => 'Notifications';

  @override
  String get flowShowPlaybackControlsDuringBackgroundMusicPlayback =>
      'Show playback controls during background music playback.';

  @override
  String get flowCouldNotSaveConfirmationPleaseRetry =>
      'Could not save confirmation. Please retry.';

  @override
  String get flowSeparateGuardianConsent => 'Separate guardian consent';

  @override
  String get flowPleaseHandTheDeviceToAGuardian =>
      'Please hand the device to a guardian. The guardian should read the documents below to understand the information processed, its purposes, and how to access or delete it.';

  @override
  String get flowIAmThisUserSGuardianI =>
      'I am this user’s guardian. I have read and agree to the User Agreement and Privacy Policy, and consent to processing the ward’s necessary personal information to provide these features.';

  @override
  String get flowAfterConsentPermissionsAndFeaturesRemainOptional =>
      'After consent, permissions and features remain optional. Authorization can be withdrawn or deletion requested as described in the Privacy Policy.';

  @override
  String get flowGuardianConsent => 'Guardian consent';

  @override
  String get flowGoBackOnceMoreToExit => 'Go back once more to exit';

  @override
  String get flowGettingStartedWithChiffonMai =>
      'Getting started with ChiffonMai';

  @override
  String get flowPrevious3 => 'Previous';

  @override
  String get flowStartExploring => 'Start exploring';

  @override
  String get flowNext3 => 'Next';

  @override
  String get flowWelcomeToChiffonMai => 'Welcome to ChiffonMai';

  @override
  String get flowSongsChartsScoresAndUsefulToolsAll =>
      'Songs, charts, scores and useful tools, all in one place.\nStart with one song and take your time.';

  @override
  String get flowAllSet => 'All set!';

  @override
  String get flowStartExploringWithASong => 'Start exploring with a song.';

  @override
  String flowCouldNotRequestPermissionP0(String p0) {
    return 'Could not request permission: $p0';
  }

  @override
  String get flowAgreementsAndPermissions => 'Agreements and permissions';

  @override
  String get flowAgreeToTheDocumentsFirstYouCan =>
      'Agree to the documents first. You can grant permissions now or when a feature needs them.';

  @override
  String get flowTheSystemManagesNetworkAccessBackgroundPlayback =>
      'The system manages network access, background playback and secure storage automatically; no separate authorization is needed here.';

  @override
  String get flowIHaveReadAndAgreeTo => 'I have read and agree to';

  @override
  String get flowUserAgreement => 'User Agreement';

  @override
  String get flowPrivacyPolicy => 'Privacy Policy';

  @override
  String get flowToProvideTheGameServiceWeProcess =>
      'To provide the game service, we process necessary information such as play records, scores, account and device identifiers. Multiplayer game communications are transmitted in real time solely to maintain online play.';

  @override
  String get flowUsersUnder18ShouldUseTheApp =>
      'Users under 18 should use the app under guardian guidance. Users under 14 need separate guardian consent.';

  @override
  String get flowGuardianHasGivenSeparateConsent =>
      'Guardian has given separate consent';

  @override
  String get flowUnder14GuardianMustProvideConsent =>
      'Under 14: guardian must provide consent';

  @override
  String flowP0SelectAllowFullAccessInThe(String p0) {
    return '$p0 Select “Allow full access” in the system dialog.';
  }

  @override
  String get flowAccessIsCurrentlyLimitedChangeToAllow =>
      'Access is currently limited. Change to “Allow full access” in system settings.';

  @override
  String get flowNotAuthorizedYetPermissionWillBeRequested =>
      'Not authorized yet. Permission will be requested again when needed.';

  @override
  String get flowOpenSettings => 'Open settings';

  @override
  String get flowAllow => 'Allow';

  @override
  String flowDrawFailedP0(String p0) {
    return 'Draw failed: $p0';
  }

  @override
  String get flowNumberToDraw => 'Number to draw';

  @override
  String get flowPreparing => 'Preparing…';

  @override
  String get flowStop => 'Stop!';

  @override
  String get flowStartDrawing => 'Start drawing';

  @override
  String get flowDrawResults => 'Draw results';

  @override
  String flowP0SongsDrawn(String p0) {
    return '$p0 songs drawn';
  }

  @override
  String get flowDrawHistory => 'Draw history';

  @override
  String get flowNoHistoryYet2 => 'No history yet';

  @override
  String get flowRecommendationRange => 'Recommendation range';

  @override
  String get flowPrioritizeChartsInRange => 'Prioritize charts in range';

  @override
  String get flowRecalculateByTargetRating => 'Recalculate by target Rating';

  @override
  String get flowRecalculateByConstantRange => 'Recalculate by constant range';

  @override
  String get flowCalculatingRecommendations => 'Calculating recommendations…';

  @override
  String get flowSongConstant => 'Song constant';

  @override
  String get flowSongRating => 'Song Rating';

  @override
  String get flowMultiplier => 'Multiplier';

  @override
  String get flowEnterConstantAndAchievementToCalculateSong =>
      'Enter constant and achievement to calculate · Song Rating = constant × multiplier × achievement (rounded down)';

  @override
  String get flowSongRatingConstantMultiplierAchievementRoundedDown =>
      'Song Rating = constant × multiplier × achievement (rounded down)';

  @override
  String get flowEquivalentConstants => 'Equivalent constants';

  @override
  String flowEquivalentToP0(String p0) {
    return 'Equivalent to $p0';
  }

  @override
  String get flowMultiplierTable => 'Multiplier table';

  @override
  String get flowUseTheMultiplierWhenAchievementMeetsThe =>
      'Use the multiplier when achievement meets the left-hand threshold. Values above 100.5% are treated as 100.5%.';

  @override
  String get flowAchievement4 => 'Achievement ≥';

  @override
  String get flowChooseWhereToSaveTheSupportQR =>
      'Choose where to save the support QR code';

  @override
  String get flowSupportQRCodeSaved => 'Support QR code saved';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved2 =>
      'The public directory is not writable. Saved to the app documents directory; use sharing or app file access to retrieve it.';

  @override
  String get flowChiffonMaiIsAFreeOpenSourceTool =>
      'ChiffonMai is a free, open-source tool. If it helps you, you are welcome to support its development!';

  @override
  String get flowWeChatSupportQRCode => 'WeChat support QR code';

  @override
  String get flowDownloadQRImage => 'Download QR image';

  @override
  String get flowOrSupportMeOnAfdian => 'Or support me on Afdian';

  @override
  String get flowOpenAfdian => 'Open Afdian';

  @override
  String get flowYourSupportKeepsDevelopmentAndMaintenanceGoing =>
      'Your support keeps development and maintenance going. Thank you! ❤️';

  @override
  String get flowYouAlreadyGuessedThisSong => 'You already guessed this song!';

  @override
  String get flowHowToPlay => 'How to play';

  @override
  String get flowGreenTheAttributeMatchesTheTargetExactly =>
      'Green: the attribute matches the target exactly.';

  @override
  String get flowOrangeTheAttributeIsCloseToThe =>
      'Orange: the attribute is close to the target:';

  @override
  String get flowBPMDiffersByNoMoreThan20 => 'BPM differs by no more than ±20;';

  @override
  String get flowMASTEROrReMASTERDifficultyDiffersBy =>
      'MASTER or Re:MASTER difficulty differs by no more than ±0.4;';

  @override
  String get flowVersionsAreOneGenerationApartEG =>
      'Versions are one generation apart (e.g. maimai ← maimai PLUS → maimai GreeN).';

  @override
  String get flowGrayTheAttributeIsFarFromThe =>
      'Gray: the attribute is far from the target.';

  @override
  String get flowArrows => 'Arrows:';

  @override
  String get flowTargetValueIsHigherThanYourGuess =>
      '↑ Target value is higher than your guess';

  @override
  String get flowTargetValueIsLowerThanYourGuess =>
      '↓ Target value is lower than your guess';

  @override
  String get flowDesignInspiration2 => 'Design inspiration:';

  @override
  String get flowCouldNotOpenThisLinkLinkCopied =>
      'Could not open this link. Link copied to clipboard.';

  @override
  String get flowNoSongsMatchTheseFiltersBroadenYour =>
      'No songs match these filters. Broaden your selection.';

  @override
  String get flowGameSettings => 'Game settings';

  @override
  String get flowAppliesFromTheNextGame => 'Applies from the next game';

  @override
  String get flowSettingsSavedTheyApplyFromTheNext =>
      'Settings saved. They apply from the next game.';

  @override
  String get flowLoading5 => 'Loading…';

  @override
  String get flowRules => 'Rules';

  @override
  String get flowSettings => 'Settings';

  @override
  String get flowNewQuestion => 'New question';

  @override
  String get flowYouGotIt => 'You got it!';

  @override
  String get flowThisGameSAnswer => 'This game’s answer';

  @override
  String get flowSearchTitleAliasIDAndMore =>
      'Search title, alias, ID and more';

  @override
  String get flowModeSettings => 'Mode settings';

  @override
  String get flowDestruction => 'Destruction';

  @override
  String get flowBlur => 'Blur';

  @override
  String get flowCoverArtIsTurnedIntoAPixel =>
      'Cover art is turned into a pixel mosaic at the selected destruction level. Guess from the blocks, colors and outlines. 0% shows the original; higher values create larger pixels.';

  @override
  String get flowTheOriginalCoverAppearsAfterACorrect =>
      'The original cover appears after a correct guess, giving up or the round ending.';

  @override
  String flowDestructionP0(String p0) {
    return 'Destruction $p0%';
  }

  @override
  String get flowARandomSongIsChosenFromYour =>
      'A random song is chosen from your cached charts, and a silent chart animation excerpt is played.';

  @override
  String get flowWatchNoteDensityPatternsAndReachTo =>
      'Watch note density, patterns and reach to guess the song.';

  @override
  String flowYouMayReplayTheExcerptUpTo(String p0) {
    return 'You may replay the excerpt up to $p0 times.';
  }

  @override
  String get flowTags2 => 'Tags:';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor =>
      'Shows pattern, difficulty and evaluation tags for the MASTER chart of your guessed song.';

  @override
  String get flowATagTurnsGreenWhenItMatches =>
      'A tag turns green when it matches an attribute of the target.';

  @override
  String get flowSomeSongsMayNotHaveTags => 'Some songs may not have tags.';

  @override
  String get flowNoSongsMatchBroadenTheDifficultyPool =>
      'No songs match. Broaden the difficulty pool, constant range or filters.';

  @override
  String get flowExcerptLength => 'Excerpt length';

  @override
  String get flowNoChartsAvailableCacheMaidataInThe =>
      'No charts available. Cache maidata in the chart library first.';

  @override
  String get flowExcerptFinished => 'Excerpt finished';

  @override
  String get flowLoadingAudio2 => 'Loading audio…';

  @override
  String get flowReplayExcerptAudioUnavailable =>
      'Replay excerpt (audio unavailable)';

  @override
  String get flowReplayExcerptWithAudio => 'Replay excerpt with audio';

  @override
  String get flowReplayExcerpt => 'Replay excerpt';

  @override
  String get flowPlayExcerpt => 'Play excerpt';

  @override
  String flowReplayP0(String p0) {
    return 'Replay$p0';
  }

  @override
  String get flowTheCoverFlashesBrieflyAtTheStart =>
      'The cover flashes briefly at the start, then disappears. Adjust the duration in settings.';

  @override
  String get flowRememberTheCoverThenSearchBelowAnd =>
      'Remember the cover, then search below and guess the song.';

  @override
  String get flowFlashDuration => 'Flash duration';

  @override
  String get flowPlaybackLength => 'Playback length';

  @override
  String flowAudioPlaybackFailedP0(String p0) {
    return 'Audio playback failed: $p0';
  }

  @override
  String get flowTheCoverIsSplitIntoTilesAt =>
      'The cover is split into tiles. At intervals, random batches are revealed and stay visible, making the image progressively clearer.';

  @override
  String get flowEarlierGuessesImproveYourScoreAverageTime =>
      'Earlier guesses improve your score (average time). You can also wait until more tiles are visible.';

  @override
  String get flowTileCount => 'Tile count';

  @override
  String get flowRevealInterval => 'Reveal interval';

  @override
  String flowP0RevealedP1P2Tiles(String p0, String p1, String p2) {
    return '$p0% revealed ($p1 / $p2 tiles)';
  }

  @override
  String get flowRevealPaused => 'Reveal paused';

  @override
  String flowNextRevealInP0S(String p0) {
    return 'Next reveal in ${p0}s';
  }

  @override
  String get flowResumeReveal => 'Resume reveal';

  @override
  String get flowPauseReveal => 'Pause reveal';

  @override
  String get flowCouldNotReloadSongsCheckYourConnection =>
      'Could not reload songs. Check your connection and retry.';

  @override
  String get flowFetchingSongs => 'Fetching songs…';

  @override
  String get flowReloadSongs => 'Reload songs';

  @override
  String get flowOpenSettings2 => 'Open settings';

  @override
  String get flowSettingsSavedLocally => 'Settings saved locally';

  @override
  String get flowChangesSaveAutomaticallyAndApplyToThe =>
      'Changes save automatically and apply to the next game.';

  @override
  String get flowSongExcerptsReverseAndSpeedPitch =>
      'Song excerpts, reverse and speed / pitch';

  @override
  String get flowChartExcerpt => 'Chart excerpt';

  @override
  String get flowCoverModes => 'Cover modes';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate =>
      '0% shows the original; higher values create larger pixels.';

  @override
  String get flowRevealLetters => 'Reveal letters';

  @override
  String get flowDefaultSettingsRestored => 'Default settings restored';

  @override
  String get flowEnterOneCharacter => 'Enter one character!';

  @override
  String get flowEnterASongTitle => 'Enter a song title!';

  @override
  String get flowCorrect => 'Correct!';

  @override
  String flowGuessP0(String p0) {
    return 'Guess #$p0';
  }

  @override
  String flow1TheGameRandomlySelectsP0Songs(String p0) {
    return '1. The game randomly selects $p0 songs from the maimai library.';
  }

  @override
  String get flow2SendXWhereXIsOne =>
      '2. Send “开字母 X”, where X is one Chinese or Japanese character, number or symbol.';

  @override
  String get flow3IfATitleContainsThatCharacter =>
      '3. If a title contains that character, its positions are revealed.';

  @override
  String get flow4IfNoTitleContainsItNo =>
      '4. If no title contains it, no clue is shown.';

  @override
  String get flow5UseTheRevealedCharactersToInfer =>
      '5. Use the revealed characters to infer the title, then send “回答 title/alias”.';

  @override
  String get flow6GuessEverySongOrSurrenderTo =>
      '6. Guess every song or surrender to end the game and see the results.';

  @override
  String get flowSongsPerGame => 'Songs per game';

  @override
  String get flowNonEnglishCharacterFilterPercentage =>
      'Non-English character filter percentage';

  @override
  String get flowEnterOneCharacter2 => 'Enter one character';

  @override
  String get flowSurrender => 'Surrender';

  @override
  String get flowNewGame => 'New game';

  @override
  String get flowGuessHistory => 'Guess history';

  @override
  String get flowBlueGateDetails => 'Blue Gate details';

  @override
  String get flowWhiteGateDetails => 'White Gate details';

  @override
  String get flowPurpleGateDetails => 'Purple Gate details';

  @override
  String get flowBlackGateDetails => 'Black Gate details';

  @override
  String get flowYellowGateDetails => 'Yellow Gate details';

  @override
  String get flowRedGateDetails => 'Red Gate details';

  @override
  String get flowPrismTowerDetails => 'Prism Tower details';

  @override
  String get flowGlitchGateDetails => 'Glitch Gate details';

  @override
  String get flowHopeGateDetails => 'Hope Gate details';

  @override
  String get flowFinalPhaseDetails => 'Final Phase details';

  @override
  String get flowNoActiveChallengesCheckTheScheduleBelow =>
      'No active challenges. Check the schedule below.';

  @override
  String get flowCurrentPhase => 'Current phase';

  @override
  String get flowLIFEPhase1Phase2 => 'LIFE phase 1 / phase 2';

  @override
  String get flowInProgress => 'In progress';

  @override
  String flowPhase1P0(String p0) {
    return 'Phase 1 $p0';
  }

  @override
  String flowPhase2P0(String p0) {
    return 'Phase 2 $p0';
  }

  @override
  String flowMarkedP0P1(String p0, String p1) {
    return 'Marked $p0 / $p1';
  }

  @override
  String get flowTapASongToToggleCompletion =>
      'Tap a song to toggle completion';

  @override
  String get flowEnableMarkingThenTapSongsToRecord =>
      'Enable marking, then tap songs to record completion';

  @override
  String get flowMarkingMode => 'Marking mode';

  @override
  String get flowCouldNotLoadTheGuideTryAgain =>
      'Could not load the guide. Try again later.';

  @override
  String flowSongIDP02(String p0) {
    return 'Song ID $p0';
  }

  @override
  String get flowRefreshTheLibraryToShowSongInformation =>
      'Refresh the library to show song information';

  @override
  String get flowRefreshGateList => 'Refresh gate list';

  @override
  String get flowEnterYourLXNSPersonalAPIKey =>
      'Enter your LXNS personal API key';

  @override
  String get flowLXNSAPIKeySaved => 'LXNS API key saved';

  @override
  String get flowSavedLocallyItWillBeLinkedTo =>
      'Saved locally; it will be linked to the cloud during sync';

  @override
  String get flowSetYourLXNSPersonalAPIKeyFirst =>
      'Set your LXNS personal API key first';

  @override
  String get flowHowDoIGetIt => 'How do I get it?';

  @override
  String get flowThenScrollToTheBottomToFind =>
      ', then scroll to the bottom to find your personal API key.';

  @override
  String get flowLXNSAPIKeyIsSet => 'LXNS API key is set';

  @override
  String flowClosesAutomaticallyInP0S(String p0) {
    return 'Closes automatically in ${p0}s';
  }

  @override
  String flowP0GotItP1Points(String p0, String p1) {
    return '🎉 $p0 got it! +$p1 points';
  }

  @override
  String get flowNoConfirmationReceivedCheckYourConnectionAnd =>
      'No confirmation received. Check your connection and retry.';

  @override
  String get flowTimingStartsWhenTheRoundBeginsNot =>
      'Timing starts when the round begins, not when the previous song is guessed. Later songs naturally take longer than the first.';

  @override
  String get flowConfirmLeaving => 'Confirm leaving';

  @override
  String get flowLeaveThisRoom => 'Leave this room?';

  @override
  String get flowLeave => 'Leave';

  @override
  String get flowNoConfirmationOfLeavingReceivedPleaseRetry =>
      'No confirmation of leaving received. Please retry.';

  @override
  String flowCouldNotLeaveRoomP0(String p0) {
    return 'Could not leave room: $p0';
  }

  @override
  String get flowRestoringGame => 'Restoring game…';

  @override
  String get flowWaitingForTheGameToStart => 'Waiting for the game to start…';

  @override
  String get flowGameOver => 'Game over!';

  @override
  String get flowPlayAgain => 'Play again';

  @override
  String get flowRoundOver => 'Round over!';

  @override
  String get flowNextRound2 => 'Next round';

  @override
  String get flowYouSurrenderedWaitingForOtherPlayers =>
      'You surrendered. Waiting for other players…';

  @override
  String flowTimeRemainingP0S(String p0) {
    return '⏱️ Time remaining: ${p0}s';
  }

  @override
  String get flowWaitingForServerConfirmation =>
      'Waiting for server confirmation…';

  @override
  String get flowTimeIsUpWaitingForRoundResults =>
      'Time is up. Waiting for round results…';

  @override
  String get flowSearchSongIDBPMChartDesignerAnd =>
      'Search song, ID, BPM, chart designer and more';

  @override
  String get flowTimeLeft => 'Time left';

  @override
  String get flowGuessesLeft => 'Guesses left';

  @override
  String flowP0Points(String p0) {
    return '$p0 points';
  }

  @override
  String flowThisSongHasP0Aliases(String p0) {
    return 'This song has $p0 aliases';
  }

  @override
  String get flowNoAliasesAvailableGuessFromTheSong =>
      'No aliases available. Guess from the song information.';

  @override
  String get flowThisRoundHasEnded => 'This round has ended';

  @override
  String flowP0P1SongsRemaining(String p0, String p1) {
    return '$p0 / $p1 songs remaining';
  }

  @override
  String get flowRevealed => 'Revealed:';

  @override
  String get flowCharacters => 'characters';

  @override
  String get flowPreparingCoverClue => 'Preparing cover clue…';

  @override
  String get flowWaitingForPlayersToLoadTheCover =>
      'Waiting for players to load the cover…';

  @override
  String get flowFlashingRememberIt => 'Flashing… Remember it!';

  @override
  String get flowTheCoverIsHiddenGuessFromMemory =>
      'The cover is hidden. Guess from memory.';

  @override
  String flowP0P1TilesRevealedP2(String p0, String p1, String p2) {
    return '$p0 / $p1 tiles revealed$p2';
  }

  @override
  String get flowPaused2 => ' (paused)';

  @override
  String get flowPreparingChartExcerpt => 'Preparing chart excerpt…';

  @override
  String get flowNoReplaysLeft => 'No replays left';

  @override
  String get flowGuessTheSongFromThisCoverFragment =>
      'Guess the song from this cover fragment';

  @override
  String get flowOriginalCover => 'Original cover';

  @override
  String flowBlurP0(String p0) {
    return 'Blur: $p0%';
  }

  @override
  String get flowSongExcerpt => 'Song excerpt';

  @override
  String get flowTheGameHasEnded => 'The game has ended';

  @override
  String get flowReplay => 'Replay';

  @override
  String get flowPlaySongExcerpt => 'Play song excerpt';

  @override
  String get flowMultiplayerRoom => 'Multiplayer room';

  @override
  String flowP0RoundP1P2(String p0, String p1, String p2) {
    return '$p0 · Round $p1/$p2';
  }

  @override
  String get flowReconnect => 'Reconnect';

  @override
  String flowCouldNotCreateRoomP0(String p0) {
    return 'Could not create room: $p0';
  }

  @override
  String flowCouldNotJoinRoomP0(String p0) {
    return 'Could not join room: $p0';
  }

  @override
  String flowYouAreStillInRoomP0(String p0) {
    return 'You are still in room $p0';
  }

  @override
  String flowP0P1PlayersTapToReturn(String p0, String p1) {
    return '$p0 · $p1 players · Tap to return';
  }

  @override
  String get flowCreateRoom => 'Create room';

  @override
  String get flowChooseAModeAndRulesThenInvite =>
      'Choose a mode and rules, then invite friends';

  @override
  String get flowJoinRoom => 'Join room';

  @override
  String get flowEnterARoomCodeSharedByA =>
      'Enter a room code shared by a friend';

  @override
  String get flowCouldNotCreateRoom => 'Could not create room';

  @override
  String flowCouldNotCreateRoomP02(String p0) {
    return 'Could not create room: $p0';
  }

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate2 =>
      '0% shows the original; higher values create larger pixels. All players use the same destruction level.';

  @override
  String get flowSpeedPitchMultiplier => 'Speed / pitch multiplier';

  @override
  String get flowRestoreDefaults => 'Restore defaults';

  @override
  String get flowGameMode => 'Game mode';

  @override
  String get flowMaximumPlayers => 'Maximum players';

  @override
  String flowP0Settings(String p0) {
    return '$p0 settings';
  }

  @override
  String get flowEnterRoomCode => 'Enter room code';

  @override
  String get flowEnterA6DigitCodeOrThe =>
      'Enter a 6-digit code or the full room ID';

  @override
  String get flowPasteRoomCode => 'Paste room code';

  @override
  String get flowHowDoIGetARoomCode => 'How do I get a room code?';

  @override
  String get flowUpdateDownloadedInstallWhenConvenient =>
      'Update downloaded. Install when convenient.';

  @override
  String get flowViewInstallation => 'View installation';

  @override
  String get flowView => 'View';

  @override
  String get flowPreparingTheUpdateInTheBackgroundYou =>
      'Preparing the update in the background. You can keep using the app.';

  @override
  String flowExportingP0InTheBackgroundYouCan(String p0) {
    return 'Exporting $p0 in the background. You can keep using the app.';
  }

  @override
  String flowCouldNotExportP0PleaseRetry(String p0) {
    return 'Could not export $p0. Please retry.';
  }

  @override
  String flowCouldNotExportP0CheckStoragePermission(String p0) {
    return 'Could not export $p0. Check storage permission and retry.';
  }

  @override
  String flowP0Exported(String p0) {
    return '$p0 exported';
  }

  @override
  String flowCouldNotExportP0P1(String p0, String p1) {
    return 'Could not export $p0: $p1';
  }

  @override
  String get flowCouldNotLoadAppearanceReopenThisPage =>
      'Could not load appearance. Reopen this page.';

  @override
  String get flowChiffonMaiClosedUnexpectedlyLastTime =>
      'ChiffonMai closed unexpectedly last time';

  @override
  String flowReasonP0AutomaticLogExportFailedExport(String p0) {
    return 'Reason: $p0.\nAutomatic log export failed. Export manually from Me → Export logs.';
  }

  @override
  String get flowChiffonChuAnAllInOneCHUNITHMTool =>
      'ChiffonChu, an all-in-one CHUNITHM tool';

  @override
  String get flowWebMiniGamesFromTheAWMCCommunity =>
      'Web mini-games from the AWMC community, continuously improving!';

  @override
  String get flowAnInnovativeRhythmGameInspiredByRailways =>
      'An innovative rhythm game inspired by railways';

  @override
  String get flowAnOfflineMaimaiLibraryWithQuickCover =>
      'An offline maimai library with quick cover-based lookup';

  @override
  String flowRefusedRequestToANonGatewayAddress(String p0) {
    return 'Refused request to a non-gateway address: $p0';
  }

  @override
  String flowUnsupportedMethodP0(String p0) {
    return 'Unsupported method: $p0';
  }

  @override
  String flowRequestTimedOutP0S(String p0) {
    return 'Request timed out (${p0}s)';
  }

  @override
  String flowCouldNotScheduleWriteP0(String p0) {
    return 'Could not schedule write: $p0';
  }

  @override
  String flowMusicListMustContain14EntriesCurrently(String p0) {
    return 'musicList must contain 1–4 entries (currently $p0)';
  }

  @override
  String get flowOnlyChargeId235IsSupported =>
      'Only chargeId 2 / 3 / 5 is supported (2× / 3× / 5× tickets)';

  @override
  String flowOrderP0(String p0) {
    return 'Order: $p0';
  }

  @override
  String flowSourceP0ExportedP1GeneratedByChiffonMai(
      String p0, String p1, String p2) {
    return 'Source: $p0\nExported: $p1\nGenerated by ChiffonMai\nCommunity group: $p2';
  }

  @override
  String get flowCouldNotCreateRoomEnvironmentIDIs =>
      'Could not create room: environment ID is not set';

  @override
  String get flowCouldNotCreateRoomNotSignedIn =>
      'Could not create room: not signed in';

  @override
  String flowCouldNotJoinRoomP02(String p0) {
    return 'Could not join room: $p0';
  }

  @override
  String flowCouldNotRejoinRoomP0(String p0) {
    return 'Could not rejoin room: $p0';
  }

  @override
  String flowCouldNotChangeReadyStatusP0(String p0) {
    return 'Could not change ready status: $p0';
  }

  @override
  String flowCouldNotChangeSurrenderStatusP0(String p0) {
    return 'Could not change surrender status: $p0';
  }

  @override
  String flowCouldNotStartGameP0(String p0) {
    return 'Could not start game: $p0';
  }

  @override
  String flowCouldNotStartNextRoundP0(String p0) {
    return 'Could not start next round: $p0';
  }

  @override
  String flowCouldNotSubmitGuessP0(String p0) {
    return 'Could not submit guess: $p0';
  }

  @override
  String flowCouldNotRevealLetterP0(String p0) {
    return 'Could not reveal letter: $p0';
  }

  @override
  String flowCouldNotSurrenderP0(String p0) {
    return 'Could not surrender: $p0';
  }

  @override
  String flowCouldNotUploadSongsP0(String p0) {
    return 'Could not upload songs: $p0';
  }

  @override
  String flowCouldNotGetSongCountP0(String p0) {
    return 'Could not get song count: $p0';
  }

  @override
  String flowCouldNotParseMessageP0(String p0) {
    return 'Could not parse message: $p0';
  }

  @override
  String get flowYellow => 'Yellow';

  @override
  String get flowCurrentSaveLocation => 'Current save location';

  @override
  String get flowUseTheDefaultPublicDirectoryOrChoose =>
      'Use the default public directory or choose a custom folder.';

  @override
  String flowCouldNotChooseSaveFolderP0(String p0) {
    return 'Could not choose save folder: $p0';
  }

  @override
  String get flowChooseAnotherFolder => 'Choose another folder';

  @override
  String get flowUseDefaultPath => 'Use default path';

  @override
  String get flowThisFolderIsNotWritableChooseAnother =>
      'This folder is not writable. Choose another folder.';

  @override
  String get flowCannotImport => 'Cannot import';

  @override
  String flowImportCompleteP0(String p0) {
    return 'Import complete: $p0';
  }

  @override
  String flowP0FoldersP1Charts(String p0, String p1) {
    return '$p0 folders, $p1 charts';
  }

  @override
  String flowP0P1Charts2(String p0, String p1) {
    return '· $p0 ($p1 charts)';
  }

  @override
  String flowP0MoreFolders(String p0) {
    return '· $p0 more folders…';
  }

  @override
  String get flowMergeWithExistingFolders => 'Merge with existing folders';

  @override
  String get flowFoldersWithTheSameNameAreMerged =>
      'Folders with the same name are merged; duplicate charts are skipped.';

  @override
  String get flowReplaceExistingFavorites => 'Replace existing favorites';

  @override
  String get flowClearAllCurrentFoldersThenImportThe =>
      'Clear all current folders, then import the file.';

  @override
  String get flowImport => 'Import';

  @override
  String flowP0Loading(String p0) {
    return '$p0, loading';
  }

  @override
  String get flowUnavailable => 'Unavailable';

  @override
  String get flowIncrease => ', increase';

  @override
  String get flowDecrease => ', decrease';

  @override
  String flowP0P1P2BeijingTime(String p0, String p1, String p2) {
    return '$p0-$p1-$p2 · Beijing time';
  }

  @override
  String get flowDoNotShowThisAnnouncementAgain =>
      'Do not show this announcement again';

  @override
  String get flowCouldNotLoadImageTapToRetry =>
      'Could not load image. Tap to retry.';

  @override
  String get flowEnlargeAnnouncementImage => 'Enlarge announcement image';

  @override
  String flowDecreaseP0ByOne(String p0) {
    return 'Decrease $p0 by one';
  }

  @override
  String flowIncreaseP0ByOne(String p0) {
    return 'Increase $p0 by one';
  }

  @override
  String get flowInstallUpdate => 'Install update';

  @override
  String get flowDownloadUpdateInBackground => 'Download update in background';

  @override
  String get flowNoDownloadTask => 'No download task';

  @override
  String get flowKeepUsingTheApp => 'Keep using the app';

  @override
  String get flowCancelInstallationTask => 'Cancel installation task';

  @override
  String get flowCancelDownload => 'Cancel download';

  @override
  String get flowDownloadAgain => 'Download again';

  @override
  String get flowAllowInstallation => 'Allow installation';

  @override
  String get flowInstallNow => 'Install now';

  @override
  String get flowCalculatingCacheSize => 'Calculating cache size…';

  @override
  String flowTotalUsageP0(String p0) {
    return 'Total usage $p0';
  }

  @override
  String get flowAudioCache => 'Audio cache';

  @override
  String get flowCalculating3 => 'Calculating…';

  @override
  String flowP0FilesTotalP1(String p0, String p1) {
    return '$p0 files\nTotal $p1';
  }

  @override
  String get flowPVCache => 'PV cache';

  @override
  String get flowMaidataCache => 'maidata cache';

  @override
  String get flowReloadBaseMaidata => 'Reload base maidata';

  @override
  String flowCleaningP0(String p0) {
    return 'Cleaning… $p0%';
  }

  @override
  String get flowCleaning => 'Cleaning…';

  @override
  String get flowClear2 => 'Clear';

  @override
  String flowNoteSpeedP0P1(String p0, String p1) {
    return 'Note speed $p0 · $p1';
  }

  @override
  String get flowNoteSpeed => 'Note speed';

  @override
  String get flowMirror => 'Mirror';

  @override
  String get flowRandomDifficultyPool => 'Random difficulty pool';

  @override
  String flowP0ConstantP12(String p0, String p1) {
    return '$p0 constant $p1';
  }

  @override
  String get flowUTAGE2 => 'UTAGE';

  @override
  String get flowResetTodaySStatistics => 'Reset today’s statistics?';

  @override
  String get flowClearTodaySCorrectIncorrectGuessesTimes =>
      'Clear today’s correct / incorrect guesses, times and win streaks for this mode.';

  @override
  String flowP0SRemaining(String p0) {
    return '${p0}s remaining';
  }

  @override
  String get flowResetTodaySStatistics2 => 'Reset today’s statistics';

  @override
  String get flowResetStatistics => 'Reset statistics';

  @override
  String get flowThisGameHasEnded => 'This game has ended';

  @override
  String flowAnswerP0(String p0) {
    return 'Answer: $p0';
  }

  @override
  String get flowOriginalAudioExcerpt => 'Original audio excerpt';

  @override
  String get flowPreparingOriginalAudio => 'Preparing original audio…';

  @override
  String get flowTheSameExcerptPlayedForwardAtOriginal =>
      'The same excerpt, played forward at original speed';

  @override
  String get flowSelectAll2 => 'Select all';

  @override
  String get flowCurrentAll => 'Current: all';

  @override
  String flowP0SelectedNoneMeansAll(String p0) {
    return '$p0 selected; none means all';
  }

  @override
  String get flowMASTERTags => 'MASTER tags';

  @override
  String flowGuessHistoryP0(String p0) {
    return 'Guess history ($p0)';
  }

  @override
  String get flowOldestFirst => 'Oldest first';

  @override
  String get flowNewestFirst => 'Newest first';

  @override
  String get flowCouldNotOpenTheGuideSourceLink =>
      'Could not open the guide source. Link copied to clipboard.';

  @override
  String get flowDataSourceAWMCKALEIDXSCOPE => 'Data source: AWMC KALEIDXSCOPE';

  @override
  String get flowRoom => 'Room ';

  @override
  String flowP0PlayersP1(String p0, String p1) {
    return ' · $p0 players · $p1';
  }

  @override
  String get flowCopyRoomCode => 'Copy room code';

  @override
  String get flowRoomCodeCopied => 'Room code copied';

  @override
  String get flowInviteFriendsToGuessSongsTogether =>
      'Invite friends to guess songs together';

  @override
  String get flowRoomCode => 'Room code';

  @override
  String get flowRoomCodeCopiedSendItToA =>
      'Room code copied. Send it to a friend to invite them.';

  @override
  String get flowPlayerSlots => 'Player slots';

  @override
  String flowP0P1PlayersP2(String p0, String p1, String p2) {
    return '$p0 / $p1 players$p2';
  }

  @override
  String flowP0Ready(String p0) {
    return ' · $p0 ready';
  }

  @override
  String get flowWaitingForPlayers => 'Waiting for players';

  @override
  String get flowMe2 => ' · Me';

  @override
  String get flowNotReady => 'Not ready';

  @override
  String get flowReady => 'Ready';

  @override
  String get flowStartGame => 'Start game';

  @override
  String get flowDecreaseCount2 => 'Decrease count';

  @override
  String get flowIncreaseCount2 => 'Increase count';

  @override
  String get flowConnectionRestored => 'Connection restored';

  @override
  String get flowOfflineShowingCachedData => 'Offline – showing cached data';

  @override
  String flowDrawingP0SongsTapStopToReveal(String p0) {
    return 'Drawing $p0 songs · Tap “Stop!” to reveal';
  }

  @override
  String flowCardP0WaitingToReveal(String p0) {
    return 'Card $p0, waiting to reveal';
  }

  @override
  String get flowCyclingCoverArt => 'Cycling cover art…';

  @override
  String flowSongP0WaitingForYouToStop(String p0) {
    return 'Song $p0 · Waiting for you to stop';
  }

  @override
  String get flowChiffonMaiIsAnAllInOneMobile =>
      'ChiffonMai is an all-in-one mobile tool for maimai DX 2026 players, bringing together song lookup, score statistics, Rating calculators and chart recommendations to support your play.';

  @override
  String get flowProvidedTheBackgroundArtworkAndTheLovely =>
      'Provided the background artwork and the lovely Chiffon fox';

  @override
  String get flowContributedValuableIdeasForPersonalizedChartRecommendations =>
      'Contributed valuable ideas for personalized chart recommendations';

  @override
  String get flowContributedValuableFeedbackOnPageDesign =>
      'Contributed valuable feedback on page design';

  @override
  String get flowProvidedPersonalPlayDataForDevelopmentAnd =>
      'Provided personal play data for development and testing';

  @override
  String get flowProposedChiffonMaiAndHelpedSparkTheProject =>
      'Proposed ChiffonMai and helped spark the project';

  @override
  String get flowContributedManySuggestionsOnInterfaceDetailsAnd =>
      'Contributed many suggestions on interface details and interaction';

  @override
  String get flowProvidedTechnicalAndFinancialSupportThatGreatly =>
      'Provided technical and financial support that greatly helped the project';

  @override
  String get flowEveryoneInTheChiffonMaiCommunityGroup =>
      'Everyone in the ChiffonMai community group';

  @override
  String get flowContributedManySuggestionsAndFeedbackDuringDevelopment =>
      'Contributed many suggestions and feedback during development';

  @override
  String get flowDivingFish => 'Diving-Fish';

  @override
  String get flowProvidesSongAndPlayerScoreDatabases =>
      'Provides song and player score databases';

  @override
  String get flowProvidesChartTagAndAliasDatabases =>
      'Provides chart tag and alias databases';

  @override
  String get flowProvidesAnAliasDatabase => 'Provides an alias database';

  @override
  String get flowLXNS => 'LXNS';

  @override
  String get flowProvidesCollectiblesAudioSongAndPlayerScore =>
      'Provides collectibles, audio, song and player score data';

  @override
  String get flowProvidesChartConversionSupport =>
      'Provides chart conversion support';

  @override
  String get flowProvidesMaimaiServerStatus => 'Provides maimai server status';

  @override
  String get flowProvidesDivingFishLXNSSyncAndFinancial =>
      'Provides Diving-Fish / LXNS sync and financial support';

  @override
  String get flowProvidesScoreSyncToDivingFishAnd =>
      'Provides score sync to Diving-Fish and LXNS';

  @override
  String get flowProvidesScoreSyncToLXNS => 'Provides score sync to LXNS';

  @override
  String get flowProvidesASongDatabase => 'Provides a song database';

  @override
  String get flowProvidesWorldwideArcadeData =>
      'Provides worldwide arcade data';

  @override
  String get flowProvidesHighResolutionVersionArtwork =>
      'Provides high-resolution version artwork';

  @override
  String get flowThankYouForYourDonations => 'Thank you for your donations';

  @override
  String get flowMaintainer => 'Maintainer';

  @override
  String get flowTheDeveloperBehindChiffonMai =>
      'The developer behind ChiffonMai.';

  @override
  String get flowSpecialThanks => 'Special thanks';

  @override
  String get flowThanksToEveryoneWhoHelpedInNo =>
      'Thanks to everyone who helped, in no particular order.';

  @override
  String get flowBilibili => 'Bilibili';

  @override
  String get flowEmail => 'Email';

  @override
  String get flowSignInFailedTryAgainLater =>
      'Sign-in failed. Try again later.';

  @override
  String get flowEnterTargetAchievement => 'Enter target achievement';

  @override
  String get flowInvalidAchievementEnterANumberSuchAs =>
      'Invalid achievement. Enter a number such as 100.5000.';

  @override
  String get flowEnterAchievementBetween0And101 =>
      'Enter achievement between 0 and 101';

  @override
  String get flow50PointLoss2 => '50-point loss';

  @override
  String get flow100PointLoss2 => '100-point loss';

  @override
  String get flowBase100Bonus100 => 'Base 100% · Bonus 100%';

  @override
  String get flowPERFECT50PointLoss => 'PERFECT · 50-point loss';

  @override
  String get flowBase100Bonus75 => 'Base 100% · Bonus 75%';

  @override
  String get flowPERFECT100PointLoss => 'PERFECT · 100-point loss';

  @override
  String get flowBase100Bonus50 => 'Base 100% · Bonus 50%';

  @override
  String get flowBase80Bonus40 => 'Base 80% · Bonus 40%';

  @override
  String get flowBase60Bonus40 => 'Base 60% · Bonus 40%';

  @override
  String get flowBase50Bonus40 => 'Base 50% · Bonus 40%';

  @override
  String get flowBase40Bonus30 => 'Base 40% · Bonus 30%';

  @override
  String get flowBase0Bonus0 => 'Base 0% · Bonus 0%';

  @override
  String get flowNoLoss => 'No loss';

  @override
  String get flowStayHome => 'Stay home';

  @override
  String get flowScoreTargetsBREAKDistribution =>
      'Score targets / BREAK distribution';

  @override
  String get flowRatingTargets => 'Rating targets';

  @override
  String get flowCalculationMode => 'Calculation mode';

  @override
  String get flowByAchievement => 'By achievement';

  @override
  String get flowByRating => 'By Rating';

  @override
  String get flowResult2 => 'Result';

  @override
  String get flowTargetRating2 => 'Target Rating';

  @override
  String get flowEG143 => 'e.g. 14.3';

  @override
  String get flowEG1005667 => 'e.g. 100.5667';

  @override
  String get flowEG321 => 'e.g. 321';

  @override
  String flowAchievementP02(String p0) {
    return 'Achievement $p0';
  }

  @override
  String get flowNoteDistributionEditable => 'Note distribution (editable)';

  @override
  String get flowScoreLossDetails => 'Score / loss details';

  @override
  String flowP0P1P2WeekdayP3(String p0, String p1, String p2, String p3) {
    return '$p0-$p1-$p2, weekday $p3';
  }

  @override
  String get flowExporting3 => 'Exporting…';

  @override
  String get flowExportBackupFile => 'Export backup file';

  @override
  String get flowRestoringData => 'Restoring data…';

  @override
  String get flowImporting => 'Importing…';

  @override
  String get flowChooseBackupFile => 'Choose backup file';

  @override
  String get flowImportClearsAllCurrentLocalDataBefore =>
      '⚠ Import clears all current local data before restoring the backup.\nItems absent from the backup, including caches, are also removed.\nDo not leave this page during restoration.';

  @override
  String get flowBackupFile => 'Backup file';

  @override
  String get flowFindTheFileInDownloadsChiffonMaiIn =>
      'Find the file in Downloads/ChiffonMai/备份 in your file manager.';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved3 =>
      'The public directory is not writable. Saved to app documents.';

  @override
  String get flowRename => 'Rename';

  @override
  String get flowConstantHighLow => 'Constant (high → low)';

  @override
  String get flowConstantLowHigh => 'Constant (low → high)';

  @override
  String get flowAddedNewOld => 'Added (new → old)';

  @override
  String get flowAddedOldNew => 'Added (old → new)';

  @override
  String get flowSongTitleAZ => 'Song title (A–Z)';

  @override
  String get flowSignOut2 => 'Sign out';

  @override
  String get flowGetAnImportTokenForScoreSync =>
      'Get an ImportToken for score sync';

  @override
  String get flowOnlineLinksAreUnavailableShowingLocallyCached =>
      'Online links are unavailable. Showing locally cached links.';

  @override
  String flowCouldNotGenerateRecommendationsP0(String p0) {
    return 'Could not generate recommendations: $p0';
  }

  @override
  String get flowMixed => 'Mixed';

  @override
  String flowSourceRatingP0DiffersFromTheLocally(String p0) {
    return 'Source Rating $p0 differs from the locally recalculated value. The recalculated value is used.';
  }

  @override
  String flowP0ScoresAreMissingFromTheSong(String p0) {
    return '$p0 scores are missing from the song library and treated as older songs. Refresh the library for better accuracy.';
  }

  @override
  String flowP0P12(String p0, String p1) {
    return '$p0/$p1';
  }

  @override
  String flowP0Arcades(String p0) {
    return '$p0 arcades';
  }

  @override
  String flowP0ArcadesTotal(String p0) {
    return '$p0 arcades total';
  }

  @override
  String get flowDivingFishSignInFailedTryAgain =>
      'Diving-Fish sign-in failed. Try again later.';

  @override
  String get flowUserAgreement2 => 'User Agreement';

  @override
  String get flowPrivacyPolicy2 => 'Privacy Policy';

  @override
  String flowLocalQuotesP0(String p0) {
    return 'Local quotes $p0';
  }

  @override
  String flowCloudQuotesP0(String p0) {
    return 'Cloud quotes $p0';
  }

  @override
  String get flowQuoteCannotBeEmpty => 'Quote cannot be empty';

  @override
  String get flowServerStatusIsTemporarilyUnavailable =>
      'Server status is temporarily unavailable';

  @override
  String get flowCouldNotLoadServerStatus => 'Could not load server status';

  @override
  String get flowHealthy => 'Healthy';

  @override
  String get flowUnhealthy => 'Unhealthy';

  @override
  String get flowLatency => 'Latency --';

  @override
  String flowLatencyP0Ms(String p0) {
    return 'Latency $p0 ms';
  }

  @override
  String flowHealthyP0(String p0) {
    return 'Healthy $p0';
  }

  @override
  String flowIssuesP0(String p0) {
    return 'Issues $p0';
  }

  @override
  String get flowNoSongsAddedYetUseAddTo =>
      'No songs added yet.\nUse “Add to play next” in song details or the music player.';

  @override
  String get flowProfileFavoriteFeaturesSyncAndServerStatus =>
      'Profile, favorite features, sync and server status';

  @override
  String get flowFindSongsInspectChartsAndBrowseCollectibles =>
      'Find songs, inspect charts and browse collectibles';

  @override
  String get flowBest50RatingToolsAndLeaderboards =>
      'Best50, Rating tools and leaderboards';

  @override
  String get flowFindArcadesPlayGuessingGamesAndListen =>
      'Find arcades, play guessing games and listen to music';

  @override
  String get flowAccountsDataRefreshAndSettings =>
      'Accounts, data refresh and settings';

  @override
  String get flowOpenFromMeOrTapYourRating =>
      'Open from Me or tap your Rating on Home';

  @override
  String get flowSyncScores => 'Sync scores';

  @override
  String get flowDivingFishLXNSAndAWMCNETLink =>
      'Diving-Fish, LXNS and AWMC NET; link an account first';

  @override
  String get flowRunsThroughoutTheDayWhenEnabledCheck =>
      'Runs throughout the day when enabled; check results on Home';

  @override
  String get flowTheme => 'Theme';

  @override
  String get flowLightDarkBlackOrSystemThemePlus =>
      'Light, dark, black or system theme, plus custom theme colors';

  @override
  String get flowCustomBackgroundImagesDecorationsAndOverlays =>
      'Custom background images, decorations and overlays';

  @override
  String get flowNavigation => 'Navigation';

  @override
  String get flowThreeNavigationStylesWithOptionalAnimationAnd =>
      'Three navigation styles, with optional animation and swipe switching';

  @override
  String get flowConfetti => 'Confetti';

  @override
  String get flowCelebrateASuccessfulRefreshOrSyncWith =>
      'Celebrate a successful refresh or sync with confetti';

  @override
  String get flowEverythingIsReadyRememberToRefreshData =>
      'Everything is ready. Remember to refresh data first!';

  @override
  String get flowChecking => 'Checking';

  @override
  String get flowAllowed => 'Allowed';

  @override
  String get flowLimitedAccess => 'Limited access';

  @override
  String get flowOpenSettings3 => 'Open settings';

  @override
  String get flowNotAllowed => 'Not allowed';

  @override
  String get flowIHaveReadAndAgreeToThe =>
      'I have read and agree to the User Agreement and Privacy Policy';

  @override
  String get flowChooseYourFiltersThenDrawSomeSongs =>
      'Choose your filters, then draw some songs';

  @override
  String get flowEnterAnIntegerFrom2To100 => 'Enter an integer from 2 to 100';

  @override
  String get flowDrawCountMustBeBetween2And =>
      'Draw count must be between 2 and 100';

  @override
  String get flowNoMatchingSongsAdjustTheFilters =>
      'No matching songs. Adjust the filters.';

  @override
  String get flowSongs3 => ' songs';

  @override
  String get flowAllVersions => 'All versions';

  @override
  String flowP0VersionsSelected(String p0) {
    return '$p0 versions selected';
  }

  @override
  String get flowTypeFilter => 'Type filter';

  @override
  String get flowAllTypes => 'All types';

  @override
  String flowP0TypesSelected(String p0) {
    return '$p0 types selected';
  }

  @override
  String get flowConstantRange => 'Constant range';

  @override
  String get flowAdvancedMASTER => 'Advanced MASTER';

  @override
  String get flowExpertMASTER => 'Expert MASTER';

  @override
  String flowCouldNotFetchRecommendationsP0(String p0) {
    return 'Could not fetch recommendations: $p0';
  }

  @override
  String get flowConstantRange2 => 'Constant range';

  @override
  String get flowSimilarity => 'Similarity';

  @override
  String flowCurrentP0TargetP1(String p0, String p1) {
    return 'Current $p0% → Target $p1%';
  }

  @override
  String flowEnterAValidP0(String p0) {
    return 'Enter a valid $p0';
  }

  @override
  String flowP0MustBeBetweenP1AndP2(String p0, String p1, String p2) {
    return '$p0 must be between $p1 and $p2';
  }

  @override
  String flowP1ForP0(String p0, String p1) {
    return '$p1 for $p0';
  }

  @override
  String get flowMultiPlatformSync => 'Multi-platform sync';

  @override
  String get flowAdvancedDataRefresh => 'Advanced data refresh';

  @override
  String get flowReadPlayCounts => 'Read play counts';

  @override
  String get flowSignOut3 => 'Sign out';

  @override
  String get flowHomeDataRefresh => 'Home data refresh';

  @override
  String get flowWebsiteLink => 'Website link';

  @override
  String get flowFeedbackLink => 'Feedback link';

  @override
  String get flowGroupNumber => 'Group number';

  @override
  String get flowSurveyLink => 'Survey link';

  @override
  String get flowGatewayCheckBeforeReadingPlayCounts =>
      'Gateway check before reading play counts';

  @override
  String get flowReadPlayCountsSeparately => 'Read play counts separately';

  @override
  String get flowPushToDivingFishThroughTheAWMC =>
      'Push to Diving-Fish through the AWMC gateway';

  @override
  String get flowPushToLXNSThroughTheAWMCGateway =>
      'Push to LXNS through the AWMC gateway';

  @override
  String get flowCouldNotLoadTheMosaicCoverTry =>
      'Could not load the mosaic cover. Try another question.';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate3 =>
      '0% shows the original; higher values create larger pixels.';

  @override
  String get flowNoCachedChartsCacheMaidataInThe =>
      'No cached charts. Cache maidata in the chart library first.';

  @override
  String get flowNoCachedSongsMatchTheDifficultyPool =>
      'No cached songs match the difficulty pool and constant range.';

  @override
  String get flowCouldNotReadThisSongSChart =>
      'Could not read this song’s chart data';

  @override
  String get flowThisSongHasNoChartsInThe =>
      'This song has no charts in the difficulty pool';

  @override
  String get flowTheChartIsTooShortToExtract =>
      'The chart is too short to extract a clip';

  @override
  String get flowCouldNotParseChart => 'Could not parse chart';

  @override
  String flowP0ReplaysLeft(String p0) {
    return ' ($p0 replays left)';
  }

  @override
  String get flowNoReplaysLeft2 => ' (no replays left)';

  @override
  String get flowFiltersUseEachSelectedDifficultySOwn =>
      'Filters use each selected difficulty’s own constant. For example, EXPERT uses its EXPERT constant; EXPERT+MASTER accepts either within range.';

  @override
  String get flowCouldNotLoadCoverArtPleaseRetry =>
      'Could not load cover art. Please retry.';

  @override
  String get flowNoRecognizableCropAreaInThisCover =>
      'No recognizable crop area in this cover. Retry or broaden filters.';

  @override
  String get flowAudioIsTemporarilyUnavailable =>
      'Audio is temporarily unavailable';

  @override
  String get flowCouldNotReadAudioDuration => 'Could not read audio duration';

  @override
  String get flowAudioExcerptIsEmpty => 'Audio excerpt is empty';

  @override
  String get flowPreparingAudio2 => 'Preparing audio…';

  @override
  String flowP0Tiles(String p0) {
    return '$p0 tiles';
  }

  @override
  String get flowTheSongCacheIsEmptyNoSong =>
      'The song cache is empty; no song can be drawn.';

  @override
  String get flowNoSongsMatchBroadenTheFiltersIn =>
      'No songs match. Broaden the filters in settings.';

  @override
  String get flowCouldNotLoadSettingsPleaseRetry =>
      'Could not load settings. Please retry.';

  @override
  String get flowExcerptPlaybackLength => 'Excerpt playback length';

  @override
  String get flowS => ' s';

  @override
  String get flowBlurredCoverBlur => 'Blurred cover: blur';

  @override
  String get flowPixelCoverDestruction => 'Pixel cover: destruction';

  @override
  String get flowFlashCoverDuration => 'Flash cover: duration';

  @override
  String get flowTileRevealTileCount => 'Tile reveal: tile count';

  @override
  String get flowTiles => ' tiles';

  @override
  String get flowTileRevealInterval => 'Tile reveal: interval';

  @override
  String get flowNonEnglishCharacterThreshold =>
      'Non-English character threshold';

  @override
  String get flowExcludeSongsWhoseShareOfJapaneseAnd =>
      'Exclude songs whose share of Japanese and other non-English, non-space characters meets or exceeds this threshold.';

  @override
  String get flowRemainingSongs => 'Remaining songs';

  @override
  String get flowYouGuessedEverySong => 'You guessed every song!';

  @override
  String get flowSongsFromAllAreas => 'Songs from all areas';

  @override
  String get flowPerfectChallengeSongsFromAllAreas =>
      'Perfect Challenge songs from all areas';

  @override
  String get flowFixedTheHiddenSong => 'Fixed: the hidden song';

  @override
  String get flowBlueGateEntrance => 'Blue Gate entrance';

  @override
  String get flowSkyStreetArea6 => 'Sky Street area 6';

  @override
  String get flowWhiteGateEntrance => 'White Gate entrance';

  @override
  String get flowHeavenArea8 => 'Heaven area 8';

  @override
  String get flowPurpleGateEntrance => 'Purple Gate entrance';

  @override
  String get flowPurpleRoseArea10 => 'Purple Rose area 10';

  @override
  String get flowBlackGateEntrance => 'Black Gate entrance';

  @override
  String get flowMetropolisArea9 => 'Metropolis area 9';

  @override
  String get flowPlayAll11SongsInThePool =>
      'Play all 11 songs in the pool below';

  @override
  String get flowTrackSkipIsAllowedDanCertificationAnd =>
      'Track Skip is allowed; Dan certification and UTAGE are excluded.';

  @override
  String get flowYellowGateEntrance => 'Yellow Gate entrance';

  @override
  String get flowRainbowArea => 'Rainbow area (なないろちほー)';

  @override
  String get flowAfterTheGateUpdateUseRandomSong =>
      'After the gate update, use random song selection to draw and play any song in the pool below once.';

  @override
  String get flowAnyDifficultyRetryingIsAllowedFavoritesCategories =>
      '(Any difficulty; retrying is allowed. Favorites categories may be used.)';

  @override
  String get flowRandomSelectionInTheDepartureArea =>
      'Random selection in the departure area';

  @override
  String get flowRandomPerfectChallengeSongMAXRAGEAndUniTas =>
      'Random Perfect Challenge song, MAXRAGE and UniTas in the departure area';

  @override
  String get flowRedGateEntrance => 'Red Gate entrance';

  @override
  String get flowSongPool => 'Song pool';

  @override
  String get flowGateConditions => 'Gate conditions';

  @override
  String get flowNotSet3 => ' (not set)';

  @override
  String get flowKeyRequiredToChallenge => 'Key (required to challenge)';

  @override
  String get flowKALEIDXSCOPEMode => 'KALEIDXSCOPE mode';

  @override
  String flowFirstSongP0(String p0) {
    return 'First song: $p0';
  }

  @override
  String flowSecondSongP0(String p0) {
    return 'Second song: $p0';
  }

  @override
  String flowThirdSongP0(String p0) {
    return 'Third song: $p0';
  }

  @override
  String get flowPerfectChallengeSong => 'Perfect Challenge song';

  @override
  String get flowClearRewardSong => 'Clear reward song';

  @override
  String get flowHiddenSong => 'Hidden song';

  @override
  String get flowPerfectChallenge => 'Perfect Challenge';

  @override
  String get flowGuide => 'Guide';

  @override
  String get flowSongs4 => 'Songs';

  @override
  String get flowBlueGate => 'Blue Gate';

  @override
  String get flowWhiteGate => 'White Gate';

  @override
  String get flowPurpleGate => 'Purple Gate';

  @override
  String get flowBlackGate => 'Black Gate';

  @override
  String get flowYellowGate => 'Yellow Gate';

  @override
  String get flowRedGate => 'Red Gate';

  @override
  String get flowCouldNotLoadNewGatesRefreshUsing =>
      'Could not load new gates. Refresh using the button above.';

  @override
  String get flowDraw => '🤝 Draw';

  @override
  String get flowJointWinners => '🤝 Joint winners';

  @override
  String get flowYouWon => '🏆 You won!';

  @override
  String flowP0Won(String p0) {
    return '🏆 $p0 won';
  }

  @override
  String get flowNoOneScoredInThisGame => 'No one scored in this game';

  @override
  String get flowCouldNotConnectToTheRoomCheck =>
      'Could not connect to the room. Check your connection and retry.';

  @override
  String flowP0IsNowTheHost(String p0) {
    return '$p0 is now the host';
  }

  @override
  String get flowNoCoverArtAvailable => 'No cover art available';

  @override
  String get flowScoring => 'Scoring';

  @override
  String get flowCorrectAnswer100SecondsSinceTheRound =>
      'Correct answer = 100 − seconds since the round started, with a minimum of 10. Incorrect answers earn 0.';

  @override
  String get flowFasterAnswersScoreHigherInstantAnswersApproach =>
      'Faster answers score higher: instant answers approach 100 points; even a late answer earns at least 10.';

  @override
  String get flowOnlyYourBestAttemptForEachSong =>
      'Only your best attempt for each song counts; repeat submissions do not add points.';

  @override
  String get flowOnlyTheFirstCorrectPlayerScoresFor =>
      'Only the first correct player scores for each song; everyone else earns 0 for that song.';

  @override
  String get flowIncorrectGuessesDoNotSubtractPoints =>
      'Incorrect guesses do not subtract points.';

  @override
  String get flowLetterRevealHasSeveralSongsPerRound =>
      'Letter reveal has several songs per round, scored separately. Maximum round score = songs × 100.';

  @override
  String get flowColorMeanings => 'Color meanings';

  @override
  String get flowYellowCloseToTheTargetBPMWithin =>
      'Yellow: close to the target — BPM within ±20, MASTER/Re:MASTER constant within ±0.4, or one version apart (maimai ← maimai PLUS → maimai GreeN).';

  @override
  String get flowGrayFarFromTheTarget => 'Gray: far from the target.';

  @override
  String get flowArrows2 => 'Arrows';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor2 =>
      'Shows pattern, difficulty and evaluation tags for your guess’s MASTER chart.';

  @override
  String get flowAMatchingTargetTagTurnsGreen =>
      'A matching target tag turns green.';

  @override
  String get flowSomeSongsMayNotHaveTags2 => 'Some songs may not have tags.';

  @override
  String get flowLetterRevealRules => 'Letter reveal rules';

  @override
  String get flowTitlesAreMaskedWithAnyoneCanReveal =>
      'Titles are masked with □. Anyone can reveal characters, which become visible to the whole room.';

  @override
  String get flowEachCharacterCanBeRevealedOnlyOnce =>
      'Each character can be revealed only once.';

  @override
  String get flowOnceASongIsGuessedItsFull =>
      'Once a song is guessed, its full title is revealed to everyone.';

  @override
  String get flowGuessingFirstMayRevealTheAnswerBut =>
      'Guessing first may reveal the answer, but only the first correct player scores, so answering early still helps.';

  @override
  String get flowTheRoundEndsOnlyWhenEveryTitle =>
      'The round ends only when every title has been guessed.';

  @override
  String get flowRoomRules => 'Room rules';

  @override
  String get flowRemainingGuessesAreSharedByTheWhole =>
      'Remaining guesses are shared by the whole room. Every guess uses the same pool; the round ends when it is empty.';

  @override
  String get flowAfterSurrenderingYouCannotScoreOrSubmit =>
      'After surrendering, you cannot score or submit more guesses this round, but can keep watching.';

  @override
  String get flowWinning => 'Winning';

  @override
  String get flowTheHighestTotalScoreAfterAllRounds =>
      'The highest total score after all rounds wins.';

  @override
  String get flowEqualScoresShareTheWinIfNo =>
      'Equal scores share the win. If no one scores, the game is a draw.';

  @override
  String get flowScoresAreSettledAtTheEndOf =>
      'Scores are settled at the end of each round; the leaderboard shows settled totals.';

  @override
  String get flowNoTimeLimit => 'No time limit';

  @override
  String get flowTimeIsUp => 'Time is up';

  @override
  String get flowAlmostOutOfTime => 'Almost out of time!';

  @override
  String get flowPlentyOfTime => 'Plenty of time';

  @override
  String get flowAliasClue => 'Alias clue';

  @override
  String get flowReplayExcerptAudioPreparing =>
      'Replay excerpt (audio preparing)';

  @override
  String flowReplayExcerptP0ReplaysLeft(String p0) {
    return 'Replay excerpt ($p0 replays left)';
  }

  @override
  String get flowAnswerUnlimitedReplaysChartOnlyAudioUnavailable =>
      'Answer: unlimited replays (chart only; audio unavailable)';

  @override
  String get flowAnswerUnlimitedReplaysWithAudio =>
      'Answer: unlimited replays with audio';

  @override
  String get flowAnswerUnlimitedReplaysPreparingAudio =>
      'Answer: unlimited replays (preparing audio…)';

  @override
  String get flowPlaybackStopsAutomaticallyAtTheEndOf =>
      'Playback stops automatically at the end of the excerpt';

  @override
  String get flowThisChartIsNotCachedOnThis =>
      'This chart is not cached on this device, and automatic fetching failed.';

  @override
  String get flowNoChartForThisSongMatchesThe =>
      'No chart for this song matches the difficulty pool / constant range.';

  @override
  String flowCouldNotReadInoteP0ForThis(String p0) {
    return 'Could not read inote_$p0 for this song';
  }

  @override
  String get flowCouldNotPlayChartExcerptPleaseRetry =>
      'Could not play chart excerpt. Please retry.';

  @override
  String get flowInvalidSongID => 'Invalid song ID';

  @override
  String get flowCouldNotFetchAudioTryAgainLater =>
      'Could not fetch audio. Try again later.';

  @override
  String get flowLeavingRoom => 'Leaving room…';

  @override
  String get flowRoomDoesNotExistOrCannotBe =>
      'Room does not exist or cannot be joined';

  @override
  String get flow2Players => '2 players';

  @override
  String get flow3Players => '3 players';

  @override
  String get flow4Players => '4 players';

  @override
  String get flow5Players => '5 players';

  @override
  String get flow6Players => '6 players';

  @override
  String get flowRoomCodeCannotBeEmpty => 'Room code cannot be empty';

  @override
  String get flowAfterCreatingARoomTheHostCan =>
      'After creating a room, the host can copy its code from the room page.';

  @override
  String get flowAskYourFriendToSendTheCode =>
      'Ask your friend to send the code, then paste it above to join.';

  @override
  String get flowCouldNotReadAutomaticInstallationSettingsPlease =>
      'Could not read automatic installation settings. Please retry.';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettingsPlease =>
      'Could not save automatic installation settings. Please retry.';

  @override
  String get flowCouldNotOpenInstallationSourceSettingsAllow =>
      'Could not open installation-source settings. Allow ChiffonMai to install apps in system settings.';

  @override
  String get flowDownloadCancelledByUser => 'Download cancelled by user';

  @override
  String get flowThisVersionHasNotBeenPublishedYet =>
      'This version has not been published yet';

  @override
  String get flowCouldNotIdentifyASingleAPKFor =>
      'Could not identify a single APK for this device. Download from the website.';

  @override
  String get flowReleaseAssetLacksValidAPKInformationOr =>
      'Release asset lacks valid APK information or a SHA-256 digest';

  @override
  String get flowCouldNotFetchGitHubReleaseInformation =>
      'Could not fetch GitHub release information';

  @override
  String get flowFetchingAPKInformation => 'Fetching APK information…';

  @override
  String get flowPreparingBackgroundDownload =>
      'Preparing background download…';

  @override
  String get flowCouldNotStartBackgroundDownload =>
      'Could not start background download';

  @override
  String get flowCouldNotStartBackgroundDownloadPleaseRetry =>
      'Could not start background download. Please retry.';

  @override
  String get flowCouldNotReadExcerptDuration =>
      'Could not read excerpt duration';

  @override
  String get flowAudioExcerptIsIncomplete => 'Audio excerpt is incomplete';

  @override
  String get flowAudioResponseIsNotAValidWAV =>
      'Audio response is not a valid WAV file';

  @override
  String get flowNoAliases => 'No aliases';

  @override
  String get flowTooLate => 'Too late';

  @override
  String get flowTooEarly => 'Too early';

  @override
  String get flowInitializationFailed => 'Initialization failed';

  @override
  String get flowInitializationTimedOut => 'Initialization timed out';

  @override
  String flowRepeatOneP0Times(String p0) {
    return 'Repeat one $p0 times';
  }

  @override
  String get flowCurrentSong => 'Current song';

  @override
  String flowLXNSAudioFailedForP0TryingWmc(String p0) {
    return 'LXNS audio failed for “$p0”. Trying wmc…';
  }

  @override
  String flowNoAudioAvailableForP0Skipped(String p0) {
    return 'No audio available for “$p0”. Skipped.';
  }

  @override
  String get flowChiffonMaiMusicPlayer => 'ChiffonMai music player';

  @override
  String get flowSeveralSongsFailedToLoadAutomaticSkipping =>
      'Several songs failed to load. Automatic skipping stopped; check your connection and retry.';

  @override
  String flowNowPlayingP0(String p0) {
    return 'Now playing: $p0';
  }

  @override
  String flowCouldNotSaveAudioP0(String p0) {
    return 'Could not save audio: $p0';
  }

  @override
  String get flowInvalidAPKDirectoryRange => 'Invalid APK directory range';

  @override
  String get flowIncompleteAPKDirectoryData => 'Incomplete APK directory data';

  @override
  String get flowCouldNotReadAPKZIPDirectory =>
      'Could not read APK ZIP directory';

  @override
  String get flowInvalidAPKManifestSize => 'Invalid APK manifest size';

  @override
  String get flowInvalidAPKManifestDirectory =>
      'Invalid APK manifest directory';

  @override
  String get flowAPKManifestDecompressedSizeMismatch =>
      'APK manifest decompressed size mismatch';

  @override
  String get flowUnsupportedAPKManifestCompression =>
      'Unsupported APK manifest compression';

  @override
  String get flowIncompleteAPKManifestData => 'Incomplete APK manifest data';

  @override
  String get flowAPKHasNoVersionManifest => 'APK has no version manifest';

  @override
  String get flowInvalidBinaryAPKManifest => 'Invalid binary APK manifest';

  @override
  String get flowInvalidAPKManifestStringIndex =>
      'Invalid APK manifest string index';

  @override
  String get flowInvalidAPKManifestChunk => 'Invalid APK manifest chunk';

  @override
  String get flowInvalidAPKManifestStringTable =>
      'Invalid APK manifest string table';

  @override
  String get flowInvalidAPKManifestAttribute =>
      'Invalid APK manifest attribute';

  @override
  String get flowAPKManifestAttributeOutOfBounds =>
      'APK manifest attribute out of bounds';

  @override
  String get flowAPKLacksValidVersionInformation =>
      'APK lacks valid version information';

  @override
  String get flowAPKHasNoAppVersionInformation =>
      'APK has no app version information';

  @override
  String get flowAPKManifestDataOutOfBounds =>
      'APK manifest data out of bounds';

  @override
  String get flowContentContainsDisallowedWordingEditItAnd =>
      'Content contains disallowed wording. Edit it and retry.';

  @override
  String get flowMASTERConstantRange => 'MASTER constant range';

  @override
  String get flowUnlimited2 => 'Unlimited';

  @override
  String get flowEnterOneValueOrACompleteRange =>
      'Enter one value or a complete range, such as 13.7 or 13.4–14';

  @override
  String get flowConstantMustBeAFiniteNumberGreater =>
      'Constant must be a finite number greater than 0';

  @override
  String get flowLowerBoundCannotExceedUpperBound =>
      'Lower bound cannot exceed upper bound';

  @override
  String get flowUnknownDifficulty => 'Unknown difficulty';

  @override
  String get flowUTAGECannotBeCombinedWithNormalDifficulties =>
      'UTAGE cannot be combined with normal difficulties';

  @override
  String get flowChooseSaveLocation => 'Choose save location';

  @override
  String get flowPublicExportDirectoryIsNotWritableWriting =>
      'Public export directory is not writable; writing to the app’s private directory was refused.';

  @override
  String flowSupportsChiffonMaiFavoritesFilesSuchAsP0(String p0) {
    return 'Supports ChiffonMai favorites files such as $p0';
  }

  @override
  String get flowCouldNotReadCoverPixels => 'Could not read cover pixels';

  @override
  String get flowCouldNotReadImageData => 'Could not read image data';

  @override
  String get flowDateToBeUpdated => 'Date to be updated';

  @override
  String get flowLater => 'Later';

  @override
  String get flowWaitForRetryAfterSecondsOrQuotaResetAtBefore =>
      'Wait for retryAfterSeconds or quota.resetAt before retrying';

  @override
  String flowRetryAfterSecondsP0S(String p0) {
    return 'retryAfterSeconds (${p0}s)';
  }

  @override
  String flowRetryAfterP0OrP1(String p0, String p1) {
    return 'Retry after $p0 or $p1';
  }

  @override
  String get flowYourSelectionIsActiveButCouldNot =>
      'Your selection is active but could not be saved. Tap the selected difficulty again to retry.';

  @override
  String flowP0ReleasedTapForChanges(String p0) {
    return '$p0 released. Tap for changes.';
  }

  @override
  String get flowPleaseSignIn => 'Please sign in';

  @override
  String get flowSettingsWereNotSavedPleaseRetry =>
      'Settings were not saved. Please retry.';

  @override
  String flowP0Count(String p0) {
    return '$p0 count';
  }

  @override
  String get flowAllowChiffonMaiToInstallUpdates =>
      'Allow ChiffonMai to install updates';

  @override
  String get flowCouldNotOpenInstaller => 'Could not open installer';

  @override
  String get flowCouldNotOpenInstallationPermissionSettings =>
      'Could not open installation permission settings';

  @override
  String get flowActionFailedPleaseRetry => 'Action failed. Please retry.';

  @override
  String flowCouldNotReadCacheUsageP0(String p0) {
    return 'Could not read cache usage: $p0';
  }

  @override
  String flowCouldNotClearCacheP0(String p0) {
    return 'Could not clear cache: $p0';
  }

  @override
  String get flowLeftRight => 'Left / right';

  @override
  String get flowUpDown => 'Up / down';

  @override
  String get flowBoth => 'Both';

  @override
  String get flowNoMirror => 'No mirror';

  @override
  String get flowNothingHereYet => 'Nothing here yet';

  @override
  String get flowChoose015SpeedAndPitch =>
      'Choose 0.1×–5×. Speed and pitch change together; shorter sources play for their actual length.';

  @override
  String get flowBPMChanges => 'BPM changes?';

  @override
  String get flowNotProvided => 'Not provided';

  @override
  String get flowYes => 'Yes';

  @override
  String get flowNo2 => 'No';

  @override
  String get flowBPMChangeCount => 'BPM change count';

  @override
  String get flowCouldNotLoadCoverArt2 => 'Could not load cover art';

  @override
  String get flowCorrect2 => 'Correct';

  @override
  String get flowAccuracy => 'Accuracy';

  @override
  String get flowAverageTime => 'Average time';

  @override
  String get flowCurrentStreak => 'Current streak';

  @override
  String get flowBestStreak => 'Best streak';

  @override
  String get flowResultOriginalAudio => 'Result original audio';

  @override
  String get flowOriginalAudioIsUnavailablePleaseRetry =>
      'Original audio is unavailable. Please retry.';

  @override
  String get flowPlayOriginalAudio => 'Play original audio';

  @override
  String get flowTitle2 => 'Title';

  @override
  String get flowType => 'Type';

  @override
  String get flowMASTERConstant => 'MASTER constant';

  @override
  String get flowMASTERChartDesigner => 'MASTER chart designer';

  @override
  String get flowReMASTERConstant => 'Re:MASTER constant';

  @override
  String get flowReMASTERChartDesigner => 'Re:MASTER chart designer';

  @override
  String get flowMatch => 'Match';

  @override
  String get flowCloseArrowsPointToTheAnswer =>
      'Close (arrows point to the answer)';

  @override
  String get flowNoMatch => 'No match';

  @override
  String flowP0SRound(String p0) {
    return '${p0}s / round';
  }

  @override
  String flowP0Rounds(String p0) {
    return '$p0 rounds';
  }

  @override
  String flowP0SharedGuessesPerRound(String p0) {
    return '$p0 shared guesses per round';
  }

  @override
  String get flowUnlimitedGuesses => 'Unlimited guesses';

  @override
  String flowConstantsP0P1(String p0, String p1) {
    return 'Constants $p0–$p1';
  }

  @override
  String get flowTemporarilyOffline => 'Temporarily offline';

  @override
  String get flowSurrendered => 'Surrendered';

  @override
  String get flowShareTheRoomCodeToInviteFriends =>
      'Share the room code to invite friends';

  @override
  String get flowReady2 => 'Ready';

  @override
  String get flowWaitingToBeReady => 'Waiting to be ready';

  @override
  String get flowConfirmingPlayerIdentity => 'Confirming player identity…';

  @override
  String get flowShareTheCodeAndInviteAtLeast =>
      'Share the code and invite at least one friend';

  @override
  String flowP0PlayersAreNotReadyYet(String p0) {
    return '$p0 players are not ready yet';
  }

  @override
  String get flowEveryoneIsReadyYouCanStart =>
      'Everyone is ready. You can start!';

  @override
  String get flowEveryoneIsReadyWaitingForTheHost =>
      'Everyone is ready. Waiting for the host.';

  @override
  String get flowCouldNotUpdateSongLeaderboard =>
      'Could not update song leaderboard';

  @override
  String get flowRoute1SyncFailed => 'Route 1 sync failed';

  @override
  String get flowCoverGuessing => 'Cover guessing';

  @override
  String get flowBlurredCover => 'Blurred cover';

  @override
  String get flowPixelCover => 'Pixel cover';

  @override
  String get flowReverseAudio => 'Reverse audio';

  @override
  String get flowSpeedPitch => 'Speed / pitch';

  @override
  String get flowAliasGuessing => 'Alias guessing';

  @override
  String get flowFlashCover => 'Flash cover';

  @override
  String get flowTileReveal => 'Tile reveal';

  @override
  String get flowGuessTheSongFromItsInformation =>
      'Guess the song from its information';

  @override
  String get flowGuessTheSongFromACoverFragment =>
      'Guess the song from a cover fragment';

  @override
  String get flowGuessTheSongFromABlurredCover =>
      'Guess the song from a blurred cover';

  @override
  String get flowGuessTheSongFromPixelBlocksAnd =>
      'Guess the song from pixel blocks and outlines';

  @override
  String get flowGuessTheSongFromAReversedExcerpt =>
      'Guess the song from a reversed excerpt';

  @override
  String get flowGuessFromAnExcerptWithLinkedSpeed =>
      'Guess from an excerpt with linked speed and pitch changes';

  @override
  String get flowGuessTheSongFromAnAudioExcerpt =>
      'Guess the song from an audio excerpt';

  @override
  String get flowGuessTheSongFromAnAlias => 'Guess the song from an alias';

  @override
  String get flowGuessTheSongFromInitialLetters =>
      'Guess the song from initial letters';

  @override
  String get flowRememberABrieflyFlashedCoverToGuess =>
      'Remember a briefly flashed cover to guess the song';

  @override
  String get flowCoverTilesAreRevealedInBatches =>
      'Cover tiles are revealed in batches';

  @override
  String get flowGuessFromASilentChartExcerpt =>
      'Guess from a silent chart excerpt';

  @override
  String get flowAutomaticInstallationTestingRequiresAndroid12Or =>
      'Automatic installation testing requires Android 12 or later';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettings =>
      'Could not save automatic installation settings';

  @override
  String get flowAutomaticInstallationIsOffYouCanInstall =>
      'Automatic installation is off. You can install manually.';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo =>
      'Update downloaded. Waiting for the app to stay in the background without tasks for 8 seconds before attempting automatic installation.';

  @override
  String get flowInstallationTaskInformationIsIncomplete =>
      'Installation task information is incomplete';

  @override
  String get flowAutomaticInstallationIsOffInstallManually =>
      'Automatic installation is off. Install manually.';

  @override
  String get flowFinishActiveTasksOrPlaybackBeforeUpdating =>
      'Finish active tasks or playback before updating';

  @override
  String get flowAllowAppsToBeInstalledFromThis =>
      'Allow apps to be installed from this source first';

  @override
  String get flowInstallationTaskChangedCheckUpdateStatusAgain =>
      'Installation task changed. Check update status again.';

  @override
  String get flowCouldNotMoveTheAppToThe =>
      'Could not move the app to the background. Try again later.';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo2 =>
      'Update downloaded. Waiting for the app to enter the background before automatic installation.';

  @override
  String get flowUpdateDownloadedWaitingForTheCurrentTask =>
      'Update downloaded. Waiting for the current task to finish before automatic installation.';

  @override
  String get flowTheLastAutomaticInstallationDidNotFinish =>
      'The last automatic installation did not finish. You can install manually.';

  @override
  String get flowCannotReadTheAPK => 'Cannot read the APK';

  @override
  String get flowThisAPKDoesNotMeetTheSystem =>
      'This APK does not meet the system’s confirmation-free installation requirements. Install manually.';

  @override
  String get flowCouldNotSaveInstallationTask =>
      'Could not save installation task';

  @override
  String get flowPreparingAutomaticUpdateInstallation =>
      'Preparing automatic update installation…';

  @override
  String get flowAPKVerificationFailedDownloadAgain =>
      'APK verification failed. Download again.';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo3 =>
      'Update downloaded. Waiting for the app to stay in the background without tasks for 8 seconds before installation.';

  @override
  String get flowTheSystemNeedsInstallationConfirmationTapTo =>
      'The system needs installation confirmation. Tap to install manually.';

  @override
  String get flowAutomaticInstallationDidNotFinishYouCan =>
      'Automatic installation did not finish. You can install manually.';

  @override
  String get flowUpdateDownloadDirectoryUnavailable =>
      'Update download directory unavailable';

  @override
  String get flowInvalidDownloadAddress => 'Invalid download address';

  @override
  String get flowInvalidAPKVerificationInformation =>
      'Invalid APK verification information';

  @override
  String get flowUpdateTaskChanged => 'Update task changed';

  @override
  String get flowCouldNotRemoveThePreviousUpdateFile =>
      'Could not remove the previous update file';

  @override
  String get flowDownloadingInTheBackgroundYouCanKeep =>
      'Downloading in the background. You can keep using the app.';

  @override
  String get flowDownloadingUpdateInTheBackground =>
      'Downloading update in the background…';

  @override
  String get flowTheAPKWasRemovedDownloadAgain =>
      'The APK was removed. Download again.';

  @override
  String get flowDownloadCancelled => 'Download cancelled';

  @override
  String get flowWaitingForNetworkOrTheSystemTo =>
      'Waiting for network or the system to resume downloading…';

  @override
  String get flowAutomaticInstallationCancelled =>
      'Automatic installation cancelled';

  @override
  String get flowCheckForUpdatesAgainBeforeDownloading =>
      'Check for updates again before downloading';

  @override
  String get flowDownloadFailed => 'Download failed';

  @override
  String get flowVerifyingAPKInTheBackground =>
      'Verifying APK in the background…';

  @override
  String get flowAPKDownloadIsIncomplete => 'APK download is incomplete';

  @override
  String get flowAPKIntegrityCheckFailed => 'APK integrity check failed';

  @override
  String get flowUpdateDownloadFailedPleaseRetry =>
      'Update download failed. Please retry.';

  @override
  String get flowChiffonMaiUpdateDownloaded => 'ChiffonMai update downloaded';

  @override
  String get flowChiffonMaiUpdateDownloadFailed =>
      'ChiffonMai update download failed';

  @override
  String get flowTapToChooseInstallation => 'Tap to choose installation';

  @override
  String get flowTapForDetailsOrToDownloadAgain =>
      'Tap for details or to download again';

  @override
  String get flowSwitchedToManualInstallation =>
      'Switched to manual installation';

  @override
  String get flowCouldNotPrepareUpdateInstallation =>
      'Could not prepare update installation';

  @override
  String get flowAPKInformationIsMissing => 'APK information is missing';

  @override
  String get flowAPKIsOutsideTheUpdateCacheDirectory =>
      'APK is outside the update cache directory';

  @override
  String get flowTheDownloadedFileIsNotAValid =>
      'The downloaded file is not a valid APK';

  @override
  String get flowThisAPKDoesNotBelongToChiffonMai =>
      'This APK does not belong to ChiffonMai';

  @override
  String get flowAPKVersionDoesNotMatchTheUpdate =>
      'APK version does not match the update. Download from the website.';

  @override
  String get flowAPKSignatureMismatchInstallationStopped =>
      'APK signature mismatch. Installation stopped.';

  @override
  String get flowChiffonMaiCrashed => 'ChiffonMai crashed';

  @override
  String get flowLogsWillBeExportedWhenYouReopen =>
      'Logs will be exported when you reopen the app';

  @override
  String get flowAppCrash => 'App crash';

  @override
  String get flowNativeCrash => 'Native crash';

  @override
  String get flowAppNotResponding => 'App not responding';

  @override
  String get flowCrashAlerts => 'Crash alerts';

  @override
  String get flowOpenTheAppToRefreshData => 'Open the app to refresh data';

  @override
  String get flowUpdatesAutomaticallyWhenOnline =>
      'Updates automatically when online';

  @override
  String get flowOpenTheAppToUpdate => 'Open the app to update';

  @override
  String get flowImageExports => 'Image exports';

  @override
  String get flowCouldNotReadSystemWallpaperColors =>
      'Could not read system wallpaper colors';

  @override
  String get flowMusicPlayback => 'Music playback';

  @override
  String get flowShowsTheCurrentSongAndPlaybackControls =>
      'Shows the current song and playback controls';

  @override
  String get flowMusicPlayerPlaying => 'Music player · Playing';

  @override
  String get flowMusicPlayerPaused => 'Music player · Paused';

  @override
  String get flowSyncNow => 'Sync now';

  @override
  String get flowRecognizeScore => 'Recognize score';

  @override
  String get flowMaimaiStatus => 'maimai status';

  @override
  String get flowPlayPause => 'Play / pause';

  @override
  String get flowMaimaiStatusAndSync => 'maimai status and sync';

  @override
  String get flowChiffonMaiOverview => 'ChiffonMai overview';

  @override
  String get flowChiffonMaiDetails => 'ChiffonMai details';

  @override
  String get flowShowsYourRating => 'Shows your Rating';

  @override
  String get flowShowsMaimaiStatusAndAutomaticSync =>
      'Shows maimai status and automatic sync';

  @override
  String get flowRatingMaimaiStatusAndAutomaticSync =>
      'Rating, maimai status and automatic sync';

  @override
  String get flowAddsSourceSyncResultsAndQuickActions =>
      'Adds source sync results and quick actions';

  @override
  String flowChiffonMaiVP0Update(String p0) {
    return 'ChiffonMai v$p0 update';
  }

  @override
  String flowAutomaticInstallationDidNotFinishP0You(String p0) {
    return 'Automatic installation did not finish: $p0. You can install manually.';
  }

  @override
  String flowP0P1Healthy(String p0, String p1) {
    return '$p0/$p1 healthy';
  }

  @override
  String flowTodayP0(String p0) {
    return 'Today $p0';
  }

  @override
  String flowP0P1P22(String p0, String p1, String p2) {
    return '$p0/$p1 $p2';
  }

  @override
  String flowUpdatedP03(String p0) {
    return 'Updated $p0';
  }

  @override
  String get flowImageSavedTapToReturnToChiffonMai =>
      'Image saved. Tap to return to ChiffonMai.';

  @override
  String get flowNotSupportedByTheSystemRightNow =>
      'Not supported by the system right now';

  @override
  String get svcCheckInIsUnavailableRightNowIt =>
      'Check-in is unavailable right now. It will retry on next launch.';

  @override
  String get svcCouldNotReadGrowthRecordsItWill =>
      'Could not read growth records. It will retry on next launch.';

  @override
  String get svcCheckedInToday => 'Checked in today';

  @override
  String get svcSignInToCheckInAndEarn =>
      'Sign in to check in and earn EXP on your first launch each day';

  @override
  String get svcNoGrowthRecordsYetYouWillBe =>
      'No growth records yet. You will be checked in on next launch.';

  @override
  String get svcCheckingIn => 'Checking in…';

  @override
  String get svcCheckInAccountDoesNotMatch => 'Check-in account does not match';

  @override
  String svcCheckedInTodayP0EXP(String p0) {
    return 'Checked in today: +$p0 EXP';
  }

  @override
  String get svcSavedOnThisDeviceOnlySyncsAfter =>
      'Saved on this device only · Syncs after signing in to Diving-Fish';

  @override
  String get svcSavedOnThisDeviceOnlySignIn =>
      'Saved on this device only · Sign in and refresh your LXNS account first';

  @override
  String get svcSavedOnThisDeviceOnlyEnterThe =>
      'Saved on this device only · Enter the QQ number of your AWMC account first';

  @override
  String get svcLoadingCommunityAppearance => 'Loading community appearance';

  @override
  String get svcAppearanceWaitingToSync => 'Appearance waiting to sync';

  @override
  String get svcAppearanceWaitingToSyncSignInOr =>
      'Appearance waiting to sync · Sign in or verify the account, then retry';

  @override
  String get svcAppearanceWaitingToSyncTapToRetry =>
      'Appearance waiting to sync · Tap to retry';

  @override
  String get svcSavedOnThisDeviceOnlySignIn2 =>
      'Saved on this device only · Sign in or verify the account first';

  @override
  String get svcSyncingCommunityAppearance => 'Syncing community appearance';

  @override
  String get svcCommunityAppearanceSynced => 'Community appearance synced';

  @override
  String get svcAppearanceWaitingToSyncTheServerHas =>
      'Appearance waiting to sync · The server has not confirmed your selection yet';

  @override
  String get svcCouldNotGetTheAPKVersionsPublished =>
      'Could not get the APK versions published on GitHub';

  @override
  String get svcCouldNotReadTheActualVersionOf =>
      'Could not read the actual version of the GitHub APK. Try again later.';

  @override
  String get svcTheAppOrVersionOfTheGitHub =>
      'The app or version of the GitHub APK does not match the release information';

  @override
  String get svcExperienceImprovements => 'Experience improvements';

  @override
  String get svcNetworkConnectionFailedCheckYourNetworkAnd =>
      'Network connection failed. Check your network and try again.';

  @override
  String svcUpdateCheckFailedP0(String p0) {
    return 'Update check failed: $p0';
  }

  @override
  String get svcSwitchRoutesAutomatically => 'Switch routes automatically';

  @override
  String get svcTriesTheMirrorRoutesThenTheOfficial =>
      'Tries the mirror routes, then the official direct download';

  @override
  String get svcCommonMirrorRoute => 'Common mirror route';

  @override
  String get svcBackupMirrorRoute => 'Backup mirror route';

  @override
  String get svcGitHubDirect => 'GitHub direct';

  @override
  String get svcDownloadDirectlyFromGitHub => 'Download directly from GitHub';

  @override
  String get svcQRCodeEntryCancelled => 'QR code entry cancelled';

  @override
  String svcReasonP0TheLogWasExportedAutomatically(String p0) {
    return 'Reason: $p0. The log was exported automatically as';
  }

  @override
  String get gainRouteStable => 'Safe gains';

  @override
  String get gainRouteChallenge => 'Push higher';

  @override
  String get gainRouteExplore => 'Explore';

  @override
  String get svcIncorrectUsernameOrPasswordCheckAndTry =>
      'Incorrect username or password. Check and try again.';

  @override
  String get svcTooManySignInAttemptsTryAgain =>
      'Too many sign-in attempts. Try again later.';

  @override
  String get svcTheDivingFishSignInServiceIs =>
      'The Diving-Fish sign-in service is unavailable. Try again later.';

  @override
  String get svcTheDivingFishSignInServiceReturned =>
      'The Diving-Fish sign-in service returned an unexpected response. Try again later.';

  @override
  String get svcSignedInButNoSessionWasCreated =>
      'Signed in, but no session was created. Try again later.';

  @override
  String get svcSignedInButCouldNotGetThe =>
      'Signed in, but could not get the account profile. Try again later.';

  @override
  String get svcSignedInButNoImportTokenWasReturned =>
      'Signed in, but no ImportToken was returned. Rotate and save it on the Diving-Fish website.';

  @override
  String get svcSignedInButNoLinkedQQNumber =>
      'Signed in, but no linked QQ number was found. Enter and save it on the Diving-Fish website.';

  @override
  String get svcASyncIsAlreadyInProgressTry =>
      'A sync is already in progress. Try again later.';

  @override
  String get svcTheQRCodeIsInvalidOrHas =>
      'The QR code is invalid or has expired. Scan again.';

  @override
  String get svcMaimaiScoreHubReturnedAnUnexpectedResponse =>
      'maimai Score Hub returned an unexpected response without token or friendCode. Try again later.';

  @override
  String get svcCouldNotCreateTheFetchTaskTry =>
      'Could not create the fetch task. Try again later.';

  @override
  String get svcCouldNotCreateTheFriendRequestTry =>
      'Could not create the friend request. Try again later.';

  @override
  String get svcMaimaiScoreHubDidNotReturnA =>
      'maimai Score Hub did not return a friend request task ID';

  @override
  String get svcFriendRequestTimedOutAcceptTheRequest =>
      'Friend request timed out. Accept the request on NET or the cabinet, then retry.';

  @override
  String get svcFriendRequestFailed => 'Friend request failed';

  @override
  String get svcMaimaiScoreHubDidNotReturnA2 =>
      'maimai Score Hub did not return a task ID';

  @override
  String svcSyncTimedOutFetchingScoresTookMore(String p0) {
    return 'Sync timed out: fetching scores took more than $p0 minutes. The bot friend request may not have been accepted. Confirm it on NET and retry.';
  }

  @override
  String get svcCouldNotCheckTheTaskStatusCheck =>
      'Could not check the task status. Check your network and try again.';

  @override
  String get svcTaskFailed => 'Task failed';

  @override
  String get svcScoresWereFetchedButSyncingToDiving =>
      'Scores were fetched, but syncing to Diving-Fish failed. You can retry the export manually later.';

  @override
  String svcDivingFishExportFailedP0(String p0) {
    return 'Diving-Fish export failed: $p0';
  }

  @override
  String svcSyncErrorP0(String p0) {
    return 'Sync error: $p0';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub =>
      'Not signed in to maimai Score Hub. Sign in before using route 2.';

  @override
  String get svcCouldNotSubmitTheQRCodeCheck =>
      'Could not submit the QR code. Check your network and try again.';

  @override
  String svcSyncTimedOutFetchingScoresTookMore2(String p0) {
    return 'Sync timed out: fetching scores took more than $p0 minutes. Try again later.';
  }

  @override
  String get svcCouldNotSetTheLXNSAPIKey =>
      'Could not set the LXNS API key. Check your network and try again.';

  @override
  String svcSyncTimedOutFetchingCabinetScoresTook(String p0) {
    return 'Sync timed out: fetching cabinet scores took more than $p0 minutes';
  }

  @override
  String get svcScoresWereFetchedButSyncingToLXNS =>
      'Scores were fetched, but syncing to LXNS failed. You can retry the export manually later.';

  @override
  String svcLXNSExportFailedP0(String p0) {
    return 'LXNS export failed: $p0';
  }

  @override
  String get svcQueueStatisticsAreUnavailableTryAgainLater =>
      'Queue statistics are unavailable. Try again later.';

  @override
  String get svcCouldNotReadTheAutoSyncSettings =>
      'Could not read the auto-sync settings. Keep the local data and try again.';

  @override
  String get svcCouldNotReadTheAutoSyncCredentials =>
      'Could not read the auto-sync credentials. Keep the local data and try again.';

  @override
  String get svcTheAutoSyncServiceIsUnavailableCheck =>
      'The auto-sync service is unavailable. Check your network and try again; the setting has not been confirmed.';

  @override
  String get svcSyncedButTheLocalDataRefreshDid =>
      'Synced, but the local data refresh did not finish. Refresh manually.';

  @override
  String get svcPersonalKeySavedOnThisDeviceThe =>
      'Personal key saved on this device; the scheduled task is waiting to update';

  @override
  String get svcTheAccountChangedTurnOffAutoSync =>
      'The account changed. Turn off auto-sync for the old account, then turn it on again.';

  @override
  String get svcSaveThePersonalKeyForThisData =>
      'Save the personal key for this data source again';

  @override
  String svcPersonalKeySavedOnThisDeviceThe2(String p0) {
    return 'Personal key saved on this device; the scheduled task is waiting to update: $p0';
  }

  @override
  String get svcCheckYourNetworkAndTryAgain =>
      'Check your network and try again';

  @override
  String get svcEnterThePersonalKey => 'Enter the personal key';

  @override
  String get svcPersonalKeySaved => 'Personal key saved';

  @override
  String get svcPersonalKeySavedAndTheScheduledTask =>
      'Personal key saved and the scheduled task updated';

  @override
  String get svcPersonalKeySavedAutoSyncStaysOff =>
      'Personal key saved; auto-sync stays off';

  @override
  String get svcPersonalKeyCleared => 'Personal key cleared';

  @override
  String get svcPersonalKeyClearedAndTheMatchingAuto =>
      'Personal key cleared and the matching auto-sync turned off';

  @override
  String get svcCouldNotVerifyTheTargetAccountScores =>
      'Could not verify the target account scores or sync credentials. Check the account status for this data source.';

  @override
  String get svcAnAutoSyncTaskAlreadyExistsTrying =>
      'An auto-sync task already exists. Trying to restore management access for the current user.';

  @override
  String get svcNoMatchingAutoSyncTaskWasFound =>
      'No matching auto-sync task was found. Turn it on again.';

  @override
  String get svcTheTaskIsRunningRestoreManagementAccess =>
      'The task is running. Restore management access later.';

  @override
  String get svcTheAccountLinkedToTheTaskChanged =>
      'The account linked to the task changed. Turn auto-sync off, then on again.';

  @override
  String get svcQuickSyncCredentialsAreIncompleteEnterA =>
      'Quick-sync credentials are incomplete. Enter a QR code to link your cabinet identity first.';

  @override
  String get svcTooManyRequestsTryAgainLater =>
      'Too many requests. Try again later.';

  @override
  String get svcCouldNotReadTheSongLibraryOf =>
      'Could not read the song library of the target data source; this sync stopped.';

  @override
  String get svcScoreUploadFailedSomeBatchesMayHave =>
      'Score upload failed; some batches may have been submitted. It will not retry automatically this time.';

  @override
  String get svcTheAWMCNETImportTokenIsInvalid =>
      'The AWMC NET Import-Token is invalid. Save a valid token in Score import credentials; enabled scheduled tasks will update automatically.';

  @override
  String get svcCouldNotReadCabinetScoresTryAgain =>
      'Could not read cabinet scores. Try again later.';

  @override
  String get svcTheUpstreamReturnedPagedScoresReadingStopped =>
      'The upstream returned paged scores; reading stopped this round to avoid repeated requests.';

  @override
  String get svcNoValidScoresSupportedByTheTarget =>
      'No valid scores supported by the target data source were read';

  @override
  String get svcAServiceRestartInterruptedTheLastSync =>
      'A service restart interrupted the last sync. It will continue at the next scheduled time.';

  @override
  String get svcTheAutoSyncSettingChangedRefreshThe =>
      'The auto-sync setting changed. Refresh the status.';

  @override
  String get svcThisSyncTimedOutAndStoppedIt =>
      'This sync timed out and stopped. It will continue at the next scheduled time.';

  @override
  String get svcAutoSyncCapacityIsFullTurnIt =>
      'Auto-sync capacity is full. Turn it on again later.';

  @override
  String get svcTheUpstreamQuotaCannotBeConfirmedOr =>
      'The upstream quota cannot be confirmed or is used up. The task will continue once it recovers.';

  @override
  String get svcTheUpstreamServiceIsUnavailableTheTask =>
      'The upstream service is unavailable. The task is paused and will continue after it recovers.';

  @override
  String get svcThisMorningSProcessingWindowHasEnded =>
      'This morning\'s processing window has ended. It will continue in the next round.';

  @override
  String get svcTheUploadResultIsUncertainTheNext =>
      'The upload result is uncertain. The next round will check it before continuing.';

  @override
  String get svcTheAutoSyncServiceIsUnavailableTry =>
      'The auto-sync service is unavailable. Try again later.';

  @override
  String svcSetUpTheSyncCredentialsForP0(String p0) {
    return 'Set the $p0 score import token in Score import credentials first';
  }

  @override
  String svcSetUpYourP0AccountFirst(String p0) {
    return 'Set up your $p0 account first';
  }

  @override
  String svcRefreshYourP0AccountDataBeforeUsing(String p0) {
    return 'Refresh your $p0 account data before using quick sync';
  }

  @override
  String get svcAWMCReportedSuccessWithoutAUserIdThe =>
      'AWMC reported success without a userId; the cabinet identity was not cached';

  @override
  String get svcQuickSyncIsInProgressPleaseWait =>
      'Quick sync is in progress. Please wait.';

  @override
  String get svcUserCredentialsAreNotCachedEnterA =>
      'User credentials are not cached. Enter a QR code to link your cabinet identity first.';

  @override
  String get svcUpdateTheSongLibraryBeforeUsingQuick =>
      'Update the song library before using quick sync';

  @override
  String get svcNoValidScoresMatchedTheLocalSong =>
      'No valid scores matched the local song library; nothing was uploaded';

  @override
  String svcTheAWMCGatewayIsUnavailableP0(String p0) {
    return 'The AWMC gateway is unavailable: $p0';
  }

  @override
  String get svcScorePagingWasAbnormalTheUpdateStopped =>
      'Score paging was abnormal; the update stopped';

  @override
  String get svcTheServerDoesNotOfferQuickSync =>
      'The server does not offer quick sync yet. Update the server proxy.';

  @override
  String get svcTheCurrentGatewayUpstreamCannotReadWithout =>
      'The current gateway upstream cannot read without a QR code. Use regular sync.';

  @override
  String svcQuickReadFailedP0(String p0) {
    return 'Quick read failed: $p0';
  }

  @override
  String get svcTheAWMCGatewayReturnedAnInvalidScore =>
      'The AWMC gateway returned an invalid score page cursor';

  @override
  String get svcTheAWMCGatewayReturnedPagedResultsReading =>
      'The AWMC gateway returned paged results; reading stopped to avoid repeated requests';

  @override
  String get svcNoValidScoresWereReadNothingWas =>
      'No valid scores were read; nothing was uploaded';

  @override
  String svcCouldNotReadTheP0SongLibrary(String p0) {
    return 'Could not read the $p0 song library; no scores were uploaded';
  }

  @override
  String svcTheP0SongLibraryIsEmptyNo(String p0) {
    return 'The $p0 song library is empty; no scores were uploaded';
  }

  @override
  String svcCouldNotReadExistingP0ScoresSo(String p0) {
    return 'Could not read existing $p0 scores, so quick sync did not run. Check the account status of this source first.';
  }

  @override
  String svcP0ReturnedScoresInAnInvalidFormat(String p0) {
    return '$p0 returned scores in an invalid format, so quick sync did not run';
  }

  @override
  String svcP0ScoresAreMissingChartOrCombo(String p0) {
    return '$p0 scores are missing chart or combo/sync fields, so quick sync did not run';
  }

  @override
  String svcUploadToP0FailedHTTPP1Remaining(String p0, String p1) {
    return 'Upload to $p0 failed (HTTP $p1); remaining batches were stopped. Submitted batches may already have taken effect.';
  }

  @override
  String get svcThereAreNoFavoriteFoldersToExport =>
      'There are no favorite folders to export';

  @override
  String get svcChooseAChiffonMaiFavoritesFile =>
      'Choose a ChiffonMai favorites file';

  @override
  String get svcCouldNotReadTheSelectedFile =>
      'Could not read the selected file';

  @override
  String svcFileNotFoundP0(String p0) {
    return 'File not found: $p0';
  }

  @override
  String svcTheFavoritesFileIsTooLargeLimit(String p0) {
    return 'The favorites file is too large (limit $p0 MB)';
  }

  @override
  String get svcThisFileIsNotInTheChiffonMai =>
      'This file is not in the ChiffonMai favorites format.\n(Plain .txt lists from older versions have no song IDs and cannot be restored. Export again.)';

  @override
  String get svcTheFileIsNotValidJSONAnd =>
      'The file is not valid JSON and may be damaged';

  @override
  String svcTheFileFormatTagIsP0Not(String p0) {
    return 'The file format tag is \"$p0\", not a ChiffonMai favorites file';
  }

  @override
  String get svcTheFileContentCouldNotBeRecognized =>
      'The file content could not be recognized';

  @override
  String get svcTheFileHasNoFavoritesData => 'The file has no favorites data';

  @override
  String get svcTheFileIsMissingTheFoldersField =>
      'The file is missing the folders field';

  @override
  String get svcTheFileIsEmpty => 'The file is empty';

  @override
  String get svcTheBackupExceedsThe50MBLimit =>
      'The backup exceeds the 50 MB limit. Reduce custom chart archives and try again.';

  @override
  String svcTheBackupFileIsTooLargeLimit(String p0) {
    return 'The backup file is too large (limit $p0 MB)';
  }

  @override
  String get svcInvalidBackupFileMissingTheDataField =>
      'Invalid backup file: missing the data field';

  @override
  String get svcInvalidBackupFileMissingTheVersionField =>
      'Invalid backup file: missing the version field';

  @override
  String get svcUnsupportedBackupVersionOrAppFormat =>
      'Unsupported backup version or app format';

  @override
  String get svcTheBackupFileIsEmptyThereIs =>
      'The backup file is empty; there is nothing to restore';

  @override
  String get svcADataRestoreIsAlreadyInProgress =>
      'A data restore is already in progress';

  @override
  String get svcSecureCredentialsHaveNotFinishedMigratingTry =>
      'Secure credentials have not finished migrating. Try restoring again later.';

  @override
  String get svcCouldNotClearTheOldSettings =>
      'Could not clear the old settings';

  @override
  String svcCouldNotWriteTheBackupSettingP0(String p0) {
    return 'Could not write the backup setting: $p0';
  }

  @override
  String get svcTheBackupHasNoUserSettingsTo =>
      'The backup has no user settings to restore; current data was kept';

  @override
  String get svcSignInAndLinkYourDivingFish =>
      'Sign in and link your Diving-Fish QQ first';

  @override
  String get svcTheCurrentDivingFishUserHasNo =>
      'The current Diving-Fish user has no play data. Refresh data first.';

  @override
  String get svcNoPlayDataWasFoundForThis =>
      'No play data was found for this friend. Check that the QQ number is correct.';

  @override
  String get svcAddYourAWMCNETQQNumberIn =>
      'Link your AWMC NET QQ number in Links & authorization first';

  @override
  String get svcSignInToYourLXNSAccountFirst =>
      'Sign in to your LXNS account first';

  @override
  String get svcCouldNotReadYourLXNSScoresTry =>
      'Could not read your LXNS scores. Try again later.';

  @override
  String get svcTheSongLibraryHasNotLoadedYet =>
      'The song library has not loaded yet. Try again later.';

  @override
  String get svcTheFriendCodeMustContainOnlyDigits =>
      'The friend code must contain only digits. Check and try again.';

  @override
  String svcCouldNotLookUpTheFriendS(String p0) {
    return 'Could not look up the friend\'s scores (HTTP $p0)';
  }

  @override
  String get svcNoLXNSScoresForThisFriendThey =>
      'No LXNS scores for this friend. They need to join the ChiffonMai leaderboard and refresh their data.';

  @override
  String get svcChooseAtLeastOneResultScreenImage =>
      'Choose at least one result screen image first';

  @override
  String svcUpToP0ImagesCanBeRecognized(String p0, String p1) {
    return 'Up to $p0 images can be recognized at once; $p1 are selected';
  }

  @override
  String svcP0ExceedsThe8MiBLimitP1(String p0, String p1) {
    return '$p0 exceeds the 8 MiB limit ($p1 MiB)';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub2 =>
      'Not signed in to maimai Score Hub, so this recognition service is unavailable';

  @override
  String svcNoImagesOrTooManyImagesP0(String p0) {
    return 'No images, or too many images$p0';
  }

  @override
  String get svcYourSignInHasExpiredSignIn =>
      'Your sign-in has expired. Sign in to maimai Score Hub again.';

  @override
  String get svcAnImageExceedsThe8MiBLimit =>
      'An image exceeds the 8 MiB limit';

  @override
  String get svcUnsupportedImageFormatOnlyJPEGPNGWebP =>
      'Unsupported image format (only JPEG / PNG / WebP)';

  @override
  String get svcTheOCRServiceReturnedAResultThat =>
      'The OCR service returned a result that could not be parsed';

  @override
  String get svcTheOCRServiceIsUnavailableTryAgain =>
      'The OCR service is unavailable. Try again later.';

  @override
  String get svcOCRRecognitionTimedOutTryAgainLater =>
      'OCR recognition timed out. Try again later.';

  @override
  String svcRecognitionFailedHTTPP0P1(String p0, String p1) {
    return 'Recognition failed (HTTP $p0)$p1';
  }

  @override
  String get svcAccountDataIsUpdatingTryAgainWhen =>
      'Account data is updating. Try again when it finishes.';

  @override
  String get svcCouldNotSaveAccountRecoveryInformation =>
      'Could not save account recovery information';

  @override
  String get svcTheAccountChangedSoTheDataRefresh =>
      'The account changed, so the data refresh after this sync was skipped';

  @override
  String get svcTheReturnedDataBelongsToAnotherAccount =>
      'The returned data belongs to another account; this automatic refresh was cancelled';

  @override
  String get svcCouldNotRollBackTheAccountArchive =>
      'Could not roll back the account archive';

  @override
  String get svcCouldNotIdentifyTheAccountToRestore =>
      'Could not identify the account to restore';

  @override
  String get svcCouldNotSaveHistoryMigrationInformation =>
      'Could not save history migration information';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit =>
      'User files exceed the backup size limit. Reduce custom chart archives and try again.';

  @override
  String get svcTheUserFilesInTheBackupHave =>
      'The user files in the backup have an invalid format';

  @override
  String get svcInvalidUserFileEntry => 'Invalid user file entry';

  @override
  String get svcInvalidUserFilePath => 'Invalid user file path';

  @override
  String get svcInvalidUserFileContent => 'Invalid user file content';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit2 =>
      'User files exceed the backup size limit';

  @override
  String get svcTheUserFileFolderCannotBeA =>
      'The user file folder cannot be a symbolic link';

  @override
  String get svcUserFilesCannotBeSymbolicLinks =>
      'User files cannot be symbolic links';

  @override
  String get svcCouldNotWriteTheAccountArchive =>
      'Could not write the account archive';

  @override
  String get svcTheAccountArchiveHasAnInvalidFormat =>
      'The account archive has an invalid format';

  @override
  String get svcCouldNotRestoreTheAccountArchive =>
      'Could not restore the account archive';

  @override
  String svcRefreshTheTargetP0AccountSData(String p0) {
    return 'Refresh the target $p0 account\'s data first to keep its combo and sync marks';
  }

  @override
  String svcTheP0ScoreCacheIsInvalidRefresh(String p0) {
    return 'The $p0 score cache is invalid. Refresh data first.';
  }

  @override
  String svcLoadedP0FromTheLocalCache(String p0) {
    return 'Loaded $p0 from the local cache';
  }

  @override
  String get svcAudio => 'audio';

  @override
  String get svcAudioFile => 'audio file';

  @override
  String svcDownloadingP0(String p0) {
    return 'Downloading $p0…';
  }

  @override
  String get svcTheResponseIsNotAMediaFile =>
      'The response is not a media file';

  @override
  String get svcTheMediaFileIsIncompleteOrHas =>
      'The media file is incomplete or has an invalid format';

  @override
  String get svcFileCached => 'File cached';

  @override
  String svcMediaDownloadFailedP0(String p0) {
    return 'Media download failed: $p0';
  }

  @override
  String svcP0AddedP1UpdatedP2SkippedP3(
      String p0, String p1, String p2, String p3) {
    return '$p0 added · $p1 updated · $p2 skipped ($p3 on the cabinet)';
  }

  @override
  String get svcTheAWMCNETScoreImportTokenHas =>
      'The AWMC NET score import token has not been set';

  @override
  String get svcPasteOrScanTheCabinetSignIn =>
      'Paste or scan the cabinet sign-in QR code first';

  @override
  String svcRefusedARequestToANonAWMC(String p0) {
    return 'Refused a request to a non-AWMC NET address: $p0';
  }

  @override
  String svcImportTimedOutAfterP0SecondsLarge(String p0) {
    return 'Import timed out after $p0 seconds. Large cabinet data takes longer; try again later.';
  }

  @override
  String svcCouldNotConnectToAWMCNETP0(String p0) {
    return 'Could not connect to AWMC NET: $p0';
  }

  @override
  String get svcAWMCNETReturnedUnrecognizedData =>
      'AWMC NET returned unrecognized data';

  @override
  String svcCouldNotParseTheAWMCNETResponse(String p0) {
    return 'Could not parse the AWMC NET response: $p0';
  }

  @override
  String get svcTheAWMCNETImportTokenIsInvalid2 =>
      'The AWMC NET import token is invalid. Regenerate it at the bottom of the net.wmc.pub settings page.';

  @override
  String get svcTheAWMCNETImportTokenIsMissing =>
      'The AWMC NET import token is missing';

  @override
  String get svcTheCabinetQRCodeIsInvalidOr =>
      'The cabinet QR code is invalid or expired. Get a new one from the official account or cabinet and retry.';

  @override
  String svcAWMCNETRejectedTheRequestP0(String p0) {
    return 'AWMC NET rejected the request: $p0';
  }

  @override
  String get svcInvalidParameters => 'invalid parameters';

  @override
  String svcTooManyAWMCNETRequestsTryAgain(String p0) {
    return 'Too many AWMC NET requests. Try again later.\n$p0';
  }

  @override
  String svcAWMCNETChimeUserReadFailed(String p0) {
    return 'Could not read cabinet scores: Chime could not retrieve the user (code 3002, HTTP $p0). Try a new QR code. If it still fails, try again later or use quick sync with an already linked cabinet identity.';
  }

  @override
  String svcAWMCNETServerErrorHTTPP0Try(String p0) {
    return 'AWMC NET server error (HTTP $p0). Try again later.';
  }

  @override
  String svcAWMCNETReturnedHTTPP0(String p0) {
    return 'AWMC NET returned HTTP $p0';
  }

  @override
  String get svcNoDivingFishImportTokenYetSign =>
      'No Diving-Fish Import-Token yet. Sign in to your Diving-Fish account first.';

  @override
  String svcCouldNotConnectToDivingFishP0(String p0) {
    return 'Could not connect to Diving-Fish: $p0';
  }

  @override
  String get svcTheImportTokenIsWrongOrThe =>
      'The import token is wrong or the request format is invalid';

  @override
  String get svcYourSignInIsInvalidSignIn =>
      'Your sign-in is invalid. Sign in to Diving-Fish again.';

  @override
  String svcSyncFailedHTTPP0P1(String p0, String p1) {
    return 'Sync failed (HTTP $p0)$p1';
  }

  @override
  String get svcDivingFishDidNotAcceptThisScore =>
      'Diving-Fish did not accept this score (the song did not match, or that difficulty does not exist for it). Check the title and difficulty.';

  @override
  String get svcUTAGEChartsCannotBeSyncedLXNSDifficulty =>
      'UTAGE charts cannot be synced: LXNS difficulty indexes do not cover UTAGE';

  @override
  String svcDifficultyIndexP0IsOutsideTheLXNS(String p0) {
    return 'Difficulty index $p0 is outside the LXNS range (0–4)';
  }

  @override
  String get svcYourLXNSAccountIsNotAuthorizedComplete =>
      'Your LXNS account is not authorized. Complete OAuth in Links & authorization, or paste a personal API key in the LXNS status bar on the OCR page.';

  @override
  String svcCouldNotConnectToLXNSP0(String p0) {
    return 'Could not connect to LXNS: $p0';
  }

  @override
  String get svcLXNSAuthorizationExpiredOrTheKeyIs =>
      'LXNS authorization expired or the key is invalid. Authorize again or paste a key.';

  @override
  String get svcLXNSRejectedThisWriteInsufficientPermissions =>
      'LXNS rejected this write (insufficient permissions)';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatDataIs =>
      'LXNS returned an unexpected format: data is empty';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatData0 =>
      'LXNS returned an unexpected format: data[0] is not an object';

  @override
  String get svcThisUserHasNotAuthorizedTheApp =>
      'This user has not authorized the app. Finish linking and try again.';

  @override
  String get svcAuthenticationFailedTryAgain =>
      'Authentication failed. Try again.';

  @override
  String get svcNoPermissionToAccessThisUserS =>
      'No permission to access this user\'s data';

  @override
  String get svcTodaySQueryLimitHasBeenReached =>
      'Today\'s query limit has been reached. Try again later.';

  @override
  String svcRequestFailedStatusCodeP0(String p0) {
    return 'Request failed (status code $p0)';
  }

  @override
  String get svcConnectionCancelled => 'Connection cancelled';

  @override
  String get svcDisconnectedReconnectAndTryAgain =>
      'Disconnected. Reconnect and try again.';

  @override
  String get svcDisconnectedTheCoverReadyStatusWasNot =>
      'Disconnected; the cover-ready status was not sent';

  @override
  String get svcDisconnectedThisGuessWasNotSubmittedReconnect =>
      'Disconnected; this guess was not submitted. Reconnect and try again.';

  @override
  String get svcDisconnectedReconnectBeforeLeavingTheRoom =>
      'Disconnected. Reconnect before leaving the room.';

  @override
  String get svcEnterAQQNumber => 'Enter a QQ number';

  @override
  String svcAWMCNETQueryTimedOutP0S(String p0) {
    return 'AWMC NET query timed out ($p0 s). Check your network and try again.';
  }

  @override
  String svcAWMCNETConnectionFailedP0(String p0) {
    return 'AWMC NET connection failed: $p0';
  }

  @override
  String svcAWMCNETReturnedDataThatCouldNot(String p0) {
    return 'AWMC NET returned data that could not be parsed: $p0';
  }

  @override
  String get svcAWMCNETReturnedAnUnrecognizedDataStructure =>
      'AWMC NET returned an unrecognized data structure (missing records)';

  @override
  String svcAWMCNETHasNoDataForQQ(String p0) {
    return 'AWMC NET has no data for QQ $p0.\nMake sure this QQ is linked on net.wmc.pub and has uploaded scores.';
  }

  @override
  String svcTheAWMCNETDeveloperKeyIsInvalid(String p0) {
    return 'The AWMC NET developer key is invalid or expired (HTTP $p0)';
  }

  @override
  String svcAWMCNETReturnedAnUnknownStatusHTTP(String p0, String p1) {
    return 'AWMC NET returned an unknown status: HTTP $p0$p1';
  }

  @override
  String svcInvalidQQNumber512DigitsExpected(String p0) {
    return 'Invalid QQ number (5–12 digits expected): $p0';
  }

  @override
  String svcAWMCNETHasNoDataForQQ2(String p0) {
    return 'AWMC NET has no data for QQ $p0 (make sure it is linked on net.wmc.pub and has uploaded scores)';
  }

  @override
  String get svcAWMCNETRejectedTheRequestDaysIs =>
      'AWMC NET rejected the request: days is out of range (1–365)';

  @override
  String svcAWMCNETReturnedJSONThatCouldNot(String p0) {
    return 'AWMC NET returned JSON that could not be parsed: $p0';
  }

  @override
  String get svcTheAWMCNETResponseHasNoPoints =>
      'The AWMC NET response has no points array';

  @override
  String svcP0MsOfflineMode(String p0) {
    return '$p0 ms (offline mode)';
  }

  @override
  String get svcLoadingTheSongAliasDatabase =>
      'Loading the song alias database...';

  @override
  String get svcInitializingTheMaidataManager =>
      'Initializing the maidata manager...';

  @override
  String get svcFetchingAllMaidataTheFirstLoadMay =>
      'Fetching all maidata...\n(The first load may be slow. Please wait.)';

  @override
  String get svcLoadingMaidataFromCache => 'Loading maidata from cache...';

  @override
  String get svcSyncingSongInfoAndDifficultyData =>
      'Syncing song info and difficulty data...';

  @override
  String get svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd =>
      'Loading collectibles, tags, songs, knowledge base, and more...';

  @override
  String get svcBuildingSongMappings => 'Building song mappings...';

  @override
  String get svcTheExportCanvasIsNotReady => 'The export canvas is not ready';

  @override
  String get svcDiscoveringBaseMaidata => 'Discovering base maidata…';

  @override
  String svcFetchingMaidataP0P1(String p0, String p1) {
    return 'Fetching maidata: $p0/$p1';
  }

  @override
  String svcFoundP0MaidataFiles(String p0) {
    return 'Found $p0 maidata files';
  }

  @override
  String get svcTheLogWasExportedAutomaticallyYouCan =>
      'The log was exported automatically. You can send it to the developer.';

  @override
  String get svcLogExportFailedYouCanExportIt =>
      'Log export failed. You can export it manually from \"Print log\".';

  @override
  String get svcTheGatewayCouldNotReachItsOrigin =>
      'The gateway could not reach its origin: the CDN returned an error page with invalid headers (SpeedOnline). This is usually a gateway/origin timeout; try again later.';

  @override
  String svcRequestFailedP0(String p0) {
    return 'Request failed: $p0';
  }

  @override
  String get svcSuccess => 'Success';

  @override
  String get svcTheServerHasNoAWMCDeveloperKey =>
      'The server has no AWMC developer key configured. Contact the administrator.';

  @override
  String get svcHTTP401TokenMissingOrInvalid =>
      'HTTP 401: token missing or invalid';

  @override
  String get svcHTTP403InsufficientBalanceRedeemTokensIn =>
      'HTTP 403: insufficient balance. Redeem tokens in the console first.';

  @override
  String svcHTTPP0TheGatewayOrUpstreamFailed(String p0) {
    return 'HTTP $p0: the gateway or upstream failed to forward';
  }

  @override
  String svcUsedP0Tokens(String p0) {
    return 'Used $p0 tokens';
  }

  @override
  String get svcTheRequestDidNotSucceedNoTokens =>
      'The request did not succeed; no tokens were charged under the official rules';

  @override
  String get svcCouldNotReadTheRefreshSettingsRefresh =>
      'Could not read the refresh settings. Refresh data manually.';

  @override
  String get svcTheRefreshSourceDiffersFromTheSync =>
      'The refresh source differs from the sync target; automatic refresh was skipped';

  @override
  String get svcTheRefreshAccountDiffersFromTheSync =>
      'The refresh account differs from the sync target; automatic refresh was skipped';

  @override
  String get svcTheAccountOrSyncCredentialsChangedAutomatic =>
      'The account or sync credentials changed; automatic refresh was skipped';

  @override
  String get svcCouldNotLoadTheGateListRight =>
      'Could not load the gate list right now';

  @override
  String get svcCouldNotLoadTheGuideRightNow =>
      'Could not load the guide right now';

  @override
  String get svcTheGuideDataDoesNotMatch => 'The guide data does not match';

  @override
  String get svcReadAndAcceptTheUserAgreementAnd =>
      'Read and accept the User Agreement and Privacy Policy first';

  @override
  String get svcCouldNotSaveTheOnboardingConfirmationTry =>
      'Could not save the onboarding confirmation. Try again.';

  @override
  String get svcCreatingTheRoomTimedOutCheckYour =>
      'Creating the room timed out. Check your connection and try again.';

  @override
  String get svcJoiningTheRoomTimedOutCheckThe =>
      'Joining the room timed out. Check the room code and your network.';

  @override
  String svcCouldNotLoadReleaseDataP0(String p0) {
    return 'Could not load release data ($p0)';
  }

  @override
  String get svcInvalidReleaseData => 'Invalid release data';

  @override
  String get svcInvalidFriendLinkDataFormat =>
      'Invalid friend link data format';

  @override
  String get svcSaveFailed => 'Save failed';

  @override
  String svcCouldNotParseTheRecognitionResultJSON(String p0) {
    return 'Could not parse the recognition result JSON: $p0';
  }

  @override
  String svcRecognitionRequestFailedP0(String p0) {
    return 'Recognition request failed: $p0';
  }

  @override
  String get gainBelowS => 'below S';

  @override
  String gainRaiseTo(String p0) {
    return 'reach $p0';
  }

  @override
  String gainWithinGrade(String p0) {
    return 'improve within $p0';
  }

  @override
  String gainBasisMember(String p0, String p1, String p2, String p3) {
    return '$p0; chart RA in $p1: $p2→$p3';
  }

  @override
  String gainBasisReplace(
      String p0, String p1, String p2, String p3, String p4) {
    return '$p0; RA $p1 replaces the lowest $p2 chart \"$p3\" (RA $p4)';
  }

  @override
  String gainBasisFill(String p0, String p1, String p2) {
    return '$p0; RA $p1 fills an empty $p2 slot';
  }

  @override
  String gainNetGainReason(String p0, String p1) {
    return 'Standalone net gain +$p0 ($p1)';
  }

  @override
  String gainExploreReason(String p0, String p1) {
    return 'Median of your best scores at this level: $p0% · Standalone net gain +$p1 (a conditional estimate, not a success rate)';
  }

  @override
  String gainAlternativeChallenge(String p0, String p1) {
    return '; challenge option $p0% (standalone net gain +$p1, not added to the safe target)';
  }

  @override
  String gainFillNoteExhausted(String p0) {
    return '$p0 eligible new candidates; none left';
  }

  @override
  String gainFillNoteFiltered(String p0) {
    return '$p0 eligible new candidates; the rest were filtered by feedback or eligibility';
  }

  @override
  String get accountAuthorizeLXNS => 'Authorize LXNS account';

  @override
  String get accountLinkAWMC => 'Link AWMC NET account';

  @override
  String get accountSwitchCachedSubtitle =>
      'Switch data source and player using local caches';

  @override
  String get accountAuthorizeLXNSSubtitle =>
      'Manage LXNS score reading authorization';

  @override
  String get accountLinkAWMCSubtitle =>
      'Set the QQ ID for AWMC NET score lookup';

  @override
  String get accountCabinetIdentitySubtitle =>
      'Link the cabinet identity shared by quick sync';

  @override
  String get accountAuthorizeLXNSFirst =>
      'First authorize LXNS in Me → Accounts and authorization → Links & authorization.';

  @override
  String get accountLinkAWMCFirst =>
      'First set a QQ ID in Me → Accounts and authorization → Links & authorization.';

  @override
  String get accountConfigurationSaved =>
      'Account settings saved. Refresh data to update scores.';

  @override
  String get accountAuthorizationFailed =>
      'Authorization or saving failed. Check your connection and input, then try again.';

  @override
  String get accountLXNSAuthorized => 'LXNS account authorized';

  @override
  String get accountLXNSAuthorizedSubtitle =>
      'Authorized. Refresh scores or tap to authorize again.';

  @override
  String get accountAWMCLinked => 'AWMC NET account linked';

  @override
  String accountAWMCLinkedSubtitle(String qq) {
    return 'Linked QQ: $qq. Tap to change accounts.';
  }

  @override
  String get accountCabinetLinkedSubtitle =>
      'Quick sync identity saved. Tap to link again.';

  @override
  String get accountBindingManage => 'Links & authorization';

  @override
  String get accountBindingManageSubtitle =>
      'Sign in, authorize and link your data source accounts';

  @override
  String get accountBindingScoreHub => 'maimai Score Hub';

  @override
  String get accountBindingDivingFish => 'Diving-Fish';

  @override
  String get accountBindingLxns => 'LXNS';

  @override
  String get accountBindingAwmc => 'AWMC NET';

  @override
  String get accountBindingCabinet => 'Cabinet ID';

  @override
  String get accountBindingSignedIn => 'Signed in';

  @override
  String get accountBindingSignedOut => 'Signed out';

  @override
  String get accountBindingAuthorized => 'Authorized';

  @override
  String get accountBindingUnauthorized => 'Not authorized';

  @override
  String get accountBindingLinked => 'Linked';

  @override
  String get accountBindingUnlinked => 'Not linked';

  @override
  String get accountBindingDivingFishAuth => 'Diving-Fish auth';

  @override
  String get accountBindingUnknown => 'Unknown';

  @override
  String get accountBindingRecheck => 'Check again';

  @override
  String get syncDialogMode => 'Sync mode';

  @override
  String get syncDialogQrCode => 'Cabinet QR code';

  @override
  String get languageTranslationDisclaimer =>
      'All languages other than Simplified Chinese are translations and may contain inaccurate or unnatural wording. If a translation differs in meaning, the Simplified Chinese text prevails. Song data, server-provided text and user content are not translated. Please report translation issues through Feedback.';

  @override
  String get accountSwitchSaved => 'Account saved';

  @override
  String get accountSwitchNotSaved => 'No account saved';

  @override
  String get accountSwitchCurrent => 'In use';

  @override
  String get customTagTitle => 'Custom tags';

  @override
  String get customTagFeatureSubtitle =>
      'Name, color and charts of your own tags, usable in tag filters and stats';

  @override
  String get customTagGroupName => 'Custom';

  @override
  String get customTagIntro =>
      'Custom tags appear alongside chart tags in song search tag filters, chart details, Best50 / favorites tag stats and Tag 50 in personalized Best50. They are stored on this device and included in data backups.';

  @override
  String get customTagCreate => 'New tag';

  @override
  String get customTagEdit => 'Edit tag';

  @override
  String get customTagName => 'Tag name';

  @override
  String get customTagColor => 'Tag color';

  @override
  String get customTagHue => 'Hue';

  @override
  String get customTagPreview => 'Preview';

  @override
  String get customTagNameRequired => 'Enter a tag name';

  @override
  String get customTagNameDuplicate => 'A tag with this name already exists';

  @override
  String get customTagSaveFailed => 'Could not save custom tags. Try again.';

  @override
  String get customTagForChart => 'Custom tags for this chart';

  @override
  String get customTagEmpty => 'No custom tags yet. Create one first.';

  @override
  String get customTagAddToChart => 'Add custom tag';

  @override
  String get customTagManage => 'Manage';

  @override
  String get customTagSearchHint => 'Search by title, alias, artist or ID';

  @override
  String get customTagNoSongs => 'No songs found';

  @override
  String get customTagChooseDifficulties => 'Choose difficulties';

  @override
  String get customTagAddCharts => 'Add charts';

  @override
  String get customTagRemoveChart => 'Remove from tag';

  @override
  String get customTagDelete => 'Delete';

  @override
  String get customTagDeleteTitle => 'Delete tag';

  @override
  String customTagChartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charts',
      one: '1 chart',
    );
    return '$_temp0';
  }

  @override
  String customTagDeleteMessage(String name) {
    return 'Deleting \"$name\" removes it from every chart. This cannot be undone.';
  }

  @override
  String accountSwitchCurrentLabel(String name) {
    return 'Current: $name';
  }

  @override
  String customTagMarked(String name) {
    return '$name (custom)';
  }

  @override
  String get chartCodeFont => 'Code font';

  @override
  String get chartCodeFontDefault => 'Default';

  @override
  String get chartCodeFontSaveFailed =>
      'Font changed, but the choice could not be saved';

  @override
  String get ratingSegmentTitle => 'Rating potential and score table steps';

  @override
  String get ratingSegmentStandard => 'Standard';

  @override
  String get ratingSegmentDetailed => 'Detailed';

  @override
  String get ratingSegmentStandardHint =>
      'Show only the achievement steps for each rank.';

  @override
  String get ratingSegmentDetailedHint =>
      'Also show the achievement needed for every +1 Rating.';

  @override
  String get searchAvoidKeyboard => 'Keep search above the keyboard';

  @override
  String get searchAvoidKeyboardHint =>
      'In home search, song lookup, international song lookup and score lookup, results can scroll fully above the keyboard. The background stays in place.';

  @override
  String get arcadeTabInView => 'In view';

  @override
  String get arcadeTabFavorites => 'Saved';

  @override
  String get arcadeOpenNow => 'Open';

  @override
  String get arcadeClosedNow => 'Closed';

  @override
  String get arcadeHoursUnknown => 'Hours unknown';

  @override
  String arcadeClosesAt(String p0) {
    return 'Closes $p0';
  }

  @override
  String arcadeOpensAt(String p0) {
    return 'Opens $p0';
  }

  @override
  String arcadeOpensTomorrowAt(String p0) {
    return 'Opens tomorrow $p0';
  }

  @override
  String get arcadeClearFilters => 'Clear filters';

  @override
  String get arcadeRandomPick => 'Pick one at random';

  @override
  String get arcadeRandomEmpty => 'No arcades to pick from here';

  @override
  String get arcadeZoomIn => 'Zoom in';

  @override
  String get arcadeZoomOut => 'Zoom out';

  @override
  String get arcadeResetNorth => 'Face north';

  @override
  String get arcadeLocate => 'Go to my location';

  @override
  String get arcadeRegions => 'Worldwide';

  @override
  String get arcadeRegionCount => 'Regions';

  @override
  String get arcadeShopCount => 'Arcades';

  @override
  String get arcadeMachineCount => 'Machines';

  @override
  String get arcadeDownloadData => 'Download arcade data';

  @override
  String get arcadeNoDataHint =>
      'Once downloaded, you can browse arcades offline.';

  @override
  String arcadeUpdating(String p0, String p1) {
    return 'Updating $p0 / $p1';
  }

  @override
  String get arcadeUpdateFailed => 'Update failed. Your current data was kept.';

  @override
  String get arcadeNoMatchTitle => 'No matching arcades';

  @override
  String get arcadeNoMatchHint => 'Try other filters, or move the map.';

  @override
  String get arcadeNoFavoritesTitle => 'No saved arcades yet';

  @override
  String get arcadeNoFavoritesHint =>
      'Tap the star on arcades you visit often to find them here.';

  @override
  String get arcadeNeedsUpdateToFavorite =>
      'Update the arcade data first to save arcades.';

  @override
  String get arcadeLegacyHint =>
      'This data is outdated. Update it to save arcades and see metro info.';

  @override
  String get arcadeNavigate => 'Directions';

  @override
  String get arcadeCopyAddress => 'Copy address';

  @override
  String get arcadeViewOnNearcade => 'View on nearcade';

  @override
  String get arcadeCouldNotOpenLink => 'Could not open the link';

  @override
  String get arcadeHours => 'Opening hours';

  @override
  String get arcadeEveryDay => 'Every day';

  @override
  String get arcadeToday => 'Today';

  @override
  String arcadeMetroWalk(String p0, String p1) {
    return '$p0 · about $p1 min walk';
  }

  @override
  String arcadeMetroStation(String p0) {
    return '$p0';
  }

  @override
  String get arcadeNote => 'Notes';

  @override
  String arcadeFromYou(String p0) {
    return '$p0 away';
  }

  @override
  String get arcadeFilterAction => 'Filter';

  @override
  String get arcadeFilterSearchHint => 'Search machines';

  @override
  String get arcadeFilterEmpty => 'No matching machines';

  @override
  String get arcadeChooseMapApp => 'Choose a map app';

  @override
  String get arcadeMapAmap => 'Amap';

  @override
  String get arcadeMapBaidu => 'Baidu Maps';

  @override
  String get arcadeMapTencent => 'Tencent Maps';

  @override
  String get arcadeMapGoogle => 'Google Maps';

  @override
  String get arcadeMapApple => 'Apple Maps';

  @override
  String get arcadeMapOther => 'Other map apps';

  @override
  String get arcadeMapWeb => 'Open in browser';
}
