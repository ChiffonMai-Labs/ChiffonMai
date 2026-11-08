// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get autoUpdateSuccessTitle => '自動更新が完了しました';

  @override
  String get autoUpdateSuccessBody =>
      'ChiffonMaiのバックグラウンド更新が完了しました。引き続きご利用いただけます。';

  @override
  String get autoUpdateChangesTitle => '今回の更新内容';

  @override
  String get settingsTitle => 'システム設定';

  @override
  String get appearance => '外観';

  @override
  String get interaction => '操作';

  @override
  String get effects => 'エフェクト';

  @override
  String get other => 'その他';

  @override
  String get language => '言語';

  @override
  String get followSystem => 'システムに従う';

  @override
  String get languageDescription =>
      '画面・メッセージ・システム通知が多言語に対応しています。楽曲データ・サーバーの原文・ユーザーの投稿は原文のまま表示されます。切り替えるとすぐに反映されます。';

  @override
  String get languageSaveFailed => '言語設定を保存できませんでした。もう一度お試しください。';

  @override
  String get homeSearchScope => 'ホームの検索対象';

  @override
  String get searchFeatures => '機能';

  @override
  String get searchSongs => '楽曲';

  @override
  String get searchBoth => '両方';

  @override
  String get searchMode => '検索方法';

  @override
  String get searchInline => 'その場で入力';

  @override
  String get searchOverlay => '検索画面を開く';

  @override
  String get searchOverlayHint => 'ホームの機能や楽曲の検索を専用の画面で行います。';

  @override
  String get searchInlineHint => '元の検索欄に直接入力します。楽曲の検索履歴は検索欄の下に表示されます。';

  @override
  String get showMatchInfo => '一致した項目を表示';

  @override
  String get showMatchInfoHint => '検索結果に一致した譜面定数、BPM、タグなどを表示します。';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get themeColor => 'テーマカラー';

  @override
  String get backgroundImage => '背景画像';

  @override
  String get decorationImage => '装飾画像';

  @override
  String get pureBlackBackgroundDisabled => '完全な黒のモードでは背景画像と装飾画像を調整できません。';

  @override
  String get reading => '読み込み中…';

  @override
  String get useSystemWallpaperColor => 'システムの壁紙色を使用';

  @override
  String get systemWallpaperHint =>
      'Android 12 以降で利用できます。現在のシステム配色をテーマカラーに適用します。';

  @override
  String get wallpaperColorUnsupported => '壁紙の配色には Android 12 以降が必要です。';

  @override
  String get wallpaperColorApplied => '壁紙の配色を適用しました。';

  @override
  String get wallpaperColorFailed => '壁紙の配色を読み取れませんでした。しばらくしてからお試しください。';

  @override
  String get wallpaperApplied => '壁紙を設定しました。';

  @override
  String get wallpaperAndThemeApplied => '壁紙を設定し、テーマカラーを更新しました。';

  @override
  String get backgroundReset => '背景を初期設定に戻しました。';

  @override
  String get themeColorUpdated => 'テーマカラーを更新しました。';

  @override
  String get themeColorReset => 'テーマカラーを初期設定に戻しました。';

  @override
  String get navigationExperience => 'ナビゲーション';

  @override
  String get searchInteraction => '検索欄の動作';

  @override
  String get confetti => '紙吹雪';

  @override
  String get appUpdate => 'アプリの更新';

  @override
  String get featureGuide => '機能ガイド';

  @override
  String get featureGuideHint => '各機能の場所を確認したいときは、いつでもガイドを開けます。';

  @override
  String get reopenGuide => '機能ガイドをもう一度見る';

  @override
  String get preview => 'プレビュー';

  @override
  String get primaryButton => 'メインボタン';

  @override
  String get primaryColor => 'メイン';

  @override
  String get secondaryColor => 'サブ';

  @override
  String get tertiaryColor => 'アクセント';

  @override
  String get surfaceColor => '背景';

  @override
  String get customColor => '色を指定';

  @override
  String get restoreDefaults => '初期設定に戻す';

  @override
  String get builtInBackground => '現在：標準の背景';

  @override
  String get customBackground => '現在：指定した画像';

  @override
  String get processing => '処理中…';

  @override
  String get chooseFromGallery => '写真から選ぶ';

  @override
  String get decorationOpacity => 'Chiffon 装飾画像の不透明度';

  @override
  String get decorationOpacityHint =>
      '初期値は 40%。完全な黒のモードでは非表示になり、ライトとダークで同じ値を使用します。';

  @override
  String get hide => '非表示';

  @override
  String get favoriteExportExtension => 'お気に入りの拡張子';

  @override
  String get syncAndGateway => '同期とゲートウェイ';

  @override
  String get gatewayTimeout => 'AWMC ゲートウェイのタイムアウト';

  @override
  String get gatewayTimeoutHint =>
      '回線 1 は同期前に GET /v1/health で接続を確認します。時間を超えると、トークンを消費せずに同期を中止します。';

  @override
  String get gatewayTimeoutDialogHint =>
      '回線 1 は同期前に GET /v1/health で接続を確認します。応答が時間内に返らない場合は、トークンを消費せずに同期を中止します。';

  @override
  String get enterIntegerSeconds => '秒数を整数で入力してください。';

  @override
  String get timeout => 'タイムアウト';

  @override
  String get secondsUnit => '秒';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get confirm => '決定';

  @override
  String get backgroundOpacity => '背景の覆いの濃さ';

  @override
  String get backgroundDarkHint => '値を上げるほど背景が暗くなります。0% で元の画像を表示します。';

  @override
  String get backgroundLightHint => '値を上げるほど背景が薄くなります。0% で元の画像を表示します。';

  @override
  String get lightMode => 'ライト';

  @override
  String get darkMode => 'ダーク';

  @override
  String get pureBlack => '完全な黒';

  @override
  String get pureBlackHint => '背景を完全な黒にして、背景画像を非表示にします。';

  @override
  String get navigationStyle => 'ナビゲーションバーの表示';

  @override
  String get navigationClassic => 'クラシック';

  @override
  String get navigationGlass => 'ガラス';

  @override
  String get navigationPill => 'カプセル';

  @override
  String get navigationClassicHint => 'アイコンの下にすべてのカテゴリ名を常に表示します。';

  @override
  String get navigationGlassHint => '透き通ったガラス風の表示で、選択中の項目を柔らかく強調します。';

  @override
  String get navigationPillHint =>
      '選択中の項目だけ名前を表示し、ほかはアイコンのみになります。切り替え時に滑らかに伸縮します。';

  @override
  String get navigationAnimation => '切替アニメーション';

  @override
  String get navigationAnimationHint => '画面とアイコンを滑らかに切り替えます。';

  @override
  String get swipeNavigation => 'スワイプで切替';

  @override
  String get swipeNavigationHint => '画面の内容を左右にスワイプして、下部のタブを切り替えます。';

  @override
  String get immersiveStatusBar => 'ステータスバーを隠す';

  @override
  String get immersiveStatusBarHint => '上部の時刻や電池残量などを隠し、下部のシステムナビゲーションは表示します。';

  @override
  String get busyHint => '処理中の説明';

  @override
  String get busyHintDescription => '同期や更新の処理中に、使えない項目の理由を赤字で表示します。';

  @override
  String get customHarmonyColor => '調和色を指定';

  @override
  String get confettiHint => 'データ更新やスコア同期が成功したときに紙吹雪を表示します。';

  @override
  String get gravityEffect => '重力効果';

  @override
  String get gravityEffectHint => '紙吹雪が弧を描いて舞い、上に飛んだ紙も下に落ちます。';

  @override
  String get harmonyColor => '調和色';

  @override
  String get harmonyLevel => '色の調和度';

  @override
  String get harmonyHint => '値を上げるほど紙吹雪が調和色に近づきます。0% で鮮やかな多色表示になります。';

  @override
  String get paperType => '紙吹雪の形';

  @override
  String get paperMixed => 'ミックス';

  @override
  String get paperSquare => '四角';

  @override
  String get paperCircle => '丸';

  @override
  String get paperRibbon => 'リボン';

  @override
  String get burstPosition => '表示位置';

  @override
  String get burstTopBottom => '上下';

  @override
  String get burstLeftRight => '左右';

  @override
  String get burstAllEdges => '全方向';

  @override
  String get previewNow => '今すぐプレビュー';

  @override
  String get defaultDifficulty => '楽曲詳細の初期難易度';

  @override
  String get defaultDifficultyHint =>
      '楽曲検索など、難易度の指定がない場所から開くときに、この難易度を優先して表示します。';

  @override
  String get defaultDifficultyNote =>
      '初回は MASTER です。スコアや譜面などで難易度が指定されている場合は、その難易度を表示します。';

  @override
  String get settingSaveFailed => '設定を保存できませんでした。もう一度お試しください。';

  @override
  String get autoInstall => '更新を自動インストール';

  @override
  String get experimental => '試験機能';

  @override
  String get autoInstallHint =>
      '初期設定はオフで、自動ダウンロードは行いません。アプリ内で開始したダウンロードのみが対象です。検証完了後、前面では確認を表示し、同意後にバックグラウンドへ移ってインストールを試みます。バックグラウンドでは、同期・更新・読み込み・書き出し・ダウンロードなどの処理がない状態が 8 秒続くと、自動でインストールを試みます。処理の開始やアプリへの復帰で計時をやり直します。';

  @override
  String get autoInstallNote =>
      'Android 12 以降と、この提供元からのインストール許可が必要です。音楽再生中や通話中は待機します。画面のロックは不要です。システムのスケジュールによる遅延や、確認操作が必要な場合があります。その場合は手動でインストールできます。インストール時には旧プロセスが終了します。システムが開始したインストールは、スイッチをオフにしても取り消せません。';

  @override
  String get autoInstallUnsupported => 'このシステムでは試験機能を利用できません。手動で更新してください。';

  @override
  String get allowInstallSource => 'この提供元からのインストールを許可';

  @override
  String get autoInstallSettingsError =>
      '自動インストール設定を適用できません。再試行するか、システムのインストール権限を確認してください。';

  @override
  String get reloadSettings => '設定を再読み込み';

  @override
  String get hexFormatError => '#RRGGBB または #AARRGGBB で入力してください。';

  @override
  String get enterHexColor => '16 進数で色を入力';

  @override
  String get hexColorHint => '#RRGGBB または #AARRGGBB';

  @override
  String get hue => '色相';

  @override
  String get colorPickerHint => '上の四角をドラッグするか、16 進数で色を入力してください。';

  @override
  String get enterHex => '16 進数で入力';

  @override
  String get wallpaperCropHint => 'ピンチで拡大・縮小し、ドラッグで壁紙の範囲を選んでください。';

  @override
  String get wallpaperReadFailed =>
      '画像を読み取れませんでした。このシステムでは画像形式に対応していない可能性があります。';

  @override
  String get wallpaperCropFailed => '画像を切り抜けませんでした。もう一度お試しください。';

  @override
  String get setWallpaper => '壁紙に設定';

  @override
  String picturePickFailed(String error) {
    return '画像を選択できませんでした：$error';
  }

  @override
  String exportDescription(String extension) {
    return 'お気に入りは <名前>$extension として Download/ChiffonMai/收藏夹/ に保存され、ファイル管理アプリから確認できます。\nほかの形式の既定のアプリに影響しないよう、拡張子は固定です。\n読み込みはファイルの内容で判定するため、別の拡張子の古いバックアップも利用できます。';
  }

  @override
  String secondsValue(int seconds) {
    return '$seconds 秒';
  }

  @override
  String gatewayTimeoutSemantics(int seconds) {
    return 'AWMC ゲートウェイのタイムアウト、現在 $seconds 秒';
  }

  @override
  String gatewayTimeoutSaved(int seconds) {
    return 'AWMC ゲートウェイのタイムアウトを $seconds 秒に設定しました。';
  }

  @override
  String allowedSeconds(int min, int max) {
    return '$min～$max 秒で入力してください。';
  }

  @override
  String defaultSecondsHint(int defaultSeconds, int min, int max) {
    return '初期値は $defaultSeconds 秒、設定範囲は $min～$max 秒です。';
  }

  @override
  String get foregroundUpdateTitle => '更新の準備ができました';

  @override
  String get foregroundUpdateBody =>
      '更新ファイルの検証が完了しました。「終了して更新」を選ぶと、アプリがバックグラウンドに移り、インストールを試みます。インストール時にアプリが終了するため、先に操作内容を保存してください。完了後はアプリを開き直してください。';

  @override
  String get foregroundUpdateLaterHint =>
      '「後で」を選ぶと、そのまま使えます。バックグラウンドで処理のない状態が 8 秒続くと、自動インストールを試みます。端末によっては確認操作が必要です。';

  @override
  String get foregroundUpdateBusy => '処理や再生が続いています。終了してから更新してください。';

  @override
  String get foregroundUpdateChanged =>
      'ダウンロードや処理の状態が変わりました。更新の状態をもう一度確認してください。';

  @override
  String get foregroundUpdateFailed =>
      '更新を開始できませんでした。しばらくしてから再試行するか、更新画面から手動でインストールしてください。';

  @override
  String get updateLater => '後で';

  @override
  String get exitAndUpdate => '終了して更新';

  @override
  String get featureSongSearch => '楽曲検索';

  @override
  String get featureSearchTheChinaAndInternationalLibraries => '中国版・海外版の楽曲を検索';

  @override
  String get featureVersionsAndLibraryAnalysis => 'バージョンと楽曲分析';

  @override
  String get featureVersionDetailsUpdateComparisonsAndChartConstants =>
      'バージョン情報・更新比較・譜面定数';

  @override
  String get featureImageRecognition => '画像認識';

  @override
  String get featureFindSongsByCoverArtAndRead => 'ジャケットから楽曲を検索・リザルトを読み取り';

  @override
  String get featureCollectibles => 'コレクション図鑑';

  @override
  String get featureBrowseIconsNameplatesAndOtherCollectibles =>
      'アイコン・ネームプレートなどを閲覧';

  @override
  String get featureSearchAndFilter => '検索と絞り込み';

  @override
  String get featureBrowseScoresAndFilterChartResults => '成績の閲覧と譜面の絞り込み';

  @override
  String get featureGrowthAndComparison => '成長と比較';

  @override
  String get featureReviewImprovementsAndCompareWithFriends =>
      '成長の記録とフレンドの成績を比較';

  @override
  String get featureBest50Overview => 'Best50 概要';

  @override
  String get featureCurrentPerformanceAndFittedPotential => '現在の実力と推定ポテンシャル';

  @override
  String get featurePersonalizedAnalysis => 'カスタム分析';

  @override
  String get featureFilterBest50ByTagsAndConditions => 'タグや条件で Best50 を絞り込み';

  @override
  String get featureGoalsAndScoreCards => '目標と成績画像';

  @override
  String get featureSimulateIdealScoresAndCreateCustomScore =>
      '理想の成績をシミュレーション・成績画像を作成';

  @override
  String get featureRatingRankings => 'Rating ランキング';

  @override
  String get featureOfficialAndFittedRatingRankings =>
      '公式 Rating と推定 Rating のランキング';

  @override
  String get featureAchievementRankings => '達成率ランキング';

  @override
  String get featureCompareAveragePerformanceAcrossAllScores => '全成績の平均を比較';

  @override
  String get featureSpecialRankings => '特殊ランキング';

  @override
  String get featureExplorePlayerStatisticsFromDifferentAngles =>
      'さまざまな視点からプレイヤーデータを表示';

  @override
  String get featureProgressAndChallenges => '進捗とチャレンジ';

  @override
  String get featureVersionTitlesRanksAndKALEIDXSCOPE =>
      'バージョン称号・段位・KALEIDXSCOPE';

  @override
  String get featureCalculators => '計算ツール';

  @override
  String get featureRatingAchievementAndJudgementAnalysis => 'Rating・達成率・判定の逆算';

  @override
  String get featureRandomPicks => 'ランダム選曲';

  @override
  String get featureDecideWhatToPlayToday => '今日遊ぶ曲を決めよう';

  @override
  String get featurePracticeRecommendations => '練習のおすすめ';

  @override
  String get featureChooseChartsByGainTagsGoalsOr => '伸び幅・タグ・目標・定数から譜面を選択';

  @override
  String get featureFavoritesAndPlayQueue => 'お気に入りとプレイ予定';

  @override
  String get featureOrganizeChartsForYourNextArcadeVisit => '次のプレイに向けて譜面を整理';

  @override
  String get featureArcadeMaps => 'ゲームセンターマップ';

  @override
  String get featureFindRhythmGameArcadesInChinaAnd => '中国・世界の音楽ゲーム設置店を検索';

  @override
  String get featureSoloGameSettings => 'ソロゲーム設定';

  @override
  String get featureManageSharedRulesAndModePreferences => '共通ルールとモード別設定を管理';

  @override
  String get featureTextClues => '文字のヒント';

  @override
  String get featureGuessSongsFromMemoryAliasesAndLetters => '記憶・別名・文字から曲を当てる';

  @override
  String get featureCoverArtChallenges => 'ジャケット当て';

  @override
  String get featureTryCroppedPixelatedBlurredFlashAndPuzzle =>
      '部分・ピクセル・ぼかし・瞬間表示・パズル';

  @override
  String get featureAudioChallenges => '音声当て';

  @override
  String get featureIdentifyNormalReversedOrPitchShiftedClips =>
      '通常・逆再生・変速音声から曲を当てる';

  @override
  String get featureChartChallenges => '譜面当て';

  @override
  String get featureGuessSongsFromSilentChartClips => '無音の譜面映像から曲を当てる';

  @override
  String get featureMultiplayer => 'マルチプレイ';

  @override
  String get featureChallengeTheSongLibraryWithFriends => 'フレンドと一緒に楽曲クイズに挑戦';

  @override
  String get featureMusicAndChartPlayback => '音楽と譜面の再生';

  @override
  String get featureListenToMaimaiSongsAndPlayCustom =>
      'maimai の楽曲を聴く・カスタム譜面を再生';

  @override
  String get featureAccountsAndAuthorization => 'アカウントと認証';

  @override
  String get featureManageAccountsAndDataSourceSignIns =>
      'アカウントとデータソースのログイン状態を管理';

  @override
  String get featureSinglePlatformSync => '個別同期';

  @override
  String get featureSyncScoresToEachScoreTracker => '各スコアサービスに成績を同期';

  @override
  String get featureBatchAndScheduledSync => '一括同期と定期同期';

  @override
  String get featureSyncToMultiplePlatformsOrAutomatically => '複数サービスへの同期と自動同期';

  @override
  String get featureRefreshData => 'データ更新';

  @override
  String get featureUpdateCachedScoresAndCabinetPlayCounts =>
      '成績キャッシュと筐体プレイ回数を更新';

  @override
  String get featureLocalData => 'ローカルデータ';

  @override
  String get featureBackUpDataAndManageLocalCaches => 'データのバックアップとキャッシュ管理';

  @override
  String get featureAppPreferences => 'アプリ設定';

  @override
  String get featureThemeInteractionsAndLoadingQuotes => 'テーマ・操作・読み込み時のメッセージ';

  @override
  String get featureDiagnostics => '診断';

  @override
  String get featureCheckServicesAndExportLogs => 'サービス状態の確認とログの書き出し';

  @override
  String get featureCommunityActivity => 'コミュニティ';

  @override
  String get featureBrowseRecentCommentsAndRatings => '最近のコメントと評価を閲覧';

  @override
  String get featureVersionAndProject => 'バージョンとプロジェクト';

  @override
  String get featureUpdatesProjectInformationAndLinks => '更新情報・プロジェクト紹介・関連リンク';

  @override
  String get featureFeedbackAndSupport => 'フィードバックとサポート';

  @override
  String get featureReportIssuesShareIdeasAndSupportDevelopment =>
      '不具合報告・ご意見・開発支援';

  @override
  String get featureSongLookup => '楽曲検索';

  @override
  String get featureSearchByTitleAliasCharterOrTag => '曲名・別名・譜面制作者・タグで検索';

  @override
  String get featureInternationalSongLookup => '海外版楽曲検索';

  @override
  String get featureSearchAndFilterTheInternationalLibrary => '海外版の楽曲を検索・絞り込み';

  @override
  String get featureChinaUpdateComparison => '中国版の更新比較';

  @override
  String get featureFindSongsReleasedInJapanButNot => '日本版に登場し中国版には未収録の曲を表示';

  @override
  String get featureUpdateCalendar => '更新カレンダー';

  @override
  String get featureBrowseChinaChartUpdatesByDate => '中国版の譜面更新を日付で表示';

  @override
  String get featureVersionComparison => 'バージョン比較';

  @override
  String get featureBrowsePlayableSongsByVersion => 'バージョン別に楽曲を表示';

  @override
  String get featureChartConstantDistribution => '譜面定数の分布';

  @override
  String get featureViewTheDistributionOfChartConstants => '譜面定数の分布を表示';

  @override
  String get featureCoverRecognition => 'ジャケット認識';

  @override
  String get featureFindSongsUsingYourCameraOrAn => 'カメラや画像から楽曲を検索';

  @override
  String get featureResultScreenRecognition => 'リザルト認識';

  @override
  String get featurePhotographAResultScreenToReadScores =>
      '筐体のリザルトを撮影して成績を読み取り';

  @override
  String get featureCollectibleLookup => 'コレクション検索';

  @override
  String get featureViewIconsNameplatesAndOtherCollectibles =>
      'アイコン・ネームプレートなどを表示';

  @override
  String get featureScoreLookup => '成績検索';

  @override
  String get featureBrowseAndFilterAllPlayRecords => '全プレイ記録の閲覧と絞り込み';

  @override
  String get featureCustomScoreLookup => 'カスタム成績検索';

  @override
  String get featureViewScoresByLevelOrCharter => 'レベルや譜面制作者で成績を表示';

  @override
  String get featureScoreImprovementHistory => '成績の成長履歴';

  @override
  String get featureReviewDailyChangesToYourBestScores => 'ベスト成績の変化と成長を日別に確認';

  @override
  String get featureRatingHistory => 'Rating 履歴';

  @override
  String get featureTrackRatingOverTime => 'Rating の推移を確認';

  @override
  String get featureFriendComparison => 'フレンド比較';

  @override
  String get featureCompareYourScoresWithAFriend => 'フレンドとの成績の違いを確認';

  @override
  String get featureViewYourCurrentBest35AndBest15 => '現在の Best35 と Best15 を表示';

  @override
  String get featureFittedBest50 => '推定 Best50';

  @override
  String get featureAnalyzeYourPotentialRatingCeiling => '潜在的な Rating 上限を分析';

  @override
  String get featureCustomBest50Analysis => 'カスタム Best50 分析';

  @override
  String get featureFilterBest50ByTag => 'タグで Best50 を絞り込み';

  @override
  String get featureCustomFittedBest50 => 'カスタム推定 Best50';

  @override
  String get featureViewFittedRatingPotentialByTag => 'タグ別に推定 Rating 上限を表示';

  @override
  String get featureIdealBest50 => '理想の Best50';

  @override
  String get featureSimulateBest50WithEveryScoreRaisedOne =>
      '全成績が1ランク上がった Best50 を試算';

  @override
  String get featureCreateBest50 => 'Best50 作成';

  @override
  String get featureFillIn50ScoreCardsManually => '50枚の成績カードを手動入力';

  @override
  String get featureRatingLeaderboard => 'Rating ランキング';

  @override
  String get featureViewPlayerRatingRankings => 'プレイヤーの Rating 順位を表示';

  @override
  String get featureTotalFittedRatingLeaderboard => '推定総 Rating ランキング';

  @override
  String get featureCompareFittedTotalRatingWithOfficialBest50 =>
      '推定総 Rating と公式 Best50 の差を表示';

  @override
  String get featureAverageAchievementLeaderboard => '平均達成率ランキング';

  @override
  String get featureRankByAverageAchievementAcrossAllScores =>
      '全成績の平均達成率で順位を表示';

  @override
  String get featureAverageDXScoreRateLeaderboard => '平均 DX スコア達成率ランキング';

  @override
  String get featureRankByAverageDXScoreRateAcross => '全成績の平均 DX スコア達成率で順位を表示';

  @override
  String get featureSpecialLeaderboards => '特殊ランキング';

  @override
  String get featureDiscoverInterestingPlayerStatistics => 'プレイヤーの面白いデータを発見';

  @override
  String get featureVersionTitleProgress => 'バージョン称号の進捗';

  @override
  String get featureViewVersionsAndTargetTitles => '各バージョンと目標称号を表示';

  @override
  String get featureRankTable => '段位表';

  @override
  String get featureChallengeYourNextRank => '次の段位に挑戦';

  @override
  String get featureExploreAUniqueMaimaiMode => 'maimai の特別なモードを楽しもう';

  @override
  String get featureSongRatingCalculator => '単曲 Rating 計算';

  @override
  String get featureCalculateASongRatingFromAchievement => '達成率から単曲 Rating を計算';

  @override
  String get featureAchievementCalculator => '達成率計算';

  @override
  String get featureCalculateAchievementFromJudgements => '判定内訳から達成率を計算';

  @override
  String get featureReverseAchievementCalculator => '達成率の逆算';

  @override
  String get featureInferBREAKDetailsFromJudgements => '判定内訳から BREAK の詳細を逆算';

  @override
  String get featureDailyRecommendations => '今日のおすすめ';

  @override
  String get featureLetRecommendationsPickYourNextSong => '今日の選曲をおすすめにおまかせ';

  @override
  String get featureRandomSongs => 'ランダム楽曲';

  @override
  String get featureDrawACustomNumberOfRandomSongs => '指定した数の楽曲をランダムに抽選';

  @override
  String get featureArcadeRoulette => 'プレイルーレット';

  @override
  String get featureLetARouletteWheelChooseYourSession => 'ルーレットで今回のプレイ内容を決定';

  @override
  String get featureRatingGainRecommendations => 'Rating アップのおすすめ';

  @override
  String get featureChooseChartsByNetB50GainAlgorithm =>
      'B50 の伸び幅で選曲 · AWMC アルゴリズム';

  @override
  String get featureTagRecommendations => 'タグからおすすめ';

  @override
  String get featureFindSongsBasedOnTagsFromYour => 'プレイ済み譜面のタグから楽曲をおすすめ';

  @override
  String get featureTargetRatingRecommendations => '目標 Rating からおすすめ';

  @override
  String get featureFindChartsThatCanRaiseYourRating => 'Rating アップに適した譜面を検索';

  @override
  String get featureConstantRangeRecommendations => '定数範囲からおすすめ';

  @override
  String get featureChooseChartsWithinAConstantRange => '定数の範囲で譜面を選択';

  @override
  String get featureFavoriteFolders => 'お気に入りフォルダー';

  @override
  String get featureManageYourFavoriteCharts => 'お気に入りの譜面を管理';

  @override
  String get featurePlayNext => '次に遊ぶ曲';

  @override
  String get featureQueueSongsForYourNextArcadeVisit => '次のプレイ予定曲を整理';

  @override
  String get featureChinaRhythmGameMap => '中国の音楽ゲームマップ';

  @override
  String get featureFindArcadesWithTheGamesYouWant => '遊びたいゲームの設置店を検索';

  @override
  String get featureWorldwideArcadeMap => '世界のゲームセンターマップ';

  @override
  String get featureBrowseArcadesWorldwideOnNearCade =>
      'NearCade で世界のゲームセンターを検索';

  @override
  String get featureSoloSongGameSettings => 'ソロ曲当て設定';

  @override
  String get featureManageSharedAndModeSpecificRules => '共通ルールとモード別の設定を管理';

  @override
  String get featureNoClueSongQuiz => 'ヒントなし曲当て';

  @override
  String get featureChallengeTheSongLibraryFromMemory => '記憶だけで楽曲クイズに挑戦';

  @override
  String get featureAliasSongQuiz => '別名で曲当て';

  @override
  String get featureTestYourKnowledgeOfSongAliases => '楽曲の別名で知識を試そう';

  @override
  String get featureMaimaiLetterReveal => 'maimai 文字開け';

  @override
  String get featureGuessSongsFromRevealedLetters => '表示された文字から曲を当てる';

  @override
  String get featureCroppedCoverQuiz => '部分ジャケット当て';

  @override
  String get featureGuessTheSongFromASmallPart => 'ジャケットの一部分から曲を当てる';

  @override
  String get featureBlurredCoverQuiz => 'ぼかしジャケット当て';

  @override
  String get featureGuessSongsFromBlurredCoverArt => 'ぼかされたジャケットから曲を当てる';

  @override
  String get featurePixelCoverQuiz => 'ピクセルジャケット当て';

  @override
  String get featureGuessSongsFromPixelatedColorsAndShapes =>
      'ピクセル化された色や輪郭から曲を当てる';

  @override
  String get featureFlashCoverQuiz => '瞬間ジャケット当て';

  @override
  String get featureRememberABrieflyFlashedCover => '一瞬だけ表示されたジャケットから曲を当てる';

  @override
  String get featureCoverPuzzleQuiz => 'ジャケットパズル当て';

  @override
  String get featureWatchCoverPiecesAppearOverTime => '時間とともに現れるジャケットのピース';

  @override
  String get featureAudioClipQuiz => '音声クリップ当て';

  @override
  String get featureGuessSongsFromShortAudioClips => '短い音声から曲を当てる';

  @override
  String get featureReversedAudioQuiz => '逆再生曲当て';

  @override
  String get featureGuessSongsFromReversedClips => '逆再生の音声から曲を当てる';

  @override
  String get featureSpeedAndPitchQuiz => '変速・変調曲当て';

  @override
  String get featureGuessSongsFromSpeedAndPitchChanges => '速度と音程が変わった音声から曲を当てる';

  @override
  String get featureChartClipQuiz => '譜面クリップ当て';

  @override
  String get featureGuessSongsFromSilentChartAnimations =>
      '無音の譜面アニメーションから曲を当てる';

  @override
  String get featureMultiplayerSongQuiz => 'マルチ曲当て';

  @override
  String get featureGuessMaimaiSongsWithFriends => 'フレンドと maimai の曲当てに挑戦';

  @override
  String get featureMusicPlayer => 'ミュージックプレイヤー';

  @override
  String get featurePlayMaimaiMusicInTheBackgroundWith =>
      '通知の再生操作で maimai 楽曲をバックグラウンド再生';

  @override
  String get featureCustomChartPlayback => 'カスタム譜面再生';

  @override
  String get featurePlayLocalCustomCharts => 'ローカルのカスタム譜面を再生';

  @override
  String get featureAccountManagement => '成績取り込み認証情報';

  @override
  String get featureViewYourLinkedDivingFishAccount =>
      '水魚・落雪・AWMC NET の成績取り込み Token を管理';

  @override
  String get featureAccountSetupGuide => 'アカウント登録ガイド';

  @override
  String get featureSetUpDivingFishLXNSAndAWMC => '水魚・落雪・AWMC NET の登録ガイド';

  @override
  String get featureSignInToMaimaiScoreHub => 'maimai Score Hub にログイン';

  @override
  String get featureSignInForOCRAndScoreHub =>
      'OCR と Score Hub 用にログイン・成績同期は行いません';

  @override
  String get featureSignOutOfDivingFish => '水魚からログアウト';

  @override
  String get featureClearYourDivingFishSignIn => '水魚のログイン状態を解除';

  @override
  String get featureSignInToDivingFish => '水魚にログイン';

  @override
  String get featureGetAnImportTokenToEnableScoreSync => '同期用の ImportToken を取得';

  @override
  String get featureSyncToDivingFish => '水魚に成績を同期';

  @override
  String get featureScanACodeToFetchAndSync => 'コードを読み取り最新の成績を取得・同期';

  @override
  String get featureSyncToLXNS => '落雪に成績を同期';

  @override
  String get featureSyncLocalScoresToLXNS => 'ローカルの成績を落雪に同期';

  @override
  String get featureSyncToAWMCNET => 'AWMC NET に成績を同期';

  @override
  String get featureImportScoresToAWMCNETUsingA =>
      '筐体の QR コードで AWMC NET に成績を取り込み';

  @override
  String get featureSyncToMultiplePlatforms => '複数サービスに同期';

  @override
  String get featureSendTheSameScoresToMultipleTrackers => '同じ成績を複数のスコアサービスに同期';

  @override
  String get featureAutoSync => '自動同期';

  @override
  String get featureQuickSyncDailyAt0000And => '毎日中国時間の0時と12時に自動クイック同期';

  @override
  String get featureRefreshCachedData => '成績取得とデータ更新';

  @override
  String get featureFetchAndInitializeAllLocalCachesAgain =>
      '選んだアカウントの成績を取得して Best50 を再計算し、楽曲・定数・タグも更新';

  @override
  String get featureAdvancedRefresh => '成績取得とデータ更新（詳細）';

  @override
  String get featureChooseCachesToRefreshAndTestAPI =>
      'データの種類ごとに強制再取得を選び、各 API の接続を確認';

  @override
  String get featureRefreshCabinetPlayCount => '筐体プレイ回数を更新';

  @override
  String get featureReadOnlyTheCurrentAccountPlayCount =>
      '成績を同期せず現在のアカウントの PC 数を取得';

  @override
  String get featureDataBackup => 'データバックアップ';

  @override
  String get featureImportOrExportLocalData => 'ローカルデータの取り込み・書き出し';

  @override
  String get featureCacheManagement => 'キャッシュ管理';

  @override
  String get featureViewAndClearAudioPVAndMaidata =>
      '音源・PV・maidata のキャッシュを確認・削除';

  @override
  String get featureSystemSettings => 'システム設定';

  @override
  String get featureAdjustThemeBackgroundInteractionsAndSync =>
      'テーマ・背景・操作・同期を設定';

  @override
  String get featureLoadingQuotes => '読み込みメッセージ';

  @override
  String get featureChooseQuotesShownWhileLoading => '読み込み中に表示するメッセージを選択';

  @override
  String get featureServerStatus => 'サーバー状態';

  @override
  String get featureViewMaimaiServiceStatus => 'maimai のサービス状態を確認';

  @override
  String get featureExportLogs => 'ログを書き出す';

  @override
  String get featureExportRecentLogsForTroubleshooting => '最近の実行ログを書き出して問題を調査';

  @override
  String get featureRecentComments => '最近のコメント';

  @override
  String get featureViewRecentCommunityComments => 'コミュニティの最新コメントを表示';

  @override
  String get featureRecentRatings => '最近の評価';

  @override
  String get featureViewRecentCommunityRatings => 'コミュニティの最新評価を表示';

  @override
  String get featureCheckForUpdates => '更新を確認';

  @override
  String get featureCheckForANewerAppVersion => 'アプリの新しいバージョンを確認';

  @override
  String get featureAboutTheApp => 'アプリについて';

  @override
  String get featureViewProjectAndVersionInformation => 'プロジェクトとバージョンの情報を表示';

  @override
  String get featureOfficialWebsite => '公式サイト';

  @override
  String get featureVisitTheProjectAtChiffonmaiCloud =>
      'chiffonmai.cloud でプロジェクトを表示';

  @override
  String get featureRelatedProjects => '関連プロジェクト';

  @override
  String get featureDiscoverCommunityProjects => '同じ趣味のプロジェクトを発見';

  @override
  String get featureReportAnIssue => '問題を報告';

  @override
  String get featureReportProblemsYouEncounter => '利用中に発生した問題を報告';

  @override
  String get featureJoinTheQQGroup => 'QQ グループに参加';

  @override
  String get featureOpenTheOfficialCommunityGroup => '公式交流グループを開く';

  @override
  String get featureSurvey => 'アンケート';

  @override
  String get featureHelpImproveChiffonMai => 'ChiffonMai の改善にご協力ください';

  @override
  String get featureSupportDevelopment => '開発を支援';

  @override
  String get featureSupportContinuedProjectUpdates => 'プロジェクトの継続的な更新を支援';

  @override
  String get featureLibrary => '楽曲';

  @override
  String get featureSearchSongsBrowseInformationAndRecognizeImages =>
      '楽曲検索・情報閲覧・画像認識';

  @override
  String get featureSiteWideTotalFittedRatingRanking => 'サイト内の推定総 Rating ランキング';

  @override
  String get featureRankAllScoresByAverageDXScore => '全成績の平均 DX スコア達成率で順位を表示';

  @override
  String get featureScores => '成績';

  @override
  String get featureBrowseScoresImprovementsRankingsAndProgress =>
      '成績・成長・ランキング・進捗を確認';

  @override
  String get featureAllFeatures => 'すべての機能';

  @override
  String get featureStarAFeatureToAddItTo => '星を押すとホームのお気に入りに追加';

  @override
  String get featureChallengeYourMelodyMemoryWithReversedClips =>
      '逆再生の音声でメロディーの記憶に挑戦';

  @override
  String get featureChangeBothSpeedAndPitchForA => '速度と音程を変えて曲当てに挑戦';

  @override
  String get featureSyncScoresOnADailySchedule => '毎日決まった時間に成績を同期';

  @override
  String get featureMe => 'マイページ';

  @override
  String get featureAccountsSyncBackupAndAppPreferences =>
      'アカウント・同期・バックアップ・アプリ設定';

  @override
  String get featureSharedRulesAndSettingsForEachMode => '共通ルールとモードごとの設定';

  @override
  String get featureHome => 'ホーム';

  @override
  String get featurePlay => 'プレイ';

  @override
  String get featureArcade => 'アーケード';

  @override
  String get featureCasual => 'カジュアル';

  @override
  String get featureChooseSongsPlanPracticeAndFindArcades => '選曲・練習計画・設置店検索';

  @override
  String get featureSongQuizzesMusicAndCustomCharts => '曲当て・音楽・カスタム譜面';

  @override
  String get featureSystem => 'システム';

  @override
  String get featureBuildingCoverIndex => 'ジャケット索引を作成中…';

  @override
  String get featureAnotherTaskIsRunningPleaseWait => '別の処理が実行中です。お待ちください';

  @override
  String get featureLeaderboards => 'ランキング';

  @override
  String get featureTotalFittedRating => '推定総 Rating';

  @override
  String get featureAverageAchievement => '平均達成率';

  @override
  String get featureAverageDXScoreRate => '平均 DX スコア達成率';

  @override
  String get featureSpecial => '特殊';

  @override
  String get featureCalculators2 => '計算ツール';

  @override
  String get featureFindScoresTitleConstantOrSongID => '成績検索：曲名・定数・楽曲 ID';

  @override
  String get featureRefreshDataToSeeYourBest35And =>
      'データ更新後に Best35 と Best15 を表示します';

  @override
  String get featureFitted => '推定';

  @override
  String get featureCustom => 'カスタム';

  @override
  String get featureCustomFitted => 'カスタム推定';

  @override
  String get featureIdeal => '理想';

  @override
  String get featureCreate => '作成';

  @override
  String get featureScoreImprovements => '成績の成長';

  @override
  String get featureRecordsBeginAfterSyncing => '同期後に記録を開始';

  @override
  String get featureDailyHistory => '日別の履歴';

  @override
  String get featureThemeAndNavigationSettings => 'テーマとナビゲーション設定';

  @override
  String get featureSyncDataInMe => 'マイページでデータを同期';

  @override
  String get featureNoMatchingFeatures => '一致する機能がありません';

  @override
  String get featureNoFeaturesFound => '該当する機能がありません';

  @override
  String get featureFavorites => 'お気に入り';

  @override
  String get featureDragToReorderTapOrDragTo =>
      'ドラッグで並べ替え。×を押すか削除エリアに移動すると解除できます';

  @override
  String get featureStarFeaturesInAnyCategoryToShow =>
      '各カテゴリの ⭐ を押すと、ここに機能を追加できます';

  @override
  String get featureFinishEditingFavorites => 'お気に入りの編集を終了';

  @override
  String get featureEditFavorites => 'お気に入りを編集';

  @override
  String get featureDone => '完了';

  @override
  String get featureEdit => '編集';

  @override
  String get featureReleaseToRemove => '離して解除';

  @override
  String get featureDragHereToRemove => 'ここにドラッグして解除';

  @override
  String get featureRemoveFavorite => 'お気に入りを解除';

  @override
  String get featureFavoriteFeature => 'お気に入りに追加';

  @override
  String get featureSearchFeaturesOrKeywords => '機能名やキーワードで検索';

  @override
  String get featureSearchSongTitlesAliasesOrIDs => '曲名・別名・楽曲 ID を検索…';

  @override
  String get featureSearchFeaturesOrSongs => '機能や楽曲を検索';

  @override
  String get featureSearch => '検索…';

  @override
  String get featureClear => 'クリア';

  @override
  String get featureSearch2 => '検索';

  @override
  String get featureCloseSearch => '検索を閉じる';

  @override
  String get featureClearInput => '入力をクリア';

  @override
  String get featureClearSearch => '検索をクリア';

  @override
  String get featureSearchHistory => '検索履歴';

  @override
  String get featureLoadingSearchHistory => '検索履歴を読み込み中…';

  @override
  String get featureNoSearchHistory => '検索履歴はありません';

  @override
  String get featureDeleteThisSearchEntry => 'この検索履歴を削除';

  @override
  String get featureCouldNotUpdateSearchHistoryTryAgain =>
      '検索履歴を更新できませんでした。再試行してください';

  @override
  String get featureSearchSongTitlesOnly => '曲名のみで検索';

  @override
  String get featureTitleBPMCharterArtistAliasID =>
      '曲名・BPM・譜面制作者・アーティスト・別名・ID…';

  @override
  String get featureTitleAliasIDArtistCharterBPM => '曲名・別名・ID・アーティスト・譜面制作者・BPM';

  @override
  String get featureEnterAKeywordToFindSongs => 'キーワードを入力して楽曲を検索';

  @override
  String get featureNoMatchingSongs => '一致する楽曲がありません';

  @override
  String get featureSongs => '楽曲';

  @override
  String get featureThemeSettings => 'テーマ設定';

  @override
  String get featureMoreSettings => 'その他の設定';

  @override
  String get featureCancel => 'キャンセル';

  @override
  String get featureOK => '確認';

  @override
  String get featureClose => '閉じる';

  @override
  String get featureGotIt => 'わかりました';

  @override
  String get featureNotice => 'お知らせ';

  @override
  String get featureOperationFailed => '操作に失敗しました';

  @override
  String get featureUnknownError => '不明なエラー';

  @override
  String get featureDialog => 'ダイアログ';

  @override
  String get featureNoDetailsAvailable => '詳細はありません';

  @override
  String get featureUnknown => '不明';

  @override
  String get featureOff => '無効';

  @override
  String get featureWaitingForUpstream => '上流サービス待ち';

  @override
  String get featureSyncing => '同期中';

  @override
  String get featureOn => '有効';

  @override
  String get featureLastRunIncomplete => '前回は未完了';

  @override
  String get featureUpToDate => '最新です';

  @override
  String get featureLoading => '読み込み中…';

  @override
  String get featureCheckingSyncStatus => '同期状態を確認中';

  @override
  String get featureStatusUnknown => '状態不明';

  @override
  String get featureTemporarilyUnavailable => '現在取得できません';

  @override
  String get featureTapToSetUp => 'タップして設定';

  @override
  String get featureUnavailableRetryingShortly => '取得できません。後で自動的に再試行します';

  @override
  String get featureCheckingServerStatus => 'サーバー状態を確認中';

  @override
  String get featureSyncing2 => '同期中…';

  @override
  String get featureReadingCabinetScores => '筐体の成績を読み込み中…';

  @override
  String get featureCheckingForUpdates => '更新を確認中…';

  @override
  String get featureCouldNotCheckForUpdates => '更新を確認できませんでした';

  @override
  String get featureCheckYourConnectionAndTryAgain => '通信状態を確認して再試行してください';

  @override
  String get featureCopyDownloadLink => 'ダウンロードリンクをコピー';

  @override
  String get featureDownloadLinkCopied => 'ダウンロードリンクをコピーしました';

  @override
  String get featureUpdateAvailable => '新しいバージョンがあります';

  @override
  String get featureNewVersion => '新しいバージョン';

  @override
  String get featureSignedInForOCRAndMaimaiScore =>
      'OCR と maimai Score Hub にログイン済み';

  @override
  String get featureSignedInOCRAndMaimaiScoreHub =>
      'ログインしました。OCR と maimai Score Hub を利用できます';

  @override
  String get featureRainbow => '虹';

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
  String get featureRed => '赤';

  @override
  String get featureOrange => '橙';

  @override
  String get featureGreen => '緑';

  @override
  String get featureBlue => '青';

  @override
  String get featureWhite => '白';

  @override
  String homeWelcome(String name) {
    return 'おかえりなさい、$name';
  }

  @override
  String homeSwitchSource(String source) {
    return 'データソースを切り替え、現在は $source';
  }

  @override
  String homeTotalRatingAction(String rating) {
    return '総 Rating $rating。詳細更新を開く';
  }

  @override
  String homeFeatureCount(int count) {
    return '機能（$count）';
  }

  @override
  String homeAllFeatureCount(int count) {
    return 'すべての機能（$count）';
  }

  @override
  String homeResultCount(int count) {
    return '検索結果（$count）';
  }

  @override
  String homeSongCount(int count) {
    return '楽曲（$count）';
  }

  @override
  String homeSongCountLimited(int count, int limit) {
    return '楽曲（$count、最初の$limit曲を表示）';
  }

  @override
  String homeRemoveFavorite(String name) {
    return 'お気に入りを解除：$name';
  }

  @override
  String hubRatingRecords(int rating, int count) {
    return '最新 $rating · $count件の記録';
  }

  @override
  String hubFeaturesCount(int count) {
    return '$count個の機能';
  }

  @override
  String hubCoverIndexFailed(String error) {
    return 'ジャケット索引を作成できませんでした：$error';
  }

  @override
  String hubOpenFailed(String error) {
    return '開けませんでした：$error';
  }

  @override
  String hubLinkUnavailable(String name) {
    return 'リンクを開けませんでした：$name';
  }

  @override
  String hubJoinGroup(String number) {
    return '公式 QQ グループを開く（$number）';
  }

  @override
  String hubUpdateReleased(String version) {
    return '$version が公開されました。更新内容を表示';
  }

  @override
  String homeSyncSubmitted(int count) {
    return '$count件を送信';
  }

  @override
  String homeSyncIncomplete(int count) {
    return '$count件が未完了';
  }

  @override
  String homeSyncSources(int count) {
    return '$count個のデータソース';
  }

  @override
  String homeSyncSourcesWaiting(int count) {
    return '$count個のソース · 実行待ち';
  }

  @override
  String homeSyncUpload(int completed, int total) {
    return '$completed/$total件をアップロード';
  }

  @override
  String homeSyncReadPage(int page) {
    return '筐体成績を読み込み · $pageページ';
  }

  @override
  String homeServerHealthy(int healthy, int total) {
    return '$healthy/$total 正常';
  }

  @override
  String homeTodayAt(String time) {
    return '今日 $time';
  }

  @override
  String get homeInitWorking => 'アプリデータを初期化中です。お待ちください…';

  @override
  String homeInitFinished(String duration) {
    return 'データを初期化しました。所要時間 $duration';
  }

  @override
  String homeInitFailed(String error) {
    return '初期化に失敗しました：$error\n通信状態を確認してアプリを再起動してください';
  }

  @override
  String get featureHubSignedIn => 'OCR にログイン済み。タップして再ログイン';

  @override
  String get featureFish => '水魚';

  @override
  String get featureLxns => '落雪';

  @override
  String get featureServerNormal => 'サービス正常';

  @override
  String get featureServerAbnormal => 'サービスに異常';

  @override
  String get featureTapCommunityAppearance => 'タップしてコミュニティの装飾を選択';

  @override
  String get featureManageAccountBelow => '下でアカウントデータを管理できます';

  @override
  String get featureCollapseProfile => 'プロフィールを簡易表示';

  @override
  String get featureExpandProfile => 'プロフィールを詳細表示';

  @override
  String get featureSynced => '同期済み';

  @override
  String get featureSyncFailed => '同期失敗';

  @override
  String get featurePendingSync => '同期待ち';

  @override
  String get featureLocalOnly => 'この端末のみ';

  @override
  String get featureLoadingGrowth => '成長記録を読み込み中…';

  @override
  String get featureGrowthRules => '成長ルール';

  @override
  String get featureSyncProgress => '同期中です。お待ちください…';

  @override
  String get featurePreparing => '準備中…';

  @override
  String homeStreak(int days) {
    return '連続チェックイン $days日';
  }

  @override
  String homeTrophyId(String id) {
    return '称号 #$id';
  }

  @override
  String get growthRulesBody =>
      '中国時間で毎日の初回起動時にチェックインを確認します。この端末でログインやアカウント認証に成功した際も、その日まだチェックインしていないアカウントを自動チェックインします。\n\n初日は20 EXP、連続チェックインで毎日5 EXPずつ増え、7日目から毎日50 EXPになります。途切れると20 EXPに戻りますが、累計経験値は保持されます。\n\nLv.1 のレベルアップには100 EXPが必要です。以後はレベルごとに必要量が20 EXP増えます。\n\n成長記録は各データソースのアカウントに紐づきます。同じアカウントは1日1回受け取れます。';

  @override
  String hubOpenRelatedProject(String name) {
    return '関連プロジェクトを開く：$name';
  }

  @override
  String hubBusyTask(String task) {
    return '$taskを実行中のため、この機能は利用できません';
  }

  @override
  String get flowEnterYourAWMCNETTokenFirst => '先に AWMC NET Token を入力してください';

  @override
  String get flowCouldNotSaveYourPersonalKeyTry => '個人キーを保存できませんでした。再試行してください';

  @override
  String get flowCouldNotDisableAutoSyncYourKey =>
      '自動同期を無効にできなかったためキーを保持しました。再試行してください';

  @override
  String get flowAWMCNETScoreImportToken => 'AWMC NET 成績取り込み Token';

  @override
  String get flowSet => '設定済み';

  @override
  String get flowNotSet => '未設定';

  @override
  String get flowVisit => 'アクセス：';

  @override
  String get flowToGenerateOrRotateYourTokenAt => '。ページ下部で Token を生成・更新できます。';

  @override
  String get flowPasteYourAWMCNETScoreImportToken =>
      'AWMC NET 成績取り込み Token を貼り付け…';

  @override
  String get flowClearToken => 'Token を削除';

  @override
  String flowSignOutFailedP0(String p0) {
    return 'ログアウト失敗：$p0';
  }

  @override
  String get flowSignedOutOfDivingFish => '水魚からログアウトしました';

  @override
  String get flowLinkDivingFishAccount => '水魚アカウントを連携';

  @override
  String get flowRequestAndOpenALoginQRCode =>
      '「舞萌・中二」公式 WeChat でログイン QR コードを発行して開き、読み取った文字列を下に貼り付けてください：';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID =>
      'maimai DX・CHUNITHM ログイン QR（SGWCMAID…）';

  @override
  String get flowJoinLeaderboards => 'ランキングに参加';

  @override
  String get flowShowNicknameOtherwiseShownAsAnonymous => 'ニックネームを公開（無効時は匿名表示）';

  @override
  String get flowScoresFetchedLinkYourDivingFishAccount =>
      '成績を取得しました。水魚に送信するにはアカウントを連携してください：';

  @override
  String get flowDivingFishUsername => '水魚ユーザー名';

  @override
  String get flowEnterDivingFishUsername => '水魚のユーザー名を入力';

  @override
  String get flowDivingFishPassword => '水魚パスワード';

  @override
  String get flowEnterDivingFishPassword => '水魚のパスワードを入力';

  @override
  String get flowSyncInProgressPleaseWaitAndAvoid => '同期中です。他の操作をせずにお待ちください';

  @override
  String get flowScoresSyncedViewThemOnDivingFish => '成績を同期しました。水魚で確認できます';

  @override
  String flowOKP0(String p0) {
    return '確認（$p0）';
  }

  @override
  String get flowSkip => 'スキップ';

  @override
  String get flowLinking => '連携中…';

  @override
  String get flowLinkAndSync => '連携して同期';

  @override
  String flowDoneP0ScoresSyncedAndLocalData(String p0) {
    return '完了しました。$p0件の成績を同期し、ローカルデータを更新しました';
  }

  @override
  String get flowStartSync => '同期を開始';

  @override
  String get flowPasteTheMaimaiCHUNITHMLoginQRString =>
      '先に maimai・CHUNITHM のログイン QR 文字列を貼り付けてください';

  @override
  String get flowSignedIn => 'ログイン済み';

  @override
  String get flowEnterYourDivingFishCredentialsToObtain =>
      'ImportToken を取得するため、水魚アカウントの認証情報を入力してください：';

  @override
  String get flowUsername => 'ユーザー名';

  @override
  String get flowDivingFishUsername2 => '水魚ユーザー名';

  @override
  String get flowPassword => 'パスワード';

  @override
  String get flowDivingFishPassword2 => '水魚パスワード';

  @override
  String get flowImportTokenRetrievedAndSaved => 'ImportToken を取得して保存しました';

  @override
  String get flowYouCanNowSyncScoresToDiving => '「成績を同期」から水魚に同期できます';

  @override
  String get flowSigningIn => 'ログイン中…';

  @override
  String get flowSignIn => 'ログイン';

  @override
  String get flowDataRefreshed => 'データを更新しました';

  @override
  String get flowDivingFishProfile => '水魚 成績取り込み Token';

  @override
  String get flowNotSignedInToDivingFishOnly => '水魚に未ログインのため、落雪の設定のみ表示します';

  @override
  String get flowNoQQIDFoundRefreshDataOr =>
      'QQ 番号がありません。データを更新するか水魚にログインしてください';

  @override
  String get flowAuthorized => '認証済み';

  @override
  String get flowNotAuthorized => '未認証';

  @override
  String get flowReadingDivingFishScoresRequiresBrowserAuthorization =>
      '水魚の成績を読み込むには、ブラウザーで本アプリを認証してください。下のリンクを開き、水魚にログインして許可してください。';

  @override
  String get flowDivingFishAuthorization => '水魚の認証';

  @override
  String get flowAuthorizationOpenedCompleteItInYourBrowser =>
      '認証ページを開きました。ブラウザーで認証後、戻ってください';

  @override
  String get flowCouldNotStartAuthorizationTryAgain =>
      '認証を開始できませんでした。再試行してください';

  @override
  String get flowAuthorizeAgain => '再認証';

  @override
  String get flowOpenAuthorizationLink => '認証リンクを開く';

  @override
  String get flowLXNSPersonalAPIKey => '落雪の個人 API キー';

  @override
  String get flowVisit2 => 'アクセス：';

  @override
  String get flowAndScrollToTheBottomToGet => '。最下部でキーを取得できます。';

  @override
  String get flowPasteYourLXNSPersonalAPIKey => '落雪の個人 API キーを貼り付け…';

  @override
  String get flowEnterYourAPIKeyFirst => '先に API キーを入力してください';

  @override
  String get flowClearKey => 'キーを削除';

  @override
  String get flowRefreshImportToken => 'ImportToken を更新';

  @override
  String get flowCouldNotRefreshImportTokenTryAgain =>
      'ImportToken を更新できませんでした。再試行してください';

  @override
  String get flowCopyImportToken => 'ImportToken をコピー';

  @override
  String get flowImportTokenCopied => 'ImportToken をコピーしました';

  @override
  String get flowConfirmRefresh => '更新を確認';

  @override
  String get flowThisClearsAllMaidataCachesAndDownloads =>
      'すべての maidata キャッシュを削除して再取得します。時間がかかる場合があります。\n\n更新しますか？';

  @override
  String get flowMaidataRefreshed => 'maidata を更新しました';

  @override
  String flowRefreshFailedP0(String p0) {
    return '更新失敗：$p0';
  }

  @override
  String flowCouldNotOpenABrowserWebsiteLink(String p0) {
    return 'ブラウザーを開けないためリンクをコピーしました。$p0 を手動で開いてください';
  }

  @override
  String get flowConfirmSignOut => 'ログアウトの確認';

  @override
  String get flowSigningOutClearsSavedLoginDetailsAnd =>
      'ログアウトすると保存したログイン情報と ImportToken を削除します。続けますか？';

  @override
  String get flowSignOut => 'ログアウト';

  @override
  String get flowAccountChangedChooseYourAppearanceAgain =>
      'アカウントが変わりました。装飾を選び直してください';

  @override
  String get flowCouldNotSaveYourAppearanceChooseAgain =>
      '装飾を保存できませんでした。選び直してください';

  @override
  String get flowChooseWhereToSaveLogs => 'ログの保存先を選択';

  @override
  String get flowLogsExported => 'ログを書き出しました';

  @override
  String flowCouldNotExportLogsP0(String p0) {
    return 'ログの書き出し失敗：$p0';
  }

  @override
  String flowCouldNotOpenABrowserP0Copied(String p0) {
    return 'ブラウザーを開けないため $p0 をコピーしました。手動で開いてください';
  }

  @override
  String get flowBaseNoteMaidataDownloadedAgain => '基本物量の maidata を再取得しました';

  @override
  String flowDownloadFailedP0(String p0) {
    return '再取得失敗：$p0';
  }

  @override
  String flowPlayCountsUpdatedP0Records(String p0) {
    return 'プレイ回数を更新しました（$p0件）';
  }

  @override
  String flowCouldNotReadPlayCountsP0(String p0) {
    return 'プレイ回数の取得失敗：$p0';
  }

  @override
  String get flowNoConnectionConnectAndTryAgain => '通信できません。接続後に再試行してください';

  @override
  String get flowMaimaiScoreHubSignInSavedOCR =>
      'maimai Score Hub のログイン状態を保存しました。OCR を利用できます';

  @override
  String get flowSignOutOfDivingFish => '水魚からログアウトしますか？';

  @override
  String flowCouldNotSignOutOfDivingFish(String p0) {
    return '水魚のログアウト失敗：$p0';
  }

  @override
  String get flowCannotSave => '保存できません';

  @override
  String get flowEnterYourAWMCNETScoreImportToken =>
      'AWMC NET 成績取り込み Token を入力してください';

  @override
  String get flowAWMCNETScoreImportTokenSaved =>
      'AWMC NET 成績取り込み Token を保存しました';

  @override
  String get flowAWMCNETScoreImportTokenCleared =>
      'AWMC NET 成績取り込み Token を削除しました';

  @override
  String get flowSignedInToDivingFish => '水魚にログインしました';

  @override
  String get flowScoreImportToken => '成績取り込み Token';

  @override
  String get flowPasteATokenGeneratedInAWMCNET =>
      'AWMC NET の設定で生成した Token を貼り付け';

  @override
  String get flowSaveToken => 'Token を保存';

  @override
  String flowP0AutoSyncEnabledScheduledDailyBetween(String p0) {
    return '$p0 の自動同期を有効にしました。毎日中国時間08:00～24:00に順次処理します';
  }

  @override
  String flowP0AutoSyncDisabledHostedCredentialsDeleted(String p0) {
    return '$p0 の自動同期を無効にし、サーバー上の認証情報を削除しました';
  }

  @override
  String get flowAutoSyncTemporarilyLimited => '自動同期は一時的に制限されています';

  @override
  String get flowCouldNotConfigureAutoSyncCheckYour =>
      '自動同期を設定できませんでした。アカウントを確認して再試行してください';

  @override
  String get flowRefreshStatus => '状態を更新';

  @override
  String get flowQueueStatus => 'キューの状況';

  @override
  String get flowSyncSources => '同期するデータソース';

  @override
  String get flowLoading => '読み込み中…';

  @override
  String get flowSourcesEnabled => '個のソースが有効';

  @override
  String get flowScheduledQueueWindow => '定時処理の時間帯';

  @override
  String get flowChinaTimeUTC8OnceDailyQuick => '中国時間（UTC+8）・毎日1回・クイック同期のみ';

  @override
  String get flowCredentialsAreEncryptedAndHostedWhileEnabled =>
      '有効時は認証情報を暗号化して保管し、無効にすると削除します。';

  @override
  String get flowAboutSync => '同期について';

  @override
  String get flowUsersAreProcessedInDailyBatchesNew =>
      '毎日バッチ処理します。実行中・待機中のバッチに参加すると末尾に加わり、終了後は次のランダム順のバッチに入ります。上流の制限や混雑により後の時間帯に延期される場合があります。';

  @override
  String get flowEachUserBatchHasAProcessingLimit =>
      'ユーザーごとの処理には制限時間があります。上流の応答遅延・割当不足・大量アップロードで終了した場合は前回結果に理由を表示し、翌日の時間帯で再開します。キュー待機時間は含みません。';

  @override
  String flowAfterReadingCabinetScoresEachUserHas(String p0) {
    return '筐体成績の取得後はユーザーごとに最大$p0分処理します。取得前のキュー・割当待ちは含みません。制限時間や当日の終了時刻を超えると翌日に続きます。';
  }

  @override
  String get flowLinkYourCabinetIdentityUsingAQR =>
      'QR コードで筐体 ID を連携すると、3つのソースで認証情報を共有できます。通常の QR 同期でも自動連携します。各ソースの個人キーとアカウントは別途必要です。\n\n毎日中国時間08:00～24:00にクイック同期します。同一ユーザーの3ソースは筐体成績を1回だけ取得し、各サービスの成績と比較して変更分を送信します。\n\n処理段階・取得ページ数・アップロード件数・送信済み件数・経過時間を表示します。上流待ちでは理由と再試行予定時刻を表示し、前回結果には所要時間・筐体データ取得時刻・次回再試行時刻を表示します。\n\n上流へのリクエスト割当と制限を共有し、メンテナンス・割当不足・通信エラーでは理由を表示して一時停止します。連続再試行はしません。\n\n実行中に無効にすると後続バッチを停止します。送信済みの成績は保持し、結果が不明な送信は確認してから再試行します。';

  @override
  String get flowSaving => '保存中…';

  @override
  String flowP0AutoSync(String p0) {
    return '$p0 の自動同期';
  }

  @override
  String flowRoundStartedP0(String p0) {
    return '今回の開始：$p0';
  }

  @override
  String flowNextRunP0(String p0) {
    return '次回実行：$p0';
  }

  @override
  String get flowLoadingSyncStatus => '同期状態を読み込み中…';

  @override
  String get flowOffEnableAnytime => '無効・いつでも有効にできます';

  @override
  String flowSyncSucceededButLocalRefreshWasIncomplete(String p0) {
    return '同期は成功しましたが、ローカル更新は未完了です：$p0';
  }

  @override
  String get flowTheQueueIsBusyYourRunMay => '混雑のため、後の処理時間帯に延期される場合があります';

  @override
  String flowLastProgressP0(String p0) {
    return '前回の進捗：$p0';
  }

  @override
  String flowP0NoExecutionSlotIsUsedWhile(String p0) {
    return '$p0。待機中は実行枠を使用しません';
  }

  @override
  String flowRunTimeP0(String p0) {
    return '実行時刻：$p0';
  }

  @override
  String flowCabinetDataCollectedP0(String p0) {
    return '筐体データ取得：$p0';
  }

  @override
  String get flowTheRoundExceededItsTimeLimitAnd =>
      '今回の制限時間を超えたため終了しました。未完了分は次の定時実行に続きます。';

  @override
  String flowTheRoundExceededItsP0MinuteLimit(String p0) {
    return '今回の$p0分の制限を超えたため終了しました。未完了分は次の定時実行に続きます。';
  }

  @override
  String get flowNextAutomaticRetry => '次回自動再試行';

  @override
  String get flowNextRun => '次回実行';

  @override
  String flowP0Queue(String p0) {
    return '$p0のキュー';
  }

  @override
  String get flowNextRound => '次回';

  @override
  String get flowThisRound => '今回';

  @override
  String get flowChinaTimeUTC8 => '中国時間（UTC+8）';

  @override
  String flowLimitP0MinutesPerRound(String p0) {
    return '・1回最大$p0分';
  }

  @override
  String get flowWaitingForUpstreamRecovery => '上流サービスの復旧待ち';

  @override
  String get flowPreviousRoundQueue => '前回のキュー処理';

  @override
  String get flowLoadingPreviousRoundStatistics => '前回の統計を読み込み中…';

  @override
  String get flowStatisticsUnavailableRetryingAutomatically =>
      '統計を取得できません。自動的に再試行します';

  @override
  String get flowNoPreviousRound => '前回の記録なし';

  @override
  String flowSubmittedP0SkippedP1P2(String p0, String p1, String p2) {
    return '送信 $p0件・スキップ $p1件・$p2';
  }

  @override
  String get flowCabinetIdentityLinked => '筐体 ID 連携済み';

  @override
  String get flowLinkCabinetIdentityFirst => '先に筐体 ID を連携';

  @override
  String get flowRequestAndOpenALoginQRCode2 =>
      '「舞萌・中二」公式 WeChat のログイン QR コードを開き、SGWCMAID で始まる文字列を入力してください。3つのソースで連携を共有し、QR コード自体は保存しません。通常の QR 同期でも自動連携します。';

  @override
  String get flowCabinetLoginQRCode => '筐体ログイン QR コード';

  @override
  String get flowLinking2 => '連携中…';

  @override
  String get flowLinkCabinetIdentity => '筐体 ID を連携';

  @override
  String flowEnterYourP0PersonalKeyToo(String p0) {
    return '$p0 の個人キーも入力してください';
  }

  @override
  String get flowOpenDivingFish => '水魚を開く';

  @override
  String get flowOpenKeyPage => 'キー取得ページを開く';

  @override
  String get flowPersonalKey => '個人キー';

  @override
  String get flowPasteImportToken => 'ImportToken を貼り付け…';

  @override
  String get flowSavePersonalKey => '個人キーを保存';

  @override
  String get flowInvalidCabinetLoginQRCode => '筐体ログイン QR コードが無効です';

  @override
  String flowSyncFailedP0(String p0) {
    return '同期失敗：$p0';
  }

  @override
  String flowAWMCGatewayUnavailableP0(String p0) {
    return 'AWMC ゲートウェイを利用できません：$p0';
  }

  @override
  String get flowThisReadsOnlyTheActiveAccountPlay =>
      '現在のアカウントのプレイ回数のみ取得します。新しく発行した QR コードを使ってください。上流へのリクエストは1回のみです。';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID2 =>
      'maimai DX・CHUNITHM ログイン QR（SGWCMAID…）';

  @override
  String get flowEnterAValidSGWCMAIDCabinetLoginQR =>
      '有効な SGWCMAID の筐体ログイン QR コードを入力してください';

  @override
  String get flowReadPlayCount => '回数を取得';

  @override
  String get flowNone => '（なし）';

  @override
  String get flowViewFullData => '全データを表示';

  @override
  String get flowDataIsShownOnlyOnThisDevice => 'データはこの端末のみで表示し、第三者に送信しません。';

  @override
  String get flowSetGatewayToken => 'ゲートウェイ Token を設定';

  @override
  String get flowQRCodeContent => 'QR コードの内容';

  @override
  String get flowInvalidQRFormatMustStartWithSGWCMAID =>
      'QR の形式が不正です（SGWCMAID で始まる必要があります）';

  @override
  String get flowConfirmAction => '実行を確認';

  @override
  String get flowNoCharge => '課金なし';

  @override
  String get flowShow => '表示';

  @override
  String get flowFullData => '全データ';

  @override
  String flowP0P1CharactersP2LinesShownOnly(String p0, String p1, String p2) {
    return '$p0・$p1文字 / $p2行\nこの端末のみで表示し、第三者に送信しません。';
  }

  @override
  String get flowEnterYourAWMCNETScoreImportToken2 =>
      'AWMC NET 成績取り込み Token を入力してください';

  @override
  String get flowImportTokenSaved => '取り込み Token を保存しました';

  @override
  String get flowPasteOrScanACabinetLoginQR =>
      'SGWCMAID で始まる筐体ログイン QR を貼り付けるか読み取ってください';

  @override
  String get flowSetYourAWMCNETScoreImportToken =>
      '先に AWMC NET 成績取り込み Token を設定してください';

  @override
  String get flowRequestAndOpenALoginQRIn =>
      '「舞萌・中二」公式 WeChat でログイン QR を発行して開き、下に貼り付けるか、スキャン・画像認識を使ってください。';

  @override
  String get flowMaimaiDXCHUNITHMLoginQRSGWCMAID3 =>
      'maimai DX・CHUNITHM ログイン QR（SGWCMAID…）';

  @override
  String get flowScoreImportTokenSet => '成績取り込み Token 設定済み';

  @override
  String get flowSetAWMCNETScoreImportToken => 'AWMC NET 成績取り込み Token を設定';

  @override
  String get flowChange => '変更';

  @override
  String get flowPasteScoreImportToken => '成績取り込み Token を貼り付け…';

  @override
  String get flowGenerateYourOwnTokenOnAWMCNET =>
      'AWMC NET でご自身の Token を生成してください（プロジェクト付属のキーは使えません）：';

  @override
  String get flow1OpenTheAWMCNETSettingsLink => '① 下のリンクから AWMC NET の設定を開く';

  @override
  String get flow2ScrollToTheBottomAndGenerate => '② 最下部の「Token を生成・更新」を押す';

  @override
  String get flow3CopyTheTokenAndPasteIt => '③ 生成した Token をコピーしてここに貼り付ける';

  @override
  String get flowCabinetScoresTakePriorityAndOverwriteMatching =>
      '筐体の成績を優先し、AWMC NET の対応する成績を上書きします。';

  @override
  String flowCouldNotOpenABrowserVisitP0(String p0) {
    return 'ブラウザーを開けません。$p0 に手動でアクセスしてください';
  }

  @override
  String flowClearP0AccountData(String p0) {
    return '$p0 のアカウントデータを削除';
  }

  @override
  String flowThisDeletesLocalP0CachesScoresBest50(String p0) {
    return '$p0 のローカルキャッシュ（成績・Best50・プロフィール・おすすめ等）を削除します。ログイン状態は保持します。\n\n次にこのアカウントを使う際はデータ更新が必要です。削除しますか？';
  }

  @override
  String get flowClear => '削除';

  @override
  String flowCouldNotClearP0(String p0) {
    return '削除失敗：$p0';
  }

  @override
  String flowClearedP0AccountData(String p0) {
    return '$p0 のアカウントデータを削除しました';
  }

  @override
  String flowSwitchedToP0Account(String p0) {
    return '$p0 のアカウントに切り替えました';
  }

  @override
  String get flowAccountSwitchFailedAttemptedToRestoreThe =>
      '切り替えに失敗しました。元のアカウントへの復元を試みました';

  @override
  String get flowSwitchingPleaseWait => '切り替え中です。お待ちください';

  @override
  String get flowNoCachedDataForThisAccount => 'このアカウントのキャッシュはありません';

  @override
  String flowNoDataHasBeenCachedForP0(String p0) {
    return '$p0 のデータはまだ保存されていません。今すぐ更新しますか？';
  }

  @override
  String get flowRefreshNow => 'データを更新';

  @override
  String get flowSwitchAccount => 'アカウント切り替え';

  @override
  String flowSwitchingToP0(String p0) {
    return '$p0 に切り替え中…';
  }

  @override
  String get flowTapAnAccountToSwitchSourceAnd =>
      'アカウントを押すと、通信せずローカルデータでソースとプロフィールを切り替えます';

  @override
  String get flowRefreshToUpdateTheActiveAccountDiving =>
      '更新すると現在のアカウントを更新します。水魚と落雪のログインは別々です。AWMC NET は QQ 番号で照会し、ログインは不要です。';

  @override
  String get flowCurrent => '現在';

  @override
  String get flowNoCache => 'キャッシュなし';

  @override
  String flowCopiedP0(String p0) {
    return 'コピーしました：$p0';
  }

  @override
  String flowAWMCBOTQQIDCopiedP0(String p0) {
    return 'AWMC BOT の QQ 番号をコピーしました：$p0';
  }

  @override
  String flowCopyP0(String p0) {
    return '$p0 をコピー';
  }

  @override
  String get flowOpenLXNS => '落雪を開く';

  @override
  String get flowSendMymaiFirstIfNoAccountRecord =>
      '先に mymai を送信してください。アカウントの記録がない場合はボットが手順を返信します。';

  @override
  String get flowThenSendMaiAndFollowTheInstructions =>
      '次に mai绑定 を送信し、案内に従ってプロフィールを作成してください。';

  @override
  String get flowOpenAWMCNET => 'AWMC NET を開く';

  @override
  String get flowTapAnImageToEnlargeIt => '画像をタップすると拡大できます';

  @override
  String get flowEnlargeImage => '画像を拡大';

  @override
  String get flowNotSignedInToDivingFish => '水魚に未ログイン';

  @override
  String get flowYourDivingFishAccountHasNoLinked => '水魚アカウントに QQ 番号が連携されていません';

  @override
  String get flowLinkQQOnDivingFish => '水魚で QQ を連携';

  @override
  String get flowISavedItReadAgain => '入力済み・再取得';

  @override
  String get flowAccount => 'アカウント';

  @override
  String get flowCheckingAuthorization => '認証状態を確認中…';

  @override
  String get flowAuthorizationOpenedFinishInYourBrowserThen =>
      '認証ページを開きました。ブラウザーで完了後、再確認してください';

  @override
  String get flowReadingScoresRequiresAuthorizationRefreshWillFail =>
      '成績の取得には認証が必要です。未認証では更新できません';

  @override
  String get flowAuthorizedCheckAgain => '認証済み・再確認';

  @override
  String get flowAuthorize => '認証する';

  @override
  String get flowCouldNotOpenABrowserLinkCopied =>
      'ブラウザーを開けないためリンクをコピーしました。手動で開いてください';

  @override
  String flowP0ReusesThisDeviceSMaimaiScore(String p0) {
    return '$p0 はこの端末に保存した maimai Score Hub のログイン状態を利用します。\n\n有効なログイン状態がありません。まず新しい筐体 QR コードでログインしてください。その後の同期には成績取得用の別の新しい QR コードが必要です。同じコードはログインと同期で兼用できません。\n\nログイン状態は端末に保存され、以後の経路2では再ログイン不要です。';
  }

  @override
  String get flowRoute2Sync => '経路2の同期';

  @override
  String flowP0Sync(String p0) {
    return '$p0 の同期';
  }

  @override
  String get flowTipGenerateTwoDifferentLoginQRCodes =>
      'ヒント：読み取る前に異なるログイン QR コードを2枚発行してください。';

  @override
  String get flowSignInFirst => 'ログインへ';

  @override
  String get flowSignedInToMaimaiScoreHub => 'maimai Score Hub にログインしました';

  @override
  String get flowSignInSavedForOCRAndRoute =>
      'OCR と経路2の同期に使うログイン状態を保存しました。\n再ログインのためのスキャンは不要です。';

  @override
  String get flowAuthenticatesWithMaimaiScoreHubOnlyNo =>
      'maimai Score Hub の認証のみ行います。成績の取得や同期はしません。';

  @override
  String get flowInvalidQRCodeUseALoginQR =>
      'QR コードが無効です。「舞萌・中二」公式 WeChat のログイン QR を使ってください';

  @override
  String get flowSetLXNSPersonalAPIKey => '落雪の個人 API キーを設定';

  @override
  String get flowExportingToLXNSRequiresYourPersonalAPI =>
      '落雪への書き出しには、パスワードではなく個人 API キーが必要です：';

  @override
  String get flow1OpenTheLXNSProfileLinkBelow => '① 下のリンクから落雪の個人ページを開く';

  @override
  String get flow2ScrollToTheBottomAndCopy => '② 最下部の「個人 API キー」をコピー';

  @override
  String get flow3ReturnToAccountManagementLXNSAPI =>
      '③ アプリの「成績取り込み認証情報 → 落雪 API キー」に貼り付けて保存';

  @override
  String get flowReopenThisDialogAfterSavingToSync =>
      '保存後、このダイアログを開き直すと同期できます。';

  @override
  String get flowLinkYourDivingFishAccountToObtain =>
      'ImportToken を取得するため水魚アカウントを連携してください：';

  @override
  String flowSyncSucceededButDataRefreshFailedP0(String p0) {
    return '同期は成功しましたがデータ更新に失敗しました：$p0';
  }

  @override
  String get flowSignInToYourDivingFishAccount => '同期する前に水魚アカウントにログインしてください。';

  @override
  String get flowAccountMismatch => 'アカウントが一致しません';

  @override
  String flowTheSignedInDivingFishQQP0(String p0, String p1) {
    return 'ログイン中の水魚の QQ（$p0）と端末に保存した QQ（$p1）が異なります。\n\nログアウトして正しいアカウントにログインしてから同期してください。';
  }

  @override
  String flowSyncCompleteP0ScoresSyncedAndLocal(String p0) {
    return '同期完了。$p0件の成績を同期し、ローカルデータを更新しました';
  }

  @override
  String flowSyncCompleteP0ScoresSentToDiving(String p0) {
    return '同期完了。水魚に$p0件の成績を送信しました';
  }

  @override
  String flowSyncCompleteP0ScoresExportedToLXNS(String p0) {
    return '同期完了。落雪に$p0件の成績を書き出しました';
  }

  @override
  String flowEnterANewQRCodeForP0(String p0) {
    return '$p0 用の新しい QR コードを入力';
  }

  @override
  String flowMultiPlatformSyncCompleteP0(String p0) {
    return '複数サービスへの同期完了：$p0';
  }

  @override
  String flowSyncCompleteP0P1P2(String p0, String p1, String p2) {
    return '同期完了：$p0$p1$p2';
  }

  @override
  String get flowNone2 => 'なし';

  @override
  String flowSyncFailedP02(String p0) {
    return '\n\n同期失敗：\n$p0';
  }

  @override
  String flowSyncSucceededButRefreshFailedP0(String p0) {
    return '\n\n同期は成功しましたが更新に失敗しました：\n$p0';
  }

  @override
  String get flowCouldNotSaveCredentialsTryAgain =>
      '認証情報を保存できませんでした。再試行してください。';

  @override
  String flowCouldNotOpenTheWebsiteVisitP0(String p0) {
    return 'サイトを開けません。ブラウザーで $p0 にアクセスしてください。';
  }

  @override
  String get flowRoute1 => '経路1';

  @override
  String get flowRoute2 => '経路2';

  @override
  String flowCurrentP0P1(String p0, String p1) {
    return '現在：$p0・$p1';
  }

  @override
  String get flowQuickSyncAlwaysUsesRoute1 => 'クイック同期は経路1を使用します';

  @override
  String get flowAvailable => '保存済み';

  @override
  String get flowMissing => '未入力';

  @override
  String get flowFillInCredentialsToSelectThisSource => '認証情報を入力すると選択できます';

  @override
  String get flowCollapse => '閉じる';

  @override
  String get flowFillInMissingCredentials => '不足する認証情報を入力';

  @override
  String get flowGetYourImportTokenFromTheDivingFish =>
      '水魚のサイトで ImportToken を取得してください。アプリのログインで保存した認証情報も自動検出します。';

  @override
  String get flowSignInToLXNSAndGetYour =>
      '落雪にログインし、アカウント設定で個人 API キーを取得してください。';

  @override
  String get flowEnterTheQQLinkedToAWMCNET =>
      'AWMC NET に連携した QQ を入力してください。取り込みには公式サイト設定の最下部で生成した Import-Token も必要です。';

  @override
  String get flowOpenWebsite => '公式サイトを開く';

  @override
  String get flowAWMCNETQQID => 'AWMC NET の QQ 番号';

  @override
  String get flowSaveAndSelect => '保存して選択';

  @override
  String get flowNormalSyncRequiresANewCabinetQR =>
      '通常同期は対象ごとに新しい筐体 QR が必要です。同じコードは2回目のリクエストに使いません。クイック同期は QR 不要です。';

  @override
  String get flowSourcesWithSavedCredentialsAreSelectedBy =>
      '保存した認証情報があるサービスを初期選択します。水魚 → 落雪 → AWMC NET の順に同期します。';

  @override
  String get flowReloadCredentials => '認証情報を再取得';

  @override
  String get flowAWMCNETOverwritesMatchingRecordsWithCabinet =>
      'AWMC NET の対応する成績を筐体成績で上書きします。';

  @override
  String flowStartSyncP0(String p0) {
    return '同期を開始（$p0）';
  }

  @override
  String get flowRefreshDataAfterSync => '同期後にデータを更新';

  @override
  String get flowRefreshAutomaticallyAfterUploadRefreshErrorsAre =>
      '送信成功後に自動更新します。更新の失敗は別途通知します。';

  @override
  String get flowCouldNotReadRefreshSettingsUploadCan =>
      '更新設定を取得できません。送信は続行でき、更新エラーは別途通知します。';

  @override
  String get flowReloadRefreshSettings => '更新設定を再取得';

  @override
  String get flowQuickSync => 'クイック同期';

  @override
  String get flowCheckingCachedUserCredentials => '保存したユーザー認証情報を確認中…';

  @override
  String get flowCabinetIdentityLinkedNoQRNeededThis =>
      '筐体 ID は連携済みです。今回は QR 不要です';

  @override
  String get flowChooseASyncSourceFirst => '先に同期先を選んでください';

  @override
  String get flowEnterAQRToLinkCabinetIdentity => 'QR を入力して筐体 ID を連携できます';

  @override
  String get flowUserCredentialsCached => 'ユーザー認証情報を保存済み';

  @override
  String get flowUserCredentialsNotCached => 'ユーザー認証情報が未保存';

  @override
  String get flowValidatingQRCode => 'QR コードを検証中…';

  @override
  String get flowLinkCabinetIdentityUsingQR => 'QR で筐体 ID を連携';

  @override
  String get flowUpdatesAchievementAndDXScoresComboAnd =>
      '達成率と DX スコアを更新します。コンボ・シンクのマークは各サービスの既存値を保持します。宴譜面とプレイ回数は未対応です。';

  @override
  String get flowCouldNotDeleteCredentialsTryAgain =>
      '認証情報を削除できませんでした。再試行してください';

  @override
  String get flowDeleteUserCredentials => 'ユーザー認証情報を削除';

  @override
  String get flowAllThreeSourcesShareTheseCredentialsDeleting =>
      '3つのソースで共有する認証情報です。削除するとすべての自動同期を無効にします。';

  @override
  String get flowCabinetIdentityCachedQuickSyncIsReady =>
      '筐体 ID を保存しました。クイック同期を利用できます';

  @override
  String flowCouldNotLinkCabinetIdentityP0(String p0) {
    return '筐体 ID の連携失敗：$p0';
  }

  @override
  String get flowReadsOnlyUserIdForQuickSyncDoes =>
      'クイック同期用の userId のみ取得します。成績の取得や通常同期は行いません。';

  @override
  String get flowVerifyAndSave => '検証して保存';

  @override
  String get flowValidQRStringDetectedAndFilledIn => '有効な QR 文字列を検出し、自動入力しました';

  @override
  String get flowClipboardIsEmpty => 'クリップボードが空です';

  @override
  String get flowClipboardContentIsNotAValidLogin =>
      'クリップボードは有効なログイン QR ではありません。そのまま入力しますか？';

  @override
  String get flowFillIn => '入力する';

  @override
  String get flowNoQRCodeFoundInTheImage => '画像に QR コードがありません';

  @override
  String get flowCouldNotReadQRContentFromThe => '画像から QR の内容を読み取れませんでした';

  @override
  String get flowQRCodeDetectedAndFilledIn => 'QR コードを検出し、自動入力しました';

  @override
  String flowRecognitionFailedP0(String p0) {
    return '認識失敗：$p0';
  }

  @override
  String flowScanFailedP0(String p0) {
    return 'スキャン失敗：$p0';
  }

  @override
  String get flowReadClipboard => 'クリップボード';

  @override
  String get flowReadFromGallery => 'アルバムから認識';

  @override
  String get flowScanQRCode => 'QR をスキャン';

  @override
  String flowCameraErrorP0(String p0) {
    return 'カメラエラー：$p0';
  }

  @override
  String get flowBack => '戻る';

  @override
  String get flowCouldNotOpenTheLinkCopiedTo =>
      'リンクを開けないためコピーしました。ブラウザーに貼り付けて開いてください';

  @override
  String get flowStillNoQQIDFoundCheckThat =>
      'QQ 番号を取得できません。水魚で保存したか確認するか、再ログインしてください';

  @override
  String flowLinkedQQFoundP0(String p0) {
    return '連携した QQ を取得しました：$p0';
  }

  @override
  String get flowNoQQIDFound => 'QQ 番号がありません';

  @override
  String get flowAuthorizationOpenedReturnAfterAuthorizingAndTap =>
      '認証ページを開きました。認証後に戻り「認証済み・再確認」を押してください';

  @override
  String get flowAuthorizedYouCanNowRefreshData => '認証しました。データを更新できます';

  @override
  String get flowAuthorizationNotDetectedApproveAccessInYour =>
      '認証を確認できません。ブラウザーで「同意」を押したか確認してください';

  @override
  String get flowCheckFailedVerifyYourConnectionAndTry =>
      '確認できませんでした。通信状態を確認して再試行してください';

  @override
  String get flowCurrentDataSource => '現在のデータソース：';

  @override
  String get flowConfirm => '確認';

  @override
  String get flowLXNSAuthorizationSavedItRenewsAutomaticallyNo =>
      '落雪の認証を保存しました。自動更新されるため、認証コードの再入力は不要です。';

  @override
  String get flowAuthorize2 => '認証へ';

  @override
  String get flowAuthorizationButtonNotWorking => '認証ボタンが反応しない場合';

  @override
  String get flowCopyThisLinkAndOpenItManually => 'リンクをコピーしてブラウザーで開き、認証してください：';

  @override
  String get flowCopyAuthorizationLink => '認証リンクをコピー';

  @override
  String get flowAuthorizationLinkCopiedPasteItIntoYour =>
      '認証リンクをコピーしました。ブラウザーに貼り付けてください';

  @override
  String get flowAfterAuthorizingCopyTheCodeShownOn =>
      '認証後に表示されるコードをコピーして下に貼り付けてください';

  @override
  String get flowEnterAuthorizationCode => '認証コードを入力してください';

  @override
  String get flowPasteAuthorizationCode => '認証コードを貼り付け';

  @override
  String get flowQQID => 'QQ 番号';

  @override
  String get flowEnterAQQIDAlreadyLinkedOn => 'AWMC NET に連携済みの QQ 番号を入力';

  @override
  String get flowNoSignInNeeded => 'ログイン不要';

  @override
  String get flowAWMCNETIsAThirdPartyScore =>
      'AWMC NET は QQ 番号で公開成績を照会する外部サービスです。ログインや認証は不要です。\nnet.wmc.pub で QQ を連携し成績を送信済みである必要があります。未登録の場合はデータが見つかりません。';

  @override
  String get flowLinkQQUploadScoresOnAWMCNET => 'AWMC NET で連携・成績送信';

  @override
  String get flowForceFullRefreshIgnoreStaticCaches => '完全更新を強制（静的キャッシュを無視）';

  @override
  String get flowMaidataStillUpdatesAsASeparateBackground =>
      'maidata は引き続き別のバックグラウンド処理で更新します';

  @override
  String get flowSignInThroughMeSignInTo => '先に「マイページ → 水魚にログイン」でログインしてください';

  @override
  String get flowYourDivingFishAccountHasNoQQ =>
      '水魚アカウントに QQ がありません。公式サイトのプロフィール編集で入力してください';

  @override
  String get flowEnterYourLXNSAuthorizationCodeFirst => '先に落雪の認証コードを入力してください';

  @override
  String get flowEnterYourAWMCNETQQID => 'AWMC NET の QQ 番号を入力してください';

  @override
  String get flowInvalidQQID512DigitsRequired => 'QQ 番号は5～12桁の数字で入力してください';

  @override
  String get flowCannotRefreshWithoutAConnectionConnectAnd =>
      '通信できないため更新できません。接続後に再試行してください。';

  @override
  String get flowCouldNotOpenABrowserLinkCopied2 =>
      'ブラウザーを開けないためリンクをコピーしました。ブラウザーに貼り付けてください';

  @override
  String get flowAWMCNETOffersPublicScoreLookupBy =>
      'AWMC NET はログインや認証なしで QQ から公開成績を照会します。\nnet.wmc.pub で QQ を連携し成績を送信済みである必要があります。';

  @override
  String get flowForceRefreshCachedData => 'キャッシュデータを強制更新';

  @override
  String get flowDeselectAll => 'すべて解除';

  @override
  String get flowSelectAll => 'すべて選択';

  @override
  String get flowSelectedCachesAreIgnoredAndFetchedFrom =>
      '選択したキャッシュは今回無視して通信で取得します。未選択の項目は利用可能なキャッシュを再利用します。';

  @override
  String get flowLoading2 => '読み込み中…';

  @override
  String flowConnectedP0P1Ms(String p0, String p1) {
    return '接続成功：$p0・$p1 ms';
  }

  @override
  String flowFailedP0P1Ms(String p0, String p1) {
    return '失敗：$p0（$p1 ms）';
  }

  @override
  String get flowTest => 'テスト';

  @override
  String get flowRoute => '経路';

  @override
  String flowP0LastRefreshFailedShowingOlderData(String p0) {
    return '$p0・前回の更新失敗のため古いデータを表示';
  }

  @override
  String flowP0Last100P1SamplesAvgP2(
      String p0, String p1, String p2, String p3) {
    return '$p0：直近100回 / $p1件 / 平均$p2 / 成功$p3%';
  }

  @override
  String get flowSyncStatistics => '同期統計';

  @override
  String flowTracksDurationAndOutcomeForTheLatest(String p0) {
    return '直近$p0回の同期時間と結果を記録します。全ユーザー共通で、QR やアカウント情報は含みません。';
  }

  @override
  String flowNormalSyncP0(String p0) {
    return '通常同期・$p0';
  }

  @override
  String get flowStatisticsUnavailable => '統計を取得できません';

  @override
  String get flowNoRecordsYet => '記録はありません';

  @override
  String get flowFailed => '失敗';

  @override
  String flowP0P1UsersQueuedP2ItemsProcessing(String p0, String p1, String p2) {
    return '$p0：$p1人待ち・$p2件処理中';
  }

  @override
  String flowP0P1ChinaTime(String p0, String p1) {
    return '\n$p0：$p1（中国時間）';
  }

  @override
  String get flowDifficultyFilter => '難易度フィルター';

  @override
  String get flowRecentSearches => '最近の検索';

  @override
  String get flowEG137Or134 => '例：13.7 または 13.4-14';

  @override
  String flowClearP0Constant(String p0) {
    return '$p0 の定数をクリア';
  }

  @override
  String get flowEveryEnteredDifficultyMustMatchBlankFields =>
      '入力した難易度をすべて満たす必要があります。空欄は制限なしです。上の難易度や他の条件と併せて絞り込みます。';

  @override
  String get flowUTAGEIsFilledInSoNormalDifficulties =>
      'UTAGE を入力中のため通常難易度は無効です。クリアすると戻ります。';

  @override
  String get flowNormalDifficultiesAreFilledInSoUTAGE =>
      '通常難易度を入力中のため UTAGE は無効です。すべてクリアすると戻ります。';

  @override
  String get flowConstantFilter => '定数フィルター';

  @override
  String get flowAnyDifficulty => 'いずれかの難易度';

  @override
  String get flowDifficultyCombination => '難易度の組み合わせ';

  @override
  String get flowClearConstants => '定数をクリア';

  @override
  String get flowMinimum => '最小値';

  @override
  String get flowMaximum => '最大値';

  @override
  String get flowNoteCountFilter => 'ノーツ数フィルター';

  @override
  String get flowMinimumNotes => '最小ノーツ数';

  @override
  String get flowMaximumNotes => '最大ノーツ数';

  @override
  String get flowBPMFilter => 'BPM フィルター';

  @override
  String get flowMinimumBPM => '最小 BPM';

  @override
  String get flowMaximumBPM => '最大 BPM';

  @override
  String get flowVersionFilter => 'バージョンフィルター';

  @override
  String get flowGenreFilter => 'ジャンルフィルター';

  @override
  String get flowTagFilter => 'タグフィルター';

  @override
  String get flowNoTagData => 'タグデータがありません';

  @override
  String get flowCharterFilter => '譜面制作者フィルター';

  @override
  String get flowArtistFilter => 'アーティストフィルター';

  @override
  String get flowClearSelection => '選択をクリア';

  @override
  String flowLevelP0(String p0) {
    return 'レベル $p0';
  }

  @override
  String get flowDXChartsOnly => 'DX 譜面のみ';

  @override
  String get flowTitlesOnly => '曲名のみ';

  @override
  String get flowSearching => '検索中…';

  @override
  String get flowEnterASearchKeyword => 'キーワードを入力してください';

  @override
  String flowP0SongsInTheLibraryEnterA(String p0) {
    return '曲庫は$p0曲です。キーワードを入力してください';
  }

  @override
  String flowP0SongsFound15PerPage(String p0) {
    return '$p0曲が見つかりました・1ページ15曲';
  }

  @override
  String get flowReset => 'リセット';

  @override
  String get flowNoSongsMatchTheseFilters => '条件に一致する楽曲がありません';

  @override
  String get flowTryAWiderConstantRangeOrClear => '定数の範囲を広げるかフィルターを解除してください';

  @override
  String get flowPrevious => '前へ';

  @override
  String get flowNext => '次へ';

  @override
  String flowCoverIndexReadyProcessedP0Covers(String p0) {
    return 'ジャケット索引を作成しました。$p0枚を処理しました';
  }

  @override
  String flowCouldNotBuildIndexP0(String p0) {
    return '索引の作成失敗：$p0';
  }

  @override
  String get flowChooseImageSource => '画像の取得元を選択';

  @override
  String get flowTakePhoto => '写真を撮る';

  @override
  String get flowPhotographCoverArt => 'カメラでジャケットを撮影';

  @override
  String get flowChooseACoverScreenshotFromYourGallery => 'アルバムからジャケット画像を選択';

  @override
  String get flowCameraPermissionRequired => 'カメラの許可が必要です';

  @override
  String flowCouldNotSelectImageP0(String p0) {
    return '画像の選択失敗：$p0';
  }

  @override
  String get flowRecognitionFailedTryAgain => '認識できませんでした。再試行してください';

  @override
  String flowRecognitionErrorP0(String p0) {
    return '認識エラー：$p0';
  }

  @override
  String get flowRebuildCoverIndex => 'ジャケット索引を再作成';

  @override
  String get flowThisClearsTheIndexAndRecalculatesHashes =>
      '現在の索引を削除して全ジャケットのハッシュを再計算します。数十秒かかる場合があります。続けますか？';

  @override
  String get flowRebuild => '再作成';

  @override
  String get flowLoading3 => '読み込み中…';

  @override
  String get flowBuildingCoverIndex => 'ジャケット索引を作成中…';

  @override
  String flowComputingFeaturesForP0Covers(String p0) {
    return '$p0枚のジャケットの特徴を計算';
  }

  @override
  String get flowNeededOnlyOncePleaseWait => '初回のみ必要です。お待ちください';

  @override
  String get flowTakeOrChooseACoverImage => 'ジャケット画像を撮影・選択';

  @override
  String get flowCropTheCoverRegionAfterSelectingFor =>
      '選択後にジャケット部分を切り抜くと認識精度が上がります';

  @override
  String get flowImageReady => '画像の準備完了';

  @override
  String get flowMatchConfidenceIsTooLowThisMay =>
      '一致度が低いため、ジャケット以外の可能性があります。切り抜く範囲を調整して再試行してください';

  @override
  String get flowInputImage => '入力画像';

  @override
  String get flowMatchedCover => '一致したジャケット';

  @override
  String get flowCombinedMatchUnreliable => '総合一致（信頼度低）';

  @override
  String get flowCombinedMatch => '総合一致';

  @override
  String get flowTop10Matches => '認識結果 上位10件';

  @override
  String flowSongP0(String p0) {
    return '楽曲 #$p0';
  }

  @override
  String get flowChooseImage => '画像を選択';

  @override
  String get flowRecognizing => '認識中…';

  @override
  String get flowStartRecognition => '認識を開始';

  @override
  String get flowCropAgain => '再切り抜き';

  @override
  String get flowChooseAgain => '選び直す';

  @override
  String get flowRecognizeAgain => '再認識';

  @override
  String get flowChooseAnother => '別の画像を選択';

  @override
  String get flowCoverIndexReady => 'ジャケット索引の準備完了';

  @override
  String get flowIndexNotBuilt => '索引未作成';

  @override
  String get flowRebuildIndex => '索引を再作成';

  @override
  String get flowCannotReadThisImageTryAnother => '画像を読み込めません。別の画像を試してください';

  @override
  String get flowCropFailedContinuingWithTheOriginalImage =>
      '切り抜きに失敗したため元の画像を使います';

  @override
  String get flowDragTheCornersToSelectCoverArt => '角をドラッグしてジャケット部分を選択';

  @override
  String get flowProcessing => '処理中…';

  @override
  String get flowDragCornersToResizeDragInsideTo => '四隅でサイズ変更・枠内で移動';

  @override
  String get flowNoDivingFishImportTokenSignIn =>
      '水魚の Import-Token がありません。先にログインしてください';

  @override
  String flowAddedToDivingFishP0(String p0) {
    return '水魚に追加しました：$p0';
  }

  @override
  String flowDivingFishScoreUpdatedP0(String p0) {
    return '水魚の成績を更新しました：$p0';
  }

  @override
  String get flowCannotParseSongIDForLXNSSync => '楽曲 ID を解析できないため落雪に同期できません';

  @override
  String get flowNoLXNSPersonalAPIKeySetIt =>
      '落雪の個人 API キーがありません。先に「成績取り込み認証情報」で設定してください';

  @override
  String get flowPhotographTheCabinetResultScreen => '筐体のリザルトを撮影';

  @override
  String get flowChooseAPhotographedResultScreen => '撮影済みのリザルトを選択';

  @override
  String get flowNoScoreRecognizedCropCloserToThe =>
      '成績を認識できません。リザルト部分をより近く切り抜いて再試行してください';

  @override
  String get flowCorrectRecognitionResults => '認識結果を修正';

  @override
  String get flowRecognitionIsNotAlwaysAccurateEditedValues =>
      '認識には誤りがあり得ます。編集した値はカードの表示に直接反映されます';

  @override
  String get flowDifficulty => '難易度';

  @override
  String get flowSelectASongFirstToListIts => '先に楽曲を選ぶと、その楽曲の難易度を表示します';

  @override
  String flowConstantP0(String p0) {
    return '定数 $p0';
  }

  @override
  String flowConstantP02(String p0) {
    return '・定数 $p0';
  }

  @override
  String get flowAchievement => '達成率（%）';

  @override
  String get flowDXScore => 'DX スコア';

  @override
  String get flowCombo => 'コンボ';

  @override
  String get flowSync => 'シンク';

  @override
  String get flowEmptyMeansNoMarkerSyncMarkersUse =>
      '「なし」はマーク未設定です。シンクは水魚の値（FS / FS+ / FDX / FDX+ / SYNC）で送信します。';

  @override
  String get flowRestoreRecognizedValues => '認識結果に戻す';

  @override
  String get flowEmpty => 'なし';

  @override
  String get flowNoSongData => '楽曲データがありません';

  @override
  String get flowNoMatchingSong => '一致する楽曲がありません';

  @override
  String get flowRecognizingScores => '成績を認識中';

  @override
  String get flowMatchingCoverArtAndTitlesUsuallyTakes =>
      'ジャケットと曲名で照合します。通常は数秒かかります';

  @override
  String get flowPhotographACabinetResultScreen => '筐体リザルトを撮影してください';

  @override
  String get flowRecognizesTitleAchievementDXScoreDifficultyAnd =>
      '曲名・達成率・DX スコア・難易度・FC/FS を認識';

  @override
  String get flowImageReadyTapStartRecognitionBelow =>
      '画像の準備ができました。下の「認識を開始」を押してください';

  @override
  String flowRecognitionCompleteP0P1Succeeded(String p0, String p1) {
    return '認識完了・$p0/$p1件成功';
  }

  @override
  String get flowCouldNotRecognizeAScore => '成績を認識できませんでした';

  @override
  String get flowSongTitleNotRecognized => '曲名を認識できませんでした';

  @override
  String get flowAchievement2 => '達成率';

  @override
  String flowMatchSourceP0(String p0) {
    return '一致した情報：$p0';
  }

  @override
  String get flowEditThisResult => 'この項目を編集';

  @override
  String get flowSyncing => '同期中…';

  @override
  String get flowSyncToDivingFish => '水魚に同期';

  @override
  String get flowSyncToLXNS => '落雪に同期';

  @override
  String flowCannotSyncYetP0(String p0) {
    return 'まだ同期できません：$p0';
  }

  @override
  String flowOtherCandidatesP0(String p0) {
    return '他の候補：$p0';
  }

  @override
  String get flowRecognizeAgain2 => '再認識';

  @override
  String get flowUseAnotherImage => '別の画像に変更';

  @override
  String get flowClearAndChooseAgain => 'クリアして選び直す';

  @override
  String get flowSignInToMaimaiScoreHubFirst => '先に maimai Score Hub にログイン';

  @override
  String get flowResultRecognitionRequiresSignInRequestA =>
      'リザルト認識にはログインが必要です。「舞萌・中二」公式 WeChat のログイン QR を開き、読み取った文字列を入力してください。認証のみ行い、成績の取得や同期はしません。ログイン状態は端末に保存します。';

  @override
  String get flowSigningIn2 => 'ログイン中…';

  @override
  String get flowDragCornersToSelectTheResultArea => '角をドラッグしてリザルト部分を選択';

  @override
  String get flowStoragePermissionIsNeededToSaveVersion =>
      'バージョン画像を保存するにはストレージの許可が必要です。設定で有効にしてください';

  @override
  String get flowImageSavedToGallery => '画像をアルバムに保存しました';

  @override
  String flowSaveFailedP0(String p0) {
    return '保存失敗：$p0';
  }

  @override
  String get flowSaveImage => '画像を保存';

  @override
  String get flowJapan => '日本版';

  @override
  String get flowChina => '中国版';

  @override
  String get flowJapanVersion => '日本版バージョン';

  @override
  String get flowChinaVersion => '中国版バージョン';

  @override
  String flowP0VersionsInReleaseOrderTapAn(String p0) {
    return 'リリース順に$p0バージョンを表示します。画像を押すと拡大・保存できます。';
  }

  @override
  String flowP0VersionImageNotAvailableYet(String p0) {
    return '$p0、バージョン画像は準備中';
  }

  @override
  String flowP0ViewVersionImage(String p0) {
    return '$p0、バージョン画像を表示';
  }

  @override
  String get flowImagePending => '画像準備中';

  @override
  String get flowVersionImageNotAvailableYet => 'バージョン画像は準備中です';

  @override
  String get flowTapToEnlarge => 'タップして拡大';

  @override
  String get flowAboutThisComparison => '比較基準について';

  @override
  String get flowNoSongsInThisSection => 'この範囲に楽曲はありません';

  @override
  String get flowChinaDivingFishUpdateFrontier => '中国版（水魚）の更新到達点';

  @override
  String flowJapanDebutP0P1(String p0, String p1) {
    return '日本版初登場 $p0・$p1';
  }

  @override
  String get flowFirstReleaseMeansTheJapanReleaseDate =>
      '初登場日は日本版の日時で、中国版の日時ではありません。候補は初登場日と確認済み未収録バッチから選び、日付がない場合のみ ID を参照します。ID が小さい新曲も含みます。';

  @override
  String flowExcludedP0SongsReleasedEarlyInChina(String p0, String p1) {
    return '中国版先行の$p0曲（$p1）を除外しました。到達点が押し上げられ、未収録曲が候補から外れるのを防ぎます。';
  }

  @override
  String flowP0P1JapanP2(String p0, String p1, String p2) {
    return '#$p0・$p1・日本版 $p2';
  }

  @override
  String get flowNoCachedLibraryYet => '曲庫のキャッシュがありません';

  @override
  String get flowThisPageUsesTheLocalDivingFish =>
      'このページは水魚＋union のローカル曲庫を使用します。\n先にホームで「成績取得とデータ更新」を実行してから戻ってください。';

  @override
  String get flowHowThisPageWorks => 'このページの基準';

  @override
  String get flow1DataSources => '1. データの取得元';

  @override
  String get flowTheLocalLibraryCombinesDivingFishAll =>
      'ローカル曲庫は水魚（中国版全曲）と union（全曲）を統合しています。union のみの曲には isExtra を付け、確認済み中国先行曲の一覧を優先します。このページは完全にオフラインで使えます。';

  @override
  String get flow2DefiningTheUpdateFrontier => '2. 更新到達点の決め方';

  @override
  String get flowRegularChinaSongsInDivingFishAre =>
      '水魚の中国版通常曲を初登場日の新しい順に並べ、先頭を中国版の到達点とします。日付がない・不正な場合は ID を参照します。\n宴（6桁 ID）と maidata 追加曲は対象外です。\n中国版先行曲も除き、実際の未収録曲が隠れないようにします。';

  @override
  String get flow3CompletingTheCandidateList => '3. 候補の補完';

  @override
  String get flowStartWithUnionOnlyRegularSongsUsing =>
      'union のみの通常曲を取り、到達点の日本版初登場日を基準にします。確認済み未収録バッチに古い曲があれば、その最古の日付まで広げます。\n同日や小さい ID も含め、基準日以降の曲をすべて採用します。\n日付がない・不正な場合のみ ID を参照し、確認済み未収録曲は必ず残します。\n古い曲は別に表示し、地域限定とは断定しません。候補は参考で、実際の更新は公式告知に従います。';

  @override
  String get flow4WhatFirstReleaseMeans => '4. 初登場日について';

  @override
  String get flowTheDebutDatesFromDivingFishAnd =>
      '水魚と union の初登場日は日本版の日付で、中国版の配信日ではありません。楽曲詳細の初登場日だけでは中国版の収録状況を判断できないのはこのためです。';

  @override
  String get flowUpdateDataTemporarilyUnavailable => '更新データを取得できません';

  @override
  String get flowRetry => '再試行';

  @override
  String get flowReleaseContents => '配信内容';

  @override
  String get flowCouldNotLoadReleaseDataRetry => '配信データを読み込めません。再試行してください';

  @override
  String get flowNoContentDetails => '内容の詳細はありません';

  @override
  String flowP0OtherItemsNotShown(String p0) {
    return '他$p0件は省略';
  }

  @override
  String get flowLXNSMaimaiDXScoreTracker => '落雪 maimai DX スコアサービス';

  @override
  String get flowPreviousMonthWithUpdates => '更新のある前の月';

  @override
  String flowChooseYearAndMonthCurrentP0P1(String p0, String p1) {
    return '年月を選択。現在：$p0年$p1月';
  }

  @override
  String flowP0P1(String p0, String p1) {
    return '$p0年$p1月';
  }

  @override
  String get flowReleaseRecordOnly => '配信記録のみ';

  @override
  String flowP0UpdatesP1Songs(String p0, String p1) {
    return '$p0回更新・$p1曲';
  }

  @override
  String get flowNextMonthWithUpdates => '更新のある次の月';

  @override
  String get flowRelease => '配信';

  @override
  String flowP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '$p0月$p1日$p2$p3';
  }

  @override
  String flowP0Songs(String p0) {
    return '、$p0曲';
  }

  @override
  String get flowReleaseRecorded => '、配信記録あり';

  @override
  String get flowNotReleasedYet => '  未配信';

  @override
  String get flowReleaseRecord => '配信記録';

  @override
  String flowP0SongsP1Charts(String p0, String p1) {
    return '$p0曲・$p1譜面';
  }

  @override
  String flowMonthP0(String p0) {
    return '$p0月';
  }

  @override
  String get flowChooseYearAndMonth => '年月を選択';

  @override
  String flowYearP0(String p0) {
    return '$p0年';
  }

  @override
  String get flowNoData => 'データがありません';

  @override
  String flowLvP0P1SongsP2Played(String p0, String p1, String p2) {
    return 'Lv.$p0\n全$p1曲\nプレイ済み$p2曲';
  }

  @override
  String flowLvP0P1P2Songs(String p0, String p1, String p2) {
    return 'Lv.$p0 $p1（全$p2曲）';
  }

  @override
  String get flowFilterTitleBackgroundColors => '称号の背景色で絞り込み';

  @override
  String get flowChooseMultipleColors => '複数の色を選択できます';

  @override
  String get flowApply => '適用';

  @override
  String get flowCacheClearedReloading => 'キャッシュを削除しました。再読み込み中…';

  @override
  String get flowCouldNotClearCache => 'キャッシュを削除できませんでした';

  @override
  String get flowSearchCollectibleNamesDescriptionsOrIDs => 'コレクション名・説明・ID で検索';

  @override
  String get flowSongRequirements => '楽曲条件あり';

  @override
  String get flowBackgroundColor => '背景色';

  @override
  String get flowIDDescending => 'ID 降順';

  @override
  String get flowIDAscending => 'ID 昇順';

  @override
  String flowP0Items(String p0) {
    return '$p0件';
  }

  @override
  String get flowHasUnlockRequirements => '獲得条件あり';

  @override
  String get flowNoMatchingCollectibles => '一致するコレクションがありません';

  @override
  String get flowClearCacheAndReload => 'キャッシュを削除して再読み込み';

  @override
  String get flowPermissionRequired => '許可が必要です';

  @override
  String get flowStoragePermissionIsNeededToSaveImages =>
      '画像の保存にはストレージの許可が必要です。設定で有効にしてください';

  @override
  String get flowExcludedSongs => '対象外の楽曲';

  @override
  String flowP0SongsExcludedFromRequirements(String p0) {
    return '全$p0曲、条件には含みません';
  }

  @override
  String get flowSongList => '楽曲一覧';

  @override
  String flowP0SongsTotal(String p0) {
    return '合計$p0曲';
  }

  @override
  String flowTranslatedFromP0ByBaiduSLanguage(String p0) {
    return 'Baidu の言語モデルで$p0から翻訳';
  }

  @override
  String get flowTranslateToChinese => '中国語に翻訳';

  @override
  String get flowSaving2 => '保存中';

  @override
  String get flowSaveToGallery => 'アルバムに保存';

  @override
  String get flowCopyLink => 'リンクをコピー';

  @override
  String get flowDescription => '説明';

  @override
  String get flowUnlockRequirements => '獲得条件';

  @override
  String flowP0Details(String p0) {
    return '$p0の詳細';
  }

  @override
  String get flowCollectibleNotFound => 'コレクション情報がありません';

  @override
  String get flowCouldNotRefreshData => 'データを更新できませんでした';

  @override
  String flowQQP0HasNotAuthorizedThisApp(String p0) {
    return 'QQ $p0 は本アプリを未認証です。「アカウントと同期」で認証してください';
  }

  @override
  String get flowAuthorizationNeeded => '認証が必要です';

  @override
  String get flowThisQQHasNotAuthorizedTheApp =>
      'この QQ は本アプリを未認証です。認証ページで完了後、再度データを更新してください';

  @override
  String get flowThisQQHasNotAuthorizedTheApp2 =>
      'この QQ は本アプリを未認証です。ブラウザーで認証ページを開いて連携してください';

  @override
  String flowCouldNotRefreshDataP0(String p0) {
    return 'データの更新失敗：$p0';
  }

  @override
  String get flowSigningOutOfDivingFish => '水魚からログアウト中…';

  @override
  String get flowEnterYourDivingFishUsernameAndPassword =>
      '水魚のユーザー名とパスワードを入力してください';

  @override
  String get flowCouldNotLinkDivingFishTryAgain => '水魚を連携できませんでした。再試行してください';

  @override
  String get flowSyncSucceededRefreshingLocalData => '同期しました。ローカルデータを更新中…';

  @override
  String get flowExportFailedTryAgain => '書き出しに失敗しました。再試行してください';

  @override
  String get flowPreparingSync => '同期の準備中…';

  @override
  String flowP0ScoresSentToDivingFishSign(String p0) {
    return '水魚に$p0件の成績を送信しました。\nローカルデータの自動更新には水魚へのログインが必要です。';
  }

  @override
  String get flowSyncCancelled => '同期をキャンセルしました';

  @override
  String get flowEnterUsernameAndPassword => 'ユーザー名とパスワードを入力してください';

  @override
  String flowWelcomeP0P1(String p0, String p1) {
    return 'ようこそ、$p0$p1';
  }

  @override
  String get flowAdvancedDataRefreshInProgress => '詳細データ更新中…';

  @override
  String get flowRefreshingData => 'データ更新中…';

  @override
  String flowCouldNotLoadAccountDetailsP0(String p0) {
    return 'アカウント情報を取得できません（$p0）';
  }

  @override
  String get flowNickname => 'ニックネーム';

  @override
  String get flowVersionTitle => 'バージョン称号';

  @override
  String get flowRatingRank => 'Rating 段位';

  @override
  String get flowLinkedQQ => '連携 QQ';

  @override
  String get flowChannelID => 'チャンネル ID';

  @override
  String get flowBeginner => '初心者';

  @override
  String get flow1stDan => '初段';

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
  String get flowShinKaiden => '真皆伝';

  @override
  String get flowUraKaiden => '裏皆伝';

  @override
  String get flowRefreshingMaidata => 'maidata 更新中…';

  @override
  String flowCouldNotOpenQQGroupIDP0(String p0) {
    return 'QQ を開けません。グループ番号 $p0 をコピーしました。QQ で検索して参加してください';
  }

  @override
  String get flowSongSearchFailedTheLibraryMayNot =>
      '楽曲検索に失敗しました。曲庫の読み込みが終わっていない可能性があります';

  @override
  String get flowPreparingToReadCabinetPlayCount => '筐体プレイ回数の取得準備中…';

  @override
  String get flowSigningOutOfDivingFish2 => '水魚からログアウト中…';

  @override
  String get flowStartQRSyncFromHome => 'ホームの同期入口から QR 同期を開始してください';

  @override
  String get flowStartSyncFromHome => 'ホームの同期入口から開始してください';

  @override
  String get flowEnterYourPersonalKeyAboveToEnable => '上の個人キーを入力すると有効にできます';

  @override
  String flowNoP0AccountYetSignInThrough(String p0) {
    return '$p0 のアカウントがありません。「連携と認証の管理」でログインし、データを更新してください';
  }

  @override
  String get flowSyncCredentialsReady => '同期用認証情報の準備完了';

  @override
  String get flowLinkTheCabinetIdentityAboveToEnable => '上の筐体 ID を連携すると有効にできます';

  @override
  String get flowCouldNotReadSyncCredentialsTryAgain =>
      '同期用認証情報を取得できません。再試行してください';

  @override
  String get flowCouldNotReadAutoSyncStatusTry => '自動同期の状態を取得できません。再試行してください';

  @override
  String get flowLinkCabinetIdentityAboveFirst => '先に上で筐体 ID を連携してください';

  @override
  String get flowSyncSetupIncomplete => '同期の設定が未完了';

  @override
  String flowAccountEndingInP0(String p0) {
    return 'アカウント末尾 $p0';
  }

  @override
  String get flowStatusNotConfirmedYet => '状態は未確認です';

  @override
  String flowP0QueueUserPositionP1(String p0, String p1) {
    return '$p0のキュー・ユーザー$p1番目';
  }

  @override
  String get flowEnabledWaitingForSchedule => '有効・定時実行待ち';

  @override
  String get flowSyncing2 => '同期中';

  @override
  String get flowPreviousRoundNoRunYet => '前回・実行記録なし';

  @override
  String get flowPreviousRoundUpToDateNoUpload => '前回は最新・送信不要';

  @override
  String flowPreviousRoundCompleteSubmittedP0(String p0) {
    return '前回完了・$p0件送信';
  }

  @override
  String flowPreviousRoundIncompleteP0(String p0) {
    return '前回未完了$p0';
  }

  @override
  String flowSubmittedP0(String p0) {
    return '・$p0件送信済み';
  }

  @override
  String flowPreviousRoundP0(String p0) {
    return '前回・$p0';
  }

  @override
  String get flowLoadingStatistics => '統計を読み込み中';

  @override
  String get flowUpdateFailed => '更新失敗';

  @override
  String get flowUpdatesEvery3Seconds => '3秒ごとに更新';

  @override
  String get flowQueuedUsers => '待機ユーザー';

  @override
  String get flowPendingTasks => '待機タスク';

  @override
  String get flowProcessing2 => '処理中';

  @override
  String get flowProcessedUsers => '処理済みユーザー';

  @override
  String get flowSuccessfulUsers => '成功ユーザー';

  @override
  String get flowFailedUsers => '失敗ユーザー';

  @override
  String flowSubmittedP0P1(String p0, String p1) {
    return '$p0件送信済み$p1';
  }

  @override
  String flowSkippedP0UnsupportedCharts(String p0) {
    return '、未対応譜面$p0件をスキップ';
  }

  @override
  String flowConfirmedP0Submitted(String p0) {
    return '（$p0件の送信を確認済み）';
  }

  @override
  String get flowWaitingForScheduledRun => '定時実行待ち';

  @override
  String get flowWaitingToBeScheduled => '実行予定待ち';

  @override
  String get flowEnterACabinetLoginQRCodeFirst => '先に筐体ログイン QR を入力してください';

  @override
  String get flowLinkFailedCheckTheQRHasNot => '連携できません。QR の有効期限を確認して再試行してください';

  @override
  String get flowEnterYourPersonalKeyFirst => '先に個人キーを入力してください';

  @override
  String get flowAccountChangedRefreshThisPageAndEnter =>
      'アカウントが変わりました。ページを更新して再入力してください';

  @override
  String get flow1SignInThroughMeSignIn =>
      '①「マイページ → 連携と認証の管理」で水魚にログインし、ImportToken を取得します。\n②「成績取り込み認証情報 → 水魚 成績取り込み Token」をコピーします。\n③ ここに貼り付けて保存します。';

  @override
  String get flowQuickSyncing => 'クイック同期中…';

  @override
  String get flowCheckingAWMCGateway => 'AWMC ゲートウェイを確認中…';

  @override
  String flowAWMCGatewayUnavailableP0SyncCancelledNo(String p0) {
    return 'AWMC ゲートウェイを利用できません（$p0）。同期を中止しました。Token は消費していません';
  }

  @override
  String flowSyncingToP0ThroughAWMCGateway(String p0) {
    return 'AWMC ゲートウェイで$p0に同期中…';
  }

  @override
  String flowP0ScoresAreUpToDateNo(String p0) {
    return '$p0 の成績は最新です。送信不要です';
  }

  @override
  String flowQuickSyncCompleteSubmittedP1ChangedScores(String p0, String p1) {
    return 'クイック同期完了。$p0に変更のある成績を$p1件送信しました';
  }

  @override
  String flowP0ScoresTotal(String p0) {
    return '合計$p0件の成績';
  }

  @override
  String get flowSentToDivingFishThroughAWMCGateway => 'AWMC ゲートウェイから水魚に送信しました';

  @override
  String get flowExportedToLXNSThroughAWMCGateway => 'AWMC ゲートウェイから落雪に書き出しました';

  @override
  String flowSyncCompleteP0P1(String p0, String p1) {
    return '同期完了。$p0$p1';
  }

  @override
  String get flowNoCachedDivingFishImportTokenSignIn =>
      '水魚の ImportToken が未保存です。経路2（maimai Score Hub）で一度ログイン・同期すると端末に保存されます。';

  @override
  String get flowNoCachedLXNSPersonalAPIKeySync =>
      '落雪の個人 API キーが未保存です。一度同期してキーを入力すると端末に保存されます。';

  @override
  String get flowReadingCabinetPlayCount => '筐体プレイ回数を取得中…';

  @override
  String get flowEndpoint => 'エンドポイント';

  @override
  String get flowResult => '結果';

  @override
  String get flowBusinessOperationSucceeded => '処理成功';

  @override
  String flowUpstreamMessageTruncatedFullLengthP0Characters(String p0) {
    return '上流メッセージが長いため省略しました（全$p0文字）';
  }

  @override
  String get flowDuration => '所要時間';

  @override
  String get flowBilling => '料金';

  @override
  String get flowGetThisTokenFromTheAWMCConsole =>
      'AWMC コンソール（api.wmc.pub）で取得する gw_xxxx 形式の Token です。\n\n⚠️ アカウント操作と残高を利用できる情報です。スクリーンショットやチャット・公開リポジトリへの貼り付けは避けてください。漏えいが疑われる場合はコンソールで失効させ、再発行してください。';

  @override
  String get flowTokenStaysOnThisDeviceCanBe =>
      'Token はこの端末に保存し、いつでも削除できます。バックアップには含みません。';

  @override
  String get flowEnterCabinetQRCode => '筐体 QR コードを入力';

  @override
  String get flowUsedOnlyForThisOperationThenDiscarded =>
      '今回の操作にのみ使用し、保存せず破棄します。次回は改めて入力してください。';

  @override
  String get flowUse => '使用';

  @override
  String get flowThisKeyIsSentOnlyWithThis =>
      'キーは今回のリクエストで AWMC ゲートウェイに送信するだけで、端末には保存しません。';

  @override
  String get flowContinue => '続行';

  @override
  String get flowTokenCost => 'Token 消費量';

  @override
  String flowP0ChargedOnlyOnSuccess(String p0) {
    return '$p0（成功時のみ消費）';
  }

  @override
  String get flowNoTokenSpent => '消費なし';

  @override
  String get flowReversible => '取り消し可否';

  @override
  String get flowYesUploadAgainToOverwrite => '可能（再送信で上書き）';

  @override
  String get flowNo => '不可';

  @override
  String get flowIUnderstandTheEffectsAboveAndConfirm =>
      '上記の影響を確認し、自分のアカウントの QR であることを確認しました';

  @override
  String get flowWrite => '書き込み';

  @override
  String flowImportingScoresWaitingP0Seconds(String p0) {
    return '成績を取り込み中… $p0秒待機';
  }

  @override
  String get flowImportFailed => '取り込み失敗';

  @override
  String get flowScoresAreUpToDateNoUpload => '成績は最新です。送信不要です';

  @override
  String flowQuickSyncCompleteSubmittedP0ChangedScores(String p0) {
    return 'クイック同期完了。変更のある成績を$p0件送信しました';
  }

  @override
  String flowImportCompleteAddedP0UpdatedP1(String p0, String p1) {
    return '取り込み完了。追加$p0件 / 更新$p1件';
  }

  @override
  String flowSkippedP0(String p0) {
    return ' / スキップ$p0件';
  }

  @override
  String flowP0Seconds(String p0) {
    return '（$p0秒）';
  }

  @override
  String flowP0ChartsAreNotYetInAWMC(String p0) {
    return '。$p0譜面は AWMC NET に未収録です';
  }

  @override
  String flowP0Account(String p0) {
    return '$p0 アカウント';
  }

  @override
  String get flowNotLinked => '未連携';

  @override
  String get flowThenChooseRegisterUnderQuickActionsOn =>
      '。右側の「クイック操作」から「登録」を選んでください。';

  @override
  String get flowFollowThePageInstructionsToRegisterA =>
      'ページの案内に従って水魚アカウントを登録してください。';

  @override
  String get flowAfterSigningInOpenEditProfileAt =>
      'ログイン後、右上のプロフィール編集を開き、次の項目を設定してください：';

  @override
  String get flowScoreImportTokenRotateItUsingThe =>
      '成績取り込み Token：右の更新アイコンで必ず再発行してください。未更新ではアプリからログインできません。';

  @override
  String get flowLinkedQQRequiredAvoidUsingTheSame =>
      '連携 QQ：必須です。サブアカウントと同じ QQ は避けてください。';

  @override
  String get flowNicknameRecommendedWithoutOneTheAppSaves =>
      'ニックネーム：入力を推奨します。空欄の場合は shuiyu:QQ 形式で保存します。';

  @override
  String get flowChannelIDAndRankNoSpecificRequirements =>
      'チャンネル ID と段位：特に指定はありません。';

  @override
  String get flowDisablePreventPublicAPIsFromUsingMy =>
      '「公開 API に自分の成績を使用させない」は無効にしてください。';

  @override
  String get flowDisableMaskingScoresForNonWebQueries =>
      '「ウェブ以外の照会では成績をマスクする」は無効を推奨します。マスクはランキングに影響します。';

  @override
  String get flowRememberToSaveAfterMakingChanges => '変更後は忘れずに保存してください。';

  @override
  String get flowThenChooseNewUserRegistrationInThe =>
      '。左の「新規登録」または中央の「maimai DX アカウント登録」を選んでください。';

  @override
  String get flowFollowThePageInstructionsToRegisterAn =>
      'ページの案内に従って落雪アカウントを登録してください。';

  @override
  String get flowAfterSigningInOpenAccountDetailsIn =>
      'ログイン後、左のアカウント詳細から「外部アプリ」を開いてください：';

  @override
  String get flowOAuthInMeRefreshDataChooseLXNS =>
      'OAuth 認証：アプリの「マイページ → 成績取得とデータ更新」で落雪を選び、案内に従って認証すると、OAuth アプリ一覧に ChiffonMai が表示されます。';

  @override
  String get flowPersonalAPIKeyResetItThenPaste =>
      '個人 API キー：「API キーをリセット」で発行し、アプリの「マイページ → 成績取り込み認証情報 → 落雪 API キー」に貼り付けてください。';

  @override
  String get flowYouCanAlsoVisitChiffonChuFromThe =>
      '「プレイ → アーケード」のバナーから ChiffonChu にもアクセスできます。';

  @override
  String get flowMessage => '個別チャット：';

  @override
  String get flowPrivatelyOrFollowTheseStepsInA =>
      '、またはボットのいるグループで次の手順を進めてください：';

  @override
  String get flowSendTheSGWCMAIDStringOrMaimaiQR =>
      '案内に従って SGWCMAID 文字列か maimai QR を送信し、ボットの完了返信を待ってください。';

  @override
  String get flowAndConfigureTheseSettings => '。次の項目を設定してください：';

  @override
  String get flowEnableMakeMyScoresPublicOrScores =>
      '「自分の成績を公開する」を必ず有効にしてください。無効では成績を取得できません。';

  @override
  String get flowImportTokenRegenerateItThenPasteIt =>
      'Import-Token：再発行して、アプリの「マイページ → 成績取り込み認証情報 → AWMC 成績取り込み Token」に貼り付けてください。';

  @override
  String get flowRotatingATokenReplacesTheOldOne =>
      'Token を再発行すると以前の Token は置き換わります。アプリ内も手動更新してください。未更新では同期できません。';

  @override
  String get flowJoin => '参加：';

  @override
  String get flowCouldNotOpenQQAWMCGroup1 =>
      'QQ を開けません。AWMC グループ1の番号をコピーしました。QQ で検索して参加してください';

  @override
  String get flowCouldNotOpenQQAWMCGroup2 =>
      'QQ を開けません。AWMC グループ2の番号をコピーしました。QQ で検索して参加してください';

  @override
  String get flowCloseImage => '画像を閉じる';

  @override
  String get flowTheAppNeedsYourLinkedQQBefore =>
      '水魚の成績取得にはアカウントに連携した QQ が必要です。\n「マイページ → 水魚にログイン」でログインしてから戻ってください。';

  @override
  String get flowTheAppIdentifiesYourDivingFishAccount =>
      '本アプリは QQ で水魚アカウントを識別しますが、連携 QQ が空欄です。\nログインの問題ではありません。プロフィールの QQ を入力すると成績を取得できます。';

  @override
  String get flow1OpenDivingFishAndSignIn => '① 水魚の公式サイトを開いてログイン';

  @override
  String get flow2OpenEditProfileEnterLinkedQQ => '② プロフィール編集で連携 QQ を入力して保存';

  @override
  String get flow3ReturnAndTapISavedIt => '③ 戻って「入力済み・再取得」を押す';

  @override
  String get flowSignInToMaimaiScoreHubFirst2 =>
      '先に maimai Score Hub にログインしてください';

  @override
  String get flowPasteOrScanALoginQRCode => 'ログイン QR を貼り付けるか読み取ってください';

  @override
  String get flowUseALoginQRFromTheMaimai =>
      '「舞萌・中二」公式 WeChat のログイン QR を使用してください';

  @override
  String get flowMaimaiScoreHubSignInFailedThe =>
      'maimai Score Hub にログインできません。QR の有効期限切れの可能性があるため再発行してください';

  @override
  String flowSignInFailedP0(String p0) {
    return 'ログイン失敗：$p0';
  }

  @override
  String get flowNoLXNSPersonalAPIKeySetConfigure =>
      '落雪の個人 API キーが未設定です。先に「成績取り込み認証情報」で設定してください';

  @override
  String get flowQuickSyncSupportsRoute1Only => 'クイック同期は経路1のみ対応です';

  @override
  String get flowMaimaiScoreHubSessionExpiredSignIn =>
      'maimai Score Hub のログイン期限が切れました。経路2の同期前に再ログインしてください';

  @override
  String get flowSyncCompleteRefreshingLocalData => '同期完了。ローカルデータを更新中…';

  @override
  String get flowLinkDivingFishToObtainAnImportToken =>
      'ImportToken の取得に水魚の連携が必要です。「水魚に同期」を開き直して連携してください';

  @override
  String get flowDoneLocalDataRefreshed => '完了しました。ローカルデータを更新しました';

  @override
  String get flowSyncComplete => '同期完了！';

  @override
  String flowP0ScoresSentToDivingFishData(String p0, String p1) {
    return '水魚に$p0件送信しました。\nデータ更新失敗：$p1';
  }

  @override
  String get flowDivingFishRoute2 => '水魚 経路2';

  @override
  String get flowSyncingScores => '成績を同期中…';

  @override
  String get flowLXNSRoute2 => '落雪 経路2';

  @override
  String get flowPreparingSync2 => '同期の準備中…';

  @override
  String get flowMultiPlatformRoute2 => '複数サービス 経路2';

  @override
  String flowEnterANewQRForP0P1(String p0, String p1) {
    return '$p0（$p1）用の新しい QR を入力してください…';
  }

  @override
  String flowThisQRIsUsedOnlyForThis(String p0, String p1) {
    return 'この QR は今回の$p0（$p1）にのみ使います。他の対象に使った QR は再利用できません。';
  }

  @override
  String get flowDirectQRUpload => 'QR 直接送信';

  @override
  String flowSyncingToP0P1(String p0, String p1) {
    return '$p0（$p1）に同期中…';
  }

  @override
  String flowP0UpToDate(String p0) {
    return '$p0（最新）';
  }

  @override
  String flowP0QuickSyncUpdatedP1(String p0, String p1) {
    return '$p0（クイック同期、$p1件更新）';
  }

  @override
  String flowP0Route1P1(String p0, String p1) {
    return '$p0（経路1）：$p1';
  }

  @override
  String flowP0Route1P1P2(String p0, String p1, String p2) {
    return '$p0（経路1）：$p1 $p2%';
  }

  @override
  String flowP0Route1(String p0) {
    return '$p0（経路1）';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub =>
      'maimai Score Hub に未ログインのため、水魚の経路2をスキップしました';

  @override
  String flowDivingFishRoute2P0P1(String p0, String p1) {
    return '水魚（経路2）：$p0 $p1%';
  }

  @override
  String flowDivingFishP0(String p0) {
    return '水魚：$p0';
  }

  @override
  String flowDivingFishRoute2P0Scores(String p0) {
    return '水魚（経路2、$p0件）';
  }

  @override
  String get flowNotSignedInToMaimaiScoreHub2 =>
      'maimai Score Hub に未ログインのため、落雪の経路2をスキップしました';

  @override
  String flowLXNSP0(String p0) {
    return '落雪：$p0';
  }

  @override
  String flowLXNSRoute2P0P1(String p0, String p1) {
    return '落雪（経路2）：$p0 $p1%';
  }

  @override
  String flowLXNSRoute2P0Scores(String p0) {
    return '落雪（経路2、$p0件）';
  }

  @override
  String get flowAWMCNETScoreImportTokenNotSet =>
      'AWMC NET 成績取り込み Token が未設定です';

  @override
  String get flowCouldNotReadSavedCredentialsTryAgain =>
      '保存した認証情報を取得できません。再試行してください。';

  @override
  String flowEnterP0(String p0) {
    return '$p0 を入力してください';
  }

  @override
  String get flowPersonalAPIKey => '個人 API キー';

  @override
  String get flowEnterA512DigitQQID => '5～12桁の QQ 番号を入力してください';

  @override
  String get flowCouldNotSaveQQID => 'QQ 番号を保存できませんでした';

  @override
  String get flowSelectAtLeastOneSourceWithCredentials =>
      '認証情報が揃ったソースを1つ以上選択してください';

  @override
  String get flowLXNSAuthorizationCodeMissing => '落雪の認証コードが未入力です';

  @override
  String flowNoLookupIDObtainedForP0(String p0) {
    return '$p0 の照会 ID を取得できませんでした';
  }

  @override
  String get flowStartingDataRefresh => 'データ更新を開始…';

  @override
  String get flowDataRefreshComplete => 'データ更新完了';

  @override
  String get flowClearingCaches => 'キャッシュを削除中…';

  @override
  String get flowRefreshingDataInParallel => 'データを並列更新中…';

  @override
  String get flowSongDataRefreshed => '楽曲データ更新済み';

  @override
  String get flowDifficultyDataRefreshed => '難易度データ更新済み';

  @override
  String get flowTagDataRefreshed => 'タグデータ更新済み';

  @override
  String get flowUserDataRetrieved => 'ユーザーデータ取得済み';

  @override
  String get flowCollectibleDataRefreshed => 'コレクション更新済み';

  @override
  String get flowAliasDataRefreshed => '別名データ更新済み';

  @override
  String get flowUnionDataRefreshed => 'Union データ更新済み';

  @override
  String get flowCouldNotFetchDivingFishScores => '水魚の成績を取得できませんでした';

  @override
  String get flowCalculatingRating => 'Rating を計算中…';

  @override
  String get flowSavingData => 'データを保存中…';

  @override
  String flowUploadingSongRankingsP0P1(String p0, String p1) {
    return '単曲ランキングを送信中 $p0/$p1…';
  }

  @override
  String get flowCouldNotRemoveLeaderboardEntries => 'ランキングを削除できませんでした';

  @override
  String get flowAWMCNETScoresRetrieved => 'AWMC NET 成績取得済み';

  @override
  String get flowObtainingAccessToken => 'アクセストークンを取得中…';

  @override
  String get flowRenewingAccessToken => 'アクセストークンを更新中…';

  @override
  String get flowAuthorizationFailedCheckYourCode => '認証に失敗しました。認証コードを確認してください';

  @override
  String get flowLXNSAuthorizationExpiredEnterANewAuthorization =>
      '落雪の認証期限が切れました。認証コードを再入力してください';

  @override
  String get flowAuthorizedRefreshingDataInParallel => '認証しました。データを並列更新中…';

  @override
  String get flowPreparingLXNSData => '落雪のデータを準備';

  @override
  String get flowLXNSProfileRetrieved => '落雪のプレイヤー情報取得済み';

  @override
  String get flowLXNSScoresRetrieved => '落雪の成績取得済み';

  @override
  String get flowCouldNotFetchLXNSProfileOrScores =>
      '落雪のプロフィールまたは成績を取得できませんでした';

  @override
  String get flowCouldNotConvertLXNSScores => '落雪の成績を変換できませんでした';

  @override
  String get flowCalculatingBest50 => 'Best50 を計算中…';

  @override
  String get flowMissingSongDataCannotCalculateLXNSRating =>
      '楽曲データがないため落雪の Rating を計算できません';

  @override
  String get flowInvalidBest50Data => 'Best50 データが不正です';

  @override
  String get flowInvalidBest35Data => 'Best35 データが不正です';

  @override
  String get flowInvalidBest15Data => 'Best15 データが不正です';

  @override
  String flowP0CheckForInvalidData(String p0) {
    return '$p0。不正なデータがないか確認してください';
  }

  @override
  String flowCouldNotUpdateLeaderboardDataP0(String p0) {
    return 'ランキングデータの更新失敗：$p0';
  }

  @override
  String flowLeaderboardUpdateErrorP0(String p0) {
    return 'ランキング更新エラー：$p0';
  }

  @override
  String get flowSongsAndCharts => '楽曲と譜面';

  @override
  String get flowTagsAndAliases => 'タグと別名';

  @override
  String get flowCollectibles => 'コレクション';

  @override
  String get flowMetadataAndExtras => 'メタデータと補助情報';

  @override
  String get flowNormal => '通常';

  @override
  String get flowQuick => 'クイック';

  @override
  String flowLoadingP0Statistics(String p0) {
    return '$p0の統計を読み込み中…';
  }

  @override
  String flowP0StatisticsUnavailable(String p0) {
    return '$p0の統計を取得できません';
  }

  @override
  String flowP0Last100NoRecords(String p0) {
    return '$p0：直近100回 / 記録なし';
  }

  @override
  String flowP0Last100P1SamplesAvgP22(
      String p0, String p1, String p2, String p3) {
    return '$p0：直近100回 / $p1件 / 平均$p2 / 成功$p3';
  }

  @override
  String get flowAverageDuration => '平均時間';

  @override
  String get flowSuccessRate => '成功率';

  @override
  String get flowSuccessfulSamples => '成功件数';

  @override
  String get flowLatestRun => '最近の実行';

  @override
  String get flowStatusUnconfirmed => '状態未確認';

  @override
  String get flowExpectedRetry => '再試行予定';

  @override
  String get flowLastRun => '最近の実行';

  @override
  String get flowRefreshPending => '更新待ち';

  @override
  String get flowStatusRefreshFailedTapToViewOr =>
      '状態を更新できません。タップして確認・再試行してください。以前の結果は今回確認された状態ではありません';

  @override
  String get flowSyncStatusNotReadYet => '同期状態はまだ未取得です';

  @override
  String flowP0UserP1OfP2(String p0, String p1, String p2) {
    return '$p0：ユーザー$p1番目 / $p2人';
  }

  @override
  String flowPreviousRoundP02(String p0) {
    return '前回：$p0';
  }

  @override
  String flowSuccessP0P1(String p0, String p1) {
    return '成功・$p0・$p1';
  }

  @override
  String flowFailedP0P1(String p0, String p1) {
    return '失敗・$p0・$p1';
  }

  @override
  String flowP0UserPositionP1(String p0, String p1) {
    return '$p0：ユーザー$p1番目';
  }

  @override
  String flowSyncFailedP03(String p0) {
    return '同期失敗・$p0';
  }

  @override
  String get flowSyncSucceeded => '同期成功';

  @override
  String flowSyncSucceededP0(String p0) {
    return '同期成功・$p0';
  }

  @override
  String get flowCorrectTheDifficultyCombinationConstantsFirst =>
      '先に難易度の組み合わせの定数入力を修正してください';

  @override
  String flowSearchFailedP0(String p0) {
    return '検索失敗：$p0';
  }

  @override
  String get flowAny => '制限なし';

  @override
  String get flowChooseACharter => '譜面制作者を選択';

  @override
  String get flowSelectCharter => '譜面制作者を選択';

  @override
  String get flowSearchCharters => '譜面制作者を検索';

  @override
  String get flowFilterByCharterName => '譜面制作者の名前で絞り込み…';

  @override
  String get flowChooseAnArtist => 'アーティストを選択';

  @override
  String get flowSelectArtist => 'アーティストを選択';

  @override
  String get flowSearchArtists => 'アーティストを検索';

  @override
  String get flowFilterByArtistName => 'アーティストの名前で絞り込み…';

  @override
  String flowP0Items2(String p0) {
    return '$p0項目';
  }

  @override
  String get flowByDifficulty => '難易度別';

  @override
  String get flowConstant => '定数';

  @override
  String get flowVersion => 'バージョン';

  @override
  String get flowGenre => 'ジャンル';

  @override
  String get flowNotes => 'ノーツ数';

  @override
  String get flowTags => 'タグ';

  @override
  String get flowCharter => '譜面制作者';

  @override
  String get flowArtist => 'アーティスト';

  @override
  String get flowSongID => '楽曲 ID';

  @override
  String get flowSongTitle => '曲名';

  @override
  String get flowArtist2 => 'アーティスト';

  @override
  String get flowAlias => '別名';

  @override
  String get flowTakeAPhotoOrChooseAnImage => '撮影または画像を選択';

  @override
  String get flowCropTheCoverArtInTheImage => '画像内のジャケット部分を切り抜く';

  @override
  String get flowRecognizeAndViewTheClosestSongs => '認識して最も近い楽曲を表示';

  @override
  String get flowTexture => '模様';

  @override
  String get flowColor => '色';

  @override
  String get flowEnterANumber => '数値を入力してください';

  @override
  String get flowCannotBeNegative => '負の数は入力できません';

  @override
  String flowMustNotExceedP0(String p0) {
    return '$p0以下で入力してください';
  }

  @override
  String flowDifficultyP0(String p0) {
    return '難易度 $p0';
  }

  @override
  String get flowLocalLibraryIsEmptyRefreshItFrom =>
      'ローカル曲庫が空です。先にホームで更新してください';

  @override
  String get flowNoSongMatchedTapEditThisResult =>
      '一致する曲がありません。「この項目を編集」で指定してください';

  @override
  String get flowDifficultyNotRecognizedUTAGESyncIsUnsupported =>
      '難易度を認識できません（宴譜面の同期は未対応です）';

  @override
  String get flowNoChartInformationForThisSongIn => '曲庫にこの曲の譜面情報がありません';

  @override
  String flowDifficultyP0DoesNotExistOnlyP1(String p0, String p1) {
    return '難易度$p0はありません（譜面は$p1個のみ）';
  }

  @override
  String get flowAchievementMissingTapEditThisResultTo =>
      '達成率がありません。「この項目を編集」で入力してください';

  @override
  String flowUpdatedOnLXNSP0(String p0) {
    return '落雪を更新しました：$p0';
  }

  @override
  String flowSyncedToLXNSUnchangedP0(String p0) {
    return '落雪に同期済み（変更なし）：$p0';
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
    return 'DX スコア $p0 → $p1';
  }

  @override
  String flowDXScoreP0(String p0) {
    return 'DX スコア $p0';
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
  String get flowPhotographOrChooseAResultScreen => 'リザルトを撮影・選択';

  @override
  String get flowPhotographStraightAndClearlyForBetterRecognition =>
      '正面から鮮明に撮ると認識精度が上がります';

  @override
  String get flowCheckResultsThenSyncToDivingFish => '結果を確認して水魚・落雪に同期';

  @override
  String get flowStandard => 'スタンダード';

  @override
  String get flowConfidence => '信頼度 —';

  @override
  String flowConfidenceP0(String p0) {
    return '信頼度 $p0%';
  }

  @override
  String get flowCoverArt => 'ジャケット';

  @override
  String get flowTitle => '曲名';

  @override
  String get flowSignInFailedTheQRMayHave =>
      'ログインできません。QR の期限切れの可能性があるため再発行してください';

  @override
  String get flowAllSongs => '全曲';

  @override
  String get flowInChina => '中国版収録済み';

  @override
  String get flowPendingRelease => '配信待ち';

  @override
  String get flowNotIncluded => '未収録';

  @override
  String get flowNextUpdateCandidates => '次回更新候補';

  @override
  String get flowOlderSongsMissingInChina => '中国版未収録の旧曲';

  @override
  String get flowUTAGE => '宴会場';

  @override
  String get flowChinaRegularSongs => '中国版通常曲';

  @override
  String get flowEarlyChinaReleases => '中国版先行曲';

  @override
  String get flowNoMissingRegularSongsInTheCurrent => '現在の参照範囲に未収録の通常曲はありません。';

  @override
  String flowSortedByIDNotReleaseOrderOfficial(String p0) {
    return 'ID 順で表示します。配信順ではありません。実際の更新は公式告知に従います。$p0';
  }

  @override
  String get flowTheseSongsPredateTheReferenceStartOr =>
      '参照開始日より古い曲、または日付がなく ID が小さい曲です。地域限定・コラボ限定・未追加の旧曲の可能性がありますが、今後配信されないとは限りません。';

  @override
  String get flowUTAGEDoesNotFollowVersionUpdatesListed =>
      '宴譜面はバージョン更新と連動しません。参考として表示しています。';

  @override
  String get flowRegularDivingFishChinaSongsNewestDebut =>
      '水魚の中国版通常曲を初登場日の新しい順に表示します。先頭がこのページの更新到達点です。';

  @override
  String get flowTheseSongsReachedChinaBeforeJapanTheir =>
      '日本版より先に中国版へ配信された曲です。新しい ID が到達点を押し上げて未収録曲を隠すため、別に表示します。';

  @override
  String flowVersionsInvolvedP0(String p0) {
    return '\n対象バージョン：$p0';
  }

  @override
  String flowP0P1Songs(String p0, String p1) {
    return '$p0：$p1曲';
  }

  @override
  String get flowChartDateSource => '譜面の日付の取得元：';

  @override
  String get flowReleaseDataSource => '配信データの取得元：';

  @override
  String get flowUpdatesOnThisDay => '当日の更新';

  @override
  String flowP0P1P2(String p0, String p1, String p2) {
    return '$p0月$p1日（$p2）';
  }

  @override
  String get flowAll => 'すべて';

  @override
  String get flowPlayed => 'プレイ済み';

  @override
  String get flowUnplayed => '未プレイ';

  @override
  String flowP0Types(String p0) {
    return '$p0種類';
  }

  @override
  String get flowThisCollectibleHasNoImage => 'このコレクションに画像はありません';

  @override
  String flowCouldNotSaveImageP0(String p0) {
    return '画像の保存失敗：$p0';
  }

  @override
  String get flowThisCollectibleHasNoImageLink => 'このコレクションに画像リンクはありません';

  @override
  String get flowLinkCopied => 'リンクをコピーしました';

  @override
  String get flowCouldNotCopyLink => 'リンクをコピーできませんでした';

  @override
  String get flowRequiredDifficulty => '必要な難易度';

  @override
  String get flowMinimumAchievement => '最低達成率';

  @override
  String get flowRequiredNoteSpeed => '必要なノーツ速度';

  @override
  String get flowRequiredCombo => '必要なコンボ';

  @override
  String get flowRequiredSync => '必要なシンク';

  @override
  String get flowJapaneseEnglish => '日本語＋英語';

  @override
  String get flowEnglish => '英語';

  @override
  String get flowJapanese => '日本語';

  @override
  String flowP0Seconds2(String p0) {
    return '$p0秒';
  }

  @override
  String flowP0Minutes(String p0) {
    return '$p0分';
  }

  @override
  String flowP0MinP1Sec(String p0, String p1) {
    return '$p0分$p1秒';
  }

  @override
  String get flowJustNow => 'たった今';

  @override
  String get flowWaitingForUpstreamQuota => '上流の割当回復待ち';

  @override
  String get flowWaitingForUpstreamService => '上流サービスの復旧待ち';

  @override
  String get flowWaitingForUpstreamGateway => '上流ゲートウェイの復旧待ち';

  @override
  String get flowWaitingForUpstreamProcessing => '上流の処理待ち';

  @override
  String flowP0RetryAroundP1(String p0, String p1) {
    return '$p0、$p1頃に再試行';
  }

  @override
  String get flowProcessingTimedOut => '処理タイムアウト';

  @override
  String get flowQuotaInsufficient => '割当不足';

  @override
  String get flowUpstreamUnavailable => '上流サービスを利用できません';

  @override
  String get flowUploadIncomplete => 'アップロード未完了';

  @override
  String get flowUploadCredentialsExpired => 'アップロード認証情報の期限切れ';

  @override
  String get flowCouldNotReadTargetScores => '対象の成績を取得できません';

  @override
  String get flowCouldNotReadLibrary => '曲庫を取得できません';

  @override
  String get flowCouldNotReadCabinetData => '筐体データを取得できません';

  @override
  String get flowNoScoresToSync => '同期できる成績がありません';

  @override
  String get flowInterruptedByServiceRestart => 'サービス再起動で中断';

  @override
  String get flowProcessingWindowEnded => '処理時間帯が終了';

  @override
  String get flowRoundDataExpired => '今回のデータは失効しました';

  @override
  String get flowTaskCancelled => 'タスクをキャンセルしました';

  @override
  String get flowPreparingQuickSync => 'クイック同期を準備中…';

  @override
  String flowElapsedP0P1(String p0, String p1) {
    return '経過 $p0$p1';
  }

  @override
  String flowLimitP0Min(String p0) {
    return ' / 上限$p0分';
  }

  @override
  String get flowWaitingForProcessingToStart => '処理開始待ち';

  @override
  String flowCabinetDataCollectedP02(String p0) {
    return '筐体データ取得 $p0';
  }

  @override
  String flowUploadingP0P1P2(String p0, String p1, String p2) {
    return 'アップロード $p0/$p1件$p2';
  }

  @override
  String flowReadingCabinetScoresPageP0(String p0) {
    return '筐体成績を取得・$p0ページ';
  }

  @override
  String flowSubmittedP02(String p0) {
    return '$p0件送信';
  }

  @override
  String flowSkippedP0UnsupportedCharts2(String p0) {
    return '未対応譜面$p0件をスキップ';
  }

  @override
  String flowUnchangedP0(String p0) {
    return '変更なし$p0件';
  }

  @override
  String flowP0TookP1(String p0, String p1) {
    return '$p0・所要時間 $p1';
  }

  @override
  String get flowAccountAndSync => 'アカウントと同期';

  @override
  String get flowAccountAndSyncHint => 'アカウント・認証・成績同期を管理';

  @override
  String get flowFishAccount => '水魚アカウント';

  @override
  String get flowReadingAccountState => 'アカウント状態を確認中';

  @override
  String get flowNotSignedIn => '未ログイン';

  @override
  String get flowSignInFishAgain => '水魚に再ログイン';

  @override
  String get flowUseFishForToken => '水魚の認証情報で ImportToken を取得';

  @override
  String get flowScoreSync => '成績同期';

  @override
  String get flowSyncSourcesHint => 'maimai の成績を外部サービスに同期';

  @override
  String get flowImportTokenNotSet => '成績取り込み Token 未設定';

  @override
  String get flowTitleCollectible => '称号';

  @override
  String get flowIconCollectible => 'アイコン';

  @override
  String get flowPlateCollectible => 'ネームプレート';

  @override
  String get flowFrameCollectible => 'フレーム';

  @override
  String get flowAwmcGateway => 'AWMC ゲートウェイ';

  @override
  String get flowNormalSource => '中国版曲庫';

  @override
  String get flowExtraSource => '海外版曲庫';

  @override
  String get flowQrPrivateNotice =>
      '成績同期と同じ SGWCMAID で始まる QR 文字列です。WeChat やカメラの認識結果からコピーできます。\n\n⚠️ 筐体のログイン認証情報です。自分のアカウントにのみ使用してください。';

  @override
  String get flowReadingExistingScoresOnTheTargetAccount => '対象アカウントの既存成績を取得中…';

  @override
  String get flowCheckingChartsSupportedByTheTarget => '対象サービスの対応譜面を確認中…';

  @override
  String flowReadingCabinetScoresP0PagesRead(String p0) {
    return '筐体の成績を取得中・$p0ページ取得済み';
  }

  @override
  String get flowReadingCabinetScores => '筐体の成績を取得中…';

  @override
  String get flowPreparingChartsComboAndSyncMarkers => '譜面・コンボ・シンク情報を整理中…';

  @override
  String flowUploadingScoresP0P1P2(String p0, String p1, String p2) {
    return '成績をアップロード中（$p0 / $p1件$p2）';
  }

  @override
  String flowP0Submitted(String p0) {
    return '、$p0件送信済み';
  }

  @override
  String get flowSyncComplete2 => '同期完了';

  @override
  String get flowWaitingForUpstreamQuota2 => '上流の割当回復待ち…';

  @override
  String get flowWaitingForUpstreamService2 => '上流サービスの復旧待ち…';

  @override
  String flowReadingExistingScoresOnP0(String p0) {
    return '$p0 の既存成績を取得中…';
  }

  @override
  String flowCheckingChartsSupportedByP0(String p0) {
    return '$p0 の対応譜面を確認中…';
  }

  @override
  String get flowComparingChangesAndPreparingUploads => '変更を比較して送信内容を準備中…';

  @override
  String flowUploadingToP0P1P2P3(String p0, String p1, String p2, String p3) {
    return '$p0 にアップロード中：$p1 / $p2件$p3';
  }

  @override
  String get flowValidatingQRCode2 => 'QR コードを確認中…';

  @override
  String get flowCreatingScoreFetchTask => '成績取得タスクを作成中…';

  @override
  String get flowBotIsSendingAFriendRequest => 'ボットがフレンド申請を送信中…';

  @override
  String get flowFriendAddedCreatingScoreFetchTask =>
      'フレンドを追加しました。成績取得タスクを作成中…';

  @override
  String get flowSyncingToDivingFish => '水魚に同期中…';

  @override
  String flowSyncCompleteP0ScoresSynced(String p0) {
    return '同期完了。$p0件の成績を同期しました';
  }

  @override
  String get flowSubmittingQRCode => 'QR コードを送信中…';

  @override
  String get flowSyncingToLXNS => '落雪に同期中…';

  @override
  String flowSyncCompleteP0ScoresSyncedToLXNS(String p0) {
    return '同期完了。落雪に$p0件の成績を同期しました';
  }

  @override
  String get flowAcceptTheFriendRequestOnNETOr => 'NET または筐体でフレンド申請を承認してください';

  @override
  String flowFetchingScoresP0P1(String p0, String p1) {
    return '成績を取得中…（$p0/$p1）';
  }

  @override
  String get flowFetchingScores => '成績を取得中…';

  @override
  String get flowFetchingFriendList => 'フレンド一覧を取得中…';

  @override
  String get flowTaskQueuedWaitingForProcessing => 'タスクがキューに入りました。処理待ち…';

  @override
  String get flowPreviewingData => 'データを確認中…';

  @override
  String get flowSigningIn3 => 'ログイン中…';

  @override
  String flowReadingChartScoresP0Records(String p0) {
    return '譜面成績を取得中…（$p0件）';
  }

  @override
  String get flowReadingChartScores => '譜面成績を取得中…';

  @override
  String get flowSigningOut => 'ログアウト中…';

  @override
  String get flowCleaningUp => '後処理中…';

  @override
  String flowSavingScoresP0Records(String p0) {
    return '成績を保存中…（$p0件）';
  }

  @override
  String get flowSavingScores => '成績を保存中…';

  @override
  String flowReadingComboAndSyncMarkersFromP0(String p0) {
    return '$p0 のコンボ・シンク情報を取得中…';
  }

  @override
  String flowCheckingChartsSupportedByP02(String p0) {
    return '$p0 の対応譜面を確認中…';
  }

  @override
  String get flowReadingCabinetScoresForThisRound => '今回の筐体成績を取得中…';

  @override
  String flowUpdatingP0ScoresP1P2(String p0, String p1, String p2) {
    return '$p0 の成績を更新中（$p1/$p2）…';
  }

  @override
  String flowQuickSyncCompleteUpdatedP0Scores(String p0) {
    return 'クイック同期完了：$p0件更新';
  }

  @override
  String flowSkippedP0UnchangedScores(String p0) {
    return '、変更のない$p0件をスキップ';
  }

  @override
  String flowP0ChartsUnmatchedOrUnsupported(String p0) {
    return '、$p0譜面は未一致または未対応';
  }

  @override
  String get flowCheckingAWMCGateway2 => 'AWMC ゲートウェイを確認中…';

  @override
  String get flowQuicklyReadingCabinetScores => '筐体成績をクイック取得中…';

  @override
  String get flowClearSignIn => '現在のログイン状態を解除';

  @override
  String flowBoundQq(String qq) {
    return '連携 QQ：$qq';
  }

  @override
  String get flowStatsNotUpdated => '未更新';

  @override
  String get flowStatsJustUpdated => '更新したばかり';

  @override
  String flowStatsSecondsAgo(String count) {
    return '$count秒前に更新';
  }

  @override
  String flowStatsMinutesAgo(String count) {
    return '$count分前に更新';
  }

  @override
  String flowStatsHoursAgo(String count) {
    return '$count時間前に更新';
  }

  @override
  String get flowCacheNeverExpires => '有効期限なし';

  @override
  String get flowCacheNoTimestamp => 'キャッシュの日時なし';

  @override
  String get flowCacheAbsent => 'キャッシュなし';

  @override
  String get flowCacheExpiredPrefix => '期限切れ';

  @override
  String flowCacheExpired(String duration) {
    return '$duration前に期限切れ';
  }

  @override
  String flowCacheRemaining(String duration) {
    return '残り$duration';
  }

  @override
  String flowCacheDaysHours(String days, String hours) {
    return '$days日$hours時間';
  }

  @override
  String flowCacheDays(String days) {
    return '$days日';
  }

  @override
  String flowCacheHoursMinutes(String hours, String minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String flowCacheHours(String hours) {
    return '$hours時間';
  }

  @override
  String flowCacheMinutes(String minutes) {
    return '$minutes分';
  }

  @override
  String get flowRankingShowIdentity => 'ニックネームとアイコンを公開';

  @override
  String get flowRankingIdentityHint =>
      '無効時は匿名名と初期アイコンを表示します。選択したアイコンは保存・同期します。';

  @override
  String get flowRankingShowBrief => 'ランキングの簡易プロフィールを公開';

  @override
  String get flowRankingBriefHint =>
      '称号・装飾・レベル・ベスト成績を公開します。ログインか本人確認が必要です。初期設定は無効です。';

  @override
  String get flowCacheFishSongs => '楽曲（水魚）';

  @override
  String get flowCacheUnionSongs => '楽曲（Union）';

  @override
  String get flowCacheDifficulties => '譜面定数';

  @override
  String get flowCacheTags => 'タグ';

  @override
  String get flowCacheAlias1 => '別名：取得元1';

  @override
  String get flowCacheAlias2 => '別名：取得元2';

  @override
  String get flowCacheAlias3 => '別名：取得元3';

  @override
  String get flowCacheTitles => 'コレクション：称号';

  @override
  String get flowCacheIcons => 'コレクション：アイコン';

  @override
  String get flowCachePlates => 'コレクション：ネームプレート';

  @override
  String get flowCacheFrames => 'コレクション：フレーム';

  @override
  String get flowCacheUnionMetadata => 'Union メタデータ';

  @override
  String get flowCacheFishDescription => '全楽曲データ（水魚）';

  @override
  String get flowCacheUnionDescription => '追加の独自楽曲（godserver）';

  @override
  String get flowCacheConstantDescription => '譜面定数（水魚 chart_stats）';

  @override
  String get flowCacheTagDescription => 'DXRating 譜面タグ';

  @override
  String get flowCacheTitleDescription => '落雪の称号';

  @override
  String get flowCacheIconDescription => '落雪のアイコン';

  @override
  String get flowCachePlateDescription => '落雪のネームプレート';

  @override
  String get flowCacheFrameDescription => '落雪のフレーム';

  @override
  String get flowCacheMetadataDescription => 'プレイ可能地域（cn/jp）など';

  @override
  String get flowCacheMaidataDescription => '譜面追加情報（一覧＋全 maidata）';

  @override
  String get flowSongDetails => '楽曲詳細';

  @override
  String get flowExpandOrCollapseSongInformation => '楽曲情報を開閉';

  @override
  String get flowFavorited => 'お気に入り登録済み';

  @override
  String get flowAddToAFavoritesFolder => 'お気に入りフォルダに追加';

  @override
  String flowCreatedP0AndAddedThisChart(String p0) {
    return '「$p0」を作成し、この譜面を追加しました';
  }

  @override
  String get flowNoFavoritesFoldersYet => 'お気に入りフォルダがありません';

  @override
  String get flowCreateAFavoritesFolderFirst => '先にお気に入りフォルダを作成してください';

  @override
  String flowP0Charts(String p0) {
    return '$p0譜面';
  }

  @override
  String get flowNewFavoritesFolder => 'お気に入りフォルダを作成';

  @override
  String get flowEnterAFolderName => 'フォルダ名を入力してください';

  @override
  String get flowCreate => '作成';

  @override
  String get flowPause => '一時停止';

  @override
  String get flowPlay => '再生';

  @override
  String flowP0P1SBufferedAhead(String p0, String p1) {
    return '$p0：$p1秒先までバッファ済み';
  }

  @override
  String get flowCouldNotLoadThePVCheckYour =>
      'PVを読み込めませんでした。接続を確認して再試行してください。';

  @override
  String get flowBackToSongDetails => '楽曲詳細に戻る';

  @override
  String get flowCopiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get flowExportZIPZip => 'ZIPで書き出す (.zip)';

  @override
  String get flowMaidataTxtCoverArtAndAudioIn =>
      'maidata.txt・ジャケット・音源を含む汎用譜面パッケージ';

  @override
  String get flowExportAstroDXChartAdx => 'AstroDX譜面を書き出す (.adx)';

  @override
  String get flowOpenInAstroDXToInstallTheChart => 'AstroDXで開くと譜面をインストールできます';

  @override
  String get flowChooseWhereToSaveTheChartPackage => '譜面パッケージの保存先を選択';

  @override
  String get flowChooseWhereToSaveTheAstroDXChart => 'AstroDX譜面の保存先を選択';

  @override
  String flowExportFailedP0(String p0) {
    return '書き出しに失敗しました：$p0';
  }

  @override
  String get flowSelectDifficulty => '難易度を選択';

  @override
  String get flowRenderedChartsAreForReferenceAndMay =>
      '表示される譜面は参考用で、公式譜面とは異なる場合があります。高密度の譜面では、アプリの停止や終了を防ぐため、再生位置を頻繁に変更しないでください。';

  @override
  String get flowLoadAudio => '音源を読み込む';

  @override
  String get flowTurnOffToLoadTheChartWithout => 'オフにすると音源をダウンロードせずに譜面を読み込みます';

  @override
  String get flowFetchingChartConstants => '譜面定数を取得中…';

  @override
  String flowSongIDP0(String p0) {
    return '楽曲ID $p0';
  }

  @override
  String get flowChartCode => '譜面コード';

  @override
  String get flowCopy => 'コピー';

  @override
  String get flowExporting => '書き出し中';

  @override
  String get flowExport => '書き出す';

  @override
  String get flowRender => '表示';

  @override
  String flowVideoGeneratedTapSaveToPhotosOn(String p0, String p1, String p2) {
    return '動画を生成しました。書き出しページの「写真に保存」を押してください：$p0×$p1・$p2 MB';
  }

  @override
  String flowLoadedMaidataWithP0Difficulties(String p0) {
    return 'maidataを読み込み、$p0個の難易度を解析しました';
  }

  @override
  String get flowUnsupportedEncodingUseUTF8OrShift =>
      '文字コードに対応していません。UTF-8またはShift-JISを使用してください。';

  @override
  String flowCouldNotOpenTheFilePickerP0(String p0) {
    return 'ファイル選択を開けませんでした：$p0';
  }

  @override
  String get flowCoverArtSelected => 'ジャケットを選択しました';

  @override
  String get flowCoverArtSelectedUsingItsOriginalPath => '元のパスでジャケットを選択しました';

  @override
  String flowCouldNotOpenTheImagePickerP0(String p0) {
    return '画像選択を開けませんでした：$p0';
  }

  @override
  String get flowAudioSelected => '音源を選択しました';

  @override
  String get flowAudioSelectedUsingItsOriginalPath => '元のパスで音源を選択しました';

  @override
  String flowCouldNotOpenTheAudioPickerP0(String p0) {
    return '音源選択を開けませんでした：$p0';
  }

  @override
  String flowTheFileForP0IsMissingAnd(String p0) {
    return '「$p0」のファイルが見つからないため、一覧から削除しました';
  }

  @override
  String flowCouldNotParseAgainP0(String p0) {
    return '再解析に失敗しました：$p0';
  }

  @override
  String get flowDeleteThisRecord => 'この記録を削除';

  @override
  String flowRemoveP0FromRecentlyParsedChartsAnd(String p0) {
    return '「$p0」を最近の解析から削除し、保存したファイルも削除しますか？';
  }

  @override
  String get flowDelete => '削除';

  @override
  String get flowCouldNotReadThisFileTryAnother =>
      'ファイルを読み込めませんでした。別の取得元をお試しください。';

  @override
  String flowImportFailedP0(String p0) {
    return '読み込みに失敗しました：$p0';
  }

  @override
  String get flowNoMaidataTxtFoundThisIsNot =>
      'maidata.txtが見つかりません。有効な譜面パッケージではありません。';

  @override
  String get flowUnsupportedMaidataTxtEncodingUseAUTF =>
      'maidata.txtの文字コードに対応していません。UTF-8またはShift-JISの譜面パッケージを使用してください。';

  @override
  String flowImportedAllThreeFilesFromP0Found(String p0, String p1) {
    return '$p0から3ファイルを読み込み、$p1個の難易度を解析しました';
  }

  @override
  String flowImportedMaidataP0DifficultiesNoP1In(String p0, String p1) {
    return 'maidata（$p0難易度）を読み込みました。パッケージ内に$p1がないため、必要に応じて手動で選択してください。';
  }

  @override
  String get flowRecentlyParsed => '最近の解析';

  @override
  String get flowTapToParseTheArchivedFilesAgain => 'タップで保存ファイルを再解析、長押しで削除';

  @override
  String get flowSelectAMaidataFileFirst => '先にmaidataファイルを選択してください';

  @override
  String get flowNoValidDifficultiesFound => '有効な難易度がありません';

  @override
  String get flowTurnOffToLoadTheChartWithout2 => 'オフにすると音源なしで譜面を読み込みます';

  @override
  String get flowSelectionCleared => '選択を解除しました';

  @override
  String get flowCustomChart => 'カスタム譜面';

  @override
  String get flowImportAChartPackage => '譜面パッケージを読み込む';

  @override
  String get flowSelectAnAdxOrZipPackageTo =>
      '.adxまたは.zipを選択すると、maidata.txt・ジャケット・音源を展開します';

  @override
  String get flowExtracting => '展開中…';

  @override
  String get flowSelectChartPackage => '譜面パッケージを選択';

  @override
  String get flowOrSelectTheThreeFilesSeparately => 'または3ファイルを個別に選択';

  @override
  String get flowSelectMaidataTxt => 'maidata.txtを選択';

  @override
  String get flowRequiredATextFileContainingChartData => '必須：譜面データを含むtxtファイル';

  @override
  String get flowSelectCoverArt => 'ジャケットを選択';

  @override
  String get flowOptionalChartBackgroundImagePNGJPG => '任意：譜面の背景画像（png/jpg）';

  @override
  String get flowSelectAudio => '音源を選択';

  @override
  String get flowOptionalChartMusicMP3WAVOGG => '任意：譜面の音源（mp3/wav/ogg）';

  @override
  String get flowParsedDifficulties => '解析した難易度：';

  @override
  String get flowStartPlayback => '再生開始';

  @override
  String get flowInstructions => '使い方：';

  @override
  String get flowOption1SelectAnAdxOrZip =>
      '方法1：「譜面パッケージを選択」で.adxや.zipを選び、3ファイルをまとめて読み込みます';

  @override
  String get flowOption2TapARecentlyParsedEntry =>
      '方法2：「最近の解析」の記録から、以前使用したパッケージを再解析します';

  @override
  String get flowOption3SelectMaidataTxtCoverArt =>
      '方法3：maidata.txt・ジャケット・音源を個別に選択します';

  @override
  String get flow1MaidataTxtIsRequiredTheOther =>
      '1. maidata.txtは必須です。他の2ファイルは省略できます';

  @override
  String get flow2DifficultiesAreDetectedAutomatically => '2. 譜面の難易度は自動で解析されます';

  @override
  String get flow3SelectADifficultyThenStartPlayback => '3. 表示したい難易度を選択して再生します';

  @override
  String flowSelectedP0(String p0) {
    return '選択済み：$p0';
  }

  @override
  String get flowChooseAgain2 => '選び直す';

  @override
  String get flowChooseFile => 'ファイルを選択';

  @override
  String get flowChooseWhereToSaveTheSong => '楽曲の保存先を選択';

  @override
  String get flowDownloaded => 'ダウンロードしました';

  @override
  String get flowGoToCurrentSong => '再生中の楽曲へ移動';

  @override
  String get flowRebuildLibrary => 'ライブラリを再構築';

  @override
  String get flowMusicPlayerSettings => '音楽プレイヤー設定';

  @override
  String get flowShowFloatingPlayerAfterLeavingThisPage =>
      'ページを離れたときにフローティングプレイヤーを表示';

  @override
  String get flowWhenOffLeavingTheMusicPlayerWill =>
      'オフにすると、音楽プレイヤーを離れてもフローティングプレイヤーを表示しません';

  @override
  String get flowSearchTitleArtistGenreAliasBPMID =>
      '曲名・アーティスト・ジャンル・別名・BPM・IDで検索';

  @override
  String get flowNowPlaying => '再生中';

  @override
  String get flowPaused => '一時停止中';

  @override
  String get flowUnknownArtist => '不明なアーティスト';

  @override
  String get flowDownloadSong => '楽曲をダウンロード';

  @override
  String get flowAddToPlayNext => '次に遊びたい曲に追加';

  @override
  String get flowAddedToPlayNext => '次に遊びたい曲に追加しました';

  @override
  String get flowPlayMusic => '音楽を再生';

  @override
  String get flowNothingPlayingYet => '再生中の音楽がありません';

  @override
  String get flowPreparingAudio => '音源を準備中…';

  @override
  String get flowPrevious2 => '前の曲';

  @override
  String get flowNext2 => '次の曲';

  @override
  String get flowChooseSortOrder => '並び順を選択';

  @override
  String get flowDXScoreRate => 'でらっくスコア率';

  @override
  String get flowAchievementFilter => '達成率で絞り込み';

  @override
  String get flowComboSyncFilter => 'コンボ・シンクで絞り込み';

  @override
  String get flowAnyOptionWithinAGroupMatchesWhen =>
      '同じグループ内はどれかに一致すれば対象になります。コンボとシンクの両方を選ぶと、両条件を満たす必要があります。';

  @override
  String get flowCloseSearch => '検索を閉じる';

  @override
  String get flowSearchSongTitleOrConstant => '曲名や定数で検索';

  @override
  String get flowNoCachedDataFound => 'キャッシュデータがありません';

  @override
  String get flowTapASegmentOrStatisticToFilter => '色や集計項目をタップで絞り込み・計';

  @override
  String get flowEntries => '件';

  @override
  String flowFilteredByP0TapAgainToClear(String p0) {
    return '$p0で絞り込み中・再タップで解除';
  }

  @override
  String flowP0P1EntriesTapToFilter(String p0, String p1) {
    return '$p0 $p1件、タップして絞り込み';
  }

  @override
  String get flowComboSync => 'コンボ・シンク';

  @override
  String get flowPerPage => '1ページの件数';

  @override
  String flowP0Entries(String p0) {
    return '計$p0件';
  }

  @override
  String get flowList => '一覧';

  @override
  String get flowUnknownSong => '不明な楽曲';

  @override
  String get flowSelectMultipleAnySelectedOptionMatches =>
      '複数選択可。いずれかに一致すれば対象です';

  @override
  String flowClearP0(String p0) {
    return '$p0を解除';
  }

  @override
  String get flowQuickOptions => 'クイック選択';

  @override
  String get flowCustomRange => '範囲を指定';

  @override
  String get flowExportAsImage => '画像で書き出す';

  @override
  String get flowSelectCategory => '種類を選択';

  @override
  String get flowLevel => 'レベル';

  @override
  String get flowNoChartDesignerDataFound => '譜面制作者のデータがありません';

  @override
  String get flowSelectVersion => 'バージョンを選択';

  @override
  String get flowNoComposerDataFound => 'アーティストのデータがありません';

  @override
  String get flowNoGenreDataFound => 'ジャンルのデータがありません';

  @override
  String get flowSelectGenre => 'ジャンルを選択';

  @override
  String flowP0P1Songs2(String p0, String p1) {
    return '$p0（$p1曲）';
  }

  @override
  String get flowSelectLevel => 'レベルを選択';

  @override
  String get flowNoCompletedSongsYet => '達成済みの楽曲がありません';

  @override
  String get flowNoIncompleteSongs => '未達成の楽曲がありません';

  @override
  String get flowStoragePermissionIsRequiredToExportImages =>
      '写真への書き出しにはストレージ権限が必要です。設定で許可してください。';

  @override
  String get flowPersonalizedScores => '条件別成績';

  @override
  String flowExportFailedP02(String p0) {
    return '書き出しに失敗しました：$p0';
  }

  @override
  String get flowCouldNotOpenTheAuthorizationPageLink =>
      '認証ページを開けませんでした。リンクをコピーしました。';

  @override
  String get flowFetchingFriendDataAndComparing => 'フレンドのデータを取得・比較中…';

  @override
  String flowCompareMyP0ScoresWithMyFriend(String p0) {
    return '自分の$p0の成績と、この取得元のフレンドの成績を比較';
  }

  @override
  String flowEnterYourFriendSP0(String p0) {
    return 'フレンドの$p0を入力';
  }

  @override
  String get flowCompare => '比較する';

  @override
  String get flowCompareWithAFriend => 'フレンドと比較';

  @override
  String flowEnterYourFriendSP0ToCompare(String p0, String p1) {
    return 'フレンドの$p0を入力して比較します\nフレンドは$p1にデータが必要です';
  }

  @override
  String get flowClearHistory => '履歴を消去';

  @override
  String get flowClearAllHistory => '履歴をすべて消去しますか？';

  @override
  String get flowPastComparisons => '比較履歴';

  @override
  String flowP0P1P2SongsInCommon(String p0, String p1, String p2) {
    return '$p0・$p1・共通$p2曲';
  }

  @override
  String get flowPrivate => '非公開';

  @override
  String get flowSameScore => '同点';

  @override
  String get flowMyCharts => '自分の譜面';

  @override
  String get flowFriendSCharts => 'フレンドの譜面';

  @override
  String get flowSharedCharts => '共通の譜面';

  @override
  String get flowAllDifficulties => 'すべての難易度';

  @override
  String flowConstantHighToLowShowingP0P1(String p0, String p1) {
    return '定数の高い順・表示$p0 / $p1';
  }

  @override
  String get flowNoMatchingCharts => '条件に合う譜面がありません';

  @override
  String flowLoadMoreP0P1(String p0, String p1) {
    return 'さらに読み込む（$p0 / $p1）';
  }

  @override
  String get flowTie => '引き分け';

  @override
  String get flowSelectFirstCharacter => '頭文字を選択';

  @override
  String flowP0SongsExcludedFromPlateProgress(String p0) {
    return '$p0曲、プレート進捗には含みません';
  }

  @override
  String flowP0P1P2Statistics(String p0, String p1, String p2) {
    return '$p0$p1（$p2）集計';
  }

  @override
  String get flowRecommendationSettings => 'おすすめ条件';

  @override
  String flowConstantsP0P1P2Results(String p0, String p1, String p2) {
    return '定数$p0～$p1・$p2件';
  }

  @override
  String get flowTargetRating => '目標Rating';

  @override
  String get flowRecommend => 'おすすめ';

  @override
  String get flowLoadingRecommendations => 'おすすめを読み込み中…';

  @override
  String get flowNoRecommendationsCheckTheRatingYouEntered =>
      'おすすめがありません。入力したRatingを確認してください。';

  @override
  String flowCouldNotSaveHistoryP0(String p0) {
    return '履歴を保存できませんでした：$p0';
  }

  @override
  String flowCouldNotDeleteDataPointP0(String p0) {
    return '記録点を削除できませんでした：$p0';
  }

  @override
  String get flowLinkYourQQThroughSyncScoresTo =>
      '先に「AWMC NETに成績を同期」からQQを連携してください';

  @override
  String flowNoRatingRecordsForQQP0On(String p0) {
    return 'AWMC NETにQQ $p0の直近90日間のRating記録がありません';
  }

  @override
  String flowSyncedRatingHistoryFromAWMCNETAdded(String p0) {
    return 'AWMC NETからRating履歴を同期し、$p0件追加しました';
  }

  @override
  String flowNoNewAWMCNETPointsP0Already(String p0) {
    return 'AWMC NETに新しい記録点はありません（$p0件は記録済み）';
  }

  @override
  String get flowSyncRatingHistoryFromAWMCNET => 'AWMC NETからRating履歴を同期';

  @override
  String get flowAddHistoryRecord => '履歴を追加';

  @override
  String flowCurrentSourceP0(String p0) {
    return '現在の取得元：$p0';
  }

  @override
  String flowBaselinesForP0ChartsP1ScoreChanges(String p0, String p1) {
    return '$p0譜面の基準成績・$p1回の成績変化を記録（楽曲詳細の達成率・でらっくスコアの推移に使用）';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs(String p0) {
    return '水魚・落雪・AWMC NETの履歴はアカウントごとに記録します。$p0（AWMC NETでは右上のクラウド同期から過去の推移を取得できます）';
  }

  @override
  String flowDivingFishLXNSAWMCNETHistoryIs2(String p0) {
    return '水魚・落雪・AWMC NETの履歴はアカウントごとに記録します。$p0（水魚と落雪には過去成績のAPIがないため、記録開始後の履歴のみです）';
  }

  @override
  String get flowHighest => '最高';

  @override
  String get flowDataPoints => '記録点';

  @override
  String flowP0EntriesShowingTheLatest30(String p0) {
    return '計$p0件、最新30件を表示';
  }

  @override
  String get flowNoHistoryYet => '履歴がありません';

  @override
  String get flowEachDataRefreshRecordsAPointAutomatically =>
      '「成績取得とデータ更新」のたびに自動で記録します。\n時刻は秒単位です。同じ秒の更新は上書きし、異なる時刻の変化は別々に保存します。';

  @override
  String get flowAddRatingHistory => 'Rating履歴を追加';

  @override
  String get flowCurrentTheoreticalRating => '現在の理論Rating';

  @override
  String get flowBest35Optional => 'Best35（任意）';

  @override
  String get flowCurrentTheoreticalB35 => '現在の理論B35';

  @override
  String get flowBest15Optional => 'Best15（任意）';

  @override
  String get flowCurrentTheoreticalB15 => '現在の理論B15';

  @override
  String get flowAboutScoreImprovementHistory => '成績向上履歴について';

  @override
  String get flowLocalScoreHistoryForThisAccount => 'このアカウントのローカル成績履歴';

  @override
  String get flowRecordingStartsAfterADataRefreshThe =>
      'データ更新後から記録します。過去の成績がない初回は基準のみ作成します。';

  @override
  String flowRecordedSinceP0SameDayChangesTo(String p0) {
    return '$p0から記録・同じ日の同一譜面は統合';
  }

  @override
  String get flowCharts => '譜面';

  @override
  String get flowImprovement => '向上';

  @override
  String get flowChanges => '変化回数';

  @override
  String get flowRecordingRules => '記録ルール';

  @override
  String flowLoadMoreFromThisDayP0Charts(String p0) {
    return 'この日の記録をさらに読み込む（残り$p0譜面）';
  }

  @override
  String get flowNoRatingsYet => '評価履歴がありません';

  @override
  String get flowNoCommentsYet => 'コメントがありません';

  @override
  String get flowNoBest50DataYet => 'Best50のデータがありません';

  @override
  String get flowReturnHomeAndTapRefreshData => 'ホームに戻り「成績取得とデータ更新」を押してください';

  @override
  String get flowTheoreticalRatingBest50 => '理論Rating Best50';

  @override
  String get flowSaveCurrentRecord => '現在の記録を保存';

  @override
  String get flowHistory => '履歴';

  @override
  String get flowAccountDataChangedReopenBest50BeforeSaving =>
      'アカウントのデータが更新されました。Best50を開き直してから保存してください。';

  @override
  String flowBest50RecordSavedP0(String p0) {
    return 'Best50の記録を保存しました（$p0）';
  }

  @override
  String get flowBest50History => 'Best50履歴';

  @override
  String get flowNoSavedRecordsTapSaveCurrentRecord =>
      '保存した記録がありません。「現在の記録を保存」から保存できます。';

  @override
  String flowTheoreticalRatingAverageP0(String p0) {
    return '理論Rating（平均$p0）';
  }

  @override
  String flowCurrentRatingAverageP0(String p0) {
    return '現在のRating（平均$p0）';
  }

  @override
  String get flowTheoretical => '理論値';

  @override
  String get flowAverageAchievementDXScoreRate => '平均達成率・でらっくスコア率';

  @override
  String get flowTagStatistics => 'タグ集計';

  @override
  String get flowTheoreticalBest50 => '理論Best50';

  @override
  String get flowCalculatingFittedBest50 => '推定Best50を計算中…';

  @override
  String get flowNoFittedBest50DataYet => '推定Best50のデータがありません';

  @override
  String flowFittedTotalRatingDifferenceFromBest50Average(String p0) {
    return '推定合計Rating・Best50との差（平均$p0）';
  }

  @override
  String flowModeP0(String p0) {
    return 'モード$p0';
  }

  @override
  String get flowNoDataToExport => '書き出すデータがありません';

  @override
  String flowCategoryChartDesigner50P0(String p0) {
    return '種類：譜面制作者50 - $p0';
  }

  @override
  String flowCategoryVersion50P0(String p0) {
    return '種類：バージョン50 - $p0';
  }

  @override
  String flowCategoryGenre50P0(String p0) {
    return '種類：ジャンル50 - $p0';
  }

  @override
  String flowCategoryStar50P0(String p0) {
    return '種類：スター50 - $p0';
  }

  @override
  String flowCategoryTag50P0(String p0) {
    return '種類：タグ50 - $p0';
  }

  @override
  String get flowCategoryRandom50 => '種類：ランダム50';

  @override
  String get flowCategoryOverreach50 => '種類：背伸び50';

  @override
  String flowCategoryDifficulty50P0(String p0) {
    return '種類：難易度50 - $p0';
  }

  @override
  String flowCategoryBestP0(String p0) {
    return '種類：Best $p0';
  }

  @override
  String flowCategoryP0(String p0) {
    return '種類：$p0';
  }

  @override
  String get flowChooseCategory => '種類を選択';

  @override
  String get flowNoVersionDataFound => 'バージョンのデータがありません';

  @override
  String get flowSelectStars => 'スター数を選択';

  @override
  String get flowGenerateBestN => 'Best Nを生成';

  @override
  String get flowEnterAnIntegerOf1OrMore => '1以上の整数を入力してください';

  @override
  String get flowNoTagDataFound => 'タグのデータがありません';

  @override
  String get flowSelectTag => 'タグを選択';

  @override
  String get flowNoMatchingChartDesigners => '条件に合う譜面制作者がいません';

  @override
  String flowP0P1Charts(String p0, String p1) {
    return '$p0（$p1譜面）';
  }

  @override
  String get flowTotalCharts => '総譜面数';

  @override
  String get flowAverageRA => '平均RA';

  @override
  String get flowInclusionMode => '包含関係モード';

  @override
  String get flowDrawAgain => 'もう一度抽選';

  @override
  String flowNoChartDesigner50DataForP0(String p0) {
    return '譜面制作者50 - $p0のデータがありません';
  }

  @override
  String flowNoVersion50DataForP0(String p0) {
    return 'バージョン50 - $p0のデータがありません';
  }

  @override
  String flowNoGenre50DataForP0(String p0) {
    return 'ジャンル50 - $p0のデータがありません';
  }

  @override
  String flowNoStar50DataForP0(String p0) {
    return 'スター50 - $p0のデータがありません';
  }

  @override
  String flowNoP0DataYet(String p0) {
    return '$p0のデータがありません';
  }

  @override
  String get flowRefreshArcadePlayCountsFromMeBefore =>
      'PC50を見る前に「マイページ」で「筐体プレイ回数を更新」を実行してください';

  @override
  String flowSelectTagP0(String p0) {
    return 'タグを選択：$p0';
  }

  @override
  String get flowCalculatingPersonalizedFittedBest50 => '条件別推定Best50を計算中…';

  @override
  String get flowSelectATagFirst => '先にタグを選択してください';

  @override
  String get flowSelectATagToShowYourTop =>
      'タグを選ぶと、そのタグを含むプレイ済み譜面を推定定数のRA順で上位50件表示します';

  @override
  String flowNoFittedBest50DataForTagP0(String p0) {
    return 'タグ「$p0」の推定Best50データがありません';
  }

  @override
  String get flowNoMatchingPlayRecordsMayExistTry =>
      '対象のプレイ記録がない可能性があります。\n別のタグをお試しください。';

  @override
  String get flowChangeTag => 'タグを変更';

  @override
  String flowFittedTotalRatingDifferenceFromThisTag(String p0) {
    return '推定合計Rating・このタグのBest50との差（平均$p0）';
  }

  @override
  String get flowNoCachedPlayData => 'プレイデータのキャッシュがありません';

  @override
  String get flowIdealRatingRaiseNonSSSScoresTo =>
      '理想Rating・SSS+未満の成績を次のランクの下限まで引き上げ';

  @override
  String get flowOriginalRating => '元のRating';

  @override
  String get flowNewEntries => '新規ランクイン';

  @override
  String flowNewEntriesThisTimeP0Songs(String p0) {
    return '今回の新規ランクイン（$p0曲）';
  }

  @override
  String get flowNoNewEntriesTheSameChartsRemain => '新規ランクインなし（ランク上昇後も対象譜面は同じ）';

  @override
  String flowConstantP0RAP1P2(String p0, String p1, String p2) {
    return '定数$p0・RA $p1 → $p2';
  }

  @override
  String get flowNoData2 => 'データなし';

  @override
  String flowSlotP0(String p0) {
    return '枠$p0';
  }

  @override
  String get flowNotSelected => '未選択';

  @override
  String flowP0P1ConstantP2(String p0, String p1, String p2) {
    return '$p0・$p1・定数$p2';
  }

  @override
  String get flowSelectASongFirst => '先に楽曲を選択してください';

  @override
  String flowInvalidAchievementExceedsP0(String p0) {
    return '無効なデータ：達成率が$p0%を超えています';
  }

  @override
  String flowInvalidDXScoreExceedsTheChartMaximum(String p0) {
    return '無効なデータ：でらっくスコアが譜面上限$p0を超えています';
  }

  @override
  String get flowClearThisCard => 'このカードを消去';

  @override
  String get flowNoCardsFilledInYet => '入力済みのカードがありません';

  @override
  String flowByP0(String p0) {
    return '$p0順';
  }

  @override
  String get flowClearAll => 'すべて消去';

  @override
  String get flowClearAll50SlotsThisCannotBe => '50枠すべてを消去しますか？この操作は取り消せません。';

  @override
  String get flowCustomBest50TotalRA => 'カスタムBest50の合計RA';

  @override
  String flowCurrentOrderP0ClearedWhenCardsChange(String p0) {
    return '現在の並び順：$p0（カードの変更で解除）';
  }

  @override
  String get flowAutoSort => '自動並べ替え';

  @override
  String get flowTapToFillIn => 'タップして入力';

  @override
  String flowP0Passed(String p0) {
    return '/ $p0合格済み';
  }

  @override
  String flowRedPassP0(String p0) {
    return '赤合格$p0';
  }

  @override
  String flowFailedP0(String p0) {
    return '不合格$p0';
  }

  @override
  String get flowDanCourseSongs => '段位の楽曲';

  @override
  String get flowDanCertification => '段位認定';

  @override
  String get flowMyChallenges => '自分の挑戦';

  @override
  String get flowEstimatedResult => '予測結果';

  @override
  String get flowFailed2 => '不合格';

  @override
  String get flowPassed => '合格';

  @override
  String get flowTotalAchievement => '合計達成率';

  @override
  String get flowRemainingLife => '残りライフ';

  @override
  String flowSongP02(String p0) {
    return '楽曲$p0';
  }

  @override
  String get flowEstimatedMinimumLifeLoss => '予測最小ライフ減少';

  @override
  String get flowLifeSettings => 'ライフ設定';

  @override
  String get flowStartingLife => '初期ライフ';

  @override
  String get flowClearRecovery => 'クリア時の回復';

  @override
  String get flowNoDanDataFound => '段位データがありません';

  @override
  String get flowYouAreOutsideTheTop100 => '上位100名に入っていません';

  @override
  String flowP0Entries2(String p0) {
    return '$p0件';
  }

  @override
  String get flowNoRankingDataYet => 'ランキングデータがありません';

  @override
  String get flowRefresh => '更新';

  @override
  String get flowGoToMyRank => '自分の順位へ移動';

  @override
  String flowDifferenceFromBest50P0P1(String p0, String p1) {
    return 'Best50との差$p0$p1';
  }

  @override
  String flowModeP02(String p0) {
    return 'モード$p0';
  }

  @override
  String get flowDisclaimer => '免責事項';

  @override
  String get flowThisLeaderboardIsForReferenceAndEntertainment =>
      'このランキングは参考・娯楽用で、公式または権威ある順位を示すものではありません。プレイヤーが任意で公開したデータに基づくため、誤差や遅延が生じる場合があります。順位を過度に気にせず、ゲームをお楽しみください。';

  @override
  String get flowDoNotShowAgain => '今後表示しない';

  @override
  String flowDXScoreDisplayP0TapToSwitch(String p0) {
    return 'でらっくスコア表示：$p0（タップで切替）';
  }

  @override
  String get flowDXScoreRanking => 'でらっくスコアランキング';

  @override
  String get flowAchievementRanking => '達成率ランキング';

  @override
  String get flowNoOneIsRankedYetBeThe => 'まだ誰もランクインしていません。最初の一人になりましょう！';

  @override
  String get flowYourPlayDataForThisChartAppears =>
      'この譜面のプレイデータに異常があります。確認してください。';

  @override
  String get flowChooseRankingType => 'ランキングの種類を選択';

  @override
  String get flowReverse => '逆順';

  @override
  String get flowForward => '正順';

  @override
  String get flowShowingPreviouslySavedDataRefreshWhenConnected =>
      '前回保存したデータを表示しています。接続後に更新できます。';

  @override
  String get flowNoLeaderboardDataYetTryRefreshingLater =>
      'ランキングデータがありません。しばらくしてから更新してください。';

  @override
  String get flowBilibiliChartVideoViews => 'Bilibili譜面確認動画の再生数';

  @override
  String flowDifficultyP02(String p0) {
    return '難易度：$p0';
  }

  @override
  String flowCurrentViewsP0(String p0) {
    return '現在の再生数：$p0';
  }

  @override
  String flowBVIDP0(String p0) {
    return 'BV番号：$p0';
  }

  @override
  String flowSourceP0(String p0) {
    return '取得元：$p0';
  }

  @override
  String get flowLoadingViews => '再生数を読み込み中…';

  @override
  String get flowNoViewDataYet => '再生数のデータがありません';

  @override
  String get flowEnterBVIDManually => 'BV番号を手動入力';

  @override
  String get flowIfViewsCannotBeFetchedAutomaticallyEnter =>
      '再生数を自動取得できない場合は、この楽曲の譜面確認動画のBV番号を入力できます。';

  @override
  String get flowExampleBV1xx411c7mD => '例：BV1xx411c7mD';

  @override
  String flowViewsP0(String p0) {
    return '再生数：$p0';
  }

  @override
  String flowP010000(String p0) {
    return '$p0万';
  }

  @override
  String get flowCheckBVID => 'BV番号を確認';

  @override
  String get flowBVIDUploaded => 'BV番号を送信しました';

  @override
  String get flowConfirmUpload => '送信を確定';

  @override
  String get flowChartScoreCard => '譜面成績カード';

  @override
  String get flowScoreShareCard => '成績共有カード';

  @override
  String get flowSongInformation => '楽曲情報';

  @override
  String get flowSongInformationImage => '楽曲情報の画像';

  @override
  String get flowStoragePermissionIsRequiredToSaveImages =>
      '画像の保存にはストレージ権限が必要です';

  @override
  String get flowCouldNotLoadCoverArt => 'ジャケットを読み込めませんでした';

  @override
  String get flowCoverArtSavedToPhotos => 'ジャケットを写真に保存しました';

  @override
  String flowSaveFailedP02(String p0) {
    return '保存に失敗しました：$p0';
  }

  @override
  String get flowPlayPV => 'PVを再生';

  @override
  String get flowChooseHowToPlayThePV => 'PVの再生方法を選択';

  @override
  String get flowOpenBilibili => 'Bilibiliを開く';

  @override
  String get flowPlayInApp => 'アプリ内で再生';

  @override
  String get flowPleaseWait => 'お待ちください';

  @override
  String get flowLoadingRelatedCollectibles => '関連コレクションを読み込み中…';

  @override
  String get flowError => 'エラー';

  @override
  String get flowCouldNotLoadRelatedCollectiblesTryAgain =>
      '関連コレクションを取得できませんでした。後でもう一度お試しください。';

  @override
  String get flowChartNotes => '譜面メモ';

  @override
  String get flowAddChartNotes => '譜面メモを追加';

  @override
  String get flowWriteYourNotesForThisChartHere =>
      'この譜面のメモを入力…\n例：最後のスライドの運指に注意';

  @override
  String flowCreatedP0P1(String p0, String p1) {
    return '作成：$p0$p1';
  }

  @override
  String flowUpdatedP0(String p0) {
    return '\n更新：$p0';
  }

  @override
  String get flowConfirmDeletion => '削除の確認';

  @override
  String get flowDeleteTheNotesForThisChartThis =>
      'この譜面のメモを削除しますか？この操作は取り消せません。';

  @override
  String get flowRelatedCollectibles => '関連コレクション';

  @override
  String get flowNoCollectiblesLinkedToThisSong => 'この楽曲に関連するコレクションがありません';

  @override
  String get flowRefreshDataOnTheHomePageTo => '先にホームでデータを更新し、ユーザー情報を取得してください';

  @override
  String get flowRatingSubmitted => '評価を送信しました';

  @override
  String get flowCouldNotSubmitRating => '評価を送信できませんでした';

  @override
  String get flowDeleteYourRating => '自分の評価を削除しますか？';

  @override
  String get flowRatingDeleted => '評価を削除しました';

  @override
  String get flowCouldNotDeleteRating => '評価を削除できませんでした';

  @override
  String get flowChartRating => '譜面評価';

  @override
  String flowP0Ratings(String p0) {
    return '（$p0人が評価）';
  }

  @override
  String get flowDistribution => '分布';

  @override
  String get flowRatingsAreForReferencePleaseRateObjectively =>
      '評価は参考用です。客観的に評価してください。';

  @override
  String get flowRefreshRatings => '評価を更新';

  @override
  String get flowMyRecentRatings => '最近の自分の評価';

  @override
  String get flowMyRatingTapToEdit => '自分の評価（タップで変更）';

  @override
  String get flowRateThisChart => 'この譜面を評価';

  @override
  String get flowDeleteRating => '評価を削除';

  @override
  String get flowUpdate => '更新';

  @override
  String get flowSubmit => '送信';

  @override
  String get flowRefreshDataOnTheHomePageTo2 =>
      '評価する前にホームでデータを更新し、ユーザー情報を取得してください';

  @override
  String get flowNoRatingsYet2 => '評価データがありません';

  @override
  String get flowRatingDistribution => '評価分布';

  @override
  String flowP0Ratings2(String p0) {
    return '$p0人が評価';
  }

  @override
  String flowAverageP0(String p0) {
    return '平均$p0';
  }

  @override
  String get flowSetYourIdentityFirst => '先にユーザー情報を設定してください';

  @override
  String get flowCommentPosted => 'コメントを投稿しました';

  @override
  String get flowCouldNotPostComment => 'コメントを投稿できませんでした';

  @override
  String flowCouldNotPostCommentP0(String p0) {
    return 'コメントを投稿できませんでした：$p0';
  }

  @override
  String get flowCannotDeleteIdentityInformationIsMissing =>
      'ユーザー情報がないため削除できません';

  @override
  String get flowDeleteThisComment => 'このコメントを削除しますか？';

  @override
  String get flowCommentDeleted => 'コメントを削除しました';

  @override
  String get flowCouldNotDeleteComment => 'コメントを削除できませんでした';

  @override
  String get flowComments => 'コメント';

  @override
  String get flowCommentsRefreshed => 'コメントを更新しました';

  @override
  String get flowRefreshComments => 'コメントを更新';

  @override
  String get flowCommentsAreForReferencePleaseBeRespectful =>
      'コメントは参考用です。マナーを守って投稿してください。';

  @override
  String get flowRefreshDataOnTheHomePageTo3 =>
      'コメントする前にホームでデータを更新し、ユーザー情報を取得してください';

  @override
  String get flowEnterYourComment => 'コメントを入力…';

  @override
  String get flowPost => '投稿';

  @override
  String get flowNoCommentsYetBeTheFirstTo => 'コメントがありません。最初のコメントを投稿しましょう！';

  @override
  String get flowMe => '自分';

  @override
  String get flowViewNotes => 'メモを見る';

  @override
  String get flowAddNotes => 'メモを追加';

  @override
  String get flowExportSongInformation => '楽曲情報を書き出す';

  @override
  String get flowShareScore => '成績を共有';

  @override
  String get flowEnlargeCoverArt => 'ジャケットを拡大';

  @override
  String get flowSwitchToDX => 'DXに切替';

  @override
  String get flowSwitchToST => 'STに切替';

  @override
  String flowP0LevelP1(String p0, String p1) {
    return '$p0 レベル$p1';
  }

  @override
  String flowNoScoreForP0Yet(String p0) {
    return '$p0の成績がありません';
  }

  @override
  String get flowPlayAndSyncToSeeYourScore => 'プレイ後に同期すると、ここに成績が表示されます';

  @override
  String flowDXScoreMAXP0(String p0) {
    return 'でらっくスコア（MAX -$p0）';
  }

  @override
  String get flowShowStarBonus => 'スターのボーナスを表示';

  @override
  String get flowShowPointsNeededForTheNextStar => '次のスターまでの必要点を表示';

  @override
  String get flowRatingPotential => 'Rating向上の余地';

  @override
  String get flowBasicInformation => '基本情報';

  @override
  String get flowNoteDistribution => 'ノーツ分布';

  @override
  String get flowBREAKDistribution => 'BREAK分布';

  @override
  String get flowNoGlobalGradeOrComboDistributionData =>
      'この譜面の全体ランク・コンボ分布データはまだありません';

  @override
  String get flowTAPGREATsAllBREAKsCriticalPerfect =>
      ' TAP GREAT（BREAKはすべてCRITICAL PERFECT）';

  @override
  String get flowOpenCalculatorWithThisChartSNotes =>
      'この譜面のノーツ数と成績を引き継いで計算機を開く';

  @override
  String get flowNoTagsYet => 'タグがありません';

  @override
  String get flowTagDataFrom => 'タグのデータ提供元：';

  @override
  String get flowUnknownTag => '不明なタグ';

  @override
  String get flowConstantHistory => '定数の履歴';

  @override
  String get flowStarsDXScoreTable => 'スター・でらっくスコア対応表';

  @override
  String get flowStars => 'スター数';

  @override
  String get flowDXScore2 => 'でらっくスコア';

  @override
  String get flowPlayers => 'プレイヤー';

  @override
  String get flowAchievementScoreTable => '達成率・得点対応表';

  @override
  String get flowScore => '得点';

  @override
  String get flowJudgmentAllowance => '許容判定の計算';

  @override
  String get flowNoteType => 'ノーツの種類：';

  @override
  String get flowShareOfTotalWeight => '合計重みに占める割合：';

  @override
  String get flowBREAKLossSoFar => '現在のBREAK損失';

  @override
  String get flow50PointLosses => '50落ちの数';

  @override
  String get flowInvalid => '無効';

  @override
  String get flow100PointLosses => '100落ちの数';

  @override
  String get flow80GREATCount => '80% GREATの数';

  @override
  String get flow60GREATCount => '60% GREATの数';

  @override
  String get flow50GREATCount => '50% GREATの数';

  @override
  String get flowGOODCount => 'GOODの数';

  @override
  String get flowMISSCount => 'MISSの数';

  @override
  String get flowTotalBREAKLoss => 'BREAKの合計損失：';

  @override
  String get flowRemainingBudgetSSS => '残り許容損失（SSS+）：';

  @override
  String get flowRemainingBudgetSSS2 => '残り許容損失（SSS）：';

  @override
  String get flowRemainingBudgetSS => '残り許容損失（SS+）：';

  @override
  String get flowRemainingBudgetSS2 => '残り許容損失（SS）：';

  @override
  String get flowGREATLoss => 'GREATの損失';

  @override
  String get flowGOODLoss => 'GOODの損失';

  @override
  String get flowMISSLoss => 'MISSの損失';

  @override
  String get flowSSSGREATAllowance => 'SSS+の許容GREAT';

  @override
  String get flowSSSGOODAllowance => 'SSS+の許容GOOD';

  @override
  String get flowSSSMISSAllowance => 'SSS+の許容MISS';

  @override
  String flowP0(String p0) {
    return '$p0個';
  }

  @override
  String get flowSSSGREATAllowance2 => 'SSSの許容GREAT';

  @override
  String get flowSSSGOODAllowance2 => 'SSSの許容GOOD';

  @override
  String get flowSSSMISSAllowance2 => 'SSSの許容MISS';

  @override
  String get flowSSGREATAllowance => 'SS+の許容GREAT';

  @override
  String get flowSSGOODAllowance => 'SS+の許容GOOD';

  @override
  String get flowSSMISSAllowance => 'SS+の許容MISS';

  @override
  String get flowSSGREATAllowance2 => 'SSの許容GREAT';

  @override
  String get flowSSGOODAllowance2 => 'SSの許容GOOD';

  @override
  String get flowSSMISSAllowance2 => 'SSの許容MISS';

  @override
  String get flow50PointLoss => '50落ちの損失';

  @override
  String get flow100PointLoss => '100落ちの損失';

  @override
  String get flow80GREATLoss => '80% GREATの損失';

  @override
  String get flow60GREATLoss => '60% GREATの損失';

  @override
  String get flow50GREATLoss => '50% GREATの損失';

  @override
  String get flow0580GREATAllowance => '-0.5%の許容80% GREAT';

  @override
  String get flow0560GREATAllowance => '-0.5%の許容60% GREAT';

  @override
  String get flow0550GREATAllowance => '-0.5%の許容50% GREAT';

  @override
  String get flow05Allowance => '-0.5%の許容数';

  @override
  String get flow180GREATAllowance => '-1%の許容80% GREAT';

  @override
  String get flow160GREATAllowance => '-1%の許容60% GREAT';

  @override
  String get flow150GREATAllowance => '-1%の許容50% GREAT';

  @override
  String get flow1Allowance => '-1%の許容数';

  @override
  String get flowGradeDistributionReferenceOnly => 'ランク分布（参考用）';

  @override
  String get flowComboDistributionReferenceOnly => 'コンボ分布（参考用）';

  @override
  String get flowInTheOrderBPMMarkersAppearIn => 'この譜面内でBPM指定が現れる順';

  @override
  String get flowChangeIndex => '変更順';

  @override
  String get flowPlayOnBilibili => 'Bilibiliで再生';

  @override
  String get flowPlayableRegions => 'プレイ可能地域';

  @override
  String get flowParsingDataUnavailable => '解析データがありません';

  @override
  String get flowExcludesSLIDETOUCHAndBREAKStars =>
      'SLIDE・TOUCH・BREAKスターを除きます。';

  @override
  String get flowAliasesNone => '別名：なし';

  @override
  String flowAliasesForP0(String p0) {
    return '$p0の別名';
  }

  @override
  String get flowTapAnyAliasToCopy => '別名をタップしてコピー';

  @override
  String flowViewAliasesP0(String p0) {
    return '別名を見る（$p0）';
  }

  @override
  String flowDXScoreP02(String p0) {
    return 'でらっくスコア$p0%';
  }

  @override
  String flowRankP0P1RatingP2(String p0, String p1, String p2) {
    return '$p0位、$p1、Rating $p2';
  }

  @override
  String get flowRatingHeadroom => 'Rating向上の余地';

  @override
  String flowRaiseToP0P1(String p0, String p1) {
    return '$p0（$p1%）まで向上';
  }

  @override
  String flowDXScoreP0P12(String p0, String p1) {
    return 'でらっくスコア$p0 / $p1';
  }

  @override
  String get flowViewSongDetails => '楽曲詳細を見る';

  @override
  String flowP0SongsRemaining(String p0) {
    return '残り$p0曲';
  }

  @override
  String flowP0EqualToTheLastChartOn(String p0) {
    return '$p0、リスト末尾の譜面と同値';
  }

  @override
  String flowP0ConstantP1RAP2(String p0, String p1, String p2) {
    return '$p0・定数$p1・RA $p2';
  }

  @override
  String get flowAddScoreHistory => '成績履歴を追加';

  @override
  String flowScoreHistoryP0(String p0) {
    return '成績履歴（$p0）';
  }

  @override
  String get flowTheCurveDropsInGameScoresKeep =>
      '推移が低下しています。ゲーム内では最高成績が保持されるため、取得元やアカウントの切替による記録の差であることが多いです。';

  @override
  String get flowUnknownDate => '日時不明';

  @override
  String flowShowAllP0Entries(String p0) {
    return 'すべて表示（$p0件）';
  }

  @override
  String get flowAddChartScoreHistory => '譜面の成績履歴を追加';

  @override
  String get flowAchievement3 => '達成率（%）';

  @override
  String get flowSumOfUTAGESubcharts => '宴会場の子譜面の合計';

  @override
  String get flowNormalChartLimit => '通常譜面の上限';

  @override
  String get flowDXScoreOptional => 'でらっくスコア（任意）';

  @override
  String get flowChartMaximumScore => '譜面の満点';

  @override
  String get flowSelectTime => '時刻を選択';

  @override
  String get flowSeconds059 => '秒（0～59）';

  @override
  String get flowDeleteThisDataPoint => 'この記録点を削除しますか？';

  @override
  String get flowThisCannotBeUndoneIfThisIs =>
      '削除は取り消せません。自動記録された現在の成績の場合、次回の更新で再度記録されることがあります。';

  @override
  String get flowDataVoluntarilyUploadedByPlayersForReference =>
      'プレイヤーが任意で公開したデータです。参考・娯楽用としてご覧ください';

  @override
  String get flowBriefProfilesAreHiddenForAnonymousPlayers =>
      '匿名プレイヤーの簡易プロフィールは表示しません';

  @override
  String get flowCouldNotLoadTheBriefProfileTry =>
      '簡易プロフィールを読み込めませんでした。後でもう一度お試しください。';

  @override
  String get flowReload => '再読み込み';

  @override
  String get flowUnknownPlayer => '不明なプレイヤー';

  @override
  String get flowNoTitleSet => '称号未設定';

  @override
  String get flowB1IsTheChartWithTheHighest =>
      'B1は該当するBestリストの中で単曲Ratingが最も高い譜面です。';

  @override
  String get flowNoScoresYet => '成績がありません';

  @override
  String get flowDanCompletion => '段位の達成状況';

  @override
  String get flowTotalAchievementUpTo4040000 => '合計達成率（最大404.0000%）';

  @override
  String get flowCompletionRate => '達成率';

  @override
  String flowP0Songs2(String p0) {
    return '$p0曲';
  }

  @override
  String get flowExcluded => '対象外';

  @override
  String get flowCompleted => '達成済み';

  @override
  String get flowIncomplete => '未達成';

  @override
  String get flowLoading4 => '読み込み中';

  @override
  String get flowFirstRecord => '初回記録';

  @override
  String flowP0P1Changes(String p0, String p1) {
    return '−$p0・$p1回変化';
  }

  @override
  String get flowRecorded => ' 記録';

  @override
  String get flowTheScoreChangedDuringTheDayBut =>
      '日中に成績が変化しましたが、最新値はその日の初期値に戻っています。';

  @override
  String get flowNoChange => '変化なし';

  @override
  String get flowPlaybackProgressDragTheOuterRingTo =>
      '再生進捗：外周をドラッグして位置を調整、ジャケットを左右にスワイプして曲を切替';

  @override
  String get flowElapsed => '再生済み';

  @override
  String get flowDuration2 => '総時間';

  @override
  String get flowQueue => 'キュー';

  @override
  String get flowLoadingAudio => '音源を読み込み中';

  @override
  String get flowOpenPlaybackQueue => '再生キューを開く';

  @override
  String get flowPlaybackQueue => '再生キュー';

  @override
  String flowPlaybackModeP0TapToSwitchAnd(String p0) {
    return '再生モード：$p0（タップで切替・展開）';
  }

  @override
  String get flowRepeatCount => '繰り返し回数';

  @override
  String get flowNotSet2 => '設定なし';

  @override
  String flowP0Times(String p0) {
    return '$p0回';
  }

  @override
  String get flowUnlimited => '回数指定なし';

  @override
  String get flowRepeatTheCurrentSongIndefinitely => '現在の楽曲を繰り返し再生';

  @override
  String get flowSetCount => '回数を設定';

  @override
  String get flowDecreaseCount => '回数を減らす';

  @override
  String get flowIncreaseCount => '回数を増やす';

  @override
  String get flowHideFloatingPlayer => 'フローティングプレイヤーを隠す';

  @override
  String get flowPlaylist => 'プレイリスト';

  @override
  String get flowKeepPlayingAndReopenTheFloatingPlayer =>
      '再生を続けて後から音楽プレイヤーで再表示するか、一時停止して音楽通知も削除できます。';

  @override
  String get flowKeepPlaying => '再生を続ける';

  @override
  String get flowPauseAndRemove => '一時停止して削除';

  @override
  String get flowSongTitle2 => '楽曲タイトル';

  @override
  String get flowTranslatedByBaiduSLanguageModel => 'Baiduの大規模言語モデルによる翻訳';

  @override
  String get flowTranslating => '翻訳中…';

  @override
  String get flowDifficultiesToPlayMultipleSelections => '遊びたい難易度（複数選択可）';

  @override
  String get flowNotesOptional => 'メモ（任意）';

  @override
  String get flowExamplePlayWithFriends => '例：フレンドと一緒に遊ぶ';

  @override
  String get flowAdd => '追加';

  @override
  String get flowTotalSongs => '総楽曲数';

  @override
  String get flowPathCopiedToClipboard => 'パスをクリップボードにコピーしました';

  @override
  String get flowNoAppAvailableToViewImages => '画像を表示できるアプリがありません';

  @override
  String get flowCopied => 'コピーしました';

  @override
  String get flowCopyPath => 'パスをコピー';

  @override
  String flowPublicDirectoryIsNotWritableSavedTo(String p0) {
    return '公開フォルダに書き込めないため、代替パスに保存しました：$p0';
  }

  @override
  String get flowViewImage => '画像を見る';

  @override
  String get flowPerRow => '1行あたり';

  @override
  String get flowFewerAvatarsPerRow => '1行のアイコン数を減らす';

  @override
  String get flowMoreAvatarsPerRow => '1行のアイコン数を増やす';

  @override
  String get flowChooseAppearance => '装飾を選択';

  @override
  String flowSearchP0ByNameDescriptionOrID(String p0) {
    return '$p0の名前・説明・番号で検索';
  }

  @override
  String flowP0Items3(String p0) {
    return '計$p0件';
  }

  @override
  String flowLoadingP0(String p0) {
    return '$p0を読み込み中…';
  }

  @override
  String flowNoP0YetRefreshCollectibleDataFirst(String p0) {
    return '$p0がありません。先にコレクションデータを更新してください。';
  }

  @override
  String flowNoMatchingP0(String p0) {
    return '一致する$p0がありません';
  }

  @override
  String get flowPNGLosslessOriginalQuality => 'PNG可逆圧縮（元の画質）';

  @override
  String get flowJPEGHighQuality => 'JPEG高画質';

  @override
  String get flowJPEGStandard => 'JPEG標準';

  @override
  String get flowJPEGCompressed => 'JPEG高圧縮';

  @override
  String get flowChooseExportQuality => '書き出し品質を選択';

  @override
  String flowExportingP0(String p0) {
    return '書き出し中：$p0';
  }

  @override
  String get flowImageTheme => '画像テーマ';

  @override
  String get flowThunderMode => 'サンダーモード';

  @override
  String get flowArrangeCardsIn50RowsOr50 => 'カードを50行1列または1行50列に配置し、細長い画像にします';

  @override
  String get flowExportPreview => '書き出しプレビュー';

  @override
  String get flowConfirmExport => '書き出す';

  @override
  String flowCouldNotGeneratePreviewP0(String p0) {
    return 'プレビューを生成できませんでした：$p0';
  }

  @override
  String flowP0P1EstimatedP2(String p0, String p1, String p2) {
    return '$p0、$p1、推定$p2';
  }

  @override
  String flowAboutP0(String p0) {
    return '約$p0';
  }

  @override
  String get flowQuestionPool => '出題範囲';

  @override
  String get flowGameRules => 'ゲームルール';

  @override
  String get flowMaximumGuesses => '最大回答回数';

  @override
  String get flowTimeLimit => '制限時間';

  @override
  String get flowTo => '～';

  @override
  String get flowEnter10150ThenTap => '1.0～15.0で入力し、他の場所をタップするかEnterで確定';

  @override
  String get flowBest35ConstantRange => 'Best35の定数範囲';

  @override
  String get flowBest15ConstantRange => 'Best15の定数範囲';

  @override
  String get flowBest50Average => 'Best 50平均';

  @override
  String get flowBest35Average => 'Best 35平均';

  @override
  String get flowBest15Average => 'Best 15平均';

  @override
  String get flowSSSCountIn50Charts => '50譜面のSSS+数';

  @override
  String get flowSSSCountIn50Charts2 => '50譜面のSSS数';

  @override
  String get flowPotentialConstantRATable => '向上可能な定数・RA対応表';

  @override
  String get flowFittedTotalRating => '推定合計Rating';

  @override
  String get flowDifferenceFromBest50 => 'Best50との差';

  @override
  String get flowAverageAchievementDXScoreRate2 => '平均達成率・でらっくスコア率';

  @override
  String flowCurrentOrderP0(String p0) {
    return '現在の並び順：$p0';
  }

  @override
  String get flowTotalRA => '合計RA';

  @override
  String get flowSongs => '楽曲数';

  @override
  String get flowComparedWithThisTagSBest50 => 'このタグのBest50との差';

  @override
  String get flowSongAchievement => '単曲達成率';

  @override
  String flowTotalRatingP0(String p0) {
    return '合計Rating $p0';
  }

  @override
  String flowP0ConstantP1(String p0, String p1) {
    return '$p0（定数$p1）';
  }

  @override
  String get flowNoteStatistics => 'ノーツ集計';

  @override
  String get flowBREAKStatistics => 'BREAK集計';

  @override
  String flowP0P1P2Statistics2(String p0, String p1, String p2) {
    return '$p0 $p1（$p2）集計';
  }

  @override
  String flowChartDesignerP0(String p0) {
    return '譜面制作者：$p0';
  }

  @override
  String flowVersionP0(String p0) {
    return 'バージョン：$p0';
  }

  @override
  String flowGenreP0(String p0) {
    return 'ジャンル：$p0';
  }

  @override
  String flowComposerP0(String p0) {
    return 'アーティスト：$p0';
  }

  @override
  String flowP0P1P2SongsTotal(String p0, String p1, String p2) {
    return '$p0$p1・計$p2曲';
  }

  @override
  String get flowFolderNameCannotBeEmpty => 'フォルダ名を入力してください';

  @override
  String get flowNoAudioIsAvailableForThisSong => 'この楽曲の音源はまだありません';

  @override
  String get flowCouldNotLoadAudioTryAgainLater =>
      '音源を読み込めませんでした。後でもう一度お試しください。';

  @override
  String get flowReadingLocalVideo => 'ローカル動画を読み込み中…';

  @override
  String get flowBufferingVideo => '動画をバッファ中…';

  @override
  String get flowNoMatchingChartCodeFound => '一致する譜面コードがありません';

  @override
  String flowCouldNotFetchChartCodeP0(String p0) {
    return '譜面コードを取得できませんでした：$p0';
  }

  @override
  String get flowExporting2 => '書き出し中…';

  @override
  String get flowNoChartCodeAvailable => '譜面コードがありません';

  @override
  String get flowAudio => '音源';

  @override
  String flowCouldNotFetchP0ThePackageOnly(String p0) {
    return '$p0を取得できませんでした。パッケージには譜面データのみ含まれます。正常に遊ぶには、読み込み後に不足ファイルを追加してください。';
  }

  @override
  String get flowPreparingChart => '譜面を準備中…';

  @override
  String get flowReadingChartSettings => '譜面設定を読み込み中…';

  @override
  String get flowFindingAudio => '音源を検索中…';

  @override
  String get flowPreparingCoverArt => 'ジャケットを準備中…';

  @override
  String get flowParsingChartData => '譜面データを解析中…';

  @override
  String get flowAudioLoadedFromLocalCache => 'ローカルキャッシュから音源を読み込みました';

  @override
  String get flowAnd => 'と';

  @override
  String flowP0MinutesAgo(String p0) {
    return '$p0分前';
  }

  @override
  String flowP0HoursAgo(String p0) {
    return '$p0時間前';
  }

  @override
  String flowP0DaysAgo(String p0) {
    return '$p0日前';
  }

  @override
  String get flowCustomChart2 => 'カスタム譜面';

  @override
  String get flowMaidataFileSelected => 'maidataファイルを選択済み';

  @override
  String get flowTheLibraryIsNotReadyRefreshData =>
      'ライブラリの準備ができていません。ホームで「成績取得とデータ更新」を実行するか、接続を確認して再試行してください。';

  @override
  String flowCouldNotLoadLibraryP0(String p0) {
    return 'ライブラリを読み込めませんでした：$p0';
  }

  @override
  String get flowNotificationPermissionWasNotGrantedBackgroundPlayback =>
      '通知が許可されていません。バックグラウンド再生はできますが、通知プレイヤーは表示されません。';

  @override
  String get flowDownloaded2 => 'ダウンロード済み';

  @override
  String flowDownloadFailedP02(String p0) {
    return 'ダウンロードに失敗しました：$p0';
  }

  @override
  String get flowTheCurrentSongIsNotInThis => '再生中の楽曲はこの一覧にありません';

  @override
  String get flowNoPlayableSongs => '再生できる楽曲がありません';

  @override
  String get flowNoMatchingSongs => '一致する楽曲がありません';

  @override
  String flowP0PlayableSongs(String p0) {
    return '再生可能な楽曲：計$p0曲';
  }

  @override
  String flowExcludedP0UTAGESongs(String p0) {
    return '宴会場の$p0曲を除外';
  }

  @override
  String flowP0SongsHaveNoDivingFishEntry(String p0) {
    return '水魚に対応するデータがない楽曲：$p0曲';
  }

  @override
  String get flowCalculating => '計算中';

  @override
  String get flowSwitchingSongs => '楽曲を切り替え中…';

  @override
  String get flowThisIsTheLastSong => '最後の楽曲です';

  @override
  String get flowUpNext => '次の曲';

  @override
  String get flowUpToOneDecimalPlaceLeaveBlank => '小数第1位まで。空欄は初期値を使用します。';

  @override
  String get flowUpToFourDecimalPlacesLeaveBlank => '小数第4位まで。空欄は初期値を使用します。';

  @override
  String get flowGrade => 'ランク';

  @override
  String get flowLowerBound => '下限';

  @override
  String get flowUpperBound => '上限';

  @override
  String get flowCategory => '種類';

  @override
  String get flowSelectALevel => 'レベルを選択してください';

  @override
  String get flowSelectAVersion => 'バージョンを選択してください';

  @override
  String get flowSelectAGenre => 'ジャンルを選択してください';

  @override
  String get flowTitleType => '称号の種類';

  @override
  String get flowNoMatchingChartDesigners2 => '一致する譜面制作者がいません';

  @override
  String get flowNoMatchingComposers => '一致するアーティストがいません';

  @override
  String get flowSongs2 => '曲';

  @override
  String get flowNoSongsMatchThisLevel => 'このレベルに一致する楽曲がありません';

  @override
  String get flowNoSongsMatchThisChartDesigner => 'この譜面制作者に一致する楽曲がありません';

  @override
  String get flowNoSongsMatchThisVersion => 'このバージョンに一致する楽曲がありません';

  @override
  String get flowNoSongsMatchThisGenre => 'このジャンルに一致する楽曲がありません';

  @override
  String get flowNoSongsMatchThisComposer => 'このアーティストに一致する楽曲がありません';

  @override
  String flowLvP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'Lv.$p0（$p1）の$p2称号集計';
  }

  @override
  String flowChartDesignerP0P1P2TitleStatistics(
      String p0, String p1, String p2) {
    return '譜面制作者$p0（$p1）の$p2称号集計';
  }

  @override
  String flowVersionP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'バージョン$p0（$p1）の$p2称号集計';
  }

  @override
  String flowGenreP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'ジャンル$p0（$p1）の$p2称号集計';
  }

  @override
  String flowComposerP0P1P2TitleStatistics(String p0, String p1, String p2) {
    return 'アーティスト$p0（$p1）の$p2称号集計';
  }

  @override
  String get flowFriendCode => 'フレンドコード';

  @override
  String flowEnterYourFriendSP02(String p0) {
    return 'フレンドの$p0を入力してください';
  }

  @override
  String flowMeP0(String p0) {
    return '自分・$p0';
  }

  @override
  String get flowMyWins => '自分の勝ち';

  @override
  String get flowFriendSWins => 'フレンドの勝ち';

  @override
  String get flowFriend => 'フレンド';

  @override
  String get flowFirstCharacter => '頭文字';

  @override
  String get flowSelectAFirstCharacter => '頭文字を選択してください';

  @override
  String get flowNoSongsMatchThisDifficulty => 'この難易度に一致する楽曲がありません';

  @override
  String get flowByAverageAchievement => '平均達成率でおすすめ';

  @override
  String get flowByConstantDifference => '定数差でおすすめ';

  @override
  String get flowAvgAchievement => '平均達成率';

  @override
  String get flowConstantDifference => '定数差';

  @override
  String flowPersonalBestP0(String p0) {
    return '自己ベスト$p0%';
  }

  @override
  String get flowLast30Days => '直近30日';

  @override
  String get flowLast90Days => '直近90日';

  @override
  String flowLimitP0TheoreticalValueUnavailable(String p0) {
    return '上限$p0（理論値を取得できません）';
  }

  @override
  String flowCouldNotLoadImprovementHistoryP0(String p0) {
    return '向上履歴を読み込めませんでした：$p0';
  }

  @override
  String get flowChangesAreRecordedAutomaticallyAfterYourScores =>
      '自分の成績の更新に成功すると自動で記録します。水魚・落雪・AWMC NETの記録は取得元・アカウント別に保存します。\n\n過去成績がない初回は基準のみを作成し、変化のない更新では記録を追加しません。同じ日の同一譜面の変化は1枚に統合し、最初の変化前と最新の値を表示します。\n\n更新時の端末の日付で分類します。時刻は変化を検出した時点で、実際のプレイ時刻ではありません。前後の値に応じて向上・低下・変化なし・混合の変化を表示し、初めて取得した譜面には初回記録と記します。\n\nRatingはその譜面の値で、合計Ratingの増分ではありません。履歴はこの端末だけに保存され、記録開始前の成績は取得しません。';

  @override
  String get flowNoScoreImprovementRecordsYet => '成績向上の記録がありません';

  @override
  String get flowNoMatchingRecords => '条件に合う記録がありません';

  @override
  String get flowBestScoresThatChangeAfterASuccessful =>
      '更新成功後に変化したベスト成績がここに表示されます。';

  @override
  String get flowTryAnotherKeywordOrDate => '別のキーワードや日付をお試しください。';

  @override
  String get flowCouldNotLoad => '読み込みに失敗しました';

  @override
  String flowRequestFailedP0(String p0) {
    return 'リクエストに失敗しました（$p0）';
  }

  @override
  String flowNetworkErrorP0(String p0) {
    return '通信エラー：$p0';
  }

  @override
  String flowP0MinutesAgo2(String p0) {
    return '$p0分前';
  }

  @override
  String flowP0HoursAgo2(String p0) {
    return '$p0時間前';
  }

  @override
  String flowP0DaysAgo2(String p0) {
    return '$p0日前';
  }

  @override
  String flowP0User(String p0) {
    return '$p0ユーザー';
  }

  @override
  String flowCouldNotSaveSnapshotP0(String p0) {
    return 'スナップショットを保存できませんでした：$p0';
  }

  @override
  String get flowHighestConstantsFromOlderVersions => '旧バージョンの最高定数';

  @override
  String get flowBestScoresFromOlderVersions => '旧バージョンのベスト成績';

  @override
  String get flowHighestConstantsFromThisVersion => '現バージョンの最高定数';

  @override
  String get flowBestScoresFromThisVersion => '現バージョンのベスト成績';

  @override
  String get flowPattern => '配置';

  @override
  String get flowEvaluation => '評価';

  @override
  String get flowModeATakeTheTop50Charts =>
      'モードA：Best35とBest15を分けず、推定定数でのRating上位50譜面を選びます。';

  @override
  String get flowModeBReplaceConstantsInYourOfficial =>
      'モードB：公式Best35・Best15の定数を推定定数に置き換え、Ratingを再計算して降順に並べます。';

  @override
  String get flowModeCTakeTheTop35Older =>
      'モードC：推定定数でのRatingから、旧バージョンの上位35譜面と現バージョンの上位15譜面を選びます。';

  @override
  String get flowTop35FromOlderVersions => '旧バージョンの上位35';

  @override
  String get flowTop15FromThisVersion => '現バージョンの上位15';

  @override
  String flowP0ChartsHaveNoFittedConstantOfficial(String p0) {
    return '$p0譜面に推定定数がないため、公式定数を使用しています。';
  }

  @override
  String flowIncludesP0(String p0) {
    return '含む：$p0';
  }

  @override
  String flowChartDesigner50P0(String p0) {
    return '譜面制作者50 - $p0';
  }

  @override
  String flowVersion50P0(String p0) {
    return 'バージョン50 - $p0';
  }

  @override
  String flowGenre50P0(String p0) {
    return 'ジャンル50 - $p0';
  }

  @override
  String flowStar50P0(String p0) {
    return 'スター50 - $p0';
  }

  @override
  String flowTag50P0(String p0) {
    return 'タグ50 - $p0';
  }

  @override
  String flowPersonalizedBest50P0(String p0) {
    return '条件別Best50 - $p0';
  }

  @override
  String flowChartDesigner50P0Statistics(String p0) {
    return '譜面制作者50 - $p0 集計';
  }

  @override
  String flowVersion50P0Statistics(String p0) {
    return 'バージョン50 - $p0 集計';
  }

  @override
  String flowGenre50P0Statistics(String p0) {
    return 'ジャンル50 - $p0 集計';
  }

  @override
  String flowStar50P0Statistics(String p0) {
    return 'スター50 - $p0 集計';
  }

  @override
  String flowTag50P0Statistics(String p0) {
    return 'タグ50 - $p0 集計';
  }

  @override
  String flowP0Statistics(String p0) {
    return '$p0 集計';
  }

  @override
  String flowPersonalizedFittedBest50P0(String p0) {
    return '条件別推定Best50 - $p0';
  }

  @override
  String flowTagP0P1ChartsTop50By(String p0, String p1) {
    return 'タグ：$p0・計$p1譜面・推定定数の単曲Rating上位50譜面';
  }

  @override
  String get flowAverage => '平均';

  @override
  String get flowOlderVersions => '旧バージョン';

  @override
  String get flowCurrentVersion => '現バージョン';

  @override
  String flowP0InvalidEntriesAchievementOrDXScore(String p0) {
    return '⚠ 無効なデータが$p0件あります（達成率やでらっくスコアが譜面の上限を超えています）';
  }

  @override
  String get flowEG1005 => '例：100.5';

  @override
  String get flowEG3000 => '例：3000';

  @override
  String get flowEnterAchievement => '達成率を入力してください';

  @override
  String flowDifficultyP03(String p0) {
    return '難易度$p0';
  }

  @override
  String get flowRADescending => 'RAの高い順';

  @override
  String get flowRAAscending => 'RAの低い順';

  @override
  String get flowConstantDescending => '定数の高い順';

  @override
  String get flowConstantAscending => '定数の低い順';

  @override
  String get flowFilled => '入力済み';

  @override
  String flowCouldNotLoadP0(String p0) {
    return '読み込みに失敗しました：$p0';
  }

  @override
  String get flowModeATop50ByFittedRating => 'モードA：区分なしで推定Rating上位50譜面';

  @override
  String get flowModeBRecalculateOfficialBest35Best15Using =>
      'モードB：公式Best35・Best15を推定定数で再計算';

  @override
  String get flowModeCTop35OlderChartsAnd => 'モードC：旧曲上位35譜面・新曲上位15譜面';

  @override
  String get flow6MaximumReached => '✦ 6 到達済み';

  @override
  String get flowCouldNotLoadLeaderboardData => 'ランキングデータを読み込めませんでした';

  @override
  String get flowAchievementRanking2 => '達成率ランキング';

  @override
  String get flowDXScoreRanking2 => 'でらっくスコアランキング';

  @override
  String flowCouldNotFetchLeaderboardP0(String p0) {
    return 'ランキングを取得できませんでした：$p0';
  }

  @override
  String get flowBREAKShareRanking => 'BREAK割合ランキング';

  @override
  String get flowSameSongDifficultyGapRanking => '同曲の難易度差ランキング';

  @override
  String get flowSLIDEShareRanking => 'SLIDE割合ランキング';

  @override
  String get flowTOUCHShareRanking => 'TOUCH割合ランキング';

  @override
  String get flowTAPShareRanking => 'TAP割合ランキング';

  @override
  String get flowHOLDShareRanking => 'HOLD割合ランキング';

  @override
  String get flowBREAKCountRanking => 'BREAK数ランキング';

  @override
  String get flowNormalChartBREAKCountRanking => '通常譜面のBREAK数ランキング';

  @override
  String get flowConstantDifferenceRanking => '定数差ランキング';

  @override
  String get flowMASTERReMASTERConstantDifferenceRanking =>
      'MASTER/Re:MASTER定数差ランキング';

  @override
  String get flowEXPERTConstantDifferenceRanking => 'EXPERT定数差ランキング';

  @override
  String get flowSampleCountRanking => 'サンプル数ランキング';

  @override
  String get flowNoteCountRanking => 'ノーツ数ランキング';

  @override
  String get flowMASTERReMASTERAverageAchievementRanking =>
      'MASTER/Re:MASTER平均達成率ランキング';

  @override
  String get flowEXPERTAverageAchievementRanking => 'EXPERT平均達成率ランキング';

  @override
  String get flowBPMRanking => 'BPMランキング';

  @override
  String get flowBREAKShare => 'BREAK割合';

  @override
  String get flowConstantGap => '定数差';

  @override
  String get flowSLIDEShare => 'SLIDE割合';

  @override
  String get flowTOUCHShare => 'TOUCH割合';

  @override
  String get flowTAPShare => 'TAP割合';

  @override
  String get flowHOLDShare => 'HOLD割合';

  @override
  String get flowBREAKCount => 'BREAK数';

  @override
  String get flowSampleCount => 'サンプル数';

  @override
  String get flowRankByBREAKCountOrderCanBe => 'BREAK数で順位付け（正順・逆順を切替可能）';

  @override
  String get flowRankByBREAKCountExcludingUTAGEOrder =>
      '宴会場を除くBREAK数で順位付け（正順・逆順を切替可能）';

  @override
  String get flowBREAKCountTotalNotesRankedAsA =>
      'BREAK数÷総ノーツ数の割合で順位付け（正順・逆順を切替可能）';

  @override
  String get flowTAPCountTotalNotesIncludesSTDX =>
      'TAP数÷総ノーツ数。ST・DX・UTが対象（正順・逆順を切替可能）';

  @override
  String get flowHOLDCountTotalNotesIncludesSTDX =>
      'HOLD数÷総ノーツ数。ST・DX・UTが対象（正順・逆順を切替可能）';

  @override
  String get flowSLIDECountTotalNotesIncludesSTDX =>
      'SLIDE数÷総ノーツ数。ST・DX・UTが対象（正順・逆順を切替可能）';

  @override
  String get flowTOUCHCountTotalNotesIncludesDXUT =>
      'TOUCH数÷総ノーツ数。DX・UTが対象、STは除外（正順・逆順を切替可能）';

  @override
  String get flowOfficialConstantGapForEXPERTMASTERAnd =>
      '同曲のEXPERT→MASTER・MASTER→Re:MASTERの公式定数差（後者－前者、正順・逆順を切替可能）';

  @override
  String get flowRankByFittedMinusOfficialConstantOrder =>
      '推定定数と公式定数の差で順位付け（正順・逆順を切替可能）';

  @override
  String get flowMASTERReMASTEROnlyOrderCanBe =>
      'MASTER・Re:MASTERのみ（正順・逆順を切替可能）';

  @override
  String get flowEXPERTOnlyOrderCanBeReversed => 'EXPERTのみ（正順・逆順を切替可能）';

  @override
  String get flowRankByTotalPlayerSamplesOrderCan =>
      'プレイヤーのサンプル総数で順位付け（正順・逆順を切替可能）';

  @override
  String get flowRankByTheTotalOfAllFive => '5種類のノーツ合計で順位付け（正順・逆順を切替可能）';

  @override
  String get flowRankByAverageAchievementOrderCanBe => '平均達成率で順位付け（正順・逆順を切替可能）';

  @override
  String get flowRankBySongBPMOrderCanBe => '楽曲のBPMで順位付け（正順・逆順を切替可能）';

  @override
  String get flowEnterABVID => 'BV番号を入力してください';

  @override
  String get flowInvalidBVIDExpectedBVFollowedBy => 'BV番号の形式が正しくありません（BV＋10文字）';

  @override
  String get flowCheckFailedVideoInformationUnavailableTheBV =>
      '確認失敗：動画情報を取得できません（BV番号が存在しない可能性があります）';

  @override
  String flowVerifiedVideoTitleP0(String p0) {
    return '確認できました！動画タイトル：「$p0」';
  }

  @override
  String flowCheckFailedVideoTitleP0DoesNot(String p0, String p1) {
    return '確認失敗：動画タイトル「$p0」に曲名「$p1」が含まれていません';
  }

  @override
  String flowVerificationErrorP0(String p0) {
    return '確認中にエラーが発生しました：$p0';
  }

  @override
  String get flowSongPV => '楽曲PV';

  @override
  String get flowPlayThisChartAtLeastOnceBefore =>
      '評価するには、この譜面を1回以上プレイする必要があります';

  @override
  String get flowInvalidScorePleaseCheckIt => '成績が正しくありません。確認してください。';

  @override
  String get flowContentCannotBeEmpty => '内容を入力してください';

  @override
  String get flowCommentsCannotExceed500Characters => 'コメントは500文字以内で入力してください';

  @override
  String get flowSending => '送信中…';

  @override
  String get flowOpenBilibili2 => 'Bilibiliを開く';

  @override
  String flowRelatedCollectiblesP0(String p0) {
    return '関連コレクション$p0';
  }

  @override
  String flowMyScoreP0(String p0) {
    return '自分の成績・$p0';
  }

  @override
  String flowPlayedP0Times(String p0) {
    return 'プレイ回数$p0回';
  }

  @override
  String flowFittedP0P1(String p0, String p1) {
    return '推定$p0$p1';
  }

  @override
  String get flowDuration3 => '長さ';

  @override
  String get flowScoreHistory => '成績履歴';

  @override
  String get flowData => 'データ';

  @override
  String get flowCommunity => 'コミュニティ';

  @override
  String get flowTools => 'ツール';

  @override
  String get flowTrueBREAKTAP => '通常BREAK TAP';

  @override
  String get flowTrueBREAKHOLD => '通常BREAK HOLD';

  @override
  String get flowProtectedBREAK => '保護付きBREAK';

  @override
  String get flowBREAKStar => 'BREAKスター';

  @override
  String get flowCategory2 => '種類';

  @override
  String get flowTotal => '計';

  @override
  String get flowSSSAllowance => 'SSS+許容数';

  @override
  String get flowSSSAllowance2 => 'SSS許容数';

  @override
  String get flowChartTagsReferenceOnly => '譜面タグ（参考用）';

  @override
  String get flowPreview => '試聴';

  @override
  String get flowMore => 'その他';

  @override
  String get flowViewChartCode => '譜面コードを見る';

  @override
  String get flowUTAGESongsAreExcludedFromBest50 => '宴会場の楽曲はBest50の対象外です';

  @override
  String flowThisChartIsAlreadyWithinP0With(String p0) {
    return 'この譜面はすでに$p0内にあり、向上の余地がありません';
  }

  @override
  String flowThisChartCannotEnterP0(String p0) {
    return 'この譜面は$p0に入れません';
  }

  @override
  String flowReachP0ToP1P2(String p0, String p1, String p2) {
    return '$p0%で$p1 $p2';
  }

  @override
  String get flowEnter => 'ランクイン';

  @override
  String flowThisChartHasRAP0ReachingThe(String p0, String p1) {
    return 'この譜面の現在のRAは$p0です。以下の達成率で$p1の合計に加算できる値：';
  }

  @override
  String flowThisChartIsNotInP0The(String p0, String p1) {
    return 'この譜面は$p0の対象外で、末尾はRA $p1です。以下の達成率で入れ替えた場合に合計に加算できる値：';
  }

  @override
  String flowP0BaseP1(String p0, String p1) {
    return '$p0（基準$p1）';
  }

  @override
  String get flowUserUpload => 'ユーザー投稿';

  @override
  String get flowRedisCache => 'Redisキャッシュ';

  @override
  String get flowAutomaticLookup => '自動取得';

  @override
  String get flowUnknownType => '不明な種類';

  @override
  String get flowCountCannotBeNegative => '個数に負の値は指定できません';

  @override
  String flowPlayedCountP0CannotExceedTheTotal(String p0, String p1) {
    return '判定済みの合計（$p0）はBREAKの総数（$p1）を超えられません';
  }

  @override
  String flowBREAKLossIsP0BeyondTheSS(String p0) {
    return 'BREAK損失が$p0%でSS（-2%）の上限を超えています。許容できる判定はありません。';
  }

  @override
  String flowP0DaysApart(String p0) {
    return '（$p0日の差）';
  }

  @override
  String flowFirstReleaseP0(String p0) {
    return '初登場$p0';
  }

  @override
  String get flowBase => '基準';

  @override
  String get flowProtectedNOTEDistribution => '保護付きNOTE分布';

  @override
  String get flowProtectedTAP => '保護付きTAP';

  @override
  String get flowProtectedHOLD => '保護付きHOLD';

  @override
  String get flowUnprotectedNOTEDistribution => '保護なしNOTE分布';

  @override
  String get flowUnprotectedTAP => '保護なしTAP';

  @override
  String get flowUnprotectedHOLD => '保護なしHOLD';

  @override
  String get flowTwoColumns => '2列';

  @override
  String get flowOneColumn => '1列';

  @override
  String flowP00Songs(String p0) {
    return '$p0 0曲';
  }

  @override
  String flowP0P1SongsMinP2AvgP3(String p0, String p1, String p2, String p3) {
    return '$p0 $p1曲・最低$p2・平均$p3・カードをタップして向上の余地を確認';
  }

  @override
  String get flowSongLimitReached => '単曲の上限に到達済み';

  @override
  String flowChartHistoryCouldNotReadChartHistoryIgnored(String p0) {
    return '[ChartHistory] 譜面履歴の読み込み失敗（無視）：$p0';
  }

  @override
  String flowP0AchievementP1P2(String p0, String p1, String p2) {
    return '$p0\n達成率$p1%$p2';
  }

  @override
  String flowDXScoreP03(String p0) {
    return '・でらっくスコア$p0';
  }

  @override
  String get flow1DataPoint => '記録点1件';

  @override
  String flowP0Changes(String p0) {
    return '$p0回の変化';
  }

  @override
  String get flowDXScoreOfMaximum => 'でらっくスコア（満点比%）';

  @override
  String flowP0AchievementP1DXScoreP2(String p0, String p1, String p2) {
    return '$p0\n達成率$p1%\nでらっくスコア$p2';
  }

  @override
  String get flowChartLimit => '譜面の上限';

  @override
  String get flowDeleteThisDataPoint2 => 'この記録点を削除';

  @override
  String get flowPlayerBriefProfile => 'プレイヤーの簡易プロフィール';

  @override
  String get flowBriefProfileUnavailable => '簡易プロフィールを取得できません';

  @override
  String get flowLoadingBriefProfile => '簡易プロフィールを読み込み中…';

  @override
  String get flowNoBackgroundSet => '背景未設定';

  @override
  String get flowLoadingBackground => '背景を読み込み中';

  @override
  String get flowBackgroundUnavailable => '背景を表示できません';

  @override
  String get flowNoNameplateSet => 'ネームプレート未設定';

  @override
  String get flowLoadingNameplate => 'ネームプレートを読み込み中';

  @override
  String get flowNameplateUnavailable => 'ネームプレートを表示できません';

  @override
  String flowTitleP0(String p0) {
    return '称号 #$p0';
  }

  @override
  String get flowNotAttempted => '未挑戦';

  @override
  String get flowRedPass => '赤合格';

  @override
  String get flowEnterAValidTotalAchievement => '有効な合計達成率を入力してください';

  @override
  String get flowTotalAchievementMustBeBetween0And => '合計達成率は0～404%で入力してください';

  @override
  String get flowTotalAchievementSupportsUpToFourDecimal =>
      '合計達成率は小数第4位まで入力できます';

  @override
  String get flowTotal2 => '合計';

  @override
  String get flowByLevel => 'レベル別';

  @override
  String get flowByConstant => '定数別';

  @override
  String get flowRegression => '低下';

  @override
  String get flowChange2 => '変化';

  @override
  String get flowClosePlaybackModeSelection => '再生モードの選択を閉じる';

  @override
  String get flowSequential => '順番に再生';

  @override
  String get flowShuffle => 'シャッフル';

  @override
  String get flowRepeatOne => '1曲リピート';

  @override
  String get flowTranslationIsUnavailableTryAgainLater =>
      '現在翻訳できません。後でもう一度お試しください。';

  @override
  String get flowTranslationFailedTryAgainLater => '翻訳に失敗しました。後でもう一度お試しください。';

  @override
  String get flowNumberOfEntries => '追加回数';

  @override
  String flowSourceP02(String p0) {
    return '取得元 $p0';
  }

  @override
  String flowGeneratedByChiffonMaiCommunityGroupP0(String p0) {
    return 'Generated by ChiffonMai・交流グループ$p0';
  }

  @override
  String get flowExportSuccessful => '書き出しました';

  @override
  String get flowExported => '書き出し済み';

  @override
  String get flow50Rows1Column => '50行1列';

  @override
  String get flow1Row50Columns => '1行50列';

  @override
  String get flowZoomOut => '縮小';

  @override
  String get flowZoomIn => '拡大';

  @override
  String get flowFitToWindow => 'ウィンドウに合わせる';

  @override
  String get flowMustBeGreaterThan0 => '0より大きい値にしてください';

  @override
  String flowMustNotExceedP0P1(String p0, String p1) {
    return '$p0$p1以下にしてください';
  }

  @override
  String flowLimitP0P1(String p0, String p1) {
    return '上限$p0（$p1）';
  }

  @override
  String flowRatingP0Best35P1Best15P2Average(
      String p0, String p1, String p2, String p3, String p4) {
    return 'Rating $p0\nBest35 $p1・Best15 $p2\n平均達成率$p3%\n平均でらっくスコア率$p4%';
  }

  @override
  String get flowTheoreticalBest35HighestConstantsFromOlderVersions =>
      '理論Best35・旧バージョンの最高定数';

  @override
  String get flowBest35BestScoresFromOlderVersions => 'Best35・旧バージョンのベスト成績';

  @override
  String get flowTheoreticalBest15HighestConstantsFromThisVersion =>
      '理論Best15・現バージョンの最高定数';

  @override
  String get flowBest15BestScoresFromThisVersion => 'Best15・現バージョンのベスト成績';

  @override
  String flowAverageP02(String p0) {
    return '平均$p0';
  }

  @override
  String flowFittedRatingP0AverageRatingP1Average(
      String p0, String p1, String p2, String p3) {
    return '推定Rating $p0\n平均Rating $p1\n平均達成率$p2%\n平均でらっくスコア率$p3%';
  }

  @override
  String get flowBest50BasedOnFittedConstants => '推定定数に基づくBest50';

  @override
  String flowP0ChartsTotalRatingP1AverageDX(String p0, String p1, String p2) {
    return '計$p0譜面\n合計Rating $p1\n平均でらっくスコア率$p2%';
  }

  @override
  String flowAverageRAP0(String p0) {
    return '平均RA $p0';
  }

  @override
  String flowFittedRatingP0VsThisTagS(
      String p0, String p1, String p2, String p3, String p4, String p5) {
    return '推定Rating $p0（このタグのBest50比$p1$p2）\n平均Rating $p3\n平均達成率$p4%\n平均でらっくスコア率$p5%';
  }

  @override
  String get flowChartType => '譜面タイプ';

  @override
  String get flowReferenceDuration => '参考時間';

  @override
  String get flowNOTECountsAndTotalNotes => 'NOTE数と総ノーツ数';

  @override
  String get flowBREAKCounts => 'BREAK数';

  @override
  String get flowTotalNotes => '総ノーツ数';

  @override
  String get flowOfficialConstant => '公式定数';

  @override
  String get flowFittedConstant => '推定定数';

  @override
  String get flowTotal3 => '合計';

  @override
  String get flowRequestingStoragePermission => 'ストレージ権限を確認中…';

  @override
  String get flowBuildingExportContent => '書き出し内容を構築中…';

  @override
  String get flowPreloadingImages => '画像を事前読み込み中…';

  @override
  String get flowRenderingExportContent => '書き出し内容を描画中…';

  @override
  String get flowGeneratingImage => '画像を生成中…';

  @override
  String get flowSavingImage => '画像を保存中…';

  @override
  String get flowExportComplete => '書き出し完了';

  @override
  String get flowBPMRange => 'BPM範囲';

  @override
  String get flowBaseBPM => '基準BPM';

  @override
  String get flowSOrLower => 'S+以下';

  @override
  String get flowNoCombo => 'コンボなし';

  @override
  String get flowNoSync => 'シンクなし';

  @override
  String flowCouldNotLoadDataP0(String p0) {
    return 'データを読み込めませんでした：$p0';
  }

  @override
  String get flowUncategorized => '未分類';

  @override
  String get flowNarrowPass50 => 'ぎりぎり達成50';

  @override
  String get flowJustShort50 => '寸止め50';

  @override
  String get flowNarrowSSS50 => 'ぎりぎりSSS+50';

  @override
  String get flowJustShortOfSSS50 => 'SSS+寸止め50';

  @override
  String get flowNarrowSSS502 => 'ぎりぎりSSS50';

  @override
  String get flowJustShortOfSSS502 => 'SSS寸止め50';

  @override
  String get flowChartDesigner50 => '譜面制作者50';

  @override
  String get flowGenre50 => 'ジャンル50';

  @override
  String get flowVersion50 => 'バージョン50';

  @override
  String get flowStar50 => 'スター50';

  @override
  String get flowTag50 => 'タグ50';

  @override
  String get flowRandom50 => 'ランダム50';

  @override
  String get flowOverreach50 => '背伸び50';

  @override
  String get flowDifficulty50 => '難易度50';

  @override
  String get flowDan => '段位';

  @override
  String get flowTrueDan => '真段位';

  @override
  String get flowOverallRanking => '総合ランキング';

  @override
  String get flowStarBonus => 'スターボーナス';

  @override
  String get flowToNextStar => '次のスターまで';

  @override
  String get flowPNGLossless => 'PNG可逆圧縮';

  @override
  String get flowOriginalQuality => '元の画質';

  @override
  String get flowClearImageSmallerFile => '鮮明でファイルサイズを抑える';

  @override
  String get flowGoodForSharing => '共有に最適';

  @override
  String get flowSmallestFile => '最小サイズ';

  @override
  String get detailChartBpm => '譜面';

  @override
  String get bestDisplayCover => '画像';

  @override
  String get bestDisplayTwoColumns => '2列';

  @override
  String get bestDisplayOneColumn => '1列';

  @override
  String rankingServiceUnavailable(String code) {
    return 'ランキングサービスを利用できません（$code）';
  }

  @override
  String get rankingInvalidResponse => 'ランキングの応答形式が正しくありません';

  @override
  String get ratingFetchFailed => '評価情報を取得できませんでした';

  @override
  String commentPostHttpFailed(String code) {
    return 'コメントを投稿できませんでした（$code）';
  }

  @override
  String commentDeleteHttpFailed(String code) {
    return 'コメントを削除できませんでした（$code）';
  }

  @override
  String get unknownDataSource => '不明な取得元';

  @override
  String get exportBlackTheme => '黒';

  @override
  String get songTabHistory => '履歴';

  @override
  String get songTabCommunity => '交流';

  @override
  String get flowUnknown => '不明';

  @override
  String get flowChooseDownloadMethod => 'ダウンロード方法を選択';

  @override
  String get flowDownloadInBrowser => 'ブラウザでダウンロード';

  @override
  String get flowOpenDownloadPage => 'ダウンロードページを開く';

  @override
  String get flowDownloadInApp => 'アプリ内でダウンロード';

  @override
  String get flowDownloadInTheBackgroundWhileYouKeep =>
      'アプリを使いながらバックグラウンドでダウンロード';

  @override
  String get flowChooseDownloadRoute => 'ダウンロード経路を選択';

  @override
  String get flowCouldNotConnectToTheServerCheck =>
      'サーバーに接続できません。接続を確認して再試行してください。';

  @override
  String get flowYouAreUpToDate => '最新バージョンです';

  @override
  String flowCurrentVersionP0BuildP1(String p0, String p1) {
    return '現在のバージョン：$p0（ビルド：$p1）';
  }

  @override
  String flowLatestVersionP0BuildP1(String p0, String p1) {
    return '最新バージョン：$p0（ビルド：$p1）';
  }

  @override
  String flowLatestChangesP0(String p0) {
    return '最新の更新内容：\n$p0';
  }

  @override
  String get flowHideFor3Days => '3日間表示しない';

  @override
  String get flowDownloadNow => '今すぐダウンロード';

  @override
  String flowCouldNotOpenLinkP0(String p0) {
    return 'リンクを開けませんでした：$p0';
  }

  @override
  String get flowEmailAddressCopied => 'メールアドレスをコピーしました';

  @override
  String get flowCreationAndSupport => '制作と支援';

  @override
  String get flowSupporterAcknowledgments => '支援者への謝辞';

  @override
  String get flowDataAndServices => 'データとサービス';

  @override
  String get flowDesignInspiration => 'デザインの参考';

  @override
  String get flowThankYouForEveryContributionThatHelps =>
      'ChiffonMaiの成長を支えてくださる皆様に感謝します。';

  @override
  String get flowHereForEveryMaimaiVisit => 'maimaiを遊ぶ毎日のお供に';

  @override
  String get flowReadingVersion => 'バージョンを読み込み中…';

  @override
  String flowVersionP02(String p0) {
    return 'バージョン$p0';
  }

  @override
  String get flowAppRegistrationICP20240152563A =>
      'アプリ登録番号：津ICP备2024015256号-3A';

  @override
  String get flowDevelopmentAndMaintenance => '開発と保守';

  @override
  String get flowInputError => '入力エラー';

  @override
  String get flowTargetAchievement => '目標達成率';

  @override
  String get flowEG1005000 => '例：100.5000';

  @override
  String get flowJudgmentDetails => '判定の内訳';

  @override
  String get flowForBREAKEnterTheMainJudgmentCounts =>
      'BREAKは大分類の判定数のみ入力します。50落ち・100落ちとGREATの内訳は逆算します。';

  @override
  String get flowCalculating2 => '計算中…';

  @override
  String get flowCalculateBREAKDetails => 'BREAKの内訳を計算';

  @override
  String get flowSolutionFoundError00001 => '解が見つかりました（誤差≤0.0001%）';

  @override
  String get flowNoExactSolutionShowingTheClosestResult =>
      '完全一致の解がないため、最も近い結果を表示します';

  @override
  String flowTargetP0BaseP1ExtraP2(String p0, String p1, String p2) {
    return '目標$p0%・基礎$p1%・追加$p2%';
  }

  @override
  String flowTotalAchievementP0P1P2(String p0, String p1, String p2) {
    return '合計達成率$p0%・$p1 $p2%';
  }

  @override
  String get flowError2 => '誤差';

  @override
  String get flowMinimumError => '最小誤差';

  @override
  String get flowJudgmentLossPerNote => '1ノーツの判定損失';

  @override
  String flowP0BREAKsBaseBonusScoreRatiosBelow(String p0) {
    return 'BREAK計$p0個・各行の下に基礎点／ボーナス点の割合を表示';
  }

  @override
  String flowP0P1NotesRedValuesShowAchievement(String p0, String p1) {
    return '$p0 計$p1個・赤字はその判定で失う達成率';
  }

  @override
  String get flowViewPerNoteLoss => '1ノーツの損失を見る';

  @override
  String get flowLiveAchievement => 'リアルタイム達成率';

  @override
  String get flowEnterJudgmentCountsBelowToCalculateAutomatically =>
      '各判定の個数を入力すると自動で計算します';

  @override
  String flowTotalAchievementP0GradeP1(String p0, String p1) {
    return '合計達成率$p0%、ランク$p1';
  }

  @override
  String flowBaseP0BonusP1(String p0, String p1) {
    return '基礎$p0%・ボーナス$p1%';
  }

  @override
  String get flowAlreadyAtTheHighestGradeSSS => '最高ランクのSSS+に到達済み';

  @override
  String flowP2NeededForP0P1(String p0, String p1, String p2) {
    return '$p0（$p1%）まであと$p2%';
  }

  @override
  String get flowAlternatingPlayRestSegmentsLetTheWheel =>
      '遊ぶ・休むを交互に並べたルーレットで、今日のゲーセン行きを決めましょう。';

  @override
  String get flowSegments => '区画数';

  @override
  String get flowFewerSegments => '区画を減らす';

  @override
  String get flowMoreSegments => '区画を増やす';

  @override
  String get flow20ByDefaultUpTo100Changes =>
      '初期値は20、最大100区画。交互の配置を保つため2区画ずつ変更します。';

  @override
  String get flowSpinning => '回転中…';

  @override
  String get flowStartWhenYouAreReady => '準備ができたら始めましょう';

  @override
  String flowThisSpinP0(String p0) {
    return '今回：$p0';
  }

  @override
  String get flowSpin => '回す';

  @override
  String get flowError3 => '誤差＋';

  @override
  String get flowEG5 => '例：5';

  @override
  String get flowNoMatchingResults => '条件に合う結果がありません';

  @override
  String get flowBREAKDistributionCalculator => 'BREAK分布の計算';

  @override
  String get flowTAPGREATAllowance => ' TAP GREATの許容数';

  @override
  String get flowUserData => 'ユーザーデータ';

  @override
  String flowP0TAPGREATs(String p0) {
    return 'TAP GREAT $p0個';
  }

  @override
  String get flowTodaySRecommendations => '今日のおすすめ';

  @override
  String get flowPreparingTodaySRecommendations => '今日のおすすめを準備中…';

  @override
  String get flowAnotherBatch => '別の候補';

  @override
  String get flowPickingTodaySRecommendations => '今日のおすすめを選択中…';

  @override
  String get flowNoChartsToRecommendYetRefreshData =>
      'おすすめの譜面がありません。\n先にホームでデータを更新してください。';

  @override
  String get flowBackupsExportFavoritesChartNotesAccountProfiles =>
      'お気に入り・譜面メモ・アカウント情報・設定・曲当て統計・成績とRatingの履歴・カスタム背景・保存済みローカル譜面パッケージをJSONに書き出します。\n\nログイン情報・個人キー・自動同期の認証情報は含まれず、新しい端末で再認証が必要です。楽曲データ・maidata・音源・PV・ランキングなど再取得できるキャッシュも含みません。\n\n旧形式のバックアップにも対応しますが、当時含まれていた設定・データのみ復元できます。ファイル上限は50 MBです。';

  @override
  String get flowExportBackup => 'バックアップを書き出す';

  @override
  String get flowExportLocalDataAsAJSONFile => 'ローカルデータをJSONファイルに書き出す';

  @override
  String flowExportedToP0(String p0) {
    return '書き出し先：$p0';
  }

  @override
  String get flowImportBackup => 'バックアップを読み込む';

  @override
  String get flowRestoreDataFromAJSONBackup => 'JSONバックアップからデータを復元';

  @override
  String get flowChooseWhereToSaveTheBackup => 'バックアップの保存先を選択';

  @override
  String get flowExportCancelled => '書き出しをキャンセルしました';

  @override
  String get flowConfirmRestore => '復元の確認';

  @override
  String get flowRestoringOverwritesCurrentLocalSettingsAndProfiles =>
      '復元すると現在のローカル設定とユーザー情報を上書きします。v3ではユーザーファイルも復元します。旧形式は元々含まれている内容のみ復元します。先に現在のバックアップを書き出すことをおすすめします。';

  @override
  String flowBackupVersionVP0(String p0) {
    return 'バックアップのバージョン：v$p0';
  }

  @override
  String flowExportedP0(String p0) {
    return '書き出し日時：$p0';
  }

  @override
  String flowContainsP0DataItems(String p0) {
    return '$p0件のデータを含みます';
  }

  @override
  String flowUserFilesP0(String p0) {
    return 'ユーザーファイル：$p0件';
  }

  @override
  String flowExcludedP0CacheItems(String p0) {
    return 'キャッシュ$p0件を除外';
  }

  @override
  String get flowSongMaidataAndLeaderboardCachesAreExcluded =>
      '楽曲・maidata・ランキングなどのキャッシュは含まれず、復元後に必要に応じて再取得します。初回の読み込みは遅くなる場合があります。ログイン情報は復元しません。';

  @override
  String get flowThisCannotBeUndoneContinue => 'この操作は取り消せません。続行しますか？';

  @override
  String get flowRestore => '復元';

  @override
  String flowRestoredP0SettingsAndP1UserFiles(String p0, String p1) {
    return '設定$p0件とユーザーファイル$p1件を復元しました。\nすべての変更を反映するにはアプリを再起動してください。';
  }

  @override
  String flowImportFailedP02(String p0) {
    return '読み込みに失敗しました：$p0';
  }

  @override
  String get flowMinimumConstant => '最低定数';

  @override
  String get flowMaximumConstant => '最高定数';

  @override
  String get flowNoRecommendationsCheckTheConstantRange =>
      'おすすめがありません。定数の範囲を確認してください。';

  @override
  String get flowRenameFavoritesFolder => 'お気に入りフォルダの名前を変更';

  @override
  String get flowEnterANewName => '新しい名前を入力してください';

  @override
  String get flowDeleteFavoritesFolder => 'お気に入りフォルダを削除';

  @override
  String flowDeleteP0ChartsWillRemainButWill(String p0) {
    return '「$p0」を削除しますか？\n譜面は削除されませんが、グループから外れます。';
  }

  @override
  String flowDeletedP0(String p0) {
    return '「$p0」を削除しました';
  }

  @override
  String get flowImportFavorites => 'お気に入りを読み込む';

  @override
  String get flowAddChartsToFavoritesFoldersFromSong =>
      '楽曲詳細から譜面をお気に入りフォルダに追加できます';

  @override
  String flowOrUseImportFavoritesAboveP0(String p0) {
    return 'または上の「お気に入りを読み込む」から、$p0';
  }

  @override
  String get flowRemoveChart => '譜面を削除';

  @override
  String flowRemoveP1FromP0(String p0, String p1) {
    return '「$p0」から「$p1」を削除しますか？';
  }

  @override
  String get flowRemove => '削除';

  @override
  String get flowRemoved => '削除しました';

  @override
  String get flowSortOrder => '並び順';

  @override
  String get flowExportFavorites => 'お気に入りを書き出す';

  @override
  String get flowFavoritesFolderIsEmpty => 'お気に入りフォルダは空です';

  @override
  String get flowRemoveFromFavoritesFolder => 'お気に入りフォルダから削除';

  @override
  String flowP0Selected(String p0) {
    return '$p0件選択中';
  }

  @override
  String get flowMove => '移動';

  @override
  String get flowRemoveMultipleCharts => '譜面をまとめて削除';

  @override
  String flowRemoveP1ChartsFromP0(String p0, String p1) {
    return '「$p0」から$p1譜面を削除しますか？';
  }

  @override
  String flowRemovedP0Charts(String p0) {
    return '$p0譜面を削除しました';
  }

  @override
  String get flowNoOtherFoldersToMoveTo => '移動先のフォルダがありません';

  @override
  String get flowMoveTo => '移動先…';

  @override
  String flowMovedP0Charts(String p0) {
    return '$p0譜面を移動しました';
  }

  @override
  String get flowThisFolderIsEmptyThereAreNo => 'このフォルダは空のため、書き出す譜面がありません。';

  @override
  String get flowChooseWhereToExportFavorites => 'お気に入りの書き出し先を選択';

  @override
  String flowExportedP02(String p0) {
    return '$p0を書き出しました';
  }

  @override
  String get flowImportItInTheAppOrOpen =>
      'アプリの「お気に入りを読み込む」、またはファイル管理アプリでこのファイルを開くと直接読み込めます。';

  @override
  String get flowFileSavedTo => 'ファイルの保存先：';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved =>
      '公開フォルダに書き込めないため、アプリの専用フォルダに保存しました。ファイル管理アプリから見えない場合があります。';

  @override
  String get flowInvalidLink => '無効なリンク';

  @override
  String get flowCouldNotOpenABrowserLinkCopied3 =>
      'ブラウザを開けませんでした。リンクをコピーしました。';

  @override
  String get flowRelatedCommunityProjectsTapACardTo =>
      '関連するコミュニティのプロジェクトです。カードをタップするとブラウザで開きます。';

  @override
  String flowSkippedP0ForThisSession(String p0) {
    return '今回のみ$p0をスキップしました';
  }

  @override
  String flowCouldNotSaveFeedbackP0(String p0) {
    return 'フィードバックを保存できませんでした：$p0';
  }

  @override
  String flowStoppedRecommendingP0UndoInFeedbackManagement(String p0) {
    return '$p0のおすすめを停止しました（フィードバック管理で解除できます）';
  }

  @override
  String flowPausedRecommendationsForP0For14Days(String p0) {
    return '$p0のおすすめを14日間停止しました';
  }

  @override
  String get flowUndo => '元に戻す';

  @override
  String get flowManageFeedback => 'フィードバック管理';

  @override
  String get flowNoChartsCanDirectlyRaiseYourRating =>
      '今すぐRatingを上げられる譜面がありません。\n成績を更新してから確認してください。';

  @override
  String get flowNoUnseenCandidatesMatchStartOverOr =>
      '条件に合う未表示の候補がありません。\n最初からやり直すか、フィードバック管理で除外を解除してください。';

  @override
  String get flowTotalGainIfAllTargetsOnThis =>
      'このページの目標をすべて達成した場合の合計（B50を順に再計算し、入れ替わりを考慮）';

  @override
  String flowBatchP0P1EntriesEachGainIs(String p0, String p1) {
    return '第$p0組・$p1件（各増分は独立しており、そのまま合計できません）';
  }

  @override
  String get flowStartOver => '最初から';

  @override
  String get flowNoMore => 'これ以上ありません';

  @override
  String get flowCurrentB50 => '現在のB50';

  @override
  String flowB35CutoffP0(String p0) {
    return 'B35・下限$p0';
  }

  @override
  String flowB15CutoffP0(String p0) {
    return 'B15・下限$p0';
  }

  @override
  String flowCountedB35P0P1B15P2P3(String p0, String p1, String p2, String p3) {
    return '集計済み：B35 $p0/$p1・B15 $p2/$p3';
  }

  @override
  String get flowNetGain => '純増';

  @override
  String get flowFeedback => 'フィードバック';

  @override
  String get flowSkipThisTime => '今回はスキップ';

  @override
  String get flowTemporarilyStuck14Days => '一時的に行き詰まり（14日間）';

  @override
  String get flowDislikeThisChart => 'この譜面は好みではない';

  @override
  String flowNoScoreRecordedReferenceTargetP0(String p0) {
    return '記録なし→参考目標$p0%';
  }

  @override
  String flowP0P1GainP2(String p0, String p1, String p2) {
    return '$p0% → $p1%（上昇$p2%）';
  }

  @override
  String get flowSteadyTargetImprovement020Challenge0 =>
      '堅実＝目標上昇幅≤0.20%、挑戦＝≤0.80%、探索＝成績未記録で、同定数の自己成績中央値から推定。「堅実」は差が小さいことを示し、成功率ではありません。\nローカルの成績キャッシュに基づき、データ更新後に結果も変わります。';

  @override
  String get flowRatingGainRecommendationsPoweredByAWMC =>
      'Rating向上おすすめアルゴリズム：AWMC提供';

  @override
  String get flowUndoingDoesNotInsertChartsBackInto =>
      '解除した譜面は現在の組には戻りません。次の組や最初からやり直した際に再び表示されます。';

  @override
  String get flowNoFeedbackYet => 'フィードバックがありません';

  @override
  String get flowDislikedUntilUndone => '好みではない・解除まで';

  @override
  String flowTemporarilyStuckClearsAutomaticallyOnP0(String p0) {
    return '一時停止・$p0に自動解除';
  }

  @override
  String flowP0ArcadesTapToExpand(String p0) {
    return '$p0店舗、タップで展開';
  }

  @override
  String get flowTurnOnDeviceLocationServicesFirst => '先に端末の位置情報サービスを有効にしてください';

  @override
  String get flowLocationPermissionIsPermanentlyDeniedEnableIt =>
      '位置情報の権限が拒否されています。システム設定で許可してください。';

  @override
  String get flowCouldNotGetYourLocationCheckThat =>
      '現在地を取得できません。位置情報サービスと受信状況を確認してください。';

  @override
  String flowLocationFailedP0(String p0) {
    return '位置情報の取得に失敗しました：$p0';
  }

  @override
  String get flowFiltered => '（絞り込み中）';

  @override
  String flowP0ArcadesInViewNearbyPointsGrouped(String p0) {
    return '表示範囲内$p0店舗（近い地点は自動で統合）';
  }

  @override
  String flowLastUpdatedP0(String p0) {
    return '最終更新：$p0';
  }

  @override
  String get flowSearchArcadeNameOrAddress => '店舗名や住所で検索';

  @override
  String get flowMachineFilters => '筐体の絞り込み';

  @override
  String get flowNoArcadeDataYet => '店舗データがありません';

  @override
  String get flowMachines => '🎮 筐体：';

  @override
  String get flowCouldNotOpenTheLinkTryAgain => 'リンクを開けませんでした。後でもう一度お試しください。';

  @override
  String get flowCouldNotLoadDocumentTapToRetry => '文書を読み込めません。タップして再試行。';

  @override
  String get flowSubmitALoadingQuote => '読み込みメッセージを投稿';

  @override
  String get flowAddALocalQuote => 'ローカルメッセージを追加';

  @override
  String get flowUploadFailedTryAgainLater => '送信できませんでした。後でもう一度お試しください。';

  @override
  String flowSubmittedForReviewP0ShownOnlyAfter(String p0) {
    return '審査に送信しました（$p0）。承認後に表示されます';
  }

  @override
  String get flowLocalQuoteAdded => 'ローカルメッセージを追加しました';

  @override
  String get flowCouldNotFetchLoadingQuotesKeptThe =>
      '読み込みメッセージを取得できませんでした。ローカルキャッシュを保持しました。';

  @override
  String get flowRefreshQuotes => 'メッセージを更新';

  @override
  String flowP0QuotesEnabled(String p0) {
    return '/ $p0件有効';
  }

  @override
  String get flowAddLocally => 'ローカルに追加';

  @override
  String get flowUploadToCloud => 'クラウドに投稿';

  @override
  String get flowDeleteLocalQuote => 'ローカルメッセージを削除';

  @override
  String get flowEnterALoadingQuote => '読み込みメッセージを入力';

  @override
  String get flowDataFromIsMaiDownByChongxi => 'データ提供：ChongxiのisMaiDown';

  @override
  String get flowServiceStatus => 'サービス状態';

  @override
  String get flowReadingServerStatus => 'サーバー状態を取得中…';

  @override
  String flowUpdatedP02(String p0) {
    return '更新日時：$p0';
  }

  @override
  String get flowDifficultyNotSpecified => '難易度未指定';

  @override
  String flowNoteP0(String p0) {
    return 'メモ：$p0';
  }

  @override
  String get flowRemoveThisEntry => 'この1件を削除';

  @override
  String get flowMeetChiffonMai => 'ChiffonMaiを知ろう';

  @override
  String get flowFiveTabsKeepEverythingWithinReach => '5つのタブから必要な機能を見つけられます。';

  @override
  String get flowRefreshDataThenStartExploring => 'データを更新してから始めましょう';

  @override
  String get flowARefreshPreparesSongsConstantsTagsAnd =>
      'データ更新で楽曲・定数・タグ・成績を準備します。\nログインせずに見ることもできます。';

  @override
  String get flowMakeItFeelLikeYourApp => '自分好みの使い心地に';

  @override
  String get flowFindTheseOptionsInMeSettingsAnd => '「マイページ」の設定からいつでも変更できます。';

  @override
  String get flowPhotosAndMedia => '写真とメディア';

  @override
  String get flowChooseCoverArtAndSaveExportedSong =>
      'ジャケットを選択し、書き出した楽曲情報や成績画像を保存します。';

  @override
  String get flowCamera => 'カメラ';

  @override
  String get flowCaptureCoverArtOrScoreImagesFor => 'ジャケットや成績を撮影して画像認識に使います。';

  @override
  String get flowLocation => '位置情報';

  @override
  String get flowUsedForLocationFeaturesOnTheGlobal => '世界のゲーセンマップで現在地を利用します。';

  @override
  String get flowNotifications => '通知';

  @override
  String get flowShowPlaybackControlsDuringBackgroundMusicPlayback =>
      'バックグラウンド再生中に通知プレイヤーを表示します。';

  @override
  String get flowCouldNotSaveConfirmationPleaseRetry =>
      '確認内容を保存できませんでした。再試行してください。';

  @override
  String get flowSeparateGuardianConsent => '保護者による個別の同意';

  @override
  String get flowPleaseHandTheDeviceToAGuardian =>
      '端末を保護者に渡してください。保護者は以下の文書を読み、処理する情報・利用目的・情報の照会や削除方法を確認してください。';

  @override
  String get flowIAmThisUserSGuardianI =>
      '私はこのユーザーの保護者です。利用規約とプライバシーポリシーを読み、同意し、機能の提供に必要な被保護者の個人情報の処理に同意します。';

  @override
  String get flowAfterConsentPermissionsAndFeaturesRemainOptional =>
      '同意後も権限や機能は必要に応じて選べます。プライバシーポリシーに従って同意の撤回や情報の削除も申請できます。';

  @override
  String get flowGuardianConsent => '保護者の同意';

  @override
  String get flowGoBackOnceMoreToExit => 'もう一度戻るとアプリを終了します';

  @override
  String get flowGettingStartedWithChiffonMai => 'ChiffonMaiをはじめる';

  @override
  String get flowPrevious3 => '前へ';

  @override
  String get flowStartExploring => '始める';

  @override
  String get flowNext3 => '次へ';

  @override
  String get flowWelcomeToChiffonMai => 'ChiffonMaiへようこそ';

  @override
  String get flowSongsChartsScoresAndUsefulToolsAll =>
      '楽曲・譜面・成績・便利なツールをひとつに。\nまずは1曲から、ゆっくり使ってみましょう。';

  @override
  String get flowAllSet => '準備完了！';

  @override
  String get flowStartExploringWithASong => 'さっそく楽曲を探してみましょう。';

  @override
  String flowCouldNotRequestPermissionP0(String p0) {
    return '権限をリクエストできませんでした：$p0';
  }

  @override
  String get flowAgreementsAndPermissions => '規約と権限';

  @override
  String get flowAgreeToTheDocumentsFirstYouCan =>
      '先に規約への同意が必要です。権限は今許可することも、機能の利用時に許可することもできます。';

  @override
  String get flowTheSystemManagesNetworkAccessBackgroundPlayback =>
      'ネットワーク・バックグラウンド再生・安全な保存はシステムが管理するため、ここで個別に許可する必要はありません。';

  @override
  String get flowIHaveReadAndAgreeTo => '読み、同意します：';

  @override
  String get flowUserAgreement => '利用規約';

  @override
  String get flowPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get flowToProvideTheGameServiceWeProcess =>
      'ゲームサービスの提供に必要なプレイ記録・楽曲成績・アカウントおよび端末の識別子などを処理します。マルチプレイでは、オンライン機能の維持に必要な対戦通信データをリアルタイムで送信します。';

  @override
  String get flowUsersUnder18ShouldUseTheApp =>
      '18歳未満の方は保護者の指導のもとで使用してください。14歳未満の方には保護者による個別の同意が必要です。';

  @override
  String get flowGuardianHasGivenSeparateConsent => '保護者が個別に同意済み';

  @override
  String get flowUnder14GuardianMustProvideConsent => '14歳未満：保護者による同意が必要';

  @override
  String flowP0SelectAllowFullAccessInThe(String p0) {
    return '$p0 システムの画面で「フルアクセスを許可」を選択してください。';
  }

  @override
  String get flowAccessIsCurrentlyLimitedChangeToAllow =>
      '現在はアクセスが制限されています。システム設定でフルアクセスを許可してください。';

  @override
  String get flowNotAuthorizedYetPermissionWillBeRequested =>
      'まだ許可されていません。対象機能の利用時に再度リクエストします。';

  @override
  String get flowOpenSettings => '設定を開く';

  @override
  String get flowAllow => '許可';

  @override
  String flowDrawFailedP0(String p0) {
    return '抽選に失敗しました：$p0';
  }

  @override
  String get flowNumberToDraw => '抽選数';

  @override
  String get flowPreparing => '準備中…';

  @override
  String get flowStop => 'ストップ！';

  @override
  String get flowStartDrawing => '抽選開始';

  @override
  String get flowDrawResults => '抽選結果';

  @override
  String flowP0SongsDrawn(String p0) {
    return '今回の抽選：$p0曲';
  }

  @override
  String get flowDrawHistory => '抽選履歴';

  @override
  String get flowNoHistoryYet2 => '履歴がありません';

  @override
  String get flowRecommendationRange => 'おすすめ範囲';

  @override
  String get flowPrioritizeChartsInRange => '範囲内の譜面を優先';

  @override
  String get flowRecalculateByTargetRating => '目標Ratingで再計算';

  @override
  String get flowRecalculateByConstantRange => '定数の範囲で再計算';

  @override
  String get flowCalculatingRecommendations => 'おすすめを計算中…';

  @override
  String get flowSongConstant => '楽曲定数';

  @override
  String get flowSongRating => '単曲Rating';

  @override
  String get flowMultiplier => '係数';

  @override
  String get flowEnterConstantAndAchievementToCalculateSong =>
      '定数と達成率を入力すると自動計算・単曲Rating＝定数×係数×達成率（切り捨て）';

  @override
  String get flowSongRatingConstantMultiplierAchievementRoundedDown =>
      '単曲Rating＝定数×係数×達成率（切り捨て）';

  @override
  String get flowEquivalentConstants => '等価定数の対応表';

  @override
  String flowEquivalentToP0(String p0) {
    return '$p0に相当';
  }

  @override
  String get flowMultiplierTable => '係数の対応表';

  @override
  String get flowUseTheMultiplierWhenAchievementMeetsThe =>
      '達成率が左列以上の場合に対応する係数を使用します。100.5%を超える値は100.5%として計算します。';

  @override
  String get flowAchievement4 => '達成率≥';

  @override
  String get flowChooseWhereToSaveTheSupportQR => '支援用QRコードの保存先を選択';

  @override
  String get flowSupportQRCodeSaved => '支援用QRコードを保存しました';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved2 =>
      '公開フォルダに書き込めないため、アプリの書類フォルダに保存しました。共有やアプリのファイル機能から取得できます。';

  @override
  String get flowChiffonMaiIsAFreeOpenSourceTool =>
      'ChiffonMaiは無料のオープンソースツールです。お役に立てましたら、開発をご支援いただけると嬉しいです！';

  @override
  String get flowWeChatSupportQRCode => 'WeChatの支援用QRコード';

  @override
  String get flowDownloadQRImage => 'QR画像をダウンロード';

  @override
  String get flowOrSupportMeOnAfdian => 'またはAfdianで支援';

  @override
  String get flowOpenAfdian => 'Afdianを開く';

  @override
  String get flowYourSupportKeepsDevelopmentAndMaintenanceGoing =>
      '皆様のご支援が、開発と保守を続ける励みになります。ありがとうございます！❤️';

  @override
  String get flowYouAlreadyGuessedThisSong => 'この楽曲はすでに回答済みです！';

  @override
  String get flowHowToPlay => 'ルール説明';

  @override
  String get flowGreenTheAttributeMatchesTheTargetExactly =>
      '緑：回答の属性が正解と完全に一致しています。';

  @override
  String get flowOrangeTheAttributeIsCloseToThe => 'オレンジ：回答の属性が正解に近い状態です：';

  @override
  String get flowBPMDiffersByNoMoreThan20 => 'BPMの差が±20以内';

  @override
  String get flowMASTEROrReMASTERDifficultyDiffersBy =>
      'MASTERまたはRe:MASTERの難易度差が±0.4以内';

  @override
  String get flowVersionsAreOneGenerationApartEG =>
      'バージョンが1世代違い（例：maimai ← maimai PLUS → maimai GreeN）';

  @override
  String get flowGrayTheAttributeIsFarFromThe => '灰色：回答の属性が正解から離れています。';

  @override
  String get flowArrows => '矢印：';

  @override
  String get flowTargetValueIsHigherThanYourGuess => '↑ 正解の値が回答より高い';

  @override
  String get flowTargetValueIsLowerThanYourGuess => '↓ 正解の値が回答より低い';

  @override
  String get flowDesignInspiration2 => 'デザインの参考：';

  @override
  String get flowCouldNotOpenThisLinkLinkCopied =>
      'リンクを開けませんでした。クリップボードにコピーしました。';

  @override
  String get flowNoSongsMatchTheseFiltersBroadenYour =>
      '条件に合う楽曲がありません。絞り込みを緩めてください。';

  @override
  String get flowGameSettings => 'ゲーム設定';

  @override
  String get flowAppliesFromTheNextGame => '次のゲームから適用';

  @override
  String get flowSettingsSavedTheyApplyFromTheNext => '設定を保存しました。次のゲームから適用します。';

  @override
  String get flowLoading5 => '読み込み中…';

  @override
  String get flowRules => 'ルール';

  @override
  String get flowSettings => '設定';

  @override
  String get flowNewQuestion => '別の問題';

  @override
  String get flowYouGotIt => '正解です！';

  @override
  String get flowThisGameSAnswer => '今回の正解';

  @override
  String get flowSearchTitleAliasIDAndMore => '曲名・別名・番号などで検索';

  @override
  String get flowModeSettings => 'このモードの設定';

  @override
  String get flowDestruction => '破壊度';

  @override
  String get flowBlur => 'ぼかし';

  @override
  String get flowCoverArtIsTurnedIntoAPixel =>
      '設定した破壊度でジャケットをモザイク化します。色の塊や輪郭から曲名を当ててください。0%は元画像で、値が高いほどピクセルが大きくなります。';

  @override
  String get flowTheOriginalCoverAppearsAfterACorrect =>
      '正解・降参・ラウンド終了後に元のジャケットを表示します。';

  @override
  String flowDestructionP0(String p0) {
    return '破壊度$p0%';
  }

  @override
  String get flowARandomSongIsChosenFromYour =>
      'キャッシュ済みの譜面からランダムに1曲選び、音のない譜面の一部を再生します。';

  @override
  String get flowWatchNoteDensityPatternsAndReachTo =>
      'ノーツの密度・配置・手の動きを見て楽曲を当ててください。';

  @override
  String flowYouMayReplayTheExcerptUpTo(String p0) {
    return 'この抜粋は最大$p0回まで再生し直せます。';
  }

  @override
  String get flowTags2 => 'タグ：';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor =>
      '回答した楽曲のMASTER譜面の配置・難易度・評価タグを表示します。';

  @override
  String get flowATagTurnsGreenWhenItMatches => '正解の属性と一致するタグは緑になります。';

  @override
  String get flowSomeSongsMayNotHaveTags => 'タグが付いていない楽曲もあります。';

  @override
  String get flowNoSongsMatchBroadenTheDifficultyPool =>
      '条件に合う楽曲がありません。難易度候補・定数範囲・絞り込みを緩めてください。';

  @override
  String get flowExcerptLength => '抜粋の長さ';

  @override
  String get flowNoChartsAvailableCacheMaidataInThe =>
      '利用できる譜面がありません。先に譜面ライブラリでmaidataをキャッシュしてください。';

  @override
  String get flowExcerptFinished => '抜粋の再生が終了しました';

  @override
  String get flowLoadingAudio2 => '音源を読み込み中…';

  @override
  String get flowReplayExcerptAudioUnavailable => '抜粋を再生（音源なし）';

  @override
  String get flowReplayExcerptWithAudio => '抜粋を音源付きで再生';

  @override
  String get flowReplayExcerpt => '抜粋を再生し直す';

  @override
  String get flowPlayExcerpt => '抜粋を再生';

  @override
  String flowReplayP0(String p0) {
    return '再生し直す$p0';
  }

  @override
  String get flowTheCoverFlashesBrieflyAtTheStart =>
      '開始時にジャケットが一瞬だけ表示され、その後消えます。表示時間は設定で変更できます。';

  @override
  String get flowRememberTheCoverThenSearchBelowAnd =>
      'ジャケットを覚え、下の検索から楽曲を当ててください。';

  @override
  String get flowFlashDuration => '表示時間';

  @override
  String get flowPlaybackLength => '再生時間';

  @override
  String flowAudioPlaybackFailedP0(String p0) {
    return '音源の再生に失敗しました：$p0';
  }

  @override
  String get flowTheCoverIsSplitIntoTilesAt =>
      'ジャケットを分割し、一定間隔でランダムな部分を公開します。公開済みの部分は残り、少しずつ全体が見えてきます。';

  @override
  String get flowEarlierGuessesImproveYourScoreAverageTime =>
      '早く当てるほど成績（平均時間）が良くなります。画像が見えやすくなるまで待つこともできます。';

  @override
  String get flowTileCount => '分割数';

  @override
  String get flowRevealInterval => '公開間隔';

  @override
  String flowP0RevealedP1P2Tiles(String p0, String p1, String p2) {
    return '$p0%公開済み（$p1 / $p2マス）';
  }

  @override
  String get flowRevealPaused => '公開を一時停止中';

  @override
  String flowNextRevealInP0S(String p0) {
    return '次の公開まで$p0秒';
  }

  @override
  String get flowResumeReveal => '公開を再開';

  @override
  String get flowPauseReveal => '公開を一時停止';

  @override
  String get flowCouldNotReloadSongsCheckYourConnection =>
      '楽曲を再取得できませんでした。接続を確認して再試行してください。';

  @override
  String get flowFetchingSongs => '楽曲を取得中…';

  @override
  String get flowReloadSongs => '楽曲を再取得';

  @override
  String get flowOpenSettings2 => '設定を開く';

  @override
  String get flowSettingsSavedLocally => '設定を端末に保存しました';

  @override
  String get flowChangesSaveAutomaticallyAndApplyToThe =>
      '変更は自動で保存し、次のゲームから適用します。';

  @override
  String get flowSongExcerptsReverseAndSpeedPitch => '楽曲の抜粋・逆再生・速度と音程';

  @override
  String get flowChartExcerpt => '譜面の抜粋';

  @override
  String get flowCoverModes => 'ジャケットのモード';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate =>
      '0%は元画像で、値が高いほどピクセルが大きくなります。';

  @override
  String get flowRevealLetters => '文字開き';

  @override
  String get flowDefaultSettingsRestored => '初期設定に戻しました';

  @override
  String get flowEnterOneCharacter => '1文字を入力してください！';

  @override
  String get flowEnterASongTitle => '曲名を入力してください！';

  @override
  String get flowCorrect => '正解！';

  @override
  String flowGuessP0(String p0) {
    return '回答 #$p0';
  }

  @override
  String flow1TheGameRandomlySelectsP0Songs(String p0) {
    return '1. maimaiの楽曲からランダムに$p0曲を選びます。';
  }

  @override
  String get flow2SendXWhereXIsOne =>
      '2. 「开字母 X」を送信します。Xには漢字・日本語・数字・記号など1文字を指定します。';

  @override
  String get flow3IfATitleContainsThatCharacter =>
      '3. 曲名にその文字が含まれていると、該当する位置を公開します。';

  @override
  String get flow4IfNoTitleContainsItNo => '4. 含まれていない場合はヒントが出ません。';

  @override
  String get flow5UseTheRevealedCharactersToInfer =>
      '5. 公開された文字から曲名を推測し、「回答 曲名/別名」で回答します。';

  @override
  String get flow6GuessEverySongOrSurrenderTo => '6. 全曲正解するか降参すると終了し、結果を表示します。';

  @override
  String get flowSongsPerGame => '1ゲームの曲数';

  @override
  String get flowNonEnglishCharacterFilterPercentage => '英字以外の文字を隠す割合';

  @override
  String get flowEnterOneCharacter2 => '1文字を入力';

  @override
  String get flowSurrender => '降参';

  @override
  String get flowNewGame => '新しいゲーム';

  @override
  String get flowGuessHistory => '回答履歴';

  @override
  String get flowBlueGateDetails => '青の扉の詳細';

  @override
  String get flowWhiteGateDetails => '白の扉の詳細';

  @override
  String get flowPurpleGateDetails => '紫の扉の詳細';

  @override
  String get flowBlackGateDetails => '黒の扉の詳細';

  @override
  String get flowYellowGateDetails => '黄の扉の詳細';

  @override
  String get flowRedGateDetails => '赤の扉の詳細';

  @override
  String get flowPrismTowerDetails => 'プリズムタワーの詳細';

  @override
  String get flowGlitchGateDetails => '文字化けの扉の詳細';

  @override
  String get flowHopeGateDetails => '希望の扉の詳細';

  @override
  String get flowFinalPhaseDetails => '最終相の詳細';

  @override
  String get flowNoActiveChallengesCheckTheScheduleBelow =>
      '開催中のチャレンジはありません。以下の日程をご確認ください。';

  @override
  String get flowCurrentPhase => '現在のフェーズ';

  @override
  String get flowLIFEPhase1Phase2 => 'LIFE 第1段階／第2段階';

  @override
  String get flowInProgress => '開催中';

  @override
  String flowPhase1P0(String p0) {
    return '第1段階 $p0';
  }

  @override
  String flowPhase2P0(String p0) {
    return '第2段階 $p0';
  }

  @override
  String flowMarkedP0P1(String p0, String p1) {
    return '記録済み$p0 / $p1';
  }

  @override
  String get flowTapASongToToggleCompletion => '楽曲をタップして達成状態を切替';

  @override
  String get flowEnableMarkingThenTapSongsToRecord =>
      '記録モードを有効にして楽曲をタップすると達成状態を記録できます';

  @override
  String get flowMarkingMode => '記録モード';

  @override
  String get flowCouldNotLoadTheGuideTryAgain =>
      '攻略情報を読み込めませんでした。後でもう一度お試しください。';

  @override
  String flowSongIDP02(String p0) {
    return '楽曲ID $p0';
  }

  @override
  String get flowRefreshTheLibraryToShowSongInformation =>
      '楽曲情報を表示するにはライブラリを更新してください';

  @override
  String get flowRefreshGateList => '扉の一覧を更新';

  @override
  String get flowEnterYourLXNSPersonalAPIKey => '落雪の個人APIキーを入力してください';

  @override
  String get flowLXNSAPIKeySaved => '落雪のAPIキーを保存しました';

  @override
  String get flowSavedLocallyItWillBeLinkedTo => '端末に保存しました。同期時にクラウドと自動で連携します';

  @override
  String get flowSetYourLXNSPersonalAPIKeyFirst => '先に落雪の個人APIキーを設定してください';

  @override
  String get flowHowDoIGetIt => '取得方法';

  @override
  String get flowThenScrollToTheBottomToFind =>
      'を開き、最下部までスクロールすると個人APIキーがあります。';

  @override
  String get flowLXNSAPIKeyIsSet => '落雪のAPIキーは設定済みです';

  @override
  String flowClosesAutomaticallyInP0S(String p0) {
    return '$p0秒後に自動で閉じます';
  }

  @override
  String flowP0GotItP1Points(String p0, String p1) {
    return '🎉 $p0さんが正解！＋$p1点';
  }

  @override
  String get flowNoConfirmationReceivedCheckYourConnectionAnd =>
      '確認応答がありません。接続を確認して再試行してください。';

  @override
  String get flowTimingStartsWhenTheRoundBeginsNot =>
      '計測は前の曲の正解時ではなく、ラウンド開始時からです。そのため、後の曲ほど記録時間が長くなります。';

  @override
  String get flowConfirmLeaving => '退出の確認';

  @override
  String get flowLeaveThisRoom => 'このルームから退出しますか？';

  @override
  String get flowLeave => '退出';

  @override
  String get flowNoConfirmationOfLeavingReceivedPleaseRetry =>
      '退出の確認応答がありません。再試行してください。';

  @override
  String flowCouldNotLeaveRoomP0(String p0) {
    return 'ルームから退出できませんでした：$p0';
  }

  @override
  String get flowRestoringGame => '対戦を復元中…';

  @override
  String get flowWaitingForTheGameToStart => 'ゲームの開始を待っています…';

  @override
  String get flowGameOver => 'ゲーム終了！';

  @override
  String get flowPlayAgain => 'もう一度';

  @override
  String get flowRoundOver => 'ラウンド終了！';

  @override
  String get flowNextRound2 => '次のラウンド';

  @override
  String get flowYouSurrenderedWaitingForOtherPlayers =>
      '降参しました。他のプレイヤーを待っています…';

  @override
  String flowTimeRemainingP0S(String p0) {
    return '⏱️ 残り時間：$p0秒';
  }

  @override
  String get flowWaitingForServerConfirmation => 'サーバーの確認を待っています…';

  @override
  String get flowTimeIsUpWaitingForRoundResults => '時間切れです。ラウンドの集計を待っています…';

  @override
  String get flowSearchSongIDBPMChartDesignerAnd => '曲名・ID・BPM・譜面制作者などで検索';

  @override
  String get flowTimeLeft => '残り時間';

  @override
  String get flowGuessesLeft => '残り回数';

  @override
  String flowP0Points(String p0) {
    return '$p0点';
  }

  @override
  String flowThisSongHasP0Aliases(String p0) {
    return 'この楽曲には$p0個の別名があります';
  }

  @override
  String get flowNoAliasesAvailableGuessFromTheSong =>
      '別名データがありません。楽曲情報から推測してください。';

  @override
  String get flowThisRoundHasEnded => 'このラウンドは終了しました';

  @override
  String flowP0P1SongsRemaining(String p0, String p1) {
    return '残り$p0 / $p1曲';
  }

  @override
  String get flowRevealed => '公開済み：';

  @override
  String get flowCharacters => '文字';

  @override
  String get flowPreparingCoverClue => 'ジャケットのヒントを準備中…';

  @override
  String get flowWaitingForPlayersToLoadTheCover => 'プレイヤーのジャケット読み込みを待っています…';

  @override
  String get flowFlashingRememberIt => '表示中…覚えてください！';

  @override
  String get flowTheCoverIsHiddenGuessFromMemory =>
      'ジャケットが消えました。記憶を頼りに回答してください。';

  @override
  String flowP0P1TilesRevealedP2(String p0, String p1, String p2) {
    return '$p0 / $p1マス公開済み$p2';
  }

  @override
  String get flowPaused2 => '（一時停止中）';

  @override
  String get flowPreparingChartExcerpt => '譜面の抜粋を準備中…';

  @override
  String get flowNoReplaysLeft => '再生し直せる回数が残っていません';

  @override
  String get flowGuessTheSongFromThisCoverFragment => 'ジャケットの一部から曲名を当ててください';

  @override
  String get flowOriginalCover => '元のジャケット';

  @override
  String flowBlurP0(String p0) {
    return 'ぼかし：$p0%';
  }

  @override
  String get flowSongExcerpt => '楽曲の抜粋';

  @override
  String get flowTheGameHasEnded => 'ゲームは終了しました';

  @override
  String get flowReplay => '再生し直す';

  @override
  String get flowPlaySongExcerpt => '楽曲の抜粋を再生';

  @override
  String get flowMultiplayerRoom => 'マルチプレイルーム';

  @override
  String flowP0RoundP1P2(String p0, String p1, String p2) {
    return '$p0・第$p1/$p2ラウンド';
  }

  @override
  String get flowReconnect => '再接続';

  @override
  String flowCouldNotCreateRoomP0(String p0) {
    return 'ルームを作成できませんでした：$p0';
  }

  @override
  String flowCouldNotJoinRoomP0(String p0) {
    return 'ルームに参加できませんでした：$p0';
  }

  @override
  String flowYouAreStillInRoomP0(String p0) {
    return 'ルーム$p0に参加中です';
  }

  @override
  String flowP0P1PlayersTapToReturn(String p0, String p1) {
    return '$p0・$p1人・タップして戻る';
  }

  @override
  String get flowCreateRoom => 'ルームを作成';

  @override
  String get flowChooseAModeAndRulesThenInvite => 'モードとルールを選び、フレンドを招待';

  @override
  String get flowJoinRoom => 'ルームに参加';

  @override
  String get flowEnterARoomCodeSharedByA => 'フレンドが共有したルームコードを入力';

  @override
  String get flowCouldNotCreateRoom => 'ルームを作成できませんでした';

  @override
  String flowCouldNotCreateRoomP02(String p0) {
    return 'ルームを作成できませんでした：$p0';
  }

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate2 =>
      '0%は元画像で、値が高いほどピクセルが大きくなります。ルーム内の全員に同じ破壊度を適用します。';

  @override
  String get flowSpeedPitchMultiplier => '速度・音程の倍率';

  @override
  String get flowRestoreDefaults => '初期設定に戻す';

  @override
  String get flowGameMode => 'ゲームモード';

  @override
  String get flowMaximumPlayers => '最大人数';

  @override
  String flowP0Settings(String p0) {
    return '$p0の設定';
  }

  @override
  String get flowEnterRoomCode => 'ルームコードを入力';

  @override
  String get flowEnterA6DigitCodeOrThe => '6桁のコード、または完全なルームIDを入力';

  @override
  String get flowPasteRoomCode => 'ルームコードを貼り付け';

  @override
  String get flowHowDoIGetARoomCode => 'ルームコードの取得方法';

  @override
  String get flowUpdateDownloadedInstallWhenConvenient =>
      '更新をダウンロードしました。都合のよい時にインストールできます。';

  @override
  String get flowViewInstallation => 'インストールを確認';

  @override
  String get flowView => '表示';

  @override
  String get flowPreparingTheUpdateInTheBackgroundYou =>
      'バックグラウンドで更新を準備中です。引き続きアプリを使えます。';

  @override
  String flowExportingP0InTheBackgroundYouCan(String p0) {
    return 'バックグラウンドで$p0を書き出し中です。他の操作を続けられます。';
  }

  @override
  String flowCouldNotExportP0PleaseRetry(String p0) {
    return '$p0を書き出せませんでした。再試行してください。';
  }

  @override
  String flowCouldNotExportP0CheckStoragePermission(String p0) {
    return '$p0を書き出せませんでした。ストレージ権限を確認して再試行してください。';
  }

  @override
  String flowP0Exported(String p0) {
    return '$p0を書き出しました';
  }

  @override
  String flowCouldNotExportP0P1(String p0, String p1) {
    return '$p0を書き出せませんでした：$p1';
  }

  @override
  String get flowCouldNotLoadAppearanceReopenThisPage =>
      '装飾を読み込めませんでした。このページを開き直してください。';

  @override
  String get flowChiffonMaiClosedUnexpectedlyLastTime =>
      '前回ChiffonMaiが予期せず終了しました';

  @override
  String flowReasonP0AutomaticLogExportFailedExport(String p0) {
    return '原因：$p0。\nログの自動書き出しに失敗しました。「マイページ→ログを書き出す」から手動で書き出せます。';
  }

  @override
  String get flowChiffonChuAnAllInOneCHUNITHMTool =>
      'CHUNITHM向けの総合ツール、ChiffonChu';

  @override
  String get flowWebMiniGamesFromTheAWMCCommunity =>
      'AWMCコミュニティが制作する、更新中のブラウザミニゲーム！';

  @override
  String get flowAnInnovativeRhythmGameInspiredByRailways =>
      '鉄道の要素を取り入れた新しいリズムゲーム';

  @override
  String get flowAnOfflineMaimaiLibraryWithQuickCover =>
      'ジャケットからすばやく検索できるオフラインmaimaiライブラリ';

  @override
  String flowRefusedRequestToANonGatewayAddress(String p0) {
    return 'ゲートウェイ以外へのリクエストを拒否しました：$p0';
  }

  @override
  String flowUnsupportedMethodP0(String p0) {
    return '未対応のメソッド：$p0';
  }

  @override
  String flowRequestTimedOutP0S(String p0) {
    return 'リクエストがタイムアウトしました（$p0秒）';
  }

  @override
  String flowCouldNotScheduleWriteP0(String p0) {
    return '書き込みを予約できませんでした：$p0';
  }

  @override
  String flowMusicListMustContain14EntriesCurrently(String p0) {
    return 'musicListの件数は1～4件にしてください（現在$p0件）';
  }

  @override
  String get flowOnlyChargeId235IsSupported =>
      'chargeIdは2・3・5のみ対応しています（2倍・3倍・5倍チケット）';

  @override
  String flowOrderP0(String p0) {
    return '並び順：$p0';
  }

  @override
  String flowSourceP0ExportedP1GeneratedByChiffonMai(
      String p0, String p1, String p2) {
    return '取得元：$p0\n書き出し日時：$p1\nGenerated by ChiffonMai\n交流グループ：$p2';
  }

  @override
  String get flowCouldNotCreateRoomEnvironmentIDIs => 'ルームを作成できません：環境IDが未設定です';

  @override
  String get flowCouldNotCreateRoomNotSignedIn => 'ルームを作成できません：ログインしていません';

  @override
  String flowCouldNotJoinRoomP02(String p0) {
    return 'ルームに参加できませんでした：$p0';
  }

  @override
  String flowCouldNotRejoinRoomP0(String p0) {
    return 'ルームに再参加できませんでした：$p0';
  }

  @override
  String flowCouldNotChangeReadyStatusP0(String p0) {
    return '準備状態を変更できませんでした：$p0';
  }

  @override
  String flowCouldNotChangeSurrenderStatusP0(String p0) {
    return '降参状態を変更できませんでした：$p0';
  }

  @override
  String flowCouldNotStartGameP0(String p0) {
    return 'ゲームを開始できませんでした：$p0';
  }

  @override
  String flowCouldNotStartNextRoundP0(String p0) {
    return '次のラウンドを開始できませんでした：$p0';
  }

  @override
  String flowCouldNotSubmitGuessP0(String p0) {
    return '回答を送信できませんでした：$p0';
  }

  @override
  String flowCouldNotRevealLetterP0(String p0) {
    return '文字を開けませんでした：$p0';
  }

  @override
  String flowCouldNotSurrenderP0(String p0) {
    return '降参できませんでした：$p0';
  }

  @override
  String flowCouldNotUploadSongsP0(String p0) {
    return '楽曲を送信できませんでした：$p0';
  }

  @override
  String flowCouldNotGetSongCountP0(String p0) {
    return '楽曲数を取得できませんでした：$p0';
  }

  @override
  String flowCouldNotParseMessageP0(String p0) {
    return 'メッセージを解析できませんでした：$p0';
  }

  @override
  String get flowYellow => '黄';

  @override
  String get flowCurrentSaveLocation => '現在の保存先';

  @override
  String get flowUseTheDefaultPublicDirectoryOrChoose =>
      '標準の公開フォルダを使うか、別のフォルダを選択できます。';

  @override
  String flowCouldNotChooseSaveFolderP0(String p0) {
    return '保存先を選択できませんでした：$p0';
  }

  @override
  String get flowChooseAnotherFolder => '別のフォルダを選択';

  @override
  String get flowUseDefaultPath => '標準のパスを使用';

  @override
  String get flowThisFolderIsNotWritableChooseAnother =>
      'このフォルダに書き込めません。別のフォルダを選択してください。';

  @override
  String get flowCannotImport => '読み込めません';

  @override
  String flowImportCompleteP0(String p0) {
    return '読み込み完了：$p0';
  }

  @override
  String flowP0FoldersP1Charts(String p0, String p1) {
    return 'フォルダ$p0個、譜面$p1個';
  }

  @override
  String flowP0P1Charts2(String p0, String p1) {
    return '・$p0（$p1譜面）';
  }

  @override
  String flowP0MoreFolders(String p0) {
    return '・ほか$p0フォルダ…';
  }

  @override
  String get flowMergeWithExistingFolders => '既存のフォルダに統合';

  @override
  String get flowFoldersWithTheSameNameAreMerged =>
      '同名のフォルダを統合し、重複する譜面はスキップします。';

  @override
  String get flowReplaceExistingFavorites => 'お気に入りを置き換え';

  @override
  String get flowClearAllCurrentFoldersThenImportThe =>
      '現在の全フォルダを消去してから、ファイルを読み込みます。';

  @override
  String get flowImport => '読み込む';

  @override
  String flowP0Loading(String p0) {
    return '$p0、読み込み中';
  }

  @override
  String get flowUnavailable => '利用できません';

  @override
  String get flowIncrease => '、増加';

  @override
  String get flowDecrease => '、減少';

  @override
  String flowP0P1P2BeijingTime(String p0, String p1, String p2) {
    return '$p0-$p1-$p2・北京時間';
  }

  @override
  String get flowDoNotShowThisAnnouncementAgain => 'このお知らせを今後表示しない';

  @override
  String get flowCouldNotLoadImageTapToRetry => '画像を読み込めません。タップして再試行。';

  @override
  String get flowEnlargeAnnouncementImage => 'お知らせの画像を拡大';

  @override
  String flowDecreaseP0ByOne(String p0) {
    return '$p0を1減らす';
  }

  @override
  String flowIncreaseP0ByOne(String p0) {
    return '$p0を1増やす';
  }

  @override
  String get flowInstallUpdate => '更新をインストール';

  @override
  String get flowDownloadUpdateInBackground => '更新をバックグラウンドでダウンロード';

  @override
  String get flowNoDownloadTask => 'ダウンロード中のタスクはありません';

  @override
  String get flowKeepUsingTheApp => 'アプリを使い続ける';

  @override
  String get flowCancelInstallationTask => 'インストールの予約を取り消す';

  @override
  String get flowCancelDownload => 'ダウンロードをキャンセル';

  @override
  String get flowDownloadAgain => '再ダウンロード';

  @override
  String get flowAllowInstallation => 'インストールを許可';

  @override
  String get flowInstallNow => '今すぐインストール';

  @override
  String get flowCalculatingCacheSize => 'キャッシュ容量を集計中…';

  @override
  String flowTotalUsageP0(String p0) {
    return '合計使用量$p0';
  }

  @override
  String get flowAudioCache => '音源キャッシュ';

  @override
  String get flowCalculating3 => '集計中…';

  @override
  String flowP0FilesTotalP1(String p0, String p1) {
    return '$p0ファイル\n合計$p1';
  }

  @override
  String get flowPVCache => 'PVキャッシュ';

  @override
  String get flowMaidataCache => 'maidataキャッシュ';

  @override
  String get flowReloadBaseMaidata => '基本maidataを再取得';

  @override
  String flowCleaningP0(String p0) {
    return '削除中…$p0%';
  }

  @override
  String get flowCleaning => '削除中…';

  @override
  String get flowClear2 => '削除';

  @override
  String flowNoteSpeedP0P1(String p0, String p1) {
    return 'ノーツ速度$p0・$p1';
  }

  @override
  String get flowNoteSpeed => 'ノーツ速度';

  @override
  String get flowMirror => 'ミラー';

  @override
  String get flowRandomDifficultyPool => '難易度の抽選候補';

  @override
  String flowP0ConstantP12(String p0, String p1) {
    return '$p0 定数$p1';
  }

  @override
  String get flowUTAGE2 => '宴会場';

  @override
  String get flowResetTodaySStatistics => '今日の統計をリセットしますか？';

  @override
  String get flowClearTodaySCorrectIncorrectGuessesTimes =>
      'このモードの今日の正解・不正解・時間・連続正解の記録を消去します。';

  @override
  String flowP0SRemaining(String p0) {
    return '残り$p0秒';
  }

  @override
  String get flowResetTodaySStatistics2 => '今日の統計をリセット';

  @override
  String get flowResetStatistics => '統計をリセット';

  @override
  String get flowThisGameHasEnded => 'このゲームは終了しました';

  @override
  String flowAnswerP0(String p0) {
    return '正解：$p0';
  }

  @override
  String get flowOriginalAudioExcerpt => '元の音源の抜粋';

  @override
  String get flowPreparingOriginalAudio => '元の音源を準備中…';

  @override
  String get flowTheSameExcerptPlayedForwardAtOriginal =>
      'このラウンドの同じ抜粋を、元の速度で順方向に再生';

  @override
  String get flowSelectAll2 => 'すべて選択';

  @override
  String get flowCurrentAll => '現在：すべて';

  @override
  String flowP0SelectedNoneMeansAll(String p0) {
    return '$p0件選択中、未選択ですべて対象';
  }

  @override
  String get flowMASTERTags => 'MASTERのタグ';

  @override
  String flowGuessHistoryP0(String p0) {
    return '回答履歴（$p0）';
  }

  @override
  String get flowOldestFirst => '古い順';

  @override
  String get flowNewestFirst => '新しい順';

  @override
  String get flowCouldNotOpenTheGuideSourceLink =>
      '攻略情報の出典を開けませんでした。リンクをコピーしました。';

  @override
  String get flowDataSourceAWMCKALEIDXSCOPE => 'データ提供：AWMC KALEIDXSCOPE';

  @override
  String get flowRoom => 'ルーム';

  @override
  String flowP0PlayersP1(String p0, String p1) {
    return '・$p0人・$p1';
  }

  @override
  String get flowCopyRoomCode => 'ルームコードをコピー';

  @override
  String get flowRoomCodeCopied => 'ルームコードをコピーしました';

  @override
  String get flowInviteFriendsToGuessSongsTogether => 'フレンドを招待して一緒に曲当て';

  @override
  String get flowRoomCode => 'ルームコード';

  @override
  String get flowRoomCodeCopiedSendItToA => 'ルームコードをコピーしました。フレンドに送ると参加できます。';

  @override
  String get flowPlayerSlots => 'プレイヤー枠';

  @override
  String flowP0P1PlayersP2(String p0, String p1, String p2) {
    return '$p0 / $p1人$p2';
  }

  @override
  String flowP0Ready(String p0) {
    return '・$p0人準備完了';
  }

  @override
  String get flowWaitingForPlayers => '参加を待っています';

  @override
  String get flowMe2 => '・自分';

  @override
  String get flowNotReady => '準備解除';

  @override
  String get flowReady => '準備完了';

  @override
  String get flowStartGame => 'ゲーム開始';

  @override
  String get flowDecreaseCount2 => '数を減らす';

  @override
  String get flowIncreaseCount2 => '数を増やす';

  @override
  String get flowConnectionRestored => '接続が復旧しました';

  @override
  String get flowOfflineShowingCachedData => 'オフライン・キャッシュデータを表示中';

  @override
  String flowDrawingP0SongsTapStopToReveal(String p0) {
    return '$p0曲を抽選中・「ストップ！」で結果を表示';
  }

  @override
  String flowCardP0WaitingToReveal(String p0) {
    return '$p0枚目、結果の表示待ち';
  }

  @override
  String get flowCyclingCoverArt => 'ジャケットを切り替え中…';

  @override
  String flowSongP0WaitingForYouToStop(String p0) {
    return '$p0曲目・ストップ待ち';
  }

  @override
  String get flowChiffonMaiIsAnAllInOneMobile =>
      'ChiffonMaiはmaimai DX 2026のプレイヤー向け総合モバイルツールです。楽曲検索・成績集計・Rating計算・楽曲のおすすめなどをまとめ、プレイをサポートします。';

  @override
  String get flowProvidedTheBackgroundArtworkAndTheLovely =>
      '背景画像と、とても可愛い戚風のキツネを提供';

  @override
  String get flowContributedValuableIdeasForPersonalizedChartRecommendations =>
      '条件別譜面おすすめ機能の設計に貴重なアイデアを提供';

  @override
  String get flowContributedValuableFeedbackOnPageDesign => 'ページデザインに貴重な意見を提供';

  @override
  String get flowProvidedPersonalPlayDataForDevelopmentAnd =>
      '開発・テスト用の個人プレイデータを提供';

  @override
  String get flowProposedChiffonMaiAndHelpedSparkTheProject =>
      'ChiffonMaiの開発を提案し、プロジェクト誕生のきっかけを提供';

  @override
  String get flowContributedManySuggestionsOnInterfaceDetailsAnd =>
      '画面の細部や操作体験に多くの貴重な提案を提供';

  @override
  String get flowProvidedTechnicalAndFinancialSupportThatGreatly =>
      '開発に技術・資金の支援を提供し、プロジェクトの進行に大きく貢献';

  @override
  String get flowEveryoneInTheChiffonMaiCommunityGroup => 'ChiffonMai交流グループの皆様';

  @override
  String get flowContributedManySuggestionsAndFeedbackDuringDevelopment =>
      '開発に多くの貴重な提案とフィードバックを提供';

  @override
  String get flowDivingFish => '水魚';

  @override
  String get flowProvidesSongAndPlayerScoreDatabases => '楽曲・プレイヤー成績データベースを提供';

  @override
  String get flowProvidesChartTagAndAliasDatabases => '譜面タグ・別名データベースを提供';

  @override
  String get flowProvidesAnAliasDatabase => '別名データベースを提供';

  @override
  String get flowLXNS => '落雪カフェ';

  @override
  String get flowProvidesCollectiblesAudioSongAndPlayerScore =>
      'コレクション・音源・楽曲・プレイヤー成績データを提供';

  @override
  String get flowProvidesChartConversionSupport => '譜面変換をサポート';

  @override
  String get flowProvidesMaimaiServerStatus => 'maimaiのサーバー状態を提供';

  @override
  String get flowProvidesDivingFishLXNSSyncAndFinancial =>
      '水魚・落雪への同期機能と開発資金を支援';

  @override
  String get flowProvidesScoreSyncToDivingFishAnd => '水魚・落雪への成績同期をサポート';

  @override
  String get flowProvidesScoreSyncToLXNS => '落雪への成績同期をサポート';

  @override
  String get flowProvidesASongDatabase => '楽曲データベースを提供';

  @override
  String get flowProvidesWorldwideArcadeData => '世界のゲーセン情報を提供';

  @override
  String get flowProvidesHighResolutionVersionArtwork => '高解像度のバージョン画像を提供';

  @override
  String get flowThankYouForYourDonations => 'ご寄付によるご支援に感謝します';

  @override
  String get flowMaintainer => '管理者';

  @override
  String get flowTheDeveloperBehindChiffonMai => 'ChiffonMaiを開発しています。';

  @override
  String get flowSpecialThanks => '謝辞';

  @override
  String get flowThanksToEveryoneWhoHelpedInNo => 'ご協力いただいた皆様に感謝します。順不同です。';

  @override
  String get flowBilibili => 'Bilibili';

  @override
  String get flowEmail => 'メール';

  @override
  String get flowSignInFailedTryAgainLater => 'ログインできませんでした。後でもう一度お試しください。';

  @override
  String get flowEnterTargetAchievement => '目標達成率を入力してください';

  @override
  String get flowInvalidAchievementEnterANumberSuchAs =>
      '達成率の形式が正しくありません。100.5000のような数値を入力してください。';

  @override
  String get flowEnterAchievementBetween0And101 => '達成率は0～101で入力してください';

  @override
  String get flow50PointLoss2 => '50落ち';

  @override
  String get flow100PointLoss2 => '100落ち';

  @override
  String get flowBase100Bonus100 => '基礎100%・ボーナス100%';

  @override
  String get flowPERFECT50PointLoss => 'PERFECT・50落ち';

  @override
  String get flowBase100Bonus75 => '基礎100%・ボーナス75%';

  @override
  String get flowPERFECT100PointLoss => 'PERFECT・100落ち';

  @override
  String get flowBase100Bonus50 => '基礎100%・ボーナス50%';

  @override
  String get flowBase80Bonus40 => '基礎80%・ボーナス40%';

  @override
  String get flowBase60Bonus40 => '基礎60%・ボーナス40%';

  @override
  String get flowBase50Bonus40 => '基礎50%・ボーナス40%';

  @override
  String get flowBase40Bonus30 => '基礎40%・ボーナス30%';

  @override
  String get flowBase0Bonus0 => '基礎0%・ボーナス0%';

  @override
  String get flowNoLoss => '損失なし';

  @override
  String get flowStayHome => '休む';

  @override
  String get flowScoreTargetsBREAKDistribution => '目標得点・BREAK分布';

  @override
  String get flowRatingTargets => '目標Rating';

  @override
  String get flowCalculationMode => '計算モード';

  @override
  String get flowByAchievement => '達成率から';

  @override
  String get flowByRating => 'Ratingから';

  @override
  String get flowResult2 => '計算結果';

  @override
  String get flowTargetRating2 => '目標Rating';

  @override
  String get flowEG143 => '例：14.3';

  @override
  String get flowEG1005667 => '例：100.5667';

  @override
  String get flowEG321 => '例：321';

  @override
  String flowAchievementP02(String p0) {
    return '達成率$p0';
  }

  @override
  String get flowNoteDistributionEditable => 'ノーツ分布（編集可）';

  @override
  String get flowScoreLossDetails => '得点・失点の内訳';

  @override
  String flowP0P1P2WeekdayP3(String p0, String p1, String p2, String p3) {
    return '$p0年$p1月$p2日 $p3曜日';
  }

  @override
  String get flowExporting3 => '書き出し中…';

  @override
  String get flowExportBackupFile => 'バックアップファイルを書き出す';

  @override
  String get flowRestoringData => 'データを復元中…';

  @override
  String get flowImporting => '読み込み中…';

  @override
  String get flowChooseBackupFile => 'バックアップファイルを選択';

  @override
  String get flowImportClearsAllCurrentLocalDataBefore =>
      '⚠ 読み込み前に現在のローカルデータをすべて消去してから復元します。\nバックアップにない項目やキャッシュも削除します。\n復元中はこのページを離れないでください。';

  @override
  String get flowBackupFile => 'バックアップファイル';

  @override
  String get flowFindTheFileInDownloadsChiffonMaiIn =>
      'ファイル管理アプリの「ダウンロード/ChiffonMai/备份」フォルダに保存しています。';

  @override
  String get flowThePublicDirectoryIsNotWritableSaved3 =>
      '公開フォルダに書き込めないため、アプリの書類フォルダに保存しました。';

  @override
  String get flowRename => '名前を変更';

  @override
  String get flowConstantHighLow => '定数（高い順）';

  @override
  String get flowConstantLowHigh => '定数（低い順）';

  @override
  String get flowAddedNewOld => '追加日時（新しい順）';

  @override
  String get flowAddedOldNew => '追加日時（古い順）';

  @override
  String get flowSongTitleAZ => '曲名（A–Z）';

  @override
  String get flowSignOut2 => 'ログアウト';

  @override
  String get flowGetAnImportTokenForScoreSync => '成績同期用のImportTokenを取得';

  @override
  String get flowOnlineLinksAreUnavailableShowingLocallyCached =>
      'オンラインのリンク一覧を取得できません。ローカルキャッシュを表示しています。';

  @override
  String flowCouldNotGenerateRecommendationsP0(String p0) {
    return 'おすすめを生成できませんでした：$p0';
  }

  @override
  String get flowMixed => '混合';

  @override
  String flowSourceRatingP0DiffersFromTheLocally(String p0) {
    return '取得元のRating $p0と端末での再計算結果が異なるため、再計算結果を使用します。';
  }

  @override
  String flowP0ScoresAreMissingFromTheSong(String p0) {
    return '$p0件の成績が楽曲データにないため旧曲として扱います。ライブラリ更新で精度が向上します。';
  }

  @override
  String flowP0P12(String p0, String p1) {
    return '$p0月$p1日';
  }

  @override
  String flowP0Arcades(String p0) {
    return '$p0店舗';
  }

  @override
  String flowP0ArcadesTotal(String p0) {
    return '計$p0店舗';
  }

  @override
  String get flowDivingFishSignInFailedTryAgain =>
      '水魚にログインできませんでした。後でもう一度お試しください。';

  @override
  String get flowUserAgreement2 => '利用規約';

  @override
  String get flowPrivacyPolicy2 => 'プライバシーポリシー';

  @override
  String flowLocalQuotesP0(String p0) {
    return 'ローカル $p0件';
  }

  @override
  String flowCloudQuotesP0(String p0) {
    return 'クラウド $p0件';
  }

  @override
  String get flowQuoteCannotBeEmpty => 'メッセージを入力してください';

  @override
  String get flowServerStatusIsTemporarilyUnavailable => '現在サーバー状態を取得できません';

  @override
  String get flowCouldNotLoadServerStatus => 'サーバー状態を読み込めませんでした';

  @override
  String get flowHealthy => '正常';

  @override
  String get flowUnhealthy => '異常';

  @override
  String get flowLatency => '遅延 --';

  @override
  String flowLatencyP0Ms(String p0) {
    return '遅延$p0 ms';
  }

  @override
  String flowHealthyP0(String p0) {
    return '正常$p0';
  }

  @override
  String flowIssuesP0(String p0) {
    return '異常$p0';
  }

  @override
  String get flowNoSongsAddedYetUseAddTo =>
      '楽曲がまだありません。\n楽曲詳細や音楽プレイヤーで「次に遊びたい曲に追加」を押してください。';

  @override
  String get flowProfileFavoriteFeaturesSyncAndServerStatus =>
      'プロフィール・よく使う機能・同期・サーバー状態';

  @override
  String get flowFindSongsInspectChartsAndBrowseCollectibles =>
      '楽曲・譜面・コレクションを探す';

  @override
  String get flowBest50RatingToolsAndLeaderboards => 'Best50・Rating向上ツール・ランキング';

  @override
  String get flowFindArcadesPlayGuessingGamesAndListen => 'ゲーセン探し・曲当て・音楽再生';

  @override
  String get flowAccountsDataRefreshAndSettings => 'アカウント・データ更新・各種設定';

  @override
  String get flowOpenFromMeOrTapYourRating => '「マイページ」、またはホームのRatingをタップ';

  @override
  String get flowSyncScores => '成績を同期';

  @override
  String get flowDivingFishLXNSAndAWMCNETLink =>
      '水魚・落雪・AWMC NETに対応。先にアカウント連携が必要';

  @override
  String get flowRunsThroughoutTheDayWhenEnabledCheck =>
      '有効にすると毎日時間を分けて処理し、ホームで結果を確認可能';

  @override
  String get flowTheme => 'テーマ';

  @override
  String get flowLightDarkBlackOrSystemThemePlus => 'ライト・ダーク・黒・システム連動とテーマ色の変更';

  @override
  String get flowCustomBackgroundImagesDecorationsAndOverlays =>
      '背景画像・装飾画像・オーバーレイの変更';

  @override
  String get flowNavigation => 'ナビゲーション';

  @override
  String get flowThreeNavigationStylesWithOptionalAnimationAnd =>
      '3種類のナビゲーション。アニメーションやスワイプ切替も設定可能';

  @override
  String get flowConfetti => '紙吹雪';

  @override
  String get flowCelebrateASuccessfulRefreshOrSyncWith => 'データ更新や同期の成功時に紙吹雪を表示';

  @override
  String get flowEverythingIsReadyRememberToRefreshData =>
      '準備ができましたね。最初にデータを更新してくださいね。';

  @override
  String get flowChecking => '確認中';

  @override
  String get flowAllowed => '許可済み';

  @override
  String get flowLimitedAccess => '制限付きアクセス';

  @override
  String get flowOpenSettings3 => '設定を開いてください';

  @override
  String get flowNotAllowed => '未許可';

  @override
  String get flowIHaveReadAndAgreeToThe => '利用規約とプライバシーポリシーを読み、同意します';

  @override
  String get flowChooseYourFiltersThenDrawSomeSongs => '条件を選んで楽曲を抽選しましょう';

  @override
  String get flowEnterAnIntegerFrom2To100 => '2～100の整数を入力してください';

  @override
  String get flowDrawCountMustBeBetween2And => '抽選数は2～100で指定してください';

  @override
  String get flowNoMatchingSongsAdjustTheFilters =>
      '条件に合う楽曲がありません。絞り込みを変更してください。';

  @override
  String get flowSongs3 => '曲';

  @override
  String get flowAllVersions => 'すべてのバージョン';

  @override
  String flowP0VersionsSelected(String p0) {
    return '$p0バージョン選択中';
  }

  @override
  String get flowTypeFilter => 'タイプで絞り込み';

  @override
  String get flowAllTypes => 'すべてのタイプ';

  @override
  String flowP0TypesSelected(String p0) {
    return '$p0タイプ選択中';
  }

  @override
  String get flowConstantRange => '定数の範囲';

  @override
  String get flowAdvancedMASTER => 'MASTER上級';

  @override
  String get flowExpertMASTER => 'MASTER超上級';

  @override
  String flowCouldNotFetchRecommendationsP0(String p0) {
    return 'おすすめを取得できませんでした：$p0';
  }

  @override
  String get flowConstantRange2 => '定数の範囲';

  @override
  String get flowSimilarity => '類似度';

  @override
  String flowCurrentP0TargetP1(String p0, String p1) {
    return '現在$p0% → 目標$p1%';
  }

  @override
  String flowEnterAValidP0(String p0) {
    return '有効な$p0を入力してください';
  }

  @override
  String flowP0MustBeBetweenP1AndP2(String p0, String p1, String p2) {
    return '$p0は$p1～$p2で入力してください';
  }

  @override
  String flowP1ForP0(String p0, String p1) {
    return '$p0の$p1';
  }

  @override
  String get flowMultiPlatformSync => '複数サービスへの同期';

  @override
  String get flowAdvancedDataRefresh => '高度なデータ更新';

  @override
  String get flowReadPlayCounts => 'プレイ回数の取得';

  @override
  String get flowSignOut3 => 'ログアウト';

  @override
  String get flowHomeDataRefresh => 'ホームのデータ更新';

  @override
  String get flowWebsiteLink => '公式サイトのリンク';

  @override
  String get flowFeedbackLink => 'フィードバックのリンク';

  @override
  String get flowGroupNumber => 'グループ番号';

  @override
  String get flowSurveyLink => 'アンケートのリンク';

  @override
  String get flowGatewayCheckBeforeReadingPlayCounts => 'プレイ回数取得前のゲートウェイ接続確認';

  @override
  String get flowReadPlayCountsSeparately => 'プレイ回数のみ取得';

  @override
  String get flowPushToDivingFishThroughTheAWMC => 'AWMCゲートウェイ経由で水魚に送信';

  @override
  String get flowPushToLXNSThroughTheAWMCGateway => 'AWMCゲートウェイ経由で落雪に送信';

  @override
  String get flowCouldNotLoadTheMosaicCoverTry =>
      'モザイク画像を読み込めませんでした。別の問題をお試しください。';

  @override
  String get flow0ShowsTheOriginalHigherValuesCreate3 =>
      '0%は元画像で、値が高いほどピクセルが大きくなります。';

  @override
  String get flowNoCachedChartsCacheMaidataInThe =>
      '譜面キャッシュがありません。先に譜面ライブラリでmaidataをキャッシュしてください。';

  @override
  String get flowNoCachedSongsMatchTheDifficultyPool =>
      '難易度候補・定数範囲に一致するキャッシュ済み譜面がありません。';

  @override
  String get flowCouldNotReadThisSongSChart => 'この楽曲の譜面データを読み込めませんでした';

  @override
  String get flowThisSongHasNoChartsInThe => 'この楽曲に抽選対象の難易度の譜面がありません';

  @override
  String get flowTheChartIsTooShortToExtract => '譜面が短すぎるため抜粋できません';

  @override
  String get flowCouldNotParseChart => '譜面を解析できませんでした';

  @override
  String flowP0ReplaysLeft(String p0) {
    return '（あと$p0回再生可能）';
  }

  @override
  String get flowNoReplaysLeft2 => '（再生回数を使い切りました）';

  @override
  String get flowFiltersUseEachSelectedDifficultySOwn =>
      '選択した各難易度の定数で絞り込みます。EXPERTのみならEXPERTの定数、EXPERT＋MASTERならどちらかが範囲内であれば対象です。';

  @override
  String get flowCouldNotLoadCoverArtPleaseRetry =>
      'ジャケットを読み込めませんでした。再試行してください。';

  @override
  String get flowNoRecognizableCropAreaInThisCover =>
      '識別できる切り抜き領域がありません。再試行するか、絞り込みを緩めてください。';

  @override
  String get flowAudioIsTemporarilyUnavailable => '現在音源を取得できません';

  @override
  String get flowCouldNotReadAudioDuration => '音源の長さを取得できませんでした';

  @override
  String get flowAudioExcerptIsEmpty => '音源の抜粋が空です';

  @override
  String get flowPreparingAudio2 => '音源を準備中…';

  @override
  String flowP0Tiles(String p0) {
    return '$p0マス';
  }

  @override
  String get flowTheSongCacheIsEmptyNoSong => '楽曲キャッシュが空のため抽選できません。';

  @override
  String get flowNoSongsMatchBroadenTheFiltersIn =>
      '条件に合う楽曲がありません。設定で絞り込みを緩めてください。';

  @override
  String get flowCouldNotLoadSettingsPleaseRetry => '設定を読み込めませんでした。再試行してください。';

  @override
  String get flowExcerptPlaybackLength => '抜粋の再生時間';

  @override
  String get flowS => '秒';

  @override
  String get flowBlurredCoverBlur => 'ぼかしジャケット：ぼかし度';

  @override
  String get flowPixelCoverDestruction => 'ピクセルジャケット：破壊度';

  @override
  String get flowFlashCoverDuration => '一瞬ジャケット：表示時間';

  @override
  String get flowTileRevealTileCount => 'ジャケットパズル：分割数';

  @override
  String get flowTiles => 'マス';

  @override
  String get flowTileRevealInterval => 'ジャケットパズル：公開間隔';

  @override
  String get flowNonEnglishCharacterThreshold => '英字以外の文字の割合上限';

  @override
  String get flowExcludeSongsWhoseShareOfJapaneseAnd =>
      '曲名に占める日本語など英字以外の文字（空白を除く）の割合が、この値以上の楽曲を除外します。';

  @override
  String get flowRemainingSongs => '残りの楽曲';

  @override
  String get flowYouGuessedEverySong => '全曲正解です！';

  @override
  String get flowSongsFromAllAreas => 'すべてのエリアの楽曲';

  @override
  String get flowPerfectChallengeSongsFromAllAreas => 'すべてのエリアのパーフェクトチャレンジ楽曲';

  @override
  String get flowFixedTheHiddenSong => '固定：隠し楽曲';

  @override
  String get flowBlueGateEntrance => '青の扉';

  @override
  String get flowSkyStreetArea6 => '天空街エリア6';

  @override
  String get flowWhiteGateEntrance => '白の扉';

  @override
  String get flowHeavenArea8 => '天界エリア8';

  @override
  String get flowPurpleGateEntrance => '紫の扉';

  @override
  String get flowPurpleRoseArea10 => '紫薔薇エリア10';

  @override
  String get flowBlackGateEntrance => '黒の扉';

  @override
  String get flowMetropolisArea9 => '大都会エリア9';

  @override
  String get flowPlayAll11SongsInThePool => '以下の楽曲候補11曲をすべてプレイ';

  @override
  String get flowTrackSkipIsAllowedDanCertificationAnd =>
      'Track Skip可。段位認定と宴会場は対象外です。';

  @override
  String get flowYellowGateEntrance => '黄の扉';

  @override
  String get flowRainbowArea => 'なないろちほー';

  @override
  String get flowAfterTheGateUpdateUseRandomSong =>
      '扉の更新後、ランダム選曲で以下の候補からいずれか1曲を引き、プレイします。';

  @override
  String get flowAnyDifficultyRetryingIsAllowedFavoritesCategories =>
      '（難易度不問。引き直し可。お気に入り分類も利用可能）';

  @override
  String get flowRandomSelectionInTheDepartureArea => '出発エリアでランダム選曲';

  @override
  String get flowRandomPerfectChallengeSongMAXRAGEAndUniTas =>
      '出発エリアのランダムパーフェクトチャレンジ楽曲・MAXRAGE・UniTas';

  @override
  String get flowRedGateEntrance => '赤の扉';

  @override
  String get flowSongPool => '楽曲候補';

  @override
  String get flowGateConditions => '扉の条件';

  @override
  String get flowNotSet3 => '（未設定）';

  @override
  String get flowKeyRequiredToChallenge => 'カギ（挑戦に必要なアイテム）';

  @override
  String get flowKALEIDXSCOPEMode => 'KALEIDXSCOPEモード';

  @override
  String flowFirstSongP0(String p0) {
    return '1曲目：$p0';
  }

  @override
  String flowSecondSongP0(String p0) {
    return '2曲目：$p0';
  }

  @override
  String flowThirdSongP0(String p0) {
    return '3曲目：$p0';
  }

  @override
  String get flowPerfectChallengeSong => 'パーフェクトチャレンジ楽曲';

  @override
  String get flowClearRewardSong => 'クリア解放楽曲';

  @override
  String get flowHiddenSong => '隠し楽曲';

  @override
  String get flowPerfectChallenge => 'パーフェクトチャレンジ';

  @override
  String get flowGuide => '攻略';

  @override
  String get flowSongs4 => '楽曲';

  @override
  String get flowBlueGate => '青の扉';

  @override
  String get flowWhiteGate => '白の扉';

  @override
  String get flowPurpleGate => '紫の扉';

  @override
  String get flowBlackGate => '黒の扉';

  @override
  String get flowYellowGate => '黄の扉';

  @override
  String get flowRedGate => '赤の扉';

  @override
  String get flowCouldNotLoadNewGatesRefreshUsing =>
      '追加の扉を読み込めませんでした。右上のボタンで更新してください。';

  @override
  String get flowDraw => '🤝 引き分け';

  @override
  String get flowJointWinners => '🤝 同点優勝';

  @override
  String get flowYouWon => '🏆 あなたの勝ち！';

  @override
  String flowP0Won(String p0) {
    return '🏆 $p0さんの勝ち';
  }

  @override
  String get flowNoOneScoredInThisGame => 'このゲームでは得点者がいません';

  @override
  String get flowCouldNotConnectToTheRoomCheck =>
      'ルームに接続できませんでした。接続を確認して再試行してください。';

  @override
  String flowP0IsNowTheHost(String p0) {
    return '$p0さんがホストになりました';
  }

  @override
  String get flowNoCoverArtAvailable => '利用できるジャケットがありません';

  @override
  String get flowScoring => '得点ルール';

  @override
  String get flowCorrectAnswer100SecondsSinceTheRound =>
      '正解時の得点＝100－ラウンド開始からの秒数、最低10点。不正解は0点です。';

  @override
  String get flowFasterAnswersScoreHigherInstantAnswersApproach =>
      '早い正解ほど高得点です。即答は100点に近く、最後でも最低10点を獲得できます。';

  @override
  String get flowOnlyYourBestAttemptForEachSong =>
      '同じ楽曲は最も良い1回のみ集計し、繰り返し回答しても得点は増えません。';

  @override
  String get flowOnlyTheFirstCorrectPlayerScoresFor =>
      '各楽曲で最初に正解した人だけが得点し、ほかの人はその曲では0点です。';

  @override
  String get flowIncorrectGuessesDoNotSubtractPoints => '不正解でも減点はありません。';

  @override
  String get flowLetterRevealHasSeveralSongsPerRound =>
      '文字開きは1ラウンドに複数曲あり、それぞれ得点を集計します。ラウンドの満点＝曲数×100点です。';

  @override
  String get flowColorMeanings => '色の意味';

  @override
  String get flowYellowCloseToTheTargetBPMWithin =>
      '黄色：正解に近い属性です。BPM差±20以内、MASTER／Re:MASTERの定数差±0.4以内、または1世代違い（maimai ← maimai PLUS → maimai GreeN）。';

  @override
  String get flowGrayFarFromTheTarget => '灰色：正解から離れています。';

  @override
  String get flowArrows2 => '矢印';

  @override
  String get flowShowsPatternDifficultyAndEvaluationTagsFor2 =>
      '回答した楽曲のMASTER譜面の配置・難易度・評価タグを表示します。';

  @override
  String get flowAMatchingTargetTagTurnsGreen => '正解と一致するタグは緑になります。';

  @override
  String get flowSomeSongsMayNotHaveTags2 => 'タグがない楽曲もあります。';

  @override
  String get flowLetterRevealRules => '文字開きのルール';

  @override
  String get flowTitlesAreMaskedWithAnyoneCanReveal =>
      '曲名を□で隠します。各プレイヤーが文字を開くと、ルーム全体に公開されます。';

  @override
  String get flowEachCharacterCanBeRevealedOnlyOnce => '同じ文字を開けるのは1回だけです。';

  @override
  String get flowOnceASongIsGuessedItsFull => '正解した楽曲の曲名は全員に公開されます。';

  @override
  String get flowGuessingFirstMayRevealTheAnswerBut =>
      '先に正解すると答えが公開される場合がありますが、得点は最初の正解者だけなので、早い回答が有利です。';

  @override
  String get flowTheRoundEndsOnlyWhenEveryTitle => 'すべての曲名を当てるとラウンドが終了します。';

  @override
  String get flowRoomRules => 'ルームのルール';

  @override
  String get flowRemainingGuessesAreSharedByTheWhole =>
      '残り回答回数はルーム全体で共有します。誰が回答しても同じ回数から消費し、使い切るとラウンド終了です。';

  @override
  String get flowAfterSurrenderingYouCannotScoreOrSubmit =>
      '降参後はそのラウンドで得点・回答できませんが、観戦は続けられます。';

  @override
  String get flowWinning => '勝敗の決め方';

  @override
  String get flowTheHighestTotalScoreAfterAllRounds =>
      '全ラウンド終了時に合計得点が最も高い人が勝ちです。';

  @override
  String get flowEqualScoresShareTheWinIfNo => '同点は同点優勝、全員無得点なら引き分けです。';

  @override
  String get flowScoresAreSettledAtTheEndOf =>
      '各ラウンドの終了時に集計し、ランキングには集計後の合計を表示します。';

  @override
  String get flowNoTimeLimit => '時間制限なし';

  @override
  String get flowTimeIsUp => '時間切れ';

  @override
  String get flowAlmostOutOfTime => '残り時間わずか！';

  @override
  String get flowPlentyOfTime => 'まだ余裕があります';

  @override
  String get flowAliasClue => '別名のヒント';

  @override
  String get flowReplayExcerptAudioPreparing => '抜粋を再生（音源準備中）';

  @override
  String flowReplayExcerptP0ReplaysLeft(String p0) {
    return '抜粋を再生（あと$p0回）';
  }

  @override
  String get flowAnswerUnlimitedReplaysChartOnlyAudioUnavailable =>
      '正解公開：何度でも再生可（音源なし、譜面のみ）';

  @override
  String get flowAnswerUnlimitedReplaysWithAudio => '正解公開：音源付きで何度でも再生可';

  @override
  String get flowAnswerUnlimitedReplaysPreparingAudio => '正解公開：何度でも再生可（音源準備中…）';

  @override
  String get flowPlaybackStopsAutomaticallyAtTheEndOf => '抜粋の末尾で自動停止します';

  @override
  String get flowThisChartIsNotCachedOnThis => 'この端末に譜面キャッシュがなく、自動取得もできませんでした。';

  @override
  String get flowNoChartForThisSongMatchesThe => 'この楽曲に難易度候補・定数範囲に合う譜面がありません。';

  @override
  String flowCouldNotReadInoteP0ForThis(String p0) {
    return 'この楽曲のinote_$p0を読み込めませんでした';
  }

  @override
  String get flowCouldNotPlayChartExcerptPleaseRetry =>
      '譜面の抜粋を再生できませんでした。再試行してください。';

  @override
  String get flowInvalidSongID => '無効な楽曲ID';

  @override
  String get flowCouldNotFetchAudioTryAgainLater =>
      '音源を取得できませんでした。後でもう一度お試しください。';

  @override
  String get flowLeavingRoom => 'ルームから退出中…';

  @override
  String get flowRoomDoesNotExistOrCannotBe => 'ルームが存在しないか、参加できません';

  @override
  String get flow2Players => '2人';

  @override
  String get flow3Players => '3人';

  @override
  String get flow4Players => '4人';

  @override
  String get flow5Players => '5人';

  @override
  String get flow6Players => '6人';

  @override
  String get flowRoomCodeCannotBeEmpty => 'ルームコードを入力してください';

  @override
  String get flowAfterCreatingARoomTheHostCan =>
      'ホストはルームを作成すると、ルーム画面からコードをコピーできます。';

  @override
  String get flowAskYourFriendToSendTheCode => 'フレンドからコードを受け取り、上に貼り付けると参加できます。';

  @override
  String get flowCouldNotReadAutomaticInstallationSettingsPlease =>
      '自動インストール設定を読み込めませんでした。再試行してください。';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettingsPlease =>
      '自動インストール設定を保存できませんでした。再試行してください。';

  @override
  String get flowCouldNotOpenInstallationSourceSettingsAllow =>
      'インストール元の設定を開けませんでした。システム設定でChiffonMaiからのインストールを許可してください。';

  @override
  String get flowDownloadCancelledByUser => 'ユーザーがダウンロードをキャンセルしました';

  @override
  String get flowThisVersionHasNotBeenPublishedYet => 'このバージョンはまだ公開されていません';

  @override
  String get flowCouldNotIdentifyASingleAPKFor =>
      'この端末用のAPKを一意に特定できません。Webからダウンロードしてください。';

  @override
  String get flowReleaseAssetLacksValidAPKInformationOr =>
      '公開ファイルに有効なAPK情報またはSHA-256値がありません';

  @override
  String get flowCouldNotFetchGitHubReleaseInformation =>
      'GitHubのリリース情報を取得できませんでした';

  @override
  String get flowFetchingAPKInformation => 'APK情報を取得中…';

  @override
  String get flowPreparingBackgroundDownload => 'バックグラウンドダウンロードを準備中…';

  @override
  String get flowCouldNotStartBackgroundDownload => 'バックグラウンドダウンロードを開始できませんでした';

  @override
  String get flowCouldNotStartBackgroundDownloadPleaseRetry =>
      'バックグラウンドダウンロードを開始できませんでした。再試行してください。';

  @override
  String get flowCouldNotReadExcerptDuration => '抜粋の長さを取得できませんでした';

  @override
  String get flowAudioExcerptIsIncomplete => '音源の抜粋が不完全です';

  @override
  String get flowAudioResponseIsNotAValidWAV => '音源の応答が有効なWAVファイルではありません';

  @override
  String get flowNoAliases => '別名なし';

  @override
  String get flowTooLate => '遅すぎます';

  @override
  String get flowTooEarly => '早すぎます';

  @override
  String get flowInitializationFailed => '初期化に失敗しました';

  @override
  String get flowInitializationTimedOut => '初期化がタイムアウトしました';

  @override
  String flowRepeatOneP0Times(String p0) {
    return '1曲を$p0回リピート';
  }

  @override
  String get flowCurrentSong => '現在の楽曲';

  @override
  String flowLXNSAudioFailedForP0TryingWmc(String p0) {
    return '「$p0」の落雪音源を取得できません。wmcを試しています…';
  }

  @override
  String flowNoAudioAvailableForP0Skipped(String p0) {
    return '「$p0」の音源がないためスキップしました。';
  }

  @override
  String get flowChiffonMaiMusicPlayer => 'ChiffonMai音楽プレイヤー';

  @override
  String get flowSeveralSongsFailedToLoadAutomaticSkipping =>
      '複数の音源の読み込みに失敗したため、自動スキップを停止しました。接続を確認して再試行してください。';

  @override
  String flowNowPlayingP0(String p0) {
    return '再生中：$p0';
  }

  @override
  String flowCouldNotSaveAudioP0(String p0) {
    return '音源を保存できませんでした：$p0';
  }

  @override
  String get flowInvalidAPKDirectoryRange => 'APKのディレクトリ範囲が無効です';

  @override
  String get flowIncompleteAPKDirectoryData => 'APKのディレクトリデータが不完全です';

  @override
  String get flowCouldNotReadAPKZIPDirectory => 'APKのZIPディレクトリを読み込めません';

  @override
  String get flowInvalidAPKManifestSize => 'APKマニフェストのサイズが無効です';

  @override
  String get flowInvalidAPKManifestDirectory => 'APKマニフェストのディレクトリが無効です';

  @override
  String get flowAPKManifestDecompressedSizeMismatch =>
      'APKマニフェストの展開後サイズが一致しません';

  @override
  String get flowUnsupportedAPKManifestCompression => 'APKマニフェストの圧縮形式に対応していません';

  @override
  String get flowIncompleteAPKManifestData => 'APKマニフェストのデータが不完全です';

  @override
  String get flowAPKHasNoVersionManifest => 'APKにバージョンマニフェストがありません';

  @override
  String get flowInvalidBinaryAPKManifest => 'APKのバイナリマニフェストが無効です';

  @override
  String get flowInvalidAPKManifestStringIndex => 'APKマニフェストの文字列索引が無効です';

  @override
  String get flowInvalidAPKManifestChunk => 'APKマニフェストのチャンクが無効です';

  @override
  String get flowInvalidAPKManifestStringTable => 'APKマニフェストの文字列表が無効です';

  @override
  String get flowInvalidAPKManifestAttribute => 'APKマニフェストの属性が無効です';

  @override
  String get flowAPKManifestAttributeOutOfBounds => 'APKマニフェストの属性が範囲外です';

  @override
  String get flowAPKLacksValidVersionInformation => 'APKに有効なバージョン情報がありません';

  @override
  String get flowAPKHasNoAppVersionInformation => 'APKにアプリのバージョン情報がありません';

  @override
  String get flowAPKManifestDataOutOfBounds => 'APKマニフェストのデータが範囲外です';

  @override
  String get flowContentContainsDisallowedWordingEditItAnd =>
      '使用できない表現が含まれています。修正して再試行してください。';

  @override
  String get flowMASTERConstantRange => 'MASTERの定数範囲';

  @override
  String get flowUnlimited2 => '制限なし';

  @override
  String get flowEnterOneValueOrACompleteRange =>
      '13.7、または13.4-14のように単一の値か完全な範囲を入力してください';

  @override
  String get flowConstantMustBeAFiniteNumberGreater => '定数は0より大きい有限の数値にしてください';

  @override
  String get flowLowerBoundCannotExceedUpperBound => '下限は上限以下にしてください';

  @override
  String get flowUnknownDifficulty => '不明な難易度';

  @override
  String get flowUTAGECannotBeCombinedWithNormalDifficulties =>
      'UTAGEと通常難易度は同時に指定できません';

  @override
  String get flowChooseSaveLocation => '保存先を選択';

  @override
  String get flowPublicExportDirectoryIsNotWritableWriting =>
      '公開の書き出し先に書き込めないため、アプリ専用フォルダへの保存を拒否しました。';

  @override
  String flowSupportsChiffonMaiFavoritesFilesSuchAsP0(String p0) {
    return '$p0などのChiffonMaiお気に入りファイルに対応';
  }

  @override
  String get flowCouldNotReadCoverPixels => 'ジャケットのピクセルを読み込めません';

  @override
  String get flowCouldNotReadImageData => '画像データを読み込めません';

  @override
  String get flowDateToBeUpdated => '日程は未定';

  @override
  String get flowLater => '以降';

  @override
  String get flowWaitForRetryAfterSecondsOrQuotaResetAtBefore =>
      'retryAfterSecondsまたはquota.resetAtまで待って再試行してください';

  @override
  String flowRetryAfterSecondsP0S(String p0) {
    return 'retryAfterSeconds（$p0秒）';
  }

  @override
  String flowRetryAfterP0OrP1(String p0, String p1) {
    return '$p0または$p1まで待って再試行してください';
  }

  @override
  String get flowYourSelectionIsActiveButCouldNot =>
      '今回の選択は反映されていますが、保存できませんでした。選択した難易度をもう一度押して再試行してください。';

  @override
  String flowP0ReleasedTapForChanges(String p0) {
    return '$p0を公開しました。タップして更新内容を確認。';
  }

  @override
  String get flowPleaseSignIn => 'ログインしてください';

  @override
  String get flowSettingsWereNotSavedPleaseRetry => '設定を保存できませんでした。再試行してください。';

  @override
  String flowP0Count(String p0) {
    return '$p0の数';
  }

  @override
  String get flowAllowChiffonMaiToInstallUpdates =>
      'ChiffonMaiによる更新のインストールを許可してください';

  @override
  String get flowCouldNotOpenInstaller => 'インストール画面を開けませんでした';

  @override
  String get flowCouldNotOpenInstallationPermissionSettings =>
      'インストール権限の設定を開けませんでした';

  @override
  String get flowActionFailedPleaseRetry => '操作に失敗しました。再試行してください。';

  @override
  String flowCouldNotReadCacheUsageP0(String p0) {
    return 'キャッシュ使用量を読み込めませんでした：$p0';
  }

  @override
  String flowCouldNotClearCacheP0(String p0) {
    return 'キャッシュを削除できませんでした：$p0';
  }

  @override
  String get flowLeftRight => '左右反転';

  @override
  String get flowUpDown => '上下反転';

  @override
  String get flowBoth => '全反転';

  @override
  String get flowNoMirror => 'ミラーなし';

  @override
  String get flowNothingHereYet => 'まだ何もありません';

  @override
  String get flowChoose015SpeedAndPitch =>
      '0.1～5倍を選択できます。速度と音程は連動して変わります。音源が設定時間より短い場合は実際の長さで再生します。';

  @override
  String get flowBPMChanges => 'BPM変化';

  @override
  String get flowNotProvided => '未提供';

  @override
  String get flowYes => 'あり';

  @override
  String get flowNo2 => 'なし';

  @override
  String get flowBPMChangeCount => 'BPM変化回数';

  @override
  String get flowCouldNotLoadCoverArt2 => 'ジャケットを読み込めませんでした';

  @override
  String get flowCorrect2 => '正解数';

  @override
  String get flowAccuracy => '正解率';

  @override
  String get flowAverageTime => '平均時間';

  @override
  String get flowCurrentStreak => '現在の連続正解';

  @override
  String get flowBestStreak => '最多連続正解';

  @override
  String get flowResultOriginalAudio => '結果の原音';

  @override
  String get flowOriginalAudioIsUnavailablePleaseRetry =>
      '元の音源を再生できません。再試行してください。';

  @override
  String get flowPlayOriginalAudio => '元の音源を再生';

  @override
  String get flowTitle2 => '曲名';

  @override
  String get flowType => 'タイプ';

  @override
  String get flowMASTERConstant => 'MASTER定数';

  @override
  String get flowMASTERChartDesigner => 'MASTER譜面制作者';

  @override
  String get flowReMASTERConstant => 'Re:MASTER定数';

  @override
  String get flowReMASTERChartDesigner => 'Re:MASTER譜面制作者';

  @override
  String get flowMatch => '一致';

  @override
  String get flowCloseArrowsPointToTheAnswer => '近い（矢印は正解の方向）';

  @override
  String get flowNoMatch => '不一致';

  @override
  String flowP0SRound(String p0) {
    return '1ラウンド$p0秒';
  }

  @override
  String flowP0Rounds(String p0) {
    return '$p0ラウンド';
  }

  @override
  String flowP0SharedGuessesPerRound(String p0) {
    return '各ラウンドで$p0回の回答を共有';
  }

  @override
  String get flowUnlimitedGuesses => '回答回数無制限';

  @override
  String flowConstantsP0P1(String p0, String p1) {
    return '定数$p0～$p1';
  }

  @override
  String get flowTemporarilyOffline => '一時オフライン';

  @override
  String get flowSurrendered => '降参済み';

  @override
  String get flowShareTheRoomCodeToInviteFriends => 'ルームコードを共有してフレンドを招待';

  @override
  String get flowReady2 => '準備完了';

  @override
  String get flowWaitingToBeReady => '準備待ち';

  @override
  String get flowConfirmingPlayerIdentity => 'プレイヤーの本人確認中…';

  @override
  String get flowShareTheCodeAndInviteAtLeast => 'コードを共有して1人以上のフレンドを招待してください';

  @override
  String flowP0PlayersAreNotReadyYet(String p0) {
    return 'あと$p0人が準備中です';
  }

  @override
  String get flowEveryoneIsReadyYouCanStart => '全員準備完了。開始できます！';

  @override
  String get flowEveryoneIsReadyWaitingForTheHost => '全員準備完了。ホストの開始を待っています。';

  @override
  String get flowCouldNotUpdateSongLeaderboard => '単曲ランキングを更新できませんでした';

  @override
  String get flowRoute1SyncFailed => '経路1の同期に失敗しました';

  @override
  String get flowCoverGuessing => 'ジャケット曲当て';

  @override
  String get flowBlurredCover => 'ぼかしジャケット';

  @override
  String get flowPixelCover => 'ピクセルジャケット';

  @override
  String get flowReverseAudio => '逆再生';

  @override
  String get flowSpeedPitch => '速度・音程';

  @override
  String get flowAliasGuessing => '別名曲当て';

  @override
  String get flowFlashCover => '一瞬ジャケット';

  @override
  String get flowTileReveal => 'ジャケットパズル';

  @override
  String get flowGuessTheSongFromItsInformation => '楽曲情報から曲名を当てる';

  @override
  String get flowGuessTheSongFromACoverFragment => 'ジャケットの一部から曲名を当てる';

  @override
  String get flowGuessTheSongFromABlurredCover => 'ぼかしたジャケットから曲名を当てる';

  @override
  String get flowGuessTheSongFromPixelBlocksAnd => 'ピクセルの色や輪郭から曲名を当てる';

  @override
  String get flowGuessTheSongFromAReversedExcerpt => '逆再生した抜粋から曲名を当てる';

  @override
  String get flowGuessFromAnExcerptWithLinkedSpeed => '速度と音程を連動して変えた抜粋から曲名を当てる';

  @override
  String get flowGuessTheSongFromAnAudioExcerpt => '音源の抜粋から曲名を当てる';

  @override
  String get flowGuessTheSongFromAnAlias => '別名から曲名を当てる';

  @override
  String get flowGuessTheSongFromInitialLetters => '頭文字から曲名を当てる';

  @override
  String get flowRememberABrieflyFlashedCoverToGuess =>
      '一瞬表示されるジャケットを覚えて曲名を当てる';

  @override
  String get flowCoverTilesAreRevealedInBatches => 'ジャケットのパーツを順に公開';

  @override
  String get flowGuessFromASilentChartExcerpt => '無音の譜面の抜粋から曲名を当てる';

  @override
  String get flowAutomaticInstallationTestingRequiresAndroid12Or =>
      '自動インストールのテスト機能にはAndroid 12以降が必要です';

  @override
  String get flowCouldNotSaveAutomaticInstallationSettings =>
      '自動インストール設定を保存できませんでした';

  @override
  String get flowAutomaticInstallationIsOffYouCanInstall =>
      '自動インストールを無効にしました。手動でインストールできます。';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo =>
      '更新をダウンロードしました。アプリがバックグラウンドでタスクなしの状態を8秒保つと、自動インストールを試みます。';

  @override
  String get flowInstallationTaskInformationIsIncomplete =>
      'インストールタスクの情報が不完全です';

  @override
  String get flowAutomaticInstallationIsOffInstallManually =>
      '自動インストールは無効です。手動でインストールしてください。';

  @override
  String get flowFinishActiveTasksOrPlaybackBeforeUpdating =>
      '更新する前に実行中のタスクや再生を終了してください';

  @override
  String get flowAllowAppsToBeInstalledFromThis =>
      '先にこの提供元からのアプリのインストールを許可してください';

  @override
  String get flowInstallationTaskChangedCheckUpdateStatusAgain =>
      'インストールタスクが変わりました。更新状態を確認し直してください。';

  @override
  String get flowCouldNotMoveTheAppToThe =>
      'アプリをバックグラウンドに移せませんでした。後でもう一度お試しください。';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo2 =>
      '更新をダウンロードしました。バックグラウンドに移ってから自動インストールを試みます。';

  @override
  String get flowUpdateDownloadedWaitingForTheCurrentTask =>
      '更新をダウンロードしました。現在のタスクが終了してから自動インストールを試みます。';

  @override
  String get flowTheLastAutomaticInstallationDidNotFinish =>
      '前回の自動インストールは完了していません。手動でインストールできます。';

  @override
  String get flowCannotReadTheAPK => 'APKを読み込めません';

  @override
  String get flowThisAPKDoesNotMeetTheSystem =>
      'このAPKは現在のシステムの確認不要インストール要件を満たしません。手動でインストールしてください。';

  @override
  String get flowCouldNotSaveInstallationTask => 'インストールタスクを保存できませんでした';

  @override
  String get flowPreparingAutomaticUpdateInstallation => '更新の自動インストールを準備中…';

  @override
  String get flowAPKVerificationFailedDownloadAgain =>
      'APKの検証に失敗しました。再ダウンロードしてください。';

  @override
  String get flowUpdateDownloadedWaitingForTheAppTo3 =>
      '更新をダウンロードしました。アプリがバックグラウンドでタスクなしの状態を8秒保つとインストールします。';

  @override
  String get flowTheSystemNeedsInstallationConfirmationTapTo =>
      'システムがインストールの確認を求めています。タップして手動でインストールしてください。';

  @override
  String get flowAutomaticInstallationDidNotFinishYouCan =>
      '自動インストールは完了していません。手動でインストールできます。';

  @override
  String get flowUpdateDownloadDirectoryUnavailable => '更新のダウンロード先を利用できません';

  @override
  String get flowInvalidDownloadAddress => '無効なダウンロード先';

  @override
  String get flowInvalidAPKVerificationInformation => 'APKの検証情報が無効です';

  @override
  String get flowUpdateTaskChanged => '更新タスクを切り替えました';

  @override
  String get flowCouldNotRemoveThePreviousUpdateFile => '前回の更新ファイルを削除できませんでした';

  @override
  String get flowDownloadingInTheBackgroundYouCanKeep =>
      'バックグラウンドでダウンロード中です。引き続きアプリを使えます。';

  @override
  String get flowDownloadingUpdateInTheBackground => '更新をバックグラウンドでダウンロード中…';

  @override
  String get flowTheAPKWasRemovedDownloadAgain => 'APKが削除されています。再ダウンロードしてください。';

  @override
  String get flowDownloadCancelled => 'ダウンロードをキャンセルしました';

  @override
  String get flowWaitingForNetworkOrTheSystemTo =>
      'ネットワークまたはシステムによるダウンロードの再開を待っています…';

  @override
  String get flowAutomaticInstallationCancelled => '自動インストールをキャンセルしました';

  @override
  String get flowCheckForUpdatesAgainBeforeDownloading =>
      '更新を再確認してからダウンロードしてください';

  @override
  String get flowDownloadFailed => 'ダウンロードに失敗しました';

  @override
  String get flowVerifyingAPKInTheBackground => 'バックグラウンドでAPKを検証中…';

  @override
  String get flowAPKDownloadIsIncomplete => 'APKのダウンロードが不完全です';

  @override
  String get flowAPKIntegrityCheckFailed => 'APKの完全性検証に失敗しました';

  @override
  String get flowUpdateDownloadFailedPleaseRetry =>
      '更新のダウンロードに失敗しました。再試行してください。';

  @override
  String get flowChiffonMaiUpdateDownloaded => 'ChiffonMaiの更新をダウンロードしました';

  @override
  String get flowChiffonMaiUpdateDownloadFailed => 'ChiffonMaiの更新ダウンロードに失敗しました';

  @override
  String get flowTapToChooseInstallation => 'タップしてインストール方法を選択';

  @override
  String get flowTapForDetailsOrToDownloadAgain => 'タップして詳細確認または再ダウンロード';

  @override
  String get flowSwitchedToManualInstallation => '手動インストールに切り替えました';

  @override
  String get flowCouldNotPrepareUpdateInstallation => '更新のインストールを準備できませんでした';

  @override
  String get flowAPKInformationIsMissing => 'APK情報がありません';

  @override
  String get flowAPKIsOutsideTheUpdateCacheDirectory =>
      'APKが更新キャッシュフォルダの外にあります';

  @override
  String get flowTheDownloadedFileIsNotAValid => 'ダウンロードしたファイルは有効なAPKではありません';

  @override
  String get flowThisAPKDoesNotBelongToChiffonMai =>
      'このAPKはChiffonMaiのものではありません';

  @override
  String get flowAPKVersionDoesNotMatchTheUpdate =>
      'APKのバージョンが更新情報と一致しません。Webからダウンロードしてください。';

  @override
  String get flowAPKSignatureMismatchInstallationStopped =>
      'APKの署名が一致しないため、インストールを停止しました。';

  @override
  String get flowChiffonMaiCrashed => 'ChiffonMaiが異常終了しました';

  @override
  String get flowLogsWillBeExportedWhenYouReopen => 'アプリを再度開くとログを自動で書き出します';

  @override
  String get flowAppCrash => 'アプリの異常終了';

  @override
  String get flowNativeCrash => 'ネイティブの異常終了';

  @override
  String get flowAppNotResponding => 'アプリが応答していません';

  @override
  String get flowCrashAlerts => '異常終了の通知';

  @override
  String get flowOpenTheAppToRefreshData => 'アプリを開いてデータを更新';

  @override
  String get flowUpdatesAutomaticallyWhenOnline => '接続後に自動更新';

  @override
  String get flowOpenTheAppToUpdate => 'アプリを開いて更新';

  @override
  String get flowImageExports => '画像の書き出し';

  @override
  String get flowCouldNotReadSystemWallpaperColors => 'システムの壁紙の色を取得できませんでした';

  @override
  String get flowMusicPlayback => '音楽再生';

  @override
  String get flowShowsTheCurrentSongAndPlaybackControls => '再生中の楽曲と操作ボタンを表示';

  @override
  String get flowMusicPlayerPlaying => '音楽プレイヤー・再生中';

  @override
  String get flowMusicPlayerPaused => '音楽プレイヤー・一時停止中';

  @override
  String get flowSyncNow => '今すぐ同期';

  @override
  String get flowRecognizeScore => '成績を認識';

  @override
  String get flowMaimaiStatus => 'maimaiの状態';

  @override
  String get flowPlayPause => '再生／一時停止';

  @override
  String get flowMaimaiStatusAndSync => 'maimaiの状態と同期';

  @override
  String get flowChiffonMaiOverview => 'ChiffonMai概要';

  @override
  String get flowChiffonMaiDetails => 'ChiffonMai詳細';

  @override
  String get flowShowsYourRating => '自分のRatingを表示';

  @override
  String get flowShowsMaimaiStatusAndAutomaticSync => 'maimaiの状態と自動同期を表示';

  @override
  String get flowRatingMaimaiStatusAndAutomaticSync => 'Rating・maimaiの状態・自動同期';

  @override
  String get flowAddsSourceSyncResultsAndQuickActions => '取得元ごとの同期結果とクイック操作を追加';

  @override
  String flowChiffonMaiVP0Update(String p0) {
    return 'ChiffonMai v$p0の更新';
  }

  @override
  String flowAutomaticInstallationDidNotFinishP0You(String p0) {
    return '自動インストールが完了していません：$p0。手動でインストールできます。';
  }

  @override
  String flowP0P1Healthy(String p0, String p1) {
    return '$p0/$p1正常';
  }

  @override
  String flowTodayP0(String p0) {
    return '今日 $p0';
  }

  @override
  String flowP0P1P22(String p0, String p1, String p2) {
    return '$p0月$p1日 $p2';
  }

  @override
  String flowUpdatedP03(String p0) {
    return '$p0更新';
  }

  @override
  String get flowImageSavedTapToReturnToChiffonMai =>
      '画像を保存しました。タップしてChiffonMaiに戻る。';

  @override
  String get flowNotSupportedByTheSystemRightNow => '現在システムが対応していません';

  @override
  String get svcCheckInIsUnavailableRightNowIt =>
      '現在チェックインできません。次回起動時に自動で再試行します。';

  @override
  String get svcCouldNotReadGrowthRecordsItWill =>
      '成長記録を読み込めませんでした。次回起動時に自動で再試行します。';

  @override
  String get svcCheckedInToday => '本日はチェックイン済み';

  @override
  String get svcSignInToCheckInAndEarn => 'ログインすると、毎日最初の起動時にチェックインしてEXPを獲得できます';

  @override
  String get svcNoGrowthRecordsYetYouWillBe =>
      '成長記録はまだありません。次回起動時に自動でチェックインします。';

  @override
  String get svcCheckingIn => 'チェックイン中…';

  @override
  String get svcCheckInAccountDoesNotMatch => 'チェックインのアカウントが一致しません';

  @override
  String svcCheckedInTodayP0EXP(String p0) {
    return '本日のチェックイン：+$p0 EXP';
  }

  @override
  String get svcSavedOnThisDeviceOnlySyncsAfter => 'この端末にのみ保存 · 水魚にログインすると自動同期';

  @override
  String get svcSavedOnThisDeviceOnlySignIn =>
      'この端末にのみ保存 · 先に落雪アカウントにログインして更新してください';

  @override
  String get svcSavedOnThisDeviceOnlyEnterThe =>
      'この端末にのみ保存 · 先にAWMCアカウントのQQ番号を入力してください';

  @override
  String get svcLoadingCommunityAppearance => 'コミュニティの装いを読み込み中';

  @override
  String get svcAppearanceWaitingToSync => '装いの同期待ち';

  @override
  String get svcAppearanceWaitingToSyncSignInOr =>
      '装いの同期待ち · 対応するアカウントにログインまたは認証してから再試行してください';

  @override
  String get svcAppearanceWaitingToSyncTapToRetry => '装いの同期待ち · タップして再試行';

  @override
  String get svcSavedOnThisDeviceOnlySignIn2 =>
      'この端末にのみ保存 · 先に対応するアカウントにログインまたは認証してください';

  @override
  String get svcSyncingCommunityAppearance => 'コミュニティの装いを同期中';

  @override
  String get svcCommunityAppearanceSynced => 'コミュニティの装いを同期しました';

  @override
  String get svcAppearanceWaitingToSyncTheServerHas =>
      '装いの同期待ち · 選択した装いはまだサーバーで確認されていません';

  @override
  String get svcCouldNotGetTheAPKVersionsPublished =>
      'GitHubで公開されているAPKのバージョンを取得できませんでした';

  @override
  String get svcCouldNotReadTheActualVersionOf =>
      'GitHubのAPKの実際のバージョンを読み取れませんでした。しばらくしてから再試行してください。';

  @override
  String get svcTheAppOrVersionOfTheGitHub =>
      'GitHubのAPKのアプリまたはバージョンがリリース情報と一致しません';

  @override
  String get svcExperienceImprovements => '使い勝手の改善';

  @override
  String get svcNetworkConnectionFailedCheckYourNetworkAnd =>
      'ネットワークに接続できませんでした。ネットワークを確認して再試行してください。';

  @override
  String svcUpdateCheckFailedP0(String p0) {
    return '更新の確認に失敗しました：$p0';
  }

  @override
  String get svcSwitchRoutesAutomatically => '経路を自動切り替え';

  @override
  String get svcTriesTheMirrorRoutesThenTheOfficial => '高速化経路と公式直接接続を順に試します';

  @override
  String get svcCommonMirrorRoute => '標準の高速化経路';

  @override
  String get svcBackupMirrorRoute => '予備の高速化経路';

  @override
  String get svcGitHubDirect => 'GitHub直接接続';

  @override
  String get svcDownloadDirectlyFromGitHub => 'GitHub公式から直接ダウンロード';

  @override
  String get svcQRCodeEntryCancelled => 'QRコードの入力をキャンセルしました';

  @override
  String svcReasonP0TheLogWasExportedAutomatically(String p0) {
    return '原因：$p0。ログは自動でエクスポートされました：';
  }

  @override
  String get gainRouteStable => '堅実に上げる';

  @override
  String get gainRouteChallenge => '限界突破';

  @override
  String get gainRouteExplore => '探索';

  @override
  String get svcIncorrectUsernameOrPasswordCheckAndTry =>
      'ユーザー名またはパスワードが違います。確認して再試行してください。';

  @override
  String get svcTooManySignInAttemptsTryAgain =>
      'ログインの試行回数が多すぎます。しばらくしてから再試行してください。';

  @override
  String get svcTheDivingFishSignInServiceIs =>
      '水魚のログインサービスは現在利用できません。しばらくしてから再試行してください。';

  @override
  String get svcTheDivingFishSignInServiceReturned =>
      '水魚のログインAPIが異常な応答を返しました。しばらくしてから再試行してください。';

  @override
  String get svcSignedInButNoSessionWasCreated =>
      'ログインしましたが、セッションを確立できませんでした。しばらくしてから再試行してください。';

  @override
  String get svcSignedInButCouldNotGetThe =>
      'ログインしましたが、アカウント情報を取得できませんでした。しばらくしてから再試行してください。';

  @override
  String get svcSignedInButNoImportTokenWasReturned =>
      'ログインしましたが、ImportTokenを取得できませんでした。水魚の公式サイトで再発行して保存してください。';

  @override
  String get svcSignedInButNoLinkedQQNumber =>
      'ログインしましたが、連携済みのQQ番号を取得できませんでした。水魚の公式サイトで入力して保存してください。';

  @override
  String get svcASyncIsAlreadyInProgressTry => '同期はすでに実行中です。しばらくしてから再試行してください。';

  @override
  String get svcTheQRCodeIsInvalidOrHas => 'QRコードが無効か期限切れです。もう一度スキャンしてください。';

  @override
  String get svcMaimaiScoreHubReturnedAnUnexpectedResponse =>
      'maimai Score Hubの応答が異常です（tokenまたはfriendCodeがありません）。しばらくしてから再試行してください。';

  @override
  String get svcCouldNotCreateTheFetchTaskTry =>
      '取得タスクを作成できませんでした。しばらくしてから再試行してください。';

  @override
  String get svcCouldNotCreateTheFriendRequestTry =>
      'フレンド申請を作成できませんでした。しばらくしてから再試行してください。';

  @override
  String get svcMaimaiScoreHubDidNotReturnA =>
      'maimai Score HubからフレンドリクエストのタスクIDが返されませんでした';

  @override
  String get svcFriendRequestTimedOutAcceptTheRequest =>
      'フレンド申請がタイムアウトしました。NETまたは筐体で申請を承認してから再試行してください。';

  @override
  String get svcFriendRequestFailed => 'フレンド申請に失敗しました';

  @override
  String get svcMaimaiScoreHubDidNotReturnA2 =>
      'maimai Score HubからタスクIDが返されませんでした';

  @override
  String svcSyncTimedOutFetchingScoresTookMore(String p0) {
    return '同期がタイムアウトしました。スコア取得に$p0分以上かかっています。Botのフレンド申請が承認されていない可能性があります。NETで申請を確認してから再試行してください。';
  }

  @override
  String get svcCouldNotCheckTheTaskStatusCheck =>
      'タスクの状態を確認できませんでした。ネットワークを確認して再試行してください。';

  @override
  String get svcTaskFailed => 'タスクに失敗しました';

  @override
  String get svcScoresWereFetchedButSyncingToDiving =>
      'スコアは取得できましたが、水魚への同期に失敗しました。後で手動でエクスポートを再試行できます。';

  @override
  String svcDivingFishExportFailedP0(String p0) {
    return '水魚へのエクスポートに失敗しました：$p0';
  }

  @override
  String svcSyncErrorP0(String p0) {
    return '同期エラー：$p0';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub =>
      'maimai Score Hubにログインしていません。経路2で同期する前にログインしてください。';

  @override
  String get svcCouldNotSubmitTheQRCodeCheck =>
      'QRコードを送信できませんでした。ネットワークを確認して再試行してください。';

  @override
  String svcSyncTimedOutFetchingScoresTookMore2(String p0) {
    return '同期がタイムアウトしました。スコア取得に$p0分以上かかっています。しばらくしてから再試行してください。';
  }

  @override
  String get svcCouldNotSetTheLXNSAPIKey =>
      '落雪APIキーを設定できませんでした。ネットワークを確認して再試行してください。';

  @override
  String svcSyncTimedOutFetchingCabinetScoresTook(String p0) {
    return '同期がタイムアウトしました。筐体スコアの取得に$p0分以上かかっています';
  }

  @override
  String get svcScoresWereFetchedButSyncingToLXNS =>
      'スコアは取得できましたが、落雪への同期に失敗しました。後で手動でエクスポートを再試行できます。';

  @override
  String svcLXNSExportFailedP0(String p0) {
    return '落雪へのエクスポートに失敗しました：$p0';
  }

  @override
  String get svcQueueStatisticsAreUnavailableTryAgainLater =>
      'キューの統計は現在利用できません。しばらくしてから再試行してください。';

  @override
  String get svcCouldNotReadTheAutoSyncSettings =>
      '自動同期の設定を読み込めませんでした。端末のデータを残したまま再試行してください。';

  @override
  String get svcCouldNotReadTheAutoSyncCredentials =>
      '自動同期の認証情報を読み込めませんでした。端末のデータを残したまま再試行してください。';

  @override
  String get svcTheAutoSyncServiceIsUnavailableCheck =>
      '自動同期サービスは現在利用できません。ネットワークを確認して再試行してください。設定状態はまだ確認されていません。';

  @override
  String get svcSyncedButTheLocalDataRefreshDid =>
      '同期しましたが、端末データの更新が完了していません。手動で更新してください。';

  @override
  String get svcPersonalKeySavedOnThisDeviceThe =>
      '個人キーは端末に保存しました。定期タスクの更新待ちです';

  @override
  String get svcTheAccountChangedTurnOffAutoSync =>
      'アカウントが切り替わりました。以前のアカウントの自動同期をオフにしてから、もう一度オンにしてください。';

  @override
  String get svcSaveThePersonalKeyForThisData => 'このデータソースの個人キーをもう一度保存してください';

  @override
  String svcPersonalKeySavedOnThisDeviceThe2(String p0) {
    return '個人キーは端末に保存しました。定期タスクの更新待ちです：$p0';
  }

  @override
  String get svcCheckYourNetworkAndTryAgain => 'ネットワークを確認して再試行してください';

  @override
  String get svcEnterThePersonalKey => '個人キーを入力してください';

  @override
  String get svcPersonalKeySaved => '個人キーを保存しました';

  @override
  String get svcPersonalKeySavedAndTheScheduledTask => '個人キーを保存し、定期タスクを更新しました';

  @override
  String get svcPersonalKeySavedAutoSyncStaysOff => '個人キーを保存しました。自動同期はオフのままです';

  @override
  String get svcPersonalKeyCleared => '個人キーを削除しました';

  @override
  String get svcPersonalKeyClearedAndTheMatchingAuto =>
      '個人キーを削除し、対応する自動同期をオフにしました';

  @override
  String get svcCouldNotVerifyTheTargetAccountScores =>
      '対象アカウントのスコアまたは同期認証情報を確認できませんでした。このデータソースのアカウント状態を確認してください。';

  @override
  String get svcAnAutoSyncTaskAlreadyExistsTrying =>
      '自動同期タスクはすでにあります。現在のユーザーの管理権限を復元しています。';

  @override
  String get svcNoMatchingAutoSyncTaskWasFound =>
      '一致する自動同期タスクが見つかりません。もう一度オンにしてください。';

  @override
  String get svcTheTaskIsRunningRestoreManagementAccess =>
      'タスクを実行中です。後で管理権限を復元してください。';

  @override
  String get svcTheAccountLinkedToTheTaskChanged =>
      'タスクに紐づくアカウントが変わりました。自動同期をオフにしてから、もう一度オンにしてください。';

  @override
  String get svcQuickSyncCredentialsAreIncompleteEnterA =>
      'クイック同期の認証情報が不完全です。先にQRコードを入力して筐体の本人情報を連携してください。';

  @override
  String get svcTooManyRequestsTryAgainLater => '操作が多すぎます。しばらくしてから再試行してください。';

  @override
  String get svcCouldNotReadTheSongLibraryOf =>
      '対象データソースの楽曲ライブラリを読み込めなかったため、今回の同期を中止しました。';

  @override
  String get svcScoreUploadFailedSomeBatchesMayHave =>
      'スコアのアップロードに失敗しました。一部のバッチは送信済みの可能性があります。今回は自動で再試行しません。';

  @override
  String get svcTheAWMCNETImportTokenIsInvalid =>
      'AWMC NETのImport-Tokenが無効です。「成績取り込み認証情報」で有効なトークンを保存し直してください。有効な定期タスクは自動で更新されます。';

  @override
  String get svcCouldNotReadCabinetScoresTryAgain =>
      '筐体のスコアを読み込めませんでした。しばらくしてから再試行してください。';

  @override
  String get svcTheUpstreamReturnedPagedScoresReadingStopped =>
      '上流からページ分割されたスコアが返されたため、連続リクエストを避けるため今回の読み込みを停止しました。';

  @override
  String get svcNoValidScoresSupportedByTheTarget =>
      '対象データソースが対応する有効なスコアを読み込めませんでした';

  @override
  String get svcAServiceRestartInterruptedTheLastSync =>
      'サービスの再起動で前回の同期が中断されました。次の予定時刻に再開します。';

  @override
  String get svcTheAutoSyncSettingChangedRefreshThe =>
      '自動同期の設定が変わりました。状態を更新してください。';

  @override
  String get svcThisSyncTimedOutAndStoppedIt =>
      '今回の同期処理がタイムアウトしたため停止しました。次の予定時刻に再開します。';

  @override
  String get svcAutoSyncCapacityIsFullTurnIt =>
      '自動同期の受付枠がいっぱいです。しばらくしてからオンにしてください。';

  @override
  String get svcTheUpstreamQuotaCannotBeConfirmedOr =>
      '上流の利用枠を確認できないか使い切りました。回復後にタスクを再開します。';

  @override
  String get svcTheUpstreamServiceIsUnavailableTheTask =>
      '上流サービスが利用できないため、タスクを一時停止しました。回復後に再開します。';

  @override
  String get svcThisMorningSProcessingWindowHasEnded =>
      '今回の午前の処理時間帯が終了しました。次の回で再開します。';

  @override
  String get svcTheUploadResultIsUncertainTheNext =>
      'アップロード結果が確定していません。次の回で確認してから処理します。';

  @override
  String get svcTheAutoSyncServiceIsUnavailableTry =>
      '自動同期サービスは現在利用できません。しばらくしてから再試行してください。';

  @override
  String svcSetUpTheSyncCredentialsForP0(String p0) {
    return '先に「成績取り込み認証情報」で$p0の成績取り込み Token を設定してください';
  }

  @override
  String svcSetUpYourP0AccountFirst(String p0) {
    return '先に$p0アカウントを設定してください';
  }

  @override
  String svcRefreshYourP0AccountDataBeforeUsing(String p0) {
    return 'クイック同期を使う前に$p0アカウントのデータを更新してください';
  }

  @override
  String get svcAWMCReportedSuccessWithoutAUserIdThe =>
      'AWMCは成功を返しましたがuserIdがないため、筐体の本人情報を保存していません';

  @override
  String get svcQuickSyncIsInProgressPleaseWait => 'クイック同期を実行中です。しばらくお待ちください。';

  @override
  String get svcUserCredentialsAreNotCachedEnterA =>
      'ユーザー認証情報が保存されていません。先にQRコードを入力して筐体の本人情報を連携してください。';

  @override
  String get svcUpdateTheSongLibraryBeforeUsingQuick =>
      'クイック同期を使う前に楽曲ライブラリを更新してください';

  @override
  String get svcNoValidScoresMatchedTheLocalSong =>
      '有効なスコアが端末の楽曲ライブラリと一致しなかったため、何もアップロードしていません';

  @override
  String svcTheAWMCGatewayIsUnavailableP0(String p0) {
    return 'AWMCゲートウェイは現在利用できません：$p0';
  }

  @override
  String get svcScorePagingWasAbnormalTheUpdateStopped =>
      'スコアのページ分割が異常なため、更新を中止しました';

  @override
  String get svcTheServerDoesNotOfferQuickSync =>
      'サーバーはまだクイック同期に対応していません。サーバーのプロキシを更新してください。';

  @override
  String get svcTheCurrentGatewayUpstreamCannotReadWithout =>
      '現在のゲートウェイの上流はQRコードなしの読み込みに対応していません。通常の同期を使ってください。';

  @override
  String svcQuickReadFailedP0(String p0) {
    return 'クイック読み込みに失敗しました：$p0';
  }

  @override
  String get svcTheAWMCGatewayReturnedAnInvalidScore =>
      'AWMCゲートウェイが無効なスコアのページカーソルを返しました';

  @override
  String get svcTheAWMCGatewayReturnedPagedResultsReading =>
      'AWMCゲートウェイがページ分割された結果を返したため、連続リクエストを避けるため読み込みを停止しました';

  @override
  String get svcNoValidScoresWereReadNothingWas =>
      '有効なスコアを読み込めなかったため、何もアップロードしていません';

  @override
  String svcCouldNotReadTheP0SongLibrary(String p0) {
    return '$p0の楽曲ライブラリを読み込めなかったため、スコアをアップロードしていません';
  }

  @override
  String svcTheP0SongLibraryIsEmptyNo(String p0) {
    return '$p0の楽曲ライブラリが空のため、スコアをアップロードしていません';
  }

  @override
  String svcCouldNotReadExistingP0ScoresSo(String p0) {
    return '$p0の既存スコアを読み込めなかったため、クイック同期を行っていません。先にこのソースのアカウント状態を確認してください。';
  }

  @override
  String svcP0ReturnedScoresInAnInvalidFormat(String p0) {
    return '$p0から返されたスコアの形式が無効なため、クイック同期を行っていません';
  }

  @override
  String svcP0ScoresAreMissingChartOrCombo(String p0) {
    return '$p0のスコアに譜面またはコンボ・シンクの項目がないため、クイック同期を行っていません';
  }

  @override
  String svcUploadToP0FailedHTTPP1Remaining(String p0, String p1) {
    return '$p0へのアップロードに失敗しました（HTTP $p1）。以降のバッチを停止しました。送信済みのバッチは反映されている可能性があります。';
  }

  @override
  String get svcThereAreNoFavoriteFoldersToExport =>
      'エクスポートできるお気に入りフォルダーがありません';

  @override
  String get svcChooseAChiffonMaiFavoritesFile => 'ChiffonMaiのお気に入りファイルを選択';

  @override
  String get svcCouldNotReadTheSelectedFile => '選択したファイルを読み込めませんでした';

  @override
  String svcFileNotFoundP0(String p0) {
    return 'ファイルが見つかりません：$p0';
  }

  @override
  String svcTheFavoritesFileIsTooLargeLimit(String p0) {
    return 'お気に入りファイルが大きすぎます（上限 $p0 MB）';
  }

  @override
  String get svcThisFileIsNotInTheChiffonMai =>
      'このファイルはChiffonMaiのお気に入り形式ではありません。\n（旧バージョンの.txtテキスト一覧には楽曲IDがないため復元できません。もう一度エクスポートしてください）';

  @override
  String get svcTheFileIsNotValidJSONAnd =>
      'ファイルの内容が正しいJSONではありません。破損している可能性があります';

  @override
  String svcTheFileFormatTagIsP0Not(String p0) {
    return 'ファイル形式の識別子は「$p0」で、ChiffonMaiのお気に入りファイルではありません';
  }

  @override
  String get svcTheFileContentCouldNotBeRecognized => 'ファイルの内容を認識できません';

  @override
  String get svcTheFileHasNoFavoritesData => 'ファイルにお気に入りのデータがありません';

  @override
  String get svcTheFileIsMissingTheFoldersField => 'ファイルにfolders項目がありません';

  @override
  String get svcTheFileIsEmpty => 'ファイルが空です';

  @override
  String get svcTheBackupExceedsThe50MBLimit =>
      'バックアップが50 MBの上限を超えています。カスタム譜面のアーカイブを減らしてから再試行してください。';

  @override
  String svcTheBackupFileIsTooLargeLimit(String p0) {
    return 'バックアップファイルが大きすぎます（上限 $p0 MB）';
  }

  @override
  String get svcInvalidBackupFileMissingTheDataField =>
      '無効なバックアップファイルです：data項目がありません';

  @override
  String get svcInvalidBackupFileMissingTheVersionField =>
      '無効なバックアップファイルです：version項目がありません';

  @override
  String get svcUnsupportedBackupVersionOrAppFormat =>
      '対応していないバックアップのバージョンまたはアプリ形式です';

  @override
  String get svcTheBackupFileIsEmptyThereIs => 'バックアップファイルが空のため、復元するデータがありません';

  @override
  String get svcADataRestoreIsAlreadyInProgress => 'データの復元はすでに実行中です';

  @override
  String get svcSecureCredentialsHaveNotFinishedMigratingTry =>
      '安全な認証情報の移行がまだ完了していません。しばらくしてから復元を再試行してください。';

  @override
  String get svcCouldNotClearTheOldSettings => '古い設定を消去できませんでした';

  @override
  String svcCouldNotWriteTheBackupSettingP0(String p0) {
    return 'バックアップ設定を書き込めませんでした：$p0';
  }

  @override
  String get svcTheBackupHasNoUserSettingsTo =>
      'バックアップに復元できるユーザー設定がないため、現在のデータを残しました';

  @override
  String get svcSignInAndLinkYourDivingFish => '先にログインして水魚のQQを連携してください';

  @override
  String get svcTheCurrentDivingFishUserHasNo =>
      '現在の水魚ユーザーにはプレイデータがありません。先にデータを更新してください。';

  @override
  String get svcNoPlayDataWasFoundForThis =>
      'このフレンドのプレイデータが見つかりません。QQ番号が正しいか確認してください。';

  @override
  String get svcAddYourAWMCNETQQNumberIn =>
      '先に「連携と認証の管理」でAWMC NETのQQ番号を連携してください';

  @override
  String get svcSignInToYourLXNSAccountFirst => '先に落雪アカウントにログインしてください';

  @override
  String get svcCouldNotReadYourLXNSScoresTry =>
      'あなたの落雪スコアを読み込めませんでした。しばらくしてから再試行してください。';

  @override
  String get svcTheSongLibraryHasNotLoadedYet =>
      '楽曲ライブラリがまだ読み込まれていません。しばらくしてから再試行してください。';

  @override
  String get svcTheFriendCodeMustContainOnlyDigits =>
      'フレンドコードは数字のみです。確認して再試行してください。';

  @override
  String svcCouldNotLookUpTheFriendS(String p0) {
    return 'フレンドのスコアを取得できませんでした（HTTP $p0）';
  }

  @override
  String get svcNoLXNSScoresForThisFriendThey =>
      'このフレンドの落雪スコアがありません。フレンドがChiffonMaiのランキングに参加し、データを更新している必要があります。';

  @override
  String get svcChooseAtLeastOneResultScreenImage => '先にリザルト画面の画像を1枚以上選択してください';

  @override
  String svcUpToP0ImagesCanBeRecognized(String p0, String p1) {
    return '一度に認識できるのは$p0枚までです（現在$p1枚選択中）';
  }

  @override
  String svcP0ExceedsThe8MiBLimitP1(String p0, String p1) {
    return '$p0は8 MiBの上限を超えています（$p1 MiB）';
  }

  @override
  String get svcNotSignedInToMaimaiScoreHub2 =>
      'maimai Score Hubにログインしていないため、この認識サービスは使えません';

  @override
  String svcNoImagesOrTooManyImagesP0(String p0) {
    return '画像がないか、枚数が上限を超えています$p0';
  }

  @override
  String get svcYourSignInHasExpiredSignIn =>
      'ログイン状態の有効期限が切れました。maimai Score Hubにもう一度ログインしてください。';

  @override
  String get svcAnImageExceedsThe8MiBLimit => '8 MiBの上限を超える画像があります';

  @override
  String get svcUnsupportedImageFormatOnlyJPEGPNGWebP =>
      '対応していない画像形式です（JPEG / PNG / WebPのみ）';

  @override
  String get svcTheOCRServiceReturnedAResultThat => 'OCRサービスが解析できない結果を返しました';

  @override
  String get svcTheOCRServiceIsUnavailableTryAgain =>
      'OCRサービスは現在利用できません。しばらくしてから再試行してください。';

  @override
  String get svcOCRRecognitionTimedOutTryAgainLater =>
      'OCR認識がタイムアウトしました。しばらくしてから再試行してください。';

  @override
  String svcRecognitionFailedHTTPP0P1(String p0, String p1) {
    return '認識に失敗しました（HTTP $p0）$p1';
  }

  @override
  String get svcAccountDataIsUpdatingTryAgainWhen =>
      'アカウントデータを更新中です。完了してから再試行してください。';

  @override
  String get svcCouldNotSaveAccountRecoveryInformation =>
      'アカウントの復元情報を保存できませんでした';

  @override
  String get svcTheAccountChangedSoTheDataRefresh =>
      'アカウントが切り替わったため、今回の同期後のデータ更新をスキップしました';

  @override
  String get svcTheReturnedDataBelongsToAnotherAccount =>
      '返されたデータは別のアカウントのものなので、今回の自動更新を取り消しました';

  @override
  String get svcCouldNotRollBackTheAccountArchive => 'アカウントの保存データを元に戻せませんでした';

  @override
  String get svcCouldNotIdentifyTheAccountToRestore => '復元するアカウントを特定できませんでした';

  @override
  String get svcCouldNotSaveHistoryMigrationInformation => '履歴の移行情報を保存できませんでした';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit =>
      'ユーザーファイルがバックアップの容量上限を超えています。カスタム譜面のアーカイブを減らしてから再試行してください。';

  @override
  String get svcTheUserFilesInTheBackupHave => 'バックアップ内のユーザーファイルの形式が無効です';

  @override
  String get svcInvalidUserFileEntry => 'ユーザーファイルの項目が無効です';

  @override
  String get svcInvalidUserFilePath => 'ユーザーファイルのパスが無効です';

  @override
  String get svcInvalidUserFileContent => 'ユーザーファイルの内容が無効です';

  @override
  String get svcUserFilesExceedTheBackupSizeLimit2 =>
      'ユーザーファイルがバックアップの容量上限を超えています';

  @override
  String get svcTheUserFileFolderCannotBeA => 'ユーザーファイルのフォルダーをシンボリックリンクにはできません';

  @override
  String get svcUserFilesCannotBeSymbolicLinks => 'ユーザーファイルをシンボリックリンクにはできません';

  @override
  String get svcCouldNotWriteTheAccountArchive => 'アカウントの保存データを書き込めませんでした';

  @override
  String get svcTheAccountArchiveHasAnInvalidFormat => 'アカウントの保存データの形式が無効です';

  @override
  String get svcCouldNotRestoreTheAccountArchive => 'アカウントの保存データを復元できませんでした';

  @override
  String svcRefreshTheTargetP0AccountSData(String p0) {
    return 'その連携アカウントのコンボ・シンクの記録を残すため、先に$p0の対象アカウントのデータを更新してください';
  }

  @override
  String svcTheP0ScoreCacheIsInvalidRefresh(String p0) {
    return '$p0のスコアキャッシュが無効です。先にデータを更新してください。';
  }

  @override
  String svcLoadedP0FromTheLocalCache(String p0) {
    return 'ローカルキャッシュから$p0を読み込みました';
  }

  @override
  String get svcAudio => '音声';

  @override
  String get svcAudioFile => '音声ファイル';

  @override
  String svcDownloadingP0(String p0) {
    return '$p0をダウンロード中…';
  }

  @override
  String get svcTheResponseIsNotAMediaFile => '応答はメディアファイルではありません';

  @override
  String get svcTheMediaFileIsIncompleteOrHas => 'メディアファイルが不完全か形式が無効です';

  @override
  String get svcFileCached => 'ファイルをキャッシュしました';

  @override
  String svcMediaDownloadFailedP0(String p0) {
    return 'メディアのダウンロードに失敗しました：$p0';
  }

  @override
  String svcP0AddedP1UpdatedP2SkippedP3(
      String p0, String p1, String p2, String p3) {
    return '追加 $p0 件 · 更新 $p1 件 · スキップ $p2 件（筐体全体 $p3 件）';
  }

  @override
  String get svcTheAWMCNETScoreImportTokenHas =>
      'AWMC NETのスコアインポートトークンがまだ設定されていません';

  @override
  String get svcPasteOrScanTheCabinetSignIn =>
      '先に筐体のログイン用QRコードを貼り付けるかスキャンしてください';

  @override
  String svcRefusedARequestToANonAWMC(String p0) {
    return 'AWMC NET以外のアドレスへのリクエストを拒否しました：$p0';
  }

  @override
  String svcImportTimedOutAfterP0SecondsLarge(String p0) {
    return 'インポートがタイムアウトしました（$p0秒待機）。筐体のデータが多いと時間がかかります。しばらくしてから再試行してください。';
  }

  @override
  String svcCouldNotConnectToAWMCNETP0(String p0) {
    return 'AWMC NETに接続できませんでした：$p0';
  }

  @override
  String get svcAWMCNETReturnedUnrecognizedData => 'AWMC NETが認識できないデータを返しました';

  @override
  String svcCouldNotParseTheAWMCNETResponse(String p0) {
    return 'AWMC NETの応答を解析できませんでした：$p0';
  }

  @override
  String get svcTheAWMCNETImportTokenIsInvalid2 =>
      'AWMC NETのインポートトークンが無効です。net.wmc.pubの設定ページ最下部で再生成してください。';

  @override
  String get svcTheAWMCNETImportTokenIsMissing => 'AWMC NETのインポートトークンがありません';

  @override
  String get svcTheCabinetQRCodeIsInvalidOr =>
      '筐体のQRコードが無効か期限切れです。公式アカウントまたは筐体で取得し直してから再試行してください。';

  @override
  String svcAWMCNETRejectedTheRequestP0(String p0) {
    return 'AWMC NETがリクエストを拒否しました：$p0';
  }

  @override
  String get svcInvalidParameters => 'パラメーターが不正です';

  @override
  String svcTooManyAWMCNETRequestsTryAgain(String p0) {
    return 'AWMC NETへのリクエストが多すぎます。しばらくしてから再試行してください。\n$p0';
  }

  @override
  String svcAWMCNETChimeUserReadFailed(String p0) {
    return '筐体のスコアを取得できませんでした：Chimeがユーザーを取得できません（コード3002、HTTP $p0）。新しいQRコードで再試行してください。解決しない場合は時間をおくか、連携済みの筐体IDでクイック同期をお試しください。';
  }

  @override
  String svcAWMCNETServerErrorHTTPP0Try(String p0) {
    return 'AWMC NETのサーバーでエラーが発生しました（HTTP $p0）。しばらくしてから再試行してください。';
  }

  @override
  String svcAWMCNETReturnedHTTPP0(String p0) {
    return 'AWMC NETがHTTP $p0を返しました';
  }

  @override
  String get svcNoDivingFishImportTokenYetSign =>
      '水魚のImport-Tokenがまだありません。先に水魚アカウントにログインしてください。';

  @override
  String svcCouldNotConnectToDivingFishP0(String p0) {
    return '水魚に接続できませんでした：$p0';
  }

  @override
  String get svcTheImportTokenIsWrongOrThe =>
      'インポートトークンが誤っているか、リクエストの形式が正しくありません';

  @override
  String get svcYourSignInIsInvalidSignIn => 'ログイン状態が無効です。水魚にもう一度ログインしてください。';

  @override
  String svcSyncFailedHTTPP0P1(String p0, String p1) {
    return '同期に失敗しました（HTTP $p0）$p1';
  }

  @override
  String get svcDivingFishDidNotAcceptThisScore =>
      '水魚はこのスコアを受け付けませんでした（楽曲が一致しないか、その難易度が存在しません）。曲名と難易度を確認してください。';

  @override
  String get svcUTAGEChartsCannotBeSyncedLXNSDifficulty =>
      '宴譜面は同期できません：落雪の難易度インデックスは宴に対応していません';

  @override
  String svcDifficultyIndexP0IsOutsideTheLXNS(String p0) {
    return '難易度インデックス$p0は落雪の範囲（0–4）外です';
  }

  @override
  String get svcYourLXNSAccountIsNotAuthorizedComplete =>
      '落雪アカウントが認証されていません。「連携と認証の管理」でOAuth認証を完了するか、OCR画面の落雪ステータスバーに個人APIキーを貼り付けてください。';

  @override
  String svcCouldNotConnectToLXNSP0(String p0) {
    return '落雪に接続できませんでした：$p0';
  }

  @override
  String get svcLXNSAuthorizationExpiredOrTheKeyIs =>
      '落雪の認証が切れたか、キーが無効です。もう一度認証するかキーを貼り付けてください。';

  @override
  String get svcLXNSRejectedThisWriteInsufficientPermissions =>
      '落雪がこの書き込みを拒否しました（権限不足）';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatDataIs => '落雪の応答形式が異常です：dataが空です';

  @override
  String get svcLXNSReturnedAnUnexpectedFormatData0 =>
      '落雪の応答形式が異常です：data[0]がオブジェクトではありません';

  @override
  String get svcThisUserHasNotAuthorizedTheApp =>
      'このユーザーはまだアプリを認可していません。連携を完了してから再試行してください。';

  @override
  String get svcAuthenticationFailedTryAgain => '認証に失敗しました。再試行してください。';

  @override
  String get svcNoPermissionToAccessThisUserS => 'このユーザーのデータにアクセスする権限がありません';

  @override
  String get svcTodaySQueryLimitHasBeenReached =>
      '本日の問い合わせ回数の上限に達しました。しばらくしてから再試行してください。';

  @override
  String svcRequestFailedStatusCodeP0(String p0) {
    return 'リクエストに失敗しました（ステータスコード $p0）';
  }

  @override
  String get svcConnectionCancelled => '接続をキャンセルしました';

  @override
  String get svcDisconnectedReconnectAndTryAgain =>
      '接続が切れました。再接続してから再試行してください。';

  @override
  String get svcDisconnectedTheCoverReadyStatusWasNot =>
      '接続が切れたため、ジャケットの準備状態を送信できませんでした';

  @override
  String get svcDisconnectedThisGuessWasNotSubmittedReconnect =>
      '接続が切れたため、今回の回答は送信されていません。再接続してから再試行してください。';

  @override
  String get svcDisconnectedReconnectBeforeLeavingTheRoom =>
      '接続が切れました。再接続してからルームを退出してください。';

  @override
  String get svcEnterAQQNumber => 'QQ番号を入力してください';

  @override
  String svcAWMCNETQueryTimedOutP0S(String p0) {
    return 'AWMC NETの問い合わせがタイムアウトしました（$p0秒）。ネットワークを確認して再試行してください。';
  }

  @override
  String svcAWMCNETConnectionFailedP0(String p0) {
    return 'AWMC NETへの接続に失敗しました：$p0';
  }

  @override
  String svcAWMCNETReturnedDataThatCouldNot(String p0) {
    return 'AWMC NETが解析できないデータを返しました：$p0';
  }

  @override
  String get svcAWMCNETReturnedAnUnrecognizedDataStructure =>
      'AWMC NETが認識できないデータ構造を返しました（recordsがありません）';

  @override
  String svcAWMCNETHasNoDataForQQ(String p0) {
    return 'AWMC NETにQQ $p0のデータがありません。\nこのQQがnet.wmc.pubで連携され、スコアをアップロード済みか確認してください。';
  }

  @override
  String svcTheAWMCNETDeveloperKeyIsInvalid(String p0) {
    return 'AWMC NETの開発者キーが無効か期限切れです（HTTP $p0）';
  }

  @override
  String svcAWMCNETReturnedAnUnknownStatusHTTP(String p0, String p1) {
    return 'AWMC NETが不明なステータスを返しました：HTTP $p0$p1';
  }

  @override
  String svcInvalidQQNumber512DigitsExpected(String p0) {
    return 'QQ番号の形式が正しくありません（5～12桁の数字）：$p0';
  }

  @override
  String svcAWMCNETHasNoDataForQQ2(String p0) {
    return 'AWMC NETにQQ $p0のデータがありません（net.wmc.pubで連携され、スコアをアップロード済みか確認してください）';
  }

  @override
  String get svcAWMCNETRejectedTheRequestDaysIs =>
      'AWMC NETがリクエストを拒否しました：daysが範囲外です（1～365）';

  @override
  String svcAWMCNETReturnedJSONThatCouldNot(String p0) {
    return 'AWMC NETが解析できないJSONを返しました：$p0';
  }

  @override
  String get svcTheAWMCNETResponseHasNoPoints => 'AWMC NETの応答にpoints配列がありません';

  @override
  String svcP0MsOfflineMode(String p0) {
    return '$p0 ms（オフラインモード）';
  }

  @override
  String get svcLoadingTheSongAliasDatabase => '楽曲の別名データベースを読み込み中...';

  @override
  String get svcInitializingTheMaidataManager => 'maidataマネージャーを初期化中...';

  @override
  String get svcFetchingAllMaidataTheFirstLoadMay =>
      'すべてのmaidataを取得中...\n（初回は時間がかかる場合があります。しばらくお待ちください）';

  @override
  String get svcLoadingMaidataFromCache => 'キャッシュからmaidataを読み込み中...';

  @override
  String get svcSyncingSongInfoAndDifficultyData => '楽曲情報と難易度データを同期中...';

  @override
  String get svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd =>
      'コレクション、タグ、楽曲、ナレッジベースなどのデータを読み込み中...';

  @override
  String get svcBuildingSongMappings => '楽曲の対応関係を作成中...';

  @override
  String get svcTheExportCanvasIsNotReady => 'エクスポート用キャンバスの準備ができていません';

  @override
  String get svcDiscoveringBaseMaidata => '基本のmaidataを検出中…';

  @override
  String svcFetchingMaidataP0P1(String p0, String p1) {
    return 'maidataを取得中：$p0/$p1';
  }

  @override
  String svcFoundP0MaidataFiles(String p0) {
    return '$p0件のmaidataを検出しました';
  }

  @override
  String get svcTheLogWasExportedAutomaticallyYouCan =>
      'ログは自動でエクスポートされました。開発者に送って調査に使えます。';

  @override
  String get svcLogExportFailedYouCanExportIt =>
      'ログのエクスポートに失敗しました。「ログを出力」から手動でエクスポートできます。';

  @override
  String get svcTheGatewayCouldNotReachItsOrigin =>
      'ゲートウェイがオリジンに接続できませんでした。CDNが不正なヘッダーのエラーページ（SpeedOnline）を返しました。通常はゲートウェイ／オリジンのタイムアウトなので、しばらくしてから再試行してください。';

  @override
  String svcRequestFailedP0(String p0) {
    return 'リクエストに失敗しました：$p0';
  }

  @override
  String get svcSuccess => '成功';

  @override
  String get svcTheServerHasNoAWMCDeveloperKey =>
      'サーバーにAWMC開発者キーが設定されていません。管理者に連絡してください。';

  @override
  String get svcHTTP401TokenMissingOrInvalid => 'HTTP 401：トークンがないか無効です';

  @override
  String get svcHTTP403InsufficientBalanceRedeemTokensIn =>
      'HTTP 403：残高不足です。先にコンソールでトークンを交換してください。';

  @override
  String svcHTTPP0TheGatewayOrUpstreamFailed(String p0) {
    return 'HTTP $p0：ゲートウェイまたは上流の転送に失敗しました';
  }

  @override
  String svcUsedP0Tokens(String p0) {
    return '今回の消費：$p0 トークン';
  }

  @override
  String get svcTheRequestDidNotSucceedNoTokens =>
      '処理が成功しなかったため、公式ルールによりトークンは消費されません';

  @override
  String get svcCouldNotReadTheRefreshSettingsRefresh =>
      '更新設定を読み込めませんでした。手動でデータを更新してください。';

  @override
  String get svcTheRefreshSourceDiffersFromTheSync =>
      '更新元が同期先と異なるため、自動更新をスキップしました';

  @override
  String get svcTheRefreshAccountDiffersFromTheSync =>
      '更新するアカウントが同期先と異なるため、自動更新をスキップしました';

  @override
  String get svcTheAccountOrSyncCredentialsChangedAutomatic =>
      'アカウントまたは同期の認証情報が変わったため、自動更新をスキップしました';

  @override
  String get svcCouldNotLoadTheGateListRight => '扉の一覧を現在読み込めません';

  @override
  String get svcCouldNotLoadTheGuideRightNow => '攻略を現在読み込めません';

  @override
  String get svcTheGuideDataDoesNotMatch => '攻略データが一致しません';

  @override
  String get svcReadAndAcceptTheUserAgreementAnd =>
      '先に利用規約とプライバシーポリシーを読んで同意してください';

  @override
  String get svcCouldNotSaveTheOnboardingConfirmationTry =>
      'ガイドの確認記録を保存できませんでした。再試行してください。';

  @override
  String get svcCreatingTheRoomTimedOutCheckYour =>
      'ルームの作成がタイムアウトしました。接続を確認して再試行してください。';

  @override
  String get svcJoiningTheRoomTimedOutCheckThe =>
      'ルームへの参加がタイムアウトしました。ルームコードとネットワークを確認してください。';

  @override
  String svcCouldNotLoadReleaseDataP0(String p0) {
    return '配信データを読み込めませんでした（$p0）';
  }

  @override
  String get svcInvalidReleaseData => '配信データが無効です';

  @override
  String get svcInvalidFriendLinkDataFormat => 'リンク集のデータ形式が正しくありません';

  @override
  String get svcSaveFailed => '保存に失敗しました';

  @override
  String svcCouldNotParseTheRecognitionResultJSON(String p0) {
    return '認識結果のJSONを解析できませんでした：$p0';
  }

  @override
  String svcRecognitionRequestFailedP0(String p0) {
    return '認識リクエストに失敗しました：$p0';
  }

  @override
  String get gainBelowS => 'S未満';

  @override
  String gainRaiseTo(String p0) {
    return '$p0へ到達';
  }

  @override
  String gainWithinGrade(String p0) {
    return '$p0内でスコアアップ';
  }

  @override
  String gainBasisMember(String p0, String p1, String p2, String p3) {
    return '$p0；$p1内の単曲RA $p2→$p3';
  }

  @override
  String gainBasisReplace(
      String p0, String p1, String p2, String p3, String p4) {
    return '$p0；RA $p1で$p2最下位の「$p3」（RA $p4）と入れ替わり';
  }

  @override
  String gainBasisFill(String p0, String p1, String p2) {
    return '$p0；RA $p1で$p2の空き枠に入る';
  }

  @override
  String gainNetGainReason(String p0, String p1) {
    return '単独での純増 +$p0（$p1）';
  }

  @override
  String gainExploreReason(String p0, String p1) {
    return '同じ定数帯での自己ベストの中央値 $p0% · 単独での純増 +$p1（条件付きの推定で、次回の成功率ではありません）';
  }

  @override
  String gainAlternativeChallenge(String p0, String p1) {
    return '；チャレンジ候補 $p0%（単独での純増 +$p1、堅実目標とは合算しません）';
  }

  @override
  String gainFillNoteExhausted(String p0) {
    return '未表示の対象候補 $p0件、すべて表示済み';
  }

  @override
  String gainFillNoteFiltered(String p0) {
    return '未表示の対象候補 $p0件、残りはフィードバックや条件で除外';
  }

  @override
  String get accountAuthorizeLXNS => 'LXNS アカウント認証';

  @override
  String get accountLinkAWMC => 'AWMC NET アカウントを連携';

  @override
  String get accountSwitchCachedSubtitle => 'ローカルキャッシュでデータソースとプレイヤーを切り替え';

  @override
  String get accountAuthorizeLXNSSubtitle => 'LXNS の成績読み取り認証を管理';

  @override
  String get accountLinkAWMCSubtitle => 'AWMC NET の成績照会用 QQ ID を設定';

  @override
  String get accountCabinetIdentitySubtitle => 'クイック同期で共有する筐体 ID を連携';

  @override
  String get accountAuthorizeLXNSFirst =>
      '「マイページ → アカウントと認証 → 連携と認証の管理」で落雪を認証してください。';

  @override
  String get accountLinkAWMCFirst =>
      '「マイページ → アカウントと認証 → 連携と認証の管理」で AWMC NET の QQ ID を設定してください。';

  @override
  String get accountConfigurationSaved => 'アカウント設定を保存しました。データを更新すると成績が反映されます。';

  @override
  String get accountAuthorizationFailed =>
      '認証または保存に失敗しました。接続と入力内容を確認して再試行してください。';

  @override
  String get accountLXNSAuthorized => 'LXNS アカウント認証済み';

  @override
  String get accountLXNSAuthorizedSubtitle => '認証済みです。成績を更新できます。タップして再認証します。';

  @override
  String get accountAWMCLinked => 'AWMC NET アカウント連携済み';

  @override
  String accountAWMCLinkedSubtitle(String qq) {
    return '連携済み QQ：$qq。タップしてアカウントを変更します。';
  }

  @override
  String get accountCabinetLinkedSubtitle => 'クイック同期用 ID を保存済みです。タップして再連携します。';

  @override
  String get accountBindingManage => '連携と認証の管理';

  @override
  String get accountBindingManageSubtitle => '各データソースのログイン・認証・連携を管理';

  @override
  String get accountBindingScoreHub => 'maimai Score Hub';

  @override
  String get accountBindingDivingFish => '水魚';

  @override
  String get accountBindingLxns => '落雪';

  @override
  String get accountBindingAwmc => 'AWMC NET';

  @override
  String get accountBindingCabinet => '筐体 ID';

  @override
  String get accountBindingSignedIn => 'ログイン済み';

  @override
  String get accountBindingSignedOut => '未ログイン';

  @override
  String get accountBindingAuthorized => '認証済み';

  @override
  String get accountBindingUnauthorized => '未認証';

  @override
  String get accountBindingLinked => '連携済み';

  @override
  String get accountBindingUnlinked => '未連携';

  @override
  String get accountBindingDivingFishAuth => '水魚認証';

  @override
  String get accountBindingUnknown => '不明';

  @override
  String get accountBindingRecheck => '再確認';

  @override
  String get syncDialogMode => '同期方法';

  @override
  String get syncDialogQrCode => '筐体 QR コード';

  @override
  String get languageTranslationDisclaimer =>
      '簡体字中国語以外の表示は翻訳であり、不正確または不自然な表現を含む場合があります。意味が異なる場合は簡体字中国語の表記が優先されます。楽曲情報、サーバーからの原文、ユーザーのコンテンツは翻訳されません。翻訳の問題は「フィードバック」からお知らせください。';

  @override
  String get accountSwitchSaved => 'アカウント保存済み';

  @override
  String get accountSwitchNotSaved => 'アカウント未保存';

  @override
  String get accountSwitchCurrent => '使用中';

  @override
  String get customTagTitle => 'カスタムタグ';

  @override
  String get customTagFeatureSubtitle => '名前・色・譜面を自由に決めたタグ。タグ絞り込みや統計で使えます';

  @override
  String get customTagGroupName => 'カスタム';

  @override
  String get customTagIntro =>
      'カスタムタグは譜面タグと同様に、楽曲検索のタグ絞り込み、譜面詳細、Best50・お気に入りのタグ統計、個性化 Best50 の「タグ50」に表示されます。この端末にのみ保存され、データバックアップに含まれます。';

  @override
  String get customTagCreate => '新規タグ';

  @override
  String get customTagEdit => 'タグを編集';

  @override
  String get customTagName => 'タグ名';

  @override
  String get customTagColor => 'タグの色';

  @override
  String get customTagHue => '色相';

  @override
  String get customTagPreview => 'プレビュー';

  @override
  String get customTagNameRequired => 'タグ名を入力してください';

  @override
  String get customTagNameDuplicate => '同じ名前のタグがあります';

  @override
  String get customTagSaveFailed => 'カスタムタグを保存できませんでした。もう一度お試しください';

  @override
  String get customTagForChart => 'この譜面のカスタムタグ';

  @override
  String get customTagEmpty => 'カスタムタグはまだありません。まず作成しましょう。';

  @override
  String get customTagAddToChart => 'カスタムタグを追加';

  @override
  String get customTagManage => '管理';

  @override
  String get customTagSearchHint => '曲名・別名・アーティスト・ID で検索';

  @override
  String get customTagNoSongs => '楽曲が見つかりません';

  @override
  String get customTagChooseDifficulties => '難易度を選択';

  @override
  String get customTagAddCharts => '譜面を追加';

  @override
  String get customTagRemoveChart => 'このタグから外す';

  @override
  String get customTagDelete => '削除';

  @override
  String get customTagDeleteTitle => 'タグを削除';

  @override
  String customTagChartCount(int count) {
    return '$count 譜面';
  }

  @override
  String customTagDeleteMessage(String name) {
    return '「$name」を削除すると、すべての譜面から外れ、元に戻せません。';
  }

  @override
  String accountSwitchCurrentLabel(String name) {
    return '現在：$name';
  }

  @override
  String customTagMarked(String name) {
    return '$name（カスタム）';
  }

  @override
  String get chartCodeFont => 'コードフォント';

  @override
  String get chartCodeFontDefault => 'デフォルト';

  @override
  String get chartCodeFontSaveFailed => 'フォントは変更しましたが、選択を保存できませんでした';
}
