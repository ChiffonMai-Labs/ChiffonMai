import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameStateEntity.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameType.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/RoomEntity.dart';
import 'package:my_first_flutter_app/service/Multiplayer/WebSocketBroadcastService.dart';
import 'package:my_first_flutter_app/utils/GameSeedUtil.dart';

import 'support/fake_multiplayer_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('房间破坏程度透传、复制和缺省回填，不串到其他房间', () {
    for (final key in ['pixelation_level', 'pixelationLevel']) {
      final room = RoomEntity.fromJson({'id': 'room', 'gameType': 'pixelated', key: 85});
      expect(room.pixelationLevel, 85);
      expect(RoomEntity.fromJson(room.copyWith().toJson()).pixelationLevel, 85);
      expect(RoomEntity.fromJson({'id': 'room'})
          .withModeSettingsFallback(room).pixelationLevel, 85);
      expect(RoomEntity.fromJson({'id': 'other'})
          .withModeSettingsFallback(room).pixelationLevel, 50);
    }
    expect(RoomEntity.fromJson({'pixelationLevel': 0}).pixelationLevel, 0);
    expect(RoomEntity.fromJson({'pixelationLevel': 101}).pixelationLevel, 100);
    expect(RoomEntity.fromJson({}).pixelationLevel, 50);
  });

  test('像素模式的 API、房间解析及全图就绪协议保持一致', () {
    expect(GameType.pixelated.apiKey, 'pixelated');
    for (final key in ['pixelated', '像素曲绘']) {
      final room = RoomEntity.fromJson({'id': 'room', 'gameType': key});
      expect(room.gameType, GameType.pixelated);
      expect(RoomEntity.fromJson(room.copyWith().toJson()).gameType, GameType.pixelated);
    }
    final state = GameStateEntity.fromJson({
      'coverProtocolVersion': 1, 'coverPreparing': true,
      'coverCrop': {'x1': 0, 'y1': 0, 'x2': 1, 'y2': 1},
    });
    expect(state.coverCrop!.toJson(), {'x1': 0.0, 'y1': 0.0, 'x2': 1.0, 'y2': 1.0});
  });

  test('曲绘准备状态、共享选区和错误提示完整解析并保留', () {
    final state = GameStateEntity.fromJson({
      'roomId': 'room',
      'roundId': 'round',
      'coverProtocolVersion': 1,
      'coverPreparing': true,
      'coverCrop': {'x1': 0.1, 'y1': 0.2, 'x2': 0.3, 'y2': 0.4},
      'coverPreparerId': 'host',
      'coverError': '没有有效曲绘',
      'timeRemaining': 40,
      'timeLimit': 40,
    });
    final restored = GameStateEntity.fromJson(state.copyWith().toJson());
    expect(restored.coverProtocolVersion, 1);
    expect(restored.coverPreparing, isTrue);
    expect(restored.roundEndsAt, isNull);
    expect(restored.timeRemaining, 40);
    expect(restored.coverCrop!.toJson(), state.coverCrop!.toJson());
    expect(restored.coverPreparerId, 'host');
    expect(restored.coverError, '没有有效曲绘');
    expect(GameStateEntity.fromJson({}).coverPreparing, isFalse);
    expect(GameStateEntity.fromJson({}).coverProtocolVersion, 0);
  });

  test('非法或缺失的共享选区不会用于渲染', () {
    for (final value in [
      null,
      {},
      {'x1': '0', 'y1': 0, 'x2': 0.3, 'y2': 0.3},
      {'x1': 0.3, 'y1': 0, 'x2': 0.1, 'y2': 0.3},
      {'x1': 0, 'y1': 0, 'x2': double.nan, 'y2': 0.3},
      {'x1': 0, 'y1': 0, 'x2': 1.1, 'y2': 0.3},
    ]) {
      expect(CropRect.tryFromJson(value), isNull);
    }
  });

  test('能力握手和准备回执保留捕获时的房间回合令牌', () async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await FakeMultiplayerServer.start();
    final ws = WebSocketBroadcastService();
    addTearDown(() async {
      ws.disconnect();
      await server.stop();
      HttpOverrides.global = previous;
    });
    await ws.initialize(host: server.url);
    await ws.sendInitialize('测试玩家');
    const crop = CropRect(x1: 0.1, y1: 0.2, x2: 0.3, y2: 0.4);
    await ws.sendCoverPreparation(
        'cover_prepared', 'captured-room', 'captured-round',
        crop: crop.toJson());
    await ws.sendCoverPreparation(
        'cover_ready', 'captured-room', 'captured-round');
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (server.ofAction('cover_ready').isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(
        server.ofAction('initialize').single['payload']
            ['coverPreparationVersion'],
        1);
    expect(server.ofAction('cover_prepared').single['payload'], {
      'roomId': 'captured-room',
      'roundId': 'captured-round',
      'crop': crop.toJson(),
      'failed': false,
    });
    expect(server.ofAction('cover_ready').single['payload']['roundId'],
        'captured-round');
  });
}
