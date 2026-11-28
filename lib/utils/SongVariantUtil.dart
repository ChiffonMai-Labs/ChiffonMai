import '../entity/DivingFish/Song.dart';
import 'ChartDifficulty.dart';

/// 同一曲目家族下的谱面版本分类（标准 ST / DX / 宴会场 UTAGE）。
enum SongVariantKind {
  standard,
  dx,
  utage,
}

/// 同一曲目在歌曲详情页中可切换的关联谱面条目。
class SongVariantOption {
  final String songId;
  final SongVariantKind kind;
  final String title;
  final String? utageTag;
  final String levelLabel;
  final bool isBuddy;

  const SongVariantOption({
    required this.songId,
    required this.kind,
    required this.title,
    this.utageTag,
    this.levelLabel = '',
    this.isBuddy = false,
  });

  String get kindLabel => switch (kind) {
        SongVariantKind.standard => 'ST',
        SongVariantKind.dx => 'DX',
        SongVariantKind.utage => ChartDifficulty.utageLabel,
      };
}

/// 解析同一曲目关联的 ST / DX / 宴会场（UTAGE）多版本谱面列表。
abstract final class SongVariantUtil {
  static final RegExp _utageTagRegex = RegExp(r'^\[([^\]]+)\]\s*');

  /// 识别歌曲所属的展示大类：宴会场优先于 `type == 'DX'` 判定。
  static SongVariantKind kindOf(Song song) {
    final genre = song.basicInfo.genre;
    final isUtage = ChartDifficulty.isUtageSong(song.id, type: song.type) ||
        genre == ChartDifficulty.awmcUtageLabel ||
        genre == '宴会場';
    if (isUtage) return SongVariantKind.utage;
    return song.type.toUpperCase() == 'DX'
        ? SongVariantKind.dx
        : SongVariantKind.standard;
  }

  /// 提取宴会场曲名前缀方括号标记，例如 `[は]Garakuta Doll Play` -> `は`。
  static String? extractUtageTag(String title) {
    final match = _utageTagRegex.firstMatch(title.trim());
    final tag = match?.group(1)?.trim();
    return (tag == null || tag.isEmpty) ? null : tag;
  }

  /// 去掉宴会场前缀标记后的基础曲名。
  static String stripUtagePrefix(String title) =>
      title.trim().replaceFirst(_utageTagRegex, '').trim();

  static String _formatLevelLabel(Song song, SongVariantKind kind) {
    final levels = song.level
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (levels.isEmpty) return '';
    if (kind == SongVariantKind.utage) {
      return levels.join(' / ');
    }
    if (levels.length == 1) return levels.first;
    return '${levels.first} ~ ${levels.last}';
  }

  static SongVariantOption _toOption(Song song) {
    final kind = kindOf(song);
    final title =
        song.basicInfo.title.isNotEmpty ? song.basicInfo.title : song.title;
    return SongVariantOption(
      songId: song.id,
      kind: kind,
      title: title,
      utageTag: kind == SongVariantKind.utage ? extractUtageTag(title) : null,
      levelLabel: _formatLevelLabel(song, kind),
      isBuddy: kind == SongVariantKind.utage && song.ds.length == 2,
    );
  }

  /// 按当前曲目解析同一家族全部 ST / DX / UTAGE 谱面并有序返回（ST → DX → UTAGE）。
  static List<SongVariantOption> resolveVariants(
    Iterable<Song> songs, {
    required String currentSongId,
    required String currentTitle,
    required String currentType,
  }) {
    final trimmedId = currentSongId.trim();
    final numericId = int.tryParse(trimmedId);
    final baseId =
        numericId != null && numericId > 0 ? numericId % 10000 : null;
    final cleanBaseTitle = stripUtagePrefix(currentTitle);

    final byId = <String, Song>{};
    for (final song in songs) {
      final sid = song.id.trim();
      if (sid.isEmpty) continue;
      final songNum = int.tryParse(sid);
      final songBase = songNum != null && songNum > 0 ? songNum % 10000 : null;
      final sameBase = baseId != null && baseId > 0 && songBase == baseId;
      final songTitle =
          song.basicInfo.title.isNotEmpty ? song.basicInfo.title : song.title;
      final songCleanTitle = stripUtagePrefix(songTitle);
      final sameTitle =
          cleanBaseTitle.isNotEmpty && songCleanTitle == cleanBaseTitle;
      if (sameBase || sameTitle) {
        byId.putIfAbsent(sid, () => song);
      }
    }

    final result = [
      for (final song in byId.values) _toOption(song),
    ];
    result.sort((a, b) {
      final kindCompare = a.kind.index.compareTo(b.kind.index);
      if (kindCompare != 0) return kindCompare;
      final aNum = int.tryParse(a.songId) ?? 0;
      final bNum = int.tryParse(b.songId) ?? 0;
      final numCompare = aNum.compareTo(bNum);
      if (numCompare != 0) return numCompare;
      return a.songId.compareTo(b.songId);
    });
    return result;
  }
}
