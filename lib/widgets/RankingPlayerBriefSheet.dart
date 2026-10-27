import 'TrophyTitleBadge.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/ApiUrls.dart';
import '../utils/ApiClient.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../utils/CoverUtil.dart';
import '../utils/StringUtil.dart';
import 'CommunityAvatar.dart';
import 'LxnsAssetImage.dart';
import 'PlayerExperienceStrip.dart';
import 'SmoothLinearProgressIndicator.dart';

/// 玩家行的点击入口。匿名行不请求、不打开信息面板。
class RankingPlayerRow extends StatelessWidget {
  final String playerId;
  final String? nickname;
  final Widget child;
  const RankingPlayerRow(
      {super.key,
      required this.playerId,
      required this.nickname,
      required this.child});
  @override
  Widget build(BuildContext context) {
    final enabled = playerId.isNotEmpty &&
        nickname != null &&
        nickname!.trim().isNotEmpty &&
        !const ['匿名', '匿名用户'].contains(nickname!.trim());
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      useSafeArea: true,
                      constraints: const BoxConstraints(maxWidth: 560),
                      builder: (_) =>
                          RankingPlayerBriefSheet(playerId: playerId));
                }
              : null,
          child: child,
        ));
  }
}

class RankingPlayerBriefSheet extends StatefulWidget {
  final String playerId;
  const RankingPlayerBriefSheet({super.key, required this.playerId});
  @override
  State<RankingPlayerBriefSheet> createState() =>
      _RankingPlayerBriefSheetState();
}

class _RankingPlayerBriefSheetState extends State<RankingPlayerBriefSheet> {
  late Future<Map<String, dynamic>> _request;
  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await ApiClient.get(
        Uri.parse(
            '${ApiUrls.RankingsBaseUrl}/player/${Uri.encodeComponent(widget.playerId)}/brief'),
        timeout: const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map;
    if (response.statusCode != 200 || body['success'] != true) {
      throw _BriefError(body['error']?.toString() ?? '暂时无法读取简要信息',
          private: body['code'] == 'PROFILE_PRIVATE');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        child: FutureBuilder<Map<String, dynamic>>(
            future: _request,
            builder: (context, snapshot) {
              if (snapshot.hasData)
                return SingleChildScrollView(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 20),
                    child: RankingPlayerBriefContent(data: snapshot.data!));
              final error = snapshot.error;
              final closed = error is _BriefError && error.private;
              return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      const Expanded(
                          child: Text('玩家简要信息',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(
                          tooltip: '关闭',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close))
                    ]),
                    if (!snapshot.hasError) ...[
                      const SizedBox(height: 20),
                      const SmoothLinearProgressIndicator(),
                      const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('正在读取简要信息…')),
                    ] else ...[
                      Icon(
                          closed
                              ? Icons.lock_outline_rounded
                              : Icons.cloud_off_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                          error is _BriefError
                              ? error.message
                              : '暂时无法读取简要信息，请稍后重试',
                          textAlign: TextAlign.center),
                      if (!closed)
                        TextButton(
                            onPressed: () => setState(() => _request = _load()),
                            child: const Text('重新加载')),
                    ],
                  ]));
            }),
      );
}

class _BriefError implements Exception {
  final String message;
  final bool private;
  const _BriefError(this.message, {this.private = false});
}

/// 生产面板和离线效果图共用实际布局。未提供的收藏品不使用别人的装扮兜底。
class RankingPlayerBriefContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const RankingPlayerBriefContent({super.key, required this.data});
  Map? _collection(String key) => data[key] is Map ? data[key] as Map : null;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final frame = _collection('frame');
    final plate = _collection('nameplate');
    final trophy = _collection('trophy');
    final frameId = frame?['id'] as int?;
    final plateId = plate?['id'] as int?;
    Widget missing(String label, IconData icon) => ColoredBox(
        color: scheme.surfaceContainerLow,
        child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))
        ])));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
          child: Row(children: [
            const Expanded(
                child: Text('玩家简要信息',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close)),
          ])),
      SizedBox(
          height: 104,
          child: frameId == null
              ? missing('未设置背景', Icons.landscape_outlined)
              : LxnsAssetImage(
                  url: lxnsFrameUrl(frameId),
                  fit: BoxFit.cover,
                  placeholder: missing('背景加载中', Icons.landscape_outlined),
                  errorWidget: missing('背景暂不可用', Icons.landscape_outlined))),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CommunityAvatar(
                  avatarId: data['avatarId'] as int? ?? 1, size: 64),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(data['nickname']?.toString() ?? '未知玩家',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        RefreshDataSource.displayNameOfKey(
                            data['dataSource'] as String?),
                        style: TextStyle(fontSize: 12, color: scheme.primary)),
                  ])),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                    height: 54,
                    child: plateId == null
                        ? missing('未设置姓名框', Icons.badge_outlined)
                        : LxnsAssetImage(
                            url: lxnsPlateUrl(plateId),
                            fit: BoxFit.contain,
                            placeholder:
                                missing('姓名框加载中', Icons.badge_outlined),
                            errorWidget:
                                missing('姓名框暂不可用', Icons.badge_outlined)))),
            const SizedBox(height: 12),
            if (trophy != null)
              TrophyTitleBadge(
                  name: trophy['name']?.toString() ?? '称号 #${trophy['id']}',
                  color: trophy['color'] as String?,
                  trophyId: trophy['id'] as int?)
            else
              Text('未设置称号',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 18),
            PlayerExperienceStrip(
                data: Map<String, dynamic>.from(
                    data['experience'] as Map? ?? {})),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(children: [
              for (final entry in [
                ('Best50', 'totalRating'),
                ('Best35', 'best35Rating'),
                ('Best15', 'best15Rating')
              ])
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(children: [
                          Text(entry.$1,
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${data[entry.$2] ?? 0}',
                                  style: TextStyle(
                                      fontSize: entry.$1 == 'Best50' ? 26 : 22,
                                      fontWeight: FontWeight.w800,
                                      color: entry.$1 == 'Best50'
                                          ? scheme.primary
                                          : scheme.onSurface)))
                        ])))
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1),
            _b1(context, 'Best35 · B1', data['best35B1']),
            const Divider(height: 1),
            _b1(context, 'Best15 · B1', data['best15B1']),
            Text('B1 为对应 Best 列表中单曲 Rating 最高的谱面。',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
          ])),
    ]);
  }

  Widget _b1(BuildContext context, String label, dynamic value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          const SizedBox(height: 8),
          if (value is! Map)
            Text('暂无成绩', style: TextStyle(color: scheme.onSurfaceVariant))
          else
            Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CoverUtil.buildCoverWidgetWithContext(
                      context, '${value['song_id']}', 52)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(value['title']?.toString() ?? '未知歌曲',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                        '${StringUtil.formatSongType(value['type']?.toString() ?? '')} · ${ChartDifficulty.labelOf(value['level_index'] as int? ?? 0)} ${value['ds']}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 11)),
                    Text(
                        '${(value['achievements'] as num).toStringAsFixed(4)}%',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12)),
                  ])),
              const SizedBox(width: 8),
              Column(children: [
                Text('${value['ra']}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                Text('Rating',
                    style:
                        TextStyle(fontSize: 10, color: scheme.onSurfaceVariant))
              ]),
            ]),
        ]));
  }
}
