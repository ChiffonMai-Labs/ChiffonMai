import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../widgets/ExportStatsUi.dart';

class PersonalizedScoreConvertToImg {
  static GlobalKey _globalKey = GlobalKey();

  static Future<File?> convertToImage(
    BuildContext context, {
    required String? selectedLevel,
    required String? selectedCharter,
    required String? selectedVersion,
    required String? selectedArtist,
    required String? selectedGenre,
    required String mode,
    required String? selectedTitleType,
    required int? selectedDifficulty,
    required List<Map<String, dynamic>>? cachedSongsWithStatus,
    required String filterMode,
    required String Function(int) getDifficultyName,
    required String Function(double) getLevelDisplay,
    required double Function(int, int) getSongAchievement,
    required bool useLevelDisplay,
    void Function(String message, double progress)? onProgress,
    int? jpegQuality,
    ExportImageTheme theme = ExportImageTheme.light,
  }) async {
    OverlayEntry? overlayEntry;
    try {
      debugPrint('=== STARTING PERSONALIZED SCORE IMAGE CONVERSION ===');
      debugPrint(
          'Current platform: ${Platform.operatingSystem} ${Platform.version}');

      onProgress?.call(context.l10n.flowRequestingStoragePermission, 0.0);
      debugPrint('Step 1: Requesting storage permission...');
      PermissionStatus status = await _requestStoragePermission();
      debugPrint('Step 1 completed: Storage permission status: $status');
      debugPrint('Is granted: ${status.isGranted}');

      GlobalKey globalKey = GlobalKey();
      final mountedAll = Completer<void>();

      onProgress?.call(context.l10n.flowBuildingExportContent, 0.1);

      Widget imageWidget = RepaintBoundary(
        key: globalKey,
        child: _buildExportImageWidget(
          context,
          onMounted: () {
            if (!mountedAll.isCompleted) mountedAll.complete();
          },
          selectedLevel: selectedLevel,
          selectedCharter: selectedCharter,
          selectedVersion: selectedVersion,
          selectedArtist: selectedArtist,
          selectedGenre: selectedGenre,
          mode: mode,
          selectedTitleType: selectedTitleType,
          selectedDifficulty: selectedDifficulty,
          cachedSongsWithStatus: cachedSongsWithStatus,
          filterMode: filterMode,
          getDifficultyName: getDifficultyName,
          getLevelDisplay: getLevelDisplay,
          getSongAchievement: getSongAchievement,
          useLevelDisplay: useLevelDisplay,
          theme: theme,
        ),
      );

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

      await _preloadImages();
      debugPrint('Images preloaded');

      onProgress?.call(context.l10n.flowPreloadingImages, 0.2);

      Overlay.of(context).insert(overlayEntry);
      debugPrint('Overlay entry inserted');

      onProgress?.call(context.l10n.flowRenderingExportContent, 0.3);

      // 曲绘分批挂载，全部挂完才能截图。
      await mountedAll.future
          .timeout(const Duration(seconds: 30), onTimeout: () {});
      await _waitForRender();
      debugPrint('Render wait completed');

      final RenderRepaintBoundary? boundary = globalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('Error: RenderRepaintBoundary not found');
        overlayEntry.remove();
        return null;
      }
      debugPrint('RenderRepaintBoundary found successfully');

      await Future.delayed(Duration(milliseconds: 100));

      onProgress?.call(context.l10n.flowGeneratingImage, 0.5);

      debugPrint('Starting image capture...');

      // 动态计算 pixelRatio：超过 GPU 最大纹理尺寸就是黑图（见 helper 注释）
      final double pixelRatio = ImageEncodeUtil.safeCapturePixelRatio(
          boundary.size.width, boundary.size.height);

      debugPrint(
          'Widget size: ${boundary.size.width}x${boundary.size.height}, calculated pixelRatio: $pixelRatio');

      final encoded = await ImageEncodeUtil.encodeBoundary(boundary,
          jpegQuality: jpegQuality);
      final Uint8List finalBytes = encoded.bytes;
      final String extension = encoded.extension;

      overlayEntry.remove();

      onProgress?.call(context.l10n.flowSavingImage, 0.8);

      Directory? directory;
      debugPrint(
          'Step 4: Saving image. Permission granted: ${status.isGranted}');

      if (status.isGranted) {
        debugPrint(
            'Step 4a: Permission granted, trying to use Pictures directory');
        try {
          String picturesPath = '/storage/emulated/0/Pictures';
          directory = Directory(picturesPath);
          debugPrint('Pictures directory path: $picturesPath');

          bool exists = directory.existsSync();
          debugPrint('Pictures directory exists: $exists');

          if (!exists) {
            debugPrint('Creating Pictures directory...');
            directory.createSync(recursive: true);
            debugPrint('Created Pictures directory successfully');
          }

          bool canWrite = await _checkDirectoryWritable(directory);
          debugPrint('Pictures directory writable: $canWrite');

          if (!canWrite) {
            debugPrint(
                'Warning: Pictures directory is not writable, will fall back');
            directory = null;
          }
        } catch (e) {
          debugPrint('Error getting pictures directory: $e');
          directory = null;
        }
      }

      if (directory == null) {
        debugPrint('Step 4b: Using fallback directory');
        try {
          directory = await getApplicationDocumentsDirectory();
          debugPrint('Using app documents directory: ${directory.path}');
        } catch (e) {
          debugPrint('Error getting application documents directory: $e');
          try {
            directory = await getExternalStorageDirectory();
            debugPrint('Using external storage directory: ${directory?.path}');
          } catch (e2) {
            debugPrint('Error getting external storage directory: $e2');
          }
        }
      }

      if (directory == null) {
        debugPrint('Error: No storage directory found');
        overlayEntry.remove();
        return null;
      }

      debugPrint('Selected directory: ${directory.path}');

      if (Platform.isAndroid && status.isGranted) {
        debugPrint('Step 5: Trying to save via MediaStore API...');
        String? galleryPath = await _saveImageToGallery(finalBytes,
            'personalized_score_export_${DateTime.now().millisecondsSinceEpoch}.$extension');
        if (galleryPath != null) {
          debugPrint('Image saved to gallery via MediaStore: $galleryPath');
          await _notifySystemGallery(galleryPath);
          onProgress?.call(context.l10n.flowExportComplete, 1.0);
          return File(galleryPath);
        }
        debugPrint('MediaStore API failed, falling back to file system');
      }

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file = File(
          '${directory.path}/personalized_score_export_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await file.writeAsBytes(finalBytes);
      debugPrint('Image saved to: ${file.path}');

      if (Platform.isAndroid) {
        await _notifySystemGallery(file.path);
        debugPrint('Media scanner completed for: ${file.path}');
      }

      onProgress?.call(context.l10n.flowExportComplete, 1.0);
      return file;
    } catch (e) {
      debugPrint('Error converting to image: $e');
      overlayEntry?.remove();
      return null;
    }
  }

  /// 构建与实际导出相同的预览 Widget。
  static Widget buildPreviewWidget(
    BuildContext context, {
    required String? selectedLevel,
    required String? selectedCharter,
    required String? selectedVersion,
    required String? selectedArtist,
    required String? selectedGenre,
    required String mode,
    required String? selectedTitleType,
    required int? selectedDifficulty,
    required List<Map<String, dynamic>>? cachedSongsWithStatus,
    required String filterMode,
    required String Function(int) getDifficultyName,
    required String Function(double) getLevelDisplay,
    required double Function(int, int) getSongAchievement,
    required bool useLevelDisplay,
    ExportImageTheme theme = ExportImageTheme.light,
  }) =>
      _buildExportImageWidget(
        context,
        selectedLevel: selectedLevel,
        selectedCharter: selectedCharter,
        selectedVersion: selectedVersion,
        selectedArtist: selectedArtist,
        selectedGenre: selectedGenre,
        mode: mode,
        selectedTitleType: selectedTitleType,
        selectedDifficulty: selectedDifficulty,
        cachedSongsWithStatus: cachedSongsWithStatus,
        filterMode: filterMode,
        getDifficultyName: getDifficultyName,
        getLevelDisplay: getLevelDisplay,
        getSongAchievement: getSongAchievement,
        useLevelDisplay: useLevelDisplay,
        theme: theme,
      );

  static Widget _buildExportImageWidget(
    BuildContext context, {
    VoidCallback? onMounted,
    required String? selectedLevel,
    required String? selectedCharter,
    required String? selectedVersion,
    required String? selectedArtist,
    required String? selectedGenre,
    required String mode,
    required String? selectedTitleType,
    required int? selectedDifficulty,
    required List<Map<String, dynamic>>? cachedSongsWithStatus,
    required String filterMode,
    required String Function(int) getDifficultyName,
    required String Function(double) getLevelDisplay,
    required double Function(int, int) getSongAchievement,
    required bool useLevelDisplay,
    ExportImageTheme theme = ExportImageTheme.light,
  }) {
    const double containerWidth = 1200.0;
    final c = ExportPalette.forTheme(theme);

    if (cachedSongsWithStatus == null || cachedSongsWithStatus.isEmpty) {
      onMounted?.call();
      return ExportPage(
        theme: theme,
        width: containerWidth,
        height: 400,
        child: Center(
          child: Text(
            context.l10n.flowNoData,
            style: TextStyle(fontSize: 36, color: Colors.grey),
          ),
        ),
      );
    }

    List<Map<String, dynamic>> songsWithStatus = cachedSongsWithStatus;

    if (filterMode == 'completed') {
      songsWithStatus =
          songsWithStatus.where((item) => item['completed'] as bool).toList();
    } else if (filterMode == 'uncompleted') {
      songsWithStatus = songsWithStatus
          .where((item) => !(item['completed'] as bool))
          .toList();
    }

    final totalCount = songsWithStatus.length;
    final completedCount =
        songsWithStatus.where((item) => item['completed'] as bool).length;
    final completionRate =
        totalCount > 0 ? (completedCount / totalCount * 100) : 0;

    // 统计各难度完成情况
    final difficultyNames = ChartDifficulty.standardLabels;
    List<Map<String, dynamic>> difficultyStats = [];
    for (int d = 0; d < difficultyNames.length; d++) {
      final diffSongs = songsWithStatus
          .where((item) => (item['difficulty'] as int) == d)
          .toList();
      if (diffSongs.isNotEmpty) {
        final diffTotal = diffSongs.length;
        final diffCompleted =
            diffSongs.where((item) => item['completed'] as bool).length;
        difficultyStats.add({
          'name': difficultyNames[d],
          'total': diffTotal,
          'completed': diffCompleted,
          'rate': diffTotal > 0 ? diffCompleted / diffTotal : 0.0,
        });
      }
    }

    double totalAchievement = 0.0;
    for (final item in songsWithStatus) {
      final dynamic song = item['song'];
      final diff = item['difficulty'] as int;
      if (song is Song) {
        totalAchievement += getSongAchievement(int.parse(song.id), diff);
      }
    }
    final averageAchievement =
        totalCount > 0 ? totalAchievement / totalCount : 0.0;

    Map<String, List<Map<String, dynamic>>> groupedSongs = {};
    for (final item in songsWithStatus) {
      final dynamic song = item['song'];
      final diffIndex = item['difficulty'] as int;
      String levelKey = context.l10n.flowUnknown;
      if (song is Song) {
        if (song.ds != null && song.ds.length > diffIndex) {
          final ds = song.ds[diffIndex];
          levelKey =
              useLevelDisplay ? getLevelDisplay(ds) : ds.toStringAsFixed(1);
        }
      }
      if (!groupedSongs.containsKey(levelKey)) {
        groupedSongs[levelKey] = [];
      }
      groupedSongs[levelKey]!.add(item);
    }

    final sortedLevelKeys = groupedSongs.keys.toList()
      ..sort((a, b) {
        double parseDs(String ds) {
          if (useLevelDisplay) {
            if (ds == '15') return 15.0;
            if (ds.endsWith('+')) {
              return double.parse(ds.substring(0, ds.length - 1)) + 0.5;
            }
            return double.tryParse(ds) ?? 0.0;
          } else {
            return double.tryParse(ds) ?? 0.0;
          }
        }

        return parseDs(b).compareTo(parseDs(a));
      });

    double coverSize = containerWidth * 0.083;
    double sectionNameFontSize = containerWidth * 0.022;

    return ExportPage(
      theme: theme,
      width: containerWidth,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExportPosterHeader(
                title: context.l10n.featureScoreLookup, scale: 0.7),
            SizedBox(height: 16.0),

            // 统计区域
            ExportCompletionPanel(
              title: context.l10n.flowP0P1P2Statistics2(
                  (mode == 'level'
                          ? 'Lv.${selectedLevel ?? ''}'
                          : mode == 'charter'
                              ? context.l10n.flowChartDesignerP0(
                                  (selectedCharter ?? '').toString())
                              : mode == 'version'
                                  ? context.l10n.flowVersionP0(
                                      (StringUtil.formatVersion2(
                                              selectedVersion ?? ''))
                                          .toString())
                                  : mode == 'genre'
                                      ? context.l10n.flowGenreP0(
                                          (selectedGenre ?? '').toString())
                                      : context.l10n.flowComposerP0(
                                          (selectedArtist ?? '').toString()))
                      .toString(),
                  (selectedTitleType ?? '').toString(),
                  (getDifficultyName(selectedDifficulty ?? -1)).toString()),
              total: totalCount,
              completed: completedCount,
              completionRate: completionRate.toDouble(),
              averageAchievement: averageAchievement,
              difficultyStats: [
                for (final stat in (difficultyStats))
                  ExportDifficultyStat(
                    name: stat['name'] as String,
                    color: ColorUtil.getCoverBorderColor(
                        difficultyNames.indexOf(stat['name'] as String)),
                    completed: stat['completed'] as int,
                    total: stat['total'] as int,
                    rate: stat['rate'] as double,
                  ),
              ],
            ),
            SizedBox(height: 16.0),

            // 歌曲列表
            ExportProgressiveColumn(
              onComplete: onMounted,
              children: [
                for (final levelKey in sortedLevelKeys) ...[
                  // 定数分隔线
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: c.panel,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
                    margin: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      context.l10n.flowP0P1P2SongsTotal(
                          (useLevelDisplay ? 'Lv.' : '').toString(),
                          (levelKey).toString(),
                          (groupedSongs[levelKey]!.length).toString()),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sectionNameFontSize,
                        color: c.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...exportCoverRows(groupedSongs[levelKey]!.length,
                      (context, index) {
                    final item = groupedSongs[levelKey]![index];
                    final dynamic song = item['song'];
                    final isCompleted = item['completed'] as bool;
                    final diffIndex = item['difficulty'] as int;

                    String songId = '';
                    if (song is Song) {
                      songId = song.id;
                    }

                    return Center(
                      child: SizedBox(
                        width: coverSize,
                        height: coverSize,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CoverUtil.buildCoverWidgetWithContext(
                                _globalKey.currentContext ?? context,
                                songId,
                                coverSize,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: coverSize * 0.4,
                                  ),
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      ColorUtil.getCoverBorderColor(diffIndex),
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 16.0),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _preloadImages() async {
    try {
      debugPrint('Personalized score: preloading images...');
    } catch (e) {
      debugPrint('Error preloading images: $e');
    }
  }

  static Future<void> _waitForRender() async {
    Completer<void> frameCompleter = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      frameCompleter.complete();
    });
    await frameCompleter.future;

    Completer<void> frameCompleter2 = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      frameCompleter2.complete();
    });
    await frameCompleter2.future;

    await Future.delayed(Duration(milliseconds: 500));
    debugPrint('Render wait completed');
  }

  static Future<void> _sendMediaScanBroadcast(String filePath) async {
    try {
      const MethodChannel channel = MethodChannel('com.example.app/media_scan');
      await channel.invokeMethod('scanFile', {'path': filePath});
      debugPrint('Broadcast sent for: $filePath');
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
    }
  }

  static Future<void> _notifySystemGallery(String filePath) async {
    try {
      await MediaScanner.loadMedia(path: filePath);
      debugPrint('MediaScanner.loadMedia succeeded for: $filePath');
    } catch (e) {
      debugPrint('MediaScanner.loadMedia failed: $e');
    }

    await _sendMediaScanBroadcast(filePath);

    try {
      const MethodChannel channel = MethodChannel('com.example.app/media_scan');
      await channel.invokeMethod('scanImage', {'path': filePath});
      debugPrint('MediaStore scan succeeded for: $filePath');
    } catch (e) {
      debugPrint('MediaStore scan failed: $e');
    }
  }

  static Future<String?> _saveImageToGallery(
      Uint8List imageBytes, String fileName) async {
    try {
      const MethodChannel channel =
          MethodChannel('com.example.app/media_store');
      final String? result = await channel.invokeMethod('saveImage', {
        'imageBytes': imageBytes,
        'fileName': fileName,
      });
      debugPrint('MediaStore save result: $result');
      return result;
    } catch (e) {
      debugPrint('Error saving image via MediaStore: $e');
      return null;
    }
  }

  static Future<bool> _checkDirectoryWritable(Directory directory) async {
    try {
      String testFileName =
          'test_write_permission_${DateTime.now().millisecondsSinceEpoch}.tmp';
      File testFile = File('${directory.path}/$testFileName');

      await testFile.writeAsString('test');
      await testFile.delete();

      debugPrint('Directory writable test passed: ${directory.path}');
      return true;
    } catch (e) {
      debugPrint('Directory writable test failed: $e');
      return false;
    }
  }

  static Future<PermissionStatus> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      debugPrint('Android platform detected');

      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus videosStatus = await Permission.videos.status;

      debugPrint('Storage status: $storageStatus');
      debugPrint('Photos status: $photosStatus');
      debugPrint('Videos status: $videosStatus');

      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted) {
        debugPrint('At least one permission already granted');
        return PermissionStatus.granted;
      }

      debugPrint('Requesting storage, photos and videos permissions...');
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

      debugPrint('Storage granted: $storageGranted');
      debugPrint('Photos granted: $photosGranted');
      debugPrint('Videos granted: $videosGranted');

      return (storageGranted || photosGranted || videosGranted)
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } else {
      debugPrint(
          'Non-Android platform detected, requesting storage permission');
      PermissionStatus status = await Permission.storage.request();
      debugPrint('Storage permission result: $status');
      return status;
    }
  }
}
