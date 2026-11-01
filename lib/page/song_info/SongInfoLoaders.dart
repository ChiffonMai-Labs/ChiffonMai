part of '../SongInfoPage.dart';

/// SongInfoPage · 数据加载、解析与数值计算
///
/// 2026-11 从 SongInfoPage.dart 原样拆出（方法体未改，仅 setState → _update）。
extension _SongInfoLoaders on _SongInfoPageState {

  /// 游玩次数缓存（AWMC 网关 `/v1/user/music` 拉到的 playCount）。
  ///
  /// 缓存是懒加载的：这里读一次 prefs，读到就重建页面把「游玩次数」显示出来；
  /// 没有缓存就不显示这一行（而不是显示 0——没记录和打了 0 次是两回事）。
  Future<void> _loadAwmcPlayCounts() async {
    if (AwmcPlayCountStore.isLoaded) {
      if (mounted) _update(() {});
      return;
    }
    await AwmcPlayCountStore.ensureLoaded();
    if (mounted) _update(() {});
  }

  /// 当前谱面的游玩次数；无缓存记录时返回 null。
  int? get _currentPlayCount => AwmcPlayCountStore.playCountOfDiffIndex(
        int.tryParse(widget.songId) ?? 0,
        _currentDiffIndex,
      );

  void _scheduleSongTitleVisibilityCheck() {
    if (_titleVisibilityCheckScheduled) return;
    _titleVisibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleVisibilityCheckScheduled = false;
      if (mounted) _updateSongTitleVisibility();
    });
  }

  void _updateSongTitleVisibility() {
    if (!mounted || !_songScrollController.hasClients) return;
    final titleBox =
        _songTitleKey.currentContext?.findRenderObject() as RenderBox?;
    final scrollBox =
        _songScrollKey.currentContext?.findRenderObject() as RenderBox?;
    if (titleBox == null || scrollBox == null || !titleBox.hasSize) return;

    final viewportTop = scrollBox.localToGlobal(Offset.zero).dy;
    final titleBottom = titleBox
        .localToGlobal(
          Offset(0, titleBox.size.height),
        )
        .dy;
    // 头图铺到状态栏下面，歌名要算上状态栏 + 顶部栏才算「滚出去了」。
    final shouldShow = titleBottom <=
        viewportTop + MediaQuery.paddingOf(context).top + kToolbarHeight;
    if (shouldShow != _showSongTitleInAppBar) {
      _update(() => _showSongTitleInAppBar = shouldShow);
    }
  }

  // 加载所有数据
  Future<void> _loadData() async {
    try {
      // 使用SongInfoService加载数据
      final result = await SongInfoService().loadData(widget.songId);
      if (!mounted) return;
      _songData = result['songData'];
      _diffData = result['diffData'];
      _userData = result['userData'];
      _tagData = result['tagData'];
      _tagSongsData = result['tagSongsData'];

      // 单曲缺失时后台补齐，网络请求不阻塞详情页；解析完成后即时刷新统计。
      unawaited(_loadMaidataNoteCounts());

      // 加载相关收藏品数量
      if (_songData != null) {
        final songTitle = _songData!['basic_info']['title'];
        final songType = _songData!['type'] ?? '';
        await _loadRelatedCollectionsCount(songTitle, songType);

        // 检测是否存在另一种谱面
        await _checkAlternativeSong(songTitle, songType);
      }

      if (!mounted) return;

      // 加载参考时长
      _loadReferenceDuration();

      // 加载B站谱面确认播放量
      _loadBiliPlayCount();

      // 加载评论者身份信息
      final identity = await SongInfoService.getCommentIdentity();
      if (!mounted) return;
      if (identity != null) {
        _update(() {
          _commentDataSource = identity.dataSource;
          _commentOriginalId = identity.originalId;
          _commentNickname = identity.nickname;
        });
      }

      // 加载评论
      _loadComments();

      // 加载 union uni 元数据（cn/jp 可游玩地区）
      _loadUniInfo();

      // 加载谱面评分数据
      _loadChartRating();

      // 预加载用户总Rating和理论Rating
      _preloadRatingData();
    } catch (e) {
      debugPrint('加载数据失败: $e');
    } finally {
      if (!mounted) return;
      // 调整_currentDiffIndex，确保不超过实际难度数量
      if (_songData != null) {
        final levels = _songData!['level'];
        if (levels != null && levels is List) {
          // 对于难度数量大于等于4个的歌曲，默认选择第4个难度（仅当使用默认值时）
          if (levels.length >= 4 &&
              widget.isDefaultLevelIndex &&
              widget.initialLevelIndex == 0 &&
              _currentDiffIndex == 0) {
            _currentDiffIndex = 3; // 第4个难度（索引为3）
          } else if (_currentDiffIndex >= levels.length) {
            _currentDiffIndex = levels.length - 1;
          }
          // 确保索引不为负数
          if (_currentDiffIndex < 0) {
            _currentDiffIndex = 0;
          }

          // 对于只有2个难度的歌曲，拟合难度的数据跟第一个难度保持相同
          if (levels.length == 2 &&
              _diffData != null &&
              _diffData!.isNotEmpty) {
            _diffData = [_diffData![0], _diffData![0]];
          }
        } else {
          // 如果没有难度数据，设置为0
          _currentDiffIndex = 0;
        }
      }

      // 如果 _currentDiffIndex 在 finally 中被调整了，重新加载 B站播放量
      if (_currentDiffIndex != (_biliLoadedDiffIndex ?? -1)) {
        _update(() {
          _isLoading = false;
        });
        _loadBiliPlayCount();
      } else {
        _update(() {
          _isLoading = false;
        });
      }
      // 检查当前谱面是否已被收藏
      _checkBookmarkStatus();
      // 检查当前谱面是否有笔记
      _checkNoteStatus();
      _loadBest50Opportunity();
    }
  }

  /// 判断当前谱面在理论上能否挤进对应的 Best35 / Best15。
  /// 使用推荐页同一套 Rating 权重和最低达成率算法，避免两个页面给出不同结论。
  Future<void> _loadBest50Opportunity() async {
    if (mounted) _update(() => _best50OpportunityText = null);
    final song = _songData;
    // 宴会场歌曲（UTAGE）不属于普通 Best35/15，不能套用普通谱面的
    // Rating 门槛计算。六位数 ID 是项目现有的主判定，genre 作为曲库字段兜底。
    final isUtage = widget.songId.length == 6 ||
        song?['basic_info']?['genre']?.toString() == '宴会场' ||
        song?['genre']?.toString() == '宴会场';
    if (isUtage) {
      if (mounted) {
        _update(() => _best50OpportunityText = '宴会场歌曲不参与Best50');
      }
      return;
    }
    final user = _userData;
    if (song == null || user == null || user['records'] is! List) return;
    final dsList = song['ds'];
    if (dsList is! List || _currentDiffIndex >= dsList.length) return;
    final ds = double.tryParse(dsList[_currentDiffIndex].toString());
    if (ds == null) return;

    final allSongs = await MaimaiMusicDataManager().getCachedSongs() ?? [];
    Song? sourceSong;
    for (final item in allSongs) {
      if (item.id == widget.songId) {
        sourceSong = item;
        break;
      }
    }
    if (sourceSong == null) return;
    if (sourceSong.basicInfo.genre == '宴会场') {
      if (mounted) {
        _update(() => _best50OpportunityText = '宴会场歌曲不参与Best50');
      }
      return;
    }
    final isNew = sourceSong.basicInfo.isNew;
    final limit = isNew ? 15 : 35;
    final categoryRecords = <Map<String, dynamic>>[];
    for (final raw in (user['records'] as List)) {
      if (raw is! Map) continue;
      final id = raw['song_id']?.toString();
      final levelIndex = int.tryParse(raw['level_index']?.toString() ?? '');
      if (id == null || levelIndex == null) continue;
      Song? matched;
      for (final item in allSongs) {
        if (item.id == id) {
          matched = item;
          break;
        }
      }
      if (matched == null || matched.basicInfo.isNew != isNew) continue;
      categoryRecords.add(Map<String, dynamic>.from(raw));
    }
    categoryRecords.sort((a, b) => ((b['ra'] as num?)?.toInt() ?? 0)
        .compareTo((a['ra'] as num?)?.toInt() ?? 0));
    final cutoff = categoryRecords.length >= limit
        ? ((categoryRecords[limit - 1]['ra'] as num?)?.toInt() ?? 0)
        : 0;
    final threshold = cutoff + 1;
    final current = _getUserBestRecord();
    final currentAchievement =
        (current?['achievements'] as num?)?.toDouble() ?? 0;
    final currentRa = (current?['ra'] as num?)?.toInt() ?? 0;
    final bestLabel = 'Best${isNew ? 15 : 35}';
    // 下限成绩也属于 Best 区间，不能只比较「进入区间需要的下一分」。
    final alreadyInBest = current != null && currentRa >= cutoff;
    final maxRa = _calculateSingleRating(ds, 100.5);
    if (alreadyInBest && maxRa <= currentRa) {
      if (mounted) {
        _update(() => _best50OpportunityText = '该谱面已在${bestLabel}区间内且无提升空间');
      }
      return;
    }
    final targetAchievement = _findMinimumAchievementForRating(
      ds,
      alreadyInBest ? currentRa + 1 : threshold,
      currentAchievement,
    );
    if (targetAchievement == null) {
      if (mounted) {
        _update(() => _best50OpportunityText =
            alreadyInBest ? '该谱面已在${bestLabel}区间内且无提升空间' : '该谱面无法进入$bestLabel');
      }
      return;
    }
    final targetRa = _calculateSingleRating(ds, targetAchievement);
    // 区间外谱面替换的是末位成绩，区间内谱面提升的是自己的成绩。
    final increase = targetRa - (alreadyInBest ? currentRa : cutoff);
    if (mounted) {
      _update(() {
        _best50OpportunityText =
            '推到${targetAchievement.toStringAsFixed(4)}%可${alreadyInBest ? '提升' : '进入'}$bestLabel\n加${increase < 0 ? 0 : increase}分';
      });
    }
  }

  /// 按下方「达成率 - Rating」表中的全部倍率区间，寻找达到目标 Rating 的最小达成率。
  /// 不能只尝试 100% / 100.5%，因为不少谱面在 97%～100% 的区间就能跨过门槛。
  double? _findMinimumAchievementForRating(
      double difficulty, int targetRating, double currentAchievement) {
    if (difficulty <= 0 || targetRating <= 0) return null;
    final lower = math.max(0.0, currentAchievement + 0.0001);
    if (lower > 100.5) return null;
    double? best;

    for (var index = 0; index < maimaiRatingMultiplier.length; index++) {
      final item = maimaiRatingMultiplier[index];
      final threshold = (item['completion'] as num).toDouble();
      final multiplier = (item['multiplier'] as num).toDouble();
      // 当前倍率区间的上界。表格按达成率从高到低排列，边界本身属于当前行。
      final upper = index == 0
          ? 100.5
          : (maimaiRatingMultiplier[index - 1]['completion'] as num)
                  .toDouble() -
              0.0001;
      if (upper < threshold || upper < lower) continue;

      var candidate = math.max(
        math.max(threshold, lower),
        targetRating / (difficulty * multiplier),
      );
      candidate = (candidate * 10000).ceil() / 10000;
      if (candidate > upper) continue;
      // floor 取整可能让理论边界差 1 分，向上补一个最小可显示步进。
      while (candidate <= upper &&
          _calculateSingleRating(difficulty, candidate) < targetRating) {
        candidate += 0.0001;
      }
      if (candidate <= upper &&
          _calculateSingleRating(difficulty, candidate) >= targetRating) {
        if (best == null || candidate < best) best = candidate;
      }
    }
    return best;
  }

  // 加载定数历史静态数据
  Future<void> _loadDxData() async {
    final data = await DXDataManager().load();
    if (mounted && data != null) {
      _update(() {
        _dxData = data;
      });
    }
  }

  // 找到当前歌曲（标题 + 类型 + 当前难度）对应的 sheet
  DXDataSheet? _findMatchedSheet() {
    final dxData = _dxData;
    final songData = _songData;
    if (dxData == null || songData == null) return null;

    final songTitle = songData['basic_info']?['title']?.toString() ?? '';
    final songType = songData['type']?.toString() ?? '';
    final sheetType = songType == 'DX' ? 'dx' : 'std';
    final difficultyName =
        _dxDifficultyNames[_currentDiffIndex.clamp(0, 4).toInt()];
    final localSongId = _normalizeDxInternalId(widget.songId);
    final localExactId = int.tryParse(widget.songId.trim());
    final titleMatches = <DXDataSheet>[];
    DXDataSheet? legacyIdMatch;

    // 优先使用谱面 internalId。仅按曲名匹配会在同名曲、不同版本或宴会场
    // 谱面上拿到另一张谱面的定数，这是历史定数错乱的主要来源。
    for (final song in dxData.songs) {
      if (song.title != songTitle) continue;
      for (final sheet in song.sheets) {
        if (sheet.type != sheetType) continue;
        if (sheet.difficulty != difficultyName) continue;
        // 先用官网目录的完整 internalId 精确匹配。只有旧目录仍使用
        // 10000 偏移编号时，才走归一化兜底；否则两个不同谱面可能被归一化
        // 成同一个编号，取到错误的定数或地区信息。
        if (localExactId != null && sheet.internalId == localExactId) {
          return sheet;
        }
        if (legacyIdMatch == null &&
            _normalizeDxInternalId('${sheet.internalId}') == localSongId) {
          legacyIdMatch = sheet;
        }
        titleMatches.add(sheet);
      }
    }

    // 旧目录或个别特殊谱面可能仍使用偏移后的 internalId；再退回标题唯一
    // 匹配，避免把一个不确定的定数显示成确定答案。
    return legacyIdMatch ??
        (titleMatches.length == 1 ? titleMatches.single : null);
  }

  // 构建当前歌曲（标题 + 类型 + 当前难度）的定数历史
  List<({String version, double? value})> _buildDxHistory() {
    final dxData = _dxData;
    if (dxData == null) return [];
    final matchedSheet = _findMatchedSheet();
    if (matchedSheet == null) return [];

    // 版本 → 定数。DXRating 的 `internalLevelValue` 是谱面原始基准值，
    // `multiverInternalLevelValue` 才是各版本校正后的历史值；同一版本同时
    // 存在时必须保留后者，否则会把官网的历史定数（例如 [X] 的 FESTiVAL
    // 14.0）覆盖成谱面原始值 13.8。
    final Map<String, double> versionValue = {
      ...matchedSheet.multiverInternalLevelValue,
    };
    versionValue.putIfAbsent(
      matchedSheet.version,
      () => matchedSheet.internalLevelValue,
    );

    if (!versionValue.values.any((value) => value.isFinite && value > 0))
      return [];
    final versions = dxData.versions.toList()
      ..sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    // 统一从 DX 初代开始列出完整版本；缺失定数留空，不前填或后填。
    final names = versions
        .where((v) => v.releaseDate.compareTo('2019-07-11') >= 0)
        .map((v) => v.version)
        .toSet();
    final entries = [
      for (final version in names)
        (
          version: version,
          value: switch (versionValue[version]) {
            final double value when value.isFinite && value > 0 => value,
            _ => null,
          }
        )
    ];
    return entries.any((entry) => entry.value != null) ? entries : [];
  }

  /// 定数历史的 DX 初代短名使用社区常用的 DX / DX+，避免显示日文原名。
  String _formatDxHistoryVersion(String version) {
    final normalized = version.trim();
    if (normalized == 'maimai でらっくす' || normalized == 'maimaiでらっくす') {
      return 'DX';
    }
    if (normalized == 'maimai でらっくす PLUS' || normalized == 'maimaiでらっくす PLUS') {
      return 'DX+';
    }
    return StringUtil.formatVersion(normalized);
  }

  bool _hasDistributionData(dynamic data, bool combo) {
    if (data == null) return false;
    final raw = data is DiffData
        ? (combo ? data.fcDist : data.dist)
        : data[combo ? 'fc_dist' : 'dist'];
    return raw is List && raw.isNotEmpty;
  }

  // 加载相关收藏品数量
  Future<void> _loadRelatedCollectionsCount(
      String songTitle, String songType) async {
    try {
      final relatedCollections =
          await SongInfoService().fetchRelatedCollections(songTitle, songType);
      _update(() {
        _relatedCollectionsCount = relatedCollections.length;
      });
    } catch (e) {
      debugPrint('获取相关收藏品数量时出错: $e');
      _update(() {
        _relatedCollectionsCount = 0;
      });
    }
  }

  // 检测是否存在另一种谱面的歌曲
  Future<void> _checkAlternativeSong(
      String songTitle, String currentType) async {
    try {
      // 获取所有歌曲数据
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs == null || songs.isEmpty) {
        _alternativeSongId = null;
        return;
      }

      // 确定要查找的另一种类型
      String targetType = currentType == 'DX' ? 'SD' : 'DX';

      // 查找同名但类型不同的歌曲
      final alternativeSong = songs.firstWhere(
        (song) =>
            song.basicInfo.title == songTitle &&
            song.type == targetType &&
            song.id != widget.songId,
        orElse: () => Song(
          id: '',
          title: '',
          type: '',
          ds: [],
          level: [],
          cids: [],
          charts: [],
          basicInfo: BasicInfo(
            title: '',
            artist: '',
            genre: '',
            bpm: 0,
            releaseDate: '',
            from: '',
            isNew: false,
          ),
        ),
      );

      // 如果找到另一种谱面，设置其ID
      if (alternativeSong.id.isNotEmpty) {
        _alternativeSongId = alternativeSong.id;
      } else {
        _alternativeSongId = null;
      }
    } catch (e) {
      debugPrint('检测另一种谱面时出错: $e');
      _alternativeSongId = null;
    }
  }

  // 优先读取全量和单曲缓存，缺失时联网补齐并持久化，再即时更新物量与绝赞统计。
  Future<void> _loadMaidataNoteCounts() async {
    try {
      final song = _songData;
      if (song == null) return;
      final basicInfo = song['basic_info'] is Map
          ? Map<String, dynamic>.from(song['basic_info'] as Map)
          : const <String, dynamic>{};
      final service = SongMaidataPageService(
        songId: widget.songId,
        songTitle: basicInfo['title']?.toString() ?? '',
        genre: basicInfo['genre']?.toString() ?? '',
        songType: song['type']?.toString() ?? '',
      );
      final maidataContent = await service.fetchMaidata(
        onInoteParsed: (_) {},
      );
      // 离开页面后缓存仍可保存，但不能再刷新已销毁的页面。
      if (!mounted) return;

      // 日志：输出当前歌曲ID
      debugPrint('[MaidataDecode] 正在解析歌曲ID: ${widget.songId}');

      if (maidataContent != null && maidataContent.isNotEmpty) {
        // 日志：输出原始maidata内容长度
        debugPrint('[MaidataDecode] maidata内容长度: ${maidataContent.length}');

        MaidataData maidata = MaidataDecodeUtil.decode(maidataContent);

        // 日志：输出解析后的chart数量
        debugPrint('[MaidataDecode] 解析出 ${maidata.charts.length} 个chart');

        Map<int, List<int>> newNoteCounts = {};
        Map<int, List<int>> newBreakCounts = {};
        Map<int, String> newBpmByDiffIndex = {};
        final newBpmChanges = <int, List<double>>{};
        for (ChartData chart in maidata.charts) {
          // 难度索引转换：maidata的difficultyIndex是1-6，对应界面显示的0-4（跳过EASY）
          int index = chart.difficultyIndex - 2; // 转换为0-4

          // 日志：输出每个chart的详细信息
          debugPrint(
              '[MaidataDecode] chart[$index] difficultyIndex=${chart.difficultyIndex}, stats=${chart.stats}, breakStats=${chart.breakStats}');

          final bpm = _parseMaidataBpmForChart(maidata, chart);
          debugPrint(
              '[MaidataDecode] chart[$index] inoteLength=${chart.inote.length}, bpm=$bpm');
          if (bpm != null && index >= 0 && index <= 5) {
            newBpmByDiffIndex[index] = bpm;
            newBpmChanges[index] = _bpmChangesForChart(maidata, chart);
            // UTAGE 的 maidata 通常使用 difficultyIndex=7，页面仍以第一个
            // 难度槽显示，所以同步写入索引 0。
            if (widget.songId.length == 6 && index == 5) {
              newBpmByDiffIndex[0] = bpm;
              newBpmChanges[0] = newBpmChanges[index]!;
            }
          }

          if (chart.stats != null) {
            NoteStats stats = chart.stats!;
            debugPrint(
                '[MaidataDecode] chart[$index] tap=${stats.tap}, hold=${stats.hold}, slide=${stats.slide}, touch=${stats.touch}, break=${stats.breakNote}');
          }

          if (chart.breakStats != null) {
            BreakStats breakStats = chart.breakStats!;
            debugPrint(
                '[MaidataDecode] chart[$index] trueZettaiTap=${breakStats.trueZettaiTap}, trueZettaiHold=${breakStats.trueZettaiHold}, protectedZettai=${breakStats.protectedZettai}, star=${breakStats.star}');
          }

          if (index >= 0 && index <= 5 && chart.stats != null) {
            NoteStats stats = chart.stats!;
            newNoteCounts[index] = [
              stats.tap,
              stats.hold,
              stats.slide,
              stats.touch,
              stats.breakNote,
            ];
            // 特殊处理6位数ID的UTAGE歌曲：只有一个难度(index=0)，但maidata中是index=5
            if (widget.songId.length == 6 && index == 5) {
              newNoteCounts[0] = [
                stats.tap,
                stats.hold,
                stats.slide,
                stats.touch,
                stats.breakNote,
              ];
            }
          }
          if (index >= 0 && index <= 5 && chart.breakStats != null) {
            BreakStats breakStats = chart.breakStats!;
            newBreakCounts[index] = [
              breakStats.trueZettaiTap,
              breakStats.trueZettaiHold,
              breakStats.protectedZettai,
              breakStats.star,
            ];
            // 特殊处理6位数ID的UTAGE歌曲：只有一个难度(index=0)，但maidata中是index=5
            if (widget.songId.length == 6 && index == 5) {
              newBreakCounts[0] = [
                breakStats.trueZettaiTap,
                breakStats.trueZettaiHold,
                breakStats.protectedZettai,
                breakStats.star,
              ];
            }
          }
        }

        // 更新状态并刷新界面
        if (newNoteCounts.isNotEmpty ||
            newBreakCounts.isNotEmpty ||
            newBpmByDiffIndex.isNotEmpty) {
          _update(() {
            _maidataNoteCounts = newNoteCounts;
            _maidataBreakCounts = newBreakCounts;
            _maidataBpmByDiffIndex = newBpmByDiffIndex;
            _maidataBpmChangesByDiffIndex = newBpmChanges;
            _maidataDecodedSuccessfully = true;
          });
        }
      } else {
        // 严格按 widget.songId 命中失败就不再尝试其它 shortId / title 顶替，
        // 让 SongInfoPage 的 songId 与 maidata.txt 的 &shortid= 严格一一对应。
        debugPrint(
            '[MaidataDecode] 严格查询失败, songId=${widget.songId}，不再使用 short_id 或 title 顶替');
      }
    } catch (e) {
      // 获取失败保留原来的统计兜底，不打断详情页。
      debugPrint('[MaidataDecode] 加载歌曲 ${widget.songId} 的统计失败: $e');
    }
  }

  /// 从指定难度的 inote 中提取 `(数字或小数)` BPM 标记。
  ///
  /// 同一张谱面可能有多个 BPM：全部相同时显示单值，否则显示最小值-最大值。
  /// 没有合法标记时返回 null，让页面继续使用曲库中的默认 BPM。
  List<double> _parseBpmChanges(String inote) => ChartBpmInfo.parse(inote);

  List<double> _bpmChangesForChart(MaidataData maidata, ChartData chart) {
    final values = _parseBpmChanges(chart.inote);
    if (values.isNotEmpty) return values;
    final match =
        RegExp('&inote_${chart.difficultyIndex}=([\\s\\S]*?)(?=\\r?\\n&|\$)')
            .firstMatch(maidata.rawContent);
    return _parseBpmChanges(match?.group(1) ?? '');
  }

  String _formatBpm(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  String _defaultBpm(dynamic basicInfo) {
    final value = basicInfo is Map ? basicInfo['bpm'] : null;
    return value is num && value.isFinite
        ? _formatBpm(value.toDouble())
        : value?.toString() ?? '-';
  }

  bool get _hasBpmChanges =>
      (_maidataBpmChangesByDiffIndex[_currentDiffIndex] ?? const <double>[])
          .toSet()
          .length >
      1;

  /// 无变速时导出曲库默认值；有变速时同时标明当前谱面的范围与基准值。
  String _exportBpm(dynamic basicInfo) {
    final defaultBpm = _defaultBpm(basicInfo);
    return _hasBpmChanges
        ? '$_bpmRangeLabel：${_displayBpm(basicInfo)}\n$_defaultBpmLabel：$defaultBpm'
        : defaultBpm;
  }

  String? _parseMaidataBpmForChart(MaidataData maidata, ChartData chart) {
    final values = _bpmChangesForChart(maidata, chart).toSet().toList()..sort();
    if (values.isEmpty) return null;
    return values.length == 1
        ? _formatBpm(values.single)
        : '${_formatBpm(values.first)}-${_formatBpm(values.last)}';
  }

  Widget _valueWithDirection(String text, int? direction) {
    final scheme = Theme.of(context).colorScheme;
    final arrow = direction == null
        ? ''
        : direction > 0
            ? '↑'
            : direction < 0
                ? '↓'
                : '→';
    return Text.rich(
        TextSpan(children: [
          TextSpan(
              text: text,
              style: AppTheme.number(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface)),
          if (arrow.isNotEmpty)
            TextSpan(
                text: ' $arrow',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: direction! > 0
                        ? Colors.redAccent
                        : direction < 0
                            ? Colors.blueAccent
                            : scheme.onSurfaceVariant)),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
  }

  String _displayBpm(dynamic basicInfo) {
    return _maidataBpmByDiffIndex[_currentDiffIndex] ??
        basicInfo['bpm'].toString();
  }

  // 加载参考时长（从落雪音频获取；落雪失败时尝试 wmc 兜底）
  //
  // 优先级：本地 Redis 缓存 > 落雪 (assets2.lxns.net) > wmc.pub
  // 任意一条路拿到 mp3，都走 [AudioPlayer.getDuration] 读时长，再走
  // [BiliRedisService.saveReferenceDuration] 上传到 Redis 缓存 30 天。
  Future<void> _loadReferenceDuration() async {
    if (_referenceDurationLoading) return;
    _referenceDurationLoading = true;

    try {
      final songId = widget.songId;
      final songTitle = _songData!['basic_info']['title'];

      // 1. 先查 Redis 缓存
      final cached = await BiliRedisService().getCachedReferenceDuration(
        songId: songId,
      );

      if (cached != null && mounted) {
        _update(() {
          _referenceDurationSeconds = cached;
          _referenceDurationLoading = false;
        });
        debugPrint('[RefDuration] Redis 缓存命中: ${cached}s');
        return;
      }

      // 2. 解析落雪 song id（与之前一样）
      final songType = _songData!['type'] ?? '';
      final songPlayService = SongPlayService();
      String? luoXueSongId;

      // 宴会场歌曲（6 位数 songId）：曲绘实际用的是 cover id，
      // 落雪那边的歌曲 ID 与曲绘 ID 一致，所以用 cover id 就能找到对应的落雪歌曲。
      // 例如: songId=100018 -> coverId=18 -> 落雪歌曲 id=18
      if (widget.songId.length == 6) {
        final coverId = CoverUtil.extractCoverId(widget.songId);
        if (coverId.isNotEmpty && coverId != '0') {
          luoXueSongId =
              await songPlayService.findLuoXueSongIdByCoverId(coverId);
        }
      }

      // 兜底：通过 title 和 type 查找（非宴会场歌曲，或宴会场 cover id 查不到时）
      luoXueSongId ??=
          await songPlayService.findLuoXueSongId(songTitle, songType);

      // 3. 落雪 → wmc 兜底：拿到一个 mp3 本地路径就停手
      String? localMp3 = await _downloadAudioForDuration(
        source: 'luoXue',
        url: luoXueSongId != null
            ? 'https://assets2.lxns.net/maimai/music/$luoXueSongId.mp3'
            : null,
        cacheFileName: luoXueSongId != null ? '$luoXueSongId.mp3' : null,
      );
      if (localMp3 == null) {
        // 落雪走不通（luoXueSongId 解析失败 / 下载非 200） → 试 wmc.pub 兜底
        debugPrint('[RefDuration] 落雪失败，尝试 wmc.pub 兜底: $songId');
        localMp3 = await _downloadAudioForDuration(
          source: 'wmc',
          url: ApiUrls.wmcAudioUrl(songId),
          cacheFileName: 'wmc_$songId.mp3',
        );
      }

      if (localMp3 == null) {
        debugPrint('[RefDuration] 落雪 + wmc 两条路都没拿到音频');
        _update(() {
          _referenceDurationLoading = false;
        });
        return;
      }

      // 4. 用 AudioPlayer 取时长
      final audioPlayer = AudioPlayer();
      await audioPlayer.setSource(DeviceFileSource(localMp3));

      final duration = await audioPlayer.getDuration();
      audioPlayer.dispose();

      if (duration != null && mounted) {
        final seconds = duration.inSeconds;
        _update(() {
          _referenceDurationSeconds = seconds;
          _referenceDurationLoading = false;
        });

        // 5. 保存到 Redis（30 天）—— 不管走的是落雪还是 wmc，存的都是同一份数据
        BiliRedisService().saveReferenceDuration(
          songId: songId,
          songTitle: songTitle,
          durationSeconds: seconds,
        );
      } else {
        _update(() {
          _referenceDurationLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载参考时长失败: $e');
      if (mounted) {
        _update(() {
          _referenceDurationLoading = false;
        });
      }
    }
  }

  /// 参考时长、播放和导出复用同一份音源，缓存命中时不联网。
  Future<String?> _downloadAudioForDuration({
    required String source,
    required String? url,
    required String? cacheFileName,
  }) async {
    if (url == null || cacheFileName == null) return null;
    try {
      final file =
          await SongMediaCache.instance.ensureAudio(widget.songId, urls: [url]);
      return file.path;
    } catch (error) {
      debugPrint('[RefDuration] $source 音源准备失败: $error');
      return null;
    }
  }

  // 格式化参考时长显示
  String _formatReferenceDuration() {
    if (_referenceDurationSeconds == null) {
      return _referenceDurationLoading ? '...' : '-';
    }
    final minutes = _referenceDurationSeconds! ~/ 60;
    final seconds = _referenceDurationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // 格式化首次上线日期显示（"20190711" → "2019-07-11"）
  Future<void> _loadUniInfo() async {
    try {
      final lookup = await UnionManager().getLookup();
      if (lookup.isEmpty) {
        debugPrint('[SongInfoPage] union uni 缓存为空');
        return;
      }

      // 按照 CoverUtil 的曲绘路径规则生成候选 ID 列表
      final rawId = widget.songId;
      final candidates = <String>{
        rawId,
        CoverUtil.buildCoverPath(rawId)
            .replaceAll(RegExp(r'assets/cover/|\.webp'), ''),
        CoverUtil.getLocalCoverPath(rawId)
            .replaceAll(RegExp(r'assets/cover/|\.webp'), ''),
        CoverUtil.getLocalCoverPathRetry1(rawId)
            .replaceAll(RegExp(r'assets/cover/|\.webp'), ''),
        CoverUtil.getLocalCoverPathRetry2(rawId)
            .replaceAll(RegExp(r'assets/cover/|\.webp'), ''),
      }.where((id) => id.isNotEmpty && id != '0').toList();

      String? foundId;
      for (final tryId in candidates) {
        if (lookup.containsKey(tryId)) {
          foundId = tryId;
          break;
        }
      }

      if (foundId != null) {
        final info = lookup[foundId]!;
        debugPrint(
            '[SongInfoPage] 通过 $foundId 找到 union 数据 (cn=${info.cn}, jp=${info.jp})');

        // 合并 union albums 到歌曲别名列表并去重
        if (info.albums.isNotEmpty && _songData != null) {
          final title = _songData!['basic_info']['title'] ?? '';
          if (title.isNotEmpty) {
            final aliasMgr = SongAliasManager.instance;
            final existing = Set<String>.from(aliasMgr.aliases[title] ?? []);
            final added = <String>[];
            for (final album in info.albums) {
              if (album.isNotEmpty && existing.add(album)) {
                added.add(album);
              }
            }
            if (added.isNotEmpty) {
              aliasMgr.aliases[title] = existing.toList();
              debugPrint(
                  '[SongInfoPage] 从 union albums 补充 ${added.length} 个别名: $added');
            }
          }
        }
      } else {
        debugPrint('[SongInfoPage] 未找到 union 数据, 候选ID: $candidates');
      }
    } catch (e) {
      debugPrint('[SongInfoPage] 加载 union uni 信息失败: $e');
    }
  }

  String _formatReleaseDate(String raw) {
    if (raw.isEmpty) return '未知';
    // 支持 YYYYMMDD 格式
    if (raw.length == 8) {
      try {
        final year = raw.substring(0, 4);
        final month = raw.substring(4, 6);
        final day = raw.substring(6, 8);
        return '$year-$month-$day';
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  // 加载B站谱面确认播放量
  Future<void> _loadBiliPlayCount() async {
    if (_biliPlayCountLoading) return;
    _biliPlayCountLoading = true;
    _biliLoadedDiffIndex = _currentDiffIndex;
    final targetDiffIndex = _currentDiffIndex;

    try {
      final songId = widget.songId;
      final songTitle = _songData!['basic_info']['title'];

      // 1. 首先尝试从 Redis 缓存获取
      final cached = await BiliRedisService().getCachedPlayCount(
        songId: songId,
        diffIndex: targetDiffIndex,
      );

      if (cached != null &&
          mounted &&
          _biliLoadedDiffIndex == targetDiffIndex) {
        final cachedPlayCount = cached['play_count'] as int?;
        final cachedBvid = cached['bvid'] as String?;
        final source = cached['source'] as String?;
        if (cachedPlayCount != null && cachedPlayCount > 0) {
          _update(() {
            _biliPlayCount = cachedPlayCount;
            _biliBvid = cachedBvid;
            _biliFromRedis = true;
            _biliFromUser = source == 'user_upload';
            _biliPlayCountLoading = false;
          });
          debugPrint(
              '[BiliRedis] 使用 Redis 缓存播放量: $cachedPlayCount, BV: $cachedBvid, source: $source');
          return;
        }
      }

      // 2. Redis 未命中，通过 B站 API 搜索
      final playCount = await BiliSearchService().fetchMaxPlayCount(
        songTitle,
        targetDiffIndex,
      );

      if (mounted && _biliLoadedDiffIndex == targetDiffIndex) {
        final result = BiliSearchService().lastSearchResult;
        final bvid = result?.bvid;
        _update(() {
          _biliPlayCount = playCount;
          _biliBvid = bvid;
          _biliFromRedis = false;
          _biliFromUser = false;
          _biliPlayCountLoading = false;
        });

        // 3. 搜索成功，将结果保存到 Redis
        if (playCount != null && playCount > 0) {
          BiliRedisService().savePlayCount(
            songId: songId,
            songTitle: songTitle,
            diffIndex: targetDiffIndex,
            playCount: playCount,
            bvid: bvid,
          );
        }
      } else {
        _biliPlayCountLoading = false;
      }
    } catch (e) {
      debugPrint('加载B站播放量失败: $e');
      if (mounted) {
        _update(() {
          _biliPlayCountLoading = false;
        });
      }
    }
  }

  // 格式化B站播放量显示
  String _formatBiliPlayCount() {
    if (_biliPlayCount == null) {
      return _biliPlayCountLoading ? '...' : '-';
    }
    final n = _biliPlayCount!;
    if (n >= 10000) {
      return '${(n / 10000).toStringAsFixed(1)}万';
    }
    return n.toString();
  }

  /// 获取来源标签（仅在对话框中显示）
  String _getBiliSourceLabel() {
    if (_biliFromUser) return '用户上传';
    if (_biliFromRedis) return 'Redis 缓存';
    return '自动获取';
  }

  // 获取音符数量，优先使用Maidata解析的结果
  List<int> _getNoteCounts(Map<String, dynamic> currentChart) {
    // 优先使用Maidata解析的物量统计
    if (_maidataNoteCounts.containsKey(_currentDiffIndex)) {
      List<int> counts = _maidataNoteCounts[_currentDiffIndex]!;
      // 检查是否所有值都为0（可能是解析失败）
      bool allZero = counts.every((count) => count == 0);
      if (!allZero) {
        return counts;
      }
    }

    // 否则使用默认的notes数据
    List<int> notes = List.filled(5, 0);
    List<dynamic> chartNotes = currentChart['notes'];
    notes[0] = chartNotes.length > 0
        ? (chartNotes[0] is int
            ? chartNotes[0]
            : int.tryParse(chartNotes[0].toString()) ?? 0)
        : 0;
    notes[1] = chartNotes.length > 1
        ? (chartNotes[1] is int
            ? chartNotes[1]
            : int.tryParse(chartNotes[1].toString()) ?? 0)
        : 0;
    notes[2] = chartNotes.length > 2
        ? (chartNotes[2] is int
            ? chartNotes[2]
            : int.tryParse(chartNotes[2].toString()) ?? 0)
        : 0;
    if (chartNotes.length > 4) {
      notes[3] = chartNotes[3] is int
          ? chartNotes[3]
          : int.tryParse(chartNotes[3].toString()) ?? 0;
      notes[4] = chartNotes[4] is int
          ? chartNotes[4]
          : int.tryParse(chartNotes[4].toString()) ?? 0;
    } else if (chartNotes.length > 3) {
      notes[4] = chartNotes[3] is int
          ? chartNotes[3]
          : int.tryParse(chartNotes[3].toString()) ?? 0;
    }
    return notes;
  }

  // 获取用户最佳成绩
  Map<String, dynamic>? _getUserBestRecord() {
    if (_userData == null || _songData == null) return null;

    final records = _userData!['records'];
    if (records == null) return null;

    // 找到对应歌曲的记录
    final songRecord = records
        .where((record) =>
            record['song_id'].toString() == widget.songId &&
            record['level_index'].toString() == _currentDiffIndex.toString())
        .toList();

    return songRecord.isNotEmpty ? songRecord.first : null;
  }

  // 获取标签分组
  Map<String, List<dynamic>> _getTagsByGroup() {
    final Map<String, List<dynamic>> groupedTags = {
      '配置': [],
      '评价': [],
      '难度': []
    };

    if (_tagData != null && _tagSongsData != null && _songData != null) {
      // 获取当前曲目的相关信息
      final String songTitle = _songData!['basic_info']['title'];
      final String songType = _songData!['type'];
      final String sheetType = songType == 'DX' ? 'dx' : 'std';

      // 映射难度索引到sheet_difficulty
      final sheetDifficulty =
          ChartDifficulty.apiNameOf(_currentDiffIndex, fallback: 'master');

      // 过滤出当前曲目的当前难度的标签ID
      final List<int> tagIds = _tagSongsData!
          .where((item) =>
              item['song_id'] == songTitle &&
              item['sheet_type'] == sheetType &&
              item['sheet_difficulty'] == sheetDifficulty)
          .map((item) => item['tag_id'] as int)
          .toList();

      // 根据标签ID获取标签详情
      for (int tagId in tagIds) {
        final tag = _tagData!.firstWhere((t) => t['id'] == tagId,
            orElse: () => <String, Object>{});

        if (tag != null) {
          int groupId = tag['group_id'] ?? 0;
          String groupName;

          switch (groupId) {
            case 1:
              groupName = '配置';
              break;
            case 2:
              groupName = '难度';
              break;
            case 3:
              groupName = '评价';
              break;
            default:
              groupName = '配置';
          }

          if (groupedTags.containsKey(groupName)) {
            groupedTags[groupName]!.add(tag);
          }
        }
      }
    }

    return groupedTags;
  }

  // 根据难度索引获取强调颜色
  Color _getAccentColor(int diffIndex, Brightness brightness) {
    // 检查难度数量
    int difficultyCount = 0;
    if (_songData != null && _songData!['level'] != null) {
      difficultyCount = _songData!['level'].length;
    }

    // 对于6位数ID的歌曲，使用独特的粉色主题
    if (widget.songId.length == 6) {
      return AppColors.utageAccent(brightness: brightness);
    }

    // 对于只有1或2个难度的歌曲，所有难度的背景全部采用粉色
    if (difficultyCount <= 2) {
      return AppColors.difficultyForegroundByIndex(3,
          brightness: brightness); // Master
    }

    return AppColors.difficultyForegroundByIndex(diffIndex,
        brightness: brightness);
  }

  // 计算单曲Rating
  int _calculateSingleRating(double difficulty, double completion) {
    // 特别处理：如果达成率大于100.5，则按100.5计算
    double adjustedCompletion = completion > 100.5 ? 100.5 : completion;
    double calculationCompletion = completion > 100.5 ? 100.5 : completion;

    // 查找对应的评级和乘数
    Map<String, dynamic>? selectedRating;

    // 遍历表格查找正确的区间
    for (var item in maimaiRatingMultiplier) {
      if (adjustedCompletion >= item['completion']) {
        selectedRating = item;
        break;
      }
    }

    // 如果没有找到（不应该发生），使用默认值
    selectedRating ??= {"rating": "D", "multiplier": 0.016};

    double multiplier = selectedRating['multiplier'];

    // 计算单曲Rating
    double singleRating = difficulty * multiplier * calculationCompletion;
    return singleRating.floor(); // 取整数部分（向下取整）
  }

  // 获取Break统计显示值，maidata解析失败时使用兜底方案
  String _getBreakCountDisplay(int index) {
    // 如果maidata解析成功，优先使用解析结果
    if (_maidataDecodedSuccessfully &&
        _maidataBreakCounts.containsKey(_currentDiffIndex)) {
      List<int> counts = _maidataBreakCounts[_currentDiffIndex]!;
      // 零绝赞谱面也属于有效解析结果，不应退回未知值或旧统计。
      if (index >= 0 && index < counts.length) {
        return counts[index].toString();
      }
    }

    // 兜底方案：当前难度没有有效解析结果时
    if (_songData != null) {
      String songType = _songData!['type'] ?? '';
      // ST谱面（type为SD）
      if (songType == 'SD') {
        // 获取当前难度的break音符数量
        int breakCount = 0;
        try {
          final currentChart = _songData!['charts'][_currentDiffIndex];
          if (currentChart != null && currentChart['notes'] != null) {
            List<dynamic> notes = currentChart['notes'];
            // ST谱面（SD类型）的notes数组只有4个元素，break在索引3
            // DX谱面的notes数组有5个元素，break在索引4
            int breakIndex = notes.length >= 5 ? 4 : 3;
            if (notes.length > breakIndex) {
              breakCount = notes[breakIndex] is int ? notes[breakIndex] : 0;
            }
          }
        } catch (e) {
          debugPrint('[SongInfoPage] Error getting break count: $e');
        }

        // 真绝赞TAP（index 0）设为总绝赞数量，其余为0
        if (index == 0) {
          return breakCount.toString();
        } else {
          return '0';
        }
      }
    }

    // 默认返回'-'
    return '-';
  }

  /// 安全转换为 double，兼容 String/int/double/num
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// 安全转换为 int，兼容 String/int/double/num
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // 获取难度标签
  String _getDiffLabel(int index) {
    // 检查难度数量
    int difficultyCount = 0;
    if (_songData != null && _songData!['level'] != null) {
      difficultyCount = _songData!['level'].length;
    }

    // 宴谱统一使用公共难度名称。
    if (difficultyCount <= 2) {
      return ChartDifficulty.utageLabel;
    }

    // 否则返回原来的标签
    return ChartDifficulty.labelOf(index, fallback: '');
  }

  // 计算maxScore
  int _calculateMaxScore(int songId, int levelIndex) {
    if (_songData == null) return 0;

    // 查找对应的charts
    List<dynamic> charts = _songData!['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0;

    dynamic chart = charts[levelIndex];
    if (chart['notes'] == null) return 0;

    // 计算maxScore
    List<dynamic> notes = chart['notes'];
    int notesSum = notes.fold(0, (sum, note) => sum + (note as int));
    return notesSum * 3;
  }

  /// 这张谱面的**达成率上限**：普通曲 101%；宴会场（6 位 songId）一个曲目里
  /// 有多张子谱、达成率相加，上限 = 101 × 子谱数。
  ///
  /// 口径与「自定义 Best50」一致（见 [maxAchievementFor]），供成绩历史的手动录入校验。
  double _calculateMaxAchievement() {
    final ds = _songData?['ds'];
    return maxAchievementFor(
      isUtage: widget.songId.length == 6,
      chartCount: ds is List ? ds.length : 1,
    );
  }

  // 计算最大DX分
  // 当ds数组长度为2时，返回两个难度谱面DX分之和
  // 否则返回当前难度的最大分数
  int _calculateMaxDxScore(int songId, int levelIndex) {
    if (_songData == null) return 0;

    // 检查ds数组长度
    List<dynamic> ds = _songData!['ds'];
    if (ds.length == 2) {
      // 计算两个难度谱面的最大分数之和
      int maxScore1 = _calculateMaxScore(songId, 0);
      int maxScore2 = _calculateMaxScore(songId, 1);
      return maxScore1 + maxScore2;
    } else {
      // 返回当前难度的最大分数
      return _calculateMaxScore(songId, levelIndex);
    }
  }

  // 计算scoreRate
  double _calculateScoreRate(int songId, int levelIndex, int score) {
    int maxScore = _calculateMaxDxScore(songId, levelIndex);
    return maxScore > 0 ? score / maxScore : 0.0;
  }

  // 计算星星等级

  // 计算星星等级的最低DX分和超出部分
  String _calculateStars(int songId, int levelIndex, int score) {
    double scoreRate = _calculateScoreRate(songId, levelIndex, score);

    // 确定星星等级
    if (scoreRate >= 0.99) {
      return '\u2726 6';
    } else if (scoreRate >= 0.98) {
      return '\u2726 5.5';
    } else if (scoreRate >= 0.97) {
      return '\u2726 5';
    } else if (scoreRate >= 0.95) {
      return '\u2726 4';
    } else if (scoreRate >= 0.93) {
      return '\u2726 3';
    } else if (scoreRate >= 0.90) {
      return '\u2726 2';
    } else if (scoreRate >= 0.85) {
      return '\u2726 1';
    } else {
      return '\u2726 0';
    }
  }

  /// 星级文字色：黄 / 橙 / 绿三档。浅色模式下白卡片上用加深的同色相，否则看不清。
  Color _getStarsColor(String stars, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (stars) {
      case '\u2726 6':
      case '\u2726 5.5':
      case '\u2726 5':
        return dark ? Colors.yellow : const Color(0xFFC29100);
      case '\u2726 4':
      case '\u2726 3':
        return dark ? Colors.orange : const Color(0xFFDD7A00);
      case '\u2726 2':
      case '\u2726 1':
        return dark ? Colors.green.shade300 : const Color(0xFF2E9E5B);
      case '\u2726 0':
      default:
        return dark ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }

  String _calculateStarsBonus(int songId, int levelIndex, int score) {
    int maxScore = _calculateMaxDxScore(songId, levelIndex);
    double scoreRate = score / maxScore;
    dynamic starLevel = 0;
    double minRate = 0.0;

    // 确定当前星星等级和对应的最低达成率
    if (scoreRate >= 0.99) {
      starLevel = 6;
      minRate = 0.99;
    } else if (scoreRate >= 0.98) {
      starLevel = 5.5;
      minRate = 0.98;
    } else if (scoreRate >= 0.97) {
      starLevel = 5;
      minRate = 0.97;
    } else if (scoreRate >= 0.95) {
      starLevel = 4;
      minRate = 0.95;
    } else if (scoreRate >= 0.93) {
      starLevel = 3;
      minRate = 0.93;
    } else if (scoreRate >= 0.90) {
      starLevel = 2;
      minRate = 0.90;
    } else if (scoreRate >= 0.85) {
      starLevel = 1;
      minRate = 0.85;
    } else {
      starLevel = 0;
      minRate = 0.85; // 0星时计算与1星的差距
    }

    // 计算最低DX分（向上取整）
    int minScore = (maxScore * minRate).ceil();
    // 计算超出部分或差距
    int difference = score - minScore;
    String symbol = difference >= 0 ? '+' : '';

    // 0星时显示1星的差距
    dynamic displayStarLevel = starLevel == 0 ? 1 : starLevel;

    return '\u2726 $displayStarLevel $symbol$difference';
  }

  // 计算到下一星级还需要多少分
  String _calculateNextStarDiff(int songId, int levelIndex, int score) {
    int maxScore = _calculateMaxDxScore(songId, levelIndex);
    double scoreRate = score / maxScore;

    // 定义各星级对应的最低达成率
    Map<dynamic, double> starRates = {
      0: 0.85, // 1星最低
      1: 0.85, // 1星
      2: 0.90, // 2星
      3: 0.93, // 3星
      4: 0.95, // 4星
      5: 0.97, // 5星
      5.5: 0.98, // 5.5星
      6: 0.99, // 6星
    };

    // 确定当前星星等级
    dynamic currentStar = 0;
    if (scoreRate >= 0.99) {
      currentStar = 6;
    } else if (scoreRate >= 0.98) {
      currentStar = 5.5;
    } else if (scoreRate >= 0.97) {
      currentStar = 5;
    } else if (scoreRate >= 0.95) {
      currentStar = 4;
    } else if (scoreRate >= 0.93) {
      currentStar = 3;
    } else if (scoreRate >= 0.90) {
      currentStar = 2;
    } else if (scoreRate >= 0.85) {
      currentStar = 1;
    } else {
      currentStar = 0;
    }

    // 确定下一星级
    List<dynamic> starOrder = [0, 1, 2, 3, 4, 5, 5.5, 6];
    int currentIndex = starOrder.indexOf(currentStar);

    // 如果已经是最高星级，显示已满
    if (currentIndex >= starOrder.length - 1) {
      return '\u2726 6 已满';
    }

    // 获取下一星级和对应的最低分数
    dynamic nextStar = starOrder[currentIndex + 1];
    double nextRate = starRates[nextStar]!;
    int nextMinScore = (maxScore * nextRate).ceil();

    // 计算还需要多少分
    int diff = nextMinScore - score;

    return '\u2726 $nextStar -$diff';
  }

  // 获取星星颜色。
  //
  // 评级越高越「重」：黄/橙/绿；★ 0 走中性灰（与同行的 `DX分数达成率` label
  // 同样的颜色源 `onSurfaceVariant`，保持浅色模式下能看见）。
  //
  // ⚠️ **0 星这条在浅色模式下专门修了**：
  // 原来写死 `Colors.grey`（=`Colors.grey[500]`=`#9E9E9E`），在 `Colors.white`
  // 的卡片底上几乎看不见；而且 `default` 分支兜底是 `Colors.white` —— 纯白叠
  // 纯白，无论何时都看不见，是个**潜伏 bug**。这里统一改成跟主题走。


  // 获取当前难度的定数
  double _getCurrentDs() {
    if (_songData != null && _songData!['ds'] != null) {
      final dsList = _songData!['ds'] as List<dynamic>;
      if (_currentDiffIndex < dsList.length) {
        return (dsList[_currentDiffIndex] as num).toDouble();
      }
    }
    return 0.0;
  }

  // 格式化时间戳
  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 获取收藏品类型名称
  String _getCollectionTypeName(String type) {
    switch (type) {
      case 'trophies':
        return '称号';
      case 'icons':
        return '头像';
      case 'plates':
        return '姓名框';
      case 'frames':
        return '背景';
      default:
        return '未知类型';
    }
  }

  // 获取收藏品类型颜色
  Color _getCollectionTypeColor(String type) {
    final brightness = Theme.of(context).brightness;
    switch (type) {
      case 'trophies':
        return AppColors.warningOrange(brightness);
      case 'icons':
        return AppColors.linkBlue(brightness);
      case 'plates':
        return AppColors.successGreen(brightness);
      case 'frames':
        return Colors.purple; // 语义色，保持不变
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  // 获取标签颜色
  Color _getTagColor(String group) => AppColors.tagGroupBackground(group);

  // 获取标签边框颜色
  Color _getTagBorderColor(String group) => AppColors.tagGroupBorder(group);

  // 获取标签文本颜色
  Color _getTagTextColor(String group) => AppColors.tagGroupText(group);

  /// 本曲是否 extra（宴会场 / maidata 追加 / union 独有）。
  ///
  /// 用于统计和曲目分类；宴谱属于非正曲，但不能据此去掉版本年号。
  bool get _isExtraSong => SongFilterUtil.isExtraRaw(
        songId: widget.songId,
        isExtraFlag: _songData?['is_extra'] == true,
        cids: _songData?['cids'] is List
            ? (_songData!['cids'] as List).cast<dynamic>()
            : null,
      );

  /// 宴谱沿用常规世代名；只有其它追加曲使用不带年号的 extra 版本名。
  bool get _usesExtraVersionName =>
      _isExtraSong &&
      !ChartDifficulty.isUtageSong(widget.songId,
          type: _songData?['type']?.toString());
}
