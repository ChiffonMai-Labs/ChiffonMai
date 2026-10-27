import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../../entity/Multiplayer/GameType.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

// 消息回调类型
typedef MessageCallback = void Function(Map<String, dynamic> message);

class WebSocketBroadcastService {
  static final WebSocketBroadcastService _instance =
      WebSocketBroadcastService._internal();
  factory WebSocketBroadcastService() => _instance;
  WebSocketBroadcastService._internal();

  WebSocketChannel? _channel;
  Future<void>? _connecting;
  final Map<String, List<MessageCallback>> _listeners = {};
  bool _isConnected = false;
  String? _currentPlayerId;

  // 重连成功回调
  void Function()? onReconnected;

  // 是否正在主动断开连接（用于区分主动断开和被动断开）
  bool _isDisconnecting = false;

  // 心跳相关
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastHeartbeatReceived;
  static const int _heartbeatInterval = 30; // 心跳间隔（秒）- 增加到30秒
  static const int _heartbeatTimeout = 90; // 心跳超时时间（秒）- 增加到90秒
  int _reconnectAttempts = 0;
  // 退避 2/4/8/16/30/30/30/30 ≈ 150s。**必须覆盖服务端的断线宽限期（120s）**：
  // 原来只有 5 次（≈62s），切后台超过一分钟就彻底放弃重连，
  // 座位还在宽限期里等着也没人来坐，等于白留。
  static const int _maxReconnectAttempts = 8;

  // 保存连接信息用于重连
  String? _host;
  String? _appkey;
  String? _username;
  int _avatarId = 1;
  String? _roomId;
  String? _roundId;
  int _requestSerial = 0;

  /// 回合令牌阻止延迟操作串到下一回合；请求编号供服务端识别网络重发。
  Map<String, dynamic> _roundCommandPayload(
          [Map<String, dynamic> fields = const {}]) =>
      {
        ...fields,
        if (_roomId != null) 'roomId': _roomId,
        if (_roundId != null) 'roundId': _roundId,
        'requestId':
            '${DateTime.now().microsecondsSinceEpoch}-${_requestSerial++}',
      };

  /// 本机上一位玩家的 ID：重连时重放给服务端，用来接回原座位。
  String? _resumePlayerId;

  /// 最近一次 `initialized` 是否是服务端把我们**接回原座位**（`resumed: true`）。
  /// true 时房间/对局状态由服务端补发，客户端不该再 joinRoom。
  bool _lastInitResumed = false;

  bool get lastInitResumed => _lastInitResumed;

  // 获取当前玩家ID
  String? get currentPlayerId => _currentPlayerId;

  Future<void> initialize({
    required String host,
    String appkey = '',
    String? username,
  }) async {
    if (_connecting != null) return _connecting!;
    final pending = _connect(host: host, appkey: appkey, username: username);
    _connecting = pending;
    try {
      await pending;
    } finally {
      if (identical(_connecting, pending)) _connecting = null;
    }
  }

  Future<void> _connect({
    required String host,
    required String appkey,
    String? username,
  }) async {
    // 重置主动断开标志，允许重连
    _isDisconnecting = false;

    // 保存连接信息用于重连
    _host = host;
    _appkey = appkey;
    _username = username;

    try {
      // 如果已连接且连接正常，直接返回，不重新连接
      // 只有在连接断开或未连接时才建立新连接
      if (_isConnected && _channel != null) {
        debugPrint('[WebSocket] 已连接，跳过初始化');
        return;
      }

      // 构建 WebSocket URL。生产连接必须走 TLS，避免房间消息被明文窃听。
      String wsUrl = host;
      if (host.startsWith('http://')) {
        wsUrl = 'wss://' + host.substring(7);
      } else if (host.startsWith('https://')) {
        wsUrl = 'wss://' + host.substring(8);
      } else if (host.startsWith('ws://')) {
        wsUrl = 'wss://' + host.substring(5);
      } else if (!host.startsWith('wss://')) {
        wsUrl = 'wss://' + host;
      }

      debugPrint('[WebSocket] 连接到: $wsUrl');

      final url = Uri.parse(wsUrl);
      final local = const ['localhost', '127.0.0.1', '::1'].contains(url.host);
      final endpoint =
          local && (host.startsWith('ws://') || host.startsWith('http://'))
              ? url.replace(scheme: 'ws')
              : url;
      final channel = WebSocketChannel.connect(endpoint);
      _channel = channel;

      channel.stream.listen(
        (message) {
          if (!identical(_channel, channel)) return;
          _handleMessage(message);
        },
        onError: (error) {
          if (!identical(_channel, channel)) return;
          debugPrint('[WebSocket] 错误: $error');
          _isConnected = false;
          _stopHeartbeat();
          // 如果不是主动断开，才触发重连
          if (!_isDisconnecting) {
            _scheduleReconnect();
          }
        },
        onDone: () {
          if (!identical(_channel, channel)) return;
          debugPrint('[WebSocket] 连接关闭');
          _isConnected = false;
          _stopHeartbeat();
          // 如果不是主动断开，才触发重连
          if (!_isDisconnecting) {
            _scheduleReconnect();
          }
        },
      );

      // 等待连接真正建立
      await channel.ready.timeout(const Duration(seconds: 10));
      if (_isDisconnecting || !identical(_channel, channel)) {
        throw StateError('连接已取消');
      }

      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('[WebSocket] 连接成功');

      // 启动心跳
      _startHeartbeat();
    } catch (e) {
      _isConnected = false;
      debugPrint('[WebSocket] 初始化失败: $e');
      rethrow;
    }
  }

  // 启动心跳定时器
  void _startHeartbeat() {
    _stopHeartbeat();

    // 发送心跳消息
    _sendHeartbeat();

    // 设置定时发送心跳
    _heartbeatTimer =
        Timer.periodic(Duration(seconds: _heartbeatInterval), (timer) {
      _sendHeartbeat();

      // 检查心跳超时
      if (_lastHeartbeatReceived != null) {
        Duration elapsed = DateTime.now().difference(_lastHeartbeatReceived!);
        if (elapsed.inSeconds > _heartbeatTimeout) {
          debugPrint('[WebSocket] 心跳超时，尝试重连');
          _isConnected = false;
          _stopHeartbeat();
          _scheduleReconnect();
        }
      }
    });
  }

  // 停止心跳定时器
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // 发送心跳消息
  void _sendHeartbeat() {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      final data = json.encode({
        'action': 'heartbeat',
        'payload': {},
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送心跳');
    } catch (e) {
      debugPrint('[WebSocket] 发送心跳失败: $e');
    }
  }

  // 调度重连（使用指数退避策略）
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocket] 已达到最大重连次数，停止尝试');
      return;
    }

    _reconnectTimer?.cancel();

    // 指数退避：第n次重连延迟为 2^n 秒，最多30秒
    int delay = (pow(2, _reconnectAttempts)).toInt();
    delay = delay > 30 ? 30 : delay;

    debugPrint('[WebSocket] ${delay}秒后进行第 ${_reconnectAttempts + 1} 次重连...');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnect();
    });
  }

  // 尝试重连
  Future<void> _reconnect() async {
    _reconnectAttempts++;
    debugPrint('[WebSocket] 第 $_reconnectAttempts 次尝试重连...');

    try {
      // 关闭旧连接
      _channel?.sink.close(status.normalClosure);
      _channel = null;
      _isConnected = false;

      // 使用保存的连接信息重新初始化
      if (_host != null) {
        await initialize(
          host: _host!,
          appkey: _appkey ?? '',
          username: _username,
        );
        debugPrint('[WebSocket] 重连成功');

        // 重连后必须**重放一次 initialize**：服务端要靠 resumePlayerId 才能把这条
        // 新 socket 接回原座位。少了这一步，服务端只看到一个陌生连接，
        // 而原座位还在断线宽限期里等着 —— 玩家就真的被挤出去了。
        _lastInitResumed = false;
        await sendInitialize(_username,
            resumePlayerId: _resumePlayerId, avatarId: _avatarId);

        // 调用重连成功回调
        if (onReconnected != null) {
          debugPrint('[WebSocket] 触发重连成功回调');
          onReconnected!();
        }
      } else {
        debugPrint('[WebSocket] 无法重连：没有保存连接信息');
      }
    } catch (e) {
      debugPrint('[WebSocket] 重连失败: $e');
      _scheduleReconnect();
    }
  }

  // 发送初始化消息
  //
  // [resumePlayerId]：**上一次的玩家 ID**。切后台/掉线重连时带上它，
  // 服务端在断线宽限期（120s）内会把这条 socket 接回原座位 —— 分数、房主身份、
  // 房间都还在，客户端不用重新 join（对局中途本来也 join 不进去）。
  // 服务端不认识这个 ID（宽限期已过 / 旧版服务端）时会当成新玩家，行为与从前一致。
  Future<void> sendInitialize(String? nickname,
      {String? resumePlayerId, int avatarId = 1}) async {
    _avatarId = avatarId;
    // 记住身份与昵称：重连时自动重放（见 _reconnect）
    if (nickname != null && nickname.isNotEmpty) _username = nickname;
    if (resumePlayerId != null && resumePlayerId.isNotEmpty) {
      _resumePlayerId = resumePlayerId;
    }
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'initialize',
        'payload': {
          'nickname': nickname,
          'avatarId': _avatarId,
          if (_resumePlayerId != null) 'resumePlayerId': _resumePlayerId,
        },
      });
      debugPrint('[WebSocket] 准备发送初始化消息: $data');
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 初始化消息已发送');
    } catch (e) {
      debugPrint('[WebSocket] 发送初始化消息失败: $e');
      rethrow;
    }
  }

  /// 社区头像切换后通知房间；离线时只记住头像，重连初始化时自动带上。
  void sendUpdateAvatar(int avatarId) {
    if (_avatarId == avatarId) return;
    _avatarId = avatarId;
    if (!_isConnected || _channel == null || _currentPlayerId == null) return;
    _channel!.sink.add(json.encode({
      'action': 'update_avatar',
      'payload': {'avatarId': avatarId},
    }));
  }

  // 发送创建房间消息
  Future<void> sendCreateRoom(Map<String, dynamic> options) async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'create_room',
        'payload': options,
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送创建房间消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送创建房间消息失败: $e');
      rethrow;
    }
  }

  // 发送加入房间消息（支持房间ID或房间码）
  Future<void> sendJoinRoom(String roomId, String? nickname) async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      // 添加详细的调试日志
      debugPrint(
          '[WebSocket] 准备加入房间 - roomId: "$roomId", 长度: ${roomId.length}, nickname: "$nickname"');

      String data;

      // 判断是房间ID还是房间码
      // 房间码是6位数字，房间ID是36位UUID
      if (roomId.length == 6 && RegExp(r'^\d{6}$').hasMatch(roomId)) {
        // 使用房间码加入
        debugPrint('[WebSocket] 检测到房间码，使用 join_room_by_code 动作');
        data = json.encode({
          'action': 'join_room_by_code',
          'payload': {
            'code': roomId,
            'supportedGameTypes':
                GameType.values.map((type) => type.apiKey).toList(),
            'nickname': nickname,
          },
        });
      } else {
        // 使用房间ID加入
        data = json.encode({
          'action': 'join_room',
          'payload': {
            'roomId': roomId,
            'supportedGameTypes':
                GameType.values.map((type) => type.apiKey).toList(),
            'nickname': nickname,
          },
        });
      }

      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送加入房间消息成功');
    } catch (e) {
      debugPrint('[WebSocket] 发送加入房间消息失败: $e');
      rethrow;
    }
  }

  // 发送更新准备状态消息
  Future<void> sendUpdateReady(bool ready) async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'update_ready',
        'payload': {'ready': ready},
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送更新准备状态消息: $ready');
    } catch (e) {
      debugPrint('[WebSocket] 发送更新准备状态消息失败: $e');
      rethrow;
    }
  }

  // 发送开始游戏消息
  Future<void> sendStartGame() async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'start_game',
        'payload': {},
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送开始游戏消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送开始游戏消息失败: $e');
      rethrow;
    }
  }

  // 发送开始下一回合消息
  Future<void> sendStartNextRound() async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'start_next_round',
        'payload': _roundCommandPayload(),
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送开始下一回合消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送开始下一回合消息失败: $e');
      rethrow;
    }
  }

  // 发送猜测消息
  Future<void> sendGuess(String songId, String songName) async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，本次猜测未提交，请连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'submit_guess',
        'payload': _roundCommandPayload({
          'songId': songId,
          'songName': songName,
        }),
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送猜测消息: $songId');
    } catch (e) {
      debugPrint('[WebSocket] 发送猜测消息失败: $e');
      rethrow;
    }
  }

  // 发送开字母消息（letters 模式）
  Future<void> sendOpenLetter(String letter) async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'open_letter',
        'payload': _roundCommandPayload({'letter': letter}),
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送开字母消息: $letter');
    } catch (e) {
      debugPrint('[WebSocket] 发送开字母消息失败: $e');
      rethrow;
    }
  }

  // 发送离开房间消息
  Future<void> sendLeaveRoom() async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后再退出房间');
    }

    try {
      final data = json.encode({
        'action': 'leave_room',
        'payload': {},
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送离开房间消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送离开房间消息失败: $e');
      rethrow;
    }
  }

  // 发送获取房间列表消息
  Future<void> sendGetRooms() async {
    if (!_isConnected || _channel == null) {
      debugPrint('[WebSocket] 未连接，无法发送消息');
      return;
    }

    try {
      final data = json.encode({
        'action': 'get_rooms',
        'payload': {},
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送获取房间列表消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送获取房间列表消息失败: $e');
    }
  }

  // 发送投降消息
  Future<void> sendSurrender() async {
    if (!_isConnected || _channel == null) {
      throw StateError('连接已断开，请重新连接后重试');
    }

    try {
      final data = json.encode({
        'action': 'surrender',
        'payload': _roundCommandPayload(),
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送投降消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送投降消息失败: $e');
      rethrow;
    }
  }

  // 发送上传歌曲数据消息
  Future<void> sendUploadSongs(List<Map<String, dynamic>> songs) async {
    if (!_isConnected || _channel == null) {
      debugPrint('[WebSocket] 未连接，无法发送消息');
      return;
    }

    try {
      final data = json.encode({
        'action': 'upload_songs',
        'payload': {
          'songs': songs,
        },
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送上传歌曲数据消息，数量: ${songs.length}');
    } catch (e) {
      debugPrint('[WebSocket] 发送上传歌曲数据消息失败: $e');
    }
  }

  // 发送获取歌曲数量消息
  Future<void> sendGetSongCount() async {
    if (!_isConnected || _channel == null) {
      debugPrint('[WebSocket] 未连接，无法发送消息');
      return;
    }

    try {
      final data = json.encode({
        'action': 'get_song_count',
        'payload': {},
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送获取歌曲数量消息');
    } catch (e) {
      debugPrint('[WebSocket] 发送获取歌曲数量消息失败: $e');
    }
  }

  void subscribe({
    required String channel,
    required MessageCallback onMessage,
  }) {
    if (!_listeners.containsKey(channel)) {
      _listeners[channel] = [];
    }
    if (!_listeners[channel]!.contains(onMessage)) {
      _listeners[channel]!.add(onMessage);
    }
    debugPrint('[WebSocket] 订阅频道: $channel');
  }

  void unsubscribe({required String channel}) {
    _listeners.remove(channel);
    debugPrint('[WebSocket] 取消订阅频道: $channel');
  }

  Future<void> publish({
    required String channel,
    required Map<String, dynamic> message,
  }) async {
    if (!_isConnected || _channel == null) {
      debugPrint('[WebSocket] 未连接，无法发送消息');
      return;
    }

    try {
      final data = json.encode({
        'channel': channel,
        'event': 'broadcast',
        'data': message,
      });
      _channel!.sink.add(data);
      debugPrint('[WebSocket] 发送消息到频道 $channel: $message');
    } catch (e) {
      debugPrint('[WebSocket] 发送消息失败: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message.toString());
      final String action = data['action'] ?? '';
      // 避免高频打印整份歌曲与猜测历史；只保留必要的连接和错误日志。

      // 如果是初始化响应，保存玩家ID
      if (action == 'initialized') {
        _currentPlayerId = data['payload']?['playerId'];
        _lastInitResumed = data['payload']?['resumed'] == true;
        if (!_lastInitResumed) {
          _roomId = null;
          _roundId = null;
        }
        debugPrint('[WebSocket] 收到初始化响应，playerId: $_currentPlayerId'
            '${_lastInitResumed ? '（服务端已把我们接回原座位）' : ''}');
        debugPrint('[WebSocket] 响应 payload: ${data['payload']}');
      }

      final payload = data['payload'];
      if (payload is Map) {
        final room = payload['room'];
        if (room is Map &&
            (action == 'room_created' ||
                action == 'room_joined' ||
                room['id'] == _roomId)) {
          _roomId = (room['id'] ?? room['roomId'])?.toString();
          if (room.containsKey('roundId'))
            _roundId = room['roundId']?.toString();
        }
        final gameState = payload['gameState'];
        if (gameState is Map &&
            (gameState['roomId'] == _roomId || _roomId == null)) {
          _roomId = gameState['roomId']?.toString() ?? _roomId;
          if (gameState.containsKey('roundId'))
            _roundId = gameState['roundId']?.toString();
        }
      }
      if (action == 'left_room') {
        _roomId = null;
        _roundId = null;
        _resumePlayerId = null;
        _lastInitResumed = false;
      }

      // 处理心跳响应，更新最后收到心跳的时间
      if (action == 'heartbeat') {
        _lastHeartbeatReceived = DateTime.now();
        debugPrint('[WebSocket] 收到心跳响应');
      }

      // 检查是否有全局监听器
      if (_listeners.containsKey('global')) {
        for (final callback in _listeners['global']!) {
          callback(data);
        }
      }

      // 检查特定频道的监听器
      final String channel = data['channel'] ?? '';
      if (channel.isNotEmpty && _listeners.containsKey(channel)) {
        for (final callback in _listeners[channel]!) {
          callback(data['payload'] ?? {});
        }
      }

      // 如果没有指定频道，尝试使用action作为频道
      if (channel.isEmpty && _listeners.containsKey(action)) {
        for (final callback in _listeners[action]!) {
          callback(data['payload'] ?? {});
        }
      }
    } catch (e) {
      debugPrint('[WebSocket] 处理消息失败: $e');
    }
  }

  void disconnect() {
    // 标记为主动断开，防止触发重连
    _isDisconnecting = true;
    debugPrint('[WebSocket] 开始主动断开连接');

    // 停止所有定时器
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // 关闭连接
    _channel?.sink.close(status.normalClosure);
    _channel = null;

    _isConnected = false;
    _listeners.clear();

    debugPrint('[WebSocket] 已断开连接');
  }

  bool get isConnected => _isConnected;
}
