class VersionListConstant {
  static const Set<String> standardVersions = {
    'maimai',
    'maimai PLUS',
    'maimai GreeN',
    'maimai GreeN PLUS',
    'maimai ORANGE',
    'maimai ORANGE PLUS',
    'maimai PiNK',
    'maimai PiNK PLUS',
    'maimai MURASAKi',
    'maimai MURASAKi PLUS',
    'maimai MiLK',
    'MiLK PLUS',
    'maimai FiNALE',
    'maimai でらっくす',
    'maimai でらっくす Splash',
    'maimai でらっくす UNiVERSE',
    'maimai でらっくす FESTiVAL',
    'maimai でらっくす BUDDiES',
    'maimai でらっくす PRiSM',
    'maimai でらっくす PRiSM PLUS',
  };

  static const Map<String, int> versionOrderMap = {
    'maimai': 1,
    'maimai PLUS': 2,
    'maimai GreeN': 3,
    'maimai GreeN PLUS': 4,
    'maimai ORANGE': 5,
    'maimai ORANGE PLUS': 6,
    'maimai PiNK': 7,
    'maimai PiNK PLUS': 8,
    'maimai MURASAKi': 9,
    'maimai MURASAKi PLUS': 10,
    'maimai MiLK': 11,
    'MiLK PLUS': 12,
    'maimai FiNALE': 13,
    'maimai でらっくす': 14,
    'maimai でらっくす Splash': 15,
    'maimai でらっくす UNiVERSE': 16,
    'maimai でらっくす FESTiVAL': 17,
    'maimai でらっくす BUDDiES': 18,
    'maimai でらっくす PRiSM': 19,
    'maimai でらっくす PRiSM PLUS': 20,
  };

  static const List<String> versionOrderList = [
    'maimai',
    'maimai PLUS',
    'maimai GreeN',
    'maimai GreeN PLUS',
    'maimai ORANGE',
    'maimai ORANGE PLUS',
    'maimai PiNK',
    'maimai PiNK PLUS',
    'maimai MURASAKi',
    'maimai MURASAKi PLUS',
    'maimai MiLK',
    'MiLK PLUS',
    'maimai FiNALE',
    'maimai でらっくす',
    'maimai でらっくす Splash',
    'maimai でらっくす UNiVERSE',
    'maimai でらっくす FESTiVAL',
    'maimai でらっくす BUDDiES',
    'maimai でらっくす PRiSM',
    'maimai でらっくす PRiSM PLUS',
  ];

  static const _japanesePlusVersions = {
    'maimai でらっくす': 'maimai でらっくす PLUS',
    'maimai でらっくす Splash': 'maimai でらっくす Splash PLUS',
    'maimai でらっくす UNiVERSE': 'maimai でらっくす UNiVERSE PLUS',
    'maimai でらっくす FESTiVAL': 'maimai でらっくす FESTiVAL PLUS',
    'maimai でらっくす BUDDiES': 'maimai でらっくす BUDDiES PLUS',
  };

  /// 日服版本顺序：各世代后紧跟 PLUS，再接后续世代；查询与版本对照共用。
  static final List<String> japaneseVersionOrderList = List.unmodifiable([
    for (final key in versionOrderList) ...[
      key,
      if (_japanesePlusVersions.containsKey(key)) _japanesePlusVersions[key]!,
    ],
    'maimai でらっくす CiRCLE',
    'maimai でらっくす CiRCLE PLUS',
    'maimai でらっくす MAGiCAL',
  ]);

  static final Map<String, int> japaneseVersionOrderMap = Map.unmodifiable({
    for (var i = 0; i < japaneseVersionOrderList.length; i++)
      japaneseVersionOrderList[i]: i,
    // union 的 MiLK PLUS 带 maimai 前缀，版本对照使用水鱼的无前缀写法。
    'maimai MiLK PLUS': japaneseVersionOrderList.indexOf('MiLK PLUS'),
  });
}
