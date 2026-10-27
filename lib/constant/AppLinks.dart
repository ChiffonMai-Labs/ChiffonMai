/// 项目的对外链接与联系方式。
///
/// **只在这里定义一次**：这些值会散落在 UI（系统 hub 的按钮）、导出的图片
/// （Best50 底部的交流群）、个人主页信息栏等好几个地方，各写一份字面量迟早会
/// 改漏一处 —— 之前群号 `291826702` 就在两处各写了一遍。
class AppLinks {
  AppLinks._();

  /// 官网。
  static const String officialSite = 'https://chiffonmai.cloud/';

  /// 查分器账号注册入口。
  static const String divingFishRegistrationUrl =
      'https://maimai.diving-fish.com/';
  static const String luoXueRegistrationUrl = 'https://maimai.lxns.net/';

  /// AWMC 注册引导：群名按展示约定，跳转使用官方群分享链接。
  static const String awmcGroupOneName = 'AWMC 交流 1 群';
  static const String awmcGroupOneNumber = '1072033605';
  static const String awmcGroupOneJoinUrl = 'https://qm.qq.com/q/Gj3QmfEyY0';
  static const String awmcGroupTwoName = 'AWMC 交流 2 群';
  static const String awmcGroupTwoNumber = '993795066';
  static const String awmcGroupTwoJoinUrl = 'https://qm.qq.com/q/PF5t1VXPi0';
  static const String awmcBotName = 'AWMC BOT';
  static const String awmcBotNumber = '4013752603';

  /// 官方交流 QQ 群号（跳转失败时复制这个给用户手动搜索）。
  static const String qqGroupNumber = '291826702';

  /// 一键加群链接（`qm.qq.com` 的分享链接）。
  ///
  /// 装了 QQ 会直接拉起加群页；没装 / 打不开时**不要**把这个链接复制给用户
  /// （在浏览器里打开只有一个空壳中转页），要复制 [qqGroupNumber]。
  static const String qqGroupJoinUrl = 'https://qm.qq.com/q/bNUUN3aiaI';

  /// 问卷。
  static const String surveyUrl = 'https://wj.qq.com/s2/26540572/7828/';

  /// 问题反馈。
  static const String feedbackUrl = 'https://wj.qq.com/s2/28237817/wmfe/';
}
