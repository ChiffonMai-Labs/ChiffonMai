import 'package:flutter/material.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/GainRecommend/ScoreInsights.dart';
import '../../utils/ChartDifficulty.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../SongInfoPage.dart';

class CooperativeBest50Page extends StatelessWidget {
  const CooperativeBest50Page({
    super.key,
    required this.result,
    required this.mySource,
    required this.friendSource,
    required this.friendName,
  });

  final CooperativeBest50 result;
  final String mySource;
  final String friendSource;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final baseline = result.baseline;
    final style = Theme.of(context).textTheme;
    return BackgroundPageScaffold(
      title: l10n.awmcCoopBest50,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Rating  ${baseline.raSum}', style: style.headlineSmall),
          Text('${l10n.flowMe} · $mySource  /  $friendName · $friendSource'),
          for (final (name, group) in [
            ('B35', baseline.b35),
            ('B15', baseline.b15)
          ]) ...[
            const SizedBox(height: 12),
            Text('$name · ${group.length}', style: style.titleSmall),
            for (final record in group)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(record.title),
                subtitle: Text([
                  ChartDifficulty.labelOf(record.levelIndex),
                  '${record.achievements.toStringAsFixed(4)}%',
                  switch (result.contributors[record.key]) {
                    CooperativeContributor.mine => l10n.flowMe,
                    CooperativeContributor.friend => friendName,
                    CooperativeContributor.both => l10n.awmcSharedContribution,
                    null => '',
                  },
                ].join(' · ')),
                trailing: Text('${record.ra}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SongInfoPage(
                            songId: '${record.songId}',
                            initialLevelIndex: record.levelIndex,
                          )),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
