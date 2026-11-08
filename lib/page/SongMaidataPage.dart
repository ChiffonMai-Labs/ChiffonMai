import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/widgets/ExportSuccessDialog.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import '../utils/CoverUtil.dart';
import '../utils/AppTheme.dart';
import '../utils/ExportPathUtil.dart';
import '../service/SongMaidataPageService.dart';
import '../service/DxRatingCoverService.dart';
import '../service/SongMediaCache.dart';
import '../api/ApiUrls.dart';
import '../service/ChartPlaySettingsStore.dart';
import '../manager/MaidataManager.dart';
import '../widgets/BackgroundPageScaffold.dart';
import 'ChartPlayPage.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../utils/ChartCodeFontPreference.dart';

class SongMaidataPage extends StatefulWidget {
  final String songId;
  final String songTitle;
  final String genre;
  final String songType;
  final int difficultyIndex;

  const SongMaidataPage({
    super.key,
    required this.songId,
    required this.songTitle,
    required this.genre,
    required this.songType,
    required this.difficultyIndex,
  });

  @override
  State<SongMaidataPage> createState() => _SongMaidataPageState();
}

class _SongMaidataPageState extends State<SongMaidataPage> {
  bool _isLoading = true;
  bool _isExporting = false;
  String _maidataContent = '';
  String? _errorMessage;
  List<String> _inoteList = [];
  String? _selectedInote;
  String? _displayedInote; // 当前显示的难度
  bool _loadAudio = true;

  /// 公开目录不可写时，记录实际落盘的私有路径，用于在成功弹窗里提示用户
  String? _fallbackPath;
  final ScrollController _scrollController = ScrollController();

  late SongMaidataPageService _service;

  @override
  void initState() {
    super.initState();
    _service = SongMaidataPageService(
      songId: widget.songId,
      songTitle: widget.songTitle,
      genre: widget.genre,
      songType: widget.songType,
    );
    _loadAudioPreference();
    _loadCodeFont();
    _loadMaidata();
  }

  /// 记住的谱面代码字体；读取完成前先用默认字体。
  ChartCodeFont _codeFont = ChartCodeFont.standard;

  Future<void> _loadCodeFont() async {
    final font = await ChartCodeFontPreference.load();
    if (mounted) setState(() => _codeFont = font);
  }

  Future<void> _chooseCodeFont() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDialog<ChartCodeFont>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(ctx.l10n.chartCodeFont),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final font in ChartCodeFont.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppDialogOption(
                  title: font == ChartCodeFont.standard
                      ? ctx.l10n.chartCodeFontDefault
                      : 'Inconsolata',
                  // 选项标题用对应字体预览效果。
                  titleWidget: Text(
                    font == ChartCodeFont.standard
                        ? ctx.l10n.chartCodeFontDefault
                        : 'Inconsolata',
                    style: font.apply(const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ),
                  selected: font == _codeFont,
                  leading: Icon(font == _codeFont
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded),
                  onTap: () => Navigator.pop(ctx, font),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.featureCancel)),
        ],
      ),
    );
    if (picked == null || !mounted || picked == _codeFont) return;
    setState(() => _codeFont = picked);
    if (!await ChartCodeFontPreference.save(picked) && mounted) {
      AppToast.show(context.l10n.chartCodeFontSaveFailed,
          tone: AppToastTone.warning);
    }
  }

  Future<void> _loadAudioPreference() async {
    final value = await ChartPlayAudioPreference.load();
    if (mounted) setState(() => _loadAudio = value);
  }

  Future<void> _loadMaidata() async {
    // 单曲页面按需读取，不因缺少全量缓存而先下载整个谱面库。
    await MaidataManager().initialize();
    if (!mounted) return;
    await _fetchMaidata();
  }

  Future<void> _fetchMaidata() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? content = await _service.fetchMaidata(
        onInoteParsed: (inoteList) {
          if (!mounted) return;
          setState(() {
            _inoteList = inoteList;
            _selectedInote = null;
          });
        },
      );

      if (!mounted) return;
      if (content != null) {
        setState(() {
          _maidataContent = content;
        });
      } else {
        setState(() {
          _errorMessage = appL10n.flowNoMatchingChartCodeFound;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = appL10n.flowCouldNotFetchChartCodeP0((e).toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_maidataContent.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _maidataContent));

    AppToast.show(context.l10n.flowCopiedToClipboard,
        tone: AppToastTone.success);
  }

  /// 谱面导出：先让用户选目标格式
  Future<void> _showExportOptions() async {
    if (_maidataContent.isEmpty || _isExporting) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: Text(context.l10n.flowExportZIPZip),
              subtitle: Text(context.l10n.flowMaidataTxtCoverArtAndAudioIn),
              onTap: () => Navigator.of(ctx).pop('zip'),
            ),
            ListTile(
              leading: const Icon(Icons.sports_esports_outlined),
              title: Text(context.l10n.flowExportAstroDXChartAdx),
              subtitle: Text(context.l10n.flowOpenInAstroDXToInstallTheChart),
              onTap: () => Navigator.of(ctx).pop('adx'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;
    if (choice == 'zip') {
      await _exportToZip();
    } else if (choice == 'adx') {
      await _exportAstroDx();
    }
  }

  /// 收集谱面三件套：maidata 文本、曲绘、音源
  Future<_ChartExportAssets> _collectExportAssets() async {
    // 必须用 utf8.encode，不能用 codeUnits。
    // codeUnits 返回的是 UTF-16 码元，日文/中文标题会被写成乱码字节，
    // 导出的 maidata.txt 到别的工具里就是一堆问号。
    final maidataBytes = Uint8List.fromList(utf8.encode(_maidataContent));
    final rawCoverBytes = await _getCoverBytes();
    // 本地曲绘资源通常是 WebP，网络兜底也可能返回 PNG/JPEG。
    // 导出文件名固定为 bg.jpg 时必须同步转码，否则只是改后缀，
    // AstroDX 和文件管理器会按 JPEG 解码失败。
    final coverBytes =
        rawCoverBytes == null ? null : _encodeCoverAsJpeg(rawCoverBytes);
    final audioBytes = await _getAudioBytes();
    return _ChartExportAssets(
      maidataBytes: maidataBytes,
      coverBytes: coverBytes,
      audioBytes: audioBytes,
    );
  }

  /// 导出通用 zip 压缩包（三件套平铺在压缩包根目录）
  Future<void> _exportToZip() async {
    if (_maidataContent.isEmpty || _isExporting) return;
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '谱面',
        title: context.l10n.flowChooseWhereToSaveTheChartPackage)) {
      return;
    }
    await _runExport(() async {
      final assets = await _collectExportAssets();

      final archive = Archive();
      archive.add(ArchiveFile.bytes('maidata.txt', assets.maidataBytes));
      if (assets.coverBytes != null) {
        archive.add(ArchiveFile.bytes('bg.jpg', assets.coverBytes!));
      }
      if (assets.audioBytes != null) {
        archive.add(ArchiveFile.bytes('track.mp3', assets.audioBytes!));
      }

      final zipData = ZipEncoder().encode(archive);
      final safeName =
          ExportPathUtil.sanitizeFileName(widget.songTitle, fallback: 'chart');
      final file = await ExportPathUtil.writeExportFile(
        fileName: '$safeName.zip',
        bytes: zipData,
        subDir: '谱面',
        onFallback: (p) => _fallbackPath = p,
      );
      return (file.path, '$safeName.zip', assets.missingHint);
    });
  }

  /// 导出 AstroDX 谱面包（.adx）
  ///
  /// `.adx` 本质就是「改了后缀的 zip」：AstroDX 会扫描压缩包内容，
  /// 找到包含 maidata.txt 的谱面文件夹后自动安装。
  /// 因此三件套必须套在一层以曲名命名的文件夹里，
  /// 而不能像通用 zip 那样平铺在压缩包根目录。
  Future<void> _exportAstroDx() async {
    if (_maidataContent.isEmpty || _isExporting) return;
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '谱面',
        title: context.l10n.flowChooseWhereToSaveTheAstroDXChart)) {
      return;
    }
    await _runExport(() async {
      final assets = await _collectExportAssets();
      final safeName =
          ExportPathUtil.sanitizeFileName(widget.songTitle, fallback: 'chart');

      final archive = Archive();
      archive
          .add(ArchiveFile.bytes('$safeName/maidata.txt', assets.maidataBytes));
      if (assets.coverBytes != null) {
        archive.add(ArchiveFile.bytes('$safeName/bg.jpg', assets.coverBytes!));
      }
      if (assets.audioBytes != null) {
        archive
            .add(ArchiveFile.bytes('$safeName/track.mp3', assets.audioBytes!));
      }

      final zipData = ZipEncoder().encode(archive);
      final file = await ExportPathUtil.writeExportFile(
        fileName: '$safeName.adx',
        bytes: zipData,
        subDir: '谱面',
        onFallback: (p) => _fallbackPath = p,
      );
      return (file.path, '$safeName.adx', assets.missingHint);
    });
  }

  /// 统一的导出流程：进度弹窗 → 执行 → 成功/失败提示
  Future<void> _runExport(
    Future<(String path, String fileName, String? warning)> Function() job,
  ) async {
    setState(() => _isExporting = true);
    _fallbackPath = null;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AppAlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(context.l10n.flowExporting2),
            ],
          ),
        ),
      );
    }

    try {
      final (path, fileName, warning) = await job();

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        await _showExportSuccessDialog(path, fileName, warning: warning);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        AppToast.show(context.l10n.flowExportFailedP0((e).toString()),
            tone: AppToastTone.error, duration: const Duration(seconds: 3));
      }
      debugPrint('[DEBUG][SongMaidataPage] 导出失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  /// 显示导出成功对话框：展示导出路径并提供复制按钮
  Future<void> _showExportSuccessDialog(
    String filePath,
    String fileName, {
    String? warning,
  }) {
    return showExportSuccessDialog(
      context,
      filePath: filePath,
      fileName: fileName,
      fallbackPath: _fallbackPath,
      warning: warning,
    );
  }

  /// 获取曲绘字节数据（优先本地资源，兜底网络下载）
  Future<Uint8List?> _getCoverBytes() async {
    final songId = widget.songId;

    // 尝试从本地assets加载（依次尝试多种路径）
    final coverPaths = [
      CoverUtil.buildCoverPath(songId),
      CoverUtil.getLocalCoverPath(songId),
      CoverUtil.getLocalCoverPathRetry1(songId),
      CoverUtil.getLocalCoverPathRetry2(songId),
    ];

    for (final path in coverPaths) {
      try {
        final byteData = await rootBundle.load(path);
        return byteData.buffer.asUint8List();
      } catch (_) {
        // 当前路径失败，尝试下一个
      }
    }

    // 本地加载失败，从网络下载
    try {
      final networkUrl = CoverUtil.getNetworkCoverUrl(songId);
      debugPrint('[DEBUG][SongMaidataPage] 从网络获取曲绘: $networkUrl');
      final response = await ApiClient.get(Uri.parse(networkUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[DEBUG][SongMaidataPage] 网络获取曲绘失败: $e');
    }

    // 新增兜底：dxrating（shama）曲绘 —— 拿 dxdata 的 imageName 换图
    // （水鱼的 DX 条目 id = 10000 + 基础 id，上面那条 URL 规则会 404，只能靠这里）
    try {
      // 索引通常是现成的（本地缓存）；万一还没建好，最多等 3 秒，
      // 超时就让后台继续补，本次仍按「没有曲绘」处理，别卡住导出
      await DxRatingCoverService.instance
          .ensureLoaded()
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      final dxUrl = DxRatingCoverService.instance.coverUrlFor(songId);
      if (dxUrl != null) {
        debugPrint('[DEBUG][SongMaidataPage] 从 dxrating 获取曲绘: $dxUrl');
        final response = await ApiClient.get(Uri.parse(dxUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      }
    } catch (e) {
      debugPrint('[DEBUG][SongMaidataPage] dxrating 曲绘获取失败: $e');
    }

    return null;
  }

  /// 将任意支持的曲绘格式统一编码为 JPEG，确保导出内容与 `bg.jpg` 扩展名一致。
  Uint8List? _encodeCoverAsJpeg(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('[DEBUG][SongMaidataPage] 曲绘无法解码，跳过导出');
        return null;
      }
      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (e) {
      debugPrint('[DEBUG][SongMaidataPage] 曲绘转 JPEG 失败，跳过导出: $e');
      return null;
    }
  }

  /// 获取音源字节数据
  Future<Uint8List?> _getAudioBytes() async {
    try {
      final id = SongMediaCache.audioIdFor(widget.songId);
      final file =
          await SongMediaCache.instance.ensureAudio(widget.songId, urls: [
        if (id > 0) 'https://assets2.lxns.net/maimai/music/$id.mp3',
        ApiUrls.wmcAudioUrl(widget.songId),
      ]);
      return await file.readAsBytes();
    } catch (error) {
      debugPrint('导出谱面包时准备音源失败: $error');
      return null;
    }
  }

  void _navigateToChartPlay() {
    _showDifficultySelector();
  }

  void _showDifficultySelector() {
    if (_inoteList.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChartPlayPage(
            maidataContent: _maidataContent,
            songTitle: widget.songTitle,
            songId: widget.songId,
            songType: widget.songType,
            selectedInote: null,
            loadAudio: _loadAudio,
          ),
        ),
      );
      return;
    }

    var loadAudio = _loadAudio;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectDifficulty),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    context.l10n.flowRenderedChartsAreForReferenceAndMay,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setDialogState) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: loadAudio,
                    title: Text(context.l10n.flowLoadAudio),
                    subtitle:
                        Text(context.l10n.flowTurnOffToLoadTheChartWithout),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => loadAudio = value);
                      _loadAudio = value;
                      ChartPlayAudioPreference.save(value);
                    },
                  ),
                ),
                ..._inoteList.map((inote) {
                  String difficultyName = _getInoteDifficulty(inote);
                  Color inoteColor = _getInoteColor(inote);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChartPlayPage(
                              maidataContent: _maidataContent,
                              songTitle: widget.songTitle,
                              songId: widget.songId,
                              songType: widget.songType,
                              selectedInote: inote,
                              loadAudio: loadAudio,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inoteColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: AppTheme.font(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                      ),
                      child: Text(difficultyName),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInoteDifficulty(String inoteNum) {
    if (widget.genre == '宴会場' ||
        widget.songType == 'UTAGE' ||
        (widget.songId.length == 6 && int.tryParse(widget.songId) != null)) {
      final index = _inoteList.indexOf(inoteNum);
      return _inoteList.length > 1 && index >= 0
          ? '${ChartDifficulty.utageLabel} ${index + 1}'
          : ChartDifficulty.utageLabel;
    }
    return SongMaidataPageService.inoteDifficultyMap[inoteNum] ?? inoteNum;
  }

  Color _getInoteColor(String inoteNum) {
    if (widget.genre == '宴会場' ||
        widget.songType == 'UTAGE' ||
        (widget.songId.length == 6 && int.tryParse(widget.songId) != null))
      return AppColors.utageAccent(brightness: Theme.of(context).brightness);
    int colorValue =
        SongMaidataPageService.inoteColorMap[inoteNum] ?? 0xFF9E9E9E;
    return Color(colorValue);
  }

  void _scrollToInote(String inoteNum) {
    setState(() {
      _selectedInote = inoteNum;
      // ALL选项显示全部内容，其他选项显示对应难度
      _displayedInote = inoteNum == 'ALL' ? null : inoteNum;
    });

    // 切换难度时自动滚动到最顶端
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // 提取单个难度的maidata内容
  String _getFilteredMaidata() {
    if (_displayedInote == null || _maidataContent.isEmpty) {
      return _maidataContent;
    }

    String targetInote = '&inote_${_displayedInote}';
    String nextInote = '';

    // 找到下一个难度的起始位置
    for (String inote in _inoteList) {
      if (inote != _displayedInote) {
        String candidate = '&inote_$inote';
        int targetIndex = _maidataContent.indexOf(targetInote);
        int candidateIndex = _maidataContent.indexOf(candidate);

        if (candidateIndex > targetIndex) {
          if (nextInote.isEmpty ||
              candidateIndex < _maidataContent.indexOf('&inote_$nextInote')) {
            nextInote = inote;
          }
        }
      }
    }

    int startIndex = _maidataContent.indexOf(targetInote);
    if (startIndex == -1) {
      return _maidataContent;
    }

    int endIndex = nextInote.isEmpty
        ? _maidataContent.length
        : _maidataContent.indexOf('&inote_$nextInote');

    if (endIndex == -1) {
      endIndex = _maidataContent.length;
    }

    return _maidataContent.substring(startIndex, endIndex);
  }

  Widget _buildDsDisplay() {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<String>>(
      future: _service.getSongDsList(),
      builder: (context, snapshot) {
        return Text(
          snapshot.hasData
              ? snapshot.data!.join(' / ')
              : context.l10n.flowFetchingChartConstants,
          style: AppTheme.number(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  /// 难度切换胶囊：选中时填充该难度的颜色。
  Widget _buildInotePill(String inote, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterPill(
        label: label,
        selected: _selectedInote == inote,
        selectedColor: color,
        selectedForeground:
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                ? Colors.white
                : Colors.black87,
        onTap: () => _scrollToInote(inote),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, widget.songId.toString(), 68),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SongTypeBadge(
                            songId: widget.songId, type: widget.songType),
                        const SizedBox(width: 6),
                        Expanded(
                          child: MarqueeText(
                            text: widget.songTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.flowSongIDP0((widget.songId).toString()),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    _buildDsDisplay(),
                  ],
                ),
              ),
            ],
          ),
          if (_inoteList.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInotePill('ALL', 'ALL', scheme.primary),
                  for (final inote in _inoteList)
                    _buildInotePill(inote, _getInoteDifficulty(inote),
                        _getInoteColor(inote)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final hasCode = !_isLoading && _maidataContent.isNotEmpty;

    return BackgroundPageScaffold(
      title: context.l10n.flowChartCode,
      actions: [
        IconButton(
          tooltip: context.l10n.chartCodeFont,
          icon: const Icon(Icons.text_fields_rounded),
          onPressed: _chooseCodeFont,
        ),
      ],
      contentPadding: hasCode
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 10),
          child: _buildHeaderCard(),
        ),
        Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.errorRed(brightness),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.errorRed(brightness),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _fetchMaidata,
                                child: Text(context.l10n.flowRetry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _maidataContent.isEmpty
                        ? Center(
                            child: Text(context.l10n.flowNoChartCodeAvailable),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppDesignTokens.gutter,
                                0,
                                AppDesignTokens.gutter,
                                12),
                            child: AppCard(
                              radius: AppDesignTokens.radiusMedium,
                              padding: EdgeInsets.zero,
                              child: SizedBox.expand(
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(14),
                                  child: SelectableText(
                                    _getFilteredMaidata(),
                                    style: _codeFont.apply(TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurface,
                                      height: 1.4,
                                    )),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ),
                            ),
                          )),
        // 操作放到底部，带文字，比顶部三个小图标好认
        if (hasCode)
          BottomActionBar(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(context.l10n.flowCopy),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isExporting ? null : _showExportOptions,
                  icon: Icon(
                    _isExporting ? Icons.hourglass_empty : Icons.download,
                    size: 18,
                  ),
                  label: Text(_isExporting
                      ? context.l10n.flowExporting
                      : context.l10n.flowExport),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _navigateToChartPlay,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(context.l10n.flowRender),
                ),
              ),
            ],
          ),
      ]),
    );
  }
}

/// 一次导出需要的三件套
class _ChartExportAssets {
  final Uint8List maidataBytes;
  final Uint8List? coverBytes;
  final Uint8List? audioBytes;

  _ChartExportAssets({
    required this.maidataBytes,
    this.coverBytes,
    this.audioBytes,
  });

  /// 缺件提示。缺少音源/曲绘时 AstroDX 仍能装谱，但游玩体验不完整，
  /// 所以这里不阻断导出，只在成功弹窗里提醒。
  String? get missingHint {
    final missing = <String>[];
    if (coverBytes == null) missing.add(appL10n.flowCoverArt);
    if (audioBytes == null) missing.add(appL10n.flowAudio);
    if (missing.isEmpty) return null;
    return appL10n
        .flowCouldNotFetchP0ThePackageOnly((missing.join('、')).toString());
  }
}
