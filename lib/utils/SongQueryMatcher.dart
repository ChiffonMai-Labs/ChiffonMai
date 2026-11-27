/*
 * 歌名搜索的**唯一**匹配规则。
 *
 * 由来：随身听搜索要求「照搬乐曲查询页（SongSearchPage）的逻辑」，而那份逻辑原本
 * 写死在 `SongSearchService.searchSongs` 里，只吃水鱼的 `Song`。
 * 与其在随身听里再抄一份（两份迟早会漂移），这里抽成一份**纯函数**，
 * 两个调用点都走它：
 *   * `SongSearchService.searchSongs` —— 乐曲查询页（水鱼 Song）
 *   * `PortableSongLibrary.search` —— 随身听（随身听条目）
 *
 * 匹配字段（与乐曲查询页逐条对齐）：id 精确 / 曲名 / 艺术家 / BPM 精确 /
 * 谱师 / 流派 / 版本 / 别名，任一命中即算匹配；全部大小写不敏感。
 */
import 'dart:math' as math;

import 'package:kana_kit/kana_kit.dart';
import 'package:pinyin/pinyin.dart';

import '../entity/DivingFish/Song.dart';
import '../entity/Portable/PortableSong.dart';

/// 查询串规范化：去首尾空白 + 转小写。
///
/// 只 trim 不删中间空格 —— 乐曲查询页原来就是 `query.toLowerCase()`，
/// 保留中间空格能让「Link CoF」这类带空格的搜索按预期工作。
String normalizeSongQuery(String query) => query.trim().toLowerCase();

/// 乐曲查询匹配范围。
enum SongSearchScope {
  all,
  titleAndAlias,
  titleOnly,
  aliasOnly,
}

final _versionBrandTokens = RegExp(
  r'(?:maimai|舞萌|でらっくす|deluxe|dx)',
  caseSensitive: false,
);
final _multiWhitespace = RegExp(r'\s+');

/// 剥离版本名中的通用游戏品牌词，只保留具体版本代号（如 "PRiSM" / "2024" / "GreeN"），
/// 避免搜索 "maimai" 或 "舞萌" 时误命中全库。
String extractSongVersionCode(String version) {
  return version
      .toLowerCase()
      .replaceAll(_versionBrandTokens, ' ')
      .replaceAll(_multiWhitespace, ' ')
      .trim();
}

bool _containsNormalized(Iterable<String> candidates, String normalizedQuery) {
  for (final value in candidates) {
    if (value.toLowerCase().contains(normalizedQuery)) return true;
  }
  return false;
}

/// 水鱼 [Song] 是否命中查询（乐曲查询页用）。
///
/// [aliases] 传该曲的别名列表，[scope] 指定参与匹配的字段范围。
bool matchesDivingFishSongQuery(
  Song song,
  String normalizedQuery, {
  List<String> aliases = const <String>[],
  SongSearchScope scope = SongSearchScope.all,
}) {
  if (normalizedQuery.isEmpty) return false;
  switch (scope) {
    case SongSearchScope.titleOnly:
      if (song.basicInfo.title.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
      return matchesFuzzySongTitle(normalizedQuery, [song.basicInfo.title]);
    case SongSearchScope.aliasOnly:
      if (aliases.isEmpty) return false;
      if (_containsNormalized(aliases, normalizedQuery)) return true;
      return matchesFuzzySongTitle(normalizedQuery, aliases);
    case SongSearchScope.titleAndAlias:
      if (song.basicInfo.title.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
      if (_containsNormalized(aliases, normalizedQuery)) return true;
      return matchesFuzzySongTitle(
          normalizedQuery, [song.basicInfo.title, ...aliases]);
    case SongSearchScope.all:
      // 歌曲 ID（精确匹配，和乐曲查询页一致：`song.id.toString() == query`）
      if (song.id.trim() == normalizedQuery) return true;
      // 曲名
      if (song.basicInfo.title.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
      // 艺术家
      if (song.basicInfo.artist.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
      // BPM（精确匹配）
      if (song.basicInfo.bpm.toString() == normalizedQuery) return true;
      // 谱师
      for (final chart in song.charts) {
        if (chart.charter.toLowerCase().contains(normalizedQuery)) return true;
      }
      // 流派
      if (song.basicInfo.genre.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
      // 版本（仅比对剥离通用品牌词后的版本代号）
      final versionCode = extractSongVersionCode(song.basicInfo.from);
      if (versionCode.isNotEmpty && versionCode.contains(normalizedQuery)) {
        return true;
      }
      // 别名
      if (_containsNormalized(aliases, normalizedQuery)) return true;
      return matchesFuzzySongTitle(
          normalizedQuery, [song.basicInfo.title, ...aliases]);
  }
}

/// 随身听条目是否命中查询。
///
/// 字段集合与 [matchesDivingFishSongQuery] 一一对应：
///   * id 精确 → 两个 id 都比（水鱼 id 和落雪 id，用户看到的编号是哪个都不奇怪，
///     但**落雪 id 不参与 contains**：像 `1` 这种短数字会命中一大片）
///   * 曲名 / 艺术家 / 流派 → 普通 contains
///   * BPM 精确 / 别名 contains
///   * 谱师、版本 → 随身听条目里**没有**这两个字段（不为了搜索把整个水鱼
///     `Song` 塞进库缓存，那会让条目体积涨好几倍）。因此这两项在随身听里搜不到，
///     这是刻意的取舍。
bool matchesPortableSongQuery(
  PortableSong song,
  String normalizedQuery, {
  List<String> aliases = const <String>[],
}) {
  if (normalizedQuery.isEmpty) return true;
  final dfId = song.divingFishId.trim();
  if (dfId == normalizedQuery) return true;
  if ('${song.lxnsId}' == normalizedQuery) return true;
  if (song.title.toLowerCase().contains(normalizedQuery)) return true;
  if (song.artist.toLowerCase().contains(normalizedQuery)) return true;
  if (song.bpm.toString() == normalizedQuery) return true;
  if (song.genre.toLowerCase().contains(normalizedQuery)) return true;
  for (final alias in aliases) {
    if (alias.toLowerCase().contains(normalizedQuery)) return true;
  }
  return matchesFuzzySongTitle(normalizedQuery, [song.title, ...aliases]);
}

class _TitleForms {
  const _TitleForms(this.compact, this.textForms, this.pinyinTokens);

  final String compact;
  final Set<String> textForms;
  final List<String> pinyinTokens;
}

final _kana = KanaKit();
final _kanaPattern = RegExp(r'[\u3040-\u30ff]');
final _hanPattern = RegExp(r'[\u3400-\u9fff]');
final _punctuation = RegExp(r'[^a-z0-9\u3040-\u30ff\u3400-\u9fff]');
final _kanaUnsafeChars = RegExp(r'[\u3099\u309a\u30f7-\u30fa]');
final _sokuonWithLongDash = RegExp(r'ッ[・ヶヵー]*ー[・ヶヵー]*');
final _latinQueryPattern = RegExp(r'^[a-z0-9]*[a-z][a-z0-9]*$');
final _whitespace = RegExp(r'\s+');
final _digits = RegExp(r'^[0-9]+$');
final _titleForms = <String, _TitleForms>{};
String? _cachedQuery;
Set<String> _cachedQueryTextForms = const {};
String? _cachedLatinPinyinNeedle;

String _compactTitle(String value) =>
    value.toLowerCase().replaceAll(_punctuation, '');

/// 规避 kana_kit 2.1.1 在 `_katakanaToHiragana` 中的两个缺陷：
/// 1) 促音 `ッ` 后接长音符 `ー`（如 `ウッーウッーウマウマ(ﾟ∀ﾟ)`）时，
///    `toRomaji('っ')` 返回空串，取 `.chars.last` 会抛出 `Bad state: No element`；
/// 2) 内部混用 `chars` 与 UTF-16 下标，须先剔除组合字符与非标准片假名。
String _sanitizeForKana(String compact) => compact
    .replaceAll(_kanaUnsafeChars, '')
    .replaceAllMapped(
      _sokuonWithLongDash,
      (match) => match.group(0)!.replaceAll('ー', ''),
    );

String _safeConvert(String Function() convert) {
  try {
    return convert();
  } catch (_) {
    return '';
  }
}

Set<String> _buildTextFormsFromCompact(String compact) {
  if (compact.isEmpty) return const <String>{};
  final kanaSafe =
      _kanaPattern.hasMatch(compact) ? _sanitizeForKana(compact) : '';
  return {
    compact,
    if (kanaSafe.isNotEmpty)
      _safeConvert(() => _compactTitle(_kana.toHiragana(kanaSafe))),
    if (kanaSafe.isNotEmpty)
      _safeConvert(() => _compactTitle(_kana.toRomaji(kanaSafe))),
  }..remove('');
}

/// 保留音节边界：仅在输入拉丁拼音时按连续完整音节匹配，避免跨字截断或中文同音串台。
List<String> _extractPinyinTokens(String compact) {
  if (!_hanPattern.hasMatch(compact)) return const <String>[];
  final spaced = _safeConvert(
    () => PinyinHelper.getPinyin(
      compact,
      separator: ' ',
      format: PinyinFormat.WITHOUT_TONE,
    ),
  );
  if (spaced.isEmpty) return const <String>[];
  return spaced
      .split(_whitespace)
      .map(_compactTitle)
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

_TitleForms _buildTitleForms(String title) {
  final compact = _compactTitle(title);
  if (compact.isEmpty) return const _TitleForms('', <String>{}, <String>[]);
  return _TitleForms(
    compact,
    _buildTextFormsFromCompact(compact),
    _extractPinyinTokens(compact),
  );
}

void _ensureFuzzyQueryCache(String query) {
  if (_cachedQuery == query) return;
  _cachedQuery = query;
  final compact = _compactTitle(query);
  _cachedQueryTextForms = _buildTextFormsFromCompact(compact);
  _cachedLatinPinyinNeedle =
      compact.length >= 2 && _latinQueryPattern.hasMatch(compact)
          ? compact
          : null;
}

_TitleForms _getOrBuildTitleForms(String title) {
  if (_titleForms.length >= 12000) _titleForms.clear();
  return _titleForms.putIfAbsent(title, () => _buildTitleForms(title));
}

bool _matchesSyllableSequence(String needle, List<String> tokens) {
  final needleLen = needle.length;
  for (var start = 0; start < tokens.length; start++) {
    var offset = 0;
    for (var end = start; end < tokens.length; end++) {
      final token = tokens[end];
      if (offset + token.length > needleLen) break;
      if (!needle.startsWith(token, offset)) break;
      offset += token.length;
      if (offset == needleLen) return true;
    }
  }
  return false;
}

/// 若 [title] 通过假名/罗马音/拼音/去标点/容错规则命中 [query]，返回对应的命中读音形式：
/// - 命中罗马音、假名转换或拼音时返回对应的转换串（便于搜索结果「显示匹配字段」解释命中原因）；
/// - 仅通过去标点或编辑距离命中原文本时返回空串 `''`；
/// - 未命中返回 `null`。
String? describeFuzzySongTitleMatch(String query, String title) {
  _ensureFuzzyQueryCache(query);

  final hasTextNeedles = _cachedQueryTextForms.any(
    (needle) => needle.length >= 2 && !_digits.hasMatch(needle),
  );
  final latinPinyinNeedle = _cachedLatinPinyinNeedle;
  if (!hasTextNeedles && latinPinyinNeedle == null) return null;

  final forms = _getOrBuildTitleForms(title);
  if (latinPinyinNeedle != null &&
      forms.pinyinTokens.isNotEmpty &&
      _matchesSyllableSequence(latinPinyinNeedle, forms.pinyinTokens)) {
    return forms.pinyinTokens.join();
  }
  for (final needle in _cachedQueryTextForms) {
    if (needle.length < 2 || _digits.hasMatch(needle)) continue;
    final maxEdits = needle.length >= 8
        ? 2
        : needle.length >= 5
            ? 1
            : 0;
    for (final candidate in forms.textForms) {
      if (candidate.contains(needle) ||
          (maxEdits > 0 && _withinEdits(needle, candidate, maxEdits))) {
        return candidate == forms.compact ? '' : candidate;
      }
    }
  }
  return null;
}

bool matchesFuzzySongTitle(String query, Iterable<String> titles) {
  for (final title in titles) {
    if (describeFuzzySongTitleMatch(query, title) != null) return true;
  }
  return false;
}

bool _withinEdits(String a, String b, int limit) {
  if ((a.length - b.length).abs() > limit) return false;
  var previous = List.generate(b.length + 1, (i) => i);
  var next = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    next[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final replace = previous[j - 1] +
          (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1);
      next[j] = math.min(replace, math.min(previous[j], next[j - 1]) + 1);
    }
    final swap = previous;
    previous = next;
    next = swap;
  }
  return previous.last <= limit;
}
