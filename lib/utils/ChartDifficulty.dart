/// 谱面难度的统一定义，不依赖 Flutter，供页面、服务和数据转换共用。
///
/// 普通谱面的成绩索引为 0–4；[utage] 的 5 仅表示难度选项，
/// 宴谱在歌曲 charts 中仍可能使用 0/1，不能拿 5 覆盖成绩的 level_index。
abstract final class ChartDifficulty {
  static const basic = 0;
  static const advanced = 1;
  static const expert = 2;
  static const master = 3;
  static const reMaster = 4;
  static const utage = 5;

  static const basicLabel = 'BASIC';
  static const advancedLabel = 'ADVANCED';
  static const expertLabel = 'EXPERT';
  static const masterLabel = 'MASTER';
  static const reMasterLabel = 'Re:MASTER';
  /// 兼容已有页面先转大写再匹配难度的分支，不作为显示文案。
  static const reMasterUpperLabel = 'RE:MASTER';
  static const utageLabel = 'UTAGE';

  static const standardLabels = [
    basicLabel,
    advancedLabel,
    expertLabel,
    masterLabel,
    reMasterLabel,
  ];
  static const labels = [...standardLabels, utageLabel];
  static const standardIndices = [basic, advanced, expert, master, reMaster];
  static const indices = [...standardIndices, utage];

  static const standardIndexByLabel = {
    basicLabel: basic,
    advancedLabel: advanced,
    expertLabel: expert,
    masterLabel: master,
    reMasterLabel: reMaster,
  };
  static const indexByLabel = {...standardIndexByLabel, utageLabel: utage};

  /// 标签接口、DXRating 等外部数据使用的小写名称。
  static const apiNames = ['basic', 'advanced', 'expert', 'master', 'remaster'];
  static const apiNameByIndex = {
    basic: 'basic',
    advanced: 'advanced',
    expert: 'expert',
    master: 'master',
    reMaster: 'remaster',
  };

  /// 旧标签缓存键和视频搜索关键词需要保留的大小写。
  static const legacyLabels = [
    'Basic',
    'Advanced',
    'Expert',
    'Master',
    'Re:Master'
  ];

  /// 视频标题里的历史写法和中文别称，仅供关键词匹配。
  static const searchKeywords = {
    basicLabel: ['Basic', 'basic', '绿谱', '绿', basicLabel],
    advancedLabel: ['Advanced', 'advanced', '黄谱', '黄', advancedLabel],
    expertLabel: ['Expert', 'expert', '红谱', '红', expertLabel],
    masterLabel: ['Master', 'master', '紫谱', '紫', masterLabel],
    reMasterLabel: [
      'Re:Master',
      'ReMaster',
      'remaster',
      're:master',
      '白谱',
      '白',
      'REM',
      reMasterLabel
    ],
  };

  /// maidata 的 inote 编号独立于成绩索引：1 为 EASY，2–7 为这六种难度。
  static const standardMaidataLabels = {
    '2': basicLabel,
    '3': advancedLabel,
    '4': expertLabel,
    '5': masterLabel,
    '6': reMasterLabel,
  };
  static const maidataLabels = {...standardMaidataLabels, '7': utageLabel};

  /// AWMC 宴谱编号是 10，不能与本地筛选项的 5 或 maidata 的 7 混用。
  static const awmcUtage = 10;
  static const awmcUtageLabel = '宴会场';
  static const awmcLevelNames = {
    basic: basicLabel,
    advanced: advancedLabel,
    expert: expertLabel,
    master: masterLabel,
    reMaster: reMasterLabel,
    awmcUtage: awmcUtageLabel,
  };
  static const awmcLevelCodes = {
    ...standardIndexByLabel,
    awmcUtageLabel: awmcUtage,
  };

  static bool isStandard(int index) => index >= basic && index <= reMaster;
  static bool isValid(int index) => index >= basic && index <= utage;

  static bool isUtageSong(Object? songId, {String? type}) =>
      type?.toUpperCase() == utageLabel || songId?.toString().length == 6;

  static int? standardIndexOf(String? label) {
    final index = indexOf(label);
    return index != null && isStandard(index) ? index : null;
  }

  /// 显示歌曲难度时，宴谱身份优先于其 charts 中的 0/1 索引。
  static String labelOf(int? index,
      {bool isUtage = false, String fallback = '?'}) {
    if (isUtage) return utageLabel;
    return index != null && isValid(index) ? labels[index] : fallback;
  }

  static String apiNameOf(int index, {String fallback = ''}) =>
      apiNameByIndex[index] ?? fallback;

  /// 兼容 API 小写、旧大小写以及 Re:MASTER / REMASTER 两种拼法。
  static int? indexOf(String? label) {
    final normalized = label?.trim().toUpperCase().replaceAll(':', '');
    return switch (normalized) {
      'BASIC' => basic,
      'ADVANCED' => advanced,
      'EXPERT' => expert,
      'MASTER' => master,
      'REMASTER' => reMaster,
      'UTAGE' || awmcUtageLabel => utage,
      _ => null,
    };
  }

  static String normalizeLabel(String label) {
    final index = indexOf(label);
    return index == null ? label : labels[index];
  }

  static int? fromMaidataIndex(int index) =>
      index >= 2 && index <= 7 ? index - 2 : null;
  static int? toMaidataIndex(int index) => isValid(index) ? index + 2 : null;
  static String maidataLabelOf(int index, {String fallback = 'UNKNOWN'}) =>
      index == 1 ? 'EASY' : maidataLabels['$index'] ?? fallback;

  static int? fromAwmcLevel(int level) =>
      level == awmcUtage ? utage : (isStandard(level) ? level : null);
  static int? toAwmcLevel(int index) =>
      index == utage ? awmcUtage : (isStandard(index) ? index : null);
}
