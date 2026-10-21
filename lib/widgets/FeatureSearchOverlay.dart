import 'package:flutter/material.dart';

import '../service/SongSearchHistoryStore.dart';
import 'SongSearchOverlay.dart';

/// 功能搜索复用搜索历史界面，独立保存关键词；输入后直接在搜索层展示结果。
class FeatureSearchOverlay {
  FeatureSearchOverlay._();

  static final historyStore = SongSearchHistoryStore(
    storageKey: 'feature_search_history_v1',
  );

  static PageRouteBuilder<String> route({
    required Rect sourceRect,
    required String initialQuery,
    required bool reduceMotion,
    Widget Function(BuildContext, String, VoidCallback)? queryResultsBuilder,
  }) =>
      SongSearchOverlay.route(
        sourceRect: sourceRect,
        initialQuery: initialQuery,
        titleOnly: false,
        reduceMotion: reduceMotion,
        hintText: '搜索功能名称或关键词',
        historyStore: historyStore,
        queryResultsBuilder: queryResultsBuilder,
      );
}
