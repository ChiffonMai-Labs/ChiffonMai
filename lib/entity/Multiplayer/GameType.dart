import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
enum GameType {
  info, // 无提示猜歌
  cover, // 根据部分曲绘猜歌
  blurred, // 根据模糊曲绘猜歌
  reverseAudio, // 倒放音频
  pitchAudio, // 变速变调
  audio, // 根据歌曲片段猜歌
  alia, // 根据别名猜歌
  letters, // 舞萌开字母
  flash, // 曲绘快闪
  tileReveal, // 曲绘拼图
  chartPeek, // 谱面片段
  pixelated, // 像素马赛克曲绘
}

extension GameTypeExtension on GameType {
  /// 仅用于界面显示，name 与 apiKey 保留原值以兼容旧房间。
  String get localizedName => appLocalizeLabel(name);
  String get localizedDescription => appLocalizeLabel(description);

  bool get isAudio =>
      this == GameType.audio ||
      this == GameType.reverseAudio ||
      this == GameType.pitchAudio;

  /// 用于 API 通信的英文字段名
  /// (info, cover, blurred, pixelated, audio, alia, letters, flash, tileReveal, chartPeek)
  ///
  /// 注意 flash / tileReveal / chartPeek 用的是 camelCase：服务端只做透传，
  /// 客户端 RoomEntity._parseGameType 同时认 camelCase 与中文显示名。
  String get apiKey {
    switch (this) {
      case GameType.info:
        return 'info';
      case GameType.cover:
        return 'cover';
      case GameType.blurred:
        return 'blurred';
      case GameType.pixelated:
        return 'pixelated';
      case GameType.reverseAudio:
        return 'reverseAudio';
      case GameType.pitchAudio:
        return 'pitchAudio';
      case GameType.audio:
        return 'audio';
      case GameType.alia:
        return 'alia';
      case GameType.letters:
        return 'letters';
      case GameType.flash:
        return 'flash';
      case GameType.tileReveal:
        return 'tileReveal';
      case GameType.chartPeek:
        return 'chartPeek';
    }
  }

  /// 用于 UI 显示的中文名
  String get name {
    switch (this) {
      case GameType.info:
        return appL10n.featureNoClueSongQuiz;
      case GameType.cover:
        return appL10n.flowCoverGuessing;
      case GameType.blurred:
        return appL10n.flowBlurredCover;
      case GameType.pixelated:
        return appL10n.flowPixelCover;
      case GameType.reverseAudio:
        return appL10n.flowReverseAudio;
      case GameType.pitchAudio:
        return appL10n.flowSpeedPitch;
      case GameType.audio:
        return appL10n.flowSongExcerpt;
      case GameType.alia:
        return appL10n.flowAliasGuessing;
      case GameType.letters:
        return appL10n.flowRevealLetters;
      case GameType.flash:
        return appL10n.flowFlashCover;
      case GameType.tileReveal:
        return appL10n.flowTileReveal;
      case GameType.chartPeek:
        return appL10n.flowChartExcerpt;
    }
  }

  String get description {
    switch (this) {
      case GameType.info:
        return appL10n.flowGuessTheSongFromItsInformation;
      case GameType.cover:
        return appL10n.flowGuessTheSongFromACoverFragment;
      case GameType.blurred:
        return appL10n.flowGuessTheSongFromABlurredCover;
      case GameType.pixelated:
        return appL10n.flowGuessTheSongFromPixelBlocksAnd;
      case GameType.reverseAudio:
        return appL10n.flowGuessTheSongFromAReversedExcerpt;
      case GameType.pitchAudio:
        return appL10n.flowGuessFromAnExcerptWithLinkedSpeed;
      case GameType.audio:
        return appL10n.flowGuessTheSongFromAnAudioExcerpt;
      case GameType.alia:
        return appL10n.flowGuessTheSongFromAnAlias;
      case GameType.letters:
        return appL10n.flowGuessTheSongFromInitialLetters;
      case GameType.flash:
        return appL10n.flowRememberABrieflyFlashedCoverToGuess;
      case GameType.tileReveal:
        return appL10n.flowCoverTilesAreRevealedInBatches;
      case GameType.chartPeek:
        return appL10n.flowGuessFromASilentChartExcerpt;
    }
  }
}
