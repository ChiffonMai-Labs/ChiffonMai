import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../entity/LuoXue/Collection.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AppError.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/SecureCredentialStore.dart';
import '../Account/AccountStore.dart';
import 'CommunityProfileAuthorization.dart';
import 'CommunityTravelAppearanceStore.dart';
import '../RankingList/RatingRankListService.dart';
import '../RankingList/AvgRankingListService.dart';
import '../RankingList/FittedRatingRankingListService.dart';

/// 保留原类型名称，头像与其它装扮共用同步状态。
enum AvatarSyncLevel { localOnly, syncing, synced, pending, error }

class AvatarSyncState {
  final String? playerId;
  final int avatarId, generation;
  final Map<String, dynamic>? nameplate, frame, trophy;
  final List<dynamic>? travelTeam;
  final Map<String, dynamic>? travelPartner;
  final String message;
  final bool pending;
  final AvatarSyncLevel level;
  int? get plateId => nameplate?['id'] as int?;
  int? get frameId => frame?['id'] as int?;
  int? get trophyId => trophy?['id'] as int?;
  const AvatarSyncState(
      {this.playerId,
      this.avatarId = 1,
      this.nameplate,
      this.frame,
      this.trophy,
      this.travelTeam,
      this.travelPartner,
      this.generation = 0,
      this.message = '装扮仅保存在本机',
      this.pending = false,
      this.level = AvatarSyncLevel.localOnly});
  Map<String, dynamic> get appearance => {
        'avatarId': avatarId,
        'nameplate': nameplate,
        'frame': frame,
        'trophy': trophy,
        'travelTeam': travelTeam,
        'travelPartner': travelPartner,
        'generation': generation
      };
}

/// 每账号独立的持久化待发队列；只上传有改动的字段，版本冲突时重读并重试。
class CommunityAvatarStore extends ValueNotifier<AvatarSyncState> {
  CommunityAvatarStore._() : super(const AvatarSyncState());
  static final instance = CommunityAvatarStore._();

  /// 服务端确认装扮变化并清理缓存后通知公开资料页面重新读取。
  static final profileChanges = ChangeNotifier();
  static const _endpoint = 'https://chiffonmai.cloud/api/me/appearance';
  static const _legacyOwner = 'community_avatar_legacy_owner';
  static const _localKey = 'community_appearance_local_v1';
  static const _fields = [
    'avatarId', 'nameplate', 'frame', 'trophy', 'travelTeam', 'travelPartner',
  ];
  static String _key(String player) => 'community_avatar_v1_$player';
  Future<void> _writes = Future.value();
  final Map<String, Future<void>> _syncing = {};
  final Set<String> _resync = {};
  Future<void>? _activationFuture;
  bool _activateAgain = false;
  String? _lastActivatedPlayer;

  Future<T> _queue<T>(Future<T> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Map<String, dynamic> _read(SharedPreferences prefs, String key) {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(prefs.getString(key) ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _entry(SharedPreferences prefs, String player) =>
      _read(prefs, _key(player));
  Future<void> _persist(
      SharedPreferences prefs, String key, Map<String, dynamic> entry) async {
    if (!await prefs.setString(key, jsonEncode(entry))) {
      throw AppError(
        code: 'DATA-AVATAR-SAVE',
        userMessage: '无法保存装扮，请检查存储空间后重试',
        stage: '保存社区装扮',
        source: 'local',
      ).asStateError();
    }
  }

  Set<String> _dirty(Map<String, dynamic> entry) => entry['dirtyFields'] is List
      ? (entry['dirtyFields'] as List)
          .whereType<String>()
          .where(_fields.contains)
          .toSet()
      : entry['pending'] == true
          ? {'avatarId'}
          : {};
  AvatarSyncState _state(String? player, Map<String, dynamic> entry,
      String message, AvatarSyncLevel level) {
    Map<String, dynamic>? item(String key) =>
        entry[key] is Map ? Map<String, dynamic>.from(entry[key] as Map) : null;
    return AvatarSyncState(
        playerId: player,
        avatarId: entry['avatarId'] as int? ?? 1,
        nameplate: item('nameplate'),
        frame: item('frame'),
        trophy: item('trophy'),
        travelTeam: entry['travelTeam'] is List ? entry['travelTeam'] as List : null,
        travelPartner: item('travelPartner'),
        generation: entry['generation'] as int? ?? 0,
        pending: entry['pending'] == true,
        message: message,
        level: level);
  }

  void _publish(String player, Map<String, dynamic> entry, String message,
      AvatarSyncLevel level) {
    if (value.playerId != player ||
        (value.pending &&
            value.generation > (entry['generation'] as int? ?? 0))) return;
    value = _state(player, entry, message, level);
  }

  Future<String?> _activePlayer(SharedPreferences prefs) async {
    final source = RefreshDataSource.fromKey(
        prefs.getString(CacheKeyConstant.lastDataSource));
    final marker = prefs.getString(source.userIdCacheKey);
    if (marker?.startsWith('${source.key}:') == true &&
        RefreshDataSource.parseUserIdMarker(marker) != null) return marker;
    if (source == RefreshDataSource.shuiyu &&
        (await SecureCredentialStore.read(
                    CacheKeyConstant.probeDivingFishToken))
                ?.isNotEmpty ==
            true) {
      final qq =
          prefs.getString(CacheKeyConstant.probeDivingFishBindQQ)?.trim();
      if (qq != null && RegExp(r'^[1-9]\d{4,11}$').hasMatch(qq))
        return 'shuiyu:$qq';
    }
    return null;
  }

  Future<void> _compatibility(SharedPreferences prefs, String? player,
      Map<String, dynamic> entry) async {
    if (value.playerId != player ||
        value.generation != (entry['generation'] as int? ?? 0)) return;
    if (player != await _activePlayer(prefs)) return;
    await prefs.setInt('selectedAvatarId', entry['avatarId'] as int? ?? 1);
    if (value.playerId != player || player != await _activePlayer(prefs))
      return;
    final plate =
        entry['nameplate'] is Map ? entry['nameplate']['id'] as int? : null;
    if (plate == null) {
      await prefs.remove(CacheKeyConstant.selectedPlateIdCache);
    } else {
      await prefs.setInt(CacheKeyConstant.selectedPlateIdCache, plate);
    }
    final frame = entry['frame'] is Map ? entry['frame']['id'] as int? : null;
    if (frame == null) {
      await prefs.remove(CacheKeyConstant.selectedFrameIdCache);
    } else {
      await prefs.setInt(CacheKeyConstant.selectedFrameIdCache, frame);
    }
  }

  Future<void> activate() {
    if (_activationFuture != null) {
      _activateAgain = true;
      return _activationFuture!;
    }
    final future = _runActivation();
    _activationFuture = future;
    future.whenComplete(() => _activationFuture = null);
    return future;
  }

  Future<void> _runActivation() async {
    try {
      do {
        _activateAgain = false;
        await _queue(_activate);
      } while (_activateAgain);
    } catch (_) {
      value =  AvatarSyncState(
          message: appL10n.flowCouldNotLoadAppearanceReopenThisPage, level: AvatarSyncLevel.error);
    }
  }

  Future<void> _activate() async {
    final prefs = await SharedPreferences.getInstance();
    final player = await _activePlayer(prefs);
    if (player != await _activePlayer(prefs)) {
      _activateAgain = true;
      return;
    }
    if (player == null) {
      _lastActivatedPlayer = null;
      var local = _read(prefs, _localKey);
      if (local.isEmpty && prefs.getString(_legacyOwner) == null)
        local = {
          'avatarId': prefs.getInt('selectedAvatarId') ?? 1,
          if (prefs.getInt(CacheKeyConstant.selectedPlateIdCache) != null)
            'nameplate': {
              'id': prefs.getInt(CacheKeyConstant.selectedPlateIdCache)
            }
        };
      final source = RefreshDataSource.fromKey(
          prefs.getString(CacheKeyConstant.lastDataSource));
      final message = switch (source) {
        RefreshDataSource.shuiyu => appL10n.svcSavedOnThisDeviceOnlySyncsAfter,
        RefreshDataSource.luoxue => appL10n.svcSavedOnThisDeviceOnlySignIn,
        RefreshDataSource.awmc => appL10n.svcSavedOnThisDeviceOnlyEnterThe,
      };
      value = _state(null, local, message, AvatarSyncLevel.localOnly);
      return;
    }
    var entry = _entry(prefs, player);
    // 落雪的首次装扮由服务端按上游资料初始化；不把本机默认值当成用户选择上传。
    final preferRemote = player.startsWith('luoxue:');
    final local = _read(prefs, _localKey);
    if (!preferRemote && entry.isEmpty && local['pending'] == true) {
      entry = Map<String, dynamic>.from(local);
      await _persist(prefs, _key(player), entry);
      await prefs.remove(_localKey);
    }
    if (!preferRemote &&
        entry.isEmpty &&
        prefs.getString(_legacyOwner) == null &&
        prefs.containsKey('selectedAvatarId')) {
      entry = {
        'avatarId': prefs.getInt('selectedAvatarId') ?? 1,
        'pending': true,
        'generation': 1,
        'dirtyFields': ['avatarId']
      };
    }
    if (entry['appearanceMigrated'] != true) {
      final dirty = _dirty(entry),
          plate = prefs.getInt(CacheKeyConstant.selectedPlateIdCache);
      final source = RefreshDataSource.fromKey(
          prefs.getString(CacheKeyConstant.lastDataSource));
      if (!preferRemote &&
          plate != null &&
          (prefs.getString(source.userIdCacheKey) == player ||
              prefs.getString(_legacyOwner) == null) &&
          !entry.containsKey('nameplate')) {
        entry['nameplate'] = {'id': plate};
        dirty.add('nameplate');
      }
      entry.addAll({
        'appearanceMigrated': true,
        'dirtyFields': dirty.toList(),
        'pending': dirty.isNotEmpty
      });
      await _persist(prefs, _key(player), entry);
    }
    if (prefs.getString(_legacyOwner) == null)
      await prefs.setString(_legacyOwner, player);
    if (player != await _activePlayer(prefs)) {
      _activateAgain = true;
      return;
    }
    if (_lastActivatedPlayer == player && value.playerId == player) {
      if (preferRemote) unawaited(sync(player));
      return;
    }
    _lastActivatedPlayer = player;
    value = _state(
        player,
        entry,
        entry['pending'] == true ? appL10n.svcAppearanceWaitingToSync : appL10n.svcLoadingCommunityAppearance,
        AvatarSyncLevel.syncing);
    await _compatibility(prefs, player, entry);
    unawaited(sync(player));
  }

  Future<void> select(int avatarId) => _select('avatarId', avatarId);
  Future<void> selectPlate(Collection? item) =>
      _select('nameplate', _item(item));
  Future<void> selectFrame(Collection? item) => _select('frame', _item(item));
  Future<void> selectTrophy(Collection? item) => _select('trophy', _item(item));
  Map<String, dynamic>? _item(Collection? item) => item == null
      ? null
      : {
          'id': item.id,
          'name': item.name,
          if (item.color != null) 'color': item.color
        };
  Future<void> _select(String field, dynamic choice) =>
      _selectFields({field: choice});

  Future<String> _travelAccountKey(String player) {
    final [source, id] = player.split(':');
    return AccountStore.accountKey(sourceKey: source, accountId: id);
  }

  Future<void> publishTravelAppearance(String accountKey, {
    List<CommunityTravelMember>? members,
    Collection? partner,
  }) async {
    await activate();
    final player = value.playerId;
    if (player == null || await _travelAccountKey(player) != accountKey ||
        value.playerId != player) return;
    await _selectFields({
      if (members != null) 'travelTeam': members.map((member) => member.toJson()).toList(),
      if (partner != null) 'travelPartner': _item(partner),
    });
  }

  Future<String?> cabinetImportPlayer() async {
    await activate();
    final player = value.playerId;
    if (player == null) return null;
    final headers = await CommunityProfileAuthorization.ownerHeaders(player);
    return _canSync(headers) && value.playerId == player ? player : null;
  }

  Future<({List<CommunityTravelMember>? members, Collection? partner})>
      loadTravelAppearance(String accountKey) async {
    final local = await CommunityTravelAppearanceStore(accountKey).load();
    await activate();
    final player = value.playerId;
    if (player == null || await _travelAccountKey(player) != accountKey) {
      return local;
    }
    await sync(player);
    final state = value;
    if (state.playerId != player) return local;
    return (
      members: CommunityTravelAppearanceStore.parseTeam(state.travelTeam) ??
          local.members,
      partner:
          CommunityTravelAppearanceStore.parseCharacter(state.travelPartner) ??
              local.partner,
    );
  }

  Future<bool?> importCabinetAppearance(
    String player, {
    required int? avatarId,
    required Map<String, Collection?> collectibles,
    required List<CommunityTravelMember>? members,
    required Collection? partner,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (await _activePlayer(prefs) != player || value.playerId != player) {
      return null;
    }
    // 所有已确认的选项共用一笔待发记录和同一次云端提交。
    await _selectFields({
      if (avatarId != null && avatarId > 0) 'avatarId': avatarId,
      for (final field in ['nameplate', 'frame', 'trophy'])
        if (collectibles.containsKey(field)) field: _item(collectibles[field]),
      if (members != null)
        'travelTeam': members.map((member) => member.toJson()).toList(),
      if (partner != null) 'travelPartner': _item(partner),
    });
    await sync(player);
    final entry = _entry(prefs, player);
    return entry['pending'] != true;
  }

  Future<void> _selectFields(Map<String, dynamic> choices) {
    if (choices.isEmpty) return Future.value();
    final player = value.playerId,
        optimistic = {
          ...value.appearance,
          ...choices,
          'pending': true,
          'generation': value.generation + 1
        };
    value = _state(player, optimistic, player == null ? value.message : appL10n.svcAppearanceWaitingToSync,
        player == null ? AvatarSyncLevel.localOnly : AvatarSyncLevel.pending);
    return _queue(() async {
      final prefs = await SharedPreferences.getInstance(),
          key = player == null ? _localKey : _key(player);
      final entry = player == null ? _read(prefs, key) : _entry(prefs, player);
      final dirty = _dirty(entry)..addAll(choices.keys);
      entry.addAll({
        ...choices,
        'dirtyFields': dirty.toList(),
        'pending': true,
        'generation': optimistic['generation'],
        'appearanceMigrated': true
      });
      await _persist(prefs, key, entry);
      await _compatibility(prefs, player, entry);
      if (player != null) unawaited(sync(player));
    });
  }

  /// 保留旧昵称与资料接口的来源凭据入口。
  static Future<Map<String, String>?> authorizationHeaders(String player) =>
      CommunityProfileAuthorization.legacyHeaders(player);
  Future<void> retry() async {
    final player = value.playerId;
    if (player != null) await sync(player);
  }

  String _failure(int status) =>
      [401, 403].contains(status) ? appL10n.svcAppearanceWaitingToSyncSignInOr : appL10n.svcAppearanceWaitingToSyncTapToRetry;

  bool _sameChoice(String key, dynamic local, dynamic remote) {
    if (key == 'avatarId') {
      return int.tryParse('$local') == int.tryParse('$remote');
    }
    if (local == null || remote == null) return local == remote;
    if (key == 'travelTeam') {
      final before = CommunityTravelAppearanceStore.parseTeam(local);
      final after = CommunityTravelAppearanceStore.parseTeam(remote);
      if (before == null || after == null) return false;
      for (var slot = 0; slot < before.length; slot++) {
        if (before[slot].character.id != after[slot].character.id ||
            before[slot].level != after[slot].level ||
            before[slot].superAwakening != after[slot].superAwakening) return false;
      }
      return true;
    }
    return local is Map && remote is Map && local['id'] == remote['id'];
  }

  Future<void> _restorePendingTravel(
      SharedPreferences prefs, String player, Map<String, dynamic> remote) async {
    final needsTeam = remote['travelTeam'] == null;
    final needsPartner = remote['travelPartner'] == null;
    if (!needsTeam && !needsPartner) return;
    final local = await CommunityTravelAppearanceStore(await _travelAccountKey(player)).load();
    await _queue(() async {
      final entry = _entry(prefs, player);
      final dirty = _dirty(entry);
      final restored = {
        if (needsTeam && !dirty.contains('travelTeam') && local.members != null)
          'travelTeam': local.members!.map((member) => member.toJson()).toList(),
        if (needsPartner && !dirty.contains('travelPartner') && local.partner != null)
          'travelPartner': _item(local.partner),
      };
      if (restored.isEmpty) return;
      dirty.addAll(restored.keys);
      entry.addAll({
        ...restored,
        'pending': true,
        'dirtyFields': dirty.toList(),
        'generation': (entry['generation'] as int? ?? 0) + 1,
      });
      await _persist(prefs, _key(player), entry);
      _publish(player, entry, appL10n.svcSyncingCommunityAppearance, AvatarSyncLevel.syncing);
    });
  }

  Future<void> _invalidateProfileCaches(SharedPreferences prefs) async {
    await Future.wait([
      RatingRankListService.clearRankingsCache(),
      AvgRankingListService.clearRankingsCache(),
      FittedRatingRankingListService.clearRankingsCache(),
    ]);
    for (final key in prefs
        .getKeys()
        .where((key) =>
            key.startsWith(CacheKeyConstant.songCommentsCacheTimestampPrefix))
        .toList()) {
      await prefs.remove(key);
    }
    profileChanges.notifyListeners();
  }

  static bool _canSync(Map<String, String> headers) =>
      headers.containsKey('Authorization') ||
      headers.containsKey('X-Auto-Sync-Token');

  Future<void> sync(String player) {
    final running = _syncing[player];
    if (running != null) {
      _resync.add(player);
      return running;
    }
    return _syncing[player] = _sync(player);
  }

  Future<void> _sync(String player) async {
    var rerun = false;
    try {
      await _writes;
      final prefs = await SharedPreferences.getInstance(),
          headers = await CommunityProfileAuthorization.ownerHeaders(player);
      var entry = _entry(prefs, player);
      if (!_canSync(headers)) {
        _publish(
            player, entry, appL10n.svcSavedOnThisDeviceOnlySignIn2, AvatarSyncLevel.localOnly);
        return;
      }
      _publish(player, entry, appL10n.svcSyncingCommunityAppearance, AvatarSyncLevel.syncing);
      final get = await ApiClient.get(
          Uri.parse(_endpoint).replace(queryParameters: {'playerId': player}),
          headers: headers);
      if (get.statusCode != 200) {
        debugPrint('[Appearance] 读取装扮失败: HTTP ${get.statusCode}');
        _publish(
            player, entry, _failure(get.statusCode), AvatarSyncLevel.error);
        return;
      }
      final readBody = jsonDecode(utf8.decode(get.bodyBytes)) as Map;
      if (readBody['success'] != true || readBody['data'] is! Map) {
        throw AppError(
          code: 'SRV-AVATAR-UNCONFIRMED',
          userMessage: '装扮读取未被服务端确认，请稍后重试',
          stage: '读取云端装扮',
          source: 'chiffonmai',
          httpStatus: get.statusCode,
          requestId: ApiClient.requestIdOf(get),
        ).asStateError();
      }
      var remote = Map<String, dynamic>.from(readBody['data'] as Map);
      if (remote['playerId'] != player) {
        throw AppError(
          code: 'AUTH-AVATAR-MISMATCH',
          userMessage: '装扮账号不匹配，请重新登录后再试',
          stage: '校验装扮账号归属',
          source: 'chiffonmai',
          retryable: false,
        ).asStateError();
      }
      await _restorePendingTravel(prefs, player, remote);
      await _writes;
      entry = _entry(prefs, player);
      if (entry['pending'] != true) {
        final applied = await _queue(() async {
          final latest = _entry(prefs, player);
          if (latest['pending'] == true) return false;
          final changed =
              _fields.any((key) => !_sameChoice(key, latest[key], remote[key]));
          latest.addAll({
            for (final key in _fields) key: remote[key],
            'revision': remote['profileRevision']
          });
          await _persist(prefs, _key(player), latest);
          _publish(player, latest, appL10n.svcCommunityAppearanceSynced, AvatarSyncLevel.synced);
          await _compatibility(prefs, player, latest);
          if (changed) await _invalidateProfileCaches(prefs);
          return true;
        });
        if (!applied) rerun = true;
      } else {
        for (var attempt = 0; attempt < 3; attempt++) {
          final generation = entry['generation'], dirty = _dirty(entry);
          final result = await ApiClient.put(Uri.parse(_endpoint),
              headers: headers,
              timeout: const Duration(seconds: 25),
              body: jsonEncode({
                'playerId': player,
                'expectedProfileRevision': remote['profileRevision'].toString(),
                for (final key in dirty) key: entry[key]
              }));
          final body = jsonDecode(utf8.decode(result.bodyBytes)) as Map;
          await _writes;
          final latest = _entry(prefs, player);
          if (result.statusCode == 409 && body['data'] is Map) {
            remote = Map<String, dynamic>.from(body['data'] as Map);
            if (remote['playerId'] != player) {
              throw AppError(
                code: 'AUTH-AVATAR-MISMATCH',
                userMessage: '装扮账号不匹配，请重新登录后再试',
                stage: '更新云端装扮',
                source: 'chiffonmai',
                httpStatus: result.statusCode,
                requestId: ApiClient.requestIdOf(result),
                retryable: false,
              ).asStateError();
            }
            entry = latest;
            continue;
          }
          if (result.statusCode != 200 ||
              body['success'] != true ||
              body['data']?['playerId'] != player) {
            debugPrint('[Appearance] 写入装扮失败: HTTP ${result.statusCode}');
            _publish(player, latest, _failure(result.statusCode),
                AvatarSyncLevel.error);
            return;
          }
          remote = Map<String, dynamic>.from(body['data'] as Map);
          // HTTP 成功并不等于选择已经保存；旧响应或接口忽略字段时保留待发选择。
          if (dirty.any((key) =>
              !remote.containsKey(key) ||
              !_sameChoice(key, entry[key], remote[key]))) {
            _publish(
                player, latest, appL10n.svcAppearanceWaitingToSyncTheServerHas, AvatarSyncLevel.error);
            return;
          }
          final saved = await _queue(() async {
            final current = _entry(prefs, player);
            if (current['generation'] != generation) return false;
            current.addAll({
              for (final key in _fields) key: remote[key],
              'pending': false,
              'dirtyFields': <String>[],
              'revision': remote['profileRevision']
            });
            await _persist(prefs, _key(player), current);
            _publish(player, current, appL10n.svcCommunityAppearanceSynced, AvatarSyncLevel.synced);
            await _compatibility(prefs, player, current);
            return true;
          });
          if (!saved) {
            entry = _entry(prefs, player);
            continue;
          }
          await _invalidateProfileCaches(prefs);
          break;
        }
        entry = _entry(prefs, player);
        if (entry['pending'] == true)
          _publish(player, entry, appL10n.svcAppearanceWaitingToSyncTapToRetry, AvatarSyncLevel.pending);
      }
    } catch (error) {
      debugPrint('[Appearance] 社区装扮同步失败: ${error.runtimeType}');
      final prefs = await SharedPreferences.getInstance();
      _publish(
          player, _entry(prefs, player), appL10n.svcAppearanceWaitingToSyncTapToRetry, AvatarSyncLevel.error);
    } finally {
      await _writes;
      final prefs = await SharedPreferences.getInstance();
      final pending = _entry(prefs, player)['pending'] == true;
      _syncing.remove(player);
      final requested = _resync.remove(player);
      if ((rerun || requested) && (pending || player.startsWith('luoxue:')))
        unawaited(sync(player));
    }
  }
}
