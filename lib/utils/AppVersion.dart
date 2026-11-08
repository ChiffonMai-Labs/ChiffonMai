/// 应用版本比较：先比较版本名，同版本再比较 Android / iOS 的构建号。
abstract final class AppVersion {
  static int? compare(String first, String second) {
    final pattern = RegExp(
        r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$');
    final a = pattern.firstMatch(first.trim());
    final b = pattern.firstMatch(second.trim());
    if (a == null || b == null) return null;
    for (var i = 1; i <= 3; i++) {
      final difference =
          int.parse(a.group(i)!).compareTo(int.parse(b.group(i)!));
      if (difference != 0) return difference;
    }
    final preA = a.group(4), preB = b.group(4);
    if (preA == null && preB == null) return 0;
    if (preA == null) return 1;
    if (preB == null) return -1;
    final partsA = preA.split('.'), partsB = preB.split('.');
    for (var i = 0; i < partsA.length && i < partsB.length; i++) {
      final numberA = int.tryParse(partsA[i]),
          numberB = int.tryParse(partsB[i]);
      final difference = numberA != null && numberB != null
          ? numberA.compareTo(numberB)
          : numberA != null
              ? -1
              : numberB != null
                  ? 1
                  : partsA[i].compareTo(partsB[i]);
      if (difference != 0) return difference;
    }
    return partsA.length.compareTo(partsB.length);
  }

  static bool isNewer(
      {required String remoteVersion,
      required int remoteBuild,
      required String localVersion,
      required int localBuild}) {
    final difference = compare(remoteVersion, localVersion);
    if (difference == null) return false;
    return difference > 0 || (difference == 0 && remoteBuild > localBuild);
  }
}
