import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../service/CoverRecognitionService.dart';
import '../utils/CoverUtil.dart';
import '../utils/AppTheme.dart';
import '../utils/OcrImageCropUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';
import 'SongInfoPage.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';
import '../widgets/RankingUi.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 曲绘识别页面
/// 支持拍照/相册选取 → 手动裁剪 → 识别 → 显示Top10匹配结果
class CoverRecognitionPage extends StatefulWidget {
  const CoverRecognitionPage({super.key});

  @override
  State<CoverRecognitionPage> createState() => _CoverRecognitionPageState();
}

class _CoverRecognitionPageState extends State<CoverRecognitionPage> {
  final ImagePicker _picker = ImagePicker();
  final CoverRecognitionService _service = CoverRecognitionService.instance;

  bool _isInitializing = true;
  bool _isPrecomputing = false;
  int _precomputeCurrent = 0;
  int _precomputeTotal = 0;

  String? _photoPath;
  bool _isRecognizing = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _checkHashCache();
  }

  Future<void> _checkHashCache() async {
    final valid = await _service.isHashCacheValid();
    if (mounted) {
      setState(() => _isInitializing = false);
      if (!valid) _startPrecompute();
    }
  }

  Future<void> _startPrecompute() async {
    setState(() {
      _isPrecomputing = true;
      _precomputeCurrent = 0;
      _precomputeTotal = 0;
    });
    try {
      await _service.precomputeHashes(
        onProgress: (current, total) {
          if (mounted)
            setState(() {
              _precomputeCurrent = current;
              _precomputeTotal = total;
            });
        },
      );
      if (mounted) {
        setState(() => _isPrecomputing = false);
        AppToast.show(context.l10n.flowCoverIndexReadyProcessedP0Covers(
            (_precomputeTotal).toString()));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrecomputing = false);
        AppToast.show(context.l10n.flowCouldNotBuildIndexP0((e).toString()),
            tone: AppToastTone.error);
      }
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.flowChooseImageSource,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: Text(context.l10n.flowTakePhoto),
              subtitle: Text(context.l10n.flowPhotographCoverArt),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title: Text(context.l10n.chooseFromGallery),
              subtitle:
                  Text(context.l10n.flowChooseACoverScreenshotFromYourGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          AppToast.show(context.l10n.flowCameraPermissionRequired);
          openAppSettings();
        }
        return;
      }
    }
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      if (photo != null && mounted) {
        // 打开裁剪页面
        final cropped = await Navigator.push<String>(
          context,
          MaterialPageRoute(
              builder: (_) => _ImageCropPage(imagePath: photo.path)),
        );
        if (cropped != null && mounted) {
          setState(() {
            _photoPath = cropped;
            _result = null;
          });
        } else if (mounted) {
          // 用户取消裁剪，仍然使用原图
          setState(() {
            _photoPath = photo.path;
            _result = null;
          });
        }
      }
    } catch (e) {
      AppToast.show(context.l10n.flowCouldNotSelectImageP0((e).toString()),
          tone: AppToastTone.error);
    }
  }

  Future<void> _recognize() async {
    if (_photoPath == null) return;
    setState(() => _isRecognizing = true);
    try {
      final result = await _service.recognizeCover(_photoPath!);
      if (mounted) {
        setState(() {
          _result = result;
          _isRecognizing = false;
        });
        if (result == null)
          AppToast.show(context.l10n.flowRecognitionFailedTryAgain,
              tone: AppToastTone.error);
      }
    } catch (e) {
      if (mounted) setState(() => _isRecognizing = false);
      AppToast.show(context.l10n.flowRecognitionErrorP0((e).toString()),
          tone: AppToastTone.error);
    }
  }

  void _reset() => setState(() {
        _photoPath = null;
        _result = null;
      });

  Future<void> _rebuildIndex() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(context.l10n.flowRebuildCoverIndex),
        content: Text(context.l10n.flowThisClearsTheIndexAndRecalculatesHashes),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.featureCancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.flowRebuild)),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.clearCache();
      await _startPrecompute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final c = Theme.of(context).colorScheme.onSurface;
    return BackgroundPageScaffold(
      title: context.l10n.featureCoverRecognition,
      resizeToAvoidBottomInset: false,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 10),
      child: _buildContent(sw, c),
    );
  }

  // 顶部栏统一走公共组件（标题样式对齐 Rating 排行榜页的 AppBar）
  Widget _buildContent(double sw, Color c) {
    if (_isPrecomputing) return _buildPrecomputeProgress(sw, c);
    if (_isInitializing) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(context.l10n.flowLoading3,
            style: TextStyle(color: c, fontSize: sw * 0.04)),
      ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
          AppDesignTokens.gutter, AppDesignTokens.gutter),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (_result != null) ...[
          _buildTopMatch(sw, c),
          const SizedBox(height: AppDesignTokens.cardGap),
          _buildTop10List(sw, c),
          const SizedBox(height: 16),
          _buildActionButtons(sw, c),
        ] else if (_photoPath != null) ...[
          _buildPhotoPreview(sw, c),
          const SizedBox(height: 16),
          _buildActionButtons(sw, c),
        ] else ...[
          _buildPhotoGuide(sw, c),
          const SizedBox(height: 16),
          _buildActionButtons(sw, c),
        ],
        const SizedBox(height: 12),
        _buildCacheInfo(sw, c),
      ]),
    );
  }

  Widget _buildPrecomputeProgress(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    final p =
        _precomputeTotal > 0 ? _precomputeCurrent / _precomputeTotal : 0.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.gutter),
        child: AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.image_search, size: 44, color: scheme.primary),
              const SizedBox(height: 14),
              Text(context.l10n.flowBuildingCoverIndex,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  context.l10n.flowComputingFeaturesForP0Covers(
                      (_precomputeTotal).toString()),
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 14),
              SmoothLinearProgressIndicator(
                  value: p,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: AppSurfaces.inset(context),
                  color: scheme.primary),
              const SizedBox(height: 8),
              Text('$_precomputeCurrent / $_precomputeTotal',
                  textAlign: TextAlign.center,
                  style: AppTheme.number(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 4),
              Text(context.l10n.flowNeededOnlyOncePleaseWait,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGuide(double sw, Color c) => RecognitionGuideCard(
        icon: Icons.image_search,
        title: context.l10n.flowTakeOrChooseACoverImage,
        description: context.l10n.flowCropTheCoverRegionAfterSelectingFor,
        steps: [
          context.l10n.flowTakeAPhotoOrChooseAnImage,
          context.l10n.flowCropTheCoverArtInTheImage,
          context.l10n.flowRecognizeAndViewTheClosestSongs
        ],
      );

  Widget _buildPhotoPreview(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
              child: Image.file(
                File(_photoPath!),
                fit: BoxFit.cover,
                cacheWidth: 1080,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(context.l10n.flowImageReady,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  /// 相似度 → 颜色：高绿、中橙、低红。
  Color _similarityColor(double sim, {double high = 80, double mid = 60}) {
    final brightness = Theme.of(context).brightness;
    return sim >= high
        ? AppColors.successGreen(brightness)
        : sim >= mid
            ? AppColors.warningOrange(brightness)
            : AppColors.errorRed(brightness);
  }

  Widget _buildTopMatch(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    final songId = _result!['songId'] as String? ?? '';
    final sim = _result!['similarity'] as double? ?? 0;
    final hashSim = _result!['hashSimilarity'] as double? ?? 0;
    final colorSim = _result!['colorSimilarity'] as double? ?? 0;
    final title = _result!['songTitle'] as String? ?? '';
    final artist = _result!['artist'] as String? ?? '';
    final lowConf = _result!['lowConfidence'] as bool? ?? false;
    final brightness = Theme.of(context).brightness;
    final mc = _similarityColor(sim);
    // 页边距 + 卡片内边距 + 中间箭头之后，两张图平分剩下的宽度
    final imageSize = (sw - 2 * AppDesignTokens.gutter - 2 * 14 - 36) / 2;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 低置信度警告
          if (lowConf)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorRed(brightness).withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber,
                    color: AppColors.errorRed(brightness), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.l10n.flowMatchConfidenceIsTooLowThisMay,
                      style: TextStyle(
                          color: AppColors.errorRed(brightness), fontSize: 12)),
                ),
              ]),
            ),

          // 左右对比：用户输入 vs 匹配曲绘
          Row(
            children: [
              // 左侧：用户输入图片
              _buildSideImage(
                size: imageSize,
                label: context.l10n.flowInputImage,
                image: _photoPath != null
                    ? Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: AppSurfaces.inset(context),
                          child: Center(
                            child: Icon(Icons.broken_image,
                                size: 32, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(
                width: 36,
                child: Icon(Icons.arrow_forward_rounded, color: mc, size: 22),
              ),
              // 右侧：匹配曲绘
              // ⚠️ 不能用 AssetImage(CoverUtil.buildCoverPath(songId))：那是**原始 id**
              // 的路径，5 位（DX 条目，如 11312 / 10030）与 6 位（宴会场）的曲绘资源
              // 名字是剔除后的 id（1312.webp / 1634.webp），直读必然 errorBuilder
              // —— 表现就是「识别结果里的曲绘不显示」。统一走 CoverUtil 的多级兜底。
              _buildSideImage(
                size: imageSize,
                label: context.l10n.flowMatchedCover,
                image: CoverUtil.buildCoverWidget(songId, imageSize),
                borderColor: mc,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 曲名
          Text(title,
              style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          if (artist.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(artist,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          // 综合匹配
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${sim.toStringAsFixed(2)}%',
                  style: AppTheme.number(
                      fontSize: 28, fontWeight: FontWeight.w800, color: mc)),
              const SizedBox(width: 8),
              Text(
                  lowConf
                      ? context.l10n.flowCombinedMatchUnreliable
                      : context.l10n.flowCombinedMatch,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          // 纹理相似度 + 颜色相似度 分解
          _buildSimRow(context.l10n.flowTexture, hashSim),
          const SizedBox(height: 6),
          _buildSimRow(context.l10n.flowColor, colorSim),
        ],
      ),
    );
  }

  Widget _buildSimRow(String label, double value) {
    final scheme = Theme.of(context).colorScheme;
    final color = _similarityColor(value, mid: 55);
    return Row(children: [
      SizedBox(
        width: 32,
        child: Text(label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ),
      Expanded(
        child: SmoothLinearProgressIndicator(
          value: (value / 100).clamp(0.0, 1.0).toDouble(),
          minHeight: 6,
          color: color,
          backgroundColor: AppSurfaces.inset(context),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Text('${value.toStringAsFixed(2)}%',
          style: AppTheme.number(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  /// 左右对比里的一格。
  ///
  /// 直接收一个 [image]（而不是 ImageProvider）：曲绘那一格交给
  /// `CoverUtil.buildCoverWidget` 走多级兜底链，它返回的是 Widget ——
  /// 用 provider 就没法落地「本地路径规则 + 网络兜底」了。
  Widget _buildSideImage({
    required double size,
    required String label,
    required Widget? image,
    Color? borderColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDesignTokens.radiusMedium);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(fit: StackFit.expand, children: [
              image ??
                  ColoredBox(
                      color: AppSurfaces.inset(context),
                      child: Center(
                          child: Icon(Icons.image,
                              size: 32, color: scheme.onSurfaceVariant))),
              if (borderColor != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 2.5),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildTop10List(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    final matches = (_result!['topMatches'] as List<dynamic>?) ?? [];
    if (matches.isEmpty) return const SizedBox.shrink();

    // 过滤掉无歌名的条目（如"歌曲 #xxx"），让后续顺延
    final namedMatches = matches.where((m) {
      final title = (m as Map<String, dynamic>)['songTitle'] as String? ?? '';
      return title.isNotEmpty && !title.startsWith('歌曲 #');
    }).toList();

    // 去重：同一首歌（DX/ST/UTAGE）共用曲绘，只保留相似度最高的那条
    final seenTitles = <String>{};
    final validMatches = namedMatches
        .where((m) {
          final title =
              (m as Map<String, dynamic>)['songTitle'] as String? ?? '';
          return seenTitles.add(title); // add 返回 true 表示首次出现
        })
        .take(10)
        .toList(); // 截取前10条，确保过滤/去重后始终显示10个
    if (validMatches.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppSectionHeader(
          title: context.l10n.flowTop10Matches,
          padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
        ),
        ...validMatches.asMap().entries.map((e) {
          final m = e.value as Map<String, dynamic>;
          final sid = m['songId'] as String? ?? '';
          final sim = m['similarity'] as double? ?? 0;
          final title = m['songTitle'] as String? ?? '';
          final artist = m['artist'] as String? ?? '';
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SongInfoPage(songId: sid),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppSurfaces.hairline(context))),
              ),
              child: Row(children: [
                SizedBox(
                    width: 32,
                    child: Center(child: RankingMedal(rank: e.key + 1))),
                const SizedBox(width: 6),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                  // ⚠️ 原来直接 Image.asset(CoverUtil.buildCoverPath(sid))：
                  // 那是**原始 id** 的路径，5 位（DX 条目，如 11312 / 10030）与
                  // 6 位（宴会场）的曲绘资源名是剔除后的 id（1312.webp / 1634.webp），
                  // 直读必然失败 → Top10 里部分曲绘显示成裂图。
                  // 统一走 CoverUtil 的多级兜底（本地规则 + 网络 + dxrating）。
                  child: CoverUtil.buildCoverWidget(sid, 44),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MarqueeText(
                        text: title.isNotEmpty
                            ? title
                            : context.l10n.flowSongP0((sid).toString()),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface),
                      ),
                      if (artist.isNotEmpty)
                        MarqueeText(
                          text: artist,
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${sim.toStringAsFixed(2)}%',
                    style: AppTheme.number(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sim >= 60
                            ? _similarityColor(sim)
                            : scheme.onSurfaceVariant)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildActionButtons(double sw, Color c) {
    final Widget content;
    if (_photoPath == null) {
      content = FilledButton.icon(
        onPressed: _showSourcePicker,
        icon: const Icon(Icons.add_a_photo),
        label: Text(context.l10n.flowChooseImage),
      );
    } else if (_result == null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _isRecognizing ? null : _recognize,
            icon: _isRecognizing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isRecognizing
                ? context.l10n.flowRecognizing
                : context.l10n.flowStartRecognition),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    if (_photoPath == null) return;
                    final cropped = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                _ImageCropPage(imagePath: _photoPath!)));
                    if (cropped != null && mounted)
                      setState(() {
                        _photoPath = cropped;
                        _result = null;
                      });
                  },
                  icon: const Icon(Icons.crop),
                  label: Text(context.l10n.flowCropAgain),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.flowChooseAgain),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.flowRecognizeAgain),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.add_a_photo),
              label: Text(context.l10n.flowChooseAnother),
            ),
          ),
        ],
      );
    }
    return SizedBox(width: double.infinity, child: content);
  }

  Widget _buildCacheInfo(double sw, Color c) => FutureBuilder<bool>(
        future: _service.isHashCacheValid(),
        builder: (_, snap) {
          final brightness = Theme.of(context).brightness;
          final ok = snap.data ?? false;
          return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ok ? Icons.check_circle_outline : Icons.info_outline,
                size: 14,
                color: ok
                    ? AppColors.successGreen(brightness)
                    : AppColors.warningOrange(brightness)),
            const SizedBox(width: 4),
            Text(
                ok
                    ? context.l10n.flowCoverIndexReady
                    : context.l10n.flowIndexNotBuilt,
                style: TextStyle(
                    fontSize: 11,
                    color: ok
                        ? AppColors.successGreen(brightness)
                        : AppColors.warningOrange(brightness))),
            if (ok) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _rebuildIndex,
                child: Text(context.l10n.flowRebuildIndex,
                    style: TextStyle(
                        fontSize: 11,
                        color: c.withValues(alpha: 0.6),
                        decoration: TextDecoration.underline)),
              ),
            ],
          ]);
        },
      );
}

// ────────────────────────────────────────────────────────
// 手动裁剪页面
// ────────────────────────────────────────────────────────

/// 裁剪框的拖拽手柄类型
enum _Handle { none, body, topLeft, topRight, bottomLeft, bottomRight }

/// 全屏手动裁剪页面
class _ImageCropPage extends StatefulWidget {
  final String imagePath;
  const _ImageCropPage({required this.imagePath});

  @override
  State<_ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<_ImageCropPage> {
  ui.Image? _image;
  bool _loading = true;
  bool _cropping = false;

  // 图片在屏幕上的显示区域（BoxFit.contain 后的实际区域）
  Rect _imageRect = Rect.zero;

  // 裁剪框（相对于 _imageRect）
  Rect _cropRect = Rect.zero;

  // 拖拽状态
  _Handle _activeHandle = _Handle.none;
  Offset? _dragStart;
  Rect? _cropRectStart;

  final double _handleSize = 24;
  final double _minCropSize = 50;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // 裁剪使用已经限制到 2048px 的预览图，避免再次把相机原图全尺寸解码。
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 2048);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = frame.image;
        _loading = false;
      });
    } catch (e) {
      debugPrint('曲绘裁剪页加载图片失败: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(context.l10n.flowCannotReadThisImageTryAnother,
          tone: AppToastTone.error);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// 计算 BoxFit.contain 后图片在容器中的实际区域
  Rect _calcImageRect(Size container) {
    if (_image == null) return Rect.zero;
    final iw = _image!.width.toDouble();
    final ih = _image!.height.toDouble();
    final scale = (container.width / iw) < (container.height / ih)
        ? container.width / iw
        : container.height / ih;
    final dw = iw * scale;
    final dh = ih * scale;
    final dx = (container.width - dw) / 2;
    final dy = (container.height - dh) / 2;
    return Rect.fromLTWH(dx, dy, dw, dh);
  }

  /// 初始化裁剪框（正方形，取较长边的70%）
  void _initCropRect() {
    final size = math.min(_imageRect.width, _imageRect.height) * 0.7;
    setState(() {
      _cropRect = Rect.fromLTWH(
        _imageRect.left + (_imageRect.width - size) / 2,
        _imageRect.top + (_imageRect.height - size) / 2,
        size,
        size,
      );
    });
  }

  Rect _clampCropRect(Rect rect, Rect imageRect) {
    final maxSize = math.min(imageRect.width, imageRect.height);
    if (maxSize <= 0) return Rect.zero;
    final minSize = math.min(_minCropSize, maxSize);
    final size = rect.width.clamp(minSize, maxSize).toDouble();
    final maxLeft = math.max(imageRect.left, imageRect.right - size);
    final maxTop = math.max(imageRect.top, imageRect.bottom - size);
    final left = rect.left.clamp(imageRect.left, maxLeft).toDouble();
    final top = rect.top.clamp(imageRect.top, maxTop).toDouble();
    return Rect.fromLTWH(left, top, size, size);
  }

  /// 获取指定手柄的光标样式
  MouseCursor _cursorForHandle(_Handle h) => switch (h) {
        _Handle.topLeft ||
        _Handle.bottomRight =>
          SystemMouseCursors.resizeUpLeftDownRight,
        _Handle.topRight ||
        _Handle.bottomLeft =>
          SystemMouseCursors.resizeUpRightDownLeft,
        _Handle.body => SystemMouseCursors.move,
        _ => SystemMouseCursors.basic,
      };

  _Handle _hitTest(Offset p) {
    const r = 20.0; // 触摸容差
    if ((p - _cropRect.topLeft).distance < r) return _Handle.topLeft;
    if ((p - _cropRect.topRight).distance < r) return _Handle.topRight;
    if ((p - _cropRect.bottomLeft).distance < r) return _Handle.bottomLeft;
    if ((p - _cropRect.bottomRight).distance < r) return _Handle.bottomRight;
    if (_cropRect.contains(p)) return _Handle.body;
    return _Handle.none;
  }

  void _onPanStart(DragStartDetails d) {
    _activeHandle = _hitTest(d.localPosition);
    _dragStart = d.localPosition;
    _cropRectStart = _cropRect;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_activeHandle == _Handle.none ||
        _cropRectStart == null ||
        _dragStart == null) return;

    final delta = d.localPosition - _dragStart!;
    final r = _cropRectStart!;
    final minSize = math.min(
      _minCropSize,
      math.min(_imageRect.width, _imageRect.height),
    );
    if (minSize <= 0) return;
    Rect newRect;

    switch (_activeHandle) {
      case _Handle.body:
        var dx = r.left + delta.dx;
        var dy = r.top + delta.dy;
        if (dx < _imageRect.left) dx = _imageRect.left;
        if (dy < _imageRect.top) dy = _imageRect.top;
        if (dx + r.width > _imageRect.right) dx = _imageRect.right - r.width;
        if (dy + r.height > _imageRect.bottom)
          dy = _imageRect.bottom - r.height;
        newRect = Rect.fromLTWH(dx, dy, r.width, r.height);

      case _Handle.topLeft:
        // 锚点：右下角；正方形缩放
        final maxDelta =
            math.max(r.width - delta.dx, r.height - delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              r.right - _imageRect.left,
              r.bottom - _imageRect.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          (r.right - size).clamp(_imageRect.left, _imageRect.right - minSize),
          (r.bottom - size).clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );

      case _Handle.topRight:
        final maxDelta =
            math.max(r.width + delta.dx, r.height - delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              _imageRect.right - r.left,
              r.bottom - _imageRect.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          r.left.clamp(_imageRect.left, _imageRect.right - minSize),
          (r.bottom - size).clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );

      case _Handle.bottomLeft:
        final maxDelta =
            math.max(r.width - delta.dx, r.height + delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              r.right - _imageRect.left,
              _imageRect.bottom - r.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          (r.right - size).clamp(_imageRect.left, _imageRect.right - minSize),
          r.top.clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );

      case _Handle.bottomRight:
        final maxDelta =
            math.max(r.width + delta.dx, r.height + delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              _imageRect.right - r.left,
              _imageRect.bottom - r.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          r.left.clamp(_imageRect.left, _imageRect.right - minSize),
          r.top.clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );

      case _Handle.none:
        return;
    }

    setState(() => _cropRect = newRect);
  }

  void _onPanEnd(DragEndDetails d) {
    _activeHandle = _Handle.none;
    _dragStart = null;
    _cropRectStart = null;
  }

  /// 执行裁剪
  Future<String?> _doCrop() async {
    if (_image == null || _imageRect.isEmpty || _cropRect.isEmpty) {
      return widget.imagePath;
    }
    try {
      final crop = _cropRect.intersect(_imageRect);
      if (crop.isEmpty || crop.width <= 0 || crop.height <= 0) {
        return widget.imagePath;
      }
      final bytes = await File(widget.imagePath).readAsBytes();
      final encoded = await OcrImageCropUtil.cropAndEncodeAsync(
        bytes: bytes,
        left: (crop.left - _imageRect.left) / _imageRect.width,
        top: (crop.top - _imageRect.top) / _imageRect.height,
        width: crop.width / _imageRect.width,
        height: crop.height / _imageRect.height,
      );
      if (encoded == null) {
        AppToast.show(context.l10n.flowCropFailedContinuingWithTheOriginalImage,
            tone: AppToastTone.error);
        return widget.imagePath;
      }
      final outPath =
          '${Directory.systemTemp.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(encoded, flush: true);
      return outPath;
    } catch (e) {
      debugPrint('裁剪出错: $e');
      AppToast.show(context.l10n.flowCropFailedContinuingWithTheOriginalImage,
          tone: AppToastTone.error);
      return widget.imagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _image == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          // 顶部工具栏
          Container(
            height: kToolbarHeight,
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                label: Text(context.l10n.featureCancel,
                    style: TextStyle(color: Colors.white)),
              ),
              const Spacer(),
              Text(context.l10n.flowDragTheCornersToSelectCoverArt,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  if (_cropping) return;
                  setState(() => _cropping = true);
                  final navigator = Navigator.of(context);
                  try {
                    final result = await _doCrop();
                    if (mounted) navigator.pop(result);
                  } finally {
                    if (mounted) setState(() => _cropping = false);
                  }
                },
                icon: const Icon(Icons.check, color: Colors.green, size: 20),
                label: Text(
                    _cropping
                        ? context.l10n.flowProcessing
                        : context.l10n.flowConfirm,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          // 图片 + 裁剪框（用 LayoutBuilder 取实际尺寸）
          Expanded(
            child: LayoutBuilder(builder: (ctx, imageConstraints) {
              final actualSize =
                  Size(imageConstraints.maxWidth, imageConstraints.maxHeight);
              _imageRect = _calcImageRect(actualSize);
              if (_imageRect.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              if (_cropRect.isEmpty || _cropRect == Rect.zero) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _initCropRect());
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              _cropRect = _clampCropRect(_cropRect, _imageRect);

              return GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: MouseRegion(
                  cursor: _activeHandle != _Handle.none
                      ? _cursorForHandle(_activeHandle)
                      : SystemMouseCursors.basic,
                  child: Stack(children: [
                    Positioned.fill(
                      child: RawImage(image: _image, fit: BoxFit.contain),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropOverlayPainter(
                          imageRect: _imageRect,
                          cropRect: _cropRect,
                          handleSize: _handleSize,
                          handleBorderColor:
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),

          // 底部提示
          Container(
            height: 48,
            color: Colors.black87,
            alignment: Alignment.center,
            child: Text(
              context.l10n.flowDragCornersToResizeDragInsideTo,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 裁剪遮罩绘制器
class _CropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;
  final double handleSize;
  final Color handleBorderColor;

  _CropOverlayPainter({
    required this.imageRect,
    required this.cropRect,
    required this.handleSize,
    required this.handleBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 半透明遮罩
    final mask = Paint()..color = Colors.black.withValues(alpha: 0.55);
    // 上
    canvas.drawRect(
        Rect.fromLTRB(
            imageRect.left, imageRect.top, imageRect.right, cropRect.top),
        mask);
    // 下
    canvas.drawRect(
        Rect.fromLTRB(
            imageRect.left, cropRect.bottom, imageRect.right, imageRect.bottom),
        mask);
    // 左
    canvas.drawRect(
        Rect.fromLTRB(
            imageRect.left, cropRect.top, cropRect.left, cropRect.bottom),
        mask);
    // 右
    canvas.drawRect(
        Rect.fromLTRB(
            cropRect.right, cropRect.top, imageRect.right, cropRect.bottom),
        mask);

    // 裁剪框边框
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, border);

    // 九宫格辅助线
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(cropRect.left + thirdW * i, cropRect.top),
          Offset(cropRect.left + thirdW * i, cropRect.bottom), grid);
      canvas.drawLine(Offset(cropRect.left, cropRect.top + thirdH * i),
          Offset(cropRect.right, cropRect.top + thirdH * i), grid);
    }

    // 四角手柄
    final handle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final corner in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ]) {
      final r = Rect.fromCenter(
          center: corner, width: handleSize, height: handleSize);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)), handle);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)), handleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) =>
      cropRect != old.cropRect || imageRect != old.imageRect;
}
