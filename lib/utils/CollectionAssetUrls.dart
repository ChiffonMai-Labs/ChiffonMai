import '../api/ApiUrls.dart';

/// 收藏品图片由自家后端缓存后返回，客户端不再直接请求落雪素材服务器。
const String lxnsAssetBaseUrl = ApiUrls.CollectionAssetsUrl;
const String _legacyBaseUrl = 'https://assets2.lxns.net/maimai';

String lxnsIconUrl(int id) => '$lxnsAssetBaseUrl/icon/$id.png';
String lxnsPlateUrl(int id) => '$lxnsAssetBaseUrl/plate/$id.png';
String lxnsFrameUrl(int id) => '$lxnsAssetBaseUrl/frame/$id.png';

String? _collectionPath(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty)
    return null;
  String path;
  if (const {'assets2.lxns.net', 'assets.lxns.net'}.contains(uri.host)) {
    if (!uri.path.startsWith('/maimai/')) return null;
    path = uri.path.substring('/maimai/'.length);
  } else {
    final proxy = Uri.parse(lxnsAssetBaseUrl);
    if (uri.authority != proxy.authority ||
        !uri.path.startsWith('${proxy.path}/')) return null;
    path = uri.path.substring(proxy.path.length + 1);
  }
  final match = RegExp(r'^(icon|plate|frame)/(\d{1,9})\.png$').firstMatch(path);
  if (match == null) return null;
  return '${match[1]}/${int.parse(match[2]!)}.png';
}

/// 同时兼容历史缓存和服务端资料里保存的旧素材地址，不代理任意外部 URL。
String collectionAssetProxyUrl(String url) {
  final path = _collectionPath(url);
  return path == null ? url : '$lxnsAssetBaseUrl/$path';
}

/// 延续旧 URL 作为磁盘缓存键，让升级前已下载的图片继续命中本地缓存。
String collectionAssetCacheKey(String url) {
  final path = _collectionPath(url);
  return path == null ? url : '$_legacyBaseUrl/$path';
}
