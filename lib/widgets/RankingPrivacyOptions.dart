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
            title: const Text('参与排行榜'),
            value: participate,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => onChanged(v == true, v == true && showNickname,
                v == true && showNickname && showBriefProfile)),
        if (participate)
          CheckboxListTile(
              title: const Text('展示昵称与头像'),
              subtitle: const Text('关闭时显示匿名用户和默认头像；自选头像仍会保存并同步。'),
              value: showNickname,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) =>
                  onChanged(true, v == true, v == true && showBriefProfile)),
        if (participate && showNickname)
          CheckboxListTile(
              title: const Text('展示排行榜简要信息'),
              subtitle: const Text('公开称号、装扮、等级与 Best 成绩；需登录或完成账号身份验证。默认关闭。'),
              value: showBriefProfile,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => onChanged(true, true, v == true)),
      ]);
}
