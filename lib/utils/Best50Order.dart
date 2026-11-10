import '../entity/DivingFish/RecordItem.dart';
import '../entity/DivingFish/Song.dart';
import 'SongFilterUtil.dart';

typedef _Score = ({
  num ra,
  num achievements,
  num dxScore,
  num ds,
  int songId,
  int levelIndex,
});

/// Best50 的统一排序。拟合榜可用拟合 RA 代替原始 RA。
class Best50Order {
  Best50Order.fromSongs(Iterable<Song> songs)
      : this._fromIndex({for (final song in songs) song.id: song});

  Best50Order._fromIndex(Map<String, Song> songs)
      : this((songId, levelIndex) {
          final charts = songs['$songId']?.charts;
          if (charts == null || levelIndex < 0 || levelIndex >= charts.length) {
            return 0;
          }
          return charts[levelIndex].notes.fold(0, (sum, note) => sum + note) *
              3;
        }, chartDs: (songId, levelIndex) {
          final ds = songs['$songId']?.ds;
          return ds != null && levelIndex >= 0 && levelIndex < ds.length
              ? ds[levelIndex]
              : 0;
        });

  Best50Order(this._maxDxScore, {num Function(int, int)? chartDs})
      : _chartDs = chartDs;

  final int Function(int songId, int levelIndex) _maxDxScore;
  final num Function(int songId, int levelIndex)? _chartDs;
  final _maxScores = <(int, int), int>{};

  int compareRecords(RecordItem a, RecordItem b) =>
      _compare(_recordScore(a), _recordScore(b));

  int compareMaps(Map a, Map b, {String ratingField = 'ra'}) =>
      _compare(_mapScore(a, ratingField), _mapScore(b, ratingField));

  static _Score _recordScore(RecordItem record) => (
        ra: record.ra,
        achievements: record.achievements,
        dxScore: record.dxScore,
        ds: record.ds,
        songId: record.songId,
        levelIndex: record.levelIndex,
      );

  static _Score _mapScore(Map record, String ratingField) {
    final songId = _number(record['song_id']).toInt();
    return (
      ra: ratingField == 'ra' && SongFilterUtil.isUtageSong('$songId')
          ? 0
          : _number(record[ratingField]),
      achievements: _number(record['achievements']),
      dxScore: _number(record['dxScore']),
      ds: _number(record['ds']),
      songId: songId,
      levelIndex: _number(record['level_index']).toInt(),
    );
  }

  static num _number(Object? value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    return number != null && number.isFinite ? number : 0;
  }

  num _ds(_Score score) => score.ds > 0
      ? score.ds
      : _chartDs?.call(score.songId, score.levelIndex) ?? 0;

  double _dxRate(_Score score) {
    if (score.dxScore <= 0) return 0;
    final maxScore = _maxScores.putIfAbsent(
      (score.songId, score.levelIndex),
      () => _maxDxScore(score.songId, score.levelIndex),
    );
    return maxScore > 0 ? score.dxScore / maxScore : 0;
  }

  int _compare(_Score a, _Score b) {
    final byRa = b.ra.compareTo(a.ra);
    if (byRa != 0) return byRa;
    final byAchievement = b.achievements.compareTo(a.achievements);
    if (byAchievement != 0) return byAchievement;
    final byDxRate = _dxRate(b).compareTo(_dxRate(a));
    if (byDxRate != 0) return byDxRate;
    final byDs = _ds(b).compareTo(_ds(a));
    if (byDs != 0) return byDs;
    final byId = a.songId.compareTo(b.songId);
    if (byId != 0) return byId;
    return a.levelIndex.compareTo(b.levelIndex);
  }
}
