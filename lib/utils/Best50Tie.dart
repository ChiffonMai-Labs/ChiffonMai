/// 榜单截断后，和最后一首并列的谱面。
///
/// [sorted] 必须已按 [field] 降序排好；没有截断或没有并列时返回空列表。
List<T> tiedBeyondCut<T>(List<T> sorted, int limit, String field) {
  if (limit <= 0 || sorted.length <= limit) return <T>[];
  final last = (sorted[limit - 1] as Map)[field];
  if (last == null) return <T>[];
  return sorted.skip(limit).where((item) => (item as Map)[field] == last).toList();
}
