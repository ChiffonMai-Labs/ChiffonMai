import '../l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

/// 普通刷新、高级刷新与同步后刷新的隐私选项使用同一套交互。
class RankingPrivacyOptions extends StatelessWidget {
  final bool participate, showNickname, showBriefProfile;
  final void Function(
      bool participate, bool showNickname, bool showBriefProfile) onChanged;
  const RankingPrivacyOptions(
      {super.key,
      required this.participate,
      required this.showNickname,
      required this.showBriefProfile,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(children: [
        CheckboxListTile(
            title: Text(context.l10n.flowJoinLeaderboards),
            value: participate,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => onChanged(v == true, v == true && showNickname,
                v == true && showNickname && showBriefProfile)),
        if (participate)
          CheckboxListTile(
              title: Text(context.l10n.flowRankingShowIdentity),
              subtitle: Text(context.l10n.flowRankingIdentityHint),
              value: showNickname,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) =>
                  onChanged(true, v == true, v == true && showBriefProfile)),
        if (participate && showNickname)
          CheckboxListTile(
              title: Text(context.l10n.flowRankingShowBrief),
              subtitle: Text(context.l10n.flowRankingBriefHint),
              value: showBriefProfile,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => onChanged(true, true, v == true)),
      ]);
}
