import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ImageEncodeUtil.dart';
import '../../widgets/ExportStatsUi.dart';
import '../../widgets/HistoryLineChart.dart';
import 'ChartHistoryCore.dart';

/// Rating 历史导出图片：头部玩家信息、概览数值、趋势曲线和最近的记录点。
///
/// 预览和正式导出共用 [buildExportWidget]，保证导出抽屉里看到的就是最终效果。
class RatingHistoryExportService {
  RatingHistoryExportService._();

  static const double _width = 1200;

  /// 导出图里最多列出的记录点数量（最新的在前）。
  static const int _maxListedPoints = 30;

  static Future<File?> convertToImage(
    BuildContext context, {
    required List<RatingPoint> points,
    required String rangeLabel,
    int? jpegQuality,
    ExportImageTheme theme = ExportImageTheme.light,
  }) async {
    if (points.isEmpty) return null;
    OverlayEntry? overlayEntry;
    try {
      final status = await _requestStoragePermission();
      final globalKey = GlobalKey();
      overlayEntry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          left: -9999,
          top: -9999,
          width: _width,
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: globalKey,
              child: buildExportWidget(overlayContext,
                  points: points, rangeLabel: rangeLabel, theme: theme),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(overlayEntry);
      await _waitForRender();

      final boundary = globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        return null;
      }
      final encoded = await ImageEncodeUtil.encodeBoundary(boundary,
          jpegQuality: jpegQuality);
      overlayEntry.remove();
      overlayEntry = null;
      return await _saveImage(encoded.bytes, status.isGranted,
          extension: encoded.extension);
    } catch (e) {
      debugPrint('[RatingHistoryExport] 导出失败: $e');
      overlayEntry?.remove();
      return null;
    }
  }

  /// 导出画面本体（预览与导出共用）。
  static Widget buildExportWidget(
    BuildContext context, {
    required List<RatingPoint> points,
    required String rangeLabel,
    ExportImageTheme theme = ExportImageTheme.light,
  }) {
    return ExportPage(
      theme: theme,
      width: _width,
      padding: const EdgeInsets.all(40),
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExportPosterHeader(
              title: context.l10n.featureRatingHistory,
              caption: rangeLabel,
              scale: 0.7,
            ),
            const SizedBox(height: 32),
            _overview(context, points),
            const SizedBox(height: 32),
            ExportSectionTitle(rangeLabel),
            const SizedBox(height: 16),
            ExportStatsPanel(child: _chart(context, points, theme)),
            const SizedBox(height: 32),
            ExportSectionTitle(context.l10n.flowDataPoints),
            const SizedBox(height: 16),
            ExportStatsPanel(child: _pointList(context, points)),
          ],
        ),
      ),
    );
  }

  static Widget _overview(BuildContext context, List<RatingPoint> points) {
    final current = points.last;
    final best = points.reduce((a, b) => a.rating >= b.rating ? a : b);
    final delta = points.length >= 2 ? current.rating - points.first.rating : 0;
    return ExportStatsPanel(
      child: Row(
        children: [
          Expanded(
            child: ExportStatBlock(
                label: context.l10n.flowCurrent, value: '${current.rating}'),
          ),
          Expanded(
            child: ExportStatBlock(
              label: context.l10n.flowChange2,
              value: '${delta >= 0 ? '+' : ''}$delta',
              positive: delta == 0 ? null : delta > 0,
            ),
          ),
          Expanded(
            child: ExportStatBlock(
                label: context.l10n.flowHighest, value: '${best.rating}'),
          ),
          Expanded(
            child: ExportStatBlock(
              label: 'Best35',
              value: current.best35 > 0 ? '${current.best35}' : '-',
            ),
          ),
          Expanded(
            child: ExportStatBlock(
              label: 'Best15',
              value: current.best15 > 0 ? '${current.best15}' : '-',
            ),
          ),
        ],
      ),
    );
  }

  /// 曲线沿用页面上的 [HistoryLineChart]；它的配色取自当前 Theme，
  /// 所以按导出主题套一层对应的 App 主题，不跟随手机当时的明暗。
  static Widget _chart(
      BuildContext context, List<RatingPoint> points, ExportImageTheme theme) {
    final firstMs = points.first.tMs;
    const dayMs = 24 * 3600 * 1000;
    double x(RatingPoint p) => (p.tMs - firstMs) / dayMs;
    final ratings = points.map((p) => p.rating).toList();
    final minR = ratings.reduce((a, b) => a < b ? a : b).toDouble();
    final maxR = ratings.reduce((a, b) => a > b ? a : b).toDouble();
    final axis = niceAxisRange(minR, maxR);
    final bestIdx = ratings.indexOf(maxR.toInt());
    final themeData = switch (theme) {
      ExportImageTheme.light => AppTheme.lightTheme(),
      ExportImageTheme.dark => AppTheme.darkTheme(),
      ExportImageTheme.black => AppTheme.pureBlackTheme(),
    };
    return Theme(
      data: themeData,
      child: HistoryLineChart(
        spots: [for (final p in points) FlSpot(x(p), p.rating.toDouble())],
        height: 360,
        minY: axis.min,
        maxY: axis.max,
        leftInterval: axis.interval,
        highlightIndex: bestIdx < 0 ? null : bestIdx,
        interval: (x(points.last) / 4).clamp(1, 9999).toDouble(),
        bottomLabel: (value) => _formatDay(points.length == 1
            ? firstMs
            : firstMs + (value * dayMs).round()),
        tooltipLabel: (_) => '',
      ),
    );
  }

  static Widget _pointList(BuildContext context, List<RatingPoint> points) {
    final c = ExportPalette.of(context);
    final latest =
        points.reversed.take(_maxListedPoints).toList(growable: false);
    return Column(
      children: [
        for (final (index, p) in latest.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: index == 0
                  ? null
                  : Border(top: BorderSide(color: c.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(p.tMs),
                    style: TextStyle(fontSize: 20, color: c.ink),
                  ),
                ),
                if (p.best35 > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(
                      'B35 ${p.best35} / B15 ${p.best15}',
                      style: TextStyle(fontSize: 18, color: c.muted),
                    ),
                  ),
                Text(
                  '${p.rating}',
                  style: AppTheme.number(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _formatDay(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.month}/${d.day}';
  }

  static String _formatDateTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}/${_two(d.month)}/${_two(d.day)} '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  static Future<PermissionStatus> _requestStoragePermission() async {
    final status = await Permission.storage.status;
    final photoStatus = await Permission.photos.status;
    final videoStatus = await Permission.videos.status;
    if (status.isGranted || photoStatus.isGranted || videoStatus.isGranted) {
      return status.isGranted ? status : photoStatus;
    }
    final results = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ].request();
    return results[Permission.storage] ?? PermissionStatus.denied;
  }

  /// 保存方式与其它导出图片一致：优先 MediaStore 进相册，失败再落到目录。
  static Future<File?> _saveImage(
    Uint8List bytes,
    bool hasPermission, {
    String extension = 'png',
  }) async {
    final fileName =
        'chiffonmai_rating_history_${DateTime.now().millisecondsSinceEpoch}.$extension';
    if (Platform.isAndroid && hasPermission) {
      try {
        const channel = MethodChannel('com.example.app/media_store');
        final String? galleryPath = await channel.invokeMethod('saveImage', {
          'imageBytes': bytes,
          'fileName': fileName,
        });
        if (galleryPath != null) {
          await _notifySystemGallery(galleryPath);
          return File(galleryPath);
        }
      } catch (e) {
        debugPrint('[RatingHistoryExport] MediaStore 保存失败: $e');
      }
    }

    Directory? directory;
    if (hasPermission) {
      try {
        final pictures = Directory('/storage/emulated/0/Pictures');
        if (!pictures.existsSync()) pictures.createSync(recursive: true);
        if (await _checkDirectoryWritable(pictures)) directory = pictures;
      } catch (e) {
        debugPrint('[RatingHistoryExport] Pictures 目录不可用: $e');
      }
    }
    directory ??= await getApplicationDocumentsDirectory();
    if (!directory.existsSync()) directory.createSync(recursive: true);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    if (Platform.isAndroid) await _notifySystemGallery(file.path);
    return file;
  }

  static Future<void> _notifySystemGallery(String filePath) async {
    try {
      await MediaScanner.loadMedia(path: filePath);
    } catch (e) {
      debugPrint('[RatingHistoryExport] MediaScanner 失败: $e');
    }
  }

  /// 可写性用探针文件实测，目录存在不代表可写。
  static Future<bool> _checkDirectoryWritable(Directory directory) async {
    try {
      final probe = File(
          '${directory.path}/test_write_${DateTime.now().millisecondsSinceEpoch}.tmp');
      await probe.writeAsString('test');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _waitForRender() async {
    for (var i = 0; i < 2; i++) {
      final frame = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) => frame.complete());
      await frame.future;
    }
    // 曲线有入场动画，等它画完再截图
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
