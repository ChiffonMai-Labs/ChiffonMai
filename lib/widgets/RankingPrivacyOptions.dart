import '../l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../service/RankingList/RankingUploadGuard.dart';
import '../utils/DivingFishMaskStatus.dart';

/// 普通刷新、高级刷新与同步后刷新的隐私选项使用同一套交互。
///
/// [divingFishSource] 为 true（这次用水鱼数据）且水鱼账号开启了成绩掩码时，
/// 「参与排行榜」禁用并说明原因，已勾选的会被取消：掩码后的成绩不能如实反映真实水平。
class RankingPrivacyOptions extends StatefulWidget {
  final bool participate, showNickname, showBriefProfile;
  final bool divingFishSource;

  /// 这次上传所用的数据源（shuiyu / luoxue / awmc）。该数据源的账号被冻结或拉黑时，
  /// 「参与排行榜」同样禁用并说明原因（见 RankingUploadGuard）。
  final String? dataSourceKey;
  final void Function(
      bool participate, bool showNickname, bool showBriefProfile) onChanged;
  const RankingPrivacyOptions(
      {super.key,
      required this.participate,
      required this.showNickname,
      required this.showBriefProfile,
      required this.onChanged,
      this.divingFishSource = false,
      this.dataSourceKey});

  @override
  State<RankingPrivacyOptions> createState() => _RankingPrivacyOptionsState();
}

class _RankingPrivacyOptionsState extends State<RankingPrivacyOptions> {
  final _mask = DivingFishMaskStatus.instance;

  @override
  void initState() {
    super.initState();
    if (widget.divingFishSource) _mask.refresh();
    RankingUploadGuard.load();
  }

  @override
  void didUpdateWidget(covariant RankingPrivacyOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 对话框里切到水鱼时再确认一次最新设置
    if (widget.divingFishSource && !oldWidget.divingFishSource) {
      _mask.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([_mask, RankingUploadGuard.states]),
        builder: (context, _) {
          final maskOn = _mask.value;
          final guardState = widget.dataSourceKey == null
              ? RankingGuardState.normal
              : RankingUploadGuard.states.value[widget.dataSourceKey] ??
                  RankingGuardState.normal;
          final maskBlocked = widget.divingFishSource && maskOn;
          final blocked = maskBlocked || guardState != RankingGuardState.normal;
          final reason = switch (guardState) {
            RankingGuardState.blacklisted =>
              context.l10n.rankingGuardBlacklisted,
            RankingGuardState.frozen => context.l10n.rankingGuardFrozen,
            RankingGuardState.normal =>
              context.l10n.flowRankingDivingFishMasked,
          };
          if (blocked && widget.participate) {
            // 不能在 build 里改父级状态，下一帧再把勾选取消
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.participate) {
                widget.onChanged(false, false, false);
              }
            });
          }
          final participate = widget.participate && !blocked;
          return Column(children: [
            CheckboxListTile(
                title: Text(context.l10n.flowJoinLeaderboards),
                subtitle: blocked
                    ? Text(reason,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))
                    : null,
                value: participate,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: blocked
                    ? null
                    : (v) => widget.onChanged(
                        v == true,
                        v == true && widget.showNickname,
                        v == true &&
                            widget.showNickname &&
                            widget.showBriefProfile)),
            if (participate)
              CheckboxListTile(
                  title: Text(context.l10n.flowRankingShowIdentity),
                  subtitle: Text(context.l10n.flowRankingIdentityHint),
                  value: widget.showNickname,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => widget.onChanged(
                      true, v == true, v == true && widget.showBriefProfile)),
            if (participate && widget.showNickname)
              CheckboxListTile(
                  title: Text(context.l10n.flowRankingShowBrief),
                  subtitle: Text(context.l10n.flowRankingBriefHint),
                  value: widget.showBriefProfile,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => widget.onChanged(true, true, v == true)),
          ]);
        },
      );
}
