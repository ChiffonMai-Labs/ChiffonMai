part of '../SongInfoPage.dart';

/// SongInfoPage · 操作：分享 / 导出 / 跳转 / 收藏 / 笔记 / 上传 BV
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoActions on _SongInfoPageState {
  Future<void> _addToNextPlayQueue() async {
    final basic = _songData?['basic_info'];
    if (basic is! Map) return;
    final levels = _songData?['level'] as List?;
    final constants = _songData?['ds'] as List?;
    final difficultyCount = levels?.length ?? 0;
    final difficultyConstants = constants
            ?.map((value) => value == null ? null : '$value')
            .toList()
            .cast<String?>() ??
        const <String?>[];
    final isUtage = widget.songId.length == 6 || difficultyCount <= 2;
    final difficulties = isUtage
        ? List.generate(
            difficultyCount > 0 ? difficultyCount : 1,
            (index) => NextPlayDifficultyOption(
              index: 5,
              name: ChartDifficulty.utageLabel,
              constant: index < difficultyConstants.length
                  ? difficultyConstants[index]
                  : null,
            ),
          )
        : NextPlayDifficultyOption.standard(
            count: difficultyCount > 0 ? difficultyCount : 5,
            constants: difficultyConstants,
          );
    if (!mounted) return;
    final added = await showNextPlayAddDialog(context,
        songId: widget.songId,
        title: '${basic['title'] ?? ''}',
        artist: '${basic['artist'] ?? ''}',
        type: '${_songData?['type'] ?? 'SD'}',
        coverId: int.tryParse(widget.songId),
        difficulties: difficulties);
    if (mounted && added)
      AppToast.show(context.l10n.flowAddedToPlayNext,
          tone: AppToastTone.success);
  }

  /// 显示 BV 号上传对话框
  void _showBvUploadDialog() {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'];
    final songId = widget.songId;
    final diffIndex = _currentDiffIndex;
    final diffLabel = _getDiffLabel(diffIndex);
    final bvController = TextEditingController(text: _biliBvid ?? '');
    bool isValidating = false;
    String? validationMessage;
    bool? validationPassed;
    int? validatedPlayCount;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final brightness = Theme.of(context).brightness;
            return AppAlertDialog(
              title: Text(context.l10n.flowBilibiliChartVideoViews),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 歌曲信息和当前播放量
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppSurfaces.inset(context),
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            songTitle,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(context.l10n
                              .flowDifficultyP02((diffLabel).toString())),
                          const SizedBox(height: 6),
                          if (_biliPlayCount != null) ...[
                            Text(context.l10n.flowCurrentViewsP0(
                                (_formatBiliPlayCount()).toString())),
                            if (_biliBvid != null)
                              Text(context.l10n
                                  .flowBVIDP0((_biliBvid).toString())),
                            Text(
                                context.l10n.flowSourceP0(
                                    (_getBiliSourceLabel()).toString()),
                                style: TextStyle(
                                  color: _biliFromUser
                                      ? AppColors.linkBlue(brightness)
                                      : (_biliFromRedis
                                          ? AppColors.warningOrange(brightness)
                                          : AppColors.successGreen(brightness)),
                                  fontSize: 12,
                                )),
                          ] else if (_biliPlayCountLoading)
                            Text(context.l10n.flowLoadingViews)
                          else
                            Text(context.l10n.flowNoViewDataYet,
                                style: TextStyle(
                                    color: AppColors.errorRed(brightness))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 手动上传区域
                    Text(context.l10n.flowEnterBVIDManually,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.flowIfViewsCannotBeFetchedAutomaticallyEnter,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bvController,
                      decoration: InputDecoration(
                        hintText: context.l10n.flowExampleBV1xx411c7mD,
                        suffixIcon: bvController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  bvController.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) {
                        // 清除之前的校验结果
                        if (validationMessage != null) {
                          setDialogState(() {
                            validationMessage = null;
                            validationPassed = null;
                            validatedPlayCount = null;
                          });
                        }
                      },
                    ),
                    // 校验结果
                    if (validationMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: validationPassed == true
                              ? AppColors.successGreen(brightness)
                              : AppColors.errorRed(brightness),
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              validationPassed == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // 校验通过后显示播放量
                    if (validatedPlayCount != null &&
                        validationPassed == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.flowViewsP0((validatedPlayCount! >= 10000
                                ? context.l10n.flowP010000(
                                    ((validatedPlayCount! / 10000)
                                            .toStringAsFixed(1))
                                        .toString())
                                : validatedPlayCount.toString())
                            .toString()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen(brightness),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.l10n.featureCancel),
                ),
                // 校验按钮
                TextButton(
                  onPressed: isValidating
                      ? null
                      : () async {
                          final bvid = bvController.text.trim();
                          if (bvid.isEmpty) {
                            setDialogState(() {
                              validationMessage = context.l10n.flowEnterABVID;
                              validationPassed = false;
                            });
                            return;
                          }
                          if (!RegExp(r'^BV[a-zA-Z0-9]{10}$').hasMatch(bvid)) {
                            setDialogState(() {
                              validationMessage = context
                                  .l10n.flowInvalidBVIDExpectedBVFollowedBy;
                              validationPassed = false;
                            });
                            return;
                          }

                          setDialogState(() => isValidating = true);

                          try {
                            final result = await BiliSearchService()
                                .validateBvForSong(bvid, songTitle);

                            if (result == null) {
                              setDialogState(() {
                                validationMessage = context.l10n
                                    .flowCheckFailedVideoInformationUnavailableTheBV;
                                validationPassed = false;
                                isValidating = false;
                              });
                            } else if (result.passed) {
                              setDialogState(() {
                                validationMessage = context.l10n
                                    .flowVerifiedVideoTitleP0(
                                        (result.videoInfo.title).toString());
                                validationPassed = true;
                                validatedPlayCount = result.videoInfo.playCount;
                                isValidating = false;
                              });
                            } else {
                              setDialogState(() {
                                validationMessage = context.l10n
                                    .flowCheckFailedVideoTitleP0DoesNot(
                                        (result.videoInfo.title).toString(),
                                        (songTitle).toString());
                                validationPassed = false;
                                isValidating = false;
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              validationMessage = context.l10n
                                  .flowVerificationErrorP0((e).toString());
                              validationPassed = false;
                              isValidating = false;
                            });
                          }
                        },
                  child: isValidating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.flowCheckBVID),
                ),
                // 确认上传按钮（只有校验通过后才可点击）
                TextButton(
                  onPressed: (validationPassed == true && !isValidating)
                      ? () async {
                          final bvid = bvController.text.trim();
                          final playCount = validatedPlayCount;

                          // 保存到本地状态
                          _update(() {
                            _biliPlayCount = playCount ?? _biliPlayCount;
                            _biliBvid = bvid;
                            _biliFromRedis = false;
                            _biliFromUser = true;
                          });

                          // 保存到 Redis 服务器
                          BiliRedisService().uploadUserBv(
                            songId: songId,
                            songTitle: songTitle,
                            diffIndex: diffIndex,
                            bvid: bvid,
                            playCount: playCount,
                          );

                          Navigator.of(dialogContext).pop();
                          AppToast.show(context.l10n.flowBVIDUploaded,
                              duration: Duration(seconds: 2));
                        }
                      : null,
                  child: Text(context.l10n.flowConfirmUpload),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 请求存储权限
  Future<PermissionStatus> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus videosStatus = await Permission.videos.status;

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
      PermissionStatus status = await Permission.storage.request();
      return status;
    }
  }

  Future<Widget> _buildScoreSharePreview({
    required ExportImageTheme theme,
    required Map<String, dynamic> userRecord,
    required Map<String, dynamic> basicInfo,
    required List<dynamic> levels,
    required BuildContext context,
  }) async {
    final songId = widget.songId;
    final songType = _songData!['type'] ?? 'SD';
    final levelStr = (levels[_currentDiffIndex] ?? '').toString();
    final achievements = _safeToDouble(userRecord['achievements']);
    final ra = _safeToInt(userRecord['ra']);
    final dxScore = _safeToInt(userRecord['dxScore']);
    return SongScoreShareService.buildPreviewWidget(
      theme: theme,
      context: context,
      songId: songId,
      songTitle: basicInfo['title']?.toString() ?? '',
      artist: basicInfo['artist']?.toString() ?? '',
      songType: songType.toString(),
      levelIndex: _currentDiffIndex,
      levelStr: levelStr,
      ds: _safeToDouble(_songData!['ds'] != null &&
              (_songData!['ds'] as List).length > _currentDiffIndex
          ? (_songData!['ds'] as List)[_currentDiffIndex]
          : 0.0),
      genre: basicInfo['genre']?.toString() ?? '',
      bpm: _safeToInt(basicInfo['bpm']),
      achievements: achievements,
      ra: ra,
      dxScore: dxScore,
      maxDxScore: _calculateMaxDxScore(int.parse(songId), _currentDiffIndex),
      fc: userRecord['fc']?.toString() ?? '',
      fs: userRecord['fs']?.toString() ?? '',
      rawRate: userRecord['rate']?.toString() ?? '',
    );
  }

  // 导出成绩分享卡片
  Future<void> _shareScoreCard({
    required Map<String, dynamic> userRecord,
    required Map<String, dynamic> basicInfo,
    required List<dynamic> levels,
  }) async {
    final quality = await ExportQualitySelector.show(context,
        estimatedPngSize: ImageEncodeUtil.estimatePngSize(
            songCount: 1, hasHeader: false, cardsPerRow: 1),
        exportingLabel: context.l10n.flowChartScoreCard,
        previewBuilder: (previewContext, previewQuality) =>
            _buildScoreSharePreview(
              theme: previewQuality.theme,
              context: previewContext,
              userRecord: userRecord,
              basicInfo: basicInfo,
              levels: levels,
            ));
    if (quality == null) return;

    try {
      // 获取数据（安全类型转换，处理API可能返回String的情况）
      final songId = widget.songId;
      final songTitle = basicInfo['title'] ?? '';
      final artist = basicInfo['artist'] ?? '';
      final songType = _songData!['type'] ?? 'SD';
      final levelStr = (levels[_currentDiffIndex] ?? '').toString();
      final achievements = _safeToDouble(userRecord['achievements']);
      final ra = _safeToInt(userRecord['ra']);
      final dxScore = _safeToInt(userRecord['dxScore']);
      final maxDxScore = _calculateMaxDxScore(
        int.parse(songId),
        _currentDiffIndex,
      );
      final fc = userRecord['fc'] ?? '';
      final fs = userRecord['fs'] ?? '';
      final rawRate = userRecord['rate'] ?? '';
      final genre = basicInfo['genre'] ?? '';
      final bpm = _safeToInt(basicInfo['bpm']);
      final ds = _safeToDouble(_songData!['ds'] != null &&
              (_songData!['ds'] as List).length > _currentDiffIndex
          ? (_songData!['ds'] as List)[_currentDiffIndex]
          : 0.0);

      // 调用导出服务
      final levelIndex = _currentDiffIndex;
      BackgroundExport.run(
        label: context.l10n.flowScoreShareCard,
        task: (exportContext) => SongScoreShareService.convertToImage(
          exportContext,
          songId: songId,
          songTitle: songTitle,
          artist: artist,
          songType: songType,
          levelIndex: levelIndex,
          levelStr: levelStr,
          ds: ds,
          genre: genre,
          bpm: bpm,
          achievements: achievements,
          ra: ra,
          dxScore: dxScore,
          maxDxScore: maxDxScore,
          fc: fc,
          fs: fs,
          rawRate: rawRate,
          jpegQuality: quality.jpegQuality,
          theme: quality.theme,
        ),
      );
    } catch (e) {
      AppToast.show(context.l10n.flowExportFailedP02((e).toString()),
          tone: AppToastTone.error);
    }
  }

  Widget _buildSongInfoExportPreview(
      BuildContext previewContext, ExportImageTheme theme) {
    final data = _songData;
    if (data == null) return const SizedBox.shrink();
    final basicInfo = data['basic_info'] as Map<String, dynamic>;
    return SongInfoExportToImgService.buildPreviewWidget(
      theme: theme,
      context: previewContext,
      songId: widget.songId,
      basicInfo: basicInfo,
      charts: (data['charts'] as List<dynamic>?) ?? const [],
      levels: (data['level'] as List<dynamic>?) ?? const [],
      ds: (data['ds'] as List<dynamic>?) ?? const [],
      songType: data['type']?.toString() ?? 'SD',
      diffData: _diffData,
      bpm: _exportBpm(basicInfo),
      maidataNoteCounts: _maidataNoteCounts,
      maidataBreakCounts: _maidataBreakCounts,
      maidataDecodedSuccessfully: _maidataDecodedSuccessfully,
      isExtra: _isExtraSong,
      referenceDuration: _formatReferenceDuration(),
    );
  }

  // 导出歌曲信息为图片
  Future<void> _exportSongInfoToImage() async {
    if (_songData == null) return;

    final quality = await ExportQualitySelector.show(context,
        estimatedPngSize: ImageEncodeUtil.estimatePngSize(
            songCount: 1, hasHeader: false, cardsPerRow: 1),
        exportingLabel: context.l10n.flowSongInformation,
        previewBuilder: (previewContext, previewQuality) =>
            _buildSongInfoExportPreview(previewContext, previewQuality.theme));
    if (quality == null) return;

    try {
      final basicInfo = _songData!['basic_info'];
      final charts = _songData!['charts'];
      final levels = _songData!['level'];
      final ds = _songData!['ds'];
      final songType = _songData!['type'] ?? 'SD';

      final songId = widget.songId;
      final bpm = _exportBpm(basicInfo);
      final referenceDuration = _formatReferenceDuration();
      final diffData = _diffData;
      final noteCounts = _maidataNoteCounts;
      final breakCounts = _maidataBreakCounts;
      final decoded = _maidataDecodedSuccessfully;
      final isExtra = _isExtraSong;
      BackgroundExport.run(
        label: context.l10n.flowSongInformationImage,
        task: (exportContext) => SongInfoExportToImgService.convertToImage(
          exportContext,
          songId: songId,
          basicInfo: basicInfo,
          charts: charts,
          levels: levels,
          ds: ds,
          songType: songType,
          diffData: diffData,
          bpm: bpm,
          maidataNoteCounts: noteCounts,
          maidataBreakCounts: breakCounts,
          maidataDecodedSuccessfully: decoded,
          isExtra: isExtra,
          referenceDuration: referenceDuration,
          jpegQuality: quality.jpegQuality,
          theme: quality.theme,
        ),
      );
    } catch (e) {
      AppToast.show(context.l10n.flowExportFailedP02((e).toString()),
          tone: AppToastTone.error);
    }
  }

  // 保存封面到相册
  Future<void> _saveCoverToGallery(String songId, String title) async {
    try {
      // 请求存储权限
      PermissionStatus status = await _requestStoragePermission();
      if (!status.isGranted) {
        AppToast.show(context.l10n.flowStoragePermissionIsRequiredToSaveImages,
            tone: AppToastTone.warning);
        return;
      }

      // 获取封面图片数据
      ByteData? byteData;
      try {
        // 尝试从assets加载
        String coverPath = CoverUtil.buildCoverPath(songId);
        byteData = await rootBundle.load(coverPath);
      } catch (e) {
        // 尝试其他路径
        try {
          String coverPath = CoverUtil.getLocalCoverPath(songId);
          byteData = await rootBundle.load(coverPath);
        } catch (e2) {
          try {
            String coverPath = CoverUtil.getLocalCoverPathRetry1(songId);
            byteData = await rootBundle.load(coverPath);
          } catch (e3) {
            AppToast.show(context.l10n.flowCouldNotLoadCoverArt,
                tone: AppToastTone.error);
            return;
          }
        }
      }

      if (byteData == null) {
        AppToast.show(context.l10n.flowCouldNotLoadCoverArt,
            tone: AppToastTone.error);
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 保存到相册
      Directory? directory;
      if (status.isGranted) {
        try {
          String picturesPath = '/storage/emulated/0/Pictures';
          directory = Directory(picturesPath);
          if (!directory.existsSync()) {
            directory.createSync(recursive: true);
          }
        } catch (e) {
          directory = null;
        }
      }

      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      String fileName =
          '${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 通知系统相册
      if (Platform.isAndroid) {
        await MediaScanner.loadMedia(path: file.path);
      }

      AppToast.show(context.l10n.flowCoverArtSavedToPhotos,
          tone: AppToastTone.success);
    } catch (e) {
      AppToast.show(context.l10n.flowSaveFailedP02((e).toString()),
          tone: AppToastTone.error);
    }
  }

  // 跳转到B站
  void _jumpToBilibili() async {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'];
    final diffLabel = _getDiffLabel(_currentDiffIndex);
    final searchQuery = '$songTitle $diffLabel';

    // B站搜索链接
    final url = Uri.parse(
        'bilibili://search?keyword=${Uri.encodeComponent(searchQuery)}');

    // 尝试打开B站应用
    if (!await ExternalLaunchUtil.open(url)) {
      // 如果无法打开B站应用，尝试在浏览器中打开
      final webUrl = Uri.parse(
          'https://search.bilibili.com/all?keyword=${Uri.encodeComponent(searchQuery)}');
      await ExternalLaunchUtil.open(webUrl);
    }
  }

  // 播放音乐
  void _playMusic() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongPlayPage(
          songId: widget.songId,
          songTitle: _songData!['basic_info']['title'],
          songType: _songData!['type'],
          songArtist: _songData!['basic_info']['artist'],
        ),
      ),
    );
  }

  // 播放歌曲 PV
  Future<void> _playPv() async {
    if (_songData == null) return;
    final title = _songData!['basic_info']?['title']?.toString() ??
        context.l10n.flowSongPV;
    final openBilibili = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(context.l10n.flowPlayPV),
        content: Text(context.l10n.flowChooseHowToPlayThePV),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.flowOpenBilibili),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.flowPlayInApp),
          ),
        ],
      ),
    );
    if (!mounted || openBilibili == null) return;
    if (openBilibili) {
      final searchQuery = '$title PV';
      final biliUri = Uri.parse(
        'bilibili://search?keyword=${Uri.encodeComponent(searchQuery)}',
      );
      if (!await ExternalLaunchUtil.open(biliUri)) {
        final webUri = Uri.parse(
          'https://search.bilibili.com/all?keyword=${Uri.encodeComponent(searchQuery)}',
        );
        await ExternalLaunchUtil.open(webUri);
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPvPage(
          songId: widget.songId,
          songTitle: title,
        ),
      ),
    );
  }

  // 查看相关收藏品
  void _viewRelatedCollectibles() {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'];
    _fetchRelatedCollections(songTitle);
  }

  // 获取相关收藏品
  Future<void> _fetchRelatedCollections(String songTitle) async {
    try {
      // 显示加载对话框
      showAppProgressDialog(context,
          title: appL10n.flowPleaseWait,
          message: appL10n.flowLoadingRelatedCollectibles);

      // 获取歌曲类型
      final songType = _songData!['type'] ?? '';

      // 使用SongInfoService获取相关收藏品
      final relatedCollections =
          await SongInfoService().fetchRelatedCollections(songTitle, songType);

      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示相关收藏品
      _showRelatedCollectionsDialog(songTitle, relatedCollections);
    } catch (e) {
      debugPrint('获取相关收藏品时出错: $e');
      // 关闭加载对话框
      Navigator.of(context).pop();
      // 显示错误信息
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AppAlertDialog(
            title: Text(appL10n.flowError),
            content: Text(appL10n.flowCouldNotLoadRelatedCollectiblesTryAgain),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(appL10n.featureClose),
              ),
            ],
          );
        },
      );
    }
  }

  // 检查当前谱面的收藏夹状态
  // 检查当前谱面是否有笔记
  Future<void> _checkNoteStatus() async {
    try {
      final service = ChartNoteService();
      final note = await service.getNoteByChart(
        widget.songId,
        _currentDiffIndex,
      );
      if (mounted) {
        _update(() {
          _hasNote = note != null;
        });
      }
    } catch (e) {
      debugPrint('检查谱面笔记状态失败: $e');
    }
  }

  // 显示谱面笔记对话框
  Future<void> _showNoteDialog() async {
    final service = ChartNoteService();
    final existingNote = await service.getNoteByChart(
      widget.songId,
      _currentDiffIndex,
    );

    if (!mounted) return;

    final basicInfo = _songData!['basic_info'];
    final songTitle = basicInfo['title'] ?? '';
    final levels = _songData!['level'];
    final isUtage = widget.songId.length == 6;
    final rawLevel = (levels[_currentDiffIndex] ?? '').toString();
    const diffNames = ChartDifficulty.standardLabels;
    final diffName = isUtage
        ? ChartDifficulty.utageLabel
        : diffNames[_currentDiffIndex.clamp(0, 4)];

    final TextEditingController controller = TextEditingController(
      text: existingNote?.content ?? '',
    );
    bool isEditing = existingNote != null;

    showDialog(
      context: context,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AppAlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.note : Icons.note_add_outlined,
                    color:
                        AppColors.warningOrange(Theme.of(context).brightness),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing
                          ? context.l10n.flowChartNotes
                          : context.l10n.flowAddChartNotes,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 谱面信息（与收藏页面一致）
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusSmall),
                            child: CoverUtil.buildCoverWidgetWithContext(
                                context, widget.songId, 60),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 第一行：类型标签 + 歌名
                                Row(
                                  children: [
                                    _buildNoteTypeTag(),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(songTitle,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                // 第二行：难度标签
                                _buildNoteDiffTag(diffName),
                                SizedBox(height: 4),
                                // 第三行：类别
                                Text(
                                  basicInfo['genre'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // 笔记内容（限制行数避免键盘弹出时溢出）
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          hintText:
                              context.l10n.flowWriteYourNotesForThisChartHere,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSmall)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSmall),
                              borderSide: BorderSide(
                                  color: AppColors.warningOrange(
                                      Theme.of(context).brightness),
                                  width: 2)),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      // 时间信息
                      if (existingNote != null) ...[
                        SizedBox(height: 8),
                        Text(
                            context.l10n.flowCreatedP0P1(
                                (_formatTimestamp(existingNote.createdAt))
                                    .toString(),
                                (existingNote.updatedAt !=
                                            existingNote.createdAt
                                        ? context.l10n.flowUpdatedP0(
                                            (_formatTimestamp(
                                                    existingNote.updatedAt))
                                                .toString())
                                        : '')
                                    .toString()),
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.greyHint(brightness))),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                // 删除按钮（仅在有笔记时显示）
                if (existingNote != null)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (confirmCtx) => AppAlertDialog(
                          title: Text(context.l10n.flowConfirmDeletion),
                          content: Text(
                              context.l10n.flowDeleteTheNotesForThisChartThis),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(confirmCtx).pop(false),
                              child: Text(context.l10n.featureCancel),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(confirmCtx).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.errorRed(brightness),
                              ),
                              child: Text(context.l10n.flowDelete),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await service.deleteNote(
                          widget.songId,
                          _currentDiffIndex,
                        );
                        if (mounted) {
                          _update(() {
                            _hasNote = false;
                          });
                        }
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                    child: Text(context.l10n.flowDelete),
                  ),
                // 取消按钮
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.l10n.featureCancel),
                ),
                // 保存按钮
                ElevatedButton(
                  onPressed: (controller.text.trim().isNotEmpty)
                      ? () async {
                          final note = ChartNote(
                            songId: widget.songId,
                            levelIndex: _currentDiffIndex,
                            songTitle: songTitle,
                            level: '$diffName $rawLevel',
                            ds: _getCurrentDs(),
                            content: controller.text.trim(),
                          );
                          await service.saveNote(note);
                          if (mounted) {
                            _update(() {
                              _hasNote = true;
                            });
                          }
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.warningOrange(Theme.of(context).brightness),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(context.l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 笔记对话框：类型标签
  Widget _buildNoteTypeTag() {
    final isUtage = widget.songId.length == 6;
    if (isUtage) {
      return Text('UT',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red));
    }
    final songType = _songData!['type'] ?? 'SD';
    if (songType == 'DX') {
      return Text('DX',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.warningOrange(Theme.of(context).brightness)));
    }
    return Text('ST',
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.linkBlue(Theme.of(context).brightness)));
  }

  // 笔记对话框：难度标签
  Widget _buildNoteDiffTag(String diffLabel) {
    final isUtage = widget.songId.length == 6;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    Color bgColor, textColor;
    if (isUtage) {
      bgColor = isDark ? const Color(0xFF4A2020) : Colors.red.shade100;
      textColor = isDark ? const Color(0xFFEF5350) : Colors.red;
    } else {
      switch (_currentDiffIndex) {
        case ChartDifficulty.basic:
          bgColor = isDark ? const Color(0xFF1B3D1B) : Colors.green.shade100;
          textColor = isDark ? const Color(0xFF66BB6A) : Colors.green.shade700;
          break;
        case ChartDifficulty.advanced:
          bgColor = isDark ? const Color(0xFF3D2E00) : Colors.orange.shade100;
          textColor = isDark ? const Color(0xFFFFB74D) : Colors.orange.shade700;
          break;
        case ChartDifficulty.expert:
          bgColor = isDark ? const Color(0xFF4A2020) : Colors.red.shade100;
          textColor = isDark ? const Color(0xFFEF5350) : Colors.red;
          break;
        case ChartDifficulty.master:
          bgColor = isDark ? const Color(0xFF2A1A3D) : Colors.purple.shade100;
          textColor = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade700;
          break;
        case ChartDifficulty.reMaster:
          bgColor = isDark ? const Color(0xFF2A1A3D) : Colors.purple.shade100;
          textColor = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade300;
          break;
        default:
          bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
          textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
      }
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(diffLabel,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Future<void> _checkBookmarkStatus() async {
    final uniqueKey = '${widget.songId}_$_currentDiffIndex';
    final folderIds =
        await FavoriteFolderService().findFoldersContainingChart(uniqueKey);
    if (mounted) {
      _update(() {
        _isBookmarked = folderIds.isNotEmpty;
      });
    }
  }

  // 显示收藏夹选择对话框
  void _showBookmarkDialog() {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'] ?? '';
    final levels = _songData!['level'] as List?;
    final levelStr = (levels != null && _currentDiffIndex < levels.length)
        ? levels[_currentDiffIndex].toString()
        : '';
    final dss = _songData!['ds'] as List?;
    final dsValue = (dss != null && _currentDiffIndex < dss.length)
        ? (dss[_currentDiffIndex] as num).toDouble()
        : 0.0;
    final songType = _songData!['type'] ?? '';

    final chart = FavoriteChart(
      songId: widget.songId,
      levelIndex: _currentDiffIndex,
      songTitle: songTitle,
      level: levelStr,
      ds: dsValue,
      songType: songType,
    );

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return _BookmarkFolderSelectorDialog(chart: chart);
      },
    ).then((_) {
      // 对话框关闭后刷新状态
      _checkBookmarkStatus();
      if (mounted) _update(() {});
    });
  }

  // 显示相关收藏品对话框
  void _showRelatedCollectionsDialog(
      String songTitle, List<Map<String, dynamic>> relatedCollections) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowRelatedCollectibles),
          subtitle: songTitle,
          content: relatedCollections.isEmpty
              ? AppDialogEmpty(
                  icon: Icons.workspace_premium_outlined,
                  message: context.l10n.flowNoCollectiblesLinkedToThisSong,
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, item) in relatedCollections.indexed)
                        Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                          child: AppDialogOption(
                            title: item['name'],
                            subtitle: item['description'],
                            leading: AppBadge(
                              text: _getCollectionTypeName(item['type']),
                              background: _getCollectionTypeColor(item['type']),
                              foreground: Colors.white,
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            onTap: () {
                              // 跳转到收藏品详情页面
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CollectionInfoPage(
                                    collectionId:
                                        (item['collection'] as Collection).id,
                                    collectionType: item['type'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.featureClose),
            ),
          ],
        );
      },
    );
  }

  // 打开计算工具页面：预填当前曲谱的物量、定数、用户达成率等
  void _openCalculator() {
    if (_songData == null) return;
    final currentChart = _songData!['charts'][_currentDiffIndex];
    final record = _getUserBestRecord();

    // 拟合定数兼容两种类型：DiffData 对象 / 普通 Map
    double? fitDiffValue;
    final diffEntry = _diffData != null ? _diffData![_currentDiffIndex] : null;
    if (diffEntry is DiffData) {
      fitDiffValue = diffEntry.fitDiff.toDouble();
    } else if (diffEntry is Map) {
      final raw = diffEntry['fit_diff'];
      fitDiffValue = raw is num ? raw.toDouble() : null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalculatorPage(
          songId: widget.songId,
          songTitle: _songData!['basic_info']['title'] ?? '',
          songType: _songData!['type'] ?? 'DX',
          difficultyIndex: _currentDiffIndex,
          difficultyLabel: _getDiffLabel(_currentDiffIndex),
          ds: (_songData!['ds'][_currentDiffIndex] as num).toDouble(),
          fitDiff: fitDiffValue,
          noteCounts: _getNoteCounts(currentChart),
          userAchievement: (record?['achievements'] as num?)?.toDouble(),
          userRating:
              (record?['ra'] is num) ? (record!['ra'] as num).toInt() : null,
        ),
      ),
    );
  }

  // 查看谱面代码（跳转到maidata页面）
  void _viewMaidata() {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'];
    final genre = _songData!['basic_info']['genre'];
    final songType = _songData!['type'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongMaidataPage(
          songId: widget.songId,
          songTitle: songTitle,
          genre: genre,
          songType: songType,
          difficultyIndex: _currentDiffIndex,
        ),
      ),
    );
  }

  void _viewAchievementRanking() {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'];
    final songType = _songData!['type'];
    final artist = _songData!['basic_info']['artist'] ?? '';
    final from = _songData!['basic_info']['from'] ?? '';

    double difficultyDs = 0.0;
    if (_songData!['ds'] != null && _songData!['ds'] is List) {
      List<dynamic> dsList = _songData!['ds'];
      if (_currentDiffIndex >= 0 && _currentDiffIndex < dsList.length) {
        difficultyDs = (dsList[_currentDiffIndex] as num).toDouble();
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongRankingPage(
          songId: widget.songId,
          difficultyIndex: _currentDiffIndex,
          rankingType: RankingType.achievementRate,
          songTitle: songTitle,
          difficultyLabel: _getDiffLabel(_currentDiffIndex),
          songType: songType,
          artist: artist,
          genre: '',
          from: from,
          isExtra: _isExtraSong,
          difficultyDs: difficultyDs,
        ),
      ),
    );
  }

  void _viewDxScoreRanking() {
    if (_songData == null) return;

    final songTitle = _songData!['basic_info']['title'];
    final songType = _songData!['type'];
    final artist = _songData!['basic_info']['artist'] ?? '';
    final from = _songData!['basic_info']['from'] ?? '';

    double difficultyDs = 0.0;
    if (_songData!['ds'] != null && _songData!['ds'] is List) {
      List<dynamic> dsList = _songData!['ds'];
      if (_currentDiffIndex >= 0 && _currentDiffIndex < dsList.length) {
        difficultyDs = (dsList[_currentDiffIndex] as num).toDouble();
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongRankingPage(
          songId: widget.songId,
          difficultyIndex: _currentDiffIndex,
          rankingType: RankingType.dxScore,
          songTitle: songTitle,
          difficultyLabel: _getDiffLabel(_currentDiffIndex),
          songType: songType,
          artist: artist,
          genre: '',
          from: from,
          isExtra: _isExtraSong,
          difficultyDs: difficultyDs,
        ),
      ),
    );
  }
}
