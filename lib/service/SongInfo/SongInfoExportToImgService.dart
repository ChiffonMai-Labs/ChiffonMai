import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';

/// 歌曲信息导出为图片服务
/// 将歌曲的完整信息（曲绘、歌名、所有难度的物量和绝赞统计）渲染为图片
class SongInfoExportToImgService {
  /// 导出为图片的主方法
  static Future<File?> convertToImage(
    BuildContext context, {
    required String songId,
    required Map<String, dynamic> basicInfo,
    required List<dynamic> charts,
    required List<dynamic> levels,
    required List<dynamic> ds,
    required String songType,
    required List<dynamic>? diffData,
    required String bpm,
    required Map<int, List<int>> maidataNoteCounts,
    required Map<int, List<int>> maidataBreakCounts,
    required bool maidataDecodedSuccessfully,

    /// 该曲是否 extra（宴会场 / maidata 追加 / union 独有）：只影响「版本」一栏的显示
    bool isExtra = false,
    String referenceDuration = '-',
    int? jpegQuality,
  }) async {
    OverlayEntry? overlayEntry;
    try {
      debugPrint('=== SongInfoExport: STARTING IMAGE CONVERSION ===');

      // 请求存储权限
      final status = await _requestStoragePermission();
      debugPrint('Storage permission: $status');

      // 创建GlobalKey用于截图
      GlobalKey globalKey = GlobalKey();

      // 构建导出Widget
      Widget imageWidget = RepaintBoundary(
        key: globalKey,
        child: _buildExportWidget(
          context: context,
          songId: songId,
          basicInfo: basicInfo,
          charts: charts,
          levels: levels,
          ds: ds,
          songType: songType,
          diffData: diffData,
          bpm: bpm,
          maidataNoteCounts: maidataNoteCounts,
          maidataBreakCounts: maidataBreakCounts,
          maidataDecodedSuccessfully: maidataDecodedSuccessfully,
          isExtra: isExtra,
          referenceDuration: referenceDuration,
        ),
      );

      // 创建离屏OverlayEntry
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -9999,
          top: -9999,
          width: 1200,
          child: Material(
            type: MaterialType.transparency,
            child: imageWidget,
          ),
        ),
      );

      // 插入到Overlay并等待渲染
      Overlay.of(context).insert(overlayEntry);
      await _waitForRender();

      // 捕获为图片
      final boundary = globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('SongInfoExport: RenderRepaintBoundary not found');
        overlayEntry.remove();
        return null;
      }

      // 动态计算 pixelRatio：超过 GPU 最大纹理尺寸就是黑图（见 helper 注释）
      final double pixelRatio = ImageEncodeUtil.safeCapturePixelRatio(
          boundary.size.width, boundary.size.height);
      debugPrint(
          'SongInfoExport: Widget size: ${boundary.size.width}x${boundary.size.height}, pixelRatio: $pixelRatio');

      ui.Image image;
      try {
        image = await boundary.toImage(pixelRatio: pixelRatio);
      } catch (e) {
        debugPrint('SongInfoExport: First capture failed: $e');
        await Future.delayed(Duration(milliseconds: 200));
        image = await boundary.toImage(pixelRatio: pixelRatio);
      }

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('SongInfoExport: ByteData is null');
        overlayEntry.remove();
        image.dispose();
        return null;
      }

      Uint8List pngBytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      // 立刻释放 ui.Image：它本身也是上百 MB 的原生位图，而下面的 JPEG
      // 转码还要再分配上百 MB（decodePng + copyResize）。等转码完再释放，
      // 峰值内存会白白多一份 —— 低内存机就是这样被 OOM 掉的。
      // 转码只用得到 pngBytes，用不到这个 image。
      image.dispose();

      overlayEntry.remove();

      // 根据质量参数决定最终格式
      Uint8List finalBytes;
      String extension;
      if (jpegQuality != null) {
        finalBytes = await ImageEncodeUtil.pngToJpegAsync(pngBytes,
            quality: jpegQuality);
        extension = 'jpg';
      } else {
        finalBytes = pngBytes;
        extension = 'png';
      }

      // 保存图片
      final songTitle = basicInfo['title'] ?? '';
      return await _saveImage(finalBytes, songTitle, status.isGranted,
          extension: extension);
    } catch (e) {
      debugPrint('SongInfoExport: Error: $e');
      overlayEntry?.remove();
      return null;
    }
  }

  /// 构建导出Widget
  /// 构建导出预览/导出图片内容。布局顺序固定为：曲绘信息、基础信息、物量表、谱师表。
  static Widget buildPreviewWidget({
    required BuildContext context,
    required String songId,
    required Map<String, dynamic> basicInfo,
    required List<dynamic> charts,
    required List<dynamic> levels,
    required List<dynamic> ds,
    required String songType,
    required List<dynamic>? diffData,
    required String bpm,
    required Map<int, List<int>> maidataNoteCounts,
    required Map<int, List<int>> maidataBreakCounts,
    required bool maidataDecodedSuccessfully,
    bool isExtra = false,
    String referenceDuration = '-',
  }) =>
      _buildExportWidget(
        context: context,
        songId: songId,
        basicInfo: basicInfo,
        charts: charts,
        levels: levels,
        ds: ds,
        songType: songType,
        diffData: diffData,
        bpm: bpm,
        maidataNoteCounts: maidataNoteCounts,
        maidataBreakCounts: maidataBreakCounts,
        maidataDecodedSuccessfully: maidataDecodedSuccessfully,
        isExtra: isExtra,
        referenceDuration: referenceDuration,
      );

  static Widget _buildExportWidget({
    required BuildContext context,
    required String songId,
    required Map<String, dynamic> basicInfo,
    required List<dynamic> charts,
    required List<dynamic> levels,
    required List<dynamic> ds,
    required String songType,
    required List<dynamic>? diffData,
    required String bpm,
    required Map<int, List<int>> maidataNoteCounts,
    required Map<int, List<int>> maidataBreakCounts,
    required bool maidataDecodedSuccessfully,
    bool isExtra = false,
    String referenceDuration = '-',
  }) {
    final isUtage = songId.length == 6;
    final title = basicInfo['title']?.toString() ?? '';
    final artist = basicInfo['artist']?.toString() ?? '';
    final from = basicInfo['from']?.toString() ?? '';
    final genre = basicInfo['genre']?.toString() ?? '';
    final typeLabel = isUtage ? ChartDifficulty.utageLabel : StringUtil.formatSongType(songType);
    const names = ChartDifficulty.standardLabels;
    final accent = isUtage
        ? AppColors.utageAccent()
        : ColorUtil.getCardColor((levels.length - 1).clamp(0, 4).toInt());
    // 宴谱的 extra 分类只用于统计，不改变其常规世代名称。
    final versionLabel = StringUtil.formatVersion2WithFlag(from, isExtra && !isUtage);
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < levels.length; i++) {
      final notes = _getNoteCounts(
          diffIndex: i, charts: charts, maidataNoteCounts: maidataNoteCounts);
      final breakCounts = _getBreakCounts(
        diffIndex: i,
        charts: charts,
        songType: songType,
        maidataBreakCounts: maidataBreakCounts,
        maidataDecodedSuccessfully: maidataDecodedSuccessfully,
      );
      final chart =
          i < charts.length ? charts[i] as Map<String, dynamic>? : null;
      final dsValue = i < ds.length
          ? _formatDs(ds[i])
          : _formatDs(chart?['ds'] ??
              chart?['level_value'] ??
              chart?['levelValue'] ??
              chart?['internal_level'] ??
              chart?['internalLevel']);
      rows.add({
        'index': i,
        'utage': isUtage,
        'name': isUtage ? ChartDifficulty.utageLabel : (i < names.length ? names[i] : 'Lv.$i'),
        'ds': dsValue,
        'notes': notes,
        'breaks': breakCounts,
        'charter': chart?['charter']?.toString() ?? '-',
      });
    }
    // 导出画布始终为白底，表格线固定采用默认浅色配色，不跟随当前主题。
    final border = BorderSide(
        color: AppTheme.buildLightColorScheme().outlineVariant, width: 1.2);
    return Container(
      width: 1200,
      color: Colors.white,
      padding: const EdgeInsets.all(36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 4),
                    borderRadius: BorderRadius.circular(16)),
                child:
                    CoverUtil.buildCoverWidgetWithContext(context, songId, 240),
              )),
          const SizedBox(width: 28),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        height: 1.2),
                    maxLines: 3),
                const SizedBox(height: 12),
                Text(artist,
                    style: const TextStyle(
                        fontSize: 26,
                        color: Color(0xFF546161),
                        fontWeight: FontWeight.w500),
                    maxLines: 3),
                const SizedBox(height: 16),
                Text(
                  'ID: $songId',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF546161),
                  ),
                ),
                const SizedBox(height: 12),
                _buildVersionImage(from),
              ])),
        ]),
        const SizedBox(height: 30),
        _buildExportSectionTitle('基础信息', accent),
        _buildInfoTable([
          ['类别', 'BPM', '曲师', '谱面类型', '版本', '参考时长'],
          [genre, bpm, artist, typeLabel, versionLabel, referenceDuration],
        ],
        border,
        accent,
        typeColor: isUtage
            ? AppColors.utageAccent()
            : (songType == 'SD'
                ? AppColors.linkBlue(Brightness.light)
                : AppColors.warningOrange(Brightness.light)),
      ),
        const SizedBox(height: 26),
        _buildExportSectionTitle('NOTE 数量与总物量', accent),
        _buildNoteTable(rows, border, accent),
        const SizedBox(height: 26),
        _buildExportSectionTitle('绝赞数量', accent),
        _buildBreakTable(rows, border, accent),
        const SizedBox(height: 26),
        _buildExportSectionTitle('谱师', accent),
        _buildCharterTable(rows, border, accent),
        const SizedBox(height: 28),
        Center(
            child: Text('ChiffonMai',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: accent.withAlpha(170),
                    letterSpacing: 2))),
      ]),
    );
  }

  static Widget _buildExportSectionTitle(String text, Color accent) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
              width: 7,
              height: 28,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)))
        ]),
      );

  static Widget _buildInfoTable(
      List<List<String>> rows, BorderSide border, Color accent,
          {Color? typeColor}) =>
      Table(
        border: TableBorder.all(color: border.color, width: border.width),
        columnWidths: const {
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FlexColumnWidth(),
          5: FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: rows.first
                .map((label) => _tableCell(
                      label,
                      bold: true,
                      bg: accent.withAlpha(30),
                      center: true,
                    ))
                .toList(),
          ),
          TableRow(
            children: List.generate(
              rows.first.length,
              (index) {
                final label = rows.first[index];
                return _tableCell(
                  rows.length > 1 && index < rows[1].length
                      ? rows[1][index]
                      : '-',
                  color: label == '谱面类型' ? typeColor : null,
                  bold: label == '谱面类型',
                  center: true,
                  softWrap: true,
                  fitContent: label == 'BPM',
                );
              },
            ),
          ),
        ],
      );

  static Widget _buildNoteTable(
      List<Map<String, dynamic>> rows, BorderSide border, Color accent) {
    const heads = ['难度', '定数', 'TAP', 'HOLD', 'SLIDE', 'TOUCH', 'BREAK', '总物量'];
    return Table(
        border: TableBorder.all(color: border.color, width: border.width),
        columnWidths: const {
          0: FixedColumnWidth(150)
        },
        children: [
          TableRow(
              decoration: BoxDecoration(color: accent.withAlpha(30)),
              children: heads
                  .map(
                      (h) => _tableCell(h, bold: true, center: true))
                  .toList()),
          ...rows.map((r) {
            final n = (r['notes'] as List<int>);
            final total = n.fold<int>(0, (a, b) => a + b);
            final rowIndex = (r['index'] as int?) ?? 0;
            final rowAccent = r['utage'] == true
                ? AppColors.utageAccent()
                : rowIndex >= 0 && rowIndex <= 4
                    ? ColorUtil.getCardColor(rowIndex)
                    : accent;
            return TableRow(children: [
              _tableCell('${r['name']}',
                  bold: true, color: rowAccent, center: true),
              _tableCell('${r['ds']}', center: true),
              ...n.map((v) => _tableCell('$v', center: true)),
              _tableCell('$total',
                  bold: true, color: rowAccent, center: true),
            ]);
          }),
        ]);
  }

  static Widget _buildCharterTable(
          List<Map<String, dynamic>> rows, BorderSide border, Color accent) =>
      Table(
        border: TableBorder.all(color: border.color, width: border.width),
        children: [
          TableRow(
              decoration: BoxDecoration(color: accent.withAlpha(30)),
              children: rows.map((r) {
                final rowIndex = (r['index'] as int?) ?? 0;
                final rowAccent = r['utage'] == true
                    ? AppColors.utageAccent()
                    : rowIndex >= 0 && rowIndex <= 4
                        ? ColorUtil.getCardColor(rowIndex)
                        : accent;
                return _tableCell('${r['name']}',
                    bold: true, color: rowAccent, center: true);
              }).toList()),
          TableRow(
              children: rows
                  .map((r) => _tableCell('${r['charter']}',
                      center: true, softWrap: true))
                  .toList()),
        ],
      );

  static Widget _buildBreakTable(
      List<Map<String, dynamic>> rows, BorderSide border, Color accent) {
    const heads = ['难度', '真绝赞TAP', '真绝赞HOLD', '保护套绝赞', '绝赞星星'];
    return Table(
      border: TableBorder.all(color: border.color, width: border.width),
      columnWidths: const {0: FixedColumnWidth(150)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: accent.withAlpha(30)),
          children: heads
              .map((head) => _tableCell(head, bold: true, center: true))
              .toList(),
        ),
        ...rows.map((row) {
          final rowIndex = (row['index'] as int?) ?? 0;
          final rowAccent = row['utage'] == true
              ? AppColors.utageAccent()
              : rowIndex >= 0 && rowIndex <= 4
                  ? ColorUtil.getCardColor(rowIndex)
                  : accent;
          final breaks = (row['breaks'] as List<String>?) ?? const [
            '-',
            '-',
            '-',
            '-',
          ];
          return TableRow(
            children: [
              _tableCell('${row['name']}',
                  bold: true, color: rowAccent, center: true),
              ...List.generate(
                4,
                (index) => _tableCell(
                  index < breaks.length ? breaks[index] : '-',
                  center: true,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static Widget _tableCell(String value,
          {bool bold = false,
          Color? bg,
          Color? color,
          TextAlign align = TextAlign.left,
          bool center = false,
          bool softWrap = true,
          bool fitContent = false}) {
    final text = Text(value,
        textAlign: center ? TextAlign.center : align,
        softWrap: fitContent ? false : softWrap,
        style: TextStyle(
            fontSize: 20,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF2C3E50),
            height: 1.25));
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        color: bg,
        alignment: center ? Alignment.center : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        // BPM 的两行作为一个整体等比缩小，保留范围与基准的显式换行。
        child: fitContent
            ? FittedBox(fit: BoxFit.scaleDown, child: text)
            : text,
      ),
    );
  }

  static String _formatDs(dynamic value) {
    if (value == null) return '-';
    if (value is num) return value.toStringAsFixed(1);
    final parsed = double.tryParse(value.toString().trim());
    return parsed == null ? '-' : parsed.toStringAsFixed(1);
  }

  static Widget _buildVersionImage(String from) {
    var key = from.trim().replaceFirst('maimaiでらっくす', 'maimai でらっくす');
    if (key == 'maimai DX') key = 'maimai でらっくす';
    if (key.startsWith('maimai DX '))
      key = 'maimai でらっくす ${key.substring('maimai DX '.length)}';
    if (key == 'DX') key = 'maimai でらっくす';
    if (key.startsWith('DX '))
      key = 'maimai でらっくす ${key.substring('DX '.length)}';
    if (key == 'でらっくす') key = 'maimai でらっくす';
    if (key == 'でらっくす+') key = 'maimai でらっくす PLUS';
    const yearAliases = <String, String>{
      'maimai でらっくす 2020': 'maimai でらっくす',
      'maimai でらっくす 2021': 'maimai でらっくす Splash',
      'maimai でらっくす 2022': 'maimai でらっくす UNiVERSE',
      'maimai でらっくす 2023': 'maimai でらっくす FESTiVAL',
      'maimai でらっくす 2024': 'maimai でらっくす BUDDiES',
      'maimai でらっくす 2025': 'maimai でらっくす PRiSM',
      'maimai でらっくす 2026': 'maimai でらっくす PRiSM PLUS',
    };
    key = yearAliases[key] ?? key;
    const assets = <String, String>{
      'maimai': 'assets/version/maimai.webp',
      'maimai PLUS': 'assets/version/maimai_PLUS.webp',
      'maimai GreeN': 'assets/version/maimai_GreeN.webp',
      'maimai GreeN PLUS': 'assets/version/maimai_GreeN_PLUS.webp',
      'maimai ORANGE': 'assets/version/maimai_ORANGE.webp',
      'maimai ORANGE PLUS': 'assets/version/maimai_ORANGE_PLUS.webp',
      'maimai PiNK': 'assets/version/maimai_PiNK.webp',
      'maimai PiNK PLUS': 'assets/version/maimai_PiNK_PLUS.webp',
      'maimai MURASAKi': 'assets/version/maimai_MURASAKi.webp',
      'maimai MURASAKi PLUS': 'assets/version/maimai_MURASAKi_PLUS.webp',
      'maimai MiLK': 'assets/version/maimai_MiLK.webp',
      'MiLK PLUS': 'assets/version/maimai_MiLK_PLUS.webp',
      'maimai MiLK PLUS': 'assets/version/maimai_MiLK_PLUS.webp',
      'maimai FiNALE': 'assets/version/maimai_FiNALE.webp',
      'maimai でらっくす': 'assets/version/maimai_DX.webp',
      'maimai でらっくす PLUS': 'assets/version/maimai_DX_PLUS.webp',
      'maimai でらっくす Splash': 'assets/version/maimai_DX_Splash.webp',
      'maimai でらっくす Splash PLUS': 'assets/version/maimai_DX_Splash_PLUS.webp',
      'maimai でらっくす UNiVERSE': 'assets/version/maimai_DX_UNiVERSE.webp',
      'maimai でらっくす UNiVERSE PLUS':
          'assets/version/maimai_DX_UNiVERSE_PLUS.webp',
      'maimai でらっくす FESTiVAL': 'assets/version/maimai_DX_FESTiVAL.webp',
      'maimai でらっくす FESTiVAL PLUS':
          'assets/version/maimai_DX_FESTiVAL_PLUS.webp',
      'maimai でらっくす BUDDiES': 'assets/version/maimai_DX_BUDDiES.webp',
      'maimai でらっくす BUDDiES PLUS': 'assets/version/maimai_DX_BUDDiES_PLUS.webp',
      'maimai でらっくす PRiSM': 'assets/version/maimai_DX_PRiSM.webp',
      'maimai でらっくす PRiSM PLUS': 'assets/version/maimai_DX_PRiSM_PLUS.webp',
      'maimai でらっくす CiRCLE': 'assets/version/maimai_DX_CiRCLE.webp',
      'maimai でらっくす CiRCLE PLUS': 'assets/version/maimai_DX_CiRCLE_PLUS.webp',
      'maimai でらっくす MAGiCAL': 'assets/version/maimai_DX_MAGiCAL.webp',
    };
    // 版本对照页的中文版本图按 DX 年份命名；不能直接使用 BUDDiES 等日服图，
    // 否则「DX 2024」会错误显示为 BUDDiES 图。
    const chineseAssets = <String, String>{
      'maimai でらっくす': 'assets/version/maimai_2020.webp',
      'maimai でらっくす Splash': 'assets/version/maimai_2021.webp',
      'maimai でらっくす UNiVERSE': 'assets/version/maimai_2022.webp',
      'maimai でらっくす FESTiVAL': 'assets/version/maimai_2023.webp',
      'maimai でらっくす BUDDiES': 'assets/version/maimai_2024.webp',
      'maimai でらっくす PRiSM': 'assets/version/maimai_2025.webp',
      'maimai でらっくす PRiSM PLUS': 'assets/version/maimai_2026.webp',
    };
    final asset = chineseAssets[key] ?? assets[key];
    if (asset == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(asset,
          width: 150,
          height: 64,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    );
  }

  /// 构建单个难度区域
  static Widget _buildDifficultySection({
    required BuildContext context,
    required String songId,
    required int diffIndex,
    required String diffName,
    required String levelStr,
    required double dsValue,
    required Map<String, dynamic> basicInfo,
    required List<dynamic> charts,
    required List<dynamic>? diffData,
    required Map<int, List<int>> maidataNoteCounts,
    required Map<int, List<int>> maidataBreakCounts,
    required bool maidataDecodedSuccessfully,
    required bool isUtage,
  }) {
    final Color accentColor =
        isUtage ? AppColors.utageAccent() : ColorUtil.getCardColor(diffIndex);

    // 获取谱面信息
    Map<String, dynamic>? chart;
    if (diffIndex < charts.length) {
      chart = charts[diffIndex] as Map<String, dynamic>?;
    }
    final String charter = chart?['charter'] ?? '-';

    // 获取 diffData（拟合定数、平均达成）
    dynamic currentDiffData;
    if (diffData != null && diffData.length > diffIndex) {
      currentDiffData = diffData[diffIndex];
    }

    // 获取物量
    List<int> noteCounts = _getNoteCounts(
      diffIndex: diffIndex,
      charts: charts,
      maidataNoteCounts: maidataNoteCounts,
    );

    // 获取绝赞统计
    List<String> breakCounts = _getBreakCounts(
      diffIndex: diffIndex,
      charts: charts,
      songType: basicInfo['type'] ?? '',
      maidataBreakCounts: maidataBreakCounts,
      maidataDecodedSuccessfully: maidataDecodedSuccessfully,
    );

    // 计算最大DX分（用于显示）
    int maxDxScore = _calculateMaxScore(noteCounts);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accentColor, width: 5),
        ),
        color: const Color(0xFFFCFCFC),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 难度标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _getDifficultyBgColor(diffIndex, isUtage),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  isUtage ? ChartDifficulty.utageLabel : diffName,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isUtage
                        ? AppColors.utageAccent()
                        : _getDifficultyFgColor(diffIndex),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$levelStr (定数 ${dsValue.toStringAsFixed(1)})',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isUtage
                        ? AppColors.utageAccent()
                        : _getDifficultyFgColor(diffIndex),
                  ),
                ),
                const Spacer(),
                Text(
                  'Max: $maxDxScore',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 信息行1: 官方定数 + 拟合定数 + 定数差值
          Row(
            children: [
              Expanded(
                  child: _buildStatItem('官方定数', dsValue.toStringAsFixed(1))),
              _buildStatDivider(),
              Expanded(
                child: _buildStatItem(
                  '拟合定数',
                  currentDiffData != null
                      ? _parseFitDiff(currentDiffData).toStringAsFixed(2)
                      : '-',
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: () {
                  if (currentDiffData == null) {
                    return _buildStatItem('定数差值', '-');
                  }
                  final fd = _parseFitDiff(currentDiffData);
                  final diff = fd - dsValue;
                  return _buildStatItem(
                    '定数差值',
                    '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)}',
                    valueColor: diff < 0 ? Colors.green : Colors.red,
                  );
                }(),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatItem(
                  '平均达成',
                  currentDiffData != null
                      ? '${_parseAvg(currentDiffData).toStringAsFixed(2)}%'
                      : '-',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 信息行2: 谱师
          Row(
            children: [
              _buildStatItem('谱师', charter),
            ],
          ),

          const SizedBox(height: 16),

          // 分隔线
          Divider(color: Colors.grey.shade200, height: 1),

          const SizedBox(height: 12),

          // 物量行
          Text(
            '物量统计',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildNoteItem(
                      '总计',
                      noteCounts.fold<int>(0, (sum, n) => sum + n).toString(),
                      accentColor)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildNoteItem(
                      'TAP', noteCounts[0].toString(), accentColor)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildNoteItem(
                      'HOLD', noteCounts[1].toString(), accentColor)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildNoteItem(
                      'SLIDE', noteCounts[2].toString(), accentColor)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildNoteItem(
                      'TOUCH', noteCounts[3].toString(), accentColor)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildNoteItem(
                      'BREAK', noteCounts[4].toString(), accentColor)),
            ],
          ),

          const SizedBox(height: 16),

          // 绝赞统计行
          Text(
            '绝赞统计',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildBreakItem(
                      '真绝赞TAP', breakCounts[0], const Color(0xFFEF5350))),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildBreakItem(
                      '真绝赞HOLD', breakCounts[1], const Color(0xFFFF6B6B))),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildBreakItem(
                      '保护套绝赞', breakCounts[2], const Color(0xFF64B5F6))),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildBreakItem(
                      '绝赞星星', breakCounts[3], const Color(0xFFFBC02D))),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 数据解析辅助方法 ====================

  /// 获取物量统计，优先使用 maidata 解析结果，fallback 到 charts notes
  static List<int> _getNoteCounts({
    required int diffIndex,
    required List<dynamic> charts,
    required Map<int, List<int>> maidataNoteCounts,
  }) {
    // 优先使用Maidata解析的物量统计
    if (maidataNoteCounts.containsKey(diffIndex)) {
      final rawCounts = maidataNoteCounts[diffIndex]!;
      final counts = List<int>.filled(5, 0);
      for (var i = 0; i < rawCounts.length && i < counts.length; i++) {
        counts[i] = rawCounts[i];
      }
      bool allZero = counts.every((count) => count == 0);
      if (!allZero) {
        return counts;
      }
    }

    // Fallback: 使用默认的notes数据
    List<int> notes = List.filled(5, 0);
    if (diffIndex >= charts.length) return notes;

    final chart = charts[diffIndex] as Map<String, dynamic>?;
    if (chart == null || chart['notes'] == null) return notes;

    List<dynamic> chartNotes = chart['notes'];
    notes[0] = chartNotes.length > 0 ? _parseInt(chartNotes[0]) : 0;
    notes[1] = chartNotes.length > 1 ? _parseInt(chartNotes[1]) : 0;
    notes[2] = chartNotes.length > 2 ? _parseInt(chartNotes[2]) : 0;
    if (chartNotes.length > 4) {
      // DX谱面: notes = [tap, hold, slide, touch, break]
      notes[3] = _parseInt(chartNotes[3]);
      notes[4] = _parseInt(chartNotes[4]);
    } else if (chartNotes.length > 3) {
      // ST谱面: notes = [tap, hold, slide, break]
      notes[4] = _parseInt(chartNotes[3]);
    }
    return notes;
  }

  /// 获取绝赞统计，优先使用 maidata 解析结果，fallback 到兜底逻辑
  static List<String> _getBreakCounts({
    required int diffIndex,
    required List<dynamic> charts,
    required String songType,
    required Map<int, List<int>> maidataBreakCounts,
    required bool maidataDecodedSuccessfully,
  }) {
    // 优先使用 maidata 解析结果
    if (maidataDecodedSuccessfully &&
        maidataBreakCounts.containsKey(diffIndex)) {
      List<int> counts = maidataBreakCounts[diffIndex]!;
      bool allZero = counts.every((count) => count == 0);
      if (!allZero && counts.length >= 4) {
        return counts.map((c) => c.toString()).toList();
      }
    }

    // 兜底方案
    // ST谱面（SD类型）：真绝赞TAP = 总绝赞数量，其余为0
    if (songType == 'SD') {
      int breakCount = 0;
      if (diffIndex < charts.length) {
        final chart = charts[diffIndex] as Map<String, dynamic>?;
        if (chart != null && chart['notes'] != null) {
          List<dynamic> notes = chart['notes'];
          int breakIndex = notes.length >= 5 ? 4 : 3;
          if (notes.length > breakIndex) {
            breakCount = _parseInt(notes[breakIndex]);
          }
        }
      }
      return [breakCount.toString(), '0', '0', '0'];
    }

    // DX谱面无maidata时返回'-'
    return ['-', '-', '-', '-'];
  }

  /// 计算最大DX分
  static int _calculateMaxScore(List<int> noteCounts) {
    int totalNotes = noteCounts.fold(0, (sum, n) => sum + n);
    return totalNotes * 3;
  }

  /// 安全解析 int
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 解析拟合定数（兼容 DiffData 对象和 Map）
  static double _parseFitDiff(dynamic diffData) {
    if (diffData == null) return 0.0;
    try {
      // DiffData 对象
      final fitDiff = diffData.fitDiff;
      if (fitDiff != null) {
        if (fitDiff is num) return fitDiff.toDouble();
        return double.tryParse(fitDiff.toString()) ?? 0.0;
      }
    } catch (_) {}
    try {
      // Map 对象
      final fd = diffData['fit_diff'];
      if (fd != null) {
        if (fd is num) return fd.toDouble();
        return double.tryParse(fd.toString()) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  /// 解析平均达成（兼容 DiffData 对象和 Map）
  static double _parseAvg(dynamic diffData) {
    if (diffData == null) return 0.0;
    try {
      final avg = diffData.avg;
      if (avg != null) {
        if (avg is num) return avg.toDouble();
        return double.tryParse(avg.toString()) ?? 0.0;
      }
    } catch (_) {}
    try {
      final a = diffData['avg'];
      if (a != null) {
        if (a is num) return a.toDouble();
        return double.tryParse(a.toString()) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  // ==================== UI 组件构建方法 ====================

  /// 构建信息标签
  static Widget _buildInfoChip(String text, Color color,
      {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: filled ? null : Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }

  /// 构建统计项
  static Widget _buildStatItem(String label, String value,
      {Color? valueColor}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF546161).withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF2C3E50),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 统计项分隔线
  static Widget _buildStatDivider() {
    return Container(
      width: 2,
      height: 50,
      color: const Color(0xFF546161).withAlpha(30),
    );
  }

  /// 构建物量项
  static Widget _buildNoteItem(String type, String count, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            type,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF6D7D7D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建绝赞统计项
  static Widget _buildBreakItem(String type, String count, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            type,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF6D7D7D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 渲染和保存管线 ====================

  static Future<void> _waitForRender() async {
    Completer<void> completer1 = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer1.complete());
    await completer1.future;

    Completer<void> completer2 = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer2.complete());
    await completer2.future;

    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('SongInfoExport: Render wait completed');
  }

  static Future<PermissionStatus> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;
      final videosStatus = await Permission.videos.status;

      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted) {
        return PermissionStatus.granted;
      }

      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

      return (storageGranted || photosGranted || videosGranted)
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } else {
      final status = await Permission.storage.request();
      return status;
    }
  }

  static Future<File?> _saveImage(
    Uint8List imageBytes,
    String songTitle,
    bool hasPermission, {
    String extension = 'png',
  }) async {
    Directory? directory;

    if (hasPermission) {
      try {
        String picturesPath = '/storage/emulated/0/Pictures';
        directory = Directory(picturesPath);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        bool canWrite = await _checkDirectoryWritable(directory);
        if (!canWrite) {
          directory = null;
        }
      } catch (e) {
        debugPrint('SongInfoExport: Pictures dir error: $e');
        directory = null;
      }
    }

    if (directory == null) {
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        try {
          directory = await getExternalStorageDirectory();
        } catch (e2) {
          debugPrint('SongInfoExport: No storage dir found');
          return null;
        }
      }
    }

    if (directory == null) return null;

    // Android: 尝试 MediaStore API
    if (Platform.isAndroid && hasPermission) {
      String? galleryPath = await _saveImageToGallery(
        imageBytes,
        'chiffonmai_songinfo_${_sanitizeFileName(songTitle)}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (galleryPath != null) {
        await _notifySystemGallery(galleryPath);
        return File(galleryPath);
      }
    }

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File(
      '${directory.path}/chiffonmai_songinfo_${_sanitizeFileName(songTitle)}_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(imageBytes);

    if (Platform.isAndroid) {
      await _notifySystemGallery(file.path);
    }

    return file;
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(' ', '_');
  }

  static Future<String?> _saveImageToGallery(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      const MethodChannel channel =
          MethodChannel('com.example.app/media_store');
      final String? result = await channel.invokeMethod('saveImage', {
        'imageBytes': imageBytes,
        'fileName': fileName,
      });
      return result;
    } catch (e) {
      debugPrint('SongInfoExport: MediaStore error: $e');
      return null;
    }
  }

  static Future<void> _notifySystemGallery(String filePath) async {
    try {
      await MediaScanner.loadMedia(path: filePath);
    } catch (e) {
      debugPrint('SongInfoExport: MediaScanner error: $e');
    }
    try {
      const MethodChannel channel = MethodChannel('com.example.app/media_scan');
      await channel.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      debugPrint('SongInfoExport: scanFile error: $e');
    }
    try {
      const MethodChannel channel = MethodChannel('com.example.app/media_scan');
      await channel.invokeMethod('scanImage', {'path': filePath});
    } catch (e) {
      debugPrint('SongInfoExport: scanImage error: $e');
    }
  }

  static Future<bool> _checkDirectoryWritable(Directory directory) async {
    try {
      String testFileName =
          'test_write_${DateTime.now().millisecondsSinceEpoch}.tmp';
      File testFile = File('${directory.path}/$testFileName');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== 颜色辅助 ====================

  /// 获取难度前景色（标签/文字颜色）
  static Color _getDifficultyFgColor(int diffIndex) {
    switch (diffIndex) {
      case ChartDifficulty.basic:
        return const Color(0xFF4CAF50);
      case ChartDifficulty.advanced:
        return const Color(0xFFFF9800);
      case ChartDifficulty.expert:
        return const Color(0xFFE91E63);
      case ChartDifficulty.master:
        return const Color(0xFF9966CC);
      case ChartDifficulty.reMaster:
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9966CC);
    }
  }

  /// 获取难度背景色
  static Color _getDifficultyBgColor(int diffIndex, bool isUtage) {
    if (isUtage) return const Color(0xFFFFE6F0);
    switch (diffIndex) {
      case ChartDifficulty.basic:
        return const Color(0xFFE8F5E8);
      case ChartDifficulty.advanced:
        return const Color(0xFFFFF8E1);
      case ChartDifficulty.expert:
        return const Color(0xFFFCE4EC);
      case ChartDifficulty.master:
        return const Color(0xFFE9D8FF);
      case ChartDifficulty.reMaster:
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFE9D8FF);
    }
  }
}
