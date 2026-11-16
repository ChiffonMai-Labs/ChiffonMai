/**
 * 收藏品详情服务
 * */
import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/manager/LuoXue/CollectionsManager.dart';
import 'package:my_first_flutter_app/entity/LuoXue/Collection.dart';

class CollectionInfoService {
  // 获取收藏品详情
  Future<Collection?> getCollectionById(
      int collectionId, String collectionType) async {
    try {
      final data = await CollectionsManager().fetchCatalog(collectionType);
      final entries = data?.entriesFor(collectionType);
      if (entries == null) return null;
      for (final entry in entries) {
        if (entry.id == collectionId) return entry;
      }
      return null;
    } catch (e) {
      debugPrint('获取收藏品详情时出错: $e');
      return null;
    }
  }
}
