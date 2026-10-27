import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/CommunityProfileUtil.dart';

/// 玩家实体类
class PlayerEntity {
  /// 玩家ID
  final String playerId;

  /// 玩家昵称（从缓存获取）
  final String nickname;

  /// 沿用社区装扮选择的头像，旧服务端未下发时使用默认头像。
  final int avatarId;

  /// 分数
  final int score;

  /// 是否是房主
  final bool isHost;

  /// 是否准备就绪
  final bool isReady;

  /// 是否在线
  final bool isOnline;

  /// 是否投降
  final bool isSurrendered;

  /// 当前回合的猜测次数（独立于其他玩家）
  final int currentGuesses;

  PlayerEntity({
    required this.playerId,
    required this.nickname,
    this.avatarId = CommunityProfileUtil.defaultAvatarId,
    this.score = 0,
    this.isHost = false,
    this.isReady = false,
    this.isOnline = true,
    this.isSurrendered = false,
    this.currentGuesses = 0,
  });

  /// 从JSON解析（支持 snake_case、camelCase 和后端字段）
  factory PlayerEntity.fromJson(Map<String, dynamic> json) {
    return PlayerEntity(
      playerId: json['player_id'] ?? json['playerId'] ?? json['id'] ?? '',
      nickname: json['nickname'] ?? '玩家',
      avatarId: CommunityProfileUtil.normalizeAvatarId(
          json['avatarId'] ?? json['avatar_id']),
      score: json['score'] ?? 0,
      isHost: json['is_host'] ?? json['isHost'] ?? json['host'] ?? false,
      isReady: json['is_ready'] ?? json['isReady'] ?? json['ready'] ?? false,
      isOnline: json['is_online'] ??
          json['isOnline'] ??
          json['online'] ??
          json['connected'] ??
          true,
      isSurrendered: json['is_surrendered'] ??
          json['isSurrendered'] ??
          json['surrendered'] ??
          false,
      currentGuesses: json['current_guesses'] ?? json['currentGuesses'] ?? 0,
    );
  }

  /// 转换为JSON（使用 snake_case，与数据库表结构一致）
  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'nickname': nickname,
      'avatar_id': avatarId,
      'score': score,
      'is_host': isHost,
      'is_ready': isReady,
      'is_online': isOnline,
      'is_surrendered': isSurrendered,
    };
  }

  /// 创建副本并更新属性
  PlayerEntity copyWith({
    String? playerId,
    String? nickname,
    int? avatarId,
    int? score,
    bool? isHost,
    bool? isReady,
    bool? isOnline,
    bool? isSurrendered,
    int? currentGuesses,
  }) {
    return PlayerEntity(
      playerId: playerId ?? this.playerId,
      nickname: nickname ?? this.nickname,
      avatarId: avatarId ?? this.avatarId,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isOnline: isOnline ?? this.isOnline,
      isSurrendered: isSurrendered ?? this.isSurrendered,
      currentGuesses: currentGuesses ?? this.currentGuesses,
    );
  }

  /// 从缓存获取玩家昵称（与首页使用相同的键名）
  static Future<String> getCachedNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userNickname') ?? '玩家';
  }

  /// 保存玩家昵称到缓存（与首页使用相同的键名）
  static Future<void> saveNicknameToCache(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userNickname', nickname);
  }
}
