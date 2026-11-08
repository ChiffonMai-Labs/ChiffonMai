import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import '../manager/MaidataManager.dart';
import '../utils/ChartBpmInfo.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/AppTheme.dart';
import 'GuessUi.dart';

/// 猜测历史的谱面变速信息，以 MASTER 为准，没有 MASTER 时使用最高可用难度。
class GuessBpmHistoryFields extends StatefulWidget {
  final String songId;
  final String? targetSongId;
  const GuessBpmHistoryFields(
      {super.key, required this.songId, this.targetSongId});
  @override
  State<GuessBpmHistoryFields> createState() => _GuessBpmHistoryFieldsState();
}

class _GuessBpmHistoryFieldsState extends State<GuessBpmHistoryFields> {
  static final Map<String, Future<ChartBpmInfo?>> _pending = {};
  late Future<List<ChartBpmInfo?>> _info;

  static Future<ChartBpmInfo?> _load(String id) async {
    try {
      final manager = MaidataManager();
      await manager.initialize();
      var content = manager.getMaidata(id);
      if (content == null) {
        await manager.fetchMaidataForSongIds([id]);
        content = manager.getMaidata(id);
      }
      if (content == null) return null;
      final charts = <int, String>{};
      for (final match in RegExp(r'&inote_(\d+)\s*=([\s\S]*?)(?=\r?\n&|$)')
          .allMatches(content)) {
        charts[int.parse(match.group(1)!)] = match.group(2)!;
      }
      final master = ChartDifficulty.toMaidataIndex(ChartDifficulty.master);
      final keys = charts.keys.toList()..sort();
      final source =
          charts[master] ?? (keys.isEmpty ? null : charts[keys.last]);
      if (source == null) return null;
      final values = ChartBpmInfo.parse(source);
      return values.isEmpty ? null : ChartBpmInfo(values);
    } catch (_) {
      return null;
    }
  }

  void _loadInfo() {
    // 限制历史缓存大小，缺失结果只保留到本次会话，避免每次重建都发起请求。
    if (_pending.length >= 300 && !_pending.containsKey(widget.songId))
      _pending.remove(_pending.keys.first);
    Future<ChartBpmInfo?> cached(String id) =>
        _pending.putIfAbsent(id, () => _load(id));
    _info = Future.wait([
      cached(widget.songId),
      if (widget.targetSongId case final String id when id.isNotEmpty)
        cached(id)
      else
        Future<ChartBpmInfo?>.value(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void didUpdateWidget(covariant GuessBpmHistoryFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId ||
        oldWidget.targetSongId != widget.targetSongId) _loadInfo();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ChartBpmInfo?>>(
        future: _info,
        builder: (context, snapshot) {
          final brightness = Theme.of(context).brightness;
          final info = snapshot.data?.first;
          final target = snapshot.data?.last;
          final loading = snapshot.connectionState != ConnectionState.done;
          final comparable = !loading && info != null && target != null;
          final difference =
              comparable ? info.changeCount - target.changeCount : null;
          final hasChangesColor =
              comparable && info.hasChanges == target.hasChanges
                  ? AppColors.guessCorrectBg(brightness)
                  : AppColors.guessWrongBg(brightness);
          final countColor = difference == 0
              ? AppColors.guessCorrectBg(brightness)
              : difference != null && difference.abs() <= 1
                  ? AppColors.guessCloseBg(brightness)
                  : AppColors.guessWrongBg(brightness);
          final arrow = difference == null || difference == 0
              ? null
              : difference < 0
                  ? '↑'
                  : '↓';
          Widget field(String title, String value, Color color,
                  {String? arrow}) =>
              Expanded(
                child: GuessCell(
                  label: title,
                  value: value,
                  color: color,
                  arrow: arrow,
                ),
              );
          return Padding(
              padding: EdgeInsets.zero,
              child: Row(children: [
                field(
                    context.l10n.flowBPMChanges,
                    loading
                        ? context.l10n.flowLoading2
                        : info == null
                            ? context.l10n.flowNotProvided
                            : info.hasChanges
                                ? context.l10n.flowYes
                                : context.l10n.flowNo2,
                    hasChangesColor),
                const SizedBox(width: 8),
                field(
                    context.l10n.flowBPMChangeCount,
                    loading
                        ? '…'
                        : info == null
                            ? '—'
                            : context.l10n.flowP0Times((info.changeCount).toString()),
                    countColor,
                    arrow: arrow),
              ]));
        },
      );
}
