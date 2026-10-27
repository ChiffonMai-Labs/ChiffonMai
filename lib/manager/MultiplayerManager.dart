import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/RoomEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/PlayerEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameStateEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameType.dart';
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/MultiplayerCloudBaseService.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/MultiplayerGameService.dart';

class MultiplayerManager {
  static final MultiplayerManager _instance = MultiplayerManager._internal();
  factory MultiplayerManager() => _instance;
  MultiplayerManager._internal();

  final MultiplayerCloudBaseService _cloudService =
      MultiplayerCloudBaseService();
  StreamSubscription? _eventSubscription;

  String? _currentRoomId;
  RoomEntity? _currentRoom; // 当前房间（判定 letters 等模式需要）
  PlayerEntity? _currentPlayer;
  GameStateEntity? _currentGameState; // 本地缓存游戏状态
  DateTime? _gameStateReceivedAt;

  final StreamController<RoomEntity?> _roomController =
      StreamController.broadcast();
  final StreamController<GameStateEntity?> _gameStateController =
      StreamController.broadcast();
  final StreamController<List<RoomEntity>> _roomListController =
      StreamController.broadcast();
  final StreamController<String> _errorMessageController =
      StreamController.broadcast();

  Stream<RoomEntity?> get roomStream => _roomController.stream;
  Stream<GameStateEntity?> get gameStateStream => _gameStateController.stream;
  Stream<List<RoomEntity>> get roomListStream => _roomListController.stream;
  Stream<String> get errorMessageStream => _errorMessageController.stream;

  /// 当前所在房间（不在房间时为 null）。
  ///
  /// 用它可以做到「冷启动后回到房间」：进程被杀后重开时，只要服务端的
  /// 断线宽限期还没过，initialize 就会把我们接回原座位并发回 room_joined，
  /// 于是这里会有值 —— 大厅据此显示「你还在房间 XXXXXX 里，点击返回」。
  RoomEntity? get currentRoom => _currentRoom;

  String? get currentRoomId => _currentRoomId;
  GameStateEntity? get currentGameState {
    final state = _currentGameState;
    if (state == null ||
        _gameStateReceivedAt == null ||
        state.timeLimit <= 0 ||
        state.isRoundOver ||
        state.isGameOver) return state;
    final elapsed =
        DateTime.now().difference(_gameStateReceivedAt!).inMilliseconds;
    return state.copyWith(
      serverNow: state.serverNow == null ? null : state.serverNow! + elapsed,
      timeRemaining:
          (state.timeRemaining - elapsed ~/ 1000).clamp(0, state.timeLimit),
    );
  }

  /// 测试用：把服务端地址换成本机假服务端（默认 [ApiUrls.MultiplayerServerUrl]）。
  @visibleForTesting
  static String? debugServerUrlOverride;

  /// 测试用：直接注入「当前房间」（正常路径由 room_joined 事件写入）。
  @visibleForTesting
  void debugSetCurrentRoom(RoomEntity? room) {
    _currentRoom = room;
    _currentRoomId = room?.roomId;
    _roomController.add(room);
  }

  String? get currentPlayerId => _cloudService.currentPlayerId;

  Future<void> initialize({String? nickname}) async {
    debugPrint('[DEBUG][Manager] 开始初始化...');
    debugPrint('[DEBUG][Manager] 传入昵称: $nickname');

    try {
      _eventSubscription ??= _cloudService.listen(_handleCloudEvent);
      await _cloudService.initialize(
        envId: debugServerUrlOverride ?? ApiUrls.MultiplayerServerUrl,
        nickname: nickname,
      );
      debugPrint('[DEBUG][Manager] CloudService 初始化完成');
      debugPrint('[DEBUG][Manager] 当前玩家ID: ${_cloudService.currentPlayerId}');
      debugPrint('[DEBUG][Manager] 当前玩家昵称: ${_cloudService.currentNickname}');

      if (_eventSubscription == null) {
        debugPrint('[DEBUG][Manager] 创建事件订阅...');
        _eventSubscription = _cloudService.listen(_handleCloudEvent);
        debugPrint('[DEBUG][Manager] 事件订阅创建完成');
      }
    } catch (e) {
      debugPrint('[DEBUG][Manager] 初始化异常: $e');
      rethrow;
    }
  }

  void _publishGameState(GameStateEntity state) {
    if (state.roomId != null && state.roomId != _currentRoomId) return;
    // 等待房间恢复时服务端也会补发快照，尚未开始的第 0 回合不能当作对局。
    if (_currentRoom?.status == RoomStatus.waiting && state.currentRound <= 0)
      return;
    _currentGameState = state;
    _gameStateReceivedAt = DateTime.now();
    _gameStateController.add(state);
  }

  void _handleCloudEvent(MultiplayerEvent event) {
    switch (event.type) {
      case MultiplayerEventType.connected:
        break;
      case MultiplayerEventType.roomCreated:
        if (event is RoomCreatedEvent && event.room != null) {
          if (_currentRoomId != event.room.roomId ||
              event.room.status == RoomStatus.waiting) {
            _currentGameState = null;
          }
          _currentRoomId = event.room.roomId;
          _currentRoom = event.room;
          _roomController.add(event.room);
          _refreshRoomList();
        }
        break;
      case MultiplayerEventType.roomJoined:
        if (event is RoomJoinedEvent) {
          if (_currentRoomId != event.room.roomId ||
              event.room.status == RoomStatus.waiting) {
            _currentGameState = null;
          }
          _currentRoomId = event.room.roomId;
          _currentRoom = event.room;
          _currentPlayer = event.player;
          _roomController.add(event.room);
          _refreshRoomList();
        }
        break;
      case MultiplayerEventType.playerJoined:
        _refreshRoom();
        break;
      case MultiplayerEventType.playerLeft:
        _refreshRoom();
        break;
      case MultiplayerEventType.playerReady:
        _refreshRoom();
        break;
      case MultiplayerEventType.playerSurrender:
        _refreshRoom();
        break;
      case MultiplayerEventType.roundStart:
        if (event is RoundStartEvent) {
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.roundEnd:
        _refreshRoom();
        break;
      case MultiplayerEventType.roundOver:
        if (event is RoundOverEvent) {
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.gameEnd:
        if (event is GameEndEvent) {
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.gameOver:
        if (event is GameOverEvent) {
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.gameStateUpdated:
        if (event is GameStateUpdatedEvent) {
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.gameStart:
        if (event is GameStartEvent) {
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.guessResult:
        // 紧随其后的 game_state_updated / round_over 才是权威快照。
        // 不根据单条猜测预测输赢、叠加分数或结束回合。
        break;
      case MultiplayerEventType.guessUpdate:
        if (event is GuessUpdateEvent) {
          debugPrint('[DEBUG][Manager] guessUpdate event received');
          _publishGameState(event.gameState);
        }
        break;
      case MultiplayerEventType.disconnected:
        _currentRoomId = null;
        _currentRoom = null;
        _currentPlayer = null;
        _currentGameState = null;
        _roomController.add(null);
        _gameStateController.add(null);
        break;
      case MultiplayerEventType.error:
        if (event is ErrorEvent) {
          _errorMessageController.add(event.message);
        }
        break;
      case MultiplayerEventType.joinFailed:
        break;
      case MultiplayerEventType.connectionError:
        break;
      case MultiplayerEventType.hostChanged:
        _refreshRoom();
        break;
      case MultiplayerEventType.initialized:
        break;
      case MultiplayerEventType.roomUpdated:
        if (event is RoomUpdatedEvent) {
          debugPrint('[DEBUG][Manager] 收到 roomUpdated 事件，发送到 roomController');
          _currentRoom = event.room;
          _roomController.add(event.room);
        }
        break;
      case MultiplayerEventType.leftRoom:
        _currentRoomId = null;
        _currentRoom = null;
        _currentPlayer = null;
        _currentGameState = null;
        _roomController.add(null);
        _gameStateController.add(null);
        break;
      case MultiplayerEventType.readyUpdated:
        _refreshRoom();
        break;
    }
  }

  Future<RoomEntity?> createRoom({
    required GameType gameType,
    int maxPlayers = 4,
    int timeLimit = 60,
    int maxGuesses = 10,
    List<String> selectedVersions = const [],
    double masterMinDx = 1.0,
    double masterMaxDx = 15.0,
    List<String> selectedGenres = const [],
    int blurLevel = 50,
    int playDuration = 5,
    double audioRate = 1.25,
    int songCount = 3,
    int nonEnglishCharThreshold = 50,
    int flashDurationMs = 300,
    int tileCount = 1000,
    int tileRevealIntervalMs = 1500,
    int peekDurationSeconds = 8,
    List<String> peekDifficulties = const ['4'],
  }) async {
    debugPrint('[DEBUG][Manager] 开始创建房间请求...');
    debugPrint(
        '[DEBUG][Manager] 参数: gameType=${gameType.name}, maxPlayers=$maxPlayers, timeLimit=$timeLimit, maxGuesses=$maxGuesses');
    debugPrint(
        '[DEBUG][Manager] 歌曲筛选参数: selectedVersions=$selectedVersions, masterMinDx=$masterMinDx, masterMaxDx=$masterMaxDx, selectedGenres=$selectedGenres');
    debugPrint(
        '[DEBUG][Manager] 模式专属参数: blurLevel=$blurLevel, playDuration=$playDuration, songCount=$songCount');
    debugPrint('[DEBUG][Manager] 新模式参数: flashDurationMs=$flashDurationMs, '
        'tileCount=$tileCount, tileRevealIntervalMs=$tileRevealIntervalMs, '
        'peekDurationSeconds=$peekDurationSeconds, peekDifficulties=$peekDifficulties');

    await initialize();
    debugPrint('[DEBUG][Manager] 初始化完成');

    Completer<RoomEntity?> completer = Completer();
    bool completed = false;

    StreamSubscription? sub;
    sub = _cloudService.events.listen((event) {
      if (!completed) {
        debugPrint('[DEBUG][Manager] 收到事件: ${event.type}');

        if (event is RoomCreatedEvent) {
          completed = true;
          debugPrint('[DEBUG][Manager] 房间创建成功: ${event.room.roomId}');
          completer.complete(event.room);
          sub?.cancel();
        } else if (event is ErrorEvent) {
          completed = true;
          debugPrint('[DEBUG][Manager] 房间创建失败: ${event.message}');
          completer.completeError(StateError(event.message));
          sub?.cancel();
        }
      }
    });

    debugPrint('[DEBUG][Manager] 调用 CloudService.createRoom...');
    await _cloudService.createRoom(
      gameType: gameType,
      maxPlayers: maxPlayers,
      timeLimit: timeLimit,
      maxGuesses: maxGuesses,
      selectedVersions: selectedVersions,
      masterMinDx: masterMinDx,
      masterMaxDx: masterMaxDx,
      selectedGenres: selectedGenres,
      blurLevel: blurLevel,
      playDuration: playDuration,
      audioRate: audioRate,
      songCount: songCount,
      nonEnglishCharThreshold: nonEnglishCharThreshold,
      flashDurationMs: flashDurationMs,
      tileCount: tileCount,
      tileRevealIntervalMs: tileRevealIntervalMs,
      peekDurationSeconds: peekDurationSeconds,
      peekDifficulties: peekDifficulties,
    );

    debugPrint('[DEBUG][Manager] 等待房间创建结果...');
    return completer.future.timeout(const Duration(seconds: 12), onTimeout: () {
      throw TimeoutException('创建房间超时，请检查连接后重试');
    }).whenComplete(() => sub?.cancel());
  }

  Future<RoomEntity?> joinRoom(String roomId) async {
    debugPrint('[DEBUG][Manager] joinRoom called with roomId: "$roomId"');
    await initialize();

    Completer<RoomEntity?> completer = Completer();
    bool completed = false;

    StreamSubscription? sub;
    sub = _cloudService.events.listen((event) {
      if (!completed) {
        debugPrint('[DEBUG][Manager] joinRoom event received: ${event.type}');
        if (event is RoomJoinedEvent) {
          completed = true;
          debugPrint('[DEBUG][Manager] Room joined successfully');
          completer.complete(event.room);
          sub?.cancel();
        } else if (event is JoinFailedEvent) {
          completed = true;
          debugPrint('[DEBUG][Manager] Join failed: ${event.reason}');
          completer.complete(null);
          sub?.cancel();
        } else if (event is ErrorEvent) {
          completed = true;
          debugPrint('[DEBUG][Manager] Error occurred: ${event.message}');
          completer.complete(null);
          sub?.cancel();
        }
      }
    });

    debugPrint('[DEBUG][Manager] Calling cloudService.joinRoom...');
    await _cloudService.joinRoom(roomId);

    debugPrint('[DEBUG][Manager] Waiting for join result...');
    return completer.future.timeout(const Duration(seconds: 12), onTimeout: () {
      throw TimeoutException('加入房间超时，请检查房间码与网络');
    }).whenComplete(() => sub?.cancel());
  }

  Future<void> leaveRoom() async {
    await _cloudService.leaveRoom();
    final hadRoom = _currentRoom != null ||
        _currentRoomId != null ||
        _currentGameState != null;
    _currentRoomId = null;
    _currentRoom = null;
    _currentPlayer = null;
    _currentGameState = null;
    if (hadRoom) {
      _roomController.add(null);
      _gameStateController.add(null);
    }
  }

  Future<void> updatePlayerReady(bool isReady) async {
    await _cloudService.setReady(isReady);
    if (_currentPlayer != null) {
      _currentPlayer = _currentPlayer!.copyWith(isReady: isReady);
    }
  }

  Future<void> updatePlayerSurrendered(bool surrendered) async {
    await _cloudService.setSurrendered(surrendered);
  }

  Future<void> startGame() async {
    await _cloudService.startGame();
  }

  Future<void> startNextRound() async {
    await _cloudService.startNextRound();
  }

  Future<void> submitGuess(String songId, String songName) async {
    await _cloudService.submitGuess(songId, songName);
  }

  /// 开字母（letters 模式）
  Future<void> openLetter(String letter) async {
    await _cloudService.openLetter(letter);
  }

  Future<List<RoomEntity>> getRoomList() async {
    await initialize();

    try {
      return _cloudService.getWaitingRooms();
    } catch (e) {
      debugPrint('获取房间列表失败: $e');
    }

    return [];
  }

  void _refreshRoomList() async {
    final rooms = await getRoomList();
    _roomListController.add(rooms);
  }

  void _refreshRoom() async {
    if (_currentRoomId == null) return;

    try {
      final room = _cloudService.getRoomById(_currentRoomId!);

      if (room != null) {
        _roomController.add(room);
      }
    } catch (e) {
      debugPrint('刷新房间状态失败: $e');
    }
  }

  void startListeningToRoom(String roomId) {
    _currentRoomId = roomId;
    _refreshRoom();
  }

  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _cloudService.dispose();
  }
}
