/// 曲库 JSON 列表的按 ID 索引。
///
/// Best50 系列每张卡片都要查曲库，逐首遍历上千首会拖慢构建。索引跟着列表对象走，
/// 同一份列表只建一次；列表长度变了就重建。ID 重复时取靠前的那首。
class MusicDataIndex {
  MusicDataIndex._();

  static final Expando<_Index> _indexes = Expando<_Index>();

  /// 返回下标，找不到时是 -1。
  static int indexOf(List<dynamic> data, Object songId) {
    var index = _indexes[data];
    if (index == null || index.length != data.length) {
      final positions = <String, int>{};
      for (var i = 0; i < data.length; i++) {
        positions.putIfAbsent('${data[i]['id']}', () => i);
      }
      index = _Index(data.length, positions);
      _indexes[data] = index;
    }
    return index.positions[songId.toString()] ?? -1;
  }
}

class _Index {
  final int length;
  final Map<String, int> positions;

  const _Index(this.length, this.positions);
}
