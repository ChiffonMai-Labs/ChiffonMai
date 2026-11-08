import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
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

/// 玩家行的点击入口。匿名行不请求接口，只提示不展示简要信息。
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
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                useSafeArea: true,
                constraints: const BoxConstraints(maxWidth: 560),
                builder: (_) => enabled
                    ? RankingPlayerBriefSheet(playerId: playerId)
                    : const _AnonymousPlayerSheet());
          },
          child: child,
        ));
  }
}

class _AnonymousPlayerSheet extends StatelessWidget {
  const _AnonymousPlayerSheet();

  @override
  Widget build(BuildContext context) => _BriefNoticeFrame(children: [
        _BriefNotice(
            icon: Icons.lock_outline_rounded,
            message:
                context.l10n.flowBriefProfilesAreHiddenForAnonymousPlayers),
      ]);
}

/// 简要信息还没有内容时的抽屉：加载中、读取失败、玩家关闭展示、匿名用户。
class _BriefNoticeFrame extends StatelessWidget {
  final List<Widget> children;
  const _BriefNoticeFrame({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
              child: Text(context.l10n.flowPlayerBriefProfile,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(
              tooltip: context.l10n.featureClose,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close))
        ]),
        ...children,
      ]));
}

class _BriefNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  const _BriefNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ]);
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
      throw _BriefError(
          body['error']?.toString() ?? appL10n.flowBriefProfileUnavailable,
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
              return _BriefNoticeFrame(children: [
                if (!snapshot.hasError) ...[
                  const SizedBox(height: 20),
                  const SmoothLinearProgressIndicator(),
                  Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(context.l10n.flowLoadingBriefProfile)),
                ] else ...[
                  _BriefNotice(
                      icon: closed
                          ? Icons.lock_outline_rounded
                          : Icons.cloud_off_rounded,
                      message: error is _BriefError
                          ? error.message
                          : context.l10n.flowCouldNotLoadTheBriefProfileTry),
                  if (!closed)
                    TextButton(
                        onPressed: () => setState(() => _request = _load()),
                        child: Text(context.l10n.flowReload)),
                ],
              ]);
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
            Expanded(
                child: Text(context.l10n.flowPlayerBriefProfile,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(
                tooltip: context.l10n.featureClose,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close)),
          ])),
      SizedBox(
          height: 104,
          child: frameId == null
              ? missing(
                  context.l10n.flowNoBackgroundSet, Icons.landscape_outlined)
              : LxnsAssetImage(
                  url: lxnsFrameUrl(frameId),
                  fit: BoxFit.cover,
                  placeholder: missing(context.l10n.flowLoadingBackground,
                      Icons.landscape_outlined),
                  errorWidget: missing(context.l10n.flowBackgroundUnavailable,
                      Icons.landscape_outlined))),
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
                    Text(
                        data['nickname']?.toString() ??
                            context.l10n.flowUnknownPlayer,
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
                        ? missing(context.l10n.flowNoNameplateSet,
                            Icons.badge_outlined)
                        : LxnsAssetImage(
                            url: lxnsPlateUrl(plateId),
                            fit: BoxFit.contain,
                            placeholder: missing(
                                context.l10n.flowLoadingNameplate,
                                Icons.badge_outlined),
                            errorWidget: missing(
                                context.l10n.flowNameplateUnavailable,
                                Icons.badge_outlined)))),
            const SizedBox(height: 12),
            if (trophy != null)
              TrophyTitleBadge(
                  name: trophy['name']?.toString() ??
                      context.l10n.flowTitleP0((trophy['id']).toString()),
                  color: trophy['color'] as String?,
                  trophyId: trophy['id'] as int?)
            else
              Text(context.l10n.flowNoTitleSet,
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
            Text(context.l10n.flowB1IsTheChartWithTheHighest,
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
            Text(context.l10n.flowNoScoresYet,
                style: TextStyle(color: scheme.onSurfaceVariant))
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
                    Text(
                        value['title']?.toString() ??
                            context.l10n.flowUnknownSong,
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
