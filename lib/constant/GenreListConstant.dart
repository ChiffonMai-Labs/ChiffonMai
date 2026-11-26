class GenreListConstant {
  static const List<String> genreList = [
    '舞萌',
    '流行&动漫',
    'niconico & VOCALOID',
    '其他游戏',
    '东方Project',
    '音击&中二节奏',
    '\u5bb4\u4f1a\u5834',
  ];

  static const Map<String, String> _genreAliases = {
    'maimai': '舞萌',
    'POPS & アニメ': '流行&动漫',
    'POPS＆アニメ': '流行&动漫',
    'niconico & ボーカロイド': 'niconico & VOCALOID',
    'niconico＆ボーカロイド': 'niconico & VOCALOID',
    'ゲーム & バラエティ': '其他游戏',
    'ゲーム＆バラエティ': '其他游戏',
    '東方Project': '东方Project',
    'オンゲキ & CHUNITHM': '音击&中二节奏',
    'オンゲキ＆CHUNITHM': '音击&中二节奏',
    '宴会场': '\u5bb4\u4f1a\u5834',
  };

  /// 将非国服曲库中的日文流派名映射为通用流派标签，便于普通查询统一筛选。
  static String normalizeGenre(String raw) {
    final trimmed = raw.trim();
    return _genreAliases[trimmed] ?? trimmed;
  }
}
