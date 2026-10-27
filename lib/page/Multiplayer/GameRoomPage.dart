import '../../service/GuessChartGame/GuessAudioService.dart';
import '../../widgets/GuessBpmHistoryFields.dart';
import '../../widgets/GuessOriginalAudioCard.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:simai_flutter/simai_flutter.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/RoomEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameStateEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/PlayerEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GuessRecord.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameType.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/entity/GuessChartGame/GuessSong.dart';
import 'package:my_first_flutter_app/manager/MaidataManager.dart';
import 'package:my_first_flutter_app/manager/MultiplayerManager.dart';
import 'package:my_first_flutter_app/manager/SongAliasManager.dart';
import 'package:my_first_flutter_app/page/GuessChartGame/GuessChartByChartPeekPage.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/GuessChartByInfoService.dart';
import 'package:my_first_flutter_app/service/SongSearchService.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import 'package:my_first_flutter_app/utils/GameSeedUtil.dart';
import 'package:my_first_flutter_app/utils/LuoXueSongUtil.dart';
import 'package:my_first_flutter_app/widgets/TileRevealImage.dart';
import '../../widgets/MultiplayerRoomOverview.dart';

class GameRoomPage extends StatefulWidget {
  final RoomEntity room;

  const GameRoomPage({super.key, required this.room});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  final MultiplayerManager _manager = MultiplayerManager();
  RoomEntity? _currentRoom;
  GameStateEntity? _gameState;
  PlayerEntity? _currentPlayer;
  String? _initializationError;
  bool _isLeaving = false;
  bool _leaveDialogOpen = false;
  bool _canPopAfterLeave = false;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  Timer? _searchTimer;
  int _searchGeneration = 0;
  int _targetSongLoadGeneration = 0;
  static const Duration _searchDelay = Duration(milliseconds: 800);
  bool _showSearchResults = false;

  // 猜测历史
  bool _isSubmitting = false;

  // 搜索中状态（与单人猜歌页一致，用于显示转圈提示）
  bool _isSearching = false;

  // 歌曲别名管理器
  late SongAliasManager _songAliasManager;

  // 目标歌曲（用于本地判定）
  Song? _targetSong;

  // 倒计时相关
  int _remainingTime = 0;
  Timer? _countdownTimer;

  // 回合结束原因
  DateTime? _roundDeadline;
  int _modeGeneration = 0;
  final Map<String, Future<GuessSong?>> _guessDetails = {};
  bool _audioLoading = false;
  bool _actionPending = false;
  String? _pendingAction, _pendingSongId, _pendingLetter;
  bool? _requestedReady;
  Timer? _actionTimer;

  // 当前玩家是否已投降
  bool _hasSurrendered = false;

  // 房主变更提示消息
  String? _hostChangeMessage;

  // 游戏是否已结算（房主点击结算后变为true）

  // ==================== 模式专属状态 ====================
  // 开字母输入（letters 模式，房间共享进度）
  final TextEditingController _openLetterController = TextEditingController();

  // 曲绘截取参数 (cover 模式，基于种子确定性生成)
  CropRect? _cropRect;
  ImageProvider? _croppedCoverProvider;

  // 音频播放相关 (audio 模式)
  bool _isPlaying = false;
  bool _hasPlayed = false;
  int? _audioStartTime;
  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  Timer? _playbackTimer;
  AudioPlayer? _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;

  // 曲绘快闪相关 (flash 模式)
  bool _flashVisible = false;
  Timer? _flashTimer;

  // 曲绘拼图相关 (tileReveal 模式)
  // 揭示顺序由确定性种子生成，所有玩家看到同一批块被揭示。
  List<int> _tileRevealOrder = const [];
  int _revealedTileCount = 0;
  Timer? _tileRevealTimer;
  bool _tileRevealPaused = false;

  // 谱面片段相关 (chartPeek 模式)
  // 与单人谱面片段猜歌同一套口径：难度池 ∩ 房间定数范围 → 确定性挑一个难度，
  // 片段窗口也用确定性种子，保证所有玩家看到同一段谱面。
  SimaiPlayerController? _peekController;
  double _peekClipStart = 0.0;
  double _peekClipEnd = 0.0;
  bool _peekPlaying = false;
  bool _peekPreparing = false;
  bool _peekClipFinished = false;
  String? _peekUnavailableReason;

  /// 本回合实际播放的难度（inote 编号），用于显示与单人一致的难度标签。
  String? _peekResolvedInote;

  /// 本回合谱面（回合结束后重建带音频的播放器要用同一份谱面）。
  MaiChart? _peekChart;

  /// 答案模式（回合结束后）：
  /// 音频就绪后把播放器换成带音频实例，可无限复播对答案。
  bool _peekAnswerModeEntered = false;
  bool _peekAnswerAudioReady = false;
  bool _peekAnswerAudioFailed = false;
  bool _peekAudioAttached = false;
  String? _peekAnswerAudioPath;

  /// 手动复播次数（自动播放那一次不计）。**每人独立计数**。
  int _peekReplaysLeft = kPeekMaxReplays;
  static const int kPeekMaxReplays = 3; // 与单人谱面片段猜歌一致

  // 获取玩家显示名称（处理重复昵称）
  String _getPlayerDisplayName(PlayerEntity player) {
    if (_currentRoom == null) return player.nickname;

    // 检查是否有重复昵称
    int nicknameCount = _currentRoom!.players
        .where((p) => p.nickname == player.nickname)
        .length;

    if (nicknameCount > 1) {
      // 有重复昵称，显示昵称+ID后缀
      String idSuffix = player.playerId
          .substring(0, min(4, player.playerId.length))
          .toUpperCase();
      return '${player.nickname}($idSuffix)';
    }

    return player.nickname;
  }

  // 检查是否所有玩家都投降了
  bool _isAllPlayersSurrendered() {
    if (_currentRoom == null) return false;
    return _currentRoom!.players.every((p) => p.isSurrendered);
  }

  /// 终局横幅：显示本局获胜者（并列则列出所有人），无人得分时显示平局。
  ///
  /// 胜负由服务端 `winners` 下发，客户端不自己排序取第一名：
  /// Dart 的 `List.sort` 不保证稳定，同分玩家名次会随刷新跳动；而且同分本应
  /// 并列获胜，用排序先后决定赢家是错的。
  Widget _buildGameResultBanner(Brightness brightness) {
    final state = _gameState;
    if (state == null || !state.isGameOver) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final List<String> winnerIds = state.winners;

    // 拿不到玩家名册就没法把 id 翻译成人名，此时不硬猜，交给排行榜展示分数
    final players = state.players.isNotEmpty
        ? state.players
        : (_currentRoom?.players ?? const <PlayerEntity>[]);
    if (players.isEmpty) return const SizedBox.shrink();

    final bool isDraw = winnerIds.isEmpty;
    final List<String> winnerNames = isDraw
        ? const []
        : [
            for (final id in winnerIds)
              _getPlayerDisplayName(
                players.firstWhere(
                  (p) => p.playerId == id,
                  orElse: () => PlayerEntity(playerId: id, nickname: '玩家'),
                ),
              ),
          ];

    // 全场 0 分（例如全员投降 / 一题都没答出来）算平局，不写「获胜」
    final bool iAmWinner =
        !isDraw && winnerIds.contains(_manager.currentPlayerId);
    final String headline = isDraw
        ? '🤝 平局'
        : (winnerIds.length > 1
            ? '🤝 并列获胜'
            : (iAmWinner ? '🏆 你赢了！' : '🏆 ${winnerNames.first} 获胜'));
    final String? subline = (!isDraw && winnerIds.length > 1)
        ? winnerNames.join('、')
        : (isDraw ? '本局无人得分' : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDraw
            ? scheme.surfaceContainerHighest
            : AppColors.successSurface(brightness),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDraw
              ? scheme.outlineVariant
              : AppColors.successForeground(brightness).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDraw
                  ? scheme.onSurface
                  : AppColors.successForeground(brightness),
            ),
          ),
          if (subline != null) ...[
            const SizedBox(height: 4),
            Text(
              subline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDraw
                    ? scheme.onSurfaceVariant
                    : AppColors.successForeground(brightness),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 构建回合获胜者显示组件（只有当有人答对时才显示）
  Widget _buildRoundWinner() {
    final gains = _roundScoresByPlayer();
    final correctGuesses = _gameState?.guesses
            .where((g) =>
                g.isCorrect && g.score > 0 && (gains[g.playerId] ?? 0) > 0)
            .toList() ??
        [];
    if (correctGuesses.isEmpty) return const SizedBox.shrink();
    final latestGuess = correctGuesses.last;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.successSurface(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '🎉 ${_getGuessPlayerDisplayName(latestGuess.playerId, latestGuess.playerNickname)} 答对了! +${latestGuess.score}分',
        style: TextStyle(
          color: AppColors.successForeground(Theme.of(context).brightness),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 获取猜测记录中玩家的显示名称
  String _getGuessPlayerDisplayName(String playerId, String playerNickname) {
    if (_currentRoom == null) return playerNickname;

    // 查找对应的玩家
    PlayerEntity? player;
    for (var p in _currentRoom!.players) {
      if (p.playerId == playerId) {
        player = p;
        break;
      }
    }

    if (player != null) {
      return _getPlayerDisplayName(player);
    }

    // 如果找不到玩家，检查是否有重复昵称
    int nicknameCount =
        _currentRoom!.players.where((p) => p.nickname == playerNickname).length;

    if (nicknameCount > 1) {
      // 有重复昵称，显示昵称+ID后缀
      String idSuffix = playerId.substring(0, 4).toUpperCase();
      return '${playerNickname}($idSuffix)';
    }

    return playerNickname;
  }

  /// 取玩家的「已结算」分数。
  ///
  /// room.players 的分数永远慢一回合：服务端 endRoundHandler 是先
  /// room.endRound() 结算、再广播 round_over，而结算前那条 room_updated
  /// 早就发出去了，之后也不会补发。所以只要 gameState 里有该玩家的分数
  /// 快照（服务端 getGameState 会带 players），就以它为准。
  int _settledScoreOf(PlayerEntity player) {
    for (final p in _gameState?.players ?? const <PlayerEntity>[]) {
      if (p.playerId == player.playerId) return p.score;
    }
    return player.score;
  }

  // 排序状态
  bool _isAscending = true;

  // Stream订阅
  StreamSubscription? _roomSubscription;
  StreamSubscription? _gameStateSubscription;
  StreamSubscription? _errorMessageSubscription;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _songAliasManager = SongAliasManager.instance;
    _initRoom();
  }

  Future<void> _initRoom() async {
    try {
      if (mounted) setState(() => _initializationError = null);
      await _initializeRoomState();
    } catch (error) {
      if (mounted) setState(() => _initializationError = '房间连接失败，请检查网络后重试');
    }
  }

  Future<void> _initializeRoomState() async {
    await _songAliasManager.init();
    if (!mounted) return;

    // 确保 MultiplayerManager 已初始化（建立事件订阅）
    await _manager.initialize();
    if (!mounted) return;

    debugPrint(
        '[DEBUG][GameRoomPage] 初始化房间 - gameType: ${widget.room.gameType.name} (${widget.room.gameType.description})');
    debugPrint(
        '[DEBUG][GameRoomPage] 房间码: ${widget.room.roomCode}, 房间ID: ${widget.room.roomId}');

    setState(() {
      _currentRoom = _manager.currentRoom?.roomId == widget.room.roomId
          ? _manager.currentRoom
          : widget.room;
      // 初始化时就从房间信息中获取当前玩家
      if (_currentRoom!.players.isNotEmpty) {
        _currentPlayer = _currentRoom!.players
            .where((p) => p.playerId == _manager.currentPlayerId)
            .firstOrNull;
      }
      _hasSurrendered = _currentPlayer?.isSurrendered ?? false;
    });

    _manager.startListeningToRoom(widget.room.roomId);

    _roomSubscription = _manager.roomStream.listen((room) {
      debugPrint('[DEBUG][GameRoomPage] 收到 roomStream 更新: ${room?.roomId}');
      if (!mounted ||
          _isLeaving ||
          (room != null && room.roomId != widget.room.roomId)) return;

      // 打印玩家投降状态（调试）
      if (room != null) {
        room.players.forEach((p) {
          debugPrint(
              '[DEBUG][GameRoomPage] 玩家 ${p.nickname} - 投降: ${p.isSurrendered}');
        });
      }

      // 强制创建新的房间对象，确保 Flutter 检测到变化。
      //
      // ⚠️ 这里**必须用 copyWith()**，不要手写字段列表：以前是逐字段 new 一个
      // RoomEntity，结果新增的模式设置（flashDurationMs / tileCount /
      // tileRevealIntervalMs / peekDurationSeconds / peekDifficulties）没被带上，
      // 服务器一推房间状态就被覆盖成默认值——表现就是「自定义切块数量/揭示间隔
      // 进游戏后又变回 1000 块 / 1.5s」。
      //
      // 再用 withModeSettingsFallback 兜一层：万一某条房间事件没带这些字段
      // （fromJson 会退回默认值），就沿用本机已知的值（房间创建后这些设置不可改）。
      RoomEntity? newRoom = room
          ?.copyWith(players: List.from(room.players))
          .withModeSettingsFallback(_currentRoom ?? widget.room);

      setState(() {
        // 检测房主变更
        if (_currentRoom != null && newRoom != null) {
          String? oldHostName = _currentRoom!.players
              .firstWhere((p) => p.isHost,
                  orElse: () => PlayerEntity(
                      playerId: '',
                      nickname: '',
                      score: 0,
                      isHost: false,
                      isReady: false,
                      isOnline: false,
                      isSurrendered: false))
              .nickname;
          String? newHostName = newRoom.players
              .firstWhere((p) => p.isHost,
                  orElse: () => PlayerEntity(
                      playerId: '',
                      nickname: '',
                      score: 0,
                      isHost: false,
                      isReady: false,
                      isOnline: false,
                      isSurrendered: false))
              .nickname;

          // 如果房主变更了且不是同一个人
          if (oldHostName != null &&
              newHostName != null &&
              oldHostName != newHostName) {
            _hostChangeMessage = '$newHostName 成为了房主';
            // 3秒后清除提示
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _hostChangeMessage = null;
                });
              }
            });
          }
        }

        _currentRoom = newRoom;
        // 每次收到房间更新都更新当前玩家信息，确保状态同步
        if (newRoom != null) {
          _currentPlayer = newRoom.players
              .where((p) => p.playerId == _manager.currentPlayerId)
              .firstOrNull;
        }

        _hasSurrendered = _currentPlayer?.isSurrendered ?? false;
        if ((_pendingAction == 'ready' &&
                _currentPlayer?.isReady == _requestedReady) ||
            (_pendingAction == 'surrender' && _hasSurrendered))
          _completeAction();
      });
    });

    _gameStateSubscription = _manager.gameStateStream.listen(_applyGameState);
    if (_manager.currentGameState != null)
      _applyGameState(_manager.currentGameState);

    // 监听服务器错误消息
    _errorMessageSubscription = _manager.errorMessageStream.listen((message) {
      if (!mounted || _isLeaving) return;
      setState(_completeAction);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _applyGameState(GameStateEntity? state) {
    if (!mounted || _isLeaving) return;
    if (state?.roomId != null && state!.roomId != widget.room.roomId) return;
    setState(() {
      if (state == null) {
        _gameState = null;
        _roundDeadline = null;
        _countdownTimer?.cancel();
        return;
      }
      final previous = _gameState;
      final isNewRound = previous == null ||
          previous.currentRound != state.currentRound ||
          (state.roundId != null && previous.roundId != state.roundId) ||
          (previous.isGameOver && !state.isGameOver);
      if (isNewRound) {
        _countdownTimer?.cancel();
        _resetModeSpecificState();
        _targetSong = null;
        _targetSongLoadGeneration++;
        _clearSearchInput();
      }
      _gameState = state;
      final self = state.players
              .where((p) => p.playerId == _manager.currentPlayerId)
              .firstOrNull ??
          _currentPlayer;
      _hasSurrendered = self?.isSurrendered ?? false;
      if (_hasSurrendered) {
        _playbackTimer?.cancel();
        _audioPlayer?.stop();
        _isPlaying = false;
        _peekController?.pause();
        _peekPlaying = false;
      }
      final guessConfirmed = _pendingAction == 'guess' &&
          state.guesses.any((guess) =>
              guess.playerId == _manager.currentPlayerId &&
              guess.songId.toString() == _pendingSongId);
      if (guessConfirmed) _clearSearchInput();
      if (_pendingAction == 'letter' &&
          state.openedLetters.any((letter) =>
              letter.toLowerCase() == _pendingLetter?.toLowerCase()))
        _openLetterController.clear();
      if (isNewRound ||
          state.isRoundOver ||
          state.isGameOver ||
          guessConfirmed ||
          (_pendingAction == 'surrender' && _hasSurrendered) ||
          (_pendingAction == 'letter' &&
              state.openedLetters.any((letter) =>
                  letter.toLowerCase() == _pendingLetter?.toLowerCase())))
        _completeAction();
      final milliseconds = state.timeLimit <= 0
          ? 0
          : state.serverNow != null && state.roundEndsAt != null
              ? max(0, state.roundEndsAt! - state.serverNow!)
              : max(0, state.timeRemaining * 1000);
      _remainingTime = (milliseconds / 1000).ceil();
      _roundDeadline = state.timeLimit > 0
          ? DateTime.now().add(Duration(milliseconds: milliseconds))
          : null;
      if (state.isRoundOver || state.isGameOver) {
        _countdownTimer?.cancel();
        _flashTimer?.cancel();
        _tileRevealTimer?.cancel();
        _playbackTimer?.cancel();
        _audioPlayer?.stop();
        _isPlaying = false;
        _enterPeekAnswerModeIfNeeded();
      } else if (_countdownTimer?.isActive != true) {
        _startCountdown();
      }
      if (state.targetSong != null) _loadTargetSong(state.targetSong);
    });
  }

  Future<void> _loadTargetSong(dynamic targetSongData) async {
    final requestedId = targetSongData is Map
        ? targetSongData['id']?.toString()
        : targetSongData?.toString();
    if (requestedId == null ||
        requestedId.isEmpty ||
        _targetSong?.id == requestedId) return;
    final generation = ++_targetSongLoadGeneration;
    try {
      final allSongs = await GuessChartByInfoService.loadAllSongs();
      if (!mounted || _isLeaving || generation != _targetSongLoadGeneration)
        return;

      String targetSongId;

      // 处理两种情况：字符串ID或歌曲对象
      if (targetSongData is String) {
        targetSongId = targetSongData;
      } else if (targetSongData is Map) {
        targetSongId = targetSongData['id']?.toString() ?? '';
      } else {
        debugPrint('[DEBUG][GameRoom] 无法解析目标歌曲数据');
        return;
      }

      if (targetSongId.isEmpty) {
        debugPrint('[DEBUG][GameRoom] 目标歌曲ID为空');
        return;
      }

      // 根据歌曲ID查找目标歌曲
      final target =
          allSongs?.where((song) => song.id == targetSongId).firstOrNull ??
              (targetSongData is Map
                  ? Song.fromJson(Map<String, dynamic>.from(targetSongData))
                  : null);
      final coverProvider = target != null &&
              (_currentRoom?.gameType == GameType.cover ||
                  _currentRoom?.gameType == GameType.flash) &&
              _croppedCoverProvider == null
          ? await CoverUtil.resolveCoverProvider(target.id)
          : _croppedCoverProvider;
      if (!mounted || _isLeaving || generation != _targetSongLoadGeneration)
        return;
      if (_currentRoom?.gameType == GameType.flash && coverProvider != null) {
        await precacheImage(coverProvider, context);
        if (!mounted || _isLeaving || generation != _targetSongLoadGeneration)
          return;
      }
      if (_targetSong?.id != target?.id ||
          _croppedCoverProvider != coverProvider) {
        setState(() {
          _targetSong = target;
          _croppedCoverProvider = coverProvider;
          if (_currentRoom?.gameType == GameType.flash &&
              _gameState?.isRoundOver == false) _startFlashCover();
        });
        final type = _currentRoom?.gameType;
        if (target != null && _gameState?.isRoundOver == false &&
            (type == GameType.reverseAudio || type == GameType.pitchAudio)) {
          final musicId = LuoXueSongUtil.toLxnsMusicId(target.id);
          if (musicId > 0) {
            GuessAudioService.prefetch(
              musicId: musicId.toString(),
              mode: type == GameType.reverseAudio
                  ? GuessAudioMode.reverseAudio : GuessAudioMode.pitchAudio,
              duration: _currentRoom?.playDuration ?? 5,
              rate: _currentRoom?.audioRate ?? 1.25,
              seed: '${widget.room.roomId}-${_gameState?.roundId ?? _gameState?.currentRound}-${target.id}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[DEBUG][GameRoom] 加载目标歌曲失败: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('[DEBUG][GameRoomPage] dispose - 用户离开页面，取消所有订阅');

    // 取消搜索控制器和定时器
    _searchController.dispose();
    _openLetterController.dispose();
    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    _actionTimer?.cancel();

    // 取消房间和游戏状态订阅
    _roomSubscription?.cancel();
    _gameStateSubscription?.cancel();
    _errorMessageSubscription?.cancel();

    // 清理音频资源
    _playbackTimer?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.dispose();

    // 清理 flash / tileReveal / chartPeek 的模式专属资源
    _flashTimer?.cancel();
    _tileRevealTimer?.cancel();
    _peekController?.timeNotifier.removeListener(_onPeekTimeChanged);
    _peekController?.dispose();
    _peekController = null;

    // 大厅与房间共用管理器和连接；这里只取消本页订阅，不能关闭大厅的连接。

    super.dispose();
  }

  bool get _canAct =>
      !_actionPending &&
      !_isLeaving &&
      _gameState != null &&
      !_gameState!.isRoundOver &&
      !_gameState!.isGameOver &&
      (_gameState!.timeLimit <= 0 || _remainingTime > 0);

  void _completeAction() {
    _actionPending = false;
    _pendingAction = null;
    _actionTimer?.cancel();
  }

  void _beginAction(String action) {
    _pendingAction = action;
    setState(() => _actionPending = true);
    _actionTimer?.cancel();
    _actionTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || !_actionPending) return;
      setState(_completeAction);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('操作未收到确认，请检查连接后重试')));
    });
  }

  void _handleReady() {
    if (_actionPending || _isLeaving) return;
    _requestedReady = !(_currentPlayer?.isReady ?? false);
    _beginAction('ready');
    if (_currentRoom != null) {
      _manager.updatePlayerReady(!(_currentPlayer?.isReady ?? false));
    }
  }

  void _handleStartGame() {
    if (_actionPending || _isLeaving) return;
    _beginAction('start');
    _manager.startGame();
  }

  // 按快照中的截止时刻倒数，后台停留后也能按实际经过的时间恢复。
  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_roundDeadline == null || _remainingTime <= 0) return;
    _countdownTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || _roundDeadline == null) {
        timer.cancel();
        return;
      }
      final seconds = max(
          0,
          (_roundDeadline!.difference(DateTime.now()).inMilliseconds / 1000)
              .ceil());
      if (seconds != _remainingTime) setState(() => _remainingTime = seconds);
      if (seconds == 0) timer.cancel();
      // 到零只等待服务端结算，不提前揭晓答案或开放“下一轮”。
    });
  }

  Future<void> _handleSurrender() async {
    if (!_canAct || _hasSurrendered) return;
    _beginAction('surrender');
    await _manager.updatePlayerSurrendered(true);
    // 投降状态由 player_surrendered / room_updated / 游戏快照确认。
  }

  // 显示规则说明对话框
  void _showRulesDialog() {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final gameType = _currentRoom?.gameType ?? widget.room.gameType;

    // 小标题：把长文分段，否则一整屏文字没人看
    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: scheme.primary,
            ),
          ),
        );

    Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('· $text'),
        );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              const Text('规则说明'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- 得分机制 ----------
                // 原先的规则弹窗只讲颜色、完全没提怎么算分，
                // 「为什么我猜中了分数却不高」这类疑问在游戏内无从查证。
                sectionTitle('得分机制'),
                bullet('答对得分 = 100 − 从回合开始经过的秒数，最低 10 分；答错 0 分。'),
                bullet('也就是越快猜中分数越高：秒答接近 100 分，拖到最后也有 10 分保底。'),
                bullet('同一首曲目只按你在这首上最好的一次计分，重复提交不会刷分。'),
                bullet('每一首曲目只给最先猜中的人计分，其余人这首拿 0 分。'),
                bullet('猜错不扣分，不用怕猜错拖累总分。'),
                if (gameType == GameType.letters) ...[
                  // letters 单回合有多首目标曲，计分口径与其它模式不同
                  bullet('开字母一回合有多首曲目，每首独立计分，'
                      '单回合满分 = 曲目数 × 100。'),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange(brightness)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warningOrange(brightness)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        // 玩家最容易误解的一点，单独点出来
                        '注意：计时是从「回合开始」算的，不是从「猜中上一首」算的。'
                        '所以后面几首天然比第一首慢 —— 不是你的错觉。',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warningOrange(brightness),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],

                // ---------- 颜色 ----------
                sectionTitle('颜色含义'),
                bullet('绿色 - 该属性与你猜的完全一致。'),
                bullet('黄色 - 该属性与你猜的接近：BPM 相差 ±20 以内；'
                    'MASTER / Re:MASTER 难度相差 ±0.4 以内；'
                    '版本相差一个世代（maimai ← maimai PLUS → maimai GreeN）。'),
                bullet('灰色 - 该属性与你猜的差距较大。'),

                // ---------- 箭头 ----------
                sectionTitle('箭头'),
                bullet('↑ - 目标值比你猜的更高'),
                bullet('↓ - 目标值比你猜的更低'),

                // ---------- 标签 ----------
                sectionTitle('标签'),
                bullet('显示你猜的曲目在 MASTER 难度下的配置、难度和评价标签。'),
                bullet('当某个标签与目标曲目一致时，该标签会变绿。'),
                bullet('注意：有些曲目可能未添加标签。'),

                // ---------- 开字母 ----------
                if (gameType == GameType.letters) ...[
                  sectionTitle('开字母玩法'),
                  bullet('本回合曲名以 □ 遮蔽，每人可开字母逐字揭示，开出的字母全房间可见。'),
                  bullet('同一个字母只能开一次。'),
                  bullet('猜中某首后，该曲名会对全房间公开完整名称。'),
                  bullet('抢先猜中可能要「送答案」，但每首只给最先猜中的人计分，先猜中仍然划算。'),
                  bullet('把所有曲名都猜中，本回合才结束。'),
                ],

                // ---------- 房间规则 ----------
                sectionTitle('房间规则'),
                bullet('剩余猜测次数是全房间共享的，谁先猜都消耗同一个池子，'
                    '用完本回合即结束。'),
                bullet('投降后本回合不再计分，也无法再提交猜测；但仍可围观其他人继续。'),

                // ---------- 胜负 ----------
                sectionTitle('胜负判定'),
                bullet('全部回合结束后，总分最高的人获胜。'),
                bullet('同分则并列获胜；全场无人得分时算平局。'),
                bullet('分数在每回合结束时结算，排行榜显示的就是结算后的总分。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 保留房间的防抖与候选数限制，匹配规则直接复用歌曲搜索页的常规搜索。
  void _handleSearchInput(String value) {
    _searchTimer?.cancel();
    final generation = ++_searchGeneration;
    final query = value.trim();
    setState(() {
      _searchResults = [];
      _showSearchResults = false;
      _isSearching = query.isNotEmpty;
    });
    if (query.isEmpty) return;

    _searchTimer = Timer(_searchDelay, () async {
      try {
        final results = await SongSearchService.searchSongs(query);
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          // 题库范围仍排除非国服与 maidata 追加曲，保留原房间规则。
          _searchResults =
              results.where((song) => !_isMaidataSong(song)).take(20).toList();
          _showSearchResults = _searchResults.isNotEmpty;
          _isSearching = false;
        });
      } catch (e) {
        if (!mounted || generation != _searchGeneration) return;
        setState(() => _isSearching = false);
        debugPrint('[GameRoom] 搜索失败: $e');
      }
    });
  }

  // 判断是否是从maidata追加的歌曲（cids全为0表示从maidata解析），或union独有的歌曲
  bool _isMaidataSong(Song song) {
    if (song.isExtra) return true;
    if (song.cids.isEmpty) return false;
    return song.cids.every((cid) => cid == 0);
  }

  // 处理猜测
  Future<void> _handleGuess(Song guessedSong) async {
    if (_isSubmitting || !_canAct || _hasSurrendered) return;

    // 检查是否已经猜过这首歌（用 id 字符串比对：宴会场 id 或异常数据下
    // int.parse 会直接抛异常，导致点选即崩）
    bool hasGuessed = _gameState!.guesses.any((guess) =>
        guess.playerId == _manager.currentPlayerId &&
        guess.songId.toString() == guessedSong.id);
    if (hasGuessed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已经猜过这首歌了！'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _isSubmitting = true;
    _pendingSongId = guessedSong.id;
    _beginAction('guess');
    try {
      // 作答直接发给服务端；抢答输赢、扣次数和回合结束均等待权威状态，
      // 避免本地先判答对后把被拒绝的请求粘成「回合已结束」。
      FocusManager.instance.primaryFocus?.unfocus();
      await _manager.submitGuess(guessedSong.id, guessedSong.basicInfo.title);
    } finally {
      _isSubmitting = false;
    }
  }

  void _handleNextRound() {
    if (_actionPending || _isLeaving) return;
    _beginAction('next');
    _manager.startNextRound();
  }

  void _handleRestartGame() {
    if (_actionPending || _isLeaving) return;
    _beginAction('start');
    _manager.startGame();
  }

  void _showLeaveRoomConfirmDialog() async {
    if (_isLeaving || _leaveDialogOpen) return;
    _leaveDialogOpen = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认离开'),
          content: const Text('是否离开当前房间？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('离开'),
            ),
          ],
        );
      },
    );
    _leaveDialogOpen = false;
    if (mounted && confirmed == true) await _handleLeaveRoom();
  }

  Future<void> _handleLeaveRoom() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    try {
      await _manager.leaveRoom();
      if (!mounted) return;
      debugPrint('[GameRoom] 已收到退房确认，准备返回大厅');
      setState(() => _canPopAfterLeave = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[GameRoom] 执行返回大厅');
        if (mounted) Navigator.pop(context);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLeaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              error is TimeoutException ? '退出房间未收到确认，请重试' : '退出房间失败：$error')));
    }
  }

  Widget _buildPlayerList() => MultiplayerRoomPlayers(
        room: _currentRoom ?? widget.room,
        currentPlayerId: _manager.currentPlayerId,
        playing: _gameState != null,
        displayName: _getPlayerDisplayName,
        scoreOf: _settledScoreOf,
      );

  Widget _buildGameArea(Brightness brightness) {
    if (_gameState == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              (_currentRoom?.status == RoomStatus.playing ||
                      _currentRoom?.status == RoomStatus.ended)
                  ? '正在恢复对局…'
                  : '等待游戏开始...',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_gameState!.isGameOver) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events,
                  size: 26, color: AppColors.warningOrange(brightness)),
              const SizedBox(width: 8),
              const Text('游戏结束!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildGameResultBanner(brightness),
          const SizedBox(height: 16),
          _buildAudioAnswerArea(),

          // 显示答案区域（绿色背景）
          if (_targetSong != null)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.guessAnswerCardBg(brightness),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildAnswerDisplay(),
            ),

          const SizedBox(height: 16),
          _buildScoreboard(),

          // 服务端已完成终局结算；房主可直接开启一局新游戏。
          if (_currentPlayer?.isHost == true)
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _actionPending ? null : _handleRestartGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('再来一局'),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (_gameState!.isRoundOver) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag,
                  size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('回合结束!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // 显示当前回合答对的玩家（只显示最新的答对记录）
          _buildRoundWinner(),
          _buildAudioAnswerArea(),

          // 显示答案区域（绿色背景）
          if (_targetSong != null)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.guessAnswerCardBg(brightness),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildAnswerDisplay(),
            ),

          const SizedBox(height: 16),

          // 显示排行榜（放在下一轮按钮之前）
          _buildScoreboard(),

          const SizedBox(height: 16),

          // 以服务端确认的回合结束状态开放下一轮，包括共享次数耗尽。
          if (_currentPlayer?.isHost == true)
            ElevatedButton(
              onPressed: _actionPending ? null : _handleNextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('下一轮'),
            ),
        ],
      );
    }

    // 如果当前玩家已投降，显示等待提示
    if (_hasSurrendered) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.hourglass_empty,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text(
            '已投降，请等待其他玩家……',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // 显示剩余时间（给投降玩家看）
          if (_remainingTime > 0)
            Text(
              '⏱️ 剩余时间: $_remainingTime 秒',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 16),

          // 猜测历史（从游戏状态获取，实时更新）
          if (_gameState != null && _gameState!.guesses.isNotEmpty)
            _buildGuessHistory(),
        ],
      );
    }

    return Column(
      children: [
        // 回合进度：模式名已由顶栏展示，这里只显示「第几回合/共几回合」。
        if (_gameState != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '第 ${_gameState!.currentRound} / ${_gameState!.totalRounds} 回合',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),

        // 模式专属提示（曲绘截取/模糊曲绘/音频播放器）
        _buildModeSpecificHint(),

        // 状态徽章行：倒计时 + 剩余次数。
        // 原先这两条是两行裸文字，和模式提示、搜索框混在一起没有视觉分组，
        // 玩家扫一眼看不到「还剩多少时间/几次机会」。改成带图标的徽章，
        // 并用底色表达危险程度（时间紧迫 / 次数将尽）。
        _buildStatusBadges(brightness),
        if (_actionPending ||
            (_gameState!.timeLimit > 0 && _remainingTime == 0))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_actionPending ? '正在等待服务端确认…' : '时间到，正在等待回合结算…'),
          ),

        const SizedBox(height: 16),
        _buildSearchField(),

        const SizedBox(height: 16),

        // 搜索结果
        if (_showSearchResults && _searchResults.isNotEmpty)
          _buildSearchResults(),

        // 按钮区域
        Container(
          margin: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 规则按钮
                  IconButton(
                    tooltip: '规则说明',
                    icon: Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24),
                    onPressed: _showRulesDialog,
                  ),
                  const SizedBox(width: 4),
                  // 排序按钮
                  IconButton(
                    tooltip: _isAscending ? '当前：正序，点按切换为倒序' : '当前：倒序，点按切换为正序',
                    icon: Icon(
                      _isAscending
                          ? Icons.sort_by_alpha
                          : Icons.sort_by_alpha_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isAscending = !_isAscending;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // 投降按钮
                  OutlinedButton(
                    onPressed: _canAct ? _handleSurrender : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('投降'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 猜测历史（从游戏状态获取，实时更新）
        if (_gameState != null && _gameState!.guesses.isNotEmpty)
          _buildGuessHistory(),
      ],
    );
  }

  Widget _buildSearchField() {
    // 搜索框加一个前置图标，避免它和上面的模式提示糊成一团
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled: _canAct && !_hasSurrendered,
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索歌曲、ID、BPM、谱师等',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _clearSearchInput();
                            });
                          },
                        ),
                ),
                onChanged: _handleSearchInput,
              ),
            ),
          ],
        ),
        // 搜索中状态（与单人猜歌页一致）
        if (_isSearching)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  /// 状态徽章行：剩余时间 + 剩余猜测次数（房间共享）。
  ///
  /// 两者都是「一眼要知道」的读数，用同一种徽章形态并排显示；进入危险区间
  /// （时间 ≤10 秒 / 次数 ≤3）时整块变底色，比只改文字颜色更容易被注意到。
  Widget _buildStatusBadges(Brightness brightness) {
    final int? guessesLeft = _gameState == null || _gameState!.maxGuesses <= 0
        ? null
        : max(0, _gameState!.maxGuesses - _gameState!.currentGuesses);

    final List<Widget> badges = [];

    if (_gameState != null) {
      final bool unlimited = _gameState!.timeLimit <= 0;
      final bool urgent = !unlimited && _remainingTime <= 10;
      badges.add(_buildStatusBadge(
        icon: Icons.timer_outlined,
        label: '剩余时间',
        value: unlimited ? '不限时' : '$_remainingTime 秒',
        accent: urgent
            ? AppColors.errorRed(brightness)
            : Theme.of(context).colorScheme.primary,
        background: urgent
            ? AppColors.errorRed(brightness).withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ));
    }

    if (_gameState != null) {
      final bool low = guessesLeft != null && guessesLeft <= 3;
      badges.add(_buildStatusBadge(
        icon: Icons.search_outlined,
        label: '剩余次数',
        value: guessesLeft == null ? '不限' : '$guessesLeft 次',
        accent: low
            ? AppColors.warningOrange(brightness)
            : Theme.of(context).colorScheme.primary,
        background: low
            ? AppColors.warningOrange(brightness).withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < badges.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Flexible(child: badges[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        // ListView 默认会把 MediaQuery 的 viewPadding 当成第一项前的 padding
        // （等于状态栏高度），导致搜索结果顶部多出约半张卡片高的空白
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return _buildSearchResultItem(_searchResults[index]);
        },
      ),
    );
  }

  Widget _buildSearchResultItem(Song song) {
    final aliases = _songAliasManager.aliases[song.title] ?? [];
    String aliasText = aliases.isNotEmpty ? aliases.join('、') : '';

    return GestureDetector(
      onTap: () => _handleGuess(song),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    CoverUtil.buildCoverWidgetWithContext(context, song.id, 60),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        song.type == 'SD' ? 'ST' : 'DX',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              song.type == 'SD' ? Colors.blue : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          song.basicInfo.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    song.basicInfo.artist,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (aliasText.isNotEmpty)
                    Text(
                      aliasText,
                      style: TextStyle(
                          fontSize: 14,
                          color:
                              AppColors.linkBlue(Theme.of(context).brightness)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessHistory() {
    if (_gameState == null || _gameState!.guesses.isEmpty) {
      return const SizedBox.shrink();
    }

    List<GuessRecord> guesses = List.from(_gameState!.guesses);

    // 去重：根据playerId、songId和guessedAt组合去重
    Map<String, GuessRecord> uniqueGuesses = {};
    for (var guess in guesses) {
      String key =
          '${guess.playerId}_${guess.songId}_${guess.guessedAt.millisecondsSinceEpoch}';
      uniqueGuesses[key] = guess;
    }
    guesses = uniqueGuesses.values.toList();

    // 先按时间排序确定实际提交顺序
    List<GuessRecord> timeSortedGuesses = List.from(guesses);
    timeSortedGuesses.sort((a, b) => a.guessedAt.compareTo(b.guessedAt));

    // 创建猜测序号映射
    Map<String, int> guessOrderMap = {};
    for (int i = 0; i < timeSortedGuesses.length; i++) {
      String key =
          '${timeSortedGuesses[i].playerId}_${timeSortedGuesses[i].songId}_${timeSortedGuesses[i].guessedAt.millisecondsSinceEpoch}';
      guessOrderMap[key] = i + 1;
    }

    // 根据排序状态排序显示顺序
    if (_isAscending) {
      guesses.sort((a, b) => a.guessedAt.compareTo(b.guessedAt));
    } else {
      guesses.sort((a, b) => b.guessedAt.compareTo(a.guessedAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '猜测历史 (${guesses.length})',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...guesses.map((guess) {
          String key =
              '${guess.playerId}_${guess.songId}_${guess.guessedAt.millisecondsSinceEpoch}';
          int guessNumber = guessOrderMap[key] ?? 1;
          return _buildGuessHistoryItemFromRecord(guess, guessNumber);
        }),
      ],
    );
  }

  Widget _buildGuessHistoryItemFromRecord(GuessRecord guess, int guessNumber) {
    final detailsKey =
        '${guess.songId}:${_targetSong?.id}:${Theme.of(context).brightness.name}';
    return FutureBuilder<GuessSong?>(
      future: _guessDetails.putIfAbsent(
          detailsKey, () => _buildGuessSongForRecord(guess)),
      builder: (context, snapshot) {
        GuessSong? guessSong = snapshot.data;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 提交者信息行：把序号做成小圆点，一眼能数出是第几次猜测
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$guessNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guess.playerNickname,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 第一行：曲绘，曲名
              Row(
                children: [
                  // 方形曲绘
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CoverUtil.buildCoverWidgetWithContext(
                          context, guess.songId, 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoItem(
                        '曲名',
                        guessSong?.title ?? guess.songName,
                        guessSong?.titleBgColor ?? Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 第二行：类型，BPM，曲师
              if (guessSong != null)
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildInfoItem(
                          '类型',
                          guessSong.type == 'SD' ? 'ST' : guessSong.type,
                          guessSong.typeBgColor ?? Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: _buildInfoItem('BPM', guessSong.bpm.toString(),
                          guessSong.bpmBgColor ?? Colors.grey,
                          arrow: guessSong.bpmArrow),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: guessSong.artistBgColor ?? Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '曲师',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              guessSong.artist,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              GuessBpmHistoryFields(songId: guess.songId, targetSongId: _currentRoom?.gameType == GameType.letters && guess.isCorrect ? guess.songId : _targetSong?.id),

              // 第三行：Master定数，Master谱师
              if (guessSong != null)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInfoItem('MASTER定数', guessSong.masterDs,
                          guessSong.masterLevelBgColor ?? Colors.grey,
                          arrow: guessSong.masterLevelArrow),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildInfoItem('MASTER谱师', guessSong.masterCharter,
                          guessSong.masterCharterBgColor ?? Colors.grey),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // 第四行：ReMaster定数，ReMaster谱师
              if (guessSong != null)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInfoItem(
                          'Re:MASTER定数',
                          guessSong.remasterDs.isNotEmpty
                              ? guessSong.remasterDs
                              : '-',
                          guessSong.remasterLevelBgColor ?? Colors.grey,
                          arrow: guessSong.remasterLevelArrow),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              guessSong.remasterCharterBgColor ?? Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Re:MASTER谱师',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              guessSong.remasterCharter.isNotEmpty
                                  ? guessSong.remasterCharter
                                  : '-',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // 第五行：流派，版本
              if (guessSong != null)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInfoItem('流派', guessSong.genre,
                          guessSong.genreBgColor ?? Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: guessSong.versionBgColor ?? Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '版本',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    StringUtil.formatVersion2(
                                        guessSong.version),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (guessSong.versionArrow != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      guessSong.versionArrow!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: guessSong.versionArrow == '↑'
                                            ? Colors.blue
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // 第六行：Master标签
              if (guessSong?.masterTags?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MASTER标签',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                          guessSong!.masterTags?.length ?? 0, (i) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: guessSong.tagBgColors?[i] ?? Colors.grey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            guessSong.masterTags?[i] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<GuessSong?> _buildGuessSongForRecord(GuessRecord guess) async {
    final generation = _modeGeneration;
    final target = _targetSong;
    final brightness = Theme.of(context).brightness;
    try {
      final songs = await GuessChartByInfoService.loadAllSongs();
      if (!mounted ||
          _isLeaving ||
          generation != _modeGeneration ||
          songs == null ||
          songs.isEmpty) return null;

      Song? song;
      for (var s in songs) {
        if (s.id == guess.songId) {
          song = s;
          break;
        }
      }
      if (song == null) return null;

      GuessSong guessSong =
          await GuessChartByInfoService.buildGuessSongEntity(song);
      if (!mounted || _isLeaving || generation != _modeGeneration) return null;

      if (target != null) {
        guessSong = await GuessChartByInfoService.calculateGuessResult(
            guessSong, target, brightness);
      }

      return guessSong;
    } catch (e) {
      return null;
    }
  }

  // 构建信息项
  Widget _buildInfoItem(String label, String value, Color color,
      {String? arrow}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (arrow != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 12,
                      color: arrow == '↑' ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建答案显示区域
  Widget _buildAnswerDisplay() {
    if ((_currentRoom?.gameType ?? widget.room.gameType) == GameType.letters)
      return _buildLettersHint();
    if (_targetSong == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            Icon(Icons.check_circle,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              '本局答案',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 曲绘和信息
        Row(
          children: [
            // 曲绘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, _targetSong!.id, 60),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：类型 曲名
                  Row(
                    children: [
                      Text(
                        _targetSong!.type == 'SD' ? 'ST' : _targetSong!.type,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _targetSong!.type == 'SD'
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _targetSong!.basicInfo.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // 第二行：曲师 | 流派
                  Text(
                    '${_targetSong!.basicInfo.artist} | ${_targetSong!.basicInfo.genre}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 第三行：masterDs | remasterDs | version
                  Text(
                    '${_targetSong!.ds.length > 3 ? _targetSong!.ds[3].toString() : '-'} | ${_targetSong!.ds.length > 4 ? _targetSong!.ds[4].toString() : '-'} | ${StringUtil.formatVersion2WithFlag(_targetSong!.basicInfo.from, _targetSong!.isExtra)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if ((_currentRoom?.gameType ?? widget.room.gameType) ==
            GameType.chartPeek)
          _buildChartPeekHint(
              widget.room.roomId, _gameState!.currentRound, _targetSong!.id),
      ],
    );
  }

  Widget _buildAudioAnswerArea() {
    final room = _currentRoom ?? widget.room;
    final state = _gameState;
    final target = _targetSong;
    if (state == null || target == null ||
        (!state.isRoundOver && !state.isGameOver) ||
        (room.gameType != GameType.reverseAudio &&
            room.gameType != GameType.pitchAudio)) {
      return const SizedBox.shrink();
    }
    final musicId = LuoXueSongUtil.toLxnsMusicId(target.id);
    if (musicId <= 0) return const SizedBox.shrink();
    final seed = '${room.roomId}-${state.roundId ?? state.currentRound}-${target.id}';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAudioPlayerHint(room.roomId, state.currentRound, target.id),
          const SizedBox(height: 16),
          GuessOriginalAudioCard(
            key: ValueKey(seed),
            musicId: musicId.toString(),
            mode: room.gameType == GameType.reverseAudio
                ? GuessAudioMode.reverseAudio : GuessAudioMode.pitchAudio,
            duration: room.playDuration,
            rate: room.audioRate,
            seed: seed,
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    if (_currentRoom == null) return const SizedBox();
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;

    // 分数以服务端结算结果为准。
    //
    // 服务端 endRound() 结算分数**之后**只广播 round_over，而 round_over 之前那条
    // room_updated 是在结算前发的（见 server.js 的 endRoundHandler）。也就是说
    // _currentRoom.players 里的分数**永远慢一回合** —— 真机上表现为
    // 「答对了! +62分」横幅下面，排行榜还停在上一回合的 57 分。
    // gameState.players 是结算后的快照，优先用它。
    final Map<String, int> settledScores = {
      for (final p in _gameState?.players ?? const <PlayerEntity>[])
        p.playerId: p.score,
    };
    final Map<String, int> roundGains = _roundScoresByPlayer();

    List<PlayerEntity> sortedPlayers = _currentRoom!.players.map((p) {
      final int? settled = settledScores[p.playerId];
      return settled != null ? p.copyWith(score: settled) : p;
    }).toList()
      // 同分时必须有一个稳定的次序，否则每次重建（倒计时每秒都会触发）
      // 同分玩家的名次会来回跳。Dart 的 List.sort 不保证稳定，
      // 所以显式用「昵称 → playerId」兜底，保证名次固定。
      ..sort((a, b) {
        final int byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final int byName = a.nickname.compareTo(b.nickname);
        if (byName != 0) return byName;
        return a.playerId.compareTo(b.playerId);
      });

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              '排行榜',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...sortedPlayers.asMap().entries.map((entry) {
          final int index = entry.key;
          final PlayerEntity player = entry.value;
          final bool isMe = player.playerId == _manager.currentPlayerId;
          final int gain = roundGains[player.playerId] ?? 0;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: index < 3
                  ? AppColors.podiumSurface(brightness)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: isMe
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                // 名次徽章：前三名用奖牌，其余用序号
                SizedBox(
                  width: 30,
                  child: index < 3
                      ? Text(
                          const ['🥇', '🥈', '🥉'][index],
                          style: const TextStyle(fontSize: 17),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getPlayerDisplayName(player),
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 本回合增量：让「得分怎么来的」一眼可见
                if (gain > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface(brightness),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+$gain',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successForeground(brightness),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${player.score} 分',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 统计本回合每位玩家的得分。
  ///
  /// 口径与服务端 endRound() 保持一致：**每名玩家、每道题只计一次，取最高分**。
  /// 同一首曲子可以被反复提交（letters 模式玩家会重试），直接累加会重复计分；
  /// 服务端正是按 (playerId, matchedSongId) 去重取最大值的，这里按
  /// (playerId, songId) 复刻同一套逻辑，保证界面上的增量之和与总分对得上。
  Map<String, int> _roundScoresByPlayer() {
    final surrendered = {
      for (final player in _gameState?.players ?? const <PlayerEntity>[])
        if (player.isSurrendered) player.playerId,
    };
    final Map<String, int> best = {};
    for (final guess in _gameState?.guesses ?? const <GuessRecord>[]) {
      if (!guess.isCorrect || surrendered.contains(guess.playerId)) continue;
      final String key = '${guess.playerId}\u0000${guess.songId}';
      final int prev = best[key] ?? -1;
      if (guess.score > prev) best[key] = guess.score;
    }
    final Map<String, int> totals = {};
    best.forEach((key, score) {
      final String playerId = key.split('\u0000').first;
      totals[playerId] = (totals[playerId] ?? 0) + score;
    });
    return totals;
  }

  // ==================== 模式专属构建器 ====================

  /// 构建别名猜歌提示（alia 模式）
  Widget _buildAliaHint() {
    if (_targetSong == null) return const SizedBox.shrink();

    final aliases = _songAliasManager.findAliasesBySongName(_targetSong!.title);
    final bool isGameOver = _gameState?.isGameOver ?? false;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标+标题并排一行，比上下堆叠省一截高度
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  '别名提示',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (aliases != null && aliases.isNotEmpty) ...[
              // 游戏未结束时只显示别名数量，结束后显示全部别名
              if (!isGameOver) ...[
                Text(
                  '该歌曲共有 ${aliases.length} 个别名',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // 随机显示1-2个别名作为提示
                ..._getRandomAliasHints(aliases),
              ] else ...[
                // 游戏结束后显示全部别名
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: aliases
                      .map((alias) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              alias,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ] else
              const Text(
                '暂无别名数据，请根据歌曲信息猜歌',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 从别名列表中随机选取1-2个作为提示（使用确定性种子保证所有玩家一致）
  List<Widget> _getRandomAliasHints(List<String> aliases) {
    if (aliases.isEmpty) return [];

    final roomId = _currentRoom?.roomId ?? '';
    final roundNumber = _gameState?.currentRound ?? 1;
    final targetSongId = _targetSong?.id ?? '';

    final seed = GameSeedUtil.generateSeed(
      roomId: roomId,
      roundNumber: roundNumber,
      targetSongId: targetSongId,
    );
    final random = GameSeedUtil.createRandom(seed);

    // 随机选1-2个别名
    final hintCount = aliases.length == 1
        ? 1
        : (1 + random.nextInt(2.clamp(1, aliases.length)));
    final shuffled = List<String>.from(aliases)..shuffle(random);
    final hints = shuffled.take(hintCount).toList();

    return hints
        .map((alias) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  alias,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ))
        .toList();
  }

  /// 构建开字母提示（letters 模式）
  ///
  /// 规则（与单机版 GuessSongByOpenLettersPage 一致）：
  /// 开局随机抽取 songCount 首曲目，曲名以 □ 遮蔽；玩家可以「开字母」逐字揭示，
  /// 全部猜中才结束回合。开字母进度由服务端保存并广播，保证所有玩家看到的掩码一致。
  Widget _buildLettersHint() {
    if (_gameState == null) return const SizedBox.shrink();

    final bool isGameOver = _gameState!.isGameOver;
    final bool isRoundOver = _gameState!.isRoundOver;

    // 目标曲目：优先用服务端下发的 targetSongs；旧版服务端只给 currentSong
    final List<dynamic> rawSongs = _gameState!.targetSongs.isNotEmpty
        ? _gameState!.targetSongs
        : [_targetSong];
    final List<dynamic> targetSongs = rawSongs.where((e) => e != null).toList();
    if (targetSongs.isEmpty) return const SizedBox.shrink();

    final int foundCount = _gameState!.foundSongIds.length;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE17055), Color(0xFFFDCB6E)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标+标题并排一行，比上下堆叠省一截高度
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.text_fields, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  '开字母',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 进度做成白色药丸徽章，比裸文字更醒目
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isGameOver || isRoundOver
                    ? '本回合已结束'
                    : '剩余 ${targetSongs.length - foundCount} / ${targetSongs.length} 首',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // 各曲目的掩码
            ...targetSongs.map((song) {
              // 服务端下发的 targetSongs 是歌曲对象；容错一下，避免结构异常
              // （例如只给了 id 字符串）时整块提示直接抛异常。
              final Map<String, dynamic> map = song is Map
                  ? Map<String, dynamic>.from(song)
                  : <String, dynamic>{'id': song.toString()};
              final String id = (map['id'] ?? '').toString();
              final String title =
                  (map['title'] ?? (map['basic_info']?['title'] ?? ''))
                      .toString();
              // 未结束时用服务端掩码；结束后直接显示完整曲名
              final String display = (isGameOver || isRoundOver)
                  ? title
                  : (_gameState!.maskedTitles[id] ??
                      List.filled(title.length, '□').join());
              final bool found = _gameState!.foundSongIds.contains(id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (found) ...[
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        display,
                        textAlign: TextAlign.center,
                        // 已猜中的曲名降一档透明度，视觉重心留在还没猜出的掩码上
                        style: TextStyle(
                          color: found ? Colors.white70 : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 已开字母 + 开字母输入
            if (!isGameOver && !isRoundOver) ...[
              const SizedBox(height: 12),
              if (_gameState!.openedLetters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        '已开:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      ..._gameState!.openedLetters.map((letter) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _openLetterController,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        counterText: '',
                        isDense: true,
                        hintText: '字',
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                      ),
                      onSubmitted: (_) => _handleOpenLetter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleOpenLetter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE17055),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('开字母'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 提交开字母（交给服务端判定并广播，保证各端掩码一致）
  void _handleOpenLetter() {
    if (!_canAct || _hasSurrendered) return;
    final String letter = _openLetterController.text.trim();
    if (letter.isEmpty) return;
    if (_manager.currentPlayerId == null) return;

    _pendingLetter = letter;
    _beginAction('letter');
    _manager.openLetter(letter);
  }

  /// 构建模式专属的提示区域（曲绘截取、模糊曲绘、音频播放器）
  Widget _buildModeSpecificHint() {
    if (_gameState == null) return const SizedBox.shrink();
    if ((_currentRoom?.gameType ?? widget.room.gameType) == GameType.letters)
      return _buildLettersHint();
    if (_targetSong == null) return const SizedBox.shrink();

    final gameType = _currentRoom?.gameType;
    final roomId = _currentRoom?.roomId ?? '';
    final roundNumber = _gameState!.currentRound;
    final targetSongId = _targetSong!.id;

    switch (gameType) {
      case GameType.cover:
        return _buildCroppedCoverHint(roomId, roundNumber, targetSongId);

      case GameType.blurred:
        return _buildBlurredCoverHint(roomId, roundNumber, targetSongId);

      case GameType.reverseAudio:
      case GameType.pitchAudio:
      case GameType.audio:
        return _buildAudioPlayerHint(roomId, roundNumber, targetSongId);

      case GameType.alia:
        return _buildAliaHint();

      case GameType.letters:
        return _buildLettersHint();

      case GameType.flash:
        return _buildFlashCoverHint(targetSongId);

      case GameType.tileReveal:
        return _buildTileRevealHint(roomId, roundNumber, targetSongId);

      case GameType.chartPeek:
        return _buildChartPeekHint(roomId, roundNumber, targetSongId);

      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建曲绘快闪提示（flash 模式）
  ///
  /// 回合开始时整张曲绘显示 flashDurationMs（房间设置，各端一致），随后消失，
  /// 之后只能凭记忆猜 —— 与单人「曲绘快闪猜歌」同一套规则。
  Widget _buildFlashCoverHint(String targetSongId) {
    final bool isGameOver = _gameState?.isGameOver ?? false;
    final bool showCover = isGameOver || _flashVisible;
    final Brightness brightness = Theme.of(context).brightness;

    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGameOver
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: showCover
                  ? (_croppedCoverProvider == null
                      ? CoverUtil.buildCoverWidgetWithContext(
                          context, targetSongId, 200)
                      : Image(
                          image: _croppedCoverProvider!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover))
                  : Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.visibility_off_outlined,
                        size: 36,
                        color: AppColors.greyHint(brightness),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGameOver
                ? '本局答案'
                : (_flashVisible ? '快闪中……记住它！' : '曲绘已消失，凭记忆猜歌名'),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建曲绘拼图提示（tileReveal 模式）
  ///
  /// 揭示顺序用确定性种子（房间 + 回合 + 曲目）生成，所以每个玩家看到的
  /// 已揭示块完全一致；切块数与揭示间隔来自房间设置。
  Widget _buildTileRevealHint(
      String roomId, int roundNumber, String targetSongId) {
    final int tileCount = _currentRoom?.tileCount ?? 1000;
    final bool isGameOver = _gameState?.isGameOver ?? false;

    // 游戏结束：直接给完整曲绘对答案
    if (isGameOver) {
      return Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CoverUtil.buildCoverWidgetWithContext(
                context, targetSongId, 200),
          ),
        ),
      );
    }

    // 本回合首次构建：按确定性种子生成揭示顺序并启动定时揭示
    if (_tileRevealOrder.isEmpty) {
      _tileRevealOrder = GameSeedUtil.generateTileRevealOrder(
        roomId: roomId,
        roundNumber: roundNumber,
        targetSongId: targetSongId,
        tileCount: tileCount,
      );
      _revealedTileCount = 20.clamp(0, tileCount);
      _startTileRevealTimer(tileCount);
    }

    final Set<int> revealedTiles =
        _tileRevealOrder.take(_revealedTileCount).toSet();
    final bool allRevealed = _revealedTileCount >= tileCount;

    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TileRevealImage(
                songId: targetSongId,
                size: 200,
                tileCount: tileCount,
                revealedTiles: revealedTiles,
                emptyColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已揭示 $_revealedTileCount / $tileCount 块'
            '${_tileRevealPaused ? '（已暂停）' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!allRevealed)
            TextButton.icon(
              onPressed: _toggleTileRevealPause,
              icon: Icon(
                _tileRevealPaused ? Icons.play_arrow : Icons.pause,
                size: 18,
              ),
              label: Text(_tileRevealPaused ? '继续揭示' : '暂停揭示'),
            ),
        ],
      ),
    );
  }

  /// 启动拼图定时揭示（间隔来自房间设置）
  void _startTileRevealTimer(int tileCount) {
    _tileRevealTimer?.cancel();
    final int intervalMs = _currentRoom?.tileRevealIntervalMs ?? 1500;
    final int batchSize =
        tileCount > 200 ? max(1, (tileCount / 40).round()) : 5;

    _tileRevealTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (!mounted || (_gameState?.isGameOver ?? false)) {
        t.cancel();
        return;
      }
      if (_tileRevealPaused || _revealedTileCount >= tileCount) return;
      setState(() {
        _revealedTileCount =
            (_revealedTileCount + batchSize).clamp(0, tileCount);
      });
      if (_revealedTileCount >= tileCount) t.cancel();
    });
  }

  /// 暂停 / 继续揭示（只影响本机观感，不影响判定）
  void _toggleTileRevealPause() {
    setState(() {
      _tileRevealPaused = !_tileRevealPaused;
    });
  }

  /// 构建谱面片段提示（chartPeek 模式）
  ///
  /// 谱面取自本机 maidata 缓存（没有就按需拉一次），难度池 ∩ 房间定数范围
  /// 用确定性种子挑一个难度，片段窗口同样是确定性种子 —— 三种随机量都加盐隔离，
  /// 保证所有玩家看到同一段谱面。进回合自动播一次，之后可手动复播（每人独立计数）。
  Widget _buildChartPeekHint(
      String roomId, int roundNumber, String targetSongId) {
    final bool isGameOver = _gameState?.isGameOver ?? false;
    final bool isRoundOver = _gameState?.isRoundOver ?? false;
    // 回合结束后进入「答案模式」：与单人一致，可无限复播（音频就绪后带声音）
    final bool answerMode = isGameOver || isRoundOver;

    if (_peekUnavailableReason != null) {
      return Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            _peekUnavailableReason!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final SimaiPlayerController? controller = _peekController;
    if (controller == null) {
      // 本回合还没准备好谱面：触发一次（幂等，靠 _peekPreparing 防重入）
      if (!_peekPreparing) {
        _prepareChartPeek(roomId, roundNumber, targetSongId);
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              '正在准备谱面片段…',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final bool canReplay = answerMode || _peekReplaysLeft > 0;

    // 复播按钮文案（与单人谱面片段猜歌同一套说法）
    final String replayLabel;
    if (_peekPlaying) {
      replayLabel = '暂停';
    } else if (answerMode) {
      if (_peekAnswerAudioFailed) {
        replayLabel = '复播片段（音频不可用）';
      } else if (_peekAnswerAudioReady) {
        replayLabel = '复播片段（带音频）';
      } else {
        replayLabel = '复播片段（音频准备中）';
      }
    } else {
      replayLabel = '复播片段（还可复播 $_peekReplaysLeft 次）';
    }

    final String hintText;
    if (answerMode) {
      hintText = _peekAnswerAudioFailed
          ? '本局答案：片段可无限复播（音频不可用，仅有谱面）'
          : (_peekAnswerAudioReady
              ? '本局答案：片段可无限复播，带音频'
              : '本局答案：片段可无限复播（正在准备音频…）');
    } else {
      hintText = '片段播完会自动停在结尾';
    }

    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: SimaiPlayer(controller: controller),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 本回合播放难度的标签（与单人同一套名字与底色）
              if (_peekResolvedInote != null &&
                  GuessChartByChartPeekPage.difficultyNames
                      .containsKey(_peekResolvedInote))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: GuessChartByChartPeekPage
                            .difficultyColors[_peekResolvedInote] ??
                        Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    GuessChartByChartPeekPage
                            .difficultyNames[_peekResolvedInote] ??
                        '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: canReplay
                    ? (_peekPlaying ? _pausePeek : _replayPeek)
                    : null,
                icon: Icon(
                  (_peekClipFinished || (answerMode && !_peekAnswerAudioFailed))
                      ? Icons.replay
                      : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(replayLabel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hintText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 准备本回合的谱面片段（缓存优先，缺失则按需拉取）
  Future<void> _prepareChartPeek(
      String roomId, int roundNumber, String targetSongId) async {
    final generation = _modeGeneration;
    bool current() => mounted && !_isLeaving && generation == _modeGeneration;
    _peekPreparing = true;
    try {
      final manager = MaidataManager();
      await manager.initialize();
      if (!current()) return;

      String? content = manager.getMaidata(targetSongId);
      if (content == null || content.isEmpty) {
        // 多人抽曲由服务端决定，本机不一定缓存了这首 → 按需拉一次
        await manager.fetchMaidataForSongIds([targetSongId]);
        content = manager.getMaidata(targetSongId);
      }
      if (!current()) return;
      if (content == null || content.isEmpty) {
        setState(() => _peekUnavailableReason = '本机没有该曲的谱面缓存，自动拉取也没拿到');
        return;
      }

      final simaiFile = SimaiFile(content);
      final Song? song = _targetSong;
      final List<String> pool = _currentRoom?.peekDifficulties ?? const ['4'];
      final List<String> eligible = song == null
          ? const <String>[]
          : GuessChartByChartPeekPage.eligibleInotesFor(
              song: song,
              pool: pool,
              masterMinDx: _currentRoom?.masterMinDx ?? 1.0,
              masterMaxDx: _currentRoom?.masterMaxDx ?? 15.0,
              hasInote: (inote) => content!.contains('&inote_$inote'),
            );
      final String? inote = GameSeedUtil.pickDeterministic(
        roomId: roomId,
        roundNumber: roundNumber,
        targetSongId: targetSongId,
        candidates: eligible,
        salt: 'chartPeekDifficulty',
      );
      if (inote == null) {
        setState(() => _peekUnavailableReason = '这首曲没有符合难度池 / 定数范围的谱面');
        return;
      }

      final String? chartText = simaiFile.getValue('inote_$inote');
      if (chartText == null) {
        setState(() => _peekUnavailableReason = '未能读取该曲 inote_$inote 谱面');
        return;
      }

      final chart = SimaiConvert.deserialize(chartText);

      // 谱面总时长（与单人谱面片段猜歌同口径）
      double totalDuration = chart.finishTiming ?? 0.0;
      for (final collection in chart.noteCollections) {
        if (collection.time.isFinite) {
          totalDuration = max(totalDuration, collection.time);
        }
        for (final note in collection) {
          final holdEnd = collection.time + (note.length ?? 0.0);
          if (holdEnd.isFinite) totalDuration = max(totalDuration, holdEnd);
          for (final slide in note.slidePaths) {
            final slideEnd = collection.time + slide.delay + slide.duration;
            if (slideEnd.isFinite) totalDuration = max(totalDuration, slideEnd);
          }
        }
      }
      if (totalDuration <= 1.0) {
        setState(() => _peekUnavailableReason = '谱面过短，无法截取片段');
        return;
      }

      final double clipLength = min(
        (_currentRoom?.peekDurationSeconds ?? 8).toDouble(),
        max(totalDuration - 1.0, 0.5),
      );
      final ClipWindow window = GameSeedUtil.generateClipWindow(
        roomId: roomId,
        roundNumber: roundNumber,
        targetSongId: targetSongId,
        totalDuration: totalDuration,
        clipLength: clipLength,
      );

      final controller = GuessChartByChartPeekPage.buildChartOnlyController(
        chart: chart,
        initialChartTime: window.start,
      );
      controller.timeNotifier.addListener(_onPeekTimeChanged);
      if (!current()) {
        controller.dispose();
        return;
      }

      setState(() {
        _peekController = controller;
        _peekClipStart = window.start;
        _peekClipEnd = window.end;
        _peekPlaying = false;
        _peekClipFinished = false;
        _peekResolvedInote = inote;
        _peekChart = chart;
        // 进回合自动播放一次（不计入复播次数）
        _peekReplaysLeft = kPeekMaxReplays;
      });
      if (_gameState?.isRoundOver == true || _gameState?.isGameOver == true) {
        _enterPeekAnswerModeIfNeeded();
      } else {
        _autoPlayPeek();
      }
    } catch (e) {
      debugPrint('[GameRoomPage] chartPeek 准备失败: $e');
      if (current()) {
        setState(() => _peekUnavailableReason = '谱面解析失败');
      }
    } finally {
      if (generation == _modeGeneration) _peekPreparing = false;
    }
  }

  /// 片段到点后自动暂停（停在结尾）
  void _onPeekTimeChanged() {
    final controller = _peekController;
    if (controller == null) return;
    if (controller.chartTime >= _peekClipEnd) {
      controller.pause();
      _peekClipFinished = true;
      if (mounted && _peekPlaying) {
        setState(() => _peekPlaying = false);
      }
    }
  }

  /// 进回合自动播放一次片段
  Future<void> _autoPlayPeek() async {
    final controller = _peekController;
    if (controller == null) return;
    if (_gameState?.isRoundOver != false || _hasSurrendered) return;
    try {
      await controller.seek(_peekClipStart);
      if (!mounted ||
          _isLeaving ||
          !identical(controller, _peekController) ||
          _gameState?.isRoundOver != false) return;
      await controller.play();
      if (mounted && identical(controller, _peekController))
        setState(() => _peekPlaying = true);
    } catch (error) {
      if (mounted && !_isLeaving && identical(controller, _peekController))
        setState(() => _peekUnavailableReason = '谱面片段播放失败，请重试');
    }
  }

  // ==================== chartPeek：回合结束后的答案模式 ====================
  //
  // 照搬单人「谱面片段猜歌」：
  //   1. 回合结束 → 异步取该曲音频（LuoXueSongUtil，自带磁盘缓存）；
  //   2. 用户点复播时，把播放器换成带音频的新实例（音频 position 0 与片段
  //      起点对齐），此后可**无限次**复播，边听边对答案；
  //   3. 音频拿不到就保持无声，界面上如实说明。

  /// 回合结束只进入一次答案模式（服务端多次推送回合结束 / 本地抢先置位都安全）。
  void _enterPeekAnswerModeIfNeeded() {
    if (_peekAnswerModeEntered) return;
    final gameType = _currentRoom?.gameType ?? widget.room.gameType;
    if (gameType != GameType.chartPeek) return;
    if (_targetSong == null || _peekChart == null) return;
    _peekAnswerModeEntered = true;
    unawaited(_enterPeekAnswerMode());
  }

  Future<void> _enterPeekAnswerMode() async {
    final generation = _modeGeneration;
    await _peekController?.pause();
    if (!mounted || _isLeaving || generation != _modeGeneration) return;
    if (mounted) setState(() => _peekPlaying = false);
    final song = _targetSong;
    if (song == null || _peekChart == null) return;
    // 异步取音频，不阻塞答案展示
    unawaited(_preparePeekAnswerAudio(song));
  }

  Future<void> _preparePeekAnswerAudio(Song song) async {
    final generation = _modeGeneration;
    bool current() => mounted && !_isLeaving && generation == _modeGeneration;
    try {
      final int musicId = LuoXueSongUtil.toLxnsMusicId(song.id);
      if (musicId <= 0) {
        debugPrint('[GameRoomPage] chartPeek 歌曲 id 异常，答案模式保持无声: ${song.id}');
        if (current()) setState(() => _peekAnswerAudioFailed = true);
        return;
      }
      final file = await LuoXueSongUtil().getMusicFile(musicId.toString());
      if (!current() || !_peekAnswerModeEntered) return;
      if (file == null) {
        setState(() => _peekAnswerAudioFailed = true);
        return;
      }
      _peekAnswerAudioPath = file.path;
      setState(() => _peekAnswerAudioReady = true);
      debugPrint('[GameRoomPage] chartPeek 答案音频就绪: ${file.path}');
    } catch (e) {
      debugPrint('[GameRoomPage] chartPeek 答案音频获取失败: $e');
      if (current()) setState(() => _peekAnswerAudioFailed = true);
    }
  }

  /// 把片段播放器换成带音频的实例并定位到片段起点。
  ///
  /// 对齐原理（与单人一致）：包内音频时钟满足 chartTime = audioPosition + offset，
  /// offset = initialChartTime + musicOffsetMs/1000。答案播放器把 initialChartTime
  /// 设为 0（offset = 0），随后 seek(_clipStart) 会把谱面时间与音频位置一起放到
  /// 片段起点；若沿用 initialChartTime = _clipStart，播出来的是整首歌的开头。
  Future<void> _rebuildPeekPlayerWithAudio() async {
    final chart = _peekChart;
    final path = _peekAnswerAudioPath;
    if (chart == null || path == null || !mounted) return;

    _peekController?.timeNotifier.removeListener(_onPeekTimeChanged);
    _peekController?.dispose();

    final controller = GuessChartByChartPeekPage.buildChartOnlyController(
      chart: chart,
      audioFilePath: path,
      initialChartTime: 0,
    );
    setState(() {
      _peekController = controller;
      _peekClipFinished = false;
      _peekAudioAttached = true;
    });
    controller.timeNotifier.addListener(_onPeekTimeChanged);

    // 音频刚交给 game 还在异步加载，等 game 就绪再 seek，
    // 否则 seek 的同步音频分支会因 handle 未建而丢位置。
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted || !identical(_peekController, controller)) return;
    await controller.seek(_peekClipStart);
  }

  /// 手动复播（对局中消耗复播次数；结束后不限次）
  Future<void> _replayPeek() async {
    final controller = _peekController;
    if (controller == null) return;
    final bool isGameOver = _gameState?.isGameOver ?? false;
    final bool isRoundOver = _gameState?.isRoundOver ?? false;
    final bool answerMode = isGameOver || isRoundOver;
    if (!answerMode && _peekReplaysLeft <= 0) {
      Fluttertoast.showToast(msg: '复播次数已用完');
      return;
    }
    if (!answerMode) {
      setState(() => _peekReplaysLeft--);
    }

    if (answerMode && _peekAnswerAudioReady && _peekAnswerAudioPath != null) {
      // 答案模式：第一次复播时换成带音频的播放器（之后复用，不再重建）
      if (!_peekAudioAttached) {
        await _rebuildPeekPlayerWithAudio();
      } else {
        await _peekController?.seek(_peekClipStart);
      }
    } else {
      await controller.seek(_peekClipStart);
    }
    await _peekController?.play();
    if (mounted) setState(() => _peekPlaying = true);
  }

  /// 暂停片段播放
  Future<void> _pausePeek() async {
    await _peekController?.pause();
    if (mounted) setState(() => _peekPlaying = false);
  }

  /// 构建曲绘截取提示（cover 模式）
  Widget _buildCroppedCoverHint(
      String roomId, int roundNumber, String targetSongId) {
    // 使用确定性种子生成截取区域，确保所有玩家看到相同的截取
    if (_cropRect == null) {
      _cropRect = GameSeedUtil.generateCropRect(
        roomId: roomId,
        roundNumber: roundNumber,
        targetSongId: targetSongId,
      );
    }

    final rect = _cropRect!;
    final double size = 200.0;
    final bool isGameOver = _gameState?.isGameOver ?? false;
    // 提前解析实际存在的资源，避免倒计时、搜索或主题重建时反复触发
    // 不存在的 DX 原始 ID 的 errorBuilder，导致已加载的备用曲绘消失。
    final provider = _croppedCoverProvider;

    return Center(
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGameOver
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 完整曲绘
                  if (provider != null)
                    Image(
                        image: provider,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            CoverUtil.buildCoverWidgetWithContext(
                                context, targetSongId, size))
                  else
                    const ColoredBox(color: Colors.black),
                  // 游戏未结束时用黑色遮盖非截取区域
                  if (!isGameOver) ...[
                    // 顶部遮盖
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: rect.y1 * size,
                      child: Container(color: Colors.black),
                    ),
                    // 底部遮盖
                    Positioned(
                      top: rect.y2 * size,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(color: Colors.black),
                    ),
                    // 左侧遮盖
                    Positioned(
                      top: rect.y1 * size,
                      left: 0,
                      width: rect.x1 * size,
                      height: (rect.y2 - rect.y1) * size,
                      child: Container(color: Colors.black),
                    ),
                    // 右侧遮盖
                    Positioned(
                      top: rect.y1 * size,
                      left: rect.x2 * size,
                      right: 0,
                      height: (rect.y2 - rect.y1) * size,
                      child: Container(color: Colors.black),
                    ),
                  ],
                  // 游戏结束后用红框标示截取区域
                  if (isGameOver)
                    Positioned(
                      left: rect.x1 * size,
                      top: rect.y1 * size,
                      width: rect.width * size,
                      height: rect.height * size,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isGameOver)
            Text(
              '根据截取的曲绘部分猜歌名',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建模糊曲绘提示（blurred 模式）
  Widget _buildBlurredCoverHint(
      String roomId, int roundNumber, String targetSongId) {
    final int blurLevel = _currentRoom?.blurLevel ?? 50;
    final bool isGameOver = _gameState?.isGameOver ?? false;

    // 使用确定性种子微调模糊程度，确保所有玩家一致
    final int effectiveBlur = GameSeedUtil.generateBlurLevel(
      roomId: roomId,
      roundNumber: roundNumber,
      targetSongId: targetSongId,
      baseBlurLevel: blurLevel,
    );

    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGameOver
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isGameOver
                  ? CoverUtil.buildCoverWidgetWithContext(
                      context, targetSongId, 200)
                  : ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: effectiveBlur / 3,
                        sigmaY: effectiveBlur / 3,
                      ),
                      child: CoverUtil.buildCoverWidgetWithContext(
                          context, targetSongId, 200),
                    ),
            ),
          ),
          if (!isGameOver) ...[
            const SizedBox(height: 8),
            Text(
              '模糊程度: $effectiveBlur%',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建音频播放器提示（audio 模式）
  Widget _buildAudioPlayerHint(
      String roomId, int roundNumber, String targetSongId) {
    final int playDuration = _currentRoom?.playDuration ?? 5;
    final bool isGameOver = _gameState?.isGameOver ?? false;

    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2979FF), Color(0xFF7C4DFF)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_currentRoom?.gameType.name ?? '歌曲片段',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // 进度条（拖动仅预览位置；音频以服务端种子的起始点整段播放，
            // 不支持 seek 到任意位置——只是把拖动反馈做得更平滑）
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: _currentPosition.clamp(
                    0.0,
                    _totalDuration > 0
                        ? _totalDuration
                        : playDuration.toDouble()),
                min: 0.0,
                max: _totalDuration > 0
                    ? _totalDuration
                    : playDuration.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _currentPosition = value;
                  });
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            // 时间显示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentPosition.toStringAsFixed(1)} 秒',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '${_totalDuration > 0 ? _totalDuration : playDuration} 秒',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 播放/暂停按钮
            ElevatedButton.icon(
              onPressed: isGameOver ||
                      _audioLoading ||
                      !_canAct ||
                      _hasSurrendered
                  ? null
                  : (_isPlaying
                      ? _pausePlayback
                      : () =>
                          _playSongExcerpt(roomId, roundNumber, targetSongId)),
              icon: Icon(
                isGameOver
                    ? Icons.block
                    : (_isPlaying ? Icons.pause : Icons.play_arrow),
                size: 20,
              ),
              label: Text(
                isGameOver
                    ? '游戏已结束'
                    : (_audioLoading
                        ? '正在加载音频…'
                        : _isPlaying
                            ? '暂停'
                            : (_hasPlayed ? '重新播放' : '播放歌曲片段')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2979FF),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 播放歌曲片段（使用确定性起始时间）
  Future<void> _playSongExcerpt(
      String roomId, int roundNumber, String targetSongId) async {
    if (_targetSong == null || _audioLoading || !_canAct || _hasSurrendered)
      return;
    final generation = _modeGeneration;
    bool current() =>
        mounted &&
        !_isLeaving &&
        generation == _modeGeneration &&
        _gameState?.isRoundOver == false &&
        !_hasSurrendered;
    final playDuration = _currentRoom?.playDuration ?? 5;
    AudioPlayer? player;
    setState(() => _audioLoading = true);
    try {
      _playbackTimer?.cancel();
      final previous = _audioPlayer;
      _audioPlayer = null;
      await previous?.dispose();
      if (!current()) return;
      final utility = LuoXueSongUtil();
      final musicId = LuoXueSongUtil.toLxnsMusicId(targetSongId);
      if (musicId <= 0) throw StateError('歌曲编号无效');
      final mode = switch (_currentRoom?.gameType) {
        GameType.reverseAudio => GuessAudioMode.reverseAudio,
        GameType.pitchAudio => GuessAudioMode.pitchAudio,
        _ => GuessAudioMode.normal,
      };
      player = AudioPlayer();
      _audioPlayer = player;
      if (mode == GuessAudioMode.normal) {
        final file = await utility.getMusicFile(musicId.toString());
        if (!current()) return;
        if (file == null) throw StateError('未能获取音频，请稍后重试');
        final durationEvent = player.onDurationChanged.first
            .timeout(const Duration(seconds: 3))
            .then<Duration?>((value) => value, onError: (_) => null);
        await player.setSource(DeviceFileSource(file.path));
        if (!current()) return;
        final duration = await player.getDuration() ?? await durationEvent;
        if (!current()) return;
        if (duration == null || duration <= Duration.zero)
          throw StateError('无法读取音源时长');
        _audioStartTime ??= GameSeedUtil.generateAudioStartTime(
            roomId: roomId,
            roundNumber: roundNumber,
            targetSongId: targetSongId,
            totalDuration: duration.inSeconds,
            playDuration: playDuration);
        await player.seek(Duration(seconds: _audioStartTime!));
      } else {
        final file = await GuessAudioService.excerpt(
            musicId: musicId.toString(),
            mode: mode,
            start: 0,
            duration: playDuration,
            rate: _currentRoom?.audioRate ?? 1.25,
            seed:
                '$roomId-${_gameState?.roundId ?? roundNumber}-$targetSongId');
        if (!current()) return;
        await player.setSource(DeviceFileSource(file.path));
      }
      if (!current() || !identical(player, _audioPlayer)) return;
      await player.resume();
      if (!current() || !identical(player, _audioPlayer)) return;
      setState(() {
        _isPlaying = true;
        _totalDuration = playDuration.toDouble();
        _currentPosition = 0;
      });
      final started = DateTime.now();
      _playbackTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!current() || !_isPlaying) {
          timer.cancel();
          return;
        }
        final elapsed =
            DateTime.now().difference(started).inMilliseconds / 1000;
        setState(
            () => _currentPosition = min(elapsed, playDuration.toDouble()));
        if (elapsed >= playDuration) _handlePlaybackComplete();
      });
    } catch (error) {
      if (current()) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('音频播放失败：$error')));
      }
    } finally {
      if (!current() && player != null && identical(player, _audioPlayer)) {
        _audioPlayer = null;
        await player.dispose();
      }
      if (mounted && generation == _modeGeneration)
        setState(() => _audioLoading = false);
    }
  }

  void _handlePlaybackComplete() {
    _playbackTimer?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.stop();
    setState(() {
      _isPlaying = false;
      _hasPlayed = true;
      _currentPosition = _totalDuration;
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  /// 在新回合开始时重置模式专属状态
  /// 清空搜索框与搜索结果（换回合 / 开始新游戏时调用）。
  ///
  /// 为什么必须清：输入框里留着上一回合的关键字时，新回合的候选列表会被旧
  /// 关键字过滤，玩家看到「搜不出歌」，或者以为要重新输入而耽误抢答——
  /// 结果就是白白丢掉一次获胜机会。
  void _clearSearchInput() {
    _searchTimer?.cancel();
    _searchGeneration++;
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _searchResults = [];
    _showSearchResults = false;
    _isSearching = false;
  }

  void _resetModeSpecificState() {
    _modeGeneration++;
    _guessDetails.clear();
    _audioLoading = false;
    _openLetterController.clear();
    _cropRect = null;
    _croppedCoverProvider = null;
    _audioStartTime = null;
    _isPlaying = false;
    _hasPlayed = false;
    _currentPosition = 0.0;
    _totalDuration = 0.0;
    _playbackTimer?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;

    // flash：回合开始就闪现一次（时长来自房间设置，各端一致）
    _flashTimer?.cancel();
    _flashVisible = false; // 图片实际解码就绪后才开始快闪。

    // tileReveal：顺序/进度由题面构建时按确定性种子惰性初始化
    _tileRevealTimer?.cancel();
    _tileRevealOrder = const [];
    _revealedTileCount = 0;
    _tileRevealPaused = false;

    // chartPeek：谱面片段（控制器、窗口、复播次数、答案模式）
    _peekController?.timeNotifier.removeListener(_onPeekTimeChanged);
    _peekController?.dispose();
    _peekController = null;
    _peekClipStart = 0.0;
    _peekClipEnd = 0.0;
    _peekPlaying = false;
    _peekPreparing = false;
    _peekClipFinished = false;
    _peekUnavailableReason = null;
    _peekReplaysLeft = kPeekMaxReplays;
    _peekResolvedInote = null;
    _peekChart = null;
    _peekAnswerModeEntered = false;
    _peekAnswerAudioReady = false;
    _peekAnswerAudioFailed = false;
    _peekAudioAttached = false;
    _peekAnswerAudioPath = null;
  }

  /// 回合开始时的曲绘快闪：先显示，flashDurationMs 之后消失。
  void _startFlashCover() {
    final GameType gameType = _currentRoom?.gameType ?? widget.room.gameType;
    if (gameType != GameType.flash) return;

    final int flashDurationMs = _currentRoom?.flashDurationMs ?? 300;
    _flashVisible = true;
    _flashTimer = Timer(Duration(milliseconds: flashDurationMs), () {
      if (!mounted) return;
      setState(() => _flashVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = _currentRoom ?? widget.room;
    final waiting = room.status == RoomStatus.waiting && _gameState == null;
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _canPopAfterLeave,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showLeaveRoomConfirmDialog();
      },
      child: AbsorbPointer(
        absorbing: _isLeaving,
        child: BackgroundPageScaffold(
          title: '多人房间',
          onBack: _showLeaveRoomConfirmDialog,
          resizeToAvoidBottomInset: false,
          child: Column(children: [
            if (_isLeaving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('正在退出房间…'),
              ),
            if (_initializationError != null)
              MaterialBanner(
                content: Text(_initializationError!),
                leading: Icon(Icons.wifi_off_rounded, color: scheme.error),
                actions: [
                  TextButton(onPressed: _initRoom, child: const Text('重新连接'))
                ],
              ),
            if (_hostChangeMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(_hostChangeMessage!,
                    style: TextStyle(color: scheme.primary)),
              ),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final gameArea = _buildGameArea(Theme.of(context).brightness);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    24 +
                        MediaQuery.viewInsetsOf(context).bottom +
                        (waiting ? 0 : MediaQuery.paddingOf(context).bottom)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MultiplayerRoomHeader(room: room, compact: !waiting),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 280, child: _buildPlayerList()),
                              const SizedBox(width: 28),
                              Expanded(child: gameArea),
                            ])
                      else ...[
                        _buildPlayerList(),
                        const SizedBox(height: 24),
                        gameArea,
                      ],
                    ]),
              );
            })),
            if (waiting)
              MultiplayerRoomReadyBar(
                  room: room,
                  player: _currentPlayer,
                  busy: _actionPending,
                  onReady: _handleReady,
                  onStart: _handleStartGame),
          ]),
        ),
      ),
    );
  }
}
