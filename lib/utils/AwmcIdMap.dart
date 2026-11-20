/// AWMC 下载目录里同一首歌的标准、DX 或宴谱条目。
enum AwmcChartKind { standard, dx, utage }

/// 将 AWMC 下载目录的六位 shortid 与 App 曲库 ID 互转。
/// [baseSongId] 用于聚合同曲的标准谱和 DX 谱，宴谱保留独立 ID。
class AwmcIdMap {
  const AwmcIdMap._(this.songId, this.kind);

  static const _dxOffset = 10000;
  static const _utageStart = 100000;
  static final _shortIdPattern = RegExp(r'^[0-9]{6}$');

  final int songId;
  final AwmcChartKind kind;

  String get chartFileId => songId.toString().padLeft(6, '0');

  int get baseSongId => kind == AwmcChartKind.dx ? songId - _dxOffset : songId;

  static AwmcIdMap? fromSongId(int songId) {
    if (songId <= 0 || songId == _dxOffset || songId > 999999) return null;
    final kind = switch (songId) {
      >= _utageStart => AwmcChartKind.utage,
      > _dxOffset => AwmcChartKind.dx,
      _ => AwmcChartKind.standard,
    };
    return AwmcIdMap._(songId, kind);
  }

  static AwmcIdMap? fromChartFileId(String shortId) {
    if (!_shortIdPattern.hasMatch(shortId)) return null;
    return fromSongId(int.parse(shortId));
  }

  static AwmcIdMap? fromBaseSongId(int baseSongId, AwmcChartKind kind) {
    if (baseSongId <= 0) return null;
    final song = fromSongId(
      kind == AwmcChartKind.dx ? baseSongId + _dxOffset : baseSongId,
    );
    return song?.kind == kind ? song : null;
  }
}
