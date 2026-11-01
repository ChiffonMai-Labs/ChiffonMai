import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entity/Multiplayer/PlayerEntity.dart';
import '../entity/Multiplayer/RoomEntity.dart';
import '../entity/Multiplayer/GameType.dart';
import 'MarqueeText.dart';
import 'CommunityAvatar.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';

/// 房间身份与规则独立于对局内容，等待和游玩时都能快速找到房间码。
class MultiplayerRoomHeader extends StatelessWidget {
  const MultiplayerRoomHeader(
      {super.key, required this.room, this.compact = false});
  final RoomEntity room;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (compact)
      return Row(children: [
        Expanded(
            child: Text.rich(
          TextSpan(children: [
            const TextSpan(text: '房间 '),
            TextSpan(
                text: room.roomCode,
                style: AppTheme.number(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            TextSpan(
                text:
                    ' · ${room.players.length} 人 · ${room.status.displayName}'),
          ]),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        )),
        IconButton(
            tooltip: '复制房间码',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: room.roomCode));
              if (context.mounted)
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('房间码已复制')));
            }),
      ]);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('邀请好友，一起猜歌',
                  style: Theme.of(context).textTheme.labelLarge)),
          Icon(
              room.status == RoomStatus.playing
                  ? Icons.play_circle_outline
                  : Icons.groups_outlined,
              size: 16,
              color: scheme.primary),
          const SizedBox(width: 6),
          Text(room.status.displayName,
              style: TextStyle(color: scheme.primary)),
        ]),
        const SizedBox(height: 12),
        Text('房间码',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        Row(children: [
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(room.roomCode,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: scheme.primary)))),
          IconButton.filledTonal(
            tooltip: '复制房间码',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: room.roomCode));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('房间码已复制，发送给好友即可加入')));
            },
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
        ]),
        const SizedBox(height: 16),
        Text(room.gameType.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(room.gameType.description,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 8, children: [
          _rule(context, Icons.timer_outlined,
              room.timeLimit > 0 ? '${room.timeLimit} 秒 / 回合' : '不限时'),
          _rule(context, Icons.repeat_rounded, '${room.totalRounds} 回合'),
          _rule(context, Icons.touch_app_outlined,
              room.maxGuesses > 0 ? '每回合共享 ${room.maxGuesses} 次猜测' : '猜测次数不限'),
          _rule(context, Icons.tune_rounded,
              '定数 ${room.masterMinDx.toStringAsFixed(1)} - ${room.masterMaxDx.toStringAsFixed(1)}'),
        ]),
      ]),
    );
  }

  Widget _rule(BuildContext context, IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.bodySmall)
        ],
      );
}

class MultiplayerRoomPlayers extends StatelessWidget {
  const MultiplayerRoomPlayers(
      {super.key,
      required this.room,
      required this.currentPlayerId,
      required this.playing,
      required this.displayName,
      required this.scoreOf});
  final RoomEntity room;
  final String? currentPlayerId;
  final bool playing;
  final String Function(PlayerEntity) displayName;
  final int Function(PlayerEntity) scoreOf;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = room.players.where((p) => p.isReady).length;
    // 对局中只留一排玩家胶囊，把空间让给题目。
    if (playing) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(children: [
          for (final player in room.players)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(context, player),
            ),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.people_outline_rounded, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text('玩家席位',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700))),
        Text(
            '${room.players.length} / ${room.maxPlayers} 人${playing ? '' : ' · $ready 人准备'}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 310 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21
              ? 1
              : 2;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < room.maxPlayers; i++)
              SizedBox(
                  width: width,
                  child: _seat(context,
                      i < room.players.length ? room.players[i] : null)),
          ]);
        }),
    ]);
  }

  /// 对局中的玩家胶囊：自己反色，离线和投降也写在分数那一行。
  Widget _chip(BuildContext context, PlayerEntity player) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = player.playerId == currentPlayerId;
    final fg = mine ? scheme.onInverseSurface : scheme.onSurface;
    final status = !player.isOnline
        ? '暂时离线'
        : player.isSurrendered
            ? '已投降'
            : '${scoreOf(player)} 分';
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
      decoration: BoxDecoration(
        color: mine
            ? (theme.brightness == Brightness.dark
                ? scheme.inverseSurface
                : scheme.onSurface)
            : AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CommunityAvatar(avatarId: player.avatarId, size: 36),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (player.isHost) ...[
                Icon(Icons.workspace_premium_outlined, size: 12, color: fg),
                const SizedBox(width: 2),
              ],
              Text(displayName(player),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
            ]),
            Text(status,
                style: AppTheme.number(
                    fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ]),
    );
  }

  Widget _seat(BuildContext context, PlayerEntity? player) {
    final scheme = Theme.of(context).colorScheme;
    final mine = player != null && player.playerId == currentPlayerId;
    final status = player == null
        ? '分享房间码邀请好友'
        : !player.isOnline
            ? '暂时离线'
            : playing
                ? (player.isSurrendered ? '已投降' : '${scoreOf(player)} 分')
                : player.isReady
                    ? '已准备'
                    : '等待准备';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? scheme.primaryContainer : AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: Row(children: [
        if (player != null)
          CommunityAvatar(avatarId: player.avatarId, size: 34)
        else
          CircleAvatar(
              radius: 17,
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              child: const Icon(Icons.person_add_alt_1_outlined, size: 18)),
        const SizedBox(width: 9),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              MarqueeText(
                  text: player == null
                      ? '等待加入'
                      : '${displayName(player)}${mine ? ' · 我' : ''}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface)),
              const SizedBox(height: 5),
              Row(children: [
                if (player?.isHost == true) ...[
                  Icon(Icons.workspace_premium_outlined,
                      size: 13, color: scheme.primary),
                  const SizedBox(width: 3)
                ],
                Expanded(
                    child: Text(status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: player?.isReady == true && !playing
                                ? scheme.primary
                                : scheme.onSurfaceVariant))),
                if (player?.isReady == true && !playing)
                  Icon(Icons.check_circle_outline,
                      size: 15, color: scheme.primary),
              ]),
            ])),
      ]),
    );
  }
}

/// 等待阶段的操作固定在底部，不让开始与准备按钮被玩家列表挤到屏幕外。
class MultiplayerRoomReadyBar extends StatelessWidget {
  const MultiplayerRoomReadyBar(
      {super.key,
      required this.room,
      required this.player,
      required this.onReady,
      required this.onStart,
      this.busy = false});
  final RoomEntity room;
  final PlayerEntity? player;
  final VoidCallback onReady, onStart;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = room.players.where((p) => !p.isReady || !p.isOnline).length;
    final canStart = room.players.length >= 2 && missing == 0;
    final ready = player?.isReady == true;
    final hint = player == null
        ? '正在确认玩家身份…'
        : room.players.length < 2
            ? '分享房间码，邀请至少一位好友加入'
            : missing > 0
                ? '还有 $missing 位玩家尚未准备就绪'
                : player!.isHost
                    ? '全员就绪，可以开始了'
                    : '全员就绪，等待房主开始';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
          color: AppSurfaces.card(context),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ]),
      child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(busy ? '正在等待服务端确认…' : hint,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final host = player?.isHost == true;
              final stacked = constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21;
              final width = host && !stacked
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(spacing: 12, runSpacing: 8, children: [
                SizedBox(
                    width: width,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: Colors.transparent),
                      onPressed: player == null || busy ? null : onReady,
                      icon: Icon(
                          ready
                              ? Icons.check_circle_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 20),
                      label: Text(ready ? '取消准备' : '准备就绪'),
                    )),
                if (host)
                  SizedBox(
                      width: width,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48)),
                        onPressed: canStart && !busy ? onStart : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('开始游戏'),
                      )),
              ]);
            }),
          ])),
    );
  }
}
